---
title: Special Node Types
description: GroupNode and CommentNode for organizing your node flows
---

# Special Node Types

Vyuh Node Flow provides **special node types** for organization and documentation:

- **`CommentNode<T>`** - Free-floating sticky notes for documentation
- **`GroupNode<T>`** - Visual containers for grouping related nodes

Both are added via the standard `controller.addNode()` API and support all node features including selection, visibility, and serialization.

## Quick Reference

### CommentNode (Sticky Notes)

```dart
final comment = CommentNode<String>(
  id: 'note-1',
  position: const Offset(100, 100),
  text: 'This is a reminder',
  data: 'optional-data',
  width: 200,   // Default: 200.0, range: 100-600
  height: 150,  // Default: 100.0, range: 60-400
  color: Colors.yellow,
);
controller.addNode(comment);
```

**Features:**
- Renders in foreground layer (above nodes)
- Inline text editing (double-click)
- Auto-grow height as you type
- Resizable with drag handles
- Size constraints: min 100x60, max 600x400

### GroupNode (Containers)

```dart
final group = GroupNode<String>(
  id: 'group-1',
  position: const Offset(50, 50),
  size: const Size(400, 300),
  title: 'Processing Region',
  data: 'group-data',
  color: Colors.blue,
  behavior: GroupBehavior.bounds, // or .explicit, .parent
  nodeIds: {'node-1', 'node-2'},  // For explicit/parent behaviors
);
controller.addNode(group);
```

**Behavior Modes:**

| Mode       | Membership                    | Size                 | Node Movement               |
| ---------- | ----------------------------- | -------------------- | --------------------------- |
| `bounds`   | Spatial (nodes inside bounds) | Manual (resizable)   | Nodes can escape by dragging|
| `explicit` | Explicit (node ID set)        | Auto-computed        | Group resizes to fit nodes  |
| `parent`   | Explicit (node ID set)        | Manual (resizable)   | Nodes move with group       |

**Features:**
- Renders in background layer (behind nodes)
- Inline title editing (double-click)
- Optional input/output ports for subflows
- Nested group support

## Full Documentation

For complete documentation including:
- All properties and methods
- Behavior mode details
- Programmatic updates
- Complete examples
- Serialization

See **[Special Node Types (Advanced)](/docs/advanced/special-node-types)**.

## See Also

- [Level of Detail](/docs/plugins/lod) - Zoom-based visibility control
- [Theming Overview](/docs/theming/overview) - Customize node appearance
- [Controller](/docs/concepts/controller) - Node management API
