part of 'node_flow_controller.dart';

/// Editor initialization API for [NodeFlowController].
///
/// This extension provides the canonical initialization entry point for the
/// NodeFlow editor. ALL initialization happens here - this is the "Big Bang"
/// moment that sets up the entire universe of the editor.
///
/// ## Design Principles
///
/// 1. **Single Entry Point**: [_initController] is THE ONLY place where
///    initialization occurs. No scattered initialization across multiple files.
///
/// 2. **Predictable Order**: All setup happens in a specific, documented order.
///    This eliminates timing-related bugs where components depend on each other.
///
/// 3. **Private to Editor**: This API is internal - only [NodeFlowEditor] can
///    call it. External code cannot interfere with initialization.
///
/// 4. **Idempotent**: Calling [_initController] multiple times is safe - it
///    only initializes once.
///
/// ## Initialization Order
///
/// 1. Theme setup
/// 2. Node shape builder setup
/// 3. Spatial index callbacks (portSizeResolver, nodeShapeBuilder)
/// 4. Connection painter creation
/// 5. Connection hit tester setup
/// 6. Render order provider setup
/// 7. Connection segment calculator storage
/// 8. Spatial index reactions setup
/// 9. Event handlers setup
/// 10. Initial spatial index rebuild (handles pre-loaded nodes)
///
extension EditorInitApi<T, C> on NodeFlowController<T, C> {
  // ============================================================================
  // Initialization State
  // ============================================================================

  /// Whether the controller has been initialized for editor use.
  ///
  /// This becomes true after [initController] completes successfully.
  /// Operations that require the editor to be initialized should check this
  /// flag first.
  bool get isEditorInitialized => _editorInitialized;

  // ============================================================================
  // Primary Initialization Entry Point
  // ============================================================================

  /// Initializes the controller for use with the NodeFlow editor.
  ///
  /// **THIS IS THE CANONICAL INITIALIZATION POINT.**
  ///
  /// All editor infrastructure is set up here in a specific order. This method
  /// must be called from [NodeFlowEditor.initState] before any other operations.
  ///
  /// **@internal** - This method is for internal use by [NodeFlowEditor] only.
  /// Do not call directly from application code.
  ///
  /// ## Parameters
  ///
  /// - [theme]: The visual theme for the editor (required)
  /// - [portSizeResolver]: Resolves the size of a port for spatial indexing (required)
  /// - [nodeShapeBuilder]: Optional builder for custom node shapes
  /// - [connectionHitTesterBuilder]: Builder for the connection hit test callback.
  ///   This receives the [ConnectionPainter] and returns a hit test function.
  /// - [connectionSegmentCalculator]: Calculates segment bounds for connection
  ///   spatial indexing. Required for accurate connection hit testing.
  /// - [events]: Optional event handlers for node/connection/viewport events
  ///
  /// ## Example
  ///
  /// ```dart
  /// // In NodeFlowEditor.initState():
  /// widget.controller.initController(
  ///   theme: widget.theme,
  ///   portSizeResolver: (port) => port.size ?? widget.theme.portTheme.size,
  ///   nodeShapeBuilder: widget.nodeShapeBuilder != null
  ///       ? (node) => widget.nodeShapeBuilder!(context, node)
  ///       : null,
  ///   connectionHitTesterBuilder: (painter) => (connection, point) {
  ///     // hit test logic using painter
  ///   },
  ///   connectionSegmentCalculator: (connection) {
  ///     // calculate segment bounds
  ///   },
  ///   events: widget.events,
  /// );
  /// ```
  void initController({
    required NodeFlowTheme theme,
    required Size Function(Port port) portSizeResolver,
    NodeShape? Function(Node<T> node)? nodeShapeBuilder,
    bool Function(Connection connection, Offset point)? Function(
      ConnectionPainter painter,
    )?
    connectionHitTesterBuilder,
    List<Rect> Function(Connection connection)? connectionSegmentCalculator,
    NodeFlowEvents<T, C>? events,
  }) {
    // Idempotent - only initialize once
    if (_editorInitialized) return;
    _editorInitialized = true;

    // =========================================================================
    // Step 1: Store the theme
    // =========================================================================
    runInAction(() => _themeObservable.value = theme);

    // =========================================================================
    // Step 2: Set up node shape builder
    // =========================================================================
    // This must happen before spatial index setup and connection painter
    // creation since both use the shape builder.
    _nodeShapeBuilder = nodeShapeBuilder;

    // =========================================================================
    // Step 3: Set up spatial index callbacks
    // =========================================================================
    // These callbacks are used when calculating bounds for nodes and ports.
    // They must be set before any spatial index operations.
    _spatialIndex.portSizeResolver = portSizeResolver;
    _spatialIndex.nodeShapeBuilder = nodeShapeBuilder;

    // =========================================================================
    // Step 4: Create connection painter
    // =========================================================================
    // The connection painter handles rendering and hit testing of connections.
    // It needs the theme and optionally the node shape builder.
    _connectionPainter = ConnectionPainter(
      theme: theme,
      nodeShape: nodeShapeBuilder != null
          ? (node) => nodeShapeBuilder(node as Node<T>)
          : null,
    );

    // =========================================================================
    // Step 5: Set up connection hit tester
    // =========================================================================
    // Now that the connection painter exists, we can create the hit tester.
    if (connectionHitTesterBuilder != null) {
      _spatialIndex.connectionHitTester = connectionHitTesterBuilder(
        _connectionPainter!,
      );
    }

    // =========================================================================
    // Step 6: Set up render order provider
    // =========================================================================
    // This enables accurate hit testing based on visual stacking order.
    _spatialIndex.renderOrderProvider = () => sortedNodes;

    // =========================================================================
    // Step 7: Store connection segment calculator for later use
    // =========================================================================
    _connectionSegmentCalculator = connectionSegmentCalculator;

    // =========================================================================
    // Step 8: Set up spatial index reactions
    // =========================================================================
    // These reactions automatically sync the spatial index when nodes,
    // connections, or theme properties change.
    _setupSpatialIndexReactions();

    // =========================================================================
    // Step 9: Set up event handlers
    // =========================================================================
    if (events != null) {
      _events = events;
    }

    // =========================================================================
    // Step 10: Initialize spatial indexes and node infrastructure
    // =========================================================================
    // If nodes were pre-loaded (e.g., from loadDocument before editor mounted),
    // we need to set up their infrastructure and rebuild spatial indexes now.
    _initializeLoadedNodes();
    _rebuildSpatialIndexes();
  }

  // ============================================================================
  // Theme Updates (Post-Initialization)
  // ============================================================================

  /// Updates the theme on an already-initialized controller.
  ///
  /// **@internal** - This method is for internal use by [NodeFlowEditor] only.
  /// Do not call directly from application code.
  ///
  /// This should only be called after [initController] has been called.
  /// For initial setup, use [initController] instead.
  void updateTheme(NodeFlowTheme theme) {
    if (!_editorInitialized) {
      throw StateError(
        'Cannot update theme before controller is initialized. '
        'Call initController first.',
      );
    }

    // Update the connection painter's theme (invalidates cache if style changed)
    _connectionPainter?.updateTheme(theme);

    // Update observable theme
    runInAction(() => _themeObservable.value = theme);
  }

  // ============================================================================
  // Event Updates (Post-Initialization)
  // ============================================================================

  /// Updates the event handlers on an already-initialized controller.
  ///
  /// **@internal** - This method is for internal use by [NodeFlowEditor] only.
  /// Do not call directly from application code.
  void updateEvents(NodeFlowEvents<T, C> events) {
    _events = events;
  }

  // ============================================================================
  // Node Shape Builder Updates (Post-Initialization)
  // ============================================================================

  /// Updates the node shape builder on an already-initialized controller.
  ///
  /// **@internal** - This method is for internal use by [NodeFlowEditor] only.
  /// Do not call directly from application code.
  ///
  /// This also updates the spatial index callback to use the new builder.
  void updateNodeShapeBuilder(NodeShape? Function(Node<T> node)? builder) {
    _nodeShapeBuilder = builder;
    _spatialIndex.nodeShapeBuilder = builder;

    // Update connection painter if it exists
    _connectionPainter?.updateNodeShape(
      builder != null ? (node) => builder(node as Node<T>) : null,
    );
  }

  // ============================================================================
  // Spatial Index Reactions Setup
  // ============================================================================

  /// Sets up MobX reactions for automatic spatial index synchronization.
  ///
  /// These reactions ensure the spatial index stays in sync with:
  /// - Node additions/removals
  /// - Connection additions/removals
  /// - Theme/style changes that affect path geometry
  /// - Node visibility changes
  /// - Drag state changes
  ///
  /// This is called once during [_initController] and should not be called
  /// directly.
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
    // When connections are added/removed, rebuild connection spatial index
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

  // ============================================================================
  // Node Infrastructure Setup
  // ============================================================================

  /// Sets up infrastructure for nodes that were loaded before initialization.
  ///
  /// This handles:
  /// - Setting visual positions with grid snapping
  /// - Attaching context for groupable nodes (GroupNode, etc.)
  ///
  /// Called during [_initController] if nodes exist.
  void _initializeLoadedNodes() {
    for (final node in _nodes.values) {
      // Set visual position with snapping
      node.setVisualPosition(_config.snapToGridIfEnabled(node.position.value));

      // Attach context for nodes with GroupableMixin (e.g., GroupNode)
      if (node is GroupableMixin<T>) {
        node.attachContext(_createGroupableContext());
      }
    }
  }

  // ============================================================================
  // Spatial Index Rebuild
  // ============================================================================

  /// Rebuilds all spatial indexes from current state.
  ///
  /// This is called during initialization and whenever a full rebuild is needed.
  void _rebuildSpatialIndexes() {
    // Rebuild node and port spatial index
    _spatialIndex.rebuildFromNodes(_nodes.values);

    // Rebuild connection spatial index if we have a segment calculator
    if (_connectionSegmentCalculator != null) {
      _spatialIndex.rebuildConnectionsWithSegments(
        _connections,
        _connectionSegmentCalculator!,
      );
    }
  }
}
