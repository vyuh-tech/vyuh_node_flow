import 'package:flutter/material.dart';

import '../connections/connection.dart';
import '../nodes/node.dart';
import 'node_flow_behavior.dart';
import 'node_flow_config.dart';
import 'node_flow_controller.dart';
import 'node_flow_editor.dart';
import 'node_flow_events.dart';
import 'node_flow_theme.dart';
import 'viewport.dart';

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
class NodeFlowViewer<T> extends StatelessWidget {
  const NodeFlowViewer({
    super.key,
    required this.controller,
    required this.nodeBuilder,
    required this.theme,
    this.nodeContainerBuilder,
    this.scrollToZoom = true,
    this.showAnnotations = false,
    this.onNodeTap,
    this.onNodeSelected,
    this.onConnectionTap,
    this.onConnectionSelected,
  });

  /// The controller managing the node flow state.
  ///
  /// This controller holds all nodes, connections, annotations, and viewport state.
  /// Create it externally and pass it in, or use [NodeFlowViewer.withData] to
  /// have one created automatically.
  final NodeFlowController<T> controller;

  /// Builder function for rendering node content.
  ///
  /// Called for each node to create its visual representation. The returned
  /// widget is automatically wrapped in a NodeWidget container.
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

  /// Optional builder for customizing the node container.
  ///
  /// Receives the node content (from [nodeBuilder]) and the node itself.
  /// Use this to wrap nodes with custom decorations or modify the default
  /// NodeWidget appearance.
  ///
  /// Example:
  /// ```dart
  /// nodeContainerBuilder: (context, node, content) {
  ///   return Container(
  ///     decoration: BoxDecoration(
  ///       border: Border.all(color: Colors.blue),
  ///     ),
  ///     child: NodeWidget(node: node, child: content),
  ///   );
  /// }
  /// ```
  final Widget Function(BuildContext context, Node<T> node, Widget content)?
  nodeContainerBuilder;

  /// The theme configuration for visual styling.
  ///
  /// Controls colors, sizes, and appearance of nodes, connections, ports,
  /// and other UI elements.
  final NodeFlowTheme theme;

  /// Whether trackpad scroll gestures should cause zooming.
  ///
  /// When `true`, scrolling on a trackpad zooms in/out.
  /// When `false`, trackpad scroll is treated as pan gestures.
  /// Defaults to `true`.
  final bool scrollToZoom;

  /// Whether to show annotation layers (sticky notes, markers, groups).
  ///
  /// When `false`, annotations are not rendered but remain in the graph data.
  /// Defaults to `false` for viewers.
  final bool showAnnotations;

  /// Called when a node is tapped.
  final ValueChanged<Node<T>?>? onNodeTap;

  /// Called when a node's selection state changes.
  ///
  /// Receives the selected node, or `null` if selection was cleared.
  final ValueChanged<Node<T>?>? onNodeSelected;

  /// Called when a connection is tapped.
  final ValueChanged<Connection?>? onConnectionTap;

  /// Called when a connection's selection state changes.
  ///
  /// Receives the selected connection, or `null` if selection was cleared.
  final ValueChanged<Connection?>? onConnectionSelected;

  @override
  Widget build(BuildContext context) {
    // Viewer always uses preview behavior - allows navigation but no editing
    const behavior = NodeFlowBehavior.preview;

    return NodeFlowEditor<T>(
      controller: controller,
      nodeBuilder: nodeBuilder,
      nodeContainerBuilder: nodeContainerBuilder,
      theme: theme,
      behavior: behavior,
      scrollToZoom: scrollToZoom,
      showAnnotations: showAnnotations,
      events: NodeFlowEvents<T>(
        node: NodeEvents<T>(onTap: onNodeTap, onSelected: onNodeSelected),
        connection: ConnectionEvents<T>(
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
  static NodeFlowViewer<T> withData<T>({
    Key? key,
    required NodeFlowTheme theme,
    required Widget Function(BuildContext context, Node<T> node) nodeBuilder,
    required Map<String, Node<T>> nodes,
    required List<Connection> connections,
    NodeFlowConfig? config,
    Widget Function(BuildContext context, Node<T> node, Widget content)?
    nodeContainerBuilder,
    bool scrollToZoom = true,
    bool showAnnotations = false,
    ValueChanged<Node<T>?>? onNodeTap,
    ValueChanged<Node<T>?>? onNodeSelected,
    ValueChanged<Connection?>? onConnectionTap,
    ValueChanged<Connection?>? onConnectionSelected,
    GraphViewport? initialViewport,
  }) {
    final controller = NodeFlowController<T>(
      initialViewport: initialViewport,
      config: config,
    );

    // Set theme
    controller.setTheme(theme);

    // Load nodes
    for (final node in nodes.values) {
      controller.addNode(node);
    }

    // Load connections
    for (final connection in connections) {
      controller.addConnection(connection);
    }

    return NodeFlowViewer<T>(
      key: key,
      controller: controller,
      nodeBuilder: nodeBuilder,
      nodeContainerBuilder: nodeContainerBuilder,
      theme: theme,
      scrollToZoom: scrollToZoom,
      showAnnotations: showAnnotations,
      onNodeTap: onNodeTap,
      onNodeSelected: onNodeSelected,
      onConnectionTap: onConnectionTap,
      onConnectionSelected: onConnectionSelected,
    );
  }
}
