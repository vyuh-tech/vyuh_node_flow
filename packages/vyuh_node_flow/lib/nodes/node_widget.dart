import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';

import '../connections/connection.dart';
import '../graph/node_flow_theme.dart';
import '../nodes/node.dart';
import '../nodes/node_shape.dart';
import '../nodes/node_shape_clipper.dart';
import '../nodes/node_shape_painter.dart';
import '../nodes/node_theme.dart';
import '../ports/port.dart';
import '../ports/port_widget.dart';

/// A unified node widget that handles positioning, rendering, and interactions.
///
/// This widget is the primary UI component for rendering nodes in the flow graph.
/// It handles:
/// * Positioning and sizing based on [Node] state
/// * Rendering ports at appropriate positions
/// * Applying theme-based or custom styling
/// * Reactive updates via MobX observables
///
/// Note: Tap, double-tap, context menu, and hover events are handled at the
/// Listener level in NodeFlowEditor using hit testing. This ensures events
/// work correctly regardless of node position on the canvas.
///
/// The widget supports two usage patterns:
/// 1. **Custom content**: Provide a [child] widget for complete control over node appearance
/// 2. **Default style**: Use [NodeWidget.defaultStyle] for standard node rendering
///
/// Appearance can be customized per-node by providing optional appearance parameters
/// which will override values from the theme.
///
/// Example with custom content:
/// ```dart
/// NodeWidget<MyData>(
///   node: myNode,
///   child: MyCustomNodeContent(data: myNode.data),
///   backgroundColor: Colors.blue.shade50,
/// )
/// ```
///
/// Example with default style:
/// ```dart
/// NodeWidget<MyData>.defaultStyle(
///   node: myNode,
///   connections: connections,
///   onPortTap: handlePortTap,
/// )
/// ```
///
/// See also:
/// * [Node], the data model for nodes
/// * [NodeTheme], which defines default styling
/// * [PortWidget], which renders individual ports
class NodeWidget<T> extends StatelessWidget {
  /// Creates a node widget with optional custom content.
  ///
  /// Parameters:
  /// * [node] - The node data model to render
  /// * [child] - Optional custom widget to display as node content
  /// * [shape] - Optional shape for the node (renders shaped node instead of rectangle)
  /// * [connections] - List of connections for determining port connection state
  /// * [onPortTap] - Callback when a port is tapped
  /// * [onPortHover] - Callback when a port is hovered
  /// * [hoveredPortInfo] - Information about the currently hovered port
  /// * [backgroundColor] - Custom background color (overrides theme)
  /// * [selectedBackgroundColor] - Custom selected background color (overrides theme)
  /// * [borderColor] - Custom border color (overrides theme)
  /// * [selectedBorderColor] - Custom selected border color (overrides theme)
  /// * [borderWidth] - Custom border width (overrides theme)
  /// * [selectedBorderWidth] - Custom selected border width (overrides theme)
  /// * [borderRadius] - Custom border radius (overrides theme)
  /// * [padding] - Custom padding (overrides theme)
  /// * [portBuilder] - Optional builder for customizing port widgets
  const NodeWidget({
    super.key,
    required this.node,
    this.child,
    this.shape,
    this.connections = const [],
    this.onPortTap,
    this.onPortHover,
    this.hoveredPortInfo,
    this.backgroundColor,
    this.selectedBackgroundColor,
    this.borderColor,
    this.selectedBorderColor,
    this.borderWidth,
    this.selectedBorderWidth,
    this.borderRadius,
    this.padding,
    this.portBuilder,
  });

  /// Creates a node widget with default content layout.
  ///
  /// This constructor uses the standard node rendering which displays
  /// the node type as a title and node ID as content.
  ///
  /// Parameters are the same as the default constructor, except [child]
  /// is always null.
  const NodeWidget.defaultStyle({
    super.key,
    required this.node,
    this.shape,
    this.connections = const [],
    this.onPortTap,
    this.onPortHover,
    this.hoveredPortInfo,
    this.backgroundColor,
    this.selectedBackgroundColor,
    this.borderColor,
    this.selectedBorderColor,
    this.borderWidth,
    this.selectedBorderWidth,
    this.borderRadius,
    this.padding,
    this.portBuilder,
  }) : child = null;

  /// The node data model to render.
  final Node<T> node;

  /// Optional custom widget to display as node content.
  ///
  /// When null, default content (type and ID) is displayed.
  final Widget? child;

  /// Optional shape for the node.
  ///
  /// When null, the node is rendered as a rectangle.
  /// When provided, the node is rendered using the shape's path and visual properties.
  final NodeShape? shape;

  /// List of connections for determining which ports are connected.
  final List<Connection> connections;

  /// Callback invoked when a port is tapped.
  ///
  /// Parameters: (nodeId, portId, isOutput)
  final void Function(String nodeId, String portId, bool isOutput)? onPortTap;

  /// Callback invoked when a port hover state changes.
  ///
  /// Parameters: (nodeId, portId, isHover)
  final void Function(String nodeId, String portId, bool isHover)? onPortHover;

  /// Information about the currently hovered port.
  ///
  /// Used for highlighting ports during connection creation.
  final ({String nodeId, String portId, bool isOutput})? hoveredPortInfo;

  /// Custom background color.
  ///
  /// Overrides the theme's default background color when provided.
  final Color? backgroundColor;

  /// Custom background color for selected state.
  ///
  /// Overrides the theme's selected background color when provided.
  final Color? selectedBackgroundColor;

  /// Custom border color.
  ///
  /// Overrides the theme's default border color when provided.
  final Color? borderColor;

  /// Custom border color for selected state.
  ///
  /// Overrides the theme's selected border color when provided.
  final Color? selectedBorderColor;

  /// Custom border width.
  ///
  /// Overrides the theme's default border width when provided.
  final double? borderWidth;

  /// Custom border width for selected state.
  ///
  /// Overrides the theme's selected border width when provided.
  final double? selectedBorderWidth;

  /// Custom border radius.
  ///
  /// Overrides the theme's border radius when provided.
  final BorderRadius? borderRadius;

  /// Custom padding inside the node.
  ///
  /// Overrides the theme's padding when provided.
  final EdgeInsets? padding;

  /// Optional builder for customizing individual port widgets.
  ///
  /// When provided, this builder is called for each port and receives:
  /// - [node] - The node containing the port
  /// - [port] - The port to render
  /// - [isOutput] - Whether the port is an output port
  /// - [isConnected] - Whether the port has any connections
  /// - [isHighlighted] - Whether the port is being hovered during connection drag
  ///
  /// The returned widget replaces the default [PortWidget].
  final PortBuilder<T>? portBuilder;

  @override
  Widget build(BuildContext context) {
    final theme =
        Theme.of(context).extension<NodeFlowTheme>() ?? NodeFlowTheme.light;
    final nodeTheme = theme.nodeTheme;

    return Observer(
      builder: (context) {
        // Use visual position for rendering
        final position = node.visualPosition.value;
        final isSelected = node.isSelected;
        final size = node.size.value;

        // Note: Tap, double-tap, context menu, and hover events are handled
        // at the Listener level in NodeFlowEditor using hit testing. This
        // ensures events work even when nodes are dragged outside the viewport.
        return Positioned(
          left: position.dx,
          top: position.dy,
          child: SizedBox(
            width: size.width,
            height: size.height,
            child: Stack(
              clipBehavior: Clip.none, // Allow ports to overflow the bounds
              children: [
                // Main node visual - either shaped or rectangular
                Positioned.fill(
                  child: shape != null
                      ? _buildShapedNode(nodeTheme, isSelected)
                      : _buildRectangularNode(nodeTheme, isSelected),
                ),

                // Input ports (positioned on edges of padded container)
                ...node.inputPorts.map(
                  (port) => _buildPort(context, port, false, nodeTheme),
                ),

                // Output ports (positioned on edges of padded container)
                ...node.outputPorts.map(
                  (port) => _buildPort(context, port, true, nodeTheme),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Color _getNodeBackgroundColor(NodeTheme nodeTheme, bool isSelected) {
    if (isSelected) {
      return selectedBackgroundColor ??
          backgroundColor ??
          nodeTheme.selectedBackgroundColor;
    } else {
      return backgroundColor ?? nodeTheme.backgroundColor;
    }
  }

  Color _getNodeBorderColor(NodeTheme nodeTheme, bool isSelected) {
    if (isSelected) {
      return selectedBorderColor ??
          borderColor ??
          nodeTheme.selectedBorderColor;
    } else {
      return borderColor ?? nodeTheme.borderColor;
    }
  }

  double _getNodeBorderWidth(NodeTheme nodeTheme, bool isSelected) {
    if (isSelected) {
      return selectedBorderWidth ??
          borderWidth ??
          nodeTheme.selectedBorderWidth;
    } else {
      return borderWidth ?? nodeTheme.borderWidth;
    }
  }

  Widget _buildNodeContent(NodeTheme nodeTheme) {
    // Use custom child if provided, otherwise fall back to default content
    if (child != null) {
      return child!;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Node title - always visible
        Text(
          node.type,
          style: nodeTheme.titleStyle,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),

        const SizedBox(height: 4),

        // Simple node info
        Text(
          node.id,
          style: nodeTheme.contentStyle,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  Widget _buildPort(
    BuildContext context,
    Port port,
    bool isOutput,
    NodeTheme nodeTheme,
  ) {
    final theme =
        Theme.of(context).extension<NodeFlowTheme>() ?? NodeFlowTheme.light;
    final portTheme = theme.portTheme;
    final isConnected = _isPortConnected(port.id, isOutput);
    final isHighlighted = _isPortHighlighted(port.id, isOutput);

    // Get the visual position from the Node model
    // Use cascade: port.size → theme.size
    final effectivePortSize = port.size ?? portTheme.size;
    final visualPosition = node.getVisualPortPosition(
      port.id,
      portSize: effectivePortSize,
      shape: shape,
    );

    // Use custom port builder if provided
    final portWidget = portBuilder != null
        ? portBuilder!(
            context,
            node,
            port,
            isOutput,
            isConnected,
            isHighlighted,
          )
        : PortWidget(
            port: port,
            theme: portTheme,
            isConnected: isConnected,
            isHighlighted: isHighlighted,
            onTap: onPortTap != null
                ? (p) => onPortTap!(node.id, p.id, isOutput)
                : null,
            onHover: onPortHover != null
                ? (data) => onPortHover!(node.id, data.$1.id, data.$2)
                : null,
          );

    return Positioned(
      left: visualPosition.dx,
      top: visualPosition.dy,
      child: portWidget,
    );
  }

  /// Checks if a port is connected by examining the connections list.
  ///
  /// Parameters:
  /// * [portId] - The ID of the port to check
  /// * [isOutput] - Whether the port is an output port
  ///
  /// Returns true if the port is connected to any other port.
  bool _isPortConnected(String portId, bool isOutput) {
    return connections.any((connection) {
      if (isOutput) {
        // For output ports, check if this port is the source of any connection
        return connection.sourceNodeId == node.id &&
            connection.sourcePortId == portId;
      } else {
        // For input ports, check if this port is the target of any connection
        return connection.targetNodeId == node.id &&
            connection.targetPortId == portId;
      }
    });
  }

  /// Checks if a port is highlighted (being hovered during connection drag).
  ///
  /// Parameters:
  /// * [portId] - The ID of the port to check
  /// * [isOutput] - Whether the port is an output port
  ///
  /// Returns true if this port is currently being hovered as a potential
  /// connection target during a connection drag operation.
  bool _isPortHighlighted(String portId, bool isOutput) {
    return hoveredPortInfo?.nodeId == node.id &&
        hoveredPortInfo?.portId == portId &&
        hoveredPortInfo?.isOutput == isOutput;
  }

  /// Builds a shaped node using CustomPaint and ClipPath.
  ///
  /// This method renders nodes with custom shapes (circle, diamond, etc.)
  /// by painting the shape background and border, then clipping the content
  /// to the shape's boundaries.
  ///
  /// The shape fills the entire node bounds. Ports are positioned at the
  /// shape boundary (which equals node boundary) and extend inward.
  Widget _buildShapedNode(NodeTheme nodeTheme, bool isSelected) {
    return CustomPaint(
      painter: NodeShapePainter(
        shape: shape!,
        backgroundColor: _getNodeBackgroundColor(nodeTheme, isSelected),
        borderColor: _getNodeBorderColor(nodeTheme, isSelected),
        borderWidth: _getNodeBorderWidth(nodeTheme, isSelected),
        size: node.size.value,
      ),
      child: ClipPath(
        clipper: NodeShapeClipper(shape: shape!),
        child: Center(child: _buildNodeContent(nodeTheme)),
      ),
    );
  }

  /// Builds a rectangular node using a Container.
  ///
  /// This is the default node rendering method that uses a Container
  /// with BoxDecoration for rectangular nodes. The container fills the
  /// entire node bounds. Ports are positioned at the node boundary.
  Widget _buildRectangularNode(NodeTheme nodeTheme, bool isSelected) {
    return Container(
      decoration: BoxDecoration(
        color: _getNodeBackgroundColor(nodeTheme, isSelected),
        border: Border.all(
          color: _getNodeBorderColor(nodeTheme, isSelected),
          width: _getNodeBorderWidth(nodeTheme, isSelected),
        ),
        borderRadius: borderRadius ?? nodeTheme.borderRadius,
      ),
      child: _buildNodeContent(nodeTheme),
    );
  }
}
