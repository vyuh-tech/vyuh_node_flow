import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../ports/port.dart';
import 'connection_style_base.dart';
import 'waypoint_builder.dart';

/// Straight line connection style
///
/// Creates direct connections with small extensions from ports.
/// This is the simplest connection style with minimal path computation.
///
/// ## Loopback Routing
///
/// When the target is behind the source (loopback scenario), this style
/// uses the shared [WaypointBuilder] routing to create step-based paths
/// that route around nodes, ensuring connections never pass through them.
class StraightConnectionStyle extends ConnectionStyle {
  const StraightConnectionStyle();

  @override
  String get id => 'straight';

  @override
  String get displayName => 'Straight';

  @override
  Path createPath(ConnectionPathParameters params) {
    // Check if we need loopback routing (target behind source, same-side ports, etc.)
    if (WaypointBuilder.needsLoopbackRouting(params)) {
      // Use shared loopback routing - produces clean step-based routing
      final segments = WaypointBuilder.buildLoopbackSegments(params);
      return WaypointBuilder.generatePathFromSegments(
        start: params.start,
        segments: segments,
      );
    }

    // Forward connection - use simple straight path with extensions
    final path = Path();
    path.moveTo(params.start.dx, params.start.dy);

    _createStraightPath(
      path,
      params.start,
      params.end,
      params.offset,
      params.sourcePort,
      params.targetPort,
    );

    return path;
  }

  @override
  bool get needsBendDetection => false; // Straight lines don't have bends

  @override
  double get bendThreshold => double.infinity; // No bends expected

  @override
  int getSampleCount(double pathLength) => 2; // Just start and end

  @override
  double get minBendDistance => double.infinity; // No multiple bends

  @override
  List<Rect> getHitTestSegments(
    Path originalPath,
    double tolerance, {
    ConnectionPathParameters? pathParams,
  }) {
    if (pathParams == null) {
      return super.getHitTestSegments(originalPath, tolerance);
    }

    // Use segment-based hit testing for loopback routing
    if (WaypointBuilder.needsLoopbackRouting(pathParams)) {
      final segments = WaypointBuilder.buildLoopbackSegments(pathParams);
      return WaypointBuilder.generateHitTestFromSegments(
        start: pathParams.start,
        segments: segments,
        tolerance: tolerance,
      );
    }

    // Forward connection - use simple hit test segments
    final sourcePosition =
        pathParams.sourcePort?.position ?? PortPosition.right;
    final targetPosition = pathParams.targetPort?.position ?? PortPosition.left;

    final startExtension = _calculateExtensionPoint(
      pathParams.start,
      sourcePosition,
      pathParams.offset,
    );
    final endExtension = _calculateExtensionPoint(
      pathParams.end,
      targetPosition,
      pathParams.offset,
    );

    final segments = <Rect>[];

    // If extension is too small, handle the single diagonal line
    if (pathParams.offset < 5.0) {
      _addDiagonalSegments(
        pathParams.start,
        pathParams.end,
        tolerance,
        segments,
      );
      return segments;
    }

    // First segment: port → extension (usually horizontal or vertical)
    _addDiagonalSegments(pathParams.start, startExtension, tolerance, segments);

    // Middle segment: extension → extension (the diagonal part)
    _addDiagonalSegments(startExtension, endExtension, tolerance, segments);

    // Last segment: extension → port (usually horizontal or vertical)
    _addDiagonalSegments(endExtension, pathParams.end, tolerance, segments);

    return segments;
  }

  /// Creates tight hit test segments for a line segment.
  ///
  /// For axis-aligned lines (horizontal/vertical), creates a single rectangle.
  /// For diagonal lines, calculates the **perpendicular expansion** of the AABB
  /// (the wasted corner area) and only splits if that expansion is excessive.
  ///
  /// Key insight: The dimension along the line direction isn't wasted - it's
  /// necessary to cover the line. Only the perpendicular expansion represents
  /// wasted area in the AABB corners.
  ///
  /// Perpendicular expansion = L × min(sin(θ), cos(θ)) + 2t
  /// - For horizontal/vertical: just 2t (no excess)
  /// - For 45°: 0.7L + 2t (significant excess for long lines)
  void _addDiagonalSegments(
    Offset start,
    Offset end,
    double tolerance,
    List<Rect> segments,
  ) {
    final dx = end.dx - start.dx;
    final dy = end.dy - start.dy;
    final length = math.sqrt(dx * dx + dy * dy);

    // Skip zero-length segments
    if (length < 0.1) return;

    // Check if the line is axis-aligned (horizontal or vertical)
    final isHorizontal = dy.abs() < 0.5;
    final isVertical = dx.abs() < 0.5;

    if (isHorizontal || isVertical) {
      // Axis-aligned lines can use a single rectangle
      segments.add(_createAxisAlignedRect(start, end, tolerance));
      return;
    }

    // Calculate perpendicular expansion - this is what creates wasted corner area
    // For a line at angle θ, the perpendicular AABB dimension expands by:
    //   L × min(|sin(θ)|, |cos(θ)|) + 2t
    final cosAngle = dx.abs() / length;
    final sinAngle = dy.abs() / length;
    final minTrigComponent = math.min(sinAngle, cosAngle);
    final perpExpansion = length * minTrigComponent + 2 * tolerance;

    // Limit perpendicular expansion to a factor of tolerance
    // This correctly handles:
    // - Long horizontal lines → small perpExpansion → single segment
    // - Long 45° lines → large perpExpansion → multiple segments
    // Using 3x tolerance (same as Bezier) for consistent hit test precision
    final maxAllowedPerpExpansion = tolerance * 3;

    if (perpExpansion <= maxAllowedPerpExpansion) {
      // Single segment - perpendicular expansion is acceptable
      segments.add(_createDiagonalSegmentRect(start, end, tolerance));
      return;
    }

    // Need to split to reduce perpendicular expansion
    // Segment count based on how much we need to reduce
    final segmentCount = (perpExpansion / maxAllowedPerpExpansion).ceil();

    for (int i = 0; i < segmentCount; i++) {
      final t1 = i / segmentCount;
      final t2 = (i + 1) / segmentCount;

      final p1 = Offset(start.dx + dx * t1, start.dy + dy * t1);
      final p2 = Offset(start.dx + dx * t2, start.dy + dy * t2);

      // Create rectangle with perpendicular tolerance
      segments.add(_createDiagonalSegmentRect(p1, p2, tolerance));
    }
  }

  /// Creates a rectangle for an axis-aligned line segment.
  Rect _createAxisAlignedRect(Offset start, Offset end, double tolerance) {
    return Rect.fromLTRB(
      math.min(start.dx, end.dx) - tolerance,
      math.min(start.dy, end.dy) - tolerance,
      math.max(start.dx, end.dx) + tolerance,
      math.max(start.dy, end.dy) + tolerance,
    );
  }

  /// Creates a tight rectangle for a diagonal line segment.
  ///
  /// Uses perpendicular distance to create a narrow strip that follows
  /// the actual line direction rather than a large axis-aligned bounding box.
  Rect _createDiagonalSegmentRect(Offset p1, Offset p2, double tolerance) {
    final dx = p2.dx - p1.dx;
    final dy = p2.dy - p1.dy;
    final length = math.sqrt(dx * dx + dy * dy);

    if (length < 0.001) {
      // Point-like segment
      return Rect.fromCenter(
        center: p1,
        width: tolerance * 2,
        height: tolerance * 2,
      );
    }

    // Calculate perpendicular direction (normalized)
    final perpX = -dy / length;
    final perpY = dx / length;

    // Create 4 corner points at ±tolerance perpendicular to each endpoint
    final corners = [
      Offset(p1.dx + perpX * tolerance, p1.dy + perpY * tolerance),
      Offset(p1.dx - perpX * tolerance, p1.dy - perpY * tolerance),
      Offset(p2.dx + perpX * tolerance, p2.dy + perpY * tolerance),
      Offset(p2.dx - perpX * tolerance, p2.dy - perpY * tolerance),
    ];

    // Find bounding box of the rotated rectangle
    double minX = corners[0].dx;
    double maxX = corners[0].dx;
    double minY = corners[0].dy;
    double maxY = corners[0].dy;

    for (final corner in corners) {
      if (corner.dx < minX) minX = corner.dx;
      if (corner.dx > maxX) maxX = corner.dx;
      if (corner.dy < minY) minY = corner.dy;
      if (corner.dy > maxY) maxY = corner.dy;
    }

    return Rect.fromLTRB(minX, minY, maxX, maxY);
  }

  /// Creates the straight line path with extensions
  void _createStraightPath(
    Path path,
    Offset start,
    Offset end,
    double offset,
    Port? sourcePort,
    Port? targetPort,
  ) {
    final sourcePosition = sourcePort?.position ?? PortPosition.right;
    final targetPosition = targetPort?.position ?? PortPosition.left;

    // Calculate extension points based on port positions
    // Both extensions go AWAY from their respective ports
    final startExtension = _calculateExtensionPoint(
      start,
      sourcePosition,
      offset,
    );
    final endExtension = _calculateExtensionPoint(end, targetPosition, offset);

    // Draw path with extensions
    path.lineTo(startExtension.dx, startExtension.dy);
    path.lineTo(endExtension.dx, endExtension.dy);
    path.lineTo(end.dx, end.dy);
  }

  /// Calculate extension point based on port position
  Offset _calculateExtensionPoint(
    Offset point,
    PortPosition position,
    double offset,
  ) {
    switch (position) {
      case PortPosition.left:
        return Offset(point.dx - offset, point.dy);
      case PortPosition.right:
        return Offset(point.dx + offset, point.dy);
      case PortPosition.top:
        return Offset(point.dx, point.dy - offset);
      case PortPosition.bottom:
        return Offset(point.dx, point.dy + offset);
    }
  }
}
