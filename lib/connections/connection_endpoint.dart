import 'package:json_annotation/json_annotation.dart';

import 'connection_theme.dart';

part 'connection_endpoint.g.dart';

@JsonSerializable()
class ConnectionEndPoint {
  const ConnectionEndPoint({required this.shape, required this.size});

  final EndpointShape shape;
  final double size;

  ConnectionEndPoint copyWith({EndpointShape? shape, double? size}) {
    return ConnectionEndPoint(
      shape: shape ?? this.shape,
      size: size ?? this.size,
    );
  }

  factory ConnectionEndPoint.fromJson(Map<String, dynamic> json) =>
      _$ConnectionEndPointFromJson(json);

  Map<String, dynamic> toJson() => _$ConnectionEndPointToJson(this);

  static const none = ConnectionEndPoint(shape: EndpointShape.none, size: 0.0);

  static const capsuleHalf = ConnectionEndPoint(
    shape: EndpointShape.capsuleHalf,
    size: 5.0,
  );

  static const circle = ConnectionEndPoint(
    shape: EndpointShape.circle,
    size: 5.0,
  );

  static const square = ConnectionEndPoint(
    shape: EndpointShape.square,
    size: 5.0,
  );

  static const diamond = ConnectionEndPoint(
    shape: EndpointShape.diamond,
    size: 5.0,
  );

  static const triangle = ConnectionEndPoint(
    shape: EndpointShape.triangle,
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
