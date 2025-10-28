import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';

import '../../connections/connection.dart';
import '../../nodes/node.dart';
import '../../nodes/node_widget.dart';
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
    this.nodeContainerBuilder,
  });

  final NodeFlowController<T> controller;
  final Widget Function(BuildContext context, Node<T> node) nodeBuilder;

  /// Optional builder for customizing the node container.
  /// When not provided, uses the default NodeWidget implementation.
  final Widget Function(BuildContext context, Node<T> node, Widget content)?
      nodeContainerBuilder;

  final List<Connection> connections;
  final void Function(Node<T> node) onNodeTap;
  final void Function(Node<T> node) onNodeDoubleTap;

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
                for (final node in nodesList) _buildNodeContainer(context, node),
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

    // Default implementation: NodeWidget with standard functionality
    return NodeWidget<T>(
      key: ValueKey(node.id),
      node: node,
      connections: connections,
      onNodeTap: (nodeId) => onNodeTap(node),
      onNodeDoubleTap: (nodeId) => onNodeDoubleTap(node),
      child: content,
    );
  }
}
