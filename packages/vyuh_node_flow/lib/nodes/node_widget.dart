import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';

import '../connections/connection.dart';
import '../graph/coordinates.dart';
import '../graph/cursor_theme.dart';
import '../graph/node_flow_controller.dart';
import '../graph/node_flow_theme.dart';
import '../nodes/node.dart';
import '../nodes/node_shape.dart';
import '../nodes/node_shape_clipper.dart';
import '../nodes/node_shape_painter.dart';
import '../nodes/node_theme.dart';
import '../ports/port.dart';
import '../ports/port_widget.dart';
import '../shared/element_scope.dart';
import '../shared/resizer_widget.dart';
import '../shared/unbounded_widgets.dart';

/// A unified node widget that handles positioning, rendering, and interactions
/// for both regular nodes and annotations.
///
/// This widget is the primary UI component for rendering all graph elements.
/// It handles:
/// * Positioning and sizing based on [Node] state
/// * Rendering ports at appropriate positions (for nodes in middle layer)
/// * Applying theme-based or custom styling
/// * Reactive updates via MobX observables
/// * Gesture handling (tap, double-tap, drag, context menu, hover)
/// * Resize handles for resizable elements (annotations)
/// * Self-rendering nodes via [Node.buildWidget]
///
/// Gesture handling is delegated to [ElementScope] which provides:
/// * Consistent drag lifecycle management
/// * Proper cleanup on widget disposal
/// * Guard clauses to prevent duplicate start/end calls
///
/// The widget supports three rendering modes:
/// 1. **Self-rendering**: When [Node.buildWidget] returns non-null, it's used directly
/// 2. **Custom content**: Provide a [child] widget for complete control over node appearance
/// 3. **Default style**: Use [NodeWidget.defaultStyle] for standard node rendering
///
/// ## Layer-Based Behavior
///
/// The widget automatically adjusts behavior based on [Node.layer]:
/// * **Background/Foreground**: Uses annotation drag methods and styling
/// * **Middle (default)**: Uses node drag methods and styling
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
/// * [ElementScope], which handles gesture lifecycle
/// * [ResizerWidget], which provides resize handles for resizable nodes
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
  /// * [backgroundColor] - Custom background color (overrides theme)
  /// * [selectedBackgroundColor] - Custom selected background color (overrides theme)
  /// * [borderColor] - Custom border color (overrides theme)
  /// * [selectedBorderColor] - Custom selected border color (overrides theme)
  /// * [borderWidth] - Custom border width (overrides theme)
  /// * [selectedBorderWidth] - Custom selected border width (overrides theme)
  /// * [borderRadius] - Custom border radius (overrides theme)
  /// * [padding] - Custom padding (overrides theme)
  /// * [portBuilder] - Optional builder for customizing port widgets
  /// * [onTap] - Callback when node is tapped
  /// * [onDoubleTap] - Callback when node is double-tapped
  /// * [onContextMenu] - Callback when node is right-clicked
  /// * [onMouseEnter] - Callback when mouse enters node
  /// * [onMouseLeave] - Callback when mouse leaves node
  /// * [controller] - Controller for direct drag handling (required)
  const NodeWidget({
    super.key,
    required this.node,
    required this.controller,
    this.child,
    this.shape,
    this.connections = const [],
    this.onPortTap,
    this.onPortHover,
    this.onPortContextMenu,
    this.backgroundColor,
    this.selectedBackgroundColor,
    this.borderColor,
    this.selectedBorderColor,
    this.borderWidth,
    this.selectedBorderWidth,
    this.borderRadius,
    this.padding,
    this.portBuilder,
    this.onTap,
    this.onDoubleTap,
    this.onContextMenu,
    this.onMouseEnter,
    this.onMouseLeave,
    this.portSnapDistance = 8.0,
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
    required this.controller,
    this.shape,
    this.connections = const [],
    this.onPortTap,
    this.onPortHover,
    this.onPortContextMenu,
    this.backgroundColor,
    this.selectedBackgroundColor,
    this.borderColor,
    this.selectedBorderColor,
    this.borderWidth,
    this.selectedBorderWidth,
    this.borderRadius,
    this.padding,
    this.portBuilder,
    this.onTap,
    this.onDoubleTap,
    this.onContextMenu,
    this.onMouseEnter,
    this.onMouseLeave,
    this.portSnapDistance = 8.0,
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

  /// Controller for direct drag handling.
  ///
  /// The widget calls controller methods directly for:
  /// - Node drag operations (start, move, end)
  /// - Port connection drag operations (delegated to PortWidget)
  ///
  /// This eliminates callback chains and simplifies event handling.
  final NodeFlowController<T> controller;

  /// Callback invoked when a port is tapped.
  ///
  /// Parameters: (nodeId, portId, isOutput)
  final void Function(String nodeId, String portId, bool isOutput)? onPortTap;

  /// Callback invoked when a port hover state changes.
  ///
  /// Parameters: (nodeId, portId, isHover)
  final void Function(String nodeId, String portId, bool isHover)? onPortHover;

  /// Callback invoked when a port is right-clicked (context menu).
  ///
  /// Parameters: (nodeId, portId, isOutput, globalPosition)
  final void Function(
    String nodeId,
    String portId,
    bool isOutput,
    Offset globalPosition,
  )?
  onPortContextMenu;

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

  /// Callback invoked when the node is tapped.
  final VoidCallback? onTap;

  /// Callback invoked when the node is double-tapped.
  final VoidCallback? onDoubleTap;

  /// Callback invoked when the node is right-clicked (context menu).
  ///
  /// The [Offset] parameter is the global position of the tap.
  final void Function(Offset globalPosition)? onContextMenu;

  /// Callback invoked when the mouse enters the node bounds.
  final VoidCallback? onMouseEnter;

  /// Callback invoked when the mouse leaves the node bounds.
  final VoidCallback? onMouseLeave;

  /// Distance around ports that expands the hit area for easier targeting.
  final double portSnapDistance;

  /// Checks if this node is in an annotation layer (background or foreground).
  bool get _isAnnotationLayer => node.layer != NodeRenderLayer.middle;

  @override
  Widget build(BuildContext context) {
    // Use controller's theme as single source of truth
    final theme = controller.theme ?? NodeFlowTheme.light;
    final nodeTheme = theme.nodeTheme;

    return Observer(
      builder: (context) {
        // Check visibility first - return nothing if hidden
        if (!node.isVisible) {
          return const SizedBox.shrink();
        }

        // Use visual position for rendering
        final position = node.visualPosition.value;
        final isSelected = node.isSelected;
        final size = node.size.value;

        // Derive cursor from interaction state based on layer
        final cursor = theme.cursorTheme.cursorFor(
          _isAnnotationLayer ? ElementType.annotation : ElementType.node,
          controller.interaction,
          isLocked: node.locked,
        );

        // Determine if resize handles should be shown
        final showResizeHandles = isSelected && node.isResizable;

        return Positioned(
          left: position.dx,
          top: position.dy,
          child: UnboundedSizedBox(
            width: size.width,
            height: size.height,
            child: UnboundedStack(
              clipBehavior: Clip.none, // Allow ports/handles to overflow
              children: [
                // Main node visual with gesture handling via ElementScope
                Positioned.fill(
                  child: ElementScope(
                    // Drag lifecycle - unified for all node types (including GroupNode, CommentNode)
                    isDraggable: !node.locked,
                    onDragStart: (_) => controller.startNodeDrag(node.id),
                    onDragUpdate: (details) =>
                        controller.moveNodeDrag(details.delta),
                    onDragEnd: (_) => controller.endNodeDrag(),
                    // Interaction callbacks
                    onTap: onTap,
                    onDoubleTap: onDoubleTap,
                    onContextMenu: onContextMenu,
                    onMouseEnter: onMouseEnter,
                    onMouseLeave: onMouseLeave,
                    cursor: cursor,
                    // Background/foreground layers use translucent for hit testing to allow clicks through transparent areas
                    hitTestBehavior: _isAnnotationLayer
                        ? HitTestBehavior.translucent
                        : HitTestBehavior.opaque,
                    // Autopan configuration
                    autoPan: controller.config.autoPan.value,
                    getViewportBounds: () =>
                        controller.viewportScreenBounds.rect,
                    onAutoPan: (delta) {
                      // Pan viewport (convert graph units to screen units)
                      final zoom = controller.viewport.zoom;
                      controller.panBy(
                        ScreenOffset(
                          Offset(-delta.dx * zoom, -delta.dy * zoom),
                        ),
                      );
                    },
                    // Node visual - check for self-rendering first
                    child: _buildNodeVisual(context, nodeTheme, isSelected),
                  ),
                ),

                // Input ports (positioned on edges - only for middle layer nodes)
                if (!_isAnnotationLayer)
                  ...node.inputPorts.map(
                    (port) => _buildPort(context, port, false, nodeTheme),
                  ),

                // Output ports (positioned on edges - only for middle layer nodes)
                if (!_isAnnotationLayer)
                  ...node.outputPorts.map(
                    (port) => _buildPort(context, port, true, nodeTheme),
                  ),

                // Resize handles (only when selected and resizable)
                if (showResizeHandles)
                  Positioned.fill(
                    child: ResizerWidget(
                      handleSize: theme.resizerTheme.handleSize,
                      color: theme.resizerTheme.color,
                      borderColor: theme.resizerTheme.borderColor,
                      borderWidth: theme.resizerTheme.borderWidth,
                      snapDistance: theme.resizerTheme.snapDistance,
                      onResizeStart: (handle) =>
                          controller.startResize(node.id, handle),
                      onResizeUpdate: (delta) => controller.updateResize(delta),
                      onResizeEnd: () => controller.endResize(),
                      child: const SizedBox.expand(),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  /// Builds the node visual based on rendering mode.
  ///
  /// Priority:
  /// 1. Self-rendering: [node.buildWidget] returns non-null
  /// 2. Custom content: [child] parameter is provided
  /// 3. Default rendering: Shape or rectangular based on [shape]
  Widget _buildNodeVisual(
    BuildContext context,
    NodeTheme nodeTheme,
    bool isSelected,
  ) {
    // Check if node provides its own widget (annotations, custom nodes)
    final selfRenderedWidget = node.buildWidget(context);
    if (selfRenderedWidget != null) {
      // For self-rendering nodes (annotations), apply selection styling
      return _wrapWithSelectionStyling(context, selfRenderedWidget, isSelected);
    }

    // Use custom child or default rendering
    if (shape != null) {
      return _buildShapedNode(nodeTheme, isSelected);
    } else {
      return _buildRectangularNode(nodeTheme, isSelected);
    }
  }

  /// Wraps self-rendered content with selection styling for annotations.
  Widget _wrapWithSelectionStyling(
    BuildContext context,
    Widget content,
    bool isSelected,
  ) {
    final theme = controller.theme ?? NodeFlowTheme.light;
    final annotationTheme = theme.annotationTheme;
    final borderWidth = annotationTheme.borderWidth;

    // Determine border color and background color based on state
    // When editing, use transparent border for seamless editing experience
    Color borderColor = Colors.transparent;
    Color? backgroundColor;

    if (!node.isEditing && isSelected) {
      borderColor = annotationTheme.selectionBorderColor;
      backgroundColor = annotationTheme.selectionBackgroundColor;
    }

    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: borderColor, width: borderWidth),
        borderRadius: annotationTheme.borderRadius,
        color: backgroundColor,
      ),
      child: content,
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
    // Use controller's theme as single source of truth
    final theme = controller.theme ?? NodeFlowTheme.light;
    final portTheme = theme.portTheme;
    final isConnected = _isPortConnected(port.id, isOutput);

    // Get the visual position from the Node model
    // Use cascade: port.size → theme.size
    final effectivePortSize = port.size ?? portTheme.size;
    final visualPosition = node.getVisualPortOrigin(
      port.id,
      portSize: effectivePortSize,
      shape: shape,
    );

    // Calculate node bounds once for both custom and default port builders
    final nodeBounds = Rect.fromLTWH(
      node.position.value.dx,
      node.position.value.dy,
      node.size.value.width,
      node.size.value.height,
    );

    // Use custom port builder if provided
    // Note: Highlighting is handled via Port.highlighted observable
    final portWidget = portBuilder != null
        ? portBuilder!(
            context,
            controller,
            node,
            port,
            isOutput,
            isConnected,
            nodeBounds,
          )
        : PortWidget<T>(
            port: port,
            theme: portTheme,
            isConnected: isConnected,
            snapDistance: portSnapDistance,
            // Controller for connection drag handling
            controller: controller,
            nodeId: node.id,
            isOutput: isOutput,
            nodeBounds: nodeBounds,
            // Event callbacks for external handling
            onTap: onPortTap != null
                ? (p) => onPortTap!(node.id, p.id, isOutput)
                : null,
            onHover: onPortHover != null
                ? (data) => onPortHover!(node.id, data.$1.id, data.$2)
                : null,
            onContextMenu: onPortContextMenu != null
                ? (pos) => onPortContextMenu!(node.id, port.id, isOutput, pos)
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
