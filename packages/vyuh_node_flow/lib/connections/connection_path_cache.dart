import 'package:flutter/material.dart';

import '../connections/connection.dart' show Connection;
import '../connections/styles/connection_style_base.dart';
import '../connections/styles/endpoint_position_calculator.dart';
import '../graph/node_flow_theme.dart';
import '../nodes/node.dart';
import '../nodes/node_shape.dart';
import '../ports/port.dart';
import '../shared/shapes/none_marker_shape.dart';

/// Cached path data with hit testing capabilities
class _CachedConnectionPath {
  _CachedConnectionPath({
    required this.originalPath,
    required this.hitTestPath,
    required this.sourcePosition,
    required this.targetPosition,
    required this.startGap,
    required this.endGap,
  });

  /// The original geometric path for drawing
  final Path originalPath;

  /// The expanded path for hit testing (includes stroke tolerance)
  final Path hitTestPath;

  /// Cached node positions for invalidation
  final Offset sourcePosition;
  final Offset targetPosition;

  /// Cached gap values for invalidation
  final double startGap;
  final double endGap;
}

/// Manages connection path caching and hit testing
/// Separates concerns from ConnectionPainter
class ConnectionPathCache {
  ConnectionPathCache({required NodeFlowTheme theme, this.nodeShape})
    : _theme = theme;

  NodeFlowTheme _theme;

  NodeFlowTheme get theme => _theme;

  /// Optional function to get the shape for a node.
  /// Used to calculate correct port positions for shaped nodes.
  NodeShape? Function(Node node)? nodeShape;

  /// Update the theme and intelligently invalidate cache if needed
  void updateTheme(NodeFlowTheme newTheme) {
    final oldTheme = _theme;
    _theme = newTheme;

    // Invalidate cache only if path-affecting properties changed
    final pathChanged =
        oldTheme.connectionTheme.style != newTheme.connectionTheme.style ||
        oldTheme.connectionTheme.bezierCurvature !=
            newTheme.connectionTheme.bezierCurvature ||
        oldTheme.connectionTheme.cornerRadius !=
            newTheme.connectionTheme.cornerRadius ||
        oldTheme.connectionTheme.startPoint !=
            newTheme.connectionTheme.startPoint ||
        oldTheme.connectionTheme.endPoint !=
            newTheme.connectionTheme.endPoint ||
        oldTheme.connectionTheme.startGap !=
            newTheme.connectionTheme.startGap ||
        oldTheme.connectionTheme.endGap != newTheme.connectionTheme.endGap ||
        oldTheme.portTheme.size != newTheme.portTheme.size;

    if (pathChanged) {
      invalidateAll();
    }
  }

  /// Invalidate all cached paths
  void invalidateAll() {
    _pathCache.clear();
  }

  /// Get the hit tolerance from the connection theme
  double get defaultHitTolerance => theme.connectionTheme.hitTolerance;

  // Cache storage
  final Map<String, _CachedConnectionPath> _pathCache = {};

  /// Test if a point hits a connection path
  /// Returns true if the point is within the hit tolerance of the connection
  bool hitTest({
    required Connection connection,
    required Node sourceNode,
    required Node targetNode,
    required Offset testPoint,
    double? tolerance,
  }) {
    final hitTolerance = tolerance ?? defaultHitTolerance;

    // Get cached path - read only, no creation during hit testing
    final cachedPath = _getCachedPath(connection.id);
    if (cachedPath == null) {
      return false; // No cached path - should be created during painting
    }

    // Validate cache is still valid
    final currentSourcePos = sourceNode.position.value;
    final currentTargetPos = targetNode.position.value;

    if (cachedPath.sourcePosition != currentSourcePos ||
        cachedPath.targetPosition != currentTargetPos) {
      return false; // Stale cache - will be recreated on next paint
    }

    // Use the pre-computed hit test path (already expanded for tolerance)
    // Only recompute if tolerance differs significantly from default
    if ((hitTolerance - defaultHitTolerance).abs() > 1.0) {
      // Custom tolerance - create temporary expanded path
      final customHitPath = _createHitTestPath(
        cachedPath.originalPath,
        hitTolerance,
        connectionStyle: theme.connectionTheme.style,
      );
      return customHitPath.contains(testPoint);
    }

    // Use cached hit test path (most common case)
    return cachedPath.hitTestPath.contains(testPoint);
  }

  /// Get or create cached path during painting operations
  /// This is the only place where paths should be created
  Path? getOrCreatePath({
    required Connection connection,
    required Node sourceNode,
    required Node targetNode,
    required ConnectionStyle connectionStyle,
  }) {
    final currentSourcePos = sourceNode.position.value;
    final currentTargetPos = targetNode.position.value;
    final connectionTheme = theme.connectionTheme;
    final currentStartGap = connection.startGap ?? connectionTheme.startGap;
    final currentEndGap = connection.endGap ?? connectionTheme.endGap;

    // Check if cache needs updating
    final existing = _getCachedPath(connection.id);
    if (existing != null &&
        existing.sourcePosition == currentSourcePos &&
        existing.targetPosition == currentTargetPos &&
        existing.startGap == currentStartGap &&
        existing.endGap == currentEndGap) {
      return existing.originalPath; // Cache hit
    }

    // Create new path and cache it
    final newPath = _createAndCachePath(
      connection: connection,
      sourceNode: sourceNode,
      targetNode: targetNode,
      sourcePosition: currentSourcePos,
      targetPosition: currentTargetPos,
      connectionStyle: connectionStyle,
      startGap: currentStartGap,
      endGap: currentEndGap,
    );

    return newPath?.originalPath;
  }

  /// Create and cache a new connection path
  _CachedConnectionPath? _createAndCachePath({
    required Connection connection,
    required Node sourceNode,
    required Node targetNode,
    required Offset sourcePosition,
    required Offset targetPosition,
    required ConnectionStyle connectionStyle,
    required double startGap,
    required double endGap,
  }) {
    // Get connection and port themes
    final connectionTheme = theme.connectionTheme;
    final portTheme = theme.portTheme;

    // Get shapes for the nodes (if shape builder is available)
    final sourceShape = nodeShape?.call(sourceNode);
    final targetShape = nodeShape?.call(targetNode);

    // Get ports first to determine their sizes
    Port? sourcePort;
    Port? targetPort;

    try {
      sourcePort = [
        ...sourceNode.inputPorts,
        ...sourceNode.outputPorts,
      ].firstWhere((port) => port.id == connection.sourcePortId);
    } catch (e) {
      return null;
    }

    try {
      targetPort = [
        ...targetNode.inputPorts,
        ...targetNode.outputPorts,
      ].firstWhere((port) => port.id == connection.targetPortId);
    } catch (e) {
      return null;
    }

    // Use cascade: port.size if set, otherwise fallback to theme.size
    final sourcePortSize = sourcePort.size ?? portTheme.size;
    final targetPortSize = targetPort.size ?? portTheme.size;

    // Calculate port positions with shapes and effective sizes
    final sourcePortPosition = sourceNode.getPortPosition(
      connection.sourcePortId,
      portSize: sourcePortSize,
      shape: sourceShape,
    );
    final targetPortPosition = targetNode.getPortPosition(
      connection.targetPortId,
      portSize: targetPortSize,
      shape: targetShape,
    );

    // Get effective endpoint configurations from connection instance or theme
    final effectiveStartPoint = connection.getEffectiveStartPoint(
      connectionTheme.startPoint,
    );
    final effectiveEndPoint = connection.getEffectiveEndPoint(
      connectionTheme.endPoint,
    );

    // Use 0 size for NoneMarkerShape to avoid creating gaps
    final startPointSize = effectiveStartPoint.shape is NoneMarkerShape
        ? Size.zero
        : effectiveStartPoint.size;
    final endPointSize = effectiveEndPoint.shape is NoneMarkerShape
        ? Size.zero
        : effectiveEndPoint.size;

    // Calculate connection points using passed gap values
    final source = EndpointPositionCalculator.calculatePortConnectionPoints(
      sourcePortPosition,
      sourcePort.position,
      startPointSize,
      gap: startGap,
    );
    final target = EndpointPositionCalculator.calculatePortConnectionPoints(
      targetPortPosition,
      targetPort.position,
      endPointSize,
      gap: endGap,
    );

    // Create path parameters for both original and hit test paths
    final pathParams = ConnectionPathParameters(
      start: source.linePos,
      end: target.linePos,
      curvature: connectionTheme.bezierCurvature,
      sourcePort: sourcePort,
      targetPort: targetPort,
      cornerRadius: connectionTheme.cornerRadius,
      offset: connectionTheme.portExtension,
      controlPoints: connection.controlPoints
          .toList(), // Convert ObservableList to List
    );

    // Create the original geometric path
    final originalPath = connectionStyle.createPath(pathParams);

    // Create hit test path with connection style-specific logic
    final hitTestPath = _createHitTestPath(
      originalPath,
      defaultHitTolerance,
      connectionStyle: connectionStyle,
      pathParams: pathParams,
    );

    // Cache both paths with gap values for invalidation
    final cachedPath = _CachedConnectionPath(
      originalPath: originalPath,
      hitTestPath: hitTestPath,
      sourcePosition: sourcePosition,
      targetPosition: targetPosition,
      startGap: startGap,
      endGap: endGap,
    );

    _pathCache[connection.id] = cachedPath;
    return cachedPath;
  }

  /// Create an expanded path for hit testing with given tolerance
  /// Uses connection style-specific segmentation strategies
  Path _createHitTestPath(
    Path originalPath,
    double tolerance, {
    required ConnectionStyle connectionStyle,
    ConnectionPathParameters? pathParams,
  }) {
    // Delegate to the connection style's own hit test path creation
    // Pass path parameters if available for optimized hit test path creation
    return connectionStyle.createHitTestPath(
      originalPath,
      tolerance,
      pathParams: pathParams,
    );
  }

  /// Get cached path (read-only)
  _CachedConnectionPath? _getCachedPath(String connectionId) {
    return _pathCache[connectionId];
  }

  /// Remove cached path when connection is deleted
  void removeConnection(String connectionId) {
    _pathCache.remove(connectionId);
  }

  /// Clear all cached paths
  void clearAll() {
    if (_pathCache.isEmpty) return;
    _pathCache.clear();
  }

  /// Check if connection has cached path
  bool hasConnection(String connectionId) {
    return _pathCache.containsKey(connectionId);
  }

  /// Get the cached hit test path for debugging purposes
  Path? getHitTestPath(String connectionId) {
    return _getCachedPath(connectionId)?.hitTestPath;
  }

  /// Get the cached original path for debugging purposes
  Path? getOriginalPath(String connectionId) {
    return _getCachedPath(connectionId)?.originalPath;
  }

  /// Get cache statistics
  Map<String, dynamic> getStats() {
    return {
      'cachedPaths': _pathCache.length,
      'hitTolerance': defaultHitTolerance,
      'hitToleranceSource': 'theme.connectionTheme.hitTolerance',
    };
  }

  /// Dispose and clean up
  void dispose() {
    _pathCache.clear();
  }
}
