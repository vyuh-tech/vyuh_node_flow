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
  gridTheme: GridTheme(
    style: GridStyles.lines,
    size: 20.0,                  // Distance between lines
    color: Colors.grey[300]!,    // Line color
    thickness: 1.0,              // Line thickness
  ),
);
```

**Best for**: Technical diagrams, circuit design, when precise alignment is important

::: code-group

```dart [Fine Grid]
NodeFlowTheme.light.copyWith(
  gridTheme: GridTheme.light.copyWith(
    style: GridStyles.lines,
    size: 10.0,  // Fine grid
    color: Colors.grey[200]!,
  ),
)
```

```dart [Medium Grid]
NodeFlowTheme.light.copyWith(
  gridTheme: GridTheme.light.copyWith(
    style: GridStyles.lines,
    size: 20.0,  // Medium grid (default)
    color: Colors.grey[300]!,
  ),
)
```

```dart [Coarse Grid]
NodeFlowTheme.light.copyWith(
  gridTheme: GridTheme.light.copyWith(
    style: GridStyles.lines,
    size: 40.0,  // Coarse grid
    color: Colors.grey[400]!,
  ),
)
```

:::

### Dots Grid

A more subtle alternative with dots at grid intersections, reducing visual clutter while maintaining reference points.

```dart
final theme = NodeFlowTheme.light.copyWith(
  gridTheme: GridTheme.light.copyWith(
    style: GridStyles.dots,
    size: 20.0,
    color: Colors.grey[300]!,
  ),
);
```

**Best for**: Clean interfaces, when you want subtle guidance, modern designs

::: code-group

```dart [Small Dots]
NodeFlowTheme.light.copyWith(
  gridTheme: GridTheme.light.copyWith(
    style: DotsGridStyle(dotSize: 1.5),
    size: 20.0,
  ),
)
```

```dart [Medium Dots]
NodeFlowTheme.light.copyWith(
  gridTheme: GridTheme.light.copyWith(
    style: DotsGridStyle(dotSize: 2.0), // Default uses theme thickness
    size: 20.0,
  ),
)
```

```dart [Large Dots]
NodeFlowTheme.light.copyWith(
  gridTheme: GridTheme.light.copyWith(
    style: DotsGridStyle(dotSize: 3.0),
    size: 20.0,
  ),
)
```

:::

### Cross Grid

Features small crosses at grid intersections, offering a balance between visibility and subtlety.

```dart
final theme = NodeFlowTheme.light.copyWith(
  gridTheme: GridTheme.light.copyWith(
    style: GridStyles.cross,
    size: 20.0,
    color: Colors.grey[300]!,
  ),
);
```

**Best for**: Engineering diagrams, when dots are too subtle but lines are too prominent

::: code-group

```dart [Small Crosses]
NodeFlowTheme.light.copyWith(
  gridTheme: GridTheme.light.copyWith(
    style: CrossGridStyle(crossSize: 3.0),
    size: 20.0,
  ),
)
```

```dart [Medium Crosses]
NodeFlowTheme.light.copyWith(
  gridTheme: GridTheme.light.copyWith(
    style: CrossGridStyle(crossSize: 4.0), // Default uses theme thickness * 3
    size: 20.0,
  ),
)
```

```dart [Large Crosses]
NodeFlowTheme.light.copyWith(
  gridTheme: GridTheme.light.copyWith(
    style: CrossGridStyle(crossSize: 6.0),
    size: 20.0,
  ),
)
```

:::

### Hierarchical Grid

Renders both minor and major grid lines at different intervals, with major lines appearing every 5 minor grid cells by default. Minor lines use 30% opacity and major lines use double thickness. Useful for complex diagrams requiring multiple levels of visual organization.

```dart
// Use default hierarchical (5x multiplier)
final theme = NodeFlowTheme.light.copyWith(
  gridTheme: GridTheme.light.copyWith(
    style: GridStyles.hierarchical,
    size: 20.0,  // Minor grid size
  ),
);

// Custom multiplier for major grid lines
final customTheme = NodeFlowTheme.light.copyWith(
  gridTheme: GridTheme.light.copyWith(
    style: HierarchicalGridStyle(majorGridMultiplier: 10),
    size: 20.0,
  ),
);
```

**Best for**: Large, complex diagrams; architectural drawings; when you need multiple levels of organization

::: code-group

```dart [Standard]
NodeFlowTheme.light.copyWith(
  gridTheme: GridTheme.light.copyWith(
    style: HierarchicalGridStyle(
      majorGridMultiplier: 5,  // Major line every 5 cells (default)
    ),
    size: 20.0,
  ),
)
```

```dart [Wide Spacing]
NodeFlowTheme.light.copyWith(
  gridTheme: GridTheme.light.copyWith(
    style: HierarchicalGridStyle(
      majorGridMultiplier: 10,  // Major line every 10 cells
    ),
    size: 20.0,
  ),
)
```

```dart [Narrow Spacing]
NodeFlowTheme.light.copyWith(
  gridTheme: GridTheme.light.copyWith(
    style: HierarchicalGridStyle(
      majorGridMultiplier: 3,  // Major line every 3 cells
    ),
    size: 20.0,
  ),
)
```

:::

### No Grid

Provides a clean canvas with no background pattern.

```dart
final theme = NodeFlowTheme.light.copyWith(
  gridTheme: GridTheme.light.copyWith(
    style: GridStyles.none,
  ),
);
```

**Best for**: Presentations, screenshots, when grid is distracting

## Customizing Grid Appearance

Control the grid size and color through the GridTheme:

```dart
final theme = NodeFlowTheme.light.copyWith(
  gridTheme: GridTheme(
    style: GridStyles.lines,
    size: 20.0,                  // Size of each grid cell in pixels
    color: Colors.grey[300]!,    // Grid line/dot color
    thickness: 1.0,              // Line/dot thickness
  ),
  backgroundColor: Colors.white, // Canvas background
);
```

## Dark Theme Grids

Adjust grid colors for dark themes:

::: code-group

```dart [Dark Lines]
NodeFlowTheme.dark.copyWith(
  gridTheme: GridTheme.dark.copyWith(
    style: GridStyles.lines,
    size: 20.0,
    color: Colors.grey[800]!,      // Darker lines
  ),
  backgroundColor: Colors.grey[900]!, // Dark background
)
```

```dart [Dark Dots]
NodeFlowTheme.dark.copyWith(
  gridTheme: GridTheme.dark.copyWith(
    style: GridStyles.dots,
    size: 20.0,
    color: Colors.grey[700]!,      // Subtle dots
  ),
  backgroundColor: Colors.black,
)
```

```dart [Dark Hierarchical]
NodeFlowTheme.dark.copyWith(
  gridTheme: GridTheme.dark.copyWith(
    style: HierarchicalGridStyle(majorGridMultiplier: 5),
    size: 20.0,
    color: Colors.grey[700]!,
  ),
  backgroundColor: Colors.grey[900]!,
)
```

:::

## Grid Snapping

Enable grid snapping to help users align nodes:

```dart
final controller = NodeFlowController(
  config: NodeFlowConfig(
    snapToGrid: true,            // Enable node snapping
    gridSize: 20.0,              // Snap to 20px grid
    snapAnnotationsToGrid: true, // Also snap annotations
  ),
);
```

::: info
**Grid Snapping**: When enabled, nodes automatically align to grid intersections as you drag them, making it easy to create perfectly aligned layouts.

:::

Users can toggle snapping programmatically:
- `controller.config.toggleSnapping()` - Toggle both node and annotation snapping
- `controller.config.toggleNodeSnapping()` - Toggle only node snapping
- `controller.config.toggleAnnotationSnapping()` - Toggle only annotation snapping

## Dynamic Grid Style Changes

Change grid style at runtime by providing a new theme to the NodeFlowEditor widget:

```dart
// Example: dynamically changing grid style
NodeFlowTheme currentTheme = NodeFlowTheme.light;

// Switch to dots
currentTheme = currentTheme.copyWith(
  gridTheme: currentTheme.gridTheme.copyWith(style: GridStyles.dots),
);

// Switch to lines
currentTheme = currentTheme.copyWith(
  gridTheme: currentTheme.gridTheme.copyWith(style: GridStyles.lines),
);

// Turn off grid
currentTheme = currentTheme.copyWith(
  gridTheme: currentTheme.gridTheme.copyWith(style: GridStyles.none),
);
```

## Grid Style Selector

Create a UI to let users choose grid styles:

```dart
class GridStyleSelector extends StatefulWidget {
  final NodeFlowTheme initialTheme;
  final ValueChanged<NodeFlowTheme> onThemeChanged;

  const GridStyleSelector({
    required this.initialTheme,
    required this.onThemeChanged,
  });

  @override
  State<GridStyleSelector> createState() => _GridStyleSelectorState();
}

class _GridStyleSelectorState extends State<GridStyleSelector> {
  late NodeFlowTheme _currentTheme;

  @override
  void initState() {
    super.initState();
    _currentTheme = widget.initialTheme;
  }

  void _changeGridStyle(GridStyle style) {
    setState(() {
      _currentTheme = _currentTheme.copyWith(
        gridTheme: _currentTheme.gridTheme.copyWith(style: style),
      );
    });
    widget.onThemeChanged(_currentTheme);
  }

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<GridStyle>(
      icon: Icon(Icons.grid_on),
      tooltip: 'Grid Style',
      onSelected: _changeGridStyle,
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

Create your own grid style by extending `GridStyle` and implementing `paintGrid`:

```dart
class DiagonalGridStyle extends GridStyle {
  const DiagonalGridStyle({this.lineLength = 5.0});

  final double lineLength;

  @override
  void paintGrid(
    Canvas canvas,
    NodeFlowTheme theme,
    ({double left, double top, double right, double bottom}) gridArea,
  ) {
    final paint = createGridPaint(theme);
    final gridSize = theme.gridTheme.size;

    // Calculate grid-aligned start positions
    final startX = (gridArea.left / gridSize).floor() * gridSize;
    final startY = (gridArea.top / gridSize).floor() * gridSize;

    // Draw diagonal lines at each grid intersection
    for (double x = startX; x <= gridArea.right; x += gridSize) {
      for (double y = startY; y <= gridArea.bottom; y += gridSize) {
        // Draw small diagonal line
        canvas.drawLine(
          Offset(x, y),
          Offset(x + lineLength, y + lineLength),
          paint,
        );
      }
    }
  }
}

// Usage
final theme = NodeFlowTheme.light.copyWith(
  gridTheme: GridTheme.light.copyWith(
    style: DiagonalGridStyle(lineLength: 5.0),
    size: 30.0,
  ),
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
NodeFlowTheme.light.copyWith(
  gridTheme: GridTheme.light.copyWith(size: 40.0), // vs 20.0
)

// 2. Simpler grid style
NodeFlowTheme.light.copyWith(
  gridTheme: GridTheme.light.copyWith(style: GridStyles.dots), // vs hierarchical
)

// 3. Or disable grid for best performance
NodeFlowTheme.light.copyWith(
  gridTheme: GridTheme.light.copyWith(style: GridStyles.none),
)
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
  NodeFlowTheme currentTheme = NodeFlowTheme.light;

  @override
  void initState() {
    super.initState();
    controller = NodeFlowController(
      config: NodeFlowConfig(
        snapToGrid: true,
        gridSize: 20.0,
      ),
    );
  }

  void _changeGridStyle(GridStyle style) {
    setState(() {
      currentTheme = currentTheme.copyWith(
        gridTheme: currentTheme.gridTheme.copyWith(style: style),
      );
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
        theme: currentTheme,
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
- [Connection Styles](/docs/concepts/connections) - Customize connections
- [Node Styling](/docs/concepts/nodes) - Style your nodes

::: tip
**Tip**: Try different grid styles to see what works best for your use case. The right grid can dramatically improve the user experience!

:::
