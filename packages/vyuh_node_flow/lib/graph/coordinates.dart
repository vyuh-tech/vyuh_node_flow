import 'dart:ui';

/// Extension type representing an absolute position in graph/world coordinate space.
///
/// Graph coordinates are the logical coordinate space where nodes are positioned.
/// They are independent of screen size and zoom level. Use [GraphPosition] to
/// clearly indicate that a position is in graph space, not screen space.
///
/// This provides compile-time type safety to prevent accidentally passing
/// screen coordinates where graph coordinates are expected.
///
/// Example:
/// ```dart
/// // Create a graph position
/// final nodePosition = GraphPosition.fromXY(100, 200);
///
/// // Access components
/// print(nodePosition.dx); // 100
/// print(nodePosition.dy); // 200
///
/// // Arithmetic operations
/// final moved = nodePosition + GraphPosition.fromXY(50, 50);
///
/// // Convert to raw Offset when needed
/// final raw = nodePosition.offset; // Offset(100, 200)
/// ```
extension type const GraphPosition(Offset offset) {
  /// Creates a [GraphPosition] from x and y components.
  GraphPosition.fromXY(double dx, double dy) : this(Offset(dx, dy));

  /// The zero position in graph space.
  static const zero = GraphPosition(Offset.zero);

  /// The x component in graph coordinates.
  double get dx => offset.dx;

  /// The y component in graph coordinates.
  double get dy => offset.dy;

  /// Returns true if both components are finite.
  bool get isFinite => offset.isFinite;

  /// Adds two graph positions together.
  GraphPosition operator +(GraphPosition other) =>
      GraphPosition(offset + other.offset);

  /// Subtracts one graph position from another.
  GraphPosition operator -(GraphPosition other) =>
      GraphPosition(offset - other.offset);

  /// Negates the position.
  GraphPosition operator -() => GraphPosition(-offset);

  /// Scales the position by a scalar value.
  GraphPosition operator *(double operand) => GraphPosition(offset * operand);

  /// Divides the position by a scalar value.
  GraphPosition operator /(double operand) => GraphPosition(offset / operand);

  /// Returns the distance from this position to [other].
  double distanceTo(GraphPosition other) => (offset - other.offset).distance;

  /// Returns the squared distance from this position to [other].
  double distanceSquaredTo(GraphPosition other) =>
      (offset - other.offset).distanceSquared;

  /// Linearly interpolates between two graph positions.
  static GraphPosition lerp(GraphPosition a, GraphPosition b, double t) =>
      GraphPosition(Offset.lerp(a.offset, b.offset, t)!);

  /// Returns a string representation for debugging.
  String toDebugString() =>
      'GraphPosition(${dx.toStringAsFixed(1)}, ${dy.toStringAsFixed(1)})';
}

/// Extension type representing an absolute position in screen coordinate space.
///
/// Screen coordinates are pixel positions on the display, affected by the
/// viewport's pan and zoom. Use [ScreenPosition] to clearly indicate that a
/// position is in screen space, not graph space.
///
/// This provides compile-time type safety to prevent accidentally passing
/// graph coordinates where screen coordinates are expected.
///
/// Example:
/// ```dart
/// // Create a screen position from a tap position
/// final tapPosition = ScreenPosition(details.localPosition);
///
/// // Convert to graph coordinates
/// final graphPos = viewport.toGraph(tapPosition);
/// ```
extension type const ScreenPosition(Offset offset) {
  /// Creates a [ScreenPosition] from x and y components.
  ScreenPosition.fromXY(double dx, double dy) : this(Offset(dx, dy));

  /// The zero position in screen space.
  static const zero = ScreenPosition(Offset.zero);

  /// The x component in screen pixels.
  double get dx => offset.dx;

  /// The y component in screen pixels.
  double get dy => offset.dy;

  /// Returns true if both components are finite.
  bool get isFinite => offset.isFinite;

  /// Adds two screen positions together.
  ScreenPosition operator +(ScreenPosition other) =>
      ScreenPosition(offset + other.offset);

  /// Subtracts one screen position from another.
  ScreenPosition operator -(ScreenPosition other) =>
      ScreenPosition(offset - other.offset);

  /// Negates the position.
  ScreenPosition operator -() => ScreenPosition(-offset);

  /// Scales the position by a scalar value.
  ScreenPosition operator *(double operand) => ScreenPosition(offset * operand);

  /// Divides the position by a scalar value.
  ScreenPosition operator /(double operand) => ScreenPosition(offset / operand);

  /// Returns a string representation for debugging.
  String toDebugString() =>
      'ScreenPosition(${dx.toStringAsFixed(1)}, ${dy.toStringAsFixed(1)})';
}

/// Extension type representing a delta/movement in graph coordinate space.
///
/// Unlike [GraphPosition] which represents an absolute position, [GraphOffset]
/// represents a change or movement amount. This distinction is important
/// because deltas don't include viewport translation, only scaling.
///
/// Example:
/// ```dart
/// // Convert a screen drag delta to graph delta
/// final screenDrag = ScreenOffset(details.delta);
/// final graphDrag = viewport.toGraphOffset(screenDrag);
///
/// // Apply the delta to move a node
/// node.position = node.position.translate(graphDrag);
/// ```
extension type const GraphOffset(Offset offset) {
  /// Creates a [GraphOffset] from dx and dy components.
  GraphOffset.fromXY(double dx, double dy) : this(Offset(dx, dy));

  /// The zero offset.
  static const zero = GraphOffset(Offset.zero);

  /// The x component of the offset.
  double get dx => offset.dx;

  /// The y component of the offset.
  double get dy => offset.dy;

  /// Returns true if both components are finite.
  bool get isFinite => offset.isFinite;

  /// The magnitude of the offset.
  double get distance => offset.distance;

  /// Adds two graph offsets together.
  GraphOffset operator +(GraphOffset other) =>
      GraphOffset(offset + other.offset);

  /// Subtracts one graph offset from another.
  GraphOffset operator -(GraphOffset other) =>
      GraphOffset(offset - other.offset);

  /// Negates the offset.
  GraphOffset operator -() => GraphOffset(-offset);

  /// Scales the offset by a scalar value.
  GraphOffset operator *(double operand) => GraphOffset(offset * operand);

  /// Divides the offset by a scalar value.
  GraphOffset operator /(double operand) => GraphOffset(offset / operand);

  /// Returns a string representation for debugging.
  String toDebugString() =>
      'GraphOffset(${dx.toStringAsFixed(1)}, ${dy.toStringAsFixed(1)})';
}

/// Extension type representing a delta/movement in screen coordinate space.
///
/// Represents a change in screen position (pixels), typically from gesture
/// callbacks like `onPanUpdate`.
extension type const ScreenOffset(Offset offset) {
  /// Creates a [ScreenOffset] from dx and dy components.
  ScreenOffset.fromXY(double dx, double dy) : this(Offset(dx, dy));

  /// The zero offset.
  static const zero = ScreenOffset(Offset.zero);

  /// The x component of the offset in pixels.
  double get dx => offset.dx;

  /// The y component of the offset in pixels.
  double get dy => offset.dy;

  /// Returns true if both components are finite.
  bool get isFinite => offset.isFinite;

  /// The magnitude of the offset in pixels.
  double get distance => offset.distance;

  /// Adds two screen offsets together.
  ScreenOffset operator +(ScreenOffset other) =>
      ScreenOffset(offset + other.offset);

  /// Subtracts one screen offset from another.
  ScreenOffset operator -(ScreenOffset other) =>
      ScreenOffset(offset - other.offset);

  /// Negates the offset.
  ScreenOffset operator -() => ScreenOffset(-offset);

  /// Scales the offset by a scalar value.
  ScreenOffset operator *(double operand) => ScreenOffset(offset * operand);

  /// Divides the offset by a scalar value.
  ScreenOffset operator /(double operand) => ScreenOffset(offset / operand);

  /// Returns a string representation for debugging.
  String toDebugString() =>
      'ScreenOffset(${dx.toStringAsFixed(1)}, ${dy.toStringAsFixed(1)})';
}

/// Extension methods for applying [GraphOffset] to [GraphPosition].
extension GraphPositionOffsetExtension on GraphPosition {
  /// Applies an offset to this position, returning a new position.
  GraphPosition translate(GraphOffset delta) =>
      GraphPosition(offset + delta.offset);
}

/// Extension methods for applying [ScreenOffset] to [ScreenPosition].
extension ScreenPositionOffsetExtension on ScreenPosition {
  /// Applies an offset to this position, returning a new position.
  ScreenPosition translate(ScreenOffset delta) =>
      ScreenPosition(offset + delta.offset);
}

/// Extension type representing a rectangle in graph/world coordinate space.
///
/// Use [GraphRect] to clearly indicate that a rectangle's position and size
/// are in graph coordinates, not screen coordinates.
///
/// Example:
/// ```dart
/// // Create a graph rect for a node's bounds
/// final nodeBounds = GraphRect(Rect.fromLTWH(100, 100, 200, 150));
///
/// // Check if a point is inside
/// if (nodeBounds.contains(GraphPosition.fromXY(150, 125))) {
///   print('Point is inside the node');
/// }
/// ```
extension type const GraphRect(Rect rect) {
  /// Creates a [GraphRect] from left, top, width, height values.
  GraphRect.fromLTWH(double left, double top, double width, double height)
    : this(Rect.fromLTWH(left, top, width, height));

  /// Creates a [GraphRect] from two corner points.
  GraphRect.fromPoints(GraphPosition a, GraphPosition b)
    : this(Rect.fromPoints(a.offset, b.offset));

  /// Creates a [GraphRect] centered at a point with given size.
  GraphRect.fromCenter({
    required GraphPosition center,
    required double width,
    required double height,
  }) : this(
         Rect.fromCenter(center: center.offset, width: width, height: height),
       );

  /// An empty rectangle at the origin.
  static const zero = GraphRect(Rect.zero);

  /// The position of the top-left corner.
  GraphPosition get topLeft => GraphPosition(rect.topLeft);

  /// The position of the top-right corner.
  GraphPosition get topRight => GraphPosition(rect.topRight);

  /// The position of the bottom-left corner.
  GraphPosition get bottomLeft => GraphPosition(rect.bottomLeft);

  /// The position of the bottom-right corner.
  GraphPosition get bottomRight => GraphPosition(rect.bottomRight);

  /// The position of the center point.
  GraphPosition get center => GraphPosition(rect.center);

  /// The x-coordinate of the left edge.
  double get left => rect.left;

  /// The y-coordinate of the top edge.
  double get top => rect.top;

  /// The x-coordinate of the right edge.
  double get right => rect.right;

  /// The y-coordinate of the bottom edge.
  double get bottom => rect.bottom;

  /// The width of the rectangle.
  double get width => rect.width;

  /// The height of the rectangle.
  double get height => rect.height;

  /// The size of the rectangle.
  Size get size => rect.size;

  /// Whether this rectangle has zero area.
  bool get isEmpty => rect.isEmpty;

  /// Whether this rectangle has non-zero area.
  bool get isFinite => rect.isFinite;

  /// Whether this rectangle contains the given point.
  bool contains(GraphPosition point) => rect.contains(point.offset);

  /// Whether this rectangle overlaps with another.
  bool overlaps(GraphRect other) => rect.overlaps(other.rect);

  /// Returns the intersection of two rectangles.
  GraphRect intersect(GraphRect other) => GraphRect(rect.intersect(other.rect));

  /// Returns the smallest rectangle containing both rectangles.
  GraphRect expandToInclude(GraphRect other) =>
      GraphRect(rect.expandToInclude(other.rect));

  /// Returns a rectangle expanded by the given delta on all sides.
  GraphRect inflate(double delta) => GraphRect(rect.inflate(delta));

  /// Returns a rectangle contracted by the given delta on all sides.
  GraphRect deflate(double delta) => GraphRect(rect.deflate(delta));

  /// Translates this rectangle by the given offset.
  GraphRect translate(GraphOffset delta) =>
      GraphRect(rect.translate(delta.dx, delta.dy));

  /// Shifts this rectangle by the given position offset.
  GraphRect shift(GraphPosition position) =>
      GraphRect(rect.shift(position.offset));

  /// Returns a string representation for debugging.
  String toDebugString() =>
      'GraphRect(${left.toStringAsFixed(1)}, ${top.toStringAsFixed(1)}, '
      '${width.toStringAsFixed(1)}, ${height.toStringAsFixed(1)})';
}

/// Extension type representing a rectangle in screen coordinate space.
///
/// Use [ScreenRect] to clearly indicate that a rectangle's position and size
/// are in screen pixels.
extension type const ScreenRect(Rect rect) {
  /// Creates a [ScreenRect] from left, top, width, height values.
  ScreenRect.fromLTWH(double left, double top, double width, double height)
    : this(Rect.fromLTWH(left, top, width, height));

  /// Creates a [ScreenRect] from two corner points.
  ScreenRect.fromPoints(ScreenPosition a, ScreenPosition b)
    : this(Rect.fromPoints(a.offset, b.offset));

  /// An empty rectangle at the origin.
  static const zero = ScreenRect(Rect.zero);

  /// The position of the top-left corner.
  ScreenPosition get topLeft => ScreenPosition(rect.topLeft);

  /// The position of the center point.
  ScreenPosition get center => ScreenPosition(rect.center);

  /// The x-coordinate of the left edge.
  double get left => rect.left;

  /// The y-coordinate of the top edge.
  double get top => rect.top;

  /// The x-coordinate of the right edge.
  double get right => rect.right;

  /// The y-coordinate of the bottom edge.
  double get bottom => rect.bottom;

  /// The width of the rectangle in pixels.
  double get width => rect.width;

  /// The height of the rectangle in pixels.
  double get height => rect.height;

  /// The size of the rectangle in pixels.
  Size get size => rect.size;

  /// Whether this rectangle contains the given point.
  bool contains(ScreenPosition point) => rect.contains(point.offset);

  /// Whether this rectangle overlaps with another.
  bool overlaps(ScreenRect other) => rect.overlaps(other.rect);

  /// Returns a string representation for debugging.
  String toDebugString() =>
      'ScreenRect(${left.toStringAsFixed(1)}, ${top.toStringAsFixed(1)}, '
      '${width.toStringAsFixed(1)}, ${height.toStringAsFixed(1)})';
}
