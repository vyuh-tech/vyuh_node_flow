import 'package:flutter/material.dart';

import '../connections/connection.dart';
import '../nodes/node.dart';
import 'controller/node_flow_controller.dart';
import 'node_flow_behavior.dart';
import 'node_flow_config.dart';
import 'node_flow_editor.dart';
import 'node_flow_events.dart';
import 'themes/node_flow_theme.dart';
import '../graph/viewport.dart';

/// A simplified viewer for node flow graphs.
///
/// This widget provides a read-only view of a node flow graph. It is a wrapper
/// around [NodeFlowEditor] configured with [NodeFlowBehavior.preview], which
/// allows navigation (pan, zoom, select, drag) but prevents structural changes
/// (create, update, delete).
///
/// For full editing capabilities, use [NodeFlowEditor] with
/// [NodeFlowBehavior.design].
///
/// For a completely non-interactive display, use [NodeFlowEditor] with
/// [NodeFlowBehavior.present].
///
/// Example:
/// ```dart
/// NodeFlowViewer<MyData>(
///   controller: controller,
///   theme: NodeFlowTheme.light,
///   nodeBuilder: (context, node) {
///     return Text(node.data.toString());
///   },
///   onNodeTap: (node) {
///     print('Tapped: ${node?.id}');
///   },
/// )
/// ```
///
/// For convenience, you can also use [NodeFlowViewer.withData] to create
/// a viewer with pre-loaded data:
///
/// ```dart
/// NodeFlowViewer.withData<MyData>(
///   theme: NodeFlowTheme.light,
///   nodeBuilder: (context, node) => MyNodeWidget(node: node),
///   nodes: myNodesMap,
///   connections: myConnectionsList,
/// )
/// ```
class NodeFlowViewer<T, C> extends StatelessWidget {
  const NodeFlowViewer({
    super.key,
    required this.controller,
    required this.nodeBuilder,
    required this.theme,
    this.onNodeTap,
    this.onNodeSelected,
    this.onConnectionTap,
    this.onConnectionSelected,
  });

  /// The controller managing the node flow state.
  ///
  /// This controller holds all nodes, connections, and viewport state.
  /// Create it externally and pass it in, or use [NodeFlowViewer.withData] to
  /// have one created automatically.
  final NodeFlowController<T, C> controller;

  /// Builder function for rendering node content.
  ///
  /// Called for each node to create its visual representation. The returned
  /// widget is automatically wrapped in a NodeWidget container.
  ///
  /// For full control over node rendering, implement [Node.buildWidget] to make
  /// your node self-rendering.
  ///
  /// Example:
  /// ```dart
  /// nodeBuilder: (context, node) {
  ///   return Container(
  ///     padding: EdgeInsets.all(16),
  ///     child: Text(node.data.toString()),
  ///   );
  /// }
  /// ```
  final Widget Function(BuildContext context, Node<T> node) nodeBuilder;

  /// The theme configuration for visual styling.
  ///
  /// Controls colors, sizes, and appearance of nodes, connections, ports,
  /// and other UI elements.
  final NodeFlowTheme theme;

  /// Called when a node is tapped.
  final ValueChanged<Node<T>?>? onNodeTap;

  /// Called when a node's selection state changes.
  ///
  /// Receives the selected node, or `null` if selection was cleared.
  final ValueChanged<Node<T>?>? onNodeSelected;

  /// Called when a connection is tapped.
  final ValueChanged<Connection<C>?>? onConnectionTap;

  /// Called when a connection's selection state changes.
  ///
  /// Receives the selected connection, or `null` if selection was cleared.
  final ValueChanged<Connection<C>?>? onConnectionSelected;

  @override
  Widget build(BuildContext context) {
    // Viewer always uses preview behavior - allows navigation but no editing
    const behavior = NodeFlowBehavior.preview;

    return NodeFlowEditor<T, C>(
      controller: controller,
      nodeBuilder: nodeBuilder,
      theme: theme,
      behavior: behavior,
      events: NodeFlowEvents<T, C>(
        node: NodeEvents<T>(onTap: onNodeTap, onSelected: onNodeSelected),
        connection: ConnectionEvents<T, C>(
          onTap: onConnectionTap,
          onSelected: onConnectionSelected,
        ),
      ),
    );
  }

  /// Convenience factory to create a viewer with data pre-loaded.
  ///
  /// This factory creates a [NodeFlowController] internally and populates it
  /// with the provided nodes and connections. Useful for quickly displaying
  /// a graph without manually managing the controller.
  ///
  /// Parameters:
  /// - [theme]: Required theme for styling the viewer
  /// - [nodeBuilder]: Required function to build node content
  /// - [nodes]: Map of node IDs to [Node] objects
  /// - [connections]: List of [Connection] objects
  /// - [config]: Optional configuration for viewport and interaction behavior
  /// - [initialViewport]: Optional starting viewport position and zoom
  ///
  /// Example:
  /// ```dart
  /// final viewer = NodeFlowViewer.withData<String>(
  ///   theme: NodeFlowTheme.light,
  ///   nodeBuilder: (context, node) => Text(node.data),
  ///   nodes: {
  ///     'node1': Node(id: 'node1', data: 'First Node'),
  ///     'node2': Node(id: 'node2', data: 'Second Node'),
  ///   },
  ///   connections: [
  ///     Connection(
  ///       id: 'conn1',
  ///       sourceNodeId: 'node1',
  ///       targetNodeId: 'node2',
  ///       sourcePortId: 'out',
  ///       targetPortId: 'in',
  ///     ),
  ///   ],
  /// );
  /// ```
  static NodeFlowViewer<T, C> withData<T, C>({
    Key? key,
    required NodeFlowTheme theme,
    required Widget Function(BuildContext context, Node<T> node) nodeBuilder,
    required Map<String, Node<T>> nodes,
    required List<Connection<C>> connections,
    NodeFlowConfig? config,
    ValueChanged<Node<T>?>? onNodeTap,
    ValueChanged<Node<T>?>? onNodeSelected,
    ValueChanged<Connection<C>?>? onConnectionTap,
    ValueChanged<Connection<C>?>? onConnectionSelected,
    GraphViewport? initialViewport,
  }) {
    final controller = NodeFlowController<T, C>(
      initialViewport: initialViewport,
      config: config,
    );

    // NOTE: Theme is not set here - it's handled by NodeFlowEditor.initState()
    // which calls initController with all required parameters.

    // Load nodes
    for (final node in nodes.values) {
      controller.addNode(node);
    }

    // Load connections
    for (final connection in connections) {
      controller.addConnection(connection);
    }

    return NodeFlowViewer<T, C>(
      key: key,
      controller: controller,
      nodeBuilder: nodeBuilder,
      theme: theme,
      onNodeTap: onNodeTap,
      onNodeSelected: onNodeSelected,
      onConnectionTap: onConnectionTap,
      onConnectionSelected: onConnectionSelected,
    );
  }
}
