import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';

import '../annotations/annotation.dart';
import '../graph/node_flow_controller.dart';
import '../shared/unbounded_widgets.dart';
import 'annotation_widget.dart';

/// A rendering layer for annotations in the node flow editor.
///
/// This widget serves as a rendering layer that displays annotations on the
/// canvas. It automatically:
/// - Observes annotation changes via MobX for reactive updates
/// - Sorts annotations by z-index for proper layering
/// - Applies filtering to show specific annotation types
/// - Handles selection and highlight visual feedback
/// - Wires gesture callbacks to individual [AnnotationWidget] instances
/// - Uses [RepaintBoundary] for optimized rendering
///
/// ## Layer Architecture
///
/// The node flow editor typically uses two annotation layers:
/// 1. **Background layer**: Renders [GroupAnnotation]s behind nodes
/// 2. **Foreground layer**: Renders sticky notes and markers above connections
///
/// ## Example Usage
///
/// ```dart
/// // Background layer for groups
/// AnnotationLayer<MyNodeData>.background(controller)
///
/// // Foreground layer for stickies and markers
/// AnnotationLayer<MyNodeData>.foreground(controller)
///
/// // Custom filtered layer
/// AnnotationLayer<MyNodeData>(
///   controller: controller,
///   filter: (annotation) => annotation is StickyAnnotation,
/// )
/// ```
///
/// See also:
/// - [AnnotationWidget] for individual annotation rendering
/// - [Annotation] for creating custom annotation types
/// - [NodeFlowController] for annotation management
class AnnotationLayer<T> extends StatelessWidget {
  /// Creates an annotation layer.
  ///
  /// ## Parameters
  /// - [controller]: The node flow controller managing the annotations
  /// - [filter]: Optional predicate to filter which annotations to render
  const AnnotationLayer({
    super.key,
    required this.controller,
    this.filter,
    this.onAnnotationTap,
    this.onAnnotationDoubleTap,
    this.onAnnotationContextMenu,
    this.onAnnotationMouseEnter,
    this.onAnnotationMouseLeave,
  });

  /// Creates a background annotation layer.
  ///
  /// Renders annotations with [AnnotationRenderLayer.background] behind nodes,
  /// such as [GroupAnnotation].
  ///
  /// ## Example
  ///
  /// ```dart
  /// Stack(
  ///   children: [
  ///     Background(),
  ///     AnnotationLayer<T>.background(controller), // Groups behind nodes
  ///     Nodes(),
  ///     Connections(),
  ///   ],
  /// )
  /// ```
  static AnnotationLayer<T> background<T>(
    NodeFlowController<T> controller, {
    void Function(Annotation annotation)? onAnnotationTap,
    void Function(Annotation annotation)? onAnnotationDoubleTap,
    void Function(Annotation annotation, Offset globalPosition)?
    onAnnotationContextMenu,
    void Function(Annotation annotation)? onAnnotationMouseEnter,
    void Function(Annotation annotation)? onAnnotationMouseLeave,
  }) {
    return AnnotationLayer<T>(
      controller: controller,
      filter: (annotation) =>
          annotation.layer == AnnotationRenderLayer.background,
      onAnnotationTap: onAnnotationTap,
      onAnnotationDoubleTap: onAnnotationDoubleTap,
      onAnnotationContextMenu: onAnnotationContextMenu,
      onAnnotationMouseEnter: onAnnotationMouseEnter,
      onAnnotationMouseLeave: onAnnotationMouseLeave,
    );
  }

  /// Creates a foreground annotation layer.
  ///
  /// Renders annotations with [AnnotationRenderLayer.foreground] above nodes
  /// and connections, such as [StickyAnnotation] and [MarkerAnnotation].
  ///
  /// ## Example
  ///
  /// ```dart
  /// Stack(
  ///   children: [
  ///     Background(),
  ///     Groups(),
  ///     Nodes(),
  ///     Connections(),
  ///     AnnotationLayer<T>.foreground(controller), // Stickies and markers on top
  ///   ],
  /// )
  /// ```
  static AnnotationLayer<T> foreground<T>(
    NodeFlowController<T> controller, {
    void Function(Annotation annotation)? onAnnotationTap,
    void Function(Annotation annotation)? onAnnotationDoubleTap,
    void Function(Annotation annotation, Offset globalPosition)?
    onAnnotationContextMenu,
    void Function(Annotation annotation)? onAnnotationMouseEnter,
    void Function(Annotation annotation)? onAnnotationMouseLeave,
  }) {
    return AnnotationLayer<T>(
      controller: controller,
      filter: (annotation) =>
          annotation.layer == AnnotationRenderLayer.foreground,
      onAnnotationTap: onAnnotationTap,
      onAnnotationDoubleTap: onAnnotationDoubleTap,
      onAnnotationContextMenu: onAnnotationContextMenu,
      onAnnotationMouseEnter: onAnnotationMouseEnter,
      onAnnotationMouseLeave: onAnnotationMouseLeave,
    );
  }

  /// The node flow controller managing the annotations.
  ///
  /// This layer observes the controller's annotation collection for reactive updates.
  final NodeFlowController<T> controller;

  /// Optional filter to determine which annotations to render.
  ///
  /// When null, all annotations are rendered. When provided, only annotations
  /// for which this function returns true are displayed.
  ///
  /// ## Example
  ///
  /// ```dart
  /// // Only render sticky notes
  /// filter: (annotation) => annotation is StickyAnnotation
  ///
  /// // Only render visible annotations
  /// filter: (annotation) => annotation.currentIsVisible
  /// ```
  final bool Function(Annotation)? filter;

  /// Callback invoked when an annotation is tapped.
  final void Function(Annotation annotation)? onAnnotationTap;

  /// Callback invoked when an annotation is double-tapped.
  final void Function(Annotation annotation)? onAnnotationDoubleTap;

  /// Callback invoked when an annotation is right-clicked (context menu).
  final void Function(Annotation annotation, Offset globalPosition)?
  onAnnotationContextMenu;

  /// Callback invoked when mouse enters an annotation.
  final void Function(Annotation annotation)? onAnnotationMouseEnter;

  /// Callback invoked when mouse leaves an annotation.
  final void Function(Annotation annotation)? onAnnotationMouseLeave;

  @override
  Widget build(BuildContext context) {
    return UnboundedPositioned.fill(
      child: UnboundedRepaintBoundary(
        child: Observer(
          builder: (_) {
            // Observe sorted annotations for z-index ordering, apply filter if provided
            var annotations = controller.annotations.sortedAnnotations;

            if (filter != null) {
              annotations = annotations.where(filter!).toList();
            }

            // Use unified AnnotationWidget for ALL annotation types
            // Selection and highlight states are read directly from annotation/controller
            return UnboundedStack(
              clipBehavior: Clip.none,
              children: annotations.map((annotation) {
                return AnnotationWidget(
                  key: ValueKey('${annotation.id}_z${annotation.zIndex}'),
                  annotation: annotation,
                  controller: controller,
                  // Event callbacks for external handling
                  onTap: onAnnotationTap != null
                      ? () => onAnnotationTap!(annotation)
                      : null,
                  onDoubleTap: onAnnotationDoubleTap != null
                      ? () => onAnnotationDoubleTap!(annotation)
                      : null,
                  onContextMenu: onAnnotationContextMenu != null
                      ? (pos) => onAnnotationContextMenu!(annotation, pos)
                      : null,
                  onMouseEnter: onAnnotationMouseEnter != null
                      ? () => onAnnotationMouseEnter!(annotation)
                      : null,
                  onMouseLeave: onAnnotationMouseLeave != null
                      ? () => onAnnotationMouseLeave!(annotation)
                      : null,
                );
              }).toList(),
            );
          },
        ),
      ),
    );
  }
}
