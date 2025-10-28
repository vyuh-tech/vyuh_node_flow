part of 'node_flow_controller.dart';

extension NodeFlowControllerAPI<T> on NodeFlowController<T> {
  // Node operations
  void addNode(Node<T> node) {
    runInAction(() {
      _nodes[node.id] = node;
      // Initialize visual position with snapping
      node.setVisualPosition(_config.snapToGridIfEnabled(node.position.value));
    });
    // Fire callback after successful addition
    callbacks.onNodeCreated?.call(node);
  }

  void addInputPort(String nodeId, Port port) {
    final node = _nodes[nodeId];
    if (node == null) return;

    node.addInputPort(port);
  }

  void addOutputPort(String nodeId, Port port) {
    final node = _nodes[nodeId];
    if (node == null) return;

    node.addOutputPort(port);
  }

  void removePort(String nodeId, String portId) {
    final node = _nodes[nodeId];
    if (node == null) return;

    runInAction(() {
      // Remove any connections involving this port
      _connections.removeWhere(
        (c) =>
            (c.sourceNodeId == nodeId && c.sourcePortId == portId) ||
            (c.targetNodeId == nodeId && c.targetPortId == portId),
      );

      // Remove the port using the node's dynamic method
      node.removePort(portId);
    });
  }

  void updateNodePorts(
    String nodeId, {
    List<Port>? inputPorts,
    List<Port>? outputPorts,
  }) {
    final node = _nodes[nodeId];
    if (node == null) return;

    runInAction(() {
      // Update input ports if provided
      if (inputPorts != null) {
        node.inputPorts.clear();
        node.inputPorts.addAll(inputPorts);
      }

      // Update output ports if provided
      if (outputPorts != null) {
        node.outputPorts.clear();
        node.outputPorts.addAll(outputPorts);
      }
    });
  }

  void removeNode(String nodeId) {
    final nodeToDelete = _nodes[nodeId]; // Capture before deletion
    runInAction(() {
      _nodes.remove(nodeId);
      _selectedNodeIds.remove(nodeId);

      // Remove connections involving this node
      _connections.removeWhere(
        (c) => c.sourceNodeId == nodeId || c.targetNodeId == nodeId,
      );

      // Clean up empty group annotations
      // Find all group annotations that contain this node
      final groupsToCheck = <String>[];
      for (final annotation in annotations.annotations.values) {
        if (annotation is GroupAnnotation &&
            annotation.dependencies.contains(nodeId)) {
          // Remove the node from the group's dependencies
          annotation.dependencies.remove(nodeId);
          groupsToCheck.add(annotation.id);
        }
      }

      // Remove any groups that are now empty
      for (final groupId in groupsToCheck) {
        final group = annotations.getAnnotation(groupId);
        if (group is GroupAnnotation && group.dependencies.isEmpty) {
          annotations.removeAnnotation(groupId);
        }
      }
    });
    // Fire callback after successful removal
    if (nodeToDelete != null) {
      callbacks.onNodeDeleted?.call(nodeToDelete);
    }
  }

  void moveNode(String nodeId, Offset delta) {
    final node = _nodes[nodeId];
    if (node != null) {
      runInAction(() {
        final newPosition = node.position.value + delta;
        node.position.value = newPosition;
        // Update visual position with snapping
        node.setVisualPosition(_config.snapToGridIfEnabled(newPosition));
      });
    }
  }

  void moveSelectedNodes(Offset delta) {
    final nodeIds = _selectedNodeIds.toList();
    if (nodeIds.isEmpty) return;

    runInAction(() {
      // Batch position updates
      for (final nodeId in nodeIds) {
        final node = _nodes[nodeId];
        if (node != null) {
          final newPosition = node.position.value + delta;
          node.position.value = newPosition;
          // Update visual position with snapping
          node.setVisualPosition(_config.snapToGridIfEnabled(newPosition));
        }
      }
    });
  }

  // Selection operations
  void selectNode(String nodeId, {bool toggle = false}) {
    runInAction(() {
      // Clear other element types' selections
      clearConnectionSelection();
      annotations.clearAnnotationSelection();

      if (toggle) {
        if (_selectedNodeIds.contains(nodeId)) {
          _selectedNodeIds.remove(nodeId);
          final node = _nodes[nodeId];
          if (node != null) {
            node.selected.value = false;
          }
        } else {
          _selectedNodeIds.add(nodeId);
          final node = _nodes[nodeId];
          if (node != null) {
            node.selected.value = true;
          }
        }
      } else {
        // Clear previous node selection
        clearNodeSelection();

        // Select new node
        _selectedNodeIds.add(nodeId);
        final node = _nodes[nodeId];
        if (node != null) {
          node.selected.value = true;
        }
      }
    });

    // Fire selection callback with current selection state
    final selectedNode = _selectedNodeIds.contains(nodeId)
        ? _nodes[nodeId]
        : null;
    callbacks.onNodeSelected?.call(selectedNode);

    if (!canvasFocusNode.hasFocus) {
      canvasFocusNode.requestFocus();
    }
  }

  void selectNodes(List<String> nodeIds, {bool toggle = false}) {
    runInAction(() {
      // Clear other element types' selections
      clearConnectionSelection();
      annotations.clearAnnotationSelection();

      if (toggle) {
        // Cmd+drag: toggle selection state of intersecting nodes
        for (final nodeId in nodeIds) {
          final node = _nodes[nodeId];
          if (node != null) {
            if (_selectedNodeIds.contains(nodeId)) {
              // Node is selected, deselect it
              _selectedNodeIds.remove(nodeId);
              node.selected.value = false;
            } else {
              // Node is not selected, select it
              _selectedNodeIds.add(nodeId);
              node.selected.value = true;
            }
          }
        }
      } else {
        // Shift+drag: replace selection with intersecting nodes
        clearNodeSelection();

        for (final nodeId in nodeIds) {
          _selectedNodeIds.add(nodeId);
          final node = _nodes[nodeId];
          if (node != null) {
            node.selected.value = true;
          }
        }
      }
    });

    // Request focus only if canvas doesn't already have it
    if (!canvasFocusNode.hasFocus) {
      canvasFocusNode.requestFocus();
    }
  }

  void selectConnection(String connectionId, {bool toggle = false}) {
    runInAction(() {
      // Clear other element types' selections
      clearNodeSelection();
      annotations.clearAnnotationSelection();

      // Find the connection - if it doesn't exist, we can't select it
      final connection = _connections.firstWhere((c) => c.id == connectionId);

      if (toggle) {
        if (_selectedConnectionIds.contains(connectionId)) {
          _selectedConnectionIds.remove(connectionId);
          connection.selected = false;
        } else {
          _selectedConnectionIds.add(connectionId);
          connection.selected = true;
        }
      } else {
        // Clear previous connection selection
        clearConnectionSelection();

        // Select new connection
        _selectedConnectionIds.add(connectionId);
        connection.selected = true;
      }
    });

    // Fire selection callback with current selection state
    final selectedConnection = _selectedConnectionIds.contains(connectionId)
        ? _connections.firstWhere((c) => c.id == connectionId)
        : null;
    callbacks.onConnectionSelected?.call(selectedConnection);

    if (!canvasFocusNode.hasFocus) {
      canvasFocusNode.requestFocus();
    }
  }

  void clearNodeSelection() {
    if (_selectedNodeIds.isEmpty) return;

    for (final id in _selectedNodeIds) {
      final node = _nodes[id];
      if (node != null) {
        node.selected.value = false;
        // Keep z-index elevated (don't reset)
      }
    }
    _selectedNodeIds.clear();

    // Fire selection callback with null to indicate no selection
    callbacks.onNodeSelected?.call(null);
  }

  void clearConnectionSelection() {
    if (_selectedConnectionIds.isEmpty) return;

    for (final id in _selectedConnectionIds) {
      // Find and clear the selected state of each connection
      for (final connection in _connections) {
        if (connection.id == id) {
          connection.selected = false;
          break;
        }
      }
    }
    _selectedConnectionIds.clear();

    // Fire selection callback with null to indicate no selection
    callbacks.onConnectionSelected?.call(null);
  }

  void clearSelection() {
    if (_selectedNodeIds.isEmpty &&
        _selectedConnectionIds.isEmpty &&
        !annotations.hasAnnotationSelection) {
      return;
    }

    runInAction(() {
      clearNodeSelection();
      clearConnectionSelection();
      annotations.clearAnnotationSelection();
    });
  }

  // Graph loading with annotation support
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

    // Update dependent annotations after loading
    annotations.internalUpdateDependentAnnotations(_nodes);
  }

  // Export graph with annotations
  NodeGraph<T> exportGraph() {
    return NodeGraph<T>(
      nodes: _nodes.values.toList(),
      connections: _connections,
      annotations: annotations.sortedAnnotations,
      viewport: _viewport.value,
    );
  }

  // Connection operations
  void addConnection(Connection connection) {
    runInAction(() {
      _connections.add(connection);
    });
    // Fire callback after successful addition
    callbacks.onConnectionCreated?.call(connection);
  }

  void removeConnection(String connectionId) {
    final connectionToDelete = _connections.firstWhere(
      (c) => c.id == connectionId,
      orElse: () => throw ArgumentError('Connection $connectionId not found'),
    );
    runInAction(() {
      _connections.removeWhere((c) => c.id == connectionId);
      _selectedConnectionIds.remove(connectionId);
    });
    // Fire callback after successful removal
    callbacks.onConnectionDeleted?.call(connectionToDelete);
  }

  // Viewport operations
  void setViewport(GraphViewport viewport) {
    // Immediate viewport updates for real-time panning responsiveness
    runInAction(() {
      _viewport.value = viewport;
    });
  }

  void setScreenSize(Size size) {
    runInAction(() {
      _screenSize.value = size;
    });
  }

  /// Zoom while maintaining the viewport center as the focal point
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
  Node<T>? getNode(String nodeId) => _nodes[nodeId];

  bool isNodeSelected(String nodeId) => _selectedNodeIds.contains(nodeId);

  // Annotation methods
  void addAnnotation(Annotation annotation) {
    annotations.addAnnotation(annotation);
    // Fire callback after successful addition
    callbacks.onAnnotationCreated?.call(annotation);
  }

  void removeAnnotation(String annotationId) {
    final annotationToDelete = annotations.getAnnotation(annotationId);
    annotations.removeAnnotation(annotationId);
    // Fire callback after successful removal
    if (annotationToDelete != null) {
      callbacks.onAnnotationDeleted?.call(annotationToDelete);
    }
  }

  Annotation? getAnnotation(String annotationId) =>
      annotations.getAnnotation(annotationId);

  // Public API for selecting annotations
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
    callbacks.onAnnotationSelected?.call(selectedAnnotation);

    canvasFocusNode.requestFocus();
  }

  void clearAnnotationSelection() {
    final hadSelection = annotations.hasAnnotationSelection;
    annotations.clearAnnotationSelection();

    // Fire selection callback with null to indicate no selection
    if (hadSelection) {
      callbacks.onAnnotationSelected?.call(null);
    }
  }

  bool isAnnotationSelected(String annotationId) =>
      annotations.isAnnotationSelected(annotationId);

  // Annotation factory methods for convenience
  StickyAnnotation createStickyNote({
    required Offset position,
    required String text,
    String? id,
    double width = 200.0,
    double height = 100.0,
    Color color = const Color(0xFFFFF59D), // Light yellow
    Offset offset = Offset.zero,
  }) {
    final annotation = annotations.createStickyAnnotation(
      id: id ?? 'sticky-${DateTime.now().millisecondsSinceEpoch}',
      position: position,
      text: text,
      width: width,
      height: height,
      color: color,
      offset: offset,
    );
    addAnnotation(annotation);
    return annotation;
  }

  GroupAnnotation createGroupAnnotation({
    required String title,
    required Set<String> nodeIds,
    String? id,
    EdgeInsets padding = const EdgeInsets.all(20.0),
    Color color = const Color(0xFF2196F3), // Blue
  }) {
    final annotation = annotations.createGroupAnnotation(
      id: id ?? 'group-${DateTime.now().millisecondsSinceEpoch}',
      title: title,
      nodeIds: nodeIds,
      nodes: _nodes, // Pass the nodes map for initial positioning
      padding: padding,
      color: color,
    );
    addAnnotation(annotation);
    return annotation;
  }

  MarkerAnnotation createMarker({
    required Offset position,
    MarkerType markerType = MarkerType.info,
    String? id,
    double size = 24.0,
    Color color = const Color(0xFFF44336), // Red
    String? tooltip,
    Offset offset = Offset.zero,
  }) {
    final annotation = annotations.createMarkerAnnotation(
      id: id ?? 'marker-${DateTime.now().millisecondsSinceEpoch}',
      position: position,
      markerType: markerType,
      size: size,
      color: color,
      tooltip: tooltip,
      offset: offset,
    );
    addAnnotation(annotation);
    return annotation;
  }

  // Annotation bulk operations
  void deleteSelectedAnnotations() => annotations.deleteSelectedAnnotations();

  void hideAllAnnotations() => annotations.hideAllAnnotations();

  void showAllAnnotations() => annotations.showAllAnnotations();

  // Viewport extent methods

  /// Gets the viewport extent as a Rect in world coordinates
  /// This represents the visible area of the graph in world space
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

  /// Gets the viewport extent as a Rect in screen coordinates
  /// This represents the screen area that displays the graph
  Rect get viewportScreenBounds {
    final size = _screenSize.value;
    return Rect.fromLTWH(0, 0, size.width, size.height);
  }

  /// Converts a world coordinate point to screen coordinates
  Offset worldToScreen(Offset worldPoint) {
    final vp = _viewport.value;
    return Offset(
      worldPoint.dx * vp.zoom + vp.x,
      worldPoint.dy * vp.zoom + vp.y,
    );
  }

  /// Converts a screen coordinate point to world coordinates
  Offset screenToWorld(Offset screenPoint) {
    final vp = _viewport.value;
    return Offset(
      (screenPoint.dx - vp.x) / vp.zoom,
      (screenPoint.dy - vp.y) / vp.zoom,
    );
  }

  /// Checks if a world coordinate point is visible in the current viewport
  bool isPointVisible(Offset worldPoint) {
    return viewportExtent.contains(worldPoint);
  }

  /// Checks if a world coordinate rectangle intersects with the viewport
  bool isRectVisible(Rect worldRect) {
    return viewportExtent.overlaps(worldRect);
  }

  /// Gets the bounds of selected nodes in world coordinates
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
      final size = node.size;
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

  void centerOnNode(String nodeId) {
    final node = _nodes[nodeId];
    if (node == null || _screenSize.value == Size.zero) return;

    final pos = node.position.value;
    final size = node.size;
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
        final size = node.size;
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
      size: node.size,
      inputPorts: node.inputPorts,
      outputPorts: node.outputPorts,
    );

    addNode(duplicatedNode);
  }

  // Graph operations
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

    // Clear connection painter cache to prevent stale paths
    _connectionPainter?.clearAllCachedPaths();
  }

  void selectAllNodes() {
    runInAction(() {
      _selectedNodeIds.clear();
      _selectedNodeIds.addAll(_nodes.keys);
      for (final node in _nodes.values) {
        node.selected.value = true;
      }
    });
  }

  void selectAllConnections() {
    runInAction(() {
      _selectedConnectionIds.clear();
      _selectedConnectionIds.addAll(_connections.map((c) => c.id));
    });
  }

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
  void arrangeNodesInGrid({double spacing = 150.0}) {
    final nodeList = _nodes.values.toList();
    final gridSize = math.sqrt(nodeList.length.toDouble()).ceil();

    runInAction(() {
      for (int i = 0; i < nodeList.length; i++) {
        final row = i ~/ gridSize;
        final col = i % gridSize;
        nodeList[i].position.value = Offset(col * spacing, row * spacing);
      }
    });
  }

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
          node.position.value = Offset(x, y);
          x += 200;
        }
        y += 150;
      }
    });
  }

  // Query methods
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
  void deleteNodes(List<String> nodeIds) {
    runInAction(() {
      for (final nodeId in nodeIds) {
        removeNode(nodeId);
      }
    });
  }

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
            newX = rightmost - node.size.width;
            break;
          case NodeAlignment.top:
            // Align top edges - position.dy should equal topmost
            newY = topmost;
            break;
          case NodeAlignment.bottom:
            // Align bottom edges - position.dy + height should equal bottommost
            newY = bottommost - node.size.height;
            break;
          case NodeAlignment.center:
            // Align center points on both axes
            newX = centerX - node.size.width / 2;
            newY = centerY - node.size.height / 2;
            break;
          case NodeAlignment.horizontalCenter:
            // Align center points horizontally only
            newX = centerX - node.size.width / 2;
            // Keep original Y position
            break;
          case NodeAlignment.verticalCenter:
            // Align center points vertically only
            newY = centerY - node.size.height / 2;
            // Keep original X position
            break;
        }

        final newPosition = Offset(newX, newY);
        node.position.value = newPosition;
        // Update visual position with snapping
        node.setVisualPosition(_config.snapToGridIfEnabled(newPosition));
      }
    });
  }

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
        nodes[i].position.value = Offset(targetX, nodes[i].position.value.dy);
      }
    });
  }

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
        nodes[i].position.value = Offset(nodes[i].position.value.dx, targetY);
      }
    });
  }

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

  void deleteAllConnectionsForNode(String nodeId) {
    final connectionsToRemove = _connections
        .where(
          (conn) => conn.sourceNodeId == nodeId || conn.targetNodeId == nodeId,
        )
        .toList();

    runInAction(() {
      for (final conn in connectionsToRemove) {
        _connections.remove(conn);
      }
    });
  }

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

  void setNodePosition(String nodeId, Offset position) {
    final node = _nodes[nodeId];
    if (node != null) {
      runInAction(() {
        node.position.value = position;
        // Update visual position with snapping
        node.setVisualPosition(_config.snapToGridIfEnabled(position));
      });
    }
  }

  List<Connection> getConnectionsForNode(String nodeId) {
    return _connections
        .where(
          (conn) => conn.sourceNodeId == nodeId || conn.targetNodeId == nodeId,
        )
        .toList();
  }

  // Computed properties
  Rect get nodesBounds {
    if (_nodes.isEmpty) return Rect.zero;

    double minX = double.infinity;
    double minY = double.infinity;
    double maxX = double.negativeInfinity;
    double maxY = double.negativeInfinity;

    for (final node in _nodes.values) {
      final pos = node.position.value;
      final size = node.size;
      minX = math.min(minX, pos.dx);
      minY = math.min(minY, pos.dy);
      maxX = math.max(maxX, pos.dx + size.width);
      maxY = math.max(maxY, pos.dy + size.height);
    }

    return Rect.fromLTRB(minX, minY, maxX, maxY);
  }

  double get currentZoom => _viewport.value.zoom;
  Offset get currentPan => Offset(_viewport.value.x, _viewport.value.y);

  // Analysis methods
  /// Test if a point hits any connection
  /// Returns the connection ID if hit, null otherwise
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

  /// Show the keyboard shortcuts dialog
  ///
  /// Displays a comprehensive dialog showing all available keyboard shortcuts
  /// organized by category for easy reference.
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

  /// Set the theme and initialize the connection painter
  /// This is called internally by the editor widget only
  void setTheme(NodeFlowTheme theme) {
    _theme = theme;
    _connectionPainter ??= ConnectionPainter(theme: theme);
  }

  /// Update the callbacks that the controller will use
  /// This is called internally by the editor widget only
  void setCallbacks(NodeFlowCallbacks<T> callbacks) {
    _callbacks = callbacks;
  }

  /// Hit test annotations at a specific position
  /// This is a delegating method for the editor's hit testing
  Annotation? hitTestAnnotations(Offset graphPosition) {
    return annotations.internalHitTestAnnotations(graphPosition);
  }
}
