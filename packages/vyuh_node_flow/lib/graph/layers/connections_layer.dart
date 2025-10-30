import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';

import '../../connections/connections_canvas.dart';
import '../node_flow_controller.dart';
import '../node_flow_theme.dart';

/// Connections layer widget that renders all connections between nodes
class ConnectionsLayer<T> extends StatelessWidget {
  const ConnectionsLayer({super.key, required this.controller});

  final NodeFlowController<T> controller;

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

            // Get theme from context - this ensures automatic rebuilds when theme changes
            final theme =
                Theme.of(context).extension<NodeFlowTheme>() ??
                NodeFlowTheme.light;

            return CustomPaint(
              painter: ConnectionsCanvas<T>(
                store: controller,
                theme: theme,
                connectionPainter: controller.connectionPainter,
                snapGuides: const [],
              ),
              size: Size.infinite,
            );
          },
        ),
      ),
    );
  }
}
