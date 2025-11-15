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
    ShapeDirection? orientation,
    bool isOutputPort = false,
  }) {
    final path = Path();
    final halfSize = size / 2;

    // Default to right if no orientation provided
    final effectiveOrientation = orientation ?? ShapeDirection.right;

    // Orient triangle based on port type:
    // - Input ports (isOutputPort = false): point faces inward, flat side outside
    // - Output ports (isOutputPort = true): point faces outward, flat side inside
    switch (effectiveOrientation) {
      case ShapeDirection.left:
        if (isOutputPort) {
          // Point on left (outside), flat side on right (inside)
          path.moveTo(center.dx - halfSize, center.dy);
          path.lineTo(center.dx + halfSize, center.dy - halfSize);
          path.lineTo(center.dx + halfSize, center.dy + halfSize);
        } else {
          // Flat side on left (outside), point toward right (inside)
          path.moveTo(center.dx + halfSize, center.dy);
          path.lineTo(center.dx - halfSize, center.dy - halfSize);
          path.lineTo(center.dx - halfSize, center.dy + halfSize);
        }
        break;
      case ShapeDirection.right:
        if (isOutputPort) {
          // Point on right (outside), flat side on left (inside)
          path.moveTo(center.dx + halfSize, center.dy);
          path.lineTo(center.dx - halfSize, center.dy - halfSize);
          path.lineTo(center.dx - halfSize, center.dy + halfSize);
        } else {
          // Flat side on right (outside), point toward left (inside)
          path.moveTo(center.dx - halfSize, center.dy);
          path.lineTo(center.dx + halfSize, center.dy - halfSize);
          path.lineTo(center.dx + halfSize, center.dy + halfSize);
        }
        break;
      case ShapeDirection.top:
        if (isOutputPort) {
          // Point on top (outside), flat side on bottom (inside)
          path.moveTo(center.dx, center.dy - halfSize);
          path.lineTo(center.dx - halfSize, center.dy + halfSize);
          path.lineTo(center.dx + halfSize, center.dy + halfSize);
        } else {
          // Flat side on top (outside), point toward bottom (inside)
          path.moveTo(center.dx, center.dy + halfSize);
          path.lineTo(center.dx - halfSize, center.dy - halfSize);
          path.lineTo(center.dx + halfSize, center.dy - halfSize);
        }
        break;
      case ShapeDirection.bottom:
        if (isOutputPort) {
          // Point on bottom (outside), flat side on top (inside)
          path.moveTo(center.dx, center.dy + halfSize);
          path.lineTo(center.dx - halfSize, center.dy - halfSize);
          path.lineTo(center.dx + halfSize, center.dy - halfSize);
        } else {
          // Flat side on bottom (outside), point toward top (inside)
          path.moveTo(center.dx, center.dy - halfSize);
          path.lineTo(center.dx - halfSize, center.dy + halfSize);
          path.lineTo(center.dx + halfSize, center.dy + halfSize);
        }
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
