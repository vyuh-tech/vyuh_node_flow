import 'package:mobx/mobx.dart';

import '../../extensions/events/events.dart';
import '../../extensions/node_flow_extension.dart';
import '../controller/node_flow_controller.dart';
import 'detail_visibility.dart';
import 'lod_config.dart';

/// Level of Detail (LOD) extension that provides reactive visibility
/// settings based on the viewport zoom level.
///
/// This extension extends [NodeFlowExtension] with [LODConfig] and manages
/// its own config via an internal Observable. It computes visibility settings
/// using MobX [Computed] values that react to zoom and config changes.
///
/// ## Usage
///
/// Access LOD state via the controller's `lod` getter:
///
/// ```dart
/// // In a widget build method
/// return Observer(builder: (_) {
///   if (!controller.lod.showConnectionLines) {
///     return const SizedBox.shrink();
///   }
///   return ConnectionsLayer(...);
/// });
/// ```
///
/// ## Configuration
///
/// Update LOD thresholds at runtime:
///
/// ```dart
/// controller.lod.updateConfig(LODConfig.disabled); // Always show full detail
/// ```
class LodExtension extends NodeFlowExtension<LODConfig> {
  /// Creates a LOD extension with optional initial configuration.
  ///
  /// Defaults to [LODConfig.standard] if no config is provided.
  LodExtension({LODConfig config = LODConfig.defaultConfig})
    : _config = Observable(config);

  /// The internal observable holding the LOD configuration.
  final Observable<LODConfig> _config;

  NodeFlowController? _controller;

  late Computed<double> _normalizedZoom;
  late Computed<DetailVisibility> _currentVisibility;

  @override
  String get id => 'lod';

  @override
  LODConfig get config => _config.value;

  @override
  void attach(NodeFlowController controller) {
    _controller = controller;
    _setupComputedValues();
  }

  @override
  void detach() {
    _controller = null;
  }

  @override
  void onEvent(GraphEvent event) {
    // LOD doesn't need to react to graph events - it only reacts to
    // viewport zoom changes via MobX computed values
  }

  // ============================================================================
  // Core LOD State
  // ============================================================================

  /// The LOD configuration containing thresholds and visibility presets.
  LODConfig get lodConfig => _config.value;

  /// The current zoom value normalized to a 0.0-1.0 range.
  ///
  /// - 0.0 = at minZoom (most zoomed out)
  /// - 1.0 = at maxZoom (most zoomed in)
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
  /// controller.lod.updateConfig(LODConfig.disabled);
  /// ```
  void updateConfig(LODConfig newConfig) {
    runInAction(() => _config.value = newConfig);
  }

  /// Disables LOD by setting config to [LODConfig.disabled].
  ///
  /// This ensures all visual elements are always shown regardless of zoom.
  void disable() => updateConfig(LODConfig.disabled);

  /// Enables standard LOD behavior by setting config to [LODConfig.defaultConfig].
  void useDefault() => updateConfig(LODConfig.defaultConfig);

  // ============================================================================
  // Private Implementation
  // ============================================================================

  void _setupComputedValues() {
    final controller = _controller!;
    final flowConfig = controller.config;

    _normalizedZoom = Computed(() {
      final zoom = controller.currentZoom;
      final minZoom = flowConfig.minZoom.value;
      final maxZoom = flowConfig.maxZoom.value;

      final range = maxZoom - minZoom;
      if (range <= 0) {
        return 1.0;
      }

      return ((zoom - minZoom) / range).clamp(0.0, 1.0);
    });

    _currentVisibility = Computed(() {
      final normalized = _normalizedZoom.value;
      // Use the extension's internal config Observable
      final lodConfig = _config.value;

      return lodConfig.getVisibilityForZoom(normalized);
    });
  }
}

// ============================================================================
// Controller Extension for LOD Access
// ============================================================================

/// Dart extension providing convenient access to LOD functionality.
///
/// This extension adds a [lod] getter to [NodeFlowController] that
/// lazily registers and returns the [LodExtension]. This pattern keeps
/// the controller lean while providing ergonomic access:
///
/// ```dart
/// // Access LOD state reactively
/// Observer(builder: (_) {
///   if (controller.lod.showPorts) {
///     return PortsLayer(...);
///   }
///   return const SizedBox.shrink();
/// });
/// ```
extension LodControllerExtension<T> on NodeFlowController<T> {
  /// Gets the Level of Detail (LOD) extension.
  ///
  /// LOD controls which visual elements are rendered based on zoom level.
  /// The extension is retrieved from the registry and attached on first access.
  ///
  /// Example:
  /// ```dart
  /// // Configure via NodeFlowConfig
  /// final flowConfig = NodeFlowConfig(
  ///   extensions: [
  ///     LodExtension(config: LODConfig.disabled),
  ///   ],
  /// );
  ///
  /// // Later access uses the configured extension
  /// controller.lod.showPorts; // always true (disabled LOD)
  /// ```
  LodExtension get lod {
    var existing = getExtension<LodExtension>();
    if (existing == null) {
      existing = config.extensionRegistry.get<LodExtension>();
      assert(
        existing != null,
        'LodExtension not found. Add it to NodeFlowConfig.extensions.',
      );
      addExtension(existing!);
    }
    return existing;
  }
}
