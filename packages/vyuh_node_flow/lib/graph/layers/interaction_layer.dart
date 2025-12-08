import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';

import '../../connections/temporary_connection.dart';
import '../../ports/port.dart';
import '../node_flow_controller.dart';
import '../node_flow_theme.dart';

/// Interaction layer widget that renders temporary connections and selection rectangles.
///
/// This layer is positioned outside the InteractiveViewer (as a peer to the MinimapOverlay)
/// to ensure that interactions can be rendered anywhere on the infinite canvas without
/// being clipped by the viewport bounds. The layer applies the canvas transform internally
/// to convert graph coordinates to screen coordinates for rendering.
///
/// This layer uses [IgnorePointer] since it's purely for rendering - all event handling
/// is done by the [Listener] that wraps the InteractiveViewer in the parent widget.
class InteractionLayer<T> extends StatelessWidget {
  const InteractionLayer({
    super.key,
    required this.controller,
    required this.transformationController,
    this.animation,
  });

  final NodeFlowController<T> controller;

  /// The transformation controller that provides the current canvas transform.
  ///
  /// Used to convert graph coordinates to screen coordinates for rendering
  /// the selection rectangle and temporary connections.
  final TransformationController transformationController;

  /// Optional animation for animated temporary connections.
  ///
  /// When provided, the animation value will be passed to temporary connections
  /// for rendering animation effects (if configured in the theme).
  final Animation<double>? animation;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
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
                transformationController: transformationController,
                animation: animation,
              ),
              size: Size.infinite,
            );
          },
        ),
      ),
    );
  }
}

/// Custom painter for the interaction layer.
///
/// This painter applies the canvas transform to convert graph coordinates
/// to screen coordinates, enabling rendering of elements that extend beyond
/// the visible viewport bounds.
///
/// Listens to both [transformationController] and [animation] for repaints.
class InteractionLayerPainter<T> extends CustomPainter {
  InteractionLayerPainter({
    required this.controller,
    required this.theme,
    required this.selectionRectangle,
    required this.temporaryConnection,
    required this.transformationController,
    this.animation,
  }) : super(
         repaint: animation != null
             ? Listenable.merge([transformationController, animation])
             : transformationController,
       );

  final NodeFlowController<T> controller;
  final NodeFlowTheme theme;
  final Rect? selectionRectangle;
  final TemporaryConnection? temporaryConnection;

  /// The transformation controller to read the current transform from.
  final TransformationController transformationController;

  /// Optional animation for animated temporary connections.
  final Animation<double>? animation;

  @override
  void paint(Canvas canvas, Size size) {
    // Apply the canvas transform to convert graph coordinates to screen coordinates
    canvas.save();
    canvas.transform(transformationController.value.storage);

    // Draw selection rectangle (in graph coordinates)
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

    // Draw temporary connection (in graph coordinates)
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
        animationValue: animation?.value,
      );
    }

    canvas.restore();
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
