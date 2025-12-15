import 'dart:math' as math;
import 'dart:ui';

/// Base class for path segment primitives.
///
/// Path segments represent the building blocks of connection paths.
/// Each segment defines how to draw from the current point to [end],
/// and knows how to generate its own hit test rectangles.
///
/// ## Available Segment Types
///
/// - [StraightSegment]: Direct line to endpoint
/// - [QuadraticSegment]: Quadratic bezier curve (one control point)
/// - [CubicSegment]: Cubic bezier curve (two control points)
///
/// ## Usage Example
///
/// ```dart
/// final segments = <PathSegment>[
///   StraightSegment(end: Offset(100, 50)),  // Horizontal segment
///   QuadraticSegment(
///     controlPoint: Offset(100, 75),
///     end: Offset(100, 100),
///     generateHitTestRects: false,  // Corner already covered by adjacent segments
///   ),  // Rounded corner
///   StraightSegment(end: Offset(60, 100)), // Vertical segment
/// ];
/// ```
sealed class PathSegment {
  const PathSegment({required this.end, this.generateHitTestRects = true});

  /// The endpoint of this segment.
  final Offset end;

  /// Whether to generate hit test rectangles for this segment.
  ///
  /// Set to `false` for segments that are already covered by adjacent
  /// segments' hit areas (e.g., small corner curves in step connections).
  final bool generateHitTestRects;

  /// Multiplier for determining maximum hit test rectangle size.
  ///
  /// Hit test rectangles are capped at `tolerance * hitTestSizeMultiplier`
  /// in each dimension. This ensures rectangles stay reasonably sized
  /// while still providing good hit detection coverage.
  ///
  /// Used by [StraightSegment] for diagonal lines and [CubicSegment]
  /// for bezier curves.
  static const double hitTestSizeMultiplier = 3.0;

  /// Returns the maximum hit test box dimension for a given tolerance.
  ///
  /// This is a convenience method that applies [hitTestSizeMultiplier]
  /// to the tolerance value.
  static double maxHitTestSize(double tolerance) =>
      tolerance * hitTestSizeMultiplier;

  /// Generates hit test rectangles for this segment.
  ///
  /// [start] is the starting point of this segment.
  /// [tolerance] is the hit test tolerance (half-width of the hit area).
  ///
  /// Returns a list of rectangles that cover the segment path.
  List<Rect> getHitTestRects(Offset start, double tolerance);
}

/// A straight line segment from the current point to [end].
///
/// This is the simplest segment type, creating a direct line.
/// Used for:
/// - Port extensions (the straight part coming out of a port)
/// - Horizontal and vertical routing segments
/// - Diagonal connections
class StraightSegment extends PathSegment {
  const StraightSegment({
    required super.end,
    super.generateHitTestRects,
  });

  @override
  List<Rect> getHitTestRects(Offset start, double tolerance) {
    if (!generateHitTestRects) return [];

    final dx = end.dx - start.dx;
    final dy = end.dy - start.dy;
    final length = math.sqrt(dx * dx + dy * dy);

    // Skip zero-length segments
    if (length < 0.1) return [];

    // Axis-aligned segments get a single rectangle
    final isHorizontal = dy.abs() < 0.5;
    final isVertical = dx.abs() < 0.5;

    if (isHorizontal || isVertical) {
      return [
        Rect.fromLTRB(
          math.min(start.dx, end.dx) - tolerance,
          math.min(start.dy, end.dy) - tolerance,
          math.max(start.dx, end.dx) + tolerance,
          math.max(start.dy, end.dy) + tolerance,
        ),
      ];
    }

    // Diagonal segment - check perpendicular expansion
    final cosAngle = dx.abs() / length;
    final sinAngle = dy.abs() / length;
    final minTrigComponent = math.min(sinAngle, cosAngle);
    final perpExpansion = length * minTrigComponent + 2 * tolerance;

    // Limit perpendicular expansion using shared max size
    final maxAllowedPerpExpansion = PathSegment.maxHitTestSize(tolerance);

    if (perpExpansion <= maxAllowedPerpExpansion) {
      return [_createDiagonalRect(start, end, tolerance)];
    }

    // Split diagonal into smaller segments
    final segmentCount = (perpExpansion / maxAllowedPerpExpansion).ceil();
    final rects = <Rect>[];

    for (int i = 0; i < segmentCount; i++) {
      final t1 = i / segmentCount;
      final t2 = (i + 1) / segmentCount;
      final p1 = Offset(start.dx + dx * t1, start.dy + dy * t1);
      final p2 = Offset(start.dx + dx * t2, start.dy + dy * t2);
      rects.add(_createDiagonalRect(p1, p2, tolerance));
    }

    return rects;
  }

  /// Creates a tight rectangle for a diagonal line.
  static Rect _createDiagonalRect(Offset p1, Offset p2, double tolerance) {
    final dx = p2.dx - p1.dx;
    final dy = p2.dy - p1.dy;
    final length = math.sqrt(dx * dx + dy * dy);

    if (length < 0.001) {
      return Rect.fromCenter(
        center: p1,
        width: tolerance * 2,
        height: tolerance * 2,
      );
    }

    // Perpendicular direction (normalized)
    final perpX = -dy / length;
    final perpY = dx / length;

    // Four corners at ±tolerance perpendicular to each endpoint
    final corners = [
      Offset(p1.dx + perpX * tolerance, p1.dy + perpY * tolerance),
      Offset(p1.dx - perpX * tolerance, p1.dy - perpY * tolerance),
      Offset(p2.dx + perpX * tolerance, p2.dy + perpY * tolerance),
      Offset(p2.dx - perpX * tolerance, p2.dy - perpY * tolerance),
    ];

    double minX = corners[0].dx;
    double maxX = corners[0].dx;
    double minY = corners[0].dy;
    double maxY = corners[0].dy;

    for (final corner in corners) {
      if (corner.dx < minX) minX = corner.dx;
      if (corner.dx > maxX) maxX = corner.dx;
      if (corner.dy < minY) minY = corner.dy;
      if (corner.dy > maxY) maxY = corner.dy;
    }

    return Rect.fromLTRB(minX, minY, maxX, maxY);
  }

  @override
  String toString() => 'StraightSegment(end: $end)';
}

/// A quadratic bezier curve segment.
///
/// Uses a single [controlPoint] to define the curve shape.
/// The curve starts from the current point, is pulled toward
/// [controlPoint], and ends at [end].
///
/// Used for:
/// - Rounded corners in step/smoothstep connections
/// - Simple curved transitions
class QuadraticSegment extends PathSegment {
  const QuadraticSegment({
    required this.controlPoint,
    required super.end,
    super.generateHitTestRects,
  });

  /// The control point that defines the curve shape.
  final Offset controlPoint;

  @override
  List<Rect> getHitTestRects(Offset start, double tolerance) {
    if (!generateHitTestRects) return [];

    // For quadratic bezier (typically small rounded corners), a single
    // bounding rectangle that encompasses start, control point, and end
    // is sufficient. No need for curve sampling.
    final minX = math.min(start.dx, math.min(controlPoint.dx, end.dx));
    final maxX = math.max(start.dx, math.max(controlPoint.dx, end.dx));
    final minY = math.min(start.dy, math.min(controlPoint.dy, end.dy));
    final maxY = math.max(start.dy, math.max(controlPoint.dy, end.dy));

    return [
      Rect.fromLTRB(
        minX - tolerance,
        minY - tolerance,
        maxX + tolerance,
        maxY + tolerance,
      ),
    ];
  }

  @override
  String toString() =>
      'QuadraticSegment(controlPoint: $controlPoint, end: $end)';
}

/// A cubic bezier curve segment.
///
/// Uses two control points ([controlPoint1] and [controlPoint2]) to define
/// a more complex curve shape. This is the standard bezier curve used in
/// most vector graphics.
///
/// Used for:
/// - Smooth bezier connections
/// - Complex curved paths
class CubicSegment extends PathSegment {
  const CubicSegment({
    required this.controlPoint1,
    required this.controlPoint2,
    required super.end,
    this.curvature = 0.5,
    super.generateHitTestRects,
  });

  /// First control point (influences the curve near the start).
  final Offset controlPoint1;

  /// Second control point (influences the curve near the end).
  final Offset controlPoint2;

  /// The curvature factor used to create this segment (0.0 to 1.0).
  /// Higher values mean sharper curves that need more hit test segments.
  final double curvature;

  @override
  List<Rect> getHitTestRects(Offset start, double tolerance) {
    if (!generateHitTestRects) return [];

    // Maximum perpendicular expansion allowed (same constraint as StraightSegment)
    final maxPerpExpansion = PathSegment.maxHitTestSize(tolerance);

    // Calculate chord from start to end
    final chordDx = end.dx - start.dx;
    final chordDy = end.dy - start.dy;
    final chordLength = math.sqrt(chordDx * chordDx + chordDy * chordDy);

    // Very short curves - single rectangle
    if (chordLength < 0.1) {
      return [
        Rect.fromCenter(
          center: start,
          width: tolerance * 2,
          height: tolerance * 2,
        ),
      ];
    }

    // Calculate AABB for small curve check
    final aabb = _boundingBox(start);

    // For very small curves (both dimensions within perpendicular limit), single rectangle
    if (aabb.width < maxPerpExpansion && aabb.height < maxPerpExpansion) {
      return [aabb.inflate(tolerance)];
    }

    // Calculate maximum perpendicular deviation from chord
    // This tells us how "curved" the path is
    final maxDeviation = _maxDeviationFromChord(
      start,
      chordDx,
      chordDy,
      chordLength,
    );

    // Calculate chord "diagonality" - same approach as StraightSegment
    // minTrigComponent is ~0 for horizontal/vertical, ~0.707 for 45° diagonal
    final cosAngle = chordDx.abs() / chordLength;
    final sinAngle = chordDy.abs() / chordLength;
    final minTrigComponent = math.min(sinAngle, cosAngle);

    // Perpendicular expansion of chord (same formula as StraightSegment)
    // - Horizontal/vertical: ~2*tolerance (minimal)
    // - Diagonal: length * minTrigComponent + 2*tolerance (significant)
    final chordPerpExpansion = chordLength * minTrigComponent + 2 * tolerance;

    // Segment count based on perpendicular expansion constraints:
    // 1. Length-based: ONLY for diagonal curves where perpExpansion exceeds limit
    // 2. Deviation: curves with more bulge need more segments
    // 3. Curvature: higher curvature means sharper curves
    final lengthBasedCount = chordPerpExpansion > maxPerpExpansion
        ? (chordPerpExpansion / maxPerpExpansion).ceil()
        : 1; // Horizontal/vertical curves don't need length-based splitting
    final deviationBasedCount = maxDeviation > 0
        ? math.max(2, (maxDeviation / (maxPerpExpansion / 2)).ceil())
        : 1;
    final curvatureBasedCount = math.max(1, (curvature * 3).ceil());

    final segmentCount = math.max(
      curvatureBasedCount,
      math.max(lengthBasedCount, deviationBasedCount),
    );

    // Generate tight rectangles for each segment (like StraightSegment's diagonal handling)
    final rects = <Rect>[];
    Offset prevPoint = start;

    for (int i = 1; i <= segmentCount; i++) {
      final t = i / segmentCount;
      final point = _evaluate(start, t);

      rects.add(_createTightSegmentRect(prevPoint, point, tolerance));
      prevPoint = point;
    }

    return rects;
  }

  /// Calculates maximum perpendicular deviation of control points from the chord.
  ///
  /// This measures how far the curve bulges from the straight line between
  /// start and end. Higher deviation means we need more segments to maintain
  /// tight hit test rectangles.
  double _maxDeviationFromChord(
    Offset start,
    double chordDx,
    double chordDy,
    double chordLength,
  ) {
    if (chordLength < 0.001) return 0;

    // Perpendicular direction to chord (normalized)
    final perpX = -chordDy / chordLength;
    final perpY = chordDx / chordLength;

    // Calculate perpendicular distance of control points from chord line
    final cp1Offset = Offset(
      controlPoint1.dx - start.dx,
      controlPoint1.dy - start.dy,
    );
    final cp2Offset = Offset(
      controlPoint2.dx - start.dx,
      controlPoint2.dy - start.dy,
    );

    final cp1Perp = (cp1Offset.dx * perpX + cp1Offset.dy * perpY).abs();
    final cp2Perp = (cp2Offset.dx * perpX + cp2Offset.dy * perpY).abs();

    return math.max(cp1Perp, cp2Perp);
  }

  /// Creates a tight rectangle for a segment between two points.
  ///
  /// Uses the same perpendicular expansion approach as [StraightSegment]
  /// for diagonal segments, creating tighter AABBs than simple min/max.
  static Rect _createTightSegmentRect(Offset p1, Offset p2, double tolerance) {
    final dx = p2.dx - p1.dx;
    final dy = p2.dy - p1.dy;
    final length = math.sqrt(dx * dx + dy * dy);

    if (length < 0.001) {
      return Rect.fromCenter(
        center: p1,
        width: tolerance * 2,
        height: tolerance * 2,
      );
    }

    // For axis-aligned segments, use simple AABB
    final isHorizontal = dy.abs() < 0.5;
    final isVertical = dx.abs() < 0.5;

    if (isHorizontal || isVertical) {
      return Rect.fromLTRB(
        math.min(p1.dx, p2.dx) - tolerance,
        math.min(p1.dy, p2.dy) - tolerance,
        math.max(p1.dx, p2.dx) + tolerance,
        math.max(p1.dy, p2.dy) + tolerance,
      );
    }

    // Diagonal segment - use perpendicular expansion approach
    // (same logic as StraightSegment._createDiagonalRect)
    final perpX = -dy / length;
    final perpY = dx / length;

    // Four corners at ±tolerance perpendicular to each endpoint
    final corners = [
      Offset(p1.dx + perpX * tolerance, p1.dy + perpY * tolerance),
      Offset(p1.dx - perpX * tolerance, p1.dy - perpY * tolerance),
      Offset(p2.dx + perpX * tolerance, p2.dy + perpY * tolerance),
      Offset(p2.dx - perpX * tolerance, p2.dy - perpY * tolerance),
    ];

    double minX = corners[0].dx;
    double maxX = corners[0].dx;
    double minY = corners[0].dy;
    double maxY = corners[0].dy;

    for (final corner in corners) {
      if (corner.dx < minX) minX = corner.dx;
      if (corner.dx > maxX) maxX = corner.dx;
      if (corner.dy < minY) minY = corner.dy;
      if (corner.dy > maxY) maxY = corner.dy;
    }

    return Rect.fromLTRB(minX, minY, maxX, maxY);
  }

  /// Calculates the bounding box for this cubic bezier curve.
  Rect _boundingBox(Offset start) {
    final minX = math.min(
      start.dx,
      math.min(controlPoint1.dx, math.min(controlPoint2.dx, end.dx)),
    );
    final maxX = math.max(
      start.dx,
      math.max(controlPoint1.dx, math.max(controlPoint2.dx, end.dx)),
    );
    final minY = math.min(
      start.dy,
      math.min(controlPoint1.dy, math.min(controlPoint2.dy, end.dy)),
    );
    final maxY = math.max(
      start.dy,
      math.max(controlPoint1.dy, math.max(controlPoint2.dy, end.dy)),
    );

    return Rect.fromLTRB(minX, minY, maxX, maxY);
  }

  /// Evaluates this cubic bezier curve at parameter t.
  Offset _evaluate(Offset start, double t) {
    final oneMinusT = 1 - t;
    final oneMinusT2 = oneMinusT * oneMinusT;
    final oneMinusT3 = oneMinusT2 * oneMinusT;
    final t2 = t * t;
    final t3 = t2 * t;

    return Offset(
      oneMinusT3 * start.dx +
          3 * oneMinusT2 * t * controlPoint1.dx +
          3 * oneMinusT * t2 * controlPoint2.dx +
          t3 * end.dx,
      oneMinusT3 * start.dy +
          3 * oneMinusT2 * t * controlPoint1.dy +
          3 * oneMinusT * t2 * controlPoint2.dy +
          t3 * end.dy,
    );
  }

  @override
  String toString() =>
      'CubicSegment(cp1: $controlPoint1, cp2: $controlPoint2, end: $end, curvature: $curvature)';
}
