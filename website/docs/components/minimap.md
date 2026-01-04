---
title: Minimap
description: Navigate large flow diagrams with an overview minimap
---

# Minimap

The minimap provides a bird's-eye view of your entire flow diagram, making it easy to navigate large graphs and understand the overall structure at a glance.

::: details Minimap Component
NodeFlowEditor with minimap in bottom-right corner. Minimap shows scaled-down view of entire graph with nodes as small rectangles, viewport indicator as highlighted rectangle showing current visible area. Main editor shows zoomed-in portion of the graph.
:::

## Basic Usage

The minimap is enabled via the `MinimapExtension` registered in your controller's config. The `NodeFlowEditor` automatically renders the minimap overlay when the extension is configured:

```dart
import 'package:flutter/material.dart';
import 'package:vyuh_node_flow/vyuh_node_flow.dart';

// Configure the controller with minimap extension
final controller = NodeFlowController<MyData, dynamic>(
  config: NodeFlowConfig(
    extensions: [
      MinimapExtension(
        visible: true,
        position: MinimapPosition.bottomRight,
        margin: 20.0,
        theme: MinimapTheme.light,
      ),
    ],
  ),
);

// The minimap is automatically rendered by NodeFlowEditor
NodeFlowEditor<MyData, dynamic>(
  controller: controller,
  theme: NodeFlowTheme.light,
  nodeBuilder: (context, node) => MyNodeWidget(node: node),
)
```

## Configuration

Configure minimap behavior directly via constructor parameters:

```dart
MinimapExtension(
  visible: true,                           // Initial visibility
  interactive: true,                       // Allow click/drag navigation
  position: MinimapPosition.bottomRight,   // Corner position
  margin: 20.0,                            // Margin from edge
  autoHighlightSelection: true,            // Highlight selected nodes
)
```

### Position Options

| Position | Description |
|----------|-------------|
| `MinimapPosition.topLeft` | Top-left corner |
| `MinimapPosition.topRight` | Top-right corner |
| `MinimapPosition.bottomLeft` | Bottom-left corner |
| `MinimapPosition.bottomRight` | Bottom-right corner (default) |

## MinimapTheme

Customize the minimap appearance via `MinimapTheme`:

```dart
MinimapExtension(
  visible: true,
  theme: MinimapTheme(
    size: Size(200, 150),              // Minimap dimensions
    backgroundColor: Color(0xFFF5F5F5),
    nodeColor: Color(0xFF1976D2),
    viewportColor: Color(0xFF1976D2),
    viewportFillOpacity: 0.1,
    viewportBorderOpacity: 0.4,
    borderColor: Color(0xFFBDBDBD),
    borderWidth: 1.0,
    borderRadius: 4.0,
    padding: EdgeInsets.all(4.0),
    showViewport: true,
    nodeBorderRadius: 2.0,
  ),
)
```

### Built-in Themes

Two built-in themes are provided:

```dart
// Light theme (default)
MinimapTheme.light

// Dark theme
MinimapTheme.dark

// Customize a theme
MinimapTheme.light.copyWith(
  nodeColor: Colors.blue,
  size: Size(250, 180),
)
```

## Controlling the Minimap

Access the minimap extension via the controller to control visibility and behavior:

```dart
// Toggle visibility
controller.minimap.toggle();
controller.minimap.show();
controller.minimap.hide();

// Check visibility
if (controller.minimap.isVisible) {
  print('Minimap is visible');
}

// Change position
controller.minimap.setPosition(MinimapPosition.topRight);
controller.minimap.cyclePosition(); // Cycle through positions

// Control interactivity
controller.minimap.enableInteraction();
controller.minimap.disableInteraction();
controller.minimap.toggleInteraction();

// Highlight specific nodes (e.g., search results)
controller.minimap.highlightNodes({'node-1', 'node-3'});
controller.minimap.clearHighlights();

// Navigate to a position
controller.minimap.centerOn(Offset(500, 300));
controller.minimap.focusNodes({'node-1', 'node-2'});
```

## Interactive Features

### Viewport Navigation

The minimap supports click and drag navigation when `interactive` is true:

**Interactions**:
- **Click**: Jump to that area of the canvas
- **Drag**: Pan the main editor view by dragging on the minimap
- **Viewport indicator**: Shows the currently visible portion of the graph

### Reactive Updates

The minimap automatically updates when:
- Nodes are added, removed, or moved
- The viewport is panned or zoomed
- Node sizes change
- The graph structure changes

## Using NodeFlowMinimap Directly

While the extension-based approach is recommended, you can also use `NodeFlowMinimap` directly for custom layouts:

```dart
// Direct widget usage with custom positioning
NodeFlowMinimap<MyData>(
  controller: controller,
  theme: MinimapTheme.light.copyWith(
    size: Size(220, 160),
  ),
  interactive: true,
)
```

### Side Panel Minimap

Integrate minimap into a side panel by using the widget directly:

```dart
class EditorWithSidePanel extends StatelessWidget {
  final NodeFlowController<MyData, dynamic> controller;

  const EditorWithSidePanel({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // Main editor (without extension-based minimap)
        Expanded(
          flex: 3,
          child: NodeFlowEditor<MyData, dynamic>(
            controller: controller,
            theme: NodeFlowTheme.light,
            nodeBuilder: (context, node) => MyNodeWidget(node: node),
          ),
        ),

        // Side panel with minimap widget
        Container(
          width: 280,
          color: Colors.grey[100],
          padding: EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Overview',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 12),
              NodeFlowMinimap<MyData>(
                controller: controller,
                theme: MinimapTheme.light.copyWith(
                  size: Size(248, 180),
                ),
              ),
              SizedBox(height: 24),
              // Additional panel content
              Text('Properties'),
            ],
          ),
        ),
      ],
    );
  }
}
```

## Performance Optimization

The minimap is optimized for performance:

- Uses `CustomPainter` for efficient rendering
- Reactively updates via MobX when graph state changes
- Renders nodes as simple rectangles (no detailed shapes)
- Does not render connections (for performance)

For very large graphs, consider hiding the minimap:

```dart
// Toggle minimap visibility based on node count
if (controller.nodes.length > 1000) {
  controller.minimap.hide();
}
```

## Best Practices

1. **Position**: Bottom-right is most familiar to users
2. **Size**: Keep between 150-300px wide for optimal usability
3. **Visibility**: Ensure good contrast between viewport and background
4. **Persistence**: Use `autoHighlightSelection` to highlight selected nodes
5. **Performance**: Consider hiding for graphs with 1000+ nodes

## Common Patterns

### Toggle Button

Add a button to show/hide the minimap using the extension API:

```dart
class MinimapToggle extends StatelessWidget {
  final NodeFlowController<MyData, dynamic> controller;

  const MinimapToggle({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Observer(
      builder: (_) {
        final isVisible = controller.minimap.isVisible;
        return IconButton(
          icon: Icon(isVisible ? Icons.map : Icons.map_outlined),
          onPressed: () => controller.minimap.toggle(),
          tooltip: isVisible ? 'Hide minimap' : 'Show minimap',
        );
      },
    );
  }
}
```

### Node Count Badge

Show node count overlaid on the minimap:

```dart
class MinimapWithBadge extends StatelessWidget {
  final NodeFlowController<MyData, dynamic> controller;

  const MinimapWithBadge({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        NodeFlowMinimap<MyData>(
          controller: controller,
          theme: MinimapTheme.light,
        ),
        Positioned(
          top: 8,
          right: 8,
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.blue,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Observer(
              builder: (_) => Text(
                '${controller.nodes.length}',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
```

## See Also

- [NodeFlowEditor](/docs/components/node-flow-editor) - Main editor component
- [Controller](/docs/core-concepts/controller) - Managing viewport and navigation
