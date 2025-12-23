part of 'node_flow_controller.dart';

/// Annotation and drag operations for [NodeFlowController].
///
/// This extension provides methods for:
/// - Annotation CRUD operations
/// - Annotation factory methods
/// - Annotation selection and bulk operations
/// - Widget-level drag operations for nodes, connections, and annotations
extension NodeFlowControllerAPI<T> on NodeFlowController<T> {
  // ============================================================================
  // Annotation CRUD
  // ============================================================================

  /// Adds an annotation to the graph.
  ///
  /// Annotations are visual elements like sticky notes, markers, or group containers
  /// that provide additional context to the graph.
  ///
  /// Triggers the `onAnnotationCreated` callback after successful addition.
  ///
  /// Parameters:
  /// - `annotation`: The annotation to add
  ///
  /// See also:
  /// - `createStickyNote` for creating sticky note annotations
  /// - `createGroupAnnotation` for creating group annotations
  /// - `createMarker` for creating marker annotations
  void addAnnotation(Annotation annotation) {
    annotations.addAnnotation(annotation);
    // Fire event after successful addition
    events.annotation?.onCreated?.call(annotation);
  }

  /// Removes an annotation from the graph.
  ///
  /// Triggers the `onAnnotationDeleted` callback after successful removal.
  ///
  /// Parameters:
  /// - [annotationId]: The ID of the annotation to remove
  void removeAnnotation(String annotationId) {
    final annotationToDelete = annotations.getAnnotation(annotationId);
    annotations.removeAnnotation(annotationId);
    // Fire event after successful removal
    if (annotationToDelete != null) {
      events.annotation?.onDeleted?.call(annotationToDelete);
    }
  }

  /// Gets an annotation by its ID.
  ///
  /// Returns `null` if the annotation doesn't exist.
  ///
  /// Parameters:
  /// - [annotationId]: The ID of the annotation to retrieve
  ///
  /// Returns the annotation if found, otherwise `null`.
  Annotation? getAnnotation(String annotationId) =>
      annotations.getAnnotation(annotationId);

  // ============================================================================
  // Annotation Selection
  // ============================================================================

  /// Selects an annotation in the graph.
  ///
  /// Automatically clears selections of other element types (nodes, connections).
  /// Requests canvas focus.
  ///
  /// Triggers the `onAnnotationSelected` callback after selection changes.
  ///
  /// Parameters:
  /// - [annotationId]: The ID of the annotation to select
  /// - [toggle]: If `true`, toggles the annotation's selection state. If `false`
  ///   (default), clears other selections and selects only this annotation.
  void selectAnnotation(String annotationId, {bool toggle = false}) {
    runInAction(() {
      // Clear other element types' selections
      clearNodeSelection();
      clearConnectionSelection();
    });

    annotations.selectAnnotation(annotationId, toggle: toggle);

    // Fire selection callback with current selection state
    final selectedAnnotation = annotations.isAnnotationSelected(annotationId)
        ? annotations.getAnnotation(annotationId)
        : null;
    events.annotation?.onSelected?.call(selectedAnnotation);

    canvasFocusNode.requestFocus();
  }

  /// Clears all annotation selections.
  ///
  /// Triggers the `onAnnotationSelected` callback with `null` if there was a selection.
  void clearAnnotationSelection() {
    final hadSelection = annotations.hasAnnotationSelection;
    annotations.clearAnnotationSelection();

    // Fire selection event with null to indicate no selection
    if (hadSelection) {
      events.annotation?.onSelected?.call(null);
    }
  }

  /// Checks if an annotation is currently selected.
  ///
  /// Parameters:
  /// - [annotationId]: The ID of the annotation to check
  ///
  /// Returns `true` if the annotation is selected, otherwise `false`.
  bool isAnnotationSelected(String annotationId) =>
      annotations.isAnnotationSelected(annotationId);

  // ============================================================================
  // Annotation Factory Methods
  // ============================================================================

  /// Creates and adds a sticky note annotation to the graph.
  ///
  /// Sticky notes are floating text annotations that can be placed anywhere on the canvas.
  ///
  /// Parameters:
  /// - [position]: Position in graph coordinates
  /// - [text]: The text content of the sticky note
  /// - [id]: Optional custom ID (auto-generated if not provided)
  /// - [width]: Width of the sticky note (default: 200.0)
  /// - [height]: Height of the sticky note (default: 100.0)
  /// - [color]: Background color (default: light yellow)
  ///
  /// Returns the created [StickyAnnotation].
  ///
  /// Example:
  /// ```dart
  /// controller.createStickyNote(
  ///   position: Offset(100, 100),
  ///   text: 'Important note here',
  ///   color: Colors.yellow,
  /// );
  /// ```
  StickyAnnotation createStickyNote({
    required Offset position,
    required String text,
    String? id,
    double width = 200.0,
    double height = 100.0,
    Color color = const Color(0xFFFFF59D), // Light yellow
  }) {
    final annotation = annotations.createStickyAnnotation(
      id: id ?? 'sticky-${DateTime.now().millisecondsSinceEpoch}',
      position: position,
      text: text,
      width: width,
      height: height,
      color: color,
    );
    addAnnotation(annotation);
    return annotation;
  }

  /// Creates and adds a group annotation that visually groups multiple nodes.
  ///
  /// Group annotations automatically resize to encompass their contained nodes.
  /// They appear as colored rectangles behind the nodes with a title.
  ///
  /// Parameters:
  /// - [title]: Title displayed at the top of the group
  /// - [position]: Position in graph coordinates
  /// - [size]: Size of the group
  /// - [id]: Optional custom ID (auto-generated if not provided)
  /// - [color]: Background color of the group (default: blue)
  ///
  /// Returns the created [GroupAnnotation].
  ///
  /// Example:
  /// ```dart
  /// controller.createGroupAnnotation(
  ///   title: 'Input Processing',
  ///   position: Offset(100, 100),
  ///   size: Size(400, 300),
  ///   color: Colors.blue,
  /// );
  /// ```
  GroupAnnotation createGroupAnnotation({
    required String title,
    required Offset position,
    required Size size,
    String? id,
    Color color = const Color(0xFF2196F3), // Blue
  }) {
    final annotation = annotations.createGroupAnnotation(
      id: id ?? 'group-${DateTime.now().millisecondsSinceEpoch}',
      title: title,
      position: position,
      size: size,
      color: color,
    );
    addAnnotation(annotation);
    return annotation;
  }

  /// Creates and adds a group annotation that surrounds the specified nodes.
  ///
  /// This is a convenience method that calculates the bounding box of the
  /// given nodes and creates a group that encompasses them with padding.
  ///
  /// Parameters:
  /// - [title]: Display title for the group header
  /// - [nodeIds]: Set of node IDs to surround
  /// - [id]: Optional custom ID (auto-generated if not provided)
  /// - [padding]: Space between the group boundary and the nodes (default: 20.0)
  /// - [color]: Background color of the group (default: blue)
  ///
  /// Returns the created [GroupAnnotation].
  ///
  /// Example:
  /// ```dart
  /// controller.createGroupAnnotationAroundNodes(
  ///   title: 'Input Processing',
  ///   nodeIds: {'node1', 'node2', 'node3'},
  ///   padding: EdgeInsets.all(30),
  ///   color: Colors.blue,
  /// );
  /// ```
  GroupAnnotation createGroupAnnotationAroundNodes({
    required String title,
    required Set<String> nodeIds,
    String? id,
    EdgeInsets padding = const EdgeInsets.all(20.0),
    Color color = const Color(0xFF2196F3), // Blue
  }) {
    final annotation = annotations.createGroupAnnotationAroundNodes(
      id: id ?? 'group-${DateTime.now().millisecondsSinceEpoch}',
      title: title,
      nodeIds: nodeIds,
      padding: padding,
      color: color,
    );
    addAnnotation(annotation);
    return annotation;
  }

  /// Creates and adds a marker annotation to the graph.
  ///
  /// Markers are small icons that can be used to highlight specific locations
  /// or draw attention to important points.
  ///
  /// Parameters:
  /// - [position]: Position in graph coordinates
  /// - [markerType]: Type of marker (info, warning, error, success, etc.)
  /// - [id]: Optional custom ID (auto-generated if not provided)
  /// - [size]: Size of the marker icon (default: 24.0)
  /// - [color]: Color of the marker (default: red)
  /// - [tooltip]: Optional tooltip text shown on hover
  ///
  /// Returns the created [MarkerAnnotation].
  ///
  /// Example:
  /// ```dart
  /// controller.createMarker(
  ///   position: Offset(200, 150),
  ///   markerType: MarkerType.warning,
  ///   tooltip: 'Check this connection',
  ///   color: Colors.orange,
  /// );
  /// ```
  MarkerAnnotation createMarker({
    required Offset position,
    MarkerType markerType = MarkerType.info,
    String? id,
    double size = 24.0,
    Color color = const Color(0xFFF44336), // Red
    String? tooltip,
  }) {
    final annotation = annotations.createMarkerAnnotation(
      id: id ?? 'marker-${DateTime.now().millisecondsSinceEpoch}',
      position: position,
      markerType: markerType,
      size: size,
      color: color,
      tooltip: tooltip,
    );
    addAnnotation(annotation);
    return annotation;
  }

  // ============================================================================
  // Annotation Bulk Operations
  // ============================================================================

  /// Deletes all currently selected annotations.
  ///
  /// This is a convenience method for batch deletion.
  void deleteSelectedAnnotations() => annotations.deleteSelectedAnnotations();

  /// Hides all annotations in the graph.
  ///
  /// Hidden annotations are not rendered but remain in the graph data.
  void hideAllAnnotations() => annotations.hideAllAnnotations();

  /// Shows all annotations in the graph.
  ///
  /// This makes all previously hidden annotations visible again.
  void showAllAnnotations() => annotations.showAllAnnotations();

  // ============================================================================
  // Widget-Level Drag API
  // ============================================================================
  //
  // These methods are designed to be called directly by widgets (NodeWidget,
  // PortWidget, AnnotationWidget) to handle drag operations. This eliminates
  // callback chains and gives widgets direct controller access.

  // ---------------------------------------------------------------------------
  // Node Drag Operations
  // ---------------------------------------------------------------------------

  /// Starts a node drag operation.
  ///
  /// Call this from NodeWidget's GestureDetector.onPanStart. If the node is
  /// part of a selection, all selected nodes will be dragged together.
  ///
  /// This method:
  /// - Selects the node if not already selected
  /// - Brings the node to front (increases z-index)
  /// - Sets up drag state and cursor
  /// - Disables canvas panning during drag
  /// - Fires the drag start event
  ///
  /// Parameters:
  /// - [nodeId]: The ID of the node being dragged
  /// - [cursor]: The cursor to display during drag (optional, defaults to grabbing)
  void startNodeDrag(String nodeId, {MouseCursor? cursor}) {
    final wasSelected = selectedNodeIds.contains(nodeId);

    // Select node if not already selected
    if (!wasSelected) {
      selectNode(nodeId);
    }

    // Bring node to front
    bringNodeToFront(nodeId);

    runInAction(() {
      // Set drag state
      interaction.draggedNodeId.value = nodeId;

      // Cursor is handled by widgets via their MouseRegion

      // Disable panning during node drag
      interaction.panEnabled.value = false;

      // Update visual dragging state on all affected nodes
      // Re-check selection since we might have just selected the node
      final nodeIds = selectedNodeIds.contains(nodeId)
          ? selectedNodeIds.toList()
          : [nodeId];
      for (final id in nodeIds) {
        _nodes[id]?.dragging.value = true;
      }
    });

    // Fire drag start event
    final node = _nodes[nodeId];
    if (node != null) {
      events.node?.onDragStart?.call(node);
    }
  }

  /// Moves nodes during a drag operation.
  ///
  /// Call this from NodeWidget's GestureDetector.onPanUpdate. The delta
  /// is already in graph coordinates since GestureDetector is inside
  /// InteractiveViewer's transformed space - no conversion needed.
  ///
  /// Parameters:
  /// - [graphDelta]: The movement delta in graph coordinates
  void moveNodeDrag(Offset graphDelta) {
    final draggedNodeId = interaction.draggedNodeId.value;
    if (draggedNodeId == null) return;

    // Collect nodes that will be moved for event firing
    final movedNodes = <Node<T>>[];

    runInAction(() {
      // Update node positions and visual positions
      if (selectedNodeIds.contains(draggedNodeId)) {
        // Move all selected nodes
        for (final nodeId in selectedNodeIds) {
          final node = _nodes[nodeId];
          if (node != null) {
            final newPosition = node.position.value + graphDelta;
            node.position.value = newPosition;
            // Update visual position with snapping
            node.setVisualPosition(_config.snapToGridIfEnabled(newPosition));
            movedNodes.add(node);
          }
        }
      } else {
        // Move single node
        final node = _nodes[draggedNodeId];
        if (node != null) {
          final newPosition = node.position.value + graphDelta;
          node.position.value = newPosition;
          // Update visual position with snapping
          node.setVisualPosition(_config.snapToGridIfEnabled(newPosition));
          movedNodes.add(node);
        }
      }
    });

    // Mark moved nodes dirty for spatial index
    internalMarkNodesDirty(movedNodes.map((n) => n.id));

    // Fire drag event for all moved nodes
    for (final node in movedNodes) {
      events.node?.onDrag?.call(node);
    }
  }

  /// Ends a node drag operation.
  ///
  /// Call this from NodeWidget's GestureDetector.onPanEnd.
  void endNodeDrag() {
    // Capture dragged nodes before clearing state
    final draggedNodes = <Node<T>>[];
    final draggedNodeIds = <String>[];
    for (final node in _nodes.values) {
      if (node.dragging.value) {
        draggedNodes.add(node);
        draggedNodeIds.add(node.id);
      }
    }

    runInAction(() {
      // Clear dragging state on nodes
      for (final node in draggedNodes) {
        node.dragging.value = false;
      }

      // Clear drag state
      interaction.draggedNodeId.value = null;
      interaction.lastPointerPosition.value = null;

      // Re-enable panning after node drag ends
      interaction.panEnabled.value = true;
    });

    // Rebuild connection segments with accurate path bounds after drag ends
    if (draggedNodeIds.isNotEmpty) {
      rebuildConnectionSegmentsForNodes(draggedNodeIds);
    }

    // Fire drag stop event for all dragged nodes
    for (final node in draggedNodes) {
      events.node?.onDragStop?.call(node);
    }
  }

  // ---------------------------------------------------------------------------
  // Annotation Drag Operations
  // ---------------------------------------------------------------------------

  /// Starts an annotation drag operation.
  ///
  /// Call this from AnnotationWidget's GestureDetector.onPanStart.
  /// Pan is disabled by the editor's pointer down handler before gesture arena runs.
  ///
  /// Parameters:
  /// - [annotationId]: The ID of the annotation being dragged
  void startAnnotationDrag(String annotationId) {
    annotations.internalStartAnnotationDrag(annotationId);
  }

  /// Moves an annotation during a drag operation.
  ///
  /// Call this from AnnotationWidget's GestureDetector.onPanUpdate. The delta
  /// is already in graph coordinates since GestureDetector is inside
  /// InteractiveViewer's transformed space - no conversion needed.
  ///
  /// Parameters:
  /// - [graphDelta]: The movement delta in graph coordinates
  void moveAnnotationDrag(Offset graphDelta) {
    annotations.internalMoveAnnotationDrag(graphDelta, _nodes);
  }

  /// Ends an annotation drag operation.
  ///
  /// Call this from AnnotationWidget's GestureDetector.onPanEnd.
  /// Pan is re-enabled by the editor's _updatePanState reaction when drag state clears.
  void endAnnotationDrag() {
    annotations.internalEndAnnotationDrag();
  }
}
