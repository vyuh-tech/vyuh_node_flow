/// Graph evaluation logic for the math calculator.
///
/// This module provides standalone evaluation that works directly on
/// [MathNodeData] lists, independent of the NodeFlowController.
///
/// ### Why Custom Cycle Detection?
/// While the core package provides `controller.hasCycles()`, this evaluator
/// implements its own cycle detection because:
/// 1. It operates on [MathNodeData] lists, not controller nodes
/// 2. Evaluator runs independently without controller access
/// 3. Cycle check feeds directly into topological sort (same pass optimization)
/// 4. Domain-specific: only considers valid math connections
library;

import 'package:vyuh_node_flow/vyuh_node_flow.dart';

import '../core/constants.dart';
import '../core/models.dart';
import '../utils/connection_utils.dart';
import '../utils/formatters.dart';

/// Represents the evaluation outcome for a single math node.
///
/// Contains either:
/// - A computed [value] with optional human-readable [expression] (success)
/// - An [error] message describing why evaluation failed
class EvalResult {
  final double? value;
  final String? expression;
  final String? error;

  const EvalResult._({this.value, this.expression, this.error});

  factory EvalResult.success(double value, {String? expression}) =>
      EvalResult._(value: value, expression: expression);

  factory EvalResult.error(String message) => EvalResult._(error: message);

  bool get hasValue => value != null && !value!.isNaN;
  bool get hasError => error != null;
}

/// Evaluates a math node graph using topological sort.
///
/// Performs a complete evaluation pass:
/// 1. Validates connections (filters orphaned references)
/// 2. Detects cycles (fails fast if found)
/// 3. Topologically sorts nodes (dependency order)
/// 4. Evaluates each node in order
class MathEvaluator {
  /// Evaluates the entire node graph and returns results for each node.
  ///
  /// Algorithm:
  /// 1. Filter orphaned connections (references to deleted nodes)
  /// 2. Detect cycles - returns error for all nodes if found
  /// 3. Topologically sort nodes (guarantees inputs evaluated before outputs)
  /// 4. Evaluate each node in dependency order, building expressions
  ///
  /// Returns a map of nodeId → [EvalResult] with computed values.
  static Map<String, EvalResult> evaluate(
    List<MathNodeData> nodes,
    List<Connection> connections,
  ) {
    final results = <String, EvalResult>{};

    final nodeIds = MathConnectionUtils.getNodeIds(nodes);
    final validConnections = MathConnectionUtils.getValidConnections(
      nodes,
      connections,
    );

    if (_hasCycle(nodes, validConnections, nodeIds)) {
      for (final node in nodes) {
        results[node.id] = EvalResult.error('Cycle detected');
      }
      return results;
    }

    final sorted = _topologicalSort(nodes, validConnections, nodeIds);

    final values = <String, double>{};
    final expressions = <String, String>{};

    for (final node in sorted) {
      final result = _evaluateNode(
        node,
        validConnections,
        nodeIds,
        values,
        expressions,
      );
      results[node.id] = result;

      if (result.hasValue) {
        values[node.id] = result.value!;
        if (result.expression != null) {
          expressions[node.id] = result.expression!;
        }
      }
    }

    return results;
  }

  /// Dispatches evaluation to the appropriate handler based on node type.
  ///
  /// Each node type has specific evaluation logic:
  /// - Number: returns its stored value directly
  /// - Operator: combines two inputs with arithmetic operation
  /// - Function: applies mathematical function to single input
  /// - Result: passes through input value for display
  static EvalResult _evaluateNode(
    MathNodeData node,
    List<Connection> connections,
    Set<String> nodeIds,
    Map<String, double> values,
    Map<String, String> expressions,
  ) {
    switch (node) {
      case NumberData(:final value):
        return EvalResult.success(
          value,
          expression: MathFormatters.formatNumber(value),
        );

      case OperatorData(:final operator):
        return _evaluateOperator(
          node.id,
          operator,
          connections,
          nodeIds,
          values,
          expressions,
        );

      case FunctionData(:final function):
        return _evaluateFunction(
          node.id,
          function,
          connections,
          nodeIds,
          values,
          expressions,
        );

      case ResultData():
        return _evaluateResult(
          node.id,
          connections,
          nodeIds,
          values,
          expressions,
        );
    }
  }

  /// Evaluates a binary operator node (A op B).
  ///
  /// Handles partial connections gracefully:
  /// - Both inputs connected: computes result and builds expression (e.g. "5+3")
  /// - Only one input: shows partial expression, returns 0
  /// - No inputs: returns "?" placeholder
  ///
  /// Detects division by zero and returns error.
  /// Ensures expressions only reference nodes that exist in nodeIds.
  static EvalResult _evaluateOperator(
    String nodeId,
    MathOperator operator,
    List<Connection> connections,
    Set<String> nodeIds,
    Map<String, double> values,
    Map<String, String> expressions,
  ) {
    final portAId = MathPortIds.inputA(nodeId);
    final portBId = MathPortIds.inputB(nodeId);

    // Find inputs, ensuring source nodes exist
    final inputA = connections
        .where(
          (c) =>
              c.targetNodeId == nodeId &&
              c.targetPortId == portAId &&
              nodeIds.contains(c.sourceNodeId),
        )
        .firstOrNull;
    final inputB = connections
        .where(
          (c) =>
              c.targetNodeId == nodeId &&
              c.targetPortId == portBId &&
              nodeIds.contains(c.sourceNodeId),
        )
        .firstOrNull;

    // Verify both connection and node existence, and that value was computed
    final hasA =
        inputA != null &&
        nodeIds.contains(inputA.sourceNodeId) &&
        values.containsKey(inputA.sourceNodeId);
    final hasB =
        inputB != null &&
        nodeIds.contains(inputB.sourceNodeId) &&
        values.containsKey(inputB.sourceNodeId);

    // Partial connections - show only available input
    if (hasA && !hasB) {
      // Only use expression if source node still exists and has value
      final aExpr =
          nodeIds.contains(inputA.sourceNodeId) &&
              values.containsKey(inputA.sourceNodeId)
          ? (expressions[inputA.sourceNodeId] ??
                MathFormatters.formatNumber(values[inputA.sourceNodeId]!))
          : '?';
      return EvalResult.success(0.0, expression: aExpr);
    }

    if (!hasA && hasB) {
      // Only use expression if source node still exists and has value
      final bExpr =
          nodeIds.contains(inputB.sourceNodeId) &&
              values.containsKey(inputB.sourceNodeId)
          ? (expressions[inputB.sourceNodeId] ??
                MathFormatters.formatNumber(values[inputB.sourceNodeId]!))
          : '?';
      return EvalResult.success(0.0, expression: bExpr);
    }

    if (!hasA && !hasB) {
      return EvalResult.success(0.0, expression: '?');
    }

    // Both inputs available - build full expression
    // Double-check nodes exist before using their expressions
    if (!nodeIds.contains(inputA!.sourceNodeId) ||
        !values.containsKey(inputA.sourceNodeId) ||
        !nodeIds.contains(inputB!.sourceNodeId) ||
        !values.containsKey(inputB.sourceNodeId)) {
      return EvalResult.success(0.0, expression: '?');
    }

    final aValue = values[inputA.sourceNodeId]!;
    final bValue = values[inputB.sourceNodeId]!;
    final aExpr =
        expressions[inputA.sourceNodeId] ?? MathFormatters.formatNumber(aValue);
    final bExpr =
        expressions[inputB.sourceNodeId] ?? MathFormatters.formatNumber(bValue);

    final result = operator.apply(aValue, bValue);

    if (result.isNaN) {
      return EvalResult.error(
        operator == MathOperator.divide ? 'Division by zero' : 'Invalid result',
      );
    }

    return EvalResult.success(
      result,
      expression: '$aExpr${operator.symbol}$bExpr',
    );
  }

  /// Evaluates a unary function node (fn(x)).
  ///
  /// Applies mathematical function (sin, cos, sqrt) to input value.
  /// Returns error for invalid inputs (e.g., sqrt of negative number).
  /// Builds expression string in function notation (e.g., "sin(45)").
  /// Ensures input node exists before using its expression.
  static EvalResult _evaluateFunction(
    String nodeId,
    MathFunction function,
    List<Connection> connections,
    Set<String> nodeIds,
    Map<String, double> values,
    Map<String, String> expressions,
  ) {
    final input = connections
        .where(
          (c) => c.targetNodeId == nodeId && nodeIds.contains(c.sourceNodeId),
        )
        .firstOrNull;

    // No valid input connection or source node doesn't exist
    if (input == null || !nodeIds.contains(input.sourceNodeId)) {
      return EvalResult.success(0.0, expression: '${function.symbol}(?)');
    }

    // Source node exists but value wasn't computed (shouldn't happen, but be safe)
    final inputValue = values[input.sourceNodeId];
    if (inputValue == null || !nodeIds.contains(input.sourceNodeId)) {
      return EvalResult.success(0.0, expression: '${function.symbol}(?)');
    }

    final result = function.apply(inputValue);

    if (result.isNaN) {
      return EvalResult.error('Invalid input');
    }

    // Only use expression if source node still exists
    final inputExpr =
        nodeIds.contains(input.sourceNodeId) &&
            values.containsKey(input.sourceNodeId)
        ? (expressions[input.sourceNodeId] ??
              MathFormatters.formatNumber(inputValue))
        : '?';

    return EvalResult.success(
      result,
      expression: '${function.symbol}($inputExpr)',
    );
  }

  /// Evaluates a result/display node.
  ///
  /// Passes through the input value and expression unchanged.
  /// Shows "?" when not connected, indicating awaiting input.
  /// Ensures source node exists before using its expression.
  static EvalResult _evaluateResult(
    String nodeId,
    List<Connection> connections,
    Set<String> nodeIds,
    Map<String, double> values,
    Map<String, String> expressions,
  ) {
    final input = connections
        .where(
          (c) => c.targetNodeId == nodeId && nodeIds.contains(c.sourceNodeId),
        )
        .firstOrNull;

    // No valid input connection or source node doesn't exist
    if (input == null || !nodeIds.contains(input.sourceNodeId)) {
      return EvalResult.success(0.0, expression: '?');
    }

    // Source node exists but value wasn't computed
    final inputValue = values[input.sourceNodeId];
    if (inputValue == null || !nodeIds.contains(input.sourceNodeId)) {
      return EvalResult.success(0.0, expression: '?');
    }

    // Only use expression if source node still exists and has value
    final inputExpr =
        nodeIds.contains(input.sourceNodeId) &&
            values.containsKey(input.sourceNodeId)
        ? (expressions[input.sourceNodeId] ??
              MathFormatters.formatNumber(inputValue))
        : '?';

    return EvalResult.success(inputValue, expression: inputExpr);
  }

  /// Detects cycles in the graph using DFS with three-color marking.
  ///
  /// Uses the "visiting" set to track nodes in the current DFS path.
  /// If we encounter a node already in "visiting", we've found a back edge (cycle).
  ///
  /// Separate from controller.hasCycles() because this evaluator operates on
  /// raw MathNodeData lists and needs cycle detection as part of evaluation.
  static bool _hasCycle(
    List<MathNodeData> nodes,
    List<Connection> connections,
    Set<String> nodeIds,
  ) {
    final visiting = <String>{};
    final visited = <String>{};

    bool dfs(String nodeId) {
      if (!nodeIds.contains(nodeId)) return false;
      if (visiting.contains(nodeId)) return true;
      if (visited.contains(nodeId)) return false;

      visiting.add(nodeId);

      for (final conn in connections.where(
        (c) => c.sourceNodeId == nodeId && nodeIds.contains(c.targetNodeId),
      )) {
        if (dfs(conn.targetNodeId)) return true;
      }

      visiting.remove(nodeId);
      visited.add(nodeId);
      return false;
    }

    for (final node in nodes) {
      if (dfs(node.id)) return true;
    }
    return false;
  }

  /// Sorts nodes in dependency order using Kahn's algorithm.
  ///
  /// Guarantees that when evaluating node N, all nodes that N depends on
  /// have already been evaluated. This enables single-pass evaluation.
  ///
  /// Algorithm:
  /// 1. Count incoming edges (in-degree) for each node
  /// 2. Start with nodes that have no dependencies (in-degree = 0)
  /// 3. Process each node, decrementing in-degrees of its neighbors
  /// 4. Add neighbors to queue when their in-degree becomes 0
  static List<MathNodeData> _topologicalSort(
    List<MathNodeData> nodes,
    List<Connection> connections,
    Set<String> nodeIds,
  ) {
    final nodeMap = {for (final n in nodes) n.id: n};
    final inDegree = <String, int>{};
    final adjacency = <String, List<String>>{};

    for (final node in nodes) {
      inDegree[node.id] = 0;
      adjacency[node.id] = [];
    }

    for (final conn in connections) {
      if (nodeIds.contains(conn.sourceNodeId) &&
          nodeIds.contains(conn.targetNodeId)) {
        adjacency[conn.sourceNodeId]!.add(conn.targetNodeId);
        inDegree[conn.targetNodeId] = (inDegree[conn.targetNodeId] ?? 0) + 1;
      }
    }

    final queue = <String>[
      for (final entry in inDegree.entries)
        if (entry.value == 0) entry.key,
    ];

    final result = <MathNodeData>[];

    while (queue.isNotEmpty) {
      final nodeId = queue.removeAt(0);
      final node = nodeMap[nodeId];
      if (node != null) result.add(node);

      for (final neighbor in adjacency[nodeId] ?? []) {
        if (!nodeIds.contains(neighbor)) continue;
        inDegree[neighbor] = (inDegree[neighbor] ?? 1) - 1;
        if (inDegree[neighbor] == 0) {
          queue.add(neighbor);
        }
      }
    }

    return result;
  }
}
