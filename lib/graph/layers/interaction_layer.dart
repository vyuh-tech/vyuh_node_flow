import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';

import '../../connections/temporary_connection.dart';
import '../../ports/port.dart';
import '../node_flow_controller.dart';
import '../node_flow_theme.dart';

/// Interaction layer widget that renders temporary connections and selection rectangles
class InteractionLayer<T> extends StatelessWidget {
  const InteractionLayer({super.key, required this.controller});

  final NodeFlowController<T> controller;

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: IgnorePointer(
        child: RepaintBoundary(
          child: Observer(
            builder: (builderContext) {
              // Observe selection rectangle
              final selectionRectangle = controller.selectionRectangle;

              // Observe temporary connection and its changing properties
              final tempConnection = controller.temporaryConnection;
              if (tempConnection != null) {
                tempConnection.currentPoint;
                tempConnection.targetNodeId;
                tempConnection.targetPortId;
              }

              // Get theme from context - this ensures automatic rebuilds when theme changes
              final theme =
                  Theme.of(builderContext).extension<NodeFlowTheme>() ??
                  NodeFlowTheme.light;

              return CustomPaint(
                painter: InteractionLayerPainter<T>(
                  controller: controller,
                  theme: theme,
                  selectionRectangle: selectionRectangle,
                  temporaryConnection: tempConnection,
                ),
                size: Size.infinite,
              );
            },
          ),
        ),
      ),
    );
  }
}

/// Custom painter for the interaction layer
class InteractionLayerPainter<T> extends CustomPainter {
  const InteractionLayerPainter({
    required this.controller,
    required this.theme,
    required this.selectionRectangle,
    required this.temporaryConnection,
  });

  final NodeFlowController<T> controller;
  final NodeFlowTheme theme;
  final Rect? selectionRectangle;
  final TemporaryConnection? temporaryConnection;

  @override
  void paint(Canvas canvas, Size size) {
    // Draw selection rectangle
    if (selectionRectangle != null) {
      final paint = Paint()
        ..color = theme.connectionTheme.color.withValues(alpha: 0.2)
        ..style = PaintingStyle.fill;

      final borderPaint = Paint()
        ..color = theme.connectionTheme.color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.0;

      canvas.drawRect(selectionRectangle!, paint);
      canvas.drawRect(selectionRectangle!, borderPaint);
    }

    // Draw temporary connection
    if (temporaryConnection != null) {
      Port? sourcePort;
      Port? targetPort;

      // Get source port
      final sourceNode = controller.nodes[temporaryConnection!.sourceNodeId];
      if (sourceNode != null) {
        for (final port in sourceNode.outputPorts) {
          if (port.id == temporaryConnection!.sourcePortId) {
            sourcePort = port;
            break;
          }
        }
      }

      // Get target port if available
      if (temporaryConnection!.targetNodeId != null &&
          temporaryConnection!.targetPortId != null) {
        final targetNode = controller.nodes[temporaryConnection!.targetNodeId!];
        if (targetNode != null) {
          for (final port in targetNode.inputPorts) {
            if (port.id == temporaryConnection!.targetPortId) {
              targetPort = port;
              break;
            }
          }
        }
      }

      controller.connectionPainter.paintTemporaryConnection(
        canvas,
        temporaryConnection!.startPoint,
        temporaryConnection!.currentPoint,
        sourcePort: sourcePort,
        targetPort: targetPort,
        isReversed: false,
      );
    }
  }

  @override
  bool shouldRepaint(InteractionLayerPainter<T> oldDelegate) {
    // Always repaint if we have a temporary connection to ensure real-time updates
    if (temporaryConnection != null ||
        oldDelegate.temporaryConnection != null) {
      return true;
    }

    return selectionRectangle != oldDelegate.selectionRectangle;
  }
}
