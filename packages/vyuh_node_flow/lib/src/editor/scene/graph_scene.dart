import 'dart:async';
import 'dart:collection';

import 'package:flutter/material.dart';

import '../../connections/connection.dart';
import '../../nodes/node.dart';

/// The part of a retained node representation changed by a graph mutation.
enum SceneNodeChange {
  added,
  geometry,
  visual,
  selection,
  visibility,
  zOrder,
  ports,
  interaction,
}

/// The part of a retained connection representation changed by a mutation.
enum SceneConnectionChange { added, geometry, visual, selection, visibility }

/// An immutable renderer-facing projection of a [Node].
///
/// [source] keeps existing thumbnail painters source-compatible. Rendering and
/// cache decisions should use the copied fields on this snapshot instead of
/// reading mutable MobX state from [source].
@immutable
class SceneNodeSnapshot<T> {
  const SceneNodeSnapshot({
    required this.id,
    required this.type,
    required this.position,
    required this.visualPosition,
    required this.size,
    required this.isVisible,
    required this.isSelected,
    required this.isDragging,
    required this.isEditing,
    required this.zIndex,
    required this.layer,
    required this.retainedRendering,
    required this.portRevision,
    required this.thumbnailCacheKey,
    required this.retainedVisualRevision,
    required this.source,
  });

  factory SceneNodeSnapshot.fromNode(Node<T> node) {
    return SceneNodeSnapshot<T>(
      id: node.id,
      type: node.type,
      position: node.position.value,
      visualPosition: node.visualPosition.value,
      size: node.size.value,
      isVisible: node.isVisible,
      isSelected: node.isSelected,
      isDragging: node.isDragging,
      isEditing: node.isEditing,
      zIndex: node.currentZIndex,
      layer: node.layer,
      retainedRendering: node.retainedRendering,
      portRevision: Object.hashAll(node.ports),
      thumbnailCacheKey: node.thumbnailCacheKey,
      retainedVisualRevision: node.retainedVisualRevision,
      source: node,
    );
  }

  final String id;
  final String type;
  final Offset position;
  final Offset visualPosition;
  final Size size;
  final bool isVisible;
  final bool isSelected;
  final bool isDragging;
  final bool isEditing;
  final int zIndex;
  final NodeRenderLayer layer;
  final RetainedNodeRendering retainedRendering;
  final int portRevision;
  final Object? thumbnailCacheKey;
  final int retainedVisualRevision;
  final Node<T> source;
}

/// An immutable renderer-facing projection of a [Connection].
@immutable
class SceneConnectionSnapshot<C> {
  const SceneConnectionSnapshot({
    required this.id,
    required this.sourceNodeId,
    required this.sourcePortId,
    required this.targetNodeId,
    required this.targetPortId,
    required this.isVisible,
    required this.isSelected,
    required this.isAnimated,
    required this.visualRevision,
    required this.source,
  });

  factory SceneConnectionSnapshot.fromConnection(Connection<C> connection) {
    return SceneConnectionSnapshot<C>(
      id: connection.id,
      sourceNodeId: connection.sourceNodeId,
      sourcePortId: connection.sourcePortId,
      targetNodeId: connection.targetNodeId,
      targetPortId: connection.targetPortId,
      isVisible: connection.visible,
      isSelected: connection.selected,
      isAnimated: connection.animated,
      visualRevision: Object.hash(
        connection.style,
        connection.startLabel,
        connection.label,
        connection.endLabel,
        connection.startPoint,
        connection.endPoint,
        connection.color,
        connection.selectedColor,
        connection.strokeWidth,
        connection.selectedStrokeWidth,
        connection.animationEffect,
      ),
      source: connection,
    );
  }

  final String id;
  final String sourceNodeId;
  final String sourcePortId;
  final String targetNodeId;
  final String targetPortId;
  final bool isVisible;
  final bool isSelected;
  final bool isAnimated;
  final int visualRevision;
  final Connection<C> source;
}

/// A stable immutable view of the complete renderer scene.
@immutable
class SceneSnapshot<T, C> {
  SceneSnapshot({
    required this.revision,
    required Map<String, SceneNodeSnapshot<T>> nodes,
    required Map<String, SceneConnectionSnapshot<C>> connections,
  }) : nodes = UnmodifiableMapView(Map.of(nodes)),
       connections = UnmodifiableMapView(Map.of(connections));

  final int revision;
  final Map<String, SceneNodeSnapshot<T>> nodes;
  final Map<String, SceneConnectionSnapshot<C>> connections;
}

/// A coalesced immutable change between two scene revisions.
@immutable
class SceneDelta<T, C> {
  SceneDelta({
    required this.fromRevision,
    required this.toRevision,
    required Map<String, SceneNodeSnapshot<T>> nodes,
    required Map<String, Set<SceneNodeChange>> nodeChanges,
    required Set<String> removedNodeIds,
    required Map<String, SceneConnectionSnapshot<C>> connections,
    required Map<String, Set<SceneConnectionChange>> connectionChanges,
    required Set<String> removedConnectionIds,
  }) : nodes = UnmodifiableMapView(Map.of(nodes)),
       nodeChanges = UnmodifiableMapView({
         for (final entry in nodeChanges.entries)
           entry.key: Set<SceneNodeChange>.unmodifiable(entry.value),
       }),
       removedNodeIds = Set<String>.unmodifiable(removedNodeIds),
       connections = UnmodifiableMapView(Map.of(connections)),
       connectionChanges = UnmodifiableMapView({
         for (final entry in connectionChanges.entries)
           entry.key: Set<SceneConnectionChange>.unmodifiable(entry.value),
       }),
       removedConnectionIds = Set<String>.unmodifiable(removedConnectionIds);

  final int fromRevision;
  final int toRevision;
  final Map<String, SceneNodeSnapshot<T>> nodes;
  final Map<String, Set<SceneNodeChange>> nodeChanges;
  final Set<String> removedNodeIds;
  final Map<String, SceneConnectionSnapshot<C>> connections;
  final Map<String, Set<SceneConnectionChange>> connectionChanges;
  final Set<String> removedConnectionIds;

  bool get hasNodeChanges => nodes.isNotEmpty || removedNodeIds.isNotEmpty;
  bool get hasConnectionChanges =>
      connections.isNotEmpty || removedConnectionIds.isNotEmpty;
}

/// A granular signal carrying the most recently published scene delta.
class SceneDeltaListenable<T, C> extends ChangeNotifier {
  SceneDelta<T, C>? get value => _value;
  SceneDelta<T, C>? _value;

  void publish(SceneDelta<T, C> delta) {
    _value = delta;
    notifyListeners();
  }
}

/// Maintains immutable render snapshots and emits coalesced scene deltas.
///
/// Writes update O(1) entity entries immediately. Notifications are merged in
/// a microtask so a MobX action or controller batch causes one render invalidation
/// instead of rebuilding the widget tree for every changed entity.
class GraphSceneProjection<T, C> {
  final Map<String, SceneNodeSnapshot<T>> _nodes = {};
  final Map<String, SceneConnectionSnapshot<C>> _connections = {};

  final Map<String, Set<SceneNodeChange>> _pendingNodeChanges = {};
  final Map<String, Set<SceneConnectionChange>> _pendingConnectionChanges = {};
  final Set<String> _pendingRemovedNodeIds = {};
  final Set<String> _pendingRemovedConnectionIds = {};

  final SceneDeltaListenable<T, C> nodeDeltas = SceneDeltaListenable<T, C>();
  final SceneDeltaListenable<T, C> connectionDeltas =
      SceneDeltaListenable<T, C>();

  int _revision = 0;
  bool _flushScheduled = false;
  bool _disposed = false;

  int get revision => _revision;

  SceneSnapshot<T, C> get snapshot => SceneSnapshot<T, C>(
    revision: _revision,
    nodes: _nodes,
    connections: _connections,
  );

  SceneNodeSnapshot<T>? nodeSnapshot(String id) => _nodes[id];
  SceneConnectionSnapshot<C>? connectionSnapshot(String id) => _connections[id];

  void seed({
    required Iterable<Node<T>> nodes,
    required Iterable<Connection<C>> connections,
  }) {
    _nodes
      ..clear()
      ..addEntries(
        nodes.map(
          (node) => MapEntry(node.id, SceneNodeSnapshot.fromNode(node)),
        ),
      );
    _connections
      ..clear()
      ..addEntries(
        connections.map(
          (connection) => MapEntry(
            connection.id,
            SceneConnectionSnapshot.fromConnection(connection),
          ),
        ),
      );
  }

  void upsertNode(Node<T> node, Set<SceneNodeChange> changes) {
    if (_disposed) return;
    _nodes[node.id] = SceneNodeSnapshot.fromNode(node);
    _pendingRemovedNodeIds.remove(node.id);
    _pendingNodeChanges.putIfAbsent(node.id, () => {}).addAll(changes);
    _scheduleFlush();
  }

  void removeNode(String id) {
    if (_disposed || _nodes.remove(id) == null) return;
    _pendingNodeChanges.remove(id);
    _pendingRemovedNodeIds.add(id);
    _scheduleFlush();
  }

  void upsertConnection(
    Connection<C> connection,
    Set<SceneConnectionChange> changes,
  ) {
    if (_disposed) return;
    _connections[connection.id] = SceneConnectionSnapshot.fromConnection(
      connection,
    );
    _pendingRemovedConnectionIds.remove(connection.id);
    _pendingConnectionChanges
        .putIfAbsent(connection.id, () => {})
        .addAll(changes);
    _scheduleFlush();
  }

  void removeConnection(String id) {
    if (_disposed || _connections.remove(id) == null) return;
    _pendingConnectionChanges.remove(id);
    _pendingRemovedConnectionIds.add(id);
    _scheduleFlush();
  }

  void _scheduleFlush() {
    if (_flushScheduled) return;
    _flushScheduled = true;
    scheduleMicrotask(_flush);
  }

  void _flush() {
    _flushScheduled = false;
    if (_disposed) return;
    if (_pendingNodeChanges.isEmpty &&
        _pendingRemovedNodeIds.isEmpty &&
        _pendingConnectionChanges.isEmpty &&
        _pendingRemovedConnectionIds.isEmpty) {
      return;
    }

    final fromRevision = _revision;
    _revision++;
    final changedNodes = <String, SceneNodeSnapshot<T>>{};
    for (final id in _pendingNodeChanges.keys) {
      final snapshot = _nodes[id];
      if (snapshot != null) changedNodes[id] = snapshot;
    }
    final changedConnections = <String, SceneConnectionSnapshot<C>>{};
    for (final id in _pendingConnectionChanges.keys) {
      final snapshot = _connections[id];
      if (snapshot != null) changedConnections[id] = snapshot;
    }
    final delta = SceneDelta<T, C>(
      fromRevision: fromRevision,
      toRevision: _revision,
      nodes: changedNodes,
      nodeChanges: _pendingNodeChanges,
      removedNodeIds: _pendingRemovedNodeIds,
      connections: changedConnections,
      connectionChanges: _pendingConnectionChanges,
      removedConnectionIds: _pendingRemovedConnectionIds,
    );

    _pendingNodeChanges.clear();
    _pendingRemovedNodeIds.clear();
    _pendingConnectionChanges.clear();
    _pendingRemovedConnectionIds.clear();

    if (delta.hasNodeChanges) nodeDeltas.publish(delta);
    if (delta.hasConnectionChanges) connectionDeltas.publish(delta);
  }

  void dispose() {
    _disposed = true;
    nodeDeltas.dispose();
    connectionDeltas.dispose();
    _nodes.clear();
    _connections.clear();
    _pendingNodeChanges.clear();
    _pendingConnectionChanges.clear();
    _pendingRemovedNodeIds.clear();
    _pendingRemovedConnectionIds.clear();
  }
}
