part of 'node_flow_editor.dart';

/// Internal controller extension methods for widget implementation
/// These methods are not part of the public API
extension _NodeFlowControllerWidgetInternal<T> on NodeFlowController<T> {
  // Internal widget support methods - not part of public API

  /// Get all connections for a specific port
  List<Connection> _getConnectionsForPort(
    String nodeId,
    String portId,
    bool isOutput,
  ) {
    if (isOutput) {
      return connections
          .where(
            (conn) =>
                conn.sourceNodeId == nodeId && conn.sourcePortId == portId,
          )
          .toList();
    } else {
      return connections
          .where(
            (conn) =>
                conn.targetNodeId == nodeId && conn.targetPortId == portId,
          )
          .toList();
    }
  }

  /// Check if a port allows multiple connections
  bool _portAllowsMultipleConnections(String nodeId, String portId) {
    final node = getNode(nodeId);
    if (node == null) return false;

    // Check input ports
    for (final port in node.inputPorts) {
      if (port.id == portId) {
        return port.multiConnections;
      }
    }

    // Check output ports
    for (final port in node.outputPorts) {
      if (port.id == portId) {
        return port.multiConnections;
      }
    }

    return false;
  }

  /// Get existing connections that need to be removed (for batching)
  List<Connection> _getConnectionsToRemove(
    String nodeId,
    String portId,
    bool isOutput,
  ) {
    if (_portAllowsMultipleConnections(nodeId, portId)) {
      return []; // Multi-connections allowed, don't remove existing
    }

    return _getConnectionsForPort(nodeId, portId, isOutput);
  }

  /// Optimized drag start that batches all state changes for instant response
  void _startNodeDrag(
    String nodeId,
    Offset pointerPosition,
    MouseCursor dragCursor,
  ) {
    final wasDragging = interaction.draggedNodeId.value != null;
    final wasSelected = selectedNodeIds.contains(nodeId);

    runInAction(() {
      // 1. Set drag state
      interaction.draggedNodeId.value = nodeId;
      interaction.lastPointerPosition.value = pointerPosition;

      // 2. Update cursor
      interaction.currentCursor.value = dragCursor;

      // 3. Update visual dragging state
      if (!wasDragging) {
        final nodeIds = wasSelected ? selectedNodeIds.toList() : [nodeId];
        for (final id in nodeIds) {
          nodes[id]?.dragging.value = true;
        }
      }
    });

    // Selection is now handled entirely in _handlePointerDown for precise control
    // We only ensure focus here if needed
    if (!canvasFocusNode.hasFocus) {
      canvasFocusNode.requestFocus();
    }
  }

  /// Optimized drag end that batches all cleanup changes
  void _endNodeDrag() {
    runInAction(() {
      // Check for drag-to-group intersections before clearing drag state
      final draggedNodeIds = <String>[];
      for (final node in nodes.values) {
        if (node.dragging.value) {
          draggedNodeIds.add(node.id);
          node.dragging.value = false;
        }
      }

      // Handle Command+drag group operations (add/remove from groups)
      final isCommandPressed = HardwareKeyboard.instance.isMetaPressed;
      for (final nodeId in draggedNodeIds) {
        annotations.handleCommandDragGroupOperation(nodeId, isCommandPressed);
      }

      // Clear drag highlight and drag state
      annotations.clearDragHighlight();
      interaction.draggedNodeId.value = null;
      interaction.lastPointerPosition.value = null;
    });
  }

  /// Optimized node movement that batches position and pointer updates
  void _moveNodeDrag(
    String draggedNodeId,
    Offset graphDelta,
    Offset newPointerPosition,
  ) {
    // Request focus only if canvas doesn't already have it (performance optimization)
    if (!canvasFocusNode.hasFocus) {
      canvasFocusNode.requestFocus();
    }
    runInAction(() {
      // Update pointer position
      interaction.lastPointerPosition.value = newPointerPosition;

      // Update node positions and visual positions
      if (selectedNodeIds.contains(draggedNodeId)) {
        // Move all selected nodes
        for (final nodeId in selectedNodeIds) {
          final node = nodes[nodeId];
          if (node != null) {
            final newPosition = node.position.value + graphDelta;
            node.position.value = newPosition;
            // Update visual position with snapping
            node.setVisualPosition(config.snapToGridIfEnabled(newPosition));
          }
        }
        // Update drag-to-group highlight for the dragged node (Command+drag only)
        final isCommandPressed = HardwareKeyboard.instance.isMetaPressed;
        annotations.updateDragHighlight(draggedNodeId, isCommandPressed);
      } else {
        // Move single node
        final node = nodes[draggedNodeId];
        if (node != null) {
          final newPosition = node.position.value + graphDelta;
          node.position.value = newPosition;
          // Update visual position with snapping
          node.setVisualPosition(config.snapToGridIfEnabled(newPosition));
          // Update drag-to-group highlight (Command+drag only)
          final isCommandPressed = HardwareKeyboard.instance.isMetaPressed;
          annotations.updateDragHighlight(draggedNodeId, isCommandPressed);
        }
      }
    });
  }

  void _setPointerPosition(Offset? position) {
    interaction.setPointerPosition(position);
  }

  /// Optimized temporary connection update that batches all changes
  void _updateTemporaryConnection(
    Offset screenPosition,
    Offset graphPosition,
    String? targetNodeId,
    String? targetPortId,
  ) {
    final temp = interaction.temporaryConnection.value;
    if (temp == null) return;

    runInAction(() {
      // Update pointer position
      interaction.lastPointerPosition.value = screenPosition;

      // Update connection state
      temp.currentPoint = graphPosition;
      if (temp.targetNodeId != targetNodeId) {
        temp.targetNodeId = targetNodeId;
      }
      if (temp.targetPortId != targetPortId) {
        temp.targetPortId = targetPortId;
      }
    });
  }

  void _updateInteractionState({MouseCursor? cursor, bool? panEnabled}) {
    interaction.update(cursor: cursor, panEnabled: panEnabled);
  }

  void _updateSelectionDrag({
    Offset? startPoint,
    Rect? rectangle,
    List<String>? intersectingNodes,
    bool? toggle,
  }) {
    interaction.updateSelection(
      startPoint: startPoint,
      rectangle: rectangle,
      intersectingNodes: intersectingNodes,
      toggle: toggle,
      selectNodes: selectNodes,
    );
  }

  void _finishSelectionDrag() => interaction.finishSelection();

  void _setTemporaryConnection(TemporaryConnection? connection) =>
      interaction.update(temporaryConnection: connection);
  void _cancelConnection() => interaction.cancelConnection();

  List<Connection> _startConnection(
    String nodeId,
    String portId,
    bool isOutput,
  ) {
    // Batch removal of existing connections if port doesn't allow multiple connections
    final connectionsToRemove = _getConnectionsToRemove(
      nodeId,
      portId,
      isOutput,
    );
    if (connectionsToRemove.isNotEmpty) {
      runInAction(() {
        for (final connection in connectionsToRemove) {
          removeConnection(connection.id);
        }
      });
    }
    return connectionsToRemove;
  }

  void _startAnnotationDrag(String annotationId, Offset pointerPosition) {
    annotations.internalStartAnnotationDrag(annotationId, pointerPosition);
    // Request focus only if canvas doesn't already have it
    if (!canvasFocusNode.hasFocus) {
      canvasFocusNode.requestFocus();
    }
  }

  void _moveAnnotationDrag(Offset pointerPosition, Offset graphDelta) {
    // Request focus only if canvas doesn't already have it (performance optimization)
    if (!canvasFocusNode.hasFocus) {
      canvasFocusNode.requestFocus();
    }
    annotations.internalMoveAnnotationDrag(pointerPosition, graphDelta, nodes);
  }

  void _endAnnotationDrag() {
    annotations.internalEndAnnotationDrag();
  }

  Connection? _completeConnection(String targetNodeId, String targetPortId) {
    if (interaction.connectionSourceNodeId != null &&
        interaction.connectionSourcePortId != null) {
      final sourceNodeId = interaction.connectionSourceNodeId!;
      final sourcePortId = interaction.connectionSourcePortId!;

      // Get connections to remove before batching
      final connectionsToRemove = _getConnectionsToRemove(
        targetNodeId,
        targetPortId,
        false,
      );

      // Batch all connection operations for instant visual update
      final createdConnection = runInAction(() {
        // Remove existing connections from target port if needed
        for (final connection in connectionsToRemove) {
          removeConnection(connection.id);
        }

        // Create the new connection
        final connection = Connection(
          id: '${sourceNodeId}_${sourcePortId}_${targetNodeId}_$targetPortId',
          sourceNodeId: sourceNodeId,
          sourcePortId: sourcePortId,
          targetNodeId: targetNodeId,
          targetPortId: targetPortId,
        );
        addConnection(connection);

        // Clear temporary connection state
        interaction.temporaryConnection.value = null;

        return connection;
      });

      return createdConnection;
    }

    return null;
  }
}
