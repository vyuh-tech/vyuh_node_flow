/// Adaptive overview rendering tests for NodesLayer.
@Tags(['unit'])
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vyuh_node_flow/src/editor/layers/nodes_layer.dart';
import 'package:vyuh_node_flow/src/editor/layers/nodes_thumbnail_layer.dart';
import 'package:vyuh_node_flow/src/editor/unbounded_widgets.dart';
import 'package:vyuh_node_flow/vyuh_node_flow.dart';

import '../../helpers/test_factories.dart';

void main() {
  setUp(resetTestCounters);

  testWidgets(
    'switches between batched overview and full node widgets by visible count',
    (tester) async {
      final controller = NodeFlowController<String, dynamic>(
        nodes: [
          createTestNode(id: 'one'),
          createTestNode(id: 'two'),
          createTestNode(id: 'three'),
        ],
        config: NodeFlowConfig(
          plugins: [
            LodPlugin(enabled: true, minThreshold: 0, maxInteractiveNodes: 2),
          ],
        ),
      );
      addTearDown(controller.dispose);
      var nodeBuildCount = 0;

      await tester.pumpWidget(
        MaterialApp(
          home: SizedBox(
            width: 800,
            height: 600,
            child: Stack(
              children: [
                NodesLayer.middle<String>(controller, (context, node) {
                  nodeBuildCount++;
                  return Text(node.id);
                }),
              ],
            ),
          ),
        ),
      );
      await tester.pump();

      expect(find.byType(NodesThumbnailLayer<String>), findsOneWidget);
      expect(nodeBuildCount, 0);

      controller.lod!.setMaxInteractiveNodes(3);
      await tester.pump();

      expect(find.byType(NodesThumbnailLayer<String>), findsNothing);
      expect(find.text('one'), findsOneWidget);
      expect(find.text('two'), findsOneWidget);
      expect(find.text('three'), findsOneWidget);
      expect(nodeBuildCount, 3);

      controller.lod!.setMaxInteractiveNodes(2);
      await tester.pump();

      expect(find.byType(NodesThumbnailLayer<String>), findsOneWidget);
    },
  );

  testWidgets(
    'removes full node widget subtrees from active navigation frames',
    (tester) async {
      final controller = NodeFlowController<String, dynamic>(
        nodes: [
          createTestNode(id: 'one'),
          createTestNode(id: 'two'),
        ],
        config: NodeFlowConfig(
          plugins: [
            LodPlugin(enabled: true, minThreshold: 0, maxInteractiveNodes: 10),
          ],
        ),
      );
      addTearDown(controller.dispose);
      var nodeBuildCount = 0;

      await tester.pumpWidget(
        MaterialApp(
          home: Stack(
            children: [
              NodesLayer.middle<String>(controller, (context, node) {
                nodeBuildCount++;
                return Text(node.id);
              }),
            ],
          ),
        ),
      );

      expect(find.byType(NodesThumbnailLayer<String>), findsNothing);
      expect(find.text('one'), findsOneWidget);
      expect(find.text('two'), findsOneWidget);
      expect(nodeBuildCount, 2);

      controller.interaction.setViewportInteracting(true);
      await tester.pump();

      expect(find.byType(NodesThumbnailLayer<String>), findsOneWidget);
      expect(find.text('one'), findsNothing);
      expect(find.text('two'), findsNothing);

      controller.interaction.setViewportInteracting(false);
      await tester.pump();

      expect(find.byType(NodesThumbnailLayer<String>), findsNothing);
      expect(find.text('one'), findsOneWidget);
      expect(find.text('two'), findsOneWidget);
    },
  );

  testWidgets('selected nodes remain promoted during painted navigation', (
    tester,
  ) async {
    final controller = NodeFlowController<String, dynamic>(
      nodes: [
        createTestNode(id: 'one'),
        createTestNode(id: 'two'),
      ],
      config: NodeFlowConfig(
        plugins: [
          LodPlugin(enabled: true, minThreshold: 0, maxInteractiveNodes: 10),
        ],
      ),
    );
    addTearDown(controller.dispose);
    controller.selectNode('one');

    await tester.pumpWidget(
      MaterialApp(
        home: Stack(
          children: [
            NodesLayer.middle<String>(
              controller,
              (context, node) => Text(node.id),
            ),
          ],
        ),
      ),
    );

    controller.interaction.setViewportInteracting(true);
    await tester.pump();

    expect(controller.lod!.sceneMode, NodeSceneMode.navigation);
    expect(find.byType(NodesThumbnailLayer<String>), findsOneWidget);
    expect(find.text('one'), findsOneWidget);
    expect(find.text('two'), findsNothing);

    final thumbnail = tester.widget<NodesThumbnailLayer<String>>(
      find.byType(NodesThumbnailLayer<String>),
    );
    expect(thumbnail.nodes!.map((node) => node.id), ['two']);
  });

  testWidgets('editing nodes remain promoted in dense retained scenes', (
    tester,
  ) async {
    final first = createTestNode(id: 'one');
    final controller = NodeFlowController<String, dynamic>(
      nodes: [
        first,
        createTestNode(id: 'two'),
      ],
      config: NodeFlowConfig(
        plugins: [
          LodPlugin(enabled: true, minThreshold: 0, maxInteractiveNodes: 1),
        ],
      ),
    );
    addTearDown(controller.dispose);

    await tester.pumpWidget(
      MaterialApp(
        home: Stack(
          children: [
            NodesLayer.middle<String>(
              controller,
              (context, node) => Text(node.id),
            ),
          ],
        ),
      ),
    );

    expect(controller.lod!.sceneMode, NodeSceneMode.overview);
    expect(find.text('one'), findsNothing);

    first.isEditing = true;
    await tester.pump();

    expect(find.text('one'), findsOneWidget);
    final thumbnail = tester.widget<NodesThumbnailLayer<String>>(
      find.byType(NodesThumbnailLayer<String>),
    );
    expect(thumbnail.nodes!.map((node) => node.id), ['two']);
  });

  testWidgets('live nodes remain widgets over dense retained scenes', (
    tester,
  ) async {
    final controller = NodeFlowController<String, dynamic>(
      nodes: [
        createTestNode(
          id: 'live',
          retainedRendering: RetainedNodeRendering.live,
        ),
        createTestNode(id: 'cached'),
      ],
      config: NodeFlowConfig(
        plugins: [
          LodPlugin(enabled: true, minThreshold: 0, maxInteractiveNodes: 1),
        ],
      ),
    );
    addTearDown(controller.dispose);

    await tester.pumpWidget(
      MaterialApp(
        home: Stack(
          children: [
            NodesLayer.middle<String>(
              controller,
              (context, node) => Text(node.id),
            ),
          ],
        ),
      ),
    );

    expect(find.text('live'), findsOneWidget);
    expect(find.text('cached'), findsNothing);
    final thumbnail = tester.widget<NodesThumbnailLayer<String>>(
      find.byType(NodesThumbnailLayer<String>),
    );
    expect(thumbnail.nodes!.map((node) => node.id), ['cached']);
  });

  testWidgets('retains unchanged node pictures across scene repaints', (
    tester,
  ) async {
    final controller = NodeFlowController<String, dynamic>(
      nodes: [
        createTestNode(id: 'one'),
        createTestNode(id: 'two', position: const Offset(200, 0)),
      ],
      config: NodeFlowConfig(
        plugins: [
          LodPlugin(enabled: true, minThreshold: 0, maxInteractiveNodes: 1),
        ],
      ),
    );
    addTearDown(controller.dispose);
    final paintCounts = <String, int>{};
    bool paintNode(
      Canvas canvas,
      Node<String> node,
      Rect bounds,
      bool isSelected,
    ) {
      paintCounts.update(node.id, (count) => count + 1, ifAbsent: () => 1);
      canvas.drawRect(bounds, Paint()..color = Colors.blue);
      return true;
    }

    await tester.pumpWidget(
      MaterialApp(
        home: SizedBox(
          width: 800,
          height: 600,
          child: Stack(
            children: [
              NodesLayer.middle<String>(
                controller,
                (context, node) => Text(node.id),
                thumbnailBuilder: paintNode,
              ),
            ],
          ),
        ),
      ),
    );
    await tester.pump();

    expect(paintCounts, {'one': 1, 'two': 1});

    controller.moveNode('one', const Offset(20, 0));
    await tester.pump();
    expect(paintCounts, {
      'one': 1,
      'two': 1,
    }, reason: 'position-only changes should reuse node-local pictures');

    controller.selectNode('one');
    await tester.pump();
    expect(paintCounts, {'one': 2, 'two': 1});

    controller.nodes['two']!.invalidateRetainedVisual();
    await tester.pump();
    await tester.pump();
    expect(paintCounts, {'one': 2, 'two': 2});
  });

  testWidgets('repaints a stable retained delegate when its node set changes', (
    tester,
  ) async {
    final controller = NodeFlowController<String, dynamic>(
      nodes: [
        createTestNode(id: 'one'),
        createTestNode(id: 'two'),
      ],
      config: NodeFlowConfig(
        plugins: [
          LodPlugin(enabled: true, minThreshold: 0, maxInteractiveNodes: 1),
        ],
      ),
    );
    addTearDown(controller.dispose);
    final paintCounts = <String, int>{};

    await tester.pumpWidget(
      MaterialApp(
        home: Stack(
          children: [
            NodesLayer.middle<String>(
              controller,
              (context, node) => Text(node.id),
              thumbnailBuilder: (canvas, node, bounds, isSelected) {
                paintCounts.update(
                  node.id,
                  (count) => count + 1,
                  ifAbsent: () => 1,
                );
                return true;
              },
            ),
          ],
        ),
      ),
    );
    await tester.pump();
    expect(paintCounts, {'one': 1, 'two': 1});

    controller.addNode(createTestNode(id: 'three'));
    await tester.pump();
    await tester.pump();

    expect(paintCounts, {
      'one': 1,
      'two': 1,
      'three': 1,
    }, reason: 'the stable painter must schedule paint for a new visible ID');
  });

  testWidgets('retained layer follows a replacement controller', (
    tester,
  ) async {
    final first = NodeFlowController<String, dynamic>(
      nodes: [createTestNode(id: 'first')],
    );
    final second = NodeFlowController<String, dynamic>(
      nodes: [createTestNode(id: 'second')],
    );
    addTearDown(first.dispose);
    addTearDown(second.dispose);
    final paintedIds = <String>[];

    Widget buildLayer(NodeFlowController<String, dynamic> controller) {
      return MaterialApp(
        home: Stack(
          children: [
            NodesThumbnailLayer<String>(
              controller: controller,
              thumbnailBuilder: (canvas, node, bounds, isSelected) {
                paintedIds.add(node.id);
                return true;
              },
            ),
          ],
        ),
      );
    }

    await tester.pumpWidget(buildLayer(first));
    await tester.pump();
    expect(paintedIds, ['first']);

    paintedIds.clear();
    await tester.pumpWidget(buildLayer(second));
    await tester.pump();
    expect(paintedIds, ['second']);
  });

  testWidgets('dragged note remains a full widget in dense overview', (
    tester,
  ) async {
    final controller = NodeFlowController<String, dynamic>(
      nodes: [
        createTestCommentNode<String>(
          id: 'note-one',
          text: 'Keep this note visible',
          data: 'one',
        ),
        createTestCommentNode<String>(
          id: 'note-two',
          position: const Offset(250, 0),
          text: 'Painted neighbor',
          data: 'two',
        ),
      ],
      config: NodeFlowConfig(
        plugins: [
          LodPlugin(enabled: true, minThreshold: 0, maxInteractiveNodes: 1),
        ],
      ),
    );
    addTearDown(controller.dispose);

    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(extensions: [NodeFlowTheme.light]),
        home: SizedBox(
          width: 800,
          height: 600,
          child: Stack(
            children: [
              NodesLayer.foreground<String>(
                controller,
                (context, node) => Text(node.id),
              ),
            ],
          ),
        ),
      ),
    );
    await tester.pump();

    expect(controller.lod!.sceneMode, NodeSceneMode.overview);
    expect(find.text('Keep this note visible'), findsNothing);

    controller.startNodeDrag('note-one');
    await tester.pump();

    expect(find.text('Keep this note visible'), findsOneWidget);
    final thumbnail = tester.widget<NodesThumbnailLayer<String>>(
      find.byType(NodesThumbnailLayer<String>),
    );
    expect(thumbnail.nodes!.map((node) => node.id), ['note-two']);

    controller.endNodeDrag();
    await tester.pump();
    expect(find.text('Keep this note visible'), findsNothing);
  });

  testWidgets('empty widget layer allocates no full-canvas render objects', (
    tester,
  ) async {
    final controller = NodeFlowController<String, dynamic>(
      config: NodeFlowConfig(plugins: [LodPlugin(enabled: false)]),
    );
    addTearDown(controller.dispose);

    await tester.pumpWidget(
      MaterialApp(
        home: NodesLayer.middle<String>(
          controller,
          (context, node) => Text(node.id),
        ),
      ),
    );

    final layer = find.byType(NodesLayer<String>);
    expect(
      find.descendant(
        of: layer,
        matching: find.byType(UnboundedRepaintBoundary),
      ),
      findsNothing,
    );
    expect(
      find.descendant(of: layer, matching: find.byType(CustomPaint)),
      findsNothing,
    );
  });

  testWidgets(
    'overview allocates a full-canvas painter only for non-empty z-layers',
    (tester) async {
      final controller = NodeFlowController<String, dynamic>(
        nodes: [
          createTestNode(id: 'one'),
          createTestNode(id: 'two'),
          createTestNode(id: 'three'),
        ],
        config: NodeFlowConfig(
          plugins: [
            LodPlugin(enabled: true, minThreshold: 0, maxInteractiveNodes: 1),
          ],
        ),
      );
      addTearDown(controller.dispose);

      Widget nodeBuilder(BuildContext context, Node<String> node) =>
          Text(node.id);

      await tester.pumpWidget(
        MaterialApp(
          home: Stack(
            children: [
              NodesLayer.background<String>(controller, nodeBuilder),
              NodesLayer.middle<String>(controller, nodeBuilder),
              NodesLayer.foreground<String>(controller, nodeBuilder),
            ],
          ),
        ),
      );

      final layers = find.byType(NodesLayer<String>);
      expect(find.byType(NodesThumbnailLayer<String>), findsOneWidget);
      expect(
        find.descendant(
          of: layers,
          matching: find.byType(UnboundedRepaintBoundary),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(of: layers, matching: find.byType(CustomPaint)),
        findsOneWidget,
      );
    },
  );

  testWidgets('direct empty thumbnail layer allocates no painter or boundary', (
    tester,
  ) async {
    final controller = NodeFlowController<String, dynamic>();
    addTearDown(controller.dispose);

    await tester.pumpWidget(
      MaterialApp(
        home: NodesThumbnailLayer<String>(
          controller: controller,
          thumbnailBuilder: null,
        ),
      ),
    );

    final layer = find.byType(NodesThumbnailLayer<String>);
    expect(
      find.descendant(
        of: layer,
        matching: find.byType(UnboundedRepaintBoundary),
      ),
      findsNothing,
    );
    expect(
      find.descendant(of: layer, matching: find.byType(CustomPaint)),
      findsNothing,
    );
  });
}
