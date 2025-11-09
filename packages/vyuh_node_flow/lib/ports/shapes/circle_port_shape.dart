import 'package:flutter/material.dart';

import 'port_shape.dart';

/// Circular port shape
class CirclePortShape extends PortShape {
  const CirclePortShape();

  @override
  String get typeName => 'circle';

  @override
  void paint(
    Canvas canvas,
    Offset center,
    double size,
    Paint fillPaint,
    Paint? borderPaint, {
    ShapeOrientation? orientation,
  }) {
    final radius = size / 2;
    canvas.drawCircle(center, radius, fillPaint);
    if (borderPaint != null && borderPaint.strokeWidth > 0) {
      canvas.drawCircle(
        center,
        radius - borderPaint.strokeWidth / 2,
        borderPaint,
      );
    }
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is CirclePortShape;

  @override
  int get hashCode => typeName.hashCode;
}
