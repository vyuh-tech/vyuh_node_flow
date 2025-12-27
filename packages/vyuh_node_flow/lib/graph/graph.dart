import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;

import '../connections/connection.dart';
import '../nodes/comment_node.dart';
import '../nodes/group_node.dart';
import '../nodes/node.dart';
import 'viewport.dart';

/// Default factory for deserializing nodes with type routing.
///
/// Routes to the appropriate Node subclass based on the 'type' field:
/// - 'group' -> GroupNode
/// - 'comment' -> CommentNode
/// - All other types -> Node (base class)
///
/// Parameters:
/// * [json] - The JSON map containing node data
/// * [fromJsonT] - Function to deserialize the custom data of type [T]
Node<T> defaultNodeFromJson<T>(
  Map<String, dynamic> json,
  T Function(Object? json) fromJsonT,
) {
  final type = json['type'] as String;
  return switch (type) {
    'group' => GroupNode<T>.fromJson(json, dataFromJson: fromJsonT),
    'comment' => CommentNode<T>.fromJson(json, dataFromJson: fromJsonT),
    _ => Node<T>.fromJson(json, fromJsonT),
  };
}

/// Immutable data class for graph serialization/deserialization
/// All state management is handled by NodeFlowController
class NodeGraph<T> {
  const NodeGraph({
    this.nodes = const [],
    this.connections = const [],
    this.viewport = const GraphViewport(),
    this.metadata = const {},
  });

  final List<Node<T>> nodes;
  final List<Connection> connections;
  final GraphViewport viewport;
  final Map<String, dynamic> metadata;

  // Utility methods for graph analysis (non-reactive)

  /// Get a node by its ID
  Node<T>? getNodeById(String nodeId) {
    return nodes.cast<Node<T>?>().firstWhere(
      (node) => node?.id == nodeId,
      orElse: () => null,
    );
  }

  /// Get the index of a node by its ID
  int getNodeIndex(String nodeId) {
    return nodes.indexWhere((node) => node.id == nodeId);
  }

  /// Gets all connections for a specific node
  List<Connection> getNodeConnections(String nodeId) {
    return connections.where((conn) => conn.involvesNode(nodeId)).toList();
  }

  /// Gets all input connections for a node
  List<Connection> getInputConnections(String nodeId) {
    return connections.where((conn) => conn.targetNodeId == nodeId).toList();
  }

  /// Gets all output connections for a node
  List<Connection> getOutputConnections(String nodeId) {
    return connections.where((conn) => conn.sourceNodeId == nodeId).toList();
  }

  /// Gets connections for a specific port
  List<Connection> getPortConnections(String nodeId, String portId) {
    return connections
        .where((conn) => conn.involvesPort(nodeId, portId))
        .toList();
  }

  /// Checks if two nodes are connected
  bool areNodesConnected(String sourceNodeId, String targetNodeId) {
    return connections.any(
      (conn) =>
          conn.sourceNodeId == sourceNodeId &&
          conn.targetNodeId == targetNodeId,
    );
  }

  /// Gets the bounding box of all nodes
  Rect getBounds() {
    if (nodes.isEmpty) return Rect.zero;

    double minX = double.infinity;
    double minY = double.infinity;
    double maxX = double.negativeInfinity;
    double maxY = double.negativeInfinity;

    for (final node in nodes) {
      final bounds = node.getBounds();
      minX = minX < bounds.left ? minX : bounds.left;
      minY = minY < bounds.top ? minY : bounds.top;
      maxX = maxX > bounds.right ? maxX : bounds.right;
      maxY = maxY > bounds.bottom ? maxY : bounds.bottom;
    }

    return Rect.fromLTRB(minX, minY, maxX, maxY);
  }

  /// Validates the graph for circular dependencies
  bool hasCircularDependency() {
    final visited = <String>{};
    final recursionStack = <String>{};

    bool hasCycle(String nodeId) {
      if (recursionStack.contains(nodeId)) return true;
      if (visited.contains(nodeId)) return false;

      visited.add(nodeId);
      recursionStack.add(nodeId);

      for (final conn in getOutputConnections(nodeId)) {
        if (hasCycle(conn.targetNodeId)) return true;
      }

      recursionStack.remove(nodeId);
      return false;
    }

    for (final node in nodes) {
      if (hasCycle(node.id)) return true;
    }

    return false;
  }

  /// Gets nodes that have no input connections (root nodes)
  List<Node<T>> getRootNodes() {
    return nodes.where((node) => getInputConnections(node.id).isEmpty).toList();
  }

  /// Gets nodes that have no output connections (leaf nodes)
  List<Node<T>> getLeafNodes() {
    return nodes
        .where((node) => getOutputConnections(node.id).isEmpty)
        .toList();
  }

  // Node type filtering methods

  /// Get all group nodes
  List<GroupNode<T>> getGroupNodes() {
    return nodes.whereType<GroupNode<T>>().toList();
  }

  /// Get all comment nodes
  List<CommentNode<T>> getCommentNodes() {
    return nodes.whereType<CommentNode<T>>().toList();
  }

  /// Get regular nodes (excluding GroupNode and CommentNode)
  List<Node<T>> getRegularNodes() {
    return nodes
        .where((node) => node is! GroupNode<T> && node is! CommentNode<T>)
        .toList();
  }

  factory NodeGraph.fromJson(
    Map<String, dynamic> json,
    T Function(Object? json) fromJsonT, {
    Node<T> Function(
      Map<String, dynamic> json,
      T Function(Object? json) fromJsonT,
    )?
    nodeFromJson,
  }) {
    final actualNodeFromJson = nodeFromJson ?? defaultNodeFromJson<T>;

    final nodesJson = json['nodes'] as List<dynamic>? ?? [];
    final nodes = nodesJson
        .map((e) => actualNodeFromJson(e as Map<String, dynamic>, fromJsonT))
        .toList();

    final connectionsJson = json['connections'] as List<dynamic>? ?? [];
    final connections = connectionsJson
        .map((e) => Connection.fromJson(e as Map<String, dynamic>))
        .toList();

    final viewport = json['viewport'] != null
        ? GraphViewport.fromJson(json['viewport'] as Map<String, dynamic>)
        : GraphViewport();

    return NodeGraph<T>(
      nodes: nodes,
      connections: connections,
      viewport: viewport,
      metadata: json['metadata'] as Map<String, dynamic>? ?? {},
    );
  }

  /// Convenience method to load graph from JSON string
  static NodeGraph<T> fromJsonString<T>(
    String jsonString,
    T Function(Object? json) fromJsonT, {
    Node<T> Function(
      Map<String, dynamic> json,
      T Function(Object? json) fromJsonT,
    )?
    nodeFromJson,
  }) {
    final Map<String, dynamic> json = jsonDecode(jsonString);
    return NodeGraph<T>.fromJson(json, fromJsonT, nodeFromJson: nodeFromJson);
  }

  /// Convenience method to load graph from asset file
  static Future<NodeGraph<T>> fromAsset<T>(
    String assetPath,
    T Function(Object? json) fromJsonT, {
    Node<T> Function(
      Map<String, dynamic> json,
      T Function(Object? json) fromJsonT,
    )?
    nodeFromJson,
  }) async {
    final String jsonString = await rootBundle.loadString(assetPath);
    return fromJsonString<T>(jsonString, fromJsonT, nodeFromJson: nodeFromJson);
  }

  /// Simple factory for Map data type (most common case)
  static NodeGraph<Map<String, dynamic>> fromJsonMap(
    Map<String, dynamic> json, {
    Node<Map<String, dynamic>> Function(
      Map<String, dynamic> json,
      Map<String, dynamic> Function(Object? json) fromJsonT,
    )?
    nodeFromJson,
  }) {
    return NodeGraph<Map<String, dynamic>>.fromJson(
      json,
      (jsonData) => Map<String, dynamic>.from(jsonData as Map? ?? {}),
      nodeFromJson: nodeFromJson,
    );
  }

  /// Convenience method to load graph with Map data from JSON string
  static NodeGraph<Map<String, dynamic>> fromJsonStringMap(
    String jsonString, {
    Node<Map<String, dynamic>> Function(
      Map<String, dynamic> json,
      Map<String, dynamic> Function(Object? json) fromJsonT,
    )?
    nodeFromJson,
  }) {
    final Map<String, dynamic> json = jsonDecode(jsonString);
    return fromJsonMap(json, nodeFromJson: nodeFromJson);
  }

  /// Convenience method to load graph with Map data from asset file
  static Future<NodeGraph<Map<String, dynamic>>> fromAssetMap(
    String assetPath, {
    Node<Map<String, dynamic>> Function(
      Map<String, dynamic> json,
      Map<String, dynamic> Function(Object? json) fromJsonT,
    )?
    nodeFromJson,
  }) async {
    final String jsonString = await rootBundle.loadString(assetPath);
    return fromJsonStringMap(jsonString, nodeFromJson: nodeFromJson);
  }

  static Future<NodeGraph<Map<String, dynamic>>> fromUrl(
    String url, {
    Node<Map<String, dynamic>> Function(
      Map<String, dynamic> json,
      Map<String, dynamic> Function(Object? json) fromJsonT,
    )?
    nodeFromJson,
  }) async {
    final response = await http.get(Uri.parse(url));
    final Map<String, dynamic> json = jsonDecode(response.body);
    return fromJsonMap(json, nodeFromJson: nodeFromJson);
  }

  Map<String, dynamic> toJson(Object? Function(T value) toJsonT) => {
    'nodes': nodes.map((node) => node.toJson(toJsonT)).toList(),
    'connections': connections.map((e) => e.toJson()).toList(),
    'viewport': viewport.toJson(),
    'metadata': metadata,
  };

  /// Convenience method to convert graph to JSON string
  String toJsonString({bool indent = false}) {
    final map = toJson((value) => value);
    if (indent) {
      const encoder = JsonEncoder.withIndent('  ');
      return encoder.convert(map);
    }
    return jsonEncode(map);
  }
}
