---
title: Port Shapes
description: Customize the visual appearance of connection ports
---

# Port Shapes

Port shapes define how connection points appear on your nodes. Vyuh Node Flow provides six built-in shapes, each serving different visual and functional purposes.

::: details 🖼️ All Port Shapes
Six port shapes displayed on a node: Circle (default), Square, Diamond, Triangle (pointing right), Capsule Half (half-circle opening outward), and None (invisible). Each labeled with name and typical use case.
:::

## Available Shapes

### Circle

The default port shape - a simple circle. Universal and works in all contexts.

```dart
Port(
  id: 'port-1',
  name: 'Output',
  position: PortPosition.right,
  shape: PortShapes.circle, // Default
)
```

**Best for**:
- General purpose
- Data flow diagrams
- When no specific meaning is needed

**Characteristics**:
- Symmetrical in all directions
- Easy to recognize and interact with
- Works with all port positions (left, right, top, bottom)

### Square

A rectangular port shape. Good for technical and structured diagrams.

```dart
Port(
  id: 'port-1',
  name: 'Control',
  position: PortPosition.right,
  shape: PortShapes.square,
)
```

**Best for**:
- Control flow ports
- Event triggers
- Grid-aligned designs

**Characteristics**:
- Sharp, technical appearance
- Aligns well with rectangular nodes
- Clear visual distinction from circular ports

### Diamond

A diamond (rotated square) shape. Excellent for conditional or decision points.

```dart
Port(
  id: 'condition-port',
  name: 'Decision',
  position: PortPosition.right,
  shape: PortShapes.diamond,
)
```

::: details 🖼️ Diamond Port Shape
Close-up of diamond port (rotated 45-degree square). Shows how it stands out for decision/branch points.
:::

**Best for**:
- Conditional/decision ports
- Branch points
- Special connection types

**Characteristics**:
- Visually distinct
- Suggests branching or decisions
- Common in flowchart conventions

### Triangle

A triangular shape that points in the direction of the port position. Shows directionality.

```dart
Port(
  id: 'output-port',
  name: 'Output',
  position: PortPosition.right,
  shape: PortShapes.triangle, // Points right
)
```

**Best for**:
- Directional data flow
- Output ports
- Signal paths

**Characteristics**:
- Directional - points toward port position
- Strong visual indicator of flow direction
- Orientation automatically matches port position:
  - `PortPosition.right` → points right (▶)
  - `PortPosition.left` → points left (◀)
  - `PortPosition.top` → points up (▲)
  - `PortPosition.bottom` → points down (▼)

### Capsule Half

A half-capsule (semi-circle) shape that opens toward the connection direction.

```dart
Port(
  id: 'connector',
  name: 'Socket',
  position: PortPosition.left,
  shape: PortShapes.capsuleHalf, // Opens left
)
```

::: details 🖼️ Capsule Half Port Shape
Capsule half (semi-circle) ports shown on left and right edges, opening toward connection direction. Demonstrates socket/plug metaphor.
:::

**Best for**:
- Socket/plug metaphors
- Interface connection points
- Hardware connection diagrams

**Characteristics**:
- Suggests physical connection
- Opens in the direction of port position
- Visually suggests "plugging in"

### None

An invisible port shape. The port is functional but not visually rendered.

```dart
Port(
  id: 'invisible-port',
  name: 'Hidden',
  position: PortPosition.right,
  shape: PortShapes.none,
)
```

**Best for**:
- Minimalist designs
- When connections should appear to connect directly to nodes
- Hidden functionality

**Characteristics**:
- Fully functional for connections
- No visual representation
- Connection endpoints still render normally

## Setting Port Shapes

### Per-Port Configuration

```dart
Node(
  id: 'node-1',
  inputPorts: [
    Port(
      id: 'in-1',
      name: 'Data Input',
      position: PortPosition.left,
      shape: PortShapes.circle,
    ),
    Port(
      id: 'trigger',
      name: 'Trigger',
      position: PortPosition.top,
      shape: PortShapes.square,
    ),
  ],
  outputPorts: [
    Port(
      id: 'out-1',
      name: 'Output',
      position: PortPosition.right,
      shape: PortShapes.triangle,
    ),
    Port(
      id: 'error',
      name: 'Error',
      position: PortPosition.bottom,
      shape: PortShapes.diamond,
    ),
  ],
)
```

### Type-Based Shapes

Use different shapes for different port types:

```dart
Port createPort({
  required String id,
  required String name,
  required PortPosition position,
  required String portType,
}) {
  PortShape shape;

  switch (portType) {
    case 'data':
      shape = PortShapes.circle;
      break;
    case 'control':
      shape = PortShapes.square;
      break;
    case 'event':
      shape = PortShapes.triangle;
      break;
    case 'condition':
      shape = PortShapes.diamond;
      break;
    case 'socket':
      shape = PortShapes.capsuleHalf;
      break;
    default:
      shape = PortShapes.circle;
  }

  return Port(
    id: id,
    name: name,
    position: position,
    shape: shape,
  );
}
```

## Shape Comparison

| Shape | Use Case | Directionality | Visual Weight |
|-------|----------|----------------|---------------|
| **Circle** | General purpose | None | Medium |
| **Square** | Control flow | None | Medium |
| **Diamond** | Decisions | None | High |
| **Triangle** | Directional flow | Yes | High |
| **Capsule Half** | Connections | Yes | Medium |
| **None** | Minimalist | N/A | None |

## Styling Port Shapes

Customize appearance through theme:

```dart
NodeFlowEditor(
  theme: NodeFlowTheme(
    portTheme: PortTheme(
      size: 12,                      // Port diameter
      color: Colors.blue,            // Fill color
      hoverColor: Colors.blue[700]!, // Hover state
      borderColor: Colors.white,     // Border color
      borderWidth: 2,                // Border thickness
    ),
  ),
)
```

## Shape Orientation

Directional shapes (triangle, capsuleHalf) automatically orient based on port position:

::: code-group

```dart [Triangle]
// Points in direction of port
Port(
  position: PortPosition.right,
  shape: PortShapes.triangle, // ▶
)

Port(
  position: PortPosition.left,
  shape: PortShapes.triangle, // ◀
)

Port(
  position: PortPosition.top,
  shape: PortShapes.triangle, // ▲
)

Port(
  position: PortPosition.bottom,
  shape: PortShapes.triangle, // ▼
)
```

```dart [Capsule Half]
// Opens toward connection direction
Port(
  position: PortPosition.left,
  shape: PortShapes.capsuleHalf, // Opens left ⊂
)

Port(
  position: PortPosition.right,
  shape: PortShapes.capsuleHalf, // Opens right ⊃
)
```

:::

## Visual Conventions

Consider these common conventions when choosing shapes:

### Data Flow Diagrams
- **Circle**: Data ports
- **Triangle**: Output direction indicators
- **None**: Clean, minimal design

### Control Flow / BPMN
- **Square**: Event/message ports
- **Diamond**: Gateway/decision points
- **Circle**: Standard sequence flow

### Circuit Diagrams
- **Capsule Half**: Pin connections
- **Circle**: General connection points
- **Square**: Digital signal ports

## Creating Custom Port Shapes

Extend `PortShape` to create custom shapes:

```dart
class StarPortShape extends PortShape {
  const StarPortShape();

  @override
  void paint(
    Canvas canvas,
    Offset center,
    double size,
    Paint fillPaint,
    Paint? borderPaint, {
    ShapeOrientation? orientation,
  }) {
    final path = Path();
    final radius = size / 2;

    // Draw 5-point star
    for (int i = 0; i < 5; i++) {
      final angle = (i * 4 * pi / 5) - pi / 2;
      final x = center.dx + radius * cos(angle);
      final y = center.dy + radius * sin(angle);

      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    path.close();

    canvas.drawPath(path, fillPaint);
    if (borderPaint != null) {
      canvas.drawPath(path, borderPaint);
    }
  }

  @override
  String get typeName => 'star';
}

// Usage
Port(
  id: 'special-port',
  name: 'Special',
  position: PortPosition.right,
  shape: const StarPortShape(),
)
```

::: info
**Learn More**: See the [API Reference](/docs/api/custom-port-shapes) for detailed guidance on creating custom port shapes.

:::

## Best Practices

1. **Consistency**: Use the same shape for the same port type across all nodes
2. **Meaning**: Choose shapes that convey meaning (diamonds for decisions, triangles for outputs)
3. **Contrast**: Use different shapes to distinguish different port types
4. **Size**: Keep port sizes between 8-16 pixels for good usability
5. **Color Coding**: Combine shape with color for maximum clarity

## Interactive Behavior

All port shapes support the same interaction features:

- **Hover**: Visual feedback when mouse is over port
- **Connection dragging**: Start new connections from source ports
- **Multi-connections**: Allow multiple connections based on port settings
- **Validation**: Connection validation works regardless of shape

## See Also

- [Ports](/docs/core-concepts/ports) - Understanding port concepts
- [Theming Overview](/docs/theming/overview) - Complete theming guide
- [Port Theme](/docs/theming/overview#port-theme) - Port styling options
