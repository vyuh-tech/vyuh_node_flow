/// Comprehensive unit tests for the [NodeGraph] data model.
///
/// Tests cover:
/// - Graph construction (from nodes/connections lists, empty, etc.)
/// - Node and connection accessors
/// - Serialization/deserialization to/from JSON
/// - Graph analysis methods (bounds, root/leaf nodes, etc.)
/// - Node type filtering (regular, group, comment nodes)
/// - Validation and edge cases
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
  // GRAPH CONSTRUCTION TESTS
  // ===========================================================================

  group('NodeGraph Construction', () {
    group('Default Constructor', () {
      test('creates empty graph with default values', () {
        const graph = NodeGraph<String, dynamic>();

        expect(graph.nodes, isEmpty);
        expect(graph.connections, isEmpty);
        expect(graph.viewport, equals(const GraphViewport()));
        expect(graph.metadata, isEmpty);
      });

      test('creates graph with nodes only', () {
        final nodes = [
          createTestNode(id: 'node-1'),
          createTestNode(id: 'node-2'),
        ];

        final graph = NodeGraph<String, dynamic>(nodes: nodes);

        expect(graph.nodes.length, equals(2));
        expect(graph.connections, isEmpty);
      });

      test('creates graph with connections only', () {
        final connections = [
          createTestConnection(sourceNodeId: 'node-1', targetNodeId: 'node-2'),
        ];

        final graph = NodeGraph<String, dynamic>(connections: connections);

        expect(graph.nodes, isEmpty);
        expect(graph.connections.length, equals(1));
      });

      test('creates graph with custom viewport', () {
        const viewport = GraphViewport(x: 100, y: 200, zoom: 1.5);
        final graph = NodeGraph<String, dynamic>(viewport: viewport);

        expect(graph.viewport.x, equals(100));
        expect(graph.viewport.y, equals(200));
        expect(graph.viewport.zoom, equals(1.5));
      });

      test('creates graph with metadata', () {
        final metadata = {
          'version': '1.0',
          'author': 'test',
          'createdAt': '2025-01-01',
        };

        final graph = NodeGraph<String, dynamic>(metadata: metadata);

        expect(graph.metadata['version'], equals('1.0'));
        expect(graph.metadata['author'], equals('test'));
        expect(graph.metadata['createdAt'], equals('2025-01-01'));
      });

      test('creates graph with all properties', () {
        final nodes = [createTestNode(id: 'node-1')];
        final connections = [
          createTestConnection(sourceNodeId: 'node-1', targetNodeId: 'node-2'),
        ];
        const viewport = GraphViewport(x: 50, y: 75, zoom: 2.0);
        final metadata = {'key': 'value'};

        final graph = NodeGraph<String, dynamic>(
          nodes: nodes,
          connections: connections,
          viewport: viewport,
          metadata: metadata,
        );

        expect(graph.nodes.length, equals(1));
        expect(graph.connections.length, equals(1));
        expect(graph.viewport.zoom, equals(2.0));
        expect(graph.metadata['key'], equals('value'));
      });
    });

    group('Graph from Chain Factory', () {
      test('creates connected node chain', () {
        final chain = createNodeChain(count: 4);

        final graph = NodeGraph<String, dynamic>(
          nodes: chain.nodes,
          connections: chain.connections,
        );

        expect(graph.nodes.length, equals(4));
        expect(graph.connections.length, equals(3));
      });

      test('creates graph from row of nodes', () {
        final nodes = createNodeRow(count: 5, spacing: 100);

        final graph = NodeGraph<String, dynamic>(nodes: nodes);

        expect(graph.nodes.length, equals(5));

        // Verify positions
        for (var i = 0; i < 5; i++) {
          expect(graph.nodes[i].position.value.dx, equals(i * 100.0));
        }
      });

      test('creates graph from grid of nodes', () {
        final nodes = createNodeGrid(rows: 3, cols: 3);

        final graph = NodeGraph<String, dynamic>(nodes: nodes);

        expect(graph.nodes.length, equals(9));
      });
    });
  });

  // ===========================================================================
  // NODE ACCESSOR TESTS
  // ===========================================================================

  group('Node Accessors', () {
    late NodeGraph<String, dynamic> graph;

    setUp(() {
      final nodes = [
        createTestNode(id: 'node-a', position: const Offset(0, 0)),
        createTestNode(id: 'node-b', position: const Offset(100, 0)),
        createTestNode(id: 'node-c', position: const Offset(200, 0)),
      ];

      graph = NodeGraph<String, dynamic>(nodes: nodes);
    });

    group('getNodeById()', () {
      test('returns node when found', () {
        final node = graph.getNodeById('node-a');

        expect(node, isNotNull);
        expect(node!.id, equals('node-a'));
      });

      test('returns null when node not found', () {
        final node = graph.getNodeById('non-existent');

        expect(node, isNull);
      });

      test('returns correct node among multiple nodes', () {
        final nodeB = graph.getNodeById('node-b');

        expect(nodeB, isNotNull);
        expect(nodeB!.id, equals('node-b'));
        expect(nodeB.position.value.dx, equals(100));
      });
    });

    group('getNodeIndex()', () {
      test('returns correct index for first node', () {
        final index = graph.getNodeIndex('node-a');

        expect(index, equals(0));
      });

      test('returns correct index for middle node', () {
        final index = graph.getNodeIndex('node-b');

        expect(index, equals(1));
      });

      test('returns correct index for last node', () {
        final index = graph.getNodeIndex('node-c');

        expect(index, equals(2));
      });

      test('returns -1 for non-existent node', () {
        final index = graph.getNodeIndex('non-existent');

        expect(index, equals(-1));
      });
    });
  });

  // ===========================================================================
  // CONNECTION ACCESSOR TESTS
  // ===========================================================================

  group('Connection Accessors', () {
    late NodeGraph<String, dynamic> graph;

    setUp(() {
      final nodes = [
        createTestNodeWithPorts(id: 'node-a'),
        createTestNodeWithPorts(id: 'node-b'),
        createTestNodeWithPorts(id: 'node-c'),
        createTestNodeWithPorts(id: 'node-d'),
      ];

      final connections = [
        createTestConnection(
          id: 'conn-1',
          sourceNodeId: 'node-a',
          targetNodeId: 'node-b',
        ),
        createTestConnection(
          id: 'conn-2',
          sourceNodeId: 'node-b',
          targetNodeId: 'node-c',
        ),
        createTestConnection(
          id: 'conn-3',
          sourceNodeId: 'node-b',
          targetNodeId: 'node-d',
        ),
      ];

      graph = NodeGraph<String, dynamic>(
        nodes: nodes,
        connections: connections,
      );
    });

    group('getNodeConnections()', () {
      test('returns all connections for a node', () {
        final connections = graph.getNodeConnections('node-b');

        expect(connections.length, equals(3));
      });

      test('returns empty list for disconnected node', () {
        final graphWithDisconnected = NodeGraph<String, dynamic>(
          nodes: [
            createTestNode(id: 'isolated'),
            ...graph.nodes,
          ],
          connections: graph.connections,
        );

        final connections = graphWithDisconnected.getNodeConnections(
          'isolated',
        );

        expect(connections, isEmpty);
      });

      test('returns empty list for non-existent node', () {
        final connections = graph.getNodeConnections('non-existent');

        expect(connections, isEmpty);
      });
    });

    group('getInputConnections()', () {
      test('returns connections where node is target', () {
        final inputConnections = graph.getInputConnections('node-b');

        expect(inputConnections.length, equals(1));
        expect(inputConnections.first.targetNodeId, equals('node-b'));
        expect(inputConnections.first.sourceNodeId, equals('node-a'));
      });

      test('returns empty for root node', () {
        final inputConnections = graph.getInputConnections('node-a');

        expect(inputConnections, isEmpty);
      });

      test('returns multiple input connections', () {
        final additionalConnection = createTestConnection(
          id: 'conn-4',
          sourceNodeId: 'node-c',
          targetNodeId: 'node-d',
        );

        final graphWithMultipleInputs = NodeGraph<String, dynamic>(
          nodes: graph.nodes,
          connections: [...graph.connections, additionalConnection],
        );

        final inputConnections = graphWithMultipleInputs.getInputConnections(
          'node-d',
        );

        expect(inputConnections.length, equals(2));
      });
    });

    group('getOutputConnections()', () {
      test('returns connections where node is source', () {
        final outputConnections = graph.getOutputConnections('node-b');

        expect(outputConnections.length, equals(2));
        for (final conn in outputConnections) {
          expect(conn.sourceNodeId, equals('node-b'));
        }
      });

      test('returns empty for leaf node', () {
        final outputConnections = graph.getOutputConnections('node-c');

        expect(outputConnections, isEmpty);
      });
    });

    group('getPortConnections()', () {
      test('returns connections for specific port', () {
        final portConnections = graph.getPortConnections('node-b', 'output-1');

        expect(portConnections.length, equals(2));
      });

      test('returns empty for port with no connections', () {
        final portConnections = graph.getPortConnections('node-c', 'output-1');

        expect(portConnections, isEmpty);
      });
    });

    group('areNodesConnected()', () {
      test('returns true for connected nodes', () {
        final result = graph.areNodesConnected('node-a', 'node-b');

        expect(result, isTrue);
      });

      test('returns false for disconnected nodes', () {
        final result = graph.areNodesConnected('node-a', 'node-c');

        expect(result, isFalse);
      });

      test('returns false for reversed connection', () {
        // node-a -> node-b exists, but not node-b -> node-a
        final result = graph.areNodesConnected('node-b', 'node-a');

        expect(result, isFalse);
      });

      test('returns false for non-existent nodes', () {
        final result = graph.areNodesConnected('non-existent', 'node-a');

        expect(result, isFalse);
      });
    });
  });

  // ===========================================================================
  // BOUNDS CALCULATION TESTS
  // ===========================================================================

  group('Bounds Calculation', () {
    group('getBounds()', () {
      test('returns Rect.zero for empty graph', () {
        const graph = NodeGraph<String, dynamic>();

        final bounds = graph.getBounds();

        expect(bounds, equals(Rect.zero));
      });

      test('calculates bounds for single node', () {
        final nodes = [
          createTestNode(
            id: 'node-1',
            position: const Offset(100, 50),
            size: const Size(150, 100),
          ),
        ];

        final graph = NodeGraph<String, dynamic>(nodes: nodes);
        final bounds = graph.getBounds();

        expect(bounds.left, equals(100));
        expect(bounds.top, equals(50));
        expect(bounds.right, equals(250));
        expect(bounds.bottom, equals(150));
      });

      test('calculates bounds for multiple nodes', () {
        final nodes = [
          createTestNode(
            id: 'node-1',
            position: const Offset(0, 0),
            size: const Size(100, 100),
          ),
          createTestNode(
            id: 'node-2',
            position: const Offset(200, 150),
            size: const Size(100, 100),
          ),
        ];

        final graph = NodeGraph<String, dynamic>(nodes: nodes);
        final bounds = graph.getBounds();

        expect(bounds.left, equals(0));
        expect(bounds.top, equals(0));
        expect(bounds.right, equals(300));
        expect(bounds.bottom, equals(250));
      });

      test('handles negative positions', () {
        final nodes = [
          createTestNode(
            id: 'node-1',
            position: const Offset(-100, -50),
            size: const Size(50, 50),
          ),
          createTestNode(
            id: 'node-2',
            position: const Offset(100, 100),
            size: const Size(50, 50),
          ),
        ];

        final graph = NodeGraph<String, dynamic>(nodes: nodes);
        final bounds = graph.getBounds();

        expect(bounds.left, equals(-100));
        expect(bounds.top, equals(-50));
        expect(bounds.right, equals(150));
        expect(bounds.bottom, equals(150));
      });

      test('handles varying node sizes', () {
        final nodes = [
          createTestNode(
            id: 'small',
            position: const Offset(0, 0),
            size: const Size(50, 50),
          ),
          createTestNode(
            id: 'large',
            position: const Offset(50, 50),
            size: const Size(200, 200),
          ),
        ];

        final graph = NodeGraph<String, dynamic>(nodes: nodes);
        final bounds = graph.getBounds();

        expect(bounds.left, equals(0));
        expect(bounds.top, equals(0));
        expect(bounds.right, equals(250));
        expect(bounds.bottom, equals(250));
      });
    });
  });

  // ===========================================================================
  // CIRCULAR DEPENDENCY TESTS
  // ===========================================================================

  group('Circular Dependency Detection', () {
    group('hasCircularDependency()', () {
      test('returns false for empty graph', () {
        const graph = NodeGraph<String, dynamic>();

        expect(graph.hasCircularDependency(), isFalse);
      });

      test('returns false for single node', () {
        final nodes = [createTestNodeWithPorts(id: 'node-1')];

        final graph = NodeGraph<String, dynamic>(nodes: nodes);

        expect(graph.hasCircularDependency(), isFalse);
      });

      test('returns false for linear chain', () {
        final chain = createNodeChain(count: 5);

        final graph = NodeGraph<String, dynamic>(
          nodes: chain.nodes,
          connections: chain.connections,
        );

        expect(graph.hasCircularDependency(), isFalse);
      });

      test('returns false for tree structure', () {
        final nodes = [
          createTestNodeWithPorts(id: 'root'),
          createTestNodeWithPorts(id: 'left'),
          createTestNodeWithPorts(id: 'right'),
        ];

        final connections = [
          createTestConnection(sourceNodeId: 'root', targetNodeId: 'left'),
          createTestConnection(sourceNodeId: 'root', targetNodeId: 'right'),
        ];

        final graph = NodeGraph<String, dynamic>(
          nodes: nodes,
          connections: connections,
        );

        expect(graph.hasCircularDependency(), isFalse);
      });

      test('returns false for DAG (diamond pattern)', () {
        final nodes = [
          createTestNodeWithPorts(id: 'A'),
          createTestNodeWithPorts(id: 'B'),
          createTestNodeWithPorts(id: 'C'),
          createTestNodeWithPorts(id: 'D'),
        ];

        final connections = [
          createTestConnection(
            sourceNodeId: 'A',
            sourcePortId: 'output-1',
            targetNodeId: 'B',
            targetPortId: 'input-1',
          ),
          createTestConnection(
            sourceNodeId: 'A',
            sourcePortId: 'output-1',
            targetNodeId: 'C',
            targetPortId: 'input-1',
          ),
          createTestConnection(
            sourceNodeId: 'B',
            sourcePortId: 'output-1',
            targetNodeId: 'D',
            targetPortId: 'input-1',
          ),
          createTestConnection(
            sourceNodeId: 'C',
            sourcePortId: 'output-1',
            targetNodeId: 'D',
            targetPortId: 'input-1',
          ),
        ];

        final graph = NodeGraph<String, dynamic>(
          nodes: nodes,
          connections: connections,
        );

        expect(graph.hasCircularDependency(), isFalse);
      });

      test('returns true for two-node cycle', () {
        final nodes = [
          createTestNodeWithPorts(id: 'A'),
          createTestNodeWithPorts(id: 'B'),
        ];

        final connections = [
          createTestConnection(
            sourceNodeId: 'A',
            sourcePortId: 'output-1',
            targetNodeId: 'B',
            targetPortId: 'input-1',
          ),
          createTestConnection(
            sourceNodeId: 'B',
            sourcePortId: 'output-1',
            targetNodeId: 'A',
            targetPortId: 'input-1',
          ),
        ];

        final graph = NodeGraph<String, dynamic>(
          nodes: nodes,
          connections: connections,
        );

        expect(graph.hasCircularDependency(), isTrue);
      });

      test('returns true for three-node cycle', () {
        final nodes = [
          createTestNodeWithPorts(id: 'A'),
          createTestNodeWithPorts(id: 'B'),
          createTestNodeWithPorts(id: 'C'),
        ];

        final connections = [
          createTestConnection(
            sourceNodeId: 'A',
            sourcePortId: 'output-1',
            targetNodeId: 'B',
            targetPortId: 'input-1',
          ),
          createTestConnection(
            sourceNodeId: 'B',
            sourcePortId: 'output-1',
            targetNodeId: 'C',
            targetPortId: 'input-1',
          ),
          createTestConnection(
            sourceNodeId: 'C',
            sourcePortId: 'output-1',
            targetNodeId: 'A',
            targetPortId: 'input-1',
          ),
        ];

        final graph = NodeGraph<String, dynamic>(
          nodes: nodes,
          connections: connections,
        );

        expect(graph.hasCircularDependency(), isTrue);
      });

      test('returns true for self-loop', () {
        final nodes = [createTestNodeWithPorts(id: 'A')];

        final connections = [
          createTestConnection(
            sourceNodeId: 'A',
            sourcePortId: 'output-1',
            targetNodeId: 'A',
            targetPortId: 'input-1',
          ),
        ];

        final graph = NodeGraph<String, dynamic>(
          nodes: nodes,
          connections: connections,
        );

        expect(graph.hasCircularDependency(), isTrue);
      });
    });
  });

  // ===========================================================================
  // ROOT AND LEAF NODE TESTS
  // ===========================================================================

  group('Root and Leaf Node Detection', () {
    late NodeGraph<String, dynamic> graph;

    setUp(() {
      // Create a graph: A -> B -> C, D (isolated)
      final nodes = [
        createTestNodeWithPorts(id: 'A'),
        createTestNodeWithPorts(id: 'B'),
        createTestNodeWithPorts(id: 'C'),
        createTestNodeWithPorts(id: 'D'),
      ];

      final connections = [
        createTestConnection(
          sourceNodeId: 'A',
          sourcePortId: 'output-1',
          targetNodeId: 'B',
          targetPortId: 'input-1',
        ),
        createTestConnection(
          sourceNodeId: 'B',
          sourcePortId: 'output-1',
          targetNodeId: 'C',
          targetPortId: 'input-1',
        ),
      ];

      graph = NodeGraph<String, dynamic>(
        nodes: nodes,
        connections: connections,
      );
    });

    group('getRootNodes()', () {
      test('returns nodes with no input connections', () {
        final rootNodes = graph.getRootNodes();

        expect(rootNodes.length, equals(2));
        expect(rootNodes.map((n) => n.id), containsAll(['A', 'D']));
      });

      test('returns all nodes when no connections exist', () {
        final unconnectedGraph = NodeGraph<String, dynamic>(
          nodes: [
            createTestNode(id: 'node-1'),
            createTestNode(id: 'node-2'),
          ],
        );

        final rootNodes = unconnectedGraph.getRootNodes();

        expect(rootNodes.length, equals(2));
      });

      test('returns empty for empty graph', () {
        const emptyGraph = NodeGraph<String, dynamic>();

        final rootNodes = emptyGraph.getRootNodes();

        expect(rootNodes, isEmpty);
      });
    });

    group('getLeafNodes()', () {
      test('returns nodes with no output connections', () {
        final leafNodes = graph.getLeafNodes();

        expect(leafNodes.length, equals(2));
        expect(leafNodes.map((n) => n.id), containsAll(['C', 'D']));
      });

      test('returns all nodes when no connections exist', () {
        final unconnectedGraph = NodeGraph<String, dynamic>(
          nodes: [
            createTestNode(id: 'node-1'),
            createTestNode(id: 'node-2'),
          ],
        );

        final leafNodes = unconnectedGraph.getLeafNodes();

        expect(leafNodes.length, equals(2));
      });

      test('returns empty for empty graph', () {
        const emptyGraph = NodeGraph<String, dynamic>();

        final leafNodes = emptyGraph.getLeafNodes();

        expect(leafNodes, isEmpty);
      });
    });

    test('isolated node is both root and leaf', () {
      final rootNodes = graph.getRootNodes();
      final leafNodes = graph.getLeafNodes();

      expect(rootNodes.any((n) => n.id == 'D'), isTrue);
      expect(leafNodes.any((n) => n.id == 'D'), isTrue);
    });
  });

  // ===========================================================================
  // NODE TYPE FILTERING TESTS
  // ===========================================================================

  group('Node Type Filtering', () {
    late NodeGraph<String, dynamic> mixedGraph;

    setUp(() {
      final nodes = <Node<String>>[
        createTestNode(id: 'regular-1'),
        createTestNode(id: 'regular-2'),
        createTestGroupNode<String>(
          id: 'group-1',
          data: 'group-data',
          position: const Offset(0, 0),
        ),
        createTestGroupNode<String>(
          id: 'group-2',
          data: 'group-data',
          position: const Offset(100, 0),
        ),
        createTestCommentNode<String>(
          id: 'comment-1',
          data: 'comment-data',
          position: const Offset(200, 0),
        ),
      ];

      mixedGraph = NodeGraph<String, dynamic>(nodes: nodes);
    });

    group('getGroupNodes()', () {
      test('returns only GroupNode instances', () {
        final groupNodes = mixedGraph.getGroupNodes();

        expect(groupNodes.length, equals(2));
        // getGroupNodes returns List<GroupNode<T>>, so all elements are GroupNodes
        expect(groupNodes, everyElement(isA<GroupNode<String>>()));
        expect(
          groupNodes.map((n) => n.id),
          containsAll(['group-1', 'group-2']),
        );
      });

      test('returns empty when no group nodes exist', () {
        final graphWithoutGroups = NodeGraph<String, dynamic>(
          nodes: [createTestNode(id: 'regular')],
        );

        final groupNodes = graphWithoutGroups.getGroupNodes();

        expect(groupNodes, isEmpty);
      });
    });

    group('getCommentNodes()', () {
      test('returns only CommentNode instances', () {
        final commentNodes = mixedGraph.getCommentNodes();

        expect(commentNodes.length, equals(1));
        // getCommentNodes returns List<CommentNode<T>>, so all elements are CommentNodes
        expect(commentNodes, everyElement(isA<CommentNode<String>>()));
        expect(commentNodes.first.id, equals('comment-1'));
      });

      test('returns empty when no comment nodes exist', () {
        final graphWithoutComments = NodeGraph<String, dynamic>(
          nodes: [createTestNode(id: 'regular')],
        );

        final commentNodes = graphWithoutComments.getCommentNodes();

        expect(commentNodes, isEmpty);
      });
    });

    group('getRegularNodes()', () {
      test('returns only regular nodes (not group or comment)', () {
        final regularNodes = mixedGraph.getRegularNodes();

        expect(regularNodes.length, equals(2));
        expect(regularNodes.every((n) => n is! GroupNode<String>), isTrue);
        expect(regularNodes.every((n) => n is! CommentNode<String>), isTrue);
        expect(
          regularNodes.map((n) => n.id),
          containsAll(['regular-1', 'regular-2']),
        );
      });

      test('returns all nodes when no special nodes exist', () {
        final regularGraph = NodeGraph<String, dynamic>(
          nodes: [
            createTestNode(id: 'node-1'),
            createTestNode(id: 'node-2'),
          ],
        );

        final regularNodes = regularGraph.getRegularNodes();

        expect(regularNodes.length, equals(2));
      });

      test('returns empty when only special nodes exist', () {
        final specialGraph = NodeGraph<String, dynamic>(
          nodes: [
            createTestGroupNode<String>(
              id: 'group-1',
              data: 'data',
              position: Offset.zero,
            ),
            createTestCommentNode<String>(
              id: 'comment-1',
              data: 'data',
              position: Offset.zero,
            ),
          ],
        );

        final regularNodes = specialGraph.getRegularNodes();

        expect(regularNodes, isEmpty);
      });
    });
  });

  // ===========================================================================
  // JSON SERIALIZATION TESTS
  // ===========================================================================

  group('JSON Serialization', () {
    group('toJson()', () {
      test('serializes empty graph', () {
        const graph = NodeGraph<String, dynamic>();

        final json = graph.toJson((v) => v, (v) => v);

        expect(json['nodes'], isEmpty);
        expect(json['connections'], isEmpty);
        expect(json['viewport'], isNotNull);
        expect(json['metadata'], isEmpty);
      });

      test('serializes graph with nodes', () {
        final nodes = [
          createTestNode(id: 'node-1', data: 'data-1'),
          createTestNode(id: 'node-2', data: 'data-2'),
        ];

        final graph = NodeGraph<String, dynamic>(nodes: nodes);
        final json = graph.toJson((v) => v, (v) => v);

        expect(json['nodes'], hasLength(2));
        expect(json['nodes'][0]['id'], equals('node-1'));
        expect(json['nodes'][1]['id'], equals('node-2'));
      });

      test('serializes graph with connections', () {
        final connections = [
          createTestConnection(
            id: 'conn-1',
            sourceNodeId: 'node-a',
            targetNodeId: 'node-b',
          ),
        ];

        final graph = NodeGraph<String, dynamic>(connections: connections);
        final json = graph.toJson((v) => v, (v) => v);

        expect(json['connections'], hasLength(1));
        expect(json['connections'][0]['id'], equals('conn-1'));
        expect(json['connections'][0]['sourceNodeId'], equals('node-a'));
        expect(json['connections'][0]['targetNodeId'], equals('node-b'));
      });

      test('serializes graph with viewport', () {
        const viewport = GraphViewport(x: 100, y: 200, zoom: 1.5);
        final graph = NodeGraph<String, dynamic>(viewport: viewport);

        final json = graph.toJson((v) => v, (v) => v);

        expect(json['viewport']['x'], equals(100.0));
        expect(json['viewport']['y'], equals(200.0));
        expect(json['viewport']['zoom'], equals(1.5));
      });

      test('serializes graph with metadata', () {
        final metadata = {'version': '2.0', 'name': 'Test Graph'};
        final graph = NodeGraph<String, dynamic>(metadata: metadata);

        final json = graph.toJson((v) => v, (v) => v);

        expect(json['metadata']['version'], equals('2.0'));
        expect(json['metadata']['name'], equals('Test Graph'));
      });
    });

    group('fromJson()', () {
      test('deserializes empty graph', () {
        final json = {
          'nodes': <dynamic>[],
          'connections': <dynamic>[],
          'viewport': {'x': 0.0, 'y': 0.0, 'zoom': 1.0},
          'metadata': <String, dynamic>{},
        };

        final graph = NodeGraph<String, dynamic>.fromJson(
          json,
          (j) => j as String? ?? '',
          (j) => j,
        );

        expect(graph.nodes, isEmpty);
        expect(graph.connections, isEmpty);
      });

      test('deserializes graph with nodes', () {
        final json = {
          'nodes': [
            {
              'id': 'node-1',
              'type': 'test',
              'x': 100.0,
              'y': 200.0,
              'width': 150.0,
              'height': 100.0,
              'data': 'test-data',
              'inputPorts': <dynamic>[],
              'outputPorts': <dynamic>[],
            },
          ],
          'connections': <dynamic>[],
          'viewport': {'x': 0.0, 'y': 0.0, 'zoom': 1.0},
          'metadata': <String, dynamic>{},
        };

        final graph = NodeGraph<String, dynamic>.fromJson(
          json,
          (j) => j as String? ?? '',
          (j) => j,
        );

        expect(graph.nodes.length, equals(1));
        expect(graph.nodes.first.id, equals('node-1'));
        expect(graph.nodes.first.position.value.dx, equals(100));
        expect(graph.nodes.first.position.value.dy, equals(200));
      });

      test('deserializes graph with connections', () {
        final json = {
          'nodes': <dynamic>[],
          'connections': [
            {
              'id': 'conn-1',
              'sourceNodeId': 'node-a',
              'sourcePortId': 'out',
              'targetNodeId': 'node-b',
              'targetPortId': 'in',
            },
          ],
          'viewport': {'x': 0.0, 'y': 0.0, 'zoom': 1.0},
          'metadata': <String, dynamic>{},
        };

        final graph = NodeGraph<String, dynamic>.fromJson(
          json,
          (j) => j as String? ?? '',
          (j) => j,
        );

        expect(graph.connections.length, equals(1));
        expect(graph.connections.first.id, equals('conn-1'));
        expect(graph.connections.first.sourceNodeId, equals('node-a'));
      });

      test('deserializes graph with viewport', () {
        final json = {
          'nodes': <dynamic>[],
          'connections': <dynamic>[],
          'viewport': {'x': 150.0, 'y': 250.0, 'zoom': 2.0},
          'metadata': <String, dynamic>{},
        };

        final graph = NodeGraph<String, dynamic>.fromJson(
          json,
          (j) => j as String? ?? '',
          (j) => j,
        );

        expect(graph.viewport.x, equals(150));
        expect(graph.viewport.y, equals(250));
        expect(graph.viewport.zoom, equals(2.0));
      });

      test('deserializes graph with metadata', () {
        final json = {
          'nodes': <dynamic>[],
          'connections': <dynamic>[],
          'viewport': {'x': 0.0, 'y': 0.0, 'zoom': 1.0},
          'metadata': {'key': 'value', 'count': 42},
        };

        final graph = NodeGraph<String, dynamic>.fromJson(
          json,
          (j) => j as String? ?? '',
          (j) => j,
        );

        expect(graph.metadata['key'], equals('value'));
        expect(graph.metadata['count'], equals(42));
      });

      test('handles missing optional fields with defaults', () {
        final json = {'nodes': <dynamic>[], 'connections': <dynamic>[]};

        final graph = NodeGraph<String, dynamic>.fromJson(
          json,
          (j) => j as String? ?? '',
          (j) => j,
        );

        expect(graph.viewport.x, equals(0.0));
        expect(graph.viewport.y, equals(0.0));
        expect(graph.viewport.zoom, equals(1.0));
        expect(graph.metadata, isEmpty);
      });
    });

    group('fromJsonString()', () {
      test('deserializes from JSON string', () {
        const jsonString = '''
        {
          "nodes": [
            {
              "id": "node-1",
              "type": "test",
              "x": 50.0,
              "y": 75.0,
              "width": 100.0,
              "height": 80.0,
              "data": "string-data",
              "inputPorts": [],
              "outputPorts": []
            }
          ],
          "connections": [],
          "viewport": {"x": 0.0, "y": 0.0, "zoom": 1.0},
          "metadata": {}
        }
        ''';

        final graph = NodeGraph.fromJsonString<String, dynamic>(
          jsonString,
          (j) => j as String? ?? '',
          (j) => j,
        );

        expect(graph.nodes.length, equals(1));
        expect(graph.nodes.first.id, equals('node-1'));
      });
    });

    group('toJsonString()', () {
      test('serializes to compact JSON string', () {
        final graph = NodeGraph<String, dynamic>(
          nodes: [createTestNode(id: 'node-1', data: 'data-1')],
        );

        final jsonString = graph.toJsonString();

        expect(jsonString, isNotEmpty);
        expect(jsonString, isNot(contains('\n'))); // Not indented
        expect(jsonString, contains('"node-1"'));
      });

      test('serializes to indented JSON string', () {
        final graph = NodeGraph<String, dynamic>(
          nodes: [createTestNode(id: 'node-1', data: 'data-1')],
        );

        final jsonString = graph.toJsonString(indent: true);

        expect(jsonString, contains('\n'));
        expect(jsonString, contains('  ')); // Indented
      });
    });

    group('Round-trip Serialization', () {
      test('round-trips graph with nodes', () {
        final originalNodes = [
          createTestNode(
            id: 'node-1',
            data: 'data-1',
            position: const Offset(100, 200),
          ),
          createTestNode(
            id: 'node-2',
            data: 'data-2',
            position: const Offset(300, 400),
          ),
        ];

        final original = NodeGraph<String, dynamic>(nodes: originalNodes);
        final json = original.toJson((v) => v, (v) => v);
        final restored = NodeGraph<String, dynamic>.fromJson(
          json,
          (j) => j as String? ?? '',
          (j) => j,
        );

        expect(restored.nodes.length, equals(original.nodes.length));
        for (var i = 0; i < original.nodes.length; i++) {
          expect(restored.nodes[i].id, equals(original.nodes[i].id));
          expect(
            restored.nodes[i].position.value,
            equals(original.nodes[i].position.value),
          );
        }
      });

      test('round-trips graph with connections', () {
        final connections = [
          createTestConnection(
            id: 'conn-1',
            sourceNodeId: 'A',
            sourcePortId: 'out',
            targetNodeId: 'B',
            targetPortId: 'in',
          ),
          createTestConnection(
            id: 'conn-2',
            sourceNodeId: 'B',
            sourcePortId: 'out',
            targetNodeId: 'C',
            targetPortId: 'in',
          ),
        ];

        final original = NodeGraph<String, dynamic>(connections: connections);
        final json = original.toJson((v) => v, (v) => v);
        final restored = NodeGraph<String, dynamic>.fromJson(
          json,
          (j) => j as String? ?? '',
          (j) => j,
        );

        expect(restored.connections.length, equals(2));
        expect(restored.connections[0].id, equals('conn-1'));
        expect(restored.connections[1].id, equals('conn-2'));
      });

      test('round-trips graph with viewport', () {
        const originalViewport = GraphViewport(x: 123, y: 456, zoom: 2.5);
        final original = NodeGraph<String, dynamic>(viewport: originalViewport);

        final json = original.toJson((v) => v, (v) => v);
        final restored = NodeGraph<String, dynamic>.fromJson(
          json,
          (j) => j as String? ?? '',
          (j) => j,
        );

        expect(restored.viewport.x, equals(123));
        expect(restored.viewport.y, equals(456));
        expect(restored.viewport.zoom, equals(2.5));
      });

      test('round-trips graph with metadata', () {
        final originalMetadata = {
          'version': '1.0',
          'description': 'Test graph',
          'count': 5,
          'active': true,
        };

        final original = NodeGraph<String, dynamic>(metadata: originalMetadata);
        final json = original.toJson((v) => v, (v) => v);
        final restored = NodeGraph<String, dynamic>.fromJson(
          json,
          (j) => j as String? ?? '',
          (j) => j,
        );

        expect(restored.metadata['version'], equals('1.0'));
        expect(restored.metadata['description'], equals('Test graph'));
        expect(restored.metadata['count'], equals(5));
        expect(restored.metadata['active'], equals(true));
      });

      test('round-trips complete graph', () {
        final nodes = [
          createTestNodeWithPorts(id: 'node-A'),
          createTestNodeWithPorts(id: 'node-B'),
        ];
        final connections = [
          createTestConnection(sourceNodeId: 'node-A', targetNodeId: 'node-B'),
        ];
        const viewport = GraphViewport(x: 50, y: 100, zoom: 1.5);
        final metadata = {'name': 'Complete Test'};

        final original = NodeGraph<String, dynamic>(
          nodes: nodes,
          connections: connections,
          viewport: viewport,
          metadata: metadata,
        );

        final jsonString = original.toJsonString();
        final restored = NodeGraph.fromJsonString<String, dynamic>(
          jsonString,
          (j) => j as String? ?? '',
          (j) => j,
        );

        expect(restored.nodes.length, equals(2));
        expect(restored.connections.length, equals(1));
        expect(restored.viewport.zoom, equals(1.5));
        expect(restored.metadata['name'], equals('Complete Test'));
      });
    });

    group('Special Node Type Serialization', () {
      test('deserializes GroupNode with type routing', () {
        final json = {
          'nodes': [
            {
              'id': 'group-1',
              'type': 'group',
              'x': 100.0,
              'y': 200.0,
              'width': 300.0,
              'height': 200.0,
              'title': 'Test Group',
              'data': 'group-data',
              'color': Colors.blue.toARGB32(),
              'behavior': 'bounds',
              'nodeIds': <String>[],
              'inputPorts': <dynamic>[],
              'outputPorts': <dynamic>[],
            },
          ],
          'connections': <dynamic>[],
          'viewport': {'x': 0.0, 'y': 0.0, 'zoom': 1.0},
          'metadata': <String, dynamic>{},
        };

        final graph = NodeGraph<String, dynamic>.fromJson(
          json,
          (j) => j as String? ?? '',
          (j) => j,
        );

        expect(graph.nodes.length, equals(1));
        expect(graph.nodes.first, isA<GroupNode<String>>());
        expect(
          (graph.nodes.first as GroupNode).currentTitle,
          equals('Test Group'),
        );
      });

      test('deserializes CommentNode with type routing', () {
        final json = {
          'nodes': [
            {
              'id': 'comment-1',
              'type': 'comment',
              'x': 50.0,
              'y': 75.0,
              'width': 200.0,
              'height': 100.0,
              'text': 'This is a comment',
              'data': 'comment-data',
              'color': Colors.yellow.toARGB32(),
            },
          ],
          'connections': <dynamic>[],
          'viewport': {'x': 0.0, 'y': 0.0, 'zoom': 1.0},
          'metadata': <String, dynamic>{},
        };

        final graph = NodeGraph<String, dynamic>.fromJson(
          json,
          (j) => j as String? ?? '',
          (j) => j,
        );

        expect(graph.nodes.length, equals(1));
        expect(graph.nodes.first, isA<CommentNode<String>>());
        expect(
          (graph.nodes.first as CommentNode).text,
          equals('This is a comment'),
        );
      });

      test('preserves regular nodes with custom types', () {
        final json = {
          'nodes': [
            {
              'id': 'custom-1',
              'type': 'custom-processor',
              'x': 0.0,
              'y': 0.0,
              'width': 150.0,
              'height': 100.0,
              'data': 'custom-data',
              'inputPorts': <dynamic>[],
              'outputPorts': <dynamic>[],
            },
          ],
          'connections': <dynamic>[],
          'viewport': {'x': 0.0, 'y': 0.0, 'zoom': 1.0},
          'metadata': <String, dynamic>{},
        };

        final graph = NodeGraph<String, dynamic>.fromJson(
          json,
          (j) => j as String? ?? '',
          (j) => j,
        );

        expect(graph.nodes.first, isA<Node<String>>());
        expect(graph.nodes.first, isNot(isA<GroupNode<String>>()));
        expect(graph.nodes.first, isNot(isA<CommentNode<String>>()));
        expect(graph.nodes.first.type, equals('custom-processor'));
      });
    });
  });

  // ===========================================================================
  // MAP DATA TYPE CONVENIENCE METHODS
  // ===========================================================================

  group('Map Data Type Convenience Methods', () {
    group('fromJsonMap()', () {
      test('deserializes graph with Map data type', () {
        final json = {
          'nodes': [
            {
              'id': 'node-1',
              'type': 'test',
              'x': 100.0,
              'y': 200.0,
              'width': 150.0,
              'height': 100.0,
              'data': {'key': 'value', 'count': 42},
              'inputPorts': <dynamic>[],
              'outputPorts': <dynamic>[],
            },
          ],
          'connections': <dynamic>[],
          'viewport': {'x': 0.0, 'y': 0.0, 'zoom': 1.0},
          'metadata': <String, dynamic>{},
        };

        final graph = NodeGraph.fromJsonMap(json);

        expect(graph.nodes.length, equals(1));
        expect(graph.nodes.first.data, isA<Map<String, dynamic>>());
        expect(graph.nodes.first.data['key'], equals('value'));
        expect(graph.nodes.first.data['count'], equals(42));
      });
    });

    group('fromJsonStringMap()', () {
      test('deserializes from JSON string with Map data type', () {
        const jsonString = '''
        {
          "nodes": [
            {
              "id": "node-1",
              "type": "test",
              "x": 0.0,
              "y": 0.0,
              "width": 100.0,
              "height": 80.0,
              "data": {"message": "hello"},
              "inputPorts": [],
              "outputPorts": []
            }
          ],
          "connections": [],
          "viewport": {"x": 0.0, "y": 0.0, "zoom": 1.0},
          "metadata": {}
        }
        ''';

        final graph = NodeGraph.fromJsonStringMap(jsonString);

        expect(graph.nodes.first.data['message'], equals('hello'));
      });
    });
  });

  // ===========================================================================
  // DEFAULT NODE FACTORY TESTS
  // ===========================================================================

  group('defaultNodeFromJson', () {
    test('routes group type to GroupNode', () {
      final json = {
        'id': 'group-1',
        'type': 'group',
        'x': 0.0,
        'y': 0.0,
        'width': 200.0,
        'height': 150.0,
        'title': 'My Group',
        'data': 'data',
        'color': Colors.blue.toARGB32(),
        'behavior': 'bounds',
        'nodeIds': <String>[],
      };

      final node = defaultNodeFromJson<String>(json, (j) => j as String? ?? '');

      expect(node, isA<GroupNode<String>>());
    });

    test('routes comment type to CommentNode', () {
      final json = {
        'id': 'comment-1',
        'type': 'comment',
        'x': 0.0,
        'y': 0.0,
        'width': 200.0,
        'height': 100.0,
        'text': 'A note',
        'data': 'data',
        'color': Colors.yellow.toARGB32(),
      };

      final node = defaultNodeFromJson<String>(json, (j) => j as String? ?? '');

      expect(node, isA<CommentNode<String>>());
    });

    test('routes other types to base Node', () {
      final json = {
        'id': 'custom-1',
        'type': 'processor',
        'x': 0.0,
        'y': 0.0,
        'width': 150.0,
        'height': 100.0,
        'data': 'data',
        'inputPorts': <dynamic>[],
        'outputPorts': <dynamic>[],
      };

      final node = defaultNodeFromJson<String>(json, (j) => j as String? ?? '');

      expect(node, isA<Node<String>>());
      expect(node, isNot(isA<GroupNode<String>>()));
      expect(node, isNot(isA<CommentNode<String>>()));
    });
  });

  // ===========================================================================
  // EDGE CASES AND VALIDATION
  // ===========================================================================

  group('Edge Cases and Validation', () {
    test('handles graph with many nodes', () {
      final nodes = List.generate(
        100,
        (i) => createTestNode(id: 'node-$i', position: Offset(i * 100.0, 0)),
      );

      final graph = NodeGraph<String, dynamic>(nodes: nodes);

      expect(graph.nodes.length, equals(100));
      expect(graph.getNodeById('node-50'), isNotNull);
      expect(graph.getNodeIndex('node-99'), equals(99));
    });

    test('handles graph with many connections', () {
      final nodes = List.generate(
        50,
        (i) => createTestNodeWithPorts(id: 'node-$i'),
      );

      final connections = List.generate(
        49,
        (i) => createTestConnection(
          id: 'conn-$i',
          sourceNodeId: 'node-$i',
          sourcePortId: 'output-1',
          targetNodeId: 'node-${i + 1}',
          targetPortId: 'input-1',
        ),
      );

      final graph = NodeGraph<String, dynamic>(
        nodes: nodes,
        connections: connections,
      );

      expect(graph.connections.length, equals(49));
      expect(graph.getNodeConnections('node-25').length, equals(2));
    });

    test('handles nodes at extreme positions', () {
      final nodes = [
        createTestNode(
          id: 'far-negative',
          position: const Offset(-10000, -10000),
        ),
        createTestNode(
          id: 'far-positive',
          position: const Offset(10000, 10000),
        ),
      ];

      final graph = NodeGraph<String, dynamic>(nodes: nodes);
      final bounds = graph.getBounds();

      expect(bounds.left, equals(-10000));
      expect(bounds.top, equals(-10000));
    });

    test('handles empty node list passed explicitly', () {
      final graph = NodeGraph<String, dynamic>(
        nodes: const [],
        connections: const [],
      );

      expect(graph.nodes, isEmpty);
      expect(graph.getRootNodes(), isEmpty);
      expect(graph.getLeafNodes(), isEmpty);
    });

    test('handles connection to non-existent node', () {
      final connections = [
        createTestConnection(
          sourceNodeId: 'non-existent-source',
          targetNodeId: 'non-existent-target',
        ),
      ];

      final graph = NodeGraph<String, dynamic>(connections: connections);

      // Graph should still be valid, just no nodes to match
      expect(graph.connections.length, equals(1));
      expect(graph.getNodeById('non-existent-source'), isNull);
    });

    test('handles self-referencing node ID in connections', () {
      final connections = [
        createTestConnection(sourceNodeId: 'self', targetNodeId: 'self'),
      ];

      final graph = NodeGraph<String, dynamic>(
        nodes: [createTestNodeWithPorts(id: 'self')],
        connections: connections,
      );

      expect(graph.areNodesConnected('self', 'self'), isTrue);
      expect(graph.hasCircularDependency(), isTrue);
    });

    test('JSON with null values in metadata', () {
      final json = {
        'nodes': <dynamic>[],
        'connections': <dynamic>[],
        'viewport': {'x': 0.0, 'y': 0.0, 'zoom': 1.0},
        'metadata': {'nullValue': null, 'realValue': 'exists'},
      };

      final graph = NodeGraph<String, dynamic>.fromJson(
        json,
        (j) => j as String? ?? '',
        (j) => j,
      );

      expect(graph.metadata['nullValue'], isNull);
      expect(graph.metadata['realValue'], equals('exists'));
    });

    test('JSON with integer viewport values', () {
      final json = {
        'nodes': <dynamic>[],
        'connections': <dynamic>[],
        'viewport': {'x': 100, 'y': 200, 'zoom': 2}, // Integers
        'metadata': <String, dynamic>{},
      };

      final graph = NodeGraph<String, dynamic>.fromJson(
        json,
        (j) => j as String? ?? '',
        (j) => j,
      );

      expect(graph.viewport.x, equals(100.0));
      expect(graph.viewport.y, equals(200.0));
      expect(graph.viewport.zoom, equals(2.0));
    });
  });

  // ===========================================================================
  // CUSTOM NODE FACTORY TESTS
  // ===========================================================================

  group('Custom Node Factory', () {
    test('uses custom nodeFromJson when provided', () {
      var customFactoryCalled = false;

      Node<String> customFactory(
        Map<String, dynamic> json,
        String Function(Object? json) fromJsonT,
      ) {
        customFactoryCalled = true;
        return Node<String>.fromJson(json, fromJsonT);
      }

      final json = {
        'nodes': [
          {
            'id': 'custom-1',
            'type': 'test',
            'x': 0.0,
            'y': 0.0,
            'width': 100.0,
            'height': 80.0,
            'data': 'data',
            'inputPorts': <dynamic>[],
            'outputPorts': <dynamic>[],
          },
        ],
        'connections': <dynamic>[],
        'viewport': {'x': 0.0, 'y': 0.0, 'zoom': 1.0},
        'metadata': <String, dynamic>{},
      };

      NodeGraph<String, dynamic>.fromJson(
        json,
        (j) => j as String? ?? '',
        (j) => j,
        nodeFromJson: customFactory,
      );

      expect(customFactoryCalled, isTrue);
    });
  });

  // ===========================================================================
  // TYPED CONNECTION DATA TESTS
  // ===========================================================================

  group('Typed Connection Data', () {
    test('handles connections with typed data', () {
      final json = {
        'nodes': <dynamic>[],
        'connections': [
          {
            'id': 'conn-1',
            'sourceNodeId': 'A',
            'sourcePortId': 'out',
            'targetNodeId': 'B',
            'targetPortId': 'in',
            'data': {'weight': 1.5, 'label': 'priority'},
          },
        ],
        'viewport': {'x': 0.0, 'y': 0.0, 'zoom': 1.0},
        'metadata': <String, dynamic>{},
      };

      final graph = NodeGraph<String, Map<String, dynamic>>.fromJson(
        json,
        (j) => j as String? ?? '',
        (j) => j as Map<String, dynamic>? ?? {},
      );

      expect(graph.connections.first.data, isNotNull);
      expect(graph.connections.first.data!['weight'], equals(1.5));
      expect(graph.connections.first.data!['label'], equals('priority'));
    });

    test('handles connections without data', () {
      final json = {
        'nodes': <dynamic>[],
        'connections': [
          {
            'id': 'conn-1',
            'sourceNodeId': 'A',
            'sourcePortId': 'out',
            'targetNodeId': 'B',
            'targetPortId': 'in',
          },
        ],
        'viewport': {'x': 0.0, 'y': 0.0, 'zoom': 1.0},
        'metadata': <String, dynamic>{},
      };

      final graph = NodeGraph<String, dynamic>.fromJson(
        json,
        (j) => j as String? ?? '',
        (j) => j,
      );

      expect(graph.connections.first.data, isNull);
    });
  });

  // ===========================================================================
  // FROMJSONMAP NULL DATA HANDLING TESTS
  // ===========================================================================

  group('fromJsonMap Null Data Handling', () {
    test('handles node with null data in fromJsonMap', () {
      final json = {
        'nodes': [
          {
            'id': 'node-1',
            'type': 'test',
            'x': 0.0,
            'y': 0.0,
            'width': 100.0,
            'height': 80.0,
            'data': null, // null data should become empty map
            'inputPorts': <dynamic>[],
            'outputPorts': <dynamic>[],
          },
        ],
        'connections': <dynamic>[],
        'viewport': {'x': 0.0, 'y': 0.0, 'zoom': 1.0},
        'metadata': <String, dynamic>{},
      };

      final graph = NodeGraph.fromJsonMap(json);

      expect(graph.nodes.length, equals(1));
      expect(graph.nodes.first.data, isA<Map<String, dynamic>>());
      expect(graph.nodes.first.data, isEmpty);
    });

    test('handles node with missing data field in fromJsonMap', () {
      final json = {
        'nodes': [
          {
            'id': 'node-1',
            'type': 'test',
            'x': 0.0,
            'y': 0.0,
            'width': 100.0,
            'height': 80.0,
            // 'data' field is completely missing
            'inputPorts': <dynamic>[],
            'outputPorts': <dynamic>[],
          },
        ],
        'connections': <dynamic>[],
        'viewport': {'x': 0.0, 'y': 0.0, 'zoom': 1.0},
        'metadata': <String, dynamic>{},
      };

      final graph = NodeGraph.fromJsonMap(json);

      expect(graph.nodes.length, equals(1));
      // The data should default to an empty map when missing
      expect(graph.nodes.first.data, isA<Map<String, dynamic>>());
    });

    test('fromJsonMap with custom nodeFromJson factory', () {
      var customFactoryCalled = false;

      Node<Map<String, dynamic>> customNodeFactory(
        Map<String, dynamic> json,
        Map<String, dynamic> Function(Object? json) fromJsonT,
      ) {
        customFactoryCalled = true;
        return Node<Map<String, dynamic>>.fromJson(json, fromJsonT);
      }

      final json = {
        'nodes': [
          {
            'id': 'custom-node',
            'type': 'test',
            'x': 0.0,
            'y': 0.0,
            'width': 100.0,
            'height': 80.0,
            'data': {'key': 'value'},
            'inputPorts': <dynamic>[],
            'outputPorts': <dynamic>[],
          },
        ],
        'connections': <dynamic>[],
        'viewport': {'x': 0.0, 'y': 0.0, 'zoom': 1.0},
        'metadata': <String, dynamic>{},
      };

      final graph = NodeGraph.fromJsonMap(
        json,
        nodeFromJson: customNodeFactory,
      );

      expect(customFactoryCalled, isTrue);
      expect(graph.nodes.first.id, equals('custom-node'));
    });

    test('fromJsonMap preserves connection data as dynamic', () {
      final json = {
        'nodes': <dynamic>[],
        'connections': [
          {
            'id': 'conn-with-data',
            'sourceNodeId': 'A',
            'sourcePortId': 'out',
            'targetNodeId': 'B',
            'targetPortId': 'in',
            'data': {'weight': 3.14, 'label': 'edge-label'},
          },
          {
            'id': 'conn-without-data',
            'sourceNodeId': 'B',
            'sourcePortId': 'out',
            'targetNodeId': 'C',
            'targetPortId': 'in',
          },
        ],
        'viewport': {'x': 0.0, 'y': 0.0, 'zoom': 1.0},
        'metadata': <String, dynamic>{},
      };

      final graph = NodeGraph.fromJsonMap(json);

      expect(graph.connections.length, equals(2));
      // Connection with data should preserve the dynamic data
      expect(graph.connections[0].data, isNotNull);
      expect(graph.connections[0].data['weight'], equals(3.14));
      expect(graph.connections[0].data['label'], equals('edge-label'));
      // Connection without data should have null
      expect(graph.connections[1].data, isNull);
    });
  });

  // ===========================================================================
  // FROMJSONSTRINGMAP TESTS
  // ===========================================================================

  group('fromJsonStringMap Extended', () {
    test('fromJsonStringMap with custom nodeFromJson factory', () {
      var customFactoryCalled = false;

      Node<Map<String, dynamic>> customNodeFactory(
        Map<String, dynamic> json,
        Map<String, dynamic> Function(Object? json) fromJsonT,
      ) {
        customFactoryCalled = true;
        return Node<Map<String, dynamic>>.fromJson(json, fromJsonT);
      }

      const jsonString = '''
      {
        "nodes": [
          {
            "id": "string-map-node",
            "type": "test",
            "x": 50.0,
            "y": 100.0,
            "width": 120.0,
            "height": 90.0,
            "data": {"value": 42},
            "inputPorts": [],
            "outputPorts": []
          }
        ],
        "connections": [],
        "viewport": {"x": 0.0, "y": 0.0, "zoom": 1.0},
        "metadata": {}
      }
      ''';

      final graph = NodeGraph.fromJsonStringMap(
        jsonString,
        nodeFromJson: customNodeFactory,
      );

      expect(customFactoryCalled, isTrue);
      expect(graph.nodes.first.id, equals('string-map-node'));
      expect(graph.nodes.first.data['value'], equals(42));
    });

    test('fromJsonStringMap handles GroupNode type routing', () {
      const jsonString = '''
      {
        "nodes": [
          {
            "id": "group-from-string",
            "type": "group",
            "x": 0.0,
            "y": 0.0,
            "width": 300.0,
            "height": 200.0,
            "title": "String Map Group",
            "data": {"groupData": true},
            "color": 4278190335,
            "behavior": "bounds",
            "nodeIds": []
          }
        ],
        "connections": [],
        "viewport": {"x": 0.0, "y": 0.0, "zoom": 1.0},
        "metadata": {}
      }
      ''';

      final graph = NodeGraph.fromJsonStringMap(jsonString);

      expect(graph.nodes.first, isA<GroupNode<Map<String, dynamic>>>());
      expect(
        (graph.nodes.first as GroupNode).currentTitle,
        equals('String Map Group'),
      );
    });

    test('fromJsonStringMap handles CommentNode type routing', () {
      const jsonString = '''
      {
        "nodes": [
          {
            "id": "comment-from-string",
            "type": "comment",
            "x": 100.0,
            "y": 50.0,
            "width": 180.0,
            "height": 80.0,
            "text": "A comment from JSON string",
            "data": {"note": "important"},
            "color": 4294961979
          }
        ],
        "connections": [],
        "viewport": {"x": 0.0, "y": 0.0, "zoom": 1.0},
        "metadata": {}
      }
      ''';

      final graph = NodeGraph.fromJsonStringMap(jsonString);

      expect(graph.nodes.first, isA<CommentNode<Map<String, dynamic>>>());
      expect(
        (graph.nodes.first as CommentNode).text,
        equals('A comment from JSON string'),
      );
    });
  });

  // ===========================================================================
  // FROMJSONSTRING WITH CUSTOM NODEFROMJSON TESTS
  // ===========================================================================

  group('fromJsonString with Custom nodeFromJson', () {
    test('uses custom nodeFromJson when provided', () {
      var customFactoryCalled = false;

      Node<String> customFactory(
        Map<String, dynamic> json,
        String Function(Object? json) fromJsonT,
      ) {
        customFactoryCalled = true;
        return Node<String>.fromJson(json, fromJsonT);
      }

      const jsonString = '''
      {
        "nodes": [
          {
            "id": "typed-node",
            "type": "test",
            "x": 0.0,
            "y": 0.0,
            "width": 100.0,
            "height": 80.0,
            "data": "typed-data",
            "inputPorts": [],
            "outputPorts": []
          }
        ],
        "connections": [],
        "viewport": {"x": 0.0, "y": 0.0, "zoom": 1.0},
        "metadata": {}
      }
      ''';

      NodeGraph.fromJsonString<String, dynamic>(
        jsonString,
        (j) => j as String? ?? '',
        (j) => j,
        nodeFromJson: customFactory,
      );

      expect(customFactoryCalled, isTrue);
    });
  });
}
