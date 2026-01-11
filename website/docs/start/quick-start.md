---
title: Quick Start
description: Build your first node flow editor in 10 minutes
---

# Quick Start

Build a fully functional flow editor with nodes, connections, and interactions.

## What You'll Build

![Final Example](/images/quick-start.png)

A flow editor with:

- Three connected nodes
- Drag-and-drop node positioning
- Interactive connection creation
- Pan and zoom navigation
- Add new nodes with a button

## The Code

### Create the Controller with Initial Graph

The `NodeFlowController` manages all state - nodes, connections, selection, and viewport.
You can provide initial nodes and connections directly in the constructor.

<<< @/.vitepress/theme/code-samples/quick-start/controller.dart{dart}

::: tip
The generic type `<String>` represents your node data. Use any type - `Map<String, dynamic>`, a custom class, or sealed classes for type-safe nodes.

:::

### Build the Editor

Use `NodeFlowEditor` with a `nodeBuilder` callback.

<<< @/.vitepress/theme/code-samples/quick-start/build.dart{dart}

## Complete Example

Here's the full working code:

<<< @/.vitepress/theme/code-samples/quick-start/complete.dart{dart} [my_flow_editor.dart]

## Interactions Out of the Box

Your editor now supports:

| Interaction           | How                                       |
|-----------------------|-------------------------------------------|
| **Pan canvas**        | Left-click drag on empty canvas           |
| **Zoom**              | Mouse wheel or pinch gesture              |
| **Auto-pan**          | Drag nodes near canvas edge               |
| **Select node**       | Click on a node                           |
| **Multi-select**      | `Shift` + click, or `Shift` + drag marquee    |
| **Drag node**         | Click and drag a node                     |
| **Duplicate**         | `Ctrl`/`Cmd` + `D`                              |
| **Create connection** | Drag from an output port to an input port |
| **Delete**            | Select and press Delete or Backspace      |
| **Fit view**          | Press `F` key                             |
| **Fit selected**      | Press `H` key                             |
| **Select all**        | `Ctrl`/`Cmd` + `A`                              |
| **Invert Selection**  | `Ctrl`/`Cmd` + `I`                              |
| **Toggle minimap**    | Press `M` key                             |
| **Toggle snapping**   | Press `N` key                             |

## Customization Options

::: code-group

```dart [Theme]
NodeFlowEditor<String, dynamic>(
  controller: controller,
  theme: NodeFlowTheme.dark, // or NodeFlowTheme.light
  // Or customize an existing theme:
  // theme: NodeFlowTheme.dark.copyWith(
  //   backgroundColor: Colors.grey.shade900,
  //   nodeTheme: NodeTheme.dark.copyWith(
  //     backgroundColor: Colors.blue.shade800,
  //     borderColor: Colors.blue.shade400,
  //   ),
  //   connectionTheme: ConnectionTheme.dark.copyWith(
  //     style: ConnectionStyles.bezier,
  //     color: Colors.blue,
  //   ),
  //   gridTheme: GridTheme.dark.copyWith(
  //     style: GridStyles.dots,
  //     color: Colors.grey.shade700,
  //   ),
  // ),
)
```

```dart [Events]
NodeFlowEditor<String, dynamic>(
  controller: controller,
  events: NodeFlowEvents(
    node: NodeEvents(
      onTap: (node) => print('Tapped: ${node.id}'),
      onDoubleTap: (node) => _editNode(node),
      onDragStop: (node) => _savePosition(node),
    ),
    connection: ConnectionEvents(
      onCreated: (conn) => print('Created: ${conn.id}'),
      onDeleted: (conn) => print('Deleted: ${conn.id}'),
    ),
    viewport: ViewportEvents(
      onCanvasTap: (pos) => _handleCanvasTap(pos),
    ),
    onSelectionChange: (state) => _updateToolbar(state),
  ),
)
```

```dart [Behavior]
NodeFlowEditor<String, dynamic>(
  controller: controller,
  // Use behavior presets to control interaction modes
  behavior: NodeFlowBehavior.design,   // Full editing (default)
  // behavior: NodeFlowBehavior.preview, // Navigate and drag, no structural changes
  // behavior: NodeFlowBehavior.inspect, // Select only, no dragging or editing
  // behavior: NodeFlowBehavior.present, // Display only, no interaction
  scrollToZoom: true,      // Enable scroll wheel zoom
  showAnnotations: true,   // Show GroupNode/CommentNode annotations
)
```

:::

## Next Steps

  - **[Core Concepts](/docs/concepts/architecture)** - Understand nodes, ports, and connections
  - **[Theming](/docs/theming/overview)** - Customize every visual aspect
  - **[Connection Styles](/docs/theming/connection-styles)** - Bezier, step, straight, and more
  - **[Serialization](/docs/advanced/serialization)** - Save and load your flows
