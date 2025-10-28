import 'package:flutter/material.dart';

import '../connections/connection_theme.dart';
import '../ports/point_shape_painter.dart';
import '../ports/port.dart';

/// Painter for connection endpoints that can render different shapes
class EndpointPainter {
  /// Paints an endpoint shape at the given position
  static void paint({
    required Canvas canvas,
    required Offset position,
    required double size,
    required EndpointShape shape,
    required PortPosition portPosition,
    required Paint fillPaint,
    Paint? borderPaint,
  }) {
    // Convert EndpointShape to PointShape
    final pointShape = _endpointShapeToPointShape(shape);

    // Get orientation (endpoints face away from the port they connect to)
    final orientation = _getOppositeOrientation(portPosition);

    // Use the common PointShapePainter
    PointShapePainter.paint(
      canvas: canvas,
      position: position,
      size: size,
      shape: pointShape,
      orientation: orientation,
      fillPaint: fillPaint,
      borderPaint: borderPaint,
    );
  }

  /// Convert EndpointShape to PointShape
  static PointShape _endpointShapeToPointShape(EndpointShape shape) {
    switch (shape) {
      case EndpointShape.none:
        return PointShape.none;
      case EndpointShape.capsuleHalf:
        return PointShape.capsuleHalf;
      case EndpointShape.circle:
        return PointShape.circle;
      case EndpointShape.square:
        return PointShape.square;
      case EndpointShape.diamond:
        return PointShape.diamond;
      case EndpointShape.triangle:
        return PointShape.triangle;
    }
  }

  /// Get the opposite orientation for endpoints
  /// (endpoints should face away from the port they connect to)
  static ShapeOrientation _getOppositeOrientation(PortPosition position) {
    switch (position) {
      case PortPosition.left:
        return ShapeOrientation
            .right; // Endpoint faces right when connecting to left port
      case PortPosition.right:
        return ShapeOrientation
            .left; // Endpoint faces left when connecting to right port
      case PortPosition.top:
        return ShapeOrientation
            .bottom; // Endpoint faces down when connecting to top port
      case PortPosition.bottom:
        return ShapeOrientation
            .top; // Endpoint faces up when connecting to bottom port
    }
  }
}
