import 'dart:ui';

import 'package:mobx/mobx.dart';

import '../../editor/resizer_widget.dart';
import '../node.dart';

/// Mixin providing resize functionality for nodes.
///
/// This mixin handles resize operations through 8 handle positions:
/// - 4 corners: topLeft, topRight, bottomLeft, bottomRight
/// - 4 edge midpoints: topCenter, centerLeft, centerRight, bottomCenter
///
/// The resize operation respects minimum size constraints defined by [minSize]
/// and automatically adjusts the node position when resizing from edges that
/// would otherwise push the node below minimum size.
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

  /// Applies a resize operation based on the handle being dragged.
  ///
  /// This method handles all 8 resize handles (corners and edge midpoints),
  /// calculating the new position and size based on the delta movement.
  /// Minimum size constraints are enforced via [minSize].
  ///
  /// Parameters:
  /// * [handle] - The resize handle being dragged
  /// * [delta] - The movement delta in graph coordinates
  ///
  /// Example:
  /// ```dart
  /// // In a resize gesture callback:
  /// node.resize(ResizeHandle.bottomRight, Offset(10, 5));
  /// ```
  void resize(ResizeHandle handle, Offset delta) {
    if (!isResizable) return;

    runInAction(() {
      var newX = position.value.dx;
      var newY = position.value.dy;
      var newWidth = size.value.width;
      var newHeight = size.value.height;

      switch (handle) {
        case ResizeHandle.topLeft:
          newX += delta.dx;
          newY += delta.dy;
          newWidth -= delta.dx;
          newHeight -= delta.dy;
        case ResizeHandle.topCenter:
          newY += delta.dy;
          newHeight -= delta.dy;
        case ResizeHandle.topRight:
          newY += delta.dy;
          newWidth += delta.dx;
          newHeight -= delta.dy;
        case ResizeHandle.centerLeft:
          newX += delta.dx;
          newWidth -= delta.dx;
        case ResizeHandle.centerRight:
          newWidth += delta.dx;
        case ResizeHandle.bottomLeft:
          newX += delta.dx;
          newWidth -= delta.dx;
          newHeight += delta.dy;
        case ResizeHandle.bottomCenter:
          newHeight += delta.dy;
        case ResizeHandle.bottomRight:
          newWidth += delta.dx;
          newHeight += delta.dy;
      }

      // Apply minimum size constraints with position adjustment
      if (newWidth < minSize.width) {
        if (handle == ResizeHandle.topLeft ||
            handle == ResizeHandle.centerLeft ||
            handle == ResizeHandle.bottomLeft) {
          newX = position.value.dx + size.value.width - minSize.width;
        }
        newWidth = minSize.width;
      }

      if (newHeight < minSize.height) {
        if (handle == ResizeHandle.topLeft ||
            handle == ResizeHandle.topCenter ||
            handle == ResizeHandle.topRight) {
          newY = position.value.dy + size.value.height - minSize.height;
        }
        newHeight = minSize.height;
      }

      // Update position if changed
      final newPosition = Offset(newX, newY);
      if (newPosition != position.value) {
        position.value = newPosition;
        // Note: visualPosition update handled by controller
      }

      // Update size via setSize to allow subclass customization
      setSize(Size(newWidth, newHeight));
    });
  }
}
