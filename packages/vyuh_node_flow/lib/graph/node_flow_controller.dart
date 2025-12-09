import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:mobx/mobx.dart';

import '../annotations/annotation.dart';
import '../connections/connection.dart';
import '../connections/connection_painter.dart';
import '../connections/temporary_connection.dart';
import '../graph/graph.dart';
import '../graph/node_flow_config.dart';
import '../graph/node_flow_events.dart';
import '../graph/node_flow_theme.dart';
import '../graph/viewport.dart';
import '../nodes/interaction_state.dart';
import '../nodes/node.dart';
import '../nodes/node_data.dart';
import '../nodes/node_shape.dart';
import '../ports/port.dart';
import '../shared/shortcuts_viewer_dialog.dart';
import '../shared/spatial/graph_spatial_index.dart';
import 'node_flow_actions.dart';

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
      _config = config ?? NodeFlowConfig.defaultConfig {
    // Initialize annotation controller with reference to this controller
    annotations = AnnotationController<T>(this);

    // Initialize actions and shortcuts system
    shortcuts = NodeFlowShortcutManager<T>();
    shortcuts.registerActions(DefaultNodeFlowActions.createDefaultActions<T>());

    // Setup annotation reactions after construction
    _setupAnnotationReactions();

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

  // Theme configuration
  NodeFlowTheme? _theme;

  /// Gets the current theme configuration.
  ///
  /// Returns `null` if no theme has been set. The theme is typically set
  /// by the editor widget during initialization.
  NodeFlowTheme? get theme => _theme;

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

  // Spatial hit testing
  late final GraphSpatialIndex<T> _spatialIndex = GraphSpatialIndex<T>(
    portSnapDistance: _config.portSnapDistance.value,
  );

  // Pending spatial index updates (dirty tracking)
  final Set<String> _pendingNodeUpdates = {};
  final Set<String> _pendingAnnotationUpdates = {};
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

  void _setupSelectionReactions() {
    // Fire selection change event when selection changes
    reaction(
      (_) {
        // Observe all selection state
        return (
          _selectedNodeIds.toSet(),
          _selectedConnectionIds.toSet(),
          annotations.selectedAnnotationIds.toSet(),
        );
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

        final selectedAnnotations = annotations.selectedAnnotationIds
            .map((id) => annotations.annotations[id])
            .where((anno) => anno != null)
            .cast<Annotation>()
            .toList();

        final selectionState = SelectionState<T>(
          nodes: selectedNodes,
          connections: selectedConnections,
          annotations: selectedAnnotations,
        );

        // Fire the selection change event
        events.onSelectionChange?.call(selectionState);
      },
    );
  }

  void _setupSpatialIndexReactions() {
    // === DRAG STATE FLUSH REACTION ===
    // When any drag ends (node or annotation), flush all pending spatial index updates.
    // This is the single point where pending updates are committed.
    reaction(
      (_) => (
        interaction.draggedNodeId.value,
        annotations.draggedAnnotationId,
      ),
      ((String?, String?) dragState) {
        final (nodeDragId, annotationDragId) = dragState;
        // Only flush when ALL drags have ended
        if (nodeDragId == null && annotationDragId == null) {
          _flushPendingSpatialUpdates();
        }
      },
      fireImmediately: false,
    );

    // === NODE ADD/REMOVE SYNC ===
    // When nodes are added/removed, rebuild the node spatial index
    reaction(
      (_) => _nodes.keys.toSet(),
      (Set<String> currentNodeIds) {
        _spatialIndex.rebuildFromNodes(_nodes.values);
      },
      fireImmediately: false,
    );

    // === CONNECTION ADD/REMOVE SYNC ===
    // When connections are added/removed, rebuild connection spatial index and update index
    reaction(
      (_) => _connections.map((c) => c.id).toSet(),
      (Set<String> connectionIds) {
        // Rebuild connection-by-node index
        _rebuildConnectionsByNodeIndex();
        // Rebuild connection spatial index
        _spatialIndex.rebuildConnections(
          _connections,
          (connection) => _calculateConnectionBounds(connection) ?? Rect.zero,
        );
      },
      fireImmediately: false,
    );

    // === ANNOTATION ADD/REMOVE SYNC ===
    reaction(
      (_) => annotations.annotations.keys.toSet(),
      (Set<String> annotationIds) {
        _spatialIndex.rebuildFromAnnotations(annotations.annotations.values);
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

/// Private extension for dirty tracking and spatial index management.
///
/// This extension groups all the dirty tracking logic for efficient spatial
/// index updates. The pattern defers spatial index updates during drag
/// operations and batches them when the drag ends.
///
/// Key concepts:
/// - Dirty tracking: Nodes/annotations/connections are marked "dirty" during drag
/// - Deferred updates: Spatial index updates are deferred to pending sets
/// - Batch flush: All pending updates are flushed when drag ends
/// - Connection index: O(1) lookup of connections by node ID
extension DirtyTrackingExtension<T> on NodeFlowController<T> {
  /// Checks if any drag operation is in progress (node or annotation)
  bool get _isAnyDragInProgress =>
      interaction.draggedNodeId.value != null ||
      annotations.draggedAnnotationId != null;

  /// Flushes all pending spatial index updates.
  /// Called when drag operations end.
  void _flushPendingSpatialUpdates() {
    // Flush node updates
    if (_pendingNodeUpdates.isNotEmpty) {
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

    // Flush connection updates
    if (_pendingConnectionUpdates.isNotEmpty) {
      for (final connectionId in _pendingConnectionUpdates) {
        final connection = _connections.firstWhere(
          (c) => c.id == connectionId,
          orElse: () => throw StateError('Connection not found'),
        );
        final bounds = _calculateConnectionBounds(connection);
        if (bounds != null) {
          _spatialIndex.updateConnection(connection, [bounds]);
        }
      }
      _pendingConnectionUpdates.clear();
    }

    // Flush annotation updates
    if (_pendingAnnotationUpdates.isNotEmpty) {
      for (final annotationId in _pendingAnnotationUpdates) {
        final annotation = annotations.annotations[annotationId];
        if (annotation != null) {
          _spatialIndex.updateAnnotation(annotation);
        }
      }
      _pendingAnnotationUpdates.clear();
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

  /// Updates spatial index bounds for a single node's connections using the index.
  void _updateConnectionBoundsForNode(String nodeId) {
    final connectionIds = _connectionsByNodeId[nodeId];
    if (connectionIds == null || connectionIds.isEmpty) return;

    for (final connectionId in connectionIds) {
      final connection = _connections.firstWhere(
        (c) => c.id == connectionId,
        orElse: () => throw StateError('Connection not found: $connectionId'),
      );
      final bounds = _calculateConnectionBounds(connection);
      if (bounds != null) {
        _spatialIndex.updateConnection(connection, [bounds]);
      }
    }
  }

  /// Updates spatial index bounds for connections attached to the given nodes.
  void _updateConnectionBoundsForNodeIds(Iterable<String> nodeIds) {
    final connectionIdsToUpdate = <String>{};
    for (final nodeId in nodeIds) {
      final connectedIds = _connectionsByNodeId[nodeId];
      if (connectedIds != null) {
        connectionIdsToUpdate.addAll(connectedIds);
      }
    }

    for (final connectionId in connectionIdsToUpdate) {
      final connection = _connections.firstWhere(
        (c) => c.id == connectionId,
        orElse: () => throw StateError('Connection not found: $connectionId'),
      );
      final bounds = _calculateConnectionBounds(connection);
      if (bounds != null) {
        _spatialIndex.updateConnection(connection, [bounds]);
      }
    }
  }

  // === Public internal methods (accessible from other libraries) ===
  // These methods need to be part of the extension but accessible externally,
  // hence the 'internal' prefix convention instead of underscore.

  // @nodoc - Internal framework use only - do not use in user code
  /// Marks a node as needing spatial index update.
  /// If no drag is in progress, updates immediately. Otherwise, defers until drag ends.
  void internalMarkNodeDirty(String nodeId) {
    if (_isAnyDragInProgress) {
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
    if (_isAnyDragInProgress) {
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

  // @nodoc - Internal framework use only - do not use in user code
  /// Marks an annotation as needing spatial index update.
  void internalMarkAnnotationDirty(String annotationId) {
    if (_isAnyDragInProgress) {
      _pendingAnnotationUpdates.add(annotationId);
    } else {
      final annotation = annotations.annotations[annotationId];
      if (annotation != null) {
        _spatialIndex.updateAnnotation(annotation);
      }
    }
  }
}
