import 'package:flutter/material.dart';

import 'grid_styles.dart';
import 'styles/grid_style.dart';

/// Theme configuration for the grid background.
///
/// [GridTheme] defines the visual appearance of the grid rendered behind the
/// node flow canvas. The grid provides visual reference points and can be
/// used for alignment and snapping.
///
/// Example:
/// ```dart
/// // Create a custom grid theme
/// final customTheme = GridTheme(
///   color: Colors.grey.shade300,
///   size: 25.0,
///   thickness: 1.0,
///   style: GridStyles.lines,
/// );
///
/// // Or use a predefined theme
/// final lightTheme = GridTheme.light;
/// final darkTheme = GridTheme.dark;
/// ```
class GridTheme {
  /// Creates a grid theme with the specified visual properties.
  ///
  /// Parameters:
  /// - [color]: Color of the grid lines or dots
  /// - [size]: Base spacing between grid lines in graph units
  /// - [thickness]: Width of grid lines (or radius for dots)
  /// - [style]: The grid pattern style to render
  const GridTheme({
    required this.color,
    required this.size,
    required this.thickness,
    required this.style,
    this.minScreenSpacing = 24.0,
  });

  /// Color of the grid lines or dots.
  final Color color;

  /// Base spacing between grid lines in graph units.
  ///
  /// This determines both horizontal and vertical spacing.
  /// Default is 20.0 in predefined themes.
  final double size;

  /// Thickness of grid lines in pixels.
  ///
  /// For dot style, this affects dot radius.
  /// Default is 1.0 in predefined themes.
  final double thickness;

  /// Minimum on-screen distance between grid primitives.
  ///
  /// When zoom would place grid points or lines closer than this value, the
  /// renderer advances to a power-of-two multiple of [size]. This preserves
  /// world alignment while bounding low-zoom paint work. Set to `0` to disable
  /// adaptive grid coarsening.
  final double minScreenSpacing;

  /// The grid style to render on the canvas background.
  ///
  /// Use constants from [GridStyles] class or create a custom [GridStyle].
  /// Use [GridStyles.none] for no grid.
  ///
  /// Example:
  /// ```dart
  /// // Using GridStyles constants
  /// style: GridStyles.lines,
  /// style: GridStyles.hierarchical,
  ///
  /// // Custom grid style
  /// style: MyCustomGridStyle(),
  ///
  /// // No grid
  /// style: GridStyles.none,
  /// ```
  final GridStyle style;

  /// Creates a copy of this theme with the specified properties replaced.
  GridTheme copyWith({
    Color? color,
    double? size,
    double? thickness,
    GridStyle? style,
    double? minScreenSpacing,
  }) {
    return GridTheme(
      color: color ?? this.color,
      size: size ?? this.size,
      thickness: thickness ?? this.thickness,
      style: style ?? this.style,
      minScreenSpacing: minScreenSpacing ?? this.minScreenSpacing,
    );
  }

  /// A predefined light theme for the grid.
  ///
  /// Features a subtle light grey dot pattern suitable for light backgrounds.
  static const light = GridTheme(
    color: Color(0xFFC8C8C8),
    size: 20.0,
    thickness: 1.0,
    style: GridStyles.dots,
  );

  /// A predefined dark theme for the grid.
  ///
  /// Features a visible medium grey dot pattern suitable for dark backgrounds.
  static const dark = GridTheme(
    color: Color(0xFF707070),
    size: 20.0,
    thickness: 1.0,
    style: GridStyles.dots,
  );
}
