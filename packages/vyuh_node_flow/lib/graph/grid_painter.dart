import 'package:flutter/material.dart';

import '../graph/node_flow_theme.dart';
import '../graph/viewport.dart';
import 'grid_calculator.dart';

class GridPainter extends CustomPainter {
  const GridPainter({required this.theme, required this.viewport});

  final NodeFlowTheme theme;
  final GraphViewport viewport;

  @override
  void paint(Canvas canvas, Size size) {
    if (theme.gridSize <= 0 || theme.gridStyle == GridStyle.none) return;

    switch (theme.gridStyle) {
      case GridStyle.lines:
        _paintLinesGrid(canvas, size);
        break;
      case GridStyle.dots:
        _paintDotsGrid(canvas, size);
        break;
      case GridStyle.hierarchical:
        _paintHierarchicalGrid(canvas, size);
        break;
      case GridStyle.none:
        // No grid to paint
        break;
    }
  }

  void _paintLinesGrid(Canvas canvas, Size size) {
    final paint = GridCalculator.calculateGridPaint(theme);
    final gridSize = theme.gridSize;

    // Calculate visible area and grid area
    final visibleArea = GridCalculator.calculateVisibleArea(viewport, size);
    final gridArea = GridCalculator.calculateGridArea(visibleArea, gridSize);

    // Calculate grid lines
    final gridLines = GridCalculator.calculateGridLines(gridArea, gridSize);

    // Draw vertical lines
    for (final x in gridLines.verticalLines) {
      canvas.drawLine(
        Offset(x, gridArea.top),
        Offset(x, gridArea.bottom),
        paint,
      );
    }

    // Draw horizontal lines
    for (final y in gridLines.horizontalLines) {
      canvas.drawLine(
        Offset(gridArea.left, y),
        Offset(gridArea.right, y),
        paint,
      );
    }
  }

  void _paintDotsGrid(Canvas canvas, Size size) {
    final gridSize = theme.gridSize;
    final dotPaintData = GridCalculator.calculateDotsPaint(theme);

    // Calculate visible area and grid area
    final visibleArea = GridCalculator.calculateVisibleArea(viewport, size);
    final gridArea = GridCalculator.calculateGridArea(visibleArea, gridSize);

    // Calculate dot positions
    final dots = GridCalculator.calculateGridDots(gridArea, gridSize);

    // Draw dots
    for (final dot in dots) {
      canvas.drawCircle(dot, dotPaintData.radius, dotPaintData.paint);
    }
  }

  void _paintHierarchicalGrid(Canvas canvas, Size size) {
    final gridSize = theme.gridSize;
    final paints = GridCalculator.calculateHierarchicalPaints(theme);

    // Calculate visible area and grid area (using major grid size for padding)
    final majorGridSize = gridSize * 5; // Major grid every 5 minor grids
    final visibleArea = GridCalculator.calculateVisibleArea(viewport, size);
    final gridArea = GridCalculator.calculateGridArea(
      visibleArea,
      majorGridSize,
      paddingMultiplier: 2.0,
    );

    // Calculate hierarchical grid data
    final hierarchicalGrid = GridCalculator.calculateHierarchicalGrid(
      gridArea,
      gridSize,
    );

    // Paint minor grid
    for (final x in hierarchicalGrid.minorVerticalLines) {
      canvas.drawLine(
        Offset(x, gridArea.top),
        Offset(x, gridArea.bottom),
        paints.minorPaint,
      );
    }

    for (final y in hierarchicalGrid.minorHorizontalLines) {
      canvas.drawLine(
        Offset(gridArea.left, y),
        Offset(gridArea.right, y),
        paints.minorPaint,
      );
    }

    // Paint major grid
    for (final x in hierarchicalGrid.majorVerticalLines) {
      canvas.drawLine(
        Offset(x, gridArea.top),
        Offset(x, gridArea.bottom),
        paints.majorPaint,
      );
    }

    for (final y in hierarchicalGrid.majorHorizontalLines) {
      canvas.drawLine(
        Offset(gridArea.left, y),
        Offset(gridArea.right, y),
        paints.majorPaint,
      );
    }
  }

  @override
  bool shouldRepaint(GridPainter oldDelegate) {
    return viewport != oldDelegate.viewport || theme != oldDelegate.theme;
  }
}
