import 'package:flutter/material.dart';

import '../../ports/port.dart';
import '../node_shape.dart';

/// A diamond (rhombus) node shape.
///
/// This shape renders nodes as diamonds, commonly used for:
/// - Decision nodes in flowcharts (if/else branches)
/// - Gateway nodes in BPMN diagrams
/// - Conditional logic nodes
///
/// The diamond has four points at the cardinal directions (top, right, bottom, left).
/// Ports are positioned at these four points.
///
/// Example:
/// ```dart
/// DiamondShape(
///   fillColor: Colors.orange,
///   strokeColor: Colors.deepOrange,
///   strokeWidth: 2.0,
/// )
/// ```
class DiamondShape extends NodeShape {
  /// Creates a diamond shape.
  ///
  /// Parameters:
  /// * [fillColor] - The fill color for the diamond background
  /// * [strokeColor] - The stroke color for the diamond outline
  /// * [strokeWidth] - The stroke width for the diamond outline
  const DiamondShape({
    super.fillColor,
    super.strokeColor,
    super.strokeWidth,
  });

  @override
  Path buildPath(Size size) {
    final centerX = size.width / 2;
    final centerY = size.height / 2;

    return Path()
      ..moveTo(centerX, 0) // Top point
      ..lineTo(size.width, centerY) // Right point
      ..lineTo(centerX, size.height) // Bottom point
      ..lineTo(0, centerY) // Left point
      ..close();
  }

  @override
  List<PortAnchor> getPortAnchors(Size size) {
    final centerX = size.width / 2;
    final centerY = size.height / 2;

    return [
      // Top port
      PortAnchor(
        position: PortPosition.top,
        offset: Offset(centerX, 0),
        normal: const Offset(0, -1),
      ),
      // Right port
      PortAnchor(
        position: PortPosition.right,
        offset: Offset(size.width, centerY),
        normal: const Offset(1, 0),
      ),
      // Bottom port
      PortAnchor(
        position: PortPosition.bottom,
        offset: Offset(centerX, size.height),
        normal: const Offset(0, 1),
      ),
      // Left port
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

    // Diamond can be represented as the intersection of 4 half-planes
    // formed by the 4 edges. A point is inside if it satisfies all 4 inequalities.

    // Transform point to centered coordinates
    final px = point.dx - centerX;
    final py = point.dy - centerY;

    // Check if point is within diamond bounds using Manhattan distance
    // For a diamond centered at origin: |x/a| + |y/b| <= 1
    // where a = width/2, b = height/2
    final normalizedDistance = (px.abs() / centerX) + (py.abs() / centerY);
    return normalizedDistance <= 1.0;
  }

  @override
  Rect getBounds(Size size) {
    return Offset.zero & size;
  }
}
