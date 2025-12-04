import 'package:flutter/material.dart';

import '../../graph/node_flow_theme.dart';
import '../../graph/viewport.dart';

/// Abstract base class for all grid styles.
///
/// Calculates common grid parameters once and delegates to [paintGrid] for
/// style-specific rendering. This eliminates code duplication across grid styles.
///
/// Each grid style extends this class and implements [paintGrid] to render its
/// specific pattern (lines, dots, crosses, etc.).
///
/// Example:
/// ```dart
/// class MyGridStyle extends GridStyle {
///   const MyGridStyle({this.customSize = 5.0});
///
///   final double customSize;
///
///   @override
///   void paintGrid(
///     Canvas canvas,
///     NodeFlowTheme theme,
///     ({double left, double top, double right, double bottom}) gridArea,
///   ) {
///     // Calculate style-specific positions and render
///     final gridSize = theme.gridTheme.size;
///     final startX = (gridArea.left / gridSize).floor() * gridSize;
///     // ... custom grid painting logic here
///   }
/// }
/// ```
abstract class GridStyle {
  const GridStyle();

  /// Paints the grid pattern on the canvas.
  ///
  /// Calculates common parameters (visible area, grid area) once, then calls
  /// [paintGrid] for style-specific rendering.
  ///
  /// Parameters:
  /// - [canvas]: The canvas to paint on
  /// - [size]: The size of the canvas
  /// - [theme]: Theme containing grid configuration (size, color, thickness)
  /// - [viewport]: Current viewport transformation (pan and zoom)
  void paint(
    Canvas canvas,
    Size size,
    NodeFlowTheme theme,
    GraphViewport viewport,
  ) {
    final gridSize = theme.gridTheme.size;
    if (gridSize <= 0) return;

    // Calculate common parameters once
    final visibleArea = _calculateVisibleArea(viewport, size);
    final gridArea = _calculateGridArea(visibleArea, gridSize);

    // Delegate to style-specific implementation
    paintGrid(canvas, theme, gridArea);
  }

  /// Renders the style-specific grid pattern.
  ///
  /// Each grid style implements this method to draw its specific pattern
  /// (lines, dots, crosses, etc.) using the pre-calculated [gridArea].
  ///
  /// Parameters:
  /// - [canvas]: The canvas to paint on
  /// - [theme]: Theme containing grid configuration
  /// - [gridArea]: Pre-calculated grid-aligned area covering the visible region
  @protected
  void paintGrid(
    Canvas canvas,
    NodeFlowTheme theme,
    ({double left, double top, double right, double bottom}) gridArea,
  );

  /// Calculates the visible area in world coordinates.
  ///
  /// Transforms the screen viewport bounds to graph coordinates.
  ({double left, double top, double right, double bottom})
  _calculateVisibleArea(GraphViewport viewport, Size canvasSize) {
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

  /// Calculates the grid-aligned area with padding for smooth panning.
  ///
  /// Extends the visible area by 2 grid cells to prevent grid elements from
  /// popping in/out during panning.
  ({double left, double top, double right, double bottom}) _calculateGridArea(
    ({double left, double top, double right, double bottom}) visibleArea,
    double gridSize,
  ) {
    final padding = gridSize * 2.0;

    return (
      left: visibleArea.left - padding,
      top: visibleArea.top - padding,
      right: visibleArea.right + padding,
      bottom: visibleArea.bottom + padding,
    );
  }

  /// Helper to create a base paint object with grid color and thickness.
  @protected
  Paint createGridPaint(NodeFlowTheme theme) {
    final gridTheme = theme.gridTheme;
    return Paint()
      ..color = gridTheme.color
      ..strokeWidth = gridTheme.thickness
      ..style = PaintingStyle.stroke;
  }
}
