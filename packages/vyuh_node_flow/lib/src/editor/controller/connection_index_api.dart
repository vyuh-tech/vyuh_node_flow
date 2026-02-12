part of 'node_flow_controller.dart';

/// Connection indexing utilities for O(1) connectivity queries.
///
/// This extension owns index maintenance and lookup helpers used by
/// rendering and connection validation paths.
extension ConnectionIndexApi<T, C> on NodeFlowController<T, C> {
  /// Checks if a port has outgoing connections.
  ///
  /// Uses an internal O(1) index instead of scanning all connections.
  bool hasOutgoingConnectionsFromPort(String nodeId, String portId) {
    return (_sourceConnectionCountByPortKey[_portKey(nodeId, portId)] ?? 0) > 0;
  }

  /// Checks if a port has incoming connections.
  ///
  /// Uses an internal O(1) index instead of scanning all connections.
  bool hasIncomingConnectionsToPort(String nodeId, String portId) {
    return (_targetConnectionCountByPortKey[_portKey(nodeId, portId)] ?? 0) > 0;
  }

  /// Checks if a port participates in any connection (incoming or outgoing).
  bool hasConnectionsForPort(String nodeId, String portId) {
    final key = _portKey(nodeId, portId);
    return (_sourceConnectionCountByPortKey[key] ?? 0) > 0 ||
        (_targetConnectionCountByPortKey[key] ?? 0) > 0;
  }

  /// Rebuilds all connection indexes from [_connections].
  ///
  /// Call this after bulk graph loading operations.
  void _rebuildConnectionIndexes() {
    _connectionsByNodeId.clear();
    _sourceConnectionCountByPortKey.clear();
    _targetConnectionCountByPortKey.clear();
    _connectionPairCountByPorts.clear();

    for (final connection in _connections) {
      _indexConnection(connection);
    }
  }

  String _portKey(String nodeId, String portId) => '$nodeId::$portId';

  String _connectionPairKey({
    required String sourceNodeId,
    required String sourcePortId,
    required String targetNodeId,
    required String targetPortId,
  }) {
    return '$sourceNodeId::$sourcePortId->$targetNodeId::$targetPortId';
  }

  void _incrementIndex(Map<String, int> index, String key) {
    index.update(key, (value) => value + 1, ifAbsent: () => 1);
  }

  void _decrementIndex(Map<String, int> index, String key) {
    final current = index[key];
    if (current == null) return;
    if (current <= 1) {
      index.remove(key);
      return;
    }
    index[key] = current - 1;
  }

  void _indexConnection(Connection<C> connection) {
    _connectionsByNodeId
        .putIfAbsent(connection.sourceNodeId, () => {})
        .add(connection.id);
    _connectionsByNodeId
        .putIfAbsent(connection.targetNodeId, () => {})
        .add(connection.id);

    _incrementIndex(
      _sourceConnectionCountByPortKey,
      _portKey(connection.sourceNodeId, connection.sourcePortId),
    );
    _incrementIndex(
      _targetConnectionCountByPortKey,
      _portKey(connection.targetNodeId, connection.targetPortId),
    );
    _incrementIndex(
      _connectionPairCountByPorts,
      _connectionPairKey(
        sourceNodeId: connection.sourceNodeId,
        sourcePortId: connection.sourcePortId,
        targetNodeId: connection.targetNodeId,
        targetPortId: connection.targetPortId,
      ),
    );
  }

  void _deindexConnection(Connection<C> connection) {
    final sourceSet = _connectionsByNodeId[connection.sourceNodeId];
    sourceSet?.remove(connection.id);
    if (sourceSet != null && sourceSet.isEmpty) {
      _connectionsByNodeId.remove(connection.sourceNodeId);
    }

    final targetSet = _connectionsByNodeId[connection.targetNodeId];
    targetSet?.remove(connection.id);
    if (targetSet != null && targetSet.isEmpty) {
      _connectionsByNodeId.remove(connection.targetNodeId);
    }

    _decrementIndex(
      _sourceConnectionCountByPortKey,
      _portKey(connection.sourceNodeId, connection.sourcePortId),
    );
    _decrementIndex(
      _targetConnectionCountByPortKey,
      _portKey(connection.targetNodeId, connection.targetPortId),
    );
    _decrementIndex(
      _connectionPairCountByPorts,
      _connectionPairKey(
        sourceNodeId: connection.sourceNodeId,
        sourcePortId: connection.sourcePortId,
        targetNodeId: connection.targetNodeId,
        targetPortId: connection.targetPortId,
      ),
    );
  }
}
