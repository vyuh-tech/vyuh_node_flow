part of 'node_flow_editor.dart';

/// Extension on [_NodeFlowEditorState] for hit testing functionality.
///
/// This part file contains all hit testing related logic including:
/// - Mouse hover handling and cursor updates
/// - Tap and double-tap detection
/// - Mouse enter/leave event firing
/// - Shift key tracking for selection mode
extension _HitTestingExtension<T> on _NodeFlowEditorState<T> {
  // ============================================================
  // Hit Testing State (stored in main class, accessed via extension)
  // ============================================================

  /// Handles keyboard events for shift key cursor changes.
  bool _handleKeyEvent(KeyEvent event) {
    // Only care about shift key changes
    final isShiftKey =
        event.logicalKey == LogicalKeyboardKey.shiftLeft ||
        event.logicalKey == LogicalKeyboardKey.shiftRight;

    if (!isShiftKey) return false;

    _isShiftPressed = HardwareKeyboard.instance.isShiftPressed;

    // Update interaction state for cursor feedback
    widget.controller.interaction.setSelectionStarted(_isShiftPressed);

    // Don't consume the event - let other handlers process it
    return false;
  }

  // ============================================================
  // Mouse Hover Handling
  // ============================================================

  /// Handles mouse hover events, updating cursor and firing enter/leave events.
  void _handleMouseHover(PointerHoverEvent event) {
    // Check shift key state for selection mode cursor
    final isShiftPressed = HardwareKeyboard.instance.isShiftPressed;
    if (isShiftPressed != _isShiftPressed) {
      _isShiftPressed = isShiftPressed;
      widget.controller.interaction.setSelectionStarted(_isShiftPressed);
    }

    // Update mouse position in world coordinates for debug visualization
    final worldPosition = widget.controller.viewport.toGraph(
      ScreenPosition(event.localPosition),
    );
    widget.controller.setMousePositionWorld(worldPosition);

    final hitResult = _performHitTest(event.localPosition);

    // Track hover state changes and fire enter/leave events
    _handleHoverStateChange(hitResult);

    // Cursor is derived from state via Observer - no update needed
  }

  /// Handles hover state changes and fires onMouseEnter/onMouseLeave events.
  void _handleHoverStateChange(HitTestResult hitResult) {
    // Determine current hover entity
    final currentHitType = hitResult.hitType;
    String? currentEntityId;
    String? currentNodeId;
    bool? currentPortIsOutput;

    switch (currentHitType) {
      case HitTarget.node:
        currentEntityId = hitResult.nodeId;
        break;
      case HitTarget.port:
        currentEntityId = hitResult.portId;
        currentNodeId = hitResult.nodeId;
        currentPortIsOutput = hitResult.isOutput;
        break;
      case HitTarget.connection:
        currentEntityId = hitResult.connectionId;
        break;
      case HitTarget.canvas:
        // No entity on canvas
        break;
    }

    // Check if hover target changed
    final hoverChanged =
        _lastHoverHitType != currentHitType ||
        _lastHoveredEntityId != currentEntityId;

    if (!hoverChanged) return;

    // Fire leave event for previous hover target
    if (_lastHoverHitType != null) {
      _fireMouseLeaveEvent();
    }

    // Fire enter event for new hover target
    _fireMouseEnterEvent(
      currentHitType,
      currentEntityId,
      currentNodeId,
      currentPortIsOutput,
    );

    // Update tracking state
    _lastHoverHitType = currentHitType;
    _lastHoveredEntityId = currentEntityId;

    // Update connection hover state for cursor feedback
    widget.controller.interaction.setHoveringConnection(
      currentHitType == HitTarget.connection,
    );
  }

  /// Fires mouse leave event for the previously hovered entity.
  /// Only handles connections - nodes and ports handle their own
  /// mouse events via their widget's MouseRegion.
  void _fireMouseLeaveEvent() {
    switch (_lastHoverHitType!) {
      // Nodes and ports handle their own mouse events
      // via their widget's MouseRegion - don't fire again here
      case HitTarget.node:
      case HitTarget.port:
      case HitTarget.canvas:
        break;

      case HitTarget.connection:
        if (_lastHoveredEntityId != null) {
          final connection = widget.controller.connections
              .where((c) => c.id == _lastHoveredEntityId!)
              .firstOrNull;
          if (connection != null) {
            widget.controller.events.connection?.onMouseLeave?.call(connection);
          }
        }
        break;
    }
  }

  /// Fires mouse enter event for the newly hovered entity.
  /// Only handles connections - nodes and ports handle their own
  /// mouse events via their widget's MouseRegion.
  void _fireMouseEnterEvent(
    HitTarget hitType,
    String? entityId,
    String? nodeId,
    bool? isOutput,
  ) {
    switch (hitType) {
      // Nodes and ports handle their own mouse events
      // via their widget's MouseRegion - don't fire again here
      case HitTarget.node:
      case HitTarget.port:
      case HitTarget.canvas:
        break;

      case HitTarget.connection:
        if (entityId != null) {
          final connection = widget.controller.connections
              .where((c) => c.id == entityId)
              .firstOrNull;
          if (connection != null) {
            widget.controller.events.connection?.onMouseEnter?.call(connection);
          }
        }
        break;
    }
  }

  // ============================================================
  // Context Menu (Right-Click) Handling
  // ============================================================

  /// Handles right-click context menu for connections and canvas only.
  /// Nodes and ports handle their own context menu via their widgets.
  /// Returns true if the event was handled (context menu shown).
  bool _handleContextMenu(PointerDownEvent event) {
    if (event.buttons != kSecondaryMouseButton) return false;

    final hitResult = _performHitTest(event.localPosition);

    switch (hitResult.hitType) {
      // Nodes and ports handle their own context menu
      // via their widget's onSecondaryTapUp - don't fire again here
      case HitTarget.node:
      case HitTarget.port:
        break;

      case HitTarget.connection:
        final connection = widget.controller.connections
            .where((c) => c.id == hitResult.connectionId!)
            .firstOrNull;
        if (connection != null) {
          // Use event.position (screen/global coordinates) for context menu
          // positioning with showMenu or similar popup APIs
          widget.controller.events.connection?.onContextMenu?.call(
            connection,
            ScreenPosition(event.position),
          );
        }
        break;

      case HitTarget.canvas:
        final graphPosition = widget.controller.viewport.toGraph(
          ScreenPosition(event.localPosition),
        );
        widget.controller.events.viewport?.onCanvasContextMenu?.call(
          graphPosition,
        );
        break;
    }

    return true;
  }

  // ============================================================
  // Tap Event Handling
  // ============================================================

  /// Handles tap events for all hit target types (nodes, connections, canvas).
  /// Detects single taps and double-taps, firing appropriate callbacks.
  void _handleTapEvent(Offset position, HitTestResult hitResult) {
    // Ensure canvas has PRIMARY focus for keyboard shortcuts to work
    if (!widget.controller.canvasFocusNode.hasPrimaryFocus) {
      widget.controller.canvasFocusNode.requestFocus();
    }

    final now = DateTime.now();
    final entityId = hitResult.nodeId ?? hitResult.connectionId;

    // Check for double-tap: same target type, same entity (if applicable),
    // within timeout and position threshold
    final isDoubleTap =
        _lastTapTime != null &&
        _lastTapPosition != null &&
        _lastTapHitType == hitResult.hitType &&
        _lastTappedEntityId == entityId &&
        now.difference(_lastTapTime!) <
            _NodeFlowEditorState._doubleTapTimeout &&
        (position - _lastTapPosition!).distance <
            _NodeFlowEditorState._doubleTapSlop;

    if (isDoubleTap) {
      _handleDoubleTap(position, hitResult);
      _resetDoubleTapTracking();
    } else {
      _handleSingleTap(position, hitResult);
      // Update tracking for potential double-tap
      _lastTapTime = now;
      _lastTapPosition = position;
      _lastTapHitType = hitResult.hitType;
      _lastTappedEntityId = entityId;
    }
  }

  /// Handles single tap events for all hit target types.
  void _handleSingleTap(Offset position, HitTestResult hitResult) {
    switch (hitResult.hitType) {
      // Note: Node tap is now handled by widget-level gestures (NodeWidget.onTap)
      // to avoid double-firing the callback.
      case HitTarget.node:
        // Widget handles tap - nothing to do here
        break;

      case HitTarget.port:
        final node = widget.controller.getNode(hitResult.nodeId!);
        if (node != null) {
          final port = _findPort(node, hitResult.portId!);
          if (port != null) {
            widget.controller.events.port?.onTap?.call(node, port);
          }
        }
        break;

      case HitTarget.connection:
        // Connection tap is already handled in _handlePointerDown for selection
        // The onTap callback is also fired there
        break;

      case HitTarget.canvas:
        // Clear selection on canvas tap (if _shouldClearSelectionOnTap is set)
        if (_shouldClearSelectionOnTap) {
          widget.controller.clearSelection();
          final graphPosition = widget.controller.viewport.toGraph(
            ScreenPosition(position),
          );
          widget.controller.events.viewport?.onCanvasTap?.call(graphPosition);
        }
        break;
    }
  }

  /// Handles double-tap events for all hit target types.
  void _handleDoubleTap(Offset position, HitTestResult hitResult) {
    switch (hitResult.hitType) {
      // Note: Node double-tap is now handled by widget-level gestures (NodeWidget.onDoubleTap)
      // to avoid double-firing the callback.
      case HitTarget.node:
        // Widget handles double-tap - nothing to do here
        break;

      case HitTarget.port:
        final node = widget.controller.getNode(hitResult.nodeId!);
        if (node != null) {
          final port = _findPort(node, hitResult.portId!);
          if (port != null) {
            widget.controller.events.port?.onDoubleTap?.call(node, port);
          }
        }
        break;

      case HitTarget.connection:
        final connection = widget.controller.connections
            .where((c) => c.id == hitResult.connectionId!)
            .firstOrNull;
        if (connection != null) {
          widget.controller.events.connection?.onDoubleTap?.call(connection);
        }
        break;

      case HitTarget.canvas:
        final graphPosition = widget.controller.viewport.toGraph(
          ScreenPosition(position),
        );
        widget.controller.events.viewport?.onCanvasDoubleTap?.call(
          graphPosition,
        );
        break;
    }
  }

  /// Resets double-tap tracking state.
  void _resetDoubleTapTracking() {
    _lastTapTime = null;
    _lastTapPosition = null;
    _lastTapHitType = null;
    _lastTappedEntityId = null;
  }

  // ============================================================
  // Utility Methods
  // ============================================================

  /// Helper to find a port by ID in a node's input or output ports.
  Port? _findPort(Node<T> node, String portId) {
    for (final port in node.inputPorts) {
      if (port.id == portId) return port;
    }
    for (final port in node.outputPorts) {
      if (port.id == portId) return port;
    }
    return null;
  }

  /// Performs hit testing at the given local position.
  /// Converts screen coordinates to graph coordinates and delegates to spatial index.
  HitTestResult _performHitTest(Offset localPosition) {
    final graphPosition = widget.controller.viewport.toGraph(
      ScreenPosition(localPosition),
    );
    return widget.controller.spatialIndex.hitTest(graphPosition.offset);
  }
}
