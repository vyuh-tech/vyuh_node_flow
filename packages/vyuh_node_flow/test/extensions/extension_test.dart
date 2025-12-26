@Tags(['unit', 'extensions'])
library;

import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:vyuh_node_flow/vyuh_node_flow.dart';

/// A simple test extension that tracks events
class TestExtension<T> implements NodeFlowExtension<T> {
  @override
  final String id;

  TestExtension({this.id = 'test-extension'});

  dynamic controller;
  final List<GraphEvent> events = [];
  bool attached = false;
  bool detached = false;

  @override
  void attach(dynamic controller) {
    this.controller = controller;
    attached = true;
  }

  @override
  void detach() {
    controller = null;
    detached = true;
  }

  @override
  void onEvent(GraphEvent event) {
    events.add(event);
  }

  void clearEvents() => events.clear();
}

void main() {
  group('NodeFlowExtension', () {
    late NodeFlowController<String> controller;

    setUp(() {
      controller = NodeFlowController<String>();
    });

    tearDown(() {
      controller.dispose();
    });

    group('Extension Lifecycle', () {
      test('addExtension attaches extension', () {
        final extension = TestExtension<String>();
        expect(extension.attached, isFalse);

        controller.addExtension(extension);

        expect(extension.attached, isTrue);
        expect(extension.controller, isNotNull);
      });

      test('removeExtension detaches extension', () {
        final extension = TestExtension<String>();
        controller.addExtension(extension);
        expect(extension.detached, isFalse);

        controller.removeExtension('test-extension');

        expect(extension.detached, isTrue);
        expect(controller.hasExtension('test-extension'), isFalse);
      });

      test('dispose detaches all extensions', () {
        // Use a separate controller for this test to avoid double-dispose
        final testController = NodeFlowController<String>();
        final extension1 = TestExtension<String>(id: 'ext-1');
        final extension2 = TestExtension<String>(id: 'ext-2');

        testController.addExtension(extension1);
        testController.addExtension(extension2);

        testController.dispose();

        expect(extension1.detached, isTrue);
        expect(extension2.detached, isTrue);
      });

      test('hasExtension returns true for registered extensions', () {
        final extension = TestExtension<String>();
        expect(controller.hasExtension('test-extension'), isFalse);

        controller.addExtension(extension);

        expect(controller.hasExtension('test-extension'), isTrue);
      });

      test('getExtension returns typed extension', () {
        final extension = TestExtension<String>();
        controller.addExtension(extension);

        final retrieved = controller.getExtension<TestExtension<String>>();

        expect(retrieved, isNotNull);
        expect(retrieved, same(extension));
      });

      test('getExtension returns null for non-existent extension', () {
        final retrieved = controller.getExtension<TestExtension<String>>();
        expect(retrieved, isNull);
      });

      test('extensions getter returns unmodifiable list', () {
        final extension = TestExtension<String>();
        controller.addExtension(extension);

        final extensions = controller.extensions;
        expect(extensions.length, equals(1));
        expect(() => extensions.add(extension), throwsA(isA<Error>()));
      });
    });

    group('Node Events', () {
      test('NodeAdded event is emitted when node is added', () {
        final extension = TestExtension<String>();
        controller.addExtension(extension);
        extension.clearEvents();

        final node = Node<String>(
          id: 'node-1',
          type: 'test',
          position: Offset.zero,
          data: 'test',
        );
        controller.addNode(node);

        expect(extension.events.length, equals(1));
        expect(extension.events.first, isA<NodeAdded<String>>());
        final event = extension.events.first as NodeAdded<String>;
        expect(event.node.id, equals('node-1'));
      });

      test('NodeRemoved event is emitted when node is removed', () {
        final node = Node<String>(
          id: 'node-1',
          type: 'test',
          position: Offset.zero,
          data: 'test',
        );
        controller.addNode(node);

        final extension = TestExtension<String>();
        controller.addExtension(extension);
        extension.clearEvents();

        controller.removeNode('node-1');

        expect(extension.events.length, equals(1));
        expect(extension.events.first, isA<NodeRemoved<String>>());
        final event = extension.events.first as NodeRemoved<String>;
        expect(event.node.id, equals('node-1'));
      });

      test('NodeMoved event is emitted when node position changes', () {
        final node = Node<String>(
          id: 'node-1',
          type: 'test',
          position: Offset.zero,
          data: 'test',
        );
        controller.addNode(node);

        final extension = TestExtension<String>();
        controller.addExtension(extension);
        extension.clearEvents();

        controller.setNodePosition('node-1', const Offset(100, 200));

        expect(extension.events.length, equals(1));
        expect(extension.events.first, isA<NodeMoved<String>>());
        final event = extension.events.first as NodeMoved<String>;
        expect(event.node.id, equals('node-1'));
        expect(event.previousPosition, equals(Offset.zero));
      });

      test('NodeResized event is emitted when node size changes', () {
        final node = Node<String>(
          id: 'node-1',
          type: 'test',
          position: Offset.zero,
          data: 'test',
        );
        controller.addNode(node);

        final extension = TestExtension<String>();
        controller.addExtension(extension);
        extension.clearEvents();

        controller.setNodeSize('node-1', const Size(200, 150));

        expect(extension.events.length, equals(1));
        expect(extension.events.first, isA<NodeResized<String>>());
        final event = extension.events.first as NodeResized<String>;
        expect(event.node.id, equals('node-1'));
      });

      test(
        'NodeVisibilityChanged event is emitted when visibility changes',
        () {
          final node = Node<String>(
            id: 'node-1',
            type: 'test',
            position: Offset.zero,
            data: 'test',
          );
          controller.addNode(node);

          final extension = TestExtension<String>();
          controller.addExtension(extension);
          extension.clearEvents();

          controller.setNodeVisibility('node-1', false);

          expect(extension.events.length, equals(1));
          expect(extension.events.first, isA<NodeVisibilityChanged<String>>());
          final event = extension.events.first as NodeVisibilityChanged<String>;
          expect(event.node.id, equals('node-1'));
          expect(event.wasVisible, isTrue);
        },
      );
    });

    group('Connection Events', () {
      test('ConnectionAdded event is emitted when connection is added', () {
        final node1 = Node<String>(
          id: 'node-1',
          type: 'test',
          position: Offset.zero,
          data: 'test',
        );
        final node2 = Node<String>(
          id: 'node-2',
          type: 'test',
          position: const Offset(200, 0),
          data: 'test',
        );
        controller.addNode(node1);
        controller.addNode(node2);

        final extension = TestExtension<String>();
        controller.addExtension(extension);
        extension.clearEvents();

        final connection = Connection(
          id: 'conn-1',
          sourceNodeId: 'node-1',
          sourcePortId: 'output',
          targetNodeId: 'node-2',
          targetPortId: 'input',
        );
        controller.addConnection(connection);

        expect(extension.events.length, equals(1));
        expect(extension.events.first, isA<ConnectionAdded>());
        final event = extension.events.first as ConnectionAdded;
        expect(event.connection.id, equals('conn-1'));
      });

      test('ConnectionRemoved event is emitted when connection is removed', () {
        final node1 = Node<String>(
          id: 'node-1',
          type: 'test',
          position: Offset.zero,
          data: 'test',
        );
        final node2 = Node<String>(
          id: 'node-2',
          type: 'test',
          position: const Offset(200, 0),
          data: 'test',
        );
        controller.addNode(node1);
        controller.addNode(node2);

        final connection = Connection(
          id: 'conn-1',
          sourceNodeId: 'node-1',
          sourcePortId: 'output',
          targetNodeId: 'node-2',
          targetPortId: 'input',
        );
        controller.addConnection(connection);

        final extension = TestExtension<String>();
        controller.addExtension(extension);
        extension.clearEvents();

        controller.removeConnection('conn-1');

        expect(extension.events.length, equals(1));
        expect(extension.events.first, isA<ConnectionRemoved>());
        final event = extension.events.first as ConnectionRemoved;
        expect(event.connection.id, equals('conn-1'));
      });

      test(
        'ConnectionRemoved events are emitted when node with connections is removed',
        () {
          final node1 = Node<String>(
            id: 'node-1',
            type: 'test',
            position: Offset.zero,
            data: 'test',
          );
          final node2 = Node<String>(
            id: 'node-2',
            type: 'test',
            position: const Offset(200, 0),
            data: 'test',
          );
          controller.addNode(node1);
          controller.addNode(node2);

          final connection = Connection(
            id: 'conn-1',
            sourceNodeId: 'node-1',
            sourcePortId: 'output',
            targetNodeId: 'node-2',
            targetPortId: 'input',
          );
          controller.addConnection(connection);

          final extension = TestExtension<String>();
          controller.addExtension(extension);
          extension.clearEvents();

          controller.removeNode('node-1');

          // Should emit ConnectionRemoved first, then NodeRemoved
          expect(extension.events.length, equals(2));
          expect(extension.events[0], isA<ConnectionRemoved>());
          expect(extension.events[1], isA<NodeRemoved<String>>());
        },
      );
    });

    group('Viewport Events', () {
      test('ViewportChanged event is emitted when viewport changes', () {
        final extension = TestExtension<String>();
        controller.addExtension(extension);
        extension.clearEvents();

        controller.setViewport(const GraphViewport(x: 100, y: 50, zoom: 1.5));

        expect(extension.events.length, equals(1));
        expect(extension.events.first, isA<ViewportChanged>());
        final event = extension.events.first as ViewportChanged;
        expect(event.viewport.x, equals(100));
        expect(event.viewport.y, equals(50));
        expect(event.viewport.zoom, equals(1.5));
      });
    });

    group('Batch Operations', () {
      test('batch emits BatchStarted and BatchEnded events', () {
        final extension = TestExtension<String>();
        controller.addExtension(extension);
        extension.clearEvents();

        controller.batch('test-batch', () {});

        expect(extension.events.length, equals(2));
        expect(extension.events[0], isA<BatchStarted>());
        expect(extension.events[1], isA<BatchEnded>());
        expect(
          (extension.events[0] as BatchStarted).reason,
          equals('test-batch'),
        );
      });

      test('batch wraps operations between start and end events', () {
        final node = Node<String>(
          id: 'node-1',
          type: 'test',
          position: Offset.zero,
          data: 'test',
        );
        controller.addNode(node);

        final extension = TestExtension<String>();
        controller.addExtension(extension);
        extension.clearEvents();

        controller.batch('multi-move', () {
          controller.setNodePosition('node-1', const Offset(100, 100));
          controller.setNodePosition('node-1', const Offset(200, 200));
        });

        expect(extension.events.length, equals(4));
        expect(extension.events[0], isA<BatchStarted>());
        expect(extension.events[1], isA<NodeMoved<String>>());
        expect(extension.events[2], isA<NodeMoved<String>>());
        expect(extension.events[3], isA<BatchEnded>());
      });

      test('nested batch only emits events for outermost batch', () {
        final node = Node<String>(
          id: 'node-1',
          type: 'test',
          position: Offset.zero,
          data: 'test',
        );
        controller.addNode(node);

        final extension = TestExtension<String>();
        controller.addExtension(extension);
        extension.clearEvents();

        controller.batch('outer', () {
          controller.setNodePosition('node-1', const Offset(100, 100));
          controller.batch('inner', () {
            controller.setNodePosition('node-1', const Offset(200, 200));
          });
          controller.setNodePosition('node-1', const Offset(300, 300));
        });

        // Should see: BatchStarted(outer), moves, but no inner batch events
        final batchEvents = extension.events.whereType<BatchStarted>().toList();
        expect(batchEvents.length, equals(1));
        expect(batchEvents[0].reason, equals('outer'));
      });
    });

    group('Event Content', () {
      test('NodeMoved contains previous position', () {
        final node = Node<String>(
          id: 'node-1',
          type: 'test',
          position: Offset.zero,
          data: 'test',
        );
        controller.addNode(node);
        controller.setNodePosition('node-1', const Offset(50, 50));

        final extension = TestExtension<String>();
        controller.addExtension(extension);
        extension.clearEvents();

        controller.setNodePosition('node-1', const Offset(100, 100));

        final event = extension.events.first as NodeMoved<String>;
        expect(event.previousPosition, equals(const Offset(50, 50)));
        expect(event.node.position.value, equals(const Offset(100, 100)));
      });

      test('NodeResized contains previous size', () {
        final node = Node<String>(
          id: 'node-1',
          type: 'test',
          position: Offset.zero,
          data: 'test',
        );
        controller.addNode(node);
        controller.setNodeSize('node-1', const Size(100, 100));

        final extension = TestExtension<String>();
        controller.addExtension(extension);
        extension.clearEvents();

        controller.setNodeSize('node-1', const Size(200, 150));

        final event = extension.events.first as NodeResized<String>;
        expect(event.previousSize, equals(const Size(100, 100)));
        expect(event.node.size.value, equals(const Size(200, 150)));
      });

      test('ViewportChanged contains previous viewport', () {
        controller.setViewport(const GraphViewport(x: 10, y: 20, zoom: 1.0));

        final extension = TestExtension<String>();
        controller.addExtension(extension);
        extension.clearEvents();

        controller.setViewport(const GraphViewport(x: 100, y: 50, zoom: 1.5));

        final event = extension.events.first as ViewportChanged;
        expect(event.previousViewport.x, equals(10));
        expect(event.previousViewport.y, equals(20));
        expect(event.previousViewport.zoom, equals(1.0));
      });
    });

    group('Multiple Extensions', () {
      test('events are broadcast to all extensions', () {
        final extension1 = TestExtension<String>(id: 'ext-1');
        final extension2 = TestExtension<String>(id: 'ext-2');

        controller.addExtension(extension1);
        controller.addExtension(extension2);
        extension1.clearEvents();
        extension2.clearEvents();

        final node = Node<String>(
          id: 'node-1',
          type: 'test',
          position: Offset.zero,
          data: 'test',
        );
        controller.addNode(node);

        expect(extension1.events.length, equals(1));
        expect(extension2.events.length, equals(1));
        expect(extension1.events.first, isA<NodeAdded<String>>());
        expect(extension2.events.first, isA<NodeAdded<String>>());
      });
    });

    group('Event toString', () {
      test('NodeAdded toString includes node id', () {
        final node = Node<String>(
          id: 'my-node',
          type: 'test',
          position: Offset.zero,
          data: 'test',
        );
        final event = NodeAdded<String>(node);
        expect(event.toString(), contains('my-node'));
      });

      test('BatchStarted toString includes reason', () {
        const event = BatchStarted('my-batch');
        expect(event.toString(), contains('my-batch'));
      });
    });
  });
}
