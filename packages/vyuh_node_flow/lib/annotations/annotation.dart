import 'package:flutter/material.dart';
import 'package:mobx/mobx.dart';

import '../nodes/node.dart';
import 'annotation_drag_context.dart';

export 'annotation_drag_context.dart';
export 'group_annotation.dart';
export 'marker_annotation.dart';
export 'sticky_annotation.dart';

/// The rendering layer for an annotation.
///
/// Annotations are rendered in two layers relative to nodes:
/// - [background]: Behind nodes (e.g., group boxes)
/// - [foreground]: Above nodes and connections (e.g., sticky notes, markers)
enum AnnotationRenderLayer {
  /// Rendered behind nodes.
  ///
  /// Use this for annotations that should appear as backgrounds or containers,
  /// such as [GroupAnnotation].
  background,

  /// Rendered above nodes and connections.
  ///
  /// Use this for annotations that should overlay the canvas content,
  /// such as [StickyAnnotation] and [MarkerAnnotation].
  foreground,
}

/// Callback type for looking up nodes by ID.
///
/// Used by annotations that need to access node data during lifecycle
/// operations like fitting bounds or responding to node changes.
typedef NodeLookup = Node? Function(String nodeId);

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
    this.metadata = const {},
  }) {
    _position = Observable(initialPosition);
    _visualPosition = Observable(
      initialPosition,
    ); // Initialize to same as position
    _zIndex = Observable(initialZIndex);
    _isVisible = Observable(initialIsVisible);
    _selected = Observable(selected);
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

  /// The rendering layer for this annotation.
  ///
  /// Determines whether the annotation is rendered behind nodes ([AnnotationRenderLayer.background])
  /// or above nodes and connections ([AnnotationRenderLayer.foreground]).
  ///
  /// Override in subclasses to specify the layer. Default is [AnnotationRenderLayer.foreground].
  /// [GroupAnnotation] overrides this to return [AnnotationRenderLayer.background].
  AnnotationRenderLayer get layer => AnnotationRenderLayer.foreground;

  // Internal observables for MobX reactivity
  late final Observable<Offset> _position;
  late final Observable<Offset> _visualPosition;
  late final Observable<int> _zIndex;
  late final Observable<bool> _isVisible;
  late final Observable<bool> _selected;

  /// The annotation's logical position (before grid snapping).
  ///
  /// Reading this inside an `Observer` widget automatically tracks changes.
  /// The visual position (after snapping) is [visualPosition].
  Offset get position => _position.value;

  set position(Offset value) => runInAction(() => _position.value = value);

  /// The annotation's visual position (after grid snapping).
  ///
  /// This is what's actually rendered on screen.
  /// Reading this inside an `Observer` widget automatically tracks changes.
  Offset get visualPosition => _visualPosition.value;

  set visualPosition(Offset value) =>
      runInAction(() => _visualPosition.value = value);

  /// The annotation's z-index (rendering order within its layer).
  ///
  /// Lower values render first (behind), higher values render last (in front).
  /// Reading this inside an `Observer` widget automatically tracks changes.
  int get zIndex => _zIndex.value;

  set zIndex(int value) => runInAction(() => _zIndex.value = value);

  /// Whether the annotation is visible.
  ///
  /// When false, the annotation is hidden from the canvas.
  /// Reading this inside an `Observer` widget automatically tracks changes.
  bool get isVisible => _isVisible.value;

  set isVisible(bool value) => runInAction(() => _isVisible.value = value);

  /// Whether the annotation is currently selected.
  ///
  /// When true, displays selection visual feedback.
  /// Reading this inside an `Observer` widget automatically tracks changes.
  bool get selected => _selected.value;

  set selected(bool value) => runInAction(() => _selected.value = value);

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
  /// Based on [visualPosition] and [size]. The framework uses this
  /// for automatic hit testing in [containsPoint].
  ///
  /// You typically don't need to override this unless you have a custom shape
  /// that requires non-rectangular hit testing.
  Rect get bounds => Rect.fromLTWH(
    visualPosition.dx,
    visualPosition.dy,
    size.width,
    size.height,
  );

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

  // ============================================================
  // Drag Lifecycle Methods
  // ============================================================

  /// Called when a drag operation starts on this annotation.
  ///
  /// Override this method to perform setup when the user begins dragging
  /// this annotation. Use the [context] to capture state, such as which
  /// nodes are contained within a group annotation.
  ///
  /// ## Example
  ///
  /// ```dart
  /// Set<String>? _containedNodeIds;
  ///
  /// @override
  /// void onDragStart(AnnotationDragContext context) {
  ///   _containedNodeIds = context.findNodesInBounds(bounds);
  /// }
  /// ```
  void onDragStart(AnnotationDragContext context) {
    // Default implementation does nothing
  }

  /// Called during drag with the movement delta.
  ///
  /// Override this method to perform actions while the annotation is being
  /// dragged. Use the [context] to move related nodes or perform other
  /// operations. The [delta] is in graph coordinates.
  ///
  /// ## Example
  ///
  /// ```dart
  /// @override
  /// void onDragMove(Offset delta, AnnotationDragContext context) {
  ///   if (_containedNodeIds != null && _containedNodeIds!.isNotEmpty) {
  ///     context.moveNodes(_containedNodeIds!, delta);
  ///   }
  /// }
  /// ```
  void onDragMove(Offset delta, AnnotationDragContext context) {
    // Default implementation does nothing
  }

  /// Called when a drag operation ends on this annotation.
  ///
  /// Override this method to perform cleanup after dragging completes.
  /// This is called whether the drag ended normally or was cancelled.
  ///
  /// ## Example
  ///
  /// ```dart
  /// @override
  /// void onDragEnd() {
  ///   _containedNodeIds = null;
  /// }
  /// ```
  void onDragEnd() {
    // Default implementation does nothing
  }

  // ============================================================
  // Node Lifecycle Methods
  // ============================================================

  /// Called when nodes are deleted from the graph.
  ///
  /// Override this method to respond when nodes that this annotation
  /// tracks or contains are deleted.
  ///
  /// The [context] provides access to remaining nodes for operations
  /// like refitting bounds.
  ///
  /// For [GroupAnnotation], this removes nodes from explicit membership
  /// and triggers a refit for explicit behavior.
  ///
  /// ## Example
  ///
  /// ```dart
  /// @override
  /// void onNodesDeleted(Set<String> nodeIds, AnnotationDragContext context) {
  ///   final removed = _trackedNodeIds.intersection(nodeIds);
  ///   _trackedNodeIds.removeAll(removed);
  ///   if (removed.isNotEmpty) {
  ///     _refitBounds(context);
  ///   }
  /// }
  /// ```
  void onNodesDeleted(Set<String> nodeIds, AnnotationDragContext context) {
    // Default implementation does nothing
  }

  /// Called when a node's position changes.
  ///
  /// Override this method to respond when a tracked node moves.
  /// The [nodeId] is the node that moved, [newPosition] is its new position.
  /// The [context] provides access to node data for operations like refitting.
  ///
  /// For [GroupAnnotation] with explicit behavior, this triggers a refit.
  ///
  /// ## Example
  ///
  /// ```dart
  /// @override
  /// void onNodeMoved(String nodeId, Offset newPosition, AnnotationDragContext context) {
  ///   if (_trackedNodeIds.contains(nodeId)) {
  ///     _updateBoundsForNode(nodeId, newPosition);
  ///   }
  /// }
  /// ```
  void onNodeMoved(
    String nodeId,
    Offset newPosition,
    AnnotationDragContext context,
  ) {
    // Default implementation does nothing
  }

  /// Called when a new node is added to the graph.
  ///
  /// Override this method to respond when nodes are added.
  /// Return `true` if the annotation took action (e.g., auto-added to group).
  ///
  /// ## Example
  ///
  /// ```dart
  /// @override
  /// bool onNodeAdded(String nodeId, Rect nodeBounds, AnnotationDragContext context) {
  ///   if (bounds.contains(nodeBounds.center)) {
  ///     addNode(nodeId);
  ///     return true;
  ///   }
  ///   return false;
  /// }
  /// ```
  bool onNodeAdded(
    String nodeId,
    Rect nodeBounds,
    AnnotationDragContext context,
  ) {
    // Default implementation does nothing
    return false;
  }

  /// Called when a node's size changes.
  ///
  /// Override this method to respond when a tracked node is resized.
  /// For [GroupAnnotation] with explicit behavior, this triggers a refit.
  void onNodeResized(
    String nodeId,
    Size newSize,
    AnnotationDragContext context,
  ) {
    // Default implementation does nothing
  }

  /// Called when a node's visibility changes.
  ///
  /// Override this method to respond when a tracked node becomes
  /// visible or hidden.
  void onNodeVisibilityChanged(String nodeId, bool isVisible) {
    // Default implementation does nothing
  }

  /// Called when the node selection changes.
  ///
  /// Override to respond when nodes are selected or deselected.
  /// The [selectedNodeIds] contains all currently selected node IDs.
  void onSelectionChanged(Set<String> selectedNodeIds) {
    // Default implementation does nothing
  }

  /// Whether this annotation should receive automatic node lifecycle callbacks.
  ///
  /// When `true`, the annotation controller sets up MobX reactions to
  /// automatically monitor node changes and call the lifecycle methods:
  /// - [onNodeDeleted] / [onNodesDeleted] when nodes are removed
  /// - [onNodeAdded] when nodes are added
  /// - [onNodeMoved] when node positions change
  /// - [onNodeResized] when node sizes change
  ///
  /// Returns `false` by default. [GroupAnnotation] returns `true` for
  /// explicit and parent behaviors.
  bool get monitorNodes => false;

  /// Whether this annotation is considered "empty" and has no content.
  ///
  /// Override to define what "empty" means for your annotation type.
  /// For [GroupAnnotation] with explicit/parent behavior, this returns
  /// `true` when there are no member nodes.
  ///
  /// Returns `false` by default (annotations are not considered empty).
  bool get isEmpty => false;

  /// Whether this annotation should be automatically removed when empty.
  ///
  /// Override to return `true` if your annotation should be deleted
  /// when [isEmpty] becomes true (e.g., after all member nodes are deleted).
  ///
  /// Returns `false` by default. [GroupAnnotation] returns `true` for
  /// explicit behavior only.
  bool get shouldRemoveWhenEmpty => false;

  /// Whether this annotation can be resized by the user.
  ///
  /// When `true`, resize handles will be shown when the annotation is selected,
  /// allowing the user to drag to change the annotation's size.
  ///
  /// Override to return `true` for annotations that support resizing.
  /// The default is `false`. [GroupAnnotation] and [StickyAnnotation]
  /// return `true` to enable resize functionality.
  bool get isResizable => false;

  /// Sets the size of this annotation.
  ///
  /// Override this method to implement resize behavior for your annotation.
  /// The default implementation does nothing.
  ///
  /// For annotations with immutable size properties (like [StickyAnnotation]),
  /// this method should replace the annotation in the controller with a new
  /// instance having the updated size.
  ///
  /// ## Example
  ///
  /// ```dart
  /// @override
  /// void setSize(Size newSize) {
  ///   _width.value = newSize.width.clamp(minWidth, maxWidth);
  ///   _height.value = newSize.height.clamp(minHeight, maxHeight);
  /// }
  /// ```
  void setSize(Size newSize) {
    // Default implementation does nothing
    // Subclasses should override to implement resize behavior
  }

  /// The set of node IDs that this annotation monitors for position/size changes.
  ///
  /// When [monitorNodes] is `true`, the annotation controller sets up MobX
  /// reactions to watch these specific node IDs. Override to return the
  /// nodes your annotation cares about.
  ///
  /// Returns an empty set by default. [GroupAnnotation] returns its
  /// [nodeIds] for explicit and parent behaviors.
  Set<String> get monitoredNodeIds => const {};

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
}
