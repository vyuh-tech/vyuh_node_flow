import 'dart:ui';

import 'package:mobx/mobx.dart';

import '../editor/controller/node_flow_controller.dart';
import '../editor/lod/detail_visibility.dart';
import '../editor/lod/lod_extension.dart';
import '../nodes/comment_node.dart';
import '../nodes/group_node.dart';
import 'events/events.dart';
import 'node_flow_extension.dart';

/// Reactive graph statistics extension.
///
/// Provides computed statistics that automatically update when the graph
/// changes. All getters are backed by MobX Computed values for efficiency -
/// they only recalculate when their dependencies change.
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
class StatsExtension extends NodeFlowExtension<void> {
  /// Creates a stats extension.
  StatsExtension();

  NodeFlowController? _controller;

  @override
  Null get config => null;

  // Computed values (lazy initialized on attach)
  late final Computed<int> _nodeCount;
  late final Computed<int> _visibleNodeCount;
  late final Computed<int> _lockedNodeCount;
  late final Computed<int> _groupCount;
  late final Computed<int> _commentCount;
  late final Computed<Map<String, int>> _nodesByType;
  late final Computed<int> _connectionCount;
  late final Computed<int> _labeledConnectionCount;
  late final Computed<int> _selectedNodeCount;
  late final Computed<int> _selectedConnectionCount;
  late final Computed<int> _nodesInViewport;
  late final Computed<Rect> _bounds;

  // ═══════════════════════════════════════════════════════════════════════════
  // Node Statistics
  // ═══════════════════════════════════════════════════════════════════════════

  /// Total number of nodes in the graph.
  int get nodeCount => _nodeCount.value;

  /// Number of visible (non-hidden) nodes.
  int get visibleNodeCount => _visibleNodeCount.value;

  /// Number of locked nodes.
  int get lockedNodeCount => _lockedNodeCount.value;

  /// Number of GroupNode instances.
  int get groupCount => _groupCount.value;

  /// Number of CommentNode instances.
  int get commentCount => _commentCount.value;

  /// Number of regular nodes (excluding groups and comments).
  int get regularNodeCount => nodeCount - groupCount - commentCount;

  /// Breakdown of nodes by their type property.
  /// Example: `{'process': 5, 'decision': 3, 'start': 1}`
  Map<String, int> get nodesByType => _nodesByType.value;

  // ═══════════════════════════════════════════════════════════════════════════
  // Connection Statistics
  // ═══════════════════════════════════════════════════════════════════════════

  /// Total number of connections.
  int get connectionCount => _connectionCount.value;

  /// Number of connections that have labels.
  int get labeledConnectionCount => _labeledConnectionCount.value;

  /// Average number of connections per node.
  double get avgConnectionsPerNode =>
      nodeCount > 0 ? connectionCount / nodeCount : 0;

  // ═══════════════════════════════════════════════════════════════════════════
  // Selection Statistics
  // ═══════════════════════════════════════════════════════════════════════════

  /// Number of selected nodes.
  int get selectedNodeCount => _selectedNodeCount.value;

  /// Number of selected connections.
  int get selectedConnectionCount => _selectedConnectionCount.value;

  /// Total selected items (nodes + connections).
  int get selectedCount => selectedNodeCount + selectedConnectionCount;

  /// Whether any item is selected.
  bool get hasSelection => selectedCount > 0;

  /// Whether multiple items are selected.
  bool get isMultiSelection => selectedCount > 1;

  // ═══════════════════════════════════════════════════════════════════════════
  // Viewport Statistics
  // ═══════════════════════════════════════════════════════════════════════════

  /// Current zoom level (e.g., 1.0, 0.5, 2.0).
  double get zoom => _controller?.currentZoom ?? 1.0;

  /// Zoom as integer percentage (e.g., 100, 50, 200).
  int get zoomPercent => (zoom * 100).round();

  /// Current pan offset in graph coordinates.
  Offset get pan {
    final vp = _controller?.viewport;
    return vp != null ? Offset(vp.x, vp.y) : Offset.zero;
  }

  /// Current LOD level name: 'minimal', 'standard', or 'full'.
  String get lodLevel {
    if (_controller == null) return 'full';
    final visibility = _controller!.lod.currentVisibility;
    if (visibility == DetailVisibility.minimal) return 'minimal';
    if (visibility == DetailVisibility.standard) return 'standard';
    return 'full';
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // Bounds Statistics
  // ═══════════════════════════════════════════════════════════════════════════

  /// Bounding rectangle containing all nodes.
  Rect get bounds => _bounds.value;

  /// Width of the graph bounds.
  double get boundsWidth => bounds.width;

  /// Height of the graph bounds.
  double get boundsHeight => bounds.height;

  /// Center point of the graph.
  Offset get boundsCenter => bounds.center;

  /// Total area of the graph bounds.
  double get boundsArea => bounds.width * bounds.height;

  // ═══════════════════════════════════════════════════════════════════════════
  // Performance Statistics
  // ═══════════════════════════════════════════════════════════════════════════

  /// Number of nodes currently visible in the viewport.
  int get nodesInViewport => _nodesInViewport.value;

  /// Whether this is considered a "large" graph (> 100 nodes).
  bool get isLargeGraph => nodeCount > 100;

  /// Node density (nodes per 1,000,000 square units).
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
    _setupComputedValues();
  }

  @override
  void detach() {
    _controller = null;
  }

  @override
  void onEvent(GraphEvent event) {
    // Stats are computed reactively, no event handling needed
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // Private Implementation
  // ═══════════════════════════════════════════════════════════════════════════

  void _setupComputedValues() {
    final controller = _controller!;

    _nodeCount = Computed(() => controller.nodes.length);

    _visibleNodeCount = Computed(() {
      return controller.nodes.values.where((n) => n.isVisible).length;
    });

    _lockedNodeCount = Computed(() {
      return controller.nodes.values.where((n) => n.locked).length;
    });

    _groupCount = Computed(() {
      return controller.nodes.values.whereType<GroupNode>().length;
    });

    _commentCount = Computed(() {
      return controller.nodes.values.whereType<CommentNode>().length;
    });

    _nodesByType = Computed(() {
      final counts = <String, int>{};
      for (final node in controller.nodes.values) {
        final type = node.type;
        counts[type] = (counts[type] ?? 0) + 1;
      }
      return counts;
    });

    _connectionCount = Computed(() => controller.connections.length);

    _labeledConnectionCount = Computed(() {
      return controller.connections
          .where((c) => c.label != null && c.label!.text.isNotEmpty)
          .length;
    });

    _selectedNodeCount = Computed(() => controller.selectedNodeIds.length);

    _selectedConnectionCount = Computed(
      () => controller.selectedConnectionIds.length,
    );

    _nodesInViewport = Computed(() => controller.visibleNodes.length);

    _bounds = Computed(() => controller.nodesBounds);
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// Controller Extension
// ═══════════════════════════════════════════════════════════════════════════

/// Dart extension providing convenient access to stats functionality.
extension StatsControllerExtension<T> on NodeFlowController<T> {
  /// Gets the stats extension.
  ///
  /// The extension must be registered in [NodeFlowConfig.extensions].
  /// Throws [AssertionError] if not found.
  StatsExtension get stats {
    var ext = getExtension<StatsExtension>();
    if (ext == null) {
      ext = config.extensionRegistry.get<StatsExtension>();
      assert(
        ext != null,
        'StatsExtension not found. Add it to NodeFlowConfig.extensions.',
      );
      addExtension(ext!);
    }
    return ext;
  }
}
