import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';

import '../../connections/styles/connection_style_base.dart';
import '../../connections/temporary_connection.dart';
import '../../graph/coordinates.dart';
import '../../nodes/node.dart';
import '../../ports/port.dart';
import '../controller/node_flow_controller.dart';
import '../themes/node_flow_theme.dart';

typedef TemporaryConnectionStyleResolver<T> =
    ConnectionStyle? Function(
      TemporaryConnection temporary,
      Node<T> startNode,
      Port startPort,
      Node<T>? hoveredNode,
      Port? hoveredPort,
    );

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
    this.temporaryStyleResolver,
  });

  final NodeFlowController<T, dynamic> controller;

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

  /// Optional resolver for temporary connection routing style.
  ///
  /// Use this to align temporary routing with final connection style selection
  /// (for example, when using dynamic `connectionStyleBuilder`).
  final TemporaryConnectionStyleResolver<T>? temporaryStyleResolver;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: RepaintBoundary(
        child: Observer(
          builder: (builderContext) {
            // Observe selection rectangle (in graph coordinates, typed as GraphRect)
            final selectionRect = controller.selectionRect;

            // Observe temporary connection and its changing properties
            final tempConnection = controller.temporaryConnection;
            if (tempConnection != null) {
              tempConnection.currentPoint;
              tempConnection.targetNodeId;
              tempConnection.targetPortId;
            }

            // Observe preview connections (for edge insertion preview etc.)
            final previewConnections = controller.interaction.previewConnections
                .toList();

            final hasInteractionVisuals =
                selectionRect != null ||
                tempConnection != null ||
                previewConnections.isNotEmpty;

            // Get theme from context - this ensures automatic rebuilds when theme changes
            final theme =
                Theme.of(builderContext).extension<NodeFlowTheme>() ??
                NodeFlowTheme.light;

            return CustomPaint(
              painter: InteractionLayerPainter<T>(
                controller: controller,
                theme: theme,
                selectionRect: selectionRect,
                temporaryConnection: tempConnection,
                previewConnections: previewConnections,
                transformationController: transformationController,
                animation: animation,
                temporaryStyleResolver: temporaryStyleResolver,
                listenToTransform: hasInteractionVisuals,
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
/// Listens to [transformationController] (and optionally [animation]) only when
/// interaction visuals are active.
class InteractionLayerPainter<T> extends CustomPainter {
  InteractionLayerPainter({
    required this.controller,
    required this.theme,
    required this.selectionRect,
    required this.temporaryConnection,
    this.previewConnections = const [],
    required this.transformationController,
    this.animation,
    this.temporaryStyleResolver,
    this.listenToTransform = true,
  }) : super(
         repaint: listenToTransform
             ? (animation != null
                   ? Listenable.merge([transformationController, animation])
                   : transformationController)
             : null,
       );

  final NodeFlowController<T, dynamic> controller;
  final NodeFlowTheme theme;

  /// Selection rectangle in graph coordinates.
  ///
  /// Uses [GraphRect] for compile-time type safety, matching node positions
  /// for accurate hit testing during selection drag operations.
  final GraphRect? selectionRect;
  final TemporaryConnection? temporaryConnection;

  /// Preview connections for visualization (e.g., edge insertion preview).
  /// Rendered with the same styling as temporary connections.
  final List<TemporaryConnection> previewConnections;

  /// The transformation controller to read the current transform from.
  final TransformationController transformationController;

  /// Optional animation for animated temporary connections.
  final Animation<double>? animation;

  /// Optional resolver for temporary connection routing style.
  final TemporaryConnectionStyleResolver<T>? temporaryStyleResolver;

  /// Whether this painter should listen to viewport transform updates.
  ///
  /// Disabled when there are no interaction visuals, avoiding redundant
  /// repaint scheduling while panning an otherwise idle canvas.
  final bool listenToTransform;

  @override
  void paint(Canvas canvas, Size size) {
    // Apply the canvas transform to convert graph coordinates to screen coordinates
    canvas.save();
    canvas.transform(transformationController.value.storage);

    // Draw selection rectangle in graph coordinates.
    // Since we've applied the canvas transform, the rectangle (which is already
    // in graph coordinates) will be correctly positioned on screen.
    if (selectionRect != null) {
      final paint = Paint()
        ..color = theme.connectionTheme.color.withValues(alpha: 0.2)
        ..style = PaintingStyle.fill;

      final borderPaint = Paint()
        ..color = theme.connectionTheme.color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.0;

      // Extract the underlying Rect from GraphRect for Canvas API
      canvas.drawRect(selectionRect!.rect, paint);
      canvas.drawRect(selectionRect!.rect, borderPaint);
    }

    // Draw temporary connection (in graph coordinates)
    if (temporaryConnection != null) {
      final temp = temporaryConnection!;
      final isStartFromOutput = temp.isStartFromOutput;
      final portTheme = controller.theme?.portTheme;

      // Get the starting port and node (where drag began)
      Port? startPort;
      final startNode = controller.nodes[temp.startNodeId];
      if (startNode != null) {
        startPort = startNode.findPort(temp.startPortId);
      }

      // Get the hovered port and node if available (where mouse is hovering)
      Port? hoveredPort;
      Node<T>? hoveredNode;
      if (temp.targetNodeId != null && temp.targetPortId != null) {
        hoveredNode = controller.nodes[temp.targetNodeId!];
        if (hoveredNode != null) {
          hoveredPort = hoveredNode.findPort(temp.targetPortId!);
        }
      }

      // Calculate the hovered port's connection point if hovering over a valid port.
      // This ensures the temporary connection snaps to the correct port position,
      // matching the actual connection routing behavior.
      Offset? hoveredPortPoint;
      if (hoveredNode != null && hoveredPort != null) {
        final portSize =
            hoveredPort.size ?? portTheme?.size ?? const Size(12, 12);
        final shape = controller.nodeShapeBuilder?.call(hoveredNode);
        hoveredPortPoint = hoveredNode.getConnectionPoint(
          hoveredPort.id,
          portSize: portSize,
          shape: shape,
        );
      }

      // Determine actual source/target based on port direction:
      // - If started from output: start port is SOURCE, hovered/mouse is TARGET
      // - If started from input: start port is TARGET, hovered/mouse is SOURCE
      final Port? sourcePort;
      final Port? targetPort;
      final Offset sourcePoint;
      final Offset targetPoint;
      final Rect? sourceNodeBounds;
      final Rect? targetNodeBounds;

      if (isStartFromOutput) {
        // Output → Input: start is source, current point is target
        sourcePort = startPort;
        targetPort = hoveredPort;
        sourcePoint = temp.startPoint;
        // Use calculated port position if hovering, otherwise raw mouse position
        targetPoint = hoveredPortPoint ?? temp.currentPoint;
        sourceNodeBounds = temp.startNodeBounds;
        targetNodeBounds = temp.targetNodeBounds;
      } else {
        // Input ← Output: start is target, current point is source
        sourcePort = hoveredPort;
        targetPort = startPort;
        // Use calculated port position if hovering, otherwise raw mouse position
        sourcePoint = hoveredPortPoint ?? temp.currentPoint;
        targetPoint = temp.startPoint;
        sourceNodeBounds = temp.targetNodeBounds;
        targetNodeBounds = temp.startNodeBounds;
      }

      ConnectionStyle? overrideStyle;
      if (startNode != null && startPort != null) {
        overrideStyle = temporaryStyleResolver?.call(
          temp,
          startNode,
          startPort,
          hoveredNode,
          hoveredPort,
        );
      }

      controller.connectionPainter.paintTemporaryConnection(
        canvas,
        sourcePoint,
        targetPoint,
        sourcePort: sourcePort,
        targetPort: targetPort,
        sourceNodeBounds: sourceNodeBounds,
        targetNodeBounds: targetNodeBounds,
        overrideStyle: overrideStyle,
        animationValue: animation?.value,
      );
    }

    // Draw preview connections (for edge insertion preview, etc.)
    for (final preview in previewConnections) {
      controller.connectionPainter.paintTemporaryConnection(
        canvas,
        preview.startPoint,
        preview.currentPoint,
        sourceNodeBounds: preview.startNodeBounds,
        targetNodeBounds: preview.targetNodeBounds,
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

    // Repaint if preview connections changed
    if (previewConnections.isNotEmpty ||
        oldDelegate.previewConnections.isNotEmpty) {
      return true;
    }

    return selectionRect != oldDelegate.selectionRect ||
        listenToTransform != oldDelegate.listenToTransform;
  }
}
