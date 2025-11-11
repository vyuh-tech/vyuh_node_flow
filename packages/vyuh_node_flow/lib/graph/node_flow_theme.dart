import 'dart:ui' show lerpDouble;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../connections/connection_endpoint.dart';
import '../connections/connection_theme.dart';
import '../connections/styles/connection_styles.dart';
import '../connections/label_theme.dart';
import '../nodes/node_theme.dart';
import '../ports/port_theme.dart';
import 'grid_styles.dart';
import 'painters/grid_style.dart';

/// Theme configuration for the node flow editor.
///
/// Defines the visual appearance and styling for all elements in the node flow
/// editor including nodes, connections, ports, grid, and interaction feedback.
///
/// The theme uses Flutter's [ThemeExtension] pattern, allowing it to be
/// integrated with Flutter's theming system and accessed via `Theme.of(context)`.
///
/// Two built-in themes are provided:
/// - [NodeFlowTheme.light]: Light color scheme suitable for bright backgrounds
/// - [NodeFlowTheme.dark]: Dark color scheme suitable for dark backgrounds
///
/// Example usage:
/// ```dart
/// // Use a built-in theme
/// NodeFlowEditor(
///   theme: NodeFlowTheme.light,
///   // ...
/// );
///
/// // Customize a theme
/// final customTheme = NodeFlowTheme.light.copyWith(
///   backgroundColor: Colors.grey[100],
///   gridStyle: GridStyles.hierarchical,
///   nodeTheme: NodeTheme.light.copyWith(
///     defaultColor: Colors.blue,
///   ),
/// );
///
/// // Access theme from context (when using Theme widget)
/// final theme = Theme.of(context).extension<NodeFlowTheme>()!;
/// ```
class NodeFlowTheme extends ThemeExtension<NodeFlowTheme> {
  const NodeFlowTheme({
    required this.nodeTheme,
    required this.connectionTheme,
    required this.temporaryConnectionTheme,
    this.connectionAnimationDuration = const Duration(seconds: 2),
    required this.portTheme,
    required this.labelTheme,
    this.backgroundColor = Colors.white,
    this.gridColor = const Color(0xFF919191),
    this.gridSize = 20.0,
    this.gridThickness = 0.5,
    this.gridStyle = GridStyles.dots,
    this.selectionColor = const Color(0x3300BCD4),
    this.selectionBorderColor = const Color(0xFF00BCD4),
    this.selectionBorderWidth = 1.0,
    this.cursorStyle = SystemMouseCursors.basic,
    this.dragCursorStyle = SystemMouseCursors.grabbing,
    this.nodeCursorStyle = SystemMouseCursors.click,
    this.portCursorStyle = SystemMouseCursors.precise,
    this.debugMode = false,
  });

  /// Theme for node appearance (colors, borders, shadows, etc.).
  final NodeTheme nodeTheme;

  /// Theme for established connection appearance (colors, stroke width, style, etc.).
  final ConnectionTheme connectionTheme;

  /// Theme for temporary connection appearance during connection creation.
  final ConnectionTheme temporaryConnectionTheme;

  /// Duration for the connection animation controller cycle.
  ///
  /// This controls how long a full cycle of connection animation effects takes.
  /// Effects like flowing dashes, particles, and gradients will complete one
  /// full cycle in this duration. Default is 2 seconds.
  final Duration connectionAnimationDuration;

  /// Theme for port appearance (size, colors, shapes).
  final PortTheme portTheme;

  /// Theme for connection label styling (font, background, positioning).
  final LabelTheme labelTheme;

  /// Background color of the canvas.
  final Color backgroundColor;

  /// Color of the grid lines or dots.
  final Color gridColor;

  /// Spacing between grid lines in pixels.
  ///
  /// Default is 20.0. Applies to both horizontal and vertical spacing.
  final double gridSize;

  /// Thickness of grid lines in pixels.
  ///
  /// Default is 0.5. For dot style, this affects dot radius.
  final double gridThickness;

  /// The grid style to render on the canvas background.
  ///
  /// Use constants from [GridStyles] class or create a custom [GridStyle].
  /// Use [GridStyles.none] for no grid.
  ///
  /// Default is [GridStyles.dots].
  ///
  /// Example:
  /// ```dart
  /// // Using GridStyles constants
  /// gridStyle: GridStyles.lines,
  /// gridStyle: GridStyles.hierarchical,
  ///
  /// // Custom grid style
  /// gridStyle: MyCustomGridStyle(),
  ///
  /// // No grid
  /// gridStyle: GridStyles.none,
  /// ```
  final GridStyle gridStyle;

  /// Fill color for the selection rectangle.
  ///
  /// Used when dragging to select multiple nodes. Typically semi-transparent.
  final Color selectionColor;

  /// Border color for the selection rectangle.
  final Color selectionBorderColor;

  /// Border width for the selection rectangle in pixels.
  final double selectionBorderWidth;

  /// Default mouse cursor style for the canvas.
  final SystemMouseCursor cursorStyle;

  /// Mouse cursor style when dragging nodes or panning.
  final SystemMouseCursor dragCursorStyle;

  /// Mouse cursor style when hovering over nodes.
  final SystemMouseCursor nodeCursorStyle;

  /// Mouse cursor style when hovering over ports or creating connections.
  final SystemMouseCursor portCursorStyle;

  /// Whether to enable debug visualization.
  ///
  /// When true, may show additional overlays like bounds, hit areas, etc.
  final bool debugMode;

  @override
  NodeFlowTheme copyWith({
    NodeTheme? nodeTheme,
    ConnectionTheme? connectionTheme,
    ConnectionTheme? temporaryConnectionTheme,
    Duration? connectionAnimationDuration,
    PortTheme? portTheme,
    LabelTheme? labelTheme,
    Color? backgroundColor,
    Color? gridColor,
    double? gridSize,
    double? gridThickness,
    GridStyle? gridStyle,
    Color? selectionColor,
    Color? selectionBorderColor,
    double? selectionBorderWidth,
    SystemMouseCursor? cursorStyle,
    SystemMouseCursor? dragCursorStyle,
    SystemMouseCursor? nodeCursorStyle,
    SystemMouseCursor? portCursorStyle,
    bool? debugMode,
  }) {
    return NodeFlowTheme(
      nodeTheme: nodeTheme ?? this.nodeTheme,
      connectionTheme: connectionTheme ?? this.connectionTheme,
      temporaryConnectionTheme:
          temporaryConnectionTheme ?? this.temporaryConnectionTheme,
      connectionAnimationDuration:
          connectionAnimationDuration ?? this.connectionAnimationDuration,
      portTheme: portTheme ?? this.portTheme,
      labelTheme: labelTheme ?? this.labelTheme,
      backgroundColor: backgroundColor ?? this.backgroundColor,
      gridColor: gridColor ?? this.gridColor,
      gridSize: gridSize ?? this.gridSize,
      gridThickness: gridThickness ?? this.gridThickness,
      gridStyle: gridStyle ?? this.gridStyle,
      selectionColor: selectionColor ?? this.selectionColor,
      selectionBorderColor: selectionBorderColor ?? this.selectionBorderColor,
      selectionBorderWidth: selectionBorderWidth ?? this.selectionBorderWidth,
      cursorStyle: cursorStyle ?? this.cursorStyle,
      dragCursorStyle: dragCursorStyle ?? this.dragCursorStyle,
      nodeCursorStyle: nodeCursorStyle ?? this.nodeCursorStyle,
      portCursorStyle: portCursorStyle ?? this.portCursorStyle,
      debugMode: debugMode ?? this.debugMode,
    );
  }

  @override
  NodeFlowTheme lerp(NodeFlowTheme? other, double t) {
    if (other is! NodeFlowTheme) return this;

    return NodeFlowTheme(
      nodeTheme: nodeTheme,
      // NodeTheme doesn't support lerp
      connectionTheme: connectionTheme,
      // ConnectionTheme doesn't support lerp
      temporaryConnectionTheme: temporaryConnectionTheme,
      // ConnectionTheme doesn't support lerp
      connectionAnimationDuration: t < 0.5
          ? connectionAnimationDuration
          : other.connectionAnimationDuration,
      portTheme: portTheme,
      // PortTheme doesn't support lerp
      labelTheme: t < 0.5 ? labelTheme : other.labelTheme,
      backgroundColor:
          Color.lerp(backgroundColor, other.backgroundColor, t) ??
          backgroundColor,
      gridColor: Color.lerp(gridColor, other.gridColor, t) ?? gridColor,
      gridSize: lerpDouble(gridSize, other.gridSize, t) ?? gridSize,
      gridThickness:
          lerpDouble(gridThickness, other.gridThickness, t) ?? gridThickness,
      gridStyle: t < 0.5 ? gridStyle : other.gridStyle,
      selectionColor:
          Color.lerp(selectionColor, other.selectionColor, t) ?? selectionColor,
      selectionBorderColor:
          Color.lerp(selectionBorderColor, other.selectionBorderColor, t) ??
          selectionBorderColor,
      selectionBorderWidth:
          lerpDouble(selectionBorderWidth, other.selectionBorderWidth, t) ??
          selectionBorderWidth,
      cursorStyle: t < 0.5 ? cursorStyle : other.cursorStyle,
      dragCursorStyle: t < 0.5 ? dragCursorStyle : other.dragCursorStyle,
      nodeCursorStyle: t < 0.5 ? nodeCursorStyle : other.nodeCursorStyle,
      portCursorStyle: t < 0.5 ? portCursorStyle : other.portCursorStyle,
      debugMode: t < 0.5 ? debugMode : other.debugMode,
    );
  }

  /// Built-in light theme with bright colors and subtle grid.
  ///
  /// Suitable for applications with light backgrounds. Features:
  /// - White background
  /// - Light grey dot grid
  /// - Blue selection and highlights
  /// - Black text and borders
  static const light = NodeFlowTheme(
    nodeTheme: NodeTheme.light,
    connectionTheme: ConnectionTheme.light,
    temporaryConnectionTheme: ConnectionTheme(
      style: ConnectionStyles.smoothstep,
      color: Color(0xFF666666),
      selectedColor: Color(0xFF2196F3),
      strokeWidth: 2.0,
      selectedStrokeWidth: 3.0,
      startPoint: ConnectionEndPoint.none,
      endPoint: ConnectionEndPoint.capsuleHalf,
      bezierCurvature: 0.5,
      dashPattern: [5, 5],
    ),
    portTheme: PortTheme.light,
    labelTheme: LabelTheme(
      textStyle: TextStyle(
        color: Color(0xFF333333),
        fontSize: 12.0,
        fontWeight: FontWeight.w500,
      ),
      backgroundColor: Color(0xFFFBFBFB),
      border: Border.fromBorderSide(
        BorderSide(color: Color(0xFFDDDDDD), width: 1.0),
      ),
      borderRadius: BorderRadius.all(Radius.circular(4.0)),
      offset: 0.0,
    ),
    backgroundColor: Colors.white,
    gridColor: Color(0xFFC8C8C8),
    gridSize: 20.0,
    gridThickness: 1,
    gridStyle: GridStyles.dots,
    selectionColor: Color(0x3300BCD4),
    selectionBorderColor: Color(0xFF00BCD4),
    selectionBorderWidth: 1.0,
    cursorStyle: SystemMouseCursors.grab,
    dragCursorStyle: SystemMouseCursors.grabbing,
    nodeCursorStyle: SystemMouseCursors.click,
    portCursorStyle: SystemMouseCursors.precise,
  );

  /// Built-in dark theme with muted colors and visible grid.
  ///
  /// Suitable for applications with dark backgrounds. Features:
  /// - Dark grey background
  /// - Medium grey dot grid
  /// - Light blue selection and highlights
  /// - Light text and borders
  static final dark = NodeFlowTheme(
    nodeTheme: NodeTheme.dark,
    connectionTheme: ConnectionTheme.dark,
    temporaryConnectionTheme: ConnectionTheme(
      style: ConnectionStyles.smoothstep,
      color: Color(0xFF999999),
      selectedColor: Color(0xFF64B5F6),
      strokeWidth: 2.0,
      selectedStrokeWidth: 3.0,
      startPoint: ConnectionEndPoint.none,
      endPoint: ConnectionEndPoint.capsuleHalf,
      bezierCurvature: 0.5,
      dashPattern: [5, 5],
    ),
    portTheme: PortTheme.dark,
    labelTheme: LabelTheme(
      textStyle: TextStyle(
        color: Color(0xFFE5E5E5),
        fontSize: 12.0,
        fontWeight: FontWeight.w500,
      ),
      backgroundColor: Color(0xFF404040),
      border: Border.fromBorderSide(
        BorderSide(color: Color(0xFF606060), width: 1.0),
      ),
      borderRadius: BorderRadius.all(Radius.circular(4.0)),
      offset: 0.0,
    ),
    backgroundColor: const Color(0xFF1A1A1A),
    gridColor: const Color(0xFF707070),
    gridSize: 20.0,
    gridThickness: 1,
    gridStyle: GridStyles.dots,
    selectionColor: const Color(0x3364B5F6),
    selectionBorderColor: const Color(0xFF64B5F6),
    selectionBorderWidth: 1.0,
    cursorStyle: SystemMouseCursors.grab,
    dragCursorStyle: SystemMouseCursors.grabbing,
    nodeCursorStyle: SystemMouseCursors.click,
    portCursorStyle: SystemMouseCursors.precise,
  );
}
