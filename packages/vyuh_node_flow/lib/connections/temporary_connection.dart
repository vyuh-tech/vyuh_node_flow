import 'package:flutter/material.dart';
import 'package:mobx/mobx.dart';

/// Represents a temporary connection during a drag-and-drop operation.
///
/// A [TemporaryConnection] is created when a user starts dragging from a port
/// and is updated as the mouse/pointer moves. It becomes a permanent connection
/// when dropped on a valid target port, or is discarded if the drag is cancelled.
///
/// ## Immutable Properties (Set at Start)
/// - [startPoint]: Where the connection starts (source port position)
/// - [sourceNodeId]: ID of the source node
/// - [sourcePortId]: ID of the source port
///
/// ## Observable Properties (Change During Drag)
/// - [currentPoint]: Current pointer position
/// - [targetNodeId]: ID of the target node (null until hovering over valid target)
/// - [targetPortId]: ID of the target port (null until hovering over valid target)
///
/// ## Usage Example
/// ```dart
/// // Create when drag starts
/// final tempConnection = TemporaryConnection(
///   startPoint: portPosition,
///   sourceNodeId: 'node-1',
///   sourcePortId: 'port-out',
///   initialCurrentPoint: portPosition,
/// );
///
/// // Update as pointer moves
/// tempConnection.currentPoint = newPointerPosition;
///
/// // Set target when hovering over a valid port
/// tempConnection.targetNodeId = 'node-2';
/// tempConnection.targetPortId = 'port-in';
/// ```
///
/// See also:
/// - [Connection] for permanent connections
/// - [NodeFlowController] for managing temporary connections
class TemporaryConnection {
  /// Creates a temporary connection for drag-and-drop operations.
  ///
  /// Parameters:
  /// - [startPoint]: The position where the connection starts (source port position)
  /// - [sourceNodeId]: ID of the node containing the source port
  /// - [sourcePortId]: ID of the source port
  /// - [initialCurrentPoint]: Initial pointer position (typically same as [startPoint])
  /// - [targetNodeId]: Optional ID of the target node (set when hovering over a port)
  /// - [targetPortId]: Optional ID of the target port (set when hovering over a port)
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

  /// The position where the connection starts (source port position).
  ///
  /// This is set when the drag operation begins and remains constant.
  final Offset startPoint;

  /// ID of the node containing the source port.
  final String sourceNodeId;

  /// ID of the source port where the connection originates.
  final String sourcePortId;

  // Observable target properties (change during drag)
  final Observable<Offset> _currentPoint;
  final Observable<String?> _targetNodeId;
  final Observable<String?> _targetPortId;

  /// The current pointer position.
  ///
  /// This updates continuously as the user drags the connection.
  Offset get currentPoint => _currentPoint.value;

  /// ID of the target node.
  ///
  /// Set to null when not hovering over a valid target, or to the node ID
  /// when hovering over a valid target port.
  String? get targetNodeId => _targetNodeId.value;

  /// ID of the target port.
  ///
  /// Set to null when not hovering over a valid target, or to the port ID
  /// when hovering over a valid target port.
  String? get targetPortId => _targetPortId.value;

  /// Sets the current pointer position.
  set currentPoint(Offset value) => _currentPoint.value = value;

  /// Sets the target node ID.
  set targetNodeId(String? value) => _targetNodeId.value = value;

  /// Sets the target port ID.
  set targetPortId(String? value) => _targetPortId.value = value;

  /// Gets the MobX observable for the current point.
  ///
  /// Use this when you need to observe position changes in MobX reactions
  /// or computed values. For simple access, use [currentPoint] instead.
  Observable<Offset> get currentPointObservable => _currentPoint;

  /// Gets the MobX observable for the target node ID.
  ///
  /// Use this when you need to observe target node changes in MobX reactions
  /// or computed values. For simple access, use [targetNodeId] instead.
  Observable<String?> get targetNodeIdObservable => _targetNodeId;

  /// Gets the MobX observable for the target port ID.
  ///
  /// Use this when you need to observe target port changes in MobX reactions
  /// or computed values. For simple access, use [targetPortId] instead.
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
