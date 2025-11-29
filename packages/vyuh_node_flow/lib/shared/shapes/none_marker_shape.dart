import 'package:flutter/material.dart';

import 'marker_shape.dart';

/// Marker shape that renders nothing.
///
/// Use this when you want an invisible marker or to disable
/// visual markers for ports or connection endpoints.
class NoneMarkerShape extends MarkerShape {
  const NoneMarkerShape();

  @override
  String get typeName => 'none';

  @override
  void paint(
    Canvas canvas,
    Offset center,
    double size,
    Paint fillPaint,
    Paint? borderPaint, {
    ShapeDirection? orientation,
    bool isPointingOutward = false,
  }) {
    // Intentionally empty - no shape rendered
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is NoneMarkerShape;

  @override
  int get hashCode => typeName.hashCode;
}
