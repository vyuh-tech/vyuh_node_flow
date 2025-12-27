---
title: Port Labels
description: Display and customize port names alongside connection points
---

# Port Labels

Port labels display the port's name alongside its visual shape, helping users understand what each connection point represents. Labels support intelligent positioning, zoom-based visibility, and full styling control.

::: details 🖼️ Port Labels Overview
Node with labeled ports on all four sides: Left port with 'Input' label on the right, Right port with 'Output' label on the left, Top port with 'Signal' label below, Bottom port with 'Event' label above. Shows how labels automatically position inside the node boundary.
:::

## Overview

Port labels are controlled at two levels:

1. **Theme Level**: Global enable/disable for all ports
2. **Port Level**: Individual control per port

Both must be enabled for labels to display.

## Basic Usage

### Enabling Labels Globally

Enable port labels through the theme:

```dart
NodeFlowEditor(
  controller: controller,
  theme: NodeFlowTheme.dark.copyWith(
    portTheme: PortTheme.dark.copyWith(
      showLabel: true, // Enable labels globally
    ),
  ),
)
```

### Enabling Labels Per Port

Enable labels for individual ports:

```dart
Node(
  id: 'node-1',
  inputPorts: [
    Port(
      id: 'input-1',
      name: 'Data Input', // This name will be displayed
      position: PortPosition.left,
      showLabel: true, // Enable label for this port
    ),
  ],
  outputPorts: [
    Port(
      id: 'output-1',
      name: 'Result', // This name will be displayed
      position: PortPosition.right,
      showLabel: true, // Enable label for this port
    ),
  ],
)
```

::: warning
**Dual Control**: Labels only appear when **both** `theme.portTheme.showLabel` AND
  `port.showLabel` are `true`.

:::

## Label Positioning

Labels automatically position themselves based on port location, always appearing **"inside"** (toward the node):

| Port Position | Label Position         |
| ------------- | ---------------------- |
| **Left**      | Right of port (inside) |
| **Right**     | Left of port (inside)  |
| **Top**       | Below port (inside)    |
| **Bottom**    | Above port (inside)    |

```dart "showLabel: true"
// Left port → label appears to the right
Port(
  id: 'left-port',
  name: 'Input',
  position: PortPosition.left,
  showLabel: true,
)

// Right port → label appears to the left
Port(
  id: 'right-port',
  name: 'Output',
  position: PortPosition.right,
  showLabel: true,
)

// Top port → label appears below
Port(
  id: 'top-port',
  name: 'Signal',
  position: PortPosition.top,
  showLabel: true,
)

// Bottom port → label appears above
Port(
  id: 'bottom-port',
  name: 'Event',
  position: PortPosition.bottom,
  showLabel: true,
)
```

## Styling Labels

### Text Style

Customize label appearance:

```dart
NodeFlowEditor(
  theme: NodeFlowTheme.dark.copyWith(
    portTheme: PortTheme.dark.copyWith(
      showLabel: true,
      labelTextStyle: const TextStyle(
        fontSize: 11.0,
        color: Colors.white,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.5,
      ),
    ),
  ),
)
```

### Label Offset

Control distance from port center:

```dart
portTheme: PortTheme.dark.copyWith(
  showLabel: true,
  labelOffset: 12.0, // Distance in logical pixels (default: 8.0)
)
```

## Zoom-Based Visibility

Labels automatically hide when zoomed out to reduce visual clutter.

### Setting Visibility Threshold

```dart
portTheme: PortTheme.dark.copyWith(
  showLabel: true,
  labelVisibilityThreshold: 0.5, // Hide labels below 50% zoom (default)
)
```

**Always Visible** (threshold = 0.0):

```dart
portTheme: PortTheme.dark.copyWith(
  showLabel: true,
  labelVisibilityThreshold: 0.0, // Always show labels
)
```

**Hide When Zoomed Out** (threshold = 0.5):

```dart
portTheme: PortTheme.dark.copyWith(
  showLabel: true,
  labelVisibilityThreshold: 0.5, // Hide below 50% zoom
)
```

**Custom Threshold** (threshold = 0.75):

```dart
portTheme: PortTheme.dark.copyWith(
  showLabel: true,
  labelVisibilityThreshold: 0.75, // Hide below 75% zoom
)
```

## Complete Example

Here's a full example demonstrating port labels with different configurations:

```dart "showLabel: true"
import 'package:flutter/material.dart';
import 'package:vyuh_node_flow/vyuh_node_flow.dart';

class PortLabelsExample extends StatefulWidget {
  const PortLabelsExample({super.key});

  @override
  State<PortLabelsExample> createState() => _PortLabelsExampleState();
}

class _PortLabelsExampleState extends State<PortLabelsExample> {
  late final NodeFlowController<String> _controller;
  bool _showLabels = true;

  @override
  void initState() {
    super.initState();
    _controller = NodeFlowController<String>();
    _setupNodes();
  }

  void _setupNodes() {
    // Node with all port positions
    final node1 = Node<String>(
      id: 'node-1',
      position: const Offset(100, 100),
      size: const Size(200, 200),
      data: 'All Positions',
      inputPorts: [
        Port(
          id: 'input-left',
          name: 'Left Input',
          position: PortPosition.left,
          showLabel: true,
        ),
        Port(
          id: 'input-top',
          name: 'Top Input',
          position: PortPosition.top,
          showLabel: true,
        ),
      ],
      outputPorts: [
        Port(
          id: 'output-right',
          name: 'Right Output',
          position: PortPosition.right,
          showLabel: true,
        ),
        Port(
          id: 'output-bottom',
          name: 'Bottom Output',
          position: PortPosition.bottom,
          showLabel: true,
        ),
      ],
    );

    // Node with different port shapes
    final node2 = Node<String>(
      id: 'node-2',
      position: const Offset(400, 100),
      size: const Size(180, 180),
      data: 'Different Shapes',
      inputPorts: [
        Port(
          id: 'circle-input',
          name: 'Circle',
          position: PortPosition.left,
          shape: const CirclePortShape(),
          showLabel: true,
        ),
        Port(
          id: 'square-input',
          name: 'Square',
          position: PortPosition.left,
          offset: const Offset(0, 40),
          shape: const SquarePortShape(),
          showLabel: true,
        ),
        Port(
          id: 'diamond-input',
          name: 'Diamond',
          position: PortPosition.left,
          offset: const Offset(0, 80),
          shape: const DiamondPortShape(),
          showLabel: true,
        ),
      ],
      outputPorts: [
        Port(
          id: 'triangle-output',
          name: 'Triangle',
          position: PortPosition.right,
          shape: const TrianglePortShape(),
          showLabel: true,
        ),
      ],
    );

    // Node with multiple ports on same side
    final node3 = Node<String>(
      id: 'node-3',
      position: const Offset(100, 400),
      size: const Size(200, 150),
      data: 'Multiple Ports',
      inputPorts: List.generate(
        3,
        (i) => Port(
          id: 'input-$i',
          name: 'Port ${i + 1}',
          position: PortPosition.left,
          offset: Offset(0, (i - 1) * 40),
          showLabel: true,
        ),
      ),
      outputPorts: List.generate(
        3,
        (i) => Port(
          id: 'output-$i',
          name: 'Out ${i + 1}',
          position: PortPosition.right,
          offset: Offset(0, (i - 1) * 40),
          showLabel: true,
        ),
      ),
    );

    // Node with mixed labels
    final node4 = Node<String>(
      id: 'node-4',
      position: const Offset(400, 400),
      size: const Size(180, 150),
      data: 'Mixed Labels',
      inputPorts: [
        Port(
          id: 'labeled-input',
          name: 'With Label',
          position: PortPosition.left,
          showLabel: true, // Label enabled
        ),
        Port(
          id: 'unlabeled-input',
          name: 'No Label',
          position: PortPosition.left,
          offset: const Offset(0, 50),
          showLabel: false, // Label disabled
        ),
      ],
      outputPorts: [
        Port(
          id: 'labeled-output',
          name: 'With Label',
          position: PortPosition.right,
          showLabel: true,
        ),
        Port(
          id: 'unlabeled-output',
          name: 'No Label',
          position: PortPosition.right,
          offset: const Offset(0, 50),
          showLabel: false,
        ),
      ],
    );

    _controller.addNode(node1);
    _controller.addNode(node2);
    _controller.addNode(node3);
    _controller.addNode(node4);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Port Labels Example'),
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Row(
              children: [
                const Text('Show Labels: '),
                Switch(
                  value: _showLabels,
                  onChanged: (value) {
                    setState(() {
                      _showLabels = value;
                    });
                  },
                ),
              ],
            ),
          ),
        ],
      ),
      body: NodeFlowEditor<String>(
        controller: _controller,
        theme: NodeFlowTheme.dark.copyWith(
          portTheme: PortTheme.dark.copyWith(
            showLabel: _showLabels, // Global control
            labelTextStyle: const TextStyle(
              fontSize: 11.0,
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
            labelOffset: 10.0,
            labelVisibilityThreshold: 0.5,
          ),
        ),
        nodeBuilder: (context, node) {
          return Container(
            decoration: BoxDecoration(
              color: Colors.grey.shade800,
              border: Border.all(color: Colors.blueAccent, width: 2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
              child: Text(
                node.data ?? '',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
```

## Use Cases

### Data Pipeline Editor

Show data type information on ports:

```dart
Node(
  id: 'transform-node',
  inputPorts: [
    Port(
      id: 'csv-input',
      name: 'CSV Data',
      showLabel: true,
    ),
    Port(
      id: 'config-input',
      name: 'Config',
      showLabel: true,
    ),
  ],
  outputPorts: [
    Port(
      id: 'json-output',
      name: 'JSON Output',
      showLabel: true,
    ),
  ],
)
```

### Workflow Builder

Label ports with action descriptions:

```dart
Node(
  id: 'approval-node',
  inputPorts: [
    Port(
      id: 'request',
      name: 'Request',
      showLabel: true,
    ),
  ],
  outputPorts: [
    Port(
      id: 'approved',
      name: 'Approved',
      position: PortPosition.right,
      showLabel: true,
    ),
    Port(
      id: 'rejected',
      name: 'Rejected',
      position: PortPosition.bottom,
      showLabel: true,
    ),
  ],
)
```

### State Machine

Label transitions clearly:

```dart
Node(
  id: 'state-node',
  outputPorts: [
    Port(
      id: 'success',
      name: 'On Success',
      showLabel: true,
    ),
    Port(
      id: 'failure',
      name: 'On Failure',
      showLabel: true,
    ),
    Port(
      id: 'timeout',
      name: 'On Timeout',
      showLabel: true,
    ),
  ],
)
```

## Dynamic Label Control

Toggle labels at runtime:

```dart
// Toggle all labels
setState(() {
  theme = theme.copyWith(
    portTheme: theme.portTheme.copyWith(
      showLabel: !theme.portTheme.showLabel,
    ),
  );
});

// Toggle specific port label
controller.updateNode(
  node.copyWith(
    inputPorts: node.inputPorts.map((port) {
      return port.id == targetPortId
          ? port.copyWith(showLabel: !port.showLabel)
          : port;
    }).toList(),
  ),
);
```

## Configuration Reference

### PortTheme Properties

| Property                   | Type         | Default | Description                                       |
| -------------------------- | ------------ | ------- | ------------------------------------------------- |
| `showLabel`                | `bool`       | `false` | Global enable/disable for all port labels         |
| `labelTextStyle`           | `TextStyle?` | `null`  | Text style for labels (size, color, weight, etc.) |
| `labelOffset`              | `double`     | `8.0`   | Distance from port center in logical pixels       |
| `labelVisibilityThreshold` | `double`     | `0.5`   | Minimum zoom level to show labels (0.0-1.0+)      |

### Port Properties

| Property    | Type     | Default  | Description                         |
| ----------- | -------- | -------- | ----------------------------------- |
| `name`      | `String` | required | Text displayed as the label         |
| `showLabel` | `bool`   | `false`  | Enable label for this specific port |

## Best Practices

1. **Meaningful Names**: Use clear, descriptive port names that explain the port's purpose
2. **Consistent Naming**: Use consistent naming conventions across similar nodes
3. **Abbreviations**: Consider abbreviating long names for space-constrained layouts
4. **Theme Control**: Use theme-level control for quick toggle during development/debugging
5. **Zoom Threshold**: Set appropriate threshold based on your typical zoom levels
6. **Mixed Labels**: Selectively disable labels on obvious/redundant ports

## Accessibility

Port labels improve accessibility by:

- Providing text descriptions of connection points
- Making the purpose of ports immediately clear
- Reducing cognitive load for new users
- Supporting screen readers (when enabled)

::: info
**Tip**: Keep label text concise (1-3 words) for best visual appearance and readability.

:::

## Performance Considerations

- Labels use responsive visibility to reduce rendering overhead when zoomed out
- Text rendering is optimized for performance
- Labels only rebuild when port or theme properties change
- No performance impact when labels are disabled globally

## See Also

- [Ports](/docs/core-concepts/ports) - Understanding port concepts
- [Port Shapes](/docs/theming/port-shapes) - Customizing port appearance
- [Theming Overview](/docs/theming/overview) - Complete theming guide
