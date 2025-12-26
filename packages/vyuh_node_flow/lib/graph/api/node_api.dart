part of '../node_flow_controller.dart';

/// Node-related operations for [NodeFlowController].
///
/// This extension provides comprehensive APIs for working with nodes:
///
/// ## Model APIs
/// - [getNode], [getNodeIds], [nodeCount] - Lookup operations
/// - [addNode], [removeNode], [duplicateNode], [deleteNodes] - CRUD operations
///
/// ## Port APIs
/// - [getPort], [getPortWorldPosition] - Port lookup
/// - [addInputPort], [addOutputPort], [removePort], [setNodePorts] - Port CRUD
///
/// ## Visual Query APIs
/// - [getNodeBounds] - Node bounds queries (graph bounds are in [GraphApi] and [ViewportApi])
/// - [getVisibleNodes], [getHiddenNodes] - Visibility queries
/// - (Graph analysis methods like getOrphanNodes are in [GraphApi])
///
/// ## Mutation APIs
/// - [moveNode], [moveSelectedNodes], [setNodePosition] - Position changes
/// - [setNodeSize] - Size changes
/// - [setNodeVisibility], [toggleNodeVisibility] - Visibility changes
///
/// ## Selection APIs
/// - [selectNode], [selectNodes], [clearNodeSelection] - Selection management
/// - (Bulk selection methods are in [GraphApi])
///
/// ## Z-Order APIs
/// - [bringNodeToFront], [sendNodeToBack] - Extreme positioning
/// - [bringNodeForward], [sendNodeBackward] - Incremental positioning
///
/// ## Layout APIs
/// - [alignNodes] - Alignment operations
/// - [distributeNodesHorizontally], [distributeNodesVertically] - Distribution
extension NodeApi<T> on NodeFlowController<T> {
  // ============================================================================
  // Model APIs - Lookup
  // ============================================================================

  /// Gets a node by its ID.
  ///
  /// Returns `null` if the node doesn't exist.
  ///
  /// Example:
  /// ```dart
  /// final node = controller.getNode('node1');
  /// if (node != null) {
  ///   print('Node type: ${node.type}');
  /// }
  /// ```
  Node<T>? getNode(String nodeId) => _nodes[nodeId];

  /// Gets all node IDs in the graph.
  ///
  /// Returns an iterable of all node IDs.
  Iterable<String> get nodeIds => _nodes.keys;

  /// Gets the total number of nodes in the graph.
  int get nodeCount => _nodes.length;

  /// Gets all nodes of a specific type.
  ///
  /// Example:
  /// ```dart
  /// final processNodes = controller.getNodesByType('process');
  /// ```
  List<Node<T>> getNodesByType(String type) {
    return _nodes.values.where((node) => node.type == type).toList();
  }

  // ============================================================================
  // Model APIs - CRUD
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

      // Attach context for nodes with GroupableMixin (e.g., GroupNode)
      // This enables the node to monitor child nodes, look up other nodes, etc.
      if (node is GroupableMixin<T>) {
        node.attachContext(_createGroupableContext());
      }
    });
    // Fire event after successful addition
    events.node?.onCreated?.call(node);
    // Emit extension event
    _emitEvent(NodeAdded<T>(node));
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
  void removeNode(String nodeId) {
    final nodeToDelete = _nodes[nodeId]; // Capture before deletion
    if (nodeToDelete == null) return;

    // Capture connections to emit events for
    final connectionsToRemove = _connections
        .where((c) => c.sourceNodeId == nodeId || c.targetNodeId == nodeId)
        .toList();

    runInAction(() {
      // Detach context for nodes with GroupableMixin before removal
      // This disposes MobX reactions and cleans up the context
      if (nodeToDelete is GroupableMixin<T>) {
        nodeToDelete.detachContext();
      }

      _nodes.remove(nodeId);
      _selectedNodeIds.remove(nodeId);
      // Remove from spatial index
      _spatialIndex.removeNode(nodeId);

      // Remove connections involving this node from spatial index first
      for (final connection in connectionsToRemove) {
        _spatialIndex.removeConnection(connection.id);
        // Also remove from path cache to prevent stale rendering
        _connectionPainter?.removeConnectionFromCache(connection.id);
      }

      // Then remove from connections list
      _connections.removeWhere(
        (c) => c.sourceNodeId == nodeId || c.targetNodeId == nodeId,
      );

      // Note: Groupable nodes (like GroupNode) are notified of deletions via MobX reaction
      // in _setupNodeMonitoringReactions that watches _nodes.keys for additions/deletions
    });
    // Fire event after successful removal
    events.node?.onDeleted?.call(nodeToDelete);
    // Emit extension events for removed connections first
    for (final connection in connectionsToRemove) {
      _emitEvent(ConnectionRemoved(connection));
    }
    // Emit extension event for removed node
    _emitEvent(NodeRemoved<T>(nodeToDelete));
  }

  /// Creates a duplicate of a node and adds it to the graph.
  ///
  /// The duplicated node:
  /// - Has a new auto-generated ID
  /// - Is positioned 50 pixels down and right from the original
  /// - Has a cloned copy of the data if it implements [NodeData]
  /// - Has the same type, size, and ports as the original
  ///
  /// Does nothing if the node doesn't exist.
  ///
  /// Example:
  /// ```dart
  /// controller.duplicateNode('node1');
  /// ```
  void duplicateNode(String nodeId) {
    final node = _nodes[nodeId];
    if (node == null) return;

    // Clone the data if it implements NodeData interface
    final clonedData = node.data is NodeData
        ? (node.data as NodeData).clone() as T
        : node.data;

    final duplicatedNode = Node<T>(
      id: '${node.id}_copy_${DateTime.now().millisecondsSinceEpoch}',
      type: node.type,
      position: node.position.value + const Offset(50, 50),
      data: clonedData,
      size: node.size.value,
      inputPorts: node.inputPorts,
      outputPorts: node.outputPorts,
    );

    addNode(duplicatedNode);
  }

  /// Deletes multiple nodes from the graph.
  ///
  /// This is a convenience method for batch deletion. Each node removal also
  /// removes its associated connections.
  ///
  /// Example:
  /// ```dart
  /// controller.deleteNodes(['node1', 'node2', 'node3']);
  /// ```
  void deleteNodes(List<String> nodeIds) {
    runInAction(() {
      for (final nodeId in nodeIds) {
        removeNode(nodeId);
      }
    });
  }

  // ============================================================================
  // Port APIs - Lookup
  // ============================================================================

  /// Gets a specific port from a node.
  ///
  /// Searches both input and output ports.
  /// Returns `null` if the node or port doesn't exist.
  ///
  /// Example:
  /// ```dart
  /// final port = controller.getPort('node1', 'output1');
  /// if (port != null) {
  ///   print('Port type: ${port.type}');
  /// }
  /// ```
  Port? getPort(String nodeId, String portId) {
    final node = _nodes[nodeId];
    if (node == null) return null;

    // Search input ports
    for (final port in node.inputPorts) {
      if (port.id == portId) return port;
    }

    // Search output ports
    for (final port in node.outputPorts) {
      if (port.id == portId) return port;
    }

    return null;
  }

  /// Gets the world position of a port.
  ///
  /// Returns the center position of the port in graph coordinates.
  /// Returns `null` if the node or port doesn't exist.
  ///
  /// Example:
  /// ```dart
  /// final position = controller.getPortWorldPosition('node1', 'output1');
  /// if (position != null) {
  ///   print('Port at: $position');
  /// }
  /// ```
  Offset? getPortWorldPosition(String nodeId, String portId) {
    final node = _nodes[nodeId];
    if (node == null) return null;

    final port = getPort(nodeId, portId);
    if (port == null) return null;

    // Use the node's getPortCenter method which handles coordinate conversion
    // We need the theme to get the port size for accurate calculations
    if (_theme == null) return null;
    final portSize = _theme!.portTheme.resolveSize(port);

    try {
      return node.getPortCenter(
        portId,
        portSize: portSize,
        shape: _nodeShapeBuilder?.call(node),
      );
    } catch (_) {
      return null;
    }
  }

  /// Gets all input ports for a node.
  ///
  /// Returns an empty list if the node doesn't exist.
  List<Port> getInputPorts(String nodeId) {
    final node = _nodes[nodeId];
    return node?.inputPorts.toList() ?? [];
  }

  /// Gets all output ports for a node.
  ///
  /// Returns an empty list if the node doesn't exist.
  List<Port> getOutputPorts(String nodeId) {
    final node = _nodes[nodeId];
    return node?.outputPorts.toList() ?? [];
  }

  // ============================================================================
  // Port APIs - CRUD
  // ============================================================================

  /// Adds an input port to an existing node.
  ///
  /// Does nothing if the node with [nodeId] doesn't exist.
  void addInputPort(String nodeId, Port port) {
    final node = _nodes[nodeId];
    if (node == null) return;

    node.addInputPort(port);
  }

  /// Adds an output port to an existing node.
  ///
  /// Does nothing if the node with [nodeId] doesn't exist.
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
      if (inputPorts != null) {
        node.inputPorts.clear();
        node.inputPorts.addAll(inputPorts);
      }

      if (outputPorts != null) {
        node.outputPorts.clear();
        node.outputPorts.addAll(outputPorts);
      }
    });
  }

  // ============================================================================
  // Visual Query APIs - Bounds
  // ============================================================================

  /// Gets the bounding rectangle for a specific node.
  ///
  /// Returns `null` if the node doesn't exist.
  ///
  /// Example:
  /// ```dart
  /// final bounds = controller.getNodeBounds('node1');
  /// if (bounds != null) {
  ///   print('Node size: ${bounds.width} x ${bounds.height}');
  /// }
  /// ```
  Rect? getNodeBounds(String nodeId) {
    final node = _nodes[nodeId];
    if (node == null) return null;

    return node.getBounds();
  }

  // ============================================================================
  // Visual Query APIs - Visibility
  // ============================================================================

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

  // ============================================================================
  // Mutation APIs - Position
  // ============================================================================

  /// Moves a node by the specified delta.
  ///
  /// The node's new position will be automatically snapped to the grid if
  /// snap-to-grid is enabled in the controller's configuration.
  ///
  /// Does nothing if the node doesn't exist.
  void moveNode(String nodeId, Offset delta) {
    final node = _nodes[nodeId];
    if (node != null) {
      final previousPosition = node.position.value;
      runInAction(() {
        final newPosition = previousPosition + delta;
        node.position.value = newPosition;
        // Update visual position with snapping
        node.setVisualPosition(_config.snapToGridIfEnabled(newPosition));
      });
      internalMarkNodeDirty(nodeId);
      // Emit extension event
      _emitEvent(NodeMoved<T>(node, previousPosition));
    }
  }

  /// Moves all selected nodes by the specified delta.
  ///
  /// Does nothing if no nodes are selected.
  void moveSelectedNodes(Offset delta) {
    final nodeIds = _selectedNodeIds.toList();
    if (nodeIds.isEmpty) return;

    // Capture previous positions for events
    final previousPositions = <String, Offset>{};
    for (final nodeId in nodeIds) {
      final node = _nodes[nodeId];
      if (node != null) {
        previousPositions[nodeId] = node.position.value;
      }
    }

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

    // Emit extension events for each moved node
    for (final nodeId in nodeIds) {
      final node = _nodes[nodeId];
      final previousPosition = previousPositions[nodeId];
      if (node != null && previousPosition != null) {
        _emitEvent(NodeMoved<T>(node, previousPosition));
      }
    }
  }

  /// Sets a node's position to an absolute position.
  ///
  /// The position will be automatically snapped to the grid if snap-to-grid
  /// is enabled in the controller's configuration.
  ///
  /// Example:
  /// ```dart
  /// controller.setNodePosition('node1', Offset(200, 150));
  /// ```
  void setNodePosition(String nodeId, Offset position) {
    final node = _nodes[nodeId];
    if (node != null) {
      final previousPosition = node.position.value;
      runInAction(() {
        node.position.value = position;
        node.setVisualPosition(_config.snapToGridIfEnabled(position));
      });
      internalMarkNodeDirty(nodeId);
      // Emit extension event
      _emitEvent(NodeMoved<T>(node, previousPosition));
    }
  }

  // ============================================================================
  // Mutation APIs - Size
  // ============================================================================

  /// Sets the size of a node.
  ///
  /// Updates the node's size which will trigger reactive updates in the UI
  /// and automatically adjust port positions and connections.
  ///
  /// Example:
  /// ```dart
  /// controller.setNodeSize('node1', Size(200, 150));
  /// ```
  void setNodeSize(String nodeId, Size size) {
    final node = _nodes[nodeId];
    if (node == null) return;

    final previousSize = node.size.value;
    runInAction(() {
      node.size.value = size;
    });
    internalMarkNodeDirty(nodeId);
    // Emit extension event
    _emitEvent(NodeResized<T>(node, previousSize));
  }

  // ============================================================================
  // Mutation APIs - Visibility
  // ============================================================================

  /// Sets the visibility of a specific node.
  ///
  /// When a node is hidden:
  /// - It is not rendered on the canvas
  /// - Its ports cannot participate in new connections
  /// - Existing connections to/from this node are not rendered
  /// - The node is excluded from hit testing
  void setNodeVisibility(String nodeId, bool visible) {
    final node = _nodes[nodeId];
    if (node == null) return;

    final wasVisible = node.isVisible;
    runInAction(() {
      node.isVisible = visible;
    });
    // Emit extension event
    _emitEvent(NodeVisibilityChanged<T>(node, wasVisible));
  }

  /// Sets visibility for multiple nodes at once.
  ///
  /// More efficient than calling [setNodeVisibility] multiple times
  /// as it batches the MobX action.
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
  void hideAllNodes() {
    if (_nodes.isEmpty) return;

    runInAction(() {
      for (final node in _nodes.values) {
        node.isVisible = false;
      }
    });
  }

  /// Shows all nodes in the graph.
  void showAllNodes() {
    if (_nodes.isEmpty) return;

    runInAction(() {
      for (final node in _nodes.values) {
        node.isVisible = true;
      }
    });
  }

  /// Hides all currently selected nodes.
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

  // ============================================================================
  // Selection APIs
  // ============================================================================

  /// Selects a node in the graph.
  ///
  /// Automatically clears connection selections.
  /// Requests canvas focus if not already focused.
  ///
  /// Triggers the `onNodeSelected` callback after selection changes.
  ///
  /// Parameters:
  /// - [nodeId]: The ID of the node to select
  /// - [toggle]: If `true`, toggles the node's selection state. If `false` (default),
  ///   clears other node selections and selects only this node.
  ///
  /// Example:
  /// ```dart
  /// // Select single node
  /// controller.selectNode('node1');
  ///
  /// // Toggle node selection (for multi-select)
  /// controller.selectNode('node2', toggle: true);
  /// ```
  void selectNode(String nodeId, {bool toggle = false}) {
    runInAction(() {
      // Clear connection selections
      clearConnectionSelection();

      if (toggle) {
        if (_selectedNodeIds.contains(nodeId)) {
          _selectedNodeIds.remove(nodeId);
          final node = _nodes[nodeId];
          if (node != null) {
            node.selected.value = false;
          }
        } else {
          _selectedNodeIds.add(nodeId);
          final node = _nodes[nodeId];
          if (node != null) {
            node.selected.value = true;
          }
        }
      } else {
        // Clear previous node selection
        clearNodeSelection();

        // Select new node
        _selectedNodeIds.add(nodeId);
        final node = _nodes[nodeId];
        if (node != null) {
          node.selected.value = true;
        }
      }
    });

    // Fire selection callback with current selection state
    final selectedNode = _selectedNodeIds.contains(nodeId)
        ? _nodes[nodeId]
        : null;
    events.node?.onSelected?.call(selectedNode);

    if (!canvasFocusNode.hasFocus) {
      canvasFocusNode.requestFocus();
    }
  }

  /// Selects multiple nodes in the graph.
  ///
  /// Automatically clears connection selections.
  ///
  /// Example:
  /// ```dart
  /// // Replace selection with multiple nodes
  /// controller.selectNodes(['node1', 'node2', 'node3']);
  ///
  /// // Toggle multiple nodes (for multi-select)
  /// controller.selectNodes(['node4', 'node5'], toggle: true);
  /// ```
  void selectNodes(List<String> nodeIds, {bool toggle = false}) {
    runInAction(() {
      // Clear connection selections
      clearConnectionSelection();

      if (toggle) {
        for (final nodeId in nodeIds) {
          final node = _nodes[nodeId];
          if (node != null) {
            if (_selectedNodeIds.contains(nodeId)) {
              _selectedNodeIds.remove(nodeId);
              node.selected.value = false;
            } else {
              _selectedNodeIds.add(nodeId);
              node.selected.value = true;
            }
          }
        }
      } else {
        clearNodeSelection();

        for (final nodeId in nodeIds) {
          _selectedNodeIds.add(nodeId);
          final node = _nodes[nodeId];
          if (node != null) {
            node.selected.value = true;
          }
        }
      }
    });

    if (!canvasFocusNode.hasFocus) {
      canvasFocusNode.requestFocus();
    }
  }

  /// Clears all node selections.
  ///
  /// Triggers the `onNodeSelected` callback with `null` to indicate no selection.
  void clearNodeSelection() {
    if (_selectedNodeIds.isEmpty) return;

    for (final id in _selectedNodeIds) {
      final node = _nodes[id];
      if (node != null) {
        node.selected.value = false;
      }
    }
    _selectedNodeIds.clear();

    events.node?.onSelected?.call(null);
  }

  /// Checks if a node is currently selected.
  bool isNodeSelected(String nodeId) => _selectedNodeIds.contains(nodeId);

  // ============================================================================
  // Z-Order APIs
  // ============================================================================

  /// Brings a node to the front of the z-order (renders on top of all other nodes).
  void bringNodeToFront(String nodeId) {
    final node = _nodes[nodeId];
    if (node != null) {
      runInAction(() {
        final maxZIndex = _nodes.values
            .map((n) => n.zIndex.value)
            .fold(0, math.max);
        node.zIndex.value = maxZIndex + 1;
      });
    }
  }

  /// Sends a node to the back of the z-order (renders behind all other nodes).
  void sendNodeToBack(String nodeId) {
    final node = _nodes[nodeId];
    if (node != null) {
      runInAction(() {
        final minZIndex = _nodes.values
            .map((n) => n.zIndex.value)
            .fold(0, math.min);
        node.zIndex.value = minZIndex - 1;
      });
    }
  }

  /// Moves a node one step forward in the z-order.
  ///
  /// Swaps the z-index with the next higher node in the visual stack.
  void bringNodeForward(String nodeId) {
    final node = _nodes[nodeId];
    if (node == null) return;

    runInAction(() {
      final sortedNodes = _nodes.values.toList()
        ..sort((a, b) => a.zIndex.value.compareTo(b.zIndex.value));

      final currentIndex = sortedNodes.indexOf(node);

      if (currentIndex < sortedNodes.length - 1) {
        final nextNode = sortedNodes[currentIndex + 1];

        if (node.zIndex.value == nextNode.zIndex.value) {
          for (int i = 0; i < sortedNodes.length; i++) {
            sortedNodes[i].zIndex.value = i;
          }
          node.zIndex.value = currentIndex + 1;
          nextNode.zIndex.value = currentIndex;
        } else {
          final currentZ = node.zIndex.value;
          final nextZ = nextNode.zIndex.value;
          node.zIndex.value = nextZ;
          nextNode.zIndex.value = currentZ;
        }
      }
    });
  }

  /// Moves a node one step backward in the z-order.
  ///
  /// Swaps the z-index with the next lower node in the visual stack.
  void sendNodeBackward(String nodeId) {
    final node = _nodes[nodeId];
    if (node == null) return;

    runInAction(() {
      final sortedNodes = _nodes.values.toList()
        ..sort((a, b) => a.zIndex.value.compareTo(b.zIndex.value));

      final currentIndex = sortedNodes.indexOf(node);

      if (currentIndex > 0) {
        final prevNode = sortedNodes[currentIndex - 1];

        if (node.zIndex.value == prevNode.zIndex.value) {
          for (int i = 0; i < sortedNodes.length; i++) {
            sortedNodes[i].zIndex.value = i;
          }
          node.zIndex.value = currentIndex - 1;
          prevNode.zIndex.value = currentIndex;
        } else {
          final currentZ = node.zIndex.value;
          final prevZ = prevNode.zIndex.value;
          node.zIndex.value = prevZ;
          prevNode.zIndex.value = currentZ;
        }
      }
    });
  }

  // ============================================================================
  // Layout APIs
  // ============================================================================

  /// Aligns multiple nodes according to the specified alignment option.
  ///
  /// Requires at least 2 nodes. Calculates alignment based on the bounds
  /// of all specified nodes.
  ///
  /// Example:
  /// ```dart
  /// controller.alignNodes(
  ///   ['node1', 'node2', 'node3'],
  ///   NodeAlignment.left,
  /// );
  /// ```
  void alignNodes(List<String> nodeIds, NodeAlignment alignment) {
    if (nodeIds.length < 2) return;

    final nodes = nodeIds.map((id) => _nodes[id]).whereType<Node<T>>().toList();
    if (nodes.length < 2) return;

    final bounds = _calculateNodesBounds(nodes);
    if (bounds == null) return;

    final leftmost = bounds.left;
    final rightmost = bounds.right;
    final topmost = bounds.top;
    final bottommost = bounds.bottom;
    final centerX = bounds.center.dx;
    final centerY = bounds.center.dy;

    runInAction(() {
      for (final node in nodes) {
        final currentPos = node.position.value;
        double newX = currentPos.dx;
        double newY = currentPos.dy;

        switch (alignment) {
          case NodeAlignment.left:
            newX = leftmost;
          case NodeAlignment.right:
            newX = rightmost - node.size.value.width;
          case NodeAlignment.top:
            newY = topmost;
          case NodeAlignment.bottom:
            newY = bottommost - node.size.value.height;
          case NodeAlignment.center:
            newX = centerX - node.size.value.width / 2;
            newY = centerY - node.size.value.height / 2;
          case NodeAlignment.horizontalCenter:
            newX = centerX - node.size.value.width / 2;
          case NodeAlignment.verticalCenter:
            newY = centerY - node.size.value.height / 2;
        }

        final newPosition = Offset(newX, newY);
        node.position.value = newPosition;
        node.setVisualPosition(_config.snapToGridIfEnabled(newPosition));
      }
    });

    internalMarkNodesDirty(nodeIds);
    rebuildConnectionSegmentsForNodes(nodeIds);
  }

  /// Distributes nodes evenly along the horizontal axis.
  ///
  /// Requires at least 3 nodes. Sorts nodes by X position, keeps the leftmost
  /// and rightmost nodes in place, and distributes the middle nodes evenly.
  void distributeNodesHorizontally(List<String> nodeIds) {
    if (nodeIds.length < 3) return;

    final nodes = nodeIds.map((id) => _nodes[id]).whereType<Node<T>>().toList();
    if (nodes.length < 3) return;

    nodes.sort((a, b) => a.position.value.dx.compareTo(b.position.value.dx));

    final leftmost = nodes.first.position.value.dx;
    final rightmost = nodes.last.position.value.dx;
    final spacing = (rightmost - leftmost) / (nodes.length - 1);

    runInAction(() {
      for (int i = 1; i < nodes.length - 1; i++) {
        final targetX = leftmost + spacing * i;
        final newPosition = Offset(targetX, nodes[i].position.value.dy);
        nodes[i].position.value = newPosition;
        nodes[i].setVisualPosition(_config.snapToGridIfEnabled(newPosition));
      }
    });

    internalMarkNodesDirty(nodeIds);
    rebuildConnectionSegmentsForNodes(nodeIds);
  }

  /// Distributes nodes evenly along the vertical axis.
  ///
  /// Requires at least 3 nodes. Sorts nodes by Y position, keeps the topmost
  /// and bottommost nodes in place, and distributes the middle nodes evenly.
  void distributeNodesVertically(List<String> nodeIds) {
    if (nodeIds.length < 3) return;

    final nodes = nodeIds.map((id) => _nodes[id]).whereType<Node<T>>().toList();
    if (nodes.length < 3) return;

    nodes.sort((a, b) => a.position.value.dy.compareTo(b.position.value.dy));

    final topmost = nodes.first.position.value.dy;
    final bottommost = nodes.last.position.value.dy;
    final spacing = (bottommost - topmost) / (nodes.length - 1);

    runInAction(() {
      for (int i = 1; i < nodes.length - 1; i++) {
        final targetY = topmost + spacing * i;
        final newPosition = Offset(nodes[i].position.value.dx, targetY);
        nodes[i].position.value = newPosition;
        nodes[i].setVisualPosition(_config.snapToGridIfEnabled(newPosition));
      }
    });

    internalMarkNodesDirty(nodeIds);
    rebuildConnectionSegmentsForNodes(nodeIds);
  }

  // ============================================================================
  // Connection Segment Rebuilding (Internal)
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
}
