import 'package:flutter/widgets.dart';
import 'package:mobx/mobx.dart';

import '../../editor/controller/node_flow_controller.dart';
import '../../editor/snap_delegate.dart';
import '../events/events.dart';
import '../layer_provider.dart';
import '../node_flow_plugin.dart';

/// A plugin that manages snap behavior through a delegate chain.
///
/// This plugin wraps a [SnapDelegateChain] and registers itself as the
/// controller's snap delegate. Delegates are processed in order, with the
/// first delegate to snap an axis "winning" that axis.
///
/// ## Master Enable Switch
///
/// The plugin has an [enabled] property that acts as a master switch for
/// all snapping. When disabled (the default), no snapping occurs. Toggle with
/// the 'N' key or programmatically:
///
/// ```dart
/// snapPlugin.toggle();  // Toggle with N key
/// snapPlugin.enabled = true;  // Enable programmatically
/// ```
///
/// ## Default Setup
///
/// By default, include [GridSnapDelegate] for grid snapping:
///
/// ```dart
/// SnapPlugin([
///   GridSnapDelegate(gridSize: 20.0),
/// ])
/// ```
///
/// ## With Alignment Guides
///
/// Add alignment snap delegates with higher priority:
///
/// ```dart
/// SnapPlugin([
///   SnapLinesDelegate(),              // Priority 1: alignment guides
///   GridSnapDelegate(gridSize: 20.0), // Priority 2: grid snap fallback
/// ])
/// ```
class SnapPlugin extends NodeFlowPlugin implements SnapDelegate, LayerProvider {
  SnapPlugin(List<SnapDelegate> delegates, {bool enabled = false})
    : _chain = SnapDelegateChain(delegates),
      _delegates = delegates,
      _enabled = Observable(enabled);

  final SnapDelegateChain _chain;
  final List<SnapDelegate> _delegates;
  final Observable<bool> _enabled;

  NodeFlowController? _controller;

  /// Whether snapping is enabled globally.
  ///
  /// When false, all snapping (grid snap, alignment guides, etc.) is disabled.
  /// Toggle with the 'N' key or programmatically.
  bool get enabled => _enabled.value;

  set enabled(bool value) => runInAction(() => _enabled.value = value);

  /// Toggles the enabled state.
  ///
  /// Convenience method for keyboard shortcuts and UI controls.
  void toggle() => runInAction(() => _enabled.value = !_enabled.value);

  /// The delegates in this plugin's chain.
  List<SnapDelegate> get delegates => List.unmodifiable(_delegates);

  /// Gets the [GridSnapDelegate] from the chain, if present.
  ///
  /// Useful for accessing grid snap settings:
  /// ```dart
  /// snapPlugin.gridSnapDelegate?.gridSize = 10.0;
  /// snapPlugin.gridSnapDelegate?.snapPoint(position);
  /// ```
  GridSnapDelegate? get gridSnapDelegate =>
      _delegates.whereType<GridSnapDelegate>().firstOrNull;

  /// Gets the first [SnapLayerDelegate] from the delegate chain, if any.
  SnapLayerDelegate? get _snapLayerDelegate =>
      _delegates.whereType<SnapLayerDelegate>().firstOrNull;

  // ═══════════════════════════════════════════════════════════════════════════
  // NodeFlowPlugin Implementation
  // ═══════════════════════════════════════════════════════════════════════════

  @override
  String get id => 'snap';

  @override
  void attach(NodeFlowController controller) {
    _controller = controller;
    controller.setSnapDelegate(this);

    // Notify controller-aware delegates
    for (final delegate in _delegates) {
      if (delegate case final ControllerAwareDelegate aware) {
        aware.setController(controller);
      }
    }
  }

  @override
  void detach() {
    // Clear controller reference from aware delegates
    for (final delegate in _delegates) {
      if (delegate case final ControllerAwareDelegate aware) {
        aware.setController(null);
      }
    }

    _controller?.setSnapDelegate(null);
    _controller = null;
  }

  @override
  void onEvent(GraphEvent event) {
    // Snap events are handled through SnapDelegate interface
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // SnapDelegate Implementation (forwards to chain)
  // ═══════════════════════════════════════════════════════════════════════════

  @override
  void onDragStart(Set<String> nodeIds) {
    _chain.onDragStart(nodeIds);
  }

  @override
  SnapResult snapPosition({
    required Set<String> draggedNodeIds,
    required Offset intendedPosition,
    required Rect visibleBounds,
  }) {
    // Return no snapping if plugin is disabled
    if (!_enabled.value) {
      return SnapResult.none(intendedPosition);
    }

    return _chain.snapPosition(
      draggedNodeIds: draggedNodeIds,
      intendedPosition: intendedPosition,
      visibleBounds: visibleBounds,
    );
  }

  @override
  void onDragEnd() {
    _chain.onDragEnd();
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // LayerProvider Implementation (delegates to SnapLayerDelegate)
  // ═══════════════════════════════════════════════════════════════════════════

  @override
  LayerPosition get layerPosition => NodeFlowLayer.foregroundNodes.after;

  @override
  Widget? buildLayer(BuildContext context) {
    // Delegate to the first SnapLayerDelegate in the chain
    return _snapLayerDelegate?.buildSnapLayer(context);
  }
}

/// Extension to access the snap plugin from a controller.
extension SnapPluginAccess<T> on NodeFlowController<T, dynamic> {
  /// Gets the snap plugin, or null if not configured.
  SnapPlugin? get snap => resolvePlugin<SnapPlugin>();
}
