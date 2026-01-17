import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';

import '../connections/connection.dart';
import '../editor/controller/node_flow_controller.dart';
import '../editor/drag_session.dart';
import '../editor/element_scope.dart';
import '../extensions/lod/detail_visibility.dart';
import '../extensions/lod/lod_extension.dart';
import '../extensions/autopan/auto_pan_extension.dart';
import '../editor/resizer_widget.dart';
import '../editor/themes/cursor_theme.dart';
import '../editor/themes/node_flow_theme.dart';
import '../editor/unbounded_widgets.dart';
import '../graph/coordinates.dart';
import '../ports/port.dart';
import '../ports/port_widget.dart';
import 'node.dart';
import 'node_shape.dart';

/// A container widget that handles the structural/positioning aspects of a node.
///
/// This widget is responsible for:
/// - Positioning the node at its visual position
/// - Sizing the node based on its size observable
/// - Handling gesture callbacks (tap, drag, context menu, hover)
/// - Rendering ports at appropriate positions
/// - Rendering resize handles when selected and resizable
///
/// The [child] widget is injected and represents the visual content of the node,
/// which is typically built by [NodeWidget].
///
/// This separation allows for:
/// - Cleaner dual-layer optimization (static vs active layers)
/// - Better separation of concerns
/// - Easier creation of proxy nodes for smooth drag rendering
class NodeContainer<T> extends StatelessWidget {
  const NodeContainer({
    super.key,
    required this.node,
    required this.controller,
    required this.child,
    this.shape,
    this.connections = const [],
    this.portBuilder,
    this.onTap,
    this.onDoubleTap,
    this.onContextMenu,
    this.onMouseEnter,
    this.onMouseLeave,
    this.onPortTap,
    this.onPortHover,
    this.onPortContextMenu,
    this.portSnapDistance = 8.0,
  });

  /// The node data model.
  final Node<T> node;

  /// The controller for node operations.
  final NodeFlowController<T, dynamic> controller;

  /// The visual content of the node (built by NodeWidget or custom builder).
  final Widget child;

  /// Optional shape for the node (used for port positioning).
  final NodeShape? shape;

  /// List of connections for determining which ports are connected.
  final List<Connection> connections;

  /// Optional builder for customizing individual port widgets.
  final PortBuilder<T>? portBuilder;

  /// Callback invoked when the node is tapped.
  final VoidCallback? onTap;

  /// Callback invoked when the node is double-tapped.
  final VoidCallback? onDoubleTap;

  /// Callback invoked when the node is right-clicked (context menu).
  final void Function(ScreenPosition screenPosition)? onContextMenu;

  /// Callback invoked when the mouse enters the node bounds.
  final VoidCallback? onMouseEnter;

  /// Callback invoked when the mouse leaves the node bounds.
  final VoidCallback? onMouseLeave;

  /// Callback invoked when a port is tapped.
  final void Function(String nodeId, String portId, bool isOutput)? onPortTap;

  /// Callback invoked when a port hover state changes.
  final void Function(String nodeId, String portId, bool isHover)? onPortHover;

  /// Callback invoked when a port is right-clicked (context menu).
  final void Function(
    String nodeId,
    String portId,
    ScreenPosition screenPosition,
  )?
  onPortContextMenu;

  /// Distance around ports that expands the hit area for easier targeting.
  final double portSnapDistance;

  @override
  Widget build(BuildContext context) {
    final theme = controller.theme ?? NodeFlowTheme.light;

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

        // Derive cursor from interaction state
        final cursor = theme.cursorTheme.cursorFor(
          ElementType.node,
          controller.interaction,
          isLocked: node.locked,
        );

        // Get LOD visibility state - default to full visibility if not configured
        final lodVisibility =
            controller.lod?.currentVisibility ?? DetailVisibility.full;

        // Show resize handles when node is selected, resizable, LOD allows,
        // AND behavior mode permits updates (resize is a form of modification)
        final showResizer =
            isSelected &&
            node.isResizable &&
            lodVisibility.showResizeHandles &&
            controller.behavior.canUpdate;

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
                    // Session for canvas locking during drag
                    createSession: () =>
                        controller.createSession(DragSessionType.nodeDrag),
                    // Drag lifecycle - unified for all node types
                    // Check both node lock state AND behavior mode
                    isDraggable: !node.locked && controller.behavior.canDrag,
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
                    // Background/foreground layers use translucent for hit testing
                    hitTestBehavior: HitTestBehavior.opaque,
                    // Autopan configuration
                    autoPan: controller.autoPan,
                    getViewportBounds: () =>
                        controller.viewportScreenBounds.rect,
                    onAutoPan: (delta) {
                      final zoom = controller.viewport.zoom;
                      controller.panBy(
                        ScreenOffset(
                          Offset(-delta.dx * zoom, -delta.dy * zoom),
                        ),
                      );
                    },
                    child: child,
                  ),
                ),

                // Input ports (only when LOD allows and ports exist)
                if (lodVisibility.showPorts && node.inputPorts.isNotEmpty)
                  ...node.inputPorts.map(
                    (port) => _buildPort(context, port, false),
                  ),

                // Output ports (only when LOD allows and ports exist)
                if (lodVisibility.showPorts && node.outputPorts.isNotEmpty)
                  ...node.outputPorts.map(
                    (port) => _buildPort(context, port, true),
                  ),

                // Resize handles (shown when selected and resizable)
                if (showResizer)
                  Positioned.fill(
                    child: ResizerWidget(
                      handleSize: theme.resizerTheme.handleSize,
                      color: theme.resizerTheme.color,
                      borderColor: theme.resizerTheme.borderColor,
                      borderWidth: theme.resizerTheme.borderWidth,
                      snapDistance: theme.resizerTheme.snapDistance,
                      isResizing: controller.interaction.isResizing,
                      onResizeStart: (handle, globalPos) =>
                          controller.startResize(node.id, handle, globalPos),
                      onResizeUpdate: (globalPos) =>
                          controller.updateResize(globalPos),
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

  Widget _buildPort(BuildContext context, Port port, bool isOutput) {
    final theme = controller.theme ?? NodeFlowTheme.light;
    final portTheme = theme.portTheme;
    final isConnected = _isPortConnected(port.id, isOutput);

    // Get the visual position from the Node model
    final effectivePortSize = port.size ?? portTheme.size;
    final visualPosition = node.getVisualPortOrigin(
      port.id,
      portSize: effectivePortSize,
      shape: shape,
    );

    // Calculate node bounds for port positioning
    final nodeBounds = Rect.fromLTWH(
      node.position.value.dx,
      node.position.value.dy,
      node.size.value.width,
      node.size.value.height,
    );

    // Port widget cascade:
    // 1. port.buildWidget (per-instance builder)
    // 2. portBuilder (global editor builder)
    // 3. PortWidget (framework default)
    final portWidget =
        port.buildWidget(context, node) ??
        (portBuilder != null
            ? portBuilder!(context, node, port)
            : PortWidget<T>(
                port: port,
                theme: portTheme,
                isConnected: isConnected,
                snapDistance: portSnapDistance,
                controller: controller,
                nodeId: node.id,
                isOutput: isOutput,
                nodeBounds: nodeBounds,
                onTap: onPortTap != null
                    ? (p) => onPortTap!(node.id, p.id, isOutput)
                    : null,
                onHover: onPortHover != null
                    ? (data) => onPortHover!(node.id, data.$1.id, data.$2)
                    : null,
                onContextMenu: onPortContextMenu != null
                    ? (pos) => onPortContextMenu!(node.id, port.id, pos)
                    : null,
              ));

    return Positioned(
      left: visualPosition.dx,
      top: visualPosition.dy,
      child: portWidget,
    );
  }

  /// Checks if a port is connected by examining the connections list.
  bool _isPortConnected(String portId, bool isOutput) {
    return connections.any((connection) {
      if (isOutput) {
        return connection.sourceNodeId == node.id &&
            connection.sourcePortId == portId;
      } else {
        return connection.targetNodeId == node.id &&
            connection.targetPortId == portId;
      }
    });
  }
}
