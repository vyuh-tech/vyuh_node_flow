---
title: Theming Overview
description: Customize the appearance of your node flow editor
---

# Theming Overview

::: details 🖼️ Theme Customization Overview
Side-by-side comparison showing the same workflow in three different themes: Light (white background, blue connections), Dark (dark gray background, bright connections), and Custom branded (purple/indigo color scheme with custom node styling). Each shows nodes, connections, ports, and grid.
:::

Vyuh Node Flow provides a comprehensive theming system that allows you to customize every visual aspect of your node flow editor.

## Theme Structure

The `NodeFlowTheme` is the main configuration object:

```dart
class NodeFlowTheme {
  final NodeTheme nodeTheme;
  final ConnectionStyle connectionStyle;
  final ConnectionStyle temporaryConnectionStyle;
  final ConnectionTheme connectionTheme;
  final ConnectionTheme temporaryConnectionTheme;
  final PortTheme portTheme;
  final LabelTheme labelTheme;
  final Color backgroundColor;
  final GridStyle gridStyle;
  final Color gridColor;
  final double gridSize;
}
```

## Quick Start

::: code-group

```dart [Light Theme (Default)]
NodeFlowEditor<MyData>(
  controller: controller,
  theme: NodeFlowTheme(
    nodeTheme: NodeTheme.light,
    connectionStyle: ConnectionStyles.smoothstep,
    backgroundColor: Colors.white,
    gridStyle: GridStyle.dots,
  ),
  // ...
)
```

```dart [Dark Theme]
NodeFlowEditor<MyData>(
  controller: controller,
  theme: NodeFlowTheme(
    nodeTheme: NodeTheme.dark,
    connectionStyle: ConnectionStyles.smoothstep,
    connectionTheme: ConnectionTheme.dark,
    backgroundColor: Colors.grey[900]!,
    gridColor: Colors.grey[800]!,
    portTheme: PortTheme.dark,
  ),
  // ...
)
```

:::

## Theme Components

### 1. Node Theme

Controls the appearance of nodes:

```dart
nodeTheme: NodeTheme(
  selectedBorderColor: Colors.blue,
  selectedBorderWidth: 3,
  defaultBorderColor: Colors.grey,
  defaultBorderWidth: 1,
  hoverBorderColor: Colors.blue.shade200,
)
```

**Note**: The node widget itself is fully customizable via `nodeBuilder`. The theme primarily controls selection/hover borders.

### 2. Connection Style

Choose how connections are drawn:

```dart
// Smooth curved connections
connectionStyle: ConnectionStyles.smoothstep

// Bezier curves
connectionStyle: ConnectionStyles.bezier

// Step connections
connectionStyle: ConnectionStyles.step

// Straight lines
connectionStyle: ConnectionStyles.straight
```

### 3. Connection Theme

Customize connection appearance:

```dart
connectionTheme: ConnectionTheme(
  color: Colors.blue,
  strokeWidth: 2,
  selectedColor: Colors.blue[700]!,
  selectedStrokeWidth: 3,
  startPoint: ConnectionEndPoint.none,
  endPoint: ConnectionEndPoint(
    shape: EndpointShape.triangle,
    size: 9,
  ),
)
```

### 4. Port Theme

Customize port appearance:

```dart
portTheme: PortTheme(
  size: 12,
  color: Colors.blue,
  hoverColor: Colors.blue[700]!,
  borderColor: Colors.white,
  borderWidth: 2,
)
```

### 5. Background & Grid

```dart
backgroundColor: Colors.grey[50]!,
gridStyle: GridStyle.dots, // or GridStyle.lines
gridColor: Colors.grey[300]!,
gridSize: 20, // pixels
```

## Complete Custom Theme

```dart
final customTheme = NodeFlowTheme(
  // Nodes
  nodeTheme: NodeTheme(
    selectedBorderColor: Color(0xFF6366F1),
    selectedBorderWidth: 3,
    defaultBorderColor: Color(0xFFE5E7EB),
    defaultBorderWidth: 1,
    hoverBorderColor: Color(0xFFA5B4FC),
  ),

  // Connections
  connectionStyle: ConnectionStyles.smoothstep,
  connectionTheme: ConnectionTheme(
    color: Color(0xFF6366F1),
    strokeWidth: 2,
    selectedColor: Color(0xFF4F46E5),
    selectedStrokeWidth: 3,
    startPoint: ConnectionEndPoint.none,
    endPoint: ConnectionEndPoint(
      shape: EndpointShape.triangle,
      size: 10,
      color: Color(0xFF6366F1),
    ),
  ),

  // Temporary connections (while dragging)
  temporaryConnectionStyle: ConnectionStyles.smoothstep,
  temporaryConnectionTheme: ConnectionTheme(
    color: Color(0xFF6366F1).withOpacity(0.5),
    strokeWidth: 2,
    dashPattern: [8, 4],
    startPoint: ConnectionEndPoint.none,
    endPoint: ConnectionEndPoint(
      shape: EndpointShape.triangle,
      size: 10,
    ),
  ),

  // Ports
  portTheme: PortTheme(
    size: 12,
    color: Color(0xFF6366F1),
    hoverColor: Color(0xFF4F46E5),
    borderColor: Colors.white,
    borderWidth: 2,
  ),

  // Labels
  labelTheme: LabelTheme(
    fontSize: 12,
    color: Color(0xFF1F2937),
    backgroundColor: Colors.white,
    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    borderRadius: 4,
  ),

  // Background
  backgroundColor: Color(0xFFFAFAFA),
  gridStyle: GridStyle.dots,
  gridColor: Color(0xFFE5E7EB),
  gridSize: 20,
);
```

## Responsive Themes

Adapt theme based on context:

```dart
NodeFlowTheme getTheme(BuildContext context) {
  final isDark = Theme.of(context).brightness == Brightness.dark;

  return NodeFlowTheme(
    nodeTheme: isDark ? NodeTheme.dark : NodeTheme.light,
    connectionTheme: isDark
        ? ConnectionTheme.dark
        : ConnectionTheme.light,
    backgroundColor: isDark ? Colors.grey[900]! : Colors.white,
    gridColor: isDark ? Colors.grey[800]! : Colors.grey[200]!,
    portTheme: isDark ? PortTheme.dark : PortTheme.light,
  );
}

// Usage
NodeFlowEditor<MyData>(
  controller: controller,
  theme: getTheme(context),
  // ...
)
```

## Theme Presets

Create reusable theme presets:

```dart
class FlowThemes {
  static NodeFlowTheme get blueprint => NodeFlowTheme(
    nodeTheme: NodeTheme.light,
    connectionStyle: ConnectionStyles.step,
    connectionTheme: ConnectionTheme(
      color: Colors.white,
      strokeWidth: 2,
    ),
    backgroundColor: Color(0xFF1E3A8A),
    gridStyle: GridStyle.lines,
    gridColor: Colors.white.withOpacity(0.1),
  );

  static NodeFlowTheme get minimal => NodeFlowTheme(
    nodeTheme: NodeTheme(
      selectedBorderColor: Colors.black,
      selectedBorderWidth: 2,
      defaultBorderColor: Colors.grey[300]!,
      defaultBorderWidth: 1,
    ),
    connectionStyle: ConnectionStyles.straight,
    connectionTheme: ConnectionTheme(
      color: Colors.black,
      strokeWidth: 1,
    ),
    backgroundColor: Colors.white,
    gridStyle: GridStyle.none,
  );
}
```

## Dynamic Theme Updates

Change theme at runtime:

```dart
class _MyEditorState extends State<MyEditor> {
  NodeFlowTheme _currentTheme = NodeFlowTheme.light;

  void _toggleTheme() {
    setState(() {
      _currentTheme = _currentTheme == NodeFlowTheme.light
          ? NodeFlowTheme.dark
          : NodeFlowTheme.light;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ElevatedButton(
          onPressed: _toggleTheme,
          child: Text('Toggle Theme'),
        ),
        Expanded(
          child: NodeFlowEditor<MyData>(
            controller: controller,
            theme: _currentTheme,
            // ...
          ),
        ),
      ],
    );
  }
}
```

## Best Practices

1. **Consistency**: Keep theme consistent with your app's design system
2. **Contrast**: Ensure sufficient contrast for accessibility
3. **Performance**: Theme changes trigger full repaints, use sparingly
4. **Testing**: Test themes in different lighting conditions
5. **Presets**: Create reusable theme presets for common styles

## Next Steps

- [Node Theme](/docs/theming/node-theme) - Detailed node theming
- [Connection Theme](/docs/theming/connection-theme) - Connection customization
- [Examples](/docs/examples/) - See themes in action
