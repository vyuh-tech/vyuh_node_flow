---
title: NodeFlowController
description: API reference for the NodeFlowController class
---

# NodeFlowController

The `NodeFlowController` manages all graph state including nodes, connections, selection, and viewport. It's the central point for programmatic graph manipulation.

## Constructor

```dart
NodeFlowController<T, dynamic>({
  GraphViewport? initialViewport,
  NodeFlowConfig? config,
  List<Node<T>>? nodes,
  List<Connection>? connections,
})
```

| Parameter | Type | Description |
|-----------|------|-------------|
| `initialViewport` | `GraphViewport?` | Initial viewport position and zoom |
| `config` | `NodeFlowConfig?` | Behavioral configuration (snap-to-grid, zoom limits, etc.) |
| `nodes` | `List<Node<T>>?` | Initial nodes to populate the graph |
| `connections` | `List<Connection>?` | Initial connections between nodes |

## Node Operations

### addNode

Add a node to the graph.

```dart
void addNode(Node<T> node)
```

**Example:**
```dart
final node = Node<MyData>(
  id: 'node-1',
  type: 'process',
  position: Offset(100, 100),
  data: MyData(label: 'Process'),
  inputPorts: [Port(id: 'in-1', name: 'Input')],
  outputPorts: [Port(id: 'out-1', name: 'Output')],
);
controller.addNode(node);
```

### removeNode

Remove a node and all its connections.

```dart
void removeNode(String nodeId)
```

::: info
Removing a node automatically removes all connections to and from that node, and removes the node from any group annotations.
:::

### requestDeleteNode

Request deletion with lock check and confirmation callback.

```dart
Future<bool> requestDeleteNode(String nodeId)
```

Returns `true` if deleted, `false` if prevented by lock or callback.

### duplicateNode

Create a duplicate of a node.

```dart
void duplicateNode(String nodeId)
```

### deleteNodes

Delete multiple nodes at once.

```dart
void deleteNodes(List<String> nodeIds)
```

### moveNode

Move a node by a delta offset.

```dart
void moveNode(String nodeId, Offset delta)
```

### moveSelectedNodes

Move all selected nodes by a delta offset.

```dart
void moveSelectedNodes(Offset delta)
```

### setNodeSize

Update a node's size.

```dart
void setNodeSize(String nodeId, Size size)
```

### setNodePorts

Replace a node's ports.

```dart
void setNodePorts(String nodeId, {
  List<Port>? inputPorts,
  List<Port>? outputPorts,
})
```

### addInputPort / addOutputPort

Add ports to an existing node.

```dart
void addInputPort(String nodeId, Port port)
void addOutputPort(String nodeId, Port port)
```

### removePort

Remove a port and all its connections.

```dart
void removePort(String nodeId, String portId)
```

### getNode

Get a node by ID.

```dart
Node<T>? getNode(String nodeId)
```

## Connection Operations

### addConnection

Create a connection between ports.

```dart
void addConnection(Connection connection)
```

**Example:**
```dart
final connection = Connection(
  id: 'conn-1',
  sourceNodeId: 'node-1',
  sourcePortId: 'out-1',
  targetNodeId: 'node-2',
  targetPortId: 'in-1',
);
controller.addConnection(connection);
```

### removeConnection

Remove a connection by ID.

```dart
void removeConnection(String connectionId)
```

### requestDeleteConnection

Request deletion with lock check and confirmation callback.

```dart
Future<bool> requestDeleteConnection(String connectionId)
```

Returns `true` if deleted, `false` if prevented by lock or callback.

### createConnection

Create a connection with auto-generated ID.

```dart
void createConnection(
  String sourceNodeId,
  String sourcePortId,
  String targetNodeId,
  String targetPortId,
)
```

### getConnectionsForNode

Get all connections for a node.

```dart
List<Connection> getConnectionsForNode(String nodeId)
```

### connections

Access all connections (read-only list).

```dart
List<Connection> get connections
```

## Control Points

Connections support user-defined control points for custom routing.

::: code-group

```dart [addControlPoint]
void addControlPoint(String connectionId, Offset position, {int? index})
```

```dart [updateControlPoint]
void updateControlPoint(String connectionId, int index, Offset position)
```

```dart [removeControlPoint]
void removeControlPoint(String connectionId, int index)
```

```dart [clearControlPoints]
void clearControlPoints(String connectionId)
```

:::

## Selection

### selectNode

Select a node. Use `toggle: true` for multi-select behavior.

```dart
void selectNode(String nodeId, {bool toggle = false})
```

### selectNodes

Select multiple nodes.

```dart
void selectNodes(List<String> nodeIds, {bool toggle = false})
```

### selectConnection

Select a connection.

```dart
void selectConnection(String connectionId, {bool toggle = false})
```

### clearSelection

Clear all selections (nodes, connections, annotations).

```dart
void clearSelection()
```

### clearNodeSelection / clearConnectionSelection

Clear specific selection types.

```dart
void clearNodeSelection()
void clearConnectionSelection()
```

### selectedNodeIds

Get IDs of selected nodes.

```dart
Set<String> get selectedNodeIds
```

### hasSelection

Check if anything is selected.

```dart
bool get hasSelection
```

### isNodeSelected

Check if a specific node is selected.

```dart
bool isNodeSelected(String nodeId)
```

## Viewport

### viewport

Current viewport state.

```dart
GraphViewport get viewport
```

Returns `GraphViewport` with:
- `x`, `y` - Pan offset
- `zoom` - Zoom level

### currentZoom / currentPan

Access current zoom level and pan position.

```dart
double get currentZoom
ScreenOffset get currentPan
```

### setViewport

Set viewport directly.

```dart
void setViewport(GraphViewport viewport)
```

### panBy

Pan viewport by a delta.

```dart
void panBy(ScreenOffset delta)
```

### zoomBy

Zoom by a delta amount (positive = zoom in), keeping the viewport center fixed.

```dart
void zoomBy(double delta)
```

### zoomTo

Set zoom to a specific level.

```dart
void zoomTo(double zoom)
```

### fitToView

Fit all nodes in the viewport with padding.

```dart
void fitToView()
```

### fitSelectedNodes

Fit only selected nodes in the viewport with padding.

```dart
void fitSelectedNodes()
```

### centerOnNode

Center viewport on a specific node without changing zoom.

```dart
void centerOnNode(String nodeId)
```

### centerOnSelection

Center viewport on the geometric center of selected nodes.

```dart
void centerOnSelection()
```

### centerViewport

Center viewport on the geometric center of all nodes.

```dart
void centerViewport()
```

### centerOn

Center viewport on a specific point in graph coordinates.

```dart
void centerOn(GraphOffset point)
```

### getViewportCenter

Get the center point of the viewport in graph coordinates.

```dart
GraphPosition getViewportCenter()
```

### resetViewport

Reset viewport to zoom 1.0 and center on all nodes.

```dart
void resetViewport()
```

## Coordinate Transformations

Node Flow uses typed coordinate systems to prevent accidentally mixing screen and graph coordinates.

### globalToGraph

Convert global screen position to graph coordinates.

```dart
GraphPosition globalToGraph(ScreenPosition globalPosition)
```

**Example:**
```dart
// In a gesture callback
final graphPos = controller.globalToGraph(
  ScreenPosition(details.globalPosition)
);
```

### graphToScreen

Convert graph coordinates to screen coordinates.

```dart
ScreenPosition graphToScreen(GraphPosition graphPoint)
```

### screenToGraph

Convert screen coordinates to graph coordinates.

```dart
GraphPosition screenToGraph(ScreenPosition screenPoint)
```

**Example:**
```dart
// Convert mouse position to graph coordinates
final graphPos = controller.screenToGraph(
  ScreenPosition(event.localPosition)
);
```

## Visibility & Bounds

### viewportExtent

Get the visible area in graph coordinates.

```dart
GraphRect get viewportExtent
```

### viewportScreenBounds

Get the viewport bounds in global screen coordinates.

```dart
ScreenRect get viewportScreenBounds
```

### isPointVisible

Check if a graph coordinate point is visible.

```dart
bool isPointVisible(GraphPosition graphPoint)
```

### isRectVisible

Check if a graph coordinate rectangle is visible (useful for culling).

```dart
bool isRectVisible(GraphRect graphRect)
```

### selectedNodesBounds

Get the bounding rectangle of all selected nodes.

```dart
GraphRect? get selectedNodesBounds
```

### nodesBounds

Get the bounding rectangle of all nodes.

```dart
GraphRect get nodesBounds
```

## Viewport Animations

All animation methods use smooth easing and accept optional duration and curve parameters.

### animateToViewport

Animate to a target viewport state.

```dart
void animateToViewport(
  GraphViewport target, {
  Duration duration = const Duration(milliseconds: 400),
  Curve curve = Curves.easeInOut,
})
```

**Example:**
```dart
controller.animateToViewport(
  GraphViewport(x: 100, y: 50, zoom: 1.5),
  duration: Duration(milliseconds: 300),
);
```

### animateToNode

Animate to center on a specific node.

```dart
void animateToNode(
  String nodeId, {
  double? zoom = 1.0,
  Duration duration = const Duration(milliseconds: 400),
  Curve curve = Curves.easeInOut,
})
```

**Example:**
```dart
// Animate to node with zoom
controller.animateToNode('node-123', zoom: 1.5);

// Animate to node, keeping current zoom
controller.animateToNode('node-123', zoom: null);
```

### animateToPosition

Animate to center on a specific graph position.

```dart
void animateToPosition(
  GraphOffset position, {
  double? zoom,
  Duration duration = const Duration(milliseconds: 400),
  Curve curve = Curves.easeInOut,
})
```

### animateToBounds

Animate to fit a bounding rectangle with padding.

```dart
void animateToBounds(
  GraphRect bounds, {
  double padding = 50.0,
  Duration duration = const Duration(milliseconds: 400),
  Curve curve = Curves.easeInOut,
})
```

**Example:**
```dart
// Animate to fit selected nodes
final bounds = controller.selectedNodesBounds;
if (bounds != null) {
  controller.animateToBounds(bounds, padding: 100);
}
```

### animateToScale

Animate to a specific zoom level, keeping the center fixed.

```dart
void animateToScale(
  double scale, {
  Duration duration = const Duration(milliseconds: 400),
  Curve curve = Curves.easeInOut,
})
```

### centerOnNodeWithZoom

Immediately center on a node with a specific zoom (non-animated).

```dart
void centerOnNodeWithZoom(String nodeId, {double zoom = 1.0})
```

## Mouse Position

### mousePositionWorld

Get the current mouse position in graph coordinates.

```dart
GraphPosition? get mousePositionWorld
```

Returns `null` if the mouse is outside the canvas.

## Graph Operations

### loadGraph

Load a complete graph (nodes, connections, annotations, viewport).

```dart
void loadGraph(NodeGraph<T, dynamic> graph)
```

### exportGraph

Export current graph state.

```dart
NodeGraph<T, dynamic> exportGraph()
```

**Example:**
```dart
// Save
final graph = controller.exportGraph();
final json = graph.toJson((data) => data.toJson());
await saveToFile(jsonEncode(json));

// Load
final json = jsonDecode(await loadFromFile());
final graph = NodeGraph.fromJson(json, (map) => MyData.fromJson(map));
controller.loadGraph(graph);
```

### clearGraph

Remove all nodes, connections, and annotations.

```dart
void clearGraph()
```

## Alignment & Distribution

### alignNodes

Align nodes to a specific edge or center.

```dart
void alignNodes(List<String> nodeIds, NodeAlignment alignment)
```

| Alignment | Description |
|-----------|-------------|
| `NodeAlignment.left` | Align to left edge |
| `NodeAlignment.right` | Align to right edge |
| `NodeAlignment.top` | Align to top edge |
| `NodeAlignment.bottom` | Align to bottom edge |
| `NodeAlignment.horizontalCenter` | Center horizontally |
| `NodeAlignment.verticalCenter` | Center vertically |

### distributeNodesHorizontally / distributeNodesVertically

Distribute nodes evenly.

```dart
void distributeNodesHorizontally(List<String> nodeIds)
void distributeNodesVertically(List<String> nodeIds)
```

## Annotations (GroupNode & CommentNode)

Annotations in Vyuh Node Flow are special node types: `GroupNode` and `CommentNode`. They're added and managed using the same `addNode`/`removeNode` methods as regular nodes.

### GroupNode

Create visual groups around other nodes:

```dart
// Create a group node
final group = GroupNode<MyData>(
  id: 'group-1',
  position: Offset(50, 50),
  data: myData,
  title: 'Processing Pipeline',
  color: Colors.blue.withOpacity(0.2),
  childNodeIds: {'node-1', 'node-2', 'node-3'},
);
controller.addNode(group);
```

### CommentNode

Create floating text annotations:

```dart
// Create a comment node
final comment = CommentNode<MyData>(
  id: 'comment-1',
  position: Offset(100, 100),
  data: myData,
  text: 'This section handles user input validation',
  color: Colors.yellow,
);
controller.addNode(comment);
```

### Selecting Annotations

Since GroupNode and CommentNode are nodes, use the standard selection methods:

```dart
controller.selectNode('group-1');
controller.selectNode('comment-1', toggle: true);
```

## Lifecycle

### dispose

Dispose the controller and release resources.

```dart
void dispose()
```

::: info
Always call `dispose()` when the controller is no longer needed to prevent memory leaks.

:::

## Complete Example

```dart
class WorkflowEditor extends StatefulWidget {
  @override
  State<WorkflowEditor> createState() => _WorkflowEditorState();
}

class _WorkflowEditorState extends State<WorkflowEditor> {
  late final NodeFlowController<WorkflowData, dynamic> controller;

  @override
  void initState() {
    super.initState();
    controller = NodeFlowController<WorkflowData, dynamic>();
    _setupGraph();
  }

  void _setupGraph() {
    controller.addNode(Node(
      id: 'start',
      type: 'trigger',
      position: Offset(100, 100),
      data: WorkflowData(label: 'Start'),
      outputPorts: [Port(id: 'start-out', name: 'Next')],
    ));

    controller.addNode(Node(
      id: 'process',
      type: 'action',
      position: Offset(300, 100),
      data: WorkflowData(label: 'Process'),
      inputPorts: [Port(id: 'process-in', name: 'Input')],
      outputPorts: [Port(id: 'process-out', name: 'Output')],
    ));

    controller.addConnection(Connection(
      id: 'conn-1',
      sourceNodeId: 'start',
      sourcePortId: 'start-out',
      targetNodeId: 'process',
      targetPortId: 'process-in',
    ));

    WidgetsBinding.instance.addPostFrameCallback((_) {
      controller.fitToView();
    });
  }

  void _addNode() {
    final id = 'node-${DateTime.now().millisecondsSinceEpoch}';
    controller.addNode(Node(
      id: id,
      type: 'action',
      position: Offset(200, 200),
      data: WorkflowData(label: 'New Node'),
      inputPorts: [Port(id: '$id-in', name: 'Input')],
      outputPorts: [Port(id: '$id-out', name: 'Output')],
    ));
    controller.selectNode(id);
  }

  void _deleteSelected() {
    for (final nodeId in controller.selectedNodeIds.toList()) {
      controller.removeNode(nodeId);
    }
  }

  void _saveGraph() async {
    final graph = controller.exportGraph();
    final json = graph.toJson((data) => data.toJson());
    // Save to file or API
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Workflow Editor'),
        actions: [
          IconButton(icon: Icon(Icons.add), onPressed: _addNode),
          IconButton(icon: Icon(Icons.delete), onPressed: _deleteSelected),
          IconButton(icon: Icon(Icons.fit_screen), onPressed: controller.fitToView),
          IconButton(icon: Icon(Icons.save), onPressed: _saveGraph),
        ],
      ),
      body: NodeFlowEditor<WorkflowData, dynamic>(
        controller: controller,
        theme: NodeFlowTheme.light,
        nodeBuilder: (context, node) => Center(child: Text(node.data.label)),
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
