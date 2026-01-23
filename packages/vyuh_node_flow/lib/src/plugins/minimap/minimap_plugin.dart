import 'package:flutter/material.dart';
import 'package:mobx/mobx.dart';

import '../../editor/controller/node_flow_controller.dart';
import '../../graph/coordinates.dart';
import '../../nodes/node.dart';
import '../events/events.dart';
import '../layer_provider.dart';
import '../node_flow_plugin.dart';
import 'minimap_overlay.dart';
import 'minimap_theme.dart';

// Re-export MinimapPosition for convenience
export 'minimap_theme.dart' show MinimapPosition;

/// Builder function for custom minimap node rendering.
///
/// This callback allows applications to customize how nodes appear in the minimap.
/// Return `true` if you handled the painting, `false` to use the node's default
/// [Node.paintMinimapThumbnail] method.
///
/// ## Parameters
/// - [canvas]: The canvas to paint on (already transformed to graph coordinates)
/// - [node]: The node being painted (cast to your data type as needed)
/// - [bounds]: The rectangle to paint within (node position and size in graph coords)
/// - [defaultColor]: The default color from minimap theme
///
/// ## Example
/// ```dart
/// MinimapPlugin(
///   thumbnailBuilder: (canvas, node, bounds, defaultColor) {
///     // Cast node.data to your type
///     final data = node.data as MyNodeData;
///     final color = data.color ?? defaultColor;
///     final paint = Paint()
///       ..style = PaintingStyle.fill
///       ..color = color;
///     canvas.drawRect(bounds, paint);
///     return true; // We handled painting
///   },
/// );
/// ```
typedef MinimapThumbnailBuilder = bool Function(
  Canvas canvas,
  Node<dynamic> node,
  Rect bounds,
  Color defaultColor,
);

/// Minimap plugin for managing minimap state and behavior.
///
/// This plugin provides reactive state for minimap visibility, position,
/// and highlight features. The actual minimap widget consumes this state.
///
/// ## Usage
/// ```dart
/// // Create with visibility enabled
/// MinimapPlugin(visible: true);
///
/// // Configure position and theme
/// MinimapPlugin(
///   visible: true,
///   position: MinimapPosition.topLeft,
///   theme: MinimapTheme.dark,
/// );
///
/// // Toggle visibility at runtime
/// controller.minimap?.toggle();
///
/// // Highlight nodes (e.g., search results)
/// controller.minimap?.highlightNodes({'node-1', 'node-3'});
/// ```
class MinimapPlugin extends NodeFlowPlugin implements LayerProvider {
  /// Creates a minimap plugin.
  ///
  /// Parameters:
  /// - [visible]: Whether the minimap is shown initially (default: false)
  /// - [interactive]: Whether the minimap responds to clicks/drags (default: true)
  /// - [position]: Corner position of the minimap (default: bottomRight)
  /// - [size]: Size of the minimap in pixels (default: 200x150)
  /// - [margin]: Distance from the edge (default: 20.0)
  /// - [autoHighlightSelection]: Auto-highlight selected nodes (default: true)
  /// - [theme]: Visual theme for the minimap (default: MinimapTheme.light)
  /// - [thumbnailBuilder]: Optional custom node painting callback
  MinimapPlugin({
    bool visible = false,
    bool interactive = true,
    MinimapPosition position = MinimapPosition.bottomRight,
    Size size = const Size(200, 150),
    this.margin = 20.0,
    bool autoHighlightSelection = true,
    MinimapTheme theme = MinimapTheme.light,
    this.thumbnailBuilder,
  }) : _theme = theme,
       _size = Observable(size),
       _isVisible = Observable(visible),
       _isInteractive = Observable(interactive),
       _position = Observable(position),
       _autoHighlightSelection = Observable(autoHighlightSelection);

  final MinimapTheme _theme;

  /// Optional custom builder for minimap node painting.
  ///
  /// When provided, this builder is called for each node. Return `true` if
  /// you handled the painting, `false` to fall back to the node's default
  /// [Node.paintMinimapThumbnail] method.
  final MinimapThumbnailBuilder? thumbnailBuilder;

  /// The visual theme for the minimap.
  ///
  /// This theme controls colors, sizes, and visual appearance of the minimap.
  MinimapTheme get theme => _theme;

  /// Margin from the edge of the editor to the minimap.
  final double margin;

  NodeFlowController? _controller;

  // ═══════════════════════════════════════════════════════════════════════════
  // Observable State
  // ═══════════════════════════════════════════════════════════════════════════

  final Observable<Size> _size;
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
  // Size
  // ═══════════════════════════════════════════════════════════════════════════

  /// Current size of the minimap in pixels.
  Size get size => _size.value;

  /// Sets the minimap size.
  void setSize(Size size) => runInAction(() => _size.value = size);

  /// Sets the minimap width, keeping height unchanged.
  void setWidth(double width) =>
      runInAction(() => _size.value = Size(width, _size.value.height));

  /// Sets the minimap height, keeping width unchanged.
  void setHeight(double height) =>
      runInAction(() => _size.value = Size(_size.value.width, height));

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
  // NodeFlowPlugin Implementation
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

  // ═══════════════════════════════════════════════════════════════════════════
  // LayerProvider Implementation
  // ═══════════════════════════════════════════════════════════════════════════

  @override
  LayerPosition get layerPosition => NodeFlowLayer.overlays.before;

  @override
  Widget? buildLayer(BuildContext context) {
    final controller = _controller;
    if (controller == null) return null;

    return MinimapOverlay(controller: controller);
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// Controller Extension
// ═══════════════════════════════════════════════════════════════════════════

/// Dart extension providing access to the minimap plugin.
extension MinimapPluginAccess<T> on NodeFlowController<T, dynamic> {
  /// Gets the minimap plugin, or null if not configured.
  ///
  /// Returns null if the plugin is not registered, which effectively
  /// disables minimap functionality. Use null-aware operators to safely
  /// access minimap features.
  ///
  /// ```dart
  /// // Add plugin
  /// controller.addPlugin(MinimapPlugin(visible: true));
  ///
  /// // Safe access - returns null if not configured
  /// controller.minimap?.toggle();
  /// ```
  MinimapPlugin? get minimap => resolvePlugin<MinimapPlugin>();
}
