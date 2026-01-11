import 'package:vyuh_node_flow/vyuh_node_flow.dart';

import '../core/models.dart';

/// Connection filtering utilities shared between canvas and evaluator.
abstract final class MathConnectionUtils {
  /// Filters out orphaned connections (references to deleted nodes).
  ///
  /// Connections may reference nodes that have been deleted. This filters
  /// the connection list to only include valid connections where both
  /// source and target nodes still exist.
  static List<Connection> getValidConnections(
    List<MathNodeData> nodes,
    List<Connection> connections,
  ) {
    final nodeIds = {for (final node in nodes) node.id};
    return connections
        .where(
          (c) =>
              nodeIds.contains(c.sourceNodeId) &&
              nodeIds.contains(c.targetNodeId),
        )
        .toList();
  }

  /// Builds a set of node IDs for O(1) membership checks.
  static Set<String> getNodeIds(List<MathNodeData> nodes) {
    return {for (final node in nodes) node.id};
  }
}
