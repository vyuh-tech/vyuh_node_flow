---
title: Snap Plugin
description: Enable grid snapping and alignment guides for precise node positioning
---

# Snap Plugin

The Snap plugin provides precise node positioning through grid snapping and alignment guides. When enabled, nodes
automatically snap to a grid and show alignment guides when approaching other nodes.

## Basic Usage

The snap plugin is included in the default plugins but disabled by default. Enable it via the controller:

```dart
import 'package:vyuh_node_flow/vyuh_node_flow.dart';

// Configure with snap plugin
final controller = NodeFlowController<MyData, dynamic>(
  config: NodeFlowConfig(
    plugins: [
      SnapPlugin(
        enabled: false, // Master switch for all snapping
        delegates: [
          GridSnapDelegate(gridSize: 20.0),
        ],
      ),
      // ... other plugins
    ],
  ),
);
```

## Toggle Snapping

Use the keyboard shortcut **N** to toggle snapping on/off, or control it programmatically:

```dart
// Toggle snapping
controller.snap?.toggle();

// Check if enabled
final isEnabled = controller.snap?.enabled ?? false;

// Enable/disable directly
controller.snap?.enabled = true;
```

## Snap Delegates

The SnapPlugin uses a chain of delegates to determine snap positions. Each delegate can provide different snapping
behavior:

### GridSnapDelegate

Snaps nodes to a regular grid:

```dart
GridSnapDelegate(
  gridSize: 20.0,  // Snap to 20px grid
)
```

### Custom Snap Delegates

Create custom delegates by implementing the `SnapDelegate` interface:

```dart
class MyCustomSnapDelegate implements SnapDelegate {
  @override
  SnapResult snapPosition({
    required Offset intendedPosition,
    required Size nodeSize,
    required String nodeId,
  }) {
    // Return snapped position and which axes were snapped
    return SnapResult(
      position: snappedOffset,
      snappedX: true,
      snappedY: false,
    );
  }

  @override
  void onDragStart() {}

  @override
  void onDragEnd() {}
}
```

## Configuration

### SnapPlugin Constructor

```dart
SnapPlugin({
  bool enabled = false,        // Master switch for snapping
  List<SnapDelegate> delegates = const [],  // Snap delegate chain
})
```

### Properties

| Property           | Type                 | Description                                       |
|--------------------|----------------------|---------------------------------------------------|
| `enabled`          | `bool`               | Master switch that controls all snapping behavior |
| `delegates`        | `List<SnapDelegate>` | Chain of delegates that determine snap positions  |
| `gridSnapDelegate` | `GridSnapDelegate?`  | Convenience getter for the grid delegate          |

### Methods

| Method              | Description                                     |
|---------------------|-------------------------------------------------|
| `toggle()`          | Toggle the enabled state                        |
| `snapPosition(...)` | Calculate snapped position using delegate chain |

## Integration with Alignment Guides

The SnapPlugin can work with alignment guide delegates (available in Pro) to show visual guides when nodes align with
each other:

```dart
SnapPlugin(
  enabled: true,
  delegates: [
    GridSnapDelegate(gridSize: 20.0),
    SnapLinesDelegate(threshold: 8.0),  // Pro feature
  ],
)
```

## See Also

- [Plugins](/docs/concepts/plugins) - Plugin system overview
- [Configuration](/docs/concepts/configuration) - Controller configuration
