import 'dart:math' as math;
import 'dart:ui';

import 'connection_style_base.dart';
import 'editable_path_connection_style.dart';
import 'smoothstep_path_calculator.dart';

/// An editable connection style that creates smooth step paths with rounded corners.
///
/// This style maintains the 90-degree turn characteristic of smooth step connections
/// while allowing users to customize the path by adding, moving, or removing control
/// points. The path is rendered as a series of horizontal and vertical segments with
/// smoothly rounded corners.
///
/// ## Features
///
/// - **Editable flat edges**: Users can tweak the horizontal and vertical segments
/// - **Add control points**: Insert intermediate waypoints along the path
/// - **Maintain orthogonal routing**: All segments remain horizontal or vertical
/// - **Smooth corners**: Configurable corner radius for rounded turns
///
/// ## Path Behavior
///
/// ### Without Control Points (Algorithmic Mode)
/// Uses the standard smooth step algorithm to automatically calculate an optimal
/// path between the source and target ports based on their positions.
///
/// ### With Control Points (Manual Mode)
/// Creates a path that passes through all control points while maintaining the
/// smooth step visual style (90-degree turns with rounded corners).
///
/// ## Usage Example
///
/// ```dart
/// // Create a connection with editable smooth step style
/// final connection = Connection(
///   id: 'conn-1',
///   sourceNodeId: 'node-a',
///   sourcePortId: 'output-1',
///   targetNodeId: 'node-b',
///   targetPortId: 'input-1',
///   style: editableSmoothStepStyle,
///   controlPoints: [
///     Offset(150, 100),  // First bend point
///     Offset(150, 200),  // Second bend point
///   ],
/// );
/// ```
///
/// See also:
/// - [EditablePathConnectionStyle] for the base editable path functionality
/// - [SmoothstepPathCalculator] for the underlying path algorithm
class EditableSmoothStepConnectionStyle extends EditablePathConnectionStyle {
  /// Creates an editable smooth step connection style.
  ///
  /// Parameters:
  /// - [defaultCornerRadius]: The corner radius to use when not specified in params (default: 8.0)
  const EditableSmoothStepConnectionStyle({this.defaultCornerRadius = 8.0});

  /// The default corner radius for rounded corners
  final double defaultCornerRadius;

  @override
  String get id => 'editable-smoothstep';

  @override
  String get displayName => 'Editable Smooth Step';

  @override
  Path createDefaultPath(ConnectionPathParameters params) {
    // Use the standard smooth step algorithm when no control points exist
    return SmoothstepPathCalculator.calculatePath(
      start: params.start,
      end: params.end,
      sourcePosition: params.sourcePosition,
      targetPosition: params.targetPosition,
      offset: params.offset,
      cornerRadius: params.cornerRadius,
    );
  }

  @override
  Path createPathThroughWaypoints(
    List<Offset> waypoints,
    ConnectionPathParameters params,
  ) {
    if (waypoints.isEmpty) {
      return createDefaultPath(params);
    }

    // If only start and end, use default path
    if (waypoints.length == 2) {
      return createDefaultPath(params);
    }

    // Create orthogonal path through all waypoints
    // We need to convert the arbitrary control points into orthogonal segments
    final orthogonalWaypoints = _createOrthogonalWaypoints(waypoints);

    // Generate smooth path with rounded corners
    return _generateSmoothPath(
      orthogonalWaypoints,
      params.cornerRadius > 0 ? params.cornerRadius : defaultCornerRadius,
    );
  }

  /// Converts arbitrary waypoints into orthogonal (horizontal/vertical) segments.
  ///
  /// This ensures the smooth step characteristic is maintained even when users
  /// place control points at arbitrary positions. The algorithm creates horizontal
  /// and vertical segments that pass as close as possible to each control point.
  List<Offset> _createOrthogonalWaypoints(List<Offset> waypoints) {
    if (waypoints.length < 2) return waypoints;

    final orthogonal = <Offset>[waypoints.first];
    bool isHorizontal = true; // Alternate between horizontal and vertical

    for (int i = 1; i < waypoints.length - 1; i++) {
      final current = orthogonal.last;
      final target = waypoints[i];

      if (isHorizontal) {
        // Move horizontally, then add a vertical segment
        orthogonal.add(Offset(target.dx, current.dy));
        orthogonal.add(target);
      } else {
        // Move vertically, then add a horizontal segment
        orthogonal.add(Offset(current.dx, target.dy));
        orthogonal.add(target);
      }

      isHorizontal = !isHorizontal;
    }

    // Connect to the last waypoint
    final secondLast = orthogonal.last;
    final last = waypoints.last;

    // Determine best way to connect based on current orientation
    if (isHorizontal) {
      // Try horizontal first
      if ((last.dx - secondLast.dx).abs() > (last.dy - secondLast.dy).abs()) {
        orthogonal.add(Offset(last.dx, secondLast.dy));
      } else {
        orthogonal.add(Offset(secondLast.dx, last.dy));
      }
    } else {
      // Try vertical first
      if ((last.dy - secondLast.dy).abs() > (last.dx - secondLast.dx).abs()) {
        orthogonal.add(Offset(secondLast.dx, last.dy));
      } else {
        orthogonal.add(Offset(last.dx, secondLast.dy));
      }
    }

    orthogonal.add(last);

    // Optimize by removing collinear points
    return _optimizeWaypoints(orthogonal);
  }

  /// Optimizes waypoints by removing collinear points.
  ///
  /// This reduces unnecessary intermediate points where three consecutive points
  /// lie on the same horizontal or vertical line.
  List<Offset> _optimizeWaypoints(List<Offset> waypoints) {
    if (waypoints.length < 3) return waypoints;

    final optimized = <Offset>[waypoints.first];

    for (int i = 1; i < waypoints.length - 1; i++) {
      final prev = optimized.last;
      final current = waypoints[i];
      final next = waypoints[i + 1];

      // Check if three points are collinear
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

  /// Generates a smooth path with rounded corners through waypoints.
  ///
  /// This creates the final Path object with quadratic bezier curves at corners
  /// to create the smooth step appearance.
  Path _generateSmoothPath(List<Offset> waypoints, double cornerRadius) {
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

  @override
  bool get hasExactBendPoints => true;

  @override
  List<Offset>? getExactBendPoints(ConnectionPathParameters params) {
    // Return the waypoints (without start and end) for bend detection
    return SmoothstepPathCalculator.getBendPoints(
      start: params.start,
      end: params.end,
      sourcePosition: params.sourcePosition,
      targetPosition: params.targetPosition,
      offset: params.offset,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      super == other &&
          other is EditableSmoothStepConnectionStyle &&
          defaultCornerRadius == other.defaultCornerRadius;

  @override
  int get hashCode => Object.hash(super.hashCode, defaultCornerRadius);
}
