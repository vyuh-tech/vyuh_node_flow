import 'package:flutter/material.dart';

import '../connections/connection.dart';
import '../nodes/node.dart';
import 'node_flow_config.dart';
import 'node_flow_controller.dart';
import 'node_flow_editor.dart';
import 'node_flow_theme.dart';
import 'viewport.dart';

/// A simplified read-only viewer for node flow graphs.
///
/// This widget provides a read-only view of a node flow graph with pan and zoom
/// capabilities but no editing functionality. It is a wrapper around [NodeFlowEditor]
/// configured for display-only purposes.
///
/// Use this widget when you need to display a graph without allowing users to:
/// - Drag or move nodes
/// - Create or delete connections
/// - Modify the graph structure
///
/// Users can still:
/// - Pan the viewport (if [enablePanning] is true)
/// - Zoom in/out (if [enableZooming] is true)
/// - Select items (if [allowSelection] is true)
/// - Tap on nodes/connections (with callbacks)
///
/// Example:
/// ```dart
/// NodeFlowViewer<MyData>(
///   controller: controller,
///   theme: NodeFlowTheme.light,
///   nodeBuilder: (context, node) {
///     return Text(node.data.toString());
///   },
///   enablePanning: true,
///   enableZooming: true,
///   allowSelection: true,
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
    this.enablePanning = true,
    this.enableZooming = true,
    this.scrollToZoom = true,
    this.showAnnotations = false,
    this.allowSelection = false,
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

  /// Whether to enable viewport panning with mouse/trackpad drag.
  ///
  /// When `true`, dragging on the canvas pans the viewport.
  /// Defaults to `true`.
  final bool enablePanning;

  /// Whether to enable zoom controls (pinch-to-zoom, scroll wheel zoom).
  ///
  /// Defaults to `true`.
  final bool enableZooming;

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

  /// Whether to allow selection of nodes and connections.
  ///
  /// When enabled, users can click to select items and see selection feedback,
  /// but cannot drag or edit them. Useful for highlighting or inspecting items
  /// in a read-only view.
  ///
  /// Defaults to `false`.
  final bool allowSelection;

  /// Called when a node is tapped.
  ///
  /// Only active if [allowSelection] is `true`.
  final ValueChanged<Node<T>?>? onNodeTap;

  /// Called when a node's selection state changes.
  ///
  /// Receives the selected node, or `null` if selection was cleared.
  /// Only active if [allowSelection] is `true`.
  final ValueChanged<Node<T>?>? onNodeSelected;

  /// Called when a connection is tapped.
  ///
  /// Only active if [allowSelection] is `true`.
  final ValueChanged<Connection?>? onConnectionTap;

  /// Called when a connection's selection state changes.
  ///
  /// Receives the selected connection, or `null` if selection was cleared.
  /// Only active if [allowSelection] is `true`.
  final ValueChanged<Connection?>? onConnectionSelected;

  @override
  Widget build(BuildContext context) {
    return NodeFlowEditor<T>(
      controller: controller,
      nodeBuilder: nodeBuilder,
      nodeContainerBuilder: nodeContainerBuilder,
      theme: theme,
      // Viewer configuration - no dragging or connection creation
      enablePanning: enablePanning,
      enableZooming: enableZooming,
      enableSelection: allowSelection,
      enableNodeDragging: false,
      enableConnectionCreation: false,
      scrollToZoom: scrollToZoom,
      showAnnotations: showAnnotations,
      // Selection callbacks (only active if allowSelection is true)
      onNodeSelected: allowSelection ? onNodeSelected : null,
      onNodeTap: allowSelection ? onNodeTap : null,
      onNodeDoubleTap: null,
      onConnectionSelected: allowSelection ? onConnectionSelected : null,
      onConnectionTap: allowSelection ? onConnectionTap : null,
      onConnectionDoubleTap: null,
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
    bool enablePanning = true,
    bool enableZooming = true,
    bool scrollToZoom = true,
    bool showAnnotations = false,
    bool allowSelection = false,
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
      enablePanning: enablePanning,
      enableZooming: enableZooming,
      scrollToZoom: scrollToZoom,
      showAnnotations: showAnnotations,
      allowSelection: allowSelection,
      onNodeTap: onNodeTap,
      onNodeSelected: onNodeSelected,
      onConnectionTap: onConnectionTap,
      onConnectionSelected: onConnectionSelected,
    );
  }
}
