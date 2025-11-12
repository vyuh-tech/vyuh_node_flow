import 'package:flutter/material.dart';

import 'port_shape.dart';

/// Square port shape
class SquarePortShape extends PortShape {
  const SquarePortShape();

  @override
  String get typeName => 'square';

  @override
  void paint(
    Canvas canvas,
    Offset center,
    double size,
    Paint fillPaint,
    Paint? borderPaint, {
    ShapeDirection? orientation,
  }) {
    final rect = Rect.fromCenter(center: center, width: size, height: size);
    canvas.drawRect(rect, fillPaint);
    if (borderPaint != null && borderPaint.strokeWidth > 0) {
      canvas.drawRect(rect, borderPaint);
    }
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is SquarePortShape;

  @override
  int get hashCode => typeName.hashCode;
}
