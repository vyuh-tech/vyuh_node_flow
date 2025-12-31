import 'package:flutter/material.dart';
import 'package:mobx/mobx.dart';

import '../../editor/controller/node_flow_controller.dart';
import '../events/events.dart';
import '../node_flow_extension.dart';

// ═══════════════════════════════════════════════════════════════════════════
// Debug Theme
// ═══════════════════════════════════════════════════════════════════════════

/// Theme configuration for debug visualizations.
///
/// Controls colors for spatial index grid, hit areas, and debug overlays.
///
/// Use [DebugTheme.light] or [DebugTheme.dark] for pre-configured themes.
class DebugTheme {
  const DebugTheme({
    this.color = const Color(0x20CC4444),
    this.borderColor = const Color(0xFF994444),
    this.activeColor = const Color(0x2000AA00),
    this.activeBorderColor = const Color(0xFF338833),
    this.labelColor = const Color(0xCCDDDDDD),
    this.labelBackgroundColor = const Color(0xDD1A1A1A),
    this.indicatorColor = const Color(0xFF00DD00),
    this.segmentColors = _defaultSegmentColors,
  });

  /// Default segment colors: red (connections), blue (nodes), green (ports)
  static const _defaultSegmentColors = [
    Color(0xFFCC4444), // connections (red)
    Color(0xFF4488FF), // nodes (blue)
    Color(0xFF44CC44), // ports (green)
  ];

  /// Fill color for inactive grid cells. Reddish tone, can be transparent.
  final Color color;

  /// Border color for inactive grid cells. Reddish tone, opaque.
  final Color borderColor;

  /// Fill color for active grid cells. Greenish tone, can be transparent.
  final Color activeColor;

  /// Border color for active grid cells. Greenish tone, opaque.
  final Color activeBorderColor;

  /// Text color for labels.
  final Color labelColor;

  /// Background color for labels.
  final Color labelBackgroundColor;

  /// Color for active indicators (mouse in cell, etc.). Opaque.
  final Color indicatorColor;

  /// Colors for spatial segments in Z-order (lowest to highest).
  ///
  /// Index 0: connections (drawn first, lowest Z)
  /// Index 1: nodes (drawn second)
  /// Index 2: ports (drawn last, highest Z)
  ///
  /// If fewer colors are provided, the last color is used for higher indices.
  final List<Color> segmentColors;

  /// Gets the segment color for a given index.
  ///
  /// If the index exceeds the available colors, returns the last color.
  Color getSegmentColor(int index) {
    if (segmentColors.isEmpty) return _defaultSegmentColors[0];
    return segmentColors[index.clamp(0, segmentColors.length - 1)];
  }

  /// Light theme variant for debug visualization.
  static const light = DebugTheme(
    color: Color(0x20FF6666),
    borderColor: Color(0xFFCC6666),
    activeColor: Color(0x1844DD44),
    activeBorderColor: Color(0xFF66BB66),
    labelColor: Color(0xFFFFFFFF),
    labelBackgroundColor: Color(0xCC333333),
    indicatorColor: Color(0xFF44DD44),
    segmentColors: [
      Color(0xFFDD6666), // connections (red)
      Color(0xFF6699FF), // nodes (blue)
      Color(0xFF66DD66), // ports (green)
    ],
  );

  /// Dark theme variant for debug visualization.
  static const dark = DebugTheme(
    color: Color(0x20FF6666),
    borderColor: Color(0xFFAA5555),
    activeColor: Color(0x2000FF00),
    activeBorderColor: Color(0xFF44AA44),
    labelColor: Color(0xCCDDDDDD),
    labelBackgroundColor: Color(0xDD1A1A1A),
    indicatorColor: Color(0xFF00FF00),
    segmentColors: [
      Color(0xFFCC4444), // connections (red)
      Color(0xFF4488FF), // nodes (blue)
      Color(0xFF44CC44), // ports (green)
    ],
  );

  DebugTheme copyWith({
    Color? color,
    Color? borderColor,
    Color? activeColor,
    Color? activeBorderColor,
    Color? labelColor,
    Color? labelBackgroundColor,
    Color? indicatorColor,
    List<Color>? segmentColors,
  }) {
    return DebugTheme(
      color: color ?? this.color,
      borderColor: borderColor ?? this.borderColor,
      activeColor: activeColor ?? this.activeColor,
      activeBorderColor: activeBorderColor ?? this.activeBorderColor,
      labelColor: labelColor ?? this.labelColor,
      labelBackgroundColor: labelBackgroundColor ?? this.labelBackgroundColor,
      indicatorColor: indicatorColor ?? this.indicatorColor,
      segmentColors: segmentColors ?? this.segmentColors,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! DebugTheme) return false;
    if (other.color != color ||
        other.borderColor != borderColor ||
        other.activeColor != activeColor ||
        other.activeBorderColor != activeBorderColor ||
        other.labelColor != labelColor ||
        other.labelBackgroundColor != labelBackgroundColor ||
        other.indicatorColor != indicatorColor) {
      return false;
    }
    // Compare segment colors list
    if (other.segmentColors.length != segmentColors.length) return false;
    for (int i = 0; i < segmentColors.length; i++) {
      if (other.segmentColors[i] != segmentColors[i]) return false;
    }
    return true;
  }

  @override
  int get hashCode => Object.hash(
    color,
    borderColor,
    activeColor,
    activeBorderColor,
    labelColor,
    labelBackgroundColor,
    indicatorColor,
    Object.hashAll(segmentColors),
  );
}

// ═══════════════════════════════════════════════════════════════════════════
// Debug Mode
// ═══════════════════════════════════════════════════════════════════════════

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
/// in the node flow editor, along with the theme for debug visualizations.
///
/// ## Usage
///
/// ```dart
/// // Configure via NodeFlowConfig
/// NodeFlowConfig(
///   extensions: [
///     DebugExtension(
///       mode: DebugMode.spatialIndex,
///       theme: DebugTheme.dark,
///     ),
///   ],
/// );
///
/// // Access via controller
/// controller.debug.isEnabled;        // true
/// controller.debug.showSpatialIndex; // true
/// controller.debug.showAutoPanZone;  // false
/// controller.debug.theme;            // DebugTheme.dark
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
  /// Defaults to [DebugMode.none] (no debug overlays) and [DebugTheme.light].
  DebugExtension({
    DebugMode mode = DebugMode.none,
    DebugTheme theme = DebugTheme.light,
  }) : _mode = Observable(mode),
       _theme = theme;

  final Observable<DebugMode> _mode;
  final DebugTheme _theme;

  @override
  String get id => 'debug';

  @override
  DebugMode get config => _mode.value;

  /// The visual theme for debug visualizations.
  ///
  /// This theme controls colors for spatial index grid, hit areas, and
  /// debug overlays.
  DebugTheme get theme => _theme;

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
extension DebugExtensionAccess<T> on NodeFlowController<T, dynamic> {
  /// Gets the debug extension, or null if not configured.
  ///
  /// Returns null if the extension is not registered, which effectively
  /// disables debug functionality. Use null-aware operators to safely
  /// access debug features.
  DebugExtension? get debug => resolveExtension<DebugExtension>();
}
