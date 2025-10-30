import 'package:flutter/material.dart';

import '../nodes/node.dart';

/// Custom layout delegate for positioning nodes efficiently
class NodeFlowLayoutDelegate<T> extends MultiChildLayoutDelegate {
  NodeFlowLayoutDelegate({required this.nodes});

  final List<Node<T>> nodes;
  final Map<String, Offset> _previousPositions = {};

  @override
  void performLayout(Size size) {
    // Layout each node at its position
    for (final node in nodes) {
      if (hasChild(node.id)) {
        final currentPosition = node.position.value;
        final previousPosition = _previousPositions[node.id];

        // Layout the child with loose constraints
        layoutChild(node.id, BoxConstraints.loose(size));

        // Only position child if it has moved or is new
        if (previousPosition != currentPosition) {
          positionChild(node.id, currentPosition);
          _previousPositions[node.id] = currentPosition;
        }
      }
    }

    // Clean up positions for removed nodes
    _previousPositions.removeWhere(
      (id, _) => !nodes.any((node) => node.id == id),
    );
  }

  @override
  bool shouldRelayout(NodeFlowLayoutDelegate<T> oldDelegate) {
    // Always relayout to handle position changes
    // The Observer in _buildNodesLayer will handle tracking position changes
    return true;
  }
}
