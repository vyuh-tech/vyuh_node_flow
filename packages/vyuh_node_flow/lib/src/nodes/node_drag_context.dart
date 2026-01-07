import 'dart:ui';

import 'node.dart';

/// Context provided to nodes during drag and lifecycle operations.
///
/// This context allows nodes (including [GroupNode] and [CommentNode]) to
/// interact with other nodes during drag, enabling behaviors like moving
/// contained nodes when a group is dragged, or refitting bounds when
/// member nodes are deleted.
///
/// ## Example Usage
///
/// ```dart
/// class MyGroupNode extends Node<GroupData> {
///   Set<String>? _containedNodeIds;
///
///   @override
///   void onDragStart(NodeDragContext context) {
///     // Capture nodes inside this group at drag start
///     _containedNodeIds = context.findNodesInBounds(getBounds());
///   }
///
///   @override
///   void onDragMove(Offset delta, NodeDragContext context) {
///     // Move the contained nodes along with this group
///     if (_containedNodeIds != null && _containedNodeIds!.isNotEmpty) {
///       context.moveNodes(_containedNodeIds!, delta);
///     }
///   }
///
///   @override
///   void onDragEnd() {
///     _containedNodeIds = null;
///   }
/// }
/// ```
class NodeDragContext<T> {
  const NodeDragContext({
    required this.moveNodes,
    required this.findNodesInBounds,
    required this.getNode,
    this.shouldSkipUpdates,
    this.selectedNodeIds = const {},
  });

  /// Moves a set of nodes by the given delta.
  ///
  /// Call this during [Node.onDragMove] to move nodes along with
  /// the current node. The delta should be in graph coordinates.
  final void Function(Set<String> nodeIds, Offset delta) moveNodes;

  /// Finds all node IDs whose bounds are completely contained within the given rect.
  ///
  /// Useful for determining which nodes are inside a group node
  /// at the start of a drag operation.
  final Set<String> Function(Rect bounds) findNodesInBounds;

  /// Looks up a node by ID.
  ///
  /// Returns `null` if the node doesn't exist. Useful for refitting
  /// group bounds after node changes.
  final Node<T>? Function(String nodeId) getNode;

  /// Returns true if updates should be skipped.
  ///
  /// This is used by groupable nodes to prevent recursive updates
  /// during batch operations like group drag moves.
  /// Optional - only needed for monitoring operations.
  final bool Function()? shouldSkipUpdates;

  /// The IDs of currently selected nodes.
  ///
  /// Used by group nodes to avoid double-moving nodes that are already
  /// being moved as part of the selection drag.
  final Set<String> selectedNodeIds;
}
