import 'package:flutter/material.dart';
import 'package:vyuh_node_flow/vyuh_node_flow.dart';

/// Custom port marker shape with rounded corners on all sides.
///
/// Used for the math calculator's vertical bar-style ports (10x22px).
/// Provides a softer appearance compared to the default rectangle marker.
class RoundedRectangleMarkerShape extends MarkerShape {
  final double borderRadius;

  const RoundedRectangleMarkerShape({this.borderRadius = 4.0});

  @override
  String get typeName => 'roundedRectangle';

  /// Renders the rounded rectangle with optional border.
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

    final rrect = RRect.fromRectAndRadius(rect, Radius.circular(borderRadius));

    canvas.drawRRect(rrect, fillPaint);

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
