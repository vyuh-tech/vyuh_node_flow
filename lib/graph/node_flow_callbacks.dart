import 'package:flutter/material.dart';

import '../annotations/annotation.dart';
import '../connections/connection.dart';
import '../nodes/node.dart';

/// Callback functions that the NodeFlowController can invoke for lifecycle events
class NodeFlowCallbacks<T> {
  const NodeFlowCallbacks({
    this.onNodeCreated,
    this.onNodeDeleted,
    this.onNodeSelected,
    this.onConnectionCreated,
    this.onConnectionDeleted,
    this.onConnectionSelected,
    this.onAnnotationCreated,
    this.onAnnotationDeleted,
    this.onAnnotationSelected,
  });

  // Node lifecycle callbacks
  final ValueChanged<Node<T>>? onNodeCreated;
  final ValueChanged<Node<T>>? onNodeDeleted;
  final ValueChanged<Node<T>?>? onNodeSelected;

  // Connection lifecycle callbacks
  final ValueChanged<Connection>? onConnectionCreated;
  final ValueChanged<Connection>? onConnectionDeleted;
  final ValueChanged<Connection?>? onConnectionSelected;

  // Annotation lifecycle callbacks
  final ValueChanged<Annotation>? onAnnotationCreated;
  final ValueChanged<Annotation>? onAnnotationDeleted;
  final ValueChanged<Annotation?>? onAnnotationSelected;

  /// Create a new callbacks object with updated values
  NodeFlowCallbacks<T> copyWith({
    ValueChanged<Node<T>>? onNodeCreated,
    ValueChanged<Node<T>>? onNodeDeleted,
    ValueChanged<Node<T>?>? onNodeSelected,
    ValueChanged<Connection>? onConnectionCreated,
    ValueChanged<Connection>? onConnectionDeleted,
    ValueChanged<Connection?>? onConnectionSelected,
    ValueChanged<Annotation>? onAnnotationCreated,
    ValueChanged<Annotation>? onAnnotationDeleted,
    ValueChanged<Annotation?>? onAnnotationSelected,
  }) {
    return NodeFlowCallbacks<T>(
      onNodeCreated: onNodeCreated ?? this.onNodeCreated,
      onNodeDeleted: onNodeDeleted ?? this.onNodeDeleted,
      onNodeSelected: onNodeSelected ?? this.onNodeSelected,
      onConnectionCreated: onConnectionCreated ?? this.onConnectionCreated,
      onConnectionDeleted: onConnectionDeleted ?? this.onConnectionDeleted,
      onConnectionSelected: onConnectionSelected ?? this.onConnectionSelected,
      onAnnotationCreated: onAnnotationCreated ?? this.onAnnotationCreated,
      onAnnotationDeleted: onAnnotationDeleted ?? this.onAnnotationDeleted,
      onAnnotationSelected: onAnnotationSelected ?? this.onAnnotationSelected,
    );
  }
}
