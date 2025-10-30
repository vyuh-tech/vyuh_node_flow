# Change Log

All notable changes to this project will be documented in this file.
See [Conventional Commits](https://conventionalcommits.org) for commit guidelines.

## 2025-10-30

### Changes

---

Packages with breaking changes:

 - There are no breaking changes in this release.

Packages with other changes:

 - [`vyuh_node_flow` - `v0.2.5+1`](#vyuh_node_flow---v0251)

---

#### `vyuh_node_flow` - `v0.2.5+1`

 - **FIX**: align horizontal, align vertical, distribute horizontal, distribute vertical. grid layout and hierarchical layout were not working properly because the visual positions were not being set.

## 0.2.5

- Added API docs for `NodeFlowEditor` and `NodeFlowController`

## 0.2.4+1

- updated images
- added github workflows

## 0.2.4

- Merging PR #1 from @kevmoo
- Updated deps to latest in example

## 0.2.3 - 0.2.3+1

- Fix for connection rendering when theme changes
- Updated readme

## 0.2.2

- Updated pubspec for better scores on pub.dev

## 0.2.1

- Updated readme

## 0.2.0+2

- Updated examples
- Publishing to https://flow.demo.vyuh.tech

## 0.2.0+1

- Adding images to README.md
- Fixing rendering of Straight line Connection
- Making the `ConnectionsLayer` reactive to theme changes

## 0.1.0

- Initial release of Vyuh Node Flow
- Reactive node-based flow editor with high-performance rendering
- Comprehensive theming system for nodes, connections, and ports
- Flexible port configuration with multiple shapes and positions
- Connection validation and multiple connection styles (bezier, smoothstep,
  straight, step)
- Built-in annotations system for labels and notes
- Minimap support for navigation in complex flows
- Full keyboard shortcuts and accessibility support
- Read-only viewer mode
- Serialization support (save/load graphs to/from JSON)
- Strongly-typed node data with sealed class support
- Pattern matching for node rendering
- Complete examples demonstrating all features
