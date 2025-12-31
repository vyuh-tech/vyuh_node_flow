---
title: Examples
description: Interactive examples showcasing Vyuh Node Flow capabilities
---

# Examples

Learn by exploring interactive examples. Each example demonstrates a specific feature or pattern.

::: info
**Live Demo**: All examples are available in our [interactive demo](https://flow.demo.vyuh.tech). Try them directly in your browser.

:::

## Basics

Master the fundamentals with these introductory examples.

  - **Simple Node Addition** - Add nodes to the canvas with a click. The most basic starting point.

  - **Controlling Nodes** - Add, select, move, and delete nodes programmatically.

  - **Node Shapes** - Circle, diamond, hexagon, and rectangle node variants.

  - **Dynamic Ports** - Add ports at runtime - nodes resize automatically.

  - **Port Positions & Styles** - All port positions and connection style combinations.

  - **Port Labels** - Display port names with intelligent positioning.

  - **Minimap Navigation** - Navigate large graphs with the interactive minimap.

  - **Event Callbacks** - Real-time logging of all node, connection, and annotation events.

## Advanced Features

Explore sophisticated capabilities for production applications.

  - **Keyboard Shortcuts** - All built-in shortcuts plus custom action registration.

  - **Save & Load (JSON)** - Serialize and deserialize complete workflows.

  - **Alignment & Distribution** - Align and distribute nodes with precision tools.

  - **Annotation System** - Sticky notes, groups, and markers for documentation.

  - **Animated Connections** - Flowing dashes, particles, gradients, and pulse effects.

  - **Connection Labels** - Position and style labels on connections.

  - **Theme Customization** - Light, dark, and fully custom themes.

  - **Read-only Viewer** - Display flows without editing capability.

  - **Connection Validation** - Type checking and connection limit enforcement.

  - **Full Workbench** - Complete demo with all features integrated.

## Example Code Patterns

::: code-group

```dart [Basic Setup]
class MyEditor extends StatefulWidget {
  @override
  State<MyEditor> createState() => _MyEditorState();
}

class _MyEditorState extends State<MyEditor> {
  late final NodeFlowController<String, dynamic> controller;

  @override
  void initState() {
    super.initState();
    controller = NodeFlowController<String, dynamic>();
    // Add initial nodes...
  }

  @override
  Widget build(BuildContext context) {
    return NodeFlowEditor<String, dynamic>(
      controller: controller,
      theme: NodeFlowTheme.light,
      nodeBuilder: (context, node) => Center(
        child: Text(node.data),
      ),
    );
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }
}
```

```dart [With Events]
NodeFlowEditor<String, dynamic>(
  controller: controller,
  events: NodeFlowEvents(
    node: NodeEvents(
      onTap: (node) => _showNodeDetails(node),
      onDoubleTap: (node) => _editNode(node),
      onContextMenu: (node, position) => _showContextMenu(node, position),
    ),
    connection: ConnectionEvents(
      onCreated: (conn) => _logConnection(conn),
      onBeforeComplete: (context) => _validateConnection(context),
    ),
    viewport: ViewportEvents(
      onCanvasTap: (position) => _addNodeAt(position),
    ),
    onSelectionChange: (state) => setState(() => _selection = state),
  ),
)
```

```dart [Custom Theme]
NodeFlowEditor<String, dynamic>(
  controller: controller,
  theme: NodeFlowTheme(
    backgroundColor: const Color(0xFF1a1a2e),
    nodeTheme: NodeTheme(
      backgroundColor: const Color(0xFF16213e),
      selectedBackgroundColor: const Color(0xFF0f3460),
      borderColor: const Color(0xFF0f3460),
      selectedBorderColor: const Color(0xFFe94560),
      borderWidth: 2,
      borderRadius: BorderRadius.circular(12),
    ),
    connectionTheme: ConnectionTheme(
      style: ConnectionStyles.bezier,
      color: const Color(0xFF0f3460),
      selectedColor: const Color(0xFFe94560),
      strokeWidth: 2,
    ),
    gridTheme: GridTheme(
      style: GridStyles.dots,
      color: const Color(0xFF0f3460).withOpacity(0.3),
      size: 20,
    ),
  ),
)
```

:::

## Running the Demo Locally

Clone and run the demo app to explore all examples with source code:

```bash
# Clone the repository
git clone https://github.com/vyuh-tech/vyuh_node_flow.git
cd vyuh_node_flow

# Install dependencies
melos bootstrap

# Run the demo
cd packages/demo
flutter run -d chrome
```

## Source Code

All examples are available in the repository:

- **Demo App**: [packages/demo](https://github.com/vyuh-tech/vyuh_node_flow/tree/main/packages/demo)
- **Example Registry**: [example_registry.dart](https://github.com/vyuh-tech/vyuh_node_flow/blob/main/packages/demo/lib/example_registry.dart)
- **Individual Examples**: [examples/](https://github.com/vyuh-tech/vyuh_node_flow/tree/main/packages/demo/lib/examples)

## Next Steps

  - **[API Reference](/docs/core-concepts/controller)** - Detailed controller and widget documentation
  - **[Theming Guide](/docs/theming/overview)** - Customize every visual aspect
  - **[GitHub Discussions](https://github.com/vyuh-tech/vyuh_node_flow/discussions)** - Ask questions and share ideas
