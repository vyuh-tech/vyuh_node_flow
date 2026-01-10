/// Defines how the node flow canvas behaves.
///
/// Each behavior mode has specific capabilities that determine what
/// interactions are allowed. Uses consolidated CRUD properties that
/// apply to all elements (nodes, ports, connections):
/// - Create: Add new items
/// - Read: Always allowed (viewing)
/// - Update: Modify existing items (edit labels, etc.)
/// - Delete: Remove items
///
/// Plus viewport/interaction controls:
/// - Drag: Move nodes
/// - Select: Select elements
/// - Pan: Pan the viewport
/// - Zoom: Zoom the viewport
///
/// Example:
/// ```dart
/// final behavior = NodeFlowBehavior.preview;
/// if (behavior.canDrag) {
///   // Allow dragging nodes
/// }
/// ```
enum NodeFlowBehavior {
  /// Full editing mode - create, modify, delete everything.
  ///
  /// Use this for the main editor interface where users design graphs.
  design(
    canCreate: true,
    canUpdate: true,
    canDelete: true,
    canDrag: true,
    canSelect: true,
    canPan: true,
    canZoom: true,
  ),

  /// Preview mode - navigate and rearrange, but no structural changes.
  ///
  /// Use this for reviewing graphs where layout adjustments are allowed
  /// but the graph structure cannot be modified.
  /// Ideal for run/debug modes where you want to see execution state.
  preview(
    canCreate: false,
    canUpdate: false,
    canDelete: false,
    canDrag: true,
    canSelect: true,
    canPan: true,
    canZoom: true,
  ),

  /// Inspect mode - view and select, but no modifications or rearrangement.
  ///
  /// Use this for runtime inspection where you want to select nodes to view
  /// their state but prevent any layout changes. Ideal for execution/run modes
  /// where the graph layout should remain stable.
  inspect(
    canCreate: false,
    canUpdate: false,
    canDelete: false,
    canDrag: false,
    canSelect: true,
    canPan: true,
    canZoom: true,
  ),

  /// Presentation mode - display only, no interaction.
  ///
  /// Use this for embedded displays, thumbnails, or presentation contexts
  /// where the graph should be completely non-interactive.
  present(
    canCreate: false,
    canUpdate: false,
    canDelete: false,
    canDrag: false,
    canSelect: false,
    canPan: false,
    canZoom: false,
  );

  const NodeFlowBehavior({
    required this.canCreate,
    required this.canUpdate,
    required this.canDelete,
    required this.canDrag,
    required this.canSelect,
    required this.canPan,
    required this.canZoom,
  });

  // ─────────────────────────────────────────────────────────────────────────
  // CRUD Operations (apply to all elements)
  // ─────────────────────────────────────────────────────────────────────────

  /// Whether new elements can be created (nodes, connections).
  final bool canCreate;

  /// Whether elements can be updated (edit labels, waypoints, etc.).
  final bool canUpdate;

  /// Whether elements can be deleted.
  final bool canDelete;

  // ─────────────────────────────────────────────────────────────────────────
  // Interaction
  // ─────────────────────────────────────────────────────────────────────────

  /// Whether elements can be dragged to new positions.
  final bool canDrag;

  /// Whether elements can be selected.
  final bool canSelect;

  /// Whether the viewport can be panned.
  final bool canPan;

  /// Whether the viewport can be zoomed.
  final bool canZoom;

  // ─────────────────────────────────────────────────────────────────────────
  // Computed Properties
  // ─────────────────────────────────────────────────────────────────────────

  /// Whether any modifications are allowed.
  bool get canModify => canCreate || canUpdate || canDelete;

  /// Whether any interaction is allowed.
  bool get isInteractive => canDrag || canSelect || canPan || canZoom;
}
