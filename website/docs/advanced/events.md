---
title: Event System
description: Handle user interactions with nodes, connections, and the canvas
---

# Event System

::: details 🖼️ Event System Overview
Diagram showing event flow architecture: NodeFlowEvents container with four event groups (NodeEvents, PortEvents, ConnectionEvents, ViewportEvents) plus top-level callbacks (onSelectionChange, onInit, onError). Arrows showing event propagation from user interactions.
:::

The event system provides comprehensive callbacks for all user interactions. Events are organized into logical groups for nodes (including GroupNode and CommentNode), ports, connections, and viewport.

## Event Structure

Events are passed via the `events` parameter on `NodeFlowEditor`:

```dart
NodeFlowEditor<MyData, dynamic>(
  controller: controller,
  events: NodeFlowEvents(
    node: NodeEvents(...),      // Includes GroupNode & CommentNode
    port: PortEvents(...),
    connection: ConnectionEvents(...),
    viewport: ViewportEvents(...),
    onSelectionChange: (state) => ...,
    onInit: () => ...,
    onError: (error) => ...,
  ),
)
```

## Node Events

React to node lifecycle and interaction events.

::: details 🖼️ Node Events Demo
Animated demonstration of node events: clicking (onTap), double-clicking (onDoubleTap), dragging (onDragStart/onDrag/onDragStop), hovering (onMouseEnter/onMouseLeave), and right-clicking (onContextMenu). Shows visual feedback for each event.
:::

```dart
NodeEvents<MyData>(
  // Lifecycle
  onCreated: (node) => print('Created: ${node.id}'),
  onBeforeDelete: (node) async {
    // Return true to allow deletion, false to prevent it
    return await showConfirmationDialog(context, node);
  },
  onDeleted: (node) => print('Deleted: ${node.id}'),
  onSelected: (node) => print('Selected: ${node?.id}'),

  // Interactions
  onTap: (node) => _showDetails(node),
  onDoubleTap: (node) => _editNode(node),
  onContextMenu: (node, screenPosition) => _showMenu(node, screenPosition),

  // Drag operations
  onDragStart: (node) => _startDrag(node),
  onDrag: (node) => _updatePosition(node),
  onDragStop: (node) => _savePosition(node),
  onDragCancel: (node) => _restorePosition(node),
  onResizeCancel: (node) => _restoreSize(node),

  // Hover
  onMouseEnter: (node) => _highlightNode(node),
  onMouseLeave: (node) => _unhighlightNode(node),
)
```

| Event | Trigger | Signature |
|-------|---------|-----------|
| `onCreated` | Node added to graph | `ValueChanged<Node<T>>` |
| `onBeforeDelete` | Before node deletion | `Future<bool> Function(Node<T>)` |
| `onDeleted` | Node removed from graph | `ValueChanged<Node<T>>` |
| `onSelected` | Selection state changes | `ValueChanged<Node<T>?>` |
| `onTap` | Single tap on node | `ValueChanged<Node<T>>` |
| `onDoubleTap` | Double tap on node | `ValueChanged<Node<T>>` |
| `onDragStart` | Drag begins | `ValueChanged<Node<T>>` |
| `onDrag` | During drag | `ValueChanged<Node<T>>` |
| `onDragStop` | Drag ends successfully | `ValueChanged<Node<T>>` |
| `onDragCancel` | Drag cancelled (reverted) | `ValueChanged<Node<T>>` |
| `onResizeCancel` | Resize cancelled (reverted) | `ValueChanged<Node<T>>` |
| `onMouseEnter` | Mouse enters node | `ValueChanged<Node<T>>` |
| `onMouseLeave` | Mouse leaves node | `ValueChanged<Node<T>>` |
| `onContextMenu` | Right-click / long-press | `(Node<T>, ScreenPosition)` |

## Port Events

Handle interactions with connection ports.

```dart
PortEvents<MyData>(
  onTap: (node, port) {
    print('Tapped ${port.isOutput ? 'output' : 'input'} port: ${port.id}');
  },
  onDoubleTap: (node, port) => _configurePort(port),
  onMouseEnter: (node, port) => _showPortTooltip(port),
  onMouseLeave: (node, port) => _hideTooltip(),
  onContextMenu: (node, port, screenPosition) {
    _showPortMenu(node, port, screenPosition);
  },
)
```

::: info
Port events include the parent `node` for context, since ports are always attached to nodes. Use `port.isOutput` or `port.isInput` to determine the port direction.

:::

## Connection Events

Handle connection lifecycle and interactions, including validation.

::: details 🖼️ Connection Events Demo
Animated demonstration of connection creation with validation: drag from port (onConnectStart), hover over valid/invalid targets showing validation feedback, complete connection (onConnectEnd with success), and connection rejection showing error reason.
:::

```dart
ConnectionEvents<MyData, dynamic>(
  // Lifecycle
  onCreated: (conn) => print('Connected: ${conn.id}'),
  onBeforeDelete: (conn) async {
    // Return true to allow deletion, false to prevent it
    return await showConfirmationDialog(context, conn);
  },
  onDeleted: (conn) => print('Disconnected: ${conn.id}'),
  onSelected: (conn) => _highlightConnection(conn),

  // Interactions
  onTap: (conn) => _selectConnection(conn),
  onDoubleTap: (conn) => _editConnection(conn),
  onMouseEnter: (conn) => _highlightConnection(conn),
  onMouseLeave: (conn) => _unhighlightConnection(conn),
  onContextMenu: (conn, screenPosition) => _showConnectionMenu(conn, screenPosition),

  // Connection creation process
  onConnectStart: (sourceNode, sourcePort) {
    print('Starting connection from ${sourceNode.id}:${sourcePort.id}');
  },
  onConnectEnd: (targetNode, targetPort, position) {
    if (targetNode != null && targetPort != null) {
      print('Connected to ${targetNode.id}:${targetPort.id}');
    } else {
      print('Connection cancelled at $position');
    }
  },

  // Validation hooks
  onBeforeStart: (context) => _validateStart(context),
  onBeforeComplete: (context) => _validateComplete(context),
)
```

### Connection Validation

Use validation callbacks to control which connections are allowed:

  ### Start Validation

Prevent connection creation from certain ports:

```dart
ConnectionEvents<MyData, dynamic>(
  onBeforeStart: (context) {
    final node = context.sourceNode;
    final port = context.sourcePort;

    // Prevent connections from disabled nodes
    if (node.data.isDisabled) {
      return ConnectionValidationResult.deny(
        reason: 'Cannot connect from disabled node',
        showMessage: true,
      );
    }

    // Check existing connections from this port
    if (!port.allowMultiple && context.existingConnections.isNotEmpty) {
      return ConnectionValidationResult.deny(
        reason: 'Port already has a connection',
        showMessage: true,
      );
    }

    return ConnectionValidationResult.allow();
  },
)
```

  ### Complete Validation

Validate before completing a connection:

```dart
ConnectionEvents<MyData, dynamic>(
  onBeforeComplete: (context) {
    // Prevent self-connections (convenience getter available)
    if (context.isSelfConnection) {
      return ConnectionValidationResult.deny(
        reason: 'Cannot connect to same node',
        showMessage: true,
      );
    }

    // Ensure output-to-input direction (convenience getter available)
    if (!context.isOutputToInput) {
      return ConnectionValidationResult.deny(
        reason: 'Must connect output to input',
        showMessage: true,
      );
    }

    // Type checking using node data
    final source = context.sourceNode;
    final target = context.targetNode;
    if (source.data.outputType != target.data.inputType) {
      return ConnectionValidationResult.deny(
        reason: 'Incompatible types',
        showMessage: true,
      );
    }

    return ConnectionValidationResult.allow();
  },
)
```

### Validation Context Objects

```dart
// Available in onBeforeStart
class ConnectionStartContext<T> {
  final Node<T> sourceNode;
  final Port sourcePort;
  final List<String> existingConnections; // IDs of existing connections from this port

  // Convenience getters
  bool get isOutputPort;
  bool get isInputPort;
}

// Available in onBeforeComplete
class ConnectionCompleteContext<T> {
  final Node<T> sourceNode;
  final Port sourcePort;
  final Node<T> targetNode;
  final Port targetPort;
  final List<String> existingSourceConnections; // IDs of existing connections from source port
  final List<String> existingTargetConnections; // IDs of existing connections to target port

  // Convenience getters
  bool get isOutputToInput;
  bool get isInputToOutput;
  bool get isSelfConnection;
  bool get isSamePort;
}
```

## Viewport Events

React to canvas pan, zoom, and background interactions.

```dart
ViewportEvents(
  // Pan/zoom tracking
  onMoveStart: (viewport) => _saveInitialState(viewport),
  onMove: (viewport) => _updateMinimap(viewport),
  onMoveEnd: (viewport) => _saveViewportState(viewport),

  // Canvas interactions (positions are GraphPosition, in graph coordinates)
  onCanvasTap: (graphPosition) => _addNodeAt(graphPosition),
  onCanvasDoubleTap: (graphPosition) => _openQuickMenu(graphPosition),
  onCanvasContextMenu: (graphPosition) => _showCanvasMenu(graphPosition),
)
```

| Event | Trigger | Signature |
|-------|---------|-----------|
| `onMoveStart` | Pan/zoom begins | `ValueChanged<GraphViewport>` |
| `onMove` | During pan/zoom | `ValueChanged<GraphViewport>` |
| `onMoveEnd` | Pan/zoom ends | `ValueChanged<GraphViewport>` |
| `onCanvasTap` | Tap on empty canvas | `ValueChanged<GraphPosition>` |
| `onCanvasDoubleTap` | Double-tap on canvas | `ValueChanged<GraphPosition>` |
| `onCanvasContextMenu` | Right-click on canvas | `ValueChanged<GraphPosition>` |

::: tip
Canvas positions are `GraphPosition` type, representing **graph coordinates** (not screen coordinates). They account for pan and zoom automatically.

:::

## Selection State

Track the complete selection state across all element types:

```dart
NodeFlowEvents<MyData, dynamic>(
  onSelectionChange: (state) {
    print('Selected nodes: ${state.nodes.length}');
    print('Selected connections: ${state.connections.length}');

    // Update toolbar based on selection
    if (state.hasSelection) {
      _showSelectionToolbar(state);
    } else {
      _hideSelectionToolbar();
    }
  },
)
```

The `SelectionState` object provides:

```dart
class SelectionState<T> {
  /// Currently selected nodes (includes GroupNode and CommentNode)
  final List<Node<T>> nodes;

  /// Currently selected connections
  final List<Connection> connections;

  /// True if anything is selected
  bool get hasSelection;
}
```

::: info
GroupNode and CommentNode are included in the `nodes` list since they extend Node.
:::

## Top-Level Events

```dart
NodeFlowEvents<MyData, dynamic>(
  // Called when editor is ready
  onInit: () {
    print('Editor initialized');
    controller.fitToView();
  },

  // Called on errors
  onError: (error) {
    print('Error: ${error.message}');
    if (error.stackTrace != null) {
      print(error.stackTrace);
    }
  },
)
```

## Complete Example

Here's a full example with event handling for a workflow editor:

::: details 🎬 Interactive Event Log Demo
Split-screen demo: left side shows NodeFlowEditor with nodes and connections, right side shows real-time event log with timestamps. User interactions (clicks, drags, connections) instantly appear in the log panel.
:::

```dart
class WorkflowEditor extends StatefulWidget {
  @override
  State<WorkflowEditor> createState() => _WorkflowEditorState();
}

class _WorkflowEditorState extends State<WorkflowEditor> {
  late final NodeFlowController<WorkflowData, dynamic> controller;
  SelectionState<WorkflowData>? _selection;
  final List<String> _eventLog = [];

  @override
  void initState() {
    super.initState();
    controller = NodeFlowController<WorkflowData, dynamic>();
  }

  void _log(String message) {
    setState(() {
      _eventLog.insert(0, '${DateTime.now().toIso8601String()}: $message');
      if (_eventLog.length > 50) _eventLog.removeLast();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // Editor
        Expanded(
          child: NodeFlowEditor<WorkflowData, dynamic>(
            controller: controller,
            theme: NodeFlowTheme.light,
            nodeBuilder: (context, node) => WorkflowNodeWidget(node: node),
            events: NodeFlowEvents(
              node: NodeEvents(
                onTap: (node) => _log('Tapped: ${node.data.name}'),
                onDoubleTap: (node) => _editNode(node),
                onDragStop: (node) => _log('Moved: ${node.data.name}'),
                onContextMenu: (node, pos) => _showNodeMenu(node, pos),
              ),
              connection: ConnectionEvents(
                onCreated: (conn) => _log('Connected: ${conn.id}'),
                onDeleted: (conn) => _log('Disconnected: ${conn.id}'),
                onBeforeComplete: (context) => _validateConnection(context),
              ),
              viewport: ViewportEvents(
                onCanvasTap: (pos) => _clearSelection(),
                onCanvasContextMenu: (pos) => _showAddNodeMenu(pos),
              ),
              onSelectionChange: (state) {
                setState(() => _selection = state);
              },
              onInit: () => _log('Editor ready'),
              onError: (error) => _log('Error: ${error.message}'),
            ),
          ),
        ),
        // Event log sidebar
        SizedBox(
          width: 300,
          child: ListView.builder(
            itemCount: _eventLog.length,
            itemBuilder: (context, index) => Text(
              _eventLog[index],
              style: const TextStyle(fontSize: 12),
            ),
          ),
        ),
      ],
    );
  }

  ConnectionValidationResult _validateConnection(
    ConnectionCompleteContext<WorkflowData> context,
  ) {
    // Implement your validation logic
    return ConnectionValidationResult.allow();
  }

  void _editNode(Node<WorkflowData> node) {
    // Show edit dialog
  }

  void _showNodeMenu(Node<WorkflowData> node, ScreenPosition position) {
    // Show context menu using position.offset for showMenu()
  }

  void _showAddNodeMenu(GraphPosition position) {
    // Show menu to add new node at graph position
  }

  void _clearSelection() {
    controller.clearSelection();
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }
}
```

## Best Practices

1. **Keep handlers lightweight** - Heavy operations should be async or debounced
2. **Use `onBeforeComplete` for validation** - Prevent invalid connections before they're created
3. **Track selection state** - Use `onSelectionChange` for toolbar/panel updates
4. **Handle errors** - Use `onError` for logging and user notifications
5. **Context menus need position** - Node/port/connection `onContextMenu` callbacks receive `ScreenPosition` for menu placement; canvas context menu receives `GraphPosition`

## See Also

- [Controller](/docs/core-concepts/controller) - Programmatic graph manipulation
- [Connection Validation](/docs/advanced/validation) - Advanced validation patterns
- [Keyboard Shortcuts](/docs/advanced/keyboard-shortcuts) - Keyboard event handling
