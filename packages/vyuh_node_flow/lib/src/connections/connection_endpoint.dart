import 'package:flutter/material.dart';
import 'package:json_annotation/json_annotation.dart';

import '../shared/json_converters.dart';
import '../shared/shapes/marker_shape.dart';
import '../shared/shapes/marker_shapes.dart';

part 'connection_endpoint.g.dart';

/// Defines the visual marker at the start or end of a connection.
///
/// A [ConnectionEndPoint] specifies the shape, size, and colors of decorative markers
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
/// // Create a custom endpoint with colors
/// const myEndpoint = ConnectionEndPoint(
///   shape: MarkerShapes.triangle,
///   size: Size.square(8.0),
///   color: Colors.blue,
///   borderColor: Colors.blueAccent,
///   borderWidth: 1.0,
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
  /// - [color]: Optional fill color (falls back to connection/port theme color)
  /// - [borderColor]: Optional border color (falls back to port theme border color)
  /// - [borderWidth]: Optional border width (falls back to port theme border width)
  const ConnectionEndPoint({
    required this.shape,
    required this.size,
    this.color,
    this.borderColor,
    this.borderWidth,
  });

  /// The geometric shape of the endpoint marker.
  @MarkerShapeConverter()
  final MarkerShape shape;

  /// The size of the marker in logical pixels.
  ///
  /// For most shapes, this represents the width and height dimensions.
  /// Use [Size.square] for symmetric shapes where width equals height.
  @RequiredSizeConverter()
  final Size size;

  /// The fill color of the endpoint marker.
  ///
  /// If null, falls back to the connection theme's endpoint color.
  @ColorConverter()
  final Color? color;

  /// The border color of the endpoint marker.
  ///
  /// If null, falls back to the connection theme's endpoint border color.
  @ColorConverter()
  final Color? borderColor;

  /// The border width of the endpoint marker.
  ///
  /// If null, falls back to the connection theme's endpoint border width.
  final double? borderWidth;

  /// Creates a copy of this endpoint with optionally updated properties.
  ///
  /// Parameters:
  /// - [shape]: If provided, replaces the current shape
  /// - [size]: If provided, replaces the current size
  /// - [color]: If provided, replaces the current color
  /// - [borderColor]: If provided, replaces the current border color
  /// - [borderWidth]: If provided, replaces the current border width
  ///
  /// Returns: A new [ConnectionEndPoint] with the specified changes
  ConnectionEndPoint copyWith({
    MarkerShape? shape,
    Size? size,
    Color? color,
    Color? borderColor,
    double? borderWidth,
  }) {
    return ConnectionEndPoint(
      shape: shape ?? this.shape,
      size: size ?? this.size,
      color: color ?? this.color,
      borderColor: borderColor ?? this.borderColor,
      borderWidth: borderWidth ?? this.borderWidth,
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
  static const none = ConnectionEndPoint(
    shape: MarkerShapes.none,
    size: Size.zero,
  );

  /// Half-capsule endpoint marker with default size 5.0.
  ///
  /// This creates a rounded arrow-like appearance.
  static const capsuleHalf = ConnectionEndPoint(
    shape: MarkerShapes.capsuleHalf,
    size: Size.square(5.0),
  );

  /// Circular endpoint marker with default size 5.0.
  ///
  /// Creates a simple dot at the endpoint.
  static const circle = ConnectionEndPoint(
    shape: MarkerShapes.circle,
    size: Size.square(5.0),
  );

  /// Rectangle endpoint marker with default size 5.0.
  ///
  /// Creates a solid rectangle at the endpoint.
  static const rectangle = ConnectionEndPoint(
    shape: MarkerShapes.rectangle,
    size: Size.square(5.0),
  );

  /// Diamond endpoint marker with default size 5.0.
  ///
  /// Creates a diamond (45-degree rotated square) at the endpoint.
  static const diamond = ConnectionEndPoint(
    shape: MarkerShapes.diamond,
    size: Size.square(5.0),
  );

  /// Triangular endpoint marker with default size 5.0.
  ///
  /// Creates an arrow-head triangle at the endpoint, pointing in the
  /// direction of the connection.
  static const triangle = ConnectionEndPoint(
    shape: MarkerShapes.triangle,
    size: Size.square(5.0),
  );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ConnectionEndPoint &&
          runtimeType == other.runtimeType &&
          shape == other.shape &&
          size == other.size &&
          color == other.color &&
          borderColor == other.borderColor &&
          borderWidth == other.borderWidth;

  @override
  int get hashCode => Object.hash(shape, size, color, borderColor, borderWidth);

  @override
  String toString() =>
      'ConnectionEndPoint(shape: $shape, size: $size, color: $color, borderColor: $borderColor, borderWidth: $borderWidth)';
}
