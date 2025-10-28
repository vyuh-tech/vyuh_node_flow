import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../ports/port.dart';
import '../connection_style_base.dart';

/// Straight line connection style
///
/// Creates direct connections with small extensions from ports.
/// This is the simplest connection style with minimal path computation.
class StraightConnectionStyle extends ConnectionStyle {
  const StraightConnectionStyle();

  @override
  String get id => 'straight';

  @override
  String get displayName => 'Straight';

  @override
  Path createPath(PathParameters params) {
    final path = Path();
    path.moveTo(params.start.dx, params.start.dy);

    _createStraightPath(
      path,
      params.start,
      params.end,
      params.offset,
      params.sourcePort,
      params.targetPort,
    );

    return path;
  }

  @override
  bool get needsBendDetection => false; // Straight lines don't have bends

  @override
  double get bendThreshold => double.infinity; // No bends expected

  @override
  int getSampleCount(double pathLength) => 2; // Just start and end

  @override
  double get minBendDistance => double.infinity; // No multiple bends

  @override
  Path createHitTestPath(Path originalPath, double tolerance) {
    // For straight lines, we can create precise rectangular hit areas
    final bounds = originalPath.getBounds();

    if (bounds.width <= 0 && bounds.height <= 0) {
      return Path();
    }

    // Get the path metrics to extract the actual line
    final metrics = originalPath.computeMetrics().toList();
    if (metrics.isEmpty) {
      return Path()..addRect(bounds.inflate(tolerance));
    }

    final combinedHitPath = Path();

    for (final metric in metrics) {
      if (metric.length == 0) continue;

      final startTangent = metric.getTangentForOffset(0);
      final endTangent = metric.getTangentForOffset(metric.length);

      if (startTangent != null && endTangent != null) {
        final segmentHitPath = _createPreciseHitArea(
          startTangent.position,
          endTangent.position,
          tolerance,
        );
        combinedHitPath.addPath(segmentHitPath, Offset.zero);
      }
    }

    return combinedHitPath;
  }

  /// Creates the straight line path with extensions
  void _createStraightPath(
    Path path,
    Offset start,
    Offset end,
    double offset,
    Port? sourcePort,
    Port? targetPort,
  ) {
    final sourcePosition = sourcePort?.position ?? PortPosition.right;
    final targetPosition = targetPort?.position ?? PortPosition.left;

    // Calculate extension points based on port positions
    final startExtension = _calculateExtensionPoint(
      start,
      sourcePosition,
      offset,
    );
    final endExtension = _calculateExtensionPoint(end, targetPosition, -offset);

    // Draw path with extensions
    path.lineTo(startExtension.dx, startExtension.dy);
    path.lineTo(endExtension.dx, endExtension.dy);
    path.lineTo(end.dx, end.dy);
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

  /// Create precise rectangular hit area for straight connections
  Path _createPreciseHitArea(Offset start, Offset end, double tolerance) {
    final dx = end.dx - start.dx;
    final dy = end.dy - start.dy;
    final length = math.sqrt(dx * dx + dy * dy);

    if (length == 0) {
      // Point connection - create circular hit area
      return Path()..addOval(
        Rect.fromCenter(
          center: start,
          width: tolerance * 2,
          height: tolerance * 2,
        ),
      );
    }

    // Handle perfectly horizontal or vertical lines (use more generous tolerance)
    if (dy.abs() < 1.0) {
      // Horizontal line - create vertical rectangle
      return Path()..addRect(
        Rect.fromLTRB(
          math.min(start.dx, end.dx),
          start.dy - tolerance,
          math.max(start.dx, end.dx),
          start.dy + tolerance,
        ),
      );
    }

    if (dx.abs() < 1.0) {
      // Vertical line - create horizontal rectangle
      return Path()..addRect(
        Rect.fromLTRB(
          start.dx - tolerance,
          math.min(start.dy, end.dy),
          start.dx + tolerance,
          math.max(start.dy, end.dy),
        ),
      );
    }

    // Create rectangular hit area around the diagonal line
    final perpX = -dy / length * tolerance;
    final perpY = dx / length * tolerance;

    return Path()
      ..moveTo(start.dx + perpX, start.dy + perpY)
      ..lineTo(end.dx + perpX, end.dy + perpY)
      ..lineTo(end.dx - perpX, end.dy - perpY)
      ..lineTo(start.dx - perpX, start.dy - perpY)
      ..close();
  }
}
