/// Factory functions for creating test objects in vyuh_node_flow tests.
///
/// These factories provide consistent, minimal test objects that can be
/// customized as needed for specific test scenarios.
library;

import 'package:flutter/material.dart';
import 'package:vyuh_node_flow/vyuh_node_flow.dart';

// =============================================================================
// Node Factories
// =============================================================================

/// Creates a test node with sensible defaults.
///
/// All parameters are optional and will use defaults if not provided.
/// The node uses String as its data type for simplicity.
Node<String> createTestNode({
  String? id,
  String type = 'test',
  Offset position = Offset.zero,
  Size? size,
  String data = 'test-data',
  List<Port>? inputPorts,
  List<Port>? outputPorts,
  int zIndex = 0,
  bool visible = true,
}) {
  return Node<String>(
    id: id ?? 'node-${_nodeCounter++}',
    type: type,
    position: position,
    size: size,
    data: data,
    inputPorts: inputPorts ?? [],
    outputPorts: outputPorts ?? [],
    initialZIndex: zIndex,
    visible: visible,
  );
}

int _nodeCounter = 1;

/// Creates a test node with a single input port on the left.
Node<String> createTestNodeWithInputPort({
  String? id,
  String? portId,
  Offset position = Offset.zero,
  bool visible = true,
}) {
  return createTestNode(
    id: id,
    position: position,
    inputPorts: [createTestPort(id: portId ?? 'input-1', type: PortType.input)],
    visible: visible,
  );
}

/// Creates a test node with a single output port on the right.
Node<String> createTestNodeWithOutputPort({
  String? id,
  String? portId,
  Offset position = Offset.zero,
  bool visible = true,
}) {
  return createTestNode(
    id: id,
    position: position,
    outputPorts: [
      createTestPort(id: portId ?? 'output-1', type: PortType.output),
    ],
    visible: visible,
  );
}

/// Creates a test node with both input and output ports.
Node<String> createTestNodeWithPorts({
  String? id,
  String inputPortId = 'input-1',
  String outputPortId = 'output-1',
  Offset position = Offset.zero,
}) {
  return createTestNode(
    id: id,
    position: position,
    inputPorts: [createTestPort(id: inputPortId, type: PortType.input)],
    outputPorts: [createTestPort(id: outputPortId, type: PortType.output)],
  );
}

// =============================================================================
// Port Factories
// =============================================================================

/// Creates a test port with sensible defaults.
Port createTestPort({
  String? id,
  String name = 'Test Port',
  PortType type = PortType.input,
  PortPosition? position,
  Offset offset = Offset.zero,
  bool multiConnections = false,
  int? maxConnections,
  bool isConnectable = true,
}) {
  // Infer position from type if not provided
  final portPosition =
      position ??
      (type == PortType.input ? PortPosition.left : PortPosition.right);

  return Port(
    id: id ?? 'port-${_portCounter++}',
    name: name,
    type: type,
    position: portPosition,
    offset: offset,
    multiConnections: multiConnections,
    maxConnections: maxConnections,
    isConnectable: isConnectable,
  );
}

int _portCounter = 1;

/// Creates a left input port.
Port createInputPort({String? id, Offset offset = Offset.zero}) {
  return createTestPort(
    id: id ?? 'input-${_portCounter++}',
    type: PortType.input,
    position: PortPosition.left,
    offset: offset,
  );
}

/// Creates a right output port.
Port createOutputPort({String? id, Offset offset = Offset.zero}) {
  return createTestPort(
    id: id ?? 'output-${_portCounter++}',
    type: PortType.output,
    position: PortPosition.right,
    offset: offset,
  );
}

// =============================================================================
// Connection Factories
// =============================================================================

/// Creates a test connection with sensible defaults.
Connection createTestConnection({
  String? id,
  required String sourceNodeId,
  String sourcePortId = 'output-1',
  required String targetNodeId,
  String targetPortId = 'input-1',
  bool animated = false,
  Map<String, dynamic>? data,
}) {
  return Connection(
    id: id ?? 'conn-${_connectionCounter++}',
    sourceNodeId: sourceNodeId,
    sourcePortId: sourcePortId,
    targetNodeId: targetNodeId,
    targetPortId: targetPortId,
    animated: animated,
    data: data,
  );
}

int _connectionCounter = 1;

// =============================================================================
// Controller Factory
// =============================================================================

/// Creates a test controller with optional initial nodes and connections.
///
/// The controller uses String as its data type for simplicity.
NodeFlowController<String> createTestController({
  List<Node<String>>? nodes,
  List<Connection>? connections,
  NodeFlowConfig? config,
}) {
  final controller = NodeFlowController<String>(config: config);

  if (nodes != null) {
    for (final node in nodes) {
      controller.addNode(node);
    }
  }

  if (connections != null) {
    for (final connection in connections) {
      controller.addConnection(connection);
    }
  }

  return controller;
}

/// Creates a test controller with two connected nodes.
///
/// Creates node-a with an output port and node-b with an input port,
/// connected together.
NodeFlowController<String> createConnectedNodesController() {
  final nodeA = createTestNodeWithOutputPort(
    id: 'node-a',
    portId: 'output-1',
    position: const Offset(0, 0),
  );
  final nodeB = createTestNodeWithInputPort(
    id: 'node-b',
    portId: 'input-1',
    position: const Offset(200, 0),
  );
  final connection = createTestConnection(
    sourceNodeId: 'node-a',
    sourcePortId: 'output-1',
    targetNodeId: 'node-b',
    targetPortId: 'input-1',
  );

  return createTestController(nodes: [nodeA, nodeB], connections: [connection]);
}

// =============================================================================
// Viewport Factory
// =============================================================================

/// Creates a test viewport with sensible defaults.
GraphViewport createTestViewport({
  double x = 0.0,
  double y = 0.0,
  double zoom = 1.0,
}) {
  return GraphViewport(x: x, y: y, zoom: zoom);
}

// =============================================================================
// Config Factory
// =============================================================================

/// Creates a test config with sensible defaults.
NodeFlowConfig createTestConfig({
  bool snapToGrid = false,
  double gridSize = 16.0,
  double portSnapDistance = 8.0,
  double minZoom = 0.1,
  double maxZoom = 4.0,
}) {
  return NodeFlowConfig(
    snapToGrid: snapToGrid,
    gridSize: gridSize,
    portSnapDistance: portSnapDistance,
    minZoom: minZoom,
    maxZoom: maxZoom,
  );
}

// =============================================================================
// Batch Factories
// =============================================================================

/// Creates a list of test nodes positioned in a row.
List<Node<String>> createNodeRow({
  int count = 3,
  double spacing = 200.0,
  double startX = 0.0,
  double y = 0.0,
}) {
  return List.generate(
    count,
    (i) => createTestNode(
      id: 'node-row-$i',
      position: Offset(startX + i * spacing, y),
    ),
  );
}

/// Creates a list of test nodes positioned in a grid.
List<Node<String>> createNodeGrid({
  int rows = 3,
  int cols = 3,
  double spacingX = 200.0,
  double spacingY = 150.0,
}) {
  final nodes = <Node<String>>[];
  for (var row = 0; row < rows; row++) {
    for (var col = 0; col < cols; col++) {
      nodes.add(
        createTestNode(
          id: 'node-$row-$col',
          position: Offset(col * spacingX, row * spacingY),
        ),
      );
    }
  }
  return nodes;
}

/// Creates a chain of connected nodes (A -> B -> C -> ...).
({List<Node<String>> nodes, List<Connection> connections}) createNodeChain({
  int count = 3,
  double spacing = 200.0,
}) {
  final nodes = <Node<String>>[];
  final connections = <Connection>[];

  for (var i = 0; i < count; i++) {
    final isFirst = i == 0;
    final isLast = i == count - 1;

    nodes.add(
      createTestNode(
        id: 'chain-$i',
        position: Offset(i * spacing, 0),
        inputPorts: isFirst ? [] : [createInputPort(id: 'input-$i')],
        outputPorts: isLast ? [] : [createOutputPort(id: 'output-$i')],
      ),
    );

    if (i > 0) {
      connections.add(
        createTestConnection(
          id: 'chain-conn-${i - 1}',
          sourceNodeId: 'chain-${i - 1}',
          sourcePortId: 'output-${i - 1}',
          targetNodeId: 'chain-$i',
          targetPortId: 'input-$i',
        ),
      );
    }
  }

  return (nodes: nodes, connections: connections);
}

// =============================================================================
// Annotation Factories
// =============================================================================

/// Creates a test sticky annotation with sensible defaults.
StickyAnnotation createTestStickyAnnotation({
  String? id,
  Offset position = Offset.zero,
  String text = 'Test note',
  double width = 200.0,
  double height = 100.0,
  Color color = Colors.yellow,
  int zIndex = 0,
  bool isVisible = true,
  bool isInteractive = true,
}) {
  return StickyAnnotation(
    id: id ?? 'sticky-${_annotationCounter++}',
    position: position,
    text: text,
    width: width,
    height: height,
    color: color,
    zIndex: zIndex,
    isVisible: isVisible,
    isInteractive: isInteractive,
  );
}

/// Creates a test group annotation with sensible defaults.
GroupAnnotation createTestGroupAnnotation({
  String? id,
  Offset position = Offset.zero,
  Size size = const Size(400, 300),
  String title = 'Test Group',
  Color color = Colors.blue,
  GroupBehavior behavior = GroupBehavior.bounds,
  Set<String>? nodeIds,
  EdgeInsets padding = GroupAnnotation.defaultPadding,
  int zIndex = -1,
  bool isVisible = true,
  bool isInteractive = true,
}) {
  return GroupAnnotation(
    id: id ?? 'group-${_annotationCounter++}',
    position: position,
    size: size,
    title: title,
    color: color,
    behavior: behavior,
    nodeIds: nodeIds,
    padding: padding,
    zIndex: zIndex,
    isVisible: isVisible,
    isInteractive: isInteractive,
  );
}

/// Creates a test marker annotation with sensible defaults.
MarkerAnnotation createTestMarkerAnnotation({
  String? id,
  Offset position = Offset.zero,
  MarkerType markerType = MarkerType.info,
  double markerSize = 24.0,
  Color color = Colors.red,
  String? tooltip,
  int zIndex = 0,
  bool isVisible = true,
  bool isInteractive = true,
}) {
  return MarkerAnnotation(
    id: id ?? 'marker-${_annotationCounter++}',
    position: position,
    markerType: markerType,
    markerSize: markerSize,
    color: color,
    tooltip: tooltip,
    zIndex: zIndex,
    isVisible: isVisible,
    isInteractive: isInteractive,
  );
}

int _annotationCounter = 1;

// =============================================================================
// Reset Counters
// =============================================================================

/// Resets all counters to ensure test isolation.
///
/// Call this in setUp() to ensure unique IDs across test runs.
void resetTestCounters() {
  _nodeCounter = 1;
  _portCounter = 1;
  _connectionCounter = 1;
  _annotationCounter = 1;
}
