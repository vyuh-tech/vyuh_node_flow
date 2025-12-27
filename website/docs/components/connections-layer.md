---
title: Connections Layer
description: Understanding connection rendering and the connections canvas
---

# Connections Layer

::: details 🖼️ Connections Layer Architecture
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
    animation: animationController,
  ),
)
```

### Properties

| Property | Type | Description |
|----------|------|-------------|
| `store` | `NodeFlowController<T>` | Source of connection data |
| `theme` | `NodeFlowTheme` | Visual styling |
| `connectionPainter` | `ConnectionPainter` | Shared painter for path caching |
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

::: details 🖼️ Connection Style Comparison
Four-panel comparison showing same connection with different styles: Smoothstep (orthogonal with rounded corners), Bezier (smooth S-curve), Step (sharp 90-degree turns), Straight (direct diagonal line).
:::

### Smoothstep (Recommended)

Smooth orthogonal paths that maintain horizontal/vertical segments with rounded corners:

```dart
theme: NodeFlowTheme(
  connectionTheme: ConnectionTheme(
    style: ConnectionStyles.smoothstep,
  ),
)
```

### Bezier

Flowing curved paths using cubic bezier curves:

```dart
theme: NodeFlowTheme(
  connectionTheme: ConnectionTheme(
    style: ConnectionStyles.bezier,
  ),
)
```

### Step

Sharp right-angle paths with no rounding:

```dart
theme: NodeFlowTheme(
  connectionTheme: ConnectionTheme(
    style: ConnectionStyles.step,
  ),
)
```

### Straight

Direct straight lines between ports:

```dart
theme: NodeFlowTheme(
  connectionTheme: ConnectionTheme(
    style: ConnectionStyles.straight,
  ),
)
```

## Connection Theming

Customize connection appearance through `ConnectionTheme`:

```dart
NodeFlowTheme(
  connectionTheme: ConnectionTheme(
    // Style
    style: ConnectionStyles.smoothstep,

    // Colors
    color: Colors.blue,
    selectedColor: Colors.blue.shade700,

    // Stroke
    strokeWidth: 2.0,
    selectedStrokeWidth: 3.0,

    // Dash pattern (null for solid)
    dashPattern: null,  // or [8, 4] for dashed

    // Endpoints
    startPoint: ConnectionEndPoint.none,
    endPoint: ConnectionEndPoint(
      shape: EndpointShape.triangle,
      size: 10,
      color: Colors.blue,
    ),
  ),
)
```

### Endpoint Shapes

| Shape | Description |
|-------|-------------|
| `EndpointShape.none` | No endpoint marker |
| `EndpointShape.triangle` | Arrow/triangle pointing in flow direction |
| `EndpointShape.circle` | Filled circle |
| `EndpointShape.diamond` | Diamond shape |

```dart
// Arrow at end
endPoint: ConnectionEndPoint(
  shape: EndpointShape.triangle,
  size: 10,
  color: Colors.blue,
)

// Circle at start
startPoint: ConnectionEndPoint(
  shape: EndpointShape.circle,
  size: 6,
  color: Colors.grey,
)
```

## Per-Connection Styling

Override styles for individual connections:

### Using connectionStyleResolver

```dart
NodeFlowEditor<MyData>(
  controller: controller,
  theme: theme,
  connectionStyleResolver: (connection) {
    // Style based on connection properties
    if (connection.label?.text?.contains('error') ?? false) {
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
        dashPattern: [8, 4],
        color: Colors.orange,
      );
    }

    return null;  // Use theme defaults
  },
  nodeBuilder: (context, node) => MyNodeWidget(node: node),
)
```

### Using Connection Properties

Connections can have inline style overrides:

```dart
final connection = Connection(
  id: 'conn-1',
  sourceNodeId: 'node-1',
  sourcePortId: 'out',
  targetNodeId: 'node-2',
  targetPortId: 'in',
  color: Colors.red,  // Override theme color
  label: ConnectionLabel.center(text: 'Error Path'),
);
```

## Temporary Connections

During connection creation, a temporary connection is displayed:

```dart
NodeFlowTheme(
  temporaryConnectionStyle: ConnectionStyles.smoothstep,
  temporaryConnectionTheme: ConnectionTheme(
    color: Colors.blue.withOpacity(0.5),
    strokeWidth: 2,
    dashPattern: [8, 4],  // Dashed line
    endPoint: ConnectionEndPoint(
      shape: EndpointShape.triangle,
      size: 9,
    ),
  ),
)
```

The temporary connection:
- Starts from the source port
- Follows the cursor position
- Uses the temporary theme styling
- Disappears when released (replaced by actual connection or cancelled)

## Control Points

Connections support user-defined control points for manual routing:

```dart
// Add a control point
controller.addControlPoint('conn-1', Offset(300, 200), index: 0);

// Update a control point
controller.updateControlPoint('conn-1', 0, Offset(320, 220));

// Remove a control point
controller.removeControlPoint('conn-1', 0);

// Clear all control points
controller.clearControlPoints('conn-1');
```

::: details 🖼️ Control Points
Connection with two control points creating a custom routing path. Control points shown as small circles that can be dragged. Before/after comparison showing automatic vs manual routing.
:::

## Connection Labels

Labels are rendered in a separate layer for optimal text quality:

```dart
Connection(
  id: 'conn-1',
  sourceNodeId: 'node-1',
  sourcePortId: 'out',
  targetNodeId: 'node-2',
  targetPortId: 'in',
  label: ConnectionLabel.center(text: 'Data Flow'),
  startLabel: ConnectionLabel.start(text: 'Send'),
  endLabel: ConnectionLabel.end(text: 'Receive'),
)
```

::: code-group

```dart [Label Theming]
NodeFlowTheme(
  labelTheme: LabelTheme(
    fontSize: 12,
    color: Colors.black87,
    backgroundColor: Colors.white,
    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    borderRadius: 4,
    border: Border.all(color: Colors.grey.shade300),
  ),
)
```

```dart [Custom Label Builder]
NodeFlowEditor<MyData>(
  controller: controller,
  theme: theme,
  labelBuilder: (context, connection, label, position) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: _getLabelColor(connection),
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
    );
  },
  nodeBuilder: (context, node) => MyNodeWidget(node: node),
)
```

:::

## Hit Testing

Connections support click/tap detection for selection:

```dart
events: NodeFlowEvents(
  connection: ConnectionEvents(
    onTap: (connection) {
      print('Clicked: ${connection.id}');
      controller.selectConnection(connection.id);
    },
    onDoubleTap: (connection) {
      _editConnectionLabel(connection);
    },
    onContextMenu: (connection, position) {
      _showConnectionMenu(connection, position);
    },
  ),
)
```

The hit testing uses path distance calculations to detect clicks near the connection line.

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

Connections can be animated using effects:

```dart
// Animated flow effect on a connection
connection.effect = ConnectionEffect.flow(
  color: Colors.blue,
  speed: 1.0,
);

// Pulse effect
connection.effect = ConnectionEffect.pulse(
  color: Colors.green,
  frequency: 2.0,
);
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

- [Connections (Core Concepts)](/docs/core-concepts/connections) - Connection model and operations
- [Connection Styles](/docs/theming/connection-styles) - Style options
- [Connection Effects](/docs/theming/connection-effects) - Animation effects
- [Events](/docs/advanced/events) - Connection event handling
