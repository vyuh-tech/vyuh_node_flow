import 'package:flutter/material.dart';

import 'capsule_half_port_shape.dart';
import 'circle_port_shape.dart';
import 'diamond_port_shape.dart';
import 'none_port_shape.dart';
import 'square_port_shape.dart';
import 'triangle_port_shape.dart';

/// Orientation for directional port shapes (capsuleHalf, triangle)
enum ShapeDirection { left, right, top, bottom }

/// Abstract base class for port shapes.
///
/// Following the GridStyle pattern, this class provides a common interface
/// for rendering different port shapes. Each shape type is implemented as a
/// concrete subclass that defines its own painting logic.
///
/// See [PortShapes] for predefined shape constants.
///
/// Custom shapes can be created by extending this class and implementing
/// the [paint] method.
abstract class PortShape {
  const PortShape();

  /// Paints the port shape on the given canvas.
  ///
  /// Parameters:
  /// - [canvas]: The canvas to draw on
  /// - [center]: The center position of the shape
  /// - [size]: The diameter of the shape
  /// - [fillPaint]: Paint to use for filling the shape
  /// - [borderPaint]: Optional paint to use for the border/stroke
  /// - [orientation]: Optional orientation for directional shapes (capsuleHalf, triangle)
  void paint(
    Canvas canvas,
    Offset center,
    double size,
    Paint fillPaint,
    Paint? borderPaint, {
    ShapeDirection? orientation,
  });

  /// Returns the type name of this shape for JSON serialization
  String get typeName;

  /// Converts this shape to a JSON-serializable map
  Map<String, dynamic> toJson() {
    return {'type': typeName};
  }

  /// Creates a PortShape from JSON
  factory PortShape.fromJson(Map<String, dynamic> json) {
    final type = json['type'] as String;

    switch (type) {
      case 'none':
        return const NonePortShape();
      case 'circle':
        return const CirclePortShape();
      case 'square':
        return const SquarePortShape();
      case 'diamond':
        return const DiamondPortShape();
      case 'triangle':
        return const TrianglePortShape();
      case 'capsuleHalf':
        return const CapsuleHalfPortShape();
      default:
        throw ArgumentError('Unknown port shape type: $type');
    }
  }
}
