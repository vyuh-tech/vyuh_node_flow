/// Reactive state management for the Node Math Calculator.
///
/// Uses MobX observables with debounced evaluation for performance.
import 'dart:async';

import 'package:mobx/mobx.dart';
import 'package:vyuh_node_flow/vyuh_node_flow.dart';

import 'evaluation.dart';
import 'models.dart';

/// Central state store for the math calculator, managing nodes, connections, and results.
///
/// Owns the source of truth for the graph structure. Changes here propagate
/// to [MathCanvas] via MobX reactions. Evaluation is debounced to prevent
/// rapid re-computation during fast edits.
class MathState {
  MathState();

  /// Observable list of all nodes in the graph.
  final nodes = ObservableList<MathNodeData>();

  /// Observable list of all connections between nodes.
  final connections = ObservableList<Connection>();

  /// Cached evaluation results, keyed by node ID.
  final results = ObservableMap<String, EvalResult>();

  /// Currently selected node for UI highlighting (if any).
  final selectedNodeId = Observable<String?>(null);

  /// Auto-incrementing counter for generating unique node IDs.
  int _nodeCounter = 0;

  /// Debounce timer to coalesce rapid state changes before evaluation.
  Timer? _evalDebouncer;

  /// Generates a unique node ID using incremental counter.
  String generateNodeId() {
    _nodeCounter++;
    return 'math-node-$_nodeCounter';
  }

  /// Adds a new node to the graph and triggers re-evaluation.
  void addNode(MathNodeData node) {
    nodes.add(node);
    _scheduleEvaluation();
  }

  /// Removes a node and all its connections, then re-evaluates.
  ///
  /// Also clears selection if the deleted node was selected.
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

  /// Updates a node's data (e.g., value change, operator toggle).
  void updateNode(MathNodeData node) {
    final index = nodes.indexWhere((n) => n.id == node.id);
    if (index != -1) {
      nodes[index] = node;
      _scheduleEvaluation();
    }
  }

  /// Adds a connection between two ports if not already present.
  void addConnection(Connection connection) {
    if (connections.any((c) => c.id == connection.id)) return;
    connections.add(connection);
    _scheduleEvaluation();
  }

  /// Removes a connection by ID and triggers re-evaluation.
  void removeConnection(String connectionId) {
    connections.removeWhere((c) => c.id == connectionId);
    _scheduleEvaluation();
  }

  /// Sets the currently selected node for UI highlighting.
  void selectNode(String? nodeId) {
    selectedNodeId.value = nodeId;
  }

  /// Resets the calculator to empty state.
  void clearAll() {
    nodes.clear();
    connections.clear();
    results.clear();
    selectedNodeId.value = null;
  }

  /// Schedules evaluation after a 50ms debounce window.
  ///
  /// Prevents rapid re-computation when user types quickly or
  /// drags connections in rapid succession.
  void _scheduleEvaluation() {
    _evalDebouncer?.cancel();
    _evalDebouncer = Timer(const Duration(milliseconds: 50), evaluate);
  }

  /// Runs the graph evaluator and updates all node results.
  ///
  /// Called automatically via debounce after any graph mutation.
  void evaluate() {
    final evalResults = MathEvaluator.evaluate(
      nodes.toList(),
      connections.toList(),
    );

    results.clear();
    results.addAll(evalResults);
  }

  /// Releases resources (cancels pending evaluation timer).
  void dispose() {
    _evalDebouncer?.cancel();
  }
}
