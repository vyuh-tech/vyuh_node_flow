import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_mobx/flutter_mobx.dart';

import '../../connections/connection.dart';
import '../../connections/connection_label.dart';
import '../../connections/label_theme.dart';
import '../../connections/styles/label_calculator.dart';
import '../../shared/unbounded_widgets.dart';
import '../node_flow_controller.dart';
import '../node_flow_theme.dart';

/// Builder function type for customizing connection label widgets.
///
/// This typedef defines the signature for custom label builders that can be
/// provided to [NodeFlowEditor] to customize how connection labels are rendered.
///
/// Parameters:
/// - [context]: The build context
/// - [connection]: The connection containing this label
/// - [label]: The label being rendered
/// - [position]: The calculated position rect for the label (includes size)
/// - [onTap]: Optional tap callback that handles selection with modifier key support.
///   Custom widgets can use this to get the standard selection behavior, or ignore
///   it to implement custom tap handling.
///
/// Example:
/// ```dart
/// LabelBuilder myLabelBuilder = (context, connection, label, position, onTap) {
///   return GestureDetector(
///     onTap: onTap, // Use the provided tap handler for selection
///     child: Container(
///       padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
///       decoration: BoxDecoration(
///         color: Colors.amber.shade100,
///         borderRadius: BorderRadius.circular(12),
///       ),
///       child: Row(
///         mainAxisSize: MainAxisSize.min,
///         children: [
///           Icon(Icons.bolt, size: 14),
///           SizedBox(width: 4),
///           Text(label.text),
///         ],
///       ),
///     ),
///   );
/// };
/// ```
typedef LabelBuilder =
    Widget Function(
      BuildContext context,
      Connection connection,
      ConnectionLabel label,
      Rect position,
      VoidCallback? onTap,
    );

/// Layer that renders connection labels independently from connection lines
/// This allows for optimized repainting when only labels change
class ConnectionLabelsLayer<T> extends StatelessWidget {
  const ConnectionLabelsLayer({
    super.key,
    required this.controller,
    this.labelBuilder,
  });

  final NodeFlowController<T> controller;

  /// Optional builder for customizing individual label widgets.
  ///
  /// When provided, this builder is called for each label and receives:
  /// - [connection] - The connection containing the label
  /// - [label] - The label to render
  /// - [position] - The calculated rect position for the label
  ///
  /// The returned widget replaces the default label rendering.
  final LabelBuilder? labelBuilder;

  @override
  Widget build(BuildContext context) {
    return UnboundedPositioned.fill(
      child: Observer(
        builder: (context) {
          // Observe connections list changes
          final connections = controller.connections;

          // Filter to only connections that have at least one label
          final connectionsWithLabels = connections.where((connection) {
            return connection.labels.isNotEmpty;
          }).toList();

          return UnboundedStack(
            clipBehavior: Clip.none,
            children: connectionsWithLabels.map((connection) {
              return _ConnectionLabelWidget<T>(
                key: ValueKey('label_${connection.id}'),
                connection: connection,
                controller: controller,
                labelBuilder: labelBuilder,
                onLabelTap: () {
                  // Check for modifier keys to support toggle selection
                  final isCmd = HardwareKeyboard.instance.isMetaPressed;
                  final isCtrl = HardwareKeyboard.instance.isControlPressed;
                  final toggle = isCmd || isCtrl;

                  // Select the connection when any label is tapped
                  // This will clear node/annotation selections and focus canvas (when not toggling)
                  controller.selectConnection(connection.id, toggle: toggle);
                },
              );
            }).toList(),
          );
        },
      ),
    );
  }
}

/// Individual widget for rendering a single connection's labels
/// This provides granular repaint boundaries for label updates
class _ConnectionLabelWidget<T> extends StatelessWidget {
  const _ConnectionLabelWidget({
    super.key,
    required this.connection,
    required this.controller,
    this.labelBuilder,
    this.onLabelTap,
  });

  final Connection connection;
  final NodeFlowController<T> controller;
  final LabelBuilder? labelBuilder;
  final VoidCallback? onLabelTap;

  @override
  Widget build(BuildContext context) {
    return Observer(
      builder: (context) {
        // Get nodes and observe their positions
        final sourceNode = controller.getNode(connection.sourceNodeId);
        final targetNode = controller.getNode(connection.targetNodeId);

        if (sourceNode == null || targetNode == null) {
          return const SizedBox.shrink();
        }

        // Observe node positions to trigger rebuilds when nodes move
        sourceNode.position.value;
        targetNode.position.value;

        // Observe connection labels changes
        final labels = connection.labels;

        // Observe individual label property changes for reactivity
        for (final label in labels) {
          label.text;
          label.anchor;
          label.offset;
        }

        // Skip rendering if no labels
        if (labels.isEmpty) {
          return const SizedBox.shrink();
        }

        // Get theme from context - this ensures automatic rebuilds when theme changes
        final currentTheme =
            Theme.of(context).extension<NodeFlowTheme>() ?? NodeFlowTheme.light;

        // Get the effective connection style (per-connection override or theme default)
        final effectiveStyle = connection.getEffectiveStyle(
          currentTheme.connectionTheme.style,
        );

        // Calculate all label positions using the cached paths
        // Use the larger dimension from start and end point sizes
        final startSize = currentTheme.connectionTheme.startPoint.size;
        final endSize = currentTheme.connectionTheme.endPoint.size;
        final effectiveEndpointSize = Size(
          math.max(startSize.width, endSize.width),
          math.max(startSize.height, endSize.height),
        );

        final labelRects = LabelCalculator.calculateAllLabelPositions(
          connection: connection,
          sourceNode: sourceNode,
          targetNode: targetNode,
          connectionStyle: effectiveStyle,
          curvature: currentTheme.connectionTheme.bezierCurvature,
          endpointSize: effectiveEndpointSize,
          labelTheme: currentTheme.labelTheme,
          pathCache: controller.connectionPainter.pathCache,
          portExtension: currentTheme.connectionTheme.portExtension,
          startGap:
              connection.startGap ?? currentTheme.connectionTheme.startGap,
          endGap: connection.endGap ?? currentTheme.connectionTheme.endGap,
        );

        if (labelRects.isEmpty) {
          return const SizedBox.shrink();
        }

        return _buildLabelWidgets(context, labels, labelRects, currentTheme);
      },
    );
  }

  Widget _buildLabelWidgets(
    BuildContext context,
    List<ConnectionLabel> labels,
    List<Rect> labelRects,
    NodeFlowTheme currentTheme,
  ) {
    final labelWidgets = <Widget>[];
    final labelTheme = currentTheme.labelTheme;

    // Build a widget for each label
    for (var i = 0; i < math.min(labels.length, labelRects.length); i++) {
      final label = labels[i];
      final rect = labelRects[i];

      // Use custom label builder if provided, passing onLabelTap for selection handling
      final labelWidget = labelBuilder != null
          ? labelBuilder!(context, connection, label, rect, onLabelTap)
          : _TappableLabelWidget(
              text: label.text,
              labelTheme: labelTheme,
              anchor: label.anchor,
              onTap: onLabelTap,
              visualSize: rect.size,
            );

      // Position the label at the calculated position
      // Pass the calculated visual size to ensure correct anchoring
      labelWidgets.add(
        Positioned(
          key: ValueKey('label_${connection.id}_${label.id}'),
          left: rect.left,
          top: rect.top,
          child: labelWidget,
        ),
      );
    }

    return UnboundedStack(clipBehavior: Clip.none, children: labelWidgets);
  }
}

/// Private widget for rendering a tappable label with proper interaction
class _TappableLabelWidget extends StatelessWidget {
  const _TappableLabelWidget({
    required this.text,
    required this.labelTheme,
    required this.anchor,
    this.onTap,
    required this.visualSize,
  });

  final String text;
  final LabelTheme labelTheme;
  final double anchor;
  final VoidCallback? onTap;
  final Size visualSize;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: Container(
          width: visualSize.width,
          height: visualSize.height,
          decoration: BoxDecoration(
            color: labelTheme.backgroundColor,
            borderRadius: labelTheme.borderRadius,
            border: labelTheme.border,
          ),
          child: CustomPaint(
            painter: _LabelTextPainter(
              text: text,
              textStyle: labelTheme.textStyle,
              padding: labelTheme.padding,
              maxWidth: labelTheme.maxWidth,
              maxLines: labelTheme.maxLines,
            ),
          ),
        ),
      ),
    );
  }
}

/// Private CustomPainter that paints label text using TextPainter
/// This ensures the text is rendered exactly as it was measured in LabelCalculator
class _LabelTextPainter extends CustomPainter {
  _LabelTextPainter({
    required this.text,
    required this.textStyle,
    required this.padding,
    required this.maxWidth,
    required this.maxLines,
  });

  final String text;
  final TextStyle textStyle;
  final EdgeInsets padding;
  final double maxWidth;
  final int? maxLines;

  @override
  void paint(Canvas canvas, Size size) {
    // Create TextPainter with same parameters as calculator
    final textPainter = TextPainter(
      text: TextSpan(text: text, style: textStyle),
      textDirection: TextDirection.ltr,
      maxLines: maxLines,
      textAlign: TextAlign.center,
      ellipsis: '...',
    );

    // Layout with same maxWidth constraint as calculator
    final maxTextWidth = maxWidth.isFinite ? maxWidth : double.infinity;
    textPainter.layout(maxWidth: maxTextWidth);

    // Calculate position to center the text within the padded area
    final textWidth = textPainter.width;
    final textHeight = textPainter.height;

    // Available space after padding
    final availableWidth = size.width - padding.horizontal;
    final availableHeight = size.height - padding.vertical;

    // Center the text
    final dx = padding.left + (availableWidth - textWidth) / 2;
    final dy = padding.top + (availableHeight - textHeight) / 2;

    // Paint the text
    textPainter.paint(canvas, Offset(dx, dy));
  }

  @override
  bool shouldRepaint(_LabelTextPainter oldDelegate) {
    return text != oldDelegate.text ||
        textStyle != oldDelegate.textStyle ||
        padding != oldDelegate.padding ||
        maxWidth != oldDelegate.maxWidth ||
        maxLines != oldDelegate.maxLines;
  }
}
