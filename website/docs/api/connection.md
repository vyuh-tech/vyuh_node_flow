---
title: Connection
description: API reference for the Connection class
---

# Connection

The `Connection` class represents a visual link between two ports on different
nodes. Connections support styling, labels, animation, and use MobX observables
for reactive state management.

## Constructor

```dart
Connection({
  required String id,
  required String sourceNodeId,
  required String sourcePortId,
  required String targetNodeId,
  required String targetPortId,
  bool animated = false,
  bool selected = false,
  Map<String, dynamic>? data,
  ConnectionStyle? style,
  ConnectionLabel? startLabel,
  ConnectionLabel? label,
  ConnectionLabel? endLabel,
  ConnectionEndPoint? startPoint,
  ConnectionEndPoint? endPoint,
  double? startGap,
  double? endGap,
  ConnectionEffect? animationEffect,
  List<Offset>? controlPoints,
  bool locked = false,
})
```

## Properties

### Required Properties

| Property       | Type     | Description       |
| -------------- | -------- | ----------------- |
| `id`           | `String` | Unique identifier |
| `sourceNodeId` | `String` | Source node ID    |
| `sourcePortId` | `String` | Source port ID    |
| `targetNodeId` | `String` | Target node ID    |
| `targetPortId` | `String` | Target port ID    |

### Optional Properties

| Property          | Type                    | Default | Description                  |
| ----------------- | ----------------------- | ------- | ---------------------------- |
| `animated`        | `bool`                  | `false` | Show flowing animation       |
| `selected`        | `bool`                  | `false` | Selection state              |
| `data`            | `Map<String, dynamic>?` | `null`  | Custom metadata              |
| `style`           | `ConnectionStyle?`      | `null`  | Line style override          |
| `startLabel`      | `ConnectionLabel?`      | `null`  | Label at source (anchor 0.0) |
| `label`           | `ConnectionLabel?`      | `null`  | Label at center (anchor 0.5) |
| `endLabel`        | `ConnectionLabel?`      | `null`  | Label at target (anchor 1.0) |
| `startPoint`      | `ConnectionEndPoint?`   | `null`  | Start marker override        |
| `endPoint`        | `ConnectionEndPoint?`   | `null`  | End marker override          |
| `startGap`        | `double?`               | `null`  | Gap from source port         |
| `endGap`          | `double?`               | `null`  | Gap from target port         |
| `animationEffect` | `ConnectionEffect?`     | `null`  | Animation effect             |
| `controlPoints`   | `List<Offset>?`         | `[]`    | User-defined waypoints       |
| `locked`          | `bool`                  | `false` | Prevents deletion when true  |

::: info Properties like `animated`, `selected`, and labels are MobX
observables. Changes trigger automatic UI updates.

:::

## Observable Properties

The following properties are reactive and can be modified after construction:

```dart
// Get/set animation state
connection.animated = true;

// Get/set selection state
connection.selected = true;

// Get/set labels (use ConnectionLabel objects)
connection.startLabel = ConnectionLabel.start(text: 'Begin');
connection.label = ConnectionLabel.center(text: 'Data Flow');
connection.endLabel = ConnectionLabel.end(text: 'End');

// Get/set animation effect
connection.animationEffect = FlowingDashEffect();

// Get/set control points
connection.controlPoints = [Offset(300, 200), Offset(400, 200)];
```

## ConnectionLabel

Labels are `ConnectionLabel` objects, not plain strings. Use the factory
constructors:

```dart
// Label at start (anchor 0.0)
ConnectionLabel.start(text: 'Start', offset: 10.0)

// Label at center (anchor 0.5)
ConnectionLabel.center(text: 'Data Flow')

// Label at end (anchor 1.0)
ConnectionLabel.end(text: 'End', offset: 10.0)

// Custom anchor position
ConnectionLabel(text: 'Custom', anchor: 0.25)
```

### labels Property

Get all non-null labels as a list:

```dart
List<ConnectionLabel> get labels
```

## Examples

::: code-group

```dart [Basic]
final connection = Connection(
  id: 'conn-1',
  sourceNodeId: 'node-1',
  sourcePortId: 'out-1',
  targetNodeId: 'node-2',
  targetPortId: 'in-1',
);
controller.addConnection(connection);
```

```dart [With Labels]
final connection = Connection(
  id: 'conn-2',
  sourceNodeId: 'sender',
  sourcePortId: 'output',
  targetNodeId: 'receiver',
  targetPortId: 'input',
  startLabel: ConnectionLabel.start(text: 'Send'),
  label: ConnectionLabel.center(text: 'Data Flow'),
  endLabel: ConnectionLabel.end(text: 'Receive'),
);
```

```dart [Custom Style]
final connection = Connection(
  id: 'conn-3',
  sourceNodeId: 'a',
  sourcePortId: 'out',
  targetNodeId: 'b',
  targetPortId: 'in',
  style: ConnectionStyles.bezier,
  startPoint: ConnectionEndPoint.none,
  endPoint: ConnectionEndPoint.triangle,
  animated: true,
  data: {'type': 'dataflow', 'priority': 1},
);
```

:::

## Methods

### Query Methods

#### involvesNode

Check if this connection involves a specific node.

```dart
bool involvesNode(String nodeId)
```

**Example:**

```dart
if (connection.involvesNode('node-a')) {
  print('Connection involves node-a');
}
```

#### involvesPort

Check if this connection involves a specific node and port combination.

```dart
bool involvesPort(String nodeId, String portId)
```

### Effective Style Methods

Get the actual style to use, falling back to theme defaults:

```dart
// Get effective connection style
ConnectionStyle getEffectiveStyle(ConnectionStyle themeStyle)

// Get effective start endpoint
ConnectionEndPoint getEffectiveStartPoint(ConnectionEndPoint themeStartPoint)

// Get effective end endpoint
ConnectionEndPoint getEffectiveEndPoint(ConnectionEndPoint themeEndPoint)

// Get effective animation effect
ConnectionEffect? getEffectiveAnimationEffect(ConnectionEffect? themeEffect)
```

**Example:**

```dart
final style = connection.getEffectiveStyle(theme.connectionTheme.style);
final endPoint = connection.getEffectiveEndPoint(theme.connectionTheme.endPoint);
```

### Serialization

#### toJson

Serialize to JSON. Labels and control points are included automatically.

```dart
Map<String, dynamic> toJson()
```

#### fromJson

Create from JSON. Labels and control points are deserialized automatically.

```dart
factory Connection.fromJson(Map<String, dynamic> json)
```

## ConnectionStyle

Built-in connection line styles via `ConnectionStyles`:

| Style                         | Description                 |
| ----------------------------- | --------------------------- |
| `ConnectionStyles.straight`   | Direct line                 |
| `ConnectionStyles.bezier`     | Curved Bezier               |
| `ConnectionStyles.step`       | Right-angle segments        |
| `ConnectionStyles.smoothstep` | Smooth orthogonal (default) |

**Example:**

```dart
Connection(
  id: 'conn',
  sourceNodeId: 'a',
  sourcePortId: 'out',
  targetNodeId: 'b',
  targetPortId: 'in',
  style: ConnectionStyles.bezier,
)
```

## ConnectionEndPoint

Markers at connection endpoints. Built-in options:

```dart
// No marker
ConnectionEndPoint.none

// Capsule half (default for end)
ConnectionEndPoint.capsuleHalf

// Triangle arrow
ConnectionEndPoint.triangle

// Custom marker
ConnectionEndPoint(
  shape: MarkerShapes.diamond,
  size: Size(10, 10),
  color: Colors.blue,
  borderColor: Colors.black,
  borderWidth: 1.0,
)
```

## Animation Effects

Animate connections using `ConnectionEffect` subclasses:

```dart
// Flowing dashes
connection.animationEffect = FlowingDashEffect(
  speed: 2.0,
  dashLength: 10.0,
  gapLength: 5.0,
);

// Particles along path
connection.animationEffect = ParticleEffect();

// Gradient flow
connection.animationEffect = GradientFlowEffect();

// Pulsing glow
connection.animationEffect = PulseEffect();
```

## Control Points

Add user-defined waypoints for custom routing:

```dart
// Set control points
connection.controlPoints = [
  Offset(300, 200),
  Offset(400, 200),
  Offset(400, 300),
];

// Clear control points
connection.controlPoints = [];
```

::: tip Control points are used by editable connection styles to let users
customize connection paths.

:::

## Connection Operations

::: code-group

```dart [Add Connection]
controller.addConnection(connection);
```

```dart [Remove Connection]
controller.removeConnection('conn-1');
```

```dart [Get Connections]
// All connections
final all = controller.connections;

// For a node
final nodeConns = controller.getConnectionsForNode('node-1');
```

```dart [Modify Labels]
// Update via observable property
final conn = controller.getConnection('conn-1');
if (conn != null) {
  conn.label = ConnectionLabel.center(text: 'Updated Label');
}
```

:::

## Connection Styling

Configure appearance through `ConnectionTheme`:

```dart
NodeFlowTheme(
  connectionTheme: ConnectionTheme(
    style: ConnectionStyles.smoothstep,
    color: Colors.grey,
    selectedColor: Colors.blue,
    strokeWidth: 2.0,
    selectedStrokeWidth: 3.0,
    dashPattern: null, // Solid line
    startPoint: ConnectionEndPoint.none,
    endPoint: ConnectionEndPoint.capsuleHalf,
    endpointColor: Colors.grey,
    endpointBorderColor: Colors.white,
    endpointBorderWidth: 0,
    bezierCurvature: 0.5,
    cornerRadius: 4.0,
    portPlugin: 20.0,
    backEdgeGap: 20.0,
    hitTolerance: 8.0,
    startGap: 0.0,
    endGap: 0.0,
  ),
)
```

See [Connection Styles](/docs/theming/connection-styles) and
[Connection Effects](/docs/theming/connection-effects) for more.

## Validation

Validate connections before creation using events:

```dart
events: NodeFlowEvents(
  connection: ConnectionEvents(
    onBeforeComplete: (context) {
      // Prevent self-connections
      if (context.isSelfConnection) {
        return ConnectionValidationResult.deny(
          reason: 'Cannot connect to same node',
          showMessage: true,
        );
      }

      // Ensure output-to-input direction
      if (!context.isOutputToInput) {
        return ConnectionValidationResult.deny(
          reason: 'Must connect output to input',
        );
      }

      return ConnectionValidationResult.allow();
    },
  ),
)
```

## Best Practices

1. **Unique IDs**: Use timestamps or UUIDs for connection IDs
2. **Validation**: Always validate before adding connections
3. **Cleanup**: Connections are auto-removed when nodes are deleted
4. **Labels**: Use labels sparingly to avoid visual clutter
5. **Styling**: Use consistent colors to indicate connection types
6. **Animation**: Use animation effects for active data flow indication
