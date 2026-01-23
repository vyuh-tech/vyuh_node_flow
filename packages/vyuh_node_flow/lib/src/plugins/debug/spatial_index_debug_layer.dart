import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';

import '../../editor/controller/node_flow_controller.dart';
import '../../graph/viewport.dart';
import 'debug_plugin.dart';
import 'spatial_index_debug_painter.dart';

/// Debug layer that visualizes the spatial index grid.
///
/// This layer renders an overlay showing how the spatial index partitions
/// the canvas into cells. It displays:
/// - Grid cell boundaries (large cells, typically 500px)
/// - Cell coordinates as `[x, y]` in the top-left corner (green background when mouse is in cell)
/// - Object counts as vertical list: `N: X`, `C: X`, `P: X` (nodes, connections, ports)
/// - Visual highlighting for active (non-empty) cells
///
/// The spatial index grid is much larger than the visual grid (default 500px
/// vs 20px) because it's optimized for query performance, not visual reference.
///
/// ## Usage
///
/// Add this layer to your node flow editor when debug mode is enabled:
///
/// ```dart
/// if (controller.debug.isEnabled) ...[
///   SpatialIndexDebugLayer<MyData>(
///     controller: controller,
///     transformationController: transformationController,
///   ),
/// ],
/// ```
class SpatialIndexDebugLayer<T> extends StatelessWidget {
  const SpatialIndexDebugLayer({
    super.key,
    required this.controller,
    required this.transformationController,
  });

  /// The node flow controller containing the spatial index.
  final NodeFlowController<T, dynamic> controller;

  /// The transformation controller for viewport tracking.
  final TransformationController transformationController;

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
                  // the index changes (nodes/connections added/moved/removed)
                  final version = controller.spatialIndex.version.value;

                  // Observe the mouse position from the controller
                  final mousePosition = controller.mousePositionWorld;

                  // Get theme from debug extension, fallback to light theme
                  final debugTheme =
                      controller.debug?.theme ?? DebugTheme.light;

                  return CustomPaint(
                    painter: SpatialIndexDebugPainter(
                      spatialIndex: controller.spatialIndex,
                      viewport: viewport,
                      version: version,
                      theme: debugTheme,
                      mousePositionWorld: mousePosition?.offset,
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
