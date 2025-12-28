@Tags(['behavior'])
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:vyuh_node_flow/vyuh_node_flow.dart';

import '../../helpers/test_factories.dart';

void main() {
  late NodeFlowController<String> controller;

  setUp(() {
    controller = createTestController();
  });

  tearDown(() {
    controller.dispose();
  });

  group('Start Node Drag', () {
    test('startNodeDrag initiates drag on existing node', () {
      final node = createTestNode(id: 'node1');
      controller.addNode(node);

      controller.startNodeDrag('node1');

      expect(controller.interaction.draggedNodeId.value, equals('node1'));
    });

    test('startNodeDrag sets node dragging state to true', () {
      final node = createTestNode(id: 'node1');
      controller.addNode(node);

      controller.startNodeDrag('node1');

      expect(node.dragging.value, isTrue);
    });

    test(
      'startNodeDrag does not lock canvas directly (session handles locking)',
      () {
        // Note: Canvas locking is now handled by DragSession in the UI layer,
        // not by controller methods. This test verifies the separation of concerns.
        final node = createTestNode(id: 'node1');
        controller.addNode(node);
        expect(controller.interaction.canvasLocked.value, isFalse);

        controller.startNodeDrag('node1');

        // Controller method does NOT lock canvas - that's the session's job
        expect(controller.interaction.canvasLocked.value, isFalse);
      },
    );

    test('startNodeDrag selects node if not already selected', () {
      final node = createTestNode(id: 'node1');
      controller.addNode(node);
      expect(controller.selectedNodeIds, isEmpty);

      controller.startNodeDrag('node1');

      expect(controller.selectedNodeIds, contains('node1'));
    });

    test('startNodeDrag brings node to front', () {
      final node1 = createTestNode(id: 'node1');
      final node2 = createTestNode(id: 'node2');
      controller.addNode(node1);
      controller.addNode(node2);
      final initialZIndex = node1.zIndex.value;

      controller.startNodeDrag('node1');

      expect(node1.zIndex.value, greaterThan(initialZIndex));
    });

    test('startNodeDrag fires onDragStart callback', () {
      final node = createTestNode(id: 'node1');
      controller.addNode(node);

      Node<String>? draggedNode;
      controller.updateEvents(
        NodeFlowEvents<String>(
          node: NodeEvents<String>(
            onDragStart: (n) {
              draggedNode = n;
            },
          ),
        ),
      );

      controller.startNodeDrag('node1');

      expect(draggedNode?.id, equals('node1'));
    });

    test('startNodeDrag sets dragging on all selected nodes', () {
      final node1 = createTestNode(id: 'node1');
      final node2 = createTestNode(id: 'node2');
      final node3 = createTestNode(id: 'node3');
      controller.addNode(node1);
      controller.addNode(node2);
      controller.addNode(node3);

      // Select multiple nodes
      controller.selectNode('node1');
      controller.selectNode('node2', toggle: true);

      // Start drag from node1
      controller.startNodeDrag('node1');

      // Both selected nodes should be dragging
      expect(node1.dragging.value, isTrue);
      expect(node2.dragging.value, isTrue);
      // Unselected node should not be dragging
      expect(node3.dragging.value, isFalse);
    });

    test('startNodeDrag on non-existent node does not throw', () {
      // This tests graceful handling of invalid IDs
      expect(() => controller.startNodeDrag('non-existent'), returnsNormally);
      expect(
        controller.interaction.draggedNodeId.value,
        equals('non-existent'),
      );
    });
  });

  group('Move Node Drag', () {
    test('moveNodeDrag updates node position', () {
      final node = createTestNode(
        id: 'node1',
        position: const Offset(100, 100),
      );
      controller.addNode(node);
      controller.startNodeDrag('node1');

      controller.moveNodeDrag(const Offset(50, 30));

      expect(node.position.value, equals(const Offset(150, 130)));
    });

    test('moveNodeDrag fires onDrag callback', () {
      final node = createTestNode(
        id: 'node1',
        position: const Offset(100, 100),
      );
      controller.addNode(node);

      Node<String>? movedNode;
      controller.updateEvents(
        NodeFlowEvents<String>(
          node: NodeEvents<String>(
            onDrag: (n) {
              movedNode = n;
            },
          ),
        ),
      );

      controller.startNodeDrag('node1');
      controller.moveNodeDrag(const Offset(50, 30));

      expect(movedNode?.id, equals('node1'));
    });

    test('moveNodeDrag moves all selected nodes together', () {
      final node1 = createTestNode(
        id: 'node1',
        position: const Offset(100, 100),
      );
      final node2 = createTestNode(
        id: 'node2',
        position: const Offset(200, 200),
      );
      controller.addNode(node1);
      controller.addNode(node2);

      // Select both nodes
      controller.selectNode('node1');
      controller.selectNode('node2', toggle: true);

      // Start drag from node1
      controller.startNodeDrag('node1');
      controller.moveNodeDrag(const Offset(50, 30));

      // Both should move by the same delta
      expect(node1.position.value, equals(const Offset(150, 130)));
      expect(node2.position.value, equals(const Offset(250, 230)));
    });

    test('moveNodeDrag does nothing without active drag', () {
      final node = createTestNode(
        id: 'node1',
        position: const Offset(100, 100),
      );
      controller.addNode(node);

      // Don't start drag, just try to move
      controller.moveNodeDrag(const Offset(50, 30));

      expect(node.position.value, equals(const Offset(100, 100)));
    });

    test('moveNodeDrag fires onDrag for each moved node', () {
      final node1 = createTestNode(
        id: 'node1',
        position: const Offset(100, 100),
      );
      final node2 = createTestNode(
        id: 'node2',
        position: const Offset(200, 200),
      );
      controller.addNode(node1);
      controller.addNode(node2);

      final movedNodeIds = <String>[];
      controller.updateEvents(
        NodeFlowEvents<String>(
          node: NodeEvents<String>(
            onDrag: (n) {
              movedNodeIds.add(n.id);
            },
          ),
        ),
      );

      // Select both and drag
      controller.selectNode('node1');
      controller.selectNode('node2', toggle: true);
      controller.startNodeDrag('node1');
      controller.moveNodeDrag(const Offset(50, 30));

      expect(movedNodeIds, containsAll(['node1', 'node2']));
    });

    test('moveNodeDrag accumulates multiple movements', () {
      final node = createTestNode(id: 'node1', position: const Offset(0, 0));
      controller.addNode(node);
      controller.startNodeDrag('node1');

      controller.moveNodeDrag(const Offset(10, 10));
      controller.moveNodeDrag(const Offset(20, 20));
      controller.moveNodeDrag(const Offset(30, 30));

      expect(node.position.value, equals(const Offset(60, 60)));
    });

    test('moveNodeDrag handles negative deltas', () {
      final node = createTestNode(
        id: 'node1',
        position: const Offset(100, 100),
      );
      controller.addNode(node);
      controller.startNodeDrag('node1');

      controller.moveNodeDrag(const Offset(-50, -30));

      expect(node.position.value, equals(const Offset(50, 70)));
    });
  });

  group('End Node Drag', () {
    test('endNodeDrag clears dragging state', () {
      final node = createTestNode(id: 'node1');
      controller.addNode(node);
      controller.startNodeDrag('node1');
      expect(node.dragging.value, isTrue);

      controller.endNodeDrag();

      expect(node.dragging.value, isFalse);
    });

    test('endNodeDrag clears draggedNodeId', () {
      final node = createTestNode(id: 'node1');
      controller.addNode(node);
      controller.startNodeDrag('node1');
      expect(controller.interaction.draggedNodeId.value, isNotNull);

      controller.endNodeDrag();

      expect(controller.interaction.draggedNodeId.value, isNull);
    });

    test(
      'endNodeDrag does not manage canvas lock (session handles locking)',
      () {
        // Note: Canvas locking is now handled by DragSession in the UI layer.
        final node = createTestNode(id: 'node1');
        controller.addNode(node);
        controller.startNodeDrag('node1');
        // Canvas was never locked by startNodeDrag - session handles that
        expect(controller.interaction.canvasLocked.value, isFalse);

        controller.endNodeDrag();

        // Canvas lock state unchanged by controller methods
        expect(controller.interaction.canvasLocked.value, isFalse);
      },
    );

    test('endNodeDrag fires onDragStop callback', () {
      final node = createTestNode(id: 'node1');
      controller.addNode(node);

      Node<String>? stoppedNode;
      controller.updateEvents(
        NodeFlowEvents<String>(
          node: NodeEvents<String>(
            onDragStop: (n) {
              stoppedNode = n;
            },
          ),
        ),
      );

      controller.startNodeDrag('node1');
      controller.endNodeDrag();

      expect(stoppedNode?.id, equals('node1'));
    });

    test('endNodeDrag fires onDragStop for all dragged nodes', () {
      final node1 = createTestNode(id: 'node1');
      final node2 = createTestNode(id: 'node2');
      controller.addNode(node1);
      controller.addNode(node2);

      final stoppedNodeIds = <String>[];
      controller.updateEvents(
        NodeFlowEvents<String>(
          node: NodeEvents<String>(
            onDragStop: (n) {
              stoppedNodeIds.add(n.id);
            },
          ),
        ),
      );

      // Select and drag both
      controller.selectNode('node1');
      controller.selectNode('node2', toggle: true);
      controller.startNodeDrag('node1');
      controller.endNodeDrag();

      expect(stoppedNodeIds, containsAll(['node1', 'node2']));
    });

    test('endNodeDrag does nothing without active drag', () {
      final node = createTestNode(id: 'node1');
      controller.addNode(node);

      // endNodeDrag without startNodeDrag should be safe
      expect(() => controller.endNodeDrag(), returnsNormally);
      expect(controller.interaction.canvasLocked.value, isFalse);
    });

    test('endNodeDrag clears dragging on all affected nodes', () {
      final node1 = createTestNode(id: 'node1');
      final node2 = createTestNode(id: 'node2');
      controller.addNode(node1);
      controller.addNode(node2);

      controller.selectNode('node1');
      controller.selectNode('node2', toggle: true);
      controller.startNodeDrag('node1');

      expect(node1.dragging.value, isTrue);
      expect(node2.dragging.value, isTrue);

      controller.endNodeDrag();

      expect(node1.dragging.value, isFalse);
      expect(node2.dragging.value, isFalse);
    });
  });

  group('Complete Drag Sequence', () {
    test('full drag sequence: start → move → end', () {
      final node = createTestNode(id: 'node1', position: const Offset(0, 0));
      controller.addNode(node);

      // Start
      controller.startNodeDrag('node1');
      expect(node.dragging.value, isTrue);
      // Canvas locking is handled by DragSession in UI layer, not controller

      // Move
      controller.moveNodeDrag(const Offset(100, 50));
      expect(node.position.value, equals(const Offset(100, 50)));

      // End
      controller.endNodeDrag();
      expect(node.dragging.value, isFalse);
      // Position should be preserved
      expect(node.position.value, equals(const Offset(100, 50)));
    });

    test('all events fire in correct order during drag sequence', () {
      final node = createTestNode(id: 'node1', position: const Offset(0, 0));
      controller.addNode(node);

      final events = <String>[];
      controller.updateEvents(
        NodeFlowEvents<String>(
          node: NodeEvents<String>(
            onDragStart: (n) => events.add('start'),
            onDrag: (n) => events.add('drag'),
            onDragStop: (n) => events.add('stop'),
          ),
        ),
      );

      controller.startNodeDrag('node1');
      controller.moveNodeDrag(const Offset(10, 10));
      controller.moveNodeDrag(const Offset(10, 10));
      controller.endNodeDrag();

      expect(events, equals(['start', 'drag', 'drag', 'stop']));
    });

    test('multiple sequential drags work correctly', () {
      final node = createTestNode(id: 'node1', position: const Offset(0, 0));
      controller.addNode(node);

      // First drag
      controller.startNodeDrag('node1');
      controller.moveNodeDrag(const Offset(100, 100));
      controller.endNodeDrag();
      expect(node.position.value, equals(const Offset(100, 100)));

      // Second drag
      controller.startNodeDrag('node1');
      controller.moveNodeDrag(const Offset(50, 50));
      controller.endNodeDrag();
      expect(node.position.value, equals(const Offset(150, 150)));
    });

    test('drag different nodes sequentially', () {
      final node1 = createTestNode(id: 'node1', position: const Offset(0, 0));
      final node2 = createTestNode(
        id: 'node2',
        position: const Offset(100, 100),
      );
      controller.addNode(node1);
      controller.addNode(node2);

      // Drag first node
      controller.startNodeDrag('node1');
      controller.moveNodeDrag(const Offset(50, 50));
      controller.endNodeDrag();

      // Drag second node
      controller.startNodeDrag('node2');
      controller.moveNodeDrag(const Offset(25, 25));
      controller.endNodeDrag();

      expect(node1.position.value, equals(const Offset(50, 50)));
      expect(node2.position.value, equals(const Offset(125, 125)));
    });
  });

  group('Drag with Selection Changes', () {
    test('selection changes during drag do not affect ongoing drag', () {
      final node1 = createTestNode(id: 'node1', position: const Offset(0, 0));
      final node2 = createTestNode(
        id: 'node2',
        position: const Offset(100, 100),
      );
      controller.addNode(node1);
      controller.addNode(node2);

      // Select node1 and start drag
      controller.selectNode('node1');
      controller.startNodeDrag('node1');

      // Move
      controller.moveNodeDrag(const Offset(50, 50));

      // Node1 should have moved
      expect(node1.position.value, equals(const Offset(50, 50)));
      // Node2 should not have moved
      expect(node2.position.value, equals(const Offset(100, 100)));

      controller.endNodeDrag();
    });

    test('starting drag on unselected node clears previous selection', () {
      final node1 = createTestNode(id: 'node1');
      final node2 = createTestNode(id: 'node2');
      controller.addNode(node1);
      controller.addNode(node2);

      // Select node2 first
      controller.selectNode('node2');
      expect(controller.selectedNodeIds, equals(['node2']));

      // Start drag on node1 (unselected)
      controller.startNodeDrag('node1');

      // Selection should change to node1
      expect(controller.selectedNodeIds, equals(['node1']));
    });

    test('starting drag on selected node preserves multi-selection', () {
      final node1 = createTestNode(id: 'node1');
      final node2 = createTestNode(id: 'node2');
      controller.addNode(node1);
      controller.addNode(node2);

      // Multi-select both nodes
      controller.selectNode('node1');
      controller.selectNode('node2', toggle: true);
      expect(controller.selectedNodeIds.length, equals(2));

      // Start drag on node1 (already selected)
      controller.startNodeDrag('node1');

      // Multi-selection should be preserved
      expect(controller.selectedNodeIds.length, equals(2));
    });
  });

  group('Drag Edge Cases', () {
    test('drag with zero delta does not change position', () {
      final node = createTestNode(id: 'node1', position: const Offset(50, 50));
      controller.addNode(node);
      controller.startNodeDrag('node1');

      controller.moveNodeDrag(Offset.zero);

      expect(node.position.value, equals(const Offset(50, 50)));
    });

    test('drag handles very large deltas', () {
      final node = createTestNode(id: 'node1', position: const Offset(0, 0));
      controller.addNode(node);
      controller.startNodeDrag('node1');

      controller.moveNodeDrag(const Offset(10000, 10000));

      expect(node.position.value, equals(const Offset(10000, 10000)));
    });

    test('drag to negative coordinates works', () {
      final node = createTestNode(id: 'node1', position: const Offset(0, 0));
      controller.addNode(node);
      controller.startNodeDrag('node1');

      controller.moveNodeDrag(const Offset(-500, -300));

      expect(node.position.value, equals(const Offset(-500, -300)));
    });

    test('ending drag when no nodes were dragging is safe', () {
      // Setup with nodes but don't drag
      final node = createTestNode(id: 'node1');
      controller.addNode(node);

      // Should not throw even without a drag operation
      expect(() => controller.endNodeDrag(), returnsNormally);
    });

    test('multiple endNodeDrag calls are safe', () {
      final node = createTestNode(id: 'node1');
      controller.addNode(node);
      controller.startNodeDrag('node1');

      controller.endNodeDrag();
      expect(() => controller.endNodeDrag(), returnsNormally);
      expect(() => controller.endNodeDrag(), returnsNormally);
    });
  });
}
