/// Interface that defines the contract for node data objects.
///
/// All node data objects should implement this interface to support
/// core functionality like cloning, and can be extended in the future
/// for additional capabilities like validation, transformation, etc.
abstract interface class NodeData {
  /// Creates a deep copy of this node data object.
  ///
  /// The cloned object should be completely independent of the original,
  /// with no shared references to mutable objects.
  NodeData clone();
}
