import 'package:flutter/gestures.dart' show DragStartBehavior;
import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';

import '../graph/cursor_theme.dart';
import '../graph/node_flow_controller.dart';
import '../graph/node_flow_theme.dart';
import '../nodes/node.dart';
import '../ports/port.dart';
import '../ports/port_theme.dart';
import '../shared/unbounded_widgets.dart';
import 'port_shape_widget.dart';

/// Builder function type for customizing individual port widgets.
///
/// This typedef defines the signature for custom port builders that can be
/// provided to [NodeFlowEditor] or [NodeWidget] to customize port rendering.
///
/// Parameters:
/// - [context]: The build context
/// - [controller]: The node flow controller for drag operations
/// - [node]: The node containing this port
/// - [port]: The port being rendered
/// - [isOutput]: Whether this is an output port (true) or input port (false)
/// - [isConnected]: Whether the port currently has any connections
/// - [nodeBounds]: The bounds of the parent node in graph coordinates
///
/// Note: Highlighting is automatically handled via the [Port.highlighted]
/// observable, which is set by the controller during connection drag operations.
///
/// Example:
/// ```dart
/// PortBuilder myPortBuilder = (context, controller, node, port, isOutput, isConnected, nodeBounds) {
///   final color = isOutput ? Colors.green : Colors.blue;
///   return PortWidget(
///     port: port,
///     theme: Theme.of(context).extension<NodeFlowTheme>()!.portTheme,
///     controller: controller,
///     nodeId: node.id,
///     isOutput: isOutput,
///     nodeBounds: nodeBounds,
///     isConnected: isConnected,
///     color: color,
///   );
/// };
/// ```
typedef PortBuilder<T> =
    Widget Function(
      BuildContext context,
      NodeFlowController<T> controller,
      Node<T> node,
      Port port,
      bool isOutput,
      bool isConnected,
      Rect nodeBounds,
    );

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
/// 3. Model-level values (from [Port]) - highest priority
///
/// For example, port size is resolved as:
/// - `port.size` (if different from default) → widget `size` → `theme.size`
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
  final NodeFlowController<T> controller;

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
  final void Function(Offset globalPosition)? onContextMenu;

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

  void _handleHoverChange(bool isHovered) {
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
    }
  }

  void _handlePanUpdate(DragUpdateDetails details) {
    if (!_isDragging) return;

    // Convert global position to graph coordinates
    // Using globalToGraph which handles canvas offset + viewport transformation
    final graphPosition = widget.controller.globalToGraph(
      details.globalPosition,
    );

    // Hit test to find target port for snapping
    final hitResult = widget.controller.hitTestPort(graphPosition);

    // Get target node bounds if we have a hit
    Rect? targetNodeBounds;
    if (hitResult != null) {
      final targetNode = widget.controller.getNode(hitResult.nodeId);
      targetNodeBounds = targetNode?.getBounds();
    }

    // Update the connection drag
    widget.controller.updateConnectionDrag(
      graphPosition: graphPosition,
      targetNodeId: hitResult?.nodeId,
      targetPortId: hitResult?.portId,
      targetNodeBounds: targetNodeBounds,
    );
  }

  void _handlePanEnd(DragEndDetails details) {
    if (!_isDragging) return;
    _isDragging = false;

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
    widget.controller.cancelConnectionDrag();
    setState(() {});
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
              final isHighlighted = widget.port.highlighted.value;
              // Use getter which accesses .value internally for MobX reactivity
              final isConnecting =
                  widget.controller.interaction.isCreatingConnection;

              // During connection drag: only show snapping circle for valid (highlighted) targets
              // When idle: show snapping circle on hover for visual feedback
              final showSnappingCircle = isConnecting
                  ? isHighlighted
                  : _isHovered;

              return UnboundedStack(
                clipBehavior: Clip.none,
                children: [
                  // Snapping circle - shows on hover OR when highlighted during connection drag
                  if (showSnappingCircle)
                    Positioned(
                      left: -widget.snapDistance,
                      top: -widget.snapDistance,
                      right: -widget.snapDistance,
                      bottom: -widget.snapDistance,
                      child: IgnorePointer(
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            color: widget.theme.snappingColor,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                    ),
                  // Marker shape - visual appearance reacts to highlighted state
                  Positioned.fill(
                    child: IgnorePointer(
                      child: PortShapeWidget(
                        shape: widget.port.shape ?? widget.theme.shape,
                        position: widget.port.position,
                        size: effectiveSize,
                        color: _getPortColorFromHighlight(isHighlighted),
                        borderColor: _getBorderColorFromHighlight(
                          isHighlighted,
                        ),
                        borderWidth: _getBorderWidth(),
                      ),
                    ),
                  ),
                  // Port label (if enabled in both theme and port)
                  if (widget.theme.showLabel && widget.port.showLabel)
                    _PortLabel(
                      port: widget.port,
                      theme: widget.theme,
                      size: effectiveSize,
                      currentZoom: widget.controller.viewport.zoom,
                    ),
                ],
              );
            },
          ),
          // Gesture detector is OUTSIDE Observer to prevent recognizer recreation
          // during MobX rebuilds, which would cancel the active gesture.
          // Using UnboundedPositioned to allow hit testing outside the port bounds,
          // enabling drag gestures to continue even when pointer moves outside.
          UnboundedPositioned(
            left: -widget.snapDistance,
            top: -widget.snapDistance,
            right: -widget.snapDistance,
            bottom: -widget.snapDistance,
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              dragStartBehavior: DragStartBehavior.down,
              onPanStart: _handlePanStart,
              onPanUpdate: _handlePanUpdate,
              onPanEnd: _handlePanEnd,
              onPanCancel: _handlePanCancel,
              onTap: widget.onTap != null
                  ? () => widget.onTap!(widget.port)
                  : null,
              onDoubleTap: widget.onDoubleTap,
              onSecondaryTapUp: widget.onContextMenu != null
                  ? (details) => widget.onContextMenu!(details.globalPosition)
                  : null,
              // Observer.withBuiltChild ensures only MouseRegion rebuilds when
              // interaction state changes, not the entire subtree
              child: Observer.withBuiltChild(
                builder: (context, child) {
                  // Derive cursor from interaction state
                  final cursorTheme = Theme.of(
                    context,
                  ).extension<NodeFlowTheme>()!.cursorTheme;
                  final cursor = cursorTheme.cursorFor(
                    ElementType.port,
                    widget.controller.interaction,
                  );
                  return MouseRegion(
                    cursor: cursor,
                    onEnter: (_) => _handleHoverChange(true),
                    onExit: (_) => _handleHoverChange(false),
                    child: child,
                  );
                },
                child: const SizedBox.expand(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Get the effective port size using the cascade:
  /// port.size (model) → widget.size → theme.size
  Size _getPortSize() {
    // Cascade: port.size → widget.size → theme.size
    return widget.port.size ?? widget.size ?? widget.theme.size;
  }

  /// Determines the appropriate color for the port based on its state.
  ///
  /// Uses widget-level overrides if provided, otherwise falls back to theme.
  /// Priority: highlightColor (when highlighted) > connectedColor > color
  Color _getPortColorFromHighlight(bool isHighlighted) {
    if (isHighlighted) {
      return widget.highlightColor ?? widget.theme.highlightColor;
    } else if (widget.isConnected) {
      return widget.connectedColor ?? widget.theme.connectedColor;
    } else {
      return widget.color ?? widget.theme.color;
    }
  }

  /// Get border color based on port state.
  ///
  /// Uses widget-level overrides if provided, otherwise falls back to theme.
  Color _getBorderColorFromHighlight(bool isHighlighted) {
    if (isHighlighted) {
      return widget.highlightBorderColor ?? widget.theme.highlightBorderColor;
    } else {
      return widget.borderColor ?? widget.theme.borderColor;
    }
  }

  /// Get border width.
  ///
  /// Uses widget-level overrides if provided, otherwise falls back to theme.
  double _getBorderWidth() {
    return widget.borderWidth ?? widget.theme.borderWidth;
  }
}

/// Private widget for rendering port labels
/// Handles positioning based on port position and theme settings
class _PortLabel extends StatelessWidget {
  const _PortLabel({
    required this.port,
    required this.theme,
    required this.size,
    required this.currentZoom,
  });

  final Port port;
  final PortTheme theme;
  final Size size;
  final double currentZoom;

  @override
  Widget build(BuildContext context) {
    // Check zoom level for responsive visibility
    final currentScale = currentZoom;

    // Hide label if zoom is below threshold
    if (currentScale < theme.labelVisibilityThreshold) {
      return const SizedBox.shrink();
    }

    final textStyle =
        theme.labelTextStyle ??
        const TextStyle(
          fontSize: 10.0,
          color: Color(0xFF333333),
          fontWeight: FontWeight.w500,
        );

    // Calculate label position based on port position
    // Labels appear "inside" (toward the node)
    // Offset is measured from the inner edge of the port
    switch (port.position) {
      case PortPosition.left:
        // Left port: label to the right (inside)
        // Offset from right edge of port, vertically centered
        return Positioned(
          left: size.width + theme.labelOffset,
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
          right: size.width + theme.labelOffset,
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
          top: size.height / 2 + theme.labelOffset,
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
          bottom: size.height / 2 + theme.labelOffset,
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
