import 'package:flutter/material.dart';

import 'themes/node_flow_theme.dart';

class SelectionPainter {
  SelectionPainter({required this.theme})
    : _fillPaint = Paint()
        ..color = theme.selectionTheme.color
        ..style = PaintingStyle.fill,
      _borderPaint = Paint()
        ..color = theme.selectionTheme.borderColor
        ..strokeWidth = theme.selectionTheme.borderWidth
        ..style = PaintingStyle.stroke;

  final NodeFlowTheme theme;

  // Pre-calculated paint objects for maximum performance
  final Paint _fillPaint;
  final Paint _borderPaint;

  /// Paints multi-selection rectangle with optimized performance
  void paintSelectionRectangle(Canvas canvas, Rect selectionRect) {
    // Ultra-fast painting with pre-calculated paint objects
    canvas.drawRect(selectionRect, _fillPaint);
    canvas.drawRect(selectionRect, _borderPaint);
  }

  /// Paints snap guides
  void paintSnapGuides(
    Canvas canvas,
    Size canvasSize,
    List<Offset> guideLines,
  ) {
    final selectionTheme = theme.selectionTheme;
    final paint = Paint()
      ..color = selectionTheme.borderColor.withValues(alpha: 0.5)
      ..strokeWidth = selectionTheme.borderWidth
      ..style = PaintingStyle.stroke;

    for (final guide in guideLines) {
      // Vertical guide
      if (guide.dx.isFinite) {
        canvas.drawLine(
          Offset(guide.dx, 0),
          Offset(guide.dx, canvasSize.height),
          paint,
        );
      }

      // Horizontal guide
      if (guide.dy.isFinite) {
        canvas.drawLine(
          Offset(0, guide.dy),
          Offset(canvasSize.width, guide.dy),
          paint,
        );
      }
    }
  }
}
