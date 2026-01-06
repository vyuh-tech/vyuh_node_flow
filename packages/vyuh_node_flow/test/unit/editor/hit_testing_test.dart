/// Unit tests for the hit testing functionality in GraphSpatialIndex.
///
/// Tests cover:
/// - HitTestResult class construction and properties
/// - Hit testing for nodes, ports, connections
/// - Point hit testing with spatial index
/// - Area selection hit testing (nodesIn, nodesAt, connectionsAt)
/// - Z-order handling in hit tests
/// - Node render layer priority
/// - Edge cases and boundary conditions
/// - Port finding behavior
/// - Viewport coordinate transformations
@Tags(['unit'])
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vyuh_node_flow/vyuh_node_flow.dart';
import 'package:vyuh_node_flow/src/shared/spatial/graph_spatial_index.dart';

import '../../helpers/test_factories.dart';

void main() {
  setUp(() {
    resetTestCounters();
  });

  // ===========================================================================
  // HitTestResult Class Tests
  // ===========================================================================

  group('HitTestResult', () {
    group('Construction', () {
      test('creates default canvas hit result', () {
        const result = HitTestResult();

        expect(result.hitType, equals(HitTarget.canvas));
        expect(result.nodeId, isNull);
        expect(result.portId, isNull);
        expect(result.connectionId, isNull);
        expect(result.isOutput, isNull);
        expect(result.position, isNull);
      });

      test('creates node hit result with all properties', () {
        const result = HitTestResult(
          hitType: HitTarget.node,
          nodeId: 'test-node-1',
          position: Offset(100, 200),
        );

        expect(result.hitType, equals(HitTarget.node));
        expect(result.nodeId, equals('test-node-1'));
        expect(result.position, equals(const Offset(100, 200)));
        expect(result.portId, isNull);
        expect(result.connectionId, isNull);
      });

      test('creates port hit result with parent node', () {
        const result = HitTestResult(
          hitType: HitTarget.port,
          nodeId: 'parent-node',
          portId: 'output-port-1',
          isOutput: true,
          position: Offset(150, 100),
        );

        expect(result.hitType, equals(HitTarget.port));
        expect(result.nodeId, equals('parent-node'));
        expect(result.portId, equals('output-port-1'));
        expect(result.isOutput, isTrue);
        expect(result.position, equals(const Offset(150, 100)));
      });

      test('creates input port hit result', () {
        const result = HitTestResult(
          hitType: HitTarget.port,
          nodeId: 'parent-node',
          portId: 'input-port-1',
          isOutput: false,
        );

        expect(result.hitType, equals(HitTarget.port));
        expect(result.isOutput, isFalse);
      });

      test('creates connection hit result', () {
        const result = HitTestResult(
          hitType: HitTarget.connection,
          connectionId: 'conn-1',
          position: Offset(300, 150),
        );

        expect(result.hitType, equals(HitTarget.connection));
        expect(result.connectionId, equals('conn-1'));
        expect(result.nodeId, isNull);
        expect(result.portId, isNull);
      });
    });

    group('Convenience Getters', () {
      test('isNode returns true only for node hits', () {
        const nodeResult = HitTestResult(
          hitType: HitTarget.node,
          nodeId: 'node-1',
        );
        const portResult = HitTestResult(
          hitType: HitTarget.port,
          nodeId: 'node-1',
          portId: 'port-1',
        );
        const connectionResult = HitTestResult(
          hitType: HitTarget.connection,
          connectionId: 'conn-1',
        );
        const canvasResult = HitTestResult();

        expect(nodeResult.isNode, isTrue);
        expect(portResult.isNode, isFalse);
        expect(connectionResult.isNode, isFalse);
        expect(canvasResult.isNode, isFalse);
      });

      test('isPort returns true only for port hits', () {
        const nodeResult = HitTestResult(
          hitType: HitTarget.node,
          nodeId: 'node-1',
        );
        const portResult = HitTestResult(
          hitType: HitTarget.port,
          nodeId: 'node-1',
          portId: 'port-1',
        );
        const connectionResult = HitTestResult(
          hitType: HitTarget.connection,
          connectionId: 'conn-1',
        );
        const canvasResult = HitTestResult();

        expect(nodeResult.isPort, isFalse);
        expect(portResult.isPort, isTrue);
        expect(connectionResult.isPort, isFalse);
        expect(canvasResult.isPort, isFalse);
      });

      test('isConnection returns true only for connection hits', () {
        const nodeResult = HitTestResult(
          hitType: HitTarget.node,
          nodeId: 'node-1',
        );
        const portResult = HitTestResult(
          hitType: HitTarget.port,
          nodeId: 'node-1',
          portId: 'port-1',
        );
        const connectionResult = HitTestResult(
          hitType: HitTarget.connection,
          connectionId: 'conn-1',
        );
        const canvasResult = HitTestResult();

        expect(nodeResult.isConnection, isFalse);
        expect(portResult.isConnection, isFalse);
        expect(connectionResult.isConnection, isTrue);
        expect(canvasResult.isConnection, isFalse);
      });

      test('isCanvas returns true only for canvas hits', () {
        const nodeResult = HitTestResult(
          hitType: HitTarget.node,
          nodeId: 'node-1',
        );
        const portResult = HitTestResult(
          hitType: HitTarget.port,
          nodeId: 'node-1',
          portId: 'port-1',
        );
        const connectionResult = HitTestResult(
          hitType: HitTarget.connection,
          connectionId: 'conn-1',
        );
        const canvasResult = HitTestResult();

        expect(nodeResult.isCanvas, isFalse);
        expect(portResult.isCanvas, isFalse);
        expect(connectionResult.isCanvas, isFalse);
        expect(canvasResult.isCanvas, isTrue);
      });
    });

    group('Edge Cases', () {
      test('handles position with negative coordinates', () {
        const result = HitTestResult(
          hitType: HitTarget.node,
          nodeId: 'node-1',
          position: Offset(-100, -50),
        );

        expect(result.position!.dx, equals(-100));
        expect(result.position!.dy, equals(-50));
      });

      test('handles position with zero coordinates', () {
        const result = HitTestResult(
          hitType: HitTarget.node,
          nodeId: 'node-1',
          position: Offset.zero,
        );

        expect(result.position, equals(Offset.zero));
      });

      test('handles position with large coordinates', () {
        const result = HitTestResult(
          hitType: HitTarget.node,
          nodeId: 'node-1',
          position: Offset(10000, 10000),
        );

        expect(result.position!.dx, equals(10000));
        expect(result.position!.dy, equals(10000));
      });

      test('handles position with fractional coordinates', () {
        const result = HitTestResult(
          hitType: HitTarget.node,
          nodeId: 'node-1',
          position: Offset(100.5, 200.75),
        );

        expect(result.position!.dx, equals(100.5));
        expect(result.position!.dy, equals(200.75));
      });

      test('port hit with null isOutput is valid', () {
        const result = HitTestResult(
          hitType: HitTarget.port,
          nodeId: 'node-1',
          portId: 'port-1',
          isOutput: null,
        );

        expect(result.hitType, equals(HitTarget.port));
        expect(result.isOutput, isNull);
      });

      test('node hit without nodeId is valid but semantically incorrect', () {
        // This is technically valid but semantically incorrect
        const result = HitTestResult(hitType: HitTarget.node, nodeId: null);

        expect(result.hitType, equals(HitTarget.node));
        expect(result.nodeId, isNull);
        expect(result.isNode, isTrue);
      });
    });
  });

  // ===========================================================================
  // HitTarget Enum Tests
  // ===========================================================================

  group('HitTarget Enum', () {
    test('has all expected values', () {
      expect(HitTarget.values, hasLength(4));
      expect(HitTarget.values, contains(HitTarget.node));
      expect(HitTarget.values, contains(HitTarget.port));
      expect(HitTarget.values, contains(HitTarget.connection));
      expect(HitTarget.values, contains(HitTarget.canvas));
    });

    test('enum names match expected values', () {
      expect(HitTarget.node.name, equals('node'));
      expect(HitTarget.port.name, equals('port'));
      expect(HitTarget.connection.name, equals('connection'));
      expect(HitTarget.canvas.name, equals('canvas'));
    });

    test('enum index values are stable', () {
      expect(HitTarget.node.index, equals(0));
      expect(HitTarget.port.index, equals(1));
      expect(HitTarget.connection.index, equals(2));
      expect(HitTarget.canvas.index, equals(3));
    });
  });

  // ===========================================================================
  // GraphSpatialIndex Hit Testing Tests
  // ===========================================================================

  group('GraphSpatialIndex Hit Testing', () {
    late GraphSpatialIndex<String, dynamic> spatialIndex;

    setUp(() {
      spatialIndex = GraphSpatialIndex<String, dynamic>();
    });

    group('Node Hit Testing', () {
      test('hitTest returns canvas when empty', () {
        final result = spatialIndex.hitTest(const Offset(100, 100));

        expect(result.hitType, equals(HitTarget.canvas));
      });

      test('hitTest returns node when point is inside node bounds', () {
        final node = createTestNode(
          id: 'test-node',
          position: const Offset(100, 100),
          size: const Size(150, 100),
        );
        spatialIndex.update(node);

        // Test point inside node bounds
        final result = spatialIndex.hitTest(const Offset(150, 150));

        expect(result.hitType, equals(HitTarget.node));
        expect(result.nodeId, equals('test-node'));
      });

      test('hitTest returns canvas when point is outside node bounds', () {
        final node = createTestNode(
          id: 'test-node',
          position: const Offset(100, 100),
          size: const Size(150, 100),
        );
        spatialIndex.update(node);

        // Test point outside node bounds
        final result = spatialIndex.hitTest(const Offset(50, 50));

        expect(result.hitType, equals(HitTarget.canvas));
      });

      test('hitTest respects node visibility', () {
        final node = createTestNode(
          id: 'hidden-node',
          position: const Offset(100, 100),
          size: const Size(150, 100),
          visible: false,
        );
        spatialIndex.update(node);

        // Point inside hidden node bounds
        final result = spatialIndex.hitTest(const Offset(150, 150));

        expect(result.hitType, equals(HitTarget.canvas));
      });

      test('hitTest returns topmost node by zIndex', () {
        final bottomNode = createTestNode(
          id: 'bottom-node',
          position: const Offset(100, 100),
          size: const Size(150, 100),
          zIndex: 0,
        );
        final topNode = createTestNode(
          id: 'top-node',
          position: const Offset(120, 120),
          size: const Size(150, 100),
          zIndex: 1,
        );
        spatialIndex.update(bottomNode);
        spatialIndex.update(topNode);

        // Test point where both nodes overlap
        final result = spatialIndex.hitTest(const Offset(150, 150));

        expect(result.hitType, equals(HitTarget.node));
        expect(result.nodeId, equals('top-node'));
      });

      test('hitTest handles multiple overlapping nodes', () {
        final node1 = createTestNode(
          id: 'node-1',
          position: const Offset(100, 100),
          size: const Size(200, 200),
          zIndex: 0,
        );
        final node2 = createTestNode(
          id: 'node-2',
          position: const Offset(150, 150),
          size: const Size(100, 100),
          zIndex: 5,
        );
        final node3 = createTestNode(
          id: 'node-3',
          position: const Offset(175, 175),
          size: const Size(50, 50),
          zIndex: 3,
        );
        spatialIndex.update(node1);
        spatialIndex.update(node2);
        spatialIndex.update(node3);

        // Test point where all three overlap - should hit node2 (highest zIndex)
        final result = spatialIndex.hitTest(const Offset(190, 190));

        expect(result.hitType, equals(HitTarget.node));
        expect(result.nodeId, equals('node-2'));
      });

      test('hitTest at exact node boundary top-left', () {
        final node = createTestNode(
          id: 'boundary-test',
          position: const Offset(100, 100),
          size: const Size(100, 100),
        );
        spatialIndex.update(node);

        // Exactly at top-left corner
        final result = spatialIndex.hitTest(const Offset(100, 100));

        expect(result.hitType, equals(HitTarget.node));
        expect(result.nodeId, equals('boundary-test'));
      });

      test('hitTest just outside node boundary', () {
        final node = createTestNode(
          id: 'boundary-test',
          position: const Offset(100, 100),
          size: const Size(100, 100),
        );
        spatialIndex.update(node);

        // Just outside top-left corner
        final result = spatialIndex.hitTest(const Offset(99.9, 99.9));

        expect(result.hitType, equals(HitTarget.canvas));
      });

      test('hitTest handles nodes at negative positions', () {
        final node = createTestNode(
          id: 'negative-pos',
          position: const Offset(-100, -50),
          size: const Size(80, 60),
        );
        spatialIndex.update(node);

        // Inside the node at negative coordinates
        final result = spatialIndex.hitTest(const Offset(-60, -20));

        expect(result.hitType, equals(HitTarget.node));
        expect(result.nodeId, equals('negative-pos'));
      });

      test('hitTest handles node spanning origin', () {
        final node = createTestNode(
          id: 'origin-span',
          position: const Offset(-50, -50),
          size: const Size(100, 100),
        );
        spatialIndex.update(node);

        // At origin
        final atOrigin = spatialIndex.hitTest(Offset.zero);
        expect(atOrigin.hitType, equals(HitTarget.node));

        // In negative quadrant
        final negative = spatialIndex.hitTest(const Offset(-25, -25));
        expect(negative.hitType, equals(HitTarget.node));

        // In positive quadrant
        final positive = spatialIndex.hitTest(const Offset(25, 25));
        expect(positive.hitType, equals(HitTarget.node));
      });
    });

    group('Port Hit Testing', () {
      test('hitTestPort returns null when no ports exist', () {
        final result = spatialIndex.hitTestPort(const Offset(100, 100));

        expect(result, isNull);
      });

      test('hitTestPort returns port when point is within snap distance', () {
        final node = createTestNodeWithPorts(
          id: 'node-with-ports',
          position: const Offset(100, 100),
        );
        // Set the node size for proper port positioning
        node.setSize(const Size(150, 100));
        spatialIndex.update(node);

        // Get the port center from the node
        const portSize = Size.square(10);
        final portCenter = node.getPortCenter('output-1', portSize: portSize);

        // Test point at port center
        final result = spatialIndex.hitTestPort(portCenter);

        expect(result, isNotNull);
        expect(result!.hitType, equals(HitTarget.port));
        expect(result.nodeId, equals('node-with-ports'));
        expect(result.portId, equals('output-1'));
        expect(result.isOutput, isTrue);
      });

      test('hitTestPort returns null when point is far from port', () {
        final node = createTestNodeWithPorts(
          id: 'node-with-ports',
          position: const Offset(100, 100),
        );
        node.setSize(const Size(150, 100));
        spatialIndex.update(node);

        // Test point far from any port
        final result = spatialIndex.hitTestPort(const Offset(0, 0));

        expect(result, isNull);
      });

      test('hitTestPort respects node visibility', () {
        // Use createTestNode directly to set visible=false
        final node = createTestNode(
          id: 'hidden-node',
          position: const Offset(100, 100),
          inputPorts: [createTestPort(id: 'input-1', type: PortType.input)],
          outputPorts: [createTestPort(id: 'output-1', type: PortType.output)],
          visible: false,
        );
        node.setSize(const Size(150, 100));
        spatialIndex.update(node);

        const portSize = Size.square(10);
        final portCenter = node.getPortCenter('output-1', portSize: portSize);
        final result = spatialIndex.hitTestPort(portCenter);

        expect(result, isNull);
      });

      test('hitTestPort detects input port', () {
        final node = createTestNodeWithInputPort(
          id: 'input-node',
          portId: 'my-input',
          position: const Offset(100, 100),
        );
        node.setSize(const Size(100, 50));
        spatialIndex.update(node);

        const portSize = Size.square(10);
        final portCenter = node.getPortCenter('my-input', portSize: portSize);
        final result = spatialIndex.hitTestPort(portCenter);

        expect(result, isNotNull);
        expect(result!.portId, equals('my-input'));
        expect(result.isOutput, isFalse);
      });

      test('hitTestPort with custom snap distance', () {
        const customSnapDistance = 20.0;
        final customIndex = GraphSpatialIndex<String, dynamic>(
          portSnapDistance: customSnapDistance,
        );

        final node = createTestNodeWithPorts(
          id: 'snap-test',
          position: const Offset(100, 100),
        );
        node.setSize(const Size(150, 100));
        customIndex.update(node);

        const portSize = Size.square(10);
        final portCenter = node.getPortCenter('output-1', portSize: portSize);

        // Point 15 pixels away should be within 20px snap distance
        final nearbyPoint = portCenter + const Offset(15, 0);
        final result = customIndex.hitTestPort(nearbyPoint);

        expect(result, isNotNull);
        expect(result!.portId, equals('output-1'));
      });

      test('hitTestPort returns null when beyond snap distance', () {
        const snapDistance = 8.0;
        final index = GraphSpatialIndex<String, dynamic>(
          portSnapDistance: snapDistance,
        );

        final node = createTestNodeWithPorts(
          id: 'snap-test',
          position: const Offset(100, 100),
        );
        node.setSize(const Size(150, 100));
        index.update(node);

        const portSize = Size.square(10);
        final portCenter = node.getPortCenter('output-1', portSize: portSize);

        // Point 15 pixels away should be beyond 8px snap distance
        final farPoint = portCenter + const Offset(15, 0);
        final result = index.hitTestPort(farPoint);

        expect(result, isNull);
      });
    });

    group('nodesAt Query', () {
      test('nodesAt returns empty list when no nodes exist', () {
        final nodes = spatialIndex.nodesAt(const Offset(100, 100));

        expect(nodes, isEmpty);
      });

      test('nodesAt returns node at exact point', () {
        final node = createTestNode(
          id: 'test-node',
          position: const Offset(100, 100),
          size: const Size(150, 100),
        );
        spatialIndex.update(node);

        final nodes = spatialIndex.nodesAt(const Offset(150, 150));

        expect(nodes, hasLength(1));
        expect(nodes.first.id, equals('test-node'));
      });

      test('nodesAt returns multiple overlapping nodes', () {
        final node1 = createTestNode(
          id: 'node-1',
          position: const Offset(100, 100),
          size: const Size(200, 200),
        );
        final node2 = createTestNode(
          id: 'node-2',
          position: const Offset(150, 150),
          size: const Size(100, 100),
        );
        spatialIndex.update(node1);
        spatialIndex.update(node2);

        final nodes = spatialIndex.nodesAt(const Offset(175, 175));

        expect(nodes, hasLength(2));
        expect(nodes.map((n) => n.id), containsAll(['node-1', 'node-2']));
      });

      test('nodesAt with radius expands hit area', () {
        final node = createTestNode(
          id: 'test-node',
          position: const Offset(100, 100),
          size: const Size(50, 50),
        );
        spatialIndex.update(node);

        // Point just outside node bounds
        final nodesWithoutRadius = spatialIndex.nodesAt(const Offset(160, 125));
        final nodesWithRadius = spatialIndex.nodesAt(
          const Offset(160, 125),
          radius: 20,
        );

        expect(nodesWithoutRadius, isEmpty);
        expect(nodesWithRadius, hasLength(1));
      });

      test('nodesAt excludes hidden nodes', () {
        final visibleNode = createTestNode(
          id: 'visible',
          position: const Offset(100, 100),
          size: const Size(100, 100),
        );
        final hiddenNode = createTestNode(
          id: 'hidden',
          position: const Offset(100, 100),
          size: const Size(100, 100),
          visible: false,
        );
        spatialIndex.update(visibleNode);
        spatialIndex.update(hiddenNode);

        final nodes = spatialIndex.nodesAt(const Offset(150, 150));

        expect(nodes, hasLength(1));
        expect(nodes.first.id, equals('visible'));
      });

      test('nodesAt returns empty at point with no nodes', () {
        final node = createTestNode(
          id: 'far-away',
          position: const Offset(500, 500),
          size: const Size(50, 50),
        );
        spatialIndex.update(node);

        final nodes = spatialIndex.nodesAt(const Offset(100, 100));

        expect(nodes, isEmpty);
      });
    });

    group('nodesIn Query (Area Selection)', () {
      test('nodesIn returns empty list when no nodes exist', () {
        final nodes = spatialIndex.nodesIn(const Rect.fromLTWH(0, 0, 500, 500));

        expect(nodes, isEmpty);
      });

      test('nodesIn returns nodes within bounds', () {
        final node1 = createTestNode(
          id: 'inside',
          position: const Offset(100, 100),
          size: const Size(50, 50),
        );
        final node2 = createTestNode(
          id: 'outside',
          position: const Offset(600, 600),
          size: const Size(50, 50),
        );
        spatialIndex.update(node1);
        spatialIndex.update(node2);

        final nodes = spatialIndex.nodesIn(const Rect.fromLTWH(0, 0, 500, 500));

        expect(nodes, hasLength(1));
        expect(nodes.first.id, equals('inside'));
      });

      test('nodesIn includes partially overlapping nodes', () {
        final node = createTestNode(
          id: 'partial-overlap',
          position: const Offset(450, 450),
          size: const Size(100, 100),
        );
        spatialIndex.update(node);

        final nodes = spatialIndex.nodesIn(const Rect.fromLTWH(0, 0, 500, 500));

        expect(nodes, hasLength(1));
        expect(nodes.first.id, equals('partial-overlap'));
      });

      test('nodesIn returns all nodes for large bounds', () {
        final nodes = createNodeGrid(rows: 3, cols: 3);
        for (final node in nodes) {
          spatialIndex.update(node);
        }

        final result = spatialIndex.nodesIn(
          const Rect.fromLTWH(-1000, -1000, 3000, 3000),
        );

        expect(result, hasLength(9));
      });

      test('nodesIn excludes hidden nodes', () {
        final visibleNode = createTestNode(
          id: 'visible',
          position: const Offset(100, 100),
          size: const Size(50, 50),
        );
        final hiddenNode = createTestNode(
          id: 'hidden',
          position: const Offset(200, 200),
          size: const Size(50, 50),
          visible: false,
        );
        spatialIndex.update(visibleNode);
        spatialIndex.update(hiddenNode);

        final nodes = spatialIndex.nodesIn(const Rect.fromLTWH(0, 0, 500, 500));

        expect(nodes, hasLength(1));
        expect(nodes.first.id, equals('visible'));
      });

      test('nodesIn with zero-area bounds returns nodes at that point', () {
        final node = createTestNode(
          id: 'test-node',
          position: const Offset(100, 100),
          size: const Size(50, 50),
        );
        spatialIndex.update(node);

        // Zero-area rect at a point inside the node still intersects
        final nodesInside = spatialIndex.nodesIn(
          const Rect.fromLTWH(125, 125, 0, 0),
        );
        expect(nodesInside, hasLength(1));

        // Zero-area rect at a point outside the node doesn't intersect
        final nodesOutside = spatialIndex.nodesIn(
          const Rect.fromLTWH(200, 200, 0, 0),
        );
        expect(nodesOutside, isEmpty);
      });

      test('nodesIn with negative bounds', () {
        final node = createTestNode(
          id: 'negative-node',
          position: const Offset(-100, -100),
          size: const Size(50, 50),
        );
        spatialIndex.update(node);

        final nodes = spatialIndex.nodesIn(
          const Rect.fromLTWH(-200, -200, 200, 200),
        );

        expect(nodes, hasLength(1));
        expect(nodes.first.id, equals('negative-node'));
      });
    });

    group('Connection Hit Testing', () {
      test('connectionsAt returns empty list when no connections exist', () {
        final connections = spatialIndex.connectionsAt(const Offset(100, 100));

        expect(connections, isEmpty);
      });

      test('connectionsAt returns connections at point', () {
        // Create source and target nodes
        final sourceNode = createTestNodeWithOutputPort(
          id: 'source',
          position: const Offset(0, 0),
        );
        sourceNode.setSize(const Size(100, 50));
        final targetNode = createTestNodeWithInputPort(
          id: 'target',
          position: const Offset(300, 0),
        );
        targetNode.setSize(const Size(100, 50));

        spatialIndex.update(sourceNode);
        spatialIndex.update(targetNode);

        // Create connection
        final connection = createTestConnection(
          id: 'conn-1',
          sourceNodeId: 'source',
          targetNodeId: 'target',
        );

        // Add connection with segment bounds
        final segmentBounds = [const Rect.fromLTWH(100, 20, 200, 10)];
        spatialIndex.updateConnection(connection, segmentBounds);

        // Query at point within segment bounds
        final connections = spatialIndex.connectionsAt(const Offset(200, 25));

        expect(connections, hasLength(1));
        expect(connections.first.id, equals('conn-1'));
      });

      test('connectionsAt excludes connections with hidden source node', () {
        final sourceNode = createTestNodeWithOutputPort(
          id: 'source',
          position: const Offset(0, 0),
          visible: false,
        );
        sourceNode.setSize(const Size(100, 50));
        final targetNode = createTestNodeWithInputPort(
          id: 'target',
          position: const Offset(300, 0),
        );
        targetNode.setSize(const Size(100, 50));

        spatialIndex.update(sourceNode);
        spatialIndex.update(targetNode);

        final connection = createTestConnection(
          id: 'conn-1',
          sourceNodeId: 'source',
          targetNodeId: 'target',
        );

        final segmentBounds = [const Rect.fromLTWH(100, 20, 200, 10)];
        spatialIndex.updateConnection(connection, segmentBounds);

        final connections = spatialIndex.connectionsAt(const Offset(200, 25));

        expect(connections, isEmpty);
      });

      test('connectionsAt excludes connections with hidden target node', () {
        final sourceNode = createTestNodeWithOutputPort(
          id: 'source',
          position: const Offset(0, 0),
        );
        sourceNode.setSize(const Size(100, 50));
        final targetNode = createTestNodeWithInputPort(
          id: 'target',
          position: const Offset(300, 0),
          visible: false,
        );
        targetNode.setSize(const Size(100, 50));

        spatialIndex.update(sourceNode);
        spatialIndex.update(targetNode);

        final connection = createTestConnection(
          id: 'conn-1',
          sourceNodeId: 'source',
          targetNodeId: 'target',
        );

        final segmentBounds = [const Rect.fromLTWH(100, 20, 200, 10)];
        spatialIndex.updateConnection(connection, segmentBounds);

        final connections = spatialIndex.connectionsAt(const Offset(200, 25));

        expect(connections, isEmpty);
      });

      test('connectionsAt returns empty outside segment bounds', () {
        final sourceNode = createTestNodeWithOutputPort(id: 'source');
        final targetNode = createTestNodeWithInputPort(id: 'target');
        spatialIndex.update(sourceNode);
        spatialIndex.update(targetNode);

        final connection = createTestConnection(
          id: 'conn-1',
          sourceNodeId: 'source',
          targetNodeId: 'target',
        );

        spatialIndex.updateConnection(connection, [
          const Rect.fromLTWH(100, 20, 50, 10),
        ]);

        // Query outside segment bounds
        final connections = spatialIndex.connectionsAt(const Offset(200, 100));

        expect(connections, isEmpty);
      });
    });

    group('Connection Segment Management', () {
      test('updateConnection with multiple segments', () {
        final sourceNode = createTestNodeWithOutputPort(id: 'source');
        final targetNode = createTestNodeWithInputPort(id: 'target');
        spatialIndex.update(sourceNode);
        spatialIndex.update(targetNode);

        final connection = createTestConnection(
          id: 'conn-multi',
          sourceNodeId: 'source',
          targetNodeId: 'target',
        );

        // Multiple segment bounds for curved path
        final segmentBounds = [
          const Rect.fromLTWH(100, 20, 50, 10),
          const Rect.fromLTWH(150, 30, 50, 10),
          const Rect.fromLTWH(200, 25, 50, 10),
        ];
        spatialIndex.updateConnection(connection, segmentBounds);

        // Should find connection at each segment
        final atSeg1 = spatialIndex.connectionsAt(const Offset(125, 25));
        final atSeg2 = spatialIndex.connectionsAt(const Offset(175, 35));
        final atSeg3 = spatialIndex.connectionsAt(const Offset(225, 30));

        expect(atSeg1, hasLength(1));
        expect(atSeg2, hasLength(1));
        expect(atSeg3, hasLength(1));
      });

      test('removeConnection removes all segments', () {
        final sourceNode = createTestNodeWithOutputPort(id: 'source');
        final targetNode = createTestNodeWithInputPort(id: 'target');
        spatialIndex.update(sourceNode);
        spatialIndex.update(targetNode);

        final connection = createTestConnection(
          id: 'conn-remove',
          sourceNodeId: 'source',
          targetNodeId: 'target',
        );

        final segmentBounds = [
          const Rect.fromLTWH(100, 20, 50, 10),
          const Rect.fromLTWH(150, 30, 50, 10),
        ];
        spatialIndex.updateConnection(connection, segmentBounds);

        // Verify connection exists
        expect(spatialIndex.connectionsAt(const Offset(125, 25)), hasLength(1));

        // Remove connection
        spatialIndex.removeConnection('conn-remove');

        // Verify connection is gone
        expect(spatialIndex.connectionsAt(const Offset(125, 25)), isEmpty);
      });

      test('updateConnection replaces existing segments', () {
        final sourceNode = createTestNodeWithOutputPort(id: 'source');
        final targetNode = createTestNodeWithInputPort(id: 'target');
        spatialIndex.update(sourceNode);
        spatialIndex.update(targetNode);

        final connection = createTestConnection(
          id: 'conn-update',
          sourceNodeId: 'source',
          targetNodeId: 'target',
        );

        // Initial segments
        spatialIndex.updateConnection(connection, [
          const Rect.fromLTWH(100, 20, 50, 10),
        ]);

        expect(spatialIndex.connectionsAt(const Offset(125, 25)), hasLength(1));

        // Update with new segments at different location
        spatialIndex.updateConnection(connection, [
          const Rect.fromLTWH(300, 50, 50, 10),
        ]);

        // Old location should be empty
        expect(spatialIndex.connectionsAt(const Offset(125, 25)), isEmpty);

        // New location should have connection
        expect(spatialIndex.connectionsAt(const Offset(325, 55)), hasLength(1));
      });
    });

    group('Z-Order Handling', () {
      test('hitTest respects zIndex for overlapping nodes', () {
        // Create nodes with different z-indices at same position
        final lowZ = createTestNode(
          id: 'low-z',
          position: const Offset(100, 100),
          size: const Size(100, 100),
          zIndex: 1,
        );
        final midZ = createTestNode(
          id: 'mid-z',
          position: const Offset(100, 100),
          size: const Size(100, 100),
          zIndex: 5,
        );
        final highZ = createTestNode(
          id: 'high-z',
          position: const Offset(100, 100),
          size: const Size(100, 100),
          zIndex: 10,
        );

        // Add in reverse order to test sorting
        spatialIndex.update(highZ);
        spatialIndex.update(lowZ);
        spatialIndex.update(midZ);

        final result = spatialIndex.hitTest(const Offset(150, 150));

        expect(result.hitType, equals(HitTarget.node));
        expect(result.nodeId, equals('high-z'));
      });

      test('hitTest handles equal zIndex nodes', () {
        final node1 = createTestNode(
          id: 'node-1',
          position: const Offset(100, 100),
          size: const Size(100, 100),
          zIndex: 5,
        );
        final node2 = createTestNode(
          id: 'node-2',
          position: const Offset(100, 100),
          size: const Size(100, 100),
          zIndex: 5,
        );

        spatialIndex.update(node1);
        spatialIndex.update(node2);

        final result = spatialIndex.hitTest(const Offset(150, 150));

        // Should hit one of them (order depends on render order provider)
        expect(result.hitType, equals(HitTarget.node));
        expect(result.nodeId, anyOf(equals('node-1'), equals('node-2')));
      });

      test('hitTest handles negative zIndex', () {
        final negativeZ = createTestNode(
          id: 'negative-z',
          position: const Offset(100, 100),
          size: const Size(100, 100),
          zIndex: -10,
        );
        final zeroZ = createTestNode(
          id: 'zero-z',
          position: const Offset(100, 100),
          size: const Size(100, 100),
          zIndex: 0,
        );

        spatialIndex.update(negativeZ);
        spatialIndex.update(zeroZ);

        final result = spatialIndex.hitTest(const Offset(150, 150));

        expect(result.hitType, equals(HitTarget.node));
        expect(result.nodeId, equals('zero-z'));
      });

      test('zIndex update changes hit order', () {
        final node1 = createTestNode(
          id: 'node-1',
          position: const Offset(100, 100),
          size: const Size(100, 100),
          zIndex: 10,
        );
        final node2 = createTestNode(
          id: 'node-2',
          position: const Offset(100, 100),
          size: const Size(100, 100),
          zIndex: 5,
        );

        spatialIndex.update(node1);
        spatialIndex.update(node2);

        // Initially node1 is on top
        expect(
          spatialIndex.hitTest(const Offset(150, 150)).nodeId,
          equals('node-1'),
        );

        // Update node2 to have higher zIndex
        node2.zIndex.value = 20;
        spatialIndex.update(node2);

        // Now node2 should be on top
        expect(
          spatialIndex.hitTest(const Offset(150, 150)).nodeId,
          equals('node-2'),
        );
      });
    });

    group('Special Node Types', () {
      test('CommentNode hits in foreground layer', () {
        final regularNode = createTestNode(
          id: 'regular',
          position: const Offset(100, 100),
          size: const Size(150, 100),
          zIndex: 100, // High zIndex
        );
        final commentNode = createTestCommentNode<String>(
          id: 'comment',
          position: const Offset(100, 100),
          width: 150,
          height: 100,
          data: 'test',
          zIndex: 0, // Low zIndex but foreground layer
        );

        spatialIndex.update(regularNode);
        spatialIndex.update(commentNode);

        final result = spatialIndex.hitTest(const Offset(150, 150));

        // CommentNode should be hit first due to foreground layer
        expect(result.hitType, equals(HitTarget.node));
        expect(result.nodeId, equals('comment'));
      });

      test('GroupNode hits in background layer', () {
        final groupNode = createTestGroupNode<String>(
          id: 'group',
          position: const Offset(50, 50),
          size: const Size(300, 300),
          data: 'test',
          zIndex: 100, // High zIndex but background layer
        );
        final regularNode = createTestNode(
          id: 'regular',
          position: const Offset(100, 100),
          size: const Size(100, 100),
          zIndex: 0, // Low zIndex but middle layer
        );

        spatialIndex.update(groupNode);
        spatialIndex.update(regularNode);

        // Test point where both overlap
        final result = spatialIndex.hitTest(const Offset(150, 150));

        // Regular node should be hit first due to middle layer priority
        expect(result.hitType, equals(HitTarget.node));
        expect(result.nodeId, equals('regular'));
      });

      test('GroupNode can be hit when no regular nodes overlap', () {
        final groupNode = createTestGroupNode<String>(
          id: 'group',
          position: const Offset(50, 50),
          size: const Size(300, 300),
          data: 'test',
        );
        final regularNode = createTestNode(
          id: 'regular',
          position: const Offset(500, 500),
          size: const Size(100, 100),
        );

        spatialIndex.update(groupNode);
        spatialIndex.update(regularNode);

        // Test point inside group but not regular node
        final result = spatialIndex.hitTest(const Offset(100, 100));

        expect(result.hitType, equals(HitTarget.node));
        expect(result.nodeId, equals('group'));
      });

      test('layer priority: foreground > middle > background', () {
        final groupNode = createTestGroupNode<String>(
          id: 'group',
          position: const Offset(100, 100),
          size: const Size(200, 200),
          data: 'test',
          zIndex: 100,
        );
        final regularNode = createTestNode(
          id: 'regular',
          position: const Offset(100, 100),
          size: const Size(200, 200),
          zIndex: 50,
        );
        final commentNode = createTestCommentNode<String>(
          id: 'comment',
          position: const Offset(100, 100),
          width: 200,
          height: 200,
          data: 'test',
          zIndex: 0,
        );

        spatialIndex.update(groupNode);
        spatialIndex.update(regularNode);
        spatialIndex.update(commentNode);

        final result = spatialIndex.hitTest(const Offset(200, 200));

        // CommentNode wins due to foreground layer
        expect(result.nodeId, equals('comment'));
      });
    });

    group('Statistics', () {
      test('nodeCount tracks added nodes', () {
        expect(spatialIndex.nodeCount, equals(0));

        spatialIndex.update(createTestNode(id: 'node-1'));
        expect(spatialIndex.nodeCount, equals(1));

        spatialIndex.update(createTestNode(id: 'node-2'));
        expect(spatialIndex.nodeCount, equals(2));
      });

      test('connectionCount tracks added connections', () {
        expect(spatialIndex.connectionCount, equals(0));

        final sourceNode = createTestNodeWithOutputPort(id: 'source');
        final targetNode = createTestNodeWithInputPort(id: 'target');
        spatialIndex.update(sourceNode);
        spatialIndex.update(targetNode);

        final connection = createTestConnection(
          sourceNodeId: 'source',
          targetNodeId: 'target',
        );
        spatialIndex.updateConnection(connection, [
          const Rect.fromLTWH(0, 0, 100, 10),
        ]);

        expect(spatialIndex.connectionCount, equals(1));
      });

      test('portCount tracks ports from nodes', () {
        expect(spatialIndex.portCount, equals(0));

        final nodeWithPorts = createTestNodeWithPorts(id: 'node-with-ports');
        nodeWithPorts.setSize(const Size(100, 50));
        spatialIndex.update(nodeWithPorts);

        // Node has one input and one output port
        expect(spatialIndex.portCount, equals(2));
      });

      test('clear resets all counts', () {
        spatialIndex.update(createTestNode(id: 'node'));
        final sourceNode = createTestNodeWithOutputPort(id: 'source');
        final targetNode = createTestNodeWithInputPort(id: 'target');
        spatialIndex.update(sourceNode);
        spatialIndex.update(targetNode);
        spatialIndex.updateConnection(
          createTestConnection(sourceNodeId: 'source', targetNodeId: 'target'),
          [const Rect.fromLTWH(0, 0, 100, 10)],
        );

        spatialIndex.clear();

        expect(spatialIndex.nodeCount, equals(0));
        expect(spatialIndex.connectionCount, equals(0));
        expect(spatialIndex.portCount, equals(0));
      });

      test('removeNode decrements nodeCount', () {
        spatialIndex.update(createTestNode(id: 'node-1'));
        spatialIndex.update(createTestNode(id: 'node-2'));
        expect(spatialIndex.nodeCount, equals(2));

        spatialIndex.removeNode('node-1');
        expect(spatialIndex.nodeCount, equals(1));

        spatialIndex.removeNode('node-2');
        expect(spatialIndex.nodeCount, equals(0));
      });
    });

    group('Retrieval Methods', () {
      test('getNode returns node by ID', () {
        final node = createTestNode(id: 'find-me');
        spatialIndex.update(node);

        final found = spatialIndex.getNode('find-me');

        expect(found, isNotNull);
        expect(found!.id, equals('find-me'));
      });

      test('getNode returns null for non-existent ID', () {
        final found = spatialIndex.getNode('not-found');

        expect(found, isNull);
      });

      test('getConnection returns connection by ID', () {
        final sourceNode = createTestNodeWithOutputPort(id: 'source');
        final targetNode = createTestNodeWithInputPort(id: 'target');
        spatialIndex.update(sourceNode);
        spatialIndex.update(targetNode);

        final connection = createTestConnection(
          id: 'find-conn',
          sourceNodeId: 'source',
          targetNodeId: 'target',
        );
        spatialIndex.updateConnection(connection, [
          const Rect.fromLTWH(0, 0, 100, 10),
        ]);

        final found = spatialIndex.getConnection('find-conn');

        expect(found, isNotNull);
        expect(found!.id, equals('find-conn'));
      });

      test('getConnection returns null for non-existent ID', () {
        final found = spatialIndex.getConnection('not-found');

        expect(found, isNull);
      });

      test('getNode after update returns updated node', () {
        final node = createTestNode(
          id: 'update-test',
          position: const Offset(0, 0),
        );
        spatialIndex.update(node);

        node.position.value = const Offset(100, 100);
        spatialIndex.update(node);

        final found = spatialIndex.getNode('update-test');
        expect(found!.position.value, equals(const Offset(100, 100)));
      });
    });

    group('Batch Operations', () {
      test('batch operation defers index updates', () {
        final nodes = createNodeRow(count: 5);

        spatialIndex.batch(() {
          for (final node in nodes) {
            spatialIndex.update(node);
          }
        });

        expect(spatialIndex.nodeCount, equals(5));
      });

      test('rebuild rebuilds entire index', () {
        // Add initial data
        spatialIndex.update(createTestNode(id: 'old-node'));

        // Rebuild with new data
        final newNodes = [
          createTestNode(id: 'new-node-1'),
          createTestNode(id: 'new-node-2'),
        ];

        spatialIndex.rebuild(
          nodes: newNodes,
          connections: [],
          connectionSegmentCalculator: (conn) => [],
        );

        expect(spatialIndex.nodeCount, equals(2));
        expect(spatialIndex.getNode('old-node'), isNull);
        expect(spatialIndex.getNode('new-node-1'), isNotNull);
        expect(spatialIndex.getNode('new-node-2'), isNotNull);
      });

      test('batch within batch works correctly', () {
        spatialIndex.batch(() {
          spatialIndex.update(createTestNode(id: 'outer-1'));
          spatialIndex.batch(() {
            spatialIndex.update(createTestNode(id: 'inner-1'));
            spatialIndex.update(createTestNode(id: 'inner-2'));
          });
          spatialIndex.update(createTestNode(id: 'outer-2'));
        });

        expect(spatialIndex.nodeCount, equals(4));
      });
    });

    group('Version Tracking', () {
      test('version increments on node update', () {
        final initialVersion = spatialIndex.version.value;

        spatialIndex.update(createTestNode());

        expect(spatialIndex.version.value, greaterThan(initialVersion));
      });

      test('version increments on node removal', () {
        final node = createTestNode(id: 'to-remove');
        spatialIndex.update(node);
        final versionAfterAdd = spatialIndex.version.value;

        spatialIndex.removeNode('to-remove');

        expect(spatialIndex.version.value, greaterThan(versionAfterAdd));
      });

      test('version increments on connection update', () {
        final sourceNode = createTestNodeWithOutputPort(id: 'source');
        final targetNode = createTestNodeWithInputPort(id: 'target');
        spatialIndex.update(sourceNode);
        spatialIndex.update(targetNode);
        final versionAfterNodes = spatialIndex.version.value;

        spatialIndex.updateConnection(
          createTestConnection(sourceNodeId: 'source', targetNodeId: 'target'),
          [const Rect.fromLTWH(0, 0, 100, 10)],
        );

        expect(spatialIndex.version.value, greaterThan(versionAfterNodes));
      });

      test('version increments on clear', () {
        spatialIndex.update(createTestNode());
        final versionBeforeClear = spatialIndex.version.value;

        spatialIndex.clear();

        expect(spatialIndex.version.value, greaterThan(versionBeforeClear));
      });

      test('version increments on connection removal', () {
        final sourceNode = createTestNodeWithOutputPort(id: 'source');
        final targetNode = createTestNodeWithInputPort(id: 'target');
        spatialIndex.update(sourceNode);
        spatialIndex.update(targetNode);
        spatialIndex.updateConnection(
          createTestConnection(
            id: 'conn',
            sourceNodeId: 'source',
            targetNodeId: 'target',
          ),
          [const Rect.fromLTWH(0, 0, 100, 10)],
        );
        final versionAfterConn = spatialIndex.version.value;

        spatialIndex.removeConnection('conn');

        expect(spatialIndex.version.value, greaterThan(versionAfterConn));
      });
    });

    group('Edge Cases', () {
      test('handles very small node', () {
        final tinyNode = createTestNode(
          id: 'tiny',
          position: const Offset(100, 100),
          size: const Size(1, 1),
        );
        spatialIndex.update(tinyNode);

        final result = spatialIndex.hitTest(const Offset(100.5, 100.5));

        expect(result.hitType, equals(HitTarget.node));
        expect(result.nodeId, equals('tiny'));
      });

      test('handles very large node', () {
        final hugeNode = createTestNode(
          id: 'huge',
          position: const Offset(-5000, -5000),
          size: const Size(10000, 10000),
        );
        spatialIndex.update(hugeNode);

        expect(spatialIndex.hitTest(Offset.zero).nodeId, equals('huge'));
        expect(
          spatialIndex.hitTest(const Offset(4999, 4999)).nodeId,
          equals('huge'),
        );
        expect(
          spatialIndex.hitTest(const Offset(-4999, -4999)).nodeId,
          equals('huge'),
        );
      });

      test('handles node at extreme coordinates', () {
        final extremeNode = createTestNode(
          id: 'extreme',
          position: const Offset(1000000, 1000000),
          size: const Size(100, 100),
        );
        spatialIndex.update(extremeNode);

        final result = spatialIndex.hitTest(const Offset(1000050, 1000050));

        expect(result.hitType, equals(HitTarget.node));
        expect(result.nodeId, equals('extreme'));
      });

      test('handles many overlapping nodes performance', () {
        // Create 100 overlapping nodes with increasing z-index
        for (var i = 0; i < 100; i++) {
          final node = createTestNode(
            id: 'overlap-$i',
            position: const Offset(100, 100),
            size: const Size(100, 100),
            zIndex: i,
          );
          spatialIndex.update(node);
        }

        // Should hit the one with highest z-index
        final result = spatialIndex.hitTest(const Offset(150, 150));

        expect(result.nodeId, equals('overlap-99'));
      });

      test('handles zero-size node', () {
        final zeroNode = createTestNode(
          id: 'zero-size',
          position: const Offset(100, 100),
          size: Size.zero,
        );
        spatialIndex.update(zeroNode);

        // Zero-size node should not be hit
        final result = spatialIndex.hitTest(const Offset(100, 100));

        expect(result.hitType, equals(HitTarget.canvas));
      });

      test('handles node with only width', () {
        final lineNode = createTestNode(
          id: 'line',
          position: const Offset(100, 100),
          size: const Size(100, 0),
        );
        spatialIndex.update(lineNode);

        // Zero-height node should not be hit
        final result = spatialIndex.hitTest(const Offset(150, 100));

        expect(result.hitType, equals(HitTarget.canvas));
      });

      test('handles rapid sequential updates', () {
        final node = createTestNode(
          id: 'rapid',
          position: const Offset(0, 0),
          size: const Size(100, 100),
        );
        spatialIndex.update(node);

        // Rapid position updates
        for (var i = 0; i < 100; i++) {
          node.position.value = Offset(i.toDouble(), i.toDouble());
          spatialIndex.update(node);
        }

        // Final position should be at (99, 99)
        final result = spatialIndex.hitTest(const Offset(150, 150));
        expect(result.hitType, equals(HitTarget.node));
        expect(result.nodeId, equals('rapid'));
      });
    });
  });

  // ===========================================================================
  // SpatialQueries Interface Tests
  // ===========================================================================

  group('SpatialQueries Interface via Controller', () {
    test('controller exposes spatialIndex', () {
      final controller = createTestController();

      expect(controller.spatialIndex, isNotNull);
      expect(controller.spatialIndex, isA<SpatialQueries<String, dynamic>>());
    });

    test('spatialIndex can be accessed through controller', () {
      // Note: The controller's spatial index requires initialization
      // before nodes are indexed. This test verifies the interface exists.
      final controller = createTestController();

      // Direct access to spatial index is available
      expect(controller.spatialIndex, isNotNull);

      // Statistics methods are available
      expect(controller.spatialIndex.nodeCount, isA<int>());
      expect(controller.spatialIndex.connectionCount, isA<int>());
      expect(controller.spatialIndex.portCount, isA<int>());
    });

    test('version observable is accessible through controller', () {
      final controller = createTestController();

      // Version observable is available for reactivity
      expect(controller.spatialIndex.version, isNotNull);
      expect(controller.spatialIndex.version.value, isA<int>());
    });
  });

  // ===========================================================================
  // Hit Testing Priority Order Tests
  // ===========================================================================

  group('Hit Testing Priority Order', () {
    late GraphSpatialIndex<String, dynamic> spatialIndex;

    setUp(() {
      spatialIndex = GraphSpatialIndex<String, dynamic>();
    });

    test('port has priority over node body', () {
      final node = createTestNodeWithPorts(
        id: 'port-priority',
        position: const Offset(100, 100),
      );
      node.setSize(const Size(150, 100));
      spatialIndex.update(node);

      const portSize = Size.square(10);
      final portCenter = node.getPortCenter('output-1', portSize: portSize);

      // hitTest at port location should return port, not node body
      final result = spatialIndex.hitTest(portCenter);

      expect(result.hitType, equals(HitTarget.port));
      expect(result.portId, equals('output-1'));
    });

    test('node has priority over connection', () {
      final sourceNode = createTestNodeWithOutputPort(
        id: 'source',
        position: const Offset(0, 0),
      );
      sourceNode.setSize(const Size(100, 50));
      final targetNode = createTestNodeWithInputPort(
        id: 'target',
        position: const Offset(200, 0),
      );
      targetNode.setSize(const Size(100, 50));

      // Create a node that overlaps with connection path
      final overlappingNode = createTestNode(
        id: 'overlapping',
        position: const Offset(100, 10),
        size: const Size(50, 30),
      );

      spatialIndex.update(sourceNode);
      spatialIndex.update(targetNode);
      spatialIndex.update(overlappingNode);

      // Add connection that passes through overlappingNode's area
      final connection = createTestConnection(
        id: 'conn',
        sourceNodeId: 'source',
        targetNodeId: 'target',
      );
      spatialIndex.updateConnection(connection, [
        const Rect.fromLTWH(100, 15, 50, 20),
      ]);

      // Hit test in overlap area - node should win
      final result = spatialIndex.hitTest(const Offset(125, 25));

      expect(result.hitType, equals(HitTarget.node));
      expect(result.nodeId, equals('overlapping'));
    });

    test('connection is hit when no node overlaps', () {
      final sourceNode = createTestNodeWithOutputPort(id: 'source');
      final targetNode = createTestNodeWithInputPort(id: 'target');
      spatialIndex.update(sourceNode);
      spatialIndex.update(targetNode);

      // Set up connection hit tester
      spatialIndex.connectionHitTester = (connection, point) {
        return const Rect.fromLTWH(100, 100, 100, 20).contains(point);
      };

      final connection = createTestConnection(
        id: 'conn',
        sourceNodeId: 'source',
        targetNodeId: 'target',
      );
      spatialIndex.updateConnection(connection, [
        const Rect.fromLTWH(100, 100, 100, 20),
      ]);

      // Hit test on connection (not on any node)
      final result = spatialIndex.hitTest(const Offset(150, 110));

      expect(result.hitType, equals(HitTarget.connection));
      expect(result.connectionId, equals('conn'));
    });
  });

  // ===========================================================================
  // Viewport Coordinate Transformation Tests
  // ===========================================================================

  group('Viewport Coordinate Transformations', () {
    test('viewport converts screen to graph coordinates at 1x zoom', () {
      const viewport = GraphViewport(x: 0, y: 0, zoom: 1.0);

      final screenPos = ScreenPosition.fromXY(100, 200);
      final graphPos = viewport.toGraph(screenPos);

      expect(graphPos.dx, equals(100));
      expect(graphPos.dy, equals(200));
    });

    test('viewport converts screen to graph with pan offset', () {
      const viewport = GraphViewport(x: 100, y: 50, zoom: 1.0);

      final screenPos = ScreenPosition.fromXY(200, 150);
      final graphPos = viewport.toGraph(screenPos);

      expect(graphPos.dx, equals(100));
      expect(graphPos.dy, equals(100));
    });

    test('viewport converts screen to graph with zoom', () {
      const viewport = GraphViewport(x: 0, y: 0, zoom: 2.0);

      final screenPos = ScreenPosition.fromXY(200, 100);
      final graphPos = viewport.toGraph(screenPos);

      expect(graphPos.dx, equals(100));
      expect(graphPos.dy, equals(50));
    });

    test('viewport converts screen to graph with pan and zoom combined', () {
      const viewport = GraphViewport(x: 100, y: 50, zoom: 2.0);

      final screenPos = ScreenPosition.fromXY(300, 150);
      final graphPos = viewport.toGraph(screenPos);

      expect(graphPos.dx, equals(100));
      expect(graphPos.dy, equals(50));
    });

    test('viewport converts graph to screen coordinates', () {
      const viewport = GraphViewport(x: 0, y: 0, zoom: 1.0);

      final graphPos = GraphPosition(const Offset(100, 200));
      final screenPos = viewport.toScreen(graphPos);

      expect(screenPos.offset.dx, equals(100));
      expect(screenPos.offset.dy, equals(200));
    });

    test('viewport converts graph to screen with zoom', () {
      const viewport = GraphViewport(x: 0, y: 0, zoom: 2.0);

      final graphPos = GraphPosition(const Offset(100, 200));
      final screenPos = viewport.toScreen(graphPos);

      expect(screenPos.offset.dx, equals(200));
      expect(screenPos.offset.dy, equals(400));
    });

    test('coordinate conversion is reversible', () {
      const viewport = GraphViewport(x: 100, y: 50, zoom: 1.5);

      final originalScreen = ScreenPosition.fromXY(300, 400);
      final graphPos = viewport.toGraph(originalScreen);
      final backToScreen = viewport.toScreen(graphPos);

      expect(backToScreen.offset.dx, closeTo(originalScreen.offset.dx, 0.001));
      expect(backToScreen.offset.dy, closeTo(originalScreen.offset.dy, 0.001));
    });

    test('hit testing uses graph coordinates after viewport transform', () {
      final spatialIndex = GraphSpatialIndex<String, dynamic>();

      final node = createTestNode(
        id: 'graph-pos',
        position: const Offset(100, 100),
        size: const Size(100, 100),
      );
      spatialIndex.update(node);

      const viewport = GraphViewport(x: 50, y: 50, zoom: 1.0);

      // Screen position (200, 200) -> graph (150, 150) which is inside node
      final screenPos = ScreenPosition.fromXY(200, 200);
      final graphPos = viewport.toGraph(screenPos);

      final result = spatialIndex.hitTest(graphPos.offset);

      expect(result.hitType, equals(HitTarget.node));
      expect(result.nodeId, equals('graph-pos'));
    });

    test('zoomed out viewport affects hit testing', () {
      final spatialIndex = GraphSpatialIndex<String, dynamic>();

      final node = createTestNode(
        id: 'zoom-test',
        position: Offset.zero,
        size: const Size(50, 50),
      );
      spatialIndex.update(node);

      // Zoomed out (zoom 0.5 means graph appears half size)
      const viewport = GraphViewport(x: 0, y: 0, zoom: 0.5);

      // Screen (50, 50) -> graph (100, 100) which is outside node
      final screenPos = ScreenPosition.fromXY(50, 50);
      final graphPos = viewport.toGraph(screenPos);

      final result = spatialIndex.hitTest(graphPos.offset);

      expect(result.hitType, equals(HitTarget.canvas));
    });
  });

  // ===========================================================================
  // Port Finding Behavior Tests
  // ===========================================================================

  group('Port Finding Behavior', () {
    late GraphSpatialIndex<String, dynamic> spatialIndex;

    setUp(() {
      spatialIndex = GraphSpatialIndex<String, dynamic>();
    });

    test('finds input port by id', () {
      final node = createTestNode(
        id: 'multi-port',
        position: const Offset(100, 100),
        inputPorts: [
          createTestPort(id: 'in-1', type: PortType.input),
          createTestPort(id: 'in-2', type: PortType.input),
        ],
        outputPorts: [],
      );
      node.setSize(const Size(100, 80));
      spatialIndex.update(node);

      const portSize = Size.square(10);
      final port1Center = node.getPortCenter('in-1', portSize: portSize);
      final result = spatialIndex.hitTestPort(port1Center);

      expect(result, isNotNull);
      expect(result!.portId, equals('in-1'));
    });

    test('finds output port by id', () {
      final node = createTestNode(
        id: 'multi-port',
        position: const Offset(100, 100),
        inputPorts: [],
        outputPorts: [createTestPort(id: 'out-1', type: PortType.output)],
      );
      node.setSize(const Size(100, 80));
      spatialIndex.update(node);

      const portSize = Size.square(10);
      final portCenter = node.getPortCenter('out-1', portSize: portSize);
      final result = spatialIndex.hitTestPort(portCenter);

      expect(result, isNotNull);
      expect(result!.portId, equals('out-1'));
      expect(result.isOutput, isTrue);
    });

    test('finds correct port from mixed input and output', () {
      final node = createTestNodeWithPorts(
        id: 'mixed-ports',
        position: const Offset(100, 100),
      );
      node.setSize(const Size(100, 50));
      spatialIndex.update(node);

      const portSize = Size.square(10);

      // Check input port
      final inputCenter = node.getPortCenter('input-1', portSize: portSize);
      final inputResult = spatialIndex.hitTestPort(inputCenter);
      expect(inputResult!.portId, equals('input-1'));
      expect(inputResult.isOutput, isFalse);

      // Check output port
      final outputCenter = node.getPortCenter('output-1', portSize: portSize);
      final outputResult = spatialIndex.hitTestPort(outputCenter);
      expect(outputResult!.portId, equals('output-1'));
      expect(outputResult.isOutput, isTrue);
    });

    test('throws for non-existent port id', () {
      final node = createTestNodeWithPorts(
        id: 'test-node',
        position: const Offset(100, 100),
      );
      node.setSize(const Size(100, 50));
      spatialIndex.update(node);

      // getPortCenter throws an ArgumentError for non-existent ports
      expect(
        () =>
            node.getPortCenter('non-existent', portSize: const Size.square(10)),
        throwsArgumentError,
      );
    });
  });

  // ===========================================================================
  // Connection Hit Tester Callback Tests
  // ===========================================================================

  group('Connection Hit Tester Callback', () {
    late GraphSpatialIndex<String, dynamic> spatialIndex;

    setUp(() {
      spatialIndex = GraphSpatialIndex<String, dynamic>();
    });

    test('connectionHitTester is called for connection hit testing', () {
      final sourceNode = createTestNodeWithOutputPort(id: 'source');
      final targetNode = createTestNodeWithInputPort(id: 'target');
      spatialIndex.update(sourceNode);
      spatialIndex.update(targetNode);

      var hitTesterCalled = false;
      Connection? hitTestedConnection;
      Offset? hitTestedPoint;

      spatialIndex.connectionHitTester = (connection, point) {
        hitTesterCalled = true;
        hitTestedConnection = connection;
        hitTestedPoint = point;
        return true;
      };

      final connection = createTestConnection(
        id: 'test-conn',
        sourceNodeId: 'source',
        targetNodeId: 'target',
      );
      spatialIndex.updateConnection(connection, [
        const Rect.fromLTWH(100, 100, 100, 20),
      ]);

      spatialIndex.hitTest(const Offset(150, 110));

      expect(hitTesterCalled, isTrue);
      expect(hitTestedConnection!.id, equals('test-conn'));
      expect(hitTestedPoint, equals(const Offset(150, 110)));
    });

    test('connectionHitTester returning false skips connection', () {
      final sourceNode = createTestNodeWithOutputPort(id: 'source');
      final targetNode = createTestNodeWithInputPort(id: 'target');
      spatialIndex.update(sourceNode);
      spatialIndex.update(targetNode);

      spatialIndex.connectionHitTester = (connection, point) => false;

      final connection = createTestConnection(
        id: 'test-conn',
        sourceNodeId: 'source',
        targetNodeId: 'target',
      );
      spatialIndex.updateConnection(connection, [
        const Rect.fromLTWH(100, 100, 100, 20),
      ]);

      final result = spatialIndex.hitTest(const Offset(150, 110));

      // Should return canvas since hit tester returned false
      expect(result.hitType, equals(HitTarget.canvas));
    });

    test('connectionHitTester is not called when no segment overlaps', () {
      final sourceNode = createTestNodeWithOutputPort(id: 'source');
      final targetNode = createTestNodeWithInputPort(id: 'target');
      spatialIndex.update(sourceNode);
      spatialIndex.update(targetNode);

      var hitTesterCalled = false;
      spatialIndex.connectionHitTester = (connection, point) {
        hitTesterCalled = true;
        return true;
      };

      final connection = createTestConnection(
        id: 'test-conn',
        sourceNodeId: 'source',
        targetNodeId: 'target',
      );
      spatialIndex.updateConnection(connection, [
        const Rect.fromLTWH(100, 100, 100, 20),
      ]);

      // Query at point far from any segment
      spatialIndex.hitTest(const Offset(500, 500));

      // Hit tester should not be called since no segment overlaps
      expect(hitTesterCalled, isFalse);
    });
  });
}
