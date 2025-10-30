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
    final routingKey = '${sourcePos.name}-${targetPos.name}';

    switch (routingKey) {
      // RIGHT source combinations
      case 'right-left':
        return _calculateRightToLeft(startX, startY, endX, endY, offset);
      case 'right-right':
        return _calculateRightToRight(startX, startY, endX, endY, offset);
      case 'right-top':
        return _calculateRightToTop(startX, startY, endX, endY, offset);
      case 'right-bottom':
        return _calculateRightToBottom(startX, startY, endX, endY, offset);

      // LEFT source combinations
      case 'left-right':
        return _calculateLeftToRight(startX, startY, endX, endY, offset);
      case 'left-left':
        return _calculateLeftToLeft(startX, startY, endX, endY, offset);
      case 'left-top':
        return _calculateLeftToTop(startX, startY, endX, endY, offset);
      case 'left-bottom':
        return _calculateLeftToBottom(startX, startY, endX, endY, offset);

      // TOP source combinations
      case 'top-bottom':
        return _calculateTopToBottom(startX, startY, endX, endY, offset);
      case 'top-top':
        return _calculateTopToTop(startX, startY, endX, endY, offset);
      case 'top-left':
        return _calculateTopToLeft(startX, startY, endX, endY, offset);
      case 'top-right':
        return _calculateTopToRight(startX, startY, endX, endY, offset);

      // BOTTOM source combinations
      case 'bottom-top':
        return _calculateBottomToTop(startX, startY, endX, endY, offset);
      case 'bottom-bottom':
        return _calculateBottomToBottom(startX, startY, endX, endY, offset);
      case 'bottom-left':
        return _calculateBottomToLeft(startX, startY, endX, endY, offset);
      case 'bottom-right':
        return _calculateBottomToRight(startX, startY, endX, endY, offset);

      default:
        return [Offset(startX, startY), Offset(endX, endY)];
    }
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
