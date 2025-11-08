import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_mobx/flutter_mobx.dart';

import '../../connections/connection.dart';
import '../../connections/connection_label.dart';
import '../../connections/label_calculator.dart';
import '../../connections/label_theme.dart';
import '../node_flow_controller.dart';
import '../node_flow_theme.dart';

/// Layer that renders connection labels independently from connection lines
/// This allows for optimized repainting when only labels change
class ConnectionLabelsLayer<T> extends StatelessWidget {
  const ConnectionLabelsLayer({super.key, required this.controller});

  final NodeFlowController<T> controller;

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: Observer(
        builder: (context) {
          // Observe connections list changes
          final connections = controller.connections;

          // Filter to only connections that have at least one label
          final connectionsWithLabels = connections.where((connection) {
            return connection.labels.isNotEmpty;
          }).toList();

          return Stack(
            clipBehavior: Clip.none,
            children: connectionsWithLabels.map((connection) {
              return _ConnectionLabelWidget<T>(
                key: ValueKey('label_${connection.id}'),
                connection: connection,
                controller: controller,
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
    this.onLabelTap,
  });

  final Connection connection;
  final NodeFlowController<T> controller;
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

        // Calculate all label positions using convenience method
        final labelRects = LabelCalculator.calculateAllLabelPositions(
          connection: connection,
          sourceNode: sourceNode,
          targetNode: targetNode,
          connectionStyle: currentTheme.connectionTheme.style,
          curvature: currentTheme.connectionTheme.bezierCurvature,
          portSize: currentTheme.portTheme.size,
          endpointSize: math.max(
            currentTheme.connectionTheme.startPoint.size,
            currentTheme.connectionTheme.endPoint.size,
          ),
          labelTheme: currentTheme.labelTheme,
          portExtension: currentTheme.connectionTheme.portExtension,
        );

        if (labelRects.isEmpty) {
          return const SizedBox.shrink();
        }

        return _buildLabelWidgets(labels, labelRects, currentTheme);
      },
    );
  }

  Widget _buildLabelWidgets(
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

      // Position the label at the calculated position
      // Pass the calculated visual size to ensure correct anchoring
      labelWidgets.add(
        Positioned(
          key: ValueKey('label_${connection.id}_${label.id}'),
          left: rect.left,
          top: rect.top,
          child: _TappableLabelWidget(
            text: label.text,
            labelTheme: labelTheme,
            anchor: label.anchor,
            onTap: onLabelTap,
            visualSize: rect.size,
          ),
        ),
      );
    }

    return Stack(clipBehavior: Clip.none, children: labelWidgets);
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
        // Constrain outer size to exact calculated visual size for positioning
        child: Container(
          decoration: BoxDecoration(
            color: labelTheme.backgroundColor,
            borderRadius: labelTheme.borderRadius,
            border: labelTheme.border,
          ),
          // padding: labelTheme.padding,
          width: visualSize.width,
          height: visualSize.height,
          alignment: Alignment.center,
          // Constrain text to the exact calculated text width
          child: Text(
            text,
            style: labelTheme.textStyle,
            textAlign: TextAlign.center,
            maxLines: labelTheme.maxLines,
            overflow: labelTheme.maxLines != null
                ? TextOverflow.ellipsis
                : TextOverflow.clip,
          ),
        ),
      ),
    );
  }
}
