---
title: Configuration
description: Configure editor behavior with NodeFlowConfig and extensions
---

# Configuration

Node Flow uses a configuration system with two components: `NodeFlowConfig` for core behavioral settings and an extension system for features like minimap, autopan, and debug visualization.

## NodeFlowConfig

`NodeFlowConfig` is a reactive configuration class that controls core behavioral properties of the editor. Most properties are MobX observables, allowing real-time updates.

### Constructor

```dart
NodeFlowConfig({
  bool snapToGrid = false,
  bool snapAnnotationsToGrid = false,
  double gridSize = 20.0,
  double portSnapDistance = 8.0,
  double minZoom = 0.5,
  double maxZoom = 2.0,
  bool showAttribution = true,
  List<NodeFlowExtension>? extensions,
})
```

### Properties

| Property | Type | Default | Description |
|----------|------|---------|-------------|
| `snapToGrid` | `Observable<bool>` | `false` | Snap node positions to grid when dragging |
| `snapAnnotationsToGrid` | `Observable<bool>` | `false` | Snap annotation positions to grid |
| `gridSize` | `Observable<double>` | `20.0` | Grid cell size in pixels for snapping |
| `portSnapDistance` | `Observable<double>` | `8.0` | Distance threshold for port snapping during connection |
| `minZoom` | `Observable<double>` | `0.5` | Minimum zoom level (0.5 = 50%) |
| `maxZoom` | `Observable<double>` | `2.0` | Maximum zoom level (2.0 = 200%) |
| `showAttribution` | `bool` | `true` | Whether to show the attribution label |
| `extensions` | `List<NodeFlowExtension>?` | default extensions | Extensions for minimap, autopan, debug, etc. |

::: details 🖼️ Snap-to-Grid Behavior
Split-screen animation: left side shows free-form node dragging (smooth movement), right side shows snap-to-grid enabled (nodes jump to grid intersections). Visual grid overlay shows the 20px grid cells.
:::

### Default Extensions

If no extensions are provided, the following defaults are used:

- `AutoPanExtension` - autopan near viewport edges (normal mode)
- `DebugExtension` - debug overlays (disabled by default)
- `LodExtension` - level of detail (disabled by default)
- `MinimapExtension` - minimap overlay
- `StatsExtension` - performance statistics display (disabled by default)

### Basic Usage

```dart
// Create controller with configuration
final controller = NodeFlowController<MyData, dynamic>(
  config: NodeFlowConfig(
    snapToGrid: true,
    gridSize: 20.0,
    extensions: [
      MinimapExtension(visible: true),
      AutoPanExtension(),
    ],
  ),
);

// Access config from controller
final gridSize = controller.config.gridSize.value;
```

### Reactive Updates

Since observable properties can be updated at runtime:

```dart
// Toggle snap-to-grid
controller.config.toggleSnapping();

// Update specific property
controller.config.snapToGrid.value = true;

// Batch update multiple properties
controller.config.update(
  snapToGrid: true,
  gridSize: 25.0,
);
```

::: code-group

```dart [Toggle Methods]
// Toggle both node and annotation snapping
controller.config.toggleSnapping();

// Toggle only node snapping
controller.config.toggleNodeSnapping();

// Toggle only annotation snapping
controller.config.toggleAnnotationSnapping();
```

```dart [Extension Access]
// Access extensions via controller
controller.minimap.toggle();
controller.minimap.setPosition(MinimapPosition.topRight);

controller.autoPan.disable();
controller.autoPan.setConfig(AutoPanConfig.fast);

controller.debug.toggle();
controller.debug.setMode(DebugMode.spatialIndex);
```

:::

## AutoPanExtension

The `AutoPanExtension` manages automatic viewport panning when dragging elements near the edges of the viewport. Configure it via `AutoPanConfig`.

### How Autopan Works

When you drag an element near the edge of the viewport, the canvas automatically pans to reveal more space. This allows seamless dragging across large canvases without manually panning.

### AutoPanConfig Constructor

```dart
const AutoPanConfig({
  EdgeInsets edgePadding = const EdgeInsets.all(50.0),
  double panAmount = 10.0,
  Duration panInterval = const Duration(milliseconds: 16),
  bool useProximityScaling = false,
  Curve? speedCurve,
})
```

### Properties

| Property | Type | Default | Description |
|----------|------|---------|-------------|
| `edgePadding` | `EdgeInsets` | `EdgeInsets.all(50.0)` | Distance from viewport edges where autopan activates |
| `panAmount` | `double` | `10.0` | Base pan amount per tick in graph units |
| `panInterval` | `Duration` | `16ms` | Time between pan ticks (~60fps) |
| `useProximityScaling` | `bool` | `false` | Scale speed based on proximity to edge |
| `speedCurve` | `Curve?` | `null` | Easing curve for proximity scaling |

### Preset Configurations

AutoPanConfig provides three preset configurations for common use cases:

::: code-group

```dart [Normal]
// Balanced settings for most use cases (default)
AutoPanConfig.normal
// Equivalent to:
AutoPanConfig(
  edgePadding: EdgeInsets.all(50.0),
  panAmount: 10.0,
  panInterval: Duration(milliseconds: 16),
)
```

```dart [Fast]
// Faster panning for large canvases
AutoPanConfig.fast
// Equivalent to:
AutoPanConfig(
  edgePadding: EdgeInsets.all(60.0),
  panAmount: 20.0,
  panInterval: Duration(milliseconds: 12),
)
```

```dart [Precise]
// Slower, more controlled panning
AutoPanConfig.precise
// Equivalent to:
AutoPanConfig(
  edgePadding: EdgeInsets.all(30.0),
  panAmount: 5.0,
  panInterval: Duration(milliseconds: 20),
)
```

:::

You can specify different padding for each edge:

```dart
AutoPanConfig(
  edgePadding: EdgeInsets.only(
    left: 50.0,
    right: 50.0,
    top: 30.0,
    bottom: 80.0,  // Larger to avoid bottom toolbar
  ),
  panAmount: 10.0,
)
```

### Proximity Scaling

Enable proximity scaling for gradual speed increase as the pointer approaches the edge:

```dart
AutoPanConfig(
  edgePadding: EdgeInsets.all(50.0),
  panAmount: 15.0,
  useProximityScaling: true,
  speedCurve: Curves.easeIn,  // Slow start, fast finish
)
```

Available curves:
- `Curves.linear` - Constant speed increase (default when null)
- `Curves.easeIn` - Slow start, fast finish (recommended for precision)
- `Curves.easeInQuad` - More gradual acceleration

::: code-group

```dart [Disabling Autopan]
// Option 1: Pass null config to extension
NodeFlowConfig(
  extensions: [
    AutoPanExtension(config: null),  // Disabled
  ],
)

// Option 2: Disable at runtime via extension
controller.autoPan.disable();
```

```dart [Checking Autopan State]
// Access via controller extension
if (controller.autoPan.isEnabled) {
  // Autopan is active
}

final config = controller.autoPan.currentConfig;
```

:::

## DebugExtension

The `DebugExtension` provides debug visualization overlays for understanding internal editor state.

Enable debug mode via extension configuration:

```dart
NodeFlowConfig(
  extensions: [
    DebugExtension(mode: DebugMode.all),
  ],
)
```

### Debug Modes

| Mode | Description |
|------|-------------|
| `DebugMode.none` | No debug visualizations (default) |
| `DebugMode.all` | Show all debug visualizations |
| `DebugMode.spatialIndex` | Show only spatial index grid |
| `DebugMode.autoPanZone` | Show only autopan edge zones |

Debug mode shows:
- **Spatial index grid**: Visualization of the spatial partitioning used for hit testing
- **Autopan edge zones**: Highlighted areas where autopan activates

Toggle at runtime via extension:

```dart
// Toggle between none and all
controller.debug.toggle();

// Set specific mode
controller.debug.setMode(DebugMode.spatialIndex);

// Cycle through all modes
controller.debug.cycle();
```

::: info
Debug mode is useful during development to understand hit testing and autopan behavior. Disable it in production for better performance.

:::

## Complete Example

```dart
class ConfigurableEditor extends StatefulWidget {
  @override
  State<ConfigurableEditor> createState() => _ConfigurableEditorState();
}

class _ConfigurableEditorState extends State<ConfigurableEditor> {
  late final NodeFlowController<MyData, dynamic> controller;

  @override
  void initState() {
    super.initState();
    controller = NodeFlowController<MyData, dynamic>(
      config: NodeFlowConfig(
        // Grid snapping
        snapToGrid: true,
        snapAnnotationsToGrid: true,
        gridSize: 20.0,

        // Zoom limits
        minZoom: 0.25,
        maxZoom: 4.0,

        // Port connection snapping
        portSnapDistance: 12.0,

        // Extensions for additional features
        extensions: [
          // Minimap with custom settings
          MinimapExtension(
            visible: true,
            interactive: true,
            position: MinimapPosition.bottomRight,
          ),

          // Autopan enabled
          AutoPanExtension(),

          // Debug visualization (disabled by default)
          DebugExtension(mode: DebugMode.none),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Toolbar with config toggles
        Observer(
          builder: (_) => Row(
            children: [
              ToggleButton(
                isSelected: controller.config.snapToGrid.value,
                onPressed: controller.config.toggleNodeSnapping,
                child: Text('Snap to Grid'),
              ),
              ToggleButton(
                isSelected: controller.minimap.isVisible,
                onPressed: controller.minimap.toggle,
                child: Text('Minimap'),
              ),
              ToggleButton(
                isSelected: controller.debug.isEnabled,
                onPressed: controller.debug.toggle,
                child: Text('Debug'),
              ),
            ],
          ),
        ),

        // Editor
        Expanded(
          child: NodeFlowEditor<MyData, dynamic>(
            controller: controller,
            theme: NodeFlowTheme.light,
            nodeBuilder: (context, node) => MyNodeWidget(node: node),
          ),
        ),
      ],
    );
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }
}
```

## See Also

- [NodeFlowEditor](/docs/components/node-flow-editor) - Main editor widget
- [Minimap](/docs/components/minimap) - Minimap component
- [Theming](/docs/theming/overview) - Visual customization
