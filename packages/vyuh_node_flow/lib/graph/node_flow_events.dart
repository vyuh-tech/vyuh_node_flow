import 'package:flutter/material.dart';

import '../annotations/annotation.dart';
import '../connections/connection.dart';
import '../connections/connection_validation.dart';
import '../nodes/node.dart';
import 'viewport.dart';

/// Comprehensive event system for the NodeFlowEditor
///
/// Organizes all callbacks into logical groups for better discoverability and maintainability.
class NodeFlowEvents<T> {
  const NodeFlowEvents({
    this.node,
    this.connection,
    this.viewport,
    this.annotation,
    this.onSelectionChange,
    this.onInit,
    this.onError,
  });

  /// Node-related events
  final NodeEvents<T>? node;

  /// Connection-related events
  final ConnectionEvents<T>? connection;

  /// Viewport/canvas events (pan, zoom, taps on empty canvas)
  final ViewportEvents? viewport;

  /// Annotation events
  final AnnotationEvents? annotation;

  /// Called when the selection changes (nodes, connections, or annotations)
  /// Provides the complete current selection state
  final ValueChanged<SelectionState<T>>? onSelectionChange;

  /// Called when the editor is initialized and ready
  final VoidCallback? onInit;

  /// Called when an error occurs
  /// Useful for logging or showing error notifications
  final ValueChanged<FlowError>? onError;

  /// Create a new events object with updated values
  NodeFlowEvents<T> copyWith({
    NodeEvents<T>? node,
    ConnectionEvents<T>? connection,
    ViewportEvents? viewport,
    AnnotationEvents? annotation,
    ValueChanged<SelectionState<T>>? onSelectionChange,
    VoidCallback? onInit,
    ValueChanged<FlowError>? onError,
  }) {
    return NodeFlowEvents<T>(
      node: node ?? this.node,
      connection: connection ?? this.connection,
      viewport: viewport ?? this.viewport,
      annotation: annotation ?? this.annotation,
      onSelectionChange: onSelectionChange ?? this.onSelectionChange,
      onInit: onInit ?? this.onInit,
      onError: onError ?? this.onError,
    );
  }
}

/// Events related to node interactions
class NodeEvents<T> {
  const NodeEvents({
    this.onCreated,
    this.onDeleted,
    this.onSelected,
    this.onTap,
    this.onDoubleTap,
    this.onDragStart,
    this.onDrag,
    this.onDragStop,
    this.onMouseEnter,
    this.onMouseLeave,
    this.onContextMenu,
  });

  /// Called when a node is created and added to the graph
  final ValueChanged<Node<T>>? onCreated;

  /// Called when a node is deleted from the graph
  final ValueChanged<Node<T>>? onDeleted;

  /// Called when a node's selection state changes
  /// Receives the selected node, or null if selection was cleared
  final ValueChanged<Node<T>?>? onSelected;

  /// Called when a node is tapped
  final ValueChanged<Node<T>>? onTap;

  /// Called when a node is double-tapped
  final ValueChanged<Node<T>>? onDoubleTap;

  /// Called when node dragging starts
  final ValueChanged<Node<T>>? onDragStart;

  /// Called continuously while a node is being dragged
  /// Useful for real-time updates or validation during drag
  final ValueChanged<Node<T>>? onDrag;

  /// Called when node dragging ends
  final ValueChanged<Node<T>>? onDragStop;

  /// Called when mouse enters a node's bounds
  final ValueChanged<Node<T>>? onMouseEnter;

  /// Called when mouse leaves a node's bounds
  final ValueChanged<Node<T>>? onMouseLeave;

  /// Called on secondary tap on a node (right-click/long-press for context menu)
  /// Receives both the node and the pointer position for menu placement
  final void Function(Node<T> node, Offset position)? onContextMenu;

  NodeEvents<T> copyWith({
    ValueChanged<Node<T>>? onCreated,
    ValueChanged<Node<T>>? onDeleted,
    ValueChanged<Node<T>?>? onSelected,
    ValueChanged<Node<T>>? onTap,
    ValueChanged<Node<T>>? onDoubleTap,
    ValueChanged<Node<T>>? onDragStart,
    ValueChanged<Node<T>>? onDrag,
    ValueChanged<Node<T>>? onDragStop,
    ValueChanged<Node<T>>? onMouseEnter,
    ValueChanged<Node<T>>? onMouseLeave,
    void Function(Node<T> node, Offset position)? onContextMenu,
  }) {
    return NodeEvents<T>(
      onCreated: onCreated ?? this.onCreated,
      onDeleted: onDeleted ?? this.onDeleted,
      onSelected: onSelected ?? this.onSelected,
      onTap: onTap ?? this.onTap,
      onDoubleTap: onDoubleTap ?? this.onDoubleTap,
      onDragStart: onDragStart ?? this.onDragStart,
      onDrag: onDrag ?? this.onDrag,
      onDragStop: onDragStop ?? this.onDragStop,
      onMouseEnter: onMouseEnter ?? this.onMouseEnter,
      onMouseLeave: onMouseLeave ?? this.onMouseLeave,
      onContextMenu: onContextMenu ?? this.onContextMenu,
    );
  }
}

/// Events related to connection interactions
class ConnectionEvents<T> {
  const ConnectionEvents({
    this.onCreated,
    this.onDeleted,
    this.onSelected,
    this.onTap,
    this.onDoubleTap,
    this.onMouseEnter,
    this.onMouseLeave,
    this.onContextMenu,
    this.onConnectStart,
    this.onConnectEnd,
    this.onBeforeStart,
    this.onBeforeComplete,
  });

  /// Called when a connection is created
  final ValueChanged<Connection>? onCreated;

  /// Called when a connection is deleted
  final ValueChanged<Connection>? onDeleted;

  /// Called when a connection's selection state changes
  /// Receives the selected connection, or null if selection was cleared
  final ValueChanged<Connection?>? onSelected;

  /// Called when a connection is tapped
  final ValueChanged<Connection>? onTap;

  /// Called when a connection is double-tapped
  final ValueChanged<Connection>? onDoubleTap;

  /// Called when mouse enters a connection's path
  final ValueChanged<Connection>? onMouseEnter;

  /// Called when mouse leaves a connection's path
  final ValueChanged<Connection>? onMouseLeave;

  /// Called on secondary tap on a connection (right-click/long-press for context menu)
  /// Receives both the connection and the pointer position for menu placement
  final void Function(Connection connection, Offset position)? onContextMenu;

  /// Called when starting to create a connection from a port
  /// Useful for showing UI hints or validation messages
  final void Function(String nodeId, String portId, bool isOutput)?
  onConnectStart;

  /// Called when connection creation ends (whether successful or cancelled)
  /// Parameters indicate if a connection was successfully created
  final void Function(bool success)? onConnectEnd;

  /// Validation callback before starting a connection from a port
  /// Return ConnectionValidationResult with allowed: false to prevent connection start
  final ConnectionValidationResult Function(ConnectionStartContext<T> context)?
  onBeforeStart;

  /// Validation callback before completing a connection to a target port
  /// Return ConnectionValidationResult with allowed: false to prevent connection
  final ConnectionValidationResult Function(
    ConnectionCompleteContext<T> context,
  )?
  onBeforeComplete;

  ConnectionEvents<T> copyWith({
    ValueChanged<Connection>? onCreated,
    ValueChanged<Connection>? onDeleted,
    ValueChanged<Connection?>? onSelected,
    ValueChanged<Connection>? onTap,
    ValueChanged<Connection>? onDoubleTap,
    ValueChanged<Connection>? onMouseEnter,
    ValueChanged<Connection>? onMouseLeave,
    void Function(Connection connection, Offset position)? onContextMenu,
    void Function(String nodeId, String portId, bool isOutput)? onConnectStart,
    void Function(bool success)? onConnectEnd,
    ConnectionValidationResult Function(ConnectionStartContext<T> context)?
    onBeforeStart,
    ConnectionValidationResult Function(ConnectionCompleteContext<T> context)?
    onBeforeComplete,
  }) {
    return ConnectionEvents<T>(
      onCreated: onCreated ?? this.onCreated,
      onDeleted: onDeleted ?? this.onDeleted,
      onSelected: onSelected ?? this.onSelected,
      onTap: onTap ?? this.onTap,
      onDoubleTap: onDoubleTap ?? this.onDoubleTap,
      onMouseEnter: onMouseEnter ?? this.onMouseEnter,
      onMouseLeave: onMouseLeave ?? this.onMouseLeave,
      onContextMenu: onContextMenu ?? this.onContextMenu,
      onConnectStart: onConnectStart ?? this.onConnectStart,
      onConnectEnd: onConnectEnd ?? this.onConnectEnd,
      onBeforeStart: onBeforeStart ?? this.onBeforeStart,
      onBeforeComplete: onBeforeComplete ?? this.onBeforeComplete,
    );
  }
}

/// Events related to viewport/canvas interactions (pan, zoom, canvas taps)
class ViewportEvents {
  const ViewportEvents({
    this.onMove,
    this.onMoveStart,
    this.onMoveEnd,
    this.onCanvasTap,
    this.onCanvasContextMenu,
  });

  /// Called continuously during viewport movement (pan or zoom)
  /// Receives the new viewport state
  final ValueChanged<GraphViewport>? onMove;

  /// Called when viewport movement starts
  /// Receives the initial viewport state
  final ValueChanged<GraphViewport>? onMoveStart;

  /// Called when viewport movement ends
  /// Receives the final viewport state
  final ValueChanged<GraphViewport>? onMoveEnd;

  /// Called when tapping on empty canvas area (not on nodes/connections)
  /// Receives the tap position in graph coordinates
  final ValueChanged<Offset>? onCanvasTap;

  /// Called on secondary tap on empty canvas (right-click/long-press for context menu)
  /// Receives the tap position in graph coordinates
  final ValueChanged<Offset>? onCanvasContextMenu;

  ViewportEvents copyWith({
    ValueChanged<GraphViewport>? onMove,
    ValueChanged<GraphViewport>? onMoveStart,
    ValueChanged<GraphViewport>? onMoveEnd,
    ValueChanged<Offset>? onCanvasTap,
    ValueChanged<Offset>? onCanvasContextMenu,
  }) {
    return ViewportEvents(
      onMove: onMove ?? this.onMove,
      onMoveStart: onMoveStart ?? this.onMoveStart,
      onMoveEnd: onMoveEnd ?? this.onMoveEnd,
      onCanvasTap: onCanvasTap ?? this.onCanvasTap,
      onCanvasContextMenu: onCanvasContextMenu ?? this.onCanvasContextMenu,
    );
  }
}

/// Represents the current selection state
class SelectionState<T> {
  const SelectionState({
    required this.nodes,
    required this.connections,
    required this.annotations,
  });

  /// Currently selected nodes
  final List<Node<T>> nodes;

  /// Currently selected connections
  final List<Connection> connections;

  /// Currently selected annotations
  final List<Annotation> annotations;

  /// Whether anything is selected
  bool get hasSelection =>
      nodes.isNotEmpty || connections.isNotEmpty || annotations.isNotEmpty;
}

/// Events related to annotation interactions
class AnnotationEvents {
  const AnnotationEvents({
    this.onCreated,
    this.onDeleted,
    this.onSelected,
    this.onTap,
  });

  /// Called when an annotation is created
  final ValueChanged<Annotation>? onCreated;

  /// Called when an annotation is deleted
  final ValueChanged<Annotation>? onDeleted;

  /// Called when an annotation's selection state changes
  /// Receives the selected annotation, or null if selection was cleared
  final ValueChanged<Annotation?>? onSelected;

  /// Called when an annotation is tapped
  final ValueChanged<Annotation>? onTap;

  AnnotationEvents copyWith({
    ValueChanged<Annotation>? onCreated,
    ValueChanged<Annotation>? onDeleted,
    ValueChanged<Annotation?>? onSelected,
    ValueChanged<Annotation>? onTap,
  }) {
    return AnnotationEvents(
      onCreated: onCreated ?? this.onCreated,
      onDeleted: onDeleted ?? this.onDeleted,
      onSelected: onSelected ?? this.onSelected,
      onTap: onTap ?? this.onTap,
    );
  }
}

/// Error information
class FlowError {
  const FlowError({required this.message, this.error, this.stackTrace});

  /// Human-readable error message
  final String message;

  /// The error object (if available)
  final Object? error;

  /// Stack trace (if available)
  final StackTrace? stackTrace;
}
