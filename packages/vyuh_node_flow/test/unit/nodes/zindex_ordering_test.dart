/// Unit tests for z-index and node ordering in vyuh_node_flow.
///
/// Tests cover:
/// - bringToFront and sendToBack operations
/// - Z-index assignment and initial values
/// - Node sorting by z-index via sortedNodes
/// - Multiple node z-ordering scenarios
/// - bringNodeForward and sendNodeBackward incremental operations
/// - Edge cases and boundary conditions
@Tags(['unit'])
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:vyuh_node_flow/vyuh_node_flow.dart';

import '../../helpers/test_factories.dart';

void main() {
  setUp(() {
    resetTestCounters();
  });

  // ===========================================================================
  // Z-Index Assignment Tests
  // ===========================================================================

  group('Z-Index Assignment', () {
    test('node has default z-index of 0', () {
      final node = createTestNode(id: 'node-1');

      expect(node.currentZIndex, equals(0));
      expect(node.zIndex.value, equals(0));
    });

    test('node uses provided initial z-index', () {
      final node = createTestNode(id: 'node-1', zIndex: 5);

      expect(node.currentZIndex, equals(5));
    });

    test('node can have negative z-index', () {
      final node = createTestNode(id: 'node-1', zIndex: -10);

      expect(node.currentZIndex, equals(-10));
    });

    test('node z-index can be updated directly', () {
      final node = createTestNode(id: 'node-1', zIndex: 0);

      node.currentZIndex = 100;

      expect(node.currentZIndex, equals(100));
      expect(node.zIndex.value, equals(100));
    });

    test('multiple nodes maintain independent z-indices', () {
      final node1 = createTestNode(id: 'node-1', zIndex: 1);
      final node2 = createTestNode(id: 'node-2', zIndex: 5);
      final node3 = createTestNode(id: 'node-3', zIndex: -2);

      expect(node1.currentZIndex, equals(1));
      expect(node2.currentZIndex, equals(5));
      expect(node3.currentZIndex, equals(-2));
    });

    test('nodes can have the same z-index', () {
      final node1 = createTestNode(id: 'node-1', zIndex: 5);
      final node2 = createTestNode(id: 'node-2', zIndex: 5);

      expect(node1.currentZIndex, equals(node2.currentZIndex));
    });
  });

  // ===========================================================================
  // Bring Node To Front Tests
  // ===========================================================================

  group('bringNodeToFront', () {
    test('moves node to highest z-index', () {
      final controller = createTestController();
      controller.addNode(createTestNode(id: 'node-1', zIndex: 0));
      controller.addNode(createTestNode(id: 'node-2', zIndex: 5));
      controller.addNode(createTestNode(id: 'node-3', zIndex: 10));

      controller.bringNodeToFront('node-1');

      final node1 = controller.getNode('node-1')!;
      expect(node1.currentZIndex, greaterThan(10));
    });

    test('moves lowest z-index node to front', () {
      final controller = createTestController();
      controller.addNode(createTestNode(id: 'node-a', zIndex: -5));
      controller.addNode(createTestNode(id: 'node-b', zIndex: 0));
      controller.addNode(createTestNode(id: 'node-c', zIndex: 5));

      controller.bringNodeToFront('node-a');

      final nodeA = controller.getNode('node-a')!;
      final nodeC = controller.getNode('node-c')!;
      expect(nodeA.currentZIndex, greaterThan(nodeC.currentZIndex));
    });

    test('node already at front remains at highest z-index', () {
      final controller = createTestController();
      controller.addNode(createTestNode(id: 'node-1', zIndex: 0));
      controller.addNode(createTestNode(id: 'node-2', zIndex: 10));

      final initialZ = controller.getNode('node-2')!.currentZIndex;
      controller.bringNodeToFront('node-2');

      final node2 = controller.getNode('node-2')!;
      expect(node2.currentZIndex, greaterThanOrEqualTo(initialZ));
    });

    test('does nothing for non-existent node', () {
      final controller = createTestController();
      controller.addNode(createTestNode(id: 'node-1', zIndex: 5));

      // Should not throw
      expect(
        () => controller.bringNodeToFront('non-existent'),
        returnsNormally,
      );

      // Existing node unchanged
      expect(controller.getNode('node-1')!.currentZIndex, equals(5));
    });

    test('works with single node in graph', () {
      final controller = createTestController();
      controller.addNode(createTestNode(id: 'solo', zIndex: 0));

      controller.bringNodeToFront('solo');

      expect(
        controller.getNode('solo')!.currentZIndex,
        greaterThanOrEqualTo(0),
      );
    });

    test('sequential bringToFront creates ascending z-indices', () {
      final controller = createTestController();
      controller.addNode(createTestNode(id: 'node-1', zIndex: 0));
      controller.addNode(createTestNode(id: 'node-2', zIndex: 0));
      controller.addNode(createTestNode(id: 'node-3', zIndex: 0));

      controller.bringNodeToFront('node-1');
      final z1 = controller.getNode('node-1')!.currentZIndex;

      controller.bringNodeToFront('node-2');
      final z2 = controller.getNode('node-2')!.currentZIndex;

      controller.bringNodeToFront('node-3');
      final z3 = controller.getNode('node-3')!.currentZIndex;

      expect(z2, greaterThan(z1));
      expect(z3, greaterThan(z2));
    });

    test('bringToFront does not affect other nodes z-indices', () {
      final controller = createTestController();
      controller.addNode(createTestNode(id: 'node-1', zIndex: 1));
      controller.addNode(createTestNode(id: 'node-2', zIndex: 2));
      controller.addNode(createTestNode(id: 'node-3', zIndex: 3));

      controller.bringNodeToFront('node-1');

      expect(controller.getNode('node-2')!.currentZIndex, equals(2));
      expect(controller.getNode('node-3')!.currentZIndex, equals(3));
    });
  });

  // ===========================================================================
  // Send Node To Back Tests
  // ===========================================================================

  group('sendNodeToBack', () {
    test('moves node to lowest z-index', () {
      final controller = createTestController();
      controller.addNode(createTestNode(id: 'node-1', zIndex: 0));
      controller.addNode(createTestNode(id: 'node-2', zIndex: 5));
      controller.addNode(createTestNode(id: 'node-3', zIndex: 10));

      controller.sendNodeToBack('node-3');

      final node3 = controller.getNode('node-3')!;
      expect(node3.currentZIndex, lessThan(0));
    });

    test('moves highest z-index node to back', () {
      final controller = createTestController();
      controller.addNode(createTestNode(id: 'node-a', zIndex: -5));
      controller.addNode(createTestNode(id: 'node-b', zIndex: 0));
      controller.addNode(createTestNode(id: 'node-c', zIndex: 5));

      controller.sendNodeToBack('node-c');

      final nodeA = controller.getNode('node-a')!;
      final nodeC = controller.getNode('node-c')!;
      expect(nodeC.currentZIndex, lessThan(nodeA.currentZIndex));
    });

    test('node already at back remains at lowest z-index', () {
      final controller = createTestController();
      controller.addNode(createTestNode(id: 'node-1', zIndex: -10));
      controller.addNode(createTestNode(id: 'node-2', zIndex: 5));

      final initialZ = controller.getNode('node-1')!.currentZIndex;
      controller.sendNodeToBack('node-1');

      final node1 = controller.getNode('node-1')!;
      expect(node1.currentZIndex, lessThanOrEqualTo(initialZ));
    });

    test('does nothing for non-existent node', () {
      final controller = createTestController();
      controller.addNode(createTestNode(id: 'node-1', zIndex: 5));

      // Should not throw
      expect(() => controller.sendNodeToBack('non-existent'), returnsNormally);

      // Existing node unchanged
      expect(controller.getNode('node-1')!.currentZIndex, equals(5));
    });

    test('works with single node in graph', () {
      final controller = createTestController();
      controller.addNode(createTestNode(id: 'solo', zIndex: 5));

      controller.sendNodeToBack('solo');

      expect(controller.getNode('solo')!.currentZIndex, lessThanOrEqualTo(5));
    });

    test('sequential sendToBack creates descending z-indices', () {
      final controller = createTestController();
      controller.addNode(createTestNode(id: 'node-1', zIndex: 10));
      controller.addNode(createTestNode(id: 'node-2', zIndex: 10));
      controller.addNode(createTestNode(id: 'node-3', zIndex: 10));

      controller.sendNodeToBack('node-1');
      final z1 = controller.getNode('node-1')!.currentZIndex;

      controller.sendNodeToBack('node-2');
      final z2 = controller.getNode('node-2')!.currentZIndex;

      controller.sendNodeToBack('node-3');
      final z3 = controller.getNode('node-3')!.currentZIndex;

      expect(z2, lessThan(z1));
      expect(z3, lessThan(z2));
    });

    test('sendToBack does not affect other nodes z-indices', () {
      final controller = createTestController();
      controller.addNode(createTestNode(id: 'node-1', zIndex: 1));
      controller.addNode(createTestNode(id: 'node-2', zIndex: 2));
      controller.addNode(createTestNode(id: 'node-3', zIndex: 3));

      controller.sendNodeToBack('node-3');

      expect(controller.getNode('node-1')!.currentZIndex, equals(1));
      expect(controller.getNode('node-2')!.currentZIndex, equals(2));
    });
  });

  // ===========================================================================
  // Bring Node Forward Tests
  // ===========================================================================

  group('bringNodeForward', () {
    test('moves node one step up in z-order', () {
      final controller = createTestController();
      controller.addNode(createTestNode(id: 'node-1', zIndex: 0));
      controller.addNode(createTestNode(id: 'node-2', zIndex: 1));

      controller.bringNodeForward('node-1');

      final node1 = controller.getNode('node-1')!;
      final node2 = controller.getNode('node-2')!;
      expect(node1.currentZIndex, greaterThan(node2.currentZIndex));
    });

    test('swaps z-index with next higher node', () {
      final controller = createTestController();
      controller.addNode(createTestNode(id: 'low', zIndex: 5));
      controller.addNode(createTestNode(id: 'high', zIndex: 10));

      controller.bringNodeForward('low');

      final low = controller.getNode('low')!;
      final high = controller.getNode('high')!;
      expect(low.currentZIndex, equals(10));
      expect(high.currentZIndex, equals(5));
    });

    test('does nothing for node already at front', () {
      final controller = createTestController();
      controller.addNode(createTestNode(id: 'node-1', zIndex: 0));
      controller.addNode(createTestNode(id: 'node-2', zIndex: 10));

      final initialZ = controller.getNode('node-2')!.currentZIndex;
      controller.bringNodeForward('node-2');

      expect(controller.getNode('node-2')!.currentZIndex, equals(initialZ));
    });

    test('handles nodes with same z-index by normalizing', () {
      final controller = createTestController();
      controller.addNode(createTestNode(id: 'node-1', zIndex: 0));
      controller.addNode(createTestNode(id: 'node-2', zIndex: 0));
      controller.addNode(createTestNode(id: 'node-3', zIndex: 0));

      // When z-indices are equal, bringNodeForward should normalize them
      controller.bringNodeForward('node-1');

      // After normalization and swap, node-1 should have moved forward
      final sorted = controller.sortedNodes;

      // node-1 should not be at the very bottom after moving forward
      expect(sorted.last.id, isNot(equals('node-1')));
    });

    test('does nothing for non-existent node', () {
      final controller = createTestController();
      controller.addNode(createTestNode(id: 'node-1', zIndex: 5));

      expect(
        () => controller.bringNodeForward('non-existent'),
        returnsNormally,
      );
      expect(controller.getNode('node-1')!.currentZIndex, equals(5));
    });

    test('works with single node', () {
      final controller = createTestController();
      controller.addNode(createTestNode(id: 'solo', zIndex: 5));

      controller.bringNodeForward('solo');

      // Single node cannot move forward, z-index should remain unchanged
      expect(controller.getNode('solo')!.currentZIndex, equals(5));
    });

    test('multiple forward moves work correctly', () {
      final controller = createTestController();
      controller.addNode(createTestNode(id: 'a', zIndex: 1));
      controller.addNode(createTestNode(id: 'b', zIndex: 2));
      controller.addNode(createTestNode(id: 'c', zIndex: 3));

      // Move 'a' forward twice
      controller.bringNodeForward('a'); // a swaps with b
      controller.bringNodeForward('a'); // a swaps with c

      final sorted = controller.sortedNodes;
      expect(sorted.last.id, equals('a'));
    });
  });

  // ===========================================================================
  // Send Node Backward Tests
  // ===========================================================================

  group('sendNodeBackward', () {
    test('moves node one step down in z-order', () {
      final controller = createTestController();
      controller.addNode(createTestNode(id: 'node-1', zIndex: 0));
      controller.addNode(createTestNode(id: 'node-2', zIndex: 1));

      controller.sendNodeBackward('node-2');

      final node1 = controller.getNode('node-1')!;
      final node2 = controller.getNode('node-2')!;
      expect(node2.currentZIndex, lessThan(node1.currentZIndex));
    });

    test('swaps z-index with next lower node', () {
      final controller = createTestController();
      controller.addNode(createTestNode(id: 'low', zIndex: 5));
      controller.addNode(createTestNode(id: 'high', zIndex: 10));

      controller.sendNodeBackward('high');

      final low = controller.getNode('low')!;
      final high = controller.getNode('high')!;
      expect(high.currentZIndex, equals(5));
      expect(low.currentZIndex, equals(10));
    });

    test('does nothing for node already at back', () {
      final controller = createTestController();
      controller.addNode(createTestNode(id: 'node-1', zIndex: -5));
      controller.addNode(createTestNode(id: 'node-2', zIndex: 10));

      final initialZ = controller.getNode('node-1')!.currentZIndex;
      controller.sendNodeBackward('node-1');

      expect(controller.getNode('node-1')!.currentZIndex, equals(initialZ));
    });

    test('handles nodes with same z-index by normalizing', () {
      final controller = createTestController();
      controller.addNode(createTestNode(id: 'node-1', zIndex: 5));
      controller.addNode(createTestNode(id: 'node-2', zIndex: 5));
      controller.addNode(createTestNode(id: 'node-3', zIndex: 5));

      // When z-indices are equal, sendNodeBackward should normalize them
      controller.sendNodeBackward('node-3');

      // After normalization and swap, node-3 should have moved backward
      final sorted = controller.sortedNodes;

      // node-3 should not be at the very top after moving backward
      expect(sorted.first.id, isNot(equals('node-3')));
    });

    test('does nothing for non-existent node', () {
      final controller = createTestController();
      controller.addNode(createTestNode(id: 'node-1', zIndex: 5));

      expect(
        () => controller.sendNodeBackward('non-existent'),
        returnsNormally,
      );
      expect(controller.getNode('node-1')!.currentZIndex, equals(5));
    });

    test('works with single node', () {
      final controller = createTestController();
      controller.addNode(createTestNode(id: 'solo', zIndex: 5));

      controller.sendNodeBackward('solo');

      // Single node cannot move backward, z-index should remain unchanged
      expect(controller.getNode('solo')!.currentZIndex, equals(5));
    });

    test('multiple backward moves work correctly', () {
      final controller = createTestController();
      controller.addNode(createTestNode(id: 'a', zIndex: 1));
      controller.addNode(createTestNode(id: 'b', zIndex: 2));
      controller.addNode(createTestNode(id: 'c', zIndex: 3));

      // Move 'c' backward twice
      controller.sendNodeBackward('c'); // c swaps with b
      controller.sendNodeBackward('c'); // c swaps with a

      final sorted = controller.sortedNodes;
      expect(sorted.first.id, equals('c'));
    });
  });

  // ===========================================================================
  // Node Sorting by Z-Index Tests
  // ===========================================================================

  group('Node Sorting by Z-Index (sortedNodes)', () {
    test('sortedNodes returns nodes in ascending z-index order', () {
      final controller = createTestController();
      controller.addNode(createTestNode(id: 'mid', zIndex: 5));
      controller.addNode(createTestNode(id: 'low', zIndex: 0));
      controller.addNode(createTestNode(id: 'high', zIndex: 10));

      final sorted = controller.sortedNodes;

      expect(sorted[0].id, equals('low'));
      expect(sorted[1].id, equals('mid'));
      expect(sorted[2].id, equals('high'));
    });

    test('sortedNodes handles negative z-indices', () {
      final controller = createTestController();
      controller.addNode(createTestNode(id: 'positive', zIndex: 5));
      controller.addNode(createTestNode(id: 'zero', zIndex: 0));
      controller.addNode(createTestNode(id: 'negative', zIndex: -5));

      final sorted = controller.sortedNodes;

      expect(sorted[0].id, equals('negative'));
      expect(sorted[1].id, equals('zero'));
      expect(sorted[2].id, equals('positive'));
    });

    test('sortedNodes returns empty list for empty graph', () {
      final controller = createTestController();

      expect(controller.sortedNodes, isEmpty);
    });

    test('sortedNodes returns single node', () {
      final controller = createTestController();
      controller.addNode(createTestNode(id: 'only'));

      final sorted = controller.sortedNodes;

      expect(sorted.length, equals(1));
      expect(sorted[0].id, equals('only'));
    });

    test('sortedNodes handles nodes with equal z-indices', () {
      final controller = createTestController();
      controller.addNode(createTestNode(id: 'a', zIndex: 5));
      controller.addNode(createTestNode(id: 'b', zIndex: 5));
      controller.addNode(createTestNode(id: 'c', zIndex: 5));

      final sorted = controller.sortedNodes;

      expect(sorted.length, equals(3));
      // All should have the same z-index
      expect(sorted[0].currentZIndex, equals(5));
      expect(sorted[1].currentZIndex, equals(5));
      expect(sorted[2].currentZIndex, equals(5));
    });

    test('sortedNodes updates after z-index changes', () {
      final controller = createTestController();
      controller.addNode(createTestNode(id: 'a', zIndex: 0));
      controller.addNode(createTestNode(id: 'b', zIndex: 1));
      controller.addNode(createTestNode(id: 'c', zIndex: 2));

      controller.bringNodeToFront('a');

      final sorted = controller.sortedNodes;

      // 'a' should now be at the end (highest z-index)
      expect(sorted.last.id, equals('a'));
    });

    test('sortedNodes length matches nodeCount', () {
      final controller = createTestController();
      for (var i = 0; i < 20; i++) {
        controller.addNode(createTestNode(id: 'node-$i', zIndex: i % 5));
      }

      expect(controller.sortedNodes.length, equals(controller.nodeCount));
      expect(controller.sortedNodes.length, equals(20));
    });

    test('sortedNodes reflects node removal', () {
      final controller = createTestController();
      controller.addNode(createTestNode(id: 'a', zIndex: 0));
      controller.addNode(createTestNode(id: 'b', zIndex: 1));
      controller.addNode(createTestNode(id: 'c', zIndex: 2));

      controller.removeNode('b');

      final sorted = controller.sortedNodes;
      expect(sorted.length, equals(2));
      expect(sorted.map((n) => n.id), containsAll(['a', 'c']));
      expect(sorted.map((n) => n.id), isNot(contains('b')));
    });

    test('sortedNodes reflects node addition', () {
      final controller = createTestController();
      controller.addNode(createTestNode(id: 'a', zIndex: 0));

      var sorted = controller.sortedNodes;
      expect(sorted.length, equals(1));

      controller.addNode(createTestNode(id: 'b', zIndex: 1));

      sorted = controller.sortedNodes;
      expect(sorted.length, equals(2));
      expect(sorted.last.id, equals('b'));
    });
  });

  // ===========================================================================
  // Multiple Node Z-Ordering Tests
  // ===========================================================================

  group('Multiple Node Z-Ordering', () {
    test('large number of nodes maintains correct order', () {
      final controller = createTestController();
      for (var i = 0; i < 100; i++) {
        controller.addNode(createTestNode(id: 'node-$i', zIndex: i));
      }

      final sorted = controller.sortedNodes;

      for (var i = 0; i < sorted.length - 1; i++) {
        expect(
          sorted[i].currentZIndex,
          lessThanOrEqualTo(sorted[i + 1].currentZIndex),
        );
      }
    });

    test('random z-indices are sorted correctly', () {
      final controller = createTestController();
      final zIndices = [42, -17, 0, 100, -50, 23, 7, -3];
      for (var i = 0; i < zIndices.length; i++) {
        controller.addNode(createTestNode(id: 'node-$i', zIndex: zIndices[i]));
      }

      final sorted = controller.sortedNodes;

      for (var i = 0; i < sorted.length - 1; i++) {
        expect(
          sorted[i].currentZIndex,
          lessThanOrEqualTo(sorted[i + 1].currentZIndex),
        );
      }
    });

    test('mixed bringToFront and sendToBack operations', () {
      final controller = createTestController();
      controller.addNode(createTestNode(id: 'a', zIndex: 0));
      controller.addNode(createTestNode(id: 'b', zIndex: 0));
      controller.addNode(createTestNode(id: 'c', zIndex: 0));

      controller.bringNodeToFront('a');
      controller.sendNodeToBack('c');
      controller.bringNodeToFront('b');

      final sorted = controller.sortedNodes;

      // Order should be: c (back), a (middle), b (front)
      expect(sorted[0].id, equals('c'));
      expect(sorted[2].id, equals('b'));
    });

    test('alternating forward and backward operations', () {
      final controller = createTestController();
      controller.addNode(createTestNode(id: 'a', zIndex: 0));
      controller.addNode(createTestNode(id: 'b', zIndex: 1));
      controller.addNode(createTestNode(id: 'c', zIndex: 2));
      controller.addNode(createTestNode(id: 'd', zIndex: 3));

      controller.bringNodeForward('a');
      controller.sendNodeBackward('d');
      controller.bringNodeForward('c');

      final sorted = controller.sortedNodes;

      // Verify ordering is valid (ascending z-index)
      for (var i = 0; i < sorted.length - 1; i++) {
        expect(
          sorted[i].currentZIndex,
          lessThanOrEqualTo(sorted[i + 1].currentZIndex),
        );
      }
    });

    test('repeated front operations on same node', () {
      final controller = createTestController();
      controller.addNode(createTestNode(id: 'node-1', zIndex: 0));
      controller.addNode(createTestNode(id: 'node-2', zIndex: 1));

      controller.bringNodeToFront('node-1');
      controller.bringNodeToFront('node-1');
      controller.bringNodeToFront('node-1');

      // node-1 should still be at front
      final sorted = controller.sortedNodes;
      expect(sorted.last.id, equals('node-1'));
    });

    test('repeated back operations on same node', () {
      final controller = createTestController();
      controller.addNode(createTestNode(id: 'node-1', zIndex: 0));
      controller.addNode(createTestNode(id: 'node-2', zIndex: 1));

      controller.sendNodeToBack('node-2');
      controller.sendNodeToBack('node-2');
      controller.sendNodeToBack('node-2');

      // node-2 should still be at back
      final sorted = controller.sortedNodes;
      expect(sorted.first.id, equals('node-2'));
    });
  });

  // ===========================================================================
  // Special Node Types Z-Index Tests
  // ===========================================================================

  group('Special Node Types Z-Index', () {
    test('GroupNode default z-index is -1', () {
      final group = createTestGroupNode<String>(id: 'group-1', data: 'test');

      expect(group.currentZIndex, equals(-1));
    });

    test('CommentNode default z-index is 0', () {
      final comment = createTestCommentNode<String>(
        id: 'comment-1',
        data: 'test',
      );

      expect(comment.currentZIndex, equals(0));
    });

    test('GroupNode with custom z-index', () {
      final group = createTestGroupNode<String>(
        id: 'group-1',
        data: 'test',
        zIndex: -10,
      );

      expect(group.currentZIndex, equals(-10));
    });

    test('CommentNode with custom z-index', () {
      final comment = createTestCommentNode<String>(
        id: 'comment-1',
        data: 'test',
        zIndex: 100,
      );

      expect(comment.currentZIndex, equals(100));
    });

    test('mixed node types sort correctly', () {
      final controller = createTestController();
      final group = createTestGroupNode<String>(
        id: 'group',
        data: 'g',
        zIndex: -5,
      );
      final regular = createTestNode(id: 'regular', zIndex: 0);
      final comment = createTestCommentNode<String>(
        id: 'comment',
        data: 'c',
        zIndex: 10,
      );

      controller.addNode(group);
      controller.addNode(regular);
      controller.addNode(comment);

      final sorted = controller.sortedNodes;

      expect(sorted[0].id, equals('group'));
      expect(sorted[1].id, equals('regular'));
      expect(sorted[2].id, equals('comment'));
    });

    test('bringToFront works on GroupNode', () {
      final controller = createTestController();
      final group = createTestGroupNode<String>(
        id: 'group',
        data: 'g',
        zIndex: -5,
      );
      final regular = createTestNode(id: 'regular', zIndex: 10);

      controller.addNode(group);
      controller.addNode(regular);

      controller.bringNodeToFront('group');

      final sorted = controller.sortedNodes;
      expect(sorted.last.id, equals('group'));
    });

    test('sendToBack works on CommentNode', () {
      final controller = createTestController();
      final regular = createTestNode(id: 'regular', zIndex: 0);
      final comment = createTestCommentNode<String>(
        id: 'comment',
        data: 'c',
        zIndex: 10,
      );

      controller.addNode(regular);
      controller.addNode(comment);

      controller.sendNodeToBack('comment');

      final sorted = controller.sortedNodes;
      expect(sorted.first.id, equals('comment'));
    });
  });

  // ===========================================================================
  // Edge Cases
  // ===========================================================================

  group('Edge Cases', () {
    test('operations on empty controller do not throw', () {
      final controller = createTestController();

      expect(() => controller.bringNodeToFront('any'), returnsNormally);
      expect(() => controller.sendNodeToBack('any'), returnsNormally);
      expect(() => controller.bringNodeForward('any'), returnsNormally);
      expect(() => controller.sendNodeBackward('any'), returnsNormally);
    });

    test('z-index with very large positive value', () {
      final controller = createTestController();
      controller.addNode(createTestNode(id: 'node-1', zIndex: 999999));

      expect(controller.getNode('node-1')!.currentZIndex, equals(999999));

      controller.bringNodeToFront('node-1');
      expect(
        controller.getNode('node-1')!.currentZIndex,
        greaterThanOrEqualTo(999999),
      );
    });

    test('z-index with very large negative value', () {
      final controller = createTestController();
      controller.addNode(createTestNode(id: 'node-1', zIndex: -999999));

      expect(controller.getNode('node-1')!.currentZIndex, equals(-999999));

      controller.sendNodeToBack('node-1');
      expect(
        controller.getNode('node-1')!.currentZIndex,
        lessThanOrEqualTo(-999999),
      );
    });

    test('concurrent z-index modifications', () {
      final controller = createTestController();
      for (var i = 0; i < 10; i++) {
        controller.addNode(createTestNode(id: 'node-$i', zIndex: i));
      }

      // Perform many operations
      for (var i = 0; i < 10; i++) {
        if (i % 2 == 0) {
          controller.bringNodeToFront('node-$i');
        } else {
          controller.sendNodeToBack('node-$i');
        }
      }

      // Verify sortedNodes is still valid
      final sorted = controller.sortedNodes;
      expect(sorted.length, equals(10));

      for (var i = 0; i < sorted.length - 1; i++) {
        expect(
          sorted[i].currentZIndex,
          lessThanOrEqualTo(sorted[i + 1].currentZIndex),
        );
      }
    });

    test('z-index operations after node removal', () {
      final controller = createTestController();
      controller.addNode(createTestNode(id: 'a', zIndex: 0));
      controller.addNode(createTestNode(id: 'b', zIndex: 1));
      controller.addNode(createTestNode(id: 'c', zIndex: 2));

      controller.removeNode('b');

      // Operations should still work
      controller.bringNodeToFront('a');
      controller.sendNodeToBack('c');

      final sorted = controller.sortedNodes;
      expect(sorted.first.id, equals('c'));
      expect(sorted.last.id, equals('a'));
    });

    test('z-index preserved after removing and re-adding node', () {
      final controller = createTestController();
      controller.addNode(createTestNode(id: 'node-1', zIndex: 5));

      controller.bringNodeToFront('node-1');
      final zAfterBring = controller.getNode('node-1')!.currentZIndex;

      controller.removeNode('node-1');
      controller.addNode(createTestNode(id: 'node-1', zIndex: zAfterBring));

      expect(controller.getNode('node-1')!.currentZIndex, equals(zAfterBring));
    });

    test('sortedNodes is consistent during rapid z-index changes', () {
      final controller = createTestController();
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
  });

  // ===========================================================================
  // Z-Index Observable Reactivity Tests
  // ===========================================================================

  group('Z-Index Observable Reactivity', () {
    test('zIndex observable updates when bringToFront called', () {
      final controller = createTestController();
      final node = createTestNode(id: 'node-1', zIndex: 0);
      controller.addNode(node);
      controller.addNode(createTestNode(id: 'node-2', zIndex: 10));

      final initialZ = node.zIndex.value;
      controller.bringNodeToFront('node-1');

      expect(node.zIndex.value, greaterThan(initialZ));
    });

    test('zIndex observable updates when sendToBack called', () {
      final controller = createTestController();
      final node = createTestNode(id: 'node-1', zIndex: 10);
      controller.addNode(createTestNode(id: 'node-2', zIndex: 0));
      controller.addNode(node);

      final initialZ = node.zIndex.value;
      controller.sendNodeToBack('node-1');

      expect(node.zIndex.value, lessThan(initialZ));
    });

    test('currentZIndex getter and setter work correctly', () {
      final node = createTestNode(id: 'node-1', zIndex: 5);

      expect(node.currentZIndex, equals(5));

      node.currentZIndex = 20;

      expect(node.currentZIndex, equals(20));
      expect(node.zIndex.value, equals(20));
    });
  });
}
