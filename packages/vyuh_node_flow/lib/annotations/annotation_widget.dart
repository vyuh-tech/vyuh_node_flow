import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';

import '../annotations/annotation.dart';
import '../graph/node_flow_theme.dart';

/// Framework widget that wraps custom annotations with automatic functionality.
///
/// This widget serves as the rendering layer for annotations, automatically providing:
/// - **Reactive positioning**: Updates automatically based on [annotation.visualPosition]
/// - **Visibility control**: Shows/hides based on [annotation.isVisible]
/// - **Selection feedback**: Theme-consistent borders and highlights when selected
/// - **Hover feedback**: Visual indication when annotation is being dragged over (highlighted)
/// - **Theme integration**: Uses [NodeFlowTheme] for consistent styling across the editor
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
/// 3. Selection/highlight borders using theme colors
/// 4. Visibility logic to hide when [annotation.isVisible] is false
///
/// ## Example Usage
///
/// This widget is typically used internally by [AnnotationLayer]:
///
/// ```dart
/// AnnotationWidget(
///   annotation: stickyNote,
///   isSelected: controller.annotations.isAnnotationSelected(stickyNote.id),
///   isHighlighted: false,
/// )
/// ```
///
/// See also:
/// - [Annotation] for creating custom annotation types
/// - [AnnotationLayer] for rendering multiple annotations
/// - [NodeFlowTheme] for theming options
class AnnotationWidget extends StatelessWidget {
  /// Creates an annotation widget.
  ///
  /// ## Parameters
  /// - [annotation]: The annotation to render
  /// - [isSelected]: Whether this annotation is currently selected
  /// - [isHighlighted]: Whether this annotation is being highlighted (e.g., during drag-over)
  const AnnotationWidget({
    super.key,
    required this.annotation,
    this.isSelected = false,
    this.isHighlighted = false,
  });

  /// The annotation to render.
  ///
  /// The widget observes this annotation's reactive properties ([visualPosition],
  /// [isVisible]) for automatic UI updates.
  final Annotation annotation;

  /// Whether this annotation is currently selected.
  ///
  /// When true, a selection border is drawn around the annotation using the
  /// theme's selection colors.
  final bool isSelected;

  /// Whether this annotation is being highlighted (e.g., during a drag-over operation).
  ///
  /// When true, a bright highlight border is shown. Highlight takes precedence
  /// over selection for better drag feedback.
  final bool isHighlighted;

  @override
  Widget build(BuildContext context) {
    return Observer(
      builder: (_) {
        final position = annotation.visualPosition.value;
        final isVisible = annotation.isVisible.value;

        if (!isVisible) {
          return const SizedBox.shrink();
        }

        Widget child = Positioned(
          left: position.dx,
          top: position.dy,
          child: _buildAnnotationContent(context),
        );

        // Don't add interaction handling here - it's handled by the main editor
        // Just position the content directly

        return child;
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
  /// - Highlighted state takes precedence over selected
  /// - Selected state is used when not highlighted
  /// - No border when neither selected nor highlighted
  Widget _buildAnnotationContent(BuildContext context) {
    // Get the custom widget from the annotation implementation
    Widget content = annotation.buildWidget(context);

    // Get the NodeFlowTheme for consistent styling
    final theme = Theme.of(context).extension<NodeFlowTheme>()!;
    final annotationTheme = theme.annotationTheme;

    // Determine border color and background color based on state
    // Highlight takes precedence over selection for better drag feedback
    Color borderColor = Colors.transparent;
    Color? backgroundColor;
    double borderWidth = annotationTheme.borderWidth;

    if (isHighlighted) {
      // Use highlight colors for drag-over feedback
      borderColor = annotationTheme.highlightBorderColor;
      backgroundColor = annotationTheme.highlightBackgroundColor;
      borderWidth =
          annotationTheme.borderWidth +
          annotationTheme.highlightBorderWidthDelta;
    } else if (isSelected) {
      borderColor = annotationTheme.selectionBorderColor;
      backgroundColor = annotationTheme.selectionBackgroundColor;
    }

    // Apply theme-consistent selection and highlight styling
    return Container(
      width: annotation.size.width,
      height: annotation.size.height,
      decoration: BoxDecoration(
        border: Border.all(color: borderColor, width: borderWidth),
        borderRadius: annotationTheme.borderRadius,
        color: backgroundColor,
      ),
      child: content,
    );
  }
}
