import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';

import '../../connections/connection.dart';
import '../../nodes/node.dart';
import '../../nodes/node_widget.dart';
import '../../ports/port_widget.dart';
import '../node_flow_controller.dart';

/// Nodes layer widget that renders all nodes with optimized reactivity.
///
/// Note: Tap, double-tap, context menu, and hover events are handled at the
/// Listener level in NodeFlowEditor using hit testing. This ensures events
/// work correctly regardless of node position on the canvas.
class NodesLayer<T> extends StatelessWidget {
  const NodesLayer({
    super.key,
    required this.controller,
    required this.nodeBuilder,
    required this.connections,
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
    // Note: Event callbacks (tap, double-tap, context menu, hover) are handled
    // at the Listener level in NodeFlowEditor, not here.
    return NodeWidget<T>(
      key: ValueKey(node.id),
      node: node,
      shape: shape,
      connections: connections,
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
