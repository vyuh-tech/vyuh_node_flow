import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';

import '../../nodes/node.dart';
import '../controller/node_flow_controller.dart';
import '../node_flow_editor.dart';
import '../unbounded_widgets.dart';

/// A layer that renders all nodes using a single CustomPaint.
///
/// Used when zoomed out below the LOD minThreshold for maximum performance.
/// No interaction is possible in this mode - just visual representation.
class NodesThumbnailLayer<T> extends StatelessWidget {
  const NodesThumbnailLayer({
    super.key,
    required this.controller,
    required this.thumbnailBuilder,
    this.layerFilter,
  });

  final NodeFlowController<T, dynamic> controller;
  final ThumbnailBuilder<T>? thumbnailBuilder;
  final NodeRenderLayer? layerFilter;

  @override
  Widget build(BuildContext context) {
    return UnboundedPositioned.fill(
      child: UnboundedRepaintBoundary(
        child: Observer(
          builder: (_) {
            // Get visible nodes (already cached and sorted)
            var nodes = controller.visibleNodes;

            // Apply layer filter if specified
            if (layerFilter != null) {
              nodes = nodes.where((n) => n.layer == layerFilter).toList();
            }

            // Build selected IDs by checking each node's isSelected property.
            // This creates MobX dependencies on node.selected.value - same as widget layer.
            final selectedIds = <String>{
              for (final node in nodes)
                if (node.isSelected) node.id,
            };

            // Get theme for default colors
            final theme = controller.theme;
            final defaultColor =
                theme?.nodeTheme.backgroundColor ?? Colors.grey;
            final selectedBorderColor = theme?.nodeTheme.selectedBorderColor;

            return CustomPaint(
              painter: _NodesThumbnailPainter<T>(
                nodes: nodes,
                selectedIds: selectedIds,
                defaultColor: defaultColor,
                selectedBorderColor: selectedBorderColor,
                thumbnailBuilder: thumbnailBuilder,
              ),
              size: Size.infinite,
            );
          },
        ),
      ),
    );
  }
}

/// CustomPainter that renders all nodes as thumbnails.
class _NodesThumbnailPainter<T> extends CustomPainter {
  _NodesThumbnailPainter({
    required this.nodes,
    required this.selectedIds,
    required this.defaultColor,
    this.selectedBorderColor,
    this.thumbnailBuilder,
  }) : _fingerprint = _computeFingerprint(nodes, selectedIds);

  final List<Node<T>> nodes;
  final Set<String> selectedIds;
  final Color defaultColor;
  final Color? selectedBorderColor;
  final ThumbnailBuilder<T>? thumbnailBuilder;

  /// Fingerprint for efficient change detection
  final int _fingerprint;

  /// Computes a fingerprint based on nodes and selection state
  static int _computeFingerprint<T>(
    List<Node<T>> nodes,
    Set<String> selectedIds,
  ) {
    var hash = nodes.length;

    for (final node in nodes) {
      // Include all visual properties in fingerprint
      hash = Object.hash(
        hash,
        node.id,
        node.position.value.dx.toInt(),
        node.position.value.dy.toInt(),
        node.size.value.width.toInt(),
        node.size.value.height.toInt(),
        node.isVisible,
        selectedIds.contains(node.id),
      );
    }

    return hash;
  }

  @override
  void paint(Canvas canvas, Size size) {
    for (final node in nodes) {
      final position = node.position.value;
      final nodeSize = node.size.value;
      final bounds = Rect.fromLTWH(
        position.dx,
        position.dy,
        nodeSize.width,
        nodeSize.height,
      );

      final isSelected = selectedIds.contains(node.id);

      // Try custom thumbnail builder first
      if (thumbnailBuilder != null) {
        final handled = thumbnailBuilder!(canvas, node, bounds, isSelected);
        if (handled) continue;
      }

      // Fall back to node's paintThumbnail
      node.paintThumbnail(
        canvas,
        bounds,
        color: defaultColor,
        isSelected: isSelected,
        selectedBorderColor: selectedBorderColor,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _NodesThumbnailPainter<T> oldDelegate) {
    // Repaint when fingerprint changes (nodes, positions, visibility, or selection)
    if (_fingerprint != oldDelegate._fingerprint) return true;
    // Check theme colors
    if (defaultColor != oldDelegate.defaultColor) return true;
    if (selectedBorderColor != oldDelegate.selectedBorderColor) return true;
    return false;
  }
}
