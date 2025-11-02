import 'package:flutter/material.dart';

import 'node_shape.dart';

/// A custom painter that renders a node shape with background and border.
///
/// This painter is used by [NodeWidget] to draw non-rectangular node shapes.
/// It renders:
/// - The shape's outline path
/// - Background fill color
/// - Border stroke
///
/// The painter respects the node's theme settings for colors and styling.
class NodeShapePainter extends CustomPainter {
  /// Creates a node shape painter.
  ///
  /// Parameters:
  /// * [shape] - The shape to render
  /// * [backgroundColor] - The fill color for the shape
  /// * [borderColor] - The color of the shape's outline
  /// * [borderWidth] - The width of the border stroke
  /// * [inset] - Optional inset to shrink the shape (for port space)
  /// * [shadows] - Optional list of shadows to render behind the shape
  const NodeShapePainter({
    required this.shape,
    required this.backgroundColor,
    required this.borderColor,
    required this.borderWidth,
    this.inset = EdgeInsets.zero,
    this.shadows,
    required this.size,
  });

  /// The shape to render.
  final NodeShape shape;

  /// The background fill color.
  final Color backgroundColor;

  /// The border stroke color.
  final Color borderColor;

  /// The border stroke width.
  final double borderWidth;

  /// Inset to shrink the shape, leaving space around edges (e.g., for ports).
  final EdgeInsets inset;

  /// Optional shadows to render behind the shape.
  final List<BoxShadow>? shadows;

  /// The size of the painter (needed for hit testing).
  final Size size;

  @override
  void paint(Canvas canvas, Size size) {
    // Use shape's visual properties if available, otherwise use passed values
    final effectiveFillColor = shape.fillColor ?? backgroundColor;
    final effectiveStrokeColor = shape.strokeColor ?? borderColor;
    final effectiveStrokeWidth = shape.strokeWidth ?? borderWidth;

    // Calculate the inset size
    final insetSize = Size(
      size.width - inset.left - inset.right,
      size.height - inset.top - inset.bottom,
    );

    // Build the fill path at the full inset size
    final fillPath = shape.buildPath(insetSize);
    final translatedFillPath = fillPath.shift(Offset(inset.left, inset.top));

    // Draw shadows if provided
    if (shadows != null && shadows!.isNotEmpty) {
      for (final shadow in shadows!) {
        final shadowPath = translatedFillPath.shift(shadow.offset);
        final shadowPaint = Paint()
          ..color = shadow.color
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, shadow.blurRadius);
        canvas.drawPath(shadowPath, shadowPaint);
      }
    }

    // Draw the filled background
    final fillPaint = Paint()
      ..color = effectiveFillColor
      ..style = PaintingStyle.fill;
    canvas.drawPath(translatedFillPath, fillPaint);

    // Draw the border - inset by the full border width on all sides
    // The stroke extends half-width on each side, so the outer edge
    // reaches the fill edge while the entire stroke stays inside
    if (effectiveStrokeWidth > 0) {
      final halfBorder = effectiveStrokeWidth / 2;

      // Border path is smaller by full border width
      final borderSize = Size(
        insetSize.width - effectiveStrokeWidth,
        insetSize.height - effectiveStrokeWidth,
      );
      final borderPath = shape.buildPath(borderSize);

      // Position inward by half border width
      final translatedBorderPath = borderPath.shift(
        Offset(inset.left + halfBorder, inset.top + halfBorder),
      );

      final borderPaint = Paint()
        ..color = effectiveStrokeColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = effectiveStrokeWidth
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round;
      canvas.drawPath(translatedBorderPath, borderPaint);
    }
  }

  @override
  bool shouldRepaint(NodeShapePainter oldDelegate) {
    return shape != oldDelegate.shape ||
        backgroundColor != oldDelegate.backgroundColor ||
        borderColor != oldDelegate.borderColor ||
        borderWidth != oldDelegate.borderWidth ||
        inset != oldDelegate.inset ||
        shadows != oldDelegate.shadows ||
        size != oldDelegate.size;
  }

  @override
  bool hitTest(Offset position) {
    // Use full size for hit testing (not inset)
    // The shape might be rendered smaller due to inset/padding, but we want
    // the entire painter area to be clickable
    return shape.containsPoint(position, size);
  }
}
