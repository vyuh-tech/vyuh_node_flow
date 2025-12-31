---
title: Node Shapes
description: Create visually distinct nodes with different geometric shapes
---

# Node Shapes

::: details 🖼️ All Node Shapes
Four built-in node shapes displayed side by side: Rectangle (default process node), Circle (terminal start/end), Diamond (decision/conditional), and Hexagon (preparation/setup). Each labeled with name, typical use case, and port positions.
:::

Node shapes transform how your nodes appear on the canvas. Instead of plain rectangles, you can use circles, diamonds, hexagons, or create custom shapes to match your diagram's visual language.

## Available Shapes

Vyuh Node Flow provides four built-in node shapes, each designed for specific use cases:

| Shape | Class | Use Case |
|-------|-------|----------|
| **Rectangle** | Default (no shape) | Process nodes, general purpose |
| **Circle** | `CircleShape` | Terminal nodes (start/end) |
| **Diamond** | `DiamondShape` | Decision/conditional nodes |
| **Hexagon** | `HexagonShape` | Preparation/setup nodes |

## Rectangle (Default)

The default node shape. Used when no custom shape is specified.

```dart
// No shape specified = rectangle
NodeWidget(
  node: node,
  child: Text('Process'),
)
```

**Best for:**
- Process steps
- General-purpose nodes
- Data transformation nodes
- Any node without special meaning

**Characteristics:**
- Standard rectangular bounds
- Supports all port positions (left, right, top, bottom)
- Familiar and easy to work with

## Circle

Circular nodes, commonly used for start/end points in flowcharts.

```dart
CircleShape(
  fillColor: Colors.green,
  strokeColor: Colors.green.shade700,
  strokeWidth: 2.0,
)
```

**Best for:**
- Start/end terminal nodes
- Event nodes in BPMN diagrams
- State nodes in state machines
- Connector nodes

**Characteristics:**
- Symmetrical in all directions
- Ports positioned at cardinal points (top, right, bottom, left)
- Works with elliptical sizing (width != height)

## Diamond

Diamond (rhombus) shaped nodes for decision points.

::: details 🖼️ Diamond Node Shape
Diamond-shaped decision node with ports at the four vertices. Orange fill with deep orange stroke, showing 'Yes/No' branching pattern typical for conditional logic.
:::

```dart
DiamondShape(
  fillColor: Colors.orange,
  strokeColor: Colors.deepOrange,
  strokeWidth: 2.0,
)
```

**Best for:**
- Decision/branch nodes (if/else)
- Gateway nodes in BPMN
- Conditional logic nodes
- Merge points

**Characteristics:**
- Four points at cardinal directions
- Ports attach to the pointed vertices
- Strong visual indicator of branching logic
- Hit testing uses Manhattan distance

## Hexagon

Six-sided nodes available in two orientations.

::: details 🖼️ Hexagon Node Orientations
Two hexagon orientations: Horizontal (flat top/bottom, pointed left/right) and Vertical (pointed top/bottom, flat left/right). Purple fill showing sideRatio effect on angle.
:::

  ### Horizontal

Flat top and bottom edges, pointed left and right.

```dart
HexagonShape(
  orientation: HexagonOrientation.horizontal,
  sideRatio: 0.2, // Controls the angle of sides
  fillColor: Colors.purple,
  strokeColor: Colors.deepPurple,
)
```

```
   ___
  /   \
 <     >
  \___/
```

  ### Vertical

Pointed top and bottom, flat left and right edges.

```dart
HexagonShape(
  orientation: HexagonOrientation.vertical,
  sideRatio: 0.2,
  fillColor: Colors.purple,
  strokeColor: Colors.deepPurple,
)
```

```
   /\
  |  |
  |  |
   \/
```

**Best for:**
- Preparation/setup nodes in flowcharts
- Configuration steps
- Processing nodes
- Sub-routine calls

**Characteristics:**
- `sideRatio` parameter (0.0 - 0.5) controls the angled portion
- 0.0 = rectangle, 0.5 = diamond, 0.2 = typical hexagon
- Ports at cardinal positions
- Two orientation options

## Using Node Shapes

### The nodeShapeBuilder Callback

Assign shapes based on node type using `nodeShapeBuilder`:

```dart
NodeFlowEditor<MyData, dynamic>(
  controller: controller,
  nodeBuilder: (context, node) => Text(node.data.label),
  nodeShapeBuilder: (context, node) {
    switch (node.type) {
      case 'Terminal':
        return CircleShape();
      case 'Decision':
        return DiamondShape();
      case 'Preparation':
        return const HexagonShape(
          orientation: HexagonOrientation.horizontal,
        );
      default:
        return null; // Use default rectangle
    }
  },
)
```

::: info
Returning `null` from `nodeShapeBuilder` uses the default rectangular shape.

:::

### Complete Example

Here's a flowchart with different node shapes:

::: details 🖼️ Complete Flowchart with Mixed Shapes
Flowchart showing all shapes in action: Circle (Start) → Rectangle (Process Data) → Diamond (Valid?) with Yes branch to Circle (End) and No branch looping back. Demonstrates nodeShapeBuilder assigning shapes based on node type.
:::

```dart
class FlowchartExample extends StatefulWidget {
  @override
  State<FlowchartExample> createState() => _FlowchartExampleState();
}

class _FlowchartExampleState extends State<FlowchartExample> {
  late final NodeFlowController<Map<String, dynamic>> controller;

  @override
  void initState() {
    super.initState();
    controller = NodeFlowController();
    _setupNodes();
  }

  void _setupNodes() {
    // Start node (Circle)
    controller.addNode(Node(
      id: 'start',
      type: 'Terminal',
      position: const Offset(100, 50),
      size: const Size(100, 100),
      data: {'label': 'Start'},
      outputPorts: const [
        Port(id: 'out', position: PortPosition.bottom),
      ],
    ));

    // Process node (Rectangle - default)
    controller.addNode(Node(
      id: 'process',
      type: 'Process',
      position: const Offset(100, 200),
      size: const Size(140, 80),
      data: {'label': 'Process Data'},
      inputPorts: const [
        Port(id: 'in', position: PortPosition.top),
      ],
      outputPorts: const [
        Port(id: 'out', position: PortPosition.bottom),
      ],
    ));

    // Decision node (Diamond)
    controller.addNode(Node(
      id: 'decision',
      type: 'Decision',
      position: const Offset(100, 350),
      size: const Size(120, 100),
      data: {'label': 'Valid?'},
      inputPorts: const [
        Port(id: 'in', position: PortPosition.top),
      ],
      outputPorts: const [
        Port(id: 'yes', name: 'Yes', position: PortPosition.right),
        Port(id: 'no', name: 'No', position: PortPosition.bottom),
      ],
    ));

    // End node (Circle)
    controller.addNode(Node(
      id: 'end',
      type: 'Terminal',
      position: const Offset(280, 350),
      size: const Size(100, 100),
      data: {'label': 'End'},
      inputPorts: const [
        Port(id: 'in', position: PortPosition.left),
      ],
    ));

    // Add connections
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
      targetNodeId: 'decision',
      targetPortId: 'in',
    ));

    controller.addConnection(Connection(
      id: 'c3',
      sourceNodeId: 'decision',
      sourcePortId: 'yes',
      targetNodeId: 'end',
      targetPortId: 'in',
    ));
  }

  @override
  Widget build(BuildContext context) {
    return NodeFlowEditor<Map<String, dynamic>>(
      controller: controller,
      nodeBuilder: (context, node) => Center(
        child: Text(
          node.data['label'] ?? '',
          textAlign: TextAlign.center,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      nodeShapeBuilder: (context, node) {
        switch (node.type) {
          case 'Terminal':
            return CircleShape();
          case 'Decision':
            return DiamondShape();
          default:
            return null;
        }
      },
    );
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }
}
```

## Port Positioning with Shapes

For shaped nodes (non-rectangular), ports are automatically positioned at the shape's anchor points. You don't need to specify manual offsets.

```dart
// For shaped nodes, use default offset (or Offset.zero)
// The shape defines where ports attach
Node(
  id: 'circle-node',
  type: 'Terminal',
  size: const Size(120, 120),
  inputPorts: const [
    Port(
      id: 'input',
      position: PortPosition.left, // Attaches to left anchor
      // No offset needed - shape provides it
    ),
  ],
)
```

::: tip
For rectangular nodes, you may want to specify offsets manually. For shaped nodes, let the shape's `getPortAnchors()` method handle positioning.

:::

## Customizing Shape Appearance

Each shape accepts optional styling parameters:

```dart
DiamondShape(
  fillColor: Colors.amber,      // Background fill
  strokeColor: Colors.orange,   // Border color
  strokeWidth: 3.0,             // Border thickness
)
```

If not specified, shapes inherit colors from the `NodeTheme`:

```dart
NodeFlowEditor(
  theme: NodeFlowTheme(
    nodeTheme: NodeTheme(
      backgroundColor: Colors.blue.shade50,
      borderColor: Colors.blue,
      borderWidth: 2.0,
    ),
  ),
)
```

**Priority order:**
1. Shape-level colors (`CircleShape(fillColor: ...)`)
2. Theme-level colors (`NodeTheme.backgroundColor`)

## Creating Custom Shapes

Extend `NodeShape` to create your own shapes:

```dart
import 'dart:math';

class StarShape extends NodeShape {
  const StarShape({
    this.points = 5,
    super.fillColor,
    super.strokeColor,
    super.strokeWidth,
  });

  final int points;

  @override
  Path buildPath(Size size) {
    final path = Path();
    final center = Offset(size.width / 2, size.height / 2);
    final outerRadius = size.width / 2;
    final innerRadius = outerRadius * 0.4;

    for (int i = 0; i < points * 2; i++) {
      final radius = i.isEven ? outerRadius : innerRadius;
      final angle = (i * pi / points) - pi / 2;
      final point = Offset(
        center.dx + radius * cos(angle),
        center.dy + radius * sin(angle),
      );

      if (i == 0) {
        path.moveTo(point.dx, point.dy);
      } else {
        path.lineTo(point.dx, point.dy);
      }
    }

    path.close();
    return path;
  }

  @override
  List<PortAnchor> getPortAnchors(Size size) {
    final centerX = size.width / 2;
    final centerY = size.height / 2;

    return [
      PortAnchor(
        position: PortPosition.top,
        offset: Offset(centerX, 0),
        normal: const Offset(0, -1),
      ),
      PortAnchor(
        position: PortPosition.right,
        offset: Offset(size.width, centerY),
        normal: const Offset(1, 0),
      ),
      PortAnchor(
        position: PortPosition.bottom,
        offset: Offset(centerX, size.height),
        normal: const Offset(0, 1),
      ),
      PortAnchor(
        position: PortPosition.left,
        offset: Offset(0, centerY),
        normal: const Offset(-1, 0),
      ),
    ];
  }
}
```

### Required Methods

| Method | Purpose |
|--------|---------|
| `buildPath(Size)` | Returns a `Path` defining the shape's outline |
| `getPortAnchors(Size)` | Returns `PortAnchor` list for port positioning |

### Optional Methods

| Method | Default Behavior |
|--------|-----------------|
| `containsPoint(Offset, Size)` | Uses `Path.contains()` |
| `getBounds(Size)` | Returns `Offset.zero & size` |

## Shape Comparison

| Shape | Vertices | Port Positions | Typical Size |
|-------|----------|----------------|--------------|
| **Rectangle** | 4 corners | All sides | 120x80 |
| **Circle** | Continuous | Cardinal points | 100x100 |
| **Diamond** | 4 points | At vertices | 120x100 |
| **Hexagon** | 6 points | Cardinal points | 150x100 |

## Best Practices

1. **Match semantics to shapes** - Use circles for terminals, diamonds for decisions
2. **Consistent sizing** - Keep similar shapes at similar sizes for visual harmony
3. **Use shape colors sparingly** - Let theme handle colors for consistency
4. **Consider port positions** - Shapes affect how connections attach
5. **Test hit detection** - Custom shapes should implement `containsPoint` correctly

## See Also

- [Nodes](/docs/core-concepts/nodes) - Node concepts and properties
- [Port Shapes](/docs/theming/port-shapes) - Customize port appearance
- [Theming Overview](/docs/theming/overview) - Complete theming guide
