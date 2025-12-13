import 'package:flutter/material.dart';

import 'spatial_grid.dart';

/// Sealed class hierarchy for spatial items in the node flow graph.
///
/// Using sealed classes provides:
/// - Exhaustive pattern matching (compiler enforces handling all cases)
/// - Type-specific fields (no nullable fields for irrelevant data)
/// - Clear type hierarchy
///
/// ## Pattern Matching Example
///
/// ```dart
/// final result = switch (item) {
///   NodeSpatialItem(:final nodeId) => 'Node: $nodeId',
///   PortSpatialItem(:final portId, :final nodeId) => 'Port: $portId on $nodeId',
///   ConnectionSegmentItem(:final connectionId, :final segmentIndex) =>
///     'Connection: $connectionId[$segmentIndex]',
///   AnnotationSpatialItem(:final annotationId) => 'Annotation: $annotationId',
/// };
/// ```
sealed class SpatialItem implements SpatialIndexable {
  const SpatialItem({required this.bounds});

  /// The bounding rectangle of this item.
  final Rect bounds;

  /// Unique identifier for the spatial index.
  @override
  String get id;

  /// The ID of the actual domain object (node ID, connection ID, etc.).
  String get referenceId;

  @override
  Rect getBounds() => bounds;

  /// Creates a copy with updated bounds.
  SpatialItem copyWithBounds(Rect newBounds);
}

/// Spatial item for a node.
final class NodeSpatialItem extends SpatialItem {
  const NodeSpatialItem({required this.nodeId, required super.bounds});

  final String nodeId;

  @override
  String get id => 'node_$nodeId';

  @override
  String get referenceId => nodeId;

  @override
  NodeSpatialItem copyWithBounds(Rect newBounds) =>
      NodeSpatialItem(nodeId: nodeId, bounds: newBounds);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is NodeSpatialItem &&
          runtimeType == other.runtimeType &&
          nodeId == other.nodeId;

  @override
  int get hashCode => nodeId.hashCode;

  @override
  String toString() => 'NodeSpatialItem($nodeId, bounds: $bounds)';
}

/// Spatial item for a port on a node.
final class PortSpatialItem extends SpatialItem {
  const PortSpatialItem({
    required this.portId,
    required this.nodeId,
    required this.isOutput,
    required super.bounds,
  });

  final String portId;
  final String nodeId;

  /// Whether this is an output port (true) or input port (false).
  final bool isOutput;

  @override
  String get id => 'port_${nodeId}_$portId';

  @override
  String get referenceId => portId;

  @override
  PortSpatialItem copyWithBounds(Rect newBounds) => PortSpatialItem(
    portId: portId,
    nodeId: nodeId,
    isOutput: isOutput,
    bounds: newBounds,
  );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PortSpatialItem &&
          runtimeType == other.runtimeType &&
          portId == other.portId &&
          nodeId == other.nodeId;

  @override
  int get hashCode => Object.hash(portId, nodeId);

  @override
  String toString() => 'PortSpatialItem($portId on $nodeId, bounds: $bounds)';
}

/// Spatial item for a segment of a connection path.
final class ConnectionSegmentItem extends SpatialItem {
  const ConnectionSegmentItem({
    required this.connectionId,
    required this.segmentIndex,
    required super.bounds,
  });

  final String connectionId;
  final int segmentIndex;

  @override
  String get id => 'conn_${connectionId}_seg_$segmentIndex';

  @override
  String get referenceId => connectionId;

  @override
  ConnectionSegmentItem copyWithBounds(Rect newBounds) => ConnectionSegmentItem(
    connectionId: connectionId,
    segmentIndex: segmentIndex,
    bounds: newBounds,
  );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ConnectionSegmentItem &&
          runtimeType == other.runtimeType &&
          connectionId == other.connectionId &&
          segmentIndex == other.segmentIndex;

  @override
  int get hashCode => Object.hash(connectionId, segmentIndex);

  @override
  String toString() =>
      'ConnectionSegmentItem($connectionId[$segmentIndex], bounds: $bounds)';
}

/// Spatial item for an annotation.
final class AnnotationSpatialItem extends SpatialItem {
  const AnnotationSpatialItem({
    required this.annotationId,
    required super.bounds,
  });

  final String annotationId;

  @override
  String get id => 'annot_$annotationId';

  @override
  String get referenceId => annotationId;

  @override
  AnnotationSpatialItem copyWithBounds(Rect newBounds) =>
      AnnotationSpatialItem(annotationId: annotationId, bounds: newBounds);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AnnotationSpatialItem &&
          runtimeType == other.runtimeType &&
          annotationId == other.annotationId;

  @override
  int get hashCode => annotationId.hashCode;

  @override
  String toString() => 'AnnotationSpatialItem($annotationId, bounds: $bounds)';
}

// ═══════════════════════════════════════════════════════════════════════════
// Factory Constructors
// ═══════════════════════════════════════════════════════════════════════════

/// Extension to provide factory-style constructors for spatial items.
extension SpatialItemFactories on SpatialItem {
  /// Creates a spatial item for a node.
  static NodeSpatialItem node({required String nodeId, required Rect bounds}) =>
      NodeSpatialItem(nodeId: nodeId, bounds: bounds);

  /// Creates a spatial item for a port.
  static PortSpatialItem port({
    required String portId,
    required String nodeId,
    required bool isOutput,
    required Rect bounds,
  }) => PortSpatialItem(
    portId: portId,
    nodeId: nodeId,
    isOutput: isOutput,
    bounds: bounds,
  );

  /// Creates a spatial item for a connection segment.
  static ConnectionSegmentItem connectionSegment({
    required String connectionId,
    required int segmentIndex,
    required Rect bounds,
  }) => ConnectionSegmentItem(
    connectionId: connectionId,
    segmentIndex: segmentIndex,
    bounds: bounds,
  );

  /// Creates a spatial item for an annotation.
  static AnnotationSpatialItem annotation({
    required String annotationId,
    required Rect bounds,
  }) => AnnotationSpatialItem(annotationId: annotationId, bounds: bounds);
}

// ═══════════════════════════════════════════════════════════════════════════
// TYPE CHECKING HELPERS
// ═══════════════════════════════════════════════════════════════════════════

/// Extension for convenient type checking.
extension SpatialItemTypeChecks on SpatialItem {
  bool get isNode => this is NodeSpatialItem;
  bool get isPort => this is PortSpatialItem;
  bool get isConnectionSegment => this is ConnectionSegmentItem;
  bool get isAnnotation => this is AnnotationSpatialItem;
}
