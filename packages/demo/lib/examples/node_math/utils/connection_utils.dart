import 'package:vyuh_node_flow/vyuh_node_flow.dart';

import '../core/models.dart';

abstract final class MathConnectionUtils {
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

  static Set<String> getNodeIds(List<MathNodeData> nodes) {
    return {for (final node in nodes) node.id};
  }
}
