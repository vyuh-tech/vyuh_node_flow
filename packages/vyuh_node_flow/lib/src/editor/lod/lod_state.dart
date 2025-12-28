import 'package:mobx/mobx.dart';

import '../../graph/viewport.dart';
import '../node_flow_config.dart';
import 'detail_visibility.dart';
import 'lod_config.dart';

/// Reactive Level of Detail (LOD) state that computes current visibility
/// settings based on the viewport zoom level.
///
/// This class provides MobX-reactive access to LOD state, automatically
/// updating when the viewport zoom changes. Use this in widgets to
/// conditionally render elements based on zoom level.
///
/// The state is computed using MobX [Computed] values, which are cached
/// and only recalculated when dependencies change. This ensures efficient
/// reactivity without unnecessary recalculations.
///
/// Example:
/// ```dart
/// // In a widget build method
/// return Observer(builder: (_) {
///   final visibility = controller.lodState.currentVisibility;
///
///   if (!visibility.showConnectionLines) {
///     return const SizedBox.shrink();
///   }
///
///   return ConnectionsLayer(...);
/// });
/// ```
class LODState {
  /// Creates an LOD state that reacts to viewport and configuration changes.
  ///
  /// Parameters:
  /// - [config]: The node flow configuration containing minZoom/maxZoom and lodConfig
  /// - [viewport]: Observable viewport containing the current zoom level
  LODState({
    required NodeFlowConfig config,
    required Observable<GraphViewport> viewport,
  }) : _config = config,
       _viewport = viewport {
    _setupComputedValues();
  }

  final NodeFlowConfig _config;
  final Observable<GraphViewport> _viewport;

  late final Computed<double> _normalizedZoom;
  late final Computed<DetailVisibility> _currentVisibility;

  /// The LOD configuration containing thresholds and visibility presets.
  LODConfig get lodConfig => _config.lodConfig.value;

  /// The current zoom value normalized to a 0.0-1.0 range.
  ///
  /// - 0.0 = at minZoom (most zoomed out)
  /// - 1.0 = at maxZoom (most zoomed in)
  ///
  /// This value is computed from the viewport zoom and the min/max zoom
  /// settings in [NodeFlowConfig].
  double get normalizedZoom => _normalizedZoom.value;

  /// The current visibility configuration based on zoom level.
  ///
  /// Returns one of:
  /// - [LODConfig.minVisibility] when normalizedZoom < minThreshold
  /// - [LODConfig.midVisibility] when minThreshold <= normalizedZoom < midThreshold
  /// - [LODConfig.maxVisibility] when normalizedZoom >= midThreshold
  DetailVisibility get currentVisibility => _currentVisibility.value;

  // ============================================================================
  // Convenience Accessors
  // ============================================================================

  /// Whether node content should be visible at the current zoom level.
  bool get showNodeContent => currentVisibility.showNodeContent;

  /// Whether port shapes should be visible at the current zoom level.
  bool get showPorts => currentVisibility.showPorts;

  /// Whether port labels should be visible at the current zoom level.
  bool get showPortLabels => currentVisibility.showPortLabels;

  /// Whether connection lines should be visible at the current zoom level.
  bool get showConnectionLines => currentVisibility.showConnectionLines;

  /// Whether connection labels should be visible at the current zoom level.
  bool get showConnectionLabels => currentVisibility.showConnectionLabels;

  /// Whether connection endpoints should be visible at the current zoom level.
  bool get showConnectionEndpoints => currentVisibility.showConnectionEndpoints;

  /// Whether resize handles should be visible at the current zoom level.
  bool get showResizeHandles => currentVisibility.showResizeHandles;

  // ============================================================================
  // Configuration Updates
  // ============================================================================

  /// Updates the LOD configuration at runtime.
  ///
  /// Use this to change LOD thresholds or visibility presets dynamically.
  /// The change will immediately affect [currentVisibility].
  ///
  /// Example:
  /// ```dart
  /// // Switch to disabled LOD (always show full detail)
  /// controller.lodState.updateConfig(LODConfig.disabled);
  ///
  /// // Adjust thresholds
  /// controller.lodState.updateConfig(LODConfig(
  ///   minThreshold: 0.3,
  ///   midThreshold: 0.7,
  /// ));
  /// ```
  void updateConfig(LODConfig newConfig) {
    _config.setLODConfig(newConfig);
  }

  // ============================================================================
  // Private Implementation
  // ============================================================================

  void _setupComputedValues() {
    _normalizedZoom = Computed(() {
      final zoom = _viewport.value.zoom;
      final minZoom = _config.minZoom.value;
      final maxZoom = _config.maxZoom.value;

      final range = maxZoom - minZoom;
      if (range <= 0) {
        // If min equals max, we're at "full" zoom
        return 1.0;
      }

      return ((zoom - minZoom) / range).clamp(0.0, 1.0);
    });

    _currentVisibility = Computed(() {
      final normalized = _normalizedZoom.value;
      final config = _config.lodConfig.value;

      return config.getVisibilityForZoom(normalized);
    });
  }
}
