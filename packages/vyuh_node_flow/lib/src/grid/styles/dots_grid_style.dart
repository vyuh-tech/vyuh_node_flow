import 'dart:typed_data';
import 'dart:ui' as ui show PointMode;

import 'package:flutter/material.dart';

import '../../editor/themes/node_flow_theme.dart';
import 'grid_sampling_policy.dart';
import 'grid_style.dart';

/// Grid style that renders dots at grid intersections.
///
/// Creates a subtle dot-based grid with dots positioned where vertical and
/// horizontal grid lines would intersect.
///
/// The [dotSize] parameter controls the radius of each dot. If not provided,
/// it defaults to the gridTheme's thickness clamped to 0.5-2.0 pixels.
///
/// This style reduces visual clutter while still providing reference points
/// for positioning and alignment.
class DotsGridStyle extends GridStyle {
  /// Creates a dots grid style.
  ///
  /// [dotSize] - Optional dot radius. If null, uses gridTheme.thickness clamped to 0.5-2.0.
  const DotsGridStyle({this.dotSize});

  /// The radius of each dot. If null, calculated from gridTheme.thickness.
  final double? dotSize;

  @override
  void paintGrid(
    Canvas canvas,
    NodeFlowTheme theme,
    GridArea gridArea,
  ) {
    final gridTheme = theme.gridTheme;
    final sampling = GridSamplingPolicy.resolve(
      area: gridArea,
      baseSpacing: gridTheme.size,
      maxColumns: 260,
      maxRows: 260,
    );
    if (sampling == null) return;

    // Calculate dot radius and create paint.
    // Draw points in a single batch with round stroke caps for lower draw-call cost.
    final radius = dotSize ?? gridTheme.thickness.clamp(0.5, 2.0).toDouble();
    final paint = Paint()
      ..color = gridTheme.color
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = radius * 2;

    final columnCount = sampling.columns;
    final rowCount = sampling.rows;

    final rawPoints = Float32List(columnCount * rowCount * 2);
    var i = 0;

    // Build points in a flat float array for drawRawPoints batching.
    for (var col = 0; col < columnCount; col++) {
      final x = sampling.startX + col * sampling.spacing;
      for (var row = 0; row < rowCount; row++) {
        rawPoints[i++] = x;
        rawPoints[i++] = sampling.startY + row * sampling.spacing;
      }
    }

    canvas.drawRawPoints(ui.PointMode.points, rawPoints, paint);
  }
}
