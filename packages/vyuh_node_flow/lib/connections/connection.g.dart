// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'connection.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Connection _$ConnectionFromJson(Map json) => Connection(
  id: json['id'] as String,
  sourceNodeId: json['sourceNodeId'] as String,
  sourcePortId: json['sourcePortId'] as String,
  targetNodeId: json['targetNodeId'] as String,
  targetPortId: json['targetPortId'] as String,
  data: (json['data'] as Map?)?.map((k, e) => MapEntry(k as String, e)),
  style: _connectionStyleFromJson(json['style']),
  startPoint: json['startPoint'] == null
      ? null
      : ConnectionEndPoint.fromJson(
          Map<String, dynamic>.from(json['startPoint'] as Map),
        ),
  endPoint: json['endPoint'] == null
      ? null
      : ConnectionEndPoint.fromJson(
          Map<String, dynamic>.from(json['endPoint'] as Map),
        ),
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
      'startPoint': instance.startPoint?.toJson(),
      'endPoint': instance.endPoint?.toJson(),
    };
