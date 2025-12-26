part of '../node_flow_controller.dart';

/// Graph-level operations for [NodeFlowController].
///
/// This extension provides methods for:
/// - Loading and exporting complete graphs
/// - Graph analysis and validation
/// - Layout and arrangement operations
/// - Batch selection operations
/// - Theme and event configuration
/// - Keyboard shortcuts
extension GraphApi<T> on NodeFlowController<T> {
  // ============================================================================
  // Graph Loading & Export
  // ============================================================================

  /// Loads a complete graph into the controller.
  ///
  /// This method:
  /// 1. Clears the existing graph state
  /// 2. Bulk loads all nodes and connections
  /// 3. Sets the viewport to match the saved state
  /// 4. Sets up visual positioning and hit-testing infrastructure
  /// 5. Sets up node monitoring for GroupNode and CommentNode
  ///
  /// This is the preferred method for loading saved graphs as it performs
  /// efficient bulk loading rather than individual additions.
  ///
  /// Parameters:
  /// - `graph`: The graph to load containing nodes, connections, and viewport state
  ///
  /// Example:
  /// ```dart
  /// final graph = NodeGraph<MyData>(
  ///   nodes: savedNodes,
  ///   connections: savedConnections,
  ///   viewport: savedViewport,
  /// );
  /// controller.loadGraph(graph);
  /// ```
  void loadGraph(NodeGraph<T> graph) {
    runInAction(() {
      // Clear existing state
      clearGraph();

      // Bulk load all data structures without infrastructure setup
      for (final node in graph.nodes) {
        _nodes[node.id] = node;
      }
      _connections.addAll(graph.connections);

      // Set viewport
      _viewport.value = graph.viewport;

      // Single infrastructure setup call after bulk loading
      _setupLoadedGraphInfrastructure();
    });
  }

  /// Sets up all necessary infrastructure after bulk loading graph data.
  ///
  /// This includes visual positioning, hit-testing setup, node context attachment,
  /// and other post-load configuration.
  void _setupLoadedGraphInfrastructure() {
    // Setup node visual positions with snapping and attach context for groupable nodes
    for (final node in _nodes.values) {
      node.setVisualPosition(_config.snapToGridIfEnabled(node.position.value));

      // Attach context for nodes with GroupableMixin (e.g., GroupNode)
      if (node is GroupableMixin<T>) {
        node.attachContext(_createGroupableContext());
      }
    }

    // Rebuild spatial indexes for hit testing
    _spatialIndex.rebuildFromNodes(_nodes.values);
    _spatialIndex.rebuildConnections(
      _connections,
      (connection) => _calculateConnectionBounds(connection) ?? Rect.zero,
    );
  }

  /// Exports the current graph state including all nodes, connections, and viewport.
  ///
  /// This creates a snapshot of the entire graph that can be serialized and saved.
  /// Use `loadGraph` to restore the graph from the exported data.
  ///
  /// Note: GroupNode and CommentNode are included in the nodes list and will be
  /// serialized with their specific type fields for proper deserialization.
  ///
  /// Returns a [NodeGraph] containing all current graph data.
  ///
  /// Example:
  /// ```dart
  /// // Export the graph
  /// final graph = controller.exportGraph();
  ///
  /// // Save to JSON
  /// final json = graph.toJson();
  /// ```
  NodeGraph<T> exportGraph() {
    return NodeGraph<T>(
      nodes: _nodes.values.toList(),
      connections: _connections,
      viewport: _viewport.value,
    );
  }

  /// Clears the entire graph, removing all nodes, connections, and selections.
  ///
  /// This operation:
  /// - Removes all nodes (including GroupNode and CommentNode)
  /// - Removes all connections
  /// - Clears all selections
  /// - Clears node monitoring reactions
  /// - Clears the connection painter cache
  ///
  /// Does nothing if the graph is already empty.
  ///
  /// Example:
  /// ```dart
  /// controller.clearGraph();
  /// ```
  void clearGraph() {
    if (_nodes.isEmpty && _connections.isEmpty) return;

    // Detach context from groupable nodes before clearing
    for (final node in _nodes.values) {
      if (node is GroupableMixin<T>) {
        node.detachContext();
      }
    }

    runInAction(() {
      _nodes.clear();
      _connections.clear();
      _selectedNodeIds.clear();
      _selectedConnectionIds.clear();
    });

    // Clear spatial indexes to prevent stale hit test entries
    _spatialIndex.clear();

    // Clear connection painter cache to prevent stale paths
    _connectionPainter?.clearAllCachedPaths();
  }

  // ============================================================================
  // Graph Analysis
  // ============================================================================

  /// Gets all nodes that have no connections.
  ///
  /// Returns a list of nodes that are neither sources nor targets of any connections.
  /// Useful for identifying isolated or unused nodes in the graph.
  ///
  /// Returns a list of orphan nodes (may be empty).
  ///
  /// Example:
  /// ```dart
  /// final orphans = controller.getOrphanNodes();
  /// print('Found ${orphans.length} orphan nodes');
  /// ```
  List<Node<T>> getOrphanNodes() {
    final connectedNodeIds = <String>{};
    for (final connection in _connections) {
      connectedNodeIds.add(connection.sourceNodeId);
      connectedNodeIds.add(connection.targetNodeId);
    }
    return _nodes.values
        .where((node) => !connectedNodeIds.contains(node.id))
        .toList();
  }

  /// Detects cycles in the graph using depth-first search.
  ///
  /// A cycle exists when you can follow connections from a node and eventually
  /// return to the same node.
  ///
  /// Returns a list of cycles, where each cycle is represented as a list of node IDs
  /// forming the cycle. Returns an empty list if no cycles are found.
  ///
  /// Example:
  /// ```dart
  /// final cycles = controller.detectCycles();
  /// if (cycles.isNotEmpty) {
  ///   print('Found ${cycles.length} cycles in the graph');
  ///   for (final cycle in cycles) {
  ///     print('Cycle: ${cycle.join(' -> ')}');
  ///   }
  /// }
  /// ```
  List<List<String>> detectCycles() {
    // Simple cycle detection implementation
    final cycles = <List<String>>[];
    final visited = <String>{};
    final recursionStack = <String>{};

    void dfs(String nodeId, List<String> path) {
      if (recursionStack.contains(nodeId)) {
        // Found a cycle
        final cycleStart = path.indexOf(nodeId);
        if (cycleStart >= 0) {
          cycles.add(path.sublist(cycleStart));
        }
        return;
      }

      if (visited.contains(nodeId)) return;

      visited.add(nodeId);
      recursionStack.add(nodeId);
      path.add(nodeId);

      // Follow outgoing connections
      final outgoingConnections = _connections.where(
        (c) => c.sourceNodeId == nodeId,
      );
      for (final conn in outgoingConnections) {
        dfs(conn.targetNodeId, List.from(path));
      }

      recursionStack.remove(nodeId);
      path.removeLast();
    }

    for (final node in _nodes.values) {
      if (!visited.contains(node.id)) {
        dfs(node.id, []);
      }
    }

    return cycles;
  }

  /// Tests if a point hits any connection.
  ///
  /// Uses the connection painter's hit-testing to determine if the given
  /// graph position intersects with any connection path.
  ///
  /// Parameters:
  /// - [graphPosition]: The position to test in graph/world coordinates
  ///
  /// Returns the connection ID if hit, `null` otherwise.
  ///
  /// Example:
  /// ```dart
  /// final hitConnectionId = controller.hitTestConnections(Offset(100, 100));
  /// if (hitConnectionId != null) {
  ///   print('Clicked on connection: $hitConnectionId');
  /// }
  /// ```
  String? hitTestConnections(Offset graphPosition) {
    // Use the controller's connection painter for hit-testing
    final painter = connectionPainter;

    // Check connections for hit-testing
    for (final connection in _connections) {
      final sourceNode = getNode(connection.sourceNodeId);
      final targetNode = getNode(connection.targetNodeId);

      if (sourceNode != null && targetNode != null) {
        if (painter.hitTestConnection(
          connection: connection,
          sourceNode: sourceNode,
          targetNode: targetNode,
          testPoint: graphPosition,
        )) {
          return connection.id;
        }
      }
    }
    return null;
  }

  /// Hit test for a port at the given graph position.
  ///
  /// Returns a record containing (nodeId, portId, isOutput) if a port is found
  /// at the position, otherwise returns null.
  ///
  /// This is useful for finding target ports during connection drag operations.
  ///
  /// Example:
  /// ```dart
  /// final result = controller.hitTestPort(graphPosition);
  /// if (result != null) {
  ///   print('Found port ${result.portId} on node ${result.nodeId}');
  /// }
  /// ```
  ({String nodeId, String portId, bool isOutput})? hitTestPort(
    Offset graphPosition,
  ) {
    final result = _spatialIndex.hitTestPort(graphPosition);
    if (result != null && result.portId != null) {
      return (
        nodeId: result.nodeId!,
        portId: result.portId!,
        isOutput: result.isOutput ?? false,
      );
    }
    return null;
  }

  // ============================================================================
  // Layout Operations
  // ============================================================================

  /// Arranges all nodes in a grid layout.
  ///
  /// Calculates an optimal grid size based on the square root of the number of nodes
  /// and positions them in rows and columns with the specified spacing.
  ///
  /// Parameters:
  /// - [spacing]: The distance between nodes in pixels (default: 150.0)
  ///
  /// Example:
  /// ```dart
  /// controller.arrangeNodesInGrid(spacing: 200.0);
  /// ```
  void arrangeNodesInGrid({double spacing = 150.0}) {
    final nodeList = _nodes.values.toList();
    final gridSize = math.sqrt(nodeList.length.toDouble()).ceil();

    runInAction(() {
      for (int i = 0; i < nodeList.length; i++) {
        final row = i ~/ gridSize;
        final col = i % gridSize;
        final newPosition = Offset(col * spacing, row * spacing);
        nodeList[i].position.value = newPosition;
        // Update visual position with snapping
        nodeList[i].setVisualPosition(_config.snapToGridIfEnabled(newPosition));
      }
    });

    // Rebuild spatial index for all nodes and connections after layout
    _spatialIndex.rebuildFromNodes(nodeList);
    rebuildAllConnectionSegments();
  }

  /// Arranges nodes hierarchically by type.
  ///
  /// Groups nodes by their type property and arranges each type group in rows,
  /// with 200 pixels horizontal spacing and 150 pixels vertical spacing between groups.
  ///
  /// Example:
  /// ```dart
  /// controller.arrangeNodesHierarchically();
  /// ```
  void arrangeNodesHierarchically() {
    // Simple implementation - arrange by type
    final nodesByType = <String, List<Node<T>>>{};
    for (final node in _nodes.values) {
      nodesByType.putIfAbsent(node.type, () => []).add(node);
    }

    runInAction(() {
      double y = 0;
      for (final entry in nodesByType.entries) {
        double x = 0;
        for (final node in entry.value) {
          final newPosition = Offset(x, y);
          node.position.value = newPosition;
          // Update visual position with snapping
          node.setVisualPosition(_config.snapToGridIfEnabled(newPosition));
          x += 200;
        }
        y += 150;
      }
    });

    // Rebuild spatial index for all nodes and connections after layout
    _spatialIndex.rebuildFromNodes(_nodes.values);
    rebuildAllConnectionSegments();
  }

  // ============================================================================
  // Batch Selection Operations
  // ============================================================================

  /// Clears all selections (nodes and connections) and exits any active
  /// editing mode.
  ///
  /// This is a convenience method that calls `clearNodeSelection` and
  /// `clearConnectionSelection`, and also clears any inline editing state
  /// on nodes like CommentNode.
  void clearSelection() {
    runInAction(() {
      // Clear any inline editing state on nodes
      for (final node in _nodes.values) {
        if (node.isEditing) {
          node.isEditing = false;
        }
      }

      // Only clear selections if something is selected
      if (_selectedNodeIds.isNotEmpty || _selectedConnectionIds.isNotEmpty) {
        clearNodeSelection();
        clearConnectionSelection();
      }
    });
  }

  /// Selects all selectable nodes in the graph.
  ///
  /// Only nodes with `selectable: true` are included. GroupNode and CommentNode
  /// have `selectable: false` by default and won't be selected.
  ///
  /// This is a convenience method for selecting everything. Use Cmd+A / Ctrl+A
  /// keyboard shortcut to trigger this.
  ///
  /// Example:
  /// ```dart
  /// controller.selectAllNodes();
  /// ```
  void selectAllNodes() {
    runInAction(() {
      _selectedNodeIds.clear();
      for (final node in _nodes.values) {
        if (node.selectable) {
          _selectedNodeIds.add(node.id);
          node.selected.value = true;
        }
      }
    });
  }

  /// Selects all connections in the graph.
  ///
  /// Example:
  /// ```dart
  /// controller.selectAllConnections();
  /// ```
  void selectAllConnections() {
    runInAction(() {
      _selectedConnectionIds.clear();
      _selectedConnectionIds.addAll(_connections.map((c) => c.id));
    });
  }

  /// Selects all nodes of a specific type.
  ///
  /// This clears the current selection and selects only nodes matching the given type.
  ///
  /// Parameters:
  /// - [type]: The node type to select (matches the `node.type` property)
  ///
  /// Example:
  /// ```dart
  /// controller.selectNodesByType('process');
  /// ```
  void selectNodesByType(String type) {
    runInAction(() {
      for (final node in _nodes.values) {
        node.selected.value = false;
      }
      _selectedNodeIds.clear();

      for (final node in _nodes.values) {
        if (node.type == type) {
          _selectedNodeIds.add(node.id);
          node.selected.value = true;
        }
      }
    });
  }

  /// Inverts the current node selection.
  ///
  /// All currently selected nodes become deselected, and all deselected nodes
  /// become selected.
  ///
  /// Example:
  /// ```dart
  /// controller.invertSelection();
  /// ```
  void invertSelection() {
    runInAction(() {
      final currentlySelected = Set.from(_selectedNodeIds);
      _selectedNodeIds.clear();

      for (final node in _nodes.values) {
        if (currentlySelected.contains(node.id)) {
          node.selected.value = false;
        } else {
          _selectedNodeIds.add(node.id);
          node.selected.value = true;
        }
      }
    });
  }

  /// Selects only the specified nodes, clearing any existing selection.
  ///
  /// This is similar to `selectNodes` but always clears the existing selection first.
  ///
  /// Parameters:
  /// - [nodeIds]: List of node IDs to select
  ///
  /// Example:
  /// ```dart
  /// controller.selectSpecificNodes(['node1', 'node2']);
  /// ```
  void selectSpecificNodes(List<String> nodeIds) {
    runInAction(() {
      // Clear current selection
      for (final node in _nodes.values) {
        node.selected.value = false;
      }
      _selectedNodeIds.clear();

      // Select specified nodes
      for (final nodeId in nodeIds) {
        final node = _nodes[nodeId];
        if (node != null) {
          _selectedNodeIds.add(nodeId);
          node.selected.value = true;
        }
      }
    });
  }

  // ============================================================================
  // Theme & Events Configuration
  // ============================================================================

  /// Set the theme and update the connection painter.
  ///
  /// This is called internally by the editor widget only.
  ///
  /// Parameters:
  /// - [theme]: The theme to apply to the graph editor
  void setTheme(NodeFlowTheme theme) {
    final isFirstTimeSetup = _connectionPainter == null;

    // Create painter if it doesn't exist, otherwise update its theme
    if (isFirstTimeSetup) {
      _connectionPainter = ConnectionPainter(
        theme: theme,
        // Cast to Node<dynamic> since ConnectionPainter is not generic
        nodeShape: _nodeShapeBuilder != null
            ? (node) => _nodeShapeBuilder!(node as Node<T>)
            : null,
      );
    } else {
      _connectionPainter!.updateTheme(theme);
    }

    // Update observable theme - this triggers the reaction for spatial index rebuild
    runInAction(() => _themeObservable.value = theme);

    // If this is the first time setup and we have pre-loaded nodes from
    // the constructor, set up the infrastructure now that we have a theme
    if (isFirstTimeSetup && _nodes.isNotEmpty) {
      _setupLoadedGraphInfrastructure();
    }
  }

  /// Update the events that the controller will use.
  ///
  /// This is called internally by the editor widget only.
  ///
  /// Parameters:
  /// - [events]: The event handlers for node, connection, and annotation events
  void setEvents(NodeFlowEvents<T> events) {
    _events = events;
  }

  // ============================================================================
  // Keyboard Shortcuts
  // ============================================================================

  /// Shows the keyboard shortcuts dialog.
  ///
  /// Displays a comprehensive dialog showing all available keyboard shortcuts
  /// organized by category for easy reference.
  ///
  /// Parameters:
  /// - [context]: The BuildContext for showing the dialog
  ///
  /// Example:
  /// ```dart
  /// controller.showShortcutsDialog(context);
  /// ```
  void showShortcutsDialog(BuildContext context) {
    // Import will be added at the top when used
    showDialog(
      context: context,
      builder: (context) => ShortcutsViewerDialog(
        shortcuts: shortcuts.keyMap,
        actions: shortcuts.actions,
      ),
    );
  }

  // ============================================================================
  // Computed Properties
  // ============================================================================

  /// Gets the bounding rectangle that encompasses all nodes in the graph.
  ///
  /// Calculates the minimal rectangle that contains all nodes based on their
  /// positions and sizes.
  ///
  /// Returns `Rect.zero` if there are no nodes.
  ///
  /// Example:
  /// ```dart
  /// final bounds = controller.nodesBounds;
  /// print('Graph size: ${bounds.width} x ${bounds.height}');
  /// ```
  Rect get nodesBounds {
    if (_nodes.isEmpty) return Rect.zero;

    double minX = double.infinity;
    double minY = double.infinity;
    double maxX = double.negativeInfinity;
    double maxY = double.negativeInfinity;

    for (final node in _nodes.values) {
      final pos = node.position.value;
      final size = node.size.value;
      minX = math.min(minX, pos.dx);
      minY = math.min(minY, pos.dy);
      maxX = math.max(maxX, pos.dx + size.width);
      maxY = math.max(maxY, pos.dy + size.height);
    }

    return Rect.fromLTRB(minX, minY, maxX, maxY);
  }
}
