/// Tests that verify GraphEvents are actually emitted by controller operations.
///
/// These tests ensure that the extension event system is properly integrated
/// with the controller API methods.
@Tags(['unit'])
library;

import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:vyuh_node_flow/vyuh_node_flow.dart';

import '../../helpers/test_factories.dart';

/// Test extension that captures events for verification.
class EventCaptureExtension extends NodeFlowExtension {
  @override
  String get id => 'event-capture';

  final List<GraphEvent> capturedEvents = [];

  @override
  void attach(NodeFlowController controller) {}

  @override
  void detach() {}

  @override
  void onEvent(GraphEvent event) {
    capturedEvents.add(event);
  }

  void clear() => capturedEvents.clear();

  List<T> eventsOfType<T extends GraphEvent>() =>
      capturedEvents.whereType<T>().toList();
}

void main() {
  late NodeFlowController<String, dynamic> controller;
  late EventCaptureExtension captureExtension;

  setUp(() {
    resetTestCounters();
    captureExtension = EventCaptureExtension();
    controller = createTestController();
    controller.addExtension(captureExtension);
  });

  tearDown(() {
    controller.dispose();
  });

  // ===========================================================================
  // Node Drag Event Emission
  // ===========================================================================
  group('Node Drag Event Emission', () {
    test('emits NodeDragStarted when drag starts', () {
      final node = createTestNode(
        id: 'node1',
        position: const Offset(100, 100),
      );
      controller.addNode(node);

      controller.startNodeDrag('node1');

      final events = captureExtension.eventsOfType<NodeDragStarted>();
      expect(events.length, equals(1));
      expect(events.first.nodeIds, contains('node1'));
    });

    test('NodeDragStarted includes all selected nodes in multi-drag', () {
      final node1 = createTestNode(id: 'node1');
      final node2 = createTestNode(id: 'node2');
      controller.addNode(node1);
      controller.addNode(node2);

      // Select both nodes
      controller.selectNode('node1');
      controller.selectNode('node2', toggle: true);

      controller.startNodeDrag('node1');

      final events = captureExtension.eventsOfType<NodeDragStarted>();
      expect(events.length, equals(1));
      expect(events.first.nodeIds, containsAll(['node1', 'node2']));
    });

    test('emits NodeDragEnded when drag ends', () {
      final node = createTestNode(
        id: 'node1',
        position: const Offset(100, 100),
      );
      controller.addNode(node);

      controller.startNodeDrag('node1');
      controller.moveNodeDrag(const Offset(50, 50));
      captureExtension.clear(); // Clear previous events

      controller.endNodeDrag();

      final events = captureExtension.eventsOfType<NodeDragEnded>();
      expect(events.length, equals(1));
      expect(events.first.nodeIds, contains('node1'));
    });

    test('NodeDragEnded includes original positions for undo', () {
      final node = createTestNode(
        id: 'node1',
        position: const Offset(100, 100),
      );
      controller.addNode(node);

      controller.startNodeDrag('node1');
      controller.moveNodeDrag(const Offset(50, 50));
      captureExtension.clear();

      controller.endNodeDrag();

      final events = captureExtension.eventsOfType<NodeDragEnded>();
      expect(events.length, equals(1));
      expect(
        events.first.originalPositions['node1'],
        equals(const Offset(100, 100)),
      );
    });

    test('NodeDragEnded includes all original positions in multi-drag', () {
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

      controller.startNodeDrag('node1');
      controller.moveNodeDrag(const Offset(50, 50));
      captureExtension.clear();

      controller.endNodeDrag();

      final events = captureExtension.eventsOfType<NodeDragEnded>();
      expect(events.length, equals(1));
      expect(
        events.first.originalPositions['node1'],
        equals(const Offset(100, 100)),
      );
      expect(
        events.first.originalPositions['node2'],
        equals(const Offset(200, 200)),
      );
    });

    test('drag sequence emits both start and end events', () {
      final node = createTestNode(id: 'node1', position: Offset.zero);
      controller.addNode(node);

      controller.startNodeDrag('node1');
      controller.moveNodeDrag(const Offset(100, 100));
      controller.endNodeDrag();

      final startEvents = captureExtension.eventsOfType<NodeDragStarted>();
      final endEvents = captureExtension.eventsOfType<NodeDragEnded>();

      expect(startEvents.length, equals(1));
      expect(endEvents.length, equals(1));
    });

    test('no NodeDragEnded emitted if no nodes are dragged', () {
      // End drag without starting
      controller.endNodeDrag();

      final events = captureExtension.eventsOfType<NodeDragEnded>();
      expect(events, isEmpty);
    });
  });

  // ===========================================================================
  // Node Resize Event Emission
  // ===========================================================================
  group('Node Resize Event Emission', () {
    test('emits ResizeStarted when resize starts', () {
      // Use GroupNode which is resizable
      final node = createTestGroupNode<String>(
        id: 'group1',
        position: Offset.zero,
        size: const Size(200, 150),
        data: 'test',
      );
      controller.addNode(node);

      controller.startResize(
        'group1',
        ResizeHandle.bottomRight,
        const Offset(200, 150),
      );

      final events = captureExtension.eventsOfType<ResizeStarted>();
      expect(events.length, equals(1));
      expect(events.first.nodeId, equals('group1'));
      expect(events.first.initialSize, equals(const Size(200, 150)));
    });

    test('emits ResizeEnded when resize ends', () {
      final node = createTestGroupNode<String>(
        id: 'group1',
        position: Offset.zero,
        size: const Size(200, 150),
        data: 'test',
      );
      controller.addNode(node);

      controller.startResize(
        'group1',
        ResizeHandle.bottomRight,
        const Offset(200, 150),
      );
      controller.updateResize(const Offset(250, 200));
      captureExtension.clear();

      controller.endResize();

      final events = captureExtension.eventsOfType<ResizeEnded>();
      expect(events.length, equals(1));
      expect(events.first.nodeId, equals('group1'));
    });

    test('ResizeEnded includes initial and final sizes', () {
      final node = createTestGroupNode<String>(
        id: 'group1',
        position: Offset.zero,
        size: const Size(200, 150),
        data: 'test',
      );
      controller.addNode(node);

      controller.startResize(
        'group1',
        ResizeHandle.bottomRight,
        const Offset(200, 150),
      );
      controller.updateResize(const Offset(250, 200));
      captureExtension.clear();

      controller.endResize();

      final events = captureExtension.eventsOfType<ResizeEnded>();
      expect(events.length, equals(1));
      expect(events.first.initialSize, equals(const Size(200, 150)));
      // Final size depends on resize logic, just verify it's different
      expect(events.first.finalSize, isNot(equals(const Size(200, 150))));
    });

    test('resize sequence emits both start and end events', () {
      final node = createTestGroupNode<String>(
        id: 'group1',
        position: Offset.zero,
        size: const Size(200, 150),
        data: 'test',
      );
      controller.addNode(node);

      controller.startResize(
        'group1',
        ResizeHandle.bottomRight,
        const Offset(200, 150),
      );
      controller.updateResize(const Offset(250, 200));
      controller.endResize();

      final startEvents = captureExtension.eventsOfType<ResizeStarted>();
      final endEvents = captureExtension.eventsOfType<ResizeEnded>();

      expect(startEvents.length, equals(1));
      expect(endEvents.length, equals(1));
    });
  });

  // ===========================================================================
  // Node Add/Remove Event Emission
  // ===========================================================================
  group('Node Add/Remove Event Emission', () {
    test('emits NodeAdded when node is added', () {
      final node = createTestNode(id: 'node1');

      controller.addNode(node);

      final events = captureExtension.eventsOfType<NodeAdded>();
      expect(events.length, equals(1));
      expect(events.first.node.id, equals('node1'));
    });

    test('emits NodeRemoved when node is removed', () {
      final node = createTestNode(id: 'node1');
      controller.addNode(node);
      captureExtension.clear();

      controller.removeNode('node1');

      final events = captureExtension.eventsOfType<NodeRemoved>();
      expect(events.length, equals(1));
      expect(events.first.node.id, equals('node1'));
    });
  });

  // ===========================================================================
  // Connection Event Emission
  // ===========================================================================
  group('Connection Event Emission', () {
    test('emits ConnectionAdded when connection is created', () {
      final source = createTestNodeWithOutputPort(id: 'source', portId: 'out1');
      final target = createTestNodeWithInputPort(
        id: 'target',
        portId: 'in1',
        position: const Offset(200, 0),
      );
      controller.addNode(source);
      controller.addNode(target);
      captureExtension.clear();

      final connection = createTestConnection(
        sourceNodeId: 'source',
        sourcePortId: 'out1',
        targetNodeId: 'target',
        targetPortId: 'in1',
      );
      controller.addConnection(connection);

      final events = captureExtension.eventsOfType<ConnectionAdded>();
      expect(events.length, equals(1));
      expect(events.first.connection.sourceNodeId, equals('source'));
      expect(events.first.connection.targetNodeId, equals('target'));
    });

    test('emits ConnectionRemoved when connection is removed', () {
      final source = createTestNodeWithOutputPort(id: 'source', portId: 'out1');
      final target = createTestNodeWithInputPort(
        id: 'target',
        portId: 'in1',
        position: const Offset(200, 0),
      );
      controller.addNode(source);
      controller.addNode(target);

      final connection = createTestConnection(
        id: 'conn1',
        sourceNodeId: 'source',
        sourcePortId: 'out1',
        targetNodeId: 'target',
        targetPortId: 'in1',
      );
      controller.addConnection(connection);
      captureExtension.clear();

      controller.removeConnection('conn1');

      final events = captureExtension.eventsOfType<ConnectionRemoved>();
      expect(events.length, equals(1));
      expect(events.first.connection.id, equals('conn1'));
    });
  });

  // ===========================================================================
  // Node Position/Size Change Event Emission
  // ===========================================================================
  group('Programmatic Position/Size Event Emission', () {
    test('emits NodeMoved for programmatic position change', () {
      final node = createTestNode(
        id: 'node1',
        position: const Offset(100, 100),
      );
      controller.addNode(node);
      captureExtension.clear();

      controller.setNodePosition('node1', const Offset(200, 200));

      final events = captureExtension.eventsOfType<NodeMoved>();
      expect(events.length, equals(1));
      expect(events.first.node.id, equals('node1'));
      expect(events.first.previousPosition, equals(const Offset(100, 100)));
    });

    test('emits NodeResized for programmatic size change', () {
      // Use GroupNode which is resizable
      final node = createTestGroupNode<String>(
        id: 'group1',
        position: Offset.zero,
        size: const Size(200, 150),
        data: 'test',
      );
      controller.addNode(node);
      captureExtension.clear();

      controller.setNodeSize('group1', const Size(300, 250));

      final events = captureExtension.eventsOfType<NodeResized>();
      expect(events.length, equals(1));
      expect(events.first.node.id, equals('group1'));
      expect(events.first.previousSize, equals(const Size(200, 150)));
    });

    test('emits NodeMoved for each node in moveSelectedNodes', () {
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
      captureExtension.clear();

      controller.moveSelectedNodes(const Offset(50, 50));

      final events = captureExtension.eventsOfType<NodeMoved>();
      expect(events.length, equals(2));
    });
  });

  // Note: SelectionChanged events are not currently emitted by the controller.
  // Add tests when selection event emission is implemented.
}
