part of 'graph_event.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Drag Events - Node Dragging
// ─────────────────────────────────────────────────────────────────────────────

/// Emitted when a node drag operation starts.
class NodeDragStarted extends GraphEvent {
  const NodeDragStarted(this.nodeIds, this.startPosition);

  /// The IDs of nodes being dragged.
  final Set<String> nodeIds;

  /// The starting position in graph coordinates.
  final Offset startPosition;

  @override
  String toString() => 'NodeDragStarted(${nodeIds.length} nodes)';
}

/// Emitted when a node drag operation ends.
class NodeDragEnded extends GraphEvent {
  const NodeDragEnded(this.nodeIds, this.originalPositions);

  /// The IDs of nodes that were dragged.
  final Set<String> nodeIds;

  /// Original positions of nodes before the drag started.
  ///
  /// Used by extensions to implement undo/redo for drag operations.
  final Map<String, Offset> originalPositions;

  @override
  String toString() =>
      'NodeDragEnded(${nodeIds.length} nodes, originalPositions: ${originalPositions.length})';
}

// ─────────────────────────────────────────────────────────────────────────────
// Drag Events - Connection Dragging
// ─────────────────────────────────────────────────────────────────────────────

/// Emitted when connection creation begins (dragging from a port).
class ConnectionDragStarted extends GraphEvent {
  const ConnectionDragStarted({
    required this.sourceNodeId,
    required this.sourcePortId,
    required this.isOutput,
  });

  /// The node ID where the drag started.
  final String sourceNodeId;

  /// The port ID where the drag started.
  final String sourcePortId;

  /// Whether dragging from an output port (true) or input port (false).
  final bool isOutput;

  @override
  String toString() =>
      'ConnectionDragStarted($sourceNodeId:$sourcePortId, isOutput: $isOutput)';
}

/// Emitted when connection drag ends (connected or cancelled).
class ConnectionDragEnded extends GraphEvent {
  const ConnectionDragEnded({required this.wasConnected, this.connection});

  /// Whether a connection was successfully created.
  final bool wasConnected;

  /// The connection that was created (null if cancelled).
  final Connection? connection;

  @override
  String toString() =>
      'ConnectionDragEnded(wasConnected: $wasConnected${connection != null ? ', ${connection!.id}' : ''})';
}

// ─────────────────────────────────────────────────────────────────────────────
// Drag Events - Resize Dragging
// ─────────────────────────────────────────────────────────────────────────────

/// Emitted when a resize operation starts.
class ResizeStarted extends GraphEvent {
  const ResizeStarted(this.nodeId, this.initialSize);

  /// The ID of the node being resized.
  final String nodeId;

  /// The size when resize started.
  final Size initialSize;

  @override
  String toString() => 'ResizeStarted($nodeId, $initialSize)';
}

/// Emitted when a resize operation ends.
class ResizeEnded extends GraphEvent {
  const ResizeEnded(this.nodeId, this.initialSize, this.finalSize);

  /// The ID of the node that was resized.
  final String nodeId;

  /// The size when resize started.
  final Size initialSize;

  /// The size when resize ended.
  final Size finalSize;

  @override
  String toString() => 'ResizeEnded($nodeId, $initialSize -> $finalSize)';
}
