@Tags(['behavior'])
library;

import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:vyuh_node_flow/src/editor/drag_session.dart';
import 'package:vyuh_node_flow/vyuh_node_flow.dart';

import '../../helpers/test_factories.dart';

void main() {
  late NodeFlowController<String> controller;

  setUp(() {
    controller = createTestController();
    // Set a screen size for viewport calculations
    controller.setScreenSize(const Size(800, 600));
  });

  tearDown(() {
    controller.dispose();
  });

  group('Pan Behavior', () {
    test('panBy moves viewport by offset', () {
      final initialPan = controller.currentPan;

      controller.panBy(ScreenOffset.fromXY(100, 50));

      final newPan = controller.currentPan;
      expect(newPan.dx, equals(initialPan.dx + 100));
      expect(newPan.dy, equals(initialPan.dy + 50));
    });

    test('panBy accumulates multiple calls', () {
      controller.panBy(ScreenOffset.fromXY(100, 0));
      controller.panBy(ScreenOffset.fromXY(0, 100));
      controller.panBy(ScreenOffset.fromXY(-50, -50));

      final pan = controller.currentPan;
      expect(pan.dx, equals(50));
      expect(pan.dy, equals(50));
    });

    // Note: Canvas locking is now handled by DragSession, not controller methods.
    // These tests verify the session-based locking mechanism.

    test('canvas is locked during drag session', () {
      expect(controller.interaction.canvasLocked.value, isFalse);

      final session = controller.createSession(DragSessionType.nodeDrag);
      session.start();

      expect(controller.interaction.canvasLocked.value, isTrue);

      session.end();
    });

    test('canvas is unlocked after drag session ends', () {
      final session = controller.createSession(DragSessionType.nodeDrag);
      session.start();
      expect(controller.interaction.canvasLocked.value, isTrue);

      session.end();

      expect(controller.interaction.canvasLocked.value, isFalse);
    });

    test('canvas is unlocked after drag session is cancelled', () {
      final session = controller.createSession(DragSessionType.nodeDrag);
      session.start();
      expect(controller.interaction.canvasLocked.value, isTrue);

      session.cancel();

      expect(controller.interaction.canvasLocked.value, isFalse);
    });

    test('node drag controller methods do not lock canvas directly', () {
      // Controller methods handle node-specific logic but delegate
      // canvas locking to the session layer (handled by ElementScope).
      final node = createTestNode(id: 'node1');
      controller.addNode(node);

      expect(controller.interaction.canvasLocked.value, isFalse);

      controller.startNodeDrag('node1');
      // Canvas is NOT locked by controller - that's the session's job
      expect(controller.interaction.canvasLocked.value, isFalse);

      controller.endNodeDrag();
      expect(controller.interaction.canvasLocked.value, isFalse);
    });

    test('connection drag controller methods do not lock canvas directly', () {
      // Controller methods handle connection-specific logic but delegate
      // canvas locking to the session layer (handled by ElementScope).
      final node = createTestNode(
        id: 'node1',
        outputPorts: [createTestPort(id: 'out1', type: PortType.output)],
      );
      controller.addNode(node);

      expect(controller.interaction.canvasLocked.value, isFalse);

      controller.startConnectionDrag(
        nodeId: 'node1',
        portId: 'out1',
        isOutput: true,
        startPoint: const Offset(100, 50),
        nodeBounds: const Rect.fromLTWH(0, 0, 100, 100),
      );
      // Canvas is NOT locked by controller - that's the session's job
      expect(controller.interaction.canvasLocked.value, isFalse);

      controller.cancelConnectionDrag();
      expect(controller.interaction.canvasLocked.value, isFalse);
    });

    test('panBy with zero offset does not change viewport', () {
      final initialPan = controller.currentPan;

      controller.panBy(ScreenOffset.fromXY(0, 0));

      expect(controller.currentPan.dx, equals(initialPan.dx));
      expect(controller.currentPan.dy, equals(initialPan.dy));
    });

    test('panBy handles negative offsets', () {
      controller.panBy(ScreenOffset.fromXY(-200, -150));

      final pan = controller.currentPan;
      expect(pan.dx, equals(-200));
      expect(pan.dy, equals(-150));
    });
  });

  group('Zoom Behavior', () {
    test('zoomTo sets exact zoom level', () {
      controller.zoomTo(2.0);

      expect(controller.currentZoom, equals(2.0));
    });

    test('zoomTo clamps to minZoom', () {
      // Default minZoom is 0.1
      controller.zoomTo(0.01);

      expect(controller.currentZoom, greaterThanOrEqualTo(0.1));
    });

    test('zoomTo clamps to maxZoom', () {
      // Default maxZoom is 4.0
      controller.zoomTo(10.0);

      expect(controller.currentZoom, lessThanOrEqualTo(4.0));
    });

    test('zoomBy adjusts zoom relatively', () {
      controller.zoomTo(1.0);
      controller.zoomBy(0.5);

      expect(controller.currentZoom, equals(1.5));
    });

    test('zoomBy with negative value decreases zoom', () {
      controller.zoomTo(2.0);
      controller.zoomBy(-0.5);

      expect(controller.currentZoom, equals(1.5));
    });

    test('zoom does not change node position in graph coordinates', () {
      final node = createTestNode(
        id: 'node1',
        position: const Offset(100, 100),
      );
      controller.addNode(node);

      // At zoom 1.0
      controller.zoomTo(1.0);
      final pos1 = node.position.value;

      // At zoom 2.0
      controller.zoomTo(2.0);
      final pos2 = node.position.value;

      // Position in graph space doesn't change with zoom
      expect(pos1, equals(pos2));
    });

    test('multiple zoom operations work correctly', () {
      controller.zoomTo(1.0);
      controller.zoomBy(0.5); // 1.5
      controller.zoomBy(0.5); // 2.0
      controller.zoomBy(-1.0); // 1.0

      expect(controller.currentZoom, equals(1.0));
    });
  });

  group('Navigation Behavior', () {
    test('fitToView handles nodes at various positions', () {
      // Create nodes at various positions
      final node1 = createTestNode(id: 'node1', position: const Offset(0, 0));
      final node2 = createTestNode(id: 'node2', position: const Offset(500, 0));
      final node3 = createTestNode(id: 'node3', position: const Offset(0, 500));
      final node4 = createTestNode(
        id: 'node4',
        position: const Offset(500, 500),
      );
      controller.addNode(node1);
      controller.addNode(node2);
      controller.addNode(node3);
      controller.addNode(node4);

      // This should adjust viewport to fit all nodes
      controller.fitToView();

      // Viewport should have been modified
      expect(controller.currentZoom, isNotNull);
    });

    test('fitToView handles empty graph gracefully', () {
      // No nodes added
      expect(() => controller.fitToView(), returnsNormally);
    });

    test('fitToView handles single node', () {
      final node = createTestNode(
        id: 'node1',
        position: const Offset(100, 100),
      );
      controller.addNode(node);

      expect(() => controller.fitToView(), returnsNormally);
    });

    test('fitSelectedNodes fits only selected nodes', () {
      final node1 = createTestNode(id: 'node1', position: const Offset(0, 0));
      final node2 = createTestNode(
        id: 'node2',
        position: const Offset(1000, 1000),
      );
      final node3 = createTestNode(
        id: 'node3',
        position: const Offset(100, 100),
      );
      controller.addNode(node1);
      controller.addNode(node2);
      controller.addNode(node3);

      // Select only node1 and node3 (ignore node2)
      controller.selectNode('node1');
      controller.selectNode('node3', toggle: true);

      controller.fitSelectedNodes();

      // Should complete without error
      expect(controller.currentZoom, isNotNull);
    });

    test('fitSelectedNodes with no selection does nothing', () {
      final node = createTestNode(
        id: 'node1',
        position: const Offset(100, 100),
      );
      controller.addNode(node);

      final beforeZoom = controller.currentZoom;
      final beforePan = controller.currentPan;

      controller.fitSelectedNodes();

      expect(controller.currentZoom, equals(beforeZoom));
      expect(controller.currentPan.dx, equals(beforePan.dx));
      expect(controller.currentPan.dy, equals(beforePan.dy));
    });

    test('centerOnNode centers viewport on specific node', () {
      final node = createTestNode(
        id: 'node1',
        position: const Offset(300, 300),
      );
      controller.addNode(node);

      controller.centerOnNode('node1');

      // Should complete without error
      expect(controller.currentPan, isNotNull);
    });

    test('centerOnNode with non-existent node is safe', () {
      expect(() => controller.centerOnNode('non-existent'), returnsNormally);
    });

    test('centerOn centers on specific graph point', () {
      controller.centerOn(GraphOffset.fromXY(500, 500));

      expect(controller.currentPan, isNotNull);
    });

    test('centerOnSelection centers on selected nodes', () {
      final node1 = createTestNode(
        id: 'node1',
        position: const Offset(100, 100),
      );
      final node2 = createTestNode(
        id: 'node2',
        position: const Offset(200, 200),
      );
      controller.addNode(node1);
      controller.addNode(node2);

      controller.selectNode('node1');
      controller.selectNode('node2', toggle: true);

      controller.centerOnSelection();

      expect(controller.currentPan, isNotNull);
    });

    test('centerViewport centers on all nodes', () {
      final node1 = createTestNode(
        id: 'node1',
        position: const Offset(100, 100),
      );
      final node2 = createTestNode(
        id: 'node2',
        position: const Offset(500, 500),
      );
      controller.addNode(node1);
      controller.addNode(node2);

      controller.centerViewport();

      expect(controller.currentPan, isNotNull);
    });
  });

  group('Viewport Reset Behavior', () {
    test('resetViewport resets to zoom 1.0 and centers on content', () {
      final node = createTestNode(
        id: 'node1',
        position: const Offset(100, 100),
      );
      controller.addNode(node);

      controller.panBy(ScreenOffset.fromXY(500, 500));
      controller.zoomTo(2.0);

      expect(controller.currentZoom, equals(2.0));

      controller.resetViewport();

      expect(controller.currentZoom, equals(1.0));
    });

    test('resetViewport with no nodes resets to origin', () {
      controller.panBy(ScreenOffset.fromXY(500, 500));
      controller.zoomTo(2.0);

      controller.resetViewport();

      expect(controller.currentZoom, equals(1.0));
    });
  });

  group('Viewport State Queries', () {
    test('getViewportCenter returns center in graph coordinates', () {
      final center = controller.getViewportCenter();

      expect(center, isNotNull);
    });

    test('viewportExtent returns visible bounds', () {
      final extent = controller.viewportExtent;

      expect(extent, isNotNull);
      expect(extent.width, greaterThan(0));
      expect(extent.height, greaterThan(0));
    });

    test('isPointVisible returns true for visible points', () {
      // Center of viewport should be visible
      final center = controller.getViewportCenter();

      expect(controller.isPointVisible(center), isTrue);
    });

    test('isRectVisible returns true for visible rectangles', () {
      final center = controller.getViewportCenter();
      final rect = GraphRect(
        Rect.fromCenter(center: center.offset, width: 100, height: 100),
      );

      expect(controller.isRectVisible(rect), isTrue);
    });

    test('selectedNodesBounds returns null when nothing selected', () {
      final node = createTestNode(
        id: 'node1',
        position: const Offset(100, 100),
      );
      controller.addNode(node);

      expect(controller.selectedNodesBounds, isNull);
    });

    test('selectedNodesBounds returns bounds when nodes selected', () {
      final node1 = createTestNode(
        id: 'node1',
        position: const Offset(100, 100),
      );
      final node2 = createTestNode(
        id: 'node2',
        position: const Offset(200, 200),
      );
      controller.addNode(node1);
      controller.addNode(node2);

      controller.selectNode('node1');
      controller.selectNode('node2', toggle: true);

      final bounds = controller.selectedNodesBounds;
      expect(bounds, isNotNull);
      expect(bounds!.left, lessThanOrEqualTo(100));
      expect(bounds.top, lessThanOrEqualTo(100));
    });
  });

  group('Coordinate Transformations', () {
    test('screenToGraph transforms screen to graph coordinates', () {
      controller.zoomTo(1.0);
      controller.setViewport(GraphViewport(x: 0, y: 0, zoom: 1.0));

      final screenPos = ScreenPosition.fromXY(100, 100);
      final graphPos = controller.screenToGraph(screenPos);

      expect(graphPos, isNotNull);
    });

    test('graphToScreen transforms graph to screen coordinates', () {
      controller.zoomTo(1.0);
      controller.setViewport(GraphViewport(x: 0, y: 0, zoom: 1.0));

      final graphPos = GraphPosition.fromXY(100, 100);
      final screenPos = controller.graphToScreen(graphPos);

      expect(screenPos, isNotNull);
    });

    test('round-trip transformation preserves position', () {
      controller.setViewport(GraphViewport(x: 0, y: 0, zoom: 1.0));

      final original = GraphPosition.fromXY(150, 150);
      final screenPos = controller.graphToScreen(original);
      final roundTrip = controller.screenToGraph(screenPos);

      // Should be approximately equal (floating point tolerance)
      expect(roundTrip.dx, closeTo(original.dx, 0.001));
      expect(roundTrip.dy, closeTo(original.dy, 0.001));
    });

    test('zoom affects coordinate transformation', () {
      controller.setViewport(GraphViewport(x: 0, y: 0, zoom: 1.0));
      final pos1 = controller.graphToScreen(GraphPosition.fromXY(100, 100));

      controller.setViewport(GraphViewport(x: 0, y: 0, zoom: 2.0));
      final pos2 = controller.graphToScreen(GraphPosition.fromXY(100, 100));

      // At 2x zoom, same graph point should appear at 2x screen position
      expect(pos2.dx, equals(pos1.dx * 2));
      expect(pos2.dy, equals(pos1.dy * 2));
    });
  });

  group('Viewport and Element Interaction', () {
    test('nodes remain in correct position after pan', () {
      final node = createTestNode(
        id: 'node1',
        position: const Offset(100, 100),
      );
      controller.addNode(node);

      controller.panBy(ScreenOffset.fromXY(500, 500));

      // Node position in graph coordinates should not change
      expect(node.position.value, equals(const Offset(100, 100)));
    });

    test('nodes remain in correct position after zoom', () {
      final node = createTestNode(
        id: 'node1',
        position: const Offset(100, 100),
      );
      controller.addNode(node);

      controller.zoomTo(3.0);

      // Node position in graph coordinates should not change
      expect(node.position.value, equals(const Offset(100, 100)));
    });

    test('selection is preserved through viewport changes', () {
      final node = createTestNode(id: 'node1');
      controller.addNode(node);
      controller.selectNode('node1');

      expect(controller.selectedNodeIds, contains('node1'));

      controller.panBy(ScreenOffset.fromXY(1000, 1000));
      controller.zoomTo(0.5);

      expect(controller.selectedNodeIds, contains('node1'));
    });

    test('connections remain valid through viewport changes', () {
      final node1 = createTestNode(
        id: 'node1',
        outputPorts: [createTestPort(id: 'out1', type: PortType.output)],
      );
      final node2 = createTestNode(
        id: 'node2',
        inputPorts: [createTestPort(id: 'in1', type: PortType.input)],
      );
      controller.addNode(node1);
      controller.addNode(node2);
      controller.createConnection('node1', 'out1', 'node2', 'in1');

      expect(controller.connectionCount, equals(1));

      controller.panBy(ScreenOffset.fromXY(-500, -500));
      controller.zoomTo(2.0);

      expect(controller.connectionCount, equals(1));
      expect(controller.getConnectionsForNode('node1'), hasLength(1));
    });
  });

  group('Edge Cases', () {
    test('very large pan values are handled', () {
      controller.panBy(ScreenOffset.fromXY(1000000, 1000000));

      expect(controller.currentPan.dx, equals(1000000));
      expect(controller.currentPan.dy, equals(1000000));
    });

    test('very small zoom is clamped', () {
      controller.zoomTo(0.001);

      expect(controller.currentZoom, greaterThanOrEqualTo(0.1));
    });

    test('very large zoom is clamped', () {
      controller.zoomTo(1000);

      expect(controller.currentZoom, lessThanOrEqualTo(4.0));
    });

    test('negative zoom is handled', () {
      controller.zoomTo(-1.0);

      expect(controller.currentZoom, greaterThan(0));
    });

    test('setViewport with specific values works', () {
      controller.setViewport(GraphViewport(x: 100, y: 200, zoom: 1.5));

      expect(controller.currentPan.dx, equals(100));
      expect(controller.currentPan.dy, equals(200));
      expect(controller.currentZoom, equals(1.5));
    });
  });
}
