import 'package:flutter/material.dart';
import 'package:mobx/mobx.dart';

/// Temporary connection state during drag operations
/// Source properties are immutable (set once when connection starts)
/// Target properties are observable (change during drag)
class TemporaryConnection {
  TemporaryConnection({
    required this.startPoint,
    required this.sourceNodeId,
    required this.sourcePortId,
    required Offset initialCurrentPoint,
    String? targetNodeId,
    String? targetPortId,
  }) : _currentPoint = Observable(initialCurrentPoint),
       _targetNodeId = Observable(targetNodeId),
       _targetPortId = Observable(targetPortId);

  // Immutable source properties (set when connection starts)
  final Offset startPoint;
  final String sourceNodeId;
  final String sourcePortId;

  // Observable target properties (change during drag)
  final Observable<Offset> _currentPoint;
  final Observable<String?> _targetNodeId;
  final Observable<String?> _targetPortId;

  // Getters for observable properties
  Offset get currentPoint => _currentPoint.value;

  String? get targetNodeId => _targetNodeId.value;

  String? get targetPortId => _targetPortId.value;

  // Setters for observable properties
  set currentPoint(Offset value) => _currentPoint.value = value;

  set targetNodeId(String? value) => _targetNodeId.value = value;

  set targetPortId(String? value) => _targetPortId.value = value;

  // Observable getters for direct observation
  Observable<Offset> get currentPointObservable => _currentPoint;

  Observable<String?> get targetNodeIdObservable => _targetNodeId;

  Observable<String?> get targetPortIdObservable => _targetPortId;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TemporaryConnection &&
          runtimeType == other.runtimeType &&
          startPoint == other.startPoint &&
          currentPoint == other.currentPoint &&
          sourceNodeId == other.sourceNodeId &&
          sourcePortId == other.sourcePortId &&
          targetNodeId == other.targetNodeId &&
          targetPortId == other.targetPortId;

  @override
  int get hashCode =>
      startPoint.hashCode ^
      currentPoint.hashCode ^
      sourceNodeId.hashCode ^
      sourcePortId.hashCode ^
      targetNodeId.hashCode ^
      targetPortId.hashCode;
}
