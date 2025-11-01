import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:mobx/mobx.dart';

import '../annotations/annotation.dart';
import '../connections/connection.dart';
import '../connections/connection_painter.dart';
import '../connections/temporary_connection.dart';
import '../graph/graph.dart';
import '../graph/node_flow_callbacks.dart';
import '../graph/node_flow_config.dart';
import '../graph/node_flow_theme.dart';
import '../graph/viewport.dart';
import '../models/node_data.dart';
import '../nodes/interaction_state.dart';
import '../nodes/node.dart';
import '../ports/port.dart';
import '../shared/node_flow_actions.dart';
import '../widgets/shortcuts_viewer_dialog.dart';

part '../annotations/annotation_controller.dart';
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
      _config = config ?? NodeFlowConfig.defaultConfig,
      _callbacks = const NodeFlowCallbacks() {
    // Initialize annotation controller with reference to this controller
    annotations = AnnotationController<T>(this);

    // Initialize actions and shortcuts system
    shortcuts = NodeFlowShortcutManager<T>();
    shortcuts.registerActions(DefaultNodeFlowActions.createDefaultActions<T>());

    // Setup annotation reactions after construction
    _setupAnnotationReactions();
  }

  // Behavioral configuration
  final NodeFlowConfig _config;

  /// Gets the controller's configuration settings.
  ///
  /// The configuration controls behavior like snap-to-grid, zoom limits,
  /// port snap distance, and other behavioral settings.
  NodeFlowConfig get config => _config;

  // Theme configuration
  NodeFlowTheme? _theme;

  /// Gets the current theme configuration.
  ///
  /// Returns `null` if no theme has been set. The theme is typically set
  /// by the editor widget during initialization.
  NodeFlowTheme? get theme => _theme;

  // Callbacks for various events
  NodeFlowCallbacks<T> _callbacks = const NodeFlowCallbacks();

  /// Gets the current callback configuration.
  ///
  /// Callbacks are triggered for various events like node creation,
  /// deletion, selection, etc.
  NodeFlowCallbacks<T> get callbacks => _callbacks;

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

  // UI interaction flags
  final Observable<bool> _enableNodeDeletion = Observable(true);

  /// Whether node deletion via keyboard shortcuts is enabled.
  ///
  /// When `false`, the Delete/Backspace keyboard shortcuts will not delete nodes.
  /// Programmatic deletion via `removeNode()` is still possible regardless of this setting.
  bool get enableNodeDeletion => _enableNodeDeletion.value;

  /// Sets whether node deletion via keyboard shortcuts is enabled.
  void setNodeDeletion(bool value) {
    runInAction(() => _enableNodeDeletion.value = value);
  }

  // Core data structures
  final ObservableMap<String, Node<T>> _nodes =
      ObservableMap<String, Node<T>>();
  final ObservableList<Connection> _connections = ObservableList<Connection>();
  final ObservableSet<String> _selectedNodeIds = ObservableSet<String>();
  final ObservableSet<String> _selectedConnectionIds = ObservableSet<String>();
  final Observable<GraphViewport> _viewport;
  final Observable<Size> _screenSize = Observable(Size.zero);

  // Interaction state - organized in separate object
  final InteractionState interaction = InteractionState();

  // Annotation management
  late final AnnotationController<T> annotations;

  // Connection painting and hit-testing
  ConnectionPainter? _connectionPainter;

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

  /// Gets the last known pointer position (package-private).
  ///
  /// Used for drag operations. Returns `null` if no pointer position is tracked.
  Offset? get lastPointerPosition => interaction.currentPointerPosition;

  /// Gets the current selection rectangle being drawn (package-private).
  ///
  /// Returns `null` if no selection rectangle is active.
  Rect? get selectionRectangle => interaction.selectionRectangle.value;

  /// Gets the starting point of the selection rectangle (package-private).
  ///
  /// Returns `null` if no selection is being drawn.
  Offset? get selectionStartPoint => interaction.selectionStart;

  /// Gets the current mouse cursor style (package-private).
  ///
  /// Changes based on what the mouse is hovering over and current interaction state.
  MouseCursor get currentCursor => interaction.cursor;

  /// Checks if viewport panning is currently enabled (package-private).
  ///
  /// Panning is disabled during certain interactions like node dragging or
  /// connection creation.
  bool get panEnabled => interaction.isPanEnabled;

  /// Gets the IDs of all currently selected connections (package-private).
  ///
  /// Returns a set of connection IDs. An empty set means no connections are selected.
  Set<String> get selectedConnectionIds => _selectedConnectionIds;

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

  void _setupAnnotationReactions() {
    // Update annotations when nodes change position
    reaction(
      (_) {
        // Observe all node visual positions (what's actually rendered)
        for (final node in _nodes.values) {
          node.visualPosition.value; // Trigger observation on visual position
        }
        return _nodes.values.map((node) => node.visualPosition.value).toList();
      },
      (_) {
        // Update dependent annotations
        annotations.internalUpdateDependentAnnotations(_nodes);
      },
    );

    // Update annotations when nodes are added/removed
    reaction((_) => _nodes.keys.toSet(), (_) {
      // Update dependent annotations when node set changes
      annotations.internalUpdateDependentAnnotations(_nodes);
    });
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
        'ConnectionPainter not initialized. Call setTheme or setCallbacksAndTheme first.',
      );
    }
    return _connectionPainter!;
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
    annotations.dispose();
    // Other disposal logic...
  }
}
