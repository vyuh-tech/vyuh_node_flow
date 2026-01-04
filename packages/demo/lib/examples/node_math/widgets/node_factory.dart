import 'package:flutter/material.dart';
import 'package:vyuh_node_flow/vyuh_node_flow.dart';

import '../constants.dart';
import '../evaluation.dart';
import '../models.dart';
import '../theme.dart';
import 'function_node.dart';
import 'number_node.dart';
import 'operator_node.dart';
import 'result_node.dart';
import 'rounded_rectangle_marker_shape.dart';

/// Factory for creating math nodes and their widgets.
class MathNodeFactory {
  /// Build node content widget based on type.
  static Widget buildContent(
    Node<MathNodeData> node,
    EvalResult? result,
    void Function(MathNodeData) onUpdate,
  ) {
    final data = node.data;

    return switch (data) {
      NumberData() => NumberNodeContent(
        data: data,
        result: result,
        onChanged: onUpdate,
      ),
      OperatorData() => OperatorNodeContent(
        data: data,
        onOperatorChanged: (op) => onUpdate(data.copyWith(operator: op)),
      ),
      FunctionData() => FunctionNodeContent(data: data, result: result),
      ResultData() => ResultNodeContent(data: data, result: result),
    };
  }

  /// Create a vyuh Node from MathNodeData.
  static Node<MathNodeData> createNode(MathNodeData data, Offset position) {
    final size = MathNodeSizes.forType(data.type);

    return Node<MathNodeData>(
      id: data.id,
      type: data.type,
      position: position,
      size: size,
      data: data,
      inputPorts: _createInputPorts(data, size),
      outputPorts: _createOutputPorts(data, size),
    );
  }

  /// Create a PortTheme for vertical rounded rectangle ports with border.
  static PortTheme _portThemeFor(Color color) {
    return PortTheme.light.copyWith(
      color: color,
      connectedColor: color,
      highlightColor: color,
      size: const Size(10, 22), // Vertical rectangle
      borderWidth: 1,
      borderColor: Colors.white,
      shape: const RoundedRectangleMarkerShape(borderRadius: 4.0),
    );
  }

  static List<Port> _createInputPorts(MathNodeData data, Size size) {
    final portColor = MathColors.portColorFor(data.type);
    final portTheme = _portThemeFor(portColor);

    return switch (data) {
      NumberData() => [],
      OperatorData() => [
        Port(
          id: '${data.id}-input-a',
          name: 'A',
          type: PortType.input,
          position: PortPosition.left,
          // Centered on left edge, 1/3 from top
          offset: Offset(-3, size.height * 0.30),
          theme: portTheme,
          maxConnections: MathPortConfig.maxInputConnections,
        ),
        Port(
          id: '${data.id}-input-b',
          name: 'B',
          type: PortType.input,
          position: PortPosition.left,
          // Centered on left edge, 2/3 from top
          offset: Offset(-3, size.height * 0.70),
          theme: portTheme,
          maxConnections: MathPortConfig.maxInputConnections,
        ),
      ],
      FunctionData() => [
        Port(
          id: '${data.id}-input',
          name: 'x',
          type: PortType.input,
          position: PortPosition.left,
          offset: Offset(-3, size.height / 2),
          theme: portTheme,
          maxConnections: MathPortConfig.maxInputConnections,
        ),
      ],
      ResultData() => [
        Port(
          id: '${data.id}-input',
          name: 'value',
          type: PortType.input,
          position: PortPosition.left,
          offset: Offset(-3, size.height / 2),
          theme: _portThemeFor(MathColors.portResult),
          maxConnections: MathPortConfig.maxInputConnections,
        ),
      ],
    };
  }

  static List<Port> _createOutputPorts(MathNodeData data, Size size) {
    final portColor = MathColors.portColorFor(data.type);
    final portTheme = _portThemeFor(portColor);

    return switch (data) {
      NumberData() => [
        Port(
          id: '${data.id}-output',
          name: 'value',

          type: PortType.output,
          position: PortPosition.right,
          offset: Offset(3, size.height / 2),
          theme: portTheme,
          multiConnections: true,
        ),
      ],
      OperatorData() || FunctionData() => [
        Port(
          id: '${data.id}-output',
          name: 'result',
          type: PortType.output,
          position: PortPosition.right,
          offset: Offset(3, size.height / 2),
          theme: portTheme,
          multiConnections: true,
        ),
      ],
      ResultData() => [],
    };
  }
}
