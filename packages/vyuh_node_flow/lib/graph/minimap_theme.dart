import 'package:flutter/material.dart';

/// Position options for minimap placement
enum MinimapPosition { topLeft, topRight, bottomLeft, bottomRight }

/// Theme configuration for the minimap overlay.
///
/// Defines the visual appearance of the minimap including colors, dimensions,
/// positioning, and styling options.
///
/// Two built-in themes are provided:
/// - [MinimapTheme.light]: Light color scheme with subtle styling
/// - [MinimapTheme.dark]: Dark color scheme with visible contrast
class MinimapTheme {
  const MinimapTheme({
    this.position = MinimapPosition.bottomRight,
    this.margin = 20.0,
    this.size = const Size(200, 150),
    this.backgroundColor = const Color(0xFFF5F5F5),
    this.nodeColor = const Color(0xFF1976D2),
    this.viewportColor = const Color(0xFF1976D2),
    this.viewportFillOpacity = 0.1,
    this.viewportBorderOpacity = 0.4,
    this.borderColor = const Color(0xFFBDBDBD),
    this.borderWidth = 1.0,
    this.borderRadius = 4.0,
    this.padding = const EdgeInsets.all(4.0),
    this.showViewport = true,
    this.nodeBorderRadius = 2.0,
  });

  /// Position of the minimap in the editor.
  ///
  /// Determines which corner the minimap is placed in.
  final MinimapPosition position;

  /// Margin from the edge of the editor to the minimap.
  ///
  /// Applied to both axes based on [position].
  final double margin;

  /// Size of the minimap widget in pixels.
  ///
  /// Defaults to 200x150. Larger sizes provide more detail but take more
  /// screen space.
  final Size size;

  /// Background color of the minimap container.
  final Color backgroundColor;

  /// Color used to draw nodes in the minimap.
  ///
  /// Nodes are drawn as small filled rectangles.
  final Color nodeColor;

  /// Color used for the viewport indicator.
  ///
  /// The viewport is drawn as a semi-transparent rectangle with a border.
  final Color viewportColor;

  /// Opacity of the viewport fill.
  ///
  /// Applied to [viewportColor] for the fill. Defaults to 0.1.
  final double viewportFillOpacity;

  /// Opacity of the viewport border.
  ///
  /// Applied to [viewportColor] for the border. Defaults to 0.4.
  final double viewportBorderOpacity;

  /// Border color of the minimap container.
  final Color borderColor;

  /// Border width of the minimap container.
  final double borderWidth;

  /// Border radius for the minimap widget corners.
  ///
  /// Applied to both the minimap container and viewport indicator.
  final double borderRadius;

  /// Internal padding between minimap edge and content.
  final EdgeInsets padding;

  /// Whether to show the viewport indicator rectangle.
  ///
  /// When true, displays a highlighted region showing the currently visible
  /// portion of the graph.
  final bool showViewport;

  /// Border radius for node rectangles in the minimap.
  final double nodeBorderRadius;

  /// Create a copy with different values.
  MinimapTheme copyWith({
    MinimapPosition? position,
    double? margin,
    Size? size,
    Color? backgroundColor,
    Color? nodeColor,
    Color? viewportColor,
    double? viewportFillOpacity,
    double? viewportBorderOpacity,
    Color? borderColor,
    double? borderWidth,
    double? borderRadius,
    EdgeInsets? padding,
    bool? showViewport,
    double? nodeBorderRadius,
  }) {
    return MinimapTheme(
      position: position ?? this.position,
      margin: margin ?? this.margin,
      size: size ?? this.size,
      backgroundColor: backgroundColor ?? this.backgroundColor,
      nodeColor: nodeColor ?? this.nodeColor,
      viewportColor: viewportColor ?? this.viewportColor,
      viewportFillOpacity: viewportFillOpacity ?? this.viewportFillOpacity,
      viewportBorderOpacity:
          viewportBorderOpacity ?? this.viewportBorderOpacity,
      borderColor: borderColor ?? this.borderColor,
      borderWidth: borderWidth ?? this.borderWidth,
      borderRadius: borderRadius ?? this.borderRadius,
      padding: padding ?? this.padding,
      showViewport: showViewport ?? this.showViewport,
      nodeBorderRadius: nodeBorderRadius ?? this.nodeBorderRadius,
    );
  }

  /// Light theme with subtle styling.
  static const light = MinimapTheme(
    backgroundColor: Color(0xFFF5F5F5),
    nodeColor: Color(0xFF1976D2),
    viewportColor: Color(0xFF1976D2),
    borderColor: Color(0xFFBDBDBD),
  );

  /// Dark theme with visible contrast.
  static const dark = MinimapTheme(
    backgroundColor: Color(0xFF2D2D2D),
    nodeColor: Color(0xFF64B5F6),
    viewportColor: Color(0xFF64B5F6),
    borderColor: Color(0xFF424242),
  );
}
