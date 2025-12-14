import 'package:flutter/material.dart';

import 'connection_style_base.dart';
import 'waypoint_builder.dart';

/// Step connection style (90-degree turns with optional rounded corners)
///
/// Creates connections with 90-degree turns that follow a predictable
/// step pattern based on port positions. The corner radius can be configured
/// to create either sharp corners (0) or smoothly rounded corners (> 0).
///
/// Uses [WaypointBuilder] for all routing scenarios including:
/// - Forward connections
/// - Loopback routing (target behind source)
/// - Self-connections (same node)
/// - Same-side ports (e.g., right→right)
///
/// ## Segment-Based Architecture
///
/// This style implements [createSegments] as the primary method.
/// All path rendering, hit testing, and bend detection derive from
/// the segments calculated once - eliminating redundant calculations.
class StepConnectionStyle extends ConnectionStyle {
  /// Creates a step connection style.
  ///
  /// [cornerRadius] - The radius for rounding corners (default: 0 for sharp corners)
  const StepConnectionStyle({this.cornerRadius = 0});

  /// The radius used for rounding corners.
  /// - 0: Creates sharp 90-degree corners
  /// - > 0: Creates smoothly rounded corners
  final double cornerRadius;

  @override
  String get id => cornerRadius > 0 ? 'smoothstep' : 'step';

  @override
  String get displayName => cornerRadius > 0 ? 'Smooth Step' : 'Step';

  @override
  ({Offset start, List<PathSegment> segments}) createSegments(
    ConnectionPathParameters params,
  ) {
    // Calculate waypoints for all routing scenarios (ONCE)
    final waypoints = WaypointBuilder.calculateWaypoints(
      start: params.start,
      end: params.end,
      sourcePosition: params.sourcePosition,
      targetPosition: params.targetPosition,
      offset: params.offset,
      backEdgeGap: params.backEdgeGap,
      sourceNodeBounds: params.sourceNodeBounds,
      targetNodeBounds: params.targetNodeBounds,
    );

    // Optimize waypoints (remove redundant collinear points)
    final optimized = WaypointBuilder.optimizeWaypoints(waypoints);

    // Determine effective corner radius
    final effectiveCornerRadius = params.cornerRadius > 0
        ? params.cornerRadius
        : cornerRadius;

    // Convert to segments with rounded corners
    final segments = WaypointBuilder.waypointsToSegments(
      optimized,
      cornerRadius: effectiveCornerRadius,
    );

    return (start: params.start, segments: segments);
  }

  // === Build methods derive from segments (overridable) ===
  // - buildPath(start, segments) → Path
  // - buildHitTestRects(start, segments, tolerance) → List<Rect>
  // - extractBendPoints(start, segments) → List<Offset>

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is StepConnectionStyle &&
          runtimeType == other.runtimeType &&
          cornerRadius == other.cornerRadius;

  @override
  int get hashCode => cornerRadius.hashCode;
}
