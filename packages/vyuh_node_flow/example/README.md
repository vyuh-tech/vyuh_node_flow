# Vyuh Node Flow - Examples

This document provides practical examples to help you get started with Vyuh Node Flow.

---

## 🚀 Quick Start - Simple Flow Editor

Here's a minimal example to create a basic node flow editor:

```dart
import 'package:flutter/material.dart';
import 'package:vyuh_node_flow/vyuh_node_flow.dart';

class SimpleFlowEditor extends StatefulWidget {
  @override
  State<SimpleFlowEditor> createState() => _SimpleFlowEditorState();
}

class _SimpleFlowEditorState extends State<SimpleFlowEditor> {
  late final NodeFlowController<String> controller;

  @override
  void initState() {
    super.initState();

    // 1. Create the controller
    controller = NodeFlowController<String>();

    // 2. Add some nodes
    controller.addNode(Node<String>(
      id: 'node-1',
      type: 'input',
      position: const Offset(100, 100),
      data: 'Input Node',
      outputPorts: const [Port(id: 'out', name: 'Output')],
    ));

    controller.addNode(Node<String>(
      id: 'node-2',
      type: 'output',
      position: const Offset(400, 100),
      data: 'Output Node',
      inputPorts: const [Port(id: 'in', name: 'Input')],
    ));

    // 3. Create a connection between nodes
    controller.createConnection('node-1', 'out', 'node-2', 'in');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Simple Flow Editor')),
      body: NodeFlowEditor<String>(
        controller: controller,
        theme: NodeFlowTheme.light,
        nodeBuilder: (context, node) => _buildNode(node),
      ),
    );
  }

  Widget _buildNode(Node<String> node) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            node.data,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(
            node.type,
            style: TextStyle(fontSize: 10, color: Colors.grey.shade600),
          ),
        ],
      ),
    );
  }
}
```

---

## 🎨 Customizing the Theme

You can easily customize the appearance of your flow editor:

```dart
import 'package:flutter/material.dart';
import 'package:vyuh_node_flow/vyuh_node_flow.dart';

class ThemedFlowEditor extends StatefulWidget {
  @override
  State<ThemedFlowEditor> createState() => _ThemedFlowEditorState();
}

class _ThemedFlowEditorState extends State<ThemedFlowEditor> {
  late final NodeFlowController<String> controller;

  @override
  void initState() {
    super.initState();
    controller = NodeFlowController<String>();

    // Create a custom theme
    final customTheme = NodeFlowTheme.light.copyWith(
      connectionStyle: ConnectionStyles.smoothstep,
      connectionTheme: NodeFlowTheme.light.connectionTheme.copyWith(
        color: Colors.blue.shade300,
        strokeWidth: 2.5,
      ),
      portTheme: NodeFlowTheme.light.portTheme.copyWith(
        size: 12.0,
        color: Colors.blue.shade400,
      ),
      gridStyle: GridStyle.dots,
      gridColor: Colors.grey.shade300,
    );

    // Apply the theme
    controller.setTheme(customTheme);

    // Add your nodes...
    _setupNodes();
  }

  void _setupNodes() {
    controller.addNode(Node<String>(
      id: 'start',
      type: 'start',
      position: const Offset(100, 200),
      data: 'Start',
      outputPorts: const [Port(id: 'out', name: 'Next')],
    ));

    controller.addNode(Node<String>(
      id: 'process',
      type: 'process',
      position: const Offset(350, 200),
      data: 'Process',
      inputPorts: const [Port(id: 'in', name: 'Input')],
      outputPorts: const [Port(id: 'out', name: 'Output')],
    ));

    controller.addNode(Node<String>(
      id: 'end',
      type: 'end',
      position: const Offset(600, 200),
      data: 'End',
      inputPorts: const [Port(id: 'in', name: 'Finish')],
    ));

    // Connect the nodes
    controller.createConnection('start', 'out', 'process', 'in');
    controller.createConnection('process', 'out', 'end', 'in');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Themed Flow Editor'),
        actions: [
          IconButton(
            icon: const Icon(Icons.light_mode),
            onPressed: () => controller.setTheme(NodeFlowTheme.light),
            tooltip: 'Light Theme',
          ),
          IconButton(
            icon: const Icon(Icons.dark_mode),
            onPressed: () => controller.setTheme(NodeFlowTheme.dark),
            tooltip: 'Dark Theme',
          ),
        ],
      ),
      body: NodeFlowEditor<String>(
        controller: controller,
        nodeBuilder: (context, node) => _buildNode(node),
      ),
    );
  }

  Widget _buildNode(Node<String> node) {
    final color = _getNodeColor(node.type);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        border: Border.all(color: color, width: 2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(_getNodeIcon(node.type), color: color),
          const SizedBox(height: 8),
          Text(
            node.data,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Color _getNodeColor(String type) {
    switch (type) {
      case 'start':
        return Colors.green;
      case 'process':
        return Colors.blue;
      case 'end':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  IconData _getNodeIcon(String type) {
    switch (type) {
      case 'start':
        return Icons.play_arrow;
      case 'process':
        return Icons.settings;
      case 'end':
        return Icons.stop;
      default:
        return Icons.circle;
    }
  }
}
```

---

## 🎯 Key Concepts

### 1. **Controller**

The `NodeFlowController` manages all state including nodes, connections, and viewport.

### 2. **Nodes**

Each node has:

- `id`: Unique identifier
- `type`: Category/type of the node
- `position`: Position on the canvas
- `data`: Your custom data (type-safe with generics!)
- `inputPorts` / `outputPorts`: Connection points

### 3. **Ports**

Connection points on nodes:

- Can be positioned on any side (left, right, top, bottom)
- Support validation for allowed connections
- Customizable appearance

### 4. **Theme**

Control the visual appearance:

- Built-in light/dark themes
- Fully customizable colors, sizes, and styles
- Grid styles (dots, lines, hierarchical, none)
- Connection styles (bezier, smoothstep, straight, step)

---

## 🌐 Interactive Demo

Want to see all features in action? Check out our comprehensive demo:

**[👉 Launch Live Demo](https://flow.demo.vyuh.tech)**

The demo includes:

- Multiple workflow examples
- Full theme customization
- Layout algorithms
- Annotations and markers
- Minimap navigation
- Keyboard shortcuts
- And much more!

---

<p align="center">
  Made with ❤️ by the <a href="https://vyuh.tech">Vyuh Team</a>
</p>
