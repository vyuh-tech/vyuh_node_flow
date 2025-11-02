import 'package:flutter/material.dart';

import 'node_shape.dart';

/// A custom clipper that clips content to a node shape.
///
/// This clipper is used by [NodeWidget] to ensure that the node's content
/// (child widget) is clipped to the shape's boundaries, preventing content
/// from spilling outside non-rectangular shapes.
///
/// For example, when using a [DiamondShape], text and other content will
/// be clipped to stay within the diamond outline.
class NodeShapeClipper extends CustomClipper<Path> {
  /// Creates a node shape clipper.
  ///
  /// Parameters:
  /// * [shape] - The shape to clip to
  /// * [padding] - Optional inset padding to shrink the clipping area
  const NodeShapeClipper({required this.shape, this.padding = EdgeInsets.zero});

  /// The shape to clip to.
  final NodeShape shape;

  /// Optional padding to inset the clipping area.
  ///
  /// This can be used to ensure content doesn't touch the edges of the shape.
  final EdgeInsets padding;

  @override
  Path getClip(Size size) {
    // If there's padding, we need to create an inset path
    if (padding != EdgeInsets.zero) {
      // Calculate the inset size
      final insetSize = Size(
        size.width - padding.left - padding.right,
        size.height - padding.top - padding.bottom,
      );

      // Get the path for the inset size
      final insetPath = shape.buildPath(insetSize);

      // Translate the path by the padding offset
      return insetPath.shift(Offset(padding.left, padding.top));
    }

    // No padding, return the shape's path directly
    return shape.buildPath(size);
  }

  @override
  bool shouldReclip(NodeShapeClipper oldClipper) {
    return shape != oldClipper.shape || padding != oldClipper.padding;
  }
}
