import 'package:flutter/material.dart';

import '../connections/connection.dart';
import '../nodes/node.dart';

/// Callback functions that the NodeFlowController can invoke for lifecycle events.
///
/// Note: GroupNode and CommentNode lifecycle events are handled through the
/// node callbacks since they are now regular nodes. Use type checks like
/// `node is GroupNode` or `node is CommentNode` to filter by node type.
class NodeFlowCallbacks<T> {
  const NodeFlowCallbacks({
    this.onNodeCreated,
    this.onNodeDeleted,
    this.onNodeSelected,
    this.onConnectionCreated,
    this.onConnectionDeleted,
    this.onConnectionSelected,
  });

  /// Called when a node is created (includes GroupNode and CommentNode)
  final ValueChanged<Node<T>>? onNodeCreated;

  /// Called when a node is deleted (includes GroupNode and CommentNode)
  final ValueChanged<Node<T>>? onNodeDeleted;

  /// Called when node selection changes (includes GroupNode and CommentNode)
  final ValueChanged<Node<T>?>? onNodeSelected;

  // Connection lifecycle callbacks
  final ValueChanged<Connection>? onConnectionCreated;
  final ValueChanged<Connection>? onConnectionDeleted;
  final ValueChanged<Connection?>? onConnectionSelected;

  /// Create a new callbacks object with updated values
  NodeFlowCallbacks<T> copyWith({
    ValueChanged<Node<T>>? onNodeCreated,
    ValueChanged<Node<T>>? onNodeDeleted,
    ValueChanged<Node<T>?>? onNodeSelected,
    ValueChanged<Connection>? onConnectionCreated,
    ValueChanged<Connection>? onConnectionDeleted,
    ValueChanged<Connection?>? onConnectionSelected,
  }) {
    return NodeFlowCallbacks<T>(
      onNodeCreated: onNodeCreated ?? this.onNodeCreated,
      onNodeDeleted: onNodeDeleted ?? this.onNodeDeleted,
      onNodeSelected: onNodeSelected ?? this.onNodeSelected,
      onConnectionCreated: onConnectionCreated ?? this.onConnectionCreated,
      onConnectionDeleted: onConnectionDeleted ?? this.onConnectionDeleted,
      onConnectionSelected: onConnectionSelected ?? this.onConnectionSelected,
    );
  }
}
