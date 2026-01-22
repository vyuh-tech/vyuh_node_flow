part of 'node_flow_controller.dart';

/// Factory methods and drag operations for [NodeFlowController].
///
/// This extension provides methods for:
/// - Factory methods for creating GroupNode and CommentNode
/// - Widget-level drag operations for nodes and connections
/// - Utility methods for group operations
extension NodeFlowControllerAPI<T, C> on NodeFlowController<T, C> {
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

  /// Hides all [GroupNode] and [CommentNode] instances.
  ///
  /// Hidden nodes are not rendered but remain in the graph data.
  void hideAllGroupAndCommentNodes() {
    runInAction(() {
      for (final node in _nodes.values) {
        if (node is GroupNode || node is CommentNode) {
          node.isVisible = false;
        }
      }
    });
  }

  /// Shows all [GroupNode] and [CommentNode] instances.
  ///
  /// This makes all previously hidden group and comment nodes visible again.
  void showAllGroupAndCommentNodes() {
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
  /// - Sets up drag state
  /// - Fires the drag start event
  /// - Notifies monitoring nodes (like GroupNode) of drag start
  ///
  /// Note: Canvas locking is handled by [DragSession], not this method.
  /// Widgets should create a session and call [DragSession.start] to lock canvas.
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

      // Note: Canvas locking is now handled by DragSession

      // Update visual dragging state on all affected nodes
      final nodeIds = selectedNodeIds.contains(nodeId)
          ? selectedNodeIds.toList()
          : [nodeId];
      for (final id in nodeIds) {
        _nodes[id]?.dragging.value = true;
      }
    });

    // Notify monitoring nodes of drag start
    final context = _createDragContext();
    final nodeIds = selectedNodeIds.contains(nodeId)
        ? selectedNodeIds.toList()
        : [nodeId];
    for (final id in nodeIds) {
      _nodes[id]?.onDragStart(context);
    }

    // Capture original positions for extension events
    final originalPositions = <String, Offset>{};
    for (final id in nodeIds) {
      final n = _nodes[id];
      if (n != null) {
        originalPositions[id] = n.position.value;
      }
    }
    interaction.captureDragStartPositions(originalPositions);

    // Fire drag start event
    final node = _nodes[nodeId];
    if (node != null) {
      events.node?.onDragStart?.call(node);
    }

    // Emit extension event
    _emitEvent(
      NodeDragStarted(nodeIds.toSet(), node?.position.value ?? Offset.zero),
    );

    // Notify snap delegate
    _snapDelegate?.onDragStart(nodeIds.toSet());
  }

  /// Moves nodes during a drag operation.
  ///
  /// Call this from NodeWidget's GestureDetector.onPanUpdate. The delta
  /// is already in graph coordinates since GestureDetector is inside
  /// InteractiveViewer's transformed space - no conversion needed.
  ///
  /// ## Position Model
  ///
  /// This method uses a two-position model:
  /// - **position**: The user's intended position (accumulates raw deltas)
  /// - **visualPosition**: The displayed position (may be snapped)
  ///
  /// The snap delegate transforms intended → visual position. This prevents
  /// "sticky snap" behavior where small movements can't escape a snap point.
  ///
  /// The method applies snapping in this order:
  /// 1. Snap delegate (alignment guides to other nodes)
  /// 2. Snap-to-grid (quantizes final position if enabled in config)
  ///
  /// Parameters:
  /// - [graphDelta]: The movement delta in graph coordinates
  void moveNodeDrag(Offset graphDelta) {
    final draggedNodeId = interaction.draggedNodeId.value;
    if (draggedNodeId == null) return;

    // Get nodes to move
    final nodeIdsToMove = selectedNodeIds.contains(draggedNodeId)
        ? selectedNodeIds.toSet()
        : {draggedNodeId};

    // Collect nodes that will be moved for event firing
    final movedNodes = <Node<T>>[];
    final context = _createDragContext();

    // First pass: Update all nodes' intended positions (raw movement)
    runInAction(() {
      for (final nodeId in nodeIdsToMove) {
        final node = _nodes[nodeId];
        if (node != null) {
          node.position.value = node.position.value + graphDelta;
          movedNodes.add(node);
        }
      }
    });

    // Get the primary node's intended position for snap calculation
    final primaryNode = _nodes[draggedNodeId];
    final intendedPosition = primaryNode?.position.value ?? Offset.zero;

    // Calculate snap adjustment
    var snappingX = false;
    var snappingY = false;
    var snapDelta = Offset.zero;

    if (_snapDelegate != null) {
      final snapResult = _snapDelegate!.snapPosition(
        draggedNodeIds: nodeIdsToMove,
        intendedPosition: intendedPosition,
        visibleBounds: visibleGraphBounds,
      );

      // Calculate the delta between intended and snapped positions
      // This delta will be applied to all selected nodes to maintain relative positions
      snapDelta = snapResult.position - intendedPosition;
      snappingX = snapResult.snappingX;
      snappingY = snapResult.snappingY;
    }

    // Second pass: Apply visual positions to all moved nodes
    runInAction(() {
      for (final node in movedNodes) {
        // Visual position = intended position + snap delta
        final snappedPosition = node.position.value + snapDelta;

        // Apply grid snapping only to axes not handled by snap delegate
        // This allows alignment snap (when active) to take priority over grid snap
        final visualPosition = _applyGridSnapPerAxis(
          snappedPosition,
          skipX: snappingX,
          skipY: snappingY,
        );
        node.setVisualPosition(visualPosition);

        // Notify the node of its own drag move
        node.onDragMove(graphDelta, context);
      }
    });

    // Mark moved nodes dirty for spatial index
    _markNodesDirty(movedNodes.map((n) => n.id));

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

    // Capture original positions before clearing them
    final originalPositions = Map<String, Offset>.from(
      interaction.dragStartPositions,
    );

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

      // Note: Canvas unlocking is now handled by DragSession
    });

    // Clear original positions tracking
    interaction.clearDragStartPositions();

    // Rebuild connection segments with accurate path bounds after drag ends
    if (draggedNodeIds.isNotEmpty) {
      rebuildConnectionSegmentsForNodes(draggedNodeIds);
    }

    // Fire drag stop event for all dragged nodes
    for (final node in draggedNodes) {
      events.node?.onDragStop?.call(node);
    }

    // Emit extension event with original positions for undo/redo
    if (draggedNodeIds.isNotEmpty) {
      _emitEvent(NodeDragEnded(draggedNodeIds.toSet(), originalPositions));
    }

    // Notify snap delegate
    _snapDelegate?.onDragEnd();
  }

  /// Cancels a node drag operation and reverts to original positions.
  ///
  /// Call this to abort a drag and restore nodes to their positions before
  /// the drag started. The caller provides the original positions since
  /// the widget that initiated the drag owns that state.
  ///
  /// Parameters:
  /// - [originalPositions]: Map of node ID to original position before drag
  void cancelNodeDrag(Map<String, Offset> originalPositions) {
    // Capture dragged nodes before clearing state
    final draggedNodes = <Node<T>>[];
    for (final node in _nodes.values) {
      if (node.dragging.value) {
        draggedNodes.add(node);
      }
    }

    // Revert positions
    runInAction(() {
      for (final entry in originalPositions.entries) {
        final node = _nodes[entry.key];
        if (node != null) {
          node.position.value = entry.value;
          node.setVisualPosition(snapToGrid(entry.value));
        }
      }

      // Clear dragging state on nodes
      for (final node in draggedNodes) {
        node.dragging.value = false;
      }

      // Clear drag state
      interaction.draggedNodeId.value = null;
      interaction.lastPointerPosition.value = null;

      // Note: Canvas unlocking is now handled by DragSession
    });

    // Rebuild connection segments
    if (originalPositions.isNotEmpty) {
      rebuildConnectionSegmentsForNodes(originalPositions.keys.toList());
    }

    // Fire drag cancel event for all dragged nodes
    for (final node in draggedNodes) {
      events.node?.onDragCancel?.call(node);
    }

    // Notify snap delegate
    _snapDelegate?.onDragEnd();
  }

  /// Applies grid snapping per-axis, allowing some axes to be skipped.
  ///
  /// This enables alignment snapping to take priority on specific axes
  /// while still applying grid snap to the remaining axes.
  Offset _applyGridSnapPerAxis(Offset position, {
    bool skipX = false,
    bool skipY = false,
  }) {
    // Get snap extension and grid delegate
    SnapExtension? snapExt;
    GridSnapDelegate? gridDelegate;
    final delegate = _snapDelegate;
    if (delegate is SnapExtension) {
      snapExt = delegate;
      gridDelegate = delegate.gridSnapDelegate;
    } else if (delegate is GridSnapDelegate) {
      gridDelegate = delegate;
    }

    // Fall back to extension registry (for unit tests without initController)
    if (gridDelegate == null) {
      snapExt = _config.extensionRegistry.get<SnapExtension>();
      gridDelegate = snapExt?.gridSnapDelegate;
    }

    // If no grid delegate or snap extension not enabled, return unchanged
    if (gridDelegate == null) return position;
    if (snapExt != null && !snapExt.enabled) return position;

    final grid = gridDelegate.gridSize;
    final snappedX = skipX ? position.dx : (position.dx / grid).round() * grid;
    final snappedY = skipY ? position.dy : (position.dy / grid).round() * grid;

    return Offset(snappedX.toDouble(), snappedY.toDouble());
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
