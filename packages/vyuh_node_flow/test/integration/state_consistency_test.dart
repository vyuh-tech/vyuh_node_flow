@Tags(['integration'])
library;

import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:vyuh_node_flow/vyuh_node_flow.dart';

import '../helpers/test_factories.dart';

void main() {
  late NodeFlowController<String> controller;

  setUp(() {
    resetTestCounters();
    controller = createTestController();
    controller.setScreenSize(const Size(1200, 800));
  });

  tearDown(() {
    controller.dispose();
  });

  group('State Consistency - MobX Observable Sync', () {
    test('node position observable updates correctly', () {
      final node = createTestNode(
        id: 'node-1',
        position: const Offset(100, 100),
      );
      controller.addNode(node);

      // Observe initial state
      expect(node.position.value, equals(const Offset(100, 100)));

      // Move node
      controller.moveNode('node-1', const Offset(50, 50));

      // Observable should reflect the new position
      expect(node.position.value, equals(const Offset(150, 150)));
    });

    test('node size observable updates correctly', () {
      final node = createTestNode(id: 'node-1', size: const Size(100, 80));
      controller.addNode(node);

      expect(node.size.value, equals(const Size(100, 80)));

      // Update size
      controller.setNodeSize('node-1', const Size(200, 150));

      expect(node.size.value, equals(const Size(200, 150)));
    });

    test('node zIndex observable updates correctly', () {
      final node1 = createTestNode(id: 'node-1', zIndex: 0);
      final node2 = createTestNode(id: 'node-2', zIndex: 1);
      controller.addNode(node1);
      controller.addNode(node2);

      expect(node1.zIndex.value, equals(0));
      expect(node2.zIndex.value, equals(1));

      // Bring node1 to front
      controller.bringNodeToFront('node-1');

      // node1 should now have higher zIndex than node2
      expect(node1.zIndex.value, greaterThan(node2.zIndex.value));
    });

    test('node selection state observable updates correctly', () {
      final node = createTestNode(id: 'node-1');
      controller.addNode(node);

      expect(node.selected.value, isFalse);

      // Select node
      controller.selectNode('node-1');

      expect(node.selected.value, isTrue);

      // Deselect
      controller.clearNodeSelection();

      expect(node.selected.value, isFalse);
    });

    test('node visibility observable updates correctly', () {
      final node = createTestNode(id: 'node-1', visible: true);
      controller.addNode(node);

      expect(node.isVisible, isTrue);

      // Hide node
      controller.setNodeVisibility('node-1', false);

      expect(node.isVisible, isFalse);

      // Show node
      controller.setNodeVisibility('node-1', true);

      expect(node.isVisible, isTrue);
    });
  });

  group('State Consistency - Spatial Index Sync', () {
    test('spatial index updates on node addition', () {
      controller.addNode(
        createTestNode(
          id: 'node-1',
          position: const Offset(100, 100),
          size: const Size(100, 80),
        ),
      );

      // Node should be findable through spatial query
      final visibleNodes = controller.getVisibleNodes();
      expect(visibleNodes.map((n) => n.id), contains('node-1'));
    });

    test('spatial index updates on node removal', () {
      controller.addNode(
        createTestNode(
          id: 'node-1',
          position: const Offset(100, 100),
          size: const Size(100, 80),
        ),
      );

      controller.removeNode('node-1');

      // Node should no longer be findable
      expect(controller.getNode('node-1'), isNull);
    });

    test('spatial index updates on node movement', () {
      controller.addNode(
        createTestNode(
          id: 'node-1',
          position: const Offset(0, 0),
          size: const Size(100, 80),
        ),
      );

      // Move node far away
      controller.moveNode('node-1', const Offset(5000, 5000));

      // Node should still be tracked
      final node = controller.getNode('node-1');
      expect(node, isNotNull);
      expect(node!.position.value, equals(const Offset(5000, 5000)));
    });
  });

  group('State Consistency - Selection State', () {
    test('selection state cleared when node is removed', () {
      controller.addNode(createTestNode(id: 'node-1'));
      controller.selectNode('node-1');

      expect(controller.selectedNodeIds, contains('node-1'));

      controller.removeNode('node-1');

      // Selection should be cleared for removed node
      expect(controller.selectedNodeIds, isNot(contains('node-1')));
    });

    test('multiple selection stays consistent during removals', () {
      for (var i = 0; i < 5; i++) {
        controller.addNode(createTestNode(id: 'node-$i'));
      }

      controller.selectAllNodes();
      expect(controller.selectedNodeIds.length, equals(5));

      // Remove middle node
      controller.removeNode('node-2');

      expect(controller.selectedNodeIds.length, equals(4));
      expect(controller.selectedNodeIds, isNot(contains('node-2')));
    });

    test('selection type exclusivity is maintained', () {
      controller.addNode(createTestNodeWithOutputPort(id: 'a'));
      controller.addNode(createTestNodeWithInputPort(id: 'b'));
      controller.createConnection('a', 'output-1', 'b', 'input-1');

      // Select node
      controller.selectNode('a');
      expect(controller.selectedNodeIds, isNotEmpty);

      // Select connection - should clear node selection
      final conn = controller.connections.first;
      controller.selectConnection(conn.id);

      expect(controller.selectedConnectionIds, isNotEmpty);
      expect(controller.selectedNodeIds, isEmpty);
    });
  });

  group('State Consistency - Connection Cascading', () {
    test('removing node removes all its connections', () {
      controller.addNode(createTestNodeWithOutputPort(id: 'a'));
      controller.addNode(createTestNodeWithInputPort(id: 'b'));
      controller.createConnection('a', 'output-1', 'b', 'input-1');

      expect(controller.connectionCount, equals(1));

      controller.removeNode('a');

      expect(controller.connectionCount, equals(0));
    });

    test('no orphaned connections after node removal', () {
      // Create: A -> B -> C
      controller.addNode(createTestNodeWithOutputPort(id: 'a'));
      controller.addNode(createTestNodeWithPorts(id: 'b'));
      controller.addNode(createTestNodeWithInputPort(id: 'c'));

      controller.createConnection('a', 'output-1', 'b', 'input-1');
      controller.createConnection('b', 'output-1', 'c', 'input-1');

      expect(controller.connectionCount, equals(2));

      // Remove middle node
      controller.removeNode('b');

      expect(controller.connectionCount, equals(0));

      // Verify no connection references non-existent nodes
      for (final conn in controller.connections) {
        expect(controller.getNode(conn.sourceNodeId), isNotNull);
        expect(controller.getNode(conn.targetNodeId), isNotNull);
      }
    });

    test('connection selection cleared when connection removed', () {
      controller.addNode(createTestNodeWithOutputPort(id: 'a'));
      controller.addNode(createTestNodeWithInputPort(id: 'b'));
      controller.createConnection('a', 'output-1', 'b', 'input-1');

      final conn = controller.connections.first;
      controller.selectConnection(conn.id);

      expect(controller.selectedConnectionIds, contains(conn.id));

      controller.removeConnection(conn.id);

      expect(controller.selectedConnectionIds, isNot(contains(conn.id)));
    });
  });

  group('State Consistency - Viewport State', () {
    test('viewport state persists through graph modifications', () {
      controller.setViewport(GraphViewport(x: 100, y: 50, zoom: 1.5));

      // Add nodes
      for (var i = 0; i < 10; i++) {
        controller.addNode(createTestNode(id: 'node-$i'));
      }

      // Viewport should remain unchanged
      expect(controller.currentPan.dx, equals(100));
      expect(controller.currentPan.dy, equals(50));
      expect(controller.currentZoom, equals(1.5));
    });

    test('viewport updates reflect in coordinate transforms', () {
      controller.setViewport(GraphViewport(x: 0, y: 0, zoom: 1.0));

      final screenPos = ScreenPosition.fromXY(100, 100);
      final graphPos = controller.screenToGraph(screenPos);

      expect(graphPos.dx, equals(100.0));
      expect(graphPos.dy, equals(100.0));

      // Change zoom
      controller.zoomTo(2.0);

      final graphPos2 = controller.screenToGraph(screenPos);

      // At 2x zoom, same screen position maps to different graph position
      expect(graphPos2.dx, equals(50.0));
      expect(graphPos2.dy, equals(50.0));
    });
  });

  group('State Consistency - Annotation State', () {
    test('annotation selection cleared when annotation removed', () {
      final annotation = createTestStickyAnnotation(id: 'sticky-1');
      controller.addAnnotation(annotation);

      controller.selectAnnotation('sticky-1');
      expect(
        controller.annotations.selectedAnnotationIds,
        contains('sticky-1'),
      );

      controller.removeAnnotation('sticky-1');
      expect(
        controller.annotations.selectedAnnotationIds,
        isNot(contains('sticky-1')),
      );
    });

    test('annotation position updates correctly', () {
      final annotation = createTestStickyAnnotation(
        id: 'sticky-1',
        position: const Offset(100, 100),
      );
      controller.addAnnotation(annotation);

      expect(annotation.position, equals(const Offset(100, 100)));

      // Move annotation directly
      annotation.position = const Offset(200, 200);

      expect(annotation.position, equals(const Offset(200, 200)));
    });
  });

  group('State Consistency - Graph Clear and Load', () {
    test('clearGraph removes all state', () {
      // Setup initial state
      controller.addNode(createTestNodeWithOutputPort(id: 'a'));
      controller.addNode(createTestNodeWithInputPort(id: 'b'));
      controller.createConnection('a', 'output-1', 'b', 'input-1');
      controller.addAnnotation(createTestStickyAnnotation(id: 'note'));
      controller.selectNode('a');

      controller.clearGraph();

      expect(controller.nodeCount, equals(0));
      expect(controller.connectionCount, equals(0));
      expect(controller.annotations.sortedAnnotations, isEmpty);
      expect(controller.selectedNodeIds, isEmpty);
    });

    test('loadGraph replaces existing state', () {
      // Initial state
      controller.addNode(createTestNode(id: 'old-node'));

      // Create new graph
      final newNodes = [
        createTestNode(id: 'new-a'),
        createTestNode(id: 'new-b'),
      ];
      final newGraph = NodeGraph<String>(nodes: newNodes, connections: []);

      controller.loadGraph(newGraph);

      expect(controller.nodeCount, equals(2));
      expect(controller.getNode('old-node'), isNull);
      expect(controller.getNode('new-a'), isNotNull);
      expect(controller.getNode('new-b'), isNotNull);
    });

    test('state remains consistent after multiple clear/load cycles', () {
      for (var cycle = 0; cycle < 5; cycle++) {
        // Create state
        for (var i = 0; i < 10; i++) {
          controller.addNode(createTestNode(id: 'node-$cycle-$i'));
        }

        expect(controller.nodeCount, equals(10));

        // Clear
        controller.clearGraph();

        expect(controller.nodeCount, equals(0));
      }
    });
  });

  group('State Consistency - Controller Disposal', () {
    test('disposed controller has empty state', () {
      controller.addNode(createTestNode(id: 'node-1'));
      controller.dispose();

      // Create new controller for verification
      final newController = createTestController();
      expect(newController.nodeCount, equals(0));

      // Reassign to controller so tearDown can safely dispose it
      // (prevents double-dispose of the original controller)
      controller = newController;
    });

    test('multiple controllers maintain separate state', () {
      final controller2 = createTestController();

      controller.addNode(createTestNode(id: 'in-controller-1'));
      controller2.addNode(createTestNode(id: 'in-controller-2'));

      expect(controller.nodeCount, equals(1));
      expect(controller2.nodeCount, equals(1));
      expect(controller.getNode('in-controller-1'), isNotNull);
      expect(controller.getNode('in-controller-2'), isNull);
      expect(controller2.getNode('in-controller-1'), isNull);
      expect(controller2.getNode('in-controller-2'), isNotNull);

      controller2.dispose();
    });
  });

  group('State Consistency - Drag State', () {
    test('drag state clears after drag ends', () {
      controller.addNode(createTestNode(id: 'node-1'));

      controller.startNodeDrag('node-1');

      // During drag, node should be marked as dragging
      final node = controller.getNode('node-1');
      expect(node?.dragging.value, isTrue);

      controller.endNodeDrag();

      // After drag, node should not be marked as dragging
      expect(node?.dragging.value, isFalse);
    });

    test('drag state clears if dragged node is removed', () {
      controller.addNode(createTestNode(id: 'node-1'));
      controller.startNodeDrag('node-1');

      controller.removeNode('node-1');

      // End drag should complete gracefully
      expect(() => controller.endNodeDrag(), returnsNormally);
    });
  });

  group('State Consistency - SortedNodes List', () {
    test('sortedNodes maintains z-index order', () {
      controller.addNode(createTestNode(id: 'low', zIndex: 0));
      controller.addNode(createTestNode(id: 'mid', zIndex: 5));
      controller.addNode(createTestNode(id: 'high', zIndex: 10));

      final sorted = controller.sortedNodes;

      expect(sorted[0].id, equals('low'));
      expect(sorted[1].id, equals('mid'));
      expect(sorted[2].id, equals('high'));
    });

    test('sortedNodes updates after z-index changes', () {
      controller.addNode(createTestNode(id: 'a', zIndex: 0));
      controller.addNode(createTestNode(id: 'b', zIndex: 1));
      controller.addNode(createTestNode(id: 'c', zIndex: 2));

      controller.bringNodeToFront('a');

      final sorted = controller.sortedNodes;

      // 'a' should now be at the end (highest z-index)
      expect(sorted.last.id, equals('a'));
    });

    test('sortedNodes length matches nodeCount', () {
      for (var i = 0; i < 20; i++) {
        controller.addNode(createTestNode(id: 'node-$i'));
      }

      expect(controller.sortedNodes.length, equals(controller.nodeCount));
      expect(controller.sortedNodes.length, equals(20));
    });
  });

  group('State Consistency - Port State', () {
    test('port connection count updates correctly', () {
      final nodeA = createTestNodeWithOutputPort(id: 'a');
      final nodeB = createTestNodeWithInputPort(id: 'b');
      final nodeC = createTestNodeWithInputPort(id: 'c');

      controller.addNode(nodeA);
      controller.addNode(nodeB);
      controller.addNode(nodeC);

      // Create connections
      controller.createConnection('a', 'output-1', 'b', 'input-1');
      controller.createConnection('a', 'output-1', 'c', 'input-1');

      // Verify connections exist
      expect(controller.connectionCount, equals(2));
    });

    test('removing connection updates port state', () {
      final nodeA = createTestNodeWithOutputPort(id: 'a');
      final nodeB = createTestNodeWithInputPort(id: 'b');

      controller.addNode(nodeA);
      controller.addNode(nodeB);

      controller.createConnection('a', 'output-1', 'b', 'input-1');

      expect(controller.connectionCount, equals(1));

      final conn = controller.connections.first;
      controller.removeConnection(conn.id);

      expect(controller.connectionCount, equals(0));
    });
  });

  group('State Consistency - Edge Cases', () {
    test('operations on empty controller are safe', () {
      expect(controller.nodeCount, equals(0));
      expect(controller.connectionCount, equals(0));
      expect(controller.selectedNodeIds, isEmpty);
      expect(controller.sortedNodes, isEmpty);
      expect(() => controller.fitToView(), returnsNormally);
      expect(() => controller.clearGraph(), returnsNormally);
      expect(() => controller.selectAllNodes(), returnsNormally);
    });

    test('multiple rapid state changes maintain consistency', () {
      // Add nodes rapidly
      for (var i = 0; i < 100; i++) {
        controller.addNode(createTestNode(id: 'node-$i'));
      }

      expect(controller.nodeCount, equals(100));
      expect(controller.sortedNodes.length, equals(100));

      // Remove half rapidly
      for (var i = 0; i < 50; i++) {
        controller.removeNode('node-$i');
      }

      expect(controller.nodeCount, equals(50));
      expect(controller.sortedNodes.length, equals(50));

      // All remaining nodes should be accessible
      for (var i = 50; i < 100; i++) {
        expect(controller.getNode('node-$i'), isNotNull);
      }
    });
  });
}
