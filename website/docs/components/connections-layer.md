---
title: Connections Layer
description: Understanding connection rendering and the connections canvas
---

# Connections Layer

::: details Connections Layer Architecture
Layered diagram showing: Grid Layer (bottom), Connections Layer (CustomPaint), Connection Labels Layer (widgets), Nodes Layer, Annotations Layer (top). Arrows showing how connections are painted between node ports.
:::

The connections layer is responsible for rendering all connection lines between nodes. It uses efficient `CustomPainter` rendering for optimal performance with large graphs.

## Layer Architecture

The `NodeFlowEditor` renders content in distinct layers:

```
Top    → Annotations Layer (widgets)
       → Nodes Layer (widgets)
       → Connection Labels Layer (widgets)
       → Connections Layer (CustomPaint)
Bottom → Grid Layer (CustomPaint)
```

This separation ensures:
- **Performance**: Connections use `CustomPaint` for efficient rendering
- **Labels**: Connection labels are rendered as widgets for text quality
- **Interactivity**: Nodes and annotations have proper gesture handling
- **Layering**: Clear visual hierarchy

## ConnectionsCanvas

The `ConnectionsCanvas` is the `CustomPainter` that draws all connection lines:

```dart
// Used internally by NodeFlowEditor
CustomPaint(
  painter: ConnectionsCanvas<MyData>(
    store: controller,
    theme: theme,
    connectionPainter: sharedPainter,
    connections: null, // optional, defaults to all connections
    animation: animationController,
  ),
)
```

### Properties

| Property | Type | Description |
|----------|------|-------------|
| `store` | `NodeFlowController<T, dynamic>` | Source of connection data |
| `theme` | `NodeFlowTheme` | Visual styling |
| `connectionPainter` | `ConnectionPainter` | Shared painter for path caching |
| `connections` | `List<Connection>?` | Specific connections to render (defaults to all) |
| `animation` | `Animation<double>?` | Optional animation for effects |

### Rendering Process

For each connection, the painter:

1. Gets source and target nodes from controller
2. Calculates port positions based on node bounds
3. Determines connection style (bezier, smoothstep, etc.)
4. Computes the path through any control points
5. Draws the path with appropriate stroke and color
6. Draws endpoint markers (arrows, circles, etc.)

::: info
Labels are intentionally NOT rendered by the `ConnectionsCanvas`. They're rendered in a separate widget layer for better text quality and performance.

:::

## Connection Styles

::: details Connection Style Comparison
Four-panel comparison showing same connection with different styles: Smoothstep (orthogonal with rounded corners), Bezier (smooth S-curve), Step (sharp 90-degree turns), Straight (direct diagonal line).
:::

### Smoothstep (Recommended)

Smooth orthogonal paths that maintain horizontal/vertical segments with rounded corners:

```dart
// Use the built-in light or dark theme with smoothstep (default)
theme: NodeFlowTheme.light,

// Or customize the connection theme
theme: NodeFlowTheme.light.copyWith(
  connectionTheme: ConnectionTheme.light.copyWith(
    style: ConnectionStyles.smoothstep,
  ),
)
```

### Bezier

Flowing curved paths using cubic bezier curves:

```dart
theme: NodeFlowTheme.light.copyWith(
  connectionTheme: ConnectionTheme.light.copyWith(
    style: ConnectionStyles.bezier,
  ),
)
```

### Step

Sharp right-angle paths with no rounding:

```dart
theme: NodeFlowTheme.light.copyWith(
  connectionTheme: ConnectionTheme.light.copyWith(
    style: ConnectionStyles.step,
  ),
)
```

### Straight

Direct straight lines between ports:

```dart
theme: NodeFlowTheme.light.copyWith(
  connectionTheme: ConnectionTheme.light.copyWith(
    style: ConnectionStyles.straight,
  ),
)
```

## Connection Theming

Customize connection appearance through `ConnectionTheme`. Use the built-in `light` or `dark` themes and customize with `copyWith`:

```dart
NodeFlowTheme.light.copyWith(
  connectionTheme: ConnectionTheme.light.copyWith(
    // Style
    style: ConnectionStyles.smoothstep,

    // Colors
    color: Colors.blue,
    selectedColor: Colors.blue.shade700,
    highlightColor: Colors.blue.shade400,

    // Stroke
    strokeWidth: 2.0,
    selectedStrokeWidth: 3.0,

    // Dash pattern (null for solid)
    dashPattern: [8, 4],  // for dashed lines

    // Endpoints - use predefined constants
    startPoint: ConnectionEndPoint.none,
    endPoint: ConnectionEndPoint.triangle,

    // Geometry
    bezierCurvature: 0.5,
    cornerRadius: 4.0,
    portExtension: 20.0,
  ),
)
```

### Endpoint Shapes

Use the predefined `ConnectionEndPoint` constants:

| Constant | Description |
|----------|-------------|
| `ConnectionEndPoint.none` | No endpoint marker |
| `ConnectionEndPoint.triangle` | Arrow/triangle pointing in flow direction |
| `ConnectionEndPoint.circle` | Filled circle |
| `ConnectionEndPoint.diamond` | Diamond shape |
| `ConnectionEndPoint.rectangle` | Solid rectangle |
| `ConnectionEndPoint.capsuleHalf` | Rounded half-capsule (default for end) |

```dart
// Use predefined constants
endPoint: ConnectionEndPoint.triangle,
startPoint: ConnectionEndPoint.circle,

// Or create custom endpoints with MarkerShapes
endPoint: ConnectionEndPoint(
  shape: MarkerShapes.triangle,
  size: Size.square(8.0),
  color: Colors.blue,
  borderColor: Colors.blueAccent,
  borderWidth: 1.0,
)
```

## Per-Connection Styling

Override styles for individual connections:

### Using connectionStyleResolver

```dart
NodeFlowEditor<MyData, dynamic>(
  controller: controller,
  theme: theme,
  connectionStyleResolver: (connection) {
    // Style based on connection properties
    if (connection.label?.text.contains('error') ?? false) {
      return ConnectionStyleOverrides(
        color: Colors.red,
        selectedColor: Colors.red.shade700,
        strokeWidth: 3.0,
      );
    }

    // Style based on custom data
    final type = connection.data?['type'];
    if (type == 'conditional') {
      return ConnectionStyleOverrides(
        color: Colors.orange,
      );
    }

    return null;  // Use theme defaults
  },
  nodeBuilder: (context, node) => MyNodeWidget(node: node),
)
```

### ConnectionStyleOverrides

The `ConnectionStyleOverrides` class allows overriding these properties:

| Property | Type | Description |
|----------|------|-------------|
| `color` | `Color?` | Connection color when not selected |
| `selectedColor` | `Color?` | Connection color when selected |
| `strokeWidth` | `double?` | Stroke width when not selected |
| `selectedStrokeWidth` | `double?` | Stroke width when selected |

### Using Connection Properties

Connections can have per-instance style overrides via constructor parameters:

```dart
final connection = Connection(
  id: 'conn-1',
  sourceNodeId: 'node-1',
  sourcePortId: 'out',
  targetNodeId: 'node-2',
  targetPortId: 'in',
  // Override style, endpoints, or gaps
  style: ConnectionStyles.bezier,
  startPoint: ConnectionEndPoint.circle,
  endPoint: ConnectionEndPoint.triangle,
  startGap: 5.0,
  endGap: 5.0,
  // Add labels
  label: ConnectionLabel.center(text: 'Data Flow'),
);
```

## Temporary Connections

During connection creation, a temporary connection is displayed. Configure its appearance via `temporaryConnectionTheme`:

```dart
NodeFlowTheme.light.copyWith(
  temporaryConnectionTheme: ConnectionTheme.light.copyWith(
    color: Color(0xFF666666),
    dashPattern: [5, 5],  // Dashed line
    startPoint: ConnectionEndPoint.none,
    endPoint: ConnectionEndPoint.capsuleHalf,
  ),
)
```

The temporary connection:
- Starts from the source port
- Follows the cursor position
- Uses the temporary theme styling
- Disappears when released (replaced by actual connection or cancelled)

## Control Points

Connections support user-defined control points for manual routing. Control points are stored directly on the `Connection` object:

```dart
// Access control points on a connection
final connection = controller.getConnection('conn-1');
print(connection?.controlPoints); // ObservableList<Offset>

// Set control points directly
connection?.controlPoints = [
  Offset(300, 200),
  Offset(400, 250),
];
```

::: details Control Points
Connection with two control points creating a custom routing path. Control points shown as small circles that can be dragged. Before/after comparison showing automatic vs manual routing.
:::

## Connection Labels

Labels are rendered in a separate layer for optimal text quality. Each connection can have up to three labels:

```dart
Connection(
  id: 'conn-1',
  sourceNodeId: 'node-1',
  sourcePortId: 'out',
  targetNodeId: 'node-2',
  targetPortId: 'in',
  // Three label positions available
  startLabel: ConnectionLabel.start(text: 'Send'),      // anchor 0.0
  label: ConnectionLabel.center(text: 'Data Flow'),     // anchor 0.5
  endLabel: ConnectionLabel.end(text: 'Receive'),       // anchor 1.0
)
```

### ConnectionLabel

Labels support customizable positioning:

```dart
// Factory constructors for common positions
ConnectionLabel.start(text: 'Start', offset: 5.0)   // anchor 0.0
ConnectionLabel.center(text: 'Middle', offset: 0.0) // anchor 0.5
ConnectionLabel.end(text: 'End', offset: -5.0)      // anchor 1.0

// Custom anchor position (0.0 to 1.0)
ConnectionLabel(text: 'Custom', anchor: 0.25, offset: 10.0)
```

::: code-group

```dart [Label Theming]
NodeFlowTheme.light.copyWith(
  labelTheme: LabelTheme(
    textStyle: TextStyle(
      color: Colors.black87,
      fontSize: 12.0,
      fontWeight: FontWeight.w500,
    ),
    backgroundColor: Colors.white,
    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
    borderRadius: BorderRadius.all(Radius.circular(4.0)),
    border: Border.all(color: Colors.grey.shade300),
    labelGap: 8.0,  // Gap from endpoints at anchor 0.0 or 1.0
  ),
)
```

```dart [Custom Label Builder]
NodeFlowEditor<MyData, dynamic>(
  controller: controller,
  theme: theme,
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
          boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4)],
        ),
        child: Text(
          label.text,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  },
  nodeBuilder: (context, node) => MyNodeWidget(node: node),
)
```

:::

## Hit Testing

Connections support click/tap detection for selection:

```dart
NodeFlowEditor<MyData, dynamic>(
  controller: controller,
  theme: theme,
  events: NodeFlowEvents(
    connection: ConnectionEvents(
      onTap: (connection) {
        print('Clicked: ${connection.id}');
      },
      onDoubleTap: (connection) {
        _editConnectionLabel(connection);
      },
      onContextMenu: (connection, screenPosition) {
        _showConnectionMenu(connection, screenPosition);
      },
      onMouseEnter: (connection) {
        print('Hovering: ${connection.id}');
      },
      onMouseLeave: (connection) {
        print('Left: ${connection.id}');
      },
    ),
  ),
  nodeBuilder: (context, node) => MyNodeWidget(node: node),
)
```

The hit testing uses path distance calculations to detect clicks near the connection line. Hit tolerance is configured via `ConnectionTheme.hitTolerance`.

## Performance Considerations

The connections layer is optimized for performance:

1. **Path Caching**: Connection paths are cached and reused
2. **Shared Painter**: A single `ConnectionPainter` instance is reused
3. **Viewport Clipping**: `InteractiveViewer` handles visibility
4. **Separate Label Layer**: Text is rendered separately to avoid repaint issues

### Large Graphs

For graphs with 100+ connections:

- Use simpler connection styles (straight or step)
- Minimize dash patterns
- Consider hiding labels at low zoom levels
- Use connection effects sparingly

## Animated Connections

Connections can be animated using effects. Set effects on individual connections or via the theme:

```dart
// Use built-in effect constants
connection.animationEffect = ConnectionEffects.flowingDash;
connection.animationEffect = ConnectionEffects.particles;
connection.animationEffect = ConnectionEffects.gradientFlow;
connection.animationEffect = ConnectionEffects.pulse;

// Create custom effects
connection.animationEffect = FlowingDashEffect(
  speed: 2.0,
  dashLength: 10.0,
  gapLength: 5.0,
);

connection.animationEffect = ParticleEffect(
  particleCount: 5,
  speed: 1.5,
);

connection.animationEffect = PulseEffect(
  speed: 2.0,
  minOpacity: 0.3,
  maxOpacity: 1.0,
);

// Or set default effect in theme
NodeFlowTheme.light.copyWith(
  connectionTheme: ConnectionTheme.light.copyWith(
    animationEffect: ConnectionEffects.flowingDash,
  ),
)
```

### Available Effect Types

| Effect | Description |
|--------|-------------|
| `FlowingDashEffect` | Animated dashed line flowing along the path |
| `ParticleEffect` | Particles moving along the connection |
| `GradientFlowEffect` | Animated gradient flowing along the path |
| `PulseEffect` | Pulsing/glowing opacity and width animation |

### Effect Presets

The `ConnectionEffects` class provides ready-to-use presets:

```dart
ConnectionEffects.flowingDash      // Standard flowing dashes
ConnectionEffects.flowingDashFast  // Fast flowing dashes
ConnectionEffects.particles        // Circle particles
ConnectionEffects.particlesArrow   // Arrow-shaped particles
ConnectionEffects.gradientFlow     // Rainbow gradient
ConnectionEffects.gradientFlowBlue // Blue-cyan gradient
ConnectionEffects.pulse            // Standard pulse
ConnectionEffects.pulseSubtle      // Subtle pulse effect
```

See [Connection Effects](/docs/theming/connection-effects) for more details.

## Best Practices

1. **Consistent Styling**: Use theme for consistent connection appearance
2. **Meaningful Colors**: Color-code connections by type or status
3. **Clear Labels**: Use labels sparingly to avoid clutter
4. **Arrow Direction**: Use arrows to show data flow direction
5. **Selection Feedback**: Ensure selected connections are clearly visible
6. **Performance**: Test with realistic connection counts

## See Also

- [Connections (Core Concepts)](/docs/concepts/connections) - Connection model and operations
- [Connection Styles](/docs/theming/connection-styles) - Style options
- [Connection Effects](/docs/theming/connection-effects) - Animation effects
- [Events](/docs/advanced/events) - Connection event handling
