/// Plugin system - events, plugins, and built-in plugins.
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
/// ## Plugin System
/// - [NodeFlowPlugin] - Base class for plugins
/// - [PluginRegistry] - Registry for managing plugins
///
/// ## Built-in Plugins
/// - [AutoPanPlugin] - Autopan near viewport edges
/// - [DebugPlugin] - Debug overlay visualizations
/// - [LodPlugin] - Level of Detail visibility based on zoom
/// - [MinimapPlugin] - Minimap state and highlighting
/// - [StatsPlugin] - Reactive graph statistics
library;

// Built-in plugins (each in its own subdirectory)
export 'src/plugins/autopan/auto_pan_plugin.dart';
export 'src/plugins/autopan/autopan_zone_debug_layer.dart';
export 'src/plugins/debug/debug_plugin.dart';
export 'src/plugins/debug/spatial_index_debug_layer.dart';
export 'src/plugins/debug/spatial_index_debug_painter.dart';
// Events (organized by category)
export 'src/plugins/events/events.dart';
export 'src/plugins/lod/detail_visibility.dart';
export 'src/plugins/lod/lod_plugin.dart';
export 'src/plugins/minimap/minimap_plugin.dart';
export 'src/plugins/minimap/minimap_theme.dart';
export 'src/plugins/minimap/node_flow_minimap.dart';
// Core plugin interface and registry
export 'src/plugins/node_flow_plugin.dart';
export 'src/plugins/plugin_registry.dart';
export 'src/plugins/snap/snap_plugin.dart';
export 'src/plugins/stats/stats_plugin.dart';
