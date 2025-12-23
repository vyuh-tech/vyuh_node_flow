import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:vyuh_node_flow/vyuh_node_flow.dart';

/// Framework widget that wraps custom annotations with automatic functionality.
///
/// This widget serves as the **universal rendering layer** for ALL annotation types,
/// automatically providing:
/// - **Reactive positioning**: Updates automatically based on [annotation.visualPosition]
/// - **Visibility control**: Shows/hides based on [annotation.isVisible]
/// - **Selection feedback**: Theme-consistent borders and highlights when selected
/// - **Hover feedback**: Visual indication when annotation is being dragged over (highlighted)
/// - **Theme integration**: Uses [NodeFlowTheme] for consistent styling across the editor
/// - **Gesture handling**: Tap, double-tap, drag, and context menu events via [ElementScope]
/// - **Resize handles**: Shown for annotations where [Annotation.isResizable] is true
///
/// ## Framework Integration
///
/// Custom annotation implementers only need to focus on their [Annotation.buildWidget]
/// method. The [AnnotationWidget] handles all positioning, selection, theming, and
/// interaction logic automatically.
///
/// The widget wraps the custom annotation content with:
/// 1. [Observer] for MobX reactivity
/// 2. [Positioned] for absolute canvas positioning
/// 3. [ElementScope] for unified gesture handling with proper lifecycle management
/// 4. Selection/highlight borders using theme colors
/// 5. Visibility logic to hide when [annotation.isVisible] is false
/// 6. Resize handles when annotation is selected and resizable
///
/// ## Unified Annotation Handling
///
/// This widget handles ALL annotation types uniformly:
/// - **StickyAnnotation**: Resizable sticky notes
/// - **GroupAnnotation**: Resizable/non-resizable groups (based on behavior)
/// - **MarkerAnnotation**: Non-resizable markers
/// - **Custom annotations**: Any annotation implementing [Annotation]
///
/// Selection and highlight states are read directly from the annotation and
/// controller, eliminating the need for specialized widgets per annotation type.
///
/// ## Example Usage
///
/// This widget is typically used internally by [AnnotationLayer]:
///
/// ```dart
/// AnnotationWidget(
///   annotation: stickyNote,
///   controller: controller,
///   onTap: () => controller.selectAnnotation(stickyNote.id),
/// )
/// ```
///
/// See also:
/// - [Annotation] for creating custom annotation types
/// - [AnnotationLayer] for rendering multiple annotations
/// - [NodeFlowTheme] for theming options
/// - [ElementScope] for gesture lifecycle management
class AnnotationWidget extends StatelessWidget {
  /// Creates an annotation widget.
  ///
  /// Selection and highlight states are read directly from the annotation
  /// and controller - they do not need to be passed in.
  ///
  /// ## Parameters
  /// - [annotation]: The annotation to render
  /// - [controller]: Controller for drag handling and state queries
  const AnnotationWidget({
    super.key,
    required this.annotation,
    required this.controller,
    this.onTap,
    this.onDoubleTap,
    this.onContextMenu,
    this.onMouseEnter,
    this.onMouseLeave,
  });

  /// The annotation to render.
  ///
  /// The widget observes this annotation's reactive properties ([visualPosition],
  /// [isVisible], [selected]) for automatic UI updates.
  final Annotation annotation;

  /// Controller for drag handling and state queries.
  ///
  /// The widget calls controller methods directly for annotation drag operations
  /// and queries selection/highlight state.
  final NodeFlowController controller;

  /// Callback invoked when the annotation is tapped.
  final VoidCallback? onTap;

  /// Callback invoked when the annotation is double-tapped.
  final VoidCallback? onDoubleTap;

  /// Callback invoked when the annotation is right-clicked (context menu).
  final void Function(Offset globalPosition)? onContextMenu;

  /// Callback invoked when mouse enters the annotation.
  final VoidCallback? onMouseEnter;

  /// Callback invoked when mouse leaves the annotation.
  final VoidCallback? onMouseLeave;

  @override
  Widget build(BuildContext context) {
    // Use controller's theme as single source of truth
    final theme = controller.theme ?? NodeFlowTheme.light;

    return Observer(
      builder: (_) {
        // graphPosition is the position in graph/canvas coordinates
        final graphPosition = annotation.visualPosition;
        final isVisible = annotation.isVisible;

        if (!isVisible) {
          return const SizedBox.shrink();
        }

        // Read selection directly from annotation (reactive)
        final isSelected = annotation.selected;

        final showResizeHandles = isSelected && annotation.isResizable;

        // Derive cursor from interaction state
        final cursor = theme.cursorTheme.cursorFor(
          ElementType.annotation,
          controller.interaction,
          isInteractive: annotation.isInteractive,
        );

        // Simple positioning: exact annotation position and size
        // Stack with clip: none allows resize handles to extend outside
        return Positioned(
          left: graphPosition.dx,
          top: graphPosition.dy,
          width: annotation.size.width,
          height: annotation.size.height,
          child: UnboundedStack(
            clipBehavior: Clip.none,
            children: [
              // Main annotation content with gesture handling via ElementScope
              Positioned.fill(
                child: ElementScope(
                  // Drag lifecycle - delegated to controller
                  isDraggable: annotation.isInteractive,
                  onDragStart: (_) =>
                      controller.startAnnotationDrag(annotation.id),
                  onDragUpdate: (details) =>
                      controller.moveAnnotationDrag(details.delta),
                  onDragEnd: (_) => controller.endAnnotationDrag(),
                  // Interaction callbacks
                  onTap: onTap,
                  onDoubleTap: onDoubleTap,
                  onContextMenu: onContextMenu,
                  onMouseEnter: onMouseEnter,
                  onMouseLeave: onMouseLeave,
                  cursor: cursor,
                  hitTestBehavior: HitTestBehavior.translucent,
                  // Annotation visual
                  child: _buildAnnotationContent(
                    context,
                    isSelected: isSelected,
                  ),
                ),
              ),

              // Resize handles as overlay (only when selected and resizable)
              // ResizerWidget handles extending outside via its internal layout
              if (showResizeHandles)
                Positioned.fill(
                  child: ResizerWidget(
                    handleSize: theme.resizerTheme.handleSize,
                    color: theme.resizerTheme.color,
                    borderColor: theme.resizerTheme.borderColor,
                    borderWidth: theme.resizerTheme.borderWidth,
                    snapDistance: theme.resizerTheme.snapDistance,
                    onResizeStart: (handle) => controller.annotations
                        .startAnnotationResize(annotation.id, handle),
                    onResizeUpdate: (delta) =>
                        controller.annotations.updateAnnotationResize(delta),
                    onResizeEnd: () =>
                        controller.annotations.endAnnotationResize(),
                    child: const SizedBox.expand(),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  /// Builds the annotation content with theme-consistent selection/highlight styling.
  ///
  /// This method:
  /// 1. Retrieves the custom widget from [annotation.buildWidget]
  /// 2. Applies theme-consistent borders and backgrounds based on selection/highlight state
  /// 3. Returns a [Container] with the styled content
  ///
  /// The styling priority is:
  /// - Editing state: Transparent border (maintains layout, seamless editing)
  /// - Selected state: Selection border and background
  /// - Transparent border when not selected
  ///
  /// IMPORTANT: Always apply a border (even if transparent) to prevent content
  /// shifting when selection/editing state changes.
  Widget _buildAnnotationContent(
    BuildContext context, {
    required bool isSelected,
  }) {
    // Get the custom widget from the annotation implementation
    final content = annotation.buildWidget(context);

    // Use controller's theme as single source of truth
    final theme = controller.theme ?? NodeFlowTheme.light;
    final annotationTheme = theme.annotationTheme;
    final borderWidth = annotationTheme.borderWidth;

    // Determine border color and background color based on state
    // When editing, use transparent border for seamless editing experience
    // ALWAYS apply a border (transparent if not selected) to prevent content shift
    Color borderColor = Colors.transparent;
    Color? backgroundColor;

    if (!annotation.isEditing && isSelected) {
      borderColor = annotationTheme.selectionBorderColor;
      backgroundColor = annotationTheme.selectionBackgroundColor;
    }

    // Apply theme-consistent selection and highlight styling
    // Content fills the available space - no explicit size needed
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: borderColor, width: borderWidth),
        borderRadius: annotationTheme.borderRadius,
        color: backgroundColor,
      ),
      child: content,
    );
  }
}
