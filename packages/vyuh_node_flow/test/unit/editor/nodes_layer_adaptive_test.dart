/// Adaptive overview rendering tests for NodesLayer.
@Tags(['unit'])
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vyuh_node_flow/src/editor/layers/nodes_layer.dart';
import 'package:vyuh_node_flow/src/editor/layers/nodes_thumbnail_layer.dart';
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
}
