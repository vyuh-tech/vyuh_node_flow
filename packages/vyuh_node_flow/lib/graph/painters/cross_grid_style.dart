import 'package:flutter/material.dart';

import '../node_flow_theme.dart';
import 'grid_style.dart';

/// Grid style that renders small crosses at grid intersections.
///
/// Creates a subtle grid pattern by drawing small cross marks where vertical
/// and horizontal grid lines would intersect.
///
/// The [crossSize] parameter controls the arm length of each cross. If not provided,
/// it defaults to theme.gridThickness * 3, clamped to 2.0-6.0 pixels.
///
/// This style provides a unique visual reference that's more distinct than dots
/// while remaining less prominent than full lines.
class CrossGridStyle extends GridStyle {
  /// Creates a cross grid style.
  ///
  /// [crossSize] - Optional arm length for each cross. If null, calculated from theme.gridThickness.
  const CrossGridStyle({this.crossSize});

  /// The arm length of each cross. If null, calculated from theme.gridThickness.
  final double? crossSize;

  @override
  void paintGrid(
    Canvas canvas,
    NodeFlowTheme theme,
    ({double left, double top, double right, double bottom}) gridArea,
  ) {
    final gridSize = theme.gridSize;

    // Create paint for the crosses
    final paint = createGridPaint(theme)
      ..strokeWidth = theme.gridThickness.clamp(0.5, 1.5);

    // Calculate arm length
    final armLength = crossSize ?? (theme.gridThickness * 3).clamp(2.0, 6.0);

    // Calculate grid-aligned start positions
    final startX = (gridArea.left / gridSize).floor() * gridSize;
    final startY = (gridArea.top / gridSize).floor() * gridSize;

    // Draw crosses at each grid intersection
    for (double x = startX; x <= gridArea.right; x += gridSize) {
      for (double y = startY; y <= gridArea.bottom; y += gridSize) {
        // Draw horizontal arm
        canvas.drawLine(
          Offset(x - armLength, y),
          Offset(x + armLength, y),
          paint,
        );

        // Draw vertical arm
        canvas.drawLine(
          Offset(x, y - armLength),
          Offset(x, y + armLength),
          paint,
        );
      }
    }
  }
}
