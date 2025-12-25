/// Unit tests for the NodeFlowController Connection API.
///
/// Tests cover:
/// - Connection lookup operations (getConnection, connectionIds, connectionCount)
/// - Connection CRUD operations (addConnection, removeConnection, createConnection)
/// - Connection query operations (getConnectionsForNode, getConnectionsFromPort)
/// - Visibility operations (getVisibleConnections, getHiddenConnections)
/// - Selection operations (selectConnection, clearConnectionSelection)
/// - Control point operations (addControlPoint, removeControlPoint)
/// - Cycle detection (hasCycles, getCycles)
@Tags(['unit'])
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:vyuh_node_flow/vyuh_node_flow.dart';

import '../../helpers/test_factories.dart';

void main() {
  setUp(() {
    resetTestCounters();
  });

  // ===========================================================================
  // Model APIs - Lookup
  // ===========================================================================

  group('Connection Lookup APIs', () {
    test('getConnection returns connection for existing ID', () {
      final controller = createConnectedNodesController();

      final connection = controller.getConnection(
        controller.connections.first.id,
      );

      expect(connection, isNotNull);
    });

    test('getConnection returns null for non-existent ID', () {
      final controller = createTestController();

      final connection = controller.getConnection('non-existent');

      expect(connection, isNull);
    });

    test('connectionIds returns all connection IDs', () {
      final nodeA = createTestNodeWithOutputPort(id: 'node-a');
      final nodeB = createTestNodeWithInputPort(id: 'node-b');
      final nodeC = createTestNodeWithInputPort(id: 'node-c');
      final conn1 = createTestConnection(
        id: 'conn-1',
        sourceNodeId: 'node-a',
        targetNodeId: 'node-b',
      );
      final conn2 = createTestConnection(
        id: 'conn-2',
        sourceNodeId: 'node-a',
        targetNodeId: 'node-c',
      );
      final controller = createTestController(
        nodes: [nodeA, nodeB, nodeC],
        connections: [conn1, conn2],
      );

      final ids = controller.connectionIds.toList();

      expect(ids, hasLength(2));
      expect(ids, containsAll(['conn-1', 'conn-2']));
    });

    test('connectionCount returns correct count', () {
      final controller = createConnectedNodesController();

      expect(controller.connectionCount, equals(1));
    });

    test('connectionCount returns 0 for empty graph', () {
      final controller = createTestController();

      expect(controller.connectionCount, equals(0));
    });

    test('getConnectionsForNode returns connections for source node', () {
      final nodeA = createTestNodeWithOutputPort(id: 'node-a');
      final nodeB = createTestNodeWithInputPort(id: 'node-b');
      final nodeC = createTestNodeWithInputPort(id: 'node-c');
      final conn1 = createTestConnection(
        id: 'conn-1',
        sourceNodeId: 'node-a',
        targetNodeId: 'node-b',
      );
      final conn2 = createTestConnection(
        id: 'conn-2',
        sourceNodeId: 'node-a',
        targetNodeId: 'node-c',
      );
      final controller = createTestController(
        nodes: [nodeA, nodeB, nodeC],
        connections: [conn1, conn2],
      );

      final connections = controller.getConnectionsForNode('node-a');

      expect(connections, hasLength(2));
    });

    test('getConnectionsForNode returns connections for target node', () {
      final controller = createConnectedNodesController();

      final connections = controller.getConnectionsForNode('node-b');

      expect(connections, hasLength(1));
    });

    test('getConnectionsForNode returns empty list for unconnected node', () {
      final controller = createTestController();
      controller.addNode(createTestNode(id: 'isolated'));

      final connections = controller.getConnectionsForNode('isolated');

      expect(connections, isEmpty);
    });

    test('getConnectionsFromPort returns outgoing connections', () {
      final nodeA = createTestNodeWithOutputPort(id: 'node-a', portId: 'out-1');
      final nodeB = createTestNodeWithInputPort(id: 'node-b');
      final nodeC = createTestNodeWithInputPort(id: 'node-c');
      final conn1 = createTestConnection(
        sourceNodeId: 'node-a',
        sourcePortId: 'out-1',
        targetNodeId: 'node-b',
      );
      final conn2 = createTestConnection(
        sourceNodeId: 'node-a',
        sourcePortId: 'out-1',
        targetNodeId: 'node-c',
      );
      final controller = createTestController(
        nodes: [nodeA, nodeB, nodeC],
        connections: [conn1, conn2],
      );

      final connections = controller.getConnectionsFromPort('node-a', 'out-1');

      expect(connections, hasLength(2));
    });

    test('getConnectionsToPort returns incoming connections', () {
      final nodeA = createTestNodeWithOutputPort(id: 'node-a');
      final nodeB = createTestNodeWithOutputPort(id: 'node-b');
      final nodeC = createTestNodeWithInputPort(id: 'node-c', portId: 'in-1');
      final conn1 = createTestConnection(
        sourceNodeId: 'node-a',
        targetNodeId: 'node-c',
        targetPortId: 'in-1',
      );
      final conn2 = createTestConnection(
        sourceNodeId: 'node-b',
        targetNodeId: 'node-c',
        targetPortId: 'in-1',
      );
      final controller = createTestController(
        nodes: [nodeA, nodeB, nodeC],
        connections: [conn1, conn2],
      );

      final connections = controller.getConnectionsToPort('node-c', 'in-1');

      expect(connections, hasLength(2));
    });
  });

  // ===========================================================================
  // Model APIs - CRUD
  // ===========================================================================

  group('Connection CRUD APIs', () {
    test('addConnection adds connection to controller', () {
      final nodeA = createTestNodeWithOutputPort(id: 'node-a');
      final nodeB = createTestNodeWithInputPort(id: 'node-b');
      final controller = createTestController(nodes: [nodeA, nodeB]);
      final connection = createTestConnection(
        sourceNodeId: 'node-a',
        targetNodeId: 'node-b',
      );

      controller.addConnection(connection);

      expect(controller.connectionCount, equals(1));
    });

    test('addConnection makes connection available in connections list', () {
      final nodeA = createTestNodeWithOutputPort(id: 'node-a');
      final nodeB = createTestNodeWithInputPort(id: 'node-b');
      final controller = createTestController(nodes: [nodeA, nodeB]);
      final connection = createTestConnection(
        id: 'new-conn',
        sourceNodeId: 'node-a',
        targetNodeId: 'node-b',
      );

      controller.addConnection(connection);

      expect(controller.connections.any((c) => c.id == 'new-conn'), isTrue);
    });

    test('removeConnection removes connection from controller', () {
      final controller = createConnectedNodesController();
      final connectionId = controller.connections.first.id;

      controller.removeConnection(connectionId);

      expect(controller.connectionCount, equals(0));
    });

    test('removeConnection removes connection from selection if selected', () {
      final controller = createConnectedNodesController();
      final connectionId = controller.connections.first.id;
      controller.selectConnection(connectionId);

      controller.removeConnection(connectionId);

      expect(controller.selectedConnectionIds, isEmpty);
    });

    test('removeConnection throws for non-existent connection', () {
      final controller = createTestController();

      expect(
        () => controller.removeConnection('non-existent'),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('createConnection creates connection with auto-generated ID', () {
      final nodeA = createTestNodeWithOutputPort(id: 'node-a', portId: 'out');
      final nodeB = createTestNodeWithInputPort(id: 'node-b', portId: 'in');
      final controller = createTestController(nodes: [nodeA, nodeB]);

      controller.createConnection('node-a', 'out', 'node-b', 'in');

      expect(controller.connectionCount, equals(1));
      expect(controller.connections.first.sourceNodeId, equals('node-a'));
      expect(controller.connections.first.targetNodeId, equals('node-b'));
    });

    test('deleteAllConnectionsForNode removes all connections for node', () {
      final nodeA = createTestNodeWithOutputPort(id: 'node-a');
      final nodeB = createTestNodeWithInputPort(id: 'node-b');
      final nodeC = createTestNodeWithInputPort(id: 'node-c');
      final conn1 = createTestConnection(
        sourceNodeId: 'node-a',
        targetNodeId: 'node-b',
      );
      final conn2 = createTestConnection(
        sourceNodeId: 'node-a',
        targetNodeId: 'node-c',
      );
      final controller = createTestController(
        nodes: [nodeA, nodeB, nodeC],
        connections: [conn1, conn2],
      );

      controller.deleteAllConnectionsForNode('node-a');

      expect(controller.connectionCount, equals(0));
    });

    test('deleteAllConnectionsForNode does not remove the node itself', () {
      final controller = createConnectedNodesController();

      controller.deleteAllConnectionsForNode('node-a');

      expect(controller.getNode('node-a'), isNotNull);
    });
  });

  // ===========================================================================
  // Visual Query APIs
  // ===========================================================================

  group('Connection Visual Query APIs', () {
    test('getConnectionBounds returns bounding rectangle', () {
      final controller = createConnectedNodesController();
      final connectionId = controller.connections.first.id;

      final bounds = controller.getConnectionBounds(connectionId);

      expect(bounds, isNotNull);
      expect(bounds!.width, greaterThan(0));
      expect(bounds.height, greaterThan(0));
    });

    test('getConnectionBounds returns null for non-existent connection', () {
      final controller = createTestController();

      final bounds = controller.getConnectionBounds('non-existent');

      expect(bounds, isNull);
    });

    test(
      'getVisibleConnections returns connections with visible endpoints',
      () {
        final nodeA = createTestNodeWithOutputPort(id: 'node-a');
        final nodeB = createTestNodeWithInputPort(id: 'node-b');
        final nodeC = createTestNodeWithInputPort(id: 'node-c', visible: false);
        final conn1 = createTestConnection(
          id: 'visible-conn',
          sourceNodeId: 'node-a',
          targetNodeId: 'node-b',
        );
        final conn2 = createTestConnection(
          id: 'hidden-conn',
          sourceNodeId: 'node-a',
          targetNodeId: 'node-c',
        );
        final controller = createTestController(
          nodes: [nodeA, nodeB, nodeC],
          connections: [conn1, conn2],
        );

        final visibleConnections = controller.getVisibleConnections();

        expect(visibleConnections, hasLength(1));
        expect(visibleConnections.first.id, equals('visible-conn'));
      },
    );

    test('getHiddenConnections returns connections with hidden endpoints', () {
      final nodeA = createTestNodeWithOutputPort(id: 'node-a');
      final nodeB = createTestNodeWithInputPort(id: 'node-b', visible: false);
      final conn = createTestConnection(
        id: 'hidden-conn',
        sourceNodeId: 'node-a',
        targetNodeId: 'node-b',
      );
      final controller = createTestController(
        nodes: [nodeA, nodeB],
        connections: [conn],
      );

      final hiddenConnections = controller.getHiddenConnections();

      expect(hiddenConnections, hasLength(1));
    });
  });

  // ===========================================================================
  // Control Point APIs
  // ===========================================================================

  group('Connection Control Point APIs', () {
    test('addControlPoint adds control point to connection', () {
      final controller = createConnectedNodesController();
      final connectionId = controller.connections.first.id;

      controller.addControlPoint(connectionId, const Offset(150, 100));

      expect(controller.connections.first.controlPoints, hasLength(1));
      expect(
        controller.connections.first.controlPoints.first,
        equals(const Offset(150, 100)),
      );
    });

    test('addControlPoint inserts at specific index', () {
      final controller = createConnectedNodesController();
      final connectionId = controller.connections.first.id;
      controller.addControlPoint(connectionId, const Offset(100, 100));
      controller.addControlPoint(connectionId, const Offset(300, 100));

      controller.addControlPoint(
        connectionId,
        const Offset(200, 100),
        index: 1,
      );

      expect(controller.connections.first.controlPoints, hasLength(3));
      expect(
        controller.connections.first.controlPoints[1],
        equals(const Offset(200, 100)),
      );
    });

    test('addControlPoint throws for non-existent connection', () {
      final controller = createTestController();

      expect(
        () =>
            controller.addControlPoint('non-existent', const Offset(100, 100)),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('updateControlPoint updates control point position', () {
      final controller = createConnectedNodesController();
      final connectionId = controller.connections.first.id;
      controller.addControlPoint(connectionId, const Offset(100, 100));

      controller.updateControlPoint(connectionId, 0, const Offset(200, 200));

      expect(
        controller.connections.first.controlPoints.first,
        equals(const Offset(200, 200)),
      );
    });

    test('updateControlPoint ignores invalid index', () {
      final controller = createConnectedNodesController();
      final connectionId = controller.connections.first.id;
      controller.addControlPoint(connectionId, const Offset(100, 100));

      // Should not throw
      controller.updateControlPoint(connectionId, 5, const Offset(200, 200));

      expect(
        controller.connections.first.controlPoints.first,
        equals(const Offset(100, 100)),
      );
    });

    test('removeControlPoint removes control point', () {
      final controller = createConnectedNodesController();
      final connectionId = controller.connections.first.id;
      controller.addControlPoint(connectionId, const Offset(100, 100));
      controller.addControlPoint(connectionId, const Offset(200, 200));

      controller.removeControlPoint(connectionId, 0);

      expect(controller.connections.first.controlPoints, hasLength(1));
      expect(
        controller.connections.first.controlPoints.first,
        equals(const Offset(200, 200)),
      );
    });

    test('removeControlPoint ignores invalid index', () {
      final controller = createConnectedNodesController();
      final connectionId = controller.connections.first.id;
      controller.addControlPoint(connectionId, const Offset(100, 100));

      // Should not throw
      controller.removeControlPoint(connectionId, 5);

      expect(controller.connections.first.controlPoints, hasLength(1));
    });

    test('clearControlPoints removes all control points', () {
      final controller = createConnectedNodesController();
      final connectionId = controller.connections.first.id;
      controller.addControlPoint(connectionId, const Offset(100, 100));
      controller.addControlPoint(connectionId, const Offset(200, 200));
      controller.addControlPoint(connectionId, const Offset(300, 300));

      controller.clearControlPoints(connectionId);

      expect(controller.connections.first.controlPoints, isEmpty);
    });
  });

  // ===========================================================================
  // Selection APIs
  // ===========================================================================

  group('Connection Selection APIs', () {
    test('selectConnection selects a connection', () {
      final controller = createConnectedNodesController();
      final connectionId = controller.connections.first.id;

      controller.selectConnection(connectionId);

      expect(controller.selectedConnectionIds, contains(connectionId));
      expect(controller.connections.first.selected, isTrue);
    });

    test('selectConnection clears previous selection by default', () {
      final nodeA = createTestNodeWithOutputPort(id: 'node-a');
      final nodeB = createTestNodeWithInputPort(id: 'node-b');
      final nodeC = createTestNodeWithInputPort(id: 'node-c');
      final conn1 = createTestConnection(
        id: 'conn-1',
        sourceNodeId: 'node-a',
        targetNodeId: 'node-b',
      );
      final conn2 = createTestConnection(
        id: 'conn-2',
        sourceNodeId: 'node-a',
        targetNodeId: 'node-c',
      );
      final controller = createTestController(
        nodes: [nodeA, nodeB, nodeC],
        connections: [conn1, conn2],
      );
      controller.selectConnection('conn-1');

      controller.selectConnection('conn-2');

      expect(controller.selectedConnectionIds, hasLength(1));
      expect(controller.selectedConnectionIds, contains('conn-2'));
    });

    test('selectConnection with toggle adds to selection', () {
      final nodeA = createTestNodeWithOutputPort(id: 'node-a');
      final nodeB = createTestNodeWithInputPort(id: 'node-b');
      final nodeC = createTestNodeWithInputPort(id: 'node-c');
      final conn1 = createTestConnection(
        id: 'conn-1',
        sourceNodeId: 'node-a',
        targetNodeId: 'node-b',
      );
      final conn2 = createTestConnection(
        id: 'conn-2',
        sourceNodeId: 'node-a',
        targetNodeId: 'node-c',
      );
      final controller = createTestController(
        nodes: [nodeA, nodeB, nodeC],
        connections: [conn1, conn2],
      );
      controller.selectConnection('conn-1');

      controller.selectConnection('conn-2', toggle: true);

      expect(controller.selectedConnectionIds, hasLength(2));
    });

    test('selectConnection with toggle removes if already selected', () {
      final controller = createConnectedNodesController();
      final connectionId = controller.connections.first.id;
      controller.selectConnection(connectionId);

      controller.selectConnection(connectionId, toggle: true);

      expect(controller.selectedConnectionIds, isEmpty);
      expect(controller.connections.first.selected, isFalse);
    });

    test('selectConnection clears node selection', () {
      final controller = createConnectedNodesController();
      controller.selectNode('node-a');

      controller.selectConnection(controller.connections.first.id);

      expect(controller.selectedNodeIds, isEmpty);
    });

    test('clearConnectionSelection clears all connection selections', () {
      final nodeA = createTestNodeWithOutputPort(id: 'node-a');
      final nodeB = createTestNodeWithInputPort(id: 'node-b');
      final nodeC = createTestNodeWithInputPort(id: 'node-c');
      final conn1 = createTestConnection(
        id: 'conn-1',
        sourceNodeId: 'node-a',
        targetNodeId: 'node-b',
      );
      final conn2 = createTestConnection(
        id: 'conn-2',
        sourceNodeId: 'node-a',
        targetNodeId: 'node-c',
      );
      final controller = createTestController(
        nodes: [nodeA, nodeB, nodeC],
        connections: [conn1, conn2],
      );
      controller.selectConnection('conn-1');
      controller.selectConnection('conn-2', toggle: true);

      controller.clearConnectionSelection();

      expect(controller.selectedConnectionIds, isEmpty);
    });

    test('isConnectionSelected returns true for selected connection', () {
      final controller = createConnectedNodesController();
      final connectionId = controller.connections.first.id;
      controller.selectConnection(connectionId);

      expect(controller.isConnectionSelected(connectionId), isTrue);
    });

    test('isConnectionSelected returns false for unselected connection', () {
      final controller = createConnectedNodesController();
      final connectionId = controller.connections.first.id;

      expect(controller.isConnectionSelected(connectionId), isFalse);
    });

    test('selectAllConnections selects all connections', () {
      final nodeA = createTestNodeWithOutputPort(id: 'node-a');
      final nodeB = createTestNodeWithInputPort(id: 'node-b');
      final nodeC = createTestNodeWithInputPort(id: 'node-c');
      final conn1 = createTestConnection(
        id: 'conn-1',
        sourceNodeId: 'node-a',
        targetNodeId: 'node-b',
      );
      final conn2 = createTestConnection(
        id: 'conn-2',
        sourceNodeId: 'node-a',
        targetNodeId: 'node-c',
      );
      final controller = createTestController(
        nodes: [nodeA, nodeB, nodeC],
        connections: [conn1, conn2],
      );

      // Use explicit extension syntax to avoid ambiguity with GraphApi
      ConnectionApi(controller).selectAllConnections();

      expect(controller.selectedConnectionIds, hasLength(2));
    });
  });

  // ===========================================================================
  // Validation APIs - Cycle Detection
  // ===========================================================================

  group('Cycle Detection APIs', () {
    test('hasCycles returns false for DAG (no cycles)', () {
      // A -> B -> C (linear DAG)
      final nodeA = createTestNodeWithOutputPort(id: 'node-a', portId: 'out');
      final nodeB = createTestNodeWithPorts(id: 'node-b');
      final nodeC = createTestNodeWithInputPort(id: 'node-c', portId: 'in');
      final conn1 = createTestConnection(
        sourceNodeId: 'node-a',
        sourcePortId: 'out',
        targetNodeId: 'node-b',
        targetPortId: 'input-1',
      );
      final conn2 = createTestConnection(
        sourceNodeId: 'node-b',
        sourcePortId: 'output-1',
        targetNodeId: 'node-c',
        targetPortId: 'in',
      );
      final controller = createTestController(
        nodes: [nodeA, nodeB, nodeC],
        connections: [conn1, conn2],
      );

      expect(controller.hasCycles(), isFalse);
    });

    test('hasCycles returns true for simple cycle', () {
      // A -> B -> A (simple cycle)
      final nodeA = createTestNodeWithPorts(id: 'node-a');
      final nodeB = createTestNodeWithPorts(id: 'node-b');
      final conn1 = createTestConnection(
        sourceNodeId: 'node-a',
        sourcePortId: 'output-1',
        targetNodeId: 'node-b',
        targetPortId: 'input-1',
      );
      final conn2 = createTestConnection(
        sourceNodeId: 'node-b',
        sourcePortId: 'output-1',
        targetNodeId: 'node-a',
        targetPortId: 'input-1',
      );
      final controller = createTestController(
        nodes: [nodeA, nodeB],
        connections: [conn1, conn2],
      );

      expect(controller.hasCycles(), isTrue);
    });

    test('hasCycles returns true for complex cycle', () {
      // A -> B -> C -> A (triangle cycle)
      final nodeA = createTestNodeWithPorts(id: 'node-a');
      final nodeB = createTestNodeWithPorts(id: 'node-b');
      final nodeC = createTestNodeWithPorts(id: 'node-c');
      final conn1 = createTestConnection(
        sourceNodeId: 'node-a',
        sourcePortId: 'output-1',
        targetNodeId: 'node-b',
        targetPortId: 'input-1',
      );
      final conn2 = createTestConnection(
        sourceNodeId: 'node-b',
        sourcePortId: 'output-1',
        targetNodeId: 'node-c',
        targetPortId: 'input-1',
      );
      final conn3 = createTestConnection(
        sourceNodeId: 'node-c',
        sourcePortId: 'output-1',
        targetNodeId: 'node-a',
        targetPortId: 'input-1',
      );
      final controller = createTestController(
        nodes: [nodeA, nodeB, nodeC],
        connections: [conn1, conn2, conn3],
      );

      expect(controller.hasCycles(), isTrue);
    });

    test('getCycles returns empty list for DAG', () {
      final controller = createConnectedNodesController();

      final cycles = controller.getCycles();

      expect(cycles, isEmpty);
    });

    test('getCycles returns cycle path for simple cycle', () {
      final nodeA = createTestNodeWithPorts(id: 'node-a');
      final nodeB = createTestNodeWithPorts(id: 'node-b');
      final conn1 = createTestConnection(
        sourceNodeId: 'node-a',
        sourcePortId: 'output-1',
        targetNodeId: 'node-b',
        targetPortId: 'input-1',
      );
      final conn2 = createTestConnection(
        sourceNodeId: 'node-b',
        sourcePortId: 'output-1',
        targetNodeId: 'node-a',
        targetPortId: 'input-1',
      );
      final controller = createTestController(
        nodes: [nodeA, nodeB],
        connections: [conn1, conn2],
      );

      final cycles = controller.getCycles();

      expect(cycles, isNotEmpty);
    });

    test('hasCycles returns false for empty graph', () {
      final controller = createTestController();

      expect(controller.hasCycles(), isFalse);
    });

    test('hasCycles returns false for disconnected nodes', () {
      final controller = createTestController();
      controller.addNode(createTestNode(id: 'isolated-1'));
      controller.addNode(createTestNode(id: 'isolated-2'));

      expect(controller.hasCycles(), isFalse);
    });
  });

  // ===========================================================================
  // Edge Cases
  // ===========================================================================

  group('Edge Cases', () {
    test('operations on empty controller do not throw', () {
      final controller = createTestController();

      expect(() => controller.getConnection('any'), returnsNormally);
      expect(() => controller.getConnectionsForNode('any'), returnsNormally);
      expect(() => controller.clearConnectionSelection(), returnsNormally);
      expect(() => controller.hasCycles(), returnsNormally);
    });

    test('removing node cascades to connections', () {
      final controller = createConnectedNodesController();

      controller.removeNode('node-a');

      expect(controller.connectionCount, equals(0));
    });

    test('hiding source node affects getVisibleConnections', () {
      final controller = createConnectedNodesController();
      controller.setNodeVisibility('node-a', false);

      final visibleConnections = controller.getVisibleConnections();

      expect(visibleConnections, isEmpty);
    });

    test('hiding target node affects getVisibleConnections', () {
      final controller = createConnectedNodesController();
      controller.setNodeVisibility('node-b', false);

      final visibleConnections = controller.getVisibleConnections();

      expect(visibleConnections, isEmpty);
    });
  });
}
