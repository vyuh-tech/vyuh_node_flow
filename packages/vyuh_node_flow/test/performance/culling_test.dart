import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vyuh_node_flow/src/editor/drag_session.dart';
import 'package:vyuh_node_flow/vyuh_node_flow.dart';

void main() {
  group('Performance Culling Logic', () {
    late NodeFlowController<void> controller;

    setUp(() {
      controller = NodeFlowController<void>();

      // Initialize controller infrastructure
      controller.initController(
        theme: NodeFlowTheme.light,
        portSizeResolver: (port) => const Size(10, 10),
        nodeShapeBuilder: (node) => null,
        connectionHitTesterBuilder: (painter) =>
            (c, p) => false,
        connectionSegmentCalculator: (c) {
          // Return non-zero rects to ensure overlaps check passes
          // Rect.zero does not overlap anything (0 > 0 is false)
          if (c.id == 'c2') return [Rect.fromLTWH(10000, 0, 100, 10)];
          return [Rect.fromLTWH(0, 0, 100, 10)];
        },
      );
    });

    test('visibleNodes returns subset of total nodes based on viewport', () {
      const nodeCount = 1000;
      final nodes = List.generate(nodeCount, (i) {
        return Node(
          id: 'node_$i',
          type: 'default',
          position: Offset(i * 200.0, 0),
          data: null,
        )..size.value = const Size(100, 100);
      });

      controller.loadGraph(NodeGraph(nodes: nodes, connections: []));

      controller.setViewport(const GraphViewport(x: 0, y: 0, zoom: 1.0));
      controller.setScreenSize(const Size(800, 600));

      final visible = controller.visibleNodes;

      expect(visible.length, lessThan(50));
      expect(visible.length, greaterThan(0));
    });

    test('visibleConnections returns subset of total connections', () {
      final nodeA = Node(
        id: 'a',
        type: 'default',
        position: const Offset(0, 0),
        data: null,
      );
      final nodeB = Node(
        id: 'b',
        type: 'default',
        position: const Offset(200, 0),
        data: null,
      );

      final nodeFar1 = Node(
        id: 'f1',
        type: 'default',
        position: const Offset(10000, 0),
        data: null,
      );
      final nodeFar2 = Node(
        id: 'f2',
        type: 'default',
        position: const Offset(10200, 0),
        data: null,
      );

      final connVisible = Connection(
        id: 'c1',
        sourceNodeId: 'a',
        sourcePortId: 'out',
        targetNodeId: 'b',
        targetPortId: 'in',
      );

      final connHidden = Connection(
        id: 'c2',
        sourceNodeId: 'f1',
        sourcePortId: 'out',
        targetNodeId: 'f2',
        targetPortId: 'in',
      );

      controller.loadGraph(
        NodeGraph(
          nodes: [nodeA, nodeB, nodeFar1, nodeFar2],
          connections: [connVisible, connHidden],
        ),
      );

      controller.setViewport(const GraphViewport(x: 0, y: 0, zoom: 1.0));
      controller.setScreenSize(const Size(800, 600));

      final visible = controller.visibleConnections;

      expect(visible.length, 1);
      expect(visible.first.id, 'c1');
    });

    test('activeConnectionIds identifies connections on dragged node', () {
      final node1 = Node(
        id: 'n1',
        type: 'default',
        position: Offset.zero,
        data: null,
      );
      final node2 = Node(
        id: 'n2',
        type: 'default',
        position: const Offset(200, 0),
        data: null,
      );
      final conn = Connection(
        id: 'c1',
        sourceNodeId: 'n1',
        sourcePortId: 'out',
        targetNodeId: 'n2',
        targetPortId: 'in',
      );

      controller.loadGraph(
        NodeGraph(nodes: [node1, node2], connections: [conn]),
      );

      final session = controller.createSession(DragSessionType.nodeDrag);
      session.start();
      controller.startNodeDrag('n1');

      expect(controller.activeConnectionIds, contains('c1'));

      controller.endNodeDrag();
      session.end();

      expect(controller.activeConnectionIds, isEmpty);
    });

    test('activeNodeIds identifies single dragged node', () {
      final node1 = Node(
        id: 'n1',
        type: 'default',
        position: Offset.zero,
        data: null,
      );
      final node2 = Node(
        id: 'n2',
        type: 'default',
        position: const Offset(200, 0),
        data: null,
      );

      controller.loadGraph(NodeGraph(nodes: [node1, node2], connections: []));

      // Before drag - no active nodes
      expect(controller.activeNodeIds, isEmpty);

      // Start drag on n1 (not selected)
      final session = controller.createSession(DragSessionType.nodeDrag);
      session.start();
      controller.startNodeDrag('n1');

      expect(controller.activeNodeIds, contains('n1'));
      expect(controller.activeNodeIds.length, 1);

      controller.endNodeDrag();
      session.end();

      expect(controller.activeNodeIds, isEmpty);
    });

    test(
      'activeNodeIds includes all selected nodes during multi-select drag',
      () {
        final node1 = Node(
          id: 'n1',
          type: 'default',
          position: Offset.zero,
          data: null,
        );
        final node2 = Node(
          id: 'n2',
          type: 'default',
          position: const Offset(200, 0),
          data: null,
        );
        final node3 = Node(
          id: 'n3',
          type: 'default',
          position: const Offset(400, 0),
          data: null,
        );

        controller.loadGraph(
          NodeGraph(nodes: [node1, node2, node3], connections: []),
        );

        // Select n1 and n2
        controller.selectNodes(['n1', 'n2']);
        expect(controller.selectedNodeIds, containsAll(['n1', 'n2']));

        // Start drag on n1 (which is in selection)
        final session = controller.createSession(DragSessionType.nodeDrag);
        session.start();
        controller.startNodeDrag('n1');

        // Both selected nodes should be active
        expect(controller.activeNodeIds, containsAll(['n1', 'n2']));
        expect(controller.activeNodeIds.length, 2);
        // n3 should NOT be active
        expect(controller.activeNodeIds.contains('n3'), isFalse);

        controller.endNodeDrag();
        session.end();

        expect(controller.activeNodeIds, isEmpty);
      },
    );
  });
}
