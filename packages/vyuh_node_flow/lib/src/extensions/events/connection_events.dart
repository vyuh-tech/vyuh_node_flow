part of 'graph_event.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Connection Events
// ─────────────────────────────────────────────────────────────────────────────

/// Emitted when a connection is added to the graph.
class ConnectionAdded extends GraphEvent {
  const ConnectionAdded(this.connection);

  /// The connection that was added.
  final Connection connection;

  @override
  String toString() => 'ConnectionAdded(${connection.id})';
}

/// Emitted when a connection is removed from the graph.
class ConnectionRemoved extends GraphEvent {
  const ConnectionRemoved(this.connection);

  /// The connection that was removed.
  /// Contains full state for undo capability.
  final Connection connection;

  @override
  String toString() => 'ConnectionRemoved(${connection.id})';
}
