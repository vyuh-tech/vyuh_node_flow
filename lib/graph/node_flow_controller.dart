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

/// High-performance MobX controller for node flow state management
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
  NodeFlowConfig get config => _config;

  // Theme configuration
  NodeFlowTheme? _theme;
  NodeFlowTheme? get theme => _theme;

  // Callbacks for various events
  NodeFlowCallbacks<T> _callbacks = const NodeFlowCallbacks();
  NodeFlowCallbacks<T> get callbacks => _callbacks;

  // Canvas focus management
  final FocusNode _canvasFocusNode = FocusNode(debugLabel: 'NodeFlowCanvas');

  /// The focus node for the canvas - to be used by the editor widget
  FocusNode get canvasFocusNode => _canvasFocusNode;

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
  List<Connection> get connections => _connections;
  Set<String> get selectedNodeIds => _selectedNodeIds;
  GraphViewport get viewport => _viewport.value;
  bool get hasSelection => _hasSelection.value;

  // Package-private - for internal widget use only
  Map<String, Node<T>> get nodes => _nodes;
  List<Node<T>> get sortedNodes => _sortedNodes.value;
  Size get screenSize => _screenSize.value;
  String? get draggedNodeId => interaction.currentDraggedNodeId;
  bool get isConnecting => interaction.isCreatingConnection;
  TemporaryConnection? get temporaryConnection =>
      interaction.temporaryConnection.value;
  bool get isDrawingSelection => interaction.isDrawingSelection;
  Offset? get lastPointerPosition => interaction.currentPointerPosition;
  Rect? get selectionRectangle => interaction.selectionRectangle.value;
  Offset? get selectionStartPoint => interaction.selectionStart;
  MouseCursor get currentCursor => interaction.cursor;
  bool get panEnabled => interaction.isPanEnabled;
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

  /// Get the connection painter - must be initialized first
  ConnectionPainter get connectionPainter {
    if (_connectionPainter == null) {
      throw StateError(
        'ConnectionPainter not initialized. Call setTheme or setCallbacksAndTheme first.',
      );
    }
    return _connectionPainter!;
  }

  void dispose() {
    _canvasFocusNode.dispose();
    _connectionPainter?.dispose();
    annotations.dispose();
    // Other disposal logic...
  }
}
