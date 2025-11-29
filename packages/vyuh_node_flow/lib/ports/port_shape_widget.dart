import 'package:flutter/material.dart';

import '../shared/shapes/marker_shape.dart';
import 'port.dart';

/// A widget that renders different marker shapes for ports.
///
/// For ports, asymmetric shapes (like triangles) always have their tips
/// pointing inward (into the node).
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

  final MarkerShape shape;
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

/// Custom painter that uses MarkerShape classes for rendering
class _PortShapePainter extends CustomPainter {
  const _PortShapePainter({
    required this.shape,
    required this.position,
    required this.color,
    required this.borderColor,
    required this.borderWidth,
  });

  final MarkerShape shape;
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

    // Use the shape's paint method, passing orientation from port position.
    // For ports, isPointingOutward is always false (tips point inward).
    shape.paint(
      canvas,
      Offset(size.width / 2, size.height / 2),
      size.width,
      fillPaint,
      borderPaint,
      orientation: position.toOrientation(),
      isPointingOutward: false,
    );
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
