part of 'graph_event.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Viewport Events
// ─────────────────────────────────────────────────────────────────────────────

/// Emitted when the viewport changes (pan or zoom).
class ViewportChanged extends GraphEvent {
  const ViewportChanged(this.viewport, this.previousViewport);

  /// The current viewport state.
  final GraphViewport viewport;

  /// The previous viewport state (for undo capability).
  final GraphViewport previousViewport;

  @override
  String toString() => 'ViewportChanged(zoom: ${viewport.zoom})';
}
