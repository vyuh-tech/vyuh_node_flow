import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';

import '../../graph/viewport.dart';
import '../../grid/grid_painter.dart';
import '../../grid/grid_render_policy.dart';
import '../../plugins/lod/lod_plugin.dart';
import '../controller/node_flow_controller.dart';
import '../themes/node_flow_theme.dart';

/// Grid background layer widget that renders the grid pattern
class GridLayer extends StatelessWidget {
  const GridLayer({
    super.key,
    required this.controller,
    required this.theme,
    required this.transformationController,
  });

  final NodeFlowController<dynamic, dynamic> controller;
  final NodeFlowTheme theme;
  final TransformationController transformationController;

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: RepaintBoundary(
        child: Observer(
          builder: (context) {
            final isViewportInteracting =
                controller.interaction.isViewportInteracting.value;
            final lod = controller.lod;

            final effectiveTheme = GridRenderPolicy.resolve(
              baseTheme: theme,
              isViewportInteracting: isViewportInteracting,
              adaptiveInteractionActive:
                  lod?.isAdaptiveInteractionActive ?? false,
              useThumbnailMode: lod?.useThumbnailMode ?? false,
            );

            return ValueListenableBuilder<Matrix4>(
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
                  painter: GridPainter(
                    theme: effectiveTheme,
                    viewport: viewport,
                  ),
                  size: Size.infinite,
                );
              },
            );
          },
        ),
      ),
    );
  }
}
