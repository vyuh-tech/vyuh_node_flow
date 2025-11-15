import 'package:flutter/material.dart';

import '../capsule_half.dart';
import 'port_shape.dart';

/// Extension to convert ShapeDirection to CapsuleFlatSide
extension ShapeDirectionExtension on ShapeDirection {
  CapsuleFlatSide toCapsuleFlatSide() {
    switch (this) {
      case ShapeDirection.left:
        return CapsuleFlatSide.left;
      case ShapeDirection.right:
        return CapsuleFlatSide.right;
      case ShapeDirection.top:
        return CapsuleFlatSide.top;
      case ShapeDirection.bottom:
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
    ShapeDirection? orientation,
    bool isOutputPort = false,
  }) {
    // Default to right if no orientation provided
    final effectiveOrientation = orientation ?? ShapeDirection.right;
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
