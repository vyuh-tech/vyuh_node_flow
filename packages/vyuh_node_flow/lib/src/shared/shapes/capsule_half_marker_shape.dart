import 'package:flutter/material.dart';

import '../../ports/capsule_half.dart';
import 'marker_shape.dart';

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

/// Half-capsule marker shape with orientation.
///
/// Renders a half-capsule (semicircular) shape. The flat side is determined
/// by the [orientation] parameter.
class CapsuleHalfMarkerShape extends MarkerShape {
  const CapsuleHalfMarkerShape();

  @override
  String get typeName => 'capsuleHalf';

  @override
  void paint(
    Canvas canvas,
    Offset center,
    Size size,
    Paint fillPaint,
    Paint? borderPaint, {
    ShapeDirection? orientation,
    bool isPointingOutward = false,
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
      identical(this, other) || other is CapsuleHalfMarkerShape;

  @override
  int get hashCode => typeName.hashCode;
}
