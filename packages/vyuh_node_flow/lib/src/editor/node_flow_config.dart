import 'package:mobx/mobx.dart';

import '../extensions/autopan/auto_pan_extension.dart';
import '../extensions/debug/debug_extension.dart';
import '../extensions/extension_registry.dart';
import '../extensions/lod/lod.dart';
import '../extensions/minimap/minimap_extension.dart';
import '../extensions/node_flow_extension.dart';
import '../extensions/snap/snap_extension.dart';
import '../extensions/stats/stats_extension.dart';
import 'snap_delegate.dart';

// Re-export DebugMode for convenience
export '../extensions/debug/debug_extension.dart' show DebugMode;

/// Reactive configuration class for NodeFlow behavioral properties.
///
/// Visual properties like minimap appearance, colors, and styling are
/// configured through [NodeFlowTheme] and [MinimapTheme].
///
/// ## Extension Configuration
///
/// Extensions are passed pre-configured. Built-in extensions are included
/// by default. Customize or add extensions via the [extensions] parameter:
///
/// ```dart
/// NodeFlowConfig(
///   extensions: [
///     MinimapExtension(visible: true, interactive: true),
///     LodExtension(enabled: false),
///     AutoPanExtension(config: AutoPanConfig.fast),
///     DebugExtension(mode: DebugMode.spatialIndex),
///     StatsExtension(),
///   ],
/// );
/// ```
///
/// ## Default Extensions
///
/// If no extensions are provided, these defaults are used:
/// - [AutoPanExtension] - autopan near edges (normal mode)
/// - [DebugExtension] - debug overlays (disabled by default)
/// - [LodExtension] - level of detail (disabled by default)
/// - [MinimapExtension] - minimap overlay
/// - [SnapExtension] - grid and alignment snapping (disabled by default)
/// - [StatsExtension] - graph statistics (nodeCount, connectionCount, etc.)
///
/// ## Snapping
///
/// Snapping is configured through [SnapExtension] with snap delegates:
///
/// ```dart
/// // Toggle snapping with 'N' key or programmatically
/// controller.snapExtension?.toggle();
/// controller.snapExtension?.enabled = true;
///
/// // Access grid snap settings
/// controller.snapExtension?.gridSnapDelegate?.gridSize = 10.0;
///
/// // Configure in extensions
/// NodeFlowConfig(
///   extensions: [
///     SnapExtension([
///       SnapLinesDelegate(),              // Alignment guides
///       GridSnapDelegate(gridSize: 10.0), // Grid snap fallback
///     ]),
///     // ... other extensions
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
    List<NodeFlowExtension>? extensions,
  }) : extensionRegistry = ExtensionRegistry(
         extensions ?? defaultExtensions(),
       ) {
    runInAction(() {
      this.portSnapDistance.value = portSnapDistance;
      this.minZoom.value = minZoom;
      this.maxZoom.value = maxZoom;
      this.scrollToZoom.value = scrollToZoom;
    });
  }

  /// Default extensions for a new config.
  ///
  /// Note: [SnapExtension] is disabled by default and can be toggled
  /// with the 'N' key.
  static List<NodeFlowExtension> defaultExtensions() {
    return [
      AutoPanExtension(),
      DebugExtension(),
      LodExtension(),
      MinimapExtension(),
      SnapExtension([GridSnapDelegate(gridSize: 20.0)]),
      StatsExtension(),
    ];
  }

  /// Registry of extensions.
  ///
  /// Extensions are attached when first accessed via the controller's
  /// getters (e.g., `controller.minimap`, `controller.autoPan`).
  final ExtensionRegistry extensionRegistry;

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
