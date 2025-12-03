// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'connection_endpoint.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ConnectionEndPoint _$ConnectionEndPointFromJson(Map<String, dynamic> json) =>
    ConnectionEndPoint(
      shape: MarkerShape.fromJson(json['shape'] as Map<String, dynamic>),
      size: const RequiredSizeConverter().fromJson(
        json['size'] as Map<String, dynamic>,
      ),
      color: _$JsonConverterFromJson<int, Color>(
        json['color'],
        const ColorConverter().fromJson,
      ),
      borderColor: _$JsonConverterFromJson<int, Color>(
        json['borderColor'],
        const ColorConverter().fromJson,
      ),
      borderWidth: (json['borderWidth'] as num?)?.toDouble(),
    );

Map<String, dynamic> _$ConnectionEndPointToJson(ConnectionEndPoint instance) =>
    <String, dynamic>{
      'shape': instance.shape,
      'size': const RequiredSizeConverter().toJson(instance.size),
      'color': _$JsonConverterToJson<int, Color>(
        instance.color,
        const ColorConverter().toJson,
      ),
      'borderColor': _$JsonConverterToJson<int, Color>(
        instance.borderColor,
        const ColorConverter().toJson,
      ),
      'borderWidth': instance.borderWidth,
    };

Value? _$JsonConverterFromJson<Json, Value>(
  Object? json,
  Value? Function(Json json) fromJson,
) => json == null ? null : fromJson(json as Json);

Json? _$JsonConverterToJson<Json, Value>(
  Value? value,
  Json? Function(Value value) toJson,
) => value == null ? null : toJson(value);
