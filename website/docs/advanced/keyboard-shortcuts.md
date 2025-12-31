---
title: Keyboard Shortcuts
description: Master keyboard shortcuts for efficient flow editing
---

# Keyboard Shortcuts

::: details 🖼️ Keyboard Shortcuts Overview
Visual keyboard showing common shortcuts: Cmd+A (Select All), Delete (Remove), F (Fit View), Cmd+D (Duplicate), arrow keys with Cmd+Shift (Alignment). Each shortcut labeled with its action. Shows platform-aware display (Cmd on macOS, Ctrl on Windows).
:::

Vyuh Node Flow includes built-in keyboard shortcuts for power users. Navigate, select, and manipulate your flow diagrams without touching the mouse.

::: tip
**Platform-Aware**: Shortcuts automatically adapt to your platform, using Cmd on macOS and Ctrl on Windows/Linux.

:::

## Available Shortcuts

::: info
**Note**: The keyboard shortcut system is extensible, but not all features are currently implemented. The shortcuts listed below are the currently available ones.

:::

### Selection

| Shortcut | Action | Description |
|----------|--------|-------------|
| `Cmd/Ctrl + A` | Select all | Select all nodes |
| `Cmd/Ctrl + I` | Invert selection | Invert current selection |
| `Escape` | Cancel/Clear | Cancel operation or clear selection |

### Editing

| Shortcut | Action | Description |
|----------|--------|-------------|
| `Delete` / `Backspace` | Delete | Delete selected nodes, connections, and annotations |
| `Cmd/Ctrl + D` | Duplicate | Duplicate selected nodes |
| `N` | Toggle snapping | Toggle grid snapping on/off |
| `Enter` | Edit node | Edit selected node (comment text or group title) |

### Navigation

| Shortcut | Action | Description |
|----------|--------|-------------|
| `F` | Fit all to view | Fit all nodes in viewport |
| `H` | Fit selected | Fit selected nodes in viewport |
| `Cmd/Ctrl + 0` | Reset zoom | Reset zoom to 100% |
| `Cmd/Ctrl + =` | Zoom in | Increase zoom level |
| `Cmd/Ctrl + -` | Zoom out | Decrease zoom level |
| `M` | Toggle minimap | Show/hide minimap |

### Arrangement

| Shortcut | Action | Description |
|----------|--------|-------------|
| `[` | Send to back | Send selected items to back layer |
| `]` | Bring to front | Bring selected items to front layer |
| `Cmd/Ctrl + [` | Send backward | Send selected items backward one layer |
| `Cmd/Ctrl + ]` | Bring forward | Bring selected items forward one layer |

### Alignment

::: warning
**Requires 2+ nodes**: Alignment shortcuts only work when at least 2 nodes are selected.

:::

| Shortcut | Action | Description |
|----------|--------|-------------|
| `Cmd/Ctrl + Shift + ↑` | Align top | Align selected nodes to top edge |
| `Cmd/Ctrl + Shift + ↓` | Align bottom | Align selected nodes to bottom edge |
| `Cmd/Ctrl + Shift + ←` | Align left | Align selected nodes to left edge |
| `Cmd/Ctrl + Shift + →` | Align right | Align selected nodes to right edge |

## Not Yet Implemented

The following features have shortcuts registered but the actions are not yet fully implemented:

- **Copy/Cut/Paste** (`Cmd/Ctrl + C/X/V`) - Clipboard functionality pending
- **Undo/Redo** - Not currently available
- **Grouping** (`Cmd/Ctrl + G`) - Create group action pending
- **Ungrouping** (`Cmd/Ctrl + Shift + G`) - Ungroup action pending

## How Shortcuts Work

Keyboard shortcuts are automatically enabled and integrated into the `NodeFlowEditor`. The shortcuts system is built into the `NodeFlowController` and requires no additional setup.

```dart
// Shortcuts work automatically
final controller = NodeFlowController<MyData, dynamic>();

NodeFlowEditor(
  controller: controller,
  nodeBuilder: (context, node) => MyNodeWidget(node),
)
```

The editor internally wraps your content with `NodeFlowKeyboardHandler`, which manages all keyboard interactions using Flutter's Actions and Shortcuts system.

::: info
**For Developers**: To customize shortcuts or create custom actions, see the [Shortcuts & Actions API](/docs/advanced/shortcuts-actions) reference.

:::

## Viewing Available Shortcuts

You can query available shortcuts programmatically to build your own shortcuts help UI:

```dart
// Get all actions grouped by category
final actionsByCategory = controller.shortcuts.getActionsByCategory();

// Get the shortcut for a specific action
final shortcut = controller.shortcuts.getShortcutForAction('fit_to_view');

// Search for actions
final results = controller.shortcuts.searchActions('align');
```

See the [Shortcuts & Actions API](/docs/advanced/shortcuts-actions) for more details on querying and customizing shortcuts.

## Best Practices

1. **Discoverability**: Show keyboard shortcuts in tooltips and provide a shortcuts dialog
2. **Consistency**: Follow platform conventions (Cmd on macOS, Ctrl on Windows/Linux)
3. **Visual Feedback**: Provide feedback when shortcuts are triggered
4. **Documentation**: Make shortcuts visible and discoverable to users

## See Also

- [Shortcuts & Actions API](/docs/advanced/shortcuts-actions) - Customize and extend shortcuts
- [NodeFlowEditor](/docs/components/node-flow-editor) - Main editor component
- [Examples](/docs/examples/) - See shortcuts in action
