import 'package:flutter/material.dart';
import 'package:mobx/mobx.dart';

import 'group_annotation.dart';
import 'marker_annotation.dart';
import 'sticky_annotation.dart';

export 'annotation_dependency.dart';
export 'group_annotation.dart';
export 'marker_annotation.dart';
export 'sticky_annotation.dart';

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
