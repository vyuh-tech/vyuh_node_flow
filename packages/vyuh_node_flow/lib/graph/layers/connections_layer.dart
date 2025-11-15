import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';

import '../../connections/connections_canvas.dart';
import '../node_flow_controller.dart';
import '../node_flow_theme.dart';

/// Connections layer widget that renders all connections between nodes
class ConnectionsLayer<T> extends StatelessWidget {
  const ConnectionsLayer({super.key, required this.controller, this.animation});

  final NodeFlowController<T> controller;
  final Animation<double>? animation;

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: RepaintBoundary(
        child: Observer(
          builder: (context) {
            // Only observe actual connections, not temporary ones
            controller.connections.length;
            controller.selectedConnectionIds.length;

            // Force tracking of node positions during drag for connection updates
            for (final node in controller.nodes.values) {
              node.position.value; // Trigger observation
            }

            // Force tracking of animation effects and control points on connections
            for (final connection in controller.connections) {
              connection.animationEffect; // Trigger observation
              // Observe control points by accessing each item to track changes
              for (var i = 0; i < connection.controlPoints.length; i++) {
                connection
                    .controlPoints[i]; // Force observation of each control point
              }
            }

            // Get theme from context - this ensures automatic rebuilds when theme changes
            final theme =
                Theme.of(context).extension<NodeFlowTheme>() ??
                NodeFlowTheme.light;

            return CustomPaint(
              painter: ConnectionsCanvas<T>(
                store: controller,
                theme: theme,
                connectionPainter: controller.connectionPainter,
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
