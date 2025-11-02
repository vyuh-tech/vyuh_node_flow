import 'package:flutter/material.dart';

import '../graph/node_flow_controller.dart';
import '../graph/node_flow_theme.dart';
import '../graph/selection_painter.dart';
import 'connection_painter.dart';

/// Custom painter for rendering all connections in the node flow canvas.
///
/// This painter is responsible for drawing connection lines and their endpoint
/// markers (but not labels, which are rendered in a separate layer for
/// performance reasons). It also optionally renders snap guides during node
/// dragging operations.
///
/// ## Performance Considerations
/// - Uses a shared [ConnectionPainter] for path caching and reuse
/// - Relies on InteractiveViewer for viewport clipping (no manual culling)
/// - Separates connection rendering from label rendering for better performance
///
/// ## Usage
/// This painter is used internally by the node flow rendering system and
/// typically doesn't need to be instantiated directly by users.
///
/// ```dart
/// CustomPaint(
///   painter: ConnectionsCanvas<MyDataType>(
///     store: controller,
///     theme: theme,
///     connectionPainter: sharedPainter,
///     snapGuides: [Offset(100, 0), Offset(0, 100)],
///   ),
/// )
/// ```
///
/// See also:
/// - [ConnectionPainter] for the actual connection rendering logic
/// - [NodeFlowController] for managing connections
class ConnectionsCanvas<T> extends CustomPainter {
  /// Creates a connections canvas painter.
  ///
  /// Parameters:
  /// - [store]: The node flow controller containing connection data
  /// - [theme]: The visual theme for rendering
  /// - [connectionPainter]: Shared painter instance for path caching
  /// - [snapGuides]: Optional list of snap guide positions to render
  const ConnectionsCanvas({
    required this.store,
    required this.theme,
    required this.connectionPainter,
    this.snapGuides = const [],
  });

  /// The node flow controller containing all connection data.
  final NodeFlowController<T> store;

  /// The visual theme for rendering connections and snap guides.
  final NodeFlowTheme theme;

  /// Shared connection painter instance for path caching and reuse.
  ///
  /// Using a shared instance ensures paths are cached and reused for both
  /// painting and hit testing, improving performance.
  final ConnectionPainter connectionPainter;

  /// Optional snap guide positions to render during node dragging.
  ///
  /// Snap guides are vertical/horizontal lines that help align nodes
  /// during drag operations.
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

  /// Paints all connections in the node flow.
  ///
  /// This method iterates through all connections and renders their paths
  /// and endpoint markers. It skips connections whose nodes are not found
  /// (e.g., during deletion operations).
  ///
  /// Note: Labels are intentionally NOT rendered here - they are rendered
  /// in a separate layer for better performance and to avoid text rendering
  /// issues during rapid repaints.
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
      connectionPainter.paintConnection(
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
    // This is necessary because MobX observables may have changed
    return true;
  }

  @override
  bool shouldRebuildSemantics(ConnectionsCanvas<T> oldDelegate) => false;
}
