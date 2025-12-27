---
title: Configuration
description: Configure editor behavior with NodeFlowConfig and AutoPanConfig
---

# Configuration

Node Flow provides two configuration classes that control editor behavior: `NodeFlowConfig` for general settings and `AutoPanConfig` for automatic viewport panning during drag operations.

## NodeFlowConfig

`NodeFlowConfig` is a reactive configuration class that controls behavioral properties of the editor. All properties are MobX observables, allowing real-time updates.

### Constructor

```dart
NodeFlowConfig({
  bool snapToGrid = false,
  bool snapAnnotationsToGrid = false,
  double gridSize = 20.0,
  double portSnapDistance = 8.0,
  double minZoom = 0.5,
  double maxZoom = 2.0,
  bool showMinimap = false,
  bool isMinimapInteractive = true,
  bool showAttribution = true,
  AutoPanConfig? autoPan = AutoPanConfig.normal,
  bool debugMode = false,
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
| `showMinimap` | `Observable<bool>` | `false` | Whether to show the minimap overlay |
| `isMinimapInteractive` | `Observable<bool>` | `true` | Whether the minimap responds to clicks |
| `showAttribution` | `bool` | `true` | Whether to show the attribution label |
| `autoPan` | `Observable<AutoPanConfig?>` | `.normal` | Autopan configuration (null to disable) |
| `debugMode` | `Observable<bool>` | `false` | Enable debug visualization overlays |

::: details 🖼️ Snap-to-Grid Behavior
Split-screen animation: left side shows free-form node dragging (smooth movement), right side shows snap-to-grid enabled (nodes jump to grid intersections). Visual grid overlay shows the 20px grid cells.
:::

### Basic Usage

```dart
// Create controller with configuration
final controller = NodeFlowController<MyData>(
  config: NodeFlowConfig(
    snapToGrid: true,
    gridSize: 20.0,
    showMinimap: true,
    autoPan: AutoPanConfig.normal,
  ),
);

// Access config from controller
final gridSize = controller.config.gridSize.value;
```

### Reactive Updates

Since all properties are observables, you can update them at runtime:

```dart
// Toggle snap-to-grid
controller.config.toggleSnapping();

// Update specific property
controller.config.snapToGrid.value = true;

// Batch update multiple properties
controller.config.update(
  snapToGrid: true,
  gridSize: 25.0,
  showMinimap: true,
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

// Toggle minimap visibility
controller.config.toggleMinimap();

// Toggle debug mode
controller.config.toggleDebugMode();
```

```dart [Autopan Control]
// Disable autopan
controller.config.disableAutoPan();

// Set specific autopan configuration
controller.config.setAutoPan(AutoPanConfig.fast);

// Or directly set the observable
controller.config.autoPan.value = AutoPanConfig.precise;
```

:::

## AutoPanConfig

`AutoPanConfig` controls automatic viewport panning when dragging elements (nodes, annotations, connections) near the edges of the viewport.

### How Autopan Works

When you drag an element near the edge of the viewport, the canvas automatically pans to reveal more space. This allows seamless dragging across large canvases without manually panning.

### Constructor

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
// Option 1: Set to null in config
NodeFlowConfig(
  autoPan: null,
)

// Option 2: Disable at runtime
controller.config.disableAutoPan();

// Option 3: Set null directly
controller.config.autoPan.value = null;
```

```dart [Checking Autopan State]
final config = controller.config.autoPan.value;

if (config != null && config.isEnabled) {
  // Autopan is active
}
```

:::

## Debug Mode

Enable debug mode to visualize internal editor state:

```dart
NodeFlowConfig(
  debugMode: true,
)
```

Debug mode shows:
- **Spatial index grid**: Visualization of the spatial partitioning used for hit testing
- **Autopan edge zones**: Highlighted areas where autopan activates
- **Hit areas and bounds**: Visual feedback for interaction areas

Toggle at runtime:

```dart
controller.config.toggleDebugMode();
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
  late final NodeFlowController<MyData> controller;

  @override
  void initState() {
    super.initState();
    controller = NodeFlowController<MyData>(
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

        // Minimap
        showMinimap: true,
        isMinimapInteractive: true,

        // Autopan with custom settings
        autoPan: AutoPanConfig(
          edgePadding: EdgeInsets.symmetric(
            horizontal: 50.0,
            vertical: 40.0,
          ),
          panAmount: 12.0,
          useProximityScaling: true,
          speedCurve: Curves.easeIn,
        ),

        // Debug visualization (disable in production)
        debugMode: false,
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
                isSelected: controller.config.showMinimap.value,
                onPressed: controller.config.toggleMinimap,
                child: Text('Minimap'),
              ),
              ToggleButton(
                isSelected: controller.config.debugMode.value,
                onPressed: controller.config.toggleDebugMode,
                child: Text('Debug'),
              ),
            ],
          ),
        ),

        // Editor
        Expanded(
          child: NodeFlowEditor<MyData>(
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
