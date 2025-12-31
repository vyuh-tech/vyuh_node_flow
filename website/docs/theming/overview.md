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
class NodeFlowTheme extends ThemeExtension<NodeFlowTheme> {
  final NodeTheme nodeTheme;
  final ConnectionTheme connectionTheme;
  final ConnectionTheme temporaryConnectionTheme;
  final Duration connectionAnimationDuration;
  final PortTheme portTheme;
  final LabelTheme labelTheme;
  final GridTheme gridTheme;
  final SelectionTheme selectionTheme;
  final CursorTheme cursorTheme;
  final ResizerTheme resizerTheme;
  final Color backgroundColor;
}
```

## Quick Start

::: code-group

```dart [Light Theme (Default)]
NodeFlowEditor<MyData, dynamic>(
  controller: controller,
  theme: NodeFlowTheme.light,
  // ...
)
```

```dart [Dark Theme]
NodeFlowEditor<MyData, dynamic>(
  controller: controller,
  theme: NodeFlowTheme.dark,
  // ...
)
```

```dart [Custom Theme]
NodeFlowEditor<MyData, dynamic>(
  controller: controller,
  theme: NodeFlowTheme.light.copyWith(
    backgroundColor: Colors.grey[50],
    gridTheme: GridTheme.light.copyWith(
      style: GridStyles.lines,
    ),
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
  backgroundColor: Colors.white,
  selectedBackgroundColor: Color(0xFFF5F5F5),
  highlightBackgroundColor: Color(0xFFE3F2FD),
  borderColor: Color(0xFFE0E0E0),
  selectedBorderColor: Colors.blue,
  highlightBorderColor: Color(0xFF42A5F5),
  borderWidth: 2.0,
  selectedBorderWidth: 2.0,
  borderRadius: BorderRadius.all(Radius.circular(8.0)),
  titleStyle: TextStyle(fontSize: 14.0, color: Color(0xFF333333)),
  contentStyle: TextStyle(fontSize: 12.0, color: Color(0xFF666666)),
)
```

**Note**: The node widget itself is fully customizable via `nodeBuilder`. The theme primarily controls selection/hover borders.

### 2. Connection Style

Connection styles are configured via `ConnectionTheme`. Choose how connections are drawn:

```dart
// Use the style property within ConnectionTheme
connectionTheme: ConnectionTheme.light.copyWith(
  style: ConnectionStyles.smoothstep, // Smooth curved step connections (default)
)

// Available styles:
// ConnectionStyles.smoothstep - 90-degree step with rounded corners
// ConnectionStyles.bezier - Smooth bezier curves
// ConnectionStyles.step - 90-degree step without rounded corners
// ConnectionStyles.straight - Straight lines
// ConnectionStyles.customBezier - Configurable bezier curves
```

### 3. Connection Theme

Customize connection appearance:

```dart
connectionTheme: ConnectionTheme(
  style: ConnectionStyles.smoothstep,
  color: Color(0xFF666666),
  selectedColor: Colors.blue,
  highlightColor: Color(0xFF42A5F5),
  highlightBorderColor: Color(0xFF1565C0),
  strokeWidth: 2.0,
  selectedStrokeWidth: 3.0,
  startPoint: ConnectionEndPoint.none,
  endPoint: ConnectionEndPoint.capsuleHalf,
  endpointColor: Color(0xFF666666),
  endpointBorderColor: Color(0xFF444444),
  endpointBorderWidth: 0.0,
  bezierCurvature: 0.5,
  cornerRadius: 4.0,
  portExtension: 20.0,
  backEdgeGap: 20.0,
  hitTolerance: 8.0,
)
```

### 4. Port Theme

Customize port appearance:

```dart
portTheme: PortTheme(
  size: Size(12, 12),
  color: Color(0xFFBABABA),
  connectedColor: Color(0xFF2196F3),
  highlightColor: Color(0xFF42A5F5),
  highlightBorderColor: Color(0xFF000000),
  borderColor: Colors.transparent,
  borderWidth: 0.0,
  showLabel: false,
  labelOffset: 4.0,
)
```

### 5. Background & Grid

```dart
backgroundColor: Colors.grey[50]!,
gridTheme: GridTheme(
  color: Colors.grey[300]!,
  size: 20.0,              // pixels between grid lines
  thickness: 1.0,          // line/dot thickness
  style: GridStyles.dots,  // or GridStyles.lines, GridStyles.cross, etc.
),
```

## Complete Custom Theme

```dart
final customTheme = NodeFlowTheme.light.copyWith(
  // Nodes
  nodeTheme: NodeTheme.light.copyWith(
    selectedBorderColor: Color(0xFF6366F1),
    selectedBorderWidth: 3.0,
    borderColor: Color(0xFFE5E7EB),
    borderWidth: 1.0,
    highlightBorderColor: Color(0xFFA5B4FC),
  ),

  // Connections
  connectionTheme: ConnectionTheme.light.copyWith(
    style: ConnectionStyles.smoothstep,
    color: Color(0xFF6366F1),
    strokeWidth: 2.0,
    selectedColor: Color(0xFF4F46E5),
    selectedStrokeWidth: 3.0,
    startPoint: ConnectionEndPoint.none,
    endPoint: ConnectionEndPoint.capsuleHalf,
    endpointColor: Color(0xFF6366F1),
  ),

  // Temporary connections (while dragging)
  temporaryConnectionTheme: ConnectionTheme.light.copyWith(
    color: Color(0xFF6366F1).withOpacity(0.5),
    strokeWidth: 2.0,
    dashPattern: [8, 4],
    startPoint: ConnectionEndPoint.none,
    endPoint: ConnectionEndPoint.capsuleHalf,
  ),

  // Ports
  portTheme: PortTheme.light.copyWith(
    size: Size(12, 12),
    color: Color(0xFF6366F1),
    highlightColor: Color(0xFF4F46E5),
    borderColor: Colors.white,
    borderWidth: 2.0,
  ),

  // Labels
  labelTheme: LabelTheme.light.copyWith(
    textStyle: TextStyle(
      fontSize: 12.0,
      color: Color(0xFF1F2937),
    ),
    backgroundColor: Colors.white,
    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    borderRadius: BorderRadius.circular(4),
  ),

  // Background & Grid
  backgroundColor: Color(0xFFFAFAFA),
  gridTheme: GridTheme.light.copyWith(
    style: GridStyles.dots,
    color: Color(0xFFE5E7EB),
    size: 20.0,
  ),
);
```

## Responsive Themes

Adapt theme based on context:

```dart
NodeFlowTheme getTheme(BuildContext context) {
  final isDark = Theme.of(context).brightness == Brightness.dark;

  return isDark ? NodeFlowTheme.dark : NodeFlowTheme.light;
}

// Usage
NodeFlowEditor<MyData, dynamic>(
  controller: controller,
  theme: getTheme(context),
  // ...
)
```

## Theme Presets

Create reusable theme presets:

```dart
class FlowThemes {
  static NodeFlowTheme get blueprint => NodeFlowTheme.light.copyWith(
    connectionTheme: ConnectionTheme.light.copyWith(
      style: ConnectionStyles.step,
      color: Colors.white,
      strokeWidth: 2.0,
    ),
    backgroundColor: Color(0xFF1E3A8A),
    gridTheme: GridTheme.light.copyWith(
      style: GridStyles.lines,
      color: Colors.white.withOpacity(0.1),
    ),
  );

  static NodeFlowTheme get minimal => NodeFlowTheme.light.copyWith(
    nodeTheme: NodeTheme.light.copyWith(
      selectedBorderColor: Colors.black,
      selectedBorderWidth: 2.0,
      borderColor: Colors.grey[300]!,
      borderWidth: 1.0,
    ),
    connectionTheme: ConnectionTheme.light.copyWith(
      style: ConnectionStyles.straight,
      color: Colors.black,
      strokeWidth: 1.0,
    ),
    backgroundColor: Colors.white,
    gridTheme: GridTheme.light.copyWith(
      style: GridStyles.none,
    ),
  );
}
```

## Dynamic Theme Updates

Change theme at runtime:

```dart
class _MyEditorState extends State<MyEditor> {
  bool _isDark = false;

  NodeFlowTheme get _currentTheme => _isDark
      ? NodeFlowTheme.dark
      : NodeFlowTheme.light;

  void _toggleTheme() {
    setState(() {
      _isDark = !_isDark;
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
          child: NodeFlowEditor<MyData, dynamic>(
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
