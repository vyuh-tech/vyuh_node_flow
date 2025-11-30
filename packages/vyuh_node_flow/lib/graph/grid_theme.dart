import 'package:flutter/material.dart';

import 'grid_styles.dart';
import 'painters/grid_style.dart';

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
  /// - [size]: Spacing between grid lines in pixels
  /// - [thickness]: Width of grid lines (or radius for dots)
  /// - [style]: The grid pattern style to render
  const GridTheme({
    required this.color,
    required this.size,
    required this.thickness,
    required this.style,
  });

  /// Color of the grid lines or dots.
  final Color color;

  /// Spacing between grid lines in pixels.
  ///
  /// This determines both horizontal and vertical spacing.
  /// Default is 20.0 in predefined themes.
  final double size;

  /// Thickness of grid lines in pixels.
  ///
  /// For dot style, this affects dot radius.
  /// Default is 1.0 in predefined themes.
  final double thickness;

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
  }) {
    return GridTheme(
      color: color ?? this.color,
      size: size ?? this.size,
      thickness: thickness ?? this.thickness,
      style: style ?? this.style,
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
