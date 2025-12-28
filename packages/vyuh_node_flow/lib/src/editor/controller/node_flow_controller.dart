import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:mobx/mobx.dart';

import '../../connections/connection.dart';
import '../../connections/connection_painter.dart';
import '../../connections/connection_validation.dart';
import '../../connections/temporary_connection.dart';
import '../../extensions/graph_events.dart';
import '../../extensions/node_flow_extension.dart';
import '../../graph/coordinates.dart';
import '../../graph/graph.dart';
import '../../graph/viewport.dart';
import '../../nodes/comment_node.dart';
import '../../nodes/group_node.dart';
import '../../nodes/interaction_state.dart';
import '../../nodes/mixins/groupable_mixin.dart';
import '../../nodes/mixins/resizable_mixin.dart';
import '../../nodes/node.dart';
import '../../nodes/node_data.dart';
import '../../nodes/node_shape.dart';
import '../../ports/port.dart';
import '../../shared/spatial/graph_spatial_index.dart';
import '../drag_session.dart';
import '../keyboard/node_flow_actions.dart';
import '../node_flow_behavior.dart';
import '../node_flow_config.dart';
import '../node_flow_events.dart';
import '../resizer_widget.dart';
import '../themes/node_flow_theme.dart';
import '../viewport_animation_mixin.dart';

part 'connection_api.dart';
part 'editor_init_api.dart';
part 'graph_api.dart';
part 'node_api.dart';
part 'node_flow_controller_api.dart';
part 'viewport_api.dart';

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
  /// Creates a new node flow controller.
  ///
  /// Parameters:
  /// * [initialViewport] - Initial viewport position and zoom (defaults to origin at 1x zoom)
  /// * [config] - Configuration settings for behavior like snap-to-grid, zoom limits, etc.
  /// * [nodes] - Optional initial nodes to populate the graph with
  /// * [connections] - Optional initial connections between nodes
  ///
  /// Example:
  /// ```dart
  /// // Create an empty controller
  /// final controller = NodeFlowController<MyData>();
  ///
  /// // Create a pre-populated controller
  /// final controller = NodeFlowController<MyData>(
  ///   nodes: [node1, node2, node3],
  ///   connections: [conn1, conn2],
  ///   initialViewport: GraphViewport(x: 0, y: 0, zoom: 1.0),
  /// );
  /// ```
  NodeFlowController({
    GraphViewport? initialViewport,
    NodeFlowConfig? config,
    List<Node<T>>? nodes,
    List<Connection>? connections,
  }) : _viewport = Observable(
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

    // NOTE: Spatial index reactions are NOT set up here.
    // They are deferred to _initController() because the spatial index requires
    // callbacks (portSizeResolver, nodeShapeBuilder) that are set by the
    // editor widget. If reactions fire before callbacks are set, ports
    // will be indexed with incorrect bounds causing hit testing to fail.
    //
    // The canonical initialization point is _initController() in editor_init_api.dart.
    // That method sets up: theme, node shape builder, spatial index callbacks,
    // connection painter, hit testers, reactions, and initializes loaded nodes.

    // Load initial nodes and connections if provided
    if (nodes != null && nodes.isNotEmpty) {
      _loadInitialGraph(nodes, connections ?? const []);
    }
  }

  /// Loads initial graph data during construction.
  ///
  /// This is similar to [loadGraph] but designed for constructor use.
  /// Infrastructure setup is deferred until the theme is set by the editor.
  void _loadInitialGraph(List<Node<T>> nodes, List<Connection> connections) {
    runInAction(() {
      for (final node in nodes) {
        _nodes[node.id] = node;
      }
      _connections.addAll(connections);
    });

    // Note: Full infrastructure setup (_setupLoadedGraphInfrastructure)
    // happens when setTheme is called by the editor, since we need the
    // theme for proper spatial index setup.
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

  // Connection segment calculator for spatial index (set by _initController)
  List<Rect> Function(Connection connection)? _connectionSegmentCalculator;

  // Spatial hit testing
  late final GraphSpatialIndex<T> _spatialIndex = GraphSpatialIndex<T>(
    portSnapDistance: _config.portSnapDistance.value,
  );

  // Pending spatial index updates (dirty tracking)
  final Set<String> _pendingNodeUpdates = {};
  final Set<String> _pendingConnectionUpdates = {};

  // Connection index for O(1) lookup by node ID
  final Map<String, Set<String>> _connectionsByNodeId = {};

  // Editor initialization tracking - set to true after initializeForEditor() is called
  bool _editorInitialized = false;

  // Actions and shortcuts management
  late final NodeFlowShortcutManager<T> shortcuts;

  // Caching state for smart culling (hysteresis)
  // We query a larger chunk and only re-query when approaching the edge
  Rect? _cachedNodeQueryRect;
  List<Node<T>> _cachedVisibleNodesList = [];
  int _lastNodeIndexVersion = -1;

  Rect? _cachedConnectionQueryRect;
  List<Connection> _cachedVisibleConnectionsList = [];
  int _lastConnectionIndexVersion = -1;

  // Computed values - stored as late final fields for proper caching
  late final Computed<bool> _hasSelection = Computed(
    () => _selectedNodeIds.isNotEmpty || _selectedConnectionIds.isNotEmpty,
  );

  late final Computed<List<Node<T>>> _sortedNodes = Computed(
    _computeSortedNodes,
  );

  /// Connections currently affected by an interaction (drag/resize).
  /// These should be rendered in the active layer.
  late final Computed<Set<String>> _activeConnectionIds = Computed(() {
    final draggedId = interaction.currentDraggedNodeId;
    final resizingId = interaction.currentResizingNodeId;

    if (draggedId != null) {
      return _connectionsByNodeId[draggedId] ?? const {};
    }
    if (resizingId != null) {
      return _connectionsByNodeId[resizingId] ?? const {};
    }
    return const {};
  });

  /// Nodes currently affected by an interaction (drag/resize).
  /// When dragging a selected node, ALL selected nodes are active since they move together.
  /// These should be rendered in the active layer for 60fps during interaction.
  late final Computed<Set<String>> _activeNodeIds = Computed(() {
    final result = <String>{};
    final draggedId = interaction.currentDraggedNodeId;
    final resizingId = interaction.currentResizingNodeId;

    // If dragging, check if the dragged node is in selection
    // If so, all selected nodes are active (they move together)
    if (draggedId != null) {
      if (_selectedNodeIds.contains(draggedId)) {
        result.addAll(_selectedNodeIds);
      } else {
        result.add(draggedId);
      }
    }

    // Resizing always affects only one node
    if (resizingId != null) result.add(resizingId);

    return result;
  });

  /// Visible nodes based on current viewport with hysteresis.
  late final Computed<List<Node<T>>> _visibleNodes = Computed(() {
    // Depend on viewport and screen size
    final v = _viewport.value;
    final s = _screenSize.value;

    if (s.isEmpty) return _nodes.values.toList();

    // Calculate current viewport rect
    final currentViewportRect = Rect.fromLTWH(
      -v.x / v.zoom,
      -v.y / v.zoom,
      s.width / v.zoom,
      s.height / v.zoom,
    );

    // Check if spatial index changed
    final currentIndexVersion = _spatialIndex.version.value;
    final indexChanged = currentIndexVersion != _lastNodeIndexVersion;

    // Check if viewport is safely within cached query rect (Hysteresis)
    // We use a margin of 200px. If we are within 200px of the edge of the
    // cached area, we trigger a re-query.
    final cacheValid =
        !indexChanged &&
        _cachedNodeQueryRect != null &&
        _cachedNodeQueryRect!.contains(
          currentViewportRect.topLeft - const Offset(200, 200),
        ) &&
        _cachedNodeQueryRect!.contains(
          currentViewportRect.bottomRight + const Offset(200, 200),
        );

    if (cacheValid) {
      return _cachedVisibleNodesList;
    }

    // Re-query: Expand viewport by 1000px (chunk size)
    final queryRect = currentViewportRect.inflate(1000);
    final nodes = _spatialIndex.nodesIn(queryRect);

    // Ensure currently interacting nodes are always included
    final draggedId = interaction.currentDraggedNodeId;
    final resizingId = interaction.currentResizingNodeId;

    void ensureIncluded(String? id) {
      if (id == null) return;
      final node = _nodes[id];
      if (node != null && !nodes.contains(node)) {
        nodes.add(node);
      }
    }

    ensureIncluded(draggedId);
    ensureIncluded(resizingId);

    // Update cache
    _cachedNodeQueryRect = queryRect;
    _cachedVisibleNodesList = nodes;
    _lastNodeIndexVersion = currentIndexVersion;

    return nodes;
  });

  /// Visible connections based on current viewport with hysteresis.
  late final Computed<List<Connection>> _visibleConnections = Computed(() {
    // Depend on viewport and screen size
    final v = _viewport.value;
    final s = _screenSize.value;

    if (s.isEmpty) return _connections;

    final currentViewportRect = Rect.fromLTWH(
      -v.x / v.zoom,
      -v.y / v.zoom,
      s.width / v.zoom,
      s.height / v.zoom,
    );

    final currentIndexVersion = _spatialIndex.version.value;
    final indexChanged = currentIndexVersion != _lastConnectionIndexVersion;

    final cacheValid =
        !indexChanged &&
        _cachedConnectionQueryRect != null &&
        _cachedConnectionQueryRect!.contains(
          currentViewportRect.topLeft - const Offset(200, 200),
        ) &&
        _cachedConnectionQueryRect!.contains(
          currentViewportRect.bottomRight + const Offset(200, 200),
        );

    if (cacheValid) {
      return _cachedVisibleConnectionsList;
    }

    final queryRect = currentViewportRect.inflate(1000);
    final connections = _spatialIndex.connectionsIn(queryRect);

    _cachedConnectionQueryRect = queryRect;
    _cachedVisibleConnectionsList = connections;
    _lastConnectionIndexVersion = currentIndexVersion;

    return connections;
  });

  /// Visible nodes sorted by z-index (cached Computed).
  /// This caches the sorted result to avoid O(n log n) sort on every frame.
  late final Computed<List<Node<T>>> _sortedVisibleNodes = Computed(() {
    // Get the cached visible nodes
    final nodes = List<Node<T>>.from(_visibleNodes.value);

    // Observe zIndex values to ensure reactivity when zIndex changes
    for (final node in nodes) {
      node.zIndex.value;
    }

    // Sort by zIndex ascending (lower zIndex = rendered first = behind)
    nodes.sort((a, b) => a.zIndex.value.compareTo(b.zIndex.value));
    return nodes;
  });

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

  /// Gets visible nodes sorted by z-index (package-private).
  ///
  /// Optimized for rendering only what's on screen.
  /// Uses cached Computed to avoid sorting on every access.
  List<Node<T>> get visibleNodes => _sortedVisibleNodes.value;

  /// Gets visible connections (package-private).
  List<Connection> get visibleConnections => _visibleConnections.value;

  /// Gets IDs of connections involved in current interaction (package-private).
  Set<String> get activeConnectionIds => _activeConnectionIds.value;

  /// Gets IDs of nodes involved in current interaction (package-private).
  /// When dragging a selected node, includes ALL selected nodes.
  Set<String> get activeNodeIds => _activeNodeIds.value;

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

  // NOTE: _setupSpatialIndexReactions() is now defined in editor_init_api.dart
  // It is called during _initController() to set up spatial index synchronization.

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
  ///
  /// Parameters:
  /// * [nodeId] - The ID of the node to resize
  /// * [handle] - The resize handle being dragged
  /// * [globalPosition] - The global position of the pointer when resize started
  void startResize(String nodeId, ResizeHandle handle, Offset globalPosition) {
    final node = _nodes[nodeId];
    if (node == null || !node.isResizable) return;

    // Convert global position to graph coordinates
    final graphPos = viewport.toGraph(ScreenPosition(globalPosition));

    // Capture original bounds
    final originalBounds = Rect.fromLTWH(
      node.position.value.dx,
      node.position.value.dy,
      node.size.value.width,
      node.size.value.height,
    );

    interaction.startResize(nodeId, handle, graphPos.offset, originalBounds);
  }

  /// Updates the size of the currently resizing node during a resize operation.
  ///
  /// Uses absolute position-based resizing for predictable behavior:
  /// - Calculates new bounds from original state + total movement
  /// - Handles constraint boundaries (min/max size)
  /// - Supports handle swapping when crossing opposite edges
  /// - Tracks drift for proximity-based resume
  ///
  /// Parameters:
  /// * [globalPosition] - The current global position of the pointer
  void updateResize(Offset globalPosition) {
    final nodeId = interaction.currentResizingNodeId;
    final handle = interaction.currentResizeHandle;
    final startPos = interaction.currentResizeStartPosition;
    final originalBounds = interaction.currentOriginalNodeBounds;

    if (nodeId == null ||
        handle == null ||
        startPos == null ||
        originalBounds == null) {
      return;
    }

    final node = _nodes[nodeId];
    if (node == null || !node.isResizable) return;

    // Convert global position to graph coordinates
    final graphPos = viewport.toGraph(ScreenPosition(globalPosition));

    // Calculate new bounds using absolute positioning
    final resizableNode = node as ResizableMixin<T>;
    final result = resizableNode.calculateResize(
      handle: handle,
      originalBounds: originalBounds,
      startPosition: startPos,
      currentPosition: graphPos.offset,
    );

    // Apply the resize
    runInAction(() {
      resizableNode.applyBounds(result.newBounds);
      node.setVisualPosition(_config.snapToGridIfEnabled(node.position.value));
    });
    markNodeDirty(nodeId);

    // Track drift for debugging/analytics
    interaction.setHandleDrift(result.drift);
  }

  /// Ends the current resize operation.
  ///
  /// Clears resize state and re-enables panning.
  void endResize() {
    interaction.endResize();
  }

  /// Cancels a resize operation and reverts to original position/size.
  ///
  /// Restores the node to its state before the resize started using the
  /// original bounds captured in [InteractionState].
  void cancelResize() {
    final nodeId = interaction.currentResizingNodeId;
    final originalBounds = interaction.currentOriginalNodeBounds;

    if (nodeId == null || originalBounds == null) return;

    final node = _nodes[nodeId];
    if (node != null && node.isResizable) {
      runInAction(() {
        node.position.value = originalBounds.topLeft;
        node.setVisualPosition(
          _config.snapToGridIfEnabled(originalBounds.topLeft),
        );
        (node as ResizableMixin<T>).setSize(originalBounds.size);
      });
      markNodeDirty(nodeId);
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

    // Detach all extensions
    for (final extension in _extensions.toList()) {
      extension.detach();
    }
    _extensions.clear();

    // Detach context from all groupable nodes to clean up their reactions
    for (final node in _nodes.values) {
      if (node is GroupableMixin<T>) {
        node.detachContext();
      }
    }
  }

  // ============================================================
  // Extension System
  // ============================================================

  /// Registered extensions for this controller.
  final List<NodeFlowExtension<T>> _extensions = [];

  /// Current batch nesting depth.
  /// When > 0, we're inside a batch operation.
  int _batchDepth = 0;

  /// Registers an extension with this controller.
  ///
  /// The extension's [NodeFlowExtension.attach] method is called immediately.
  /// Throws a [StateError] if an extension with the same ID is already registered.
  ///
  /// Example:
  /// ```dart
  /// controller.addExtension(UndoRedoExtension<MyData>());
  /// ```
  void addExtension(NodeFlowExtension<T> extension) {
    if (_extensions.any((e) => e.id == extension.id)) {
      throw StateError(
        'Extension "${extension.id}" is already registered. '
        'Remove it first before adding a new instance.',
      );
    }
    _extensions.add(extension);
    extension.attach(this);
  }

  /// Removes an extension by its ID.
  ///
  /// The extension's [NodeFlowExtension.detach] method is called before removal.
  /// Does nothing if no extension with the given ID is registered.
  ///
  /// Example:
  /// ```dart
  /// controller.removeExtension('undo-redo');
  /// ```
  void removeExtension(String id) {
    final index = _extensions.indexWhere((e) => e.id == id);
    if (index == -1) return;

    final extension = _extensions.removeAt(index);
    extension.detach();
  }

  /// Gets an extension by its type.
  ///
  /// Returns `null` if no extension of the given type is registered.
  /// Useful for Pro extensions that expose additional capabilities.
  ///
  /// Example:
  /// ```dart
  /// final history = controller.getExtension<HistoryExtension<MyData>>();
  /// if (history?.canUndo ?? false) {
  ///   history!.undo();
  /// }
  /// ```
  E? getExtension<E extends NodeFlowExtension<T>>() {
    for (final ext in _extensions) {
      if (ext is E) return ext;
    }
    return null;
  }

  /// Checks if an extension with the given ID is registered.
  ///
  /// Example:
  /// ```dart
  /// if (controller.hasExtension('undo-redo')) {
  ///   // Undo/redo is available
  /// }
  /// ```
  bool hasExtension(String id) => _extensions.any((e) => e.id == id);

  /// Gets all registered extensions.
  ///
  /// Returns an unmodifiable view of the extensions list.
  List<NodeFlowExtension<T>> get extensions => List.unmodifiable(_extensions);

  /// Emits an event to all registered extensions.
  ///
  /// Called internally by mutation methods. Extensions receive events
  /// in the order they were registered.
  void _emitEvent(GraphEvent event) {
    for (final extension in _extensions) {
      extension.onEvent(event);
    }
  }

  /// Wraps multiple operations in a batch.
  ///
  /// Extensions will see [BatchStarted] before the operations and
  /// [BatchEnded] after. This allows extensions like undo/redo to
  /// group multiple operations into a single undoable action.
  ///
  /// Batches can be nested. Only the outermost batch emits events.
  ///
  /// Example:
  /// ```dart
  /// controller.batch('delete-selection', () {
  ///   for (final id in selectedNodeIds.toList()) {
  ///     controller.removeNode(id);
  ///   }
  /// });
  /// ```
  void batch(String reason, void Function() operations) {
    if (_batchDepth == 0) {
      _emitEvent(BatchStarted(reason));
    }
    _batchDepth++;

    try {
      operations();
    } finally {
      _batchDepth--;
      if (_batchDepth == 0) {
        _emitEvent(BatchEnded());
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
      markNodesDirty(nodeIds);
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
      _isAnyDragInProgress && !(_theme?.debugMode.isEnabled ?? false);

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
  void markNodeDirty(String nodeId) {
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
  void markNodesDirty(Iterable<String> nodeIds) {
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
