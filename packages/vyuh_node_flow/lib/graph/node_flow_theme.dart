import 'package:flutter/material.dart';

import '../annotations/annotation_theme.dart';
import '../connections/connection_endpoint.dart';
import '../connections/connection_theme.dart';
import '../connections/label_theme.dart';
import '../nodes/node_theme.dart';
import '../ports/port_theme.dart';
import 'cursor_theme.dart';
import '../grid/grid_theme.dart';
import 'selection_theme.dart';

/// Theme configuration for the node flow editor.
///
/// Defines the visual appearance and styling for all elements in the node flow
/// editor including nodes, connections, ports, grid, and interaction feedback.
///
/// The theme uses Flutter's [ThemeExtension] pattern, allowing it to be
/// integrated with Flutter's theming system and accessed via `Theme.of(context)`.
///
/// ## Theme Hierarchy
///
/// The theme is organized into logical sub-themes:
/// - [nodeTheme]: Node appearance (colors, borders, shadows)
/// - [connectionTheme]: Connection appearance (colors, stroke, style)
/// - [temporaryConnectionTheme]: Temporary connection during creation
/// - [portTheme]: Port appearance (size, colors, shapes)
/// - [labelTheme]: Connection label styling
/// - [annotationTheme]: Annotation appearance (selection, highlight)
/// - [gridTheme]: Grid background appearance
/// - [selectionTheme]: Selection rectangle and indicator colors
/// - [cursorTheme]: Mouse cursor styles for different interactions
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
///   gridTheme: GridTheme.light.copyWith(
///     style: GridStyles.hierarchical,
///   ),
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
    required this.annotationTheme,
    required this.gridTheme,
    required this.selectionTheme,
    required this.cursorTheme,
    this.backgroundColor = Colors.white,
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

  /// Theme for annotation appearance (selection, highlight colors).
  final AnnotationTheme annotationTheme;

  /// Theme for grid background appearance (color, size, style).
  final GridTheme gridTheme;

  /// Theme for selection rectangle and indicator colors.
  final SelectionTheme selectionTheme;

  /// Theme for mouse cursor styles.
  final CursorTheme cursorTheme;

  /// Background color of the canvas.
  final Color backgroundColor;

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
    AnnotationTheme? annotationTheme,
    GridTheme? gridTheme,
    SelectionTheme? selectionTheme,
    CursorTheme? cursorTheme,
    Color? backgroundColor,
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
      annotationTheme: annotationTheme ?? this.annotationTheme,
      gridTheme: gridTheme ?? this.gridTheme,
      selectionTheme: selectionTheme ?? this.selectionTheme,
      cursorTheme: cursorTheme ?? this.cursorTheme,
      backgroundColor: backgroundColor ?? this.backgroundColor,
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
      annotationTheme: t < 0.5 ? annotationTheme : other.annotationTheme,
      // AnnotationTheme doesn't support lerp
      gridTheme: t < 0.5 ? gridTheme : other.gridTheme,
      // GridTheme doesn't support lerp
      selectionTheme: t < 0.5 ? selectionTheme : other.selectionTheme,
      // SelectionTheme doesn't support lerp
      cursorTheme: t < 0.5 ? cursorTheme : other.cursorTheme,
      // CursorTheme doesn't support lerp
      backgroundColor:
          Color.lerp(backgroundColor, other.backgroundColor, t) ??
          backgroundColor,
      debugMode: t < 0.5 ? debugMode : other.debugMode,
    );
  }

  /// Built-in light theme with bright colors and subtle grid.
  ///
  /// Suitable for applications with light backgrounds. Features:
  /// - White background
  /// - Light grey dot grid
  /// - Cyan selection and highlights
  /// - Black text and borders
  static final light = NodeFlowTheme(
    nodeTheme: NodeTheme.light,
    connectionTheme: ConnectionTheme.light,
    temporaryConnectionTheme: ConnectionTheme.light.copyWith(
      color: Color(0xFF666666),
      startPoint: ConnectionEndPoint.none,
      endPoint: ConnectionEndPoint.capsuleHalf,
      dashPattern: [5, 5],
    ),
    portTheme: PortTheme.light,
    labelTheme: LabelTheme.light,
    annotationTheme: AnnotationTheme.light,
    gridTheme: GridTheme.light,
    selectionTheme: SelectionTheme.light,
    cursorTheme: CursorTheme.light,
    backgroundColor: Colors.white,
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
    temporaryConnectionTheme: ConnectionTheme.dark.copyWith(
      color: Color(0xFF999999),
      startPoint: ConnectionEndPoint.none,
      endPoint: ConnectionEndPoint.capsuleHalf,
      dashPattern: [5, 5],
    ),
    portTheme: PortTheme.dark,
    labelTheme: LabelTheme.dark,
    annotationTheme: AnnotationTheme.dark,
    gridTheme: GridTheme.dark,
    selectionTheme: SelectionTheme.dark,
    cursorTheme: CursorTheme.dark,
    backgroundColor: const Color(0xFF1A1A1A),
  );
}
