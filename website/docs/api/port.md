---
title: Port
description: API reference for the Port class
---

# Port

The `Port` class represents a connection point on a node. Ports are where connections begin and end, defining how nodes can be linked together.

## Constructor

```dart
const Port({
  required String id,
  required String name,
  bool multiConnections = false,
  PortPosition position = PortPosition.left,
  Offset offset = Offset.zero,
  PortType type = PortType.both,
  MarkerShape? shape,
  Size? size,
  String? tooltip,
  bool isConnectable = true,
  int? maxConnections,
  bool showLabel = false,
})
```

## Properties

| Property | Type | Default | Description |
|----------|------|---------|-------------|
| `id` | `String` | required | Unique identifier within the node |
| `name` | `String` | required | Display label |
| `multiConnections` | `bool` | `false` | Whether multiple connections are allowed |
| `position` | `PortPosition` | `left` | Side of the node |
| `offset` | `Offset` | `Offset.zero` | Position offset for precise placement |
| `type` | `PortType` | inferred | Direction: input or output (inferred from position if not set) |
| `shape` | `MarkerShape?` | `null` | Visual shape (falls back to theme) |
| `size` | `Size?` | `null` | Port dimensions (falls back to theme) |
| `tooltip` | `String?` | `null` | Tooltip text on hover |
| `isConnectable` | `bool` | `true` | Whether connections can be made |
| `maxConnections` | `int?` | `null` | Maximum connections (null = unlimited) |
| `showLabel` | `bool` | `false` | Whether to display the port's label |

## PortPosition

Where the port appears on the node:

| Position | Description |
|----------|-------------|
| `PortPosition.left` | Left edge (default) |
| `PortPosition.right` | Right edge |
| `PortPosition.top` | Top edge |
| `PortPosition.bottom` | Bottom edge |

::: info
Input ports are typically on the left, output ports on the right. But you can place them anywhere.

:::

## PortType

Direction of data flow for the port:

| Type | Description |
|------|-------------|
| `PortType.input` | Input only - can receive connections |
| `PortType.output` | Output only - can emit connections |

::: info
Port type is automatically inferred from position if not specified:
- Left/Top positions default to `input`
- Right/Bottom positions default to `output`
:::

## Computed Properties

| Property | Type | Description |
|----------|------|-------------|
| `isOutput` | `bool` | Whether this port can act as an output (source) |
| `isInput` | `bool` | Whether this port can act as an input (target) |

## Port Offset

The `offset` property controls precise port positioning within the node.

For **left/right** ports:
- `offset.dy` specifies the vertical center position (distance from top)
- `offset.dx` adjusts horizontal position from the edge

For **top/bottom** ports:
- `offset.dx` specifies the horizontal center position (distance from left)
- `offset.dy` adjusts vertical position from the edge

**Example for a 150x100 node:**
```dart
// Right port centered vertically at 50 (middle of node)
Port(id: 'out', name: 'Output', position: PortPosition.right, offset: Offset(0, 50))

// Top port centered horizontally at 75 (middle of node width)
Port(id: 'in', name: 'Input', position: PortPosition.top, offset: Offset(75, 0))

// Two right ports at 1/3 and 2/3 height
Port(id: 'out1', name: 'Out 1', position: PortPosition.right, offset: Offset(0, 33))
Port(id: 'out2', name: 'Out 2', position: PortPosition.right, offset: Offset(0, 67))
```

## Examples

::: code-group

```dart [Basic]
final node = Node<MyData>(
  id: 'node-1',
  type: 'process',
  position: Offset(100, 100),
  data: MyData(),
  inputPorts: [
    Port(id: 'in-1', name: 'Input'),
  ],
  outputPorts: [
    Port(id: 'out-1', name: 'Output', position: PortPosition.right),
  ],
);
```

```dart [With Labels]
final node = Node<ProcessData>(
  id: 'process',
  type: 'processor',
  position: Offset(100, 100),
  size: Size(180, 120),
  data: ProcessData(),
  inputPorts: [
    Port(
      id: 'data-in',
      name: 'Data',
      position: PortPosition.left,
      showLabel: true,
    ),
    Port(
      id: 'config-in',
      name: 'Config',
      position: PortPosition.top,
      showLabel: true,
    ),
  ],
  outputPorts: [
    Port(
      id: 'result-out',
      name: 'Result',
      position: PortPosition.right,
      showLabel: true,
    ),
    Port(
      id: 'error-out',
      name: 'Error',
      position: PortPosition.bottom,
      showLabel: true,
    ),
  ],
);
```

```dart [Custom Configuration]
final node = Node<TypedData>(
  id: 'typed-node',
  type: 'typed',
  position: Offset(100, 100),
  size: Size(200, 100),
  data: TypedData(),
  inputPorts: [
    Port(
      id: 'string-in',
      name: 'String',
      type: PortType.target,
      multiConnections: true,
      maxConnections: 5,
      tooltip: 'Accepts up to 5 string connections',
    ),
    Port(
      id: 'number-in',
      name: 'Number',
      type: PortType.target,
      shape: MarkerShapes.diamond,
      size: Size(12, 12),
    ),
  ],
  outputPorts: [
    Port(
      id: 'any-out',
      name: 'Output',
      type: PortType.source,
      position: PortPosition.right,
    ),
  ],
);
```

:::

## Connection Limits

Control how many connections a port can have:

```dart
// Single connection only
Port(
  id: 'trigger',
  name: 'Trigger',
  multiConnections: false, // Default - one connection max
)

// Multiple connections with limit
Port(
  id: 'inputs',
  name: 'Inputs',
  multiConnections: true,
  maxConnections: 5, // Up to 5 connections
)

// Unlimited connections
Port(
  id: 'broadcast',
  name: 'Broadcast',
  multiConnections: true,
  maxConnections: null, // No limit
)
```

## MarkerShape

Port shapes are defined using the `MarkerShape` abstract class. Built-in shapes are available through `MarkerShapes`:

```dart
// Use built-in shapes
Port(id: 'port', name: 'Port', shape: MarkerShapes.circle)
Port(id: 'port', name: 'Port', shape: MarkerShapes.diamond)
Port(id: 'port', name: 'Port', shape: MarkerShapes.triangle)
Port(id: 'port', name: 'Port', shape: MarkerShapes.square)
Port(id: 'port', name: 'Port', shape: MarkerShapes.capsuleHalf)
```

::: tip
If no shape is specified, the port uses the shape from `PortTheme.shape` (default: `capsuleHalf`).

:::

## Methods

### copyWith

Create a copy with updated properties.

```dart
Port copyWith({
  String? id,
  String? name,
  bool? multiConnections,
  PortPosition? position,
  Offset? offset,
  PortType? type,
  MarkerShape? shape,
  Size? size,
  String? tooltip,
  bool? isConnectable,
  int? maxConnections,
  bool? showLabel,
})
```

**Example:**
```dart
final updatedPort = port.copyWith(
  name: 'Updated Name',
  multiConnections: true,
);
```

### toJson

Serialize to JSON.

```dart
Map<String, dynamic> toJson()
```

### fromJson

Create from JSON.

```dart
factory Port.fromJson(Map<String, dynamic> json)
```

## Port Styling

Configure port appearance through `PortTheme`:

```dart
NodeFlowTheme(
  portTheme: PortTheme(
    size: Size(9, 9),
    color: Colors.grey,
    connectedColor: Colors.blue,
    highlightColor: Colors.lightBlue,
    highlightBorderColor: Colors.black,
    borderColor: Colors.white,
    borderWidth: 0,
    shape: MarkerShapes.capsuleHalf,
    showLabel: false,
    labelTextStyle: TextStyle(fontSize: 10),
    labelOffset: 4.0,
  ),
)
```

| Property | Description |
|----------|-------------|
| `size` | Port dimensions (Size, not double) |
| `color` | Default fill color |
| `connectedColor` | Color when port has connections |
| `highlightColor` | Fill color when port is highlighted during connection drag |
| `highlightBorderColor` | Border color when port is highlighted |
| `borderColor` | Border outline color |
| `borderWidth` | Border thickness |
| `shape` | Default marker shape |
| `showLabel` | Global label visibility |
| `labelTextStyle` | Text style for labels |
| `labelOffset` | Distance from port to label |

See [Port Shapes](/docs/theming/port-shapes) and [Port Labels](/docs/theming/port-labels) for more styling details.

## Best Practices

1. **Unique IDs**: Port IDs should be unique within a node, often prefixed with node ID
2. **Clear Names**: Use descriptive names that explain the port's purpose
3. **Consistent Positioning**: Follow conventions (inputs left, outputs right)
4. **Type Indication**: Use shapes or tooltips to indicate data types
5. **Limit Connections**: Set `maxConnections` when appropriate
6. **Connectable Flag**: Use `isConnectable: false` for display-only ports
