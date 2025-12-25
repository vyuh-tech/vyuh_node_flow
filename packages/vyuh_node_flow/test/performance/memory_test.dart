@Tags(['performance'])
library;

import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:vyuh_node_flow/vyuh_node_flow.dart';

import '../helpers/test_factories.dart';

/// Memory-related performance tests.
///
/// These tests verify that the library properly cleans up resources
/// and doesn't have memory leaks from repeated operations.
void main() {
  group('Memory - Controller Lifecycle', () {
    test('controller disposal cleans up resources', () {
      // Create and populate a controller
      final controller = createTestController();
      controller.setScreenSize(const Size(1920, 1080));

      for (var i = 0; i < 100; i++) {
        controller.addNode(createTestNodeWithPorts(id: 'node-$i'));
      }

      for (var i = 0; i < 99; i++) {
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

      for (var i = 0; i < 10; i++) {
        controller.addNode(
          createTestCommentNode<String>(data: '', id: 'comment-$i'),
        );
      }

      // 100 regular nodes + 10 CommentNodes = 110
      expect(controller.nodeCount, equals(110));
      expect(controller.connectionCount, equals(99));

      // Dispose should complete without error
      expect(() => controller.dispose(), returnsNormally);
    });

    test('multiple controller creations and disposals', () {
      // Verify no resource leaks from repeated controller lifecycle
      for (var i = 0; i < 10; i++) {
        resetTestCounters();
        final controller = createTestController();
        controller.setScreenSize(const Size(800, 600));

        for (var j = 0; j < 50; j++) {
          controller.addNode(createTestNode(id: 'node-$j'));
        }

        controller.dispose();
      }

      // If we get here without error, no obvious resource leaks
      expect(true, isTrue);
    });

    test('rapid controller creation/disposal cycles', () {
      final stopwatch = Stopwatch()..start();

      for (var i = 0; i < 100; i++) {
        resetTestCounters();
        final controller = createTestController();
        controller.setScreenSize(const Size(800, 600));

        controller.addNode(createTestNode(id: 'node-0'));
        controller.addNode(createTestNode(id: 'node-1'));

        controller.dispose();
      }

      stopwatch.stop();
      expect(
        stopwatch.elapsedMilliseconds,
        lessThan(2000),
        reason: '100 controller cycles should complete in under 2 seconds',
      );
    });
  });

  group('Memory - Graph Clearing', () {
    test('clearGraph properly releases node references', () {
      final controller = createTestController();
      controller.setScreenSize(const Size(800, 600));

      // Create a large graph
      for (var i = 0; i < 500; i++) {
        controller.addNode(createTestNode(id: 'node-$i'));
      }

      expect(controller.nodeCount, equals(500));

      // Clear the graph
      controller.clearGraph();

      expect(controller.nodeCount, equals(0));
      expect(controller.connectionCount, equals(0));

      // Should be able to add nodes with same IDs (references released)
      for (var i = 0; i < 100; i++) {
        controller.addNode(createTestNode(id: 'node-$i'));
      }

      expect(controller.nodeCount, equals(100));

      controller.dispose();
    });

    test('repeated clear cycles dont accumulate memory', () {
      final controller = createTestController();
      controller.setScreenSize(const Size(800, 600));

      final stopwatch = Stopwatch()..start();

      for (var cycle = 0; cycle < 10; cycle++) {
        // Add 200 nodes
        for (var i = 0; i < 200; i++) {
          controller.addNode(createTestNode(id: 'cycle-$cycle-node-$i'));
        }

        // Clear
        controller.clearGraph();
        expect(controller.nodeCount, equals(0));
      }

      stopwatch.stop();

      // Each cycle should be roughly the same speed
      expect(
        stopwatch.elapsedMilliseconds,
        lessThan(3000),
        reason: '10 clear cycles with 200 nodes each should be under 3s',
      );

      controller.dispose();
    });
  });

  group('Memory - Add/Remove Cycles', () {
    test('1000 add/remove cycles dont leak', () {
      final controller = createTestController();
      controller.setScreenSize(const Size(800, 600));

      final stopwatch = Stopwatch()..start();

      for (var i = 0; i < 1000; i++) {
        controller.addNode(createTestNode(id: 'temp-node'));
        controller.removeNode('temp-node');
      }

      stopwatch.stop();
      expect(controller.nodeCount, equals(0));
      expect(
        stopwatch.elapsedMilliseconds,
        lessThan(2000),
        reason: '1000 add/remove cycles should complete in under 2 seconds',
      );

      controller.dispose();
    });

    test('connection add/remove cycles dont leak', () {
      final controller = createTestController();
      controller.setScreenSize(const Size(800, 600));

      // Create persistent nodes
      controller.addNode(
        createTestNodeWithOutputPort(id: 'source', portId: 'out'),
      );
      controller.addNode(
        createTestNodeWithInputPort(id: 'target', portId: 'in'),
      );

      final stopwatch = Stopwatch()..start();

      for (var i = 0; i < 500; i++) {
        controller.addConnection(
          createTestConnection(
            id: 'temp-conn',
            sourceNodeId: 'source',
            sourcePortId: 'out',
            targetNodeId: 'target',
            targetPortId: 'in',
          ),
        );
        controller.removeConnection('temp-conn');
      }

      stopwatch.stop();
      expect(controller.connectionCount, equals(0));
      expect(
        stopwatch.elapsedMilliseconds,
        lessThan(1000),
        reason: '500 connection add/remove cycles should be under 1 second',
      );

      controller.dispose();
    });

    test('CommentNode add/remove cycles dont leak', () {
      final controller = createTestController();
      controller.setScreenSize(const Size(800, 600));

      final stopwatch = Stopwatch()..start();

      for (var i = 0; i < 500; i++) {
        controller.addNode(
          createTestCommentNode<String>(data: '', id: 'temp-comment'),
        );
        controller.removeNode('temp-comment');
      }

      stopwatch.stop();
      expect(controller.nodeCount, equals(0));
      expect(
        stopwatch.elapsedMilliseconds,
        lessThan(1000),
        reason: '500 CommentNode add/remove cycles should be under 1 second',
      );

      controller.dispose();
    });
  });

  group('Memory - Selection State', () {
    test('selection changes dont accumulate', () {
      final controller = createTestController();
      controller.setScreenSize(const Size(800, 600));

      // Create nodes
      for (var i = 0; i < 100; i++) {
        controller.addNode(createTestNode(id: 'node-$i'));
      }

      final stopwatch = Stopwatch()..start();

      // Rapidly change selection many times
      for (var i = 0; i < 1000; i++) {
        controller.selectNode('node-${i % 100}');
      }

      stopwatch.stop();
      expect(
        stopwatch.elapsedMilliseconds,
        lessThan(500),
        reason: '1000 selection changes should be under 500ms',
      );

      controller.dispose();
    });

    test('selectAll/clear cycles dont accumulate', () {
      final controller = createTestController();
      controller.setScreenSize(const Size(800, 600));

      // Create nodes
      for (var i = 0; i < 200; i++) {
        controller.addNode(createTestNode(id: 'node-$i'));
      }

      final stopwatch = Stopwatch()..start();

      for (var i = 0; i < 100; i++) {
        controller.selectAllNodes();
        controller.clearNodeSelection();
      }

      stopwatch.stop();
      expect(
        stopwatch.elapsedMilliseconds,
        lessThan(500),
        reason: '100 selectAll/clear cycles should be under 500ms',
      );

      controller.dispose();
    });
  });

  group('Memory - Viewport State', () {
    test('viewport changes dont accumulate state', () {
      final controller = createTestController();
      controller.setScreenSize(const Size(800, 600));

      controller.addNode(createTestNode(id: 'node-1'));

      final stopwatch = Stopwatch()..start();

      // Perform many viewport operations
      for (var i = 0; i < 10000; i++) {
        controller.panBy(ScreenOffset.fromXY(1, 1));
        controller.zoomBy((i % 2 == 0) ? 0.001 : -0.001);
      }

      stopwatch.stop();
      expect(
        stopwatch.elapsedMilliseconds,
        lessThan(1000),
        reason: '10000 viewport operations should be under 1 second',
      );

      controller.dispose();
    });
  });

  group('Memory - Observable Cleanup', () {
    test('node removal cleans up observables', () {
      final controller = createTestController();
      controller.setScreenSize(const Size(800, 600));

      // Create node and modify its observables
      controller.addNode(createTestNode(id: 'test-node'));
      expect(controller.getNode('test-node'), isNotNull);

      // Trigger some observable updates
      for (var i = 0; i < 100; i++) {
        controller.moveNode('test-node', const Offset(1, 1));
        controller.setNodeSize('test-node', Size(100.0 + i, 80.0 + i));
      }

      // Remove the node
      controller.removeNode('test-node');
      expect(controller.getNode('test-node'), isNull);

      // Verify the node is no longer tracked
      expect(controller.nodeCount, equals(0));

      // Should be able to create new node with same ID
      controller.addNode(createTestNode(id: 'test-node'));
      expect(controller.nodeCount, equals(1));

      controller.dispose();
    });
  });

  group('Memory - Graph Loading', () {
    test('loadGraph properly replaces previous state', () {
      final controller = createTestController();
      controller.setScreenSize(const Size(800, 600));

      // Initial state
      for (var i = 0; i < 100; i++) {
        controller.addNode(createTestNode(id: 'old-$i'));
      }

      expect(controller.nodeCount, equals(100));

      // Load new graph
      final newNodes = List.generate(50, (i) => createTestNode(id: 'new-$i'));
      final newGraph = NodeGraph<String>(nodes: newNodes, connections: []);

      controller.loadGraph(newGraph);

      expect(controller.nodeCount, equals(50));

      // Old nodes should not be accessible
      expect(controller.getNode('old-0'), isNull);
      expect(controller.getNode('new-0'), isNotNull);

      controller.dispose();
    });

    test('repeated loadGraph cycles dont leak', () {
      final controller = createTestController();
      controller.setScreenSize(const Size(800, 600));

      final stopwatch = Stopwatch()..start();

      for (var cycle = 0; cycle < 20; cycle++) {
        final nodes = List.generate(
          50,
          (i) => createTestNode(id: 'cycle-$cycle-node-$i'),
        );
        final graph = NodeGraph<String>(nodes: nodes, connections: []);

        controller.loadGraph(graph);
        expect(controller.nodeCount, equals(50));
      }

      stopwatch.stop();
      expect(
        stopwatch.elapsedMilliseconds,
        lessThan(2000),
        reason: '20 loadGraph cycles should be under 2 seconds',
      );

      controller.dispose();
    });
  });

  group('Memory - Large Graph Handling', () {
    test('large graph with connections can be cleared', () {
      final controller = createTestController();
      controller.setScreenSize(const Size(1920, 1080));

      // Create large graph
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

      expect(controller.nodeCount, equals(500));
      expect(controller.connectionCount, equals(499));

      final stopwatch = Stopwatch()..start();
      controller.clearGraph();
      stopwatch.stop();

      expect(controller.nodeCount, equals(0));
      expect(controller.connectionCount, equals(0));
      expect(
        stopwatch.elapsedMilliseconds,
        lessThan(500),
        reason: 'Clearing 500 nodes + 499 connections should be under 500ms',
      );

      controller.dispose();
    });

    test('operations after large clear are still fast', () {
      final controller = createTestController();
      controller.setScreenSize(const Size(1920, 1080));

      // Create large graph
      for (var i = 0; i < 500; i++) {
        controller.addNode(createTestNode(id: 'node-$i'));
      }

      controller.clearGraph();

      // Operations after clear should be fast
      final stopwatch = Stopwatch()..start();

      for (var i = 0; i < 100; i++) {
        controller.addNode(createTestNode(id: 'new-$i'));
      }

      stopwatch.stop();
      expect(controller.nodeCount, equals(100));
      expect(
        stopwatch.elapsedMilliseconds,
        lessThan(100),
        reason: 'Adding 100 nodes after clear should be under 100ms',
      );

      controller.dispose();
    });
  });

  group('Memory - Stability Tests', () {
    test('mixed operations over extended period', () {
      final controller = createTestController();
      controller.setScreenSize(const Size(1920, 1080));

      final stopwatch = Stopwatch()..start();

      // Simulate an extended editing session
      for (var round = 0; round < 5; round++) {
        // Add nodes
        for (var i = 0; i < 50; i++) {
          controller.addNode(
            createTestNodeWithPorts(id: 'round-$round-node-$i'),
          );
        }

        // Add connections
        for (var i = 0; i < 49; i++) {
          controller.addConnection(
            createTestConnection(
              id: 'round-$round-conn-$i',
              sourceNodeId: 'round-$round-node-$i',
              sourcePortId: 'output-1',
              targetNodeId: 'round-$round-node-${i + 1}',
              targetPortId: 'input-1',
            ),
          );
        }

        // Add CommentNodes
        for (var i = 0; i < 5; i++) {
          controller.addNode(
            createTestCommentNode<String>(
              data: '',
              id: 'round-$round-comment-$i',
            ),
          );
        }

        // Selection operations
        controller.selectAllNodes();
        controller.clearNodeSelection();

        // Viewport operations
        for (var i = 0; i < 10; i++) {
          controller.panBy(ScreenOffset.fromXY(5, 5));
          controller.zoomBy(0.01);
        }

        // Query operations
        controller.getVisibleNodes();
        controller.detectCycles();

        // Remove some nodes (cascades to connections)
        for (var i = 0; i < 20; i++) {
          controller.removeNode('round-$round-node-$i');
        }
      }

      stopwatch.stop();

      // Verify final state is consistent
      // 50 regular nodes - 20 removed = 30, plus 5 CommentNodes = 35 per round × 5 = 175
      expect(controller.nodeCount, equals((50 - 20 + 5) * 5));
      expect(
        stopwatch.elapsedMilliseconds,
        lessThan(5000),
        reason: 'Extended editing simulation should be under 5 seconds',
      );

      controller.dispose();
    });
  });
}
