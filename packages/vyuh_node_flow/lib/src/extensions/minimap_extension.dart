import 'package:flutter/material.dart';
import 'package:mobx/mobx.dart';

import '../editor/controller/node_flow_controller.dart';
import '../editor/themes/minimap_theme.dart' show MinimapPosition;
import '../graph/coordinates.dart';
import 'events/events.dart';
import 'node_flow_extension.dart';

// Re-export MinimapPosition for convenience
export '../editor/themes/minimap_theme.dart' show MinimapPosition;

/// Configuration for the minimap extension.
///
/// Use this to set initial state when creating the extension:
/// ```dart
/// MinimapExtension(config: MinimapConfig(
///   visible: false,
///   position: MinimapPosition.topLeft,
/// ));
/// ```
class MinimapConfig {
  /// Creates a minimap configuration.
  const MinimapConfig({
    this.visible = false,
    this.interactive = true,
    this.position = MinimapPosition.bottomRight,
    this.autoHighlightSelection = true,
  });

  /// Initial visibility of the minimap.
  final bool visible;

  /// Whether the minimap can be interacted with (panning, clicking).
  final bool interactive;

  /// Initial position/corner of the minimap.
  final MinimapPosition position;

  /// Whether to automatically highlight selected nodes in the minimap.
  final bool autoHighlightSelection;

  /// Default configuration with minimap visible in bottom-right.
  static const defaultConfig = MinimapConfig();

  /// Configuration with minimap hidden by default.
  static const hidden = MinimapConfig(visible: false);

  /// Configuration with minimap visible but non-interactive.
  static const readOnly = MinimapConfig(interactive: false);
}

/// Minimap extension for managing minimap state and behavior.
///
/// This extension provides reactive state for minimap visibility, position,
/// and highlight features. The actual minimap widget consumes this state.
///
/// ## Usage
/// ```dart
/// // Toggle visibility
/// controller.minimap.toggle();
///
/// // Highlight nodes (e.g., search results)
/// controller.minimap.highlightNodes({'node-1', 'node-3'});
///
/// // Change position
/// controller.minimap.setPosition(MinimapPosition.topRight);
///
/// // In widget - reactive to extension state
/// Observer(builder: (_) {
///   if (!controller.minimap.isVisible) return const SizedBox.shrink();
///   return NodeFlowMinimap(controller: controller);
/// });
/// ```
class MinimapExtension extends NodeFlowExtension<MinimapConfig> {
  /// Creates a minimap extension with optional configuration.
  MinimapExtension({MinimapConfig config = const MinimapConfig()})
    : _config = config,
      _isVisible = Observable(config.visible),
      _isInteractive = Observable(config.interactive),
      _position = Observable(config.position),
      _autoHighlightSelection = Observable(config.autoHighlightSelection);

  final MinimapConfig _config;

  @override
  MinimapConfig get config => _config;

  NodeFlowController? _controller;

  // ═══════════════════════════════════════════════════════════════════════════
  // Observable State
  // ═══════════════════════════════════════════════════════════════════════════

  final Observable<bool> _isVisible;
  final Observable<bool> _isInteractive;
  final Observable<MinimapPosition> _position;
  final Observable<Rect?> _highlightRegion = Observable(null);
  final Observable<Set<String>> _highlightedNodeIds = Observable({});
  final Observable<bool> _autoHighlightSelection;

  // ═══════════════════════════════════════════════════════════════════════════
  // Visibility
  // ═══════════════════════════════════════════════════════════════════════════

  /// Whether the minimap is currently visible.
  bool get isVisible => _isVisible.value;

  /// Shows the minimap.
  void show() => runInAction(() => _isVisible.value = true);

  /// Hides the minimap.
  void hide() => runInAction(() => _isVisible.value = false);

  /// Toggles minimap visibility.
  void toggle() => runInAction(() => _isVisible.value = !_isVisible.value);

  /// Sets minimap visibility.
  void setVisible(bool visible) =>
      runInAction(() => _isVisible.value = visible);

  // ═══════════════════════════════════════════════════════════════════════════
  // Interactivity
  // ═══════════════════════════════════════════════════════════════════════════

  /// Whether the minimap can be interacted with.
  bool get isInteractive => _isInteractive.value;

  /// Enables minimap interaction.
  void enableInteraction() => runInAction(() => _isInteractive.value = true);

  /// Disables minimap interaction.
  void disableInteraction() => runInAction(() => _isInteractive.value = false);

  /// Toggles minimap interaction.
  void toggleInteraction() =>
      runInAction(() => _isInteractive.value = !_isInteractive.value);

  /// Sets minimap interaction state.
  void setInteractive(bool interactive) =>
      runInAction(() => _isInteractive.value = interactive);

  // ═══════════════════════════════════════════════════════════════════════════
  // Position
  // ═══════════════════════════════════════════════════════════════════════════

  /// Current position/corner of the minimap.
  MinimapPosition get position => _position.value;

  /// Sets the minimap position.
  void setPosition(MinimapPosition pos) =>
      runInAction(() => _position.value = pos);

  /// Cycles to the next position (clockwise).
  void cyclePosition() {
    runInAction(() {
      final positions = MinimapPosition.values;
      final currentIndex = positions.indexOf(_position.value);
      final nextIndex = (currentIndex + 1) % positions.length;
      _position.value = positions[nextIndex];
    });
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // Highlighting
  // ═══════════════════════════════════════════════════════════════════════════

  /// Node IDs to highlight in the minimap.
  Set<String> get highlightedNodeIds => _highlightedNodeIds.value;

  /// Optional region to highlight (e.g., search results area).
  Rect? get highlightRegion => _highlightRegion.value;

  /// Whether to auto-highlight selected nodes.
  bool get autoHighlightSelection => _autoHighlightSelection.value;

  /// Sets whether to auto-highlight selected nodes in the minimap.
  void setAutoHighlightSelection(bool value) =>
      runInAction(() => _autoHighlightSelection.value = value);

  /// Highlights specific nodes in the minimap.
  void highlightNodes(Set<String> nodeIds) =>
      runInAction(() => _highlightedNodeIds.value = Set.from(nodeIds));

  /// Highlights a rectangular region in the minimap.
  void highlightArea(Rect region) =>
      runInAction(() => _highlightRegion.value = region);

  /// Clears all highlights.
  void clearHighlights() {
    runInAction(() {
      _highlightRegion.value = null;
      _highlightedNodeIds.value = {};
    });
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // Navigation
  // ═══════════════════════════════════════════════════════════════════════════

  /// Centers the main viewport on the given graph position.
  void centerOn(Offset graphPosition) {
    _controller?.centerOn(GraphOffset(graphPosition));
  }

  /// Pans to show the specified nodes.
  void focusNodes(Set<String> nodeIds) {
    if (_controller == null || nodeIds.isEmpty) return;

    // Calculate bounds of the nodes
    Rect? bounds;
    for (final id in nodeIds) {
      final node = _controller!.getNode(id);
      if (node != null) {
        final nodeRect = Rect.fromLTWH(
          node.position.value.dx,
          node.position.value.dy,
          node.size.value.width,
          node.size.value.height,
        );
        bounds = bounds?.expandToInclude(nodeRect) ?? nodeRect;
      }
    }

    if (bounds != null) {
      centerOn(bounds.center);
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // NodeFlowExtension Implementation
  // ═══════════════════════════════════════════════════════════════════════════

  @override
  String get id => 'minimap';

  @override
  void attach(NodeFlowController controller) {
    _controller = controller;
  }

  @override
  void detach() {
    _controller = null;
  }

  @override
  void onEvent(GraphEvent event) {
    // Auto-highlight selected nodes if enabled
    if (_autoHighlightSelection.value) {
      switch (event) {
        case SelectionChanged(:final selectedNodeIds):
          if (selectedNodeIds.isNotEmpty) {
            highlightNodes(selectedNodeIds);
          } else {
            clearHighlights();
          }
        default:
          break;
      }
    }
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// Controller Extension
// ═══════════════════════════════════════════════════════════════════════════

/// Dart extension providing access to the minimap extension.
extension MinimapExtensionAccess<T> on NodeFlowController<T> {
  /// Gets the minimap extension.
  ///
  /// The extension must be registered in [NodeFlowConfig.extensions].
  /// Throws [AssertionError] if not found.
  ///
  /// ```dart
  /// // Configure via NodeFlowConfig
  /// final flowConfig = NodeFlowConfig(
  ///   extensions: [
  ///     MinimapExtension(config: MinimapConfig(visible: false)),
  ///   ],
  /// );
  ///
  /// // Later access uses the configured extension
  /// controller.minimap.isVisible; // false
  /// ```
  MinimapExtension get minimap {
    var ext = getExtension<MinimapExtension>();
    if (ext == null) {
      ext = config.extensionRegistry.get<MinimapExtension>();
      assert(
        ext != null,
        'MinimapExtension not found. Add it to NodeFlowConfig.extensions.',
      );
      addExtension(ext!);
    }
    return ext;
  }
}
