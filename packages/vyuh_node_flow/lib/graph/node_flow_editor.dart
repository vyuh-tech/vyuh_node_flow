import 'package:flutter/gestures.dart' hide HitTestResult;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:mobx/mobx.dart' hide Listener;
import 'package:vector_math/vector_math_64.dart' hide Colors;

import '../annotations/annotation_layer.dart';
import '../connections/connection.dart';
import '../connections/connection_style_overrides.dart';
import '../connections/connection_validation.dart';
import '../connections/temporary_connection.dart';
import '../graph/hit_test_result.dart';
import '../graph/node_flow_controller.dart';
import '../graph/node_flow_events.dart';
import '../graph/node_flow_theme.dart';
import '../graph/viewport.dart';
import '../nodes/node.dart';
import '../nodes/node_shape.dart';
import '../ports/port.dart';
import '../ports/port_widget.dart';
import '../shared/flutter_actions_integration.dart';
import '../shared/spatial/graph_spatial_index.dart';
import 'canvas_transform_provider.dart';
import 'layers/attribution_overlay.dart';
import 'layers/connection_control_points_layer.dart';
import 'layers/connection_labels_layer.dart';
import 'layers/connections_layer.dart';
import 'layers/grid_layer.dart';
import 'layers/interaction_layer.dart';
import 'layers/minimap_overlay.dart';
import 'layers/nodes_layer.dart';
import 'layers/spatial_index_debug_layer.dart';

part 'node_flow_controller_extensions.dart';
part 'node_flow_editor_hit_testing.dart';

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
    this.enablePanning = true,
    this.enableZooming = true,
    this.enableSelection = true,
    this.enableNodeDragging = true,
    this.enableConnectionCreation = true,
    this.enableNodeDeletion = true,
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
  /// - [isHighlighted]: Whether the port is being hovered during connection drag
  ///
  /// Return null to use the default PortWidget with theme styling.
  ///
  /// Example:
  /// ```dart
  /// portBuilder: (context, node, port, isOutput, isConnected, isHighlighted) {
  ///   // Color ports based on data type
  ///   final color = port.name.contains('error')
  ///       ? Colors.red
  ///       : null; // Use theme default
  ///
  ///   return PortWidget(
  ///     port: port,
  ///     theme: Theme.of(context).extension<NodeFlowTheme>()!.portTheme,
  ///     isConnected: isConnected,
  ///     isHighlighted: isHighlighted,
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

  /// Whether to enable viewport panning with mouse/trackpad drag.
  ///
  /// When `true`, dragging on empty canvas will pan the viewport.
  /// Defaults to `true`.
  final bool enablePanning;

  /// Whether to enable zoom controls (pinch-to-zoom, scroll wheel zoom).
  ///
  /// Defaults to `true`.
  final bool enableZooming;

  /// Whether to enable selection operations (shift+drag selection rectangle).
  ///
  /// Defaults to `true`.
  final bool enableSelection;

  /// Whether to enable dragging nodes with the mouse.
  ///
  /// When `false`, nodes cannot be moved but can still be selected.
  /// Defaults to `true`.
  final bool enableNodeDragging;

  /// Whether to enable creating connections by dragging from ports.
  ///
  /// Defaults to `true`.
  final bool enableConnectionCreation;

  /// Whether to enable node deletion via keyboard shortcuts (Delete/Backspace) and API.
  ///
  /// When `false`, nodes cannot be deleted through keyboard shortcuts.
  /// Programmatic deletion via controller.removeNode() is still possible.
  /// Defaults to `true`.
  final bool enableNodeDeletion;

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
    with TickerProviderStateMixin {
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
  String? _lastHoveredNodeId; // For port hover, track the parent node
  bool?
  _lastHoveredPortIsOutput; // For port hover, track if it's an output port

  // Shift key tracking for selection mode cursor
  bool _isShiftPressed = false;

  @override
  void initState() {
    super.initState();

    // Note: Controller only needs config, theme is handled by editor

    // Set UI interaction flags
    widget.controller.setNodeDeletion(widget.enableNodeDeletion);

    _transformationController = TransformationController();

    // Initialize animation controller for animated connections
    _connectionAnimationController = AnimationController(
      vsync: this,
      duration: widget.theme.connectionAnimationDuration,
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
    // Theme is handled by editor, config is immutable in controller

    // Update UI interaction flags if they changed
    if (oldWidget.enableNodeDeletion != widget.enableNodeDeletion) {
      widget.controller.setNodeDeletion(widget.enableNodeDeletion);
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
            child: Listener(
              onPointerDown: _handlePointerDown,
              onPointerMove: _handlePointerMove,
              onPointerUp: _handlePointerUp,
              onPointerHover: _handleMouseHover,
              child: Observer.withBuiltChild(
                builder: (context, child) {
                  return MouseRegion(
                    cursor: widget.controller.currentCursor,
                    child: child,
                  );
                },
                child: Container(
                  width: constraints.maxWidth,
                  height: constraints.maxHeight,
                  clipBehavior: Clip.hardEdge,
                  decoration: BoxDecoration(color: theme.backgroundColor),
                  child: Stack(
                    children: [
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
                            scaleEnabled: widget.enableZooming,
                            trackpadScrollCausesScale: widget.scrollToZoom,
                            onInteractionStart: _onInteractionStart,
                            onInteractionUpdate: _onInteractionUpdate,
                            onInteractionEnd: _onInteractionEnd,
                            child: child,
                          );
                        },
                        child: SizedBox(
                          width: constraints.maxWidth,
                          height: constraints.maxHeight,
                          child: AnimatedBuilder(
                            animation: _transformationController,
                            builder: (context, child) {
                              return CanvasTransformProvider(
                                transform: _transformationController.value,
                                child: child!,
                              );
                            },
                            child: Stack(
                              clipBehavior: Clip.none,
                              children: [
                                // Background grid
                                GridLayer(
                                  theme: theme,
                                  transformationController:
                                      _transformationController,
                                ),

                                // Background annotations (groups)
                                if (widget.showAnnotations)
                                  AnnotationLayer.background(widget.controller),

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

                                // Connection control points
                                ConnectionControlPointsLayer<T>(
                                  controller: widget.controller,
                                ),

                                // Nodes
                                NodesLayer<T>(
                                  controller: widget.controller,
                                  nodeBuilder: widget.nodeBuilder,
                                  nodeContainerBuilder:
                                      widget.nodeContainerBuilder,
                                  portBuilder: widget.portBuilder,
                                  connections: widget.controller.connections,
                                ),

                                // Foreground annotations (stickies, markers)
                                if (widget.showAnnotations)
                                  AnnotationLayer.foreground(widget.controller),

                                // Spatial index debug visualization (when debug mode is enabled)
                                if (theme.debugMode)
                                  SpatialIndexDebugLayer<T>(
                                    controller: widget.controller,
                                    transformationController:
                                        _transformationController,
                                    theme: theme,
                                  ),
                              ],
                            ),
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
    _disposers.add(
      reaction(
        (_) => (
          widget.controller.draggedNodeId != null,
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

    // Set up port size resolver
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
    final newPanEnabled =
        widget.enablePanning &&
        widget.controller.draggedNodeId == null &&
        !widget.controller.isConnecting &&
        !widget.controller.isDrawingSelection;

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
  void _onInteractionStart(ScaleStartDetails details) {
    // Fire viewport move start event
    final transform = _transformationController.value;
    final translation = transform.getTranslation();
    final scale = transform.getMaxScaleOnAxis();

    final viewport = GraphViewport(
      x: translation.x,
      y: translation.y,
      zoom: scale,
    );
    widget.controller.events.viewport?.onMoveStart?.call(viewport);
  }

  void _onInteractionUpdate(ScaleUpdateDetails details) {
    // Update viewport in store during interaction for real-time updates
    final transform = _transformationController.value;
    final translation = transform.getTranslation();
    final scale = transform.getMaxScaleOnAxis();

    final viewport = GraphViewport(
      x: translation.x,
      y: translation.y,
      zoom: scale,
    );
    widget.controller.setViewport(viewport);

    // Fire viewport move event
    widget.controller.events.viewport?.onMove?.call(viewport);
  }

  void _onInteractionEnd(ScaleEndDetails details) {
    // Update viewport in store when interaction ends to keep store in sync
    final transform = _transformationController.value;
    final translation = transform.getTranslation();
    final scale = transform.getMaxScaleOnAxis();

    final viewport = GraphViewport(
      x: translation.x,
      y: translation.y,
      zoom: scale,
    );
    widget.controller.setViewport(viewport);

    // Fire viewport move end event
    widget.controller.events.viewport?.onMoveEnd?.call(viewport);
  }

  void _handlePointerDown(PointerDownEvent event) {
    // Handle secondary button (right-click) for context menu
    if (_handleContextMenu(event)) {
      return;
    }

    // Early return if all interactions are disabled
    if (!widget.enableSelection &&
        !widget.enableNodeDragging &&
        !widget.enableConnectionCreation) {
      return;
    }

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

    // Store initial pointer position immediately
    widget.controller._setPointerPosition(event.localPosition);

    // No longer needed - isInteractingWithPort removed

    if (HardwareKeyboard.instance.isShiftPressed && widget.enableSelection) {
      _startSelectionDrag(event.localPosition);
      return;
    }

    if (hitResult.isPort && widget.enableConnectionCreation) {
      // No longer needed - isInteractingWithPort removed
      _handlePortInteraction(hitResult);
      return;
    }

    switch (hitResult.hitType) {
      case HitTarget.node:
        final isCmd = HardwareKeyboard.instance.isMetaPressed;
        final isCtrl = HardwareKeyboard.instance.isControlPressed;
        final isNodeSelected = widget.controller.isNodeSelected(
          hitResult.nodeId!,
        );

        if (isCmd || isCtrl) {
          // Command+click: toggle selection AND enable dragging for group operations
          widget.controller.selectNode(hitResult.nodeId!, toggle: true);

          // Selection is handled by controller - no need to fire callbacks here

          if (widget.enableNodeDragging) {
            // Start dragging with Command held down for group operations
            widget.controller._startNodeDrag(
              hitResult.nodeId!,
              event.localPosition,
              widget.theme.cursorTheme.dragCursor,
            );
            // Disable panning to allow Command+drag of nodes over canvas
            widget.controller._updateInteractionState(panEnabled: false);
          }
        } else if (widget.enableNodeDragging) {
          if (!isNodeSelected) {
            widget.controller.selectNode(hitResult.nodeId!);
          }

          // Normal drag without Command
          widget.controller._startNodeDrag(
            hitResult.nodeId!,
            event.localPosition,
            widget.theme.cursorTheme.dragCursor,
          );
        } else {
          // Handle simple node click when dragging is disabled
          widget.controller.selectNode(hitResult.nodeId!);
        }
        break;

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

      case HitTarget.annotation:
        final isCmd = HardwareKeyboard.instance.isMetaPressed;
        final isCtrl = HardwareKeyboard.instance.isControlPressed;

        final annotationId = hitResult.annotationId!;
        final annotation = widget.controller.annotations.getAnnotation(
          annotationId,
        );

        if (annotation != null && annotation.isInteractive) {
          if (isCmd || isCtrl) {
            // Toggle selection with modifier key
            widget.controller.selectAnnotation(annotationId, toggle: true);
          } else {
            // Start dragging the annotation
            widget.controller._startAnnotationDrag(
              annotationId,
              event.localPosition,
            );
            // Select if not already selected
            if (!widget.controller.annotations.isAnnotationSelected(
              annotationId,
            )) {
              widget.controller.selectAnnotation(annotationId);
            }
            // Disable panning while dragging annotation
            widget.controller._updateInteractionState(panEnabled: false);
          }
        }
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
    final worldPosition = widget.controller.viewport.screenToGraph(
      event.localPosition,
    );
    widget.controller.setMousePositionWorld(worldPosition);

    // Reset tap tracking if user moves significantly (they're dragging, not tapping)
    const dragThreshold = 5.0; // pixels
    if (_initialPointerPosition != null &&
        (event.localPosition - _initialPointerPosition!).distance >
            dragThreshold) {
      _shouldClearSelectionOnTap = false;
    }

    // Ultra-fast path for viewport panning - let InteractiveViewer handle it
    // BUT skip panning if we're dragging an annotation
    if (widget.controller.draggedNodeId == null &&
        widget.controller.annotations.draggedAnnotationId == null &&
        !widget.controller.isDrawingSelection &&
        !widget.controller.isConnecting &&
        widget.controller.panEnabled) {
      // Skip all processing during viewport panning for maximum performance
      return;
    }

    // Fast path for node dragging - batched updates with theme-aware positioning
    if (widget.controller.draggedNodeId != null &&
        widget.controller.lastPointerPosition != null) {
      final delta =
          event.localPosition - widget.controller.lastPointerPosition!;
      final graphDelta = widget.controller.viewport.screenToGraphDelta(delta);

      // Batch position and pointer updates in single runInAction
      widget.controller._moveNodeDrag(
        widget.controller.draggedNodeId!,
        graphDelta,
        event.localPosition,
      );
      return;
    }

    // Handle annotation dragging
    if (widget.controller.annotations.draggedAnnotationId != null &&
        widget.controller.annotations.lastPointerPosition != null) {
      final delta =
          event.localPosition -
          widget.controller.annotations.lastPointerPosition!;
      final graphDelta = widget.controller.viewport.screenToGraphDelta(delta);

      widget.controller._moveAnnotationDrag(event.localPosition, graphDelta);
      return;
    }

    if (widget.controller.isDrawingSelection) {
      // Ultra-fast path for selection rectangle updates
      _updateSelectionDrag(event.localPosition);
      // Skip expensive drag state update during selection for maximum performance
      return;
    }

    if (widget.controller.isConnecting || widget.controller.isConnecting) {
      _updateTemporaryConnection(event.localPosition);
      return;
    }

    // Only perform hit test when not in any interaction mode
    if (!widget.controller.isConnecting &&
        !widget.controller.isDrawingSelection) {
      final hitResult = _performHitTest(event.localPosition);
      _updateCursor(hitResult);
    }

    widget.controller._setPointerPosition(event.localPosition);
  }

  void _handlePointerUp(PointerUpEvent event) {
    // Re-enable panning if it was disabled (e.g., by ESC during connection)
    _updatePanState();

    // Check if this was a tap (minimal movement from initial position)
    const tapThreshold = 5.0; // pixels
    final wasTap =
        _initialPointerPosition != null &&
        (event.localPosition - _initialPointerPosition!).distance <
            tapThreshold;

    if (widget.controller.isDrawingSelection) {
      widget.controller._finishSelectionDrag();

      // Reset cursor after selection ends
      final hitResult = _performHitTest(event.localPosition);
      _updateCursor(hitResult);

      // Reset tap tracking
      _initialPointerPosition = null;
      _shouldClearSelectionOnTap = false;
      return;
    }

    if (widget.controller.isConnecting) {
      final hitResult = _performHitTest(event.localPosition);
      if (hitResult.isPort) {
        final tempConnection = widget.controller.temporaryConnection;
        // Only complete connection if it's a different port than the source
        if (tempConnection != null &&
            (hitResult.nodeId != tempConnection.startNodeId ||
                hitResult.portId != tempConnection.startPortId)) {
          _handlePortInteraction(hitResult);
        } else {
          // Same port or invalid target - cancel the connection
          widget.controller._cancelConnection();
        }
      } else {
        // Clicked on empty space - cancel the connection
        widget.controller._cancelConnection();
      }
    }

    // Track annotation drag state before cleanup (for panning re-enable)
    final wasAnnotationDragging =
        widget.controller.annotations.draggedAnnotationId != null;

    // Clean up drag state efficiently
    widget.controller._endNodeDrag();

    // Re-enable panning if we were dragging an annotation
    if (wasAnnotationDragging) {
      widget.controller._updateInteractionState(panEnabled: true);
    }

    widget.controller._endAnnotationDrag();

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

    _updateCursor(hitResult);
  }

  // Helper methods

  void _startSelectionDrag(Offset startPosition) {
    final startGraph = widget.controller.viewport.screenToGraph(startPosition);
    widget.controller._updateSelectionDrag(
      startPoint: startGraph,
      rectangle: Rect.fromPoints(
        startGraph,
        startGraph,
      ), // Start with zero-size rect
    );

    // Update cursor to precise immediately when selection starts
    widget.controller._updateInteractionState(
      cursor: SystemMouseCursors.precise,
    );

    // Force pan state update to disable panning during selection
    _updatePanState();
  }

  void _updateSelectionDrag(Offset currentPosition) {
    final startPoint = widget.controller.selectionStartPoint;
    if (startPoint == null) return;

    final currentGraph = widget.controller.viewport.screenToGraph(
      currentPosition,
    );
    final rect = Rect.fromPoints(startPoint, currentGraph);

    // Update visual rectangle and handle selection in one call
    widget.controller._updateSelectionDrag(
      rectangle: rect,
      intersectingNodes: _getIntersectingNodes(rect),
      toggle: HardwareKeyboard.instance.isMetaPressed,
    );
  }

  List<String> _getIntersectingNodes(Rect rect) {
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

  bool _isValidConnection(HitTestResult hitResult) {
    final tempConnection = widget.controller.temporaryConnection;
    if (tempConnection == null || !hitResult.isPort) {
      return false;
    }

    // Can't connect to the same port
    if (hitResult.nodeId == tempConnection.startNodeId &&
        hitResult.portId == tempConnection.startPortId) {
      return false;
    }

    // Get source port info from temporary connection
    final sourceNode = widget.controller.getNode(tempConnection.startNodeId);
    if (sourceNode == null) return false;

    // Determine if source port is output
    final isSourceOutput = sourceNode.outputPorts.any(
      (port) => port.id == tempConnection.startPortId,
    );
    final isTargetOutput = hitResult.isOutput ?? false;

    // Valid connections: output -> input or input -> output
    return isSourceOutput != isTargetOutput;
  }

  void _handlePortInteraction(HitTestResult hitResult) {
    if (widget.controller.isConnecting) {
      // Complete connection - validate first
      if (_isValidConnection(hitResult)) {
        final tempConnection = widget.controller.temporaryConnection;
        if (tempConnection == null) return;

        // Get nodes and ports for validation context
        final sourceNode = widget.controller.getNode(
          tempConnection.startNodeId,
        );
        final targetNode = widget.controller.getNode(hitResult.nodeId!);

        if (sourceNode == null || targetNode == null) {
          widget.controller._cancelConnection();
          return;
        }

        final sourcePort = [
          ...sourceNode.inputPorts,
          ...sourceNode.outputPorts,
        ].where((p) => p.id == tempConnection.startPortId).firstOrNull;
        final targetPort = [
          ...targetNode.inputPorts,
          ...targetNode.outputPorts,
        ].where((p) => p.id == hitResult.portId!).firstOrNull;

        if (sourcePort == null || targetPort == null) {
          widget.controller._cancelConnection();
          return;
        }

        // Get existing connections that would be affected
        final existingSourceConnections = widget.controller.connections
            .where(
              (c) =>
                  c.sourceNodeId == tempConnection.startNodeId &&
                  c.sourcePortId == tempConnection.startPortId,
            )
            .map((c) => c.id)
            .toList();

        final existingTargetConnections = widget.controller.connections
            .where(
              (c) =>
                  c.targetNodeId == hitResult.nodeId! &&
                  c.targetPortId == hitResult.portId!,
            )
            .map((c) => c.id)
            .toList();

        // Create validation context
        final context = ConnectionCompleteContext<T>(
          sourceNode: sourceNode,
          sourcePort: sourcePort,
          targetNode: targetNode,
          targetPort: targetPort,
          existingSourceConnections: existingSourceConnections,
          existingTargetConnections: existingTargetConnections,
        );

        // Check user-defined validation
        final validationCallback =
            widget.controller.events.connection?.onBeforeComplete;
        if (validationCallback != null) {
          final result = validationCallback(context);
          if (!result.allowed) {
            widget.controller._cancelConnection();
            return;
          }
        }

        // Track connections that will be removed (for ports that don't allow multiple connections)
        final connectionsToBeRemoved = <Connection>[];

        // Check target port connections
        if (!targetPort.multiConnections) {
          connectionsToBeRemoved.addAll(
            widget.controller.connections.where(
              (c) =>
                  c.targetNodeId == hitResult.nodeId! &&
                  c.targetPortId == hitResult.portId!,
            ),
          );
        }

        // Check source port connections
        if (!sourcePort.multiConnections) {
          connectionsToBeRemoved.addAll(
            widget.controller.connections.where(
              (c) =>
                  c.sourceNodeId == tempConnection.startNodeId &&
                  c.sourcePortId == tempConnection.startPortId,
            ),
          );
        }

        widget.controller._completeConnection(
          hitResult.nodeId!,
          hitResult.portId!,
        );

        // Connection deletion callbacks handled by controller via events

        // Connection creation callback handled by controller
      } else {
        // Invalid connection - cancel it
        widget.controller._cancelConnection();
      }
    } else {
      // Start connection - validate first
      final node = widget.controller.getNode(hitResult.nodeId!);
      if (node == null) return;

      final port = [
        ...node.inputPorts,
        ...node.outputPorts,
      ].where((p) => p.id == hitResult.portId!).firstOrNull;

      if (port == null) return;

      // Get existing connections from this port
      final existingConnections = widget.controller.connections
          .where(
            (c) =>
                (hitResult.isOutput! &&
                    c.sourceNodeId == hitResult.nodeId! &&
                    c.sourcePortId == hitResult.portId!) ||
                (!hitResult.isOutput! &&
                    c.targetNodeId == hitResult.nodeId! &&
                    c.targetPortId == hitResult.portId!),
          )
          .map((c) => c.id)
          .toList();

      // Create validation context
      final context = ConnectionStartContext<T>(
        sourceNode: node,
        sourcePort: port,
        existingConnections: existingConnections,
      );

      // Check user-defined validation
      final validationCallback =
          widget.controller.events.connection?.onBeforeStart;
      if (validationCallback != null) {
        final result = validationCallback(context);
        if (!result.allowed) {
          return;
        }
      }

      widget.controller._startConnection(
        hitResult.nodeId!,
        hitResult.portId!,
        hitResult.isOutput!,
      );

      // Connection deletion callbacks handled by controller via events

      final theme = widget.theme;
      final shape = widget.controller.nodeShapeBuilder?.call(node);
      // Use cascade: port.size → theme.size
      final effectivePortSize = port.size ?? theme.portTheme.size;
      final portPosition = node.getPortPosition(
        hitResult.portId!,
        portSize: effectivePortSize,
        shape: shape,
      );

      widget.controller._setTemporaryConnection(
        TemporaryConnection(
          startPoint: portPosition,
          startNodeId: hitResult.nodeId!,
          startPortId: hitResult.portId!,
          isStartFromOutput: hitResult.isOutput!,
          startNodeBounds: node.getBounds(),
          initialCurrentPoint: portPosition,
        ),
      );
    }
  }

  void _updateTemporaryConnection(Offset currentScreenPosition) {
    final temp = widget.controller.temporaryConnection;
    if (temp == null) return;

    final currentGraphPosition = widget.controller.viewport.screenToGraph(
      currentScreenPosition,
    );

    // Check for port snapping during connection drag
    String? targetNodeId;
    String? targetPortId;
    Rect? targetNodeBounds;
    Offset finalPosition = currentGraphPosition;

    // Perform hit test to find nearby ports for snapping
    final hitResult = _performHitTest(currentScreenPosition);
    // Allow snapping to any port except the exact same port we started from
    // This enables self-connections (connecting different ports on the same node)
    final isSamePort =
        hitResult.nodeId == temp.startNodeId &&
        hitResult.portId == temp.startPortId;
    if (hitResult.isPort && !isSamePort) {
      // Found a target port to snap to
      targetNodeId = hitResult.nodeId;
      targetPortId = hitResult.portId;

      // Update position to port center for snapping
      final targetNode = widget.controller.getNode(hitResult.nodeId!);
      if (targetNode != null) {
        targetNodeBounds = targetNode.getBounds();
        final theme = widget.theme;
        final shape = widget.controller.nodeShapeBuilder?.call(targetNode);
        // Find the target port to get its size
        final targetPort = [
          ...targetNode.inputPorts,
          ...targetNode.outputPorts,
        ].where((p) => p.id == hitResult.portId!).firstOrNull;
        // Use cascade: port.size → theme.size
        final effectivePortSize = targetPort?.size ?? theme.portTheme.size;
        finalPosition = targetNode.getPortPosition(
          hitResult.portId!,
          portSize: effectivePortSize,
          shape: shape,
        );
      }
    }

    // Use batched update for better performance
    widget.controller._updateTemporaryConnection(
      currentScreenPosition,
      finalPosition,
      targetNodeId,
      targetPortId,
      targetNodeBounds,
    );
  }
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
