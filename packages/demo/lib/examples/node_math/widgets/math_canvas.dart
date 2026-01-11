import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:vyuh_node_flow/vyuh_node_flow.dart';

import '../models.dart';
import '../state.dart';
import 'node_factory.dart';

/// The primary canvas widget for the math node graph editor.
///
/// Follows the pattern of other demos:
/// - Controller is the source of truth
/// - Evaluation service reacts to controller changes
/// - No bidirectional sync needed
/// - Connection validation for cycles and port limits
class MathCanvas extends StatefulWidget {
  final MathState state;
  final NodeFlowTheme theme;

  const MathCanvas({super.key, required this.state, required this.theme});

  @override
  State<MathCanvas> createState() => _MathCanvasState();
}

class _MathCanvasState extends State<MathCanvas> {
  MathState get state => widget.state;
  NodeFlowController<MathNodeData, dynamic> get controller => state.controller;

  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
  }

  /// Validates a pending connection before it's created.
  ///
  /// Rejects connections that would:
  /// - Connect a node to itself (self-loop)
  /// - Create a cycle in the graph
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

    // Check if target port already has a connection
    final nodeIds = controller.nodes.keys.toSet();
    final existingConnection = controller.connections.any(
      (c) =>
          nodeIds.contains(c.sourceNodeId) &&
          nodeIds.contains(c.targetNodeId) &&
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
  bool _wouldCreateCycle(String sourceId, String targetId) {
    final nodeIds = controller.nodes.keys.toSet();
    final validConnections = controller.connections
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

  /// Centers and scales the view to fit all nodes on first load.
  void _handleInit() {
    if (!_isInitialized && controller.nodes.isNotEmpty) {
      _isInitialized = true;
      controller.fitToView();
    }
  }

  @override
  Widget build(BuildContext context) {
    return NodeFlowEditor<MathNodeData, dynamic>(
      controller: controller,
      theme: widget.theme,
      nodeBuilder: _buildNodeContent,
      events: NodeFlowEvents(
        onInit: _handleInit,
        connection: ConnectionEvents<MathNodeData, dynamic>(
          onBeforeComplete: _validateConnection,
        ),
      ),
    );
  }

  /// Builds the content widget for each node based on its type.
  ///
  /// Uses MobX Observer to reactively update when evaluation result changes.
  Widget _buildNodeContent(BuildContext context, Node<MathNodeData> node) {
    return Observer(
      builder: (context) {
        final result = state.results[node.id];
        return MathNodeFactory.buildContent(
          node,
          result,
          (updated) => _updateNodeData(node.id, updated),
          onNodeSizeChanged: (nodeId, newSize) {
            final n = controller.nodes[nodeId];
            if (n != null) {
              n.setSize(newSize);
            }
          },
        );
      },
    );
  }

  /// Updates node data in the controller.
  ///
  /// Since ports are derived from node data, we need to recreate the node.
  void _updateNodeData(String nodeId, MathNodeData newData) {
    final existingNode = controller.nodes[nodeId];
    if (existingNode == null) return;

    // Preserve position and connections
    final position = existingNode.position.value;
    final connectionsToRestore = controller.connections
        .where(
          (c) => c.sourceNodeId == nodeId || c.targetNodeId == nodeId,
        )
        .toList();

    // Remove and recreate node with new data
    controller.removeNode(nodeId);
    final newNode = MathNodeFactory.createNode(newData, position);
    controller.addNode(newNode);

    // Restore connections
    for (final conn in connectionsToRestore) {
      final sourceExists = controller.nodes.containsKey(conn.sourceNodeId);
      final targetExists = controller.nodes.containsKey(conn.targetNodeId);
      if (sourceExists && targetExists) {
        controller.addConnection(conn);
      }
    }
  }
}
