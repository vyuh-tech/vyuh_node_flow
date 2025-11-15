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
    this.isOutputPort = false,
  });

  final PortShape shape;
  final PortPosition position;
  final double size;
  final Color color;
  final Color borderColor;
  final double borderWidth;
  final bool isOutputPort;

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
        isOutputPort: isOutputPort,
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
    required this.isOutputPort,
  });

  final PortShape shape;
  final PortPosition position;
  final Color color;
  final Color borderColor;
  final double borderWidth;
  final bool isOutputPort;

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

    // Use the shape's paint method, passing orientation from port position
    shape.paint(
      canvas,
      Offset(size.width / 2, size.height / 2),
      size.width,
      fillPaint,
      borderPaint,
      orientation: position.toOrientation(),
      isOutputPort: isOutputPort,
    );
  }

  @override
  bool shouldRepaint(_PortShapePainter oldDelegate) {
    return shape != oldDelegate.shape ||
        position != oldDelegate.position ||
        color != oldDelegate.color ||
        borderColor != oldDelegate.borderColor ||
        borderWidth != oldDelegate.borderWidth ||
        isOutputPort != oldDelegate.isOutputPort;
  }
}
