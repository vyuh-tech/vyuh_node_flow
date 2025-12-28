---
title: Nodes
description: Understanding nodes in Vyuh Node Flow
---

# Nodes

Nodes are the fundamental building blocks of your flow graph. They represent entities in your visual programming interface, workflow, or diagram.

## Node Structure

A `Node<T>` is a generic class where `T` can be any type you choose for your custom data:

```dart
class Node<T> {
  final String id;              // Unique identifier
  final String type;            // Node type for categorization
  final Observable<Offset> position;  // Position on canvas
  final Observable<Size> size;  // Dimensions
  final T data;                 // Your custom data (any type)
  final List<Port> inputPorts;  // Input connection points
  final List<Port> outputPorts; // Output connection points
  final Observable<int> zIndex; // Layer order
  bool isVisible;               // Show/hide node
  bool locked;                  // Prevent movement
}
```

## Creating Nodes

::: code-group

```dart [Basic Node]
final node = Node<ProcessData>(
  id: 'node-1',
  type: 'process',
  position: const Offset(100, 100),
  size: const Size(200, 100),
  data: ProcessData(title: 'Process Step'),
  inputPorts: const [
    Port(
      id: 'input-1',
      name: 'Input',
      position: PortPosition.left,
      type: PortType.input,
    ),
  ],
  outputPorts: const [
    Port(
      id: 'output-1',
      name: 'Output',
      position: PortPosition.right,
      type: PortType.output,
    ),
  ],
);
```

```dart [Node with Multiple Ports]
final conditionalNode = Node<ProcessData>(
  id: 'condition-1',
  type: 'condition',
  position: const Offset(300, 100),
  size: const Size(180, 120),
  data: ProcessData(title: 'If/Else'),
  inputPorts: const [
    Port(
      id: 'cond-input',
      name: 'Input',
      position: PortPosition.left,
      type: PortType.input,
    ),
  ],
  outputPorts: const [
    Port(
      id: 'true-output',
      name: 'True',
      position: PortPosition.right,
      type: PortType.output,
      offset: Offset(0, -20),
    ),
    Port(
      id: 'false-output',
      name: 'False',
      position: PortPosition.right,
      type: PortType.output,
      offset: Offset(0, 20),
    ),
  ],
);
```

:::

## Custom Node Data

The generic type `T` in `Node<T>` can be **any type** - a class, record, primitive, or even `void`:

```dart
// Simple class for node data
class ProcessData {
  final String title;
  final String description;
  final Map<String, dynamic> config;

  const ProcessData({
    required this.title,
    this.description = '',
    this.config = const {},
  });
}

// Use with nodes
final node = Node<ProcessData>(
  id: 'node-1',
  type: 'process',
  position: const Offset(100, 100),
  size: const Size(200, 100),
  data: ProcessData(title: 'Process Step'),
  // ...
);
```

For serialization, provide conversion functions:

```dart
// Export
final json = controller.toJson(
  (data) => {
    'title': data.title,
    'description': data.description,
    'config': data.config,
  },
);

// Import
controller.fromJson(
  json,
  dataFromJson: (json) => ProcessData(
    title: json['title'] as String,
    description: json['description'] as String? ?? '',
    config: Map<String, dynamic>.from(json['config'] ?? {}),
  ),
);
```

## Node Types

Use the `type` field to categorize nodes:

```dart
enum NodeType {
  start,
  process,
  condition,
  end,
}

// Create typed nodes
final startNode = Node<MyData>(
  type: NodeType.start.name,
  // ...
);

final processNode = Node<MyData>(
  type: NodeType.process.name,
  // ...
);
```

Benefits:
- Different visual styles based on type
- Type-specific validation rules
- Easy filtering and querying

::: details 🖼️ Node Types Visualization
Four node types shown with distinct visual treatments: Start node (rounded/circular, green), Process node (rectangular, blue), Condition node (diamond shape, yellow with True/False outputs), End node (rounded/circular, red). Each shows appropriate port configurations.
:::

## Node Positioning

::: code-group

```dart [Absolute Positioning]
node.position.value = Offset(100, 200);
```

```dart [Relative Positioning]
// Move right by 50 pixels
final currentPos = node.position.value;
node.position.value = currentPos + Offset(50, 0);
```

```dart [Center in Viewport]
final viewport = controller.viewport;
final centerX = viewport.x + (viewport.width / 2) - (node.size.width / 2);
final centerY = viewport.y + (viewport.height / 2) - (node.size.height / 2);
node.position.value = Offset(centerX, centerY);
```

:::

## Z-Index and Layering

Control which nodes appear on top:

```dart
// Bring node to front
node.zIndex.value = controller.maxZIndex + 1;

// Send to back
node.zIndex.value = controller.minZIndex - 1;
```

## Node Widget Rendering

Provide a custom widget builder:

```dart
NodeFlowEditor<MyData>(
  controller: controller,
  nodeBuilder: (context, node) {
    switch (node.type) {
      case 'start':
        return StartNodeWidget(node: node);
      case 'process':
        return ProcessNodeWidget(node: node);
      case 'condition':
        return ConditionNodeWidget(node: node);
      default:
        return DefaultNodeWidget(node: node);
    }
  },
)
```

### Example Node Widget

```dart
class ProcessNodeWidget extends StatelessWidget {
  final Node<ProcessNodeData> node;

  const ProcessNodeWidget({required this.node});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: node.size.width,
      height: node.size.height,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.blue, width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 8,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.settings, size: 32, color: Colors.blue),
          SizedBox(height: 8),
          Text(
            node.data.title,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
          if (node.data.description.isNotEmpty)
            Text(
              node.data.description,
              style: TextStyle(
                fontSize: 10,
                color: Colors.grey[600],
              ),
            ),
        ],
      ),
    );
  }
}
```

## Node Selection

::: code-group

```dart [Single Selection]
controller.selectNode('node-1');
```

```dart [Toggle Selection (Multi-Select)]
controller.selectNode('node-1', toggle: true);
controller.selectNode('node-2', toggle: true);
```

```dart [Clear Selection]
controller.clearSelection();
```

```dart [Get Selected Nodes]
final selectedIds = controller.selectedNodeIds;
final selectedNodes = selectedIds
    .map((id) => controller.getNode(id))
    .whereType<Node<MyData>>()
    .toList();
```

:::

## Node Operations

::: code-group

```dart [Add Node]
controller.addNode(node);
```

```dart [Remove Node]
controller.removeNode('node-1');
```

```dart [Update Node]
final node = controller.getNode('node-1');
if (node != null) {
  node.position.value = Offset(200, 200);
  // Node data is mutable if needed
}
```

```dart [Find Nodes]
// Get all nodes
final allNodes = controller.nodes.values.toList();

// Get nodes by type
final processNodes = controller.getNodesByType('process');

// Get visible nodes (in viewport)
final visibleNodes = controller.getVisibleNodes();

// Get node bounds
final bounds = controller.nodesBounds;
```

:::

## Interactive Nodes

Make nodes respond to interactions:

```dart
class InteractiveNodeWidget extends StatelessWidget {
  final Node<MyData> node;
  final VoidCallback onTap;

  const InteractiveNodeWidget({
    required this.node,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        // Node UI
        child: Text(node.data.title),
      ),
    );
  }
}

// Usage in node builder
nodeBuilder: (context, node) {
  return InteractiveNodeWidget(
    node: node,
    onTap: () {
      // Handle tap
      showDialog(
        context: context,
        builder: (_) => NodePropertiesDialog(node: node),
      );
    },
  );
}
```

## Best Practices

1. **Unique IDs**: Always use unique, meaningful IDs
2. **Type Naming**: Use consistent type naming convention
3. **Data Immutability**: Consider making NodeData immutable
4. **Size Consistency**: Keep similar node types at similar sizes
5. **Port Placement**: Place ports logically for flow direction
6. **Z-Index**: Use sparingly, only when needed
7. **Widget Performance**: Keep node widgets lightweight

## Common Patterns

### Factory Pattern for Nodes

```dart
class NodeFactory {
  static Node<MyData> createStartNode(Offset position) {
    return Node<MyData>(
      id: 'start-${DateTime.now().millisecondsSinceEpoch}',
      type: 'start',
      position: position,
      size: Size(100, 60),
      data: MyData(title: 'Start'),
      outputPorts: [
        Port(
          id: 'start-out',
          name: 'Output',
          position: PortPosition.right,
          type: PortType.output,
        ),
      ],
    );
  }

  static Node<MyData> createProcessNode(Offset position, String title) {
    return Node<MyData>(
      id: 'process-${DateTime.now().millisecondsSinceEpoch}',
      type: 'process',
      position: position,
      size: Size(150, 80),
      data: MyData(title: title),
      inputPorts: [/* ... */],
      outputPorts: [/* ... */],
    );
  }
}
```

## Next Steps

- Learn about [Ports](/docs/core-concepts/ports)
- Explore [Connections](/docs/core-concepts/connections)
- See [Node Examples](/docs/examples/custom-nodes)
