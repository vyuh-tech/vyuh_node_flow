---
title: Shortcuts & Actions API
description: Customize keyboard shortcuts and create custom actions
---

# Shortcuts & Actions API

Learn how to customize keyboard shortcuts and create custom actions for your NodeFlow editor. The shortcuts system uses Flutter's Actions and Shortcuts framework integrated with NodeFlow's action system.

## Architecture Overview

The shortcuts system consists of three main components:

1. **NodeFlowAction** - Defines executable operations
2. **NodeFlowShortcutManager** - Maps keyboard shortcuts to actions
3. **NodeFlowKeyboardHandler** - Integrates with Flutter's shortcuts system

All shortcuts are managed through the controller:

```dart
final controller = NodeFlowController<MyData>();
controller.shortcuts // Access the shortcuts manager
```

## Customizing Shortcuts

### Changing Existing Shortcuts

Reassign keyboard shortcuts to different actions:

```dart
final controller = NodeFlowController<MyData>();

// Change the fit-to-view shortcut from F to Q
controller.shortcuts.setShortcut(
  LogicalKeySet(LogicalKeyboardKey.keyQ),
  'fit_to_view',
);

// Add Cmd/Ctrl modifier
controller.shortcuts.setShortcut(
  LogicalKeySet(LogicalKeyboardKey.keyF, LogicalKeyboardKey.meta),
  'fit_to_view',
);
```

### Removing Shortcuts

Remove keyboard shortcuts entirely:

```dart
// Remove the F key shortcut for fit_to_view
controller.shortcuts.removeShortcut(
  LogicalKeySet(LogicalKeyboardKey.keyF),
);
```

### Platform-Aware Shortcuts

Shortcuts automatically handle Cmd (macOS) and Ctrl (Windows/Linux). Both are registered by default:

```dart
// This is already done by default for built-in actions
controller.shortcuts.setShortcut(
  LogicalKeySet(LogicalKeyboardKey.keyA, LogicalKeyboardKey.meta),
  'select_all_nodes',
);
controller.shortcuts.setShortcut(
  LogicalKeySet(LogicalKeyboardKey.keyA, LogicalKeyboardKey.control),
  'select_all_nodes',
);
```

## Creating Custom Actions

### Define Your Action

Create a class extending `NodeFlowAction<T>`:

```dart
class SaveGraphAction<T> extends NodeFlowAction<T> {
  const SaveGraphAction()
    : super(
        id: 'save_graph',
        label: 'Save Graph',
        description: 'Save the current graph to file',
        category: 'File',
      );

  @override
  bool execute(NodeFlowController<T> controller, BuildContext? context) {
    // Your save logic here
    final graph = controller.exportGraph();
    final json = graph.toJson((data) => data.toJson());

    // Example: Save to file
    // final file = File('graph.json');
    // await file.writeAsString(jsonEncode(json));

    // Show confirmation if context available
    if (context != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Graph saved successfully')),
      );
    }

    return true; // Return true if action succeeded
  }

  @override
  bool canExecute(NodeFlowController<T> controller) {
    // Only allow saving if there are nodes
    return controller.nodes.isNotEmpty;
  }
}
```

### Register the Action

Add your action to the shortcuts manager:

```dart
final controller = NodeFlowController<MyData>();

// Register the action
controller.shortcuts.registerAction(SaveGraphAction<MyData>());

// Assign keyboard shortcuts (both platforms)
controller.shortcuts.setShortcut(
  LogicalKeySet(LogicalKeyboardKey.keyS, LogicalKeyboardKey.meta),
  'save_graph',
);
controller.shortcuts.setShortcut(
  LogicalKeySet(LogicalKeyboardKey.keyS, LogicalKeyboardKey.control),
  'save_graph',
);
```

### Use in Your App

The shortcut now works automatically in your editor:

```dart
NodeFlowEditor(
  controller: controller,
  nodeBuilder: (context, node) => MyNodeWidget(node),
)

// Press Cmd+S (Mac) or Ctrl+S (Windows/Linux) to save!
```

## NodeFlowAction API

### Required Members

```dart
abstract class NodeFlowAction<T> {
  const NodeFlowAction({
    required this.id,        // Unique identifier
    required this.label,     // Display name
    this.description,        // Optional description
    this.category = 'General', // For grouping in menus
  });

  /// Execute the action's operation
  bool execute(NodeFlowController<T> controller, BuildContext? context);

  /// Check if action can currently be executed
  bool canExecute(NodeFlowController<T> controller) => true;
}
```

### Action Parameters

| Parameter | Type | Description |
|-----------|------|-------------|
| **id** | `String` | Unique identifier for the action (e.g., 'save_graph') |
| **label** | `String` | Human-readable name shown in UI (e.g., 'Save Graph') |
| **description** | `String?` | Optional tooltip text |
| **category** | `String` | Groups actions in menus (e.g., 'File', 'Edit', 'View') |

### Execute Method

The `execute` method performs the action:

**Parameters:**
- `controller`: The NodeFlowController to operate on
- `context`: Optional BuildContext for showing dialogs/snackbars

**Returns:** `bool` - `true` if action succeeded, `false` otherwise

### CanExecute Method

The `canExecute` method determines when an action is available:

```dart
@override
bool canExecute(NodeFlowController<T> controller) {
  // Example: Only enable when multiple nodes selected
  return controller.selectedNodeIds.length >= 2;
}
```

Common patterns:
- Check for selection: `controller.selectedNodeIds.isNotEmpty`
- Check node count: `controller.nodes.length > 0`
- Check permissions: `controller.enableNodeDeletion`
- Custom logic: Any boolean condition

## NodeFlowShortcutManager API

Access through `controller.shortcuts`:

### Methods

#### registerAction

Register a single action:

```dart
controller.shortcuts.registerAction(MyCustomAction<MyData>());
```

#### registerActions

Register multiple actions at once:

```dart
controller.shortcuts.registerActions([
  SaveAction<MyData>(),
  LoadAction<MyData>(),
  ExportAction<MyData>(),
]);
```

#### setShortcut

Map a keyboard shortcut to an action:

```dart
controller.shortcuts.setShortcut(
  LogicalKeySet(LogicalKeyboardKey.keyS, LogicalKeyboardKey.meta),
  'save_graph', // Action ID
);
```

#### removeShortcut

Remove a keyboard shortcut:

```dart
controller.shortcuts.removeShortcut(
  LogicalKeySet(LogicalKeyboardKey.keyF),
);
```

#### getAction

Get an action by its ID:

```dart
final action = controller.shortcuts.getAction('save_graph');
if (action != null) {
  // Use the action
}
```

#### getShortcutForAction

Get the keyboard shortcut for an action:

```dart
final shortcut = controller.shortcuts.getShortcutForAction('save_graph');
// Returns LogicalKeySet or null
```

#### getActionsByCategory

Get all actions grouped by category:

```dart
final actionsByCategory = controller.shortcuts.getActionsByCategory();

for (final entry in actionsByCategory.entries) {
  print('Category: ${entry.key}');
  for (final action in entry.value) {
    print('  - ${action.label}');
  }
}
```

#### searchActions

Search for actions by query:

```dart
final results = controller.shortcuts.searchActions('align');
// Returns list of actions matching the query
```

## Common Patterns

### Quick Node Creation

Create actions for adding specific node types:

```dart
class AddNodeAction<T> extends NodeFlowAction<T> {
  final String nodeType;
  final String label;

  const AddNodeAction({
    required String id,
    required this.nodeType,
    required this.label,
  }) : super(
         id: id,
         label: label,
         category: 'Nodes',
       );

  @override
  bool execute(NodeFlowController<T> controller, BuildContext? context) {
    final viewport = controller.viewport;
    final centerX = viewport.x + (viewport.width / 2);
    final centerY = viewport.y + (viewport.height / 2);

    final node = Node<T>(
      id: '$nodeType-${DateTime.now().millisecondsSinceEpoch}',
      type: nodeType,
      position: Offset(centerX, centerY),
      size: Size(150, 80),
      data: /* your data */,
    );

    controller.addNode(node);
    return true;
  }
}

// Register with number shortcuts
controller.shortcuts.registerAction(
  AddNodeAction<MyData>(
    id: 'add_start_node',
    nodeType: 'start',
    label: 'Add Start Node',
  ),
);
controller.shortcuts.setShortcut(
  LogicalKeySet(LogicalKeyboardKey.digit1),
  'add_start_node',
);
```

### Conditional Actions

Actions that are only available under certain conditions:

```dart
class AlignNodesAction<T> extends NodeFlowAction<T> {
  final NodeAlignment alignment;

  const AlignNodesAction(this.alignment)
    : super(
        id: 'align_${alignment.name}',
        label: 'Align ${alignment.name}',
        category: 'Alignment',
      );

  @override
  bool execute(NodeFlowController<T> controller, BuildContext? context) {
    controller.alignNodes(
      controller.selectedNodeIds.toList(),
      alignment,
    );
    return true;
  }

  @override
  bool canExecute(NodeFlowController<T> controller) {
    // Only enable when 2+ nodes are selected
    return controller.selectedNodeIds.length >= 2;
  }
}
```

### Actions with Dialogs

Actions that show dialogs for user input:

```dart
class RenameNodeAction<T> extends NodeFlowAction<T> {
  const RenameNodeAction()
    : super(
        id: 'rename_node',
        label: 'Rename Node',
        category: 'Editing',
      );

  @override
  bool execute(NodeFlowController<T> controller, BuildContext? context) {
    if (context == null) return false;

    final selectedIds = controller.selectedNodeIds;
    if (selectedIds.isEmpty) return false;

    final node = controller.getNode(selectedIds.first);
    if (node == null) return false;

    showDialog(
      context: context,
      builder: (context) => RenameNodeDialog(
        node: node,
        onRename: (newName) {
          // Update node with new name
          controller.updateNode(node.copyWith(data: /* updated data */));
        },
      ),
    );

    return true;
  }

  @override
  bool canExecute(NodeFlowController<T> controller) {
    return controller.selectedNodeIds.length == 1;
  }
}
```

### Async Actions

Actions that perform asynchronous operations:

```dart
class ExportImageAction<T> extends NodeFlowAction<T> {
  const ExportImageAction()
    : super(
        id: 'export_image',
        label: 'Export as Image',
        category: 'File',
      );

  @override
  bool execute(NodeFlowController<T> controller, BuildContext? context) {
    // Trigger async operation
    _exportToImage(controller, context);
    return true;
  }

  Future<void> _exportToImage(
    NodeFlowController<T> controller,
    BuildContext? context,
  ) async {
    try {
      // Show loading indicator
      if (context != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Exporting...')),
        );
      }

      // Perform export (pseudo-code)
      final imageBytes = await _captureGraph(controller);
      await _saveToFile(imageBytes);

      // Show success message
      if (context != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Export successful!')),
        );
      }
    } catch (e) {
      if (context != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Export failed: $e')),
        );
      }
    }
  }
}
```

## Programmatic Execution

Execute actions programmatically without keyboard input:

```dart
// Execute an action directly
final action = controller.shortcuts.getAction('fit_to_view');
if (action != null && action.canExecute(controller)) {
  action.execute(controller, context);
}

// Execute by ID (simpler)
void executeAction(String actionId) {
  final action = controller.shortcuts.getAction(actionId);
  if (action?.canExecute(controller) ?? false) {
    action!.execute(controller, null);
  }
}

// Use in buttons
ElevatedButton(
  onPressed: () => executeAction('save_graph'),
  child: Text('Save'),
)
```

## Introspection

Query the shortcuts system:

```dart
// Get all shortcuts
final allShortcuts = controller.shortcuts.shortcuts;

// Get all actions
final allActions = controller.shortcuts.actions;

// Find actions by category
final fileActions = controller.shortcuts
    .getActionsByCategory()['File'] ?? [];

// Search for actions
final alignActions = controller.shortcuts.searchActions('align');

// Check if shortcut exists
final saveShortcut = controller.shortcuts.getShortcutForAction('save_graph');
if (saveShortcut != null) {
  print('Save shortcut: ${_formatShortcut(saveShortcut)}');
}
```

## Built-in Action IDs

Reference for built-in actions you can customize or extend:

### Selection
- `select_all_nodes` - Select all nodes
- `invert_selection` - Invert current selection
- `clear_selection` - Clear selection

### Editing
- `delete_selected` - Delete selected items
- `duplicate_selected` - Duplicate selected nodes
- `cut_selected` - Cut selected nodes (not implemented)
- `copy_selected` - Copy selected nodes (not implemented)
- `paste` - Paste nodes (not implemented)

### Navigation
- `fit_to_view` - Fit all nodes in viewport
- `fit_selected` - Fit selected nodes in viewport
- `reset_zoom` - Reset zoom to 100%
- `zoom_in` - Zoom in
- `zoom_out` - Zoom out

### Arrangement
- `bring_to_front` - Bring selected to front
- `send_to_back` - Send selected to back
- `bring_forward` - Bring selected forward one layer
- `send_backward` - Send selected backward one layer

### Alignment
- `align_top` - Align selected nodes to top
- `align_bottom` - Align selected nodes to bottom
- `align_left` - Align selected nodes to left
- `align_right` - Align selected nodes to right
- `align_horizontal_center` - Align to horizontal center
- `align_vertical_center` - Align to vertical center

### General
- `cancel_operation` - Cancel current operation
- `toggle_minimap` - Toggle minimap visibility
- `toggle_snapping` - Toggle grid snapping

## Best Practices

1. **Unique IDs**: Use descriptive, unique action IDs (e.g., 'save_graph' not 'save')
2. **Categories**: Group related actions in meaningful categories
3. **Can Execute**: Always implement `canExecute` to disable actions when not applicable
4. **Error Handling**: Handle errors gracefully in `execute` method
5. **Context Usage**: Check for null context before showing dialogs/snackbars
6. **Return Values**: Return `true` only when action actually succeeds
7. **Side Effects**: Avoid side effects in `canExecute` - it's called frequently
8. **Platform Shortcuts**: Register both Cmd and Ctrl variants for cross-platform support

## See Also

- [Keyboard Shortcuts](/docs/advanced/keyboard-shortcuts) - User guide to shortcuts
- [Controller](/docs/core-concepts/controller) - Controller API
- [Examples](/docs/examples/) - See custom actions in practice
