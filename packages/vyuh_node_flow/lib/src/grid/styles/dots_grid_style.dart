import 'dart:typed_data';
import 'dart:ui' as ui show PointMode;

import 'package:flutter/material.dart';

import '../../editor/themes/node_flow_theme.dart';
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
    ({double left, double top, double right, double bottom}) gridArea,
  ) {
    final gridTheme = theme.gridTheme;
    final gridSize = gridTheme.size;

    // Calculate dot radius and create paint.
    // Draw points in a single batch with round stroke caps for lower draw-call cost.
    final radius = dotSize ?? gridTheme.thickness.clamp(0.5, 2.0).toDouble();
    final paint = Paint()
      ..color = gridTheme.color
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = radius * 2;

    // Calculate grid-aligned start positions
    final startX = (gridArea.left / gridSize).floor() * gridSize;
    final startY = (gridArea.top / gridSize).floor() * gridSize;

    final columnCount = ((gridArea.right - startX) / gridSize).floor() + 1;
    final rowCount = ((gridArea.bottom - startY) / gridSize).floor() + 1;
    if (columnCount <= 0 || rowCount <= 0) return;

    final rawPoints = Float32List(columnCount * rowCount * 2);
    var i = 0;

    // Build points in a flat float array for drawRawPoints batching.
    for (var col = 0; col < columnCount; col++) {
      final x = startX + col * gridSize;
      for (var row = 0; row < rowCount; row++) {
        rawPoints[i++] = x;
        rawPoints[i++] = startY + row * gridSize;
      }
    }

    canvas.drawRawPoints(ui.PointMode.points, rawPoints, paint);
  }
}
