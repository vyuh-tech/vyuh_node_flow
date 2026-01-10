---
title: Extensions
description: Add features and behavior to Node Flow using the extension system
---

# Extensions

Node Flow uses an extension system to add features without bloating the core. Extensions are self-contained modules that observe events, manage their own state, and add capabilities like minimap, autopan, and debug visualization.

## How Extensions Work

Extensions follow a simple lifecycle:

<img src="/images/diagrams/extension-lifecycle.svg" alt="Extension Lifecycle" style="max-width: 500px; display: block; margin: 1rem 0;" />

## Built-in Extensions

Node Flow includes these built-in extensions:

| Extension | Purpose | Default State | Access |
|-----------|---------|---------------|--------|
| [AutoPanExtension](/docs/extensions/autopan) | Pan viewport when dragging near edges | Enabled | `controller.autoPan` |
| [MinimapExtension](/docs/extensions/minimap) | Navigate overview panel | Visible | `controller.minimap` |
| [LodExtension](/docs/extensions/lod) | Detail visibility based on zoom | Disabled | `controller.lod` |
| [DebugExtension](/docs/extensions/debug) | Debug overlays | Disabled | `controller.debug` |
| [StatsExtension](/docs/extensions/stats) | Graph statistics | Enabled | `controller.stats` |

### Default Extensions

When no extensions are specified, Node Flow includes a default set:

```dart
// These are added automatically if extensions: is null
final defaultExtensions = [
  AutoPanExtension(),      // Enabled by default
  DebugExtension(),        // Disabled by default (mode: none)
  LodExtension(),          // Disabled by default
  MinimapExtension(),      // Visible by default
  StatsExtension(),        // Always available
];
```

### Custom Extension List

Override the defaults by providing your own list:

```dart
NodeFlowConfig(
  extensions: [
    // Only include what you need
    MinimapExtension(visible: true),
    AutoPanExtension(),
    // No debug, no LOD, no stats
  ],
)
```

## Accessing Extensions

Extensions are accessed via typed getters on the controller:

```dart
// Each built-in extension has a typed getter
controller.minimap?.toggle();
controller.autoPan?.useFast();
controller.lod?.enable();
controller.debug?.setMode(DebugMode.all);
controller.stats?.nodeCount;

// All getters return nullable types (null if not registered)
if (controller.minimap != null) {
  // Extension is available
}
```

### Resolving Custom Extensions

For custom extensions, use `resolveExtension<T>()`:

```dart
// Get a custom extension by type
final myExtension = controller.resolveExtension<MyCustomExtension>();

// Or create a typed extension getter
extension MyExtensionAccess<T> on NodeFlowController<T, dynamic> {
  MyCustomExtension? get myExtension =>
      resolveExtension<MyCustomExtension>();
}

// Then use it like built-in extensions
controller.myExtension?.doSomething();
```

## Creating Custom Extensions

Extensions implement the `NodeFlowExtension` interface:

```dart
import 'package:vyuh_node_flow/vyuh_node_flow.dart';

class LoggingExtension extends NodeFlowExtension {
  NodeFlowController? _controller;

  @override
  String get id => 'logging';

  @override
  void attach(NodeFlowController controller) {
    _controller = controller;
    print('Logging extension attached');
    print('Graph has ${controller.nodes.length} nodes');
  }

  @override
  void detach() {
    print('Logging extension detached');
    _controller = null;
  }

  @override
  void onEvent(GraphEvent event) {
    switch (event) {
      case NodeAdded(:final node):
        print('Node added: ${node.id}');
      case NodeMoved(:final node, :final previousPosition):
        print('Node ${node.id} moved from $previousPosition');
      case ConnectionAdded(:final connection):
        print('Connection: ${connection.sourceNodeId} → ${connection.targetNodeId}');
      default:
        // Ignore other events
    }
  }
}
```

### Extension Properties

| Property/Method | Description |
|-----------------|-------------|
| `id` | Unique identifier (prevents duplicates) |
| `attach(controller)` | Called when registered; store the controller reference |
| `detach()` | Called when unregistered; clean up resources |
| `onEvent(event)` | Called for each graph event |

### Event Types

Extensions receive all graph events. The event system uses a sealed class hierarchy for exhaustive pattern matching:

```dart
@override
void onEvent(GraphEvent event) {
  switch (event) {
    // Node lifecycle events
    case NodeAdded(:final node): ...
    case NodeRemoved(:final node): ...
    case NodeMoved(:final node, :final previousPosition): ...
    case NodeResized(:final node, :final previousSize): ...
    case NodeDataChanged(:final node, :final previousData): ...
    case NodeVisibilityChanged(:final node, :final wasVisible): ...
    case NodeZIndexChanged(:final node, :final previousZIndex): ...
    case NodeLockChanged(:final node, :final wasLocked): ...
    case NodeGroupChanged(:final node, :final previousGroupId, :final currentGroupId): ...

    // Connection events
    case ConnectionAdded(:final connection): ...
    case ConnectionRemoved(:final connection): ...

    // Selection events
    case SelectionChanged(:final selectedNodeIds, :final selectedConnectionIds): ...

    // Viewport events
    case ViewportChanged(:final viewport, :final previousViewport): ...

    // Drag events (for tracking drag operations)
    case NodeDragStarted(:final nodeIds, :final startPosition): ...
    case NodeDragEnded(:final nodeIds, :final originalPositions): ...
    case ConnectionDragStarted(:final sourceNodeId, :final sourcePortId): ...
    case ConnectionDragEnded(:final wasConnected, :final connection): ...
    case ResizeStarted(:final nodeId, :final initialSize): ...
    case ResizeEnded(:final nodeId, :final initialSize, :final finalSize): ...

    // Hover events
    case NodeHoverChanged(:final nodeId, :final isHovered): ...
    case ConnectionHoverChanged(:final connectionId, :final isHovered): ...
    case PortHoverChanged(:final nodeId, :final portId, :final isHovered): ...

    // Lifecycle events
    case GraphCleared(:final previousNodeCount, :final previousConnectionCount): ...
    case GraphLoaded(:final nodeCount, :final connectionCount): ...

    // Batch events (for undo/redo grouping)
    case BatchStarted(:final reason): ...
    case BatchEnded(): ...

    // LOD (Level of Detail) events
    case LODLevelChanged(:final previousVisibility, :final currentVisibility): ...
  }
}
```

### Event Reference

| Category | Event | Key Properties | Purpose |
|----------|-------|----------------|---------|
| **Node** | `NodeAdded` | `node` | Node created |
| | `NodeRemoved` | `node` | Node deleted |
| | `NodeMoved` | `node`, `previousPosition` | Position changed |
| | `NodeResized` | `node`, `previousSize` | Size changed |
| | `NodeDataChanged` | `node`, `previousData` | Data payload changed |
| | `NodeVisibilityChanged` | `node`, `wasVisible` | Visibility toggled |
| | `NodeZIndexChanged` | `node`, `previousZIndex` | Layer order changed |
| | `NodeLockChanged` | `node`, `wasLocked` | Lock state toggled |
| | `NodeGroupChanged` | `node`, `previousGroupId`, `currentGroupId` | Group membership changed |
| **Connection** | `ConnectionAdded` | `connection` | Connection created |
| | `ConnectionRemoved` | `connection` | Connection deleted |
| **Selection** | `SelectionChanged` | `selectedNodeIds`, `selectedConnectionIds`, `previousNodeIds`, `previousConnectionIds` | Selection state changed |
| **Viewport** | `ViewportChanged` | `viewport`, `previousViewport` | Pan/zoom changed |
| **Drag** | `NodeDragStarted` | `nodeIds`, `startPosition` | Drag operation began |
| | `NodeDragEnded` | `nodeIds`, `originalPositions` | Drag operation ended |
| | `ConnectionDragStarted` | `sourceNodeId`, `sourcePortId`, `isOutput` | Connection drag began |
| | `ConnectionDragEnded` | `wasConnected`, `connection` | Connection drag ended |
| | `ResizeStarted` | `nodeId`, `initialSize` | Resize operation began |
| | `ResizeEnded` | `nodeId`, `initialSize`, `finalSize` | Resize operation ended |
| **Hover** | `NodeHoverChanged` | `nodeId`, `isHovered` | Node hover state changed |
| | `ConnectionHoverChanged` | `connectionId`, `isHovered` | Connection hover state changed |
| | `PortHoverChanged` | `nodeId`, `portId`, `isHovered`, `isOutput` | Port hover state changed |
| **Lifecycle** | `GraphCleared` | `previousNodeCount`, `previousConnectionCount` | Graph was cleared |
| | `GraphLoaded` | `nodeCount`, `connectionCount` | Graph was loaded |
| **Batch** | `BatchStarted` | `reason` | Batch operation began |
| | `BatchEnded` | — | Batch operation ended |
| **LOD** | `LODLevelChanged` | `previousVisibility`, `currentVisibility`, `normalizedZoom` | Detail level changed |

### Stateful Extensions

Most extensions maintain observable state using MobX:

```dart
class SelectionTrackerExtension extends NodeFlowExtension {
  NodeFlowController? _controller;

  // Observable state
  final Observable<int> _selectionCount = Observable(0);
  final Observable<DateTime?> _lastSelectionTime = Observable(null);

  // Public accessors
  int get selectionCount => _selectionCount.value;
  DateTime? get lastSelectionTime => _lastSelectionTime.value;

  @override
  String get id => 'selection-tracker';

  @override
  void attach(NodeFlowController controller) {
    _controller = controller;
  }

  @override
  void detach() {
    _controller = null;
  }

  @override
  void onEvent(GraphEvent event) {
    switch (event) {
      case SelectionChanged(:final selectedNodeIds, :final previousNodeIds):
        runInAction(() {
          _selectionCount.value = selectedNodeIds.length;
          if (selectedNodeIds.length > previousNodeIds.length) {
            _lastSelectionTime.value = DateTime.now();
          }
        });
      default:
        break;
    }
  }
}
```

### Using Stateful Extensions in UI

```dart
Observer(
  builder: (_) {
    final tracker = controller.resolveExtension<SelectionTrackerExtension>();
    if (tracker == null) return const SizedBox.shrink();

    return Text('${tracker.selectionCount} items selected');
  },
)
```

## Extension Patterns

### Undo/Redo Extension

Extensions are ideal for implementing undo/redo:

```dart
class UndoRedoExtension extends NodeFlowExtension {
  final List<GraphEvent> _undoStack = [];
  final List<GraphEvent> _redoStack = [];
  NodeFlowController? _controller;

  bool get canUndo => _undoStack.isNotEmpty;
  bool get canRedo => _redoStack.isNotEmpty;

  @override
  String get id => 'undo-redo';

  @override
  void attach(NodeFlowController controller) {
    _controller = controller;
  }

  @override
  void detach() {
    _controller = null;
  }

  @override
  void onEvent(GraphEvent event) {
    // Only track undoable events
    switch (event) {
      case NodeMoved():
      case NodeResized():
      case ConnectionAdded():
      case ConnectionRemoved():
        _undoStack.add(event);
        _redoStack.clear(); // Clear redo on new action
      default:
        break;
    }
  }

  void undo() {
    if (!canUndo) return;
    final event = _undoStack.removeLast();
    _redoStack.add(event);
    _applyInverse(event);
  }

  void redo() {
    if (!canRedo) return;
    final event = _redoStack.removeLast();
    _undoStack.add(event);
    _applyEvent(event);
  }

  void _applyInverse(GraphEvent event) {
    // Implement inverse operations
  }

  void _applyEvent(GraphEvent event) {
    // Implement forward operations
  }
}
```

### Auto-Save Extension

```dart
class AutoSaveExtension extends NodeFlowExtension {
  final Duration debounceTime;
  final void Function(Map<String, dynamic>) onSave;

  Timer? _debounceTimer;
  NodeFlowController? _controller;

  AutoSaveExtension({
    this.debounceTime = const Duration(seconds: 2),
    required this.onSave,
  });

  @override
  String get id => 'auto-save';

  @override
  void attach(NodeFlowController controller) {
    _controller = controller;
  }

  @override
  void detach() {
    _debounceTimer?.cancel();
    _controller = null;
  }

  @override
  void onEvent(GraphEvent event) {
    // Debounce save on any data change
    switch (event) {
      case NodeAdded():
      case NodeRemoved():
      case NodeMoved():
      case ConnectionAdded():
      case ConnectionRemoved():
        _scheduleSave();
      default:
        break;
    }
  }

  void _scheduleSave() {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(debounceTime, () {
      if (_controller != null) {
        onSave(_controller!.toJson());
      }
    });
  }
}
```

## Best Practices

1. **Keep extensions focused**: Each extension should do one thing well
2. **Use MobX for state**: Makes extension state reactive with UI
3. **Handle detach properly**: Clean up timers, listeners, subscriptions
4. **Provide typed accessors**: Add extension methods for ergonomic access
5. **Use pattern matching**: Handle only the events you care about
6. **Consider batching**: Use `BatchStarted`/`BatchEnded` for grouping related changes

## See Also

- [AutoPan](/docs/extensions/autopan) - Automatic viewport panning
- [Minimap](/docs/extensions/minimap) - Navigation overview
- [Level of Detail](/docs/extensions/lod) - Zoom-based visibility
- [Debug](/docs/extensions/debug) - Debug overlays
- [Stats](/docs/extensions/stats) - Graph statistics
- [Events](/docs/advanced/events) - Event system details
