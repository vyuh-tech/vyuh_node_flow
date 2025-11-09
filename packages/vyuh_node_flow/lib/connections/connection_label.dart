import 'package:json_annotation/json_annotation.dart';
import 'package:mobx/mobx.dart';

import 'connection_anchor.dart';

part 'connection_label.g.dart';

/// Represents a label that can be positioned on a connection path.
///
/// Each label has:
/// - [text]: The label content to display
/// - [anchor]: Position along the path (0.0 = source, 1.0 = target, 0.5 = center)
/// - [offset]: Perpendicular offset from the path (positive = one side, negative = other)
/// - [id]: Optional identifier for programmatic access
///
/// All properties are observable for reactive UI updates.
///
/// ## Usage Example
/// ```dart
/// // Using factory constructors (recommended)
/// final startLabel = ConnectionLabel.start(text: 'Start');
/// final centerLabel = ConnectionLabel.center(text: 'Processing', offset: 5.0);
/// final endLabel = ConnectionLabel.end(text: 'Complete');
///
/// // Or using the default constructor with explicit anchor
/// final customLabel = ConnectionLabel(text: 'Custom', anchor: 0.25, offset: -10.0);
/// ```
@JsonSerializable()
class ConnectionLabel {
  /// Observable text content of the label
  final Observable<String> _text;

  /// Observable position along the connection path (0.0 to 1.0)
  /// - 0.0: at the source (start) of the connection
  /// - 0.5: at the center of the connection
  /// - 1.0: at the target (end) of the connection
  final Observable<double> _anchor;

  /// Observable perpendicular offset from the connection path
  /// - Positive values: offset to one side
  /// - Negative values: offset to the other side
  /// - 0.0: label sits directly on the path
  final Observable<double> _offset;

  /// Unique identifier for this label
  /// Useful for programmatically finding and updating specific labels
  final String id;

  ConnectionLabel({
    required String text,
    double anchor = ConnectionAnchor.center,
    double offset = 0.0,
    String? id,
  }) : assert(
         anchor >= 0.0 && anchor <= 1.0,
         'anchor must be between 0.0 and 1.0',
       ),
       _text = Observable(text),
       _anchor = Observable(anchor),
       _offset = Observable(offset),
       id = id ?? _generateId();

  /// Creates a label positioned at the start of the connection (anchor 0.0).
  factory ConnectionLabel.start({
    required String text,
    double offset = 0.0,
    String? id,
  }) => ConnectionLabel(
    text: text,
    anchor: ConnectionAnchor.start,
    offset: offset,
    id: id,
  );

  /// Creates a label positioned at the center of the connection (anchor 0.5).
  factory ConnectionLabel.center({
    required String text,
    double offset = 0.0,
    String? id,
  }) => ConnectionLabel(
    text: text,
    anchor: ConnectionAnchor.center,
    offset: offset,
    id: id,
  );

  /// Creates a label positioned at the end of the connection (anchor 1.0).
  factory ConnectionLabel.end({
    required String text,
    double offset = 0.0,
    String? id,
  }) => ConnectionLabel(
    text: text,
    anchor: ConnectionAnchor.end,
    offset: offset,
    id: id,
  );

  /// The text content of the label
  String get text => _text.value;

  /// The position along the connection path (0.0 to 1.0)
  double get anchor => _anchor.value;

  /// The perpendicular offset from the connection path
  double get offset => _offset.value;

  /// Updates the label text
  void updateText(String text) {
    runInAction(() {
      _text.value = text;
    });
  }

  /// Updates the anchor position (0.0 to 1.0)
  void updateAnchor(double anchor) {
    assert(
      anchor >= 0.0 && anchor <= 1.0,
      'anchor must be between 0.0 and 1.0',
    );
    runInAction(() {
      _anchor.value = anchor;
    });
  }

  /// Updates the perpendicular offset
  void updateOffset(double offset) {
    runInAction(() {
      _offset.value = offset;
    });
  }

  /// Updates multiple properties at once
  void update({String? text, double? anchor, double? offset}) {
    runInAction(() {
      if (text != null) _text.value = text;
      if (anchor != null) {
        assert(
          anchor >= 0.0 && anchor <= 1.0,
          'anchor must be between 0.0 and 1.0',
        );
        _anchor.value = anchor;
      }
      if (offset != null) _offset.value = offset;
    });
  }

  /// Creates a ConnectionLabel from JSON
  factory ConnectionLabel.fromJson(Map<String, dynamic> json) {
    final label = _$ConnectionLabelFromJson(json);
    // Initialize observables from JSON
    label._text.value = json['text'] as String;
    label._anchor.value = (json['anchor'] as num?)?.toDouble() ?? 0.5;
    label._offset.value = (json['offset'] as num?)?.toDouble() ?? 0.0;
    return label;
  }

  /// Converts this ConnectionLabel to JSON
  Map<String, dynamic> toJson() {
    final json = _$ConnectionLabelToJson(this);
    // Include observable values in JSON
    json['text'] = _text.value;
    json['anchor'] = _anchor.value;
    json['offset'] = _offset.value;
    return json;
  }

  /// Generates a unique ID for the label
  static String _generateId() {
    return 'label_${DateTime.now().microsecondsSinceEpoch}_${_idCounter++}';
  }

  static int _idCounter = 0;

  @override
  String toString() {
    return 'ConnectionLabel(id: $id, text: $text, anchor: $anchor, offset: $offset)';
  }
}
