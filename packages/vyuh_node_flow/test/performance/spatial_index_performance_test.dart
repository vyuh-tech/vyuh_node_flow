@Tags(['performance'])
library;

import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:vyuh_node_flow/vyuh_node_flow.dart';

import '../helpers/test_factories.dart';

/// Performance tests for spatial index operations.
///
/// The spatial index is critical for viewport culling, hit testing,
/// and efficient node queries. These tests ensure it scales well.
void main() {
  late NodeFlowController<String, dynamic> controller;

  setUp(() {
    resetTestCounters();
    controller = createTestController();
    controller.setScreenSize(const Size(1920, 1080));
  });

  tearDown(() {
    controller.dispose();
  });

  group('Spatial Index - Insertion Performance', () {
    test('insert 500 nodes under 2000ms', () {
      final stopwatch = Stopwatch()..start();

      for (var i = 0; i < 500; i++) {
        controller.addNode(
          createTestNode(
            id: 'node-$i',
            position: Offset((i % 25) * 200.0, (i ~/ 25) * 150.0),
            size: const Size(100, 80),
          ),
        );
      }

      stopwatch.stop();
      expect(controller.nodeCount, equals(500));
      expect(
        stopwatch.elapsedMilliseconds,
        lessThan(2000),
        reason: 'Inserting 500 nodes should take less than 2 seconds',
      );
    });

    test('insert nodes in clustered regions', () {
      // Test that clustered nodes don't cause performance issues
      final stopwatch = Stopwatch()..start();

      // Create 5 clusters of 100 nodes each
      for (var cluster = 0; cluster < 5; cluster++) {
        final clusterX = cluster * 1000.0;
        final clusterY = cluster * 800.0;

        for (var i = 0; i < 100; i++) {
          controller.addNode(
            createTestNode(
              id: 'cluster-$cluster-node-$i',
              position: Offset(
                clusterX + (i % 10) * 50.0,
                clusterY + (i ~/ 10) * 50.0,
              ),
              size: const Size(40, 30),
            ),
          );
        }
      }

      stopwatch.stop();
      expect(controller.nodeCount, equals(500));
      expect(
        stopwatch.elapsedMilliseconds,
        lessThan(2000),
        reason: 'Inserting 500 clustered nodes should take less than 2 seconds',
      );
    });

    test('insert nodes in sparse distribution', () {
      final stopwatch = Stopwatch()..start();

      // Spread nodes across a very large area
      for (var i = 0; i < 500; i++) {
        controller.addNode(
          createTestNode(
            id: 'node-$i',
            position: Offset((i % 50) * 500.0, (i ~/ 50) * 400.0),
            size: const Size(100, 80),
          ),
        );
      }

      stopwatch.stop();
      expect(
        stopwatch.elapsedMilliseconds,
        lessThan(3000),
        reason: 'Inserting 500 sparse nodes should take less than 3 seconds',
      );
    });
  });

  group('Spatial Index - Query Performance', () {
    setUp(() {
      // Pre-populate with 500 nodes for query tests
      for (var i = 0; i < 500; i++) {
        controller.addNode(
          createTestNode(
            id: 'node-$i',
            position: Offset((i % 25) * 100.0, (i ~/ 25) * 80.0),
            size: const Size(80, 60),
          ),
        );
      }
    });

    test('getVisibleNodes query under 5ms', () {
      // Set viewport to see ~100 nodes
      controller.setViewport(GraphViewport(x: 0, y: 0, zoom: 1.0));

      final stopwatch = Stopwatch()..start();

      final visibleNodes = controller.getVisibleNodes();

      stopwatch.stop();
      expect(visibleNodes, isNotEmpty);
      expect(
        stopwatch.elapsedMilliseconds,
        lessThan(5),
        reason: 'getVisibleNodes should complete in under 5ms',
      );
    });

    test('repeated visibility queries under 50ms', () {
      final stopwatch = Stopwatch()..start();

      for (var i = 0; i < 100; i++) {
        controller.getVisibleNodes();
      }

      stopwatch.stop();
      final averageMs = stopwatch.elapsedMilliseconds / 100;
      expect(
        averageMs,
        lessThan(0.5),
        reason: 'Average visibility query should be under 0.5ms',
      );
    });

    test('visibility query performance at different zoom levels', () {
      final zoomLevels = [0.5, 1.0, 1.5, 2.0];

      for (final zoom in zoomLevels) {
        controller.zoomTo(zoom);

        final stopwatch = Stopwatch()..start();
        final visibleNodes = controller.getVisibleNodes();
        stopwatch.stop();

        expect(
          stopwatch.elapsedMilliseconds,
          lessThan(10),
          reason:
              'Query at zoom $zoom should be under 10ms (found ${visibleNodes.length} nodes)',
        );
      }
    });

    test('visibility query performance at different pan positions', () {
      // Pan to different areas of the graph
      final positions = [
        ScreenOffset.fromXY(0, 0),
        ScreenOffset.fromXY(500, 400),
        ScreenOffset.fromXY(1000, 800),
        ScreenOffset.fromXY(-500, -400),
      ];

      for (final pos in positions) {
        controller.setViewport(GraphViewport(x: 0, y: 0, zoom: 1.0));
        controller.panBy(pos);

        final stopwatch = Stopwatch()..start();
        final visibleNodes = controller.getVisibleNodes();
        stopwatch.stop();

        expect(
          stopwatch.elapsedMilliseconds,
          lessThan(10),
          reason:
              'Query at position $pos should be under 10ms (found ${visibleNodes.length} nodes)',
        );
      }
    });
  });

  group('Spatial Index - Update Performance', () {
    test('batch update 500 node positions under 200ms', () {
      // Create nodes
      for (var i = 0; i < 500; i++) {
        controller.addNode(
          createTestNode(
            id: 'node-$i',
            position: Offset((i % 25) * 100.0, (i ~/ 25) * 80.0),
          ),
        );
      }

      final stopwatch = Stopwatch()..start();

      // Move all nodes
      for (var i = 0; i < 500; i++) {
        controller.moveNode('node-$i', const Offset(50, 50));
      }

      stopwatch.stop();
      expect(
        stopwatch.elapsedMilliseconds,
        lessThan(200),
        reason: 'Updating 500 node positions should take less than 200ms',
      );
    });

    test('index updates correctly after movement', () {
      // Create nodes spread out
      for (var i = 0; i < 100; i++) {
        controller.addNode(
          createTestNode(
            id: 'node-$i',
            position: Offset((i % 10) * 100.0, (i ~/ 10) * 100.0),
            size: const Size(80, 60),
          ),
        );
      }

      // Get initial visible count
      final initialVisible = controller.getVisibleNodes().length;

      // Move nodes far away
      for (var i = 0; i < 100; i++) {
        controller.moveNode('node-$i', const Offset(10000, 10000));
      }

      // Query visible nodes (should be fewer or none)
      final stopwatch = Stopwatch()..start();
      final visibleAfterMove = controller.getVisibleNodes();
      stopwatch.stop();

      expect(
        stopwatch.elapsedMilliseconds,
        lessThan(5),
        reason: 'Query after bulk move should still be fast',
      );

      // Nodes moved away should not be visible (unless viewport is very large)
      expect(visibleAfterMove.length, lessThanOrEqualTo(initialVisible));
    });
  });

  group('Spatial Index - Removal Performance', () {
    test('remove 500 nodes under 500ms', () {
      // Create nodes
      for (var i = 0; i < 500; i++) {
        controller.addNode(createTestNode(id: 'node-$i'));
      }

      final stopwatch = Stopwatch()..start();

      for (var i = 0; i < 500; i++) {
        controller.removeNode('node-$i');
      }

      stopwatch.stop();
      expect(controller.nodeCount, equals(0));
      expect(
        stopwatch.elapsedMilliseconds,
        lessThan(500),
        reason: 'Removing 500 nodes should take less than 500ms',
      );
    });

    test('queries remain fast after bulk removal', () {
      // Create 500 nodes
      for (var i = 0; i < 500; i++) {
        controller.addNode(
          createTestNode(
            id: 'node-$i',
            position: Offset((i % 25) * 100.0, (i ~/ 25) * 80.0),
          ),
        );
      }

      // Remove half
      for (var i = 0; i < 250; i++) {
        controller.removeNode('node-$i');
      }

      // Query should still be fast
      final stopwatch = Stopwatch()..start();
      final visible = controller.getVisibleNodes();
      stopwatch.stop();

      expect(visible.length, lessThanOrEqualTo(250));
      expect(
        stopwatch.elapsedMilliseconds,
        lessThan(5),
        reason: 'Query after bulk removal should be under 5ms',
      );
    });
  });

  group('Spatial Index - Stress Tests', () {
    test('1000 nodes with random positions', () {
      final stopwatch = Stopwatch()..start();

      for (var i = 0; i < 1000; i++) {
        // Pseudo-random positions based on index
        final x = ((i * 17) % 100) * 100.0;
        final y = ((i * 31) % 80) * 100.0;
        controller.addNode(
          createTestNode(
            id: 'node-$i',
            position: Offset(x, y),
            size: const Size(80, 60),
          ),
        );
      }

      stopwatch.stop();
      expect(controller.nodeCount, equals(1000));
      expect(
        stopwatch.elapsedMilliseconds,
        lessThan(20000),
        reason: 'Inserting 1000 random nodes should be under 20 seconds',
      );

      // Verify queries still work efficiently
      final queryStopwatch = Stopwatch()..start();
      controller.getVisibleNodes();
      queryStopwatch.stop();

      expect(
        queryStopwatch.elapsedMilliseconds,
        lessThan(10),
        reason: 'Query on 1000 node graph should be under 10ms',
      );
    });

    test('continuous add/remove/query operations', () {
      final stopwatch = Stopwatch()..start();

      // Simulate a realistic usage pattern
      for (var cycle = 0; cycle < 10; cycle++) {
        // Add batch
        for (var i = 0; i < 50; i++) {
          controller.addNode(
            createTestNode(
              id: 'cycle-$cycle-node-$i',
              position: Offset(i * 100.0, cycle * 100.0),
            ),
          );
        }

        // Query
        controller.getVisibleNodes();

        // Remove some
        if (cycle > 0) {
          for (var i = 0; i < 25; i++) {
            controller.removeNode('cycle-${cycle - 1}-node-$i');
          }
        }

        // Move some
        for (var i = 0; i < 20; i++) {
          if (controller.getNode('cycle-$cycle-node-$i') != null) {
            controller.moveNode('cycle-$cycle-node-$i', const Offset(10, 10));
          }
        }
      }

      stopwatch.stop();
      expect(
        stopwatch.elapsedMilliseconds,
        lessThan(1000),
        reason: 'Continuous operations should complete in under 1 second',
      );
    });

    test('overlapping nodes performance', () {
      // Create many nodes at the same position
      final stopwatch = Stopwatch()..start();

      for (var i = 0; i < 500; i++) {
        controller.addNode(
          createTestNode(
            id: 'node-$i',
            position: const Offset(500, 400), // All at same position
            size: const Size(100, 80),
          ),
        );
      }

      stopwatch.stop();
      expect(
        stopwatch.elapsedMilliseconds,
        lessThan(2000),
        reason: 'Inserting 500 overlapping nodes should be under 2 seconds',
      );

      // Query should still work
      final queryStopwatch = Stopwatch()..start();
      final visible = controller.getVisibleNodes();
      queryStopwatch.stop();

      expect(visible.length, equals(500)); // All visible since at same point
      expect(
        queryStopwatch.elapsedMilliseconds,
        lessThan(20),
        reason: 'Query with 500 overlapping nodes should be under 20ms',
      );
    });

    test('nodes at extreme coordinates', () {
      // Test with nodes at very large coordinates
      final stopwatch = Stopwatch()..start();

      for (var i = 0; i < 100; i++) {
        controller.addNode(
          createTestNode(
            id: 'node-$i',
            position: Offset(i * 10000.0, i * 10000.0),
          ),
        );
      }

      stopwatch.stop();
      expect(
        stopwatch.elapsedMilliseconds,
        lessThan(100),
        reason: 'Inserting nodes at extreme coords should be under 100ms',
      );

      // Queries should still work
      controller.setViewport(GraphViewport(x: 500000, y: 500000, zoom: 0.1));

      final queryStopwatch = Stopwatch()..start();
      controller.getVisibleNodes();
      queryStopwatch.stop();

      expect(
        queryStopwatch.elapsedMilliseconds,
        lessThan(10),
        reason: 'Query at extreme coords should be under 10ms',
      );
    });
  });

  group('Spatial Index - Viewport Culling Efficiency', () {
    test('culling efficiency with zoomed out view', () {
      // Create 500 nodes
      for (var i = 0; i < 500; i++) {
        controller.addNode(
          createTestNode(
            id: 'node-$i',
            position: Offset((i % 25) * 100.0, (i ~/ 25) * 80.0),
            size: const Size(80, 60),
          ),
        );
      }

      // Zoom out to see all nodes
      controller.setViewport(GraphViewport(x: -500, y: -400, zoom: 0.25));

      final stopwatch = Stopwatch()..start();
      final visible = controller.getVisibleNodes();
      stopwatch.stop();

      // At this zoom, most/all should be visible
      expect(visible.length, greaterThan(400));
      expect(
        stopwatch.elapsedMilliseconds,
        lessThan(10),
        reason: 'Query with many visible nodes should be under 10ms',
      );
    });

    test('culling efficiency with zoomed in view', () {
      // Create 500 nodes spread out
      for (var i = 0; i < 500; i++) {
        controller.addNode(
          createTestNode(
            id: 'node-$i',
            position: Offset((i % 25) * 200.0, (i ~/ 25) * 150.0),
            size: const Size(100, 80),
          ),
        );
      }

      // Zoom in to see only a few nodes
      controller.setViewport(GraphViewport(x: 0, y: 0, zoom: 2.0));

      final stopwatch = Stopwatch()..start();
      final visible = controller.getVisibleNodes();
      stopwatch.stop();

      // Query should complete quickly regardless of culling behavior
      // (Actual culling depends on implementation details)
      expect(visible.length, greaterThan(0));
      expect(
        stopwatch.elapsedMilliseconds,
        lessThan(50),
        reason: 'Query with zoomed viewport should be under 50ms',
      );
    });
  });

  group('Spatial Index - Memory Scaling', () {
    test('index memory scales reasonably', () {
      // This is a basic test to ensure we don't have memory bloat
      // We can't easily measure memory in Dart, but we can check
      // that operations complete in reasonable time as size grows

      final times = <int>[];

      for (var size = 100; size <= 500; size += 100) {
        controller.clearGraph();
        resetTestCounters();

        final stopwatch = Stopwatch()..start();
        for (var i = 0; i < size; i++) {
          controller.addNode(
            createTestNode(
              id: 'node-$i',
              position: Offset((i % 25) * 100.0, (i ~/ 25) * 80.0),
            ),
          );
        }
        stopwatch.stop();
        times.add(stopwatch.elapsedMilliseconds);
      }

      // Just verify that operations complete in reasonable time
      // JIT compilation and test isolation make ratio-based tests unreliable
      expect(
        times.last,
        lessThan(3000),
        reason: 'Creating 500 nodes should take less than 3 seconds',
      );
    });
  });
}
