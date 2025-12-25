import 'package:flutter/gestures.dart' hide HitTestResult;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:mobx/mobx.dart' hide Listener;
import 'package:vector_math/vector_math_64.dart' hide Colors;

import '../annotations/annotation.dart';
import '../annotations/annotation_layer.dart';
import '../connections/connection.dart';
import '../connections/connection_style_overrides.dart';
import '../graph/cursor_theme.dart';
import '../graph/hit_test_result.dart';
import '../graph/node_flow_behavior.dart';
import '../graph/node_flow_controller.dart';
import '../graph/node_flow_events.dart';
import '../graph/node_flow_theme.dart';
import '../graph/viewport.dart';
import '../graph/viewport_animation_mixin.dart';
import '../nodes/node.dart';
import '../nodes/node_shape.dart';
import '../ports/port.dart';
import '../ports/port_widget.dart';
import '../shared/flutter_actions_integration.dart';
import '../shared/spatial/graph_spatial_index.dart';
import '../shared/unbounded_widgets.dart';
import 'coordinates.dart';
import 'layers/attribution_overlay.dart';
import 'layers/connection_labels_layer.dart';
import 'layers/connections_layer.dart';
import 'layers/grid_layer.dart';
import 'layers/interaction_layer.dart';
import 'layers/minimap_overlay.dart';
import 'layers/nodes_layer.dart';
import 'layers/autopan_zone_debug_layer.dart';
import 'layers/debug_layers_stack.dart';

part 'node_flow_controller_extensions.dart';
part 'node_flow_editor_hit_testing.dart';
part 'node_flow_editor_widget_handlers.dart';

/// Node flow editor widget using MobX for reactive state management.
///
/// This is the main widget for displaying and interacting with a node-based graph.
/// It provides a highly interactive canvas with support for:
/// - Node rendering with custom builders
/// - Connection creation and management
/// - Multiple selection modes
/// - Viewport panning and zooming
/// - Annotations (sticky notes, markers, groups)
/// - Keyboard shortcuts
/// - Touch and mouse interactions
///
/// Example:
/// ```dart
/// NodeFlowEditor<MyData>(
///   controller: controller,
///   theme: NodeFlowTheme.defaultTheme,
///   nodeBuilder: (context, node) {
///     return MyCustomNodeWidget(node: node);
///   },
///   onNodeSelected: (node) {
///     print('Selected: ${node?.id}');
///   },
/// )
/// ```
class NodeFlowEditor<T> extends StatefulWidget {
  const NodeFlowEditor({
    super.key,
    required this.controller,
    required this.nodeBuilder,
    required this.theme,
    this.nodeShapeBuilder,
    this.nodeContainerBuilder,
    this.portBuilder,
    this.labelBuilder,
    this.connectionStyleResolver,
    this.events,
    this.behavior = NodeFlowBehavior.design,
    this.scrollToZoom = true,
    this.showAnnotations = true,
  });

  /// The controller that manages the graph state.
  ///
  /// This controller holds all nodes, connections, annotations, viewport state,
  /// and provides methods for manipulating the graph.
  final NodeFlowController<T> controller;

  /// Builder function for rendering node content.
  ///
  /// This function is called for each node in the graph to create its visual
  /// representation. The returned widget is automatically wrapped in a NodeWidget
  /// unless you provide a custom [nodeContainerBuilder].
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

  /// Optional builder for determining the shape of a node.
  ///
  /// This function is called to determine what shape (if any) should be used
  /// for rendering a node. Return null for rectangular nodes.
  ///
  /// The shape is used by:
  /// - The default nodeContainerBuilder to render shaped nodes
  /// - Connection drawing to calculate correct port positions
  ///
  /// Example:
  /// ```dart
  /// nodeShapeBuilder: (context, node) {
  ///   if (node.type == 'Terminal') {
  ///     return CircleShape(
  ///       fillColor: Colors.green,
  ///       strokeColor: Colors.darkGreen,
  ///       strokeWidth: 2.0,
  ///     );
  ///   }
  ///   return null; // Rectangular node
  /// }
  /// ```
  final NodeShape? Function(BuildContext context, Node<T> node)?
  nodeShapeBuilder;

  /// Optional builder for customizing the node container.
  ///
  /// Receives the node content (from `nodeBuilder`) and the node itself.
  /// By default, nodes are wrapped in a NodeWidget with standard functionality.
  ///
  /// You can use this to:
  /// - Return NodeWidget with custom appearance parameters
  /// - Wrap NodeWidget with additional decorations
  /// - Create completely custom node containers
  ///
  /// Example:
  /// ```dart
  /// nodeContainerBuilder: (context, node, content) {
  ///   return Container(
  ///     decoration: BoxDecoration(
  ///       border: Border.all(color: Colors.blue, width: 2),
  ///     ),
  ///     child: NodeWidget(node: node, child: content),
  ///   );
  /// }
  /// ```
  final Widget Function(BuildContext context, Node<T> node, Widget content)?
  nodeContainerBuilder;

  /// Optional builder for customizing individual port widgets.
  ///
  /// This function is called for each port in every node, allowing you to
  /// customize port appearance based on the port data, node, or any other
  /// application-specific logic.
  ///
  /// The builder receives:
  /// - [context]: Build context
  /// - [node]: The node containing this port
  /// - [port]: The port being rendered
  /// - [isOutput]: Whether this is an output port (true) or input port (false)
  /// - [isConnected]: Whether the port currently has connections
  ///
  /// Note: Highlighting is automatically handled via [Port.highlighted] observable.
  ///
  /// Return null to use the default PortWidget with theme styling.
  ///
  /// Example:
  /// ```dart
  /// portBuilder: (context, node, port, isOutput, isConnected) {
  ///   // Color ports based on data type
  ///   final color = port.name.contains('error')
  ///       ? Colors.red
  ///       : null; // Use theme default
  ///
  ///   return PortWidget(
  ///     port: port,
  ///     theme: Theme.of(context).extension<NodeFlowTheme>()!.portTheme,
  ///     isConnected: isConnected,
  ///     color: color,
  ///   );
  /// }
  /// ```
  final PortBuilder<T>? portBuilder;

  /// Optional builder for customizing connection label widgets.
  ///
  /// This function is called for each label on every connection, allowing you
  /// to customize label appearance based on the label data, connection, or any
  /// other application-specific logic.
  ///
  /// The builder receives:
  /// - [context]: Build context
  /// - [connection]: The connection containing this label
  /// - [label]: The label being rendered
  /// - [position]: The calculated position rect for the label
  ///
  /// Return null to use the default label widget with theme styling.
  ///
  /// Example:
  /// ```dart
  /// labelBuilder: (context, connection, label, position) {
  ///   return Positioned(
  ///     left: position.left,
  ///     top: position.top,
  ///     child: Container(
  ///       padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
  ///       decoration: BoxDecoration(
  ///         color: connection.data?['priority'] == 'high'
  ///             ? Colors.orange.shade100
  ///             : Colors.white,
  ///         borderRadius: BorderRadius.circular(4),
  ///       ),
  ///       child: Text(label.text),
  ///     ),
  ///   );
  /// }
  /// ```
  final LabelBuilder? labelBuilder;

  /// Optional resolver for customizing connection styles per-connection.
  ///
  /// This function is called for each connection during painting, allowing
  /// you to override colors and stroke widths based on connection data.
  ///
  /// Return null to use the theme defaults, or return a [ConnectionStyleOverrides]
  /// to customize specific properties.
  ///
  /// Example:
  /// ```dart
  /// connectionStyleResolver: (connection) {
  ///   if (connection.data?['type'] == 'error') {
  ///     return ConnectionStyleOverrides(
  ///       color: Colors.red,
  ///       selectedColor: Colors.red.shade700,
  ///       strokeWidth: 3.0,
  ///     );
  ///   }
  ///   return null; // Use theme defaults
  /// }
  /// ```
  final ConnectionStyleOverrides? Function(Connection connection)?
  connectionStyleResolver;

  /// The theme configuration for styling the editor.
  ///
  /// Controls colors, sizes, and visual appearance of nodes, connections,
  /// ports, and other UI elements.
  final NodeFlowTheme theme;

  /// Structured event system for handling various editor events.
  ///
  /// Events are organized into logical groups (node, connection, viewport, etc.)
  /// for better discoverability and maintainability.
  ///
  /// Example:
  /// ```dart
  /// NodeFlowEditor(
  ///   controller: controller,
  ///   nodeBuilder: nodeBuilder,
  ///   theme: theme,
  ///   events: NodeFlowEvents(
  ///     node: NodeEvents(
  ///       onTap: (node) => handleNodeTap(node),
  ///       onDragStart: (node) => print('Dragging ${node.id}'),
  ///     ),
  ///     viewport: ViewportEvents(
  ///       onCanvasTap: (pos) => clearSelection(),
  ///     ),
  ///     connection: ConnectionEvents(
  ///       onBeforeComplete: (context) {
  ///         // Validate connections
  ///         return ConnectionValidationResult(allowed: true);
  ///       },
  ///     ),
  ///     onInit: () => controller.fitToView(),
  ///   ),
  /// )
  /// ```
  final NodeFlowEvents<T>? events;

  /// The behavior mode for the canvas.
  ///
  /// Controls what operations are allowed:
  /// - [NodeFlowBehavior.design]: Full editing (default)
  /// - [NodeFlowBehavior.preview]: View and drag, no structural changes
  /// - [NodeFlowBehavior.present]: Display only, no interaction
  final NodeFlowBehavior behavior;

  /// Whether trackpad scroll gestures should cause zooming.
  ///
  /// When `true`, scrolling on a trackpad will zoom in/out.
  /// When `false`, trackpad scroll will be treated as pan gestures.
  /// Defaults to `true`.
  final bool scrollToZoom;

  /// Whether to show the annotation layers (sticky notes, markers, groups).
  ///
  /// When `false`, annotations are not rendered but remain in the graph data.
  /// Defaults to `true`.
  final bool showAnnotations;

  @override
  State<NodeFlowEditor<T>> createState() => _NodeFlowEditorState<T>();
}

class _NodeFlowEditorState<T> extends State<NodeFlowEditor<T>>
    with TickerProviderStateMixin, ViewportAnimationMixin {
  late final TransformationController _transformationController;
  final List<ReactionDisposer> _disposers = [];

  // Animation controller for animated connections
  AnimationController? _connectionAnimationController;

  // Track initial pointer position for tap detection
  Offset? _initialPointerPosition;

  // Track if we should clear selection on pointer up (for empty canvas taps)
  bool _shouldClearSelectionOnTap = false;

  // Double-tap detection - tracks last tap for any hit target type
  DateTime? _lastTapTime;
  Offset? _lastTapPosition;
  HitTarget? _lastTapHitType;
  String? _lastTappedEntityId; // nodeId, connectionId, or null for canvas
  static const _doubleTapTimeout = Duration(milliseconds: 300);
  static const _doubleTapSlop = 20.0;

  // Hover tracking for mouse enter/leave events
  HitTarget? _lastHoverHitType;
  String? _lastHoveredEntityId; // nodeId, connectionId, portId, or annotationId

  // Shift key tracking for selection mode cursor
  bool _isShiftPressed = false;

  // Pointer ID tracking for drag operations.
  // Used by the safety net in _handlePointerUp to only cleanup if the pointer
  // that started the drag is the one that ended. This prevents trackpad pointer
  // ups from prematurely ending mouse drags.
  int? _dragPointerId;

  @override
  void initState() {
    super.initState();

    // Note: Controller only needs config, theme is handled by editor

    // Set behavior mode on controller
    widget.controller.setBehavior(widget.behavior);

    _transformationController = TransformationController();

    // CRITICAL: This listener is the authoritative mechanism for syncing viewport
    // from transform changes. While InteractiveViewer's onInteraction* callbacks
    // also sync the viewport, empirically they don't work reliably for all cases
    // (particularly trackpad scroll panning when scrollToZoom is false).
    // The listener fires immediately when the transform value changes, ensuring
    // the viewport is always in sync for accurate hit testing and coordinate conversion.
    _transformationController.addListener(_syncViewportFromTransform);

    // Initialize animation controller for animated connections
    _connectionAnimationController = AnimationController(
      vsync: this,
      duration: widget.theme.connectionAnimationDuration,
    );

    // Attach viewport animation mixin - directly animates TransformationController
    // This also registers the animation handler on the controller
    debugPrint('[NodeFlowEditor] initState: attaching viewport animation');
    attachViewportAnimation(
      tickerProvider: this,
      transformationController: _transformationController,
      controller: widget.controller,
      onAnimationComplete: widget.controller.setViewport,
    );

    // Initialize transformation controller with current viewport
    final viewport = widget.controller.viewport;
    final initialMatrix = Matrix4.identity()
      ..translateByVector3(Vector3(viewport.x, viewport.y, 0))
      ..scaleByDouble(viewport.zoom, viewport.zoom, viewport.zoom, 1.0);
    _transformationController.value = initialMatrix;

    // Set up reactions for efficient updates
    _setupReactions();

    // Initialize pan state based on widget properties
    _updatePanState();

    // Set up node shape builder BEFORE theme (so ConnectionPainter gets the shape builder)
    _updateNodeShapeBuilder();

    // Set theme on the controller (this initializes the connection painter)
    widget.controller.setTheme(widget.theme);

    // Set up spatial index callbacks (requires connection painter to be initialized)
    _setupSpatialIndex();

    // Set events on the controller
    if (widget.events != null) {
      widget.controller.setEvents(widget.events!);
    }

    // Register keyboard handler for shift key cursor changes
    HardwareKeyboard.instance.addHandler(_handleKeyEvent);

    // Fire onInit event after initialization completes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      widget.controller.events.onInit?.call();
    });
  }

  @override
  void didUpdateWidget(NodeFlowEditor<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    debugPrint(
      '[NodeFlowEditor] didUpdateWidget: controller changed? ${oldWidget.controller != widget.controller}',
    );
    // Theme is handled by editor, config is immutable in controller

    // Re-attach viewport animation if controller changed
    if (oldWidget.controller != widget.controller) {
      // Detach from old controller and attach to new one
      detachViewportAnimation();
      attachViewportAnimation(
        tickerProvider: this,
        transformationController: _transformationController,
        controller: widget.controller,
        onAnimationComplete: widget.controller.setViewport,
      );
    }

    // Update behavior mode if it changed
    if (oldWidget.behavior != widget.behavior) {
      widget.controller.setBehavior(widget.behavior);
    }

    // Update node shape builder if it changed
    if (oldWidget.nodeShapeBuilder != widget.nodeShapeBuilder) {
      _updateNodeShapeBuilder();
    }

    // Update events if they changed
    if (oldWidget.events != widget.events && widget.events != null) {
      widget.controller.setEvents(widget.events!);
    }

    // Update theme if it changed
    if (oldWidget.theme != widget.theme) {
      widget.controller.setTheme(widget.theme);
    }

    // Update animation controller duration if it changed
    if (oldWidget.theme.connectionAnimationDuration !=
        widget.theme.connectionAnimationDuration) {
      _connectionAnimationController?.duration =
          widget.theme.connectionAnimationDuration;
    }

    // Check if animation should be updated due to theme change
    if (oldWidget.theme.connectionTheme.animationEffect !=
        widget.theme.connectionTheme.animationEffect) {
      _updateAnimationController();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = widget.theme;

    return Theme(
      data: Theme.of(context).copyWith(extensions: [theme]),
      child: _SizeObserver(
        onSizeChanged: widget.controller.setScreenSize,
        builder: (context, constraints) {
          return NodeFlowKeyboardHandler<T>(
            controller: widget.controller,
            focusNode: widget.controller.canvasFocusNode,
            // Listener has the canvasKey so we can convert global→local coordinates
            child: Listener(
              key: widget.controller.canvasKey,
              // IMPORTANT: Use translucent to ensure this Listener receives
              // events BEFORE child Listeners. Default (deferToChild) can cause
              // child Listeners to fire before the parent, breaking flag logic.
              behavior: HitTestBehavior.translucent,
              onPointerDown: _handlePointerDown,
              onPointerMove: _handlePointerMove,
              onPointerUp: _handlePointerUp,
              onPointerHover: _handleMouseHover,
              child: Observer.withBuiltChild(
                builder: (context, child) {
                  // Derive cursor from interaction state
                  final cursor = widget.theme.cursorTheme.cursorFor(
                    ElementType.canvas,
                    widget.controller.interaction,
                  );
                  return MouseRegion(cursor: cursor, child: child);
                },
                child: Container(
                  width: constraints.maxWidth,
                  height: constraints.maxHeight,
                  clipBehavior: Clip.hardEdge,
                  decoration: BoxDecoration(color: theme.backgroundColor),
                  child: Stack(
                    children: [
                      // Autopan zone debug overlay - screen coordinates, below all content
                      // Positioned first in stack so it renders behind InteractiveViewer
                      AutopanZoneDebugLayer<T>(controller: widget.controller),

                      // Canvas with InteractiveViewer for pan/zoom
                      // Wrapped in Observer to react to panEnabled changes
                      Observer.withBuiltChild(
                        builder: (context, child) {
                          return InteractiveViewer(
                            transformationController: _transformationController,
                            boundaryMargin: const EdgeInsets.all(
                              double.infinity,
                            ),
                            constrained: false,
                            minScale: widget.controller.config.minZoom.value,
                            maxScale: widget.controller.config.maxZoom.value,
                            panEnabled: widget.controller.panEnabled,
                            scaleEnabled: widget.behavior.canZoom,
                            trackpadScrollCausesScale: widget.scrollToZoom,
                            onInteractionStart: _onInteractionStart,
                            onInteractionUpdate: _onInteractionUpdate,
                            onInteractionEnd: _onInteractionEnd,
                            child: child,
                          );
                        },
                        child: UnboundedSizedBox(
                          width: constraints.maxWidth,
                          height: constraints.maxHeight,
                          child: UnboundedStack(
                            clipBehavior: Clip.none,
                            children: [
                              // Background grid
                              GridLayer(
                                theme: theme,
                                transformationController:
                                    _transformationController,
                              ),

                              // Debug visualization layers (when config.debugMode is enabled)
                              // Placed above grid but below content for visibility
                              // Uses Observer internally for reactivity
                              DebugLayersStack<T>(
                                controller: widget.controller,
                                transformationController:
                                    _transformationController,
                                theme: theme,
                              ),

                              // Background annotations (groups) - drag handled via AnnotationWidget
                              if (widget.showAnnotations)
                                AnnotationLayer.background(
                                  widget.controller,
                                  onAnnotationTap: _handleAnnotationTap,
                                  onAnnotationDoubleTap:
                                      _handleAnnotationDoubleTap,
                                  onAnnotationContextMenu:
                                      _handleAnnotationContextMenu,
                                  onAnnotationMouseEnter:
                                      _handleAnnotationMouseEnter,
                                  onAnnotationMouseLeave:
                                      _handleAnnotationMouseLeave,
                                ),

                              // Connections
                              ConnectionsLayer<T>(
                                controller: widget.controller,
                                animation: _connectionAnimationController,
                              ),

                              // Connection labels
                              ConnectionLabelsLayer<T>(
                                controller: widget.controller,
                                labelBuilder: widget.labelBuilder,
                              ),

                              // Nodes - drag handled directly by NodeWidget via controller
                              NodesLayer<T>(
                                controller: widget.controller,
                                nodeBuilder: widget.nodeBuilder,
                                nodeContainerBuilder:
                                    widget.nodeContainerBuilder,
                                portBuilder: widget.portBuilder,
                                connections: widget.controller.connections,
                                portSnapDistance: widget
                                    .controller
                                    .config
                                    .portSnapDistance
                                    .value,
                                onNodeTap: _handleNodeTap,
                                onNodeDoubleTap: _handleNodeDoubleTap,
                                onNodeContextMenu: _handleNodeContextMenu,
                                onNodeMouseEnter: _handleNodeMouseEnter,
                                onNodeMouseLeave: _handleNodeMouseLeave,
                                onPortContextMenu: _handlePortContextMenu,
                              ),

                              // Foreground annotations (stickies, markers) - drag handled via AnnotationWidget
                              if (widget.showAnnotations)
                                AnnotationLayer.foreground(
                                  widget.controller,
                                  onAnnotationTap: _handleAnnotationTap,
                                  onAnnotationDoubleTap:
                                      _handleAnnotationDoubleTap,
                                  onAnnotationContextMenu:
                                      _handleAnnotationContextMenu,
                                  onAnnotationMouseEnter:
                                      _handleAnnotationMouseEnter,
                                  onAnnotationMouseLeave:
                                      _handleAnnotationMouseLeave,
                                ),
                            ],
                          ),
                        ),
                      ),

                      // Interaction layer - renders temporary connections and selection rectangles
                      // Positioned outside the canvas to render anywhere on the infinite canvas
                      // Uses IgnorePointer - all event handling is done by the Listener above
                      Positioned.fill(
                        child: InteractionLayer<T>(
                          controller: widget.controller,
                          transformationController: _transformationController,
                          animation: _connectionAnimationController,
                        ),
                      ),

                      // Minimap overlay - topmost layer, outside InteractiveViewer
                      MinimapOverlay<T>(
                        controller: widget.controller,
                        theme: theme,
                        transformationController: _transformationController,
                        canvasSize: constraints.biggest,
                      ),

                      // Attribution overlay - bottom center
                      AttributionOverlay(
                        show: widget.controller.config.showAttribution,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  void _setupReactions() {
    // Sync transformation controller with viewport changes - immediate synchronous updates
    _disposers.add(
      reaction((_) => widget.controller.viewport, (GraphViewport viewport) {
        if (mounted) {
          final matrix = Matrix4.identity()
            ..translateByVector3(Vector3(viewport.x, viewport.y, 0))
            ..scaleByDouble(viewport.zoom, viewport.zoom, viewport.zoom, 1.0);

          // Force immediate update without animation for real-time panning
          _transformationController.value = matrix;
        }
      }, fireImmediately: true),
    );

    // Update pan state based on interaction state
    // Centralized pan state management - watches all drag/resize/connection states
    _disposers.add(
      reaction(
        (_) => (
          widget.controller.draggedNodeId != null,
          widget.controller.annotations.draggedAnnotationId != null,
          widget.controller.annotations.isResizing,
          widget.controller.isConnecting,
          widget.controller.isDrawingSelection,
        ),
        (_) => _updatePanState(),
      ),
    );

    // Start/stop animation controller based on whether any connections are animated
    _disposers.add(
      reaction(
        (_) => (
          widget.theme.connectionTheme.animationEffect,
          widget.theme.temporaryConnectionTheme.animationEffect,
          widget.controller.connections.any((c) => c.animationEffect != null),
        ),
        (_) => _updateAnimationController(),
        fireImmediately: true,
      ),
    );

    // Note: Viewport animation requests are handled via direct callback
    // (setAnimateToHandler) to avoid MobX batching issues.

    // Note: Snap-to-grid behavior is handled by controller config
  }

  void _updateNodeShapeBuilder() {
    // Create a closure that captures the current context
    // The State's context is stable throughout its lifetime
    if (widget.nodeShapeBuilder != null) {
      widget.controller.setNodeShapeBuilder(
        (node) => widget.nodeShapeBuilder!(context, node),
      );
    } else {
      widget.controller.setNodeShapeBuilder(null);
    }
  }

  void _setupSpatialIndex() {
    final spatialIndex = widget.controller.spatialIndex;
    final themePortSize = widget.theme.portTheme.size;

    // Set up node shape builder callback
    spatialIndex.nodeShapeBuilder = widget.controller.nodeShapeBuilder;

    // Set up port size resolver using theme cascade
    spatialIndex.portSizeResolver = (port) => port.size ?? themePortSize;

    // Set up connection hit tester callback
    spatialIndex.connectionHitTester = (connection, point) {
      final sourceNode = widget.controller.getNode(connection.sourceNodeId);
      final targetNode = widget.controller.getNode(connection.targetNodeId);
      if (sourceNode == null || targetNode == null) return false;

      return widget.controller.connectionPainter.hitTestConnection(
        connection: connection,
        sourceNode: sourceNode,
        targetNode: targetNode,
        testPoint: point,
      );
    };

    // Initialize spatial indexes
    spatialIndex.rebuildFromNodes(widget.controller.nodes.values);
    _rebuildConnectionSpatialIndex();
    spatialIndex.rebuildFromAnnotations(
      widget.controller.annotations.annotations.values,
    );
  }

  void _rebuildConnectionSpatialIndex() {
    // Guard: connection painter must be initialized first
    if (!widget.controller.isConnectionPainterInitialized) {
      return;
    }

    final spatialIndex = widget.controller.spatialIndex;
    final pathCache = widget.controller.connectionPainter.pathCache;
    final connectionStyle = widget.theme.connectionTheme.style;

    // Use segment-based spatial indexing for accurate hit testing
    spatialIndex.rebuildConnectionsWithSegments(widget.controller.connections, (
      connection,
    ) {
      final sourceNode = widget.controller.getNode(connection.sourceNodeId);
      final targetNode = widget.controller.getNode(connection.targetNodeId);
      if (sourceNode == null || targetNode == null) {
        return [];
      }

      // Get segment bounds from the path cache
      // This uses the rectangle segments created by the connection style
      return pathCache.getOrCreateSegmentBounds(
        connection: connection,
        sourceNode: sourceNode,
        targetNode: targetNode,
        connectionStyle: connectionStyle,
      );
    });
  }

  void _updatePanState() {
    // Centralized pan state calculation - pan is enabled only when:
    // - Behavior allows panning
    // - No node is being dragged
    // - No annotation is being dragged or resized
    // - No connection is being created
    // - No selection rectangle is being drawn
    final canPan = widget.behavior.canPan;
    final draggedNodeId = widget.controller.draggedNodeId;
    final draggedAnnotationId =
        widget.controller.annotations.draggedAnnotationId;
    final isResizing = widget.controller.annotations.isResizing;
    final isConnecting = widget.controller.isConnecting;
    final isDrawingSelection = widget.controller.isDrawingSelection;

    final newPanEnabled =
        canPan &&
        draggedNodeId == null &&
        draggedAnnotationId == null &&
        !isResizing &&
        !isConnecting &&
        !isDrawingSelection;

    widget.controller._updateInteractionState(panEnabled: newPanEnabled);
  }

  /// Updates the animation controller based on theme and connection animation effects.
  ///
  /// Starts the animation controller if either the theme has a default animation effect,
  /// the temporary connection theme has an animation effect, or any connection has an
  /// individual animation effect. Stops it otherwise.
  void _updateAnimationController() {
    // Check if permanent connection theme has animation effect
    final connectionThemeHasEffect =
        widget.theme.connectionTheme.animationEffect != null;

    // Check if temporary connection theme has animation effect
    final tempConnectionThemeHasEffect =
        widget.theme.temporaryConnectionTheme.animationEffect != null;

    // Check if any connection has an animation effect
    final connectionHasEffect = widget.controller.connections.any(
      (connection) => connection.animationEffect != null,
    );

    final hasAnimations =
        connectionThemeHasEffect ||
        tempConnectionThemeHasEffect ||
        connectionHasEffect;

    if (hasAnimations) {
      _connectionAnimationController?.repeat();
    } else {
      _connectionAnimationController?.stop();
    }
  }

  @override
  void dispose() {
    // Remove keyboard handler
    HardwareKeyboard.instance.removeHandler(_handleKeyEvent);

    // Remove transform listener before disposing
    _transformationController.removeListener(_syncViewportFromTransform);

    // Detach viewport animation - this also clears the handler with token check
    debugPrint('[NodeFlowEditor] dispose: detaching viewport animation');
    detachViewportAnimation();

    for (final disposer in _disposers) {
      disposer();
    }
    _transformationController.dispose();
    _connectionAnimationController?.dispose();

    // Note: Controller disposal is handled by whoever created the controller,
    // not by this widget
    super.dispose();
  }

  // Event handlers

  /// Syncs the controller's viewport with the transformation controller.
  ///
  /// This is the AUTHORITATIVE viewport sync mechanism, called by the
  /// transformation controller's listener. It ensures the viewport stays
  /// in sync with ALL transform changes, which is critical for:
  /// - Accurate hit testing (nodes, ports, connections, annotations)
  /// - Correct coordinate conversion (screen ↔ graph coordinates)
  /// - Proper spatial index queries
  ///
  /// The onInteraction* callbacks also call setViewport, but empirically
  /// they don't work reliably in all cases. This listener is the safety net.
  ///
  /// IMPORTANT: This sync is skipped during viewport animation to prevent
  /// the animation from being interrupted. The viewport is synced once
  /// when the animation completes via the onAnimationComplete callback.
  void _syncViewportFromTransform() {
    // Skip sync during animation - final sync happens via onAnimationComplete
    if (isViewportAnimating) {
      return;
    }

    final transform = _transformationController.value;
    final translation = transform.getTranslation();
    final currentZoom = transform.getMaxScaleOnAxis();

    final viewport = GraphViewport(
      x: translation.x,
      y: translation.y,
      zoom: currentZoom,
    );

    // Only update if viewport actually changed to avoid unnecessary reactions
    final currentViewport = widget.controller.viewport;
    if (currentViewport.x != viewport.x ||
        currentViewport.y != viewport.y ||
        currentViewport.zoom != viewport.zoom) {
      widget.controller.setViewport(viewport);
    }
  }

  void _onInteractionStart(ScaleStartDetails details) {
    // Mark viewport as being interacted with (for suppressing port hover during pan)
    // Cursor is handled reactively via Observer in the canvas MouseRegion
    runInAction(() {
      widget.controller.interaction.isViewportInteracting.value = true;
    });

    // Note: Viewport sync is handled by the TransformationController listener.
    // We don't call setViewport here - the listener is the authoritative source.

    // Fire viewport move start event with current viewport state
    widget.controller.events.viewport?.onMoveStart?.call(
      widget.controller.viewport,
    );
  }

  void _onInteractionUpdate(ScaleUpdateDetails details) {
    // Note: Viewport sync is handled by the TransformationController listener.
    // We don't call setViewport here - the listener is the authoritative source.

    // Fire viewport move event with current viewport state
    widget.controller.events.viewport?.onMove?.call(widget.controller.viewport);
  }

  void _onInteractionEnd(ScaleEndDetails details) {
    // Mark viewport interaction as complete
    // Cursor is handled reactively via Observer in the canvas MouseRegion
    runInAction(() {
      widget.controller.interaction.isViewportInteracting.value = false;
    });

    // Note: Viewport sync is handled by the TransformationController listener.
    // We don't call setViewport here - the listener is the authoritative source.

    // Fire viewport move end event with current viewport state
    widget.controller.events.viewport?.onMoveEnd?.call(
      widget.controller.viewport,
    );
  }

  void _handlePointerDown(PointerDownEvent event) {
    // Handle secondary button (right-click) for context menu
    if (_handleContextMenu(event)) {
      return;
    }

    // Early return if all interactions are disabled
    if (!widget.behavior.canSelect &&
        !widget.behavior.canDrag &&
        !widget.behavior.canCreate) {
      return;
    }

    // DEFENSIVE CLEANUP: Clear any stale drag state from previous incomplete gestures.
    // This handles edge cases where quick tap-pan sequences leave nodes in a dragging
    // state because gesture recognizer callbacks (onEnd/onCancel) were never called.
    // This is the earliest cleanup point, before gesture recognizers start processing.
    widget.controller._cleanupStaleDragState();

    final hitResult = _performHitTest(event.localPosition);

    // Request focus when clicking on canvas background (not on nodes/ports/annotations)
    if (!hitResult.isNode &&
        !hitResult.isPort &&
        !hitResult.isAnnotation &&
        !widget.controller.canvasFocusNode.hasFocus) {
      widget.controller.canvasFocusNode.requestFocus();
    }

    // Store initial pointer position for tap detection
    _initialPointerPosition = event.localPosition;
    _shouldClearSelectionOnTap = false;

    // Store initial pointer position in widget-local coordinates
    widget.controller._setPointerPosition(ScreenPosition(event.localPosition));

    // CRITICAL: Disable pan IMMEDIATELY for ANY interactive element (node, annotation, port)
    // This prevents InteractiveViewer from competing for drag gestures in the gesture arena.
    // Pan will be re-enabled by _updatePanState() when drag states change.
    //
    // Only capture pointer ID if we're not already tracking a drag pointer.
    // This prevents a second pointer from overwriting the original drag pointer.
    if (hitResult.isNode || hitResult.isAnnotation || hitResult.isPort) {
      widget.controller._updateInteractionState(panEnabled: false);
      // Only set drag pointer if not already set (first pointer wins)
      _dragPointerId ??= event.pointer;
    }

    if (HardwareKeyboard.instance.isShiftPressed && widget.behavior.canSelect) {
      _startSelectionDrag(event.localPosition);
      return;
    }

    // Note: Connection handling is done via GestureDetector in PortWidget.
    // PortWidget uses pan gestures to handle connection drag. Pan is disabled
    // above when pointer is on a port, preventing InteractiveViewer from competing.

    switch (hitResult.hitType) {
      // Node selection is handled by widget-level handlers:
      // - _handleNodeTap for tap gestures
      // - startNodeDrag for drag gestures (selects if not already selected)
      // Pan is already disabled above for nodes, so just break here.
      case HitTarget.node:
        break;

      // Connections use IgnorePointer and are painted via CustomPaint, so they
      // don't participate in Flutter's widget hit testing. We MUST handle
      // connection selection here in the Listener using spatial index hit testing.
      case HitTarget.connection:
        final isCmd = HardwareKeyboard.instance.isMetaPressed;
        final isCtrl = HardwareKeyboard.instance.isControlPressed;
        final toggle = isCmd || isCtrl;

        // Select the connection
        widget.controller.selectConnection(
          hitResult.connectionId!,
          toggle: toggle,
        );

        final connection = widget.controller.connections.firstWhere(
          (c) => c.id == hitResult.connectionId!,
        );
        widget.controller.events.connection?.onTap?.call(connection);
        break;

      // Annotations ARE widgets with their own GestureDetectors, so selection
      // is handled by widget-level handlers (_handleAnnotationTap). This:
      // - Respects Flutter's natural z-order for overlapping annotations
      // - Allows resize handles (positioned outside bounds) to work correctly
      // - Avoids conflicts with drag gesture recognition
      // Pan is already disabled above for annotations, so just break here.
      case HitTarget.annotation:
        break;

      default:
        final isModifierPressed =
            HardwareKeyboard.instance.isMetaPressed ||
            HardwareKeyboard.instance.isControlPressed;

        if (!isModifierPressed) {
          _shouldClearSelectionOnTap = true;
        }
    }
  }

  void _handlePointerMove(PointerMoveEvent event) {
    // Always update mouse position for debug visualization (before any early returns)
    final worldPosition = widget.controller.viewport.toGraph(
      ScreenPosition(event.localPosition),
    );
    widget.controller.setMousePositionWorld(worldPosition);

    // Reset tap tracking if user moves significantly (they're dragging, not tapping)
    const dragThreshold = 5.0; // pixels
    if (_initialPointerPosition != null &&
        (event.localPosition - _initialPointerPosition!).distance >
            dragThreshold) {
      _shouldClearSelectionOnTap = false;
    }

    // Note: Node drag is now handled by GestureDetector in NodeWidget
    // (via _handleNodeDragUpdate) to allow widgets inside nodes to win drag gestures.

    // Note: Annotation drag is now handled by GestureDetector in AnnotationWidget
    // with direct controller access, so no Listener handling needed here.

    // Note: Connection drag is now handled by GestureDetector in PortWidget
    // with dragStartBehavior.down to win the gesture arena immediately.

    // Ultra-fast path for viewport panning - let InteractiveViewer handle it
    if (!widget.controller.isDrawingSelection &&
        !widget.controller.isConnecting &&
        widget.controller.panEnabled) {
      // Skip all processing during viewport panning for maximum performance
      return;
    }

    if (widget.controller.isDrawingSelection) {
      // Ultra-fast path for selection rectangle updates
      _updateSelectionDrag(event.localPosition);
      // Skip expensive drag state update during selection for maximum performance
      return;
    }

    // Skip when connecting - PortWidget's GestureDetector handles this
    if (widget.controller.isConnecting) {
      return;
    }

    // Cursor is derived from state via Observer - no update needed

    // Update pointer position in widget-local coordinates
    widget.controller._setPointerPosition(ScreenPosition(event.localPosition));
  }

  void _handlePointerUp(PointerUpEvent event) {
    // Check if this was a tap (minimal movement from initial position)
    const tapThreshold = 5.0; // pixels
    final wasTap =
        _initialPointerPosition != null &&
        (event.localPosition - _initialPointerPosition!).distance <
            tapThreshold;

    // Note: Node drag end is now handled by GestureDetector in NodeWidget
    // (via _handleNodeDragEnd) to allow widgets inside nodes to win drag gestures.

    // Note: Annotation drag end is now handled by GestureDetector in AnnotationWidget
    // with direct controller access, so no Listener handling needed here.

    // Note: Connection drag end is now handled by pan gestures in PortWidget.
    // The GestureDetector's onPanEnd handles completion/cancellation.

    // Re-enable panning if it was disabled
    _updatePanState();

    if (widget.controller.isDrawingSelection) {
      widget.controller._finishSelectionDrag();

      // Cursor is derived from state via Observer - no update needed

      // Reset tap tracking
      _initialPointerPosition = null;
      _shouldClearSelectionOnTap = false;
      return;
    }

    // Skip when connecting - PortWidget's pan gesture handles completion
    if (widget.controller.isConnecting) {
      return;
    }

    final hitResult = _performHitTest(event.localPosition);

    // Handle tap events (minimal movement from initial position)
    // IMPORTANT: wasTap takes precedence over wasDragging because draggedNodeId
    // is set on pointer down BEFORE we know if user will tap or drag.
    // So we check wasTap first - if movement was minimal, it's a tap regardless
    // of whether drag state was set up.
    if (wasTap) {
      _handleTapEvent(event.localPosition, hitResult);
    } else {
      // Was a drag (significant movement), reset double-tap tracking
      _resetDoubleTapTracking();
    }

    // Reset tap tracking
    _initialPointerPosition = null;
    _shouldClearSelectionOnTap = false;

    // SAFETY NET: If drag state is still set after pointer up, the gesture
    // recognizer's onEnd/onCancel failed to fire. Clean up here as final fallback.
    // CRITICAL: Only run safety net if this is the EXACT pointer that started the drag.
    // Pure pointer ID matching - device kind doesn't matter.
    final isOriginalDragPointer =
        _dragPointerId != null && event.pointer == _dragPointerId;

    if (isOriginalDragPointer) {
      if (widget.controller.draggedNodeId != null) {
        widget.controller.endNodeDrag();
      }
      if (widget.controller.annotations.draggedAnnotationId != null) {
        widget.controller.endAnnotationDrag();
      }
      // Clear the drag pointer ID after cleanup
      _dragPointerId = null;
    }

    // Cursor is derived from state via Observer - no update needed
  }

  // Helper methods

  void _startSelectionDrag(Offset startPosition) {
    final startGraph = widget.controller.viewport.toGraph(
      ScreenPosition(startPosition),
    );
    widget.controller._updateSelectionDrag(
      startPoint: startGraph,
      rectangle: GraphRect.fromPoints(
        startGraph,
        startGraph,
      ), // Start with zero-size rect
    );

    // Cursor is derived from isDrawingSelection state via Observer

    // Force pan state update to disable panning during selection
    _updatePanState();
  }

  void _updateSelectionDrag(Offset currentPosition) {
    final startPoint = widget.controller.selectionStartPoint;
    if (startPoint == null) return;

    final currentGraph = widget.controller.viewport.toGraph(
      ScreenPosition(currentPosition),
    );
    final rect = GraphRect.fromPoints(startPoint, currentGraph);

    // Update visual rectangle and handle selection in one call
    widget.controller._updateSelectionDrag(
      rectangle: rect,
      intersectingNodes: _getIntersectingNodes(rect),
      toggle: HardwareKeyboard.instance.isMetaPressed,
    );
  }

  List<String> _getIntersectingNodes(GraphRect rect) {
    final intersectingNodeIds = <String>[];

    // Find all nodes currently intersecting with the rectangle
    if (rect.width >= 1 && rect.height >= 1) {
      for (final node in widget.controller.nodes.values) {
        final nodePos = node.position.value;
        final nodeSize = node.size.value;

        // Simple bounds check - much faster than getBounds() and overlaps()
        if (nodePos.dx < rect.right &&
            nodePos.dx + nodeSize.width > rect.left &&
            nodePos.dy < rect.bottom &&
            nodePos.dy + nodeSize.height > rect.top) {
          intersectingNodeIds.add(node.id);
        }
      }
    }

    return intersectingNodeIds;
  }

  // Note: Connection drag handling has been moved to PortWidget.
  // PortWidget now uses pan gestures (onPanStart/Update/End) which continue
  // to receive events even when the pointer moves outside the widget bounds,
  // just like Flutter's Slider widget.
}

/// A widget that observes size changes and notifies via callback.
///
/// This properly separates size observation from the build phase by using
/// post-frame callbacks to notify of size changes.
class _SizeObserver extends StatefulWidget {
  const _SizeObserver({required this.onSizeChanged, required this.builder});

  /// Callback invoked when the size changes.
  final ValueChanged<Size> onSizeChanged;

  /// Builder that receives the current constraints.
  final Widget Function(BuildContext context, BoxConstraints constraints)
  builder;

  @override
  State<_SizeObserver> createState() => _SizeObserverState();
}

class _SizeObserverState extends State<_SizeObserver> {
  Size? _lastSize;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final size = constraints.biggest;
        _scheduleNotification(size);
        return widget.builder(context, constraints);
      },
    );
  }

  void _scheduleNotification(Size size) {
    if (_lastSize == size) return;

    // For initial size, notify immediately to avoid flicker
    if (_lastSize == null) {
      _lastSize = size;
      widget.onSizeChanged(size);
      return;
    }

    // For subsequent changes, use post-frame callback
    _lastSize = size;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        widget.onSizeChanged(size);
      }
    });
  }
}
