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

Add `vyuh_node_flow` to your `pubspec.yaml`. The current version is <PubVersion />.

::: code-group

```yaml title="pubspec.yaml" [pub.dev]
dependencies:
  vyuh_node_flow: ^0.15.0  # See pub.dev for latest version
```

```yaml title="pubspec.yaml" [Git]
dependencies:
  vyuh_node_flow:
    git:
      url: https://github.com/vyuh-tech/vyuh_node_flow.git
      path: packages/vyuh_node_flow
```

:::

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

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: Builder(
          builder: (context) {
            // If this compiles, the package is installed correctly
            final controller = NodeFlowController<String>();
            return Center(
              child: Text('Vyuh Node Flow installed!'),
            );
          },
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
| `NodeFlowMinimap` | Bird's-eye navigation view of the canvas |

### State & Configuration

| Export | Purpose |
|--------|---------|
| `NodeFlowController` | Central controller for state management, graph operations, and viewport control |
| `NodeFlowConfig` | Behavioral configuration (grid snapping, zoom limits, auto-panning, debug mode) |
| `AutoPanConfig` | Auto-panning behavior when dragging near canvas edges |
| `NodeFlowBehavior` | Presets for editor modes: `design`, `preview`, `present` |
| `NodeFlowEvents` | Event callbacks for nodes, ports, connections, viewport, and annotations |

### Core Data Models

| Export | Purpose |
|--------|---------|
| `Node<T>` | Node with generic data type, position, size, and ports |
| `Port` | Connection point with position, shape, and constraints |
| `Connection` | Link between output and input ports with optional styling |
| `ConnectionEndpoint` | Defines connection start and end points with node/port IDs |
| `GroupNode` | Special node for visually grouping other nodes |
| `CommentNode` | Special node for floating text annotations |
| `Graph` | Container for nodes and connections (used for serialization) |

### Theming

| Export | Purpose |
|--------|---------|
| `NodeFlowTheme` | Complete theme configuration for the editor |
| `NodeTheme` | Node appearance (borders, selection, hover states) |
| `ConnectionTheme` | Connection styling (color, width, endpoints) |
| `PortTheme` | Port appearance (size, color, labels) |
| `GridStyle` | Background grid patterns (`lines`, `dots`, `cross`, `hierarchical`, `none`) |

### Visual Customization

| Export | Purpose |
|--------|---------|
| `ConnectionStyle` | Path algorithms (`bezier`, `smoothstep`, `step`, `straight`) |
| `ConnectionEffect` | Animations (`FlowingDashEffect`, `ParticleEffect`, `GradientFlowEffect`, `PulseEffect`) |
| `NodeShape` | Node shapes (`CircleShape`, `DiamondShape`, `HexagonShape`) |
| `PortShape` | Port shapes (`circle`, `square`, `diamond`, `triangle`, `capsuleHalf`, `none`) |

## Next Steps

  - **[Quick Start](/docs/getting-started/quick-start)** - Build your first flow editor
  - **[Architecture](/docs/core-concepts/architecture)** - Understand the core concepts
