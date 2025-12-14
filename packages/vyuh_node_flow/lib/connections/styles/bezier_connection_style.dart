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
///
/// ## Segment-Based Architecture
///
/// This style implements [createSegments] as the primary method.
/// All path rendering, hit testing, and bend detection derive from
/// the segments calculated once - eliminating redundant calculations.
class BezierConnectionStyle extends ConnectionStyle {
  const BezierConnectionStyle();

  @override
  String get id => 'bezier';

  @override
  String get displayName => 'Bezier';

  @override
  ({Offset start, List<PathSegment> segments}) createSegments(
    ConnectionPathParameters params,
  ) {
    // Check if we need loopback routing (target behind source or same-side ports)
    if (WaypointBuilder.needsLoopbackRouting(params)) {
      // Use shared loopback routing - produces clean step-based routing
      final segments = WaypointBuilder.buildLoopbackSegments(params);
      return (start: params.start, segments: segments);
    }

    // Forward bezier curve - use single cubic segment
    final segments = _buildForwardBezierSegments(params);
    return (start: params.start, segments: segments);
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

  // === Build methods derive from segments (overridable) ===
  // - buildPath(start, segments) → Path
  // - buildHitTestRects(start, segments, tolerance) → List<Rect>
  // - extractBendPoints(start, segments) → List<Offset>

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
  ({Offset start, List<PathSegment> segments}) createSegments(
    ConnectionPathParameters params,
  ) {
    // Use custom curvature factor by creating modified params
    final adjustedParams = ConnectionPathParameters(
      start: params.start,
      end: params.end,
      curvature: params.curvature * customCurvatureFactor,
      sourcePort: params.sourcePort,
      targetPort: params.targetPort,
      cornerRadius: params.cornerRadius,
      offset: params.offset,
      backEdgeGap: params.backEdgeGap,
      controlPoints: params.controlPoints,
      sourceNodeBounds: params.sourceNodeBounds,
      targetNodeBounds: params.targetNodeBounds,
    );

    return super.createSegments(adjustedParams);
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
