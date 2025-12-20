part of '../graph/node_flow_controller.dart';

/// Controller for managing annotations in the node flow
///
/// This controller provides methods for creating, selecting, moving, and managing
/// annotations within the node flow editor. All operations automatically handle
/// MobX reactivity and coordinate with the parent NodeFlowController.
///
/// Key behaviors:
/// - Snap-to-grid: Annotations respect the parent controller's snap-to-grid settings
/// - Unified selection: Works with the unified selection system across nodes/connections
/// - Theme integration: Automatically uses NodeFlowTheme for consistent styling
class AnnotationController<T> {
  AnnotationController(this._parentController) {
    _setupAnnotationReactions();
  }

  final NodeFlowController<T> _parentController;

  // Core annotation storage
  final ObservableMap<String, Annotation> _annotations =
      ObservableMap<String, Annotation>();
  final ObservableSet<String> _selectedAnnotationIds = ObservableSet<String>();

  // Interaction state
  final Observable<String?> _draggedAnnotationId = Observable(null);
  final Observable<Offset?> _lastPointerPosition = Observable(null);
  final Observable<MouseCursor> _annotationCursor = Observable(
    SystemMouseCursors.basic,
  );
  final Observable<String?> _highlightedGroupId = Observable(
    null,
  ); // Group highlighted during node drag

  // Resize state (works with any resizable annotation)
  final Observable<String?> _resizingAnnotationId = Observable(null);
  final Observable<ResizeHandle?> _resizeHandle = Observable(null);
  Offset? _resizeStartPosition;
  Size? _resizeStartSize;

  // Reaction disposers for cleanup
  final List<ReactionDisposer> _disposers = [];

  // Per-annotation reaction disposers (for annotations that track nodes)
  final Map<String, List<ReactionDisposer>> _annotationDisposers = {};

  // Track previous node IDs to detect additions/deletions
  Set<String> _previousNodeIds = {};

  // Computed property to track if we have any annotation selected
  late final Computed<bool> _hasSelection = Computed(
    () => _selectedAnnotationIds.isNotEmpty,
  );

  bool get hasAnnotationSelection => _hasSelection.value;

  // Flag to prevent cyclic updates when moving group nodes
  bool _isMovingGroupNodes = false;

  // Debug getter
  bool get isMovingGroupNodes => _isMovingGroupNodes;

  // Debug method to force reset flag if it gets stuck
  void resetGroupMoveFlag() {
    _isMovingGroupNodes = false;
  }

  // Public API - read-only access to annotations
  Map<String, Annotation> get annotations => _annotations;

  String? get draggedAnnotationId => _draggedAnnotationId.value;

  Offset? get lastPointerPosition => _lastPointerPosition.value;

  MouseCursor get annotationCursor => _annotationCursor.value;

  String? get highlightedGroupId => _highlightedGroupId.value;

  /// The ID of the annotation currently being resized, if any.
  String? get resizingAnnotationId => _resizingAnnotationId.value;

  /// Legacy getter for backwards compatibility.
  @Deprecated('Use resizingAnnotationId instead')
  String? get resizingGroupId => _resizingAnnotationId.value;

  /// Whether any annotation is currently being resized.
  bool get isResizing => _resizingAnnotationId.value != null;

  // Computed sorted annotations by z-index
  late final Computed<List<Annotation>> _sortedAnnotations = Computed(() {
    final annotationsList = _annotations.values.toList();

    // Trigger observation of all zIndex values for existing annotations
    for (final annotation in annotationsList) {
      annotation.zIndex; // Observe zIndex changes
    }

    // Sort by zIndex ascending (lower zIndex = rendered first = behind)
    annotationsList.sort((a, b) => a.zIndex.compareTo(b.zIndex));

    return annotationsList;
  });

  List<Annotation> get sortedAnnotations => _sortedAnnotations.value;

  // Annotation CRUD operations
  void addAnnotation(Annotation annotation) {
    runInAction(() {
      _annotations[annotation.id] = annotation;

      // Update spatial index
      _parentController._spatialIndex.updateAnnotation(annotation);

      // Only assign z-index if annotation doesn't have a meaningful one set
      // This preserves z-index values from loaded workflows while providing defaults for new annotations
      if (annotation.zIndex == -1) {
        // Find the current maximum z-index and add 1
        if (_annotations.length > 1) {
          final existingAnnotations = _annotations.values
              .where((a) => a.id != annotation.id)
              .toList();
          final maxZIndex = existingAnnotations
              .map((a) => a.zIndex)
              .fold(-1, math.max);
          annotation.zIndex = maxZIndex + 1;
        } else {
          // First annotation gets z-index 0
          annotation.zIndex = 0;
        }
      }

      // Initialize visual position with snapping (identical to node behavior)
      annotation.visualPosition = _parentController.config
          .snapAnnotationsToGridIfEnabled(annotation.position);

      // Set up node monitoring reactions if requested
      if (annotation.monitorNodes) {
        _setupNodeMonitoringForAnnotation(annotation);
      }

      // Watch for monitorNodes state changes (e.g., behavior changes in GroupAnnotation)
      // MobX tracks the underlying observable through the getter chain
      _setupMonitorNodesChangeReaction(annotation);
    });
  }

  void removeAnnotation(String annotationId) {
    runInAction(() {
      _annotations.remove(annotationId);
      _selectedAnnotationIds.remove(annotationId);

      // Remove from spatial index
      _parentController._spatialIndex.removeAnnotation(annotationId);

      // Dispose node monitoring reactions for this annotation
      _disposeNodeMonitoringForAnnotation(annotationId);

      // Clear drag state if removing the dragged annotation
      if (_draggedAnnotationId.value == annotationId) {
        _draggedAnnotationId.value = null;
        _lastPointerPosition.value = null;
      }
    });
  }

  void updateAnnotation(String annotationId, Annotation updatedAnnotation) {
    runInAction(() {
      _annotations[annotationId] = updatedAnnotation;
    });
    // Note: Spatial index update handled by MobX reactions in _setupSpatialIndexReactions()
  }

  Annotation? getAnnotation(String annotationId) {
    return _annotations[annotationId];
  }

  // @nodoc - Internal framework use only - do not use in user code
  void internalSelectAnnotation(String annotationId, {bool toggle = false}) {
    runInAction(() {
      if (toggle) {
        if (_selectedAnnotationIds.contains(annotationId)) {
          _selectedAnnotationIds.remove(annotationId);
          final annotation = _annotations[annotationId];
          if (annotation != null) {
            annotation.selected = false;
          }
        } else {
          _selectedAnnotationIds.add(annotationId);
          final annotation = _annotations[annotationId];
          if (annotation != null) {
            annotation.selected = true;
          }
          // Note: Removed auto-bring-to-front to allow manual z-index management
        }
      } else {
        // Clear previous annotation selections
        for (final id in _selectedAnnotationIds) {
          final annotation = _annotations[id];
          if (annotation != null) {
            annotation.selected = false;
          }
        }

        _selectedAnnotationIds.clear();
        _selectedAnnotationIds.add(annotationId);

        final annotation = _annotations[annotationId];
        if (annotation != null) {
          annotation.selected = true;
        }

        // IMPORTANT: Clear nodes and connections when selecting annotation (unified selection)
        _clearNodeAndConnectionSelections();

        // NOTE: Auto-bring-to-front removed to preserve manual z-index management
      }
    });
  }

  /// Select or deselect an annotation
  ///
  /// [annotationId] - The ID of the annotation to select
  /// [toggle] - If true, toggles selection state; if false, replaces current selection
  void selectAnnotation(String annotationId, {bool toggle = false}) {
    internalSelectAnnotation(annotationId, toggle: toggle);
  }

  /// Clear all annotation selections
  void clearAnnotationSelection() {
    runInAction(() {
      for (final id in _selectedAnnotationIds) {
        final annotation = _annotations[id];
        if (annotation != null) {
          annotation.selected = false;
        }
      }
      _selectedAnnotationIds.clear();
    });
  }

  /// Check if a specific annotation is currently selected
  bool isAnnotationSelected(String annotationId) {
    return _selectedAnnotationIds.contains(annotationId);
  }

  /// Get all currently selected annotation IDs
  Set<String> get selectedAnnotationIds => _selectedAnnotationIds;

  /// Check if a node intersects with any group annotation
  /// Returns the first intersecting group, or null if none found
  GroupAnnotation? findIntersectingGroup(String nodeId) {
    final node = _parentController.nodes[nodeId];
    if (node == null) return null;

    final nodeRect = Rect.fromLTWH(
      node.visualPosition.value.dx,
      node.visualPosition.value.dy,
      node.size.value.width,
      node.size.value.height,
    );

    for (final annotation in _annotations.values) {
      if (annotation is GroupAnnotation &&
          annotation.isVisible &&
          !annotation.hasNode(nodeId)) {
        final groupRect = Rect.fromLTWH(
          annotation.visualPosition.dx,
          annotation.visualPosition.dy,
          annotation.size.width,
          annotation.size.height,
        );

        if (nodeRect.overlaps(groupRect)) {
          return annotation;
        }
      }
    }

    return null;
  }

  /// Handle Command+drag group operations (add nodes to groups)
  ///
  /// This provides intuitive group management:
  /// - Command+drag node onto group → adds node to group
  /// - Visual feedback shows which group will be affected
  /// - Only works during Command+drag, preventing accidental operations
  void handleCommandDragGroupOperation(String nodeId, bool isCommandPressed) {
    if (!isCommandPressed) return;

    final intersectingGroup = findIntersectingGroup(nodeId);

    if (intersectingGroup != null) {
      // Node intersects with a group - add it if not already in group
      if (!intersectingGroup.hasNode(nodeId)) {
        intersectingGroup.addNode(nodeId);
      }
    }
    // Note: Ungroup functionality via Command+drag has been removed
    // Use keyboard shortcuts (Cmd+Shift+G) for ungrouping instead
  }

  /// Update visual feedback during node drag (only during Command+drag)
  void updateDragHighlight(String nodeId, bool isCommandPressed) {
    if (!isCommandPressed) {
      // Clear highlight if Command is not pressed
      if (_highlightedGroupId.value != null) {
        runInAction(() {
          _highlightedGroupId.value = null;
        });
      }
      return;
    }

    final intersectingGroup = findIntersectingGroup(nodeId);
    final newHighlightId = intersectingGroup?.id;

    if (_highlightedGroupId.value != newHighlightId) {
      runInAction(() {
        _highlightedGroupId.value = newHighlightId;
      });
    }
  }

  /// Clear drag highlight when node drag ends
  void clearDragHighlight() {
    runInAction(() {
      _highlightedGroupId.value = null;
    });
  }

  /// Check if a group is currently highlighted
  bool isGroupHighlighted(String groupId) {
    return _highlightedGroupId.value == groupId;
  }

  // @nodoc - Internal framework use only - do not use in user code
  void internalEndAnnotationDrag() {
    // Notify all selected annotations that drag is ending
    for (final id in _selectedAnnotationIds) {
      _annotations[id]?.onDragEnd();
    }

    runInAction(() {
      _draggedAnnotationId.value = null;
      _lastPointerPosition.value = null;
      _annotationCursor.value = SystemMouseCursors.basic;

      // Re-enable panning after annotation drag ends
      _parentController.interaction.panEnabled.value = true;

      // Safety reset: ensure flag is cleared when drag ends
      if (_isMovingGroupNodes) {
        _isMovingGroupNodes = false;
      }
    });
    // Note: Spatial index update is handled by MobX reaction in _setupSpatialIndexReactions()
    // which fires when draggedAnnotationId becomes null
  }

  // ============================================================
  // Widget-Level Drag Methods (no pointer position required)
  // ============================================================

  /// Starts an annotation drag from widget gesture handler.
  /// @nodoc - Internal framework use only - do not use in user code
  void internalStartAnnotationDrag(String annotationId) {
    final annotation = _annotations[annotationId];
    if (annotation?.isInteractive == true) {
      runInAction(() {
        _draggedAnnotationId.value = annotationId;
        _annotationCursor.value = SystemMouseCursors.grabbing;

        // Disable panning during annotation drag
        _parentController.interaction.panEnabled.value = false;

        // IMPORTANT: Always ensure proper selection when dragging starts
        if (!_selectedAnnotationIds.contains(annotationId)) {
          internalSelectAnnotation(annotationId);
        } else {
          _clearNodeAndConnectionSelections();
        }

        // Notify all selected annotations that drag is starting
        final context = _createDragContext();
        for (final id in _selectedAnnotationIds) {
          _annotations[id]?.onDragStart(context);
        }
      });
    }
  }

  /// Moves all selected annotations during drag (delta already in graph coordinates).
  ///
  /// Similar to node multi-select drag, when any selected annotation is dragged,
  /// all selected annotations move together.
  ///
  /// @nodoc - Internal framework use only - do not use in user code
  void internalMoveAnnotationDrag(
    Offset graphDelta,
    Map<String, Node<T>> nodes,
  ) {
    final draggedId = _draggedAnnotationId.value;
    if (draggedId == null) return;

    // Move all selected annotations, not just the dragged one
    final selectedIds = _selectedAnnotationIds.toList();
    if (selectedIds.isEmpty) return;

    final context = _createDragContext();

    runInAction(() {
      for (final annotationId in selectedIds) {
        final annotation = _annotations[annotationId];
        if (annotation != null) {
          final newPosition = annotation.position + graphDelta;
          annotation.position = newPosition;
          annotation.visualPosition = _parentController.config
              .snapAnnotationsToGridIfEnabled(newPosition);

          // Mark annotation dirty (deferred during drag)
          _parentController.internalMarkAnnotationDirty(annotationId);

          // Let the annotation handle its own drag behavior (e.g., moving contained nodes)
          annotation.onDragMove(graphDelta, context);
        }
      }
    });
  }

  // ============================================================
  // Annotation Resize Methods (Generic for any resizable annotation)
  // ============================================================

  /// Starts a resize operation for any resizable annotation.
  ///
  /// Works with any annotation that has [Annotation.isResizable] set to `true`,
  /// including [GroupAnnotation] and [StickyAnnotation].
  void startAnnotationResize(String annotationId, ResizeHandle handle) {
    final annotation = _annotations[annotationId];
    if (annotation == null || !annotation.isResizable) return;

    runInAction(() {
      _resizingAnnotationId.value = annotationId;
      _resizeHandle.value = handle;
      _resizeStartPosition = annotation.position;
      _resizeStartSize = annotation.size;

      // Disable panning during resize
      _parentController.interaction.panEnabled.value = false;

      // Set cursor override to lock cursor during resize
      _parentController.interaction.setCursorOverride(handle.cursor);
    });
  }

  /// Updates the annotation size during a resize operation.
  ///
  /// This method works with any resizable annotation by calling its [setSize] method.
  void updateAnnotationResize(Offset delta) {
    final annotationId = _resizingAnnotationId.value;
    final handle = _resizeHandle.value;
    if (annotationId == null || handle == null) return;

    final annotation = _annotations[annotationId];
    if (annotation == null || !annotation.isResizable) return;

    final startPos = _resizeStartPosition;
    final startSize = _resizeStartSize;
    if (startPos == null || startSize == null) return;

    runInAction(() {
      // Calculate new position and size based on handle being dragged
      var newX = annotation.position.dx;
      var newY = annotation.position.dy;
      var newWidth = annotation.size.width;
      var newHeight = annotation.size.height;

      switch (handle) {
        case ResizeHandle.topLeft:
          newX += delta.dx;
          newY += delta.dy;
          newWidth -= delta.dx;
          newHeight -= delta.dy;
        case ResizeHandle.topCenter:
          newY += delta.dy;
          newHeight -= delta.dy;
        case ResizeHandle.topRight:
          newY += delta.dy;
          newWidth += delta.dx;
          newHeight -= delta.dy;
        case ResizeHandle.centerLeft:
          newX += delta.dx;
          newWidth -= delta.dx;
        case ResizeHandle.centerRight:
          newWidth += delta.dx;
        case ResizeHandle.bottomLeft:
          newX += delta.dx;
          newWidth -= delta.dx;
          newHeight += delta.dy;
        case ResizeHandle.bottomCenter:
          newHeight += delta.dy;
        case ResizeHandle.bottomRight:
          newWidth += delta.dx;
          newHeight += delta.dy;
      }

      // Apply minimum size constraints (each annotation can further constrain in setSize)
      const minWidth = 100.0;
      const minHeight = 60.0;

      // If new size would be below minimum, adjust position back
      if (newWidth < minWidth) {
        if (handle == ResizeHandle.topLeft ||
            handle == ResizeHandle.centerLeft ||
            handle == ResizeHandle.bottomLeft) {
          newX = annotation.position.dx + annotation.size.width - minWidth;
        }
        newWidth = minWidth;
      }

      if (newHeight < minHeight) {
        if (handle == ResizeHandle.topLeft ||
            handle == ResizeHandle.topCenter ||
            handle == ResizeHandle.topRight) {
          newY = annotation.position.dy + annotation.size.height - minHeight;
        }
        newHeight = minHeight;
      }

      // Update position if changed
      final newPosition = Offset(newX, newY);
      if (newPosition != annotation.position) {
        annotation.position = newPosition;
        annotation.visualPosition = _parentController.config
            .snapAnnotationsToGridIfEnabled(newPosition);
      }

      // Update size - annotation's setSize handles any type-specific constraints
      annotation.setSize(Size(newWidth, newHeight));

      // Mark annotation dirty
      _parentController.internalMarkAnnotationDirty(annotationId);
    });
  }

  /// Ends an annotation resize operation.
  void endAnnotationResize() {
    runInAction(() {
      _resizingAnnotationId.value = null;
      _resizeHandle.value = null;
      _resizeStartPosition = null;
      _resizeStartSize = null;

      // Re-enable panning
      _parentController.interaction.panEnabled.value = true;

      // Clear cursor override
      _parentController.interaction.setCursorOverride(null);
    });
  }

  // ============================================================
  // Fluid Group Containment
  // ============================================================

  /// Finds all nodes that are completely contained within a group's bounds.
  ///
  /// This implements the fluid containment rule: a node is part of a group
  /// if and only if its bounding box is completely within the group's bounds.
  Set<String> findContainedNodes(GroupAnnotation group) {
    return _findNodesInBounds(group.bounds);
  }

  /// Finds all node IDs whose bounds are completely contained within the given rect.
  Set<String> _findNodesInBounds(Rect bounds) {
    final containedNodeIds = <String>{};

    for (final entry in _parentController.nodes.entries) {
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
          final node = _parentController.nodes[nodeId];
          if (node != null) {
            final newPosition = node.position.value + delta;

            // Update both position and visual position
            node.position.value = newPosition;
            final snappedPosition = _parentController.config
                .snapToGridIfEnabled(newPosition);
            node.setVisualPosition(snappedPosition);
          }
        }
      });

      // Mark nodes dirty (deferred during drag)
      _parentController.internalMarkNodesDirty(nodeIds);
    } finally {
      _isMovingGroupNodes = false;
    }
  }

  /// Creates a drag context for annotation lifecycle methods.
  AnnotationDragContext _createDragContext() {
    return AnnotationDragContext(
      moveNodes: _moveNodesByDelta,
      findNodesInBounds: _findNodesInBounds,
      getNode: (nodeId) => _parentController._nodes[nodeId],
    );
  }

  // @nodoc - Internal framework use only - do not use in user code
  Annotation? internalHitTestAnnotations(Offset point) {
    // Test in reverse z-order (highest z-index first)
    for (final annotation in sortedAnnotations.reversed) {
      if (annotation.isVisible && annotation.containsPoint(point)) {
        return annotation;
      }
    }
    return null;
  }

  // @nodoc - Internal framework use only - do not use in user code
  void internalUpdateAnnotationCursor(MouseCursor cursor) {
    _annotationCursor.value = cursor;
  }

  // Factory methods for creating common annotation types
  StickyAnnotation createStickyAnnotation({
    required String id,
    required Offset position,
    required String text,
    double width = 200.0,
    double height = 100.0,
    Color color = Colors.yellow,
  }) {
    return StickyAnnotation(
      id: id,
      position: position,
      text: text,
      width: width,
      height: height,
      color: color,
    );
  }

  /// Gets the single selected annotation, if exactly one is selected.
  ///
  /// Returns `null` if no annotations are selected or multiple are selected.
  Annotation? get selectedAnnotation {
    if (_selectedAnnotationIds.length != 1) return null;
    return _annotations[_selectedAnnotationIds.first];
  }

  /// Creates a new group annotation with the specified position and size.
  ///
  /// Groups are now manually sized and use fluid containment - any node
  /// completely within the group's bounds is considered part of the group.
  ///
  /// ## Parameters
  /// - [id]: Unique identifier for the group
  /// - [title]: Display title shown in the group header
  /// - [position]: Top-left position of the group
  /// - [size]: Width and height of the group (minimum 100x60)
  /// - [color]: Color for the group header and background tint
  GroupAnnotation createGroupAnnotation({
    required String id,
    required String title,
    required Offset position,
    required Size size,
    Color color = Colors.blue,
  }) {
    final groupAnnotation = GroupAnnotation(
      id: id,
      position: position,
      size: size,
      title: title,
      color: color,
    );

    return groupAnnotation;
  }

  /// Creates a group annotation that surrounds the specified nodes.
  ///
  /// This is a convenience method that calculates the bounding box of the
  /// given nodes and creates a group that encompasses them with padding.
  ///
  /// ## Parameters
  /// - [id]: Unique identifier for the group
  /// - [title]: Display title shown in the group header
  /// - [nodeIds]: Set of node IDs to surround
  /// - [padding]: Space between the group boundary and the nodes
  /// - [color]: Color for the group header and background tint
  GroupAnnotation createGroupAnnotationAroundNodes({
    required String id,
    required String title,
    required Set<String> nodeIds,
    EdgeInsets padding = const EdgeInsets.all(20.0),
    Color color = Colors.blue,
  }) {
    final nodes = _parentController.nodes;
    final dependentNodes = nodeIds
        .map((nodeId) => nodes[nodeId])
        .where((node) => node != null)
        .cast<Node<T>>()
        .toList();

    Offset initialPosition = Offset.zero;
    Size initialSize = const Size(200, 150);

    if (dependentNodes.isNotEmpty) {
      // Calculate bounding box of all dependent nodes
      double minX = double.infinity;
      double minY = double.infinity;
      double maxX = double.negativeInfinity;
      double maxY = double.negativeInfinity;

      for (final node in dependentNodes) {
        final pos = node.visualPosition.value;
        final size = node.size.value;

        minX = math.min(minX, pos.dx);
        minY = math.min(minY, pos.dy);
        maxX = math.max(maxX, pos.dx + size.width);
        maxY = math.max(maxY, pos.dy + size.height);
      }

      // Add padding around the nodes
      minX -= padding.left;
      minY -= padding.top;
      maxX += padding.right;
      maxY += padding.bottom;

      initialPosition = Offset(minX, minY);
      initialSize = Size(maxX - minX, maxY - minY);
    }

    return GroupAnnotation(
      id: id,
      position: initialPosition,
      size: initialSize,
      title: title,
      color: color,
    );
  }

  MarkerAnnotation createMarkerAnnotation({
    required String id,
    required Offset position,
    MarkerType markerType = MarkerType.info,
    double size = 24.0,
    Color color = Colors.red,
    String? tooltip,
  }) {
    return MarkerAnnotation(
      id: id,
      position: position,
      markerType: markerType,
      markerSize: size,
      color: color,
      tooltip: tooltip,
    );
  }

  // Setup reactive dependencies
  void _setupAnnotationReactions() {
    // Sync individual annotation selection state with centralized selection
    final disposer = reaction(
      (_) => _selectedAnnotationIds.toSet(),
      // Observe selected annotation IDs
      (selectedIds) {
        // Update individual annotation selection states
        runInAction(() {
          for (final annotation in _annotations.values) {
            final shouldBeSelected = selectedIds.contains(annotation.id);
            if (annotation.selected != shouldBeSelected) {
              annotation.selected = shouldBeSelected;
            }
          }
        });
      },
    );
    _disposers.add(disposer);

    // Global reaction for node additions/deletions
    final nodeMapDisposer = reaction(
      (_) => _parentController._nodes.keys.toSet(),
      (Set<String> currentNodeIds) {
        // Skip if we're currently moving nodes during annotation drag
        if (_isMovingGroupNodes) return;

        final context = _createDragContext();

        // Detect deleted nodes
        final deletedIds = _previousNodeIds.difference(currentNodeIds);
        if (deletedIds.isNotEmpty) {
          _notifyAnnotationsOfNodeDeletions(deletedIds, context);
        }

        // Detect added nodes
        final addedIds = currentNodeIds.difference(_previousNodeIds);
        if (addedIds.isNotEmpty) {
          _notifyAnnotationsOfNodeAdditions(addedIds, context);
        }

        _previousNodeIds = currentNodeIds;
      },
      fireImmediately: true,
    );
    _disposers.add(nodeMapDisposer);
  }

  // ============================================================
  // Node Monitoring for Annotations
  // ============================================================

  /// Sets up MobX reactions to monitor node changes for an annotation.
  /// Only called when `annotation.monitorNodes` returns `true`.
  void _setupNodeMonitoringForAnnotation(Annotation annotation) {
    final disposers = <ReactionDisposer>[];

    // Watch positions of monitored nodes
    final positionDisposer = reaction(
      (_) {
        // Observe positions of only monitored nodes
        final positions = <String, Offset>{};
        for (final nodeId in annotation.monitoredNodeIds) {
          final node = _parentController._nodes[nodeId];
          if (node != null) {
            positions[nodeId] = node.position.value;
          }
        }
        return positions;
      },
      (Map<String, Offset> positions) {
        // Skip if we're moving nodes during annotation drag
        if (_isMovingGroupNodes) return;

        final context = _createDragContext();
        for (final entry in positions.entries) {
          annotation.onNodeMoved(entry.key, entry.value, context);
        }
      },
    );
    disposers.add(positionDisposer);

    // Watch sizes of monitored nodes
    final sizeDisposer = reaction(
      (_) {
        // Observe sizes of only monitored nodes
        final sizes = <String, Size>{};
        for (final nodeId in annotation.monitoredNodeIds) {
          final node = _parentController._nodes[nodeId];
          if (node != null) {
            sizes[nodeId] = node.size.value;
          }
        }
        return sizes;
      },
      (Map<String, Size> sizes) {
        // Skip if we're moving nodes during annotation drag
        if (_isMovingGroupNodes) return;

        final context = _createDragContext();
        for (final entry in sizes.entries) {
          annotation.onNodeResized(entry.key, entry.value, context);
        }
      },
    );
    disposers.add(sizeDisposer);

    _annotationDisposers[annotation.id] = disposers;
  }

  /// Disposes MobX reactions for an annotation.
  void _disposeNodeMonitoringForAnnotation(String annotationId) {
    final disposers = _annotationDisposers.remove(annotationId);
    if (disposers != null) {
      for (final disposer in disposers) {
        disposer();
      }
    }
  }

  /// Sets up a reaction to watch for monitorNodes state changes.
  ///
  /// When the observable changes, checks [annotation.monitorNodes] and
  /// sets up or disposes node monitoring reactions accordingly.
  void _setupMonitorNodesChangeReaction(Annotation annotation) {
    final disposers = _annotationDisposers[annotation.id] ?? [];

    final monitorChangeDisposer = reaction((_) => annotation.monitorNodes, (_) {
      // Dispose existing node monitoring reactions (keep the change reaction)
      final existingDisposers = _annotationDisposers[annotation.id];
      if (existingDisposers != null && existingDisposers.length > 1) {
        // Dispose all except the last one (the change reaction itself)
        final nodeDisposers = existingDisposers.sublist(
          0,
          existingDisposers.length - 1,
        );
        for (final d in nodeDisposers) {
          d();
        }
        // Keep only the change reaction
        _annotationDisposers[annotation.id] = [existingDisposers.last];
      }

      // Set up new reactions if monitoring is now enabled
      if (annotation.monitorNodes) {
        _setupNodeMonitoringForAnnotation(annotation);
      }
    });
    disposers.add(monitorChangeDisposer);
    _annotationDisposers[annotation.id] = disposers;
  }

  // ============================================================
  // Node Lifecycle Notification Helpers
  // ============================================================

  void _notifyAnnotationsOfNodeDeletions(
    Set<String> deletedIds,
    AnnotationDragContext context,
  ) {
    final annotationsToRemove = <String>[];

    for (final annotation in _annotations.values) {
      if (annotation.monitorNodes) {
        annotation.onNodesDeleted(deletedIds, context);

        // Check if annotation wants to be removed
        if (annotation.shouldRemoveWhenEmpty && annotation.isEmpty) {
          annotationsToRemove.add(annotation.id);
        }
      }
    }

    // Remove empty annotations
    for (final annotationId in annotationsToRemove) {
      removeAnnotation(annotationId);
    }
  }

  void _notifyAnnotationsOfNodeAdditions(
    Set<String> addedIds,
    AnnotationDragContext context,
  ) {
    for (final nodeId in addedIds) {
      final node = _parentController._nodes[nodeId];
      if (node == null) continue;

      final nodeBounds = node.getBounds();
      for (final annotation in _annotations.values) {
        if (annotation.monitorNodes) {
          annotation.onNodeAdded(nodeId, nodeBounds, context);
        }
      }
    }
  }

  // Cleanup
  void dispose() {
    // Dispose global reactions
    for (final disposer in _disposers) {
      disposer();
    }
    _disposers.clear();

    // Dispose per-annotation reactions
    for (final disposers in _annotationDisposers.values) {
      for (final disposer in disposers) {
        disposer();
      }
    }
    _annotationDisposers.clear();
  }

  // Bulk operations
  void deleteSelectedAnnotations() {
    runInAction(() {
      for (final annotationId in _selectedAnnotationIds.toList()) {
        removeAnnotation(annotationId);
      }
    });
  }

  void moveSelectedAnnotations(Offset delta) {
    final movedAnnotationIds = <String>[];
    runInAction(() {
      for (final annotationId in _selectedAnnotationIds) {
        final annotation = _annotations[annotationId];
        if (annotation?.isInteractive == true) {
          final newPosition = annotation!.position + delta;
          annotation.position = newPosition;
          // Update visual position with snapping (identical to node behavior)
          annotation.visualPosition = _parentController.config
              .snapAnnotationsToGridIfEnabled(newPosition);
          movedAnnotationIds.add(annotationId);
        }
      }
    });
    // Mark moved annotations dirty
    for (final annotationId in movedAnnotationIds) {
      _parentController.internalMarkAnnotationDirty(annotationId);
    }
  }

  // Visibility management
  void setAnnotationVisibility(String annotationId, bool visible) {
    final annotation = _annotations[annotationId];
    if (annotation != null) {
      annotation.isVisible = visible;
    }
  }

  void hideAllAnnotations() {
    runInAction(() {
      for (final annotation in _annotations.values) {
        annotation.isVisible = false;
      }
    });
  }

  void showAllAnnotations() {
    runInAction(() {
      for (final annotation in _annotations.values) {
        annotation.isVisible = true;
      }
    });
  }

  // Z-index management
  void bringAnnotationToFront(String annotationId) {
    final annotation = _annotations[annotationId];
    if (annotation != null) {
      final maxZIndex = _annotations.values
          .map((a) => a.zIndex)
          .fold(0, math.max);
      annotation.zIndex = maxZIndex + 1;
    }
  }

  void sendAnnotationToBack(String annotationId) {
    final annotation = _annotations[annotationId];
    if (annotation != null) {
      final minZIndex = _annotations.values
          .map((a) => a.zIndex)
          .fold(0, math.min);
      annotation.zIndex = minZIndex - 1;
    }
  }

  void bringAnnotationForward(String annotationId) {
    final annotation = _annotations[annotationId];
    if (annotation == null) return;

    // Sort all annotations by z-index AND id to ensure consistent ordering
    final sortedAnnotations = _annotations.values.toList()
      ..sort((a, b) {
        final zComparison = a.zIndex.compareTo(b.zIndex);
        return zComparison != 0 ? zComparison : a.id.compareTo(b.id);
      });

    // Always normalize z-indexes to sequential values first
    for (int i = 0; i < sortedAnnotations.length; i++) {
      sortedAnnotations[i].zIndex = i;
    }

    // Find current annotation's position after normalization
    final currentIndex = sortedAnnotations.indexOf(annotation);

    // If not at the top, swap with next higher annotation
    if (currentIndex < sortedAnnotations.length - 1) {
      final nextAnnotation = sortedAnnotations[currentIndex + 1];
      // Simple swap of adjacent positions
      annotation.zIndex = currentIndex + 1;
      nextAnnotation.zIndex = currentIndex;
    }
  }

  void sendAnnotationBackward(String annotationId) {
    final annotation = _annotations[annotationId];
    if (annotation == null) return;

    // Sort all annotations by z-index AND id to ensure consistent ordering
    final sortedAnnotations = _annotations.values.toList()
      ..sort((a, b) {
        final zComparison = a.zIndex.compareTo(b.zIndex);
        return zComparison != 0 ? zComparison : a.id.compareTo(b.id);
      });

    // Always normalize z-indexes to sequential values first
    for (int i = 0; i < sortedAnnotations.length; i++) {
      sortedAnnotations[i].zIndex = i;
    }

    // Find current annotation's position after normalization
    final currentIndex = sortedAnnotations.indexOf(annotation);

    // If not at the bottom, swap with next lower annotation
    if (currentIndex > 0) {
      final prevAnnotation = sortedAnnotations[currentIndex - 1];
      // Simple swap of adjacent positions
      annotation.zIndex = currentIndex - 1;
      prevAnnotation.zIndex = currentIndex;
    }
  }

  /// Internal method to clear node and connection selections for unified selection
  void _clearNodeAndConnectionSelections() {
    // Clear visual selection state on nodes
    for (final id in _parentController._selectedNodeIds) {
      final node = _parentController._nodes[id];
      if (node != null) node.selected.value = false;
    }

    // Clear ID sets
    _parentController._selectedNodeIds.clear();
    _parentController._selectedConnectionIds.clear();
  }
}
