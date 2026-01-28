import 'package:flutter/material.dart';
import 'package:vyuh_node_flow/vyuh_node_flow.dart';

import '../../core/constants.dart';
import '../../core/models.dart';
import '../../evaluation/evaluator.dart';
import '../../presentation/theme.dart';
import '../nodes/function_node.dart';
import '../nodes/number_node.dart';
import '../nodes/operator_node.dart';
import '../nodes/result_node.dart';
import 'rounded_rectangle_marker_shape.dart';

class MathNodeFactory {
  static Widget buildContent(
    Node<MathNodeData> node,
    EvalResult? result,
    void Function(MathNodeData) onUpdate, {
    void Function(String nodeId, Size newSize)? onNodeSizeChanged,
  }) {
    final data = node.data;

    return switch (data) {
      NumberData() => NumberNodeContent(data: data, onChanged: onUpdate),
      OperatorData() => OperatorNodeContent(
        data: data,
        onOperatorChanged: (op) => onUpdate(data.copyWith(operator: op)),
      ),
      FunctionData() => FunctionNodeContent(data: data),
      ResultData() => ResultNodeContent(
        data: data,
        result: result,
        onSizeChanged: onNodeSizeChanged != null
            ? (size) => onNodeSizeChanged(data.id, size)
            : null,
      ),
    };
  }

  static Node<MathNodeData> createNode(MathNodeData data, Offset position) {
    final size = MathNodeSizes.forType(data.type);
    final portColor = MathColors.portColorFor(data.type);
    final baseTheme = MathTheme.nodeFlowTheme.nodeTheme;

    return Node<MathNodeData>(
      id: data.id,
      type: data.type,
      position: position,
      size: size,
      data: data,
      ports: [
        ..._createInputPorts(data, size),
        ..._createOutputPorts(data, size),
      ],
      theme: baseTheme.copyWith(selectedBorderColor: portColor),
    );
  }

  static PortTheme _portThemeFor(Color color) {
    return PortTheme.light.copyWith(
      color: color,
      connectedColor: color,
      highlightColor: color,
      size: const Size(10, 22),
      borderWidth: 1,
      borderColor: Colors.white,
      shape: const RoundedRectangleMarkerShape(borderRadius: 4.0),
    );
  }

  static List<Port> _createInputPorts(MathNodeData data, Size size) {
    final portColor = MathColors.portColorFor(data.type);
    final portTheme = _portThemeFor(portColor);
    final hOffset = -MathPortConfig.horizontalOffset;

    return switch (data) {
      NumberData() => [],
      OperatorData() => [
        Port(
          id: MathPortIds.inputA(data.id),
          name: 'A',
          type: PortType.input,
          position: PortPosition.left,
          offset: Offset(
            hOffset,
            size.height * MathPortConfig.operatorPortAVerticalRatio,
          ),
          theme: portTheme,
          maxConnections: MathPortConfig.maxInputConnections,
        ),
        Port(
          id: MathPortIds.inputB(data.id),
          name: 'B',
          type: PortType.input,
          position: PortPosition.left,
          offset: Offset(
            hOffset,
            size.height * MathPortConfig.operatorPortBVerticalRatio,
          ),
          theme: portTheme,
          maxConnections: MathPortConfig.maxInputConnections,
        ),
      ],
      FunctionData() => [
        Port(
          id: MathPortIds.input(data.id),
          name: 'x',
          type: PortType.input,
          position: PortPosition.left,
          offset: Offset(hOffset, size.height / 2),
          theme: portTheme,
          maxConnections: MathPortConfig.maxInputConnections,
        ),
      ],
      ResultData() => [
        Port(
          id: MathPortIds.input(data.id),
          name: 'value',
          type: PortType.input,
          position: PortPosition.left,
          offset: Offset(hOffset, size.height / 2),
          theme: _portThemeFor(MathColors.portResult),
          maxConnections: MathPortConfig.maxInputConnections,
        ),
      ],
    };
  }

  static List<Port> _createOutputPorts(MathNodeData data, Size size) {
    final portColor = MathColors.portColorFor(data.type);
    final portTheme = _portThemeFor(portColor);
    final hOffset = MathPortConfig.horizontalOffset;

    return switch (data) {
      NumberData() => [
        Port(
          id: MathPortIds.output(data.id),
          name: 'value',
          type: PortType.output,
          position: PortPosition.right,
          offset: Offset(hOffset, size.height / 2),
          theme: portTheme,
          multiConnections: true,
        ),
      ],
      OperatorData() || FunctionData() => [
        Port(
          id: MathPortIds.output(data.id),
          name: 'result',
          type: PortType.output,
          position: PortPosition.right,
          offset: Offset(hOffset, size.height / 2),
          theme: portTheme,
          multiConnections: true,
        ),
      ],
      ResultData() => [],
    };
  }
}
