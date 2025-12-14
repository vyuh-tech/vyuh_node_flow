import 'dart:ui';

import 'package:flutter/material.dart';

import '../../ports/port.dart';
import 'waypoint_builder.dart';

/// Parameters for connection path creation
class ConnectionPathParameters {
  const ConnectionPathParameters({
    required this.start,
    required this.end,
    required this.curvature,
    this.sourcePort,
    this.targetPort,
    this.cornerRadius = 4.0,
    this.offset = 10.0,
    this.backEdgeGap = 20.0,
    this.controlPoints = const [],
    this.sourceNodeBounds,
    this.targetNodeBounds,
  });

  /// Start point of the connection
  final Offset start;

  /// End point of the connection
  final Offset end;

  /// Curvature parameter for bezier curves (0.0 to 1.0)
  final double curvature;

  /// Source port information (optional)
  final Port? sourcePort;

  /// Target port information (optional)
  final Port? targetPort;

  /// Corner radius for rounded connections
  final double cornerRadius;

  /// Offset distance from ports (port extension)
  final double offset;

  /// Gap from node bounds for loopback/back-edge routing.
  ///
  /// When a connection needs to route around nodes, this value determines
  /// the clearance from the node bounds. Independent of [offset] which
  /// controls the initial straight segment from the port.
  final double backEdgeGap;

  /// Control points for editable path connections
  final List<Offset> controlPoints;

  /// Bounds of the source node for node-aware routing.
  ///
  /// When provided, the waypoint calculator uses this to ensure connections
  /// route around the node bounds rather than through them.
  final Rect? sourceNodeBounds;

  /// Bounds of the target node for node-aware routing.
  ///
  /// When provided, the waypoint calculator uses this to ensure connections
  /// route around the node bounds rather than through them.
  final Rect? targetNodeBounds;

  /// Get source port position, defaulting to right if not specified
  PortPosition get sourcePosition => sourcePort?.position ?? PortPosition.right;

  /// Get target port position, defaulting to left if not specified
  PortPosition get targetPosition => targetPort?.position ?? PortPosition.left;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ConnectionPathParameters &&
          runtimeType == other.runtimeType &&
          start == other.start &&
          end == other.end &&
          curvature == other.curvature &&
          sourcePort == other.sourcePort &&
          targetPort == other.targetPort &&
          cornerRadius == other.cornerRadius &&
          offset == other.offset &&
          backEdgeGap == other.backEdgeGap &&
          _listEquals(controlPoints, other.controlPoints) &&
          sourceNodeBounds == other.sourceNodeBounds &&
          targetNodeBounds == other.targetNodeBounds;

  @override
  int get hashCode => Object.hash(
    start,
    end,
    curvature,
    sourcePort,
    targetPort,
    cornerRadius,
    offset,
    backEdgeGap,
    Object.hashAll(controlPoints),
    sourceNodeBounds,
    targetNodeBounds,
  );

  /// Helper to compare two lists
  bool _listEquals(List<Offset> a, List<Offset> b) {
    if (a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}

/// Abstract base class for connection styles.
///
/// ## Single Responsibility: Create Segments
///
/// A connection style has ONE job: **create path segments** from parameters.
/// That's it. Everything else (path generation, hit testing, bend points)
/// is derived from segments using utility methods.
///
/// ## Architecture
///
/// ```
/// final result = style.createSegments(params);  // Call ONCE
///   ↓
///   ├─→ style.buildPath(result.start, result.segments) → Path
///   ├─→ style.buildHitTestRects(result.start, result.segments, tolerance) → List<Rect>
///   └─→ style.extractBendPoints(result.start, result.segments) → List<Offset>
/// ```
///
/// ## Usage
///
/// Callers (like ConnectionPathCache) should:
/// 1. Call `createSegments(params)` ONCE to get the segments
/// 2. Store/cache the segments
/// 3. Use static utility methods to derive path, hit test rects, etc.
///
/// ## Example Implementation
///
/// ```dart
/// class MyConnectionStyle extends ConnectionStyle {
///   @override
///   String get id => 'my-style';
///
///   @override
///   String get displayName => 'My Style';
///
///   @override
///   ({Offset start, List<PathSegment> segments}) createSegments(
///     ConnectionPathParameters params,
///   ) {
///     // Calculate waypoints
///     final waypoints = WaypointBuilder.calculateWaypoints(...);
///     // Convert to segments
///     final segments = WaypointBuilder.waypointsToSegments(waypoints);
///     return (start: params.start, segments: segments);
///   }
/// }
/// ```
abstract class ConnectionStyle {
  const ConnectionStyle();

  /// Unique identifier for this connection style
  String get id;

  /// Human-readable display name
  String get displayName;

  // === Core Contract: Create Segments ===

  /// Creates the path segments for this connection.
  ///
  /// **This is the ONLY method that subclasses MUST implement.**
  ///
  /// Returns a tuple of:
  /// - `start`: The starting point of the path
  /// - `segments`: The list of path segments
  ///
  /// All derived operations (path, hit test, bend points) use the segments
  /// returned by this method via static utility methods.
  ({Offset start, List<PathSegment> segments}) createSegments(
    ConnectionPathParameters params,
  );

  // === Build Methods (operate on segments, overridable) ===

  /// Builds a Path from segments.
  ///
  /// Override to customize path generation for special segment handling
  /// or to add post-processing like smoothing or decorations.
  ///
  /// Default implementation uses [WaypointBuilder.generatePathFromSegments].
  Path buildPath(Offset start, List<PathSegment> segments) {
    return WaypointBuilder.generatePathFromSegments(
      start: start,
      segments: segments,
    );
  }

  /// Builds hit test rectangles from segments.
  ///
  /// Override to customize hit test geometry for special requirements
  /// like wider hit areas for touch interfaces.
  ///
  /// Default implementation uses [WaypointBuilder.generateHitTestFromSegments].
  List<Rect> buildHitTestRects(
    Offset start,
    List<PathSegment> segments,
    double tolerance,
  ) {
    return WaypointBuilder.generateHitTestFromSegments(
      start: start,
      segments: segments,
      tolerance: tolerance,
    );
  }

  /// Extracts bend points from segments.
  ///
  /// Bend points are the start point plus the endpoints of each segment,
  /// representing corners and turns in the connection path.
  ///
  /// Override to customize bend point extraction for special segment types.
  List<Offset> extractBendPoints(Offset start, List<PathSegment> segments) {
    if (segments.isEmpty) return [start];

    final bendPoints = <Offset>[start];
    for (final segment in segments) {
      bendPoints.add(segment.end);
    }
    return bendPoints;
  }

  /// Builds a hit test path from rectangle bounds.
  ///
  /// Useful for debug visualization of hit test areas.
  /// Override to customize how hit test rectangles are combined into a path.
  Path buildHitTestPath(List<Rect> rects) {
    if (rects.isEmpty) return Path();

    final path = Path();
    for (final rect in rects) {
      path.addRect(rect);
    }
    return path;
  }

  // === Style Properties ===

  /// Default hit tolerance for this connection style.
  /// Some styles may need different tolerances based on their geometry.
  double get defaultHitTolerance => 8.0;

  // === Style Comparison ===

  /// Check if two connection styles are equivalent.
  /// This is used for caching decisions and theme comparisons.
  bool isEquivalentTo(ConnectionStyle other) {
    return runtimeType == other.runtimeType && id == other.id;
  }

  @override
  String toString() => 'ConnectionStyle(id: $id, displayName: $displayName)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ConnectionStyle &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => Object.hash(runtimeType, id);
}
