---
title: Viewport Animations
description: Smooth animated transitions for panning, zooming, and navigating the graph
---

# Viewport Animations

Node Flow provides smooth viewport animations for navigating your graph. Animate to specific nodes, positions, bounds, or zoom levels with customizable duration and easing.

## Quick Start

All animation methods are available on the controller:

```dart
// Animate to center on a node
controller.animateToNode('node-123');

// Animate to show multiple nodes
controller.animateToNodes(['node-1', 'node-2', 'node-3']);

// Animate to a specific position
controller.animateToPosition(GraphOffset.fromXY(500, 300));

// Animate to fit all nodes
controller.animateToBounds(controller.nodesBounds);

// Animate to a zoom level
controller.animateToScale(1.5);
```

## Animation Methods

### animateToNode

Centers the viewport on a specific node with optional zoom:

```dart
// Center on node at 100% zoom
controller.animateToNode('node-123');

// Center on node at 150% zoom
controller.animateToNode('node-123', zoom: 1.5);

// Center on node, keep current zoom
controller.animateToNode('node-123', zoom: null);

// Custom duration and curve
controller.animateToNode(
  'node-123',
  duration: Duration(milliseconds: 600),
  curve: Curves.easeOutQuart,
);
```

**Parameters:**

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `nodeId` | `String` | required | ID of the node to center on |
| `zoom` | `double?` | `1.0` | Target zoom level. `null` preserves current |
| `duration` | `Duration` | `400ms` | Animation duration |
| `curve` | `Curve` | `easeInOut` | Animation curve |

### animateToNodes

Animates the viewport to show all specified nodes. For a single node, this behaves like `animateToNode`. For multiple nodes, it calculates their combined bounding box and centers on them.

```dart
// Show multiple nodes
controller.animateToNodes(['node-1', 'node-2', 'node-3']);

// Show selected nodes with more padding
controller.animateToNodes(
  controller.selectedNodeIds.toList(),
  padding: 100,
);

// Custom duration and curve
controller.animateToNodes(
  ['task-a', 'task-b', 'task-c'],
  duration: Duration(milliseconds: 600),
  curve: Curves.easeOutQuart,
);
```

**Parameters:**

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `nodeIds` | `List<String>` | required | List of node IDs to show |
| `padding` | `double` | `60.0` | Padding around combined bounds |
| `duration` | `Duration` | `400ms` | Animation duration |
| `curve` | `Curve` | `easeInOut` | Animation curve |

::: tip
`animateToNodes` is particularly useful for focusing on the current selection. It automatically handles the single vs. multiple node case, so you don't need conditional logic.
:::

### animateToPosition

Centers the viewport on a specific graph coordinate:

```dart
// Center on position
controller.animateToPosition(GraphOffset.fromXY(500, 300));

// Center on position with zoom change
controller.animateToPosition(
  GraphOffset.fromXY(500, 300),
  zoom: 1.5,
);
```

**Parameters:**

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `position` | `GraphOffset` | required | Graph coordinate to center on |
| `zoom` | `double?` | `null` | Target zoom level. `null` preserves current |
| `duration` | `Duration` | `400ms` | Animation duration |
| `curve` | `Curve` | `easeInOut` | Animation curve |

### animateToBounds

Fits the viewport to show a bounding rectangle:

```dart
// Fit to show all nodes
controller.animateToBounds(controller.nodesBounds);

// Fit selected nodes with more padding
final selectedBounds = controller.getNodesBounds(controller.selectedNodeIds);
controller.animateToBounds(selectedBounds, padding: 100);

// Fit a specific region
controller.animateToBounds(
  GraphRect(Rect.fromLTWH(0, 0, 500, 300)),
);
```

**Parameters:**

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `bounds` | `GraphRect` | required | Bounding rectangle in graph coordinates |
| `padding` | `double` | `50.0` | Padding around bounds in screen pixels |
| `duration` | `Duration` | `400ms` | Animation duration |
| `curve` | `Curve` | `easeInOut` | Animation curve |

### animateToScale

Animates to a zoom level, keeping the current center fixed:

```dart
// Zoom to 150%
controller.animateToScale(1.5);

// Reset to 100%
controller.animateToScale(1.0);

// Zoom out to 50%
controller.animateToScale(0.5);

// Custom animation
controller.animateToScale(
  2.0,
  duration: Duration(milliseconds: 200),
  curve: Curves.easeOut,
);
```

**Parameters:**

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `scale` | `double` | required | Target zoom level (1.0 = 100%) |
| `duration` | `Duration` | `400ms` | Animation duration |
| `curve` | `Curve` | `easeInOut` | Animation curve |

### animateToViewport

The foundation method for all viewport animations. Animates to an exact viewport state:

```dart
controller.animateToViewport(
  GraphViewport(
    x: 100,      // Translation X
    y: 50,       // Translation Y
    zoom: 1.5,   // Zoom level
  ),
);
```

**Parameters:**

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `target` | `GraphViewport` | required | Target viewport state |
| `duration` | `Duration` | `400ms` | Animation duration |
| `curve` | `Curve` | `easeInOut` | Animation curve |

## Animation Curves

Flutter provides many built-in curves for different animation feels:

| Curve | Description | Use Case |
|-------|-------------|----------|
| `Curves.easeInOut` | Slow start and end (default) | General navigation |
| `Curves.easeOut` | Fast start, slow end | Snap to destination |
| `Curves.easeIn` | Slow start, fast end | Deliberate movement |
| `Curves.easeOutQuart` | Strong deceleration | Smooth landing |
| `Curves.linear` | Constant speed | Mechanical feel |
| `Curves.elasticOut` | Bouncy end | Playful UI |

```dart
// Fast snap to node
controller.animateToNode(
  'node-123',
  curve: Curves.easeOutQuart,
  duration: Duration(milliseconds: 300),
);

// Gentle pan
controller.animateToPosition(
  position,
  curve: Curves.easeInOut,
  duration: Duration(milliseconds: 600),
);
```

## Common Patterns

### Focus on Selection

Animate to show all selected nodes using `animateToNodes`:

```dart
void focusOnSelection() {
  final selectedIds = controller.selectedNodeIds.toList();
  if (selectedIds.isEmpty) return;

  // Handles both single and multiple nodes automatically
  controller.animateToNodes(selectedIds);
}
```

For more control over single vs. multiple node behavior:

```dart
void focusOnSelectionCustom() {
  final selectedIds = controller.selectedNodeIds;
  if (selectedIds.isEmpty) return;

  if (selectedIds.length == 1) {
    // Single node: center with specific zoom
    controller.animateToNode(selectedIds.first, zoom: 1.5);
  } else {
    // Multiple nodes: fit bounds with padding
    final bounds = controller.getNodesBounds(selectedIds);
    controller.animateToBounds(bounds, padding: 80);
  }
}
```

### Zoom Controls

Build zoom in/out buttons:

```dart
class ZoomControls extends StatelessWidget {
  final NodeFlowController controller;

  const ZoomControls({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        IconButton(
          icon: const Icon(Icons.add),
          onPressed: () {
            final currentZoom = controller.viewport.zoom;
            controller.animateToScale(
              (currentZoom * 1.2).clamp(0.5, 2.0),
              duration: Duration(milliseconds: 200),
            );
          },
        ),
        IconButton(
          icon: const Icon(Icons.remove),
          onPressed: () {
            final currentZoom = controller.viewport.zoom;
            controller.animateToScale(
              (currentZoom / 1.2).clamp(0.5, 2.0),
              duration: Duration(milliseconds: 200),
            );
          },
        ),
        IconButton(
          icon: const Icon(Icons.fit_screen),
          onPressed: () {
            controller.animateToBounds(
              controller.nodesBounds,
              padding: 50,
            );
          },
        ),
      ],
    );
  }
}
```

### Navigate to Search Result

Animate to a node found by search:

```dart
void onSearchResultTap(String nodeId) {
  // First select the node
  controller.selectNode(nodeId);

  // Then animate to show it
  controller.animateToNode(
    nodeId,
    zoom: 1.0,
    duration: Duration(milliseconds: 300),
    curve: Curves.easeOut,
  );
}
```

### Keyboard Navigation

Add keyboard shortcuts for navigation:

```dart
class ViewportShortcuts {
  final NodeFlowController controller;

  ViewportShortcuts(this.controller);

  void handleKeyEvent(RawKeyEvent event) {
    if (!event.isKeyPressed(LogicalKeyboardKey.keyH)) return;

    // Ctrl+H: Fit to all nodes
    if (event.isControlPressed) {
      controller.animateToBounds(controller.nodesBounds);
    }
  }
}
```

### Animated Reset

Reset viewport to origin with animation:

```dart
void resetViewport() {
  controller.animateToViewport(
    GraphViewport(x: 0, y: 0, zoom: 1.0),
    duration: Duration(milliseconds: 400),
    curve: Curves.easeInOut,
  );
}
```

### Follow Mode

Continuously animate to follow a node:

```dart
class NodeFollower {
  final NodeFlowController controller;
  final String nodeId;
  Timer? _timer;

  NodeFollower(this.controller, this.nodeId);

  void start() {
    _timer = Timer.periodic(Duration(milliseconds: 100), (_) {
      controller.animateToNode(
        nodeId,
        zoom: null, // Keep current zoom
        duration: Duration(milliseconds: 100),
        curve: Curves.linear,
      );
    });
  }

  void stop() {
    _timer?.cancel();
    _timer = null;
  }
}
```

## Viewport Controls Widget

Complete viewport controls with animation:

```dart
class ViewportControls extends StatelessWidget {
  final NodeFlowController controller;

  const ViewportControls({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return Observer(
      builder: (_) {
        final zoomPercent = (controller.viewport.zoom * 100).round();

        return Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(8),
            boxShadow: [
              BoxShadow(
                color: Colors.black12,
                blurRadius: 4,
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Zoom in
              _ControlButton(
                icon: Icons.add,
                tooltip: 'Zoom in',
                onPressed: () => _zoomIn(),
              ),

              // Zoom level display
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Text('$zoomPercent%'),
              ),

              // Zoom out
              _ControlButton(
                icon: Icons.remove,
                tooltip: 'Zoom out',
                onPressed: () => _zoomOut(),
              ),

              const Divider(),

              // Fit all
              _ControlButton(
                icon: Icons.fit_screen,
                tooltip: 'Fit all nodes',
                onPressed: () => _fitAll(),
              ),

              // Reset view
              _ControlButton(
                icon: Icons.home,
                tooltip: 'Reset view',
                onPressed: () => _resetView(),
              ),

              // Focus selection
              if (controller.selectedNodeIds.isNotEmpty)
                _ControlButton(
                  icon: Icons.center_focus_strong,
                  tooltip: 'Focus selection',
                  onPressed: () => _focusSelection(),
                ),
            ],
          ),
        );
      },
    );
  }

  void _zoomIn() {
    final current = controller.viewport.zoom;
    controller.animateToScale(
      (current * 1.25).clamp(0.25, 4.0),
      duration: Duration(milliseconds: 200),
      curve: Curves.easeOut,
    );
  }

  void _zoomOut() {
    final current = controller.viewport.zoom;
    controller.animateToScale(
      (current / 1.25).clamp(0.25, 4.0),
      duration: Duration(milliseconds: 200),
      curve: Curves.easeOut,
    );
  }

  void _fitAll() {
    if (controller.nodes.isEmpty) return;
    controller.animateToBounds(
      controller.nodesBounds,
      padding: 50,
      duration: Duration(milliseconds: 400),
    );
  }

  void _resetView() {
    controller.animateToViewport(
      GraphViewport(x: 0, y: 0, zoom: 1.0),
      duration: Duration(milliseconds: 400),
    );
  }

  void _focusSelection() {
    final ids = controller.selectedNodeIds.toList();
    if (ids.isEmpty) return;

    controller.animateToNodes(ids);
  }
}

class _ControlButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;

  const _ControlButton({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: Icon(icon),
      tooltip: tooltip,
      onPressed: onPressed,
      iconSize: 20,
    );
  }
}
```

## Non-Animated Alternatives

For immediate viewport changes without animation, use these methods:

```dart
// Set viewport directly
controller.setViewport(GraphViewport(x: 100, y: 50, zoom: 1.5));

// Center on node immediately
controller.centerOnNodeWithZoom('node-123', zoom: 1.5);

// Set zoom directly
controller.setZoom(1.5);

// Pan directly
controller.panBy(Offset(100, 50));
```

## Performance Notes

- Animations use Flutter's `AnimationController` for smooth 60fps updates
- Matrix4 interpolation is used for efficient transform animations
- Multiple animations can be started in sequence (new animation stops previous)
- Long-running animations can be interrupted by user interaction

## API Reference

### Animation Methods

| Method | Description |
|--------|-------------|
| `animateToViewport(target, {duration, curve})` | Animate to exact viewport state |
| `animateToNode(nodeId, {zoom, duration, curve})` | Center on a single node |
| `animateToNodes(nodeIds, {padding, duration, curve})` | Center on multiple nodes |
| `animateToPosition(position, {zoom, duration, curve})` | Center on position |
| `animateToBounds(bounds, {padding, duration, curve})` | Fit bounds in view |
| `animateToScale(scale, {duration, curve})` | Animate zoom level |

### Default Values

| Parameter | Default |
|-----------|---------|
| `duration` | `Duration(milliseconds: 400)` |
| `curve` | `Curves.easeInOut` |
| `padding` | `50.0` |
| `zoom` | `1.0` (for `animateToNode`) |

## See Also

- [Controller](/docs/concepts/controller) - Viewport management methods
- [Minimap](/docs/plugins/minimap) - Click-to-navigate feature
- [Keyboard Shortcuts](/docs/advanced/keyboard-shortcuts) - Add navigation shortcuts
