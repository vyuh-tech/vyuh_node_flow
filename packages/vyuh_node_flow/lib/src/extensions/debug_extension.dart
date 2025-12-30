import 'package:mobx/mobx.dart';

import '../editor/controller/node_flow_controller.dart';
import 'events/events.dart';
import 'node_flow_extension.dart';

/// Debug visualization mode for NodeFlow.
///
/// Controls which debug overlays are displayed in the editor.
enum DebugMode {
  /// No debug visualizations shown.
  none,

  /// Show all debug visualizations (spatial index, autopan zones, etc.).
  all,

  /// Show only the spatial index grid visualization.
  ///
  /// Displays how the canvas is partitioned into cells for efficient
  /// spatial querying, including cell coordinates and object counts.
  spatialIndex,

  /// Show only the autopan zone visualization.
  ///
  /// Displays the edge zones where automatic panning is triggered
  /// during drag operations.
  autoPanZone;

  /// Whether any debug visualization is enabled.
  bool get isEnabled => this != DebugMode.none;

  /// Whether the spatial index debug layer should be shown.
  bool get showSpatialIndex =>
      this == DebugMode.all || this == DebugMode.spatialIndex;

  /// Whether the autopan zone debug layer should be shown.
  bool get showAutoPanZone =>
      this == DebugMode.all || this == DebugMode.autoPanZone;
}

/// Extension for managing debug visualization overlays.
///
/// Provides reactive state for controlling which debug layers are shown
/// in the node flow editor.
///
/// ## Usage
///
/// ```dart
/// // Configure via NodeFlowConfig
/// NodeFlowConfig(
///   extensions: [
///     DebugExtension(mode: DebugMode.spatialIndex),
///   ],
/// );
///
/// // Access via controller
/// controller.debug.isEnabled;        // true
/// controller.debug.showSpatialIndex; // true
/// controller.debug.showAutoPanZone;  // false
///
/// // Toggle at runtime
/// controller.debug.toggle();
///
/// // Set specific mode
/// controller.debug.setMode(DebugMode.all);
/// ```
class DebugExtension extends NodeFlowExtension<DebugMode> {
  /// Creates a debug extension.
  ///
  /// Defaults to [DebugMode.none] (no debug overlays).
  DebugExtension({DebugMode mode = DebugMode.none}) : _mode = Observable(mode);

  final Observable<DebugMode> _mode;

  @override
  String get id => 'debug';

  @override
  DebugMode get config => _mode.value;

  // ═══════════════════════════════════════════════════════════════════════════
  // State
  // ═══════════════════════════════════════════════════════════════════════════

  /// Current debug mode.
  DebugMode get mode => _mode.value;

  /// Whether any debug visualization is enabled.
  bool get isEnabled => _mode.value.isEnabled;

  /// Whether the spatial index debug layer should be shown.
  bool get showSpatialIndex => _mode.value.showSpatialIndex;

  /// Whether the autopan zone debug layer should be shown.
  bool get showAutoPanZone => _mode.value.showAutoPanZone;

  // ═══════════════════════════════════════════════════════════════════════════
  // Actions
  // ═══════════════════════════════════════════════════════════════════════════

  /// Sets the debug mode.
  void setMode(DebugMode mode) {
    runInAction(() => _mode.value = mode);
  }

  /// Toggles debug mode between none and all.
  void toggle() {
    runInAction(() {
      _mode.value = _mode.value == DebugMode.none
          ? DebugMode.all
          : DebugMode.none;
    });
  }

  /// Cycles through all debug modes in order:
  /// none -> all -> spatialIndex -> autoPanZone -> none
  void cycle() {
    runInAction(() {
      final modes = DebugMode.values;
      final currentIndex = modes.indexOf(_mode.value);
      final nextIndex = (currentIndex + 1) % modes.length;
      _mode.value = modes[nextIndex];
    });
  }

  /// Shows all debug visualizations.
  void showAll() => setMode(DebugMode.all);

  /// Hides all debug visualizations.
  void hide() => setMode(DebugMode.none);

  /// Shows only the spatial index visualization.
  void showOnlySpatialIndex() => setMode(DebugMode.spatialIndex);

  /// Shows only the autopan zone visualization.
  void showOnlyAutoPanZone() => setMode(DebugMode.autoPanZone);

  // ═══════════════════════════════════════════════════════════════════════════
  // NodeFlowExtension Implementation
  // ═══════════════════════════════════════════════════════════════════════════

  @override
  void attach(NodeFlowController controller) {
    // No-op - debug layers observe the extension state directly
  }

  @override
  void detach() {
    // No-op
  }

  @override
  void onEvent(GraphEvent event) {
    // No event handling needed
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// Controller Extension
// ═══════════════════════════════════════════════════════════════════════════

/// Dart extension providing access to the debug extension.
extension DebugExtensionAccess<T> on NodeFlowController<T> {
  /// Gets the debug extension.
  ///
  /// The extension must be registered in [NodeFlowConfig.extensions].
  /// Throws [AssertionError] if not found.
  DebugExtension get debug {
    var ext = getExtension<DebugExtension>();
    if (ext == null) {
      ext = config.extensionRegistry.get<DebugExtension>();
      assert(
        ext != null,
        'DebugExtension not found. Add it to NodeFlowConfig.extensions.',
      );
      addExtension(ext!);
    }
    return ext;
  }
}
