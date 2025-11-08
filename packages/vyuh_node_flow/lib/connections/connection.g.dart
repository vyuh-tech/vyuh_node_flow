// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'connection.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Connection _$ConnectionFromJson(Map<String, dynamic> json) => Connection(
  id: json['id'] as String,
  sourceNodeId: json['sourceNodeId'] as String,
  sourcePortId: json['sourcePortId'] as String,
  targetNodeId: json['targetNodeId'] as String,
  targetPortId: json['targetPortId'] as String,
  data: json['data'] as Map<String, dynamic>?,
  style: _connectionStyleFromJson(json['style']),
  startPoint: json['startPoint'] == null
      ? null
      : ConnectionEndPoint.fromJson(json['startPoint'] as Map<String, dynamic>),
  endPoint: json['endPoint'] == null
      ? null
      : ConnectionEndPoint.fromJson(json['endPoint'] as Map<String, dynamic>),
);

Map<String, dynamic> _$ConnectionToJson(Connection instance) =>
    <String, dynamic>{
      'id': instance.id,
      'sourceNodeId': instance.sourceNodeId,
      'sourcePortId': instance.sourcePortId,
      'targetNodeId': instance.targetNodeId,
      'targetPortId': instance.targetPortId,
      'data': instance.data,
      'style': _connectionStyleToJson(instance.style),
      'startPoint': instance.startPoint,
      'endPoint': instance.endPoint,
    };
