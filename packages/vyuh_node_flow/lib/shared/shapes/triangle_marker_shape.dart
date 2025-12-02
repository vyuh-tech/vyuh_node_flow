import 'package:flutter/material.dart';

import 'marker_shape.dart';

/// Triangle marker shape with orientation.
///
/// The triangle orientation depends on both the [orientation] parameter
/// and the [isPointingOutward] parameter:
/// - When [isPointingOutward] is false: flat side faces outward (at node edge), tip points inward
/// - When [isPointingOutward] is true: tip points outward, flat side faces inward
///
/// The triangle is edge-aligned based on orientation:
/// - Left ports: triangle's left edge at widget's left edge (node boundary)
/// - Right ports: triangle's right edge at widget's right edge (node boundary)
/// - Top ports: triangle's top edge at widget's top edge (node boundary)
/// - Bottom ports: triangle's bottom edge at widget's bottom edge (node boundary)
class TriangleMarkerShape extends MarkerShape {
  const TriangleMarkerShape();

  @override
  String get typeName => 'triangle';

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
    final path = Path();
    final halfWidth = size.width / 2;
    final halfHeight = size.height / 2;

    // Default to right if no orientation provided
    final effectiveOrientation = orientation ?? ShapeDirection.right;

    // Orient triangle based on context:
    // - isPointingOutward = false: flat side faces outward, tip points inward (input ports)
    // - isPointingOutward = true: tip points outward, flat side faces inward (output ports, endpoints)
    //
    // The triangle is always centered on the passed center point. For both ports and
    // connection endpoints, external positioning code accounts for the centered nature.
    switch (effectiveOrientation) {
      case ShapeDirection.left:
        if (isPointingOutward) {
          // Point on left (outside), flat side on right (inside)
          path.moveTo(center.dx - halfWidth, center.dy);
          path.lineTo(center.dx + halfWidth, center.dy - halfHeight);
          path.lineTo(center.dx + halfWidth, center.dy + halfHeight);
        } else {
          // Flat side on left (outside), point toward right (inside)
          path.moveTo(center.dx + halfWidth, center.dy);
          path.lineTo(center.dx - halfWidth, center.dy - halfHeight);
          path.lineTo(center.dx - halfWidth, center.dy + halfHeight);
        }
        break;
      case ShapeDirection.right:
        if (isPointingOutward) {
          // Point on right (outside), flat side on left (inside)
          path.moveTo(center.dx + halfWidth, center.dy);
          path.lineTo(center.dx - halfWidth, center.dy - halfHeight);
          path.lineTo(center.dx - halfWidth, center.dy + halfHeight);
        } else {
          // Flat side on right (outside), point toward left (inside)
          path.moveTo(center.dx - halfWidth, center.dy);
          path.lineTo(center.dx + halfWidth, center.dy - halfHeight);
          path.lineTo(center.dx + halfWidth, center.dy + halfHeight);
        }
        break;
      case ShapeDirection.top:
        if (isPointingOutward) {
          // Point on top (outside), flat side on bottom (inside)
          path.moveTo(center.dx, center.dy - halfHeight);
          path.lineTo(center.dx - halfWidth, center.dy + halfHeight);
          path.lineTo(center.dx + halfWidth, center.dy + halfHeight);
        } else {
          // Flat side on top (outside), point toward bottom (inside)
          path.moveTo(center.dx, center.dy + halfHeight);
          path.lineTo(center.dx - halfWidth, center.dy - halfHeight);
          path.lineTo(center.dx + halfWidth, center.dy - halfHeight);
        }
        break;
      case ShapeDirection.bottom:
        if (isPointingOutward) {
          // Point on bottom (outside), flat side on top (inside)
          path.moveTo(center.dx, center.dy + halfHeight);
          path.lineTo(center.dx - halfWidth, center.dy - halfHeight);
          path.lineTo(center.dx + halfWidth, center.dy - halfHeight);
        } else {
          // Flat side on bottom (outside), point toward top (inside)
          path.moveTo(center.dx, center.dy - halfHeight);
          path.lineTo(center.dx - halfWidth, center.dy + halfHeight);
          path.lineTo(center.dx + halfWidth, center.dy + halfHeight);
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
