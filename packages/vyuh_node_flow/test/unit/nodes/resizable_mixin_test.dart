/// Unit tests for [ResizableMixin] and [ResizerWidget].
///
/// Tests cover:
/// - ResizeResult data class
/// - ResizableMixin functionality (calculateResize, applyBounds, resize)
/// - Minimum/maximum size constraints
/// - All 8 resize handles (corners and edges)
/// - Drift calculation when constraints are hit
/// - Integration with Node class
/// - ResizerWidget construction and configuration
/// - ResizerConfig copyWith
/// - ResizeHandle cursor and positioning
@Tags(['unit'])
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobx/mobx.dart';
import 'package:vyuh_node_flow/src/editor/resizer_widget.dart';
import 'package:vyuh_node_flow/vyuh_node_flow.dart';

import '../../helpers/test_factories.dart';

// =============================================================================
// Test Resizable Node Implementation
// =============================================================================

/// A simple resizable node for testing the ResizableMixin.
class TestResizableNode<T> extends Node<T> with ResizableMixin<T> {
  TestResizableNode({
    required super.id,
    required super.type,
    required super.position,
    required super.data,
    super.size,
    Size? minSizeOverride,
    Size? maxSizeOverride,
  }) : _minSizeOverride = minSizeOverride,
       _maxSizeOverride = maxSizeOverride;

  final Size? _minSizeOverride;
  final Size? _maxSizeOverride;

  @override
  Size get minSize => _minSizeOverride ?? super.minSize;

  @override
  Size? get maxSize => _maxSizeOverride ?? super.maxSize;
}

/// Creates a test resizable node with sensible defaults.
TestResizableNode<String> createTestResizableNode({
  String? id,
  Offset position = Offset.zero,
  Size size = const Size(200, 150),
  Size? minSize,
  Size? maxSize,
}) {
  return TestResizableNode<String>(
    id: id ?? 'resizable-node',
    type: 'resizable',
    position: position,
    data: 'test-data',
    size: size,
    minSizeOverride: minSize,
    maxSizeOverride: maxSize,
  );
}

void main() {
  setUp(() {
    resetTestCounters();
  });

  // ==========================================================================
  // ResizeResult Tests
  // ==========================================================================
  group('ResizeResult', () {
    test('creates with required newBounds parameter', () {
      const bounds = Rect.fromLTWH(0, 0, 100, 100);
      const result = ResizeResult(newBounds: bounds);

      expect(result.newBounds, equals(bounds));
      expect(result.drift, equals(Offset.zero));
      expect(result.constrainedByMin, isFalse);
      expect(result.constrainedByMax, isFalse);
    });

    test('creates with all optional parameters', () {
      const bounds = Rect.fromLTWH(0, 0, 100, 100);
      const drift = Offset(10, 20);
      const result = ResizeResult(
        newBounds: bounds,
        drift: drift,
        constrainedByMin: true,
        constrainedByMax: false,
      );

      expect(result.newBounds, equals(bounds));
      expect(result.drift, equals(drift));
      expect(result.constrainedByMin, isTrue);
      expect(result.constrainedByMax, isFalse);
    });

    test('uses const constructor', () {
      const result1 = ResizeResult(newBounds: Rect.fromLTWH(0, 0, 100, 100));
      const result2 = ResizeResult(newBounds: Rect.fromLTWH(0, 0, 100, 100));

      expect(identical(result1, result2), isTrue);
    });
  });

  // ==========================================================================
  // ResizableMixin Basic Tests
  // ==========================================================================
  group('ResizableMixin', () {
    group('Capability Indicators', () {
      test('isResizable returns true for resizable node', () {
        final node = createTestResizableNode();

        expect(node.isResizable, isTrue);
      });

      test('base Node.isResizable returns false', () {
        final node = createTestNode();

        expect(node.isResizable, isFalse);
      });
    });

    group('Default Size Constraints', () {
      test('default minSize is 100x60', () {
        final node = createTestResizableNode();

        expect(node.minSize, equals(const Size(100, 60)));
      });

      test('default maxSize is null (unconstrained)', () {
        final node = createTestResizableNode();

        expect(node.maxSize, isNull);
      });

      test('custom minSize can be specified', () {
        final node = createTestResizableNode(minSize: const Size(200, 120));

        expect(node.minSize, equals(const Size(200, 120)));
      });

      test('custom maxSize can be specified', () {
        final node = createTestResizableNode(maxSize: const Size(400, 300));

        expect(node.maxSize, equals(const Size(400, 300)));
      });
    });

    group('applyBounds', () {
      test('updates position and size from bounds', () {
        final node = createTestResizableNode(
          position: const Offset(0, 0),
          size: const Size(200, 150),
        );

        node.applyBounds(const Rect.fromLTWH(100, 50, 300, 200));

        expect(node.position.value, equals(const Offset(100, 50)));
        expect(node.size.value, equals(const Size(300, 200)));
      });

      test('does nothing when isResizable is false', () {
        // Using GroupNode with explicit behavior which has isResizable = false
        final group = createTestGroupNode<String>(
          data: 'test',
          behavior: GroupBehavior.explicit,
          position: const Offset(0, 0),
          size: const Size(200, 150),
        );

        // Attempt to apply bounds - should have no effect
        group.applyBounds(const Rect.fromLTWH(100, 50, 300, 200));

        // GroupNode with explicit behavior has isResizable = false
        // so applyBounds should not change anything
        expect(group.isResizable, isFalse);
      });

      test('updates within MobX action', () {
        final node = createTestResizableNode();
        var reactionCount = 0;

        final disposer = reaction(
          (_) => node.position.value,
          (_) => reactionCount++,
        );

        node.applyBounds(const Rect.fromLTWH(50, 50, 200, 150));

        expect(reactionCount, equals(1));
        disposer();
      });
    });
  });

  // ==========================================================================
  // calculateResize Tests - Corner Handles
  // ==========================================================================
  group('calculateResize - Corner Handles', () {
    test('bottomRight handle expands size correctly', () {
      final node = createTestResizableNode(
        position: const Offset(100, 100),
        size: const Size(200, 150),
      );
      final originalBounds = node.getBounds();
      const startPosition = Offset(300, 250); // Bottom-right corner
      const currentPosition = Offset(350, 300); // Moved 50 right and 50 down

      final result = node.calculateResize(
        handle: ResizeHandle.bottomRight,
        originalBounds: originalBounds,
        startPosition: startPosition,
        currentPosition: currentPosition,
      );

      expect(result.newBounds.left, equals(100));
      expect(result.newBounds.top, equals(100));
      expect(result.newBounds.width, equals(250)); // 200 + 50
      expect(result.newBounds.height, equals(200)); // 150 + 50
    });

    test('topLeft handle moves position and adjusts size', () {
      final node = createTestResizableNode(
        position: const Offset(100, 100),
        size: const Size(200, 150),
      );
      final originalBounds = node.getBounds();
      const startPosition = Offset(100, 100); // Top-left corner
      const currentPosition = Offset(50, 50); // Moved 50 left and 50 up

      final result = node.calculateResize(
        handle: ResizeHandle.topLeft,
        originalBounds: originalBounds,
        startPosition: startPosition,
        currentPosition: currentPosition,
      );

      expect(result.newBounds.left, equals(50));
      expect(result.newBounds.top, equals(50));
      expect(result.newBounds.width, equals(250)); // 200 + 50
      expect(result.newBounds.height, equals(200)); // 150 + 50
    });

    test('topRight handle adjusts correctly', () {
      final node = createTestResizableNode(
        position: const Offset(100, 100),
        size: const Size(200, 150),
      );
      final originalBounds = node.getBounds();
      const startPosition = Offset(300, 100); // Top-right corner
      const currentPosition = Offset(350, 50); // Moved 50 right and 50 up

      final result = node.calculateResize(
        handle: ResizeHandle.topRight,
        originalBounds: originalBounds,
        startPosition: startPosition,
        currentPosition: currentPosition,
      );

      expect(result.newBounds.left, equals(100));
      expect(result.newBounds.top, equals(50));
      expect(result.newBounds.width, equals(250)); // 200 + 50
      expect(result.newBounds.height, equals(200)); // 150 + 50
    });

    test('bottomLeft handle adjusts correctly', () {
      final node = createTestResizableNode(
        position: const Offset(100, 100),
        size: const Size(200, 150),
      );
      final originalBounds = node.getBounds();
      const startPosition = Offset(100, 250); // Bottom-left corner
      const currentPosition = Offset(50, 300); // Moved 50 left and 50 down

      final result = node.calculateResize(
        handle: ResizeHandle.bottomLeft,
        originalBounds: originalBounds,
        startPosition: startPosition,
        currentPosition: currentPosition,
      );

      expect(result.newBounds.left, equals(50));
      expect(result.newBounds.top, equals(100));
      expect(result.newBounds.width, equals(250)); // 200 + 50
      expect(result.newBounds.height, equals(200)); // 150 + 50
    });
  });

  // ==========================================================================
  // calculateResize Tests - Edge Handles
  // ==========================================================================
  group('calculateResize - Edge Handles', () {
    test('centerRight handle only adjusts width', () {
      final node = createTestResizableNode(
        position: const Offset(100, 100),
        size: const Size(200, 150),
      );
      final originalBounds = node.getBounds();
      const startPosition = Offset(300, 175); // Center-right edge
      const currentPosition = Offset(350, 175); // Moved 50 right

      final result = node.calculateResize(
        handle: ResizeHandle.centerRight,
        originalBounds: originalBounds,
        startPosition: startPosition,
        currentPosition: currentPosition,
      );

      expect(result.newBounds.left, equals(100));
      expect(result.newBounds.top, equals(100));
      expect(result.newBounds.width, equals(250)); // 200 + 50
      expect(result.newBounds.height, equals(150)); // Unchanged
    });

    test('centerLeft handle only adjusts width and x position', () {
      final node = createTestResizableNode(
        position: const Offset(100, 100),
        size: const Size(200, 150),
      );
      final originalBounds = node.getBounds();
      const startPosition = Offset(100, 175); // Center-left edge
      const currentPosition = Offset(50, 175); // Moved 50 left

      final result = node.calculateResize(
        handle: ResizeHandle.centerLeft,
        originalBounds: originalBounds,
        startPosition: startPosition,
        currentPosition: currentPosition,
      );

      expect(result.newBounds.left, equals(50));
      expect(result.newBounds.top, equals(100));
      expect(result.newBounds.width, equals(250)); // 200 + 50
      expect(result.newBounds.height, equals(150)); // Unchanged
    });

    test('topCenter handle only adjusts height and y position', () {
      final node = createTestResizableNode(
        position: const Offset(100, 100),
        size: const Size(200, 150),
      );
      final originalBounds = node.getBounds();
      const startPosition = Offset(200, 100); // Top-center edge
      const currentPosition = Offset(200, 50); // Moved 50 up

      final result = node.calculateResize(
        handle: ResizeHandle.topCenter,
        originalBounds: originalBounds,
        startPosition: startPosition,
        currentPosition: currentPosition,
      );

      expect(result.newBounds.left, equals(100));
      expect(result.newBounds.top, equals(50));
      expect(result.newBounds.width, equals(200)); // Unchanged
      expect(result.newBounds.height, equals(200)); // 150 + 50
    });

    test('bottomCenter handle only adjusts height', () {
      final node = createTestResizableNode(
        position: const Offset(100, 100),
        size: const Size(200, 150),
      );
      final originalBounds = node.getBounds();
      const startPosition = Offset(200, 250); // Bottom-center edge
      const currentPosition = Offset(200, 300); // Moved 50 down

      final result = node.calculateResize(
        handle: ResizeHandle.bottomCenter,
        originalBounds: originalBounds,
        startPosition: startPosition,
        currentPosition: currentPosition,
      );

      expect(result.newBounds.left, equals(100));
      expect(result.newBounds.top, equals(100));
      expect(result.newBounds.width, equals(200)); // Unchanged
      expect(result.newBounds.height, equals(200)); // 150 + 50
    });
  });

  // ==========================================================================
  // calculateResize Tests - Minimum Size Constraints
  // ==========================================================================
  group('calculateResize - Minimum Size Constraints', () {
    test('respects minimum width when shrinking from right', () {
      final node = createTestResizableNode(
        position: const Offset(100, 100),
        size: const Size(200, 150),
        minSize: const Size(100, 60),
      );
      final originalBounds = node.getBounds();
      const startPosition = Offset(300, 175); // Right edge
      const currentPosition = Offset(150, 175); // Try to shrink to width 50

      final result = node.calculateResize(
        handle: ResizeHandle.centerRight,
        originalBounds: originalBounds,
        startPosition: startPosition,
        currentPosition: currentPosition,
      );

      expect(result.newBounds.width, equals(100)); // Clamped to min
      expect(result.constrainedByMin, isTrue);
    });

    test('respects minimum width when shrinking from left', () {
      final node = createTestResizableNode(
        position: const Offset(100, 100),
        size: const Size(200, 150),
        minSize: const Size(100, 60),
      );
      final originalBounds = node.getBounds();
      const startPosition = Offset(100, 175); // Left edge
      const currentPosition = Offset(250, 175); // Try to shrink to width 50

      final result = node.calculateResize(
        handle: ResizeHandle.centerLeft,
        originalBounds: originalBounds,
        startPosition: startPosition,
        currentPosition: currentPosition,
      );

      expect(result.newBounds.width, equals(100)); // Clamped to min
      expect(result.newBounds.right, equals(300)); // Right edge preserved
      expect(result.constrainedByMin, isTrue);
    });

    test('respects minimum height when shrinking from bottom', () {
      final node = createTestResizableNode(
        position: const Offset(100, 100),
        size: const Size(200, 150),
        minSize: const Size(100, 60),
      );
      final originalBounds = node.getBounds();
      const startPosition = Offset(200, 250); // Bottom edge
      const currentPosition = Offset(200, 130); // Try to shrink to height 30

      final result = node.calculateResize(
        handle: ResizeHandle.bottomCenter,
        originalBounds: originalBounds,
        startPosition: startPosition,
        currentPosition: currentPosition,
      );

      expect(result.newBounds.height, equals(60)); // Clamped to min
      expect(result.constrainedByMin, isTrue);
    });

    test('respects minimum height when shrinking from top', () {
      final node = createTestResizableNode(
        position: const Offset(100, 100),
        size: const Size(200, 150),
        minSize: const Size(100, 60),
      );
      final originalBounds = node.getBounds();
      const startPosition = Offset(200, 100); // Top edge
      const currentPosition = Offset(200, 220); // Try to shrink to height 30

      final result = node.calculateResize(
        handle: ResizeHandle.topCenter,
        originalBounds: originalBounds,
        startPosition: startPosition,
        currentPosition: currentPosition,
      );

      expect(result.newBounds.height, equals(60)); // Clamped to min
      expect(result.newBounds.bottom, equals(250)); // Bottom edge preserved
      expect(result.constrainedByMin, isTrue);
    });
  });

  // ==========================================================================
  // calculateResize Tests - Maximum Size Constraints
  // ==========================================================================
  group('calculateResize - Maximum Size Constraints', () {
    test('respects maximum width when expanding from right', () {
      final node = createTestResizableNode(
        position: const Offset(100, 100),
        size: const Size(200, 150),
        maxSize: const Size(300, 200),
      );
      final originalBounds = node.getBounds();
      const startPosition = Offset(300, 175); // Right edge
      const currentPosition = Offset(500, 175); // Try to expand to width 400

      final result = node.calculateResize(
        handle: ResizeHandle.centerRight,
        originalBounds: originalBounds,
        startPosition: startPosition,
        currentPosition: currentPosition,
      );

      expect(result.newBounds.width, equals(300)); // Clamped to max
      expect(result.constrainedByMax, isTrue);
    });

    test('respects maximum width when expanding from left', () {
      final node = createTestResizableNode(
        position: const Offset(100, 100),
        size: const Size(200, 150),
        maxSize: const Size(300, 200),
      );
      final originalBounds = node.getBounds();
      const startPosition = Offset(100, 175); // Left edge
      const currentPosition = Offset(-100, 175); // Try to expand to width 400

      final result = node.calculateResize(
        handle: ResizeHandle.centerLeft,
        originalBounds: originalBounds,
        startPosition: startPosition,
        currentPosition: currentPosition,
      );

      expect(result.newBounds.width, equals(300)); // Clamped to max
      expect(result.newBounds.right, equals(300)); // Right edge preserved
      expect(result.constrainedByMax, isTrue);
    });

    test('respects maximum height when expanding from bottom', () {
      final node = createTestResizableNode(
        position: const Offset(100, 100),
        size: const Size(200, 150),
        maxSize: const Size(300, 200),
      );
      final originalBounds = node.getBounds();
      const startPosition = Offset(200, 250); // Bottom edge
      const currentPosition = Offset(200, 400); // Try to expand to height 300

      final result = node.calculateResize(
        handle: ResizeHandle.bottomCenter,
        originalBounds: originalBounds,
        startPosition: startPosition,
        currentPosition: currentPosition,
      );

      expect(result.newBounds.height, equals(200)); // Clamped to max
      expect(result.constrainedByMax, isTrue);
    });

    test('respects maximum height when expanding from top', () {
      final node = createTestResizableNode(
        position: const Offset(100, 100),
        size: const Size(200, 150),
        maxSize: const Size(300, 200),
      );
      final originalBounds = node.getBounds();
      const startPosition = Offset(200, 100); // Top edge
      const currentPosition = Offset(200, -50); // Try to expand to height 300

      final result = node.calculateResize(
        handle: ResizeHandle.topCenter,
        originalBounds: originalBounds,
        startPosition: startPosition,
        currentPosition: currentPosition,
      );

      expect(result.newBounds.height, equals(200)); // Clamped to max
      expect(result.newBounds.bottom, equals(250)); // Bottom edge preserved
      expect(result.constrainedByMax, isTrue);
    });

    test('no max constraint when maxSize is null', () {
      final node = createTestResizableNode(
        position: const Offset(100, 100),
        size: const Size(200, 150),
        maxSize: null, // No maximum
      );
      final originalBounds = node.getBounds();
      const startPosition = Offset(300, 250);
      const currentPosition = Offset(1000, 1000); // Very large expansion

      final result = node.calculateResize(
        handle: ResizeHandle.bottomRight,
        originalBounds: originalBounds,
        startPosition: startPosition,
        currentPosition: currentPosition,
      );

      expect(result.newBounds.width, equals(900)); // 200 + 700
      expect(result.newBounds.height, equals(900)); // 150 + 750
      expect(result.constrainedByMax, isFalse);
    });
  });

  // ==========================================================================
  // calculateResize Tests - Drift Calculation
  // ==========================================================================
  group('calculateResize - Drift Calculation', () {
    test('drift is zero when no constraints hit', () {
      final node = createTestResizableNode(
        position: const Offset(100, 100),
        size: const Size(200, 150),
      );
      final originalBounds = node.getBounds();
      const startPosition = Offset(300, 250);
      const currentPosition = Offset(350, 300);

      final result = node.calculateResize(
        handle: ResizeHandle.bottomRight,
        originalBounds: originalBounds,
        startPosition: startPosition,
        currentPosition: currentPosition,
      );

      expect(result.drift, equals(Offset.zero));
    });

    test('drift is non-zero when min constraint hit', () {
      final node = createTestResizableNode(
        position: const Offset(100, 100),
        size: const Size(200, 150),
        minSize: const Size(100, 60),
      );
      final originalBounds = node.getBounds();
      const startPosition = Offset(300, 250);
      const currentPosition = Offset(150, 130); // Try to shrink past minimum

      final result = node.calculateResize(
        handle: ResizeHandle.bottomRight,
        originalBounds: originalBounds,
        startPosition: startPosition,
        currentPosition: currentPosition,
      );

      expect(result.constrainedByMin, isTrue);
      expect(result.drift.dx, isNonZero);
      expect(result.drift.dy, isNonZero);
    });

    test('drift is non-zero when max constraint hit', () {
      final node = createTestResizableNode(
        position: const Offset(100, 100),
        size: const Size(200, 150),
        maxSize: const Size(300, 200),
      );
      final originalBounds = node.getBounds();
      const startPosition = Offset(300, 250);
      const currentPosition = Offset(500, 400); // Try to expand past maximum

      final result = node.calculateResize(
        handle: ResizeHandle.bottomRight,
        originalBounds: originalBounds,
        startPosition: startPosition,
        currentPosition: currentPosition,
      );

      expect(result.constrainedByMax, isTrue);
      expect(result.drift.dx, isNonZero);
      expect(result.drift.dy, isNonZero);
    });
  });

  // ==========================================================================
  // resize() Convenience Method Tests
  // ==========================================================================
  group('resize() Convenience Method', () {
    test('combines calculateResize and applyBounds', () {
      final node = createTestResizableNode(
        position: const Offset(100, 100),
        size: const Size(200, 150),
      );
      final originalBounds = node.getBounds();
      const startPosition = Offset(300, 250);
      const currentPosition = Offset(350, 300);

      final result = node.resize(
        handle: ResizeHandle.bottomRight,
        originalBounds: originalBounds,
        startPosition: startPosition,
        currentPosition: currentPosition,
      );

      // Check that bounds were applied
      expect(node.position.value, equals(const Offset(100, 100)));
      expect(node.size.value, equals(const Size(250, 200)));

      // Check that result is returned
      expect(result.newBounds.width, equals(250));
      expect(result.newBounds.height, equals(200));
    });

    test('returns ResizeResult for inspection', () {
      final node = createTestResizableNode(
        position: const Offset(100, 100),
        size: const Size(200, 150),
        minSize: const Size(100, 60),
      );
      final originalBounds = node.getBounds();
      const startPosition = Offset(300, 250);
      const currentPosition = Offset(150, 130); // Hit min constraint

      final result = node.resize(
        handle: ResizeHandle.bottomRight,
        originalBounds: originalBounds,
        startPosition: startPosition,
        currentPosition: currentPosition,
      );

      expect(result.constrainedByMin, isTrue);
    });
  });

  // ==========================================================================
  // ResizeHandle Extension Tests
  // ==========================================================================
  group('ResizeHandle Extension', () {
    group('cursor', () {
      test('diagonal resize cursor for corner handles', () {
        expect(
          ResizeHandle.topLeft.cursor,
          equals(SystemMouseCursors.resizeUpLeftDownRight),
        );
        expect(
          ResizeHandle.bottomRight.cursor,
          equals(SystemMouseCursors.resizeUpLeftDownRight),
        );
        expect(
          ResizeHandle.topRight.cursor,
          equals(SystemMouseCursors.resizeUpRightDownLeft),
        );
        expect(
          ResizeHandle.bottomLeft.cursor,
          equals(SystemMouseCursors.resizeUpRightDownLeft),
        );
      });

      test('horizontal resize cursor for left/right handles', () {
        expect(
          ResizeHandle.centerLeft.cursor,
          equals(SystemMouseCursors.resizeLeftRight),
        );
        expect(
          ResizeHandle.centerRight.cursor,
          equals(SystemMouseCursors.resizeLeftRight),
        );
      });

      test('vertical resize cursor for top/bottom handles', () {
        expect(
          ResizeHandle.topCenter.cursor,
          equals(SystemMouseCursors.resizeUpDown),
        );
        expect(
          ResizeHandle.bottomCenter.cursor,
          equals(SystemMouseCursors.resizeUpDown),
        );
      });
    });

    group('isCorner and isEdge', () {
      test('corner handles are identified correctly', () {
        expect(ResizeHandle.topLeft.isCorner, isTrue);
        expect(ResizeHandle.topRight.isCorner, isTrue);
        expect(ResizeHandle.bottomLeft.isCorner, isTrue);
        expect(ResizeHandle.bottomRight.isCorner, isTrue);
      });

      test('edge handles are identified correctly', () {
        expect(ResizeHandle.topCenter.isEdge, isTrue);
        expect(ResizeHandle.bottomCenter.isEdge, isTrue);
        expect(ResizeHandle.centerLeft.isEdge, isTrue);
        expect(ResizeHandle.centerRight.isEdge, isTrue);
      });

      test('corner handles are not edge handles', () {
        expect(ResizeHandle.topLeft.isEdge, isFalse);
        expect(ResizeHandle.bottomRight.isEdge, isFalse);
      });

      test('edge handles are not corner handles', () {
        expect(ResizeHandle.topCenter.isCorner, isFalse);
        expect(ResizeHandle.centerRight.isCorner, isFalse);
      });
    });

    group('edges static getter', () {
      test('returns only edge handles', () {
        final edges = ResizeHandleExtension.edges;

        expect(edges.length, equals(4));
        expect(edges, contains(ResizeHandle.topCenter));
        expect(edges, contains(ResizeHandle.bottomCenter));
        expect(edges, contains(ResizeHandle.centerLeft));
        expect(edges, contains(ResizeHandle.centerRight));
      });

      test('does not contain corner handles', () {
        final edges = ResizeHandleExtension.edges;

        expect(edges, isNot(contains(ResizeHandle.topLeft)));
        expect(edges, isNot(contains(ResizeHandle.topRight)));
        expect(edges, isNot(contains(ResizeHandle.bottomLeft)));
        expect(edges, isNot(contains(ResizeHandle.bottomRight)));
      });
    });

    group('buildEdgeHitArea', () {
      test('returns null for corner handles', () {
        final child = Container();

        expect(
          ResizeHandle.topLeft.buildEdgeHitArea(thickness: 10, child: child),
          isNull,
        );
        expect(
          ResizeHandle.topRight.buildEdgeHitArea(thickness: 10, child: child),
          isNull,
        );
        expect(
          ResizeHandle.bottomLeft.buildEdgeHitArea(thickness: 10, child: child),
          isNull,
        );
        expect(
          ResizeHandle.bottomRight.buildEdgeHitArea(
            thickness: 10,
            child: child,
          ),
          isNull,
        );
      });

      test('returns Positioned widget for edge handles', () {
        final child = Container();

        expect(
          ResizeHandle.topCenter.buildEdgeHitArea(thickness: 10, child: child),
          isA<Positioned>(),
        );
        expect(
          ResizeHandle.bottomCenter.buildEdgeHitArea(
            thickness: 10,
            child: child,
          ),
          isA<Positioned>(),
        );
        expect(
          ResizeHandle.centerLeft.buildEdgeHitArea(thickness: 10, child: child),
          isA<Positioned>(),
        );
        expect(
          ResizeHandle.centerRight.buildEdgeHitArea(
            thickness: 10,
            child: child,
          ),
          isA<Positioned>(),
        );
      });
    });

    group('buildPositioned', () {
      test('returns Positioned widget for all handles', () {
        final child = Container();

        for (final handle in ResizeHandle.values) {
          final positioned = handle.buildPositioned(
            offset: 5,
            hitAreaSize: 20,
            child: child,
          );
          expect(positioned, isA<Positioned>());
        }
      });
    });
  });

  // ==========================================================================
  // ResizerConfig Tests
  // ==========================================================================
  group('ResizerConfig', () {
    test('creates with default values', () {
      const config = ResizerConfig();

      expect(config.minSize, equals(const Size(100, 60)));
      expect(config.maxSize, isNull);
      expect(config.driftThreshold, equals(50.0));
    });

    test('creates with custom values', () {
      const config = ResizerConfig(
        minSize: Size(200, 120),
        maxSize: Size(400, 300),
        driftThreshold: 75.0,
      );

      expect(config.minSize, equals(const Size(200, 120)));
      expect(config.maxSize, equals(const Size(400, 300)));
      expect(config.driftThreshold, equals(75.0));
    });

    test('copyWith replaces specified values', () {
      const original = ResizerConfig(
        minSize: Size(100, 60),
        maxSize: Size(400, 300),
        driftThreshold: 50.0,
      );

      final copy = original.copyWith(
        minSize: const Size(150, 90),
        driftThreshold: 100.0,
      );

      expect(copy.minSize, equals(const Size(150, 90)));
      expect(copy.maxSize, equals(const Size(400, 300))); // Preserved
      expect(copy.driftThreshold, equals(100.0));
    });

    test('copyWith preserves unspecified values', () {
      const original = ResizerConfig(
        minSize: Size(100, 60),
        maxSize: Size(400, 300),
        driftThreshold: 50.0,
      );

      final copy = original.copyWith();

      expect(copy.minSize, equals(original.minSize));
      expect(copy.maxSize, equals(original.maxSize));
      expect(copy.driftThreshold, equals(original.driftThreshold));
    });
  });

  // ==========================================================================
  // ResizerWidget Tests
  // ==========================================================================
  group('ResizerWidget', () {
    test('creates with required parameters', () {
      final widget = ResizerWidget(
        onResizeStart: (_, _) {},
        onResizeUpdate: (_) {},
        onResizeEnd: () {},
        child: Container(),
      );

      expect(widget.handleSize, equals(8.0));
      expect(widget.color, equals(Colors.white));
      expect(widget.borderColor, equals(Colors.blue));
      expect(widget.borderWidth, equals(1.0));
      expect(widget.snapDistance, equals(4.0));
      expect(widget.minSize, equals(const Size(100, 60)));
      expect(widget.maxSize, isNull);
      expect(widget.isResizing, isFalse);
    });

    test('creates with custom parameters', () {
      final widget = ResizerWidget(
        onResizeStart: (_, _) {},
        onResizeUpdate: (_) {},
        onResizeEnd: () {},
        handleSize: 12.0,
        color: Colors.red,
        borderColor: Colors.green,
        borderWidth: 2.0,
        snapDistance: 8.0,
        minSize: const Size(150, 90),
        maxSize: const Size(500, 400),
        isResizing: true,
        child: Container(),
      );

      expect(widget.handleSize, equals(12.0));
      expect(widget.color, equals(Colors.red));
      expect(widget.borderColor, equals(Colors.green));
      expect(widget.borderWidth, equals(2.0));
      expect(widget.snapDistance, equals(8.0));
      expect(widget.minSize, equals(const Size(150, 90)));
      expect(widget.maxSize, equals(const Size(500, 400)));
      expect(widget.isResizing, isTrue);
    });

    testWidgets('renders child widget', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ResizerWidget(
              onResizeStart: (_, _) {},
              onResizeUpdate: (_) {},
              onResizeEnd: () {},
              child: const Text('Test Content'),
            ),
          ),
        ),
      );

      expect(find.text('Test Content'), findsOneWidget);
    });

    testWidgets('renders 8 resize handles', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: SizedBox(
                width: 200,
                height: 150,
                child: ResizerWidget(
                  onResizeStart: (_, _) {},
                  onResizeUpdate: (_) {},
                  onResizeEnd: () {},
                  child: Container(color: Colors.grey),
                ),
              ),
            ),
          ),
        ),
      );

      // Each handle has a Container with decoration (the visible square)
      // We should find 8 of them
      final handleContainers = find.byWidgetPredicate((widget) {
        if (widget is Container) {
          return widget.decoration != null &&
              widget.constraints?.maxWidth == 8.0;
        }
        return false;
      });

      expect(handleContainers, findsNWidgets(8));
    });
  });

  // ==========================================================================
  // Integration Tests with Special Nodes
  // ==========================================================================
  group('Integration with Special Nodes', () {
    group('GroupNode', () {
      test('GroupNode with bounds behavior has ResizableMixin', () {
        final group = createTestGroupNode<String>(
          data: 'test',
          behavior: GroupBehavior.bounds,
        );

        expect(group.isResizable, isTrue);
      });

      test('GroupNode with explicit behavior is not resizable', () {
        final group = createTestGroupNode<String>(
          data: 'test',
          behavior: GroupBehavior.explicit,
        );

        expect(group.isResizable, isFalse);
      });

      test('GroupNode with parent behavior is resizable', () {
        final group = createTestGroupNode<String>(
          data: 'test',
          behavior: GroupBehavior.parent,
        );

        expect(group.isResizable, isTrue);
      });

      test('GroupNode minSize is 100x60', () {
        final group = createTestGroupNode<String>(
          data: 'test',
          behavior: GroupBehavior.bounds,
        );

        expect(group.minSize, equals(const Size(100, 60)));
      });

      test('GroupNode maxSize is null (unconstrained)', () {
        final group = createTestGroupNode<String>(
          data: 'test',
          behavior: GroupBehavior.bounds,
        );

        expect(group.maxSize, isNull);
      });
    });

    group('CommentNode', () {
      test('CommentNode has ResizableMixin', () {
        final comment = createTestCommentNode<String>(data: 'test');

        expect(comment.isResizable, isTrue);
      });

      test('CommentNode minSize is 100x60', () {
        final comment = createTestCommentNode<String>(data: 'test');

        expect(comment.minSize, equals(const Size(100, 60)));
      });

      test('CommentNode maxSize is 600x400', () {
        final comment = createTestCommentNode<String>(data: 'test');

        expect(comment.maxSize, equals(const Size(600, 400)));
      });

      test('CommentNode resize respects min/max constraints', () {
        final comment = createTestCommentNode<String>(
          data: 'test',
          width: 200,
          height: 100,
        );
        final originalBounds = comment.getBounds();

        // Try to shrink below minimum
        final shrinkResult = comment.calculateResize(
          handle: ResizeHandle.bottomRight,
          originalBounds: originalBounds,
          startPosition: originalBounds.bottomRight,
          currentPosition: originalBounds.topLeft + const Offset(50, 30),
        );

        expect(shrinkResult.newBounds.width, greaterThanOrEqualTo(100));
        expect(shrinkResult.newBounds.height, greaterThanOrEqualTo(60));

        // Try to expand above maximum
        final expandResult = comment.calculateResize(
          handle: ResizeHandle.bottomRight,
          originalBounds: originalBounds,
          startPosition: originalBounds.bottomRight,
          currentPosition: originalBounds.bottomRight + const Offset(500, 400),
        );

        expect(expandResult.newBounds.width, lessThanOrEqualTo(600));
        expect(expandResult.newBounds.height, lessThanOrEqualTo(400));
      });
    });
  });

  // ==========================================================================
  // Edge Cases
  // ==========================================================================
  group('Edge Cases', () {
    test('resize with zero delta has no effect', () {
      final node = createTestResizableNode(
        position: const Offset(100, 100),
        size: const Size(200, 150),
      );
      final originalBounds = node.getBounds();
      const startPosition = Offset(300, 250);
      const currentPosition = Offset(300, 250); // Same position - no movement

      final result = node.calculateResize(
        handle: ResizeHandle.bottomRight,
        originalBounds: originalBounds,
        startPosition: startPosition,
        currentPosition: currentPosition,
      );

      expect(result.newBounds, equals(originalBounds));
    });

    test('resize node at origin', () {
      final node = createTestResizableNode(
        position: Offset.zero,
        size: const Size(200, 150),
      );
      final originalBounds = node.getBounds();

      final result = node.resize(
        handle: ResizeHandle.bottomRight,
        originalBounds: originalBounds,
        startPosition: const Offset(200, 150),
        currentPosition: const Offset(250, 200),
      );

      expect(node.position.value, equals(Offset.zero));
      expect(result.newBounds.size, equals(const Size(250, 200)));
    });

    test('resize node at negative coordinates', () {
      final node = createTestResizableNode(
        position: const Offset(-100, -50),
        size: const Size(200, 150),
      );
      final originalBounds = node.getBounds();

      final result = node.resize(
        handle: ResizeHandle.topLeft,
        originalBounds: originalBounds,
        startPosition: const Offset(-100, -50),
        currentPosition: const Offset(-150, -100),
      );

      expect(node.position.value, equals(const Offset(-150, -100)));
      expect(result.newBounds.size, equals(const Size(250, 200)));
    });

    test('very small resize movement', () {
      final node = createTestResizableNode(
        position: const Offset(100, 100),
        size: const Size(200, 150),
      );
      final originalBounds = node.getBounds();

      final result = node.calculateResize(
        handle: ResizeHandle.bottomRight,
        originalBounds: originalBounds,
        startPosition: const Offset(300, 250),
        currentPosition: const Offset(300.5, 250.5), // 0.5 pixel movement
      );

      expect(result.newBounds.width, closeTo(200.5, 0.01));
      expect(result.newBounds.height, closeTo(150.5, 0.01));
    });

    test('resize with both min and max constraints', () {
      final node = createTestResizableNode(
        position: const Offset(100, 100),
        size: const Size(200, 150),
        minSize: const Size(100, 80),
        maxSize: const Size(300, 200),
      );
      final originalBounds = node.getBounds();

      // Try to shrink to minimum
      final shrinkResult = node.calculateResize(
        handle: ResizeHandle.bottomRight,
        originalBounds: originalBounds,
        startPosition: const Offset(300, 250),
        currentPosition: const Offset(150, 130),
      );

      expect(shrinkResult.newBounds.width, equals(100));
      expect(shrinkResult.newBounds.height, equals(80));
      expect(shrinkResult.constrainedByMin, isTrue);

      // Try to expand to maximum
      final expandResult = node.calculateResize(
        handle: ResizeHandle.bottomRight,
        originalBounds: originalBounds,
        startPosition: const Offset(300, 250),
        currentPosition: const Offset(500, 450),
      );

      expect(expandResult.newBounds.width, equals(300));
      expect(expandResult.newBounds.height, equals(200));
      expect(expandResult.constrainedByMax, isTrue);
    });
  });
}
