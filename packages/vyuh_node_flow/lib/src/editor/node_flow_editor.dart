import 'package:flutter/gestures.dart' hide HitTestResult;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:mobx/mobx.dart' hide Listener;
import 'package:vector_math/vector_math_64.dart' hide Colors;

import '../connections/connection.dart';
import '../connections/styles/connection_style_base.dart';
import '../connections/temporary_connection.dart';
import '../graph/coordinates.dart';
import '../graph/viewport.dart';
import '../nodes/node.dart';
import '../nodes/node_shape.dart';
import '../plugins/autopan/autopan_zone_debug_layer.dart';
import '../plugins/debug/debug_plugin.dart';
import '../plugins/layer_provider.dart';
import '../ports/port.dart';
import '../ports/port_widget.dart';
import '../shared/spatial/graph_spatial_index.dart';
import 'controller/node_flow_controller.dart';
import 'hit_test_result.dart';
import 'keyboard/keyboard_actions.dart';
import 'layers/attribution_overlay.dart';
import 'layers/connection_labels_layer.dart';
import 'layers/connections_layer.dart';
import 'layers/grid_layer.dart';
import 'layers/interaction_layer.dart';
import 'layers/nodes_layer.dart';
import 'node_flow_behavior.dart';
import 'node_flow_events.dart';
import 'node_flow_scope.dart';
import 'themes/cursor_theme.dart';
import 'themes/node_flow_theme.dart';
import 'unbounded_widgets.dart';
import 'viewport_animation_mixin.dart';

part 'controller/node_flow_controller_plugins.dart';
part 'node_flow_editor_hit_testing.dart';
part 'node_flow_editor_widget_handlers.dart';

/// Builder for custom node thumbnail painting.
///
/// Called for each node when rendering in thumbnail mode.
/// Return `true` if you handled the painting, `false` to use default.
typedef ThumbnailBuilder<T> =
    bool Function(Canvas canvas, Node<T> node, Rect bounds, bool isSelected);

/// Node flow editor widget using MobX for reactive state management.
///
/// This is the main widget for displaying and interacting with a node-based graph.
/// It provides a highly interactive canvas with support for:
/// - Node rendering with custom builders (including GroupNode and CommentNode)
/// - Connection creation and management
/// - Multiple selection modes
/// - Viewport panning and zooming
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
class NodeFlowEditor<T, C> extends StatefulWidget {
  const NodeFlowEditor({
    super.key,
    required this.controller,
    required this.theme,
    required this.nodeBuilder,
    this.nodeShapeBuilder,
    this.portBuilder,
    this.connectionStyleBuilder,
    this.labelBuilder,
    this.thumbnailBuilder,
    this.events,
    this.behavior = NodeFlowBehavior.design,
  });

  /// The controller that manages the graph state.
  ///
  /// This controller holds all nodes (including GroupNode and CommentNode),
  /// connections, viewport state, and provides methods for manipulating the graph.
  final NodeFlowController<T, C> controller;

  /// Builder function for rendering node content.
  ///
  /// This function is called for each node in the graph to create its visual
  /// representation. The returned widget is automatically wrapped in a NodeWidget.
  ///
  /// For full control over node rendering, implement [Node.buildWidget] to make
  /// your node self-rendering.
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
  /// - NodeWidget to render shaped nodes
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

  /// Optional custom thumbnail painter for nodes.
  ///
  /// When provided, called for each node in thumbnail mode.
  /// Return `true` to indicate custom painting was done,
  /// `false` to fall back to the node's default `paintThumbnail`.
  final ThumbnailBuilder<T>? thumbnailBuilder;

  /// Optional builder for dynamic connection styling.
  ///
  /// This callback is invoked for each connection during rendering, receiving
  /// the connection and its source/target nodes. This enables dynamic styling
  /// based on node state, connection data, or any runtime conditions.
  ///
  /// ## Style Cascade
  /// Styles are resolved in this order:
  /// 1. `connectionStyleBuilder` result (if provided and non-null)
  /// 2. Connection instance properties ([Connection.color], etc.)
  /// 3. Theme colors (from [ConnectionTheme])
  ///
  /// ## Example
  /// ```dart
  /// connectionStyleBuilder: (connection, sourceNode, targetNode) {
  ///   // Style based on source node state
  ///   if (sourceNode.data?.hasError == true) {
  ///     return ConnectionStyle(color: Colors.red, strokeWidth: 3.0);
  ///   }
  ///   // Style based on connection data
  ///   if (connection.data?['priority'] == 'high') {
  ///     return ConnectionStyle(color: Colors.orange);
  ///   }
  ///   return null; // Use connection's static style or theme
  /// }
  /// ```
  /// The connection style builder for dynamic styling.
  ///
  /// Receives typed `Connection<C>` for type-safe pattern matching on connection data.
  ///
  /// ```dart
  /// // With typed connections
  /// connectionStyleBuilder: (connection, source, target) {
  ///   return switch (connection.data) {
  ///     HighPriority() => ConnectionStyle(color: Colors.red),
  ///     Normal() => null,
  ///     null => null,
  ///   };
  /// }
  /// ```
  final ConnectionStyleBuilder<T, C>? connectionStyleBuilder;

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
  final NodeFlowEvents<T, C>? events;

  /// The behavior mode for the canvas.
  ///
  /// Controls what operations are allowed:
  /// - [NodeFlowBehavior.design]: Full editing (default)
  /// - [NodeFlowBehavior.preview]: View and drag, no structural changes
  /// - [NodeFlowBehavior.present]: Display only, no interaction
  final NodeFlowBehavior behavior;

  @override
  State<NodeFlowEditor<T, C>> createState() => _NodeFlowEditorState<T, C>();
}

class _NodeFlowEditorState<T, C> extends State<NodeFlowEditor<T, C>>
    with TickerProviderStateMixin, ViewportAnimationMixin {
  late final TransformationController _transformationController;
  final List<ReactionDisposer> _disposers = [];
  bool _isSyncingViewportFromTransform = false;

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
  String? _lastHoveredEntityId; // nodeId, connectionId, or portId

  // Shift key tracking for selection mode cursor
  bool _isShiftPressed = false;

  // Pointer ID tracking for drag operations.
  // Used by the safety net in _handlePointerUp to only cleanup if the pointer
  // that started the drag is the one that ended. This prevents trackpad pointer
  // ups from prematurely ending mouse drags.
  int? _dragPointerId;

  // Touch-driven connection drag state (for mobile).
  bool _isTouchConnecting = false;
  int? _touchConnectionPointerId;
  Offset _touchConnectionPointerOffset = Offset.zero;

  bool _isTouchLike(PointerEvent event) {
    return event.kind == PointerDeviceKind.touch ||
        event.kind == PointerDeviceKind.stylus ||
        event.kind == PointerDeviceKind.invertedStylus;
  }

  @override
  void initState() {
    super.initState();

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

    // =========================================================================
    // CANONICAL CONTROLLER INITIALIZATION
    // =========================================================================
    // This is THE SINGLE PLACE where the controller is initialized for editor use.
    // All initialization happens in _initController in a specific, documented order.
    // See editor_init_api.dart for the full initialization sequence.
    final themePortSize = widget.theme.portTheme.size;

    widget.controller.initController(
      theme: widget.theme,
      portSizeResolver: (port) => port.size ?? themePortSize,
      nodeShapeBuilder: widget.nodeShapeBuilder != null
          ? (node) => widget.nodeShapeBuilder!(context, node)
          : null,
      connectionHitTesterBuilder: (painter) => (connection, point) {
        final sourceNode = widget.controller.getNode(connection.sourceNodeId);
        final targetNode = widget.controller.getNode(connection.targetNodeId);
        if (sourceNode == null || targetNode == null) return false;

        return painter.hitTestConnection(
          connection: connection,
          sourceNode: sourceNode,
          targetNode: targetNode,
          testPoint: point,
        );
      },
      connectionSegmentCalculator: (connection) {
        final sourceNode = widget.controller.getNode(connection.sourceNodeId);
        final targetNode = widget.controller.getNode(connection.targetNodeId);
        if (sourceNode == null || targetNode == null) return [];

        // Use current theme style, not a captured one from initState
        final pathCache = widget.controller.connectionPainter.pathCache;
        return pathCache.getOrCreateSegmentBounds(
          connection: connection,
          sourceNode: sourceNode,
          targetNode: targetNode,
          connectionStyle: pathCache.theme.connectionTheme.style,
        );
      },
      events: widget.events,
    );

    // Register keyboard handler for shift key cursor changes
    HardwareKeyboard.instance.addHandler(_handleKeyEvent);

    // Provide transformation controller to debug extension for layer rendering
    widget.controller.debug?.setTransformationController(
      _transformationController,
    );

    // Fire onInit event after initialization completes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      widget.controller.events.onInit?.call();
    });
  }

  @override
  void didUpdateWidget(NodeFlowEditor<T, C> oldWidget) {
    super.didUpdateWidget(oldWidget);
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

      // Update debug extension transformation controller reference
      oldWidget.controller.debug?.setTransformationController(null);
      widget.controller.debug?.setTransformationController(
        _transformationController,
      );
    }

    // Update behavior mode if it changed
    if (oldWidget.behavior != widget.behavior) {
      widget.controller.setBehavior(widget.behavior);
    }

    // Update node shape builder if it changed (uses internal method from editor_init_api)
    if (oldWidget.nodeShapeBuilder != widget.nodeShapeBuilder) {
      widget.controller.updateNodeShapeBuilder(
        widget.nodeShapeBuilder != null
            ? (node) => widget.nodeShapeBuilder!(context, node)
            : null,
      );
    }

    // Update events if they changed (uses internal method from editor_init_api)
    if (oldWidget.events != widget.events && widget.events != null) {
      widget.controller.updateEvents(widget.events!);
    }

    // Update theme if it changed (uses internal method from editor_init_api)
    if (oldWidget.theme != widget.theme) {
      widget.controller.updateTheme(widget.theme);
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

  /// Collects plugin layers for the given position relative to a core layer.
  ///
  /// Returns all widgets from plugins that implement [LayerProvider] and
  /// have their [LayerPosition] matching the given [anchor] and [relation].
  List<Widget> _getPluginLayers(
    BuildContext context,
    NodeFlowLayer anchor,
    LayerRelation relation,
  ) {
    final layers = <Widget>[];
    for (final plugin in widget.controller.plugins) {
      if (plugin is LayerProvider) {
        final provider = plugin as LayerProvider;
        if (provider.layerPosition.anchor == anchor &&
            provider.layerPosition.relation == relation) {
          final layer = provider.buildLayer(context);
          if (layer != null) {
            layers.add(layer);
          }
        }
      }
    }
    return layers;
  }

  @override
  Widget build(BuildContext context) {
    final theme = widget.theme;

    return Theme(
      data: Theme.of(context).copyWith(extensions: [theme]),
      child: NodeFlowScope<T>(
        controller: widget.controller,
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
                onPointerCancel: _handlePointerCancel,
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
                        // Wrapped in Observer to react to canvasLocked changes
                        Observer.withBuiltChild(
                          builder: (context, child) {
                            // When canvas is locked, disable both pan and zoom
                            final isLocked = widget.controller.canvasLocked;
                            return InteractiveViewer(
                              transformationController:
                                  _transformationController,
                              boundaryMargin: const EdgeInsets.all(
                                double.infinity,
                              ),
                              constrained: false,
                              minScale: widget.controller.config.minZoom.value,
                              maxScale: widget.controller.config.maxZoom.value,
                              // Respect both behavior config and lock state
                              panEnabled: widget.behavior.canPan && !isLocked,
                              scaleEnabled:
                                  widget.behavior.canZoom && !isLocked,
                              trackpadScrollCausesScale:
                                  widget.controller.config.scrollToZoom.value,
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
                                // Extension layers: before grid
                                ..._getPluginLayers(
                                  context,
                                  NodeFlowLayer.grid,
                                  LayerRelation.before,
                                ),

                                // Background grid
                                GridLayer(
                                  controller: widget.controller,
                                  theme: theme,
                                  transformationController:
                                      _transformationController,
                                ),

                                // Extension layers: after grid, before backgroundNodes
                                ..._getPluginLayers(
                                  context,
                                  NodeFlowLayer.grid,
                                  LayerRelation.after,
                                ),
                                ..._getPluginLayers(
                                  context,
                                  NodeFlowLayer.backgroundNodes,
                                  LayerRelation.before,
                                ),

                                // Background nodes (GroupNode) - drag handled via NodeWidget
                                NodesLayer.background(
                                  widget.controller,
                                  widget.nodeBuilder,
                                  portBuilder: widget.portBuilder,
                                  thumbnailBuilder: widget.thumbnailBuilder,
                                  onNodeTap: _handleNodeTap,
                                  onNodeDoubleTap: _handleNodeDoubleTap,
                                  onNodeContextMenu: _handleNodeContextMenu,
                                  onNodeMouseEnter: _handleNodeMouseEnter,
                                  onNodeMouseLeave: _handleNodeMouseLeave,
                                  onPortContextMenu: _handlePortContextMenu,
                                  portSnapDistance: widget
                                      .controller
                                      .config
                                      .portSnapDistance
                                      .value,
                                ),

                                // Extension layers: after backgroundNodes, before connections
                                ..._getPluginLayers(
                                  context,
                                  NodeFlowLayer.backgroundNodes,
                                  LayerRelation.after,
                                ),
                                ..._getPluginLayers(
                                  context,
                                  NodeFlowLayer.connections,
                                  LayerRelation.before,
                                ),

                                // Connections
                                ConnectionsLayer<T, C>(
                                  controller: widget.controller,
                                  animation: _connectionAnimationController,
                                  connectionStyleBuilder:
                                      widget.connectionStyleBuilder,
                                ),

                                // Extension layers: after connections, before connectionLabels
                                ..._getPluginLayers(
                                  context,
                                  NodeFlowLayer.connections,
                                  LayerRelation.after,
                                ),
                                ..._getPluginLayers(
                                  context,
                                  NodeFlowLayer.connectionLabels,
                                  LayerRelation.before,
                                ),

                                // Connection labels
                                ConnectionLabelsLayer<T>(
                                  controller: widget.controller,
                                  labelBuilder: widget.labelBuilder,
                                ),

                                // Extension layers: after connectionLabels, before middleNodes
                                ..._getPluginLayers(
                                  context,
                                  NodeFlowLayer.connectionLabels,
                                  LayerRelation.after,
                                ),
                                ..._getPluginLayers(
                                  context,
                                  NodeFlowLayer.middleNodes,
                                  LayerRelation.before,
                                ),

                                // Middle layer nodes (regular nodes)
                                NodesLayer.middle(
                                  widget.controller,
                                  widget.nodeBuilder,
                                  portBuilder: widget.portBuilder,
                                  thumbnailBuilder: widget.thumbnailBuilder,
                                  onNodeTap: _handleNodeTap,
                                  onNodeDoubleTap: _handleNodeDoubleTap,
                                  onNodeContextMenu: _handleNodeContextMenu,
                                  onNodeMouseEnter: _handleNodeMouseEnter,
                                  onNodeMouseLeave: _handleNodeMouseLeave,
                                  onPortContextMenu: _handlePortContextMenu,
                                  portSnapDistance: widget
                                      .controller
                                      .config
                                      .portSnapDistance
                                      .value,
                                ),

                                // Extension layers: after middleNodes, before foregroundNodes
                                ..._getPluginLayers(
                                  context,
                                  NodeFlowLayer.middleNodes,
                                  LayerRelation.after,
                                ),
                                ..._getPluginLayers(
                                  context,
                                  NodeFlowLayer.foregroundNodes,
                                  LayerRelation.before,
                                ),

                                // Foreground nodes (CommentNode) - drag handled via NodeWidget
                                NodesLayer.foreground(
                                  widget.controller,
                                  widget.nodeBuilder,
                                  portBuilder: widget.portBuilder,
                                  thumbnailBuilder: widget.thumbnailBuilder,
                                  onNodeTap: _handleNodeTap,
                                  onNodeDoubleTap: _handleNodeDoubleTap,
                                  onNodeContextMenu: _handleNodeContextMenu,
                                  onNodeMouseEnter: _handleNodeMouseEnter,
                                  onNodeMouseLeave: _handleNodeMouseLeave,
                                  onPortContextMenu: _handlePortContextMenu,
                                  portSnapDistance: widget
                                      .controller
                                      .config
                                      .portSnapDistance
                                      .value,
                                ),

                                // Extension layers: after foregroundNodes
                                // Note: SnapLinesLayer and DebugLayersStack are now provided
                                // via LayerProvider by their respective extensions
                                ..._getPluginLayers(
                                  context,
                                  NodeFlowLayer.foregroundNodes,
                                  LayerRelation.after,
                                ),
                              ],
                            ),
                          ),
                        ),

                        // Extension layers: before interaction
                        ..._getPluginLayers(
                          context,
                          NodeFlowLayer.interaction,
                          LayerRelation.before,
                        ),

                        // Interaction layer - renders temporary connections and selection rectangles
                        // Positioned outside the canvas to render anywhere on the infinite canvas
                        // Uses IgnorePointer - all event handling is done by the Listener above
                        Positioned.fill(
                          child: InteractionLayer<T>(
                            controller: widget.controller,
                            transformationController: _transformationController,
                            animation: _connectionAnimationController,
                            temporaryStyleResolver:
                                widget.connectionStyleBuilder == null
                                ? null
                                : _resolveTemporaryConnectionStyle,
                          ),
                        ),

                        // Extension layers: after interaction, before overlays
                        ..._getPluginLayers(
                          context,
                          NodeFlowLayer.interaction,
                          LayerRelation.after,
                        ),
                        // Extension layers: before overlays
                        // Note: MinimapOverlay is now provided via LayerProvider
                        // by MinimapExtension
                        ..._getPluginLayers(
                          context,
                          NodeFlowLayer.overlays,
                          LayerRelation.before,
                        ),

                        // Attribution overlay - bottom center
                        AttributionOverlay(
                          show: widget.controller.config.showAttribution,
                        ),

                        // Extension layers: after overlays
                        ..._getPluginLayers(
                          context,
                          NodeFlowLayer.overlays,
                          LayerRelation.after,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  void _setupReactions() {
    // Sync transformation controller with viewport changes - immediate synchronous updates
    _disposers.add(
      reaction((_) => widget.controller.viewport, (GraphViewport viewport) {
        if (mounted) {
          if (!viewport.x.isFinite ||
              !viewport.y.isFinite ||
              !viewport.zoom.isFinite ||
              viewport.zoom <= 0) {
            return;
          }

          // Skip feedback updates when viewport was just synced from transform.
          if (_isSyncingViewportFromTransform) {
            return;
          }

          // Avoid redundant matrix writes (which trigger listeners/repaints)
          // when InteractiveViewer already has the same transform.
          final currentTransform = _transformationController.value;
          final currentTranslation = currentTransform.getTranslation();
          final currentZoom = currentTransform.getMaxScaleOnAxis();
          if ((currentTranslation.x - viewport.x).abs() < 0.01 &&
              (currentTranslation.y - viewport.y).abs() < 0.01 &&
              (currentZoom - viewport.zoom).abs() < 0.0001) {
            return;
          }

          final matrix = Matrix4.identity()
            ..translateByVector3(Vector3(viewport.x, viewport.y, 0))
            ..scaleByDouble(viewport.zoom, viewport.zoom, viewport.zoom, 1.0);

          // Force immediate update without animation for real-time panning
          _transformationController.value = matrix;
        }
      }, fireImmediately: true),
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

  // NOTE: _updateNodeShapeBuilder(), _setupSpatialIndexCallbacks(),
  // _completeSpatialIndexSetup(), and _rebuildConnectionSpatialIndex() have been
  // removed. All initialization is now handled by _initController() in
  // editor_init_api.dart. Post-initialization updates use the private methods
  // _updateTheme(), _updateEvents(), and _updateNodeShapeBuilder() on the controller.

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

  ConnectionStyle? _resolveTemporaryConnectionStyle(
    TemporaryConnection temporary,
    Node<T> startNode,
    Port startPort,
    Node<T>? hoveredNode,
    Port? hoveredPort,
  ) {
    final styleBuilder = widget.connectionStyleBuilder;
    if (styleBuilder == null || hoveredNode == null || hoveredPort == null) {
      return null;
    }

    final Node<T> sourceNode;
    final Port sourcePort;
    final Node<T> targetNode;
    final Port targetPort;

    if (temporary.isStartFromOutput) {
      sourceNode = startNode;
      sourcePort = startPort;
      targetNode = hoveredNode;
      targetPort = hoveredPort;
    } else {
      sourceNode = hoveredNode;
      sourcePort = hoveredPort;
      targetNode = startNode;
      targetPort = startPort;
    }

    final temporaryEdge = Connection<C>(
      id:
          '__temp_${sourceNode.id}_${sourcePort.id}_'
          '${targetNode.id}_${targetPort.id}',
      sourceNodeId: sourceNode.id,
      sourcePortId: sourcePort.id,
      targetNodeId: targetNode.id,
      targetPortId: targetPort.id,
    );

    return styleBuilder(temporaryEdge, sourceNode, targetNode);
  }

  @override
  void dispose() {
    // Remove keyboard handler
    HardwareKeyboard.instance.removeHandler(_handleKeyEvent);

    // Remove transform listener before disposing
    _transformationController.removeListener(_syncViewportFromTransform);

    // Detach viewport animation - this also clears the handler with token check
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
  /// - Accurate hit testing (nodes, ports, connections)
  /// - Correct coordinate conversion (screen ↔ graph coordinates)
  /// - Proper spatial index queries
  ///
  /// The onInteraction* callbacks also call setViewport, but empirically
  /// they don't work reliably in all cases. This listener is the safety net.
  ///
  /// IMPORTANT: This sync is skipped during viewport animation to prevent
  /// the animation from being interrupted. During active pan/zoom gestures,
  /// this still syncs every transform tick so hit testing and culling remain
  /// in lock-step with what the user sees.
  void _syncViewportFromTransform() {
    // Skip sync during animation - final sync happens via onAnimationComplete
    if (isViewportAnimating) {
      return;
    }

    final transform = _transformationController.value;
    final translation = transform.getTranslation();
    final currentZoom = transform.getMaxScaleOnAxis();
    if (!translation.x.isFinite ||
        !translation.y.isFinite ||
        !currentZoom.isFinite ||
        currentZoom <= 0) {
      return;
    }

    final viewport = GraphViewport(
      x: translation.x,
      y: translation.y,
      zoom: currentZoom,
    );

    final currentViewport = widget.controller.viewport;
    if (_isSameViewport(currentViewport, viewport)) {
      return;
    }

    _syncViewportToController(viewport);
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
    widget.controller.events.viewport?.onMove?.call(
      widget.controller.viewport,
    );
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

  void _syncViewportToController(GraphViewport viewport) {
    _isSyncingViewportFromTransform = true;
    try {
      widget.controller.setViewport(viewport);
    } finally {
      _isSyncingViewportFromTransform = false;
    }
  }

  bool _isSameViewport(GraphViewport a, GraphViewport b) {
    return (a.x - b.x).abs() < 0.01 &&
        (a.y - b.y).abs() < 0.01 &&
        (a.zoom - b.zoom).abs() < 0.0001;
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

    // Request focus when clicking on canvas background (not on nodes/ports)
    if (!hitResult.isNode &&
        !hitResult.isPort &&
        !widget.controller.canvasFocusNode.hasFocus) {
      widget.controller.canvasFocusNode.requestFocus();
    }

    // Store initial pointer position for tap detection
    _initialPointerPosition = event.localPosition;
    _shouldClearSelectionOnTap = false;

    // Store initial pointer position in widget-local coordinates
    widget.controller._setPointerPosition(ScreenPosition(event.localPosition));

    // CRITICAL: Lock canvas IMMEDIATELY for ANY interactive element (node or port)
    // This prevents InteractiveViewer from competing for drag gestures in the gesture arena.
    // Canvas will be unlocked in _handlePointerUp or by the operation's end handler.
    //
    // Only capture pointer ID if we're not already tracking a drag pointer.
    // This prevents a second pointer from overwriting the original drag pointer.
    if (hitResult.isNode || hitResult.isPort) {
      widget.controller._updateInteractionState(canvasLocked: true);
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
    //
    // On touch devices, start connection drag here to ensure we keep receiving
    // pointer updates even after leaving the port bounds.
    if (hitResult.isPort &&
        _isTouchLike(event) &&
        widget.behavior.canCreate &&
        !_isTouchConnecting) {
      final node = widget.controller.getNode(hitResult.nodeId!);
      if (node != null) {
        final port = _findPort(node, hitResult.portId!);
        if (port != null) {
          final theme = widget.controller.theme ?? NodeFlowTheme.light;
          final portTheme = theme.portTheme;
          final effectivePortSize = port.size ?? portTheme.size;
          final shape = widget.controller.nodeShapeBuilder?.call(node);

          final startPoint = node.getConnectionPoint(
            port.id,
            portSize: effectivePortSize,
            shape: shape,
          );

          final result = widget.controller.startConnectionDrag(
            nodeId: node.id,
            portId: port.id,
            isOutput: hitResult.isOutput ?? false,
            startPoint: startPoint,
            nodeBounds: node.getBounds(),
            initialScreenPosition: event.position,
          );

          if (result.allowed) {
            _isTouchConnecting = true;
            _touchConnectionPointerId = event.pointer;

            final pointerGraphPos = widget.controller
                .screenToGraph(ScreenPosition(event.position))
                .offset;
            _touchConnectionPointerOffset = startPoint - pointerGraphPos;
          }
        }
      }
    }

    switch (hitResult.hitType) {
      // Node selection is handled by widget-level handlers:
      // - _handleNodeTap for tap gestures
      // - startNodeDrag for drag gestures (selects if not already selected)
      // This includes GroupNode and CommentNode which are now regular nodes.
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
    // Mouse world tracking is only needed for spatial-index debug overlays.
    if (_shouldTrackMouseWorldPosition) {
      final worldPosition = widget.controller.viewport.toGraph(
        ScreenPosition(event.localPosition),
      );
      widget.controller.setMousePositionWorld(worldPosition);
    }

    // Touch-driven connection drag updates
    if (_isTouchConnecting &&
        _touchConnectionPointerId != null &&
        event.pointer == _touchConnectionPointerId) {
      final pointerGraphPos = widget.controller
          .screenToGraph(ScreenPosition(event.position))
          .offset;
      final newEndPoint = pointerGraphPos + _touchConnectionPointerOffset;

      final hitResult = widget.controller.hitTestPort(newEndPoint);
      Rect? targetNodeBounds;
      if (hitResult != null) {
        final targetNode = widget.controller.getNode(hitResult.nodeId);
        targetNodeBounds = targetNode?.getBounds();
      }

      widget.controller.updateConnectionDrag(
        graphPosition: newEndPoint,
        targetNodeId: hitResult?.nodeId,
        targetPortId: hitResult?.portId,
        targetNodeBounds: targetNodeBounds,
      );
      return;
    }

    // Reset tap tracking if user moves significantly (they're dragging, not tapping)
    const dragThreshold = 5.0; // pixels
    if (_initialPointerPosition != null &&
        (event.localPosition - _initialPointerPosition!).distance >
            dragThreshold) {
      _shouldClearSelectionOnTap = false;
    }

    // Note: Node drag is now handled by GestureDetector in NodeWidget
    // (via _handleNodeDragUpdate) to allow widgets inside nodes to win drag gestures.

    // Note: Node drag (including GroupNode, CommentNode) is handled by
    // GestureDetector in NodeWidget with direct controller access.

    // Note: Connection drag is now handled by GestureDetector in PortWidget
    // with dragStartBehavior.down to win the gesture arena immediately.

    // Ultra-fast path for viewport panning - let InteractiveViewer handle it
    if (!widget.controller.isDrawingSelection &&
        !widget.controller.isConnecting &&
        !widget.controller.canvasLocked) {
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

  bool get _shouldTrackMouseWorldPosition =>
      widget.controller.debug?.showSpatialIndex ?? false;

  void _handlePointerUp(PointerUpEvent event) {
    // Complete touch-driven connection drag
    if (_isTouchConnecting &&
        _touchConnectionPointerId != null &&
        event.pointer == _touchConnectionPointerId) {
      final temp = widget.controller.temporaryConnection;
      if (temp != null &&
          temp.targetNodeId != null &&
          temp.targetPortId != null) {
        widget.controller.completeConnectionDrag(
          targetNodeId: temp.targetNodeId!,
          targetPortId: temp.targetPortId!,
        );
      } else {
        widget.controller.cancelConnectionDrag();
      }
      _isTouchConnecting = false;
      _touchConnectionPointerId = null;
      _touchConnectionPointerOffset = Offset.zero;
    }

    // Check if this was a tap (minimal movement from initial position)
    const tapThreshold = 5.0; // pixels
    final wasTap =
        _initialPointerPosition != null &&
        (event.localPosition - _initialPointerPosition!).distance <
            tapThreshold;

    // Note: Node drag end is now handled by GestureDetector in NodeWidget
    // (via _handleNodeDragEnd) to allow widgets inside nodes to win drag gestures.

    // Note: All node drag ends (including GroupNode, CommentNode) are handled
    // by GestureDetector in NodeWidget with direct controller access.

    // Note: Connection drag end is now handled by pan gestures in PortWidget.
    // The GestureDetector's onPanEnd handles completion/cancellation.

    // Unlock canvas if no operation is active.
    // This handles the case where pointer down locked canvas but no drag started.
    final controller = widget.controller;
    if (!controller.isConnecting &&
        controller.draggedNodeId == null &&
        !controller.isResizing &&
        !controller.isDrawingSelection) {
      controller._updateInteractionState(canvasLocked: false);
    }

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
      // Clear the drag pointer ID after cleanup
      _dragPointerId = null;
    }

    // Cursor is derived from state via Observer - no update needed
  }

  void _handlePointerCancel(PointerCancelEvent event) {
    final controller = widget.controller;

    if (controller.isDrawingSelection) {
      controller._finishSelectionDrag();
    }

    if (controller.isConnecting) {
      controller.cancelConnectionDrag();
    }

    if (!controller.isConnecting &&
        controller.draggedNodeId == null &&
        !controller.isResizing &&
        !controller.isDrawingSelection) {
      controller._updateInteractionState(canvasLocked: false);
    }

    if (_dragPointerId == event.pointer) {
      _dragPointerId = null;
    }

    _initialPointerPosition = null;
    _shouldClearSelectionOnTap = false;
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

    // Lock canvas during selection drag
    widget.controller._updateInteractionState(canvasLocked: true);
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
        // Skip nodes that don't participate in marquee selection
        if (!node.selectable) continue;

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
