---
title: Theme API
description: API reference for theming classes
---

# Theme API

Complete reference for all theming classes in Vyuh Node Flow.

## NodeFlowTheme

The top-level theme configuration. Extends Flutter's `ThemeExtension` for
integration with the theming system.

```dart
NodeFlowTheme({
  required NodeTheme nodeTheme,
  required ConnectionTheme connectionTheme,
  required ConnectionTheme temporaryConnectionTheme,
  Duration connectionAnimationDuration = const Duration(seconds: 2),
  required PortTheme portTheme,
  required LabelTheme labelTheme,
  required GridTheme gridTheme,
  required SelectionTheme selectionTheme,
  required CursorTheme cursorTheme,
  required ResizerTheme resizerTheme,
  Color backgroundColor = Colors.white,
})
```

::: info Most theme properties are **required**. Use `NodeFlowTheme.light` or
`NodeFlowTheme.dark` as starting points.

Feature-specific themes like minimap and debug visualization are configured via
their respective extensions (e.g., `MinimapExtension`, `DebugExtension`) rather
than this central theme. :::

### Properties

| Property                      | Type              | Required | Description                                   |
| ----------------------------- | ----------------- | -------- | --------------------------------------------- |
| `nodeTheme`                   | `NodeTheme`       | Yes      | Node appearance                               |
| `connectionTheme`             | `ConnectionTheme` | Yes      | Established connection appearance             |
| `temporaryConnectionTheme`    | `ConnectionTheme` | Yes      | Connection during creation                    |
| `connectionAnimationDuration` | `Duration`        | No       | Animation cycle duration (default: 2 seconds) |
| `portTheme`                   | `PortTheme`       | Yes      | Port appearance                               |
| `labelTheme`                  | `LabelTheme`      | Yes      | Connection label styling                      |
| `gridTheme`                   | `GridTheme`       | Yes      | Grid background                               |
| `selectionTheme`              | `SelectionTheme`  | Yes      | Selection rectangle styling                   |
| `cursorTheme`                 | `CursorTheme`     | Yes      | Mouse cursor styles                           |
| `resizerTheme`                | `ResizerTheme`    | Yes      | Resize handle styling                         |
| `backgroundColor`             | `Color`           | No       | Canvas background                             |

::: code-group

```dart [Preset Themes]
// Light theme
NodeFlowTheme.light

// Dark theme
NodeFlowTheme.dark
```

```dart [copyWith]
final customTheme = NodeFlowTheme.light.copyWith(
  backgroundColor: Colors.grey[50],
  nodeTheme: NodeTheme.light.copyWith(
    backgroundColor: Colors.blue[50],
  ),
);
```

:::

## NodeTheme

Style configuration for nodes.

```dart
NodeTheme({
  required Color backgroundColor,
  required Color selectedBackgroundColor,
  required Color borderColor,
  required Color selectedBorderColor,
  required double borderWidth,
  required double selectedBorderWidth,
  required BorderRadius borderRadius,
  required List<BoxShadow> shadow,
  required List<BoxShadow> selectedShadow,
})
```

| Property                  | Type              | Description                |
| ------------------------- | ----------------- | -------------------------- |
| `backgroundColor`         | `Color`           | Default background         |
| `selectedBackgroundColor` | `Color`           | Background when selected   |
| `borderColor`             | `Color`           | Default border color       |
| `selectedBorderColor`     | `Color`           | Border when selected       |
| `borderWidth`             | `double`          | Default border width       |
| `selectedBorderWidth`     | `double`          | Border width when selected |
| `borderRadius`            | `BorderRadius`    | Corner rounding            |
| `shadow`                  | `List<BoxShadow>` | Default shadow             |
| `selectedShadow`          | `List<BoxShadow>` | Shadow when selected       |

**Preset themes:**

```dart
NodeTheme.light
NodeTheme.dark
```

**Example:**

```dart
NodeTheme(
  backgroundColor: Colors.white,
  selectedBackgroundColor: Colors.blue[50]!,
  borderColor: Colors.grey[300]!,
  selectedBorderColor: Colors.blue,
  borderWidth: 1,
  selectedBorderWidth: 2,
  borderRadius: BorderRadius.circular(8),
  shadow: [
    BoxShadow(
      color: Colors.black12,
      blurRadius: 4,
      offset: Offset(0, 2),
    ),
  ],
  selectedShadow: [
    BoxShadow(
      color: Colors.blue.withOpacity(0.3),
      blurRadius: 8,
      offset: Offset(0, 2),
    ),
  ],
)
```

## ConnectionTheme

Style configuration for connections.

```dart
ConnectionTheme({
  required ConnectionStyle style,
  required Color color,
  required Color selectedColor,
  required Color highlightColor,
  required Color highlightBorderColor,
  required double strokeWidth,
  required double selectedStrokeWidth,
  List<double>? dashPattern,
  required ConnectionEndPoint startPoint,
  required ConnectionEndPoint endPoint,
  required Color endpointColor,
  required Color endpointBorderColor,
  required double endpointBorderWidth,
  ConnectionEffect? animationEffect,
  required double bezierCurvature,
  required double cornerRadius,
  required double portExtension,
  required double backEdgeGap,
  required double hitTolerance,
  double startGap = 0.0,
  double endGap = 0.0,
})
```

| Property               | Type                 | Description                            |
| ---------------------- | -------------------- | -------------------------------------- |
| `style`                | `ConnectionStyle`    | Line style (bezier, smoothstep, etc.)  |
| `color`                | `Color`              | Default line color                     |
| `selectedColor`        | `Color`              | Color when selected                    |
| `highlightColor`       | `Color`              | Color when hovered                     |
| `highlightBorderColor` | `Color`              | Border color for highlighted endpoints |
| `strokeWidth`          | `double`             | Default line width                     |
| `selectedStrokeWidth`  | `double`             | Width when selected                    |
| `dashPattern`          | `List<double>?`      | Dash pattern `[dash, gap]`             |
| `startPoint`           | `ConnectionEndPoint` | Start marker                           |
| `endPoint`             | `ConnectionEndPoint` | End marker                             |
| `endpointColor`        | `Color`              | Marker fill color                      |
| `endpointBorderColor`  | `Color`              | Marker border color                    |
| `endpointBorderWidth`  | `double`             | Marker border width                    |
| `animationEffect`      | `ConnectionEffect?`  | Default animation effect               |
| `bezierCurvature`      | `double`             | Bezier curve factor (0-1)              |
| `cornerRadius`         | `double`             | Step connection corner radius          |
| `portExtension`        | `double`             | Straight distance from port            |
| `backEdgeGap`          | `double`             | Gap for loopback routing               |
| `hitTolerance`         | `double`             | Click/tap hit area tolerance           |
| `startGap`             | `double`             | Gap from source port                   |
| `endGap`               | `double`             | Gap from target port                   |

**Preset themes:**

```dart
ConnectionTheme.light
ConnectionTheme.dark
```

## ConnectionEndPoint

Markers at connection endpoints.

```dart
ConnectionEndPoint({
  required MarkerShape shape,
  Size? size,
  Color? color,
  Color? borderColor,
  double? borderWidth,
})

// Built-in constants
ConnectionEndPoint.none       // No marker
ConnectionEndPoint.capsuleHalf // Capsule half shape (default for end)
ConnectionEndPoint.triangle   // Arrow/triangle
```

::: info Endpoint shapes use `MarkerShape`, not a separate `EndpointShape` enum.

:::

## ConnectionStyle

Path rendering styles via `ConnectionStyles`:

| Style                         | Description                 |
| ----------------------------- | --------------------------- |
| `ConnectionStyles.straight`   | Direct line                 |
| `ConnectionStyles.bezier`     | Curved Bezier               |
| `ConnectionStyles.step`       | Right-angle segments        |
| `ConnectionStyles.smoothstep` | Smooth orthogonal (default) |

## PortTheme

Style configuration for ports.

```dart
PortTheme({
  required Size size,
  required Color color,
  required Color connectedColor,
  required Color highlightColor,
  required Color highlightBorderColor,
  required Color borderColor,
  required double borderWidth,
  MarkerShape shape = MarkerShapes.capsuleHalf,
  bool showLabel = false,
  TextStyle? labelTextStyle,
  double labelOffset = 4.0,
})
```

| Property               | Type          | Description                                        |
| ---------------------- | ------------- | -------------------------------------------------- |
| `size`                 | `Size`        | Port dimensions (width, height)                    |
| `color`                | `Color`       | Default fill color                                 |
| `connectedColor`       | `Color`       | Color when connected                               |
| `highlightColor`       | `Color`       | Fill color when highlighted during connection drag |
| `highlightBorderColor` | `Color`       | Border color when highlighted                      |
| `borderColor`          | `Color`       | Default border color                               |
| `borderWidth`          | `double`      | Border thickness                                   |
| `shape`                | `MarkerShape` | Default marker shape                               |
| `showLabel`            | `bool`        | Global label visibility                            |
| `labelTextStyle`       | `TextStyle?`  | Label text style                                   |
| `labelOffset`          | `double`      | Port to label distance                             |

**Preset themes:**

```dart
PortTheme.light
PortTheme.dark
```

::: info Port `size` is a `Size` object (width x height), not a single `double`
value.

:::

## GridTheme

Style configuration for the background grid.

```dart
GridTheme({
  required GridStyle style,
  required Color color,
  required double size,
  required double thickness,
})
```

| Property    | Type        | Description         |
| ----------- | ----------- | ------------------- |
| `style`     | `GridStyle` | Grid pattern style  |
| `color`     | `Color`     | Grid line/dot color |
| `size`      | `double`    | Grid cell size      |
| `thickness` | `double`    | Line thickness      |

### GridStyle

| Style                     | Description                              |
| ------------------------- | ---------------------------------------- |
| `GridStyles.none`         | No grid                                  |
| `GridStyles.dots`         | Dot pattern                              |
| `GridStyles.lines`        | Line grid                                |
| `GridStyles.cross`        | Cross pattern                            |
| `GridStyles.hierarchical` | Hierarchical grid with major/minor lines |

**Preset themes:**

```dart
GridTheme.light
GridTheme.dark
```

**Example:**

```dart
GridTheme(
  style: GridStyles.dots,
  color: Colors.grey[300]!,
  size: 20,
  thickness: 1,
)
```

## LabelTheme

Style configuration for connection labels.

```dart
LabelTheme({
  required TextStyle textStyle,
  required Color backgroundColor,
  required EdgeInsets padding,
  required BorderRadius borderRadius,
  Border? border,
})
```

**Preset themes:**

```dart
LabelTheme.light
LabelTheme.dark
```

**Example:**

```dart
LabelTheme(
  textStyle: TextStyle(fontSize: 12, color: Colors.black87),
  backgroundColor: Colors.white,
  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
  borderRadius: BorderRadius.circular(4),
  border: Border.all(color: Colors.grey[300]!),
)
```

## SelectionTheme

Style configuration for selection rectangle.

```dart
SelectionTheme({
  required Color fillColor,
  required Color borderColor,
  required double borderWidth,
})
```

**Preset themes:**

```dart
SelectionTheme.light
SelectionTheme.dark
```

## CursorTheme

Mouse cursor styles for different interactions.

```dart
CursorTheme({
  required MouseCursor defaultCursor,
  required MouseCursor grabbingCursor,
  required MouseCursor moveCursor,
  required MouseCursor resizeCursor,
  // Additional cursor configurations
})
```

**Preset themes:**

```dart
CursorTheme.light
CursorTheme.dark
```

## DebugTheme

Theme for debug visualization overlays.

```dart
DebugTheme({
  required Color gridColor,
  required Color cellColor,
  required Color textColor,
  // Additional debug styling properties
})
```

**Preset themes:**

```dart
DebugTheme.light
DebugTheme.dark
```

## Complete Example

::: code-group

```dart [Light Theme]
NodeFlowEditor(
  controller: controller,
  theme: NodeFlowTheme.light,
  nodeBuilder: (context, node) => Text(node.data.label),
)
```

```dart [Dark Theme]
NodeFlowEditor(
  controller: controller,
  theme: NodeFlowTheme.dark,
  nodeBuilder: (context, node) => Text(node.data.label),
)
```

```dart [Custom Theme]
NodeFlowEditor(
  controller: controller,
  theme: NodeFlowTheme.light.copyWith(
    backgroundColor: Color(0xFFF5F5F5),
    nodeTheme: NodeTheme.light.copyWith(
      backgroundColor: Colors.white,
      selectedBorderColor: Colors.indigo,
      borderRadius: BorderRadius.circular(12),
    ),
    connectionTheme: ConnectionTheme.light.copyWith(
      color: Colors.grey[600],
      selectedColor: Colors.indigo,
      strokeWidth: 2.0,
      endPoint: ConnectionEndPoint.triangle,
    ),
    portTheme: PortTheme.light.copyWith(
      size: Size(12, 12),
      color: Colors.grey[400],
      connectedColor: Colors.indigo,
    ),
    gridTheme: GridTheme.light.copyWith(
      style: GridStyles.hierarchical,
      color: Colors.grey[200],
      size: 20,
    ),
  ),
  nodeBuilder: (context, node) => Text(node.data.label),
)
```

:::

## Theme Integration

Access theme from Flutter's theme system:

```dart
// In your Theme widget
Theme(
  data: ThemeData.light().copyWith(
    extensions: [NodeFlowTheme.light],
  ),
  child: MyApp(),
)

// Access in widgets
final flowTheme = Theme.of(context).extension<NodeFlowTheme>()!;
```

## See Also

- [Theming Overview](/docs/theming/overview)
- [Connection Styles](/docs/theming/connection-styles)
- [Connection Effects](/docs/theming/connection-effects)
- [Port Shapes](/docs/theming/port-shapes)
- [Grid Styles](/docs/theming/grid-styles)
