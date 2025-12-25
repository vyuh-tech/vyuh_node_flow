part of 'node_flow_editor.dart';

/// Extension on [_NodeFlowEditorState] for widget-level gesture handling.
///
/// This part file contains:
/// - Widget-level handlers for: tap, double-tap, context menu, and hover events
/// - Drag start handlers (called from Listener's _handlePointerDown)
///
/// NOTE: Drag update/end is handled via Listener in node_flow_editor.dart
/// because widget-level gestures don't work outside Stack bounds.
/// The drag start handlers are called from _handlePointerDown when hitting
/// a node or annotation.
extension _WidgetGestureHandlers<T> on _NodeFlowEditorState<T> {
  // ============================================================
  // Node Gesture Handlers
  // ============================================================

  /// Handles node tap - selects the node with modifier key support.
  ///
  /// Preserves multi-selection when clicking on an already-selected node
  /// without modifier keys, allowing drag of multiple nodes together.
  void _handleNodeTap(Node<T> node) {
    // Ensure canvas has PRIMARY focus for keyboard shortcuts to work
    if (!widget.controller.canvasFocusNode.hasPrimaryFocus) {
      widget.controller.canvasFocusNode.requestFocus();
    }

    final isCmd = HardwareKeyboard.instance.isMetaPressed;
    final isCtrl = HardwareKeyboard.instance.isControlPressed;
    final toggle = isCmd || isCtrl;
    final isAlreadySelected = widget.controller.isNodeSelected(node.id);

    // Only change selection if:
    // - Node is not already selected (click to select)
    // - Modifier keys are pressed (toggle mode)
    // This preserves multi-selection for dragging multiple nodes
    if (!isAlreadySelected || toggle) {
      widget.controller.selectNode(node.id, toggle: toggle);
    }

    // Fire user callback
    widget.controller.events.node?.onTap?.call(node);
  }

  /// Handles node double-tap.
  void _handleNodeDoubleTap(Node<T> node) {
    widget.controller.events.node?.onDoubleTap?.call(node);
  }

  /// Handles node context menu (right-click).
  ///
  /// The [screenPosition] is in screen/global coordinates, passed directly
  /// to the callback for use with [showMenu] or similar popup APIs.
  void _handleNodeContextMenu(Node<T> node, Offset screenPosition) {
    widget.controller.events.node?.onContextMenu?.call(node, screenPosition);
  }

  /// Handles mouse entering a node.
  void _handleNodeMouseEnter(Node<T> node) {
    widget.controller.events.node?.onMouseEnter?.call(node);
    // Cursor is derived from state via Observer in widget MouseRegions
  }

  /// Handles mouse leaving a node.
  void _handleNodeMouseLeave(Node<T> node) {
    widget.controller.events.node?.onMouseLeave?.call(node);
    // Cursor is derived from state via Observer in widget MouseRegions
  }

  // ============================================================
  // Port Gesture Handlers
  // ============================================================

  /// Handles port context menu (right-click).
  ///
  /// The [screenPosition] is in screen/global coordinates, passed directly
  /// to the callback for use with [showMenu] or similar popup APIs.
  void _handlePortContextMenu(
    String nodeId,
    String portId,
    bool isOutput,
    Offset screenPosition,
  ) {
    final node = widget.controller.getNode(nodeId);
    if (node == null) return;

    // Find the port
    final port = [
      ...node.inputPorts,
      ...node.outputPorts,
    ].where((p) => p.id == portId).firstOrNull;
    if (port == null) return;

    widget.controller.events.port?.onContextMenu?.call(
      node,
      port,
      isOutput,
      screenPosition,
    );
  }

  // Note: Annotation handlers have been removed.
  // GroupNode and CommentNode are now regular nodes and use the node handlers above.
  // - Node tap/double-tap/context-menu work for all node types
  // - Node drag is handled via NodeWidget's GestureDetector
}
