import 'package:flutter/material.dart';

class PortTheme {
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

  final double size;
  final Color color;
  final Color connectedColor;
  final Color hoverColor;
  final Color snappingColor;
  final Color draggingColor;
  final Color borderColor;
  final double borderWidth;
  final Duration animationDuration;

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
