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

    // Calculate dot radius and create paint
    final radius = dotSize ?? gridTheme.thickness.clamp(0.5, 2.0);
    final paint = Paint()
      ..color = gridTheme.color
      ..style = PaintingStyle.fill;

    // Calculate grid-aligned start positions
    final startX = (gridArea.left / gridSize).floor() * gridSize;
    final startY = (gridArea.top / gridSize).floor() * gridSize;

    // Draw dots at each grid intersection
    for (double x = startX; x <= gridArea.right; x += gridSize) {
      for (double y = startY; y <= gridArea.bottom; y += gridSize) {
        canvas.drawCircle(Offset(x, y), radius, paint);
      }
    }
  }
}
