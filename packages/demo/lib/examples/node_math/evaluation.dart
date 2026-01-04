import 'package:vyuh_node_flow/vyuh_node_flow.dart';

import 'constants.dart';
import 'models.dart';
import 'utils.dart';

/// Result of evaluating a single node.
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

/// Evaluates a math node graph.
class MathEvaluator {
  /// Evaluate all nodes and return results map.
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

    // Check for cycles using only valid connections
    if (_hasCycle(nodes, validConnections, nodeIds)) {
      for (final node in nodes) {
        results[node.id] = EvalResult.error('Cycle detected');
      }
      return results;
    }

    // Topological sort using valid connections
    final sorted = _topologicalSort(nodes, validConnections, nodeIds);

    // Evaluate in order
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

    final hasA =
        inputA != null &&
        nodeIds.contains(inputA.sourceNodeId) &&
        values.containsKey(inputA.sourceNodeId);
    final hasB =
        inputB != null &&
        nodeIds.contains(inputB.sourceNodeId) &&
        values.containsKey(inputB.sourceNodeId);

    if (hasA && !hasB) {
      final aExpr =
          expressions[inputA!.sourceNodeId] ??
          MathFormatters.formatNumber(values[inputA.sourceNodeId]!);
      return EvalResult.success(0.0, expression: aExpr);
    }

    if (!hasA && hasB) {
      final bExpr =
          expressions[inputB!.sourceNodeId] ??
          MathFormatters.formatNumber(values[inputB.sourceNodeId]!);
      return EvalResult.success(0.0, expression: bExpr);
    }

    if (!hasA && !hasB) {
      return EvalResult.success(0.0, expression: '?');
    }

    final aValue = values[inputA!.sourceNodeId]!;
    final bValue = values[inputB!.sourceNodeId]!;
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

    if (input == null || !nodeIds.contains(input.sourceNodeId)) {
      return EvalResult.success(0.0, expression: '${function.symbol}(0)');
    }

    final inputValue = values[input.sourceNodeId];
    if (inputValue == null) {
      return EvalResult.success(0.0, expression: '${function.symbol}(0)');
    }

    final result = function.apply(inputValue);

    if (result.isNaN) {
      return EvalResult.error('Invalid input');
    }

    final inputExpr =
        expressions[input.sourceNodeId] ??
        MathFormatters.formatNumber(inputValue);

    return EvalResult.success(
      result,
      expression: '${function.symbol}($inputExpr)',
    );
  }

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

    if (input == null || !nodeIds.contains(input.sourceNodeId)) {
      return EvalResult.success(0.0, expression: '?');
    }

    final inputValue = values[input.sourceNodeId];
    if (inputValue == null) {
      return EvalResult.success(0.0, expression: '?');
    }

    final inputExpr =
        expressions[input.sourceNodeId] ??
        MathFormatters.formatNumber(inputValue);

    return EvalResult.success(inputValue, expression: inputExpr);
  }

  /// Check if graph has a cycle using DFS.
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

  /// Topological sort using Kahn's algorithm.
  static List<MathNodeData> _topologicalSort(
    List<MathNodeData> nodes,
    List<Connection> connections,
    Set<String> nodeIds,
  ) {
    final nodeMap = {for (final n in nodes) n.id: n};
    final inDegree = <String, int>{};
    final adjacency = <String, List<String>>{};

    // Initialize
    for (final node in nodes) {
      inDegree[node.id] = 0;
      adjacency[node.id] = [];
    }

    // Build graph using only valid connections
    for (final conn in connections) {
      if (nodeIds.contains(conn.sourceNodeId) &&
          nodeIds.contains(conn.targetNodeId)) {
        adjacency[conn.sourceNodeId]!.add(conn.targetNodeId);
        inDegree[conn.targetNodeId] = (inDegree[conn.targetNodeId] ?? 0) + 1;
      }
    }

    // Find nodes with no incoming edges
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
