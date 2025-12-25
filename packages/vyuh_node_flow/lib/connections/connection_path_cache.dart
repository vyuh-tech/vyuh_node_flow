import 'package:flutter/material.dart';

import '../connections/connection.dart' show Connection;
import '../connections/styles/connection_style_base.dart';
import '../connections/styles/endpoint_position_calculator.dart';
import '../graph/node_flow_theme.dart';
import '../nodes/node.dart';
import '../nodes/node_shape.dart';
import '../shared/shapes/none_marker_shape.dart';

/// Cached path data with hit testing capabilities
class _CachedConnectionPath {
  _CachedConnectionPath({
    required this.originalPath,
    required this.hitTestPath,
    required this.segmentBounds,
    required this.sourcePosition,
    required this.targetPosition,
    required this.startGap,
    required this.endGap,
    required this.sourceNodeSize,
    required this.targetNodeSize,
    required this.sourcePortOffset,
    required this.targetPortOffset,
  });

  /// The original geometric path for drawing
  final Path originalPath;

  /// The expanded path for hit testing (includes stroke tolerance)
  final Path hitTestPath;

  /// Rectangle bounds for each path segment, used for spatial indexing
  final List<Rect> segmentBounds;

  /// Cached node positions for invalidation
  final Offset sourcePosition;
  final Offset targetPosition;

  /// Cached gap values for invalidation
  final double startGap;
  final double endGap;

  /// Cached node sizes for invalidation (used for node-aware routing)
  final Size sourceNodeSize;
  final Size targetNodeSize;

  /// Cached port offsets for invalidation (used when ports are reordered)
  final Offset sourcePortOffset;
  final Offset targetPortOffset;
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
        oldTheme.connectionTheme.portExtension !=
            newTheme.connectionTheme.portExtension ||
        oldTheme.connectionTheme.backEdgeGap !=
            newTheme.connectionTheme.backEdgeGap ||
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
    // Skip hit testing for hidden connections
    if (!sourceNode.isVisible || !targetNode.isVisible) {
      return false;
    }

    final hitTolerance = tolerance ?? defaultHitTolerance;
    final connectionStyle = theme.connectionTheme.style;

    // Get cached path
    final cachedPath = _getCachedPath(connection.id);
    final currentSourcePos = sourceNode.position.value;
    final currentTargetPos = targetNode.position.value;

    // Get current port offsets for cache invalidation
    final sourcePort = sourceNode.findPort(connection.sourcePortId);
    final targetPort = targetNode.findPort(connection.targetPortId);
    final currentSourcePortOffset = sourcePort?.offset ?? Offset.zero;
    final currentTargetPortOffset = targetPort?.offset ?? Offset.zero;

    // Check if cache is valid (positions and port offsets match)
    final cacheValid =
        cachedPath != null &&
        cachedPath.sourcePosition == currentSourcePos &&
        cachedPath.targetPosition == currentTargetPos &&
        cachedPath.sourcePortOffset == currentSourcePortOffset &&
        cachedPath.targetPortOffset == currentTargetPortOffset;

    if (cacheValid) {
      // Use the pre-computed hit test path (already expanded for tolerance)
      // Only recompute if tolerance differs significantly from default
      if ((hitTolerance - defaultHitTolerance).abs() > 1.0) {
        // Custom tolerance - recompute hit test with new tolerance
        // Note: We'd need the segments to do this properly, but for now
        // we can use the cached path bounds with adjusted tolerance
        // This is a simplification - for full accuracy we'd cache segments too
        return cachedPath.hitTestPath.contains(testPoint);
      }

      // Use cached hit test path (most common case)
      return cachedPath.hitTestPath.contains(testPoint);
    }

    // Cache is stale or missing - compute path on-demand for hit testing
    // This ensures hit testing works even before the next paint cycle
    final newCachedPath = _createAndCachePath(
      connection: connection,
      sourceNode: sourceNode,
      targetNode: targetNode,
      sourcePosition: currentSourcePos,
      targetPosition: currentTargetPos,
      connectionStyle: connectionStyle,
      startGap: connection.startGap ?? theme.connectionTheme.startGap,
      endGap: connection.endGap ?? theme.connectionTheme.endGap,
    );

    if (newCachedPath == null) {
      return false; // Could not create path (missing ports, etc.)
    }

    // Use the newly created hit test path
    // Note: Custom tolerance handling simplified - use default tolerance
    return newCachedPath.hitTestPath.contains(testPoint);
  }

  /// Get or create cached path during painting operations
  /// This is the only place where paths should be created
  Path? getOrCreatePath({
    required Connection connection,
    required Node sourceNode,
    required Node targetNode,
    required ConnectionStyle connectionStyle,
  }) {
    // Skip path creation for hidden connections
    if (!sourceNode.isVisible || !targetNode.isVisible) {
      return null;
    }

    final currentSourcePos = sourceNode.position.value;
    final currentTargetPos = targetNode.position.value;
    final currentSourceSize = sourceNode.size.value;
    final currentTargetSize = targetNode.size.value;
    final connectionTheme = theme.connectionTheme;
    final currentStartGap = connection.startGap ?? connectionTheme.startGap;
    final currentEndGap = connection.endGap ?? connectionTheme.endGap;

    // Get current port offsets for cache invalidation
    final sourcePort = sourceNode.findPort(connection.sourcePortId);
    final targetPort = targetNode.findPort(connection.targetPortId);
    final currentSourcePortOffset = sourcePort?.offset ?? Offset.zero;
    final currentTargetPortOffset = targetPort?.offset ?? Offset.zero;

    // Check if cache needs updating (including node sizes and port offsets)
    final existing = _getCachedPath(connection.id);
    if (existing != null &&
        existing.sourcePosition == currentSourcePos &&
        existing.targetPosition == currentTargetPos &&
        existing.startGap == currentStartGap &&
        existing.endGap == currentEndGap &&
        existing.sourceNodeSize == currentSourceSize &&
        existing.targetNodeSize == currentTargetSize &&
        existing.sourcePortOffset == currentSourcePortOffset &&
        existing.targetPortOffset == currentTargetPortOffset) {
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
    // Use Node.findPort which safely returns null if not found
    final sourcePort = sourceNode.findPort(connection.sourcePortId);
    final targetPort = targetNode.findPort(connection.targetPortId);

    // Return null if either port is not found - connection may be stale or ports
    // haven't been set up yet (e.g., during widget initialization)
    if (sourcePort == null || targetPort == null) {
      return null;
    }

    // Use cascade: port.size if set, otherwise fallback to theme.size
    final sourcePortSize = sourcePort.size ?? portTheme.size;
    final targetPortSize = targetPort.size ?? portTheme.size;

    // Calculate port positions with shapes and effective sizes
    final sourcePortPosition = sourceNode.getConnectionPoint(
      connection.sourcePortId,
      portSize: sourcePortSize,
      shape: sourceShape,
    );
    final targetConnectionPoint = targetNode.getConnectionPoint(
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
      targetConnectionPoint,
      targetPort.position,
      endPointSize,
      gap: endGap,
    );

    // Get node bounds for node-aware routing
    final sourceNodeBounds = sourceNode.getBounds();
    final targetNodeBounds = targetNode.getBounds();

    // Create path parameters for both original and hit test paths
    final pathParams = ConnectionPathParameters(
      start: source.linePos,
      end: target.linePos,
      curvature: connectionTheme.bezierCurvature,
      sourcePort: sourcePort,
      targetPort: targetPort,
      cornerRadius: connectionTheme.cornerRadius,
      offset: connectionTheme.portExtension,
      backEdgeGap: connectionTheme.backEdgeGap,
      controlPoints: connection.controlPoints
          .toList(), // Convert ObservableList to List
      sourceNodeBounds: sourceNodeBounds,
      targetNodeBounds: targetNodeBounds,
    );

    // Create segments ONCE - this is the canonical source
    final segmentResult = connectionStyle.createSegments(pathParams);

    // Derive path and hit test from segments using style's build methods
    final originalPath = connectionStyle.buildPath(
      segmentResult.start,
      segmentResult.segments,
    );

    final segmentBounds = connectionStyle.buildHitTestRects(
      segmentResult.start,
      segmentResult.segments,
      defaultHitTolerance,
    );

    final hitTestPath = connectionStyle.buildHitTestPath(segmentBounds);

    // Cache paths and segment bounds for invalidation
    final cachedPath = _CachedConnectionPath(
      originalPath: originalPath,
      hitTestPath: hitTestPath,
      segmentBounds: segmentBounds,
      sourcePosition: sourcePosition,
      targetPosition: targetPosition,
      startGap: startGap,
      endGap: endGap,
      sourceNodeSize: sourceNode.size.value,
      targetNodeSize: targetNode.size.value,
      sourcePortOffset: sourcePort.offset,
      targetPortOffset: targetPort.offset,
    );

    _pathCache[connection.id] = cachedPath;
    return cachedPath;
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

  /// Get the cached segment bounds for spatial indexing.
  /// Returns null if there's no cached path for this connection.
  List<Rect>? getSegmentBounds(String connectionId) {
    return _getCachedPath(connectionId)?.segmentBounds;
  }

  /// Get or compute segment bounds for a connection.
  /// Creates the path if not cached or if the cache is stale.
  List<Rect> getOrCreateSegmentBounds({
    required Connection connection,
    required Node sourceNode,
    required Node targetNode,
    required ConnectionStyle connectionStyle,
  }) {
    // Skip segment bounds creation for hidden connections
    if (!sourceNode.isVisible || !targetNode.isVisible) {
      return [];
    }

    final currentSourcePos = sourceNode.position.value;
    final currentTargetPos = targetNode.position.value;
    final currentSourceSize = sourceNode.size.value;
    final currentTargetSize = targetNode.size.value;
    final connectionTheme = theme.connectionTheme;
    final currentStartGap = connection.startGap ?? connectionTheme.startGap;
    final currentEndGap = connection.endGap ?? connectionTheme.endGap;

    // Get current port offsets for cache invalidation
    final sourcePort = sourceNode.findPort(connection.sourcePortId);
    final targetPort = targetNode.findPort(connection.targetPortId);
    final currentSourcePortOffset = sourcePort?.offset ?? Offset.zero;
    final currentTargetPortOffset = targetPort?.offset ?? Offset.zero;

    // Check if cache is valid (including node sizes and port offsets)
    final existing = _getCachedPath(connection.id);
    if (existing != null &&
        existing.sourcePosition == currentSourcePos &&
        existing.targetPosition == currentTargetPos &&
        existing.startGap == currentStartGap &&
        existing.endGap == currentEndGap &&
        existing.sourceNodeSize == currentSourceSize &&
        existing.targetNodeSize == currentTargetSize &&
        existing.sourcePortOffset == currentSourcePortOffset &&
        existing.targetPortOffset == currentTargetPortOffset) {
      return existing.segmentBounds;
    }

    // Create new path and get segments
    final newCachedPath = _createAndCachePath(
      connection: connection,
      sourceNode: sourceNode,
      targetNode: targetNode,
      sourcePosition: currentSourcePos,
      targetPosition: currentTargetPos,
      connectionStyle: connectionStyle,
      startGap: currentStartGap,
      endGap: currentEndGap,
    );

    return newCachedPath?.segmentBounds ?? [];
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
