import 'package:flutter/material.dart';

import 'annotation.dart';

/// A sticky note annotation that can be placed anywhere on the canvas.
///
/// Sticky notes are free-floating annotations that can be used for comments,
/// notes, or explanations within your node flow. They support:
/// - Custom text content
/// - Configurable size and color
/// - Free movement and positioning
///
/// ## Example
///
/// ```dart
/// final sticky = StickyAnnotation(
///   id: 'note-1',
///   position: Offset(100, 100),
///   text: 'This is a reminder',
///   width: 200,
///   height: 150,
///   color: Colors.yellow,
/// );
/// controller.annotations.addAnnotation(sticky);
/// ```
class StickyAnnotation extends Annotation {
  StickyAnnotation({
    required super.id,
    required Offset position,
    required this.text,
    this.width = 200.0,
    this.height = 100.0,
    this.color = Colors.yellow,
    int zIndex = 0,
    bool isVisible = true,
    super.selected = false,
    super.isInteractive = true,
    super.metadata,
  }) : super(
         type: 'sticky',
         initialPosition: position,
         initialZIndex: zIndex,
         initialIsVisible: isVisible,
       );

  /// The text content displayed in the sticky note.
  final String text;

  /// The width of the sticky note in pixels.
  final double width;

  /// The height of the sticky note in pixels.
  final double height;

  /// The background color of the sticky note.
  final Color color;

  @override
  Size get size => Size(width, height);

  @override
  Widget buildWidget(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(12),
      child: Text(
        text,
        style: Theme.of(context).textTheme.bodyMedium,
        overflow: TextOverflow.fade,
      ),
    );
  }

  /// Creates a copy of this sticky annotation with optional property overrides.
  ///
  /// This is useful for creating variations of an existing sticky note or
  /// for implementing undo/redo functionality.
  StickyAnnotation copyWith({
    String? id,
    Offset? position,
    String? text,
    double? width,
    double? height,
    Color? color,
    int? zIndex,
    bool? isVisible,
    bool? isInteractive,
    Map<String, dynamic>? metadata,
  }) {
    return StickyAnnotation(
      id: id ?? this.id,
      position: position ?? this.position,
      text: text ?? this.text,
      width: width ?? this.width,
      height: height ?? this.height,
      color: color ?? this.color,
      zIndex: zIndex ?? this.zIndex,
      isVisible: isVisible ?? this.isVisible,
      isInteractive: isInteractive ?? this.isInteractive,
      metadata: metadata ?? this.metadata,
    );
  }

  /// Creates a [StickyAnnotation] from a JSON map.
  ///
  /// This factory method is used during workflow deserialization to recreate
  /// sticky annotations from saved data.
  factory StickyAnnotation.fromJsonMap(Map<String, dynamic> json) {
    return StickyAnnotation(
      id: json['id'] as String,
      position: Offset(
        (json['x'] as num).toDouble(),
        (json['y'] as num).toDouble(),
      ),
      text: json['text'] as String? ?? '',
      width: (json['width'] as num?)?.toDouble() ?? 200.0,
      height: (json['height'] as num?)?.toDouble() ?? 100.0,
      color: Color(json['color'] as int? ?? Colors.yellow.toARGB32()),
      zIndex: json['zIndex'] as int? ?? 0,
      isVisible: json['isVisible'] as bool? ?? true,
      isInteractive: json['isInteractive'] as bool? ?? true,
      metadata: json['metadata'] as Map<String, dynamic>? ?? {},
    );
  }

  @override
  Map<String, dynamic> toJson() => {
    'id': id,
    'type': type,
    'x': position.dx,
    'y': position.dy,
    'text': text,
    'width': width,
    'height': height,
    'color': color.toARGB32(),
    'zIndex': zIndex,
    'isVisible': isVisible,
    'isInteractive': isInteractive,
    'metadata': metadata,
  };

  @override
  void fromJson(Map<String, dynamic> json) {
    final newPosition = Offset(
      (json['x'] as num).toDouble(),
      (json['y'] as num).toDouble(),
    );
    position = newPosition;
    zIndex = json['zIndex'] as int? ?? 0;
    isVisible = json['isVisible'] as bool? ?? true;
  }
}
