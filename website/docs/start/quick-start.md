---
title: Quick Start
description: Build your first node flow editor in 10 minutes
---

# Quick Start

Build a fully functional flow editor with nodes, connections, and interactions.

## What You'll Build

::: details 🎬 Quick Start Result
Simple flow editor showing three connected nodes: Start → Process → End. Each node is a rounded rectangle with ports. Smoothstep connection lines link the nodes. Light theme with dots grid background. Toolbar at top with Add Node and Fit View buttons.
:::

A flow editor with:

- Three connected nodes
- Drag-and-drop node positioning
- Interactive connection creation
- Pan and zoom navigation
- Add new nodes with a button

## The Code

### Create the Controller with Initial Graph

The `NodeFlowController` manages all state - nodes, connections, selection, and viewport.
You can provide initial nodes and connections directly in the constructor.

```dart
late final controller = NodeFlowController<String, dynamic>(
  nodes: [
    Node<String>(
      id: 'start',
      type: 'input',
      position: const Offset(100, 100),
      size: const Size(140, 70),
      data: 'Start',
      outputPorts: const [
        Port(id: 'out', name: 'Out', position: PortPosition.right),
      ],
    ),
    Node<String>(
      id: 'process',
      type: 'default',
      position: const Offset(320, 100),
      size: const Size(140, 70),
      data: 'Process',
      inputPorts: const [
        Port(id: 'in', name: 'In', position: PortPosition.left),
      ],
      outputPorts: const [
        Port(id: 'out', name: 'Out', position: PortPosition.right),
      ],
    ),
    Node<String>(
      id: 'end',
      type: 'output',
      position: const Offset(540, 100),
      size: const Size(140, 70),
      data: 'End',
      inputPorts: const [
        Port(id: 'in', name: 'In', position: PortPosition.left),
      ],
    ),
  ],
  connections: [
    Connection(
      id: 'conn-1',
      sourceNodeId: 'start',
      sourcePortId: 'out',
      targetNodeId: 'process',
      targetPortId: 'in',
    ),
    Connection(
      id: 'conn-2',
      sourceNodeId: 'process',
      sourcePortId: 'out',
      targetNodeId: 'end',
      targetPortId: 'in',
    ),
  ],
);

@override
void dispose() {
  controller.dispose();
  super.dispose();
}
```

::: tip
The generic type `<String>` represents your node data. Use any type - `Map<String, dynamic>`, a custom class, or sealed classes for type-safe nodes.

:::

### Build the Editor

Use `NodeFlowEditor` with a `nodeBuilder` callback.

```dart
@override
Widget build(BuildContext context) {
  return Scaffold(
    appBar: AppBar(
      title: const Text('My Flow Editor'),
      actions: [
        IconButton(
          icon: const Icon(Icons.add),
          onPressed: _addNode,
        ),
      ],
    ),
    body: NodeFlowEditor<String, dynamic>(
      controller: controller,
      theme: NodeFlowTheme.light,
      nodeBuilder: (context, node) => Center(
        child: Text(
          node.data,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
    ),
  );
}
```

## Complete Example

Here's the full working code:

```dart title="my_flow_editor.dart"
import 'package:flutter/material.dart';
import 'package:vyuh_node_flow/vyuh_node_flow.dart';

void main() {
  runApp(const MaterialApp(home: MyFlowEditor()));
}

class MyFlowEditor extends StatefulWidget {
  const MyFlowEditor({super.key});

  @override
  State<MyFlowEditor> createState() => _MyFlowEditorState();
}

class _MyFlowEditorState extends State<MyFlowEditor> {
  // Create controller with initial nodes and connections
  late final controller = NodeFlowController<String, dynamic>(
    nodes: [
      Node<String>(
        id: 'start',
        type: 'input',
        position: const Offset(100, 100),
        size: const Size(140, 70),
        data: 'Start',
        outputPorts: const [
          Port(id: 'out', name: 'Out', position: PortPosition.right),
        ],
      ),
      Node<String>(
        id: 'process',
        type: 'default',
        position: const Offset(320, 100),
        size: const Size(140, 70),
        data: 'Process',
        inputPorts: const [
          Port(id: 'in', name: 'In', position: PortPosition.left),
        ],
        outputPorts: const [
          Port(id: 'out', name: 'Out', position: PortPosition.right),
        ],
      ),
      Node<String>(
        id: 'end',
        type: 'output',
        position: const Offset(540, 100),
        size: const Size(140, 70),
        data: 'End',
        inputPorts: const [
          Port(id: 'in', name: 'In', position: PortPosition.left),
        ],
      ),
    ],
    connections: [
      Connection(
        id: 'conn-1',
        sourceNodeId: 'start',
        sourcePortId: 'out',
        targetNodeId: 'process',
        targetPortId: 'in',
      ),
      Connection(
        id: 'conn-2',
        sourceNodeId: 'process',
        sourcePortId: 'out',
        targetNodeId: 'end',
        targetPortId: 'in',
      ),
    ],
  );

  void _addNode() {
    final id = 'node-${DateTime.now().millisecondsSinceEpoch}';
    controller.addNode(Node<String>(
      id: id,
      type: 'default',
      position: const Offset(200, 250),
      size: const Size(140, 70),
      data: 'New Node',
      inputPorts: [Port(id: '$id-in', name: 'In', position: PortPosition.left)],
      outputPorts: [Port(id: '$id-out', name: 'Out', position: PortPosition.right)],
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Flow Editor'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: 'Add Node',
            onPressed: _addNode,
          ),
          IconButton(
            icon: const Icon(Icons.fit_screen),
            tooltip: 'Fit View',
            onPressed: () => controller.fitToView(),
          ),
        ],
      ),
      body: NodeFlowEditor<String, dynamic>(
        controller: controller,
        theme: NodeFlowTheme.light,
        nodeBuilder: (context, node) => Center(
          child: Text(
            node.data,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
        events: NodeFlowEvents(
          node: NodeEvents(
            onTap: (node) => debugPrint('Tapped: ${node.data}'),
          ),
          connection: ConnectionEvents(
            onCreated: (conn) => debugPrint('Connected: ${conn.id}'),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }
}
```

## Interactions Out of the Box

Your editor now supports:

| Interaction           | How                                       |
| --------------------- | ----------------------------------------- |
| **Pan canvas**        | Left-click drag on empty canvas           |
| **Zoom**              | Mouse wheel or pinch gesture              |
| **Auto-pan**          | Drag nodes near canvas edge               |
| **Select node**       | Click on a node                           |
| **Multi-select**      | Shift + click, or Shift + drag marquee    |
| **Drag node**         | Click and drag a node                     |
| **Duplicate**         | Ctrl/Cmd + D                              |
| **Create connection** | Drag from an output port to an input port |
| **Delete**            | Select and press Delete or Backspace      |
| **Fit view**          | Press `F` key                             |
| **Fit selected**      | Press `H` key                             |
| **Select all**        | Ctrl/Cmd + A                              |
| **Toggle minimap**    | Press `M` key                             |
| **Toggle snapping**   | Press `N` key                             |

## Customization Options

::: code-group

```dart [Theme]
NodeFlowEditor<String, dynamic>(
  controller: controller,
  theme: NodeFlowTheme.dark, // or NodeFlowTheme.light
  // Or customize an existing theme:
  // theme: NodeFlowTheme.dark.copyWith(
  //   backgroundColor: Colors.grey.shade900,
  //   nodeTheme: NodeTheme.dark.copyWith(
  //     backgroundColor: Colors.blue.shade800,
  //     borderColor: Colors.blue.shade400,
  //   ),
  //   connectionTheme: ConnectionTheme.dark.copyWith(
  //     style: ConnectionStyles.bezier,
  //     color: Colors.blue,
  //   ),
  //   gridTheme: GridTheme.dark.copyWith(
  //     style: GridStyles.dots,
  //     color: Colors.grey.shade700,
  //   ),
  // ),
)
```

```dart [Events]
NodeFlowEditor<String, dynamic>(
  controller: controller,
  events: NodeFlowEvents(
    node: NodeEvents(
      onTap: (node) => print('Tapped: ${node.id}'),
      onDoubleTap: (node) => _editNode(node),
      onDragStop: (node) => _savePosition(node),
    ),
    connection: ConnectionEvents(
      onCreated: (conn) => print('Created: ${conn.id}'),
      onDeleted: (conn) => print('Deleted: ${conn.id}'),
    ),
    viewport: ViewportEvents(
      onCanvasTap: (pos) => _handleCanvasTap(pos),
    ),
    onSelectionChange: (state) => _updateToolbar(state),
  ),
)
```

```dart [Behavior]
NodeFlowEditor<String, dynamic>(
  controller: controller,
  // Use behavior presets to control interaction modes
  behavior: NodeFlowBehavior.design,   // Full editing (default)
  // behavior: NodeFlowBehavior.preview, // Navigate only, no structural changes
  // behavior: NodeFlowBehavior.present, // Display only, no interaction
  scrollToZoom: true,      // Enable scroll wheel zoom
  showAnnotations: true,   // Show GroupNode/CommentNode annotations
)
```

:::

## Next Steps

  - **[Core Concepts](/docs/concepts/architecture)** - Understand nodes, ports, and connections
  - **[Theming](/docs/theming/overview)** - Customize every visual aspect
  - **[Connection Styles](/docs/theming/connection-styles)** - Bezier, step, straight, and more
  - **[Serialization](/docs/advanced/serialization)** - Save and load your flows
