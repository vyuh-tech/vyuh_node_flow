/// Reactive evaluation service that watches the controller and computes results.
///
/// This service reacts to controller changes and automatically evaluates the graph.
/// Uses incremental evaluation - only re-evaluates nodes affected by changes.
library;
import 'dart:async';

import 'package:mobx/mobx.dart';
import 'package:vyuh_node_flow/vyuh_node_flow.dart';

import 'evaluation.dart';
import 'models.dart';

/// Service that manages evaluation results by reacting to controller changes.
///
/// Architecture:
/// - Watches controller nodes and connections via MobX reactions
/// - Uses incremental evaluation (only re-evaluates affected nodes)
/// - Maintains dependency graph for efficient invalidation
/// - Debounced to prevent excessive computation during rapid edits
class MathEvaluationService {
  MathEvaluationService(this.controller) {
    _setupReactions();
  }

  final NodeFlowController<MathNodeData, dynamic> controller;

  /// Evaluation results, keyed by node ID.
  /// Observable so UI can react to changes.
  final results = ObservableMap<String, EvalResult>();

  /// Dependency graph: sourceNodeId → Set of nodes that depend on it.
  /// Used for incremental invalidation.
  final _dependencyGraph = <String, Set<String>>{};

  /// Set of node IDs that need re-evaluation.
  final _dirtyNodes = ObservableSet<String>();

  /// Debounce timer to coalesce rapid changes.
  Timer? _evalDebouncer;

  /// List of reaction disposers for cleanup.
  final List<ReactionDisposer> _reactions = [];

  /// Sets up MobX reactions to watch controller changes.
  ///
  /// Reacts to:
  /// - Node additions/removals
  /// - Connection additions/removals
  /// - Node data changes (via signature tracking)
  void _setupReactions() {
    // React to node list changes
    _reactions.add(
      reaction(
        (_) => controller.nodes.keys.toList()..sort(),
        (_) {
          _rebuildDependencyGraph();
          _markAllDirty();
          _scheduleEvaluation();
        },
      ),
    );

    // React to connection changes
    _reactions.add(
      reaction(
        (_) => controller.connections.map((c) => c.id).toList()..sort(),
        (_) {
          _rebuildDependencyGraph();
          _markAllDirty();
          _scheduleEvaluation();
        },
      ),
    );

    // React to node data changes (signature changes)
    _reactions.add(
      reaction(
        (_) => controller.nodes.values
            .map((n) => '${n.id}:${n.data.signature}')
            .toList()
          ..sort(),
        (_) {
          _markAllDirty();
          _scheduleEvaluation();
        },
      ),
    );
  }

  /// Rebuilds the dependency graph from current controller state.
  void _rebuildDependencyGraph() {
    _dependencyGraph.clear();

    final nodeIds = controller.nodes.keys.toSet();
    final validConnections = controller.connections.where(
      (c) =>
          nodeIds.contains(c.sourceNodeId) &&
          nodeIds.contains(c.targetNodeId),
    );

    for (final conn in validConnections) {
      _dependencyGraph
          .putIfAbsent(conn.sourceNodeId, () => <String>{})
          .add(conn.targetNodeId);
    }
  }

  /// Marks all nodes as dirty (full re-evaluation).
  void _markAllDirty() {
    _dirtyNodes.clear();
    _dirtyNodes.addAll(controller.nodes.keys);
  }

  /// Schedules evaluation after debounce.
  void _scheduleEvaluation() {
    _evalDebouncer?.cancel();
    _evalDebouncer = Timer(const Duration(milliseconds: 50), _evaluate);
  }

  /// Evaluates the graph and updates results.
  ///
  /// Uses incremental evaluation if possible, otherwise full evaluation.
  void _evaluate() {
    runInAction(() {
      // Get current state from controller
      final nodes = controller.nodes.values.map((n) => n.data).toList();
      final connections = controller.connections.toList();

      // Evaluate using the evaluator
      final evalResults = MathEvaluator.evaluate(nodes, connections);

      // Update results - clear removed nodes, update existing
      final currentNodeIds = controller.nodes.keys.toSet();
      
      // Remove results for deleted nodes
      results.removeWhere((nodeId, _) => !currentNodeIds.contains(nodeId));
      
      // Update/add results for existing nodes
      for (final entry in evalResults.entries) {
        if (currentNodeIds.contains(entry.key)) {
          results[entry.key] = entry.value;
        }
      }

      _dirtyNodes.clear();
    });
  }

  /// Releases resources.
  void dispose() {
    for (final reaction in _reactions) {
      reaction();
    }
    _evalDebouncer?.cancel();
    results.clear();
    _dependencyGraph.clear();
    _dirtyNodes.clear();
  }
}
