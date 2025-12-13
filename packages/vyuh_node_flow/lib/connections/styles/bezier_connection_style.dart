import 'dart:math' as math;
import 'dart:ui' show PathMetric;

import 'package:flutter/material.dart';

import '../../ports/port.dart';
import 'connection_style_base.dart';
import 'waypoint_builder.dart';

/// Bezier curve connection style
///
/// Creates smooth curved connections using cubic bezier curves.
/// Control points are calculated based on port positions and curvature settings.
///
/// ## Node-Aware Routing
///
/// When [sourceNodeBounds] and [targetNodeBounds] are provided in the path
/// parameters, control points are adjusted to guide the curve around nodes,
/// preventing curves from passing through node bodies.
class BezierConnectionStyle extends ConnectionStyle {
  const BezierConnectionStyle();

  @override
  String get id => 'bezier';

  @override
  String get displayName => 'Bezier';

  @override
  Path createPath(ConnectionPathParameters params) {
    // Check if we need loopback routing (target behind source or same-side ports)
    if (WaypointBuilder.needsLoopbackRouting(params)) {
      // Use shared loopback routing - produces clean step-based routing
      final segments = WaypointBuilder.buildLoopbackSegments(params);
      return WaypointBuilder.generatePathFromSegments(
        start: params.start,
        segments: segments,
      );
    }

    // Forward bezier curve - use segment-based API
    final segments = _buildForwardBezierSegments(params);
    return WaypointBuilder.generatePathFromSegments(
      start: params.start,
      segments: segments,
    );
  }

  /// Builds path segments for forward bezier connections.
  ///
  /// Uses a single cubic bezier segment.
  List<PathSegment> _buildForwardBezierSegments(
    ConnectionPathParameters params,
  ) {
    final sourcePosition = params.sourcePort?.position ?? PortPosition.right;
    final targetPosition = params.targetPort?.position ?? PortPosition.left;

    // Create bezier segment with control points
    var segment = WaypointBuilder.createBezierSegment(
      start: params.start,
      end: params.end,
      sourcePosition: sourcePosition,
      targetPosition: targetPosition,
      curvature: params.curvature,
      portExtension: params.offset,
    );

    // Apply node avoidance adjustments using INDIVIDUAL node bounds
    // (not union - union creates excessive curves for distant nodes)
    var cp1 = segment.controlPoint1;
    var cp2 = segment.controlPoint2;

    if (params.sourceNodeBounds != null) {
      cp1 = _adjustControlPointForNodeAvoidance(
        controlPoint: cp1,
        anchorPoint: params.start,
        position: sourcePosition,
        nodeBounds: params.sourceNodeBounds!,
        clearance: params.offset,
      );
    }

    if (params.targetNodeBounds != null) {
      cp2 = _adjustControlPointForNodeAvoidance(
        controlPoint: cp2,
        anchorPoint: params.end,
        position: targetPosition,
        nodeBounds: params.targetNodeBounds!,
        clearance: params.offset,
      );
    }

    // Only create new segment if control points changed
    if (cp1 != segment.controlPoint1 || cp2 != segment.controlPoint2) {
      segment = CubicSegment(
        controlPoint1: cp1,
        controlPoint2: cp2,
        end: segment.end,
        curvature: segment.curvature,
      );
    }

    return [segment];
  }

  @override
  bool get needsBendDetection => true; // Curves need bend detection for hit testing

  @override
  double get bendThreshold => math.pi / 9; // 20 degrees - sensitive for bezier curves

  @override
  int getSampleCount(double pathLength) {
    // More samples for curves to detect subtle bends
    return math.min(20, math.max(5, (pathLength / 20).ceil()));
  }

  @override
  double get minBendDistance => 3.0; // Closer segments for precise curves

  @override
  List<Rect> getHitTestSegments(
    Path originalPath,
    double tolerance, {
    ConnectionPathParameters? pathParams,
  }) {
    final bounds = originalPath.getBounds();
    if (bounds.width <= 0 && bounds.height <= 0) {
      return [];
    }

    // Use segment-based hit testing when params are available
    if (pathParams != null) {
      if (WaypointBuilder.needsLoopbackRouting(pathParams)) {
        // Loopback path - use shared loopback segments
        final segments = WaypointBuilder.buildLoopbackSegments(pathParams);
        return WaypointBuilder.generateHitTestFromSegments(
          start: pathParams.start,
          segments: segments,
          tolerance: tolerance,
        );
      }

      // Forward bezier curve - use segment-based hit testing
      final segments = _buildForwardBezierSegments(pathParams);
      return WaypointBuilder.generateHitTestFromSegments(
        start: pathParams.start,
        segments: segments,
        tolerance: tolerance,
      );
    }

    // Fallback: use path metrics when no params available
    final metrics = originalPath.computeMetrics().toList();
    if (metrics.isEmpty) {
      return [bounds.inflate(tolerance)];
    }

    final segmentRects = <Rect>[];

    for (final metric in metrics) {
      if (metric.length == 0) continue;
      _createBendBasedSegments(metric, tolerance, segmentRects);
    }

    return segmentRects;
  }

  /// Creates strip segments that follow the curve path tightly.
  ///
  /// Each segment samples multiple points along the curve and creates a
  /// bounding box that follows the actual curve shape with perpendicular
  /// thickness of 2 * tolerance.
  ///
  /// Segment size is limited to a factor of tolerance to prevent oversized
  /// hit test areas on curves.
  void _createBendBasedSegments(
    PathMetric metric,
    double tolerance,
    List<Rect> segments,
  ) {
    if (metric.length == 0) return;

    // Limit segment length to 3x tolerance to keep AABB sizes reasonable
    // This ensures hit test rectangles stay tight even for long curves
    final maxSegmentLength = tolerance * 3;
    final segmentCount = math.max(3, (metric.length / maxSegmentLength).ceil());
    final segmentLength = metric.length / segmentCount;

    for (int i = 0; i < segmentCount; i++) {
      final startOffset = i * segmentLength;
      final endOffset = math.min((i + 1) * segmentLength, metric.length);

      // Sample multiple points within this segment to follow curve shape
      final sampleCount = 4;
      final boundaryPoints = <Offset>[];

      for (int j = 0; j <= sampleCount; j++) {
        final t = j / sampleCount;
        final offset = startOffset + t * (endOffset - startOffset);
        final tangent = metric.getTangentForOffset(offset);

        if (tangent == null) continue;

        final point = tangent.position;
        final dir = tangent.vector;
        final dirLength = dir.distance;

        if (dirLength < 0.001) continue;

        // Perpendicular direction (normalized)
        final perpX = -dir.dy / dirLength;
        final perpY = dir.dx / dirLength;

        // Add points at ±tolerance perpendicular to the curve
        boundaryPoints.add(Offset(
          point.dx + perpX * tolerance,
          point.dy + perpY * tolerance,
        ));
        boundaryPoints.add(Offset(
          point.dx - perpX * tolerance,
          point.dy - perpY * tolerance,
        ));
      }

      if (boundaryPoints.length < 2) continue;

      // Create tight bounding box from all boundary points
      double minX = boundaryPoints[0].dx;
      double maxX = boundaryPoints[0].dx;
      double minY = boundaryPoints[0].dy;
      double maxY = boundaryPoints[0].dy;

      for (final point in boundaryPoints) {
        if (point.dx < minX) minX = point.dx;
        if (point.dx > maxX) maxX = point.dx;
        if (point.dy < minY) minY = point.dy;
        if (point.dy > maxY) maxY = point.dy;
      }

      segments.add(Rect.fromLTRB(minX, minY, maxX, maxY));
    }

    // Fallback for very short paths
    if (segments.isEmpty) {
      final center = metric.getTangentForOffset(metric.length / 2)?.position;
      if (center != null) {
        segments.add(Rect.fromCenter(
          center: center,
          width: tolerance * 2,
          height: tolerance * 2,
        ));
      }
    }
  }

  /// Creates the bezier curve path with optional node-aware control point adjustment.
  void _createBezierPath(
    Path path,
    Offset start,
    Offset end,
    double curvature,
    Port? sourcePort,
    Port? targetPort, {
    Rect? sourceNodeBounds,
    Rect? targetNodeBounds,
    double portExtension = 10.0,
  }) {
    final sourcePosition = sourcePort?.position ?? PortPosition.right;
    final targetPosition = targetPort?.position ?? PortPosition.left;

    // Calculate base control points using portExtension and curvature
    var cp1 = _getControlPoint(
      anchor: start,
      target: end,
      position: sourcePosition,
      portExtension: portExtension,
      curvature: curvature,
    );

    var cp2 = _getControlPoint(
      anchor: end,
      target: start,
      position: targetPosition,
      portExtension: portExtension,
      curvature: curvature,
    );

    // Adjust control points for node-aware routing using INDIVIDUAL bounds
    if (sourceNodeBounds != null) {
      cp1 = _adjustControlPointForNodeAvoidance(
        controlPoint: cp1,
        anchorPoint: start,
        position: sourcePosition,
        nodeBounds: sourceNodeBounds,
        clearance: portExtension,
      );
    }
    if (targetNodeBounds != null) {
      cp2 = _adjustControlPointForNodeAvoidance(
        controlPoint: cp2,
        anchorPoint: end,
        position: targetPosition,
        nodeBounds: targetNodeBounds,
        clearance: portExtension,
      );
    }

    path.cubicTo(cp1.dx, cp1.dy, cp2.dx, cp2.dy, end.dx, end.dy);
  }

  /// Adjusts a control point to ensure the curve stays outside node bounds.
  ///
  /// For horizontal ports (left/right), ensures the control point X is outside bounds.
  /// For vertical ports (top/bottom), ensures the control point Y is outside bounds.
  ///
  /// [clearance] specifies the minimum distance from node edges (defaults to port extension).
  Offset _adjustControlPointForNodeAvoidance({
    required Offset controlPoint,
    required Offset anchorPoint,
    required PortPosition position,
    required Rect nodeBounds,
    double clearance = 10.0,
  }) {
    switch (position) {
      case PortPosition.right:
        // Control point should be to the right of the node bounds
        final minX = nodeBounds.right + clearance;
        if (controlPoint.dx < minX) {
          return Offset(minX, controlPoint.dy);
        }
        return controlPoint;

      case PortPosition.left:
        // Control point should be to the left of the node bounds
        final maxX = nodeBounds.left - clearance;
        if (controlPoint.dx > maxX) {
          return Offset(maxX, controlPoint.dy);
        }
        return controlPoint;

      case PortPosition.bottom:
        // Control point should be below the node bounds
        final minY = nodeBounds.bottom + clearance;
        if (controlPoint.dy < minY) {
          return Offset(controlPoint.dx, minY);
        }
        return controlPoint;

      case PortPosition.top:
        // Control point should be above the node bounds
        final maxY = nodeBounds.top - clearance;
        if (controlPoint.dy > maxY) {
          return Offset(controlPoint.dx, maxY);
        }
        return controlPoint;
    }
  }

  /// Calculates a control point for smooth bezier curves.
  ///
  /// The control point extends from [anchor] in the direction the port faces,
  /// with distance determined by:
  /// - [portExtension]: Minimum extension from the port (ensures curve departs smoothly)
  /// - [curvature]: Additional pull based on perpendicular distance to target
  ///
  /// This creates gentle S-curves where:
  /// - curvature=0: Nearly straight lines (only portExtension offset)
  /// - curvature=0.5: Moderate curves (default)
  /// - curvature=1: More pronounced curves
  Offset _getControlPoint({
    required Offset anchor,
    required Offset target,
    required PortPosition position,
    required double portExtension,
    required double curvature,
  }) {
    // Calculate the perpendicular distance (the distance that creates the curve)
    final double perpDistance;
    final bool isForwardFlow;

    switch (position) {
      case PortPosition.right:
        perpDistance = (target.dy - anchor.dy).abs();
        isForwardFlow = target.dx >= anchor.dx;
      case PortPosition.left:
        perpDistance = (target.dy - anchor.dy).abs();
        isForwardFlow = target.dx <= anchor.dx;
      case PortPosition.bottom:
        perpDistance = (target.dx - anchor.dx).abs();
        isForwardFlow = target.dy >= anchor.dy;
      case PortPosition.top:
        perpDistance = (target.dx - anchor.dx).abs();
        isForwardFlow = target.dy <= anchor.dy;
    }

    // Calculate control point offset
    // Base: portExtension ensures minimum straight departure from port
    // Additional: scaled by curvature and perpendicular distance for smooth S-curves
    final double offset;
    if (isForwardFlow) {
      // Forward flow: use portExtension + curvature-based addition
      // The perpendicular distance determines how much extra pull we need
      final curvatureAddition = perpDistance * curvature * 0.3;
      offset = portExtension + curvatureAddition;
    } else {
      // Loopback: need more extension to route around
      // Use sqrt for gentler scaling on large distances
      final loopbackAddition = curvature * 8 * math.sqrt(perpDistance + 10);
      offset = math.max(portExtension, portExtension + loopbackAddition);
    }

    // Apply offset in the direction the port faces
    return switch (position) {
      PortPosition.right => Offset(anchor.dx + offset, anchor.dy),
      PortPosition.left => Offset(anchor.dx - offset, anchor.dy),
      PortPosition.bottom => Offset(anchor.dx, anchor.dy + offset),
      PortPosition.top => Offset(anchor.dx, anchor.dy - offset),
    };
  }
}

/// Custom bezier connection style with user-controlled parameters
///
/// Allows for more advanced bezier curve customization beyond the basic style.
class CustomBezierConnectionStyle extends BezierConnectionStyle {
  const CustomBezierConnectionStyle({
    this.customCurvatureFactor = 1.0,
    this.asymmetricControls = false,
  });

  /// Custom curvature factor multiplier (default 1.0)
  final double customCurvatureFactor;

  /// Whether to use asymmetric control points for more complex curves
  final bool asymmetricControls;

  @override
  String get id => 'customBezier';

  @override
  String get displayName => 'Custom Bezier';

  @override
  Path createPath(ConnectionPathParameters params) {
    final path = Path();
    path.moveTo(params.start.dx, params.start.dy);

    // Use custom curvature factor
    final adjustedCurvature = params.curvature * customCurvatureFactor;

    _createBezierPath(
      path,
      params.start,
      params.end,
      adjustedCurvature,
      params.sourcePort,
      params.targetPort,
      sourceNodeBounds: params.sourceNodeBounds,
      targetNodeBounds: params.targetNodeBounds,
      portExtension: params.offset,
    );

    return path;
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      super == other &&
          other is CustomBezierConnectionStyle &&
          customCurvatureFactor == other.customCurvatureFactor &&
          asymmetricControls == other.asymmetricControls;

  @override
  int get hashCode =>
      Object.hash(super.hashCode, customCurvatureFactor, asymmetricControls);
}
