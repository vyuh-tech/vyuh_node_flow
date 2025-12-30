part of 'graph_event.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Hover Events
// ─────────────────────────────────────────────────────────────────────────────

/// Emitted when hover state changes on a node.
class NodeHoverChanged extends GraphEvent {
  const NodeHoverChanged(this.nodeId, this.isHovered);

  /// The ID of the node whose hover state changed.
  final String nodeId;

  /// Whether the node is now hovered.
  final bool isHovered;

  @override
  String toString() => 'NodeHoverChanged($nodeId, isHovered: $isHovered)';
}

/// Emitted when hover state changes on a connection.
class ConnectionHoverChanged extends GraphEvent {
  const ConnectionHoverChanged(this.connectionId, this.isHovered);

  /// The ID of the connection whose hover state changed.
  final String connectionId;

  /// Whether the connection is now hovered.
  final bool isHovered;

  @override
  String toString() =>
      'ConnectionHoverChanged($connectionId, isHovered: $isHovered)';
}

/// Emitted when hover state changes on a port.
class PortHoverChanged extends GraphEvent {
  const PortHoverChanged({
    required this.nodeId,
    required this.portId,
    required this.isHovered,
    required this.isOutput,
  });

  /// The ID of the node containing the port.
  final String nodeId;

  /// The ID of the port whose hover state changed.
  final String portId;

  /// Whether the port is now hovered.
  final bool isHovered;

  /// Whether this is an output port (true) or input port (false).
  final bool isOutput;

  @override
  String toString() =>
      'PortHoverChanged($nodeId:$portId, isHovered: $isHovered)';
}
