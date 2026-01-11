/// State management for Node Math Calculator.
///
/// Simplified architecture following other demo patterns:
/// - Controller is the source of truth (like other demos)
/// - Evaluation service reacts to controller changes
/// - No separate state layer - direct controller usage
library;

import 'package:mobx/mobx.dart';
import 'package:vyuh_node_flow/vyuh_node_flow.dart';

import 'evaluation.dart';
import 'evaluation_service.dart';
import 'models.dart';

/// Simplified state that wraps controller and evaluation service.
///
/// Follows the pattern of other demos where controller is the source of truth.
/// Evaluation is handled by a reactive service that watches the controller.
class MathState {
  MathState(this.controller)
    : evaluationService = MathEvaluationService(controller);

  /// Controller is the source of truth for nodes and connections.
  final NodeFlowController<MathNodeData, dynamic> controller;

  /// Evaluation service that reacts to controller changes.
  final MathEvaluationService evaluationService;

  /// Convenience accessor for evaluation results.
  ObservableMap<String, EvalResult> get results => evaluationService.results;

  /// Currently selected node ID (for UI highlighting).
  final selectedNodeId = Observable<String?>(null);

  /// Auto-incrementing counter for node IDs.
  int _nodeCounter = 0;

  /// Generates a unique node ID.
  String generateNodeId() {
    _nodeCounter++;
    return 'math-node-$_nodeCounter';
  }

  /// Sets the selected node.
  void selectNode(String? nodeId) {
    selectedNodeId.value = nodeId;
  }

  /// Clears all nodes and connections.
  void clearAll() {
    controller.clearGraph();
    selectedNodeId.value = null;
  }

  /// Releases resources.
  void dispose() {
    evaluationService.dispose();
    controller.dispose();
  }
}
