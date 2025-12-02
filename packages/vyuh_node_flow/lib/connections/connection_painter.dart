import 'package:flutter/material.dart';

import '../graph/node_flow_theme.dart';
import '../nodes/node.dart';
import '../nodes/node_shape.dart';
import '../ports/port.dart';
import '../ports/port_theme.dart';
import '../shared/shapes/none_marker_shape.dart';
import 'connection.dart';
import 'connection_endpoint.dart';
import 'connection_path_cache.dart';
import 'connection_style_overrides.dart';
import 'connection_theme.dart';
import 'endpoint_painter.dart';
import 'styles/connection_path_calculator.dart';
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
    bool isAnimated = false,
    double? animationValue,
    ConnectionStyleOverrides? styleOverrides,
  }) {
    // Get effective style from connection instance or theme
    final effectiveStyle = connection.getEffectiveStyle(
      theme.connectionTheme.style,
    );

    // Get or create path using the cache with connection style
    final path = _pathCache.getOrCreatePath(
      connection: connection,
      sourceNode: sourceNode,
      targetNode: targetNode,
      connectionStyle: effectiveStyle, // Use effective style
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
      isAnimated: isAnimated,
      animationValue: animationValue,
      styleOverrides: styleOverrides,
    );

    // Draw debug visualization if enabled
    if (theme.debugMode) {
      _drawDebugVisualization(canvas, connection);
    }
  }

  /// Draw connection using path
  void _drawConnectionWithPath(
    Canvas canvas,
    Connection connection,
    Path connectionPath,
    Node sourceNode,
    Node targetNode, {
    bool isSelected = false,
    bool isAnimated = false,
    double? animationValue,
    ConnectionStyleOverrides? styleOverrides,
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
    Port? sourcePort;
    Port? targetPort;

    try {
      sourcePort = [
        ...sourceNode.inputPorts,
        ...sourceNode.outputPorts,
      ].firstWhere((port) => port.id == connection.sourcePortId);
    } catch (e) {
      return;
    }

    try {
      targetPort = [
        ...targetNode.inputPorts,
        ...targetNode.outputPorts,
      ].firstWhere((port) => port.id == connection.targetPortId);
    } catch (e) {
      return;
    }

    // Get shapes for the nodes (if shape builder is available)
    final sourceShape = nodeShape?.call(sourceNode);
    final targetShape = nodeShape?.call(targetNode);

    // Calculate endpoint positions for drawing
    // Use cascade: port.size if set, otherwise fallback to theme.size
    final sourcePortSize = sourcePort.size ?? portTheme.size;
    final targetPortSize = targetPort.size ?? portTheme.size;

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

    // Use 0 size for NoneMarkerShape to avoid creating gaps
    final startPointSize = effectiveStartPoint.shape is NoneMarkerShape
        ? 0.0
        : effectiveStartPoint.size;
    final endPointSize = effectiveEndPoint.shape is NoneMarkerShape
        ? 0.0
        : effectiveEndPoint.size;

    final source = EndpointPositionCalculator.calculatePortConnectionPoints(
      sourcePortPosition,
      sourcePort.position,
      startPointSize,
    );
    final target = EndpointPositionCalculator.calculatePortConnectionPoints(
      targetPortPosition,
      targetPort.position,
      endPointSize,
    );

    // Configure paint for the connection line using cached path
    // Apply style overrides if provided, otherwise use theme values
    final effectiveColor = isSelected
        ? (styleOverrides?.selectedColor ?? connectionTheme.selectedColor)
        : (styleOverrides?.color ?? connectionTheme.color);
    final effectiveStrokeWidth = isSelected
        ? (styleOverrides?.selectedStrokeWidth ??
              connectionTheme.selectedStrokeWidth)
        : (styleOverrides?.strokeWidth ?? connectionTheme.strokeWidth);

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

    // Draw endpoints
    _drawEndpoints(
      canvas,
      source: source,
      target: target,
      sourcePort: sourcePort,
      targetPort: targetPort,
      connectionTheme: connectionTheme,
      effectiveStartPoint: effectiveStartPoint,
      effectiveEndPoint: effectiveEndPoint,
      portTheme: portTheme,
      isTemporary: false,
      drawTargetEndpoint: true,
    );
  }

  // paintConnectionLabels method removed - labels are now rendered as positioned widgets

  void paintTemporaryConnection(
    Canvas canvas,
    Offset startPoint,
    Offset currentPoint, {
    Port? sourcePort,
    Port? targetPort,
    bool isReversed = false,
  }) {
    final connectionTheme = theme.temporaryConnectionTheme;

    // Calculate line endpoints and endpoint positions using same logic as permanent connections
    ({Offset endpointPos, Offset linePos})? source;
    ({Offset endpointPos, Offset linePos})? target;

    // Use 0 size for NoneMarkerShape to avoid creating gaps
    final tempStartPointSize =
        connectionTheme.startPoint.shape is NoneMarkerShape
        ? 0.0
        : connectionTheme.startPoint.size;
    final tempEndPointSize = connectionTheme.endPoint.shape is NoneMarkerShape
        ? 0.0
        : connectionTheme.endPoint.size;

    if (sourcePort != null) {
      source = EndpointPositionCalculator.calculatePortConnectionPoints(
        startPoint,
        sourcePort.position,
        tempStartPointSize,
      );
    } else {
      // When no source port, use startPoint directly
      source = (endpointPos: startPoint, linePos: startPoint);
    }

    if (targetPort != null) {
      target = EndpointPositionCalculator.calculatePortConnectionPoints(
        currentPoint,
        targetPort.position,
        tempEndPointSize,
      );
    } else {
      // When not snapped to a port, use currentPoint directly
      target = (endpointPos: currentPoint, linePos: currentPoint);
    }

    // Draw the connection and endpoints with temporary styling
    _drawConnectionWithEndpoints(
      canvas,
      null, // No connection object for temporary connections
      source: source,
      target: target,
      sourcePort: sourcePort,
      targetPort: targetPort,
      isSelected: false,
      isTemporary: true,
      drawTargetEndpoint: targetPort != null,
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
    bool isSelected = false,
    bool isTemporary = false,
    bool drawTargetEndpoint = true,
  }) {
    // Get theme components based on connection type
    final connectionTheme = isTemporary
        ? theme.temporaryConnectionTheme
        : theme.connectionTheme;
    final connectionStyle = connectionTheme.style;
    final portTheme = theme.portTheme;
    // Create connection path
    final connectionPath = ConnectionPathCalculator.createConnectionPath(
      style: connectionStyle,
      start: source.linePos,
      end: target.linePos,
      curvature: connectionTheme.bezierCurvature,
      sourcePort: sourcePort,
      targetPort: targetPort,
      cornerRadius: connectionTheme.cornerRadius,
      offset: connectionTheme.portExtension,
    );

    // Configure paint for the connection line
    final paint = Paint()
      ..color = isTemporary
          ? connectionTheme.color.withValues(alpha: 0.6)
          : (isSelected ? connectionTheme.selectedColor : connectionTheme.color)
      ..strokeWidth = isSelected && !isTemporary
          ? connectionTheme.selectedStrokeWidth
          : connectionTheme.strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

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

    // Draw endpoints
    _drawEndpoints(
      canvas,
      source: source,
      target: target,
      sourcePort: sourcePort,
      targetPort: targetPort,
      connectionTheme: connectionTheme,
      portTheme: portTheme,
      isTemporary: isTemporary,
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
    required PortTheme portTheme,
    bool isTemporary = false,
    bool drawTargetEndpoint = true,
  }) {
    // Configure paints for endpoints
    final endpointPaint = Paint()
      ..color = isTemporary ? portTheme.color : connectionTheme.color
      ..style = PaintingStyle.fill;

    final Paint? endpointBorderPaint = portTheme.borderWidth > 0
        ? (Paint()
            ..color = portTheme.borderColor
            ..strokeWidth = portTheme.borderWidth
            ..style = PaintingStyle.stroke)
        : null;

    // Use effective endpoint configurations or fallback to theme
    final startPoint = effectiveStartPoint ?? connectionTheme.startPoint;
    final endPoint = effectiveEndPoint ?? connectionTheme.endPoint;

    // Draw source endpoint (startPoint)
    final sourcePortPosition = sourcePort?.position ?? PortPosition.left;
    EndpointPainter.paint(
      canvas: canvas,
      position: source.endpointPos,
      size: Size.square(startPoint.size),
      shape: startPoint.shape,
      portPosition: sourcePortPosition,
      fillPaint: endpointPaint,
      borderPaint: endpointBorderPaint,
    );

    // Draw target endpoint (endPoint) if needed
    if (drawTargetEndpoint) {
      final targetPortPosition = targetPort?.position ?? PortPosition.right;
      EndpointPainter.paint(
        canvas: canvas,
        position: target.endpointPos,
        size: Size.square(endPoint.size),
        shape: endPoint.shape,
        portPosition: targetPortPosition,
        fillPaint: endpointPaint,
        borderPaint: endpointBorderPaint,
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

  /// Draw debug visualization for connection hit testing areas
  void _drawDebugVisualization(Canvas canvas, Connection connection) {
    // Get the hit test path for debugging
    final hitTestPath = _pathCache.getHitTestPath(connection.id);
    final originalPath = _pathCache.getOriginalPath(connection.id);

    if (hitTestPath == null || originalPath == null) return;

    // Debug paint for hit test area (semi-transparent overlay)
    final hitAreaPaint = Paint()
      ..color = Colors.red.withValues(alpha: 0.2)
      ..style = PaintingStyle.fill;

    // Debug paint for hit test border (visible outline)
    final hitBorderPaint = Paint()
      ..color = Colors.red.withValues(alpha: 0.6)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    // Debug paint for original path (green outline)
    final originalPathPaint = Paint()
      ..color = Colors.green.withValues(alpha: 0.8)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    // Draw hit test area (filled)
    canvas.drawPath(hitTestPath, hitAreaPaint);

    // Draw hit test border (outline)
    canvas.drawPath(hitTestPath, hitBorderPaint);

    // Draw original geometric path (for comparison)
    canvas.drawPath(originalPath, originalPathPaint);
  }
}
