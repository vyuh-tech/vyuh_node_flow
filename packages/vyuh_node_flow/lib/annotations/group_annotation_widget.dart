import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';

import '../graph/cursor_theme.dart';
import '../graph/node_flow_controller.dart';
import '../graph/node_flow_theme.dart';
import '../shared/resizer_widget.dart';
import '../shared/unbounded_widgets.dart';
import 'group_annotation.dart';

/// Widget that renders a group annotation with resize handles when selected.
///
/// This widget wraps the group annotation's visual content and adds interactive
/// resize handles at 8 positions (4 corners + 4 edge midpoints) when the group
/// is selected.
///
/// Uses [ResizerWidget] for consistent resize behavior with other resizable
/// elements like nodes.
class GroupAnnotationWidget extends StatelessWidget {
  const GroupAnnotationWidget({
    super.key,
    required this.group,
    required this.controller,
    required this.isSelected,
    this.isHighlighted = false,
    this.onTap,
    this.onDoubleTap,
    this.onContextMenu,
  });

  final GroupAnnotation group;
  final NodeFlowController controller;
  final bool isSelected;
  final bool isHighlighted;
  final VoidCallback? onTap;
  final VoidCallback? onDoubleTap;
  final void Function(Offset globalPosition)? onContextMenu;

  @override
  Widget build(BuildContext context) {
    // Use controller's theme as single source of truth
    final theme = controller.theme ?? NodeFlowTheme.light;

    return Observer(
      builder: (_) {
        final position = group.visualPosition;
        final isVisible = group.isVisible;
        final groupSize = group.observableSize.value;

        if (!isVisible) {
          return const SizedBox.shrink();
        }

        // Derive cursor from interaction state, same as nodes
        final cursor = theme.cursorTheme.cursorFor(
          ElementType.annotation,
          controller.interaction,
          isInteractive: group.isInteractive,
        );

        // Use UnboundedStack to allow hit testing on resize handles
        // that extend outside the annotation bounds
        return Positioned(
          left: position.dx,
          top: position.dy,
          width: groupSize.width,
          height: groupSize.height,
          child: UnboundedStack(
            clipBehavior: Clip.none,
            children: [
              // The annotation content
              Positioned.fill(
                child: MouseRegion(
                  cursor: cursor,
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onDoubleTap: onDoubleTap,
                    onSecondaryTapUp: onContextMenu != null
                        ? (details) => onContextMenu!(details.globalPosition)
                        : null,
                    onPanStart: (_) => controller.startAnnotationDrag(group.id),
                    onPanUpdate: (details) =>
                        controller.moveAnnotationDrag(details.delta),
                    onPanEnd: (_) => controller.endAnnotationDrag(),
                    child: _GroupContent(
                      group: group,
                      controller: controller,
                      isSelected: isSelected,
                      isHighlighted: isHighlighted,
                    ),
                  ),
                ),
              ),
              // Resize handles as overlay (only when selected and resizable)
              if (isSelected && group.isResizable)
                Positioned.fill(
                  child: ResizerWidget(
                    handleSize: theme.resizerTheme.handleSize,
                    color: theme.resizerTheme.color,
                    borderColor: theme.resizerTheme.borderColor,
                    borderWidth: theme.resizerTheme.borderWidth,
                    snapDistance: theme.resizerTheme.snapDistance,
                    onResizeStart: (handle) => controller.annotations
                        .startGroupResize(group.id, _toGroupHandle(handle)),
                    onResizeUpdate: (delta) =>
                        controller.annotations.updateGroupResize(delta),
                    onResizeEnd: () => controller.annotations.endGroupResize(),
                    child: const SizedBox.expand(),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  /// Convert from shared ResizeHandle to GroupAnnotation's ResizeHandlePosition
  ResizeHandlePosition _toGroupHandle(ResizeHandle handle) {
    return switch (handle) {
      ResizeHandle.topLeft => ResizeHandlePosition.topLeft,
      ResizeHandle.topCenter => ResizeHandlePosition.topCenter,
      ResizeHandle.topRight => ResizeHandlePosition.topRight,
      ResizeHandle.centerLeft => ResizeHandlePosition.centerLeft,
      ResizeHandle.centerRight => ResizeHandlePosition.centerRight,
      ResizeHandle.bottomLeft => ResizeHandlePosition.bottomLeft,
      ResizeHandle.bottomCenter => ResizeHandlePosition.bottomCenter,
      ResizeHandle.bottomRight => ResizeHandlePosition.bottomRight,
    };
  }
}

/// Internal widget for the group's visual content with selection styling.
class _GroupContent extends StatelessWidget {
  const _GroupContent({
    required this.group,
    required this.controller,
    required this.isSelected,
    required this.isHighlighted,
  });

  final GroupAnnotation group;
  final NodeFlowController controller;
  final bool isSelected;
  final bool isHighlighted;

  @override
  Widget build(BuildContext context) {
    // Use controller's theme as single source of truth
    final theme = controller.theme ?? NodeFlowTheme.light;
    final annotationTheme = theme.annotationTheme;

    // Determine border styling based on state
    Color borderColor = Colors.transparent;
    Color? backgroundColor;
    final borderWidth = annotationTheme.borderWidth;

    if (isHighlighted) {
      borderColor = annotationTheme.highlightBorderColor;
      backgroundColor = annotationTheme.highlightBackgroundColor;
    } else if (isSelected) {
      borderColor = annotationTheme.selectionBorderColor;
      backgroundColor = annotationTheme.selectionBackgroundColor;
    }

    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: borderColor, width: borderWidth),
        borderRadius: annotationTheme.borderRadius,
        color: backgroundColor,
      ),
      child: group.buildWidget(context),
    );
  }
}
