@Tags(['performance'])
library;

import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:vyuh_node_flow/vyuh_node_flow.dart';

import '../helpers/test_factories.dart';

/// Performance tests for large graphs.
///
/// Target: 500 nodes at 60 FPS (conservative, guaranteed smooth).
/// These tests verify that the library handles large graphs efficiently.
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

  group('Large Graph - Node Creation', () {
    test('create 100 nodes under 300ms', () {
      final stopwatch = Stopwatch()..start();

      for (var i = 0; i < 100; i++) {
        controller.addNode(
          createTestNode(
            id: 'node-$i',
            position: Offset((i % 10) * 200.0, (i ~/ 10) * 150.0),
          ),
        );
      }

      stopwatch.stop();
      expect(controller.nodeCount, equals(100));
      expect(
        stopwatch.elapsedMilliseconds,
        lessThan(300),
        reason: 'Creating 100 nodes should take less than 300ms',
      );
    });

    test('create 500 nodes under 2000ms', () {
      final stopwatch = Stopwatch()..start();

      for (var i = 0; i < 500; i++) {
        controller.addNode(
          createTestNode(
            id: 'node-$i',
            position: Offset((i % 25) * 200.0, (i ~/ 25) * 150.0),
          ),
        );
      }

      stopwatch.stop();
      expect(controller.nodeCount, equals(500));
      expect(
        stopwatch.elapsedMilliseconds,
        lessThan(2000),
        reason: 'Creating 500 nodes should take less than 2 seconds',
      );
    });

    test('create 1000 nodes under 6000ms', () {
      final stopwatch = Stopwatch()..start();

      for (var i = 0; i < 1000; i++) {
        controller.addNode(
          createTestNode(
            id: 'node-$i',
            position: Offset((i % 40) * 200.0, (i ~/ 40) * 150.0),
          ),
        );
      }

      stopwatch.stop();
      expect(controller.nodeCount, equals(1000));
      expect(
        stopwatch.elapsedMilliseconds,
        lessThan(6000),
        reason: 'Creating 1000 nodes should take less than 6 seconds',
      );
    });
  });

  group('Large Graph - Connection Creation', () {
    test('create 500 connections under 500ms', () {
      // First create source and target nodes
      for (var i = 0; i < 50; i++) {
        controller.addNode(
          createTestNodeWithOutputPort(id: 'src-$i', portId: 'out'),
        );
        controller.addNode(
          createTestNodeWithInputPort(id: 'tgt-$i', portId: 'in'),
        );
      }

      final stopwatch = Stopwatch()..start();

      // Create connections: each source connects to 10 targets
      var connId = 0;
      for (var src = 0; src < 50; src++) {
        for (var tgt = 0; tgt < 10; tgt++) {
          controller.addConnection(
            createTestConnection(
              id: 'conn-${connId++}',
              sourceNodeId: 'src-$src',
              sourcePortId: 'out',
              targetNodeId: 'tgt-${(src + tgt) % 50}',
              targetPortId: 'in',
            ),
          );
        }
      }

      stopwatch.stop();
      expect(controller.connectionCount, equals(500));
      expect(
        stopwatch.elapsedMilliseconds,
        lessThan(500),
        reason: 'Creating 500 connections should take less than 500ms',
      );
    });

    test('create 2000 connections under 1 second', () {
      // Create nodes
      for (var i = 0; i < 100; i++) {
        controller.addNode(
          createTestNodeWithOutputPort(id: 'src-$i', portId: 'out'),
        );
        controller.addNode(
          createTestNodeWithInputPort(id: 'tgt-$i', portId: 'in'),
        );
      }

      final stopwatch = Stopwatch()..start();

      var connId = 0;
      for (var src = 0; src < 100; src++) {
        for (var tgt = 0; tgt < 20; tgt++) {
          controller.addConnection(
            createTestConnection(
              id: 'conn-${connId++}',
              sourceNodeId: 'src-$src',
              sourcePortId: 'out',
              targetNodeId: 'tgt-${(src + tgt) % 100}',
              targetPortId: 'in',
            ),
          );
        }
      }

      stopwatch.stop();
      expect(controller.connectionCount, equals(2000));
      expect(
        stopwatch.elapsedMilliseconds,
        lessThan(1000),
        reason: 'Creating 2000 connections should take less than 1 second',
      );
    });
  });

  group('Large Graph - Viewport Operations', () {
    test('fitToView with 500 nodes under 50ms', () {
      // Create 500 nodes spread across a large area
      for (var i = 0; i < 500; i++) {
        controller.addNode(
          createTestNode(
            id: 'node-$i',
            position: Offset((i % 25) * 300.0, (i ~/ 25) * 200.0),
            size: const Size(150, 80),
          ),
        );
      }

      final stopwatch = Stopwatch()..start();

      controller.fitToView();

      stopwatch.stop();
      expect(
        stopwatch.elapsedMilliseconds,
        lessThan(50),
        reason: 'fitToView with 500 nodes should take less than 50ms',
      );
    });

    test('pan operations with 500 nodes under 10ms', () {
      // Create 500 nodes
      for (var i = 0; i < 500; i++) {
        controller.addNode(
          createTestNode(
            id: 'node-$i',
            position: Offset((i % 25) * 200.0, (i ~/ 25) * 150.0),
          ),
        );
      }

      final stopwatch = Stopwatch()..start();

      // Perform 100 pan operations
      for (var i = 0; i < 100; i++) {
        controller.panBy(ScreenOffset.fromXY(10, 10));
      }

      stopwatch.stop();

      // Average should be under 0.1ms per pan
      final averageMs = stopwatch.elapsedMilliseconds / 100;
      expect(
        averageMs,
        lessThan(1),
        reason: 'Average pan operation should be under 1ms',
      );
    });

    test('zoom operations with 500 nodes under 10ms', () {
      // Create 500 nodes
      for (var i = 0; i < 500; i++) {
        controller.addNode(
          createTestNode(
            id: 'node-$i',
            position: Offset((i % 25) * 200.0, (i ~/ 25) * 150.0),
          ),
        );
      }

      final stopwatch = Stopwatch()..start();

      // Perform 100 zoom operations
      for (var i = 0; i < 100; i++) {
        if (i % 2 == 0) {
          controller.zoomBy(0.01);
        } else {
          controller.zoomBy(-0.01);
        }
      }

      stopwatch.stop();

      final averageMs = stopwatch.elapsedMilliseconds / 100;
      expect(
        averageMs,
        lessThan(1),
        reason: 'Average zoom operation should be under 1ms',
      );
    });
  });

  group('Large Graph - Node Operations', () {
    test('move 100 nodes under 100ms', () {
      // Create nodes
      for (var i = 0; i < 100; i++) {
        controller.addNode(createTestNode(id: 'node-$i'));
      }

      final stopwatch = Stopwatch()..start();

      // Move each node
      for (var i = 0; i < 100; i++) {
        controller.moveNode('node-$i', const Offset(50, 50));
      }

      stopwatch.stop();
      expect(
        stopwatch.elapsedMilliseconds,
        lessThan(100),
        reason: 'Moving 100 nodes should take less than 100ms',
      );
    });

    test('bringToFront 100 nodes under 100ms', () {
      // Create nodes
      for (var i = 0; i < 100; i++) {
        controller.addNode(createTestNode(id: 'node-$i', zIndex: i));
      }

      final stopwatch = Stopwatch()..start();

      // Bring each node to front
      for (var i = 0; i < 100; i++) {
        controller.bringNodeToFront('node-$i');
      }

      stopwatch.stop();
      expect(
        stopwatch.elapsedMilliseconds,
        lessThan(100),
        reason: 'bringToFront 100 times should take less than 100ms',
      );
    });

    test('remove 500 nodes under 500ms', () {
      // Create nodes
      for (var i = 0; i < 500; i++) {
        controller.addNode(createTestNode(id: 'node-$i'));
      }

      expect(controller.nodeCount, equals(500));

      final stopwatch = Stopwatch()..start();

      // Remove all nodes
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
  });

  group('Large Graph - Selection Operations', () {
    test('selectAllNodes with 500 nodes under 50ms', () {
      // Create nodes
      for (var i = 0; i < 500; i++) {
        controller.addNode(createTestNode(id: 'node-$i'));
      }

      final stopwatch = Stopwatch()..start();

      controller.selectAllNodes();

      stopwatch.stop();
      expect(controller.selectedNodeIds.length, equals(500));
      expect(
        stopwatch.elapsedMilliseconds,
        lessThan(50),
        reason: 'selectAllNodes with 500 nodes should take less than 50ms',
      );
    });

    test('clearNodeSelection with 500 selected nodes under 50ms', () {
      // Create and select nodes
      for (var i = 0; i < 500; i++) {
        controller.addNode(createTestNode(id: 'node-$i'));
      }
      controller.selectAllNodes();
      expect(controller.selectedNodeIds.length, equals(500));

      final stopwatch = Stopwatch()..start();

      controller.clearNodeSelection();

      stopwatch.stop();
      expect(controller.selectedNodeIds.length, equals(0));
      expect(
        stopwatch.elapsedMilliseconds,
        lessThan(50),
        reason: 'clearNodeSelection with 500 nodes should take less than 50ms',
      );
    });

    test('selectNodes batch with 100 nodes under 50ms', () {
      // Create nodes
      for (var i = 0; i < 500; i++) {
        controller.addNode(createTestNode(id: 'node-$i'));
      }

      final nodeIds = List.generate(100, (i) => 'node-$i');

      final stopwatch = Stopwatch()..start();

      controller.selectNodes(nodeIds);

      stopwatch.stop();
      expect(controller.selectedNodeIds.length, equals(100));
      expect(
        stopwatch.elapsedMilliseconds,
        lessThan(50),
        reason: 'selectNodes with 100 IDs should take less than 50ms',
      );
    });
  });

  group('Large Graph - Query Operations', () {
    test('getVisibleNodes with 500 nodes under 20ms', () {
      // Create nodes spread across the viewport
      for (var i = 0; i < 500; i++) {
        controller.addNode(
          createTestNode(
            id: 'node-$i',
            position: Offset((i % 25) * 100.0, (i ~/ 25) * 80.0),
            size: const Size(80, 60),
          ),
        );
      }

      final stopwatch = Stopwatch()..start();

      final visibleNodes = controller.getVisibleNodes();

      stopwatch.stop();
      expect(visibleNodes, isNotEmpty);
      expect(
        stopwatch.elapsedMilliseconds,
        lessThan(20),
        reason: 'getVisibleNodes with 500 nodes should take less than 20ms',
      );
    });

    test('sortedNodes access with 500 nodes under 20ms', () {
      // Create nodes with varying z-indices
      for (var i = 0; i < 500; i++) {
        controller.addNode(createTestNode(id: 'node-$i', zIndex: i % 50));
      }

      final stopwatch = Stopwatch()..start();

      // Access sorted nodes multiple times
      for (var i = 0; i < 10; i++) {
        final sorted = controller.sortedNodes;
        expect(sorted.length, equals(500));
      }

      stopwatch.stop();
      expect(
        stopwatch.elapsedMilliseconds,
        lessThan(20),
        reason: 'Accessing sortedNodes 10 times should take less than 20ms',
      );
    });

    test('getConnectionsForNode with heavily connected node under 10ms', () {
      // Create a hub node with many connections
      controller.addNode(
        createTestNodeWithOutputPort(id: 'hub', portId: 'out'),
      );
      for (var i = 0; i < 100; i++) {
        controller.addNode(
          createTestNodeWithInputPort(id: 'spoke-$i', portId: 'in'),
        );
        controller.addConnection(
          createTestConnection(
            id: 'conn-$i',
            sourceNodeId: 'hub',
            sourcePortId: 'out',
            targetNodeId: 'spoke-$i',
            targetPortId: 'in',
          ),
        );
      }

      final stopwatch = Stopwatch()..start();

      // Query connections for hub node
      final connections = controller.getConnectionsForNode('hub');

      stopwatch.stop();
      expect(connections.length, equals(100));
      expect(
        stopwatch.elapsedMilliseconds,
        lessThan(10),
        reason: 'Getting 100 connections should take less than 10ms',
      );
    });
  });

  group('Large Graph - Graph Analysis', () {
    test('exportGraph with 500 nodes and connections under 100ms', () {
      // Create a complex graph
      for (var i = 0; i < 500; i++) {
        controller.addNode(createTestNodeWithPorts(id: 'node-$i'));
      }
      for (var i = 0; i < 499; i++) {
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

      final stopwatch = Stopwatch()..start();

      final graph = controller.exportGraph();

      stopwatch.stop();
      expect(graph.nodes.length, equals(500));
      expect(graph.connections.length, equals(499));
      expect(
        stopwatch.elapsedMilliseconds,
        lessThan(100),
        reason: 'exportGraph should take less than 100ms',
      );
    });

    test('detectCycles on acyclic graph with 500 nodes under 100ms', () {
      // Create a linear chain (no cycles)
      for (var i = 0; i < 500; i++) {
        controller.addNode(createTestNodeWithPorts(id: 'node-$i'));
      }
      for (var i = 0; i < 499; i++) {
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

      final stopwatch = Stopwatch()..start();

      final cycles = controller.detectCycles();

      stopwatch.stop();
      expect(cycles, isEmpty);
      expect(
        stopwatch.elapsedMilliseconds,
        lessThan(100),
        reason: 'detectCycles on 500 nodes should take less than 100ms',
      );
    });

    test('getBounds with 500 nodes under 20ms', () {
      // Create nodes spread across a large area
      for (var i = 0; i < 500; i++) {
        controller.addNode(
          createTestNode(
            id: 'node-$i',
            position: Offset((i % 25) * 400.0, (i ~/ 25) * 300.0),
            size: const Size(150, 100),
          ),
        );
      }

      final stopwatch = Stopwatch()..start();

      final graph = controller.exportGraph();
      final bounds = graph.getBounds();

      stopwatch.stop();
      expect(bounds, isNotNull);
      expect(bounds.width, greaterThan(0));
      expect(
        stopwatch.elapsedMilliseconds,
        lessThan(20),
        reason: 'getBounds with 500 nodes should take less than 20ms',
      );
    });
  });

  group('Large Graph - Mixed Operations', () {
    test('complex workflow simulation under 2 seconds', () {
      final stopwatch = Stopwatch()..start();

      // Phase 1: Create 200 nodes
      for (var i = 0; i < 200; i++) {
        controller.addNode(
          createTestNodeWithPorts(
            id: 'node-$i',
            position: Offset((i % 20) * 200.0, (i ~/ 20) * 150.0),
          ),
        );
      }

      // Phase 2: Create 300 connections
      for (var i = 0; i < 199; i++) {
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
      // Add some cross-connections
      for (var i = 0; i < 101; i++) {
        controller.addConnection(
          createTestConnection(
            id: 'cross-$i',
            sourceNodeId: 'node-$i',
            sourcePortId: 'output-1',
            targetNodeId: 'node-${i + 50}',
            targetPortId: 'input-1',
          ),
        );
      }

      // Phase 3: Move nodes
      for (var i = 0; i < 50; i++) {
        controller.moveNode('node-$i', const Offset(10, 10));
      }

      // Phase 4: Select and deselect
      controller.selectAllNodes();
      controller.clearNodeSelection();
      controller.selectNodes(List.generate(50, (i) => 'node-$i'));

      // Phase 5: Viewport operations
      controller.fitToView();
      for (var i = 0; i < 20; i++) {
        controller.panBy(ScreenOffset.fromXY(5, 5));
        controller.zoomBy(0.01);
      }

      // Phase 6: Query operations
      controller.getVisibleNodes();
      controller.detectCycles();
      controller.exportGraph();

      stopwatch.stop();

      expect(controller.nodeCount, equals(200));
      expect(controller.connectionCount, equals(300));
      expect(
        stopwatch.elapsedMilliseconds,
        lessThan(2000),
        reason: 'Complex workflow simulation should complete under 2 seconds',
      );
    });
  });

  group('Large Graph - Stress Test', () {
    test('1000 nodes with 2000 connections maintains performance', () {
      final stopwatch = Stopwatch()..start();

      // Create 1000 nodes
      for (var i = 0; i < 1000; i++) {
        controller.addNode(
          createTestNodeWithPorts(
            id: 'node-$i',
            position: Offset((i % 40) * 200.0, (i ~/ 40) * 150.0),
          ),
        );
      }

      // Create 2000 connections (each node connects to next 2)
      var connId = 0;
      for (var i = 0; i < 1000; i++) {
        for (var j = 1; j <= 2; j++) {
          if (i + j < 1000) {
            controller.addConnection(
              createTestConnection(
                id: 'conn-${connId++}',
                sourceNodeId: 'node-$i',
                sourcePortId: 'output-1',
                targetNodeId: 'node-${i + j}',
                targetPortId: 'input-1',
              ),
            );
          }
        }
      }

      stopwatch.stop();

      expect(controller.nodeCount, equals(1000));
      expect(controller.connectionCount, greaterThan(1000));
      expect(
        stopwatch.elapsedMilliseconds,
        lessThan(30000),
        reason: 'Creating 1000 nodes + 2000 connections should be under 30s',
      );

      // Verify operations still work quickly
      final queryStopwatch = Stopwatch()..start();

      controller.getVisibleNodes();
      controller.selectAllNodes();
      controller.clearNodeSelection();

      queryStopwatch.stop();
      expect(
        queryStopwatch.elapsedMilliseconds,
        lessThan(200),
        reason: 'Query operations on large graph should be under 200ms',
      );
    });
  });
}
