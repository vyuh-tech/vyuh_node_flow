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
  startPoint: json['startPoint'] == null
      ? null
      : ConnectionEndPoint.fromJson(json['startPoint'] as Map<String, dynamic>),
  endPoint: json['endPoint'] == null
      ? null
      : ConnectionEndPoint.fromJson(json['endPoint'] as Map<String, dynamic>),
  startGap: (json['startGap'] as num?)?.toDouble(),
  endGap: (json['endGap'] as num?)?.toDouble(),
  locked: json['locked'] as bool? ?? false,
  color: _$JsonConverterFromJson<int, Color>(
    json['color'],
    const ColorConverter().fromJson,
  ),
  selectedColor: _$JsonConverterFromJson<int, Color>(
    json['selectedColor'],
    const ColorConverter().fromJson,
  ),
  strokeWidth: (json['strokeWidth'] as num?)?.toDouble(),
  selectedStrokeWidth: (json['selectedStrokeWidth'] as num?)?.toDouble(),
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
  'startPoint': instance.startPoint,
  'endPoint': instance.endPoint,
  'startGap': instance.startGap,
  'endGap': instance.endGap,
  'locked': instance.locked,
  'color': _$JsonConverterToJson<int, Color>(
    instance.color,
    const ColorConverter().toJson,
  ),
  'selectedColor': _$JsonConverterToJson<int, Color>(
    instance.selectedColor,
    const ColorConverter().toJson,
  ),
  'strokeWidth': instance.strokeWidth,
  'selectedStrokeWidth': instance.selectedStrokeWidth,
};

T? _$nullableGenericFromJson<T>(
  Object? input,
  T Function(Object? json) fromJson,
) => input == null ? null : fromJson(input);

Value? _$JsonConverterFromJson<Json, Value>(
  Object? json,
  Value? Function(Json json) fromJson,
) => json == null ? null : fromJson(json as Json);

Object? _$nullableGenericToJson<T>(
  T? input,
  Object? Function(T value) toJson,
) => input == null ? null : toJson(input);

Json? _$JsonConverterToJson<Json, Value>(
  Value? value,
  Json? Function(Value value) toJson,
) => value == null ? null : toJson(value);
