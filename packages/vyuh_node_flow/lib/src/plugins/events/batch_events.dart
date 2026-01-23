part of 'graph_event.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Batch Events
// ─────────────────────────────────────────────────────────────────────────────

/// Marks the start of a batch operation.
///
/// Extensions should accumulate events until [BatchEnded] is received,
/// then treat them as a single undoable operation.
///
/// Example batch reasons:
/// - "multi-node-move" - dragging multiple selected nodes
/// - "paste" - pasting multiple nodes/connections
/// - "delete-selection" - deleting multiple items
class BatchStarted extends GraphEvent {
  const BatchStarted(this.reason);

  /// A descriptive name for this batch operation.
  final String reason;

  @override
  String toString() => 'BatchStarted($reason)';
}

/// Marks the end of a batch operation.
///
/// Extensions should finalize the batch started by [BatchStarted].
class BatchEnded extends GraphEvent {
  const BatchEnded();

  @override
  String toString() => 'BatchEnded()';
}
