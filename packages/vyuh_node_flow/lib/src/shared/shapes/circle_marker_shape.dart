import 'package:flutter/material.dart';

import 'marker_shape.dart';

/// Circular marker shape.
///
/// The circle uses the shortest side of the provided Size as diameter.
/// When the size is asymmetric, the circle is edge-aligned based on orientation:
/// - Left ports: circle's left edge at the widget's left edge (node boundary)
/// - Right ports: circle's right edge at the widget's right edge (node boundary)
/// - Top ports: circle's top edge at the widget's top edge (node boundary)
/// - Bottom ports: circle's bottom edge at the widget's bottom edge (node boundary)
///
/// For symmetric sizes (e.g., Size(10, 10)), the circle is centered since
/// it fills the entire widget bounds.
class CircleMarkerShape extends MarkerShape {
  const CircleMarkerShape();

  @override
  String get typeName => 'circle';

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
    // Circle uses the shortest side to maintain circular shape
    final diameter = size.shortestSide;
    final radius = diameter / 2;

    // Calculate adjusted center so the circle is edge-aligned when size is asymmetric.
    // For example, with Size(20, 10) for a right port:
    // - Circle diameter = 10, radius = 5
    // - Widget center is at (10, 5)
    // - We want circle's right edge at widget's right edge
    // - So circle center should be at (15, 5), shift right by (width/2 - radius)
    final effectiveOrientation = orientation ?? ShapeDirection.right;
    final halfWidth = size.width / 2;
    final halfHeight = size.height / 2;

    final Offset adjustedCenter = switch (effectiveOrientation) {
      // Left port: circle's left edge at widget's left edge
      ShapeDirection.left => Offset(center.dx - halfWidth + radius, center.dy),
      // Right port: circle's right edge at widget's right edge
      ShapeDirection.right => Offset(center.dx + halfWidth - radius, center.dy),
      // Top port: circle's top edge at widget's top edge
      ShapeDirection.top => Offset(center.dx, center.dy - halfHeight + radius),
      // Bottom port: circle's bottom edge at widget's bottom edge
      ShapeDirection.bottom => Offset(
        center.dx,
        center.dy + halfHeight - radius,
      ),
    };

    canvas.drawCircle(adjustedCenter, radius, fillPaint);
    if (borderPaint != null && borderPaint.strokeWidth > 0) {
      canvas.drawCircle(
        adjustedCenter,
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
