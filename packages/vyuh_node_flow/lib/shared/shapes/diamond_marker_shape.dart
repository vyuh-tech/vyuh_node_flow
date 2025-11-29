import 'package:flutter/material.dart';

import 'marker_shape.dart';

/// Diamond marker shape.
///
/// A symmetric shape (45-degree rotated square) that looks the same
/// regardless of orientation.
class DiamondMarkerShape extends MarkerShape {
  const DiamondMarkerShape();

  @override
  String get typeName => 'diamond';

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
    path.moveTo(center.dx, center.dy - size / 2);
    path.lineTo(center.dx + size / 2, center.dy);
    path.lineTo(center.dx, center.dy + size / 2);
    path.lineTo(center.dx - size / 2, center.dy);
    path.close();

    canvas.drawPath(path, fillPaint);
    if (borderPaint != null && borderPaint.strokeWidth > 0) {
      canvas.drawPath(path, borderPaint);
    }
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is DiamondMarkerShape;

  @override
  int get hashCode => typeName.hashCode;
}
