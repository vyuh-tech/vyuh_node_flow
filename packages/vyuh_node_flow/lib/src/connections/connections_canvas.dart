import 'package:flutter/material.dart';

import '../editor/controller/node_flow_controller.dart';
import '../editor/themes/node_flow_theme.dart';
import '../plugins/lod/lod_plugin.dart';
import 'connection.dart';
import 'connection_painter.dart';
import 'styles/connection_style_base.dart';

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
///   painter: ConnectionsCanvas<MyDataType, MyConnectionData>(
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
class ConnectionsCanvas<T, C> extends CustomPainter {
  /// Creates a connections canvas painter.
  ///
  /// Parameters:
  /// - [store]: The node flow controller containing connection data
  /// - [theme]: The visual theme for rendering
  /// - [connectionPainter]: Shared painter instance for path caching
  /// - [connections]: specific connections to render (defaults to all store.connections)
  /// - [animation]: Optional animation for animated connections
  /// - [connectionStyleBuilder]: Optional builder for dynamic path style selection
  const ConnectionsCanvas({
    required this.store,
    required this.theme,
    required this.connectionPainter,
    this.connections,
    this.animation,
    this.connectionStyleBuilder,
  }) : super(repaint: animation);

  /// The node flow controller containing all connection data.
  final NodeFlowController<T, C> store;

  /// The visual theme for rendering connections.
  final NodeFlowTheme theme;

  /// Shared connection painter instance for path caching and reuse.
  ///
  /// Using a shared instance ensures paths are cached and reused for both
  /// painting and hit testing, improving performance.
  final ConnectionPainter connectionPainter;

  /// Specific connections to render.
  /// If null, renders all connections from the store.
  final List<Connection<C>>? connections;

  /// Optional animation for animated connections.
  ///
  /// When provided, the animation value will be passed to animated connections
  /// for rendering effects.
  final Animation<double>? animation;

  /// Optional builder for dynamic connection style selection.
  ///
  /// When provided, this builder is called for each connection to determine
  /// which [ConnectionStyle] (path renderer) to use.
  final ConnectionStyleBuilder<T, C>? connectionStyleBuilder;

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

    // Use provided list or fallback to all connections
    final connectionsToRender = connections ?? store.connections;

    // Get current animation value
    final animationValue = animation?.value;

    // Check LOD state for endpoint visibility
    // If LOD extension is not configured, default to showing endpoints
    final skipEndpoints = !(store.lod?.showConnectionEndpoints ?? true);

    // Paint only connection lines and endpoints (no labels)
    // Labels are now rendered in a separate layer for better performance
    for (final connection in connectionsToRender) {
      // Skip hidden connections (e.g., during edge insertion preview)
      if (!connection.visible) continue;

      final sourceNode = store.getNode(connection.sourceNodeId);
      final targetNode = store.getNode(connection.targetNodeId);

      if (sourceNode == null || targetNode == null) continue;

      // Skip connections where either node is hidden
      if (!sourceNode.isVisible || !targetNode.isVisible) continue;

      final isSelected = store.selectedConnectionIds.contains(connection.id);

      // Call builder to get dynamic style override (if provided)
      final overrideStyle = connectionStyleBuilder?.call(
        connection,
        sourceNode,
        targetNode,
      );

      // Paint connection without labels using cached painter
      connectionPainter.paintConnection(
        canvas,
        connection,
        sourceNode,
        targetNode,
        isSelected: isSelected,
        animationValue: animationValue,
        skipEndpoints: skipEndpoints,
        overrideStyle: overrideStyle,
      );
    }
  }

  @override
  bool shouldRepaint(ConnectionsCanvas<T, C> oldDelegate) {
    // Always repaint when Observer rebuilds this painter
    // This is necessary because MobX observables may have changed
    return true;
  }

  @override
  bool shouldRebuildSemantics(ConnectionsCanvas<T, C> oldDelegate) => false;
}
