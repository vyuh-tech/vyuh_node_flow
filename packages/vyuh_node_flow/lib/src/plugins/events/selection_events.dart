part of 'graph_event.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Selection Events
// ─────────────────────────────────────────────────────────────────────────────

/// Emitted when the selection changes.
class SelectionChanged extends GraphEvent {
  const SelectionChanged({
    required this.selectedNodeIds,
    required this.selectedConnectionIds,
    required this.previousNodeIds,
    required this.previousConnectionIds,
  });

  /// Currently selected node IDs.
  final Set<String> selectedNodeIds;

  /// Currently selected connection IDs.
  final Set<String> selectedConnectionIds;

  /// Previously selected node IDs (for undo capability).
  final Set<String> previousNodeIds;

  /// Previously selected connection IDs (for undo capability).
  final Set<String> previousConnectionIds;

  @override
  String toString() =>
      'SelectionChanged(nodes: ${selectedNodeIds.length}, connections: ${selectedConnectionIds.length})';
}
