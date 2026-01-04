import 'package:vyuh_node_flow/vyuh_node_flow.dart';

import 'constants.dart';
import 'models.dart';

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

    // Check for cycles
    if (_hasCycle(nodes, connections)) {
      for (final node in nodes) {
        results[node.id] = EvalResult.error('Cycle detected');
      }
      return results;
    }

    // Topological sort
    final sorted = _topologicalSort(nodes, connections);

    // Evaluate in order
    final values = <String, double>{};
    final expressions = <String, String>{};

    for (final node in sorted) {
      final result = _evaluateNode(node, connections, values, expressions);
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
    Map<String, double> values,
    Map<String, String> expressions,
  ) {
    switch (node) {
      case NumberData(:final value):
        return EvalResult.success(value, expression: _formatNumber(value));

      case OperatorData(:final operator):
        return _evaluateOperator(
          node.id,
          operator,
          connections,
          values,
          expressions,
        );

      case FunctionData(:final function):
        return _evaluateFunction(
          node.id,
          function,
          connections,
          values,
          expressions,
        );

      case ResultData():
        return _evaluateResult(node.id, connections, values, expressions);
    }
  }

  static EvalResult _evaluateOperator(
    String nodeId,
    MathOperator operator,
    List<Connection> connections,
    Map<String, double> values,
    Map<String, String> expressions,
  ) {
    // Find connections to specific input ports (A and B)
    final portAId = '$nodeId-input-a';
    final portBId = '$nodeId-input-b';

    final inputA = connections
        .where((c) => c.targetNodeId == nodeId && c.targetPortId == portAId)
        .firstOrNull;
    final inputB = connections
        .where((c) => c.targetNodeId == nodeId && c.targetPortId == portBId)
        .firstOrNull;

    // Handle missing inputs gracefully - use 0 for disconnected inputs
    double aValue = 0.0;
    double bValue = 0.0;
    String aExpr = '0';
    String bExpr = '0';

    if (inputA != null) {
      final aSourceValue = values[inputA.sourceNodeId];
      if (aSourceValue != null) {
        aValue = aSourceValue;
        aExpr = expressions[inputA.sourceNodeId] ?? _formatNumber(aValue);
      }
    }

    if (inputB != null) {
      final bSourceValue = values[inputB.sourceNodeId];
      if (bSourceValue != null) {
        bValue = bSourceValue;
        bExpr = expressions[inputB.sourceNodeId] ?? _formatNumber(bValue);
      }
    }

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
    Map<String, double> values,
    Map<String, String> expressions,
  ) {
    final input = connections
        .where((c) => c.targetNodeId == nodeId)
        .firstOrNull;

    // Handle missing input gracefully - return neutral state
    if (input == null) {
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
        expressions[input.sourceNodeId] ?? _formatNumber(inputValue);

    return EvalResult.success(
      result,
      expression: '${function.symbol}($inputExpr)',
    );
  }

  static EvalResult _evaluateResult(
    String nodeId,
    List<Connection> connections,
    Map<String, double> values,
    Map<String, String> expressions,
  ) {
    final input = connections
        .where((c) => c.targetNodeId == nodeId)
        .firstOrNull;

    // Handle missing input gracefully - show placeholder
    if (input == null) {
      return EvalResult.success(0.0, expression: '—');
    }

    final inputValue = values[input.sourceNodeId];
    if (inputValue == null) {
      return EvalResult.success(0.0, expression: '—');
    }

    final inputExpr =
        expressions[input.sourceNodeId] ?? _formatNumber(inputValue);

    return EvalResult.success(inputValue, expression: inputExpr);
  }

  static String _formatNumber(double value) {
    if (value == value.toInt()) {
      return value.toInt().toString();
    }
    return value.toStringAsFixed(2);
  }

  /// Check if graph has a cycle using DFS.
  static bool _hasCycle(
    List<MathNodeData> nodes,
    List<Connection> connections,
  ) {
    final visiting = <String>{};
    final visited = <String>{};

    bool dfs(String nodeId) {
      if (visiting.contains(nodeId)) return true;
      if (visited.contains(nodeId)) return false;

      visiting.add(nodeId);

      for (final conn in connections.where((c) => c.sourceNodeId == nodeId)) {
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
  ) {
    final nodeMap = {for (final n in nodes) n.id: n};
    final inDegree = <String, int>{};
    final adjacency = <String, List<String>>{};

    // Initialize
    for (final node in nodes) {
      inDegree[node.id] = 0;
      adjacency[node.id] = [];
    }

    // Build graph
    for (final conn in connections) {
      if (nodeMap.containsKey(conn.sourceNodeId) &&
          nodeMap.containsKey(conn.targetNodeId)) {
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
        inDegree[neighbor] = (inDegree[neighbor] ?? 1) - 1;
        if (inDegree[neighbor] == 0) {
          queue.add(neighbor);
        }
      }
    }

    return result;
  }
}
