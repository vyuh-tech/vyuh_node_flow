import 'package:flutter/material.dart';
import 'package:vyuh_node_flow/vyuh_node_flow.dart';

/// A rounded rectangle marker shape for ports.
///
/// This creates a rectangle with rounded corners on all sides,
/// perfect for vertical bar ports with a subtle rounded appearance.
class RoundedRectangleMarkerShape extends MarkerShape {
  /// The border radius for the rounded corners.
  final double borderRadius;

  /// Creates a rounded rectangle marker shape.
  const RoundedRectangleMarkerShape({this.borderRadius = 4.0});

  @override
  String get typeName => 'roundedRectangle';

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

    // Create rounded rectangle
    final rrect = RRect.fromRectAndRadius(rect, Radius.circular(borderRadius));

    // Draw fill
    canvas.drawRRect(rrect, fillPaint);

    // Draw border if provided
    if (borderPaint != null && borderPaint.strokeWidth > 0) {
      canvas.drawRRect(rrect, borderPaint);
    }
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is RoundedRectangleMarkerShape &&
          other.borderRadius == borderRadius);

  @override
  int get hashCode => typeName.hashCode ^ borderRadius.hashCode;
}
