---
title: NodeFlowEditor
description: Complete API reference for the NodeFlowEditor widget
---

# NodeFlowEditor

The `NodeFlowEditor` is the main widget for creating interactive node-based flow editors. It provides a full-featured canvas with support for nodes, connections, panning, zooming, and more.

::: details 🖼️ NodeFlowEditor Overview
Quick video tour showing the editor in action: creating nodes, connecting ports, panning/zooming the canvas, selecting nodes, and using the minimap
:::

## Built-in Capabilities

The `NodeFlowEditor` provides extensive functionality out-of-the-box:

### Canvas & Viewport

| Capability | Description |
|------------|-------------|
| **Infinite Canvas** | Unlimited workspace in all directions |
| **Pan & Zoom** | Smooth viewport navigation with mouse/trackpad/touch |
| **Zoom to Fit** | Fit all nodes or selection in viewport |
| **Animated Viewport** | Smooth transitions between viewport states |
| **Grid Background** | Optional configurable grid with snap-to-grid |
| **Minimap** | Optional overview for large graphs |

### Nodes

| Capability | Description |
|------------|-------------|
| **Custom Node Widgets** | Full control over node appearance via `nodeBuilder` |
| **Node Shapes** | Rectangle, circle, diamond, hexagon, or custom shapes |
| **Drag & Drop** | Move nodes with mouse/touch, supports multi-selection |
| **Selection** | Single and multi-selection with Shift+click |
| **Selection Box** | Marquee selection by dragging on empty canvas |
| **Resize** | Optional resize handles for nodes |
| **Z-Index Layering** | Control node stacking order |
| **Visibility Control** | Show/hide individual nodes |

### Ports

| Capability | Description |
|------------|-------------|
| **Custom Port Widgets** | Full control over port appearance |
| **Port Positions** | Left, right, top, bottom with offset support |
| **Port Types** | Source, target, or bidirectional |
| **Multi-connection** | Configure ports for single or multiple connections |
| **Highlighting** | Visual feedback during connection creation |
| **Labels** | Optional port labels with theming |

### Connections

| Capability | Description |
|------------|-------------|
| **Interactive Creation** | Drag from port to create connections |
| **Connection Styles** | Bezier, smoothstep, step, or straight lines |
| **Arrows & Endpoints** | Configurable start/end markers |
| **Labels** | Start, center, and end labels on connections |
| **Dashed Lines** | Custom dash patterns |
| **Selection** | Click to select connections |
| **Validation** | Hook into connection creation for validation |
| **Control Points** | Manual routing with user-defined waypoints |

### Annotations

| Capability | Description |
|------------|-------------|
| **Sticky Notes** | Resizable text notes anywhere on canvas |
| **Groups** | Visual containers around related nodes |
| **Markers** | Icon-based indicators for status/semantics |
| **Node-following** | Annotations that move with their linked nodes |
| **Selection & Editing** | Select, move, resize annotations |

### Interaction

| Capability | Description |
|------------|-------------|
| **Keyboard Shortcuts** | Delete, select all, escape, arrow keys, and more |
| **Context Menus** | Right-click menus for nodes, connections, canvas |
| **Auto-Pan** | Canvas scrolls when dragging near edges |
| **Cursor Feedback** | Dynamic cursors based on interaction state |
| **Hit Testing** | Accurate click detection for overlapping elements |

### Alignment & Distribution

| Capability | Description |
|------------|-------------|
| **Align Left/Right/Top/Bottom** | Align selected nodes to edges |
| **Center Horizontal/Vertical** | Center-align selected nodes |
| **Distribute Evenly** | Space nodes evenly horizontally or vertically |
| **Snap to Grid** | Optional grid snapping while dragging |

### Serialization

| Capability | Description |
|------------|-------------|
| **Export Graph** | Serialize entire graph to JSON |
| **Import Graph** | Load graph from JSON |
| **Custom Data** | Full support for your custom node data types |
| **Annotations Included** | Annotations serialize with the graph |

### Theming

| Capability | Description |
|------------|-------------|
| **Light & Dark Themes** | Built-in presets |
| **Node Theme** | Colors, borders, shadows, selection styling |
| **Connection Theme** | Stroke, color, endpoints, dash patterns |
| **Port Theme** | Size, colors, borders, highlighting |
| **Annotation Theme** | Selection styling, borders |
| **Label Theme** | Font, colors, backgrounds |
| **Grid Theme** | Colors, spacing, line styles |

::: info
All these capabilities work together seamlessly. For example, when you drag a node, connected edges update in real-time, annotations follow if linked, and the minimap updates accordingly.

:::

## Constructor

```dart
NodeFlowEditor<T, dynamic>({
  Key? key,
  required NodeFlowController<T, dynamic> controller,
  required Widget Function(BuildContext, Node<T>) nodeBuilder,
  required NodeFlowTheme theme,
  NodeShape? Function(BuildContext, Node<T>)? nodeShapeBuilder,
  PortBuilder<T>? portBuilder,
  LabelBuilder? labelBuilder,
  ConnectionStyleOverrides? Function(Connection)? connectionStyleResolver,
  NodeFlowEvents<T, dynamic>? events,
  NodeFlowBehavior behavior = NodeFlowBehavior.design,
  bool scrollToZoom = true,
  bool showAnnotations = true,
})
```

## Required Parameters

### controller

```dart
required NodeFlowController<T, dynamic> controller
```

The controller that manages the graph state. Create it in your widget's state:

```dart
late final NodeFlowController<MyData, dynamic> controller;

@override
void initState() {
  super.initState();
  controller = NodeFlowController<MyData, dynamic>(
    config: NodeFlowConfig(
      snapToGrid: true,
      gridSize: 20.0,
    ),
  );
}

@override
void dispose() {
  controller.dispose();
  super.dispose();
}
```

### nodeBuilder

```dart
required Widget Function(BuildContext, Node<T>) nodeBuilder
```

A function that builds the widget for each node. This is where you customize how nodes appear:

```dart
nodeBuilder: (context, node) {
  return Container(
    padding: EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(8),
      border: Border.all(color: Colors.blue),
    ),
    child: Text(node.data.label),
  );
}
```

### theme

```dart
required NodeFlowTheme theme
```

The visual theme for the editor. This is required and controls all styling:

```dart
theme: NodeFlowTheme.light
// or
theme: NodeFlowTheme.dark
// or custom theme
theme: NodeFlowTheme(
  nodeTheme: NodeTheme(...),
  connectionTheme: ConnectionTheme(...),
  portTheme: PortTheme(...),
  backgroundColor: Colors.grey[50]!,
)
```

## Optional Parameters

### nodeShapeBuilder

```dart
NodeShape? Function(BuildContext, Node<T>)? nodeShapeBuilder
```

Determines the visual shape for each node. Return `null` for rectangular nodes.

```dart
nodeShapeBuilder: (context, node) {
  switch (node.type) {
    case 'Terminal':
      return CircleShape(
        fillColor: Colors.green,
        strokeColor: Colors.darkGreen,
        strokeWidth: 2.0,
      );
    case 'Decision':
      return DiamondShape(
        fillColor: Colors.yellow,
        strokeColor: Colors.black,
      );
    default:
      return null; // Rectangular node
  }
}
```

::: details 🖼️ Node Shapes Comparison
Side-by-side comparison showing different node shapes: rectangular (default), circle, diamond, and hexagon nodes with ports
:::

### portBuilder

```dart
PortBuilder<T>? portBuilder
```

Customize individual port widgets based on port data:

```dart
portBuilder: (context, node, port, isOutput, isConnected) {
  // Color ports based on data type
  final color = port.name.contains('error')
      ? Colors.red
      : null; // Use theme default

  return PortWidget(
    port: port,
    theme: Theme.of(context).extension<NodeFlowTheme>()!.portTheme,
    isConnected: isConnected,
    color: color,
  );
}
```

### labelBuilder

```dart
LabelBuilder? labelBuilder
```

Customize connection label appearance:

```dart
labelBuilder: (context, connection, label, position) {
  return Positioned(
    left: position.left,
    top: position.top,
    child: Container(
      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: connection.data?['priority'] == 'high'
            ? Colors.orange.shade100
            : Colors.white,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(label.text),
    ),
  );
}
```

### connectionStyleResolver

```dart
ConnectionStyleOverrides? Function(Connection)? connectionStyleResolver
```

Override connection styles per-connection:

```dart
connectionStyleResolver: (connection) {
  if (connection.data?['type'] == 'error') {
    return ConnectionStyleOverrides(
      color: Colors.red,
      selectedColor: Colors.red.shade700,
      strokeWidth: 3.0,
    );
  }
  return null; // Use theme defaults
}
```

### events

```dart
NodeFlowEvents<T, dynamic>? events
```

Comprehensive event handling for all editor interactions. See [Event System](/docs/advanced/events) for complete documentation.

::: code-group

```dart [Node Events]
events: NodeFlowEvents(
  node: NodeEvents(
    onTap: (node) => print('Tapped: ${node.id}'),
    onDoubleTap: (node) => _editNode(node),
    onSelected: (node) => setState(() => _selected = node),
    onDragStop: (node) => _savePosition(node),
    onContextMenu: (node, pos) => _showMenu(node, pos),
  ),
)
```

```dart [Connection Events]
events: NodeFlowEvents(
  connection: ConnectionEvents(
    onCreated: (conn) => print('Connected: ${conn.id}'),
    onDeleted: (conn) => print('Disconnected: ${conn.id}'),
    onBeforeComplete: (context) => _validateConnection(context),
  ),
)
```

```dart [Viewport Events]
events: NodeFlowEvents(
  viewport: ViewportEvents(
    onCanvasTap: (pos) => _addNodeAt(pos),
    onCanvasContextMenu: (pos) => _showCanvasMenu(pos),
    onMove: (viewport) => _updateMinimap(viewport),
  ),
)
```

:::

### behavior

```dart
NodeFlowBehavior behavior = NodeFlowBehavior.design
```

Controls what interactions are allowed. See [Behavior Modes](#behavior-modes) below.

| Mode | Description |
|------|-------------|
| `NodeFlowBehavior.design` | Full editing - create, modify, delete, drag, select, pan, zoom (default) |
| `NodeFlowBehavior.preview` | Navigate and rearrange - drag, select, pan, zoom but no structural changes |
| `NodeFlowBehavior.present` | Display only - no interaction at all |

### scrollToZoom

```dart
bool scrollToZoom = true
```

When `true`, trackpad scroll gestures zoom the canvas. When `false`, scroll pans the canvas instead.

### showAnnotations

```dart
bool showAnnotations = true
```

Whether to display annotations (sticky notes, markers, groups). When `false`, annotations remain in the graph data but are not rendered.

## Behavior Modes

The `NodeFlowBehavior` enum controls what interactions are allowed:

```dart
// Full editing mode (default)
NodeFlowEditor(
  behavior: NodeFlowBehavior.design,
  // ...
)

// Preview mode - rearrange but no structural changes
NodeFlowEditor(
  behavior: NodeFlowBehavior.preview,
  // ...
)

// Presentation mode - display only
NodeFlowEditor(
  behavior: NodeFlowBehavior.present,
  // ...
)
```

Each behavior mode has specific capabilities:

| Capability | design | preview | present |
|------------|:------:|:-------:|:-------:|
| `canCreate` | Yes | No | No |
| `canUpdate` | Yes | No | No |
| `canDelete` | Yes | No | No |
| `canDrag` | Yes | Yes | No |
| `canSelect` | Yes | Yes | No |
| `canPan` | Yes | Yes | No |
| `canZoom` | Yes | Yes | No |

You can check capabilities programmatically using the behavior enum:

```dart
const behavior = NodeFlowBehavior.design;

if (behavior.canDelete) {
  // Allow deletion
}

if (behavior.canModify) {
  // Any CRUD operation allowed (create, update, or delete)
}

if (behavior.isInteractive) {
  // Any interaction allowed (drag, select, pan, or zoom)
}
```

## Complete Example

```dart
class MyFlowEditor extends StatefulWidget {
  @override
  State<MyFlowEditor> createState() => _MyFlowEditorState();
}

class _MyFlowEditorState extends State<MyFlowEditor> {
  late final NodeFlowController<MyNodeData, dynamic> _controller;
  Node<MyNodeData>? _selectedNode;

  @override
  void initState() {
    super.initState();
    _controller = NodeFlowController<MyNodeData, dynamic>(
      config: NodeFlowConfig(
        snapToGrid: true,
        gridSize: 20.0,
      ),
    );
    _initializeGraph();
  }

  void _initializeGraph() {
    final node1 = Node<MyNodeData>(
      id: 'node-1',
      type: 'start',
      position: Offset(100, 100),
      size: Size(150, 80),
      data: MyNodeData(label: 'Start'),
      outputPorts: [
        Port(id: 'node-1-out', name: 'Output'),
      ],
    );
    _controller.addNode(node1);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Node Flow Editor'),
        actions: [
          IconButton(icon: Icon(Icons.add), onPressed: _addNode),
          if (_selectedNode != null)
            IconButton(icon: Icon(Icons.delete), onPressed: _deleteSelectedNode),
        ],
      ),
      body: Row(
        children: [
          Expanded(
            flex: 3,
            child: NodeFlowEditor<MyNodeData, dynamic>(
              controller: _controller,
              theme: NodeFlowTheme.light,
              behavior: NodeFlowBehavior.design,
              scrollToZoom: true,
              showAnnotations: true,
              nodeBuilder: (context, node) => _buildNode(node),
              nodeShapeBuilder: (context, node) {
                if (node.type == 'start') {
                  return CircleShape(fillColor: Colors.green);
                }
                return null;
              },
              events: NodeFlowEvents(
                node: NodeEvents(
                  onSelected: (node) => setState(() => _selectedNode = node),
                  onDoubleTap: (node) => _editNode(node),
                  onContextMenu: (node, pos) => _showNodeMenu(node, pos),
                ),
                connection: ConnectionEvents(
                  onCreated: (conn) => _showSnackBar('Connection created'),
                  onDeleted: (conn) => _showSnackBar('Connection deleted'),
                ),
                viewport: ViewportEvents(
                  onCanvasTap: (pos) => _controller.clearSelection(),
                ),
                onInit: () => _controller.fitToView(),
              ),
            ),
          ),
          if (_selectedNode != null)
            SizedBox(
              width: 300,
              child: _buildPropertiesPanel(),
            ),
        ],
      ),
    );
  }

  Widget _buildNode(Node<MyNodeData> node) {
    return Container(
      padding: EdgeInsets.all(12),
      child: Text(
        node.data.label,
        style: TextStyle(fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildPropertiesPanel() {
    return Container(
      color: Colors.grey[100],
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Properties', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          SizedBox(height: 16),
          Text('Node ID: ${_selectedNode!.id}'),
          Text('Type: ${_selectedNode!.type}'),
          SizedBox(height: 16),
          ElevatedButton(onPressed: _deleteSelectedNode, child: Text('Delete')),
        ],
      ),
    );
  }

  void _addNode() {
    final node = Node<MyNodeData>(
      id: 'node-${DateTime.now().millisecondsSinceEpoch}',
      type: 'process',
      position: Offset(200, 200),
      size: Size(150, 80),
      data: MyNodeData(label: 'New Node'),
      inputPorts: [Port(id: 'in-${DateTime.now().millisecondsSinceEpoch}', name: 'Input')],
      outputPorts: [Port(id: 'out-${DateTime.now().millisecondsSinceEpoch}', name: 'Output')],
    );
    _controller.addNode(node);
  }

  void _deleteSelectedNode() {
    if (_selectedNode != null) {
      _controller.removeNode(_selectedNode!.id);
      setState(() => _selectedNode = null);
    }
  }

  void _editNode(Node<MyNodeData> node) { /* Show edit dialog */ }
  void _showNodeMenu(Node<MyNodeData> node, ScreenPosition pos) { /* Show context menu */ }
  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}
```

## Keyboard Shortcuts

The editor includes built-in keyboard shortcuts:

- **Delete / Backspace**: Delete selected nodes
- **Ctrl+A / Cmd+A**: Select all nodes
- **Escape**: Clear selection
- **Arrow keys**: Move selected nodes
- **F**: Fit all nodes to view
- **?**: Show shortcuts dialog

See [Keyboard Shortcuts](/docs/advanced/keyboard-shortcuts) for the complete list and customization options.

## Best Practices

1. **Dispose Controller**: Always dispose the controller in your widget's dispose method
2. **Responsive Layout**: Use `LayoutBuilder` to make the editor responsive
3. **Loading State**: Show a loading indicator while initializing the graph
4. **Error Handling**: Wrap operations in try-catch blocks
5. **Performance**: Keep node widgets lightweight
6. **State Management**: Use controller APIs instead of directly modifying graph
7. **Behavior Modes**: Use `preview` mode for run/debug views, `present` for thumbnails

## See Also

- [NodeFlowViewer](/docs/components/node-flow-viewer) - Read-only view
- [NodeFlowMinimap](/docs/components/minimap) - Overview minimap
- [Configuration](/docs/concepts/configuration) - NodeFlowConfig and AutoPanConfig
- [Theming](/docs/theming/overview) - Customization guide
