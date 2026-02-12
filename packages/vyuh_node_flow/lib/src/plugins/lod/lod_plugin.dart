import 'package:mobx/mobx.dart';

import '../../editor/controller/node_flow_controller.dart';
import '../events/events.dart';
import '../node_flow_plugin.dart';
import 'detail_visibility.dart';
import 'lod_adaptive_policy.dart';

/// Level of Detail (LOD) plugin that provides reactive visibility
/// settings based on the viewport zoom level.
///
/// This plugin manages LOD state via internal Observables and computes
/// visibility settings that react to zoom and threshold changes.
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
/// Configure via constructor parameters:
///
/// ```dart
/// LodPlugin(
///   enabled: true,
///   minThreshold: 0.2,
///   midThreshold: 0.5,
/// )
/// ```
///
/// Disable LOD at runtime:
///
/// ```dart
/// controller.lod.disable(); // Always show full detail
/// ```
class LodPlugin extends NodeFlowPlugin {
  /// Creates a LOD plugin with optional threshold and visibility settings.
  ///
  /// Parameters:
  /// - [enabled]: Whether LOD is enabled (default: false)
  /// - [minThreshold]: Normalized zoom below which [minVisibility] is used (default: 0.03)
  /// - [midThreshold]: Normalized zoom below which [midVisibility] is used (default: 0.1)
  /// - [minVisibility]: Visibility settings for lowest zoom level (default: minimal)
  /// - [midVisibility]: Visibility settings for medium zoom level (default: standard)
  /// - [maxVisibility]: Visibility settings for highest zoom level (default: full)
  LodPlugin({
    bool enabled = false,
    double minThreshold = 0.03,
    double midThreshold = 0.1,
    DetailVisibility minVisibility = DetailVisibility.minimal,
    DetailVisibility midVisibility = DetailVisibility.standard,
    DetailVisibility maxVisibility = DetailVisibility.full,
    bool adaptiveEnabled = true,
    int adaptiveNodeThreshold = 300,
    int adaptiveConnectionThreshold = 500,
    int adaptiveExtremeNodeThreshold = 1000,
    int adaptiveExtremeConnectionThreshold = 2000,
  }) : _enabled = Observable(enabled),
       _minThreshold = Observable(minThreshold),
       _midThreshold = Observable(midThreshold),
       _minVisibility = Observable(minVisibility),
       _midVisibility = Observable(midVisibility),
       _maxVisibility = Observable(maxVisibility),
       _adaptiveEnabled = Observable(adaptiveEnabled),
       _adaptiveNodeThreshold = Observable(adaptiveNodeThreshold),
       _adaptiveConnectionThreshold = Observable(adaptiveConnectionThreshold),
       _adaptiveExtremeNodeThreshold = Observable(adaptiveExtremeNodeThreshold),
       _adaptiveExtremeConnectionThreshold = Observable(
         adaptiveExtremeConnectionThreshold,
       );

  // ═══════════════════════════════════════════════════════════════════════════
  // Observable State
  // ═══════════════════════════════════════════════════════════════════════════

  final Observable<bool> _enabled;
  final Observable<double> _minThreshold;
  final Observable<double> _midThreshold;
  final Observable<DetailVisibility> _minVisibility;
  final Observable<DetailVisibility> _midVisibility;
  final Observable<DetailVisibility> _maxVisibility;
  final Observable<bool> _adaptiveEnabled;
  final Observable<int> _adaptiveNodeThreshold;
  final Observable<int> _adaptiveConnectionThreshold;
  final Observable<int> _adaptiveExtremeNodeThreshold;
  final Observable<int> _adaptiveExtremeConnectionThreshold;

  NodeFlowController? _controller;

  late Computed<double> _normalizedZoom;
  late Computed<DetailVisibility> _baseVisibility;
  late Computed<DetailVisibility> _currentVisibility;
  late Computed<bool> _isInteractionActive;
  late Computed<bool> _isViewportPanning;
  late Computed<bool> _isAdaptiveComplexity;
  late Computed<bool> _isAdaptiveExtremeComplexity;

  @override
  String get id => 'lod';

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

  // ═══════════════════════════════════════════════════════════════════════════
  // Enabled State
  // ═══════════════════════════════════════════════════════════════════════════

  /// Whether LOD is enabled.
  ///
  /// When disabled, [currentVisibility] always returns [maxVisibility].
  bool get isEnabled => _enabled.value;

  /// Enables LOD functionality.
  void enable() => runInAction(() => _enabled.value = true);

  /// Disables LOD functionality (always show full detail).
  void disable() => runInAction(() => _enabled.value = false);

  /// Toggles LOD enabled state.
  void toggle() => runInAction(() => _enabled.value = !_enabled.value);

  /// Sets the enabled state.
  void setEnabled(bool enabled) => runInAction(() => _enabled.value = enabled);

  // ═══════════════════════════════════════════════════════════════════════════
  // Thresholds
  // ═══════════════════════════════════════════════════════════════════════════

  /// Normalized zoom threshold for minimal detail.
  ///
  /// When the normalized zoom is below this value, [minVisibility] is applied.
  /// Range: 0.0 to 1.0. Default: 0.03 (3% of zoom range).
  double get minThreshold => _minThreshold.value;

  /// Sets the minimum threshold.
  void setMinThreshold(double value) {
    assert(
      value >= 0.0 && value <= 1.0,
      'minThreshold must be between 0.0 and 1.0',
    );
    assert(
      value <= _midThreshold.value,
      'minThreshold must be <= midThreshold',
    );
    runInAction(() => _minThreshold.value = value);
  }

  /// Normalized zoom threshold for standard detail.
  ///
  /// When the normalized zoom is at or above [minThreshold] but below this value,
  /// [midVisibility] is applied. When at or above this value, [maxVisibility]
  /// is applied.
  /// Range: 0.0 to 1.0. Default: 0.1 (10% of zoom range).
  double get midThreshold => _midThreshold.value;

  /// Sets the mid threshold.
  void setMidThreshold(double value) {
    assert(
      value >= 0.0 && value <= 1.0,
      'midThreshold must be between 0.0 and 1.0',
    );
    assert(
      value >= _minThreshold.value,
      'midThreshold must be >= minThreshold',
    );
    runInAction(() => _midThreshold.value = value);
  }

  /// Sets both thresholds at once.
  void setThresholds({double? minThreshold, double? midThreshold}) {
    final newMin = minThreshold ?? _minThreshold.value;
    final newMid = midThreshold ?? _midThreshold.value;
    assert(
      newMin >= 0.0 && newMin <= 1.0,
      'minThreshold must be between 0.0 and 1.0',
    );
    assert(
      newMid >= 0.0 && newMid <= 1.0,
      'midThreshold must be between 0.0 and 1.0',
    );
    assert(newMin <= newMid, 'minThreshold must be <= midThreshold');
    runInAction(() {
      _minThreshold.value = newMin;
      _midThreshold.value = newMid;
    });
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // Visibility Presets
  // ═══════════════════════════════════════════════════════════════════════════

  /// Visibility configuration applied when normalizedZoom < [minThreshold].
  DetailVisibility get minVisibility => _minVisibility.value;

  /// Sets the visibility for minimum zoom level.
  void setMinVisibility(DetailVisibility visibility) =>
      runInAction(() => _minVisibility.value = visibility);

  /// Visibility configuration applied when
  /// [minThreshold] <= normalizedZoom < [midThreshold].
  DetailVisibility get midVisibility => _midVisibility.value;

  /// Sets the visibility for mid zoom level.
  void setMidVisibility(DetailVisibility visibility) =>
      runInAction(() => _midVisibility.value = visibility);

  /// Visibility configuration applied when normalizedZoom >= [midThreshold].
  DetailVisibility get maxVisibility => _maxVisibility.value;

  /// Sets the visibility for maximum zoom level.
  void setMaxVisibility(DetailVisibility visibility) =>
      runInAction(() => _maxVisibility.value = visibility);

  // ═══════════════════════════════════════════════════════════════════════════
  // Adaptive Fidelity
  // ═══════════════════════════════════════════════════════════════════════════

  /// Whether adaptive interaction fidelity is enabled.
  bool get adaptiveEnabled => _adaptiveEnabled.value;

  /// Enables adaptive interaction fidelity.
  void enableAdaptive() => runInAction(() => _adaptiveEnabled.value = true);

  /// Disables adaptive interaction fidelity.
  void disableAdaptive() => runInAction(() => _adaptiveEnabled.value = false);

  /// Sets adaptive interaction fidelity enabled state.
  void setAdaptiveEnabled(bool enabled) =>
      runInAction(() => _adaptiveEnabled.value = enabled);

  int get adaptiveNodeThreshold => _adaptiveNodeThreshold.value;

  int get adaptiveConnectionThreshold => _adaptiveConnectionThreshold.value;

  int get adaptiveExtremeNodeThreshold => _adaptiveExtremeNodeThreshold.value;

  int get adaptiveExtremeConnectionThreshold =>
      _adaptiveExtremeConnectionThreshold.value;

  /// Sets adaptive complexity thresholds.
  void setAdaptiveThresholds({
    int? nodeThreshold,
    int? connectionThreshold,
    int? extremeNodeThreshold,
    int? extremeConnectionThreshold,
  }) {
    runInAction(() {
      if (nodeThreshold != null) {
        _adaptiveNodeThreshold.value = nodeThreshold;
      }
      if (connectionThreshold != null) {
        _adaptiveConnectionThreshold.value = connectionThreshold;
      }
      if (extremeNodeThreshold != null) {
        _adaptiveExtremeNodeThreshold.value = extremeNodeThreshold;
      }
      if (extremeConnectionThreshold != null) {
        _adaptiveExtremeConnectionThreshold.value = extremeConnectionThreshold;
      }
    });
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // Computed State
  // ═══════════════════════════════════════════════════════════════════════════

  /// The current zoom value normalized to a 0.0-1.0 range.
  ///
  /// - 0.0 = at minZoom (most zoomed out)
  /// - 1.0 = at maxZoom (most zoomed in)
  double get normalizedZoom => _normalizedZoom.value;

  /// The current visibility configuration based on zoom level.
  ///
  /// When [isEnabled] is false, always returns [maxVisibility].
  ///
  /// When enabled, returns one of:
  /// - [minVisibility] when normalizedZoom < minThreshold
  /// - [midVisibility] when minThreshold <= normalizedZoom < midThreshold
  /// - [maxVisibility] when normalizedZoom >= midThreshold
  DetailVisibility get currentVisibility => _currentVisibility.value;

  /// Current zoom-only visibility before adaptive interaction adjustments.
  DetailVisibility get baseVisibility => _baseVisibility.value;

  /// Whether interaction-adaptive mode is currently active.
  bool get isAdaptiveInteractionActive =>
      _adaptiveEnabled.value && _isInteractionActive.value;

  /// Whether to use thumbnail (paint) mode instead of widget mode.
  ///
  /// Returns `true` when:
  /// 1. LOD is enabled and zoom is below minThreshold (very zoomed out), OR
  /// 2. Adaptive mode is enabled and interaction complexity crosses thresholds
  ///
  /// When true, NodesLayer should switch to NodesThumbnailLayer
  /// for maximum performance.
  bool get useThumbnailMode {
    final zoomThumbnailMode =
        _enabled.value && _normalizedZoom.value < _minThreshold.value;

    // Adaptive thumbnail mode is intentionally independent from LOD enabled state.
    // This keeps full-fidelity while idle but allows aggressive downgrades
    // during heavy interaction even when zoom-based LOD is turned off.
    final adaptiveThumbnailMode =
        _adaptiveEnabled.value &&
        _isInteractionActive.value &&
        (_isAdaptiveExtremeComplexity.value ||
            (_isViewportPanning.value && _isAdaptiveComplexity.value));

    return zoomThumbnailMode || adaptiveThumbnailMode;
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // Convenience Accessors
  // ═══════════════════════════════════════════════════════════════════════════

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

  // ═══════════════════════════════════════════════════════════════════════════
  // Private Implementation
  // ═══════════════════════════════════════════════════════════════════════════

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

    _isInteractionActive = Computed(() {
      return controller.draggedNodeId != null ||
          controller.isResizing ||
          controller.isConnecting ||
          controller.isDrawingSelection ||
          controller.canvasLocked ||
          controller.interaction.isViewportDragging;
    });

    _isViewportPanning = Computed(
      () => controller.interaction.isViewportDragging,
    );

    _isAdaptiveComplexity = Computed(() {
      return _createAdaptivePolicy().isComplex(
        nodeCount: controller.nodeCount,
        connectionCount: controller.connectionCount,
      );
    });

    _isAdaptiveExtremeComplexity = Computed(() {
      return _createAdaptivePolicy().isExtreme(
        nodeCount: controller.nodeCount,
        connectionCount: controller.connectionCount,
      );
    });

    _baseVisibility = Computed(() {
      // When disabled, always return max visibility
      if (!_enabled.value) {
        return _maxVisibility.value;
      }

      final normalized = _normalizedZoom.value;
      final minThresh = _minThreshold.value;
      final midThresh = _midThreshold.value;

      if (normalized < minThresh) {
        return _minVisibility.value;
      } else if (normalized < midThresh) {
        return _midVisibility.value;
      } else {
        return _maxVisibility.value;
      }
    });

    _currentVisibility = Computed(() {
      final base = _baseVisibility.value;
      if (!_adaptiveEnabled.value) return base;

      return _createAdaptivePolicy().apply(
        baseVisibility: base,
        isInteracting: _isInteractionActive.value,
        nodeCount: controller.nodeCount,
        connectionCount: controller.connectionCount,
      );
    });
  }

  LodAdaptivePolicy _createAdaptivePolicy() {
    return LodAdaptivePolicy(
      complexityNodeThreshold: _adaptiveNodeThreshold.value,
      complexityConnectionThreshold: _adaptiveConnectionThreshold.value,
      extremeNodeThreshold: _adaptiveExtremeNodeThreshold.value,
      extremeConnectionThreshold: _adaptiveExtremeConnectionThreshold.value,
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// Controller Extension for LOD Access
// ═══════════════════════════════════════════════════════════════════════════

/// Dart extension providing convenient access to LOD functionality.
///
/// This extension adds a [lod] getter to [NodeFlowController] that
/// lazily registers and returns the [LodPlugin]. This pattern keeps
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
extension LodPluginAccess<T> on NodeFlowController<T, dynamic> {
  /// Gets the Level of Detail (LOD) plugin, or null if not configured.
  ///
  /// LOD controls which visual elements are rendered based on zoom level.
  /// Returns null if the plugin is not registered, which effectively
  /// disables LOD functionality (all elements shown at all zoom levels).
  ///
  /// Example:
  /// ```dart
  /// // Configure via NodeFlowConfig
  /// final flowConfig = NodeFlowConfig(
  ///   plugins: [
  ///     LodPlugin(
  ///       enabled: true,
  ///       minThreshold: 0.2,
  ///       midThreshold: 0.5,
  ///     ),
  ///   ],
  /// );
  ///
  /// // Safe access - returns null if not configured
  /// controller.lod?.showPorts; // true, or null if not configured
  /// ```
  LodPlugin? get lod => resolvePlugin<LodPlugin>();
}
