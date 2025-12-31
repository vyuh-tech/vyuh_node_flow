@Tags(['behavior'])
library;

import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:vyuh_node_flow/vyuh_node_flow.dart';

import '../../helpers/test_factories.dart';

void main() {
  late NodeFlowController<String, dynamic> controller;

  setUp(() {
    controller = createTestController();
  });

  tearDown(() {
    controller.dispose();
  });

  /// Helper to create a node with both input and output ports
  Node<String> createFlowNode(String id, {Offset position = Offset.zero}) {
    return createTestNode(
      id: id,
      position: position,
      inputPorts: [createTestPort(id: '$id-in', type: PortType.input)],
      outputPorts: [createTestPort(id: '$id-out', type: PortType.output)],
    );
  }

  /// Helper to add a connection between two nodes
  void connect(String sourceId, String targetId) {
    final conn = createTestConnection(
      sourceNodeId: sourceId,
      sourcePortId: '$sourceId-out',
      targetNodeId: targetId,
      targetPortId: '$targetId-in',
    );
    controller.addConnection(conn);
  }

  group('Cycle Detection - No Cycles (DAG)', () {
    test('empty graph has no cycles', () {
      final cycles = controller.detectCycles();
      expect(cycles, isEmpty);
    });

    test('single node has no cycles', () {
      controller.addNode(createFlowNode('A'));

      final cycles = controller.detectCycles();
      expect(cycles, isEmpty);
    });

    test('two disconnected nodes have no cycles', () {
      controller.addNode(createFlowNode('A'));
      controller.addNode(createFlowNode('B'));

      final cycles = controller.detectCycles();
      expect(cycles, isEmpty);
    });

    test('linear chain A → B → C has no cycles', () {
      controller.addNode(createFlowNode('A'));
      controller.addNode(createFlowNode('B'));
      controller.addNode(createFlowNode('C'));

      connect('A', 'B');
      connect('B', 'C');

      final cycles = controller.detectCycles();
      expect(cycles, isEmpty);
    });

    test('tree structure has no cycles', () {
      //       A
      //      / \
      //     B   C
      //    / \
      //   D   E
      controller.addNode(createFlowNode('A'));
      controller.addNode(createFlowNode('B'));
      controller.addNode(createFlowNode('C'));
      controller.addNode(createFlowNode('D'));
      controller.addNode(createFlowNode('E'));

      connect('A', 'B');
      connect('A', 'C');
      connect('B', 'D');
      connect('B', 'E');

      final cycles = controller.detectCycles();
      expect(cycles, isEmpty);
    });

    test('DAG with diamond pattern has no cycles', () {
      //     A
      //    / \
      //   B   C
      //    \ /
      //     D
      controller.addNode(createFlowNode('A'));
      controller.addNode(createFlowNode('B'));
      controller.addNode(createFlowNode('C'));
      controller.addNode(createFlowNode('D'));

      connect('A', 'B');
      connect('A', 'C');
      connect('B', 'D');
      connect('C', 'D');

      final cycles = controller.detectCycles();
      expect(cycles, isEmpty);
    });

    test('multiple disconnected chains have no cycles', () {
      // Chain 1: A → B → C
      controller.addNode(createFlowNode('A'));
      controller.addNode(createFlowNode('B'));
      controller.addNode(createFlowNode('C'));
      connect('A', 'B');
      connect('B', 'C');

      // Chain 2: D → E → F
      controller.addNode(createFlowNode('D'));
      controller.addNode(createFlowNode('E'));
      controller.addNode(createFlowNode('F'));
      connect('D', 'E');
      connect('E', 'F');

      final cycles = controller.detectCycles();
      expect(cycles, isEmpty);
    });
  });

  group('Cycle Detection - Simple Cycles', () {
    test('detects simple cycle A → B → A', () {
      controller.addNode(createFlowNode('A'));
      controller.addNode(createFlowNode('B'));

      connect('A', 'B');
      connect('B', 'A');

      final cycles = controller.detectCycles();
      expect(cycles, isNotEmpty);
      expect(cycles.length, greaterThanOrEqualTo(1));
    });

    test('detects cycle A → B → C → A', () {
      controller.addNode(createFlowNode('A'));
      controller.addNode(createFlowNode('B'));
      controller.addNode(createFlowNode('C'));

      connect('A', 'B');
      connect('B', 'C');
      connect('C', 'A');

      final cycles = controller.detectCycles();
      expect(cycles, isNotEmpty);
    });

    test('detected cycle contains all participating nodes', () {
      controller.addNode(createFlowNode('A'));
      controller.addNode(createFlowNode('B'));
      controller.addNode(createFlowNode('C'));

      connect('A', 'B');
      connect('B', 'C');
      connect('C', 'A');

      final cycles = controller.detectCycles();
      expect(cycles, isNotEmpty);

      // At least one cycle should contain A, B, and C
      final containsAllNodes = cycles.any(
        (cycle) =>
            cycle.contains('A') && cycle.contains('B') && cycle.contains('C'),
      );
      expect(containsAllNodes, isTrue);
    });
  });

  group('Cycle Detection - Complex Cycles', () {
    test('detects longer cycle A → B → C → D → E → A', () {
      for (final id in ['A', 'B', 'C', 'D', 'E']) {
        controller.addNode(createFlowNode(id));
      }

      connect('A', 'B');
      connect('B', 'C');
      connect('C', 'D');
      connect('D', 'E');
      connect('E', 'A');

      final cycles = controller.detectCycles();
      expect(cycles, isNotEmpty);
    });

    test('detects cycle with branch before cycle', () {
      //     Entry
      //       |
      //       A
      //      / \
      //     B → C
      //     ↑   ↓
      //     E ← D
      controller.addNode(createFlowNode('Entry'));
      for (final id in ['A', 'B', 'C', 'D', 'E']) {
        controller.addNode(createFlowNode(id));
      }

      connect('Entry', 'A');
      connect('A', 'B');
      connect('B', 'C');
      connect('C', 'D');
      connect('D', 'E');
      connect('E', 'B'); // Creates cycle: B → C → D → E → B

      final cycles = controller.detectCycles();
      expect(cycles, isNotEmpty);

      // Cycle should not include Entry or A (they're before the cycle)
      final cycleNodes = cycles.expand((c) => c).toSet();
      expect(cycleNodes, isNot(contains('Entry')));
    });

    test('detects cycle with exit branch after cycle', () {
      //   A → B
      //   ↑   ↓
      //   C ← D
      //       ↓
      //     Exit
      for (final id in ['A', 'B', 'C', 'D', 'Exit']) {
        controller.addNode(createFlowNode(id));
      }

      connect('A', 'B');
      connect('B', 'D');
      connect('D', 'C');
      connect('C', 'A'); // Creates cycle
      connect('D', 'Exit'); // Exit branch

      final cycles = controller.detectCycles();
      expect(cycles, isNotEmpty);

      // Exit node should not be part of any cycle
      final cycleNodes = cycles.expand((c) => c).toSet();
      expect(cycleNodes, isNot(contains('Exit')));
    });
  });

  group('Cycle Detection - Multiple Cycles', () {
    test('detects multiple independent cycles', () {
      // Cycle 1: A → B → A
      controller.addNode(createFlowNode('A'));
      controller.addNode(createFlowNode('B'));
      connect('A', 'B');
      connect('B', 'A');

      // Cycle 2: C → D → C (disconnected from Cycle 1)
      controller.addNode(createFlowNode('C'));
      controller.addNode(createFlowNode('D'));
      connect('C', 'D');
      connect('D', 'C');

      final cycles = controller.detectCycles();
      expect(cycles.length, greaterThanOrEqualTo(2));
    });

    test('detects nested/overlapping cycles', () {
      // Graph:
      //   A → B → C
      //   ↑   ↓   ↓
      //   E ← D ←─┘
      //
      // Contains two cycles:
      // 1. A → B → D → E → A
      // 2. B → C → D → B
      for (final id in ['A', 'B', 'C', 'D', 'E']) {
        controller.addNode(createFlowNode(id));
      }

      connect('A', 'B');
      connect('B', 'C');
      connect('B', 'D');
      connect('C', 'D');
      connect('D', 'E');
      connect('E', 'A');

      final cycles = controller.detectCycles();
      expect(cycles, isNotEmpty);
    });
  });

  group('Cycle Detection - Edge Cases', () {
    test('handles graph with only connections (no isolated nodes)', () {
      controller.addNode(createFlowNode('A'));
      controller.addNode(createFlowNode('B'));
      connect('A', 'B');
      connect('B', 'A');

      final cycles = controller.detectCycles();
      expect(cycles, isNotEmpty);
    });

    test('handles graph with isolated nodes alongside cycle', () {
      // Cycle: A → B → A
      controller.addNode(createFlowNode('A'));
      controller.addNode(createFlowNode('B'));
      connect('A', 'B');
      connect('B', 'A');

      // Isolated nodes
      controller.addNode(createFlowNode('Isolated1'));
      controller.addNode(createFlowNode('Isolated2'));

      final cycles = controller.detectCycles();
      expect(cycles, isNotEmpty);

      // Isolated nodes should not be in cycles
      final cycleNodes = cycles.expand((c) => c).toSet();
      expect(cycleNodes, isNot(contains('Isolated1')));
      expect(cycleNodes, isNot(contains('Isolated2')));
    });

    test('removing connection breaks cycle', () {
      controller.addNode(createFlowNode('A'));
      controller.addNode(createFlowNode('B'));

      final conn1 = createTestConnection(
        id: 'conn-ab',
        sourceNodeId: 'A',
        sourcePortId: 'A-out',
        targetNodeId: 'B',
        targetPortId: 'B-in',
      );
      final conn2 = createTestConnection(
        id: 'conn-ba',
        sourceNodeId: 'B',
        sourcePortId: 'B-out',
        targetNodeId: 'A',
        targetPortId: 'A-in',
      );
      controller.addConnection(conn1);
      controller.addConnection(conn2);

      // Verify cycle exists
      expect(controller.detectCycles(), isNotEmpty);

      // Remove one connection to break cycle
      controller.removeConnection('conn-ba');

      // Cycle should be gone
      expect(controller.detectCycles(), isEmpty);
    });

    test('removing node breaks cycle', () {
      controller.addNode(createFlowNode('A'));
      controller.addNode(createFlowNode('B'));
      controller.addNode(createFlowNode('C'));

      connect('A', 'B');
      connect('B', 'C');
      connect('C', 'A');

      // Verify cycle exists
      expect(controller.detectCycles(), isNotEmpty);

      // Remove one node to break cycle
      controller.removeNode('B');

      // Cycle should be gone
      expect(controller.detectCycles(), isEmpty);
    });
  });

  group('Orphan Nodes Detection', () {
    test('getOrphanNodes returns nodes with no connections', () {
      controller.addNode(createFlowNode('Connected1'));
      controller.addNode(createFlowNode('Connected2'));
      controller.addNode(createFlowNode('Orphan1'));
      controller.addNode(createFlowNode('Orphan2'));

      connect('Connected1', 'Connected2');

      final orphans = controller.getOrphanNodes();
      expect(orphans.length, equals(2));
      expect(orphans.map((n) => n.id), containsAll(['Orphan1', 'Orphan2']));
    });

    test('getOrphanNodes returns empty when all nodes are connected', () {
      controller.addNode(createFlowNode('A'));
      controller.addNode(createFlowNode('B'));
      controller.addNode(createFlowNode('C'));

      connect('A', 'B');
      connect('B', 'C');

      final orphans = controller.getOrphanNodes();
      expect(orphans, isEmpty);
    });

    test('getOrphanNodes returns all nodes when no connections', () {
      controller.addNode(createFlowNode('A'));
      controller.addNode(createFlowNode('B'));
      controller.addNode(createFlowNode('C'));

      final orphans = controller.getOrphanNodes();
      expect(orphans.length, equals(3));
    });

    test('removing connection creates orphan nodes', () {
      controller.addNode(createFlowNode('A'));
      controller.addNode(createFlowNode('B'));

      final conn = createTestConnection(
        id: 'conn-ab',
        sourceNodeId: 'A',
        sourcePortId: 'A-out',
        targetNodeId: 'B',
        targetPortId: 'B-in',
      );
      controller.addConnection(conn);

      expect(controller.getOrphanNodes(), isEmpty);

      controller.removeConnection('conn-ab');

      expect(controller.getOrphanNodes().length, equals(2));
    });
  });

  group('Self-Connection Behavior', () {
    test(
      'self-connections (output to input on same node) are allowed by default',
      () {
        // The library allows self-connections for feedback loops and similar patterns.
        // Custom validation can be added via onBeforeComplete callback if needed.
        final node = createFlowNode('A');
        controller.addNode(node);

        // Start connection from output
        controller.startConnectionDrag(
          nodeId: 'A',
          portId: 'A-out',
          isOutput: true,
          startPoint: const Offset(100, 50),
          nodeBounds: const Rect.fromLTWH(0, 0, 100, 100),
        );

        // Check if connecting to same node's input is allowed
        final result = controller.canConnect(
          targetNodeId: 'A',
          targetPortId: 'A-in',
        );

        // Self-connections ARE allowed by default (for feedback loops, etc.)
        expect(result.allowed, isTrue);

        controller.cancelConnectionDrag();
      },
    );

    test('connecting port to itself is rejected', () {
      final node = createFlowNode('A');
      controller.addNode(node);

      // Start connection from output
      controller.startConnectionDrag(
        nodeId: 'A',
        portId: 'A-out',
        isOutput: true,
        startPoint: const Offset(100, 50),
        nodeBounds: const Rect.fromLTWH(0, 0, 100, 100),
      );

      // Try connecting the same port to itself (meaningless operation)
      final result = controller.canConnect(
        targetNodeId: 'A',
        targetPortId: 'A-out', // Same port we started from
      );

      // Connecting a port to itself should be rejected
      expect(result.allowed, isFalse);
      expect(result.reason, contains('itself'));

      controller.cancelConnectionDrag();
    });

    test(
      'self-connection creates immediate cycle detectable by detectCycles',
      () {
        final node = createFlowNode('A');
        controller.addNode(node);

        // Create a self-connection
        final conn = createTestConnection(
          sourceNodeId: 'A',
          sourcePortId: 'A-out',
          targetNodeId: 'A',
          targetPortId: 'A-in',
        );
        controller.addConnection(conn);

        // Self-connection creates a trivial cycle
        final cycles = controller.detectCycles();
        expect(cycles, isNotEmpty);
      },
    );
  });
}
