import 'package:flutter/material.dart';

import '../graph/node_flow_theme.dart';

class SelectionPainter {
  SelectionPainter({required this.theme})
    : _fillPaint = Paint()
        ..color = theme.selectionColor
        ..style = PaintingStyle.fill,
      _borderPaint = Paint()
        ..color = theme.selectionBorderColor
        ..strokeWidth = theme.selectionBorderWidth
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
    final paint = Paint()
      ..color = theme.selectionBorderColor.withValues(alpha: 0.5)
      ..strokeWidth = theme.selectionBorderWidth
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
