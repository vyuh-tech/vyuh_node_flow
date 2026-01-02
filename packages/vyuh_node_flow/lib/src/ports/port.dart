import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:mobx/mobx.dart';

import '../nodes/node.dart';
import '../shared/json_converters.dart';
import '../shared/shapes/marker_shape.dart';
import 'port_theme.dart';

part 'port.g.dart';

/// Builder function for creating a port widget.
///
/// This is used for per-instance port customization. The builder receives
/// the node containing this port, allowing access to typed node data.
///
/// ## Type Parameters
/// - `T`: The type of data stored in the containing node
///
/// ## Parameters
/// - [context]: The build context for widget creation
/// - [node]: The node containing this port (use `node.data` for typed access)
/// - [port]: The port being rendered
///
/// ## Example
/// ```dart
/// final port = Port(
///   id: 'input-1',
///   name: 'Data',
///   widgetBuilder: (context, node, port) {
///     final myNode = node as Node<MyData>;
///     return Container(
///       width: 12,
///       height: 12,
///       decoration: BoxDecoration(
///         color: myNode.data?.isActive == true ? Colors.green : Colors.blue,
///         shape: BoxShape.circle,
///       ),
///     );
///   },
/// );
/// ```
typedef PortWidgetBuilder<T> =
    Widget Function(BuildContext context, Node<T> node, Port port);

/// Default port size used when no size is specified.
const Size defaultPortSize = Size(9, 9);

/// Defines the directionality of a port in a node-based flow editor.
///
/// Ports can act as sources (output), targets (input), or both, determining
/// how connections can be made between nodes.
///
/// Example:
/// ```dart
/// // Create an output port
/// Port sourcePort = Port(
///   id: 'output-1',
///   name: 'Result',
///   type: PortType.output,
/// );
///
/// // Create an input port
/// Port targetPort = Port(
///   id: 'input-1',
///   name: 'Value',
///   type: PortType.input,
/// );
/// ```
enum PortType {
  /// Port can only receive connections (input port)
  input,

  /// Port can only emit connections (output port)
  output,
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
///   type: PortType.output,
///   position: PortPosition.right,
/// );
///
/// // Create an input port with multiple connections allowed
/// final inputPort = Port(
///   id: 'input-1',
///   name: 'Data',
///   type: PortType.input,
///   position: PortPosition.left,
///   multiConnections: true,
///   maxConnections: 5,
///   tooltip: 'Accepts up to 5 connections',
/// );
///
/// // Create a top port with custom styling
/// final topPort = Port(
///   id: 'top-1',
///   name: 'Config',
///   position: PortPosition.top,
///   shape: MarkerShapes.diamond,
///   size: Size(12, 12),
///   offset: Offset(75, 0), // Centered on a 150px wide node
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
  /// - [offset]: Position where the CENTER of the port should be. For left/right
  ///   ports, offset.dy is the vertical center. For top/bottom ports, offset.dx
  ///   is the horizontal center. (default: zero)
  /// - [type]: Whether the port is a source, target, or both (default: inferred from position -
  ///   left/top → target, right/bottom → source)
  /// - [shape]: Visual shape of the port (null = use theme default)
  /// - [size]: Size of the port in logical pixels (null = use theme default)
  /// - [tooltip]: Optional tooltip text displayed on hover
  /// - [isConnectable]: Whether connections can be made to this port (default: true)
  /// - [maxConnections]: Maximum number of connections allowed (null for unlimited)
  /// - [showLabel]: Whether to display the port's label (default: false)
  /// - [theme]: Optional theme override for this port (overrides global PortTheme)

  Port({
    required this.id,
    required this.name,
    this.multiConnections = false,
    this.position = PortPosition.left,
    this.offset = Offset.zero,
    PortType? type,
    this.shape,
    this.size,
    this.tooltip,
    this.isConnectable = true,
    this.maxConnections,
    this.showLabel = false,
    this.widgetBuilder,
    this.theme,
  }) : type = type ?? _inferTypeFromPosition(position);

  /// Infers the port type from its position.
  ///
  /// Convention:
  /// - Left/Top ports → input
  /// - Right/Bottom ports → output
  static PortType _inferTypeFromPosition(PortPosition position) {
    return switch (position) {
      PortPosition.left || PortPosition.top => PortType.input,
      PortPosition.right || PortPosition.bottom => PortType.output,
    };
  }

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

  /// Position offset that specifies where the CENTER of the port should be.
  ///
  /// The offset interpretation depends on the port's [position]:
  /// - **Left/Right ports**: [offset.dy] is the vertical center position
  ///   (distance from the top of the node). [offset.dx] adjusts the horizontal
  ///   position from the edge.
  /// - **Top/Bottom ports**: [offset.dx] is the horizontal center position
  ///   (distance from the left of the node). [offset.dy] adjusts the vertical
  ///   position from the edge.
  ///
  /// Example for a 150x100 node:
  /// ```dart
  /// // Right port centered vertically at 50 (middle of node)
  /// Port(position: PortPosition.right, offset: Offset(0, 50))
  ///
  /// // Top port centered horizontally at 75 (middle of node width)
  /// Port(position: PortPosition.top, offset: Offset(75, 0))
  ///
  /// // Two right ports at 1/3 and 2/3 height
  /// Port(position: PortPosition.right, offset: Offset(0, 33))
  /// Port(position: PortPosition.right, offset: Offset(0, 67))
  /// ```
  @OffsetConverter()
  final Offset offset;

  /// The directionality of the port.
  ///
  /// Determines whether the port can be a source (output), target (input),
  /// or both. This affects what connections can be made to/from this port.
  final PortType type;

  /// The visual shape of the port.
  ///
  /// When null, falls back to [PortTheme.shape].
  /// Different shapes can be used to visually distinguish different types
  /// of ports or data flows.
  @MarkerShapeConverter()
  final MarkerShape? shape;

  /// The size of the port in logical pixels.
  ///
  /// When null, falls back to [PortTheme.size].
  /// This determines the dimensions of the port visual and its hit area for
  /// interaction. Width and height can differ for asymmetric port shapes.
  @SizeConverter()
  final Size? size;

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
  /// When false, only the marker shape is shown.
  /// Label visibility may also be affected by zoom level based on theme settings.
  final bool showLabel;

  /// Optional theme override for this port.
  ///
  /// When provided, this theme overrides the global [PortTheme] from
  /// [NodeFlowTheme.portTheme]. Use this to customize individual port
  /// appearance without affecting other ports.
  ///
  /// Example:
  /// ```dart
  /// Port(
  ///   id: 'image_out',
  ///   name: 'Image',
  ///   theme: PortTheme.light.copyWith(
  ///     connectedColor: Colors.blue,
  ///   ),
  /// )
  /// ```
  ///
  /// Not serialized to JSON.
  @JsonKey(includeFromJson: false, includeToJson: false)
  final PortTheme? theme;

  /// Per-instance widget builder for custom port rendering.
  ///
  /// When provided, this builder takes precedence over the global `portBuilder`
  /// passed to `NodeFlowEditor`. The cascade order is:
  ///
  /// 1. `port.widgetBuilder` (this field) - instance-level customization
  /// 2. `portBuilder` (global) - editor-level customization
  /// 3. `PortWidget` (default) - framework default
  ///
  /// Since [Port] is not generic, this uses `dynamic` for the node type.
  /// Cast to your specific node type within the builder if needed.
  ///
  /// Not serialized to JSON.
  @JsonKey(includeFromJson: false, includeToJson: false)
  final PortWidgetBuilder<dynamic>? widgetBuilder;

  /// Builds the widget for this port using the instance-level builder.
  ///
  /// Returns null if no [widgetBuilder] is set, allowing fallback to
  /// the global `portBuilder` or default `PortWidget`.
  ///
  /// ## Parameters
  /// - [context]: The build context for widget creation
  /// - [node]: The node containing this port
  Widget? buildWidget(BuildContext context, Node<dynamic> node) {
    return widgetBuilder?.call(context, node, this);
  }

  /// Observable for the port's highlighted state.
  ///
  /// This is set externally during connection drag operations to indicate
  /// that this port is a potential connection target. Not serialized.
  @JsonKey(includeFromJson: false, includeToJson: false)
  final Observable<bool> highlighted = Observable(false);

  /// Whether this port can act as an output for connections.
  ///
  /// Returns true if the port type is [PortType.output].
  /// Use this to determine if connections can originate from this port.
  bool get isOutput => type == PortType.output;

  /// Whether this port can act as an input for connections.
  ///
  /// Returns true if the port type is [PortType.input].
  /// Use this to determine if connections can terminate at this port.
  bool get isInput => type == PortType.input;

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
  ///   type: PortType.input,
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
    MarkerShape? shape,
    Size? size,
    IconData? icon,
    String? tooltip,
    bool? isConnectable,
    int? maxConnections,
    bool? showLabel,
    PortWidgetBuilder<dynamic>? widgetBuilder,
    PortTheme? theme,
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
      widgetBuilder: widgetBuilder ?? this.widgetBuilder,
      theme: theme ?? this.theme,
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

/// Extension on PortPosition providing centralized port geometry calculations.
///
/// All port position-related calculations should use these methods to ensure
/// consistency across the codebase. This includes:
/// - Connection attachment points
/// - Visual center positions
/// - Widget origin positions
extension PortPositionExtension on PortPosition {
  /// Converts to [ShapeDirection] for shape-based calculations.
  ShapeDirection toOrientation() {
    switch (this) {
      case PortPosition.left:
        return ShapeDirection.left;
      case PortPosition.right:
        return ShapeDirection.right;
      case PortPosition.top:
        return ShapeDirection.top;
      case PortPosition.bottom:
        return ShapeDirection.bottom;
    }
  }

  /// Returns the offset from port's top-left to the connection attachment point.
  ///
  /// Connections attach at the port's outer edge (the edge aligned with
  /// the node boundary):
  /// - Left port: left edge, vertically centered
  /// - Right port: right edge, vertically centered
  /// - Top port: horizontally centered, top edge
  /// - Bottom port: horizontally centered, bottom edge
  ///
  /// ```
  /// Left port:     Right port:    Top port:      Bottom port:
  /// ●───┐          ┌───●          ──●──          ┌───┐
  /// │   │          │   │          │   │          │   │
  /// └───┘          └───┘          └───┘          ──●──
  /// ```
  Offset connectionOffset(Size portSize) {
    return switch (this) {
      PortPosition.left => Offset(0, portSize.height / 2),
      PortPosition.right => Offset(portSize.width, portSize.height / 2),
      PortPosition.top => Offset(portSize.width / 2, 0),
      PortPosition.bottom => Offset(portSize.width / 2, portSize.height),
    };
  }

  /// Calculates the port widget's top-left origin position relative to an anchor.
  ///
  /// Ports are positioned so their outer edge aligns with the node/shape boundary
  /// at the anchor point, extending inward. The port is centered on the
  /// perpendicular axis.
  ///
  /// Parameters:
  /// - [anchorOffset]: The anchor position on the node boundary
  /// - [portSize]: The size of the port widget
  /// - [portAdjustment]: Additional offset adjustment from the port model
  /// - [useAnchorForPerpendicularAxis]: If true, uses anchor position for
  ///   the perpendicular axis (shaped nodes). If false, uses portAdjustment
  ///   directly (rectangular nodes).
  ///
  /// Returns the top-left corner position of the port widget relative to
  /// the node's origin.
  Offset calculateOrigin({
    required Offset anchorOffset,
    required Size portSize,
    required Offset portAdjustment,
    required bool useAnchorForPerpendicularAxis,
  }) {
    switch (this) {
      case PortPosition.left:
        // Port left edge at anchor x, centered vertically
        final baseY = useAnchorForPerpendicularAxis
            ? anchorOffset.dy
            : portAdjustment.dy;
        return Offset(
          anchorOffset.dx + portAdjustment.dx,
          baseY -
              portSize.height / 2 +
              (useAnchorForPerpendicularAxis ? portAdjustment.dy : 0),
        );
      case PortPosition.right:
        // Port right edge at anchor x, centered vertically
        final baseY = useAnchorForPerpendicularAxis
            ? anchorOffset.dy
            : portAdjustment.dy;
        return Offset(
          anchorOffset.dx - portSize.width + portAdjustment.dx,
          baseY -
              portSize.height / 2 +
              (useAnchorForPerpendicularAxis ? portAdjustment.dy : 0),
        );
      case PortPosition.top:
        // Port top edge at anchor y, centered horizontally
        final baseX = useAnchorForPerpendicularAxis
            ? anchorOffset.dx
            : portAdjustment.dx;
        return Offset(
          baseX -
              portSize.width / 2 +
              (useAnchorForPerpendicularAxis ? portAdjustment.dx : 0),
          anchorOffset.dy + portAdjustment.dy,
        );
      case PortPosition.bottom:
        // Port bottom edge at anchor y, centered horizontally
        final baseX = useAnchorForPerpendicularAxis
            ? anchorOffset.dx
            : portAdjustment.dx;
        return Offset(
          baseX -
              portSize.width / 2 +
              (useAnchorForPerpendicularAxis ? portAdjustment.dx : 0),
          anchorOffset.dy - portSize.height + portAdjustment.dy,
        );
    }
  }

  /// Whether the perpendicular axis is horizontal (left/right ports)
  /// or vertical (top/bottom ports).
  bool get isHorizontal =>
      this == PortPosition.left || this == PortPosition.right;

  /// Whether the perpendicular axis is vertical (top/bottom ports).
  bool get isVertical =>
      this == PortPosition.top || this == PortPosition.bottom;

  /// Returns the outward normal direction for this port position.
  ///
  /// The normal points outward from the node boundary.
  Offset get normal {
    return switch (this) {
      PortPosition.left => const Offset(-1, 0),
      PortPosition.right => const Offset(1, 0),
      PortPosition.top => const Offset(0, -1),
      PortPosition.bottom => const Offset(0, 1),
    };
  }
}
