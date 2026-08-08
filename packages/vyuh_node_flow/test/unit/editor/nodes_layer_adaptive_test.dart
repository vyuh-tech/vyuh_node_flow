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
          plugins: [LodPlugin(minThreshold: 0, maxInteractiveNodes: 2)],
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
          plugins: [LodPlugin(minThreshold: 0, maxInteractiveNodes: 10)],
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
        plugins: [LodPlugin(minThreshold: 0, maxInteractiveNodes: 10)],
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
          plugins: [LodPlugin(minThreshold: 0, maxInteractiveNodes: 1)],
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
