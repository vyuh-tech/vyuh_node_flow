import 'package:json_annotation/json_annotation.dart';
import 'package:mobx/mobx.dart';

import 'connection_endpoint.dart';
import 'connection_style_base.dart';
import 'connection_styles.dart';

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
/// - **Multiple labels**: Supports center, start, and end labels
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
///   label: 'Data Flow',
///   animated: true,
///   style: ConnectionStyles.smoothstep,
/// );
///
/// // Update labels reactively
/// connection.updateLabel('Updated Flow');
/// connection.updateStartLabel('Source: A');
/// connection.updateEndLabel('Target: B');
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
/// - [label]: Center label text
/// - [startLabel]: Label near the source endpoint
/// - [endLabel]: Label near the target endpoint
///
/// See also:
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
  /// - [label]: Optional center label text
  /// - [startLabel]: Optional label text near the source endpoint
  /// - [endLabel]: Optional label text near the target endpoint
  /// - [startPoint]: Optional custom start endpoint marker (defaults to theme if null)
  /// - [endPoint]: Optional custom end endpoint marker (defaults to theme if null)
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
    String? label,
    String? startLabel,
    String? endLabel,
    this.startPoint,
    this.endPoint,
  }) : _animated = Observable(animated),
       _selected = Observable(selected),
       _label = Observable(label),
       _startLabel = Observable(startLabel),
       _endLabel = Observable(endLabel);

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
  final Observable<String?> _label;
  final Observable<String?> _startLabel;
  final Observable<String?> _endLabel;

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
  /// When true, the connection will display an animated effect (typically
  /// flowing dashes or particles) along the connection path.
  @JsonKey(includeFromJson: false, includeToJson: false)
  bool get animated => _animated.value;

  /// Sets whether the connection shows flowing animation.
  set animated(bool value) => runInAction(() => _animated.value = value);

  /// Whether the connection is currently selected.
  ///
  /// Selected connections typically render with a different color and/or
  /// stroke width as defined by [ConnectionTheme.selectedColor] and
  /// [ConnectionTheme.selectedStrokeWidth].
  @JsonKey(includeFromJson: false, includeToJson: false)
  bool get selected => _selected.value;

  /// Sets whether the connection is currently selected.
  set selected(bool value) => runInAction(() => _selected.value = value);

  /// The center label text displayed on the connection.
  ///
  /// The label is positioned at the midpoint (t=0.5) of the connection path.
  /// Returns null if no center label is set.
  @JsonKey(includeFromJson: false, includeToJson: false)
  String? get label => _label.value;

  /// Sets the center label text.
  set label(String? value) => runInAction(() => _label.value = value);

  /// The start label text displayed near the source endpoint.
  ///
  /// The label is positioned near the start of the connection based on the
  /// source port's position and [LabelTheme] offset settings.
  /// Returns null if no start label is set.
  @JsonKey(includeFromJson: false, includeToJson: false)
  String? get startLabel => _startLabel.value;

  /// Sets the start label text.
  set startLabel(String? value) => runInAction(() => _startLabel.value = value);

  /// The end label text displayed near the target endpoint.
  ///
  /// The label is positioned near the end of the connection based on the
  /// target port's position and [LabelTheme] offset settings.
  /// Returns null if no end label is set.
  @JsonKey(includeFromJson: false, includeToJson: false)
  String? get endLabel => _endLabel.value;

  /// Sets the end label text.
  set endLabel(String? value) => runInAction(() => _endLabel.value = value);

  /// Gets the MobX observable for the center label.
  ///
  /// Use this property when you need to observe label changes in MobX reactions
  /// or computed values. For simple access, use [label] instead.
  @JsonKey(includeFromJson: false, includeToJson: false)
  Observable<String?> get labelObservable => _label;

  /// Gets the MobX observable for the start label.
  ///
  /// Use this property when you need to observe start label changes in MobX
  /// reactions or computed values. For simple access, use [startLabel] instead.
  @JsonKey(includeFromJson: false, includeToJson: false)
  Observable<String?> get startLabelObservable => _startLabel;

  /// Gets the MobX observable for the end label.
  ///
  /// Use this property when you need to observe end label changes in MobX
  /// reactions or computed values. For simple access, use [endLabel] instead.
  @JsonKey(includeFromJson: false, includeToJson: false)
  Observable<String?> get endLabelObservable => _endLabel;

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

  /// Updates the center label of the connection.
  ///
  /// This is a reactive operation that will trigger UI updates in observers.
  ///
  /// Parameters:
  /// - [label]: The new label text, or null to clear the label
  void updateLabel(String? label) {
    runInAction(() => _label.value = label);
  }

  /// Updates the start label of the connection.
  ///
  /// This is a reactive operation that will trigger UI updates in observers.
  ///
  /// Parameters:
  /// - [label]: The new start label text, or null to clear the label
  void updateStartLabel(String? label) {
    runInAction(() => _startLabel.value = label);
  }

  /// Updates the end label of the connection.
  ///
  /// This is a reactive operation that will trigger UI updates in observers.
  ///
  /// Parameters:
  /// - [label]: The new end label text, or null to clear the label
  void updateEndLabel(String? label) {
    runInAction(() => _endLabel.value = label);
  }

  /// Updates multiple labels simultaneously in a single MobX action.
  ///
  /// This is more efficient than calling individual update methods when you
  /// need to update multiple labels at once, as it batches the updates into
  /// a single reactive transaction.
  ///
  /// Parameters:
  /// - [label]: Optional new center label text
  /// - [startLabel]: Optional new start label text
  /// - [endLabel]: Optional new end label text
  ///
  /// Note: Only non-null parameters will update their respective labels.
  void updateLabels({String? label, String? startLabel, String? endLabel}) {
    runInAction(() {
      if (label != null) _label.value = label;
      if (startLabel != null) _startLabel.value = startLabel;
      if (endLabel != null) _endLabel.value = endLabel;
    });
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
    connection._label.value = json['label'] as String?;
    connection._startLabel.value = json['startLabel'] as String?;
    connection._endLabel.value = json['endLabel'] as String?;
    return connection;
  }

  /// Converts this [Connection] to a JSON map.
  ///
  /// This method serializes all connection properties, including observable
  /// values, to a JSON-compatible map.
  Map<String, dynamic> toJson() {
    final json = _$ConnectionToJson(this);
    // Include observable labels in JSON
    json['label'] = _label.value;
    json['startLabel'] = _startLabel.value;
    json['endLabel'] = _endLabel.value;
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
