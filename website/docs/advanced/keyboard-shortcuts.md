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

The following features are planned but not yet fully implemented:

- **Copy/Cut/Paste** (`Cmd/Ctrl + C/X/V`) - Clipboard functionality pending
- **Undo/Redo** - Not currently available
- **Grouping** (`Cmd/Ctrl + G`) - Not currently available
- **Ungrouping** (`Cmd/Ctrl + Shift + G`) - Not currently available

## How Shortcuts Work

Keyboard shortcuts are automatically enabled and integrated into the `NodeFlowEditor`. The shortcuts system is built into the `NodeFlowController` and requires no additional setup.

```dart
// Shortcuts work automatically
final controller = NodeFlowController<MyData>();

NodeFlowEditor(
  controller: controller,
  nodeBuilder: (context, node) => MyNodeWidget(node),
)
```

The editor internally wraps your content with `NodeFlowKeyboardHandler`, which manages all keyboard interactions using Flutter's Actions and Shortcuts system.

::: info
**For Developers**: To customize shortcuts or create custom actions, see the [Shortcuts & Actions API](/docs/api/shortcuts-actions) reference.

:::

## Viewing Available Shortcuts

Show users what shortcuts are available:

```dart
IconButton(
  icon: Icon(Icons.keyboard),
  onPressed: () {
    showShortcutsDialog(context, controller);
  },
  tooltip: 'Keyboard Shortcuts',
)
```

The built-in dialog shows all registered actions grouped by category, along with their keyboard shortcuts.

## Best Practices

1. **Discoverability**: Show keyboard shortcuts in tooltips and provide a shortcuts dialog
2. **Consistency**: Follow platform conventions (Cmd on macOS, Ctrl on Windows/Linux)
3. **Visual Feedback**: Provide feedback when shortcuts are triggered
4. **Documentation**: Make shortcuts visible and discoverable to users

## See Also

- [Shortcuts & Actions API](/docs/api/shortcuts-actions) - Customize and extend shortcuts
- [NodeFlowEditor](/docs/components/node-flow-editor) - Main editor component
- [Examples](/docs/examples/) - See shortcuts in action
