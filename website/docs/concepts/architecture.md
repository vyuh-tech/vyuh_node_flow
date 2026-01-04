---
title: Architecture
description: Understanding the architecture and design of Vyuh Node Flow
---

Vyuh Node Flow is built with a layered architecture that separates concerns and
provides a flexible, extensible foundation for building node-based editors.

## High-Level Overview

The **`NodeFlowEditor`** is the core widget that is used to manipulate the
entire node graph. Its companion object is the **`NodeFlowController`**,
providing the API and infrastructure for manipulating the node graph.

## Core Components

### 1. NodeFlowEditor

The main widget that renders the interactive flow editor.

- Manages the visual rendering of the graph
- Handles user interactions (panning, zooming, selecting)
- Delegates to specialized layers for rendering different aspects
- Provides callbacks for user actions

### 2. NodeFlowController

The controller manages the graph state and provides APIs for manipulation:

```dart
class NodeFlowController<T, C> {
  // Core graph data
  final Map<String, Node<T>> nodes;
  final List<Connection> connections;
  final GraphViewport viewport;

  // APIs
  void addNode(Node<T> node);
  void removeNode(String nodeId);
  void addConnection(Connection connection);
  void removeConnection(String connectionId);

  // Selection
  Set<String> get selectedNodeIds;
  void selectNode(String nodeId, {bool toggle = false});

  // Viewport management
  void setViewport(GraphViewport viewport);
  void fitToView();
  void centerOn(GraphOffset position);

  // And many more...
}
```

Key responsibilities:

- **State Management**: Uses MobX observables for reactive updates
- **Graph Operations**: CRUD operations on nodes and connections
- **Selection Management**: Multi-select support
- **Keyboard Shortcuts**: Extensible keyboard shortcuts
- **Viewport Control**: Panning and zooming

### 3. NodeGraph

An immutable data class for graph serialization and deserialization. All state
management is handled by the NodeFlowController:

```dart
class NodeGraph<T, dynamic> {
  /// All nodes including GroupNode and CommentNode
  final List<Node<T>> nodes;
  final List<Connection> connections;
  final GraphViewport viewport;
  final Map<String, dynamic> metadata;
}
```

### 4. Node

Represents a single node in the graph with reactive state management:

```dart
class Node<T> {
  final String id;
  final String type;
  final T data;
  final NodeRenderLayer layer; // background, middle, foreground
  final bool locked; // Prevents dragging via UI
  final bool selectable; // Participates in marquee selection

  // Observable properties
  final Observable<Offset> position;
  final Observable<Offset> visualPosition;
  final Observable<Size> size;
  final Observable<int> zIndex;
  final Observable<bool> selected;
  final Observable<bool> dragging;

  // Port lists
  final ObservableList<Port> inputPorts;
  final ObservableList<Port> outputPorts;

  // Computed properties
  bool get isVisible;
  bool get isEditing;
  bool get isResizable; // true for nodes with ResizableMixin
}
```

**Key Features:**

- Generic data type `T` for custom node information
- MobX observables for reactive position, size, z-index, and state
- Separate `position` (logical) and `visualPosition` (for snap-to-grid)
- Observable lists for dynamic port management
- Support for shaped nodes via `NodeShape`
- `locked` flag to prevent accidental dragging
- `layer` for rendering order (GroupNode=background, regular=middle,
  CommentNode=foreground)
- `selectable` controls participation in marquee selection

### 5. Port

Connection points on nodes with extensive customization:

```dart
class Port {
  final String id;
  final String name;
  final PortPosition position; // left, right, top, bottom
  final PortType type; // input or output (inferred from position if not specified)
  final Offset offset;
  final bool multiConnections;
  final int? maxConnections;
  final MarkerShape? shape; // null = use theme default
  final Size? size; // null = use theme default
  final String? tooltip;
  final bool isConnectable;
  final bool showLabel;

  // Observable state
  final Observable<bool> highlighted; // Set during connection drag
}
```

**Key Features:**

- Configurable as input or output port type (auto-inferred from position)
- Custom shapes via `MarkerShape` (default: capsule half from theme)
- Multi-connection support with optional max limit
- Tooltips and connectable state
- Position offset specifies where the CENTER of the port should be
- Observable highlight state for connection drag feedback

### 6. Connection

Links between ports with reactive styling and labels:

```dart
class Connection {
  final String id;
  final String sourceNodeId;
  final String sourcePortId;
  final String targetNodeId;
  final String targetPortId;
  final Map<String, dynamic>? data;
  final bool locked; // Prevents deletion via UI

  // Optional customization
  final ConnectionStyle? style;
  final ConnectionEndPoint? startPoint;
  final ConnectionEndPoint? endPoint;
  final double? startGap;
  final double? endGap;

  // Observable properties
  Observable<bool> animated;
  Observable<bool> selected;
  Observable<ConnectionLabel?> startLabel;  // anchor 0.0
  Observable<ConnectionLabel?> label;       // anchor 0.5
  Observable<ConnectionLabel?> endLabel;    // anchor 1.0
  Observable<ConnectionEffect?> animationEffect;
  ObservableList<Offset> controlPoints; // For editable path connections
}
```

**Key Features:**

- Three label positions: start, center (0.5 anchor), and end
- Observable labels and animation state for reactive updates
- Custom styles and endpoint markers
- Arbitrary data attachment via `data` map
- Animation effects support (FlowingDash, Particle, GradientFlow, Pulse)
- `locked` flag to prevent accidental deletion
- Control points for user-editable connection paths

## Rendering Pipeline

The editor uses a multi-layer rendering approach:

1. **Grid Layer**: Background grid (dots or lines)
2. **Connections Layer**: All connections between nodes
3. **Connection Labels Layer**: Labels on connections
4. **Nodes Layer**: Node widgets via custom builder
5. **Interaction Layer**: Selection rectangles, temporary connections

Each layer is optimized independently for performance.

## State Management

Vyuh Node Flow uses **MobX** for reactive state management:

- All mutable state is wrapped in `Observable`
- UI automatically updates when observables change
- No need for manual state synchronization
- Efficient change detection

Example:

```dart
final node = Node<MyData>(
  position: Offset(100, 100), // Wrapped in Observable internally
);

// Moving a node triggers automatic UI update
node.position.value = Offset(200, 200);
```

## Event Flow

User interactions flow through the system like this:

```
User Action → Interaction Layer → Controller → Graph Model → MobX Reactions → UI Update
```

Example: Moving a node

1. User drags a node
2. Interaction layer detects drag
3. Calls `controller.moveNode()`
4. Controller updates node position (Observable)
5. MobX triggers reaction
6. UI re-renders affected nodes

## Extensibility Points

The architecture provides several extension points:

### Core Customization

1. **Custom Node Data**: Use any type for your node's `data` field
2. **Node Builders**: Provide custom node widgets for building the content as
   well as the container
3. **Special Nodes**: Use `GroupNode` for visual grouping and `CommentNode` for
   annotations
4. **Validators**: Add connection validation logic

### Theming

1. **Themes**: Customize all visual aspects
2. **Connection Styles**: Implement custom connection renderers like bezier,
   smoothstep, step, and straight
3. **Connection Effects**: Add effects like flowing dashed lines, pulsing lines,
   moving arrows, particles, etc.
4. **Port Shapes**: Leverage custom shapes to create endpoints and ports
5. **Grid Styles**: Create custom grid styles. By default, you get dots, grid,
   hierarchical-grid, lines, and cross styles
6. **Node Shapes**: Use built-in or custom shapes for node containers

::: details 🖼️ Customization Points Overview Grid layout showing customization
examples: (1) Connection Styles - bezier, step, smoothstep, straight paths; (2)
Connection Effects - flowing dashes, particles, gradients, pulse; (3) Port
Shapes - circle, square, diamond, triangle, capsule; (4) Grid Styles - dots,
lines, cross, hierarchical; (5) Node Shapes - rectangle, circle, diamond,
hexagon with ports. :::

## Design Principles

1. **Separation of Concerns**: Clear boundaries between layers
2. **Reactive**: Automatic UI updates via MobX
3. **Type Safety**: Generic types for compile-time safety
4. **Extensibility**: Multiple extension points
5. **Performance**: Optimized for large graphs
6. **Flutter-native**: Built with Flutter best practices

## Next Steps

- Learn about [Nodes](/docs/concepts/nodes)
- Explore [Ports](/docs/concepts/ports)
- Understand [Connections](/docs/concepts/connections)
- Deep dive into the [Controller](/docs/concepts/controller)
