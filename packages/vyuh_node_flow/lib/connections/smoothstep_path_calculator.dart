import 'dart:math' as math;
import 'dart:ui';

import '../ports/port.dart';

class SmoothstepPathCalculator {
  static Path calculatePath({
    required Offset start,
    required Offset end,
    required PortPosition sourcePosition,
    required PortPosition targetPosition,
    double offset = 10.0,
    double cornerRadius = 8.0,
  }) {
    final waypoints = _calculateWaypoints(
      start.dx,
      start.dy,
      sourcePosition,
      end.dx,
      end.dy,
      targetPosition,
      offset,
    );

    return _generateSmoothPath(waypoints, cornerRadius);
  }

  /// Get the bend points (waypoints) for a smoothstep path without creating the Path
  /// These are the exact points where 90-degree bends occur
  static List<Offset> getBendPoints({
    required Offset start,
    required Offset end,
    required PortPosition sourcePosition,
    required PortPosition targetPosition,
    double offset = 10.0,
  }) {
    return _calculateWaypoints(
      start.dx,
      start.dy,
      sourcePosition,
      end.dx,
      end.dy,
      targetPosition,
      offset,
    );
  }

  static List<Offset> _calculateWaypoints(
    double startX,
    double startY,
    PortPosition sourcePos,
    double endX,
    double endY,
    PortPosition targetPos,
    double offset,
  ) {
    // Phase II: Early detection of simple paths
    final start = Offset(startX, startY);
    final end = Offset(endX, endY);
    final startExtended = _getExtendedPoint(start, sourcePos, offset);
    final endExtended = _getExtendedPoint(end, targetPos, offset);

    // 1. Check for straight line (all points collinear)
    if (_arePointsCollinear(start, startExtended, endExtended, end)) {
      // Can draw a straight line through extended points
      return [start, startExtended, endExtended, end];
    }

    // 2. Check for L-shape (single bend)
    if (_canFormLShape(startExtended, endExtended, sourcePos, targetPos)) {
      return _createLShapePath(
        start,
        startExtended,
        endExtended,
        end,
        sourcePos,
        targetPos,
      );
    }

    // 3. Otherwise, use the full routing logic
    final routingKey = '${sourcePos.name}-${targetPos.name}';

    final waypoints = switch (routingKey) {
      // RIGHT source combinations
      'right-left' => _calculateRightToLeft(startX, startY, endX, endY, offset),
      'right-right' => _calculateRightToRight(
        startX,
        startY,
        endX,
        endY,
        offset,
      ),
      'right-top' => _calculateRightToTop(startX, startY, endX, endY, offset),
      'right-bottom' => _calculateRightToBottom(
        startX,
        startY,
        endX,
        endY,
        offset,
      ),

      // LEFT source combinations
      'left-right' => _calculateLeftToRight(startX, startY, endX, endY, offset),
      'left-left' => _calculateLeftToLeft(startX, startY, endX, endY, offset),
      'left-top' => _calculateLeftToTop(startX, startY, endX, endY, offset),
      'left-bottom' => _calculateLeftToBottom(
        startX,
        startY,
        endX,
        endY,
        offset,
      ),

      // TOP source combinations
      'top-bottom' => _calculateTopToBottom(startX, startY, endX, endY, offset),
      'top-top' => _calculateTopToTop(startX, startY, endX, endY, offset),
      'top-left' => _calculateTopToLeft(startX, startY, endX, endY, offset),
      'top-right' => _calculateTopToRight(startX, startY, endX, endY, offset),

      // BOTTOM source combinations
      'bottom-top' => _calculateBottomToTop(startX, startY, endX, endY, offset),
      'bottom-bottom' => _calculateBottomToBottom(
        startX,
        startY,
        endX,
        endY,
        offset,
      ),
      'bottom-left' => _calculateBottomToLeft(
        startX,
        startY,
        endX,
        endY,
        offset,
      ),
      'bottom-right' => _calculateBottomToRight(
        startX,
        startY,
        endX,
        endY,
        offset,
      ),

      _ => [Offset(startX, startY), Offset(endX, endY)],
    };

    // Optimize by removing collinear points
    return _optimizeWaypoints(waypoints);
  }

  /// Calculates the extended point from a port based on its position.
  ///
  /// This adds an offset in the direction the port faces:
  /// - Right port: extends to the right (x + offset)
  /// - Left port: extends to the left (x - offset)
  /// - Top port: extends upward (y - offset)
  /// - Bottom port: extends downward (y + offset)
  static Offset _getExtendedPoint(
    Offset point,
    PortPosition position,
    double offset,
  ) {
    return switch (position) {
      PortPosition.right => Offset(point.dx + offset, point.dy),
      PortPosition.left => Offset(point.dx - offset, point.dy),
      PortPosition.top => Offset(point.dx, point.dy - offset),
      PortPosition.bottom => Offset(point.dx, point.dy + offset),
    };
  }

  /// Checks if four points are collinear (all on the same straight line).
  static bool _arePointsCollinear(
    Offset p1,
    Offset p2,
    Offset p3,
    Offset p4, {
    double tolerance = 0.5,
  }) {
    // Check if all points are on a horizontal line
    final allHorizontal =
        (p1.dy - p2.dy).abs() < tolerance &&
        (p2.dy - p3.dy).abs() < tolerance &&
        (p3.dy - p4.dy).abs() < tolerance;

    // Check if all points are on a vertical line
    final allVertical =
        (p1.dx - p2.dx).abs() < tolerance &&
        (p2.dx - p3.dx).abs() < tolerance &&
        (p3.dx - p4.dx).abs() < tolerance;

    return allHorizontal || allVertical;
  }

  /// Checks if an L-shape path (single bend) is possible.
  ///
  /// An L-shape is possible when:
  /// 1. Ports are NOT on the same side
  /// 2. The extended points don't create overlap (no "backward" routing needed)
  static bool _canFormLShape(
    Offset startExtended,
    Offset endExtended,
    PortPosition sourcePos,
    PortPosition targetPos,
  ) {
    // Check if ports are on the same side (these need complex routing)
    final sameSide =
        (sourcePos == PortPosition.right && targetPos == PortPosition.right) ||
        (sourcePos == PortPosition.left && targetPos == PortPosition.left) ||
        (sourcePos == PortPosition.top && targetPos == PortPosition.top) ||
        (sourcePos == PortPosition.bottom && targetPos == PortPosition.bottom);

    if (sameSide) {
      return false;
    }

    // Check if there's overlap that would require complex routing
    // This happens when extended points are on the "wrong side" of each other

    // For horizontal source ports (left/right)
    if (sourcePos == PortPosition.right || sourcePos == PortPosition.left) {
      // Check if we have enough horizontal clearance
      final hasHorizontalClearance = sourcePos == PortPosition.right
          ? startExtended.dx <=
                endExtended
                    .dx // right port: extended point should be left of or at target
          : startExtended.dx >=
                endExtended
                    .dx; // left port: extended point should be right of or at target

      if (!hasHorizontalClearance) {
        return false; // Would need to route backward
      }
    }

    // For vertical source ports (top/bottom)
    if (sourcePos == PortPosition.top || sourcePos == PortPosition.bottom) {
      // Check if we have enough vertical clearance
      final hasVerticalClearance = sourcePos == PortPosition.bottom
          ? startExtended.dy <=
                endExtended
                    .dy // bottom port: extended point should be above or at target
          : startExtended.dy >=
                endExtended
                    .dy; // top port: extended point should be below or at target

      if (!hasVerticalClearance) {
        return false; // Would need to route backward
      }
    }

    // All checks passed - L-shape is possible!
    return true;
  }

  /// Creates an L-shape path with a single bend.
  ///
  /// The bend point is where the path changes direction (the corner of the L).
  /// This ensures the corner radius can be properly applied.
  static List<Offset> _createLShapePath(
    Offset start,
    Offset startExtended,
    Offset endExtended,
    Offset end,
    PortPosition sourcePos,
    PortPosition targetPos,
  ) {
    // Determine if we're extending horizontally or vertically first
    final sourceIsHorizontal =
        sourcePos == PortPosition.left || sourcePos == PortPosition.right;

    // Create the corner/bend point where direction changes
    final Offset cornerPoint;
    if (sourceIsHorizontal) {
      // Extend horizontally first, then vertically
      // Corner uses X from startExtended, Y from endExtended
      cornerPoint = Offset(startExtended.dx, endExtended.dy);
    } else {
      // Extend vertically first, then horizontally
      // Corner uses X from endExtended, Y from startExtended
      cornerPoint = Offset(endExtended.dx, startExtended.dy);
    }

    return [
      start,
      startExtended,
      cornerPoint, // This is the bend point where corner radius is applied
      endExtended,
      end,
    ];
  }

  /// Optimizes waypoints by removing collinear points that don't change direction.
  ///
  /// This reduces unnecessary intermediate points where three consecutive points
  /// lie on the same horizontal or vertical line. For example:
  /// - (10,20) → (10,30) → (10,40) becomes (10,20) → (10,40)
  /// - (10,20) → (20,20) → (30,20) becomes (10,20) → (30,20)
  ///
  /// This optimization significantly reduces path complexity while maintaining
  /// the exact same visual result.
  static List<Offset> _optimizeWaypoints(List<Offset> waypoints) {
    if (waypoints.length < 3) return waypoints;

    final optimized = <Offset>[waypoints.first];

    for (int i = 1; i < waypoints.length - 1; i++) {
      final prev = optimized.last;
      final current = waypoints[i];
      final next = waypoints[i + 1];

      // Check if three points are collinear (on the same line)
      final isHorizontalLine =
          (prev.dy - current.dy).abs() < 0.1 &&
          (current.dy - next.dy).abs() < 0.1;
      final isVerticalLine =
          (prev.dx - current.dx).abs() < 0.1 &&
          (current.dx - next.dx).abs() < 0.1;

      // Only add the waypoint if it's not collinear (i.e., it represents a turn)
      if (!isHorizontalLine && !isVerticalLine) {
        optimized.add(current);
      }
    }

    optimized.add(waypoints.last);
    return optimized;
  }

  // RIGHT → LEFT (Classic horizontal flow)
  static List<Offset> _calculateRightToLeft(
    double startX,
    double startY,
    double endX,
    double endY,
    double offset,
  ) {
    final startExtension = startX + offset;
    final endExtension = endX - offset;

    if (startExtension < endExtension) {
      // Enough space - simple routing
      final midX = (startExtension + endExtension) / 2;
      return [
        Offset(startX, startY),
        Offset(startExtension, startY),
        Offset(midX, startY),
        Offset(midX, endY),
        Offset(endExtension, endY),
        Offset(endX, endY),
      ];
    } else {
      // Not enough space - route around
      final midY = (startY + endY) / 2;
      return [
        Offset(startX, startY),
        Offset(startExtension, startY),
        Offset(startExtension, midY),
        Offset(endExtension, midY),
        Offset(endExtension, endY),
        Offset(endX, endY),
      ];
    }
  }

  // LEFT → RIGHT (Reverse horizontal flow)
  static List<Offset> _calculateLeftToRight(
    double startX,
    double startY,
    double endX,
    double endY,
    double offset,
  ) {
    final startExtension = startX - offset;
    final endExtension = endX + offset;

    if (endExtension < startExtension) {
      // Enough space - simple routing
      final midX = (startExtension + endExtension) / 2;
      return [
        Offset(startX, startY),
        Offset(startExtension, startY),
        Offset(midX, startY),
        Offset(midX, endY),
        Offset(endExtension, endY),
        Offset(endX, endY),
      ];
    } else {
      // Not enough space - route around
      final midY = (startY + endY) / 2;
      return [
        Offset(startX, startY),
        Offset(startExtension, startY),
        Offset(startExtension, midY),
        Offset(endExtension, midY),
        Offset(endExtension, endY),
        Offset(endX, endY),
      ];
    }
  }

  // RIGHT → RIGHT (Same-side horizontal)
  static List<Offset> _calculateRightToRight(
    double startX,
    double startY,
    double endX,
    double endY,
    double offset,
  ) {
    final maxX = math.max(startX, endX) + offset;
    return [
      Offset(startX, startY),
      Offset(maxX, startY),
      Offset(maxX, endY),
      Offset(endX, endY),
    ];
  }

  // LEFT → LEFT (Same-side horizontal)
  static List<Offset> _calculateLeftToLeft(
    double startX,
    double startY,
    double endX,
    double endY,
    double offset,
  ) {
    final minX = math.min(startX, endX) - offset;
    return [
      Offset(startX, startY),
      Offset(minX, startY),
      Offset(minX, endY),
      Offset(endX, endY),
    ];
  }

  // TOP → BOTTOM (Classic vertical flow)
  static List<Offset> _calculateTopToBottom(
    double startX,
    double startY,
    double endX,
    double endY,
    double offset,
  ) {
    final startExtension = startY - offset;
    final endExtension = endY + offset;

    if (startExtension > endExtension) {
      // Not enough space - route around
      final midX = (startX + endX) / 2;
      return [
        Offset(startX, startY),
        Offset(startX, startExtension),
        Offset(midX, startExtension),
        Offset(midX, endExtension),
        Offset(endX, endExtension),
        Offset(endX, endY),
      ];
    } else {
      // Enough space - check horizontal alignment
      final horizontalOffset = (endX - startX).abs();

      if (horizontalOffset < offset) {
        // Nodes are vertically aligned - simple straight routing
        final midY = (startExtension + endExtension) / 2;
        return [
          Offset(startX, startY),
          Offset(startX, startExtension),
          Offset(startX, midY),
          Offset(endX, midY),
          Offset(endX, endExtension),
          Offset(endX, endY),
        ];
      } else {
        // Nodes are horizontally offset - route cleanly with S-curve
        final midX = (startX + endX) / 2;
        final routeY =
            endExtension; // Use the bottom extension as routing level
        return [
          Offset(startX, startY),
          Offset(startX, startExtension),
          Offset(midX, startExtension),
          Offset(midX, routeY),
          Offset(endX, routeY),
          Offset(endX, endY),
        ];
      }
    }
  }

  // BOTTOM → TOP (Reverse vertical flow)
  static List<Offset> _calculateBottomToTop(
    double startX,
    double startY,
    double endX,
    double endY,
    double offset,
  ) {
    final startExtension = startY + offset;
    final endExtension = endY - offset;

    if (startExtension < endExtension) {
      // Enough space - check horizontal alignment
      final horizontalOffset = (endX - startX).abs();

      if (horizontalOffset < offset) {
        // Nodes are vertically aligned - simple straight routing
        final midY = (startExtension + endExtension) / 2;
        return [
          Offset(startX, startY),
          Offset(startX, startExtension),
          Offset(startX, midY),
          Offset(endX, midY),
          Offset(endX, endExtension),
          Offset(endX, endY),
        ];
      } else {
        // Nodes are horizontally offset - route cleanly with S-curve
        final midX = (startX + endX) / 2;
        final routeY = endExtension; // Use the top extension as routing level
        return [
          Offset(startX, startY),
          Offset(startX, startExtension),
          Offset(midX, startExtension),
          Offset(midX, routeY),
          Offset(endX, routeY),
          Offset(endX, endY),
        ];
      }
    } else {
      // Not enough space - route around
      final midX = (startX + endX) / 2;
      return [
        Offset(startX, startY),
        Offset(startX, startExtension),
        Offset(midX, startExtension),
        Offset(midX, endExtension),
        Offset(endX, endExtension),
        Offset(endX, endY),
      ];
    }
  }

  // TOP → TOP (Same-side vertical)
  static List<Offset> _calculateTopToTop(
    double startX,
    double startY,
    double endX,
    double endY,
    double offset,
  ) {
    final minY = math.min(startY, endY) - offset;
    return [
      Offset(startX, startY),
      Offset(startX, minY),
      Offset(endX, minY),
      Offset(endX, endY),
    ];
  }

  // BOTTOM → BOTTOM (Same-side vertical)
  static List<Offset> _calculateBottomToBottom(
    double startX,
    double startY,
    double endX,
    double endY,
    double offset,
  ) {
    final maxY = math.max(startY, endY) + offset;
    return [
      Offset(startX, startY),
      Offset(startX, maxY),
      Offset(endX, maxY),
      Offset(endX, endY),
    ];
  }

  // RIGHT → TOP
  static List<Offset> _calculateRightToTop(
    double startX,
    double startY,
    double endX,
    double endY,
    double offset,
  ) {
    final startExtension = startX + offset;
    final endExtension = endY - offset;

    // Pattern: right (extend), up, left, into top port
    return [
      Offset(startX, startY),
      Offset(startExtension, startY),
      Offset(startExtension, endExtension),
      Offset(endX, endExtension),
      Offset(endX, endY),
    ];
  }

  // RIGHT → BOTTOM
  static List<Offset> _calculateRightToBottom(
    double startX,
    double startY,
    double endX,
    double endY,
    double offset,
  ) {
    final startExtension = startX + offset;
    final endExtension = endY + offset;

    // Pattern: right (extend), down, left, into bottom port
    return [
      Offset(startX, startY),
      Offset(startExtension, startY),
      Offset(startExtension, endExtension),
      Offset(endX, endExtension),
      Offset(endX, endY),
    ];
  }

  // LEFT → TOP
  static List<Offset> _calculateLeftToTop(
    double startX,
    double startY,
    double endX,
    double endY,
    double offset,
  ) {
    final startExtension = startX - offset;
    final endExtension = endY - offset;

    // Pattern: left (extend), up/down, left/right, into top port
    return [
      Offset(startX, startY),
      Offset(startExtension, startY),
      Offset(startExtension, endExtension),
      Offset(endX, endExtension),
      Offset(endX, endY),
    ];
  }

  // LEFT → BOTTOM
  static List<Offset> _calculateLeftToBottom(
    double startX,
    double startY,
    double endX,
    double endY,
    double offset,
  ) {
    final startExtension = startX - offset;
    final endExtension = endY + offset;

    // Pattern: left (extend), down, right, into bottom port
    return [
      Offset(startX, startY),
      Offset(startExtension, startY),
      Offset(startExtension, endExtension),
      Offset(endX, endExtension),
      Offset(endX, endY),
    ];
  }

  // TOP → LEFT
  static List<Offset> _calculateTopToLeft(
    double startX,
    double startY,
    double endX,
    double endY,
    double offset,
  ) {
    final startExtension = startY - offset;
    final endExtension = endX - offset;

    // Pattern: up (extend), left/right, up/down, into left port
    return [
      Offset(startX, startY),
      Offset(startX, startExtension),
      Offset(endExtension, startExtension),
      Offset(endExtension, endY),
      Offset(endX, endY),
    ];
  }

  // TOP → RIGHT
  static List<Offset> _calculateTopToRight(
    double startX,
    double startY,
    double endX,
    double endY,
    double offset,
  ) {
    final startExtension = startY - offset;
    final endExtension = endX + offset;

    // Pattern: up (extend), left/right, up/down, into right port
    return [
      Offset(startX, startY),
      Offset(startX, startExtension),
      Offset(endExtension, startExtension),
      Offset(endExtension, endY),
      Offset(endX, endY),
    ];
  }

  // BOTTOM → LEFT
  static List<Offset> _calculateBottomToLeft(
    double startX,
    double startY,
    double endX,
    double endY,
    double offset,
  ) {
    final startExtension = startY + offset;
    final endExtension = endX - offset;

    // Pattern: down (extend), left, up, into left port
    return [
      Offset(startX, startY),
      Offset(startX, startExtension),
      Offset(endExtension, startExtension),
      Offset(endExtension, endY),
      Offset(endX, endY),
    ];
  }

  // BOTTOM → RIGHT
  static List<Offset> _calculateBottomToRight(
    double startX,
    double startY,
    double endX,
    double endY,
    double offset,
  ) {
    final startExtension = startY + offset;
    final endExtension = endX + offset;

    // Pattern: down (extend), right, up, into right port
    return [
      Offset(startX, startY),
      Offset(startX, startExtension),
      Offset(endExtension, startExtension),
      Offset(endExtension, endY),
      Offset(endX, endY),
    ];
  }

  static Path _generateSmoothPath(List<Offset> waypoints, double cornerRadius) {
    if (waypoints.length < 2) {
      return Path();
    }

    final path = Path();
    path.moveTo(waypoints.first.dx, waypoints.first.dy);

    if (waypoints.length == 2) {
      // Simple direct line
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
        // Calculate distances
        final incomingDistance = incomingVector.distance;
        final outgoingDistance = outgoingVector.distance;

        // Adapt corner radius to available space
        final maxRadius = math.min(incomingDistance / 2, outgoingDistance / 2);
        final actualRadius = math.min(cornerRadius, maxRadius);

        if (actualRadius < 1.0) {
          // Too small for a curve, just draw straight lines
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
}
