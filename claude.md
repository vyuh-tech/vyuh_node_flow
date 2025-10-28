## What is this?

This is a node-based flow editor for Flutter applications, inspired by React
Flow and designed for building visual programming interfaces, workflow editors,
and interactive diagrams.

## Tech

- Flutter
- Dart

## Interactivity

- Auto snapping when going close to an input port
- Port stays within bounds of the node widget for perfect hit testing
- Reliable hover effects and visual feedback for high-confidence interactions
- No scaling effects on ports when hovering as they are jarring and don't work
  well
- All widgets and painting is done using values from the Theme objects for Node,
  Port, Editor, Connection.
- Capsule should rotate for top and bottom sides of Port. The core idea is that
  the flat side of the half-capsule always stays on the outside.
- The connection line should connect the outer edges of the capsule halves for a
  smooth visual flow. This should work properly for both left/right and
  top/bottom ports correctly.
- The ports should be positioned on the edges of the node. For the left and
  right ports, it will be horizontally centered on the left and right edges of
  the node. For the top and bottom it should be vertically centered on the top
  and bottom edges of the node.
- Ports are always painted on top of Nodes so they are always visible
- For the left/right nodes the port can be positioned starting from the top with
  some offset from the top edge.
- For the top/bottom nodes the port can be positioned starting from the left
  with some offset from the left edge.
- The temporary connection line painting is exactly like the actual connection
  line painting. The line should connect the outer edges of the capsule halves
  for a smooth visual flow.
- Connections are established by clicking on a port and dragging to another
  port. The connection is created when the user releases the mouse button on the
  port and not as soon as the target port is hovered or snapped, but only when
  dropped on the port. A drop anywhere else on the canvas should ignore the
  connection.

# State Management

- Uses MobX for state management
- Only raw observables, no annotations
