@Tags(['edge_case'])
library;

import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:vyuh_node_flow/vyuh_node_flow.dart';

import '../helpers/test_factories.dart';

void main() {
  late NodeFlowController<String, dynamic> controller;

  setUp(() {
    controller = createTestController();
    controller.setScreenSize(const Size(800, 600));
  });

  tearDown(() {
    controller.dispose();
  });

  group('Boundary Conditions - Node Position', () {
    test('node at origin (0, 0)', () {
      final node = createTestNode(id: 'origin', position: Offset.zero);
      controller.addNode(node);

      expect(node.position.value, equals(Offset.zero));
      expect(controller.getNode('origin'), isNotNull);
    });

    test('node at negative coordinates', () {
      final node = createTestNode(
        id: 'negative',
        position: const Offset(-500, -300),
      );
      controller.addNode(node);

      expect(node.position.value.dx, equals(-500));
      expect(node.position.value.dy, equals(-300));
    });

    test('node at very large coordinates', () {
      final node = createTestNode(
        id: 'large',
        position: const Offset(1000000, 1000000),
      );
      controller.addNode(node);

      expect(node.position.value.dx, equals(1000000));
      expect(node.position.value.dy, equals(1000000));
    });

    test('move node to very large negative coordinates', () {
      final node = createTestNode(id: 'node1', position: Offset.zero);
      controller.addNode(node);

      controller.moveNode('node1', const Offset(-999999, -999999));

      expect(node.position.value.dx, equals(-999999));
      expect(node.position.value.dy, equals(-999999));
    });

    test('node with fractional coordinates', () {
      final node = createTestNode(
        id: 'fractional',
        position: const Offset(123.456, 789.012),
      );
      controller.addNode(node);

      expect(node.position.value.dx, closeTo(123.456, 0.001));
      expect(node.position.value.dy, closeTo(789.012, 0.001));
    });
  });

  group('Boundary Conditions - Node Size', () {
    test('node with zero size', () {
      final node = createTestNode(id: 'zero-size', size: Size.zero);
      controller.addNode(node);

      expect(node.size.value, equals(Size.zero));
    });

    test('node with very small size', () {
      final node = createTestNode(id: 'tiny', size: const Size(0.001, 0.001));
      controller.addNode(node);

      expect(node.size.value.width, closeTo(0.001, 0.0001));
      expect(node.size.value.height, closeTo(0.001, 0.0001));
    });

    test('node with very large size', () {
      final node = createTestNode(id: 'huge', size: const Size(10000, 10000));
      controller.addNode(node);

      expect(node.size.value.width, equals(10000));
      expect(node.size.value.height, equals(10000));
    });

    test('node with asymmetric size', () {
      final node = createTestNode(id: 'asymmetric', size: const Size(1, 10000));
      controller.addNode(node);

      expect(node.size.value.width, equals(1));
      expect(node.size.value.height, equals(10000));
    });
  });

  group('Boundary Conditions - Zoom', () {
    test('zoom at exactly minZoom', () {
      controller.zoomTo(0.5); // Default minZoom is 0.5

      expect(controller.currentZoom, equals(0.5));
    });

    test('zoom at exactly maxZoom', () {
      controller.zoomTo(2.0); // Default maxZoom

      expect(controller.currentZoom, equals(2.0));
    });

    test('zoom below minZoom clamps', () {
      controller.zoomTo(0.1);

      expect(controller.currentZoom, greaterThanOrEqualTo(0.5));
    });

    test('zoom above maxZoom clamps', () {
      controller.zoomTo(100.0);

      expect(controller.currentZoom, lessThanOrEqualTo(2.0));
    });

    test('zoom at exactly 1.0 (default)', () {
      controller.zoomTo(1.0);

      expect(controller.currentZoom, equals(1.0));
    });

    test('zoom with very small increment', () {
      controller.zoomTo(1.0);
      controller.zoomBy(0.0001);

      expect(controller.currentZoom, closeTo(1.0001, 0.0001));
    });

    test('negative zoom is handled', () {
      controller.zoomTo(-1.0);

      expect(controller.currentZoom, greaterThan(0));
    });

    test('zero zoom is handled', () {
      controller.zoomTo(0.0);

      expect(controller.currentZoom, greaterThan(0));
    });
  });

  group('Boundary Conditions - Pan', () {
    test('pan to very large positive coordinates', () {
      controller.panBy(ScreenOffset.fromXY(1000000, 1000000));

      expect(controller.currentPan.dx, equals(1000000));
      expect(controller.currentPan.dy, equals(1000000));
    });

    test('pan to very large negative coordinates', () {
      controller.panBy(ScreenOffset.fromXY(-1000000, -1000000));

      expect(controller.currentPan.dx, equals(-1000000));
      expect(controller.currentPan.dy, equals(-1000000));
    });

    test('pan with zero offset', () {
      final initialPan = controller.currentPan;
      controller.panBy(ScreenOffset.fromXY(0, 0));

      expect(controller.currentPan, equals(initialPan));
    });

    test('pan with fractional offset', () {
      controller.panBy(ScreenOffset.fromXY(0.5, 0.5));

      expect(controller.currentPan.dx, closeTo(0.5, 0.001));
      expect(controller.currentPan.dy, closeTo(0.5, 0.001));
    });
  });

  group('Boundary Conditions - Empty Graph', () {
    test('graph operations on empty graph', () {
      expect(controller.nodeCount, equals(0));
      expect(controller.connectionCount, equals(0));
      expect(controller.nodes, isEmpty);
      expect(controller.connections, isEmpty);
    });

    test('fitToView on empty graph', () {
      expect(() => controller.fitToView(), returnsNormally);
    });

    test('centerViewport on empty graph', () {
      expect(() => controller.centerViewport(), returnsNormally);
    });

    test('resetViewport on empty graph', () {
      expect(() => controller.resetViewport(), returnsNormally);
    });

    test('detectCycles on empty graph', () {
      final cycles = controller.detectCycles();
      expect(cycles, isEmpty);
    });

    test('getOrphanNodes on empty graph', () {
      final orphans = controller.getOrphanNodes();
      expect(orphans, isEmpty);
    });

    test('clearGraph on empty graph', () {
      expect(() => controller.clearGraph(), returnsNormally);
    });

    test('selectAllNodes on empty graph', () {
      controller.selectAllNodes();
      expect(controller.selectedNodeIds, isEmpty);
    });
  });

  group('Boundary Conditions - Single Element', () {
    test('single node graph operations', () {
      final node = createTestNode(id: 'only');
      controller.addNode(node);

      expect(controller.nodeCount, equals(1));
      expect(controller.connectionCount, equals(0));
    });

    test('fitToView with single node', () {
      final node = createTestNode(id: 'only', position: const Offset(100, 100));
      controller.addNode(node);

      expect(() => controller.fitToView(), returnsNormally);
    });

    test('detectCycles with single isolated node', () {
      final node = createTestNode(id: 'only');
      controller.addNode(node);

      final cycles = controller.detectCycles();
      expect(cycles, isEmpty);
    });

    test('getOrphanNodes with single node', () {
      final node = createTestNode(id: 'only');
      controller.addNode(node);

      final orphans = controller.getOrphanNodes();
      expect(orphans, hasLength(1));
    });

    test('remove only node', () {
      final node = createTestNode(id: 'only');
      controller.addNode(node);

      controller.removeNode('only');

      expect(controller.nodeCount, equals(0));
    });
  });

  group('Boundary Conditions - Connection', () {
    test('connection between nodes at same position', () {
      final node1 = createTestNode(
        id: 'node1',
        position: const Offset(100, 100),
        outputPorts: [createTestPort(id: 'out1', type: PortType.output)],
      );
      final node2 = createTestNode(
        id: 'node2',
        position: const Offset(100, 100), // Same position
        inputPorts: [createTestPort(id: 'in1', type: PortType.input)],
      );
      controller.addNode(node1);
      controller.addNode(node2);

      controller.createConnection('node1', 'out1', 'node2', 'in1');

      expect(controller.connectionCount, equals(1));
    });

    test('connection between very distant nodes', () {
      final node1 = createTestNode(
        id: 'node1',
        position: const Offset(-100000, -100000),
        outputPorts: [createTestPort(id: 'out1', type: PortType.output)],
      );
      final node2 = createTestNode(
        id: 'node2',
        position: const Offset(100000, 100000),
        inputPorts: [createTestPort(id: 'in1', type: PortType.input)],
      );
      controller.addNode(node1);
      controller.addNode(node2);

      controller.createConnection('node1', 'out1', 'node2', 'in1');

      expect(controller.connectionCount, equals(1));
    });
  });

  group('Boundary Conditions - ID Edge Cases', () {
    test('node with empty string ID', () {
      final node = createTestNode(id: '');
      controller.addNode(node);

      expect(controller.getNode(''), isNotNull);
    });

    test('node with whitespace ID', () {
      final node = createTestNode(id: '   ');
      controller.addNode(node);

      expect(controller.getNode('   '), isNotNull);
    });

    test('node with special characters in ID', () {
      final node = createTestNode(id: 'node-with_special.chars!@#\$%');
      controller.addNode(node);

      expect(controller.getNode('node-with_special.chars!@#\$%'), isNotNull);
    });

    test('node with unicode ID', () {
      final node = createTestNode(id: '节点_🔥_узел');
      controller.addNode(node);

      expect(controller.getNode('节点_🔥_узел'), isNotNull);
    });

    test('node with very long ID', () {
      final longId = 'a' * 10000;
      final node = createTestNode(id: longId);
      controller.addNode(node);

      expect(controller.getNode(longId), isNotNull);
    });
  });

  group('Boundary Conditions - Z-Index', () {
    test('node with z-index 0', () {
      final node = createTestNode(id: 'node1', zIndex: 0);
      controller.addNode(node);

      expect(node.zIndex.value, equals(0));
    });

    test('node with negative z-index', () {
      final node = createTestNode(id: 'node1', zIndex: -100);
      controller.addNode(node);

      expect(node.zIndex.value, equals(-100));
    });

    test('node with very large z-index', () {
      final node = createTestNode(id: 'node1', zIndex: 999999);
      controller.addNode(node);

      expect(node.zIndex.value, equals(999999));
    });

    test('bringToFront on single node', () {
      final node = createTestNode(id: 'only', zIndex: 0);
      controller.addNode(node);

      controller.bringNodeToFront('only');

      // Should still work, z-index may or may not change
      expect(node.zIndex.value, greaterThanOrEqualTo(0));
    });

    test('sendToBack on single node', () {
      final node = createTestNode(id: 'only', zIndex: 100);
      controller.addNode(node);

      controller.sendNodeToBack('only');

      // Should still work
      expect(node.zIndex.value, isNotNull);
    });
  });

  group('Boundary Conditions - Coordinate System', () {
    test('graph to screen at zoom 1.0', () {
      controller.zoomTo(1.0);
      controller.setViewport(GraphViewport(x: 0, y: 0, zoom: 1.0));

      final graphPos = GraphPosition.fromXY(100, 100);
      final screenPos = controller.graphToScreen(graphPos);

      expect(screenPos.dx, equals(100.0));
      expect(screenPos.dy, equals(100.0));
    });

    test('screen to graph at zoom 1.0', () {
      controller.zoomTo(1.0);
      controller.setViewport(GraphViewport(x: 0, y: 0, zoom: 1.0));

      final screenPos = ScreenPosition.fromXY(100, 100);
      final graphPos = controller.screenToGraph(screenPos);

      expect(graphPos.dx, equals(100.0));
      expect(graphPos.dy, equals(100.0));
    });

    test('transform at very high zoom', () {
      controller.setViewport(GraphViewport(x: 0, y: 0, zoom: 2.0));

      final graphPos = GraphPosition.fromXY(100, 100);
      final screenPos = controller.graphToScreen(graphPos);

      expect(screenPos.dx, equals(200.0));
      expect(screenPos.dy, equals(200.0));
    });

    test('transform at very low zoom', () {
      controller.setViewport(GraphViewport(x: 0, y: 0, zoom: 0.5));

      final graphPos = GraphPosition.fromXY(100, 100);
      final screenPos = controller.graphToScreen(graphPos);

      expect(screenPos.dx, equals(50.0));
      expect(screenPos.dy, equals(50.0));
    });

    test('transform with pan offset', () {
      controller.setViewport(GraphViewport(x: 50, y: 50, zoom: 1.0));

      final graphPos = GraphPosition.fromXY(100, 100);
      final screenPos = controller.graphToScreen(graphPos);

      expect(screenPos.dx, equals(150.0));
      expect(screenPos.dy, equals(150.0));
    });
  });

  group('Boundary Conditions - Selection', () {
    test('select non-existent node ID', () {
      controller.selectNode('non-existent');

      // Should add the ID even though node doesn't exist
      expect(controller.selectedNodeIds, contains('non-existent'));
    });

    test('select same node twice', () {
      final node = createTestNode(id: 'node1');
      controller.addNode(node);

      controller.selectNode('node1');
      controller.selectNode('node1');

      // Should only be selected once
      expect(
        controller.selectedNodeIds.where((id) => id == 'node1'),
        hasLength(1),
      );
    });

    test('deselect non-selected node', () {
      final node = createTestNode(id: 'node1');
      controller.addNode(node);

      // Toggle on non-selected should select
      controller.selectNode('node1', toggle: true);
      expect(controller.selectedNodeIds, contains('node1'));

      // Toggle again should deselect
      controller.selectNode('node1', toggle: true);
      expect(controller.selectedNodeIds, isNot(contains('node1')));
    });
  });

  group('Boundary Conditions - Viewport Extent', () {
    test('viewport extent with very large screen', () {
      controller.setScreenSize(const Size(10000, 10000));

      final extent = controller.viewportExtent;
      expect(extent.width, greaterThan(0));
      expect(extent.height, greaterThan(0));
    });

    test('viewport extent with very small screen', () {
      controller.setScreenSize(const Size(1, 1));

      final extent = controller.viewportExtent;
      expect(extent.width, greaterThan(0));
      expect(extent.height, greaterThan(0));
    });

    test('viewport center at origin', () {
      controller.setViewport(GraphViewport(x: 0, y: 0, zoom: 1.0));

      final center = controller.getViewportCenter();
      expect(center.dx, greaterThan(0)); // Center of screen
      expect(center.dy, greaterThan(0));
    });
  });
}
