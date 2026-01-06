/// Unit tests for the [GraphSpatialIndex] class.
///
/// Tests cover:
/// - GraphSpatialIndex construction and configuration
/// - Node indexing and queries (update, remove, nodesAt, nodesIn)
/// - Port indexing and queries
/// - Connection indexing with segments
/// - Rebuilding indexes (rebuildFromNodes, rebuildConnections, rebuild)
/// - Querying nodes/ports in viewport bounds
/// - Batch operations
/// - Hit testing
/// - Statistics and version tracking
@Tags(['unit'])
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vyuh_node_flow/src/connections/connection.dart';
import 'package:vyuh_node_flow/src/nodes/node.dart';
import 'package:vyuh_node_flow/src/shared/spatial/graph_spatial_index.dart';
import 'package:vyuh_node_flow/src/shared/spatial/spatial_item.dart';

import '../../helpers/test_factories.dart';

void main() {
  setUp(() {
    resetTestCounters();
  });

  group('GraphSpatialIndex Construction', () {
    test('creates with default grid size', () {
      final index = GraphSpatialIndex<String, dynamic>();

      expect(index.gridSize, equals(500.0));
      expect(index.portSnapDistance, equals(8.0));
      expect(index.nodeCount, equals(0));
      expect(index.connectionCount, equals(0));
      expect(index.portCount, equals(0));
    });

    test('creates with custom grid size', () {
      final index = GraphSpatialIndex<String, dynamic>(gridSize: 250.0);

      expect(index.gridSize, equals(250.0));
    });

    test('creates with custom port snap distance', () {
      final index = GraphSpatialIndex<String, dynamic>(portSnapDistance: 16.0);

      expect(index.portSnapDistance, equals(16.0));
    });

    test('creates with both custom grid size and port snap distance', () {
      final index = GraphSpatialIndex<String, dynamic>(
        gridSize: 100.0,
        portSnapDistance: 12.0,
      );

      expect(index.gridSize, equals(100.0));
      expect(index.portSnapDistance, equals(12.0));
    });

    test('version starts at 0', () {
      final index = GraphSpatialIndex<String, dynamic>();

      expect(index.version.value, equals(0));
    });
  });

  group('Node Indexing', () {
    late GraphSpatialIndex<String, dynamic> index;

    setUp(() {
      index = GraphSpatialIndex<String, dynamic>();
    });

    test('update adds a node to the index', () {
      final node = createTestNode(
        id: 'node-1',
        position: const Offset(100, 100),
      );

      index.update(node);

      expect(index.nodeCount, equals(1));
      expect(index.getNode('node-1'), equals(node));
    });

    test('update increments version', () {
      final node = createTestNode(id: 'node-1');
      final initialVersion = index.version.value;

      index.update(node);

      expect(index.version.value, greaterThan(initialVersion));
    });

    test('update replaces existing node with same ID', () {
      final node1 = createTestNode(
        id: 'node-1',
        position: const Offset(100, 100),
      );
      final node2 = createTestNode(
        id: 'node-1',
        position: const Offset(200, 200),
      );

      index.update(node1);
      index.update(node2);

      expect(index.nodeCount, equals(1));
      expect(index.getNode('node-1'), equals(node2));
    });

    test('update multiple nodes maintains correct count', () {
      final node1 = createTestNode(id: 'node-1');
      final node2 = createTestNode(id: 'node-2');
      final node3 = createTestNode(id: 'node-3');

      index.update(node1);
      index.update(node2);
      index.update(node3);

      expect(index.nodeCount, equals(3));
    });

    test('remove removes node from index', () {
      final node = createTestNode(id: 'node-1');

      index.update(node);
      index.remove(node);

      expect(index.nodeCount, equals(0));
      expect(index.getNode('node-1'), isNull);
    });

    test('remove increments version', () {
      final node = createTestNode(id: 'node-1');
      index.update(node);
      final versionAfterUpdate = index.version.value;

      index.remove(node);

      expect(index.version.value, greaterThan(versionAfterUpdate));
    });

    test('removeNode removes by ID', () {
      final node = createTestNode(id: 'node-1');

      index.update(node);
      index.removeNode('node-1');

      expect(index.nodeCount, equals(0));
      expect(index.getNode('node-1'), isNull);
    });

    test('removeNode does nothing for non-existent ID', () {
      final node = createTestNode(id: 'node-1');
      index.update(node);
      final versionBefore = index.version.value;

      index.removeNode('non-existent');

      expect(index.nodeCount, equals(1));
      expect(index.version.value, equals(versionBefore));
    });

    test('clear removes all nodes', () {
      index.update(createTestNode(id: 'node-1'));
      index.update(createTestNode(id: 'node-2'));
      index.update(createTestNode(id: 'node-3'));

      index.clear();

      expect(index.nodeCount, equals(0));
      expect(index.connectionCount, equals(0));
    });

    test('clear increments version', () {
      index.update(createTestNode(id: 'node-1'));
      final versionBefore = index.version.value;

      index.clear();

      expect(index.version.value, greaterThan(versionBefore));
    });
  });

  group('Node Queries', () {
    late GraphSpatialIndex<String, dynamic> index;

    setUp(() {
      index = GraphSpatialIndex<String, dynamic>();
    });

    test('getNode returns node by ID', () {
      final node = createTestNode(id: 'node-1');
      index.update(node);

      expect(index.getNode('node-1'), equals(node));
    });

    test('getNode returns null for non-existent ID', () {
      expect(index.getNode('non-existent'), isNull);
    });

    test('nodesAt returns nodes containing the point', () {
      final node = createTestNode(
        id: 'node-1',
        position: const Offset(100, 100),
        size: const Size(100, 100),
      );
      index.update(node);

      final result = index.nodesAt(const Offset(150, 150));

      expect(result.length, equals(1));
      expect(result.first, equals(node));
    });

    test('nodesAt returns empty list for point outside all nodes', () {
      final node = createTestNode(
        id: 'node-1',
        position: const Offset(100, 100),
        size: const Size(100, 100),
      );
      index.update(node);

      final result = index.nodesAt(const Offset(0, 0));

      expect(result, isEmpty);
    });

    test('nodesAt uses radius for expanded hit area', () {
      final node = createTestNode(
        id: 'node-1',
        position: const Offset(100, 100),
        size: const Size(100, 100),
      );
      index.update(node);

      // Point is just outside the node but within radius
      final result = index.nodesAt(const Offset(95, 150), radius: 10);

      expect(result.length, equals(1));
    });

    test('nodesAt excludes hidden nodes', () {
      final node = createTestNode(
        id: 'node-1',
        position: const Offset(100, 100),
        visible: false,
      );
      index.update(node);

      final result = index.nodesAt(const Offset(150, 150));

      expect(result, isEmpty);
    });

    test('nodesIn returns nodes within bounds', () {
      final node1 = createTestNode(
        id: 'node-1',
        position: const Offset(100, 100),
        size: const Size(100, 100),
      );
      final node2 = createTestNode(
        id: 'node-2',
        position: const Offset(300, 300),
        size: const Size(100, 100),
      );
      index.update(node1);
      index.update(node2);

      final result = index.nodesIn(const Rect.fromLTWH(50, 50, 200, 200));

      expect(result.length, equals(1));
      expect(result.first.id, equals('node-1'));
    });

    test('nodesIn returns all overlapping nodes', () {
      final node1 = createTestNode(
        id: 'node-1',
        position: const Offset(100, 100),
        size: const Size(100, 100),
      );
      final node2 = createTestNode(
        id: 'node-2',
        position: const Offset(150, 150),
        size: const Size(100, 100),
      );
      index.update(node1);
      index.update(node2);

      final result = index.nodesIn(const Rect.fromLTWH(0, 0, 500, 500));

      expect(result.length, equals(2));
    });

    test('nodesIn returns empty list when no nodes in bounds', () {
      final node = createTestNode(
        id: 'node-1',
        position: const Offset(500, 500),
      );
      index.update(node);

      final result = index.nodesIn(const Rect.fromLTWH(0, 0, 100, 100));

      expect(result, isEmpty);
    });

    test('nodesIn excludes hidden nodes', () {
      final node = createTestNode(
        id: 'node-1',
        position: const Offset(100, 100),
        visible: false,
      );
      index.update(node);

      final result = index.nodesIn(const Rect.fromLTWH(0, 0, 500, 500));

      expect(result, isEmpty);
    });
  });

  group('Port Indexing', () {
    late GraphSpatialIndex<String, dynamic> index;

    setUp(() {
      index = GraphSpatialIndex<String, dynamic>();
    });

    test('update adds port spatial items for node with ports', () {
      final node = createTestNodeWithPorts(id: 'node-1');
      index.update(node);

      expect(index.portCount, equals(2)); // input + output
    });

    test('port items are removed when node is removed', () {
      final node = createTestNodeWithPorts(id: 'node-1');
      index.update(node);

      index.remove(node);

      expect(index.portCount, equals(0));
    });

    test('port items are updated when node position changes', () {
      final node = createTestNodeWithPorts(
        id: 'node-1',
        position: const Offset(100, 100),
      );
      index.update(node);

      final portItemsBefore = index.portItems.toList();
      expect(portItemsBefore.length, equals(2));

      // Move the node
      node.position.value = const Offset(200, 200);
      index.update(node);

      final portItemsAfter = index.portItems.toList();
      expect(portItemsAfter.length, equals(2));
    });

    test('node without ports has zero port count', () {
      final node = createTestNode(id: 'node-1');
      index.update(node);

      expect(index.portCount, equals(0));
    });

    test('port spatial items contain correct metadata', () {
      final node = createTestNodeWithPorts(
        id: 'node-1',
        inputPortId: 'in-port',
        outputPortId: 'out-port',
      );
      index.update(node);

      final portItems = index.portItems.toList();
      expect(portItems.length, equals(2));

      final inputItem = portItems.firstWhere((p) => p.portId == 'in-port');
      expect(inputItem.nodeId, equals('node-1'));
      expect(inputItem.isOutput, isFalse);

      final outputItem = portItems.firstWhere((p) => p.portId == 'out-port');
      expect(outputItem.nodeId, equals('node-1'));
      expect(outputItem.isOutput, isTrue);
    });
  });

  group('Connection Indexing', () {
    late GraphSpatialIndex<String, dynamic> index;

    setUp(() {
      index = GraphSpatialIndex<String, dynamic>();
    });

    test('updateConnection adds connection to index', () {
      final connection = createTestConnection(
        id: 'conn-1',
        sourceNodeId: 'node-1',
        targetNodeId: 'node-2',
      );
      final segmentBounds = [const Rect.fromLTWH(100, 100, 200, 50)];

      index.updateConnection(connection, segmentBounds);

      expect(index.connectionCount, equals(1));
      expect(index.getConnection('conn-1'), equals(connection));
    });

    test('updateConnection increments version', () {
      final connection = createTestConnection(
        id: 'conn-1',
        sourceNodeId: 'node-1',
        targetNodeId: 'node-2',
      );
      final initialVersion = index.version.value;

      index.updateConnection(connection, [const Rect.fromLTWH(0, 0, 100, 50)]);

      expect(index.version.value, greaterThan(initialVersion));
    });

    test('updateConnection with multiple segments', () {
      final connection = createTestConnection(
        id: 'conn-1',
        sourceNodeId: 'node-1',
        targetNodeId: 'node-2',
      );
      final segmentBounds = [
        const Rect.fromLTWH(100, 100, 50, 50),
        const Rect.fromLTWH(150, 100, 50, 50),
        const Rect.fromLTWH(200, 100, 50, 50),
      ];

      index.updateConnection(connection, segmentBounds);

      expect(index.connectionCount, equals(1));
      expect(index.connectionSegmentItems.length, equals(3));
    });

    test('updateConnection with empty segments', () {
      final connection = createTestConnection(
        id: 'conn-1',
        sourceNodeId: 'node-1',
        targetNodeId: 'node-2',
      );

      index.updateConnection(connection, []);

      expect(index.connectionCount, equals(1));
      expect(index.connectionSegmentItems, isEmpty);
    });

    test('updateConnection replaces existing connection segments', () {
      final connection = createTestConnection(
        id: 'conn-1',
        sourceNodeId: 'node-1',
        targetNodeId: 'node-2',
      );

      index.updateConnection(connection, [
        const Rect.fromLTWH(0, 0, 50, 50),
        const Rect.fromLTWH(50, 0, 50, 50),
      ]);
      expect(index.connectionSegmentItems.length, equals(2));

      index.updateConnection(connection, [const Rect.fromLTWH(0, 0, 100, 50)]);
      expect(index.connectionSegmentItems.length, equals(1));
    });

    test('removeConnection removes connection from index', () {
      final connection = createTestConnection(
        id: 'conn-1',
        sourceNodeId: 'node-1',
        targetNodeId: 'node-2',
      );
      index.updateConnection(connection, [const Rect.fromLTWH(0, 0, 100, 50)]);

      index.removeConnection('conn-1');

      expect(index.connectionCount, equals(0));
      expect(index.getConnection('conn-1'), isNull);
      expect(index.connectionSegmentItems, isEmpty);
    });

    test('removeConnection increments version', () {
      final connection = createTestConnection(
        id: 'conn-1',
        sourceNodeId: 'node-1',
        targetNodeId: 'node-2',
      );
      index.updateConnection(connection, [const Rect.fromLTWH(0, 0, 100, 50)]);
      final versionBefore = index.version.value;

      index.removeConnection('conn-1');

      expect(index.version.value, greaterThan(versionBefore));
    });

    test('getConnection returns connection by ID', () {
      final connection = createTestConnection(
        id: 'conn-1',
        sourceNodeId: 'node-1',
        targetNodeId: 'node-2',
      );
      index.updateConnection(connection, [const Rect.fromLTWH(0, 0, 100, 50)]);

      expect(index.getConnection('conn-1'), equals(connection));
    });

    test('getConnection returns null for non-existent ID', () {
      expect(index.getConnection('non-existent'), isNull);
    });
  });

  group('Connection Queries', () {
    late GraphSpatialIndex<String, dynamic> index;

    setUp(() {
      index = GraphSpatialIndex<String, dynamic>();
    });

    test('connectionsAt returns connections at point', () {
      final nodeA = createTestNodeWithOutputPort(
        id: 'node-a',
        position: const Offset(0, 0),
      );
      final nodeB = createTestNodeWithInputPort(
        id: 'node-b',
        position: const Offset(200, 0),
      );
      final connection = createTestConnection(
        id: 'conn-1',
        sourceNodeId: 'node-a',
        targetNodeId: 'node-b',
      );

      index.update(nodeA);
      index.update(nodeB);
      index.updateConnection(connection, [
        const Rect.fromLTWH(50, 40, 150, 20),
      ]);

      final result = index.connectionsAt(const Offset(100, 50));

      expect(result.length, equals(1));
      expect(result.first.id, equals('conn-1'));
    });

    test('connectionsAt excludes connections with hidden nodes', () {
      final nodeA = createTestNodeWithOutputPort(
        id: 'node-a',
        position: const Offset(0, 0),
        visible: false,
      );
      final nodeB = createTestNodeWithInputPort(
        id: 'node-b',
        position: const Offset(200, 0),
      );
      final connection = createTestConnection(
        id: 'conn-1',
        sourceNodeId: 'node-a',
        targetNodeId: 'node-b',
      );

      index.update(nodeA);
      index.update(nodeB);
      index.updateConnection(connection, [
        const Rect.fromLTWH(50, 40, 150, 20),
      ]);

      final result = index.connectionsAt(const Offset(100, 50));

      expect(result, isEmpty);
    });

    test('connectionsIn returns connections in bounds', () {
      final nodeA = createTestNodeWithOutputPort(
        id: 'node-a',
        position: const Offset(0, 0),
      );
      final nodeB = createTestNodeWithInputPort(
        id: 'node-b',
        position: const Offset(200, 0),
      );
      final connection = createTestConnection(
        id: 'conn-1',
        sourceNodeId: 'node-a',
        targetNodeId: 'node-b',
      );

      index.update(nodeA);
      index.update(nodeB);
      index.updateConnection(connection, [
        const Rect.fromLTWH(50, 40, 150, 20),
      ]);

      final result = index.connectionsIn(const Rect.fromLTWH(0, 0, 300, 100));

      expect(result.length, equals(1));
      expect(result.first.id, equals('conn-1'));
    });

    test('connectionsIn excludes connections with hidden target node', () {
      final nodeA = createTestNodeWithOutputPort(
        id: 'node-a',
        position: const Offset(0, 0),
      );
      final nodeB = createTestNodeWithInputPort(
        id: 'node-b',
        position: const Offset(200, 0),
        visible: false,
      );
      final connection = createTestConnection(
        id: 'conn-1',
        sourceNodeId: 'node-a',
        targetNodeId: 'node-b',
      );

      index.update(nodeA);
      index.update(nodeB);
      index.updateConnection(connection, [
        const Rect.fromLTWH(50, 40, 150, 20),
      ]);

      final result = index.connectionsIn(const Rect.fromLTWH(0, 0, 300, 100));

      expect(result, isEmpty);
    });
  });

  group('Rebuild Operations', () {
    late GraphSpatialIndex<String, dynamic> index;

    setUp(() {
      index = GraphSpatialIndex<String, dynamic>();
    });

    test('rebuildFromNodes clears and rebuilds node index', () {
      index.update(createTestNode(id: 'old-node'));

      final newNodes = [
        createTestNode(id: 'new-1'),
        createTestNode(id: 'new-2'),
      ];

      index.rebuildFromNodes(newNodes);

      expect(index.nodeCount, equals(2));
      expect(index.getNode('old-node'), isNull);
      expect(index.getNode('new-1'), isNotNull);
      expect(index.getNode('new-2'), isNotNull);
    });

    test('rebuildFromNodes updates ports', () {
      final nodeWithPorts = createTestNodeWithPorts(id: 'node-with-ports');

      index.rebuildFromNodes([nodeWithPorts]);

      expect(index.portCount, equals(2));
    });

    test('rebuildConnections clears and rebuilds connection index', () {
      final node1 = createTestNodeWithOutputPort(id: 'node-1');
      final node2 = createTestNodeWithInputPort(id: 'node-2');
      index.update(node1);
      index.update(node2);

      final oldConnection = createTestConnection(
        id: 'old-conn',
        sourceNodeId: 'node-1',
        targetNodeId: 'node-2',
      );
      index.updateConnection(oldConnection, [
        const Rect.fromLTWH(0, 0, 100, 50),
      ]);

      final newConnections = [
        createTestConnection(
          id: 'new-conn',
          sourceNodeId: 'node-1',
          targetNodeId: 'node-2',
        ),
      ];

      index.rebuildConnections(
        newConnections,
        (conn) => const Rect.fromLTWH(0, 0, 150, 50),
      );

      expect(index.connectionCount, equals(1));
      expect(index.getConnection('old-conn'), isNull);
      expect(index.getConnection('new-conn'), isNotNull);
    });

    test('rebuildConnectionsWithSegments uses segment calculator', () {
      final node1 = createTestNodeWithOutputPort(id: 'node-1');
      final node2 = createTestNodeWithInputPort(id: 'node-2');
      index.update(node1);
      index.update(node2);

      final connections = [
        createTestConnection(
          id: 'conn-1',
          sourceNodeId: 'node-1',
          targetNodeId: 'node-2',
        ),
      ];

      index.rebuildConnectionsWithSegments(connections, (conn) {
        return [
          const Rect.fromLTWH(0, 0, 50, 50),
          const Rect.fromLTWH(50, 0, 50, 50),
        ];
      });

      expect(index.connectionSegmentItems.length, equals(2));
    });

    test('rebuild clears everything and rebuilds from scratch', () {
      index.update(createTestNode(id: 'old-node'));

      final node1 = createTestNodeWithOutputPort(id: 'node-1');
      final node2 = createTestNodeWithInputPort(id: 'node-2');
      final connection = createTestConnection(
        id: 'conn-1',
        sourceNodeId: 'node-1',
        targetNodeId: 'node-2',
      );

      index.rebuild(
        nodes: [node1, node2],
        connections: [connection],
        connectionSegmentCalculator: (conn) => [
          const Rect.fromLTWH(0, 0, 100, 50),
        ],
      );

      expect(index.nodeCount, equals(2));
      expect(index.connectionCount, equals(1));
      expect(index.getNode('old-node'), isNull);
    });
  });

  group('Batch Operations', () {
    late GraphSpatialIndex<String, dynamic> index;

    setUp(() {
      index = GraphSpatialIndex<String, dynamic>();
    });

    test('batch defers notifications until complete', () {
      var notificationCount = 0;
      index.version.observe((_) => notificationCount++);

      index.batch(() {
        index.update(createTestNode(id: 'node-1'));
        index.update(createTestNode(id: 'node-2'));
        index.update(createTestNode(id: 'node-3'));
      });

      // Should have one notification at the end of batch, not three
      expect(notificationCount, equals(1));
    });

    test('batch processes all operations', () {
      index.batch(() {
        index.update(createTestNode(id: 'node-1'));
        index.update(createTestNode(id: 'node-2'));
        index.update(createTestNode(id: 'node-3'));
      });

      expect(index.nodeCount, equals(3));
    });

    test('batch can include mixed operations', () {
      final node1 = createTestNodeWithOutputPort(id: 'node-1');
      final node2 = createTestNodeWithInputPort(id: 'node-2');

      index.batch(() {
        index.update(node1);
        index.update(node2);
        index.updateConnection(
          createTestConnection(
            id: 'conn-1',
            sourceNodeId: 'node-1',
            targetNodeId: 'node-2',
          ),
          [const Rect.fromLTWH(0, 0, 100, 50)],
        );
      });

      expect(index.nodeCount, equals(2));
      expect(index.connectionCount, equals(1));
    });
  });

  group('Hit Testing', () {
    late GraphSpatialIndex<String, dynamic> index;

    setUp(() {
      index = GraphSpatialIndex<String, dynamic>();
    });

    test('hitTest returns canvas for empty index', () {
      final result = index.hitTest(const Offset(100, 100));

      expect(result.hitType, equals(HitTarget.canvas));
      expect(result.isCanvas, isTrue);
    });

    test('hitTest returns node when point is inside node', () {
      final node = createTestNode(
        id: 'node-1',
        position: const Offset(100, 100),
        size: const Size(100, 100),
      );
      index.update(node);

      final result = index.hitTest(const Offset(150, 150));

      expect(result.hitType, equals(HitTarget.node));
      expect(result.nodeId, equals('node-1'));
      expect(result.isNode, isTrue);
    });

    test('hitTest returns canvas when point is outside all nodes', () {
      final node = createTestNode(
        id: 'node-1',
        position: const Offset(100, 100),
        size: const Size(100, 100),
      );
      index.update(node);

      final result = index.hitTest(const Offset(0, 0));

      expect(result.hitType, equals(HitTarget.canvas));
    });

    test('hitTest prioritizes higher zIndex nodes', () {
      final node1 = createTestNode(
        id: 'node-1',
        position: const Offset(100, 100),
        size: const Size(100, 100),
        zIndex: 0,
      );
      final node2 = createTestNode(
        id: 'node-2',
        position: const Offset(120, 120),
        size: const Size(100, 100),
        zIndex: 1,
      );
      index.update(node1);
      index.update(node2);

      // Point is inside both nodes
      final result = index.hitTest(const Offset(150, 150));

      expect(result.nodeId, equals('node-2'));
    });

    test('hitTest skips hidden nodes', () {
      final node = createTestNode(
        id: 'node-1',
        position: const Offset(100, 100),
        size: const Size(100, 100),
        visible: false,
      );
      index.update(node);

      final result = index.hitTest(const Offset(150, 150));

      expect(result.hitType, equals(HitTarget.canvas));
    });

    test('hitTestPort returns port hit result', () {
      final node = createTestNodeWithPorts(
        id: 'node-1',
        inputPortId: 'input-1',
        outputPortId: 'output-1',
        position: const Offset(100, 100),
      );
      index.update(node);

      // Find a port item and get its center for accurate hit testing
      final portItems = index.portItems.toList();
      expect(portItems.isNotEmpty, isTrue);

      final portItem = portItems.first;
      final portCenter = portItem.bounds.center;

      final result = index.hitTestPort(portCenter);

      expect(result, isNotNull);
      expect(result!.hitType, equals(HitTarget.port));
      expect(result.isPort, isTrue);
    });

    test('hitTestPort returns null when no port at point', () {
      final node = createTestNode(
        id: 'node-1',
        position: const Offset(100, 100),
      );
      index.update(node);

      final result = index.hitTestPort(const Offset(0, 0));

      expect(result, isNull);
    });
  });

  group('Statistics', () {
    late GraphSpatialIndex<String, dynamic> index;

    setUp(() {
      index = GraphSpatialIndex<String, dynamic>();
    });

    test('stats returns grid statistics', () {
      index.update(createTestNode(id: 'node-1'));

      final stats = index.stats;

      expect(stats.objectCount, equals(1));
    });

    test('nodeCount reflects current state', () {
      expect(index.nodeCount, equals(0));

      index.update(createTestNode(id: 'node-1'));
      expect(index.nodeCount, equals(1));

      index.update(createTestNode(id: 'node-2'));
      expect(index.nodeCount, equals(2));

      index.removeNode('node-1');
      expect(index.nodeCount, equals(1));
    });

    test('connectionCount reflects current state', () {
      expect(index.connectionCount, equals(0));

      index.updateConnection(
        createTestConnection(
          id: 'conn-1',
          sourceNodeId: 'node-1',
          targetNodeId: 'node-2',
        ),
        [const Rect.fromLTWH(0, 0, 100, 50)],
      );
      expect(index.connectionCount, equals(1));

      index.removeConnection('conn-1');
      expect(index.connectionCount, equals(0));
    });

    test('portCount reflects current state', () {
      expect(index.portCount, equals(0));

      final nodeWithPorts = createTestNodeWithPorts(id: 'node-1');
      index.update(nodeWithPorts);
      expect(index.portCount, equals(2));

      index.removeNode('node-1');
      expect(index.portCount, equals(0));
    });

    test('nodeItems returns all node spatial items', () {
      index.update(createTestNode(id: 'node-1'));
      index.update(createTestNode(id: 'node-2'));

      final nodeItems = index.nodeItems.toList();

      expect(nodeItems.length, equals(2));
      expect(nodeItems.every((item) => item is NodeSpatialItem), isTrue);
    });

    test('portItems returns all port spatial items', () {
      index.update(createTestNodeWithPorts(id: 'node-1'));

      final portItems = index.portItems.toList();

      expect(portItems.length, equals(2));
      expect(portItems.every((item) => item is PortSpatialItem), isTrue);
    });

    test('connectionSegmentItems returns all segment items', () {
      index.updateConnection(
        createTestConnection(
          id: 'conn-1',
          sourceNodeId: 'node-1',
          targetNodeId: 'node-2',
        ),
        [const Rect.fromLTWH(0, 0, 50, 50), const Rect.fromLTWH(50, 0, 50, 50)],
      );

      final segmentItems = index.connectionSegmentItems.toList();

      expect(segmentItems.length, equals(2));
      expect(
        segmentItems.every((item) => item is ConnectionSegmentItem),
        isTrue,
      );
    });
  });

  group('Version Tracking', () {
    late GraphSpatialIndex<String, dynamic> index;

    setUp(() {
      index = GraphSpatialIndex<String, dynamic>();
    });

    test('version increments on update', () {
      final initialVersion = index.version.value;

      index.update(createTestNode(id: 'node-1'));

      expect(index.version.value, greaterThan(initialVersion));
    });

    test('version increments on remove', () {
      index.update(createTestNode(id: 'node-1'));
      final versionAfterUpdate = index.version.value;

      index.removeNode('node-1');

      expect(index.version.value, greaterThan(versionAfterUpdate));
    });

    test('version increments on clear', () {
      index.update(createTestNode(id: 'node-1'));
      final versionAfterUpdate = index.version.value;

      index.clear();

      expect(index.version.value, greaterThan(versionAfterUpdate));
    });

    test('notifyChanged forces version increment', () {
      final initialVersion = index.version.value;

      index.notifyChanged();

      expect(index.version.value, greaterThan(initialVersion));
    });

    test('version increments once at end of batch', () {
      final initialVersion = index.version.value;

      index.batch(() {
        index.update(createTestNode(id: 'node-1'));
        index.update(createTestNode(id: 'node-2'));
        index.update(createTestNode(id: 'node-3'));
      });

      // Version should be exactly 1 more than initial (single increment)
      expect(index.version.value, equals(initialVersion + 1));
    });
  });

  group('Debug Visualization', () {
    late GraphSpatialIndex<String, dynamic> index;

    setUp(() {
      index = GraphSpatialIndex<String, dynamic>();
    });

    test('getActiveCellsInfo returns cell information', () {
      index.update(
        createTestNode(id: 'node-1', position: const Offset(100, 100)),
      );

      final cellsInfo = index.getActiveCellsInfo();

      expect(cellsInfo.isNotEmpty, isTrue);
    });

    test('getActiveCellsInfo includes type breakdown', () {
      index.update(createTestNodeWithPorts(id: 'node-1'));
      index.updateConnection(
        createTestConnection(
          id: 'conn-1',
          sourceNodeId: 'node-1',
          targetNodeId: 'node-2',
        ),
        [const Rect.fromLTWH(0, 0, 100, 50)],
      );

      final cellsInfo = index.getActiveCellsInfo();

      // At least one cell should have counts
      expect(
        cellsInfo.any(
          (c) => c.nodeCount > 0 || c.portCount > 0 || c.connectionCount > 0,
        ),
        isTrue,
      );
    });

    test('cellBounds returns correct bounds for grid cell', () {
      final bounds = index.cellBounds(0, 0);

      expect(bounds.left, equals(0));
      expect(bounds.top, equals(0));
      expect(bounds.width, equals(index.gridSize));
      expect(bounds.height, equals(index.gridSize));
    });

    test('cellBounds handles negative cell coordinates', () {
      final bounds = index.cellBounds(-1, -1);

      expect(bounds.left, equals(-index.gridSize));
      expect(bounds.top, equals(-index.gridSize));
    });
  });

  group('Render Order Provider', () {
    late GraphSpatialIndex<String, dynamic> index;

    setUp(() {
      index = GraphSpatialIndex<String, dynamic>();
    });

    test('can set render order provider', () {
      final node1 = createTestNode(id: 'node-1');
      final node2 = createTestNode(id: 'node-2');

      index.update(node1);
      index.update(node2);

      // Should not throw
      index.renderOrderProvider = () => [node1, node2];
    });

    test('render order provider can be cleared', () {
      index.renderOrderProvider = () => [];
      index.renderOrderProvider = null;
    });
  });

  group('Node Shape Builder', () {
    late GraphSpatialIndex<String, dynamic> index;

    setUp(() {
      index = GraphSpatialIndex<String, dynamic>();
    });

    test('can set node shape builder', () {
      index.nodeShapeBuilder = (node) => null;

      // Should not throw when updating nodes
      index.update(createTestNode(id: 'node-1'));
    });

    test('node shape builder can be cleared', () {
      index.nodeShapeBuilder = (node) => null;
      index.nodeShapeBuilder = null;
    });
  });

  group('Port Size Resolver', () {
    late GraphSpatialIndex<String, dynamic> index;

    setUp(() {
      index = GraphSpatialIndex<String, dynamic>();
    });

    test('can set port size resolver', () {
      index.portSizeResolver = (port) => const Size(20, 20);

      // Should use custom size for port bounds
      index.update(createTestNodeWithPorts(id: 'node-1'));

      expect(index.portCount, equals(2));
    });

    test('port size resolver defaults to Size(10, 10) when null', () {
      index.portSizeResolver = null;

      index.update(createTestNodeWithPorts(id: 'node-1'));

      // Ports should still be indexed with default size
      expect(index.portCount, equals(2));
    });
  });

  group('Connection Hit Tester', () {
    late GraphSpatialIndex<String, dynamic> index;

    setUp(() {
      index = GraphSpatialIndex<String, dynamic>();
    });

    test('can set connection hit tester', () {
      index.connectionHitTester = (connection, point) => true;
    });

    test('connection hit tester can be cleared', () {
      index.connectionHitTester = (connection, point) => true;
      index.connectionHitTester = null;
    });
  });

  group('Special Node Types', () {
    late GraphSpatialIndex<String, dynamic> index;

    setUp(() {
      index = GraphSpatialIndex<String, dynamic>();
    });

    test('handles CommentNode (foreground layer)', () {
      final commentNode = createTestCommentNode<String>(
        id: 'comment-1',
        position: const Offset(100, 100),
        data: 'test',
      );

      index.update(commentNode);

      expect(index.nodeCount, equals(1));
      expect(index.getNode('comment-1'), equals(commentNode));

      // CommentNode is in foreground layer
      expect(commentNode.layer, equals(NodeRenderLayer.foreground));
    });

    test('handles GroupNode (background layer)', () {
      final groupNode = createTestGroupNode<String>(
        id: 'group-1',
        position: const Offset(100, 100),
        data: 'test',
      );

      index.update(groupNode);

      expect(index.nodeCount, equals(1));
      expect(index.getNode('group-1'), equals(groupNode));

      // GroupNode is in background layer
      expect(groupNode.layer, equals(NodeRenderLayer.background));
    });

    test('hit test respects layer ordering', () {
      // Background node (group)
      final groupNode = createTestGroupNode<String>(
        id: 'group-1',
        position: const Offset(0, 0),
        size: const Size(400, 400),
        data: 'group',
      );

      // Middle layer node (regular)
      final regularNode = createTestNode(
        id: 'regular-1',
        position: const Offset(100, 100),
        size: const Size(100, 100),
      );

      // Foreground node (comment)
      final commentNode = createTestCommentNode<String>(
        id: 'comment-1',
        position: const Offset(100, 100),
        width: 100,
        height: 100,
        data: 'comment',
      );

      index.update(groupNode);
      index.update(regularNode);
      index.update(commentNode);

      // Point is inside all three nodes - should hit foreground (comment) first
      final result = index.hitTest(const Offset(150, 150));

      expect(result.hitType, equals(HitTarget.node));
      expect(result.nodeId, equals('comment-1'));
    });
  });

  group('Edge Cases', () {
    late GraphSpatialIndex<String, dynamic> index;

    setUp(() {
      index = GraphSpatialIndex<String, dynamic>();
    });

    test('handles node at origin', () {
      final node = createTestNode(id: 'node-1', position: Offset.zero);

      index.update(node);

      expect(index.nodeCount, equals(1));
      expect(index.nodesAt(const Offset(50, 50)).length, equals(1));
    });

    test('handles node at negative coordinates', () {
      final node = createTestNode(
        id: 'node-1',
        position: const Offset(-100, -100),
        size: const Size(100, 100),
      );

      index.update(node);

      expect(index.nodeCount, equals(1));
      expect(index.nodesAt(const Offset(-50, -50)).length, equals(1));
    });

    test('handles very large coordinates', () {
      final node = createTestNode(
        id: 'node-1',
        position: const Offset(10000, 10000),
        size: const Size(100, 100),
      );

      index.update(node);

      expect(index.nodeCount, equals(1));
      expect(index.nodesAt(const Offset(10050, 10050)).length, equals(1));
    });

    test('handles node spanning multiple grid cells', () {
      // Default grid size is 500, so a node larger than that spans cells
      final node = createTestNode(
        id: 'node-1',
        position: const Offset(400, 400),
        size: const Size(200, 200),
      );

      index.update(node);

      // Should be queryable from different parts of its bounds
      expect(index.nodesAt(const Offset(450, 450)).length, equals(1));
      expect(index.nodesAt(const Offset(550, 550)).length, equals(1));
    });

    test('handles empty batch', () {
      final initialVersion = index.version.value;

      index.batch(() {
        // No operations
      });

      // Version should still increment (batch completion notifies)
      expect(index.version.value, equals(initialVersion + 1));
    });

    test('handles removing non-existent connection', () {
      final initialVersion = index.version.value;

      // Should not throw
      index.removeConnection('non-existent');

      // No notification since nothing changed
      expect(index.version.value, equals(initialVersion));
    });
  });
}
