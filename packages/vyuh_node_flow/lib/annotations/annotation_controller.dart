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

  // Reaction disposers for cleanup
  final List<ReactionDisposer> _disposers = [];

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

  // Computed sorted annotations by z-index
  late final Computed<List<Annotation>> _sortedAnnotations = Computed(() {
    final annotationsList = _annotations.values.toList();

    // Trigger observation of all zIndex values for existing annotations
    for (final annotation in annotationsList) {
      annotation.zIndex.value; // Observe zIndex changes
    }

    // Sort by zIndex ascending (lower zIndex = rendered first = behind)
    annotationsList.sort((a, b) => a.zIndex.value.compareTo(b.zIndex.value));

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
      if (annotation.zIndex.value == -1) {
        // Find the current maximum z-index and add 1
        if (_annotations.length > 1) {
          final existingAnnotations = _annotations.values
              .where((a) => a.id != annotation.id)
              .toList();
          final maxZIndex = existingAnnotations
              .map((a) => a.zIndex.value)
              .fold(-1, math.max);
          annotation.setZIndex(maxZIndex + 1);
        } else {
          // First annotation gets z-index 0
          annotation.setZIndex(0);
        }
      }

      // Initialize visual position with snapping (identical to node behavior)
      annotation.setVisualPosition(
        _parentController.config.snapAnnotationsToGridIfEnabled(
          annotation.currentPosition,
        ),
      );

      // If this is a group annotation with dependencies, calculate initial bounds
      if (annotation is GroupAnnotation && annotation.hasAnyDependencies) {
        final dependentNodes = annotation.dependencies
            .map((nodeId) => _parentController.nodes[nodeId])
            .where((node) => node != null)
            .cast<Node<T>>()
            .toList();

        if (dependentNodes.isNotEmpty) {
          _updateGroupAnnotation(annotation, dependentNodes);
        }
      }
    });
  }

  void removeAnnotation(String annotationId) {
    runInAction(() {
      _annotations.remove(annotationId);
      _selectedAnnotationIds.remove(annotationId);

      // Remove from spatial index
      _parentController._spatialIndex.removeAnnotation(annotationId);

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
            annotation.setSelected(false);
          }
        } else {
          _selectedAnnotationIds.add(annotationId);
          final annotation = _annotations[annotationId];
          if (annotation != null) {
            annotation.setSelected(true);
          }
          // Note: Removed auto-bring-to-front to allow manual z-index management
        }
      } else {
        // Clear previous annotation selections
        for (final id in _selectedAnnotationIds) {
          final annotation = _annotations[id];
          if (annotation != null) {
            annotation.setSelected(false);
          }
        }

        _selectedAnnotationIds.clear();
        _selectedAnnotationIds.add(annotationId);

        final annotation = _annotations[annotationId];
        if (annotation != null) {
          annotation.setSelected(true);
        }

        // IMPORTANT: Clear nodes and connections when selecting annotation (unified selection)
        _clearNodeAndConnectionSelections();

        // NOTE: Auto-bring-to-front removed to preserve manual z-index management
        // Previously would set annotation.setZIndex(_annotations.length) here
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
          annotation.setSelected(false);
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
          annotation.currentIsVisible &&
          !annotation.dependencies.contains(nodeId)) {
        final groupRect = Rect.fromLTWH(
          annotation.visualPosition.value.dx,
          annotation.visualPosition.value.dy,
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
      if (!intersectingGroup.dependencies.contains(nodeId)) {
        addNodeDependency(intersectingGroup.id, nodeId);
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

  void _moveGroupDependentNodes(
    GroupAnnotation groupAnnotation,
    Offset delta,
    Map<String, Node<T>> nodes,
  ) {
    // Check if already moving to prevent nested calls
    if (_isMovingGroupNodes) {
      return;
    }

    // Temporarily disable group updates to prevent cycles
    _isMovingGroupNodes = true;

    try {
      // Use runInAction to ensure proper MobX batching
      runInAction(() {
        for (final nodeId in groupAnnotation.dependencies) {
          final node = nodes[nodeId];
          if (node != null) {
            final newPosition = node.position.value + delta;

            // Update both position and visual position (like regular node drag)
            node.position.value = newPosition;
            final snappedPosition = _parentController.config
                .snapToGridIfEnabled(newPosition);
            node.setVisualPosition(snappedPosition);
          }
        }
      });

      // Mark dependent nodes dirty (deferred during annotation drag)
      _parentController.internalMarkNodesDirty(groupAnnotation.dependencies);
    } catch (e) {
      // Force reset flag in error case
      _isMovingGroupNodes = false;
      rethrow; // Re-throw to maintain error propagation
    } finally {
      _isMovingGroupNodes = false;
    }
  }

  // @nodoc - Internal framework use only - do not use in user code
  void internalEndAnnotationDrag() {
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
      });
    }
  }

  /// Moves annotation during drag (delta already in graph coordinates).
  /// @nodoc - Internal framework use only - do not use in user code
  void internalMoveAnnotationDrag(
    Offset graphDelta,
    Map<String, Node<T>> nodes,
  ) {
    final draggedId = _draggedAnnotationId.value;
    if (draggedId == null) return;

    runInAction(() {
      final annotation = _annotations[draggedId];
      if (annotation != null) {
        final newPosition = annotation.currentPosition + graphDelta;
        annotation.setPosition(newPosition);
        annotation.setVisualPosition(
          _parentController.config.snapAnnotationsToGridIfEnabled(newPosition),
        );

        // Mark annotation dirty (deferred during drag)
        _parentController.internalMarkAnnotationDirty(draggedId);

        // If this is a group annotation, move all dependent nodes
        if (annotation is GroupAnnotation && annotation.hasAnyDependencies) {
          _moveGroupDependentNodes(annotation, graphDelta, nodes);
        }
      }
    });
  }

  // Dependency management
  void addNodeDependency(
    String annotationId,
    String nodeId, {
    AnnotationBehavior type = AnnotationBehavior.follow,
  }) {
    final annotation = _annotations[annotationId];
    if (annotation != null) {
      annotation.addDependency(nodeId);

      // If this is a group, update its bounds immediately
      if (annotation is GroupAnnotation) {
        final dependentNodes = annotation.dependencies
            .map((id) => _parentController.nodes[id])
            .where((node) => node != null)
            .cast<Node<T>>()
            .toList();

        if (dependentNodes.isNotEmpty) {
          _updateGroupAnnotation(annotation, dependentNodes);
        }
      }
    }
  }

  void removeNodeDependency(String annotationId, String nodeId) {
    final annotation = _annotations[annotationId];
    if (annotation != null) {
      annotation.removeDependency(nodeId);

      // If this is a group, update its bounds immediately
      if (annotation is GroupAnnotation) {
        final dependentNodes = annotation.dependencies
            .map((id) => _parentController.nodes[id])
            .where((node) => node != null)
            .cast<Node<T>>()
            .toList();

        if (dependentNodes.isNotEmpty) {
          _updateGroupAnnotation(annotation, dependentNodes);
        }
      }
    }
  }

  void clearNodeDependencies(String annotationId) {
    final annotation = _annotations[annotationId];
    if (annotation != null) {
      annotation.clearDependencies();
    }
  }

  // Get annotations that depend on a specific node
  List<Annotation> getAnnotationsDependingOnNode(String nodeId) {
    return _annotations.values
        .where((annotation) => annotation.hasDependency(nodeId))
        .toList();
  }

  // @nodoc - Internal framework use only - do not use in user code
  void internalUpdateDependentAnnotations(Map<String, Node<T>> nodes) {
    // Skip updates if we're currently moving group nodes to prevent cycles
    if (_isMovingGroupNodes) {
      return;
    }

    for (final annotation in _annotations.values) {
      if (annotation.hasAnyDependencies) {
        _updateAnnotationForDependencies(annotation, nodes);
      }
    }
  }

  void _updateAnnotationForDependencies(
    Annotation annotation,
    Map<String, Node<T>> nodes,
  ) {
    final dependentNodes = annotation.dependencies
        .map((nodeId) => nodes[nodeId])
        .where((node) => node != null)
        .cast<Node<T>>()
        .toList();

    if (dependentNodes.isEmpty) return;

    if (annotation is GroupAnnotation) {
      _updateGroupAnnotation(annotation, dependentNodes);
    } else {
      // For other annotation types, follow the center of dependent nodes
      _updateFollowingAnnotation(annotation, dependentNodes);
    }
  }

  void _updateGroupAnnotation(
    GroupAnnotation groupAnnotation,
    List<Node<T>> dependentNodes,
  ) {
    if (dependentNodes.isEmpty) return;

    // Calculate bounding box of all dependent nodes
    double minX = double.infinity;
    double minY = double.infinity;
    double maxX = double.negativeInfinity;
    double maxY = double.negativeInfinity;

    for (final node in dependentNodes) {
      // Use visual position (what's actually rendered) not logical position!
      final pos = node.visualPosition.value;
      final size = node.size.value;

      minX = math.min(minX, pos.dx);
      minY = math.min(minY, pos.dy);
      maxX = math.max(maxX, pos.dx + size.width);
      maxY = math.max(maxY, pos.dy + size.height);
    }

    // Add padding around the nodes
    final padding = groupAnnotation.padding;
    minX -= padding.left;
    minY -= padding.top;
    maxX += padding.right;
    maxY += padding.bottom;

    final newPosition = Offset(minX, minY);
    final newSize = Size(maxX - minX, maxY - minY);

    // Only update if there's a meaningful change to avoid unnecessary updates
    final currentPosition = groupAnnotation.currentPosition;
    final currentSize = groupAnnotation.size;

    const tolerance = 0.1; // Pixel tolerance
    if ((newPosition - currentPosition).distance > tolerance ||
        (newSize.width - currentSize.width).abs() > tolerance ||
        (newSize.height - currentSize.height).abs() > tolerance) {
      // Update group annotation position and size
      runInAction(() {
        groupAnnotation.setPosition(newPosition);
        // Update visual position with snapping (must match node behavior!)
        groupAnnotation.setVisualPosition(
          _parentController.config.snapAnnotationsToGridIfEnabled(newPosition),
        );
        groupAnnotation.updateCalculatedSize(newSize);
      });
      // Mark annotation dirty
      _parentController.internalMarkAnnotationDirty(groupAnnotation.id);
    }
  }

  void _updateFollowingAnnotation(
    Annotation annotation,
    List<Node<T>> dependentNodes,
  ) {
    // Calculate center point of dependent nodes
    double totalX = 0;
    double totalY = 0;
    int count = 0;

    for (final node in dependentNodes) {
      // Use visual position (what's actually rendered) not logical position!
      final pos = node.visualPosition.value;
      final size = node.size.value;
      totalX += pos.dx + size.width / 2;
      totalY += pos.dy + size.height / 2;
      count++;
    }

    if (count > 0) {
      final centerX = totalX / count;
      final centerY = totalY / count;

      // Position annotation relative to center, accounting for its own size and offset
      final annotationCenterOffset = Offset(
        centerX - annotation.size.width / 2 + annotation.offset.dx,
        centerY - annotation.size.height / 2 + annotation.offset.dy,
      );

      annotation.setPosition(annotationCenterOffset);
      // Update visual position with snapping (must match node behavior!)
      annotation.setVisualPosition(
        _parentController.config.snapAnnotationsToGridIfEnabled(
          annotationCenterOffset,
        ),
      );
      // Mark annotation dirty
      _parentController.internalMarkAnnotationDirty(annotation.id);
    }
  }

  // @nodoc - Internal framework use only - do not use in user code
  Annotation? internalHitTestAnnotations(Offset point) {
    // Test in reverse z-order (highest z-index first)
    for (final annotation in sortedAnnotations.reversed) {
      if (annotation.currentIsVisible && annotation.containsPoint(point)) {
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
    Offset offset = Offset.zero,
  }) {
    // Create annotation with actual position (same as nodes)
    final annotation = StickyAnnotation(
      id: id,
      position: position,
      text: text,
      width: width,
      height: height,
      color: color,
      offset: offset,
    );

    return annotation;
  }

  GroupAnnotation createGroupAnnotation({
    required String id,
    required String title,
    required Set<String> nodeIds,
    required Map<String, Node<T>> nodes,
    EdgeInsets padding = const EdgeInsets.all(20.0),
    Color color = Colors.blue,
  }) {
    // Calculate initial position and size based on dependent nodes
    final dependentNodes = nodeIds
        .map((nodeId) => nodes[nodeId])
        .where((node) => node != null)
        .cast<Node<T>>()
        .toList();

    Offset initialPosition = Offset.zero;
    Size initialSize = const Size(100, 100);

    if (dependentNodes.isNotEmpty) {
      // Calculate bounding box of all dependent nodes
      double minX = double.infinity;
      double minY = double.infinity;
      double maxX = double.negativeInfinity;
      double maxY = double.negativeInfinity;

      for (final node in dependentNodes) {
        // Use visual position (what's actually rendered) not logical position!
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

    final groupAnnotation = GroupAnnotation(
      id: id,
      position: initialPosition,
      title: title,
      padding: padding,
      color: color,
      dependencies: nodeIds,
    );

    // Set the initial calculated size
    groupAnnotation.updateCalculatedSize(initialSize);

    return groupAnnotation;
  }

  MarkerAnnotation createMarkerAnnotation({
    required String id,
    required Offset position,
    MarkerType markerType = MarkerType.info,
    double size = 24.0,
    Color color = Colors.red,
    String? tooltip,
    Offset offset = Offset.zero,
  }) {
    // Create annotation with actual position (same as nodes)
    final annotation = MarkerAnnotation(
      id: id,
      position: position,
      markerType: markerType,
      markerSize: size,
      color: color,
      tooltip: tooltip,
      offset: offset,
    );

    return annotation;
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
            if (annotation.currentSelected != shouldBeSelected) {
              annotation.setSelected(shouldBeSelected);
            }
          }
        });
      },
    );
    _disposers.add(disposer);

    // Auto-update group annotations when nodes change
    final nodeUpdateDisposer = reaction(
      (_) {
        // Observe all node positions and sizes for groups
        final nodePositions = <String, Offset>{};
        final nodeSizes = <String, Size>{};

        for (final annotation in _annotations.values) {
          if (annotation is GroupAnnotation && annotation.hasAnyDependencies) {
            for (final nodeId in annotation.dependencies) {
              final node = _parentController.nodes[nodeId];
              if (node != null) {
                nodePositions[nodeId] = node.visualPosition.value;
                nodeSizes[nodeId] = node.size.value;
              }
            }
          }
        }

        return {'positions': nodePositions, 'sizes': nodeSizes};
      },
      (_) {
        // Update all group annotations
        for (final annotation in _annotations.values) {
          if (annotation is GroupAnnotation && annotation.hasAnyDependencies) {
            final dependentNodes = annotation.dependencies
                .map((id) => _parentController.nodes[id])
                .where((node) => node != null)
                .cast<Node<T>>()
                .toList();

            if (dependentNodes.isNotEmpty) {
              _updateGroupAnnotation(annotation, dependentNodes);
            }
          }
        }
      },
    );
    _disposers.add(nodeUpdateDisposer);
  }

  // Cleanup
  void dispose() {
    for (final disposer in _disposers) {
      disposer();
    }
    _disposers.clear();
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
          final newPosition = annotation!.currentPosition + delta;
          annotation.setPosition(newPosition);
          // Update visual position with snapping (identical to node behavior)
          annotation.setVisualPosition(
            _parentController.config.snapAnnotationsToGridIfEnabled(
              newPosition,
            ),
          );
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
      annotation.setVisible(visible);
    }
  }

  void hideAllAnnotations() {
    runInAction(() {
      for (final annotation in _annotations.values) {
        annotation.setVisible(false);
      }
    });
  }

  void showAllAnnotations() {
    runInAction(() {
      for (final annotation in _annotations.values) {
        annotation.setVisible(true);
      }
    });
  }

  // Z-index management
  void bringAnnotationToFront(String annotationId) {
    final annotation = _annotations[annotationId];
    if (annotation != null) {
      final maxZIndex = _annotations.values
          .map((a) => a.zIndex.value)
          .fold(0, math.max);
      annotation.setZIndex(maxZIndex + 1);
    }
  }

  void sendAnnotationToBack(String annotationId) {
    final annotation = _annotations[annotationId];
    if (annotation != null) {
      final minZIndex = _annotations.values
          .map((a) => a.zIndex.value)
          .fold(0, math.min);
      annotation.setZIndex(minZIndex - 1);
    }
  }

  void bringAnnotationForward(String annotationId) {
    final annotation = _annotations[annotationId];
    if (annotation == null) return;

    // Sort all annotations by z-index AND id to ensure consistent ordering
    final sortedAnnotations = _annotations.values.toList()
      ..sort((a, b) {
        final zComparison = a.zIndex.value.compareTo(b.zIndex.value);
        return zComparison != 0 ? zComparison : a.id.compareTo(b.id);
      });

    // Always normalize z-indexes to sequential values first
    for (int i = 0; i < sortedAnnotations.length; i++) {
      sortedAnnotations[i].setZIndex(i);
    }

    // Find current annotation's position after normalization
    final currentIndex = sortedAnnotations.indexOf(annotation);

    // If not at the top, swap with next higher annotation
    if (currentIndex < sortedAnnotations.length - 1) {
      final nextAnnotation = sortedAnnotations[currentIndex + 1];
      // Simple swap of adjacent positions
      annotation.setZIndex(currentIndex + 1);
      nextAnnotation.setZIndex(currentIndex);
    }
  }

  void sendAnnotationBackward(String annotationId) {
    final annotation = _annotations[annotationId];
    if (annotation == null) return;

    // Sort all annotations by z-index AND id to ensure consistent ordering
    final sortedAnnotations = _annotations.values.toList()
      ..sort((a, b) {
        final zComparison = a.zIndex.value.compareTo(b.zIndex.value);
        return zComparison != 0 ? zComparison : a.id.compareTo(b.id);
      });

    // Always normalize z-indexes to sequential values first
    for (int i = 0; i < sortedAnnotations.length; i++) {
      sortedAnnotations[i].setZIndex(i);
    }

    // Find current annotation's position after normalization
    final currentIndex = sortedAnnotations.indexOf(annotation);

    // If not at the bottom, swap with next lower annotation
    if (currentIndex > 0) {
      final prevAnnotation = sortedAnnotations[currentIndex - 1];
      // Simple swap of adjacent positions
      annotation.setZIndex(currentIndex - 1);
      prevAnnotation.setZIndex(currentIndex);
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
