/// Defines how an annotation responds to changes in dependent nodes.
///
/// Different dependency types enable different behaviors for annotations
/// that track or relate to nodes in the workflow.
enum AnnotationBehavior {
  /// Annotation follows node movements.
  ///
  /// The annotation automatically updates its position to track the center
  /// of its dependent nodes. Useful for badges, labels, or indicators that
  /// should stay with specific nodes.
  follow,

  /// Annotation surrounds/encompasses nodes.
  ///
  /// The annotation's bounds automatically expand to contain all dependent
  /// nodes. This is used by [GroupAnnotation] to create visual boundaries
  /// around node sets.
  surround,

  /// Annotation is linked but doesn't move automatically.
  ///
  /// The annotation maintains a relationship with nodes but doesn't update
  /// its position. Useful for connections or references that should persist
  /// but remain stationary.
  linked,
}

/// Represents a dependency relationship between an annotation and a node.
///
/// This class encapsulates the details of how an annotation relates to a
/// specific node, including the dependency type and optional metadata.
///
/// ## Example
///
/// ```dart
/// final dependency = AnnotationDependency(
///   nodeId: 'node-1',
///   type: AnnotationBehavior.follow,
///   metadata: {'offset': Offset(10, -20)},
/// );
/// ```
class AnnotationDependency {
  /// Creates an annotation dependency.
  ///
  /// ## Parameters
  /// - [nodeId]: The ID of the node this dependency references
  /// - [type]: The type of dependency behavior
  /// - [metadata]: Optional custom data for this dependency
  const AnnotationDependency({
    required this.nodeId,
    required this.type,
    this.metadata = const {},
  });

  /// The ID of the node this dependency references.
  final String nodeId;

  /// The type of dependency behavior (follow, surround, or linked).
  final AnnotationBehavior type;

  /// Optional custom metadata for this dependency.
  ///
  /// Use this to store additional data specific to this node relationship,
  /// such as custom offsets, priority, or behavioral flags.
  final Map<String, dynamic> metadata;
}
