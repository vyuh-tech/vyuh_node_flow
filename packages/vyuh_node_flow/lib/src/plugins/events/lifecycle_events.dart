part of 'graph_event.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Graph Lifecycle Events
// ─────────────────────────────────────────────────────────────────────────────

/// Emitted when the graph is cleared.
class GraphCleared extends GraphEvent {
  const GraphCleared({
    required this.previousNodeCount,
    required this.previousConnectionCount,
  });

  /// The number of nodes before clearing.
  final int previousNodeCount;

  /// The number of connections before clearing.
  final int previousConnectionCount;

  @override
  String toString() =>
      'GraphCleared(nodes: $previousNodeCount, connections: $previousConnectionCount)';
}

/// Emitted when a graph is loaded (replacing current content).
class GraphLoaded extends GraphEvent {
  const GraphLoaded({required this.nodeCount, required this.connectionCount});

  /// The number of nodes in the loaded graph.
  final int nodeCount;

  /// The number of connections in the loaded graph.
  final int connectionCount;

  @override
  String toString() =>
      'GraphLoaded(nodes: $nodeCount, connections: $connectionCount)';
}
