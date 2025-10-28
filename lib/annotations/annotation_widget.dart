import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';

import '../annotations/annotation.dart';
import '../graph/node_flow_theme.dart';

/// Framework widget that wraps custom annotations with automatic functionality
///
/// This widget automatically provides:
/// - Reactive positioning based on annotation.position Observable
/// - Visibility control based on annotation.isVisible Observable
/// - Theme-consistent selection visual feedback using NodeFlowTheme
/// - Border radius, colors, and widths matching the node editor theme
/// - Proper z-index layering
///
/// Custom annotation implementers only need to focus on their `buildWidget()` method.
/// The framework handles all positioning, selection, theming, and interaction logic automatically.
class AnnotationWidget extends StatelessWidget {
  const AnnotationWidget({
    super.key,
    required this.annotation,
    this.isSelected = false,
    this.isHighlighted = false,
  });

  final Annotation annotation;
  final bool isSelected;
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

  Widget _buildAnnotationContent(BuildContext context) {
    // Get the custom widget from the annotation implementation
    Widget content = annotation.buildWidget(context);

    // Get the NodeFlowTheme for consistent styling
    final theme = Theme.of(context).extension<NodeFlowTheme>()!;

    // Determine border color and background color based on state
    // Highlight takes precedence over selection for better drag feedback
    Color borderColor = Colors.transparent;
    Color? backgroundColor;
    double borderWidth = theme.selectionBorderWidth;

    if (isHighlighted) {
      // Use a bright highlight color for drag-over feedback
      borderColor = Colors.orange;
      backgroundColor = Colors.orange.withValues(alpha: 0.1);
      borderWidth =
          theme.selectionBorderWidth +
          1; // Make highlight border slightly thicker
    } else if (isSelected) {
      borderColor = theme.selectionBorderColor;
      backgroundColor = theme.selectionColor;
    }

    // Apply theme-consistent selection and highlight styling
    return Container(
      width: annotation.size.width,
      height: annotation.size.height,
      decoration: BoxDecoration(
        border: Border.all(color: borderColor, width: borderWidth),
        borderRadius: theme.nodeTheme.borderRadius,
        color: backgroundColor,
      ),
      child: content,
    );
  }
}
