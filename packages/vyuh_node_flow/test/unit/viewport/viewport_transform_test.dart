/// Comprehensive unit tests for viewport and coordinate transformation.
///
/// Tests cover:
/// - GraphViewport construction and properties
/// - Zoom and pan value handling
/// - Coordinate conversions (screen to graph, graph to screen)
/// - Viewport bounds calculations
/// - Viewport constraints and clamping
/// - Type-safe coordinate system (GraphPosition, ScreenPosition, etc.)
@Tags(['unit'])
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vyuh_node_flow/vyuh_node_flow.dart';

import '../../helpers/test_factories.dart';
import '../../helpers/test_utils.dart';

void main() {
  setUp(() {
    resetTestCounters();
  });

  // ===========================================================================
  // GraphViewport Construction
  // ===========================================================================

  group('GraphViewport Construction', () {
    test('default constructor creates identity viewport', () {
      const viewport = GraphViewport();

      expect(viewport.x, equals(0.0));
      expect(viewport.y, equals(0.0));
      expect(viewport.zoom, equals(1.0));
    });

    test('constructs with custom x pan', () {
      const viewport = GraphViewport(x: 150.0);

      expect(viewport.x, equals(150.0));
      expect(viewport.y, equals(0.0));
      expect(viewport.zoom, equals(1.0));
    });

    test('constructs with custom y pan', () {
      const viewport = GraphViewport(y: 250.0);

      expect(viewport.x, equals(0.0));
      expect(viewport.y, equals(250.0));
      expect(viewport.zoom, equals(1.0));
    });

    test('constructs with custom zoom', () {
      const viewport = GraphViewport(zoom: 2.5);

      expect(viewport.x, equals(0.0));
      expect(viewport.y, equals(0.0));
      expect(viewport.zoom, equals(2.5));
    });

    test('constructs with all custom values', () {
      const viewport = GraphViewport(x: 100.0, y: 200.0, zoom: 1.75);

      expect(viewport.x, equals(100.0));
      expect(viewport.y, equals(200.0));
      expect(viewport.zoom, equals(1.75));
    });

    test('constructs with negative pan values', () {
      const viewport = GraphViewport(x: -500.0, y: -300.0);

      expect(viewport.x, equals(-500.0));
      expect(viewport.y, equals(-300.0));
    });

    test('constructs with fractional zoom values', () {
      const viewport = GraphViewport(zoom: 0.333);

      expect(viewport.zoom, closeTo(0.333, 0.001));
    });

    test('factory createTestViewport creates viewport correctly', () {
      final viewport = createTestViewport(x: 50.0, y: 75.0, zoom: 1.25);

      expect(viewport.x, equals(50.0));
      expect(viewport.y, equals(75.0));
      expect(viewport.zoom, equals(1.25));
    });
  });

  // ===========================================================================
  // Zoom Value Handling
  // ===========================================================================

  group('Zoom Value Handling', () {
    test('zoom of 1.0 represents 100% (no scaling)', () {
      const viewport = GraphViewport(zoom: 1.0);
      final graphPos = GraphPosition.fromXY(100, 100);

      final screenPos = viewport.toScreen(graphPos);

      expect(screenPos.dx, equals(100.0));
      expect(screenPos.dy, equals(100.0));
    });

    test('zoom greater than 1.0 zooms in (enlarges)', () {
      const viewport = GraphViewport(zoom: 2.0);
      final graphPos = GraphPosition.fromXY(50, 50);

      final screenPos = viewport.toScreen(graphPos);

      // At 2x zoom, graph coordinates are doubled on screen
      expect(screenPos.dx, equals(100.0));
      expect(screenPos.dy, equals(100.0));
    });

    test('zoom less than 1.0 zooms out (shrinks)', () {
      const viewport = GraphViewport(zoom: 0.5);
      final graphPos = GraphPosition.fromXY(200, 200);

      final screenPos = viewport.toScreen(graphPos);

      // At 0.5x zoom, graph coordinates are halved on screen
      expect(screenPos.dx, equals(100.0));
      expect(screenPos.dy, equals(100.0));
    });

    test('very small zoom value works correctly', () {
      const viewport = GraphViewport(zoom: 0.1);
      final graphPos = GraphPosition.fromXY(1000, 1000);

      final screenPos = viewport.toScreen(graphPos);

      expect(screenPos.dx, closeTo(100.0, 0.01));
      expect(screenPos.dy, closeTo(100.0, 0.01));
    });

    test('very large zoom value works correctly', () {
      const viewport = GraphViewport(zoom: 10.0);
      final graphPos = GraphPosition.fromXY(10, 10);

      final screenPos = viewport.toScreen(graphPos);

      expect(screenPos.dx, equals(100.0));
      expect(screenPos.dy, equals(100.0));
    });

    test('zoom affects visible area inversely', () {
      const viewportNormal = GraphViewport(zoom: 1.0);
      const viewportZoomedIn = GraphViewport(zoom: 2.0);
      const viewportZoomedOut = GraphViewport(zoom: 0.5);
      const screenSize = Size(800, 600);

      final areaNormal = viewportNormal.getVisibleArea(screenSize);
      final areaZoomedIn = viewportZoomedIn.getVisibleArea(screenSize);
      final areaZoomedOut = viewportZoomedOut.getVisibleArea(screenSize);

      // Zoomed in shows smaller area
      expect(areaZoomedIn.width, lessThan(areaNormal.width));
      expect(areaZoomedIn.height, lessThan(areaNormal.height));

      // Zoomed out shows larger area
      expect(areaZoomedOut.width, greaterThan(areaNormal.width));
      expect(areaZoomedOut.height, greaterThan(areaNormal.height));
    });
  });

  // ===========================================================================
  // Pan Value Handling
  // ===========================================================================

  group('Pan Value Handling', () {
    test('positive x pan shifts graph right on screen', () {
      const viewport = GraphViewport(x: 100.0);
      final graphPos = GraphPosition.fromXY(0, 0);

      final screenPos = viewport.toScreen(graphPos);

      expect(screenPos.dx, equals(100.0));
      expect(screenPos.dy, equals(0.0));
    });

    test('positive y pan shifts graph down on screen', () {
      const viewport = GraphViewport(y: 100.0);
      final graphPos = GraphPosition.fromXY(0, 0);

      final screenPos = viewport.toScreen(graphPos);

      expect(screenPos.dx, equals(0.0));
      expect(screenPos.dy, equals(100.0));
    });

    test('negative x pan shifts graph left on screen', () {
      const viewport = GraphViewport(x: -100.0);
      final graphPos = GraphPosition.fromXY(0, 0);

      final screenPos = viewport.toScreen(graphPos);

      expect(screenPos.dx, equals(-100.0));
    });

    test('negative y pan shifts graph up on screen', () {
      const viewport = GraphViewport(y: -100.0);
      final graphPos = GraphPosition.fromXY(0, 0);

      final screenPos = viewport.toScreen(graphPos);

      expect(screenPos.dy, equals(-100.0));
    });

    test('pan shifts visible area in graph space', () {
      const viewport = GraphViewport(x: -200.0, y: -100.0);
      const screenSize = Size(800, 600);

      final visibleArea = viewport.getVisibleArea(screenSize);

      // Negative pan means we see positive graph coordinates
      expect(visibleArea.left, equals(200.0));
      expect(visibleArea.top, equals(100.0));
    });

    test('very large pan values work correctly', () {
      const viewport = GraphViewport(x: 100000.0, y: 100000.0);
      final graphPos = GraphPosition.fromXY(0, 0);

      final screenPos = viewport.toScreen(graphPos);

      expect(screenPos.dx, equals(100000.0));
      expect(screenPos.dy, equals(100000.0));
    });
  });

  // ===========================================================================
  // Screen to Graph Coordinate Conversion
  // ===========================================================================

  group('Screen to Graph Coordinate Conversion', () {
    test('toGraph with identity viewport', () {
      const viewport = GraphViewport();
      final screenPos = ScreenPosition.fromXY(150, 200);

      final graphPos = viewport.toGraph(screenPos);

      expect(graphPos.dx, equals(150.0));
      expect(graphPos.dy, equals(200.0));
    });

    test('toGraph with zoom only', () {
      const viewport = GraphViewport(zoom: 2.0);
      final screenPos = ScreenPosition.fromXY(200, 300);

      final graphPos = viewport.toGraph(screenPos);

      // graph = screen / zoom
      expect(graphPos.dx, equals(100.0));
      expect(graphPos.dy, equals(150.0));
    });

    test('toGraph with pan only', () {
      const viewport = GraphViewport(x: 50.0, y: 100.0);
      final screenPos = ScreenPosition.fromXY(150, 200);

      final graphPos = viewport.toGraph(screenPos);

      // graph = (screen - pan)
      expect(graphPos.dx, equals(100.0));
      expect(graphPos.dy, equals(100.0));
    });

    test('toGraph with combined pan and zoom', () {
      const viewport = GraphViewport(x: 100.0, y: 50.0, zoom: 2.0);
      final screenPos = ScreenPosition.fromXY(300, 250);

      final graphPos = viewport.toGraph(screenPos);

      // graph = (screen - pan) / zoom
      // x: (300 - 100) / 2 = 100
      // y: (250 - 50) / 2 = 100
      expect(graphPos.dx, equals(100.0));
      expect(graphPos.dy, equals(100.0));
    });

    test('toGraph at screen origin with pan', () {
      const viewport = GraphViewport(x: 200.0, y: 150.0);
      final screenPos = ScreenPosition.fromXY(0, 0);

      final graphPos = viewport.toGraph(screenPos);

      expect(graphPos.dx, equals(-200.0));
      expect(graphPos.dy, equals(-150.0));
    });

    test('toGraph with zoomed out viewport', () {
      const viewport = GraphViewport(zoom: 0.5);
      final screenPos = ScreenPosition.fromXY(100, 100);

      final graphPos = viewport.toGraph(screenPos);

      // graph = screen / zoom = 100 / 0.5 = 200
      expect(graphPos.dx, equals(200.0));
      expect(graphPos.dy, equals(200.0));
    });

    test('toGraphOffset scales delta without translation', () {
      const viewport = GraphViewport(x: 1000.0, y: 500.0, zoom: 2.0);
      final screenDelta = ScreenOffset.fromXY(100, 50);

      final graphDelta = viewport.toGraphOffset(screenDelta);

      // Only zoom affects deltas, not pan
      expect(graphDelta.dx, equals(50.0));
      expect(graphDelta.dy, equals(25.0));
    });

    test('toGraphOffset with zoom out', () {
      const viewport = GraphViewport(zoom: 0.25);
      final screenDelta = ScreenOffset.fromXY(10, 20);

      final graphDelta = viewport.toGraphOffset(screenDelta);

      expect(graphDelta.dx, equals(40.0));
      expect(graphDelta.dy, equals(80.0));
    });
  });

  // ===========================================================================
  // Graph to Screen Coordinate Conversion
  // ===========================================================================

  group('Graph to Screen Coordinate Conversion', () {
    test('toScreen with identity viewport', () {
      const viewport = GraphViewport();
      final graphPos = GraphPosition.fromXY(150, 200);

      final screenPos = viewport.toScreen(graphPos);

      expect(screenPos.dx, equals(150.0));
      expect(screenPos.dy, equals(200.0));
    });

    test('toScreen with zoom only', () {
      const viewport = GraphViewport(zoom: 2.0);
      final graphPos = GraphPosition.fromXY(100, 150);

      final screenPos = viewport.toScreen(graphPos);

      // screen = graph * zoom
      expect(screenPos.dx, equals(200.0));
      expect(screenPos.dy, equals(300.0));
    });

    test('toScreen with pan only', () {
      const viewport = GraphViewport(x: 50.0, y: 100.0);
      final graphPos = GraphPosition.fromXY(100, 100);

      final screenPos = viewport.toScreen(graphPos);

      // screen = graph + pan
      expect(screenPos.dx, equals(150.0));
      expect(screenPos.dy, equals(200.0));
    });

    test('toScreen with combined pan and zoom', () {
      const viewport = GraphViewport(x: 100.0, y: 50.0, zoom: 2.0);
      final graphPos = GraphPosition.fromXY(50, 75);

      final screenPos = viewport.toScreen(graphPos);

      // screen = (graph * zoom) + pan
      // x: (50 * 2) + 100 = 200
      // y: (75 * 2) + 50 = 200
      expect(screenPos.dx, equals(200.0));
      expect(screenPos.dy, equals(200.0));
    });

    test('toScreen at graph origin with pan', () {
      const viewport = GraphViewport(x: 200.0, y: 150.0);
      final graphPos = GraphPosition.fromXY(0, 0);

      final screenPos = viewport.toScreen(graphPos);

      expect(screenPos.dx, equals(200.0));
      expect(screenPos.dy, equals(150.0));
    });

    test('toScreen with negative graph coordinates', () {
      const viewport = GraphViewport(x: 100.0, y: 100.0, zoom: 1.0);
      final graphPos = GraphPosition.fromXY(-50, -25);

      final screenPos = viewport.toScreen(graphPos);

      expect(screenPos.dx, equals(50.0));
      expect(screenPos.dy, equals(75.0));
    });

    test('toScreenOffset scales delta without translation', () {
      const viewport = GraphViewport(x: 1000.0, y: 500.0, zoom: 2.0);
      final graphDelta = GraphOffset.fromXY(50, 25);

      final screenDelta = viewport.toScreenOffset(graphDelta);

      // Only zoom affects deltas, not pan
      expect(screenDelta.dx, equals(100.0));
      expect(screenDelta.dy, equals(50.0));
    });

    test('toScreenOffset with zoom out', () {
      const viewport = GraphViewport(zoom: 0.25);
      final graphDelta = GraphOffset.fromXY(40, 80);

      final screenDelta = viewport.toScreenOffset(graphDelta);

      expect(screenDelta.dx, equals(10.0));
      expect(screenDelta.dy, equals(20.0));
    });
  });

  // ===========================================================================
  // Round-trip Coordinate Conversions
  // ===========================================================================

  group('Round-trip Coordinate Conversions', () {
    test('screen to graph to screen preserves position at zoom 1.0', () {
      const viewport = GraphViewport(x: 100.0, y: 50.0, zoom: 1.0);
      final original = ScreenPosition.fromXY(300, 400);

      final graph = viewport.toGraph(original);
      final restored = viewport.toScreen(graph);

      expect(restored.dx, closeTo(original.dx, 0.001));
      expect(restored.dy, closeTo(original.dy, 0.001));
    });

    test('screen to graph to screen preserves position at zoom 2.0', () {
      const viewport = GraphViewport(x: 200.0, y: 100.0, zoom: 2.0);
      final original = ScreenPosition.fromXY(500, 350);

      final graph = viewport.toGraph(original);
      final restored = viewport.toScreen(graph);

      expect(restored.dx, closeTo(original.dx, 0.001));
      expect(restored.dy, closeTo(original.dy, 0.001));
    });

    test('screen to graph to screen preserves position at zoom 0.5', () {
      const viewport = GraphViewport(x: -100.0, y: -50.0, zoom: 0.5);
      final original = ScreenPosition.fromXY(250, 180);

      final graph = viewport.toGraph(original);
      final restored = viewport.toScreen(graph);

      expect(restored.dx, closeTo(original.dx, 0.001));
      expect(restored.dy, closeTo(original.dy, 0.001));
    });

    test('graph to screen to graph preserves position at zoom 1.0', () {
      const viewport = GraphViewport(x: 100.0, y: 50.0, zoom: 1.0);
      final original = GraphPosition.fromXY(200, 300);

      final screen = viewport.toScreen(original);
      final restored = viewport.toGraph(screen);

      expect(restored.dx, closeTo(original.dx, 0.001));
      expect(restored.dy, closeTo(original.dy, 0.001));
    });

    test('graph to screen to graph preserves position at zoom 2.0', () {
      const viewport = GraphViewport(x: 200.0, y: 100.0, zoom: 2.0);
      final original = GraphPosition.fromXY(150, 225);

      final screen = viewport.toScreen(original);
      final restored = viewport.toGraph(screen);

      expect(restored.dx, closeTo(original.dx, 0.001));
      expect(restored.dy, closeTo(original.dy, 0.001));
    });

    test('offset round-trip preserves delta', () {
      const viewport = GraphViewport(x: 500.0, y: 300.0, zoom: 1.5);
      final originalScreen = ScreenOffset.fromXY(60, 90);

      final graph = viewport.toGraphOffset(originalScreen);
      final restored = viewport.toScreenOffset(graph);

      expect(restored.dx, closeTo(originalScreen.dx, 0.001));
      expect(restored.dy, closeTo(originalScreen.dy, 0.001));
    });

    test('multiple conversions maintain precision', () {
      const viewport = GraphViewport(x: 123.456, y: 789.012, zoom: 1.234);
      var pos = ScreenPosition.fromXY(456.789, 321.654);

      // Perform multiple round trips
      for (var i = 0; i < 10; i++) {
        final graph = viewport.toGraph(pos);
        pos = viewport.toScreen(graph);
      }

      expect(pos.dx, closeTo(456.789, 0.01));
      expect(pos.dy, closeTo(321.654, 0.01));
    });
  });

  // ===========================================================================
  // Rectangle Transformations
  // ===========================================================================

  group('Rectangle Transformations', () {
    test('toScreenRect transforms rectangle with identity viewport', () {
      const viewport = GraphViewport();
      final graphRect = GraphRect.fromLTWH(10, 20, 100, 50);

      final screenRect = viewport.toScreenRect(graphRect);

      expect(screenRect.left, equals(10.0));
      expect(screenRect.top, equals(20.0));
      expect(screenRect.width, equals(100.0));
      expect(screenRect.height, equals(50.0));
    });

    test('toScreenRect transforms rectangle with zoom', () {
      const viewport = GraphViewport(zoom: 2.0);
      final graphRect = GraphRect.fromLTWH(0, 0, 100, 50);

      final screenRect = viewport.toScreenRect(graphRect);

      expect(screenRect.width, equals(200.0));
      expect(screenRect.height, equals(100.0));
    });

    test('toScreenRect transforms rectangle with pan', () {
      const viewport = GraphViewport(x: 100.0, y: 50.0);
      final graphRect = GraphRect.fromLTWH(0, 0, 50, 50);

      final screenRect = viewport.toScreenRect(graphRect);

      expect(screenRect.left, equals(100.0));
      expect(screenRect.top, equals(50.0));
    });

    test('toScreenRect transforms rectangle with combined pan and zoom', () {
      const viewport = GraphViewport(x: 100.0, y: 50.0, zoom: 2.0);
      final graphRect = GraphRect.fromLTWH(10, 20, 50, 30);

      final screenRect = viewport.toScreenRect(graphRect);

      // Left = 10 * 2 + 100 = 120
      // Top = 20 * 2 + 50 = 90
      // Width = 50 * 2 = 100
      // Height = 30 * 2 = 60
      expect(screenRect.left, equals(120.0));
      expect(screenRect.top, equals(90.0));
      expect(screenRect.width, equals(100.0));
      expect(screenRect.height, equals(60.0));
    });

    test('toGraphRect transforms rectangle with identity viewport', () {
      const viewport = GraphViewport();
      final screenRect = ScreenRect.fromLTWH(10, 20, 100, 50);

      final graphRect = viewport.toGraphRect(screenRect);

      expect(graphRect.left, equals(10.0));
      expect(graphRect.top, equals(20.0));
      expect(graphRect.width, equals(100.0));
      expect(graphRect.height, equals(50.0));
    });

    test('toGraphRect transforms rectangle with zoom', () {
      const viewport = GraphViewport(zoom: 2.0);
      final screenRect = ScreenRect.fromLTWH(0, 0, 200, 100);

      final graphRect = viewport.toGraphRect(screenRect);

      expect(graphRect.width, equals(100.0));
      expect(graphRect.height, equals(50.0));
    });

    test('toGraphRect transforms rectangle with pan', () {
      const viewport = GraphViewport(x: 100.0, y: 50.0);
      final screenRect = ScreenRect.fromLTWH(100, 50, 50, 50);

      final graphRect = viewport.toGraphRect(screenRect);

      expect(graphRect.left, equals(0.0));
      expect(graphRect.top, equals(0.0));
    });

    test('rectangle round-trip preserves dimensions', () {
      const viewport = GraphViewport(x: 50.0, y: 25.0, zoom: 1.5);
      final original = GraphRect.fromLTWH(100, 200, 150, 75);

      final screen = viewport.toScreenRect(original);
      final restored = viewport.toGraphRect(screen);

      expect(restored.left, closeTo(original.left, 0.01));
      expect(restored.top, closeTo(original.top, 0.01));
      expect(restored.width, closeTo(original.width, 0.01));
      expect(restored.height, closeTo(original.height, 0.01));
    });
  });

  // ===========================================================================
  // Viewport Bounds Calculations
  // ===========================================================================

  group('Viewport Bounds Calculations', () {
    test('getVisibleArea with identity viewport', () {
      const viewport = GraphViewport();
      const screenSize = Size(800, 600);

      final area = viewport.getVisibleArea(screenSize);

      expect(area.left, equals(0.0));
      expect(area.top, equals(0.0));
      expect(area.right, equals(800.0));
      expect(area.bottom, equals(600.0));
    });

    test('getVisibleArea scales with zoom in', () {
      const viewport = GraphViewport(zoom: 2.0);
      const screenSize = Size(800, 600);

      final area = viewport.getVisibleArea(screenSize);

      expect(area.width, equals(400.0));
      expect(area.height, equals(300.0));
    });

    test('getVisibleArea scales with zoom out', () {
      const viewport = GraphViewport(zoom: 0.5);
      const screenSize = Size(800, 600);

      final area = viewport.getVisibleArea(screenSize);

      expect(area.width, equals(1600.0));
      expect(area.height, equals(1200.0));
    });

    test('getVisibleArea shifts with positive pan', () {
      const viewport = GraphViewport(x: 100.0, y: 50.0);
      const screenSize = Size(800, 600);

      final area = viewport.getVisibleArea(screenSize);

      expect(area.left, equals(-100.0));
      expect(area.top, equals(-50.0));
    });

    test('getVisibleArea shifts with negative pan', () {
      const viewport = GraphViewport(x: -100.0, y: -50.0);
      const screenSize = Size(800, 600);

      final area = viewport.getVisibleArea(screenSize);

      expect(area.left, equals(100.0));
      expect(area.top, equals(50.0));
    });

    test('getVisibleArea with combined pan and zoom', () {
      const viewport = GraphViewport(x: 200.0, y: 100.0, zoom: 2.0);
      const screenSize = Size(800, 600);

      final area = viewport.getVisibleArea(screenSize);

      // Top-left: (0 - 200) / 2 = -100, (0 - 100) / 2 = -50
      expect(area.left, equals(-100.0));
      expect(area.top, equals(-50.0));
      expect(area.width, equals(400.0));
      expect(area.height, equals(300.0));
    });

    test('getVisibleArea with zero screen size', () {
      const viewport = GraphViewport();
      const screenSize = Size.zero;

      final area = viewport.getVisibleArea(screenSize);

      expect(area.width, equals(0.0));
      expect(area.height, equals(0.0));
    });

    test('getVisibleArea center is correct', () {
      const viewport = GraphViewport();
      const screenSize = Size(800, 600);

      final area = viewport.getVisibleArea(screenSize);

      expect(area.center.dx, equals(400.0));
      expect(area.center.dy, equals(300.0));
    });
  });

  // ===========================================================================
  // Visibility Queries
  // ===========================================================================

  group('Visibility Queries', () {
    test('isRectVisible returns true for rect inside viewport', () {
      const viewport = GraphViewport();
      const screenSize = Size(800, 600);
      final rect = GraphRect.fromLTWH(100, 100, 100, 100);

      expect(viewport.isRectVisible(rect, screenSize), isTrue);
    });

    test('isRectVisible returns false for rect outside viewport', () {
      const viewport = GraphViewport();
      const screenSize = Size(800, 600);
      final rect = GraphRect.fromLTWH(1000, 1000, 100, 100);

      expect(viewport.isRectVisible(rect, screenSize), isFalse);
    });

    test('isRectVisible returns true for rect partially overlapping', () {
      const viewport = GraphViewport();
      const screenSize = Size(800, 600);
      final rect = GraphRect.fromLTWH(750, 550, 100, 100);

      expect(viewport.isRectVisible(rect, screenSize), isTrue);
    });

    test('isRectVisible returns true for rect touching edge', () {
      const viewport = GraphViewport();
      const screenSize = Size(800, 600);
      final rect = GraphRect.fromLTWH(700, 0, 100, 100);

      expect(viewport.isRectVisible(rect, screenSize), isTrue);
    });

    test('isRectVisible returns true for rect larger than viewport', () {
      const viewport = GraphViewport();
      const screenSize = Size(800, 600);
      final rect = GraphRect.fromLTWH(-100, -100, 1000, 800);

      expect(viewport.isRectVisible(rect, screenSize), isTrue);
    });

    test('isRectVisible works with panned viewport', () {
      const viewport = GraphViewport(x: -500.0, y: -400.0);
      const screenSize = Size(800, 600);
      final rect = GraphRect.fromLTWH(600, 500, 100, 100);

      expect(viewport.isRectVisible(rect, screenSize), isTrue);
    });

    test('isRectVisible works with zoomed viewport', () {
      const viewport = GraphViewport(zoom: 0.5);
      const screenSize = Size(800, 600);
      // At zoom 0.5, visible area is 1600x1200
      final rect = GraphRect.fromLTWH(1500, 1100, 50, 50);

      expect(viewport.isRectVisible(rect, screenSize), isTrue);
    });

    test('isPointVisible returns true for point inside viewport', () {
      const viewport = GraphViewport();
      const screenSize = Size(800, 600);
      final point = GraphPosition.fromXY(400, 300);

      expect(viewport.isPointVisible(point, screenSize), isTrue);
    });

    test('isPointVisible returns false for point outside viewport', () {
      const viewport = GraphViewport();
      const screenSize = Size(800, 600);
      final point = GraphPosition.fromXY(1000, 700);

      expect(viewport.isPointVisible(point, screenSize), isFalse);
    });

    test('isPointVisible returns true for point on viewport edge', () {
      const viewport = GraphViewport();
      const screenSize = Size(800, 600);
      // Points exactly on the edge are technically inside (< check)
      final point = GraphPosition.fromXY(0, 0);

      expect(viewport.isPointVisible(point, screenSize), isTrue);
    });

    test('isPointVisible works with panned viewport', () {
      const viewport = GraphViewport(x: -200.0, y: -100.0);
      const screenSize = Size(800, 600);
      // Visible area starts at (200, 100)
      final point = GraphPosition.fromXY(400, 300);

      expect(viewport.isPointVisible(point, screenSize), isTrue);
    });
  });

  // ===========================================================================
  // copyWith
  // ===========================================================================

  group('copyWith', () {
    test('copyWith with no arguments returns equal viewport', () {
      const original = GraphViewport(x: 100, y: 200, zoom: 1.5);

      final copy = original.copyWith();

      expect(copy, equals(original));
      expect(copy.x, equals(100.0));
      expect(copy.y, equals(200.0));
      expect(copy.zoom, equals(1.5));
    });

    test('copyWith can update x only', () {
      const original = GraphViewport(x: 100, y: 200, zoom: 1.5);

      final modified = original.copyWith(x: 300);

      expect(modified.x, equals(300.0));
      expect(modified.y, equals(200.0));
      expect(modified.zoom, equals(1.5));
    });

    test('copyWith can update y only', () {
      const original = GraphViewport(x: 100, y: 200, zoom: 1.5);

      final modified = original.copyWith(y: 400);

      expect(modified.x, equals(100.0));
      expect(modified.y, equals(400.0));
      expect(modified.zoom, equals(1.5));
    });

    test('copyWith can update zoom only', () {
      const original = GraphViewport(x: 100, y: 200, zoom: 1.5);

      final modified = original.copyWith(zoom: 2.5);

      expect(modified.x, equals(100.0));
      expect(modified.y, equals(200.0));
      expect(modified.zoom, equals(2.5));
    });

    test('copyWith can update multiple values', () {
      const original = GraphViewport(x: 100, y: 200, zoom: 1.5);

      final modified = original.copyWith(x: 50, zoom: 3.0);

      expect(modified.x, equals(50.0));
      expect(modified.y, equals(200.0));
      expect(modified.zoom, equals(3.0));
    });

    test('copyWith can update all values', () {
      const original = GraphViewport(x: 100, y: 200, zoom: 1.5);

      final modified = original.copyWith(x: 0, y: 0, zoom: 1.0);

      expect(modified.x, equals(0.0));
      expect(modified.y, equals(0.0));
      expect(modified.zoom, equals(1.0));
    });
  });

  // ===========================================================================
  // Equality and HashCode
  // ===========================================================================

  group('Equality and HashCode', () {
    test('equal viewports are equal', () {
      const viewport1 = GraphViewport(x: 100, y: 200, zoom: 1.5);
      const viewport2 = GraphViewport(x: 100, y: 200, zoom: 1.5);

      expect(viewport1, equals(viewport2));
    });

    test('viewports with different x are not equal', () {
      const viewport1 = GraphViewport(x: 100, y: 200, zoom: 1.5);
      const viewport2 = GraphViewport(x: 101, y: 200, zoom: 1.5);

      expect(viewport1, isNot(equals(viewport2)));
    });

    test('viewports with different y are not equal', () {
      const viewport1 = GraphViewport(x: 100, y: 200, zoom: 1.5);
      const viewport2 = GraphViewport(x: 100, y: 201, zoom: 1.5);

      expect(viewport1, isNot(equals(viewport2)));
    });

    test('viewports with different zoom are not equal', () {
      const viewport1 = GraphViewport(x: 100, y: 200, zoom: 1.5);
      const viewport2 = GraphViewport(x: 100, y: 200, zoom: 1.6);

      expect(viewport1, isNot(equals(viewport2)));
    });

    test('equal viewports have same hashCode', () {
      const viewport1 = GraphViewport(x: 100, y: 200, zoom: 1.5);
      const viewport2 = GraphViewport(x: 100, y: 200, zoom: 1.5);

      expect(viewport1.hashCode, equals(viewport2.hashCode));
    });

    test('identical viewports are equal', () {
      const viewport = GraphViewport(x: 100, y: 200, zoom: 1.5);

      expect(viewport, equals(viewport));
    });

    test('viewport is not equal to non-viewport', () {
      const viewport = GraphViewport(x: 100, y: 200, zoom: 1.5);

      // Intentionally comparing to unrelated type to test equality operator
      // ignore: unrelated_type_equality_checks
      expect(viewport == 'not a viewport', isFalse);
    });
  });

  // ===========================================================================
  // JSON Serialization
  // ===========================================================================

  group('JSON Serialization', () {
    test('toJson produces correct JSON', () {
      const viewport = GraphViewport(x: 100, y: 200, zoom: 1.5);

      final json = viewport.toJson();

      expect(json['x'], equals(100.0));
      expect(json['y'], equals(200.0));
      expect(json['zoom'], equals(1.5));
    });

    test('fromJson reconstructs viewport', () {
      final json = {'x': 150.0, 'y': 250.0, 'zoom': 2.0};

      final viewport = GraphViewport.fromJson(json);

      expect(viewport.x, equals(150.0));
      expect(viewport.y, equals(250.0));
      expect(viewport.zoom, equals(2.0));
    });

    test('fromJson handles missing x', () {
      final json = {'y': 200.0, 'zoom': 1.5};

      final viewport = GraphViewport.fromJson(json);

      expect(viewport.x, equals(0.0));
    });

    test('fromJson handles missing y', () {
      final json = {'x': 100.0, 'zoom': 1.5};

      final viewport = GraphViewport.fromJson(json);

      expect(viewport.y, equals(0.0));
    });

    test('fromJson handles missing zoom', () {
      final json = {'x': 100.0, 'y': 200.0};

      final viewport = GraphViewport.fromJson(json);

      expect(viewport.zoom, equals(1.0));
    });

    test('fromJson handles empty JSON', () {
      final json = <String, dynamic>{};

      final viewport = GraphViewport.fromJson(json);

      expect(viewport.x, equals(0.0));
      expect(viewport.y, equals(0.0));
      expect(viewport.zoom, equals(1.0));
    });

    test('fromJson handles integer values', () {
      final json = {'x': 100, 'y': 200, 'zoom': 2};

      final viewport = GraphViewport.fromJson(json);

      expect(viewport.x, equals(100.0));
      expect(viewport.y, equals(200.0));
      expect(viewport.zoom, equals(2.0));
    });

    test('round-trip serialization preserves values', () {
      const original = GraphViewport(x: 123.456, y: 789.012, zoom: 1.234);

      final restored = roundTripViewportJson(original);

      expect(restored.x, equals(original.x));
      expect(restored.y, equals(original.y));
      expect(restored.zoom, equals(original.zoom));
    });

    test('round-trip serialization with negative values', () {
      const original = GraphViewport(x: -500.0, y: -300.0, zoom: 0.5);

      final restored = roundTripViewportJson(original);

      expect(restored.x, equals(original.x));
      expect(restored.y, equals(original.y));
      expect(restored.zoom, equals(original.zoom));
    });
  });

  // ===========================================================================
  // toString
  // ===========================================================================

  group('toString', () {
    test('toString contains class name', () {
      const viewport = GraphViewport(x: 100, y: 200, zoom: 1.5);

      expect(viewport.toString(), contains('GraphViewport'));
    });

    test('toString contains x value', () {
      const viewport = GraphViewport(x: 100, y: 200, zoom: 1.5);

      expect(viewport.toString(), contains('100'));
    });

    test('toString contains y value', () {
      const viewport = GraphViewport(x: 100, y: 200, zoom: 1.5);

      expect(viewport.toString(), contains('200'));
    });

    test('toString contains zoom value', () {
      const viewport = GraphViewport(x: 100, y: 200, zoom: 1.5);

      expect(viewport.toString(), contains('1.5'));
    });
  });

  // ===========================================================================
  // Viewport Constraints (Controller Integration)
  // ===========================================================================

  group('Viewport Constraints', () {
    test('zoom is clamped to minZoom via controller', () {
      final controller = createTestController(
        config: createTestConfig(minZoom: 0.5, maxZoom: 3.0),
      );
      controller.setScreenSize(const Size(800, 600));

      controller.zoomTo(0.1);

      expect(controller.currentZoom, equals(0.5));
    });

    test('zoom is clamped to maxZoom via controller', () {
      final controller = createTestController(
        config: createTestConfig(minZoom: 0.5, maxZoom: 3.0),
      );
      controller.setScreenSize(const Size(800, 600));

      controller.zoomTo(5.0);

      expect(controller.currentZoom, equals(3.0));
    });

    test('zoomBy respects minZoom constraint', () {
      final controller = createTestController(
        config: createTestConfig(minZoom: 0.5, maxZoom: 3.0),
      );
      controller.setScreenSize(const Size(800, 600));
      controller.setViewport(const GraphViewport(zoom: 0.6));

      controller.zoomBy(-0.5);

      expect(controller.currentZoom, equals(0.5));
    });

    test('zoomBy respects maxZoom constraint', () {
      final controller = createTestController(
        config: createTestConfig(minZoom: 0.5, maxZoom: 3.0),
      );
      controller.setScreenSize(const Size(800, 600));
      controller.setViewport(const GraphViewport(zoom: 2.8));

      controller.zoomBy(0.5);

      expect(controller.currentZoom, equals(3.0));
    });

    test('setViewport sets values directly without clamping', () {
      final controller = createTestController(
        config: createTestConfig(minZoom: 0.5, maxZoom: 3.0),
      );

      controller.setViewport(const GraphViewport(x: 100, y: 50, zoom: 0.2));

      // setViewport directly sets the viewport without clamping
      // Use zoomTo/zoomBy for clamped zoom changes
      expect(controller.currentZoom, equals(0.2));
      expect(controller.currentPan.dx, equals(100.0));
      expect(controller.currentPan.dy, equals(50.0));
    });

    test('controller uses initial viewport when provided', () {
      final controller = createTestController(
        initialViewport: const GraphViewport(x: 200, y: 150, zoom: 1.5),
      );

      expect(controller.currentPan.dx, equals(200.0));
      expect(controller.currentPan.dy, equals(150.0));
      expect(controller.currentZoom, equals(1.5));
    });
  });

  // ===========================================================================
  // Coordinate Type Safety
  // ===========================================================================

  group('Coordinate Type Safety', () {
    test('GraphPosition arithmetic works correctly', () {
      final pos1 = GraphPosition.fromXY(100, 50);
      final pos2 = GraphPosition.fromXY(25, 25);

      final sum = pos1 + pos2;
      final diff = pos1 - pos2;
      final scaled = pos1 * 2;
      final divided = pos1 / 2;
      final negated = -pos1;

      expect(sum.dx, equals(125.0));
      expect(sum.dy, equals(75.0));
      expect(diff.dx, equals(75.0));
      expect(diff.dy, equals(25.0));
      expect(scaled.dx, equals(200.0));
      expect(scaled.dy, equals(100.0));
      expect(divided.dx, equals(50.0));
      expect(divided.dy, equals(25.0));
      expect(negated.dx, equals(-100.0));
      expect(negated.dy, equals(-50.0));
    });

    test('ScreenPosition arithmetic works correctly', () {
      final pos1 = ScreenPosition.fromXY(200, 100);
      final pos2 = ScreenPosition.fromXY(50, 50);

      final sum = pos1 + pos2;
      final diff = pos1 - pos2;
      final scaled = pos1 * 0.5;
      final divided = pos1 / 2;

      expect(sum.dx, equals(250.0));
      expect(sum.dy, equals(150.0));
      expect(diff.dx, equals(150.0));
      expect(diff.dy, equals(50.0));
      expect(scaled.dx, equals(100.0));
      expect(scaled.dy, equals(50.0));
      expect(divided.dx, equals(100.0));
      expect(divided.dy, equals(50.0));
    });

    test('GraphOffset arithmetic works correctly', () {
      final offset1 = GraphOffset.fromXY(30, 20);
      final offset2 = GraphOffset.fromXY(10, 10);

      final sum = offset1 + offset2;
      final diff = offset1 - offset2;
      final scaled = offset1 * 3;

      expect(sum.dx, equals(40.0));
      expect(sum.dy, equals(30.0));
      expect(diff.dx, equals(20.0));
      expect(diff.dy, equals(10.0));
      expect(scaled.dx, equals(90.0));
      expect(scaled.dy, equals(60.0));
    });

    test('ScreenOffset arithmetic works correctly', () {
      final offset1 = ScreenOffset.fromXY(60, 40);
      final offset2 = ScreenOffset.fromXY(20, 20);

      final sum = offset1 + offset2;
      final diff = offset1 - offset2;
      final scaled = offset1 * 0.5;

      expect(sum.dx, equals(80.0));
      expect(sum.dy, equals(60.0));
      expect(diff.dx, equals(40.0));
      expect(diff.dy, equals(20.0));
      expect(scaled.dx, equals(30.0));
      expect(scaled.dy, equals(20.0));
    });

    test('GraphPosition translate with GraphOffset', () {
      final pos = GraphPosition.fromXY(100, 100);
      final offset = GraphOffset.fromXY(25, -10);

      final translated = pos.translate(offset);

      expect(translated.dx, equals(125.0));
      expect(translated.dy, equals(90.0));
    });

    test('ScreenPosition translate with ScreenOffset', () {
      final pos = ScreenPosition.fromXY(200, 150);
      final offset = ScreenOffset.fromXY(-50, 30);

      final translated = pos.translate(offset);

      expect(translated.dx, equals(150.0));
      expect(translated.dy, equals(180.0));
    });

    test('GraphPosition distance calculation', () {
      final pos1 = GraphPosition.fromXY(0, 0);
      final pos2 = GraphPosition.fromXY(3, 4);

      expect(pos1.distanceTo(pos2), equals(5.0));
    });

    test('GraphPosition distanceSquared calculation', () {
      final pos1 = GraphPosition.fromXY(0, 0);
      final pos2 = GraphPosition.fromXY(3, 4);

      expect(pos1.distanceSquaredTo(pos2), equals(25.0));
    });

    test('GraphPosition lerp interpolates correctly', () {
      final pos1 = GraphPosition.fromXY(0, 0);
      final pos2 = GraphPosition.fromXY(100, 200);

      final half = GraphPosition.lerp(pos1, pos2, 0.5);
      final quarter = GraphPosition.lerp(pos1, pos2, 0.25);

      expect(half.dx, equals(50.0));
      expect(half.dy, equals(100.0));
      expect(quarter.dx, equals(25.0));
      expect(quarter.dy, equals(50.0));
    });

    test('GraphOffset distance property', () {
      final offset = GraphOffset.fromXY(3, 4);

      expect(offset.distance, equals(5.0));
    });

    test('ScreenOffset distance property', () {
      final offset = ScreenOffset.fromXY(6, 8);

      expect(offset.distance, equals(10.0));
    });

    test('zero constants are correct', () {
      expect(GraphPosition.zero.dx, equals(0.0));
      expect(GraphPosition.zero.dy, equals(0.0));
      expect(ScreenPosition.zero.dx, equals(0.0));
      expect(ScreenPosition.zero.dy, equals(0.0));
      expect(GraphOffset.zero.dx, equals(0.0));
      expect(GraphOffset.zero.dy, equals(0.0));
      expect(ScreenOffset.zero.dx, equals(0.0));
      expect(ScreenOffset.zero.dy, equals(0.0));
    });

    test('isFinite returns true for finite coordinates', () {
      expect(GraphPosition.fromXY(100, 200).isFinite, isTrue);
      expect(ScreenPosition.fromXY(100, 200).isFinite, isTrue);
      expect(GraphOffset.fromXY(50, 75).isFinite, isTrue);
      expect(ScreenOffset.fromXY(50, 75).isFinite, isTrue);
    });

    test('toDebugString provides readable output', () {
      final graphPos = GraphPosition.fromXY(123.456, 789.012);
      final screenPos = ScreenPosition.fromXY(100.5, 200.5);
      final graphOffset = GraphOffset.fromXY(10.1, 20.2);
      final screenOffset = ScreenOffset.fromXY(30.3, 40.4);

      expect(graphPos.toDebugString(), contains('GraphPosition'));
      expect(screenPos.toDebugString(), contains('ScreenPosition'));
      expect(graphOffset.toDebugString(), contains('GraphOffset'));
      expect(screenOffset.toDebugString(), contains('ScreenOffset'));
    });
  });

  // ===========================================================================
  // GraphRect Operations
  // ===========================================================================

  group('GraphRect Operations', () {
    test('GraphRect contains point inside', () {
      final rect = GraphRect.fromLTWH(100, 100, 200, 150);
      final insidePoint = GraphPosition.fromXY(200, 175);

      expect(rect.contains(insidePoint), isTrue);
    });

    test('GraphRect does not contain point outside', () {
      final rect = GraphRect.fromLTWH(100, 100, 200, 150);
      final outsidePoint = GraphPosition.fromXY(50, 50);

      expect(rect.contains(outsidePoint), isFalse);
    });

    test('GraphRect overlaps with overlapping rect', () {
      final rect1 = GraphRect.fromLTWH(0, 0, 100, 100);
      final rect2 = GraphRect.fromLTWH(50, 50, 100, 100);

      expect(rect1.overlaps(rect2), isTrue);
    });

    test('GraphRect does not overlap with separate rect', () {
      final rect1 = GraphRect.fromLTWH(0, 0, 100, 100);
      final rect2 = GraphRect.fromLTWH(200, 200, 100, 100);

      expect(rect1.overlaps(rect2), isFalse);
    });

    test('GraphRect inflate expands rect', () {
      final rect = GraphRect.fromLTWH(100, 100, 100, 100);

      final inflated = rect.inflate(10);

      expect(inflated.left, equals(90.0));
      expect(inflated.top, equals(90.0));
      expect(inflated.width, equals(120.0));
      expect(inflated.height, equals(120.0));
    });

    test('GraphRect deflate shrinks rect', () {
      final rect = GraphRect.fromLTWH(100, 100, 100, 100);

      final deflated = rect.deflate(10);

      expect(deflated.left, equals(110.0));
      expect(deflated.top, equals(110.0));
      expect(deflated.width, equals(80.0));
      expect(deflated.height, equals(80.0));
    });

    test('GraphRect translate moves rect', () {
      final rect = GraphRect.fromLTWH(100, 100, 50, 50);
      final offset = GraphOffset.fromXY(25, -10);

      final translated = rect.translate(offset);

      expect(translated.left, equals(125.0));
      expect(translated.top, equals(90.0));
      expect(translated.width, equals(50.0));
      expect(translated.height, equals(50.0));
    });

    test('GraphRect shift moves rect by position', () {
      final rect = GraphRect.fromLTWH(100, 100, 50, 50);
      final pos = GraphPosition.fromXY(25, -10);

      final shifted = rect.shift(pos);

      expect(shifted.left, equals(125.0));
      expect(shifted.top, equals(90.0));
    });

    test('GraphRect expandToInclude creates bounding rect', () {
      final rect1 = GraphRect.fromLTWH(0, 0, 100, 100);
      final rect2 = GraphRect.fromLTWH(150, 75, 50, 50);

      final expanded = rect1.expandToInclude(rect2);

      expect(expanded.left, equals(0.0));
      expect(expanded.top, equals(0.0));
      expect(expanded.right, equals(200.0));
      expect(expanded.bottom, equals(125.0));
    });

    test('GraphRect intersect returns overlap region', () {
      final rect1 = GraphRect.fromLTWH(0, 0, 100, 100);
      final rect2 = GraphRect.fromLTWH(50, 50, 100, 100);

      final intersection = rect1.intersect(rect2);

      expect(intersection.left, equals(50.0));
      expect(intersection.top, equals(50.0));
      expect(intersection.right, equals(100.0));
      expect(intersection.bottom, equals(100.0));
    });

    test('GraphRect fromCenter creates centered rect', () {
      final rect = GraphRect.fromCenter(
        center: GraphPosition.fromXY(100, 100),
        width: 50,
        height: 30,
      );

      expect(rect.left, equals(75.0));
      expect(rect.top, equals(85.0));
      expect(rect.width, equals(50.0));
      expect(rect.height, equals(30.0));
      expect(rect.center.dx, equals(100.0));
      expect(rect.center.dy, equals(100.0));
    });

    test('GraphRect fromPoints creates rect from corners', () {
      final rect = GraphRect.fromPoints(
        GraphPosition.fromXY(50, 100),
        GraphPosition.fromXY(150, 200),
      );

      expect(rect.left, equals(50.0));
      expect(rect.top, equals(100.0));
      expect(rect.right, equals(150.0));
      expect(rect.bottom, equals(200.0));
    });

    test('GraphRect corner accessors return correct positions', () {
      final rect = GraphRect.fromLTWH(100, 100, 200, 150);

      expect(rect.topLeft.dx, equals(100.0));
      expect(rect.topLeft.dy, equals(100.0));
      expect(rect.topRight.dx, equals(300.0));
      expect(rect.topRight.dy, equals(100.0));
      expect(rect.bottomLeft.dx, equals(100.0));
      expect(rect.bottomLeft.dy, equals(250.0));
      expect(rect.bottomRight.dx, equals(300.0));
      expect(rect.bottomRight.dy, equals(250.0));
    });

    test('GraphRect.zero is empty at origin', () {
      expect(GraphRect.zero.left, equals(0.0));
      expect(GraphRect.zero.top, equals(0.0));
      expect(GraphRect.zero.width, equals(0.0));
      expect(GraphRect.zero.height, equals(0.0));
      expect(GraphRect.zero.isEmpty, isTrue);
    });
  });

  // ===========================================================================
  // ScreenRect Operations
  // ===========================================================================

  group('ScreenRect Operations', () {
    test('ScreenRect contains point inside', () {
      final rect = ScreenRect.fromLTWH(100, 100, 200, 150);
      final insidePoint = ScreenPosition.fromXY(200, 175);

      expect(rect.contains(insidePoint), isTrue);
    });

    test('ScreenRect does not contain point outside', () {
      final rect = ScreenRect.fromLTWH(100, 100, 200, 150);
      final outsidePoint = ScreenPosition.fromXY(50, 50);

      expect(rect.contains(outsidePoint), isFalse);
    });

    test('ScreenRect overlaps with overlapping rect', () {
      final rect1 = ScreenRect.fromLTWH(0, 0, 100, 100);
      final rect2 = ScreenRect.fromLTWH(50, 50, 100, 100);

      expect(rect1.overlaps(rect2), isTrue);
    });

    test('ScreenRect fromPoints creates rect from corners', () {
      final rect = ScreenRect.fromPoints(
        ScreenPosition.fromXY(50, 100),
        ScreenPosition.fromXY(150, 200),
      );

      expect(rect.left, equals(50.0));
      expect(rect.top, equals(100.0));
      expect(rect.right, equals(150.0));
      expect(rect.bottom, equals(200.0));
    });

    test('ScreenRect accessors return correct values', () {
      final rect = ScreenRect.fromLTWH(100, 100, 200, 150);

      expect(rect.topLeft.dx, equals(100.0));
      expect(rect.topLeft.dy, equals(100.0));
      expect(rect.center.dx, equals(200.0));
      expect(rect.center.dy, equals(175.0));
      expect(rect.size.width, equals(200.0));
      expect(rect.size.height, equals(150.0));
    });

    test('ScreenRect.zero is empty at origin', () {
      expect(ScreenRect.zero.left, equals(0.0));
      expect(ScreenRect.zero.top, equals(0.0));
      expect(ScreenRect.zero.width, equals(0.0));
      expect(ScreenRect.zero.height, equals(0.0));
    });
  });

  // ===========================================================================
  // Edge Cases
  // ===========================================================================

  group('Edge Cases', () {
    test('viewport at extreme coordinates', () {
      const viewport = GraphViewport(x: 1e10, y: -1e10, zoom: 1.0);
      final graphPos = GraphPosition.fromXY(0, 0);

      final screenPos = viewport.toScreen(graphPos);

      expect(screenPos.dx, equals(1e10));
      expect(screenPos.dy, equals(-1e10));
    });

    test('coordinate conversion with very small delta', () {
      const viewport = GraphViewport(x: 0.001, y: 0.001, zoom: 1.001);
      final screenPos = ScreenPosition.fromXY(0.002, 0.002);

      final graphPos = viewport.toGraph(screenPos);
      final restored = viewport.toScreen(graphPos);

      expect(restored.dx, closeTo(screenPos.dx, 0.0001));
      expect(restored.dy, closeTo(screenPos.dy, 0.0001));
    });

    test('visibility check with point at exact boundary', () {
      const viewport = GraphViewport();
      const screenSize = Size(800, 600);

      // Point just inside the visible area
      final pointInside = GraphPosition.fromXY(399, 299);
      // Point clearly outside
      final pointOutside = GraphPosition.fromXY(900, 700);

      expect(viewport.isPointVisible(pointInside, screenSize), isTrue);
      expect(viewport.isPointVisible(pointOutside, screenSize), isFalse);
    });

    test('rect visibility with zero-size rect at visible position', () {
      const viewport = GraphViewport();
      const screenSize = Size(800, 600);
      final zeroRect = GraphRect.fromLTWH(400, 300, 0, 0);

      // A zero-size rect overlaps check may return true depending on Rect.overlaps behavior
      // The actual behavior is that overlaps returns true when rects share the same point
      expect(viewport.isRectVisible(zeroRect, screenSize), isTrue);
    });

    test('rect visibility with zero-size rect outside viewport', () {
      const viewport = GraphViewport();
      const screenSize = Size(800, 600);
      final zeroRect = GraphRect.fromLTWH(1000, 1000, 0, 0);

      expect(viewport.isRectVisible(zeroRect, screenSize), isFalse);
    });

    test('getVisibleArea with very small screen size', () {
      const viewport = GraphViewport(zoom: 2.0);
      const screenSize = Size(2, 2);

      final area = viewport.getVisibleArea(screenSize);

      expect(area.width, equals(1.0));
      expect(area.height, equals(1.0));
    });

    test('coordinate conversion with zoom at boundary values', () {
      // Very small zoom
      const smallZoom = GraphViewport(zoom: 0.001);
      final pos1 = smallZoom.toGraph(ScreenPosition.fromXY(1, 1));
      expect(pos1.dx, equals(1000.0));
      expect(pos1.dy, equals(1000.0));

      // Large zoom
      const largeZoom = GraphViewport(zoom: 1000.0);
      final pos2 = largeZoom.toGraph(ScreenPosition.fromXY(1000, 1000));
      expect(pos2.dx, equals(1.0));
      expect(pos2.dy, equals(1.0));
    });

    test('negative coordinates work correctly throughout', () {
      const viewport = GraphViewport(x: -100.0, y: -50.0, zoom: 1.0);
      final graphPos = GraphPosition.fromXY(-200, -100);

      final screenPos = viewport.toScreen(graphPos);

      // screen = graph * zoom + pan = -200 * 1 + (-100) = -300
      expect(screenPos.dx, equals(-300.0));
      expect(screenPos.dy, equals(-150.0));

      final restored = viewport.toGraph(screenPos);
      expect(restored.dx, closeTo(graphPos.dx, 0.001));
      expect(restored.dy, closeTo(graphPos.dy, 0.001));
    });
  });

  // ===========================================================================
  // Test Helpers Verification
  // ===========================================================================

  group('Test Helpers Verification', () {
    test('expectViewportPan verifies pan values correctly', () {
      const viewport = GraphViewport(x: 150.0, y: 250.0);

      expectViewportPan(viewport, 150.0, 250.0);
    });

    test('expectViewportZoom verifies zoom value correctly', () {
      const viewport = GraphViewport(zoom: 1.75);

      expectViewportZoom(viewport, 1.75);
    });

    test('screenPos helper creates correct position', () {
      final pos = screenPos(100, 200);

      expect(pos.dx, equals(100.0));
      expect(pos.dy, equals(200.0));
    });

    test('graphPos helper creates correct position', () {
      final pos = graphPos(150, 250);

      expect(pos.dx, equals(150.0));
      expect(pos.dy, equals(250.0));
    });

    test('screenOffset helper creates correct offset', () {
      final offset = screenOffset(30, 40);

      expect(offset.dx, equals(30.0));
      expect(offset.dy, equals(40.0));
    });

    test('graphOffset helper creates correct offset', () {
      final offset = graphOffset(50, 60);

      expect(offset.dx, equals(50.0));
      expect(offset.dy, equals(60.0));
    });
  });
}
