import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:mobx/mobx.dart';

import '../connections/connection.dart';
import '../connections/connection_painter.dart';
import '../connections/connection_validation.dart';
import '../connections/temporary_connection.dart';
import '../graph/graph.dart';
import '../graph/node_flow_config.dart';
import '../graph/node_flow_events.dart';
import '../graph/node_flow_theme.dart';
import '../graph/viewport.dart';
import '../graph/viewport_animation_mixin.dart';
import '../nodes/comment_node.dart';
import '../nodes/group_node.dart';
import '../nodes/interaction_state.dart';
import '../nodes/mixins/groupable_mixin.dart';
import '../nodes/mixins/resizable_mixin.dart';
import '../nodes/node.dart';
import '../nodes/node_data.dart';
import '../nodes/node_shape.dart';
import '../ports/port.dart';
import '../shared/drag_session.dart';
import '../shared/resizer_widget.dart';
import '../shared/shortcuts_viewer_dialog.dart';
import '../shared/spatial/graph_spatial_index.dart';
import 'coordinates.dart';
import 'node_flow_actions.dart';
import 'node_flow_behavior.dart';

part 'api/connection_api.dart';
part 'api/graph_api.dart';
// Domain-specific API extensions
part 'api/node_api.dart';
part 'api/viewport_api.dart';
part 'node_flow_controller_api.dart';

/// Alignment options for node alignment operations
enum NodeAlignment {
  top,
  right,
  bottom,
  left,
  center,
  horizontalCenter,
  verticalCenter,
}

/// High-performance controller for node flow state management.
///
/// This is the main controller for managing nodes, connections, annotations, viewport,
/// and interactions in a node flow editor. It uses MobX for reactive state management.
///
/// Type parameter [T] is the data type stored in each node.
///
/// Example:
/// ```dart
/// // Create a controller with custom configuration
/// final controller = NodeFlowController<MyData>(
///   initialViewport: GraphViewport(x: 0, y: 0, zoom: 1.0),
///   config: NodeFlowConfig.defaultConfig,
/// );
/// ```
class NodeFlowController<T> {
  NodeFlowController({GraphViewport? initialViewport, NodeFlowConfig? config})
    : _viewport = Observable(
        initialViewport ?? const GraphViewport(x: 0, y: 0, zoom: 1.0),
      ),
      _config = config ?? NodeFlowConfig.defaultConfig {
    // Initialize actions and shortcuts system
    shortcuts = NodeFlowShortcutManager<T>();
    shortcuts.registerActions(DefaultNodeFlowActions.createDefaultActions<T>());

    // Setup node monitoring reactions (for GroupNode tracking)
    _setupNodeMonitoringReactions();

    // Setup selection change reactions
    _setupSelectionReactions();

    // Setup spatial index auto-sync reactions
    _setupSpatialIndexReactions();

    // Provide render order to spatial index for accurate hit testing
    // when nodes have the same zIndex
    _spatialIndex.renderOrderProvider = () => sortedNodes;
  }

  // Behavioral configuration
  final NodeFlowConfig _config;

  /// Gets the controller's configuration settings.
  ///
  /// The configuration controls behavior like snap-to-grid, zoom limits,
  /// port snap distance, and other behavioral settings.
  NodeFlowConfig get config => _config;

  // Theme configuration - observable to enable reactive spatial index updates
  final Observable<NodeFlowTheme?> _themeObservable =
      Observable<NodeFlowTheme?>(null);

  /// Gets the current theme configuration.
  ///
  /// Returns `null` if no theme has been set. The theme is typically set
  /// by the editor widget during initialization.
  NodeFlowTheme? get theme => _themeObservable.value;
  NodeFlowTheme? get _theme => _themeObservable.value;

  // Node shape builder - determines the shape for each node based on its type/data
  NodeShape? Function(Node<T> node)? _nodeShapeBuilder;

  /// Gets the node shape builder function.
  ///
  /// This function is called to determine the visual shape for each node based
  /// on its type or data. If `null`, nodes will use the default rectangular shape.
  NodeShape? Function(Node<T> node)? get nodeShapeBuilder => _nodeShapeBuilder;

  /// Sets the node shape builder function.
  ///
  /// This function will be called for each node to determine its visual shape.
  /// The builder receives the node and should return a [NodeShape] or `null`
  /// for the default rectangular shape.
  ///
  /// Example:
  /// ```dart
  /// controller.setNodeShapeBuilder((node) {
  ///   switch (node.type) {
  ///     case 'Terminal':
  ///       return CircleShape(fillColor: Colors.blue, strokeColor: Colors.black);
  ///     case 'Decision':
  ///       return DiamondShape(fillColor: Colors.yellow, strokeColor: Colors.black);
  ///     default:
  ///       return null; // Rectangular node
  ///   }
  /// });
  /// ```
  void setNodeShapeBuilder(NodeShape? Function(Node<T> node)? builder) {
    _nodeShapeBuilder = builder;

    // Update the connection painter's node shape getter if it exists
    // Cast to Node<dynamic> since ConnectionPainter is not generic
    _connectionPainter?.updateNodeShape(
      builder != null ? (node) => builder(node as Node<T>) : null,
    );
  }

  // Structured events system
  NodeFlowEvents<T> _events = const NodeFlowEvents();

  /// Gets the current events configuration.
  ///
  /// Events are organized into logical groups (node, connection, viewport, etc.)
  /// for better discoverability and maintainability.
  NodeFlowEvents<T> get events => _events;

  // Canvas focus management
  final FocusNode _canvasFocusNode = FocusNode(debugLabel: 'NodeFlowCanvas');

  /// The focus node for the canvas.
  ///
  /// Used to capture keyboard events. The editor widget automatically
  /// manages this focus node. You can manually request focus if needed:
  ///
  /// ```dart
  /// controller.canvasFocusNode.requestFocus();
  /// ```
  FocusNode get canvasFocusNode => _canvasFocusNode;

  // Behavior mode
  final Observable<NodeFlowBehavior> _behavior = Observable(
    NodeFlowBehavior.design,
  );

  /// The current behavior mode determining what interactions are allowed.
  ///
  /// Use this to check capabilities:
  /// ```dart
  /// if (controller.behavior.canDelete) {
  ///   // Allow deletion
  /// }
  /// ```
  NodeFlowBehavior get behavior => _behavior.value;

  /// Sets the behavior mode for the canvas.
  ///
  /// This controls what CRUD operations are allowed on nodes, ports,
  /// connections, and annotations.
  void setBehavior(NodeFlowBehavior value) {
    runInAction(() => _behavior.value = value);
  }

  // Core data structures
  final ObservableMap<String, Node<T>> _nodes =
      ObservableMap<String, Node<T>>();
  final ObservableList<Connection> _connections = ObservableList<Connection>();
  final ObservableSet<String> _selectedNodeIds = ObservableSet<String>();
  final ObservableSet<String> _selectedConnectionIds = ObservableSet<String>();
  final Observable<GraphViewport> _viewport;
  final Observable<Size> _screenSize = Observable(Size.zero);

  /// Direct callback to trigger viewport animations.
  ///
  /// This callback is set by [NodeFlowEditor] and invoked by
  /// [animateTo] and [animateToNode] to trigger smooth viewport animations.
  /// Parameters duration and curve are optional with sensible defaults.
  void Function(GraphViewport target, {Duration duration, Curve curve})?
  _onAnimateToViewport;

  /// Token identifying which widget set the current animation handler.
  /// Used to prevent race conditions when widgets are recreated.
  Object? _animateToHandlerToken;

  /// Key for the canvas widget, used to convert global coordinates to canvas-local.
  final GlobalKey canvasKey = GlobalKey();

  /// Current mouse position in world coordinates (null if mouse is outside canvas).
  /// Used for debug visualization and other features that need cursor tracking.
  final Observable<Offset?> _mousePositionWorld = Observable<Offset?>(null);

  // Interaction state - organized in separate object
  final InteractionState interaction = InteractionState();

  /// Creates a drag session for managing drag operation lifecycle.
  ///
  /// The session automatically handles canvas locking/unlocking. Elements
  /// just need to call lifecycle methods: [start], [end], [cancel].
  ///
  /// Only one session can be active at a time. Creating a new session while
  /// one is active will cancel the existing session first.
  ///
  /// Example:
  /// ```dart
  /// DragSession? _session;
  ///
  /// void _handleDragStart(details) {
  ///   _originalPosition = node.position.value; // Capture state
  ///   _session = controller.createSession(DragSessionType.nodeDrag);
  ///   _session!.start(); // Locks canvas
  /// }
  ///
  /// void _handleDragEnd(details) {
  ///   _session?.end(); // Unlocks canvas
  ///   _session = null;
  /// }
  ///
  /// void _handleDragCancel() {
  ///   _session?.cancel(); // Unlocks canvas
  ///   _session = null;
  ///   node.position.value = _originalPosition!; // Restore state
  /// }
  /// ```
  DragSession createSession(DragSessionType type) {
    // Cancel any existing active session
    _activeSession?.cancel();

    // Create new session
    _activeSession = _DragSessionImpl(type, interaction, _onSessionEnded);
    return _activeSession!;
  }

  /// The currently active drag session, if any.
  _DragSessionImpl? _activeSession;

  /// Called when a session ends (either by end() or cancel()).
  void _onSessionEnded() {
    _activeSession = null;
  }

  // Node monitoring for GroupNode tracking
  // Track previous node IDs to detect additions/deletions
  Set<String> _previousNodeIds = {};
  // Flag to prevent cyclic updates when moving group child nodes
  bool _isMovingGroupNodes = false;

  // Connection painting and hit-testing
  ConnectionPainter? _connectionPainter;

  // Spatial hit testing
  late final GraphSpatialIndex<T> _spatialIndex = GraphSpatialIndex<T>(
    portSnapDistance: _config.portSnapDistance.value,
  );

  // Pending spatial index updates (dirty tracking)
  final Set<String> _pendingNodeUpdates = {};
  final Set<String> _pendingConnectionUpdates = {};

  // Connection index for O(1) lookup by node ID
  final Map<String, Set<String>> _connectionsByNodeId = {};

  // Actions and shortcuts management
  late final NodeFlowShortcutManager<T> shortcuts;

  // Computed values
  Computed<bool> get _hasSelection => Computed(
    () => _selectedNodeIds.isNotEmpty || _selectedConnectionIds.isNotEmpty,
  );

  Computed<List<Node<T>>> get _sortedNodes => Computed(_computeSortedNodes);

  // Public API - only what external consumers need

  /// Gets all connections in the graph.
  ///
  /// Returns a live list that will automatically update when connections
  /// are added or removed.
  List<Connection> get connections => _connections;

  /// Gets the IDs of all currently selected nodes.
  ///
  /// Returns a set of node IDs. An empty set means no nodes are selected.
  Set<String> get selectedNodeIds => _selectedNodeIds;

  /// Gets the current viewport state (position and zoom).
  ///
  /// The viewport determines what portion of the graph is visible and at
  /// what zoom level.
  GraphViewport get viewport => _viewport.value;

  /// Checks if there is any active selection (nodes, connections, or annotations).
  ///
  /// Returns `true` if anything is selected, `false` otherwise.
  bool get hasSelection => _hasSelection.value;

  // Package-private - for internal widget use only

  /// Gets all nodes in the graph as a map (package-private).
  ///
  /// This is primarily for internal use by the editor widget.
  Map<String, Node<T>> get nodes => _nodes;

  /// Gets nodes sorted by z-index (package-private).
  ///
  /// Lower z-index nodes render first (behind), higher z-index nodes render last (on top).
  /// This is primarily for internal use by the editor widget for proper rendering order.
  List<Node<T>> get sortedNodes => _sortedNodes.value;

  /// Gets the current screen/canvas size (package-private).
  ///
  /// This is used for viewport calculations. Updated automatically by the editor widget.
  Size get screenSize => _screenSize.value;

  /// Gets the ID of the node currently being dragged, if any (package-private).
  ///
  /// Returns `null` if no node is being dragged.
  String? get draggedNodeId => interaction.currentDraggedNodeId;

  /// Checks if a connection is currently being created (package-private).
  ///
  /// Returns `true` while dragging from a port to create a connection.
  bool get isConnecting => interaction.isCreatingConnection;

  /// Gets the temporary connection being created, if any (package-private).
  ///
  /// Returns `null` if no connection is being created.
  TemporaryConnection? get temporaryConnection =>
      interaction.temporaryConnection.value;

  /// Checks if a selection rectangle is being drawn (package-private).
  ///
  /// Returns `true` during shift+drag selection operations.
  bool get isDrawingSelection => interaction.isDrawingSelection;

  /// Gets the last known pointer position in screen/widget-local coordinates (package-private).
  ///
  /// Used for drag operations. Returns `null` if no pointer position is tracked.
  ScreenPosition? get pointerPosition => interaction.pointerPosition;

  /// Gets the current selection rectangle in graph coordinates (package-private).
  ///
  /// Returns `null` if no selection rectangle is active.
  /// The rectangle is in graph coordinates for hit testing against node positions.
  GraphRect? get selectionRect => interaction.currentSelectionRect;

  /// Gets the starting point of the selection rectangle in graph coordinates (package-private).
  ///
  /// Returns `null` if no selection is being drawn.
  /// This is where the user first pressed to begin the selection drag.
  GraphPosition? get selectionStartPoint => interaction.selectionStartPoint;

  /// Checks if the canvas is locked (pan/zoom disabled) (package-private).
  ///
  /// Canvas is locked during drag operations (nodes, connections, resize)
  /// to prevent coordinate misalignment when the viewport changes mid-drag.
  bool get canvasLocked => interaction.isCanvasLocked;

  // ===========================================================================
  // Resize State (unified for Node and Annotation)
  // ===========================================================================

  /// Gets the ID of the node currently being resized (package-private).
  ///
  /// Works for both regular nodes and annotations since Annotation extends Node.
  /// Returns null if no resize operation is in progress.
  String? get resizingNodeId => interaction.currentResizingNodeId;

  /// Checks if any resize operation is in progress (package-private).
  ///
  /// Returns true when a node or annotation is being resized.
  bool get isResizing => interaction.isResizing;

  /// Gets the IDs of all currently selected connections (package-private).
  ///
  /// Returns a set of connection IDs. An empty set means no connections are selected.
  Set<String> get selectedConnectionIds => _selectedConnectionIds;

  /// Gets the hit tester for spatial queries (package-private).
  ///
  /// Used by the editor for efficient hit testing with spatial indexing.
  GraphSpatialIndex<T> get spatialIndex => _spatialIndex;

  List<Node<T>> _computeSortedNodes() {
    // Create a list from nodes and sort by zIndex
    final nodesList = _nodes.values.toList();

    // Trigger observation of all zIndex values to ensure reactivity
    for (final node in nodesList) {
      node.zIndex.value; // Observe zIndex changes
    }

    // Sort by zIndex ascending (lower zIndex = rendered first = behind)
    nodesList.sort((a, b) => a.zIndex.value.compareTo(b.zIndex.value));

    return nodesList;
  }

  /// Sets up reactions for node monitoring (used by GroupNode to track child nodes).
  ///
  /// This enables GroupNodes with explicit or parent behavior to react when
  /// their member nodes move, resize, or are deleted.
  void _setupNodeMonitoringReactions() {
    // Global reaction for node additions/deletions
    reaction((_) => _nodes.keys.toSet(), (Set<String> currentNodeIds) {
      // Skip if we're currently moving nodes during group drag
      if (_isMovingGroupNodes) return;

      final context = _createDragContext();

      // Detect deleted nodes
      final deletedIds = _previousNodeIds.difference(currentNodeIds);
      if (deletedIds.isNotEmpty) {
        _notifyNodesOfNodeDeletions(deletedIds, context);
      }

      // Detect added nodes
      final addedIds = currentNodeIds.difference(_previousNodeIds);
      if (addedIds.isNotEmpty) {
        _notifyNodesOfNodeAdditions(addedIds, context);
      }

      _previousNodeIds = currentNodeIds;
    }, fireImmediately: true);
  }

  void _setupSelectionReactions() {
    // Fire selection change event when selection changes
    reaction(
      (_) {
        // Observe all selection state
        return (_selectedNodeIds.toSet(), _selectedConnectionIds.toSet());
      },
      (_) {
        // Build selection state
        final selectedNodes = _selectedNodeIds
            .map((id) => _nodes[id])
            .where((node) => node != null)
            .cast<Node<T>>()
            .toList();

        final selectedConnections = _selectedConnectionIds
            .map((id) => _connections.firstWhere((c) => c.id == id))
            .toList();

        final selectionState = SelectionState<T>(
          nodes: selectedNodes,
          connections: selectedConnections,
        );

        // Fire the selection change event
        events.onSelectionChange?.call(selectionState);
      },
    );
  }

  void _setupSpatialIndexReactions() {
    // === DRAG STATE FLUSH REACTION ===
    // When any drag ends, flush all pending spatial index updates.
    // This is the single point where pending updates are committed.
    reaction((_) => interaction.draggedNodeId.value, (String? nodeDragId) {
      // Only flush when drag has ended
      if (nodeDragId == null) {
        _flushPendingSpatialUpdates();
      }
    }, fireImmediately: false);

    // === NODE ADD/REMOVE SYNC ===
    // When nodes are added/removed, rebuild the node spatial index
    reaction((_) => _nodes.keys.toSet(), (Set<String> currentNodeIds) {
      _spatialIndex.rebuildFromNodes(_nodes.values);
    }, fireImmediately: false);

    // === CONNECTION ADD/REMOVE SYNC ===
    // When connections are added/removed, rebuild connection spatial index and update index
    reaction((_) => _connections.map((c) => c.id).toSet(), (
      Set<String> connectionIds,
    ) {
      // Rebuild connection-by-node index
      _rebuildConnectionsByNodeIndex();
      // Rebuild connection spatial index with proper segments
      rebuildAllConnectionSegments();
    }, fireImmediately: false);

    // === THEME/STYLE CHANGE SYNC ===
    // When path-affecting theme properties change, rebuild connection segments
    reaction((_) => _getPathAffectingSignature(), (_) {
      // Theme properties that affect path geometry have changed
      // Rebuild all connection segments in spatial index
      rebuildAllConnectionSegments();
    }, fireImmediately: false);

    // === NODE VISIBILITY CHANGE SYNC ===
    // When node visibility changes, rebuild connection segments
    // (connections are visible only when both endpoint nodes are visible)
    reaction(
      (_) {
        // Create a signature of all node visibility states
        return _nodes.values.map((n) => (n.id, n.isVisible)).toList();
      },
      (_) {
        // Rebuild connection spatial index segments
        // Hidden connections will return empty segments from the path cache
        rebuildAllConnectionSegments();
      },
      fireImmediately: false,
    );
  }

  /// Gets the connection painter used for rendering and hit-testing connections.
  ///
  /// The connection painter must be initialized by calling `setTheme` first,
  /// which is typically done automatically by the editor widget.
  ///
  /// Throws `StateError` if accessed before initialization.
  ConnectionPainter get connectionPainter {
    if (_connectionPainter == null) {
      throw StateError(
        'ConnectionPainter not initialized. Call setTheme first.',
      );
    }
    return _connectionPainter!;
  }

  /// Whether the connection painter has been initialized.
  /// Use this to guard access to [connectionPainter] during initialization.
  bool get isConnectionPainterInitialized => _connectionPainter != null;

  // ===========================================================================
  // Unified Resize Methods (works for any resizable Node, including Annotations)
  // ===========================================================================

  /// Starts a resize operation for any resizable node.
  ///
  /// Works for any node with `isResizable = true`, including [GroupNode]
  /// and [CommentNode]. The node must have [Node.isResizable] set to `true`.
  void startResize(String nodeId, ResizeHandle handle) {
    final node = _nodes[nodeId];
    if (node != null && node.isResizable) {
      interaction.startResize(nodeId, handle);
    }
  }

  /// Updates the size of the currently resizing node during a resize operation.
  ///
  /// Delegates to [Node.resize] which handles all resize handle calculations
  /// and size constraints. After resize, updates visual position with snapping.
  void updateResize(Offset delta) {
    final nodeId = interaction.currentResizingNodeId;
    final handle = interaction.currentResizeHandle;
    if (nodeId == null || handle == null) return;

    final node = _nodes[nodeId];
    if (node != null && node.isResizable) {
      // Safe cast: isResizable guarantees ResizableMixin
      (node as ResizableMixin<T>).resize(handle, delta);
      runInAction(() {
        node.setVisualPosition(
          _config.snapToGridIfEnabled(node.position.value),
        );
      });
      internalMarkNodeDirty(nodeId);
    }
  }

  /// Ends the current resize operation.
  ///
  /// Clears resize state and re-enables panning.
  void endResize() {
    interaction.endResize();
  }

  /// Cancels a resize operation and reverts to original position/size.
  ///
  /// Call this to abort a resize and restore the node to its state before
  /// the resize started. The caller provides the original values since
  /// the widget that initiated the resize owns that state.
  ///
  /// Parameters:
  /// - [originalPosition]: The node's position before resize
  /// - [originalSize]: The node's size before resize
  void cancelResize({
    required Offset originalPosition,
    required Size originalSize,
  }) {
    final nodeId = interaction.currentResizingNodeId;
    if (nodeId == null) return;

    final node = _nodes[nodeId];
    if (node != null && node.isResizable) {
      runInAction(() {
        node.position.value = originalPosition;
        node.setVisualPosition(_config.snapToGridIfEnabled(originalPosition));
        (node as ResizableMixin<T>).size.value = originalSize;
      });
      internalMarkNodeDirty(nodeId);
    }

    interaction.endResize();

    // Fire resize cancel event
    if (node != null) {
      events.node?.onResizeCancel?.call(node);
    }
  }

  /// Disposes of the controller and releases resources.
  ///
  /// Call this when you're done using the controller to clean up resources
  /// like the canvas focus node and connection painter.
  ///
  /// Example:
  /// ```dart
  /// @override
  /// void dispose() {
  ///   controller.dispose();
  ///   super.dispose();
  /// }
  /// ```
  void dispose() {
    _canvasFocusNode.dispose();
    _connectionPainter?.dispose();

    // Detach context from all groupable nodes to clean up their reactions
    for (final node in _nodes.values) {
      if (node is GroupableMixin<T>) {
        node.detachContext();
      }
    }
  }

  // ============================================================
  // Node Monitoring Helpers
  // ============================================================

  /// Creates a drag context for node lifecycle methods.
  ///
  /// The context provides callbacks for nodes (like [GroupNode]) that need
  /// to move child nodes, look up node bounds, etc.
  NodeDragContext<T> _createDragContext() {
    return NodeDragContext<T>(
      moveNodes: _moveNodesByDelta,
      findNodesInBounds: _findNodesInBounds,
      getNode: (nodeId) => _nodes[nodeId],
    );
  }

  /// Creates a context for GroupableMixin nodes.
  ///
  /// This extends the drag context with `shouldSkipUpdates` to prevent
  /// recursive updates during group drag operations.
  NodeDragContext<T> _createGroupableContext() {
    return NodeDragContext<T>(
      moveNodes: _moveNodesByDelta,
      findNodesInBounds: _findNodesInBounds,
      getNode: (nodeId) => _nodes[nodeId],
      shouldSkipUpdates: () => _isMovingGroupNodes,
    );
  }

  /// Moves nodes by a given delta, handling position and visual position with snapping.
  void _moveNodesByDelta(Set<String> nodeIds, Offset delta) {
    // Check if already moving to prevent nested calls
    if (_isMovingGroupNodes) {
      return;
    }

    if (nodeIds.isEmpty) return;

    // Temporarily disable updates to prevent cycles
    _isMovingGroupNodes = true;

    try {
      runInAction(() {
        for (final nodeId in nodeIds) {
          final node = _nodes[nodeId];
          if (node != null) {
            final newPosition = node.position.value + delta;

            // Update both position and visual position
            node.position.value = newPosition;
            final snappedPosition = _config.snapToGridIfEnabled(newPosition);
            node.setVisualPosition(snappedPosition);
          }
        }
      });

      // Mark nodes dirty (deferred during drag)
      internalMarkNodesDirty(nodeIds);
    } finally {
      _isMovingGroupNodes = false;
    }
  }

  /// Finds all node IDs whose bounds are completely contained within the given rect.
  ///
  /// This includes both regular nodes AND GroupNodes, enabling nested groups.
  /// A node cannot contain itself because Rect.contains uses exclusive bounds
  /// for bottom-right (the bottomRight point won't satisfy `< right` and `< bottom`).
  Set<String> _findNodesInBounds(Rect bounds) {
    final containedNodeIds = <String>{};

    for (final entry in _nodes.entries) {
      final node = entry.value;

      final nodeRect = Rect.fromLTWH(
        node.visualPosition.value.dx,
        node.visualPosition.value.dy,
        node.size.value.width,
        node.size.value.height,
      );

      // Node must be completely inside the bounds
      if (bounds.contains(nodeRect.topLeft) &&
          bounds.contains(nodeRect.bottomRight)) {
        containedNodeIds.add(entry.key);
      }
    }

    return containedNodeIds;
  }

  /// Notifies groupable nodes when other nodes are deleted.
  void _notifyNodesOfNodeDeletions(
    Set<String> deletedIds,
    NodeDragContext<T> context,
  ) {
    final nodesToRemove = <String>[];

    for (final node in _nodes.values) {
      // Only nodes with GroupableMixin can monitor other nodes
      if (node is GroupableMixin<T>) {
        if (node.isGroupable) {
          node.onChildrenDeleted(deletedIds);

          // Check if node wants to be removed
          if (node.shouldRemoveWhenEmpty && node.isEmpty) {
            nodesToRemove.add(node.id);
          }
        }
      }
    }

    // Remove empty nodes
    for (final nodeId in nodesToRemove) {
      removeNode(nodeId);
    }
  }

  /// Notifies groupable nodes when other nodes are added.
  void _notifyNodesOfNodeAdditions(
    Set<String> addedIds,
    NodeDragContext<T> context,
  ) {
    for (final addedNodeId in addedIds) {
      final addedNode = _nodes[addedNodeId];
      if (addedNode == null) continue;

      final nodeBounds = addedNode.getBounds();
      for (final node in _nodes.values) {
        // Only nodes with GroupableMixin can monitor other nodes
        if (node is GroupableMixin<T> && node.id != addedNodeId) {
          if (node.isGroupable) {
            node.onNodeAdded(addedNodeId, nodeBounds);
          }
        }
      }
    }
  }
}

/// Private extension for dirty tracking and spatial index management.
///
/// This extension groups all the dirty tracking logic for efficient spatial
/// index updates. The pattern defers spatial index updates during drag
/// operations and batches them when the drag ends.
///
/// Key concepts:
/// - Dirty tracking: Nodes/connections are marked "dirty" during drag
/// - Deferred updates: Spatial index updates are deferred to pending sets
/// - Batch flush: All pending updates are flushed when drag ends
/// - Connection index: O(1) lookup of connections by node ID
extension DirtyTrackingExtension<T> on NodeFlowController<T> {
  /// Checks if any drag operation is in progress
  bool get _isAnyDragInProgress => interaction.draggedNodeId.value != null;

  /// Checks if spatial index updates should be deferred.
  /// Updates are deferred during drag UNLESS debug mode is on (for live visualization).
  bool get _shouldDeferSpatialUpdates =>
      _isAnyDragInProgress && !(_theme?.debugMode ?? false);

  /// Flushes all pending spatial index updates.
  /// Called when drag operations end.
  void _flushPendingSpatialUpdates() {
    bool hadUpdates = false;

    // Flush node updates
    if (_pendingNodeUpdates.isNotEmpty) {
      hadUpdates = true;
      _spatialIndex.batch(() {
        for (final nodeId in _pendingNodeUpdates) {
          final node = _nodes[nodeId];
          if (node != null) {
            _spatialIndex.update(node);
          }
        }
      });
      _pendingNodeUpdates.clear();
    }

    // Flush connection updates using proper segment bounds
    if (_pendingConnectionUpdates.isNotEmpty) {
      hadUpdates = true;
      _flushPendingConnectionUpdates();
      _pendingConnectionUpdates.clear();
    }

    // Always notify at the end of flush to ensure debug layer updates
    // even if all pending updates were handled via batch (which also notifies)
    if (hadUpdates) {
      // Force a final notification to ensure observers are updated
      _spatialIndex.notifyChanged();
    }
  }

  /// Flushes all pending spatial index updates synchronously.
  ///
  /// This method should be called after drag operations end to ensure the
  /// spatial index is up-to-date before performing hit tests. Normally the
  /// flush happens via a MobX reaction, but that's asynchronous. This method
  /// allows synchronous flushing when immediate hit testing is needed.
  void flushPendingSpatialUpdates() {
    _flushPendingSpatialUpdates();
  }

  /// Returns a signature of all path-affecting theme properties.
  /// Used by the reaction to detect when spatial index needs rebuilding.
  Object _getPathAffectingSignature() {
    final theme = _themeObservable.value;
    if (theme == null) return const Object();

    final conn = theme.connectionTheme;
    // Return a tuple of all properties that affect connection path geometry
    return (
      conn.style.id,
      conn.bezierCurvature,
      conn.cornerRadius,
      conn.portExtension,
      conn.backEdgeGap,
      conn.startGap,
      conn.endGap,
      conn.hitTolerance,
      theme.portTheme.size,
    );
  }

  /// Flushes pending connection updates using proper segment bounds from path cache.
  void _flushPendingConnectionUpdates() {
    if (!isConnectionPainterInitialized || _theme == null) return;

    final pathCache = _connectionPainter!.pathCache;
    final connectionStyle = _theme!.connectionTheme.style;

    for (final connectionId in _pendingConnectionUpdates) {
      final connection = _connections.firstWhere(
        (c) => c.id == connectionId,
        orElse: () => throw StateError('Connection not found: $connectionId'),
      );

      final sourceNode = _nodes[connection.sourceNodeId];
      final targetNode = _nodes[connection.targetNodeId];
      if (sourceNode == null || targetNode == null) continue;

      final segments = pathCache.getOrCreateSegmentBounds(
        connection: connection,
        sourceNode: sourceNode,
        targetNode: targetNode,
        connectionStyle: connectionStyle,
      );
      _spatialIndex.updateConnection(connection, segments);
    }
  }

  /// Rebuilds the connection-by-node index for O(1) lookup
  void _rebuildConnectionsByNodeIndex() {
    _connectionsByNodeId.clear();
    for (final connection in _connections) {
      _connectionsByNodeId
          .putIfAbsent(connection.sourceNodeId, () => {})
          .add(connection.id);
      _connectionsByNodeId
          .putIfAbsent(connection.targetNodeId, () => {})
          .add(connection.id);
    }
  }

  /// Updates spatial index bounds for a single node's connections using proper segment bounds.
  void _updateConnectionBoundsForNode(String nodeId) {
    // Use the API method that calculates proper segment bounds from path cache
    rebuildConnectionSegmentsForNodes([nodeId]);
  }

  /// Updates spatial index bounds for connections attached to the given nodes.
  void _updateConnectionBoundsForNodeIds(Iterable<String> nodeIds) {
    // Use the API method that calculates proper segment bounds from path cache
    rebuildConnectionSegmentsForNodes(nodeIds.toList());
  }

  // === Public internal methods (accessible from other libraries) ===
  // These methods need to be part of the extension but accessible externally,
  // hence the 'internal' prefix convention instead of underscore.

  // @nodoc - Internal framework use only - do not use in user code
  /// Marks a node as needing spatial index update.
  /// If no drag is in progress (or debug mode is on), updates immediately.
  /// Otherwise, defers until drag ends.
  void internalMarkNodeDirty(String nodeId) {
    if (_shouldDeferSpatialUpdates) {
      _pendingNodeUpdates.add(nodeId);
      // Also mark connected connections as dirty
      final connectedIds = _connectionsByNodeId[nodeId];
      if (connectedIds != null) {
        _pendingConnectionUpdates.addAll(connectedIds);
      }
    } else {
      // Immediate update
      final node = _nodes[nodeId];
      if (node != null) {
        _spatialIndex.update(node);
        _updateConnectionBoundsForNode(nodeId);
      }
    }
  }

  // @nodoc - Internal framework use only - do not use in user code
  /// Marks multiple nodes as needing spatial index update.
  void internalMarkNodesDirty(Iterable<String> nodeIds) {
    if (_shouldDeferSpatialUpdates) {
      _pendingNodeUpdates.addAll(nodeIds);
      // Also mark connected connections as dirty
      for (final nodeId in nodeIds) {
        final connectedIds = _connectionsByNodeId[nodeId];
        if (connectedIds != null) {
          _pendingConnectionUpdates.addAll(connectedIds);
        }
      }
    } else {
      // Immediate update
      _spatialIndex.batch(() {
        for (final nodeId in nodeIds) {
          final node = _nodes[nodeId];
          if (node != null) {
            _spatialIndex.update(node);
          }
        }
      });
      _updateConnectionBoundsForNodeIds(nodeIds);
    }
  }
}

/// Private implementation of [DragSession].
///
/// This class is internal to the controller and should not be exposed.
/// It handles canvas locking/unlocking and notifies the controller when ended.
class _DragSessionImpl implements DragSession {
  _DragSessionImpl(this._type, this._interaction, this._onEnded);

  final DragSessionType _type;
  final InteractionState _interaction;
  final VoidCallback _onEnded;

  bool _isActive = false;

  @override
  DragSessionType get type => _type;

  @override
  bool get isActive => _isActive;

  @override
  void start() {
    if (_isActive) return;

    runInAction(() {
      _isActive = true;
      _interaction.canvasLocked.value = true;
    });
  }

  @override
  void end() {
    if (!_isActive) return;

    runInAction(() {
      _isActive = false;
      _interaction.canvasLocked.value = false;
    });

    _onEnded();
  }

  @override
  void cancel() {
    if (!_isActive) return;

    runInAction(() {
      _isActive = false;
      _interaction.canvasLocked.value = false;
    });

    _onEnded();
  }
}
