part of 'node_flow_controller.dart';

/// Factory methods and drag operations for [NodeFlowController].
///
/// This extension provides methods for:
/// - Factory methods for creating GroupNode and CommentNode
/// - Widget-level drag operations for nodes and connections
/// - Utility methods for group operations
extension NodeFlowControllerAPI<T> on NodeFlowController<T> {
  // ============================================================================
  // GroupNode and CommentNode Factory Methods
  // ============================================================================

  /// Creates and adds a comment node to the graph.
  ///
  /// Comment nodes are floating text elements that can be placed anywhere on the canvas.
  /// They support inline editing and auto-grow when text exceeds bounds.
  ///
  /// Parameters:
  /// - [position]: Position in graph coordinates
  /// - [text]: The text content of the comment
  /// - [data]: Custom data of type [T] associated with this node
  /// - [id]: Optional custom ID (auto-generated if not provided)
  /// - [width]: Width of the comment (default: 200.0)
  /// - [height]: Height of the comment (default: 100.0)
  /// - [color]: Background color (default: light yellow)
  ///
  /// Returns the created [CommentNode].
  ///
  /// Example:
  /// ```dart
  /// controller.createCommentNode(
  ///   position: Offset(100, 100),
  ///   text: 'Important note here',
  ///   data: MyNodeData(),
  ///   color: Colors.yellow,
  /// );
  /// ```
  CommentNode<T> createCommentNode({
    required Offset position,
    required String text,
    required T data,
    String? id,
    double width = 200.0,
    double height = 100.0,
    Color color = const Color(0xFFFFF59D), // Light yellow
  }) {
    final node = CommentNode<T>(
      id: id ?? 'comment-${DateTime.now().millisecondsSinceEpoch}',
      position: position,
      text: text,
      data: data,
      width: width,
      height: height,
      color: color,
    );
    addNode(node);
    return node;
  }

  /// Creates and adds a group node that visually groups multiple nodes.
  ///
  /// Group nodes create visual boundaries that can contain nodes. The behavior
  /// determines how node membership is managed (see [GroupBehavior]).
  ///
  /// Parameters:
  /// - [title]: Title displayed at the top of the group
  /// - [position]: Position in graph coordinates
  /// - [size]: Size of the group
  /// - [data]: Custom data of type [T] associated with this node
  /// - [id]: Optional custom ID (auto-generated if not provided)
  /// - [color]: Background color of the group (default: blue)
  /// - [behavior]: How the group manages node membership (default: bounds)
  /// - [nodeIds]: Initial set of node IDs for explicit/parent behavior
  /// - [padding]: Padding around member nodes (default: kGroupNodeDefaultPadding)
  /// - [inputPorts]: Optional input ports for subflow patterns
  /// - [outputPorts]: Optional output ports for subflow patterns
  ///
  /// Returns the created [GroupNode].
  ///
  /// Example:
  /// ```dart
  /// controller.createGroupNode(
  ///   title: 'Input Processing',
  ///   position: Offset(100, 100),
  ///   size: Size(400, 300),
  ///   data: MyNodeData(),
  ///   color: Colors.blue,
  /// );
  /// ```
  GroupNode<T> createGroupNode({
    required String title,
    required Offset position,
    required Size size,
    required T data,
    String? id,
    Color color = const Color(0xFF2196F3), // Blue
    GroupBehavior behavior = GroupBehavior.bounds,
    Set<String>? nodeIds,
    EdgeInsets padding = kGroupNodeDefaultPadding,
    List<Port> inputPorts = const [],
    List<Port> outputPorts = const [],
  }) {
    final node = GroupNode<T>(
      id: id ?? 'group-${DateTime.now().millisecondsSinceEpoch}',
      title: title,
      position: position,
      size: size,
      data: data,
      color: color,
      behavior: behavior,
      nodeIds: nodeIds,
      padding: padding,
      inputPorts: inputPorts,
      outputPorts: outputPorts,
    );
    addNode(node);
    return node;
  }

  /// Creates and adds a group node that surrounds the specified nodes.
  ///
  /// This is a convenience method that calculates the bounding box of the
  /// given nodes and creates a group that encompasses them with padding.
  ///
  /// Parameters:
  /// - [title]: Display title for the group header
  /// - [nodeIds]: Set of node IDs to surround
  /// - [data]: Custom data of type [T] associated with this node
  /// - [id]: Optional custom ID (auto-generated if not provided)
  /// - [padding]: Space between the group boundary and the nodes (default: 20.0)
  /// - [color]: Background color of the group (default: blue)
  /// - [behavior]: How the group manages node membership (default: bounds)
  /// - [inputPorts]: Optional input ports for subflow patterns
  /// - [outputPorts]: Optional output ports for subflow patterns
  ///
  /// Returns the created [GroupNode].
  ///
  /// Example:
  /// ```dart
  /// controller.createGroupNodeAroundNodes(
  ///   title: 'Input Processing',
  ///   nodeIds: {'node1', 'node2', 'node3'},
  ///   data: MyNodeData(),
  ///   padding: EdgeInsets.all(30),
  ///   color: Colors.blue,
  /// );
  /// ```
  GroupNode<T> createGroupNodeAroundNodes({
    required String title,
    required Set<String> nodeIds,
    required T data,
    String? id,
    EdgeInsets padding = const EdgeInsets.all(20.0),
    Color color = const Color(0xFF2196F3), // Blue
    GroupBehavior behavior = GroupBehavior.bounds,
    List<Port> inputPorts = const [],
    List<Port> outputPorts = const [],
  }) {
    final dependentNodes = nodeIds
        .map((nodeId) => _nodes[nodeId])
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

    final node = GroupNode<T>(
      id: id ?? 'group-${DateTime.now().millisecondsSinceEpoch}',
      position: initialPosition,
      size: initialSize,
      title: title,
      data: data,
      color: color,
      behavior: behavior,
      nodeIds: behavior != GroupBehavior.bounds ? nodeIds : null,
      padding: padding,
      inputPorts: inputPorts,
      outputPorts: outputPorts,
    );
    addNode(node);
    return node;
  }

  // ============================================================================
  // Group Utility Methods
  // ============================================================================

  /// Finds all nodes that are completely contained within a group's bounds.
  ///
  /// This implements the fluid containment rule: a node is part of a group
  /// if and only if its bounding box is completely within the group's bounds.
  Set<String> findContainedNodes(GroupNode<T> group) {
    return _findNodesInBounds(group.bounds);
  }

  /// Hides all group and comment nodes.
  ///
  /// Hidden nodes are not rendered but remain in the graph data.
  void hideAllAnnotationNodes() {
    runInAction(() {
      for (final node in _nodes.values) {
        if (node is GroupNode || node is CommentNode) {
          node.isVisible = false;
        }
      }
    });
  }

  /// Shows all group and comment nodes.
  ///
  /// This makes all previously hidden annotation nodes visible again.
  void showAllAnnotationNodes() {
    runInAction(() {
      for (final node in _nodes.values) {
        if (node is GroupNode || node is CommentNode) {
          node.isVisible = true;
        }
      }
    });
  }

  // ============================================================================
  // Widget-Level Drag API
  // ============================================================================
  //
  // These methods are designed to be called directly by widgets (NodeWidget,
  // PortWidget) to handle drag operations. This eliminates callback chains
  // and gives widgets direct controller access.

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
  /// - Notifies monitoring nodes (like GroupNode) of drag start
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

    // Notify monitoring nodes of drag start
    final context = _createDragContext();
    for (final id
        in selectedNodeIds.contains(nodeId)
            ? selectedNodeIds.toList()
            : [nodeId]) {
      _nodes[id]?.onDragStart(context);
    }

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

    // Get nodes to move
    final nodeIdsToMove = selectedNodeIds.contains(draggedNodeId)
        ? selectedNodeIds.toList()
        : [draggedNodeId];

    final context = _createDragContext();

    runInAction(() {
      // Update node positions and visual positions
      for (final nodeId in nodeIdsToMove) {
        final node = _nodes[nodeId];
        if (node != null) {
          final newPosition = node.position.value + graphDelta;
          node.position.value = newPosition;
          // Update visual position with snapping
          node.setVisualPosition(_config.snapToGridIfEnabled(newPosition));
          movedNodes.add(node);

          // Notify the node of its own drag move
          node.onDragMove(graphDelta, context);
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

    // Notify nodes of drag end
    for (final node in draggedNodes) {
      node.onDragEnd();
    }

    // Ensure proper z-ordering for nested groups after drag
    _ensureNestedGroupZOrdering(draggedNodes);

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

  /// Ensures dragged groups that are now inside other groups have proper z-ordering.
  ///
  /// When a group is dragged into another group, the child group's z-index must be
  /// higher than the parent group's z-index so it renders on top and remains clickable.
  void _ensureNestedGroupZOrdering(List<Node<T>> draggedNodes) {
    // Get all group nodes
    final allGroups = _nodes.values.whereType<GroupNode<T>>().toList();
    if (allGroups.length < 2) return; // Need at least 2 groups for nesting

    runInAction(() {
      // For each dragged group, check if it's now inside another group
      for (final draggedNode in draggedNodes) {
        if (draggedNode is! GroupNode<T>) continue;

        final draggedGroup = draggedNode;
        final draggedBounds = draggedGroup.bounds;

        // Check against all other groups
        for (final parentGroup in allGroups) {
          if (parentGroup.id == draggedGroup.id) continue;

          final parentBounds = parentGroup.bounds;

          // Check if dragged group is completely inside parent group
          if (parentBounds.contains(draggedBounds.topLeft) &&
              parentBounds.contains(draggedBounds.bottomRight)) {
            // Dragged group is inside parent - ensure it has higher z-index
            if (draggedGroup.zIndex.value <= parentGroup.zIndex.value) {
              draggedGroup.zIndex.value = parentGroup.zIndex.value + 1;
            }
          }
        }
      }
    });
  }
}
