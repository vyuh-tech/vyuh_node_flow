import 'package:flutter/material.dart';

import 'marker_shape.dart';

/// Rectangle marker shape that uses the provided Size directly.
///
/// The shape is edge-aligned with the port connection point:
/// - Left ports: rectangle's left edge at the center point
/// - Right ports: rectangle's right edge at the center point
/// - Top ports: rectangle's top edge at the center point
/// - Bottom ports: rectangle's bottom edge at the center point
///
/// For square markers, simply use a port with equal width and height (e.g., `Size(10, 10)`).
class RectangleMarkerShape extends MarkerShape {
  /// Creates a rectangle marker shape.
  const RectangleMarkerShape();

  @override
  String get typeName => 'rectangle';

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
    final rect = Rect.fromCenter(
      center: center,
      width: size.width,
      height: size.height,
    );
    canvas.drawRect(rect, fillPaint);
    if (borderPaint != null && borderPaint.strokeWidth > 0) {
      canvas.drawRect(rect, borderPaint);
    }
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is RectangleMarkerShape;

  @override
  int get hashCode => typeName.hashCode;
}
