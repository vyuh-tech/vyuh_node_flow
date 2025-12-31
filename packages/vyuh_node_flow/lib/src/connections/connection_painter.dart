import 'package:flutter/material.dart';

import '../editor/themes/node_flow_theme.dart';
import '../nodes/node.dart';
import '../nodes/node_shape.dart';
import '../ports/port.dart';
import '../shared/shapes/none_marker_shape.dart';
import 'connection.dart';
import 'connection_endpoint.dart';
import 'connection_path_cache.dart';
import 'connection_theme.dart';
import 'endpoint_painter.dart';
import 'styles/connection_style_base.dart';
import 'styles/endpoint_position_calculator.dart';

class ConnectionPainter {
  ConnectionPainter({required NodeFlowTheme theme, this.nodeShape})
    : _theme = theme,
      _pathCache = ConnectionPathCache(theme: theme, nodeShape: nodeShape);

  NodeFlowTheme _theme;

  NodeFlowTheme get theme => _theme;

  final ConnectionPathCache _pathCache;

  /// Gets the connection path cache
  /// Used by label calculator to leverage cached paths
  ConnectionPathCache get pathCache => _pathCache;

  /// Optional function to get the shape for a node.
  /// Used to calculate correct port positions for shaped nodes.
  NodeShape? Function(Node node)? nodeShape;

  /// Update the theme
  /// Cache invalidation is handled by the path cache itself
  void updateTheme(NodeFlowTheme newTheme) {
    _theme = newTheme;
    _pathCache.updateTheme(newTheme);
  }

  /// Update the node shape getter
  /// This allows updating how shapes are determined for nodes after painter creation
  void updateNodeShape(NodeShape? Function(Node node)? getter) {
    nodeShape = getter;
    _pathCache.nodeShape = getter;
    // Invalidate cache since shapes affect port positions
    _pathCache.invalidateAll();
  }

  void paintConnection(
    Canvas canvas,
    Connection connection,
    Node sourceNode, // Can be either Node or ObservableNode
    Node targetNode, { // Can be either Node or ObservableNode
    bool isSelected = false,
    double? animationValue,
    bool skipEndpoints = false,
    ConnectionStyle? overrideStyle,
  }) {
    // Get effective path style:
    // 1. Use overrideStyle from builder (if provided)
    // 2. Otherwise use connection.style or theme default
    final effectiveStyle =
        overrideStyle ??
        connection.getEffectiveStyle(theme.connectionTheme.style);

    // Get or create path using the cache with connection style
    final path = _pathCache.getOrCreatePath(
      connection: connection,
      sourceNode: sourceNode,
      targetNode: targetNode,
      connectionStyle: effectiveStyle,
    );

    if (path == null) {
      return; // Failed to create path
    }

    // Draw the connection using the cached path
    _drawConnectionWithPath(
      canvas,
      connection,
      path,
      sourceNode,
      targetNode,
      isSelected: isSelected,
      animationValue: animationValue,
      skipEndpoints: skipEndpoints,
    );
  }

  /// Draw connection using path
  void _drawConnectionWithPath(
    Canvas canvas,
    Connection connection,
    Path connectionPath,
    Node sourceNode,
    Node targetNode, {
    bool isSelected = false,
    double? animationValue,
    bool skipEndpoints = false,
  }) {
    final connectionTheme = theme.connectionTheme;
    final portTheme = theme.portTheme;

    // Get effective configurations from connection instance or theme
    final effectiveStartPoint = connection.getEffectiveStartPoint(
      connectionTheme.startPoint,
    );
    final effectiveEndPoint = connection.getEffectiveEndPoint(
      connectionTheme.endPoint,
    );

    // Get ports for endpoint drawing
    // Use Node.findPort which safely returns null if not found
    final sourcePort = sourceNode.findPort(connection.sourcePortId);
    final targetPort = targetNode.findPort(connection.targetPortId);

    // Return if either port is not found - connection may be stale or ports
    // haven't been set up yet (e.g., during widget initialization)
    if (sourcePort == null || targetPort == null) {
      return;
    }

    // Get shapes for the nodes (if shape builder is available)
    final sourceShape = nodeShape?.call(sourceNode);
    final targetShape = nodeShape?.call(targetNode);

    // Calculate endpoint positions for drawing
    // Use cascade: port.size if set, otherwise fallback to theme.size
    final sourcePortSize = sourcePort.size ?? portTheme.size;
    final targetPortSize = targetPort.size ?? portTheme.size;

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

    // Use 0 size for NoneMarkerShape to avoid creating gaps
    final startPointSize = effectiveStartPoint.shape is NoneMarkerShape
        ? Size.zero
        : effectiveStartPoint.size;
    final endPointSize = effectiveEndPoint.shape is NoneMarkerShape
        ? Size.zero
        : effectiveEndPoint.size;

    final source = EndpointPositionCalculator.calculatePortConnectionPoints(
      sourcePortPosition,
      sourcePort.position,
      startPointSize,
      gap: connection.startGap ?? connectionTheme.startGap,
    );
    final target = EndpointPositionCalculator.calculatePortConnectionPoints(
      targetConnectionPoint,
      targetPort.position,
      endPointSize,
      gap: connection.endGap ?? connectionTheme.endGap,
    );

    // Configure paint for the connection line using cached path
    // Use connection's effective color/strokeWidth which cascade:
    // 1. connection instance properties (if set)
    // 2. theme defaults
    final effectiveColor = connection.getEffectiveColor(
      connectionTheme.color,
      connectionTheme.selectedColor,
    );
    final effectiveStrokeWidth = connection.getEffectiveStrokeWidth(
      connectionTheme.strokeWidth,
      connectionTheme.selectedStrokeWidth,
    );

    final paint = Paint()
      ..color = effectiveColor
      ..strokeWidth = effectiveStrokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    // Get effective animation effect (from connection or theme fallback)
    final effectiveAnimationEffect = connection.getEffectiveAnimationEffect(
      connectionTheme.animationEffect,
    );

    // Check if connection has an animation effect
    if (effectiveAnimationEffect != null && animationValue != null) {
      // Use animation effect to render the connection
      effectiveAnimationEffect.paint(
        canvas,
        connectionPath,
        paint,
        animationValue,
      );
    } else {
      // Apply dash pattern if specified
      Path? dashPath;
      if (connectionTheme.dashPattern != null) {
        dashPath = _createDashedPath(
          connectionPath,
          connectionTheme.dashPattern!,
        );
      }

      // Draw connection line using path (static rendering)
      final pathToDraw = dashPath ?? connectionPath;
      canvas.drawPath(pathToDraw, paint);
    }

    // Draw endpoints (if not skipped by LOD)
    if (!skipEndpoints) {
      _drawEndpoints(
        canvas,
        source: source,
        target: target,
        sourcePort: sourcePort,
        targetPort: targetPort,
        connectionTheme: connectionTheme,
        effectiveStartPoint: effectiveStartPoint,
        effectiveEndPoint: effectiveEndPoint,
        drawTargetEndpoint: true,
      );
    }
  }

  // paintConnectionLabels method removed - labels are now rendered as positioned widgets

  void paintTemporaryConnection(
    Canvas canvas,
    Offset startPoint,
    Offset currentPoint, {
    Port? sourcePort,
    Port? targetPort,
    Rect? sourceNodeBounds,
    Rect? targetNodeBounds,
    double? animationValue,
  }) {
    final connectionTheme = theme.temporaryConnectionTheme;

    // Always use the full connection style machinery for consistent appearance
    // Calculate source endpoint positions (from the port we started dragging from)
    final ({Offset endpointPos, Offset linePos}) source;
    if (sourcePort != null) {
      // Use proper endpoint calculation to account for endpoint marker size and gap
      final startEndpoint = connectionTheme.startPoint;
      final startPointSize = startEndpoint.shape is NoneMarkerShape
          ? Size.zero
          : startEndpoint.size;
      source = EndpointPositionCalculator.calculatePortConnectionPoints(
        startPoint,
        sourcePort.position,
        startPointSize,
        gap: connectionTheme.startGap,
      );
    } else {
      source = (endpointPos: startPoint, linePos: startPoint);
    }

    // Calculate target endpoint positions (where we're dragging to)
    final ({Offset endpointPos, Offset linePos}) target;
    if (targetPort != null) {
      // Use proper endpoint calculation to account for endpoint marker size and gap
      // This ensures the connection snaps to the correct attachment point
      final endEndpoint = connectionTheme.endPoint;
      final endPointSize = endEndpoint.shape is NoneMarkerShape
          ? Size.zero
          : endEndpoint.size;
      target = EndpointPositionCalculator.calculatePortConnectionPoints(
        currentPoint,
        targetPort.position,
        endPointSize,
        gap: connectionTheme.endGap,
      );
    } else {
      target = (endpointPos: currentPoint, linePos: currentPoint);
    }

    _drawConnectionWithEndpoints(
      canvas,
      null,
      source: source,
      target: target,
      sourcePort: sourcePort,
      targetPort: targetPort,
      sourceNodeBounds: sourceNodeBounds,
      targetNodeBounds: targetNodeBounds,
      isSelected: false,
      isTemporary: true,
      drawTargetEndpoint: targetPort != null,
      animationValue: animationValue,
    );
  }

  /// Creates a dashed path from a solid path using the given dash pattern
  Path _createDashedPath(Path source, List<double> dashPattern) {
    if (dashPattern.isEmpty) return source;

    final dashedPath = Path();
    final pathMetrics = source.computeMetrics();

    for (final pathMetric in pathMetrics) {
      double distance = 0.0;
      bool isDash = true;
      int dashIndex = 0;

      while (distance < pathMetric.length) {
        final dashLength = dashPattern[dashIndex % dashPattern.length];
        final nextDistance = (distance + dashLength).clamp(
          0.0,
          pathMetric.length,
        );

        if (isDash) {
          final extractedPath = pathMetric.extractPath(distance, nextDistance);
          dashedPath.addPath(extractedPath, Offset.zero);
        }

        distance = nextDistance;
        isDash = !isDash;
        dashIndex++;
      }
    }

    return dashedPath;
  }

  /// Draws a connection with its endpoints using shared logic
  void _drawConnectionWithEndpoints(
    Canvas canvas,
    Connection? connection, {
    required ({Offset endpointPos, Offset linePos}) source,
    required ({Offset endpointPos, Offset linePos}) target,
    required Port? sourcePort,
    required Port? targetPort,
    Rect? sourceNodeBounds,
    Rect? targetNodeBounds,
    bool isSelected = false,
    bool isTemporary = false,
    bool drawTargetEndpoint = true,
    double? animationValue,
  }) {
    // Get theme components based on connection type
    final connectionTheme = isTemporary
        ? theme.temporaryConnectionTheme
        : theme.connectionTheme;
    final connectionStyle = connectionTheme.style;

    // Create connection path parameters and generate path from segments
    // For temporary connections, sourceOffset/targetOffset computed properties
    // return 0 when no port exists (mouse position), so extensions only apply
    // to the port side, not the mouse side
    final pathParams = ConnectionPathParameters(
      start: source.linePos,
      end: target.linePos,
      curvature: connectionTheme.bezierCurvature,
      sourcePort: sourcePort,
      targetPort: targetPort,
      cornerRadius: connectionTheme.cornerRadius,
      offset: connectionTheme.portExtension,
      backEdgeGap: connectionTheme.backEdgeGap,
      sourceNodeBounds: sourceNodeBounds,
      targetNodeBounds: targetNodeBounds,
    );
    final segmentResult = connectionStyle.createSegments(pathParams);
    final connectionPath = connectionStyle.buildPath(
      segmentResult.start,
      segmentResult.segments,
    );

    // Configure paint for the connection line
    final paint = Paint()
      ..color = isSelected
          ? connectionTheme.selectedColor
          : connectionTheme.color
      ..strokeWidth = isSelected
          ? connectionTheme.selectedStrokeWidth
          : connectionTheme.strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    // Get animation effect from theme (for temporary connections, there's no connection object)
    final animationEffect = connectionTheme.animationEffect;

    // Check if we have an animation effect and animation value
    if (animationEffect != null && animationValue != null) {
      // Use animation effect to render the connection
      animationEffect.paint(canvas, connectionPath, paint, animationValue);
    } else {
      // Apply dash pattern if specified
      Path? dashPath;
      if (connectionTheme.dashPattern != null) {
        dashPath = _createDashedPath(
          connectionPath,
          connectionTheme.dashPattern!,
        );
      }

      // Draw connection line (dashed or solid)
      final pathToDraw = dashPath ?? connectionPath;
      canvas.drawPath(pathToDraw, paint);
    }

    // Draw endpoints
    _drawEndpoints(
      canvas,
      source: source,
      target: target,
      sourcePort: sourcePort,
      targetPort: targetPort,
      connectionTheme: connectionTheme,
      drawTargetEndpoint: drawTargetEndpoint,
    );

    // Labels are now rendered as separate positioned widgets
  }

  /// Draws the endpoint capsules for a connection
  void _drawEndpoints(
    Canvas canvas, {
    required ({Offset endpointPos, Offset linePos}) source,
    required ({Offset endpointPos, Offset linePos}) target,
    required Port? sourcePort,
    required Port? targetPort,
    required ConnectionTheme connectionTheme,
    ConnectionEndPoint? effectiveStartPoint,
    ConnectionEndPoint? effectiveEndPoint,
    bool drawTargetEndpoint = true,
  }) {
    // Use effective endpoint configurations or fallback to theme
    final startPoint = effectiveStartPoint ?? connectionTheme.startPoint;
    final endPoint = effectiveEndPoint ?? connectionTheme.endPoint;

    // Default colors from ConnectionTheme (used as fallback)
    final defaultFillColor = connectionTheme.endpointColor;
    final defaultBorderColor = connectionTheme.endpointBorderColor;
    final defaultBorderWidth = connectionTheme.endpointBorderWidth;

    // Draw source endpoint (startPoint)
    final sourcePortPosition = sourcePort?.position ?? PortPosition.left;
    final startFillPaint = Paint()
      ..color = startPoint.color ?? defaultFillColor
      ..style = PaintingStyle.fill;
    final startBorderWidth = startPoint.borderWidth ?? defaultBorderWidth;
    final startBorderColor = startPoint.borderColor ?? defaultBorderColor;
    final Paint? startBorderPaint = startBorderWidth > 0
        ? (Paint()
            ..color = startBorderColor
            ..strokeWidth = startBorderWidth
            ..style = PaintingStyle.stroke)
        : null;

    EndpointPainter.paint(
      canvas: canvas,
      position: source.endpointPos,
      size: startPoint.size,
      shape: startPoint.shape,
      portPosition: sourcePortPosition,
      fillPaint: startFillPaint,
      borderPaint: startBorderPaint,
    );

    // Draw target endpoint (endPoint) if needed
    if (drawTargetEndpoint) {
      final targetConnectionPoint = targetPort?.position ?? PortPosition.right;
      final endFillPaint = Paint()
        ..color = endPoint.color ?? defaultFillColor
        ..style = PaintingStyle.fill;
      final endBorderWidth = endPoint.borderWidth ?? defaultBorderWidth;
      final endBorderColor = endPoint.borderColor ?? defaultBorderColor;
      final Paint? endBorderPaint = endBorderWidth > 0
          ? (Paint()
              ..color = endBorderColor
              ..strokeWidth = endBorderWidth
              ..style = PaintingStyle.stroke)
          : null;

      EndpointPainter.paint(
        canvas: canvas,
        position: target.endpointPos,
        size: endPoint.size,
        shape: endPoint.shape,
        portPosition: targetConnectionPoint,
        fillPaint: endFillPaint,
        borderPaint: endBorderPaint,
      );
    }
  }

  // Label drawing methods removed - labels are now rendered as positioned widgets

  /// Test if a point is near a connection path using cached paths for performance
  /// Returns true if the point is within the specified tolerance distance from the path
  bool hitTestConnection({
    required Connection connection,
    required Node sourceNode,
    required Node targetNode,
    required Offset testPoint,
    double? tolerance,
  }) {
    // Delegate to the cache's hit testing logic
    return _pathCache.hitTest(
      connection: connection,
      sourceNode: sourceNode,
      targetNode: targetNode,
      testPoint: testPoint,
      tolerance: tolerance,
    );
  }

  /// Dispose and clear all cached paths
  void dispose() {
    _pathCache.dispose();
  }

  /// Remove cached path when connection is deleted
  void removeConnectionFromCache(String connectionId) {
    _pathCache.removeConnection(connectionId);
  }

  /// Clear all cached paths (useful for bulk operations or theme changes)
  void clearAllCachedPaths() {
    _pathCache.clearAll();
  }

  /// Check if a connection has a cached path
  bool hasConnectionCached(String connectionId) {
    return _pathCache.hasConnection(connectionId);
  }

  /// Get cache statistics for debugging
  Map<String, dynamic> getCacheStats() {
    return _pathCache.getStats();
  }
}
