import 'dart:ui';

import '../../editor/controller/node_flow_controller.dart';
import '../../editor/snap_delegate.dart';
import '../events/events.dart';
import '../node_flow_extension.dart';

/// An extension that manages snap behavior through a delegate chain.
///
/// This extension wraps a [SnapDelegateChain] and registers itself as the
/// controller's snap delegate. Delegates are processed in order, with the
/// first delegate to snap an axis "winning" that axis.
///
/// ## Default Setup
///
/// By default, include [GridSnapDelegate] for grid snapping:
///
/// ```dart
/// SnapExtension([
///   GridSnapDelegate(gridSize: 20.0),
/// ])
/// ```
///
/// ## With Alignment Guides
///
/// Add alignment snap delegates with higher priority:
///
/// ```dart
/// SnapExtension([
///   SnapLinesDelegate(),              // Priority 1: alignment guides
///   GridSnapDelegate(gridSize: 20.0), // Priority 2: grid snap fallback
/// ])
/// ```
///
/// ## Accessing Delegates
///
/// Use [gridSnapDelegate] to access the grid snap delegate for toggling:
///
/// ```dart
/// // N key shortcut
/// snapExtension.gridSnapDelegate?.toggle();
/// ```
class SnapExtension extends NodeFlowExtension implements SnapDelegate {
  SnapExtension(List<SnapDelegate> delegates)
      : _chain = SnapDelegateChain(delegates),
        _delegates = delegates;

  final SnapDelegateChain _chain;
  final List<SnapDelegate> _delegates;

  NodeFlowController? _controller;

  /// The delegates in this extension's chain.
  List<SnapDelegate> get delegates => List.unmodifiable(_delegates);

  /// Gets the [GridSnapDelegate] from the chain, if present.
  ///
  /// Useful for toggling grid snap via keyboard shortcuts:
  /// ```dart
  /// snapExtension.gridSnapDelegate?.toggle();
  /// ```
  GridSnapDelegate? get gridSnapDelegate =>
      _delegates
          .whereType<GridSnapDelegate>()
          .firstOrNull;

  // ═══════════════════════════════════════════════════════════════════════════
  // NodeFlowExtension Implementation
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
}

/// Extension to access the snap extension from a controller.
extension SnapExtensionAccess<T> on NodeFlowController<T, dynamic> {
  /// Gets the snap extension, or null if not configured.
  SnapExtension? get snapExtension => resolveExtension<SnapExtension>();
}
