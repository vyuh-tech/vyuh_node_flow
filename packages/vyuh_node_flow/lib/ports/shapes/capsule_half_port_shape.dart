import 'package:flutter/material.dart';

import '../capsule_half.dart';
import 'port_shape.dart';

/// Extension to convert ShapeOrientation to CapsuleFlatSide
extension ShapeOrientationExtension on ShapeOrientation {
  CapsuleFlatSide toCapsuleFlatSide() {
    switch (this) {
      case ShapeOrientation.left:
        return CapsuleFlatSide.left;
      case ShapeOrientation.right:
        return CapsuleFlatSide.right;
      case ShapeOrientation.top:
        return CapsuleFlatSide.top;
      case ShapeOrientation.bottom:
        return CapsuleFlatSide.bottom;
    }
  }
}

/// Half-capsule port shape with orientation
class CapsuleHalfPortShape extends PortShape {
  const CapsuleHalfPortShape();

  @override
  String get typeName => 'capsuleHalf';

  @override
  void paint(
    Canvas canvas,
    Offset center,
    double size,
    Paint fillPaint,
    Paint? borderPaint, {
    ShapeOrientation? orientation,
  }) {
    // Default to right if no orientation provided
    final effectiveOrientation = orientation ?? ShapeOrientation.right;
    final flatSide = effectiveOrientation.toCapsuleFlatSide();
    CapsuleHalfPainter.paint(
      canvas,
      center,
      size,
      flatSide,
      fillPaint,
      borderPaint,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is CapsuleHalfPortShape;

  @override
  int get hashCode => typeName.hashCode;
}
