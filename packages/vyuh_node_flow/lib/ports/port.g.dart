// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'port.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Port _$PortFromJson(Map<String, dynamic> json) => Port(
  id: json['id'] as String,
  name: json['name'] as String,
  multiConnections: json['multiConnections'] as bool? ?? false,
  position:
      $enumDecodeNullable(_$PortPositionEnumMap, json['position']) ??
      PortPosition.left,
  offset: json['offset'] == null
      ? Offset.zero
      : const OffsetConverter().fromJson(
          json['offset'] as Map<String, dynamic>,
        ),
  type: $enumDecodeNullable(_$PortTypeEnumMap, json['type']) ?? PortType.both,
  shape: json['shape'] == null
      ? PortShapes.capsuleHalf
      : const PortShapeConverter().fromJson(
          json['shape'] as Map<String, dynamic>,
        ),
  size: (json['size'] as num?)?.toDouble() ?? 9.0,
  tooltip: json['tooltip'] as String?,
  isConnectable: json['isConnectable'] as bool? ?? true,
  maxConnections: (json['maxConnections'] as num?)?.toInt(),
  showLabel: json['showLabel'] as bool? ?? false,
);

Map<String, dynamic> _$PortToJson(Port instance) => <String, dynamic>{
  'id': instance.id,
  'name': instance.name,
  'multiConnections': instance.multiConnections,
  'position': _$PortPositionEnumMap[instance.position]!,
  'offset': const OffsetConverter().toJson(instance.offset),
  'type': _$PortTypeEnumMap[instance.type]!,
  'shape': const PortShapeConverter().toJson(instance.shape),
  'size': instance.size,
  'tooltip': instance.tooltip,
  'isConnectable': instance.isConnectable,
  'maxConnections': instance.maxConnections,
  'showLabel': instance.showLabel,
};

const _$PortPositionEnumMap = {
  PortPosition.left: 'left',
  PortPosition.right: 'right',
  PortPosition.top: 'top',
  PortPosition.bottom: 'bottom',
};

const _$PortTypeEnumMap = {
  PortType.source: 'source',
  PortType.target: 'target',
  PortType.both: 'both',
};
