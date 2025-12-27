---
title: Grid Styles
description: Customize the background grid pattern of your flow editor
---

# Grid Styles

Vyuh Node Flow offers multiple grid style options to customize the background pattern of your flow editor canvas. The grid provides visual reference points that help users align and organize nodes.

::: info
**Why Grids Matter**: A well-chosen grid style helps users align nodes, judge distances, and creates a professional appearance without being distracting.

:::

## Available Grid Styles

::: details 🖼️ All Grid Styles Comparison
Five-panel comparison showing each grid style on identical canvas: Lines (full grid), Dots (intersection points only), Cross (small + marks), Hierarchical (major/minor lines), None (blank). Each labeled.
:::

### Lines Grid

The most common grid style with evenly spaced vertical and horizontal lines, providing clear visual reference.

```dart
final theme = NodeFlowTheme.light.copyWith(
  gridStyle: GridStyles.lines,
  gridSize: 20.0,              // Distance between lines
  gridColor: Colors.grey[300], // Line color
);
```

**Best for**: Technical diagrams, circuit design, when precise alignment is important

::: code-group

```dart [Fine Grid]
NodeFlowTheme.light.copyWith(
  gridStyle: GridStyles.lines,
  gridSize: 10.0,  // Fine grid
  gridColor: Colors.grey[200],
)
```

```dart [Medium Grid]
NodeFlowTheme.light.copyWith(
  gridStyle: GridStyles.lines,
  gridSize: 20.0,  // Medium grid (default)
  gridColor: Colors.grey[300],
)
```

```dart [Coarse Grid]
NodeFlowTheme.light.copyWith(
  gridStyle: GridStyles.lines,
  gridSize: 40.0,  // Coarse grid
  gridColor: Colors.grey[400],
)
```

:::

A more subtle alternative with dots at grid intersections, reducing visual clutter while maintaining reference points.

```dart
final theme = NodeFlowTheme.light.copyWith(
  gridStyle: GridStyles.dots,
  gridSize: 20.0,
  gridColor: Colors.grey[300],
);
```

**Best for**: Clean interfaces, when you want subtle guidance, modern designs

::: code-group

```dart [Small Dots]
NodeFlowTheme.light.copyWith(
  gridStyle: DotsGridStyle(dotSize: 1.5),
  gridSize: 20.0,
)
```

```dart [Medium Dots]
NodeFlowTheme.light.copyWith(
  gridStyle: DotsGridStyle(dotSize: 2.0), // Default
  gridSize: 20.0,
)
```

```dart [Large Dots]
NodeFlowTheme.light.copyWith(
  gridStyle: DotsGridStyle(dotSize: 3.0),
  gridSize: 20.0,
)
```

:::

Features small crosses at grid intersections, offering a balance between visibility and subtlety.

```dart
final theme = NodeFlowTheme.light.copyWith(
  gridStyle: GridStyles.cross,
  gridSize: 20.0,
  gridColor: Colors.grey[300],
);
```

**Best for**: Engineering diagrams, when dots are too subtle but lines are too prominent

::: code-group

```dart [Small Crosses]
NodeFlowTheme.light.copyWith(
  gridStyle: CrossGridStyle(crossSize: 3.0),
  gridSize: 20.0,
)
```

```dart [Medium Crosses]
NodeFlowTheme.light.copyWith(
  gridStyle: CrossGridStyle(crossSize: 4.0), // Default
  gridSize: 20.0,
)
```

```dart [Large Crosses]
NodeFlowTheme.light.copyWith(
  gridStyle: CrossGridStyle(crossSize: 6.0),
  gridSize: 20.0,
)
```

:::

Renders both minor and major grid lines at different intervals, with major lines appearing every 5 minor grid cells by default. Useful for complex diagrams requiring multiple levels of visual organization.

```dart
// Use default hierarchical (5x multiplier)
final theme = NodeFlowTheme.light.copyWith(
  gridStyle: GridStyles.hierarchical,
  gridSize: 20.0,  // Minor grid size
);

// Custom multiplier for major grid lines
final customTheme = NodeFlowTheme.light.copyWith(
  gridStyle: HierarchicalGridStyle(majorGridMultiplier: 10),
  gridSize: 20.0,
);
```

**Best for**: Large, complex diagrams; architectural drawings; when you need multiple levels of organization

::: code-group

```dart [Standard]
NodeFlowTheme.light.copyWith(
  gridStyle: HierarchicalGridStyle(
    majorGridMultiplier: 5,  // Major line every 5 cells
  ),
  gridSize: 20.0,
)
```

```dart [Wide Spacing]
NodeFlowTheme.light.copyWith(
  gridStyle: HierarchicalGridStyle(
    majorGridMultiplier: 10,  // Major line every 10 cells
  ),
  gridSize: 20.0,
)
```

```dart [Narrow Spacing]
NodeFlowTheme.light.copyWith(
  gridStyle: HierarchicalGridStyle(
    majorGridMultiplier: 3,  // Major line every 3 cells
  ),
  gridSize: 20.0,
)
```

```dart [Custom Colors]
NodeFlowTheme.light.copyWith(
  gridStyle: HierarchicalGridStyle(
    majorGridMultiplier: 5,
    majorGridColor: Colors.blue[200],
    minorGridColor: Colors.grey[200],
  ),
  gridSize: 20.0,
)
```

:::

Provides a clean canvas with no background pattern.

```dart
final theme = NodeFlowTheme.light.copyWith(
  gridStyle: GridStyles.none,
);
```

**Best for**: Presentations, screenshots, when grid is distracting

## Customizing Grid Appearance

Control the grid size and color through the theme:

```dart
final theme = NodeFlowTheme.light.copyWith(
  gridStyle: GridStyles.lines,
  gridSize: 20.0,              // Size of each grid cell in pixels
  gridColor: Colors.grey[300], // Grid line/dot color
  backgroundColor: Colors.white, // Canvas background
);

controller.setTheme(theme);
```

## Dark Theme Grids

Adjust grid colors for dark themes:

::: code-group

```dart [Dark Lines]
NodeFlowTheme.dark.copyWith(
  gridStyle: GridStyles.lines,
  gridSize: 20.0,
  gridColor: Colors.grey[800],      // Darker lines
  backgroundColor: Colors.grey[900], // Dark background
)
```

```dart [Dark Dots]
NodeFlowTheme.dark.copyWith(
  gridStyle: GridStyles.dots,
  gridSize: 20.0,
  gridColor: Colors.grey[700],      // Subtle dots
  backgroundColor: Colors.black,
)
```

```dart [Dark Hierarchical]
NodeFlowTheme.dark.copyWith(
  gridStyle: HierarchicalGridStyle(
    majorGridMultiplier: 5,
    majorGridColor: Colors.grey[700],
    minorGridColor: Colors.grey[850],
  ),
  gridSize: 20.0,
  backgroundColor: Colors.grey[900],
)
```

:::

## Grid Snapping

Enable grid snapping to help users align nodes:

```dart
final controller = NodeFlowController(
  config: NodeFlowConfig(
    snapToGrid: true,           // Enable snapping
    gridSize: 20.0,              // Snap to 20px grid
    snapAnnotationsToGrid: true, // Also snap annotations
  ),
);
```

::: info
**Grid Snapping**: When enabled, nodes automatically align to grid intersections as you drag them, making it easy to create perfectly aligned layouts.

:::

Users can toggle snapping on/off:
- **Keyboard**: Press `N` to toggle
- **Programmatically**: `controller.config.toggleSnapping()`

## Dynamic Grid Style Changes

Change grid style at runtime:

```dart
// Switch to dots
controller.theme = controller.theme.copyWith(
  gridStyle: GridStyles.dots,
);

// Switch to lines
controller.theme = controller.theme.copyWith(
  gridStyle: GridStyles.lines,
);

// Turn off grid
controller.theme = controller.theme.copyWith(
  gridStyle: GridStyles.none,
);
```

## Grid Style Selector

Create a UI to let users choose grid styles:

```dart
class GridStyleSelector extends StatelessWidget {
  final NodeFlowController controller;

  const GridStyleSelector({required this.controller});

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<GridStyle>(
      icon: Icon(Icons.grid_on),
      tooltip: 'Grid Style',
      onSelected: (style) {
        controller.theme = controller.theme.copyWith(gridStyle: style);
      },
      itemBuilder: (context) => [
        PopupMenuItem(
          value: GridStyles.lines,
          child: Row(
            children: [
              Icon(Icons.grid_on),
              SizedBox(width: 8),
              Text('Lines'),
            ],
          ),
        ),
        PopupMenuItem(
          value: GridStyles.dots,
          child: Row(
            children: [
              Icon(Icons.grid_4x4),
              SizedBox(width: 8),
              Text('Dots'),
            ],
          ),
        ),
        PopupMenuItem(
          value: GridStyles.cross,
          child: Row(
            children: [
              Icon(Icons.add),
              SizedBox(width: 8),
              Text('Crosses'),
            ],
          ),
        ),
        PopupMenuItem(
          value: GridStyles.hierarchical,
          child: Row(
            children: [
              Icon(Icons.view_module),
              SizedBox(width: 8),
              Text('Hierarchical'),
            ],
          ),
        ),
        PopupMenuItem(
          value: GridStyles.none,
          child: Row(
            children: [
              Icon(Icons.grid_off),
              SizedBox(width: 8),
              Text('None'),
            ],
          ),
        ),
      ],
    );
  }
}
```

## Custom Grid Styles

Create your own grid style by extending `GridStyle`:

```dart
class DiagonalGridStyle extends GridStyle {
  const DiagonalGridStyle();

  @override
  void paint(
    Canvas canvas,
    Size size,
    double gridSize,
    Color color,
    GraphViewport viewport,
  ) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.0;

    // Calculate visible area
    final startX = (-viewport.x / viewport.zoom).floorToDouble();
    final startY = (-viewport.y / viewport.zoom).floorToDouble();
    final endX = startX + (size.width / viewport.zoom);
    final endY = startY + (size.height / viewport.zoom);

    // Draw diagonal lines
    for (var x = (startX / gridSize).floor() * gridSize;
         x <= endX;
         x += gridSize) {
      for (var y = (startY / gridSize).floor() * gridSize;
           y <= endY;
           y += gridSize) {
        // Draw small diagonal line
        canvas.drawLine(
          Offset(x, y),
          Offset(x + 5, y + 5),
          paint,
        );
      }
    }
  }
}

// Usage
final theme = NodeFlowTheme.light.copyWith(
  gridStyle: DiagonalGridStyle(),
  gridSize: 30.0,
);
```

## Comparison Guide

| Style | Visibility | Clutter | Best Use Case |
| ----- | ---------- | ------- | ------------- |
| **Lines** | High | Medium | Technical diagrams, precision work |
| **Dots** | Medium | Low | Clean interfaces, modern designs |
| **Cross** | Medium | Low | Engineering, balance of subtle/clear |
| **Hierarchical** | High | Medium | Complex diagrams, multiple org levels |
| **None** | N/A | None | Presentations, minimal designs |

## Performance Considerations

  ### Best Practices

    - **Fine grids** (small `gridSize`) require more rendering
    - **Hierarchical** grids are slightly more expensive than simple styles
    - **None** grid has the best performance (no rendering)
    - Grid rendering is optimized to only draw visible area

  ### Optimization

```dart
// For large canvases with many nodes, use:
// 1. Larger grid size
NodeFlowConfig(gridSize: 40.0) // vs 20.0

// 2. Simpler grid style
gridStyle: GridStyles.dots // vs hierarchical

// 3. Or disable grid during interactions
void onPanStart() {
  controller.theme = controller.theme.copyWith(
    gridStyle: GridStyles.none,
  );
}

void onPanEnd() {
  controller.theme = controller.theme.copyWith(
    gridStyle: GridStyles.lines,
  );
}
```

## Complete Example

```dart title="Grid Style Demo"
import 'package:flutter/material.dart';
import 'package:vyuh_node_flow/vyuh_node_flow.dart';

class GridStyleDemo extends StatefulWidget {
  @override
  State<GridStyleDemo> createState() => _GridStyleDemoState();
}

class _GridStyleDemoState extends State<GridStyleDemo> {
  late final NodeFlowController controller;
  GridStyle currentStyle = GridStyles.lines;

  @override
  void initState() {
    super.initState();
    controller = NodeFlowController(
      config: NodeFlowConfig(
        snapToGrid: true,
        gridSize: 20.0,
      ),
    );

    _updateTheme();
  }

  void _updateTheme() {
    controller.setTheme(NodeFlowTheme.light.copyWith(
      gridStyle: currentStyle,
      gridSize: 20.0,
      gridColor: Colors.grey[300],
    ));
  }

  void _changeGridStyle(GridStyle style) {
    setState(() {
      currentStyle = style;
      _updateTheme();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Grid Styles'),
        actions: [
          IconButton(
            icon: Icon(Icons.grid_4x4),
            onPressed: () => _changeGridStyle(GridStyles.dots),
          ),
          IconButton(
            icon: Icon(Icons.grid_on),
            onPressed: () => _changeGridStyle(GridStyles.lines),
          ),
          IconButton(
            icon: Icon(Icons.add),
            onPressed: () => _changeGridStyle(GridStyles.cross),
          ),
          IconButton(
            icon: Icon(Icons.view_module),
            onPressed: () => _changeGridStyle(GridStyles.hierarchical),
          ),
          IconButton(
            icon: Icon(Icons.grid_off),
            onPressed: () => _changeGridStyle(GridStyles.none),
          ),
        ],
      ),
      body: NodeFlowEditor(
        controller: controller,
        nodeBuilder: (context, node) => Container(
          padding: EdgeInsets.all(16),
          child: Text(node.data),
        ),
      ),
    );
  }
}
```

## What's Next?

Explore more theming options:

- [Theme Overview](/docs/theming/overview) - Complete theming guide
- [Connection Styles](/docs/core-concepts/connections) - Customize connections
- [Node Styling](/docs/core-concepts/nodes) - Style your nodes

::: tip
**Tip**: Try different grid styles to see what works best for your use case. The right grid can dramatically improve the user experience!

:::
