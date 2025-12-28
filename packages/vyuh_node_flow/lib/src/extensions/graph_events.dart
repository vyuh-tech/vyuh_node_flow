import 'dart:ui';

import '../connections/connection.dart';
import '../graph/viewport.dart';
import '../nodes/node.dart';

/// Base class for all graph events emitted by [NodeFlowController].
///
/// Using a sealed class hierarchy enables exhaustive pattern matching:
/// ```dart
/// void onEvent(GraphEvent event) {
///   switch (event) {
///     case NodeAdded(:final node):
///       print('Node added: ${node.id}');
///     case NodeRemoved(:final node):
///       print('Node removed: ${node.id}');
///     // ... handle all cases
///   }
/// }
/// ```
sealed class GraphEvent {
  const GraphEvent();
}

// ─────────────────────────────────────────────────────────────────────────────
// Node Events
// ─────────────────────────────────────────────────────────────────────────────

/// Emitted when a node is added to the graph.
class NodeAdded<T> extends GraphEvent {
  const NodeAdded(this.node);

  /// The node that was added.
  final Node<T> node;

  @override
  String toString() => 'NodeAdded(${node.id})';
}

/// Emitted when a node is removed from the graph.
class NodeRemoved<T> extends GraphEvent {
  const NodeRemoved(this.node);

  /// The node that was removed.
  /// Contains full state for undo capability.
  final Node<T> node;

  @override
  String toString() => 'NodeRemoved(${node.id})';
}

/// Emitted when a node's position changes.
class NodeMoved<T> extends GraphEvent {
  const NodeMoved(this.node, this.previousPosition);

  /// The node that was moved.
  final Node<T> node;

  /// The position before the move (for undo capability).
  final Offset previousPosition;

  @override
  String toString() =>
      'NodeMoved(${node.id}, $previousPosition -> ${node.position.value})';
}

/// Emitted when a node's size changes.
class NodeResized<T> extends GraphEvent {
  const NodeResized(this.node, this.previousSize);

  /// The node that was resized.
  final Node<T> node;

  /// The size before the resize (for undo capability).
  final Size previousSize;

  @override
  String toString() =>
      'NodeResized(${node.id}, $previousSize -> ${node.size.value})';
}

/// Emitted when a node's data changes.
class NodeDataChanged<T> extends GraphEvent {
  const NodeDataChanged(this.node, this.previousData);

  /// The node whose data changed.
  final Node<T> node;

  /// The data before the change (for undo capability).
  final T previousData;

  @override
  String toString() => 'NodeDataChanged(${node.id})';
}

/// Emitted when a node's visibility changes.
class NodeVisibilityChanged<T> extends GraphEvent {
  const NodeVisibilityChanged(this.node, this.wasVisible);

  /// The node whose visibility changed.
  final Node<T> node;

  /// Whether the node was visible before the change.
  final bool wasVisible;

  @override
  String toString() =>
      'NodeVisibilityChanged(${node.id}, wasVisible: $wasVisible)';
}

/// Emitted when a node's z-index changes.
class NodeZIndexChanged<T> extends GraphEvent {
  const NodeZIndexChanged(this.node, this.previousZIndex);

  /// The node whose z-index changed.
  final Node<T> node;

  /// The z-index before the change.
  final int previousZIndex;

  @override
  String toString() =>
      'NodeZIndexChanged(${node.id}, $previousZIndex -> ${node.zIndex.value})';
}

// ─────────────────────────────────────────────────────────────────────────────
// Connection Events
// ─────────────────────────────────────────────────────────────────────────────

/// Emitted when a connection is added to the graph.
class ConnectionAdded extends GraphEvent {
  const ConnectionAdded(this.connection);

  /// The connection that was added.
  final Connection connection;

  @override
  String toString() => 'ConnectionAdded(${connection.id})';
}

/// Emitted when a connection is removed from the graph.
class ConnectionRemoved extends GraphEvent {
  const ConnectionRemoved(this.connection);

  /// The connection that was removed.
  /// Contains full state for undo capability.
  final Connection connection;

  @override
  String toString() => 'ConnectionRemoved(${connection.id})';
}

// ─────────────────────────────────────────────────────────────────────────────
// Selection Events
// ─────────────────────────────────────────────────────────────────────────────

/// Emitted when the selection changes.
class SelectionChanged extends GraphEvent {
  const SelectionChanged({
    required this.selectedNodeIds,
    required this.selectedConnectionIds,
    required this.previousNodeIds,
    required this.previousConnectionIds,
  });

  /// Currently selected node IDs.
  final Set<String> selectedNodeIds;

  /// Currently selected connection IDs.
  final Set<String> selectedConnectionIds;

  /// Previously selected node IDs (for undo capability).
  final Set<String> previousNodeIds;

  /// Previously selected connection IDs (for undo capability).
  final Set<String> previousConnectionIds;

  @override
  String toString() =>
      'SelectionChanged(nodes: ${selectedNodeIds.length}, connections: ${selectedConnectionIds.length})';
}

// ─────────────────────────────────────────────────────────────────────────────
// Viewport Events
// ─────────────────────────────────────────────────────────────────────────────

/// Emitted when the viewport changes (pan or zoom).
class ViewportChanged extends GraphEvent {
  const ViewportChanged(this.viewport, this.previousViewport);

  /// The current viewport state.
  final GraphViewport viewport;

  /// The previous viewport state (for undo capability).
  final GraphViewport previousViewport;

  @override
  String toString() => 'ViewportChanged(zoom: ${viewport.zoom})';
}

// ─────────────────────────────────────────────────────────────────────────────
// Batch Events
// ─────────────────────────────────────────────────────────────────────────────

/// Marks the start of a batch operation.
///
/// Extensions should accumulate events until [BatchEnded] is received,
/// then treat them as a single undoable operation.
///
/// Example batch reasons:
/// - "multi-node-move" - dragging multiple selected nodes
/// - "paste" - pasting multiple nodes/connections
/// - "delete-selection" - deleting multiple items
class BatchStarted extends GraphEvent {
  const BatchStarted(this.reason);

  /// A descriptive name for this batch operation.
  final String reason;

  @override
  String toString() => 'BatchStarted($reason)';
}

/// Marks the end of a batch operation.
///
/// Extensions should finalize the batch started by [BatchStarted].
class BatchEnded extends GraphEvent {
  const BatchEnded();

  @override
  String toString() => 'BatchEnded()';
}
