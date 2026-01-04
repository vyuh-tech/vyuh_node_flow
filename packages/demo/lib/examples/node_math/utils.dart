/// Utility functions for the Node Math Calculator.
///
/// Provides shared formatting and connection filtering used across the module.
import 'package:vyuh_node_flow/vyuh_node_flow.dart';

import 'models.dart';

/// Number formatting utilities for display and input fields.
abstract final class MathFormatters {
  /// Formats a number for result display.
  ///
  /// - Returns "?" for NaN/Infinite values
  /// - Omits decimal for whole numbers (e.g., "42" not "42.00")
  /// - Shows 2 decimal places otherwise (e.g., "3.14")
  static String formatNumber(double value) {
    if (value.isNaN || value.isInfinite) return '?';
    if (value == value.toInt()) {
      return value.toInt().toString();
    }
    return value.toStringAsFixed(2);
  }

  /// Formats a number for text field editing.
  ///
  /// Preserves full precision to avoid losing decimal places during editing.
  static String formatForInput(double value) {
    if (value == value.toInt()) {
      return value.toInt().toString();
    }
    return value.toString();
  }
}

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
