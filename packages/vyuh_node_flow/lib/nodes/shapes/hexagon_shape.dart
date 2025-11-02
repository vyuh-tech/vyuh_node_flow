import 'package:flutter/material.dart';

import '../../ports/port.dart';
import '../node_shape.dart';

/// A hexagonal node shape.
///
/// This shape renders nodes as hexagons, commonly used for:
/// - Preparation nodes in flowcharts
/// - Processing nodes
/// - Configuration or setup steps
///
/// The hexagon can be oriented horizontally (flat top/bottom) or vertically
/// (pointed top/bottom). By default, it uses horizontal orientation.
///
/// Ports are positioned at the six vertices or the four cardinal directions
/// depending on the use case.
///
/// Example:
/// ```dart
/// HexagonShape(
///   orientation: HexagonOrientation.horizontal,
///   fillColor: Colors.purple,
///   strokeColor: Colors.deepPurple,
///   strokeWidth: 2.0,
/// )
/// ```
class HexagonShape extends NodeShape {
  /// Creates a hexagon shape.
  ///
  /// Parameters:
  /// * [orientation] - Whether the hexagon has flat top/bottom or pointed top/bottom
  /// * [sideRatio] - The ratio of the angled sides to total width (0.0-0.5, default 0.2)
  /// * [fillColor] - The fill color for the hexagon background
  /// * [strokeColor] - The stroke color for the hexagon outline
  /// * [strokeWidth] - The stroke width for the hexagon outline
  const HexagonShape({
    this.orientation = HexagonOrientation.horizontal,
    this.sideRatio = 0.2,
    super.fillColor,
    super.strokeColor,
    super.strokeWidth,
  }) : assert(
         sideRatio >= 0.0 && sideRatio <= 0.5,
         'sideRatio must be between 0.0 and 0.5',
       );

  /// The orientation of the hexagon.
  final HexagonOrientation orientation;

  /// The ratio of the angled sides to total width/height.
  ///
  /// For horizontal hexagons, this is the width of the left/right angled sections.
  /// For vertical hexagons, this is the height of the top/bottom angled sections.
  ///
  /// Valid range: 0.0 (becomes a rectangle) to 0.5 (becomes a diamond).
  /// Default: 0.2 (typical hexagon appearance).
  final double sideRatio;

  @override
  Path buildPath(Size size) {
    if (orientation == HexagonOrientation.horizontal) {
      return _buildHorizontalHexagon(size);
    } else {
      return _buildVerticalHexagon(size);
    }
  }

  Path _buildHorizontalHexagon(Size size) {
    final sideWidth = size.width * sideRatio;
    final centerY = size.height / 2;

    return Path()
      ..moveTo(sideWidth, 0) // Top left corner
      ..lineTo(size.width - sideWidth, 0) // Top right corner
      ..lineTo(size.width, centerY) // Right point
      ..lineTo(size.width - sideWidth, size.height) // Bottom right corner
      ..lineTo(sideWidth, size.height) // Bottom left corner
      ..lineTo(0, centerY) // Left point
      ..close();
  }

  Path _buildVerticalHexagon(Size size) {
    final sideHeight = size.height * sideRatio;
    final centerX = size.width / 2;

    return Path()
      ..moveTo(centerX, 0) // Top point
      ..lineTo(size.width, sideHeight) // Top right corner
      ..lineTo(size.width, size.height - sideHeight) // Bottom right corner
      ..lineTo(centerX, size.height) // Bottom point
      ..lineTo(0, size.height - sideHeight) // Bottom left corner
      ..lineTo(0, sideHeight) // Top left corner
      ..close();
  }

  @override
  List<PortAnchor> getPortAnchors(Size size) {
    if (orientation == HexagonOrientation.horizontal) {
      return _getHorizontalPortAnchors(size);
    } else {
      return _getVerticalPortAnchors(size);
    }
  }

  List<PortAnchor> _getHorizontalPortAnchors(Size size) {
    final centerX = size.width / 2;
    final centerY = size.height / 2;

    return [
      // Top port (center of top edge)
      PortAnchor(
        position: PortPosition.top,
        offset: Offset(centerX, 0),
        normal: const Offset(0, -1),
      ),
      // Right port (the pointed end)
      PortAnchor(
        position: PortPosition.right,
        offset: Offset(size.width, centerY),
        normal: const Offset(1, 0),
      ),
      // Bottom port (center of bottom edge)
      PortAnchor(
        position: PortPosition.bottom,
        offset: Offset(centerX, size.height),
        normal: const Offset(0, 1),
      ),
      // Left port (the pointed end)
      PortAnchor(
        position: PortPosition.left,
        offset: Offset(0, centerY),
        normal: const Offset(-1, 0),
      ),
    ];
  }

  List<PortAnchor> _getVerticalPortAnchors(Size size) {
    final centerX = size.width / 2;
    final centerY = size.height / 2;

    return [
      // Top port (the pointed end)
      PortAnchor(
        position: PortPosition.top,
        offset: Offset(centerX, 0),
        normal: const Offset(0, -1),
      ),
      // Right port (center of right edge)
      PortAnchor(
        position: PortPosition.right,
        offset: Offset(size.width, centerY),
        normal: const Offset(1, 0),
      ),
      // Bottom port (the pointed end)
      PortAnchor(
        position: PortPosition.bottom,
        offset: Offset(centerX, size.height),
        normal: const Offset(0, 1),
      ),
      // Left port (center of left edge)
      PortAnchor(
        position: PortPosition.left,
        offset: Offset(0, centerY),
        normal: const Offset(-1, 0),
      ),
    ];
  }

  @override
  bool containsPoint(Offset point, Size size) {
    // Use the default path-based containment check
    return buildPath(size).contains(point);
  }

  @override
  Rect getBounds(Size size) {
    return Offset.zero & size;
  }
}

/// Defines the orientation of a hexagon shape.
enum HexagonOrientation {
  /// Hexagon with flat top and bottom edges, pointed left and right.
  ///
  /// Typical appearance:
  /// ```
  ///    ___
  ///   /   \
  ///  <     >
  ///   \___/
  /// ```
  horizontal,

  /// Hexagon with pointed top and bottom, flat left and right edges.
  ///
  /// Typical appearance:
  /// ```
  ///    /\
  ///   |  |
  ///   |  |
  ///    \/
  /// ```
  vertical,
}
