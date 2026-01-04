---
title: API
description: Complete API documentation for Vyuh Node Flow
---

# API

Complete reference documentation for all classes, methods, and properties in Vyuh Node Flow.

## Core Classes

  - **[NodeFlowController](/docs/api/controller)** - Central controller for managing the graph state
  - **[Node](/docs/api/node)** - Individual nodes in the graph with data and ports
  - **[Port](/docs/api/port)** - Connection points on nodes
  - **[Connection](/docs/api/connection)** - Links between node ports

## Widgets

  - **[NodeFlowEditor](/docs/components/node-flow-editor)** - Main editor widget for interactive graphs
  - **[Minimap](/docs/extensions/minimap)** - Navigation overview widget

## Events

  - **[NodeFlowEvents](/docs/api/events)** - Event handling for all interactions

## Theming

  - **[NodeFlowTheme](/docs/api/theme)** - Complete theme configuration

## Quick Reference

### Controller Methods

| Method | Description |
|--------|-------------|
| `addNode(node)` | Add a node to the graph |
| `removeNode(id)` | Remove a node by ID |
| `moveNode(id, delta)` | Move a node by offset |
| `setNodeSize(id, size)` | Update node size |
| `addConnection(conn)` | Create a connection |
| `removeConnection(id)` | Remove a connection |
| `selectNode(id)` | Select a node |
| `clearSelection()` | Clear all selections |
| `fitToView()` | Fit viewport to content |
| `zoomTo(level)` | Set zoom level |
| `panBy(delta)` | Pan by offset |
| `loadGraph(graph)` | Load complete graph |
| `exportGraph()` | Export graph state |

### Node Properties

| Property | Type | Description |
|----------|------|-------------|
| `id` | `String` | Unique identifier |
| `type` | `String` | Node type for categorization |
| `position` | `Offset` | Position on canvas |
| `size` | `Size` | Node dimensions |
| `data` | `T` | Custom data payload |
| `inputPorts` | `List<Port>` | Input connection ports |
| `outputPorts` | `List<Port>` | Output connection ports |
| `locked` | `bool` | Prevents dragging/deletion when true |
| `layer` | `NodeRenderLayer` | Rendering layer (background/middle/foreground) |

### Port Properties

| Property | Type | Description |
|----------|------|-------------|
| `id` | `String` | Unique identifier |
| `name` | `String?` | Display name |
| `position` | `PortPosition` | Side of node (top, right, bottom, left) |
| `type` | `PortType` | Direction (input, output) |
| `shape` | `MarkerShape` | Visual shape |
| `color` | `Color?` | Port color override |

### Connection Properties

| Property | Type | Description |
|----------|------|-------------|
| `id` | `String` | Unique identifier |
| `sourceNodeId` | `String` | Source node ID |
| `sourcePortId` | `String` | Source port ID |
| `targetNodeId` | `String` | Target node ID |
| `targetPortId` | `String` | Target port ID |
| `label` | `ConnectionLabel?` | Center label |
| `startLabel` | `ConnectionLabel?` | Label at source |
| `endLabel` | `ConnectionLabel?` | Label at target |
| `locked` | `bool` | Prevents deletion when true |
