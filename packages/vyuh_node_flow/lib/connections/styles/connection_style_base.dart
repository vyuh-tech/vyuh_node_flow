import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../ports/port.dart';

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

/// Abstract base class for connection styles
///
/// Each connection style encapsulates its own:
/// - Path creation logic
/// - Hit testing capabilities
/// - Bend detection parameters
/// - Optimization strategies
abstract class ConnectionStyle {
  const ConnectionStyle();

  /// Unique identifier for this connection style
  String get id;

  /// Human-readable display name
  String get displayName;

  // === Core Path Creation ===

  /// Creates the geometric path for drawing this connection
  /// This is the main responsibility of each connection style
  Path createPath(ConnectionPathParameters params);

  // === Hit Testing ===

  /// Default hit tolerance for this connection style
  /// Some styles may need different tolerances based on their geometry
  double get defaultHitTolerance => 8.0;

  /// Returns hit test segments as Rects for spatial indexing.
  /// This is the CANONICAL source for hit testing geometry.
  ///
  /// Each segment represents a rectangular hit area along the connection path.
  /// The base implementation samples the path and creates rectangle segments.
  ///
  /// Subclasses MUST override this to provide optimized segment rectangles
  /// based on their specific geometry (e.g., exact bend points for step connections,
  /// curve sampling for bezier connections).
  ///
  /// The path cache calls this once and stores the result. Both the spatial index
  /// and the hit test path are derived from these segments.
  List<Rect> getHitTestSegments(
    Path originalPath,
    double tolerance, {
    ConnectionPathParameters? pathParams,
  }) {
    return _createSegmentsFromPath(originalPath, tolerance);
  }

  /// Creates a hit test path from segment rectangles.
  /// Derives the path FROM [getHitTestSegments].
  Path createHitTestPathFromSegments(List<Rect> segments) {
    if (segments.isEmpty) return Path();

    final path = Path();
    for (final segment in segments) {
      path.addRect(segment);
    }
    return path;
  }

  /// Creates segment rectangles by sampling points along the path.
  /// Works for any path shape by using path metrics.
  List<Rect> _createSegmentsFromPath(Path path, double tolerance) {
    final bounds = path.getBounds();
    if (bounds.width <= 0 && bounds.height <= 0) {
      return [];
    }

    final metrics = path.computeMetrics().toList();
    if (metrics.isEmpty) {
      return [bounds.inflate(tolerance)];
    }

    final segments = <Rect>[];

    for (final metric in metrics) {
      if (metric.length == 0) continue;

      // Determine segment count based on path length
      final segmentCount = math.min(
        10,
        math.max(3, (metric.length / 50).ceil()),
      );
      final segmentLength = metric.length / segmentCount;

      for (int i = 0; i < segmentCount; i++) {
        final startOffset = i * segmentLength;
        final endOffset = math.min((i + 1) * segmentLength, metric.length);

        final startTangent = metric.getTangentForOffset(startOffset);
        final endTangent = metric.getTangentForOffset(endOffset);

        if (startTangent != null && endTangent != null) {
          final segmentRect = _createSegmentRect(
            startTangent.position,
            endTangent.position,
            tolerance,
          );
          segments.add(segmentRect);
        }
      }
    }

    return segments;
  }

  /// Creates a rectangle around a line segment with given tolerance.
  Rect _createSegmentRect(Offset start, Offset end, double tolerance) {
    final minX = math.min(start.dx, end.dx) - tolerance;
    final maxX = math.max(start.dx, end.dx) + tolerance;
    final minY = math.min(start.dy, end.dy) - tolerance;
    final maxY = math.max(start.dy, end.dy) + tolerance;
    return Rect.fromLTRB(minX, minY, maxX, maxY);
  }

  // === Bend Detection (for caching optimization) ===

  /// Whether this connection style needs bend detection for hit testing optimization
  bool get needsBendDetection => true;

  /// Whether this connection style has predictable bend points that can be calculated exactly
  bool get hasExactBendPoints => false;

  /// Get exact bend points for styles that support it (e.g., step connections)
  /// Returns null if the style doesn't support exact bend point calculation
  List<Offset>? getExactBendPoints(ConnectionPathParameters params) => null;

  /// Get bend detection threshold angle in radians
  /// Used for detecting significant direction changes in the path
  double get bendThreshold => math.pi / 6; // 30 degrees default

  /// Get number of samples to use for bend detection based on path length
  int getSampleCount(double pathLength) {
    return math.min(15, math.max(3, (pathLength / 30).ceil()));
  }

  /// Get minimum distance between bend points as multiplier of tolerance
  double get minBendDistance => 4.0;

  // === Style Comparison ===

  /// Check if two connection styles are equivalent
  /// This is used for caching decisions and theme comparisons
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
