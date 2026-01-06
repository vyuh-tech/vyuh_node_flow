/// Unit tests for EditorInitApi extension.
///
/// Tests cover:
/// - initController idempotency (multiple calls)
/// - initController with nodeShapeBuilder
/// - initController with connectionHitTesterBuilder
/// - initController with events
/// - updateTheme before initialization (throws error)
/// - updateTheme after initialization
/// - updateEvents
/// - updateNodeShapeBuilder
/// - Initialization of loaded nodes with GroupableMixin
/// - Spatial index rebuild with connection segment calculator
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
  // Basic Initialization
  // ===========================================================================

  group('initController - Basic', () {
    test('sets isEditorInitialized to true after initialization', () {
      final controller = createTestController();
      expect(controller.isEditorInitialized, isFalse);

      controller.initController(
        theme: NodeFlowTheme.light,
        portSizeResolver: (port) => const Size(10, 10),
      );

      expect(controller.isEditorInitialized, isTrue);
    });

    test('sets theme after initialization', () {
      final controller = createTestController();
      expect(controller.theme, isNull);

      controller.initController(
        theme: NodeFlowTheme.light,
        portSizeResolver: (port) => const Size(10, 10),
      );

      expect(controller.theme, isNotNull);
      expect(controller.theme, equals(NodeFlowTheme.light));
    });

    test('initializes connection painter after initialization', () {
      final controller = createTestController();
      expect(controller.isConnectionPainterInitialized, isFalse);

      controller.initController(
        theme: NodeFlowTheme.light,
        portSizeResolver: (port) => const Size(10, 10),
      );

      expect(controller.isConnectionPainterInitialized, isTrue);
    });
  });

  // ===========================================================================
  // Idempotency
  // ===========================================================================

  group('initController - Idempotency', () {
    test('calling initController multiple times only initializes once', () {
      final controller = createTestController();

      // First initialization
      controller.initController(
        theme: NodeFlowTheme.light,
        portSizeResolver: (port) => const Size(10, 10),
      );

      final originalTheme = controller.theme;
      expect(controller.isEditorInitialized, isTrue);

      // Second initialization attempt with different theme
      controller.initController(
        theme: NodeFlowTheme.dark,
        portSizeResolver: (port) => const Size(20, 20),
      );

      // Theme should remain the same from first initialization
      expect(controller.theme, equals(originalTheme));
    });

    test('isEditorInitialized remains true after multiple init attempts', () {
      final controller = createTestController();

      controller.initController(
        theme: NodeFlowTheme.light,
        portSizeResolver: (port) => const Size(10, 10),
      );

      expect(controller.isEditorInitialized, isTrue);

      // Second call
      controller.initController(
        theme: NodeFlowTheme.dark,
        portSizeResolver: (port) => const Size(10, 10),
      );

      expect(controller.isEditorInitialized, isTrue);

      // Third call
      controller.initController(
        theme: NodeFlowTheme.light,
        portSizeResolver: (port) => const Size(10, 10),
      );

      expect(controller.isEditorInitialized, isTrue);
    });
  });

  // ===========================================================================
  // Node Shape Builder
  // ===========================================================================

  group('initController - Node Shape Builder', () {
    test('initializes with custom node shape builder', () {
      final controller = createTestController();
      var shapeBuilderCalled = false;

      controller.initController(
        theme: NodeFlowTheme.light,
        portSizeResolver: (port) => const Size(10, 10),
        nodeShapeBuilder: (node) {
          shapeBuilderCalled = true;
          return null;
        },
      );

      expect(controller.isEditorInitialized, isTrue);
      expect(controller.nodeShapeBuilder, isNotNull);

      // Call the builder to verify it's set
      controller.nodeShapeBuilder!(createTestNode());
      expect(shapeBuilderCalled, isTrue);
    });

    test('node shape builder is passed to connection painter', () {
      final controller = createTestController();
      final node = createTestNode(id: 'test-node');
      controller.addNode(node);

      controller.initController(
        theme: NodeFlowTheme.light,
        portSizeResolver: (port) => const Size(10, 10),
        nodeShapeBuilder: (node) {
          // Return a diamond shape for testing
          return const DiamondShape();
        },
      );

      expect(controller.isConnectionPainterInitialized, isTrue);
      // Connection painter is initialized with the node shape builder
      expect(controller.connectionPainter, isNotNull);
    });

    test('null node shape builder works correctly', () {
      final controller = createTestController();

      controller.initController(
        theme: NodeFlowTheme.light,
        portSizeResolver: (port) => const Size(10, 10),
        nodeShapeBuilder: null,
      );

      expect(controller.isEditorInitialized, isTrue);
      expect(controller.nodeShapeBuilder, isNull);
    });
  });

  // ===========================================================================
  // Connection Hit Tester Builder
  // ===========================================================================

  group('initController - Connection Hit Tester Builder', () {
    test('initializes with connection hit tester builder', () {
      final controller = createTestController();
      var hitTesterBuilderCalled = false;

      controller.initController(
        theme: NodeFlowTheme.light,
        portSizeResolver: (port) => const Size(10, 10),
        connectionHitTesterBuilder: (painter) {
          hitTesterBuilderCalled = true;
          return (connection, point) => false;
        },
      );

      expect(controller.isEditorInitialized, isTrue);
      expect(hitTesterBuilderCalled, isTrue);
    });

    test(
      'connection hit tester builder receives painter and returns function',
      () {
        final controller = createTestController();
        var receivedPainterWasNotNull = false;

        controller.initController(
          theme: NodeFlowTheme.light,
          portSizeResolver: (port) => const Size(10, 10),
          connectionHitTesterBuilder: (painter) {
            receivedPainterWasNotNull = painter != null;
            return (connection, point) => false;
          },
        );

        expect(receivedPainterWasNotNull, isTrue);
      },
    );

    test('null connection hit tester builder works correctly', () {
      final controller = createTestController();

      controller.initController(
        theme: NodeFlowTheme.light,
        portSizeResolver: (port) => const Size(10, 10),
        connectionHitTesterBuilder: null,
      );

      expect(controller.isEditorInitialized, isTrue);
    });
  });

  // ===========================================================================
  // Connection Segment Calculator
  // ===========================================================================

  group('initController - Connection Segment Calculator', () {
    test('initializes with connection segment calculator', () {
      final controller = createTestController();
      var segmentCalculatorCalled = false;

      // Add nodes and a connection
      final nodeA = createTestNodeWithOutputPort(id: 'node-a');
      final nodeB = createTestNodeWithInputPort(id: 'node-b');
      controller.addNode(nodeA);
      controller.addNode(nodeB);
      controller.createConnection('node-a', 'output-1', 'node-b', 'input-1');

      controller.initController(
        theme: NodeFlowTheme.light,
        portSizeResolver: (port) => const Size(10, 10),
        connectionSegmentCalculator: (connection) {
          segmentCalculatorCalled = true;
          return [const Rect.fromLTWH(0, 0, 100, 100)];
        },
      );

      expect(controller.isEditorInitialized, isTrue);
      // The segment calculator is called during spatial index rebuild
      expect(segmentCalculatorCalled, isTrue);
    });

    test('null connection segment calculator skips segment rebuild', () {
      final controller = createTestController();

      // Add nodes and a connection
      final nodeA = createTestNodeWithOutputPort(id: 'node-a');
      final nodeB = createTestNodeWithInputPort(id: 'node-b');
      controller.addNode(nodeA);
      controller.addNode(nodeB);
      controller.createConnection('node-a', 'output-1', 'node-b', 'input-1');

      controller.initController(
        theme: NodeFlowTheme.light,
        portSizeResolver: (port) => const Size(10, 10),
        connectionSegmentCalculator: null,
      );

      expect(controller.isEditorInitialized, isTrue);
    });
  });

  // ===========================================================================
  // Events
  // ===========================================================================

  group('initController - Events', () {
    test('initializes with events', () {
      final controller = createTestController();

      final events = NodeFlowEvents<String, dynamic>(
        node: NodeEvents<String>(onTap: (node) {}),
      );

      controller.initController(
        theme: NodeFlowTheme.light,
        portSizeResolver: (port) => const Size(10, 10),
        events: events,
      );

      expect(controller.isEditorInitialized, isTrue);
      expect(controller.events, equals(events));
    });

    test('null events uses default empty events', () {
      final controller = createTestController();

      controller.initController(
        theme: NodeFlowTheme.light,
        portSizeResolver: (port) => const Size(10, 10),
        events: null,
      );

      expect(controller.isEditorInitialized, isTrue);
      // Default events should be set
      expect(controller.events, isNotNull);
    });
  });

  // ===========================================================================
  // Update Theme
  // ===========================================================================

  group('updateTheme', () {
    test('throws StateError when called before initialization', () {
      final controller = createTestController();

      expect(
        () => controller.updateTheme(NodeFlowTheme.dark),
        throwsA(isA<StateError>()),
      );
    });

    test(
      'throws StateError with descriptive message before initialization',
      () {
        final controller = createTestController();

        expect(
          () => controller.updateTheme(NodeFlowTheme.dark),
          throwsA(
            predicate(
              (e) =>
                  e is StateError &&
                  e.message.contains('Cannot update theme before controller'),
            ),
          ),
        );
      },
    );

    test('updates theme after initialization', () {
      final controller = createTestController();

      controller.initController(
        theme: NodeFlowTheme.light,
        portSizeResolver: (port) => const Size(10, 10),
      );

      expect(controller.theme, equals(NodeFlowTheme.light));

      controller.updateTheme(NodeFlowTheme.dark);

      expect(controller.theme, equals(NodeFlowTheme.dark));
    });

    test('updates connection painter theme', () {
      final controller = createTestController();

      controller.initController(
        theme: NodeFlowTheme.light,
        portSizeResolver: (port) => const Size(10, 10),
      );

      final originalPainter = controller.connectionPainter;

      controller.updateTheme(NodeFlowTheme.dark);

      // Painter should still be the same instance but with updated theme
      expect(controller.connectionPainter, equals(originalPainter));
    });
  });

  // ===========================================================================
  // Update Events
  // ===========================================================================

  group('updateEvents', () {
    test('updates events on initialized controller', () {
      final controller = createTestController();

      controller.initController(
        theme: NodeFlowTheme.light,
        portSizeResolver: (port) => const Size(10, 10),
      );

      final newEvents = NodeFlowEvents<String, dynamic>(
        node: NodeEvents<String>(onTap: (node) {}),
      );

      controller.updateEvents(newEvents);

      expect(controller.events, equals(newEvents));
    });

    test('can update events multiple times', () {
      final controller = createTestController();

      controller.initController(
        theme: NodeFlowTheme.light,
        portSizeResolver: (port) => const Size(10, 10),
      );

      final events1 = NodeFlowEvents<String, dynamic>(
        node: NodeEvents<String>(onTap: (node) {}),
      );

      final events2 = NodeFlowEvents<String, dynamic>(
        node: NodeEvents<String>(onDoubleTap: (node) {}),
      );

      controller.updateEvents(events1);
      expect(controller.events, equals(events1));

      controller.updateEvents(events2);
      expect(controller.events, equals(events2));
    });
  });

  // ===========================================================================
  // Update Node Shape Builder
  // ===========================================================================

  group('updateNodeShapeBuilder', () {
    test('updates node shape builder on initialized controller', () {
      final controller = createTestController();

      controller.initController(
        theme: NodeFlowTheme.light,
        portSizeResolver: (port) => const Size(10, 10),
      );

      expect(controller.nodeShapeBuilder, isNull);

      controller.updateNodeShapeBuilder((node) => const DiamondShape());

      expect(controller.nodeShapeBuilder, isNotNull);
    });

    test('can set node shape builder to null', () {
      final controller = createTestController();

      controller.initController(
        theme: NodeFlowTheme.light,
        portSizeResolver: (port) => const Size(10, 10),
        nodeShapeBuilder: (node) => const DiamondShape(),
      );

      expect(controller.nodeShapeBuilder, isNotNull);

      controller.updateNodeShapeBuilder(null);

      expect(controller.nodeShapeBuilder, isNull);
    });

    test('updates spatial index callback', () {
      final controller = createTestController();

      controller.initController(
        theme: NodeFlowTheme.light,
        portSizeResolver: (port) => const Size(10, 10),
      );

      // Initially null
      expect(controller.spatialIndex.nodeShapeBuilder, isNull);

      controller.updateNodeShapeBuilder((node) => const DiamondShape());

      // After update, spatial index should have the builder
      expect(controller.spatialIndex.nodeShapeBuilder, isNotNull);
    });
  });

  // ===========================================================================
  // Initialization with Pre-Loaded Nodes
  // ===========================================================================

  group('initController - Pre-Loaded Nodes', () {
    test('initializes nodes that were added before initialization', () {
      final controller = createTestController();

      // Add nodes before initialization
      final node1 = createTestNode(
        id: 'node-1',
        position: const Offset(100, 200),
      );
      final node2 = createTestNode(
        id: 'node-2',
        position: const Offset(300, 400),
      );
      controller.addNode(node1);
      controller.addNode(node2);

      controller.initController(
        theme: NodeFlowTheme.light,
        portSizeResolver: (port) => const Size(10, 10),
      );

      // Visual positions should be set
      expect(node1.visualPosition.value, isNotNull);
      expect(node2.visualPosition.value, isNotNull);
    });

    test('applies grid snapping to pre-loaded nodes', () {
      final controller = NodeFlowController<String, dynamic>(
        config: NodeFlowConfig(snapToGrid: true, gridSize: 20),
      );

      // Add node at non-grid-aligned position
      final node = createTestNode(
        id: 'node-1',
        position: const Offset(105, 215),
      );
      controller.addNode(node);

      controller.initController(
        theme: NodeFlowTheme.light,
        portSizeResolver: (port) => const Size(10, 10),
      );

      // Visual position should be snapped to grid
      expect(node.visualPosition.value.dx % 20, equals(0));
      expect(node.visualPosition.value.dy % 20, equals(0));
    });

    test('attaches context to GroupNode during initialization', () {
      final controller = createTestController();

      // Add a GroupNode before initialization
      final groupNode = createTestGroupNode<String>(
        id: 'group-1',
        data: 'group-data',
        behavior: GroupBehavior.bounds,
      );
      controller.addNode(groupNode);

      controller.initController(
        theme: NodeFlowTheme.light,
        portSizeResolver: (port) => const Size(10, 10),
      );

      // GroupNode should have context attached (it's a GroupableMixin)
      // We can verify this by checking that the group can still function
      expect(controller.getNode('group-1'), isNotNull);
      expect(controller.getNode('group-1'), isA<GroupNode<String>>());
    });

    test('initializes connections along with nodes', () {
      // Create controller with pre-loaded nodes and connections via constructor
      final nodeA = createTestNodeWithOutputPort(id: 'node-a');
      final nodeB = createTestNodeWithInputPort(id: 'node-b');
      final connection = createTestConnection(
        sourceNodeId: 'node-a',
        targetNodeId: 'node-b',
      );

      final controller = NodeFlowController<String, dynamic>(
        nodes: [nodeA, nodeB],
        connections: [connection],
      );

      controller.initController(
        theme: NodeFlowTheme.light,
        portSizeResolver: (port) => const Size(10, 10),
      );

      expect(controller.nodeCount, equals(2));
      expect(controller.connectionCount, equals(1));
    });
  });

  // ===========================================================================
  // Spatial Index Setup
  // ===========================================================================

  group('initController - Spatial Index', () {
    test('sets port size resolver on spatial index', () {
      final controller = createTestController();

      controller.initController(
        theme: NodeFlowTheme.light,
        portSizeResolver: (port) => const Size(15, 15),
      );

      expect(controller.spatialIndex.portSizeResolver, isNotNull);
    });

    test('sets node shape builder on spatial index', () {
      final controller = createTestController();

      controller.initController(
        theme: NodeFlowTheme.light,
        portSizeResolver: (port) => const Size(10, 10),
        nodeShapeBuilder: (node) => const CircleShape(),
      );

      expect(controller.spatialIndex.nodeShapeBuilder, isNotNull);
    });

    test('rebuilds spatial index during initialization', () {
      final controller = createTestController();

      // Add nodes before initialization
      final node1 = createTestNode(
        id: 'node-1',
        position: const Offset(0, 0),
        size: const Size(100, 50),
      );
      final node2 = createTestNode(
        id: 'node-2',
        position: const Offset(200, 0),
        size: const Size(100, 50),
      );
      controller.addNode(node1);
      controller.addNode(node2);

      controller.initController(
        theme: NodeFlowTheme.light,
        portSizeResolver: (port) => const Size(10, 10),
      );

      // Spatial index should be queryable
      final nodesInRect = controller.spatialIndex.nodesIn(
        const Rect.fromLTWH(-10, -10, 400, 100),
      );
      expect(nodesInRect.length, equals(2));
    });
  });

  // ===========================================================================
  // Edge Cases
  // ===========================================================================

  group('initController - Edge Cases', () {
    test('works with empty controller', () {
      final controller = createTestController();

      controller.initController(
        theme: NodeFlowTheme.light,
        portSizeResolver: (port) => const Size(10, 10),
      );

      expect(controller.isEditorInitialized, isTrue);
      expect(controller.nodeCount, equals(0));
      expect(controller.connectionCount, equals(0));
    });

    test('all initialization parameters are set correctly', () {
      final controller = createTestController();
      var shapeBuilderCalled = false;
      var hitTesterCalled = false;
      var segmentCalculatorCalled = false;

      final events = NodeFlowEvents<String, dynamic>(
        node: NodeEvents<String>(onTap: (node) {}),
      );

      // Add a connection to trigger segment calculator
      final nodeA = createTestNodeWithOutputPort(id: 'node-a');
      final nodeB = createTestNodeWithInputPort(id: 'node-b');
      controller.addNode(nodeA);
      controller.addNode(nodeB);
      controller.createConnection('node-a', 'output-1', 'node-b', 'input-1');

      controller.initController(
        theme: NodeFlowTheme.light,
        portSizeResolver: (port) => const Size(10, 10),
        nodeShapeBuilder: (node) {
          shapeBuilderCalled = true;
          return null;
        },
        connectionHitTesterBuilder: (painter) {
          hitTesterCalled = true;
          return (connection, point) => false;
        },
        connectionSegmentCalculator: (connection) {
          segmentCalculatorCalled = true;
          return [];
        },
        events: events,
      );

      expect(controller.isEditorInitialized, isTrue);
      expect(controller.theme, equals(NodeFlowTheme.light));
      expect(controller.events, equals(events));
      expect(hitTesterCalled, isTrue);
      expect(segmentCalculatorCalled, isTrue);
    });

    test('dispose cleans up after initialization', () {
      final controller = createTestController();

      controller.initController(
        theme: NodeFlowTheme.light,
        portSizeResolver: (port) => const Size(10, 10),
      );

      expect(controller.isEditorInitialized, isTrue);

      // Dispose should not throw
      expect(() => controller.dispose(), returnsNormally);
    });
  });
}
