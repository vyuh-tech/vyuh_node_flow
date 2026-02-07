import 'dart:ui';

import 'package:json_annotation/json_annotation.dart';
import 'package:mobx/mobx.dart';

import '../shared/json_converters.dart';
import 'connection_endpoint.dart';
import 'connection_label.dart';
import 'effects/connection_effect.dart';
import 'styles/connection_style_base.dart';
import 'styles/connection_styles.dart';

part 'connection.g.dart';

/// Represents a visual connection between two ports on different nodes in a node flow diagram.
///
/// A [Connection] links a source port on one node to a target port on another node,
/// creating a visual edge that can be styled, animated, and labeled. Connections are
/// reactive and use MobX observables for state management.
///
/// ## Type Parameters
/// - `C`: The type of data stored in the connection. Use `void` or omit for untyped.
///
/// ## Key Features
/// - **Port-to-port linking**: Connects specific ports between nodes
/// - **Reactive state**: Uses MobX observables for animated, selected, and label properties
/// - **Customizable styling**: Supports custom [ConnectionStyle] and [ConnectionEndPoint]s
/// - **Three label positions**: Supports startLabel (anchor 0.0), label (anchor 0.5), and endLabel (anchor 1.0)
/// - **Typed data attachment**: Can carry typed data via the [data] property
///
/// ## Usage Example
/// ```dart
/// // With typed data
/// final connection = Connection<PriorityData>(
///   id: 'conn-1',
///   sourceNodeId: 'node-a',
///   sourcePortId: 'output-1',
///   targetNodeId: 'node-b',
///   targetPortId: 'input-1',
///   data: PriorityData(priority: Priority.high),
///   startLabel: ConnectionLabel.start(text: 'Start'),
///   label: ConnectionLabel.center(text: 'Data Flow'),
///   animated: true,
///   style: ConnectionStyles.smoothstep,
/// );
///
/// // Access typed data
/// if (connection.data?.priority == Priority.high) {
///   print('High priority connection');
/// }
///
/// // Without typed data (use void or omit type parameter)
/// final simpleConnection = Connection(
///   id: 'conn-2',
///   sourceNodeId: 'node-a',
///   sourcePortId: 'output-1',
///   targetNodeId: 'node-c',
///   targetPortId: 'input-1',
/// );
/// ```
///
/// ## Observable Properties
/// The following properties are reactive and will trigger UI updates when changed:
/// - [animated]: Whether the connection has flowing animation
/// - [selected]: Whether the connection is currently selected
/// - [startLabel]: Label at the start of the connection (anchor 0.0)
/// - [label]: Label at the center of the connection (anchor 0.5)
/// - [endLabel]: Label at the end of the connection (anchor 1.0)
/// - [startPoint]: Custom start endpoint marker
/// - [endPoint]: Custom end endpoint marker
/// - [color]: Custom color for the connection line
/// - [selectedColor]: Custom color when selected
/// - [strokeWidth]: Custom stroke width for the connection line
/// - [selectedStrokeWidth]: Custom stroke width when selected
///
/// See also:
/// - [ConnectionLabel] for label configuration
/// - [ConnectionStyle] for styling options
/// - [ConnectionEndPoint] for endpoint marker configuration
/// - [NodeFlowController] for managing connections in the flow
@JsonSerializable(genericArgumentFactories: true)
class Connection<C> {
  /// Creates a connection between two ports.
  ///
  /// Parameters:
  /// - [id]: Unique identifier for this connection
  /// - [sourceNodeId]: ID of the node containing the source port
  /// - [sourcePortId]: ID of the source port on the source node
  /// - [targetNodeId]: ID of the node containing the target port
  /// - [targetPortId]: ID of the target port on the target node
  /// - [animated]: Whether to show flowing animation on the connection (default: false)
  /// - [selected]: Whether the connection is initially selected (default: false)
  /// - [data]: Optional arbitrary data to attach to the connection
  /// - [style]: Optional custom style override (defaults to theme style if null)
  /// - [startLabel]: Optional label at the start of the connection (anchor 0.0)
  /// - [label]: Optional label at the center of the connection (anchor 0.5)
  /// - [endLabel]: Optional label at the end of the connection (anchor 1.0)
  /// - [startPoint]: Optional custom start endpoint marker (defaults to theme if null)
  /// - [endPoint]: Optional custom end endpoint marker (defaults to theme if null)
  /// - [startGap]: Optional gap between source port and start endpoint (defaults to theme if null)
  /// - [endGap]: Optional gap between target port and end endpoint (defaults to theme if null)
  /// - [animationEffect]: Optional animation effect to apply (overrides animated flag)
  /// - [locked]: Whether this connection is locked from deletion (default: false)
  /// - [color]: Optional custom color for the connection line (overrides theme)
  /// - [selectedColor]: Optional custom color when the connection is selected (overrides theme)
  /// - [strokeWidth]: Optional custom stroke width for the connection line (overrides theme)
  /// - [selectedStrokeWidth]: Optional custom stroke width when selected (overrides theme)
  /// - [visible]: Whether this connection is visible (default: true)
  Connection({
    required this.id,
    required this.sourceNodeId,
    required this.sourcePortId,
    required this.targetNodeId,
    required this.targetPortId,
    bool animated = false,
    bool selected = false,
    bool visible = true,
    this.data,
    this.style,
    ConnectionLabel? startLabel,
    ConnectionLabel? label,
    ConnectionLabel? endLabel,
    ConnectionEndPoint? startPoint,
    ConnectionEndPoint? endPoint,
    this.startGap,
    this.endGap,
    ConnectionEffect? animationEffect,
    this.locked = false,
    Color? color,
    Color? selectedColor,
    double? strokeWidth,
    double? selectedStrokeWidth,
  }) : _animated = Observable(animated),
       _selected = Observable(selected),
       _visible = Observable(visible),
       _startLabel = Observable(startLabel),
       _label = Observable(label),
       _endLabel = Observable(endLabel),
       _animationEffect = Observable(animationEffect),
       _startPoint = Observable(startPoint),
       _endPoint = Observable(endPoint),
       _color = Observable(color),
       _selectedColor = Observable(selectedColor),
       _strokeWidth = Observable(strokeWidth),
       _selectedStrokeWidth = Observable(selectedStrokeWidth);

  /// Unique identifier for this connection.
  final String id;

  /// ID of the node containing the source port.
  final String sourceNodeId;

  /// ID of the source port on the source node.
  final String sourcePortId;

  /// ID of the node containing the target port.
  final String targetNodeId;

  /// ID of the target port on the target node.
  final String targetPortId;

  final Observable<bool> _animated;
  final Observable<bool> _selected;
  final Observable<bool> _visible;
  final Observable<ConnectionLabel?> _startLabel;
  final Observable<ConnectionLabel?> _label;
  final Observable<ConnectionLabel?> _endLabel;
  final Observable<ConnectionEffect?> _animationEffect;
  final Observable<ConnectionEndPoint?> _startPoint;
  final Observable<ConnectionEndPoint?> _endPoint;
  final Observable<Color?> _color;
  final Observable<Color?> _selectedColor;
  final Observable<double?> _strokeWidth;
  final Observable<double?> _selectedStrokeWidth;

  /// Optional typed data to attach to the connection.
  ///
  /// This can be used to store custom metadata, validation state, or any other
  /// application-specific information about the connection. The type `C` allows
  /// for strongly-typed access to connection data.
  ///
  /// ## Example
  /// ```dart
  /// class EdgeMetadata {
  ///   final String label;
  ///   final double weight;
  ///   EdgeMetadata({required this.label, required this.weight});
  /// }
  ///
  /// final connection = Connection<EdgeMetadata>(
  ///   id: 'conn-1',
  ///   // ... other params
  ///   data: EdgeMetadata(label: 'data-flow', weight: 1.5),
  /// );
  ///
  /// // Access typed data
  /// print(connection.data?.weight); // 1.5
  /// ```
  final C? data;

  /// Optional custom style override for this connection.
  ///
  /// If null, the connection will use the style from [ConnectionTheme].
  /// See [ConnectionStyles] for built-in style options.
  @JsonKey(fromJson: _connectionStyleFromJson, toJson: _connectionStyleToJson)
  final ConnectionStyle? style;

  /// Optional custom start endpoint marker.
  ///
  /// If null, the connection will use the startPoint from [ConnectionTheme].
  /// This property is reactive — changing it will trigger a UI repaint.
  @JsonKey(includeFromJson: false, includeToJson: false)
  ConnectionEndPoint? get startPoint => _startPoint.value;

  /// Sets the start endpoint marker for this connection.
  set startPoint(ConnectionEndPoint? value) =>
      runInAction(() => _startPoint.value = value);

  /// Optional custom end endpoint marker.
  ///
  /// If null, the connection will use the endPoint from [ConnectionTheme].
  /// This property is reactive — changing it will trigger a UI repaint.
  @JsonKey(includeFromJson: false, includeToJson: false)
  ConnectionEndPoint? get endPoint => _endPoint.value;

  /// Sets the end endpoint marker for this connection.
  set endPoint(ConnectionEndPoint? value) =>
      runInAction(() => _endPoint.value = value);

  /// Optional gap between source port and start endpoint in logical pixels.
  ///
  /// If null, the connection will use the startGap from [ConnectionTheme].
  final double? startGap;

  /// Optional gap between target port and end endpoint in logical pixels.
  ///
  /// If null, the connection will use the endGap from [ConnectionTheme].
  final double? endGap;

  /// Whether this connection is locked from deletion.
  ///
  /// When true, the connection cannot be deleted through user interactions.
  /// Useful for required connections or template elements that should not
  /// be removed.
  ///
  /// Note: This only prevents deletion, not selection or visual changes.
  final bool locked;

  /// Optional custom color for the connection line.
  ///
  /// If null, the connection will use the color from [ConnectionTheme].
  /// This color is used when the connection is not selected.
  /// This property is reactive — changing it will trigger a UI repaint.
  @JsonKey(includeFromJson: false, includeToJson: false)
  Color? get color => _color.value;

  /// Sets the custom color for the connection line.
  set color(Color? value) => runInAction(() => _color.value = value);

  /// Optional custom color when the connection is selected.
  ///
  /// If null, the connection will use the selectedColor from [ConnectionTheme].
  /// This property is reactive — changing it will trigger a UI repaint.
  @JsonKey(includeFromJson: false, includeToJson: false)
  Color? get selectedColor => _selectedColor.value;

  /// Sets the custom color when the connection is selected.
  set selectedColor(Color? value) =>
      runInAction(() => _selectedColor.value = value);

  /// Optional custom stroke width for the connection line.
  ///
  /// If null, the connection will use the strokeWidth from [ConnectionTheme].
  /// This width is used when the connection is not selected.
  /// This property is reactive — changing it will trigger a UI repaint.
  @JsonKey(includeFromJson: false, includeToJson: false)
  double? get strokeWidth => _strokeWidth.value;

  /// Sets the custom stroke width for the connection line.
  set strokeWidth(double? value) =>
      runInAction(() => _strokeWidth.value = value);

  /// Optional custom stroke width when selected.
  ///
  /// If null, the connection will use the selectedStrokeWidth from [ConnectionTheme].
  /// This property is reactive — changing it will trigger a UI repaint.
  @JsonKey(includeFromJson: false, includeToJson: false)
  double? get selectedStrokeWidth => _selectedStrokeWidth.value;

  /// Sets the custom stroke width when selected.
  set selectedStrokeWidth(double? value) =>
      runInAction(() => _selectedStrokeWidth.value = value);

  // Getters and setters for accessing observable values

  /// Whether the connection shows flowing animation.
  ///
  /// When true, the connection will display an animated effect. This is
  /// automatically true when [animationEffect] is set, or can be set manually.
  @JsonKey(includeFromJson: false, includeToJson: false)
  bool get animated => _animationEffect.value != null || _animated.value;

  /// Sets whether the connection shows flowing animation.
  ///
  /// Setting [animationEffect] is the preferred way to enable animations
  /// as it provides more control over the effect.
  set animated(bool value) => runInAction(() => _animated.value = value);

  /// The animation effect to apply to this connection.
  ///
  /// When set to a [ConnectionEffect] instance, the connection will
  /// be animated using that effect's rendering logic. Set to null to disable
  /// animation.
  ///
  /// Example:
  /// ```dart
  /// connection.animationEffect = FlowingDashEffect(
  ///   speed: 2.0,
  ///   dashLength: 10.0,
  ///   gapLength: 5.0,
  /// );
  /// ```
  @JsonKey(includeFromJson: false, includeToJson: false)
  ConnectionEffect? get animationEffect => _animationEffect.value;

  /// Sets the animation effect for this connection.
  set animationEffect(ConnectionEffect? value) =>
      runInAction(() => _animationEffect.value = value);

  /// Whether the connection is currently selected.
  ///
  /// Selected connections typically render with a different color and/or
  /// stroke width as defined by [ConnectionTheme.selectedColor] and
  /// [ConnectionTheme.selectedStrokeWidth].
  @JsonKey(includeFromJson: false, includeToJson: false)
  bool get selected => _selected.value;

  /// Sets whether the connection is currently selected.
  set selected(bool value) => runInAction(() => _selected.value = value);

  /// Whether the connection is currently visible.
  ///
  /// When false, the connection will not be rendered but remains in the graph.
  /// Useful for temporarily hiding connections during preview operations
  /// (e.g., edge insertion preview).
  @JsonKey(includeFromJson: false, includeToJson: false)
  bool get visible => _visible.value;

  /// Sets whether the connection is currently visible.
  set visible(bool value) => runInAction(() => _visible.value = value);

  /// The label at the start of the connection (anchor 0.0).
  ///
  /// This label appears at the source port. Set to null to remove the start label.
  @JsonKey(includeFromJson: false, includeToJson: false)
  ConnectionLabel? get startLabel => _startLabel.value;

  /// Sets the label at the start of the connection.
  set startLabel(ConnectionLabel? value) =>
      runInAction(() => _startLabel.value = value);

  /// The label at the center of the connection (anchor 0.5).
  ///
  /// This label appears at the midpoint of the connection. Set to null to remove the center label.
  @JsonKey(includeFromJson: false, includeToJson: false)
  ConnectionLabel? get label => _label.value;

  /// Sets the label at the center of the connection.
  set label(ConnectionLabel? value) => runInAction(() => _label.value = value);

  /// The label at the end of the connection (anchor 1.0).
  ///
  /// This label appears at the target port. Set to null to remove the end label.
  @JsonKey(includeFromJson: false, includeToJson: false)
  ConnectionLabel? get endLabel => _endLabel.value;

  /// Sets the label at the end of the connection.
  set endLabel(ConnectionLabel? value) =>
      runInAction(() => _endLabel.value = value);

  /// The list of all non-null labels displayed along the connection path.
  ///
  /// This getter returns a list containing the non-null labels from [startLabel],
  /// [label], and [endLabel] in that order. This is used internally for rendering.
  @JsonKey(includeFromJson: false, includeToJson: false)
  List<ConnectionLabel> get labels {
    final result = <ConnectionLabel>[];
    if (_startLabel.value != null) result.add(_startLabel.value!);
    if (_label.value != null) result.add(_label.value!);
    if (_endLabel.value != null) result.add(_endLabel.value!);
    return result;
  }

  /// Checks if this connection involves the given node.
  ///
  /// Returns true if the node is either the source or target of this connection.
  ///
  /// Parameters:
  /// - [nodeId]: The ID of the node to check
  ///
  /// Returns: true if [nodeId] matches either [sourceNodeId] or [targetNodeId]
  bool involvesNode(String nodeId) {
    return sourceNodeId == nodeId || targetNodeId == nodeId;
  }

  /// Checks if this connection involves the given port on a specific node.
  ///
  /// Returns true if the specified node and port combination matches either
  /// the source or target of this connection.
  ///
  /// Parameters:
  /// - [nodeId]: The ID of the node to check
  /// - [portId]: The ID of the port to check
  ///
  /// Returns: true if the node/port pair matches either the source or target
  bool involvesPort(String nodeId, String portId) {
    return (sourceNodeId == nodeId && sourcePortId == portId) ||
        (targetNodeId == nodeId && targetPortId == portId);
  }

  /// Gets the effective connection style for rendering.
  ///
  /// Returns the instance-specific [style] if set, otherwise falls back to
  /// the provided [themeStyle] from the theme.
  ///
  /// Parameters:
  /// - [themeStyle]: The default style from the theme
  ///
  /// Returns: The style to use for rendering this connection
  ConnectionStyle getEffectiveStyle(ConnectionStyle themeStyle) {
    return style ?? themeStyle;
  }

  /// Gets the effective start endpoint marker for rendering.
  ///
  /// Returns the instance-specific [startPoint] if set, otherwise falls back
  /// to the provided [themeStartPoint] from the theme.
  ///
  /// Parameters:
  /// - [themeStartPoint]: The default start point from the theme
  ///
  /// Returns: The start endpoint configuration to use for rendering
  ConnectionEndPoint getEffectiveStartPoint(
    ConnectionEndPoint themeStartPoint,
  ) {
    return startPoint ?? themeStartPoint;
  }

  /// Gets the effective end endpoint marker for rendering.
  ///
  /// Returns the instance-specific [endPoint] if set, otherwise falls back
  /// to the provided [themeEndPoint] from the theme.
  ///
  /// Parameters:
  /// - [themeEndPoint]: The default end point from the theme
  ///
  /// Returns: The end endpoint configuration to use for rendering
  ConnectionEndPoint getEffectiveEndPoint(ConnectionEndPoint themeEndPoint) {
    return endPoint ?? themeEndPoint;
  }

  /// Gets the effective animation effect for rendering.
  ///
  /// Returns the instance-specific [animationEffect] if set, otherwise falls
  /// back to the provided [themeAnimationEffect] from the theme.
  ///
  /// Parameters:
  /// - [themeAnimationEffect]: The default animation effect from the theme
  ///
  /// Returns: The animation effect to use for rendering this connection, or null if none
  ConnectionEffect? getEffectiveAnimationEffect(
    ConnectionEffect? themeAnimationEffect,
  ) {
    return animationEffect ?? themeAnimationEffect;
  }

  /// Gets the effective color for rendering based on selection state.
  ///
  /// Returns the appropriate color considering:
  /// 1. Instance-specific [color]/[selectedColor] if set
  /// 2. Theme colors as fallback
  ///
  /// Parameters:
  /// - [themeColor]: The default color from the theme (non-selected)
  /// - [themeSelectedColor]: The default selected color from the theme
  ///
  /// Returns: The color to use for rendering this connection
  Color getEffectiveColor(Color themeColor, Color themeSelectedColor) {
    if (selected) {
      return selectedColor ?? themeSelectedColor;
    }
    return color ?? themeColor;
  }

  /// Gets the effective stroke width for rendering based on selection state.
  ///
  /// Returns the appropriate stroke width considering:
  /// 1. Instance-specific [strokeWidth]/[selectedStrokeWidth] if set
  /// 2. Theme stroke widths as fallback
  ///
  /// Parameters:
  /// - [themeStrokeWidth]: The default stroke width from the theme (non-selected)
  /// - [themeSelectedStrokeWidth]: The default selected stroke width from the theme
  ///
  /// Returns: The stroke width to use for rendering this connection
  double getEffectiveStrokeWidth(
    double themeStrokeWidth,
    double themeSelectedStrokeWidth,
  ) {
    if (selected) {
      return selectedStrokeWidth ?? themeSelectedStrokeWidth;
    }
    return strokeWidth ?? themeStrokeWidth;
  }

  /// Disposes resources used by this connection.
  ///
  /// Note: MobX observables don't require manual disposal, so this method
  /// is currently a no-op but provided for API consistency.
  void dispose() {
    // MobX observables don't need manual disposal
  }

  /// Creates a [Connection] from a JSON map.
  ///
  /// This factory constructor deserializes a connection from JSON, properly
  /// initializing all observable properties.
  ///
  /// ## Parameters
  /// - [json]: The JSON map to deserialize from
  /// - [fromJsonC]: A function to deserialize the typed data field. Pass
  ///   `(json) => json as C` for simple types, or your type's fromJson for
  ///   complex types. Pass `(json) => null` if not using typed data.
  ///
  /// ## Example
  /// ```dart
  /// // With typed data
  /// final connection = Connection<EdgeMetadata>.fromJson(
  ///   jsonMap,
  ///   (json) => EdgeMetadata.fromJson(json as Map<String, dynamic>),
  /// );
  ///
  /// // Without typed data
  /// final simpleConn = Connection.fromJson(jsonMap, (json) => null);
  /// ```
  factory Connection.fromJson(
    Map<String, dynamic> json,
    C Function(Object? json) fromJsonC,
  ) {
    final connection = _$ConnectionFromJson(json, fromJsonC);
    // Initialize observable labels from JSON
    if (json['startLabel'] != null) {
      connection._startLabel.value = ConnectionLabel.fromJson(
        json['startLabel'] as Map<String, dynamic>,
      );
    }
    if (json['label'] != null) {
      connection._label.value = ConnectionLabel.fromJson(
        json['label'] as Map<String, dynamic>,
      );
    }
    if (json['endLabel'] != null) {
      connection._endLabel.value = ConnectionLabel.fromJson(
        json['endLabel'] as Map<String, dynamic>,
      );
    }

    // Initialize observable endpoints from JSON
    if (json['startPoint'] != null) {
      connection._startPoint.value = ConnectionEndPoint.fromJson(
        json['startPoint'] as Map<String, dynamic>,
      );
    }
    if (json['endPoint'] != null) {
      connection._endPoint.value = ConnectionEndPoint.fromJson(
        json['endPoint'] as Map<String, dynamic>,
      );
    }

    // Initialize observable visual properties from JSON
    if (json['color'] != null) {
      connection._color.value = const ColorConverter().fromJson(
        json['color'] as int,
      );
    }
    if (json['selectedColor'] != null) {
      connection._selectedColor.value = const ColorConverter().fromJson(
        json['selectedColor'] as int,
      );
    }
    if (json['strokeWidth'] != null) {
      connection._strokeWidth.value = (json['strokeWidth'] as num).toDouble();
    }
    if (json['selectedStrokeWidth'] != null) {
      connection._selectedStrokeWidth.value =
          (json['selectedStrokeWidth'] as num).toDouble();
    }

    return connection;
  }

  /// Converts this [Connection] to a JSON map.
  ///
  /// This method serializes all connection properties, including observable
  /// values, to a JSON-compatible map.
  ///
  /// ## Parameters
  /// - [toJsonC]: A function to serialize the typed data field. Pass
  ///   `(value) => value` for simple types, or your type's toJson for
  ///   complex types.
  ///
  /// ## Example
  /// ```dart
  /// // With typed data
  /// final json = connection.toJson((data) => data?.toJson());
  ///
  /// // Without typed data
  /// final json = simpleConn.toJson((data) => null);
  /// ```
  Map<String, dynamic> toJson(Object? Function(C value) toJsonC) {
    final json = _$ConnectionToJson(this, toJsonC);
    // Include observable labels in JSON
    if (_startLabel.value != null) {
      json['startLabel'] = _startLabel.value!.toJson();
    }
    if (_label.value != null) {
      json['label'] = _label.value!.toJson();
    }
    if (_endLabel.value != null) {
      json['endLabel'] = _endLabel.value!.toJson();
    }

    // Include observable endpoints in JSON
    if (_startPoint.value != null) {
      json['startPoint'] = _startPoint.value!.toJson();
    }
    if (_endPoint.value != null) {
      json['endPoint'] = _endPoint.value!.toJson();
    }

    // Include observable visual properties in JSON
    if (_color.value != null) {
      json['color'] = const ColorConverter().toJson(_color.value!);
    }
    if (_selectedColor.value != null) {
      json['selectedColor'] =
          const ColorConverter().toJson(_selectedColor.value!);
    }
    if (_strokeWidth.value != null) {
      json['strokeWidth'] = _strokeWidth.value;
    }
    if (_selectedStrokeWidth.value != null) {
      json['selectedStrokeWidth'] = _selectedStrokeWidth.value;
    }

    return json;
  }
}

/// Deserializes a [ConnectionStyle] from JSON.
///
/// Supports both string IDs and full style objects. Returns null if the
/// input is null, or defaults to [ConnectionStyles.smoothstep] if the
/// style cannot be found.
ConnectionStyle? _connectionStyleFromJson(dynamic json) {
  if (json == null) return null;

  if (json is String) {
    return ConnectionStyles.findById(json) ?? ConnectionStyles.smoothstep;
  }

  return ConnectionStyles.smoothstep; // Default fallback
}

/// Serializes a [ConnectionStyle] to JSON.
///
/// Returns the style's ID string, or null if the style is null.
dynamic _connectionStyleToJson(ConnectionStyle? style) {
  return style?.id;
}
