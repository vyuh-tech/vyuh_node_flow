import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';

import '../editor/controller/node_flow_controller.dart';
import '../editor/drag_session.dart';
import '../editor/element_scope.dart';
import '../extensions/lod/lod_extension.dart';
import '../extensions/autopan/auto_pan_extension.dart';
import '../editor/themes/cursor_theme.dart';
import '../editor/themes/node_flow_theme.dart';
import '../editor/unbounded_widgets.dart';
import '../graph/coordinates.dart';
import '../nodes/node.dart';
import '../ports/port.dart';
import '../ports/port_theme.dart';
import 'port_shape_widget.dart';

/// Builds a custom port widget for a node.
///
/// This builder is called for each port when rendering nodes, allowing
/// complete customization of port appearance and behavior.
///
/// ## Type Parameters
/// - `T`: The type of data stored in nodes
///
/// ## Minimal Signature
/// The builder receives only essential parameters. Use helper methods
/// to derive additional information:
/// - `node.isOutputPort(port)` - check if port is an output
/// - `node.getBounds()` - get node bounds as Rect
/// - Port highlighting is observable via `port.highlighted`
///
/// Port data can be derived from node data. For example, store port
/// configuration in your node data type: `node.data.portConfig[port.id]`
///
/// ## Parameters
/// - [context]: The build context
/// - [node]: The node containing this port (provides typed data via node.data)
/// - [port]: The port being rendered
///
/// ## Example
/// ```dart
/// PortBuilder<MyNodeData> builder = (context, node, port) {
///   final isOutput = node.isOutputPort(port);
///   // Derive port-specific data from node.data
///   final portConfig = node.data.ports[port.id];
///
///   return Container(
///     width: 12,
///     height: 12,
///     decoration: BoxDecoration(
///       color: portConfig?.color ?? (isOutput ? Colors.green : Colors.blue),
///       shape: BoxShape.circle,
///     ),
///   );
/// };
/// ```
typedef PortBuilder<T> =
    Widget Function(BuildContext context, Node<T> node, Port port);

/// Widget for rendering a port on a node.
///
/// The [PortWidget] displays a port with its shape, color, and optional label.
/// It supports property overrides at both widget and model levels.
///
/// ## Property Cascade (lowest to highest priority)
///
/// Properties are resolved in this order of precedence:
/// 1. Theme values (from [PortTheme]) - lowest priority
/// 2. Widget-level overrides (constructor parameters)
/// 3. Port theme values (from [Port.theme]) - highest priority
///
/// For example, port color is resolved as:
/// - `port.theme?.color` → widget `color` → `theme.color`
///
/// Example with overrides:
/// ```dart
/// PortWidget(
///   port: myPort, // port.size = 12.0 takes precedence
///   theme: PortTheme.light,
///   color: Colors.blue, // Override idle color
///   connectedColor: Colors.green, // Override connected color
/// )
/// ```
class PortWidget<T> extends StatefulWidget {
  const PortWidget({
    super.key,
    required this.port,
    required this.theme,
    required this.controller,
    required this.nodeId,
    required this.isOutput,
    required this.nodeBounds,
    this.isConnected = false,
    this.onTap,
    this.onDoubleTap,
    this.onContextMenu,
    this.onHover,
    this.snapDistance = 8.0,
    // Property overrides (widget level)
    this.size,
    this.color,
    this.connectedColor,
    this.highlightColor,
    this.highlightBorderColor,
    this.borderColor,
    this.borderWidth,
  });

  final Port port;
  final PortTheme theme;
  final bool isConnected;

  /// Controller for connection drag handling.
  final NodeFlowController<T, dynamic> controller;

  /// The ID of the node containing this port.
  final String nodeId;

  /// Whether this is an output port.
  final bool isOutput;

  /// The bounds of the parent node in graph coordinates (for connection start).
  final Rect nodeBounds;

  /// Callback invoked when the port is tapped.
  final ValueChanged<Port>? onTap;

  /// Callback invoked when the port is double-tapped.
  final VoidCallback? onDoubleTap;

  /// Callback invoked when the port is right-clicked (context menu).
  /// The [screenPosition] is in screen/global coordinates for menu positioning.
  final void Function(ScreenPosition screenPosition)? onContextMenu;

  /// Callback invoked when hover state changes.
  final ValueChanged<(Port, bool)>? onHover;

  /// Distance around the port that expands the hit area for easier targeting.
  final double snapDistance;

  // Optional property overrides (widget level) - if null, uses model or theme values

  /// Override for the port size.
  /// Resolution: port.size → widget.size → theme.size
  final Size? size;

  /// Override for the idle port color.
  final Color? color;

  /// Override for the connected port color.
  final Color? connectedColor;

  /// Override for the highlight fill color (when port is highlighted during drag).
  final Color? highlightColor;

  /// Override for the highlight border color.
  final Color? highlightBorderColor;

  /// Override for the border color.
  final Color? borderColor;

  /// Override for the border width.
  final double? borderWidth;

  @override
  State<PortWidget<T>> createState() => _PortWidgetState<T>();
}

class _PortWidgetState<T> extends State<PortWidget<T>> {
  bool _isHovered = false;
  bool _isDragging = false;

  /// Offset between pointer position (in graph coords) and endpoint at drag start.
  /// Used to calculate endpoint position from absolute pointer position.
  Offset _pointerToEndpointOffset = Offset.zero;

  void _handleHoverChange(bool isHovered) {
    // Suppress hover effects when connection creation is disabled (preview/present modes).
    // In these modes, port hover feedback is misleading since connections can't be created.
    if (!widget.controller.behavior.canCreate) {
      if (_isHovered) {
        // Clear hover state when transitioning to non-design mode
        setState(() => _isHovered = false);
      }
      return;
    }

    // Suppress hover effects during viewport pan/zoom to prevent stale highlights.
    // When the canvas is being panned, the mouse might pass over ports but the
    // onExit event may not fire properly, leaving stale hover states.
    if (widget.controller.interaction.isViewportDragging) {
      // If viewport is being dragged and we're trying to set hover to true, ignore it.
      // If we're trying to clear hover (isHovered = false), always allow it.
      if (isHovered) return;
    }

    setState(() => _isHovered = isHovered);
    widget.onHover?.call((widget.port, isHovered));
  }

  // ---------------------------------------------------------------------------
  // Connection Drag using PanGestureRecognizer
  // ---------------------------------------------------------------------------
  // Using standard pan gesture recognizer with DragStartBehavior.down

  void _handlePanStart(DragStartDetails details) {
    // Get the node for connection point calculation
    final node = widget.controller.getNode(widget.nodeId);
    if (node == null) return;

    // Calculate the connection start point
    final effectiveSize = _getPortSize();
    final shape = widget.controller.nodeShapeBuilder?.call(node);
    final startPoint = node.getConnectionPoint(
      widget.port.id,
      portSize: effectiveSize,
      shape: shape,
    );

    // Start the connection drag via controller's public API
    final result = widget.controller.startConnectionDrag(
      nodeId: widget.nodeId,
      portId: widget.port.id,
      isOutput: widget.isOutput,
      startPoint: startPoint,
      nodeBounds: widget.nodeBounds,
      initialScreenPosition: details.globalPosition,
    );

    if (result.allowed) {
      _isDragging = true;

      // Calculate and store the offset between pointer and endpoint at drag start.
      // This allows us to use absolute positioning during updates.
      final pointerGraphPos = widget.controller
          .screenToGraph(ScreenPosition(details.globalPosition))
          .offset;
      _pointerToEndpointOffset = startPoint - pointerGraphPos;
    }
  }

  void _handlePanUpdate(DragUpdateDetails details) {
    if (!_isDragging) return;

    final temp = widget.controller.temporaryConnection;
    if (temp == null) return;

    // Calculate endpoint from absolute pointer position, not deltas.
    // This prevents offset accumulation from port snapping and drift issues.
    final pointerGraphPos = widget.controller
        .screenToGraph(ScreenPosition(details.globalPosition))
        .offset;
    final newEndPoint = pointerGraphPos + _pointerToEndpointOffset;

    // Hit test to find target port for snapping
    final hitResult = widget.controller.hitTestPort(newEndPoint);

    // Get target node bounds if we have a hit
    Rect? targetNodeBounds;
    if (hitResult != null) {
      final targetNode = widget.controller.getNode(hitResult.nodeId);
      targetNodeBounds = targetNode?.getBounds();
    }

    // Update the connection drag
    widget.controller.updateConnectionDrag(
      graphPosition: newEndPoint,
      targetNodeId: hitResult?.nodeId,
      targetPortId: hitResult?.portId,
      targetNodeBounds: targetNodeBounds,
    );
  }

  void _handlePanEnd(DragEndDetails details) {
    if (!_isDragging) return;
    _isDragging = false;
    _pointerToEndpointOffset = Offset.zero;

    // Check if we're over a valid target port
    final temp = widget.controller.temporaryConnection;
    if (temp != null &&
        temp.targetNodeId != null &&
        temp.targetPortId != null) {
      // Complete the connection
      widget.controller.completeConnectionDrag(
        targetNodeId: temp.targetNodeId!,
        targetPortId: temp.targetPortId!,
      );
    } else {
      // Cancel - not over a valid target
      widget.controller.cancelConnectionDrag();
    }
    setState(() {});
  }

  void _handlePanCancel() {
    if (!_isDragging) return;
    _isDragging = false;
    _pointerToEndpointOffset = Offset.zero;
    widget.controller.cancelConnectionDrag();
    setState(() {});
  }

  /// Handles autopan during connection creation.
  ///
  /// Only pans the viewport - ElementScope handles updating the connection
  /// endpoint by calling onDragUpdate with clamped delta.
  void _handleAutoPan(Offset delta) {
    if (!_isDragging) return;

    // Pan viewport (convert graph units to screen units)
    final zoom = widget.controller.viewport.zoom;
    widget.controller.panBy(
      ScreenOffset(Offset(-delta.dx * zoom, -delta.dy * zoom)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final effectiveSize = _getPortSize();

    // UnboundedSizedBox/UnboundedStack needed because port size is small (e.g. 9x9)
    // but snap area extends beyond via negative positioning.
    //
    // IMPORTANT: RawGestureDetector is placed OUTSIDE the Observer to prevent
    // gesture recognizers from being recreated during MobX rebuilds. If the
    // recognizers are recreated mid-gesture, the active drag would be lost.
    return UnboundedSizedBox(
      width: effectiveSize.width,
      height: effectiveSize.height,
      child: UnboundedStack(
        clipBehavior: Clip.none,
        children: [
          // Observer only wraps the visual elements that need to react to state changes
          Observer(
            builder: (_) {
              // Access observables directly inside Observer for MobX tracking
              final isValidTarget = widget.port.highlighted.value;
              final isConnecting = widget.controller.isConnecting;

              // Port highlighting behavior depends on connection state:
              // - When connecting: Only highlight if valid target (validated by controller)
              //   This prevents misleading feedback on invalid ports
              // - When idle: Use hover for interactive feedback
              final showHighlight = isConnecting ? isValidTarget : _isHovered;

              return Stack(
                clipBehavior: Clip.none,
                children: [
                  // Marker shape - visual appearance reacts to hover and highlight state
                  Positioned.fill(
                    child: IgnorePointer(
                      child: PortShapeWidget(
                        shape:
                            widget.port.shape ??
                            widget.port.theme?.shape ??
                            widget.theme.shape,
                        position: widget.port.position,
                        size: effectiveSize,
                        color: _getPortColorFromHighlight(showHighlight),
                        borderColor: _getBorderColorFromHighlight(
                          showHighlight,
                        ),
                        borderWidth: _getBorderWidth(),
                      ),
                    ),
                  ),
                  // Port label (if enabled on port AND LOD state allows it)
                  // If LOD extension is not configured, default to showing labels
                  if (widget.port.showLabel &&
                      (widget.controller.lod?.showPortLabels ?? true))
                    _PortLabel(
                      port: widget.port,
                      theme: widget.theme,
                      size: effectiveSize,
                    ),
                ],
              );
            },
          ),
          // Gesture handling via ElementScope - provides:
          // - NonTrackpadPanGestureRecognizer for trackpad rejection
          // - Pointer ID tracking for robust drag handling
          // - Consistent lifecycle management (dispose cleanup, guard clauses)
          //
          // Using UnboundedPositioned to expand hit area beyond port bounds,
          // making it easier to target small ports.
          //
          // Observer.withBuiltChild ensures ElementScope's State persists across
          // cursor changes (RawGestureDetector reuses recognizers on rebuild).
          UnboundedPositioned(
            left: -widget.snapDistance,
            top: -widget.snapDistance,
            right: -widget.snapDistance,
            bottom: -widget.snapDistance,
            child: Observer.withBuiltChild(
              builder: (context, child) {
                // Derive cursor from interaction state
                final cursorTheme = Theme.of(
                  context,
                ).extension<NodeFlowTheme>()!.cursorTheme;

                // In preview/present modes, use canvas cursor for ports
                // since connection creation is disabled
                final cursor = widget.controller.behavior.canCreate
                    ? cursorTheme.cursorFor(
                        ElementType.port,
                        widget.controller.interaction,
                      )
                    : cursorTheme.canvasCursor;

                return ElementScope(
                  // Session for canvas locking during connection drag
                  createSession: () => widget.controller.createSession(
                    DragSessionType.connectionDrag,
                  ),
                  // Only allow dragging when connection creation is enabled
                  isDraggable: widget.controller.behavior.canCreate,
                  // Start immediately on pointer down for instant feedback
                  dragStartBehavior: DragStartBehavior.down,
                  // Connection drag lifecycle
                  onDragStart: _handlePanStart,
                  onDragUpdate: _handlePanUpdate,
                  onDragEnd: _handlePanEnd,
                  onDragCancel: _handlePanCancel,
                  // Interaction callbacks
                  onTap: widget.onTap != null
                      ? () => widget.onTap!(widget.port)
                      : null,
                  onDoubleTap: widget.onDoubleTap,
                  onContextMenu: widget.onContextMenu,
                  onMouseEnter: () => _handleHoverChange(true),
                  onMouseLeave: () => _handleHoverChange(false),
                  cursor: cursor,
                  // Autopan configuration for connection dragging
                  autoPan: widget.controller.autoPan,
                  getViewportBounds: () =>
                      widget.controller.viewportScreenBounds.rect,
                  onAutoPan: _handleAutoPan,
                  child: child,
                );
              },
              child: const SizedBox.expand(),
            ),
          ),
        ],
      ),
    );
  }

  /// Get the effective port size using the cascade:
  /// port.size (model) → port.theme.size → widget.size → theme.size
  Size _getPortSize() {
    return widget.port.size ??
        widget.port.theme?.size ??
        widget.size ??
        widget.theme.size;
  }

  /// Determines the appropriate color for the port based on its state.
  ///
  /// Cascade: port.theme → widget override → theme
  /// Priority: highlightColor (when highlighted) > connectedColor > color
  Color _getPortColorFromHighlight(bool isHighlighted) {
    final portTheme = widget.port.theme;

    if (isHighlighted) {
      return portTheme?.highlightColor ??
          widget.highlightColor ??
          widget.theme.highlightColor;
    } else if (widget.isConnected) {
      return portTheme?.connectedColor ??
          widget.connectedColor ??
          widget.theme.connectedColor;
    } else {
      return portTheme?.color ?? widget.color ?? widget.theme.color;
    }
  }

  /// Get border color based on port state.
  ///
  /// Cascade: port.theme → widget override → theme
  Color _getBorderColorFromHighlight(bool isHighlighted) {
    final portTheme = widget.port.theme;

    if (isHighlighted) {
      return portTheme?.highlightBorderColor ??
          widget.highlightBorderColor ??
          widget.theme.highlightBorderColor;
    } else {
      return portTheme?.borderColor ??
          widget.borderColor ??
          widget.theme.borderColor;
    }
  }

  /// Get border width.
  ///
  /// Cascade: port.theme → widget override → theme
  double _getBorderWidth() {
    return widget.port.theme?.borderWidth ??
        widget.borderWidth ??
        widget.theme.borderWidth;
  }
}

/// Private widget for rendering port labels
/// Handles positioning based on port position and theme settings
class _PortLabel extends StatelessWidget {
  const _PortLabel({
    required this.port,
    required this.theme,
    required this.size,
  });

  final Port port;
  final PortTheme theme;
  final Size size;

  @override
  Widget build(BuildContext context) {
    // Visibility is now controlled by the parent (PortWidget) via LOD system
    // No need to check zoom threshold here anymore

    // Cascade: port.theme → widget.theme
    final effectiveTheme = port.theme ?? theme;

    final textStyle =
        effectiveTheme.labelTextStyle ??
        const TextStyle(
          fontSize: 10.0,
          color: Color(0xFF333333),
          fontWeight: FontWeight.w500,
        );

    final labelOffset = effectiveTheme.labelOffset;

    // Calculate label position based on port position
    // Labels appear "inside" (toward the node)
    // Offset is measured from the inner edge of the port
    switch (port.position) {
      case PortPosition.left:
        // Left port: label to the right (inside)
        // Offset from right edge of port, vertically centered
        return Positioned(
          left: size.width + labelOffset,
          top: size.height / 2,
          child: FractionalTranslation(
            translation: const Offset(0.0, -0.5),
            child: Text(port.name, style: textStyle, textAlign: TextAlign.left),
          ),
        );
      case PortPosition.right:
        // Right port: label to the left (inside)
        // Offset from left edge of port, vertically centered
        return Positioned(
          right: size.width + labelOffset,
          top: size.height / 2,
          child: FractionalTranslation(
            translation: const Offset(0.0, -0.5),
            child: Text(
              port.name,
              style: textStyle,
              textAlign: TextAlign.right,
            ),
          ),
        );
      case PortPosition.top:
        // Top port: label below (inside)
        // Offset from bottom edge of port, horizontally centered
        return Positioned(
          left: size.width / 2,
          top: size.height / 2 + labelOffset,
          child: FractionalTranslation(
            translation: const Offset(-0.5, 0.0), // Center horizontally
            child: Text(
              port.name,
              style: textStyle,
              textAlign: TextAlign.center,
            ),
          ),
        );
      case PortPosition.bottom:
        // Bottom port: label above (inside)
        // Offset from top edge of port, horizontally centered
        return Positioned(
          left: size.width / 2,
          bottom: size.height / 2 + labelOffset,
          child: FractionalTranslation(
            translation: const Offset(-0.5, 0.0), // Center horizontally
            child: Text(
              port.name,
              style: textStyle,
              textAlign: TextAlign.center,
            ),
          ),
        );
    }
  }
}
