part of 'graph_event.dart';

// ─────────────────────────────────────────────────────────────────────────────
// LOD (Level of Detail) Events
// ─────────────────────────────────────────────────────────────────────────────

/// Emitted when the LOD visibility level changes.
///
/// This occurs when zooming crosses a threshold that changes the visibility
/// configuration (e.g., from minimal to standard, or standard to full).
class LODLevelChanged extends GraphEvent {
  const LODLevelChanged({
    required this.previousVisibility,
    required this.currentVisibility,
    required this.normalizedZoom,
  });

  /// The visibility configuration before the change.
  final DetailVisibility previousVisibility;

  /// The visibility configuration after the change.
  final DetailVisibility currentVisibility;

  /// The normalized zoom level (0.0 to 1.0) that triggered the change.
  final double normalizedZoom;

  @override
  String toString() =>
      'LODLevelChanged(zoom: ${normalizedZoom.toStringAsFixed(2)})';
}
