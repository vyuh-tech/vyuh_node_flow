import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:mobx/mobx.dart';
import 'package:vyuh_node_flow/vyuh_node_flow.dart';

import '../models.dart';
import '../state.dart';
import 'node_factory.dart';

/// The main canvas widget that displays the math node graph.
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

  void _setupReactions() {
    // Sync nodes from state to controller when node list changes
    // This is safe to run during drag as it only adds/removes nodes
    _reactions.add(
      reaction(
        (_) => state.nodes.map((n) => n.id).join('|'),
        (_) => _syncNodesToController(),
        fireImmediately: true,
      ),
    );

    // Sync node data updates (values, operators)
    // Defer during drag to prevent flickering
    _reactions.add(
      reaction((_) => state.nodes.map((n) => n.signature).join('|'), (_) {
        if (_isDragging()) {
          _pendingNodeDataSync = true;
        } else {
          _syncNodeDataToController();
        }
      }),
    );

    // Sync connections from state to controller
    // Defer during drag to prevent flickering
    _reactions.add(
      reaction((_) => state.connections.map((c) => c.id).join('|'), (_) {
        if (_isDragging()) {
          _pendingConnectionSync = true;
        } else {
          _syncConnectionsToController();
        }
      }, fireImmediately: true),
    );

    // When drag ends, process any pending sync operations
    _reactions.add(
      reaction((_) => _controller.interaction.draggedNodeId.value, (
        String? draggedNodeId,
      ) {
        // Drag just ended (was dragging, now null)
        final wasDragging = _previousDraggedNodeId != null;
        final isDragging = draggedNodeId != null;
        _previousDraggedNodeId = draggedNodeId;

        if (wasDragging &&
            !isDragging &&
            (_pendingNodeDataSync || _pendingConnectionSync)) {
          // Small delay to ensure drag state is fully cleared
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

  /// Check if any drag operation is in progress
  bool _isDragging() {
    return _controller.interaction.canvasLocked.value ||
        _controller.interaction.draggedNodeId.value != null;
  }

  void _syncNodesToController() {
    final controllerNodeIds = _controller.nodes.keys.toSet();
    final stateNodeIds = state.nodes.map((n) => n.id).toSet();

    // Remove nodes no longer in state
    for (final nodeId in controllerNodeIds.difference(stateNodeIds)) {
      _controller.removeNode(nodeId);
    }

    // Add new nodes from state
    for (final nodeData in state.nodes) {
      if (!controllerNodeIds.contains(nodeData.id)) {
        final position = _getNodePosition(nodeData);
        final node = MathNodeFactory.createNode(nodeData, position);
        _controller.addNode(node);
      }
    }
  }

  void _syncNodeDataToController() {
    // Skip if dragging to prevent flickering
    if (_isDragging()) {
      _pendingNodeDataSync = true;
      return;
    }

    // Use batch to group operations for better performance
    _controller.batch('sync-node-data', () {
      for (final nodeData in state.nodes) {
        final existingNode = _controller.nodes[nodeData.id];
        if (existingNode != null &&
            existingNode.data.signature != nodeData.signature) {
          // Preserve connections before removing the node
          final connectionsToRestore = state.connections
              .where(
                (c) =>
                    c.sourceNodeId == nodeData.id ||
                    c.targetNodeId == nodeData.id,
              )
              .toList();

          // Update the node's data while keeping position
          final position = existingNode.position.value;
          _controller.removeNode(nodeData.id);
          final node = MathNodeFactory.createNode(nodeData, position);
          _controller.addNode(node);

          // Restore connections after adding the new node
          for (final conn in connectionsToRestore) {
            // Only restore if both nodes exist (the other node might have been removed)
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

  Offset _getNodePosition(MathNodeData nodeData) {
    final savedPosition = switch (nodeData) {
      NumberData(:final position) => position,
      OperatorData(:final position) => position,
      FunctionData(:final position) => position,
      ResultData(:final position) => position,
    };

    if (savedPosition != null) return savedPosition;

    // Calculate a staggered default position
    final nodeIndex = state.nodes.indexWhere((n) => n.id == nodeData.id);
    final row = nodeIndex ~/ 3;
    final col = nodeIndex % 3;

    return Offset(100 + (col * 220.0), 100 + (row * 130.0));
  }

  void _syncConnectionsToController() {
    // Skip if dragging to prevent flickering
    if (_isDragging()) {
      _pendingConnectionSync = true;
      return;
    }

    // Use batch to group operations for better performance
    _controller.batch('sync-connections', () {
      final controllerConnIds = _controller.connections
          .map((c) => c.id)
          .toSet();
      final stateConnIds = state.connections.map((c) => c.id).toSet();

      // Remove connections no longer in state
      for (final connId in controllerConnIds.difference(stateConnIds)) {
        _controller.removeConnection(connId);
      }

      // Add new connections from state
      for (final conn in state.connections) {
        if (!controllerConnIds.contains(conn.id)) {
          _controller.addConnection(conn);
        }
      }
    });
  }

  void _handleConnectionCreated(Connection connection) {
    state.addConnection(connection);
  }

  void _handleConnectionDeleted(Connection connection) {
    state.removeConnection(connection.id);
  }

  void _handleNodeDeleted(Node<MathNodeData> node) {
    state.removeNode(node.id);
  }

  ConnectionValidationResult _validateConnection(
    ConnectionCompleteContext<MathNodeData> context,
  ) {
    // Prevent self-connections
    if (context.sourceNode.id == context.targetNode.id) {
      return ConnectionValidationResult.deny(
        reason: 'Cannot connect to self',
        showMessage: true,
      );
    }

    // Prevent cycles
    if (_wouldCreateCycle(context.sourceNode.id, context.targetNode.id)) {
      return ConnectionValidationResult.deny(
        reason: 'Would create a cycle',
        showMessage: true,
      );
    }

    // Get valid connections (both source and target nodes must exist)
    final nodeIds = state.nodes.map((n) => n.id).toSet();
    final validConnections = state.connections.where(
      (c) =>
          nodeIds.contains(c.sourceNodeId) && nodeIds.contains(c.targetNodeId),
    );

    // Prevent duplicate connections to same port
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

  bool _wouldCreateCycle(String sourceId, String targetId) {
    // Only consider valid connections (both nodes must exist)
    final nodeIds = state.nodes.map((n) => n.id).toSet();
    final validConnections = state.connections
        .where(
          (c) =>
              nodeIds.contains(c.sourceNodeId) &&
              nodeIds.contains(c.targetNodeId),
        )
        .toList();

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

  Widget _buildNodeContent(BuildContext context, Node<MathNodeData> node) {
    // Only observe the specific result for this node, not all results
    return Observer(
      builder: (context) {
        // Access result directly - only rebuilds when this specific result changes
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

  void _handleNodeSizeChanged(String nodeId, Size newSize) {
    final node = _controller.nodes[nodeId];
    if (node == null) return;

    final currentSize = node.size.value;
    if ((currentSize.width - newSize.width).abs() < 1 &&
        (currentSize.height - newSize.height).abs() < 1) {
      return;
    }

    // Update the node size in the controller
    node.setSize(newSize);
  }
}
