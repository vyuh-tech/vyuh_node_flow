import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:mobx/mobx.dart';

import '../graph/node_flow_theme.dart';

/// Base annotation class that can be placed in the node flow
///
/// ## Creating Custom Annotations
///
/// To create a custom annotation, simply extend this class and implement:
/// 1. `Size get size` - Return the dimensions for automatic hit testing
/// 2. `Widget buildWidget(BuildContext context)` - Return your custom widget
///
/// Example:
/// ```dart
/// class CustomAnnotation extends Annotation {
///   final String title;
///   final double width;
///   final double height;
///
///   CustomAnnotation({
///     required super.id,
///     required Offset position,
///     required this.title,
///     this.width = 150.0,
///     this.height = 80.0,
///   }) : super(
///     type: 'custom',
///     initialPosition: position,
///   );
///
///   @override
///   Size get size => Size(width, height);
///
///   @override
///   Widget buildWidget(BuildContext context) {
///     return Container(
///       width: width,
///       height: height,
///       decoration: BoxDecoration(
///         color: Colors.purple,
///         borderRadius: BorderRadius.circular(12),
///       ),
///       child: Center(child: Text(title)),
///     );
///   }
///
///   @override
///   Map<String, dynamic> toJson() => {'title': title, 'width': width, 'height': height};
///
///   @override
///   void fromJson(Map<String, dynamic> json) {
///     // Update properties from json if needed
///   }
/// }
/// ```
///
/// The framework automatically handles:
/// - Hit testing via `containsPoint()` using your `size`
/// - Positioning and coordinate transforms
/// - Selection visual feedback
/// - Drag and drop interactions (if `isInteractive = true`)
/// - Z-index layering and rendering order
/// - MobX reactivity for position and visibility changes
abstract class Annotation {
  Annotation({
    required this.id,
    required this.type,
    required Offset initialPosition,
    int initialZIndex = 0,
    bool initialIsVisible = true,
    bool selected = false,
    this.isInteractive = true,
    Set<String> initialDependencies = const {},
    this.offset = Offset.zero,
    this.metadata = const {},
  }) {
    _position = Observable(initialPosition);
    _visualPosition = Observable(
      initialPosition,
    ); // Initialize to same as position
    _zIndex = Observable(initialZIndex);
    _isVisible = Observable(initialIsVisible);
    _selected = Observable(selected);
    _dependencies = ObservableSet.of(initialDependencies);
  }

  final String id;
  final String type;
  final Map<String, dynamic> metadata;

  // Offset from dependent node (for following annotations)
  final Offset offset;

  // Observable properties for reactivity
  late final Observable<Offset> _position;
  late final Observable<Offset> _visualPosition;
  late final Observable<int> _zIndex;
  late final Observable<bool> _isVisible;
  late final Observable<bool> _selected;
  late final ObservableSet<String> _dependencies;

  // Getters for reactive access
  Observable<Offset> get position => _position;

  Observable<Offset> get visualPosition => _visualPosition;

  Observable<int> get zIndex => _zIndex;

  Observable<bool> get isVisible => _isVisible;

  Observable<bool> get selected => _selected;

  ObservableSet<String> get dependencies => _dependencies;

  // Current values
  Offset get currentPosition => _position.value;

  Offset get currentVisualPosition => _visualPosition.value;

  int get currentZIndex => _zIndex.value;

  bool get currentIsVisible => _isVisible.value;

  bool get currentSelected => _selected.value;

  final bool isInteractive;

  /// Abstract methods that subclasses must implement
  ///
  /// [size] - The dimensions of the annotation for automatic hit testing
  /// [buildWidget] - The visual representation of the annotation
  Size get size;

  Widget buildWidget(BuildContext context);

  /// Automatically calculated bounding rectangle for hit testing
  /// Based on current visual position and size - you don't need to override this
  Rect get bounds => Rect.fromLTWH(
    currentVisualPosition.dx,
    currentVisualPosition.dy,
    size.width,
    size.height,
  );

  // Position and visibility management
  void setPosition(Offset newPosition) {
    runInAction(() {
      _position.value = newPosition;
    });
  }

  /// Updates the visual position (used for rendering with snapping)
  /// This should match the node behavior exactly
  void setVisualPosition(Offset snappedPosition) {
    runInAction(() {
      _visualPosition.value = snappedPosition;
    });
  }

  void setZIndex(int newZIndex) {
    runInAction(() {
      _zIndex.value = newZIndex;
    });
  }

  void setVisible(bool visible) {
    runInAction(() {
      _isVisible.value = visible;
    });
  }

  void setSelected(bool selected) {
    runInAction(() {
      _selected.value = selected;
    });
  }

  // Dependency management
  void addDependency(String nodeId) {
    _dependencies.add(nodeId);
  }

  void removeDependency(String nodeId) {
    _dependencies.remove(nodeId);
  }

  void clearDependencies() {
    _dependencies.clear();
  }

  bool hasDependency(String nodeId) {
    return _dependencies.contains(nodeId);
  }

  bool get hasAnyDependencies => _dependencies.isNotEmpty;

  /// Automatic hit testing based on position and size
  /// Override this only if you need custom hit testing for complex shapes
  bool containsPoint(Offset point) {
    return bounds.contains(point);
  }

  // Serialization support
  Map<String, dynamic> toJson();

  void fromJson(Map<String, dynamic> json);

  // Factory method for creating annotations from JSON
  static Annotation fromJsonByType(Map<String, dynamic> json) {
    final type = json['type'] as String;
    switch (type) {
      case 'sticky':
        return StickyAnnotation.fromJsonMap(json);
      case 'group':
        return GroupAnnotation.fromJsonMap(json);
      case 'checklist_group':
        // This would need to be imported, but for now we'll use regular group
        return GroupAnnotation.fromJsonMap(json);
      case 'marker':
        return MarkerAnnotation.fromJsonMap(json);
      default:
        throw ArgumentError('Unknown annotation type: $type');
    }
  }
}

/// Sticky note annotation - can be placed anywhere and moved freely
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
    Set<String> dependencies = const {},
    super.offset = Offset.zero,
    super.metadata,
  }) : super(
         type: 'sticky',
         initialPosition: position,
         initialZIndex: zIndex,
         initialIsVisible: isVisible,
         initialDependencies: dependencies,
       );

  final String text;
  final double width;
  final double height;
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
    Set<String>? dependencies,
    Offset? offset,
    Map<String, dynamic>? metadata,
  }) {
    return StickyAnnotation(
      id: id ?? this.id,
      position: position ?? currentPosition,
      text: text ?? this.text,
      width: width ?? this.width,
      height: height ?? this.height,
      color: color ?? this.color,
      zIndex: zIndex ?? currentZIndex,
      isVisible: isVisible ?? currentIsVisible,
      isInteractive: isInteractive ?? this.isInteractive,
      dependencies: dependencies ?? this.dependencies.toSet(),
      offset: offset ?? this.offset,
      metadata: metadata ?? this.metadata,
    );
  }

  factory StickyAnnotation.fromJsonMap(Map<String, dynamic> json) {
    return StickyAnnotation(
      id: json['id'] as String,
      position: Offset(json['x'] as double, json['y'] as double),
      text: json['text'] as String? ?? '',
      width: (json['width'] as num?)?.toDouble() ?? 200.0,
      height: (json['height'] as num?)?.toDouble() ?? 100.0,
      color: Color(json['color'] as int? ?? Colors.yellow.toARGB32()),
      zIndex: json['zIndex'] as int? ?? 0,
      isVisible: json['isVisible'] as bool? ?? true,
      isInteractive: json['isInteractive'] as bool? ?? true,
      dependencies:
          (json['dependencies'] as List?)?.cast<String>().toSet() ?? {},
      offset: json['offsetX'] != null && json['offsetY'] != null
          ? Offset(json['offsetX'] as double, json['offsetY'] as double)
          : Offset.zero,
      metadata: json['metadata'] as Map<String, dynamic>? ?? {},
    );
  }

  @override
  Map<String, dynamic> toJson() => {
    'id': id,
    'type': type,
    'x': currentPosition.dx,
    'y': currentPosition.dy,
    'text': text,
    'width': width,
    'height': height,
    'color': color.toARGB32(),
    'zIndex': currentZIndex,
    'isVisible': currentIsVisible,
    'isInteractive': isInteractive,
    'dependencies': dependencies.toList(),
    'offsetX': offset.dx,
    'offsetY': offset.dy,
    'metadata': metadata,
  };

  @override
  void fromJson(Map<String, dynamic> json) {
    final newPosition = Offset(json['x'] as double, json['y'] as double);
    setPosition(newPosition);
    // Visual position will be set by controller with snapping
    setZIndex(json['zIndex'] as int? ?? 0);
    setVisible(json['isVisible'] as bool? ?? true);
    _dependencies.clear();
    _dependencies.addAll((json['dependencies'] as List?)?.cast<String>() ?? []);
  }
}

/// Group annotation - automatically surrounds a set of nodes
class GroupAnnotation extends Annotation {
  GroupAnnotation({
    required super.id,
    required Offset position,
    required String title,
    this.padding = const EdgeInsets.all(20),
    Color color = Colors.blue,
    int zIndex = -1, // Usually behind nodes
    bool isVisible = true,
    super.selected = false,
    super.isInteractive = true, // Groups should be selectable and interactive
    required Set<String> dependencies, // Groups always depend on nodes
    super.offset = Offset.zero,
    super.metadata,
  }) : super(
         type: 'group',
         initialPosition: position,
         initialZIndex: zIndex,
         initialIsVisible: isVisible,
         initialDependencies: dependencies,
       ) {
    _calculatedSize = Observable(const Size(100, 100));
    _observableTitle = Observable(title);
    _observableColor = Observable(color);
  }

  final EdgeInsets padding;

  late final Observable<String> _observableTitle;
  late final Observable<Color> _observableColor;

  late final Observable<Size> _calculatedSize;

  // Getters for observable properties
  Observable<String> get observableTitle => _observableTitle;

  Observable<Color> get observableColor => _observableColor;

  // Current values for easy access
  String get currentTitle => _observableTitle.value;

  Color get currentColor => _observableColor.value;

  @override
  Size get size => _calculatedSize.value;

  void updateCalculatedSize(Size newSize) {
    runInAction(() => _calculatedSize.value = newSize);
  }

  /// Update the group title
  void updateTitle(String newTitle) {
    runInAction(() {
      _observableTitle.value = newTitle;
    });
  }

  /// Update the group color
  void updateColor(Color newColor) {
    runInAction(() {
      _observableColor.value = newColor;
    });
  }

  @override
  Widget buildWidget(BuildContext context) {
    // Get node theme for consistent border radius
    final nodeTheme = Theme.of(context).extension<NodeFlowTheme>()!.nodeTheme;
    final borderRadius = nodeTheme.borderRadius;
    final borderWidth = nodeTheme.borderWidth;

    return Observer(
      builder: (_) {
        // Observe the reactive properties
        final title = currentTitle;
        final color = currentColor;
        final radius = Radius.circular(borderRadius.topLeft.x - borderWidth);

        return Container(
          width: size.width,
          height: size.height,
          color: color.withValues(alpha: 0.1),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.8),
                  borderRadius: BorderRadius.only(
                    topLeft: radius,
                    topRight: radius,
                  ),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                child: Text(
                  title.isNotEmpty ? title : 'Group',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w500,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Expanded(child: Container()), // Empty space for nodes
            ],
          ),
        );
      },
    );
  }

  GroupAnnotation copyWith({
    String? id,
    String? title,
    EdgeInsets? padding,
    Color? color,
    int? zIndex,
    bool? isVisible,
    bool? isInteractive,
    Set<String>? dependencies,
    Map<String, dynamic>? metadata,
  }) {
    return GroupAnnotation(
      id: id ?? this.id,
      position: Offset.zero,
      title: title ?? currentTitle,
      padding: padding ?? this.padding,
      color: color ?? currentColor,
      zIndex: zIndex ?? currentZIndex,
      isVisible: isVisible ?? currentIsVisible,
      isInteractive: isInteractive ?? this.isInteractive,
      dependencies: dependencies ?? this.dependencies.toSet(),
      metadata: metadata ?? this.metadata,
    );
  }

  factory GroupAnnotation.fromJsonMap(Map<String, dynamic> json) {
    final annotation = GroupAnnotation(
      id: json['id'] as String,
      position: Offset(json['x'] as double, json['y'] as double),
      title: json['title'] as String? ?? '',
      padding: json['padding'] != null
          ? EdgeInsets.fromLTRB(
              (json['padding']['left'] as num?)?.toDouble() ?? 20.0,
              (json['padding']['top'] as num?)?.toDouble() ?? 20.0,
              (json['padding']['right'] as num?)?.toDouble() ?? 20.0,
              (json['padding']['bottom'] as num?)?.toDouble() ?? 20.0,
            )
          : const EdgeInsets.all(20),
      color: Color(json['color'] as int? ?? Colors.blue.toARGB32()),
      zIndex: json['zIndex'] as int? ?? -1,
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
    'title': currentTitle,
    'padding': {
      'left': padding.left,
      'top': padding.top,
      'right': padding.right,
      'bottom': padding.bottom,
    },
    'color': currentColor.toARGB32(),
    'zIndex': currentZIndex,
    'isVisible': currentIsVisible,
    'isInteractive': isInteractive,
    'dependencies': dependencies.toList(),
    'metadata': metadata,
  };

  @override
  void fromJson(Map<String, dynamic> json) {
    final newPosition = Offset(json['x'] as double, json['y'] as double);
    setPosition(newPosition);
    setVisualPosition(newPosition); // Initialize visual position to match
    setZIndex(json['zIndex'] as int? ?? -1);
    setVisible(json['isVisible'] as bool? ?? true);
    updateTitle(json['title'] as String? ?? '');
    updateColor(Color(json['color'] as int? ?? Colors.blue.toARGB32()));
    _dependencies.clear();
    _dependencies.addAll((json['dependencies'] as List?)?.cast<String>() ?? []);
  }
}

enum MarkerType {
  error(Icons.error, 'Error'),
  warning(Icons.warning, 'Warning'),
  info(Icons.info, 'Information'),
  timer(Icons.timer, 'Timer'),
  message(Icons.message, 'Message'),
  user(Icons.person, 'User Task'),
  script(Icons.code, 'Script Task'),
  service(Icons.settings, 'Service Task'),
  manual(Icons.pan_tool, 'Manual Task'),
  decision(Icons.help_outline, 'Decision Point'),
  subprocess(Icons.call_made, 'Sub-process'),
  milestone(Icons.flag, 'Milestone'),
  risk(Icons.report_problem, 'Risk'),
  compliance(Icons.verified_user, 'Compliance');

  const MarkerType(this.iconData, this.label);

  final IconData iconData;
  final String label;
}

/// Marker annotation - small visual indicators for BPMN workflow elements
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

  final MarkerType markerType;

  final double markerSize;
  final Color color;
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

  factory MarkerAnnotation.fromJsonMap(Map<String, dynamic> json) {
    final markerTypeName = json['markerType'] as String? ?? 'info';
    final markerType = MarkerType.values.firstWhere(
      (e) => e.name == markerTypeName,
      orElse: () => MarkerType.info,
    );

    final annotation = MarkerAnnotation(
      id: json['id'] as String,
      position: Offset(json['x'] as double, json['y'] as double),
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
    final newPosition = Offset(json['x'] as double, json['y'] as double);
    setPosition(newPosition);
    // Visual position will be set by controller with snapping
    setZIndex(json['zIndex'] as int? ?? 0);
    setVisible(json['isVisible'] as bool? ?? true);
    _dependencies.clear();
    _dependencies.addAll((json['dependencies'] as List?)?.cast<String>() ?? []);
  }
}

/// Annotation dependency types for different update behaviors
enum AnnotationDependencyType {
  /// Annotation follows node movements
  follow,

  /// Annotation surrounds/encompasses nodes
  surround,

  /// Annotation is linked but doesn't move automatically
  linked,
}

/// Represents a dependency relationship between an annotation and nodes
class AnnotationDependency {
  const AnnotationDependency({
    required this.nodeId,
    required this.type,
    this.metadata = const {},
  });

  final String nodeId;
  final AnnotationDependencyType type;
  final Map<String, dynamic> metadata;
}
