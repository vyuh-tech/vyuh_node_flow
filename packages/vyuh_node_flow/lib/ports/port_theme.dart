import 'package:flutter/material.dart';

/// Theme configuration for port visual appearance.
///
/// [PortTheme] defines the visual styling of ports in the flow editor,
/// including colors for different interaction states, size, and border styling.
///
/// The theme supports different visual states:
/// - Normal state (default appearance)
/// - Connected state (when the port has active connections)
/// - Snapping state (when a connection is being dragged near the port)
///
/// Example:
/// ```dart
/// // Create a custom port theme
/// final customTheme = PortTheme(
///   size: 12.0,
///   color: Colors.grey,
///   connectedColor: Colors.green,
///   snappingColor: Colors.lightGreen,
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
  /// - [size]: The diameter of the port in logical pixels
  /// - [color]: Default color when the port is idle
  /// - [connectedColor]: Color when the port has active connections
  /// - [snappingColor]: Color when a connection is being dragged near
  /// - [borderColor]: Color of the port's border
  /// - [borderWidth]: Width of the port's border in logical pixels
  const PortTheme({
    required this.size,
    required this.color,
    required this.connectedColor,
    required this.snappingColor,
    required this.borderColor,
    required this.borderWidth,
  });

  /// The diameter of the port in logical pixels.
  ///
  /// This determines the visual size of the port and its hit area for
  /// interaction. Typical values range from 6.0 to 15.0.
  final double size;

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

  /// The color of the port when a connection is being dragged near it.
  ///
  /// This provides visual feedback during connection creation, indicating
  /// that the port is a valid target for the connection being dragged.
  final Color snappingColor;

  /// The color of the port's border.
  ///
  /// When [borderWidth] is greater than 0, this color is used for the
  /// port's outline.
  final Color borderColor;

  /// The width of the port's border in logical pixels.
  ///
  /// Set to 0.0 for no border. Typical values range from 1.0 to 3.0.
  final double borderWidth;

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
    double? size,
    Color? color,
    Color? connectedColor,
    Color? snappingColor,
    Color? borderColor,
    double? borderWidth,
  }) {
    return PortTheme(
      size: size ?? this.size,
      color: color ?? this.color,
      connectedColor: connectedColor ?? this.connectedColor,
      snappingColor: snappingColor ?? this.snappingColor,
      borderColor: borderColor ?? this.borderColor,
      borderWidth: borderWidth ?? this.borderWidth,
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
  /// - Snapping: Dark blue (#1565C0)
  static const light = PortTheme(
    size: 9.0,
    color: Color(0xFFBABABA),
    connectedColor: Color(0xFF2196F3),
    snappingColor: Color(0xFF1565C0),
    borderColor: Colors.transparent,
    borderWidth: 0.0,
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
  /// - Snapping: Medium blue (#42A5F5)
  static const dark = PortTheme(
    size: 9.0,
    color: Color(0xFF666666),
    connectedColor: Color(0xFF64B5F6),
    snappingColor: Color(0xFF42A5F5),
    borderColor: Colors.transparent,
    borderWidth: 0.0,
  );
}
