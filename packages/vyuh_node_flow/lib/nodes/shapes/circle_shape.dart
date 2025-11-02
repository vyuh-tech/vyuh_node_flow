import 'package:flutter/material.dart';

import '../../ports/port.dart';
import '../node_shape.dart';

/// A circular node shape.
///
/// This shape renders nodes as circles or ellipses, commonly used for:
/// - Terminal nodes in flowcharts (start/end)
/// - Event nodes in BPMN diagrams
/// - State nodes in state machines
///
/// Ports are positioned at the cardinal points (top, right, bottom, left)
/// on the circle's perimeter.
///
/// Example:
/// ```dart
/// CircleShape(
///   fillColor: Colors.green,
///   strokeColor: Colors.darkGreen,
///   strokeWidth: 2.0,
/// )
/// ```
class CircleShape extends NodeShape {
  /// Creates a circle shape.
  ///
  /// Parameters:
  /// * [fillColor] - The fill color for the circle background
  /// * [strokeColor] - The stroke color for the circle outline
  /// * [strokeWidth] - The stroke width for the circle outline
  const CircleShape({
    super.fillColor,
    super.strokeColor,
    super.strokeWidth,
  });

  @override
  Path buildPath(Size size) {
    final center = Offset(size.width / 2, size.height / 2);

    return Path()..addOval(
      Rect.fromCenter(center: center, width: size.width, height: size.height),
    );
  }

  @override
  List<PortAnchor> getPortAnchors(Size size) {
    final centerX = size.width / 2;
    final centerY = size.height / 2;

    return [
      // Top port (90 degrees)
      PortAnchor(
        position: PortPosition.top,
        offset: Offset(centerX, 0),
        normal: const Offset(0, -1),
      ),
      // Right port (0 degrees)
      PortAnchor(
        position: PortPosition.right,
        offset: Offset(size.width, centerY),
        normal: const Offset(1, 0),
      ),
      // Bottom port (270 degrees)
      PortAnchor(
        position: PortPosition.bottom,
        offset: Offset(centerX, size.height),
        normal: const Offset(0, 1),
      ),
      // Left port (180 degrees)
      PortAnchor(
        position: PortPosition.left,
        offset: Offset(0, centerY),
        normal: const Offset(-1, 0),
      ),
    ];
  }

  @override
  bool containsPoint(Offset point, Size size) {
    final centerX = size.width / 2;
    final centerY = size.height / 2;
    final radiusX = size.width / 2;
    final radiusY = size.height / 2;

    // Use ellipse equation: (x-cx)²/rx² + (y-cy)²/ry² <= 1
    final dx = (point.dx - centerX) / radiusX;
    final dy = (point.dy - centerY) / radiusY;
    return (dx * dx + dy * dy) <= 1.0;
  }

  @override
  Rect getBounds(Size size) {
    return Offset.zero & size;
  }
}
