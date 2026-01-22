part of 'node_flow_controller.dart';

/// Group and node monitoring operations for [NodeFlowController].
///
/// This extension provides APIs for:
/// - Setting up node monitoring reactions (for GroupNode tracking)
/// - Managing drag contexts for group operations
/// - Moving nodes by delta (used by GroupNode to move children)
/// - Finding nodes within bounds (for containment detection)
/// - Notifying groupable nodes of additions/deletions
///
/// These are primarily internal operations used by [GroupNode] and
/// [GroupableMixin] implementations.
extension GroupApi<T, C> on NodeFlowController<T, C> {
  // ============================================================================
  // Reaction Setup
  // ============================================================================

  /// Sets up reactions for node monitoring (used by GroupNode to track child nodes).
  ///
  /// This enables GroupNodes with explicit or parent behavior to react when
  /// their member nodes move, resize, or are deleted.
  void _setupNodeMonitoringReactions() {
    // Global reaction for node additions/deletions
    reaction((_) => _nodes.keys.toSet(), (Set<String> currentNodeIds) {
      // Skip if we're currently moving nodes during group drag
      if (_isMovingGroupNodes) return;

      final context = _createDragContext();

      // Detect deleted nodes
      final deletedIds = _previousNodeIds.difference(currentNodeIds);
      if (deletedIds.isNotEmpty) {
        _notifyNodesOfNodeDeletions(deletedIds, context);
      }

      // Detect added nodes
      final addedIds = currentNodeIds.difference(_previousNodeIds);
      if (addedIds.isNotEmpty) {
        _notifyNodesOfNodeAdditions(addedIds, context);
      }

      _previousNodeIds = currentNodeIds;
    }, fireImmediately: true);
  }

  /// Sets up reactions for selection change events.
  void _setupSelectionReactions() {
    // Fire selection change event when selection changes
    reaction(
      (_) {
        // Observe all selection state
        return (_selectedNodeIds.toSet(), _selectedConnectionIds.toSet());
      },
      (_) {
        // Build selection state
        final selectedNodes = _selectedNodeIds
            .map((id) => _nodes[id])
            .where((node) => node != null)
            .cast<Node<T>>()
            .toList();

        final selectedConnections = _selectedConnectionIds
            .map((id) => getConnection(id))
            .where((conn) => conn != null)
            .cast<Connection<C>>()
            .toList();

        final selectionState = SelectionState<T, C>(
          nodes: selectedNodes,
          connections: selectedConnections,
        );

        // Fire the selection change event
        events.onSelectionChange?.call(selectionState);
      },
    );
  }

  // ============================================================================
  // Context Creation
  // ============================================================================

  /// Creates a drag context for node lifecycle methods.
  ///
  /// The context provides callbacks for nodes (like [GroupNode]) that need
  /// to move child nodes, look up node bounds, etc.
  NodeDragContext<T> _createDragContext() {
    return NodeDragContext<T>(
      moveNodes: _moveNodesByDelta,
      findNodesInBounds: _findNodesInBounds,
      getNode: (nodeId) => _nodes[nodeId],
      selectedNodeIds: _selectedNodeIds,
    );
  }

  /// Creates a context for GroupableMixin nodes.
  ///
  /// This extends the drag context with `shouldSkipUpdates` to prevent
  /// recursive updates during group drag operations.
  NodeDragContext<T> _createGroupableContext() {
    return NodeDragContext<T>(
      moveNodes: _moveNodesByDelta,
      findNodesInBounds: _findNodesInBounds,
      getNode: (nodeId) => _nodes[nodeId],
      shouldSkipUpdates: () => _isMovingGroupNodes,
      selectedNodeIds: _selectedNodeIds,
    );
  }

  // ============================================================================
  // Node Movement
  // ============================================================================

  /// Moves nodes by a given delta, handling position and visual position with snapping.
  void _moveNodesByDelta(Set<String> nodeIds, Offset delta) {
    // Check if already moving to prevent nested calls
    if (_isMovingGroupNodes) {
      return;
    }

    if (nodeIds.isEmpty) return;

    // Temporarily disable updates to prevent cycles
    _isMovingGroupNodes = true;

    try {
      runInAction(() {
        for (final nodeId in nodeIds) {
          final node = _nodes[nodeId];
          if (node != null) {
            final newPosition = node.position.value + delta;

            // Update both position and visual position
            node.position.value = newPosition;
            final snappedPosition = snapToGrid(newPosition);
            node.setVisualPosition(snappedPosition);
          }
        }
      });

      // Mark nodes dirty (deferred during drag)
      _markNodesDirty(nodeIds);
    } finally {
      _isMovingGroupNodes = false;
    }
  }

  // ============================================================================
  // Bounds Queries
  // ============================================================================

  /// Finds all node IDs whose bounds are completely contained within the given rect.
  ///
  /// This includes both regular nodes AND GroupNodes, enabling nested groups.
  /// A node cannot contain itself because Rect.contains uses exclusive bounds
  /// for bottom-right (the bottomRight point won't satisfy `< right` and `< bottom`).
  Set<String> _findNodesInBounds(Rect bounds) {
    final containedNodeIds = <String>{};

    for (final entry in _nodes.entries) {
      final node = entry.value;

      final nodeRect = Rect.fromLTWH(
        node.visualPosition.value.dx,
        node.visualPosition.value.dy,
        node.size.value.width,
        node.size.value.height,
      );

      // Node must be completely inside the bounds
      if (bounds.contains(nodeRect.topLeft) &&
          bounds.contains(nodeRect.bottomRight)) {
        containedNodeIds.add(entry.key);
      }
    }

    return containedNodeIds;
  }

  // ============================================================================
  // Node Lifecycle Notifications
  // ============================================================================

  /// Notifies groupable nodes when other nodes are deleted.
  void _notifyNodesOfNodeDeletions(
    Set<String> deletedIds,
    NodeDragContext<T> context,
  ) {
    final nodesToRemove = <String>[];

    for (final node in _nodes.values) {
      // Only nodes with GroupableMixin can monitor other nodes
      if (node is GroupableMixin<T>) {
        if (node.isGroupable) {
          node.onChildrenDeleted(deletedIds);

          // Check if node wants to be removed
          if (node.shouldRemoveWhenEmpty && node.isEmpty) {
            nodesToRemove.add(node.id);
          }
        }
      }
    }

    // Remove empty nodes
    for (final nodeId in nodesToRemove) {
      removeNode(nodeId);
    }
  }

  /// Notifies groupable nodes when other nodes are added.
  void _notifyNodesOfNodeAdditions(
    Set<String> addedIds,
    NodeDragContext<T> context,
  ) {
    for (final addedNodeId in addedIds) {
      final addedNode = _nodes[addedNodeId];
      if (addedNode == null) continue;

      final nodeBounds = addedNode.getBounds();
      for (final node in _nodes.values) {
        // Only nodes with GroupableMixin can monitor other nodes
        if (node is GroupableMixin<T> && node.id != addedNodeId) {
          if (node.isGroupable) {
            node.onNodeAdded(addedNodeId, nodeBounds);
          }
        }
      }
    }
  }
}
