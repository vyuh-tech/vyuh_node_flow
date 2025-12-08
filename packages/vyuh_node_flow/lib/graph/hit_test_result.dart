import 'dart:ui';

/// Hit test target types for different UI elements.
///
/// Used to determine what element the user is interacting with at a specific
/// position on the canvas.
enum HitTarget {
  /// A node was hit.
  node,

  /// A port (input or output) was hit.
  port,

  /// A connection line was hit.
  connection,

  /// An annotation (sticky note, group, marker) was hit.
  annotation,

  /// Empty canvas was hit (no elements).
  canvas,
}

/// Result of a hit test operation.
///
/// Contains information about what element (if any) was found at the tested
/// position.
class HitTestResult {
  const HitTestResult({
    this.nodeId,
    this.portId,
    this.connectionId,
    this.annotationId,
    this.isOutput,
    this.position,
    this.hitType = HitTarget.canvas,
  });

  /// The ID of the hit node (if [hitType] is [HitTarget.node] or [HitTarget.port]).
  final String? nodeId;

  /// The ID of the hit port (if [hitType] is [HitTarget.port]).
  final String? portId;

  /// The ID of the hit connection (if [hitType] is [HitTarget.connection]).
  final String? connectionId;

  /// The ID of the hit annotation (if [hitType] is [HitTarget.annotation]).
  final String? annotationId;

  /// Whether the hit port is an output port.
  ///
  /// `true` for output ports, `false` for input ports, `null` if not a port.
  final bool? isOutput;

  /// The position where the hit occurred in graph coordinates.
  final Offset? position;

  /// The type of element that was hit.
  final HitTarget hitType;

  /// Returns `true` if a node was hit.
  bool get isNode => hitType == HitTarget.node;

  /// Returns `true` if a port was hit.
  bool get isPort => hitType == HitTarget.port;

  /// Returns `true` if a connection was hit.
  bool get isConnection => hitType == HitTarget.connection;

  /// Returns `true` if an annotation was hit.
  bool get isAnnotation => hitType == HitTarget.annotation;

  /// Returns `true` if empty canvas was hit (no elements).
  bool get isCanvas => hitType == HitTarget.canvas;
}
