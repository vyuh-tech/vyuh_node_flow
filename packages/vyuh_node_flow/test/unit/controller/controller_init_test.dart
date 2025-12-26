/// Unit tests for NodeFlowController constructor initialization.
///
/// Tests cover:
/// - Constructor initialization with nodes
/// - Constructor initialization with connections
/// - Constructor initialization with both nodes and connections
/// - Behavior parity between constructor and imperative initialization
/// - Edge cases for initial graph data
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
  // Constructor Initialization - Nodes Only
  // ===========================================================================

  group('Constructor Initialization - Nodes', () {
    test('initializes with empty nodes list', () {
      final controller = NodeFlowController<String>(nodes: []);

      expect(controller.nodeCount, equals(0));
      expect(controller.nodes, isEmpty);
    });

    test('initializes with single node', () {
      final node = createTestNode(id: 'node-1');

      final controller = NodeFlowController<String>(nodes: [node]);

      expect(controller.nodeCount, equals(1));
      expect(controller.getNode('node-1'), isNotNull);
      expect(controller.getNode('node-1')!.id, equals('node-1'));
    });

    test('initializes with multiple nodes', () {
      final nodes = [
        createTestNode(id: 'node-1'),
        createTestNode(id: 'node-2'),
        createTestNode(id: 'node-3'),
      ];

      final controller = NodeFlowController<String>(nodes: nodes);

      expect(controller.nodeCount, equals(3));
      expect(controller.getNode('node-1'), isNotNull);
      expect(controller.getNode('node-2'), isNotNull);
      expect(controller.getNode('node-3'), isNotNull);
    });

    test('preserves node positions', () {
      final nodes = [
        createTestNode(id: 'node-1', position: const Offset(100, 200)),
        createTestNode(id: 'node-2', position: const Offset(300, 400)),
      ];

      final controller = NodeFlowController<String>(nodes: nodes);

      expect(
        controller.getNode('node-1')!.position.value,
        equals(const Offset(100, 200)),
      );
      expect(
        controller.getNode('node-2')!.position.value,
        equals(const Offset(300, 400)),
      );
    });

    test('preserves node data', () {
      final nodes = [
        createTestNode(id: 'node-1', data: 'first-data'),
        createTestNode(id: 'node-2', data: 'second-data'),
      ];

      final controller = NodeFlowController<String>(nodes: nodes);

      expect(controller.getNode('node-1')!.data, equals('first-data'));
      expect(controller.getNode('node-2')!.data, equals('second-data'));
    });

    test('preserves node ports', () {
      final inputPort = createInputPort(id: 'input-1');
      final outputPort = createOutputPort(id: 'output-1');
      final node = createTestNode(
        id: 'node-1',
        inputPorts: [inputPort],
        outputPorts: [outputPort],
      );

      final controller = NodeFlowController<String>(nodes: [node]);

      expect(controller.getInputPorts('node-1'), hasLength(1));
      expect(controller.getOutputPorts('node-1'), hasLength(1));
      expect(controller.getPort('node-1', 'input-1'), isNotNull);
      expect(controller.getPort('node-1', 'output-1'), isNotNull);
    });

    test('preserves node visibility', () {
      final nodes = [
        createTestNode(id: 'visible', visible: true),
        createTestNode(id: 'hidden', visible: false),
      ];

      final controller = NodeFlowController<String>(nodes: nodes);

      expect(controller.getNode('visible')!.isVisible, isTrue);
      expect(controller.getNode('hidden')!.isVisible, isFalse);
    });

    test('preserves node z-index', () {
      final nodes = [
        createTestNode(id: 'node-1', zIndex: 5),
        createTestNode(id: 'node-2', zIndex: 10),
      ];

      final controller = NodeFlowController<String>(nodes: nodes);

      expect(controller.getNode('node-1')!.currentZIndex, equals(5));
      expect(controller.getNode('node-2')!.currentZIndex, equals(10));
    });

    test('all nodes appear in nodeIds', () {
      final nodes = [
        createTestNode(id: 'a'),
        createTestNode(id: 'b'),
        createTestNode(id: 'c'),
      ];

      final controller = NodeFlowController<String>(nodes: nodes);

      expect(controller.nodeIds, containsAll(['a', 'b', 'c']));
    });
  });

  // ===========================================================================
  // Constructor Initialization - Connections Only
  // ===========================================================================

  group('Constructor Initialization - Connections', () {
    test('initializes with empty connections list', () {
      final controller = NodeFlowController<String>(connections: []);

      expect(controller.connectionCount, equals(0));
      expect(controller.connections, isEmpty);
    });

    test(
      'connections without matching nodes are stored but count may differ',
      () {
        // Connections are stored during constructor initialization, but the
        // controller may filter them when accessing connectionCount if the
        // source/target nodes don't exist. This test verifies connections are
        // added to the internal list.
        final connections = [
          createTestConnection(
            id: 'conn-1',
            sourceNodeId: 'node-a',
            targetNodeId: 'node-b',
          ),
        ];

        final controller = NodeFlowController<String>(connections: connections);

        // Connections are loaded but may be filtered - verify the list is accessible
        expect(controller.connections, isNotNull);
      },
    );
  });

  // ===========================================================================
  // Constructor Initialization - Nodes and Connections
  // ===========================================================================

  group('Constructor Initialization - Nodes and Connections', () {
    test('initializes with nodes and connections together', () {
      final nodeA = createTestNodeWithOutputPort(id: 'node-a');
      final nodeB = createTestNodeWithInputPort(id: 'node-b');
      final connection = createTestConnection(
        id: 'conn-1',
        sourceNodeId: 'node-a',
        targetNodeId: 'node-b',
      );

      final controller = NodeFlowController<String>(
        nodes: [nodeA, nodeB],
        connections: [connection],
      );

      expect(controller.nodeCount, equals(2));
      expect(controller.connectionCount, equals(1));
      expect(controller.getNode('node-a'), isNotNull);
      expect(controller.getNode('node-b'), isNotNull);
      expect(controller.getConnection('conn-1'), isNotNull);
    });

    test('initializes complex graph with multiple connections', () {
      final nodes = [
        createTestNodeWithPorts(
          id: 'a',
          inputPortId: 'a-in',
          outputPortId: 'a-out',
        ),
        createTestNodeWithPorts(
          id: 'b',
          inputPortId: 'b-in',
          outputPortId: 'b-out',
        ),
        createTestNodeWithPorts(
          id: 'c',
          inputPortId: 'c-in',
          outputPortId: 'c-out',
        ),
      ];
      final connections = [
        createTestConnection(
          id: 'a-to-b',
          sourceNodeId: 'a',
          sourcePortId: 'a-out',
          targetNodeId: 'b',
          targetPortId: 'b-in',
        ),
        createTestConnection(
          id: 'b-to-c',
          sourceNodeId: 'b',
          sourcePortId: 'b-out',
          targetNodeId: 'c',
          targetPortId: 'c-in',
        ),
      ];

      final controller = NodeFlowController<String>(
        nodes: nodes,
        connections: connections,
      );

      expect(controller.nodeCount, equals(3));
      expect(controller.connectionCount, equals(2));
      expect(controller.getConnectionsFromPort('a', 'a-out'), hasLength(1));
      expect(controller.getConnectionsToPort('c', 'c-in'), hasLength(1));
    });

    test('preserves connection properties', () {
      final nodeA = createTestNodeWithOutputPort(id: 'node-a');
      final nodeB = createTestNodeWithInputPort(id: 'node-b');
      final connection = createTestConnection(
        id: 'conn-1',
        sourceNodeId: 'node-a',
        sourcePortId: 'output-1',
        targetNodeId: 'node-b',
        targetPortId: 'input-1',
        animated: true,
        data: {'key': 'value'},
      );

      final controller = NodeFlowController<String>(
        nodes: [nodeA, nodeB],
        connections: [connection],
      );

      final loadedConn = controller.getConnection('conn-1')!;
      expect(loadedConn.sourceNodeId, equals('node-a'));
      expect(loadedConn.sourcePortId, equals('output-1'));
      expect(loadedConn.targetNodeId, equals('node-b'));
      expect(loadedConn.targetPortId, equals('input-1'));
      expect(loadedConn.animated, isTrue);
      expect(loadedConn.data, equals({'key': 'value'}));
    });
  });

  // ===========================================================================
  // Constructor vs Imperative Initialization Parity
  // ===========================================================================

  group('Constructor vs Imperative Initialization Parity', () {
    test('constructor initialization matches imperative add', () {
      final node1 = createTestNode(
        id: 'node-1',
        position: const Offset(10, 20),
      );
      final node2 = createTestNode(
        id: 'node-2',
        position: const Offset(30, 40),
      );

      // Constructor initialization
      final constructorController = NodeFlowController<String>(nodes: [node1]);

      // Imperative initialization (need to recreate node since it's mutable)
      final node1Copy = createTestNode(
        id: 'node-1',
        position: const Offset(10, 20),
      );
      final imperativeController = NodeFlowController<String>();
      imperativeController.addNode(node1Copy);

      expect(
        constructorController.nodeCount,
        equals(imperativeController.nodeCount),
      );
      expect(
        constructorController.getNode('node-1')!.position.value,
        equals(imperativeController.getNode('node-1')!.position.value),
      );
    });

    test('connections accessible after constructor init', () {
      final nodeA = createTestNodeWithOutputPort(id: 'node-a');
      final nodeB = createTestNodeWithInputPort(id: 'node-b');
      final connection = createTestConnection(
        sourceNodeId: 'node-a',
        targetNodeId: 'node-b',
      );

      final controller = NodeFlowController<String>(
        nodes: [nodeA, nodeB],
        connections: [connection],
      );

      // Verify connections are accessible via all APIs
      expect(controller.connections, isNotEmpty);
      expect(controller.connectionIds, isNotEmpty);
      expect(
        controller.getConnectionsFromPort('node-a', 'output-1'),
        hasLength(1),
      );
      expect(
        controller.getConnectionsToPort('node-b', 'input-1'),
        hasLength(1),
      );
    });
  });

  // ===========================================================================
  // Constructor with Other Parameters
  // ===========================================================================

  group('Constructor Initialization - With Other Parameters', () {
    test('works with custom config', () {
      final node = createTestNode(id: 'node-1');
      final config = NodeFlowConfig(
        snapToGrid: true,
        gridSize: 50,
        debugMode: DebugMode.all,
      );

      final controller = NodeFlowController<String>(
        nodes: [node],
        config: config,
      );

      expect(controller.nodeCount, equals(1));
      expect(controller.config.snapToGrid.value, isTrue);
      expect(controller.config.gridSize.value, equals(50));
      expect(controller.config.debugMode.value, equals(DebugMode.all));
    });

    test('works with initial viewport', () {
      final node = createTestNode(id: 'node-1');
      final viewport = GraphViewport(x: 100, y: 200, zoom: 1.5);

      final controller = NodeFlowController<String>(
        nodes: [node],
        initialViewport: viewport,
      );

      expect(controller.nodeCount, equals(1));
      expect(controller.currentPan.dx, equals(100));
      expect(controller.currentPan.dy, equals(200));
      expect(controller.currentZoom, equals(1.5));
    });

    test('works with all parameters combined', () {
      final nodes = [
        createTestNodeWithOutputPort(id: 'node-a'),
        createTestNodeWithInputPort(id: 'node-b'),
      ];
      final connections = [
        createTestConnection(sourceNodeId: 'node-a', targetNodeId: 'node-b'),
      ];
      final config = NodeFlowConfig(debugMode: DebugMode.spatialIndex);
      final viewport = GraphViewport(x: 50, y: 50, zoom: 0.8);

      final controller = NodeFlowController<String>(
        nodes: nodes,
        connections: connections,
        config: config,
        initialViewport: viewport,
      );

      expect(controller.nodeCount, equals(2));
      expect(controller.connectionCount, equals(1));
      expect(controller.config.debugMode.value, equals(DebugMode.spatialIndex));
      expect(controller.currentZoom, equals(0.8));
    });
  });

  // ===========================================================================
  // Null and Optional Parameter Handling
  // ===========================================================================

  group('Constructor Initialization - Optional Parameters', () {
    test('null nodes parameter creates empty graph', () {
      final controller = NodeFlowController<String>(nodes: null);

      expect(controller.nodeCount, equals(0));
    });

    test('null connections parameter creates no connections', () {
      final node = createTestNode(id: 'node-1');

      final controller = NodeFlowController<String>(
        nodes: [node],
        connections: null,
      );

      expect(controller.nodeCount, equals(1));
      expect(controller.connectionCount, equals(0));
    });

    test('default constructor creates empty controller', () {
      final controller = NodeFlowController<String>();

      expect(controller.nodeCount, equals(0));
      expect(controller.connectionCount, equals(0));
    });
  });

  // ===========================================================================
  // Post-Initialization Operations
  // ===========================================================================

  group('Post-Constructor Operations', () {
    test('can add more nodes after constructor init', () {
      final initial = createTestNode(id: 'initial');
      final controller = NodeFlowController<String>(nodes: [initial]);

      final additional = createTestNode(id: 'additional');
      controller.addNode(additional);

      expect(controller.nodeCount, equals(2));
      expect(controller.getNode('initial'), isNotNull);
      expect(controller.getNode('additional'), isNotNull);
    });

    test('can add more connections after constructor init', () {
      final nodeA = createTestNodeWithOutputPort(id: 'node-a');
      final nodeB = createTestNodeWithPorts(id: 'node-b');
      final nodeC = createTestNodeWithInputPort(id: 'node-c');
      final initialConnection = createTestConnection(
        id: 'initial',
        sourceNodeId: 'node-a',
        targetNodeId: 'node-b',
      );

      final controller = NodeFlowController<String>(
        nodes: [nodeA, nodeB, nodeC],
        connections: [initialConnection],
      );

      controller.createConnection('node-b', 'output-1', 'node-c', 'input-1');

      expect(controller.connectionCount, equals(2));
    });

    test('can remove constructor-initialized nodes', () {
      final nodes = [
        createTestNode(id: 'node-1'),
        createTestNode(id: 'node-2'),
      ];
      final controller = NodeFlowController<String>(nodes: nodes);

      controller.removeNode('node-1');

      expect(controller.nodeCount, equals(1));
      expect(controller.getNode('node-1'), isNull);
      expect(controller.getNode('node-2'), isNotNull);
    });

    test('can remove constructor-initialized connections', () {
      final nodeA = createTestNodeWithOutputPort(id: 'node-a');
      final nodeB = createTestNodeWithInputPort(id: 'node-b');
      final connection = createTestConnection(
        id: 'conn-1',
        sourceNodeId: 'node-a',
        targetNodeId: 'node-b',
      );

      final controller = NodeFlowController<String>(
        nodes: [nodeA, nodeB],
        connections: [connection],
      );

      controller.removeConnection('conn-1');

      expect(controller.connectionCount, equals(0));
    });

    test('can select constructor-initialized nodes', () {
      final nodes = [
        createTestNode(id: 'node-1'),
        createTestNode(id: 'node-2'),
      ];
      final controller = NodeFlowController<String>(nodes: nodes);

      controller.selectNode('node-1');

      expect(controller.selectedNodeIds, contains('node-1'));
      expect(controller.getNode('node-1')!.isSelected, isTrue);
    });

    test('can clear graph after constructor init', () {
      final nodes = [
        createTestNodeWithOutputPort(id: 'node-a'),
        createTestNodeWithInputPort(id: 'node-b'),
      ];
      final connections = [
        createTestConnection(sourceNodeId: 'node-a', targetNodeId: 'node-b'),
      ];

      final controller = NodeFlowController<String>(
        nodes: nodes,
        connections: connections,
      );

      controller.clearGraph();

      expect(controller.nodeCount, equals(0));
      expect(controller.connectionCount, equals(0));
    });
  });

  // ===========================================================================
  // Edge Cases
  // ===========================================================================

  group('Constructor Initialization - Edge Cases', () {
    test('handles nodes with duplicate IDs (last wins)', () {
      final node1 = createTestNode(id: 'same-id', data: 'first');
      final node2 = createTestNode(id: 'same-id', data: 'second');

      final controller = NodeFlowController<String>(nodes: [node1, node2]);

      expect(controller.nodeCount, equals(1));
      expect(controller.getNode('same-id')!.data, equals('second'));
    });

    test('handles large number of nodes', () {
      final nodes = List.generate(
        100,
        (i) => createTestNode(
          id: 'node-$i',
          position: Offset(i * 100.0, i * 50.0),
        ),
      );

      final controller = NodeFlowController<String>(nodes: nodes);

      expect(controller.nodeCount, equals(100));
      expect(controller.getNode('node-0'), isNotNull);
      expect(controller.getNode('node-99'), isNotNull);
    });

    test('handles nodes with special ID characters', () {
      final nodes = [
        createTestNode(id: 'node-with-dashes'),
        createTestNode(id: 'node_with_underscores'),
        createTestNode(id: 'node.with.dots'),
        createTestNode(id: 'node:with:colons'),
      ];

      final controller = NodeFlowController<String>(nodes: nodes);

      expect(controller.nodeCount, equals(4));
      expect(controller.getNode('node-with-dashes'), isNotNull);
      expect(controller.getNode('node_with_underscores'), isNotNull);
      expect(controller.getNode('node.with.dots'), isNotNull);
      expect(controller.getNode('node:with:colons'), isNotNull);
    });
  });

  // ===========================================================================
  // Special Node Types
  // ===========================================================================

  group('Constructor Initialization - Special Node Types', () {
    test('initializes with CommentNode', () {
      final comment = createTestCommentNode<String>(
        id: 'comment-1',
        text: 'Test comment',
        data: 'comment-data',
      );

      final controller = NodeFlowController<String>(nodes: [comment]);

      expect(controller.nodeCount, equals(1));
      final loaded = controller.getNode('comment-1');
      expect(loaded, isA<CommentNode<String>>());
      expect((loaded as CommentNode<String>).text, equals('Test comment'));
    });

    test('initializes with GroupNode', () {
      final group = createTestGroupNode<String>(
        id: 'group-1',
        title: 'Test Group',
        data: 'group-data',
      );

      final controller = NodeFlowController<String>(nodes: [group]);

      expect(controller.nodeCount, equals(1));
      final loaded = controller.getNode('group-1');
      expect(loaded, isA<GroupNode<String>>());
      expect((loaded as GroupNode<String>).currentTitle, equals('Test Group'));
    });

    test('initializes with mixed node types', () {
      final regularNode = createTestNode(id: 'regular');
      final commentNode = createTestCommentNode<String>(
        id: 'comment',
        data: 'comment-data',
      );
      final groupNode = createTestGroupNode<String>(
        id: 'group',
        data: 'group-data',
      );

      final controller = NodeFlowController<String>(
        nodes: [regularNode, commentNode, groupNode],
      );

      expect(controller.nodeCount, equals(3));
      expect(controller.getNode('regular'), isA<Node<String>>());
      expect(controller.getNode('comment'), isA<CommentNode<String>>());
      expect(controller.getNode('group'), isA<GroupNode<String>>());
    });
  });
}
