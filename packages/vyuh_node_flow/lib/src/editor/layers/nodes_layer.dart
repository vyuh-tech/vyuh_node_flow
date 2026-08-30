import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';

import '../../graph/coordinates.dart';
import '../../nodes/node.dart';
import '../../nodes/node_container.dart';
import '../../nodes/node_widget.dart';
import '../../plugins/lod/lod_plugin.dart';
import '../../ports/port_widget.dart';
import '../controller/node_flow_controller.dart';
import '../node_flow_editor.dart';
import '../themes/node_flow_theme.dart';
import '../unbounded_widgets.dart';
import 'nodes_thumbnail_layer.dart';

/// Nodes layer widget that renders all nodes with optimized reactivity.
///
/// This layer handles rendering of all nodes and wires gesture callbacks
/// from the editor to individual [NodeWidget] instances.
///
/// ## Layer Architecture
///
/// The node flow editor uses layer-based rendering to control z-order:
/// - **Background layer**: Renders nodes with [NodeRenderLayer.background]
/// - **Middle layer**: Renders regular nodes with [NodeRenderLayer.middle] (default)
/// - **Foreground layer**: Renders nodes with [NodeRenderLayer.foreground]
///
/// Use the factory constructors to create filtered layers:
/// ```dart
/// NodesLayer.background(controller, nodeBuilder)  // Groups
/// NodesLayer.middle(controller, nodeBuilder)      // Regular nodes
/// NodesLayer.foreground(controller, nodeBuilder)  // Stickies, markers
/// ```
class NodesLayer<T> extends StatelessWidget {
  const NodesLayer({
    super.key,
    required this.controller,
    required this.nodeBuilder,
    this.portBuilder,
    this.layerFilter,
    this.onNodeTap,
    this.onNodeDoubleTap,
    this.onNodeContextMenu,
    this.onNodeMouseEnter,
    this.onNodeMouseLeave,
    this.onPortHover,
    this.onPortContextMenu,
    this.portSnapDistance = 8.0,
    this.thumbnailBuilder,
  });

  /// Creates a background nodes layer.
  ///
  /// Renders nodes with [NodeRenderLayer.background] behind all other nodes,
  /// typically used for group containers.
  static NodesLayer<T> background<T>(
    NodeFlowController<T, dynamic> controller,
    Widget Function(BuildContext context, Node<T> node) nodeBuilder, {
    PortBuilder<T>? portBuilder,
    ThumbnailBuilder<T>? thumbnailBuilder,
    void Function(Node<T> node)? onNodeTap,
    void Function(Node<T> node)? onNodeDoubleTap,
    void Function(Node<T> node, ScreenPosition screenPosition)?
    onNodeContextMenu,
    void Function(Node<T> node)? onNodeMouseEnter,
    void Function(Node<T> node)? onNodeMouseLeave,
    void Function(String nodeId, String portId, bool isHover)? onPortHover,
    void Function(String nodeId, String portId, ScreenPosition screenPosition)?
    onPortContextMenu,
    double portSnapDistance = 8.0,
  }) {
    return NodesLayer<T>(
      controller: controller,
      nodeBuilder: nodeBuilder,
      portBuilder: portBuilder,
      thumbnailBuilder: thumbnailBuilder,
      layerFilter: NodeRenderLayer.background,
      onNodeTap: onNodeTap,
      onNodeDoubleTap: onNodeDoubleTap,
      onNodeContextMenu: onNodeContextMenu,
      onNodeMouseEnter: onNodeMouseEnter,
      onNodeMouseLeave: onNodeMouseLeave,
      onPortHover: onPortHover,
      onPortContextMenu: onPortContextMenu,
      portSnapDistance: portSnapDistance,
    );
  }

  /// Creates a middle nodes layer.
  ///
  /// Renders nodes with [NodeRenderLayer.middle] at the standard layer,
  /// used for regular nodes.
  static NodesLayer<T> middle<T>(
    NodeFlowController<T, dynamic> controller,
    Widget Function(BuildContext context, Node<T> node) nodeBuilder, {
    PortBuilder<T>? portBuilder,
    ThumbnailBuilder<T>? thumbnailBuilder,
    void Function(Node<T> node)? onNodeTap,
    void Function(Node<T> node)? onNodeDoubleTap,
    void Function(Node<T> node, ScreenPosition screenPosition)?
    onNodeContextMenu,
    void Function(Node<T> node)? onNodeMouseEnter,
    void Function(Node<T> node)? onNodeMouseLeave,
    void Function(String nodeId, String portId, bool isHover)? onPortHover,
    void Function(String nodeId, String portId, ScreenPosition screenPosition)?
    onPortContextMenu,
    double portSnapDistance = 8.0,
  }) {
    return NodesLayer<T>(
      controller: controller,
      nodeBuilder: nodeBuilder,
      portBuilder: portBuilder,
      thumbnailBuilder: thumbnailBuilder,
      layerFilter: NodeRenderLayer.middle,
      onNodeTap: onNodeTap,
      onNodeDoubleTap: onNodeDoubleTap,
      onNodeContextMenu: onNodeContextMenu,
      onNodeMouseEnter: onNodeMouseEnter,
      onNodeMouseLeave: onNodeMouseLeave,
      onPortHover: onPortHover,
      onPortContextMenu: onPortContextMenu,
      portSnapDistance: portSnapDistance,
    );
  }

  /// Creates a foreground nodes layer.
  ///
  /// Renders nodes with [NodeRenderLayer.foreground] above all other content,
  /// typically used for sticky notes and markers.
  static NodesLayer<T> foreground<T>(
    NodeFlowController<T, dynamic> controller,
    Widget Function(BuildContext context, Node<T> node) nodeBuilder, {
    PortBuilder<T>? portBuilder,
    ThumbnailBuilder<T>? thumbnailBuilder,
    void Function(Node<T> node)? onNodeTap,
    void Function(Node<T> node)? onNodeDoubleTap,
    void Function(Node<T> node, ScreenPosition screenPosition)?
    onNodeContextMenu,
    void Function(Node<T> node)? onNodeMouseEnter,
    void Function(Node<T> node)? onNodeMouseLeave,
    void Function(String nodeId, String portId, bool isHover)? onPortHover,
    void Function(String nodeId, String portId, ScreenPosition screenPosition)?
    onPortContextMenu,
    double portSnapDistance = 8.0,
  }) {
    return NodesLayer<T>(
      controller: controller,
      nodeBuilder: nodeBuilder,
      portBuilder: portBuilder,
      thumbnailBuilder: thumbnailBuilder,
      layerFilter: NodeRenderLayer.foreground,
      onNodeTap: onNodeTap,
      onNodeDoubleTap: onNodeDoubleTap,
      onNodeContextMenu: onNodeContextMenu,
      onNodeMouseEnter: onNodeMouseEnter,
      onNodeMouseLeave: onNodeMouseLeave,
      onPortHover: onPortHover,
      onPortContextMenu: onPortContextMenu,
      portSnapDistance: portSnapDistance,
    );
  }

  final NodeFlowController<T, dynamic> controller;
  final Widget Function(BuildContext context, Node<T> node) nodeBuilder;

  /// Optional builder for customizing individual port widgets.
  /// When not provided, uses the default PortWidget implementation.
  final PortBuilder<T>? portBuilder;

  /// Optional filter to only render nodes in a specific layer.
  ///
  /// When null, all nodes are rendered. When set, only nodes with matching
  /// [Node.layer] are displayed. Use the factory constructors for convenience:
  /// - [NodesLayer.background] for background layer nodes
  /// - [NodesLayer.middle] for middle layer nodes (default for regular nodes)
  /// - [NodesLayer.foreground] for foreground layer nodes
  final NodeRenderLayer? layerFilter;

  /// Callback invoked when a node is tapped.
  final void Function(Node<T> node)? onNodeTap;

  /// Callback invoked when a node is double-tapped.
  final void Function(Node<T> node)? onNodeDoubleTap;

  /// Callback invoked when a node is right-clicked (context menu).
  /// The [screenPosition] is in screen/global coordinates for menu positioning.
  final void Function(Node<T> node, ScreenPosition screenPosition)?
  onNodeContextMenu;

  /// Callback invoked when mouse enters a node.
  final void Function(Node<T> node)? onNodeMouseEnter;

  /// Callback invoked when mouse leaves a node.
  final void Function(Node<T> node)? onNodeMouseLeave;

  /// Callback invoked when a port hover state changes.
  final void Function(String nodeId, String portId, bool isHover)? onPortHover;

  /// Callback invoked when a port is right-clicked (context menu).
  /// The [screenPosition] is in screen/global coordinates for menu positioning.
  final void Function(
    String nodeId,
    String portId,
    ScreenPosition screenPosition,
  )?
  onPortContextMenu;

  /// Distance around ports that expands the hit area for easier targeting.
  final double portSnapDistance;

  /// Optional custom thumbnail painter for nodes.
  final ThumbnailBuilder<T>? thumbnailBuilder;

  @override
  Widget build(BuildContext context) {
    return Observer(
      builder: (_) {
        // Resolve the visible subset before allocating any full-canvas widget.
        // Most graphs use only the middle render layer, so this keeps the empty
        // background and foreground passes out of the render tree entirely.
        var nodesList = controller.visibleNodes;
        if (layerFilter != null) {
          nodesList = nodesList
              .where((node) => node.layer == layerFilter)
              .toList();
        }

        if (nodesList.isEmpty) return const SizedBox.shrink();

        final sceneMode = controller.lod?.sceneMode ?? NodeSceneMode.widgets;

        if (sceneMode == NodeSceneMode.overview) {
          // Preserve the node under direct manipulation as a real widget.
          // Ordinary overview nodes remain in one retained painted scene.
          return _buildPaintedLayer(
            context,
            nodesList,
            promoteSelection: false,
          );
        }

        if (sceneMode == NodeSceneMode.navigation) {
          return _buildPaintedLayer(context, nodesList, promoteSelection: true);
        }

        // Widget mode: individual widgets per node
        return _buildWidgetLayer(context, nodesList);
      },
    );
  }

  Widget _buildPaintedLayer(
    BuildContext context,
    List<Node<T>> nodesList, {
    required bool promoteSelection,
  }) {
    // Keep only discrete interaction state as live widgets. Camera movement
    // itself never changes this set, so navigation frames remain paint-only
    // for the ordinary graph while selection/focus survives the mode switch.
    final promotedIds = <String>{
      if (promoteSelection) ...controller.selectedNodeIds,
      for (final node in nodesList)
        if (node.isEditing ||
            node.retainedRendering == RetainedNodeRendering.live)
          node.id,
    };
    final draggedNodeId = controller.interaction.draggedNodeId.value;
    if (draggedNodeId != null) promotedIds.add(draggedNodeId);
    final resizingNodeId = controller.interaction.resizingNodeId.value;
    if (resizingNodeId != null) promotedIds.add(resizingNodeId);
    final temporaryConnection =
        controller.interaction.temporaryConnection.value;
    if (temporaryConnection != null) {
      promotedIds.add(temporaryConnection.startNodeId);
      final targetNodeId = temporaryConnection.targetNodeId;
      if (targetNodeId != null) promotedIds.add(targetNodeId);
    }

    if (promotedIds.isEmpty) {
      return NodesThumbnailLayer<T>(
        controller: controller,
        thumbnailBuilder: thumbnailBuilder,
        layerFilter: layerFilter,
        nodes: nodesList,
      );
    }

    final paintedNodes = <Node<T>>[];
    final promotedNodes = <Node<T>>[];
    for (final node in nodesList) {
      (promotedIds.contains(node.id) ? promotedNodes : paintedNodes).add(node);
    }

    return UnboundedStack(
      clipBehavior: Clip.none,
      children: [
        if (paintedNodes.isNotEmpty)
          NodesThumbnailLayer<T>(
            controller: controller,
            thumbnailBuilder: thumbnailBuilder,
            layerFilter: layerFilter,
            nodes: paintedNodes,
          ),
        if (promotedNodes.isNotEmpty) _buildWidgetLayer(context, promotedNodes),
      ],
    );
  }

  Widget _buildWidgetLayer(BuildContext context, List<Node<T>> nodesList) {
    return UnboundedPositioned.fill(
      child: UnboundedRepaintBoundary(
        child: UnboundedStack(
          clipBehavior: Clip.none,
          children: [
            for (final node in nodesList) _buildNodeContainer(context, node),
          ],
        ),
      ),
    );
  }

  /// Builds the node container with its visual content.
  ///
  /// This method:
  /// 1. Builds the visual content using [nodeBuilder]
  /// 2. Wraps it in [NodeContainer] which handles positioning, gestures, ports, etc.
  Widget _buildNodeContainer(BuildContext context, Node<T> node) {
    // Build the node content first
    final content = nodeBuilder(context, node);

    // Get the shape for this node (if any) from the controller
    final shape = controller.nodeShapeBuilder?.call(node);

    // Get theme for NodeWidget
    final theme = controller.theme ?? NodeFlowTheme.light;
    final nodeTheme = theme.nodeTheme;

    // Check LOD visibility for node content
    // If LOD extension is not configured, default to showing node content
    final showNodeContent = controller.lod?.showNodeContent ?? true;

    // Wrap in NodeContainer which handles positioning, gestures, ports, etc.
    return NodeContainer<T>(
      key: ValueKey(node.id),
      node: node,
      controller: controller,
      shape: shape,
      portBuilder: portBuilder,
      // Event callbacks
      onTap: onNodeTap != null ? () => onNodeTap!(node) : null,
      onDoubleTap: onNodeDoubleTap != null
          ? () => onNodeDoubleTap!(node)
          : null,
      onContextMenu: onNodeContextMenu != null
          ? (pos) => onNodeContextMenu!(node, pos)
          : null,
      onMouseEnter: onNodeMouseEnter != null
          ? () => onNodeMouseEnter!(node)
          : null,
      onMouseLeave: onNodeMouseLeave != null
          ? () => onNodeMouseLeave!(node)
          : null,
      onPortHover: onPortHover,
      onPortContextMenu: onPortContextMenu,
      portSnapDistance: portSnapDistance,
      child: NodeWidget<T>(
        node: node,
        theme: node.theme ?? nodeTheme,
        shape: shape,
        showContent: showNodeContent,
        child: content,
      ),
    );
  }
}
