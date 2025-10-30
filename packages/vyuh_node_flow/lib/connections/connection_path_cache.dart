import 'package:flutter/material.dart';

import '../connections/connection.dart' show Connection;
import '../connections/connection_path_calculator.dart';
import '../connections/connection_style_base.dart';
import '../connections/endpoint_position_calculator.dart';
import '../graph/node_flow_theme.dart';
import '../nodes/node.dart';
import '../ports/port.dart';

/// Cached path data with hit testing capabilities
class _CachedConnectionPath {
  _CachedConnectionPath({
    required this.originalPath,
    required this.hitTestPath,
    required this.sourcePosition,
    required this.targetPosition,
  });

  /// The original geometric path for drawing
  final Path originalPath;

  /// The expanded path for hit testing (includes stroke tolerance)
  final Path hitTestPath;

  /// Cached node positions for invalidation
  final Offset sourcePosition;
  final Offset targetPosition;
}

/// Manages connection path caching and hit testing
/// Separates concerns from ConnectionPainter
class ConnectionPathCache {
  ConnectionPathCache({required NodeFlowTheme theme}) : _theme = theme;

  NodeFlowTheme _theme;

  NodeFlowTheme get theme => _theme;

  /// Update the theme and intelligently invalidate cache if needed
  void updateTheme(NodeFlowTheme newTheme) {
    final oldTheme = _theme;
    _theme = newTheme;

    // Invalidate cache only if path-affecting properties changed
    final pathChanged =
        oldTheme.connectionStyle != newTheme.connectionStyle ||
        oldTheme.connectionTheme.bezierCurvature !=
            newTheme.connectionTheme.bezierCurvature ||
        oldTheme.connectionTheme.cornerRadius !=
            newTheme.connectionTheme.cornerRadius ||
        oldTheme.connectionTheme.startPoint !=
            newTheme.connectionTheme.startPoint ||
        oldTheme.connectionTheme.endPoint !=
            newTheme.connectionTheme.endPoint ||
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
        connectionStyle: theme.connectionStyle,
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

    // Check if cache needs updating
    final existing = _getCachedPath(connection.id);
    if (existing != null &&
        existing.sourcePosition == currentSourcePos &&
        existing.targetPosition == currentTargetPos) {
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
  }) {
    // Get connection and port themes
    final connectionTheme = theme.connectionTheme;
    final portTheme = theme.portTheme;

    // Calculate port positions
    final sourcePortPosition = sourceNode.getPortPosition(
      connection.sourcePortId,
      portSize: portTheme.size,
    );
    final targetPortPosition = targetNode.getPortPosition(
      connection.targetPortId,
      portSize: portTheme.size,
    );

    // Get ports
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

    // Get effective endpoint configurations from connection instance or theme
    final effectiveStartPoint = connection.getEffectiveStartPoint(
      connectionTheme.startPoint,
    );
    final effectiveEndPoint = connection.getEffectiveEndPoint(
      connectionTheme.endPoint,
    );

    // Calculate connection points
    final source = EndpointPositionCalculator.calculatePortConnectionPoints(
      sourcePortPosition,
      sourcePort.position,
      effectiveStartPoint.size,
      portTheme.size,
    );
    final target = EndpointPositionCalculator.calculatePortConnectionPoints(
      targetPortPosition,
      targetPort.position,
      effectiveEndPoint.size,
      portTheme.size,
    );

    // Create the original geometric path
    final originalPath = ConnectionPathCalculator.createConnectionPath(
      style: connectionStyle,
      // Use the passed connection style which is already effective
      start: source.linePos,
      end: target.linePos,
      curvature: connectionTheme.bezierCurvature,
      sourcePort: sourcePort,
      targetPort: targetPort,
      cornerRadius: connectionTheme.cornerRadius,
    );

    // Create hit test path with connection style-specific logic
    final hitTestPath = _createHitTestPath(
      originalPath,
      defaultHitTolerance,
      connectionStyle: connectionStyle,
      sourcePort: sourcePort,
      targetPort: targetPort,
    );

    // Cache both paths
    final cachedPath = _CachedConnectionPath(
      originalPath: originalPath,
      hitTestPath: hitTestPath,
      sourcePosition: sourcePosition,
      targetPosition: targetPosition,
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
    Port? sourcePort,
    Port? targetPort,
  }) {
    // Delegate to the connection style's own hit test path creation
    return connectionStyle.createHitTestPath(originalPath, tolerance);
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
