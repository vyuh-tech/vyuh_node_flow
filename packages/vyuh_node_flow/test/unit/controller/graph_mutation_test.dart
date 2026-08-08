/// Transactional graph mutation tests for [NodeFlowController].
@Tags(['unit'])
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:mobx/mobx.dart';
import 'package:vyuh_node_flow/vyuh_node_flow.dart';

import '../../helpers/test_factories.dart';

class _EventCapturePlugin extends NodeFlowPlugin {
  final List<GraphEvent> events = [];

  @override
  String get id => 'graph-mutation-events';

  @override
  void attach(NodeFlowController controller) {}

  @override
  void detach() {}

  @override
  void onEvent(GraphEvent event) => events.add(event);
}

Connection<dynamic> _connection(
  String id,
  String sourceNodeId,
  String targetNodeId,
) {
  return Connection<dynamic>(
    id: id,
    sourceNodeId: sourceNodeId,
    sourcePortId: 'out',
    targetNodeId: targetNodeId,
    targetPortId: 'in',
  );
}

void main() {
  setUp(resetTestCounters);

  group('mutateGraph', () {
    test(
      'publishes one reactive and spatial invalidation for topology churn',
      () {
        final controller = NodeFlowController<String, dynamic>();
        addTearDown(controller.dispose);
        controller.addNodes([
          createTestNode(id: 'source', position: Offset.zero),
          createTestNode(id: 'target', position: const Offset(400, 0)),
        ]);

        var reactionRuns = 0;
        final disposeReaction = autorun((_) {
          controller.nodeCount;
          controller.connections.length;
          reactionRuns++;
        });
        addTearDown(disposeReaction.call);
        final initialSpatialVersion = controller.spatialIndex.version.value;

        controller.mutateGraph(() {
          controller.addNode(
            createTestNode(id: 'generated', position: const Offset(200, 0)),
          );
          controller.addConnections([
            _connection('incoming', 'source', 'generated'),
            _connection('outgoing', 'generated', 'target'),
          ]);
        }, reason: 'insert-generated-node');

        expect(controller.nodeCount, 3);
        expect(controller.connections, hasLength(2));
        expect(
          reactionRuns,
          2,
          reason: 'autorun should run initially and once after the mutation',
        );
        expect(
          controller.spatialIndex.version.value,
          initialSpatialVersion + 1,
        );
      },
    );

    test('preserves ordered edge and node deletion callbacks and events', () {
      final controller = NodeFlowController<String, dynamic>();
      addTearDown(controller.dispose);
      controller.mutateGraph(() {
        controller.addNodes([
          createTestNode(id: 'source'),
          createTestNode(id: 'generated'),
          createTestNode(id: 'target'),
        ]);
        controller.addConnections([
          _connection('incoming', 'source', 'generated'),
          _connection('outgoing', 'generated', 'target'),
        ]);
      }, reason: 'setup');

      final callbackOrder = <String>[];
      controller.updateEvents(
        NodeFlowEvents<String, dynamic>(
          node: NodeEvents<String>(
            onDeleted: (node) => callbackOrder.add('node:${node.id}'),
          ),
          connection: ConnectionEvents<String, dynamic>(
            onDeleted: (connection) =>
                callbackOrder.add('connection:${connection.id}'),
          ),
        ),
      );
      final plugin = _EventCapturePlugin();
      controller.addPlugin(plugin);

      var reactionRuns = 0;
      final disposeReaction = autorun((_) {
        controller.nodeCount;
        controller.connections.length;
        reactionRuns++;
      });
      addTearDown(disposeReaction.call);

      controller.mutateGraph(
        () => controller.removeNode('generated'),
        reason: 'remove-generated-node',
      );

      expect(controller.nodeCount, 2);
      expect(controller.connections, isEmpty);
      expect(reactionRuns, 2);
      expect(callbackOrder, [
        'connection:incoming',
        'connection:outgoing',
        'node:generated',
      ]);
      expect(plugin.events, [
        isA<BatchStarted>(),
        isA<ConnectionRemoved>(),
        isA<ConnectionRemoved>(),
        isA<NodeRemoved<String>>(),
        isA<BatchEnded>(),
      ]);
      expect(
        (plugin.events.first as BatchStarted).reason,
        'remove-generated-node',
      );
    });

    test(
      'nested mutations share the outer notification and event boundary',
      () {
        final controller = NodeFlowController<String, dynamic>();
        addTearDown(controller.dispose);
        final plugin = _EventCapturePlugin();
        controller.addPlugin(plugin);

        var reactionRuns = 0;
        final disposeReaction = autorun((_) {
          controller.nodeCount;
          reactionRuns++;
        });
        addTearDown(disposeReaction.call);

        controller.mutateGraph(() {
          controller.addNode(createTestNode(id: 'one'));
          controller.mutateGraph(
            () => controller.addNode(createTestNode(id: 'two')),
            reason: 'inner',
          );
        }, reason: 'outer');

        expect(reactionRuns, 2);
        expect(plugin.events.whereType<BatchStarted>(), hasLength(1));
        expect(plugin.events.whereType<BatchEnded>(), hasLength(1));
        expect(plugin.events.whereType<BatchStarted>().single.reason, 'outer');
      },
    );

    test('ends the mutation boundary when the callback throws', () {
      final controller = NodeFlowController<String, dynamic>();
      addTearDown(controller.dispose);
      final plugin = _EventCapturePlugin();
      controller.addPlugin(plugin);

      expect(
        () => controller.mutateGraph(() {
          controller.addNode(createTestNode(id: 'retained'));
          throw StateError('stop');
        }, reason: 'failing-mutation'),
        throwsStateError,
      );

      expect(controller.getNode('retained'), isNotNull);
      expect(plugin.events.first, isA<BatchStarted>());
      expect(plugin.events.last, isA<BatchEnded>());
    });
  });
}
