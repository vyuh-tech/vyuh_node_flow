import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';

import '../../editor/controller/node_flow_controller.dart';
import '../../graph/viewport.dart';
import '../../nodes/comment_node.dart';
import '../../nodes/group_node.dart';
import '../../nodes/node.dart';
import 'minimap_plugin.dart';
import 'minimap_theme.dart';

/// A minimap widget that provides an overview of the entire node flow graph.
///
/// The minimap shows a bird's-eye view of all nodes in the graph along with
/// a viewport indicator showing the currently visible area. Users can interact
/// with the minimap to navigate the graph by clicking or dragging.
///
/// Features:
/// - Displays all nodes as simplified rectangles
/// - Shows current viewport bounds as a highlighted region
/// - Interactive navigation: click to jump, drag to pan
/// - Customizable appearance via [MinimapTheme]
/// - Reactive updates via MobX when graph changes
///
/// Example:
/// ```dart
/// NodeFlowMinimap<MyData>(
///   controller: controller,
///   theme: MinimapTheme.light.copyWith(
///     nodeColor: Colors.blue,
///   ),
///   interactive: true,
/// )
/// ```
///
/// The minimap is typically placed in a corner of the editor as an overlay.
/// See [MinimapOverlay] for automatic positioning.
class NodeFlowMinimap<T> extends StatefulWidget {
  const NodeFlowMinimap({
    super.key,
    required this.controller,
    required this.size,
    this.theme = MinimapTheme.light,
    this.interactive = true,
    this.thumbnailBuilder,
  });

  /// The controller managing the node flow graph.
  ///
  /// The minimap observes this controller to reactively update when nodes,
  /// connections, or viewport change.
  final NodeFlowController<T, dynamic> controller;

  /// Size of the minimap in pixels.
  ///
  /// This is required and can be updated reactively via the extension.
  /// Use [controller.minimap.size] when using [MinimapExtension].
  final Size size;

  /// Theme configuration for the minimap appearance.
  ///
  /// Controls colors, border radius, padding, and viewport indicator.
  /// Note: Size is configured via [MinimapConfig], not theme.
  final MinimapTheme theme;

  /// Whether the minimap responds to user interaction.
  ///
  /// When true, users can click to jump to a location or drag to pan the
  /// viewport. When false, the minimap is display-only. Defaults to true.
  final bool interactive;

  /// Optional custom builder for minimap node painting.
  ///
  /// When provided, this builder is called for each node. Return `true` if
  /// you handled the painting, `false` to fall back to the node's default
  /// [Node.paintMinimapThumbnail] method.
  final MinimapThumbnailBuilder? thumbnailBuilder;

  @override
  State<NodeFlowMinimap<T>> createState() => _NodeFlowMinimapState<T>();
}

class _NodeFlowMinimapState<T> extends State<NodeFlowMinimap<T>> {
  bool _isDragging = false;

  @override
  Widget build(BuildContext context) {
    final minimapTheme = widget.theme;

    return Container(
      width: widget.size.width,
      height: widget.size.height,
      decoration: BoxDecoration(
        color: minimapTheme.backgroundColor,
        borderRadius: BorderRadius.circular(minimapTheme.borderRadius),
        border: Border.all(
          color: minimapTheme.borderColor,
          width: minimapTheme.borderWidth,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(minimapTheme.borderRadius),
        child: Padding(
          padding: minimapTheme.padding,
          child: Stack(
            children: [
              // The graph overview is isolated from viewport updates. The
              // painter constructor snapshots and sorts node geometry while
              // this Observer is tracking graph/style observables.
              Observer(
                builder: (context) {
                  return RepaintBoundary(
                    child: CustomPaint(
                      key: const ValueKey('minimap-graph'),
                      painter: MinimapPainter<T>(
                        controller: widget.controller,
                        theme: minimapTheme,
                        thumbnailBuilder: widget.thumbnailBuilder,
                      ),
                      size: Size.infinite,
                    ),
                  );
                },
              ),
              if (minimapTheme.showViewport)
                Observer(
                  builder: (context) {
                    final screenSize = widget.controller.screenSize;
                    final graphBounds = widget.controller.nodesBounds;
                    return ValueListenableBuilder<GraphViewport>(
                      valueListenable:
                          widget.controller.cameraViewportListenable,
                      builder: (context, viewport, child) {
                        return RepaintBoundary(
                          child: CustomPaint(
                            key: const ValueKey('minimap-viewport'),
                            painter: MinimapViewportPainter(
                              viewport: viewport,
                              screenSize: screenSize,
                              graphBounds: graphBounds,
                              theme: minimapTheme,
                            ),
                            size: Size.infinite,
                          ),
                        );
                      },
                    );
                  },
                ),
              // Interactive overlay
              if (widget.interactive) _buildInteractiveArea(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInteractiveArea() {
    return Positioned.fill(
      child: MouseRegion(
        cursor: _isDragging
            ? SystemMouseCursors.grabbing
            : SystemMouseCursors.grab,
        child: GestureDetector(
          onTapUp: (details) => _handleTap(details.localPosition),
          onPanStart: (details) => _handlePanStart(details.localPosition),
          onPanUpdate: (details) => _handlePanUpdate(details.localPosition),
          onPanEnd: (_) => _handlePanEnd(),
          child: Container(
            color: Colors.transparent,
            width: double.infinity,
            height: double.infinity,
          ),
        ),
      ),
    );
  }

  void _handleTap(Offset localPosition) {
    if (!widget.interactive) return;

    final graphPosition = _localToGraph(localPosition);
    widget.controller.panToPosition(graphPosition);
  }

  void _handlePanStart(Offset localPosition) {
    if (!widget.interactive) return;

    // Immediately snap viewport to cursor position
    _snapViewportToCursor(localPosition);

    setState(() {
      _isDragging = true;
    });
  }

  void _handlePanUpdate(Offset localPosition) {
    if (!widget.interactive || !_isDragging) return;

    // Snap viewport to follow cursor position continuously
    _snapViewportToCursor(localPosition);
  }

  void _snapViewportToCursor(Offset localPosition) {
    final bounds = widget.controller.nodesBounds;
    if (bounds.isEmpty) return;

    final theme = widget.theme;
    final availableSize = Size(
      widget.size.width - theme.padding.horizontal,
      widget.size.height - theme.padding.vertical,
    );

    // Calculate scale to fit bounds in minimap
    final scaleX = availableSize.width / bounds.width;
    final scaleY = availableSize.height / bounds.height;
    final scale = math.min(scaleX, scaleY);

    // Center offset for scaled content
    final scaledWidth = bounds.width * scale;
    final scaledHeight = bounds.height * scale;
    final offsetX = (availableSize.width - scaledWidth) / 2;
    final offsetY = (availableSize.height - scaledHeight) / 2;

    // Account for padding
    final adjustedPosition = Offset(
      localPosition.dx - theme.padding.left,
      localPosition.dy - theme.padding.top,
    );

    // Convert cursor position to graph coordinates
    final graphX = (adjustedPosition.dx - offsetX) / scale + bounds.left;
    final graphY = (adjustedPosition.dy - offsetY) / scale + bounds.top;

    // Center the viewport on this graph position
    final screenSize = widget.controller.screenSize;
    if (screenSize == Size.zero) return;

    final currentVp = widget.controller.viewport;
    final centerOffset = Offset(screenSize.width / 2, screenSize.height / 2);

    final newVp = currentVp.copyWith(
      x: centerOffset.dx - graphX * currentVp.zoom,
      y: centerOffset.dy - graphY * currentVp.zoom,
    );

    widget.controller.setViewport(newVp);
  }

  void _handlePanEnd() {
    setState(() {
      _isDragging = false;
    });
  }

  Offset _localToGraph(Offset localPosition) {
    final bounds = widget.controller.nodesBounds;
    if (bounds.isEmpty) return Offset.zero;

    final theme = widget.theme;
    // Account for padding
    final adjustedPosition = Offset(
      localPosition.dx - theme.padding.left,
      localPosition.dy - theme.padding.top,
    );

    final availableSize = Size(
      widget.size.width - theme.padding.horizontal,
      widget.size.height - theme.padding.vertical,
    );

    // Calculate scale to fit bounds in minimap
    final scaleX = availableSize.width / bounds.width;
    final scaleY = availableSize.height / bounds.height;
    final scale = math.min(scaleX, scaleY);

    // Center the content if one dimension is smaller
    final scaledWidth = bounds.width * scale;
    final scaledHeight = bounds.height * scale;
    final offsetX = (availableSize.width - scaledWidth) / 2;
    final offsetY = (availableSize.height - scaledHeight) / 2;

    // Convert local position to graph coordinates
    final graphX = (adjustedPosition.dx - offsetX) / scale + bounds.left;
    final graphY = (adjustedPosition.dy - offsetY) / scale + bounds.top;

    return Offset(graphX, graphY);
  }
}

/// Custom painter for rendering the minimap visualization.
///
/// Paints a scaled-down representation of the entire graph, showing:
/// - All nodes as simplified rectangles
///
/// The painter automatically scales and centers the graph to fit within
/// the minimap bounds while maintaining aspect ratio. The viewport indicator
/// is rendered independently by [MinimapViewportPainter].
class MinimapPainter<T> extends CustomPainter {
  factory MinimapPainter({
    required NodeFlowController<T, dynamic> controller,
    required MinimapTheme theme,
    MinimapThumbnailBuilder? thumbnailBuilder,
  }) {
    final nodes = <_MinimapNodeSnapshot<T>>[];
    for (final node in controller.nodes.values) {
      final position = node.position.value;
      final size = node.size.value;
      nodes.add(
        _MinimapNodeSnapshot(
          node: node,
          bounds: Rect.fromLTWH(
            position.dx,
            position.dy,
            size.width,
            size.height,
          ),
          styleToken: _nodeStyleToken(node),
        ),
      );
    }

    // Preserve the established background -> middle -> foreground ordering,
    // but do the work only when graph/style observables invalidate the graph
    // Observer rather than during every paint.
    nodes.sort((a, b) => a.node.layer.index.compareTo(b.node.layer.index));
    final graphBounds = controller.nodesBounds;
    final graphRevision = Object.hashAll([
      graphBounds,
      for (final snapshot in nodes)
        Object.hash(
          snapshot.node.id,
          snapshot.node.runtimeType,
          snapshot.node.layer,
          snapshot.bounds,
          snapshot.styleToken,
        ),
    ]);

    return MinimapPainter._(
      controller: controller,
      theme: theme,
      thumbnailBuilder: thumbnailBuilder,
      nodes: List.unmodifiable(nodes),
      graphBounds: graphBounds,
      graphRevision: graphRevision,
    );
  }

  const MinimapPainter._({
    required this.controller,
    required this.theme,
    required this.thumbnailBuilder,
    required List<_MinimapNodeSnapshot<T>> nodes,
    required Rect graphBounds,
    required int graphRevision,
  }) : _nodes = nodes,
       _graphBounds = graphBounds,
       _graphRevision = graphRevision;

  /// The controller providing access to graph data.
  final NodeFlowController<T, dynamic> controller;

  /// Theme configuration for minimap appearance.
  final MinimapTheme theme;

  /// Optional custom builder for minimap node painting.
  final MinimapThumbnailBuilder? thumbnailBuilder;

  /// Immutable, layer-sorted geometry captured when the graph Observer ran.
  final List<_MinimapNodeSnapshot<T>> _nodes;

  /// Cached graph bounds captured with [_nodes].
  final Rect _graphBounds;

  /// Fingerprint of geometry, layer, and built-in thumbnail style state.
  final int _graphRevision;

  @override
  void paint(Canvas canvas, Size size) {
    final transform = _MinimapTransform.calculate(size, _graphBounds);
    if (transform == null) return;

    canvas.save();
    transform.applyTo(canvas);

    // Draw nodes only (no connections for performance)
    _drawNodes(canvas);
    canvas.restore();
  }

  void _drawNodes(Canvas canvas) {
    for (final snapshot in _nodes) {
      final node = snapshot.node;
      final rect = snapshot.bounds;

      // Try custom thumbnail builder first
      if (thumbnailBuilder != null) {
        final handled = thumbnailBuilder!(canvas, node, rect, theme.nodeColor);
        if (handled) continue;
      }

      // Fall back to node's paintMinimapThumbnail
      node.paintMinimapThumbnail(
        canvas,
        rect,
        defaultColor: theme.nodeColor,
        borderRadius: theme.nodeBorderRadius,
      );
    }
  }

  @override
  bool shouldRepaint(covariant MinimapPainter<T> oldDelegate) {
    return oldDelegate.controller != controller ||
        oldDelegate.theme != theme ||
        oldDelegate.thumbnailBuilder != thumbnailBuilder ||
        oldDelegate._graphRevision != _graphRevision;
  }
}

/// Cheap viewport-only minimap overlay.
///
/// This painter deliberately owns no node list, sorting, or graph traversal so
/// pan and zoom frames only transform and draw a single rounded rectangle.
class MinimapViewportPainter extends CustomPainter {
  const MinimapViewportPainter({
    required this.viewport,
    required this.screenSize,
    required this.graphBounds,
    required this.theme,
  });

  final GraphViewport viewport;
  final Size screenSize;
  final Rect graphBounds;
  final MinimapTheme theme;

  @override
  void paint(Canvas canvas, Size size) {
    if (!theme.showViewport || screenSize.isEmpty) return;

    final transform = _MinimapTransform.calculate(size, graphBounds);
    if (transform == null) return;

    final viewportRect = Rect.fromLTWH(
      -viewport.x / viewport.zoom,
      -viewport.y / viewport.zoom,
      screenSize.width / viewport.zoom,
      screenSize.height / viewport.zoom,
    );
    final clippedRect = transform
        .graphToLocal(viewportRect)
        .intersect(Offset.zero & size);
    if (clippedRect.isEmpty) return;

    final fillPaint = Paint()
      ..color = theme.viewportColor.withValues(alpha: theme.viewportFillOpacity)
      ..style = PaintingStyle.fill;
    final borderPaint = Paint()
      ..color = theme.viewportColor.withValues(
        alpha: theme.viewportBorderOpacity,
      )
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;
    final viewportRRect = RRect.fromRectAndRadius(
      clippedRect,
      Radius.circular(theme.borderRadius),
    );

    canvas.drawRRect(viewportRRect, fillPaint);
    canvas.drawRRect(viewportRRect, borderPaint);
  }

  @override
  bool shouldRepaint(covariant MinimapViewportPainter oldDelegate) {
    return oldDelegate.viewport != viewport ||
        oldDelegate.screenSize != screenSize ||
        oldDelegate.graphBounds != graphBounds ||
        oldDelegate.theme != theme;
  }
}

class _MinimapNodeSnapshot<T> {
  const _MinimapNodeSnapshot({
    required this.node,
    required this.bounds,
    required this.styleToken,
  });

  final Node<T> node;
  final Rect bounds;
  final Object styleToken;
}

Object _nodeStyleToken<T>(Node<T> node) {
  final commonState = Object.hash(
    node.isVisible,
    node.selected.value,
    node.theme,
  );

  return switch (node) {
    GroupNode<T> group => Object.hash(
      commonState,
      group.currentColor,
      group.currentTitle,
      group.behavior,
    ),
    CommentNode<T> comment => Object.hash(
      commonState,
      comment.color,
      comment.text,
    ),
    _ => commonState,
  };
}

class _MinimapTransform {
  const _MinimapTransform({
    required this.graphBounds,
    required this.scale,
    required this.offset,
  });

  final Rect graphBounds;
  final double scale;
  final Offset offset;

  static _MinimapTransform? calculate(Size size, Rect graphBounds) {
    if (size.isEmpty || graphBounds.isEmpty) return null;

    final scale = math.min(
      size.width / graphBounds.width,
      size.height / graphBounds.height,
    );
    final scaledSize = Size(
      graphBounds.width * scale,
      graphBounds.height * scale,
    );
    return _MinimapTransform(
      graphBounds: graphBounds,
      scale: scale,
      offset: Offset(
        (size.width - scaledSize.width) / 2,
        (size.height - scaledSize.height) / 2,
      ),
    );
  }

  void applyTo(Canvas canvas) {
    canvas
      ..translate(offset.dx, offset.dy)
      ..scale(scale)
      ..translate(-graphBounds.left, -graphBounds.top);
  }

  Rect graphToLocal(Rect graphRect) {
    return Rect.fromLTWH(
      offset.dx + (graphRect.left - graphBounds.left) * scale,
      offset.dy + (graphRect.top - graphBounds.top) * scale,
      graphRect.width * scale,
      graphRect.height * scale,
    );
  }
}

/// Extension adding minimap navigation functionality to [NodeFlowController].
///
/// Provides methods for panning the viewport to specific graph positions,
/// used by the minimap for click-to-navigate and drag-to-pan interactions.
extension MinimapControllerExtension<T> on NodeFlowController<T, dynamic> {
  /// Pans the viewport to center on the specified graph position.
  ///
  /// Maintains the current zoom level while adjusting pan offset to center
  /// the given position in the viewport. Used when clicking on the minimap
  /// to jump to a location.
  ///
  /// Parameters:
  /// - [graphPosition]: The position in graph coordinates to center on
  ///
  /// Example:
  /// ```dart
  /// // Center viewport on graph position (100, 100)
  /// controller.panToPosition(Offset(100, 100));
  /// ```
  void panToPosition(Offset graphPosition) {
    final screenSize = this.screenSize;
    if (screenSize == Size.zero) return;

    final centerOffset = Offset(screenSize.width / 2, screenSize.height / 2);

    final currentZoom = viewport.zoom;
    final newPan = Offset(
      centerOffset.dx - graphPosition.dx * currentZoom,
      centerOffset.dy - graphPosition.dy * currentZoom,
    );

    setViewport(viewport.copyWith(x: newPan.dx, y: newPan.dy));
  }
}
