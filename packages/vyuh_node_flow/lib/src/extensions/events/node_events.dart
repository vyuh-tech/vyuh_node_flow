part of 'graph_event.dart';

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

/// Emitted when a node's lock state changes.
class NodeLockChanged<T> extends GraphEvent {
  const NodeLockChanged(this.node, this.wasLocked);

  /// The node whose lock state changed.
  final Node<T> node;

  /// Whether the node was locked before the change.
  final bool wasLocked;

  @override
  String toString() =>
      'NodeLockChanged(${node.id}, wasLocked: $wasLocked, isLocked: ${node.locked})';
}

/// Emitted when a node's group membership changes.
class NodeGroupChanged<T> extends GraphEvent {
  const NodeGroupChanged(this.node, this.previousGroupId, this.currentGroupId);

  /// The node whose group membership changed.
  final Node<T> node;

  /// The group ID before the change (null if not in a group).
  final String? previousGroupId;

  /// The group ID after the change (null if not in a group).
  final String? currentGroupId;

  @override
  String toString() =>
      'NodeGroupChanged(${node.id}, $previousGroupId -> $currentGroupId)';
}
