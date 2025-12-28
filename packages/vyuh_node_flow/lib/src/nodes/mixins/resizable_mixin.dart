import 'package:flutter/widgets.dart';
import 'package:mobx/mobx.dart';

import '../../editor/resizer_widget.dart' show ResizeHandle;
import '../node.dart';

/// Result of a resize calculation including drift tracking.
///
/// This class encapsulates all the information needed to apply a resize
/// operation, including whether constraints were hit.
class ResizeResult {
  /// The calculated bounds respecting all constraints.
  final Rect newBounds;

  /// Offset between expected handle position and pointer position.
  ///
  /// When constraints prevent resizing, the pointer can move away from
  /// where the handle "should be". This tracks that drift.
  final Offset drift;

  /// True if minimum size constraint was applied.
  final bool constrainedByMin;

  /// True if maximum size constraint was applied.
  final bool constrainedByMax;

  const ResizeResult({
    required this.newBounds,
    this.drift = Offset.zero,
    this.constrainedByMin = false,
    this.constrainedByMax = false,
  });
}

/// Mixin providing resize functionality for nodes.
///
/// This mixin handles resize operations through 8 handle positions:
/// - 4 corners: topLeft, topRight, bottomLeft, bottomRight
/// - 4 edge midpoints: topCenter, centerLeft, centerRight, bottomCenter
///
/// The resize operation respects minimum and maximum size constraints and
/// supports handle swapping when dragging past opposite edges.
///
/// ## Architecture
///
/// This mixin uses **absolute position-based resizing** rather than incremental
/// deltas. When a resize starts, we capture:
/// - The starting mouse position (graph coordinates)
/// - The original node bounds
///
/// On each update, we calculate the new bounds based on the total movement
/// from the start, which eliminates "delta debt" accumulation issues.
///
/// ## Capability Indicator
///
/// This mixin overrides [isResizable] to return `true`, indicating the node
/// has resize capability. Subclasses can further override to add conditional
/// logic (e.g., GroupNode returns `false` for explicit behavior).
///
/// ## Usage
///
/// Apply this mixin to nodes that need resize capability:
///
/// ```dart
/// class MyResizableNode<T> extends Node<T> with ResizableMixin<T> {
///   @override
///   Size get minSize => const Size(200, 120);
///
///   @override
///   Size? get maxSize => const Size(600, 400);
///
///   @override
///   Widget buildWidget(BuildContext context) {
///     return buildWithResizer(
///       context: context,
///       child: MyNodeContent(),
///     );
///   }
/// }
/// ```
mixin ResizableMixin<T> on Node<T> {
  /// Whether this node can be resized.
  ///
  /// Returns `true` by default for nodes with this mixin.
  /// Override to add conditional logic (e.g., based on node state).
  @override
  bool get isResizable => true;

  /// Minimum size constraints for resize operations.
  ///
  /// Override in subclasses to specify custom minimum dimensions.
  /// The default minimum size is 100x60 pixels.
  Size get minSize => const Size(100, 60);

  /// Maximum size constraints for resize operations.
  ///
  /// Override in subclasses to specify custom maximum dimensions.
  /// Returns null by default (unconstrained).
  Size? get maxSize => null;

  /// Calculates new bounds based on absolute pointer position.
  ///
  /// This method implements constraint-aware resize calculation with
  /// handle swapping when crossing opposite edges.
  ///
  /// Key behaviors:
  /// - **Handle swapping**: When dimensions go negative (crossing opposite edge),
  ///   swap to the corresponding handle for intuitive behavior.
  /// - **Min size constraint**: When hitting minimum, stop resizing and track drift.
  /// - **Max size constraint**: When hitting maximum, stop resizing and track drift.
  ///
  /// Parameters:
  /// * [handle] - The resize handle being dragged
  /// * [originalBounds] - The node bounds when resize started
  /// * [startPosition] - Mouse position when resize started (graph coords)
  /// * [currentPosition] - Current mouse position (graph coords)
  ///
  /// Returns a [ResizeResult] with:
  /// * newBounds - The calculated bounds respecting constraints
  /// * newHandle - If non-null, the handle should swap to this
  /// * drift - Offset between expected handle position and pointer
  /// * constrainedByMin/Max - Flags indicating which constraints were hit
  ResizeResult calculateResize({
    required ResizeHandle handle,
    required Rect originalBounds,
    required Offset startPosition,
    required Offset currentPosition,
  }) {
    // Calculate total movement from start
    final delta = currentPosition - startPosition;

    // Calculate raw new bounds based on handle
    final rawBounds = _applyDeltaToBounds(handle, originalBounds, delta);

    // Apply constraints (min/max) - this may cause drift
    final constrainedResult = _constrainBounds(rawBounds, handle);

    // Calculate drift: difference between where the handle is vs pointer
    final expectedHandlePos = _getHandlePosition(
      handle,
      constrainedResult.bounds,
    );
    final drift = currentPosition - expectedHandlePos;

    return ResizeResult(
      newBounds: constrainedResult.bounds,
      drift: drift,
      constrainedByMin: constrainedResult.hitMin,
      constrainedByMax: constrainedResult.hitMax,
    );
  }

  /// Applies the delta to bounds based on which handle is being dragged.
  Rect _applyDeltaToBounds(ResizeHandle handle, Rect original, Offset delta) {
    var left = original.left;
    var top = original.top;
    var right = original.right;
    var bottom = original.bottom;

    switch (handle) {
      case ResizeHandle.topLeft:
        left += delta.dx;
        top += delta.dy;
      case ResizeHandle.topCenter:
        top += delta.dy;
      case ResizeHandle.topRight:
        right += delta.dx;
        top += delta.dy;
      case ResizeHandle.centerLeft:
        left += delta.dx;
      case ResizeHandle.centerRight:
        right += delta.dx;
      case ResizeHandle.bottomLeft:
        left += delta.dx;
        bottom += delta.dy;
      case ResizeHandle.bottomCenter:
        bottom += delta.dy;
      case ResizeHandle.bottomRight:
        right += delta.dx;
        bottom += delta.dy;
    }

    return Rect.fromLTRB(left, top, right, bottom);
  }

  /// Result of constraining bounds.
  ({Rect bounds, bool hitMin, bool hitMax}) _constrainBounds(
    Rect bounds,
    ResizeHandle handle,
  ) {
    var newBounds = bounds;
    var hitMin = false;
    var hitMax = false;

    final min = minSize;
    final max = maxSize;

    // Determine which edges are being dragged
    final draggingLeft =
        handle == ResizeHandle.topLeft ||
        handle == ResizeHandle.centerLeft ||
        handle == ResizeHandle.bottomLeft;
    final draggingTop =
        handle == ResizeHandle.topLeft ||
        handle == ResizeHandle.topCenter ||
        handle == ResizeHandle.topRight;
    final draggingRight =
        handle == ResizeHandle.topRight ||
        handle == ResizeHandle.centerRight ||
        handle == ResizeHandle.bottomRight;
    final draggingBottom =
        handle == ResizeHandle.bottomLeft ||
        handle == ResizeHandle.bottomCenter ||
        handle == ResizeHandle.bottomRight;

    // Apply min width constraint
    if (newBounds.width < min.width) {
      hitMin = true;
      if (draggingLeft) {
        // Left edge being dragged - keep right edge fixed
        newBounds = Rect.fromLTRB(
          newBounds.right - min.width,
          newBounds.top,
          newBounds.right,
          newBounds.bottom,
        );
      } else {
        // Right edge being dragged - keep left edge fixed
        newBounds = Rect.fromLTRB(
          newBounds.left,
          newBounds.top,
          newBounds.left + min.width,
          newBounds.bottom,
        );
      }
    }

    // Apply min height constraint
    if (newBounds.height < min.height) {
      hitMin = true;
      if (draggingTop) {
        // Top edge being dragged - keep bottom edge fixed
        newBounds = Rect.fromLTRB(
          newBounds.left,
          newBounds.bottom - min.height,
          newBounds.right,
          newBounds.bottom,
        );
      } else {
        // Bottom edge being dragged - keep top edge fixed
        newBounds = Rect.fromLTRB(
          newBounds.left,
          newBounds.top,
          newBounds.right,
          newBounds.top + min.height,
        );
      }
    }

    // Apply max width constraint (if specified)
    if (max != null && newBounds.width > max.width) {
      hitMax = true;
      if (draggingRight) {
        // Right edge being dragged - keep left edge fixed
        newBounds = Rect.fromLTRB(
          newBounds.left,
          newBounds.top,
          newBounds.left + max.width,
          newBounds.bottom,
        );
      } else if (draggingLeft) {
        // Left edge being dragged - keep right edge fixed
        newBounds = Rect.fromLTRB(
          newBounds.right - max.width,
          newBounds.top,
          newBounds.right,
          newBounds.bottom,
        );
      }
    }

    // Apply max height constraint (if specified)
    if (max != null && newBounds.height > max.height) {
      hitMax = true;
      if (draggingBottom) {
        // Bottom edge being dragged - keep top edge fixed
        newBounds = Rect.fromLTRB(
          newBounds.left,
          newBounds.top,
          newBounds.right,
          newBounds.top + max.height,
        );
      } else if (draggingTop) {
        // Top edge being dragged - keep bottom edge fixed
        newBounds = Rect.fromLTRB(
          newBounds.left,
          newBounds.bottom - max.height,
          newBounds.right,
          newBounds.bottom,
        );
      }
    }

    return (bounds: newBounds, hitMin: hitMin, hitMax: hitMax);
  }

  /// Gets the position of a handle on the given bounds.
  Offset _getHandlePosition(ResizeHandle handle, Rect bounds) {
    return switch (handle) {
      ResizeHandle.topLeft => bounds.topLeft,
      ResizeHandle.topCenter => Offset(bounds.center.dx, bounds.top),
      ResizeHandle.topRight => bounds.topRight,
      ResizeHandle.centerLeft => Offset(bounds.left, bounds.center.dy),
      ResizeHandle.centerRight => Offset(bounds.right, bounds.center.dy),
      ResizeHandle.bottomLeft => bounds.bottomLeft,
      ResizeHandle.bottomCenter => Offset(bounds.center.dx, bounds.bottom),
      ResizeHandle.bottomRight => bounds.bottomRight,
    };
  }

  /// Applies new bounds to the node, updating position and size.
  ///
  /// This is called after [calculateResize] to actually update the node.
  void applyBounds(Rect bounds) {
    if (!isResizable) return;

    runInAction(() {
      position.value = bounds.topLeft;
      setSize(bounds.size);
    });
  }

  /// Resizes the node based on absolute pointer positions.
  ///
  /// This is a convenience method that combines [calculateResize] and [applyBounds].
  /// It calculates the new bounds from the absolute positions and immediately applies them.
  ///
  /// For cases where you need to inspect the result before applying (e.g., to check
  /// drift threshold or handle swapping), use [calculateResize] followed by [applyBounds].
  ///
  /// Parameters:
  /// * [handle] - The resize handle being dragged
  /// * [originalBounds] - The node bounds when resize started
  /// * [startPosition] - Mouse position when resize started (graph coords)
  /// * [currentPosition] - Current mouse position (graph coords)
  ///
  /// Returns the [ResizeResult] for callers that need to inspect the result
  /// (e.g., to detect handle swapping).
  ResizeResult resize({
    required ResizeHandle handle,
    required Rect originalBounds,
    required Offset startPosition,
    required Offset currentPosition,
  }) {
    final result = calculateResize(
      handle: handle,
      originalBounds: originalBounds,
      startPosition: startPosition,
      currentPosition: currentPosition,
    );
    applyBounds(result.newBounds);
    return result;
  }
}
