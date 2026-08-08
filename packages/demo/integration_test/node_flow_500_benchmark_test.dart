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
  defaultValue: 60,
);
const _scenarioFrames = int.fromEnvironment(
  'NODE_FLOW_BENCHMARK_SCENARIO_FRAMES',
  defaultValue: 180,
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
  await _pumpFrames(tester, _warmupFrames, (frame) {
    final phase = frame / math.max(1, _warmupFrames - 1);
    _setOscillatingViewport(controller, phase, _initialZoom, panRadius: 12);
  });
  final initialRenderState = _renderState(controller);

  // The engine may batch FrameTiming delivery. Let warm-up timings drain
  // before registering the first scenario callback.
  await Future<void>.delayed(const Duration(seconds: 2));

  final results = <String, Map<String, Object?>>{};

  _centerGraph(controller, _initialZoom);
  await tester.pump();
  results['pan'] = {
    ...await _measureScenario(
      tester: tester,
      action: () => _pumpFrames(tester, _scenarioFrames, (frame) {
        final phase = frame / math.max(1, _scenarioFrames - 1);
        _setOscillatingViewport(controller, phase, _initialZoom, panRadius: 90);
      }),
    ),
    'render_state': _renderState(controller),
  };

  _centerGraph(controller, _initialZoom);
  await tester.pump();
  results['zoom'] = {
    ...await _measureScenario(
      tester: tester,
      action: () => _pumpFrames(tester, _scenarioFrames, (frame) {
        final phase = frame / math.max(1, _scenarioFrames - 1);
        final zoom = _initialZoom + 0.055 * math.sin(phase * math.pi * 2);
        _centerGraph(controller, zoom);
      }),
    ),
    'render_state': _renderState(controller),
  };

  _centerGraph(controller, 0.24);
  await tester.pump();
  results['single_node_drag'] = {
    ...await _measureScenario(
      tester: tester,
      action: () async {
        const nodeId = 'node-249';
        controller.startNodeDrag(nodeId);
        await _pumpFrames(tester, _scenarioFrames, (frame) {
          final direction = frame < _scenarioFrames ~/ 2 ? 1.0 : -1.0;
          controller.moveNodeDrag(Offset(0.9 * direction, 0.45 * direction));
        });
        controller.endNodeDrag();
        await tester.pump();
      },
    ),
    'render_state': _renderState(controller),
  };

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
    },
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
          Node<String>(
            id: 'node-$index',
            type: 'benchmark',
            position: Offset(column * _columnSpacing, row * _rowSpacing),
            size: _nodeSize,
            data: 'Processor $index',
            ports: [
              Port(
                id: 'in',
                name: 'Input',
                position: PortPosition.left,
                offset: Offset(0, 40),
                multiConnections: true,
              ),
              Port(
                id: 'out',
                name: 'Output',
                position: PortPosition.right,
                offset: Offset(0, 40),
                multiConnections: true,
              ),
            ],
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

Future<void> _pumpFrames(
  WidgetTester tester,
  int frameCount,
  void Function(int frame) update,
) async {
  for (var frame = 0; frame < frameCount; frame++) {
    update(frame);
    await tester.pump(const Duration(microseconds: _targetFrameMicros));
  }
}

Future<Map<String, Object?>> _measureScenario({
  required WidgetTester tester,
  required Future<void> Function() action,
}) async {
  final timings = <FrameTiming>[];
  void collect(List<FrameTiming> batch) => timings.addAll(batch);

  SchedulerBinding.instance.addTimingsCallback(collect);
  try {
    await action();
    // Frame timings can be delivered by the engine in batches, approximately
    // once per second. Waiting here makes the report much less likely to omit
    // the final batch without adding idle frames to the workload.
    await Future<void>.delayed(const Duration(seconds: 2));
  } finally {
    SchedulerBinding.instance.removeTimingsCallback(collect);
  }

  return _summarize(timings);
}

Map<String, Object?> _summarize(List<FrameTiming> timings) {
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

  return {
    'frame_count': timings.length,
    'ui': distribution(build),
    'raster': distribution(raster),
    'total': distribution(total),
    'frames_over_8_33_ms': total
        .where((time) => time > _targetFrameMicros)
        .length,
    if (timings.isEmpty)
      'note': 'No FrameTiming values were delivered by this target.',
  };
}

int _percentile(List<int> sortedValues, double percentile) {
  if (sortedValues.isEmpty) return 0;
  final index = (percentile * sortedValues.length).ceil() - 1;
  return sortedValues[index.clamp(0, sortedValues.length - 1)];
}

void _centerGraph(NodeFlowController<String, void> controller, double zoom) {
  final graphCenter = Offset(
    ((_columnCount - 1) * _columnSpacing + _nodeSize.width) / 2,
    ((_rowCount - 1) * _rowSpacing + _nodeSize.height) / 2,
  );
  final screenCenter = Offset(
    controller.screenSize.width / 2,
    controller.screenSize.height / 2,
  );
  controller.setViewport(
    GraphViewport(
      x: screenCenter.dx - graphCenter.dx * zoom,
      y: screenCenter.dy - graphCenter.dy * zoom,
      zoom: zoom,
    ),
  );
}

void _setOscillatingViewport(
  NodeFlowController<String, void> controller,
  double phase,
  double zoom, {
  required double panRadius,
}) {
  _centerGraph(controller, zoom);
  final centered = controller.viewport;
  final angle = phase * math.pi * 2;
  controller.setViewport(
    centered.copyWith(
      x: centered.x + math.sin(angle) * panRadius,
      y: centered.y + math.cos(angle) * panRadius * 0.45,
    ),
  );
}
