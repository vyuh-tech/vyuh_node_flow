import 'package:flutter/material.dart';

import '../ports/port.dart';

/// Defines the visual shape and appearance of a node in the flow editor.
///
/// A [NodeShape] determines how a node appears visually by providing:
/// - A [Path] that defines the node's outline
/// - Port anchor points that define where ports attach to the shape
/// - Visual properties like fill color, stroke color, and stroke width
/// - Hit testing logic to determine if a point is inside the shape
///
/// This abstraction allows nodes to be rendered as various shapes like
/// circles, diamonds, hexagons, etc., instead of just rectangles.
///
/// Shapes are typically created in the [nodeContainerBuilder] based on
/// node type or data, keeping the node model purely data-focused.
///
/// Example:
/// ```dart
/// nodeContainerBuilder: (context, node) {
///   NodeShape? shape;
///   if (node.type == 'Decision') {
///     shape = DiamondShape(
///       fillColor: Colors.orange,
///       strokeColor: Colors.deepOrange,
///       strokeWidth: 2.0,
///     );
///   }
///   return NodeWidget(node: node, shape: shape, child: ...);
/// }
/// ```
abstract class NodeShape {
  const NodeShape({this.fillColor, this.strokeColor, this.strokeWidth});

  /// The fill color for the shape background.
  ///
  /// If null, will use the default from NodeTheme.
  final Color? fillColor;

  /// The stroke (border) color for the shape outline.
  ///
  /// If null, will use the default from NodeTheme.
  final Color? strokeColor;

  /// The stroke (border) width for the shape outline.
  ///
  /// If null, will use the default from NodeTheme.
  final double? strokeWidth;

  /// Builds the path that defines this shape's outline.
  ///
  /// The path should be constructed within the bounds of the given [size].
  /// The origin (0,0) represents the top-left corner.
  ///
  /// Parameters:
  /// * [size] - The size of the node
  ///
  /// Returns a [Path] that defines the shape's outline.
  Path buildPath(Size size);

  /// Gets the port anchor points for this shape.
  ///
  /// Port anchors define where ports can attach to the node. Each anchor
  /// specifies a position and the offset where a port should be placed.
  ///
  /// Parameters:
  /// * [size] - The size of the node
  ///
  /// Returns a list of [PortAnchor] objects defining attachment points.
  List<PortAnchor> getPortAnchors(Size size);

  /// Checks if a point is inside this shape.
  ///
  /// Used for hit testing to determine if user interactions (clicks, hovers)
  /// are within the node's bounds.
  ///
  /// Parameters:
  /// * [point] - The point to test (in the node's local coordinate space)
  /// * [size] - The size of the node
  ///
  /// Returns true if the point is inside the shape, false otherwise.
  bool containsPoint(Offset point, Size size) {
    return buildPath(size).contains(point);
  }

  /// Gets the bounding rectangle for this shape.
  ///
  /// By default, this returns a rectangle that encompasses the entire size.
  /// Shapes can override this if they have tighter bounds.
  ///
  /// Parameters:
  /// * [size] - The size of the node
  ///
  /// Returns a [Rect] that bounds the shape.
  Rect getBounds(Size size) {
    return Offset.zero & size;
  }
}

/// Defines a port anchor point on a node shape.
///
/// A port anchor specifies where a port should be positioned on a shape
/// and provides information for connection routing.
class PortAnchor {
  /// Creates a port anchor.
  ///
  /// Parameters:
  /// * [position] - The logical position (left, right, top, bottom)
  /// * [offset] - The actual offset from the node's origin where the port center should be
  /// * [normal] - Optional unit vector perpendicular to the shape edge (for connection routing)
  const PortAnchor({required this.position, required this.offset, this.normal});

  /// The logical position of this port (left, right, top, bottom).
  final PortPosition position;

  /// The actual offset from the node's origin where the port center should be positioned.
  final Offset offset;

  /// Optional unit vector perpendicular to the shape edge at this anchor point.
  ///
  /// Used for calculating connection tangents. For example:
  /// - Left port: Offset(-1, 0)
  /// - Right port: Offset(1, 0)
  /// - Top port: Offset(0, -1)
  /// - Bottom port: Offset(0, 1)
  final Offset? normal;
}
