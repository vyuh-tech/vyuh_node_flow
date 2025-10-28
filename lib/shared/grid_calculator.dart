import 'package:flutter/material.dart';

import '../graph/node_flow_theme.dart';
import '../graph/viewport.dart';

class GridCalculator {
  /// Calculates the visible area in graph coordinates
  static ({double left, double top, double right, double bottom})
  calculateVisibleArea(GraphViewport viewport, Size canvasSize) {
    final zoom = viewport.zoom;
    final viewportLeft = -viewport.x / zoom;
    final viewportTop = -viewport.y / zoom;
    final viewportRight = viewportLeft + (canvasSize.width / zoom);
    final viewportBottom = viewportTop + (canvasSize.height / zoom);

    return (
      left: viewportLeft,
      top: viewportTop,
      right: viewportRight,
      bottom: viewportBottom,
    );
  }

  /// Calculates the extended grid area with padding for smooth panning
  static ({double left, double top, double right, double bottom})
  calculateGridArea(
    ({double left, double top, double right, double bottom}) visibleArea,
    double gridSize, {
    double paddingMultiplier = 2.0,
  }) {
    final padding = gridSize * paddingMultiplier;

    return (
      left: visibleArea.left - padding,
      top: visibleArea.top - padding,
      right: visibleArea.right + padding,
      bottom: visibleArea.bottom + padding,
    );
  }

  /// Calculates grid line start positions aligned to grid
  static ({double startX, double startY}) calculateGridStartPositions(
    ({double left, double top, double right, double bottom}) gridArea,
    double gridSize,
  ) {
    return (
      startX: (gridArea.left / gridSize).floor() * gridSize,
      startY: (gridArea.top / gridSize).floor() * gridSize,
    );
  }

  /// Generates grid line positions for lines grid
  static ({List<double> verticalLines, List<double> horizontalLines})
  calculateGridLines(
    ({double left, double top, double right, double bottom}) gridArea,
    double gridSize,
  ) {
    final startPositions = calculateGridStartPositions(gridArea, gridSize);

    final verticalLines = <double>[];
    final horizontalLines = <double>[];

    // Generate vertical line positions
    for (double x = startPositions.startX; x <= gridArea.right; x += gridSize) {
      verticalLines.add(x);
    }

    // Generate horizontal line positions
    for (
      double y = startPositions.startY;
      y <= gridArea.bottom;
      y += gridSize
    ) {
      horizontalLines.add(y);
    }

    return (verticalLines: verticalLines, horizontalLines: horizontalLines);
  }

  /// Generates dot positions for dots grid
  static List<Offset> calculateGridDots(
    ({double left, double top, double right, double bottom}) gridArea,
    double gridSize,
  ) {
    final startPositions = calculateGridStartPositions(gridArea, gridSize);
    final dots = <Offset>[];

    for (double x = startPositions.startX; x <= gridArea.right; x += gridSize) {
      for (
        double y = startPositions.startY;
        y <= gridArea.bottom;
        y += gridSize
      ) {
        dots.add(Offset(x, y));
      }
    }

    return dots;
  }

  /// Calculates hierarchical grid data (minor and major grids)
  static ({
    List<double> minorVerticalLines,
    List<double> minorHorizontalLines,
    List<double> majorVerticalLines,
    List<double> majorHorizontalLines,
  })
  calculateHierarchicalGrid(
    ({double left, double top, double right, double bottom}) gridArea,
    double gridSize, {
    int majorGridMultiplier = 5,
  }) {
    final majorGridSize = gridSize * majorGridMultiplier;

    // Calculate minor grid lines
    final minorGrid = calculateGridLines(gridArea, gridSize);

    // Calculate major grid lines
    final majorGrid = calculateGridLines(gridArea, majorGridSize);

    return (
      minorVerticalLines: minorGrid.verticalLines,
      minorHorizontalLines: minorGrid.horizontalLines,
      majorVerticalLines: majorGrid.verticalLines,
      majorHorizontalLines: majorGrid.horizontalLines,
    );
  }

  /// Calculates paint styles for grid rendering
  static ({Paint minorPaint, Paint majorPaint}) calculateHierarchicalPaints(
    NodeFlowTheme theme,
  ) {
    final minorPaint = Paint()
      ..color = theme.gridColor.withValues(alpha: 0.3)
      ..strokeWidth = theme.gridThickness
      ..style = PaintingStyle.stroke;

    final majorPaint = Paint()
      ..color = theme.gridColor
      ..strokeWidth = theme.gridThickness * 2
      ..style = PaintingStyle.stroke;

    return (minorPaint: minorPaint, majorPaint: majorPaint);
  }

  /// Calculates standard grid paint
  static Paint calculateGridPaint(NodeFlowTheme theme) {
    return Paint()
      ..color = theme.gridColor
      ..strokeWidth = theme.gridThickness
      ..style = PaintingStyle.stroke;
  }

  /// Calculates dots paint and radius
  static ({Paint paint, double radius}) calculateDotsPaint(
    NodeFlowTheme theme,
  ) {
    final paint = Paint()
      ..color = theme.gridColor
      ..style = PaintingStyle.fill;

    final radius = theme.gridThickness.clamp(0.5, 2.0);

    return (paint: paint, radius: radius);
  }
}
