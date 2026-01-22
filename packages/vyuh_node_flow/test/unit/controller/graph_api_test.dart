/// Unit tests for the NodeFlowController Graph API.
///
/// Tests cover:
/// - Graph operations (clear, load, export)
/// - Batch operations
/// - Graph traversal methods
/// - Node/connection queries
/// - Layout operations
/// - Selection operations
/// - Error handling
@Tags(['unit'])
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vyuh_node_flow/vyuh_node_flow.dart';

import '../../helpers/test_factories.dart';

void main() {
  setUp(() {
    resetTestCounters();
  });

  // ===========================================================================
  // Graph Loading & Export
  // ===========================================================================

  group('Graph Loading & Export', () {
    group('loadGraph', () {
      test('loads nodes from graph', () {
        final controller = createTestController();
        final node1 = createTestNode(id: 'node-1');
        final node2 = createTestNode(id: 'node-2');
        final graph = NodeGraph<String, dynamic>(nodes: [node1, node2]);

        controller.loadGraph(graph);

        expect(controller.nodeCount, equals(2));
        expect(controller.getNode('node-1'), isNotNull);
        expect(controller.getNode('node-2'), isNotNull);
      });

      test('loads connections from graph', () {
        final controller = createTestController();
        final nodeA = createTestNodeWithOutputPort(id: 'node-a');
        final nodeB = createTestNodeWithInputPort(id: 'node-b');
        final connection = createTestConnection(
          sourceNodeId: 'node-a',
          targetNodeId: 'node-b',
        );
        final graph = NodeGraph<String, dynamic>(
          nodes: [nodeA, nodeB],
          connections: [connection],
        );

        controller.loadGraph(graph);

        expect(controller.connectionCount, equals(1));
      });

      test('loads viewport from graph', () {
        final controller = createTestController();
        final viewport = createTestViewport(x: 100, y: 200, zoom: 1.5);
        final graph = NodeGraph<String, dynamic>(viewport: viewport);

        controller.loadGraph(graph);

        expect(controller.viewport.x, equals(100));
        expect(controller.viewport.y, equals(200));
        expect(controller.viewport.zoom, equals(1.5));
      });

      test('clears existing graph before loading', () {
        final controller = createTestController();
        controller.addNode(createTestNode(id: 'existing-node'));

        final newNode = createTestNode(id: 'new-node');
        final graph = NodeGraph<String, dynamic>(nodes: [newNode]);
        controller.loadGraph(graph);

        expect(controller.nodeCount, equals(1));
        expect(controller.getNode('existing-node'), isNull);
        expect(controller.getNode('new-node'), isNotNull);
      });

      test('clears existing connections before loading', () {
        final controller = createConnectedNodesController();
        expect(controller.connectionCount, equals(1));

        final graph = NodeGraph<String, dynamic>(nodes: []);
        controller.loadGraph(graph);

        expect(controller.connectionCount, equals(0));
      });

      test('clears existing selections before loading', () {
        final controller = createTestController();
        controller.addNode(createTestNode(id: 'node-1'));
        controller.selectNode('node-1');
        expect(controller.selectedNodeIds, isNotEmpty);

        controller.loadGraph(const NodeGraph<String, dynamic>());

        expect(controller.selectedNodeIds, isEmpty);
      });

      test('loads empty graph successfully', () {
        final controller = createTestController();
        controller.addNode(createTestNode(id: 'existing'));

        controller.loadGraph(const NodeGraph<String, dynamic>());

        expect(controller.nodeCount, equals(0));
        expect(controller.connectionCount, equals(0));
      });
    });

    group('exportGraph', () {
      test('exports all nodes', () {
        final controller = createTestController();
        controller.addNode(createTestNode(id: 'node-1'));
        controller.addNode(createTestNode(id: 'node-2'));
        controller.addNode(createTestNode(id: 'node-3'));

        final graph = controller.exportGraph();

        expect(graph.nodes, hasLength(3));
        expect(
          graph.nodes.map((n) => n.id),
          containsAll(['node-1', 'node-2', 'node-3']),
        );
      });

      test('exports all connections', () {
        final controller = createConnectedNodesController();

        final graph = controller.exportGraph();

        expect(graph.connections, hasLength(1));
      });

      test('exports current viewport', () {
        final controller = createTestController(
          initialViewport: createTestViewport(x: 50, y: 75, zoom: 2.0),
        );

        final graph = controller.exportGraph();

        expect(graph.viewport.x, equals(50));
        expect(graph.viewport.y, equals(75));
        expect(graph.viewport.zoom, equals(2.0));
      });

      test('exports empty graph with default viewport', () {
        final controller = createTestController();

        final graph = controller.exportGraph();

        expect(graph.nodes, isEmpty);
        expect(graph.connections, isEmpty);
        expect(graph.viewport.zoom, equals(1.0));
      });

      test('roundtrips graph through load and export', () {
        final controller = createTestController();
        final nodeA = createTestNodeWithOutputPort(
          id: 'node-a',
          position: const Offset(100, 200),
        );
        final nodeB = createTestNodeWithInputPort(
          id: 'node-b',
          position: const Offset(300, 400),
        );
        final connection = createTestConnection(
          sourceNodeId: 'node-a',
          targetNodeId: 'node-b',
        );
        final viewport = createTestViewport(x: 10, y: 20, zoom: 1.25);
        final originalGraph = NodeGraph<String, dynamic>(
          nodes: [nodeA, nodeB],
          connections: [connection],
          viewport: viewport,
        );

        controller.loadGraph(originalGraph);
        final exportedGraph = controller.exportGraph();

        expect(exportedGraph.nodes, hasLength(2));
        expect(exportedGraph.connections, hasLength(1));
        expect(exportedGraph.viewport.x, equals(10));
        expect(exportedGraph.viewport.y, equals(20));
        expect(exportedGraph.viewport.zoom, equals(1.25));
      });
    });

    group('clearGraph', () {
      test('removes all nodes', () {
        final controller = createTestController();
        controller.addNode(createTestNode(id: 'node-1'));
        controller.addNode(createTestNode(id: 'node-2'));

        controller.clearGraph();

        expect(controller.nodeCount, equals(0));
      });

      test('removes all connections', () {
        final controller = createConnectedNodesController();

        controller.clearGraph();

        expect(controller.connectionCount, equals(0));
      });

      test('clears node selections', () {
        final controller = createTestController();
        controller.addNode(createTestNode(id: 'node-1'));
        controller.selectNode('node-1');

        controller.clearGraph();

        expect(controller.selectedNodeIds, isEmpty);
      });

      test('clears connection selections', () {
        final controller = createConnectedNodesController();
        controller.selectConnection(controller.connections.first.id);

        controller.clearGraph();

        expect(controller.selectedConnectionIds, isEmpty);
      });

      test('does nothing on already empty graph', () {
        final controller = createTestController();

        // Should not throw
        controller.clearGraph();

        expect(controller.nodeCount, equals(0));
      });

      test('clears graph with GroupNode', () {
        final controller = createTestController();
        final regularNode = createTestNode(id: 'regular-node');
        final groupNode = createTestGroupNode<String>(
          id: 'group-node',
          data: 'group-data',
          nodeIds: {'regular-node'},
        );
        controller.addNode(regularNode);
        controller.addNode(groupNode);

        controller.clearGraph();

        expect(controller.nodeCount, equals(0));
      });

      test('clears graph with CommentNode', () {
        final controller = createTestController();
        final commentNode = createTestCommentNode<String>(
          id: 'comment-node',
          data: 'comment-data',
        );
        controller.addNode(commentNode);

        controller.clearGraph();

        expect(controller.nodeCount, equals(0));
      });
    });
  });

  // ===========================================================================
  // Graph Analysis
  // ===========================================================================

  group('Graph Analysis', () {
    group('getOrphanNodes', () {
      test('returns nodes with no connections', () {
        final controller = createTestController();
        controller.addNode(createTestNode(id: 'orphan-1'));
        controller.addNode(createTestNode(id: 'orphan-2'));

        final orphans = controller.getOrphanNodes();

        expect(orphans, hasLength(2));
        expect(orphans.map((n) => n.id), containsAll(['orphan-1', 'orphan-2']));
      });

      test('excludes connected nodes', () {
        final nodeA = createTestNodeWithOutputPort(id: 'connected-a');
        final nodeB = createTestNodeWithInputPort(id: 'connected-b');
        final orphan = createTestNode(id: 'orphan');
        final connection = createTestConnection(
          sourceNodeId: 'connected-a',
          targetNodeId: 'connected-b',
        );
        final controller = createTestController(
          nodes: [nodeA, nodeB, orphan],
          connections: [connection],
        );

        final orphans = controller.getOrphanNodes();

        expect(orphans, hasLength(1));
        expect(orphans.first.id, equals('orphan'));
      });

      test('returns empty list when all nodes connected', () {
        final controller = createConnectedNodesController();

        final orphans = controller.getOrphanNodes();

        expect(orphans, isEmpty);
      });

      test('returns empty list for empty graph', () {
        final controller = createTestController();

        final orphans = controller.getOrphanNodes();

        expect(orphans, isEmpty);
      });

      test('considers both source and target nodes as connected', () {
        final nodeA = createTestNodeWithOutputPort(id: 'source');
        final nodeB = createTestNodeWithInputPort(id: 'target');
        final connection = createTestConnection(
          sourceNodeId: 'source',
          targetNodeId: 'target',
        );
        final controller = createTestController(
          nodes: [nodeA, nodeB],
          connections: [connection],
        );

        final orphans = controller.getOrphanNodes();

        expect(orphans, isEmpty);
      });
    });

    group('detectCycles', () {
      test('returns empty list for DAG (no cycles)', () {
        final nodeA = createTestNodeWithOutputPort(id: 'a', portId: 'out');
        final nodeB = createTestNodeWithPorts(id: 'b');
        final nodeC = createTestNodeWithInputPort(id: 'c', portId: 'in');
        final conn1 = createTestConnection(
          sourceNodeId: 'a',
          sourcePortId: 'out',
          targetNodeId: 'b',
          targetPortId: 'input-1',
        );
        final conn2 = createTestConnection(
          sourceNodeId: 'b',
          sourcePortId: 'output-1',
          targetNodeId: 'c',
          targetPortId: 'in',
        );
        final controller = createTestController(
          nodes: [nodeA, nodeB, nodeC],
          connections: [conn1, conn2],
        );

        final cycles = controller.detectCycles();

        expect(cycles, isEmpty);
      });

      test('detects simple two-node cycle', () {
        final nodeA = createTestNodeWithPorts(id: 'a');
        final nodeB = createTestNodeWithPorts(id: 'b');
        final conn1 = createTestConnection(
          sourceNodeId: 'a',
          sourcePortId: 'output-1',
          targetNodeId: 'b',
          targetPortId: 'input-1',
        );
        final conn2 = createTestConnection(
          sourceNodeId: 'b',
          sourcePortId: 'output-1',
          targetNodeId: 'a',
          targetPortId: 'input-1',
        );
        final controller = createTestController(
          nodes: [nodeA, nodeB],
          connections: [conn1, conn2],
        );

        final cycles = controller.detectCycles();

        expect(cycles, isNotEmpty);
      });

      test('detects triangle cycle', () {
        final nodeA = createTestNodeWithPorts(id: 'a');
        final nodeB = createTestNodeWithPorts(id: 'b');
        final nodeC = createTestNodeWithPorts(id: 'c');
        final conn1 = createTestConnection(
          sourceNodeId: 'a',
          sourcePortId: 'output-1',
          targetNodeId: 'b',
          targetPortId: 'input-1',
        );
        final conn2 = createTestConnection(
          sourceNodeId: 'b',
          sourcePortId: 'output-1',
          targetNodeId: 'c',
          targetPortId: 'input-1',
        );
        final conn3 = createTestConnection(
          sourceNodeId: 'c',
          sourcePortId: 'output-1',
          targetNodeId: 'a',
          targetPortId: 'input-1',
        );
        final controller = createTestController(
          nodes: [nodeA, nodeB, nodeC],
          connections: [conn1, conn2, conn3],
        );

        final cycles = controller.detectCycles();

        expect(cycles, isNotEmpty);
      });

      test('returns empty list for empty graph', () {
        final controller = createTestController();

        final cycles = controller.detectCycles();

        expect(cycles, isEmpty);
      });

      test('returns empty list for disconnected nodes', () {
        final controller = createTestController();
        controller.addNode(createTestNode(id: 'node-1'));
        controller.addNode(createTestNode(id: 'node-2'));

        final cycles = controller.detectCycles();

        expect(cycles, isEmpty);
      });

      test('cycle path contains the cycle nodes', () {
        final nodeA = createTestNodeWithPorts(id: 'cycle-a');
        final nodeB = createTestNodeWithPorts(id: 'cycle-b');
        final conn1 = createTestConnection(
          sourceNodeId: 'cycle-a',
          sourcePortId: 'output-1',
          targetNodeId: 'cycle-b',
          targetPortId: 'input-1',
        );
        final conn2 = createTestConnection(
          sourceNodeId: 'cycle-b',
          sourcePortId: 'output-1',
          targetNodeId: 'cycle-a',
          targetPortId: 'input-1',
        );
        final controller = createTestController(
          nodes: [nodeA, nodeB],
          connections: [conn1, conn2],
        );

        final cycles = controller.detectCycles();

        expect(cycles, isNotEmpty);
        final cyclePath = cycles.first;
        expect(cyclePath, contains('cycle-a'));
        expect(cyclePath, contains('cycle-b'));
      });

      test('detects self-loop cycle', () {
        final node = createTestNodeWithPorts(id: 'self');
        final selfLoop = createTestConnection(
          sourceNodeId: 'self',
          sourcePortId: 'output-1',
          targetNodeId: 'self',
          targetPortId: 'input-1',
        );
        final controller = createTestController(
          nodes: [node],
          connections: [selfLoop],
        );

        final cycles = controller.detectCycles();

        expect(cycles, isNotEmpty);
      });
    });

    group('nodesBounds', () {
      test('returns Rect.zero for empty graph', () {
        final controller = createTestController();

        final bounds = controller.nodesBounds;

        expect(bounds, equals(Rect.zero));
      });

      test('returns correct bounds for single node', () {
        final controller = createTestController();
        controller.addNode(
          createTestNode(
            id: 'node-1',
            position: const Offset(100, 200),
            size: const Size(150, 100),
          ),
        );

        final bounds = controller.nodesBounds;

        expect(bounds.left, equals(100));
        expect(bounds.top, equals(200));
        expect(bounds.width, equals(150));
        expect(bounds.height, equals(100));
      });

      test('returns bounding box for multiple nodes', () {
        final controller = createTestController();
        controller.addNode(
          createTestNode(
            id: 'node-1',
            position: const Offset(0, 0),
            size: const Size(100, 100),
          ),
        );
        controller.addNode(
          createTestNode(
            id: 'node-2',
            position: const Offset(200, 300),
            size: const Size(100, 100),
          ),
        );

        final bounds = controller.nodesBounds;

        expect(bounds.left, equals(0));
        expect(bounds.top, equals(0));
        expect(bounds.right, equals(300)); // 200 + 100
        expect(bounds.bottom, equals(400)); // 300 + 100
      });

      test('calculates bounds correctly with negative positions', () {
        final controller = createTestController();
        controller.addNode(
          createTestNode(
            id: 'node-1',
            position: const Offset(-100, -50),
            size: const Size(50, 50),
          ),
        );
        controller.addNode(
          createTestNode(
            id: 'node-2',
            position: const Offset(100, 100),
            size: const Size(50, 50),
          ),
        );

        final bounds = controller.nodesBounds;

        expect(bounds.left, equals(-100));
        expect(bounds.top, equals(-50));
        expect(bounds.right, equals(150)); // 100 + 50
        expect(bounds.bottom, equals(150)); // 100 + 50
      });
    });
  });

  // ===========================================================================
  // Layout Operations
  // ===========================================================================

  group('Layout Operations', () {
    group('arrangeNodesInGrid', () {
      test('arranges nodes in grid pattern', () {
        final controller = createTestController();
        controller.addNode(
          createTestNode(id: 'node-1', position: const Offset(500, 500)),
        );
        controller.addNode(
          createTestNode(id: 'node-2', position: const Offset(600, 600)),
        );
        controller.addNode(
          createTestNode(id: 'node-3', position: const Offset(700, 700)),
        );
        controller.addNode(
          createTestNode(id: 'node-4', position: const Offset(800, 800)),
        );

        controller.arrangeNodesInGrid(spacing: 100.0);

        // 4 nodes should be arranged in a 2x2 grid
        final positions = controller.nodes.values
            .map((n) => n.position.value)
            .toList();

        // Should have positions at (0,0), (100,0), (0,100), (100,100)
        expect(positions, hasLength(4));
      });

      test('uses default spacing of 150', () {
        final controller = createTestController();
        controller.addNode(createTestNode(id: 'node-1'));
        controller.addNode(createTestNode(id: 'node-2'));

        controller.arrangeNodesInGrid();

        final node1 = controller.getNode('node-1')!;
        final node2 = controller.getNode('node-2')!;

        // With 2 nodes and ceil(sqrt(2)) = 2 columns
        // node-1 at (0,0), node-2 at (150,0)
        expect(node1.position.value.dx, equals(0));
        expect(node2.position.value.dx, equals(150));
      });

      test('handles single node', () {
        final controller = createTestController();
        controller.addNode(
          createTestNode(id: 'single', position: const Offset(999, 999)),
        );

        controller.arrangeNodesInGrid();

        final node = controller.getNode('single')!;
        expect(node.position.value, equals(Offset.zero));
      });

      test('handles empty graph', () {
        final controller = createTestController();

        // Should not throw
        controller.arrangeNodesInGrid();

        expect(controller.nodeCount, equals(0));
      });

      test('updates visual position with snapping', () {
        final controller = createTestController(
          config: NodeFlowConfig(
            extensions: [
              SnapExtension([GridSnapDelegate(gridSize: 10.0, enabled: true)]),
            ],
          ),
        );
        controller.addNode(createTestNode(id: 'node-1'));

        controller.arrangeNodesInGrid(spacing: 100);

        final node = controller.getNode('node-1')!;
        expect(node.visualPosition.value.dx % 10, equals(0));
        expect(node.visualPosition.value.dy % 10, equals(0));
      });
    });

    group('arrangeNodesHierarchically', () {
      test('groups nodes by type', () {
        final controller = createTestController();
        controller.addNode(createTestNode(id: 'process-1', type: 'process'));
        controller.addNode(createTestNode(id: 'process-2', type: 'process'));
        controller.addNode(createTestNode(id: 'decision-1', type: 'decision'));

        controller.arrangeNodesHierarchically();

        // Nodes of same type should be on same Y coordinate
        final process1 = controller.getNode('process-1')!;
        final process2 = controller.getNode('process-2')!;
        final decision1 = controller.getNode('decision-1')!;

        expect(process1.position.value.dy, equals(process2.position.value.dy));
        expect(
          decision1.position.value.dy,
          isNot(equals(process1.position.value.dy)),
        );
      });

      test('spaces nodes horizontally by 200', () {
        final controller = createTestController();
        controller.addNode(createTestNode(id: 'node-1', type: 'test'));
        controller.addNode(createTestNode(id: 'node-2', type: 'test'));

        controller.arrangeNodesHierarchically();

        final node1 = controller.getNode('node-1')!;
        final node2 = controller.getNode('node-2')!;

        // Same type nodes spaced horizontally
        expect(
          (node2.position.value.dx - node1.position.value.dx).abs(),
          equals(200),
        );
      });

      test('spaces type groups vertically by 150', () {
        final controller = createTestController();
        controller.addNode(createTestNode(id: 'type-a', type: 'typeA'));
        controller.addNode(createTestNode(id: 'type-b', type: 'typeB'));

        controller.arrangeNodesHierarchically();

        final nodeA = controller.getNode('type-a')!;
        final nodeB = controller.getNode('type-b')!;

        expect(
          (nodeB.position.value.dy - nodeA.position.value.dy).abs(),
          equals(150),
        );
      });

      test('handles empty graph', () {
        final controller = createTestController();

        // Should not throw
        controller.arrangeNodesHierarchically();
      });

      test('handles single node', () {
        final controller = createTestController();
        controller.addNode(createTestNode(id: 'single', type: 'single'));

        controller.arrangeNodesHierarchically();

        final node = controller.getNode('single')!;
        expect(node.position.value, equals(Offset.zero));
      });
    });
  });

  // ===========================================================================
  // Batch Selection Operations
  // ===========================================================================

  group('Batch Selection Operations', () {
    group('clearSelection', () {
      test('clears node selection', () {
        final controller = createTestController();
        controller.addNode(createTestNode(id: 'node-1'));
        controller.addNode(createTestNode(id: 'node-2'));
        controller.selectNodes(['node-1', 'node-2']);

        controller.clearSelection();

        expect(controller.selectedNodeIds, isEmpty);
      });

      test('clears connection selection', () {
        final controller = createConnectedNodesController();
        controller.selectConnection(controller.connections.first.id);

        controller.clearSelection();

        expect(controller.selectedConnectionIds, isEmpty);
      });

      test('clears both node and connection selection', () {
        final controller = createConnectedNodesController();
        controller.selectNode('node-a');
        controller.selectConnection(
          controller.connections.first.id,
          toggle: true,
        );

        controller.clearSelection();

        expect(controller.selectedNodeIds, isEmpty);
        expect(controller.selectedConnectionIds, isEmpty);
      });

      test('does nothing when nothing is selected', () {
        final controller = createTestController();

        // Should not throw
        controller.clearSelection();

        expect(controller.selectedNodeIds, isEmpty);
        expect(controller.selectedConnectionIds, isEmpty);
      });

      test('clears node editing state', () {
        final controller = createTestController();
        final comment = createTestCommentNode<String>(
          id: 'comment',
          data: 'test',
        );
        controller.addNode(comment);
        comment.isEditing = true;

        controller.clearSelection();

        expect(comment.isEditing, isFalse);
      });
    });

    group('selectAllNodes', () {
      test('selects all selectable nodes', () {
        final controller = createTestController();
        controller.addNode(createTestNode(id: 'node-1'));
        controller.addNode(createTestNode(id: 'node-2'));
        controller.addNode(createTestNode(id: 'node-3'));

        controller.selectAllNodes();

        expect(controller.selectedNodeIds, hasLength(3));
      });

      test('clears previous selection first', () {
        final controller = createTestController();
        controller.addNode(createTestNode(id: 'node-1'));
        controller.addNode(createTestNode(id: 'node-2'));
        controller.selectNode('node-1');

        controller.selectAllNodes();

        expect(controller.selectedNodeIds, hasLength(2));
      });

      test('marks all nodes as selected', () {
        final controller = createTestController();
        controller.addNode(createTestNode(id: 'node-1'));
        controller.addNode(createTestNode(id: 'node-2'));

        controller.selectAllNodes();

        expect(controller.getNode('node-1')!.isSelected, isTrue);
        expect(controller.getNode('node-2')!.isSelected, isTrue);
      });

      test('does not select non-selectable nodes', () {
        final controller = createTestController();
        controller.addNode(createTestNode(id: 'normal'));
        // Explicitly create a non-selectable node
        controller.addNode(
          Node<String>(
            id: 'non-selectable',
            type: 'test',
            position: Offset.zero,
            data: 'test',
            selectable: false,
          ),
        );

        controller.selectAllNodes();

        // Only selectable nodes should be selected
        expect(controller.selectedNodeIds, contains('normal'));
        expect(controller.selectedNodeIds, isNot(contains('non-selectable')));
      });

      test('handles empty graph', () {
        final controller = createTestController();

        controller.selectAllNodes();

        expect(controller.selectedNodeIds, isEmpty);
      });
    });

    group('selectAllConnections', () {
      test('selects all connections', () {
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

        GraphApi(controller).selectAllConnections();

        expect(controller.selectedConnectionIds, hasLength(2));
        expect(
          controller.selectedConnectionIds,
          containsAll(['conn-1', 'conn-2']),
        );
      });

      test('clears previous selection first', () {
        final controller = createConnectedNodesController();
        final connId = controller.connections.first.id;
        controller.selectConnection(connId);

        GraphApi(controller).selectAllConnections();

        expect(controller.selectedConnectionIds, hasLength(1));
      });

      test('handles empty connections', () {
        final controller = createTestController();

        GraphApi(controller).selectAllConnections();

        expect(controller.selectedConnectionIds, isEmpty);
      });
    });

    group('selectNodesByType', () {
      test('selects only nodes of specified type', () {
        final controller = createTestController();
        controller.addNode(createTestNode(id: 'process-1', type: 'process'));
        controller.addNode(createTestNode(id: 'process-2', type: 'process'));
        controller.addNode(createTestNode(id: 'decision-1', type: 'decision'));

        controller.selectNodesByType('process');

        expect(controller.selectedNodeIds, hasLength(2));
        expect(
          controller.selectedNodeIds,
          containsAll(['process-1', 'process-2']),
        );
        expect(controller.selectedNodeIds, isNot(contains('decision-1')));
      });

      test('clears previous selection', () {
        final controller = createTestController();
        controller.addNode(createTestNode(id: 'process', type: 'process'));
        controller.addNode(createTestNode(id: 'decision', type: 'decision'));
        controller.selectNode('decision');

        controller.selectNodesByType('process');

        expect(controller.selectedNodeIds, hasLength(1));
        expect(controller.selectedNodeIds.first, equals('process'));
      });

      test('deselects nodes not of specified type', () {
        final controller = createTestController();
        controller.addNode(createTestNode(id: 'process', type: 'process'));
        controller.addNode(createTestNode(id: 'decision', type: 'decision'));
        controller.selectNodes(['process', 'decision']);

        controller.selectNodesByType('process');

        expect(controller.getNode('decision')!.isSelected, isFalse);
      });

      test('selects nothing for non-existent type', () {
        final controller = createTestController();
        controller.addNode(createTestNode(id: 'node-1', type: 'process'));

        controller.selectNodesByType('non-existent');

        expect(controller.selectedNodeIds, isEmpty);
      });

      test('handles empty graph', () {
        final controller = createTestController();

        controller.selectNodesByType('any');

        expect(controller.selectedNodeIds, isEmpty);
      });
    });

    group('invertSelection', () {
      test('inverts node selection', () {
        final controller = createTestController();
        controller.addNode(createTestNode(id: 'node-1'));
        controller.addNode(createTestNode(id: 'node-2'));
        controller.addNode(createTestNode(id: 'node-3'));
        controller.selectNodes(['node-1']);

        controller.invertSelection();

        expect(controller.selectedNodeIds, containsAll(['node-2', 'node-3']));
        expect(controller.selectedNodeIds, isNot(contains('node-1')));
      });

      test('selects all when nothing selected', () {
        final controller = createTestController();
        controller.addNode(createTestNode(id: 'node-1'));
        controller.addNode(createTestNode(id: 'node-2'));

        controller.invertSelection();

        expect(controller.selectedNodeIds, hasLength(2));
      });

      test('deselects all when all selected', () {
        final controller = createTestController();
        controller.addNode(createTestNode(id: 'node-1'));
        controller.addNode(createTestNode(id: 'node-2'));
        controller.selectAllNodes();

        controller.invertSelection();

        expect(controller.selectedNodeIds, isEmpty);
      });

      test('updates node selected state', () {
        final controller = createTestController();
        controller.addNode(createTestNode(id: 'selected'));
        controller.addNode(createTestNode(id: 'unselected'));
        controller.selectNode('selected');

        controller.invertSelection();

        expect(controller.getNode('selected')!.isSelected, isFalse);
        expect(controller.getNode('unselected')!.isSelected, isTrue);
      });

      test('handles empty graph', () {
        final controller = createTestController();

        controller.invertSelection();

        expect(controller.selectedNodeIds, isEmpty);
      });
    });

    group('selectSpecificNodes', () {
      test('selects specified nodes', () {
        final controller = createTestController();
        controller.addNode(createTestNode(id: 'node-1'));
        controller.addNode(createTestNode(id: 'node-2'));
        controller.addNode(createTestNode(id: 'node-3'));

        controller.selectSpecificNodes(['node-1', 'node-3']);

        expect(controller.selectedNodeIds, hasLength(2));
        expect(controller.selectedNodeIds, containsAll(['node-1', 'node-3']));
      });

      test('clears existing selection', () {
        final controller = createTestController();
        controller.addNode(createTestNode(id: 'node-1'));
        controller.addNode(createTestNode(id: 'node-2'));
        controller.selectNode('node-1');

        controller.selectSpecificNodes(['node-2']);

        expect(controller.selectedNodeIds, hasLength(1));
        expect(controller.selectedNodeIds.first, equals('node-2'));
      });

      test('ignores non-existent node IDs', () {
        final controller = createTestController();
        controller.addNode(createTestNode(id: 'existing'));

        controller.selectSpecificNodes(['existing', 'non-existent']);

        expect(controller.selectedNodeIds, hasLength(1));
        expect(controller.selectedNodeIds.first, equals('existing'));
      });

      test('handles empty node list', () {
        final controller = createTestController();
        controller.addNode(createTestNode(id: 'node-1'));
        controller.selectNode('node-1');

        controller.selectSpecificNodes([]);

        expect(controller.selectedNodeIds, isEmpty);
      });

      test('marks nodes as selected', () {
        final controller = createTestController();
        controller.addNode(createTestNode(id: 'node-1'));
        controller.addNode(createTestNode(id: 'node-2'));

        controller.selectSpecificNodes(['node-1']);

        expect(controller.getNode('node-1')!.isSelected, isTrue);
        expect(controller.getNode('node-2')!.isSelected, isFalse);
      });
    });

    group('deleteSelectedWithConfirmation', () {
      test('deletes selected nodes in design mode', () async {
        final controller = createTestController();
        controller.addNode(createTestNode(id: 'node-1'));
        controller.addNode(createTestNode(id: 'node-2'));
        controller.selectNode('node-1');

        await controller.deleteSelectedWithConfirmation();

        expect(controller.getNode('node-1'), isNull);
        expect(controller.getNode('node-2'), isNotNull);
      });

      test('deletes selected connections in design mode', () async {
        final controller = createConnectedNodesController();
        controller.selectConnection(controller.connections.first.id);

        await controller.deleteSelectedWithConfirmation();

        expect(controller.connectionCount, equals(0));
      });

      test('does not delete in preview mode', () async {
        final controller = createTestController();
        controller.addNode(createTestNode(id: 'node-1'));
        controller.selectNode('node-1');
        controller.setBehavior(NodeFlowBehavior.preview);

        await controller.deleteSelectedWithConfirmation();

        expect(controller.getNode('node-1'), isNotNull);
      });

      test('does not delete in present mode', () async {
        final controller = createTestController();
        controller.addNode(createTestNode(id: 'node-1'));
        controller.selectNode('node-1');
        controller.setBehavior(NodeFlowBehavior.present);

        await controller.deleteSelectedWithConfirmation();

        expect(controller.getNode('node-1'), isNotNull);
      });

      test('does nothing when nothing selected', () async {
        final controller = createTestController();
        controller.addNode(createTestNode(id: 'node-1'));

        await controller.deleteSelectedWithConfirmation();

        expect(controller.nodeCount, equals(1));
      });
    });
  });

  // ===========================================================================
  // Batch Operations
  // ===========================================================================

  group('Batch Operations', () {
    test('batch wraps operations with BatchStarted and BatchEnded events', () {
      final controller = createTestController();
      final events = <GraphEvent>[];

      // Add a simple extension to capture events
      controller.addExtension(_TestEventCapture(events));

      controller.batch('test-batch', () {
        controller.addNode(createTestNode(id: 'node-1'));
        controller.addNode(createTestNode(id: 'node-2'));
      });

      expect(events.first, isA<BatchStarted>());
      expect((events.first as BatchStarted).reason, equals('test-batch'));
      expect(events.last, isA<BatchEnded>());
    });

    test('nested batches only emit outer batch events', () {
      final controller = createTestController();
      final events = <GraphEvent>[];
      controller.addExtension(_TestEventCapture(events));

      controller.batch('outer', () {
        controller.addNode(createTestNode(id: 'node-1'));
        controller.batch('inner', () {
          controller.addNode(createTestNode(id: 'node-2'));
        });
      });

      final batchStarts = events.whereType<BatchStarted>().toList();
      final batchEnds = events.whereType<BatchEnded>().toList();

      // Only one BatchStarted and one BatchEnded
      expect(batchStarts, hasLength(1));
      expect(batchEnds, hasLength(1));
      expect(batchStarts.first.reason, equals('outer'));
    });

    test('batch emits BatchEnded even if operations throw', () {
      final controller = createTestController();
      final events = <GraphEvent>[];
      controller.addExtension(_TestEventCapture(events));

      try {
        controller.batch('error-batch', () {
          controller.addNode(createTestNode(id: 'node-1'));
          throw Exception('Test error');
        });
      } catch (_) {
        // Expected
      }

      expect(events.first, isA<BatchStarted>());
      expect(events.last, isA<BatchEnded>());
    });
  });

  // ===========================================================================
  // Edge Cases
  // ===========================================================================

  group('Edge Cases', () {
    test('graph operations on empty controller do not throw', () {
      final controller = createTestController();

      expect(() => controller.clearGraph(), returnsNormally);
      expect(() => controller.exportGraph(), returnsNormally);
      expect(() => controller.getOrphanNodes(), returnsNormally);
      expect(() => controller.detectCycles(), returnsNormally);
      expect(() => controller.nodesBounds, returnsNormally);
      expect(() => controller.clearSelection(), returnsNormally);
      expect(() => controller.selectAllNodes(), returnsNormally);
      expect(
        () => GraphApi(controller).selectAllConnections(),
        returnsNormally,
      );
    });

    test('loadGraph with same nodes does not duplicate', () {
      final controller = createTestController();
      final node = createTestNode(id: 'persistent-node');
      final graph = NodeGraph<String, dynamic>(nodes: [node]);

      controller.loadGraph(graph);
      controller.loadGraph(graph);

      expect(controller.nodeCount, equals(1));
    });

    test('clearGraph multiple times does not throw', () {
      final controller = createConnectedNodesController();

      controller.clearGraph();
      controller.clearGraph();
      controller.clearGraph();

      expect(controller.nodeCount, equals(0));
    });

    test('arrangeNodesInGrid with many nodes creates proper grid', () {
      final controller = createTestController();
      // Add 9 nodes for a 3x3 grid
      for (var i = 0; i < 9; i++) {
        controller.addNode(createTestNode(id: 'node-$i'));
      }

      controller.arrangeNodesInGrid(spacing: 100);

      // All nodes should have valid positions
      for (final node in controller.nodes.values) {
        expect(node.position.value.dx, greaterThanOrEqualTo(0));
        expect(node.position.value.dy, greaterThanOrEqualTo(0));
      }
    });

    test(
      'selectSpecificNodes with all non-existent IDs results in empty selection',
      () {
        final controller = createTestController();
        controller.addNode(createTestNode(id: 'existing'));

        controller.selectSpecificNodes(['fake-1', 'fake-2', 'fake-3']);

        expect(controller.selectedNodeIds, isEmpty);
      },
    );

    test('loadGraph preserves node data', () {
      final controller = createTestController();
      final node = createTestNode(id: 'data-node', data: 'custom-data');
      final graph = NodeGraph<String, dynamic>(nodes: [node]);

      controller.loadGraph(graph);

      expect(controller.getNode('data-node')!.data, equals('custom-data'));
    });

    test('exportGraph preserves connection data', () {
      final nodeA = createTestNodeWithOutputPort(id: 'node-a');
      final nodeB = createTestNodeWithInputPort(id: 'node-b');
      final connection = Connection<dynamic>(
        id: 'conn-with-data',
        sourceNodeId: 'node-a',
        sourcePortId: 'output-1',
        targetNodeId: 'node-b',
        targetPortId: 'input-1',
        data: {'key': 'value'},
      );
      final controller = createTestController(
        nodes: [nodeA, nodeB],
        connections: [connection],
      );

      final graph = controller.exportGraph();

      expect(graph.connections.first.data, equals({'key': 'value'}));
    });
  });
}

/// Test extension to capture events.
class _TestEventCapture extends NodeFlowExtension {
  _TestEventCapture(this.events);

  final List<GraphEvent> events;

  @override
  String get id => 'test-event-capture';

  @override
  void attach(NodeFlowController controller) {
    // No-op for testing
  }

  @override
  void detach() {
    // No-op for testing
  }

  @override
  void onEvent(GraphEvent event) {
    events.add(event);
  }
}
