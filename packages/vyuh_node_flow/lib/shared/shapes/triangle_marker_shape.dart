import 'package:flutter/material.dart';

import 'marker_shape.dart';

/// Triangle marker shape with orientation.
///
/// The triangle orientation depends on both the [orientation] parameter
/// and the [isPointingOutward] parameter:
/// - When [isPointingOutward] is false: flat side faces outward, tip points inward
/// - When [isPointingOutward] is true: tip points outward, flat side faces inward
class TriangleMarkerShape extends MarkerShape {
  const TriangleMarkerShape();

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
    bool isPointingOutward = false,
  }) {
    final path = Path();
    final halfSize = size / 2;

    // Default to right if no orientation provided
    final effectiveOrientation = orientation ?? ShapeDirection.right;

    // Orient triangle based on context:
    // - isPointingOutward = false: flat side outside, tip points inward (input ports)
    // - isPointingOutward = true: tip points outward, flat side inside (output ports, endpoints)
    switch (effectiveOrientation) {
      case ShapeDirection.left:
        if (isPointingOutward) {
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
        if (isPointingOutward) {
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
        if (isPointingOutward) {
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
        if (isPointingOutward) {
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
      identical(this, other) || other is TriangleMarkerShape;

  @override
  int get hashCode => typeName.hashCode;
}
