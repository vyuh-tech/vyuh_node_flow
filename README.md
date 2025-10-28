# Vyuh Node Flow

![Vyuh Node Flow Banner](https://github.com/vyuh-tech/vyuh_node_flow/raw/main/assets/node-flow-banner.png)

A flexible, high-performance node-based flow editor for Flutter applications, inspired by React
Flow. Build visual programming interfaces, workflow editors, interactive diagrams, and data
pipelines with ease.

<p align="center">
  <a href="https://pub.dev/packages/vyuh_node_flow">
    <img src="https://img.shields.io/pub/v/vyuh_node_flow?style=for-the-badge&logo=dart&logoColor=white&color=0175C2" alt="Pub Version">
  </a>
  <a href="https://opensource.org/licenses/MIT">
    <img src="https://img.shields.io/badge/License-MIT-yellow?style=for-the-badge" alt="License">
  </a>
</p>

## Try the Demo

**[👉 Launch Demo](https://flow.demo.vyuh.tech)**

Experience Vyuh Node Flow in action! The live demo showcases all key features, including node
creation, drag-and-drop connections, custom theming, annotations, minimap, and more.

---

## ✨ Key Features

- **High Performance** - Reactive, optimized rendering for smooth interactions
- **Fully Customizable** - Comprehensive theming system for nodes, connections, and ports
- **Flexible Ports** - Multiple port shapes, positions, and connection validation
- **Annotations** - Add labels, notes, and custom overlays to your flow
- **Minimap** - Built-in minimap for navigation in complex flows
- **Keyboard Shortcuts** - Full keyboard support for power users
- **Connection Styles** - Multiple connection path styles (bezier, smoothstep, straight)
- **Read-Only Viewer** - Display flows without editing capabilities
- **Serialization** - Save and load flows from JSON

## Screenshots

<div align="center">
  <img src="https://github.com/vyuh-tech/vyuh_node_flow/raw/main/assets/image-1.png" alt="Node Flow Editor Screenshot 1" width="800"/>
  <br/>
  <br/>
  <img src="https://github.com/vyuh-tech/vyuh_node_flow/raw/main/assets/image-2.png" alt="Node Flow Editor Screenshot 2" width="800"/>
</div>

## Installation

Add to your `pubspec.yaml`:

```yaml
dependencies:
  vyuh_node_flow: ^0.1.0
```

Then run:

```bash
flutter pub get
```

## 🚀 Quick Start

Here's a minimal example to get you started:

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
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
      child: Text(node.data),
    );
  }
}
```

---

## Core Concepts

### The Controller

The `NodeFlowController` is the central piece that manages all state:

```dart

final controller = NodeFlowController<T>(
  config: NodeFlowConfig(
    snapToGrid: true,
    gridSize: 20.0,
    minZoom: 0.5,
    maxZoom: 2.0,
  ),
  initialViewport: GraphViewport(x: 0, y: 0, zoom: 1.0),
);
```

> [!TIP]
> The type parameter `<T>` represents the data type stored in each node. We recommend using a *
*sealed class hierarchy** with multiple subclasses to create a strongly-typed collection of node
> types that work together. This provides excellent type safety and pattern matching capabilities.

<details>
<summary><strong>Controller API Reference</strong></summary>

#### Managing Nodes

```dart
// Add a node
controller.addNode
(
node);

// Remove a node
controller.removeNode(nodeId);

// Get a node
final node = controller.getNode(nodeId);

// Set node position
controller.setNodePosition(nodeId, newPosition);

// Select nodes
controller.selectNode(nodeId);
controller.selectNodes([nodeId1, nodeId2]);
controller.clearSelection();
```

#### Managing Connections

```dart
// Add a connection
controller.addConnection
(
connection);

// Remove a connection
controller.removeConnection(connectionId);

// Get connections for a node
final connections
=
controller
.
getConnectionsForNode
(
nodeId
);
```

#### Viewport Control

```dart
// Pan and zoom
controller.setViewport
(
GraphViewport(x: 100, y: 100, zoom: 1.5));
controller.zoomBy(0.1); // Zoom in
controller.zoomBy(-0.1); // Zoom out
controller.zoomTo(1.5); // Set specific zoom level
controller.fitToView(); // Fit all nodes in view
controller.centerOnNode(nodeId); // Center on specific node
```

#### Graph Operations

```dart
// Load/save graph
final graph = controller.exportGraph();
controller.loadGraph
(
graph
);

// Clear everything
controller
.
clearGraph
(
);
```

</details>

---

## Theming

### Using Built-in Themes

```dart
// Light theme
controller.setTheme
(
NodeFlowTheme.light);

// Dark theme
controller.setTheme(NodeFlowTheme.dark
);
```

### Creating Custom Themes

<details>
<summary><strong>Complete Custom Theme Example</strong></summary>

```dart

final customTheme = NodeFlowTheme(
  // Node appearance
  nodeTheme: NodeTheme(
    backgroundColor: Colors.white,
    selectedBackgroundColor: Colors.blue.shade50,
    borderColor: Colors.grey.shade300,
    selectedBorderColor: Colors.blue,
    borderWidth: 1.0,
    selectedBorderWidth: 2.0,
    borderRadius: BorderRadius.circular(8.0),
    padding: const EdgeInsets.all(16.0),
    titleStyle: TextStyle(
      fontSize: 14,
      fontWeight: FontWeight.bold,
      color: Colors.black87,
    ),
    contentStyle: TextStyle(
      fontSize: 12,
      color: Colors.grey.shade700,
    ),
  ),

  // Connection appearance
  connectionStyle: ConnectionStyles.smoothstep,
  connectionTheme: ConnectionTheme(
    color: Colors.blue.shade300,
    selectedColor: Colors.blue.shade700,
    strokeWidth: 2.0,
    selectedStrokeWidth: 3.0,
    startPoint: ConnectionEndPoint.none,
    endPoint: ConnectionEndPoint.arrow,
  ),

  // Temporary connection (while dragging)
  temporaryConnectionTheme: ConnectionTheme(
    color: Colors.grey.shade400,
    strokeWidth: 2.0,
    dashPattern: [5, 5], // Dashed line
  ),

  // Port appearance
  portTheme: PortTheme(
    size: 10.0,
    color: Colors.blue.shade400,
    connectedColor: Colors.blue.shade700,
    hoverColor: Colors.blue.shade800,
    borderColor: Colors.white,
    borderWidth: 2.0,
  ),

  // Grid and canvas
  backgroundColor: Colors.grey.shade50,
  gridColor: Colors.grey.shade300,
  gridSize: 20.0,
  gridStyle: GridStyle.dots,

  // Selection appearance
  selectionColor: Colors.blue.withOpacity(0.2),
  selectionBorderColor: Colors.blue,
  selectionBorderWidth: 1.0,
);

controller.setTheme
(
customTheme
);
```

</details>

> [!NOTE]
> Grid styles available: `GridStyle.dots`, `GridStyle.lines`, `GridStyle.hierarchical`,
`GridStyle.none`

---

## Building Nodes

### Basic Node Widget

The simplest way to display nodes is using the default `NodeWidget`:

```dart
NodeFlowEditor<String>
(
controller: controller,
theme: theme,
nodeBuilder: (context, node) {
return NodeWidget.defaultStyle(node: node);
},
)
```

### Custom Node Content

Create custom node content while keeping standard node functionality:

<details>
<summary><strong>Custom Node Content Example</strong></summary>

```dart
Widget _buildNode(BuildContext context, Node<Map<String, dynamic>> node) {
  final data = node.data;

  return Container(
    padding: const EdgeInsets.all(12),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Title
        Text(
          data['title'] ?? node.type,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),

        // Icon
        if (data['icon'] != null)
          Icon(data['icon'], size: 24, color: Colors.blue),

        // Description
        if (data['description'] != null)
          Text(
            data['description'],
            style: TextStyle(
              fontSize: 11,
              color: Colors.grey.shade600,
            ),
          ),
      ],
    ),
  );
}
```

</details>

### Using Node Container Builder

For complete control over node appearance:

<details>
<summary><strong>Custom Node Container Example</strong></summary>

```dart
NodeFlowEditor<MyData>
(
controller: controller,
theme: theme,
nodeBuilder: (context, node) => _buildNodeContent(node),
nodeContainerBuilder: (context, node, content) {
// Return NodeWidget with custom styling
return NodeWidget<MyData>(
node: node,
child: content,
backgroundColor: _getNodeColor(node),
borderColor: node.isSelected ? Colors.blue : Colors.grey,
borderWidth: node.isSelected ? 3.0 : 1.0,
borderRadius: BorderRadius.circular(12),
);
},
)
```

</details>

### Node Types and Data

Create strongly-typed nodes using sealed classes for type safety and pattern matching:

<details>
<summary><strong>Sealed Class Node Data Example (Recommended)</strong></summary>

```dart
// Define a sealed class hierarchy for all node types
sealed class NodeData {
  const NodeData();
}

class SourceNodeData extends NodeData {
  final String dataSource;
  final String format;

  const SourceNodeData({
    required this.dataSource,
    required this.format,
  });
}

class ProcessNodeData extends NodeData {
  final String title;
  final String processType;
  final IconData icon;
  final Color color;

  const ProcessNodeData({
    required this.title,
    required this.processType,
    required this.icon,
    required this.color,
  });
}

class SinkNodeData extends NodeData {
  final String destination;
  final bool isActive;

  const SinkNodeData({
    required this.destination,
    required this.isActive,
  });
}

// Create nodes with typed data
final node = Node<NodeData>(
  id: 'process-1',
  type: 'process',
  position: const Offset(100, 100),
  data: ProcessNodeData(
    title: 'Data Validation',
    processType: 'validation',
    icon: Icons.check_circle,
    color: Colors.green,
  ),
  inputPorts: [Port(id: 'in', name: 'Input')],
  outputPorts: [Port(id: 'out', name: 'Output')],
);

// Use pattern matching in node builder
Widget _buildNode(BuildContext context, Node<NodeData> node) {
  return switch (node.data) {
    SourceNodeData(dataSource: final source, format: final format) =>
        _buildSourceNode(source, format),

    ProcessNodeData(:final title, :final icon, :final color) =>
        Container(
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            border: Border.all(color: color),
            borderRadius: BorderRadius.circular(8),
          ),
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Icon(icon, color: color),
              const SizedBox(height: 8),
              Text(title, style: TextStyle(fontWeight: FontWeight.bold)),
            ],
          ),
        ),

    SinkNodeData(:final destination, :final isActive) =>
        _buildSinkNode(destination, isActive),
  };
}
```

</details>

<details>
<summary><strong>Simple Class Node Data Example</strong></summary>

For simpler use cases, you can use a single class:

```dart
class ProcessNodeData {
  final String title;
  final String processType;
  final IconData icon;
  final Color color;

  ProcessNodeData({
    required this.title,
    required this.processType,
    required this.icon,
    required this.color,
  });
}

// Create nodes with typed data
final node = Node<ProcessNodeData>(
  id: 'process-1',
  type: 'process',
  position: const Offset(100, 100),
  data: ProcessNodeData(
    title: 'Data Validation',
    processType: 'validation',
    icon: Icons.check_circle,
    color: Colors.green,
  ),
  inputPorts: [Port(id: 'in', name: 'Input')],
  outputPorts: [Port(id: 'out', name: 'Output')],
);

// Use in node builder
Widget _buildProcessNode(BuildContext context, Node<ProcessNodeData> node) {
  final data = node.data;

  return Container(
    decoration: BoxDecoration(
      color: data.color.withOpacity(0.1),
      border: Border.all(color: data.color),
      borderRadius: BorderRadius.circular(8),
    ),
    padding: const EdgeInsets.all(16),
    child: Column(
      children: [
        Icon(data.icon, color: data.color),
        const SizedBox(height: 8),
        Text(data.title, style: TextStyle(fontWeight: FontWeight.bold)),
        Text(data.processType, style: TextStyle(fontSize: 10)),
      ],
    ),
  );
}
```

</details>

---

## Working with Ports

### Port Basics

Ports are connection points on nodes:

```dart
// Input port (left side)
const Port
(
id: 'input-1',
name: 'Input',
position: PortPosition.left,
type: PortType.target, // Can only receive connections
)

// Output port (right side)
const Port(
id: 'output-1',
name: 'Output',
position: PortPosition.right,
type: PortType.source, // Can only create connections
)

// Bidirectional port
const Port(
id: 'bidirectional',
name: 'Data',
type: PortType.
both
, // Can both send and receive
)
```

### Port Positions and Offsets

<details>
<summary><strong>Port Positioning Examples</strong></summary>

```dart
// Left-side ports with vertical offsets
inputPorts: [
Port
(
id: 'in-1',
name: 'Input 1',
position: PortPosition.left,
offset: Offset(0, 20), // 20px from top
),
Port(
id: 'in-2',
name: 'Input 2',
position: PortPosition.left,
offset: Offset(0, 60), // 60px from top
),
]

// Top-side ports with horizontal offsets
inputPorts: [
Port(
id: 'in-1',
name: 'Input 1',
position: PortPosition.top,
offset: Offset(40, 0), // 40px from left
),
Port(
id: 'in-2',
name: 'Input 2',
position: PortPosition.top,
offset: Offset(120, 0
)
, // 120px from left
)
,
]
```

</details>

### Port Shapes

```dart
const Port
(
id: 'port-1',
name: 'Data',
shape
:
PortShape
.
capsuleHalf
, // Default, oriented shape
)

// Available shapes:
// - PortShape.capsuleHalf (recommended, auto-oriented)
// - PortShape.circle
// - PortShape.square
// - PortShape.diamond
// - PortShape.triangle
```

### Multiple Connections

<details>
<summary><strong>Multi-Connection Port Example</strong></summary>

```dart
// Allow unlimited connections
const Port
(
id: 'output',
name: 'Broadcast',
multiConnections: true,
)

// Limit to specific number
const Port(
id: 'output',
name: 'Limited',
multiConnections: true,
maxConnections: 3,
)
```

</details>

### Dynamic Ports

Add or remove ports at runtime:

<details>
<summary><strong>Dynamic Port Management</strong></summary>

```dart
// Add a port
node.addOutputPort
(
Port(
id: 'new-output',
name: 'New Output',
position: PortPosition.right,
));

// Remove a port
node.removePort('port-id');

// Update a port
node.updatePort('port-id', Port(
id: 'port-id',
name: 'Updated Name',
position: PortPosition.right,
));

// Find a port
final port = node.findPort('port-id
'
);
```

</details>

---

## Connections

### Creating Connections

Users create connections by dragging from one port to another. You can also create them
programmatically:

```dart

final connection = Connection(
  id: 'conn-1',
  sourceNodeId: 'node-1',
  sourcePortId: 'output',
  targetNodeId: 'node-2',
  targetPortId: 'input',
);

controller.addConnection
(
connection
);
```

### Connection Validation

Validate connections before they're created:

<details>
<summary><strong>Connection Validation Example</strong></summary>

```dart
NodeFlowEditor<MyData>
(
controller: controller,
theme: theme,
nodeBuilder: _buildNode,

// Validate when starting a connection
onBeforeStartConnection: (context) {
// Don't allow connections from disabled nodes
if (context.sourceNode.data.isDisabled) {
return ConnectionValidationResult.invalid(
reason: 'Cannot connect from disabled node',
);
}
return ConnectionValidationResult.valid();
},

// Validate when completing a connection
onBeforeCompleteConnection: (context) {
// Don't allow self-connections
if (context.sourceNode.id == context.targetNode.id) {
return ConnectionValidationResult.invalid(
reason: 'Cannot connect node to itself',
);
}

// Check for circular dependencies
if (_wouldCreateCycle(context)) {
return ConnectionValidationResult.invalid(
reason: 'Would create circular dependency',
);
}

// Check port compatibility
if (!_arePortsCompatible(context.sourcePort, context.targetPort)) {
return ConnectionValidationResult.invalid(
reason: 'Incompatible port types',
);
}

return ConnectionValidationResult.valid();
},
)
```

</details>

### Connection Styles

Choose from multiple connection path styles:

```dart
// Smooth step (default, clean right-angle paths)
connectionStyle: ConnectionStyles.smoothstep

// Bezier curves (smooth, flowing curves)
connectionStyle: ConnectionStyles.bezier

// Straight lines (direct connections)
connectionStyle: ConnectionStyles.straight

// Step lines (right-angle paths)
connectionStyle: ConnectionStyles.step
```

### Connection Endpoints

Customize connection line endpoints:

<details>
<summary><strong>Connection Endpoint Styles</strong></summary>

```dart
connectionTheme: ConnectionTheme
(
// Start endpoint (source port)
startPoint: ConnectionEndPoint.none,

// End endpoint (target port)
endPoint: ConnectionEndPoint.arrow,

// Other endpoint options:
// - ConnectionEndPoint.none
// - ConnectionEndPoint.arrow
// - ConnectionEndPoint.circle
// - ConnectionEndPoint.capsuleHalf (matches port shape)
)
```

</details>

### Connection Labels

Add labels to connections:

<details>
<summary><strong>Connection Label Example</strong></summary>

```dart

final connection = Connection(
  id: 'conn-1',
  sourceNodeId: 'node-1',
  sourcePortId: 'output',
  targetNodeId: 'node-2',
  targetPortId: 'input',
  label: 'Data Flow', // Add label
);

// Customize label appearance in theme
labelTheme: LabelTheme
(
color: Colors.black87,
fontSize: 11.0,
fontWeight: FontWeight.w500,
backgroundColor: Colors.white,
borderColor: Colors.grey.shade300,
borderWidth: 1.0,
horizontalOffset: 8.0,
verticalOffset: 8.0,
)
```

</details>

---

## Annotations

Annotations are floating elements that can be placed on the canvas for labels, notes, or custom
visualizations.

### Built-in Annotation Types

<details>
<summary><strong>Sticky Note Annotation Example</strong></summary>

```dart
// Add a sticky note annotation
controller.addAnnotation
(
StickyAnnotation(
id: 'note-1',
position: const Offset(100, 100),
text: 'This is a note',
width: 200,
height: 100,
color: Colors.yellow.shade100,
),
);

// Or use the convenience method
controller.createStickyNote(
position: const Offset(100, 100),
text: 'This is a note
'
,
);
```

</details>

### Custom Annotations

Create your own annotation types:

<details>
<summary><strong>Custom Annotation Implementation</strong></summary>

```dart
class ImageAnnotation extends Annotation {
  final String imageUrl;
  final double width;
  final double height;

  ImageAnnotation({
    required super.id,
    required Offset position,
    required this.imageUrl,
    this.width = 200,
    this.height = 150,
  }) : super(
    type: 'image',
    initialPosition: position,
  );

  @override
  Size get size => Size(width, height);

  @override
  Widget buildWidget(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Image.network(imageUrl, fit: BoxFit.cover),
      ),
    );
  }

  @override
  Map<String, dynamic> toJson() =>
      {
        'imageUrl': imageUrl,
        'width': width,
        'height': height,
      };

  @override
  void fromJson(Map<String, dynamic> json) {
    // Update from JSON if needed
  }
}

// Use the custom annotation
controller.addAnnotation
(
ImageAnnotation(
id: 'img-1',
position: const Offset(200, 200),
imageUrl: 'https://example.com/image.jpg
'
,
)
,
);
```

</details>

### Following Nodes

Make annotations follow nodes automatically:

<details>
<summary><strong>Node-Following Annotation</strong></summary>

```dart

final annotation = StickyAnnotation(
  id: 'label-1',
  position: const Offset(100, 100),
  text: 'Important Node',
  // This annotation will follow 'node-1'
  dependencies: {'node-1'},
  // Offset relative to the node
  offset: const Offset(0, -50), // 50px above the node
);

controller.addAnnotation
(
annotation
);
```

</details>

---

## Interactive Features

### Editor Callbacks

<details>
<summary><strong>All Available Callbacks</strong></summary>

```dart
NodeFlowEditor<MyData>
(
controller: controller,
theme: theme,
nodeBuilder: _buildNode,

// Node events
onNodeSelected: (node) {
print('Node selected: ${node?.id}');
},
onNodeTap: (node) {
print('Node tapped: ${node.id}');
},
onNodeDoubleTap: (node) {
print('Node double-tapped: ${node.id}');
_showNodeEditor(node);
},
onNodeCreated: (node) {
print('Node created: ${node.id}');
},
onNodeDeleted: (node) {
print('Node deleted: ${node.id}');
},

// Connection events
onConnectionSelected: (connection) {
print('Connection selected: ${connection?.id}');
},
onConnectionTap: (connection) {
print('Connection tapped: ${connection.id}');
},
onConnectionDoubleTap: (connection) {
print('Connection double-tapped: ${connection.id}');
},
onConnectionCreated: (connection) {
print('Connection created: ${connection.id}');
_notifyConnectionChange();
},
onConnectionDeleted: (connection) {
print('Connection deleted: ${connection.id}');
},

// Annotation events
onAnnotationSelected: (annotation) {
print('Annotation selected: ${annotation?.id}');
},
onAnnotationTap: (annotation) {
print('Annotation tapped: ${annotation.id}');
},
onAnnotationCreated: (annotation) {
print('Annotation created: ${annotation.id}');
},
onAnnotationDeleted: (annotation) {
print('Annotation deleted: ${annotation.id}');
},
)
```

</details>

### Keyboard Shortcuts

Built-in keyboard shortcuts are available:

| Shortcut               | Action                            |
|------------------------|-----------------------------------|
| `Delete` / `Backspace` | Delete selected nodes/connections |
| `Cmd/Ctrl + A`         | Select all nodes                  |
| `Cmd/Ctrl + C`         | Copy selected nodes               |
| `Cmd/Ctrl + V`         | Paste nodes                       |
| `Cmd/Ctrl + D`         | Duplicate selected nodes          |
| `Cmd/Ctrl + Z`         | Undo                              |
| `Cmd/Ctrl + Shift + Z` | Redo                              |
| `Space + Drag`         | Pan canvas                        |
| `+` / `-`              | Zoom in/out                       |
| `0`                    | Reset zoom to 100%                |
| `F`                    | Fit view to all nodes             |

<details>
<summary><strong>Custom Keyboard Shortcuts</strong></summary>

```dart
// Register custom actions
controller.shortcuts.registerAction
(
NodeFlowAction(
id: 'custom-action',
label: 'Custom Action',
shortcut: SingleActivator(
LogicalKeyboardKey.keyK,
control: true,
),
execute: (controller) {
// Your custom logic
print('Custom action executed!');
},
),
);

// Show shortcuts dialog
controller.showShortcutsDialog(context);
```

</details>

### Feature Toggles

Control which interactions are enabled:

```dart
NodeFlowEditor<T>
(
controller: controller,
theme: theme,
nodeBuilder: _buildNode,

enablePanning: true, // Pan with space+drag or right-click
enableZooming: true, // Zoom with mouse wheel
enableSelection: true, // Select nodes and connections
enableNodeDragging: true, // Drag nodes to reposition
enableConnectionCreation: true, // Create connections by dragging
scrollToZoom: true, // Zoom with trackpad scroll
showAnnotations: true, // Display annotation layer
)
```

---

## Minimap

Enable the built-in minimap for easier navigation in large graphs:

```dart
// Configure minimap in the controller
final controller = NodeFlowController<T>(
  config: NodeFlowConfig(
    showMinimap: true, // Enable minimap
    isMinimapInteractive: true, // Allow click-to-navigate
    minimapPosition: MinimapPosition.bottomRight, // Position on screen
    minimapSize: const Size(200, 150), // Minimap dimensions
  ),
);

// Use with editor - minimap appears automatically
NodeFlowEditor<T>
(
controller: controller,
theme: theme,
nodeBuilder: _buildNode,
)
```

You can also toggle the minimap at runtime:

```dart
// Toggle minimap visibility
controller.config.toggleMinimap
();

// Change minimap position
controller.config.setMinimapPosition
(
MinimapPosition
.
topLeft
);
```

> [!TIP]
> The minimap automatically updates as you pan, zoom, and modify the graph. Available positions:
`topLeft`, `topRight`, `bottomLeft`, `bottomRight`.

---

## Read-Only Viewer

Display flows without editing capabilities:

```dart
NodeFlowViewer<T>
(
controller: controller,
theme: theme,
nodeBuilder: _buildNode,
enablePanning: true,
enableZooming: true,
scrollToZoom:
true
,
)
```

The viewer supports panning and zooming but prevents editing, making it perfect for displaying
workflows, process diagrams, or results.

---

## Serialization

### Save and Load Graphs

<details>
<summary><strong>Complete Serialization Example</strong></summary>

```dart
// Export graph to JSON
final graph = controller.exportGraph();
final json = graph.toJson((data) => data.toJson());
final jsonString = jsonEncode(json);

// Save to file
await File
('my_flow.json
'
)
.writeAsString(jsonString);

// Load from file
final loadedJson = await File('my_flow.json').readAsString();
final decoded = jsonDecode(loadedJson);

// Import graph
final loadedGraph = NodeGraph.fromJson(
decoded,
(json) => MyData.fromJson(json),
);

controller.
loadGraph
(
loadedGraph
);
```

</details>

### Load from URL

```dart
// Load graph from a URL (web/assets)
final graph = await
NodeGraph.fromUrl<MyData>
('assets/workflows/my_flow.json
'
,
);

controller.
loadGraph
(
graph
);
```

---

## 🛠️ Advanced Configuration

### Grid Snapping

<details>
<summary><strong>Grid Configuration</strong></summary>

```dart

final config = NodeFlowConfig(
  snapToGrid: true, // Snap nodes to grid
  snapAnnotationsToGrid: true, // Snap annotations to grid
  gridSize: 20.0, // Grid cell size
  portSnapDistance: 15.0, // Distance for port snapping
);

// Toggle snapping at runtime
config.toggleSnapping
();config.toggleNodeSnapping
();config.toggleAnnotationSnapping
();
```

</details>

### Auto-Panning

<details>
<summary><strong>Auto-Pan Configuration</strong></summary>

```dart

final config = NodeFlowConfig(
  autoPanMargin: 50.0, // Pixels from edge to trigger auto-pan
  autoPanSpeed: 0.3, // Pan speed (0.0 to 1.0)
);
```

When dragging nodes or connections near the canvas edge, the viewport automatically pans.

</details>

### Zoom Limits

```dart

final config = NodeFlowConfig(
  minZoom: 0.25, // Minimum zoom level (25%)
  maxZoom: 3.0, // Maximum zoom level (300%)
);
```

---

## Complete Examples

### Example 1: Simple Data Pipeline

<details>
<summary><strong>View Code</strong></summary>

```dart
class DataPipelineEditor extends StatefulWidget {
  @override
  State<DataPipelineEditor> createState() => _DataPipelineEditorState();
}

class _DataPipelineEditorState extends State<DataPipelineEditor> {
  late final NodeFlowController<String> controller;

  @override
  void initState() {
    super.initState();
    controller = NodeFlowController<String>();
    controller.setTheme(NodeFlowTheme.light);
    _createPipeline();
  }

  void _createPipeline() {
    // Source node
    controller.addNode(Node<String>(
      id: 'source',
      type: 'source',
      position: const Offset(100, 200),
      data: 'Data Source',
      outputPorts: const [
        Port(id: 'out', name: 'Output', position: PortPosition.right),
      ],
    ));

    // Transform node
    controller.addNode(Node<String>(
      id: 'transform',
      type: 'transform',
      position: const Offset(350, 200),
      data: 'Transform',
      inputPorts: const [
        Port(id: 'in', name: 'Input', position: PortPosition.left),
      ],
      outputPorts: const [
        Port(id: 'out', name: 'Output', position: PortPosition.right),
      ],
    ));

    // Sink node
    controller.addNode(Node<String>(
      id: 'sink',
      type: 'sink',
      position: const Offset(600, 200),
      data: 'Data Sink',
      inputPorts: const [
        Port(id: 'in', name: 'Input', position: PortPosition.left),
      ],
    ));

    // Create connections
    controller.addConnection(Connection(
      id: 'c1',
      sourceNodeId: 'source',
      sourcePortId: 'out',
      targetNodeId: 'transform',
      targetPortId: 'in',
    ));

    controller.addConnection(Connection(
      id: 'c2',
      sourceNodeId: 'transform',
      sourcePortId: 'out',
      targetNodeId: 'sink',
      targetPortId: 'in',
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Data Pipeline')),
      body: NodeFlowEditor<String>(
        controller: controller,
        theme: NodeFlowTheme.light,
        nodeBuilder: _buildNode,
      ),
    );
  }

  Widget _buildNode(BuildContext context, Node<String> node) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(_getIcon(node.type), size: 24),
          const SizedBox(height: 8),
          Text(node.data, style: TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  IconData _getIcon(String type) {
    switch (type) {
      case 'source':
        return Icons.input;
      case 'transform':
        return Icons.transform;
      case 'sink':
        return Icons.output;
      default:
        return Icons.circle;
    }
  }
}
```

</details>

### Example 2: Workflow Builder with Validation

<details>
<summary><strong>View Code</strong></summary>

```dart
class WorkflowBuilder extends StatefulWidget {
  @override
  State<WorkflowBuilder> createState() => _WorkflowBuilderState();
}

class _WorkflowBuilderState extends State<WorkflowBuilder> {
  late final NodeFlowController<WorkflowNodeData> controller;

  @override
  void initState() {
    super.initState();
    controller = NodeFlowController<WorkflowNodeData>();
    controller.setTheme(_createWorkflowTheme());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Workflow Builder'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _showAddNodeDialog,
            tooltip: 'Add Node',
          ),
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _saveWorkflow,
            tooltip: 'Save',
          ),
        ],
      ),
      body: NodeFlowEditor<WorkflowNodeData>(
        controller: controller,
        theme: _createWorkflowTheme(),
        nodeBuilder: _buildWorkflowNode,

        // Prevent invalid connections
        onBeforeCompleteConnection: (context) {
          // Don't allow loops
          if (context.sourceNode.id == context.targetNode.id) {
            return ConnectionValidationResult.invalid(
              reason: 'Cannot connect to self',
            );
          }

          // Check for cycles
          if (_wouldCreateCycle(context)) {
            return ConnectionValidationResult.invalid(
              reason: 'Would create circular dependency',
            );
          }

          return ConnectionValidationResult.valid();
        },

        onConnectionCreated: (connection) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Connection created')),
          );
        },
      ),
    );
  }

  Widget _buildWorkflowNode(BuildContext context, Node<WorkflowNodeData> node) {
    final data = node.data;

    return Container(
      padding: const EdgeInsets.all(16),
      constraints: const BoxConstraints(minWidth: 150),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(data.icon, size: 20, color: data.color),
              const SizedBox(width: 8),
              Text(
                data.title,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ],
          ),
          if (data.description != null) ...[
            const SizedBox(height: 8),
            Text(
              data.description!,
              style: TextStyle(
                fontSize: 11,
                color: Colors.grey.shade600,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
    );
  }

  bool _wouldCreateCycle(ConnectionCompleteContext context) {
    // Implement cycle detection logic
    // This is a simplified version
    return false;
  }

  void _showAddNodeDialog() {
    // Show dialog to add new nodes
  }

  Future<void> _saveWorkflow() async {
    final graph = controller.exportGraph();
    // Save to file or database
  }

  NodeFlowTheme _createWorkflowTheme() {
    return NodeFlowTheme.light.copyWith(
      connectionStyle: ConnectionStyles.smoothstep,
      gridStyle: GridStyle.dots,
    );
  }
}

class WorkflowNodeData {
  final String title;
  final String? description;
  final IconData icon;
  final Color color;

  WorkflowNodeData({
    required this.title,
    this.description,
    required this.icon,
    required this.color,
  });
}
```

</details>

### Example 3: Read-Only Process Viewer

<details>
<summary><strong>View Code</strong></summary>

```dart
class ProcessViewer extends StatelessWidget {
  final String processJsonPath;

  const ProcessViewer({required this.processJsonPath});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<NodeGraph<String>>(
      future: NodeGraph.fromUrl(processJsonPath),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final controller = NodeFlowController<String>();
        controller.setTheme(NodeFlowTheme.light);
        controller.loadGraph(snapshot.data!);

        return Scaffold(
          appBar: AppBar(
            title: const Text('Process View'),
            actions: [
              IconButton(
                icon: const Icon(Icons.zoom_out),
                onPressed: () => controller.zoomBy(-0.1),
              ),
              IconButton(
                icon: const Icon(Icons.zoom_in),
                onPressed: () => controller.zoomBy(0.1),
              ),
              IconButton(
                icon: const Icon(Icons.fit_screen),
                onPressed: () => controller.fitToView(),
              ),
            ],
          ),
          body: Stack(
            children: [
              NodeFlowViewer<String>(
                controller: controller,
                theme: NodeFlowTheme.light,
                nodeBuilder: _buildNode,
              ),

              // Legend
              Positioned(
                top: 16,
                left: 16,
                child: _buildLegend(),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildNode(BuildContext context, Node<String> node) {
    return Container(
      padding: const EdgeInsets.all(12),
      child: Text(node.data),
    );
  }

  Widget _buildLegend() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('Legend', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          _legendItem(Colors.green, 'Start'),
          _legendItem(Colors.blue, 'Process'),
          _legendItem(Colors.orange, 'Decision'),
          _legendItem(Colors.red, 'End'),
        ],
      ),
    );
  }

  Widget _legendItem(Color color, String label) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Container(
            width: 16,
            height: 16,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(width: 8),
          Text(label, style: const TextStyle(fontSize: 12)),
        ],
      ),
    );
  }
}
```

</details>

---

## 🔍 API Reference

### NodeFlowController

| Method                                        | Description                     |
|-----------------------------------------------|---------------------------------|
| `addNode(Node node)`                          | Add a node to the graph         |
| `removeNode(String id)`                       | Remove a node by ID             |
| `getNode(String id)`                          | Get a node by ID                |
| `setNodePosition(String id, Offset position)` | Set node position               |
| `addConnection(Connection conn)`              | Add a connection                |
| `removeConnection(String id)`                 | Remove a connection             |
| `getConnectionsForNode(String id)`            | Get connections for a node      |
| `selectNode(String id)`                       | Select a node                   |
| `clearSelection()`                            | Clear all selections            |
| `setViewport(GraphViewport)`                  | Set viewport position and zoom  |
| `zoomBy(double delta)`                        | Adjust zoom by delta            |
| `zoomTo(double zoom)`                         | Set specific zoom level         |
| `fitToView()`                                 | Fit all nodes in view           |
| `centerOnNode(String id)`                     | Center viewport on node         |
| `exportGraph()`                               | Export graph to JSON            |
| `loadGraph(NodeGraph)`                        | Load graph from data            |
| `clearGraph()`                                | Clear all nodes and connections |

### Node

| Property      | Type       | Description       |
|---------------|------------|-------------------|
| `id`          | String     | Unique identifier |
| `type`        | String     | Node type label   |
| `data`        | T          | Custom node data  |
| `position`    | Offset     | Node position     |
| `size`        | Size       | Node dimensions   |
| `inputPorts`  | List<Port> | Input ports       |
| `outputPorts` | List<Port> | Output ports      |
| `isSelected`  | bool       | Selection state   |

### Port

| Property           | Type         | Description                |
|--------------------|--------------|----------------------------|
| `id`               | String       | Unique identifier          |
| `name`             | String       | Display name               |
| `position`         | PortPosition | Port location on node      |
| `offset`           | Offset       | Position offset            |
| `type`             | PortType     | source/target/both         |
| `shape`            | PortShape    | Visual appearance          |
| `multiConnections` | bool         | Allow multiple connections |
| `maxConnections`   | int?         | Connection limit           |

### Connection

| Property       | Type    | Description       |
|----------------|---------|-------------------|
| `id`           | String  | Unique identifier |
| `sourceNodeId` | String  | Source node ID    |
| `sourcePortId` | String  | Source port ID    |
| `targetNodeId` | String  | Target node ID    |
| `targetPortId` | String  | Target port ID    |
| `label`        | String? | Connection label  |

---

## 💡 Tips and Best Practices

> [!TIP]
> **Performance**: Use specific data types for `Node<T>` rather than `Map<String, dynamic>` when
> possible for better type safety and performance.

> [!WARNING]
> **Large Graphs**: For graphs with 100+ nodes, consider implementing virtualization or chunking
> strategies. The minimap helps with navigation.

> [!NOTE]
> **Serialization**: When implementing custom node data types, ensure they have proper `toJson()`
> and `fromJson()` methods for serialization.

---

### Development Setup

```bash
# Clone the repository
git clone https://github.com/vyuh-tech/cdx.git
cd cdx/packages/vyuh_node_flow

# Install dependencies
flutter pub get

# Run example
cd example
flutter run -d chrome
```

---

## Acknowledgments

Inspired by [React Flow](https://reactflow.dev/) - a powerful node-based editor for React
applications.

---

Made with ❤️ by the Vyuh Team
