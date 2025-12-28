import 'capsule_half_marker_shape.dart';
import 'circle_marker_shape.dart';
import 'diamond_marker_shape.dart';
import 'marker_shape.dart';
import 'none_marker_shape.dart';
import 'rectangle_marker_shape.dart';
import 'triangle_marker_shape.dart';

/// Predefined marker shape constants.
///
/// This class provides static constant instances of commonly used marker shapes.
/// Similar to Flutter's [Colors] or [Icons] classes, this offers a convenient
/// way to access standard shapes without needing to instantiate them.
///
/// Marker shapes can be used for both ports on nodes and endpoints on connections.
///
/// Example:
/// ```dart
/// Port(
///   id: 'my-port',
///   name: 'Output',
///   shape: MarkerShapes.circle,
/// )
///
/// ConnectionEndPoint(
///   shape: MarkerShapes.triangle,
///   size: 8.0,
/// )
/// ```
///
/// Available shapes:
/// - [none] - Invisible marker (functional but not visually rendered)
/// - [circle] - Circular marker (default, universal)
/// - [rectangle] - Rectangle marker (use Size.square for equal dimensions)
/// - [diamond] - Diamond-shaped marker (decisions, branching)
/// - [triangle] - Triangular marker (directional, arrow-like)
/// - [capsuleHalf] - Half-capsule marker (socket/plug metaphor)
final class MarkerShapes {
  MarkerShapes._(); // Private constructor to prevent instantiation

  /// Invisible marker shape. The marker is functional but not visually rendered.
  ///
  /// Best for:
  /// - Minimalist designs
  /// - When connections should appear to connect directly to nodes
  /// - Hidden functionality
  static const MarkerShape none = NoneMarkerShape();

  /// Circular marker shape. Universal and works in all contexts.
  ///
  /// Best for:
  /// - General purpose usage
  /// - Data flow diagrams
  /// - When no specific meaning is needed
  static const MarkerShape circle = CircleMarkerShape();

  /// Rectangle marker shape. Uses the provided Size directly.
  ///
  /// For square markers, use a port with equal width and height (e.g., `Size.square(10)`).
  ///
  /// Best for:
  /// - Control flow ports
  /// - Event triggers
  /// - Technical diagrams
  static const MarkerShape rectangle = RectangleMarkerShape();

  /// Diamond-shaped marker (rotated square). Excellent for conditional/decision points.
  ///
  /// Best for:
  /// - Conditional/decision ports
  /// - Branch points
  /// - Special connection types
  static const MarkerShape diamond = DiamondMarkerShape();

  /// Triangular marker shape.
  ///
  /// For ports: the tip points inward (into the node).
  /// For connection endpoints: the tip points outward (along the connection).
  ///
  /// Best for:
  /// - Directional data flow
  /// - Arrow-head markers
  /// - Signal paths
  static const MarkerShape triangle = TriangleMarkerShape();

  /// Half-capsule (semi-circle) shape.
  ///
  /// The flat side is determined by the orientation parameter.
  ///
  /// Best for:
  /// - Socket/plug metaphors
  /// - Interface connection points
  /// - Hardware connection diagrams
  static const MarkerShape capsuleHalf = CapsuleHalfMarkerShape();
}
