import 'package:flutter/material.dart';

/// Theme configuration for port visual appearance and animations.
///
/// [PortTheme] defines the visual styling of ports in the flow editor,
/// including colors for different interaction states, size, border styling,
/// and animation timing.
///
/// The theme supports different visual states:
/// - Normal state (default appearance)
/// - Connected state (when the port has active connections)
/// - Hover state (when the cursor is over the port)
/// - Snapping state (when a connection is being dragged near the port)
/// - Dragging state (during connection creation)
///
/// Example:
/// ```dart
/// // Create a custom port theme
/// final customTheme = PortTheme(
///   size: 12.0,
///   color: Colors.grey,
///   connectedColor: Colors.green,
///   hoverColor: Colors.black,
///   snappingColor: Colors.lightGreen,
///   draggingColor: Colors.lightGreenAccent,
///   borderColor: Colors.white,
///   borderWidth: 2.0,
///   animationDuration: Duration(milliseconds: 200),
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
  /// - [hoverColor]: Color when the cursor hovers over the port
  /// - [snappingColor]: Color when a connection is being dragged near
  /// - [draggingColor]: Color during connection creation/dragging
  /// - [borderColor]: Color of the port's border
  /// - [borderWidth]: Width of the port's border in logical pixels
  /// - [animationDuration]: Duration for color transition animations
  const PortTheme({
    required this.size,
    required this.color,
    required this.connectedColor,
    required this.hoverColor,
    required this.snappingColor,
    required this.draggingColor,
    required this.borderColor,
    required this.borderWidth,
    required this.animationDuration,
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

  /// The color of the port when the cursor hovers over it.
  ///
  /// This provides visual feedback that the port is interactive and
  /// ready for user interaction.
  final Color hoverColor;

  /// The color of the port when a connection is being dragged near it.
  ///
  /// This provides visual feedback during connection creation, indicating
  /// that the port is a valid target for the connection being dragged.
  final Color snappingColor;

  /// The color of the port during connection dragging operations.
  ///
  /// This is shown while actively creating or modifying a connection
  /// involving this port.
  final Color draggingColor;

  /// The color of the port's border.
  ///
  /// When [borderWidth] is greater than 0, this color is used for the
  /// port's outline.
  final Color borderColor;

  /// The width of the port's border in logical pixels.
  ///
  /// Set to 0.0 for no border. Typical values range from 1.0 to 3.0.
  final double borderWidth;

  /// The duration for color transition animations between states.
  ///
  /// This controls how quickly the port transitions between different
  /// colors when changing states (e.g., from idle to hover).
  final Duration animationDuration;

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
    Color? hoverColor,
    Color? snappingColor,
    Color? draggingColor,
    Color? borderColor,
    double? borderWidth,
    Duration? animationDuration,
  }) {
    return PortTheme(
      size: size ?? this.size,
      color: color ?? this.color,
      connectedColor: connectedColor ?? this.connectedColor,
      hoverColor: hoverColor ?? this.hoverColor,
      snappingColor: snappingColor ?? this.snappingColor,
      draggingColor: draggingColor ?? this.draggingColor,
      borderColor: borderColor ?? this.borderColor,
      borderWidth: borderWidth ?? this.borderWidth,
      animationDuration: animationDuration ?? this.animationDuration,
    );
  }

  /// A predefined light theme for ports.
  ///
  /// This theme is designed for use in light-themed applications with:
  /// - Light gray idle color
  /// - Blue accent colors for interactions
  /// - Dark hover color for contrast
  /// - No border
  /// - 150ms animation duration
  ///
  /// Colors:
  /// - Idle: Light gray (#BABABA)
  /// - Connected: Material blue (#2196F3)
  /// - Hover: Dark gray (#1A1A1A)
  /// - Snapping: Dark blue (#1565C0)
  /// - Dragging: Light blue (#42A5F5)
  static const light = PortTheme(
    size: 9.0,
    color: Color(0xFFBABABA),
    connectedColor: Color(0xFF2196F3),
    hoverColor: Color(0xFF1A1A1A),
    snappingColor: Color(0xFF1565C0),
    draggingColor: Color(0xFF42A5F5),
    borderColor: Colors.transparent,
    borderWidth: 0.0,
    animationDuration: Duration(milliseconds: 150),
  );

  /// A predefined dark theme for ports.
  ///
  /// This theme is designed for use in dark-themed applications with:
  /// - Medium gray idle color
  /// - Light blue accent colors for interactions
  /// - Light hover color for contrast
  /// - No border
  /// - 150ms animation duration
  ///
  /// Colors:
  /// - Idle: Medium gray (#666666)
  /// - Connected: Light blue (#64B5F6)
  /// - Hover: Light gray (#BBBBBB)
  /// - Snapping: Medium blue (#42A5F5)
  /// - Dragging: Very light blue (#90CAF9)
  static const dark = PortTheme(
    size: 9.0,
    color: Color(0xFF666666),
    connectedColor: Color(0xFF64B5F6),
    hoverColor: Color(0xFFBBBBBB),
    snappingColor: Color(0xFF42A5F5),
    draggingColor: Color(0xFF90CAF9),
    borderColor: Colors.transparent,
    borderWidth: 0.0,
    animationDuration: Duration(milliseconds: 150),
  );
}
