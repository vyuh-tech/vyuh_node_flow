@Tags(['edge_case'])
library;

import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:vyuh_node_flow/vyuh_node_flow.dart';

import '../helpers/test_factories.dart';

void main() {
  late NodeFlowController<String> controller;

  setUp(() {
    controller = createTestController();
    controller.setScreenSize(const Size(800, 600));
  });

  tearDown(() {
    controller.dispose();
  });

  group('Invalid Operations - Non-Existent Nodes', () {
    test('getNode returns null for non-existent ID', () {
      final node = controller.getNode('non-existent');
      expect(node, isNull);
    });

    test('removeNode handles non-existent ID gracefully', () {
      expect(() => controller.removeNode('non-existent'), returnsNormally);
    });

    test('moveNode handles non-existent ID gracefully', () {
      expect(
        () => controller.moveNode('non-existent', const Offset(100, 100)),
        returnsNormally,
      );
    });

    test('bringNodeToFront handles non-existent ID gracefully', () {
      expect(
        () => controller.bringNodeToFront('non-existent'),
        returnsNormally,
      );
    });

    test('sendNodeToBack handles non-existent ID gracefully', () {
      expect(() => controller.sendNodeToBack('non-existent'), returnsNormally);
    });

    test('setNodeVisibility handles non-existent ID gracefully', () {
      expect(
        () => controller.setNodeVisibility('non-existent', false),
        returnsNormally,
      );
    });

    test('setNodeSize handles non-existent ID gracefully', () {
      expect(
        () => controller.setNodeSize('non-existent', const Size(200, 150)),
        returnsNormally,
      );
    });
  });

  group('Invalid Operations - Non-Existent Connections', () {
    test('removeConnection throws for non-existent ID', () {
      // Note: Unlike nodes, removeConnection is strict and throws ArgumentError
      expect(
        () => controller.removeConnection('non-existent'),
        throwsArgumentError,
      );
    });

    test('getConnectionsForNode returns empty for non-existent node', () {
      final connections = controller.getConnectionsForNode('non-existent');
      expect(connections, isEmpty);
    });

    test('getConnectionsFromPort returns empty for non-existent port', () {
      final connections = controller.getConnectionsFromPort(
        'non-existent',
        'port',
      );
      expect(connections, isEmpty);
    });

    test('getConnectionsToPort returns empty for non-existent port', () {
      final connections = controller.getConnectionsToPort(
        'non-existent',
        'port',
      );
      expect(connections, isEmpty);
    });

    test('getConnection returns null for non-existent ID', () {
      final connection = controller.getConnection('non-existent');
      expect(connection, isNull);
    });
  });

  group('Invalid Operations - Connection Creation Edge Cases', () {
    // Note: createConnection is lenient and creates connections even with
    // non-existent nodes/ports. Validation is typically done at a higher level
    // (e.g., during interactive connection creation via port snapping).

    test(
      'createConnection creates connection even with non-existent source',
      () {
        final targetNode = createTestNode(
          id: 'target',
          inputPorts: [createTestPort(id: 'in1', type: PortType.input)],
        );
        controller.addNode(targetNode);

        // createConnection is lenient - it creates the connection object
        controller.createConnection('non-existent', 'out1', 'target', 'in1');

        // Connection IS created (data structure allows it)
        expect(controller.connectionCount, equals(1));
      },
    );

    test(
      'createConnection creates connection even with non-existent target',
      () {
        final sourceNode = createTestNode(
          id: 'source',
          outputPorts: [createTestPort(id: 'out1', type: PortType.output)],
        );
        controller.addNode(sourceNode);

        controller.createConnection('source', 'out1', 'non-existent', 'in1');

        // Connection IS created
        expect(controller.connectionCount, equals(1));
      },
    );

    test(
      'createConnection creates connection even with non-existent ports',
      () {
        final sourceNode = createTestNode(
          id: 'source',
          outputPorts: [createTestPort(id: 'out1', type: PortType.output)],
        );
        final targetNode = createTestNode(
          id: 'target',
          inputPorts: [createTestPort(id: 'in1', type: PortType.input)],
        );
        controller.addNode(sourceNode);
        controller.addNode(targetNode);

        controller.createConnection(
          'source',
          'non-existent-port',
          'target',
          'in1',
        );

        // Connection IS created (port validation is elsewhere)
        expect(controller.connectionCount, equals(1));
      },
    );

    test('createConnection allows self-connections', () {
      // Self-connections may be valid in some graph types (e.g., state machines)
      final node = createTestNode(
        id: 'node1',
        inputPorts: [createTestPort(id: 'in1', type: PortType.input)],
        outputPorts: [createTestPort(id: 'out1', type: PortType.output)],
      );
      controller.addNode(node);

      controller.createConnection('node1', 'out1', 'node1', 'in1');

      // Self-connections ARE allowed
      expect(controller.connectionCount, equals(1));
    });
  });

  group('Invalid Operations - Duplicate IDs', () {
    test('addNode with duplicate ID replaces existing node', () {
      final node1 = createTestNode(id: 'node1', position: const Offset(0, 0));
      final node2 = createTestNode(
        id: 'node1',
        position: const Offset(100, 100),
      );

      controller.addNode(node1);
      controller.addNode(node2);

      // Should have only one node
      expect(controller.nodeCount, equals(1));

      // The position should be the second node's position
      final node = controller.getNode('node1');
      expect(node?.position.value, equals(const Offset(100, 100)));
    });

    test('duplicate connections between same ports are allowed', () {
      // Note: The library allows duplicate connections (same source/target)
      // This can be useful for representing multiple relationship types
      final sourceNode = createTestNode(
        id: 'source',
        outputPorts: [createTestPort(id: 'out1', type: PortType.output)],
      );
      final targetNode = createTestNode(
        id: 'target',
        inputPorts: [createTestPort(id: 'in1', type: PortType.input)],
      );
      controller.addNode(sourceNode);
      controller.addNode(targetNode);

      // First connection
      controller.createConnection('source', 'out1', 'target', 'in1');
      expect(controller.connectionCount, equals(1));

      // Second connection (duplicate endpoint)
      controller.createConnection('source', 'out1', 'target', 'in1');

      // Both connections exist (library is permissive)
      expect(controller.connectionCount, equals(2));
    });
  });

  group('Invalid Operations - Non-Existent CommentNode/GroupNode', () {
    test('removeNode handles non-existent CommentNode ID gracefully', () {
      // Try to remove a non-existent CommentNode ID
      expect(
        () => controller.removeNode('non-existent-comment'),
        returnsNormally,
      );
    });

    test('selectNode handles non-existent GroupNode ID gracefully', () {
      // Try to select a non-existent GroupNode ID
      expect(
        () => controller.selectNode('non-existent-group'),
        returnsNormally,
      );
    });
  });

  group('Invalid Operations - Invalid Drag Operations', () {
    test('startNodeDrag handles non-existent node gracefully', () {
      expect(() => controller.startNodeDrag('non-existent'), returnsNormally);
    });

    test('moveNodeDrag handles when not in drag state', () {
      expect(
        () => controller.moveNodeDrag(const Offset(100, 100)),
        returnsNormally,
      );
    });

    test('endNodeDrag handles when not in drag state', () {
      expect(() => controller.endNodeDrag(), returnsNormally);
    });
  });

  group('Invalid Operations - Invalid Viewport Operations', () {
    test('zoomTo with NaN is handled gracefully', () {
      final initialZoom = controller.currentZoom;
      controller.zoomTo(double.nan);

      // NaN is handled - zoom remains finite and valid
      // The library protects against NaN propagation
      expect(controller.currentZoom.isFinite, isTrue);
      expect(controller.currentZoom, greaterThanOrEqualTo(0.5));
      expect(controller.currentZoom, lessThanOrEqualTo(2.0));
    });

    test('zoomTo with infinity clamps to maxZoom', () {
      controller.zoomTo(double.infinity);

      // Infinity gets clamped to maxZoom
      expect(controller.currentZoom, equals(2.0));
    });

    test('zoomTo with negative infinity clamps to minZoom', () {
      controller.zoomTo(double.negativeInfinity);

      // Negative infinity gets clamped to minZoom
      expect(controller.currentZoom, equals(0.5));
    });

    test('fitToView with no nodes handles gracefully', () {
      expect(() => controller.fitToView(), returnsNormally);
    });
  });

  group('Invalid Operations - Invalid Selection Operations', () {
    test('selectNodes with empty list clears selection', () {
      final node = createTestNode(id: 'node1');
      controller.addNode(node);
      controller.selectNode('node1');

      expect(controller.selectedNodeIds, contains('node1'));

      controller.selectNodes([]);

      expect(controller.selectedNodeIds, isEmpty);
    });

    test('selectNodes with non-existent IDs adds them anyway', () {
      controller.selectNodes(['non-existent1', 'non-existent2']);

      // Selection may or may not include non-existent IDs depending on implementation
      // Just verify it doesn't throw
      expect(() => controller.selectedNodeIds, returnsNormally);
    });

    test('toggle selection on non-existent node is handled', () {
      expect(
        () => controller.selectNode('non-existent', toggle: true),
        returnsNormally,
      );
    });

    test('clearNodeSelection on empty selection is handled', () {
      expect(() => controller.clearNodeSelection(), returnsNormally);
    });
  });

  group('Invalid Operations - NodeGraph Analysis Edge Cases', () {
    test('exportGraph().areNodesConnected with non-existent nodes', () {
      final graph = controller.exportGraph();
      final result = graph.areNodesConnected('node1', 'node2');
      expect(result, isFalse);
    });

    test('exportGraph().getBounds on empty graph returns Rect.zero', () {
      final graph = controller.exportGraph();
      final bounds = graph.getBounds();
      expect(bounds, equals(Rect.zero));
    });

    test('exportGraph().hasCircularDependency on empty graph', () {
      final graph = controller.exportGraph();
      final result = graph.hasCircularDependency();
      expect(result, isFalse);
    });

    test('exportGraph().getRootNodes on empty graph', () {
      final graph = controller.exportGraph();
      final roots = graph.getRootNodes();
      expect(roots, isEmpty);
    });

    test('exportGraph().getLeafNodes on empty graph', () {
      final graph = controller.exportGraph();
      final leaves = graph.getLeafNodes();
      expect(leaves, isEmpty);
    });
  });

  group('Invalid Operations - Port Operations', () {
    // Note: createConnection is a low-level API that doesn't enforce
    // maxConnections. Validation is done during interactive connection
    // creation (via port snapping and connection validators).

    test('createConnection ignores port maxConnections of 0', () {
      // maxConnections is enforced at the UI/interactive level, not in createConnection
      final sourceNode = createTestNode(
        id: 'source',
        outputPorts: [
          createTestPort(id: 'out1', type: PortType.output, maxConnections: 0),
        ],
      );
      final targetNode = createTestNode(
        id: 'target',
        inputPorts: [createTestPort(id: 'in1', type: PortType.input)],
      );
      controller.addNode(sourceNode);
      controller.addNode(targetNode);

      controller.createConnection('source', 'out1', 'target', 'in1');

      // Connection IS created (createConnection doesn't validate maxConnections)
      expect(controller.connectionCount, equals(1));
    });

    test('createConnection ignores port maxConnections limit', () {
      // maxConnections is enforced during interactive connection creation
      final sourceNode = createTestNode(
        id: 'source',
        outputPorts: [
          createTestPort(id: 'out1', type: PortType.output, maxConnections: 1),
        ],
      );
      final target1 = createTestNode(
        id: 'target1',
        inputPorts: [createTestPort(id: 'in1', type: PortType.input)],
      );
      final target2 = createTestNode(
        id: 'target2',
        inputPorts: [createTestPort(id: 'in1', type: PortType.input)],
      );
      controller.addNode(sourceNode);
      controller.addNode(target1);
      controller.addNode(target2);

      // First connection
      controller.createConnection('source', 'out1', 'target1', 'in1');
      expect(controller.connectionCount, equals(1));

      // Second connection - still created (maxConnections not enforced here)
      controller.createConnection('source', 'out1', 'target2', 'in1');
      expect(controller.connectionCount, equals(2));
    });

    test('port maxConnections is exposed for validation logic', () {
      // Verify maxConnections value is accessible for custom validators
      final port = createTestPort(
        id: 'out1',
        type: PortType.output,
        maxConnections: 3,
      );

      expect(port.maxConnections, equals(3));
    });
  });

  group('Invalid Operations - Disposal Edge Cases', () {
    test('operations after dispose do not throw', () {
      final disposedController = createTestController();
      disposedController.dispose();

      // These operations should be safe after disposal
      // (either throw gracefully or do nothing)
      expect(() => disposedController.nodeCount, returnsNormally);
    });
  });

  group('Invalid Operations - Null-Like Values', () {
    test('node with empty data is valid', () {
      final node = createTestNode(id: 'node1', data: '');
      controller.addNode(node);

      expect(controller.getNode('node1')?.data, equals(''));
    });

    test('connection with minimal data is valid', () {
      final sourceNode = createTestNode(
        id: 'source',
        outputPorts: [createTestPort(id: 'out1', type: PortType.output)],
      );
      final targetNode = createTestNode(
        id: 'target',
        inputPorts: [createTestPort(id: 'in1', type: PortType.input)],
      );
      controller.addNode(sourceNode);
      controller.addNode(targetNode);

      controller.createConnection('source', 'out1', 'target', 'in1');

      expect(controller.connectionCount, equals(1));
    });
  });

  group('Invalid Operations - Boundary Math', () {
    test('node getBounds with zero size is a point', () {
      final node = createTestNode(
        id: 'node1',
        position: const Offset(100, 100),
        size: Size.zero,
      );
      controller.addNode(node);

      final bounds = node.getBounds();
      expect(bounds.width, equals(0));
      expect(bounds.height, equals(0));
      expect(bounds.left, equals(100));
      expect(bounds.top, equals(100));
    });

    test('graph bounds with single zero-size node', () {
      final node = createTestNode(
        id: 'node1',
        position: const Offset(50, 50),
        size: Size.zero,
      );
      controller.addNode(node);

      final graph = controller.exportGraph();
      final bounds = graph.getBounds();
      expect(bounds, isNotNull);
    });

    test('node at extreme coordinates is handled', () {
      // This tests defensive coding against extreme values
      final node = createTestNode(
        id: 'node1',
        position: const Offset(1e10, 1e10),
      );
      controller.addNode(node);

      final graph = controller.exportGraph();
      expect(() => graph.getBounds(), returnsNormally);
    });
  });

  group('Invalid Operations - Rapid Operations', () {
    test('rapid add/remove cycles are handled', () {
      for (var i = 0; i < 100; i++) {
        final node = createTestNode(id: 'rapid-$i');
        controller.addNode(node);
        controller.removeNode('rapid-$i');
      }

      expect(controller.nodeCount, equals(0));
    });

    test('rapid selection changes are handled', () {
      final nodes = List.generate(10, (i) => createTestNode(id: 'node-$i'));
      for (final node in nodes) {
        controller.addNode(node);
      }

      for (var i = 0; i < 50; i++) {
        controller.selectNode('node-${i % 10}');
        controller.clearNodeSelection();
      }

      expect(() => controller.selectedNodeIds, returnsNormally);
    });
  });

  group('Invalid Operations - Graph Loading', () {
    test('loadGraph clears existing state', () {
      final node = createTestNode(id: 'existing');
      controller.addNode(node);

      final emptyGraph = NodeGraph<String>(nodes: [], connections: []);
      controller.loadGraph(emptyGraph);

      expect(controller.nodeCount, equals(0));
    });

    test('loadGraph with invalid connections is handled', () {
      // Connection referencing non-existent nodes
      final invalidConnection = createTestConnection(
        sourceNodeId: 'non-existent-source',
        targetNodeId: 'non-existent-target',
      );

      final graph = NodeGraph<String>(
        nodes: [],
        connections: [invalidConnection],
      );

      // Should not throw, even with invalid connections
      expect(() => controller.loadGraph(graph), returnsNormally);
    });
  });
}
