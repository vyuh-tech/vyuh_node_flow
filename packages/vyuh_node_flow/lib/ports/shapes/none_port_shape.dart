import 'package:flutter/material.dart';

import 'port_shape.dart';

/// Port shape that renders nothing
class NonePortShape extends PortShape {
  const NonePortShape();

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
    bool isOutputPort = false,
  }) {
    // Intentionally empty - no shape rendered
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is NonePortShape;

  @override
  int get hashCode => typeName.hashCode;
}
