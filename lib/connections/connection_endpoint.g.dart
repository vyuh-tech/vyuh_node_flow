// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'connection_endpoint.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ConnectionEndPoint _$ConnectionEndPointFromJson(Map json) => ConnectionEndPoint(
  shape: $enumDecode(_$EndpointShapeEnumMap, json['shape']),
  size: (json['size'] as num).toDouble(),
);

Map<String, dynamic> _$ConnectionEndPointToJson(ConnectionEndPoint instance) =>
    <String, dynamic>{
      'shape': _$EndpointShapeEnumMap[instance.shape]!,
      'size': instance.size,
    };

const _$EndpointShapeEnumMap = {
  EndpointShape.capsuleHalf: 'capsuleHalf',
  EndpointShape.circle: 'circle',
  EndpointShape.square: 'square',
  EndpointShape.diamond: 'diamond',
  EndpointShape.triangle: 'triangle',
  EndpointShape.none: 'none',
};
