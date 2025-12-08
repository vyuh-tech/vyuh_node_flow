import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:mobx/mobx.dart';

import '../../connections/connection.dart';
import '../node_flow_controller.dart';
import '../node_flow_theme.dart';

/// Layer that renders interactive control points for editable connections.
///
/// This layer displays draggable widgets at each control point position,
/// allowing users to:
/// - Move existing control points by dragging
/// - Visualize the waypoints that define the connection path
///
/// The layer sits above the connection lines but below the nodes layer,
/// ensuring control points are visible but don't interfere with node interaction.
///
/// Control points are only rendered for connections that:
/// - Have a non-empty [Connection.controlPoints] list
/// - Use an editable connection style
class ConnectionControlPointsLayer<T> extends StatelessWidget {
  const ConnectionControlPointsLayer({super.key, required this.controller});

  final NodeFlowController<T> controller;

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: Observer(
        builder: (context) {
          // Observe connections list changes
          final connections = controller.connections;

          // Filter to only connections that have control points
          final connectionsWithControlPoints = connections.where((connection) {
            return connection.controlPoints.isNotEmpty;
          }).toList();

          if (connectionsWithControlPoints.isEmpty) {
            return const SizedBox.shrink();
          }

          return Stack(
            clipBehavior: Clip.none,
            children: connectionsWithControlPoints.map((connection) {
              return _ConnectionControlPointsWidget<T>(
                key: ValueKey('control_points_${connection.id}'),
                connection: connection,
                controller: controller,
              );
            }).toList(),
          );
        },
      ),
    );
  }
}

/// Individual widget for rendering a single connection's control points.
///
/// This provides granular repaint boundaries for control point updates and
/// manages the dragging interaction for each control point.
class _ConnectionControlPointsWidget<T> extends StatelessWidget {
  const _ConnectionControlPointsWidget({
    super.key,
    required this.connection,
    required this.controller,
  });

  final Connection connection;
  final NodeFlowController<T> controller;

  @override
  Widget build(BuildContext context) {
    return Observer(
      builder: (context) {
        // Observe control points changes
        final controlPoints = connection.controlPoints;

        if (controlPoints.isEmpty) {
          return const SizedBox.shrink();
        }

        // Get theme from context
        final theme =
            Theme.of(context).extension<NodeFlowTheme>() ?? NodeFlowTheme.light;

        // Build widgets for each control point
        final widgets = <Widget>[];
        for (int i = 0; i < controlPoints.length; i++) {
          final point = controlPoints[i];

          widgets.add(
            _DraggableControlPoint(
              key: ValueKey('cp_${connection.id}_$i'),
              connection: connection,
              controlPointIndex: i,
              position: point,
              controller: controller,
              theme: theme,
            ),
          );
        }

        return Stack(clipBehavior: Clip.none, children: widgets);
      },
    );
  }
}

/// A draggable control point widget that allows users to move waypoints.
///
/// This widget renders as a small circular handle that can be dragged to
/// modify the connection path.
class _DraggableControlPoint<T> extends StatefulWidget {
  const _DraggableControlPoint({
    super.key,
    required this.connection,
    required this.controlPointIndex,
    required this.position,
    required this.controller,
    required this.theme,
  });

  final Connection connection;
  final int controlPointIndex;
  final Offset position;
  final NodeFlowController<T> controller;
  final NodeFlowTheme theme;

  @override
  State<_DraggableControlPoint<T>> createState() =>
      _DraggableControlPointState<T>();
}

class _DraggableControlPointState<T> extends State<_DraggableControlPoint<T>> {
  bool _isDragging = false;
  bool _isHovering = false;

  @override
  Widget build(BuildContext context) {
    // Determine if this is a smooth step style connection
    final effectiveStyle = widget.connection.getEffectiveStyle(
      widget.theme.connectionTheme.style,
    );
    final isSmoothStep = effectiveStyle.id == 'editable-smoothstep';

    // Control point size and style - different for smooth step
    final double size = isSmoothStep ? 10.0 : 12.0;
    final double hoverSize = isSmoothStep ? 14.0 : 16.0;
    final double hitTargetSize = 24.0;

    final effectiveSize = _isDragging || _isHovering ? hoverSize : size;
    final color = widget.theme.connectionTheme.selectedColor;
    final backgroundColor = Colors.white;

    return Positioned(
      left: widget.position.dx - (hitTargetSize / 2),
      top: widget.position.dy - (hitTargetSize / 2),
      child: GestureDetector(
        onPanStart: (details) {
          setState(() {
            _isDragging = true;
          });
        },
        onPanUpdate: (details) {
          // Update control point position
          _updateControlPoint(details.delta);
        },
        onPanEnd: (details) {
          setState(() {
            _isDragging = false;
          });
          // Rebuild spatial index for this connection after drag ends
          widget.controller.rebuildConnectionSegmentsForNodes([
            widget.connection.sourceNodeId,
            widget.connection.targetNodeId,
          ]);
        },
        child: MouseRegion(
          cursor: SystemMouseCursors.move,
          onEnter: (_) {
            setState(() {
              _isHovering = true;
            });
          },
          onExit: (_) {
            setState(() {
              _isHovering = false;
            });
          },
          child: Container(
            width: hitTargetSize,
            height: hitTargetSize,
            alignment: Alignment.center,
            child: Container(
              width: effectiveSize,
              height: effectiveSize,
              decoration: BoxDecoration(
                // Use rectangle for smooth step, circle for others
                shape: isSmoothStep ? BoxShape.rectangle : BoxShape.circle,
                borderRadius: isSmoothStep ? BorderRadius.circular(2.0) : null,
                color: backgroundColor,
                border: Border.all(color: color, width: 2.0),
                boxShadow: _isDragging || _isHovering
                    ? [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.2),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ]
                    : null,
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _updateControlPoint(Offset delta) {
    if (widget.controlPointIndex < 0 ||
        widget.controlPointIndex >= widget.connection.controlPoints.length) {
      return;
    }

    // Update the specific control point directly in the observable list
    // This will trigger MobX observers and repaint the connection
    final newPosition =
        widget.connection.controlPoints[widget.controlPointIndex] + delta;

    runInAction(() {
      widget.connection.controlPoints[widget.controlPointIndex] = newPosition;
    });

    // Invalidate the path cache for this connection
    widget.controller.connectionPainter.pathCache.removeConnection(
      widget.connection.id,
    );
  }
}
