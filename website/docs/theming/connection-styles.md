---
title: Connection Styles
description: Choose how connections are drawn between nodes
---

# Connection Styles

Connection styles control how the path between two ports is drawn. Vyuh Node
Flow provides four built-in path styles, each suited for different use cases.

::: details All Connection Styles Comparison Four-panel grid showing the same
two nodes connected with different styles: (1) Bezier - smooth flowing S-curve,
(2) Smoothstep - right angles with rounded corners, (3) Step - sharp 90-degree
angles, (4) Straight - direct diagonal line. Each labeled with style name and
best use case. :::

## Available Styles

### Bezier (Smooth Curves)

Creates smooth, flowing cubic Bezier curves between nodes. Best for organic,
natural-looking flows.

```dart
connectionTheme: ConnectionTheme.light.copyWith(
  style: ConnectionStyles.bezier,
)
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
  theme: NodeFlowTheme.light.copyWith(
    connectionTheme: ConnectionTheme.light.copyWith(
      style: ConnectionStyles.bezier,
    ),
  ),
)
```

```dart [Custom Curve Intensity]
// Curvature is configured via the ConnectionTheme
NodeFlowEditor(
  theme: NodeFlowTheme.light.copyWith(
    connectionTheme: ConnectionTheme.light.copyWith(
      style: ConnectionStyles.bezier,
      bezierCurvature: 0.5, // 0.0 = more direct, 1.0 = maximum curve
    ),
  ),
)
```

:::

### Smoothstep (Rounded Steps)

Creates step patterns with rounded corners. Ideal for technical diagrams and
structured workflows.

```dart
connectionTheme: ConnectionTheme.light.copyWith(
  style: ConnectionStyles.smoothstep,
)
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
  theme: NodeFlowTheme.light.copyWith(
    connectionTheme: ConnectionTheme.light.copyWith(
      style: ConnectionStyles.smoothstep,
    ),
  ),
)
```

```dart [Custom Corner Radius]
// Corner radius is configured via the ConnectionTheme
NodeFlowEditor(
  theme: NodeFlowTheme.light.copyWith(
    connectionTheme: ConnectionTheme.light.copyWith(
      style: ConnectionStyles.smoothstep,
      cornerRadius: 10, // Radius of rounded corners
    ),
  ),
)
```

:::

### Step (Sharp Corners)

Creates step patterns with sharp, 90-degree corners. Perfect for grid-aligned,
technical diagrams.

```dart
connectionTheme: ConnectionTheme.light.copyWith(
  style: ConnectionStyles.step,
)
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
  theme: NodeFlowTheme.light.copyWith(
    connectionTheme: ConnectionTheme.light.copyWith(
      style: ConnectionStyles.step,
    ),
  ),
)
```

### Straight (Direct Lines)

Creates direct, straight lines between ports. Minimalist and
performance-optimized.

```dart
connectionTheme: ConnectionTheme.light.copyWith(
  style: ConnectionStyles.straight,
)
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
  theme: NodeFlowTheme.light.copyWith(
    connectionTheme: ConnectionTheme.light.copyWith(
      style: ConnectionStyles.straight,
    ),
  ),
)
```

## Per-Connection Styles

Apply different styles to individual connections:

```dart
// Create connection with specific style override
final connection = Connection(
  id: 'conn-1',
  sourceNodeId: 'node-1',
  sourcePortId: 'out',
  targetNodeId: 'node-2',
  targetPortId: 'in',
  style: ConnectionStyles.bezier, // Override theme style
);

controller.addConnection(connection);
```

## Combining Styles

You can mix styles in the same diagram by setting the `style` property on
individual connections:

```dart
// Data flow connection uses bezier curves
controller.addConnection(Connection(
  id: 'data-flow-1',
  sourceNodeId: 'source',
  sourcePortId: 'dataOut',
  targetNodeId: 'processor',
  targetPortId: 'dataIn',
  style: ConnectionStyles.bezier,
));

// Control flow connection uses sharp steps
controller.addConnection(Connection(
  id: 'control-flow-1',
  sourceNodeId: 'controller',
  sourcePortId: 'controlOut',
  targetNodeId: 'processor',
  targetPortId: 'controlIn',
  style: ConnectionStyles.step,
));
```

## Style Comparison

| Style          | Performance | Visual Appeal | Use Case                      |
| -------------- | ----------- | ------------- | ----------------------------- |
| **Bezier**     | Good        | High          | Natural flows, data pipelines |
| **Smoothstep** | Good        | High          | Technical diagrams, workflows |
| **Step**       | Excellent   | Medium        | Circuit designs, grid layouts |
| **Straight**   | Excellent   | Low           | Simple diagrams, dense graphs |

## Temporary Connection Style

Customize the style used while dragging to create a connection:

```dart
NodeFlowEditor(
  theme: NodeFlowTheme.light.copyWith(
    // Normal connections
    connectionTheme: ConnectionTheme.light.copyWith(
      style: ConnectionStyles.smoothstep,
    ),

    // While dragging - use temporaryConnectionTheme
    temporaryConnectionTheme: ConnectionTheme.light.copyWith(
      style: ConnectionStyles.straight,
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

Extend `ConnectionStyle` to create custom path algorithms. The API uses a
segment-based architecture where you implement `createSegments` to define the
path:

```dart
import 'dart:math';

class WaveConnectionStyle extends ConnectionStyle {
  final double amplitude;
  final int waveCount;

  const WaveConnectionStyle({
    this.amplitude = 20.0,
    this.waveCount = 3,
  });

  @override
  String get id => 'wave';

  @override
  String get displayName => 'Wave';

  @override
  ({Offset start, List<PathSegment> segments}) createSegments(
    ConnectionPathParameters params,
  ) {
    // Generate wave points between start and end
    final segments = <PathSegment>[];
    final distance = (params.end - params.start).distance;
    final steps = (distance / 5).ceil();

    Offset previous = params.start;
    for (int i = 1; i <= steps; i++) {
      final t = i / steps;
      final x = params.start.dx + (params.end.dx - params.start.dx) * t;
      final wave = sin(t * waveCount * 2 * pi) * amplitude;
      final y = params.start.dy + (params.end.dy - params.start.dy) * t + wave;
      final current = Offset(x, y);
      segments.add(StraightSegment(end: current));
      previous = current;
    }

    return (start: params.start, segments: segments);
  }
}
```

**Usage:**

```dart
NodeFlowEditor(
  theme: NodeFlowTheme.light.copyWith(
    connectionTheme: ConnectionTheme.light.copyWith(
      style: WaveConnectionStyle(amplitude: 15),
    ),
  ),
)
```

**Common custom styles you can create:**

- Arc paths using `CubicSegment` for bezier curves
- Circuit/Manhattan routing with perpendicular `StraightSegment`s
- Spiral or custom mathematical curves
- Adaptive paths based on port positions and distance

## See Also

- [Connection Effects](/docs/theming/connection-effects) - Animate your
  connections
- [Connections](/docs/concepts/connections) - Understanding connections
- [Theming Overview](/docs/theming/overview) - Complete theming guide
