---
title: NodeFlowViewer
description: Read-only viewer for node flow graphs
---

# NodeFlowViewer

The `NodeFlowViewer` is a simplified widget for displaying node flow graphs in a read-only mode. It wraps `NodeFlowEditor` with `NodeFlowBehavior.preview`, allowing navigation (pan, zoom, select, drag) but preventing structural changes (create, update, delete).

::: details 🖼️ NodeFlowViewer Demo
Short animation showing the viewer in action: panning around a workflow graph, zooming in/out, selecting nodes to see details, but demonstrating that right-click or delete attempts are ignored (no structural changes allowed)
:::

## Use Cases

- **Debug views**: Show workflow state during execution
- **Previews**: Display graph thumbnails with limited interaction
- **Reports**: Embed flow visualizations in read-only contexts
- **History views**: Show saved graph versions without edit capability

## Constructor

```dart
NodeFlowViewer<T, dynamic>({
  Key? key,
  required NodeFlowController<T, dynamic> controller,
  required Widget Function(BuildContext, Node<T>) nodeBuilder,
  required NodeFlowTheme theme,
  bool scrollToZoom = true,
  bool showAnnotations = false,
  ValueChanged<Node<T>?>? onNodeTap,
  ValueChanged<Node<T>?>? onNodeSelected,
  ValueChanged<Connection?>? onConnectionTap,
  ValueChanged<Connection?>? onConnectionSelected,
})
```

## Required Parameters

### controller

```dart
required NodeFlowController<T, dynamic> controller
```

The controller managing the node flow state. Create it externally:

```dart
final controller = NodeFlowController<MyData, dynamic>();
// Load data into controller...
```

Or use the `withData` factory to create one automatically.

### nodeBuilder

```dart
required Widget Function(BuildContext, Node<T>) nodeBuilder
```

Builds the visual representation for each node:

```dart
nodeBuilder: (context, node) {
  return Container(
    padding: EdgeInsets.all(12),
    child: Column(
      children: [
        Text(node.data.title, style: TextStyle(fontWeight: FontWeight.bold)),
        Text(node.data.status),
      ],
    ),
  );
}
```

### theme

```dart
required NodeFlowTheme theme
```

Visual theme for the viewer:

```dart
theme: NodeFlowTheme.light
// or
theme: NodeFlowTheme.dark
```

## Optional Parameters

### scrollToZoom

```dart
bool scrollToZoom = true
```

When `true`, trackpad scroll zooms the canvas. When `false`, scroll pans instead.

### showAnnotations

```dart
bool showAnnotations = false
```

Whether to display annotations (sticky notes, markers, groups). Defaults to `false` for viewers to keep the display clean.

### Event Callbacks

```dart
ValueChanged<Node<T>?>? onNodeTap
ValueChanged<Node<T>?>? onNodeSelected
ValueChanged<Connection?>? onConnectionTap
ValueChanged<Connection?>? onConnectionSelected
```

Handle node and connection interactions:

```dart
NodeFlowViewer<MyData, dynamic>(
  controller: controller,
  theme: NodeFlowTheme.light,
  nodeBuilder: nodeBuilder,
  onNodeTap: (node) {
    if (node != null) {
      print('Tapped: ${node.id}');
    }
  },
  onNodeSelected: (node) {
    setState(() => _selectedNode = node);
  },
  onConnectionTap: (conn) {
    if (conn != null) {
      print('Connection: ${conn.id}');
    }
  },
)
```

## Factory: withData

For convenience, use the `withData` factory to create a viewer with pre-loaded data:

```dart
static NodeFlowViewer<T, dynamic> withData<T>({
  required NodeFlowTheme theme,
  required Widget Function(BuildContext, Node<T>) nodeBuilder,
  required Map<String, Node<T>> nodes,
  required List<Connection> connections,
  NodeFlowConfig? config,
  GraphViewport? initialViewport,
  // ... other optional parameters
})
```

This creates a `NodeFlowController` internally and populates it with the provided data:

```dart
final viewer = NodeFlowViewer.withData<WorkflowStep>(
  theme: NodeFlowTheme.light,
  nodeBuilder: (context, node) => WorkflowNodeWidget(node: node),
  nodes: {
    'start': Node(
      id: 'start',
      type: 'trigger',
      position: Offset(100, 100),
      size: Size(120, 60),
      data: WorkflowStep(name: 'Start'),
      outputPorts: [Port(id: 'start-out', name: 'Next')],
    ),
    'process': Node(
      id: 'process',
      type: 'action',
      position: Offset(300, 100),
      size: Size(120, 60),
      data: WorkflowStep(name: 'Process'),
      inputPorts: [Port(id: 'process-in', name: 'Input')],
      outputPorts: [Port(id: 'process-out', name: 'Output')],
    ),
  },
  connections: [
    Connection(
      id: 'conn-1',
      sourceNodeId: 'start',
      sourcePortId: 'start-out',
      targetNodeId: 'process',
      targetPortId: 'process-in',
    ),
  ],
  onNodeTap: (node) => print('Tapped: ${node?.id}'),
);
```

::: info
When using `withData`, the controller is created internally. You won't have direct access to it for programmatic operations like `fitToView()`. If you need controller access, create the controller yourself.

:::

## Comparison with NodeFlowEditor

| Feature | NodeFlowViewer | NodeFlowEditor (design) | NodeFlowEditor (present) |
|---------|:--------------:|:-----------------------:|:------------------------:|
| Pan | Yes | Yes | No |
| Zoom | Yes | Yes | No |
| Select | Yes | Yes | No |
| Drag nodes | Yes | Yes | No |
| Create nodes | No | Yes | No |
| Delete nodes | No | Yes | No |
| Create connections | No | Yes | No |
| Delete connections | No | Yes | No |
| Edit annotations | No | Yes | No |

## Complete Example

```dart
class WorkflowPreview extends StatefulWidget {
  final Map<String, Node<WorkflowStep>> nodes;
  final List<Connection> connections;

  const WorkflowPreview({
    required this.nodes,
    required this.connections,
  });

  @override
  State<WorkflowPreview> createState() => _WorkflowPreviewState();
}

class _WorkflowPreviewState extends State<WorkflowPreview> {
  late final NodeFlowController<WorkflowStep, dynamic> _controller;
  Node<WorkflowStep>? _selectedNode;

  @override
  void initState() {
    super.initState();
    _controller = NodeFlowController<WorkflowStep, dynamic>();

    // Load data
    for (final node in widget.nodes.values) {
      _controller.addNode(node);
    }
    for (final connection in widget.connections) {
      _controller.addConnection(connection);
    }

    // Fit view after frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _controller.fitToView();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Info bar
        if (_selectedNode != null)
          Container(
            padding: EdgeInsets.all(12),
            color: Colors.blue.shade50,
            child: Row(
              children: [
                Text('Selected: ${_selectedNode!.data.name}'),
                Spacer(),
                TextButton(
                  onPressed: () => _controller.centerOnNode(_selectedNode!.id),
                  child: Text('Center'),
                ),
              ],
            ),
          ),

        // Viewer
        Expanded(
          child: NodeFlowViewer<WorkflowStep, dynamic>(
            controller: _controller,
            theme: NodeFlowTheme.light,
            nodeBuilder: (context, node) => _buildNode(node),
            showAnnotations: false,
            onNodeTap: (node) {
              if (node != null) {
                _showNodeDetails(node);
              }
            },
            onNodeSelected: (node) {
              setState(() => _selectedNode = node);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildNode(Node<WorkflowStep> node) {
    final step = node.data;
    return Container(
      padding: EdgeInsets.all(12),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(_getIconForType(node.type)),
          SizedBox(height: 4),
          Text(
            step.name,
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          if (step.status != null)
            Text(
              step.status!,
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
        ],
      ),
    );
  }

  IconData _getIconForType(String type) {
    switch (type) {
      case 'trigger': return Icons.play_arrow;
      case 'action': return Icons.flash_on;
      case 'condition': return Icons.call_split;
      default: return Icons.circle;
    }
  }

  void _showNodeDetails(Node<WorkflowStep> node) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(node.data.name),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('ID: ${node.id}'),
            Text('Type: ${node.type}'),
            Text('Position: ${node.position.value}'),
            if (node.data.status != null)
              Text('Status: ${node.data.status}'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Close'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}

class WorkflowStep {
  final String name;
  final String? status;

  WorkflowStep({required this.name, this.status});
}
```

## Best Practices

1. **Use for read-only contexts**: If users shouldn't edit the graph, use `NodeFlowViewer` instead of disabling features on `NodeFlowEditor`

2. **Provide interaction feedback**: Even though editing is disabled, show selection state and respond to taps

3. **Consider minimap**: Enable minimap for large graphs to help users navigate

4. **Fit to view on load**: Call `controller.fitToView()` after the first frame to show all content

5. **Hide annotations**: Set `showAnnotations: false` for cleaner previews unless annotations are important

## See Also

- [NodeFlowEditor](/docs/components/node-flow-editor) - Full-featured editor
- [NodeFlowBehavior](/docs/components/node-flow-editor#behavior-modes) - Behavior mode details
- [Configuration](/docs/core-concepts/configuration) - NodeFlowConfig options
