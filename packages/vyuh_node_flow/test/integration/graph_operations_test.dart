@Tags(['integration'])
library;

import 'dart:convert';
import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:vyuh_node_flow/vyuh_node_flow.dart';

import '../helpers/test_factories.dart';

void main() {
  late NodeFlowController<String> controller;

  setUp(() {
    resetTestCounters();
    controller = createTestController();
    controller.setScreenSize(const Size(1200, 800));
  });

  tearDown(() {
    controller.dispose();
  });

  group('Graph Operations - Complete Workflow', () {
    test('create nodes, connect, arrange, and export', () {
      // Step 1: Create nodes
      final inputNode = createTestNodeWithOutputPort(
        id: 'input',
        portId: 'data-out',
        position: const Offset(0, 100),
      );
      final processNode = createTestNode(
        id: 'process',
        position: const Offset(250, 100),
        inputPorts: [createTestPort(id: 'data-in', type: PortType.input)],
        outputPorts: [createTestPort(id: 'result-out', type: PortType.output)],
      );
      final outputNode = createTestNodeWithInputPort(
        id: 'output',
        portId: 'result-in',
        position: const Offset(500, 100),
      );

      controller.addNode(inputNode);
      controller.addNode(processNode);
      controller.addNode(outputNode);

      expect(controller.nodeCount, equals(3));

      // Step 2: Create connections
      controller.createConnection('input', 'data-out', 'process', 'data-in');
      controller.createConnection(
        'process',
        'result-out',
        'output',
        'result-in',
      );

      expect(controller.connectionCount, equals(2));

      // Step 3: Arrange (move nodes)
      controller.moveNode('process', const Offset(50, 0)); // Move right

      expect(processNode.position.value, equals(const Offset(300, 100)));

      // Step 4: Export
      final graph = controller.exportGraph();

      expect(graph.nodes, hasLength(3));
      expect(graph.connections, hasLength(2));
    });

    test('load graph, modify, and save', () {
      // Create initial graph
      final nodes = [
        createTestNodeWithOutputPort(id: 'a', portId: 'out'),
        createTestNodeWithPorts(id: 'b'),
        createTestNodeWithInputPort(id: 'c', portId: 'in'),
      ];
      final connections = [
        createTestConnection(
          id: 'conn-1',
          sourceNodeId: 'a',
          sourcePortId: 'out',
          targetNodeId: 'b',
          targetPortId: 'input-1',
        ),
        createTestConnection(
          id: 'conn-2',
          sourceNodeId: 'b',
          sourcePortId: 'output-1',
          targetNodeId: 'c',
          targetPortId: 'in',
        ),
      ];

      final initialGraph = NodeGraph<String>(
        nodes: nodes,
        connections: connections,
      );

      // Load the graph
      controller.loadGraph(initialGraph);

      expect(controller.nodeCount, equals(3));
      expect(controller.connectionCount, equals(2));

      // Modify: add a new node
      final newNode = createTestNode(id: 'new-node');
      controller.addNode(newNode);

      expect(controller.nodeCount, equals(4));

      // Modify: remove a connection
      controller.removeConnection('conn-1');

      expect(controller.connectionCount, equals(1));

      // Save (export)
      final savedGraph = controller.exportGraph();

      expect(savedGraph.nodes, hasLength(4));
      expect(savedGraph.connections, hasLength(1));
    });

    test('graph with 50+ nodes and connections', () {
      // Create a large pipeline graph
      const nodeCount = 60;

      // Create nodes in a grid pattern
      for (var i = 0; i < nodeCount; i++) {
        final row = i ~/ 10;
        final col = i % 10;

        controller.addNode(
          createTestNode(
            id: 'node-$i',
            position: Offset(col * 150.0, row * 120.0),
            inputPorts: col > 0
                ? [createTestPort(id: 'in-$i', type: PortType.input)]
                : [],
            outputPorts: col < 9
                ? [createTestPort(id: 'out-$i', type: PortType.output)]
                : [],
          ),
        );
      }

      expect(controller.nodeCount, equals(nodeCount));

      // Connect nodes horizontally in each row
      var connectionCount = 0;
      for (var i = 0; i < nodeCount; i++) {
        final col = i % 10;
        if (col < 9) {
          controller.createConnection(
            'node-$i',
            'out-$i',
            'node-${i + 1}',
            'in-${i + 1}',
          );
          connectionCount++;
        }
      }

      expect(controller.connectionCount, equals(connectionCount));
      expect(connectionCount, greaterThan(50));

      // Verify graph operations work on large graph
      final graph = controller.exportGraph();
      expect(graph.nodes.length, equals(nodeCount));
      expect(graph.connections.length, equals(connectionCount));
    });

    test('mixed element types: nodes, connections, and annotations', () {
      // Create nodes
      for (var i = 0; i < 5; i++) {
        controller.addNode(
          createTestNodeWithPorts(
            id: 'node-$i',
            inputPortId: 'in',
            outputPortId: 'out',
          ),
        );
      }

      // Create connections
      for (var i = 0; i < 4; i++) {
        controller.createConnection('node-$i', 'out', 'node-${i + 1}', 'in');
      }

      // Create annotations
      controller.addAnnotation(
        createTestStickyAnnotation(
          id: 'note-1',
          text: 'Processing pipeline',
          position: const Offset(0, -50),
        ),
      );

      controller.addAnnotation(
        createTestGroupAnnotation(
          id: 'group-1',
          title: 'Data Processing',
          position: const Offset(-20, -20),
          size: const Size(800, 200),
        ),
      );

      controller.addAnnotation(
        createTestMarkerAnnotation(
          id: 'marker-1',
          position: const Offset(100, 100),
        ),
      );

      // Verify counts
      expect(controller.nodeCount, equals(5));
      expect(controller.connectionCount, equals(4));
      expect(controller.annotations.sortedAnnotations.length, equals(3));

      // Export and verify
      final graph = controller.exportGraph();
      expect(graph.nodes.length, equals(5));
      expect(graph.connections.length, equals(4));
    });
  });

  group('Graph Operations - Pipeline Patterns', () {
    test('build sequential pipeline (A -> B -> C -> D)', () {
      final chain = createNodeChain(count: 4);

      for (final node in chain.nodes) {
        controller.addNode(node);
      }
      for (final conn in chain.connections) {
        controller.addConnection(conn);
      }

      expect(controller.nodeCount, equals(4));
      expect(controller.connectionCount, equals(3));

      // Verify chain structure
      final connections = controller.connections;
      expect(connections[0].sourceNodeId, equals('chain-0'));
      expect(connections[0].targetNodeId, equals('chain-1'));
      expect(connections[1].sourceNodeId, equals('chain-1'));
      expect(connections[1].targetNodeId, equals('chain-2'));
      expect(connections[2].sourceNodeId, equals('chain-2'));
      expect(connections[2].targetNodeId, equals('chain-3'));
    });

    test('build fan-out pattern (A -> B, C, D)', () {
      // Source node with multiple outputs
      final source = createTestNode(
        id: 'source',
        position: const Offset(0, 150),
        outputPorts: [
          createTestPort(id: 'out-1', type: PortType.output),
          createTestPort(id: 'out-2', type: PortType.output),
          createTestPort(id: 'out-3', type: PortType.output),
        ],
      );

      final targets = List.generate(
        3,
        (i) => createTestNodeWithInputPort(
          id: 'target-$i',
          portId: 'in',
          position: Offset(250, i * 100.0),
        ),
      );

      controller.addNode(source);
      for (final target in targets) {
        controller.addNode(target);
      }

      // Connect source to all targets
      controller.createConnection('source', 'out-1', 'target-0', 'in');
      controller.createConnection('source', 'out-2', 'target-1', 'in');
      controller.createConnection('source', 'out-3', 'target-2', 'in');

      expect(controller.nodeCount, equals(4));
      expect(controller.connectionCount, equals(3));
    });

    test('build fan-in pattern (A, B, C -> D)', () {
      // Target node with multiple inputs
      final target = createTestNode(
        id: 'target',
        position: const Offset(250, 100),
        inputPorts: [
          createTestPort(id: 'in-1', type: PortType.input),
          createTestPort(id: 'in-2', type: PortType.input),
          createTestPort(id: 'in-3', type: PortType.input),
        ],
      );

      final sources = List.generate(
        3,
        (i) => createTestNodeWithOutputPort(
          id: 'source-$i',
          portId: 'out',
          position: Offset(0, i * 100.0),
        ),
      );

      controller.addNode(target);
      for (final source in sources) {
        controller.addNode(source);
      }

      // Connect all sources to target
      controller.createConnection('source-0', 'out', 'target', 'in-1');
      controller.createConnection('source-1', 'out', 'target', 'in-2');
      controller.createConnection('source-2', 'out', 'target', 'in-3');

      expect(controller.nodeCount, equals(4));
      expect(controller.connectionCount, equals(3));
    });

    test('build diamond pattern (A -> B, C -> D)', () {
      final nodeA = createTestNode(
        id: 'a',
        position: const Offset(0, 100),
        outputPorts: [
          createTestPort(id: 'out-1', type: PortType.output),
          createTestPort(id: 'out-2', type: PortType.output),
        ],
      );

      final nodeB = createTestNodeWithPorts(
        id: 'b',
        position: const Offset(200, 0),
      );

      final nodeC = createTestNodeWithPorts(
        id: 'c',
        position: const Offset(200, 200),
      );

      final nodeD = createTestNode(
        id: 'd',
        position: const Offset(400, 100),
        inputPorts: [
          createTestPort(id: 'in-1', type: PortType.input),
          createTestPort(id: 'in-2', type: PortType.input),
        ],
      );

      controller.addNode(nodeA);
      controller.addNode(nodeB);
      controller.addNode(nodeC);
      controller.addNode(nodeD);

      controller.createConnection('a', 'out-1', 'b', 'input-1');
      controller.createConnection('a', 'out-2', 'c', 'input-1');
      controller.createConnection('b', 'output-1', 'd', 'in-1');
      controller.createConnection('c', 'output-1', 'd', 'in-2');

      expect(controller.nodeCount, equals(4));
      expect(controller.connectionCount, equals(4));
    });
  });

  group('Graph Operations - Node Removal Cascading', () {
    test('removing node removes all its connections', () {
      // Create A -> B -> C
      controller.addNode(createTestNodeWithOutputPort(id: 'a', portId: 'out'));
      controller.addNode(createTestNodeWithPorts(id: 'b'));
      controller.addNode(createTestNodeWithInputPort(id: 'c', portId: 'in'));

      controller.createConnection('a', 'out', 'b', 'input-1');
      controller.createConnection('b', 'output-1', 'c', 'in');

      expect(controller.connectionCount, equals(2));

      // Remove middle node
      controller.removeNode('b');

      expect(controller.nodeCount, equals(2));
      expect(controller.connectionCount, equals(0)); // Both connections removed
    });

    test('removing hub node with many connections', () {
      // Create hub with 5 connections
      final hub = createTestNode(
        id: 'hub',
        inputPorts: [createTestPort(id: 'in', type: PortType.input)],
        outputPorts: [createTestPort(id: 'out', type: PortType.output)],
      );
      controller.addNode(hub);

      // Add sources and targets
      for (var i = 0; i < 5; i++) {
        controller.addNode(
          createTestNodeWithOutputPort(id: 'source-$i', portId: 'out'),
        );
        controller.addNode(
          createTestNodeWithInputPort(id: 'target-$i', portId: 'in'),
        );
      }

      // Connect sources to hub and hub to targets
      for (var i = 0; i < 5; i++) {
        controller.createConnection('source-$i', 'out', 'hub', 'in');
        controller.createConnection('hub', 'out', 'target-$i', 'in');
      }

      expect(controller.connectionCount, equals(10));

      // Remove hub
      controller.removeNode('hub');

      expect(controller.connectionCount, equals(0)); // All 10 connections gone
      expect(controller.nodeCount, equals(10)); // Sources and targets remain
    });
  });

  group('Graph Operations - Viewport Operations', () {
    test('fitToView centers on all nodes', () {
      // Create nodes spread out
      for (var i = 0; i < 10; i++) {
        controller.addNode(
          createTestNode(
            id: 'node-$i',
            position: Offset(i * 200.0, (i % 3) * 150.0),
          ),
        );
      }

      controller.fitToView();

      // Verify viewport covers all nodes
      final extent = controller.viewportExtent;
      expect(extent.width, greaterThan(0));
      expect(extent.height, greaterThan(0));
    });

    test('focus on specific nodes using selection', () {
      // Create scattered nodes
      controller.addNode(
        createTestNode(
          id: 'far-left',
          position: const Offset(-500, 0),
          size: const Size(100, 80),
        ),
      );
      controller.addNode(
        createTestNode(
          id: 'center',
          position: const Offset(100, 100),
          size: const Size(100, 80),
        ),
      );
      controller.addNode(
        createTestNode(
          id: 'far-right',
          position: const Offset(1000, 0),
          size: const Size(100, 80),
        ),
      );

      // Select center node and fit to selected
      controller.selectNode('center');
      controller.fitSelectedNodes();

      // Viewport should be near the center node
      final viewportCenter = controller.getViewportCenter();
      // The center node is at (100, 100), viewport center should be near it
      expect(viewportCenter.dx, greaterThan(-100));
      expect(viewportCenter.dx, lessThan(500));
    });
  });

  group('Graph Operations - Selection Operations', () {
    test('select multiple nodes programmatically', () {
      // Create nodes in a grid
      for (var row = 0; row < 3; row++) {
        for (var col = 0; col < 3; col++) {
          controller.addNode(
            createTestNode(
              id: 'node-$row-$col',
              position: Offset(col * 150.0, row * 150.0),
              size: const Size(100, 80),
            ),
          );
        }
      }

      // Select top-left 2x2 nodes programmatically
      controller.selectNodes(['node-0-0', 'node-0-1', 'node-1-0', 'node-1-1']);

      // Should have 4 nodes selected
      expect(controller.selectedNodeIds.length, equals(4));
      expect(controller.selectedNodeIds, contains('node-0-0'));
      expect(controller.selectedNodeIds, contains('node-1-1'));
    });

    test('batch select and deselect', () {
      for (var i = 0; i < 10; i++) {
        controller.addNode(createTestNode(id: 'node-$i'));
      }

      // Select odd nodes
      final oddIds = List.generate(5, (i) => 'node-${i * 2 + 1}');
      controller.selectNodes(oddIds);

      expect(controller.selectedNodeIds.length, equals(5));

      // Clear and select even nodes
      controller.clearNodeSelection();
      final evenIds = List.generate(5, (i) => 'node-${i * 2}');
      controller.selectNodes(evenIds);

      expect(controller.selectedNodeIds.length, equals(5));

      // Select all
      controller.selectAllNodes();
      expect(controller.selectedNodeIds.length, equals(10));
    });
  });

  group('Graph Operations - Analysis', () {
    test('detect cycles in graph', () {
      // Create A -> B -> C
      controller.addNode(createTestNodeWithPorts(id: 'a'));
      controller.addNode(createTestNodeWithPorts(id: 'b'));
      controller.addNode(createTestNodeWithPorts(id: 'c'));

      controller.createConnection('a', 'output-1', 'b', 'input-1');
      controller.createConnection('b', 'output-1', 'c', 'input-1');

      // No cycle yet
      expect(controller.detectCycles(), isEmpty);

      // Add C -> A to create cycle
      controller.createConnection('c', 'output-1', 'a', 'input-1');

      // Now has cycle
      expect(controller.detectCycles(), isNotEmpty);
    });

    test('find orphan nodes', () {
      // Connected nodes
      controller.addNode(createTestNodeWithOutputPort(id: 'connected-1'));
      controller.addNode(createTestNodeWithInputPort(id: 'connected-2'));
      controller.createConnection(
        'connected-1',
        'output-1',
        'connected-2',
        'input-1',
      );

      // Orphan nodes (no connections)
      controller.addNode(createTestNode(id: 'orphan-1'));
      controller.addNode(createTestNode(id: 'orphan-2'));

      final orphans = controller.getOrphanNodes();

      expect(orphans.length, equals(2));
      expect(orphans.map((n) => n.id), containsAll(['orphan-1', 'orphan-2']));
    });

    test('get root nodes (no incoming connections)', () {
      // Create pipeline: A -> B -> C, D -> C
      controller.addNode(createTestNodeWithOutputPort(id: 'a', portId: 'out'));
      controller.addNode(
        createTestNodeWithPorts(id: 'b'),
      ); // Has input and output
      controller.addNode(
        createTestNode(
          id: 'c',
          inputPorts: [
            createTestPort(id: 'in-1', type: PortType.input),
            createTestPort(id: 'in-2', type: PortType.input),
          ],
        ),
      );
      controller.addNode(createTestNodeWithOutputPort(id: 'd', portId: 'out'));

      controller.createConnection('a', 'out', 'b', 'input-1');
      controller.createConnection('b', 'output-1', 'c', 'in-1');
      controller.createConnection('d', 'out', 'c', 'in-2');

      // Export graph and use analysis methods
      final graph = controller.exportGraph();
      final roots = graph.getRootNodes();

      // A and D are root nodes (no incoming connections)
      expect(roots.length, equals(2));
      expect(roots.map((n) => n.id), containsAll(['a', 'd']));
    });

    test('get leaf nodes (no outgoing connections)', () {
      // Create: A -> B, A -> C
      controller.addNode(
        createTestNode(
          id: 'a',
          outputPorts: [
            createTestPort(id: 'out-1', type: PortType.output),
            createTestPort(id: 'out-2', type: PortType.output),
          ],
        ),
      );
      controller.addNode(createTestNodeWithInputPort(id: 'b', portId: 'in'));
      controller.addNode(createTestNodeWithInputPort(id: 'c', portId: 'in'));

      controller.createConnection('a', 'out-1', 'b', 'in');
      controller.createConnection('a', 'out-2', 'c', 'in');

      // Export graph and use analysis methods
      final graph = controller.exportGraph();
      final leaves = graph.getLeafNodes();

      // B and C are leaf nodes (no outgoing connections)
      expect(leaves.length, equals(2));
      expect(leaves.map((n) => n.id), containsAll(['b', 'c']));
    });
  });

  group('Graph Operations - Serialization Round-Trip', () {
    test('serialize and deserialize complete graph', () {
      // Build a complex graph
      controller.addNode(createTestNodeWithOutputPort(id: 'input'));
      controller.addNode(createTestNodeWithPorts(id: 'process'));
      controller.addNode(createTestNodeWithInputPort(id: 'output'));

      controller.createConnection('input', 'output-1', 'process', 'input-1');
      controller.createConnection('process', 'output-1', 'output', 'input-1');

      controller.addAnnotation(
        createTestStickyAnnotation(id: 'note', text: 'Test'),
      );

      // Export to JSON
      final graph = controller.exportGraph();
      final json = graph.toJson((data) => data);
      final jsonString = jsonEncode(json);

      // Verify JSON is valid
      expect(jsonString, isNotEmpty);
      expect(jsonString, contains('input'));
      expect(jsonString, contains('process'));
      expect(jsonString, contains('output'));

      // Reimport
      final parsedJson = jsonDecode(jsonString) as Map<String, dynamic>;
      final loadedGraph = NodeGraph<String>.fromJson(
        parsedJson,
        (json) => json as String,
      );

      expect(loadedGraph.nodes.length, equals(3));
      expect(loadedGraph.connections.length, equals(2));
    });

    test('graph maintains structure after round-trip', () {
      // Create specific structure
      final originalNodes = [
        createTestNode(
          id: 'node-a',
          position: const Offset(100, 200),
          data: 'data-a',
        ),
        createTestNode(
          id: 'node-b',
          position: const Offset(300, 200),
          data: 'data-b',
        ),
      ];

      for (final node in originalNodes) {
        controller.addNode(node);
      }

      // Export and reimport
      final graph1 = controller.exportGraph();
      controller.clearGraph();
      controller.loadGraph(graph1);

      // Verify structure
      expect(controller.nodeCount, equals(2));
      final nodeA = controller.getNode('node-a');
      final nodeB = controller.getNode('node-b');

      expect(nodeA, isNotNull);
      expect(nodeB, isNotNull);
      expect(nodeA!.data, equals('data-a'));
      expect(nodeB!.data, equals('data-b'));
    });
  });

  group('Graph Operations - Batch Operations', () {
    test('batch add nodes', () {
      final nodes = createNodeGrid(rows: 5, cols: 5);

      for (final node in nodes) {
        controller.addNode(node);
      }

      expect(controller.nodeCount, equals(25));
    });

    test('batch remove nodes', () {
      // Add 20 nodes
      for (var i = 0; i < 20; i++) {
        controller.addNode(createTestNode(id: 'node-$i'));
      }

      // Remove first 10
      for (var i = 0; i < 10; i++) {
        controller.removeNode('node-$i');
      }

      expect(controller.nodeCount, equals(10));
    });

    test('clear and rebuild graph', () {
      // Initial state
      for (var i = 0; i < 10; i++) {
        controller.addNode(createTestNode(id: 'old-$i'));
      }

      expect(controller.nodeCount, equals(10));

      // Clear
      controller.clearGraph();

      expect(controller.nodeCount, equals(0));
      expect(controller.connectionCount, equals(0));

      // Rebuild
      for (var i = 0; i < 5; i++) {
        controller.addNode(createTestNode(id: 'new-$i'));
      }

      expect(controller.nodeCount, equals(5));
    });
  });
}
