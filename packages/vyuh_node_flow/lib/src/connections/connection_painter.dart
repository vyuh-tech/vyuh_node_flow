import 'dart:typed_data';
import 'dart:ui' show PointMode;

import 'package:flutter/material.dart';

import '../editor/themes/node_flow_theme.dart';
import '../nodes/node.dart';
import '../nodes/node_shape.dart';
import '../ports/port.dart';
import '../shared/shapes/none_marker_shape.dart';
import 'connection.dart';
import 'connection_endpoint.dart';
import 'effects/connection_effect.dart';
import 'connection_path_cache.dart';
import 'connection_theme.dart';
import 'endpoint_painter.dart';
import 'styles/connection_style_base.dart';
import 'styles/endpoint_position_calculator.dart';

/// Immutable endpoint state used by the permanent connection paint path.
@immutable
class ConnectionEndpointRenderEntry {
  const ConnectionEndpointRenderEntry({
    required this.position,
    required this.portPosition,
    required this.endpoint,
    required this.fillColor,
    required this.borderColor,
    required this.borderWidth,
  });

  final Offset position;
  final PortPosition portPosition;
  final ConnectionEndPoint endpoint;
  final Color fillColor;
  final Color borderColor;
  final double borderWidth;
}

/// Immutable, fully resolved state for drawing one permanent connection.
///
/// No graph objects are retained. Paths, endpoint positions, selection colors,
/// stroke widths, dash geometry, and animation effects are all resolved before
/// Flutter enters the paint phase.
@immutable
class ConnectionRenderEntry {
  const ConnectionRenderEntry({
    required this.id,
    required this.path,
    required this.staticPath,
    required this.color,
    required this.strokeWidth,
    required this.animationEffect,
    this.sourceEndpoint,
    this.targetEndpoint,
  });

  final String id;
  final Path path;
  final Path staticPath;
  final Color color;
  final double strokeWidth;
  final ConnectionEffect? animationEffect;
  final ConnectionEndpointRenderEntry? sourceEndpoint;
  final ConnectionEndpointRenderEntry? targetEndpoint;
}

/// Immutable geometry shared by overview connections with the same paint.
///
/// Solid overview edges use packed coordinates with [Canvas.drawRawPoints].
/// Dashed edges retain a bounded path fallback. Batches are spatially tiled and
/// contour-capped so neither construction nor rasterization grows into one
/// graph-spanning operation.
@immutable
class ConnectionRenderBatch {
  const ConnectionRenderBatch({
    required this.path,
    required this.linePoints,
    required this.isDashed,
    required this.color,
    required this.strokeWidth,
    required this.edgeCount,
  });

  final Path path;
  final Float32List linePoints;
  final bool isDashed;
  final Color color;
  final double strokeWidth;
  final int edgeCount;
}

/// Immutable batch of permanent connection render entries.
@immutable
class ConnectionRenderSnapshot {
  ConnectionRenderSnapshot({
    required this.revision,
    required List<ConnectionRenderEntry> entries,
    List<ConnectionRenderBatch> batches = const [],
  }) : entries = List.unmodifiable(entries),
       batches = List.unmodifiable(batches);

  /// Stable render-input identity used for an O(1) repaint decision.
  final int revision;
  final List<ConnectionRenderEntry> entries;
  final List<ConnectionRenderBatch> batches;

  bool get isEmpty => entries.isEmpty && batches.isEmpty;
  bool get isNotEmpty => !isEmpty;
}

/// Paints connections on a canvas.
///
/// This is the UI layer - it only handles painting.
/// The [ConnectionPathCache] (data layer) handles geometry and queries.
class ConnectionPainter {
  /// Keeps overview batches small enough for efficient construction and raster.
  @visibleForTesting
  static const int overviewBatchMaxContours = 32;

  static const double _overviewBatchTileSize = 512;

  ConnectionPainter({
    required NodeFlowTheme theme,
    required ConnectionPathCache pathCache,
    this.nodeShape,
  }) : _theme = theme,
       _pathCache = pathCache;

  NodeFlowTheme _theme;

  NodeFlowTheme get theme => _theme;

  final ConnectionPathCache _pathCache;

  // Path is the weak key, so cached dash output disappears with its source
  // path instead of retaining stale connection geometry indefinitely.
  final Expando<_DashedPathCacheEntry> _staticDashedPathCache =
      Expando<_DashedPathCacheEntry>('static dashed connection paths');
  int _dashedPathCacheBuilds = 0;
  int _dashedPathCacheHits = 0;
  int _overviewBatchBuilds = 0;
  _RetainedOverviewScene? _retainedOverviewScene;

  /// Number of static dashed paths built by this painter.
  @visibleForTesting
  int get debugDashedPathCacheBuilds => _dashedPathCacheBuilds;

  /// Number of static dashed-path cache hits served by this painter.
  @visibleForTesting
  int get debugDashedPathCacheHits => _dashedPathCacheHits;

  /// Number of bounded overview render batches constructed by this painter.
  @visibleForTesting
  int get debugOverviewBatchBuilds => _overviewBatchBuilds;

  /// Gets the connection path cache (data layer)
  ConnectionPathCache get pathCache => _pathCache;

  /// Optional function to get the shape for a node.
  /// Used to calculate correct port positions for shaped nodes.
  NodeShape? Function(Node node)? nodeShape;

  /// Builds an immutable render snapshot outside the paint phase.
  ///
  /// This is the only permanent-connection path that reads nodes, ports, or
  /// reactive connection properties. [paintRenderEntry] consumes only the
  /// returned immutable values, so animation ticks never revisit graph state.
  ConnectionRenderSnapshot buildRenderSnapshot<T, C>({
    required Iterable<Connection<C>> connections,
    required Node<T>? Function(String nodeId) nodeForId,
    required Set<String> selectedIds,
    required bool skipEndpoints,
    bool simplifyPaths = false,
    bool retainOverviewBatches = false,
    ConnectionStyleBuilder<T, C>? connectionStyleBuilder,
  }) {
    final entries = <ConnectionRenderEntry>[];
    final overviewEdges = <_OverviewEdgeRenderData>[];
    final connectionTheme = theme.connectionTheme;
    final portTheme = theme.portTheme;
    final dashPattern = connectionTheme.dashPattern;
    var revision = Object.hash(
      simplifyPaths,
      simplifyPaths || skipEndpoints,
      Object.hashAll(dashPattern ?? const <double>[]),
    );

    for (final connection in connections) {
      if (!connection.visible) continue;

      final sourceNode = nodeForId(connection.sourceNodeId);
      final targetNode = nodeForId(connection.targetNodeId);
      if (sourceNode == null || targetNode == null) continue;
      if (!sourceNode.isVisible || !targetNode.isVisible) continue;

      final sourcePort = sourceNode.findPort(connection.sourcePortId);
      final targetPort = targetNode.findPort(connection.targetPortId);
      if (sourcePort == null || targetPort == null) continue;

      ConnectionStyle? effectiveStyle;
      if (!simplifyPaths) {
        final overrideStyle = connectionStyleBuilder?.call(
          connection,
          sourceNode,
          targetNode,
        );
        effectiveStyle =
            overrideStyle ??
            connection.getEffectiveStyle(connectionTheme.style);
      }
      final isSelected = selectedIds.contains(connection.id);
      final color = isSelected
          ? connection.selectedColor ?? connectionTheme.selectedColor
          : connection.color ?? connectionTheme.color;
      final strokeWidth = isSelected
          ? connection.selectedStrokeWidth ??
                connectionTheme.selectedStrokeWidth
          : connection.strokeWidth ?? connectionTheme.strokeWidth;
      final animationEffect = connection.getEffectiveAnimationEffect(
        connectionTheme.animationEffect,
      );

      Offset? sourceConnectionPoint;
      Offset? targetConnectionPoint;
      if (simplifyPaths || !skipEndpoints) {
        final sourceShape = nodeShape?.call(sourceNode);
        final targetShape = nodeShape?.call(targetNode);
        sourceConnectionPoint = sourceNode.getConnectionPoint(
          connection.sourcePortId,
          portSize: sourcePort.size ?? portTheme.size,
          shape: sourceShape,
        );
        targetConnectionPoint = targetNode.getConnectionPoint(
          connection.targetPortId,
          portSize: targetPort.size ?? portTheme.size,
          shape: targetShape,
        );
      }

      final canBatchOverview =
          simplifyPaths && !isSelected && animationEffect == null;
      Path? path;
      if (simplifyPaths && !canBatchOverview) {
        path = Path()
          ..moveTo(sourceConnectionPoint!.dx, sourceConnectionPoint.dy)
          ..lineTo(targetConnectionPoint!.dx, targetConnectionPoint.dy);
      } else if (!simplifyPaths) {
        final cachedPath = _pathCache.getOrCreatePath(
          connection: connection,
          sourceNode: sourceNode,
          targetNode: targetNode,
          connectionStyle: effectiveStyle!,
        );
        if (cachedPath == null) continue;
        path = cachedPath;
      }

      ConnectionEndpointRenderEntry? sourceEndpoint;
      ConnectionEndpointRenderEntry? targetEndpoint;
      if (!simplifyPaths && !skipEndpoints) {
        final effectiveStartPoint = connection.getEffectiveStartPoint(
          connectionTheme.startPoint,
        );
        final effectiveEndPoint = connection.getEffectiveEndPoint(
          connectionTheme.endPoint,
        );
        final startPointSize = effectiveStartPoint.shape is NoneMarkerShape
            ? Size.zero
            : effectiveStartPoint.size;
        final endPointSize = effectiveEndPoint.shape is NoneMarkerShape
            ? Size.zero
            : effectiveEndPoint.size;
        final source = EndpointPositionCalculator.calculatePortConnectionPoints(
          sourceConnectionPoint!,
          sourcePort.position,
          startPointSize,
          gap: connection.startGap ?? connectionTheme.startGap,
        );
        final target = EndpointPositionCalculator.calculatePortConnectionPoints(
          targetConnectionPoint!,
          targetPort.position,
          endPointSize,
          gap: connection.endGap ?? connectionTheme.endGap,
        );

        sourceEndpoint = _resolveEndpointRenderEntry(
          position: source.endpointPos,
          portPosition: sourcePort.position,
          endpoint: effectiveStartPoint,
          connectionTheme: connectionTheme,
        );
        targetEndpoint = _resolveEndpointRenderEntry(
          position: target.endpointPos,
          portPosition: targetPort.position,
          endpoint: effectiveEndPoint,
          connectionTheme: connectionTheme,
        );
      }

      revision = Object.hash(
        revision,
        Object.hashAll([
          connection.id,
          isSelected,
          color,
          strokeWidth,
          animationEffect,
          simplifyPaths ? sourceConnectionPoint : identityHashCode(path!),
          simplifyPaths ? targetConnectionPoint : effectiveStyle!.id,
          sourceEndpoint?.position,
          sourceEndpoint?.portPosition,
          sourceEndpoint?.endpoint,
          sourceEndpoint?.fillColor,
          sourceEndpoint?.borderColor,
          sourceEndpoint?.borderWidth,
          targetEndpoint?.position,
          targetEndpoint?.portPosition,
          targetEndpoint?.endpoint,
          targetEndpoint?.fillColor,
          targetEndpoint?.borderColor,
          targetEndpoint?.borderWidth,
        ]),
      );

      // Selected and animated edges keep independent entries so their visual
      // state and animation semantics remain isolated. The common overview
      // case is batched by resolved paint into a multi-contour path.
      if (canBatchOverview) {
        final source = sourceConnectionPoint!;
        final target = targetConnectionPoint!;
        final midpoint = Offset(
          (source.dx + target.dx) / 2,
          (source.dy + target.dy) / 2,
        );
        overviewEdges.add(
          _OverviewEdgeRenderData(
            id: connection.id,
            source: source,
            target: target,
            color: color,
            strokeWidth: strokeWidth,
            tileX: (midpoint.dx / _overviewBatchTileSize).floor(),
            tileY: (midpoint.dy / _overviewBatchTileSize).floor(),
          ),
        );
        continue;
      }

      final staticPath = dashPattern == null
          ? path!
          : _createDashedPath(path!, dashPattern);

      entries.add(
        ConnectionRenderEntry(
          id: connection.id,
          path: path,
          staticPath: staticPath,
          color: color,
          strokeWidth: strokeWidth,
          animationEffect: animationEffect,
          sourceEndpoint: sourceEndpoint,
          targetEndpoint: targetEndpoint,
        ),
      );
    }

    final rawBatches = retainOverviewBatches && simplifyPaths
        ? (_retainedOverviewScene ??= _RetainedOverviewScene(
            onBatchBuild: _recordOverviewBatchBuild,
          )).update(overviewEdges)
        : _RetainedOverviewScene(
            onBatchBuild: _recordOverviewBatchBuild,
          ).update(overviewEdges);
    final batches = dashPattern == null
        ? rawBatches
        : [
            for (final batch in rawBatches)
              ConnectionRenderBatch(
                path: _createDashedPath(batch.path, dashPattern),
                linePoints: batch.linePoints,
                isDashed: true,
                color: batch.color,
                strokeWidth: batch.strokeWidth,
                edgeCount: batch.edgeCount,
              ),
          ];

    return ConnectionRenderSnapshot(
      revision: Object.hash(revision, entries.length, batches.length),
      entries: entries,
      batches: batches,
    );
  }

  void _recordOverviewBatchBuild() => _overviewBatchBuilds++;

  /// Paints one previously resolved overview batch.
  void paintRenderBatch(Canvas canvas, ConnectionRenderBatch batch) {
    final paint = Paint()
      ..color = batch.color
      ..strokeWidth = batch.strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    if (batch.isDashed) {
      canvas.drawPath(batch.path, paint);
    } else {
      canvas.drawRawPoints(PointMode.lines, batch.linePoints, paint);
    }
  }

  /// Paints one previously resolved immutable permanent-connection entry.
  void paintRenderEntry(
    Canvas canvas,
    ConnectionRenderEntry entry, {
    double? animationValue,
  }) {
    final paint = Paint()
      ..color = entry.color
      ..strokeWidth = entry.strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    final effect = entry.animationEffect;
    if (effect != null && animationValue != null) {
      effect.paint(canvas, entry.path, paint, animationValue);
    } else {
      canvas.drawPath(entry.staticPath, paint);
    }

    final sourceEndpoint = entry.sourceEndpoint;
    if (sourceEndpoint != null) {
      _paintEndpointRenderEntry(canvas, sourceEndpoint);
    }
    final targetEndpoint = entry.targetEndpoint;
    if (targetEndpoint != null) {
      _paintEndpointRenderEntry(canvas, targetEndpoint);
    }
  }

  ConnectionEndpointRenderEntry _resolveEndpointRenderEntry({
    required Offset position,
    required PortPosition portPosition,
    required ConnectionEndPoint endpoint,
    required ConnectionTheme connectionTheme,
  }) {
    return ConnectionEndpointRenderEntry(
      position: position,
      portPosition: portPosition,
      endpoint: endpoint,
      fillColor: endpoint.color ?? connectionTheme.endpointColor,
      borderColor: endpoint.borderColor ?? connectionTheme.endpointBorderColor,
      borderWidth: endpoint.borderWidth ?? connectionTheme.endpointBorderWidth,
    );
  }

  void _paintEndpointRenderEntry(
    Canvas canvas,
    ConnectionEndpointRenderEntry entry,
  ) {
    final fillPaint = Paint()
      ..color = entry.fillColor
      ..style = PaintingStyle.fill;
    final borderPaint = entry.borderWidth > 0
        ? (Paint()
            ..color = entry.borderColor
            ..strokeWidth = entry.borderWidth
            ..style = PaintingStyle.stroke)
        : null;
    EndpointPainter.paint(
      canvas: canvas,
      position: entry.position,
      size: entry.endpoint.size,
      shape: entry.endpoint.shape,
      portPosition: entry.portPosition,
      fillPaint: fillPaint,
      borderPaint: borderPaint,
    );
  }

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

    // SIMPLIFIED ROUTING: Always use PHYSICAL port position.
    // Bidi ports use the same direction as regular ports.
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

    // Calculate endpoint positions using PHYSICAL port positions.
    // Endpoints are always at the port's actual location on the node edge.
    // Path routing handles curving the line naturally between endpoints.
    final source = EndpointPositionCalculator.calculatePortConnectionPoints(
      sourcePortPosition,
      sourcePort.position, // Physical position
      startPointSize,
      gap: connection.startGap ?? connectionTheme.startGap,
    );

    final target = EndpointPositionCalculator.calculatePortConnectionPoints(
      targetConnectionPoint,
      targetPort.position, // Physical position
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
    // Use physical port positions for endpoint orientation - the path handles routing
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

    // SIMPLIFIED ROUTING: Always use physical port positions.
    // Bidi ports are just ports that CAN be source or target - they don't change direction.
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
        sourcePort.position, // Always use physical position
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
        targetPort.position, // Always use physical position
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

    final cached = _staticDashedPathCache[source];
    if (cached != null && cached.matches(dashPattern)) {
      _dashedPathCacheHits++;
      return cached.path;
    }

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

    _staticDashedPathCache[source] = _DashedPathCacheEntry(
      pattern: List.unmodifiable(dashPattern),
      path: dashedPath,
    );
    _dashedPathCacheBuilds++;
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

    // Draw endpoints using physical port positions
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
  ///
  /// Endpoints always use physical port positions for orientation.
  /// The "bidirectional" aspect of ports means they CAN be source or target,
  /// not that they change direction dynamically.
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

    // Draw source endpoint (startPoint) - always use physical port position
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

    // Draw target endpoint (endPoint) if needed - always use physical port position
    if (drawTargetEndpoint) {
      final targetPortPosition = targetPort?.position ?? PortPosition.right;
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
        portPosition: targetPortPosition,
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
    _retainedOverviewScene = null;
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

class _DashedPathCacheEntry {
  const _DashedPathCacheEntry({required this.pattern, required this.path});

  final List<double> pattern;
  final Path path;

  bool matches(List<double> otherPattern) {
    if (pattern.length != otherPattern.length) return false;

    for (var index = 0; index < pattern.length; index++) {
      if (pattern[index] != otherPattern[index]) return false;
    }
    return true;
  }
}

typedef _OverviewBatchKey = ({
  Color color,
  double strokeWidth,
  int tileX,
  int tileY,
});

@immutable
class _OverviewEdgeRenderData {
  const _OverviewEdgeRenderData({
    required this.id,
    required this.source,
    required this.target,
    required this.color,
    required this.strokeWidth,
    required this.tileX,
    required this.tileY,
  });

  final String id;
  final Offset source;
  final Offset target;
  final Color color;
  final double strokeWidth;
  final int tileX;
  final int tileY;

  _OverviewBatchKey get batchKey =>
      (color: color, strokeWidth: strokeWidth, tileX: tileX, tileY: tileY);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is _OverviewEdgeRenderData &&
          other.id == id &&
          other.source == source &&
          other.target == target &&
          other.color == color &&
          other.strokeWidth == strokeWidth &&
          other.tileX == tileX &&
          other.tileY == tileY;

  @override
  int get hashCode =>
      Object.hash(id, source, target, color, strokeWidth, tileX, tileY);
}

class _RetainedOverviewScene {
  _RetainedOverviewScene({required this.onBatchBuild});

  final VoidCallback onBatchBuild;
  final Map<String, _RetainedOverviewEdge> _edges = {};
  final Map<_OverviewBatchKey, List<_RetainedOverviewBatch>> _batchesByKey = {};
  final List<_RetainedOverviewBatch> _orderedBatches = [];

  List<ConnectionRenderBatch> update(List<_OverviewEdgeRenderData> nextEdges) {
    final retainedIds = <String>{};
    for (final data in nextEdges) {
      retainedIds.add(data.id);
      final previous = _edges[data.id];
      if (previous?.data == data) continue;

      if (previous != null) _remove(previous);
      _add(data);
    }

    final removedIds = [
      for (final id in _edges.keys)
        if (!retainedIds.contains(id)) id,
    ];
    for (final id in removedIds) {
      _remove(_edges[id]!);
    }

    return [for (final batch in _orderedBatches) batch.render()];
  }

  void _add(_OverviewEdgeRenderData data) {
    final candidates = _batchesByKey.putIfAbsent(data.batchKey, () => []);
    var batch = candidates.firstWhere(
      (candidate) => !candidate.isFull,
      orElse: () {
        final created = _RetainedOverviewBatch(
          key: data.batchKey,
          onBuild: onBatchBuild,
        );
        candidates.add(created);
        _orderedBatches.add(created);
        return created;
      },
    );
    batch.add(data);
    _edges[data.id] = _RetainedOverviewEdge(data: data, batch: batch);
  }

  void _remove(_RetainedOverviewEdge edge) {
    _edges.remove(edge.data.id);
    final batch = edge.batch;
    batch.remove(edge.data.id);
    if (!batch.isEmpty) return;

    _orderedBatches.remove(batch);
    final candidates = _batchesByKey[batch.key]!..remove(batch);
    if (candidates.isEmpty) _batchesByKey.remove(batch.key);
  }
}

class _RetainedOverviewEdge {
  const _RetainedOverviewEdge({required this.data, required this.batch});

  final _OverviewEdgeRenderData data;
  final _RetainedOverviewBatch batch;
}

class _RetainedOverviewBatch {
  _RetainedOverviewBatch({required this.key, required this.onBuild});

  final _OverviewBatchKey key;
  final VoidCallback onBuild;
  final Map<String, _OverviewEdgeRenderData> _edges = {};
  ConnectionRenderBatch? _renderBatch;

  bool get isEmpty => _edges.isEmpty;
  bool get isFull =>
      _edges.length >= ConnectionPainter.overviewBatchMaxContours;

  void add(_OverviewEdgeRenderData data) {
    _edges[data.id] = data;
    _renderBatch = null;
  }

  void remove(String id) {
    _edges.remove(id);
    _renderBatch = null;
  }

  ConnectionRenderBatch render() {
    final retained = _renderBatch;
    if (retained != null) return retained;

    final path = Path();
    final linePoints = Float32List(_edges.length * 4);
    var pointIndex = 0;
    for (final edge in _edges.values) {
      path
        ..moveTo(edge.source.dx, edge.source.dy)
        ..lineTo(edge.target.dx, edge.target.dy);
      linePoints[pointIndex++] = edge.source.dx;
      linePoints[pointIndex++] = edge.source.dy;
      linePoints[pointIndex++] = edge.target.dx;
      linePoints[pointIndex++] = edge.target.dy;
    }
    onBuild();
    return _renderBatch = ConnectionRenderBatch(
      path: path,
      linePoints: linePoints,
      isDashed: false,
      color: key.color,
      strokeWidth: key.strokeWidth,
      edgeCount: _edges.length,
    );
  }
}
