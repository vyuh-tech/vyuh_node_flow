import 'dart:async';

import 'package:mobx/mobx.dart';
import 'package:vyuh_node_flow/vyuh_node_flow.dart';

import 'evaluation.dart';
import 'models.dart';

/// Reactive state for the math calculator.
class MathState {
  MathState();

  /// All nodes in the graph.
  final nodes = ObservableList<MathNodeData>();

  /// All connections.
  final connections = ObservableList<Connection>();

  /// Evaluation results per node.
  final results = ObservableMap<String, EvalResult>();

  /// Currently selected node ID.
  final selectedNodeId = Observable<String?>(null);

  /// Node counter for unique IDs.
  int _nodeCounter = 0;

  Timer? _evalDebouncer;

  /// Generate unique node ID.
  String generateNodeId() {
    _nodeCounter++;
    return 'math-node-$_nodeCounter';
  }

  /// Add a node.
  void addNode(MathNodeData node) {
    nodes.add(node);
    _scheduleEvaluation();
  }

  /// Remove a node and its connections.
  void removeNode(String nodeId) {
    nodes.removeWhere((n) => n.id == nodeId);
    connections.removeWhere(
      (c) => c.sourceNodeId == nodeId || c.targetNodeId == nodeId,
    );
    results.remove(nodeId);

    if (selectedNodeId.value == nodeId) {
      selectedNodeId.value = null;
    }

    _scheduleEvaluation();
  }

  /// Update a node's data.
  void updateNode(MathNodeData node) {
    final index = nodes.indexWhere((n) => n.id == node.id);
    if (index != -1) {
      nodes[index] = node;
      _scheduleEvaluation();
    }
  }

  /// Add a connection.
  void addConnection(Connection connection) {
    // Avoid duplicates
    if (connections.any((c) => c.id == connection.id)) return;
    connections.add(connection);
    _scheduleEvaluation();
  }

  /// Remove a connection.
  void removeConnection(String connectionId) {
    connections.removeWhere((c) => c.id == connectionId);
    _scheduleEvaluation();
  }

  /// Select a node.
  void selectNode(String? nodeId) {
    selectedNodeId.value = nodeId;
  }

  /// Clear all nodes and connections.
  void clearAll() {
    nodes.clear();
    connections.clear();
    results.clear();
    selectedNodeId.value = null;
  }

  void _scheduleEvaluation() {
    _evalDebouncer?.cancel();
    _evalDebouncer = Timer(const Duration(milliseconds: 50), evaluate);
  }

  /// Evaluate the graph.
  void evaluate() {
    final evalResults = MathEvaluator.evaluate(
      nodes.toList(),
      connections.toList(),
    );

    results.clear();
    results.addAll(evalResults);
  }

  /// Dispose resources.
  void dispose() {
    _evalDebouncer?.cancel();
  }
}
