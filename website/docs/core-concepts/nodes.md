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
  final String id;                        // Unique identifier
  final String type;                      // Node type for categorization
  final Observable<Offset> position;      // Position on canvas
  final Observable<Offset> visualPosition; // Visual position (may include snap-to-grid)
  final Observable<Size> size;            // Dimensions
  final T data;                           // Your custom data (any type)
  final ObservableList<Port> inputPorts;  // Input connection points
  final ObservableList<Port> outputPorts; // Output connection points
  final Observable<int> zIndex;           // Layer order
  final Observable<bool> selected;        // Selection state
  final Observable<bool> dragging;        // Dragging state
  final NodeRenderLayer layer;            // Rendering layer (background/middle/foreground)
  final bool locked;                      // Prevent user dragging (programmatic moves still work)
  final bool selectable;                  // Whether node participates in marquee selection
  bool isVisible;                         // Show/hide node (getter/setter)
  bool isResizable;                       // Whether node can be resized (getter)
}
```

### Node Render Layers

Nodes are rendered in three layers:

```dart
enum NodeRenderLayer {
  background,  // Behind regular nodes (e.g., group annotations)
  middle,      // Default layer for regular nodes
  foreground,  // Above nodes and connections (e.g., sticky notes)
}
```

## Node Anatomy

::: details Node Anatomy Diagram
<!-- TODO: Add visual diagram showing node anatomy -->
A node consists of the following visual elements:

**Container Elements:**
- **Node Background** - The filled area using `NodeTheme.backgroundColor`
- **Node Border** - The outline using `NodeTheme.borderColor` and `borderWidth`
- **Node Shape** - Optional custom shape (Circle, Diamond, Hexagon, etc.)
- **Selection Highlight** - Visual feedback when selected using `NodeTheme.selectedBackgroundColor`
- **Drag Shadow** - Shadow effect during drag operations

**Content Elements:**
- **Title Area** - Header section styled with `NodeTheme.titleStyle`
- **Content Area** - Main body styled with `NodeTheme.contentStyle`
- **Custom Widget** - Your `nodeBuilder` content

**Interaction Elements:**
- **Resize Handles** - Appear on resizable nodes (GroupNode, CommentNode)
- **Ports** - Connection points on node edges (see [Ports](/docs/core-concepts/ports))

**State Indicators:**
- **Hover State** - Visual feedback using `NodeTheme.highlightBackgroundColor`
- **Locked State** - Visual indicator when `node.locked = true`
- **Editing State** - Special mode for inline editing (CommentNode)
:::

## Creating Nodes

::: code-group

```dart [Basic Node]
final node = Node<ProcessData>(
  id: 'node-1',
  type: 'process',
  position: const Offset(100, 100),
  size: const Size(200, 100),
  data: ProcessData(title: 'Process Step'),
  inputPorts: [
    Port(
      id: 'input-1',
      name: 'Input',
      position: PortPosition.left,
      // type is inferred as PortType.input for left/top positions
    ),
  ],
  outputPorts: [
    Port(
      id: 'output-1',
      name: 'Output',
      position: PortPosition.right,
      // type is inferred as PortType.output for right/bottom positions
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
  inputPorts: [
    Port(
      id: 'cond-input',
      name: 'Input',
      position: PortPosition.left,
    ),
  ],
  outputPorts: [
    Port(
      id: 'true-output',
      name: 'True',
      position: PortPosition.right,
      offset: const Offset(0, 33),  // 1/3 of node height
    ),
    Port(
      id: 'false-output',
      name: 'False',
      position: PortPosition.right,
      offset: const Offset(0, 67),  // 2/3 of node height
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

::: details Node Types Visualization
Four node types shown with distinct visual treatments: Start node (rounded/circular, green), Process node (rectangular, blue), Condition node (diamond shape, yellow with True/False outputs), End node (rounded/circular, red). Each shows appropriate port configurations.
:::

## Specialized Node Types

Vyuh Node Flow provides two specialized node types that extend the base `Node` class with additional capabilities:

### GroupNode

`GroupNode` creates visual regions for containing other nodes. It includes both `ResizableMixin` and `GroupableMixin`.

```dart
final groupNode = GroupNode<String>(
  id: 'group-1',
  position: const Offset(100, 100),
  size: const Size(400, 300),
  title: 'Processing Region',
  data: 'group-data',
  color: Colors.blue,
  behavior: GroupBehavior.bounds,  // or .explicit, .parent
);
```

Group behaviors:
- **bounds**: Spatial containment - nodes inside the bounds move with the group
- **explicit**: Auto-sizes to fit explicitly added member nodes
- **parent**: Parent-child link - nodes move with group but can be positioned outside

### CommentNode

`CommentNode` creates sticky note-style annotations. It includes `ResizableMixin`.

```dart
final comment = CommentNode<String>(
  id: 'note-1',
  position: const Offset(100, 100),
  text: 'This is a reminder',
  data: 'optional-data',
  width: 200,
  height: 150,
  color: Colors.yellow,
);
```

Features:
- Inline text editing (double-click to edit)
- Auto-grow height when text exceeds bounds
- Renders in foreground layer (above regular nodes)
- Does not participate in marquee selection

## Node Positioning

::: code-group

```dart [Absolute Positioning]
// Direct observable access
node.position.value = const Offset(100, 200);

// Or use controller method (respects snap-to-grid)
controller.setNodePosition('node-1', const Offset(100, 200));
```

```dart [Relative Positioning]
// Move right by 50 pixels using controller
controller.moveNode('node-1', const Offset(50, 0));

// Or directly via observable
final currentPos = node.position.value;
node.position.value = currentPos + const Offset(50, 0);
```

```dart [Move Selected Nodes]
// Move all selected nodes together
controller.moveSelectedNodes(const Offset(50, 0));
```

:::

## Z-Index and Layering

Control which nodes appear on top:

```dart
// Bring node to front (renders on top of all other nodes)
controller.bringNodeToFront('node-1');

// Send to back (renders behind all other nodes)
controller.sendNodeToBack('node-1');

// Incremental positioning
controller.bringNodeForward('node-1');  // Move one step forward
controller.sendNodeBackward('node-1');  // Move one step backward

// Direct observable access
node.zIndex.value = 10;
```

## Node Widget Rendering

There are two approaches for rendering node content:

### Using nodeBuilder

Provide a custom widget builder to render nodes based on their type:

```dart
NodeFlowEditor<MyData, dynamic>(
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

### Self-Rendering Nodes

Nodes can override `buildWidget()` to control their own rendering. This is used by specialized nodes like `GroupNode` and `CommentNode`:

```dart
class MyCustomNode<T> extends Node<T> {
  @override
  Widget? buildWidget(BuildContext context) {
    return Container(
      // Custom widget implementation
    );
  }
}
```

When `buildWidget()` returns non-null, the `nodeBuilder` callback is not used for that node.

### Using NodeWidget

For standard node styling, use the `NodeWidget` class:

```dart
NodeWidget<MyData>(
  node: node,
  theme: nodeTheme,
  child: MyCustomContent(data: node.data),
  backgroundColor: Colors.blue.shade50,
)

// Or use default styling
NodeWidget<MyData>.defaultStyle(
  node: node,
  theme: nodeTheme,
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
      width: node.size.value.width,
      height: node.size.value.height,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.blue, width: 2),
        boxShadow: const [
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
          const Icon(Icons.settings, size: 32, color: Colors.blue),
          const SizedBox(height: 8),
          Text(
            node.data.title,
            style: const TextStyle(
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

// Or select multiple at once
controller.selectNodes(['node-1', 'node-2', 'node-3']);
controller.selectNodes(['node-4', 'node-5'], toggle: true);
```

```dart [Clear Selection]
controller.clearNodeSelection();
```

```dart [Check Selection]
// Check if a specific node is selected
final isSelected = controller.isNodeSelected('node-1');

// Get all selected node IDs
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
// Direct removal (skips lock checks and callbacks)
controller.removeNode('node-1');

// Request deletion (respects locks and onBeforeDelete callback)
final deleted = await controller.requestDeleteNode('node-1');
if (!deleted) {
  print('Node deletion was prevented');
}

// Delete multiple nodes
controller.deleteNodes(['node-1', 'node-2', 'node-3']);
```

```dart [Duplicate Node]
// Creates a copy with new ID, offset by 50px
controller.duplicateNode('node-1');
```

```dart [Update Node]
final node = controller.getNode('node-1');
if (node != null) {
  node.position.value = const Offset(200, 200);
  // Node data is mutable if needed
}

// Or use controller methods
controller.setNodePosition('node-1', const Offset(200, 200));
controller.setNodeSize('node-1', const Size(150, 100));
```

```dart [Find Nodes]
// Get node by ID
final node = controller.getNode('node-1');

// Get all node IDs
final allNodeIds = controller.nodeIds;
final count = controller.nodeCount;

// Get nodes by type
final processNodes = controller.getNodesByType('process');

// Get visible/hidden nodes
final visibleNodes = controller.getVisibleNodes();
final hiddenNodes = controller.getHiddenNodes();

// Get node bounds
final bounds = controller.getNodeBounds('node-1');
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

## Node Visibility

Control node visibility programmatically:

```dart
// Set visibility for a single node
controller.setNodeVisibility('node-1', false);  // Hide
controller.setNodeVisibility('node-1', true);   // Show

// Toggle visibility
final newVisibility = controller.toggleNodeVisibility('node-1');

// Bulk operations
controller.setNodesVisibility(['node-1', 'node-2'], false);
controller.hideAllNodes();
controller.showAllNodes();
controller.hideSelectedNodes();
controller.showSelectedNodes();
```

## Node Alignment and Distribution

Align and distribute multiple nodes:

```dart
// Align nodes (requires at least 2 nodes)
controller.alignNodes(['node-1', 'node-2', 'node-3'], NodeAlignment.left);
controller.alignNodes(['node-1', 'node-2', 'node-3'], NodeAlignment.center);

// Distribute nodes evenly (requires at least 3 nodes)
controller.distributeNodesHorizontally(['node-1', 'node-2', 'node-3']);
controller.distributeNodesVertically(['node-1', 'node-2', 'node-3']);
```

Available alignments: `left`, `right`, `top`, `bottom`, `center`, `horizontalCenter`, `verticalCenter`

## Best Practices

1. **Unique IDs**: Always use unique, meaningful IDs
2. **Type Naming**: Use consistent type naming convention
3. **Data Immutability**: Consider implementing `NodeData` interface for cloneable data
4. **Size Consistency**: Keep similar node types at similar sizes
5. **Port Placement**: Place ports logically for flow direction
6. **Z-Index**: Use controller methods like `bringNodeToFront()` instead of direct manipulation
7. **Widget Performance**: Keep node widgets lightweight
8. **Use Observables Reactively**: Access `.value` inside Observer widgets for reactive updates

## Common Patterns

### Factory Pattern for Nodes

```dart
class NodeFactory {
  static Node<MyData> createStartNode(Offset position) {
    return Node<MyData>(
      id: 'start-${DateTime.now().millisecondsSinceEpoch}',
      type: 'start',
      position: position,
      size: const Size(100, 60),
      data: MyData(title: 'Start'),
      outputPorts: [
        Port(
          id: 'start-out',
          name: 'Output',
          position: PortPosition.right,
        ),
      ],
    );
  }

  static Node<MyData> createProcessNode(Offset position, String title) {
    return Node<MyData>(
      id: 'process-${DateTime.now().millisecondsSinceEpoch}',
      type: 'process',
      position: position,
      size: const Size(150, 80),
      data: MyData(title: title),
      inputPorts: [
        Port(id: 'in-1', name: 'Input', position: PortPosition.left),
      ],
      outputPorts: [
        Port(id: 'out-1', name: 'Output', position: PortPosition.right),
      ],
    );
  }
}
```

### Port Management

Nodes support dynamic port management:

```dart
final node = controller.getNode('node-1');
if (node != null) {
  // Add ports
  node.addInputPort(Port(id: 'new-in', name: 'New Input', position: PortPosition.left));
  node.addOutputPort(Port(id: 'new-out', name: 'New Output', position: PortPosition.right));

  // Remove ports
  node.removeInputPort('input-id');
  node.removeOutputPort('output-id');
  node.removePort('any-port-id');  // Searches both input and output

  // Update ports
  node.updateInputPort('input-id', updatedPort);
  node.updateOutputPort('output-id', updatedPort);

  // Find ports
  final port = node.findPort('port-id');
  final allPorts = node.allPorts;
}

// Or use controller methods
controller.addInputPort('node-1', port);
controller.addOutputPort('node-1', port);
controller.removePort('node-1', 'port-id');
controller.setNodePorts('node-1', inputPorts: [...], outputPorts: [...]);
```

## Next Steps

- Learn about [Ports](/docs/core-concepts/ports)
- Explore [Connections](/docs/core-concepts/connections)
- See [Node Examples](/docs/examples/custom-nodes)
