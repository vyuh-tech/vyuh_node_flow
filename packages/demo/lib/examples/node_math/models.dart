import 'package:flutter/material.dart';
import 'package:vyuh_node_flow/vyuh_node_flow.dart';

import 'constants.dart';

/// Base class for all math node data.
sealed class MathNodeData implements NodeData {
  final String id;
  final String type;

  const MathNodeData({required this.id, required this.type});

  @override
  MathNodeData clone();

  /// Signature for change detection.
  String get signature;

  /// Copy with new position (used by sync).
  MathNodeData copyWithPosition(Offset position);
}

/// Number input node.
class NumberData extends MathNodeData {
  final double value;
  final Offset? position;

  const NumberData({required super.id, required this.value, this.position})
    : super(type: MathNodeTypes.number);

  @override
  NumberData clone() => NumberData(id: id, value: value, position: position);

  @override
  String get signature => '$id:$value';

  @override
  NumberData copyWithPosition(Offset position) =>
      NumberData(id: id, value: value, position: position);

  NumberData copyWith({double? value, Offset? position}) => NumberData(
    id: id,
    value: value ?? this.value,
    position: position ?? this.position,
  );
}

/// Operator node (+, -, ×, ÷).
class OperatorData extends MathNodeData {
  final MathOperator operator;
  final Offset? position;

  const OperatorData({required super.id, required this.operator, this.position})
    : super(type: MathNodeTypes.operator);

  @override
  OperatorData clone() =>
      OperatorData(id: id, operator: operator, position: position);

  @override
  String get signature => '$id:${operator.name}';

  @override
  OperatorData copyWithPosition(Offset position) =>
      OperatorData(id: id, operator: operator, position: position);

  OperatorData copyWith({MathOperator? operator, Offset? position}) =>
      OperatorData(
        id: id,
        operator: operator ?? this.operator,
        position: position ?? this.position,
      );
}

/// Function node (sin, cos, sqrt).
class FunctionData extends MathNodeData {
  final MathFunction function;
  final Offset? position;

  const FunctionData({required super.id, required this.function, this.position})
    : super(type: MathNodeTypes.function);

  @override
  FunctionData clone() =>
      FunctionData(id: id, function: function, position: position);

  @override
  String get signature => '$id:${function.name}';

  @override
  FunctionData copyWithPosition(Offset position) =>
      FunctionData(id: id, function: function, position: position);

  FunctionData copyWith({MathFunction? function, Offset? position}) =>
      FunctionData(
        id: id,
        function: function ?? this.function,
        position: position ?? this.position,
      );
}

/// Result/output node.
class ResultData extends MathNodeData {
  final String label;
  final Offset? position;

  const ResultData({required super.id, this.label = 'Result', this.position})
    : super(type: MathNodeTypes.result);

  @override
  ResultData clone() => ResultData(id: id, label: label, position: position);

  @override
  String get signature => '$id:$label';

  @override
  ResultData copyWithPosition(Offset position) =>
      ResultData(id: id, label: label, position: position);

  ResultData copyWith({String? label, Offset? position}) => ResultData(
    id: id,
    label: label ?? this.label,
    position: position ?? this.position,
  );
}
