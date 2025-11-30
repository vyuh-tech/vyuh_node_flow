import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';

import '../../connections/connection.dart';
import '../../nodes/node.dart';
import '../../nodes/node_widget.dart';
import '../../ports/port_widget.dart';
import '../node_flow_controller.dart';

/// Nodes layer widget that renders all nodes with optimized reactivity
class NodesLayer<T> extends StatelessWidget {
  const NodesLayer({
    super.key,
    required this.controller,
    required this.nodeBuilder,
    required this.connections,
    required this.onNodeTap,
    required this.onNodeDoubleTap,
    this.onNodeMouseEnter,
    this.onNodeMouseLeave,
    this.onNodeContextMenu,
    this.nodeContainerBuilder,
    this.portBuilder,
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
  final void Function(Node<T> node) onNodeTap;
  final void Function(Node<T> node) onNodeDoubleTap;
  final void Function(Node<T> node)? onNodeMouseEnter;
  final void Function(Node<T> node)? onNodeMouseLeave;
  final void Function(Node<T> node, Offset position)? onNodeContextMenu;

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: RepaintBoundary(
        child: Observer(
          builder: (_) {
            // Use cached sorted nodes - sorting only happens when nodes change or zIndex changes
            final nodesList = controller.sortedNodes;

            return Stack(
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

    // Default implementation: NodeWidget with standard functionality
    return NodeWidget<T>(
      key: ValueKey(node.id),
      node: node,
      shape: shape,
      connections: connections,
      onNodeTap: (nodeId) => onNodeTap(node),
      onNodeDoubleTap: (nodeId) => onNodeDoubleTap(node),
      onNodeMouseEnter: onNodeMouseEnter != null
          ? (nodeId) => onNodeMouseEnter!(node)
          : null,
      onNodeMouseLeave: onNodeMouseLeave != null
          ? (nodeId) => onNodeMouseLeave!(node)
          : null,
      onNodeContextMenu: onNodeContextMenu != null
          ? (nodeId, pos) => onNodeContextMenu!(node, pos)
          : null,
      portBuilder: portBuilder != null
          ? (context, n, port, isOutput, isConnected, isHighlighted) =>
                portBuilder!(
                  context,
                  n,
                  port,
                  isOutput,
                  isConnected,
                  isHighlighted,
                )
          : null,
      child: content,
    );
  }
}
