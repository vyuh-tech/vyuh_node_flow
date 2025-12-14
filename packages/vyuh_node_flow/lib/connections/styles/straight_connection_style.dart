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
///
/// ## Segment-Based Architecture
///
/// This style implements [createSegments] as the primary method.
/// All path rendering, hit testing, and bend detection derive from
/// the segments calculated once - eliminating redundant calculations.
class StraightConnectionStyle extends ConnectionStyle {
  const StraightConnectionStyle();

  @override
  String get id => 'straight';

  @override
  String get displayName => 'Straight';

  @override
  ({Offset start, List<PathSegment> segments}) createSegments(
    ConnectionPathParameters params,
  ) {
    // Check if we need loopback routing (target behind source, same-side ports, etc.)
    if (WaypointBuilder.needsLoopbackRouting(params)) {
      // Use shared loopback routing - produces clean step-based routing
      final segments = WaypointBuilder.buildLoopbackSegments(params);
      return (start: params.start, segments: segments);
    }

    // Forward connection - use simple straight path with extensions
    final segments = _buildForwardStraightSegments(params);
    return (start: params.start, segments: segments);
  }

  /// Builds segments for forward straight connections.
  ///
  /// Creates three segments:
  /// 1. Port to extension point (horizontal/vertical)
  /// 2. Extension to extension (diagonal)
  /// 3. Extension to port (horizontal/vertical)
  List<PathSegment> _buildForwardStraightSegments(
    ConnectionPathParameters params,
  ) {
    final sourcePosition = params.sourcePort?.position ?? PortPosition.right;
    final targetPosition = params.targetPort?.position ?? PortPosition.left;

    // Calculate extension points based on port positions
    final startExtension = _calculateExtensionPoint(
      params.start,
      sourcePosition,
      params.offset,
    );
    final endExtension = _calculateExtensionPoint(
      params.end,
      targetPosition,
      params.offset,
    );

    return [
      StraightSegment(end: startExtension),
      StraightSegment(end: endExtension),
      StraightSegment(end: params.end),
    ];
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

  // === Build methods derive from segments (overridable) ===
  // - buildPath(start, segments) → Path
  // - buildHitTestRects(start, segments, tolerance) → List<Rect>
  // - extractBendPoints(start, segments) → List<Offset>
}
