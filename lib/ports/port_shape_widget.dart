import 'package:flutter/material.dart';

import '../ports/point_shape_painter.dart';
import '../ports/port.dart';

/// A widget that renders different port shapes based on the port's shape configuration
class PortShapeWidget extends StatelessWidget {
  const PortShapeWidget({
    super.key,
    required this.shape,
    required this.position,
    required this.size,
    required this.color,
    required this.borderColor,
    required this.borderWidth,
  });

  final PortShape shape;
  final PortPosition position;
  final double size;
  final Color color;
  final Color borderColor;
  final double borderWidth;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(size, size),
      painter: _PortShapePainter(
        shape: shape,
        position: position,
        color: color,
        borderColor: borderColor,
        borderWidth: borderWidth,
      ),
    );
  }
}

/// Custom painter that uses PointShapePainter for rendering
class _PortShapePainter extends CustomPainter {
  const _PortShapePainter({
    required this.shape,
    required this.position,
    required this.color,
    required this.borderColor,
    required this.borderWidth,
  });

  final PortShape shape;
  final PortPosition position;
  final Color color;
  final Color borderColor;
  final double borderWidth;

  @override
  void paint(Canvas canvas, Size size) {
    // Convert PortShape to PointShape
    final pointShape = _portShapeToPointShape(shape);

    // Convert PortPosition to ShapeOrientation
    final orientation = _portPositionToOrientation(position);

    // Create paints
    final fillPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final borderPaint = borderWidth > 0
        ? (Paint()
            ..color = borderColor
            ..strokeWidth = borderWidth
            ..style = PaintingStyle.stroke)
        : null;

    // Use the common PointShapePainter
    PointShapePainter.paint(
      canvas: canvas,
      position: Offset(size.width / 2, size.height / 2),
      size: size.width,
      shape: pointShape,
      orientation: orientation,
      fillPaint: fillPaint,
      borderPaint: borderPaint,
    );
  }

  PointShape _portShapeToPointShape(PortShape shape) {
    switch (shape) {
      case PortShape.capsuleHalf:
        return PointShape.capsuleHalf;
      case PortShape.circle:
        return PointShape.circle;
      case PortShape.square:
        return PointShape.square;
      case PortShape.diamond:
        return PointShape.diamond;
      case PortShape.triangle:
        return PointShape.triangle;
    }
  }

  ShapeOrientation _portPositionToOrientation(PortPosition position) {
    switch (position) {
      case PortPosition.left:
        return ShapeOrientation.left;
      case PortPosition.right:
        return ShapeOrientation.right;
      case PortPosition.top:
        return ShapeOrientation.top;
      case PortPosition.bottom:
        return ShapeOrientation.bottom;
    }
  }

  @override
  bool shouldRepaint(_PortShapePainter oldDelegate) {
    return shape != oldDelegate.shape ||
        position != oldDelegate.position ||
        color != oldDelegate.color ||
        borderColor != oldDelegate.borderColor ||
        borderWidth != oldDelegate.borderWidth;
  }
}
