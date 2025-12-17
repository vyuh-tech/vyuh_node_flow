import 'dart:ui';

import '../nodes/node.dart';

/// Context provided to annotations during drag and node lifecycle operations.
///
/// This context allows annotations to interact with nodes during drag,
/// enabling behaviors like moving contained nodes when a group is dragged,
/// or refitting bounds when member nodes are deleted.
///
/// ## Example Usage in a Custom Annotation
///
/// ```dart
/// class MyGroupAnnotation extends Annotation {
///   Set<String>? _containedNodeIds;
///
///   @override
///   void onDragStart(AnnotationDragContext context) {
///     // Capture nodes inside this annotation at drag start
///     _containedNodeIds = context.findNodesInBounds(bounds);
///   }
///
///   @override
///   void onDragMove(Offset delta, AnnotationDragContext context) {
///     // Move the contained nodes along with this annotation
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
class AnnotationDragContext {
  const AnnotationDragContext({
    required this.moveNodes,
    required this.findNodesInBounds,
    required this.getNode,
  });

  /// Moves a set of nodes by the given delta.
  ///
  /// Call this during [Annotation.onDragMove] to move nodes along with
  /// the annotation. The delta should be in graph coordinates.
  final void Function(Set<String> nodeIds, Offset delta) moveNodes;

  /// Finds all node IDs whose bounds are completely contained within the given rect.
  ///
  /// Useful for determining which nodes are inside a group annotation
  /// at the start of a drag operation.
  final Set<String> Function(Rect bounds) findNodesInBounds;

  /// Looks up a node by ID.
  ///
  /// Returns `null` if the node doesn't exist. Useful for refitting
  /// group bounds after node changes.
  final Node? Function(String nodeId) getNode;
}
