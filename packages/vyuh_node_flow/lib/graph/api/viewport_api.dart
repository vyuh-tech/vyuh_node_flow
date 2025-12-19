part of '../node_flow_controller.dart';

/// Viewport operations for [NodeFlowController].
///
/// This extension provides methods for:
/// - Viewport state management (get/set viewport, zoom, pan)
/// - Coordinate transformations (screen ↔ world)
/// - Navigation (center, fit to view, focus on nodes)
/// - Visibility queries (is point/rect visible)
/// - Screen and mouse position tracking
extension ViewportApi<T> on NodeFlowController<T> {
  // ============================================================================
  // Viewport State
  // ============================================================================

  /// Gets the current zoom level of the viewport.
  ///
  /// Returns the current zoom level (1.0 = 100%, 2.0 = 200%, etc.).
  double get currentZoom => _viewport.value.zoom;

  /// Gets the current pan position of the viewport.
  ///
  /// Returns the viewport's translation as an Offset.
  Offset get currentPan => Offset(_viewport.value.x, _viewport.value.y);

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

  // ============================================================================
  // Coordinate Transformations
  // ============================================================================

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

  // ============================================================================
  // Zoom Operations
  // ============================================================================

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

  // ============================================================================
  // Pan Operations
  // ============================================================================

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

  // ============================================================================
  // Navigation
  // ============================================================================

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

  // ============================================================================
  // Viewport Extent & Visibility
  // ============================================================================

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

  /// Helper method to calculate bounds for a collection of nodes.
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

  // ============================================================================
  // Mouse Position Tracking
  // ============================================================================

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
}
