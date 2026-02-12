import 'dart:math' as math;
import 'dart:ui';

import '../../ports/port.dart';
import 'path_segments.dart';

/// Internal segment/path operations extracted from [WaypointBuilder].
///
/// Keeps segment conversion and path math isolated from routing decisions.
final class WaypointSegmentOps {
  const WaypointSegmentOps._();

  static Path generatePathFromWaypoints(
    List<Offset> waypoints, {
    double cornerRadius = 0,
  }) {
    if (waypoints.length < 2) {
      return Path();
    }

    final path = Path();
    path.moveTo(waypoints.first.dx, waypoints.first.dy);

    if (waypoints.length == 2) {
      path.lineTo(waypoints.last.dx, waypoints.last.dy);
      return path;
    }

    // If corner radius is 0, just draw straight lines
    if (cornerRadius == 0) {
      for (int i = 1; i < waypoints.length; i++) {
        path.lineTo(waypoints[i].dx, waypoints[i].dy);
      }
      return path;
    }

    // Draw path with rounded corners at waypoints
    for (int i = 1; i < waypoints.length - 1; i++) {
      final prev = waypoints[i - 1];
      final current = waypoints[i];
      final next = waypoints[i + 1];

      // Calculate vectors
      final incomingVector = current - prev;
      final outgoingVector = next - current;

      // Skip if vectors are zero (duplicate points)
      if (incomingVector.distance < 0.01 || outgoingVector.distance < 0.01) {
        path.lineTo(current.dx, current.dy);
        continue;
      }

      // Check if this is a corner (perpendicular segments)
      final incomingHorizontal = incomingVector.dy.abs() < 0.01;
      final incomingVertical = incomingVector.dx.abs() < 0.01;
      final outgoingHorizontal = outgoingVector.dy.abs() < 0.01;
      final outgoingVertical = outgoingVector.dx.abs() < 0.01;

      // Only round corners between perpendicular segments
      if ((incomingHorizontal && outgoingVertical) ||
          (incomingVertical && outgoingHorizontal)) {
        final incomingDistance = incomingVector.distance;
        final outgoingDistance = outgoingVector.distance;

        // Adapt corner radius to available space
        final maxRadius = math.min(incomingDistance / 2, outgoingDistance / 2);
        final actualRadius = math.min(cornerRadius, maxRadius);

        if (actualRadius < 1.0) {
          path.lineTo(current.dx, current.dy);
          continue;
        }

        // Calculate unit vectors
        final incomingDirection = incomingVector / incomingDistance;
        final outgoingDirection = outgoingVector / outgoingDistance;

        // Calculate corner start and end points
        final cornerStart = current - (incomingDirection * actualRadius);
        final cornerEnd = current + (outgoingDirection * actualRadius);

        // Draw line to corner start
        path.lineTo(cornerStart.dx, cornerStart.dy);

        // Draw quadratic bezier curve for the corner
        path.quadraticBezierTo(
          current.dx,
          current.dy,
          cornerEnd.dx,
          cornerEnd.dy,
        );
      } else {
        // Not a perpendicular corner, just draw straight line
        path.lineTo(current.dx, current.dy);
      }
    }

    // Draw line to the last point
    path.lineTo(waypoints.last.dx, waypoints.last.dy);

    return path;
  }

  static List<Rect> generateHitTestSegments(
    List<Offset> waypoints,
    double tolerance,
  ) {
    if (waypoints.length < 2) return [];

    // Merge collinear segments to minimize rectangle count
    final mergedSegments = _mergeCollinearSegments(waypoints);

    return mergedSegments.map((segment) {
      return Rect.fromLTRB(
        math.min(segment.start.dx, segment.end.dx) - tolerance,
        math.min(segment.start.dy, segment.end.dy) - tolerance,
        math.max(segment.start.dx, segment.end.dx) + tolerance,
        math.max(segment.start.dy, segment.end.dy) + tolerance,
      );
    }).toList();
  }

  static List<({Offset start, Offset end})> _mergeCollinearSegments(
    List<Offset> waypoints,
  ) {
    if (waypoints.length < 2) return [];

    final segments = <({Offset start, Offset end})>[];
    Offset segmentStart = waypoints[0];

    for (int i = 1; i < waypoints.length; i++) {
      final current = waypoints[i];
      bool shouldEndSegment = (i == waypoints.length - 1);

      if (!shouldEndSegment && i < waypoints.length - 1) {
        final next = waypoints[i + 1];

        final currentVector = current - segmentStart;
        final nextVector = next - current;

        final currentIsHorizontal = currentVector.dy.abs() < 0.5;
        final currentIsVertical = currentVector.dx.abs() < 0.5;
        final nextIsHorizontal = nextVector.dy.abs() < 0.5;
        final nextIsVertical = nextVector.dx.abs() < 0.5;

        // If direction changes, end this segment
        shouldEndSegment =
            (currentIsHorizontal != nextIsHorizontal) ||
            (currentIsVertical != nextIsVertical);
      }

      if (shouldEndSegment) {
        segments.add((start: segmentStart, end: current));
        segmentStart = current;
      }
    }

    return segments;
  }

  static Path generatePathFromSegments({
    required Offset start,
    required List<PathSegment> segments,
  }) {
    final path = Path();
    path.moveTo(start.dx, start.dy);

    for (final segment in segments) {
      switch (segment) {
        case StraightSegment():
          path.lineTo(segment.end.dx, segment.end.dy);
        case QuadraticSegment():
          path.quadraticBezierTo(
            segment.controlPoint.dx,
            segment.controlPoint.dy,
            segment.end.dx,
            segment.end.dy,
          );
        case CubicSegment():
          path.cubicTo(
            segment.controlPoint1.dx,
            segment.controlPoint1.dy,
            segment.controlPoint2.dx,
            segment.controlPoint2.dy,
            segment.end.dx,
            segment.end.dy,
          );
      }
    }

    return path;
  }

  static List<Rect> generateHitTestFromSegments({
    required Offset start,
    required List<PathSegment> segments,
    required double tolerance,
  }) {
    if (segments.isEmpty) return [];

    final hitRects = <Rect>[];
    Offset currentPoint = start;

    for (final segment in segments) {
      // Each segment knows how to generate its own hit test rectangles
      hitRects.addAll(segment.getHitTestRects(currentPoint, tolerance));
      currentPoint = segment.end;
    }

    return hitRects;
  }

  static List<PathSegment> waypointsToSegments(
    List<Offset> waypoints, {
    double cornerRadius = 0,
  }) {
    if (waypoints.length < 2) return [];

    final segments = <PathSegment>[];

    if (waypoints.length == 2) {
      segments.add(StraightSegment(end: waypoints[1]));
      return segments;
    }

    // No corner radius - all straight segments
    if (cornerRadius <= 0) {
      for (int i = 1; i < waypoints.length; i++) {
        segments.add(StraightSegment(end: waypoints[i]));
      }
      return segments;
    }

    // Build segments with rounded corners
    for (int i = 1; i < waypoints.length - 1; i++) {
      final prev = i == 1 ? waypoints[0] : segments.last.end;
      final current = waypoints[i];
      final next = waypoints[i + 1];

      // Calculate vectors
      final incomingVector = current - prev;
      final outgoingVector = next - current;

      // Skip if vectors are too short
      if (incomingVector.distance < 0.01 || outgoingVector.distance < 0.01) {
        segments.add(StraightSegment(end: current));
        continue;
      }

      // Check if this is a perpendicular corner
      final incomingHorizontal = incomingVector.dy.abs() < 0.01;
      final incomingVertical = incomingVector.dx.abs() < 0.01;
      final outgoingHorizontal = outgoingVector.dy.abs() < 0.01;
      final outgoingVertical = outgoingVector.dx.abs() < 0.01;

      if ((incomingHorizontal && outgoingVertical) ||
          (incomingVertical && outgoingHorizontal)) {
        // Calculate corner radius that fits available space
        final maxRadius = math.min(
          incomingVector.distance / 2,
          outgoingVector.distance / 2,
        );
        final actualRadius = math.min(cornerRadius, maxRadius);

        if (actualRadius < 1.0) {
          segments.add(StraightSegment(end: current));
          continue;
        }

        // Calculate corner start and end
        final inDir = incomingVector / incomingVector.distance;
        final outDir = outgoingVector / outgoingVector.distance;
        final cornerStart = current - (inDir * actualRadius);
        final cornerEnd = current + (outDir * actualRadius);

        // Add straight segment to corner start
        segments.add(StraightSegment(end: cornerStart));

        // Add quadratic curve for the corner
        // Skip hit test rects - corner is already covered by adjacent straight segments
        segments.add(
          QuadraticSegment(
            controlPoint: current,
            end: cornerEnd,
            generateHitTestRects: false,
          ),
        );
      } else {
        // Not a perpendicular corner - straight line
        segments.add(StraightSegment(end: current));
      }
    }

    // Add final segment
    segments.add(StraightSegment(end: waypoints.last));

    return segments;
  }

  static CubicSegment createBezierSegment({
    required Offset start,
    required Offset end,
    required PortPosition sourcePosition,
    required PortPosition targetPosition,
    required double curvature,
    required double portExtension,
    double? sourceExtension,
    double? targetExtension,
  }) {
    // Use specific extensions if provided, otherwise use default
    final effectiveSourceExtension = sourceExtension ?? portExtension;
    final effectiveTargetExtension = targetExtension ?? portExtension;

    // Calculate control points based on port positions
    final cp1 = _calculateBezierControlPoint(
      anchor: start,
      target: end,
      position: sourcePosition,
      curvature: curvature,
      portExtension: effectiveSourceExtension,
    );

    final cp2 = _calculateBezierControlPoint(
      anchor: end,
      target: start,
      position: targetPosition,
      curvature: curvature,
      portExtension: effectiveTargetExtension,
    );

    return CubicSegment(
      controlPoint1: cp1,
      controlPoint2: cp2,
      end: end,
      curvature: curvature,
    );
  }

  static Offset _calculateBezierControlPoint({
    required Offset anchor,
    required Offset target,
    required PortPosition position,
    required double curvature,
    required double portExtension,
  }) {
    switch (position) {
      case PortPosition.right:
        final offset = math.max(
          portExtension,
          (target.dx - anchor.dx).abs() * curvature,
        );
        return Offset(anchor.dx + offset, anchor.dy);

      case PortPosition.left:
        final offset = math.max(
          portExtension,
          (target.dx - anchor.dx).abs() * curvature,
        );
        return Offset(anchor.dx - offset, anchor.dy);

      case PortPosition.bottom:
        final offset = math.max(
          portExtension,
          (target.dy - anchor.dy).abs() * curvature,
        );
        return Offset(anchor.dx, anchor.dy + offset);

      case PortPosition.top:
        final offset = math.max(
          portExtension,
          (target.dy - anchor.dy).abs() * curvature,
        );
        return Offset(anchor.dx, anchor.dy - offset);
    }
  }
}
