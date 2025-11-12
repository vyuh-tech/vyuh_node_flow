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

    // Orient triangle with flat side outside (away from node)
    // Point faces toward the node (inside)
    switch (effectiveOrientation) {
      case ShapeOrientation.left:
        // Flat side on left (outside), point toward right (inside)
        path.moveTo(center.dx + halfSize, center.dy);
        path.lineTo(center.dx - halfSize, center.dy - halfSize);
        path.lineTo(center.dx - halfSize, center.dy + halfSize);
        break;
      case ShapeOrientation.right:
        // Flat side on right (outside), point toward left (inside)
        path.moveTo(center.dx - halfSize, center.dy);
        path.lineTo(center.dx + halfSize, center.dy - halfSize);
        path.lineTo(center.dx + halfSize, center.dy + halfSize);
        break;
      case ShapeOrientation.top:
        // Flat side on top (outside), point toward bottom (inside)
        path.moveTo(center.dx, center.dy + halfSize);
        path.lineTo(center.dx - halfSize, center.dy - halfSize);
        path.lineTo(center.dx + halfSize, center.dy - halfSize);
        break;
      case ShapeOrientation.bottom:
        // Flat side on bottom (outside), point toward top (inside)
        path.moveTo(center.dx, center.dy - halfSize);
        path.lineTo(center.dx - halfSize, center.dy + halfSize);
        path.lineTo(center.dx + halfSize, center.dy + halfSize);
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
