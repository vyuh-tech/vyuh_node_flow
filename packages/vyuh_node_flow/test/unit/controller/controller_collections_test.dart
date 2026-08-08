/// Tests for the controller's read-only reactive collection API.
@Tags(['unit'])
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:mobx/mobx.dart';
import 'package:vyuh_node_flow/vyuh_node_flow.dart';

import '../../helpers/test_factories.dart';

void main() {
  setUp(resetTestCounters);

  test('graph collection views are stable, live, and read-only', () {
    final controller = createTestController();
    addTearDown(controller.dispose);

    final nodes = controller.nodes;
    final connections = controller.connections;
    final selectedNodes = controller.selectedNodeIds;
    final selectedConnections = controller.selectedConnectionIds;

    expect(controller.nodes, same(nodes));
    expect(controller.connections, same(connections));
    expect(controller.selectedNodeIds, same(selectedNodes));
    expect(controller.selectedConnectionIds, same(selectedConnections));

    final source = createTestNodeWithOutputPort(id: 'source', portId: 'out');
    final target = createTestNodeWithInputPort(
      id: 'target',
      portId: 'in',
      position: const Offset(200, 0),
    );
    controller.addNodes([source, target]);
    controller.addConnection(
      createTestConnection(
        id: 'connection',
        sourceNodeId: source.id,
        sourcePortId: 'out',
        targetNodeId: target.id,
        targetPortId: 'in',
      ),
    );
    controller.selectNode(source.id);
    controller.selectConnection('connection');

    expect(nodes.keys, containsAll([source.id, target.id]));
    expect(connections.single.id, 'connection');
    expect(selectedNodes, isEmpty);
    expect(selectedConnections, contains('connection'));

    expect(
      () => nodes['injected'] = createTestNode(id: 'injected'),
      throwsUnsupportedError,
    );
    expect(() => connections.clear(), throwsUnsupportedError);
    expect(() => selectedNodes.add('injected'), throwsUnsupportedError);
    expect(() => selectedConnections.clear(), throwsUnsupportedError);
  });

  test('read-only views retain MobX collection reactivity', () {
    final controller = createTestController();
    addTearDown(controller.dispose);
    final observedNodeCounts = <int>[];
    final observedSelections = <int>[];

    final disposeNodes = autorun((_) {
      observedNodeCounts.add(controller.nodes.length);
    });
    final disposeSelection = autorun((_) {
      observedSelections.add(controller.selectedNodeIds.length);
    });
    addTearDown(disposeNodes.call);
    addTearDown(disposeSelection.call);

    controller.addNode(createTestNode(id: 'node'));
    controller.selectNode('node');
    controller.removeNode('node');

    expect(observedNodeCounts, [0, 1, 0]);
    expect(observedSelections, [0, 1, 0]);
  });

  test('mutateNodeData combines mutation and event emission', () {
    final capture = _EventCapturePlugin();
    final controller = NodeFlowController<_MutableData, dynamic>();
    addTearDown(controller.dispose);
    controller.addPlugin(capture);
    final node = Node<_MutableData>(
      id: 'node',
      type: 'test',
      position: Offset.zero,
      data: _MutableData('Before'),
    );
    controller.addNode(node);
    capture.events.clear();
    final previous = node.data.copy();

    final changed = controller.mutateNodeData(
      node.id,
      (data) => data.title = 'After',
      previousData: previous,
    );

    expect(changed, isTrue);
    expect(node.data.title, 'After');
    final event = capture.events
        .whereType<NodeDataChanged<_MutableData>>()
        .single;
    expect(event.previousData?.title, 'Before');
    expect(event.node, same(node));
  });

  test('mutateNodeData ignores unknown nodes', () {
    final controller = NodeFlowController<_MutableData, dynamic>();
    addTearDown(controller.dispose);
    var invoked = false;

    final changed = controller.mutateNodeData('missing', (_) => invoked = true);

    expect(changed, isFalse);
    expect(invoked, isFalse);
  });
}

class _MutableData {
  _MutableData(this.title);

  String title;

  _MutableData copy() => _MutableData(title);
}

class _EventCapturePlugin extends NodeFlowPlugin {
  final events = <GraphEvent>[];

  @override
  String get id => 'controller-collections-event-capture';

  @override
  void attach(NodeFlowController controller) {}

  @override
  void detach() {}

  @override
  void onEvent(GraphEvent event) => events.add(event);
}
