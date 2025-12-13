import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'connection_style_base.dart';
import 'smoothstep_path_calculator.dart';

/// Step connection style (90-degree turns with optional rounded corners)
///
/// Creates connections with 90-degree turns that follow a predictable
/// step pattern based on port positions. The corner radius can be configured
/// to create either sharp corners (0) or smoothly rounded corners (> 0).
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
  Path createPath(ConnectionPathParameters params) {
    return SmoothstepPathCalculator.calculatePath(
      start: params.start,
      end: params.end,
      sourcePosition: params.sourcePosition,
      targetPosition: params.targetPosition,
      offset: params.offset,
      cornerRadius: params.cornerRadius > 0
          ? params.cornerRadius
          : cornerRadius,
      sourceNodeBounds: params.sourceNodeBounds,
      targetNodeBounds: params.targetNodeBounds,
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
      sourceNodeBounds: params.sourceNodeBounds,
      targetNodeBounds: params.targetNodeBounds,
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
  List<Rect> getHitTestSegments(
    Path originalPath,
    double tolerance, {
    ConnectionPathParameters? pathParams,
  }) {
    // Use exact bend points for minimal segment count
    if (pathParams == null) {
      return super.getHitTestSegments(originalPath, tolerance);
    }

    final bendPoints = getExactBendPoints(pathParams);
    if (bendPoints == null || bendPoints.length < 2) {
      return super.getHitTestSegments(originalPath, tolerance);
    }

    // Merge collinear segments and create rectangles
    final mergedSegments = _mergeCollinearSegments(bendPoints);
    return mergedSegments.map((segment) {
      return _createSegmentRect(segment.start, segment.end, tolerance);
    }).toList();
  }

  /// Creates a rectangle around a line segment with tolerance extending past endpoints.
  Rect _createSegmentRect(Offset start, Offset end, double tolerance) {
    return Rect.fromLTRB(
      math.min(start.dx, end.dx) - tolerance,
      math.min(start.dy, end.dy) - tolerance,
      math.max(start.dx, end.dx) + tolerance,
      math.max(start.dy, end.dy) + tolerance,
    );
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

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is StepConnectionStyle &&
          runtimeType == other.runtimeType &&
          cornerRadius == other.cornerRadius;

  @override
  int get hashCode => cornerRadius.hashCode;
}
