---
title: Stats Plugin
description: Access reactive graph statistics for nodes, connections, viewport, and selection
---

# Stats Plugin

The Stats plugin provides reactive access to graph statistics. All properties are MobX observables, so UI components
automatically update when the graph changes.

## Quick Start

Stats is included by default and available via `controller.stats`:

```dart
// Access stats via controller
final nodeCount = controller.stats?.nodeCount ?? 0;
final connectionCount = controller.stats?.connectionCount ?? 0;
final zoomPercent = controller.stats?.zoomPercent ?? 100;
```

### Reactive UI

Wrap stats access in an `Observer` for reactive updates:

```dart
import 'package:flutter_mobx/flutter_mobx.dart';

Observer(
  builder: (_) {
    final stats = controller.stats;
    if (stats == null) return const SizedBox.shrink();

    return Text('${stats.nodeCount} nodes, ${stats.connectionCount} connections');
  },
)
```

## Node Statistics

| Property           | Type               | Description                         |
|--------------------|--------------------|-------------------------------------|
| `nodeCount`        | `int`              | Total number of nodes               |
| `visibleNodeCount` | `int`              | Non-hidden nodes                    |
| `lockedNodeCount`  | `int`              | Locked (non-draggable) nodes        |
| `groupCount`       | `int`              | Number of GroupNode instances       |
| `commentCount`     | `int`              | Number of CommentNode instances     |
| `regularNodeCount` | `int`              | Nodes excluding groups and comments |
| `nodesByType`      | `Map<String, int>` | Breakdown by node type              |

### Node Type Breakdown

```dart
Observer(
  builder: (_) {
    final nodesByType = controller.stats?.nodesByType ?? {};

    return Column(
      children: nodesByType.entries.map((entry) {
        return Text('${entry.key}: ${entry.value}');
      }).toList(),
    );
  },
)

// Output might be:
// process: 5
// decision: 3
// start: 1
// end: 2
```

## Connection Statistics

| Property                 | Type     | Description                  |
|--------------------------|----------|------------------------------|
| `connectionCount`        | `int`    | Total connections            |
| `labeledConnectionCount` | `int`    | Connections with labels      |
| `avgConnectionsPerNode`  | `double` | Average connections per node |

```dart
Observer(
  builder: (_) {
    final stats = controller.stats;
    if (stats == null) return const SizedBox.shrink();

    return Column(
      children: [
        Text('${stats.connectionCount} connections'),
        Text('${stats.labeledConnectionCount} with labels'),
        Text('Avg: ${stats.avgConnectionsPerNode.toStringAsFixed(1)} per node'),
      ],
    );
  },
)
```

## Selection Statistics

| Property                  | Type   | Description                          |
|---------------------------|--------|--------------------------------------|
| `selectedNodeCount`       | `int`  | Number of selected nodes             |
| `selectedConnectionCount` | `int`  | Number of selected connections       |
| `selectedCount`           | `int`  | Total selected (nodes + connections) |
| `hasSelection`            | `bool` | Whether anything is selected         |
| `isMultiSelection`        | `bool` | Whether multiple items are selected  |

### Selection-Aware UI

```dart
Observer(
  builder: (_) {
    final stats = controller.stats;
    if (stats == null) return const SizedBox.shrink();

    if (!stats.hasSelection) {
      return const Text('Nothing selected');
    }

    return Column(
      children: [
        if (stats.selectedNodeCount > 0)
          Text('${stats.selectedNodeCount} nodes'),
        if (stats.selectedConnectionCount > 0)
          Text('${stats.selectedConnectionCount} connections'),
        if (stats.isMultiSelection)
          const Text('(multi-selection)'),
      ],
    );
  },
)
```

## Viewport Statistics

| Property      | Type                        | Description                                         |
|---------------|-----------------------------|-----------------------------------------------------|
| `viewport`    | `Observable<GraphViewport>` | Raw viewport observable                             |
| `zoom`        | `double`                    | Current zoom level (e.g., 1.0, 0.5, 2.0)            |
| `zoomPercent` | `int`                       | Zoom as percentage (e.g., 100, 50, 200)             |
| `pan`         | `Offset`                    | Current pan offset in graph coordinates             |
| `lodLevel`    | `String`                    | Current LOD level: 'minimal', 'standard', or 'full' |

### Zoom Display

```dart
Observer(
  builder: (_) {
    final zoomPercent = controller.stats?.zoomPercent ?? 100;
    return Text('$zoomPercent%');
  },
)
```

### Viewport Coordinates

```dart
Observer(
  builder: (_) {
    final pan = controller.stats?.pan ?? Offset.zero;
    return Text('Position: (${pan.dx.toInt()}, ${pan.dy.toInt()})');
  },
)
```

## Bounds Statistics

| Property       | Type     | Description                     |
|----------------|----------|---------------------------------|
| `bounds`       | `Rect`   | Bounding rectangle of all nodes |
| `boundsWidth`  | `double` | Width of node bounds            |
| `boundsHeight` | `double` | Height of node bounds           |
| `boundsCenter` | `Offset` | Center point of the graph       |
| `boundsArea`   | `double` | Total area of the bounds        |

```dart
Observer(
  builder: (_) {
    final stats = controller.stats;
    if (stats == null) return const SizedBox.shrink();

    return Text(
      'Canvas: ${stats.boundsWidth.toInt()} × ${stats.boundsHeight.toInt()} px'
    );
  },
)
```

## Performance Statistics

| Property          | Type     | Description                         |
|-------------------|----------|-------------------------------------|
| `nodesInViewport` | `int`    | Nodes currently visible in viewport |
| `isLargeGraph`    | `bool`   | Whether graph has > 100 nodes       |
| `density`         | `double` | Nodes per million square units      |

### Performance Indicators

```dart
Observer(
  builder: (_) {
    final stats = controller.stats;
    if (stats == null) return const SizedBox.shrink();

    return Column(
      children: [
        Text('Visible: ${stats.nodesInViewport}/${stats.nodeCount}'),
        if (stats.isLargeGraph)
          const Text('Large graph - LOD recommended'),
      ],
    );
  },
)
```

## Summary Helpers

Pre-formatted strings for common displays:

| Property           | Example Output                                          |
|--------------------|---------------------------------------------------------|
| `summary`          | "25 nodes, 40 connections"                              |
| `selectionSummary` | "3 nodes, 2 connections selected" or "Nothing selected" |
| `viewportSummary`  | "100% at (0, 0)"                                        |
| `boundsSummary`    | "2400 × 1800 px"                                        |

### Status Bar Example

```dart
Observer(
  builder: (_) {
    final stats = controller.stats;
    if (stats == null) return const SizedBox.shrink();

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(stats.summary),
        Text(stats.viewportSummary),
        Text(stats.selectionSummary),
      ],
    );
  },
)

// Output: "25 nodes, 40 connections | 100% at (0, 0) | 3 nodes selected"
```

## Observable Collections

For fine-grained reactivity, access raw observables:

```dart
// Direct observable access
final nodes = controller.stats?.nodes;           // ObservableMap<String, Node>
final connections = controller.stats?.connections;  // ObservableList<Connection>
final selectedNodeIds = controller.stats?.selectedNodeIds;     // ObservableSet<String>
final selectedConnectionIds = controller.stats?.selectedConnectionIds; // ObservableSet<String>
final viewport = controller.stats?.viewport;      // Observable<GraphViewport>
```

### Granular Observers

Each stat can have its own Observer for minimal rebuilds:

```dart
Row(
  children: [
    // Only rebuilds when node count changes
    Observer(
      builder: (_) => Text('${controller.stats?.nodeCount ?? 0} nodes'),
    ),
    const SizedBox(width: 16),
    // Only rebuilds when zoom changes
    Observer(
      builder: (_) => Text('${controller.stats?.zoomPercent ?? 100}%'),
    ),
    const SizedBox(width: 16),
    // Only rebuilds when selection changes
    Observer(
      builder: (_) => Text(controller.stats?.selectionSummary ?? ''),
    ),
  ],
)
```

## Complete Example

```dart
class GraphStatusBar extends StatelessWidget {
  final NodeFlowController controller;

  const GraphStatusBar({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: Theme.of(context).colorScheme.surfaceVariant,
      child: Observer(
        builder: (_) {
          final stats = controller.stats;
          if (stats == null) return const SizedBox.shrink();

          return Row(
            children: [
              // Graph summary
              _StatChip(
                icon: Icons.circle,
                label: '${stats.nodeCount} nodes',
              ),
              const SizedBox(width: 12),
              _StatChip(
                icon: Icons.arrow_forward,
                label: '${stats.connectionCount} connections',
              ),

              const Spacer(),

              // Viewport info
              _StatChip(
                icon: Icons.zoom_in,
                label: '${stats.zoomPercent}%',
              ),
              const SizedBox(width: 12),

              // Selection info
              if (stats.hasSelection)
                _StatChip(
                  icon: Icons.select_all,
                  label: stats.selectionSummary,
                ),

              // Performance warning
              if (stats.isLargeGraph)
                const Padding(
                  padding: EdgeInsets.only(left: 12),
                  child: Tooltip(
                    message: 'Large graph - consider enabling LOD',
                    child: Icon(Icons.warning, size: 16),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _StatChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14),
        const SizedBox(width: 4),
        Text(label),
      ],
    );
  }
}
```

## API Reference

### StatsPlugin Properties

| Property                  | Type                          | Reactive | Description             |
|---------------------------|-------------------------------|----------|-------------------------|
| `nodes`                   | `ObservableMap<String, Node>` | Yes      | All nodes               |
| `connections`             | `ObservableList<Connection>`  | Yes      | All connections         |
| `selectedNodeIds`         | `ObservableSet<String>`       | Yes      | Selected node IDs       |
| `selectedConnectionIds`   | `ObservableSet<String>`       | Yes      | Selected connection IDs |
| `viewport`                | `Observable<GraphViewport>`   | Yes      | Viewport state          |
| `nodeCount`               | `int`                         | Derived  | Total nodes             |
| `visibleNodeCount`        | `int`                         | Derived  | Non-hidden nodes        |
| `lockedNodeCount`         | `int`                         | Derived  | Locked nodes            |
| `groupCount`              | `int`                         | Derived  | Group nodes             |
| `commentCount`            | `int`                         | Derived  | Comment nodes           |
| `regularNodeCount`        | `int`                         | Derived  | Regular nodes           |
| `nodesByType`             | `Map<String, int>`            | Derived  | Type breakdown          |
| `connectionCount`         | `int`                         | Derived  | Total connections       |
| `labeledConnectionCount`  | `int`                         | Derived  | Labeled connections     |
| `avgConnectionsPerNode`   | `double`                      | Derived  | Average per node        |
| `selectedNodeCount`       | `int`                         | Derived  | Selected nodes          |
| `selectedConnectionCount` | `int`                         | Derived  | Selected connections    |
| `selectedCount`           | `int`                         | Derived  | Total selected          |
| `hasSelection`            | `bool`                        | Derived  | Any selection           |
| `isMultiSelection`        | `bool`                        | Derived  | Multiple selected       |
| `zoom`                    | `double`                      | Derived  | Zoom level              |
| `zoomPercent`             | `int`                         | Derived  | Zoom percentage         |
| `pan`                     | `Offset`                      | Derived  | Pan offset              |
| `lodLevel`                | `String`                      | Derived  | LOD level name          |
| `bounds`                  | `Rect`                        | Derived  | Node bounds             |
| `boundsWidth`             | `double`                      | Derived  | Bounds width            |
| `boundsHeight`            | `double`                      | Derived  | Bounds height           |
| `boundsCenter`            | `Offset`                      | Derived  | Bounds center           |
| `boundsArea`              | `double`                      | Derived  | Bounds area             |
| `nodesInViewport`         | `int`                         | Derived  | Visible nodes           |
| `isLargeGraph`            | `bool`                        | Derived  | > 100 nodes             |
| `density`                 | `double`                      | Derived  | Nodes per area          |
| `summary`                 | `String`                      | Derived  | Graph summary           |
| `selectionSummary`        | `String`                      | Derived  | Selection summary       |
| `viewportSummary`         | `String`                      | Derived  | Viewport summary        |
| `boundsSummary`           | `String`                      | Derived  | Bounds summary          |

## See Also

- [Plugins](/docs/concepts/plugins) - Plugin system overview
- [Controller](/docs/concepts/controller) - Access controller properties directly
- [Level of Detail](/docs/plugins/lod) - Performance optimization for large graphs
