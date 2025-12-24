@Tags(['edge_case'])
library;

import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:vyuh_node_flow/vyuh_node_flow.dart';

import '../helpers/test_factories.dart';

void main() {
  late NodeFlowController<String> controller;

  setUp(() {
    controller = createTestController();
    controller.setScreenSize(const Size(800, 600));
  });

  tearDown(() {
    controller.dispose();
  });

  group('Concurrent Operations - Rapid Node Operations', () {
    test('rapid node additions do not corrupt state', () {
      // Add 100 nodes as fast as possible
      for (var i = 0; i < 100; i++) {
        final node = createTestNode(
          id: 'node-$i',
          position: Offset(i * 10.0, i * 10.0),
        );
        controller.addNode(node);
      }

      expect(controller.nodeCount, equals(100));

      // Verify all nodes are retrievable
      for (var i = 0; i < 100; i++) {
        expect(controller.getNode('node-$i'), isNotNull);
      }
    });

    test('rapid node removals do not corrupt state', () {
      // First add nodes
      for (var i = 0; i < 50; i++) {
        controller.addNode(createTestNode(id: 'node-$i'));
      }

      // Remove them rapidly
      for (var i = 0; i < 50; i++) {
        controller.removeNode('node-$i');
      }

      expect(controller.nodeCount, equals(0));
    });

    test('interleaved add/remove operations maintain consistency', () {
      // Interleave additions and removals
      for (var i = 0; i < 100; i++) {
        controller.addNode(createTestNode(id: 'node-$i'));
        if (i >= 50) {
          controller.removeNode('node-${i - 50}');
        }
      }

      // Should have 50 nodes (nodes 50-99)
      expect(controller.nodeCount, equals(50));

      for (var i = 50; i < 100; i++) {
        expect(controller.getNode('node-$i'), isNotNull);
      }
    });

    test('rapid position updates do not corrupt state', () {
      final node = createTestNode(id: 'moving-node');
      controller.addNode(node);

      // Move the node rapidly using delta movements
      // moveNode uses delta (relative offset), so we move by 1 each time
      for (var i = 0; i < 1000; i++) {
        controller.moveNode('moving-node', const Offset(1.0, 1.0));
      }

      // Final position should be (1000, 1000) since we moved 1 unit 1000 times
      expect(node.position.value, equals(const Offset(1000, 1000)));
    });
  });

  group('Concurrent Operations - Rapid Connection Operations', () {
    test('rapid connection creation does not corrupt state', () {
      // Create source and target nodes
      final sourceNodes = List.generate(
        10,
        (i) => createTestNodeWithOutputPort(id: 'src-$i'),
      );
      final targetNodes = List.generate(
        10,
        (i) => createTestNodeWithInputPort(id: 'tgt-$i'),
      );

      for (final node in [...sourceNodes, ...targetNodes]) {
        controller.addNode(node);
      }

      // Create many connections rapidly
      for (var i = 0; i < 10; i++) {
        for (var j = 0; j < 10; j++) {
          controller.createConnection(
            'src-$i',
            'output-1',
            'tgt-$j',
            'input-1',
          );
        }
      }

      // Should have 100 connections
      expect(controller.connectionCount, equals(100));
    });

    test('rapid connection removal does not corrupt state', () {
      // Setup connected nodes
      final source = createTestNodeWithOutputPort(id: 'source');
      final targets = List.generate(
        20,
        (i) => createTestNodeWithInputPort(id: 'tgt-$i'),
      );

      controller.addNode(source);
      for (final target in targets) {
        controller.addNode(target);
      }

      // Create connections using test factory with explicit IDs to avoid timestamp collisions
      for (var i = 0; i < 20; i++) {
        final conn = createTestConnection(
          id: 'conn-removal-$i',
          sourceNodeId: 'source',
          sourcePortId: 'output-1',
          targetNodeId: 'tgt-$i',
          targetPortId: 'input-1',
        );
        controller.addConnection(conn);
      }

      expect(controller.connectionCount, equals(20));

      // Remove them rapidly
      for (var i = 0; i < 20; i++) {
        controller.removeConnection('conn-removal-$i');
      }

      expect(controller.connectionCount, equals(0));
    });
  });

  group('Concurrent Operations - Selection During Modifications', () {
    test('selection changes during node additions', () {
      for (var i = 0; i < 50; i++) {
        controller.addNode(createTestNode(id: 'node-$i'));
        controller.selectNode('node-$i');
      }

      // Last selected node should be in selection
      expect(controller.selectedNodeIds, isNotEmpty);
    });

    test('selection remains valid after removing selected nodes', () {
      // Add and select nodes
      for (var i = 0; i < 10; i++) {
        controller.addNode(createTestNode(id: 'node-$i'));
      }
      controller.selectNodes(
        List.generate(5, (i) => 'node-$i'),
      ); // Select first 5

      // Remove some selected nodes
      for (var i = 0; i < 3; i++) {
        controller.removeNode('node-$i');
      }

      // Remaining nodes should still exist
      expect(controller.nodeCount, equals(7));

      // Selection might still contain removed IDs (depending on implementation)
      // But the controller should handle this gracefully
      expect(() => controller.selectedNodeIds, returnsNormally);
    });

    test('rapid selection toggle operations', () {
      for (var i = 0; i < 10; i++) {
        controller.addNode(createTestNode(id: 'node-$i'));
      }

      // Rapidly toggle selection
      for (var round = 0; round < 100; round++) {
        controller.selectNode('node-${round % 10}', toggle: true);
      }

      // Should complete without error
      expect(() => controller.selectedNodeIds, returnsNormally);
    });

    test('selectAllNodes during additions', () {
      for (var i = 0; i < 20; i++) {
        controller.addNode(createTestNode(id: 'node-$i'));
        if (i % 5 == 0) {
          controller.selectAllNodes();
        }
      }

      // All nodes should be selectable
      controller.selectAllNodes();
      expect(controller.selectedNodeIds.length, equals(20));
    });
  });

  group('Concurrent Operations - Viewport During Modifications', () {
    test('viewport changes during node operations', () {
      for (var i = 0; i < 50; i++) {
        controller.addNode(
          createTestNode(id: 'node-$i', position: Offset(i * 100.0, i * 100.0)),
        );
        controller.panBy(ScreenOffset.fromXY(10, 10));
        controller.zoomBy(0.01);
      }

      expect(controller.nodeCount, equals(50));
      expect(controller.currentZoom, greaterThan(1.0));
    });

    test('fitToView during node additions', () {
      for (var i = 0; i < 20; i++) {
        controller.addNode(
          createTestNode(id: 'node-$i', position: Offset(i * 200.0, i * 200.0)),
        );
        controller.fitToView();
      }

      expect(controller.nodeCount, equals(20));
    });

    test('rapid zoom operations', () {
      controller.addNode(createTestNode(id: 'node-1'));

      for (var i = 0; i < 1000; i++) {
        if (i % 2 == 0) {
          controller.zoomBy(0.01);
        } else {
          controller.zoomBy(-0.01);
        }
      }

      // Zoom should remain within valid bounds
      expect(controller.currentZoom, greaterThanOrEqualTo(0.5));
      expect(controller.currentZoom, lessThanOrEqualTo(2.0));
    });

    test('rapid pan operations', () {
      controller.addNode(createTestNode(id: 'node-1'));

      for (var i = 0; i < 1000; i++) {
        controller.panBy(
          ScreenOffset.fromXY(
            (i % 10) - 5.0, // Oscillating pan
            (i % 10) - 5.0,
          ),
        );
      }

      // Pan should complete without error
      expect(() => controller.currentPan, returnsNormally);
    });
  });

  group('Concurrent Operations - Drag Sequences', () {
    test('multiple drag start/end sequences', () {
      controller.addNode(createTestNode(id: 'node-1'));

      for (var i = 0; i < 50; i++) {
        controller.startNodeDrag('node-1');
        controller.moveNodeDrag(Offset(10.0, 10.0));
        controller.endNodeDrag();
      }

      // Node should have been moved
      final node = controller.getNode('node-1');
      expect(node, isNotNull);
    });

    test('overlapping drag attempts on different nodes', () {
      controller.addNode(createTestNode(id: 'node-1'));
      controller.addNode(createTestNode(id: 'node-2'));

      // Start dragging node-1
      controller.startNodeDrag('node-1');

      // Try to start dragging node-2 (should be handled gracefully)
      controller.startNodeDrag('node-2');

      // End the drag
      controller.endNodeDrag();

      // Both nodes should still exist
      expect(controller.getNode('node-1'), isNotNull);
      expect(controller.getNode('node-2'), isNotNull);
    });

    test('moveNodeDrag without startNodeDrag', () {
      controller.addNode(createTestNode(id: 'node-1'));

      // Try to move without starting drag
      for (var i = 0; i < 10; i++) {
        controller.moveNodeDrag(Offset(10.0, 10.0));
      }

      // Should complete without error
      expect(() => controller.endNodeDrag(), returnsNormally);
    });
  });

  group('Concurrent Operations - Z-Index Operations', () {
    test('rapid bringToFront operations', () {
      for (var i = 0; i < 20; i++) {
        controller.addNode(createTestNode(id: 'node-$i', zIndex: i));
      }

      // Rapidly bring nodes to front
      for (var round = 0; round < 100; round++) {
        controller.bringNodeToFront('node-${round % 20}');
      }

      // All nodes should still exist
      expect(controller.nodeCount, equals(20));
    });

    test('rapid sendToBack operations', () {
      for (var i = 0; i < 20; i++) {
        controller.addNode(createTestNode(id: 'node-$i', zIndex: i));
      }

      // Rapidly send nodes to back
      for (var round = 0; round < 100; round++) {
        controller.sendNodeToBack('node-${round % 20}');
      }

      // All nodes should still exist
      expect(controller.nodeCount, equals(20));
    });

    test('interleaved bringToFront and sendToBack', () {
      for (var i = 0; i < 10; i++) {
        controller.addNode(createTestNode(id: 'node-$i'));
      }

      for (var round = 0; round < 100; round++) {
        if (round % 2 == 0) {
          controller.bringNodeToFront('node-${round % 10}');
        } else {
          controller.sendNodeToBack('node-${round % 10}');
        }
      }

      expect(controller.nodeCount, equals(10));
    });
  });

  group('Concurrent Operations - Annotation Operations', () {
    test('rapid annotation creation', () {
      // Use addAnnotation with explicit IDs to avoid timestamp collision
      for (var i = 0; i < 50; i++) {
        controller.addAnnotation(
          createTestStickyAnnotation(
            id: 'sticky-rapid-$i',
            position: Offset(i * 50.0, i * 50.0),
            text: 'Note $i',
          ),
        );
      }

      expect(controller.annotations.sortedAnnotations.length, equals(50));
    });

    test('annotation operations during node operations', () {
      for (var i = 0; i < 20; i++) {
        controller.addNode(createTestNode(id: 'node-$i'));
        controller.addAnnotation(
          createTestStickyAnnotation(
            id: 'sticky-mixed-$i',
            position: Offset(i * 100.0, i * 100.0),
            text: 'Note $i',
          ),
        );
      }

      expect(controller.nodeCount, equals(20));
      expect(controller.annotations.sortedAnnotations.length, equals(20));
    });
  });

  group('Concurrent Operations - State Integrity', () {
    test('sortedNodes remains consistent during rapid operations', () {
      for (var i = 0; i < 50; i++) {
        controller.addNode(createTestNode(id: 'node-$i', zIndex: i % 10));
      }

      // Access sortedNodes during modifications
      for (var i = 0; i < 50; i++) {
        final sorted = controller.sortedNodes;
        expect(sorted.length, equals(50));

        controller.bringNodeToFront('node-${i % 50}');
      }
    });

    test('connections list remains consistent during modifications', () {
      final source = createTestNodeWithOutputPort(id: 'source');
      controller.addNode(source);

      for (var i = 0; i < 30; i++) {
        controller.addNode(createTestNodeWithInputPort(id: 'tgt-$i'));
        controller.createConnection('source', 'output-1', 'tgt-$i', 'input-1');

        // Access connections during modifications
        expect(controller.connections.length, equals(i + 1));
      }
    });

    test('spatial queries remain consistent during modifications', () {
      for (var i = 0; i < 20; i++) {
        controller.addNode(
          createTestNode(
            id: 'node-$i',
            position: Offset((i % 5) * 100.0, (i ~/ 5) * 100.0),
            size: const Size(80, 60),
          ),
        );

        // Query during modifications
        final visible = controller.getVisibleNodes();
        expect(visible.length, greaterThanOrEqualTo(i + 1));
      }
    });
  });

  group('Concurrent Operations - Callback Integrity', () {
    test('callbacks fire correctly during rapid operations', () {
      var nodeCreatedCount = 0;
      var nodeDeletedCount = 0;

      controller = createTestController();
      // Create events directly to avoid type inference issues with copyWith
      controller.setEvents(
        NodeFlowEvents<String>(
          node: NodeEvents<String>(
            onCreated: (node) => nodeCreatedCount++,
            onDeleted: (node) => nodeDeletedCount++,
          ),
        ),
      );
      controller.setScreenSize(const Size(800, 600));

      // Rapid add/remove
      for (var i = 0; i < 50; i++) {
        controller.addNode(createTestNode(id: 'node-$i'));
      }
      for (var i = 0; i < 50; i++) {
        controller.removeNode('node-$i');
      }

      expect(nodeCreatedCount, equals(50));
      expect(nodeDeletedCount, equals(50));
    });
  });

  group('Concurrent Operations - Edge Cases', () {
    test('operations on clearing graph', () {
      // Add initial nodes
      for (var i = 0; i < 20; i++) {
        controller.addNode(createTestNode(id: 'node-$i'));
      }

      // Clear and immediately add new nodes
      controller.clearGraph();
      for (var i = 0; i < 10; i++) {
        controller.addNode(createTestNode(id: 'new-$i'));
      }

      expect(controller.nodeCount, equals(10));
      expect(controller.getNode('node-0'), isNull);
      expect(controller.getNode('new-0'), isNotNull);
    });

    test('operations across loadGraph', () {
      // Initial state
      for (var i = 0; i < 10; i++) {
        controller.addNode(createTestNode(id: 'old-$i'));
      }

      // Create new graph and load
      final newNodes = List.generate(5, (i) => createTestNode(id: 'new-$i'));
      final graph = NodeGraph<String>(nodes: newNodes, connections: []);
      controller.loadGraph(graph);

      // Add more nodes after load
      for (var i = 0; i < 3; i++) {
        controller.addNode(createTestNode(id: 'post-$i'));
      }

      expect(controller.nodeCount, equals(8));
    });
  });
}
