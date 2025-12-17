part of '../node_flow_controller.dart';

/// Node-related operations for [NodeFlowController].
///
/// This extension provides methods for:
/// - Adding, removing, and modifying nodes
/// - Managing node ports (input/output)
/// - Moving and resizing nodes
/// - Node visibility control
/// - Rebuilding connection segments for nodes
extension NodeApi<T> on NodeFlowController<T> {
  // ============================================================================
  // Node CRUD Operations
  // ============================================================================

  /// Adds a new node to the graph.
  ///
  /// The node's position will be automatically snapped to the grid if snap-to-grid
  /// is enabled in the controller's configuration.
  ///
  /// Triggers the `onNodeCreated` callback after successful addition.
  ///
  /// Example:
  /// ```dart
  /// final node = Node<MyData>(
  ///   id: 'node1',
  ///   type: 'process',
  ///   position: Offset(100, 100),
  ///   data: MyData(),
  /// );
  /// controller.addNode(node);
  /// ```
  void addNode(Node<T> node) {
    runInAction(() {
      _nodes[node.id] = node;
      // Initialize visual position with snapping
      node.setVisualPosition(_config.snapToGridIfEnabled(node.position.value));
      // Note: Spatial index is auto-synced via MobX reaction
    });
    // Fire event after successful addition
    events.node?.onCreated?.call(node);
  }

  /// Removes a node from the graph along with all its connections.
  ///
  /// This method will:
  /// 1. Remove the node from the graph
  /// 2. Remove it from the selection if selected
  /// 3. Remove all connections involving this node
  /// 4. Remove the node from any group annotations
  /// 5. Delete empty group annotations that no longer contain any nodes
  ///
  /// Triggers the `onNodeDeleted` callback after successful removal.
  ///
  /// Parameters:
  /// - [nodeId]: The ID of the node to remove
  void removeNode(String nodeId) {
    final nodeToDelete = _nodes[nodeId]; // Capture before deletion
    runInAction(() {
      _nodes.remove(nodeId);
      _selectedNodeIds.remove(nodeId);
      // Remove from spatial index
      _spatialIndex.removeNode(nodeId);

      // Remove connections involving this node from spatial index first
      final connectionsToRemove = _connections
          .where((c) => c.sourceNodeId == nodeId || c.targetNodeId == nodeId)
          .toList();
      for (final connection in connectionsToRemove) {
        _spatialIndex.removeConnection(connection.id);
        // Also remove from path cache to prevent stale rendering
        _connectionPainter?.removeConnectionFromCache(connection.id);
      }

      // Then remove from connections list
      _connections.removeWhere(
        (c) => c.sourceNodeId == nodeId || c.targetNodeId == nodeId,
      );

      // Note: Annotations are notified via MobX reaction in AnnotationController
      // that watches _nodes.keys for additions/deletions
    });
    // Fire event after successful removal
    if (nodeToDelete != null) {
      events.node?.onDeleted?.call(nodeToDelete);
    }
  }

  // ============================================================================
  // Port Operations
  // ============================================================================

  /// Adds an input port to an existing node.
  ///
  /// Does nothing if the node with [nodeId] doesn't exist.
  ///
  /// Parameters:
  /// - [nodeId]: The ID of the node to add the port to
  /// - [port]: The port to add
  void addInputPort(String nodeId, Port port) {
    final node = _nodes[nodeId];
    if (node == null) return;

    node.addInputPort(port);
  }

  /// Adds an output port to an existing node.
  ///
  /// Does nothing if the node with [nodeId] doesn't exist.
  ///
  /// Parameters:
  /// - [nodeId]: The ID of the node to add the port to
  /// - [port]: The port to add
  void addOutputPort(String nodeId, Port port) {
    final node = _nodes[nodeId];
    if (node == null) return;

    node.addOutputPort(port);
  }

  /// Removes a port from a node and all connections involving that port.
  ///
  /// This method will:
  /// 1. Remove all connections where this port is the source or target
  /// 2. Remove the port from the node
  ///
  /// Does nothing if the node with [nodeId] doesn't exist.
  ///
  /// Parameters:
  /// - [nodeId]: The ID of the node containing the port
  /// - [portId]: The ID of the port to remove
  void removePort(String nodeId, String portId) {
    final node = _nodes[nodeId];
    if (node == null) return;

    runInAction(() {
      // Find connections involving this port
      final connectionsToRemove = _connections
          .where(
            (c) =>
                (c.sourceNodeId == nodeId && c.sourcePortId == portId) ||
                (c.targetNodeId == nodeId && c.targetPortId == portId),
          )
          .toList();

      // Remove from spatial index and path cache
      for (final connection in connectionsToRemove) {
        _spatialIndex.removeConnection(connection.id);
        _connectionPainter?.removeConnectionFromCache(connection.id);
      }

      // Remove from connections list
      _connections.removeWhere(
        (c) =>
            (c.sourceNodeId == nodeId && c.sourcePortId == portId) ||
            (c.targetNodeId == nodeId && c.targetPortId == portId),
      );

      // Remove the port using the node's dynamic method
      node.removePort(portId);
    });
  }

  /// Sets the input and/or output ports of a node.
  ///
  /// This replaces the existing ports with the provided lists. Pass `null` to
  /// leave a port type unchanged.
  ///
  /// Does nothing if the node with [nodeId] doesn't exist.
  ///
  /// Parameters:
  /// - [nodeId]: The ID of the node to update
  /// - [inputPorts]: New list of input ports (optional)
  /// - [outputPorts]: New list of output ports (optional)
  ///
  /// Example:
  /// ```dart
  /// controller.setNodePorts(
  ///   'node1',
  ///   inputPorts: [Port(id: 'in1', label: 'Input')],
  ///   outputPorts: [Port(id: 'out1', label: 'Output')],
  /// );
  /// ```
  void setNodePorts(
    String nodeId, {
    List<Port>? inputPorts,
    List<Port>? outputPorts,
  }) {
    final node = _nodes[nodeId];
    if (node == null) return;

    runInAction(() {
      // Update input ports if provided
      if (inputPorts != null) {
        node.inputPorts.clear();
        node.inputPorts.addAll(inputPorts);
      }

      // Update output ports if provided
      if (outputPorts != null) {
        node.outputPorts.clear();
        node.outputPorts.addAll(outputPorts);
      }
    });
  }

  // ============================================================================
  // Position and Size Operations
  // ============================================================================

  /// Sets the size of a node.
  ///
  /// Updates the node's size which will trigger reactive updates in the UI
  /// and automatically adjust port positions and connections.
  ///
  /// Does nothing if the node with [nodeId] doesn't exist.
  ///
  /// Parameters:
  /// - [nodeId]: The ID of the node to resize
  /// - [size]: The new size for the node
  ///
  /// Example:
  /// ```dart
  /// controller.setNodeSize('node1', Size(200, 150));
  /// ```
  void setNodeSize(String nodeId, Size size) {
    final node = _nodes[nodeId];
    if (node == null) return;

    runInAction(() {
      node.size.value = size;
    });
    internalMarkNodeDirty(nodeId);
  }

  /// Moves a node by the specified delta.
  ///
  /// The node's new position will be automatically snapped to the grid if
  /// snap-to-grid is enabled in the controller's configuration.
  ///
  /// Does nothing if the node doesn't exist.
  ///
  /// Parameters:
  /// - [nodeId]: The ID of the node to move
  /// - [delta]: The offset to move the node by
  void moveNode(String nodeId, Offset delta) {
    final node = _nodes[nodeId];
    if (node != null) {
      runInAction(() {
        final newPosition = node.position.value + delta;
        node.position.value = newPosition;
        // Update visual position with snapping
        node.setVisualPosition(_config.snapToGridIfEnabled(newPosition));
      });
      internalMarkNodeDirty(nodeId);
    }
  }

  /// Moves all selected nodes by the specified delta.
  ///
  /// The nodes' new positions will be automatically snapped to the grid if
  /// snap-to-grid is enabled in the controller's configuration.
  ///
  /// Does nothing if no nodes are selected.
  ///
  /// Parameters:
  /// - [delta]: The offset to move the selected nodes by
  void moveSelectedNodes(Offset delta) {
    final nodeIds = _selectedNodeIds.toList();
    if (nodeIds.isEmpty) return;

    runInAction(() {
      for (final nodeId in nodeIds) {
        final node = _nodes[nodeId];
        if (node != null) {
          final newPosition = node.position.value + delta;
          node.position.value = newPosition;
          // Update visual position with snapping
          node.setVisualPosition(_config.snapToGridIfEnabled(newPosition));
        }
      }
    });
    internalMarkNodesDirty(nodeIds);
  }

  // ============================================================================
  // Connection Segment Rebuilding
  // ============================================================================

  /// Rebuilds connection spatial index using accurate path segments.
  /// Call this after drag ends to restore accurate hit-testing.
  void rebuildConnectionSegmentsForNodes(List<String> nodeIds) {
    if (!isConnectionPainterInitialized || _theme == null) return;

    final nodeIdSet = nodeIds.toSet();
    final pathCache = _connectionPainter!.pathCache;
    final connectionStyle = _theme!.connectionTheme.style;

    for (final connection in _connections) {
      if (nodeIdSet.contains(connection.sourceNodeId) ||
          nodeIdSet.contains(connection.targetNodeId)) {
        final sourceNode = _nodes[connection.sourceNodeId];
        final targetNode = _nodes[connection.targetNodeId];
        if (sourceNode == null || targetNode == null) continue;

        final segments = pathCache.getOrCreateSegmentBounds(
          connection: connection,
          sourceNode: sourceNode,
          targetNode: targetNode,
          connectionStyle: connectionStyle,
        );
        _spatialIndex.updateConnection(connection, segments);
      }
    }
  }

  /// Rebuilds the entire connection spatial index using accurate path segments.
  void rebuildAllConnectionSegments() {
    if (!isConnectionPainterInitialized || _theme == null) return;

    final pathCache = _connectionPainter!.pathCache;
    final connectionStyle = _theme!.connectionTheme.style;

    _spatialIndex.rebuildConnectionsWithSegments(_connections, (connection) {
      final sourceNode = _nodes[connection.sourceNodeId];
      final targetNode = _nodes[connection.targetNodeId];
      if (sourceNode == null || targetNode == null) return [];

      return pathCache.getOrCreateSegmentBounds(
        connection: connection,
        sourceNode: sourceNode,
        targetNode: targetNode,
        connectionStyle: connectionStyle,
      );
    });
  }

  /// Rebuilds spatial index for a single connection using accurate path segments.
  /// Call this after control point changes to restore accurate hit-testing.
  void _rebuildSingleConnectionSpatialIndex(Connection connection) {
    if (!isConnectionPainterInitialized || _theme == null) return;

    final sourceNode = _nodes[connection.sourceNodeId];
    final targetNode = _nodes[connection.targetNodeId];
    if (sourceNode == null || targetNode == null) return;

    final pathCache = _connectionPainter!.pathCache;
    final connectionStyle = _theme!.connectionTheme.style;

    final segments = pathCache.getOrCreateSegmentBounds(
      connection: connection,
      sourceNode: sourceNode,
      targetNode: targetNode,
      connectionStyle: connectionStyle,
    );
    _spatialIndex.updateConnection(connection, segments);
  }

  // ============================================================================
  // Node Visibility Operations
  // ============================================================================

  /// Sets the visibility of a specific node.
  ///
  /// When a node is hidden:
  /// - It is not rendered on the canvas
  /// - Its ports cannot participate in new connections
  /// - Existing connections to/from this node are not rendered
  /// - The node is excluded from hit testing
  ///
  /// Parameters:
  /// - [nodeId]: The ID of the node to modify
  /// - [visible]: Whether the node should be visible
  ///
  /// Does nothing if the node doesn't exist.
  void setNodeVisibility(String nodeId, bool visible) {
    final node = _nodes[nodeId];
    if (node == null) return;

    runInAction(() {
      node.isVisible = visible;
    });
  }

  /// Sets visibility for multiple nodes at once.
  ///
  /// More efficient than calling [setNodeVisibility] multiple times
  /// as it batches the MobX action.
  ///
  /// Parameters:
  /// - [nodeIds]: List of node IDs to modify
  /// - [visible]: Whether the nodes should be visible
  void setNodesVisibility(List<String> nodeIds, bool visible) {
    if (nodeIds.isEmpty) return;

    runInAction(() {
      for (final nodeId in nodeIds) {
        final node = _nodes[nodeId];
        if (node != null) {
          node.isVisible = visible;
        }
      }
    });
  }

  /// Toggles visibility of a specific node.
  ///
  /// If the node is visible, it becomes hidden. If hidden, it becomes visible.
  ///
  /// Parameters:
  /// - [nodeId]: The ID of the node to toggle
  ///
  /// Returns the new visibility state, or null if node doesn't exist.
  bool? toggleNodeVisibility(String nodeId) {
    final node = _nodes[nodeId];
    if (node == null) return null;

    final newVisibility = !node.isVisible;
    runInAction(() {
      node.isVisible = newVisibility;
    });
    return newVisibility;
  }

  /// Hides all nodes in the graph.
  ///
  /// This will also hide all connections since connections require
  /// both source and target nodes to be visible.
  void hideAllNodes() {
    if (_nodes.isEmpty) return;

    runInAction(() {
      for (final node in _nodes.values) {
        node.isVisible = false;
      }
    });
  }

  /// Shows all nodes in the graph.
  ///
  /// Restores visibility for all nodes. Connections will become visible
  /// when both their source and target nodes are visible.
  void showAllNodes() {
    if (_nodes.isEmpty) return;

    runInAction(() {
      for (final node in _nodes.values) {
        node.isVisible = true;
      }
    });
  }

  /// Hides all currently selected nodes.
  ///
  /// Selection is preserved but nodes are hidden from view.
  void hideSelectedNodes() {
    if (_selectedNodeIds.isEmpty) return;

    runInAction(() {
      for (final nodeId in _selectedNodeIds) {
        final node = _nodes[nodeId];
        if (node != null) {
          node.isVisible = false;
        }
      }
    });
  }

  /// Shows all currently selected nodes.
  ///
  /// Makes all selected nodes visible again.
  void showSelectedNodes() {
    if (_selectedNodeIds.isEmpty) return;

    runInAction(() {
      for (final nodeId in _selectedNodeIds) {
        final node = _nodes[nodeId];
        if (node != null) {
          node.isVisible = true;
        }
      }
    });
  }

  /// Gets all visible nodes in the graph.
  ///
  /// Returns a list of nodes where [Node.isVisible] is true.
  List<Node<T>> getVisibleNodes() {
    return _nodes.values.where((node) => node.isVisible).toList();
  }

  /// Gets all hidden nodes in the graph.
  ///
  /// Returns a list of nodes where [Node.isVisible] is false.
  List<Node<T>> getHiddenNodes() {
    return _nodes.values.where((node) => !node.isVisible).toList();
  }

  /// Gets all visible connections in the graph.
  ///
  /// A connection is visible when both its source and target nodes are visible.
  List<Connection> getVisibleConnections() {
    return _connections.where((connection) {
      final sourceNode = _nodes[connection.sourceNodeId];
      final targetNode = _nodes[connection.targetNodeId];
      return sourceNode != null &&
          targetNode != null &&
          sourceNode.isVisible &&
          targetNode.isVisible;
    }).toList();
  }

  /// Gets all hidden connections in the graph.
  ///
  /// A connection is hidden when either its source or target node is hidden.
  List<Connection> getHiddenConnections() {
    return _connections.where((connection) {
      final sourceNode = _nodes[connection.sourceNodeId];
      final targetNode = _nodes[connection.targetNodeId];
      return sourceNode == null ||
          targetNode == null ||
          !sourceNode.isVisible ||
          !targetNode.isVisible;
    }).toList();
  }
}
