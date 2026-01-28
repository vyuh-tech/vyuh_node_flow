import 'dart:math' as math;
import 'dart:ui';

import 'connection_style_base.dart';
import 'editable_path_connection_style.dart';
import 'waypoint_builder.dart';

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
/// ## Segment-Based Architecture
///
/// This style implements [createSegmentsThroughWaypoints] as the primary method.
/// All path rendering, hit testing, and bend detection derive from the segments.
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
/// - [WaypointBuilder] for the underlying path algorithm
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
  ({Offset start, List<PathSegment> segments}) createDefaultSegments(
    ConnectionPathParameters params,
  ) {
    // Use WaypointBuilder for all routing scenarios
    // Use EFFECTIVE positions for bidirectional port support
    // Use sourceOffset/targetOffset for proper temporary connection handling
    final waypoints = WaypointBuilder.calculateWaypoints(
      start: params.start,
      end: params.end,
      sourcePosition: params.effectiveSourcePosition,
      targetPosition: params.effectiveTargetPosition,
      offset: params.offset,
      sourceOffset: params.sourceOffset,
      targetOffset: params.targetOffset,
      backEdgeGap: params.backEdgeGap,
      sourceNodeBounds: params.sourceNodeBounds,
      targetNodeBounds: params.targetNodeBounds,
    );

    final optimized = WaypointBuilder.optimizeWaypoints(waypoints);
    final effectiveCornerRadius = params.cornerRadius > 0
        ? params.cornerRadius
        : defaultCornerRadius;
    final segments = WaypointBuilder.waypointsToSegments(
      optimized,
      cornerRadius: effectiveCornerRadius,
    );

    return (start: params.start, segments: segments);
  }

  @override
  ({Offset start, List<PathSegment> segments}) createSegmentsThroughWaypoints(
    List<Offset> waypoints,
    ConnectionPathParameters params,
  ) {
    if (waypoints.isEmpty) {
      return createDefaultSegments(params);
    }

    // If only start and end, use default path
    if (waypoints.length == 2) {
      return createDefaultSegments(params);
    }

    // Create orthogonal path through all waypoints
    // We need to convert the arbitrary control points into orthogonal segments
    final orthogonalWaypoints = _createOrthogonalWaypoints(waypoints);

    // Generate segments with rounded corners
    final effectiveCornerRadius = params.cornerRadius > 0
        ? params.cornerRadius
        : defaultCornerRadius;
    final segments = _generateSmoothSegments(
      orthogonalWaypoints,
      effectiveCornerRadius,
    );

    return (start: waypoints.first, segments: segments);
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

  /// Generates segments with rounded corners through waypoints.
  ///
  /// This creates PathSegments with quadratic bezier curves at corners
  /// to create the smooth step appearance.
  List<PathSegment> _generateSmoothSegments(
    List<Offset> waypoints,
    double cornerRadius,
  ) {
    if (waypoints.length < 2) {
      return [];
    }

    if (waypoints.length == 2) {
      // Simple direct line
      return [StraightSegment(end: waypoints.last)];
    }

    // If corner radius is 0, just create straight segments
    if (cornerRadius == 0) {
      final segments = <PathSegment>[];
      for (int i = 1; i < waypoints.length; i++) {
        segments.add(StraightSegment(end: waypoints[i]));
      }
      return segments;
    }

    // Generate segments with rounded corners at waypoints
    final segments = <PathSegment>[];

    for (int i = 1; i < waypoints.length - 1; i++) {
      final prev = waypoints[i - 1];
      final current = waypoints[i];
      final next = waypoints[i + 1];

      // Calculate vectors
      final incomingVector = current - prev;
      final outgoingVector = next - current;

      // Skip if vectors are zero (duplicate points)
      if (incomingVector.distance < 0.01 || outgoingVector.distance < 0.01) {
        segments.add(StraightSegment(end: current));
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
          // Too small for a curve, just add straight segment
          segments.add(StraightSegment(end: current));
          continue;
        }

        // Calculate unit vectors
        final incomingDirection = incomingVector / incomingDistance;
        final outgoingDirection = outgoingVector / outgoingDistance;

        // Calculate corner start and end points
        final cornerStart = current - (incomingDirection * actualRadius);
        final cornerEnd = current + (outgoingDirection * actualRadius);

        // Add straight segment to corner start
        segments.add(StraightSegment(end: cornerStart));

        // Add quadratic bezier curve for the corner
        // Skip hit test rects - corner is already covered by adjacent straight segments
        segments.add(
          QuadraticSegment(
            controlPoint: current,
            end: cornerEnd,
            generateHitTestRects: false,
          ),
        );
      } else {
        // Not a perpendicular corner, just add straight segment
        segments.add(StraightSegment(end: current));
      }
    }

    // Add final segment to the last point
    segments.add(StraightSegment(end: waypoints.last));

    return segments;
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
