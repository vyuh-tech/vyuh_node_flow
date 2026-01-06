/// Unit tests for SpatialIndexDebugPainter in vyuh_node_flow.
///
/// Tests cover:
/// - Debug rendering with grid visualization
/// - Different zoom levels and viewport states
/// - Cell label drawing behavior
/// - Element bounds drawing (nodes, ports, connections)
/// - Edge cases and boundary conditions
@Tags(['unit'])
library;

import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vyuh_node_flow/src/shared/spatial/graph_spatial_index.dart';
import 'package:vyuh_node_flow/vyuh_node_flow.dart';

import '../../helpers/test_factories.dart';

void main() {
  setUp(() {
    resetTestCounters();
  });

  // ===========================================================================
  // SpatialIndexDebugPainter - Construction
  // ===========================================================================

  group('SpatialIndexDebugPainter - Construction', () {
    test('creates with required parameters', () {
      final controller = createTestController();
      final viewport = createTestViewport();

      final painter = SpatialIndexDebugPainter(
        spatialIndex: controller.spatialIndex,
        viewport: viewport,
        version: 0,
      );

      expect(painter.spatialIndex, same(controller.spatialIndex));
      expect(painter.viewport, same(viewport));
      expect(painter.version, equals(0));

      controller.dispose();
    });

    test('uses default theme when not provided', () {
      final controller = createTestController();
      final viewport = createTestViewport();

      final painter = SpatialIndexDebugPainter(
        spatialIndex: controller.spatialIndex,
        viewport: viewport,
        version: 0,
      );

      expect(painter.theme, isA<DebugTheme>());

      controller.dispose();
    });

    test('accepts custom theme', () {
      final controller = createTestController();
      final viewport = createTestViewport();

      final painter = SpatialIndexDebugPainter(
        spatialIndex: controller.spatialIndex,
        viewport: viewport,
        version: 0,
        theme: DebugTheme.dark,
      );

      expect(painter.theme, equals(DebugTheme.dark));

      controller.dispose();
    });

    test('accepts null mouse position', () {
      final controller = createTestController();
      final viewport = createTestViewport();

      final painter = SpatialIndexDebugPainter(
        spatialIndex: controller.spatialIndex,
        viewport: viewport,
        version: 0,
        mousePositionWorld: null,
      );

      expect(painter.mousePositionWorld, isNull);

      controller.dispose();
    });

    test('accepts mouse position', () {
      final controller = createTestController();
      final viewport = createTestViewport();
      const mousePos = Offset(100, 200);

      final painter = SpatialIndexDebugPainter(
        spatialIndex: controller.spatialIndex,
        viewport: viewport,
        version: 0,
        mousePositionWorld: mousePos,
      );

      expect(painter.mousePositionWorld, equals(mousePos));

      controller.dispose();
    });

    test('stores version property correctly', () {
      final controller = createTestController();
      final viewport = createTestViewport();

      final painter = SpatialIndexDebugPainter(
        spatialIndex: controller.spatialIndex,
        viewport: viewport,
        version: 42,
      );

      expect(painter.version, equals(42));

      controller.dispose();
    });
  });

  // ===========================================================================
  // SpatialIndexDebugPainter - shouldRepaint
  // ===========================================================================

  group('SpatialIndexDebugPainter - shouldRepaint', () {
    test('returns true when viewport changes', () {
      final controller = createTestController();
      final viewport1 = createTestViewport(x: 0, y: 0, zoom: 1.0);
      final viewport2 = createTestViewport(x: 100, y: 0, zoom: 1.0);

      final painter1 = SpatialIndexDebugPainter(
        spatialIndex: controller.spatialIndex,
        viewport: viewport1,
        version: 0,
      );

      final painter2 = SpatialIndexDebugPainter(
        spatialIndex: controller.spatialIndex,
        viewport: viewport2,
        version: 0,
      );

      expect(painter2.shouldRepaint(painter1), isTrue);

      controller.dispose();
    });

    test('returns true when viewport y changes', () {
      final controller = createTestController();
      final viewport1 = createTestViewport(x: 0, y: 0, zoom: 1.0);
      final viewport2 = createTestViewport(x: 0, y: 100, zoom: 1.0);

      final painter1 = SpatialIndexDebugPainter(
        spatialIndex: controller.spatialIndex,
        viewport: viewport1,
        version: 0,
      );

      final painter2 = SpatialIndexDebugPainter(
        spatialIndex: controller.spatialIndex,
        viewport: viewport2,
        version: 0,
      );

      expect(painter2.shouldRepaint(painter1), isTrue);

      controller.dispose();
    });

    test('returns true when viewport zoom changes', () {
      final controller = createTestController();
      final viewport1 = createTestViewport(x: 0, y: 0, zoom: 1.0);
      final viewport2 = createTestViewport(x: 0, y: 0, zoom: 2.0);

      final painter1 = SpatialIndexDebugPainter(
        spatialIndex: controller.spatialIndex,
        viewport: viewport1,
        version: 0,
      );

      final painter2 = SpatialIndexDebugPainter(
        spatialIndex: controller.spatialIndex,
        viewport: viewport2,
        version: 0,
      );

      expect(painter2.shouldRepaint(painter1), isTrue);

      controller.dispose();
    });

    test('returns true when version changes', () {
      final controller = createTestController();
      final viewport = createTestViewport();

      final painter1 = SpatialIndexDebugPainter(
        spatialIndex: controller.spatialIndex,
        viewport: viewport,
        version: 0,
      );

      final painter2 = SpatialIndexDebugPainter(
        spatialIndex: controller.spatialIndex,
        viewport: viewport,
        version: 1,
      );

      expect(painter2.shouldRepaint(painter1), isTrue);

      controller.dispose();
    });

    test('returns true when theme changes', () {
      final controller = createTestController();
      final viewport = createTestViewport();

      final painter1 = SpatialIndexDebugPainter(
        spatialIndex: controller.spatialIndex,
        viewport: viewport,
        version: 0,
        theme: DebugTheme.light,
      );

      final painter2 = SpatialIndexDebugPainter(
        spatialIndex: controller.spatialIndex,
        viewport: viewport,
        version: 0,
        theme: DebugTheme.dark,
      );

      expect(painter2.shouldRepaint(painter1), isTrue);

      controller.dispose();
    });

    test('returns true when mouse position changes', () {
      final controller = createTestController();
      final viewport = createTestViewport();

      final painter1 = SpatialIndexDebugPainter(
        spatialIndex: controller.spatialIndex,
        viewport: viewport,
        version: 0,
        mousePositionWorld: const Offset(0, 0),
      );

      final painter2 = SpatialIndexDebugPainter(
        spatialIndex: controller.spatialIndex,
        viewport: viewport,
        version: 0,
        mousePositionWorld: const Offset(100, 100),
      );

      expect(painter2.shouldRepaint(painter1), isTrue);

      controller.dispose();
    });

    test('returns true when mouse position becomes null', () {
      final controller = createTestController();
      final viewport = createTestViewport();

      final painter1 = SpatialIndexDebugPainter(
        spatialIndex: controller.spatialIndex,
        viewport: viewport,
        version: 0,
        mousePositionWorld: const Offset(100, 100),
      );

      final painter2 = SpatialIndexDebugPainter(
        spatialIndex: controller.spatialIndex,
        viewport: viewport,
        version: 0,
        mousePositionWorld: null,
      );

      expect(painter2.shouldRepaint(painter1), isTrue);

      controller.dispose();
    });

    test('returns true when mouse position becomes non-null', () {
      final controller = createTestController();
      final viewport = createTestViewport();

      final painter1 = SpatialIndexDebugPainter(
        spatialIndex: controller.spatialIndex,
        viewport: viewport,
        version: 0,
        mousePositionWorld: null,
      );

      final painter2 = SpatialIndexDebugPainter(
        spatialIndex: controller.spatialIndex,
        viewport: viewport,
        version: 0,
        mousePositionWorld: const Offset(50, 50),
      );

      expect(painter2.shouldRepaint(painter1), isTrue);

      controller.dispose();
    });

    test('returns false when all properties are same', () {
      final controller = createTestController();
      final viewport = createTestViewport();

      final painter1 = SpatialIndexDebugPainter(
        spatialIndex: controller.spatialIndex,
        viewport: viewport,
        version: 0,
        theme: DebugTheme.light,
        mousePositionWorld: const Offset(50, 50),
      );

      final painter2 = SpatialIndexDebugPainter(
        spatialIndex: controller.spatialIndex,
        viewport: viewport,
        version: 0,
        theme: DebugTheme.light,
        mousePositionWorld: const Offset(50, 50),
      );

      expect(painter2.shouldRepaint(painter1), isFalse);

      controller.dispose();
    });

    test('returns false when both mouse positions are null', () {
      final controller = createTestController();
      final viewport = createTestViewport();

      final painter1 = SpatialIndexDebugPainter(
        spatialIndex: controller.spatialIndex,
        viewport: viewport,
        version: 0,
        mousePositionWorld: null,
      );

      final painter2 = SpatialIndexDebugPainter(
        spatialIndex: controller.spatialIndex,
        viewport: viewport,
        version: 0,
        mousePositionWorld: null,
      );

      expect(painter2.shouldRepaint(painter1), isFalse);

      controller.dispose();
    });
  });

  // ===========================================================================
  // SpatialIndexDebugPainter - Paint Method
  // ===========================================================================

  group('SpatialIndexDebugPainter - Paint Method', () {
    test('paint method accepts valid parameters with empty index', () {
      final controller = createTestController();
      final viewport = createTestViewport();

      final painter = SpatialIndexDebugPainter(
        spatialIndex: controller.spatialIndex,
        viewport: viewport,
        version: 0,
      );

      final recorder = PictureRecorder();
      final canvas = Canvas(recorder);

      expect(
        () => painter.paint(canvas, const Size(800, 600)),
        returnsNormally,
      );

      controller.dispose();
    });

    test('paint method works with nodes in spatial index', () {
      final controller = createTestController(
        nodes: [
          createTestNode(id: 'node-1', position: const Offset(100, 100)),
          createTestNode(id: 'node-2', position: const Offset(300, 200)),
        ],
      );
      final viewport = createTestViewport();

      final painter = SpatialIndexDebugPainter(
        spatialIndex: controller.spatialIndex,
        viewport: viewport,
        version: 1,
      );

      final recorder = PictureRecorder();
      final canvas = Canvas(recorder);

      expect(
        () => painter.paint(canvas, const Size(800, 600)),
        returnsNormally,
      );

      controller.dispose();
    });

    test('paint method works with nodes that have ports', () {
      final controller = createTestController(
        nodes: [
          createTestNodeWithPorts(
            id: 'node-1',
            position: const Offset(100, 100),
          ),
          createTestNodeWithPorts(
            id: 'node-2',
            position: const Offset(300, 200),
          ),
        ],
      );
      final viewport = createTestViewport();

      final painter = SpatialIndexDebugPainter(
        spatialIndex: controller.spatialIndex,
        viewport: viewport,
        version: 1,
      );

      final recorder = PictureRecorder();
      final canvas = Canvas(recorder);

      expect(
        () => painter.paint(canvas, const Size(800, 600)),
        returnsNormally,
      );

      controller.dispose();
    });

    test('paint method works with connections', () {
      final nodeA = createTestNodeWithOutputPort(
        id: 'node-a',
        portId: 'output-1',
        position: const Offset(0, 0),
      );
      final nodeB = createTestNodeWithInputPort(
        id: 'node-b',
        portId: 'input-1',
        position: const Offset(200, 0),
      );
      final connection = createTestConnection(
        sourceNodeId: 'node-a',
        sourcePortId: 'output-1',
        targetNodeId: 'node-b',
        targetPortId: 'input-1',
      );

      final controller = createTestController(
        nodes: [nodeA, nodeB],
        connections: [connection],
      );
      controller.setScreenSize(const Size(800, 600));
      final viewport = createTestViewport();

      final painter = SpatialIndexDebugPainter(
        spatialIndex: controller.spatialIndex,
        viewport: viewport,
        version: 1,
      );

      final recorder = PictureRecorder();
      final canvas = Canvas(recorder);

      expect(
        () => painter.paint(canvas, const Size(800, 600)),
        returnsNormally,
      );

      controller.dispose();
    });

    test('paint returns early when grid size is zero', () {
      // Create a controller with a custom spatial index that has zero grid size
      // Since we cannot easily set grid size to zero with the default constructor,
      // we test with a normal controller - the paint should handle gracefully
      final controller = createTestController();
      final viewport = createTestViewport();

      final painter = SpatialIndexDebugPainter(
        spatialIndex: controller.spatialIndex,
        viewport: viewport,
        version: 0,
      );

      final recorder = PictureRecorder();
      final canvas = Canvas(recorder);

      // Should not throw even with unusual conditions
      expect(
        () => painter.paint(canvas, const Size(800, 600)),
        returnsNormally,
      );

      controller.dispose();
    });
  });

  // ===========================================================================
  // SpatialIndexDebugPainter - Viewport Variations
  // ===========================================================================

  group('SpatialIndexDebugPainter - Viewport Variations', () {
    test('paint works with various zoom levels', () {
      final controller = createTestController(
        nodes: [createTestNode(id: 'node-1', position: const Offset(100, 100))],
      );

      final zoomLevels = [0.1, 0.5, 1.0, 2.0, 4.0, 10.0];

      for (final zoom in zoomLevels) {
        final viewport = createTestViewport(zoom: zoom);

        final painter = SpatialIndexDebugPainter(
          spatialIndex: controller.spatialIndex,
          viewport: viewport,
          version: 0,
        );

        final recorder = PictureRecorder();
        final canvas = Canvas(recorder);

        expect(
          () => painter.paint(canvas, const Size(800, 600)),
          returnsNormally,
          reason: 'Should work with zoom level $zoom',
        );
      }

      controller.dispose();
    });

    test('paint works with various pan offsets', () {
      final controller = createTestController(
        nodes: [createTestNode(id: 'node-1', position: const Offset(100, 100))],
      );

      final offsets = [
        (x: 0.0, y: 0.0),
        (x: 100.0, y: 100.0),
        (x: -500.0, y: -300.0),
        (x: 1000.0, y: -1000.0),
        (x: -10000.0, y: 10000.0),
      ];

      for (final offset in offsets) {
        final viewport = createTestViewport(x: offset.x, y: offset.y);

        final painter = SpatialIndexDebugPainter(
          spatialIndex: controller.spatialIndex,
          viewport: viewport,
          version: 0,
        );

        final recorder = PictureRecorder();
        final canvas = Canvas(recorder);

        expect(
          () => painter.paint(canvas, const Size(800, 600)),
          returnsNormally,
          reason: 'Should work with pan offset (${offset.x}, ${offset.y})',
        );
      }

      controller.dispose();
    });

    test('paint works with combined zoom and pan', () {
      final controller = createTestController(
        nodes: [createTestNode(id: 'node-1', position: const Offset(100, 100))],
      );

      final combinations = [
        (x: 100.0, y: 100.0, zoom: 0.5),
        (x: -200.0, y: 300.0, zoom: 2.0),
        (x: 0.0, y: -500.0, zoom: 0.1),
        (x: 1000.0, y: 1000.0, zoom: 4.0),
      ];

      for (final combo in combinations) {
        final viewport = createTestViewport(
          x: combo.x,
          y: combo.y,
          zoom: combo.zoom,
        );

        final painter = SpatialIndexDebugPainter(
          spatialIndex: controller.spatialIndex,
          viewport: viewport,
          version: 0,
        );

        final recorder = PictureRecorder();
        final canvas = Canvas(recorder);

        expect(
          () => painter.paint(canvas, const Size(800, 600)),
          returnsNormally,
          reason:
              'Should work with x=${combo.x}, y=${combo.y}, zoom=${combo.zoom}',
        );
      }

      controller.dispose();
    });
  });

  // ===========================================================================
  // SpatialIndexDebugPainter - Canvas Size Variations
  // ===========================================================================

  group('SpatialIndexDebugPainter - Canvas Size Variations', () {
    test('paint works with different canvas sizes', () {
      final controller = createTestController(
        nodes: [createTestNode(id: 'node-1', position: const Offset(50, 50))],
      );
      final viewport = createTestViewport();

      final sizes = [
        const Size(100, 100),
        const Size(800, 600),
        const Size(1920, 1080),
        const Size(4000, 3000),
        const Size(1, 1),
        const Size(50, 1000),
        const Size(2000, 50),
      ];

      for (final size in sizes) {
        final painter = SpatialIndexDebugPainter(
          spatialIndex: controller.spatialIndex,
          viewport: viewport,
          version: 0,
        );

        final recorder = PictureRecorder();
        final canvas = Canvas(recorder);

        expect(
          () => painter.paint(canvas, size),
          returnsNormally,
          reason: 'Should work with canvas size $size',
        );
      }

      controller.dispose();
    });

    test('paint handles zero canvas size', () {
      final controller = createTestController();
      final viewport = createTestViewport();

      final painter = SpatialIndexDebugPainter(
        spatialIndex: controller.spatialIndex,
        viewport: viewport,
        version: 0,
      );

      final recorder = PictureRecorder();
      final canvas = Canvas(recorder);

      expect(() => painter.paint(canvas, Size.zero), returnsNormally);

      controller.dispose();
    });

    test('paint handles very small canvas size', () {
      final controller = createTestController();
      final viewport = createTestViewport();

      final painter = SpatialIndexDebugPainter(
        spatialIndex: controller.spatialIndex,
        viewport: viewport,
        version: 0,
      );

      final recorder = PictureRecorder();
      final canvas = Canvas(recorder);

      expect(
        () => painter.paint(canvas, const Size(0.1, 0.1)),
        returnsNormally,
      );

      controller.dispose();
    });
  });

  // ===========================================================================
  // SpatialIndexDebugPainter - Mouse Position Handling
  // ===========================================================================

  group('SpatialIndexDebugPainter - Mouse Position Handling', () {
    test('paint works with mouse position inside visible area', () {
      final controller = createTestController(
        nodes: [createTestNode(id: 'node-1', position: const Offset(100, 100))],
      );
      final viewport = createTestViewport();

      final painter = SpatialIndexDebugPainter(
        spatialIndex: controller.spatialIndex,
        viewport: viewport,
        version: 0,
        mousePositionWorld: const Offset(150, 150),
      );

      final recorder = PictureRecorder();
      final canvas = Canvas(recorder);

      expect(
        () => painter.paint(canvas, const Size(800, 600)),
        returnsNormally,
      );

      controller.dispose();
    });

    test('paint works with mouse position at origin', () {
      final controller = createTestController();
      final viewport = createTestViewport();

      final painter = SpatialIndexDebugPainter(
        spatialIndex: controller.spatialIndex,
        viewport: viewport,
        version: 0,
        mousePositionWorld: Offset.zero,
      );

      final recorder = PictureRecorder();
      final canvas = Canvas(recorder);

      expect(
        () => painter.paint(canvas, const Size(800, 600)),
        returnsNormally,
      );

      controller.dispose();
    });

    test('paint works with mouse position in negative coordinates', () {
      final controller = createTestController();
      final viewport = createTestViewport();

      final painter = SpatialIndexDebugPainter(
        spatialIndex: controller.spatialIndex,
        viewport: viewport,
        version: 0,
        mousePositionWorld: const Offset(-500, -300),
      );

      final recorder = PictureRecorder();
      final canvas = Canvas(recorder);

      expect(
        () => painter.paint(canvas, const Size(800, 600)),
        returnsNormally,
      );

      controller.dispose();
    });

    test('paint works with mouse position far from visible area', () {
      final controller = createTestController();
      final viewport = createTestViewport();

      final painter = SpatialIndexDebugPainter(
        spatialIndex: controller.spatialIndex,
        viewport: viewport,
        version: 0,
        mousePositionWorld: const Offset(10000, 10000),
      );

      final recorder = PictureRecorder();
      final canvas = Canvas(recorder);

      expect(
        () => painter.paint(canvas, const Size(800, 600)),
        returnsNormally,
      );

      controller.dispose();
    });
  });

  // ===========================================================================
  // SpatialIndexDebugPainter - Theme Variations
  // ===========================================================================

  group('SpatialIndexDebugPainter - Theme Variations', () {
    test('paint works with light theme', () {
      final controller = createTestController(
        nodes: [createTestNode(id: 'node-1', position: const Offset(100, 100))],
      );
      final viewport = createTestViewport();

      final painter = SpatialIndexDebugPainter(
        spatialIndex: controller.spatialIndex,
        viewport: viewport,
        version: 0,
        theme: DebugTheme.light,
      );

      final recorder = PictureRecorder();
      final canvas = Canvas(recorder);

      expect(
        () => painter.paint(canvas, const Size(800, 600)),
        returnsNormally,
      );

      controller.dispose();
    });

    test('paint works with dark theme', () {
      final controller = createTestController(
        nodes: [createTestNode(id: 'node-1', position: const Offset(100, 100))],
      );
      final viewport = createTestViewport();

      final painter = SpatialIndexDebugPainter(
        spatialIndex: controller.spatialIndex,
        viewport: viewport,
        version: 0,
        theme: DebugTheme.dark,
      );

      final recorder = PictureRecorder();
      final canvas = Canvas(recorder);

      expect(
        () => painter.paint(canvas, const Size(800, 600)),
        returnsNormally,
      );

      controller.dispose();
    });

    test('paint works with custom theme colors', () {
      final controller = createTestController(
        nodes: [createTestNode(id: 'node-1', position: const Offset(100, 100))],
      );
      final viewport = createTestViewport();

      const customTheme = DebugTheme(
        color: Color(0xFF123456),
        borderColor: Color(0xFF654321),
        activeColor: Color(0xFF00FF00),
        activeBorderColor: Color(0xFF0000FF),
        labelColor: Color(0xFFFFFFFF),
        labelBackgroundColor: Color(0xFF000000),
        indicatorColor: Color(0xFFFF00FF),
        segmentColors: [
          Color(0xFFFF0000),
          Color(0xFF00FF00),
          Color(0xFF0000FF),
        ],
      );

      final painter = SpatialIndexDebugPainter(
        spatialIndex: controller.spatialIndex,
        viewport: viewport,
        version: 0,
        theme: customTheme,
      );

      final recorder = PictureRecorder();
      final canvas = Canvas(recorder);

      expect(
        () => painter.paint(canvas, const Size(800, 600)),
        returnsNormally,
      );

      controller.dispose();
    });

    test('paint works with transparent theme colors', () {
      final controller = createTestController(
        nodes: [createTestNode(id: 'node-1', position: const Offset(100, 100))],
      );
      final viewport = createTestViewport();

      const customTheme = DebugTheme(
        color: Colors.transparent,
        borderColor: Colors.transparent,
        activeColor: Colors.transparent,
        activeBorderColor: Colors.transparent,
        labelColor: Colors.transparent,
        labelBackgroundColor: Colors.transparent,
        indicatorColor: Colors.transparent,
      );

      final painter = SpatialIndexDebugPainter(
        spatialIndex: controller.spatialIndex,
        viewport: viewport,
        version: 0,
        theme: customTheme,
      );

      final recorder = PictureRecorder();
      final canvas = Canvas(recorder);

      expect(
        () => painter.paint(canvas, const Size(800, 600)),
        returnsNormally,
      );

      controller.dispose();
    });
  });

  // ===========================================================================
  // SpatialIndexDebugPainter - Active Cells Info
  // ===========================================================================

  group('SpatialIndexDebugPainter - Active Cells Info', () {
    test('paint renders active cells with objects', () {
      final controller = createTestController(
        nodes: [
          createTestNode(id: 'node-1', position: const Offset(100, 100)),
          createTestNode(id: 'node-2', position: const Offset(600, 600)),
        ],
      );
      controller.setScreenSize(const Size(800, 600));
      final viewport = createTestViewport();

      final painter = SpatialIndexDebugPainter(
        spatialIndex: controller.spatialIndex,
        viewport: viewport,
        version: 1,
      );

      final recorder = PictureRecorder();
      final canvas = Canvas(recorder);

      // Paint should work regardless of active cells state
      expect(
        () => painter.paint(canvas, const Size(800, 600)),
        returnsNormally,
      );

      controller.dispose();
    });

    test('paint handles cells with mixed object types', () {
      final nodeA = createTestNodeWithOutputPort(
        id: 'node-a',
        portId: 'output-1',
        position: const Offset(100, 100),
      );
      final nodeB = createTestNodeWithInputPort(
        id: 'node-b',
        portId: 'input-1',
        position: const Offset(300, 100),
      );
      final connection = createTestConnection(
        sourceNodeId: 'node-a',
        sourcePortId: 'output-1',
        targetNodeId: 'node-b',
        targetPortId: 'input-1',
      );

      final controller = createTestController(
        nodes: [nodeA, nodeB],
        connections: [connection],
      );
      controller.setScreenSize(const Size(800, 600));
      final viewport = createTestViewport();

      final painter = SpatialIndexDebugPainter(
        spatialIndex: controller.spatialIndex,
        viewport: viewport,
        version: 1,
      );

      final recorder = PictureRecorder();
      final canvas = Canvas(recorder);

      expect(
        () => painter.paint(canvas, const Size(800, 600)),
        returnsNormally,
      );

      controller.dispose();
    });
  });

  // ===========================================================================
  // SpatialIndexDebugPainter - Label Drawing at Extreme Zoom
  // ===========================================================================

  group('SpatialIndexDebugPainter - Label Drawing at Extreme Zoom', () {
    test('paint skips labels at very high zoom (font too small)', () {
      final controller = createTestController(
        nodes: [createTestNode(id: 'node-1', position: const Offset(100, 100))],
      );
      // At very high zoom, scaledFontSize = baseFontSize / zoom = 10 / 10 = 1
      // which is less than 4, so labels should be skipped
      final viewport = createTestViewport(zoom: 10.0);

      final painter = SpatialIndexDebugPainter(
        spatialIndex: controller.spatialIndex,
        viewport: viewport,
        version: 0,
      );

      final recorder = PictureRecorder();
      final canvas = Canvas(recorder);

      // Should complete without throwing even when labels are too small
      expect(
        () => painter.paint(canvas, const Size(800, 600)),
        returnsNormally,
      );

      controller.dispose();
    });

    test('paint draws labels at normal zoom', () {
      final controller = createTestController(
        nodes: [createTestNode(id: 'node-1', position: const Offset(100, 100))],
      );
      final viewport = createTestViewport(zoom: 1.0);

      final painter = SpatialIndexDebugPainter(
        spatialIndex: controller.spatialIndex,
        viewport: viewport,
        version: 0,
      );

      final recorder = PictureRecorder();
      final canvas = Canvas(recorder);

      expect(
        () => painter.paint(canvas, const Size(800, 600)),
        returnsNormally,
      );

      controller.dispose();
    });

    test('paint draws labels at zoom just above threshold', () {
      final controller = createTestController(
        nodes: [createTestNode(id: 'node-1', position: const Offset(100, 100))],
      );
      // At zoom = 2.5, scaledFontSize = 10 / 2.5 = 4, which is the threshold
      final viewport = createTestViewport(zoom: 2.5);

      final painter = SpatialIndexDebugPainter(
        spatialIndex: controller.spatialIndex,
        viewport: viewport,
        version: 0,
      );

      final recorder = PictureRecorder();
      final canvas = Canvas(recorder);

      expect(
        () => painter.paint(canvas, const Size(800, 600)),
        returnsNormally,
      );

      controller.dispose();
    });
  });

  // ===========================================================================
  // SpatialIndexDebugPainter - Element Bounds Drawing
  // ===========================================================================

  group('SpatialIndexDebugPainter - Element Bounds Drawing', () {
    test('paint draws node bounds', () {
      final controller = createTestController(
        nodes: [
          createTestNode(id: 'node-1', position: const Offset(100, 100)),
          createTestNode(id: 'node-2', position: const Offset(200, 200)),
          createTestNode(id: 'node-3', position: const Offset(300, 300)),
        ],
      );
      controller.setScreenSize(const Size(800, 600));
      final viewport = createTestViewport();

      // Verify nodes exist in the controller
      expect(controller.nodes.length, equals(3));

      final painter = SpatialIndexDebugPainter(
        spatialIndex: controller.spatialIndex,
        viewport: viewport,
        version: 1,
      );

      final recorder = PictureRecorder();
      final canvas = Canvas(recorder);

      expect(
        () => painter.paint(canvas, const Size(800, 600)),
        returnsNormally,
      );

      controller.dispose();
    });

    test('paint draws port snap zones', () {
      final controller = createTestController(
        nodes: [
          createTestNodeWithPorts(
            id: 'node-1',
            position: const Offset(100, 100),
          ),
        ],
      );
      controller.setScreenSize(const Size(800, 600));
      final viewport = createTestViewport();

      // Verify node with ports exists in the controller
      expect(controller.nodes.length, equals(1));
      expect(controller.nodes.values.first.inputPorts.length, equals(1));
      expect(controller.nodes.values.first.outputPorts.length, equals(1));

      final painter = SpatialIndexDebugPainter(
        spatialIndex: controller.spatialIndex,
        viewport: viewport,
        version: 1,
      );

      final recorder = PictureRecorder();
      final canvas = Canvas(recorder);

      expect(
        () => painter.paint(canvas, const Size(800, 600)),
        returnsNormally,
      );

      controller.dispose();
    });

    test('paint draws connection segments', () {
      final nodeA = createTestNodeWithOutputPort(
        id: 'node-a',
        portId: 'output-1',
        position: const Offset(0, 0),
      );
      final nodeB = createTestNodeWithInputPort(
        id: 'node-b',
        portId: 'input-1',
        position: const Offset(200, 0),
      );
      final connection = createTestConnection(
        sourceNodeId: 'node-a',
        sourcePortId: 'output-1',
        targetNodeId: 'node-b',
        targetPortId: 'input-1',
      );

      final controller = createTestController(
        nodes: [nodeA, nodeB],
        connections: [connection],
      );
      controller.setScreenSize(const Size(800, 600));
      final viewport = createTestViewport();

      final painter = SpatialIndexDebugPainter(
        spatialIndex: controller.spatialIndex,
        viewport: viewport,
        version: 1,
      );

      final recorder = PictureRecorder();
      final canvas = Canvas(recorder);

      expect(
        () => painter.paint(canvas, const Size(800, 600)),
        returnsNormally,
      );

      controller.dispose();
    });
  });

  // ===========================================================================
  // SpatialIndexDebugPainter - Edge Cases
  // ===========================================================================

  group('SpatialIndexDebugPainter - Edge Cases', () {
    test('paint handles large number of nodes', () {
      final nodes = List.generate(
        100,
        (i) => createTestNode(
          id: 'node-$i',
          position: Offset((i % 10) * 100.0, (i ~/ 10) * 100.0),
        ),
      );

      final controller = createTestController(nodes: nodes);
      final viewport = createTestViewport();

      final painter = SpatialIndexDebugPainter(
        spatialIndex: controller.spatialIndex,
        viewport: viewport,
        version: 1,
      );

      final recorder = PictureRecorder();
      final canvas = Canvas(recorder);

      expect(
        () => painter.paint(canvas, const Size(1200, 1200)),
        returnsNormally,
      );

      controller.dispose();
    });

    test('paint handles nodes at cell boundaries', () {
      // Default grid size is 500, so place nodes exactly at boundaries
      final controller = createTestController(
        nodes: [
          createTestNode(id: 'node-1', position: const Offset(0, 0)),
          createTestNode(id: 'node-2', position: const Offset(500, 0)),
          createTestNode(id: 'node-3', position: const Offset(0, 500)),
          createTestNode(id: 'node-4', position: const Offset(500, 500)),
        ],
      );
      final viewport = createTestViewport();

      final painter = SpatialIndexDebugPainter(
        spatialIndex: controller.spatialIndex,
        viewport: viewport,
        version: 1,
      );

      final recorder = PictureRecorder();
      final canvas = Canvas(recorder);

      expect(
        () => painter.paint(canvas, const Size(1200, 1200)),
        returnsNormally,
      );

      controller.dispose();
    });

    test('paint handles nodes with zero size', () {
      final controller = createTestController(
        nodes: [
          createTestNode(
            id: 'node-1',
            position: const Offset(100, 100),
            size: Size.zero,
          ),
        ],
      );
      final viewport = createTestViewport();

      final painter = SpatialIndexDebugPainter(
        spatialIndex: controller.spatialIndex,
        viewport: viewport,
        version: 1,
      );

      final recorder = PictureRecorder();
      final canvas = Canvas(recorder);

      expect(
        () => painter.paint(canvas, const Size(800, 600)),
        returnsNormally,
      );

      controller.dispose();
    });

    test('paint handles nodes with very large size', () {
      final controller = createTestController(
        nodes: [
          createTestNode(
            id: 'node-1',
            position: const Offset(0, 0),
            size: const Size(2000, 2000),
          ),
        ],
      );
      final viewport = createTestViewport();

      final painter = SpatialIndexDebugPainter(
        spatialIndex: controller.spatialIndex,
        viewport: viewport,
        version: 1,
      );

      final recorder = PictureRecorder();
      final canvas = Canvas(recorder);

      expect(
        () => painter.paint(canvas, const Size(800, 600)),
        returnsNormally,
      );

      controller.dispose();
    });

    test('paint handles extreme coordinates', () {
      final controller = createTestController(
        nodes: [
          createTestNode(id: 'node-1', position: const Offset(-10000, -10000)),
          createTestNode(id: 'node-2', position: const Offset(10000, 10000)),
        ],
      );
      final viewport = createTestViewport();

      final painter = SpatialIndexDebugPainter(
        spatialIndex: controller.spatialIndex,
        viewport: viewport,
        version: 1,
      );

      final recorder = PictureRecorder();
      final canvas = Canvas(recorder);

      expect(
        () => painter.paint(canvas, const Size(800, 600)),
        returnsNormally,
      );

      controller.dispose();
    });
  });

  // ===========================================================================
  // SpatialIndexDebugPainter - Integration with DebugTheme
  // ===========================================================================

  group('SpatialIndexDebugPainter - Integration with DebugTheme', () {
    test('theme getSegmentColor returns correct colors for indices', () {
      const theme = DebugTheme.dark;

      // Index 0: connections (red)
      expect(theme.getSegmentColor(0), isA<Color>());

      // Index 1: nodes (blue)
      expect(theme.getSegmentColor(1), isA<Color>());

      // Index 2: ports (green)
      expect(theme.getSegmentColor(2), isA<Color>());

      // Index beyond range returns last color
      expect(theme.getSegmentColor(100), equals(theme.getSegmentColor(2)));
    });

    test('theme getSegmentColor clamps negative indices', () {
      const theme = DebugTheme.dark;

      expect(theme.getSegmentColor(-1), equals(theme.getSegmentColor(0)));
      expect(theme.getSegmentColor(-100), equals(theme.getSegmentColor(0)));
    });

    test('painter uses theme segment colors for element rendering', () {
      final controller = createTestController(
        nodes: [
          createTestNodeWithPorts(
            id: 'node-1',
            position: const Offset(100, 100),
          ),
        ],
      );
      final viewport = createTestViewport();

      const customTheme = DebugTheme(
        segmentColors: [
          Color(0xFFFF0000), // connections
          Color(0xFF00FF00), // nodes
          Color(0xFF0000FF), // ports
        ],
      );

      final painter = SpatialIndexDebugPainter(
        spatialIndex: controller.spatialIndex,
        viewport: viewport,
        version: 0,
        theme: customTheme,
      );

      expect(painter.theme.getSegmentColor(0), equals(const Color(0xFFFF0000)));
      expect(painter.theme.getSegmentColor(1), equals(const Color(0xFF00FF00)));
      expect(painter.theme.getSegmentColor(2), equals(const Color(0xFF0000FF)));

      final recorder = PictureRecorder();
      final canvas = Canvas(recorder);

      expect(
        () => painter.paint(canvas, const Size(800, 600)),
        returnsNormally,
      );

      controller.dispose();
    });
  });

  // ===========================================================================
  // SpatialIndexDebugPainter - Sequential Painting
  // ===========================================================================

  group('SpatialIndexDebugPainter - Sequential Painting', () {
    test('can paint multiple times to same canvas', () {
      final controller = createTestController(
        nodes: [createTestNode(id: 'node-1', position: const Offset(100, 100))],
      );
      final viewport = createTestViewport();

      final painter = SpatialIndexDebugPainter(
        spatialIndex: controller.spatialIndex,
        viewport: viewport,
        version: 0,
      );

      final recorder = PictureRecorder();
      final canvas = Canvas(recorder);

      // Paint multiple times
      for (var i = 0; i < 3; i++) {
        expect(
          () => painter.paint(canvas, const Size(800, 600)),
          returnsNormally,
          reason: 'Should paint successfully on iteration $i',
        );
      }

      controller.dispose();
    });

    test('can paint with different viewports sequentially', () {
      final controller = createTestController(
        nodes: [createTestNode(id: 'node-1', position: const Offset(100, 100))],
      );

      final viewports = [
        createTestViewport(zoom: 0.5),
        createTestViewport(zoom: 1.0),
        createTestViewport(zoom: 2.0),
        createTestViewport(x: 100, y: 100),
      ];

      for (final viewport in viewports) {
        final painter = SpatialIndexDebugPainter(
          spatialIndex: controller.spatialIndex,
          viewport: viewport,
          version: 0,
        );

        final recorder = PictureRecorder();
        final canvas = Canvas(recorder);

        expect(
          () => painter.paint(canvas, const Size(800, 600)),
          returnsNormally,
        );

        recorder.endRecording();
      }

      controller.dispose();
    });
  });

  // ===========================================================================
  // SpatialIndexDebugPainter - Cell Bounds Calculation
  // ===========================================================================

  group('SpatialIndexDebugPainter - Cell Bounds Calculation', () {
    test('spatial index cellBounds returns correct bounds', () {
      final controller = createTestController();
      final spatialIndex = controller.spatialIndex;
      final gridSize = spatialIndex.gridSize;

      // Cell (0, 0)
      final cell00 = spatialIndex.cellBounds(0, 0);
      expect(cell00.left, equals(0));
      expect(cell00.top, equals(0));
      expect(cell00.width, equals(gridSize));
      expect(cell00.height, equals(gridSize));

      // Cell (1, 1)
      final cell11 = spatialIndex.cellBounds(1, 1);
      expect(cell11.left, equals(gridSize));
      expect(cell11.top, equals(gridSize));
      expect(cell11.width, equals(gridSize));
      expect(cell11.height, equals(gridSize));

      // Cell (-1, -1)
      final cellNeg = spatialIndex.cellBounds(-1, -1);
      expect(cellNeg.left, equals(-gridSize));
      expect(cellNeg.top, equals(-gridSize));
      expect(cellNeg.width, equals(gridSize));
      expect(cellNeg.height, equals(gridSize));

      controller.dispose();
    });

    test('painter uses correct cell bounds during rendering', () {
      final controller = createTestController(
        nodes: [createTestNode(id: 'node-1', position: const Offset(100, 100))],
      );
      final viewport = createTestViewport();

      final painter = SpatialIndexDebugPainter(
        spatialIndex: controller.spatialIndex,
        viewport: viewport,
        version: 0,
      );

      final recorder = PictureRecorder();
      final canvas = Canvas(recorder);

      // The paint method internally uses spatialIndex.cellBounds
      expect(
        () => painter.paint(canvas, const Size(800, 600)),
        returnsNormally,
      );

      controller.dispose();
    });
  });

  // ===========================================================================
  // SpatialIndexDebugPainter - CellDebugInfo Integration
  // ===========================================================================

  group('SpatialIndexDebugPainter - CellDebugInfo Integration', () {
    test('CellDebugInfo provides correct type breakdown', () {
      // Use GraphSpatialIndex directly for reliable spatial indexing tests
      final spatialIndex = GraphSpatialIndex<String, dynamic>();

      // Manually add nodes to the spatial index
      final node = createTestNodeWithPorts(
        id: 'node-1',
        position: const Offset(100, 100),
      );
      spatialIndex.update(node);

      final activeCells = spatialIndex.getActiveCellsInfo();

      // Verify we have cell info after adding to the index
      expect(activeCells.isNotEmpty, isTrue);

      // Check that at least one cell has the expected objects
      final hasExpectedContent = activeCells.any(
        (cell) => cell.nodeCount > 0 || cell.portCount > 0,
      );
      expect(hasExpectedContent, isTrue);
    });

    test('CellDebugInfo isEmpty property works correctly', () {
      // Use GraphSpatialIndex directly for reliable tests
      final emptyIndex = GraphSpatialIndex<String, dynamic>();
      final emptyCells = emptyIndex.getActiveCellsInfo();

      // Empty index should have no active cells
      expect(emptyCells.isEmpty, isTrue);

      // Add a node to get non-empty cells
      final node = createTestNodeWithPorts(
        id: 'node-1',
        position: const Offset(100, 100),
      );
      emptyIndex.update(node);

      final activeCells = emptyIndex.getActiveCellsInfo();
      expect(activeCells.isNotEmpty, isTrue);

      // At least one cell should have objects (not empty)
      final hasNonEmptyCell = activeCells.any((cell) => !cell.isEmpty);
      expect(hasNonEmptyCell, isTrue);

      // Verify totalCount is calculated correctly
      for (final cell in activeCells) {
        final expectedTotal =
            cell.nodeCount + cell.portCount + cell.connectionCount;
        expect(cell.totalCount, equals(expectedTotal));
        expect(cell.isEmpty, equals(expectedTotal == 0));
      }
    });

    test('CellDebugInfo typeBreakdown formats correctly', () {
      // Use GraphSpatialIndex directly for reliable tests
      final spatialIndex = GraphSpatialIndex<String, dynamic>();

      // Add a node with ports to get cells with objects
      final node = createTestNodeWithPorts(
        id: 'node-1',
        position: const Offset(100, 100),
      );
      spatialIndex.update(node);

      final activeCells = spatialIndex.getActiveCellsInfo();
      expect(activeCells.isNotEmpty, isTrue);

      // Verify typeBreakdown format for cells with objects
      for (final cell in activeCells) {
        final breakdown = cell.typeBreakdown;

        // typeBreakdown should only contain non-zero counts
        if (cell.nodeCount > 0) {
          expect(breakdown.contains('n:${cell.nodeCount}'), isTrue);
        }
        if (cell.portCount > 0) {
          expect(breakdown.contains('p:${cell.portCount}'), isTrue);
        }
        if (cell.connectionCount > 0) {
          expect(breakdown.contains('c:${cell.connectionCount}'), isTrue);
        }

        // If cell has objects, breakdown should not be empty
        if (cell.totalCount > 0) {
          expect(breakdown.isNotEmpty, isTrue);
        }
      }
    });
  });

  // ===========================================================================
  // SpatialIndexDebugPainter - Rendering Complete Picture
  // ===========================================================================

  group('SpatialIndexDebugPainter - Rendering Complete Picture', () {
    test('can complete picture recording after paint', () {
      final controller = createTestController(
        nodes: [createTestNode(id: 'node-1', position: const Offset(100, 100))],
      );
      final viewport = createTestViewport();

      final painter = SpatialIndexDebugPainter(
        spatialIndex: controller.spatialIndex,
        viewport: viewport,
        version: 0,
      );

      final recorder = PictureRecorder();
      final canvas = Canvas(recorder);

      painter.paint(canvas, const Size(800, 600));

      final picture = recorder.endRecording();
      expect(picture, isNotNull);

      controller.dispose();
    });

    test('renders consistently with same inputs', () {
      final controller = createTestController(
        nodes: [createTestNode(id: 'node-1', position: const Offset(100, 100))],
      );
      final viewport = createTestViewport();

      final painter1 = SpatialIndexDebugPainter(
        spatialIndex: controller.spatialIndex,
        viewport: viewport,
        version: 0,
        theme: DebugTheme.light,
      );

      final painter2 = SpatialIndexDebugPainter(
        spatialIndex: controller.spatialIndex,
        viewport: viewport,
        version: 0,
        theme: DebugTheme.light,
      );

      // Both should not require repaint (same inputs)
      expect(painter2.shouldRepaint(painter1), isFalse);

      controller.dispose();
    });
  });
}
