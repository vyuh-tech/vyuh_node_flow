import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:json_annotation/json_annotation.dart';

import '../shared/json_converters.dart';

part 'port.g.dart';

enum PortType { source, target, both }

enum PortShape { capsuleHalf, circle, square, diamond, triangle }

@JsonSerializable()
class Port extends Equatable {
  const Port({
    required this.id,
    required this.name,
    this.multiConnections = false,
    this.position = PortPosition.left,
    this.offset = Offset.zero,
    this.type = PortType.both,
    this.shape = PortShape.capsuleHalf,
    this.size = 9.0,
    this.tooltip,
    this.isConnectable = true,
    this.maxConnections,
  });

  final String id;
  final String name;
  final bool multiConnections;
  final PortPosition position;
  @OffsetConverter()
  final Offset offset;
  final PortType type;
  final PortShape shape;
  final double size;
  final String? tooltip;
  final bool isConnectable;
  final int? maxConnections;

  bool get isSource => type == PortType.source || type == PortType.both;

  bool get isTarget => type == PortType.target || type == PortType.both;

  Port copyWith({
    String? id,
    String? name,
    bool? multiConnections,
    PortPosition? position,
    Offset? offset,
    PortType? type,
    PortShape? shape,
    double? size,
    IconData? icon,
    String? tooltip,
    bool? isConnectable,
    int? maxConnections,
  }) {
    return Port(
      id: id ?? this.id,
      name: name ?? this.name,
      multiConnections: multiConnections ?? this.multiConnections,
      position: position ?? this.position,
      offset: offset ?? this.offset,
      type: type ?? this.type,
      shape: shape ?? this.shape,
      size: size ?? this.size,
      tooltip: tooltip ?? this.tooltip,
      isConnectable: isConnectable ?? this.isConnectable,
      maxConnections: maxConnections ?? this.maxConnections,
    );
  }

  factory Port.fromJson(Map<String, dynamic> json) => _$PortFromJson(json);

  Map<String, dynamic> toJson() => _$PortToJson(this);

  @override
  List<Object?> get props => [
    id,
    name,
    multiConnections,
    position,
    offset,
    type,
    shape,
    size,
    tooltip,
    isConnectable,
    maxConnections,
  ];
}

enum PortPosition { left, right, top, bottom }
