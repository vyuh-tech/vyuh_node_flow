import 'dart:ui' show lerpDouble;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../connections/connection_endpoint.dart';
import '../connections/connection_style_base.dart';
import '../connections/connection_styles.dart';
import '../connections/connection_theme.dart';
import '../connections/label_theme.dart';
import '../nodes/node_theme.dart';
import '../ports/port_theme.dart';

/// Defines different grid visual styles
enum GridStyle {
  /// Traditional line-based grid
  lines,

  /// Dot-based grid (points at intersections)
  dots,

  /// Hierarchical grid with major and minor lines
  hierarchical,

  /// No grid visible
  none,
}

class NodeFlowTheme extends ThemeExtension<NodeFlowTheme> {
  const NodeFlowTheme({
    required this.nodeTheme,
    this.connectionStyle = ConnectionStyles.smoothstep,
    this.temporaryConnectionStyle = ConnectionStyles.smoothstep,
    required this.connectionTheme,
    required this.temporaryConnectionTheme,
    required this.portTheme,
    required this.labelTheme,
    this.backgroundColor = Colors.white,
    this.gridColor = const Color(0xFF919191),
    this.gridSize = 20.0,
    this.gridThickness = 0.5,
    this.gridStyle = GridStyle.dots,
    this.selectionColor = const Color(0x3300BCD4),
    this.selectionBorderColor = const Color(0xFF00BCD4),
    this.selectionBorderWidth = 1.0,
    this.hoverEffectDuration = const Duration(milliseconds: 200),
    this.enableAnimations = true,
    this.cursorStyle = SystemMouseCursors.basic,
    this.dragCursorStyle = SystemMouseCursors.grabbing,
    this.resizeCursorStyle = SystemMouseCursors.resizeUpDown,
    this.nodeCursorStyle = SystemMouseCursors.click,
    this.portCursorStyle = SystemMouseCursors.precise,
    this.debugMode = false,
  });

  final NodeTheme nodeTheme;
  final ConnectionStyle connectionStyle;
  final ConnectionStyle temporaryConnectionStyle;
  final ConnectionTheme connectionTheme;
  final ConnectionTheme temporaryConnectionTheme;
  final PortTheme portTheme;
  final LabelTheme labelTheme;
  final Color backgroundColor;
  final Color gridColor;
  final double gridSize;
  final double gridThickness;
  final GridStyle gridStyle;
  final Color selectionColor;
  final Color selectionBorderColor;
  final double selectionBorderWidth;
  final Duration hoverEffectDuration;
  final bool enableAnimations;
  final SystemMouseCursor cursorStyle;
  final SystemMouseCursor dragCursorStyle;
  final SystemMouseCursor resizeCursorStyle;
  final SystemMouseCursor nodeCursorStyle;
  final SystemMouseCursor portCursorStyle;
  final bool debugMode;

  @override
  NodeFlowTheme copyWith({
    NodeTheme? nodeTheme,
    ConnectionStyle? connectionStyle,
    ConnectionStyle? temporaryConnectionStyle,
    ConnectionTheme? connectionTheme,
    ConnectionTheme? temporaryConnectionTheme,
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
    Duration? hoverEffectDuration,
    bool? enableAnimations,
    SystemMouseCursor? cursorStyle,
    SystemMouseCursor? dragCursorStyle,
    SystemMouseCursor? resizeCursorStyle,
    SystemMouseCursor? nodeCursorStyle,
    SystemMouseCursor? portCursorStyle,
    bool? debugMode,
  }) {
    return NodeFlowTheme(
      nodeTheme: nodeTheme ?? this.nodeTheme,
      connectionStyle: connectionStyle ?? this.connectionStyle,
      temporaryConnectionStyle:
          temporaryConnectionStyle ?? this.temporaryConnectionStyle,
      connectionTheme: connectionTheme ?? this.connectionTheme,
      temporaryConnectionTheme:
          temporaryConnectionTheme ?? this.temporaryConnectionTheme,
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
      hoverEffectDuration: hoverEffectDuration ?? this.hoverEffectDuration,
      enableAnimations: enableAnimations ?? this.enableAnimations,
      cursorStyle: cursorStyle ?? this.cursorStyle,
      dragCursorStyle: dragCursorStyle ?? this.dragCursorStyle,
      resizeCursorStyle: resizeCursorStyle ?? this.resizeCursorStyle,
      nodeCursorStyle: nodeCursorStyle ?? this.nodeCursorStyle,
      portCursorStyle: portCursorStyle ?? this.portCursorStyle,
      debugMode: debugMode ?? this.debugMode,
    );
  }

  @override
  NodeFlowTheme lerp(NodeFlowTheme? other, double t) {
    if (other is! NodeFlowTheme) return this;

    return NodeFlowTheme(
      nodeTheme: nodeTheme, // NodeTheme doesn't support lerp
      connectionStyle: t < 0.5 ? connectionStyle : other.connectionStyle,
      temporaryConnectionStyle: t < 0.5
          ? temporaryConnectionStyle
          : other.temporaryConnectionStyle,
      connectionTheme: connectionTheme, // ConnectionTheme doesn't support lerp
      temporaryConnectionTheme:
          temporaryConnectionTheme, // ConnectionTheme doesn't support lerp
      portTheme: portTheme, // PortTheme doesn't support lerp
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
      hoverEffectDuration: t < 0.5
          ? hoverEffectDuration
          : other.hoverEffectDuration,
      enableAnimations: t < 0.5 ? enableAnimations : other.enableAnimations,
      cursorStyle: t < 0.5 ? cursorStyle : other.cursorStyle,
      dragCursorStyle: t < 0.5 ? dragCursorStyle : other.dragCursorStyle,
      resizeCursorStyle: t < 0.5 ? resizeCursorStyle : other.resizeCursorStyle,
      nodeCursorStyle: t < 0.5 ? nodeCursorStyle : other.nodeCursorStyle,
      portCursorStyle: t < 0.5 ? portCursorStyle : other.portCursorStyle,
    );
  }

  static const light = NodeFlowTheme(
    nodeTheme: NodeTheme.light,
    connectionStyle: ConnectionStyles.smoothstep,
    temporaryConnectionStyle: ConnectionStyles.smoothstep,
    connectionTheme: ConnectionTheme.light,
    temporaryConnectionTheme: ConnectionTheme(
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
      color: Color(0xFF333333),
      fontSize: 12.0,
      fontWeight: FontWeight.w500,
      backgroundColor: Color(0xFFFBFBFB),
      borderColor: Color(0xFFDDDDDD),
      borderWidth: 1.0,
      horizontalOffset: 8.0,
      verticalOffset: 8.0,
    ),
    backgroundColor: Colors.white,
    gridColor: Color(0xFFC8C8C8),
    gridSize: 20.0,
    gridThickness: 1,
    gridStyle: GridStyle.dots,
    selectionColor: Color(0x3300BCD4),
    selectionBorderColor: Color(0xFF00BCD4),
    selectionBorderWidth: 1.0,
    hoverEffectDuration: Duration(milliseconds: 200),
    enableAnimations: true,
    cursorStyle: SystemMouseCursors.grab,
    dragCursorStyle: SystemMouseCursors.grabbing,
    resizeCursorStyle: SystemMouseCursors.resizeUpDown,
    nodeCursorStyle: SystemMouseCursors.click,
    portCursorStyle: SystemMouseCursors.precise,
  );

  static final dark = NodeFlowTheme(
    nodeTheme: NodeTheme.dark,
    connectionStyle: ConnectionStyles.smoothstep,
    temporaryConnectionStyle: ConnectionStyles.smoothstep,
    connectionTheme: ConnectionTheme.dark,
    temporaryConnectionTheme: ConnectionTheme(
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
      color: Color(0xFFE5E5E5),
      fontSize: 12.0,
      fontWeight: FontWeight.w500,
      backgroundColor: Color(0xFF404040),
      borderColor: Color(0xFF606060),
      borderWidth: 1.0,
      horizontalOffset: 8.0,
      verticalOffset: 8.0,
    ),
    backgroundColor: const Color(0xFF1A1A1A),
    gridColor: const Color(0xFF707070),
    gridSize: 20.0,
    gridThickness: 0.5,
    gridStyle: GridStyle.dots,
    selectionColor: const Color(0x3364B5F6),
    selectionBorderColor: const Color(0xFF64B5F6),
    selectionBorderWidth: 1.0,
    hoverEffectDuration: const Duration(milliseconds: 200),
    enableAnimations: true,
    cursorStyle: SystemMouseCursors.basic,
    dragCursorStyle: SystemMouseCursors.grabbing,
    resizeCursorStyle: SystemMouseCursors.resizeUpDown,
    nodeCursorStyle: SystemMouseCursors.click,
    portCursorStyle: SystemMouseCursors.precise,
  );
}
