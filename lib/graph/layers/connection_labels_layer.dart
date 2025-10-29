import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_mobx/flutter_mobx.dart';

import '../../connections/connection.dart';
import '../../connections/edge_label_position_calculator.dart';
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
            return connection.label != null ||
                connection.startLabel != null ||
                connection.endLabel != null;
          }).toList();

          return Stack(
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

        // Observe connection label changes
        final startLabel = connection.startLabel;
        final endLabel = connection.endLabel;
        final centerLabel = connection.label;

        // Skip rendering if no labels
        if (startLabel == null && endLabel == null && centerLabel == null) {
          return const SizedBox.shrink();
        }

        // Get theme from context - this ensures automatic rebuilds when theme changes
        final currentTheme =
            Theme.of(context).extension<NodeFlowTheme>() ?? NodeFlowTheme.light;

        // Calculate all label positions using convenience method
        final labelPositions =
            EdgeLabelPositionCalculator.calculateAllLabelPositions(
              connection: connection,
              sourceNode: sourceNode,
              targetNode: targetNode,
              connectionStyle: currentTheme.connectionStyle,
              curvature: currentTheme.connectionTheme.bezierCurvature,
              portSize: currentTheme.portTheme.size,
              endpointSize: math.max(
                currentTheme.connectionTheme.startPoint.size,
                currentTheme.connectionTheme.endPoint.size,
              ),
              labelTheme: currentTheme.labelTheme,
            );

        if (labelPositions == null) {
          return const SizedBox.shrink();
        }

        return _buildLabelWidgets(labelPositions, currentTheme);
      },
    );
  }

  Widget _buildLabelWidgets(
    LabelPositionData positions,
    NodeFlowTheme currentTheme,
  ) {
    final labelWidgets = <Widget>[];
    final labelTheme = currentTheme.labelTheme;

    // Add center label if available
    if (positions.centerRect != null && connection.label != null) {
      labelWidgets.add(
        Positioned.fromRect(
          rect: positions.centerRect!,
          child: _TappableLabelWidget(
            text: connection.label!,
            labelTheme: labelTheme,
            onTap: onLabelTap,
          ),
        ),
      );
    }

    // Add start label if available
    if (positions.startRect != null && connection.startLabel != null) {
      labelWidgets.add(
        Positioned.fromRect(
          rect: positions.startRect!,
          child: _TappableLabelWidget(
            text: connection.startLabel!,
            labelTheme: labelTheme,
            onTap: onLabelTap,
          ),
        ),
      );
    }

    // Add end label if available
    if (positions.endRect != null && connection.endLabel != null) {
      labelWidgets.add(
        Positioned.fromRect(
          rect: positions.endRect!,
          child: _TappableLabelWidget(
            text: connection.endLabel!,
            labelTheme: labelTheme,
            onTap: onLabelTap,
          ),
        ),
      );
    }

    return Stack(children: labelWidgets);
  }
}

/// Private widget for rendering a tappable label with proper interaction
class _TappableLabelWidget extends StatelessWidget {
  const _TappableLabelWidget({
    required this.text,
    required this.labelTheme,
    this.onTap,
  });

  final String text;
  final LabelTheme labelTheme;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: labelTheme.padding,
          decoration: BoxDecoration(
            color: labelTheme.backgroundColor,
            borderRadius: BorderRadius.circular(labelTheme.borderRadius),
            border: labelTheme.borderColor != null && labelTheme.borderWidth > 0
                ? Border.all(
                    color: labelTheme.borderColor!,
                    width: labelTheme.borderWidth,
                  )
                : null,
          ),
          child: Text(text, style: labelTheme.textStyle),
        ),
      ),
    );
  }
}

// Old CustomPaint approach removed - now using positioned widgets
