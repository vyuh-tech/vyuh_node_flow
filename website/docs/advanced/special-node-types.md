---
title: Special Node Types
description: Add comment nodes and group nodes to organize your flows
---

# Special Node Types

::: details 🖼️ Special Node Types Overview
Canvas showing both special node types: yellow CommentNode with multi-line text in the foreground, and a blue GroupNode containing several nodes with 'Data Processing' title header. Shows how they integrate with regular nodes.
:::

Vyuh Node Flow provides two special node types for organizing and annotating your flows. These are full-fledged nodes (not a separate annotation system) and are managed via the standard `controller.addNode()` API.

<Card title="Comment Nodes" href="#comment-nodes">
Free-floating sticky notes for comments and documentation
</Card>
<Card title="Group Nodes" href="#group-nodes">
Visual containers that organize related nodes
</Card>

## Comment Nodes

Comment nodes are free-floating sticky notes that can be placed anywhere on the canvas. They render in the **foreground layer** (above regular nodes) and support inline text editing.

### Creating Comment Nodes

```dart
final comment = CommentNode<String>(
  id: 'note-1',
  position: const Offset(400, 50),
  text: 'This is a reminder!\n\nMulti-line text supported.',
  data: 'optional-data',
  width: 200,
  height: 150,
  color: Colors.yellow,
);
controller.addNode(comment);
```

### Properties

| Property   | Type     | Default          | Description                   |
| ---------- | -------- | ---------------- | ----------------------------- |
| `id`       | `String` | required         | Unique identifier             |
| `position` | `Offset` | required         | Position on canvas            |
| `text`     | `String` | required         | The note content (multi-line) |
| `data`     | `T`      | required         | Custom data of generic type   |
| `width`    | `double` | `200.0`          | Width in pixels (100-600)     |
| `height`   | `double` | `100.0`          | Height in pixels (60-400)     |
| `color`    | `Color`  | `Colors.yellow`  | Background color              |
| `zIndex`   | `int`    | `0`              | Layer order                   |
| `isVisible`| `bool`   | `true`           | Show/hide the node            |
| `locked`   | `bool`   | `false`          | Prevent movement/editing      |

### Features

- **Inline editing**: Double-click to edit text directly
- **Auto-grow height**: Text area expands automatically as you type
- **Resizable**: Drag handles to resize within constraints
- **Foreground layer**: Always renders above regular nodes
- **Escape to cancel**: Press Escape during editing to cancel changes

### Programmatic Updates

```dart
// Get the comment node
final comment = controller.getNode('note-1') as CommentNode<String>?;

if (comment != null) {
  // Update text
  comment.text = 'Updated text content';

  // Change color
  comment.color = Colors.green.shade100;

  // Update size
  comment.setSize(const Size(300, 200));

  // Toggle visibility
  comment.isVisible = false;
}
```

## Group Nodes

Group nodes create visual regions for containing and organizing related nodes. They render in the **background layer** (behind regular nodes) and support three behavior modes.

### Creating Group Nodes

```dart
// Create a basic group (bounds behavior - default)
final group = GroupNode<String>(
  id: 'group-1',
  position: const Offset(50, 50),
  size: const Size(400, 300),
  title: 'Input Processing',
  data: 'group-data',
  color: Colors.blue,
);
controller.addNode(group);

// Create a group with explicit member nodes
final explicitGroup = GroupNode<String>(
  id: 'group-2',
  position: Offset.zero, // Will be computed
  size: Size.zero,       // Will be computed
  title: 'Data Pipeline',
  data: 'pipeline-data',
  behavior: GroupBehavior.explicit,
  nodeIds: {'node-1', 'node-2', 'node-3'},
);
controller.addNode(explicitGroup);
// Fit group bounds to contain member nodes
explicitGroup.fitToNodes((id) => controller.nodes[id]);
```

### Properties

| Property      | Type            | Default               | Description                        |
| ------------- | --------------- | --------------------- | ---------------------------------- |
| `id`          | `String`        | required              | Unique identifier                  |
| `position`    | `Offset`        | required              | Position on canvas                 |
| `size`        | `Size`          | required              | Dimensions (auto for explicit)     |
| `title`       | `String`        | required              | Header label                       |
| `data`        | `T`             | required              | Custom data of generic type        |
| `color`       | `Color`         | `Colors.blue`         | Header and tint color              |
| `behavior`    | `GroupBehavior` | `.bounds`             | Membership mode                    |
| `nodeIds`     | `Set<String>?`  | `null`                | Explicit member nodes              |
| `padding`     | `EdgeInsets`    | `(20, 40, 20, 20)`    | Space around members               |
| `zIndex`      | `int`           | `-1`                  | Layer order (negative = background)|
| `inputPorts`  | `List<Port>`    | `[]`                  | Optional input ports               |
| `outputPorts` | `List<Port>`    | `[]`                  | Optional output ports              |

### Behavior Modes

Groups support three behavior modes that control how nodes interact with the group:

| Mode       | Membership                    | Size                         | Node Movement                           |
| ---------- | ----------------------------- | ---------------------------- | --------------------------------------- |
| `bounds`   | Spatial (nodes inside bounds) | Manual (resizable)           | Nodes can escape by dragging out        |
| `explicit` | Explicit (node ID set)        | Auto-computed (fits members) | Group resizes to contain nodes          |
| `parent`   | Explicit (node ID set)        | Manual (resizable)           | Nodes move with group, can leave bounds |

```dart
// Bounds mode (default) - spatial containment
final boundsGroup = GroupNode<String>(
  id: 'region-1',
  position: const Offset(100, 100),
  size: const Size(300, 200),
  title: 'Processing Region',
  data: 'region-data',
  behavior: GroupBehavior.bounds,
);

// Explicit mode - auto-sizing group
final explicitGroup = GroupNode<String>(
  id: 'explicit-1',
  position: Offset.zero,
  size: Size.zero,
  title: 'Auto-sized Group',
  data: 'explicit-data',
  behavior: GroupBehavior.explicit,
  nodeIds: {'node-1', 'node-2'},
);

// Parent mode - linked but flexible
final parentGroup = GroupNode<String>(
  id: 'parent-1',
  position: const Offset(100, 100),
  size: const Size(300, 200),
  title: 'Parent Group',
  data: 'parent-data',
  behavior: GroupBehavior.parent,
  nodeIds: {'node-1', 'node-2'},
);
```

### Features

- **Inline title editing**: Double-click the title bar to edit
- **Resizable**: Drag handles (except for `explicit` mode which auto-sizes)
- **Background layer**: Renders behind regular nodes by default
- **Color customization**: Header bar uses solid color, body uses translucent
- **Subflow ports**: Optional input/output ports for connecting to other nodes
- **Nested groups**: Groups can contain other groups with automatic z-index handling

### Group with Subflow Ports

Groups can have input/output ports, enabling them to act as subflow containers:

```dart
final subflowGroup = GroupNode<String>(
  id: 'subflow-1',
  position: const Offset(50, 50),
  size: const Size(500, 400),
  title: 'Subflow',
  data: 'subflow-data',
  inputPorts: [
    const Port(id: 'in-1', name: 'Input', position: PortPosition.left),
  ],
  outputPorts: [
    const Port(id: 'out-1', name: 'Output', position: PortPosition.right),
  ],
);
controller.addNode(subflowGroup);
```

### Programmatic Updates

```dart
// Get the group node
final group = controller.getNode('group-1') as GroupNode<String>?;

if (group != null) {
  // Update title
  group.updateTitle('New Title');

  // Change color
  group.updateColor(Colors.green);

  // For explicit/parent modes: manage members
  group.addNode('node-5');
  group.removeNode('node-2');
  group.clearNodes();

  // Change behavior at runtime
  group.setBehavior(
    GroupBehavior.explicit,
    captureContainedNodes: {'node-1', 'node-2'},
    nodeLookup: (id) => controller.nodes[id],
  );

  // For explicit mode: refit to member nodes
  group.fitToNodes((id) => controller.nodes[id]);
}
```

## Node Visibility

Both special node types support visibility toggling:

```dart
// Hide a node
controller.getNode('note-1')?.isVisible = false;

// Show a node
controller.getNode('group-1')?.isVisible = true;

// Create a node that starts hidden
controller.addNode(CommentNode<String>(
  id: 'hidden-note',
  position: const Offset(100, 100),
  text: 'Hidden by default',
  data: '',
  isVisible: false,
));
```

## Complete Example

Here's a workflow demonstrating both special node types:

```dart
class AnnotatedWorkflow extends StatefulWidget {
  @override
  State<AnnotatedWorkflow> createState() => _AnnotatedWorkflowState();
}

class _AnnotatedWorkflowState extends State<AnnotatedWorkflow> {
  late final NodeFlowController<String, dynamic> controller;

  @override
  void initState() {
    super.initState();
    controller = NodeFlowController();
    _setupWorkflow();
  }

  void _setupWorkflow() {
    // Add regular nodes
    controller.addNode(Node(
      id: 'start',
      type: 'start',
      position: const Offset(150, 150),
      size: const Size(120, 60),
      data: 'Start',
      outputPorts: const [Port(id: 'out', position: PortPosition.right)],
    ));

    controller.addNode(Node(
      id: 'process',
      type: 'process',
      position: const Offset(330, 150),
      size: const Size(140, 80),
      data: 'Process Data',
      inputPorts: const [Port(id: 'in', position: PortPosition.left)],
      outputPorts: const [Port(id: 'out', position: PortPosition.right)],
    ));

    controller.addNode(Node(
      id: 'end',
      type: 'end',
      position: const Offset(530, 150),
      size: const Size(120, 60),
      data: 'End',
      inputPorts: const [Port(id: 'in', position: PortPosition.left)],
    ));

    // Connect nodes
    controller.addConnection(Connection(
      id: 'c1',
      sourceNodeId: 'start',
      sourcePortId: 'out',
      targetNodeId: 'process',
      targetPortId: 'in',
    ));

    controller.addConnection(Connection(
      id: 'c2',
      sourceNodeId: 'process',
      sourcePortId: 'out',
      targetNodeId: 'end',
      targetPortId: 'in',
    ));

    // Add a group around the workflow (explicit mode)
    final group = GroupNode<String>(
      id: 'main-group',
      position: Offset.zero,
      size: Size.zero,
      title: 'Main Workflow',
      data: 'group-data',
      behavior: GroupBehavior.explicit,
      nodeIds: {'start', 'process', 'end'},
      color: Colors.indigo,
    );
    controller.addNode(group);
    group.fitToNodes((id) => controller.nodes[id]);

    // Add a documentation comment
    final comment = CommentNode<String>(
      id: 'doc-note',
      position: const Offset(150, 320),
      text: 'This workflow processes incoming data and outputs results.',
      data: '',
      width: 250,
      height: 80,
      color: Colors.amber.shade100,
    );
    controller.addNode(comment);
  }

  @override
  Widget build(BuildContext context) {
    return NodeFlowEditor<String, dynamic>(
      controller: controller,
      nodeBuilder: (context, node) => Center(
        child: Text(node.data),
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

## Serialization

Both node types support JSON serialization via `exportGraph()` and `loadGraph()`:

```dart
// Export includes all nodes (regular, group, and comment)
final graph = controller.exportGraph();
final json = graph.toJson((data) => data);

// Import restores all nodes
// The default node factory automatically handles group and comment nodes
final loadedGraph = NodeGraph.fromJson(
  json,
  (data) => data as String,
);
controller.loadGraph(loadedGraph);

// Or with a custom node factory for additional node types
final loadedGraph = NodeGraph.fromJson(
  json,
  (data) => data as String,
  nodeFromJson: (json, dataFromJson) {
    final type = json['type'] as String;
    switch (type) {
      case 'group':
        return GroupNode.fromJson(json, dataFromJson: dataFromJson);
      case 'comment':
        return CommentNode.fromJson(json, dataFromJson: dataFromJson);
      case 'custom':
        return CustomNode.fromJson(json, dataFromJson: dataFromJson);
      default:
        return Node.fromJson(json, dataFromJson);
    }
  },
);
controller.loadGraph(loadedGraph);
```

## Best Practices

1. **Use groups sparingly** - Too many overlapping groups create visual clutter
2. **Choose the right behavior** - Use `bounds` for regions, `explicit` for auto-sizing, `parent` for linked movement
3. **Keep notes concise** - Comment nodes work best for short reminders, not documentation
4. **Layer thoughtfully** - Groups render behind nodes, comments render in front
5. **Consider locking** - Set `locked: true` for decorative elements that shouldn't be moved

## See Also

- [Level of Detail](/docs/advanced/lod) - Visibility control at different zoom levels
- [Theming Overview](/docs/theming/overview) - Customize node appearance
- [Controller](/docs/concepts/controller) - Full controller API
