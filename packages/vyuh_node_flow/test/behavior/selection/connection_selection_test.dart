/// Behavior tests for connection selection functionality.
///
/// Tests cover:
/// - Single connection selection
/// - Toggle selection mode
/// - Multiple connection selection
/// - Selection clearing
/// - Selection state management
/// - Selection with visibility states
/// - Connection selection clears node selection
@Tags(['behavior'])
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:vyuh_node_flow/vyuh_node_flow.dart';

import '../../helpers/test_factories.dart';

void main() {
  late NodeFlowController<String, dynamic> controller;

  setUp(() {
    resetTestCounters();
    controller = createTestController();
  });

  group('Single Connection Selection', () {
    test('selectConnection selects a single connection', () {
      final node1 = createTestNodeWithOutputPort(id: 'node1', portId: 'out1');
      final node2 = createTestNodeWithInputPort(id: 'node2', portId: 'in1');
      final conn = createTestConnection(
        id: 'conn1',
        sourceNodeId: 'node1',
        sourcePortId: 'out1',
        targetNodeId: 'node2',
        targetPortId: 'in1',
      );
      controller.addNode(node1);
      controller.addNode(node2);
      controller.addConnection(conn);

      controller.selectConnection('conn1');

      expect(controller.isConnectionSelected('conn1'), isTrue);
      expect(controller.selectedConnectionIds.length, equals(1));
    });

    test(
      'selectConnection clears previous connection selection by default',
      () {
        final node1 = createTestNodeWithPorts(id: 'node1');
        final node2 = createTestNodeWithPorts(id: 'node2');
        final node3 = createTestNodeWithPorts(id: 'node3');
        final conn1 = createTestConnection(
          id: 'conn1',
          sourceNodeId: 'node1',
          sourcePortId: 'output-1',
          targetNodeId: 'node2',
          targetPortId: 'input-1',
        );
        final conn2 = createTestConnection(
          id: 'conn2',
          sourceNodeId: 'node2',
          sourcePortId: 'output-1',
          targetNodeId: 'node3',
          targetPortId: 'input-1',
        );
        controller.addNode(node1);
        controller.addNode(node2);
        controller.addNode(node3);
        controller.addConnection(conn1);
        controller.addConnection(conn2);

        controller.selectConnection('conn1');
        controller.selectConnection('conn2');

        expect(controller.isConnectionSelected('conn1'), isFalse);
        expect(controller.isConnectionSelected('conn2'), isTrue);
        expect(controller.selectedConnectionIds.length, equals(1));
      },
    );

    test('selectConnection updates connection selected state', () {
      final node1 = createTestNodeWithOutputPort(id: 'node1', portId: 'out1');
      final node2 = createTestNodeWithInputPort(id: 'node2', portId: 'in1');
      final conn = createTestConnection(
        id: 'conn1',
        sourceNodeId: 'node1',
        sourcePortId: 'out1',
        targetNodeId: 'node2',
        targetPortId: 'in1',
      );
      controller.addNode(node1);
      controller.addNode(node2);
      controller.addConnection(conn);

      controller.selectConnection('conn1');

      final connection = controller.getConnection('conn1');
      expect(connection?.selected, isTrue);
    });

    test('selectConnection clears node selection', () {
      final node1 = createTestNodeWithOutputPort(id: 'node1', portId: 'out1');
      final node2 = createTestNodeWithInputPort(id: 'node2', portId: 'in1');
      final conn = createTestConnection(
        id: 'conn1',
        sourceNodeId: 'node1',
        sourcePortId: 'out1',
        targetNodeId: 'node2',
        targetPortId: 'in1',
      );
      controller.addNode(node1);
      controller.addNode(node2);
      controller.addConnection(conn);

      // Select a node first
      controller.selectNode('node1');
      expect(controller.selectedNodeIds.length, equals(1));

      // Selecting a connection should clear node selection
      controller.selectConnection('conn1');

      expect(controller.selectedNodeIds, isEmpty);
      expect(controller.selectedConnectionIds.length, equals(1));
    });
  });

  group('Toggle Selection Mode', () {
    test('selectConnection with toggle adds to existing selection', () {
      final node1 = createTestNodeWithPorts(id: 'node1');
      final node2 = createTestNodeWithPorts(id: 'node2');
      final node3 = createTestNodeWithPorts(id: 'node3');
      final conn1 = createTestConnection(
        id: 'conn1',
        sourceNodeId: 'node1',
        sourcePortId: 'output-1',
        targetNodeId: 'node2',
        targetPortId: 'input-1',
      );
      final conn2 = createTestConnection(
        id: 'conn2',
        sourceNodeId: 'node2',
        sourcePortId: 'output-1',
        targetNodeId: 'node3',
        targetPortId: 'input-1',
      );
      controller.addNode(node1);
      controller.addNode(node2);
      controller.addNode(node3);
      controller.addConnection(conn1);
      controller.addConnection(conn2);

      controller.selectConnection('conn1');
      controller.selectConnection('conn2', toggle: true);

      expect(controller.isConnectionSelected('conn1'), isTrue);
      expect(controller.isConnectionSelected('conn2'), isTrue);
      expect(controller.selectedConnectionIds.length, equals(2));
    });

    test(
      'selectConnection with toggle deselects already selected connection',
      () {
        final node1 = createTestNodeWithOutputPort(id: 'node1', portId: 'out1');
        final node2 = createTestNodeWithInputPort(id: 'node2', portId: 'in1');
        final conn = createTestConnection(
          id: 'conn1',
          sourceNodeId: 'node1',
          sourcePortId: 'out1',
          targetNodeId: 'node2',
          targetPortId: 'in1',
        );
        controller.addNode(node1);
        controller.addNode(node2);
        controller.addConnection(conn);

        controller.selectConnection('conn1');
        controller.selectConnection('conn1', toggle: true);

        expect(controller.isConnectionSelected('conn1'), isFalse);
        expect(controller.selectedConnectionIds, isEmpty);
      },
    );

    test(
      'selectConnection with toggle preserves other selections when deselecting',
      () {
        final node1 = createTestNodeWithPorts(id: 'node1');
        final node2 = createTestNodeWithPorts(id: 'node2');
        final node3 = createTestNodeWithPorts(id: 'node3');
        final conn1 = createTestConnection(
          id: 'conn1',
          sourceNodeId: 'node1',
          sourcePortId: 'output-1',
          targetNodeId: 'node2',
          targetPortId: 'input-1',
        );
        final conn2 = createTestConnection(
          id: 'conn2',
          sourceNodeId: 'node2',
          sourcePortId: 'output-1',
          targetNodeId: 'node3',
          targetPortId: 'input-1',
        );
        controller.addNode(node1);
        controller.addNode(node2);
        controller.addNode(node3);
        controller.addConnection(conn1);
        controller.addConnection(conn2);

        controller.selectConnection('conn1');
        controller.selectConnection('conn2', toggle: true);
        controller.selectConnection('conn1', toggle: true); // Deselect conn1

        expect(controller.isConnectionSelected('conn1'), isFalse);
        expect(controller.isConnectionSelected('conn2'), isTrue);
        expect(controller.selectedConnectionIds.length, equals(1));
      },
    );
  });

  group('Multiple Connection Selection', () {
    test('selectAllConnections selects every connection', () {
      final node1 = createTestNodeWithPorts(id: 'node1');
      final node2 = createTestNodeWithPorts(id: 'node2');
      final node3 = createTestNodeWithPorts(id: 'node3');
      final conn1 = createTestConnection(
        id: 'conn1',
        sourceNodeId: 'node1',
        sourcePortId: 'output-1',
        targetNodeId: 'node2',
        targetPortId: 'input-1',
      );
      final conn2 = createTestConnection(
        id: 'conn2',
        sourceNodeId: 'node2',
        sourcePortId: 'output-1',
        targetNodeId: 'node3',
        targetPortId: 'input-1',
      );
      controller.addNode(node1);
      controller.addNode(node2);
      controller.addNode(node3);
      controller.addConnection(conn1);
      controller.addConnection(conn2);

      // Use the explicit extension syntax to call selectAllConnections
      ConnectionApi(controller).selectAllConnections();

      expect(controller.selectedConnectionIds.length, equals(2));
    });
  });

  group('Selection Clearing', () {
    test('clearConnectionSelection deselects all connections', () {
      final node1 = createTestNodeWithPorts(id: 'node1');
      final node2 = createTestNodeWithPorts(id: 'node2');
      final node3 = createTestNodeWithPorts(id: 'node3');
      final conn1 = createTestConnection(
        id: 'conn1',
        sourceNodeId: 'node1',
        sourcePortId: 'output-1',
        targetNodeId: 'node2',
        targetPortId: 'input-1',
      );
      final conn2 = createTestConnection(
        id: 'conn2',
        sourceNodeId: 'node2',
        sourcePortId: 'output-1',
        targetNodeId: 'node3',
        targetPortId: 'input-1',
      );
      controller.addNode(node1);
      controller.addNode(node2);
      controller.addNode(node3);
      controller.addConnection(conn1);
      controller.addConnection(conn2);

      controller.selectConnection('conn1');
      controller.clearConnectionSelection();

      expect(controller.selectedConnectionIds, isEmpty);
    });

    test('clearConnectionSelection updates connection selected state', () {
      final node1 = createTestNodeWithOutputPort(id: 'node1', portId: 'out1');
      final node2 = createTestNodeWithInputPort(id: 'node2', portId: 'in1');
      final conn = createTestConnection(
        id: 'conn1',
        sourceNodeId: 'node1',
        sourcePortId: 'out1',
        targetNodeId: 'node2',
        targetPortId: 'in1',
      );
      controller.addNode(node1);
      controller.addNode(node2);
      controller.addConnection(conn);

      controller.selectConnection('conn1');
      controller.clearConnectionSelection();

      final connection = controller.getConnection('conn1');
      expect(connection?.selected, isFalse);
    });

    test('clearConnectionSelection on empty selection does nothing', () {
      controller.clearConnectionSelection();

      expect(controller.selectedConnectionIds, isEmpty);
    });
  });

  group('Selection State Observable', () {
    test('hasSelection returns true when connections selected', () {
      final node1 = createTestNodeWithOutputPort(id: 'node1', portId: 'out1');
      final node2 = createTestNodeWithInputPort(id: 'node2', portId: 'in1');
      final conn = createTestConnection(
        id: 'conn1',
        sourceNodeId: 'node1',
        sourcePortId: 'out1',
        targetNodeId: 'node2',
        targetPortId: 'in1',
      );
      controller.addNode(node1);
      controller.addNode(node2);
      controller.addConnection(conn);

      expect(controller.hasSelection, isFalse);

      controller.selectConnection('conn1');

      expect(controller.hasSelection, isTrue);
    });

    test('hasSelection updates when connection selection changes', () {
      final node1 = createTestNodeWithOutputPort(id: 'node1', portId: 'out1');
      final node2 = createTestNodeWithInputPort(id: 'node2', portId: 'in1');
      final conn = createTestConnection(
        id: 'conn1',
        sourceNodeId: 'node1',
        sourcePortId: 'out1',
        targetNodeId: 'node2',
        targetPortId: 'in1',
      );
      controller.addNode(node1);
      controller.addNode(node2);
      controller.addConnection(conn);

      controller.selectConnection('conn1');
      expect(controller.hasSelection, isTrue);

      controller.clearConnectionSelection();
      expect(controller.hasSelection, isFalse);
    });
  });

  group('Selection with Connection Removal', () {
    test('removing selected connection clears it from selection', () {
      final node1 = createTestNodeWithOutputPort(id: 'node1', portId: 'out1');
      final node2 = createTestNodeWithInputPort(id: 'node2', portId: 'in1');
      final conn = createTestConnection(
        id: 'conn1',
        sourceNodeId: 'node1',
        sourcePortId: 'out1',
        targetNodeId: 'node2',
        targetPortId: 'in1',
      );
      controller.addNode(node1);
      controller.addNode(node2);
      controller.addConnection(conn);

      controller.selectConnection('conn1');
      controller.removeConnection('conn1');

      expect(controller.selectedConnectionIds, isEmpty);
      expect(controller.isConnectionSelected('conn1'), isFalse);
    });

    test('removing one selected connection preserves others', () {
      final node1 = createTestNodeWithPorts(id: 'node1');
      final node2 = createTestNodeWithPorts(id: 'node2');
      final node3 = createTestNodeWithPorts(id: 'node3');
      final conn1 = createTestConnection(
        id: 'conn1',
        sourceNodeId: 'node1',
        sourcePortId: 'output-1',
        targetNodeId: 'node2',
        targetPortId: 'input-1',
      );
      final conn2 = createTestConnection(
        id: 'conn2',
        sourceNodeId: 'node2',
        sourcePortId: 'output-1',
        targetNodeId: 'node3',
        targetPortId: 'input-1',
      );
      controller.addNode(node1);
      controller.addNode(node2);
      controller.addNode(node3);
      controller.addConnection(conn1);
      controller.addConnection(conn2);

      controller.selectConnection('conn1');
      controller.selectConnection('conn2', toggle: true);
      controller.removeConnection('conn1');

      expect(controller.selectedConnectionIds.length, equals(1));
      expect(controller.isConnectionSelected('conn2'), isTrue);
    });
  });

  group('Selection with Visibility', () {
    test('can select connection with visible endpoints', () {
      final node1 = createTestNodeWithOutputPort(id: 'node1', portId: 'out1');
      final node2 = createTestNodeWithInputPort(id: 'node2', portId: 'in1');
      final conn = createTestConnection(
        id: 'conn1',
        sourceNodeId: 'node1',
        sourcePortId: 'out1',
        targetNodeId: 'node2',
        targetPortId: 'in1',
      );
      controller.addNode(node1);
      controller.addNode(node2);
      controller.addConnection(conn);

      controller.selectConnection('conn1');

      expect(controller.isConnectionSelected('conn1'), isTrue);
    });

    test('can select connection even with hidden endpoint nodes', () {
      final node1 = createTestNodeWithOutputPort(
        id: 'node1',
        portId: 'out1',
        visible: false,
      );
      final node2 = createTestNodeWithInputPort(
        id: 'node2',
        portId: 'in1',
        visible: true,
      );
      final conn = createTestConnection(
        id: 'conn1',
        sourceNodeId: 'node1',
        sourcePortId: 'out1',
        targetNodeId: 'node2',
        targetPortId: 'in1',
      );
      controller.addNode(node1);
      controller.addNode(node2);
      controller.addConnection(conn);

      controller.selectConnection('conn1');

      expect(controller.isConnectionSelected('conn1'), isTrue);
    });
  });

  group('Selection Events', () {
    test('selectConnection fires onSelected callback', () {
      String? selectedConnectionId;
      final node1 = createTestNodeWithOutputPort(id: 'node1', portId: 'out1');
      final node2 = createTestNodeWithInputPort(id: 'node2', portId: 'in1');
      final conn = createTestConnection(
        id: 'conn1',
        sourceNodeId: 'node1',
        sourcePortId: 'out1',
        targetNodeId: 'node2',
        targetPortId: 'in1',
      );
      controller.addNode(node1);
      controller.addNode(node2);
      controller.addConnection(conn);

      controller.updateEvents(
        NodeFlowEvents<String, dynamic>(
          connection: ConnectionEvents<String, dynamic>(
            onSelected: (c) {
              selectedConnectionId = c?.id;
            },
          ),
        ),
      );

      controller.selectConnection('conn1');

      expect(selectedConnectionId, equals('conn1'));
    });

    test('clearConnectionSelection fires onSelected callback with null', () {
      String? lastSelectedConnectionId = 'initial';
      final node1 = createTestNodeWithOutputPort(id: 'node1', portId: 'out1');
      final node2 = createTestNodeWithInputPort(id: 'node2', portId: 'in1');
      final conn = createTestConnection(
        id: 'conn1',
        sourceNodeId: 'node1',
        sourcePortId: 'out1',
        targetNodeId: 'node2',
        targetPortId: 'in1',
      );
      controller.addNode(node1);
      controller.addNode(node2);
      controller.addConnection(conn);

      controller.updateEvents(
        NodeFlowEvents<String, dynamic>(
          connection: ConnectionEvents<String, dynamic>(
            onSelected: (c) {
              lastSelectedConnectionId = c?.id;
            },
          ),
        ),
      );

      controller.selectConnection('conn1');
      expect(lastSelectedConnectionId, equals('conn1'));

      controller.clearConnectionSelection();
      expect(lastSelectedConnectionId, isNull);
    });
  });

  group('Selection Count', () {
    test('selectedConnectionIds count matches actual selection', () {
      final node1 = createTestNodeWithPorts(id: 'node1');
      final node2 = createTestNodeWithPorts(id: 'node2');
      final node3 = createTestNodeWithPorts(id: 'node3');
      final conn1 = createTestConnection(
        id: 'conn1',
        sourceNodeId: 'node1',
        sourcePortId: 'output-1',
        targetNodeId: 'node2',
        targetPortId: 'input-1',
      );
      final conn2 = createTestConnection(
        id: 'conn2',
        sourceNodeId: 'node2',
        sourcePortId: 'output-1',
        targetNodeId: 'node3',
        targetPortId: 'input-1',
      );
      controller.addNode(node1);
      controller.addNode(node2);
      controller.addNode(node3);
      controller.addConnection(conn1);
      controller.addConnection(conn2);

      expect(controller.selectedConnectionIds.length, equals(0));

      controller.selectConnection('conn1');
      expect(controller.selectedConnectionIds.length, equals(1));

      controller.selectConnection('conn2', toggle: true);
      expect(controller.selectedConnectionIds.length, equals(2));

      controller.selectConnection('conn1', toggle: true);
      expect(controller.selectedConnectionIds.length, equals(1));

      controller.clearConnectionSelection();
      expect(controller.selectedConnectionIds.length, equals(0));
    });
  });

  group('Mixed Selection', () {
    test('selecting node after connection clears connection selection', () {
      final node1 = createTestNodeWithOutputPort(id: 'node1', portId: 'out1');
      final node2 = createTestNodeWithInputPort(id: 'node2', portId: 'in1');
      final conn = createTestConnection(
        id: 'conn1',
        sourceNodeId: 'node1',
        sourcePortId: 'out1',
        targetNodeId: 'node2',
        targetPortId: 'in1',
      );
      controller.addNode(node1);
      controller.addNode(node2);
      controller.addConnection(conn);

      controller.selectConnection('conn1');
      expect(controller.selectedConnectionIds.length, equals(1));

      // Selecting a node should clear connection selection
      controller.selectNode('node1');

      expect(controller.selectedConnectionIds, isEmpty);
      expect(controller.selectedNodeIds.length, equals(1));
    });

    test('clearSelection clears both nodes and connections', () {
      final node1 = createTestNodeWithOutputPort(id: 'node1', portId: 'out1');
      final node2 = createTestNodeWithInputPort(id: 'node2', portId: 'in1');
      final conn = createTestConnection(
        id: 'conn1',
        sourceNodeId: 'node1',
        sourcePortId: 'out1',
        targetNodeId: 'node2',
        targetPortId: 'in1',
      );
      controller.addNode(node1);
      controller.addNode(node2);
      controller.addConnection(conn);

      controller.selectConnection('conn1');

      // Clear all selections
      controller.clearSelection();

      expect(controller.selectedNodeIds, isEmpty);
      expect(controller.selectedConnectionIds, isEmpty);
    });
  });
}
