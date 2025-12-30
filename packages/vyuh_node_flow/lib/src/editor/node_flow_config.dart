import 'package:flutter/material.dart';
import 'package:mobx/mobx.dart';

import '../extensions/auto_pan_extension.dart';
import '../extensions/debug_extension.dart';
import '../extensions/extension_registry.dart';
import '../extensions/minimap_extension.dart';
import '../extensions/node_flow_extension.dart';
import '../extensions/stats_extension.dart';
import 'lod/lod.dart';

// Re-export DebugMode for convenience
export '../extensions/debug_extension.dart' show DebugMode;

/// Reactive configuration class for NodeFlow behavioral properties.
///
/// Visual properties like minimap appearance, colors, and styling are
/// configured through [NodeFlowTheme] and [MinimapTheme].
///
/// ## Extension Configuration
///
/// Extensions are passed pre-configured. Built-in extensions are included
/// by default. Customize or add extensions via the [extensions] parameter:
///
/// ```dart
/// NodeFlowConfig(
///   extensions: [
///     MinimapExtension(config: MinimapConfig(visible: true, interactive: true)),
///     LodExtension(config: LODConfig.disabled),
///     AutoPanExtension(config: AutoPanConfig.fast),
///     DebugExtension(mode: DebugMode.spatialIndex),
///     StatsExtension(),
///   ],
/// );
/// ```
///
/// ## Default Extensions
///
/// If no extensions are provided, these defaults are used:
/// - [MinimapExtension] - minimap overlay
/// - [LodExtension] - level of detail (disabled by default)
/// - [AutoPanExtension] - autopan near edges (normal mode)
/// - [DebugExtension] - debug overlays (disabled by default)
/// - [StatsExtension] - graph statistics
class NodeFlowConfig {
  NodeFlowConfig({
    bool snapToGrid = false,
    bool snapAnnotationsToGrid = false,
    double gridSize = 20.0,
    double portSnapDistance = 8.0,
    double minZoom = 0.5,
    double maxZoom = 2.0,
    this.showAttribution = true,
    List<NodeFlowExtension<dynamic>>? extensions,
  }) : extensionRegistry = ExtensionRegistry(
         extensions ?? defaultExtensions(),
       ) {
    runInAction(() {
      this.snapToGrid.value = snapToGrid;
      this.snapAnnotationsToGrid.value = snapAnnotationsToGrid;
      this.gridSize.value = gridSize;
      this.portSnapDistance.value = portSnapDistance;
      this.minZoom.value = minZoom;
      this.maxZoom.value = maxZoom;
    });
  }

  /// Default extensions for a new config.
  static List<NodeFlowExtension<dynamic>> defaultExtensions() {
    return [
      AutoPanExtension(),
      DebugExtension(),
      LodExtension(config: LODConfig.disabled),
      MinimapExtension(),
    ];
  }

  /// Registry of extensions.
  ///
  /// Extensions are attached when first accessed via the controller's
  /// getters (e.g., `controller.minimap`, `controller.autoPan`).
  final ExtensionRegistry extensionRegistry;

  /// Whether to snap node positions to grid
  final snapToGrid = Observable<bool>(false);

  /// Whether to snap annotation positions to grid
  final snapAnnotationsToGrid = Observable<bool>(false);

  /// Grid size for snapping calculations
  final gridSize = Observable<double>(20.0);

  /// Distance threshold for port snapping during connection
  final portSnapDistance = Observable<double>(8.0);

  /// Minimum allowed zoom level
  final minZoom = Observable<double>(0.5);

  /// Maximum allowed zoom level
  final maxZoom = Observable<double>(2.0);

  /// Whether to show attribution label
  final bool showAttribution;

  /// Toggle grid snapping for both nodes and annotations
  void toggleSnapping() {
    runInAction(() {
      final newValue = !snapToGrid.value;
      snapToGrid.value = newValue;
      snapAnnotationsToGrid.value = newValue;
    });
  }

  /// Toggle only node snapping
  void toggleNodeSnapping() {
    runInAction(() {
      snapToGrid.value = !snapToGrid.value;
    });
  }

  /// Toggle only annotation snapping
  void toggleAnnotationSnapping() {
    runInAction(() {
      snapAnnotationsToGrid.value = !snapAnnotationsToGrid.value;
    });
  }

  /// Update multiple properties at once
  void update({
    bool? snapToGrid,
    bool? snapAnnotationsToGrid,
    double? gridSize,
    double? portSnapDistance,
    double? minZoom,
    double? maxZoom,
  }) {
    runInAction(() {
      if (snapToGrid != null) this.snapToGrid.value = snapToGrid;
      if (snapAnnotationsToGrid != null) {
        this.snapAnnotationsToGrid.value = snapAnnotationsToGrid;
      }
      if (gridSize != null) this.gridSize.value = gridSize;
      if (portSnapDistance != null) {
        this.portSnapDistance.value = portSnapDistance;
      }
      if (minZoom != null) this.minZoom.value = minZoom;
      if (maxZoom != null) this.maxZoom.value = maxZoom;
    });
  }

  /// Helper method to snap coordinates to grid if enabled
  Offset snapToGridIfEnabled(Offset position) {
    if (!snapToGrid.value) return position;

    final grid = gridSize.value;
    final snappedX = (position.dx / grid).round() * grid;
    final snappedY = (position.dy / grid).round() * grid;

    return Offset(snappedX, snappedY);
  }

  /// Helper method to snap annotation coordinates to grid if enabled
  Offset snapAnnotationsToGridIfEnabled(Offset position) {
    if (!snapAnnotationsToGrid.value) return position;

    final grid = gridSize.value;
    final snappedX = (position.dx / grid).round() * grid;
    final snappedY = (position.dy / grid).round() * grid;

    return Offset(snappedX, snappedY);
  }

  /// Default configuration factory
  static NodeFlowConfig get defaultConfig => NodeFlowConfig();

  /// Create a copy with different initial values
  NodeFlowConfig copyWith({
    bool? snapToGrid,
    bool? snapAnnotationsToGrid,
    double? gridSize,
    double? portSnapDistance,
    double? minZoom,
    double? maxZoom,
    bool? showAttribution,
  }) {
    return NodeFlowConfig(
      snapToGrid: snapToGrid ?? this.snapToGrid.value,
      snapAnnotationsToGrid:
          snapAnnotationsToGrid ?? this.snapAnnotationsToGrid.value,
      gridSize: gridSize ?? this.gridSize.value,
      portSnapDistance: portSnapDistance ?? this.portSnapDistance.value,
      minZoom: minZoom ?? this.minZoom.value,
      maxZoom: maxZoom ?? this.maxZoom.value,
      showAttribution: showAttribution ?? this.showAttribution,
    );
  }
}
