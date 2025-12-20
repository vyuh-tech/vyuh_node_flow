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
  void _handleNodeTap(Node<T> node) {
    // Ensure canvas has focus
    if (!widget.controller.canvasFocusNode.hasFocus) {
      widget.controller.canvasFocusNode.requestFocus();
    }

    final isCmd = HardwareKeyboard.instance.isMetaPressed;
    final isCtrl = HardwareKeyboard.instance.isControlPressed;
    final toggle = isCmd || isCtrl;

    // Select the node
    widget.controller.selectNode(node.id, toggle: toggle);

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

  // ============================================================
  // Annotation Gesture Handlers
  // ============================================================

  /// Handles annotation tap - selects the annotation with modifier key support.
  void _handleAnnotationTap(Annotation annotation) {
    if (!annotation.isInteractive) return;

    // Ensure canvas has focus
    if (!widget.controller.canvasFocusNode.hasFocus) {
      widget.controller.canvasFocusNode.requestFocus();
    }

    final isCmd = HardwareKeyboard.instance.isMetaPressed;
    final isCtrl = HardwareKeyboard.instance.isControlPressed;
    final toggle = isCmd || isCtrl;

    // Select the annotation
    widget.controller.selectAnnotation(annotation.id, toggle: toggle);

    // Fire user callback
    widget.controller.events.annotation?.onTap?.call(annotation);
  }

  /// Handles annotation double-tap.
  void _handleAnnotationDoubleTap(Annotation annotation) {
    widget.controller.events.annotation?.onDoubleTap?.call(annotation);
  }

  /// Handles annotation context menu (right-click).
  void _handleAnnotationContextMenu(
    Annotation annotation,
    Offset globalPosition,
  ) {
    // Convert global to local position
    final RenderBox? box = context.findRenderObject() as RenderBox?;
    final localPosition = box?.globalToLocal(globalPosition) ?? globalPosition;

    widget.controller.events.annotation?.onContextMenu?.call(
      annotation,
      localPosition,
    );
  }

  /// Handles mouse entering an annotation.
  void _handleAnnotationMouseEnter(Annotation annotation) {
    widget.controller.events.annotation?.onMouseEnter?.call(annotation);
  }

  /// Handles mouse leaving an annotation.
  void _handleAnnotationMouseLeave(Annotation annotation) {
    widget.controller.events.annotation?.onMouseLeave?.call(annotation);
  }

  // Note: _handleAnnotationDragStart removed.
  // Annotation drag is now handled directly by AnnotationWidget via public API:
  // controller.startAnnotationDrag(), controller.moveAnnotationDrag(), controller.endAnnotationDrag()
}
