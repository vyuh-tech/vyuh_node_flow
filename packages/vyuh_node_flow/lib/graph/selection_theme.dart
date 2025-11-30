import 'package:flutter/material.dart';

/// Theme configuration for the selection rectangle appearance.
///
/// [SelectionTheme] defines the visual styling of the selection rectangle
/// that appears when dragging to select multiple nodes. It also affects
/// the appearance of selected nodes and connections.
///
/// Example:
/// ```dart
/// // Create a custom selection theme
/// final customTheme = SelectionTheme(
///   color: Colors.blue.withOpacity(0.2),
///   borderColor: Colors.blue,
///   borderWidth: 2.0,
/// );
///
/// // Or use a predefined theme
/// final lightTheme = SelectionTheme.light;
/// final darkTheme = SelectionTheme.dark;
/// ```
class SelectionTheme {
  /// Creates a selection theme with the specified visual properties.
  ///
  /// Parameters:
  /// - [color]: Fill color for the selection rectangle (typically semi-transparent)
  /// - [borderColor]: Border color for the selection rectangle
  /// - [borderWidth]: Width of the selection rectangle border in pixels
  const SelectionTheme({
    required this.color,
    required this.borderColor,
    required this.borderWidth,
  });

  /// Fill color for the selection rectangle.
  ///
  /// Used when dragging to select multiple nodes. Typically semi-transparent.
  final Color color;

  /// Border color for the selection rectangle.
  ///
  /// Also used as the selection indicator color for nodes and connections.
  final Color borderColor;

  /// Border width for the selection rectangle in pixels.
  final double borderWidth;

  /// Creates a copy of this theme with the specified properties replaced.
  SelectionTheme copyWith({
    Color? color,
    Color? borderColor,
    double? borderWidth,
  }) {
    return SelectionTheme(
      color: color ?? this.color,
      borderColor: borderColor ?? this.borderColor,
      borderWidth: borderWidth ?? this.borderWidth,
    );
  }

  /// A predefined light theme for selection.
  ///
  /// Features a cyan selection color suitable for light backgrounds.
  static const light = SelectionTheme(
    color: Color(0x3300BCD4),
    borderColor: Color(0xFF00BCD4),
    borderWidth: 1.0,
  );

  /// A predefined dark theme for selection.
  ///
  /// Features a light blue selection color suitable for dark backgrounds.
  static const dark = SelectionTheme(
    color: Color(0x3364B5F6),
    borderColor: Color(0xFF64B5F6),
    borderWidth: 1.0,
  );
}
