---
title: Controller
description: Programmatic control of your node flow graph
---

# NodeFlowController

The `NodeFlowController` is the central API for managing and manipulating your node flow graph programmatically.

## Creating a Controller

```dart
class _MyEditorState extends State<MyEditor> {
  late final NodeFlowController<MyNodeData, dynamic> controller;

  @override
  void initState() {
    super.initState();
    controller = NodeFlowController<MyNodeData, dynamic>();
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }
}
```

## Core Properties

### Accessing Nodes

Access nodes directly from the controller:

```dart
// Get all nodes as a map (package-private, primarily for internal use)
final allNodes = controller.nodes;

// Get specific node by ID
final node = controller.getNode('node-1');

// Get node count
final count = controller.nodeCount;

// Get all node IDs (returns Iterable<String>)
final ids = controller.nodeIds;

// Get nodes by type
final processNodes = controller.getNodesByType('process');
```

### Accessing Connections

```dart
// Get all connections
final connections = controller.connections;

// Get specific connection
final connection = controller.getConnection('conn-1');

// Get connection count
final count = controller.connectionCount;

// Get connections for a specific node
final nodeConnections = controller.getConnectionsForNode('node-1');
```

### Viewport

Control the visible area of the canvas:

```dart
final viewport = controller.viewport;

// Get current zoom level (double)
final zoom = controller.currentZoom;

// Get current pan position (ScreenOffset)
final pan = controller.currentPan;
```

## Node Operations

::: code-group

```dart [Add Node]
final node = Node<MyData>(
  id: 'new-node',
  type: 'process',
  position: Offset(200, 100),
  size: Size(150, 80),
  data: MyData(label: 'New Node'),
  inputPorts: [/* ... */],
  outputPorts: [/* ... */],
);

controller.addNode(node);
```

```dart [Remove Node]
controller.removeNode('node-1');
```

:::

This automatically removes all connections to/from the node.

::: code-group

```dart [Move Node]
// Move by delta
controller.moveNode('node-1', Offset(50, 0));

// Set absolute position
controller.setNodePosition('node-1', Offset(300, 200));
```

```dart [Duplicate Node]
// Duplicates a node and adds it to the graph (returns void)
controller.duplicateNode('node-1');
```

```dart [Get Node]
final node = controller.getNode('node-1');
```

```dart [Delete Multiple Nodes]
controller.deleteNodes(['node-1', 'node-2', 'node-3']);
```

:::

## Connection Operations

::: code-group

```dart [Add Connection]
final connection = Connection(
  id: 'conn-1',
  sourceNodeId: 'node-1',
  sourcePortId: 'out-1',
  targetNodeId: 'node-2',
  targetPortId: 'in-1',
);

controller.addConnection(connection);
```

```dart [Create Connection (Convenience Method)]
// Uses positional parameters and auto-generates connection ID
controller.createConnection(
  'node-1',    // sourceNodeId
  'out-1',     // sourcePortId
  'node-2',    // targetNodeId
  'in-1',      // targetPortId
);
```

```dart [Remove Connection]
controller.removeConnection('conn-1');
```

```dart [Get Connections]
// Get connection by ID
final connection = controller.getConnection('conn-1');

// Get all connections for a node
final nodeConnections = controller.getConnectionsForNode('node-1');

// Get connections from a specific port
final fromPort = controller.getConnectionsFromPort('node-1', 'out-1');

// Get connections to a specific port
final toPort = controller.getConnectionsToPort('node-2', 'in-1');
```

:::

## Selection Operations

::: code-group

```dart [Select Node]
// Single selection (clears previous selection)
controller.selectNode('node-1');

// Toggle selection (add/remove from selection)
controller.selectNode('node-1', toggle: true);
controller.selectNode('node-2', toggle: true);
```

```dart [Select Multiple Nodes]
controller.selectNodes(['node-1', 'node-2', 'node-3']);
```

```dart [Clear Selection]
// Clear all selections (nodes, connections, annotations)
controller.clearSelection();

// Clear only node selection
controller.clearNodeSelection();

// Clear only connection selection
controller.clearConnectionSelection();
```

```dart [Get Selected Nodes]
final selectedIds = controller.selectedNodeIds;

// Get actual node objects
final selectedNodes = selectedIds
    .map((id) => controller.getNode(id))
    .whereType<Node<MyData>>()
    .toList();
```

```dart [Select All]
controller.selectAllNodes();
```

```dart [Check Selection State]
final hasAnySelection = controller.hasSelection;
final isSelected = controller.isNodeSelected('node-1');
```

:::

## Viewport Operations

::: code-group

```dart [Pan Viewport]
// Pan by a delta (in screen pixels)
controller.panBy(ScreenOffset.fromXY(100, 50));
```

```dart [Zoom]
// Set specific zoom level
controller.zoomTo(1.5);

// Zoom by delta (positive = zoom in)
controller.zoomBy(0.1);
```

```dart [Fit to View]
// Fit all nodes in viewport
controller.fitToView();

// Fit only selected nodes
controller.fitSelectedNodes();
```

```dart [Center on Node]
// Center without changing zoom (immediate)
controller.centerOnNode('node-1');

// Center with specific zoom (immediate)
controller.centerOnNodeWithZoom('node-1', zoom: 1.5);

// Animate to node (smooth animation)
controller.animateToNode('node-1', zoom: 1.0);
// Keep current zoom with animation
controller.animateToNode('node-1', zoom: null);
```

```dart [Center Viewport]
// Center on all nodes (keeps current zoom)
controller.centerViewport();

// Center on selection (keeps current zoom)
controller.centerOnSelection();

// Center on specific point in graph coordinates
controller.centerOn(GraphOffset.fromXY(500, 300));
```

```dart [Reset Viewport]
controller.resetViewport();
```

:::

## Coordinate Transformations

Convert between screen and graph coordinate systems using typed coordinates:

```dart
// Screen to graph coordinates (for local/canvas coordinates)
final graphPos = controller.screenToGraph(ScreenPosition(screenPoint));

// Graph to screen coordinates
final screenPos = controller.graphToScreen(GraphPosition(graphPoint));

// Global (widget) to graph coordinates (for gesture globalPosition)
final graphPos = controller.globalToGraph(ScreenPosition(globalPoint));
```

The library uses typed extension types (`ScreenPosition`, `GraphPosition`, `ScreenOffset`, `GraphOffset`, etc.) to prevent accidentally mixing coordinate spaces.

## Alignment Operations

Align multiple nodes relative to each other:

```dart
// Align to left edge
controller.alignNodes(
  ['node-1', 'node-2', 'node-3'],
  NodeAlignment.left,
);

// Align to right edge
controller.alignNodes(selectedNodeIds.toList(), NodeAlignment.right);

// Align horizontal center
controller.alignNodes(selectedNodeIds.toList(), NodeAlignment.horizontalCenter);

// Align to top
controller.alignNodes(selectedNodeIds.toList(), NodeAlignment.top);

// Align to bottom
controller.alignNodes(selectedNodeIds.toList(), NodeAlignment.bottom);

// Align vertical center
controller.alignNodes(selectedNodeIds.toList(), NodeAlignment.verticalCenter);
```

## Distribution Operations

Evenly distribute nodes:

```dart
// Distribute horizontally
controller.distributeNodesHorizontally(selectedNodeIds.toList());

// Distribute vertically
controller.distributeNodesVertically(selectedNodeIds.toList());
```

## Graph Queries

::: code-group

```dart [Get Graph Bounds]
final bounds = controller.nodesBounds;
final width = bounds.width;
final height = bounds.height;
```

```dart [Find Connected Nodes]
// Get connections for a node and extract connected node IDs
final connections = controller.getConnectionsForNode('node-1');
final connectedIds = <String>{};
for (final conn in connections) {
  connectedIds.add(conn.sourceNodeId);
  connectedIds.add(conn.targetNodeId);
}
connectedIds.remove('node-1'); // Remove self
```

```dart [Cycle Detection]
final cycles = controller.detectCycles();
if (cycles.isNotEmpty) {
  print('Found ${cycles.length} cycles in the graph');
}
```

```dart [Orphan Nodes]
final orphanNodes = controller.getOrphanNodes();
print('Found ${orphanNodes.length} unconnected nodes');
```

:::

## Graph Import/Export

::: code-group

```dart [Export Graph]
final graph = controller.exportGraph();
final json = graph.toJson((data) => data.toJson());
// Save to file or API
```

```dart [Load Graph]
final json = jsonDecode(savedJson);
final graph = NodeGraph.fromJson(json, (map) => MyData.fromJson(map));
controller.loadGraph(graph);
```

```dart [Clear Graph]
controller.clearGraph();
```

:::

## Reactive Updates

The controller uses MobX for reactive state management. Wrap your UI in `Observer` to automatically rebuild:

```dart
Observer(
  builder: (_) {
    final nodeCount = controller.nodeCount;
    final connectionCount = controller.connectionCount;

    return Text('Nodes: $nodeCount, Connections: $connectionCount');
  },
)
```

## Custom Controller Extensions

Extend the controller with your own methods:

```dart
extension MyControllerExtensions on NodeFlowController<MyData, dynamic> {
  void addProcessNode(Offset position, String label) {
    final node = Node<MyData>(
      id: 'proc-${DateTime.now().millisecondsSinceEpoch}',
      type: 'process',
      position: position,
      size: Size(150, 80),
      data: MyData(label: label),
      inputPorts: [
        Port(
          id: 'in',
          name: 'Input',
          position: PortPosition.left,
        ),
      ],
      outputPorts: [
        Port(
          id: 'out',
          name: 'Output',
          position: PortPosition.right,
        ),
      ],
    );
    addNode(node);
  }
}

// Usage
controller.addProcessNode(Offset(100, 100), 'My Process');
```

## Performance Tips

1. **Batch Updates**: Group multiple operations together using `runInAction`
2. **Observer Scope**: Keep `Observer` widgets focused and small
3. **Dispose**: Always dispose the controller when done
4. **Node Count**: Monitor performance with large graphs (1000+ nodes)

## Complete Example

```dart
class FlowEditorWithController extends StatefulWidget {
  @override
  State<FlowEditorWithController> createState() =>
      _FlowEditorWithControllerState();
}

class _FlowEditorWithControllerState
    extends State<FlowEditorWithController> {
  late final NodeFlowController<MyData, dynamic> controller;

  @override
  void initState() {
    super.initState();
    controller = NodeFlowController<MyData, dynamic>();
    _initializeGraph();
  }

  void _initializeGraph() {
    // Add initial nodes
    controller.addNode(Node<MyData>(
      id: 'start',
      type: 'start',
      position: Offset(100, 100),
      size: Size(100, 60),
      data: MyData(label: 'Start'),
      outputPorts: [Port(id: 'start-out', name: 'Next')],
    ));

    controller.addNode(Node<MyData>(
      id: 'process',
      type: 'process',
      position: Offset(300, 100),
      size: Size(150, 80),
      data: MyData(label: 'Process'),
      inputPorts: [Port(id: 'process-in', name: 'Input')],
      outputPorts: [Port(id: 'process-out', name: 'Output')],
    ));

    // Connect them
    controller.addConnection(Connection(
      id: 'conn-1',
      sourceNodeId: 'start',
      sourcePortId: 'start-out',
      targetNodeId: 'process',
      targetPortId: 'process-in',
    ));

    // Fit to view
    WidgetsBinding.instance.addPostFrameCallback((_) {
      controller.fitToView();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Observer(
          builder: (_) => Text(
            'Nodes: ${controller.nodeCount}',
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.add),
            onPressed: _addNode,
          ),
          IconButton(
            icon: Icon(Icons.delete),
            onPressed: _deleteSelected,
          ),
          IconButton(
            icon: Icon(Icons.fit_screen),
            onPressed: controller.fitToView,
          ),
        ],
      ),
      body: NodeFlowEditor<MyData, dynamic>(
        controller: controller,
        nodeBuilder: (context, node) => MyNodeWidget(node: node),
      ),
    );
  }

  void _addNode() {
    final center = controller.getViewportCenter();
    controller.addNode(Node<MyData>(
      id: 'node-${DateTime.now().millisecondsSinceEpoch}',
      type: 'process',
      position: center.offset,
      size: Size(150, 80),
      data: MyData(label: 'New Node'),
      inputPorts: [Port(id: 'in', name: 'Input')],
      outputPorts: [Port(id: 'out', name: 'Output')],
    ));
  }

  void _deleteSelected() {
    controller.deleteNodes(controller.selectedNodeIds.toList());
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }
}
```

## Next Steps

- Learn about [Serialization](/docs/advanced/serialization)
- Explore [Event System](/docs/advanced/events)
- See [Examples](/docs/examples/)
