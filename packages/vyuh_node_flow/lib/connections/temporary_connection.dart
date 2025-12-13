import 'package:flutter/material.dart';
import 'package:mobx/mobx.dart';

/// Represents a temporary connection during a drag-and-drop operation.
///
/// A [TemporaryConnection] is created when a user starts dragging from a port
/// and is updated as the mouse/pointer moves. It becomes a permanent connection
/// when dropped on a valid target port, or is discarded if the drag is cancelled.
///
/// ## Port Direction Semantics
///
/// The [isStartFromOutput] flag determines the logical role of each endpoint:
/// - When `true` (dragging from output): start port is SOURCE, mouse is TARGET
/// - When `false` (dragging from input): start port is TARGET, mouse is SOURCE
///
/// This is important for path routing - connections always flow from source to target.
///
/// ## Immutable Properties (Set at Start)
/// - [startPoint]: Where the drag started (port position)
/// - [startNodeId]: ID of the node where drag started
/// - [startPortId]: ID of the port where drag started
/// - [isStartFromOutput]: Whether the drag started from an output port
/// - [startNodeBounds]: Bounds of the starting node (for routing)
///
/// ## Observable Properties (Change During Drag)
/// - [currentPoint]: Current pointer position
/// - [targetNodeId]: ID of the hovered node (null until hovering over valid target)
/// - [targetPortId]: ID of the hovered port (null until hovering over valid target)
/// - [targetNodeBounds]: Bounds of the hovered node (null until hovering)
///
/// ## Usage Example
/// ```dart
/// // Create when drag starts from an output port
/// final tempConnection = TemporaryConnection(
///   startPoint: portPosition,
///   startNodeId: 'node-1',
///   startPortId: 'port-out',
///   isStartFromOutput: true,
///   startNodeBounds: node.getBounds(),
///   initialCurrentPoint: portPosition,
/// );
///
/// // Update as pointer moves
/// tempConnection.currentPoint = newPointerPosition;
///
/// // Set target when hovering over a valid port
/// tempConnection.targetNodeId = 'node-2';
/// tempConnection.targetPortId = 'port-in';
/// tempConnection.targetNodeBounds = targetNode.getBounds();
/// ```
///
/// See also:
/// - [Connection] for permanent connections
/// - [NodeFlowController] for managing temporary connections
class TemporaryConnection {
  /// Creates a temporary connection for drag-and-drop operations.
  ///
  /// Parameters:
  /// - [startPoint]: The position where the drag started (port position)
  /// - [startNodeId]: ID of the node containing the starting port
  /// - [startPortId]: ID of the starting port
  /// - [isStartFromOutput]: Whether the drag started from an output port
  /// - [startNodeBounds]: Bounds of the starting node for node-aware routing
  /// - [initialCurrentPoint]: Initial pointer position (typically same as [startPoint])
  /// - [targetNodeId]: Optional ID of the target node (set when hovering over a port)
  /// - [targetPortId]: Optional ID of the target port (set when hovering over a port)
  /// - [targetNodeBounds]: Optional bounds of the target node (set when hovering)
  TemporaryConnection({
    required this.startPoint,
    required this.startNodeId,
    required this.startPortId,
    required this.isStartFromOutput,
    required this.startNodeBounds,
    required Offset initialCurrentPoint,
    String? targetNodeId,
    String? targetPortId,
    Rect? targetNodeBounds,
  }) : _currentPoint = Observable(initialCurrentPoint),
       _targetNodeId = Observable(targetNodeId),
       _targetPortId = Observable(targetPortId),
       _targetNodeBounds = Observable(targetNodeBounds);

  // Immutable properties (set when connection starts)

  /// The position where the drag started (port position).
  ///
  /// This is set when the drag operation begins and remains constant.
  final Offset startPoint;

  /// ID of the node where the drag started.
  final String startNodeId;

  /// ID of the port where the drag started.
  final String startPortId;

  /// Whether the drag started from an output port.
  ///
  /// This determines the logical direction of the connection:
  /// - `true`: The starting port is the SOURCE, mouse position is TARGET
  /// - `false`: The starting port is the TARGET, mouse position is SOURCE
  final bool isStartFromOutput;

  /// Bounds of the node where the drag started.
  ///
  /// Used for node-aware routing to ensure connections don't pass through nodes.
  final Rect startNodeBounds;

  // Observable properties (change during drag)
  final Observable<Offset> _currentPoint;
  final Observable<String?> _targetNodeId;
  final Observable<String?> _targetPortId;
  final Observable<Rect?> _targetNodeBounds;

  /// The current pointer position.
  ///
  /// This updates continuously as the user drags the connection.
  Offset get currentPoint => _currentPoint.value;

  /// ID of the hovered node.
  ///
  /// Set to null when not hovering over a valid target, or to the node ID
  /// when hovering over a valid target port.
  String? get targetNodeId => _targetNodeId.value;

  /// ID of the hovered port.
  ///
  /// Set to null when not hovering over a valid target, or to the port ID
  /// when hovering over a valid target port.
  String? get targetPortId => _targetPortId.value;

  /// Bounds of the hovered node.
  ///
  /// Set to null when not hovering over a valid target, or to the node bounds
  /// when hovering over a valid target port. Used for node-aware routing.
  Rect? get targetNodeBounds => _targetNodeBounds.value;

  /// Sets the current pointer position.
  set currentPoint(Offset value) => _currentPoint.value = value;

  /// Sets the target node ID.
  set targetNodeId(String? value) => _targetNodeId.value = value;

  /// Sets the target port ID.
  set targetPortId(String? value) => _targetPortId.value = value;

  /// Sets the target node bounds.
  set targetNodeBounds(Rect? value) => _targetNodeBounds.value = value;

  /// Gets the MobX observable for the current point.
  Observable<Offset> get currentPointObservable => _currentPoint;

  /// Gets the MobX observable for the target node ID.
  Observable<String?> get targetNodeIdObservable => _targetNodeId;

  /// Gets the MobX observable for the target port ID.
  Observable<String?> get targetPortIdObservable => _targetPortId;

  /// Gets the MobX observable for the target node bounds.
  Observable<Rect?> get targetNodeBoundsObservable => _targetNodeBounds;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TemporaryConnection &&
          runtimeType == other.runtimeType &&
          startPoint == other.startPoint &&
          startNodeId == other.startNodeId &&
          startPortId == other.startPortId &&
          isStartFromOutput == other.isStartFromOutput &&
          startNodeBounds == other.startNodeBounds &&
          currentPoint == other.currentPoint &&
          targetNodeId == other.targetNodeId &&
          targetPortId == other.targetPortId &&
          targetNodeBounds == other.targetNodeBounds;

  @override
  int get hashCode => Object.hash(
    startPoint,
    startNodeId,
    startPortId,
    isStartFromOutput,
    startNodeBounds,
    currentPoint,
    targetNodeId,
    targetPortId,
    targetNodeBounds,
  );
}
