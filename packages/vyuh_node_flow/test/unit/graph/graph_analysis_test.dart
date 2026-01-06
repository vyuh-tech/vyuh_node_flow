/// Comprehensive tests for graph analysis utilities in vyuh_node_flow.
///
/// Tests cover:
/// - Cycle detection algorithms
/// - Path finding and connectivity analysis
/// - Connected components identification
/// - Graph bounds calculation
@Tags(['unit'])
library;

import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:vyuh_node_flow/vyuh_node_flow.dart';

import '../../helpers/test_factories.dart';

void main() {
  late NodeFlowController<String, dynamic> controller;

  setUp(() {
    resetTestCounters();
    controller = createTestController();
  });

  tearDown(() {
    controller.dispose();
  });

  // ===========================================================================
  // Helper Functions
  // ===========================================================================

  /// Creates a node with both input and output ports for flow-based graphs.
  Node<String> createFlowNode(String id, {Offset position = Offset.zero}) {
    return createTestNode(
      id: id,
      position: position,
      inputPorts: [createTestPort(id: '$id-in', type: PortType.input)],
      outputPorts: [createTestPort(id: '$id-out', type: PortType.output)],
    );
  }

  /// Creates a directed connection between two flow nodes.
  void connect(String sourceId, String targetId) {
    final conn = createTestConnection(
      sourceNodeId: sourceId,
      sourcePortId: '$sourceId-out',
      targetNodeId: targetId,
      targetPortId: '$targetId-in',
    );
    controller.addConnection(conn);
  }

  // ===========================================================================
  // CYCLE DETECTION TESTS
  // ===========================================================================

  group('Cycle Detection', () {
    group('detectCycles() - No Cycles (Directed Acyclic Graphs)', () {
      test('empty graph has no cycles', () {
        final cycles = controller.detectCycles();
        expect(cycles, isEmpty);
        expect(controller.hasCycles(), isFalse);
      });

      test('single isolated node has no cycles', () {
        controller.addNode(createFlowNode('A'));

        expect(controller.detectCycles(), isEmpty);
        expect(controller.hasCycles(), isFalse);
      });

      test('multiple isolated nodes have no cycles', () {
        for (final id in ['A', 'B', 'C', 'D']) {
          controller.addNode(createFlowNode(id));
        }

        expect(controller.detectCycles(), isEmpty);
        expect(controller.hasCycles(), isFalse);
      });

      test('linear chain has no cycles', () {
        // A -> B -> C -> D
        for (final id in ['A', 'B', 'C', 'D']) {
          controller.addNode(createFlowNode(id));
        }
        connect('A', 'B');
        connect('B', 'C');
        connect('C', 'D');

        expect(controller.detectCycles(), isEmpty);
        expect(controller.hasCycles(), isFalse);
      });

      test('tree structure has no cycles', () {
        //       A
        //      / \
        //     B   C
        //    / \   \
        //   D   E   F
        for (final id in ['A', 'B', 'C', 'D', 'E', 'F']) {
          controller.addNode(createFlowNode(id));
        }
        connect('A', 'B');
        connect('A', 'C');
        connect('B', 'D');
        connect('B', 'E');
        connect('C', 'F');

        expect(controller.detectCycles(), isEmpty);
        expect(controller.hasCycles(), isFalse);
      });

      test('diamond pattern (DAG) has no cycles', () {
        //     A
        //    / \
        //   B   C
        //    \ /
        //     D
        for (final id in ['A', 'B', 'C', 'D']) {
          controller.addNode(createFlowNode(id));
        }
        connect('A', 'B');
        connect('A', 'C');
        connect('B', 'D');
        connect('C', 'D');

        expect(controller.detectCycles(), isEmpty);
        expect(controller.hasCycles(), isFalse);
      });

      test('complex DAG with multiple paths has no cycles', () {
        //     A
        //    /|\
        //   B C D
        //   |X| |
        //   E F G
        //    \|/
        //     H
        for (final id in ['A', 'B', 'C', 'D', 'E', 'F', 'G', 'H']) {
          controller.addNode(createFlowNode(id));
        }
        connect('A', 'B');
        connect('A', 'C');
        connect('A', 'D');
        connect('B', 'E');
        connect('B', 'F');
        connect('C', 'E');
        connect('C', 'F');
        connect('D', 'G');
        connect('E', 'H');
        connect('F', 'H');
        connect('G', 'H');

        expect(controller.detectCycles(), isEmpty);
        expect(controller.hasCycles(), isFalse);
      });

      test('parallel independent chains have no cycles', () {
        // Chain 1: A1 -> B1 -> C1
        // Chain 2: A2 -> B2 -> C2
        for (final chain in ['1', '2']) {
          for (final node in ['A', 'B', 'C']) {
            controller.addNode(createFlowNode('$node$chain'));
          }
          connect('A$chain', 'B$chain');
          connect('B$chain', 'C$chain');
        }

        expect(controller.detectCycles(), isEmpty);
        expect(controller.hasCycles(), isFalse);
      });
    });

    group('detectCycles() - Simple Cycles', () {
      test('detects simple two-node cycle', () {
        // A <-> B
        controller.addNode(createFlowNode('A'));
        controller.addNode(createFlowNode('B'));
        connect('A', 'B');
        connect('B', 'A');

        final cycles = controller.detectCycles();
        expect(cycles, isNotEmpty);
        expect(controller.hasCycles(), isTrue);
      });

      test('detects triangle cycle', () {
        // A -> B -> C -> A
        for (final id in ['A', 'B', 'C']) {
          controller.addNode(createFlowNode(id));
        }
        connect('A', 'B');
        connect('B', 'C');
        connect('C', 'A');

        final cycles = controller.detectCycles();
        expect(cycles, isNotEmpty);
        expect(controller.hasCycles(), isTrue);

        // Verify cycle contains all three nodes
        final allCycleNodes = cycles.expand((c) => c).toSet();
        expect(allCycleNodes, containsAll(['A', 'B', 'C']));
      });

      test('detects self-loop (node pointing to itself)', () {
        controller.addNode(createFlowNode('A'));
        // Self-connection
        final conn = createTestConnection(
          sourceNodeId: 'A',
          sourcePortId: 'A-out',
          targetNodeId: 'A',
          targetPortId: 'A-in',
        );
        controller.addConnection(conn);

        final cycles = controller.detectCycles();
        expect(cycles, isNotEmpty);
        expect(controller.hasCycles(), isTrue);
      });

      test('detects four-node cycle', () {
        // A -> B -> C -> D -> A
        for (final id in ['A', 'B', 'C', 'D']) {
          controller.addNode(createFlowNode(id));
        }
        connect('A', 'B');
        connect('B', 'C');
        connect('C', 'D');
        connect('D', 'A');

        final cycles = controller.detectCycles();
        expect(cycles, isNotEmpty);
        expect(controller.hasCycles(), isTrue);
      });

      test('detects long cycle with five nodes', () {
        // A -> B -> C -> D -> E -> A
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
        expect(controller.hasCycles(), isTrue);
      });
    });

    group('detectCycles() - Complex Cycles', () {
      test('detects cycle with entry branch', () {
        // Entry -> A, then cycle: A -> B -> C -> A
        controller.addNode(createFlowNode('Entry'));
        for (final id in ['A', 'B', 'C']) {
          controller.addNode(createFlowNode(id));
        }
        connect('Entry', 'A');
        connect('A', 'B');
        connect('B', 'C');
        connect('C', 'A');

        final cycles = controller.detectCycles();
        expect(cycles, isNotEmpty);

        // Entry should not be in any cycle
        final cycleNodes = cycles.expand((c) => c).toSet();
        expect(cycleNodes, isNot(contains('Entry')));
      });

      test('detects cycle with exit branch', () {
        // Cycle: A -> B -> C -> A, with C -> Exit
        for (final id in ['A', 'B', 'C', 'Exit']) {
          controller.addNode(createFlowNode(id));
        }
        connect('A', 'B');
        connect('B', 'C');
        connect('C', 'A');
        connect('C', 'Exit');

        final cycles = controller.detectCycles();
        expect(cycles, isNotEmpty);

        // Exit should not be in any cycle
        final cycleNodes = cycles.expand((c) => c).toSet();
        expect(cycleNodes, isNot(contains('Exit')));
      });

      test('detects nested cycles', () {
        // Outer cycle: A -> B -> D -> E -> A
        // Inner cycle: B -> C -> D (shares B and D with outer)
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

      test('detects multiple independent cycles', () {
        // Cycle 1: A -> B -> A
        controller.addNode(createFlowNode('A'));
        controller.addNode(createFlowNode('B'));
        connect('A', 'B');
        connect('B', 'A');

        // Cycle 2: C -> D -> C (disconnected)
        controller.addNode(createFlowNode('C'));
        controller.addNode(createFlowNode('D'));
        connect('C', 'D');
        connect('D', 'C');

        final cycles = controller.detectCycles();
        expect(cycles.length, greaterThanOrEqualTo(2));
      });

      test('detects cycle with isolated nodes nearby', () {
        // Cycle: A -> B -> A
        // Isolated: C, D
        controller.addNode(createFlowNode('A'));
        controller.addNode(createFlowNode('B'));
        controller.addNode(createFlowNode('C'));
        controller.addNode(createFlowNode('D'));
        connect('A', 'B');
        connect('B', 'A');

        final cycles = controller.detectCycles();
        expect(cycles, isNotEmpty);

        final cycleNodes = cycles.expand((c) => c).toSet();
        expect(cycleNodes, isNot(contains('C')));
        expect(cycleNodes, isNot(contains('D')));
      });
    });

    group('detectCycles() - Dynamic Cycle Detection', () {
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

        // Remove one connection
        controller.removeConnection('conn-ba');

        // Cycle should be gone
        expect(controller.detectCycles(), isEmpty);
      });

      test('removing node breaks cycle', () {
        for (final id in ['A', 'B', 'C']) {
          controller.addNode(createFlowNode(id));
        }
        connect('A', 'B');
        connect('B', 'C');
        connect('C', 'A');

        expect(controller.detectCycles(), isNotEmpty);

        controller.removeNode('B');

        expect(controller.detectCycles(), isEmpty);
      });

      test('adding connection creates cycle', () {
        controller.addNode(createFlowNode('A'));
        controller.addNode(createFlowNode('B'));
        connect('A', 'B');

        expect(controller.detectCycles(), isEmpty);

        // Add back-edge to create cycle
        connect('B', 'A');

        expect(controller.detectCycles(), isNotEmpty);
      });
    });

    group('getCycles() vs hasCycles() consistency', () {
      test(
        'getCycles and hasCycles return consistent results for no cycles',
        () {
          controller.addNode(createFlowNode('A'));
          controller.addNode(createFlowNode('B'));
          connect('A', 'B');

          expect(controller.getCycles(), isEmpty);
          expect(controller.hasCycles(), isFalse);
        },
      );

      test('getCycles and hasCycles return consistent results for cycles', () {
        controller.addNode(createFlowNode('A'));
        controller.addNode(createFlowNode('B'));
        connect('A', 'B');
        connect('B', 'A');

        expect(controller.getCycles(), isNotEmpty);
        expect(controller.hasCycles(), isTrue);
      });
    });
  });

  // ===========================================================================
  // PATH FINDING AND CONNECTIVITY TESTS
  // ===========================================================================

  group('Path Finding and Connectivity', () {
    group('getConnectionsForNode()', () {
      test('returns empty list for isolated node', () {
        controller.addNode(createFlowNode('A'));

        final connections = controller.getConnectionsForNode('A');
        expect(connections, isEmpty);
      });

      test('returns incoming connections', () {
        controller.addNode(createFlowNode('A'));
        controller.addNode(createFlowNode('B'));
        connect('A', 'B');

        final connectionsB = controller.getConnectionsForNode('B');
        expect(connectionsB.length, equals(1));
        expect(connectionsB.first.targetNodeId, equals('B'));
      });

      test('returns outgoing connections', () {
        controller.addNode(createFlowNode('A'));
        controller.addNode(createFlowNode('B'));
        connect('A', 'B');

        final connectionsA = controller.getConnectionsForNode('A');
        expect(connectionsA.length, equals(1));
        expect(connectionsA.first.sourceNodeId, equals('A'));
      });

      test('returns both incoming and outgoing connections', () {
        controller.addNode(createFlowNode('A'));
        controller.addNode(createFlowNode('B'));
        controller.addNode(createFlowNode('C'));
        connect('A', 'B');
        connect('B', 'C');

        final connectionsB = controller.getConnectionsForNode('B');
        expect(connectionsB.length, equals(2));
      });

      test('returns multiple connections from hub node', () {
        controller.addNode(createFlowNode('Hub'));
        for (int i = 1; i <= 5; i++) {
          controller.addNode(createFlowNode('N$i'));
          connect('Hub', 'N$i');
        }

        final connections = controller.getConnectionsForNode('Hub');
        expect(connections.length, equals(5));
      });

      test('returns empty for non-existent node', () {
        controller.addNode(createFlowNode('A'));

        final connections = controller.getConnectionsForNode('NonExistent');
        expect(connections, isEmpty);
      });
    });

    group('getConnectionsFromPort() and getConnectionsToPort()', () {
      test('getConnectionsFromPort returns outgoing connections from port', () {
        controller.addNode(createFlowNode('A'));
        controller.addNode(createFlowNode('B'));
        controller.addNode(createFlowNode('C'));
        connect('A', 'B');
        connect('A', 'C');

        final outgoing = controller.getConnectionsFromPort('A', 'A-out');
        expect(outgoing.length, equals(2));
      });

      test('getConnectionsToPort returns incoming connections to port', () {
        controller.addNode(createFlowNode('A'));
        controller.addNode(createFlowNode('B'));
        controller.addNode(createFlowNode('C'));
        connect('A', 'C');
        connect('B', 'C');

        final incoming = controller.getConnectionsToPort('C', 'C-in');
        expect(incoming.length, equals(2));
      });

      test('returns empty for port with no connections', () {
        controller.addNode(createFlowNode('A'));

        final outgoing = controller.getConnectionsFromPort('A', 'A-out');
        final incoming = controller.getConnectionsToPort('A', 'A-in');
        expect(outgoing, isEmpty);
        expect(incoming, isEmpty);
      });
    });

    group('Reachability Analysis', () {
      test('finds all directly connected nodes', () {
        controller.addNode(createFlowNode('A'));
        controller.addNode(createFlowNode('B'));
        controller.addNode(createFlowNode('C'));
        connect('A', 'B');
        connect('A', 'C');

        final connections = controller.getConnectionsForNode('A');
        final directTargets = connections
            .where((c) => c.sourceNodeId == 'A')
            .map((c) => c.targetNodeId)
            .toSet();

        expect(directTargets, containsAll(['B', 'C']));
      });

      test('can trace path through connections', () {
        // A -> B -> C -> D
        for (final id in ['A', 'B', 'C', 'D']) {
          controller.addNode(createFlowNode(id));
        }
        connect('A', 'B');
        connect('B', 'C');
        connect('C', 'D');

        // Trace path from A to D
        final reachable = <String>{};
        void trace(String nodeId) {
          if (reachable.contains(nodeId)) return;
          reachable.add(nodeId);
          final outgoing = controller.getConnectionsFromPort(
            nodeId,
            '$nodeId-out',
          );
          for (final conn in outgoing) {
            trace(conn.targetNodeId);
          }
        }

        trace('A');
        expect(reachable, containsAll(['A', 'B', 'C', 'D']));
      });
    });
  });

  // ===========================================================================
  // CONNECTED COMPONENTS TESTS
  // ===========================================================================

  group('Connected Components Analysis', () {
    group('getOrphanNodes()', () {
      test('returns all nodes when graph has no connections', () {
        for (final id in ['A', 'B', 'C']) {
          controller.addNode(createFlowNode(id));
        }

        final orphans = controller.getOrphanNodes();
        expect(orphans.length, equals(3));
        expect(orphans.map((n) => n.id), containsAll(['A', 'B', 'C']));
      });

      test('returns empty when all nodes are connected', () {
        controller.addNode(createFlowNode('A'));
        controller.addNode(createFlowNode('B'));
        controller.addNode(createFlowNode('C'));
        connect('A', 'B');
        connect('B', 'C');

        final orphans = controller.getOrphanNodes();
        expect(orphans, isEmpty);
      });

      test('returns only disconnected nodes', () {
        controller.addNode(createFlowNode('Connected1'));
        controller.addNode(createFlowNode('Connected2'));
        controller.addNode(createFlowNode('Orphan1'));
        controller.addNode(createFlowNode('Orphan2'));
        connect('Connected1', 'Connected2');

        final orphans = controller.getOrphanNodes();
        expect(orphans.length, equals(2));
        expect(orphans.map((n) => n.id), containsAll(['Orphan1', 'Orphan2']));
        expect(orphans.map((n) => n.id), isNot(contains('Connected1')));
        expect(orphans.map((n) => n.id), isNot(contains('Connected2')));
      });

      test('removing connection creates orphan', () {
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

      test('node with self-connection is not orphan', () {
        controller.addNode(createFlowNode('A'));
        final conn = createTestConnection(
          sourceNodeId: 'A',
          sourcePortId: 'A-out',
          targetNodeId: 'A',
          targetPortId: 'A-in',
        );
        controller.addConnection(conn);

        final orphans = controller.getOrphanNodes();
        expect(orphans, isEmpty);
      });
    });

    group('Component Identification (via connectivity analysis)', () {
      /// Helper to find connected component containing a node
      Set<String> findComponent(String startNodeId) {
        final visited = <String>{};
        void dfs(String nodeId) {
          if (visited.contains(nodeId)) return;
          visited.add(nodeId);

          final connections = controller.getConnectionsForNode(nodeId);
          for (final conn in connections) {
            dfs(conn.sourceNodeId);
            dfs(conn.targetNodeId);
          }
        }

        dfs(startNodeId);
        return visited;
      }

      test('identifies single component in fully connected graph', () {
        for (final id in ['A', 'B', 'C', 'D']) {
          controller.addNode(createFlowNode(id));
        }
        connect('A', 'B');
        connect('B', 'C');
        connect('C', 'D');

        final component = findComponent('A');
        expect(component.length, equals(4));
        expect(component, containsAll(['A', 'B', 'C', 'D']));
      });

      test('identifies separate components', () {
        // Component 1: A -> B
        controller.addNode(createFlowNode('A'));
        controller.addNode(createFlowNode('B'));
        connect('A', 'B');

        // Component 2: C -> D
        controller.addNode(createFlowNode('C'));
        controller.addNode(createFlowNode('D'));
        connect('C', 'D');

        // Isolated node (Component 3)
        controller.addNode(createFlowNode('E'));

        final comp1 = findComponent('A');
        final comp2 = findComponent('C');
        final comp3 = findComponent('E');

        expect(comp1, containsAll(['A', 'B']));
        expect(comp1.length, equals(2));

        expect(comp2, containsAll(['C', 'D']));
        expect(comp2.length, equals(2));

        expect(comp3, equals({'E'}));
      });

      test('handles bidirectional connections in component', () {
        controller.addNode(createFlowNode('A'));
        controller.addNode(createFlowNode('B'));
        connect('A', 'B');
        connect('B', 'A');

        final component = findComponent('A');
        expect(component, containsAll(['A', 'B']));
      });

      test('finds all components in graph', () {
        // Create 3 separate components
        for (int comp = 0; comp < 3; comp++) {
          final base = String.fromCharCode('A'.codeUnitAt(0) + comp * 2);
          final next = String.fromCharCode('A'.codeUnitAt(0) + comp * 2 + 1);
          controller.addNode(createFlowNode(base));
          controller.addNode(createFlowNode(next));
          connect(base, next);
        }

        // Find all components
        final allNodeIds = controller.nodes.keys.toSet();
        final components = <Set<String>>[];
        final visited = <String>{};

        for (final nodeId in allNodeIds) {
          if (!visited.contains(nodeId)) {
            final component = findComponent(nodeId);
            components.add(component);
            visited.addAll(component);
          }
        }

        expect(components.length, equals(3));
        expect(
          components.every((c) => c.length == 2),
          isTrue,
          reason: 'Each component should have 2 nodes',
        );
      });
    });
  });

  // ===========================================================================
  // GRAPH BOUNDS CALCULATION TESTS
  // ===========================================================================

  group('Graph Bounds Calculation', () {
    group('nodesBounds getter', () {
      test('returns Rect.zero for empty graph', () {
        expect(controller.nodesBounds, equals(Rect.zero));
      });

      test('calculates bounds for single node', () {
        final node = createTestNode(
          id: 'A',
          position: const Offset(100, 50),
          size: const Size(150, 100),
        );
        controller.addNode(node);

        final bounds = controller.nodesBounds;
        expect(bounds.left, equals(100));
        expect(bounds.top, equals(50));
        expect(bounds.right, equals(250)); // 100 + 150
        expect(bounds.bottom, equals(150)); // 50 + 100
      });

      test('calculates bounds for multiple nodes', () {
        controller.addNode(
          createTestNode(
            id: 'A',
            position: const Offset(0, 0),
            size: const Size(100, 100),
          ),
        );
        controller.addNode(
          createTestNode(
            id: 'B',
            position: const Offset(200, 150),
            size: const Size(100, 100),
          ),
        );

        final bounds = controller.nodesBounds;
        expect(bounds.left, equals(0));
        expect(bounds.top, equals(0));
        expect(bounds.right, equals(300)); // 200 + 100
        expect(bounds.bottom, equals(250)); // 150 + 100
      });

      test('handles negative positions', () {
        controller.addNode(
          createTestNode(
            id: 'A',
            position: const Offset(-100, -50),
            size: const Size(50, 50),
          ),
        );
        controller.addNode(
          createTestNode(
            id: 'B',
            position: const Offset(100, 100),
            size: const Size(50, 50),
          ),
        );

        final bounds = controller.nodesBounds;
        expect(bounds.left, equals(-100));
        expect(bounds.top, equals(-50));
        expect(bounds.right, equals(150));
        expect(bounds.bottom, equals(150));
      });

      test('updates bounds after node position change', () {
        controller.addNode(
          createTestNode(
            id: 'A',
            position: const Offset(0, 0),
            size: const Size(100, 100),
          ),
        );

        expect(controller.nodesBounds.right, equals(100));

        // Move node
        controller.setNodePosition('A', const Offset(200, 0));

        expect(controller.nodesBounds.left, equals(200));
        expect(controller.nodesBounds.right, equals(300));
      });

      test('updates bounds after node size change', () {
        controller.addNode(
          createTestNode(
            id: 'A',
            position: const Offset(0, 0),
            size: const Size(100, 100),
          ),
        );

        expect(controller.nodesBounds.right, equals(100));

        // Resize node
        controller.setNodeSize('A', const Size(200, 150));

        expect(controller.nodesBounds.right, equals(200));
        expect(controller.nodesBounds.bottom, equals(150));
      });

      test('updates bounds after node removal', () {
        controller.addNode(
          createTestNode(
            id: 'A',
            position: const Offset(0, 0),
            size: const Size(100, 100),
          ),
        );
        controller.addNode(
          createTestNode(
            id: 'B',
            position: const Offset(500, 500),
            size: const Size(100, 100),
          ),
        );

        expect(controller.nodesBounds.right, equals(600));
        expect(controller.nodesBounds.bottom, equals(600));

        controller.removeNode('B');

        expect(controller.nodesBounds.right, equals(100));
        expect(controller.nodesBounds.bottom, equals(100));
      });

      test('calculates bounds with varying node sizes', () {
        controller.addNode(
          createTestNode(
            id: 'Small',
            position: const Offset(0, 0),
            size: const Size(50, 50),
          ),
        );
        controller.addNode(
          createTestNode(
            id: 'Medium',
            position: const Offset(100, 100),
            size: const Size(100, 100),
          ),
        );
        controller.addNode(
          createTestNode(
            id: 'Large',
            position: const Offset(50, 50),
            size: const Size(200, 200),
          ),
        );

        final bounds = controller.nodesBounds;
        expect(bounds.left, equals(0));
        expect(bounds.top, equals(0));
        expect(bounds.right, equals(250)); // max(50, 200, 200+50=250)
        expect(bounds.bottom, equals(250));
      });

      test('handles nodes in all four quadrants', () {
        controller.addNode(
          createTestNode(
            id: 'TopLeft',
            position: const Offset(-200, -200),
            size: const Size(100, 100),
          ),
        );
        controller.addNode(
          createTestNode(
            id: 'TopRight',
            position: const Offset(100, -200),
            size: const Size(100, 100),
          ),
        );
        controller.addNode(
          createTestNode(
            id: 'BottomLeft',
            position: const Offset(-200, 100),
            size: const Size(100, 100),
          ),
        );
        controller.addNode(
          createTestNode(
            id: 'BottomRight',
            position: const Offset(100, 100),
            size: const Size(100, 100),
          ),
        );

        final bounds = controller.nodesBounds;
        expect(bounds.left, equals(-200));
        expect(bounds.top, equals(-200));
        expect(bounds.right, equals(200));
        expect(bounds.bottom, equals(200));
      });
    });

    group('getNodeBounds() for individual nodes', () {
      test('returns correct bounds for specific node', () {
        controller.addNode(
          createTestNode(
            id: 'A',
            position: const Offset(50, 100),
            size: const Size(150, 75),
          ),
        );

        final bounds = controller.getNodeBounds('A');
        expect(bounds, isNotNull);
        expect(bounds!.left, equals(50));
        expect(bounds.top, equals(100));
        expect(bounds.width, equals(150));
        expect(bounds.height, equals(75));
      });

      test('returns null for non-existent node', () {
        final bounds = controller.getNodeBounds('NonExistent');
        expect(bounds, isNull);
      });
    });

    group('Bounds with special node types', () {
      test('calculates bounds including GroupNode', () {
        controller.addNode(
          createTestNode(
            id: 'Regular',
            position: const Offset(0, 0),
            size: const Size(100, 100),
          ),
        );
        controller.addNode(
          createTestGroupNode<String>(
            id: 'Group',
            position: const Offset(200, 200),
            size: const Size(300, 300),
            data: 'group-data',
          ),
        );

        final bounds = controller.nodesBounds;
        expect(bounds.left, equals(0));
        expect(bounds.top, equals(0));
        expect(bounds.right, equals(500)); // 200 + 300
        expect(bounds.bottom, equals(500));
      });

      test('calculates bounds including CommentNode', () {
        controller.addNode(
          createTestNode(
            id: 'Regular',
            position: const Offset(0, 0),
            size: const Size(100, 100),
          ),
        );
        controller.addNode(
          createTestCommentNode<String>(
            id: 'Comment',
            position: const Offset(150, 150),
            width: 200,
            height: 100,
            data: 'comment-data',
          ),
        );

        final bounds = controller.nodesBounds;
        expect(bounds.left, equals(0));
        expect(bounds.top, equals(0));
        expect(bounds.right, equals(350)); // 150 + 200
        expect(bounds.bottom, equals(250)); // 150 + 100
      });
    });
  });

  // ===========================================================================
  // EDGE CASES AND STRESS TESTS
  // ===========================================================================

  group('Edge Cases and Stress Tests', () {
    test('handles large linear graph without stack overflow', () {
      const nodeCount = 100;

      // Create long chain
      for (int i = 0; i < nodeCount; i++) {
        controller.addNode(createFlowNode('N$i'));
        if (i > 0) {
          connect('N${i - 1}', 'N$i');
        }
      }

      // Should not throw
      expect(controller.detectCycles(), isEmpty);
      expect(controller.getOrphanNodes(), isEmpty);
      expect(controller.nodesBounds, isNotNull);
    });

    test('handles wide graph with many parallel edges', () {
      // Hub with many outgoing connections
      controller.addNode(createFlowNode('Hub'));
      for (int i = 0; i < 50; i++) {
        controller.addNode(createFlowNode('Target$i'));
        connect('Hub', 'Target$i');
      }

      final connections = controller.getConnectionsForNode('Hub');
      expect(connections.length, equals(50));
      expect(controller.detectCycles(), isEmpty);
    });

    test('handles complete graph on 5 nodes', () {
      // Complete graph K5 - every node connected to every other
      final nodes = ['A', 'B', 'C', 'D', 'E'];
      for (final id in nodes) {
        controller.addNode(createFlowNode(id));
      }

      for (final source in nodes) {
        for (final target in nodes) {
          if (source != target) {
            connect(source, target);
          }
        }
      }

      // Complete directed graph has many cycles
      expect(controller.hasCycles(), isTrue);

      // Every node should be connected
      expect(controller.getOrphanNodes(), isEmpty);
    });

    test('handles rapidly changing graph', () {
      // Add nodes
      for (int i = 0; i < 10; i++) {
        controller.addNode(createFlowNode('N$i'));
      }

      // Add connections
      for (int i = 0; i < 9; i++) {
        connect('N$i', 'N${i + 1}');
      }

      // Initial state
      expect(controller.nodeCount, equals(10));
      expect(controller.connectionCount, equals(9));

      // Remove half the nodes (N0-N4)
      // This breaks the chain, leaving N5-N9 still connected
      for (int i = 0; i < 5; i++) {
        controller.removeNode('N$i');
      }

      // Verify consistency
      expect(controller.nodeCount, equals(5));
      // N5-N9 remain connected: N5->N6->N7->N8->N9
      // Only N5 becomes an orphan (no incoming connection after N4 was removed)
      // Actually, N5-N9 are still in a chain, so none are orphans
      expect(controller.getOrphanNodes().length, equals(0));
    });

    test('bounds calculation handles zero-sized nodes', () {
      controller.addNode(
        createTestNode(
          id: 'ZeroSize',
          position: const Offset(100, 100),
          size: Size.zero,
        ),
      );

      final bounds = controller.nodesBounds;
      expect(bounds.left, equals(100));
      expect(bounds.top, equals(100));
      expect(bounds.width, equals(0));
      expect(bounds.height, equals(0));
    });

    test('cycle detection with same-port multiple connections', () {
      // Node with output connecting to multiple inputs on same target
      controller.addNode(
        createTestNode(
          id: 'A',
          outputPorts: [createOutputPort(id: 'A-out')],
        ),
      );
      controller.addNode(
        createTestNode(
          id: 'B',
          inputPorts: [
            createInputPort(id: 'B-in1'),
            createInputPort(id: 'B-in2'),
          ],
          outputPorts: [createOutputPort(id: 'B-out')],
        ),
      );

      final conn1 = createTestConnection(
        id: 'conn1',
        sourceNodeId: 'A',
        sourcePortId: 'A-out',
        targetNodeId: 'B',
        targetPortId: 'B-in1',
      );
      final conn2 = createTestConnection(
        id: 'conn2',
        sourceNodeId: 'A',
        sourcePortId: 'A-out',
        targetNodeId: 'B',
        targetPortId: 'B-in2',
      );
      controller.addConnection(conn1);
      controller.addConnection(conn2);

      // No cycle even with multiple edges between same nodes (in same direction)
      expect(controller.detectCycles(), isEmpty);
    });
  });
}
