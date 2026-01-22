part of 'node_flow_controller.dart';

/// Resize operations for [NodeFlowController].
///
/// This extension provides unified resize APIs that work for any resizable node,
/// including [GroupNode] and [CommentNode]. The node must have [Node.isResizable]
/// set to `true`.
///
/// ## Resize Lifecycle
///
/// 1. [startResize] - Captures original bounds and locks canvas
/// 2. [updateResize] - Calculates new bounds using absolute positioning
/// 3. [endResize] - Commits changes and unlocks canvas
/// 4. [cancelResize] - Reverts to original bounds and unlocks canvas
///
/// ## Example
///
/// ```dart
/// // In a resize handle widget:
/// void _handleDragStart(DragStartDetails details) {
///   controller.startResize(nodeId, ResizeHandle.bottomRight, details.globalPosition);
/// }
///
/// void _handleDragUpdate(DragUpdateDetails details) {
///   controller.updateResize(details.globalPosition);
/// }
///
/// void _handleDragEnd(DragEndDetails details) {
///   controller.endResize();
/// }
/// ```
extension ResizeApi<T, C> on NodeFlowController<T, C> {
  /// Starts a resize operation for any resizable node.
  ///
  /// Works for any node with `isResizable = true`, including [GroupNode]
  /// and [CommentNode]. The node must have [Node.isResizable] set to `true`.
  ///
  /// Parameters:
  /// * [nodeId] - The ID of the node to resize
  /// * [handle] - The resize handle being dragged
  /// * [globalPosition] - The global position of the pointer when resize started
  void startResize(String nodeId, ResizeHandle handle, Offset globalPosition) {
    final node = _nodes[nodeId];
    if (node == null || !node.isResizable) return;

    // Convert global position to graph coordinates
    final graphPos = viewport.toGraph(ScreenPosition(globalPosition));

    // Capture original bounds
    final originalBounds = Rect.fromLTWH(
      node.position.value.dx,
      node.position.value.dy,
      node.size.value.width,
      node.size.value.height,
    );

    interaction.startResize(nodeId, handle, graphPos.offset, originalBounds);

    // Emit extension event
    _emitEvent(ResizeStarted(nodeId, node.size.value));
  }

  /// Updates the size of the currently resizing node during a resize operation.
  ///
  /// Uses absolute position-based resizing for predictable behavior:
  /// - Calculates new bounds from original state + total movement
  /// - Handles constraint boundaries (min/max size)
  /// - Supports handle swapping when crossing opposite edges
  /// - Tracks drift for proximity-based resume
  ///
  /// Parameters:
  /// * [globalPosition] - The current global position of the pointer
  void updateResize(Offset globalPosition) {
    final nodeId = interaction.currentResizingNodeId;
    final handle = interaction.currentResizeHandle;
    final startPos = interaction.currentResizeStartPosition;
    final originalBounds = interaction.currentOriginalNodeBounds;

    if (nodeId == null ||
        handle == null ||
        startPos == null ||
        originalBounds == null) {
      return;
    }

    final node = _nodes[nodeId];
    if (node == null || !node.isResizable) return;

    // Convert global position to graph coordinates
    final graphPos = viewport.toGraph(ScreenPosition(globalPosition));

    // Calculate new bounds using absolute positioning
    final resizableNode = node as ResizableMixin<T>;
    final result = resizableNode.calculateResize(
      handle: handle,
      originalBounds: originalBounds,
      startPosition: startPos,
      currentPosition: graphPos.offset,
    );

    // Apply the resize
    runInAction(() {
      resizableNode.applyBounds(result.newBounds);
      node.setVisualPosition(snapToGrid(node.position.value));
    });
    _markNodeDirty(nodeId);

    // Track drift for debugging/analytics
    interaction.setHandleDrift(result.drift);
  }

  /// Ends the current resize operation.
  ///
  /// Clears resize state and re-enables panning.
  void endResize() {
    final nodeId = interaction.currentResizingNodeId;
    final originalBounds = interaction.currentOriginalNodeBounds;

    // Capture final size before clearing state
    Size? finalSize;
    if (nodeId != null) {
      finalSize = _nodes[nodeId]?.size.value;
    }

    interaction.endResize();

    // Emit extension event with original and final sizes
    if (nodeId != null && originalBounds != null && finalSize != null) {
      _emitEvent(ResizeEnded(nodeId, originalBounds.size, finalSize));
    }
  }

  /// Cancels a resize operation and reverts to original position/size.
  ///
  /// Restores the node to its state before the resize started using the
  /// original bounds captured in [InteractionState].
  void cancelResize() {
    final nodeId = interaction.currentResizingNodeId;
    final originalBounds = interaction.currentOriginalNodeBounds;

    if (nodeId == null || originalBounds == null) return;

    final node = _nodes[nodeId];
    if (node != null && node.isResizable) {
      runInAction(() {
        node.position.value = originalBounds.topLeft;
        node.setVisualPosition(snapToGrid(originalBounds.topLeft));
        (node as ResizableMixin<T>).setSize(originalBounds.size);
      });
      _markNodeDirty(nodeId);
    }

    interaction.endResize();

    // Fire resize cancel event
    if (node != null) {
      events.node?.onResizeCancel?.call(node);
    }
  }
}
