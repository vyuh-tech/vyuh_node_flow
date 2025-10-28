import 'package:flutter/material.dart';

import '../connections/connection.dart';
import '../nodes/node.dart';
import 'node_flow_config.dart';
import 'node_flow_controller.dart';
import 'node_flow_editor.dart';
import 'node_flow_theme.dart';
import 'viewport.dart';

/// A simplified read-only viewer for node flow graphs.
/// This is a wrapper around NodeFlowEditor configured for read-only display.
/// Provides pan and zoom functionality without any editing capabilities.
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

  /// Controller managing the node flow state
  final NodeFlowController<T> controller;

  /// Builder function for creating node widgets
  final Widget Function(BuildContext context, Node<T> node) nodeBuilder;

  /// Optional builder for customizing the node container
  final Widget Function(BuildContext context, Node<T> node, Widget content)?
      nodeContainerBuilder;

  /// Theme configuration for visual styling
  final NodeFlowTheme theme;

  /// Whether to enable panning the canvas
  final bool enablePanning;

  /// Whether to enable zooming the canvas
  final bool enableZooming;

  /// Whether trackpad scroll causes zoom (vs pan)
  final bool scrollToZoom;

  /// Whether to show annotations
  final bool showAnnotations;

  /// Whether to allow selection of nodes and connections
  /// When enabled, users can click to select items and see selection feedback
  /// Does not enable dragging or editing
  final bool allowSelection;

  /// Callback when a node is tapped
  final ValueChanged<Node<T>?>? onNodeTap;

  /// Callback when a node is selected
  final ValueChanged<Node<T>?>? onNodeSelected;

  /// Callback when a connection is tapped
  final ValueChanged<Connection?>? onConnectionTap;

  /// Callback when a connection is selected
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

  /// Convenience method to create a viewer with data pre-loaded
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
