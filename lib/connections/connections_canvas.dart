import 'package:flutter/material.dart';

import '../graph/node_flow_controller.dart';
import '../graph/node_flow_theme.dart';
import '../graph/selection_painter.dart';
import 'connection_painter.dart';

class ConnectionsCanvas<T> extends CustomPainter {
  const ConnectionsCanvas({
    required this.store,
    required this.theme,
    required this.connectionPainter,
    this.snapGuides = const [],
  });

  final NodeFlowController<T> store;
  final NodeFlowTheme theme;
  final ConnectionPainter connectionPainter;
  final List<Offset> snapGuides;

  @override
  void paint(Canvas canvas, Size size) {
    // Paint connections only (temporary connection moved to interaction layer)
    _paintConnections(canvas);

    // Paint snap guides (InteractiveViewer handles coordinates)
    if (snapGuides.isNotEmpty) {
      final selectionPainter = SelectionPainter(theme: theme);
      selectionPainter.paintSnapGuides(canvas, size, snapGuides);
    }
  }

  void _paintConnections(Canvas canvas) {
    // Use the shared cached connection painter
    // This ensures paths are cached and reused for both painting and hit testing

    // Always use all connections - let InteractiveViewer handle visibility
    // This avoids expensive visibility computation during panning
    final connectionsToRender = store.connections;

    // Paint only connection lines and endpoints (no labels)
    // Labels are now rendered in a separate layer for better performance
    for (final connection in connectionsToRender) {
      final sourceNode = store.getNode(connection.sourceNodeId);
      final targetNode = store.getNode(connection.targetNodeId);

      if (sourceNode == null || targetNode == null) continue;

      final isSelected = store.selectedConnectionIds.contains(connection.id);
      final isAnimated = connection.animated;

      // Paint connection without labels using cached painter
      connectionPainter.paintConnectionOnly(
        canvas,
        connection,
        sourceNode,
        targetNode,
        isSelected: isSelected,
        isAnimated: isAnimated,
      );
    }
  }

  @override
  bool shouldRepaint(ConnectionsCanvas<T> oldDelegate) {
    // Always repaint when Observer rebuilds this painter
    return true;
  }

  @override
  bool shouldRebuildSemantics(ConnectionsCanvas<T> oldDelegate) => false;
}
