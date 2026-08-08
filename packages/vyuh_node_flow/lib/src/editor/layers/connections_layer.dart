import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';

import '../../connections/connection.dart';
import '../../connections/connections_canvas.dart';
import '../../connections/styles/connection_style_base.dart';
import '../../plugins/lod/lod_plugin.dart';
import '../controller/node_flow_controller.dart';
import '../themes/node_flow_theme.dart';

/// Connections layer widget that renders all connections between nodes
class ConnectionsLayer<T, C> extends StatelessWidget {
  const ConnectionsLayer({
    super.key,
    required this.controller,
    this.animation,
    this.connectionStyleBuilder,
  });

  final NodeFlowController<T, C> controller;
  final Animation<double>? animation;
  final ConnectionStyleBuilder<T, C>? connectionStyleBuilder;

  @override
  Widget build(BuildContext context) {
    final lod = controller.lod;

    // IgnorePointer ensures connections don't block hit tests on layers below
    return Positioned.fill(
      child: IgnorePointer(
        // If LOD extension is not configured, skip the LOD Observer check
        child: lod == null
            ? _buildConnectionsStack(context)
            : Observer(
                builder: (context) {
                  // LOD check: hide connections when zoomed out
                  if (!lod.showConnectionLines) {
                    return const SizedBox.shrink();
                  }
                  return _buildConnectionsStack(context);
                },
              ),
      ),
    );
  }

  Widget _buildConnectionsStack(BuildContext context) {
    return Stack(
      children: [
        // Permanent connections are partitioned so an animated edge never
        // causes the static display list to repaint on every animation tick.
        Observer(
          builder: (context) {
            final theme = controller.theme ?? NodeFlowTheme.light;
            final themeAnimationEffect = theme.connectionTheme.animationEffect;
            final activeIds = controller.activeConnectionIds;
            final staticConnections = <Connection<C>>[];
            final animatedConnections = <Connection<C>>[];

            controller.selectedConnectionIds.length;
            for (final connection in controller.visibleConnections) {
              // Active edges are painted exclusively by the interaction layer.
              if (activeIds.contains(connection.id)) continue;

              final sourceNode = controller.getNode(connection.sourceNodeId);
              final targetNode = controller.getNode(connection.targetNodeId);

              if (sourceNode != null) {
                sourceNode.position.value;
                sourceNode.isVisible;
              }
              if (targetNode != null) {
                targetNode.position.value;
                targetNode.isVisible;
              }

              final hasAnimation =
                  connection.getEffectiveAnimationEffect(
                    themeAnimationEffect,
                  ) !=
                  null;
              (hasAnimation ? animatedConnections : staticConnections).add(
                connection,
              );
            }

            return Stack(
              children: [
                if (staticConnections.isNotEmpty)
                  RepaintBoundary(
                    child: CustomPaint(
                      key: const ValueKey('connections-static'),
                      painter: ConnectionsCanvas<T, C>(
                        store: controller,
                        theme: theme,
                        connectionPainter: controller.connectionPainter,
                        connections: staticConnections,
                        selectedIds: controller.selectedConnectionIds,
                        connectionStyleBuilder: connectionStyleBuilder,
                      ),
                      size: Size.infinite,
                    ),
                  ),
                if (animatedConnections.isNotEmpty)
                  RepaintBoundary(
                    child: CustomPaint(
                      key: const ValueKey('connections-animated'),
                      painter: ConnectionsCanvas<T, C>(
                        store: controller,
                        theme: theme,
                        connectionPainter: controller.connectionPainter,
                        connections: animatedConnections,
                        selectedIds: controller.selectedConnectionIds,
                        animation: animation,
                        connectionStyleBuilder: connectionStyleBuilder,
                      ),
                      size: Size.infinite,
                    ),
                  ),
              ],
            );
          },
        ),

        // Active connections layer (No RepaintBoundary)
        // Renders ONLY active connections (attached to dragged/resized nodes)
        // Updates frequently (60fps) during interaction
        Observer(
          builder: (context) {
            final theme = controller.theme ?? NodeFlowTheme.light;
            final activeIds = controller.activeConnectionIds;

            if (activeIds.isEmpty) return const SizedBox.shrink();

            // Resolve only the active IDs through the controller's O(1)
            // connection index. Scanning every connection here makes each drag
            // frame proportional to the total edge count rather than the
            // dragged node's degree.
            final activeConnections = [
              for (final id in activeIds) ?controller.getConnection(id),
            ];

            // Dependency tracking for active connections
            // This triggers repaint on every frame of drag
            for (final connection in activeConnections) {
              final sourceNode = controller.getNode(connection.sourceNodeId);
              final targetNode = controller.getNode(connection.targetNodeId);

              if (sourceNode != null) {
                sourceNode.position.value;
                sourceNode.isVisible;
              }
              if (targetNode != null) {
                targetNode.position.value;
                targetNode.isVisible;
              }

              connection.animationEffect;
            }

            return CustomPaint(
              key: const ValueKey('connections-active'),
              painter: ConnectionsCanvas<T, C>(
                store: controller,
                theme: theme,
                connectionPainter: controller.connectionPainter,
                connections: activeConnections,
                selectedIds: controller.selectedConnectionIds,
                animation: animation,
                connectionStyleBuilder: connectionStyleBuilder,
              ),
              size: Size.infinite,
            );
          },
        ),
      ],
    );
  }
}
