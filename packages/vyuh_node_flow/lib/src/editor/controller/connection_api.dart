part of 'node_flow_controller.dart';

/// Connection-related operations for [NodeFlowController].
///
/// This extension provides comprehensive APIs for working with connections:
///
/// ## Model APIs
/// - [getConnection], [connectionIds], [connectionCount] - Lookup operations
/// - [addConnection], [removeConnection], [createConnection] - CRUD operations
///
/// ## Query APIs
/// - [getConnectionsForNode] - Get all connections for a node
/// - [getConnectionsFromPort], [getConnectionsToPort] - Port-specific queries
/// - [getVisibleConnections], [getHiddenConnections] - Visibility queries
///
/// ## Visual Query APIs
/// - [getConnectionBounds] - Bounding box for a connection
/// - [getConnectionPath] - The rendered path for a connection
///
/// ## Control Point APIs
/// - [addControlPoint], [updateControlPoint], [removeControlPoint] - CRUD
/// - [clearControlPoints] - Remove all control points
///
/// ## Selection APIs
/// - [selectConnection], [clearConnectionSelection] - Selection management
/// - [selectAllConnections] - Bulk selection
///
/// ## Validation APIs
/// - [hasCycles], [getCycles] - Cycle detection
extension ConnectionApi<T, C> on NodeFlowController<T, C> {
  // ============================================================================
  // Model APIs - Lookup
  // ============================================================================

  /// Gets a connection by its ID.
  ///
  /// Returns `null` if the connection doesn't exist.
  ///
  /// Example:
  /// ```dart
  /// final connection = controller.getConnection('conn1');
  /// if (connection != null) {
  ///   print('Source: ${connection.sourceNodeId}');
  /// }
  /// ```
  Connection<C>? getConnection(String connectionId) {
    try {
      return _connections.firstWhere((c) => c.id == connectionId);
    } catch (_) {
      return null;
    }
  }

  /// Gets all connection IDs in the graph.
  Iterable<String> get connectionIds => _connections.map((c) => c.id);

  /// Gets the total number of connections in the graph.
  int get connectionCount => _connections.length;

  /// Gets all connections associated with a node.
  ///
  /// Returns connections where the node is either the source or target.
  ///
  /// Example:
  /// ```dart
  /// final connections = controller.getConnectionsForNode('node1');
  /// print('Node has ${connections.length} connections');
  /// ```
  List<Connection<C>> getConnectionsForNode(String nodeId) {
    return _connections
        .where(
          (conn) => conn.sourceNodeId == nodeId || conn.targetNodeId == nodeId,
        )
        .toList();
  }

  /// Gets all connections originating from a specific port.
  ///
  /// Returns connections where the specified port is the source.
  ///
  /// Example:
  /// ```dart
  /// final outgoing = controller.getConnectionsFromPort('node1', 'output1');
  /// ```
  List<Connection<C>> getConnectionsFromPort(String nodeId, String portId) {
    return _connections
        .where(
          (conn) => conn.sourceNodeId == nodeId && conn.sourcePortId == portId,
        )
        .toList();
  }

  /// Gets all connections targeting a specific port.
  ///
  /// Returns connections where the specified port is the target.
  ///
  /// Example:
  /// ```dart
  /// final incoming = controller.getConnectionsToPort('node2', 'input1');
  /// ```
  List<Connection<C>> getConnectionsToPort(String nodeId, String portId) {
    return _connections
        .where(
          (conn) => conn.targetNodeId == nodeId && conn.targetPortId == portId,
        )
        .toList();
  }

  // ============================================================================
  // Model APIs - CRUD
  // ============================================================================

  /// Adds a connection between two ports.
  ///
  /// Triggers the `onConnectionCreated` callback after successful addition.
  ///
  /// Example:
  /// ```dart
  /// final connection = Connection(
  ///   id: 'conn1',
  ///   sourceNodeId: 'node1',
  ///   sourcePortId: 'out1',
  ///   targetNodeId: 'node2',
  ///   targetPortId: 'in1',
  /// );
  /// controller.addConnection(connection);
  /// ```
  void addConnection(Connection<C> connection) {
    runInAction(() {
      _connections.add(connection);
      // Update connection index for O(1) lookup
      _connectionsByNodeId
          .putIfAbsent(connection.sourceNodeId, () => {})
          .add(connection.id);
      _connectionsByNodeId
          .putIfAbsent(connection.targetNodeId, () => {})
          .add(connection.id);
    });
    // Fire event after successful addition
    events.connection?.onCreated?.call(connection);
    // Emit extension event
    _emitEvent(ConnectionAdded(connection));
  }

  /// Requests deletion of a connection with lock check and confirmation callback.
  ///
  /// This async method:
  /// 1. Checks if deletion is allowed by current behavior
  /// 2. Checks if the connection is locked (returns false if locked)
  /// 3. Calls [onBeforeConnectionDelete] callback if provided (returns false if vetoed)
  /// 4. Removes the connection if all checks pass
  ///
  /// Use this method when you want to respect locks and confirmation dialogs.
  /// For direct removal without checks, use [removeConnection] instead.
  ///
  /// Returns `true` if the connection was deleted, `false` if deletion was prevented.
  ///
  /// Example:
  /// ```dart
  /// final deleted = await controller.requestDeleteConnection('conn1');
  /// if (!deleted) {
  ///   print('Connection deletion was prevented');
  /// }
  /// ```
  Future<bool> requestDeleteConnection(String connectionId) async {
    // Check behavior first
    if (!behavior.canDelete) return false;

    final connection = getConnection(connectionId);
    if (connection == null) return false;

    // Check if connection is locked
    if (connection.locked) return false;

    // Call before-delete callback if provided
    final callback = events.connection?.onBeforeDelete;
    if (callback != null) {
      final allowed = await callback(connection);
      if (!allowed) return false;
    }

    // Proceed with deletion
    removeConnection(connectionId);
    return true;
  }

  /// Removes a connection from the graph.
  ///
  /// This is a direct removal method that does NOT check:
  /// - Lock status
  /// - Before-delete callbacks
  ///
  /// For deletion with lock and callback checks, use [requestDeleteConnection].
  ///
  /// Also removes the connection from the selection set if it was selected.
  ///
  /// Triggers the `onConnectionDeleted` callback after successful removal.
  ///
  /// Throws [ArgumentError] if the connection doesn't exist.
  void removeConnection(String connectionId) {
    final connectionToDelete = _connections.firstWhere(
      (c) => c.id == connectionId,
      orElse: () => throw ArgumentError('Connection $connectionId not found'),
    );
    runInAction(() {
      _connections.removeWhere((c) => c.id == connectionId);
      _selectedConnectionIds.remove(connectionId);

      // Update connection index for O(1) lookup
      _connectionsByNodeId[connectionToDelete.sourceNodeId]?.remove(
        connectionId,
      );
      _connectionsByNodeId[connectionToDelete.targetNodeId]?.remove(
        connectionId,
      );

      // Remove from spatial index
      _spatialIndex.removeConnection(connectionId);
    });

    // Remove cached path to prevent stale rendering
    _connectionPainter?.removeConnectionFromCache(connectionId);

    // Fire event after successful removal
    events.connection?.onDeleted?.call(connectionToDelete);
    // Emit extension event
    _emitEvent(ConnectionRemoved(connectionToDelete));
  }

  /// Creates a connection between two ports.
  ///
  /// This is a convenience method that creates a Connection object with an
  /// auto-generated ID and adds it to the graph.
  ///
  /// Example:
  /// ```dart
  /// controller.createConnection(
  ///   'node1',
  ///   'output1',
  ///   'node2',
  ///   'input1',
  /// );
  /// ```
  void createConnection(
    String sourceNodeId,
    String sourcePortId,
    String targetNodeId,
    String targetPortId,
  ) {
    final connection = Connection<C>(
      id: 'conn_${DateTime.now().millisecondsSinceEpoch}',
      sourceNodeId: sourceNodeId,
      sourcePortId: sourcePortId,
      targetNodeId: targetNodeId,
      targetPortId: targetPortId,
    );
    addConnection(connection);
  }

  /// Deletes all connections associated with a node.
  ///
  /// Removes all connections where the node is either the source or target.
  /// The node itself is not deleted.
  ///
  /// Example:
  /// ```dart
  /// controller.deleteAllConnectionsForNode('node1');
  /// ```
  void deleteAllConnectionsForNode(String nodeId) {
    final connectionsToRemove = _connections
        .where(
          (conn) => conn.sourceNodeId == nodeId || conn.targetNodeId == nodeId,
        )
        .toList();

    runInAction(() {
      for (final conn in connectionsToRemove) {
        // Remove from spatial index and path cache
        _spatialIndex.removeConnection(conn.id);
        _connectionPainter?.removeConnectionFromCache(conn.id);

        // Update connection index for O(1) lookup
        _connectionsByNodeId[conn.sourceNodeId]?.remove(conn.id);
        _connectionsByNodeId[conn.targetNodeId]?.remove(conn.id);

        // Remove from connections list
        _connections.remove(conn);
      }
    });
  }

  // ============================================================================
  // Visual Query APIs
  // ============================================================================

  /// Gets the bounding rectangle for a connection.
  ///
  /// Returns `null` if the connection doesn't exist or its nodes are missing.
  ///
  /// Example:
  /// ```dart
  /// final bounds = controller.getConnectionBounds('conn1');
  /// if (bounds != null) {
  ///   print('Connection bounds: $bounds');
  /// }
  /// ```
  Rect? getConnectionBounds(String connectionId) {
    final connection = getConnection(connectionId);
    if (connection == null) return null;

    return _calculateConnectionBounds(connection);
  }

  /// Gets the rendered path for a connection.
  ///
  /// Returns `null` if the connection doesn't exist or the painter is not initialized.
  /// The path is in world coordinates.
  ///
  /// Example:
  /// ```dart
  /// final path = controller.getConnectionPath('conn1');
  /// if (path != null) {
  ///   // Use path for custom rendering or hit testing
  /// }
  /// ```
  Path? getConnectionPath(String connectionId) {
    if (!isConnectionPainterInitialized || _theme == null) return null;

    final connection = getConnection(connectionId);
    if (connection == null) return null;

    final sourceNode = _nodes[connection.sourceNodeId];
    final targetNode = _nodes[connection.targetNodeId];
    if (sourceNode == null || targetNode == null) return null;

    return _connectionPainter!.pathCache.getOrCreatePath(
      connection: connection,
      sourceNode: sourceNode,
      targetNode: targetNode,
      connectionStyle: _theme!.connectionTheme.style,
    );
  }

  /// Gets all visible connections in the graph.
  ///
  /// A connection is visible when both its source and target nodes are visible.
  List<Connection<C>> getVisibleConnections() {
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
  List<Connection<C>> getHiddenConnections() {
    return _connections.where((connection) {
      final sourceNode = _nodes[connection.sourceNodeId];
      final targetNode = _nodes[connection.targetNodeId];
      return sourceNode == null ||
          targetNode == null ||
          !sourceNode.isVisible ||
          !targetNode.isVisible;
    }).toList();
  }

  /// Calculates the bounding box for a connection based on its source and target nodes.
  Rect? _calculateConnectionBounds(Connection<C> connection) {
    final sourceNode = _nodes[connection.sourceNodeId];
    final targetNode = _nodes[connection.targetNodeId];
    if (sourceNode == null || targetNode == null) return null;

    final sourcePos = sourceNode.position.value;
    final sourceSize = sourceNode.size.value;
    final targetPos = targetNode.position.value;
    final targetSize = targetNode.size.value;

    final sourceCenter =
        sourcePos + Offset(sourceSize.width / 2, sourceSize.height / 2);
    final targetCenter =
        targetPos + Offset(targetSize.width / 2, targetSize.height / 2);

    // Create bounding box with padding for bezier curves
    const padding = 50.0;
    final minX =
        (sourceCenter.dx < targetCenter.dx
            ? sourceCenter.dx
            : targetCenter.dx) -
        padding;
    final maxX =
        (sourceCenter.dx > targetCenter.dx
            ? sourceCenter.dx
            : targetCenter.dx) +
        padding;
    final minY =
        (sourceCenter.dy < targetCenter.dy
            ? sourceCenter.dy
            : targetCenter.dy) -
        padding;
    final maxY =
        (sourceCenter.dy > targetCenter.dy
            ? sourceCenter.dy
            : targetCenter.dy) +
        padding;

    return Rect.fromLTRB(minX, minY, maxX, maxY);
  }

  // ============================================================================
  // Selection APIs
  // ============================================================================

  /// Selects a connection in the graph.
  ///
  /// Automatically clears node selections.
  /// Requests canvas focus if not already focused.
  ///
  /// Triggers the `onConnectionSelected` callback after selection changes.
  ///
  /// Parameters:
  /// - [connectionId]: The ID of the connection to select
  /// - [toggle]: If `true`, toggles the connection's selection state. If `false`
  ///   (default), clears other connection selections and selects only this connection.
  void selectConnection(String connectionId, {bool toggle = false}) {
    runInAction(() {
      // Clear other element types' selections
      clearNodeSelection();

      // Find the connection - if it doesn't exist, we can't select it
      final connection = _connections.firstWhere((c) => c.id == connectionId);

      if (toggle) {
        if (_selectedConnectionIds.contains(connectionId)) {
          _selectedConnectionIds.remove(connectionId);
          connection.selected = false;
        } else {
          _selectedConnectionIds.add(connectionId);
          connection.selected = true;
        }
      } else {
        // Clear previous connection selection
        clearConnectionSelection();

        // Select new connection
        _selectedConnectionIds.add(connectionId);
        connection.selected = true;
      }
    });

    // Fire selection callback with current selection state
    final selectedConnection = _selectedConnectionIds.contains(connectionId)
        ? _connections.firstWhere((c) => c.id == connectionId)
        : null;
    events.connection?.onSelected?.call(selectedConnection);

    if (!canvasFocusNode.hasFocus) {
      canvasFocusNode.requestFocus();
    }
  }

  /// Clears all connection selections.
  ///
  /// Triggers the `onConnectionSelected` callback with `null` to indicate no selection.
  void clearConnectionSelection() {
    if (_selectedConnectionIds.isEmpty) return;

    for (final id in _selectedConnectionIds) {
      for (final connection in _connections) {
        if (connection.id == id) {
          connection.selected = false;
          break;
        }
      }
    }
    _selectedConnectionIds.clear();

    events.connection?.onSelected?.call(null);
  }

  /// Checks if a connection is currently selected.
  bool isConnectionSelected(String connectionId) =>
      _selectedConnectionIds.contains(connectionId);

  /// Selects all connections in the graph.
  void selectAllConnections() {
    runInAction(() {
      _selectedConnectionIds.clear();
      _selectedConnectionIds.addAll(_connections.map((c) => c.id));
      for (final connection in _connections) {
        connection.selected = true;
      }
    });
  }

  // ============================================================================
  // Validation APIs
  // ============================================================================

  /// Checks if the graph contains any cycles.
  ///
  /// Uses depth-first search to detect back edges which indicate cycles.
  ///
  /// Returns `true` if one or more cycles exist in the graph.
  bool hasCycles() {
    return getCycles().isNotEmpty;
  }

  /// Gets all cycles in the graph.
  ///
  /// Returns a list of cycles, where each cycle is represented as a list
  /// of node IDs forming the cycle path.
  ///
  /// Example:
  /// ```dart
  /// final cycles = controller.getCycles();
  /// for (final cycle in cycles) {
  ///   print('Cycle: ${cycle.join(' -> ')}');
  /// }
  /// ```
  List<List<String>> getCycles() {
    final visited = <String>{};
    final recursionStack = <String>{};
    final cycles = <List<String>>[];

    // Build adjacency list
    final adjacencyList = <String, List<String>>{};
    for (final connection in _connections) {
      adjacencyList
          .putIfAbsent(connection.sourceNodeId, () => [])
          .add(connection.targetNodeId);
    }

    void dfs(String nodeId, List<String> path) {
      visited.add(nodeId);
      recursionStack.add(nodeId);
      path.add(nodeId);

      final neighbors = adjacencyList[nodeId] ?? [];
      for (final neighbor in neighbors) {
        if (!visited.contains(neighbor)) {
          dfs(neighbor, List.from(path));
        } else if (recursionStack.contains(neighbor)) {
          // Found a cycle - extract the cycle path
          final cycleStartIndex = path.indexOf(neighbor);
          if (cycleStartIndex != -1) {
            final cyclePath = path.sublist(cycleStartIndex);
            cyclePath.add(neighbor); // Complete the cycle
            cycles.add(cyclePath);
          }
        }
      }

      recursionStack.remove(nodeId);
    }

    // Run DFS from each unvisited node
    for (final nodeId in _nodes.keys) {
      if (!visited.contains(nodeId)) {
        dfs(nodeId, []);
      }
    }

    return cycles;
  }

  // ============================================================================
  // Widget-Level Connection Drag API
  // ============================================================================
  //
  // These methods are designed to be called directly by widgets (PortWidget)
  // to handle connection drag operations. This eliminates callback chains
  // and gives widgets direct controller access.

  /// Validates whether a connection can start from the specified port.
  ///
  /// This method checks:
  /// 1. Port exists and is connectable
  /// 2. Direction compatibility (output can emit, input can receive)
  /// 3. Max connections not exceeded (for source ports)
  /// 4. Custom validation via [ConnectionEvents.onBeforeStart] callback
  ///
  /// Returns a [ConnectionValidationResult] indicating if the connection can start.
  ConnectionValidationResult canStartConnection({
    required String nodeId,
    required String portId,
    required bool isOutput,
  }) {
    final node = _nodes[nodeId];
    if (node == null) {
      return const ConnectionValidationResult.deny(reason: 'Node not found');
    }

    final port = node.allPorts.where((p) => p.id == portId).firstOrNull;
    if (port == null) {
      return const ConnectionValidationResult.deny(reason: 'Port not found');
    }

    // Port must be connectable
    if (!port.isConnectable) {
      return const ConnectionValidationResult.deny(
        reason: 'Port is not connectable',
      );
    }

    // Direction check: output ports must be able to emit
    // input ports must be able to receive
    if (isOutput && !port.isOutput) {
      return const ConnectionValidationResult.deny(
        reason: 'Port cannot emit connections',
      );
    }
    if (!isOutput && !port.isInput) {
      return const ConnectionValidationResult.deny(
        reason: 'Port cannot receive connections',
      );
    }

    // Get existing connections for this port
    final existingConnections = _connections
        .where(
          (conn) => isOutput
              ? (conn.sourceNodeId == nodeId && conn.sourcePortId == portId)
              : (conn.targetNodeId == nodeId && conn.targetPortId == portId),
        )
        .map((c) => c.id)
        .toList();

    // Check max connections for source port (output side)
    if (isOutput && port.maxConnections != null) {
      if (port.multiConnections &&
          existingConnections.length >= port.maxConnections!) {
        return const ConnectionValidationResult.deny(
          reason: 'Maximum connections reached',
        );
      }
    }

    // Call custom validation callback if provided
    final onBeforeStart = events.connection?.onBeforeStart;
    if (onBeforeStart != null) {
      final context = ConnectionStartContext<T>(
        sourceNode: node,
        sourcePort: port,
        existingConnections: existingConnections,
      );
      final result = onBeforeStart(context);
      if (!result.allowed) {
        return result;
      }
    }

    return const ConnectionValidationResult.allow();
  }

  /// Starts a connection drag from a port.
  ///
  /// Call this from PortWidget's GestureDetector.onPanStart.
  ///
  /// Parameters:
  /// - [nodeId]: The ID of the node containing the port
  /// - [portId]: The ID of the port being dragged from
  /// - [isOutput]: Whether this is an output port
  /// - [startPoint]: The starting point in graph coordinates
  /// - [nodeBounds]: The bounds of the source node in graph coordinates
  /// - [initialScreenPosition]: Optional initial screen position for smooth start
  ///
  /// Returns the validation result. Check [ConnectionValidationResult.allowed]
  /// to determine if the drag started successfully.
  ConnectionValidationResult startConnectionDrag({
    required String nodeId,
    required String portId,
    required bool isOutput,
    required Offset startPoint,
    required Rect nodeBounds,
    Offset? initialScreenPosition,
  }) {
    // Check if connection creation is allowed by current behavior
    if (!behavior.canCreate) {
      return const ConnectionValidationResult.deny(
        reason: 'Connection creation is disabled in current behavior mode',
      );
    }

    // Validate source port before starting
    final validationResult = canStartConnection(
      nodeId: nodeId,
      portId: portId,
      isOutput: isOutput,
    );
    if (!validationResult.allowed) {
      return validationResult;
    }

    // Get node and port for callbacks
    final node = getNode(nodeId);
    final port = node?.allPorts.where((p) => p.id == portId).firstOrNull;

    // Fire connection start event
    if (node != null && port != null) {
      events.connection?.onConnectStart?.call(node, port);
    }

    // Check if we need to remove existing connections
    // (for ports that don't allow multiple connections)
    if (node != null && port != null) {
      if (!port.multiConnections) {
        // Remove existing connections from this port
        final connectionsToRemove = _connections
            .where(
              (conn) => isOutput
                  ? (conn.sourceNodeId == nodeId && conn.sourcePortId == portId)
                  : (conn.targetNodeId == nodeId &&
                        conn.targetPortId == portId),
            )
            .toList();
        runInAction(() {
          for (final connection in connectionsToRemove) {
            removeConnection(connection.id);
          }
        });
      }
    }

    // Create temporary connection
    final initialCurrentPoint = initialScreenPosition != null
        ? globalToGraph(ScreenPosition(initialScreenPosition)).offset
        : startPoint;

    runInAction(() {
      // Note: Canvas locking is now handled by DragSession

      interaction.temporaryConnection.value = TemporaryConnection(
        startNodeId: nodeId,
        startPortId: portId,
        isStartFromOutput: isOutput,
        startPoint: startPoint,
        initialCurrentPoint: initialCurrentPoint,
        startNodeBounds: nodeBounds,
      );
    });

    return validationResult;
  }

  /// Validates whether a connection can be made from the current drag state
  /// to the specified target port.
  ///
  /// This method checks:
  /// 1. Not connecting a port to itself
  /// 2. Direction compatibility (output→input or input←output)
  /// 3. Port is connectable
  /// 4. No duplicate connections
  /// 5. Max connections limit not exceeded
  /// 6. Custom validation via [ConnectionEvents.onBeforeComplete] callback
  ///
  /// Returns a [ConnectionValidationResult] indicating if the connection is valid.
  ConnectionValidationResult canConnect({
    required String targetNodeId,
    required String targetPortId,
    bool skipCustomValidation = false,
  }) {
    final temp = interaction.temporaryConnection.value;
    if (temp == null) {
      return const ConnectionValidationResult.deny(
        reason: 'No active connection drag',
      );
    }

    // Cannot connect a port to itself
    if (temp.startNodeId == targetNodeId && temp.startPortId == targetPortId) {
      return const ConnectionValidationResult.deny(
        reason: 'Cannot connect a port to itself',
      );
    }

    // Get target node
    final targetNode = _nodes[targetNodeId];
    if (targetNode == null) {
      return const ConnectionValidationResult.deny(
        reason: 'Target node not found',
      );
    }

    // Cannot connect same direction ports
    final targetIsOutput = targetNode.outputPorts.any(
      (p) => p.id == targetPortId,
    );
    if (temp.isStartFromOutput == targetIsOutput) {
      return ConnectionValidationResult.deny(
        reason: targetIsOutput
            ? 'Cannot connect output to output'
            : 'Cannot connect input to input',
      );
    }

    // Get source node and port
    final sourceNode = _nodes[temp.startNodeId];
    if (sourceNode == null) {
      return const ConnectionValidationResult.deny(
        reason: 'Source node not found',
      );
    }
    final sourcePort = sourceNode.allPorts
        .where((p) => p.id == temp.startPortId)
        .firstOrNull;
    if (sourcePort == null) {
      return const ConnectionValidationResult.deny(
        reason: 'Source port not found',
      );
    }

    // Get target port
    final targetPort = targetNode.allPorts
        .where((p) => p.id == targetPortId)
        .firstOrNull;
    if (targetPort == null) {
      return const ConnectionValidationResult.deny(
        reason: 'Target port not found',
      );
    }

    // Both ports must be connectable
    if (!sourcePort.isConnectable) {
      return const ConnectionValidationResult.deny(
        reason: 'Source port is not connectable',
      );
    }
    if (!targetPort.isConnectable) {
      return const ConnectionValidationResult.deny(
        reason: 'Target port is not connectable',
      );
    }

    // Direction compatibility
    if (temp.isStartFromOutput) {
      if (!targetPort.isInput) {
        return const ConnectionValidationResult.deny(
          reason: 'Target port cannot receive connections',
        );
      }
    } else {
      if (!targetPort.isOutput) {
        return const ConnectionValidationResult.deny(
          reason: 'Target port cannot emit connections',
        );
      }
    }

    // Determine actual source/target
    final Node<T> actualSourceNode;
    final Port actualSourcePort;
    final Node<T> actualTargetNode;
    final Port actualTargetPort;

    if (temp.isStartFromOutput) {
      actualSourceNode = sourceNode;
      actualSourcePort = sourcePort;
      actualTargetNode = targetNode;
      actualTargetPort = targetPort;
    } else {
      actualSourceNode = targetNode;
      actualSourcePort = targetPort;
      actualTargetNode = sourceNode;
      actualTargetPort = sourcePort;
    }

    // Get existing connections for both ports
    final existingSourceConnections = _connections
        .where(
          (conn) =>
              conn.sourceNodeId == actualSourceNode.id &&
              conn.sourcePortId == actualSourcePort.id,
        )
        .map((c) => c.id)
        .toList();
    final existingTargetConnections = _connections
        .where(
          (conn) =>
              conn.targetNodeId == actualTargetNode.id &&
              conn.targetPortId == actualTargetPort.id,
        )
        .map((c) => c.id)
        .toList();

    // No duplicate connections
    final duplicateExists = _connections.any(
      (conn) =>
          conn.sourceNodeId == actualSourceNode.id &&
          conn.sourcePortId == actualSourcePort.id &&
          conn.targetNodeId == actualTargetNode.id &&
          conn.targetPortId == actualTargetPort.id,
    );
    if (duplicateExists) {
      return const ConnectionValidationResult.deny(
        reason: 'Connection already exists',
      );
    }

    // Max connections limit
    if (actualTargetPort.maxConnections != null) {
      if (existingTargetConnections.length >=
          actualTargetPort.maxConnections!) {
        return const ConnectionValidationResult.deny(
          reason: 'Target port has maximum connections',
        );
      }
    }

    // Custom validation callback
    if (!skipCustomValidation) {
      final onBeforeComplete = events.connection?.onBeforeComplete;
      if (onBeforeComplete != null) {
        final context = ConnectionCompleteContext<T>(
          sourceNode: actualSourceNode,
          sourcePort: actualSourcePort,
          targetNode: actualTargetNode,
          targetPort: actualTargetPort,
          existingSourceConnections: existingSourceConnections,
          existingTargetConnections: existingTargetConnections,
        );
        final result = onBeforeComplete(context);
        if (!result.allowed) {
          return result;
        }
      }
    }

    return const ConnectionValidationResult.allow();
  }

  /// Updates a connection drag with the current position.
  ///
  /// Call this from PortWidget's GestureDetector.onPanUpdate.
  ///
  /// Parameters:
  /// - [graphPosition]: Current pointer position in graph coordinates
  /// - [targetNodeId]: ID of node being hovered (null if none)
  /// - [targetPortId]: ID of port being hovered (null if none)
  /// - [targetNodeBounds]: Bounds of hovered node (null if none)
  void updateConnectionDrag({
    required Offset graphPosition,
    String? targetNodeId,
    String? targetPortId,
    Rect? targetNodeBounds,
  }) {
    final temp = interaction.temporaryConnection.value;
    if (temp == null) return;

    // Validate target port before highlighting
    final isValidTarget =
        targetNodeId != null &&
        targetPortId != null &&
        canConnect(
          targetNodeId: targetNodeId,
          targetPortId: targetPortId,
          skipCustomValidation: true,
        ).allowed;

    final validTargetNodeId = isValidTarget ? targetNodeId : null;
    final validTargetPortId = isValidTarget ? targetPortId : null;
    final validTargetBounds = isValidTarget ? targetNodeBounds : null;

    runInAction(() {
      // Handle port highlighting when target port changes
      final prevNodeId = temp.targetNodeId;
      final prevPortId = temp.targetPortId;
      final targetChanged =
          prevNodeId != validTargetNodeId || prevPortId != validTargetPortId;

      if (targetChanged) {
        // Reset previous port's highlighted state
        if (prevNodeId != null && prevPortId != null) {
          final prevNode = _nodes[prevNodeId];
          if (prevNode != null) {
            final prevPort = prevNode.allPorts
                .where((p) => p.id == prevPortId)
                .firstOrNull;
            prevPort?.highlighted.value = false;
          }
        }

        // Set new port's highlighted state
        if (validTargetNodeId != null && validTargetPortId != null) {
          final newNode = _nodes[validTargetNodeId];
          if (newNode != null) {
            final newPort = newNode.allPorts
                .where((p) => p.id == validTargetPortId)
                .firstOrNull;
            newPort?.highlighted.value = true;
          }
        }
      }

      // Update connection endpoint
      if (validTargetNodeId != null && validTargetPortId != null) {
        // Snap to the target port's connection point
        final targetNode = _nodes[validTargetNodeId];
        if (targetNode != null) {
          final targetPort = targetNode.allPorts
              .where((p) => p.id == validTargetPortId)
              .firstOrNull;
          if (targetPort != null && _theme != null) {
            final effectivePortSize = _theme!.portTheme.resolveSize(targetPort);
            final snapPoint = targetNode.getConnectionPoint(
              validTargetPortId,
              portSize: effectivePortSize,
              shape: nodeShapeBuilder?.call(targetNode),
            );
            temp.currentPoint = snapPoint;
          } else {
            temp.currentPoint = graphPosition;
          }
        } else {
          temp.currentPoint = graphPosition;
        }
      } else {
        temp.currentPoint = graphPosition;
      }

      if (temp.targetNodeId != validTargetNodeId) {
        temp.targetNodeId = validTargetNodeId;
      }
      if (temp.targetPortId != validTargetPortId) {
        temp.targetPortId = validTargetPortId;
      }
      if (temp.targetNodeBounds != validTargetBounds) {
        temp.targetNodeBounds = validTargetBounds;
      }
    });
  }

  /// Completes a connection drag by creating the connection.
  ///
  /// Call this from PortWidget's GestureDetector.onPanEnd when over a valid target.
  ///
  /// Parameters:
  /// - [targetNodeId]: The ID of the target node
  /// - [targetPortId]: The ID of the target port
  ///
  /// Returns the created connection, or null if creation failed.
  Connection<C>? completeConnectionDrag({
    required String targetNodeId,
    required String targetPortId,
  }) {
    final temp = interaction.temporaryConnection.value;

    final eventPosition = interaction.pointerPosition == null
        ? GraphPosition.zero
        : viewport.toGraph(interaction.pointerPosition!);

    if (temp == null) {
      events.connection?.onConnectEnd?.call(null, null, eventPosition);
      return null;
    }

    // Validate connection before creating
    final validationResult = canConnect(
      targetNodeId: targetNodeId,
      targetPortId: targetPortId,
    );
    if (!validationResult.allowed) {
      cancelConnectionDrag();
      return null;
    }

    // Reset highlighted port
    final highlightedNode = _nodes[targetNodeId];
    if (highlightedNode != null) {
      final highlightedPort = highlightedNode.allPorts
          .where((p) => p.id == targetPortId)
          .firstOrNull;
      if (highlightedPort != null) {
        runInAction(() => highlightedPort.highlighted.value = false);
      }
    }

    // Determine actual source/target based on port direction
    final String sourceNodeId;
    final String sourcePortId;
    final String actualTargetNodeId;
    final String actualTargetPortId;

    if (temp.isStartFromOutput) {
      sourceNodeId = temp.startNodeId;
      sourcePortId = temp.startPortId;
      actualTargetNodeId = targetNodeId;
      actualTargetPortId = targetPortId;
    } else {
      sourceNodeId = targetNodeId;
      sourcePortId = targetPortId;
      actualTargetNodeId = temp.startNodeId;
      actualTargetPortId = temp.startPortId;
    }

    // Check if source (output) port allows multiple connections
    // If not, remove existing connections from the source port (replacement behavior)
    final sourceNode = _nodes[sourceNodeId];
    if (sourceNode != null) {
      final sourcePort = sourceNode.allPorts
          .where((p) => p.id == sourcePortId)
          .firstOrNull;
      if (sourcePort != null && !sourcePort.multiConnections) {
        final connectionsToRemove = _connections
            .where(
              (conn) =>
                  conn.sourceNodeId == sourceNodeId &&
                  conn.sourcePortId == sourcePortId,
            )
            .toList();
        runInAction(() {
          for (final connection in connectionsToRemove) {
            removeConnection(connection.id);
          }
        });
      }
    }

    // Check if target (input) port allows multiple connections
    // If not, remove existing connections to the target port (replacement behavior)
    final targetNode = _nodes[actualTargetNodeId];
    if (targetNode != null) {
      final targetPort = targetNode.allPorts
          .where((p) => p.id == actualTargetPortId)
          .firstOrNull;
      if (targetPort != null && !targetPort.multiConnections) {
        final connectionsToRemove = _connections
            .where(
              (conn) =>
                  conn.targetNodeId == actualTargetNodeId &&
                  conn.targetPortId == actualTargetPortId,
            )
            .toList();
        runInAction(() {
          for (final connection in connectionsToRemove) {
            removeConnection(connection.id);
          }
        });
      }
    }

    // Create the new connection
    final createdConnection = runInAction(() {
      final connection = Connection<C>(
        id: '${sourceNodeId}_${sourcePortId}_${actualTargetNodeId}_$actualTargetPortId',
        sourceNodeId: sourceNodeId,
        sourcePortId: sourcePortId,
        targetNodeId: actualTargetNodeId,
        targetPortId: actualTargetPortId,
      );
      addConnection(connection);

      // Clear temporary connection state
      // Note: Canvas unlocking is now handled by DragSession
      interaction.temporaryConnection.value = null;

      return connection;
    });

    // Fire connection end event with the target node and port that the user dropped on
    final droppedOnNode = _nodes[targetNodeId];

    final droppedOnPort = droppedOnNode?.allPorts
        .where((p) => p.id == targetPortId)
        .firstOrNull;

    events.connection?.onConnectEnd?.call(
      droppedOnNode,
      droppedOnPort,
      eventPosition,
    );

    return createdConnection;
  }

  /// Cancels a connection drag without creating a connection.
  ///
  /// Call this from PortWidget's GestureDetector.onPanEnd when not over a valid target,
  /// or from onPanCancel when the gesture is interrupted.
  void cancelConnectionDrag() {
    // Reset highlighted port before canceling
    final temp = interaction.temporaryConnection.value;

    if (temp != null &&
        temp.targetNodeId != null &&
        temp.targetPortId != null) {
      final targetNode = _nodes[temp.targetNodeId!];
      if (targetNode != null) {
        final targetPort = targetNode.allPorts
            .where((p) => p.id == temp.targetPortId)
            .firstOrNull;
        if (targetPort != null) {
          runInAction(() => targetPort.highlighted.value = false);
        }
      }
    }

    interaction.cancelConnection();

    // Note: Canvas unlocking is now handled by DragSession
    events.connection?.onConnectEnd?.call(
      null,
      null,
      temp == null ? GraphPosition.zero : GraphPosition(temp.currentPoint),
    );
  }
}
