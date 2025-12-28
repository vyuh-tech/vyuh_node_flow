import 'package:flutter/material.dart';

import '../connections/connection.dart';
import '../connections/connection_validation.dart';
import '../nodes/node.dart';
import '../ports/port.dart';
import '../graph/coordinates.dart';
import '../graph/viewport.dart';

/// Comprehensive event system for the NodeFlowEditor
///
/// Organizes all callbacks into logical groups for better discoverability and maintainability.
///
/// Note: GroupNode and CommentNode events are handled through [NodeEvents] since
/// they are now regular nodes. Use `node is GroupNode` or `node is CommentNode`
/// in callbacks to handle these specifically.
class NodeFlowEvents<T> {
  const NodeFlowEvents({
    this.node,
    this.port,
    this.connection,
    this.viewport,
    this.onSelectionChange,
    this.onInit,
    this.onError,
  });

  /// Node-related events (includes GroupNode and CommentNode)
  final NodeEvents<T>? node;

  /// Port-related events
  final PortEvents<T>? port;

  /// Connection-related events
  final ConnectionEvents<T>? connection;

  /// Viewport/canvas events (pan, zoom, taps on empty canvas)
  final ViewportEvents? viewport;

  /// Called when the selection changes (nodes or connections)
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
    PortEvents<T>? port,
    ConnectionEvents<T>? connection,
    ViewportEvents? viewport,
    ValueChanged<SelectionState<T>>? onSelectionChange,
    VoidCallback? onInit,
    ValueChanged<FlowError>? onError,
  }) {
    return NodeFlowEvents<T>(
      node: node ?? this.node,
      port: port ?? this.port,
      connection: connection ?? this.connection,
      viewport: viewport ?? this.viewport,
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
    this.onDragCancel,
    this.onResizeCancel,
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

  /// Called when node dragging ends successfully
  final ValueChanged<Node<T>>? onDragStop;

  /// Called when node dragging is cancelled (reverted to original position)
  final ValueChanged<Node<T>>? onDragCancel;

  /// Called when node resizing is cancelled (reverted to original size)
  final ValueChanged<Node<T>>? onResizeCancel;

  /// Called when mouse enters a node's bounds
  final ValueChanged<Node<T>>? onMouseEnter;

  /// Called when mouse leaves a node's bounds
  final ValueChanged<Node<T>>? onMouseLeave;

  /// Called on secondary tap on a node (right-click/long-press for context menu).
  ///
  /// The [screenPosition] is in screen/global coordinates, suitable for
  /// positioning popup menus via [showMenu] or similar APIs.
  final void Function(Node<T> node, ScreenPosition screenPosition)?
  onContextMenu;

  NodeEvents<T> copyWith({
    ValueChanged<Node<T>>? onCreated,
    ValueChanged<Node<T>>? onDeleted,
    ValueChanged<Node<T>?>? onSelected,
    ValueChanged<Node<T>>? onTap,
    ValueChanged<Node<T>>? onDoubleTap,
    ValueChanged<Node<T>>? onDragStart,
    ValueChanged<Node<T>>? onDrag,
    ValueChanged<Node<T>>? onDragStop,
    ValueChanged<Node<T>>? onDragCancel,
    ValueChanged<Node<T>>? onResizeCancel,
    ValueChanged<Node<T>>? onMouseEnter,
    ValueChanged<Node<T>>? onMouseLeave,
    void Function(Node<T> node, ScreenPosition screenPosition)? onContextMenu,
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
      onDragCancel: onDragCancel ?? this.onDragCancel,
      onResizeCancel: onResizeCancel ?? this.onResizeCancel,
      onMouseEnter: onMouseEnter ?? this.onMouseEnter,
      onMouseLeave: onMouseLeave ?? this.onMouseLeave,
      onContextMenu: onContextMenu ?? this.onContextMenu,
    );
  }
}

/// Events related to port interactions.
///
/// Port events include the parent node for context, since ports are always
/// associated with a node. The port's direction (input/output) can be
/// determined via [Port.isOutput] or [Port.isInput].
class PortEvents<T> {
  const PortEvents({
    this.onTap,
    this.onDoubleTap,
    this.onMouseEnter,
    this.onMouseLeave,
    this.onContextMenu,
  });

  /// Called when a port is tapped.
  ///
  /// Check [Port.isOutput] or [Port.isInput] to determine the port direction.
  final void Function(Node<T> node, Port port)? onTap;

  /// Called when a port is double-tapped.
  ///
  /// Check [Port.isOutput] or [Port.isInput] to determine the port direction.
  final void Function(Node<T> node, Port port)? onDoubleTap;

  /// Called when mouse enters a port's bounds.
  ///
  /// Check [Port.isOutput] or [Port.isInput] to determine the port direction.
  final void Function(Node<T> node, Port port)? onMouseEnter;

  /// Called when mouse leaves a port's bounds.
  ///
  /// Check [Port.isOutput] or [Port.isInput] to determine the port direction.
  final void Function(Node<T> node, Port port)? onMouseLeave;

  /// Called on secondary tap on a port (right-click/long-press for context menu).
  ///
  /// The [screenPosition] is in screen/global coordinates, suitable for
  /// positioning popup menus via [showMenu] or similar APIs.
  /// Check [Port.isOutput] or [Port.isInput] to determine the port direction.
  final void Function(Node<T> node, Port port, ScreenPosition screenPosition)?
  onContextMenu;

  PortEvents<T> copyWith({
    void Function(Node<T> node, Port port)? onTap,
    void Function(Node<T> node, Port port)? onDoubleTap,
    void Function(Node<T> node, Port port)? onMouseEnter,
    void Function(Node<T> node, Port port)? onMouseLeave,
    void Function(Node<T> node, Port port, ScreenPosition screenPosition)?
    onContextMenu,
  }) {
    return PortEvents<T>(
      onTap: onTap ?? this.onTap,
      onDoubleTap: onDoubleTap ?? this.onDoubleTap,
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

  /// Called on secondary tap on a connection (right-click/long-press for context menu).
  ///
  /// The [screenPosition] is in screen/global coordinates, suitable for
  /// positioning popup menus via [showMenu] or similar APIs.
  final void Function(Connection connection, ScreenPosition screenPosition)?
  onContextMenu;

  /// Called when starting to create a connection from a port.
  ///
  /// Provides the source node and port. Check [Port.isOutput] or [Port.isInput]
  /// to determine the port direction. Useful for showing UI hints or validation messages.
  final void Function(Node<T> sourceNode, Port sourcePort)? onConnectStart;

  /// Called when connection creation ends.
  ///
  /// If [targetNode] and [targetPort] are non-null, a connection was successfully
  /// created to that target. If both are null, the connection was cancelled.
  /// [position] provides the graph coordinates where the event occurred.
  final void Function(
    Node<T>? targetNode,
    Port? targetPort,
    GraphPosition position,
  )?
  onConnectEnd;

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
    void Function(Connection connection, ScreenPosition screenPosition)?
    onContextMenu,
    void Function(Node<T> sourceNode, Port sourcePort)? onConnectStart,
    void Function(
      Node<T>? targetNode,
      Port? targetPort,
      GraphPosition position,
    )?
    onConnectEnd,
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
    this.onCanvasDoubleTap,
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
  final ValueChanged<GraphPosition>? onCanvasTap;

  /// Called when double-tapping on empty canvas area (not on nodes/connections)
  /// Receives the tap position in graph coordinates
  final ValueChanged<GraphPosition>? onCanvasDoubleTap;

  /// Called on secondary tap on empty canvas (right-click/long-press for context menu)
  /// Receives the tap position in graph coordinates
  final ValueChanged<GraphPosition>? onCanvasContextMenu;

  ViewportEvents copyWith({
    ValueChanged<GraphViewport>? onMove,
    ValueChanged<GraphViewport>? onMoveStart,
    ValueChanged<GraphViewport>? onMoveEnd,
    ValueChanged<GraphPosition>? onCanvasTap,
    ValueChanged<GraphPosition>? onCanvasDoubleTap,
    ValueChanged<GraphPosition>? onCanvasContextMenu,
  }) {
    return ViewportEvents(
      onMove: onMove ?? this.onMove,
      onMoveStart: onMoveStart ?? this.onMoveStart,
      onMoveEnd: onMoveEnd ?? this.onMoveEnd,
      onCanvasTap: onCanvasTap ?? this.onCanvasTap,
      onCanvasDoubleTap: onCanvasDoubleTap ?? this.onCanvasDoubleTap,
      onCanvasContextMenu: onCanvasContextMenu ?? this.onCanvasContextMenu,
    );
  }
}

/// Represents the current selection state
///
/// This includes both regular nodes and special node types (GroupNode, CommentNode).
/// Use type checks like `node is GroupNode` to filter by node type.
class SelectionState<T> {
  const SelectionState({required this.nodes, required this.connections});

  /// Currently selected nodes (includes GroupNode and CommentNode)
  final List<Node<T>> nodes;

  /// Currently selected connections
  final List<Connection> connections;

  /// Whether anything is selected
  bool get hasSelection => nodes.isNotEmpty || connections.isNotEmpty;
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
