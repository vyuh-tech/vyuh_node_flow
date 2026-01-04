---
title: Ports
description: Understanding ports - connection points on nodes
---

# Ports

Ports are connection points on nodes where edges can be attached. They define how nodes can connect to each other in your graph.

## Port Structure

```dart
class Port {
  final String id;               // Unique identifier
  final String name;             // Display name
  final PortPosition position;   // left, right, top, bottom
  final PortType type;           // input or output
  final Offset offset;           // Position where the CENTER of the port should be
  final bool multiConnections;   // Allow multiple connections
  final int? maxConnections;     // Maximum connections allowed (null = unlimited)
  final MarkerShape? shape;      // Custom shape (null = use theme default)
  final Size? size;              // Custom size (null = use theme default)
  final String? tooltip;         // Optional tooltip text
  final bool isConnectable;      // Whether connections can be made (default: true)
  final bool showLabel;          // Whether to display the port's label
}
```

## Port Anatomy

::: details Port Anatomy Diagram
<!-- TODO: Add visual diagram showing port anatomy -->
A port consists of the following visual elements:

**Shape Elements:**
- **Marker Shape** - The port indicator using `MarkerShapes` (circle, capsuleHalf, triangle, diamond, rectangle)
- **Port Fill** - Interior color using `PortTheme.color` or `PortTheme.connectedColor`
- **Port Border** - Outline (implicit in shape rendering)

**Label Elements:**
- **Port Label** - Text label when `showLabel: true`, styled with `PortTheme.labelTextStyle`
- **Label Offset** - Position adjustment via `PortTheme.labelOffset`

**State Colors:**
- **Default State** - Normal color using `PortTheme.color`
- **Connected State** - When port has connections using `PortTheme.connectedColor`
- **Highlighted State** - During connection drag using `PortTheme.highlightColor`
- **Highlight Border** - Border emphasis using `PortTheme.highlightBorderColor`

**Sizing:**
- **Port Size** - Dimensions using `PortTheme.size` or port-specific `Port.size`
- **Default Size** - `Size(9, 9)` if not specified
:::

## Port Positions

Ports can be positioned on any side of a node:

```dart
enum PortPosition {
  left,   // Left edge of node
  right,  // Right edge of node
  top,    // Top edge of node
  bottom, // Bottom edge of node
}
```

### Positioning Examples

```dart
// Port on the left side (input by convention)
Port(
  id: 'input-port',
  name: 'Input',
  position: PortPosition.left,
  type: PortType.input,
)

// Port on the right side (output by convention)
Port(
  id: 'output-port',
  name: 'Output',
  position: PortPosition.right,
  type: PortType.output,
)

// Port on top (input by convention)
Port(
  id: 'trigger-port',
  name: 'Trigger',
  position: PortPosition.top,
  type: PortType.input,
)

// Port on bottom (output by convention)
Port(
  id: 'result-port',
  name: 'Result',
  position: PortPosition.bottom,
  type: PortType.output,
)
```

Note: Port type is automatically inferred from position if not specified:
- Left/Top ports default to `PortType.input`
- Right/Bottom ports default to `PortType.output`

## Port Types

Ports have two types that control connection direction:

```dart
enum PortType {
  input,   // Can only receive connections
  output,  // Can only emit connections
}
```

### Output Ports

Output ports emit connections to other nodes:

```dart
Port(
  id: 'out-1',
  name: 'Output',
  position: PortPosition.right,
  type: PortType.output,
)
```

### Input Ports

Input ports receive connections from other nodes:

```dart
Port(
  id: 'in-1',
  name: 'Input',
  position: PortPosition.left,
  type: PortType.input,
)
```

## Port Offsets

The offset specifies where the CENTER of the port should be positioned:

- **Left/Right ports**: `offset.dy` is the vertical center position (distance from top of node). `offset.dx` adjusts the horizontal position from the edge.
- **Top/Bottom ports**: `offset.dx` is the horizontal center position (distance from left of node). `offset.dy` adjusts the vertical position from the edge.

```dart
// For a 150x100 node:

// Right port centered vertically at 50 (middle of node height)
Port(
  id: 'port-1',
  name: 'Port 1',
  position: PortPosition.right,
  type: PortType.output,
  offset: Offset(0, 50),
)

// Top port centered horizontally at 75 (middle of node width)
Port(
  id: 'port-2',
  name: 'Port 2',
  position: PortPosition.top,
  type: PortType.input,
  offset: Offset(75, 0),
)

// Two right ports at 1/3 and 2/3 height of a 100px tall node
Port(
  id: 'port-3',
  name: 'Port 3',
  position: PortPosition.right,
  type: PortType.output,
  offset: Offset(0, 33),
)

Port(
  id: 'port-4',
  name: 'Port 4',
  position: PortPosition.right,
  type: PortType.output,
  offset: Offset(0, 67),
)
```

### Multiple Ports with Offsets

Create evenly spaced ports based on node height:

```dart
List<Port> createMultipleOutputPorts(int count, String nodeId, double nodeHeight) {
  final ports = <Port>[];
  final spacing = nodeHeight / (count + 1);

  for (int i = 0; i < count; i++) {
    ports.add(
      Port(
        id: '$nodeId-out-$i',
        name: 'Output $i',
        position: PortPosition.right,
        type: PortType.output,
        offset: Offset(0, spacing * (i + 1)),
      ),
    );
  }

  return ports;
}

// Usage for a node with 120px height
final node = Node(
  id: 'multi-output',
  // ...
  outputPorts: createMultipleOutputPorts(4, 'multi-output', 120.0),
);
```

## Multi-Connections

Control whether a port can have multiple connections:

```dart
// Single connection only (default behavior)
Port(
  id: 'single-out',
  name: 'Output',
  position: PortPosition.right,
  type: PortType.output,
  multiConnections: false,
)

// Allow multiple connections
Port(
  id: 'multi-in',
  name: 'Input',
  position: PortPosition.left,
  type: PortType.input,
  multiConnections: true,
)

// Allow multiple connections with a limit
Port(
  id: 'limited-in',
  name: 'Limited Input',
  position: PortPosition.left,
  type: PortType.input,
  multiConnections: true,
  maxConnections: 5, // Maximum 5 connections allowed
)
```

## Common Port Patterns

::: details 🖼️ Common Port Patterns
Four-panel diagram showing: (1) Simple Flow - one input left, one output right, (2) Conditional - one input, two outputs (True/False), (3) Merge - multiple inputs left, one output right, (4) Split - one input, multiple outputs. Each with sample connection lines showing data flow direction.
:::

::: code-group

```dart [Simple Flow Node]
// Input on left, output on right
final flowNode = Node<MyData>(
  id: 'flow-node',
  type: 'process',
  position: Offset(200, 100),
  size: Size(150, 80),
  data: MyData(label: 'Process'),
  inputPorts: [
    Port(
      id: 'flow-in',
      name: 'Input',
      position: PortPosition.left,
      type: PortType.input,
    ),
  ],
  outputPorts: [
    Port(
      id: 'flow-out',
      name: 'Output',
      position: PortPosition.right,
      type: PortType.output,
    ),
  ],
);
```

```dart [Conditional Node]
// One input, two outputs
final conditionNode = Node<MyData>(
  id: 'condition',
  type: 'condition',
  position: Offset(200, 100),
  size: Size(180, 100),
  data: MyData(label: 'If/Else'),
  inputPorts: [
    Port(
      id: 'cond-in',
      name: 'Input',
      position: PortPosition.left,
      type: PortType.input,
      offset: Offset(0, 50), // Centered vertically
    ),
  ],
  outputPorts: [
    Port(
      id: 'cond-true',
      name: 'True',
      position: PortPosition.right,
      type: PortType.output,
      offset: Offset(0, 33), // Upper third
    ),
    Port(
      id: 'cond-false',
      name: 'False',
      position: PortPosition.right,
      type: PortType.output,
      offset: Offset(0, 67), // Lower third
    ),
  ],
);
```

```dart [Merge Node]
// Multiple inputs, one output
final mergeNode = Node<MyData>(
  id: 'merge',
  type: 'merge',
  position: Offset(200, 100),
  size: Size(150, 120),
  data: MyData(label: 'Merge'),
  inputPorts: [
    Port(
      id: 'merge-in-1',
      name: 'Input 1',
      position: PortPosition.left,
      type: PortType.input,
      multiConnections: true,
      offset: Offset(0, 30),
    ),
    Port(
      id: 'merge-in-2',
      name: 'Input 2',
      position: PortPosition.left,
      type: PortType.input,
      multiConnections: true,
      offset: Offset(0, 60),
    ),
    Port(
      id: 'merge-in-3',
      name: 'Input 3',
      position: PortPosition.left,
      type: PortType.input,
      multiConnections: true,
      offset: Offset(0, 90),
    ),
  ],
  outputPorts: [
    Port(
      id: 'merge-out',
      name: 'Output',
      position: PortPosition.right,
      type: PortType.output,
      offset: Offset(0, 60), // Centered
    ),
  ],
);
```

```dart [Split Node]
// One input, multiple outputs
final splitNode = Node<MyData>(
  id: 'split',
  type: 'split',
  position: Offset(200, 100),
  size: Size(150, 120),
  data: MyData(label: 'Split'),
  inputPorts: [
    Port(
      id: 'split-in',
      name: 'Input',
      position: PortPosition.left,
      type: PortType.input,
      offset: Offset(0, 60), // Centered
    ),
  ],
  outputPorts: [
    Port(
      id: 'split-out-1',
      name: 'Output 1',
      position: PortPosition.right,
      type: PortType.output,
      offset: Offset(0, 30),
    ),
    Port(
      id: 'split-out-2',
      name: 'Output 2',
      position: PortPosition.right,
      type: PortType.output,
      offset: Offset(0, 60),
    ),
    Port(
      id: 'split-out-3',
      name: 'Output 3',
      position: PortPosition.right,
      type: PortType.output,
      offset: Offset(0, 90),
    ),
  ],
);
```

:::

## Port Theming

Customize port appearance with `PortTheme`:

```dart
theme: NodeFlowTheme(
  portTheme: PortTheme(
    size: Size(12, 12),                    // Port size (width, height)
    color: Color(0xFFBABABA),              // Default idle color
    connectedColor: Color(0xFF2196F3),     // Color when connected
    highlightColor: Color(0xFF42A5F5),     // Color when highlighted during drag
    highlightBorderColor: Color(0xFF000000), // Border color when highlighted
    borderColor: Colors.white,             // Default border color
    borderWidth: 2.0,                      // Border width
    shape: MarkerShapes.capsuleHalf,       // Default port shape
    showLabel: false,                      // Whether to show labels
    labelTextStyle: TextStyle(             // Label text styling
      fontSize: 10.0,
      color: Color(0xFF333333),
      fontWeight: FontWeight.w500,
    ),
    labelOffset: 4.0,                      // Distance from port to label
  ),
)
```

### Predefined Themes

```dart
// Light theme for light-colored backgrounds
final lightPortTheme = PortTheme.light;

// Dark theme for dark-colored backgrounds
final darkPortTheme = PortTheme.dark;

// Customize from a predefined theme
final customTheme = PortTheme.light.copyWith(
  size: Size(14, 14),
  highlightColor: Colors.green,
);
```

### Custom Port Colors by Type

```dart
// Use a custom PortBuilder to differentiate port types visually
PortBuilder myPortBuilder = (context, controller, node, port, isOutput, isConnected, nodeBounds) {
  final theme = Theme.of(context).extension<NodeFlowTheme>()!.portTheme;

  // Different colors based on port type
  final color = port.type == PortType.output ? Colors.green : Colors.blue;

  return PortWidget(
    port: port,
    theme: theme,
    controller: controller,
    nodeId: node.id,
    isOutput: isOutput,
    nodeBounds: nodeBounds,
    isConnected: isConnected,
    color: color,  // Override idle color
  );
};
```

## Querying Ports

::: code-group

```dart [Get Port from Node]
final node = controller.getNode('node-1');
if (node != null) {
  // Get specific port
  final port = node.inputPorts.firstWhere(
    (p) => p.id == 'input-1',
    orElse: () => throw Exception('Port not found'),
  );

  // Get all input ports
  final allInputs = node.inputPorts;

  // Get all output ports
  final allOutputs = node.outputPorts;

  // Get all ports
  final allPorts = [...node.inputPorts, ...node.outputPorts];
}
```

```dart [Find Connections to/from Port]
// Find connections from a source port (built-in method)
final fromPort = controller.getConnectionsFromPort('node-1', 'out-1');

// Find connections to a target port (built-in method)
final toPort = controller.getConnectionsToPort('node-2', 'in-1');

// Check if port has connections (custom helper)
bool hasConnections(String nodeId, String portId) {
  return controller.connections.any(
    (c) =>
        (c.sourceNodeId == nodeId && c.sourcePortId == portId) ||
        (c.targetNodeId == nodeId && c.targetPortId == portId),
  );
}
```

:::

## Dynamic Ports

Add or remove ports at runtime using the controller's port methods:

```dart
// Add an input port to an existing node
controller.addInputPort('node-1', Port(
  id: 'new-input',
  name: 'New Input',
  position: PortPosition.left,
  type: PortType.input,
));

// Add an output port to an existing node
controller.addOutputPort('node-1', Port(
  id: 'new-output',
  name: 'New Output',
  position: PortPosition.right,
  type: PortType.output,
));

// Remove a port (also removes its connections)
controller.removePort('node-1', 'port-id');

// Replace all ports on a node
controller.setNodePorts(
  'node-1',
  inputPorts: [/* new input ports */],
  outputPorts: [/* new output ports */],
);

// Get all input ports for a node
final inputs = controller.getInputPorts('node-1');

// Get all output ports for a node
final outputs = controller.getOutputPorts('node-1');
```

## Port Labels

Ports can have labels displayed near them. Labels require both the theme and the individual port to have `showLabel` enabled:

```dart
// Enable label on the port
Port(
  id: 'data-in',
  name: 'Data Input',  // This becomes the label text
  position: PortPosition.left,
  type: PortType.input,
  showLabel: true,     // Enable label display for this port
)
```

Configure label appearance in the port theme:

```dart
theme: NodeFlowTheme(
  portTheme: PortTheme(
    // ... other properties
    showLabel: true,  // Enable labels globally (required)
    labelTextStyle: TextStyle(
      fontSize: 10.0,
      color: Color(0xFF333333),
      fontWeight: FontWeight.w500,
    ),
    labelOffset: 4.0,  // Distance from port to label
  ),
)
```

Note: Port label visibility at different zoom levels is controlled by the LOD (Level of Detail) system via `LodExtension`. See [Level of Detail](/docs/extensions/lod) for details.

## Best Practices

1. **Unique IDs**: Ensure port IDs are unique across all nodes
2. **Meaningful Names**: Use descriptive port names
3. **Consistent Positioning**: Keep similar ports in similar positions
4. **Logical Flow**: Input ports on left/top, output ports on right/bottom
5. **Multi-Connections**: Enable for merge points, disable for one-to-one
6. **Offset Spacing**: Use consistent spacing between multiple ports
7. **Type Safety**: Use appropriate port types to guide connections

## Common Patterns

::: code-group

```dart [Port ID Generation]
String generatePortId(String nodeId, String portName) {
  return '$nodeId-${portName.toLowerCase().replaceAll(' ', '-')}';
}

// Usage
final port = Port(
  id: generatePortId('node-1', 'Data Input'),  // 'node-1-data-input'
  name: 'Data Input',
  position: PortPosition.left,
  type: PortType.input,
);
```

```dart [Port Factory]
class PortFactory {
  static Port createInputPort(String nodeId, String name, {Offset offset = Offset.zero}) {
    return Port(
      id: '$nodeId-in-${name.toLowerCase().replaceAll(' ', '-')}',
      name: name,
      position: PortPosition.left,
      type: PortType.input,
      offset: offset,
      multiConnections: true,
    );
  }

  static Port createOutputPort(String nodeId, String name, {Offset offset = Offset.zero}) {
    return Port(
      id: '$nodeId-out-${name.toLowerCase().replaceAll(' ', '-')}',
      name: name,
      position: PortPosition.right,
      type: PortType.output,
      offset: offset,
      multiConnections: false,
    );
  }
}
```

:::

## Next Steps

- Learn about [Connections](/docs/concepts/connections)
- Explore [Events & Validation](/docs/advanced/events)
- See [Examples](/docs/examples/)
