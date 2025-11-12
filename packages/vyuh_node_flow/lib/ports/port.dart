import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:json_annotation/json_annotation.dart';

import '../shared/json_converters.dart';
import 'shapes/port_shape.dart';
import 'shapes/port_shapes.dart';

part 'port.g.dart';

/// Defines the directionality of a port in a node-based flow editor.
///
/// Ports can act as sources (output), targets (input), or both, determining
/// how connections can be made between nodes.
///
/// Example:
/// ```dart
/// // Create a source port (output only)
/// Port sourcePort = Port(
///   id: 'output-1',
///   name: 'Result',
///   type: PortType.source,
/// );
///
/// // Create a target port (input only)
/// Port targetPort = Port(
///   id: 'input-1',
///   name: 'Value',
///   type: PortType.target,
/// );
/// ```
enum PortType {
  /// Port can only emit connections (output port)
  source,

  /// Port can only receive connections (input port)
  target,

  /// Port can both emit and receive connections
  both,
}

/// Represents a connection point on a node in the flow editor.
///
/// A [Port] defines where and how connections can be made to a node. Each port
/// has a position, appearance, and behavior that determines how it interacts
/// with connections in the flow editor.
///
/// Ports can be configured as sources (outputs), targets (inputs), or both,
/// and support various customization options including:
/// - Visual appearance (shape, size, position)
/// - Connection behavior (single/multiple connections, max connections)
/// - Interactive states (hoverable, connectable)
///
/// Example:
/// ```dart
/// // Create a simple output port
/// final outputPort = Port(
///   id: 'output-1',
///   name: 'Result',
///   type: PortType.source,
///   position: PortPosition.right,
/// );
///
/// // Create an input port with multiple connections allowed
/// final inputPort = Port(
///   id: 'input-1',
///   name: 'Data',
///   type: PortType.target,
///   position: PortPosition.left,
///   multiConnections: true,
///   maxConnections: 5,
///   tooltip: 'Accepts up to 5 connections',
/// );
///
/// // Create a bidirectional port with custom styling
/// final bothPort = Port(
///   id: 'io-1',
///   name: 'I/O',
///   type: PortType.both,
///   position: PortPosition.top,
///   shape: PortShape.diamond,
///   size: 12.0,
///   offset: Offset(10, 0),
/// );
/// ```
@JsonSerializable()
class Port extends Equatable {
  /// Creates a port with the specified configuration.
  ///
  /// The [id] must be unique within the node, and [name] is used for display
  /// purposes.
  ///
  /// Parameters:
  /// - [id]: Unique identifier for this port
  /// - [name]: Display name for the port
  /// - [multiConnections]: Whether multiple connections are allowed (default: false)
  /// - [position]: Where the port is positioned on the node (default: left)
  /// - [offset]: Additional offset from the default position (default: zero)
  /// - [type]: Whether the port is a source, target, or both (default: both)
  /// - [shape]: Visual shape of the port (default: capsuleHalf)
  /// - [size]: Diameter of the port in logical pixels (default: 9.0)
  /// - [tooltip]: Optional tooltip text displayed on hover
  /// - [isConnectable]: Whether connections can be made to this port (default: true)
  /// - [maxConnections]: Maximum number of connections allowed (null for unlimited)
  /// - [showLabel]: Whether to display the port's label (default: false)
  const Port({
    required this.id,
    required this.name,
    this.multiConnections = false,
    this.position = PortPosition.left,
    this.offset = Offset.zero,
    this.type = PortType.both,
    this.shape = PortShapes.capsuleHalf,
    this.size = 9.0,
    this.tooltip,
    this.isConnectable = true,
    this.maxConnections,
    this.showLabel = false,
  });

  /// Unique identifier for this port.
  ///
  /// Must be unique within the containing node to properly identify the port
  /// when creating connections.
  final String id;

  /// Display name for the port.
  ///
  /// This name is typically shown in the UI near the port visual.
  final String name;

  /// Whether this port can accept multiple connections.
  ///
  /// When true, the port can have multiple edges connected to it.
  /// When false, connecting a new edge will replace any existing connection.
  ///
  /// This can be further limited by [maxConnections].
  final bool multiConnections;

  /// The position of the port relative to its node.
  ///
  /// Determines which side of the node the port appears on.
  final PortPosition position;

  /// Additional offset from the port's base position.
  ///
  /// Used to fine-tune port placement when multiple ports are on the same
  /// side of a node or when custom positioning is required.
  @OffsetConverter()
  final Offset offset;

  /// The directionality of the port.
  ///
  /// Determines whether the port can be a source (output), target (input),
  /// or both. This affects what connections can be made to/from this port.
  final PortType type;

  /// The visual shape of the port.
  ///
  /// Different shapes can be used to visually distinguish different types
  /// of ports or data flows.
  @PortShapeConverter()
  final PortShape shape;

  /// The size of the port in logical pixels.
  ///
  /// This determines the diameter of the port visual and its hit area for
  /// interaction.
  final double size;

  /// Optional tooltip text displayed when hovering over the port.
  ///
  /// Use this to provide additional context about the port's purpose or
  /// expected data type.
  final String? tooltip;

  /// Whether connections can be made to/from this port.
  ///
  /// When false, the port is displayed but cannot participate in new
  /// connections. Existing connections are not affected.
  final bool isConnectable;

  /// Maximum number of connections allowed for this port.
  ///
  /// When null, there is no limit (if [multiConnections] is true).
  /// When set, new connections will be rejected once this limit is reached.
  /// This value is only meaningful when [multiConnections] is true.
  final int? maxConnections;

  /// Whether to display the port's label.
  ///
  /// When true, the port's [name] is displayed near the port visual.
  /// When false, only the port shape is shown.
  /// Label visibility may also be affected by zoom level based on theme settings.
  final bool showLabel;

  /// Whether this port can act as a source (output) for connections.
  ///
  /// Returns true if the port type is [PortType.source] or [PortType.both].
  /// Use this to determine if connections can originate from this port.
  bool get isSource => type == PortType.source || type == PortType.both;

  /// Whether this port can act as a target (input) for connections.
  ///
  /// Returns true if the port type is [PortType.target] or [PortType.both].
  /// Use this to determine if connections can terminate at this port.
  bool get isTarget => type == PortType.target || type == PortType.both;

  /// Creates a copy of this port with the specified properties replaced.
  ///
  /// All parameters are optional. If a parameter is not provided, the
  /// corresponding property from the current port is used.
  ///
  /// Example:
  /// ```dart
  /// final originalPort = Port(
  ///   id: 'port-1',
  ///   name: 'Input',
  ///   type: PortType.target,
  /// );
  ///
  /// final modifiedPort = originalPort.copyWith(
  ///   name: 'Modified Input',
  ///   multiConnections: true,
  /// );
  /// // modifiedPort has name 'Modified Input' and multiConnections true,
  /// // but keeps the same id and type
  /// ```
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
    bool? showLabel,
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
      showLabel: showLabel ?? this.showLabel,
    );
  }

  /// Creates a [Port] instance from a JSON map.
  ///
  /// This is typically used when deserializing port data from storage
  /// or network responses.
  factory Port.fromJson(Map<String, dynamic> json) => _$PortFromJson(json);

  /// Converts this port to a JSON map.
  ///
  /// This is typically used when serializing port data for storage
  /// or network transmission.
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
    showLabel,
  ];
}

/// Defines the position of a port on a node.
///
/// This determines which side of the node the port is attached to,
/// affecting both visual placement and connection routing.
///
/// Example:
/// ```dart
/// // Create ports on different sides of a node
/// final leftPort = Port(
///   id: 'input',
///   name: 'In',
///   position: PortPosition.left,
/// );
///
/// final rightPort = Port(
///   id: 'output',
///   name: 'Out',
///   position: PortPosition.right,
/// );
/// ```
enum PortPosition {
  /// Port is positioned on the left side of the node
  left,

  /// Port is positioned on the right side of the node
  right,

  /// Port is positioned on the top side of the node
  top,

  /// Port is positioned on the bottom side of the node
  bottom,
}

/// Extension on PortPosition to convert to ShapeOrientation
extension PortPositionExtension on PortPosition {
  ShapeOrientation toOrientation() {
    switch (this) {
      case PortPosition.left:
        return ShapeOrientation.left;
      case PortPosition.right:
        return ShapeOrientation.right;
      case PortPosition.top:
        return ShapeOrientation.top;
      case PortPosition.bottom:
        return ShapeOrientation.bottom;
    }
  }
}
