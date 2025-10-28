import 'package:flutter/material.dart';

class LabelTheme {
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

  final Color? color;
  final double? fontSize;
  final FontWeight? fontWeight;
  final String? fontFamily;

  final Color? backgroundColor;
  final EdgeInsets padding;
  final double borderRadius;

  final Color? borderColor;
  final double borderWidth;
  final double horizontalOffset;
  final double verticalOffset;

  TextStyle get textStyle => TextStyle(
    color: color,
    fontSize: fontSize,
    fontWeight: fontWeight,
    fontFamily: fontFamily,
  );
}
