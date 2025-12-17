import 'package:flutter/material.dart';

/// Theme configuration for node appearance and styling.
///
/// This class defines all visual properties for nodes in normal and selected states.
/// It includes colors, borders, text styles, and padding.
///
/// Use [NodeTheme.light] or [NodeTheme.dark] for pre-configured themes,
/// or create a custom theme with specific values.
///
/// Example usage:
/// ```dart
/// final customTheme = NodeTheme.light.copyWith(
///   backgroundColor: Colors.blue.shade50,
///   selectedBorderColor: Colors.blue,
/// );
/// ```
///
/// See also:
/// * [NodeFlowTheme], which includes this as part of the overall theme
/// * [NodeWidget], which uses this theme for rendering
class NodeTheme {
  /// Creates a new node theme with the specified properties.
  ///
  /// All parameters are required to ensure complete theme configuration.
  const NodeTheme({
    required this.backgroundColor,
    required this.selectedBackgroundColor,
    required this.highlightBackgroundColor,
    required this.borderColor,
    required this.selectedBorderColor,
    required this.highlightBorderColor,
    required this.borderWidth,
    required this.selectedBorderWidth,
    required this.borderRadius,
    required this.titleStyle,
    required this.contentStyle,
  });

  /// Background color for nodes in normal state.
  final Color backgroundColor;

  /// Background color for selected nodes.
  final Color selectedBackgroundColor;

  /// Background color for highlighted nodes (during hover).
  final Color highlightBackgroundColor;

  /// Border color for nodes in normal state.
  final Color borderColor;

  /// Border color for selected nodes.
  final Color selectedBorderColor;

  /// Border color for highlighted nodes (during hover).
  final Color highlightBorderColor;

  /// Border width for nodes in normal state.
  final double borderWidth;

  /// Border width for selected nodes.
  final double selectedBorderWidth;

  /// Corner radius for node borders.
  final BorderRadius borderRadius;

  /// Text style for the node title.
  final TextStyle titleStyle;

  /// Text style for the node content.
  final TextStyle contentStyle;

  /// Creates a copy of this theme with the specified properties overridden.
  ///
  /// Any properties not provided will use the values from the current theme.
  /// This is useful for creating variations of existing themes.
  ///
  /// Example:
  /// ```dart
  /// final customTheme = NodeTheme.light.copyWith(
  ///   selectedBorderColor: Colors.red,
  ///   selectedBorderWidth: 3.0,
  /// );
  /// ```
  NodeTheme copyWith({
    Color? backgroundColor,
    Color? selectedBackgroundColor,
    Color? highlightBackgroundColor,
    Color? borderColor,
    Color? selectedBorderColor,
    Color? highlightBorderColor,
    double? borderWidth,
    double? selectedBorderWidth,
    BorderRadius? borderRadius,
    TextStyle? titleStyle,
    TextStyle? contentStyle,
  }) {
    return NodeTheme(
      backgroundColor: backgroundColor ?? this.backgroundColor,
      selectedBackgroundColor:
          selectedBackgroundColor ?? this.selectedBackgroundColor,
      highlightBackgroundColor:
          highlightBackgroundColor ?? this.highlightBackgroundColor,
      borderColor: borderColor ?? this.borderColor,
      selectedBorderColor: selectedBorderColor ?? this.selectedBorderColor,
      highlightBorderColor: highlightBorderColor ?? this.highlightBorderColor,
      borderWidth: borderWidth ?? this.borderWidth,
      selectedBorderWidth: selectedBorderWidth ?? this.selectedBorderWidth,
      borderRadius: borderRadius ?? this.borderRadius,
      titleStyle: titleStyle ?? this.titleStyle,
      contentStyle: contentStyle ?? this.contentStyle,
    );
  }

  /// Pre-configured light theme for nodes.
  ///
  /// Features white background, subtle gray borders, and blue accents for
  /// selected states. Suitable for light mode applications.
  static const light = NodeTheme(
    backgroundColor: Colors.white,
    selectedBackgroundColor: Color(0xFFF5F5F5),
    highlightBackgroundColor: Color(0xFFE3F2FD),
    borderColor: Color(0xFFE0E0E0),
    selectedBorderColor: Color(0xFF2196F3),
    highlightBorderColor: Color(0xFF42A5F5),
    borderWidth: 2.0,
    selectedBorderWidth: 2.0,
    borderRadius: BorderRadius.all(Radius.circular(8.0)),
    titleStyle: TextStyle(
      fontSize: 14.0,
      fontWeight: FontWeight.bold,
      color: Color(0xFF333333),
    ),
    contentStyle: TextStyle(fontSize: 12.0, color: Color(0xFF666666)),
  );

  /// Pre-configured dark theme for nodes.
  ///
  /// Features dark gray background, lighter gray borders, and light blue accents
  /// for selected states. Suitable for dark mode applications.
  static const dark = NodeTheme(
    backgroundColor: Color(0xFF2D2D2D),
    selectedBackgroundColor: Color(0xFF3D3D3D),
    highlightBackgroundColor: Color(0xFF263238),
    borderColor: Color(0xFF555555),
    selectedBorderColor: Color(0xFF64B5F6),
    highlightBorderColor: Color(0xFF90CAF9),
    borderWidth: 2.0,
    selectedBorderWidth: 2.0,
    borderRadius: BorderRadius.all(Radius.circular(8.0)),
    titleStyle: TextStyle(
      fontSize: 14.0,
      fontWeight: FontWeight.bold,
      color: Color(0xFFE0E0E0),
    ),
    contentStyle: TextStyle(fontSize: 12.0, color: Color(0xFFB0B0B0)),
  );
}
