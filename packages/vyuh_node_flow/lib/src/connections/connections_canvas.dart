import 'package:flutter/material.dart';

import '../editor/controller/node_flow_controller.dart';
import '../editor/themes/node_flow_theme.dart';
import '../plugins/lod/lod_plugin.dart';
import 'connection.dart';
import 'connection_painter.dart';
import 'styles/connection_style_base.dart';

/// Paints an immutable snapshot of permanent connection render data.
///
/// The snapshot is assembled by [ConnectionPainter.buildRenderSnapshot]
/// during the widget build phase. Consequently [paint] never reads the graph
/// controller, nodes, ports, or MobX observables. Animated frames reuse the
/// same geometry and resolved visual state.
class ConnectionsCanvas<T, C> extends CustomPainter {
  /// Creates a canvas from a prebuilt immutable render snapshot.
  ConnectionsCanvas.fromSnapshot({
    required this.snapshot,
    required this.connectionPainter,
    this.animation,
  }) : store = null,
       theme = null,
       connections = null,
       selectedIds = null,
       connectionStyleBuilder = null,
       super(repaint: animation);

  /// Compatibility constructor for tests and internal callers migrating to
  /// [ConnectionsCanvas.fromSnapshot]. Snapshot construction still occurs
  /// here, before [paint], so the paint path remains graph-independent.
  ConnectionsCanvas({
    required NodeFlowController<T, C> store,
    required this.theme,
    required this.connectionPainter,
    List<Connection<C>>? connections,
    Set<String>? selectedIds,
    this.animation,
    ConnectionStyleBuilder<T, C>? connectionStyleBuilder,
  }) : store = store,
       connections = connections,
       selectedIds = selectedIds,
       connectionStyleBuilder = connectionStyleBuilder,
       snapshot = connectionPainter.buildRenderSnapshot<T, C>(
         connections: connections ?? store.connections,
         nodeForId: store.getNode,
         selectedIds: selectedIds ?? store.selectedConnectionIds,
         skipEndpoints:
             (store.lod?.useThumbnailMode ?? false) ||
             !(store.lod?.showConnectionEndpoints ?? true),
         simplifyPaths: store.lod?.useThumbnailMode ?? false,
         connectionStyleBuilder: connectionStyleBuilder,
       ),
       super(repaint: animation);

  /// Immutable entries and resolved visual state painted by this delegate.
  final ConnectionRenderSnapshot snapshot;

  /// Painter used only to draw already-resolved snapshot entries.
  final ConnectionPainter connectionPainter;

  /// Optional animation clock for entries with an animation effect.
  final Animation<double>? animation;

  // Compatibility accessors. The permanent rendering path uses
  // [fromSnapshot], where these values are null by design.
  final NodeFlowController<T, C>? store;
  final NodeFlowTheme? theme;
  final List<Connection<C>>? connections;
  final Set<String>? selectedIds;
  final ConnectionStyleBuilder<T, C>? connectionStyleBuilder;

  @override
  void paint(Canvas canvas, Size size) {
    final animationValue = animation?.value;
    for (final batch in snapshot.batches) {
      connectionPainter.paintRenderBatch(canvas, batch);
    }
    for (final entry in snapshot.entries) {
      connectionPainter.paintRenderEntry(
        canvas,
        entry,
        animationValue: animationValue,
      );
    }
  }

  @override
  bool shouldRepaint(ConnectionsCanvas<T, C> oldDelegate) =>
      snapshot.revision != oldDelegate.snapshot.revision;

  @override
  bool shouldRebuildSemantics(ConnectionsCanvas<T, C> oldDelegate) => false;
}
