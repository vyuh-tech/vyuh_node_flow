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
            final simplifyPaths = controller.lod?.useThumbnailMode ?? false;
            final skipEndpoints =
                simplifyPaths ||
                !(controller.lod?.showConnectionEndpoints ?? true);

            for (final connection in controller.visibleConnections) {
              // Active edges are painted exclusively by the interaction layer.
              if (activeIds.contains(connection.id)) continue;

              final hasAnimation =
                  connection.getEffectiveAnimationEffect(
                    themeAnimationEffect,
                  ) !=
                  null;
              (hasAnimation ? animatedConnections : staticConnections).add(
                connection,
              );
            }

            final staticSnapshot = controller.connectionPainter
                .buildRenderSnapshot<T, C>(
                  connections: staticConnections,
                  nodeForId: controller.getNode,
                  selectedIds: controller.selectedConnectionIds,
                  skipEndpoints: skipEndpoints,
                  simplifyPaths: simplifyPaths,
                  retainOverviewBatches: true,
                  connectionStyleBuilder: connectionStyleBuilder,
                );
            final animatedSnapshot = controller.connectionPainter
                .buildRenderSnapshot<T, C>(
                  connections: animatedConnections,
                  nodeForId: controller.getNode,
                  selectedIds: controller.selectedConnectionIds,
                  skipEndpoints: skipEndpoints,
                  simplifyPaths: simplifyPaths,
                  connectionStyleBuilder: connectionStyleBuilder,
                );

            return Stack(
              children: [
                if (staticSnapshot.isNotEmpty)
                  RepaintBoundary(
                    child: CustomPaint(
                      key: const ValueKey('connections-static'),
                      painter: ConnectionsCanvas<T, C>.fromSnapshot(
                        snapshot: staticSnapshot,
                        connectionPainter: controller.connectionPainter,
                      ),
                      size: Size.infinite,
                    ),
                  ),
                if (animatedSnapshot.isNotEmpty)
                  RepaintBoundary(
                    child: CustomPaint(
                      key: const ValueKey('connections-animated'),
                      painter: ConnectionsCanvas<T, C>.fromSnapshot(
                        snapshot: animatedSnapshot,
                        connectionPainter: controller.connectionPainter,
                        animation: animation,
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
            final activeIds = controller.activeConnectionIds;

            if (activeIds.isEmpty) return const SizedBox.shrink();

            // Resolve only the active IDs through the controller's O(1)
            // connection index. Scanning every connection here makes each drag
            // frame proportional to the total edge count rather than the
            // dragged node's degree.
            final activeConnections = [
              for (final id in activeIds) ?controller.getConnection(id),
            ];
            final snapshot = controller.connectionPainter
                .buildRenderSnapshot<T, C>(
                  connections: activeConnections,
                  nodeForId: controller.getNode,
                  selectedIds: controller.selectedConnectionIds,
                  skipEndpoints:
                      (controller.lod?.useThumbnailMode ?? false) ||
                      !(controller.lod?.showConnectionEndpoints ?? true),
                  simplifyPaths: controller.lod?.useThumbnailMode ?? false,
                  connectionStyleBuilder: connectionStyleBuilder,
                );

            return CustomPaint(
              key: const ValueKey('connections-active'),
              painter: ConnectionsCanvas<T, C>.fromSnapshot(
                snapshot: snapshot,
                connectionPainter: controller.connectionPainter,
                animation: animation,
              ),
              size: Size.infinite,
            );
          },
        ),
      ],
    );
  }
}
