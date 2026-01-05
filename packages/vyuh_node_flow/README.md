# Vyuh Node Flow

![Vyuh Node Flow Banner](https://github.com/vyuh-tech/vyuh_node_flow/raw/main/packages/vyuh_node_flow/assets/node-flow-banner.png)

A flexible, high-performance node-based flow editor for Flutter applications.
Build visual programming interfaces, workflow editors, interactive diagrams, and
data pipelines with ease.

<p align="center">
  <a href="https://pub.dev/packages/vyuh_node_flow">
    <img src="https://img.shields.io/pub/v/vyuh_node_flow?style=for-the-badge&logo=dart&logoColor=white&color=0175C2" alt="Pub Version">
  </a>
  <a href="https://flow.vyuh.tech">
    <img src="https://img.shields.io/badge/Docs-flow.vyuh.tech-blue?style=for-the-badge&logo=readthedocs&logoColor=white" alt="Documentation">
  </a>
  <a href="https://opensource.org/licenses/MIT">
    <img src="https://img.shields.io/badge/License-MIT-yellow?style=for-the-badge" alt="License">
  </a>
</p>

<p align="center">
  <a href="https://flow.demo.vyuh.tech"><strong>Try the Live Demo</strong></a> ·
  <a href="https://flow.vyuh.tech/docs/start/installation"><strong>Get Started</strong></a>
</p>

---

<p align="center">
  <img src="https://github.com/vyuh-tech/vyuh_node_flow/raw/main/packages/vyuh_node_flow/_screenshots/hero.gif" alt="Vyuh Node Flow in Action" width="800"/>
</p>

---

## Features

- **High Performance** — Optimized rendering for smooth 60fps interactions
- **Viewport Controls** — Pan, zoom, fit-to-view with animated transitions
- **Smart Connections** — Bezier, smoothstep, step paths with validation rules
- **Connection Effects** — Particles, flowing dashes, gradients, pulse & rainbow
- **Comprehensive Theming** — Nodes, ports, connections, grid backgrounds & more
- **Keyboard Shortcuts** — 20+ built-in actions, fully customizable
- **Multi-Select** — Marquee selection, copy/paste, and bulk operations
- **Minimap & LOD** — Bird's-eye navigation and zoom-based detail levels
- **Special Nodes** — Groups for organization, comments for annotations
- **Serialization** — Save and load flows from JSON with type-safe generics

## Showcase

<table>
  <tr>
    <td align="center" width="50%">
      <img src="https://github.com/vyuh-tech/vyuh_node_flow/raw/main/packages/vyuh_node_flow/_screenshots/demo-app.png" alt="Demo Application" width="400"/>
      <br/>
      <strong>Demo Application</strong>
      <br/>
      <em>Full-featured demo with 20+ examples</em>
    </td>
    <td align="center" width="50%">
      <img src="https://github.com/vyuh-tech/vyuh_node_flow/raw/main/packages/vyuh_node_flow/_screenshots/connection-effects.gif" alt="Connection Effects" width="400"/>
      <br/>
      <strong>Connection Effects</strong>
      <br/>
      <em>Particles, gradients, flowing dashes & more</em>
    </td>
  </tr>
  <tr>
    <td align="center" width="50%">
      <img src="https://github.com/vyuh-tech/vyuh_node_flow/raw/main/packages/vyuh_node_flow/_screenshots/minimap.png" alt="Minimap Navigation" width="400"/>
      <br/>
      <strong>Minimap Navigation</strong>
      <br/>
      <em>Bird's-eye view for large graphs</em>
    </td>
    <td align="center" width="50%">
      <img src="https://github.com/vyuh-tech/vyuh_node_flow/raw/main/packages/vyuh_node_flow/_screenshots/lod.gif" alt="Level of Detail" width="400"/>
      <br/>
      <strong>Level of Detail</strong>
      <br/>
      <em>Auto-hide details when zoomed out</em>
    </td>
  </tr>
  <tr>
    <td align="center" width="50%">
      <img src="https://github.com/vyuh-tech/vyuh_node_flow/raw/main/packages/vyuh_node_flow/_screenshots/viewport-animations.gif" alt="Viewport Animations" width="400"/>
      <br/>
      <strong>Viewport Animations</strong>
      <br/>
      <em>Smooth pan, zoom & fit-to-view</em>
    </td>
    <td align="center" width="50%">
      <img src="https://github.com/vyuh-tech/vyuh_node_flow/raw/main/packages/vyuh_node_flow/_screenshots/theming.png" alt="Theming System" width="400"/>
      <br/>
      <strong>Theming System</strong>
      <br/>
      <em>Light, dark & custom themes</em>
    </td>
  </tr>
</table>

---

## Installation

```yaml
dependencies:
  vyuh_node_flow: ^0.20.0
```

---

## Quick Start

```dart
import 'package:flutter/material.dart';
import 'package:vyuh_node_flow/vyuh_node_flow.dart';

class FlowEditor extends StatefulWidget {
  @override
  State<FlowEditor> createState() => _FlowEditorState();
}

class _FlowEditorState extends State<FlowEditor> {
  late final controller = NodeFlowController<String, dynamic>(
    nodes: [
      Node<String>(
        id: 'node-1',
        type: 'input',
        position: const Offset(100, 100),
        data: 'Start',
        outputPorts: const [
          Port(id: 'out', name: 'Output', offset: Offset(2, 40)),
        ],
      ),
      Node<String>(
        id: 'node-2',
        type: 'output',
        position: const Offset(400, 100),
        data: 'End',
        inputPorts: const [
          Port(id: 'in', name: 'Input', offset: Offset(-2, 40)),
        ],
      ),
    ],
    connections: [
      Connection(
        id: 'conn-1',
        sourceNodeId: 'node-1',
        sourcePortId: 'out',
        targetNodeId: 'node-2',
        targetPortId: 'in',
      ),
    ],
  );

  @override
  Widget build(BuildContext context) {
    return NodeFlowEditor<String, dynamic>(
      controller: controller,
      theme: NodeFlowTheme.light,
      nodeBuilder: (context, node) => Padding(
        padding: const EdgeInsets.all(16),
        child: Text(node.data, style: const TextStyle(fontWeight: FontWeight.bold)),
      ),
    );
  }
}
```

> [!TIP]
> Use a **sealed class hierarchy** for node data to get full type safety and
> pattern matching in your node builder.

---

## Theming

Customize every visual aspect with the comprehensive theming system:

```dart
final customTheme = NodeFlowTheme.dark.copyWith(
  // Connection appearance
  connectionTheme: ConnectionTheme.dark.copyWith(
    style: ConnectionStyles.bezier,
    color: Colors.purple.shade300,
    animationEffect: ConnectionEffects.particles,
  ),

  // Grid background
  gridTheme: GridTheme.dark.copyWith(
    style: GridStyles.dots,
    color: Colors.white24,
  ),

  // Node styling
  nodeTheme: NodeTheme.dark.copyWith(
    borderRadius: BorderRadius.circular(12),
    selectedBorderColor: Colors.purple,
  ),
);
```

> [!NOTE]
> See the [Theming Guide](https://flow.vyuh.tech/docs/theming/overview) for all
> available theme options including port shapes, connection effects, and custom
> builders.

---

## Events

React to user interactions with the event system:

```dart
NodeFlowEditor<MyData, dynamic>(
  controller: controller,
  theme: theme,
  nodeBuilder: _buildNode,
  events: NodeFlowEvents<MyData, dynamic>(
    // Node events
    node: NodeEvents<MyData, dynamic>(
      onTap: (node) => print('Tapped: ${node.id}'),
      onMove: (node, delta) => print('Moving: ${node.id}'),
    ),

    // Connection validation
    connection: ConnectionEvents<MyData, dynamic>(
      onBeforeComplete: (context) {
        // Prevent self-connections
        if (context.sourceNode.id == context.targetNode.id) {
          return ConnectionValidationResult.invalid(
            reason: 'Cannot connect node to itself',
          );
        }
        return ConnectionValidationResult.valid();
      },
      onCreated: (connection) => print('Connected: ${connection.id}'),
    ),

    // Selection events
    selection: SelectionEvents<MyData, dynamic>(
      onChanged: (nodes) => print('Selected: ${nodes.length} nodes'),
    ),
  ),
);
```

> [!NOTE]
> See the [Events Guide](https://flow.vyuh.tech/docs/advanced/events) for the
> complete event API including viewport, keyboard, and graph events.

---

## Extensions

Add features through the modular extension system:

```dart
NodeFlowEditor<MyData, dynamic>(
  controller: controller,
  theme: theme,
  nodeBuilder: _buildNode,
  extensions: [
    // Navigation minimap
    MinimapExtension(visible: true),

    // Performance statistics overlay
    StatsExtension(),

    // Visual debugging overlays
    DebugExtension(mode: DebugMode.all),

    // Level of detail rendering
    LodExtension(enabled: true),
  ],
);
```

---

## Documentation

For comprehensive guides and API reference, visit the documentation:

| Topic                                                                              | Description                                  |
| ---------------------------------------------------------------------------------- | -------------------------------------------- |
| [Installation](https://flow.vyuh.tech/docs/start/installation)              | Setup and requirements                       |
| [Core Concepts](https://flow.vyuh.tech/docs/concepts/architecture)           | Nodes, ports, connections, and controller    |
| [Theming](https://flow.vyuh.tech/docs/theming/overview)                      | Complete visual customization                |
| [Connection Effects](https://flow.vyuh.tech/docs/theming/connection-effects) | Particles, flowing dashes, gradients & more  |
| [Events](https://flow.vyuh.tech/docs/advanced/events)                        | Interaction callbacks and validation         |
| [Serialization](https://flow.vyuh.tech/docs/advanced/serialization)          | Save and load flows                          |
| [Special Nodes](https://flow.vyuh.tech/docs/components/special-node-types)   | Comments, groups, and annotations            |
| [API](https://flow.vyuh.tech/docs/api)                                       | Complete API documentation                   |
| [Examples](https://flow.vyuh.tech/docs/examples)                             | Working code examples                        |

---

## Acknowledgments

Vyuh Node Flow is inspired by [React Flow](https://reactflow.dev), the excellent
node-based graph library for React.

---

## License

MIT License - see [LICENSE](LICENSE) for details.

---

<p align="center">
  Made with ❤️ by the <a href="https://vyuh.tech">Vyuh</a> team
</p>
