import 'package:flutter/material.dart';

import '../../editor/themes/node_flow_theme.dart';
import 'grid_style.dart';

/// Grid style that renders evenly spaced vertical and horizontal lines.
///
/// Creates a traditional line-based grid with consistent spacing defined by
/// the gridTheme's size property. Lines are rendered using the gridTheme's
/// color and thickness.
///
/// This is the most common grid style, providing clear visual reference for
/// positioning and alignment.
class LinesGridStyle extends GridStyle {
  const LinesGridStyle();

  @override
  void paintGrid(
    Canvas canvas,
    NodeFlowTheme theme,
    ({double left, double top, double right, double bottom}) gridArea,
  ) {
    final paint = createGridPaint(theme);
    final gridSize = theme.gridTheme.size;
    final path = Path();

    // Calculate grid-aligned start positions
    final startX = (gridArea.left / gridSize).floor() * gridSize;
    final startY = (gridArea.top / gridSize).floor() * gridSize;

    // Draw vertical lines
    for (double x = startX; x <= gridArea.right; x += gridSize) {
      path
        ..moveTo(x, gridArea.top)
        ..lineTo(x, gridArea.bottom);
    }

    // Draw horizontal lines
    for (double y = startY; y <= gridArea.bottom; y += gridSize) {
      path
        ..moveTo(gridArea.left, y)
        ..lineTo(gridArea.right, y);
    }

    canvas.drawPath(path, paint);
  }
}
