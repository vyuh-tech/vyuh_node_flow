import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:mobx/mobx.dart';
import 'package:vyuh_node_flow/vyuh_node_flow.dart';

import '../models.dart';
import '../state.dart';
import '../utils.dart';
import 'node_factory.dart';

/// The primary canvas widget for the math node graph editor.
///
/// Bridges MobX state ([MathState]) with the [NodeFlowController], handling:
/// - Bidirectional sync between state and controller (nodes, connections)
/// - Drag-aware deferred updates to prevent UI flickering during interactions
/// - Connection validation (self-loops, cycles, port limits)
/// - Automatic fit-to-view on first render
class MathCanvas extends StatefulWidget {
  final MathState state;
  final NodeFlowTheme theme;

  const MathCanvas({super.key, required this.state, required this.theme});

  @override
  State<MathCanvas> createState() => _MathCanvasState();
}

class _MathCanvasState extends State<MathCanvas> {
  late final NodeFlowController<MathNodeData, dynamic> _controller;
  final List<ReactionDisposer> _reactions = [];
  bool _isInitialized = false;

  // Pending sync operations that were deferred during drag
  bool _pendingNodeDataSync = false;
  bool _pendingConnectionSync = false;

  // Track previous drag state to detect drag end
  String? _previousDraggedNodeId;

  MathState get state => widget.state;

  @override
  void initState() {
    super.initState();

    _controller = NodeFlowController<MathNodeData, dynamic>(
      config: NodeFlowConfig(
        snapToGrid: false,
        gridSize: 20.0,
        minZoom: 0.25,
        maxZoom: 2.0,
      ),
    );

    _setupReactions();
  }

  /// Configures MobX reactions to sync MathState changes to NodeFlowController.
  ///
  /// Reactions are organized by sync type:
  /// 1. Node list changes (add/remove) - safe during drag
  /// 2. Node data changes (values, operators) - deferred during drag
  /// 3. Connection changes - deferred during drag
  /// 4. Drag-end handler - flushes pending syncs after drag completes
  void _setupReactions() {
    // Node list sync: fires when nodes are added/removed
    _reactions.add(
      reaction(
        (_) => state.nodes.map((n) => n.id).join('|'),
        (_) => _syncNodesToController(),
        fireImmediately: true,
      ),
    );

    // Node data sync: tracks signature changes (value edits, operator toggles)
    _reactions.add(
      reaction((_) => state.nodes.map((n) => n.signature).join('|'), (_) {
        if (_isDragging()) {
          _pendingNodeDataSync = true;
        } else {
          _syncNodeDataToController();
        }
      }),
    );

    // Connection sync: tracks connection list changes
    _reactions.add(
      reaction((_) => state.connections.map((c) => c.id).join('|'), (_) {
        if (_isDragging()) {
          _pendingConnectionSync = true;
        } else {
          _syncConnectionsToController();
        }
      }, fireImmediately: true),
    );

    // Drag-end flush: processes deferred syncs when user stops dragging
    _reactions.add(
      reaction((_) => _controller.interaction.draggedNodeId.value, (
        String? draggedNodeId,
      ) {
        final wasDragging = _previousDraggedNodeId != null;
        final isDragging = draggedNodeId != null;
        _previousDraggedNodeId = draggedNodeId;

        if (wasDragging &&
            !isDragging &&
            (_pendingNodeDataSync || _pendingConnectionSync)) {
          Future.microtask(() {
            if (_pendingNodeDataSync) {
              _pendingNodeDataSync = false;
              _syncNodeDataToController();
            }
            if (_pendingConnectionSync) {
              _pendingConnectionSync = false;
              _syncConnectionsToController();
            }
          });
        }
      }),
    );
  }

  /// Returns true if a drag or canvas lock is active.
  bool _isDragging() {
    return _controller.interaction.canvasLocked.value ||
        _controller.interaction.draggedNodeId.value != null;
  }

  /// Synchronizes the node list from MathState to NodeFlowController.
  ///
  /// Performs set-difference operations to:
  /// - Remove controller nodes that no longer exist in state
  /// - Add new state nodes that don't exist in controller
  /// Does NOT update existing nodes (handled by [_syncNodeDataToController]).
  void _syncNodesToController() {
    final controllerNodeIds = _controller.nodes.keys.toSet();
    final stateNodeIds = state.nodes.map((n) => n.id).toSet();

    for (final nodeId in controllerNodeIds.difference(stateNodeIds)) {
      _controller.removeNode(nodeId);
    }

    for (final nodeData in state.nodes) {
      if (!controllerNodeIds.contains(nodeData.id)) {
        final position = _getNodePosition(nodeData);
        final node = MathNodeFactory.createNode(nodeData, position);
        _controller.addNode(node);
      }
    }
  }

  /// Updates controller nodes when their data (value, operator) changes.
  ///
  /// Since ports are derived from node data, changing data requires a
  /// remove-and-recreate cycle. This method:
  /// 1. Preserves the node's current position
  /// 2. Saves connections attached to the node
  /// 3. Removes and recreates the node with new data
  /// 4. Restores connections to maintain graph integrity
  ///
  /// Batched for performance; deferred during drag to prevent flickering.
  void _syncNodeDataToController() {
    if (_isDragging()) {
      _pendingNodeDataSync = true;
      return;
    }

    _controller.batch('sync-node-data', () {
      for (final nodeData in state.nodes) {
        final existingNode = _controller.nodes[nodeData.id];
        if (existingNode != null &&
            existingNode.data.signature != nodeData.signature) {
          final connectionsToRestore = state.connections
              .where(
                (c) =>
                    c.sourceNodeId == nodeData.id ||
                    c.targetNodeId == nodeData.id,
              )
              .toList();

          final position = existingNode.position.value;
          _controller.removeNode(nodeData.id);
          final node = MathNodeFactory.createNode(nodeData, position);
          _controller.addNode(node);

          for (final conn in connectionsToRestore) {
            final sourceExists = _controller.nodes.containsKey(
              conn.sourceNodeId,
            );
            final targetExists = _controller.nodes.containsKey(
              conn.targetNodeId,
            );
            if (sourceExists && targetExists) {
              _controller.addConnection(conn);
            }
          }
        }
      }
    });
  }

  /// Computes default position for nodes without explicit placement.
  ///
  /// Arranges nodes in a 3-column grid pattern, spacing them 220px
  /// horizontally and 130px vertically to prevent overlap.
  Offset _getNodePosition(MathNodeData nodeData) {
    if (nodeData.position != null) return nodeData.position!;

    final nodeIndex = state.nodes.indexWhere((n) => n.id == nodeData.id);
    final row = nodeIndex ~/ 3;
    final col = nodeIndex % 3;

    return Offset(100 + (col * 220.0), 100 + (row * 130.0));
  }

  /// Synchronizes connections from MathState to NodeFlowController.
  ///
  /// Uses set-difference to add/remove connections efficiently.
  /// Batched for performance; deferred during drag to prevent flickering.
  void _syncConnectionsToController() {
    if (_isDragging()) {
      _pendingConnectionSync = true;
      return;
    }

    _controller.batch('sync-connections', () {
      final controllerConnIds = _controller.connections
          .map((c) => c.id)
          .toSet();
      final stateConnIds = state.connections.map((c) => c.id).toSet();

      for (final connId in controllerConnIds.difference(stateConnIds)) {
        _controller.removeConnection(connId);
      }

      for (final conn in state.connections) {
        if (!controllerConnIds.contains(conn.id)) {
          _controller.addConnection(conn);
        }
      }
    });
  }

  /// Propagates new connections from controller to MathState.
  void _handleConnectionCreated(Connection connection) {
    state.addConnection(connection);
  }

  /// Propagates connection deletions from controller to MathState.
  ///
  /// Only removes from state if the connection is not being recreated during sync.
  /// During data sync operations, connections are temporarily removed and recreated,
  /// but they still exist in state - we should not remove them in that case.
  void _handleConnectionDeleted(Connection connection) {
    // Check if connection still exists in state - if it does, we're recreating it
    // during a sync operation, so don't remove it from state
    final connectionExistsInState =
        state.connections.any((c) => c.id == connection.id);
    if (!connectionExistsInState) {
      state.removeConnection(connection.id);
    }
  }

  /// Propagates node deletions from controller to MathState.
  ///
  /// Only removes from state if the node is not being recreated during sync.
  /// During data sync operations, nodes are temporarily removed and recreated,
  /// but they still exist in state - we should not remove them in that case.
  void _handleNodeDeleted(Node<MathNodeData> node) {
    // Check if node still exists in state - if it does, we're recreating it
    // during a sync operation, so don't remove it from state
    final nodeExistsInState = state.nodes.any((n) => n.id == node.id);
    if (!nodeExistsInState) {
      state.removeNode(node.id);
    }
  }

  /// Validates a pending connection before it's created.
  ///
  /// Rejects connections that would:
  /// - Connect a node to itself (self-loop)
  /// - Create a cycle in the graph (prevents infinite evaluation loops)
  /// - Connect to an input port that already has a connection
  ConnectionValidationResult _validateConnection(
    ConnectionCompleteContext<MathNodeData> context,
  ) {
    if (context.sourceNode.id == context.targetNode.id) {
      return ConnectionValidationResult.deny(
        reason: 'Cannot connect to self',
        showMessage: true,
      );
    }

    if (_wouldCreateCycle(context.sourceNode.id, context.targetNode.id)) {
      return ConnectionValidationResult.deny(
        reason: 'Would create a cycle',
        showMessage: true,
      );
    }

    final validConnections = MathConnectionUtils.getValidConnections(
      state.nodes.toList(),
      state.connections.toList(),
    );

    final existingConnection = validConnections.any(
      (c) =>
          c.targetNodeId == context.targetNode.id &&
          c.targetPortId == context.targetPort.id,
    );
    if (existingConnection) {
      return ConnectionValidationResult.deny(
        reason: 'Port already connected',
        showMessage: true,
      );
    }

    return ConnectionValidationResult.allow();
  }

  /// Detects if adding connection source→target would create a cycle.
  ///
  /// Uses DFS to check if there's already a path from target to source.
  /// If such a path exists, adding source→target would complete a cycle.
  bool _wouldCreateCycle(String sourceId, String targetId) {
    final validConnections = MathConnectionUtils.getValidConnections(
      state.nodes.toList(),
      state.connections.toList(),
    );

    final visited = <String>{};

    bool hasPath(String from, String to) {
      if (from == to) return true;
      if (visited.contains(from)) return false;
      visited.add(from);

      for (final conn in validConnections) {
        if (conn.sourceNodeId == from && hasPath(conn.targetNodeId, to)) {
          return true;
        }
      }
      return false;
    }

    return hasPath(targetId, sourceId);
  }

  /// Centers and scales the view to fit all nodes on first load.
  void _handleInit() {
    if (!_isInitialized && _controller.nodes.isNotEmpty) {
      _isInitialized = true;
      _controller.fitToView();
    }
  }

  @override
  void dispose() {
    for (final reaction in _reactions) {
      reaction();
    }
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Remove unnecessary Observer - NodeFlowEditor handles its own reactivity
    // Results are accessed per-node in _buildNodeContent, not globally
    return NodeFlowEditor<MathNodeData, dynamic>(
      controller: _controller,
      theme: widget.theme,
      nodeBuilder: _buildNodeContent,
      events: NodeFlowEvents(
        onInit: _handleInit,
        node: NodeEvents<MathNodeData>(onDeleted: _handleNodeDeleted),
        connection: ConnectionEvents<MathNodeData, dynamic>(
          onCreated: _handleConnectionCreated,
          onDeleted: _handleConnectionDeleted,
          onBeforeComplete: _validateConnection,
        ),
      ),
    );
  }

  /// Builds the content widget for each node based on its type.
  ///
  /// Uses MobX Observer to reactively update when evaluation result changes.
  /// Each node only observes its own result, preventing unnecessary rebuilds.
  Widget _buildNodeContent(BuildContext context, Node<MathNodeData> node) {
    return Observer(
      builder: (context) {
        final result = state.results[node.id];
        return MathNodeFactory.buildContent(
          node,
          result,
          (updated) => state.updateNode(updated),
          onNodeSizeChanged: _handleNodeSizeChanged,
        );
      },
    );
  }

  /// Updates node dimensions in controller when content size changes.
  ///
  /// Used by ResultNode to expand width based on expression length.
  /// Ignores sub-pixel changes to prevent layout thrashing.
  void _handleNodeSizeChanged(String nodeId, Size newSize) {
    final node = _controller.nodes[nodeId];
    if (node == null) return;

    final currentSize = node.size.value;
    if ((currentSize.width - newSize.width).abs() < 1 &&
        (currentSize.height - newSize.height).abs() < 1) {
      return;
    }

    node.setSize(newSize);
  }
}
