import 'dart:ui';

import '../connection.dart';
import 'connection_style_base.dart';

/// Abstract base class for connection styles that support interactive editing
/// of connection paths through control points.
///
/// This class extends [ConnectionStyle] to add support for user-defined waypoints
/// (control points) that allow customization of the connection path. Concrete
/// implementations define how paths are created through these waypoints.
///
/// ## Control Points
///
/// Control points are intermediate waypoints through which the connection path
/// should pass. They are stored in the [Connection.controlPoints] list and allow
/// users to:
/// - Add extra bends to the connection
/// - Move existing bends to customize the path
/// - Remove waypoints to simplify the path
///
/// ## Path Creation Strategy
///
/// Editable path styles support two modes:
/// 1. **Algorithmic mode** (no control points): Uses the default path algorithm
/// 2. **Manual mode** (with control points): Creates path through user-defined waypoints
///
/// ## Implementation Requirements
///
/// Concrete subclasses must implement:
/// - [createPathThroughWaypoints]: How to create a path through control points
/// - Optionally override [requiresControlPoints] if the style only works in manual mode
///
/// ## Example
///
/// ```dart
/// class EditableSmoothStepConnectionStyle extends EditablePathConnectionStyle {
///   @override
///   String get id => 'editable-smoothstep';
///
///   @override
///   String get displayName => 'Editable Smooth Step';
///
///   @override
///   Path createPathThroughWaypoints(
///     List<Offset> waypoints,
///     ConnectionPathParameters params,
///   ) {
///     // Generate smooth step path through waypoints with rounded corners
///     return _generateSmoothPath(waypoints, params.cornerRadius);
///   }
/// }
/// ```
abstract class EditablePathConnectionStyle extends ConnectionStyle {
  const EditablePathConnectionStyle();

  /// Whether this style requires control points to function.
  ///
  /// If true, the style cannot fall back to algorithmic path creation.
  /// Most editable styles should return false to allow both modes.
  bool get requiresControlPoints => false;

  /// Creates a path through the given waypoints.
  ///
  /// This method is called when control points are provided or when the
  /// algorithmic path has been converted to waypoints for editing.
  ///
  /// Parameters:
  /// - [waypoints]: List of points the path should pass through, including
  ///   start and end points
  /// - [params]: Original connection parameters for context (curvature,
  ///   corner radius, etc.)
  ///
  /// Returns: A [Path] that connects all waypoints according to the style's
  /// visual characteristics (e.g., smooth curves, sharp angles, etc.)
  Path createPathThroughWaypoints(
    List<Offset> waypoints,
    ConnectionPathParameters params,
  );

  /// Creates a path for this connection, using control points if available.
  ///
  /// This method is the main entry point called by the rendering system.
  /// It delegates to either:
  /// - [createPathThroughWaypoints] if control points are provided
  /// - [createDefaultPath] if no control points exist
  @override
  Path createPath(ConnectionPathParameters params) {
    if (params.controlPoints.isNotEmpty) {
      // Manual mode: use control points as waypoints
      // IMPORTANT: Include start and end points in the waypoints list
      final waypoints = createWaypointsWithEnds(params.controlPoints, params);
      return createPathThroughWaypoints(waypoints, params);
    } else if (!requiresControlPoints) {
      // Algorithmic mode: use default path creation
      return createDefaultPath(params);
    } else {
      // Style requires control points but none provided
      // Fall back to simple straight line
      final path = Path();
      path.moveTo(params.start.dx, params.start.dy);
      path.lineTo(params.end.dx, params.end.dy);
      return path;
    }
  }

  /// Creates the default algorithmic path when no control points are provided.
  ///
  /// Subclasses should implement this to define their default routing algorithm.
  /// This can be overridden to return a simple path or to use sophisticated
  /// routing logic similar to the non-editable version of the style.
  ///
  /// The default implementation creates a straight line from start to end.
  Path createDefaultPath(ConnectionPathParameters params) {
    final path = Path();
    path.moveTo(params.start.dx, params.start.dy);
    path.lineTo(params.end.dx, params.end.dy);
    return path;
  }

  /// Helper method to create waypoints including start and end points.
  ///
  /// This ensures the waypoints list always starts at [params.start] and
  /// ends at [params.end], with control points in between.
  List<Offset> createWaypointsWithEnds(
    List<Offset> controlPoints,
    ConnectionPathParameters params,
  ) {
    if (controlPoints.isEmpty) {
      return [params.start, params.end];
    }

    // Ensure start and end are included
    final waypoints = <Offset>[params.start];
    waypoints.addAll(controlPoints);
    waypoints.add(params.end);

    return waypoints;
  }

  /// Calculates the position along a path for inserting new control points.
  ///
  /// This helper method finds the point on the connection path at the given
  /// [position] (0.0 to 1.0), which is useful for adding control points at
  /// specific locations along the path.
  ///
  /// Returns null if the position cannot be calculated.
  Offset? calculatePointAtPosition(Path path, double position) {
    final metrics = path.computeMetrics().toList();
    if (metrics.isEmpty) return null;

    // Get total length across all contours
    final totalLength = metrics.fold<double>(
      0,
      (sum, metric) => sum + metric.length,
    );

    if (totalLength == 0) return null;

    // Find the position along the total length
    final targetDistance = totalLength * position;

    // Find which contour contains this distance
    var currentDistance = 0.0;
    for (final metric in metrics) {
      if (currentDistance + metric.length >= targetDistance) {
        // Found the right contour
        final localDistance = targetDistance - currentDistance;
        final tangent = metric.getTangentForOffset(localDistance);
        return tangent?.position;
      }
      currentDistance += metric.length;
    }

    return null;
  }
}
