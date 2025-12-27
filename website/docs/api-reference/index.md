---
title: API Reference
description: Complete API documentation for Vyuh Node Flow
---

# API Reference

Complete reference documentation for all classes, methods, and properties in Vyuh Node Flow.

## Core Classes

  - **[NodeFlowController](/docs/api-reference/controller)** - Central controller for managing the graph state
  - **[Node](/docs/api-reference/node)** - Individual nodes in the graph with data and ports
  - **[Port](/docs/api-reference/port)** - Connection points on nodes
  - **[Connection](/docs/api-reference/connection)** - Links between node ports

## Widgets

  - **[NodeFlowEditor](/docs/components/node-flow-editor)** - Main editor widget for interactive graphs
  - **[Minimap](/docs/components/minimap)** - Navigation overview widget

## Events

  - **[NodeFlowEvents](/docs/api-reference/events)** - Event handling for all interactions

## Theming

  - **[NodeFlowTheme](/docs/api-reference/theme)** - Complete theme configuration

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
| `type` | `String?` | Node type for categorization |
| `position` | `Offset` | Position on canvas |
| `size` | `Size` | Node dimensions |
| `data` | `T` | Custom data payload |
| `inputPorts` | `List<Port>` | Input connection ports |
| `outputPorts` | `List<Port>` | Output connection ports |
| `shape` | `NodeShape` | Visual shape (rectangle, circle, etc.) |

### Port Properties

| Property | Type | Description |
|----------|------|-------------|
| `id` | `String` | Unique identifier |
| `name` | `String?` | Display name |
| `position` | `PortPosition` | Side of node (top, right, bottom, left) |
| `shape` | `PortShape` | Visual shape (circle, square, diamond, triangle) |
| `color` | `Color?` | Port color override |

### Connection Properties

| Property | Type | Description |
|----------|------|-------------|
| `id` | `String` | Unique identifier |
| `sourceNodeId` | `String` | Source node ID |
| `sourcePortId` | `String` | Source port ID |
| `targetNodeId` | `String` | Target node ID |
| `targetPortId` | `String` | Target port ID |
| `label` | `String?` | Center label |
| `startLabel` | `String?` | Label at source |
| `endLabel` | `String?` | Label at target |
