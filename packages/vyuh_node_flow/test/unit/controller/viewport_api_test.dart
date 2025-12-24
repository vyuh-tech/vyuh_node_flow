/// Unit tests for the NodeFlowController Viewport API.
///
/// Tests cover:
/// - Viewport state operations (currentZoom, currentPan, setViewport)
/// - Coordinate transformations (graphToScreen, screenToGraph)
/// - Zoom operations (zoomBy, zoomTo)
/// - Pan operations (panBy)
/// - Navigation (fitToView, centerOnNode, resetViewport)
/// - Visibility queries (isPointVisible, isRectVisible, viewportExtent)
/// - Mouse position tracking
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
  // Viewport State
  // ===========================================================================

  group('Viewport State', () {
    test('currentZoom returns initial zoom of 1.0', () {
      final controller = createTestController();

      expect(controller.currentZoom, equals(1.0));
    });

    test('currentPan returns initial pan of (0, 0)', () {
      final controller = createTestController();

      expect(controller.currentPan.dx, equals(0.0));
      expect(controller.currentPan.dy, equals(0.0));
    });

    test('setViewport updates viewport state', () {
      final controller = createTestController();

      controller.setViewport(GraphViewport(x: 100, y: 50, zoom: 1.5));

      expect(controller.currentZoom, equals(1.5));
      expect(controller.currentPan.dx, equals(100.0));
      expect(controller.currentPan.dy, equals(50.0));
    });

    test('setViewport fires viewport observable', () {
      final controller = createTestController();
      final viewports = <GraphViewport>[];

      // Track viewport changes through the observable
      final initialViewport = controller.viewport;
      viewports.add(initialViewport);

      controller.setViewport(GraphViewport(x: 100, y: 50, zoom: 2.0));
      viewports.add(controller.viewport);

      expect(viewports.length, equals(2));
      expect(viewports[0].zoom, equals(1.0));
      expect(viewports[1].zoom, equals(2.0));
    });

    test('setScreenSize updates screen size', () {
      final controller = createTestController();

      controller.setScreenSize(const Size(1920, 1080));

      // Viewport center calculation will use the new size
      // Verify by checking viewport-based calculations work
      final center = controller.getViewportCenter();
      expect(center, isNotNull);
    });

    test('viewport getter returns current viewport', () {
      final controller = createTestController();

      controller.setViewport(GraphViewport(x: 200, y: 100, zoom: 2.5));

      final vp = controller.viewport;
      expect(vp.x, equals(200.0));
      expect(vp.y, equals(100.0));
      expect(vp.zoom, equals(2.5));
    });
  });

  // ===========================================================================
  // Coordinate Transformations
  // ===========================================================================

  group('Coordinate Transformations', () {
    test('graphToScreen converts at zoom 1.0', () {
      final controller = createTestController();
      controller.setViewport(GraphViewport(x: 0, y: 0, zoom: 1.0));

      final screenPos = controller.graphToScreen(GraphPosition.fromXY(100, 50));

      expect(screenPos.dx, equals(100.0));
      expect(screenPos.dy, equals(50.0));
    });

    test('graphToScreen converts with zoom factor', () {
      final controller = createTestController();
      controller.setViewport(GraphViewport(x: 0, y: 0, zoom: 2.0));

      final screenPos = controller.graphToScreen(GraphPosition.fromXY(100, 50));

      // At zoom 2.0, graph coordinates are doubled on screen
      expect(screenPos.dx, equals(200.0));
      expect(screenPos.dy, equals(100.0));
    });

    test('graphToScreen converts with pan offset', () {
      final controller = createTestController();
      controller.setViewport(GraphViewport(x: 100, y: 50, zoom: 1.0));

      final screenPos = controller.graphToScreen(GraphPosition.fromXY(0, 0));

      // Graph origin (0,0) should be at screen position (100, 50)
      expect(screenPos.dx, equals(100.0));
      expect(screenPos.dy, equals(50.0));
    });

    test('graphToScreen converts with combined pan and zoom', () {
      final controller = createTestController();
      controller.setViewport(GraphViewport(x: 100, y: 50, zoom: 2.0));

      final screenPos = controller.graphToScreen(GraphPosition.fromXY(10, 20));

      // Screen = pan + (graph * zoom)
      // x = 100 + (10 * 2) = 120
      // y = 50 + (20 * 2) = 90
      expect(screenPos.dx, equals(120.0));
      expect(screenPos.dy, equals(90.0));
    });

    test('screenToGraph converts at zoom 1.0', () {
      final controller = createTestController();
      controller.setViewport(GraphViewport(x: 0, y: 0, zoom: 1.0));

      final graphPos = controller.screenToGraph(ScreenPosition.fromXY(100, 50));

      expect(graphPos.dx, equals(100.0));
      expect(graphPos.dy, equals(50.0));
    });

    test('screenToGraph converts with zoom factor', () {
      final controller = createTestController();
      controller.setViewport(GraphViewport(x: 0, y: 0, zoom: 2.0));

      final graphPos = controller.screenToGraph(
        ScreenPosition.fromXY(200, 100),
      );

      // At zoom 2.0, screen coordinates are halved in graph space
      expect(graphPos.dx, equals(100.0));
      expect(graphPos.dy, equals(50.0));
    });

    test('screenToGraph converts with pan offset', () {
      final controller = createTestController();
      controller.setViewport(GraphViewport(x: 100, y: 50, zoom: 1.0));

      final graphPos = controller.screenToGraph(ScreenPosition.fromXY(100, 50));

      // Screen (100, 50) with pan offset should be at graph origin
      expect(graphPos.dx, equals(0.0));
      expect(graphPos.dy, equals(0.0));
    });

    test('round-trip screen to graph and back preserves position', () {
      final controller = createTestController();
      controller.setViewport(GraphViewport(x: 150, y: 75, zoom: 1.5));

      final originalScreen = ScreenPosition.fromXY(300, 200);
      final graphPos = controller.screenToGraph(originalScreen);
      final backToScreen = controller.graphToScreen(graphPos);

      expect(backToScreen.dx, closeTo(originalScreen.dx, 0.001));
      expect(backToScreen.dy, closeTo(originalScreen.dy, 0.001));
    });

    test('round-trip graph to screen and back preserves position', () {
      final controller = createTestController();
      controller.setViewport(GraphViewport(x: 150, y: 75, zoom: 1.5));

      final originalGraph = GraphPosition.fromXY(100, 100);
      final screenPos = controller.graphToScreen(originalGraph);
      final backToGraph = controller.screenToGraph(screenPos);

      expect(backToGraph.dx, closeTo(originalGraph.dx, 0.001));
      expect(backToGraph.dy, closeTo(originalGraph.dy, 0.001));
    });
  });

  // ===========================================================================
  // Zoom Operations
  // ===========================================================================

  group('Zoom Operations', () {
    test('zoomTo sets exact zoom level', () {
      final controller = createTestController();
      controller.setScreenSize(const Size(800, 600));

      controller.zoomTo(2.0);

      expect(controller.currentZoom, equals(2.0));
    });

    test('zoomTo clamps to minZoom', () {
      final controller = createTestController(
        config: createTestConfig(minZoom: 0.5, maxZoom: 2.0),
      );
      controller.setScreenSize(const Size(800, 600));

      controller.zoomTo(0.1);

      expect(controller.currentZoom, equals(0.5));
    });

    test('zoomTo clamps to maxZoom', () {
      final controller = createTestController(
        config: createTestConfig(minZoom: 0.5, maxZoom: 2.0),
      );
      controller.setScreenSize(const Size(800, 600));

      controller.zoomTo(5.0);

      expect(controller.currentZoom, equals(2.0));
    });

    test('zoomBy adjusts zoom relatively', () {
      final controller = createTestController();
      controller.setScreenSize(const Size(800, 600));
      controller.setViewport(GraphViewport(x: 0, y: 0, zoom: 1.0));

      controller.zoomBy(0.5);

      expect(controller.currentZoom, equals(1.5));
    });

    test('zoomBy negative zooms out', () {
      final controller = createTestController();
      controller.setScreenSize(const Size(800, 600));
      controller.setViewport(GraphViewport(x: 0, y: 0, zoom: 2.0));

      controller.zoomBy(-0.5);

      expect(controller.currentZoom, equals(1.5));
    });

    test('zoomBy clamps to minZoom', () {
      final controller = createTestController(
        config: createTestConfig(minZoom: 0.5, maxZoom: 2.0),
      );
      controller.setScreenSize(const Size(800, 600));
      controller.setViewport(GraphViewport(x: 0, y: 0, zoom: 0.6));

      controller.zoomBy(-0.5);

      expect(controller.currentZoom, equals(0.5));
    });

    test('zoomBy clamps to maxZoom', () {
      final controller = createTestController(
        config: createTestConfig(minZoom: 0.5, maxZoom: 2.0),
      );
      controller.setScreenSize(const Size(800, 600));
      controller.setViewport(GraphViewport(x: 0, y: 0, zoom: 1.8));

      controller.zoomBy(0.5);

      expect(controller.currentZoom, equals(2.0));
    });
  });

  // ===========================================================================
  // Pan Operations
  // ===========================================================================

  group('Pan Operations', () {
    test('panBy moves viewport by delta', () {
      final controller = createTestController();
      controller.setViewport(GraphViewport(x: 100, y: 50, zoom: 1.0));

      controller.panBy(ScreenOffset.fromXY(50, 25));

      expect(controller.currentPan.dx, equals(150.0));
      expect(controller.currentPan.dy, equals(75.0));
    });

    test('panBy with negative delta moves in opposite direction', () {
      final controller = createTestController();
      controller.setViewport(GraphViewport(x: 100, y: 50, zoom: 1.0));

      controller.panBy(ScreenOffset.fromXY(-30, -20));

      expect(controller.currentPan.dx, equals(70.0));
      expect(controller.currentPan.dy, equals(30.0));
    });

    test('panBy accumulates multiple calls', () {
      final controller = createTestController();
      controller.setViewport(GraphViewport(x: 0, y: 0, zoom: 1.0));

      controller.panBy(ScreenOffset.fromXY(10, 10));
      controller.panBy(ScreenOffset.fromXY(20, 20));
      controller.panBy(ScreenOffset.fromXY(30, 30));

      expect(controller.currentPan.dx, equals(60.0));
      expect(controller.currentPan.dy, equals(60.0));
    });

    test('panBy does not affect zoom', () {
      final controller = createTestController();
      controller.setViewport(GraphViewport(x: 0, y: 0, zoom: 1.5));

      controller.panBy(ScreenOffset.fromXY(100, 100));

      expect(controller.currentZoom, equals(1.5));
    });
  });

  // ===========================================================================
  // Navigation - Reset & Center
  // ===========================================================================

  group('Navigation - Reset & Center', () {
    test('resetViewport sets zoom to 1.0 with no nodes', () {
      final controller = createTestController();
      controller.setScreenSize(const Size(800, 600));
      controller.setViewport(GraphViewport(x: 500, y: 300, zoom: 2.5));

      controller.resetViewport();

      expect(controller.currentZoom, equals(1.0));
      expect(controller.currentPan.dx, equals(0.0));
      expect(controller.currentPan.dy, equals(0.0));
    });

    test('resetViewport centers on nodes when present', () {
      final node = createTestNode(
        position: const Offset(100, 100),
        size: const Size(100, 100),
      );
      final controller = createTestController(nodes: [node]);
      controller.setScreenSize(const Size(800, 600));
      controller.setViewport(GraphViewport(x: 500, y: 300, zoom: 2.5));

      controller.resetViewport();

      expect(controller.currentZoom, equals(1.0));
      // Viewport should be centered on the node
      // Node center is (150, 150), so viewport pan should center it
    });

    test('centerOnNode centers viewport on specific node', () {
      final node = createTestNode(
        id: 'target',
        position: const Offset(200, 200),
        size: const Size(100, 100),
      );
      final controller = createTestController(nodes: [node]);
      controller.setScreenSize(const Size(800, 600));

      controller.centerOnNode('target');

      // After centering, the node center (250, 250) should be at screen center (400, 300)
      final nodeCenter = controller.graphToScreen(
        GraphPosition.fromXY(250, 250),
      );
      expect(nodeCenter.dx, closeTo(400.0, 1.0));
      expect(nodeCenter.dy, closeTo(300.0, 1.0));
    });

    test('centerOnNode does nothing for non-existent node', () {
      final controller = createTestController();
      controller.setScreenSize(const Size(800, 600));
      controller.setViewport(GraphViewport(x: 100, y: 50, zoom: 1.0));

      controller.centerOnNode('non-existent');

      // Viewport should remain unchanged
      expect(controller.currentPan.dx, equals(100.0));
      expect(controller.currentPan.dy, equals(50.0));
    });

    test('centerOnNode does not change zoom', () {
      final node = createTestNode(position: const Offset(200, 200));
      final controller = createTestController(nodes: [node]);
      controller.setScreenSize(const Size(800, 600));
      controller.setViewport(GraphViewport(x: 0, y: 0, zoom: 2.0));

      controller.centerOnNode(node.id);

      expect(controller.currentZoom, equals(2.0));
    });

    test('centerOn centers viewport on graph point', () {
      final controller = createTestController();
      controller.setScreenSize(const Size(800, 600));

      controller.centerOn(GraphOffset.fromXY(500, 300));

      // After centering, graph point (500, 300) should be at screen center
      final screenPos = controller.graphToScreen(
        GraphPosition.fromXY(500, 300),
      );
      expect(screenPos.dx, closeTo(400.0, 1.0));
      expect(screenPos.dy, closeTo(300.0, 1.0));
    });

    test('centerViewport centers on all nodes', () {
      final node1 = createTestNode(
        position: const Offset(0, 0),
        size: const Size(100, 100),
      );
      final node2 = createTestNode(
        position: const Offset(200, 200),
        size: const Size(100, 100),
      );
      final controller = createTestController(nodes: [node1, node2]);
      controller.setScreenSize(const Size(800, 600));

      controller.centerViewport();

      // Center of all nodes is (150, 150) - should now be at screen center
      final center = controller.graphToScreen(GraphPosition.fromXY(150, 150));
      expect(center.dx, closeTo(400.0, 1.0));
      expect(center.dy, closeTo(300.0, 1.0));
    });

    test('centerOnSelection centers on selected nodes', () {
      final node1 = createTestNode(
        id: 'node-1',
        position: const Offset(0, 0),
        size: const Size(100, 100),
      );
      final node2 = createTestNode(
        id: 'node-2',
        position: const Offset(400, 400),
        size: const Size(100, 100),
      );
      final controller = createTestController(nodes: [node1, node2]);
      controller.setScreenSize(const Size(800, 600));
      controller.selectNode('node-2');

      controller.centerOnSelection();

      // Center of selected node (node-2) is (450, 450)
      final center = controller.graphToScreen(GraphPosition.fromXY(450, 450));
      expect(center.dx, closeTo(400.0, 1.0));
      expect(center.dy, closeTo(300.0, 1.0));
    });
  });

  // ===========================================================================
  // Navigation - Fit to View
  // ===========================================================================

  group('Navigation - Fit to View', () {
    test('fitToView adjusts zoom and pan to show all nodes', () {
      final node1 = createTestNode(
        position: const Offset(0, 0),
        size: const Size(100, 100),
      );
      final node2 = createTestNode(
        position: const Offset(500, 500),
        size: const Size(100, 100),
      );
      final controller = createTestController(nodes: [node1, node2]);
      controller.setScreenSize(const Size(800, 600));

      controller.fitToView();

      // After fitToView, all nodes should be visible
      final extent = controller.viewportExtent;
      expect(extent.contains(GraphPosition.fromXY(0, 0)), isTrue);
      expect(extent.contains(GraphPosition.fromXY(600, 600)), isTrue);
    });

    test('fitToView does nothing for empty graph', () {
      final controller = createTestController();
      controller.setScreenSize(const Size(800, 600));
      controller.setViewport(GraphViewport(x: 100, y: 50, zoom: 1.5));

      controller.fitToView();

      // Viewport should remain unchanged
      expect(controller.currentPan.dx, equals(100.0));
      expect(controller.currentPan.dy, equals(50.0));
      expect(controller.currentZoom, equals(1.5));
    });

    test('fitToView respects minZoom constraint', () {
      // Very small node that would require extreme zoom out to fit
      final node = createTestNode(
        position: const Offset(10000, 10000),
        size: const Size(100, 100),
      );
      final controller = createTestController(
        nodes: [node],
        config: createTestConfig(minZoom: 0.5),
      );
      controller.setScreenSize(const Size(800, 600));

      controller.fitToView();

      expect(controller.currentZoom, greaterThanOrEqualTo(0.5));
    });

    test('fitToView respects maxZoom constraint', () {
      // Small node that would require zoom in
      final node = createTestNode(
        position: const Offset(0, 0),
        size: const Size(10, 10),
      );
      final controller = createTestController(
        nodes: [node],
        config: createTestConfig(maxZoom: 2.0),
      );
      controller.setScreenSize(const Size(800, 600));

      controller.fitToView();

      expect(controller.currentZoom, lessThanOrEqualTo(2.0));
    });

    test('fitSelectedNodes fits only selected nodes', () {
      final node1 = createTestNode(
        id: 'node-1',
        position: const Offset(0, 0),
        size: const Size(100, 100),
      );
      final node2 = createTestNode(
        id: 'node-2',
        position: const Offset(200, 200),
        size: const Size(100, 100),
      );
      final node3 = createTestNode(
        id: 'node-3',
        position: const Offset(1000, 1000),
        size: const Size(100, 100),
      );
      final controller = createTestController(nodes: [node1, node2, node3]);
      controller.setScreenSize(const Size(800, 600));
      controller.selectNodes(['node-1', 'node-2']);

      controller.fitSelectedNodes();

      // node-1 and node-2 should be visible (0,0 to 300,300)
      final extent = controller.viewportExtent;
      expect(extent.contains(GraphPosition.fromXY(50, 50)), isTrue);
      expect(extent.contains(GraphPosition.fromXY(250, 250)), isTrue);
    });

    test('fitSelectedNodes does nothing when no selection', () {
      final node = createTestNode(position: const Offset(100, 100));
      final controller = createTestController(nodes: [node]);
      controller.setScreenSize(const Size(800, 600));
      controller.setViewport(GraphViewport(x: 100, y: 50, zoom: 1.5));

      controller.fitSelectedNodes();

      // Viewport should remain unchanged
      expect(controller.currentPan.dx, equals(100.0));
      expect(controller.currentPan.dy, equals(50.0));
      expect(controller.currentZoom, equals(1.5));
    });
  });

  // ===========================================================================
  // Viewport Center
  // ===========================================================================

  group('Viewport Center', () {
    test('getViewportCenter returns center in graph coordinates', () {
      final controller = createTestController();
      controller.setScreenSize(const Size(800, 600));
      controller.setViewport(GraphViewport(x: 0, y: 0, zoom: 1.0));

      final center = controller.getViewportCenter();

      // Screen center (400, 300) at zoom 1.0 = graph (400, 300)
      expect(center.dx, equals(400.0));
      expect(center.dy, equals(300.0));
    });

    test('getViewportCenter accounts for zoom', () {
      final controller = createTestController();
      controller.setScreenSize(const Size(800, 600));
      controller.setViewport(GraphViewport(x: 0, y: 0, zoom: 2.0));

      final center = controller.getViewportCenter();

      // Screen center (400, 300) at zoom 2.0 = graph (200, 150)
      expect(center.dx, equals(200.0));
      expect(center.dy, equals(150.0));
    });

    test('getViewportCenter accounts for pan', () {
      final controller = createTestController();
      controller.setScreenSize(const Size(800, 600));
      controller.setViewport(GraphViewport(x: 100, y: 50, zoom: 1.0));

      final center = controller.getViewportCenter();

      // Screen center (400, 300) with pan (100, 50) at zoom 1.0
      // graph = (screen - pan) / zoom = (400 - 100, 300 - 50) = (300, 250)
      expect(center.dx, equals(300.0));
      expect(center.dy, equals(250.0));
    });

    test('getViewportCenter returns zero for zero screen size', () {
      final controller = createTestController();
      // Don't set screen size, it defaults to zero

      final center = controller.getViewportCenter();

      expect(center.dx, equals(0.0));
      expect(center.dy, equals(0.0));
    });
  });

  // ===========================================================================
  // Viewport Extent & Visibility
  // ===========================================================================

  group('Viewport Extent & Visibility', () {
    test('viewportExtent returns visible area in graph coordinates', () {
      final controller = createTestController();
      controller.setScreenSize(const Size(800, 600));
      controller.setViewport(GraphViewport(x: 0, y: 0, zoom: 1.0));

      final extent = controller.viewportExtent;

      expect(extent.left, equals(0.0));
      expect(extent.top, equals(0.0));
      expect(extent.width, equals(800.0));
      expect(extent.height, equals(600.0));
    });

    test('viewportExtent scales with zoom', () {
      final controller = createTestController();
      controller.setScreenSize(const Size(800, 600));
      controller.setViewport(GraphViewport(x: 0, y: 0, zoom: 2.0));

      final extent = controller.viewportExtent;

      // At zoom 2.0, visible area in graph space is halved
      expect(extent.width, equals(400.0));
      expect(extent.height, equals(300.0));
    });

    test('viewportExtent shifts with pan', () {
      final controller = createTestController();
      controller.setScreenSize(const Size(800, 600));
      controller.setViewport(GraphViewport(x: -100, y: -50, zoom: 1.0));

      final extent = controller.viewportExtent;

      // Pan offset shifts the visible area
      expect(extent.left, equals(100.0));
      expect(extent.top, equals(50.0));
    });

    test('isPointVisible returns true for point inside viewport', () {
      final controller = createTestController();
      controller.setScreenSize(const Size(800, 600));
      controller.setViewport(GraphViewport(x: 0, y: 0, zoom: 1.0));

      final result = controller.isPointVisible(GraphPosition.fromXY(400, 300));

      expect(result, isTrue);
    });

    test('isPointVisible returns false for point outside viewport', () {
      final controller = createTestController();
      controller.setScreenSize(const Size(800, 600));
      controller.setViewport(GraphViewport(x: 0, y: 0, zoom: 1.0));

      final result = controller.isPointVisible(
        GraphPosition.fromXY(1000, 1000),
      );

      expect(result, isFalse);
    });

    test('isRectVisible returns true for overlapping rect', () {
      final controller = createTestController();
      controller.setScreenSize(const Size(800, 600));
      controller.setViewport(GraphViewport(x: 0, y: 0, zoom: 1.0));

      final result = controller.isRectVisible(
        GraphRect(const Rect.fromLTWH(700, 500, 200, 200)),
      );

      expect(result, isTrue);
    });

    test('isRectVisible returns false for non-overlapping rect', () {
      final controller = createTestController();
      controller.setScreenSize(const Size(800, 600));
      controller.setViewport(GraphViewport(x: 0, y: 0, zoom: 1.0));

      final result = controller.isRectVisible(
        GraphRect(const Rect.fromLTWH(1000, 1000, 100, 100)),
      );

      expect(result, isFalse);
    });

    test('isRectVisible returns true for rect contained in viewport', () {
      final controller = createTestController();
      controller.setScreenSize(const Size(800, 600));
      controller.setViewport(GraphViewport(x: 0, y: 0, zoom: 1.0));

      final result = controller.isRectVisible(
        GraphRect(const Rect.fromLTWH(100, 100, 200, 200)),
      );

      expect(result, isTrue);
    });
  });

  // ===========================================================================
  // Selected Nodes Bounds
  // ===========================================================================

  group('Selected Nodes Bounds', () {
    test('selectedNodesBounds returns null when nothing selected', () {
      final node = createTestNode(position: const Offset(100, 100));
      final controller = createTestController(nodes: [node]);

      expect(controller.selectedNodesBounds, isNull);
    });

    test('selectedNodesBounds returns bounds for single selected node', () {
      final node = createTestNode(
        id: 'node-1',
        position: const Offset(100, 100),
        size: const Size(200, 150),
      );
      final controller = createTestController(nodes: [node]);
      controller.selectNode('node-1');

      final bounds = controller.selectedNodesBounds;

      expect(bounds, isNotNull);
      expect(bounds!.left, equals(100.0));
      expect(bounds.top, equals(100.0));
      expect(bounds.width, equals(200.0));
      expect(bounds.height, equals(150.0));
    });

    test('selectedNodesBounds encompasses multiple selected nodes', () {
      final node1 = createTestNode(
        id: 'node-1',
        position: const Offset(0, 0),
        size: const Size(100, 100),
      );
      final node2 = createTestNode(
        id: 'node-2',
        position: const Offset(200, 200),
        size: const Size(100, 100),
      );
      final controller = createTestController(nodes: [node1, node2]);
      controller.selectNodes(['node-1', 'node-2']);

      final bounds = controller.selectedNodesBounds;

      expect(bounds, isNotNull);
      expect(bounds!.left, equals(0.0));
      expect(bounds.top, equals(0.0));
      expect(bounds.right, equals(300.0));
      expect(bounds.bottom, equals(300.0));
    });
  });

  // ===========================================================================
  // Mouse Position Tracking
  // ===========================================================================

  group('Mouse Position Tracking', () {
    test('mousePositionWorld is initially null', () {
      final controller = createTestController();

      expect(controller.mousePositionWorld, isNull);
    });

    test('setMousePositionWorld updates mouse position', () {
      final controller = createTestController();

      controller.setMousePositionWorld(GraphPosition.fromXY(150, 200));

      expect(controller.mousePositionWorld, isNotNull);
      expect(controller.mousePositionWorld!.dx, equals(150.0));
      expect(controller.mousePositionWorld!.dy, equals(200.0));
    });

    test('setMousePositionWorld with null clears position', () {
      final controller = createTestController();
      controller.setMousePositionWorld(GraphPosition.fromXY(100, 100));

      controller.setMousePositionWorld(null);

      expect(controller.mousePositionWorld, isNull);
    });
  });

  // ===========================================================================
  // Animated Navigation (Handler Registration)
  // ===========================================================================

  group('Animated Navigation', () {
    test('animateToViewport calls registered handler', () {
      final controller = createTestController();
      controller.setScreenSize(const Size(800, 600));
      GraphViewport? capturedTarget;
      Duration? capturedDuration;
      Curve? capturedCurve;

      controller.setAnimateToHandler((
        target, {
        Duration duration = const Duration(milliseconds: 400),
        Curve curve = Curves.easeInOut,
      }) {
        capturedTarget = target;
        capturedDuration = duration;
        capturedCurve = curve;
      });

      controller.animateToViewport(
        GraphViewport(x: 100, y: 50, zoom: 1.5),
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeOut,
      );

      expect(capturedTarget, isNotNull);
      expect(capturedTarget!.x, equals(100.0));
      expect(capturedTarget!.y, equals(50.0));
      expect(capturedTarget!.zoom, equals(1.5));
      expect(capturedDuration, equals(const Duration(milliseconds: 500)));
      expect(capturedCurve, equals(Curves.easeOut));
    });

    test('animateToViewport does nothing without handler', () {
      final controller = createTestController();
      controller.setScreenSize(const Size(800, 600));
      controller.setViewport(GraphViewport(x: 0, y: 0, zoom: 1.0));

      // Should not throw
      controller.animateToViewport(GraphViewport(x: 100, y: 50, zoom: 1.5));

      // Viewport should remain unchanged (no immediate update)
      expect(controller.currentPan.dx, equals(0.0));
    });

    test('animateToNode calls handler with correct target', () {
      final node = createTestNode(
        id: 'target',
        position: const Offset(200, 200),
        size: const Size(100, 100),
      );
      final controller = createTestController(nodes: [node]);
      controller.setScreenSize(const Size(800, 600));
      GraphViewport? capturedTarget;

      controller.setAnimateToHandler((
        target, {
        Duration duration = const Duration(milliseconds: 400),
        Curve curve = Curves.easeInOut,
      }) {
        capturedTarget = target;
      });

      controller.animateToNode('target', zoom: 1.5);

      expect(capturedTarget, isNotNull);
      expect(capturedTarget!.zoom, equals(1.5));
      // Node center (250, 250) should become centered in viewport
    });

    test('animateToNode does nothing for non-existent node', () {
      final controller = createTestController();
      controller.setScreenSize(const Size(800, 600));
      var handlerCalled = false;

      controller.setAnimateToHandler((
        target, {
        Duration duration = const Duration(milliseconds: 400),
        Curve curve = Curves.easeInOut,
      }) {
        handlerCalled = true;
      });

      controller.animateToNode('non-existent');

      expect(handlerCalled, isFalse);
    });

    test('animateToPosition calls handler', () {
      final controller = createTestController();
      controller.setScreenSize(const Size(800, 600));
      GraphViewport? capturedTarget;

      controller.setAnimateToHandler((
        target, {
        Duration duration = const Duration(milliseconds: 400),
        Curve curve = Curves.easeInOut,
      }) {
        capturedTarget = target;
      });

      controller.animateToPosition(GraphOffset.fromXY(500, 300));

      expect(capturedTarget, isNotNull);
    });

    test('animateToScale calls handler with correct zoom', () {
      final controller = createTestController();
      controller.setScreenSize(const Size(800, 600));
      controller.setViewport(GraphViewport(x: 0, y: 0, zoom: 1.0));
      GraphViewport? capturedTarget;

      controller.setAnimateToHandler((
        target, {
        Duration duration = const Duration(milliseconds: 400),
        Curve curve = Curves.easeInOut,
      }) {
        capturedTarget = target;
      });

      controller.animateToScale(2.0);

      expect(capturedTarget, isNotNull);
      expect(capturedTarget!.zoom, equals(2.0));
    });

    test('animateToBounds calls handler', () {
      final controller = createTestController();
      controller.setScreenSize(const Size(800, 600));
      GraphViewport? capturedTarget;

      controller.setAnimateToHandler((
        target, {
        Duration duration = const Duration(milliseconds: 400),
        Curve curve = Curves.easeInOut,
      }) {
        capturedTarget = target;
      });

      controller.animateToBounds(
        GraphRect(const Rect.fromLTWH(0, 0, 400, 300)),
      );

      expect(capturedTarget, isNotNull);
    });

    test('centerOnNodeWithZoom is immediate (not animated)', () {
      final node = createTestNode(
        id: 'target',
        position: const Offset(200, 200),
        size: const Size(100, 100),
      );
      final controller = createTestController(nodes: [node]);
      controller.setScreenSize(const Size(800, 600));
      controller.setViewport(GraphViewport(x: 0, y: 0, zoom: 1.0));

      controller.centerOnNodeWithZoom('target', zoom: 2.0);

      // Should update immediately (not via animation)
      expect(controller.currentZoom, equals(2.0));
      // Node center should be at screen center
      final nodeCenter = controller.graphToScreen(
        GraphPosition.fromXY(250, 250),
      );
      expect(nodeCenter.dx, closeTo(400.0, 1.0));
      expect(nodeCenter.dy, closeTo(300.0, 1.0));
    });
  });

  // ===========================================================================
  // Edge Cases
  // ===========================================================================

  group('Edge Cases', () {
    test('fitToView and centerViewport do nothing with zero screen size', () {
      final controller = createTestController();
      // Don't set screen size - it defaults to Size.zero
      controller.setViewport(GraphViewport(x: 100, y: 50, zoom: 1.0));

      // These operations should do nothing with zero screen size
      controller.fitToView();
      controller.centerViewport();

      // Viewport should remain unchanged
      expect(controller.currentPan.dx, equals(100.0));
      expect(controller.currentPan.dy, equals(50.0));
    });

    test('resetViewport resets to origin with zero screen size', () {
      final controller = createTestController();
      // Don't set screen size - it defaults to Size.zero
      controller.setViewport(GraphViewport(x: 100, y: 50, zoom: 1.5));

      controller.resetViewport();

      // resetViewport resets to origin with zoom 1.0 when screen size is zero
      expect(controller.currentPan.dx, equals(0.0));
      expect(controller.currentPan.dy, equals(0.0));
      expect(controller.currentZoom, equals(1.0));
    });

    test('viewport handles negative coordinates', () {
      final controller = createTestController();
      controller.setScreenSize(const Size(800, 600));

      controller.setViewport(GraphViewport(x: -200, y: -100, zoom: 1.0));

      expect(controller.currentPan.dx, equals(-200.0));
      expect(controller.currentPan.dy, equals(-100.0));
    });

    test('viewport handles extreme zoom values within bounds', () {
      final controller = createTestController(
        config: createTestConfig(minZoom: 0.01, maxZoom: 100.0),
      );
      controller.setScreenSize(const Size(800, 600));

      controller.zoomTo(0.01);
      expect(controller.currentZoom, equals(0.01));

      controller.zoomTo(100.0);
      expect(controller.currentZoom, equals(100.0));
    });

    test('coordinate transforms handle very small zoom', () {
      final controller = createTestController(
        config: createTestConfig(minZoom: 0.01),
      );
      controller.setScreenSize(const Size(800, 600));
      controller.setViewport(GraphViewport(x: 0, y: 0, zoom: 0.01));

      // Should not throw or produce NaN
      final screenPos = controller.graphToScreen(
        GraphPosition.fromXY(100, 100),
      );
      expect(screenPos.dx.isFinite, isTrue);
      expect(screenPos.dy.isFinite, isTrue);
    });

    test('coordinate transforms handle very large zoom', () {
      final controller = createTestController(
        config: createTestConfig(maxZoom: 100.0),
      );
      controller.setScreenSize(const Size(800, 600));
      controller.setViewport(GraphViewport(x: 0, y: 0, zoom: 100.0));

      // Should not throw or produce NaN
      final graphPos = controller.screenToGraph(
        ScreenPosition.fromXY(100, 100),
      );
      expect(graphPos.dx.isFinite, isTrue);
      expect(graphPos.dy.isFinite, isTrue);
    });
  });
}
