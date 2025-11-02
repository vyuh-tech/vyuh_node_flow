import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';

import '../annotations/annotation.dart';
import '../graph/node_flow_controller.dart';
import 'annotation_widget.dart';

/// A rendering layer for annotations in the node flow editor.
///
/// This widget serves as a pure rendering layer that displays annotations on the
/// canvas. It automatically:
/// - Observes annotation changes via MobX for reactive updates
/// - Sorts annotations by z-index for proper layering
/// - Applies filtering to show specific annotation types
/// - Handles selection and highlight visual feedback
/// - Uses [RepaintBoundary] for optimized rendering
///
/// ## Layer Architecture
///
/// The node flow editor typically uses two annotation layers:
/// 1. **Background layer**: Renders [GroupAnnotation]s behind nodes
/// 2. **Foreground layer**: Renders sticky notes and markers above connections
///
/// ## Important Note
///
/// This is a **pure rendering layer**. User interactions (clicks, drags, etc.)
/// are handled by the [NodeFlowEditor], not by this widget. This separation
/// ensures consistent interaction behavior across all canvas elements.
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
  const AnnotationLayer({super.key, required this.controller, this.filter});

  /// Creates a background annotation layer that renders only groups.
  ///
  /// Group annotations are typically rendered behind nodes with a negative
  /// z-index, creating visual boundaries around related nodes.
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
  static AnnotationLayer<T> background<T>(NodeFlowController<T> controller) {
    return AnnotationLayer<T>(
      controller: controller,
      filter: (annotation) => annotation is GroupAnnotation,
    );
  }

  /// Creates a foreground annotation layer that renders everything except groups.
  ///
  /// This layer renders sticky notes and markers above connections but below
  /// any overlays or UI controls.
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
  static AnnotationLayer<T> foreground<T>(NodeFlowController<T> controller) {
    return AnnotationLayer<T>(
      controller: controller,
      filter: (annotation) => annotation is! GroupAnnotation,
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

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: RepaintBoundary(
        child: Observer(
          builder: (_) {
            // Observe sorted annotations for z-index ordering, apply filter if provided
            var annotations = controller.annotations.sortedAnnotations;

            if (filter != null) {
              annotations = annotations.where(filter!).toList();
            }
            final selectedAnnotationIds =
                controller.annotations.selectedAnnotationIds;

            return Stack(
              clipBehavior: Clip.none,
              children: annotations.map((annotation) {
                final isSelected = selectedAnnotationIds.contains(
                  annotation.id,
                );

                // Check if this group annotation is highlighted during drag
                final isHighlighted =
                    annotation is GroupAnnotation &&
                    controller.annotations.isGroupHighlighted(annotation.id);

                return AnnotationWidget(
                  key: ValueKey('${annotation.id}_z${annotation.zIndex.value}'),
                  annotation: annotation,
                  isSelected: isSelected,
                  isHighlighted: isHighlighted,
                );
              }).toList(),
            );
          },
        ),
      ),
    );
  }
}

/// Extension to add annotation layer support to widgets.
///
/// This extension provides a convenient way to wrap any widget with an
/// annotation rendering layer.
extension AnnotationLayerSupport<T> on Widget {
  /// Wraps this widget with an annotation layer.
  ///
  /// This creates a [Stack] with the original widget and an [AnnotationLayer]
  /// on top. The annotation layer is purely for rendering - interactions are
  /// handled by the main [NodeFlowEditor].
  ///
  /// ## Example
  ///
  /// ```dart
  /// GridBackground()
  ///   .withAnnotationLayer(controller)
  /// ```
  ///
  /// ## Important Note
  ///
  /// User interactions (clicks, drags) are handled by [NodeFlowEditor], not
  /// by the annotation layer. This ensures consistent interaction behavior.
  ///
  /// ## Parameters
  /// - [controller]: The node flow controller managing the annotations
  ///
  /// ## Returns
  /// A [Stack] containing the original widget and the annotation layer
  Widget withAnnotationLayer(NodeFlowController<T> controller) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        // Original widget (background, grid, etc.)
        this,

        // Annotation layer - purely for rendering
        AnnotationLayer<T>(controller: controller),
      ],
    );
  }
}
