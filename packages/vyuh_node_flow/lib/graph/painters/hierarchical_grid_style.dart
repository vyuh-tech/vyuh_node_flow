import 'package:flutter/material.dart';

import '../node_flow_theme.dart';
import 'grid_style.dart';

/// Grid style that renders a two-level hierarchical grid.
///
/// Creates a grid with both minor and major lines at different intervals:
/// - Minor lines: Rendered at standard gridSize spacing with lighter color (30% opacity)
/// - Major lines: Rendered at gridSize * majorGridMultiplier spacing with full color and double thickness
///
/// This provides a multi-level visual hierarchy that makes it easier to align
/// elements at different scales.
class HierarchicalGridStyle extends GridStyle {
  const HierarchicalGridStyle({this.majorGridMultiplier = 5});

  /// Multiplier for major grid spacing relative to minor grid.
  ///
  /// For example, if gridSize is 20 and majorGridMultiplier is 5,
  /// minor lines will be every 20 pixels and major lines every 100 pixels.
  final int majorGridMultiplier;

  @override
  void paintGrid(
    Canvas canvas,
    NodeFlowTheme theme,
    ({double left, double top, double right, double bottom}) gridArea,
  ) {
    final gridSize = theme.gridSize;
    final majorGridSize = gridSize * majorGridMultiplier;

    // Create paint objects for minor and major grids
    final minorPaint = Paint()
      ..color = theme.gridColor.withValues(alpha: 0.3)
      ..strokeWidth = theme.gridThickness
      ..style = PaintingStyle.stroke;

    final majorPaint = Paint()
      ..color = theme.gridColor
      ..strokeWidth = theme.gridThickness * 2
      ..style = PaintingStyle.stroke;

    // Calculate grid-aligned start positions for minor grid
    final minorStartX = (gridArea.left / gridSize).floor() * gridSize;
    final minorStartY = (gridArea.top / gridSize).floor() * gridSize;

    // Calculate grid-aligned start positions for major grid
    final majorStartX = (gridArea.left / majorGridSize).floor() * majorGridSize;
    final majorStartY = (gridArea.top / majorGridSize).floor() * majorGridSize;

    // Draw minor grid lines
    for (double x = minorStartX; x <= gridArea.right; x += gridSize) {
      canvas.drawLine(
        Offset(x, gridArea.top),
        Offset(x, gridArea.bottom),
        minorPaint,
      );
    }

    for (double y = minorStartY; y <= gridArea.bottom; y += gridSize) {
      canvas.drawLine(
        Offset(gridArea.left, y),
        Offset(gridArea.right, y),
        minorPaint,
      );
    }

    // Draw major grid lines (on top of minor lines)
    for (double x = majorStartX; x <= gridArea.right; x += majorGridSize) {
      canvas.drawLine(
        Offset(x, gridArea.top),
        Offset(x, gridArea.bottom),
        majorPaint,
      );
    }

    for (double y = majorStartY; y <= gridArea.bottom; y += majorGridSize) {
      canvas.drawLine(
        Offset(gridArea.left, y),
        Offset(gridArea.right, y),
        majorPaint,
      );
    }
  }
}
