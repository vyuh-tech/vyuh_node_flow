import 'package:flutter/material.dart';

import 'marker_shape.dart';

/// Circular marker shape.
///
/// A symmetric shape that looks the same regardless of orientation.
class CircleMarkerShape extends MarkerShape {
  const CircleMarkerShape();

  @override
  String get typeName => 'circle';

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
      identical(this, other) || other is CircleMarkerShape;

  @override
  int get hashCode => typeName.hashCode;
}
