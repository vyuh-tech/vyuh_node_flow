import 'package:flutter/material.dart';

import '../shared/shapes/marker_shape.dart';
import '../shared/shapes/marker_shapes.dart';
import 'port.dart';

/// Theme configuration for port visual appearance.
///
/// [PortTheme] defines the visual styling of ports in the flow editor,
/// including colors for different interaction states, size, and border styling.
///
/// The theme supports different visual states:
/// - Normal state (default appearance)
/// - Connected state (when the port has active connections)
/// - Highlighted state (when a connection is being dragged near the port)
///
/// Example:
/// ```dart
/// // Create a custom port theme
/// final customTheme = PortTheme(
///   size: Size(12, 12),
///   color: Colors.grey,
///   connectedColor: Colors.green,
///   highlightColor: Colors.lightGreen,
///   highlightBorderColor: Colors.black,
///   borderColor: Colors.white,
///   borderWidth: 2.0,
/// );
///
/// // Or use a predefined theme
/// final lightTheme = PortTheme.light;
/// final darkTheme = PortTheme.dark;
/// ```
class PortTheme {
  /// Creates a port theme with the specified visual properties.
  ///
  /// All parameters are required to ensure consistent theming across
  /// different port states.
  ///
  /// Parameters:
  /// - [size]: The size of the port in logical pixels (width, height)
  /// - [color]: Default color when the port is idle
  /// - [connectedColor]: Color when the port has active connections
  /// - [highlightColor]: Color when port is highlighted during connection drag
  /// - [highlightBorderColor]: Border color when port is highlighted
  /// - [borderColor]: Color of the port's border
  /// - [borderWidth]: Width of the port's border in logical pixels
  /// - [showLabel]: Whether to show port labels globally (default: false)
  /// - [labelTextStyle]: Text style for port labels
  /// - [labelOffset]: Distance from port center to label (default: 8.0)
  /// - [labelVisibilityThreshold]: Minimum zoom level to show labels (default: 0.5)
  /// - [shape]: Default marker shape for ports (default: capsuleHalf)
  const PortTheme({
    required this.size,
    required this.color,
    required this.connectedColor,
    required this.highlightColor,
    required this.highlightBorderColor,
    required this.borderColor,
    required this.borderWidth,
    this.shape = MarkerShapes.capsuleHalf,
    this.showLabel = false,
    this.labelTextStyle,
    this.labelOffset = 4.0,
    this.labelVisibilityThreshold = 0.5,
  });

  /// The size of the port in logical pixels.
  ///
  /// This determines the visual size of the port and its hit area for
  /// interaction. Width and height can differ for asymmetric port shapes.
  final Size size;

  /// The default color of the port when idle.
  ///
  /// This is the base color shown when the port is visible but not
  /// being interacted with.
  final Color color;

  /// The color of the port when it has active connections.
  ///
  /// This provides visual feedback that the port is currently connected
  /// to other nodes in the flow.
  final Color connectedColor;

  /// The fill color when the port is highlighted (being hovered during drag).
  ///
  /// This provides strong visual feedback during connection creation.
  final Color highlightColor;

  /// The border color when the port is highlighted (being hovered during drag).
  ///
  /// This provides strong visual feedback during connection creation, indicating
  /// that the port is a valid target.
  final Color highlightBorderColor;

  /// The color of the port's border.
  ///
  /// When [borderWidth] is greater than 0, this color is used for the
  /// port's outline.
  final Color borderColor;

  /// The width of the port's border in logical pixels.
  ///
  /// Set to 0.0 for no border. Typical values range from 1.0 to 3.0.
  final double borderWidth;

  /// Whether to show port labels globally for all ports.
  ///
  /// When false, labels are hidden for all ports regardless of individual
  /// port settings. When true, labels are shown based on individual port
  /// [Port.showLabel] settings. Default is false.
  final bool showLabel;

  /// The text style for port labels.
  ///
  /// If null, a default text style will be used based on the theme.
  /// This controls font size, color, weight, and other text properties.
  final TextStyle? labelTextStyle;

  /// The distance from the port center to the label in logical pixels.
  ///
  /// This controls how far the label appears from the port visual.
  /// Default is 8.0 pixels. Increase for more spacing, decrease for less.
  final double labelOffset;

  /// The minimum zoom level at which port labels become visible.
  ///
  /// Labels are hidden when the canvas zoom level is below this threshold
  /// to prevent visual clutter when zoomed out. Default is 0.5 (50% zoom).
  /// Set to 0.0 to always show labels regardless of zoom level.
  final double labelVisibilityThreshold;

  /// The default marker shape for ports.
  ///
  /// Individual ports can override this with their own [Port.shape] property.
  /// If a port's shape is not specified, this theme value is used as fallback.
  /// Default is [MarkerShapes.capsuleHalf].
  final MarkerShape shape;

  /// Resolves the effective size for a port.
  ///
  /// Uses the port's own size if set, otherwise falls back to the theme's size.
  /// This is the canonical method for port size resolution.
  Size resolveSize(Port port) => port.size ?? size;

  /// Creates a copy of this theme with the specified properties replaced.
  ///
  /// All parameters are optional. If a parameter is not provided, the
  /// corresponding property from the current theme is used.
  ///
  /// Example:
  /// ```dart
  /// final baseTheme = PortTheme.light;
  /// final customTheme = baseTheme.copyWith(
  ///   color: Colors.purple,
  ///   size: 12.0,
  /// );
  /// // customTheme uses purple color and size 12, but keeps all other
  /// // properties from the light theme
  /// ```
  PortTheme copyWith({
    Size? size,
    Color? color,
    Color? connectedColor,
    Color? highlightColor,
    Color? highlightBorderColor,
    Color? borderColor,
    double? borderWidth,
    MarkerShape? shape,
    bool? showLabel,
    TextStyle? labelTextStyle,
    double? labelOffset,
    double? labelVisibilityThreshold,
  }) {
    return PortTheme(
      size: size ?? this.size,
      color: color ?? this.color,
      connectedColor: connectedColor ?? this.connectedColor,
      highlightColor: highlightColor ?? this.highlightColor,
      highlightBorderColor: highlightBorderColor ?? this.highlightBorderColor,
      borderColor: borderColor ?? this.borderColor,
      borderWidth: borderWidth ?? this.borderWidth,
      shape: shape ?? this.shape,
      showLabel: showLabel ?? this.showLabel,
      labelTextStyle: labelTextStyle ?? this.labelTextStyle,
      labelOffset: labelOffset ?? this.labelOffset,
      labelVisibilityThreshold:
          labelVisibilityThreshold ?? this.labelVisibilityThreshold,
    );
  }

  /// A predefined light theme for ports.
  ///
  /// This theme is designed for use in light-themed applications with:
  /// - Light gray idle color
  /// - Blue accent colors for interactions
  /// - No border
  ///
  /// Colors:
  /// - Idle: Light gray (#BABABA)
  /// - Connected: Material blue (#2196F3)
  /// - Highlight: Light blue (#42A5F5)
  static const light = PortTheme(
    size: Size(9, 9),
    color: Color(0xFFBABABA),
    connectedColor: Color(0xFF2196F3),
    highlightColor: Color(0xFF42A5F5),
    highlightBorderColor: Color(0xFF000000),
    borderColor: Colors.transparent,
    borderWidth: 0.0,
    showLabel: false,
    labelTextStyle: TextStyle(
      fontSize: 10.0,
      color: Color(0xFF333333),
      fontWeight: FontWeight.w500,
    ),
    labelOffset: 4.0,
    labelVisibilityThreshold: 0.5,
  );

  /// A predefined dark theme for ports.
  ///
  /// This theme is designed for use in dark-themed applications with:
  /// - Medium gray idle color
  /// - Light blue accent colors for interactions
  /// - No border
  ///
  /// Colors:
  /// - Idle: Medium gray (#666666)
  /// - Connected: Light blue (#64B5F6)
  /// - Highlight: Light blue (#90CAF9)
  static const dark = PortTheme(
    size: Size(9, 9),
    color: Color(0xFF666666),
    connectedColor: Color(0xFF64B5F6),
    highlightColor: Color(0xFF90CAF9),
    highlightBorderColor: Color(0xFFFFFFFF),
    borderColor: Colors.transparent,
    borderWidth: 0.0,
    showLabel: false,
    labelTextStyle: TextStyle(
      fontSize: 10.0,
      color: Color(0xFFE0E0E0),
      fontWeight: FontWeight.w500,
    ),
    labelOffset: 4.0,
    labelVisibilityThreshold: 0.5,
  );
}
