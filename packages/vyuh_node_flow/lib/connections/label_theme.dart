import 'package:flutter/material.dart';

/// Defines the visual styling for connection labels.
///
/// Connection labels can appear in three positions on a connection:
/// - **Center label**: Positioned at the midpoint (t=0.5) of the connection path
/// - **Start label**: Positioned near the source endpoint
/// - **End label**: Positioned near the target endpoint
///
/// [LabelTheme] controls the appearance of the label text and its background
/// container, including colors, borders, padding, and positioning offsets.
///
/// ## Usage Example
/// ```dart
/// const labelTheme = LabelTheme(
///   color: Colors.black,
///   fontSize: 12.0,
///   backgroundColor: Colors.white,
///   borderColor: Colors.grey,
///   borderWidth: 1.0,
///   padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
///   borderRadius: 4.0,
///   horizontalOffset: 10.0,
///   verticalOffset: 10.0,
/// );
/// ```
///
/// ## Positioning
/// - [horizontalOffset]: Distance from endpoint for left/right port positions
/// - [verticalOffset]: Distance from endpoint for top/bottom port positions
///
/// See also:
/// - [Connection] for applying labels to connections
/// - [NodeFlowTheme] for overall theme configuration
class LabelTheme {
  /// Creates a label theme with the specified styling properties.
  ///
  /// Parameters:
  /// - [color]: Text color (defaults to theme's text color if null)
  /// - [fontSize]: Font size in logical pixels (defaults to theme if null)
  /// - [fontWeight]: Font weight (e.g., FontWeight.bold)
  /// - [fontFamily]: Font family name
  /// - [backgroundColor]: Background color of the label container
  /// - [padding]: Padding inside the label container
  /// - [borderRadius]: Corner radius of the label container
  /// - [borderColor]: Border color of the label container
  /// - [borderWidth]: Border width in logical pixels
  /// - [horizontalOffset]: Horizontal distance from endpoint for left/right ports
  /// - [verticalOffset]: Vertical distance from endpoint for top/bottom ports
  const LabelTheme({
    this.color,
    this.fontSize,
    this.fontWeight,
    this.fontFamily,
    this.backgroundColor,
    this.padding = const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
    this.borderRadius = 4.0,
    this.borderColor,
    this.borderWidth = 1.0,
    this.horizontalOffset = 8.0,
    this.verticalOffset = 8.0,
  });

  /// Text color.
  ///
  /// If null, uses the default text color from the Flutter theme.
  final Color? color;

  /// Font size in logical pixels.
  ///
  /// If null, uses the default font size from the Flutter theme.
  final double? fontSize;

  /// Font weight (e.g., FontWeight.normal, FontWeight.bold).
  final FontWeight? fontWeight;

  /// Font family name.
  ///
  /// If null, uses the default font family from the Flutter theme.
  final String? fontFamily;

  /// Background color of the label container.
  ///
  /// If null, the label will have a transparent background.
  final Color? backgroundColor;

  /// Padding inside the label container.
  ///
  /// Defaults to 6 pixels horizontal and 2 pixels vertical.
  final EdgeInsets padding;

  /// Corner radius of the label container in logical pixels.
  ///
  /// Defaults to 4.0.
  final double borderRadius;

  /// Border color of the label container.
  ///
  /// If null, no border is drawn.
  final Color? borderColor;

  /// Border width in logical pixels.
  ///
  /// Defaults to 1.0. Only visible if [borderColor] is non-null.
  final double borderWidth;

  /// Horizontal distance from endpoint for left/right port positions.
  ///
  /// When a port is positioned on the left or right side, this offset
  /// determines how far the label is placed from the endpoint marker.
  /// Defaults to 8.0 logical pixels.
  final double horizontalOffset;

  /// Vertical distance from endpoint for top/bottom port positions.
  ///
  /// When a port is positioned on the top or bottom side, this offset
  /// determines how far the label is placed from the endpoint marker.
  /// Defaults to 8.0 logical pixels.
  final double verticalOffset;

  /// Creates a [TextStyle] from this theme's text properties.
  ///
  /// This is used internally for rendering label text. The returned style
  /// includes the [color], [fontSize], [fontWeight], and [fontFamily].
  TextStyle get textStyle => TextStyle(
    color: color,
    fontSize: fontSize,
    fontWeight: fontWeight,
    fontFamily: fontFamily,
  );
}
