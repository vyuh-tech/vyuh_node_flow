import 'package:flutter/material.dart';

import '../../annotations/annotation.dart';
import '../../connections/connection.dart';
import '../../graph/hit_test_result.dart';
import '../../nodes/node.dart';
import '../../nodes/node_shape.dart';
import '../../ports/port.dart';
import 'spatial_grid.dart';
import 'spatial_item.dart';

export '../../graph/hit_test_result.dart';

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
/// index.update(node);
/// index.updateAnnotation(annotation);
/// index.updateConnection(connection, segmentBounds);
///
/// // Removing elements
/// index.remove(node);
/// index.removeAnnotation(annotationId);
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
class GraphSpatialIndex<T> {
  GraphSpatialIndex({double gridSize = 500.0, this.portSnapDistance = 15.0})
    : _grid = SpatialGrid<SpatialItem>(gridSize: gridSize);

  final SpatialGrid<SpatialItem> _grid;

  /// Distance within which a port is considered "hit"
  final double portSnapDistance;

  // Domain object storage for type-safe retrieval
  final Map<String, Node<T>> _nodes = {};
  final Map<String, Connection> _connections = {};
  final Map<String, Annotation> _annotations = {};

  // Track connection segment IDs for cleanup
  final Map<String, List<String>> _connectionSegmentIds = {};

  // Batch mode tracking
  bool _inBatch = false;

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
  void update(Node<T> node) {
    _nodes[node.id] = node;
    final item = NodeSpatialItem(nodeId: node.id, bounds: node.getBounds());
    _grid.addOrUpdate(item);
    _autoFlush();
  }

  /// Updates an annotation in the spatial index.
  void updateAnnotation(Annotation annotation) {
    _annotations[annotation.id] = annotation;
    final item = AnnotationSpatialItem(
      annotationId: annotation.id,
      bounds: annotation.bounds,
    );
    _grid.addOrUpdate(item);
    _autoFlush();
  }

  /// Updates a connection in the spatial index with segment bounds.
  ///
  /// Connections use multiple segments for accurate curved path hit testing.
  void updateConnection(Connection connection, List<Rect> segmentBounds) {
    _connections[connection.id] = connection;
    _removeConnectionSegments(connection.id);

    if (segmentBounds.isEmpty) return;

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
  }

  /// Removes a node from the spatial index.
  void remove(Node<T> node) => removeNode(node.id);

  /// Removes a node by ID.
  void removeNode(String nodeId) {
    final node = _nodes.remove(nodeId);
    if (node != null) {
      _grid.remove(NodeSpatialItem(nodeId: nodeId, bounds: Rect.zero).id);
    }
  }

  /// Removes an annotation from the spatial index.
  void removeAnnotation(String annotationId) {
    _annotations.remove(annotationId);
    _grid.remove(
      AnnotationSpatialItem(annotationId: annotationId, bounds: Rect.zero).id,
    );
  }

  /// Removes a connection from the spatial index.
  void removeConnection(String connectionId) {
    _connections.remove(connectionId);
    _removeConnectionSegments(connectionId);
  }

  void _removeConnectionSegments(String connectionId) {
    final segmentIds = _connectionSegmentIds.remove(connectionId);
    if (segmentIds != null) {
      for (final segmentId in segmentIds) {
        _grid.remove(segmentId);
      }
    }
  }

  /// Clears all items from the spatial index.
  void clear() {
    _nodes.clear();
    _connections.clear();
    _annotations.clear();
    _connectionSegmentIds.clear();
    _grid.clear();
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
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // QUERIES
  // ═══════════════════════════════════════════════════════════════════════════

  /// Performs hit testing at a point.
  ///
  /// Tests in priority order: ports → nodes → connections → annotations → canvas
  HitTestResult hitTest(Offset point) {
    // 1. Ports (highest priority)
    final portResult = _hitTestPorts(point);
    if (portResult != null) return portResult;

    // 2. Nodes
    final nodeResult = _hitTestNodes(point);
    if (nodeResult != null) return nodeResult;

    // 3. Connections
    final connectionResult = _hitTestConnections(point);
    if (connectionResult != null) return connectionResult;

    // 4. Annotations
    final annotationResult = _hitTestAnnotations(point);
    if (annotationResult != null) return annotationResult;

    // 5. Canvas (background)
    return const HitTestResult(hitType: HitTarget.canvas);
  }

  /// Gets all nodes at a point.
  List<Node<T>> nodesAt(Offset point, {double radius = 0}) {
    return _grid
        .queryPoint(point, radius: radius)
        .whereType<NodeSpatialItem>()
        .map((item) => _nodes[item.nodeId])
        .whereType<Node<T>>()
        .toList();
  }

  /// Gets all nodes within bounds.
  List<Node<T>> nodesIn(Rect bounds) {
    return _grid
        .query(bounds)
        .whereType<NodeSpatialItem>()
        .map((item) => _nodes[item.nodeId])
        .whereType<Node<T>>()
        .toList();
  }

  /// Gets all connections at a point.
  List<Connection> connectionsAt(Offset point, {double radius = 0}) {
    final connectionIds = _grid
        .queryPoint(point, radius: radius)
        .whereType<ConnectionSegmentItem>()
        .map((item) => item.connectionId)
        .toSet();
    return connectionIds
        .map((id) => _connections[id])
        .whereType<Connection>()
        .toList();
  }

  /// Gets all annotations at a point.
  List<Annotation> annotationsAt(Offset point, {double radius = 0}) {
    return _grid
        .queryPoint(point, radius: radius)
        .whereType<AnnotationSpatialItem>()
        .map((item) => _annotations[item.annotationId])
        .whereType<Annotation>()
        .toList();
  }

  /// Gets a node by ID.
  Node<T>? getNode(String id) => _nodes[id];

  /// Gets a connection by ID.
  Connection? getConnection(String id) => _connections[id];

  /// Gets an annotation by ID.
  Annotation? getAnnotation(String id) => _annotations[id];

  // ═══════════════════════════════════════════════════════════════════════════
  // BULK REBUILD
  // ═══════════════════════════════════════════════════════════════════════════

  /// Rebuilds the entire index from the given elements.
  ///
  /// Use this after loading a graph or performing major structural changes.
  void rebuild({
    required Iterable<Node<T>> nodes,
    required Iterable<Connection> connections,
    required Iterable<Annotation> annotations,
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
      for (final annotation in annotations) {
        updateAnnotation(annotation);
      }
    });
  }

  /// Rebuilds only nodes from the given iterable.
  void rebuildFromNodes(Iterable<Node<T>> nodes) {
    // Clear existing nodes
    for (final nodeId in _nodes.keys.toList()) {
      _grid.remove(NodeSpatialItem(nodeId: nodeId, bounds: Rect.zero).id);
    }
    _nodes.clear();

    // Add new nodes
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
      _removeConnectionSegments(connectionId);
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

  /// Rebuilds connections using single bounds calculator (legacy compatibility).
  void rebuildConnections(
    Iterable<Connection> connections,
    Rect Function(Connection) boundsCalculator,
  ) {
    rebuildConnectionsWithSegments(
      connections,
      (connection) => [boundsCalculator(connection)],
    );
  }

  /// Rebuilds only annotations from the given iterable.
  void rebuildFromAnnotations(Iterable<Annotation> annotations) {
    // Clear existing annotations
    for (final annotationId in _annotations.keys.toList()) {
      _grid.remove(
        AnnotationSpatialItem(annotationId: annotationId, bounds: Rect.zero).id,
      );
    }
    _annotations.clear();

    // Add new annotations
    batch(() {
      for (final annotation in annotations) {
        updateAnnotation(annotation);
      }
    });
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // STATISTICS
  // ═══════════════════════════════════════════════════════════════════════════

  int get nodeCount => _nodes.length;
  int get connectionCount => _connections.length;
  int get annotationCount => _annotations.length;
  SpatialIndexStats get stats => _grid.stats;

  // ═══════════════════════════════════════════════════════════════════════════
  // PRIVATE IMPLEMENTATION
  // ═══════════════════════════════════════════════════════════════════════════

  void _autoFlush() {
    if (!_inBatch) {
      _grid.flushPendingUpdates();
    }
  }

  HitTestResult? _hitTestPorts(Offset point) {
    final nearbyNodes = _grid
        .queryPoint(point, radius: portSnapDistance)
        .whereType<NodeSpatialItem>()
        .map((item) => _nodes[item.nodeId])
        .whereType<Node<T>>()
        .toList();

    // Sort by zIndex descending (highest first = visually on top)
    // For nodes with same zIndex, we need to check render order
    nearbyNodes.sort((a, b) => b.zIndex.value.compareTo(a.zIndex.value));

    for (final node in nearbyNodes) {
      final shape = nodeShapeBuilder?.call(node);

      for (final port in [...node.inputPorts, ...node.outputPorts]) {
        final effectivePortSize =
            portSizeResolver?.call(port) ?? const Size.square(10.0);
        final portPosition = node.getPortPosition(
          port.id,
          portSize: effectivePortSize,
          shape: shape,
        );
        final distance = (point - portPosition).distance;

        if (distance <= portSnapDistance) {
          // Check if any other node is covering this port position
          // This includes nodes with higher zIndex OR nodes with the same zIndex
          // that render later (appear later in the render order)
          final isCoveredByOtherNode = _isPointCoveredByOtherNode(
            portPosition,
            node,
          );

          if (!isCoveredByOtherNode) {
            return HitTestResult(
              nodeId: node.id,
              portId: port.id,
              isOutput: node.outputPorts.contains(port),
              hitType: HitTarget.port,
            );
          }
        }
      }
    }
    return null;
  }

  /// Checks if a point is covered by any node that renders above [excludeNode].
  ///
  /// A node renders above another if:
  /// 1. It has a higher zIndex, OR
  /// 2. It has the same zIndex but appears later in the render order
  ///
  /// Used to ensure that ports visually obscured by overlapping nodes are not hit.
  bool _isPointCoveredByOtherNode(Offset point, Node<T> excludeNode) {
    final nodesAtPoint = _grid
        .queryPoint(point)
        .whereType<NodeSpatialItem>()
        .map((item) => _nodes[item.nodeId])
        .whereType<Node<T>>()
        .where((node) => node.id != excludeNode.id)
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
  /// Returns true if nodeA has a higher zIndex, or if they have the same zIndex
  /// and nodeA appears later in the render order (based on _renderOrderProvider).
  bool _nodeRendersAbove(Node<T> nodeA, Node<T> nodeB) {
    final zIndexA = nodeA.zIndex.value;
    final zIndexB = nodeB.zIndex.value;

    if (zIndexA > zIndexB) {
      return true;
    } else if (zIndexA < zIndexB) {
      return false;
    }

    // Same zIndex - check render order if provider is available
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

  HitTestResult? _hitTestNodes(Offset point) {
    final candidates = _grid
        .queryPoint(point)
        .whereType<NodeSpatialItem>()
        .map((item) => _nodes[item.nodeId])
        .whereType<Node<T>>()
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
      if (connection != null &&
          (connectionHitTester?.call(connection, point) ?? false)) {
        return HitTestResult(
          connectionId: connection.id,
          hitType: HitTarget.connection,
        );
      }
    }
    return null;
  }

  HitTestResult? _hitTestAnnotations(Offset point) {
    final candidates = _grid
        .queryPoint(point)
        .whereType<AnnotationSpatialItem>()
        .map((item) => _annotations[item.annotationId])
        .whereType<Annotation>()
        .toList();
    candidates.sort((a, b) => b.zIndex.value.compareTo(a.zIndex.value));

    for (final annotation in candidates) {
      if (annotation.currentIsVisible && annotation.containsPoint(point)) {
        return HitTestResult(
          annotationId: annotation.id,
          hitType: HitTarget.annotation,
        );
      }
    }
    return null;
  }
}
