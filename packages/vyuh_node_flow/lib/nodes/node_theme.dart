import 'package:flutter/material.dart';

class NodeTheme {
  const NodeTheme({
    required this.backgroundColor,
    required this.selectedBackgroundColor,
    required this.hoverBackgroundColor,
    required this.draggingBackgroundColor,
    required this.borderColor,
    required this.selectedBorderColor,
    required this.hoverBorderColor,
    required this.draggingBorderColor,
    required this.borderWidth,
    required this.selectedBorderWidth,
    required this.hoverBorderWidth,
    required this.draggingBorderWidth,
    required this.borderRadius,
    required this.padding,
    required this.titleStyle,
    required this.contentStyle,
    required this.animationDuration,
    required this.minWidth,
    required this.minHeight,
  });

  final Color backgroundColor;
  final Color selectedBackgroundColor;
  final Color hoverBackgroundColor;
  final Color draggingBackgroundColor;
  final Color borderColor;
  final Color selectedBorderColor;
  final Color hoverBorderColor;
  final Color draggingBorderColor;
  final double borderWidth;
  final double selectedBorderWidth;
  final double hoverBorderWidth;
  final double draggingBorderWidth;
  final BorderRadius borderRadius;
  final EdgeInsets padding;
  final TextStyle titleStyle;
  final TextStyle contentStyle;
  final Duration animationDuration;
  final double minWidth;
  final double minHeight;

  NodeTheme copyWith({
    Color? backgroundColor,
    Color? selectedBackgroundColor,
    Color? hoverBackgroundColor,
    Color? draggingBackgroundColor,
    Color? borderColor,
    Color? selectedBorderColor,
    Color? hoverBorderColor,
    Color? draggingBorderColor,
    double? borderWidth,
    double? selectedBorderWidth,
    double? hoverBorderWidth,
    double? draggingBorderWidth,
    BorderRadius? borderRadius,
    EdgeInsets? padding,
    TextStyle? titleStyle,
    TextStyle? contentStyle,
    Duration? animationDuration,
    double? minWidth,
    double? minHeight,
  }) {
    return NodeTheme(
      backgroundColor: backgroundColor ?? this.backgroundColor,
      selectedBackgroundColor:
          selectedBackgroundColor ?? this.selectedBackgroundColor,
      hoverBackgroundColor: hoverBackgroundColor ?? this.hoverBackgroundColor,
      draggingBackgroundColor:
          draggingBackgroundColor ?? this.draggingBackgroundColor,
      borderColor: borderColor ?? this.borderColor,
      selectedBorderColor: selectedBorderColor ?? this.selectedBorderColor,
      hoverBorderColor: hoverBorderColor ?? this.hoverBorderColor,
      draggingBorderColor: draggingBorderColor ?? this.draggingBorderColor,
      borderWidth: borderWidth ?? this.borderWidth,
      selectedBorderWidth: selectedBorderWidth ?? this.selectedBorderWidth,
      hoverBorderWidth: hoverBorderWidth ?? this.hoverBorderWidth,
      draggingBorderWidth: draggingBorderWidth ?? this.draggingBorderWidth,
      borderRadius: borderRadius ?? this.borderRadius,
      padding: padding ?? this.padding,
      titleStyle: titleStyle ?? this.titleStyle,
      contentStyle: contentStyle ?? this.contentStyle,
      animationDuration: animationDuration ?? this.animationDuration,
      minWidth: minWidth ?? this.minWidth,
      minHeight: minHeight ?? this.minHeight,
    );
  }

  static const light = NodeTheme(
    backgroundColor: Colors.white,
    selectedBackgroundColor: Color(0xFFF5F5F5),
    hoverBackgroundColor: Color(0xFFFAFAFA),
    draggingBackgroundColor: Color(0xFFF0F0F0),
    borderColor: Color(0xFFE0E0E0),
    selectedBorderColor: Color(0xFF2196F3),
    hoverBorderColor: Color(0xFFCCCCCC),
    draggingBorderColor: Color(0xFF2196F3),
    borderWidth: 2.0,
    selectedBorderWidth: 2.0,
    hoverBorderWidth: 2.0,
    draggingBorderWidth: 2.0,
    borderRadius: BorderRadius.all(Radius.circular(8.0)),
    padding: EdgeInsets.all(4.0),
    titleStyle: TextStyle(
      fontSize: 14.0,
      fontWeight: FontWeight.bold,
      color: Color(0xFF333333),
    ),
    contentStyle: TextStyle(fontSize: 12.0, color: Color(0xFF666666)),
    animationDuration: Duration(milliseconds: 200),
    minWidth: 150.0,
    minHeight: 100.0,
  );

  static const dark = NodeTheme(
    backgroundColor: Color(0xFF2D2D2D),
    selectedBackgroundColor: Color(0xFF3D3D3D),
    hoverBackgroundColor: Color(0xFF353535),
    draggingBackgroundColor: Color(0xFF404040),
    borderColor: Color(0xFF555555),
    selectedBorderColor: Color(0xFF64B5F6),
    hoverBorderColor: Color(0xFF666666),
    draggingBorderColor: Color(0xFF64B5F6),
    borderWidth: 2.0,
    selectedBorderWidth: 2.0,
    hoverBorderWidth: 2.0,
    draggingBorderWidth: 2.0,
    borderRadius: BorderRadius.all(Radius.circular(8.0)),
    padding: EdgeInsets.all(12.0),
    titleStyle: TextStyle(
      fontSize: 14.0,
      fontWeight: FontWeight.bold,
      color: Color(0xFFE0E0E0),
    ),
    contentStyle: TextStyle(fontSize: 12.0, color: Color(0xFFB0B0B0)),
    animationDuration: Duration(milliseconds: 200),
    minWidth: 150.0,
    minHeight: 100.0,
  );
}
