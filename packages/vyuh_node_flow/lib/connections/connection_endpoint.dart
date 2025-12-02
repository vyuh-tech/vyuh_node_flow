import 'package:json_annotation/json_annotation.dart';

import '../shared/json_converters.dart';
import '../shared/shapes/marker_shape.dart';
import '../shared/shapes/marker_shapes.dart';

part 'connection_endpoint.g.dart';

/// Defines the visual marker at the start or end of a connection.
///
/// A [ConnectionEndPoint] specifies the shape and size of decorative markers
/// (like arrows, circles, or diamonds) that appear at connection endpoints.
/// These markers help visually indicate the direction and termination points
/// of connections.
///
/// ## Common Use Cases
/// - Arrow heads to show data flow direction
/// - Circles or diamonds for aesthetic purposes
/// - No marker when a clean line is desired
///
/// ## Usage Example
/// ```dart
/// // Create a custom endpoint
/// const myEndpoint = ConnectionEndPoint(
///   shape: MarkerShapes.triangle,
///   size: 8.0,
/// );
///
/// // Use predefined endpoints
/// const arrowEnd = ConnectionEndPoint.triangle;
/// const circleEnd = ConnectionEndPoint.circle;
/// const noEnd = ConnectionEndPoint.none;
/// ```
///
/// See also:
/// - [MarkerShape] for available shapes
/// - [ConnectionTheme] for configuring default endpoints
/// - [Connection] for applying endpoints to connections
@JsonSerializable()
class ConnectionEndPoint {
  /// Creates a connection endpoint marker.
  ///
  /// Parameters:
  /// - [shape]: The geometric shape of the endpoint marker
  /// - [size]: The size of the marker in logical pixels
  const ConnectionEndPoint({required this.shape, required this.size});

  /// The geometric shape of the endpoint marker.
  @MarkerShapeConverter()
  final MarkerShape shape;

  /// The size of the marker in logical pixels.
  ///
  /// For most shapes, this represents the diameter or characteristic dimension.
  final double size;

  /// Creates a copy of this endpoint with optionally updated properties.
  ///
  /// Parameters:
  /// - [shape]: If provided, replaces the current shape
  /// - [size]: If provided, replaces the current size
  ///
  /// Returns: A new [ConnectionEndPoint] with the specified changes
  ConnectionEndPoint copyWith({MarkerShape? shape, double? size}) {
    return ConnectionEndPoint(
      shape: shape ?? this.shape,
      size: size ?? this.size,
    );
  }

  /// Creates a [ConnectionEndPoint] from a JSON map.
  factory ConnectionEndPoint.fromJson(Map<String, dynamic> json) =>
      _$ConnectionEndPointFromJson(json);

  /// Converts this endpoint to a JSON map.
  Map<String, dynamic> toJson() => _$ConnectionEndPointToJson(this);

  /// No endpoint marker (invisible).
  ///
  /// Use this when you want a clean connection line without any decorative markers.
  static const none = ConnectionEndPoint(shape: MarkerShapes.none, size: 0.0);

  /// Half-capsule endpoint marker with default size 5.0.
  ///
  /// This creates a rounded arrow-like appearance.
  static const capsuleHalf = ConnectionEndPoint(
    shape: MarkerShapes.capsuleHalf,
    size: 5.0,
  );

  /// Circular endpoint marker with default size 5.0.
  ///
  /// Creates a simple dot at the endpoint.
  static const circle = ConnectionEndPoint(
    shape: MarkerShapes.circle,
    size: 5.0,
  );

  /// Rectangle endpoint marker with default size 5.0.
  ///
  /// Creates a solid rectangle at the endpoint.
  static const rectangle = ConnectionEndPoint(
    shape: MarkerShapes.rectangle,
    size: 5.0,
  );

  /// Diamond endpoint marker with default size 5.0.
  ///
  /// Creates a diamond (45-degree rotated square) at the endpoint.
  static const diamond = ConnectionEndPoint(
    shape: MarkerShapes.diamond,
    size: 5.0,
  );

  /// Triangular endpoint marker with default size 5.0.
  ///
  /// Creates an arrow-head triangle at the endpoint, pointing in the
  /// direction of the connection.
  static const triangle = ConnectionEndPoint(
    shape: MarkerShapes.triangle,
    size: 5.0,
  );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ConnectionEndPoint &&
          runtimeType == other.runtimeType &&
          shape == other.shape &&
          size == other.size;

  @override
  int get hashCode => shape.hashCode ^ size.hashCode;

  @override
  String toString() => 'ConnectionEndPoint(shape: $shape, size: $size)';
}
