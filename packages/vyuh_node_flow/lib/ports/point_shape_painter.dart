import 'package:flutter/material.dart';

import '../ports/capsule_half.dart';

/// Common shape types for points (ports, endpoints, etc.)
enum PointShape {
  capsuleHalf,
  circle,
  square,
  diamond,
  triangle,
  none, // No shape rendered
}

/// Orientation for directional shapes (capsuleHalf, triangle)
enum ShapeOrientation { left, right, top, bottom }

/// A common painter for rendering various point shapes
/// Used by ports, connection endpoints, and other point-based visualizations
class PointShapePainter {
  /// Paints a shape at the given position
  static void paint({
    required Canvas canvas,
    required Offset position,
    required double size,
    required PointShape shape,
    ShapeOrientation? orientation,
    required Paint fillPaint,
    Paint? borderPaint,
  }) {
    switch (shape) {
      case PointShape.none:
        // No shape rendered
        return;

      case PointShape.capsuleHalf:
        if (orientation == null) return;
        final flatSide = _orientationToFlatSide(orientation);
        CapsuleHalfPainter.paint(
          canvas,
          position,
          size,
          flatSide,
          fillPaint,
          borderPaint,
        );
        break;

      case PointShape.circle:
        _paintCircle(canvas, position, size, fillPaint, borderPaint);
        break;

      case PointShape.square:
        _paintSquare(canvas, position, size, fillPaint, borderPaint);
        break;

      case PointShape.diamond:
        _paintDiamond(canvas, position, size, fillPaint, borderPaint);
        break;

      case PointShape.triangle:
        if (orientation == null) return;
        _paintTriangle(
          canvas,
          position,
          size,
          orientation,
          fillPaint,
          borderPaint,
        );
        break;
    }
  }

  static CapsuleFlatSide _orientationToFlatSide(ShapeOrientation orientation) {
    switch (orientation) {
      case ShapeOrientation.left:
        return CapsuleFlatSide.left;
      case ShapeOrientation.right:
        return CapsuleFlatSide.right;
      case ShapeOrientation.top:
        return CapsuleFlatSide.top;
      case ShapeOrientation.bottom:
        return CapsuleFlatSide.bottom;
    }
  }

  static void _paintCircle(
    Canvas canvas,
    Offset center,
    double size,
    Paint fillPaint,
    Paint? borderPaint,
  ) {
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

  static void _paintSquare(
    Canvas canvas,
    Offset center,
    double size,
    Paint fillPaint,
    Paint? borderPaint,
  ) {
    final rect = Rect.fromCenter(center: center, width: size, height: size);
    canvas.drawRect(rect, fillPaint);
    if (borderPaint != null && borderPaint.strokeWidth > 0) {
      canvas.drawRect(rect, borderPaint);
    }
  }

  static void _paintDiamond(
    Canvas canvas,
    Offset center,
    double size,
    Paint fillPaint,
    Paint? borderPaint,
  ) {
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

  static void _paintTriangle(
    Canvas canvas,
    Offset center,
    double size,
    ShapeOrientation orientation,
    Paint fillPaint,
    Paint? borderPaint,
  ) {
    final path = Path();
    final halfSize = size / 2;

    // Point the triangle based on orientation
    switch (orientation) {
      case ShapeOrientation.left:
        // Triangle pointing left
        path.moveTo(center.dx - halfSize, center.dy);
        path.lineTo(center.dx + halfSize, center.dy - halfSize);
        path.lineTo(center.dx + halfSize, center.dy + halfSize);
        break;
      case ShapeOrientation.right:
        // Triangle pointing right
        path.moveTo(center.dx + halfSize, center.dy);
        path.lineTo(center.dx - halfSize, center.dy - halfSize);
        path.lineTo(center.dx - halfSize, center.dy + halfSize);
        break;
      case ShapeOrientation.top:
        // Triangle pointing up
        path.moveTo(center.dx, center.dy - halfSize);
        path.lineTo(center.dx - halfSize, center.dy + halfSize);
        path.lineTo(center.dx + halfSize, center.dy + halfSize);
        break;
      case ShapeOrientation.bottom:
        // Triangle pointing down
        path.moveTo(center.dx, center.dy + halfSize);
        path.lineTo(center.dx - halfSize, center.dy - halfSize);
        path.lineTo(center.dx + halfSize, center.dy - halfSize);
        break;
    }
    path.close();

    canvas.drawPath(path, fillPaint);
    if (borderPaint != null && borderPaint.strokeWidth > 0) {
      canvas.drawPath(path, borderPaint);
    }
  }
}
