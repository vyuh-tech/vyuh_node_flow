---
title: Port Widget
description: Customizing port rendering and interaction
---

# Port Widget

::: details 🖼️ Port Widget States
Diagram showing a port in different states: idle (default color), connected (connected color), highlighted (glow effect during connection drag), and hovered (slightly larger with border). Each labeled with state name.
:::

The `PortWidget` renders connection points on nodes. Ports are where connections attach, enabling the flow relationships between nodes.

## Default Rendering

By default, ports are rendered automatically based on the `PortTheme` in your `NodeFlowTheme`:

```dart
NodeFlowEditor<MyData, dynamic>(
  controller: controller,
  theme: NodeFlowTheme.light.copyWith(
    portTheme: PortTheme(
      size: Size(12, 12),
      color: Colors.blue,
      connectedColor: Colors.green,
      highlightColor: Colors.yellow,
      highlightBorderColor: Colors.orange,
      borderColor: Colors.white,
      borderWidth: 2.0,
    ),
  ),
  nodeBuilder: (context, node) => MyNodeWidget(node: node),
  // Ports are rendered automatically
)
```

## Custom Port Builder

For complete control over port appearance, provide a `portBuilder`:

```dart
NodeFlowEditor<MyData, dynamic>(
  controller: controller,
  theme: NodeFlowTheme.light,
  nodeBuilder: (context, node) => MyNodeWidget(node: node),
  portBuilder: (context, controller, node, port, isOutput, isConnected, nodeBounds) {
    // Custom port appearance based on port data
    final color = _getColorForPortType(port.name);
    final theme = Theme.of(context).plugin<NodeFlowTheme>()!;

    return PortWidget(
      port: port,
      theme: theme.portTheme,
      controller: controller,
      nodeId: node.id,
      isOutput: isOutput,
      nodeBounds: nodeBounds,
      isConnected: isConnected,
      color: color,
    );
  },
)

Color _getColorForPortType(String portName) {
  if (portName.contains('error')) return Colors.red;
  if (portName.contains('data')) return Colors.blue;
  if (portName.contains('trigger')) return Colors.orange;
  return Colors.grey;
}
```

## PortWidget Properties

### Required Properties

| Property | Type | Description |
|----------|------|-------------|
| `port` | `Port` | The port model to render |
| `theme` | `PortTheme` | Theme for styling |
| `controller` | `NodeFlowController<T, dynamic>` | Controller for connection handling |
| `nodeId` | `String` | ID of the parent node |
| `isOutput` | `bool` | Whether this is an output port |
| `nodeBounds` | `Rect` | Parent node bounds in graph coordinates |

### Optional Properties

| Property | Type | Default | Description |
|----------|------|---------|-------------|
| `isConnected` | `bool` | `false` | Whether port has connections |
| `size` | `Size?` | theme | Override port size |
| `color` | `Color?` | theme | Override idle color |
| `connectedColor` | `Color?` | theme | Override connected color |
| `highlightColor` | `Color?` | theme | Override highlight color |
| `borderColor` | `Color?` | theme | Override border color |
| `borderWidth` | `double?` | theme | Override border width |
| `snapDistance` | `double` | `8.0` | Hit area expansion |

### Callbacks

| Callback | Type | Description |
|----------|------|-------------|
| `onTap` | `ValueChanged<Port>?` | Called when port is tapped |
| `onDoubleTap` | `VoidCallback?` | Called when port is double-tapped |
| `onContextMenu` | `void Function(ScreenPosition)?` | Called for right-click with screen coordinates |
| `onHover` | `ValueChanged<(Port, bool)>?` | Called on hover state change |

## Property Resolution

Port properties are resolved in this order (lowest to highest priority):

1. **Theme values** (`PortTheme`) - Base styling
2. **Widget overrides** (constructor parameters) - Per-widget customization
3. **Model values** (`Port` properties) - Per-port customization

```dart
// Example: Port model overrides take precedence
final port = Port(
  id: 'special-port',
  name: 'Output',
  position: PortPosition.right,
  type: PortType.output,
  size: Size(16, 16),  // Overrides theme size
);

// Theme size is 9x9, but this port will be 16x16
// Note: Port model doesn't support color override - use PortWidget's color parameter
```

## Port States

Ports automatically display different visual states:

### Idle State

Default appearance when no interaction is happening.

```dart
PortTheme(
  color: Colors.grey,        // Idle color
  borderColor: Colors.white,
  borderWidth: 2.0,
)
```

### Connected State

When the port has one or more connections attached.

```dart
PortTheme(
  connectedColor: Colors.green,  // Connected color
)
```

### Highlighted State

During connection dragging, valid target ports are highlighted.

```dart
PortTheme(
  highlightColor: Colors.yellow,
  highlightBorderColor: Colors.orange,
)
```

The `Port.highlighted` observable is automatically managed by the controller during connection operations.

## Port Shapes

Ports can have different shapes based on the theme or individual port configuration:

```dart
import 'package:vyuh_node_flow/vyuh_node_flow.dart';

PortTheme(
  shape: MarkerShapes.capsuleHalf,  // Default shape
)

// Or specify per-port
Port(
  id: 'my-port',
  name: 'Input',
  shape: MarkerShapes.circle,
)
```

### Built-in Shapes

Shapes are defined in `MarkerShapes`:

| Shape | Description |
|-------|-------------|
| `MarkerShapes.circle` | Circular port |
| `MarkerShapes.square` | Square port |
| `MarkerShapes.diamond` | Diamond/rotated square |
| `MarkerShapes.capsule` | Rounded rectangle (both ends rounded) |
| `MarkerShapes.capsuleHalf` | Half-capsule (default, rounded on one side) |
| `MarkerShapes.triangle` | Triangular port |
| `MarkerShapes.arrow` | Arrow-shaped port |

### Custom Port Shape

For completely custom shapes, create a `PortShapeWidget`:

```dart
class TrianglePortShape extends StatelessWidget {
  final double size;
  final Color color;
  final bool isOutput;

  const TrianglePortShape({
    required this.size,
    required this.color,
    required this.isOutput,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(size, size),
      painter: TrianglePainter(
        color: color,
        pointsRight: isOutput,
      ),
    );
  }
}
```

## Port Positioning

Ports are positioned relative to their parent node based on `PortPosition` and optional `offset`:

```dart
// Port on left edge - type defaults to input for left/top positions
Port(
  id: 'input',
  name: 'Input',
  position: PortPosition.left,
  // type: PortType.input is inferred from PortPosition.left
)

// Port on right edge with vertical offset
// offset.dy specifies the vertical CENTER position from the top of the node
Port(
  id: 'output-1',
  name: 'True',
  position: PortPosition.right,
  // type: PortType.output is inferred from PortPosition.right
  offset: Offset(0, 33),  // Center at 33px from top
)

// Another right port at a different vertical position
Port(
  id: 'output-2',
  name: 'False',
  position: PortPosition.right,
  offset: Offset(0, 67),   // Center at 67px from top
)
```

## Connection Handling

The `PortWidget` automatically handles connection creation:

1. **Drag Start**: User drags from a port
2. **Temporary Connection**: Dashed line follows cursor
3. **Port Highlighting**: Valid target ports glow
4. **Validation**: `onBeforeComplete` callback is invoked
5. **Connection Created**: If valid, connection is added

```dart
events: NodeFlowEvents(
  connection: ConnectionEvents(
    onBeforeStart: (context) {
      // Validate if connection can start from this port
      if (context.sourcePort.name == 'disabled') {
        return ConnectionValidationResult(
          allowed: false,
          reason: 'Cannot connect from disabled port',
        );
      }
      return ConnectionValidationResult(allowed: true);
    },
    onBeforeComplete: (context) {
      // Validate if connection can complete to this port
      if (context.sourcePort.name == context.targetPort.name) {
        return ConnectionValidationResult(
          allowed: false,
          reason: 'Cannot connect same port types',
        );
      }
      return ConnectionValidationResult(allowed: true);
    },
  ),
)
```

## Hit Testing

Ports have an expanded hit area for easier targeting:

```dart
PortWidget(
  port: port,
  theme: theme,
  controller: controller,
  nodeId: nodeId,
  isOutput: true,
  nodeBounds: bounds,
  snapDistance: 12.0,  // Hit area extends 12px beyond visual
)
```

The `snapDistance` creates an invisible buffer around the port, making it easier to start connections.

## Complete Example

```dart
class CustomPortNode extends StatelessWidget {
  final Node<MyData> node;
  final NodeFlowController<MyData, dynamic> controller;
  final Rect nodeBounds;

  const CustomPortNode({
    required this.node,
    required this.controller,
    required this.nodeBounds,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context).plugin<NodeFlowTheme>()!;
    final size = node.size.value;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        // Node content
        Container(
          width: size.width,
          height: size.height,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.blue),
          ),
          child: Center(child: Text(node.data.label)),
        ),

        // Input ports on left
        for (var i = 0; i < node.inputPorts.length; i++)
          Positioned(
            left: -6,  // Half port size outside node
            top: _calculatePortOffset(i, node.inputPorts.length, size.height),
            child: PortWidget(
              port: node.inputPorts[i],
              theme: theme.portTheme,
              controller: controller,
              nodeId: node.id,
              isOutput: false,
              nodeBounds: nodeBounds,
              isConnected: _isPortConnected(node.inputPorts[i].id),
            ),
          ),

        // Output ports on right
        for (var i = 0; i < node.outputPorts.length; i++)
          Positioned(
            right: -6,  // Half port size outside node
            top: _calculatePortOffset(i, node.outputPorts.length, size.height),
            child: PortWidget(
              port: node.outputPorts[i],
              theme: theme.portTheme,
              controller: controller,
              nodeId: node.id,
              isOutput: true,
              nodeBounds: nodeBounds,
              isConnected: _isPortConnected(node.outputPorts[i].id),
              color: Colors.green,  // Custom color for outputs
            ),
          ),
      ],
    );
  }

  double _calculatePortOffset(int index, int total, double nodeHeight) {
    final spacing = nodeHeight / (total + 1);
    return spacing * (index + 1) - 6;  // Center port on position
  }

  bool _isPortConnected(String portId) {
    return controller.connections.any(
      (c) => c.sourcePortId == portId || c.targetPortId == portId,
    );
  }
}
```

## Best Practices

1. **Consistent Sizing**: Keep port sizes consistent across your application
2. **Color Coding**: Use colors to indicate data types or connection categories
3. **Hit Area**: Use adequate `snapDistance` for touch-friendly interfaces
4. **Visual Feedback**: Ensure clear distinction between states (idle, connected, highlighted)
5. **Port Labels**: Use meaningful names that appear as tooltips or labels

## See Also

- [Ports (Core Concepts)](/docs/concepts/ports) - Port model and configuration
- [Connections](/docs/concepts/connections) - Connection handling
- [Theming](/docs/theming/overview) - Port theme customization
