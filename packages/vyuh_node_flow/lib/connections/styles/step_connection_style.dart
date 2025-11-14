import 'dart:math' as math;

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
  Path createPath(ConnectionPathParameters params) {
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
  List<Offset>? getExactBendPoints(ConnectionPathParameters params) {
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
  Path createHitTestPath(
    Path originalPath,
    double tolerance, {
    ConnectionPathParameters? pathParams,
  }) {
    // Use exact bend points from the path calculator
    if (pathParams == null) {
      // This shouldn't happen in normal usage
      return Path()..addRect(originalPath.getBounds().inflate(tolerance));
    }

    final bendPoints = getExactBendPoints(pathParams);
    if (bendPoints == null || bendPoints.length < 2) {
      return Path()..addRect(originalPath.getBounds().inflate(tolerance));
    }

    return _createStepHitAreas(bendPoints, tolerance);
  }

  /// Create hit areas for step paths
  /// Creates one rectangle per straight segment, merging collinear segments
  Path _createStepHitAreas(List<Offset> waypoints, double tolerance) {
    if (waypoints.length < 2) return Path();

    final combinedPath = Path();

    // Merge collinear segments to reduce rectangle count
    final mergedSegments = _mergeCollinearSegments(waypoints);

    // Create rectangles for each merged segment
    for (final segment in mergedSegments) {
      final segmentRect = _createStepSegmentHitArea(
        segment.start,
        segment.end,
        tolerance,
      );
      combinedPath.addPath(segmentRect, Offset.zero);
    }

    return combinedPath;
  }

  /// Merge consecutive collinear segments to reduce rectangle count
  /// For example: [A→B→C] where A, B, C are on same line becomes [A→C]
  List<({Offset start, Offset end})> _mergeCollinearSegments(
    List<Offset> waypoints,
  ) {
    if (waypoints.length < 2) return [];

    final segments = <({Offset start, Offset end})>[];
    Offset segmentStart = waypoints[0];

    for (int i = 1; i < waypoints.length; i++) {
      final current = waypoints[i];
      bool shouldEndSegment = (i == waypoints.length - 1); // Last point

      if (!shouldEndSegment && i < waypoints.length - 1) {
        final next = waypoints[i + 1];

        // Check if current segment and next segment are collinear
        final currentVector = current - segmentStart;
        final nextVector = next - current;

        final currentIsHorizontal = currentVector.dy.abs() < 0.5;
        final currentIsVertical = currentVector.dx.abs() < 0.5;
        final nextIsHorizontal = nextVector.dy.abs() < 0.5;
        final nextIsVertical = nextVector.dx.abs() < 0.5;

        // If direction changes, end this segment
        shouldEndSegment =
            (currentIsHorizontal != nextIsHorizontal) ||
            (currentIsVertical != nextIsVertical);
      }

      if (shouldEndSegment) {
        segments.add((start: segmentStart, end: current));
        segmentStart = current;
      }
    }

    return segments;
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

  /// Create hit test path from exact waypoints
  Path createHitTestPathFromWaypoints(
    List<Offset> waypoints,
    double tolerance,
  ) {
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
  Path createPath(ConnectionPathParameters params) {
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
  Path createHitTestPath(
    Path originalPath,
    double tolerance, {
    ConnectionPathParameters? pathParams,
  }) {
    // Use exact bend points from the path calculator
    if (pathParams == null) {
      // This shouldn't happen in normal usage
      return Path()..addRect(originalPath.getBounds().inflate(tolerance));
    }

    final bendPoints = getExactBendPoints(pathParams);
    if (bendPoints == null || bendPoints.length < 2) {
      return Path()..addRect(originalPath.getBounds().inflate(tolerance));
    }

    // For smooth step, use slightly larger tolerance to account for rounded corners
    return _createStepHitAreas(bendPoints, tolerance * 1.2);
  }
}
