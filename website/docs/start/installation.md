---
title: Installation
description: Set up Vyuh Node Flow in your Flutter project
---

# Installation

<PackageShields />

Get Vyuh Node Flow running in your Flutter project in under 5 minutes.

## Requirements

| Requirement | Minimum Version |
|-------------|-----------------|
| Flutter | 3.32.0+ |
| Dart SDK | 3.9.0+ |

## Setup

### Add the Dependency

Add `vyuh_node_flow` to your `pubspec.yaml`.

<PubspecCodeBlock />

Run the install command:

```bash
flutter pub get
```

### Import the Library

Add the import to your Dart files:

```dart
import 'package:vyuh_node_flow/vyuh_node_flow.dart';
```

## Verify Installation

Create a minimal test to confirm everything works:

```dart title="main.dart"
import 'package:flutter/material.dart';
import 'package:vyuh_node_flow/vyuh_node_flow.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late final controller = NodeFlowController<String, dynamic>();

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: NodeFlowEditor<String, dynamic>(
          controller: controller,
          theme: NodeFlowTheme.light,
          nodeBuilder: (context, node) => Center(child: Text(node.data)),
        ),
      ),
    );
  }
}
```

Run the app. If it compiles and runs without errors, you're ready to go.

::: info
**Under the Hood**: Vyuh Node Flow uses MobX for reactive state management. The package handles all MobX setup internally - no additional configuration needed.

:::

## What's Included

The `vyuh_node_flow` package exports everything you need:

### Widgets

| Export | Purpose |
|--------|---------|
| `NodeFlowEditor` | The main interactive editor widget with full editing capabilities |
| `NodeFlowViewer` | Read-only display widget for presenting flows |

### State & Configuration

| Export | Purpose |
|--------|---------|
| `NodeFlowController` | Central controller for state management, graph operations, and viewport control |
| `NodeFlowConfig` | Behavioral configuration (grid snapping, zoom limits) |
| `NodeFlowBehavior` | Presets for editor modes: `design`, `preview`, `present` |
| `NodeFlowEvents` | Event callbacks for nodes, ports, connections, viewport, and annotations |

::: tip Extensions
Additional features like **minimap**, **autopan**, **debug overlays**, **level-of-detail (LOD)**, and **statistics** are managed via **Extensions**. Most extensions take direct parameters (e.g., `MinimapExtension`, `DebugExtension`, `LodExtension`), while `AutoPanExtension` accepts an `AutoPanConfig` object. See the [Configuration](/docs/concepts/configuration) guide for details.
:::

### Core Data Models

| Export | Purpose |
|--------|---------|
| `Node<T>` | Node with generic data type, position, size, and ports |
| `Port` | Connection point with position, shape, and constraints |
| `Connection` | Link between output and input ports with optional styling |
| `ConnectionEndPoint` | Defines connection endpoint markers (arrows, circles, etc.) |
| `GroupNode` | Special node for visually grouping other nodes |
| `CommentNode` | Special node for floating text annotations |
| `Graph` | Container for nodes and connections (used for serialization) |

### Theming

| Export | Purpose |
|--------|---------|
| `NodeFlowTheme` | Root theme container |
| `NodeTheme` | Node appearance (borders, colors, shadows) |
| `ConnectionTheme` | Connection styling |
| `PortTheme` | Port appearance |
| `LabelTheme` | Connection labels |
| `GridTheme` | Grid background |
| `SelectionTheme` | Selection rectangle |
| `CursorTheme` | Mouse cursors |
| `ResizerTheme` | Resize handles |

::: tip Extension Themes
Themes for extensions like `MinimapTheme` and `DebugTheme` are configured via their respective extensions (e.g., `MinimapExtension`), not directly on `NodeFlowTheme`.
:::

### Visual Customization

| Export | Purpose |
|--------|---------|
| `ConnectionStyles` | Path algorithms (`bezier`, `smoothstep`, `step`, `straight`, `customBezier`) |
| `ConnectionEffect` | Animations (`FlowingDashEffect`, `ParticleEffect`, `GradientFlowEffect`, `PulseEffect`) |
| `NodeShape` | Node shapes (`CircleShape`, `DiamondShape`, `HexagonShape`) |
| `MarkerShape` | Port shapes (circle, square, diamond, triangle, capsuleHalf, etc.) |

## Next Steps

  - **[Quick Start](/docs/start/quick-start)** - Build your first flow editor
  - **[Architecture](/docs/concepts/architecture)** - Understand the core concepts
