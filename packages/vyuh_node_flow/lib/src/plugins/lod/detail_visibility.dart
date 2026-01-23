/// Configuration that defines which visual elements should be rendered
/// at a given Level of Detail.
///
/// This class provides fine-grained control over which parts of the node flow
/// editor are visible. Use the factory presets ([minimal], [standard], [full])
/// for common configurations, or create custom configurations.
///
/// Example:
/// ```dart
/// // Use a preset
/// final visibility = DetailVisibility.minimal;
///
/// // Create a custom configuration
/// final custom = DetailVisibility(
///   showNodeContent: true,
///   showPorts: true,
///   showPortLabels: false,
///   showConnectionLines: true,
///   showConnectionLabels: false,
///   showConnectionEndpoints: false,
///   showResizeHandles: false,
/// );
/// ```
class DetailVisibility {
  /// Creates a visibility configuration with the specified settings.
  ///
  /// All parameters default to `true` (full visibility).
  const DetailVisibility({
    this.showNodeContent = true,
    this.showPorts = true,
    this.showPortLabels = true,
    this.showConnectionLines = true,
    this.showConnectionLabels = true,
    this.showConnectionEndpoints = true,
    this.showResizeHandles = true,
  });

  /// Whether to show node content (custom widgets inside nodes).
  ///
  /// When `false`, nodes render as simple colored shapes without their
  /// internal content, improving performance at low zoom levels.
  final bool showNodeContent;

  /// Whether to show port shapes on nodes.
  ///
  /// When `false`, port markers are not rendered, but connections
  /// may still be visible if [showConnectionLines] is `true`.
  final bool showPorts;

  /// Whether to show labels next to ports.
  ///
  /// This is typically hidden at lower zoom levels to reduce visual clutter.
  final bool showPortLabels;

  /// Whether to show connection lines between nodes.
  ///
  /// When `false`, connections are not rendered at all, which significantly
  /// improves performance when viewing large graphs from a distance.
  final bool showConnectionLines;

  /// Whether to show labels on connections.
  ///
  /// Connection labels include start, middle, and end labels defined
  /// on individual connections.
  final bool showConnectionLabels;

  /// Whether to show connection endpoint markers (start/end decorations).
  ///
  /// When `false`, connections render as simple lines without decorative
  /// endpoints like circles or arrows.
  final bool showConnectionEndpoints;

  /// Whether to show resize handles on selected nodes.
  ///
  /// Resize handles are typically only useful at higher zoom levels
  /// where precise interaction is possible.
  final bool showResizeHandles;

  /// Minimal visibility preset - shows only simple colored shapes.
  ///
  /// Use this when zoomed out to maximum distance where detail is
  /// not visible anyway. Provides the best performance for large graphs.
  ///
  /// Visible: Node shapes (colored rectangles/shapes), connection lines with endpoints
  /// Hidden: Content, ports, labels, resize handles
  static const DetailVisibility minimal = DetailVisibility(
    showNodeContent: false,
    showPorts: false,
    showPortLabels: false,
    showConnectionLines: true,
    showConnectionLabels: false,
    showConnectionEndpoints: true,
    showResizeHandles: false,
  );

  /// Standard visibility preset - shows nodes with ports and connections.
  ///
  /// Use this at medium zoom levels where you can see the structure
  /// but don't need fine details like labels.
  ///
  /// Visible: Node content, ports, connection lines, connection endpoints
  /// Hidden: Port labels, connection labels, resize handles
  static const DetailVisibility standard = DetailVisibility(
    showNodeContent: true,
    showPorts: false,
    showPortLabels: false,
    showConnectionLines: true,
    showConnectionLabels: false,
    showConnectionEndpoints: true,
    showResizeHandles: false,
  );

  /// Full visibility preset - shows everything.
  ///
  /// Use this at high zoom levels where all details are visible
  /// and the user may want to interact with fine controls.
  ///
  /// Visible: All elements
  static const DetailVisibility full = DetailVisibility();

  /// Creates a copy of this configuration with the specified overrides.
  DetailVisibility copyWith({
    bool? showNodeContent,
    bool? showPorts,
    bool? showPortLabels,
    bool? showConnectionLines,
    bool? showConnectionLabels,
    bool? showConnectionEndpoints,
    bool? showResizeHandles,
  }) {
    return DetailVisibility(
      showNodeContent: showNodeContent ?? this.showNodeContent,
      showPorts: showPorts ?? this.showPorts,
      showPortLabels: showPortLabels ?? this.showPortLabels,
      showConnectionLines: showConnectionLines ?? this.showConnectionLines,
      showConnectionLabels: showConnectionLabels ?? this.showConnectionLabels,
      showConnectionEndpoints:
          showConnectionEndpoints ?? this.showConnectionEndpoints,
      showResizeHandles: showResizeHandles ?? this.showResizeHandles,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is DetailVisibility &&
        other.showNodeContent == showNodeContent &&
        other.showPorts == showPorts &&
        other.showPortLabels == showPortLabels &&
        other.showConnectionLines == showConnectionLines &&
        other.showConnectionLabels == showConnectionLabels &&
        other.showConnectionEndpoints == showConnectionEndpoints &&
        other.showResizeHandles == showResizeHandles;
  }

  @override
  int get hashCode => Object.hash(
    showNodeContent,
    showPorts,
    showPortLabels,
    showConnectionLines,
    showConnectionLabels,
    showConnectionEndpoints,
    showResizeHandles,
  );

  @override
  String toString() =>
      'DetailVisibility('
      'showNodeContent: $showNodeContent, '
      'showPorts: $showPorts, '
      'showPortLabels: $showPortLabels, '
      'showConnectionLines: $showConnectionLines, '
      'showConnectionLabels: $showConnectionLabels, '
      'showConnectionEndpoints: $showConnectionEndpoints, '
      'showResizeHandles: $showResizeHandles)';
}
