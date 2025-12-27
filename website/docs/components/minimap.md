---
title: Minimap
description: Navigate large flow diagrams with an overview minimap
---

# Minimap

The minimap provides a bird's-eye view of your entire flow diagram, making it easy to navigate large graphs and understand the overall structure at a glance.

::: details 🖼️ Minimap Component
NodeFlowEditor with minimap in bottom-right corner. Minimap shows scaled-down view of entire graph with nodes as small rectangles, viewport indicator as highlighted rectangle showing current visible area. Main editor shows zoomed-in portion of the graph.
:::

## Basic Usage

Add a minimap to your editor:

```dart
import 'package:flutter/material.dart';
import 'package:vyuh_node_flow/vyuh_node_flow.dart';

class FlowEditorWithMinimap extends StatelessWidget {
  final NodeFlowController controller;

  const FlowEditorWithMinimap({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Main editor
        NodeFlowEditor(
          controller: controller,
          nodeBuilder: (context, node) => MyNodeWidget(node),
        ),

        // Minimap in bottom-right corner
        Positioned(
          bottom: 16,
          right: 16,
          child: NodeFlowMinimap(
            controller: controller,
            width: 200,
            height: 150,
          ),
        ),
      ],
    );
  }
}
```

## Configuration

### Size

Control the minimap dimensions:

```dart
NodeFlowMinimap(
  controller: controller,
  width: 250,    // Width in pixels
  height: 180,   // Height in pixels
)
```

::: info
**Recommended Sizes**: Keep the minimap between 150-300px wide for optimal usability. Too small makes it hard to see, too large defeats its purpose.

:::

### Positioning

Position the minimap anywhere on screen:

```dart
// Bottom-right (most common)
Positioned(
  bottom: 16,
  right: 16,
  child: NodeFlowMinimap(controller: controller),
)

// Bottom-left
Positioned(
  bottom: 16,
  left: 16,
  child: NodeFlowMinimap(controller: controller),
)

// Top-right
Positioned(
  top: 16,
  right: 16,
  child: NodeFlowMinimap(controller: controller),
)

// Top-left
Positioned(
  top: 16,
  left: 16,
  child: NodeFlowMinimap(controller: controller),
)
```

### Styling

Customize the minimap appearance:

```dart
NodeFlowMinimap(
  controller: controller,
  width: 200,
  height: 150,
  backgroundColor: Colors.grey[100]!,
  borderColor: Colors.grey[400]!,
  borderWidth: 1,
  borderRadius: 8,
  nodeColor: Colors.blue[200]!,
  viewportColor: Colors.blue.withOpacity(0.3),
  viewportBorderColor: Colors.blue,
  viewportBorderWidth: 2,
)
```

## Theming

Apply consistent styling through theme:

```dart
class MinimapTheme {
  static NodeFlowMinimap styled({
    required NodeFlowController controller,
    required bool isDark,
  }) {
    return NodeFlowMinimap(
      controller: controller,
      width: 220,
      height: 160,
      backgroundColor: isDark ? Colors.grey[900]! : Colors.white,
      borderColor: isDark ? Colors.grey[700]! : Colors.grey[300]!,
      borderWidth: 1,
      borderRadius: 12,
      nodeColor: isDark ? Colors.blue[700]! : Colors.blue[300]!,
      viewportColor: Colors.blue.withOpacity(0.2),
      viewportBorderColor: Colors.blue,
      viewportBorderWidth: 2,
    );
  }
}

// Usage
MinimapTheme.styled(
  controller: controller,
  isDark: Theme.of(context).brightness == Brightness.dark,
)
```

## Interactive Features

### Viewport Navigation

Click or drag on the minimap to navigate:

```dart
NodeFlowMinimap(
  controller: controller,
  onViewportChanged: (Rect viewport) {
    print('Viewport moved to: $viewport');
  },
)
```

**Interactions**:
- **Click**: Jump to that area of the canvas
- **Drag viewport**: Pan the main editor view
- **Drag outside viewport**: Jump to and start dragging from new location

### Reactive Updates

The minimap automatically updates when:
- Nodes are added, removed, or moved
- The viewport is panned or zoomed
- Node sizes change
- The graph structure changes

## Advanced Layout

### Collapsible Minimap

Create a minimap that can be collapsed:

```dart
class CollapsibleMinimap extends StatefulWidget {
  final NodeFlowController controller;

  const CollapsibleMinimap({required this.controller});

  @override
  State<CollapsibleMinimap> createState() => _CollapsibleMinimapState();
}

class _CollapsibleMinimapState extends State<CollapsibleMinimap> {
  bool _isExpanded = true;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      bottom: 16,
      right: 16,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (_isExpanded)
            NodeFlowMinimap(
              controller: widget.controller,
              width: 220,
              height: 160,
            ),
          SizedBox(height: 8),
          IconButton(
            icon: Icon(
              _isExpanded ? Icons.expand_more : Icons.expand_less,
            ),
            onPressed: () {
              setState(() => _isExpanded = !_isExpanded);
            },
            style: IconButton.styleFrom(
              backgroundColor: Colors.white,
              elevation: 2,
            ),
          ),
        ],
      ),
    );
  }
}
```

### Resizable Minimap

Allow users to resize the minimap:

```dart
class ResizableMinimap extends StatefulWidget {
  final NodeFlowController controller;

  const ResizableMinimap({required this.controller});

  @override
  State<ResizableMinimap> createState() => _ResizableMinimapState();
}

class _ResizableMinimapState extends State<ResizableMinimap> {
  double _width = 220;
  double _height = 160;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      bottom: 16,
      right: 16,
      child: GestureDetector(
        onPanUpdate: (details) {
          setState(() {
            _width = (_width + details.delta.dx).clamp(150.0, 400.0);
            _height = (_height + details.delta.dy).clamp(100.0, 300.0);
          });
        },
        child: Stack(
          children: [
            NodeFlowMinimap(
              controller: widget.controller,
              width: _width,
              height: _height,
            ),
            // Resize handle
            Positioned(
              right: 0,
              bottom: 0,
              child: Icon(
                Icons.drag_handle,
                size: 16,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
```

### Side Panel Minimap

Integrate minimap into a side panel:

```dart
class EditorWithSidePanel extends StatelessWidget {
  final NodeFlowController controller;

  const EditorWithSidePanel({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // Main editor
        Expanded(
          flex: 3,
          child: NodeFlowEditor(
            controller: controller,
            nodeBuilder: (context, node) => MyNodeWidget(node),
          ),
        ),

        // Side panel with minimap
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
              NodeFlowMinimap(
                controller: controller,
                width: 248,
                height: 180,
              ),
              SizedBox(height: 24),
              // Additional panel content
              Text('Properties'),
              // ... more widgets
            ],
          ),
        ),
      ],
    );
  }
}
```

## Performance Optimization

The minimap is optimized for performance, but for very large graphs (1000+ nodes), consider these optimizations:

### Conditional Rendering

Only show minimap when needed:

```dart
class OptimizedMinimap extends StatelessWidget {
  final NodeFlowController controller;

  @override
  Widget build(BuildContext context) {
    return Observer(
      builder: (_) {
        final nodeCount = controller.nodes.length;

        // Only show minimap for graphs with 10+ nodes
        if (nodeCount < 10) {
          return SizedBox.shrink();
        }

        return Positioned(
          bottom: 16,
          right: 16,
          child: NodeFlowMinimap(
            controller: controller,
            width: 220,
            height: 160,
          ),
        );
      },
    );
  }
}
```

### Simplified Rendering

For extremely large graphs, the minimap automatically simplifies rendering by:
- Using solid rectangles for nodes instead of detailed shapes
- Skipping connection rendering for 500+ connections
- Reducing update frequency during rapid viewport changes

## Best Practices

1. **Position**: Bottom-right is most familiar to users
2. **Size**: Keep between 15-25% of main editor size
3. **Visibility**: Ensure good contrast between viewport and background
4. **Persistence**: Save user's show/hide preference
5. **Touch Targets**: Make interactive areas at least 44x44 pixels on mobile
6. **Performance**: Consider hiding for graphs with 1000+ nodes

## Common Patterns

### Toggle Button

Add a button to show/hide the minimap:

```dart
class MinimapToggle extends StatefulWidget {
  final NodeFlowController controller;

  @override
  State<MinimapToggle> createState() => _MinimapToggleState();
}

class _MinimapToggleState extends State<MinimapToggle> {
  bool _showMinimap = true;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        NodeFlowEditor(
          controller: widget.controller,
          nodeBuilder: (context, node) => MyNodeWidget(node),
        ),

        // Toggle button
        Positioned(
          top: 16,
          right: 16,
          child: IconButton(
            icon: Icon(Icons.map),
            onPressed: () => setState(() => _showMinimap = !_showMinimap),
            tooltip: _showMinimap ? 'Hide minimap' : 'Show minimap',
          ),
        ),

        // Minimap
        if (_showMinimap)
          Positioned(
            bottom: 16,
            right: 16,
            child: NodeFlowMinimap(controller: widget.controller),
          ),
      ],
    );
  }
}
```

### Node Count Badge

Show node count on minimap:

```dart
Stack(
  children: [
    NodeFlowMinimap(controller: controller),
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
)
```

## Accessibility

The minimap supports accessibility features:

- **Keyboard Navigation**: Navigate using arrow keys when focused
- **Screen Readers**: Announces viewport position changes
- **High Contrast**: Respects system high contrast settings
- **Focus Indicators**: Clear focus outline when navigating with keyboard

## See Also

- [NodeFlowEditor](/docs/components/node-flow-editor) - Main editor component
- [Controller](/docs/core-concepts/controller) - Managing viewport and navigation
- [Examples](/docs/examples/) - See minimap in action
