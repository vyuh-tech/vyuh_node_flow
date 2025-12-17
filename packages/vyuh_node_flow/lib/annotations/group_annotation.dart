import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:mobx/mobx.dart';

import '../graph/node_flow_theme.dart';
import 'annotation.dart';

/// A group annotation that automatically surrounds and contains a set of nodes.
///
/// Group annotations create visual boundaries around related nodes, making it
/// easier to organize complex workflows. They feature:
/// - Automatic sizing based on contained nodes
/// - Customizable title and color
/// - Automatic position updates when nodes move
/// - Support for moving all contained nodes together
/// - Typically rendered behind nodes (negative z-index)
///
/// Groups maintain node dependencies and automatically recalculate their bounds
/// when dependent nodes are moved, resized, or added/removed.
///
/// ## Example
///
/// ```dart
/// final group = controller.annotations.createGroupAnnotation(
///   id: 'group-1',
///   title: 'Data Processing',
///   nodeIds: {'node1', 'node2', 'node3'},
///   nodes: controller.nodes,
///   color: Colors.blue,
///   padding: EdgeInsets.all(20),
/// );
/// controller.annotations.addAnnotation(group);
/// ```
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

  /// The padding around contained nodes.
  ///
  /// This space is added around the bounding box of all dependent nodes to
  /// provide visual separation between the group boundary and the nodes.
  final EdgeInsets padding;

  late final Observable<String> _observableTitle;
  late final Observable<Color> _observableColor;

  late final Observable<Size> _calculatedSize;

  /// Reactive observable for the group's title.
  ///
  /// The title is displayed in the group's header bar and updates automatically
  /// when changed via [updateTitle].
  Observable<String> get observableTitle => _observableTitle;

  /// Reactive observable for the group's color.
  ///
  /// The color affects the group's header bar and background tint.
  Observable<Color> get observableColor => _observableColor;

  /// The current title value (non-reactive).
  ///
  /// For reactive access, use [observableTitle] instead.
  String get currentTitle => _observableTitle.value;

  /// The current color value (non-reactive).
  ///
  /// For reactive access, use [observableColor] instead.
  Color get currentColor => _observableColor.value;

  @override
  Size get size => _calculatedSize.value;

  /// Updates the group's calculated size.
  ///
  /// This is called by the framework when the group's bounds change due to
  /// node movement, addition, or removal. You typically don't need to call
  /// this directly.
  void updateCalculatedSize(Size newSize) {
    runInAction(() => _calculatedSize.value = newSize);
  }

  /// Updates the group's title.
  ///
  /// The title appears in the group's header bar and is automatically saved
  /// when serializing the workflow.
  void updateTitle(String newTitle) {
    runInAction(() {
      _observableTitle.value = newTitle;
    });
  }

  /// Updates the group's color.
  ///
  /// The color affects both the header bar (solid) and background (translucent).
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
        // Observe all reactive properties including size
        final title = currentTitle;
        final color = currentColor;
        final currentSize = _calculatedSize.value; // Explicitly observe size
        final radius = Radius.circular(borderRadius.topLeft.x - borderWidth);

        return Container(
          width: currentSize.width,
          height: currentSize.height,
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

  /// Creates a copy of this group annotation with optional property overrides.
  ///
  /// This is useful for creating variations of an existing group or
  /// for implementing undo/redo functionality.
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

  /// Creates a [GroupAnnotation] from a JSON map.
  ///
  /// This factory method is used during workflow deserialization to recreate
  /// group annotations from saved data.
  factory GroupAnnotation.fromJsonMap(Map<String, dynamic> json) {
    final annotation = GroupAnnotation(
      id: json['id'] as String,
      position: Offset(
        (json['x'] as num).toDouble(),
        (json['y'] as num).toDouble(),
      ),
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
    final newPosition = Offset(
      (json['x'] as num).toDouble(),
      (json['y'] as num).toDouble(),
    );
    setPosition(newPosition);
    setVisualPosition(newPosition); // Initialize visual position to match
    setZIndex(json['zIndex'] as int? ?? -1);
    setVisible(json['isVisible'] as bool? ?? true);
    updateTitle(json['title'] as String? ?? '');
    updateColor(Color(json['color'] as int? ?? Colors.blue.toARGB32()));
    dependencies.clear();
    dependencies.addAll((json['dependencies'] as List?)?.cast<String>() ?? []);
  }
}
