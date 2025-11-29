// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'connection_endpoint.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ConnectionEndPoint _$ConnectionEndPointFromJson(Map<String, dynamic> json) =>
    ConnectionEndPoint(
      shape: const MarkerShapeConverter().fromJson(
        json['shape'] as Map<String, dynamic>,
      ),
      size: (json['size'] as num).toDouble(),
    );

Map<String, dynamic> _$ConnectionEndPointToJson(ConnectionEndPoint instance) =>
    <String, dynamic>{
      'shape': const MarkerShapeConverter().toJson(instance.shape),
      'size': instance.size,
    };
