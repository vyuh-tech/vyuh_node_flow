import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';

import '../../connections/connection.dart';
import '../../nodes/node.dart';
import '../../nodes/node_widget.dart';
import '../../ports/port_widget.dart';
import '../../shared/unbounded_widgets.dart';
import '../node_flow_controller.dart';

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
    this.nodeContainerBuilder,
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
    Widget Function(BuildContext context, Node<T> node, Widget content)?
    nodeContainerBuilder,
    PortBuilder<T>? portBuilder,
    void Function(Node<T> node)? onNodeTap,
    void Function(Node<T> node)? onNodeDoubleTap,
    void Function(Node<T> node, Offset globalPosition)? onNodeContextMenu,
    void Function(Node<T> node)? onNodeMouseEnter,
    void Function(Node<T> node)? onNodeMouseLeave,
    void Function(
      String nodeId,
      String portId,
      bool isOutput,
      Offset globalPosition,
    )?
    onPortContextMenu,
    double portSnapDistance = 8.0,
  }) {
    return NodesLayer<T>(
      controller: controller,
      nodeBuilder: nodeBuilder,
      connections: connections,
      nodeContainerBuilder: nodeContainerBuilder,
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
    Widget Function(BuildContext context, Node<T> node, Widget content)?
    nodeContainerBuilder,
    PortBuilder<T>? portBuilder,
    void Function(Node<T> node)? onNodeTap,
    void Function(Node<T> node)? onNodeDoubleTap,
    void Function(Node<T> node, Offset globalPosition)? onNodeContextMenu,
    void Function(Node<T> node)? onNodeMouseEnter,
    void Function(Node<T> node)? onNodeMouseLeave,
    void Function(
      String nodeId,
      String portId,
      bool isOutput,
      Offset globalPosition,
    )?
    onPortContextMenu,
    double portSnapDistance = 8.0,
  }) {
    return NodesLayer<T>(
      controller: controller,
      nodeBuilder: nodeBuilder,
      connections: connections,
      nodeContainerBuilder: nodeContainerBuilder,
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
    Widget Function(BuildContext context, Node<T> node, Widget content)?
    nodeContainerBuilder,
    PortBuilder<T>? portBuilder,
    void Function(Node<T> node)? onNodeTap,
    void Function(Node<T> node)? onNodeDoubleTap,
    void Function(Node<T> node, Offset globalPosition)? onNodeContextMenu,
    void Function(Node<T> node)? onNodeMouseEnter,
    void Function(Node<T> node)? onNodeMouseLeave,
    void Function(
      String nodeId,
      String portId,
      bool isOutput,
      Offset globalPosition,
    )?
    onPortContextMenu,
    double portSnapDistance = 8.0,
  }) {
    return NodesLayer<T>(
      controller: controller,
      nodeBuilder: nodeBuilder,
      connections: connections,
      nodeContainerBuilder: nodeContainerBuilder,
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

  /// Optional builder for customizing the node container.
  /// When not provided, uses the default NodeWidget implementation.
  final Widget Function(BuildContext context, Node<T> node, Widget content)?
  nodeContainerBuilder;

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
  final void Function(Node<T> node, Offset globalPosition)? onNodeContextMenu;

  /// Callback invoked when mouse enters a node.
  final void Function(Node<T> node)? onNodeMouseEnter;

  /// Callback invoked when mouse leaves a node.
  final void Function(Node<T> node)? onNodeMouseLeave;

  /// Callback invoked when a port is right-clicked (context menu).
  final void Function(
    String nodeId,
    String portId,
    bool isOutput,
    Offset globalPosition,
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
            // Use cached sorted nodes - sorting only happens when nodes change or zIndex changes
            var nodesList = controller.sortedNodes;

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

  /// Builds the node container, either using the custom builder or the default NodeWidget
  Widget _buildNodeContainer(BuildContext context, Node<T> node) {
    // Build the node content first
    final content = nodeBuilder(context, node);

    // Use custom container builder if provided, otherwise use default NodeWidget
    if (nodeContainerBuilder != null) {
      return nodeContainerBuilder!(context, node, content);
    }

    // Get the shape for this node (if any) from the controller
    final shape = controller.nodeShapeBuilder?.call(node);

    // Default implementation: NodeWidget with controller for drag operations
    return NodeWidget<T>(
      key: ValueKey(node.id),
      node: node,
      controller: controller,
      shape: shape,
      connections: connections,
      portBuilder: portBuilder,
      // Event callbacks for external handling
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
      child: content,
    );
  }
}
