part of 'node_flow_controller.dart';

/// Dirty tracking and spatial index management for [NodeFlowController].
///
/// This extension groups all the dirty tracking logic for efficient spatial
/// index updates. The pattern defers spatial index updates during drag
/// operations and batches them when the drag ends.
///
/// ## Key Concepts
///
/// - **Dirty tracking**: Nodes/connections are marked "dirty" during drag
/// - **Deferred updates**: Spatial index updates are deferred to pending sets
/// - **Batch flush**: All pending updates are flushed when drag ends
/// - **Connection index**: O(1) lookup of connections by node ID
///
/// ## Performance
///
/// During drag operations, spatial index updates are expensive and can cause
/// jank. This extension defers updates until the drag ends, then batches all
/// updates together for better performance.
extension DirtyTrackingExtension<T, C> on NodeFlowController<T, C> {
  // ============================================================================
  // State Queries
  // ============================================================================

  /// Checks if any drag operation is in progress.
  bool get _isAnyDragInProgress => interaction.draggedNodeId.value != null;

  /// Checks if spatial index updates should be deferred.
  /// Updates are deferred during drag UNLESS debug mode is on (for live visualization).
  bool get _shouldDeferSpatialUpdates =>
      _isAnyDragInProgress &&
      !(getExtension<DebugExtension>()?.isEnabled ?? false);

  // ============================================================================
  // Internal API (library-private)
  // ============================================================================

  /// Marks a node as needing spatial index update.
  ///
  /// If no drag is in progress (or debug mode is on), updates immediately.
  /// Otherwise, defers until drag ends.
  void _markNodeDirty(String nodeId) {
    if (_shouldDeferSpatialUpdates) {
      _pendingNodeUpdates.add(nodeId);
      // Also mark connected connections as dirty
      final connectedIds = _connectionsByNodeId[nodeId];
      if (connectedIds != null) {
        _pendingConnectionUpdates.addAll(connectedIds);
      }
    } else {
      // Immediate update
      final node = _nodes[nodeId];
      if (node != null) {
        _spatialIndex.update(node);
        _updateConnectionBoundsForNode(nodeId);
      }
    }
  }

  /// Marks multiple nodes as needing spatial index update.
  void _markNodesDirty(Iterable<String> nodeIds) {
    if (_shouldDeferSpatialUpdates) {
      _pendingNodeUpdates.addAll(nodeIds);
      // Also mark connected connections as dirty
      for (final nodeId in nodeIds) {
        final connectedIds = _connectionsByNodeId[nodeId];
        if (connectedIds != null) {
          _pendingConnectionUpdates.addAll(connectedIds);
        }
      }
    } else {
      // Immediate update
      _spatialIndex.batch(() {
        for (final nodeId in nodeIds) {
          final node = _nodes[nodeId];
          if (node != null) {
            _spatialIndex.update(node);
          }
        }
      });
      _updateConnectionBoundsForNodeIds(nodeIds);
    }
  }

  /// Flushes all pending spatial index updates synchronously.
  ///
  /// This method should be called after drag operations end to ensure the
  /// spatial index is up-to-date before performing hit tests. Normally the
  /// flush happens via a MobX reaction, but that's asynchronous. This method
  /// allows synchronous flushing when immediate hit testing is needed.
  void flushPendingSpatialUpdates() {
    _flushPendingSpatialUpdates();
  }

  // ============================================================================
  // Internal Implementation
  // ============================================================================

  /// Flushes all pending spatial index updates.
  /// Called when drag operations end.
  void _flushPendingSpatialUpdates() {
    bool hadUpdates = false;

    // Flush node updates
    if (_pendingNodeUpdates.isNotEmpty) {
      hadUpdates = true;
      _spatialIndex.batch(() {
        for (final nodeId in _pendingNodeUpdates) {
          final node = _nodes[nodeId];
          if (node != null) {
            _spatialIndex.update(node);
          }
        }
      });
      _pendingNodeUpdates.clear();
    }

    // Flush connection updates using proper segment bounds
    if (_pendingConnectionUpdates.isNotEmpty) {
      hadUpdates = true;
      _flushPendingConnectionUpdates();
      _pendingConnectionUpdates.clear();
    }

    // Always notify at the end of flush to ensure debug layer updates
    // even if all pending updates were handled via batch (which also notifies)
    if (hadUpdates) {
      // Force a final notification to ensure observers are updated
      _spatialIndex.notifyChanged();
    }
  }

  /// Returns a signature of all path-affecting theme properties.
  /// Used by the reaction to detect when spatial index needs rebuilding.
  Object _getPathAffectingSignature() {
    final theme = _themeObservable.value;
    if (theme == null) return const Object();

    final conn = theme.connectionTheme;
    // Return a tuple of all properties that affect connection path geometry
    return (
      conn.style.id,
      conn.bezierCurvature,
      conn.cornerRadius,
      conn.portExtension,
      conn.backEdgeGap,
      conn.startGap,
      conn.endGap,
      conn.hitTolerance,
      theme.portTheme.size,
    );
  }

  /// Flushes pending connection updates using proper segment bounds from path cache.
  void _flushPendingConnectionUpdates() {
    if (!isConnectionPainterInitialized || _theme == null) return;

    final pathCache = _connectionPainter!.pathCache;
    final connectionStyle = _theme!.connectionTheme.style;

    for (final connectionId in _pendingConnectionUpdates) {
      final connection = _connections.firstWhere(
        (c) => c.id == connectionId,
        orElse: () => throw StateError('Connection not found: $connectionId'),
      );

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

  /// Rebuilds the connection-by-node index for O(1) lookup.
  void _rebuildConnectionsByNodeIndex() {
    _connectionsByNodeId.clear();
    for (final connection in _connections) {
      _connectionsByNodeId
          .putIfAbsent(connection.sourceNodeId, () => {})
          .add(connection.id);
      _connectionsByNodeId
          .putIfAbsent(connection.targetNodeId, () => {})
          .add(connection.id);
    }
  }

  /// Updates spatial index bounds for a single node's connections using proper segment bounds.
  void _updateConnectionBoundsForNode(String nodeId) {
    // Use the API method that calculates proper segment bounds from path cache
    rebuildConnectionSegmentsForNodes([nodeId]);
  }

  /// Updates spatial index bounds for connections attached to the given nodes.
  void _updateConnectionBoundsForNodeIds(Iterable<String> nodeIds) {
    // Use the API method that calculates proper segment bounds from path cache
    rebuildConnectionSegmentsForNodes(nodeIds.toList());
  }
}
