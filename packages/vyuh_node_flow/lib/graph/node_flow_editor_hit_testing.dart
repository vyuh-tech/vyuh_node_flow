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
    final isShiftKey = event.logicalKey == LogicalKeyboardKey.shiftLeft ||
        event.logicalKey == LogicalKeyboardKey.shiftRight;

    if (!isShiftKey) return false;

    final wasShiftPressed = _isShiftPressed;
    _isShiftPressed = HardwareKeyboard.instance.isShiftPressed;

    // Update cursor if shift state changed
    if (wasShiftPressed != _isShiftPressed && widget.enableSelection) {
      // Use the last known hover state to update cursor
      final hitResult = HitTestResult(
        hitType: _lastHoverHitType ?? HitTarget.canvas,
        nodeId: _lastHoverHitType == HitTarget.node ||
                _lastHoverHitType == HitTarget.port
            ? _lastHoveredEntityId ?? _lastHoveredNodeId
            : null,
        portId:
            _lastHoverHitType == HitTarget.port ? _lastHoveredEntityId : null,
        connectionId: _lastHoverHitType == HitTarget.connection
            ? _lastHoveredEntityId
            : null,
        annotationId: _lastHoverHitType == HitTarget.annotation
            ? _lastHoveredEntityId
            : null,
      );
      _updateCursor(hitResult);
    }

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
    }

    // Update mouse position in world coordinates for debug visualization
    final worldPosition =
        widget.controller.viewport.screenToGraph(event.localPosition);
    widget.controller.setMousePositionWorld(worldPosition);

    final hitResult = _performHitTest(event.localPosition);

    // Track hover state changes and fire enter/leave events
    _handleHoverStateChange(hitResult);

    _updateCursor(hitResult);
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
      case HitTarget.annotation:
        currentEntityId = hitResult.annotationId;
        break;
      case HitTarget.canvas:
        // No entity on canvas
        break;
    }

    // Check if hover target changed
    final hoverChanged = _lastHoverHitType != currentHitType ||
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
    _lastHoveredNodeId = currentNodeId;
    _lastHoveredPortIsOutput = currentPortIsOutput;
  }

  /// Fires mouse leave event for the previously hovered entity.
  void _fireMouseLeaveEvent() {
    switch (_lastHoverHitType!) {
      case HitTarget.node:
        if (_lastHoveredEntityId != null) {
          final node = widget.controller.getNode(_lastHoveredEntityId!);
          if (node != null) {
            widget.controller.events.node?.onMouseLeave?.call(node);
          }
        }
        break;
      case HitTarget.port:
        if (_lastHoveredNodeId != null && _lastHoveredEntityId != null) {
          final node = widget.controller.getNode(_lastHoveredNodeId!);
          if (node != null) {
            final port = _findPort(node, _lastHoveredEntityId!);
            if (port != null) {
              widget.controller.events.port?.onMouseLeave?.call(
                node,
                port,
                _lastHoveredPortIsOutput ?? false,
              );
            }
          }
        }
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
      case HitTarget.annotation:
        if (_lastHoveredEntityId != null) {
          final annotation =
              widget.controller.annotations.getAnnotation(_lastHoveredEntityId!);
          if (annotation != null) {
            widget.controller.events.annotation?.onMouseLeave?.call(annotation);
          }
        }
        break;
      case HitTarget.canvas:
        break;
    }
  }

  /// Fires mouse enter event for the newly hovered entity.
  void _fireMouseEnterEvent(
    HitTarget hitType,
    String? entityId,
    String? nodeId,
    bool? isOutput,
  ) {
    switch (hitType) {
      case HitTarget.node:
        if (entityId != null) {
          final node = widget.controller.getNode(entityId);
          if (node != null) {
            widget.controller.events.node?.onMouseEnter?.call(node);
          }
        }
        break;
      case HitTarget.port:
        if (nodeId != null && entityId != null) {
          final node = widget.controller.getNode(nodeId);
          if (node != null) {
            final port = _findPort(node, entityId);
            if (port != null) {
              widget.controller.events.port?.onMouseEnter?.call(
                node,
                port,
                isOutput ?? false,
              );
            }
          }
        }
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
      case HitTarget.annotation:
        if (entityId != null) {
          final annotation =
              widget.controller.annotations.getAnnotation(entityId);
          if (annotation != null) {
            widget.controller.events.annotation?.onMouseEnter?.call(annotation);
          }
        }
        break;
      case HitTarget.canvas:
        break;
    }
  }

  // ============================================================
  // Context Menu (Right-Click) Handling
  // ============================================================

  /// Handles right-click context menu for all entity types.
  /// Returns true if the event was handled (context menu shown).
  bool _handleContextMenu(PointerDownEvent event) {
    if (event.buttons != kSecondaryMouseButton) return false;

    final hitResult = _performHitTest(event.localPosition);

    switch (hitResult.hitType) {
      case HitTarget.port:
        final node = widget.controller.getNode(hitResult.nodeId!);
        if (node != null) {
          final port = _findPort(node, hitResult.portId!);
          if (port != null) {
            widget.controller.events.port?.onContextMenu?.call(
              node,
              port,
              hitResult.isOutput ?? false,
              event.localPosition,
            );
          }
        }
        break;

      case HitTarget.node:
        final node = widget.controller.getNode(hitResult.nodeId!);
        if (node != null) {
          widget.controller.events.node?.onContextMenu?.call(
            node,
            event.localPosition,
          );
        }
        break;

      case HitTarget.connection:
        final connection = widget.controller.connections
            .where((c) => c.id == hitResult.connectionId!)
            .firstOrNull;
        if (connection != null) {
          widget.controller.events.connection?.onContextMenu?.call(
            connection,
            event.localPosition,
          );
        }
        break;

      case HitTarget.annotation:
        final annotation = widget.controller.annotations
            .getAnnotation(hitResult.annotationId!);
        if (annotation != null) {
          widget.controller.events.annotation?.onContextMenu?.call(
            annotation,
            event.localPosition,
          );
        }
        break;

      case HitTarget.canvas:
        final graphPosition = widget.controller.viewport.screenToGraph(event.localPosition);
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
    // Ensure canvas has focus after tap
    if (!widget.controller.canvasFocusNode.hasFocus) {
      widget.controller.canvasFocusNode.requestFocus();
    }

    final now = DateTime.now();
    final entityId = hitResult.nodeId ?? hitResult.connectionId;

    // Check for double-tap: same target type, same entity (if applicable),
    // within timeout and position threshold
    final isDoubleTap = _lastTapTime != null &&
        _lastTapPosition != null &&
        _lastTapHitType == hitResult.hitType &&
        _lastTappedEntityId == entityId &&
        now.difference(_lastTapTime!) < _NodeFlowEditorState._doubleTapTimeout &&
        (position - _lastTapPosition!).distance < _NodeFlowEditorState._doubleTapSlop;

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
      case HitTarget.node:
        final node = widget.controller.getNode(hitResult.nodeId!);
        if (node != null) {
          widget.controller.events.node?.onTap?.call(node);
        }
        break;

      case HitTarget.port:
        final node = widget.controller.getNode(hitResult.nodeId!);
        if (node != null) {
          final port = _findPort(node, hitResult.portId!);
          if (port != null) {
            widget.controller.events.port?.onTap?.call(
              node,
              port,
              hitResult.isOutput ?? false,
            );
          }
        }
        break;

      case HitTarget.connection:
        // Connection tap is already handled in _handlePointerDown for selection
        // The onTap callback is also fired there
        break;

      case HitTarget.annotation:
        final annotation = widget.controller.annotations
            .getAnnotation(hitResult.annotationId!);
        if (annotation != null) {
          widget.controller.events.annotation?.onTap?.call(annotation);
        }
        break;

      case HitTarget.canvas:
        // Clear selection on canvas tap (if _shouldClearSelectionOnTap is set)
        if (_shouldClearSelectionOnTap) {
          widget.controller.clearSelection();
          final graphPosition = widget.controller.viewport.screenToGraph(position);
          widget.controller.events.viewport?.onCanvasTap?.call(graphPosition);
        }
        break;
    }
  }

  /// Handles double-tap events for all hit target types.
  void _handleDoubleTap(Offset position, HitTestResult hitResult) {
    switch (hitResult.hitType) {
      case HitTarget.node:
        final node = widget.controller.getNode(hitResult.nodeId!);
        if (node != null) {
          widget.controller.events.node?.onDoubleTap?.call(node);
        }
        break;

      case HitTarget.port:
        final node = widget.controller.getNode(hitResult.nodeId!);
        if (node != null) {
          final port = _findPort(node, hitResult.portId!);
          if (port != null) {
            widget.controller.events.port?.onDoubleTap?.call(
              node,
              port,
              hitResult.isOutput ?? false,
            );
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

      case HitTarget.annotation:
        final annotation = widget.controller.annotations
            .getAnnotation(hitResult.annotationId!);
        if (annotation != null) {
          widget.controller.events.annotation?.onDoubleTap?.call(annotation);
        }
        break;

      case HitTarget.canvas:
        final graphPosition = widget.controller.viewport.screenToGraph(position);
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
  // Cursor Management
  // ============================================================

  /// Updates the cursor based on the current hit test result and shift key state.
  void _updateCursor(HitTestResult hitResult) {
    final cursorTheme = widget.theme.cursorTheme;
    MouseCursor newCursor;

    // When all interactions disabled, always use selection cursor
    if (!widget.enableSelection &&
        !widget.enableNodeDragging &&
        !widget.enableConnectionCreation) {
      newCursor = cursorTheme.selectionCursor;
    } else if (_isShiftPressed && widget.enableSelection) {
      // Shift pressed - show crosshair for selection mode
      newCursor = SystemMouseCursors.precise;
    } else if (widget.controller.isDrawingSelection) {
      newCursor = SystemMouseCursors.precise;
    } else if (widget.controller.draggedNodeId != null) {
      newCursor = cursorTheme.dragCursor;
    } else if (widget.controller.isConnecting) {
      newCursor = cursorTheme.portCursor;
    } else if (hitResult.isPort) {
      newCursor = cursorTheme.portCursor;
    } else if (hitResult.isNode) {
      newCursor = cursorTheme.nodeCursor;
    } else if (hitResult.isConnection) {
      newCursor = SystemMouseCursors.click;
    } else {
      newCursor = cursorTheme.selectionCursor;
    }

    widget.controller._updateInteractionState(cursor: newCursor);
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
    final graphPosition = widget.controller.viewport.screenToGraph(localPosition);
    return widget.controller.spatialIndex.hitTest(graphPosition);
  }
}
