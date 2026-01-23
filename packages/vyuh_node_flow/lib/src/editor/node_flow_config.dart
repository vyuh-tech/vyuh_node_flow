import 'package:mobx/mobx.dart';

import '../plugins/autopan/auto_pan_plugin.dart';
import '../plugins/debug/debug_plugin.dart';
import '../plugins/lod/lod.dart';
import '../plugins/minimap/minimap_plugin.dart';
import '../plugins/node_flow_plugin.dart';
import '../plugins/plugin_registry.dart';
import '../plugins/snap/snap_plugin.dart';
import '../plugins/stats/stats_plugin.dart';
import 'snap_delegate.dart';

// Re-export DebugMode for convenience
export '../plugins/debug/debug_plugin.dart' show DebugMode;

/// Reactive configuration class for NodeFlow behavioral properties.
///
/// Visual properties like minimap appearance, colors, and styling are
/// configured through [NodeFlowTheme] and [MinimapTheme].
///
/// ## Plugin Configuration
///
/// Plugins are passed pre-configured. Built-in plugins are included
/// by default. Customize or add plugins via the [plugins] parameter:
///
/// ```dart
/// NodeFlowConfig(
///   plugins: [
///     MinimapPlugin(visible: true, interactive: true),
///     LodPlugin(enabled: false),
///     AutoPanPlugin(config: AutoPanConfig.fast),
///     DebugPlugin(mode: DebugMode.spatialIndex),
///     StatsPlugin(),
///   ],
/// );
/// ```
///
/// ## Default Plugins
///
/// If no plugins are provided, these defaults are used:
/// - [AutoPanPlugin] - autopan near edges (normal mode)
/// - [DebugPlugin] - debug overlays (disabled by default)
/// - [LodPlugin] - level of detail (disabled by default)
/// - [MinimapPlugin] - minimap overlay
/// - [SnapPlugin] - grid and alignment snapping (disabled by default)
/// - [StatsPlugin] - graph statistics (nodeCount, connectionCount, etc.)
///
/// ## Snapping
///
/// Snapping is configured through [SnapPlugin] with snap delegates:
///
/// ```dart
/// // Toggle snapping with 'N' key or programmatically
/// controller.snap?.toggle();
/// controller.snap?.enabled = true;
///
/// // Access grid snap settings
/// controller.snap?.gridSnapDelegate?.gridSize = 10.0;
///
/// // Configure in plugins
/// NodeFlowConfig(
///   plugins: [
///     SnapPlugin([
///       SnapLinesDelegate(),              // Alignment guides
///       GridSnapDelegate(gridSize: 10.0), // Grid snap fallback
///     ]),
///     // ... other plugins
///   ],
/// );
/// ```
class NodeFlowConfig {
  NodeFlowConfig({
    double portSnapDistance = 8.0,
    double minZoom = 0.5,
    double maxZoom = 2.0,
    bool scrollToZoom = true,
    this.showAttribution = true,
    List<NodeFlowPlugin>? plugins,
  }) : pluginRegistry = PluginRegistry(plugins ?? defaultPlugins()) {
    runInAction(() {
      this.portSnapDistance.value = portSnapDistance;
      this.minZoom.value = minZoom;
      this.maxZoom.value = maxZoom;
      this.scrollToZoom.value = scrollToZoom;
    });
  }

  /// Default plugins for a new config.
  ///
  /// Note: [SnapPlugin] is disabled by default and can be toggled
  /// with the 'N' key.
  static List<NodeFlowPlugin> defaultPlugins() {
    return [
      AutoPanPlugin(),
      DebugPlugin(),
      LodPlugin(),
      MinimapPlugin(),
      SnapPlugin([GridSnapDelegate(gridSize: 20.0)]),
      StatsPlugin(),
    ];
  }

  /// Registry of plugins.
  ///
  /// Plugins are attached when first accessed via the controller's
  /// getters (e.g., `controller.minimap`, `controller.autoPan`).
  final PluginRegistry pluginRegistry;

  /// Distance threshold for port snapping during connection
  final portSnapDistance = Observable<double>(8.0);

  /// Minimum allowed zoom level
  final minZoom = Observable<double>(0.5);

  /// Maximum allowed zoom level
  final maxZoom = Observable<double>(2.0);

  /// Whether trackpad scroll gestures should cause zooming.
  ///
  /// When `true`, scrolling on a trackpad zooms in/out.
  /// When `false`, trackpad scroll is treated as pan gestures.
  final scrollToZoom = Observable<bool>(true);

  /// Whether to show attribution label
  final bool showAttribution;

  /// Update multiple properties at once
  void update({
    double? portSnapDistance,
    double? minZoom,
    double? maxZoom,
    bool? scrollToZoom,
  }) {
    runInAction(() {
      if (portSnapDistance != null) {
        this.portSnapDistance.value = portSnapDistance;
      }
      if (minZoom != null) this.minZoom.value = minZoom;
      if (maxZoom != null) this.maxZoom.value = maxZoom;
      if (scrollToZoom != null) this.scrollToZoom.value = scrollToZoom;
    });
  }

  /// Default configuration factory
  static NodeFlowConfig get defaultConfig => NodeFlowConfig();

  /// Create a copy with different initial values
  NodeFlowConfig copyWith({
    double? portSnapDistance,
    double? minZoom,
    double? maxZoom,
    bool? scrollToZoom,
    bool? showAttribution,
  }) {
    return NodeFlowConfig(
      portSnapDistance: portSnapDistance ?? this.portSnapDistance.value,
      minZoom: minZoom ?? this.minZoom.value,
      maxZoom: maxZoom ?? this.maxZoom.value,
      scrollToZoom: scrollToZoom ?? this.scrollToZoom.value,
      showAttribution: showAttribution ?? this.showAttribution,
    );
  }
}
