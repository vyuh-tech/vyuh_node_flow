import 'package:flutter/material.dart';

import '../nodes/node.dart';
import 'spatial_index.dart';

/// Adapter to make Node work with the generic spatial index
class NodeSpatialAdapter<T> implements SpatialIndexable {
  NodeSpatialAdapter(this.node);

  final Node<T> node;

  @override
  String get id => node.id;

  @override
  Rect getBounds() => node.getBounds();
}

/// Specialized spatial index for managing Node objects
class NodeSpatialIndex<T> {
  NodeSpatialIndex({double gridSize = 500.0, bool enableCaching = true})
    : _spatialIndex = SpatialIndex<NodeSpatialAdapter<T>>(
        gridSize: gridSize,
        enableCaching: enableCaching,
      ),
      _nodeAdapters = <String, NodeSpatialAdapter<T>>{};

  final SpatialIndex<NodeSpatialAdapter<T>> _spatialIndex;
  final Map<String, NodeSpatialAdapter<T>> _nodeAdapters;

  /// Add or update a node in the spatial index
  void addOrUpdateNode(Node<T> node) {
    // Reuse existing adapter if available to maintain spatial index consistency
    var adapter = _nodeAdapters[node.id];
    if (adapter == null || adapter.node != node) {
      adapter = NodeSpatialAdapter(node);
      _nodeAdapters[node.id] = adapter;
    }
    _spatialIndex.addOrUpdate(adapter);
  }

  /// Remove a node from the spatial index
  void removeNode(String nodeId) {
    _nodeAdapters.remove(nodeId);
    _spatialIndex.remove(nodeId);
  }

  /// Clear all nodes from the spatial index
  void clear() {
    if (_nodeAdapters.isEmpty) return;
    _nodeAdapters.clear();
    _spatialIndex.clear();
  }

  /// Get all nodes that intersect with the given bounds
  List<Node<T>> queryNodes(Rect bounds) {
    final adapters = _spatialIndex.query(bounds);
    return adapters.map((adapter) => adapter.node).toList();
  }

  /// Start drag optimization for specified node IDs
  void startNodeDragging(List<String> nodeIds) {
    _spatialIndex.startDragging(nodeIds);
  }

  /// End drag optimization and rebuild spatial index for dragged nodes
  void endNodeDragging() {
    _spatialIndex.endDragging();
  }

  /// Update spatial index for nodes that are currently being dragged
  void updateDraggingNodes(List<Node<T>> nodes) {
    final adapters = <NodeSpatialAdapter<T>>[];

    for (final node in nodes) {
      var adapter = _nodeAdapters[node.id];
      if (adapter == null || adapter.node != node) {
        // Update adapter to ensure it references the current node
        adapter = NodeSpatialAdapter(node);
        _nodeAdapters[node.id] = adapter;
      }
      adapters.add(adapter);
    }

    _spatialIndex.updateDraggingObjects(adapters);
  }

  /// Get node by ID
  Node<T>? getNode(String nodeId) {
    return _nodeAdapters[nodeId]?.node;
  }

  /// Get total number of nodes in the index
  int get nodeCount => _spatialIndex.objectCount;

  /// Check if spatial grid is being used for performance
  bool get isUsingSpatialGrid => _spatialIndex.isUsingSpatialGrid;

  /// Get performance statistics
  SpatialIndexStats get stats => _spatialIndex.stats;

  /// Rebuild the entire spatial index (use sparingly)
  void rebuildFromNodes(Iterable<Node<T>> nodes) {
    clear();
    for (final node in nodes) {
      addOrUpdateNode(node);
    }
  }

  /// Force process any pending spatial index updates immediately
  void flushPendingUpdates() {
    _spatialIndex.flushPendingUpdates();
  }
}
