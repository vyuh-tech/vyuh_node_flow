/// Extension system - events, extensions, and built-in extensions.
///
/// ## Events
/// Events are organized by category in the `events/` subdirectory:
/// - Node events: [NodeAdded], [NodeRemoved], [NodeMoved], etc.
/// - Connection events: [ConnectionAdded], [ConnectionRemoved]
/// - Selection events: [SelectionChanged]
/// - Viewport events: [ViewportChanged]
/// - Drag events: [NodeDragStarted], [ConnectionDragStarted], etc.
/// - Hover events: [NodeHoverChanged], [PortHoverChanged], etc.
/// - Lifecycle events: [GraphCleared], [GraphLoaded]
/// - Batch events: [BatchStarted], [BatchEnded]
/// - LOD events: [LODLevelChanged]
///
/// ## Extension System
/// - [NodeFlowExtension] - Base class for extensions
/// - [ExtensionRegistry] - Registry for managing extensions
///
/// ## Built-in Extensions
/// - [AutoPanExtension] - Autopan near viewport edges
/// - [DebugExtension] - Debug overlay visualizations
/// - [LodExtension] - Level of Detail visibility based on zoom
/// - [MinimapExtension] - Minimap state and highlighting
/// - [StatsExtension] - Reactive graph statistics
library;

// Core extension interface and registry
export 'src/extensions/node_flow_extension.dart';
export 'src/extensions/extension_registry.dart';

// Events (organized by category)
export 'src/extensions/events/events.dart';

// Built-in extensions (each in its own subdirectory)
export 'src/extensions/autopan/auto_pan_extension.dart';
export 'src/extensions/debug/debug_extension.dart';
export 'src/extensions/lod/lod_extension.dart';
export 'src/extensions/minimap/minimap_extension.dart';
export 'src/extensions/stats/stats_extension.dart';
