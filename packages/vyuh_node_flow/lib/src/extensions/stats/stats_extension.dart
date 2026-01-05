import 'dart:ui';

import 'package:mobx/mobx.dart';

import '../../connections/connection.dart';
import '../../editor/controller/node_flow_controller.dart';
import '../../graph/viewport.dart';
import '../../nodes/node.dart';
import '../lod/detail_visibility.dart';
import '../lod/lod_extension.dart';
import '../../nodes/comment_node.dart';
import '../../nodes/group_node.dart';
import '../events/events.dart';
import '../node_flow_extension.dart';

/// Reactive graph statistics extension.
///
/// Provides a facade over the controller's observable properties, making it
/// convenient to access graph statistics in one place. All properties are
/// reactive through the controller's underlying MobX observables.
///
/// This extension uses `void` as its config type since it doesn't require
/// any configuration.
///
/// ## Usage with Granular Observers
/// ```dart
/// // Each stat can have its own Observer for fine-grained updates
/// Row(
///   children: [
///     Observer(builder: (_) => Text('${controller.stats.nodeCount} nodes')),
///     Observer(builder: (_) => Text('${controller.stats.zoomPercent}%')),
///   ],
/// )
/// ```
///
/// ## Summary Helpers
/// ```dart
/// Observer(builder: (_) => Text(controller.stats.summary));
/// // Output: "25 nodes, 40 connections"
/// ```
class StatsExtension extends NodeFlowExtension {
  /// Creates a stats extension.
  StatsExtension();

  NodeFlowController? _controller;

  // ═══════════════════════════════════════════════════════════════════════════
  // Observable Collections (direct access for reactive UI)
  // ═══════════════════════════════════════════════════════════════════════════

  /// The nodes observable map for direct reactive access.
  ///
  /// Use in Observer widgets to react to node changes (add/remove/modify).
  ObservableMap<String, Node> get nodes => _controller!.nodesObservable;

  /// The connections observable list for direct reactive access.
  ///
  /// Use in Observer widgets to react to connection changes.
  ObservableList<Connection> get connections =>
      _controller!.connectionsObservable;

  /// The selected node IDs observable set for direct reactive access.
  ObservableSet<String> get selectedNodeIds =>
      _controller!.selectedNodeIdsObservable;

  /// The selected connection IDs observable set for direct reactive access.
  ObservableSet<String> get selectedConnectionIds =>
      _controller!.selectedConnectionIdsObservable;

  // ═══════════════════════════════════════════════════════════════════════════
  // Node Statistics (derived from controller's observable collections)
  // ═══════════════════════════════════════════════════════════════════════════

  /// Total number of nodes in the graph. Reactive.
  int get nodeCount => nodes.length;

  /// Number of visible (non-hidden) nodes. Reactive.
  int get visibleNodeCount => nodes.values.where((n) => n.isVisible).length;

  /// Number of locked nodes. Reactive.
  int get lockedNodeCount => nodes.values.where((n) => n.locked).length;

  /// Number of GroupNode instances. Reactive.
  int get groupCount => nodes.values.whereType<GroupNode>().length;

  /// Number of CommentNode instances. Reactive.
  int get commentCount => nodes.values.whereType<CommentNode>().length;

  /// Number of regular nodes (excluding groups and comments). Reactive.
  int get regularNodeCount => nodeCount - groupCount - commentCount;

  /// Breakdown of nodes by their type property. Reactive.
  /// Example: `{'process': 5, 'decision': 3, 'start': 1}`
  Map<String, int> get nodesByType {
    final counts = <String, int>{};
    for (final node in nodes.values) {
      final type = node.type;
      counts[type] = (counts[type] ?? 0) + 1;
    }
    return counts;
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // Connection Statistics (derived from controller's observable collections)
  // ═══════════════════════════════════════════════════════════════════════════

  /// Total number of connections. Reactive.
  int get connectionCount => connections.length;

  /// Number of connections that have labels. Reactive.
  int get labeledConnectionCount => connections
      .where((c) => c.label != null && c.label!.text.isNotEmpty)
      .length;

  /// Average number of connections per node. Reactive.
  double get avgConnectionsPerNode =>
      nodeCount > 0 ? connectionCount / nodeCount : 0;

  // ═══════════════════════════════════════════════════════════════════════════
  // Selection Statistics (derived from controller's observable collections)
  // ═══════════════════════════════════════════════════════════════════════════

  /// Number of selected nodes. Reactive.
  int get selectedNodeCount => selectedNodeIds.length;

  /// Number of selected connections. Reactive.
  int get selectedConnectionCount => selectedConnectionIds.length;

  /// Total selected items (nodes + connections). Reactive.
  int get selectedCount => selectedNodeCount + selectedConnectionCount;

  /// Whether any item is selected. Reactive.
  bool get hasSelection => selectedCount > 0;

  /// Whether multiple items are selected. Reactive.
  bool get isMultiSelection => selectedCount > 1;

  // ═══════════════════════════════════════════════════════════════════════════
  // Viewport Statistics (derived from controller's observable viewport)
  // ═══════════════════════════════════════════════════════════════════════════

  /// The viewport observable for direct reactive access.
  ///
  /// Use this in Observer widgets to react to viewport changes:
  /// ```dart
  /// Observer(builder: (_) {
  ///   final vp = controller.stats!.viewport.value;
  ///   return Text('${(vp.zoom * 100).round()}%');
  /// });
  /// ```
  Observable<GraphViewport> get viewport => _controller!.viewportObservable;

  /// Current zoom level (e.g., 1.0, 0.5, 2.0). Reactive via viewport observable.
  double get zoom => viewport.value.zoom;

  /// Zoom as integer percentage (e.g., 100, 50, 200). Reactive via viewport observable.
  int get zoomPercent => (viewport.value.zoom * 100).round();

  /// Current pan offset in graph coordinates. Reactive via viewport observable.
  Offset get pan {
    final vp = viewport.value;
    return Offset(vp.x, vp.y);
  }

  /// Current LOD level name: 'minimal', 'standard', or 'full'.
  String get lodLevel {
    if (_controller == null) return 'full';
    final lod = _controller!.lod;
    if (lod == null) return 'full';
    final visibility = lod.currentVisibility;
    if (visibility == DetailVisibility.minimal) return 'minimal';
    if (visibility == DetailVisibility.standard) return 'standard';
    return 'full';
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // Bounds Statistics (directly access controller's observable properties)
  // ═══════════════════════════════════════════════════════════════════════════

  /// Bounding rectangle containing all nodes. Reactive.
  Rect get bounds => _controller!.nodesBounds;

  /// Width of the graph bounds. Reactive.
  double get boundsWidth => bounds.width;

  /// Height of the graph bounds. Reactive.
  double get boundsHeight => bounds.height;

  /// Center point of the graph. Reactive.
  Offset get boundsCenter => bounds.center;

  /// Total area of the graph bounds. Reactive.
  double get boundsArea => bounds.width * bounds.height;

  // ═══════════════════════════════════════════════════════════════════════════
  // Performance Statistics (directly access controller's observable properties)
  // ═══════════════════════════════════════════════════════════════════════════

  /// Number of nodes currently visible in the viewport. Reactive.
  int get nodesInViewport => _controller!.visibleNodes.length;

  /// Whether this is considered a "large" graph (> 100 nodes). Reactive.
  bool get isLargeGraph => nodeCount > 100;

  /// Node density (nodes per 1,000,000 square units). Reactive.
  double get density => boundsArea > 0 ? (nodeCount / boundsArea) * 1000000 : 0;

  // ═══════════════════════════════════════════════════════════════════════════
  // Summary Helpers
  // ═══════════════════════════════════════════════════════════════════════════

  /// Quick graph summary: "25 nodes, 40 connections"
  String get summary => '$nodeCount nodes, $connectionCount connections';

  /// Selection summary: "3 nodes, 2 connections selected" or "Nothing selected"
  String get selectionSummary {
    if (!hasSelection) return 'Nothing selected';
    final parts = <String>[];
    if (selectedNodeCount > 0) {
      parts.add('$selectedNodeCount node${selectedNodeCount == 1 ? '' : 's'}');
    }
    if (selectedConnectionCount > 0) {
      parts.add(
        '$selectedConnectionCount connection${selectedConnectionCount == 1 ? '' : 's'}',
      );
    }
    return '${parts.join(', ')} selected';
  }

  /// Viewport summary: "100% at (0, 0)"
  String get viewportSummary =>
      '$zoomPercent% at (${pan.dx.toInt()}, ${pan.dy.toInt()})';

  /// Bounds summary: "2400 × 1800 px"
  String get boundsSummary =>
      '${boundsWidth.toInt()} × ${boundsHeight.toInt()} px';

  // ═══════════════════════════════════════════════════════════════════════════
  // NodeFlowExtension Implementation
  // ═══════════════════════════════════════════════════════════════════════════

  @override
  String get id => 'stats';

  @override
  void attach(NodeFlowController controller) {
    _controller = controller;
  }

  @override
  void detach() {
    _controller = null;
  }

  @override
  void onEvent(GraphEvent event) {
    // Stats are reactive via direct observable access, no event handling needed
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// Controller Extension
// ═══════════════════════════════════════════════════════════════════════════

/// Dart extension providing access to the stats extension.
extension StatsExtensionAccess<T> on NodeFlowController<T, dynamic> {
  /// Gets the stats extension, or null if not configured.
  ///
  /// Returns null if the extension is not registered, which effectively
  /// disables stats functionality. Use null-aware operators to safely
  /// access stats features.
  StatsExtension? get stats => resolveExtension<StatsExtension>();
}
