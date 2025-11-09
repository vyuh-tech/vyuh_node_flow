import 'package:flutter/material.dart';

import 'port.dart';
import 'shapes/port_shape.dart';

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

/// Custom painter that uses PortShape classes for rendering
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

    // Convert port position to shape orientation
    final orientation = _portPositionToOrientation(position);

    // Use the shape's paint method, passing orientation
    shape.paint(
      canvas,
      Offset(size.width / 2, size.height / 2),
      size.width,
      fillPaint,
      borderPaint,
      orientation: orientation,
    );
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
