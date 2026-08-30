@Tags(['unit'])
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobx/mobx.dart';
import 'package:vyuh_node_flow/vyuh_node_flow.dart';

import '../../helpers/test_factories.dart';

Future<void> flushSceneDelta() => Future<void>.delayed(Duration.zero);

void main() {
  setUp(resetTestCounters);

  group('GraphSceneProjection', () {
    test('keeps previously captured snapshots immutable', () async {
      final node = createTestNode(id: 'node', position: const Offset(10, 20));
      final projection = GraphSceneProjection<String, dynamic>()
        ..seed(nodes: [node], connections: const []);
      addTearDown(projection.dispose);
      final before = projection.snapshot;

      runInAction(() => node.position.value = const Offset(80, 90));
      projection.upsertNode(node, const {SceneNodeChange.geometry});
      await flushSceneDelta();

      expect(before.nodes['node']!.position, const Offset(10, 20));
      expect(projection.snapshot.nodes['node']!.position, const Offset(80, 90));
      expect(
        () => before.nodes['other'] = SceneNodeSnapshot.fromNode(node),
        throwsUnsupportedError,
      );
    });

    test('coalesces node changes into one revision and notification', () async {
      final node = createTestNode(id: 'node');
      final projection = GraphSceneProjection<String, dynamic>()
        ..seed(nodes: [node], connections: const []);
      addTearDown(projection.dispose);
      var notifications = 0;
      projection.nodeDeltas.addListener(() => notifications++);

      projection.upsertNode(node, const {SceneNodeChange.geometry});
      projection.upsertNode(node, const {SceneNodeChange.selection});
      projection.upsertNode(node, const {SceneNodeChange.visual});
      await flushSceneDelta();

      expect(notifications, 1);
      expect(projection.revision, 1);
      expect(projection.nodeDeltas.value!.nodeChanges['node'], {
        SceneNodeChange.geometry,
        SceneNodeChange.selection,
        SceneNodeChange.visual,
      });
    });

    test('keeps node and connection repaint signals independent', () async {
      final source = createTestNodeWithOutputPort(id: 'source');
      final target = createTestNodeWithInputPort(id: 'target');
      final connection = createTestConnection(
        id: 'edge',
        sourceNodeId: source.id,
        targetNodeId: target.id,
      );
      final projection = GraphSceneProjection<String, dynamic>()
        ..seed(nodes: [source, target], connections: [connection]);
      addTearDown(projection.dispose);
      var nodeNotifications = 0;
      var connectionNotifications = 0;
      projection.nodeDeltas.addListener(() => nodeNotifications++);
      projection.connectionDeltas.addListener(() => connectionNotifications++);

      connection.selected = true;
      projection.upsertConnection(connection, const {
        SceneConnectionChange.selection,
      });
      await flushSceneDelta();

      expect(nodeNotifications, 0);
      expect(connectionNotifications, 1);
      expect(
        projection.connectionDeltas.value!.connections['edge']!.isSelected,
        isTrue,
      );
    });
  });

  group('NodeFlowController scene adapter', () {
    test(
      'projects direct legacy node mutations as one granular delta',
      () async {
        final node = createTestNode(id: 'node');
        final controller = createTestController(nodes: [node]);
        addTearDown(controller.dispose);
        var notifications = 0;
        controller.sceneProjection.nodeDeltas.addListener(
          () => notifications++,
        );

        runInAction(() {
          node.position.value = const Offset(100, 120);
          node.size.value = const Size(220, 140);
          node.selected.value = true;
          node.invalidateRetainedVisual();
        });
        await flushSceneDelta();

        expect(notifications, 1);
        final delta = controller.sceneProjection.nodeDeltas.value!;
        expect(delta.nodeChanges['node'], contains(SceneNodeChange.geometry));
        expect(delta.nodeChanges['node'], contains(SceneNodeChange.selection));
        expect(delta.nodeChanges['node'], contains(SceneNodeChange.visual));
        expect(delta.nodes['node']!.position, const Offset(100, 120));
        expect(delta.nodes['node']!.size, const Size(220, 140));
        expect(delta.nodes['node']!.isSelected, isTrue);
      },
    );

    test('node geometry invalidates only its incident connections', () async {
      final source = createTestNodeWithOutputPort(id: 'source');
      final target = createTestNodeWithInputPort(id: 'target');
      final unrelatedA = createTestNodeWithOutputPort(id: 'unrelated-a');
      final unrelatedB = createTestNodeWithInputPort(id: 'unrelated-b');
      final incident = createTestConnection(
        id: 'incident',
        sourceNodeId: source.id,
        targetNodeId: target.id,
      );
      final unrelated = createTestConnection(
        id: 'unrelated',
        sourceNodeId: unrelatedA.id,
        targetNodeId: unrelatedB.id,
      );
      final controller = createTestController(
        nodes: [source, target, unrelatedA, unrelatedB],
        connections: [incident, unrelated],
      );
      addTearDown(controller.dispose);

      controller.setNodePosition(source.id, const Offset(40, 50));
      await flushSceneDelta();

      final delta = controller.sceneProjection.connectionDeltas.value!;
      expect(delta.connectionChanges.keys, {'incident'});
      expect(
        delta.connectionChanges['incident'],
        contains(SceneConnectionChange.geometry),
      );
    });

    test('loadGraph replaces same-id entities and their observers', () async {
      final original = createTestNode(id: 'same', data: 'old');
      final replacement = createTestNode(
        id: 'same',
        data: 'new',
        position: const Offset(200, 0),
      );
      final controller = createTestController(nodes: [original]);
      addTearDown(controller.dispose);

      controller.loadGraph(
        NodeGraph<String, dynamic>(
          nodes: [replacement],
          connections: const [],
          viewport: const GraphViewport(x: 0, y: 0, zoom: 1),
        ),
      );
      await flushSceneDelta();
      replacement.isSelected = true;
      await flushSceneDelta();

      final snapshot = controller.sceneProjection.nodeSnapshot('same')!;
      expect(snapshot.source, same(replacement));
      expect(snapshot.position, const Offset(200, 0));
      expect(snapshot.isSelected, isTrue);
    });
  });
}
