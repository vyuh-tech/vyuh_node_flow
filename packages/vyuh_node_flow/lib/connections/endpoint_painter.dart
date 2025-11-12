import 'package:flutter/material.dart';

import '../ports/port.dart';
import '../ports/shapes/port_shape.dart';

/// Painter for connection endpoints that can render different shapes
class EndpointPainter {
  /// Paints an endpoint shape at the given position
  static void paint({
    required Canvas canvas,
    required Offset position,
    required double size,
    required PortShape shape,
    required PortPosition portPosition,
    required Paint fillPaint,
    Paint? borderPaint,
  }) {
    // Get opposite orientation (endpoints face away from the port they connect to)
    final orientation = _getOppositeOrientation(portPosition);

    // Use the PortShape's paint method
    shape.paint(
      canvas,
      position,
      size,
      fillPaint,
      borderPaint,
      orientation: orientation,
    );
  }

  /// Get the opposite orientation for endpoints
  /// (endpoints should face away from the port they connect to)
  static ShapeDirection _getOppositeOrientation(PortPosition position) {
    switch (position) {
      case PortPosition.left:
        return ShapeDirection
            .right; // Endpoint faces right when connecting to left port
      case PortPosition.right:
        return ShapeDirection
            .left; // Endpoint faces left when connecting to right port
      case PortPosition.top:
        return ShapeDirection
            .bottom; // Endpoint faces down when connecting to top port
      case PortPosition.bottom:
        return ShapeDirection
            .top; // Endpoint faces up when connecting to bottom port
    }
  }
}
