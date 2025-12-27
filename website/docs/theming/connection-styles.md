---
title: Connection Styles
description: Choose how connections are drawn between nodes
---

# Connection Styles

Connection styles control how the path between two ports is drawn. Vyuh Node Flow provides four built-in path styles, each suited for different use cases.

::: details 🖼️ All Connection Styles Comparison
Four-panel grid showing the same two nodes connected with different styles: (1) Bezier - smooth flowing S-curve, (2) Smoothstep - right angles with rounded corners, (3) Step - sharp 90-degree angles, (4) Straight - direct diagonal line. Each labeled with style name and best use case.
:::

## Available Styles

### Bezier (Smooth Curves)

Creates smooth, flowing cubic Bezier curves between nodes. Best for organic, natural-looking flows.

```dart
connectionStyle: ConnectionStyles.bezier
```

**Best for**:
- Data pipelines
- Workflow diagrams
- Mind maps
- When showing natural flow of information

**Characteristics**:
- Smooth, organic curves
- Automatically adjusts curve intensity based on distance
- Handles sharp turns gracefully
- Works well in all directions

::: code-group

```dart [Basic]
NodeFlowEditor(
  theme: NodeFlowTheme(
    connectionStyle: ConnectionStyles.bezier,
  ),
)
```

```dart [Custom Curve Intensity]
NodeFlowEditor(
  theme: NodeFlowTheme(
    connectionStyle: BezierConnectionStyle(
      curvature: 0.5, // 0.0 = straight, 1.0 = very curved
    ),
  ),
)
```

:::

Creates step patterns with rounded corners. Ideal for technical diagrams and structured workflows.

```dart
connectionStyle: ConnectionStyles.smoothstep
```

**Best for**:
- Technical diagrams
- Circuit designs
- BPMN-style processes
- When you need clean, structured paths

**Characteristics**:
- Right-angle turns with rounded corners
- Clean, professional appearance
- Excellent for horizontal/vertical layouts
- Predictable path routing

::: code-group

```dart [Basic]
NodeFlowEditor(
  theme: NodeFlowTheme(
    connectionStyle: ConnectionStyles.smoothstep,
  ),
)
```

```dart [Custom Corner Radius]
NodeFlowEditor(
  theme: NodeFlowTheme(
    connectionStyle: SmoothstepConnectionStyle(
      cornerRadius: 10, // Radius of rounded corners
    ),
  ),
)
```

:::

Creates step patterns with sharp, 90-degree corners. Perfect for grid-aligned, technical diagrams.

```dart
connectionStyle: ConnectionStyles.step
```

**Best for**:
- Circuit diagrams
- Network topologies
- Grid-aligned layouts
- When precision matters more than aesthetics

**Characteristics**:
- Sharp 90-degree turns
- No curves or rounding
- Aligns perfectly with grids
- Minimal visual complexity

```dart
NodeFlowEditor(
  theme: NodeFlowTheme(
    connectionStyle: ConnectionStyles.step,
  ),
)
```

### Straight (Direct Lines)

Creates direct, straight lines between ports. Minimalist and performance-optimized.

```dart
connectionStyle: ConnectionStyles.straight
```

**Best for**:
- Simple diagrams
- When performance is critical
- Minimalist designs
- Dense graphs with many connections

**Characteristics**:
- Direct line from source to target
- Fastest rendering performance
- Minimal visual clutter
- Works well with diagonal layouts

```dart
NodeFlowEditor(
  theme: NodeFlowTheme(
    connectionStyle: ConnectionStyles.straight,
  ),
)
```

## Per-Connection Styles

Apply different styles to individual connections:

```dart
// Create connection with specific style
final connection = Connection(
  id: 'conn-1',
  sourceNodeId: 'node-1',
  sourcePortId: 'out',
  targetNodeId: 'node-2',
  targetPortId: 'in',
  style: ConnectionStyles.bezier, // Override theme
);

controller.addConnection(connection);
```

## Combining Styles

Mix styles in the same diagram:

```dart
nodeBuilder: (context, node) {
  // Use different styles for different connection types
  if (node.type == 'data-source') {
    return NodeWidget(
      // Data connections use smooth curves
      connectionStyle: ConnectionStyles.bezier,
    );
  } else if (node.type == 'control-flow') {
    return NodeWidget(
      // Control flow uses sharp steps
      connectionStyle: ConnectionStyles.step,
    );
  }
}
```

## Style Comparison

| Style | Performance | Visual Appeal | Use Case |
|-------|------------|---------------|----------|
| **Bezier** | Good | High | Natural flows, data pipelines |
| **Smoothstep** | Good | High | Technical diagrams, workflows |
| **Step** | Excellent | Medium | Circuit designs, grid layouts |
| **Straight** | Excellent | Low | Simple diagrams, dense graphs |

## Temporary Connection Style

Customize the style used while dragging to create a connection:

```dart
NodeFlowEditor(
  theme: NodeFlowTheme(
    // Normal connections
    connectionStyle: ConnectionStyles.smoothstep,

    // While dragging
    temporaryConnectionStyle: ConnectionStyles.straight,
    temporaryConnectionTheme: ConnectionTheme(
      color: Colors.blue.withOpacity(0.5),
      strokeWidth: 2,
      dashPattern: [8, 4], // Dashed line
    ),
  ),
)
```

## Best Practices

1. **Consistency**: Use the same style for similar connection types
2. **Context**: Choose style based on your domain (technical vs creative)
3. **Performance**: Use `straight` for graphs with 100+ connections
4. **Grid Alignment**: Use `step` or `smoothstep` with grid snapping
5. **User Preference**: Consider allowing users to switch styles

## Creating Custom Styles

Extend `ConnectionStyle` to create custom path algorithms:

```dart
class WaveConnectionStyle extends ConnectionStyle {
  final double amplitude;

  const WaveConnectionStyle({this.amplitude = 20.0});

  @override
  Path createPath(
    Offset start,
    Offset end,
    PortPosition startPosition,
    PortPosition endPosition,
  ) {
    final path = Path();
    path.moveTo(start.dx, start.dy);

    // Generate points along a sine wave
    final distance = (end - start).distance;
    final steps = (distance / 5).ceil();

    for (int i = 0; i <= steps; i++) {
      final t = i / steps;
      final x = start.dx + (end.dx - start.dx) * t;
      final wave = sin(t * 2 * pi) * amplitude;
      final y = start.dy + (end.dy - start.dy) * t + wave;
      path.lineTo(x, y);
    }

    return path;
  }

  @override
  String get typeName => 'wave';
}
```

**Usage:**
```dart
NodeFlowEditor(
  theme: NodeFlowTheme(
    connectionStyle: WaveConnectionStyle(amplitude: 15),
  ),
)
```

**Common custom styles you can create:**
- Arc paths using Bezier curves (`quadraticBezierTo`, `cubicTo`)
- Circuit/Manhattan routing with perpendicular segments
- Spiral or custom mathematical curves
- Adaptive paths based on port positions and distance

## See Also

- [Connection Effects](/docs/theming/connection-effects) - Animate your connections
- [Connections](/docs/core-concepts/connections) - Understanding connections
- [Theming Overview](/docs/theming/overview) - Complete theming guide
