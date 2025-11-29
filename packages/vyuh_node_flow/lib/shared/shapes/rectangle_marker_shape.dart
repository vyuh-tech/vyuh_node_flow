import 'package:flutter/material.dart';

import 'marker_shape.dart';

/// Rectangle marker shape with configurable aspect ratio.
///
/// The [aspectRatio] defines the width relative to height (width / height)
/// for the base orientation (left/right ports):
/// - aspectRatio = 1.0: square
/// - aspectRatio < 1.0: taller than wide (e.g., 0.5 = 2:1 tall)
/// - aspectRatio > 1.0: wider than tall (e.g., 2.0 = 2:1 wide)
///
/// The rectangle automatically adjusts based on orientation:
/// - Left/Right ports: taller rectangle (height > width)
/// - Top/Bottom ports: wider rectangle (width > height)
///
/// The shape is centered on the port position, just like other port shapes.
///
/// The [size] parameter in [paint] represents the larger dimension.
class RectangleMarkerShape extends MarkerShape {
  /// Creates a rectangle marker shape with the given aspect ratio.
  ///
  /// Default aspect ratio is 0.5 (2:1 tall rectangle).
  const RectangleMarkerShape({this.aspectRatio = 0.5});

  /// Creates a square marker shape (aspect ratio = 1.0).
  const RectangleMarkerShape.square() : aspectRatio = 1.0;

  /// The aspect ratio (width / height) of the rectangle.
  ///
  /// - 1.0 = square
  /// - 0.5 = height is 2x width (tall)
  /// - 2.0 = width is 2x height (wide)
  final double aspectRatio;

  @override
  String get typeName => 'rectangle';

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
    final double width;
    final double height;
    Offset adjustedCenter = center;

    // Determine dimensions based on orientation
    // Left/Right: taller rectangle (height > width)
    // Top/Bottom: wider rectangle (width > height)
    final effectiveOrientation = orientation ?? ShapeDirection.right;

    // The outer edge should be flush with the node boundary (at center ± size/2),
    // just like other shapes that use a size × size bounding box.
    // Since rectangle is narrower, we offset to keep the outer edge aligned.
    switch (effectiveOrientation) {
      case ShapeDirection.left:
        // Taller rectangle, left edge flush with node's left boundary
        height = size;
        width = size * aspectRatio;
        // Left edge at center.dx - size/2, so offset center
        adjustedCenter = Offset(center.dx - size / 2 + width / 2, center.dy);
        break;
      case ShapeDirection.right:
        // Taller rectangle, right edge flush with node's right boundary
        height = size;
        width = size * aspectRatio;
        // Right edge at center.dx + size/2, so offset center
        adjustedCenter = Offset(center.dx + size / 2 - width / 2, center.dy);
        break;
      case ShapeDirection.top:
        // Wider rectangle, top edge flush with node's top boundary
        width = size;
        height = size * aspectRatio;
        // Top edge at center.dy - size/2, so offset center
        adjustedCenter = Offset(center.dx, center.dy - size / 2 + height / 2);
        break;
      case ShapeDirection.bottom:
        // Wider rectangle, bottom edge flush with node's bottom boundary
        width = size;
        height = size * aspectRatio;
        // Bottom edge at center.dy + size/2, so offset center
        adjustedCenter = Offset(center.dx, center.dy + size / 2 - height / 2);
        break;
    }

    final rect = Rect.fromCenter(
      center: adjustedCenter,
      width: width,
      height: height,
    );
    canvas.drawRect(rect, fillPaint);
    if (borderPaint != null && borderPaint.strokeWidth > 0) {
      canvas.drawRect(rect, borderPaint);
    }
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      'type': typeName,
      if (aspectRatio != 0.5) 'aspectRatio': aspectRatio,
    };
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RectangleMarkerShape && aspectRatio == other.aspectRatio;

  @override
  int get hashCode => Object.hash(typeName, aspectRatio);
}
