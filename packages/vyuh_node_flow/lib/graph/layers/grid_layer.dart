import 'package:flutter/material.dart';

import '../../grid/grid_painter.dart';
import '../node_flow_theme.dart';
import '../viewport.dart';

/// Grid background layer widget that renders the grid pattern
class GridLayer extends StatelessWidget {
  const GridLayer({
    super.key,
    required this.theme,
    required this.transformationController,
  });

  final NodeFlowTheme theme;
  final TransformationController transformationController;

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: RepaintBoundary(
        child: ValueListenableBuilder<Matrix4>(
          valueListenable: transformationController,
          builder: (context, transform, child) {
            final translation = transform.getTranslation();
            final scale = transform.getMaxScaleOnAxis();
            final viewport = GraphViewport(
              x: translation.x,
              y: translation.y,
              zoom: scale,
            );

            return CustomPaint(
              painter: GridPainter(theme: theme, viewport: viewport),
              size: Size.infinite,
            );
          },
        ),
      ),
    );
  }
}
