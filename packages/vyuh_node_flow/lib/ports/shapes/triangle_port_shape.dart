import 'package:flutter/material.dart';

import 'port_shape.dart';

/// Triangle port shape with orientation
class TrianglePortShape extends PortShape {
  const TrianglePortShape();

  @override
  String get typeName => 'triangle';

  @override
  void paint(
    Canvas canvas,
    Offset center,
    double size,
    Paint fillPaint,
    Paint? borderPaint, {
    ShapeOrientation? orientation,
  }) {
    final path = Path();
    final halfSize = size / 2;

    // Default to right if no orientation provided
    final effectiveOrientation = orientation ?? ShapeOrientation.right;

    // Point the triangle based on orientation
    switch (effectiveOrientation) {
      case ShapeOrientation.left:
        // Triangle pointing left
        path.moveTo(center.dx - halfSize, center.dy);
        path.lineTo(center.dx + halfSize, center.dy - halfSize);
        path.lineTo(center.dx + halfSize, center.dy + halfSize);
        break;
      case ShapeOrientation.right:
        // Triangle pointing right
        path.moveTo(center.dx + halfSize, center.dy);
        path.lineTo(center.dx - halfSize, center.dy - halfSize);
        path.lineTo(center.dx - halfSize, center.dy + halfSize);
        break;
      case ShapeOrientation.top:
        // Triangle pointing up
        path.moveTo(center.dx, center.dy - halfSize);
        path.lineTo(center.dx - halfSize, center.dy + halfSize);
        path.lineTo(center.dx + halfSize, center.dy + halfSize);
        break;
      case ShapeOrientation.bottom:
        // Triangle pointing down
        path.moveTo(center.dx, center.dy + halfSize);
        path.lineTo(center.dx - halfSize, center.dy - halfSize);
        path.lineTo(center.dx + halfSize, center.dy - halfSize);
        break;
    }
    path.close();

    canvas.drawPath(path, fillPaint);
    if (borderPaint != null && borderPaint.strokeWidth > 0) {
      canvas.drawPath(path, borderPaint);
    }
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is TrianglePortShape;

  @override
  int get hashCode => typeName.hashCode;
}
