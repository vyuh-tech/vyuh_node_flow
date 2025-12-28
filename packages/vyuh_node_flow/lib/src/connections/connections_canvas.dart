import 'package:flutter/material.dart';

import '../editor/controller/node_flow_controller.dart';
import '../editor/themes/node_flow_theme.dart';
import 'connection_painter.dart';

/// Custom painter for rendering all connections in the node flow canvas.
///
/// This painter is responsible for drawing connection lines and their endpoint
/// markers (but not labels, which are rendered in a separate layer for
/// performance reasons).
///
/// ## Performance Considerations
/// - Uses a shared [ConnectionPainter] for path caching and reuse
/// - Relies on InteractiveViewer for viewport clipping (no manual culling)
/// - Separates connection rendering from label rendering for better performance
/// - Supports animated connections via [Animation] parameter
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
///     animation: animationController,
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
  /// - [animation]: Optional animation for animated connections
  const ConnectionsCanvas({
    required this.store,
    required this.theme,
    required this.connectionPainter,
    this.animation,
  }) : super(repaint: animation);

  /// The node flow controller containing all connection data.
  final NodeFlowController<T> store;

  /// The visual theme for rendering connections.
  final NodeFlowTheme theme;

  /// Shared connection painter instance for path caching and reuse.
  ///
  /// Using a shared instance ensures paths are cached and reused for both
  /// painting and hit testing, improving performance.
  final ConnectionPainter connectionPainter;

  /// Optional animation for animated connections.
  ///
  /// When provided, the animation value will be passed to animated connections
  /// for rendering effects.
  final Animation<double>? animation;

  /// Paints all connections in the node flow.
  ///
  /// This method iterates through all connections and renders their paths
  /// and endpoint markers. It skips connections whose nodes are not found
  /// (e.g., during deletion operations).
  ///
  /// Note: Labels are intentionally NOT rendered here - they are rendered
  /// in a separate layer for better performance and to avoid text rendering
  /// issues during rapid repaints.
  @override
  void paint(Canvas canvas, Size size) {
    // Use the shared cached connection painter
    // This ensures paths are cached and reused for both painting and hit testing

    // Always use all connections - let InteractiveViewer handle visibility
    // This avoids expensive visibility computation during panning
    final connectionsToRender = store.connections;

    // Get current animation value
    final animationValue = animation?.value;

    // Paint only connection lines and endpoints (no labels)
    // Labels are now rendered in a separate layer for better performance
    for (final connection in connectionsToRender) {
      final sourceNode = store.getNode(connection.sourceNodeId);
      final targetNode = store.getNode(connection.targetNodeId);

      if (sourceNode == null || targetNode == null) continue;

      // Skip connections where either node is hidden
      if (!sourceNode.isVisible || !targetNode.isVisible) continue;

      final isSelected = store.selectedConnectionIds.contains(connection.id);

      // Paint connection without labels using cached painter
      connectionPainter.paintConnection(
        canvas,
        connection,
        sourceNode,
        targetNode,
        isSelected: isSelected,
        animationValue: animationValue,
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
