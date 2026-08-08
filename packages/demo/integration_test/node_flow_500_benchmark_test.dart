// This file intentionally reports measurements instead of asserting timing
// thresholds. Frame times are meaningful only in profile mode on controlled
// hardware.
// ignore_for_file: avoid_print

import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:vyuh_node_flow/vyuh_node_flow.dart';

const _nodeCount = 500;
const _columnCount = 20;
const _rowCount = 25;
const _nodeSize = Size(160, 80);
const _columnSpacing = 210.0;
const _rowSpacing = 125.0;
const _initialZoom = 0.18;
const _targetFrameMicros = 8333;
const _adaptiveNodeLimit = 200;

const _requestedRenderMode = String.fromEnvironment(
  'NODE_FLOW_BENCHMARK_RENDER_MODE',
  defaultValue: 'all',
);

const _warmupFrames = int.fromEnvironment(
  'NODE_FLOW_BENCHMARK_WARMUP_FRAMES',
  defaultValue: 100,
);
const _scenarioFrames = int.fromEnvironment(
  'NODE_FLOW_BENCHMARK_SCENARIO_FRAMES',
  defaultValue: 100,
);

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  binding.framePolicy = LiveTestWidgetsFlutterBindingFramePolicy.onlyPumps;

  for (final renderMode in _selectedRenderModes()) {
    testWidgets(
      '500-node rendered frame benchmark (${renderMode.name})',
      (tester) async {
        await _runBenchmark(tester, binding, renderMode);
      },
      timeout: Timeout.none,
    );
  }
}

Future<void> _runBenchmark(
  WidgetTester tester,
  IntegrationTestWidgetsFlutterBinding binding,
  _RenderMode renderMode,
) async {
  final fixture = _BenchmarkFixture.create();
  final controller = NodeFlowController<String, void>(
    nodes: fixture.nodes,
    connections: fixture.connections,
    initialViewport: const GraphViewport(x: 24, y: 24, zoom: _initialZoom),
    config: NodeFlowConfig(
      minZoom: 0.12,
      maxZoom: 2,
      showAttribution: false,
      plugins: [
        LodPlugin(
          enabled: renderMode == _RenderMode.adaptive,
          maxInteractiveNodes: _adaptiveNodeLimit,
        ),
      ],
    ),
  );
  addTearDown(controller.dispose);

  await tester.pumpWidget(_BenchmarkApp(controller: controller));
  await tester.pumpAndSettle();

  expect(controller.nodeCount, _nodeCount);
  expect(controller.connectionCount, fixture.connections.length);

  _centerGraph(controller, _initialZoom);
  await tester.pump();
  final warmup = await _measurePhase(
    tester: tester,
    phase: 'warmup',
    requestedFrames: _warmupFrames,
    action: () => _pumpViewportFrames(
      tester: tester,
      controller: controller,
      frameCount: _warmupFrames,
      viewportForFrame: (frame) {
        final phase = frame / math.max(1, _warmupFrames - 1);
        return _oscillatingViewport(
          controller,
          phase,
          _initialZoom,
          panRadius: 12,
        );
      },
    ),
  );
  controller.commitCameraViewport();
  await tester.pump();
  final initialRenderState = _renderState(controller);

  final results = <String, Map<String, Object?>>{};

  _centerGraph(controller, _initialZoom);
  await tester.pump();
  final pan = await _measurePhase(
    tester: tester,
    phase: 'steady_state',
    requestedFrames: _scenarioFrames,
    action: () => _pumpViewportFrames(
      tester: tester,
      controller: controller,
      frameCount: _scenarioFrames,
      viewportForFrame: (frame) {
        final phase = frame / math.max(1, _scenarioFrames - 1);
        return _oscillatingViewport(
          controller,
          phase,
          _initialZoom,
          panRadius: 90,
        );
      },
    ),
  );
  controller.commitCameraViewport();
  await tester.pump();
  results['pan'] = {...pan, 'render_state': _renderState(controller)};

  _centerGraph(controller, _initialZoom);
  await tester.pump();
  final zoom = await _measurePhase(
    tester: tester,
    phase: 'steady_state',
    requestedFrames: _scenarioFrames,
    action: () => _pumpViewportFrames(
      tester: tester,
      controller: controller,
      frameCount: _scenarioFrames,
      viewportForFrame: (frame) {
        final phase = frame / math.max(1, _scenarioFrames - 1);
        final zoom = _initialZoom + 0.055 * math.sin(phase * math.pi * 2);
        return _centeredViewport(controller, zoom);
      },
    ),
  );
  controller.commitCameraViewport();
  await tester.pump();
  results['zoom'] = {...zoom, 'render_state': _renderState(controller)};

  _centerGraph(controller, 0.24);
  await tester.pump();
  results['single_node_drag'] = {
    ...await _measurePhase(
      tester: tester,
      phase: 'steady_state',
      requestedFrames: _scenarioFrames,
      action: () async {
        const nodeId = 'node-249';
        controller.startNodeDrag(nodeId);
        final counters = await _pumpFrames(tester, _scenarioFrames, (frame) {
          final direction = frame < _scenarioFrames ~/ 2 ? 1.0 : -1.0;
          controller.moveNodeDrag(Offset(0.9 * direction, 0.45 * direction));
        }, graphUpdatesPerFrame: 1);
        controller.endNodeDrag();
        return counters;
      },
    ),
    'render_state': _renderState(controller),
  };
  // Commit the drag-end state outside the measured steady-state phase.
  await tester.pump();

  _centerGraph(controller, 0.24);
  await tester.pump();
  results['node_and_edge_churn'] = {
    ...await _measurePhase(
      tester: tester,
      phase: 'steady_state',
      requestedFrames: _scenarioFrames,
      action: () => _pumpTopologyFrames(
        tester: tester,
        controller: controller,
        frameCount: _scenarioFrames,
      ),
    ),
    'render_state': _renderState(controller),
  };
  // An odd frame count leaves the last transient node mounted. Restore the
  // deterministic 500-node fixture outside the measured phase.
  if (_scenarioFrames.isOdd) {
    controller.removeNode('churn-node-${_scenarioFrames ~/ 2}');
    await tester.pump();
  }
  expect(controller.nodeCount, _nodeCount);
  expect(controller.connectionCount, fixture.connections.length);

  final report = <String, Object?>{
    'render_mode': renderMode.name,
    'fixture': {
      'nodes': controller.nodeCount,
      'connections': controller.connectionCount,
      'columns': _columnCount,
      'rows': _rowCount,
    },
    'runtime': {
      'build_mode': kProfileMode
          ? 'profile'
          : kReleaseMode
          ? 'release'
          : 'debug',
      'web': kIsWeb,
      'platform': defaultTargetPlatform.name,
      'logical_surface': {
        'width': controller.screenSize.width,
        'height': controller.screenSize.height,
      },
      'target_frame_ms': _targetFrameMicros / 1000,
      'warmup_frames': _warmupFrames,
      'scenario_frames': _scenarioFrames,
      'phases': {
        'warmup': {'requested_frames': _warmupFrames},
        'steady_state': {'requested_frames_per_scenario': _scenarioFrames},
      },
    },
    'warmup': warmup,
    'initial_render_state': initialRenderState,
    'scenarios': results,
  };

  binding.reportData ??= <String, dynamic>{};
  final modeReports =
      binding.reportData!.putIfAbsent(
            'node_flow_500',
            () => <String, Object?>{},
          )
          as Map<String, Object?>;
  modeReports[renderMode.name] = report;
  debugPrint('NODE_FLOW_500_BENCHMARK ${jsonEncode(report)}');
}

enum _RenderMode { full, adaptive }

List<_RenderMode> _selectedRenderModes() {
  return switch (_requestedRenderMode) {
    'all' => _RenderMode.values,
    'full' => const [_RenderMode.full],
    'adaptive' => const [_RenderMode.adaptive],
    _ => throw ArgumentError.value(
      _requestedRenderMode,
      'NODE_FLOW_BENCHMARK_RENDER_MODE',
      'Expected all, full, or adaptive',
    ),
  };
}

Map<String, Object?> _renderState(NodeFlowController<String, void> controller) {
  final lod = controller.getPlugin<LodPlugin>();
  final visibility = lod?.currentVisibility;
  final detailLevel = visibility == DetailVisibility.minimal
      ? 'minimal'
      : visibility == DetailVisibility.standard
      ? 'standard'
      : 'full';

  return {
    'zoom': controller.currentZoom,
    'visible_nodes': controller.visibleNodes.length,
    'visible_connections': controller.visibleConnections.length,
    'lod_enabled': lod?.isEnabled ?? false,
    'lod_detail': detailLevel,
    'thumbnail_mode': lod?.useThumbnailMode ?? false,
    'max_interactive_nodes': lod?.maxInteractiveNodes,
  };
}

class _BenchmarkApp extends StatelessWidget {
  const _BenchmarkApp({required this.controller});

  final NodeFlowController<String, void> controller;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        body: NodeFlowEditor<String, void>(
          controller: controller,
          theme: NodeFlowTheme.light,
          nodeBuilder: (context, node) => Container(
            width: _nodeSize.width,
            height: _nodeSize.height,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xfff8fafc),
              border: Border.all(color: const Color(0xffcbd5e1)),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  node.data,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  node.id,
                  style: const TextStyle(
                    fontSize: 11,
                    color: Color(0xff64748b),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _BenchmarkFixture {
  const _BenchmarkFixture({required this.nodes, required this.connections});

  factory _BenchmarkFixture.create() {
    final nodes = <Node<String>>[];
    final connections = <Connection<void>>[];

    for (var row = 0; row < _rowCount; row++) {
      for (var column = 0; column < _columnCount; column++) {
        final index = row * _columnCount + column;
        nodes.add(
          _benchmarkNode(
            id: 'node-$index',
            data: 'Processor $index',
            position: Offset(column * _columnSpacing, row * _rowSpacing),
          ),
        );

        if (column > 0) {
          connections.add(
            Connection<void>(
              id: 'horizontal-$row-$column',
              sourceNodeId: 'node-${index - 1}',
              sourcePortId: 'out',
              targetNodeId: 'node-$index',
              targetPortId: 'in',
            ),
          );
        }
        if (row > 0) {
          connections.add(
            Connection<void>(
              id: 'vertical-$row-$column',
              sourceNodeId: 'node-${index - _columnCount}',
              sourcePortId: 'out',
              targetNodeId: 'node-$index',
              targetPortId: 'in',
            ),
          );
        }
      }
    }

    return _BenchmarkFixture(nodes: nodes, connections: connections);
  }

  final List<Node<String>> nodes;
  final List<Connection<void>> connections;
}

Node<String> _benchmarkNode({
  required String id,
  required String data,
  required Offset position,
}) {
  return Node<String>(
    id: id,
    type: 'benchmark',
    position: position,
    size: _nodeSize,
    data: data,
    ports: [
      Port(
        id: 'in',
        name: 'Input',
        position: PortPosition.left,
        offset: const Offset(0, 40),
        multiConnections: true,
      ),
      Port(
        id: 'out',
        name: 'Output',
        position: PortPosition.right,
        offset: const Offset(0, 40),
        multiConnections: true,
      ),
    ],
  );
}

Future<_WorkloadCounters> _pumpFrames(
  WidgetTester tester,
  int frameCount,
  void Function(int frame) update, {
  int graphUpdatesPerFrame = 0,
}) async {
  var pumpedFrames = 0;
  for (var frame = 0; frame < frameCount; frame++) {
    update(frame);
    await tester.pump(const Duration(microseconds: _targetFrameMicros));
    pumpedFrames++;
  }

  return _WorkloadCounters(
    requestedFrames: frameCount,
    pumpedFrames: pumpedFrames,
    viewportUpdates: 0,
    graphUpdates: pumpedFrames * graphUpdatesPerFrame,
  );
}

Future<_WorkloadCounters> _pumpViewportFrames({
  required WidgetTester tester,
  required NodeFlowController<String, void> controller,
  required int frameCount,
  required GraphViewport Function(int frame) viewportForFrame,
}) async {
  // Drive the lightweight live camera once per frame. The committed
  // MobX/plugin viewport boundary is crossed outside the measured phase.
  var pumpedFrames = 0;
  var viewportUpdates = 0;
  for (var frame = 0; frame < frameCount; frame++) {
    controller.updateCameraViewport(viewportForFrame(frame));
    viewportUpdates++;
    await tester.pump(const Duration(microseconds: _targetFrameMicros));
    pumpedFrames++;
  }

  return _WorkloadCounters(
    requestedFrames: frameCount,
    pumpedFrames: pumpedFrames,
    viewportUpdates: viewportUpdates,
    graphUpdates: 0,
  );
}

Future<_WorkloadCounters> _pumpTopologyFrames({
  required WidgetTester tester,
  required NodeFlowController<String, void> controller,
  required int frameCount,
}) async {
  var pumpedFrames = 0;
  var graphUpdates = 0;

  for (var frame = 0; frame < frameCount; frame++) {
    final cycle = frame ~/ 2;
    final nodeId = 'churn-node-$cycle';
    if (frame.isEven) {
      controller.addNode(
        _benchmarkNode(
          id: nodeId,
          data: 'Transient processor $cycle',
          position: Offset(9.5 * _columnSpacing, 12.5 * _rowSpacing),
        ),
      );
      controller.addConnections([
        Connection<void>(
          id: 'churn-in-$cycle',
          sourceNodeId: 'node-249',
          sourcePortId: 'out',
          targetNodeId: nodeId,
          targetPortId: 'in',
        ),
        Connection<void>(
          id: 'churn-out-$cycle',
          sourceNodeId: nodeId,
          sourcePortId: 'out',
          targetNodeId: 'node-250',
          targetPortId: 'in',
        ),
      ]);
      graphUpdates += 3;
    } else {
      // Removing the node also removes both incident connections, exercising
      // adjacency cleanup and connection-scene invalidation.
      controller.removeNode(nodeId);
      graphUpdates++;
    }

    await tester.pump(const Duration(microseconds: _targetFrameMicros));
    pumpedFrames++;
  }

  return _WorkloadCounters(
    requestedFrames: frameCount,
    pumpedFrames: pumpedFrames,
    viewportUpdates: 0,
    graphUpdates: graphUpdates,
  );
}

Future<Map<String, Object?>> _measurePhase({
  required WidgetTester tester,
  required String phase,
  required int requestedFrames,
  required Future<_WorkloadCounters> Function() action,
}) async {
  final timings = <FrameTiming>[];
  void collect(List<FrameTiming> batch) => timings.addAll(batch);

  late final _WorkloadCounters counters;
  SchedulerBinding.instance.addTimingsCallback(collect);
  try {
    counters = await action();
    // Frame timings can be delivered by the engine in batches, approximately
    // once per second. Waiting here makes the report much less likely to omit
    // the final batch without adding idle frames to the workload.
    await Future<void>.delayed(const Duration(seconds: 2));
  } finally {
    SchedulerBinding.instance.removeTimingsCallback(collect);
  }

  assert(counters.requestedFrames == requestedFrames);
  return _summarize(
    timings,
    phase: phase,
    requestedFrames: requestedFrames,
    workload: counters,
  );
}

Map<String, Object?> _summarize(
  List<FrameTiming> timings, {
  required String phase,
  required int requestedFrames,
  required _WorkloadCounters workload,
}) {
  final build = [
    for (final timing in timings) timing.buildDuration.inMicroseconds,
  ];
  final raster = [
    for (final timing in timings) timing.rasterDuration.inMicroseconds,
  ];
  final total = [for (final timing in timings) timing.totalSpan.inMicroseconds];

  Map<String, Object?> distribution(List<int> values) {
    values.sort();
    return {
      'p50_ms': _percentile(values, 0.50) / 1000,
      'p95_ms': _percentile(values, 0.95) / 1000,
      'p99_ms': _percentile(values, 0.99) / 1000,
      'max_ms': (values.isEmpty ? 0 : values.last) / 1000,
    };
  }

  final deliveredFrames = timings.length;
  final budgetMisses = total.where((time) => time > _targetFrameMicros).length;
  final undeliveredFrames = math.max(0, requestedFrames - deliveredFrames);
  final extraDeliveredFrames = math.max(0, deliveredFrames - requestedFrames);

  return {
    'phase': phase,
    'requested_frames': requestedFrames,
    'delivered_frames': deliveredFrames,
    'undelivered_frames': undeliveredFrames,
    'extra_delivered_frames': extraDeliveredFrames,
    'delivery_ratio': requestedFrames == 0
        ? 0.0
        : deliveredFrames / requestedFrames,
    'workload': workload.toJson(),
    'frame_budget': {
      'target_ms': _targetFrameMicros / 1000,
      'misses': budgetMisses,
      'met': math.max(0, deliveredFrames - budgetMisses),
      'miss_ratio': deliveredFrames == 0 ? 0.0 : budgetMisses / deliveredFrames,
    },
    // Compatibility aliases retained for existing report consumers.
    'frame_count': timings.length,
    'ui': distribution(build),
    'raster': distribution(raster),
    'total': distribution(total),
    'frames_over_8_33_ms': budgetMisses,
    if (timings.isEmpty)
      'note': 'No FrameTiming values were delivered by this target.',
  };
}

class _WorkloadCounters {
  const _WorkloadCounters({
    required this.requestedFrames,
    required this.pumpedFrames,
    required this.viewportUpdates,
    required this.graphUpdates,
  });

  final int requestedFrames;
  final int pumpedFrames;
  final int viewportUpdates;
  final int graphUpdates;

  Map<String, Object?> toJson() => {
    'requested_frames': requestedFrames,
    'pumped_frames': pumpedFrames,
    'viewport_updates': viewportUpdates,
    'graph_updates': graphUpdates,
  };
}

int _percentile(List<int> sortedValues, double percentile) {
  if (sortedValues.isEmpty) return 0;
  final index = (percentile * sortedValues.length).ceil() - 1;
  return sortedValues[index.clamp(0, sortedValues.length - 1)];
}

void _centerGraph(NodeFlowController<String, void> controller, double zoom) {
  controller.setViewport(_centeredViewport(controller, zoom));
}

GraphViewport _centeredViewport(
  NodeFlowController<String, void> controller,
  double zoom,
) {
  final graphCenter = Offset(
    ((_columnCount - 1) * _columnSpacing + _nodeSize.width) / 2,
    ((_rowCount - 1) * _rowSpacing + _nodeSize.height) / 2,
  );
  final screenCenter = Offset(
    controller.screenSize.width / 2,
    controller.screenSize.height / 2,
  );
  return GraphViewport(
    x: screenCenter.dx - graphCenter.dx * zoom,
    y: screenCenter.dy - graphCenter.dy * zoom,
    zoom: zoom,
  );
}

GraphViewport _oscillatingViewport(
  NodeFlowController<String, void> controller,
  double phase,
  double zoom, {
  required double panRadius,
}) {
  final centered = _centeredViewport(controller, zoom);
  final angle = phase * math.pi * 2;
  return centered.copyWith(
    x: centered.x + math.sin(angle) * panRadius,
    y: centered.y + math.cos(angle) * panRadius * 0.45,
  );
}
