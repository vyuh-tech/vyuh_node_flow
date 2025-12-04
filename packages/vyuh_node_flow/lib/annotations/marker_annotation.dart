import 'package:flutter/material.dart';

import 'annotation.dart';

/// Predefined marker types for BPMN-style workflow annotations.
///
/// Each marker type has an associated icon and label for common workflow
/// elements and indicators. Use these to annotate nodes with additional
/// semantic information.
enum MarkerType {
  /// Error or exception indicator
  error(Icons.error, 'Error'),

  /// Warning or caution indicator
  warning(Icons.warning, 'Warning'),

  /// Informational marker
  info(Icons.info, 'Information'),

  /// Timer or time-based event
  timer(Icons.timer, 'Timer'),

  /// Message or communication indicator
  message(Icons.message, 'Message'),

  /// User task requiring human interaction
  user(Icons.person, 'User Task'),

  /// Automated script task
  script(Icons.code, 'Script Task'),

  /// Service or system task
  service(Icons.settings, 'Service Task'),

  /// Manual task performed outside the system
  manual(Icons.pan_tool, 'Manual Task'),

  /// Decision or branching point
  decision(Icons.help_outline, 'Decision Point'),

  /// Sub-process or nested workflow
  subprocess(Icons.call_made, 'Sub-process'),

  /// Milestone or checkpoint
  milestone(Icons.flag, 'Milestone'),

  /// Risk indicator
  risk(Icons.report_problem, 'Risk'),

  /// Compliance or regulatory requirement
  compliance(Icons.verified_user, 'Compliance');

  const MarkerType(this.iconData, this.label);

  /// The icon used to represent this marker type
  final IconData iconData;

  /// The human-readable label for this marker type
  final String label;
}

/// A small visual indicator for workflow elements (BPMN-style markers).
///
/// Markers are compact annotations that attach semantic meaning to nodes
/// or positions in the workflow. They're rendered as circular badges with
/// icons and optional tooltips.
///
/// Common use cases include:
/// - Indicating task types (user, script, service)
/// - Showing status (error, warning, info)
/// - Marking special workflow points (decision, milestone)
/// - Highlighting compliance or risk areas
///
/// ## Example
///
/// ```dart
/// final errorMarker = MarkerAnnotation(
///   id: 'marker-1',
///   position: Offset(150, 200),
///   markerType: MarkerType.error,
///   color: Colors.red,
///   tooltip: 'Validation failed',
/// );
/// controller.annotations.addAnnotation(errorMarker);
/// ```
class MarkerAnnotation extends Annotation {
  MarkerAnnotation({
    required super.id,
    required Offset position,
    this.markerType = MarkerType.info,
    this.markerSize = 24.0,
    this.color = Colors.red,
    this.tooltip,
    int zIndex = 0,
    bool isVisible = true,
    super.selected = false,
    super.isInteractive = true,
    Set<String> dependencies = const {},
    super.offset = Offset.zero,
    super.metadata,
  }) : super(
         type: 'marker',
         initialPosition: position,
         initialZIndex: zIndex,
         initialIsVisible: isVisible,
         initialDependencies: dependencies,
       );

  /// The type of marker, determining its icon and semantic meaning.
  final MarkerType markerType;

  /// The size of the marker in pixels (both width and height).
  final double markerSize;

  /// The color of the marker icon.
  final Color color;

  /// Optional tooltip text shown on hover.
  ///
  /// When null, no tooltip is displayed. When provided, hovering over the
  /// marker shows this text for additional context.
  final String? tooltip;

  @override
  Size get size => Size(markerSize, markerSize);

  @override
  Widget buildWidget(BuildContext context) {
    final widget = Container(
      width: markerSize,
      height: markerSize,
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Icon(markerType.iconData, color: color, size: markerSize * 0.6),
    );

    if (tooltip != null) {
      return Tooltip(message: tooltip!, child: widget);
    }

    return widget;
  }

  /// Creates a copy of this marker annotation with optional property overrides.
  ///
  /// This is useful for creating variations of an existing marker or
  /// for implementing undo/redo functionality.
  MarkerAnnotation copyWith({
    String? id,
    Offset? position,
    MarkerType? markerType,
    double? size,
    Color? color,
    String? tooltip,
    int? zIndex,
    bool? isVisible,
    bool? isInteractive,
    Set<String>? dependencies,
    Map<String, dynamic>? metadata,
  }) {
    return MarkerAnnotation(
      id: id ?? this.id,
      position: position ?? currentPosition,
      markerType: markerType ?? this.markerType,
      markerSize: size ?? markerSize,
      color: color ?? this.color,
      tooltip: tooltip ?? this.tooltip,
      zIndex: zIndex ?? currentZIndex,
      isVisible: isVisible ?? currentIsVisible,
      isInteractive: isInteractive ?? this.isInteractive,
      dependencies: dependencies ?? this.dependencies.toSet(),
      metadata: metadata ?? this.metadata,
    );
  }

  /// Creates a [MarkerAnnotation] from a JSON map.
  ///
  /// This factory method is used during workflow deserialization to recreate
  /// marker annotations from saved data.
  factory MarkerAnnotation.fromJsonMap(Map<String, dynamic> json) {
    final markerTypeName = json['markerType'] as String? ?? 'info';
    final markerType = MarkerType.values.firstWhere(
      (e) => e.name == markerTypeName,
      orElse: () => MarkerType.info,
    );

    final annotation = MarkerAnnotation(
      id: json['id'] as String,
      position: Offset(
        (json['x'] as num).toDouble(),
        (json['y'] as num).toDouble(),
      ),
      markerType: markerType,
      markerSize: (json['markerSize'] as num?)?.toDouble() ?? 24.0,
      color: Color(json['color'] as int? ?? Colors.red.toARGB32()),
      tooltip: json['tooltip'] as String?,
      zIndex: json['zIndex'] as int? ?? 0,
      isVisible: json['isVisible'] as bool? ?? true,
      isInteractive: json['isInteractive'] as bool? ?? true,
      dependencies:
          (json['dependencies'] as List?)?.cast<String>().toSet() ?? {},
      metadata: json['metadata'] as Map<String, dynamic>? ?? {},
    );
    return annotation;
  }

  @override
  Map<String, dynamic> toJson() => {
    'id': id,
    'type': type,
    'x': currentPosition.dx,
    'y': currentPosition.dy,
    'markerType': markerType.name,
    'markerSize': markerSize,
    'color': color.toARGB32(),
    'tooltip': tooltip,
    'zIndex': currentZIndex,
    'isVisible': currentIsVisible,
    'isInteractive': isInteractive,
    'dependencies': dependencies.toList(),
    'metadata': metadata,
  };

  @override
  void fromJson(Map<String, dynamic> json) {
    final newPosition = Offset(
      (json['x'] as num).toDouble(),
      (json['y'] as num).toDouble(),
    );
    setPosition(newPosition);
    // Visual position will be set by controller with snapping
    setZIndex(json['zIndex'] as int? ?? 0);
    setVisible(json['isVisible'] as bool? ?? true);
    dependencies.clear();
    dependencies.addAll((json['dependencies'] as List?)?.cast<String>() ?? []);
  }
}
