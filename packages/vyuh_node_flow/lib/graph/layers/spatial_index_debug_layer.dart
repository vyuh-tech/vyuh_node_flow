import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';

import '../../grid/spatial_index_debug_painter.dart';
import '../node_flow_controller.dart';
import '../node_flow_theme.dart';
import '../viewport.dart';

/// Debug layer that visualizes the spatial index grid.
///
/// This layer renders an overlay showing how the spatial index partitions
/// the canvas into cells. It displays:
/// - Grid cell boundaries (large cells, typically 500px)
/// - Cell coordinates (e.g., "(0, 0)", "(-1, 0)") in the top-left corner
/// - Object counts by type: `n:X p:X c:X a:X` (nodes, ports, connections, annotations)
/// - Visual highlighting for active (non-empty) cells
/// - Star indicator (★) showing which cell the mouse cursor is in
///
/// The spatial index grid is much larger than the visual grid (default 500px
/// vs 20px) because it's optimized for query performance, not visual reference.
///
/// ## Usage
///
/// Add this layer to your node flow editor when debug mode is enabled:
///
/// ```dart
/// if (theme.debugMode) ...[
///   SpatialIndexDebugLayer<MyData>(
///     controller: controller,
///     transformationController: transformationController,
///     theme: theme,
///   ),
/// ],
/// ```
class SpatialIndexDebugLayer<T> extends StatelessWidget {
  const SpatialIndexDebugLayer({
    super.key,
    required this.controller,
    required this.transformationController,
    required this.theme,
  });

  /// The node flow controller containing the spatial index.
  final NodeFlowController<T> controller;

  /// The transformation controller for viewport tracking.
  final TransformationController transformationController;

  /// The node flow theme containing the debug theme configuration.
  final NodeFlowTheme theme;

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: IgnorePointer(
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

              // Observer inside ValueListenableBuilder to react to MobX changes
              return Observer(
                builder: (context) {
                  // Observe the spatial index version to trigger repaints when
                  // the index changes (nodes/connections/annotations added/moved/removed)
                  final version = controller.spatialIndex.version.value;

                  // Observe the mouse position from the controller
                  final mousePosition = controller.mousePositionWorld;

                  return CustomPaint(
                    painter: SpatialIndexDebugPainter(
                      spatialIndex: controller.spatialIndex,
                      viewport: viewport,
                      version: version,
                      theme: theme.debugTheme,
                      mousePositionWorld: mousePosition,
                    ),
                    size: Size.infinite,
                  );
                },
              );
            },
          ),
        ),
      ),
    );
  }
}
