import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';

import 'debug_extension.dart';
import '../../editor/controller/node_flow_controller.dart';
import 'spatial_index_debug_layer.dart';

/// Stack of graph-coordinate debug visualization layers.
///
/// This widget composes debug layers that are rendered in **graph coordinates**
/// (inside the InteractiveViewer's transformed space). For screen-coordinate
/// overlays like autopan zones, use [AutopanZoneDebugLayer] directly outside
/// the InteractiveViewer.
///
/// ## Coordinate Systems
///
/// NodeFlow uses two coordinate systems for debug layers:
///
/// 1. **Graph coordinates** (this widget): Layers that zoom/pan with the canvas
///    - Spatial index grid
///    - Node bounds visualization
///    - Connection routing debug
///
/// 2. **Screen coordinates** (separate widgets): Layers fixed to viewport
///    - [AutopanZoneDebugLayer]: Edge padding zones
///    - Minimap overlay
///
/// ## Included Layers
///
/// When `controller.debug.isEnabled` is true:
/// - **SpatialIndexDebugLayer**: Shows the spatial index grid partitioning
///
/// ## Usage
///
/// ```dart
/// // Inside InteractiveViewer's child (graph coordinates)
/// DebugLayersStack<MyData>(
///   controller: controller,
///   transformationController: transformationController,
/// )
///
/// // Outside InteractiveViewer (screen coordinates)
/// AutopanZoneDebugLayer<MyData>(controller: controller)
/// ```
class DebugLayersStack<T> extends StatelessWidget {
  const DebugLayersStack({
    super.key,
    required this.controller,
    required this.transformationController,
  });

  /// The node flow controller containing the config.
  final NodeFlowController<T, dynamic> controller;

  /// The transformation controller for viewport tracking.
  final TransformationController transformationController;

  @override
  Widget build(BuildContext context) {
    final debug = controller.debug;

    // If debug extension is not configured, render nothing
    if (debug == null) {
      return const SizedBox.shrink();
    }

    // Observer for reactive updates when debug mode changes
    return Observer(
      builder: (context) {
        // If debug is not enabled, render nothing
        if (!debug.isEnabled) {
          return const SizedBox.shrink();
        }

        return Stack(children: _buildDebugLayers(debug));
      },
    );
  }

  /// Builds the list of debug layers based on the current debug mode.
  ///
  /// Only layers relevant to the current debug settings are included.
  /// Note: These layers are in graph coordinates (inside InteractiveViewer).
  /// Screen-coordinate overlays like AutopanZoneDebugLayer should be added
  /// separately outside the InteractiveViewer.
  List<Widget> _buildDebugLayers(DebugExtension debug) {
    return [
      // Spatial index grid visualization (graph coordinates)
      if (debug.showSpatialIndex)
        SpatialIndexDebugLayer<T>(
          controller: controller,
          transformationController: transformationController,
        ),

      // Future debug layers in graph coordinates can be added here:
      // - HitAreaDebugLayer
      // - ConnectionRoutingDebugLayer
      // - NodeBoundsDebugLayer
      // - etc.
    ];
  }
}
