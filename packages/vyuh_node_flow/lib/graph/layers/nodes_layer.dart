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
class NodesLayer<T> extends StatelessWidget {
  const NodesLayer({
    super.key,
    required this.controller,
    required this.nodeBuilder,
    required this.connections,
    this.nodeContainerBuilder,
    this.portBuilder,
    this.onNodeTap,
    this.onNodeDoubleTap,
    this.onNodeContextMenu,
    this.onNodeMouseEnter,
    this.onNodeMouseLeave,
    this.onPortContextMenu,
    this.portSnapDistance = 8.0,
  });

  final NodeFlowController<T> controller;
  final Widget Function(BuildContext context, Node<T> node) nodeBuilder;

  /// Optional builder for customizing the node container.
  /// When not provided, uses the default NodeWidget implementation.
  final Widget Function(BuildContext context, Node<T> node, Widget content)?
  nodeContainerBuilder;

  /// Optional builder for customizing individual port widgets.
  /// When not provided, uses the default PortWidget implementation.
  final PortBuilder<T>? portBuilder;

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
            final nodesList = controller.sortedNodes;

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
