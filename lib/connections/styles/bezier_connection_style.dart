import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../ports/port.dart';
import '../connection_style_base.dart';

/// Bezier curve connection style
///
/// Creates smooth curved connections using cubic bezier curves.
/// Control points are calculated based on port positions and curvature settings.
class BezierConnectionStyle extends ConnectionStyle {
  const BezierConnectionStyle();

  @override
  String get id => 'bezier';

  @override
  String get displayName => 'Bezier';

  @override
  Path createPath(PathParameters params) {
    final path = Path();
    path.moveTo(params.start.dx, params.start.dy);

    _createBezierPath(
      path,
      params.start,
      params.end,
      params.curvature,
      params.sourcePort,
      params.targetPort,
    );

    return path;
  }

  @override
  bool get needsBendDetection => true; // Curves need bend detection for hit testing

  @override
  double get bendThreshold => math.pi / 9; // 20 degrees - sensitive for bezier curves

  @override
  int getSampleCount(double pathLength) {
    // More samples for curves to detect subtle bends
    return math.min(20, math.max(5, (pathLength / 20).ceil()));
  }

  @override
  double get minBendDistance => 3.0; // Closer segments for precise curves

  @override
  Path createHitTestPath(Path originalPath, double tolerance) {
    // For bezier curves, we need to create segmented hit areas
    // because the curve can have varying thickness perception
    return _createBezierHitTestPath(originalPath, tolerance);
  }

  /// Creates the bezier curve path
  void _createBezierPath(
    Path path,
    Offset start,
    Offset end,
    double curvature,
    Port? sourcePort,
    Port? targetPort,
  ) {
    // Calculate control points using the same method as the original calculator
    final cp1 = _getControlWithCurvature(
      position: sourcePort?.position ?? PortPosition.right,
      x1: start.dx,
      y1: start.dy,
      x2: end.dx,
      y2: end.dy,
      curvature: curvature,
    );

    final cp2 = _getControlWithCurvature(
      position: targetPort?.position ?? PortPosition.left,
      x1: end.dx,
      y1: end.dy,
      x2: start.dx,
      y2: start.dy,
      curvature: curvature,
    );

    path.cubicTo(cp1.dx, cp1.dy, cp2.dx, cp2.dy, end.dx, end.dy);
  }

  /// Calculate control point with curvature based on port position
  Offset _getControlWithCurvature({
    required PortPosition position,
    required double x1,
    required double y1,
    required double x2,
    required double y2,
    required double curvature,
  }) {
    switch (position) {
      case PortPosition.left:
        return Offset(x1 - _calculateControlOffset(x1 - x2, curvature), y1);
      case PortPosition.right:
        return Offset(x1 + _calculateControlOffset(x2 - x1, curvature), y1);
      case PortPosition.top:
        return Offset(x1, y1 - _calculateControlOffset(y1 - y2, curvature));
      case PortPosition.bottom:
        return Offset(x1, y1 + _calculateControlOffset(y2 - y1, curvature));
    }
  }

  /// Calculate control point offset distance
  double _calculateControlOffset(double distance, double curvature) {
    if (distance >= 0) {
      return 0.1 * distance;
    }
    return curvature * 16 * math.sqrt(-distance);
  }

  /// Create sophisticated hit test path for bezier curves
  Path _createBezierHitTestPath(Path originalPath, double tolerance) {
    final bounds = originalPath.getBounds();

    if (bounds.width <= 0 && bounds.height <= 0) {
      return Path();
    }

    final metrics = originalPath.computeMetrics().toList();
    if (metrics.isEmpty) {
      return Path()..addRect(bounds.inflate(tolerance));
    }

    final combinedHitPath = Path();

    for (final metric in metrics) {
      if (metric.length == 0) continue;

      // For bezier curves, create multiple segments for better hit detection
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
          final segmentHitArea = _createCurveSegmentHitArea(
            startTangent.position,
            endTangent.position,
            tolerance,
          );
          combinedHitPath.addPath(segmentHitArea, Offset.zero);
        }
      }
    }

    return combinedHitPath;
  }

  /// Create hit area for a curve segment
  Path _createCurveSegmentHitArea(Offset start, Offset end, double tolerance) {
    final dx = end.dx - start.dx;
    final dy = end.dy - start.dy;
    final length = math.sqrt(dx * dx + dy * dy);

    if (length == 0) {
      // Point segment - create circular hit area
      return Path()..addOval(
        Rect.fromCenter(
          center: start,
          width: tolerance * 2,
          height: tolerance * 2,
        ),
      );
    }

    // Create rectangular hit area around the segment
    // For curves, we use a slightly larger tolerance to account for perception
    final adjustedTolerance = tolerance * 1.2;
    final perpX = -dy / length * adjustedTolerance;
    final perpY = dx / length * adjustedTolerance;

    return Path()
      ..moveTo(start.dx + perpX, start.dy + perpY)
      ..lineTo(end.dx + perpX, end.dy + perpY)
      ..lineTo(end.dx - perpX, end.dy - perpY)
      ..lineTo(start.dx - perpX, start.dy - perpY)
      ..close();
  }
}

/// Custom bezier connection style with user-controlled parameters
///
/// Allows for more advanced bezier curve customization beyond the basic style.
class CustomBezierConnectionStyle extends BezierConnectionStyle {
  const CustomBezierConnectionStyle({
    this.customCurvatureFactor = 1.0,
    this.asymmetricControls = false,
  });

  /// Custom curvature factor multiplier (default 1.0)
  final double customCurvatureFactor;

  /// Whether to use asymmetric control points for more complex curves
  final bool asymmetricControls;

  @override
  String get id => 'customBezier';

  @override
  String get displayName => 'Custom Bezier';

  @override
  Path createPath(PathParameters params) {
    final path = Path();
    path.moveTo(params.start.dx, params.start.dy);

    // Use custom curvature factor
    final adjustedCurvature = params.curvature * customCurvatureFactor;

    _createBezierPath(
      path,
      params.start,
      params.end,
      adjustedCurvature,
      params.sourcePort,
      params.targetPort,
    );

    return path;
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      super == other &&
          other is CustomBezierConnectionStyle &&
          customCurvatureFactor == other.customCurvatureFactor &&
          asymmetricControls == other.asymmetricControls;

  @override
  int get hashCode =>
      Object.hash(super.hashCode, customCurvatureFactor, asymmetricControls);
}
