@Tags(['performance'])
library;

import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:vyuh_node_flow/vyuh_node_flow.dart';

import '../helpers/test_factories.dart';

/// Performance tests for rapid sequential operations.
///
/// These tests verify that the library handles rapid, repeated operations
/// without performance degradation or state corruption.
void main() {
  late NodeFlowController<String> controller;

  setUp(() {
    resetTestCounters();
    controller = createTestController();
    controller.setScreenSize(const Size(1920, 1080));
  });

  tearDown(() {
    controller.dispose();
  });

  group('Rapid Operations - Node Addition', () {
    test('100 node additions under 200ms', () {
      final stopwatch = Stopwatch()..start();

      for (var i = 0; i < 100; i++) {
        controller.addNode(createTestNode(id: 'node-$i'));
      }

      stopwatch.stop();
      expect(controller.nodeCount, equals(100));
      expect(
        stopwatch.elapsedMilliseconds,
        lessThan(200),
        reason: '100 rapid node additions should complete in under 200ms',
      );
    });

    test('average node addition time under 2ms', () {
      final times = <int>[];

      for (var i = 0; i < 100; i++) {
        final stopwatch = Stopwatch()..start();
        controller.addNode(createTestNode(id: 'node-$i'));
        stopwatch.stop();
        times.add(stopwatch.elapsedMicroseconds);
      }

      final averageMicros = times.reduce((a, b) => a + b) / times.length;
      final averageMs = averageMicros / 1000;

      expect(
        averageMs,
        lessThan(2),
        reason: 'Average node addition should be under 2ms',
      );
    });
  });

  group('Rapid Operations - Node Movement', () {
    test('100 node movements under 200ms', () {
      // Setup nodes
      for (var i = 0; i < 100; i++) {
        controller.addNode(createTestNode(id: 'node-$i'));
      }

      final stopwatch = Stopwatch()..start();

      for (var i = 0; i < 100; i++) {
        controller.moveNode('node-$i', const Offset(10, 10));
      }

      stopwatch.stop();
      expect(
        stopwatch.elapsedMilliseconds,
        lessThan(200),
        reason: '100 node movements should complete in under 200ms',
      );
    });

    test('1000 movements on single node under 500ms', () {
      controller.addNode(createTestNode(id: 'target'));

      final stopwatch = Stopwatch()..start();

      for (var i = 0; i < 1000; i++) {
        controller.moveNode('target', const Offset(1, 1));
      }

      stopwatch.stop();
      expect(
        stopwatch.elapsedMilliseconds,
        lessThan(500),
        reason: '1000 movements on one node should complete in under 500ms',
      );

      // Verify final position
      final node = controller.getNode('target');
      expect(node!.position.value, equals(const Offset(1000, 1000)));
    });

    test('moveNode maintains consistent performance over time', () {
      controller.addNode(createTestNode(id: 'target'));

      // Measure first batch
      final stopwatch1 = Stopwatch()..start();
      for (var i = 0; i < 100; i++) {
        controller.moveNode('target', const Offset(1, 1));
      }
      stopwatch1.stop();
      final time1 = stopwatch1.elapsedMilliseconds;

      // Measure second batch
      final stopwatch2 = Stopwatch()..start();
      for (var i = 0; i < 100; i++) {
        controller.moveNode('target', const Offset(1, 1));
      }
      stopwatch2.stop();
      final time2 = stopwatch2.elapsedMilliseconds;

      // Performance should not degrade significantly
      // Use 3x multiplier to account for JIT warmup and test isolation effects
      // Also add minimum baseline of 10ms since very small time1 values can cause false failures
      expect(
        time2,
        lessThanOrEqualTo((time1 + 10) * 3),
        reason: 'Performance should not degrade over repeated operations',
      );
    });
  });

  group('Rapid Operations - Connection Creation', () {
    test('100 connection creations under 500ms', () {
      // Setup nodes
      for (var i = 0; i < 100; i++) {
        controller.addNode(
          createTestNodeWithOutputPort(id: 'src-$i', portId: 'out'),
        );
        controller.addNode(
          createTestNodeWithInputPort(id: 'tgt-$i', portId: 'in'),
        );
      }

      final stopwatch = Stopwatch()..start();

      for (var i = 0; i < 100; i++) {
        controller.addConnection(
          createTestConnection(
            id: 'conn-$i',
            sourceNodeId: 'src-$i',
            sourcePortId: 'out',
            targetNodeId: 'tgt-$i',
            targetPortId: 'in',
          ),
        );
      }

      stopwatch.stop();
      expect(controller.connectionCount, equals(100));
      expect(
        stopwatch.elapsedMilliseconds,
        lessThan(500),
        reason: '100 connection creations should complete in under 500ms',
      );
    });
  });

  group('Rapid Operations - Selection Changes', () {
    test('rapid selection changes under 200ms', () {
      // Setup nodes
      for (var i = 0; i < 100; i++) {
        controller.addNode(createTestNode(id: 'node-$i'));
      }

      final stopwatch = Stopwatch()..start();

      // Rapidly change selection
      for (var i = 0; i < 100; i++) {
        controller.selectNode('node-$i');
      }

      stopwatch.stop();
      expect(
        stopwatch.elapsedMilliseconds,
        lessThan(200),
        reason: '100 selection changes should complete in under 200ms',
      );
    });

    test('rapid toggle selection under 200ms', () {
      // Setup nodes
      for (var i = 0; i < 50; i++) {
        controller.addNode(createTestNode(id: 'node-$i'));
      }

      final stopwatch = Stopwatch()..start();

      // Toggle each node twice (on/off)
      for (var round = 0; round < 2; round++) {
        for (var i = 0; i < 50; i++) {
          controller.selectNode('node-$i', toggle: true);
        }
      }

      stopwatch.stop();
      expect(
        stopwatch.elapsedMilliseconds,
        lessThan(200),
        reason: '100 toggle operations should complete in under 200ms',
      );
    });

    test('selectAll/clearSelection cycles under 100ms', () {
      // Setup nodes
      for (var i = 0; i < 100; i++) {
        controller.addNode(createTestNode(id: 'node-$i'));
      }

      final stopwatch = Stopwatch()..start();

      // Cycle 10 times
      for (var i = 0; i < 10; i++) {
        controller.selectAllNodes();
        controller.clearNodeSelection();
      }

      stopwatch.stop();
      expect(
        stopwatch.elapsedMilliseconds,
        lessThan(100),
        reason: '10 selectAll/clear cycles should complete in under 100ms',
      );
    });
  });

  group('Rapid Operations - Viewport Updates', () {
    test('rapid pan operations under 100ms', () {
      controller.addNode(createTestNode(id: 'node-1'));

      final stopwatch = Stopwatch()..start();

      for (var i = 0; i < 1000; i++) {
        controller.panBy(ScreenOffset.fromXY(1, 1));
      }

      stopwatch.stop();
      expect(
        stopwatch.elapsedMilliseconds,
        lessThan(100),
        reason: '1000 pan operations should complete in under 100ms',
      );
    });

    test('rapid zoom operations under 100ms', () {
      controller.addNode(createTestNode(id: 'node-1'));

      final stopwatch = Stopwatch()..start();

      for (var i = 0; i < 1000; i++) {
        // Oscillate zoom to stay in bounds
        controller.zoomBy((i % 2 == 0) ? 0.001 : -0.001);
      }

      stopwatch.stop();
      expect(
        stopwatch.elapsedMilliseconds,
        lessThan(100),
        reason: '1000 zoom operations should complete in under 100ms',
      );
    });

    test('combined pan/zoom operations under 200ms', () {
      controller.addNode(createTestNode(id: 'node-1'));

      final stopwatch = Stopwatch()..start();

      for (var i = 0; i < 500; i++) {
        controller.panBy(ScreenOffset.fromXY(1, 1));
        controller.zoomBy((i % 2 == 0) ? 0.001 : -0.001);
      }

      stopwatch.stop();
      expect(
        stopwatch.elapsedMilliseconds,
        lessThan(200),
        reason:
            '500 combined pan/zoom operations should complete in under 200ms',
      );
    });
  });

  group('Rapid Operations - Drag Sequences', () {
    test('100 complete drag sequences under 500ms', () {
      controller.addNode(createTestNode(id: 'node-1'));

      final stopwatch = Stopwatch()..start();

      for (var i = 0; i < 100; i++) {
        controller.startNodeDrag('node-1');
        controller.moveNodeDrag(const Offset(10, 10));
        controller.endNodeDrag();
      }

      stopwatch.stop();
      expect(
        stopwatch.elapsedMilliseconds,
        lessThan(500),
        reason: '100 drag sequences should complete in under 500ms',
      );
    });

    test('rapid drag movements under 200ms', () {
      controller.addNode(createTestNode(id: 'node-1'));
      controller.startNodeDrag('node-1');

      final stopwatch = Stopwatch()..start();

      for (var i = 0; i < 500; i++) {
        controller.moveNodeDrag(const Offset(1, 1));
      }

      stopwatch.stop();
      controller.endNodeDrag();

      expect(
        stopwatch.elapsedMilliseconds,
        lessThan(200),
        reason: '500 drag movements should complete in under 200ms',
      );
    });
  });

  group('Rapid Operations - Z-Index Changes', () {
    test('rapid bringToFront operations under 200ms', () {
      for (var i = 0; i < 100; i++) {
        controller.addNode(createTestNode(id: 'node-$i', zIndex: i));
      }

      final stopwatch = Stopwatch()..start();

      for (var i = 0; i < 100; i++) {
        controller.bringNodeToFront('node-$i');
      }

      stopwatch.stop();
      expect(
        stopwatch.elapsedMilliseconds,
        lessThan(200),
        reason: '100 bringToFront operations should complete in under 200ms',
      );
    });

    test('rapid sendToBack operations under 200ms', () {
      for (var i = 0; i < 100; i++) {
        controller.addNode(createTestNode(id: 'node-$i', zIndex: i));
      }

      final stopwatch = Stopwatch()..start();

      for (var i = 0; i < 100; i++) {
        controller.sendNodeToBack('node-$i');
      }

      stopwatch.stop();
      expect(
        stopwatch.elapsedMilliseconds,
        lessThan(200),
        reason: '100 sendToBack operations should complete in under 200ms',
      );
    });
  });

  group('Rapid Operations - Annotation Operations', () {
    test('100 annotation creations under 300ms', () {
      final stopwatch = Stopwatch()..start();

      for (var i = 0; i < 100; i++) {
        controller.addAnnotation(
          createTestStickyAnnotation(
            id: 'sticky-$i',
            position: Offset(i * 50.0, i * 50.0),
          ),
        );
      }

      stopwatch.stop();
      expect(controller.annotations.sortedAnnotations.length, equals(100));
      expect(
        stopwatch.elapsedMilliseconds,
        lessThan(300),
        reason: '100 annotation creations should complete in under 300ms',
      );
    });
  });

  group('Rapid Operations - Mixed Operations', () {
    test('interleaved add/remove operations under 500ms', () {
      final stopwatch = Stopwatch()..start();

      for (var i = 0; i < 200; i++) {
        controller.addNode(createTestNode(id: 'node-$i'));
        if (i >= 100) {
          controller.removeNode('node-${i - 100}');
        }
      }

      stopwatch.stop();
      expect(controller.nodeCount, equals(100));
      expect(
        stopwatch.elapsedMilliseconds,
        lessThan(500),
        reason: '200 interleaved add/remove should complete in under 500ms',
      );
    });

    test('mixed operations simulation under 1 second', () {
      final stopwatch = Stopwatch()..start();

      // Create nodes
      for (var i = 0; i < 50; i++) {
        controller.addNode(createTestNodeWithPorts(id: 'node-$i'));
      }

      // Create connections
      for (var i = 0; i < 49; i++) {
        controller.addConnection(
          createTestConnection(
            id: 'conn-$i',
            sourceNodeId: 'node-$i',
            sourcePortId: 'output-1',
            targetNodeId: 'node-${i + 1}',
            targetPortId: 'input-1',
          ),
        );
      }

      // Selection operations
      for (var i = 0; i < 10; i++) {
        controller.selectAllNodes();
        controller.clearNodeSelection();
      }

      // Movement operations
      for (var i = 0; i < 50; i++) {
        controller.moveNode('node-$i', const Offset(5, 5));
      }

      // Viewport operations
      for (var i = 0; i < 50; i++) {
        controller.panBy(ScreenOffset.fromXY(2, 2));
        controller.zoomBy((i % 2 == 0) ? 0.01 : -0.01);
      }

      // Z-index operations
      for (var i = 0; i < 25; i++) {
        controller.bringNodeToFront('node-$i');
        controller.sendNodeToBack('node-${i + 25}');
      }

      stopwatch.stop();
      expect(
        stopwatch.elapsedMilliseconds,
        lessThan(1000),
        reason: 'Mixed operations simulation should complete under 1 second',
      );
    });
  });

  group('Rapid Operations - Performance Consistency', () {
    test('operation timing remains stable across 10 batches', () {
      // Setup
      for (var i = 0; i < 100; i++) {
        controller.addNode(createTestNode(id: 'node-$i'));
      }

      final batchTimes = <int>[];

      // Measure 10 batches of 100 movements each
      for (var batch = 0; batch < 10; batch++) {
        final stopwatch = Stopwatch()..start();
        for (var i = 0; i < 100; i++) {
          controller.moveNode('node-$i', const Offset(1, 1));
        }
        stopwatch.stop();
        batchTimes.add(stopwatch.elapsedMilliseconds);
      }

      // Calculate statistics
      final average = batchTimes.reduce((a, b) => a + b) / batchTimes.length;
      final maxTime = batchTimes.reduce((a, b) => a > b ? a : b);

      // No batch should be more than 3x the average (plus baseline for small averages)
      // Using 3x multiplier and +10 baseline to account for JIT warmup effects
      expect(
        maxTime,
        lessThanOrEqualTo((average + 10) * 3),
        reason: 'Performance should remain consistent across batches',
      );
    });

    test('no performance degradation after 5000 operations', () {
      controller.addNode(createTestNode(id: 'target'));

      // Measure first 1000 operations
      final stopwatch1 = Stopwatch()..start();
      for (var i = 0; i < 1000; i++) {
        controller.moveNode('target', const Offset(1, 1));
      }
      stopwatch1.stop();
      final time1 = stopwatch1.elapsedMilliseconds;

      // Perform 3000 more operations
      for (var i = 0; i < 3000; i++) {
        controller.moveNode('target', const Offset(1, 1));
      }

      // Measure last 1000 operations
      final stopwatch2 = Stopwatch()..start();
      for (var i = 0; i < 1000; i++) {
        controller.moveNode('target', const Offset(1, 1));
      }
      stopwatch2.stop();
      final time2 = stopwatch2.elapsedMilliseconds;

      // Performance should not degrade by more than 50%
      expect(
        time2,
        lessThan(time1 * 1.5),
        reason: 'Performance should not degrade after many operations',
      );
    });
  });
}
