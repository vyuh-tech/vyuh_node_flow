import 'package:flutter/material.dart';
import 'package:mobx/mobx.dart';

import '../../connections/connection.dart';
import '../../nodes/node.dart';
import '../../nodes/node_shape.dart';
import '../../ports/port.dart';
import 'spatial_grid.dart';
import 'spatial_item.dart';
import 'spatial_queries.dart';

export 'spatial_queries.dart' show HitTestResult, HitTarget;

/// Simplified, type-safe spatial index for graph elements.
///
/// This is the primary API for spatial operations in the node flow system.
/// It provides:
/// - Type-safe operations (accepts domain objects directly)
/// - Automatic batching (no manual flush needed)
/// - Simple core operations: add, update, remove, query
///
/// ## Core Operations
///
/// ```dart
/// // Adding/updating elements
/// index.update(node);  // Works for all node types including GroupNode, CommentNode
/// index.updateConnection(connection, segmentBounds);
///
/// // Removing elements
/// index.remove(node);
/// index.removeConnection(connectionId);
///
/// // Querying
/// final result = index.hitTest(point);
/// final nodes = index.nodesAt(point);
/// final nodes = index.nodesIn(bounds);
/// ```
///
/// ## Batch Operations
///
/// For multiple operations, use [batch] to defer index updates:
/// ```dart
/// index.batch(() {
///   for (final node in nodes) {
///     index.update(node);
///   }
/// });
/// ```
class GraphSpatialIndex<T> implements SpatialQueries<T> {
  GraphSpatialIndex({double gridSize = 500.0, this.portSnapDistance = 8.0})
    : _grid = SpatialGrid<SpatialItem>(gridSize: gridSize);

  final SpatialGrid<SpatialItem> _grid;

  /// Distance within which a port is considered "hit"
  final double portSnapDistance;

  // Domain object storage for type-safe retrieval
  final Map<String, Node<T>> _nodes = {};
  final Map<String, Connection> _connections = {};

  // Track connection segment IDs for cleanup
  final Map<String, List<String>> _connectionSegmentIds = {};

  // Track port spatial item IDs per node for cleanup
  // Key: nodeId, Value: list of port spatial item IDs
  final Map<String, List<String>> _nodePortIds = {};

  // Batch mode tracking
  bool _inBatch = false;

  /// Observable version counter that increments on every spatial index change.
  ///
  /// Use this in MobX Observer widgets to reactively update when the
  /// spatial index changes. The value itself is meaningless - only changes
  /// to it trigger reactivity.
  @override
  final Observable<int> version = Observable(0);

  /// Notifies observers that the spatial index has changed.
  /// Only notifies if not currently in a batch operation.
  void _notifyChanged() {
    if (!_inBatch) {
      runInAction(() => version.value++);
    }
  }

  /// Forces a notification to observers that the spatial index has changed.
  ///
  /// This bypasses the batch check and always notifies.
  void notifyChanged() {
    runInAction(() => version.value++);
  }

  // Configurable callbacks
  NodeShape? Function(Node<T> node)? nodeShapeBuilder;
  bool Function(Connection connection, Offset point)? connectionHitTester;
  Size Function(Port port)? portSizeResolver;

  /// Provider for the canonical render order of nodes.
  ///
  /// When two nodes have the same zIndex, the render order determines which
  /// one is visually on top (later in the list = on top). This is typically
  /// provided by the controller's sortedNodes getter.
  List<Node<T>> Function()? _renderOrderProvider;

  /// Sets the render order provider for accurate hit testing.
  ///
  /// This should be called by the controller to provide access to the
  /// canonical render order (sortedNodes).
  set renderOrderProvider(List<Node<T>> Function()? provider) {
    _renderOrderProvider = provider;
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // CORE OPERATIONS
  // ═══════════════════════════════════════════════════════════════════════════

  /// Updates a node in the spatial index.
  ///
  /// Call this after any change to node position or size.
  /// Also updates all port positions for this node.
  void update(Node<T> node) {
    _nodes[node.id] = node;
    final item = NodeSpatialItem(nodeId: node.id, bounds: node.getBounds());
    _grid.addOrUpdate(item);

    // Update port positions for this node
    _updatePortsForNode(node);

    _autoFlush();
    _notifyChanged();
  }

  /// Updates all port spatial items for a node.
  void _updatePortsForNode(Node<T> node) {
    // Remove existing port items for this node
    _removePortsForNode(node.id, notify: false);

    final shape = nodeShapeBuilder?.call(node);
    final portIds = <String>[];

    // Helper to add a port to the spatial index
    void addPort(Port port, bool isOutput) {
      final effectivePortSize =
          portSizeResolver?.call(port) ?? const Size.square(10.0);

      // Use Node's centralized getPortCenter method for the visual center
      final portCenter = node.getPortCenter(
        port.id,
        portSize: effectivePortSize,
        shape: shape,
      );

      // Create bounds around the port center including both port size and snap distance.
      // This matches the visual hover area in PortWidget which extends snapDistance
      // from each edge of the port, not from its center.
      final portBounds = Rect.fromCenter(
        center: portCenter,
        width: effectivePortSize.width + portSnapDistance * 2,
        height: effectivePortSize.height + portSnapDistance * 2,
      );

      final spatialItem = PortSpatialItem(
        portId: port.id,
        nodeId: node.id,
        isOutput: isOutput,
        bounds: portBounds,
      );

      _grid.addOrUpdate(spatialItem);
      portIds.add(spatialItem.id);
    }

    // Add all input ports
    for (final port in node.inputPorts) {
      addPort(port, false);
    }

    // Add all output ports
    for (final port in node.outputPorts) {
      addPort(port, true);
    }

    _nodePortIds[node.id] = portIds;
  }

  /// Removes all port spatial items for a node.
  void _removePortsForNode(String nodeId, {required bool notify}) {
    final portIds = _nodePortIds.remove(nodeId);
    if (portIds != null) {
      for (final portId in portIds) {
        _grid.remove(portId);
      }
      if (notify) _notifyChanged();
    }
  }

  /// Updates a connection in the spatial index with segment bounds.
  ///
  /// Connections use multiple segments for accurate curved path hit testing.
  void updateConnection(Connection connection, List<Rect> segmentBounds) {
    _connections[connection.id] = connection;
    _removeConnectionSegments(connectionId: connection.id, notify: false);

    if (segmentBounds.isEmpty) {
      _notifyChanged();
      return;
    }

    final segmentIds = <String>[];
    for (int i = 0; i < segmentBounds.length; i++) {
      final item = ConnectionSegmentItem(
        connectionId: connection.id,
        segmentIndex: i,
        bounds: segmentBounds[i],
      );
      _grid.addOrUpdate(item);
      segmentIds.add(item.id);
    }
    _connectionSegmentIds[connection.id] = segmentIds;
    _autoFlush();
    _notifyChanged();
  }

  /// Removes a node from the spatial index.
  void remove(Node<T> node) => removeNode(node.id);

  /// Removes a node by ID.
  /// Also removes all port spatial items for this node.
  void removeNode(String nodeId) {
    final node = _nodes.remove(nodeId);
    if (node != null) {
      _grid.remove(NodeSpatialItem(nodeId: nodeId, bounds: Rect.zero).id);
      _removePortsForNode(nodeId, notify: false);
      _notifyChanged();
    }
  }

  /// Removes a connection from the spatial index.
  void removeConnection(String connectionId) {
    _connections.remove(connectionId);
    _removeConnectionSegments(connectionId: connectionId, notify: true);
  }

  void _removeConnectionSegments({
    required String connectionId,
    required bool notify,
  }) {
    final segmentIds = _connectionSegmentIds.remove(connectionId);
    if (segmentIds != null) {
      for (final segmentId in segmentIds) {
        _grid.remove(segmentId);
      }
      if (notify) _notifyChanged();
    }
  }

  /// Clears all items from the spatial index.
  void clear() {
    _nodes.clear();
    _connections.clear();
    _connectionSegmentIds.clear();
    _nodePortIds.clear();
    _grid.clear();
    _notifyChanged();
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // BATCH OPERATIONS
  // ═══════════════════════════════════════════════════════════════════════════

  /// Executes multiple operations in a batch.
  ///
  /// Index updates are deferred until the batch completes, improving
  /// performance for bulk operations.
  ///
  /// ```dart
  /// index.batch(() {
  ///   for (final node in movedNodes) {
  ///     index.update(node);
  ///   }
  /// });
  /// ```
  void batch(void Function() operations) {
    _inBatch = true;
    try {
      operations();
    } finally {
      _inBatch = false;
      _grid.flushPendingUpdates();
      _notifyChanged();
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // QUERIES
  // ═══════════════════════════════════════════════════════════════════════════

  /// Performs hit testing at a point.
  ///
  /// Tests in priority order matching visual z-order (top to bottom):
  /// foreground nodes (CommentNode) → ports → middle nodes → connections → background nodes (GroupNode) → canvas
  ///
  /// This order ensures that elements visually on top receive hit priority.
  /// Foreground nodes (comments) are above everything except the interaction layer.
  /// Background nodes (groups) are behind regular nodes and connections.
  @override
  HitTestResult hitTest(Offset point) {
    // 1. Foreground nodes (CommentNode - highest priority, visually on top)
    final foregroundResult = _hitTestNodesByLayer(
      point,
      layer: NodeRenderLayer.foreground,
    );
    if (foregroundResult != null) return foregroundResult;

    // 2. Ports
    final portResult = _hitTestPorts(point);
    if (portResult != null) return portResult;

    // 3. Middle layer nodes (regular nodes)
    final nodeResult = _hitTestNodesByLayer(
      point,
      layer: NodeRenderLayer.middle,
    );
    if (nodeResult != null) return nodeResult;

    // 4. Connections
    final connectionResult = _hitTestConnections(point);
    if (connectionResult != null) return connectionResult;

    // 5. Background nodes (GroupNode - behind regular nodes/connections)
    final backgroundResult = _hitTestNodesByLayer(
      point,
      layer: NodeRenderLayer.background,
    );
    if (backgroundResult != null) return backgroundResult;

    // 6. Canvas (background)
    return const HitTestResult(hitType: HitTarget.canvas);
  }

  /// Gets all visible nodes at a point.
  @override
  List<Node<T>> nodesAt(Offset point, {double radius = 0}) {
    return _grid
        .queryPoint(point, radius: radius)
        .whereType<NodeSpatialItem>()
        .map((item) => _nodes[item.nodeId])
        .whereType<Node<T>>()
        .where((node) => node.isVisible)
        .toList();
  }

  /// Gets all visible nodes within bounds.
  @override
  List<Node<T>> nodesIn(Rect bounds) {
    return _grid
        .query(bounds)
        .whereType<NodeSpatialItem>()
        .map((item) => _nodes[item.nodeId])
        .whereType<Node<T>>()
        .where((node) => node.isVisible)
        .toList();
  }

  /// Gets all visible connections at a point.
  /// Only returns connections where both source and target nodes are visible.
  @override
  List<Connection> connectionsAt(Offset point, {double radius = 0}) {
    final connectionIds = _grid
        .queryPoint(point, radius: radius)
        .whereType<ConnectionSegmentItem>()
        .map((item) => item.connectionId)
        .toSet();
    return connectionIds
        .map((id) => _connections[id])
        .whereType<Connection>()
        .where((connection) {
          final sourceNode = _nodes[connection.sourceNodeId];
          final targetNode = _nodes[connection.targetNodeId];
          return sourceNode != null &&
              targetNode != null &&
              sourceNode.isVisible &&
              targetNode.isVisible;
        })
        .toList();
  }

  /// Hit test for a port at the given position.
  ///
  /// Returns the hit test result containing nodeId, portId, and isOutput
  /// if a port is found at the position, otherwise returns null.
  ///
  /// This is useful for finding target ports during connection drag operations.
  @override
  HitTestResult? hitTestPort(Offset point) => _hitTestPorts(point);

  /// Gets a node by ID.
  @override
  Node<T>? getNode(String id) => _nodes[id];

  /// Gets a connection by ID.
  @override
  Connection? getConnection(String id) => _connections[id];

  // ═══════════════════════════════════════════════════════════════════════════
  // BULK REBUILD
  // ═══════════════════════════════════════════════════════════════════════════

  /// Rebuilds the entire index from the given elements.
  ///
  /// Use this after loading a graph or performing major structural changes.
  /// Nodes include all node types: regular nodes, GroupNode, CommentNode.
  void rebuild({
    required Iterable<Node<T>> nodes,
    required Iterable<Connection> connections,
    required List<Rect> Function(Connection) connectionSegmentCalculator,
  }) {
    clear();
    batch(() {
      for (final node in nodes) {
        update(node);
      }
      for (final connection in connections) {
        final segments = connectionSegmentCalculator(connection);
        updateConnection(connection, segments);
      }
    });
  }

  /// Rebuilds only nodes from the given iterable.
  /// Also rebuilds all port spatial items.
  void rebuildFromNodes(Iterable<Node<T>> nodes) {
    // Clear existing nodes and their ports
    for (final nodeId in _nodes.keys.toList()) {
      _grid.remove(NodeSpatialItem(nodeId: nodeId, bounds: Rect.zero).id);
      _removePortsForNode(nodeId, notify: false);
    }
    _nodes.clear();

    // Add new nodes (update() also adds their ports)
    batch(() {
      for (final node in nodes) {
        update(node);
      }
    });
  }

  /// Rebuilds connections using segment bounds calculator.
  void rebuildConnectionsWithSegments(
    Iterable<Connection> connections,
    List<Rect> Function(Connection) segmentBoundsCalculator,
  ) {
    // Clear existing connections
    for (final connectionId in _connections.keys.toList()) {
      _removeConnectionSegments(connectionId: connectionId, notify: false);
    }
    _connections.clear();

    // Add new connections
    batch(() {
      for (final connection in connections) {
        final segments = segmentBoundsCalculator(connection);
        updateConnection(connection, segments);
      }
    });
  }

  /// Rebuilds connections using single bounds calculator.
  /// Convenience wrapper that converts single-bound results to segment lists.
  void rebuildConnections(
    Iterable<Connection> connections,
    Rect Function(Connection) boundsCalculator,
  ) {
    rebuildConnectionsWithSegments(
      connections,
      (connection) => [boundsCalculator(connection)],
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // STATISTICS
  // ═══════════════════════════════════════════════════════════════════════════

  @override
  int get nodeCount => _nodes.length;
  @override
  int get connectionCount => _connections.length;
  @override
  int get portCount =>
      _nodePortIds.values.fold(0, (sum, list) => sum + list.length);
  SpatialIndexStats get stats => _grid.stats;

  /// Gets all port spatial items for debug visualization.
  ///
  /// Returns port bounds (inflated snap zones) that can be drawn
  /// to visualize the snap hit areas.
  Iterable<PortSpatialItem> get portItems =>
      _grid.objects.whereType<PortSpatialItem>();

  /// Gets all node spatial items for debug visualization.
  Iterable<NodeSpatialItem> get nodeItems =>
      _grid.objects.whereType<NodeSpatialItem>();

  /// Gets all connection segment items for debug visualization.
  Iterable<ConnectionSegmentItem> get connectionSegmentItems =>
      _grid.objects.whereType<ConnectionSegmentItem>();

  /// The grid size used for spatial hashing (default: 500.0 pixels).
  double get gridSize => _grid.gridSize;

  /// Gets information about all active spatial grid cells for debug visualization.
  ///
  /// Returns a list of [CellDebugInfo] containing:
  /// - `bounds`: The world-coordinate bounding rectangle of the cell
  /// - `cellX`, `cellY`: The grid cell coordinates (not pixels)
  /// - Type breakdown: `nodeCount`, `portCount`, `connectionCount`
  ///
  /// This is useful for visualizing how the spatial index partitions space.
  List<CellDebugInfo> getActiveCellsInfo() => _grid.getActiveCellsInfo();

  /// Converts grid cell coordinates to world bounds.
  ///
  /// Given grid cell coordinates (x, y), returns the bounding rectangle
  /// in world/pixel coordinates.
  Rect cellBounds(int cellX, int cellY) => _grid.cellBounds(cellX, cellY);

  // ═══════════════════════════════════════════════════════════════════════════
  // PRIVATE IMPLEMENTATION
  // ═══════════════════════════════════════════════════════════════════════════

  void _autoFlush() {
    if (!_inBatch) {
      _grid.flushPendingUpdates();
    }
  }

  HitTestResult? _hitTestPorts(Offset point) {
    // Query port spatial items directly - O(1) spatial lookup
    final nearbyPorts = _grid.queryPoint(point).whereType<PortSpatialItem>();

    // Collect port candidates with distance (all data is on the spatial item)
    final candidates = <({PortSpatialItem item, double distance})>[];

    for (final portItem in nearbyPorts) {
      // Skip ports of hidden nodes
      final node = _nodes[portItem.nodeId];
      if (node == null || !node.isVisible) continue;

      // Calculate distance from point to port center (used for sorting only)
      final portCenter = portItem.bounds.center;
      final distance = (point - portCenter).distance;

      // No distance check needed - spatial query already filtered by snap bounds
      candidates.add((item: portItem, distance: distance));
    }

    if (candidates.isEmpty) return null;

    // Sort by render layer (highest first), then zIndex (highest first), then distance (closest first)
    candidates.sort((a, b) {
      final nodeA = _nodes[a.item.nodeId];
      final nodeB = _nodes[b.item.nodeId];
      if (nodeA == null || nodeB == null) return 0;

      // 1. Compare render layers (foreground > middle > background)
      final layerCompare = nodeB.layer.index.compareTo(nodeA.layer.index);
      if (layerCompare != 0) return layerCompare;

      // 2. Same layer - compare zIndex
      final zIndexCompare = nodeB.zIndex.value.compareTo(nodeA.zIndex.value);
      if (zIndexCompare != 0) return zIndexCompare;

      // 3. Same layer and zIndex - prefer closer port
      return a.distance.compareTo(b.distance);
    });

    // Find the first port that isn't covered by another node
    for (final candidate in candidates) {
      final node = _nodes[candidate.item.nodeId];
      if (node == null) continue;

      final portCenter = candidate.item.bounds.center;
      final isCoveredByOtherNode = _isPointCoveredByOtherNode(portCenter, node);

      if (!isCoveredByOtherNode) {
        return HitTestResult(
          nodeId: candidate.item.nodeId,
          portId: candidate.item.portId,
          isOutput: candidate.item.isOutput,
          hitType: HitTarget.port,
        );
      }
    }

    return null;
  }

  /// Checks if a point is covered by any node that renders above [excludeNode].
  ///
  /// A node renders above another if (in priority order):
  /// 1. It is at a higher render layer (foreground > middle > background)
  /// 2. Same layer but higher zIndex
  /// 3. Same layer and zIndex but appears later in the render order
  ///
  /// This ensures that:
  /// - Background nodes (GroupNode) never cover middle layer nodes
  /// - Only nodes that are visually on top can block port hit testing
  ///
  /// Used to ensure that ports visually obscured by overlapping nodes are not hit.
  bool _isPointCoveredByOtherNode(Offset point, Node<T> excludeNode) {
    final nodesAtPoint = _grid
        .queryPoint(point)
        .whereType<NodeSpatialItem>()
        .map((item) => _nodes[item.nodeId])
        .whereType<Node<T>>()
        .where((node) => node.id != excludeNode.id && node.isVisible)
        .toList();

    for (final node in nodesAtPoint) {
      // Check if this node renders above the excludeNode
      final rendersAbove = _nodeRendersAbove(node, excludeNode);
      if (!rendersAbove) continue;

      final shape = nodeShapeBuilder?.call(node);

      if (shape != null) {
        final relativePosition = point - node.position.value;
        if (shape.containsPoint(relativePosition, node.size.value)) {
          return true;
        }
      } else {
        if (node.containsPoint(point)) {
          return true;
        }
      }
    }
    return false;
  }

  /// Determines if [nodeA] renders above [nodeB] in the visual stack.
  ///
  /// The render priority is determined in this order:
  /// 1. **Render layer**: background < middle < foreground
  ///    A node at a higher layer ALWAYS renders above nodes at lower layers,
  ///    regardless of zIndex.
  /// 2. **zIndex**: Within the same layer, higher zIndex renders on top.
  /// 3. **Render order**: For same layer and same zIndex, the node appearing
  ///    later in the render order (based on _renderOrderProvider) is on top.
  ///
  /// This ensures that:
  /// - GroupNodes (background) never cover regular nodes (middle)
  /// - Regular nodes (middle) never cover CommentNodes (foreground)
  /// - Within a layer, zIndex and render order determine stacking
  bool _nodeRendersAbove(Node<T> nodeA, Node<T> nodeB) {
    // 1. Compare render layers first
    // NodeRenderLayer enum order: background(0) < middle(1) < foreground(2)
    final layerA = nodeA.layer.index;
    final layerB = nodeB.layer.index;

    if (layerA > layerB) {
      return true; // nodeA is at a higher layer, always renders above
    } else if (layerA < layerB) {
      return false; // nodeA is at a lower layer, always renders below
    }

    // 2. Same layer - compare zIndex
    final zIndexA = nodeA.zIndex.value;
    final zIndexB = nodeB.zIndex.value;

    if (zIndexA > zIndexB) {
      return true;
    } else if (zIndexA < zIndexB) {
      return false;
    }

    // 3. Same layer and same zIndex - check render order if provider is available
    if (_renderOrderProvider != null) {
      final renderOrder = _renderOrderProvider!();
      final indexA = renderOrder.indexWhere((n) => n.id == nodeA.id);
      final indexB = renderOrder.indexWhere((n) => n.id == nodeB.id);

      // Higher index in render order = renders later = visually on top
      if (indexA >= 0 && indexB >= 0) {
        return indexA > indexB;
      }
    }

    // Fallback: if we can't determine order, assume they don't overlap in priority
    return false;
  }

  /// Hit tests nodes filtered by their render layer.
  ///
  /// This unified method replaces separate node and annotation hit testing.
  /// Nodes include all types: regular nodes, GroupNode (background), CommentNode (foreground).
  HitTestResult? _hitTestNodesByLayer(
    Offset point, {
    required NodeRenderLayer layer,
  }) {
    final candidates = _grid
        .queryPoint(point)
        .whereType<NodeSpatialItem>()
        .map((item) => _nodes[item.nodeId])
        .whereType<Node<T>>()
        .where((node) => node.isVisible && node.layer == layer)
        .toList();
    candidates.sort((a, b) => b.zIndex.value.compareTo(a.zIndex.value));

    for (final node in candidates) {
      final shape = nodeShapeBuilder?.call(node);

      if (shape != null) {
        final relativePosition = point - node.position.value;
        if (shape.containsPoint(relativePosition, node.size.value)) {
          return HitTestResult(nodeId: node.id, hitType: HitTarget.node);
        }
      } else {
        if (node.containsPoint(point)) {
          return HitTestResult(nodeId: node.id, hitType: HitTarget.node);
        }
      }
    }
    return null;
  }

  HitTestResult? _hitTestConnections(Offset point) {
    final connectionIds = _grid
        .queryPoint(point)
        .whereType<ConnectionSegmentItem>()
        .map((item) => item.connectionId)
        .toSet();

    for (final connectionId in connectionIds) {
      final connection = _connections[connectionId];
      if (connection == null) continue;

      // Skip connections where either node is hidden
      final sourceNode = _nodes[connection.sourceNodeId];
      final targetNode = _nodes[connection.targetNodeId];
      if (sourceNode == null ||
          targetNode == null ||
          !sourceNode.isVisible ||
          !targetNode.isVisible) {
        continue;
      }

      if (connectionHitTester?.call(connection, point) ?? false) {
        return HitTestResult(
          connectionId: connection.id,
          hitType: HitTarget.connection,
        );
      }
    }
    return null;
  }
}
