import 'package:flutter/material.dart';

import 'capsule_half_marker_shape.dart';
import 'circle_marker_shape.dart';
import 'diamond_marker_shape.dart';
import 'none_marker_shape.dart';
import 'rectangle_marker_shape.dart';
import 'triangle_marker_shape.dart';

/// Orientation/direction for marker shapes.
///
/// Specifies the direction a shape is anchored or facing:
/// - For ports: which side of the node the port is on
/// - For connection endpoints: which direction the endpoint faces
enum ShapeDirection { left, right, top, bottom }

/// Abstract base class for marker shapes.
///
/// Marker shapes are used to render visual markers at connection points,
/// including both ports on nodes and endpoints on connections.
///
/// Following the GridStyle pattern, this class provides a common interface
/// for rendering different shapes. Each shape type is implemented as a
/// concrete subclass that defines its own painting logic.
///
/// See [MarkerShapes] for predefined shape constants.
///
/// Custom shapes can be created by extending this class and implementing
/// the [paint] method.
abstract class MarkerShape {
  const MarkerShape();

  /// Returns the effective rendered size of this shape for a given base size
  /// and orientation.
  ///
  /// For symmetric shapes (circle, square, diamond), this returns the base size
  /// unchanged. For asymmetric shapes (rectangle, capsuleHalf), the effective
  /// size may differ based on orientation and aspect ratio.
  ///
  /// Parameters:
  /// - [baseSize]: The base size specified for the port/marker
  /// - [orientation]: The direction the shape is anchored/facing
  ///
  /// Returns the actual width and height the shape will occupy when rendered.
  ///
  /// This is used for accurate port positioning calculations where we need
  /// to know the exact dimensions of the rendered shape.
  Size getEffectiveSize(Size baseSize, ShapeDirection orientation) {
    // Default implementation: use base size as-is (for symmetric shapes)
    return baseSize;
  }

  /// Paints the marker shape on the given canvas.
  ///
  /// Parameters:
  /// - [canvas]: The canvas to draw on
  /// - [center]: The center position of the shape
  /// - [size]: The size of the shape (width and height)
  /// - [fillPaint]: Paint to use for filling the shape
  /// - [borderPaint]: Optional paint to use for the border/stroke
  /// - [orientation]: Direction the shape is anchored/facing (left, right, top, bottom)
  /// - [isPointingOutward]: For asymmetric shapes (triangle, capsuleHalf), whether the
  ///   tip/arrow points outward. For ports: true for output ports, false for input ports.
  ///   For connection endpoints: typically true (pointing along connection direction).
  void paint(
    Canvas canvas,
    Offset center,
    Size size,
    Paint fillPaint,
    Paint? borderPaint, {
    ShapeDirection? orientation,
    bool isPointingOutward = false,
  });

  /// Returns the type name of this shape for JSON serialization
  String get typeName;

  /// Converts this shape to a JSON-serializable map
  Map<String, dynamic> toJson() {
    return {'type': typeName};
  }

  /// Creates a MarkerShape from JSON
  factory MarkerShape.fromJson(Map<String, dynamic> json) {
    final type = json['type'] as String;

    switch (type) {
      case 'none':
        return const NoneMarkerShape();
      case 'circle':
        return const CircleMarkerShape();
      case 'rectangle':
        return const RectangleMarkerShape();
      case 'diamond':
        return const DiamondMarkerShape();
      case 'triangle':
        return const TriangleMarkerShape();
      case 'capsuleHalf':
        return const CapsuleHalfMarkerShape();
      default:
        throw ArgumentError('Unknown marker shape type: $type');
    }
  }
}
