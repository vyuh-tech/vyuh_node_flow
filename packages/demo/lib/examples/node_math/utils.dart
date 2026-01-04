import 'package:vyuh_node_flow/vyuh_node_flow.dart';

import 'models.dart';

/// Shared formatting utilities for the math calculator.
abstract final class MathFormatters {
  /// Formats a number for display (integer if whole, otherwise 2 decimal places).
  static String formatNumber(double value) {
    if (value.isNaN || value.isInfinite) return '?';
    if (value == value.toInt()) {
      return value.toInt().toString();
    }
    return value.toStringAsFixed(2);
  }

  /// Formats a number for input field display (preserves full precision).
  static String formatForInput(double value) {
    if (value == value.toInt()) {
      return value.toInt().toString();
    }
    return value.toString();
  }
}

/// Shared connection utilities for the math calculator.
abstract final class MathConnectionUtils {
  /// Filters connections to only include valid ones (both nodes must exist).
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

  /// Creates a set of node IDs for fast lookup.
  static Set<String> getNodeIds(List<MathNodeData> nodes) {
    return {for (final node in nodes) node.id};
  }
}
