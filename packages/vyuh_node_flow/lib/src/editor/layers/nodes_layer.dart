import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';

import '../../connections/connection.dart';
import '../../graph/coordinates.dart';
import '../../nodes/node.dart';
import '../../nodes/node_container.dart';
import '../../nodes/node_widget.dart';
import '../../ports/port_widget.dart';
import '../controller/node_flow_controller.dart';
import '../themes/node_flow_theme.dart';
import '../unbounded_widgets.dart';

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
/// NodesLayer.background(controller, nodeBuilder, connections)  // Groups
/// NodesLayer.middle(controller, nodeBuilder, connections)      // Regular nodes
/// NodesLayer.foreground(controller, nodeBuilder, connections)  // Stickies, markers
/// ```
class NodesLayer<T> extends StatelessWidget {
  const NodesLayer({
    super.key,
    required this.controller,
    required this.nodeBuilder,
    required this.connections,
    this.portBuilder,
    this.layerFilter,
    this.onNodeTap,
    this.onNodeDoubleTap,
    this.onNodeContextMenu,
    this.onNodeMouseEnter,
    this.onNodeMouseLeave,
    this.onPortContextMenu,
    this.portSnapDistance = 8.0,
  });

  /// Creates a background nodes layer.
  ///
  /// Renders nodes with [NodeRenderLayer.background] behind all other nodes,
  /// typically used for group containers.
  static NodesLayer<T> background<T>(
    NodeFlowController<T> controller,
    Widget Function(BuildContext context, Node<T> node) nodeBuilder,
    List<Connection> connections, {
    PortBuilder<T>? portBuilder,
    void Function(Node<T> node)? onNodeTap,
    void Function(Node<T> node)? onNodeDoubleTap,
    void Function(Node<T> node, ScreenPosition screenPosition)?
    onNodeContextMenu,
    void Function(Node<T> node)? onNodeMouseEnter,
    void Function(Node<T> node)? onNodeMouseLeave,
    void Function(String nodeId, String portId, ScreenPosition screenPosition)?
    onPortContextMenu,
    double portSnapDistance = 8.0,
  }) {
    return NodesLayer<T>(
      controller: controller,
      nodeBuilder: nodeBuilder,
      connections: connections,
      portBuilder: portBuilder,
      layerFilter: NodeRenderLayer.background,
      onNodeTap: onNodeTap,
      onNodeDoubleTap: onNodeDoubleTap,
      onNodeContextMenu: onNodeContextMenu,
      onNodeMouseEnter: onNodeMouseEnter,
      onNodeMouseLeave: onNodeMouseLeave,
      onPortContextMenu: onPortContextMenu,
      portSnapDistance: portSnapDistance,
    );
  }

  /// Creates a middle nodes layer.
  ///
  /// Renders nodes with [NodeRenderLayer.middle] at the standard layer,
  /// used for regular nodes.
  static NodesLayer<T> middle<T>(
    NodeFlowController<T> controller,
    Widget Function(BuildContext context, Node<T> node) nodeBuilder,
    List<Connection> connections, {
    PortBuilder<T>? portBuilder,
    void Function(Node<T> node)? onNodeTap,
    void Function(Node<T> node)? onNodeDoubleTap,
    void Function(Node<T> node, ScreenPosition screenPosition)?
    onNodeContextMenu,
    void Function(Node<T> node)? onNodeMouseEnter,
    void Function(Node<T> node)? onNodeMouseLeave,
    void Function(String nodeId, String portId, ScreenPosition screenPosition)?
    onPortContextMenu,
    double portSnapDistance = 8.0,
  }) {
    return NodesLayer<T>(
      controller: controller,
      nodeBuilder: nodeBuilder,
      connections: connections,
      portBuilder: portBuilder,
      layerFilter: NodeRenderLayer.middle,
      onNodeTap: onNodeTap,
      onNodeDoubleTap: onNodeDoubleTap,
      onNodeContextMenu: onNodeContextMenu,
      onNodeMouseEnter: onNodeMouseEnter,
      onNodeMouseLeave: onNodeMouseLeave,
      onPortContextMenu: onPortContextMenu,
      portSnapDistance: portSnapDistance,
    );
  }

  /// Creates a foreground nodes layer.
  ///
  /// Renders nodes with [NodeRenderLayer.foreground] above all other content,
  /// typically used for sticky notes and markers.
  static NodesLayer<T> foreground<T>(
    NodeFlowController<T> controller,
    Widget Function(BuildContext context, Node<T> node) nodeBuilder,
    List<Connection> connections, {
    PortBuilder<T>? portBuilder,
    void Function(Node<T> node)? onNodeTap,
    void Function(Node<T> node)? onNodeDoubleTap,
    void Function(Node<T> node, ScreenPosition screenPosition)?
    onNodeContextMenu,
    void Function(Node<T> node)? onNodeMouseEnter,
    void Function(Node<T> node)? onNodeMouseLeave,
    void Function(String nodeId, String portId, ScreenPosition screenPosition)?
    onPortContextMenu,
    double portSnapDistance = 8.0,
  }) {
    return NodesLayer<T>(
      controller: controller,
      nodeBuilder: nodeBuilder,
      connections: connections,
      portBuilder: portBuilder,
      layerFilter: NodeRenderLayer.foreground,
      onNodeTap: onNodeTap,
      onNodeDoubleTap: onNodeDoubleTap,
      onNodeContextMenu: onNodeContextMenu,
      onNodeMouseEnter: onNodeMouseEnter,
      onNodeMouseLeave: onNodeMouseLeave,
      onPortContextMenu: onPortContextMenu,
      portSnapDistance: portSnapDistance,
    );
  }

  final NodeFlowController<T> controller;
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

  final List<Connection> connections;

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

  @override
  Widget build(BuildContext context) {
    return UnboundedPositioned.fill(
      child: UnboundedRepaintBoundary(
        child: Observer(
          builder: (_) {
            // Use cached sorted visible nodes - huge performance optimization
            var nodesList = controller.visibleNodes;

            // Apply layer filter if specified
            if (layerFilter != null) {
              nodesList = nodesList
                  .where((node) => node.layer == layerFilter)
                  .toList();
            }

            return UnboundedStack(
              clipBehavior: Clip.none,
              children: [
                for (final node in nodesList)
                  _buildNodeContainer(context, node),
              ],
            );
          },
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

    // Wrap in NodeContainer which handles positioning, gestures, ports, etc.
    return NodeContainer<T>(
      key: ValueKey(node.id),
      node: node,
      controller: controller,
      shape: shape,
      connections: connections,
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
      onPortContextMenu: onPortContextMenu,
      portSnapDistance: portSnapDistance,
      child: NodeWidget<T>(
        node: node,
        theme: nodeTheme,
        shape: shape,
        child: content,
      ),
    );
  }
}
