import 'package:flutter/material.dart';

import '../graph/node_flow_theme.dart';
import '../graph/viewport.dart';

/// CustomPainter that delegates grid rendering to a GridStyle.
///
/// This painter wraps a [GridStyle] instance and provides it with the necessary
/// context (theme and viewport) to render the grid pattern on the canvas.
class GridPainter extends CustomPainter {
  const GridPainter({required this.theme, required this.viewport});

  final NodeFlowTheme theme;
  final GraphViewport viewport;

  @override
  void paint(Canvas canvas, Size size) {
    // Delegate to the grid style's paint method
    theme.gridTheme.style.paint(canvas, size, theme, viewport);
  }

  @override
  bool shouldRepaint(GridPainter oldDelegate) {
    return viewport != oldDelegate.viewport || theme != oldDelegate.theme;
  }
}
