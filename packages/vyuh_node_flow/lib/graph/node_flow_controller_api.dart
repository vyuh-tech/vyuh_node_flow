part of 'node_flow_controller.dart';

extension NodeFlowControllerAPI<T> on NodeFlowController<T> {
  // Graph loading with annotation support

  /// Loads a complete graph into the controller.
  ///
  /// This method:
  /// 1. Clears the existing graph state
  /// 2. Bulk loads all nodes, connections, and annotations
  /// 3. Sets the viewport to match the saved state
  /// 4. Sets up visual positioning and hit-testing infrastructure
  ///
  /// This is the preferred method for loading saved graphs as it performs
  /// efficient bulk loading rather than individual additions.
  ///
  /// Parameters:
  /// - `graph`: The graph to load containing nodes, connections, annotations, and viewport state
  ///
  /// Example:
  /// ```dart
  /// final graph = NodeGraph<MyData>(
  ///   nodes: savedNodes,
  ///   connections: savedConnections,
  ///   annotations: savedAnnotations,
  ///   viewport: savedViewport,
  /// );
  /// controller.loadGraph(graph);
  /// ```
  void loadGraph(NodeGraph<T> graph) {
    runInAction(() {
      // Clear existing state
      clearGraph();

      // Bulk load all data structures without infrastructure setup
      for (final node in graph.nodes) {
        _nodes[node.id] = node;
      }
      _connections.addAll(graph.connections);
      for (final annotation in graph.annotations) {
        annotations.annotations[annotation.id] = annotation;
      }

      // Set viewport
      _viewport.value = graph.viewport;

      // Single infrastructure setup call after bulk loading
      _setupLoadedGraphInfrastructure();
    });
  }

  /// Sets up all necessary infrastructure after bulk loading graph data
  /// This includes visual positioning, hit-testing setup, and other post-load configuration
  void _setupLoadedGraphInfrastructure() {
    // Setup node visual positions with snapping
    for (final node in _nodes.values) {
      node.setVisualPosition(_config.snapToGridIfEnabled(node.position.value));
    }

    // Rebuild spatial indexes for hit testing
    _spatialIndex.rebuildFromNodes(_nodes.values);
    _spatialIndex.rebuildConnections(
      _connections,
      (connection) => _calculateConnectionBounds(connection) ?? Rect.zero,
    );
    _spatialIndex.rebuildFromAnnotations(annotations.annotations.values);
  }

  // Export graph with annotations

  /// Exports the current graph state including all nodes, connections, annotations, and viewport.
  ///
  /// This creates a snapshot of the entire graph that can be serialized and saved.
  /// Use `loadGraph` to restore the graph from the exported data.
  ///
  /// Returns a [NodeGraph] containing all current graph data.
  ///
  /// Example:
  /// ```dart
  /// // Export the graph
  /// final graph = controller.exportGraph();
  ///
  /// // Save to JSON
  /// final json = graph.toJson();
  /// ```
  NodeGraph<T> exportGraph() {
    return NodeGraph<T>(
      nodes: _nodes.values.toList(),
      connections: _connections,
      annotations: annotations.sortedAnnotations,
      viewport: _viewport.value,
    );
  }

  // Viewport operations

  /// Sets the viewport to a specific position and zoom level.
  ///
  /// This method provides immediate viewport updates for real-time panning responsiveness.
  ///
  /// Parameters:
  /// - [viewport]: The new viewport state with x, y position and zoom level
  ///
  /// Example:
  /// ```dart
  /// controller.setViewport(GraphViewport(x: 100, y: 50, zoom: 1.5));
  /// ```
  void setViewport(GraphViewport viewport) {
    // Immediate viewport updates for real-time panning responsiveness
    runInAction(() {
      _viewport.value = viewport;
    });
  }

  /// Sets the screen size used for viewport calculations.
  ///
  /// This is typically called internally by the editor widget when the layout changes.
  /// You generally should not call this manually.
  ///
  /// Parameters:
  /// - [size]: The new screen size
  void setScreenSize(Size size) {
    runInAction(() {
      _screenSize.value = size;
    });
  }

  /// Converts a global screen position to graph coordinates.
  ///
  /// This method handles the full conversion from global screen coordinates
  /// (e.g., from gesture events) to graph coordinates, accounting for:
  /// - Canvas position on screen (via canvasKey's RenderBox)
  /// - Viewport pan offset
  /// - Viewport zoom level
  ///
  /// Use this method when you have a global position (like `details.globalPosition`
  /// from a gesture callback) and need to convert it to graph coordinates.
  ///
  /// Parameters:
  /// - [globalPosition]: Position in global screen coordinates
  ///
  /// Returns: The corresponding position in graph coordinates
  Offset globalToGraph(Offset globalPosition) {
    // Convert global to canvas-local using the canvas's RenderBox
    final renderBox =
        canvasKey.currentContext?.findRenderObject() as RenderBox?;
    final canvasLocal =
        renderBox?.globalToLocal(globalPosition) ?? globalPosition;
    // Then convert canvas-local to graph coordinates
    return viewport.screenToGraph(canvasLocal);
  }

  /// Gets the current mouse position in world coordinates.
  ///
  /// Returns `null` if the mouse is outside the canvas area.
  /// This is useful for debug visualization and features that need cursor tracking.
  Offset? get mousePositionWorld => _mousePositionWorld.value;

  /// Updates the mouse position in world coordinates.
  ///
  /// This is typically called internally by the editor widget during mouse hover.
  /// Pass `null` when the mouse exits the canvas.
  ///
  /// Parameters:
  /// - [position]: The mouse position in world coordinates, or `null` if outside canvas
  void setMousePositionWorld(Offset? position) {
    runInAction(() {
      _mousePositionWorld.value = position;
    });
  }

  /// Zoom the viewport by a delta value while maintaining the viewport center as the focal point.
  ///
  /// The zoom level is clamped to the min/max zoom values configured in `NodeFlowConfig`.
  /// The viewport automatically adjusts to keep the center point fixed during zoom.
  ///
  /// Parameters:
  /// - [delta]: The amount to change the zoom by (positive to zoom in, negative to zoom out)
  ///
  /// Example:
  /// ```dart
  /// controller.zoomBy(0.1); // Zoom in by 10%
  /// controller.zoomBy(-0.1); // Zoom out by 10%
  /// ```
  void zoomBy(double delta) {
    final currentVp = _viewport.value;
    final newZoom = (currentVp.zoom + delta).clamp(
      _config.minZoom.value,
      _config.maxZoom.value,
    );

    if (newZoom == currentVp.zoom) return; // No change needed

    final size = _screenSize.value;

    // Calculate the current viewport center in world coordinates
    final viewportCenterScreen = Offset(size.width / 2, size.height / 2);
    final viewportCenterWorld = screenToWorld(viewportCenterScreen);

    // After zoom, we want this world point to remain at the same screen position
    // Calculate the new pan position to keep the center point fixed
    final newPanX =
        viewportCenterScreen.dx - (viewportCenterWorld.dx * newZoom);
    final newPanY =
        viewportCenterScreen.dy - (viewportCenterWorld.dy * newZoom);

    setViewport(GraphViewport(x: newPanX, y: newPanY, zoom: newZoom));
  }

  /// Pans the viewport by a delta offset.
  ///
  /// Parameters:
  /// - [delta]: The offset to pan the viewport by
  ///
  /// Example:
  /// ```dart
  /// controller.panBy(Offset(50, 0)); // Pan right by 50 pixels
  /// controller.panBy(Offset(0, -50)); // Pan up by 50 pixels
  /// ```
  void panBy(Offset delta) {
    runInAction(() {
      _viewport.value = _viewport.value.copyWith(
        x: _viewport.value.x + delta.dx,
        y: _viewport.value.y + delta.dy,
      );
    });
  }

  // Internal methods moved to main controller class

  // Query methods

  /// Gets a node by its ID.
  ///
  /// Returns `null` if the node doesn't exist.
  ///
  /// Parameters:
  /// - [nodeId]: The ID of the node to retrieve
  ///
  /// Returns the node if found, otherwise `null`.
  Node<T>? getNode(String nodeId) => _nodes[nodeId];

  /// Checks if a node is currently selected.
  ///
  /// Parameters:
  /// - [nodeId]: The ID of the node to check
  ///
  /// Returns `true` if the node is selected, otherwise `false`.
  bool isNodeSelected(String nodeId) => _selectedNodeIds.contains(nodeId);

  // Annotation methods

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

  // Public API for selecting annotations

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

  // Annotation factory methods for convenience

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
  /// - [offset]: Optional offset for positioning (default: Offset.zero)
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
  /// - [nodeIds]: Set of node IDs to include in the group
  /// - [id]: Optional custom ID (auto-generated if not provided)
  /// - [padding]: Padding around the grouped nodes (default: 20.0 on all sides)
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
  /// - [offset]: Optional offset for positioning (default: Offset.zero)
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

  // Annotation bulk operations

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

  // Viewport extent methods

  /// Gets the viewport extent as a Rect in world coordinates.
  ///
  /// This represents the visible area of the graph in world space. Use this
  /// to determine which nodes or elements are currently visible.
  ///
  /// Returns a [Rect] representing the visible portion of the graph in world coordinates.
  Rect get viewportExtent {
    final vp = _viewport.value;
    final size = _screenSize.value;

    // Convert screen bounds to world coordinates
    final left = -vp.x / vp.zoom;
    final top = -vp.y / vp.zoom;
    final right = (size.width - vp.x) / vp.zoom;
    final bottom = (size.height - vp.y) / vp.zoom;

    return Rect.fromLTRB(left, top, right, bottom);
  }

  /// Gets the viewport extent as a Rect in screen coordinates.
  ///
  /// This represents the screen area that displays the graph. Typically this
  /// is the full size of the canvas/widget.
  ///
  /// Returns a [Rect] representing the screen bounds of the viewport.
  Rect get viewportScreenBounds {
    final size = _screenSize.value;
    return Rect.fromLTWH(0, 0, size.width, size.height);
  }

  /// Converts a world coordinate point to screen coordinates.
  ///
  /// Use this to transform positions in graph space to screen space, taking into
  /// account the current viewport position and zoom level.
  ///
  /// Parameters:
  /// - [worldPoint]: The point in world/graph coordinates
  ///
  /// Returns the corresponding point in screen coordinates.
  ///
  /// Example:
  /// ```dart
  /// final nodePos = Offset(100, 100); // Position in graph
  /// final screenPos = controller.worldToScreen(nodePos); // Position on screen
  /// ```
  Offset worldToScreen(Offset worldPoint) {
    final vp = _viewport.value;
    return Offset(
      worldPoint.dx * vp.zoom + vp.x,
      worldPoint.dy * vp.zoom + vp.y,
    );
  }

  /// Converts a screen coordinate point to world coordinates.
  ///
  /// Use this to transform mouse/touch positions or screen coordinates back to
  /// graph space, taking into account the current viewport position and zoom level.
  ///
  /// Parameters:
  /// - [screenPoint]: The point in screen coordinates
  ///
  /// Returns the corresponding point in world/graph coordinates.
  ///
  /// Example:
  /// ```dart
  /// final mousePos = event.localPosition; // Mouse position on screen
  /// final graphPos = controller.screenToWorld(mousePos); // Position in graph
  /// ```
  Offset screenToWorld(Offset screenPoint) {
    final vp = _viewport.value;
    return Offset(
      (screenPoint.dx - vp.x) / vp.zoom,
      (screenPoint.dy - vp.y) / vp.zoom,
    );
  }

  /// Checks if a world coordinate point is visible in the current viewport.
  ///
  /// Parameters:
  /// - [worldPoint]: The point to check in world/graph coordinates
  ///
  /// Returns `true` if the point is within the visible viewport, `false` otherwise.
  bool isPointVisible(Offset worldPoint) {
    return viewportExtent.contains(worldPoint);
  }

  /// Checks if a world coordinate rectangle intersects with the viewport.
  ///
  /// Use this for visibility culling to determine if a node or element should be rendered.
  ///
  /// Parameters:
  /// - [worldRect]: The rectangle to check in world/graph coordinates
  ///
  /// Returns `true` if any part of the rectangle overlaps the viewport, `false` otherwise.
  bool isRectVisible(Rect worldRect) {
    return viewportExtent.overlaps(worldRect);
  }

  /// Gets the bounding rectangle that encompasses all selected nodes in world coordinates.
  ///
  /// Returns `null` if no nodes are selected.
  ///
  /// This is useful for operations like "fit selected nodes to view" or calculating
  /// the area occupied by the selection.
  ///
  /// Returns a [Rect] containing all selected nodes, or `null` if nothing is selected.
  Rect? get selectedNodesBounds {
    if (_selectedNodeIds.isEmpty) return null;

    final selectedNodes = _selectedNodeIds
        .map((id) => _nodes[id])
        .where((node) => node != null)
        .cast<Node<T>>();

    return _calculateNodesBounds(selectedNodes);
  }

  /// Helper method to calculate bounds for a collection of nodes
  Rect? _calculateNodesBounds(Iterable<Node<T>> nodes) {
    if (nodes.isEmpty) return null;

    double minX = double.infinity;
    double minY = double.infinity;
    double maxX = double.negativeInfinity;
    double maxY = double.negativeInfinity;

    for (final node in nodes) {
      final pos = node.position.value;
      final size = node.size.value;
      minX = minX < pos.dx ? minX : pos.dx;
      minY = minY < pos.dy ? minY : pos.dy;
      maxX = maxX > pos.dx + size.width ? maxX : pos.dx + size.width;
      maxY = maxY > pos.dy + size.height ? maxY : pos.dy + size.height;
    }

    return minX != double.infinity
        ? Rect.fromLTRB(minX, minY, maxX, maxY)
        : null;
  }

  // High-level viewport control methods

  /// Sets the viewport zoom to a specific value.
  ///
  /// The zoom is clamped to the min/max zoom values configured in `NodeFlowConfig`.
  /// Unlike `zoomBy`, this sets an absolute zoom level rather than a relative change.
  ///
  /// Parameters:
  /// - [zoom]: The target zoom level (1.0 = 100%, 2.0 = 200%, etc.)
  ///
  /// Example:
  /// ```dart
  /// controller.zoomTo(1.5); // Set zoom to 150%
  /// controller.zoomTo(1.0); // Reset zoom to 100%
  /// ```
  void zoomTo(double zoom) {
    final clampedZoom = zoom.clamp(
      _config.minZoom.value,
      _config.maxZoom.value,
    );
    final currentVp = _viewport.value;
    setViewport(
      GraphViewport(x: currentVp.x, y: currentVp.y, zoom: clampedZoom),
    );
  }

  /// Adjusts the viewport to fit all nodes in the view with padding.
  ///
  /// Calculates the optimal zoom level and pan position to show all nodes
  /// in the graph with 50 pixels of padding on all sides.
  ///
  /// Does nothing if there are no nodes or if the screen size is zero.
  ///
  /// Example:
  /// ```dart
  /// // After loading a graph, fit it to view
  /// controller.loadGraph(savedGraph);
  /// controller.fitToView();
  /// ```
  void fitToView() {
    if (_nodes.isEmpty || _screenSize.value == Size.zero) return;

    final bounds = nodesBounds;
    if (bounds == Rect.zero) return;

    final contentWidth = bounds.width;
    final contentHeight = bounds.height;
    final padding = 50.0;

    final scaleX = (_screenSize.value.width - padding * 2) / contentWidth;
    final scaleY = (_screenSize.value.height - padding * 2) / contentHeight;
    final zoom = (scaleX < scaleY ? scaleX : scaleY).clamp(
      _config.minZoom.value,
      _config.maxZoom.value,
    );

    final centerX = bounds.left + contentWidth / 2;
    final centerY = bounds.top + contentHeight / 2;

    setViewport(
      GraphViewport(
        x: _screenSize.value.width / 2 - centerX * zoom,
        y: _screenSize.value.height / 2 - centerY * zoom,
        zoom: zoom,
      ),
    );
  }

  /// Adjusts the viewport to fit all selected nodes in the view with padding.
  ///
  /// Calculates the optimal zoom level and pan position to show only the
  /// selected nodes with 50 pixels of padding on all sides.
  ///
  /// Does nothing if no nodes are selected or if the screen size is zero.
  ///
  /// Example:
  /// ```dart
  /// controller.selectNodes(['node1', 'node2']);
  /// controller.fitSelectedNodes();
  /// ```
  void fitSelectedNodes() {
    if (_selectedNodeIds.isEmpty || _screenSize.value == Size.zero) return;

    final bounds = selectedNodesBounds;
    if (bounds == null) return;

    final contentWidth = bounds.width;
    final contentHeight = bounds.height;
    final padding = 50.0;

    final scaleX = (_screenSize.value.width - padding * 2) / contentWidth;
    final scaleY = (_screenSize.value.height - padding * 2) / contentHeight;
    final zoom = (scaleX < scaleY ? scaleX : scaleY).clamp(
      _config.minZoom.value,
      _config.maxZoom.value,
    );

    final centerX = bounds.left + contentWidth / 2;
    final centerY = bounds.top + contentHeight / 2;

    setViewport(
      GraphViewport(
        x: _screenSize.value.width / 2 - centerX * zoom,
        y: _screenSize.value.height / 2 - centerY * zoom,
        zoom: zoom,
      ),
    );
  }

  /// Centers the viewport on a specific node without changing the zoom level.
  ///
  /// Does nothing if the node doesn't exist or if the screen size is zero.
  ///
  /// Parameters:
  /// - [nodeId]: The ID of the node to center on
  ///
  /// Example:
  /// ```dart
  /// controller.centerOnNode('node1');
  /// ```
  void centerOnNode(String nodeId) {
    final node = _nodes[nodeId];
    if (node == null || _screenSize.value == Size.zero) return;

    final pos = node.position.value;
    final size = node.size.value;
    final currentVp = _viewport.value;

    final nodeCenterX = pos.dx + size.width / 2;
    final nodeCenterY = pos.dy + size.height / 2;

    setViewport(
      GraphViewport(
        x: _screenSize.value.width / 2 - nodeCenterX * currentVp.zoom,
        y: _screenSize.value.height / 2 - nodeCenterY * currentVp.zoom,
        zoom: currentVp.zoom,
      ),
    );
  }

  /// Centers the viewport on the center point of all selected nodes without changing zoom.
  ///
  /// Calculates the geometric center of all selected nodes and pans the viewport
  /// to that point.
  ///
  /// Does nothing if no nodes are selected or if the screen size is zero.
  ///
  /// Example:
  /// ```dart
  /// controller.selectNodes(['node1', 'node2', 'node3']);
  /// controller.centerOnSelection();
  /// ```
  void centerOnSelection() {
    if (_selectedNodeIds.isEmpty || _screenSize.value == Size.zero) return;

    // Calculate center of selected nodes
    double totalX = 0;
    double totalY = 0;
    int count = 0;

    for (final nodeId in _selectedNodeIds) {
      final node = _nodes[nodeId];
      if (node != null) {
        final pos = node.position.value;
        final size = node.size.value;
        totalX += pos.dx + size.width / 2;
        totalY += pos.dy + size.height / 2;
        count++;
      }
    }

    if (count == 0) return;

    final centerX = totalX / count;
    final centerY = totalY / count;
    final currentVp = _viewport.value;

    setViewport(
      GraphViewport(
        x: _screenSize.value.width / 2 - centerX * currentVp.zoom,
        y: _screenSize.value.height / 2 - centerY * currentVp.zoom,
        zoom: currentVp.zoom,
      ),
    );
  }

  /// Centers the viewport on the geometric center of all nodes without changing zoom.
  ///
  /// Calculates the center point of all nodes in the graph and pans the viewport
  /// to that location while maintaining the current zoom level.
  ///
  /// Does nothing if there are no nodes or if the screen size is zero.
  ///
  /// This is useful for recentering your view on the content without losing your
  /// current zoom level, unlike [fitToView] which adjusts the zoom.
  ///
  /// Example:
  /// ```dart
  /// // User zoomed in to 200% and panned around
  /// controller.setZoom(2.0);
  /// // ... user pans around ...
  ///
  /// // Recenter on all nodes while keeping 200% zoom
  /// controller.centerViewport();
  /// ```
  ///
  /// See also:
  /// - [fitToView] to fit all nodes with automatic zoom adjustment
  /// - [centerOnSelection] to center on selected nodes only
  /// - [resetViewport] to reset zoom to 1.0 and center
  void centerViewport() {
    if (_nodes.isEmpty || _screenSize.value == Size.zero) return;

    final bounds = nodesBounds;
    if (bounds == Rect.zero) return;

    // Get the center of all nodes
    final center = bounds.center;
    final currentVp = _viewport.value;

    setViewport(
      GraphViewport(
        x: _screenSize.value.width / 2 - center.dx * currentVp.zoom,
        y: _screenSize.value.height / 2 - center.dy * currentVp.zoom,
        zoom: currentVp.zoom,
      ),
    );
  }

  /// Centers the viewport on a specific point in graph coordinates without changing zoom.
  ///
  /// This is useful for centering the viewport on an arbitrary location, such as
  /// where a new node should be created.
  ///
  /// Does nothing if the screen size is zero.
  ///
  /// Parameters:
  /// - [point]: The point in graph coordinates to center on
  ///
  /// Example:
  /// ```dart
  /// // Center on a specific point where user wants to add a node
  /// final center = controller.getViewportCenter();
  /// controller.centerOn(center);
  ///
  /// // Or center on a specific coordinate
  /// controller.centerOn(Offset(500, 300));
  /// ```
  void centerOn(Offset point) {
    if (_screenSize.value == Size.zero) return;

    final currentVp = _viewport.value;

    setViewport(
      GraphViewport(
        x: _screenSize.value.width / 2 - point.dx * currentVp.zoom,
        y: _screenSize.value.height / 2 - point.dy * currentVp.zoom,
        zoom: currentVp.zoom,
      ),
    );
  }

  /// Gets the center point of the current viewport in graph coordinates.
  ///
  /// This is useful for determining where to place new nodes so they appear
  /// in the center of the visible area.
  ///
  /// Returns [Offset.zero] if the screen size is zero.
  ///
  /// Returns the center point of the viewport in graph/world coordinates.
  ///
  /// Example:
  /// ```dart
  /// // Get the viewport center to place a new node there
  /// final center = controller.getViewportCenter();
  /// final newNode = Node(
  ///   id: 'new-node',
  ///   type: 'process',
  ///   position: center, // Node will appear at viewport center
  /// );
  /// controller.addNode(newNode);
  /// ```
  Offset getViewportCenter() {
    if (_screenSize.value == Size.zero) return Offset.zero;

    // Get the screen center point
    final screenCenter = Offset(
      _screenSize.value.width / 2,
      _screenSize.value.height / 2,
    );

    // Convert to graph coordinates
    return screenToWorld(screenCenter);
  }

  /// Resets the viewport to zoom 1.0 and centers on all nodes in the graph.
  ///
  /// If there are no nodes, resets to origin (0, 0) with zoom 1.0.
  /// If there are nodes, centers the viewport on their geometric center.
  ///
  /// Example:
  /// ```dart
  /// controller.resetViewport(); // Reset to default view
  /// ```
  void resetViewport() {
    const zoom = 1.0;

    // If there are no nodes, just reset to origin
    if (_nodes.isEmpty || _screenSize.value == Size.zero) {
      setViewport(GraphViewport(x: 0, y: 0, zoom: zoom));
      return;
    }

    // Calculate center of all nodes
    final bounds = nodesBounds;
    if (bounds == Rect.zero) {
      setViewport(GraphViewport(x: 0, y: 0, zoom: zoom));
      return;
    }

    final centerX = bounds.left + bounds.width / 2;
    final centerY = bounds.top + bounds.height / 2;

    // Center the viewport on the content
    setViewport(
      GraphViewport(
        x: _screenSize.value.width / 2 - centerX * zoom,
        y: _screenSize.value.height / 2 - centerY * zoom,
        zoom: zoom,
      ),
    );
  }

  // Node management

  /// Creates a duplicate of a node and adds it to the graph.
  ///
  /// The duplicated node:
  /// - Has a new auto-generated ID
  /// - Is positioned 50 pixels down and right from the original
  /// - Has a cloned copy of the data if it implements [NodeData]
  /// - Has the same type, size, and ports as the original
  ///
  /// Does nothing if the node doesn't exist.
  ///
  /// Parameters:
  /// - [nodeId]: The ID of the node to duplicate
  ///
  /// Example:
  /// ```dart
  /// controller.duplicateNode('node1');
  /// ```
  void duplicateNode(String nodeId) {
    final node = _nodes[nodeId];
    if (node == null) return;

    // Clone the data if it implements NodeData interface, otherwise just copy the reference
    final clonedData = node.data is NodeData
        ? (node.data as NodeData).clone() as T
        : node.data;

    final duplicatedNode = Node<T>(
      id: '${node.id}_copy_${DateTime.now().millisecondsSinceEpoch}',
      type: node.type,
      position: node.position.value + const Offset(50, 50),
      data: clonedData,
      size: node.size.value,
      inputPorts: node.inputPorts,
      outputPorts: node.outputPorts,
    );

    addNode(duplicatedNode);
  }

  // Graph operations

  /// Clears the entire graph, removing all nodes, connections, annotations, and selections.
  ///
  /// This operation:
  /// - Removes all nodes
  /// - Removes all connections
  /// - Clears all selections
  /// - Removes all annotations
  /// - Clears the connection painter cache
  ///
  /// Does nothing if the graph is already empty.
  ///
  /// Example:
  /// ```dart
  /// controller.clearGraph();
  /// ```
  void clearGraph() {
    if (_nodes.isEmpty && _connections.isEmpty) return;

    runInAction(() {
      _nodes.clear();
      _connections.clear();
      _selectedNodeIds.clear();
      _selectedConnectionIds.clear();
      annotations.annotations.clear();
      annotations.clearAnnotationSelection();
    });

    // Clear spatial indexes to prevent stale hit test entries
    _spatialIndex.clear();

    // Clear connection painter cache to prevent stale paths
    _connectionPainter?.clearAllCachedPaths();
  }

  /// Selects all nodes in the graph.
  ///
  /// This is a convenience method for selecting everything. Use Cmd+A / Ctrl+A
  /// keyboard shortcut to trigger this.
  ///
  /// Example:
  /// ```dart
  /// controller.selectAllNodes();
  /// ```
  void selectAllNodes() {
    runInAction(() {
      _selectedNodeIds.clear();
      _selectedNodeIds.addAll(_nodes.keys);
      for (final node in _nodes.values) {
        node.selected.value = true;
      }
    });
  }

  /// Selects all connections in the graph.
  ///
  /// Example:
  /// ```dart
  /// controller.selectAllConnections();
  /// ```
  void selectAllConnections() {
    runInAction(() {
      _selectedConnectionIds.clear();
      _selectedConnectionIds.addAll(_connections.map((c) => c.id));
    });
  }

  /// Selects all nodes of a specific type.
  ///
  /// This clears the current selection and selects only nodes matching the given type.
  ///
  /// Parameters:
  /// - [type]: The node type to select (matches the `node.type` property)
  ///
  /// Example:
  /// ```dart
  /// controller.selectNodesByType('process');
  /// ```
  void selectNodesByType(String type) {
    runInAction(() {
      for (final node in _nodes.values) {
        node.selected.value = false;
      }
      _selectedNodeIds.clear();

      for (final node in _nodes.values) {
        if (node.type == type) {
          _selectedNodeIds.add(node.id);
          node.selected.value = true;
        }
      }
    });
  }

  /// Inverts the current node selection.
  ///
  /// All currently selected nodes become deselected, and all deselected nodes
  /// become selected.
  ///
  /// Example:
  /// ```dart
  /// controller.invertSelection();
  /// ```
  void invertSelection() {
    runInAction(() {
      final currentlySelected = Set.from(_selectedNodeIds);
      _selectedNodeIds.clear();

      for (final node in _nodes.values) {
        if (currentlySelected.contains(node.id)) {
          node.selected.value = false;
        } else {
          _selectedNodeIds.add(node.id);
          node.selected.value = true;
        }
      }
    });
  }

  // Layout methods

  /// Arranges all nodes in a grid layout.
  ///
  /// Calculates an optimal grid size based on the square root of the number of nodes
  /// and positions them in rows and columns with the specified spacing.
  ///
  /// Parameters:
  /// - [spacing]: The distance between nodes in pixels (default: 150.0)
  ///
  /// Example:
  /// ```dart
  /// controller.arrangeNodesInGrid(spacing: 200.0);
  /// ```
  void arrangeNodesInGrid({double spacing = 150.0}) {
    final nodeList = _nodes.values.toList();
    final gridSize = math.sqrt(nodeList.length.toDouble()).ceil();

    runInAction(() {
      for (int i = 0; i < nodeList.length; i++) {
        final row = i ~/ gridSize;
        final col = i % gridSize;
        final newPosition = Offset(col * spacing, row * spacing);
        nodeList[i].position.value = newPosition;
        // Update visual position with snapping
        nodeList[i].setVisualPosition(_config.snapToGridIfEnabled(newPosition));
      }
    });

    // Rebuild spatial index for all nodes and connections after layout
    _spatialIndex.rebuildFromNodes(nodeList);
    rebuildAllConnectionSegments();
  }

  /// Arranges nodes hierarchically by type.
  ///
  /// Groups nodes by their type property and arranges each type group in rows,
  /// with 200 pixels horizontal spacing and 150 pixels vertical spacing between groups.
  ///
  /// Example:
  /// ```dart
  /// controller.arrangeNodesHierarchically();
  /// ```
  void arrangeNodesHierarchically() {
    // Simple implementation - arrange by type
    final nodesByType = <String, List<Node<T>>>{};
    for (final node in _nodes.values) {
      nodesByType.putIfAbsent(node.type, () => []).add(node);
    }

    runInAction(() {
      double y = 0;
      for (final entry in nodesByType.entries) {
        double x = 0;
        for (final node in entry.value) {
          final newPosition = Offset(x, y);
          node.position.value = newPosition;
          // Update visual position with snapping
          node.setVisualPosition(_config.snapToGridIfEnabled(newPosition));
          x += 200;
        }
        y += 150;
      }
    });

    // Rebuild spatial index for all nodes and connections after layout
    _spatialIndex.rebuildFromNodes(_nodes.values);
    rebuildAllConnectionSegments();
  }

  // Query methods

  /// Gets all nodes that have no connections.
  ///
  /// Returns a list of nodes that are neither sources nor targets of any connections.
  /// Useful for identifying isolated or unused nodes in the graph.
  ///
  /// Returns a list of orphan nodes (may be empty).
  ///
  /// Example:
  /// ```dart
  /// final orphans = controller.getOrphanNodes();
  /// print('Found ${orphans.length} orphan nodes');
  /// ```
  List<Node<T>> getOrphanNodes() {
    final connectedNodeIds = <String>{};
    for (final connection in _connections) {
      connectedNodeIds.add(connection.sourceNodeId);
      connectedNodeIds.add(connection.targetNodeId);
    }
    return _nodes.values
        .where((node) => !connectedNodeIds.contains(node.id))
        .toList();
  }

  // Advanced operations

  /// Deletes multiple nodes from the graph.
  ///
  /// This is a convenience method for batch deletion. Each node removal also
  /// removes its associated connections.
  ///
  /// Parameters:
  /// - [nodeIds]: List of node IDs to delete
  ///
  /// Example:
  /// ```dart
  /// controller.deleteNodes(['node1', 'node2', 'node3']);
  /// ```
  void deleteNodes(List<String> nodeIds) {
    runInAction(() {
      for (final nodeId in nodeIds) {
        removeNode(nodeId);
      }
    });
  }

  /// Brings a node to the front of the z-order (renders on top of all other nodes).
  ///
  /// Sets the node's z-index to be higher than all other nodes.
  ///
  /// Parameters:
  /// - [nodeId]: The ID of the node to bring to front
  ///
  /// Example:
  /// ```dart
  /// controller.bringNodeToFront('node1');
  /// ```
  void bringNodeToFront(String nodeId) {
    final node = _nodes[nodeId];
    if (node != null) {
      runInAction(() {
        // Set to highest z-index
        final maxZIndex = _nodes.values
            .map((n) => n.zIndex.value)
            .fold(0, math.max);
        node.zIndex.value = maxZIndex + 1;
      });
    }
  }

  /// Sends a node to the back of the z-order (renders behind all other nodes).
  ///
  /// Sets the node's z-index to be lower than all other nodes.
  ///
  /// Parameters:
  /// - [nodeId]: The ID of the node to send to back
  ///
  /// Example:
  /// ```dart
  /// controller.sendNodeToBack('node1');
  /// ```
  void sendNodeToBack(String nodeId) {
    final node = _nodes[nodeId];
    if (node != null) {
      runInAction(() {
        // Set to lowest z-index
        final minZIndex = _nodes.values
            .map((n) => n.zIndex.value)
            .fold(0, math.min);
        node.zIndex.value = minZIndex - 1;
      });
    }
  }

  /// Moves a node one step forward in the z-order.
  ///
  /// Swaps the z-index with the next higher node in the visual stack.
  /// Does nothing if the node is already at the front.
  ///
  /// Parameters:
  /// - [nodeId]: The ID of the node to move forward
  ///
  /// Example:
  /// ```dart
  /// controller.bringNodeForward('node1');
  /// ```
  void bringNodeForward(String nodeId) {
    final node = _nodes[nodeId];
    if (node == null) return;

    runInAction(() {
      // Sort all nodes by z-index to get the visual order
      final sortedNodes = _nodes.values.toList()
        ..sort((a, b) => a.zIndex.value.compareTo(b.zIndex.value));

      // Find current node's position in the visual order
      final currentIndex = sortedNodes.indexOf(node);

      // If not at the top, swap with next higher node
      if (currentIndex < sortedNodes.length - 1) {
        final nextNode = sortedNodes[currentIndex + 1];

        // We need to ensure the z-indexes are different
        // If they're the same, normalize all z-indexes first
        if (node.zIndex.value == nextNode.zIndex.value) {
          // Normalize all z-indexes to be sequential
          for (int i = 0; i < sortedNodes.length; i++) {
            sortedNodes[i].zIndex.value = i;
          }
          // Now swap the normalized values
          node.zIndex.value = currentIndex + 1;
          nextNode.zIndex.value = currentIndex;
        } else {
          // Z-indexes are different, just swap them
          final currentZ = node.zIndex.value;
          final nextZ = nextNode.zIndex.value;
          node.zIndex.value = nextZ;
          nextNode.zIndex.value = currentZ;
        }
      }
    });
  }

  /// Moves a node one step backward in the z-order.
  ///
  /// Swaps the z-index with the next lower node in the visual stack.
  /// Does nothing if the node is already at the back.
  ///
  /// Parameters:
  /// - [nodeId]: The ID of the node to move backward
  ///
  /// Example:
  /// ```dart
  /// controller.sendNodeBackward('node1');
  /// ```
  void sendNodeBackward(String nodeId) {
    final node = _nodes[nodeId];
    if (node == null) return;

    runInAction(() {
      // Sort all nodes by z-index to get the visual order
      final sortedNodes = _nodes.values.toList()
        ..sort((a, b) => a.zIndex.value.compareTo(b.zIndex.value));

      // Find current node's position in the visual order
      final currentIndex = sortedNodes.indexOf(node);

      // If not at the bottom, swap with next lower node
      if (currentIndex > 0) {
        final prevNode = sortedNodes[currentIndex - 1];

        // We need to ensure the z-indexes are different
        // If they're the same, normalize all z-indexes first
        if (node.zIndex.value == prevNode.zIndex.value) {
          // Normalize all z-indexes to be sequential
          for (int i = 0; i < sortedNodes.length; i++) {
            sortedNodes[i].zIndex.value = i;
          }
          // Now swap the normalized values
          node.zIndex.value = currentIndex - 1;
          prevNode.zIndex.value = currentIndex;
        } else {
          // Z-indexes are different, just swap them
          final currentZ = node.zIndex.value;
          final prevZ = prevNode.zIndex.value;
          node.zIndex.value = prevZ;
          prevNode.zIndex.value = currentZ;
        }
      }
    });
  }

  /// Aligns multiple nodes according to the specified alignment option.
  ///
  /// Requires at least 2 nodes. Calculates alignment based on the bounds
  /// of all specified nodes.
  ///
  /// Parameters:
  /// - `nodeIds`: List of node IDs to align (must contain at least 2 nodes)
  /// - `alignment`: The alignment type (top, right, bottom, left, center, horizontalCenter, verticalCenter)
  ///
  /// Does nothing if fewer than 2 valid nodes are provided.
  ///
  /// Example:
  /// ```dart
  /// controller.alignNodes(
  ///   ['node1', 'node2', 'node3'],
  ///   NodeAlignment.left,
  /// );
  /// ```
  void alignNodes(List<String> nodeIds, NodeAlignment alignment) {
    if (nodeIds.length < 2) return;

    final nodes = nodeIds.map((id) => _nodes[id]).whereType<Node<T>>().toList();
    if (nodes.length < 2) return;

    // Calculate proper bounds of all nodes including their sizes
    final bounds = _calculateNodesBounds(nodes);
    if (bounds == null) return;

    // Extract alignment reference points from the bounds
    final leftmost = bounds.left;
    final rightmost = bounds.right;
    final topmost = bounds.top;
    final bottommost = bounds.bottom;
    final centerX = bounds.center.dx;
    final centerY = bounds.center.dy;

    runInAction(() {
      for (final node in nodes) {
        final currentPos = node.position.value;
        double newX = currentPos.dx;
        double newY = currentPos.dy;

        // Determine target position based on alignment
        switch (alignment) {
          case NodeAlignment.left:
            // Align left edges - position.dx should equal leftmost
            newX = leftmost;
            break;
          case NodeAlignment.right:
            // Align right edges - position.dx + width should equal rightmost
            newX = rightmost - node.size.value.width;
            break;
          case NodeAlignment.top:
            // Align top edges - position.dy should equal topmost
            newY = topmost;
            break;
          case NodeAlignment.bottom:
            // Align bottom edges - position.dy + height should equal bottommost
            newY = bottommost - node.size.value.height;
            break;
          case NodeAlignment.center:
            // Align center points on both axes
            newX = centerX - node.size.value.width / 2;
            newY = centerY - node.size.value.height / 2;
            break;
          case NodeAlignment.horizontalCenter:
            // Align center points horizontally only
            newX = centerX - node.size.value.width / 2;
            // Keep original Y position
            break;
          case NodeAlignment.verticalCenter:
            // Align center points vertically only
            newY = centerY - node.size.value.height / 2;
            // Keep original X position
            break;
        }

        final newPosition = Offset(newX, newY);
        node.position.value = newPosition;
        // Update visual position with snapping
        node.setVisualPosition(_config.snapToGridIfEnabled(newPosition));
      }
    });

    // Update spatial index and rebuild connection segments
    internalMarkNodesDirty(nodeIds);
    rebuildConnectionSegmentsForNodes(nodeIds);
  }

  /// Distributes nodes evenly along the horizontal axis.
  ///
  /// Requires at least 3 nodes. Sorts nodes by X position, keeps the leftmost
  /// and rightmost nodes in place, and distributes the middle nodes evenly.
  ///
  /// Parameters:
  /// - [nodeIds]: List of node IDs to distribute (must contain at least 3 nodes)
  ///
  /// Does nothing if fewer than 3 valid nodes are provided.
  ///
  /// Example:
  /// ```dart
  /// controller.distributeNodesHorizontally(['node1', 'node2', 'node3', 'node4']);
  /// ```
  void distributeNodesHorizontally(List<String> nodeIds) {
    if (nodeIds.length < 3) return;

    final nodes = nodeIds.map((id) => _nodes[id]).whereType<Node<T>>().toList();
    if (nodes.length < 3) return;

    // Sort nodes by X position
    nodes.sort((a, b) => a.position.value.dx.compareTo(b.position.value.dx));

    final leftmost = nodes.first.position.value.dx;
    final rightmost = nodes.last.position.value.dx;
    final spacing = (rightmost - leftmost) / (nodes.length - 1);

    runInAction(() {
      for (int i = 1; i < nodes.length - 1; i++) {
        final targetX = leftmost + spacing * i;
        final newPosition = Offset(targetX, nodes[i].position.value.dy);
        nodes[i].position.value = newPosition;
        // Update visual position with snapping
        nodes[i].setVisualPosition(_config.snapToGridIfEnabled(newPosition));
      }
    });

    // Update spatial index and rebuild connection segments
    internalMarkNodesDirty(nodeIds);
    rebuildConnectionSegmentsForNodes(nodeIds);
  }

  /// Distributes nodes evenly along the vertical axis.
  ///
  /// Requires at least 3 nodes. Sorts nodes by Y position, keeps the topmost
  /// and bottommost nodes in place, and distributes the middle nodes evenly.
  ///
  /// Parameters:
  /// - [nodeIds]: List of node IDs to distribute (must contain at least 3 nodes)
  ///
  /// Does nothing if fewer than 3 valid nodes are provided.
  ///
  /// Example:
  /// ```dart
  /// controller.distributeNodesVertically(['node1', 'node2', 'node3', 'node4']);
  /// ```
  void distributeNodesVertically(List<String> nodeIds) {
    if (nodeIds.length < 3) return;

    final nodes = nodeIds.map((id) => _nodes[id]).whereType<Node<T>>().toList();
    if (nodes.length < 3) return;

    // Sort nodes by Y position
    nodes.sort((a, b) => a.position.value.dy.compareTo(b.position.value.dy));

    final topmost = nodes.first.position.value.dy;
    final bottommost = nodes.last.position.value.dy;
    final spacing = (bottommost - topmost) / (nodes.length - 1);

    runInAction(() {
      for (int i = 1; i < nodes.length - 1; i++) {
        final targetY = topmost + spacing * i;
        final newPosition = Offset(nodes[i].position.value.dx, targetY);
        nodes[i].position.value = newPosition;
        // Update visual position with snapping
        nodes[i].setVisualPosition(_config.snapToGridIfEnabled(newPosition));
      }
    });

    // Update spatial index and rebuild connection segments
    internalMarkNodesDirty(nodeIds);
    rebuildConnectionSegmentsForNodes(nodeIds);
  }

  /// Selects only the specified nodes, clearing any existing selection.
  ///
  /// This is similar to `selectNodes` but always clears the existing selection first.
  ///
  /// Parameters:
  /// - [nodeIds]: List of node IDs to select
  ///
  /// Example:
  /// ```dart
  /// controller.selectSpecificNodes(['node1', 'node2']);
  /// ```
  void selectSpecificNodes(List<String> nodeIds) {
    runInAction(() {
      // Clear current selection
      for (final node in _nodes.values) {
        node.selected.value = false;
      }
      _selectedNodeIds.clear();

      // Select specified nodes
      for (final nodeId in nodeIds) {
        final node = _nodes[nodeId];
        if (node != null) {
          _selectedNodeIds.add(nodeId);
          node.selected.value = true;
        }
      }
    });
  }

  /// Deletes all connections associated with a node.
  ///
  /// Removes all connections where the node is either the source or target.
  /// The node itself is not deleted.
  ///
  /// Parameters:
  /// - [nodeId]: The ID of the node whose connections should be removed
  ///
  /// Example:
  /// ```dart
  /// controller.deleteAllConnectionsForNode('node1');
  /// ```
  void deleteAllConnectionsForNode(String nodeId) {
    final connectionsToRemove = _connections
        .where(
          (conn) => conn.sourceNodeId == nodeId || conn.targetNodeId == nodeId,
        )
        .toList();

    runInAction(() {
      for (final conn in connectionsToRemove) {
        // Remove from spatial index and path cache
        _spatialIndex.removeConnection(conn.id);
        _connectionPainter?.removeConnectionFromCache(conn.id);
        // Remove from connections list
        _connections.remove(conn);
      }
    });
  }

  /// Creates a connection between two ports.
  ///
  /// This is a convenience method that creates a Connection object with an
  /// auto-generated ID and adds it to the graph.
  ///
  /// Parameters:
  /// - [sourceNodeId]: The ID of the source node
  /// - [sourcePortId]: The ID of the output port on the source node
  /// - [targetNodeId]: The ID of the target node
  /// - [targetPortId]: The ID of the input port on the target node
  ///
  /// Example:
  /// ```dart
  /// controller.createConnection(
  ///   'node1',
  ///   'output1',
  ///   'node2',
  ///   'input1',
  /// );
  /// ```
  void createConnection(
    String sourceNodeId,
    String sourcePortId,
    String targetNodeId,
    String targetPortId,
  ) {
    final connection = Connection(
      id: 'conn_${DateTime.now().millisecondsSinceEpoch}',
      sourceNodeId: sourceNodeId,
      sourcePortId: sourcePortId,
      targetNodeId: targetNodeId,
      targetPortId: targetPortId,
    );
    addConnection(connection);
  }

  /// Sets a node's position to an absolute position.
  ///
  /// The position will be automatically snapped to the grid if snap-to-grid
  /// is enabled in the controller's configuration.
  ///
  /// Does nothing if the node doesn't exist.
  ///
  /// Parameters:
  /// - [nodeId]: The ID of the node to reposition
  /// - [position]: The new absolute position in graph coordinates
  ///
  /// Example:
  /// ```dart
  /// controller.setNodePosition('node1', Offset(200, 150));
  /// ```
  void setNodePosition(String nodeId, Offset position) {
    final node = _nodes[nodeId];
    if (node != null) {
      runInAction(() {
        node.position.value = position;
        // Update visual position with snapping
        node.setVisualPosition(_config.snapToGridIfEnabled(position));
      });
      internalMarkNodeDirty(nodeId);
    }
  }

  /// Gets all connections associated with a node.
  ///
  /// Returns connections where the node is either the source or target.
  ///
  /// Parameters:
  /// - [nodeId]: The ID of the node to get connections for
  ///
  /// Returns a list of connections (may be empty).
  ///
  /// Example:
  /// ```dart
  /// final connections = controller.getConnectionsForNode('node1');
  /// print('Node has ${connections.length} connections');
  /// ```
  List<Connection> getConnectionsForNode(String nodeId) {
    return _connections
        .where(
          (conn) => conn.sourceNodeId == nodeId || conn.targetNodeId == nodeId,
        )
        .toList();
  }

  // Computed properties

  /// Gets the bounding rectangle that encompasses all nodes in the graph.
  ///
  /// Calculates the minimal rectangle that contains all nodes based on their
  /// positions and sizes.
  ///
  /// Returns `Rect.zero` if there are no nodes.
  ///
  /// Example:
  /// ```dart
  /// final bounds = controller.nodesBounds;
  /// print('Graph size: ${bounds.width} x ${bounds.height}');
  /// ```
  Rect get nodesBounds {
    if (_nodes.isEmpty) return Rect.zero;

    double minX = double.infinity;
    double minY = double.infinity;
    double maxX = double.negativeInfinity;
    double maxY = double.negativeInfinity;

    for (final node in _nodes.values) {
      final pos = node.position.value;
      final size = node.size.value;
      minX = math.min(minX, pos.dx);
      minY = math.min(minY, pos.dy);
      maxX = math.max(maxX, pos.dx + size.width);
      maxY = math.max(maxY, pos.dy + size.height);
    }

    return Rect.fromLTRB(minX, minY, maxX, maxY);
  }

  /// Gets the current zoom level of the viewport.
  ///
  /// Returns the current zoom level (1.0 = 100%, 2.0 = 200%, etc.).
  double get currentZoom => _viewport.value.zoom;

  /// Gets the current pan position of the viewport.
  ///
  /// Returns the viewport's translation as an Offset.
  Offset get currentPan => Offset(_viewport.value.x, _viewport.value.y);

  // Analysis methods

  /// Tests if a point hits any connection.
  ///
  /// Uses the connection painter's hit-testing to determine if the given
  /// graph position intersects with any connection path.
  ///
  /// Parameters:
  /// - [graphPosition]: The position to test in graph/world coordinates
  ///
  /// Returns the connection ID if hit, `null` otherwise.
  ///
  /// Example:
  /// ```dart
  /// final hitConnectionId = controller.hitTestConnections(Offset(100, 100));
  /// if (hitConnectionId != null) {
  ///   print('Clicked on connection: $hitConnectionId');
  /// }
  /// ```
  String? hitTestConnections(Offset graphPosition) {
    // Use the controller's connection painter for hit-testing
    final painter = connectionPainter;

    // Check connections for hit-testing
    for (final connection in _connections) {
      final sourceNode = getNode(connection.sourceNodeId);
      final targetNode = getNode(connection.targetNodeId);

      if (sourceNode != null && targetNode != null) {
        if (painter.hitTestConnection(
          connection: connection,
          sourceNode: sourceNode,
          targetNode: targetNode,
          testPoint: graphPosition,
        )) {
          return connection.id;
        }
      }
    }
    return null;
  }

  /// Detects cycles in the graph using depth-first search.
  ///
  /// A cycle exists when you can follow connections from a node and eventually
  /// return to the same node.
  ///
  /// Returns a list of cycles, where each cycle is represented as a list of node IDs
  /// forming the cycle. Returns an empty list if no cycles are found.
  ///
  /// Example:
  /// ```dart
  /// final cycles = controller.detectCycles();
  /// if (cycles.isNotEmpty) {
  ///   print('Found ${cycles.length} cycles in the graph');
  ///   for (final cycle in cycles) {
  ///     print('Cycle: ${cycle.join(' -> ')}');
  ///   }
  /// }
  /// ```
  List<List<String>> detectCycles() {
    // Simple cycle detection implementation
    final cycles = <List<String>>[];
    final visited = <String>{};
    final recursionStack = <String>{};

    void dfs(String nodeId, List<String> path) {
      if (recursionStack.contains(nodeId)) {
        // Found a cycle
        final cycleStart = path.indexOf(nodeId);
        if (cycleStart >= 0) {
          cycles.add(path.sublist(cycleStart));
        }
        return;
      }

      if (visited.contains(nodeId)) return;

      visited.add(nodeId);
      recursionStack.add(nodeId);
      path.add(nodeId);

      // Follow outgoing connections
      final outgoingConnections = _connections.where(
        (c) => c.sourceNodeId == nodeId,
      );
      for (final conn in outgoingConnections) {
        dfs(conn.targetNodeId, List.from(path));
      }

      recursionStack.remove(nodeId);
      path.removeLast();
    }

    for (final node in _nodes.values) {
      if (!visited.contains(node.id)) {
        dfs(node.id, []);
      }
    }

    return cycles;
  }

  /// Shows the keyboard shortcuts dialog.
  ///
  /// Displays a comprehensive dialog showing all available keyboard shortcuts
  /// organized by category for easy reference.
  ///
  /// Parameters:
  /// - [context]: The BuildContext for showing the dialog
  ///
  /// Example:
  /// ```dart
  /// controller.showShortcutsDialog(context);
  /// ```
  void showShortcutsDialog(BuildContext context) {
    // Import will be added at the top when used
    showDialog(
      context: context,
      builder: (context) => ShortcutsViewerDialog(
        shortcuts: shortcuts.keyMap,
        actions: shortcuts.actions,
      ),
    );
  }

  /// Set the theme and update the connection painter
  /// This is called internally by the editor widget only
  void setTheme(NodeFlowTheme theme) {
    // Create painter if it doesn't exist, otherwise update its theme
    if (_connectionPainter == null) {
      _connectionPainter = ConnectionPainter(
        theme: theme,
        // Cast to Node<dynamic> since ConnectionPainter is not generic
        nodeShape: _nodeShapeBuilder != null
            ? (node) => _nodeShapeBuilder!(node as Node<T>)
            : null,
      );
    } else {
      _connectionPainter!.updateTheme(theme);
    }

    // Update observable theme - this triggers the reaction for spatial index rebuild
    runInAction(() => _themeObservable.value = theme);
  }

  /// Update the events that the controller will use
  /// This is called internally by the editor widget only
  void setEvents(NodeFlowEvents<T> events) {
    _events = events;
  }

  /// Hit test annotations at a specific position
  /// This is a delegating method for the editor's hit testing
  Annotation? hitTestAnnotations(Offset graphPosition) {
    return annotations.internalHitTestAnnotations(graphPosition);
  }

  /// Hit test for a port at the given graph position.
  ///
  /// Returns a record containing (nodeId, portId, isOutput) if a port is found
  /// at the position, otherwise returns null.
  ///
  /// This is useful for finding target ports during connection drag operations.
  ///
  /// Example:
  /// ```dart
  /// final result = controller.hitTestPort(graphPosition);
  /// if (result != null) {
  ///   print('Found port ${result.portId} on node ${result.nodeId}');
  /// }
  /// ```
  ({String nodeId, String portId, bool isOutput})? hitTestPort(
    Offset graphPosition,
  ) {
    final result = _spatialIndex.hitTestPort(graphPosition);
    if (result != null && result.portId != null) {
      return (
        nodeId: result.nodeId!,
        portId: result.portId!,
        isOutput: result.isOutput ?? false,
      );
    }
    return null;
  }

  // ===========================================================================
  // Widget-Level Drag API
  // ===========================================================================
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
        // Update drag-to-group highlight for the dragged node (Command+drag only)
        final isCommandPressed = HardwareKeyboard.instance.isMetaPressed;
        annotations.updateDragHighlight(draggedNodeId, isCommandPressed);
      } else {
        // Move single node
        final node = _nodes[draggedNodeId];
        if (node != null) {
          final newPosition = node.position.value + graphDelta;
          node.position.value = newPosition;
          // Update visual position with snapping
          node.setVisualPosition(_config.snapToGridIfEnabled(newPosition));
          movedNodes.add(node);
          // Update drag-to-group highlight (Command+drag only)
          final isCommandPressed = HardwareKeyboard.instance.isMetaPressed;
          annotations.updateDragHighlight(draggedNodeId, isCommandPressed);
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

      // Handle Command+drag group operations (add/remove from groups)
      final isCommandPressed = HardwareKeyboard.instance.isMetaPressed;
      for (final nodeId in draggedNodeIds) {
        annotations.handleCommandDragGroupOperation(nodeId, isCommandPressed);
      }

      // Clear drag highlight and drag state
      annotations.clearDragHighlight();
      interaction.draggedNodeId.value = null;
      interaction.lastPointerPosition.value = null;
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
  // Connection Drag Operations
  // ---------------------------------------------------------------------------

  /// Validates whether a connection can start from the specified port.
  ///
  /// This method checks:
  /// 1. Port exists and is connectable
  /// 2. Direction compatibility (output can emit, input can receive)
  /// 3. Max connections not exceeded (for source ports)
  /// 4. Custom validation via [ConnectionEvents.onBeforeStart] callback
  ///
  /// Returns a [ConnectionValidationResult] indicating if the connection can start.
  ConnectionValidationResult canStartConnection({
    required String nodeId,
    required String portId,
    required bool isOutput,
  }) {
    final node = _nodes[nodeId];
    if (node == null) {
      return const ConnectionValidationResult.deny(reason: 'Node not found');
    }

    final port = node.allPorts.where((p) => p.id == portId).firstOrNull;
    if (port == null) {
      return const ConnectionValidationResult.deny(reason: 'Port not found');
    }

    // Port must be connectable
    if (!port.isConnectable) {
      return const ConnectionValidationResult.deny(
        reason: 'Port is not connectable',
      );
    }

    // Direction check: output ports must be able to emit
    // input ports must be able to receive
    if (isOutput && !port.isOutput) {
      return const ConnectionValidationResult.deny(
        reason: 'Port cannot emit connections',
      );
    }
    if (!isOutput && !port.isInput) {
      return const ConnectionValidationResult.deny(
        reason: 'Port cannot receive connections',
      );
    }

    // Get existing connections for this port
    final existingConnections = _connections
        .where(
          (conn) => isOutput
              ? (conn.sourceNodeId == nodeId && conn.sourcePortId == portId)
              : (conn.targetNodeId == nodeId && conn.targetPortId == portId),
        )
        .map((c) => c.id)
        .toList();

    // Check max connections for source port (output side)
    // Note: For input ports starting a drag, they become the target,
    // so we check source (output) max connections
    if (isOutput && port.maxConnections != null) {
      // If port doesn't allow multi-connections, we'll remove existing on drag
      // So only block if multi-connections is allowed but max is reached
      if (port.multiConnections &&
          existingConnections.length >= port.maxConnections!) {
        return const ConnectionValidationResult.deny(
          reason: 'Maximum connections reached',
        );
      }
    }

    // Call custom validation callback if provided
    final onBeforeStart = events.connection?.onBeforeStart;
    if (onBeforeStart != null) {
      final context = ConnectionStartContext<T>(
        sourceNode: node,
        sourcePort: port,
        existingConnections: existingConnections,
      );
      final result = onBeforeStart(context);
      if (!result.allowed) {
        return result;
      }
    }

    return const ConnectionValidationResult.allow();
  }

  /// Starts a connection drag from a port.
  ///
  /// Call this from PortWidget's GestureDetector.onPanStart.
  ///
  /// Parameters:
  /// - [nodeId]: The ID of the node containing the port
  /// - [portId]: The ID of the port being dragged from
  /// - [isOutput]: Whether this is an output port
  /// - [startPoint]: The starting point in graph coordinates
  /// - [nodeBounds]: The bounds of the source node in graph coordinates
  ///
  /// Returns the validation result. Check [ConnectionValidationResult.allowed]
  /// to determine if the drag started successfully.
  ConnectionValidationResult startConnectionDrag({
    required String nodeId,
    required String portId,
    required bool isOutput,
    required Offset startPoint,
    required Rect nodeBounds,
    Offset? initialScreenPosition,
  }) {
    // Check if connection creation is allowed by current behavior
    if (!behavior.canCreate) {
      return const ConnectionValidationResult.deny(
        reason: 'Connection creation is disabled in current behavior mode',
      );
    }

    // Validate source port before starting
    final validationResult = canStartConnection(
      nodeId: nodeId,
      portId: portId,
      isOutput: isOutput,
    );
    if (!validationResult.allowed) {
      return validationResult;
    }

    // Fire connection start event
    events.connection?.onConnectStart?.call(nodeId, portId, isOutput);

    // Check if we need to remove existing connections
    // (for ports that don't allow multiple connections)
    final node = getNode(nodeId);
    if (node != null) {
      final port = node.allPorts.where((p) => p.id == portId).firstOrNull;
      if (port != null && !port.multiConnections) {
        // Remove existing connections from this port
        final connectionsToRemove = _connections
            .where(
              (conn) => isOutput
                  ? (conn.sourceNodeId == nodeId && conn.sourcePortId == portId)
                  : (conn.targetNodeId == nodeId &&
                        conn.targetPortId == portId),
            )
            .toList();
        runInAction(() {
          for (final connection in connectionsToRemove) {
            removeConnection(connection.id);
          }
        });
      }
    }

    // Create temporary connection
    // Use the initial screen position (converted to graph) for initialCurrentPoint
    // to avoid a sudden jump from port position to mouse position on first move.
    // Note: initialScreenPosition is in global coordinates, so we use globalToGraph.
    final initialCurrentPoint = initialScreenPosition != null
        ? globalToGraph(initialScreenPosition)
        : startPoint;

    runInAction(() {
      // Disable panning during connection drag so InteractiveViewer
      // doesn't steal the gesture from PortWidget's GestureDetector
      interaction.panEnabled.value = false;

      // Cursor is handled reactively via Observer in widget MouseRegions
      interaction.temporaryConnection.value = TemporaryConnection(
        startNodeId: nodeId,
        startPortId: portId,
        isStartFromOutput: isOutput,
        startPoint: startPoint,
        initialCurrentPoint: initialCurrentPoint,
        startNodeBounds: nodeBounds,
      );
    });

    return validationResult;
  }

  /// Validates whether a connection can be made from the current drag state
  /// to the specified target port.
  ///
  /// This method checks:
  /// 1. Not connecting a port to itself (same node + same port is invalid,
  ///    but same node with different ports is OK for self-loops)
  /// 2. Direction compatibility (output→input or input←output)
  /// 3. Port is connectable
  /// 4. No duplicate connections
  /// 5. Max connections limit not exceeded
  /// 6. Custom validation via [ConnectionEvents.onBeforeComplete] callback
  ///    (only when [skipCustomValidation] is false)
  ///
  /// The [skipCustomValidation] parameter allows skipping the expensive custom
  /// validation callback during drag updates. This is useful for hover feedback
  /// where only basic structural validation is needed. The full validation
  /// including custom callbacks runs at connection completion time.
  ///
  /// Returns a [ConnectionValidationResult] indicating if the connection is valid.
  ConnectionValidationResult canConnect({
    required String targetNodeId,
    required String targetPortId,
    bool skipCustomValidation = false,
  }) {
    final temp = interaction.temporaryConnection.value;
    if (temp == null) {
      return const ConnectionValidationResult.deny(
        reason: 'No active connection drag',
      );
    }

    // 1. Cannot connect a port to itself
    // Same node is OK (self-loops), but same port on same node is NOT
    if (temp.startNodeId == targetNodeId && temp.startPortId == targetPortId) {
      return const ConnectionValidationResult.deny(
        reason: 'Cannot connect a port to itself',
      );
    }

    // Get target node first (needed for direction check)
    final targetNode = _nodes[targetNodeId];
    if (targetNode == null) {
      return const ConnectionValidationResult.deny(
        reason: 'Target node not found',
      );
    }

    // 2. Cannot connect same direction ports (output→output or input→input)
    // Determine if target port is in outputPorts or inputPorts list
    final targetIsOutput = targetNode.outputPorts.any(
      (p) => p.id == targetPortId,
    );
    if (temp.isStartFromOutput == targetIsOutput) {
      return ConnectionValidationResult.deny(
        reason: targetIsOutput
            ? 'Cannot connect output to output'
            : 'Cannot connect input to input',
      );
    }

    // Get source node and port
    final sourceNode = _nodes[temp.startNodeId];
    if (sourceNode == null) {
      return const ConnectionValidationResult.deny(
        reason: 'Source node not found',
      );
    }
    final sourcePort = sourceNode.allPorts
        .where((p) => p.id == temp.startPortId)
        .firstOrNull;
    if (sourcePort == null) {
      return const ConnectionValidationResult.deny(
        reason: 'Source port not found',
      );
    }

    // Get target port (targetNode already looked up above)
    final targetPort = targetNode.allPorts
        .where((p) => p.id == targetPortId)
        .firstOrNull;
    if (targetPort == null) {
      return const ConnectionValidationResult.deny(
        reason: 'Target port not found',
      );
    }

    // 2. Both ports must be connectable
    if (!sourcePort.isConnectable) {
      return const ConnectionValidationResult.deny(
        reason: 'Source port is not connectable',
      );
    }
    if (!targetPort.isConnectable) {
      return const ConnectionValidationResult.deny(
        reason: 'Target port is not connectable',
      );
    }

    // 3. Direction compatibility (port type check)
    // If started from output, target must be able to accept input
    // If started from input, target must be able to emit output
    if (temp.isStartFromOutput) {
      if (!targetPort.isInput) {
        return const ConnectionValidationResult.deny(
          reason: 'Target port cannot receive connections',
        );
      }
    } else {
      if (!targetPort.isOutput) {
        return const ConnectionValidationResult.deny(
          reason: 'Target port cannot emit connections',
        );
      }
    }

    // Determine actual source/target for duplicate and max connection checks
    final Node<T> actualSourceNode;
    final Port actualSourcePort;
    final Node<T> actualTargetNode;
    final Port actualTargetPort;

    if (temp.isStartFromOutput) {
      actualSourceNode = sourceNode;
      actualSourcePort = sourcePort;
      actualTargetNode = targetNode;
      actualTargetPort = targetPort;
    } else {
      actualSourceNode = targetNode;
      actualSourcePort = targetPort;
      actualTargetNode = sourceNode;
      actualTargetPort = sourcePort;
    }

    // Get existing connections for both ports
    final existingSourceConnections = _connections
        .where(
          (conn) =>
              conn.sourceNodeId == actualSourceNode.id &&
              conn.sourcePortId == actualSourcePort.id,
        )
        .map((c) => c.id)
        .toList();
    final existingTargetConnections = _connections
        .where(
          (conn) =>
              conn.targetNodeId == actualTargetNode.id &&
              conn.targetPortId == actualTargetPort.id,
        )
        .map((c) => c.id)
        .toList();

    // 4. No duplicate connections
    final duplicateExists = _connections.any(
      (conn) =>
          conn.sourceNodeId == actualSourceNode.id &&
          conn.sourcePortId == actualSourcePort.id &&
          conn.targetNodeId == actualTargetNode.id &&
          conn.targetPortId == actualTargetPort.id,
    );
    if (duplicateExists) {
      return const ConnectionValidationResult.deny(
        reason: 'Connection already exists',
      );
    }

    // 5. Max connections limit (only check target port since it receives the connection)
    if (actualTargetPort.maxConnections != null) {
      if (existingTargetConnections.length >=
          actualTargetPort.maxConnections!) {
        return const ConnectionValidationResult.deny(
          reason: 'Target port has maximum connections',
        );
      }
    }

    // 6. Call custom validation callback if provided (skip during drag for performance)
    if (!skipCustomValidation) {
      final onBeforeComplete = events.connection?.onBeforeComplete;
      if (onBeforeComplete != null) {
        final context = ConnectionCompleteContext<T>(
          sourceNode: actualSourceNode,
          sourcePort: actualSourcePort,
          targetNode: actualTargetNode,
          targetPort: actualTargetPort,
          existingSourceConnections: existingSourceConnections,
          existingTargetConnections: existingTargetConnections,
        );
        final result = onBeforeComplete(context);
        if (!result.allowed) {
          return result;
        }
      }
    }

    return const ConnectionValidationResult.allow();
  }

  /// Updates a connection drag with the current position.
  ///
  /// Call this from PortWidget's GestureDetector.onPanUpdate.
  ///
  /// Parameters:
  /// - [graphPosition]: Current pointer position in graph coordinates
  /// - [targetNodeId]: ID of node being hovered (null if none)
  /// - [targetPortId]: ID of port being hovered (null if none)
  /// - [targetNodeBounds]: Bounds of hovered node (null if none)
  void updateConnectionDrag({
    required Offset graphPosition,
    String? targetNodeId,
    String? targetPortId,
    Rect? targetNodeBounds,
  }) {
    final temp = interaction.temporaryConnection.value;
    if (temp == null) return;

    // Validate target port before highlighting
    // Only highlight valid connection targets
    // Skip custom validation during drag for performance - full validation runs at completion
    final isValidTarget =
        targetNodeId != null &&
        targetPortId != null &&
        canConnect(
          targetNodeId: targetNodeId,
          targetPortId: targetPortId,
          skipCustomValidation: true,
        ).allowed;

    // If target is invalid, treat as no target
    final validTargetNodeId = isValidTarget ? targetNodeId : null;
    final validTargetPortId = isValidTarget ? targetPortId : null;
    final validTargetBounds = isValidTarget ? targetNodeBounds : null;

    runInAction(() {
      // Handle port highlighting when target port changes
      final prevNodeId = temp.targetNodeId;
      final prevPortId = temp.targetPortId;
      final targetChanged =
          prevNodeId != validTargetNodeId || prevPortId != validTargetPortId;

      if (targetChanged) {
        // Reset previous port's highlighted state
        if (prevNodeId != null && prevPortId != null) {
          final prevNode = _nodes[prevNodeId];
          if (prevNode != null) {
            final prevPort = prevNode.allPorts
                .where((p) => p.id == prevPortId)
                .firstOrNull;
            prevPort?.highlighted.value = false;
          }
        }

        // Set new port's highlighted state (only if valid target)
        if (validTargetNodeId != null && validTargetPortId != null) {
          final newNode = _nodes[validTargetNodeId];
          if (newNode != null) {
            final newPort = newNode.allPorts
                .where((p) => p.id == validTargetPortId)
                .firstOrNull;
            newPort?.highlighted.value = true;
          }
        }
      }

      // Update connection endpoint - snap to target port if we have a valid one
      if (validTargetNodeId != null && validTargetPortId != null) {
        // Snap to the target port's connection point
        final targetNode = _nodes[validTargetNodeId];
        if (targetNode != null) {
          final targetPort = targetNode.allPorts
              .where((p) => p.id == validTargetPortId)
              .firstOrNull;
          if (targetPort != null) {
            // Calculate the actual connection point on the target port
            assert(
              _theme != null,
              'Theme must be set for connection operations',
            );
            final effectivePortSize = _theme!.portTheme.resolveSize(targetPort);
            final snapPoint = targetNode.getConnectionPoint(
              validTargetPortId,
              portSize: effectivePortSize,
              shape: nodeShapeBuilder?.call(targetNode),
            );
            temp.currentPoint = snapPoint;
          } else {
            temp.currentPoint = graphPosition;
          }
        } else {
          temp.currentPoint = graphPosition;
        }
      } else {
        // No valid target - follow mouse
        temp.currentPoint = graphPosition;
      }

      if (temp.targetNodeId != validTargetNodeId) {
        temp.targetNodeId = validTargetNodeId;
      }
      if (temp.targetPortId != validTargetPortId) {
        temp.targetPortId = validTargetPortId;
      }
      if (temp.targetNodeBounds != validTargetBounds) {
        temp.targetNodeBounds = validTargetBounds;
      }
    });
  }

  /// Completes a connection drag by creating the connection.
  ///
  /// Call this from PortWidget's GestureDetector.onPanEnd when over a valid target.
  ///
  /// Parameters:
  /// - [targetNodeId]: The ID of the target node
  /// - [targetPortId]: The ID of the target port
  ///
  /// Returns the created connection, or null if creation failed.
  Connection? completeConnectionDrag({
    required String targetNodeId,
    required String targetPortId,
  }) {
    final temp = interaction.temporaryConnection.value;
    if (temp == null) {
      // Fire connection end event with failure
      events.connection?.onConnectEnd?.call(false);
      return null;
    }

    // Validate connection before creating
    final validationResult = canConnect(
      targetNodeId: targetNodeId,
      targetPortId: targetPortId,
    );
    if (!validationResult.allowed) {
      cancelConnectionDrag();
      return null;
    }

    // Reset highlighted port
    final highlightedNode = _nodes[targetNodeId];
    if (highlightedNode != null) {
      final highlightedPort = highlightedNode.allPorts
          .where((p) => p.id == targetPortId)
          .firstOrNull;
      if (highlightedPort != null) {
        runInAction(() => highlightedPort.highlighted.value = false);
      }
    }

    // Determine actual source/target based on port direction:
    // - If started from output: start is source, target is target
    // - If started from input: target is source, start is target
    final String sourceNodeId;
    final String sourcePortId;
    final String actualTargetNodeId;
    final String actualTargetPortId;

    if (temp.isStartFromOutput) {
      // Output → Input: start is source, target is target
      sourceNodeId = temp.startNodeId;
      sourcePortId = temp.startPortId;
      actualTargetNodeId = targetNodeId;
      actualTargetPortId = targetPortId;
    } else {
      // Input ← Output: target is source, start is target
      sourceNodeId = targetNodeId;
      sourcePortId = targetPortId;
      actualTargetNodeId = temp.startNodeId;
      actualTargetPortId = temp.startPortId;
    }

    // Check if target port allows multiple connections
    final targetNode = _nodes[actualTargetNodeId];
    if (targetNode != null) {
      final targetPort = targetNode.allPorts
          .where((p) => p.id == actualTargetPortId)
          .firstOrNull;
      if (targetPort != null && !targetPort.multiConnections) {
        // Remove existing connections to target port
        final connectionsToRemove = _connections
            .where(
              (conn) =>
                  conn.targetNodeId == actualTargetNodeId &&
                  conn.targetPortId == actualTargetPortId,
            )
            .toList();
        runInAction(() {
          for (final connection in connectionsToRemove) {
            removeConnection(connection.id);
          }
        });
      }
    }

    // Create the new connection
    final createdConnection = runInAction(() {
      final connection = Connection(
        id: '${sourceNodeId}_${sourcePortId}_${actualTargetNodeId}_$actualTargetPortId',
        sourceNodeId: sourceNodeId,
        sourcePortId: sourcePortId,
        targetNodeId: actualTargetNodeId,
        targetPortId: actualTargetPortId,
      );
      addConnection(connection);

      // Clear temporary connection state and re-enable panning
      // Cursor is derived from state via Observer in widget MouseRegions
      interaction.temporaryConnection.value = null;
      interaction.panEnabled.value = true;

      return connection;
    });

    // Fire connection end event with success
    events.connection?.onConnectEnd?.call(true);

    return createdConnection;
  }

  /// Cancels a connection drag without creating a connection.
  ///
  /// Call this from PortWidget's GestureDetector.onPanEnd when not over a valid target,
  /// or from onPanCancel when the gesture is interrupted.
  void cancelConnectionDrag() {
    // Reset highlighted port before canceling
    final temp = interaction.temporaryConnection.value;
    if (temp != null &&
        temp.targetNodeId != null &&
        temp.targetPortId != null) {
      final targetNode = _nodes[temp.targetNodeId!];
      if (targetNode != null) {
        final targetPort = targetNode.allPorts
            .where((p) => p.id == temp.targetPortId)
            .firstOrNull;
        if (targetPort != null) {
          runInAction(() => targetPort.highlighted.value = false);
        }
      }
    }

    interaction.cancelConnection();

    // Re-enable panning after connection drag ends
    // Cursor is derived from state via Observer in widget MouseRegions
    runInAction(() {
      interaction.panEnabled.value = true;
    });

    // Fire connection end event with failure
    events.connection?.onConnectEnd?.call(false);
  }

  // ---------------------------------------------------------------------------
  // Annotation Drag Operations
  // ---------------------------------------------------------------------------

  /// Starts an annotation drag operation.
  ///
  /// Call this from AnnotationWidget's GestureDetector.onPanStart.
  ///
  /// Parameters:
  /// - [annotationId]: The ID of the annotation being dragged
  void startAnnotationDrag(String annotationId) {
    // Disable panning during annotation drag so InteractiveViewer
    // doesn't steal the gesture from AnnotationWidget's GestureDetector
    runInAction(() {
      interaction.panEnabled.value = false;
    });
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
  void endAnnotationDrag() {
    annotations.internalEndAnnotationDrag();
    // Re-enable panning after annotation drag ends
    runInAction(() {
      interaction.panEnabled.value = true;
    });
  }
}
