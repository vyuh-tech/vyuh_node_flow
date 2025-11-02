import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';

import '../graph/node_flow_controller.dart';

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
/// - Customizable appearance (colors, size, border radius)
/// - Reactive updates via MobX when graph changes
///
/// Example:
/// ```dart
/// NodeFlowMinimap<MyData>(
///   controller: controller,
///   size: Size(200, 150),
///   backgroundColor: Colors.white,
///   nodeColor: Colors.blue,
///   viewportColor: Colors.green,
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
    this.size = const Size(200, 150),
    this.backgroundColor,
    this.nodeColor,
    this.viewportColor,
    this.borderRadius = 4.0,
    this.padding = const EdgeInsets.all(4.0),
    this.showViewport = true,
    this.interactive = true,
  });

  /// The controller managing the node flow graph.
  ///
  /// The minimap observes this controller to reactively update when nodes,
  /// connections, or viewport change.
  final NodeFlowController<T> controller;

  /// The size of the minimap widget in pixels.
  ///
  /// Defaults to 200x150. Larger sizes provide more detail but take more
  /// screen space.
  final Size size;

  /// Background color of the minimap.
  ///
  /// If null, uses the theme's surface color.
  final Color? backgroundColor;

  /// Color used to draw nodes in the minimap.
  ///
  /// If null, uses the theme's primary color. Nodes are drawn as small
  /// filled rectangles.
  final Color? nodeColor;

  /// Color used for the viewport indicator.
  ///
  /// If null, uses the theme's primary color. The viewport is drawn as a
  /// semi-transparent rectangle with a border.
  final Color? viewportColor;

  /// Border radius for the minimap widget corners.
  ///
  /// Defaults to 4.0. Applied to both the minimap container and viewport
  /// indicator for visual consistency.
  final double borderRadius;

  /// Internal padding between minimap edge and content.
  ///
  /// Defaults to EdgeInsets.all(4.0). Provides spacing between the border
  /// and the graph visualization.
  final EdgeInsets padding;

  /// Whether to show the viewport indicator rectangle.
  ///
  /// When true, displays a highlighted region showing the currently visible
  /// portion of the graph. Defaults to true.
  final bool showViewport;

  /// Whether the minimap responds to user interaction.
  ///
  /// When true, users can click to jump to a location or drag to pan the
  /// viewport. When false, the minimap is display-only. Defaults to true.
  final bool interactive;

  @override
  State<NodeFlowMinimap<T>> createState() => _NodeFlowMinimapState<T>();
}

class _NodeFlowMinimapState<T> extends State<NodeFlowMinimap<T>> {
  bool _isDragging = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      width: widget.size.width,
      height: widget.size.height,
      decoration: BoxDecoration(
        color: widget.backgroundColor ?? theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(widget.borderRadius),
        border: Border.all(color: theme.colorScheme.outline, width: 1.0),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(widget.borderRadius),
        child: Padding(
          padding: widget.padding,
          child: Stack(
            children: [
              // Minimap rendering with Observer for reactive updates
              Observer(
                builder: (context) {
                  // Access observable properties to trigger rebuilds
                  // These variables are accessed to ensure MobX tracks them for reactivity
                  widget.controller.viewport;
                  widget.controller.nodes;
                  widget.controller.connections;

                  return CustomPaint(
                    painter: MinimapPainter<T>(
                      controller: widget.controller,
                      nodeColor: widget.nodeColor ?? theme.colorScheme.primary,
                      viewportColor:
                          widget.viewportColor ?? theme.colorScheme.primary,
                      borderRadius: widget.borderRadius,
                      showViewport: widget.showViewport,
                    ),
                    size: Size.infinite,
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

    final availableSize = Size(
      widget.size.width - widget.padding.horizontal,
      widget.size.height - widget.padding.vertical,
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
      localPosition.dx - widget.padding.left,
      localPosition.dy - widget.padding.top,
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

    // Account for padding
    final adjustedPosition = Offset(
      localPosition.dx - widget.padding.left,
      localPosition.dy - widget.padding.top,
    );

    final availableSize = Size(
      widget.size.width - widget.padding.horizontal,
      widget.size.height - widget.padding.vertical,
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
/// - Current viewport as a highlighted region
///
/// The painter automatically scales and centers the graph to fit within
/// the minimap bounds while maintaining aspect ratio.
class MinimapPainter<T> extends CustomPainter {
  const MinimapPainter({
    required this.controller,
    required this.nodeColor,
    required this.viewportColor,
    required this.borderRadius,
    this.showViewport = true,
  });

  /// The controller providing access to graph data.
  final NodeFlowController<T> controller;

  /// Color to use when drawing node rectangles.
  final Color nodeColor;

  /// Color to use when drawing the viewport indicator.
  final Color viewportColor;

  /// Border radius for the viewport indicator rectangle.
  final double borderRadius;

  /// Whether to render the viewport indicator.
  final bool showViewport;

  @override
  void paint(Canvas canvas, Size size) {
    final bounds = controller.nodesBounds;
    if (bounds.isEmpty) return;

    // Calculate scale to fit bounds in minimap
    final scaleX = size.width / bounds.width;
    final scaleY = size.height / bounds.height;
    final scale = math.min(scaleX, scaleY);

    // Center the content if one dimension is smaller
    final scaledWidth = bounds.width * scale;
    final scaledHeight = bounds.height * scale;
    final offsetX = (size.width - scaledWidth) / 2;
    final offsetY = (size.height - scaledHeight) / 2;

    canvas.save();
    canvas.translate(offsetX, offsetY);
    canvas.scale(scale);
    canvas.translate(-bounds.left, -bounds.top);

    // Draw nodes only (no connections for performance)
    _drawNodes(canvas);

    // Draw viewport indicator
    if (showViewport) {
      _drawViewport(canvas, scale, offsetX, offsetY, size);
    }

    canvas.restore();
  }

  void _drawNodes(Canvas canvas) {
    final paint = Paint()
      ..color = nodeColor
      ..style = PaintingStyle.fill;

    for (final node in controller.nodes.values) {
      final rect = Rect.fromLTWH(
        node.position.value.dx,
        node.position.value.dy,
        node.size.value.width,
        node.size.value.height,
      );

      canvas.drawRRect(
        RRect.fromRectAndRadius(rect, const Radius.circular(2)),
        paint,
      );
    }
  }

  void _drawViewport(
    Canvas canvas,
    double scale,
    double offsetX,
    double offsetY,
    Size minimapSize,
  ) {
    canvas.restore(); // Restore to minimap coordinate system

    // Calculate visible area based on current viewport
    final vp = controller.viewport;
    final screenSize = controller.screenSize;
    if (screenSize == Size.zero) return;

    final viewportRect = Rect.fromLTWH(
      -vp.x / vp.zoom,
      -vp.y / vp.zoom,
      screenSize.width / vp.zoom,
      screenSize.height / vp.zoom,
    );

    final bounds = controller.nodesBounds;
    if (bounds.isEmpty) return;

    // Transform viewport rect to minimap coordinates
    final minimapViewportRect = Rect.fromLTWH(
      offsetX + (viewportRect.left - bounds.left) * scale,
      offsetY + (viewportRect.top - bounds.top) * scale,
      viewportRect.width * scale,
      viewportRect.height * scale,
    );

    // Clip to minimap bounds
    final clippedRect = minimapViewportRect.intersect(
      Rect.fromLTWH(0, 0, minimapSize.width, minimapSize.height),
    );

    if (!clippedRect.isEmpty) {
      final paint = Paint()
        ..color = viewportColor.withValues(alpha: 0.1)
        ..style = PaintingStyle.fill;

      final borderPaint = Paint()
        ..color = viewportColor.withValues(alpha: 0.4)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.0;

      // Use the same border radius as the minimap widget
      final rrect = RRect.fromRectAndRadius(
        clippedRect,
        Radius.circular(borderRadius),
      );

      canvas.drawRRect(rrect, paint);
      canvas.drawRRect(rrect, borderPaint);
    }

    canvas.save(); // Re-save for proper cleanup
  }

  @override
  bool shouldRepaint(covariant MinimapPainter<T> oldDelegate) {
    return oldDelegate.controller != controller ||
        oldDelegate.nodeColor != nodeColor ||
        oldDelegate.viewportColor != viewportColor ||
        oldDelegate.borderRadius != borderRadius ||
        oldDelegate.showViewport != showViewport;
  }
}

/// Extension adding minimap navigation functionality to [NodeFlowController].
///
/// Provides methods for panning the viewport to specific graph positions,
/// used by the minimap for click-to-navigate and drag-to-pan interactions.
extension MinimapControllerExtension<T> on NodeFlowController<T> {
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
