library;

import 'package:vyuh_node_flow/vyuh_node_flow.dart';

import '../../core/constants.dart';
import '../../core/models.dart';
import '../../evaluation/evaluator.dart';

enum ValidationLevel { info, warning, error }

class ValidationMessage {
  final ValidationLevel level;
  final String title;
  final String message;
  final String? suggestion;
  final String? nodeId;

  const ValidationMessage({
    required this.level,
    required this.title,
    required this.message,
    this.suggestion,
    this.nodeId,
  });

  int get priority => level.index;
}

class MathValidator {
  static List<ValidationMessage> validate(
    NodeFlowController<MathNodeData, dynamic> controller,
    Map<String, EvalResult> results,
  ) {
    final messages = <ValidationMessage>[];

    if (controller.nodes.isEmpty) {
      messages.add(
        const ValidationMessage(
          level: ValidationLevel.info,
          title: 'Get Started',
          message:
          'Add nodes from the toolbox to begin building your expression.',
          suggestion:
          'Start by adding a Number node, then connect it to an Operator.',
        ),
      );
      return messages;
    }

    final nodeIds = controller.nodes.keys.toSet();
    final validConnections = controller.connections.where(
      (c) =>
      nodeIds.contains(c.sourceNodeId) && nodeIds.contains(c.targetNodeId),
    );

    for (final nodeEntry in controller.nodes.entries) {
      final nodeId = nodeEntry.key;
      final node = nodeEntry.value;
      final data = node.data;

      switch (data) {
        case OperatorData():
          _validateOperator(
            nodeId,
            data,
            validConnections,
            results[nodeId],
            messages,
            controller,
          );

        case FunctionData():
          _validateFunction(
            nodeId,
            data,
            validConnections,
            results[nodeId],
            messages,
            controller,
          );

        case ResultData():
          _validateResult(nodeId, validConnections, results[nodeId], messages);

        case NumberData():
          _validateNumber(nodeId, validConnections, messages);
      }
    }

    _validateCycles(controller, messages);

    // If no validation messages, provide next step guidance
    if (messages.isEmpty) {
      messages.add(_getNextStepGuidance(controller, validConnections));
    }

    messages.sort((a, b) => b.priority.compareTo(a.priority));
    return messages;
  }

  static ValidationMessage _getNextStepGuidance(
    NodeFlowController<MathNodeData, dynamic> controller,
    Iterable<Connection> validConnections,
  ) {
    final nodes = controller.nodes.values.toList();
    final nodeDataList = nodes.map((n) => n.data).toList();

    // Check if there's a complete expression chain
    final hasNumberNodes = nodeDataList.any((d) => d is NumberData);
    final hasOperatorNodes = nodeDataList.any((d) => d is OperatorData);
    final hasFunctionNodes = nodeDataList.any((d) => d is FunctionData);
    final hasResultNodes = nodeDataList.any((d) => d is ResultData);

    // Check if result node has input
    final resultNodes = nodes.where((n) => n.data.type == MathNodeTypes.result);
    final hasConnectedResult = resultNodes.any((resultNode) {
      final inputPortId = MathPortIds.input(resultNode.id);
      return validConnections.any(
            (c) =>
        c.targetNodeId == resultNode.id && c.targetPortId == inputPortId,
      );
    });

    if (!hasNumberNodes && !hasFunctionNodes) {
      return const ValidationMessage(
        level: ValidationLevel.info,
        title: 'Get Started',
        message:
        'Click on "Number" in the toolbox to add a number node and start building your expression.',
      );
    }

    if (!hasOperatorNodes && !hasFunctionNodes) {
      return const ValidationMessage(
        level: ValidationLevel.info,
        title: 'Add an Operator or Function',
        message:
        'Add an Operator or Function node from the toolbox to perform calculations.',
      );
    }

    if (!hasResultNodes) {
      return const ValidationMessage(
        level: ValidationLevel.info,
        title: 'Add a Result Node',
        message:
        'Add a Result node from the toolbox to see the final calculation result.',
      );
    }

    if (!hasConnectedResult) {
      return const ValidationMessage(
        level: ValidationLevel.info,
        title: 'Connect to Result',
        message:
        'Connect an operator or function output to the Result node to see the calculation.',
      );
    }

    // Everything is connected - suggest adding more or building complex expressions
    return const ValidationMessage(
      level: ValidationLevel.info,
      title: 'Expression Complete',
      message:
      'Your expression is complete! Try adding more nodes to build complex calculations.',
    );
  }

  static void _validateOperator(
    String nodeId,
    OperatorData data,
    Iterable<Connection> validConnections,
    EvalResult? result,
    List<ValidationMessage> messages,
    NodeFlowController<MathNodeData, dynamic> controller,
  ) {
    final portAId = MathPortIds.inputA(nodeId);
    final portBId = MathPortIds.inputB(nodeId);
    final outputPortId = MathPortIds.output(nodeId);

    final inputA = validConnections
        .where((c) => c.targetNodeId == nodeId && c.targetPortId == portAId)
        .isNotEmpty;
    final inputB = validConnections
        .where((c) => c.targetNodeId == nodeId && c.targetPortId == portBId)
        .isNotEmpty;

    if (!inputA && !inputB) {
      messages.add(
        ValidationMessage(
          level: ValidationLevel.warning,
          title: 'Operator Needs Inputs',
          message:
          'This operator requires 2 inputs (A and B). Connect number nodes to both input ports.',
          suggestion:
          'Connect two Number nodes: one to port A (top) and one to port B (bottom).',
          nodeId: nodeId,
        ),
      );
    } else if (!inputA) {
      messages.add(
        ValidationMessage(
          level: ValidationLevel.warning,
          title: 'Operator Missing Input A',
          message:
          'Operator needs input A (top port). Connect a number or operator output.',
          suggestion:
          'Connect a Number node or another Operator\'s output to the top input port.',
          nodeId: nodeId,
        ),
      );
    } else if (!inputB) {
      messages.add(
        ValidationMessage(
          level: ValidationLevel.warning,
          title: 'Operator Missing Input B',
          message:
          'Operator needs input B (bottom port). Connect a number or operator output.',
          suggestion:
          'Connect a Number node or another Operator\'s output to the bottom input port.',
          nodeId: nodeId,
        ),
      );
    }

    // Check if operator has inputs but output doesn't eventually reach result node
    // Only suggest if operator has at least one input (partially or fully ready)
    if (inputA || inputB) {
      final eventuallyReachesResult = _outputEventuallyReachesResult(
        nodeId,
        outputPortId,
        validConnections,
        controller,
      );

      if (!eventuallyReachesResult) {
        messages.add(
          ValidationMessage(
            level: ValidationLevel.info,
            title: 'Connect to Result',
            message:
            'Connect the output to a Result node to see the calculation result.',
            nodeId: nodeId,
          ),
        );
      }
    }

    if (result?.hasError ?? false) {
      messages.add(
        ValidationMessage(
          level: ValidationLevel.error,
          title: 'Operator Error',
          message: result!.error ?? 'Invalid operation',
          suggestion: _getErrorSuggestion(result.error ?? ''),
          nodeId: nodeId,
        ),
      );
    }
  }

  static void _validateFunction(
    String nodeId,
    FunctionData data,
    Iterable<Connection> validConnections,
    EvalResult? result,
    List<ValidationMessage> messages,
    NodeFlowController<MathNodeData, dynamic> controller,
  ) {
    final inputPortId = MathPortIds.input(nodeId);
    final outputPortId = MathPortIds.output(nodeId);
    final hasInput = validConnections
        .where((c) => c.targetNodeId == nodeId && c.targetPortId == inputPortId)
        .isNotEmpty;

    if (!hasInput) {
      messages.add(
        ValidationMessage(
          level: ValidationLevel.warning,
          title: 'Function Needs Input',
          message:
          '${data.function.symbol}() function requires an input value.',
          suggestion:
          'Connect a Number node or Operator output to the function input.',
          nodeId: nodeId,
        ),
      );
    }

    // Check if function has input but output doesn't eventually reach result node
    if (hasInput) {
      final eventuallyReachesResult = _outputEventuallyReachesResult(
        nodeId,
        outputPortId,
        validConnections,
        controller,
      );

      if (!eventuallyReachesResult) {
        messages.add(
          ValidationMessage(
            level: ValidationLevel.info,
            title: 'Connect to Result',
            message:
            'Connect the output to a Result node to see the calculation result.',
            nodeId: nodeId,
          ),
        );
      }
    }

    if (result?.hasError ?? false) {
      messages.add(
        ValidationMessage(
          level: ValidationLevel.error,
          title: 'Function Error',
          message: result!.error ?? 'Invalid input',
          suggestion: _getErrorSuggestion(result.error ?? ''),
          nodeId: nodeId,
        ),
      );
    }
  }

  static void _validateResult(
    String nodeId,
    Iterable<Connection> validConnections,
    EvalResult? result,
    List<ValidationMessage> messages,
  ) {
    final inputPortId = MathPortIds.input(nodeId);
    final hasInput = validConnections
        .where((c) => c.targetNodeId == nodeId && c.targetPortId == inputPortId)
        .isNotEmpty;

    if (!hasInput) {
      messages.add(
        ValidationMessage(
          level: ValidationLevel.info,
          title: 'Result Node Unconnected',
          message: 'Connect an operator or function output to see the result.',
          suggestion:
          'Connect the output port of an Operator or Function to this Result node.',
          nodeId: nodeId,
        ),
      );
    } else if (result?.hasError ?? false) {
      messages.add(
        ValidationMessage(
          level: ValidationLevel.error,
          title: 'Result Error',
          message: result!.error ?? 'Cannot compute result',
          suggestion: _getErrorSuggestion(result.error ?? ''),
          nodeId: nodeId,
        ),
      );
    }
  }

  static void _validateNumber(
    String nodeId,
    Iterable<Connection> validConnections,
    List<ValidationMessage> messages,
  ) {
    final outputPortId = MathPortIds.output(nodeId);
    final hasOutput = validConnections
        .where(
          (c) => c.sourceNodeId == nodeId && c.sourcePortId == outputPortId,
    )
        .isNotEmpty;

    if (!hasOutput) {
      messages.add(
        ValidationMessage(
          level: ValidationLevel.info,
          title: 'Number Node Unused',
          message: 'This number node isn\'t connected to anything.',
          suggestion:
          'Connect its output to an Operator or Function input to use it in calculations.',
          nodeId: nodeId,
        ),
      );
    }
  }

  static void _validateCycles(
    NodeFlowController<MathNodeData, dynamic> controller,
    List<ValidationMessage> messages,
  ) {
    final nodes = controller.nodes.values.map((n) => n.data).toList();
    final connections = controller.connections.toList();

    final hasCycle = MathEvaluator
        .evaluate(
      nodes,
      connections,
    )
        .values
        .any((r) => r.hasError && r.error == 'Cycle detected');

    if (hasCycle) {
      messages.add(
        const ValidationMessage(
          level: ValidationLevel.error,
          title: 'Cycle Detected',
          message:
          'Your graph contains a circular dependency. Remove the circular connection.',
          suggestion:
          'Find and remove the connection that creates a loop in your graph.',
        ),
      );
    }
  }

  /// Checks if a node's output eventually reaches a result node through any path.
  ///
  /// Uses DFS to traverse the graph and find if any path from the node's output
  /// eventually leads to a result node. This handles chains like:
  /// - Operator → Function → Result
  /// - Function → Operator → Result
  /// - Operator → Operator → Result
  /// - Number → Operator → Function → Result
  static bool _outputEventuallyReachesResult(
    String sourceNodeId,
    String outputPortId,
    Iterable<Connection> validConnections,
    NodeFlowController<MathNodeData, dynamic> controller,
  ) {
    final visited = <String>{};

    bool dfs(String currentNodeId) {
      if (visited.contains(currentNodeId)) return false;
      visited.add(currentNodeId);

      final currentNode = controller.getNode(currentNodeId);
      if (currentNode == null) return false;

      // Check if this node is a result node
      if (currentNode.data.type == MathNodeTypes.result) {
        return true;
      }

      // Get the output port ID for this node type
      final nodeOutputPortId = switch (currentNode.data) {
        OperatorData() ||
        FunctionData() ||
        NumberData() => MathPortIds.output(currentNodeId),
        _ => null,
      };

      if (nodeOutputPortId == null) return false;

      // Get all connections from this node's output port
      final outputConnections = validConnections.where(
            (c) =>
        c.sourceNodeId == currentNodeId &&
            c.sourcePortId == nodeOutputPortId,
      );

      // Recursively check if any target node eventually reaches result
      for (final conn in outputConnections) {
        if (dfs(conn.targetNodeId)) {
          return true;
        }
      }

      return false;
    }

    // Start DFS from all nodes connected to the source node's output
    final outputConnections = validConnections.where(
          (c) =>
      c.sourceNodeId == sourceNodeId && c.sourcePortId == outputPortId,
    );

    for (final conn in outputConnections) {
      if (dfs(conn.targetNodeId)) {
        return true;
      }
    }

    return false;
  }

  static String? _getErrorSuggestion(String error) {
    if (error.toLowerCase().contains('division by zero')) {
      return 'Check the second input (B) of the division operator. It should not be zero.';
    }
    if (error.toLowerCase().contains('invalid input')) {
      return 'The input value is invalid for this function. For sqrt, ensure the input is non-negative.';
    }
    if (error.toLowerCase().contains('cycle')) {
      return 'Remove the connection that creates a loop. Each node should flow in one direction.';
    }
    return 'Check the node connections and input values.';
  }
}
