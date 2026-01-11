library;

import 'package:mobx/mobx.dart';
import 'package:vyuh_node_flow/vyuh_node_flow.dart';

import '../core/models.dart';
import '../evaluation/evaluator.dart';
import '../evaluation/evaluation_service.dart';

class MathState {
  MathState(this.controller)
    : evaluationService = MathEvaluationService(controller);

  final NodeFlowController<MathNodeData, dynamic> controller;
  final MathEvaluationService evaluationService;

  ObservableMap<String, EvalResult> get results => evaluationService.results;

  final selectedNodeId = Observable<String?>(null);
  int _nodeCounter = 0;

  String generateNodeId() {
    _nodeCounter++;
    return 'math-node-$_nodeCounter';
  }

  void selectNode(String? nodeId) {
    selectedNodeId.value = nodeId;
  }

  void clearAll() {
    controller.clearGraph();
    selectedNodeId.value = null;
  }

  void dispose() {
    evaluationService.dispose();
    controller.dispose();
  }
}
