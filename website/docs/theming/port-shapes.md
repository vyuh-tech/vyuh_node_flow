---
title: Port Shapes
description: Customize the visual appearance of connection ports
---

# Port Shapes

Port shapes define how connection points appear on your nodes. Vyuh Node Flow provides six built-in marker shapes, each serving different visual and functional purposes. These shapes are shared between ports and connection endpoints.

::: details 🖼️ All Port Shapes
Six port shapes displayed on a node: Circle, Rectangle, Diamond, Triangle, Capsule Half (default), and None (invisible). Each labeled with name and typical use case.
:::

## Available Shapes

### Circle

A simple circular shape. Universal and works in all contexts.

```dart
Port(
  id: 'port-1',
  name: 'Output',
  position: PortPosition.right,
  shape: MarkerShapes.circle,
)
```

::: info
The default port shape is `capsuleHalf`, not circle. To use a circle, explicitly set `shape: MarkerShapes.circle`.
:::

**Best for**:
- General purpose
- Data flow diagrams
- When no specific meaning is needed

**Characteristics**:
- Symmetrical in all directions
- Easy to recognize and interact with
- Works with all port positions (left, right, top, bottom)

### Rectangle

A rectangular port shape. Good for technical and structured diagrams.

```dart
Port(
  id: 'port-1',
  name: 'Control',
  position: PortPosition.right,
  shape: MarkerShapes.rectangle,
)
```

::: tip
For square markers, use a port with equal width and height (e.g., `size: Size.square(10)`).
:::

**Best for**:
- Control flow ports
- Event triggers
- Grid-aligned designs

**Characteristics**:
- Sharp, technical appearance
- Aligns well with rectangular nodes
- Clear visual distinction from circular ports
- Uses the provided `Size` directly (not forced to be square)

### Diamond

A diamond (rotated square) shape. Excellent for conditional or decision points.

```dart
Port(
  id: 'condition-port',
  name: 'Decision',
  position: PortPosition.right,
  shape: MarkerShapes.diamond,
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

A triangular shape with orientation based on port position. For ports, the triangle tip always points **inward** (into the node), with the flat side at the node edge.

```dart
Port(
  id: 'input-port',
  name: 'Input',
  position: PortPosition.left,
  shape: MarkerShapes.triangle,
)
```

**Best for**:
- Directional data flow
- Input/output indication
- Signal paths

**Characteristics**:
- Tip points inward (into the node)
- Flat side aligns with node boundary
- Orientation automatically matches port position:
  - `PortPosition.left` → flat side on left, tip points right (into node)
  - `PortPosition.right` → flat side on right, tip points left (into node)
  - `PortPosition.top` → flat side on top, tip points down (into node)
  - `PortPosition.bottom` → flat side on bottom, tip points up (into node)

### Capsule Half

A half-capsule (semi-circle) shape. This is the **default** port shape.

```dart
Port(
  id: 'connector',
  name: 'Socket',
  position: PortPosition.left,
  shape: MarkerShapes.capsuleHalf, // This is the default
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
  shape: MarkerShapes.none,
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
      shape: MarkerShapes.circle,
    ),
    Port(
      id: 'trigger',
      name: 'Trigger',
      position: PortPosition.top,
      shape: MarkerShapes.rectangle,
    ),
  ],
  outputPorts: [
    Port(
      id: 'out-1',
      name: 'Output',
      position: PortPosition.right,
      shape: MarkerShapes.triangle,
    ),
    Port(
      id: 'error',
      name: 'Error',
      position: PortPosition.bottom,
      shape: MarkerShapes.diamond,
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
  MarkerShape shape;

  switch (portType) {
    case 'data':
      shape = MarkerShapes.circle;
      break;
    case 'control':
      shape = MarkerShapes.rectangle;
      break;
    case 'event':
      shape = MarkerShapes.triangle;
      break;
    case 'condition':
      shape = MarkerShapes.diamond;
      break;
    case 'socket':
      shape = MarkerShapes.capsuleHalf;
      break;
    default:
      shape = MarkerShapes.circle;
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

| Shape | Class | Use Case | Visual Weight |
|-------|-------|----------|---------------|
| **Circle** | `MarkerShapes.circle` | General purpose | Medium |
| **Rectangle** | `MarkerShapes.rectangle` | Control flow | Medium |
| **Diamond** | `MarkerShapes.diamond` | Decisions | High |
| **Triangle** | `MarkerShapes.triangle` | Directional flow | High |
| **Capsule Half** | `MarkerShapes.capsuleHalf` | Connections (default) | Medium |
| **None** | `MarkerShapes.none` | Minimalist | None |

## Styling Port Shapes

Customize appearance through theme:

```dart
NodeFlowEditor(
  theme: NodeFlowTheme.dark.copyWith(
    portTheme: PortTheme.dark.copyWith(
      size: Size(12, 12),            // Port size (width, height)
      color: Colors.blue,            // Fill color
      highlightColor: Colors.blue.shade700, // Highlight state during connection drag
      borderColor: Colors.white,     // Border color
      borderWidth: 2,                // Border thickness
    ),
  ),
)
```

## Shape Orientation

Directional shapes (triangle, capsuleHalf) automatically orient based on port position. For ports, asymmetric shapes have their tips pointing **inward** (into the node).

::: code-group

```dart [Triangle]
// Tips point inward (into the node)
Port(
  position: PortPosition.right,
  shape: MarkerShapes.triangle, // flat on right, tip points left ◀
)

Port(
  position: PortPosition.left,
  shape: MarkerShapes.triangle, // flat on left, tip points right ▶
)

Port(
  position: PortPosition.top,
  shape: MarkerShapes.triangle, // flat on top, tip points down ▼
)

Port(
  position: PortPosition.bottom,
  shape: MarkerShapes.triangle, // flat on bottom, tip points up ▲
)
```

```dart [Capsule Half]
// Orientation based on port position
Port(
  position: PortPosition.left,
  shape: MarkerShapes.capsuleHalf,
)

Port(
  position: PortPosition.right,
  shape: MarkerShapes.capsuleHalf,
)
```

:::

## Visual Conventions

Consider these common conventions when choosing shapes:

### Data Flow Diagrams
- **Circle**: Data ports
- **Triangle**: Directional indicators
- **None**: Clean, minimal design

### Control Flow / BPMN
- **Rectangle**: Event/message ports
- **Diamond**: Gateway/decision points
- **Circle**: Standard sequence flow

### Circuit Diagrams
- **Capsule Half**: Pin connections (default)
- **Circle**: General connection points
- **Rectangle**: Digital signal ports

## Creating Custom Port Shapes

Extend `MarkerShape` to create custom shapes:

```dart
import 'dart:math';

class StarMarkerShape extends MarkerShape {
  const StarMarkerShape();

  @override
  String get typeName => 'star';

  @override
  void paint(
    Canvas canvas,
    Offset center,
    Size size,
    Paint fillPaint,
    Paint? borderPaint, {
    ShapeDirection? orientation,
    bool isPointingOutward = false,
  }) {
    final path = Path();
    final radius = size.shortestSide / 2;

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
    if (borderPaint != null && borderPaint.strokeWidth > 0) {
      canvas.drawPath(path, borderPaint);
    }
  }
}

// Usage
Port(
  id: 'special-port',
  name: 'Special',
  position: PortPosition.right,
  shape: const StarMarkerShape(),
)
```

::: info
The `typeName` getter is required for JSON serialization support.
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
