/// Unit tests for ResizeApi extension on NodeFlowController.
///
/// Tests cover the resize lifecycle:
/// - startResize: Captures original bounds and initializes resize state
/// - updateResize: Calculates new bounds using absolute positioning
/// - endResize: Commits changes and clears resize state
/// - cancelResize: Reverts to original bounds
@Tags(['unit'])
library;

import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:vyuh_node_flow/vyuh_node_flow.dart';

import '../../helpers/test_factories.dart';

void main() {
  setUp(() {
    resetTestCounters();
  });

  // ===========================================================================
  // startResize Tests
  // ===========================================================================

  group('ResizeApi - startResize', () {
    test('startResize initializes resize state for resizable node', () {
      final group = createTestGroupNode<String>(
        id: 'group-1',
        position: const Offset(100, 100),
        size: const Size(300, 200),
        data: 'test',
      );
      final controller = createTestController(nodes: [group]);

      controller.startResize(
        'group-1',
        ResizeHandle.bottomRight,
        const Offset(400, 300), // globalPosition at bottom-right corner
      );

      expect(controller.isResizing, isTrue);
      expect(controller.resizingNodeId, equals('group-1'));
      expect(
        controller.interaction.currentResizeHandle,
        equals(ResizeHandle.bottomRight),
      );
      expect(controller.interaction.currentOriginalNodeBounds, isNotNull);
      expect(
        controller.interaction.currentOriginalNodeBounds!.topLeft,
        equals(const Offset(100, 100)),
      );
      expect(
        controller.interaction.currentOriginalNodeBounds!.size,
        equals(const Size(300, 200)),
      );
    });

    test('startResize does nothing for non-existent node', () {
      final controller = createTestController();

      controller.startResize(
        'non-existent',
        ResizeHandle.bottomRight,
        const Offset(100, 100),
      );

      expect(controller.isResizing, isFalse);
      expect(controller.resizingNodeId, isNull);
    });

    test('startResize does nothing for non-resizable node', () {
      final node = createTestNode(id: 'regular-node');
      final controller = createTestController(nodes: [node]);

      controller.startResize(
        'regular-node',
        ResizeHandle.bottomRight,
        const Offset(100, 100),
      );

      expect(controller.isResizing, isFalse);
      expect(controller.resizingNodeId, isNull);
    });

    test('startResize works for CommentNode', () {
      final comment = createTestCommentNode<String>(
        id: 'comment-1',
        position: const Offset(50, 50),
        width: 200,
        height: 100,
        data: 'test',
      );
      final controller = createTestController(nodes: [comment]);

      controller.startResize(
        'comment-1',
        ResizeHandle.topLeft,
        const Offset(50, 50),
      );

      expect(controller.isResizing, isTrue);
      expect(controller.resizingNodeId, equals('comment-1'));
    });

    test('startResize captures correct original bounds', () {
      final group = createTestGroupNode<String>(
        id: 'group-1',
        position: const Offset(150, 200),
        size: const Size(400, 300),
        data: 'test',
      );
      final controller = createTestController(nodes: [group]);

      controller.startResize(
        'group-1',
        ResizeHandle.centerRight,
        const Offset(550, 350),
      );

      final originalBounds = controller.interaction.currentOriginalNodeBounds!;
      expect(originalBounds.left, equals(150));
      expect(originalBounds.top, equals(200));
      expect(originalBounds.width, equals(400));
      expect(originalBounds.height, equals(300));
    });

    test('startResize converts global position to graph coordinates', () {
      final group = createTestGroupNode<String>(
        id: 'group-1',
        position: Offset.zero,
        size: const Size(200, 200),
        data: 'test',
      );
      final controller = createTestController(
        nodes: [group],
        initialViewport: createTestViewport(x: 50, y: 50, zoom: 1.0),
      );

      controller.startResize(
        'group-1',
        ResizeHandle.bottomRight,
        const Offset(300, 300), // Global position
      );

      // The start position should be converted from screen to graph coordinates
      expect(controller.interaction.currentResizeStartPosition, isNotNull);
    });
  });

  // ===========================================================================
  // updateResize Tests
  // ===========================================================================

  group('ResizeApi - updateResize', () {
    test('updateResize updates node size', () {
      final group = createTestGroupNode<String>(
        id: 'group-1',
        position: const Offset(100, 100),
        size: const Size(200, 200),
        data: 'test',
      );
      final controller = createTestController(nodes: [group]);

      controller.startResize(
        'group-1',
        ResizeHandle.bottomRight,
        const Offset(300, 300),
      );

      // Move pointer 50 pixels in both directions
      controller.updateResize(const Offset(350, 350));

      final resizedNode = controller.getNode('group-1') as GroupNode<String>;
      expect(resizedNode.size.value.width, greaterThan(200));
      expect(resizedNode.size.value.height, greaterThan(200));
    });

    test('updateResize does nothing when not resizing', () {
      final group = createTestGroupNode<String>(
        id: 'group-1',
        position: const Offset(100, 100),
        size: const Size(200, 200),
        data: 'test',
      );
      final controller = createTestController(nodes: [group]);

      // Try to update without starting resize
      controller.updateResize(const Offset(350, 350));

      final node = controller.getNode('group-1') as GroupNode<String>;
      expect(node.size.value.width, equals(200));
      expect(node.size.value.height, equals(200));
    });

    test('updateResize respects minimum size constraints', () {
      final group = createTestGroupNode<String>(
        id: 'group-1',
        position: const Offset(100, 100),
        size: const Size(300, 200),
        data: 'test',
      );
      final controller = createTestController(nodes: [group]);

      controller.startResize(
        'group-1',
        ResizeHandle.bottomRight,
        const Offset(400, 300),
      );

      // Try to shrink below minimum size
      controller.updateResize(const Offset(110, 110));

      final resizedNode = controller.getNode('group-1') as GroupNode<String>;
      // Should be constrained to minimum size (GroupNode.minSize is Size(100, 60))
      expect(resizedNode.size.value.width, greaterThanOrEqualTo(100));
      expect(resizedNode.size.value.height, greaterThanOrEqualTo(60));
    });

    test('updateResize tracks drift when constrained', () {
      final group = createTestGroupNode<String>(
        id: 'group-1',
        position: const Offset(100, 100),
        size: const Size(300, 200),
        data: 'test',
      );
      final controller = createTestController(nodes: [group]);

      controller.startResize(
        'group-1',
        ResizeHandle.bottomRight,
        const Offset(400, 300),
      );

      // Try to shrink significantly - should hit constraints and create drift
      controller.updateResize(const Offset(50, 50));

      // Drift should be tracked when constraints prevent full resize
      expect(controller.interaction.currentHandleDrift, isNotNull);
    });

    test('updateResize handles different resize handles', () {
      for (final handle in ResizeHandle.values) {
        resetTestCounters();
        final group = createTestGroupNode<String>(
          id: 'group-1',
          position: const Offset(100, 100),
          size: const Size(200, 200),
          data: 'test',
        );
        final controller = createTestController(nodes: [group]);

        controller.startResize(
          'group-1',
          handle,
          const Offset(200, 200), // Start position
        );

        // Should not throw for any handle
        expect(
          () => controller.updateResize(const Offset(250, 250)),
          returnsNormally,
        );

        controller.endResize();
      }
    });

    test('updateResize with snap to grid enabled', () {
      final group = createTestGroupNode<String>(
        id: 'group-1',
        position: const Offset(100, 100),
        size: const Size(200, 200),
        data: 'test',
      );
      final controller = createTestController(
        nodes: [group],
        config: NodeFlowConfig(
          extensions: [
            SnapExtension([GridSnapDelegate(gridSize: 20.0)], enabled: true),
          ],
        ),
      );

      controller.startResize(
        'group-1',
        ResizeHandle.bottomRight,
        const Offset(300, 300),
      );

      controller.updateResize(const Offset(327, 347));

      final resizedNode = controller.getNode('group-1') as GroupNode<String>;
      // Position should be snapped to grid
      expect(resizedNode.visualPosition.value.dx % 20, equals(0));
      expect(resizedNode.visualPosition.value.dy % 20, equals(0));
    });
  });

  // ===========================================================================
  // endResize Tests
  // ===========================================================================

  group('ResizeApi - endResize', () {
    test('endResize clears resize state', () {
      final group = createTestGroupNode<String>(
        id: 'group-1',
        position: const Offset(100, 100),
        size: const Size(200, 200),
        data: 'test',
      );
      final controller = createTestController(nodes: [group]);

      controller.startResize(
        'group-1',
        ResizeHandle.bottomRight,
        const Offset(300, 300),
      );
      expect(controller.isResizing, isTrue);

      controller.endResize();

      expect(controller.isResizing, isFalse);
      expect(controller.resizingNodeId, isNull);
      expect(controller.interaction.currentResizeHandle, isNull);
    });

    test('endResize when not resizing does nothing', () {
      final controller = createTestController();

      // Should not throw
      expect(() => controller.endResize(), returnsNormally);
      expect(controller.isResizing, isFalse);
    });

    test('endResize preserves new size', () {
      final group = createTestGroupNode<String>(
        id: 'group-1',
        position: const Offset(100, 100),
        size: const Size(200, 200),
        data: 'test',
      );
      final controller = createTestController(nodes: [group]);

      controller.startResize(
        'group-1',
        ResizeHandle.bottomRight,
        const Offset(300, 300),
      );
      controller.updateResize(const Offset(400, 400));

      final sizeBeforeEnd =
          (controller.getNode('group-1') as GroupNode<String>).size.value;

      controller.endResize();

      final sizeAfterEnd =
          (controller.getNode('group-1') as GroupNode<String>).size.value;
      expect(sizeAfterEnd, equals(sizeBeforeEnd));
    });
  });

  // ===========================================================================
  // cancelResize Tests
  // ===========================================================================

  group('ResizeApi - cancelResize', () {
    test('cancelResize reverts to original size', () {
      final group = createTestGroupNode<String>(
        id: 'group-1',
        position: const Offset(100, 100),
        size: const Size(200, 200),
        data: 'test',
      );
      final controller = createTestController(nodes: [group]);

      controller.startResize(
        'group-1',
        ResizeHandle.bottomRight,
        const Offset(300, 300),
      );
      controller.updateResize(const Offset(500, 500)); // Resize to larger size

      controller.cancelResize();

      final node = controller.getNode('group-1') as GroupNode<String>;
      expect(node.size.value, equals(const Size(200, 200)));
      expect(node.position.value, equals(const Offset(100, 100)));
    });

    test('cancelResize clears resize state', () {
      final group = createTestGroupNode<String>(
        id: 'group-1',
        position: const Offset(100, 100),
        size: const Size(200, 200),
        data: 'test',
      );
      final controller = createTestController(nodes: [group]);

      controller.startResize(
        'group-1',
        ResizeHandle.bottomRight,
        const Offset(300, 300),
      );

      controller.cancelResize();

      expect(controller.isResizing, isFalse);
      expect(controller.resizingNodeId, isNull);
    });

    test('cancelResize when not resizing does nothing', () {
      final controller = createTestController();

      // Should not throw
      expect(() => controller.cancelResize(), returnsNormally);
    });

    test('cancelResize fires onResizeCancel event', () {
      Node<String>? cancelledNode;
      final group = createTestGroupNode<String>(
        id: 'group-1',
        position: const Offset(100, 100),
        size: const Size(200, 200),
        data: 'test',
      );
      final controller = createTestController(nodes: [group]);
      controller.updateEvents(
        NodeFlowEvents<String, dynamic>(
          node: NodeEvents<String>(
            onResizeCancel: (node) {
              cancelledNode = node;
            },
          ),
        ),
      );

      controller.startResize(
        'group-1',
        ResizeHandle.bottomRight,
        const Offset(300, 300),
      );
      controller.updateResize(const Offset(400, 400));

      controller.cancelResize();

      expect(cancelledNode, isNotNull);
      expect(cancelledNode!.id, equals('group-1'));
    });

    test('cancelResize reverts position when resizing from top-left', () {
      final group = createTestGroupNode<String>(
        id: 'group-1',
        position: const Offset(200, 200),
        size: const Size(200, 200),
        data: 'test',
      );
      final controller = createTestController(nodes: [group]);

      controller.startResize(
        'group-1',
        ResizeHandle.topLeft,
        const Offset(200, 200),
      );
      controller.updateResize(const Offset(100, 100)); // Move top-left inward

      controller.cancelResize();

      final node = controller.getNode('group-1') as GroupNode<String>;
      expect(node.position.value, equals(const Offset(200, 200)));
      expect(node.size.value, equals(const Size(200, 200)));
    });

    test('cancelResize with snap to grid reverts to snapped position', () {
      final group = createTestGroupNode<String>(
        id: 'group-1',
        position: const Offset(100, 100),
        size: const Size(200, 200),
        data: 'test',
      );
      final controller = createTestController(
        nodes: [group],
        config: NodeFlowConfig(
          extensions: [
            SnapExtension([GridSnapDelegate(gridSize: 20.0)], enabled: true),
          ],
        ),
      );

      controller.startResize(
        'group-1',
        ResizeHandle.bottomRight,
        const Offset(300, 300),
      );
      controller.updateResize(const Offset(400, 400));

      controller.cancelResize();

      final node = controller.getNode('group-1') as GroupNode<String>;
      expect(node.visualPosition.value.dx % 20, equals(0));
      expect(node.visualPosition.value.dy % 20, equals(0));
    });
  });

  // ===========================================================================
  // Full Resize Lifecycle Tests
  // ===========================================================================

  group('ResizeApi - Full Lifecycle', () {
    test('complete resize workflow', () {
      final group = createTestGroupNode<String>(
        id: 'group-1',
        position: const Offset(100, 100),
        size: const Size(200, 200),
        data: 'test',
      );
      final controller = createTestController(nodes: [group]);

      // Start resize
      controller.startResize(
        'group-1',
        ResizeHandle.bottomRight,
        const Offset(300, 300),
      );
      expect(controller.isResizing, isTrue);

      // Update multiple times
      controller.updateResize(const Offset(320, 320));
      controller.updateResize(const Offset(340, 340));
      controller.updateResize(const Offset(360, 360));

      // End resize
      controller.endResize();
      expect(controller.isResizing, isFalse);

      // Size should be larger than original
      final node = controller.getNode('group-1') as GroupNode<String>;
      expect(node.size.value.width, greaterThan(200));
      expect(node.size.value.height, greaterThan(200));
    });

    test('multiple resize operations in sequence', () {
      final group = createTestGroupNode<String>(
        id: 'group-1',
        position: const Offset(100, 100),
        size: const Size(200, 200),
        data: 'test',
      );
      final controller = createTestController(nodes: [group]);

      // First resize
      controller.startResize(
        'group-1',
        ResizeHandle.bottomRight,
        const Offset(300, 300),
      );
      controller.updateResize(const Offset(350, 350));
      controller.endResize();

      final sizeAfterFirst =
          (controller.getNode('group-1') as GroupNode<String>).size.value;

      // Second resize
      controller.startResize(
        'group-1',
        ResizeHandle.centerRight,
        Offset(100 + sizeAfterFirst.width, 200),
      );
      controller.updateResize(Offset(100 + sizeAfterFirst.width + 50, 200));
      controller.endResize();

      // Width should have increased in second resize
      final finalSize =
          (controller.getNode('group-1') as GroupNode<String>).size.value;
      expect(finalSize.width, greaterThan(sizeAfterFirst.width));
    });

    test('resize CommentNode full workflow', () {
      final comment = createTestCommentNode<String>(
        id: 'comment-1',
        position: const Offset(50, 50),
        width: 150,
        height: 100,
        data: 'test',
      );
      final controller = createTestController(nodes: [comment]);

      controller.startResize(
        'comment-1',
        ResizeHandle.bottomRight,
        const Offset(200, 150),
      );
      controller.updateResize(const Offset(300, 200));
      controller.endResize();

      final node = controller.getNode('comment-1') as CommentNode<String>;
      expect(node.size.value.width, greaterThan(150));
      expect(node.size.value.height, greaterThan(100));
    });
  });
}
