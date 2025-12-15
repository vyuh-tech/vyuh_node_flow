import 'package:flutter/material.dart';
import 'package:mobx/mobx.dart';

/// Position options for minimap placement
enum CornerPosition { topLeft, topRight, bottomLeft, bottomRight }

/// Reactive configuration class for NodeFlow properties
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
    CornerPosition minimapPosition = CornerPosition.bottomRight,
    Size minimapSize = const Size(200, 150),
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
      this.minimapPosition.value = minimapPosition;
      this.minimapSize.value = minimapSize;
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

  /// Position of the minimap
  final minimapPosition = Observable<CornerPosition>(CornerPosition.topRight);

  /// Size of the minimap
  final minimapSize = Observable<Size>(const Size(200, 150));

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

  /// Set minimap position
  void setCornerPosition(CornerPosition position) {
    runInAction(() {
      minimapPosition.value = position;
    });
  }

  /// Set minimap size
  void setMinimapSize(Size size) {
    runInAction(() {
      minimapSize.value = size;
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
    CornerPosition? minimapPosition,
    Size? minimapSize,
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
      if (minimapPosition != null) {
        this.minimapPosition.value = minimapPosition;
      }
      if (minimapSize != null) this.minimapSize.value = minimapSize;
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
    CornerPosition? minimapPosition,
    Size? minimapSize,
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
      minimapPosition: minimapPosition ?? this.minimapPosition.value,
      minimapSize: minimapSize ?? this.minimapSize.value,
      showAttribution: showAttribution ?? this.showAttribution,
    );
  }
}
