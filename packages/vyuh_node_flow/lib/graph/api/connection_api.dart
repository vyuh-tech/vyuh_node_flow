part of '../node_flow_controller.dart';

/// Connection-related operations for [NodeFlowController].
///
/// This extension provides methods for:
/// - Adding and removing connections
/// - Managing connection control points
/// - Connection queries
extension ConnectionApi<T> on NodeFlowController<T> {
  // ============================================================================
  // Connection CRUD Operations
  // ============================================================================

  /// Adds a connection between two ports.
  ///
  /// Triggers the `onConnectionCreated` callback after successful addition.
  ///
  /// Parameters:
  /// - [connection]: The connection to add
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
  void addConnection(Connection connection) {
    runInAction(() {
      _connections.add(connection);
      // Note: Spatial index is auto-synced via MobX reaction
    });
    // Fire event after successful addition
    events.connection?.onCreated?.call(connection);
  }

  /// Removes a connection from the graph.
  ///
  /// Also removes the connection from the selection set if it was selected.
  ///
  /// Triggers the `onConnectionDeleted` callback after successful removal.
  ///
  /// Parameters:
  /// - [connectionId]: The ID of the connection to remove
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
      // Remove from spatial index
      _spatialIndex.removeConnection(connectionId);
    });

    // Remove cached path to prevent stale rendering
    _connectionPainter?.removeConnectionFromCache(connectionId);

    // Fire event after successful removal
    events.connection?.onDeleted?.call(connectionToDelete);
  }

  /// Calculates the bounding box for a connection based on its source and target nodes.
  Rect? _calculateConnectionBounds(Connection connection) {
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
  // Control Point Operations
  // ============================================================================

  /// Adds a control point to a connection at the specified position.
  ///
  /// Control points are intermediate waypoints that define the path of
  /// editable connections. The new control point is inserted at the given
  /// index in the control points list.
  ///
  /// Automatically invalidates the connection's cached path to trigger a repaint.
  ///
  /// Does nothing if the connection doesn't exist.
  ///
  /// Parameters:
  /// - [connectionId]: The ID of the connection to modify
  /// - [position]: The position of the new control point in graph coordinates
  /// - [index]: The index where the control point should be inserted.
  ///   If null, appends to the end of the control points list.
  ///
  /// Example:
  /// ```dart
  /// // Add a control point at the end
  /// controller.addControlPoint('conn1', Offset(150, 200));
  ///
  /// // Insert a control point at a specific index
  /// controller.addControlPoint('conn1', Offset(100, 150), index: 0);
  /// ```
  void addControlPoint(String connectionId, Offset position, {int? index}) {
    final connection = _connections.firstWhere(
      (c) => c.id == connectionId,
      orElse: () => throw ArgumentError('Connection $connectionId not found'),
    );

    runInAction(() {
      final controlPoints = List<Offset>.from(connection.controlPoints);

      if (index != null && index >= 0 && index <= controlPoints.length) {
        controlPoints.insert(index, position);
      } else {
        controlPoints.add(position);
      }

      connection.controlPoints = controlPoints;
    });

    // Invalidate cached path and rebuild spatial index
    _connectionPainter?.pathCache.removeConnection(connectionId);
    _rebuildSingleConnectionSpatialIndex(connection);
  }

  /// Updates the position of a control point on a connection.
  ///
  /// This method is typically called during drag operations to move an
  /// existing control point to a new position.
  ///
  /// Automatically invalidates the connection's cached path to trigger a repaint.
  ///
  /// Does nothing if the connection doesn't exist or if the index is out of bounds.
  ///
  /// Parameters:
  /// - [connectionId]: The ID of the connection to modify
  /// - [index]: The index of the control point to update
  /// - [position]: The new position of the control point in graph coordinates
  ///
  /// Example:
  /// ```dart
  /// // Move the first control point to a new position
  /// controller.updateControlPoint('conn1', 0, Offset(180, 220));
  /// ```
  void updateControlPoint(String connectionId, int index, Offset position) {
    final connection = _connections.firstWhere(
      (c) => c.id == connectionId,
      orElse: () => throw ArgumentError('Connection $connectionId not found'),
    );

    if (index < 0 || index >= connection.controlPoints.length) {
      return; // Invalid index
    }

    runInAction(() {
      final controlPoints = List<Offset>.from(connection.controlPoints);
      controlPoints[index] = position;
      connection.controlPoints = controlPoints;
    });

    // Invalidate cached path and rebuild spatial index
    _connectionPainter?.pathCache.removeConnection(connectionId);
    _rebuildSingleConnectionSpatialIndex(connection);
  }

  /// Removes a control point from a connection.
  ///
  /// Deletes the control point at the specified index. If this results in
  /// an empty control points list, the connection will revert to using its
  /// default algorithmic path.
  ///
  /// Automatically invalidates the connection's cached path to trigger a repaint.
  ///
  /// Does nothing if the connection doesn't exist or if the index is out of bounds.
  ///
  /// Parameters:
  /// - [connectionId]: The ID of the connection to modify
  /// - [index]: The index of the control point to remove
  ///
  /// Example:
  /// ```dart
  /// // Remove the second control point
  /// controller.removeControlPoint('conn1', 1);
  /// ```
  void removeControlPoint(String connectionId, int index) {
    final connection = _connections.firstWhere(
      (c) => c.id == connectionId,
      orElse: () => throw ArgumentError('Connection $connectionId not found'),
    );

    if (index < 0 || index >= connection.controlPoints.length) {
      return; // Invalid index
    }

    runInAction(() {
      final controlPoints = List<Offset>.from(connection.controlPoints);
      controlPoints.removeAt(index);
      connection.controlPoints = controlPoints;
    });

    // Invalidate cached path and rebuild spatial index
    _connectionPainter?.pathCache.removeConnection(connectionId);
    _rebuildSingleConnectionSpatialIndex(connection);
  }

  /// Clears all control points from a connection.
  ///
  /// This reverts the connection to using its default algorithmic path.
  ///
  /// Automatically invalidates the connection's cached path to trigger a repaint.
  ///
  /// Does nothing if the connection doesn't exist.
  ///
  /// Parameters:
  /// - [connectionId]: The ID of the connection to modify
  ///
  /// Example:
  /// ```dart
  /// controller.clearControlPoints('conn1');
  /// ```
  void clearControlPoints(String connectionId) {
    final connection = _connections.firstWhere(
      (c) => c.id == connectionId,
      orElse: () => throw ArgumentError('Connection $connectionId not found'),
    );

    runInAction(() {
      connection.controlPoints = [];
    });

    // Invalidate cached path and rebuild spatial index
    _connectionPainter?.pathCache.removeConnection(connectionId);
    _rebuildSingleConnectionSpatialIndex(connection);
  }
}
