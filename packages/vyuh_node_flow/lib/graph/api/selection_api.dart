part of '../node_flow_controller.dart';

/// Selection-related operations for [NodeFlowController].
///
/// This extension provides methods for:
/// - Selecting and deselecting nodes
/// - Selecting and deselecting connections
/// - Clearing selections
/// - Managing multi-selection state
extension SelectionApi<T> on NodeFlowController<T> {
  // ============================================================================
  // Node Selection
  // ============================================================================

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
    events.node?.onSelected?.call(selectedNode);

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

    // Fire selection event with null to indicate no selection
    events.node?.onSelected?.call(null);
  }

  // ============================================================================
  // Connection Selection
  // ============================================================================

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
    events.connection?.onSelected?.call(selectedConnection);

    if (!canvasFocusNode.hasFocus) {
      canvasFocusNode.requestFocus();
    }
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

    // Fire selection event with null to indicate no selection
    events.connection?.onSelected?.call(null);
  }

  // ============================================================================
  // Combined Selection Operations
  // ============================================================================

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
}
