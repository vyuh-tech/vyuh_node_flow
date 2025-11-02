import 'package:flutter/material.dart';

import 'node_flow_theme.dart';
import 'viewport.dart';

/// Utility class for calculating grid rendering data.
///
/// Provides static methods to compute grid line positions, dot positions,
/// visible areas, and paint styles for different grid types. Used by the
/// grid layer to efficiently render the background grid.
///
/// The calculator handles:
/// - Viewport transformations to determine visible area
/// - Grid alignment to ensure lines/dots align to grid spacing
/// - Hierarchical grid computation for major/minor grids
/// - Paint style generation for different grid styles
///
/// All methods are static and stateless, operating purely on input parameters.
class GridCalculator {
  /// Calculates the visible area in graph coordinates.
  ///
  /// Transforms the screen viewport bounds to graph coordinates to determine
  /// what portion of the infinite graph is currently visible.
  ///
  /// Parameters:
  /// - [viewport]: Current viewport transformation (pan and zoom)
  /// - [canvasSize]: Size of the canvas in screen pixels
  ///
  /// Returns: A record with left, top, right, bottom bounds in graph coordinates
  ///
  /// Example:
  /// ```dart
  /// final visible = GridCalculator.calculateVisibleArea(
  ///   viewport,
  ///   Size(800, 600),
  /// );
  /// print('Visible from (${visible.left}, ${visible.top}) to (${visible.right}, ${visible.bottom})');
  /// ```
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

  /// Calculates the extended grid area with padding for smooth panning.
  ///
  /// Extends the visible area by padding to render grid lines/dots slightly
  /// beyond the visible bounds. This prevents grid elements from popping in/out
  /// during panning, providing smooth visual continuity.
  ///
  /// Parameters:
  /// - [visibleArea]: The visible bounds from [calculateVisibleArea]
  /// - [gridSize]: Grid spacing in pixels
  /// - [paddingMultiplier]: How many grid cells to extend beyond visible area
  ///
  /// Returns: Extended bounds with padding applied
  ///
  /// Example:
  /// ```dart
  /// final gridArea = GridCalculator.calculateGridArea(
  ///   visibleArea,
  ///   20.0,
  ///   paddingMultiplier: 2.0, // Extend by 2 grid cells
  /// );
  /// ```
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

  /// Calculates grid line start positions aligned to grid spacing.
  ///
  /// Snaps the grid area's left and top bounds to the nearest grid line,
  /// ensuring grid lines are always perfectly aligned regardless of viewport
  /// position.
  ///
  /// Parameters:
  /// - [gridArea]: The area to calculate grid positions for
  /// - [gridSize]: Grid spacing in pixels
  ///
  /// Returns: Aligned start positions for vertical and horizontal lines
  static ({double startX, double startY}) calculateGridStartPositions(
    ({double left, double top, double right, double bottom}) gridArea,
    double gridSize,
  ) {
    return (
      startX: (gridArea.left / gridSize).floor() * gridSize,
      startY: (gridArea.top / gridSize).floor() * gridSize,
    );
  }

  /// Generates grid line positions for line-based grid.
  ///
  /// Computes the X positions for vertical lines and Y positions for horizontal
  /// lines within the grid area, spaced according to grid size.
  ///
  /// Parameters:
  /// - [gridArea]: The area to generate lines for
  /// - [gridSize]: Spacing between lines
  ///
  /// Returns: Lists of positions for vertical and horizontal lines
  ///
  /// Example:
  /// ```dart
  /// final lines = GridCalculator.calculateGridLines(gridArea, 20.0);
  /// for (final x in lines.verticalLines) {
  ///   canvas.drawLine(Offset(x, top), Offset(x, bottom), paint);
  /// }
  /// ```
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

  /// Generates dot positions for dot-based grid.
  ///
  /// Computes positions for dots at grid intersections within the grid area.
  /// Each dot is placed where vertical and horizontal grid lines would intersect.
  ///
  /// Parameters:
  /// - [gridArea]: The area to generate dots for
  /// - [gridSize]: Spacing between dots
  ///
  /// Returns: List of [Offset] positions where dots should be rendered
  ///
  /// Example:
  /// ```dart
  /// final dots = GridCalculator.calculateGridDots(gridArea, 20.0);
  /// for (final pos in dots) {
  ///   canvas.drawCircle(pos, radius, paint);
  /// }
  /// ```
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

  /// Calculates hierarchical grid data with minor and major grid lines.
  ///
  /// Generates two sets of grid lines at different intervals:
  /// - Minor lines at standard [gridSize] spacing (subtle, light)
  /// - Major lines at [gridSize] * [majorGridMultiplier] spacing (bold, prominent)
  ///
  /// This creates a multi-level visual hierarchy for easier alignment and navigation.
  ///
  /// Parameters:
  /// - [gridArea]: The area to generate grids for
  /// - [gridSize]: Base spacing for minor grid lines
  /// - [majorGridMultiplier]: Multiplier for major grid spacing (default: 5)
  ///
  /// Returns: Separate lists for minor and major vertical/horizontal lines
  ///
  /// Example:
  /// ```dart
  /// final grid = GridCalculator.calculateHierarchicalGrid(
  ///   gridArea,
  ///   20.0,
  ///   majorGridMultiplier: 5, // Major lines every 100 pixels
  /// );
  /// // Draw minor lines first (lighter)
  /// // Then draw major lines (bolder)
  /// ```
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

  /// Calculates paint styles for hierarchical grid rendering.
  ///
  /// Creates two paint objects configured for minor and major grid lines:
  /// - Minor paint: Lighter color (30% opacity), standard thickness
  /// - Major paint: Full color, double thickness for emphasis
  ///
  /// Parameters:
  /// - [theme]: Theme providing grid color and thickness settings
  ///
  /// Returns: Paint objects for minor and major grid lines
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

  /// Calculates standard grid paint for lines.
  ///
  /// Creates a paint object configured for drawing regular grid lines
  /// using the theme's grid color and thickness.
  ///
  /// Parameters:
  /// - [theme]: Theme providing grid color and thickness settings
  ///
  /// Returns: Configured paint object for grid lines
  static Paint calculateGridPaint(NodeFlowTheme theme) {
    return Paint()
      ..color = theme.gridColor
      ..strokeWidth = theme.gridThickness
      ..style = PaintingStyle.stroke;
  }

  /// Calculates paint style and radius for dot grid.
  ///
  /// Creates a paint object configured for drawing grid dots and determines
  /// the appropriate dot radius based on grid thickness. Radius is clamped
  /// to a reasonable range (0.5 to 2.0) for visual consistency.
  ///
  /// Parameters:
  /// - [theme]: Theme providing grid color and thickness settings
  ///
  /// Returns: Paint object and dot radius for rendering
  ///
  /// Example:
  /// ```dart
  /// final dotStyle = GridCalculator.calculateDotsPaint(theme);
  /// for (final pos in dots) {
  ///   canvas.drawCircle(pos, dotStyle.radius, dotStyle.paint);
  /// }
  /// ```
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
