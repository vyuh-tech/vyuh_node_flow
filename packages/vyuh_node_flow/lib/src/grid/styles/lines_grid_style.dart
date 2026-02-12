import 'package:flutter/material.dart';

import '../../editor/themes/node_flow_theme.dart';
import 'grid_sampling_policy.dart';
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
    GridArea gridArea,
  ) {
    final sampling = GridSamplingPolicy.resolve(
      area: gridArea,
      baseSpacing: theme.gridTheme.size,
      maxColumns: 480,
      maxRows: 480,
    );
    if (sampling == null) return;

    final paint = createGridPaint(theme);
    final path = Path();

    // Draw vertical lines
    for (var col = 0; col < sampling.columns; col++) {
      final x = sampling.startX + col * sampling.spacing;
      path
        ..moveTo(x, gridArea.top)
        ..lineTo(x, gridArea.bottom);
    }

    // Draw horizontal lines
    for (var row = 0; row < sampling.rows; row++) {
      final y = sampling.startY + row * sampling.spacing;
      path
        ..moveTo(gridArea.left, y)
        ..lineTo(gridArea.right, y);
    }

    canvas.drawPath(path, paint);
  }
}
