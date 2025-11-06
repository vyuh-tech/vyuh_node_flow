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
