// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'connection.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Connection<C> _$ConnectionFromJson<C>(
  Map<String, dynamic> json,
  C Function(Object? json) fromJsonC,
) => Connection<C>(
  id: json['id'] as String,
  sourceNodeId: json['sourceNodeId'] as String,
  sourcePortId: json['sourcePortId'] as String,
  targetNodeId: json['targetNodeId'] as String,
  targetPortId: json['targetPortId'] as String,
  data: _$nullableGenericFromJson(json['data'], fromJsonC),
  style: _connectionStyleFromJson(json['style']),
  startGap: (json['startGap'] as num?)?.toDouble(),
  endGap: (json['endGap'] as num?)?.toDouble(),
  locked: json['locked'] as bool? ?? false,
);

Map<String, dynamic> _$ConnectionToJson<C>(
  Connection<C> instance,
  Object? Function(C value) toJsonC,
) => <String, dynamic>{
  'id': instance.id,
  'sourceNodeId': instance.sourceNodeId,
  'sourcePortId': instance.sourcePortId,
  'targetNodeId': instance.targetNodeId,
  'targetPortId': instance.targetPortId,
  'data': _$nullableGenericToJson(instance.data, toJsonC),
  'style': _connectionStyleToJson(instance.style),
  'startGap': instance.startGap,
  'endGap': instance.endGap,
  'locked': instance.locked,
};

T? _$nullableGenericFromJson<T>(
  Object? input,
  T Function(Object? json) fromJson,
) => input == null ? null : fromJson(input);

Object? _$nullableGenericToJson<T>(
  T? input,
  Object? Function(T value) toJson,
) => input == null ? null : toJson(input);
