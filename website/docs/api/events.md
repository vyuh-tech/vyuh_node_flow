---
title: Events API
description: API reference for the event system classes
---

# Events API

Complete reference for all event classes in Vyuh Node Flow.

## NodeFlowEvents

The top-level container for all event handlers.

```dart
NodeFlowEvents<T, dynamic>({
  NodeEvents<T>? node,
  PortEvents<T>? port,
  ConnectionEvents<T, dynamic>? connection,
  ViewportEvents? viewport,
  ValueChanged<SelectionState<T>>? onSelectionChange,
  VoidCallback? onInit,
  ValueChanged<FlowError>? onError,
})
```

| Property | Type | Description |
|----------|------|-------------|
| `node` | `NodeEvents<T>?` | Node interaction events (includes GroupNode & CommentNode) |
| `port` | `PortEvents<T>?` | Port interaction events |
| `connection` | `ConnectionEvents<T, dynamic>?` | Connection lifecycle events |
| `viewport` | `ViewportEvents?` | Canvas pan/zoom events |
| `onSelectionChange` | `ValueChanged<SelectionState<T>>?` | Selection state changes |
| `onInit` | `VoidCallback?` | Editor initialization |
| `onError` | `ValueChanged<FlowError>?` | Error handling |

## NodeEvents

Events for node interactions.

```dart
NodeEvents<T>({
  ValueChanged<Node<T>>? onCreated,
  BeforeDeleteCallback<Node<T>>? onBeforeDelete,
  ValueChanged<Node<T>>? onDeleted,
  ValueChanged<Node<T>?>? onSelected,
  ValueChanged<Node<T>>? onTap,
  ValueChanged<Node<T>>? onDoubleTap,
  void Function(Node<T> node, ScreenPosition screenPosition)? onContextMenu,
  ValueChanged<Node<T>>? onDragStart,
  ValueChanged<Node<T>>? onDrag,
  ValueChanged<Node<T>>? onDragStop,
  ValueChanged<Node<T>>? onDragCancel,
  ValueChanged<Node<T>>? onResizeCancel,
  ValueChanged<Node<T>>? onMouseEnter,
  ValueChanged<Node<T>>? onMouseLeave,
})
```

| Event | Trigger | Signature |
|-------|---------|-----------|
| `onCreated` | Node added to graph | `ValueChanged<Node<T>>` |
| `onBeforeDelete` | Before node deleted (async, can cancel) | `Future<bool> Function(Node<T>)` |
| `onDeleted` | Node removed from graph | `ValueChanged<Node<T>>` |
| `onSelected` | Selection changes | `ValueChanged<Node<T>?>` |
| `onTap` | Single tap | `ValueChanged<Node<T>>` |
| `onDoubleTap` | Double tap | `ValueChanged<Node<T>>` |
| `onContextMenu` | Right-click/long-press | `(Node<T>, ScreenPosition)` |
| `onDragStart` | Drag begins | `ValueChanged<Node<T>>` |
| `onDrag` | During drag | `ValueChanged<Node<T>>` |
| `onDragStop` | Drag ends successfully | `ValueChanged<Node<T>>` |
| `onDragCancel` | Drag cancelled (reverted) | `ValueChanged<Node<T>>` |
| `onResizeCancel` | Resize cancelled (reverted) | `ValueChanged<Node<T>>` |
| `onMouseEnter` | Mouse enters node bounds | `ValueChanged<Node<T>>` |
| `onMouseLeave` | Mouse leaves node bounds | `ValueChanged<Node<T>>` |

::: info
The `onBeforeDelete` callback is async and can be used to show confirmation dialogs before deletion. Locked nodes are automatically prevented from deletion without invoking this callback.
:::

**Example:**
```dart
NodeEvents<MyData>(
  onTap: (node) => print('Tapped: ${node.id}'),
  onDoubleTap: (node) => _editNode(node),
  onDragStop: (node) => _savePosition(node),
  onContextMenu: (node, pos) => _showMenu(node, pos),
  onBeforeDelete: (node) async {
    return await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Delete Node?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: Text('Delete')),
        ],
      ),
    ) ?? false;
  },
)
```

## PortEvents

Events for port interactions. All callbacks include the parent node for context.

```dart
PortEvents<T>({
  void Function(Node<T> node, Port port)? onTap,
  void Function(Node<T> node, Port port)? onDoubleTap,
  void Function(Node<T> node, Port port)? onMouseEnter,
  void Function(Node<T> node, Port port)? onMouseLeave,
  void Function(Node<T> node, Port port, ScreenPosition screenPosition)? onContextMenu,
})
```

Use `port.isOutput` or `port.isInput` to determine the port direction.

| Event | Trigger | Signature |
|-------|---------|-----------|
| `onTap` | Port tapped | `(Node<T>, Port)` |
| `onDoubleTap` | Port double-tapped | `(Node<T>, Port)` |
| `onMouseEnter` | Mouse enters port | `(Node<T>, Port)` |
| `onMouseLeave` | Mouse leaves port | `(Node<T>, Port)` |
| `onContextMenu` | Right-click on port | `(Node<T>, Port, ScreenPosition)` |

**Example:**
```dart
PortEvents<MyData>(
  onTap: (node, port) {
    print('Tapped ${port.isOutput ? 'output' : 'input'} port: ${port.id}');
  },
  onMouseEnter: (node, port) => _showTooltip(port),
  onMouseLeave: (node, port) => _hideTooltip(),
)
```

## ConnectionEvents

Events for connection lifecycle and validation.

```dart
ConnectionEvents<T, dynamic>({
  ValueChanged<Connection>? onCreated,
  BeforeDeleteCallback<Connection>? onBeforeDelete,
  ValueChanged<Connection>? onDeleted,
  ValueChanged<Connection?>? onSelected,
  ValueChanged<Connection>? onTap,
  ValueChanged<Connection>? onDoubleTap,
  ValueChanged<Connection>? onMouseEnter,
  ValueChanged<Connection>? onMouseLeave,
  void Function(Connection, ScreenPosition)? onContextMenu,
  void Function(Node<T> sourceNode, Port sourcePort)? onConnectStart,
  void Function(Node<T>? targetNode, Port? targetPort, GraphPosition position)? onConnectEnd,
  ConnectionValidationResult Function(ConnectionStartContext<T>)? onBeforeStart,
  ConnectionValidationResult Function(ConnectionCompleteContext<T>)? onBeforeComplete,
})
```

| Event | Trigger | Signature |
|-------|---------|-----------|
| `onCreated` | Connection added | `ValueChanged<Connection>` |
| `onBeforeDelete` | Before connection deleted | `Future<bool> Function(Connection)` |
| `onDeleted` | Connection removed | `ValueChanged<Connection>` |
| `onSelected` | Selection changes | `ValueChanged<Connection?>` |
| `onTap` | Single tap | `ValueChanged<Connection>` |
| `onDoubleTap` | Double tap | `ValueChanged<Connection>` |
| `onMouseEnter` | Mouse enters path | `ValueChanged<Connection>` |
| `onMouseLeave` | Mouse leaves path | `ValueChanged<Connection>` |
| `onContextMenu` | Right-click | `(Connection, ScreenPosition)` |
| `onConnectStart` | Drag begins from port | `(Node<T>, Port)` |
| `onConnectEnd` | Drag ends | `(Node<T>?, Port?, GraphPosition)` |
| `onBeforeStart` | Before connection starts | Returns validation result |
| `onBeforeComplete` | Before connection completes | Returns validation result |

## ConnectionStartContext

Context provided to `onBeforeStart` when starting a connection drag.

```dart
class ConnectionStartContext<T> {
  final Node<T> sourceNode;
  final Port sourcePort;
  final List<String> existingConnections;

  // Computed properties
  bool get isOutputPort;
  bool get isInputPort;
}
```

| Property | Type | Description |
|----------|------|-------------|
| `sourceNode` | `Node<T>` | Node where connection is starting |
| `sourcePort` | `Port` | Port where connection is starting |
| `existingConnections` | `List<String>` | IDs of existing connections from this port |
| `isOutputPort` | `bool` | Whether this is an output port |
| `isInputPort` | `bool` | Whether this is an input port |

## ConnectionCompleteContext

Context provided to `onBeforeComplete` when attempting to complete a connection.

```dart
class ConnectionCompleteContext<T> {
  final Node<T> sourceNode;
  final Port sourcePort;
  final Node<T> targetNode;
  final Port targetPort;
  final List<String> existingSourceConnections;
  final List<String> existingTargetConnections;

  // Computed properties
  bool get isOutputToInput;
  bool get isInputToOutput;
  bool get isSelfConnection;
  bool get isSamePort;
}
```

| Property | Type | Description |
|----------|------|-------------|
| `sourceNode` | `Node<T>` | Source node |
| `sourcePort` | `Port` | Source port |
| `targetNode` | `Node<T>` | Target node |
| `targetPort` | `Port` | Target port |
| `existingSourceConnections` | `List<String>` | Existing connection IDs from source port |
| `existingTargetConnections` | `List<String>` | Existing connection IDs to target port |
| `isOutputToInput` | `bool` | Output-to-input direction (typical) |
| `isInputToOutput` | `bool` | Input-to-output direction (reverse) |
| `isSelfConnection` | `bool` | Connecting a node to itself |
| `isSamePort` | `bool` | Connecting a port to itself |

## ConnectionValidationResult

Return value for validation callbacks.

```dart
class ConnectionValidationResult {
  final bool allowed;
  final String? reason;
  final bool showMessage;

  // Factory constructors
  const ConnectionValidationResult.allow();
  const ConnectionValidationResult.deny({String? reason, bool showMessage = false});
}
```

**Example:**
```dart
ConnectionEvents<MyData, dynamic>(
  onBeforeStart: (context) {
    // Validate port can start connections
    if (!context.sourcePort.isConnectable) {
      return ConnectionValidationResult.deny(
        reason: 'Port is not connectable',
        showMessage: true,
      );
    }
    return ConnectionValidationResult.allow();
  },
  onBeforeComplete: (context) {
    // Prevent self-connections
    if (context.isSelfConnection) {
      return ConnectionValidationResult.deny(
        reason: 'Cannot connect to same node',
        showMessage: true,
      );
    }
    // Only allow output-to-input
    if (!context.isOutputToInput) {
      return ConnectionValidationResult.deny(
        reason: 'Must connect output to input',
      );
    }
    return ConnectionValidationResult.allow();
  },
)
```

## ViewportEvents

Events for canvas interactions.

```dart
ViewportEvents({
  ValueChanged<GraphViewport>? onMove,
  ValueChanged<GraphViewport>? onMoveStart,
  ValueChanged<GraphViewport>? onMoveEnd,
  ValueChanged<GraphPosition>? onCanvasTap,
  ValueChanged<GraphPosition>? onCanvasDoubleTap,
  ValueChanged<GraphPosition>? onCanvasContextMenu,
})
```

| Event | Trigger | Signature |
|-------|---------|-----------|
| `onMove` | During pan/zoom | `ValueChanged<GraphViewport>` |
| `onMoveStart` | Pan/zoom begins | `ValueChanged<GraphViewport>` |
| `onMoveEnd` | Pan/zoom ends | `ValueChanged<GraphViewport>` |
| `onCanvasTap` | Tap on empty canvas | `ValueChanged<GraphPosition>` |
| `onCanvasDoubleTap` | Double-tap on canvas | `ValueChanged<GraphPosition>` |
| `onCanvasContextMenu` | Right-click on canvas | `ValueChanged<GraphPosition>` |

::: info
Canvas positions are in **graph coordinates** (`GraphPosition`), automatically adjusted for pan and zoom.
:::

**Example:**
```dart
ViewportEvents(
  onCanvasTap: (pos) => controller.clearSelection(),
  onCanvasDoubleTap: (pos) => _addNodeAt(pos),
  onCanvasContextMenu: (pos) => _showAddMenu(pos),
  onMove: (viewport) => _updateMinimap(viewport),
)
```

## SelectionState

Provided to `onSelectionChange` when selection changes.

```dart
class SelectionState<T> {
  /// Currently selected nodes (includes GroupNode and CommentNode)
  final List<Node<T>> nodes;

  /// Currently selected connections
  final List<Connection> connections;

  /// Whether anything is selected
  bool get hasSelection;
}
```

::: info
GroupNode and CommentNode are included in the `nodes` list since they extend Node.
:::

**Example:**
```dart
onSelectionChange: (state) {
  if (state.hasSelection) {
    _showSelectionToolbar(state);
    print('Selected ${state.nodes.length} nodes');
  } else {
    _hideSelectionToolbar();
  }
}
```

## FlowError

Error information passed to `onError`.

```dart
class FlowError {
  final String message;
  final Object? error;
  final StackTrace? stackTrace;
}
```

**Example:**
```dart
onError: (error) {
  print('Flow error: ${error.message}');
  if (error.error != null) {
    print('Caused by: ${error.error}');
  }
}
```

## Complete Example

```dart
NodeFlowEditor<WorkflowData, dynamic>(
  controller: controller,
  events: NodeFlowEvents(
    node: NodeEvents(
      onTap: (node) => setState(() => _selected = node),
      onDoubleTap: (node) => _editNode(node),
      onDragStop: (node) => _log('Moved: ${node.id}'),
      onContextMenu: (node, pos) => _showNodeMenu(node, pos),
    ),
    port: PortEvents(
      onMouseEnter: (node, port, _) => _showPortInfo(port),
      onMouseLeave: (_, __, ___) => _hidePortInfo(),
    ),
    connection: ConnectionEvents(
      onCreated: (conn) => _log('Connected: ${conn.id}'),
      onDeleted: (conn) => _log('Disconnected: ${conn.id}'),
      onMouseEnter: (conn) => conn.animated = true,
      onMouseLeave: (conn) => conn.animated = false,
      onBeforeComplete: (ctx) => _validateConnection(ctx),
    ),
    viewport: ViewportEvents(
      onCanvasTap: (_) => controller.clearSelection(),
      onCanvasContextMenu: (pos) => _showAddNodeMenu(pos),
    ),
    onSelectionChange: (state) {
      setState(() => _selectionCount = state.nodes.length);
    },
    onInit: () => _log('Editor ready'),
    onError: (error) => _log('Error: ${error.message}'),
  ),
)
```

## copyWith Methods

All event classes support `copyWith` for creating modified copies:

```dart
final baseEvents = NodeFlowEvents<MyData, dynamic>(
  node: NodeEvents(onTap: (n) => print('tap')),
);

final extendedEvents = baseEvents.copyWith(
  connection: ConnectionEvents(onCreated: (c) => print('created')),
);
```
