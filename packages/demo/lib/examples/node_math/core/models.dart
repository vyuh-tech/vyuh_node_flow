import 'package:flutter/material.dart';
import 'package:vyuh_node_flow/vyuh_node_flow.dart';

import 'constants.dart';

sealed class MathNodeData implements NodeData {
  final String id;
  final String type;

  const MathNodeData({required this.id, required this.type});

  @override
  MathNodeData clone();

  /// Combines id and mutable state for change detection in MobX reactions.
  String get signature;

  Offset? get position;
  MathNodeData copyWithPosition(Offset position);
}

class NumberData extends MathNodeData {
  final double value;
  @override
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

/// Binary arithmetic operator node with two inputs (A, B) and one output.
class OperatorData extends MathNodeData {
  final MathOperator operator;
  @override
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

class FunctionData extends MathNodeData {
  final MathFunction function;
  @override
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

class ResultData extends MathNodeData {
  final String label;
  @override
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
