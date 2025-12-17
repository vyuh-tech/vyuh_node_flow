import 'package:flutter/material.dart';
import 'package:mobx/mobx.dart';

/// Reactive configuration class for NodeFlow behavioral properties.
///
/// Visual properties like minimap appearance, colors, and styling are
/// configured through [NodeFlowTheme] and [MinimapTheme].
class NodeFlowConfig {
  NodeFlowConfig({
    bool snapToGrid = false,
    bool snapAnnotationsToGrid = false,
    double gridSize = 20.0,
    double portSnapDistance = 8.0,
    double minZoom = 0.5,
    double maxZoom = 2.0,
    bool showMinimap = false,
    bool isMinimapInteractive = true,
    this.showAttribution = true,
  }) {
    runInAction(() {
      this.snapToGrid.value = snapToGrid;
      this.snapAnnotationsToGrid.value = snapAnnotationsToGrid;
      this.gridSize.value = gridSize;
      this.portSnapDistance.value = portSnapDistance;
      this.minZoom.value = minZoom;
      this.maxZoom.value = maxZoom;
      this.showMinimap.value = showMinimap;
      this.isMinimapInteractive.value = isMinimapInteractive;
    });
  }

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

  /// Whether to show minimap overlay
  final showMinimap = Observable<bool>(false);

  /// Whether the minimap can be interacted with
  final isMinimapInteractive = Observable<bool>(true);

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

  /// Toggle minimap visibility
  void toggleMinimap() {
    runInAction(() {
      showMinimap.value = !showMinimap.value;
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
    bool? showMinimap,
    bool? isMinimapInteractive,
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
      if (showMinimap != null) this.showMinimap.value = showMinimap;
      if (isMinimapInteractive != null) {
        this.isMinimapInteractive.value = isMinimapInteractive;
      }
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

  /// Create a copy with different initial values (for migration purposes)
  /// This creates a new config instance with the specified values
  NodeFlowConfig copyWith({
    bool? snapToGrid,
    bool? snapAnnotationsToGrid,
    double? gridSize,
    double? portSnapDistance,
    double? minZoom,
    double? maxZoom,
    bool? showMinimap,
    bool? isMinimapInteractive,
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
      showMinimap: showMinimap ?? this.showMinimap.value,
      isMinimapInteractive:
          isMinimapInteractive ?? this.isMinimapInteractive.value,
      showAttribution: showAttribution ?? this.showAttribution,
    );
  }
}
