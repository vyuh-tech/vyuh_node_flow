// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'connection_label.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ConnectionLabel _$ConnectionLabelFromJson(Map<String, dynamic> json) =>
    ConnectionLabel(
      text: json['text'] as String,
      anchor: (json['anchor'] as num?)?.toDouble() ?? 0.5,
      offset: (json['offset'] as num?)?.toDouble() ?? 0.0,
      id: json['id'] as String?,
    );

Map<String, dynamic> _$ConnectionLabelToJson(ConnectionLabel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'text': instance.text,
      'anchor': instance.anchor,
      'offset': instance.offset,
    };
