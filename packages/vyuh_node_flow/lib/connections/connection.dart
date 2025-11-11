import 'package:json_annotation/json_annotation.dart';
import 'package:mobx/mobx.dart';

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
/// ## Key Features
/// - **Port-to-port linking**: Connects specific ports between nodes
/// - **Reactive state**: Uses MobX observables for animated, selected, and label properties
/// - **Customizable styling**: Supports custom [ConnectionStyle] and [ConnectionEndPoint]s
/// - **Three label positions**: Supports startLabel (anchor 0.0), label (anchor 0.5), and endLabel (anchor 1.0)
/// - **Data attachment**: Can carry arbitrary data via the [data] property
///
/// ## Usage Example
/// ```dart
/// final connection = Connection(
///   id: 'conn-1',
///   sourceNodeId: 'node-a',
///   sourcePortId: 'output-1',
///   targetNodeId: 'node-b',
///   targetPortId: 'input-1',
///   startLabel: ConnectionLabel.start(text: 'Start'),
///   label: ConnectionLabel.center(text: 'Data Flow'),
///   endLabel: ConnectionLabel.end(text: 'End', offset: 10.0),
///   animated: true,
///   style: ConnectionStyles.smoothstep,
/// );
///
/// // Update labels directly
/// connection.label = ConnectionLabel.center(text: 'Updated Flow');
/// connection.startLabel = null; // Remove start label
///
/// // Check node/port involvement
/// if (connection.involvesNode('node-a')) {
///   print('Connection involves node-a');
/// }
/// ```
///
/// ## Observable Properties
/// The following properties are reactive and will trigger UI updates when changed:
/// - [animated]: Whether the connection has flowing animation
/// - [selected]: Whether the connection is currently selected
/// - [startLabel]: Label at the start of the connection (anchor 0.0)
/// - [label]: Label at the center of the connection (anchor 0.5)
/// - [endLabel]: Label at the end of the connection (anchor 1.0)
///
/// See also:
/// - [ConnectionLabel] for label configuration
/// - [ConnectionStyle] for styling options
/// - [ConnectionEndPoint] for endpoint marker configuration
/// - [NodeFlowController] for managing connections in the flow
@JsonSerializable()
class Connection {
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
  /// - [animationEffect]: Optional animation effect to apply (overrides animated flag)
  Connection({
    required this.id,
    required this.sourceNodeId,
    required this.sourcePortId,
    required this.targetNodeId,
    required this.targetPortId,
    bool animated = false,
    bool selected = false,
    this.data,
    this.style,
    ConnectionLabel? startLabel,
    ConnectionLabel? label,
    ConnectionLabel? endLabel,
    this.startPoint,
    this.endPoint,
    ConnectionEffect? animationEffect,
  }) : _animated = Observable(animated),
       _selected = Observable(selected),
       _startLabel = Observable(startLabel),
       _label = Observable(label),
       _endLabel = Observable(endLabel),
       _animationEffect = Observable(animationEffect);

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
  final Observable<ConnectionLabel?> _startLabel;
  final Observable<ConnectionLabel?> _label;
  final Observable<ConnectionLabel?> _endLabel;
  final Observable<ConnectionEffect?> _animationEffect;

  /// Optional arbitrary data to attach to the connection.
  ///
  /// This can be used to store custom metadata, validation state, or any other
  /// application-specific information about the connection.
  final Map<String, dynamic>? data;

  /// Optional custom style override for this connection.
  ///
  /// If null, the connection will use the style from [ConnectionTheme].
  /// See [ConnectionStyles] for built-in style options.
  @JsonKey(fromJson: _connectionStyleFromJson, toJson: _connectionStyleToJson)
  final ConnectionStyle? style;

  /// Optional custom start endpoint marker.
  ///
  /// If null, the connection will use the startPoint from [ConnectionTheme].
  final ConnectionEndPoint? startPoint;

  /// Optional custom end endpoint marker.
  ///
  /// If null, the connection will use the endPoint from [ConnectionTheme].
  final ConnectionEndPoint? endPoint;

  // Getters and setters for accessing observable values

  /// Whether the connection shows flowing animation.
  ///
  /// When true, the connection will display an animated effect. This is
  /// automatically true when [animationEffect] is set, or can be set
  /// manually for backward compatibility.
  @JsonKey(includeFromJson: false, includeToJson: false)
  bool get animated => _animationEffect.value != null || _animated.value;

  /// Sets whether the connection shows flowing animation.
  ///
  /// Note: Setting [animationEffect] is the preferred way to enable animations.
  /// This setter is kept for backward compatibility.
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
  factory Connection.fromJson(Map<String, dynamic> json) {
    final connection = _$ConnectionFromJson(json);
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
    return connection;
  }

  /// Converts this [Connection] to a JSON map.
  ///
  /// This method serializes all connection properties, including observable
  /// values, to a JSON-compatible map.
  Map<String, dynamic> toJson() {
    final json = _$ConnectionToJson(this);
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
