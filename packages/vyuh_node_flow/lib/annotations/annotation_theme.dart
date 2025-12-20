import 'package:flutter/material.dart';

/// Theme configuration for annotation visual appearance.
///
/// [AnnotationTheme] defines the visual styling of annotations in the flow editor,
/// including colors for selection and highlight states, borders, and border radius.
///
/// The theme supports different visual states:
/// - Normal state (default appearance - handled by annotation's buildWidget)
/// - Selected state (when the annotation is selected)
/// - Highlighted state (when being dragged over or hovered)
///
/// Example:
/// ```dart
/// // Create a custom annotation theme
/// final customTheme = AnnotationTheme(
///   selectionBorderColor: Colors.blue,
///   selectionBackgroundColor: Colors.blue.withOpacity(0.1),
///   highlightBorderColor: Colors.orange,
///   highlightBackgroundColor: Colors.orange.withOpacity(0.1),
///   borderWidth: 2.0,
///   borderRadius: BorderRadius.circular(8.0),
///   labelStyle: TextStyle(fontSize: 12, color: Colors.black87),
/// );
///
/// // Or use a predefined theme
/// final lightTheme = AnnotationTheme.light;
/// final darkTheme = AnnotationTheme.dark;
/// ```
class AnnotationTheme {
  /// Creates an annotation theme with the specified visual properties.
  ///
  /// All parameters are required to ensure consistent theming across
  /// different annotation states.
  ///
  /// Parameters:
  /// - [selectionBorderColor]: Border color when annotation is selected
  /// - [selectionBackgroundColor]: Background overlay color when selected
  /// - [highlightBorderColor]: Border color when annotation is highlighted
  /// - [highlightBackgroundColor]: Background overlay color when highlighted
  /// - [borderWidth]: Width of the selection/highlight border
  /// - [borderRadius]: Border radius for the selection/highlight overlay
  /// - [labelStyle]: Text style for annotation labels (titles, text content)
  const AnnotationTheme({
    required this.selectionBorderColor,
    required this.selectionBackgroundColor,
    required this.highlightBorderColor,
    required this.highlightBackgroundColor,
    required this.borderWidth,
    required this.borderRadius,
    required this.labelStyle,
  });

  /// Border color when the annotation is selected.
  ///
  /// This color is used for the border drawn around selected annotations.
  final Color selectionBorderColor;

  /// Background overlay color when the annotation is selected.
  ///
  /// This is typically a semi-transparent version of the selection border color.
  final Color selectionBackgroundColor;

  /// Border color when the annotation is highlighted.
  ///
  /// This color is used during drag-over operations or hover states.
  /// Highlighting takes precedence over selection for better visual feedback.
  final Color highlightBorderColor;

  /// Background overlay color when the annotation is highlighted.
  ///
  /// This is typically a semi-transparent version of the highlight border color.
  final Color highlightBackgroundColor;

  /// Width of the selection/highlight border in logical pixels.
  final double borderWidth;

  /// Border radius for the selection/highlight overlay.
  ///
  /// This controls the corner rounding of the overlay drawn around
  /// selected or highlighted annotations.
  final BorderRadius borderRadius;

  /// Text style for annotation labels.
  ///
  /// This style is used for titles in group annotations, text content in
  /// sticky annotations, and other text elements within annotations.
  final TextStyle labelStyle;

  /// Creates a copy of this theme with the specified properties replaced.
  ///
  /// All parameters are optional. If a parameter is not provided, the
  /// corresponding property from the current theme is used.
  ///
  /// Example:
  /// ```dart
  /// final baseTheme = AnnotationTheme.light;
  /// final customTheme = baseTheme.copyWith(
  ///   selectionBorderColor: Colors.purple,
  ///   borderWidth: 3.0,
  /// );
  /// ```
  AnnotationTheme copyWith({
    Color? selectionBorderColor,
    Color? selectionBackgroundColor,
    Color? highlightBorderColor,
    Color? highlightBackgroundColor,
    double? borderWidth,
    BorderRadius? borderRadius,
    TextStyle? labelStyle,
  }) {
    return AnnotationTheme(
      selectionBorderColor: selectionBorderColor ?? this.selectionBorderColor,
      selectionBackgroundColor:
          selectionBackgroundColor ?? this.selectionBackgroundColor,
      highlightBorderColor: highlightBorderColor ?? this.highlightBorderColor,
      highlightBackgroundColor:
          highlightBackgroundColor ?? this.highlightBackgroundColor,
      borderWidth: borderWidth ?? this.borderWidth,
      borderRadius: borderRadius ?? this.borderRadius,
      labelStyle: labelStyle ?? this.labelStyle,
    );
  }

  /// A predefined light theme for annotations.
  ///
  /// This theme is designed for use in light-themed applications with:
  /// - Cyan selection colors (matching default selection theme)
  /// - Orange highlight colors for drag-over feedback
  /// - Subtle semi-transparent backgrounds
  ///
  /// Colors:
  /// - Selection: Cyan (#00BCD4)
  /// - Highlight: Orange (#FF9800)
  static const light = AnnotationTheme(
    selectionBorderColor: Color(0xFF00BCD4),
    selectionBackgroundColor: Color(0x1A00BCD4),
    highlightBorderColor: Color(0xFFFF9800),
    highlightBackgroundColor: Color(0x1AFF9800),
    borderWidth: 1.0,
    borderRadius: BorderRadius.all(Radius.circular(8.0)),
    labelStyle: TextStyle(
      fontSize: 12,
      fontWeight: FontWeight.w500,
      color: Color(0xFF212121), // Close to black
    ),
  );

  /// A predefined dark theme for annotations.
  ///
  /// This theme is designed for use in dark-themed applications with:
  /// - Light blue selection colors
  /// - Amber highlight colors for drag-over feedback
  /// - Subtle semi-transparent backgrounds
  ///
  /// Colors:
  /// - Selection: Light Blue (#64B5F6)
  /// - Highlight: Amber (#FFB74D)
  static const dark = AnnotationTheme(
    selectionBorderColor: Color(0xFF64B5F6),
    selectionBackgroundColor: Color(0x1A64B5F6),
    highlightBorderColor: Color(0xFFFFB74D),
    highlightBackgroundColor: Color(0x1AFFB74D),
    borderWidth: 1.0,
    borderRadius: BorderRadius.all(Radius.circular(8.0)),
    labelStyle: TextStyle(
      fontSize: 12,
      fontWeight: FontWeight.w500,
      color: Color(0xFFE0E0E0), // Light color for dark theme
    ),
  );
}
