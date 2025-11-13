import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:mobx/mobx.dart' hide Listener;
import 'package:vector_math/vector_math_64.dart' hide Colors;

import '../annotations/annotation.dart';
import '../annotations/annotation_layer.dart';
import '../connections/connection.dart';
import '../connections/connection_validation.dart';
import '../connections/temporary_connection.dart';
import '../graph/node_flow_callbacks.dart';
import '../graph/node_flow_controller.dart';
import '../graph/node_flow_theme.dart';
import '../graph/viewport.dart';
import '../nodes/node.dart';
import '../nodes/node_shape.dart';
import '../ports/port.dart';
import '../shared/flutter_actions_integration.dart';
import 'canvas_transform_provider.dart';
import 'layers/attribution_overlay.dart';
import 'layers/connection_labels_layer.dart';
import 'layers/connections_layer.dart';
import 'layers/grid_layer.dart';
import 'layers/interaction_layer.dart';
import 'layers/minimap_overlay.dart';
import 'layers/nodes_layer.dart';

part 'node_flow_controller_extensions.dart';

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
    this.onNodeSelected,
    this.onNodeTap,
    this.onNodeDoubleTap,
    this.onNodeCreated,
    this.onNodeDeleted,
    this.onConnectionTap,
    this.onConnectionDoubleTap,
    this.onConnectionCreated,
    this.onConnectionDeleted,
    this.onConnectionSelected,
    this.onAnnotationSelected,
    this.onAnnotationTap,
    this.onAnnotationCreated,
    this.onAnnotationDeleted,
    this.onBeforeStartConnection,
    this.onBeforeCompleteConnection,
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

  /// The theme configuration for styling the editor.
  ///
  /// Controls colors, sizes, and visual appearance of nodes, connections,
  /// ports, and other UI elements.
  final NodeFlowTheme theme;

  /// Called when a node's selection state changes.
  ///
  /// Receives the selected node, or `null` if selection was cleared.
  final ValueChanged<Node<T>?>? onNodeSelected;

  /// Called when a node is tapped.
  final ValueChanged<Node<T>>? onNodeTap;

  /// Called when a node is double-tapped.
  final ValueChanged<Node<T>>? onNodeDoubleTap;

  /// Called when a node is created and added to the graph.
  final ValueChanged<Node<T>>? onNodeCreated;

  /// Called when a node is deleted from the graph.
  final ValueChanged<Node<T>>? onNodeDeleted;

  /// Called when a connection's selection state changes.
  ///
  /// Receives the selected connection, or `null` if selection was cleared.
  final ValueChanged<Connection?>? onConnectionSelected;

  /// Called when a connection is tapped.
  final ValueChanged<Connection>? onConnectionTap;

  /// Called when a connection is double-tapped.
  final ValueChanged<Connection>? onConnectionDoubleTap;

  /// Called when a connection is created.
  final ValueChanged<Connection>? onConnectionCreated;

  /// Called when a connection is deleted.
  final ValueChanged<Connection>? onConnectionDeleted;

  /// Called when an annotation's selection state changes.
  ///
  /// Receives the selected annotation, or `null` if selection was cleared.
  final ValueChanged<Annotation?>? onAnnotationSelected;

  /// Called when an annotation is tapped.
  final ValueChanged<Annotation>? onAnnotationTap;

  /// Called when an annotation is created.
  final ValueChanged<Annotation>? onAnnotationCreated;

  /// Called when an annotation is deleted.
  final ValueChanged<Annotation>? onAnnotationDeleted;

  /// Validation callback called before starting a connection from a port.
  ///
  /// Return a `ConnectionValidationResult` to control whether the connection
  /// can be started. Set `allowed: false` to prevent the connection.
  ///
  /// Example:
  /// ```dart
  /// onBeforeStartConnection: (context) {
  ///   // Don't allow connections from ports that already have connections
  ///   if (context.existingConnections.isNotEmpty && !context.sourcePort.multiConnections) {
  ///     return ConnectionValidationResult(
  ///       allowed: false,
  ///       message: 'Port already has a connection',
  ///     );
  ///   }
  ///   return ConnectionValidationResult(allowed: true);
  /// }
  /// ```
  final ConnectionValidationResult Function(ConnectionStartContext<T> context)?
  onBeforeStartConnection;

  /// Validation callback called before completing a connection to a target port.
  ///
  /// Return a `ConnectionValidationResult` to control whether the connection
  /// can be created. Set `allowed: false` to prevent the connection.
  ///
  /// Use this to implement custom connection rules, type checking, or
  /// prevent cycles in the graph.
  ///
  /// Example:
  /// ```dart
  /// onBeforeCompleteConnection: (context) {
  ///   // Check if connection would create a cycle
  ///   if (wouldCreateCycle(context.sourceNode, context.targetNode)) {
  ///     return ConnectionValidationResult(
  ///       allowed: false,
  ///       message: 'This would create a cycle',
  ///     );
  ///   }
  ///   return ConnectionValidationResult(allowed: true);
  /// }
  /// ```
  final ConnectionValidationResult Function(
    ConnectionCompleteContext<T> context,
  )?
  onBeforeCompleteConnection;

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

  // Double-tap detection
  DateTime? _lastTapTime;
  Offset? _lastTapPosition;
  String? _lastTappedNodeId;
  static const _doubleTapTimeout = Duration(milliseconds: 300);
  static const _doubleTapSlop = 20.0;

  // Cached connection painter for efficient hit testing

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

    // Set up callbacks for the controller
    _updateCallbacks();
    widget.controller.setTheme(widget.theme);
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

    // Update callbacks if they changed
    _updateCallbacks();
    widget.controller.setTheme(widget.theme);

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
      child: LayoutBuilder(
        builder: (context, constraints) {
          // Update screen size immediately on first build, then use post frame callback for updates
          if (widget.controller.screenSize == Size.zero) {
            widget.controller.setScreenSize(constraints.biggest);
          } else {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (widget.controller.screenSize != constraints.biggest) {
                widget.controller.setScreenSize(constraints.biggest);
              }
            });
          }

          return NodeFlowKeyboardHandler<T>(
            controller: widget.controller,
            focusNode: widget.controller.canvasFocusNode,
            child: Container(
              width: constraints.maxWidth,
              height: constraints.maxHeight,
              clipBehavior: Clip.hardEdge,
              decoration: BoxDecoration(color: theme.backgroundColor),
              child: Stack(
                children: [
                  _buildCanvas(constraints, theme),

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
  /// Starts the animation controller if either the theme has a default animation effect
  /// or any connection has an individual animation effect. Stops it otherwise.
  void _updateAnimationController() {
    // Check if theme has default animation effect
    final themeHasEffect = widget.theme.connectionTheme.animationEffect != null;

    // Check if any connection has an animation effect
    final connectionHasEffect = widget.controller.connections.any(
      (connection) => connection.animationEffect != null,
    );

    final hasAnimations = themeHasEffect || connectionHasEffect;

    if (hasAnimations) {
      _connectionAnimationController?.repeat();
    } else {
      _connectionAnimationController?.stop();
    }
  }

  void _updateCallbacks() {
    final callbacks = NodeFlowCallbacks<T>(
      onNodeCreated: widget.onNodeCreated,
      onNodeDeleted: widget.onNodeDeleted,
      onNodeSelected: widget.onNodeSelected,
      onConnectionCreated: widget.onConnectionCreated,
      onConnectionDeleted: widget.onConnectionDeleted,
      onConnectionSelected: widget.onConnectionSelected,
      onAnnotationCreated: widget.onAnnotationCreated,
      onAnnotationDeleted: widget.onAnnotationDeleted,
      onAnnotationSelected: widget.onAnnotationSelected,
    );
    widget.controller.setCallbacks(callbacks);
  }

  @override
  void dispose() {
    for (final disposer in _disposers) {
      disposer();
    }
    _transformationController.dispose();
    _connectionAnimationController?.dispose();

    // Note: Controller disposal is handled by whoever created the controller,
    // not by this widget
    super.dispose();
  }

  // Node interaction handlers
  void _handleNodeTap(Node<T> node) {
    // Ensure canvas has focus when tapping nodes
    if (!widget.controller.canvasFocusNode.hasFocus) {
      widget.controller.canvasFocusNode.requestFocus();
    }

    // Call the user's callback
    widget.onNodeTap?.call(node);
  }

  void _handleNodeDoubleTap(Node<T> node) {
    // Ensure canvas has focus when double-tapping nodes
    if (!widget.controller.canvasFocusNode.hasFocus) {
      widget.controller.canvasFocusNode.requestFocus();
    }

    // Call the user's callback
    widget.onNodeDoubleTap?.call(node);
  }

  Widget _buildCanvas(BoxConstraints constraints, NodeFlowTheme theme) {
    return Listener(
      onPointerDown: _handlePointerDown,
      onPointerMove: _handlePointerMove,
      onPointerUp: _handlePointerUp,
      onPointerHover: _handleMouseHover,
      child: Observer.withBuiltChild(
        builder: (_, child) {
          return MouseRegion(
            cursor: widget.controller.currentCursor,
            child: child,
          );
        },
        child: Container(
          color: theme.backgroundColor,
          child: Observer.withBuiltChild(
            builder: (context, child) {
              return InteractiveViewer(
                transformationController: _transformationController,
                boundaryMargin: const EdgeInsets.all(double.infinity),
                constrained: false,
                minScale: widget.controller.config.minZoom.value,
                maxScale: widget.controller.config.maxZoom.value,
                panEnabled: widget.controller.panEnabled,
                scaleEnabled: widget.enableZooming,
                trackpadScrollCausesScale: widget.scrollToZoom,
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
                    // Background grid - observes only viewport changes
                    GridLayer(
                      theme: theme,
                      transformationController: _transformationController,
                    ),

                    // Background annotations (groups) - behind nodes
                    if (widget.showAnnotations)
                      AnnotationLayer.background(widget.controller),

                    // Connections - uses specialized observable layer
                    ConnectionsLayer<T>(
                      controller: widget.controller,
                      animation: _connectionAnimationController,
                    ),

                    // Connection labels - rendered separately for optimized repainting
                    ConnectionLabelsLayer<T>(controller: widget.controller),

                    // Nodes - each node observes only its own state
                    NodesLayer<T>(
                      controller: widget.controller,
                      nodeBuilder: widget.nodeBuilder,
                      nodeContainerBuilder: widget.nodeContainerBuilder,
                      connections: widget.controller.connections,
                      onNodeTap: _handleNodeTap,
                      onNodeDoubleTap: _handleNodeDoubleTap,
                    ),

                    // Foreground annotations (stickies, markers) - above nodes
                    if (widget.showAnnotations)
                      AnnotationLayer.foreground(widget.controller),

                    // Interaction layer - temporary connection and selection rectangle
                    InteractionLayer<T>(controller: widget.controller),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // Event handlers
  void _onInteractionUpdate(ScaleUpdateDetails details) {
    // Update viewport in store during interaction for real-time updates
    final transform = _transformationController.value;
    final translation = transform.getTranslation();
    final scale = transform.getMaxScaleOnAxis();

    widget.controller.setViewport(
      GraphViewport(x: translation.x, y: translation.y, zoom: scale),
    );
  }

  void _onInteractionEnd(ScaleEndDetails details) {
    // Update viewport in store when interaction ends to keep store in sync
    final transform = _transformationController.value;
    final translation = transform.getTranslation();
    final scale = transform.getMaxScaleOnAxis();

    widget.controller.setViewport(
      GraphViewport(x: translation.x, y: translation.y, zoom: scale),
    );
  }

  void _handleMouseHover(PointerHoverEvent event) {
    final hitResult = _performHitTest(event.localPosition);
    _updateCursor(hitResult);
  }

  void _handlePointerDown(PointerDownEvent event) {
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
              widget.theme.dragCursorStyle,
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
            widget.theme.dragCursorStyle,
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
        widget.onConnectionTap?.call(connection);
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
      final graphDelta = _screenToGraphDelta(delta);

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
      final graphDelta = _screenToGraphDelta(delta);

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
            (hitResult.nodeId != tempConnection.sourceNodeId ||
                hitResult.portId != tempConnection.sourcePortId)) {
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

    // Check if this was a tap (minimal movement) vs a drag
    final wasDragging = widget.controller.draggedNodeId != null;
    final wasAnnotationDragging =
        widget.controller.annotations.draggedAnnotationId != null;

    // Clean up drag state efficiently
    widget.controller._endNodeDrag();

    // Re-enable panning if we were dragging an annotation
    if (wasAnnotationDragging) {
      widget.controller._updateInteractionState(panEnabled: true);
    }

    widget.controller._endAnnotationDrag();
    // No longer needed - isInteractingWithPort removed
    // No longer needed - hoveredPortInfo removed

    final hitResult = _performHitTest(event.localPosition);

    // Clear selection only if this was a tap on empty canvas (not a drag)
    if (_shouldClearSelectionOnTap &&
        wasTap &&
        !wasDragging &&
        !wasAnnotationDragging) {
      widget.controller.clearSelection();
      // Callbacks should be managed by the selection system, not here
      // Controller clearSelection will trigger appropriate callbacks
    }

    // If this was a tap (minimal movement), handle node tap callbacks
    // Note: wasTap takes precedence over wasDragging because draggedNodeId
    // is set on pointer down even for taps when dragging is enabled
    if (wasTap && hitResult.isNode) {
      // Ensure canvas has focus after tap (in case it was lost during selection processing)
      if (!widget.controller.canvasFocusNode.hasFocus) {
        widget.controller.canvasFocusNode.requestFocus();
      }

      final node = widget.controller.getNode(hitResult.nodeId!);
      if (node != null) {
        // Check for double-tap
        final now = DateTime.now();
        final isDoubleTap =
            _lastTapTime != null &&
            _lastTapPosition != null &&
            _lastTappedNodeId == hitResult.nodeId &&
            now.difference(_lastTapTime!) < _doubleTapTimeout &&
            (event.localPosition - _lastTapPosition!).distance < _doubleTapSlop;

        if (isDoubleTap) {
          // Fire double-tap callback
          widget.onNodeDoubleTap?.call(node);
          // Reset tap tracking to prevent triple-tap being detected as another double-tap
          _lastTapTime = null;
          _lastTapPosition = null;
          _lastTappedNodeId = null;
        } else {
          // Fire single tap callback
          widget.onNodeTap?.call(node);
          // Update tap tracking for potential double-tap
          _lastTapTime = now;
          _lastTapPosition = event.localPosition;
          _lastTappedNodeId = hitResult.nodeId;
        }
      }
    } else if (!wasTap) {
      // Was a drag, reset double-tap tracking
      _lastTapTime = null;
      _lastTapPosition = null;
      _lastTappedNodeId = null;
    }

    // Reset tap tracking
    _initialPointerPosition = null;
    _shouldClearSelectionOnTap = false;

    _updateCursor(hitResult);
  }

  // Helper methods

  void _updateCursor(HitTestResult hitResult) {
    final theme = widget.theme;
    MouseCursor newCursor;

    // When all interactions disabled, always use pan cursor
    if (!widget.enableSelection &&
        !widget.enableNodeDragging &&
        !widget.enableConnectionCreation) {
      newCursor = theme.cursorStyle; // Pan cursor
    } else if (widget.controller.isDrawingSelection) {
      newCursor = SystemMouseCursors.precise;
    } else if (widget.controller.draggedNodeId != null) {
      newCursor = theme.dragCursorStyle;
    } else if (widget.controller.isConnecting) {
      newCursor = theme.portCursorStyle;
    } else if (hitResult.isPort) {
      newCursor = theme.portCursorStyle;
    } else if (hitResult.isNode) {
      newCursor = theme.nodeCursorStyle;
    } else if (hitResult.isConnection) {
      newCursor = SystemMouseCursors.click;
    } else {
      newCursor = theme.cursorStyle;
    }

    widget.controller._updateInteractionState(cursor: newCursor);
  }

  void _startSelectionDrag(Offset startPosition) {
    final startGraph = _screenToGraph(startPosition);
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

    final currentGraph = _screenToGraph(currentPosition);
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
    if (hitResult.nodeId == tempConnection.sourceNodeId &&
        hitResult.portId == tempConnection.sourcePortId) {
      return false;
    }

    // Get source port info from temporary connection
    final sourceNode = widget.controller.getNode(tempConnection.sourceNodeId);
    if (sourceNode == null) return false;

    // Determine if source port is output
    final isSourceOutput = sourceNode.outputPorts.any(
      (port) => port.id == tempConnection.sourcePortId,
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
          tempConnection.sourceNodeId,
        );
        final targetNode = widget.controller.getNode(hitResult.nodeId!);

        if (sourceNode == null || targetNode == null) {
          widget.controller._cancelConnection();
          return;
        }

        final sourcePort = [
          ...sourceNode.inputPorts,
          ...sourceNode.outputPorts,
        ].where((p) => p.id == tempConnection.sourcePortId).firstOrNull;
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
                  c.sourceNodeId == tempConnection.sourceNodeId &&
                  c.sourcePortId == tempConnection.sourcePortId,
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
        if (widget.onBeforeCompleteConnection != null) {
          final result = widget.onBeforeCompleteConnection!(context);
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
                  c.sourceNodeId == tempConnection.sourceNodeId &&
                  c.sourcePortId == tempConnection.sourcePortId,
            ),
          );
        }

        widget.controller._completeConnection(
          hitResult.nodeId!,
          hitResult.portId!,
        );

        // Fire callbacks for removed connections
        if (widget.onConnectionDeleted != null) {
          // Connection deletion callbacks handled by controller
        }

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
      if (widget.onBeforeStartConnection != null) {
        final result = widget.onBeforeStartConnection!(context);
        if (!result.allowed) {
          return;
        }
      }

      widget.controller._startConnection(
        hitResult.nodeId!,
        hitResult.portId!,
        hitResult.isOutput!,
      );

      // Fire callbacks for connections removed when starting drag from a single-connection port
      if (widget.onConnectionDeleted != null) {
        // Connection deletion callbacks handled by controller
      }

      final theme = widget.theme;
      final shape = widget.controller.nodeShapeBuilder?.call(node);
      final portPosition = node.getPortPosition(
        hitResult.portId!,
        portSize: theme.portTheme.size,
        shape: shape,
      );

      widget.controller._setTemporaryConnection(
        TemporaryConnection(
          startPoint: portPosition,
          sourceNodeId: hitResult.nodeId!,
          sourcePortId: hitResult.portId!,
          initialCurrentPoint: portPosition,
        ),
      );
    }
  }

  void _updateTemporaryConnection(Offset currentScreenPosition) {
    final temp = widget.controller.temporaryConnection;
    if (temp == null) return;

    final currentGraphPosition = _screenToGraph(currentScreenPosition);

    // Check for port snapping during connection drag
    String? targetNodeId;
    String? targetPortId;
    Offset finalPosition = currentGraphPosition;

    // Perform hit test to find nearby ports for snapping
    final hitResult = _performHitTest(currentScreenPosition);
    if (hitResult.isPort && hitResult.nodeId != temp.sourceNodeId) {
      // Found a target port to snap to
      targetNodeId = hitResult.nodeId;
      targetPortId = hitResult.portId;

      // Update position to port center for snapping
      final targetNode = widget.controller.getNode(hitResult.nodeId!);
      if (targetNode != null) {
        final theme = widget.theme;
        final shape = widget.controller.nodeShapeBuilder?.call(targetNode);
        finalPosition = targetNode.getPortPosition(
          hitResult.portId!,
          portSize: theme.portTheme.size,
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
    );
  }

  // Hit testing
  HitTestResult _performHitTest(Offset localPosition) {
    final graphPosition = _screenToGraph(localPosition);
    final portSize = widget.theme.portTheme.size;

    // Use cached sorted nodes and reverse for hit testing (highest zIndex first)
    final sortedNodes = widget.controller.sortedNodes.reversed.toList();

    // 1. Check ports first (highest priority)
    for (final node in sortedNodes) {
      // Get the shape for this node (if any) for shape-aware port positions
      final shape = widget.controller.nodeShapeBuilder?.call(node);

      for (final port in [...node.inputPorts, ...node.outputPorts]) {
        final portPosition = node.getPortPosition(
          port.id,
          portSize: portSize,
          shape: shape,
        );
        final distance = (graphPosition - portPosition).distance;

        // Is the cursor within the port's hit area?
        if (distance <= widget.controller.config.portSnapDistance.value) {
          return HitTestResult(
            nodeId: node.id,
            portId: port.id,
            isOutput: node.outputPorts.contains(port),
            hitType: HitTarget.port,
          );
        }
      }
    }

    // 2. Check nodes (use shape-aware hit testing)
    for (final node in sortedNodes) {
      // Get the shape for this node (if any)
      final shape = widget.controller.nodeShapeBuilder?.call(node);

      if (shape != null) {
        // Use shape-aware hit testing with full node size
        // Calculate position relative to node
        final relativePosition = graphPosition - node.position.value;

        // Use full node size for hit testing (not inset)
        // The shape might be rendered smaller due to padding, but we want
        // the entire node area to be clickable
        if (shape.containsPoint(relativePosition, node.size.value)) {
          return HitTestResult(nodeId: node.id, hitType: HitTarget.node);
        }
      } else {
        // Rectangular node - use simple bounds check
        if (node.containsPoint(graphPosition)) {
          return HitTestResult(nodeId: node.id, hitType: HitTarget.node);
        }
      }
    }

    // 3. Check connections
    final hitConnectionId = widget.controller.hitTestConnections(graphPosition);
    if (hitConnectionId != null) {
      return HitTestResult(
        connectionId: hitConnectionId,
        hitType: HitTarget.connection,
      );
    }

    // 4. Check annotations
    final annotation = widget.controller.hitTestAnnotations(graphPosition);
    if (annotation != null) {
      return HitTestResult(
        annotationId: annotation.id,
        hitType: HitTarget.annotation,
      );
    }

    // 5. Canvas (lowest priority)
    return const HitTestResult(hitType: HitTarget.canvas);
  }

  Offset _screenToGraph(Offset screenPosition) {
    final transform = _transformationController.value;
    final inverse = Matrix4.inverted(transform);
    final transformed = inverse.transform3(
      Vector3(screenPosition.dx, screenPosition.dy, 0),
    );
    return Offset(transformed.x, transformed.y);
  }

  Offset _screenToGraphDelta(Offset screenDelta) {
    return screenDelta / widget.controller.viewport.zoom;
  }
}

/// Optimized painter for selection rectangle rendering.
///
/// Renders the selection rectangle shown when the user drags to select
/// multiple nodes. Uses pre-calculated paint objects for maximum performance
/// to maintain 60fps during selection operations.
class SelectionRectanglePainter extends CustomPainter {
  SelectionRectanglePainter({
    required this.selectionRectangle,
    required this.theme,
  }) : _fillPaint = Paint()
         ..color = theme.selectionColor
         ..style = PaintingStyle.fill,
       _borderPaint = Paint()
         ..color = theme.selectionBorderColor
         ..strokeWidth = theme.selectionBorderWidth
         ..style = PaintingStyle.stroke;

  /// The bounds of the selection rectangle in graph coordinates.
  final Rect selectionRectangle;

  /// The theme configuration for styling the selection rectangle.
  final NodeFlowTheme theme;

  /// Pre-calculated paint for the rectangle fill.
  ///
  /// Computed once in constructor for maximum performance.
  final Paint _fillPaint;

  /// Pre-calculated paint for the rectangle border.
  ///
  /// Computed once in constructor for maximum performance.
  final Paint _borderPaint;

  @override
  void paint(Canvas canvas, Size size) {
    // Ultra-fast direct painting without intermediate objects
    canvas.drawRect(selectionRectangle, _fillPaint);
    canvas.drawRect(selectionRectangle, _borderPaint);
  }

  @override
  bool shouldRepaint(SelectionRectanglePainter oldDelegate) {
    // Only repaint if the rectangle actually changed
    return selectionRectangle != oldDelegate.selectionRectangle;
  }
}

/// Hit test result types for different UI elements.
///
/// Used to determine what element the user is interacting with at a specific
/// position on the canvas.
enum HitTarget {
  /// Empty canvas area (no elements hit)
  canvas,

  /// A node element
  node,

  /// A port on a node
  port,

  /// A connection between nodes
  connection,

  /// An annotation (sticky note, marker, or group)
  annotation,
}

/// Result of hit testing at a specific position on the canvas.
///
/// Contains information about what element was hit and its properties.
/// Used for cursor updates, interaction handling, and event routing.
class HitTestResult {
  const HitTestResult({
    this.nodeId,
    this.portId,
    this.connectionId,
    this.annotationId,
    this.isOutput,
    this.position,
    this.hitType = HitTarget.canvas,
  });

  /// The ID of the node that was hit, if any.
  final String? nodeId;

  /// The ID of the port that was hit, if any.
  final String? portId;

  /// The ID of the connection that was hit, if any.
  final String? connectionId;

  /// The ID of the annotation that was hit, if any.
  final String? annotationId;

  /// Whether the hit port is an output port.
  ///
  /// `true` for output ports, `false` for input ports, `null` if not a port.
  final bool? isOutput;

  /// The position where the hit occurred in graph coordinates.
  final Offset? position;

  /// The type of element that was hit.
  final HitTarget hitType;

  /// Returns `true` if a port was hit.
  bool get isPort => hitType == HitTarget.port;

  /// Returns `true` if a node was hit.
  bool get isNode => hitType == HitTarget.node;

  /// Returns `true` if a connection was hit.
  bool get isConnection => hitType == HitTarget.connection;

  /// Returns `true` if an annotation was hit.
  bool get isAnnotation => hitType == HitTarget.annotation;

  /// Returns `true` if empty canvas was hit (no elements).
  bool get isCanvas => hitType == HitTarget.canvas;
}

/// Painter for interactive elements (selection rectangle and temporary connection).
///
/// This painter renders transient UI elements that appear during user interactions:
/// - Selection rectangle when dragging to select multiple nodes
/// - Temporary connection line when creating connections between ports
///
/// These elements are repainted frequently during interactions and are kept
/// separate from static elements for performance optimization.
class InteractionLayerPainter<T> extends CustomPainter {
  InteractionLayerPainter({
    required this.controller,
    required this.theme,
    this.selectionRectangle,
    this.temporaryConnection,
  });

  /// The controller managing the graph state.
  final NodeFlowController<T> controller;

  /// The theme configuration for styling.
  final NodeFlowTheme theme;

  /// The current selection rectangle bounds, if user is selecting.
  final Rect? selectionRectangle;

  /// The temporary connection being created, if user is connecting ports.
  final TemporaryConnection? temporaryConnection;

  @override
  void paint(Canvas canvas, Size size) {
    // Paint selection rectangle if present
    if (selectionRectangle != null) {
      _paintSelectionRectangle(canvas);
    }

    // Paint temporary connection if present
    if (temporaryConnection != null) {
      _paintTemporaryConnection(canvas);
    }
  }

  void _paintSelectionRectangle(Canvas canvas) {
    final fillPaint = Paint()
      ..color = theme.selectionColor
      ..style = PaintingStyle.fill;

    final borderPaint = Paint()
      ..color = theme.selectionBorderColor
      ..strokeWidth = theme.selectionBorderWidth
      ..style = PaintingStyle.stroke;

    canvas.drawRect(selectionRectangle!, fillPaint);
    canvas.drawRect(selectionRectangle!, borderPaint);
  }

  void _paintTemporaryConnection(Canvas canvas) {
    final connectionPainter = controller.connectionPainter;

    // Get source port information
    Port? sourcePort;
    final sourceNode = controller.getNode(temporaryConnection!.sourceNodeId);
    if (sourceNode != null) {
      try {
        sourcePort = [
          ...sourceNode.inputPorts,
          ...sourceNode.outputPorts,
        ].firstWhere((port) => port.id == temporaryConnection!.sourcePortId);
      } catch (e) {
        sourcePort = null;
      }
    }

    // Get target port information if available (for snapping)
    Port? targetPort;
    if (temporaryConnection!.targetNodeId != null &&
        temporaryConnection!.targetPortId != null) {
      final targetNode = controller.getNode(temporaryConnection!.targetNodeId!);
      if (targetNode != null) {
        try {
          targetPort = [
            ...targetNode.inputPorts,
            ...targetNode.outputPorts,
          ].firstWhere((port) => port.id == temporaryConnection!.targetPortId);
        } catch (e) {
          targetPort = null;
        }
      }
    }

    // Paint the temporary connection line
    connectionPainter.paintTemporaryConnection(
      canvas,
      temporaryConnection!.startPoint,
      temporaryConnection!.currentPoint,
      sourcePort: sourcePort,
      targetPort: targetPort,
      isReversed: false,
    );
  }

  @override
  bool shouldRepaint(InteractionLayerPainter<T> oldDelegate) {
    // Always repaint if we have a temporary connection to ensure real-time updates
    if (temporaryConnection != null ||
        oldDelegate.temporaryConnection != null) {
      return true;
    }

    return selectionRectangle != oldDelegate.selectionRectangle;
  }
}
