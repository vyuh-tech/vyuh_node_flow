import 'package:flutter/material.dart';

import '../../editor/themes/node_flow_theme.dart';
import 'grid_style.dart';

/// Grid style that renders small crosses at grid intersections.
///
/// Creates a subtle grid pattern by drawing small cross marks where vertical
/// and horizontal grid lines would intersect.
///
/// The [crossSize] parameter controls the arm length of each cross. If not provided,
/// it defaults to gridTheme.thickness * 3, clamped to 2.0-6.0 pixels.
///
/// This style provides a unique visual reference that's more distinct than dots
/// while remaining less prominent than full lines.
class CrossGridStyle extends GridStyle {
  /// Creates a cross grid style.
  ///
  /// [crossSize] - Optional arm length for each cross. If null, calculated from gridTheme.thickness.
  const CrossGridStyle({this.crossSize});

  /// The arm length of each cross. If null, calculated from gridTheme.thickness.
  final double? crossSize;

  @override
  void paintGrid(
    Canvas canvas,
    NodeFlowTheme theme,
    ({double left, double top, double right, double bottom}) gridArea,
  ) {
    final gridTheme = theme.gridTheme;
    final gridSize = gridTheme.size;

    // Create paint for the crosses
    final paint = createGridPaint(theme)
      ..strokeWidth = gridTheme.thickness.clamp(0.5, 1.5).toDouble();

    // Calculate arm length
    final armLength =
        crossSize ?? (gridTheme.thickness * 3).clamp(2.0, 6.0).toDouble();
    final path = Path();

    // Calculate grid-aligned start positions
    final startX = (gridArea.left / gridSize).floor() * gridSize;
    final startY = (gridArea.top / gridSize).floor() * gridSize;

    // Draw crosses at each grid intersection
    for (double x = startX; x <= gridArea.right; x += gridSize) {
      for (double y = startY; y <= gridArea.bottom; y += gridSize) {
        // Horizontal arm
        path
          ..moveTo(x - armLength, y)
          ..lineTo(x + armLength, y);

        // Vertical arm
        path
          ..moveTo(x, y - armLength)
          ..lineTo(x, y + armLength);
      }
    }

    canvas.drawPath(path, paint);
  }
}
