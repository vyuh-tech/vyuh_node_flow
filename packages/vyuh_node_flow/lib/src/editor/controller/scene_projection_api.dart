part of 'node_flow_controller.dart';

extension SceneProjectionApi<T, C> on NodeFlowController<T, C> {
  /// Granular immutable scene used by retained renderers and diagnostics.
  GraphSceneProjection<T, C> get sceneProjection => _sceneProjection;

  /// Captures an immutable full scene for export, debugging, or a new renderer.
  ///
  /// Hot paint paths should use [sceneProjection] entity lookup and delta
  /// listenables so they do not copy the complete graph on every frame.
  SceneSnapshot<T, C> get sceneSnapshot => _sceneProjection.snapshot;
}

extension _SceneProjectionInternals<T, C> on NodeFlowController<T, C> {
  void _initializeSceneProjection() {
    _sceneProjection.seed(nodes: _nodes.values, connections: _connections);

    for (final node in _nodes.values) {
      _observeSceneNode(node);
    }
    for (final connection in _connections) {
      _observeSceneConnection(connection);
    }

    _sceneCollectionReactions.add(
      reaction(
        (_) {
          return Object.hashAll(
            _nodes.entries.map(
              (entry) => Object.hash(entry.key, identityHashCode(entry.value)),
            ),
          );
        },
        (_) {
          final ids = _nodes.keys.toSet();
          final removed = _sceneNodeReactions.keys
              .where((id) => !ids.contains(id))
              .toList(growable: false);
          for (final id in removed) {
            _sceneNodeReactions.remove(id)?.call();
            _sceneNodeSources.remove(id);
            _sceneProjection.removeNode(id);
          }
          for (final id in ids) {
            final node = _nodes[id];
            if (node == null || identical(_sceneNodeSources[id], node)) {
              continue;
            }
            _sceneNodeReactions.remove(id)?.call();
            _observeSceneNode(node);
            _sceneProjection.upsertNode(node, const {SceneNodeChange.added});
          }
        },
      ),
    );

    _sceneCollectionReactions.add(
      reaction(
        (_) {
          return Object.hashAll(
            _connections.map(
              (connection) =>
                  Object.hash(connection.id, identityHashCode(connection)),
            ),
          );
        },
        (_) {
          final ids = _connections.map((connection) => connection.id).toSet();
          final removed = _sceneConnectionReactions.keys
              .where((id) => !ids.contains(id))
              .toList(growable: false);
          for (final id in removed) {
            _sceneConnectionReactions.remove(id)?.call();
            _sceneConnectionSources.remove(id);
            _sceneProjection.removeConnection(id);
          }
          for (final id in ids) {
            final connection = _connectionById[id];
            if (connection == null ||
                identical(_sceneConnectionSources[id], connection)) {
              continue;
            }
            _sceneConnectionReactions.remove(id)?.call();
            _observeSceneConnection(connection);
            _sceneProjection.upsertConnection(connection, const {
              SceneConnectionChange.added,
            });
          }
        },
      ),
    );
  }

  void _observeSceneNode(Node<T> node) {
    _sceneNodeSources[node.id] = node;
    var previous = _SceneNodeObserved.fromNode(node);
    _sceneNodeReactions[node.id] = node.observeSceneChanges(() {
      final next = _SceneNodeObserved.fromNode(node);
      final changes = <SceneNodeChange>{};
      if (previous.position != next.position ||
          previous.visualPosition != next.visualPosition ||
          previous.size != next.size) {
        changes.add(SceneNodeChange.geometry);
      }
      if (previous.visualKey != next.visualKey ||
          previous.retainedVisualRevision != next.retainedVisualRevision) {
        changes.add(SceneNodeChange.visual);
      }
      if (previous.isSelected != next.isSelected) {
        changes.add(SceneNodeChange.selection);
      }
      if (previous.isVisible != next.isVisible) {
        changes.add(SceneNodeChange.visibility);
      }
      if (previous.zIndex != next.zIndex) {
        changes.add(SceneNodeChange.zOrder);
      }
      if (previous.portRevision != next.portRevision) {
        changes.add(SceneNodeChange.ports);
      }
      if (previous.isDragging != next.isDragging ||
          previous.isEditing != next.isEditing) {
        changes.add(SceneNodeChange.interaction);
      }
      previous = next;
      if (changes.isEmpty) return;

      _sceneProjection.upsertNode(node, changes);
      if (changes.contains(SceneNodeChange.geometry) ||
          changes.contains(SceneNodeChange.ports) ||
          changes.contains(SceneNodeChange.visibility)) {
        for (final connectionId in _connectionsByNodeId[node.id] ?? const {}) {
          final connection = _connectionById[connectionId];
          if (connection != null) {
            _sceneProjection.upsertConnection(connection, const {
              SceneConnectionChange.geometry,
            });
          }
        }
      }
    });
  }

  void _observeSceneConnection(Connection<C> connection) {
    _sceneConnectionSources[connection.id] = connection;
    var previous = _SceneConnectionObserved.fromConnection(connection);
    _sceneConnectionReactions[connection.id] = connection.observeSceneChanges(
      () {
        final next = _SceneConnectionObserved.fromConnection(connection);
        final changes = <SceneConnectionChange>{};
        if (previous.visualRevision != next.visualRevision ||
            previous.isAnimated != next.isAnimated) {
          changes.add(SceneConnectionChange.visual);
        }
        if (previous.isSelected != next.isSelected) {
          changes.add(SceneConnectionChange.selection);
        }
        if (previous.isVisible != next.isVisible) {
          changes.add(SceneConnectionChange.visibility);
        }
        previous = next;
        if (changes.isNotEmpty) {
          _sceneProjection.upsertConnection(connection, changes);
        }
      },
    );
  }

  void _disposeSceneProjection() {
    for (final dispose in _sceneCollectionReactions) {
      dispose();
    }
    for (final dispose in _sceneNodeReactions.values) {
      dispose();
    }
    for (final dispose in _sceneConnectionReactions.values) {
      dispose();
    }
    _sceneCollectionReactions.clear();
    _sceneNodeReactions.clear();
    _sceneConnectionReactions.clear();
    _sceneNodeSources.clear();
    _sceneConnectionSources.clear();
    _sceneProjection.dispose();
  }
}

class _SceneNodeObserved {
  const _SceneNodeObserved({
    required this.position,
    required this.visualPosition,
    required this.size,
    required this.isVisible,
    required this.isSelected,
    required this.isDragging,
    required this.isEditing,
    required this.zIndex,
    required this.portRevision,
    required this.visualKey,
    required this.retainedVisualRevision,
  });

  factory _SceneNodeObserved.fromNode(Node<dynamic> node) {
    return _SceneNodeObserved(
      position: node.position.value,
      visualPosition: node.visualPosition.value,
      size: node.size.value,
      isVisible: node.isVisible,
      isSelected: node.isSelected,
      isDragging: node.isDragging,
      isEditing: node.isEditing,
      zIndex: node.currentZIndex,
      portRevision: Object.hashAll(node.ports),
      visualKey: node.thumbnailCacheKey,
      retainedVisualRevision: node.retainedVisualRevision,
    );
  }

  final Offset position;
  final Offset visualPosition;
  final Size size;
  final bool isVisible;
  final bool isSelected;
  final bool isDragging;
  final bool isEditing;
  final int zIndex;
  final int portRevision;
  final Object? visualKey;
  final int retainedVisualRevision;

  @override
  bool operator ==(Object other) =>
      other is _SceneNodeObserved &&
      other.position == position &&
      other.visualPosition == visualPosition &&
      other.size == size &&
      other.isVisible == isVisible &&
      other.isSelected == isSelected &&
      other.isDragging == isDragging &&
      other.isEditing == isEditing &&
      other.zIndex == zIndex &&
      other.portRevision == portRevision &&
      other.visualKey == visualKey &&
      other.retainedVisualRevision == retainedVisualRevision;

  @override
  int get hashCode => Object.hash(
    position,
    visualPosition,
    size,
    isVisible,
    isSelected,
    isDragging,
    isEditing,
    zIndex,
    portRevision,
    visualKey,
    retainedVisualRevision,
  );
}

class _SceneConnectionObserved {
  const _SceneConnectionObserved({
    required this.isVisible,
    required this.isSelected,
    required this.isAnimated,
    required this.visualRevision,
  });

  factory _SceneConnectionObserved.fromConnection(
    Connection<dynamic> connection,
  ) {
    return _SceneConnectionObserved(
      isVisible: connection.visible,
      isSelected: connection.selected,
      isAnimated: connection.animated,
      visualRevision: SceneConnectionSnapshot.fromConnection(
        connection,
      ).visualRevision,
    );
  }

  final bool isVisible;
  final bool isSelected;
  final bool isAnimated;
  final int visualRevision;

  @override
  bool operator ==(Object other) =>
      other is _SceneConnectionObserved &&
      other.isVisible == isVisible &&
      other.isSelected == isSelected &&
      other.isAnimated == isAnimated &&
      other.visualRevision == visualRevision;

  @override
  int get hashCode =>
      Object.hash(isVisible, isSelected, isAnimated, visualRevision);
}
