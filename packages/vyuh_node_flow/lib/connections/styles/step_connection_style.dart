import 'dart:math' as math;
import 'dart:ui' show PathMetric;

import 'package:flutter/material.dart';

import 'connection_style_base.dart';
import 'smoothstep_path_calculator.dart';

/// Step connection style (90-degree turns without rounded corners)
///
/// Creates connections with sharp 90-degree turns that follow a predictable
/// step pattern based on port positions.
class StepConnectionStyle extends ConnectionStyle {
  const StepConnectionStyle();

  @override
  String get id => 'step';

  @override
  String get displayName => 'Step';

  @override
  Path createPath(PathParameters params) {
    return SmoothstepPathCalculator.calculatePath(
      start: params.start,
      end: params.end,
      sourcePosition: params.sourcePosition,
      targetPosition: params.targetPosition,
      offset: params.offset,
      cornerRadius: 0, // No corner radius for step style
    );
  }

  @override
  bool get needsBendDetection => true; // Step paths have predictable bends

  @override
  bool get hasExactBendPoints => true; // Can calculate exact bend points

  @override
  List<Offset>? getExactBendPoints(PathParameters params) {
    return SmoothstepPathCalculator.getBendPoints(
      start: params.start,
      end: params.end,
      sourcePosition: params.sourcePosition,
      targetPosition: params.targetPosition,
      offset: params.offset,
    );
  }

  @override
  double get bendThreshold => math.pi * 70 / 180; // ~70 degrees for 90-degree turns

  @override
  int getSampleCount(double pathLength) {
    // Fewer samples needed since we have exact bend points
    return math.min(12, math.max(3, (pathLength / 25).ceil()));
  }

  @override
  double get minBendDistance => 6.0; // Larger spacing for predictable turns

  @override
  Path createHitTestPath(Path originalPath, double tolerance) {
    // Use optimized hit testing with exact bend points when possible
    final bounds = originalPath.getBounds();

    if (bounds.width <= 0 && bounds.height <= 0) {
      return Path();
    }

    // For step connections, we can use the exact bend points for precise hit testing
    return _createStepHitTestPath(originalPath, tolerance);
  }

  /// Create optimized hit test path using step characteristics
  Path _createStepHitTestPath(Path originalPath, double tolerance) {
    final metrics = originalPath.computeMetrics().toList();
    if (metrics.isEmpty) {
      return Path()..addRect(originalPath.getBounds().inflate(tolerance));
    }

    final combinedHitPath = Path();

    for (final metric in metrics) {
      if (metric.length == 0) continue;

      // For step paths, create rectangular segments between bend points
      final segmentPath = _createStepSegmentHitAreas(metric, tolerance);
      combinedHitPath.addPath(segmentPath, Offset.zero);
    }

    return combinedHitPath;
  }

  /// Create hit areas for step path segments
  Path _createStepSegmentHitAreas(PathMetric metric, double tolerance) {
    final combinedPath = Path();

    // Sample the path at regular intervals to find horizontal/vertical segments
    final sampleCount = math.max(4, (metric.length / 20).ceil());
    final segments = <({Offset start, Offset end})>[];

    Offset? lastPoint;
    for (int i = 0; i <= sampleCount; i++) {
      final offset = (i / sampleCount) * metric.length;
      final tangent = metric.getTangentForOffset(offset);

      if (tangent != null) {
        final currentPoint = tangent.position;
        if (lastPoint != null) {
          segments.add((start: lastPoint, end: currentPoint));
        }
        lastPoint = currentPoint;
      }
    }

    // Create hit areas for each segment
    for (final segment in segments) {
      final hitArea = _createStepSegmentHitArea(
        segment.start,
        segment.end,
        tolerance,
      );
      combinedPath.addPath(hitArea, Offset.zero);
    }

    return combinedPath;
  }

  /// Create hit area for a single step segment (optimized for horizontal/vertical lines)
  Path _createStepSegmentHitArea(Offset start, Offset end, double tolerance) {
    final dx = (end.dx - start.dx).abs();
    final dy = (end.dy - start.dy).abs();

    // Determine if this is primarily horizontal or vertical
    if (dx < 1.0) {
      // Vertical segment
      return Path()..addRect(
        Rect.fromLTRB(
          start.dx - tolerance,
          math.min(start.dy, end.dy),
          start.dx + tolerance,
          math.max(start.dy, end.dy),
        ),
      );
    } else if (dy < 1.0) {
      // Horizontal segment
      return Path()..addRect(
        Rect.fromLTRB(
          math.min(start.dx, end.dx),
          start.dy - tolerance,
          math.max(start.dx, end.dx),
          start.dy + tolerance,
        ),
      );
    } else {
      // Diagonal segment (shouldn't happen in step connections, but handle gracefully)
      final length = math.sqrt(dx * dx + dy * dy);
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

  /// Create optimized hit test path from exact waypoints
  Path createOptimizedHitTestPath(List<Offset> waypoints, double tolerance) {
    if (waypoints.length <= 2) {
      // Simple case: single segment
      return _createStepSegmentHitArea(
        waypoints.first,
        waypoints.last,
        tolerance,
      );
    }

    final combinedPath = Path();

    // Create rectangles for all segments
    for (int i = 0; i < waypoints.length - 1; i++) {
      final segmentPath = _createStepSegmentHitArea(
        waypoints[i],
        waypoints[i + 1],
        tolerance,
      );
      combinedPath.addPath(segmentPath, Offset.zero);
    }

    return combinedPath;
  }
}

/// Smooth step connection style (90-degree turns with rounded corners)
///
/// Similar to step connections but with rounded corners for a smoother appearance.
class SmoothStepConnectionStyle extends StepConnectionStyle {
  const SmoothStepConnectionStyle();

  @override
  String get id => 'smoothstep';

  @override
  String get displayName => 'Smooth Step';

  @override
  Path createPath(PathParameters params) {
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
  Path createHitTestPath(Path originalPath, double tolerance) {
    // For smooth step, we need slightly different hit testing due to rounded corners
    return _createSmoothStepHitTestPath(originalPath, tolerance);
  }

  /// Create hit test path accounting for rounded corners
  Path _createSmoothStepHitTestPath(Path originalPath, double tolerance) {
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

      // For smooth step, we need to account for the curved corners
      // Use more segments to properly capture the rounded areas
      final segmentCount = math.max(6, (metric.length / 30).ceil());
      final segmentLength = metric.length / segmentCount;

      for (int i = 0; i < segmentCount; i++) {
        final startOffset = i * segmentLength;
        final endOffset = math.min((i + 1) * segmentLength, metric.length);

        final startTangent = metric.getTangentForOffset(startOffset);
        final endTangent = metric.getTangentForOffset(endOffset);

        if (startTangent != null && endTangent != null) {
          final segmentHitArea = _createSmoothStepSegmentHitArea(
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

  /// Create hit area for smooth step segment (handles both straight and curved parts)
  Path _createSmoothStepSegmentHitArea(
    Offset start,
    Offset end,
    double tolerance,
  ) {
    // For smooth step segments, use the same logic as step but with slightly larger tolerance
    // to account for the rounded corners
    final adjustedTolerance = tolerance * 1.1;

    final dx = (end.dx - start.dx).abs();
    final dy = (end.dy - start.dy).abs();

    if (dx < 1.0) {
      // Vertical segment
      return Path()..addRect(
        Rect.fromLTRB(
          start.dx - adjustedTolerance,
          math.min(start.dy, end.dy),
          start.dx + adjustedTolerance,
          math.max(start.dy, end.dy),
        ),
      );
    } else if (dy < 1.0) {
      // Horizontal segment
      return Path()..addRect(
        Rect.fromLTRB(
          math.min(start.dx, end.dx),
          start.dy - adjustedTolerance,
          math.max(start.dx, end.dx),
          start.dy + adjustedTolerance,
        ),
      );
    } else {
      // Curved segment - create more generous hit area
      final length = math.sqrt(dx * dx + dy * dy);
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
}
