import 'capsule_half_port_shape.dart';
import 'circle_port_shape.dart';
import 'diamond_port_shape.dart';
import 'none_port_shape.dart';
import 'port_shape.dart';
import 'square_port_shape.dart';
import 'triangle_port_shape.dart';

/// Predefined port shape constants.
///
/// This class provides static constant instances of commonly used port shapes.
/// Similar to Flutter's [Colors] or [Icons] classes, this offers a convenient
/// way to access standard shapes without needing to instantiate them.
///
/// Example:
/// ```dart
/// Port(
///   id: 'my-port',
///   name: 'Output',
///   shape: PortShapes.circle,
/// )
/// ```
///
/// Available shapes:
/// - [none] - Invisible port (functional but not visually rendered)
/// - [circle] - Circular port (default, universal)
/// - [square] - Square/rectangular port (technical, structured)
/// - [diamond] - Diamond-shaped port (decisions, branching)
/// - [triangle] - Triangular port (directional, points toward port position)
/// - [capsuleHalf] - Half-capsule port (socket/plug metaphor)
final class PortShapes {
  PortShapes._(); // Private constructor to prevent instantiation

  /// Invisible port shape. The port is functional but not visually rendered.
  ///
  /// Best for:
  /// - Minimalist designs
  /// - When connections should appear to connect directly to nodes
  /// - Hidden functionality
  static const PortShape none = NonePortShape();

  /// Circular port shape. Universal and works in all contexts.
  ///
  /// Best for:
  /// - General purpose usage
  /// - Data flow diagrams
  /// - When no specific meaning is needed
  static const PortShape circle = CirclePortShape();

  /// Square/rectangular port shape. Good for technical and structured diagrams.
  ///
  /// Best for:
  /// - Control flow ports
  /// - Event triggers
  /// - Grid-aligned designs
  static const PortShape square = SquarePortShape();

  /// Diamond-shaped port (rotated square). Excellent for conditional/decision points.
  ///
  /// Best for:
  /// - Conditional/decision ports
  /// - Branch points
  /// - Special connection types
  static const PortShape diamond = DiamondPortShape();

  /// Triangular port shape that points in the direction of the port position.
  ///
  /// The triangle automatically orients based on the port's position:
  /// - Right position: points right (▶)
  /// - Left position: points left (◀)
  /// - Top position: points up (▲)
  /// - Bottom position: points down (▼)
  ///
  /// Best for:
  /// - Directional data flow
  /// - Output ports
  /// - Signal paths
  static const PortShape triangle = TrianglePortShape();

  /// Half-capsule (semi-circle) shape that opens toward the connection direction.
  ///
  /// The opening direction matches the port position, suggesting a socket
  /// or plug connection metaphor.
  ///
  /// Best for:
  /// - Socket/plug metaphors
  /// - Interface connection points
  /// - Hardware connection diagrams
  static const PortShape capsuleHalf = CapsuleHalfPortShape();
}
