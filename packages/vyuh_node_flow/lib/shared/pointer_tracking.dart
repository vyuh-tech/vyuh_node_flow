/// Defines how an element tracks the pointer during drag operations,
/// particularly when the pointer moves outside the editor bounds.
///
/// This enum controls the behavior of draggable elements (nodes, annotations,
/// connections) when the pointer exits the visible viewport area.
enum PointerTracking {
  /// Element tracks pointer position freely, even outside editor bounds.
  ///
  /// Use this for elements that should follow the pointer exactly,
  /// like connection endpoints during creation. The element position
  /// is always calculated from the current pointer position.
  ///
  /// Example: Connection dragging where the endpoint should always
  /// be directly under (or offset from) the pointer.
  free,

  /// Element anchors at the boundary edge when pointer exits bounds,
  /// then resyncs to pointer position when it returns.
  ///
  /// Use this for positioned elements like nodes and annotations that
  /// should stay visible in the viewport. When the pointer goes outside:
  /// 1. Element position freezes (doesn't follow pointer outside)
  /// 2. Autopan continues to reveal more canvas
  /// 3. When pointer re-enters, element snaps to match pointer position
  ///
  /// Example: Node dragging where the node should remain visible
  /// while autopan reveals the destination area.
  anchored,
}
