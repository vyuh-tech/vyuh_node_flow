## 0.18.1

 - **FEAT**: remove snapping circle functionality to simplify port interaction visuals and theme configuration.

## 0.18.0

 - **FEAT**: updated the Resizer behavior to become more predicatable, introduced `NodeFlowScope` for inherited `NodeFlowController` access.

## 0.17.0

 - **FEAT**: restructure library and improve maintainability, modularize and reorganize editor package structure, extract graph events and extensions.

## 0.16.0

- Added the GraphPosition to the connection end callback

- **FIX**: replace `setEvents` with `updateEvents` across tests for consistency.

## 0.15.1

- **REFACTOR**: replace static `fromJsonMap` methods with unified factory
  constructors and improve `CommentNode` color observability.
- **REFACTOR**: remove unused imports and redundant test node creation in
  controller_init_test.
- **FEAT**: add EditorInitApi for unified initialization, improve spatial index
  diagnostics, and update render layer prioritization.

## 0.15.0

- **FEAT**: refactor test factory and add unit tests for constructor
  initialization.

## 0.14.1

- **FEAT**: simplify drag operations across nodes, connections and resizers.
- **FEAT**: refactor context menu callbacks to use `ScreenPosition`, enhance
  port interaction APIs, and simplify node constructor parameters.

## 0.14.0

- **FEAT**: unify Nodes and Annotations.

## 0.13.3

- **FEAT**: remove debug logs, simplify null checks in viewport animation, and
  add lifecycle unit tests for animation handlers.

## 0.13.2

- **FEAT**: streamline port retrieval across nodes and improve viewport
  animation handling with token-based race condition prevention.

## 0.13.1

- **FEAT**: initial set of tests for API, nodes, ports, graph, annotations,
  connections, rendering and performance.

## 0.13.0

- **FEAT**: enhance AutoPan and Viewport Animations, add debug mode with
  overlays for better visualization, and integrate configurable AutoPan presets.
  `debugMode` is now moved into `NodeFlowConfig`.

## 0.12.0

- **FEAT**: introducing Auto-Pan behavior which allows the elements (nodes,
  annotations, connections) to move freely and go past the edges, while keeping
  the viewport panning in place. It also does some interesting calculations for
  avoiding drift, so that the element stays relative to the mouse pointer. This
  is all implemented on the `ElementScope` with an `AutoPanMixin`.

## 0.11.0

- **FEAT**: add ViewportAnimationMixin for smooth viewport animations, integrate
  animation methods into NodeFlowController and NodeFlowEditor, and provide API
  for animating to nodes, positions, bounds, and zoom levels.

## 0.10.9

- **FEAT**: replace custom gesture implementation with ElementScope for
  streamlined gesture handling, lifecycle management, and drag state cleanup;
  enhance interaction robustness and trackpad compatibility.

## 0.10.8

- **FIX**: reset connection hit flag on pointer up to prevent interaction
  conflicts in subsequent actions, refine hit testing hierarchy and annotation
  handling for consistent z-order interaction, enhance drag/selection behaviors
  for annotations and nodes.
- **FEAT**: centralize pan state management in NodeFlowEditor for consistent
  interaction handling during drag, resize, and connection operations, add
  escape key handling to cancel annotation edits and enhance focus behaviors,
  add annotation editing cancellation, keyboard shortcuts, and selection
  clearing enhancements.
- **FEAT**: centralize pan state management in NodeFlowEditor for consistent
  interaction handling during drag, resize, and connection operations.
- **FEAT**: add escape key handling to cancel annotation edits and enhance focus
  behaviors.
- **FEAT**: add annotation editing cancellation, keyboard shortcuts, and
  selection clearing enhancements.

## 0.10.7

- **FEAT**: centralize pan state management in NodeFlowEditor for consistent
  interaction handling during drag, resize, and connection operations.
- **FEAT**: add escape key handling to cancel annotation edits and enhance focus
  behaviors.
- **FEAT**: add annotation editing cancellation, keyboard shortcuts, and
  selection clearing enhancements.

## 0.10.6

- **FEAT**: implement inline editing for annotation titles, add keyboard
  shortcut for editing, and improve canvas focus handling.
- **FEAT**: add editing state support for annotations and implement auto-grow
  for sticky notes.

## 0.10.5

- **REFACTOR**: remove short-distance temporary line drawing logic for
  consistent connection styling.
- **FEAT**: replace `ConnectionControlPointsLayer` with custom gesture
  recognition, improve touch and trackpad interaction handling across nodes,
  ports, and annotations.

## 0.10.4

- **FEAT**: add transformation listener for authoritative viewport syncing and
  improve interaction accuracy.

## 0.10.3

- **FEAT**: add selection mode tracking with cursor feedback and shift key
  interaction.

## 0.10.2

- **FIX**: hit testing outside the bounds of resizer and group-annotation.
- **FEAT**: introduce `coordinates.dart` to enforce type safety in coordinate
  transformations and refactor usage across the package.

## 0.10.1

- **FEAT**: introduce `coordinates.dart` to enforce type safety in coordinate
  transformations and refactor usage across the package.

## 0.10.0+1

- **FIX**: remove selection logic from `selection_api.dart` and consolidate it
  into `connection_api.dart` with expanded functionalities.

## 0.10.0

- **FEAT**: add visibility toggling for nodes and annotations with related UI
  and logic adjustments.
- **FEAT**: added resizing capabilities to annotations with behaviors

## 0.9.0+1

- Analysis fixes

- **FIX**: analysis fixes.
- **FEAT**: enhance interaction handling with connection hover states and
  streamline zoom-related logic.
- **FEAT**: leveraging gesture detectors to handle nodes, ports, annotations.
  Only connections leverage the top-level listener. This ensures that we can
  have widgets and interactive widgets inside nodes and annotations, and have it
  even work outside the original stack bounds.

## 0.9.0

- **FEAT**: enhance interaction handling with connection hover states and
  streamline zoom-related logic.
- **FEAT**: leveraging gesture detectors to handle nodes, ports, annotations.
  Only connections leverage the top-level listener. This ensures that we can
  have widgets and interactive widgets inside nodes and annotations, and have it
  even work outside the original stack bounds.

## 0.8.5+1

- **FIX**: analysis fixes.

## 0.8.5

- **FEAT**: more real-time debug view of spatial index, minor optimization in
  hit-test segment generation for step style connections.

## 0.8.4+3

- Fixed analysis issues and updated readme

## 0.8.4+2

- **FIX**: analysis fixes for 160.

## 0.8.4+1

- **FIX**: left aligning the stat labels for spatial debug painter.

## 0.8.4

- **FEAT**: simplifying connection styles.
- **FEAT**: improved connection routing based on path-segment primitives of
  straight, quadratic, bezier, which are also used to construct the hit-test
  rects. Also introduced loopback routing for all styles. Better port snapping
  for temporary connections. Improved port hit testing by adding it to the
  spatial index.

## 0.8.3

- **FEAT**: improved port hit testing by adding it to the spatial index.
- **FEAT**: improved connection routing based on path-segment primitives of
  straight, quadratic, bezier, which are also used to construct the hit-test
  rects. Also introduced loopback routing for all styles. Better port snapping
  for temporary connections.

## 0.8.2

- **FIX**: respecting render order when detecting events, esp. around ports and
  nodes that are overlapping.
- **FEAT**: add debug visualization for spatial index and tracking systems.
- **FEAT**: migrate layout logic to hit testing, remove
  `NodeFlowLayoutDelegate`.
- **FEAT**: migrate layout logic to hit testing, remove
  `NodeFlowLayoutDelegate`.
- **FEAT**: centralize interaction handling via hit testing, remove redundant
  node event callbacks.

## 0.8.1

- **FIX**: respecting render order when detecting events, esp. around ports and
  nodes that are overlapping.
- **FEAT**: migrate layout logic to hit testing, remove
  `NodeFlowLayoutDelegate`.
- **FEAT**: centralize interaction handling via hit testing, remove redundant
  node event callbacks.

## 0.8.0

- **FEAT**: added spatial indexing, added a custom size observer to avoid side
  effects in build method.

## 0.7.2

- **FEAT**: Restructure the grid components and annotations by splitting into
  separate files.

## 0.7.1

- **FEAT**: Add startGap and endGap support for connections.

## 0.7.0

- **FEAT**: Add animation support for temporary connections and update
  connection rendering logic, Add configurable gaps, colors, and borders for
  connection endpoints.

## 0.6.0

- **FEAT**: Refactor port positioning and size cascade system.

## 0.5.1

- **FEAT**: readme update to include section on theming.

## 0.5.0

- Theming refactoring
- **FEAT**: Sub-Themes with more control on theme overrides

## 0.4.0

- **FEAT**: moving from PortShapes to MarkerShapes! This is a BREAKING change.
  Also generalizing the square marker shape to be rectangle.

## 0.3.18

- **FEAT**: updated readme about structured events.

## 0.3.17

- **FEAT**: adding centering of viewport.

## 0.3.16

- **FEAT**: optimizing the widget tree by removing an unnecessary Container.

## 0.3.15+1

- **FIX**: update examples to indicate the consolidated step styles.

## 0.3.15

- **FEAT**: consolidating the step and smooth step connection styles.

## 0.3.14

- **FEAT**: added the ability to check for input/output port when rendering a
  port shape.

## 0.3.13

- **FEAT**: optimizing step hit area calculation.

## 0.3.12

- **FEAT**: tap and double tap handling at node editor level with custom hit
  testing.

## 0.3.11

- **FIX**: updated readme.
- **FIX**: updated icons on demo, adjusted padding in node.
- **FEAT**: refactoring and renaming across the board for better semantic
  naming.
- **FEAT**: refactoring and renaming across the board for better semantic
  naming.
- **FEAT**: using LabelTheme.light/dark directly.

## 0.3.10

- **FIX**: updated icons on demo, adjusted padding in node.
- **BREAKING**: renamed types for better semantic clarity:
  - `HitType` → `HitTarget`
  - `AnnotationDependencyType` → `AnnotationBehavior`
  - `MinimapPosition` → `CornerPosition`
  - `ShapeOrientation` → `ShapeDirection`
  - `PathParameters` → `ConnectionPathParameters`
- **FEAT**: using LabelTheme.light/dark static constants directly in
  NodeFlowTheme.

## 0.3.9

- **FEAT**: introduced Port Labels, which help in setting labels for ports on
  the inside of the port. The labels are positioned as per the port position
  with a customizable label offset, TextStyle and visibility threshold based on
  the zoom-level of canvas.

## 0.3.8

- **FEAT**: introduced ConnectionEffects, Particles with static constants for
  easy usage.

## 0.3.7+1

- **FIX**: simplified use of shape orientation.

## 0.3.7

- **FEAT**: Making PortShape into a class hierarchy and consolidating the end
  point shape into a PortShape. Also fixed the autopan related properties since
  they are currently not supported.

## 0.3.6

- **FEAT**: GridStyle is now an abstract class with subclasses that provide
  lines, hierarchical, dots, cross and none styles!

## 0.3.5

- **FEAT**: using a CustomPainter to ensure the Text Metrics are accurate for
  the connection labels.

## 0.3.4

- **FEAT**: leveraging path cache to avoid computing the paths again for
  connections.

## 0.3.3

- **FEAT**: multiple connection labels.

## 0.3.2+1

- **FIX**: adding connection effects gif and fixing a typo.

## 0.3.2

- **FEAT**: adding connection effects to readme.

## 0.3.1

- **FEAT**: renaming pulseSpeed => speed for consistency.

## 0.3.0

- **FEAT**: BREAKING CHANGE: `connectionStyle` moved from `NodeFlowTheme` to
  `ConnectionTheme`.
- Removed lots of unused properties from various themes.
- Introduced a connection animation effect at the `ConnectionTheme` level, which
  can be overridden by the connection itself.
- **NOTE**: We'll be doing a lot of API cleanups, consolidation, renaming, and
  refactoring. So please do expect some breaking changes. We'll be documenting
  this in the changelog in the coming versions.

## 0.2.15

- **FEAT**: for some effects the paths were drawn on top of the effect, fixed
  now.

## 0.2.14

- **FEAT**: better effects with particle painter, glowing gradients.

## 0.2.13+1

- **FIX**: analysis issues.

## 0.2.13

- **FEAT**: connection effects.

## 0.2.12+1

- **FIX**: analysis issues resolved.

## 0.2.12

- **FEAT**: adding attribution and fixing demos for mobile viewports.

## 0.2.11

- **FEAT**: adding shape support.

## 0.2.10+1

- **FIX**: analysis issues.

## 0.2.10

- **FEAT**: better keyboard handling.

## 0.2.9+1

- **FIX**: adding docs for the library and rearranging files.

## 0.2.9

- **FIX**: removing screenshots from publishing.
- **FEAT**: making node size observable.
- **FEAT**: added support to control deletion of nodes.

## 0.2.8

- **FEAT**: making node size observable.
- **FEAT**: added support to control deletion of nodes.

## 0.2.7

- **FEAT**: making it work with wasm, moving json files into assets, fixing
  number deserialization on macos.

## 0.2.6+4

- **FIX**: bringing the assets back ... as pub.dev expects it to be inside the
  archive.

## 0.2.6+3

- **FIX**: setting proper example.

## 0.2.6+2

- **FIX**: updated readme with proper code formatting, added assets to pubignore
  to reduce package size.

## 0.2.6+1

- **FIX**: add example and update image links in readme.

## 0.2.6

- Fixed alignment and distribution of nodes

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
