import 'package:json_annotation/json_annotation.dart';
import 'package:mobx/mobx.dart';

import 'connection_endpoint.dart';
import 'connection_style_base.dart';
import 'connection_styles.dart';

part 'connection.g.dart';

@JsonSerializable()
class Connection {
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

  final String id;
  final String sourceNodeId;
  final String sourcePortId;
  final String targetNodeId;
  final String targetPortId;

  final Observable<bool> _animated;
  final Observable<bool> _selected;
  final Observable<String?> _label;
  final Observable<String?> _startLabel;
  final Observable<String?> _endLabel;
  final Map<String, dynamic>? data;

  @JsonKey(fromJson: _connectionStyleFromJson, toJson: _connectionStyleToJson)
  final ConnectionStyle? style;
  final ConnectionEndPoint? startPoint;
  final ConnectionEndPoint? endPoint;

  // Getters for accessing the values
  @JsonKey(includeFromJson: false, includeToJson: false)
  bool get animated => _animated.value;

  set animated(bool value) => runInAction(() => _animated.value = value);

  @JsonKey(includeFromJson: false, includeToJson: false)
  bool get selected => _selected.value;

  set selected(bool value) => runInAction(() => _selected.value = value);

  @JsonKey(includeFromJson: false, includeToJson: false)
  String? get label => _label.value;

  set label(String? value) => runInAction(() => _label.value = value);

  @JsonKey(includeFromJson: false, includeToJson: false)
  String? get startLabel => _startLabel.value;

  set startLabel(String? value) => runInAction(() => _startLabel.value = value);

  @JsonKey(includeFromJson: false, includeToJson: false)
  String? get endLabel => _endLabel.value;

  set endLabel(String? value) => runInAction(() => _endLabel.value = value);

  /// Observable getter for center label - use this for reactive UI updates
  @JsonKey(includeFromJson: false, includeToJson: false)
  Observable<String?> get labelObservable => _label;

  /// Observable getter for start label - use this for reactive UI updates
  @JsonKey(includeFromJson: false, includeToJson: false)
  Observable<String?> get startLabelObservable => _startLabel;

  /// Observable getter for end label - use this for reactive UI updates
  @JsonKey(includeFromJson: false, includeToJson: false)
  Observable<String?> get endLabelObservable => _endLabel;

  /// Checks if this connection involves the given node
  bool involvesNode(String nodeId) {
    return sourceNodeId == nodeId || targetNodeId == nodeId;
  }

  /// Checks if this connection involves the given port
  bool involvesPort(String nodeId, String portId) {
    return (sourceNodeId == nodeId && sourcePortId == portId) ||
        (targetNodeId == nodeId && targetPortId == portId);
  }

  /// Updates the center label of the connection
  void updateLabel(String? label) {
    runInAction(() => _label.value = label);
  }

  /// Updates the start label of the connection
  void updateStartLabel(String? label) {
    runInAction(() => _startLabel.value = label);
  }

  /// Updates the end label of the connection
  void updateEndLabel(String? label) {
    runInAction(() => _endLabel.value = label);
  }

  /// Updates all labels simultaneously
  void updateLabels({String? label, String? startLabel, String? endLabel}) {
    runInAction(() {
      if (label != null) _label.value = label;
      if (startLabel != null) _startLabel.value = startLabel;
      if (endLabel != null) _endLabel.value = endLabel;
    });
  }

  /// Gets the effective connection style, using instance override or falling back to theme
  ConnectionStyle getEffectiveStyle(ConnectionStyle themeStyle) {
    return style ?? themeStyle;
  }

  /// Gets the effective start point, using instance override or falling back to theme
  ConnectionEndPoint getEffectiveStartPoint(
    ConnectionEndPoint themeStartPoint,
  ) {
    return startPoint ?? themeStartPoint;
  }

  /// Gets the effective end point, using instance override or falling back to theme
  ConnectionEndPoint getEffectiveEndPoint(ConnectionEndPoint themeEndPoint) {
    return endPoint ?? themeEndPoint;
  }

  void dispose() {
    // MobX observables don't need manual disposal
  }

  factory Connection.fromJson(Map<String, dynamic> json) {
    final connection = _$ConnectionFromJson(json);
    // Initialize observable labels from JSON
    connection._label.value = json['label'] as String?;
    connection._startLabel.value = json['startLabel'] as String?;
    connection._endLabel.value = json['endLabel'] as String?;
    return connection;
  }

  Map<String, dynamic> toJson() {
    final json = _$ConnectionToJson(this);
    // Include observable labels in JSON
    json['label'] = _label.value;
    json['startLabel'] = _startLabel.value;
    json['endLabel'] = _endLabel.value;
    return json;
  }
}

/// JSON serialization helpers
ConnectionStyle? _connectionStyleFromJson(dynamic json) {
  if (json == null) return null;

  if (json is String) {
    return ConnectionStyles.findById(json) ?? ConnectionStyles.smoothstep;
  }

  return ConnectionStyles.smoothstep; // Default fallback
}

dynamic _connectionStyleToJson(ConnectionStyle? style) {
  return style?.id;
}
