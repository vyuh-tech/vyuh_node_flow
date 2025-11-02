import 'package:flutter/material.dart';

/// Theme configuration for node appearance and styling.
///
/// This class defines all visual properties for nodes in different states
/// (normal, selected, hover, dragging). It includes colors, borders, text
/// styles, and sizing constraints.
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
    required this.hoverBackgroundColor,
    required this.draggingBackgroundColor,
    required this.borderColor,
    required this.selectedBorderColor,
    required this.hoverBorderColor,
    required this.draggingBorderColor,
    required this.borderWidth,
    required this.selectedBorderWidth,
    required this.hoverBorderWidth,
    required this.draggingBorderWidth,
    required this.borderRadius,
    required this.padding,
    required this.titleStyle,
    required this.contentStyle,
    required this.animationDuration,
    required this.minWidth,
    required this.minHeight,
  });

  /// Background color for nodes in normal state.
  final Color backgroundColor;

  /// Background color for selected nodes.
  final Color selectedBackgroundColor;

  /// Background color when the node is being hovered over.
  final Color hoverBackgroundColor;

  /// Background color while the node is being dragged.
  final Color draggingBackgroundColor;

  /// Border color for nodes in normal state.
  final Color borderColor;

  /// Border color for selected nodes.
  final Color selectedBorderColor;

  /// Border color when the node is being hovered over.
  final Color hoverBorderColor;

  /// Border color while the node is being dragged.
  final Color draggingBorderColor;

  /// Border width for nodes in normal state.
  final double borderWidth;

  /// Border width for selected nodes.
  final double selectedBorderWidth;

  /// Border width when the node is being hovered over.
  final double hoverBorderWidth;

  /// Border width while the node is being dragged.
  final double draggingBorderWidth;

  /// Corner radius for node borders.
  final BorderRadius borderRadius;

  /// Padding inside the node container.
  final EdgeInsets padding;

  /// Text style for the node title.
  final TextStyle titleStyle;

  /// Text style for the node content.
  final TextStyle contentStyle;

  /// Duration for node state transition animations.
  final Duration animationDuration;

  /// Minimum width constraint for nodes.
  final double minWidth;

  /// Minimum height constraint for nodes.
  final double minHeight;

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
    Color? hoverBackgroundColor,
    Color? draggingBackgroundColor,
    Color? borderColor,
    Color? selectedBorderColor,
    Color? hoverBorderColor,
    Color? draggingBorderColor,
    double? borderWidth,
    double? selectedBorderWidth,
    double? hoverBorderWidth,
    double? draggingBorderWidth,
    BorderRadius? borderRadius,
    EdgeInsets? padding,
    TextStyle? titleStyle,
    TextStyle? contentStyle,
    Duration? animationDuration,
    double? minWidth,
    double? minHeight,
  }) {
    return NodeTheme(
      backgroundColor: backgroundColor ?? this.backgroundColor,
      selectedBackgroundColor:
          selectedBackgroundColor ?? this.selectedBackgroundColor,
      hoverBackgroundColor: hoverBackgroundColor ?? this.hoverBackgroundColor,
      draggingBackgroundColor:
          draggingBackgroundColor ?? this.draggingBackgroundColor,
      borderColor: borderColor ?? this.borderColor,
      selectedBorderColor: selectedBorderColor ?? this.selectedBorderColor,
      hoverBorderColor: hoverBorderColor ?? this.hoverBorderColor,
      draggingBorderColor: draggingBorderColor ?? this.draggingBorderColor,
      borderWidth: borderWidth ?? this.borderWidth,
      selectedBorderWidth: selectedBorderWidth ?? this.selectedBorderWidth,
      hoverBorderWidth: hoverBorderWidth ?? this.hoverBorderWidth,
      draggingBorderWidth: draggingBorderWidth ?? this.draggingBorderWidth,
      borderRadius: borderRadius ?? this.borderRadius,
      padding: padding ?? this.padding,
      titleStyle: titleStyle ?? this.titleStyle,
      contentStyle: contentStyle ?? this.contentStyle,
      animationDuration: animationDuration ?? this.animationDuration,
      minWidth: minWidth ?? this.minWidth,
      minHeight: minHeight ?? this.minHeight,
    );
  }

  /// Pre-configured light theme for nodes.
  ///
  /// Features white background, subtle gray borders, and blue accents for
  /// selected states. Suitable for light mode applications.
  static const light = NodeTheme(
    backgroundColor: Colors.white,
    selectedBackgroundColor: Color(0xFFF5F5F5),
    hoverBackgroundColor: Color(0xFFFAFAFA),
    draggingBackgroundColor: Color(0xFFF0F0F0),
    borderColor: Color(0xFFE0E0E0),
    selectedBorderColor: Color(0xFF2196F3),
    hoverBorderColor: Color(0xFFCCCCCC),
    draggingBorderColor: Color(0xFF2196F3),
    borderWidth: 2.0,
    selectedBorderWidth: 2.0,
    hoverBorderWidth: 2.0,
    draggingBorderWidth: 2.0,
    borderRadius: BorderRadius.all(Radius.circular(8.0)),
    padding: EdgeInsets.all(4.0),
    titleStyle: TextStyle(
      fontSize: 14.0,
      fontWeight: FontWeight.bold,
      color: Color(0xFF333333),
    ),
    contentStyle: TextStyle(fontSize: 12.0, color: Color(0xFF666666)),
    animationDuration: Duration(milliseconds: 200),
    minWidth: 150.0,
    minHeight: 100.0,
  );

  /// Pre-configured dark theme for nodes.
  ///
  /// Features dark gray background, lighter gray borders, and light blue accents
  /// for selected states. Suitable for dark mode applications.
  static const dark = NodeTheme(
    backgroundColor: Color(0xFF2D2D2D),
    selectedBackgroundColor: Color(0xFF3D3D3D),
    hoverBackgroundColor: Color(0xFF353535),
    draggingBackgroundColor: Color(0xFF404040),
    borderColor: Color(0xFF555555),
    selectedBorderColor: Color(0xFF64B5F6),
    hoverBorderColor: Color(0xFF666666),
    draggingBorderColor: Color(0xFF64B5F6),
    borderWidth: 2.0,
    selectedBorderWidth: 2.0,
    hoverBorderWidth: 2.0,
    draggingBorderWidth: 2.0,
    borderRadius: BorderRadius.all(Radius.circular(8.0)),
    padding: EdgeInsets.all(4.0),
    titleStyle: TextStyle(
      fontSize: 14.0,
      fontWeight: FontWeight.bold,
      color: Color(0xFFE0E0E0),
    ),
    contentStyle: TextStyle(fontSize: 12.0, color: Color(0xFFB0B0B0)),
    animationDuration: Duration(milliseconds: 200),
    minWidth: 150.0,
    minHeight: 100.0,
  );
}
