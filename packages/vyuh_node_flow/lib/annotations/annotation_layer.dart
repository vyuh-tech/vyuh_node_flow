import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';

import '../annotations/annotation.dart';
import '../graph/node_flow_controller.dart';
import 'annotation_widget.dart';

/// Layer that renders annotations between background and connections
/// Note: This is a pure rendering layer - interactions are handled by NodeFlowEditor
class AnnotationLayer<T> extends StatelessWidget {
  const AnnotationLayer({super.key, required this.controller, this.filter});

  /// Factory method for background annotations layer (groups only)
  static AnnotationLayer<T> background<T>(NodeFlowController<T> controller) {
    return AnnotationLayer<T>(
      controller: controller,
      filter: (annotation) => annotation is GroupAnnotation,
    );
  }

  /// Factory method for foreground annotations layer (stickies and markers)
  static AnnotationLayer<T> foreground<T>(NodeFlowController<T> controller) {
    return AnnotationLayer<T>(
      controller: controller,
      filter: (annotation) => annotation is! GroupAnnotation,
    );
  }

  final NodeFlowController<T> controller;
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

/// Extension to add annotation layer support to node flow editor
extension AnnotationLayerSupport<T> on Widget {
  /// Wraps the widget with annotation layer support
  /// Note: Interactions are handled by the main NodeFlowEditor, not here
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
