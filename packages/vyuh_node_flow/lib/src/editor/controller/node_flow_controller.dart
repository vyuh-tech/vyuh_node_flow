import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:mobx/mobx.dart';

import '../../connections/connection.dart';
import '../../connections/connection_painter.dart';
import '../../connections/connection_path_cache.dart';
import '../../connections/connection_validation.dart';
import '../../connections/temporary_connection.dart';
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
import '../../plugins/debug/debug_plugin.dart';
import '../../plugins/events/events.dart';
import '../../plugins/node_flow_plugin.dart';
import '../../plugins/snap/snap_plugin.dart';
import '../../ports/port.dart';
import '../../shared/spatial/graph_spatial_index.dart';
import '../drag_session.dart';
import '../keyboard/node_flow_actions.dart';
import '../node_flow_behavior.dart';
import '../node_flow_config.dart';
import '../node_flow_events.dart';
import '../resizer_widget.dart';
import '../snap_delegate.dart';
import '../themes/node_flow_theme.dart';
import '../viewport_animation_mixin.dart';
import 'viewport_culling_policy.dart';

part 'connection_api.dart';
part 'connection_index_api.dart';
part 'dirty_tracking_api.dart';
part 'editor_init_api.dart';
part 'graph_api.dart';
part 'group_api.dart';
part 'node_api.dart';
part 'node_flow_controller_api.dart';
part 'resize_api.dart';
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
/// This is the main controller for managing nodes, connections, viewport,
/// and interactions in a node flow editor. It uses MobX for reactive state management.
///
/// ## Type Parameters
/// - `T`: The data type stored in each node
/// - `C`: The data type stored in each connection (defaults to `void` for untyped connections)
///
/// ## Example
/// ```dart
/// // Untyped connections (default)
/// final controller = NodeFlowController<MyNodeData>();
///
/// // Typed connections with a sealed class
/// sealed class EdgeData {}
/// class HighPriority extends EdgeData {}
/// class Normal extends EdgeData {}
///
/// final controller = NodeFlowController<MyNodeData, EdgeData>(
///   connections: [
///     Connection<EdgeData>(
///       id: 'conn-1',
///       sourceNodeId: 'a',
///       sourcePortId: 'out',
///       targetNodeId: 'b',
///       targetPortId: 'in',
///       data: HighPriority(),
///     ),
///   ],
/// );
/// ```
class NodeFlowController<T, C> {
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
    List<Connection<C>>? connections,
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
  void _loadInitialGraph(List<Node<T>> nodes, List<Connection<C>> connections) {
    runInAction(() {
      for (final node in nodes) {
        _nodes[node.id] = node;
      }
      _connections.addAll(connections);
      _rebuildConnectionIndexes();
    });

    // Note: Full infrastructure setup happens when initController is called
    // by the editor widget, since we need the theme for proper spatial index setup.
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

  // Snap delegate for alignment/snap behavior during drag
  SnapDelegate? _snapDelegate;

  /// Gets the current snap delegate for alignment/snap behavior.
  ///
  /// Returns `null` if no snap delegate is set, which means no snapping
  /// behavior during node drag operations.
  SnapDelegate? get snapDelegate => _snapDelegate;

  /// Sets the snap delegate for alignment/snap behavior during drag.
  ///
  /// The delegate is called during node drag operations to adjust the
  /// drag delta for snapping to alignment guides or other targets.
  ///
  /// Example:
  /// ```dart
  /// controller.setSnapDelegate(MySnapDelegate());
  /// ```
  void setSnapDelegate(SnapDelegate? delegate) {
    _snapDelegate = delegate;
  }

  /// Snaps a position to the grid if grid snapping is enabled.
  ///
  /// This is a convenience method that accesses the [GridSnapDelegate]
  /// through the snap delegate chain. Returns the position unchanged if:
  /// - No snap delegate is set
  /// - The snap delegate doesn't contain a [GridSnapDelegate]
  /// - Grid snapping is disabled
  ///
  /// Use this for snapping positions when adding nodes, pasting, or other
  /// programmatic position updates.
  ///
  /// Example:
  /// ```dart
  /// final snappedPos = controller.snapToGrid(position);
  /// node.setPosition(snappedPos);
  /// ```
  Offset snapToGrid(Offset position) {
    // First try the attached delegate
    final delegate = _snapDelegate;
    if (delegate is SnapPlugin) {
      // Only snap if plugin is enabled
      if (!delegate.enabled) return position;
      return delegate.gridSnapDelegate?.snapPoint(position) ?? position;
    }
    if (delegate is GridSnapDelegate) {
      return delegate.snapPoint(position);
    }

    // Fall back to plugin registry (for unit tests without initController)
    final snapExt = _config.pluginRegistry.get<SnapPlugin>();
    if (snapExt != null) {
      // Only snap if plugin is enabled
      if (!snapExt.enabled) return position;
      return snapExt.gridSnapDelegate?.snapPoint(position) ?? position;
    }

    return position;
  }

  // Structured events system
  NodeFlowEvents<T, C> _events = const NodeFlowEvents();

  /// Gets the current events configuration.
  ///
  /// Events are organized into logical groups (node, connection, viewport, etc.)
  /// for better discoverability and maintainability.
  NodeFlowEvents<T, C> get events => _events;

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
  /// and connections.
  void setBehavior(NodeFlowBehavior value) {
    runInAction(() => _behavior.value = value);
  }

  // Core data structures
  final ObservableMap<String, Node<T>> _nodes =
      ObservableMap<String, Node<T>>();
  final ObservableList<Connection<C>> _connections =
      ObservableList<Connection<C>>();
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

  /// Connection path cache - the data layer for connection geometry.
  /// Controller owns this; painter uses it for rendering.
  ConnectionPathCache? _connectionPathCache;

  // Connection segment calculator for spatial index (set by _initController)
  List<Rect> Function(Connection connection)? _connectionSegmentCalculator;

  // Spatial hit testing
  late final GraphSpatialIndex<T, C> _spatialIndex = GraphSpatialIndex<T, C>(
    portSnapDistance: _config.portSnapDistance.value,
  );

  // Pending spatial index updates (dirty tracking)
  final Set<String> _pendingNodeUpdates = {};
  final Set<String> _pendingConnectionUpdates = {};

  // Connection index for O(1) lookup by node ID
  final Map<String, Set<String>> _connectionsByNodeId = {};

  // Connection indexes for O(1) port-level queries.
  // Keys use "nodeId::portId" format.
  final Map<String, int> _sourceConnectionCountByPortKey = {};
  final Map<String, int> _targetConnectionCountByPortKey = {};

  // Duplicate-connection detection index keyed by:
  // "sourceNode::sourcePort->targetNode::targetPort".
  final Map<String, int> _connectionPairCountByPorts = {};

  // Editor initialization tracking - set to true after initializeForEditor() is called
  bool _editorInitialized = false;

  // Actions and shortcuts management
  late final NodeFlowShortcutManager<T> shortcuts;

  // Caching state for smart culling (hysteresis)
  // We query a larger chunk and only re-query when approaching the edge
  Rect? _cachedNodeQueryRect;
  List<Node<T>> _cachedVisibleNodesList = [];
  int _lastNodeIndexVersion = -1;
  Rect? _lastNodeViewportRect;

  Rect? _cachedConnectionQueryRect;
  List<Connection<C>> _cachedVisibleConnectionsList = [];
  int _lastConnectionIndexVersion = -1;
  Rect? _lastConnectionViewportRect;

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
    final isViewportInteracting = interaction.isViewportDragging;

    if (!v.x.isFinite || !v.y.isFinite || !v.zoom.isFinite || v.zoom <= 0) {
      return _nodes.values.toList();
    }

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
    final previousViewportRect = _lastNodeViewportRect;

    // Reuse cache while the viewport remains safely inside the prefetched area.
    final cacheValid = ViewportCullingPolicy.isCacheValid(
      cachedQueryRect: _cachedNodeQueryRect,
      viewportRect: currentViewportRect,
      indexChanged: indexChanged,
    );

    if (cacheValid) {
      _lastNodeViewportRect = currentViewportRect;
      return _cachedVisibleNodesList;
    }

    final queryRect = ViewportCullingPolicy.buildQueryRect(
      viewportRect: currentViewportRect,
      previousViewportRect: previousViewportRect,
      isViewportInteracting: isViewportInteracting,
    );
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
    _lastNodeViewportRect = currentViewportRect;

    return nodes;
  });

  /// Visible connections based on current viewport with hysteresis.
  late final Computed<List<Connection<C>>> _visibleConnections = Computed(() {
    // Depend on viewport and screen size
    final v = _viewport.value;
    final s = _screenSize.value;
    final isViewportInteracting = interaction.isViewportDragging;

    if (!v.x.isFinite || !v.y.isFinite || !v.zoom.isFinite || v.zoom <= 0) {
      return _connections;
    }

    if (s.isEmpty) return _connections;

    final currentViewportRect = Rect.fromLTWH(
      -v.x / v.zoom,
      -v.y / v.zoom,
      s.width / v.zoom,
      s.height / v.zoom,
    );

    final currentIndexVersion = _spatialIndex.version.value;
    final indexChanged = currentIndexVersion != _lastConnectionIndexVersion;
    final previousViewportRect = _lastConnectionViewportRect;

    final cacheValid = ViewportCullingPolicy.isCacheValid(
      cachedQueryRect: _cachedConnectionQueryRect,
      viewportRect: currentViewportRect,
      indexChanged: indexChanged,
    );

    if (cacheValid) {
      _lastConnectionViewportRect = currentViewportRect;
      return _cachedVisibleConnectionsList;
    }

    final queryRect = ViewportCullingPolicy.buildQueryRect(
      viewportRect: currentViewportRect,
      previousViewportRect: previousViewportRect,
      isViewportInteracting: isViewportInteracting,
    );
    final connections = _spatialIndex.connectionsIn(queryRect);

    _cachedConnectionQueryRect = queryRect;
    _cachedVisibleConnectionsList = connections;
    _lastConnectionIndexVersion = currentIndexVersion;
    _lastConnectionViewportRect = currentViewportRect;

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
  List<Connection<C>> get connections => _connections;

  /// Gets the IDs of all currently selected nodes.
  ///
  /// Returns a set of node IDs. An empty set means no nodes are selected.
  Set<String> get selectedNodeIds => _selectedNodeIds;

  /// Gets the current viewport state (position and zoom).
  ///
  /// The viewport determines what portion of the graph is visible and at
  /// what zoom level.
  GraphViewport get viewport => _viewport.value;

  /// Gets the viewport observable for reactive UI updates.
  ///
  /// Use this when you need to observe viewport changes in MobX Observer widgets.
  /// Access `.value` to get the current [GraphViewport].
  ///
  /// Example:
  /// ```dart
  /// Observer(builder: (_) => Text('Zoom: ${controller.viewportObservable.value.zoom}'));
  /// ```
  Observable<GraphViewport> get viewportObservable => _viewport;

  /// Gets the nodes observable map for reactive UI updates.
  ///
  /// Use this when you need to observe node collection changes in MobX Observer widgets.
  ObservableMap<String, Node<T>> get nodesObservable => _nodes;

  /// Gets the connections observable list for reactive UI updates.
  ///
  /// Use this when you need to observe connection collection changes in MobX Observer widgets.
  ObservableList<Connection<C>> get connectionsObservable => _connections;

  /// Gets the selected node IDs observable set for reactive UI updates.
  ///
  /// Use this when you need to observe selection changes in MobX Observer widgets.
  ObservableSet<String> get selectedNodeIdsObservable => _selectedNodeIds;

  /// Gets the selected connection IDs observable set for reactive UI updates.
  ///
  /// Use this when you need to observe connection selection changes in MobX Observer widgets.
  ObservableSet<String> get selectedConnectionIdsObservable =>
      _selectedConnectionIds;

  /// Checks if there is any active selection (nodes or connections).
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
  List<Connection<C>> get visibleConnections => _visibleConnections.value;

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
  // Resize State
  // ===========================================================================

  /// Gets the ID of the node currently being resized (package-private).
  ///
  /// Works for all node types including [GroupNode] and [CommentNode].
  /// Returns null if no resize operation is in progress.
  String? get resizingNodeId => interaction.currentResizingNodeId;

  /// Checks if any resize operation is in progress (package-private).
  ///
  /// Returns true when any node is being resized.
  bool get isResizing => interaction.isResizing;

  /// Gets the IDs of all currently selected connections (package-private).
  ///
  /// Returns a set of connection IDs. An empty set means no connections are selected.
  Set<String> get selectedConnectionIds => _selectedConnectionIds;

  /// Gets the hit tester for spatial queries (package-private).
  ///
  /// Used by the editor for efficient hit testing with spatial indexing.
  GraphSpatialIndex<T, C> get spatialIndex => _spatialIndex;

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

  // NOTE: _setupNodeMonitoringReactions() and _setupSelectionReactions()
  // are defined in group_api.dart.
  //
  // NOTE: _setupSpatialIndexReactions() is defined in editor_init_api.dart.
  // It is called during _initController() to set up spatial index synchronization.

  /// Gets the connection painter used for rendering and hit-testing connections.
  ///
  /// The connection painter is initialized during [initController], which is
  /// typically called automatically by the editor widget during its initState.
  ///
  /// Throws `StateError` if accessed before initialization.
  ConnectionPainter get connectionPainter {
    if (_connectionPainter == null) {
      throw StateError(
        'ConnectionPainter not initialized. '
        'Ensure the controller is used with a NodeFlowEditor widget.',
      );
    }
    return _connectionPainter!;
  }

  /// Whether the connection painter has been initialized.
  /// Use this to guard access to [connectionPainter] during initialization.
  bool get isConnectionPainterInitialized => _connectionPainter != null;

  /// Gets the connection path cache (data layer).
  ///
  /// Use this for geometry queries (hit testing, bounds intersection).
  /// Throws `StateError` if accessed before initialization.
  ConnectionPathCache get connectionPathCache {
    if (_connectionPathCache == null) {
      throw StateError(
        'ConnectionPathCache not initialized. '
        'Ensure the controller is used with a NodeFlowEditor widget.',
      );
    }
    return _connectionPathCache!;
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

    // Detach all plugins
    for (final plugin in _plugins.toList()) {
      plugin.detach();
    }
    _plugins.clear();

    // Detach context from all groupable nodes to clean up their reactions
    for (final node in _nodes.values) {
      if (node is GroupableMixin<T>) {
        node.detachContext();
      }
    }
  }

  // ============================================================
  // Plugin System
  // ============================================================

  /// Registered plugins for this controller.
  final List<NodeFlowPlugin> _plugins = [];

  /// Current batch nesting depth.
  /// When > 0, we're inside a batch operation.
  int _batchDepth = 0;

  /// Registers a plugin with this controller.
  ///
  /// The plugin's [NodeFlowPlugin.attach] method is called immediately.
  /// Throws a [StateError] if a plugin with the same ID is already registered.
  ///
  /// Example:
  /// ```dart
  /// controller.addPlugin(UndoRedoPlugin<MyData>());
  /// ```
  void addPlugin(NodeFlowPlugin plugin) {
    if (_plugins.any((e) => e.id == plugin.id)) {
      throw StateError(
        'Plugin "${plugin.id}" is already registered. '
        'Remove it first before adding a new instance.',
      );
    }
    _plugins.add(plugin);
    plugin.attach(this);
  }

  /// Removes a plugin by its ID.
  ///
  /// The plugin's [NodeFlowPlugin.detach] method is called before removal.
  /// Does nothing if no plugin with the given ID is registered.
  ///
  /// Example:
  /// ```dart
  /// controller.removePlugin('undo-redo');
  /// ```
  void removePlugin(String id) {
    final index = _plugins.indexWhere((e) => e.id == id);
    if (index == -1) return;

    final plugin = _plugins.removeAt(index);
    plugin.detach();
  }

  /// Gets a plugin by its type.
  ///
  /// Returns `null` if no plugin of the given type is registered.
  /// Useful for plugins that expose additional capabilities.
  ///
  /// Example:
  /// ```dart
  /// final history = controller.getPlugin<HistoryPlugin>();
  /// if (history?.canUndo ?? false) {
  ///   history!.undo();
  /// }
  /// ```
  E? getPlugin<E extends NodeFlowPlugin>() {
    for (final ext in _plugins) {
      if (ext is E) return ext;
    }
    return null;
  }

  /// Resolves a plugin by type.
  ///
  /// Checks the controller's attached plugins first, then falls back to
  /// the config's plugin registry.
  ///
  /// Returns `null` if the plugin is not found.
  ///
  /// Example:
  /// ```dart
  /// final minimap = controller.resolvePlugin<MinimapPlugin>();
  /// minimap?.toggle();
  /// ```
  E? resolvePlugin<E extends NodeFlowPlugin>() {
    // First check if already attached
    var ext = getPlugin<E>();
    if (ext != null) return ext;

    // Try to get from registry and attach
    ext = config.pluginRegistry.get<E>();
    if (ext != null) {
      addPlugin(ext);
    }
    return ext;
  }

  /// Checks if a plugin with the given ID is registered.
  ///
  /// Example:
  /// ```dart
  /// if (controller.hasPlugin('undo-redo')) {
  ///   // Undo/redo is available
  /// }
  /// ```
  bool hasPlugin(String id) => _plugins.any((e) => e.id == id);

  /// Gets all registered plugins.
  ///
  /// Returns an unmodifiable view of the plugins list.
  List<NodeFlowPlugin> get plugins => List.unmodifiable(_plugins);

  /// Emits an event to all registered plugins.
  ///
  /// Called internally by mutation methods. Plugins receive events
  /// in the order they were registered.
  void _emitEvent(GraphEvent event) {
    for (final plugin in _plugins) {
      plugin.onEvent(event);
    }
  }

  /// Wraps multiple operations in a batch.
  ///
  /// Plugins will see [BatchStarted] before the operations and
  /// [BatchEnded] after. This allows plugins like undo/redo to
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
}

// NOTE: DirtyTrackingPlugin is defined in dirty_tracking_api.dart.

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
