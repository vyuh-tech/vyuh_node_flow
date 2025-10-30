part of 'node_flow_controller.dart';

extension NodeFlowControllerAPI<T> on NodeFlowController<T> {
  // Node operations

  /// Adds a new node to the graph.
  ///
  /// The node's position will be automatically snapped to the grid if snap-to-grid
  /// is enabled in the controller's configuration.
  ///
  /// Triggers the `onNodeCreated` callback after successful addition.
  ///
  /// Example:
  /// ```dart
  /// final node = Node<MyData>(
  ///   id: 'node1',
  ///   type: 'process',
  ///   position: Offset(100, 100),
  ///   data: MyData(),
  /// );
  /// controller.addNode(node);
  /// ```
  void addNode(Node<T> node) {
    runInAction(() {
      _nodes[node.id] = node;
      // Initialize visual position with snapping
      node.setVisualPosition(_config.snapToGridIfEnabled(node.position.value));
    });
    // Fire callback after successful addition
    callbacks.onNodeCreated?.call(node);
  }

  /// Adds an input port to an existing node.
  ///
  /// Does nothing if the node with [nodeId] doesn't exist.
  ///
  /// Parameters:
  /// - [nodeId]: The ID of the node to add the port to
  /// - [port]: The port to add
  void addInputPort(String nodeId, Port port) {
    final node = _nodes[nodeId];
    if (node == null) return;

    node.addInputPort(port);
  }

  /// Adds an output port to an existing node.
  ///
  /// Does nothing if the node with [nodeId] doesn't exist.
  ///
  /// Parameters:
  /// - [nodeId]: The ID of the node to add the port to
  /// - [port]: The port to add
  void addOutputPort(String nodeId, Port port) {
    final node = _nodes[nodeId];
    if (node == null) return;

    node.addOutputPort(port);
  }

  /// Removes a port from a node and all connections involving that port.
  ///
  /// This method will:
  /// 1. Remove all connections where this port is the source or target
  /// 2. Remove the port from the node
  ///
  /// Does nothing if the node with [nodeId] doesn't exist.
  ///
  /// Parameters:
  /// - [nodeId]: The ID of the node containing the port
  /// - [portId]: The ID of the port to remove
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

  /// Updates the input and/or output ports of a node.
  ///
  /// This replaces the existing ports with the provided lists. Pass `null` to
  /// leave a port type unchanged.
  ///
  /// Does nothing if the node with [nodeId] doesn't exist.
  ///
  /// Parameters:
  /// - [nodeId]: The ID of the node to update
  /// - [inputPorts]: New list of input ports (optional)
  /// - [outputPorts]: New list of output ports (optional)
  ///
  /// Example:
  /// ```dart
  /// controller.updateNodePorts(
  ///   'node1',
  ///   inputPorts: [Port(id: 'in1', label: 'Input')],
  ///   outputPorts: [Port(id: 'out1', label: 'Output')],
  /// );
  /// ```
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

  /// Removes a node from the graph along with all its connections.
  ///
  /// This method will:
  /// 1. Remove the node from the graph
  /// 2. Remove it from the selection if selected
  /// 3. Remove all connections involving this node
  /// 4. Remove the node from any group annotations
  /// 5. Delete empty group annotations that no longer contain any nodes
  ///
  /// Triggers the `onNodeDeleted` callback after successful removal.
  ///
  /// Parameters:
  /// - [nodeId]: The ID of the node to remove
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

  /// Moves a node by the specified delta.
  ///
  /// The node's new position will be automatically snapped to the grid if
  /// snap-to-grid is enabled in the controller's configuration.
  ///
  /// Does nothing if the node doesn't exist.
  ///
  /// Parameters:
  /// - [nodeId]: The ID of the node to move
  /// - [delta]: The offset to move the node by
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

  /// Moves all selected nodes by the specified delta.
  ///
  /// The nodes' new positions will be automatically snapped to the grid if
  /// snap-to-grid is enabled in the controller's configuration.
  ///
  /// Does nothing if no nodes are selected.
  ///
  /// Parameters:
  /// - [delta]: The offset to move the selected nodes by
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

  /// Selects a node in the graph.
  ///
  /// Automatically clears selections of other element types (connections, annotations).
  /// Requests canvas focus if not already focused.
  ///
  /// Triggers the `onNodeSelected` callback after selection changes.
  ///
  /// Parameters:
  /// - [nodeId]: The ID of the node to select
  /// - [toggle]: If `true`, toggles the node's selection state. If `false` (default),
  ///   clears other node selections and selects only this node.
  ///
  /// Example:
  /// ```dart
  /// // Select single node
  /// controller.selectNode('node1');
  ///
  /// // Toggle node selection (for multi-select)
  /// controller.selectNode('node2', toggle: true);
  /// ```
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

  /// Selects multiple nodes in the graph.
  ///
  /// Automatically clears selections of other element types (connections, annotations).
  /// Requests canvas focus if not already focused.
  ///
  /// Parameters:
  /// - [nodeIds]: List of node IDs to select
  /// - [toggle]: If `true`, toggles each node's selection state. If `false` (default),
  ///   replaces current selection with the provided nodes.
  ///
  /// Example:
  /// ```dart
  /// // Replace selection with multiple nodes
  /// controller.selectNodes(['node1', 'node2', 'node3']);
  ///
  /// // Toggle multiple nodes (for multi-select)
  /// controller.selectNodes(['node4', 'node5'], toggle: true);
  /// ```
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

  /// Selects a connection in the graph.
  ///
  /// Automatically clears selections of other element types (nodes, annotations).
  /// Requests canvas focus if not already focused.
  ///
  /// Triggers the `onConnectionSelected` callback after selection changes.
  ///
  /// Parameters:
  /// - [connectionId]: The ID of the connection to select
  /// - [toggle]: If `true`, toggles the connection's selection state. If `false`
  ///   (default), clears other connection selections and selects only this connection.
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

  /// Clears all node selections.
  ///
  /// Triggers the `onNodeSelected` callback with `null` to indicate no selection.
  ///
  /// Does nothing if no nodes are currently selected.
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

  /// Clears all connection selections.
  ///
  /// Triggers the `onConnectionSelected` callback with `null` to indicate no selection.
  ///
  /// Does nothing if no connections are currently selected.
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

  /// Clears all selections (nodes, connections, and annotations).
  ///
  /// This is a convenience method that calls `clearNodeSelection`,
  /// `clearConnectionSelection`, and `clearAnnotationSelection`.
  ///
  /// Does nothing if there are no active selections.
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

    // Update dependent annotations after loading
    annotations.internalUpdateDependentAnnotations(_nodes);
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

  // Connection operations

  /// Adds a connection between two ports.
  ///
  /// Triggers the `onConnectionCreated` callback after successful addition.
  ///
  /// Parameters:
  /// - [connection]: The connection to add
  ///
  /// Example:
  /// ```dart
  /// final connection = Connection(
  ///   id: 'conn1',
  ///   sourceNodeId: 'node1',
  ///   sourcePortId: 'out1',
  ///   targetNodeId: 'node2',
  ///   targetPortId: 'in1',
  /// );
  /// controller.addConnection(connection);
  /// ```
  void addConnection(Connection connection) {
    runInAction(() {
      _connections.add(connection);
    });
    // Fire callback after successful addition
    callbacks.onConnectionCreated?.call(connection);
  }

  /// Removes a connection from the graph.
  ///
  /// Also removes the connection from the selection set if it was selected.
  ///
  /// Triggers the `onConnectionDeleted` callback after successful removal.
  ///
  /// Parameters:
  /// - [connectionId]: The ID of the connection to remove
  ///
  /// Throws [ArgumentError] if the connection doesn't exist.
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
    // Fire callback after successful addition
    callbacks.onAnnotationCreated?.call(annotation);
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
    // Fire callback after successful removal
    if (annotationToDelete != null) {
      callbacks.onAnnotationDeleted?.call(annotationToDelete);
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
    callbacks.onAnnotationSelected?.call(selectedAnnotation);

    canvasFocusNode.requestFocus();
  }

  /// Clears all annotation selections.
  ///
  /// Triggers the `onAnnotationSelected` callback with `null` if there was a selection.
  void clearAnnotationSelection() {
    final hadSelection = annotations.hasAnnotationSelection;
    annotations.clearAnnotationSelection();

    // Fire selection callback with null to indicate no selection
    if (hadSelection) {
      callbacks.onAnnotationSelected?.call(null);
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
  ///   nodeIds: {'node1', 'node2', 'node3'},
  ///   color: Colors.blue.withOpacity(0.2),
  /// );
  /// ```
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
      nodes: _nodes,
      // Pass the nodes map for initial positioning
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
      size: node.size,
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
        nodeList[i].position.value = Offset(col * spacing, row * spacing);
      }
    });
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
          node.position.value = Offset(x, y);
          x += 200;
        }
        y += 150;
      }
    });
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
        nodes[i].position.value = Offset(targetX, nodes[i].position.value.dy);
      }
    });
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
        nodes[i].position.value = Offset(nodes[i].position.value.dx, targetY);
      }
    });
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
      final size = node.size;
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
    _theme = theme;

    // Create painter if it doesn't exist, otherwise update its theme
    if (_connectionPainter == null) {
      _connectionPainter = ConnectionPainter(theme: theme);
    } else {
      _connectionPainter!.updateTheme(theme);
    }
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
