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

  /// Unique identifier for this annotation.
  ///
  /// This ID is used for selection, hit testing, and referencing the annotation
  /// throughout the node flow system.
  final String id;

  /// The type of annotation (e.g., 'sticky', 'group', 'marker').
  ///
  /// This type is used for serialization and deserialization, allowing the framework
  /// to recreate the correct annotation subclass from JSON.
  final String type;

  /// Additional metadata for custom data storage.
  ///
  /// Use this map to store any custom data associated with the annotation.
  /// This metadata is automatically serialized and deserialized with the annotation.
  final Map<String, dynamic> metadata;

  /// Offset from dependent node position (for following annotations).
  ///
  /// When an annotation follows a node (via dependencies), this offset determines
  /// how far from the node's center the annotation should be positioned.
  /// Default is [Offset.zero] for centered positioning.
  final Offset offset;

  // Observable properties for reactivity - these are observed by the framework
  // for automatic UI updates when properties change
  late final Observable<Offset> _position;
  late final Observable<Offset> _visualPosition;
  late final Observable<int> _zIndex;
  late final Observable<bool> _isVisible;
  late final Observable<bool> _selected;
  late final ObservableSet<String> _dependencies;

  /// Reactive observable for the annotation's logical position.
  ///
  /// This is the "true" position of the annotation before any grid snapping.
  /// The framework observes this for automatic UI updates.
  Observable<Offset> get position => _position;

  /// Reactive observable for the annotation's visual position.
  ///
  /// This is the snapped position that's actually rendered on screen.
  /// When grid snapping is enabled, this may differ from [position].
  Observable<Offset> get visualPosition => _visualPosition;

  /// Reactive observable for the annotation's z-index (rendering order).
  ///
  /// Lower values are rendered first (behind), higher values are rendered last (in front).
  /// Group annotations typically have negative z-index to appear behind nodes.
  Observable<int> get zIndex => _zIndex;

  /// Reactive observable for the annotation's visibility state.
  ///
  /// When false, the annotation is hidden from the canvas.
  Observable<bool> get isVisible => _isVisible;

  /// Reactive observable for the annotation's selection state.
  ///
  /// When true, the annotation displays selection feedback (border/highlight).
  Observable<bool> get selected => _selected;

  /// Reactive observable set of node IDs this annotation depends on.
  ///
  /// For group annotations, these are the nodes contained within the group.
  /// For following annotations, these are the nodes the annotation tracks.
  ObservableSet<String> get dependencies => _dependencies;

  /// The current logical position value (non-reactive).
  ///
  /// Use this for calculations where you don't need reactive updates.
  /// For reactive access, use [position] instead.
  Offset get currentPosition => _position.value;

  /// The current visual (snapped) position value (non-reactive).
  ///
  /// This is what's actually rendered on screen after grid snapping.
  /// For reactive access, use [visualPosition] instead.
  Offset get currentVisualPosition => _visualPosition.value;

  /// The current z-index value (non-reactive).
  ///
  /// For reactive access, use [zIndex] instead.
  int get currentZIndex => _zIndex.value;

  /// The current visibility state (non-reactive).
  ///
  /// For reactive access, use [isVisible] instead.
  bool get currentIsVisible => _isVisible.value;

  /// The current selection state (non-reactive).
  ///
  /// For reactive access, use [selected] instead.
  bool get currentSelected => _selected.value;

  /// Whether this annotation responds to user interactions.
  ///
  /// When false, the annotation cannot be selected, dragged, or clicked.
  /// Useful for purely decorative or informational annotations.
  final bool isInteractive;

  /// The dimensions of the annotation for automatic hit testing.
  ///
  /// This size is used by the framework to:
  /// - Calculate the bounding box for hit testing (see [containsPoint])
  /// - Position selection highlights and borders
  /// - Compute layout and rendering bounds
  ///
  /// Subclasses must implement this to return the annotation's current size.
  Size get size;

  /// Builds the visual representation of the annotation.
  ///
  /// This method is called by the framework to render the annotation's content.
  /// Implement this to define how your custom annotation appears on the canvas.
  ///
  /// The framework automatically wraps your widget with:
  /// - Positioning logic (using [visualPosition])
  /// - Selection visual feedback
  /// - Theme-consistent borders and highlights
  ///
  /// ## Example
  ///
  /// ```dart
  /// @override
  /// Widget buildWidget(BuildContext context) {
  ///   return Container(
  ///     width: size.width,
  ///     height: size.height,
  ///     decoration: BoxDecoration(
  ///       color: Colors.blue,
  ///       borderRadius: BorderRadius.circular(8),
  ///     ),
  ///     child: Center(child: Text('My Annotation')),
  ///   );
  /// }
  /// ```
  Widget buildWidget(BuildContext context);

  /// Automatically calculated bounding rectangle for hit testing.
  ///
  /// Based on [currentVisualPosition] and [size]. The framework uses this
  /// for automatic hit testing in [containsPoint].
  ///
  /// You typically don't need to override this unless you have a custom shape
  /// that requires non-rectangular hit testing.
  Rect get bounds => Rect.fromLTWH(
    currentVisualPosition.dx,
    currentVisualPosition.dy,
    size.width,
    size.height,
  );

  /// Sets the annotation's logical position.
  ///
  /// This is the "true" position before grid snapping. The framework will
  /// automatically update [visualPosition] with the snapped value.
  ///
  /// Use this when programmatically positioning annotations.
  void setPosition(Offset newPosition) {
    runInAction(() {
      _position.value = newPosition;
    });
  }

  /// Updates the visual position (used for rendering with grid snapping).
  ///
  /// This is called by the framework to set the snapped position that's
  /// actually rendered on screen. This should match node behavior exactly
  /// for consistent grid alignment.
  ///
  /// Generally, you don't need to call this directly - the framework handles
  /// it automatically when you call [setPosition].
  void setVisualPosition(Offset snappedPosition) {
    runInAction(() {
      _visualPosition.value = snappedPosition;
    });
  }

  /// Sets the annotation's z-index (rendering order).
  ///
  /// Lower values are rendered first (behind), higher values last (in front).
  /// Group annotations typically use negative z-index (e.g., -1) to appear
  /// behind nodes.
  void setZIndex(int newZIndex) {
    runInAction(() {
      _zIndex.value = newZIndex;
    });
  }

  /// Sets the annotation's visibility state.
  ///
  /// When set to false, the annotation is hidden from the canvas but remains
  /// in the controller's annotation collection.
  void setVisible(bool visible) {
    runInAction(() {
      _isVisible.value = visible;
    });
  }

  /// Sets the annotation's selection state.
  ///
  /// When true, the annotation displays selection visual feedback (border/highlight).
  /// This is typically managed by the framework, but can be called directly for
  /// custom selection logic.
  void setSelected(bool selected) {
    runInAction(() {
      _selected.value = selected;
    });
  }

  /// Adds a node dependency to this annotation.
  ///
  /// For group annotations, the node will be contained within the group.
  /// For following annotations, the annotation will track the node's position.
  void addDependency(String nodeId) {
    _dependencies.add(nodeId);
  }

  /// Removes a node dependency from this annotation.
  ///
  /// The annotation will no longer track or contain the specified node.
  void removeDependency(String nodeId) {
    _dependencies.remove(nodeId);
  }

  /// Clears all node dependencies from this annotation.
  ///
  /// The annotation becomes independent and will not track any nodes.
  void clearDependencies() {
    _dependencies.clear();
  }

  /// Checks if this annotation depends on a specific node.
  ///
  /// Returns true if the node ID is in the annotation's dependencies.
  bool hasDependency(String nodeId) {
    return _dependencies.contains(nodeId);
  }

  /// Whether this annotation has any node dependencies.
  ///
  /// Returns true if the annotation depends on at least one node.
  bool get hasAnyDependencies => _dependencies.isNotEmpty;

  /// Automatic hit testing based on position and size.
  ///
  /// Returns true if the given point intersects with this annotation's [bounds].
  ///
  /// Override this only if you need custom hit testing for complex shapes
  /// (e.g., circular annotations, irregular polygons).
  ///
  /// ## Example of custom hit testing for a circular annotation:
  ///
  /// ```dart
  /// @override
  /// bool containsPoint(Offset point) {
  ///   final center = Offset(
  ///     currentVisualPosition.dx + size.width / 2,
  ///     currentVisualPosition.dy + size.height / 2,
  ///   );
  ///   final radius = size.width / 2;
  ///   return (point - center).distance <= radius;
  /// }
  /// ```
  bool containsPoint(Offset point) {
    return bounds.contains(point);
  }

  /// Serializes this annotation to JSON.
  ///
  /// Implement this to define how your custom annotation is persisted.
  /// Include all properties needed to recreate the annotation.
  ///
  /// The JSON should include at minimum:
  /// - 'id': The annotation's unique identifier
  /// - 'type': The annotation type string
  /// - 'x', 'y': Position coordinates
  /// - Any custom properties specific to your annotation
  Map<String, dynamic> toJson();

  /// Deserializes JSON data into this annotation.
  ///
  /// Implement this to update the annotation's properties from persisted data.
  /// This is called when loading saved workflows.
  ///
  /// You typically update position, visibility, z-index, and any custom properties.
  void fromJson(Map<String, dynamic> json);

  /// Factory method for creating annotations from JSON based on type.
  ///
  /// This is used by the framework when deserializing saved workflows.
  /// It reads the 'type' field and creates the appropriate annotation subclass.
  ///
  /// To support custom annotation types, you'll need to extend this method
  /// or provide your own deserialization logic.
  ///
  /// ## Parameters
  /// - [json]: The JSON map containing the annotation data
  ///
  /// ## Returns
  /// An [Annotation] instance of the appropriate subclass
  ///
  /// ## Throws
  /// - [ArgumentError] if the annotation type is unknown
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

/// A sticky note annotation that can be placed anywhere on the canvas.
///
/// Sticky notes are free-floating annotations that can be used for comments,
/// notes, or explanations within your node flow. They support:
/// - Custom text content
/// - Configurable size and color
/// - Free movement and positioning
/// - Optional node dependencies for tracking
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
      dependencies:
          (json['dependencies'] as List?)?.cast<String>().toSet() ?? {},
      offset: json['offsetX'] != null && json['offsetY'] != null
          ? Offset(
              (json['offsetX'] as num).toDouble(),
              (json['offsetY'] as num).toDouble(),
            )
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
    final newPosition = Offset(
      (json['x'] as num).toDouble(),
      (json['y'] as num).toDouble(),
    );
    setPosition(newPosition);
    // Visual position will be set by controller with snapping
    setZIndex(json['zIndex'] as int? ?? 0);
    setVisible(json['isVisible'] as bool? ?? true);
    _dependencies.clear();
    _dependencies.addAll((json['dependencies'] as List?)?.cast<String>() ?? []);
  }
}

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
    _dependencies.clear();
    _dependencies.addAll((json['dependencies'] as List?)?.cast<String>() ?? []);
  }
}

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
    _dependencies.clear();
    _dependencies.addAll((json['dependencies'] as List?)?.cast<String>() ?? []);
  }
}

/// Defines how an annotation responds to changes in dependent nodes.
///
/// Different dependency types enable different behaviors for annotations
/// that track or relate to nodes in the workflow.
enum AnnotationBehavior {
  /// Annotation follows node movements.
  ///
  /// The annotation automatically updates its position to track the center
  /// of its dependent nodes. Useful for badges, labels, or indicators that
  /// should stay with specific nodes.
  follow,

  /// Annotation surrounds/encompasses nodes.
  ///
  /// The annotation's bounds automatically expand to contain all dependent
  /// nodes. This is used by [GroupAnnotation] to create visual boundaries
  /// around node sets.
  surround,

  /// Annotation is linked but doesn't move automatically.
  ///
  /// The annotation maintains a relationship with nodes but doesn't update
  /// its position. Useful for connections or references that should persist
  /// but remain stationary.
  linked,
}

/// Represents a dependency relationship between an annotation and a node.
///
/// This class encapsulates the details of how an annotation relates to a
/// specific node, including the dependency type and optional metadata.
///
/// ## Example
///
/// ```dart
/// final dependency = AnnotationDependency(
///   nodeId: 'node-1',
///   type: AnnotationBehavior.follow,
///   metadata: {'offset': Offset(10, -20)},
/// );
/// ```
class AnnotationDependency {
  /// Creates an annotation dependency.
  ///
  /// ## Parameters
  /// - [nodeId]: The ID of the node this dependency references
  /// - [type]: The type of dependency behavior
  /// - [metadata]: Optional custom data for this dependency
  const AnnotationDependency({
    required this.nodeId,
    required this.type,
    this.metadata = const {},
  });

  /// The ID of the node this dependency references.
  final String nodeId;

  /// The type of dependency behavior (follow, surround, or linked).
  final AnnotationBehavior type;

  /// Optional custom metadata for this dependency.
  ///
  /// Use this to store additional data specific to this node relationship,
  /// such as custom offsets, priority, or behavioral flags.
  final Map<String, dynamic> metadata;
}
