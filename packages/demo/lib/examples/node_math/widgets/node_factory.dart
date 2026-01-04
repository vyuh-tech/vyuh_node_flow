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

/// Factory for creating math nodes and their content widgets.
///
/// Centralizes all node creation logic, ensuring consistent port configuration,
/// theming, and widget building across all node types.
class MathNodeFactory {
  /// Builds the interactive content widget for a node based on its type.
  ///
  /// Returns type-specific widgets:
  /// - NumberData → editable text field for value input
  /// - OperatorData → button group to toggle between +, -, ×, ÷
  /// - FunctionData → static label showing function symbol
  /// - ResultData → computed value display with expression
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

  /// Creates a fully configured [Node] from [MathNodeData].
  ///
  /// Configures the node with:
  /// - Type-appropriate size from [MathNodeSizes]
  /// - Color-coded ports based on node type
  /// - Input/output ports with proper positioning and limits
  /// - Selection border color matching port color for visual consistency
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
      inputPorts: _createInputPorts(data, size),
      outputPorts: _createOutputPorts(data, size),
      theme: baseTheme.copyWith(selectedBorderColor: portColor),
    );
  }

  /// Creates a port theme with vertical rounded rectangle shape.
  ///
  /// All ports use the same geometry (10x22px) but vary by color
  /// to indicate node type visually.
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

  /// Creates input ports based on node type.
  ///
  /// Port configuration by type:
  /// - Number: no inputs (source-only node)
  /// - Operator: two inputs (A, B) at 30% and 70% vertical positions
  /// - Function: single input (x) at center
  /// - Result: single input (value) at center
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

  /// Creates output ports based on node type.
  ///
  /// Port configuration by type:
  /// - Number/Operator/Function: single output with multi-connection enabled
  /// - Result: no outputs (sink-only node)
  ///
  /// Multi-connections allow one output to feed multiple downstream nodes.
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
