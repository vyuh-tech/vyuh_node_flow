@Tags(['widget'])
library;

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobx/mobx.dart';
import 'package:vyuh_node_flow/src/editor/layers/nodes_thumbnail_layer.dart';
import 'package:vyuh_node_flow/vyuh_node_flow.dart';

import '../helpers/test_factories.dart';

/// Widget tests for NodeFlowEditor.
///
/// These tests verify that the editor widget builds correctly, handles
/// configuration changes, and properly integrates with the controller.
void main() {
  late NodeFlowController<String, dynamic> controller;

  setUp(() {
    resetTestCounters();
    controller = createTestController();
  });

  tearDown(() {
    controller.dispose();
  });

  group('NodeFlowEditor - Widget Creation', () {
    testWidgets('editor builds without error', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: NodeFlowEditor<String, dynamic>(
              controller: controller,
              nodeBuilder: (context, node) => Container(),
              theme: NodeFlowTheme.light,
            ),
          ),
        ),
      );

      expect(find.byType(NodeFlowEditor<String, dynamic>), findsOneWidget);
    });

    testWidgets('editor with initial nodes renders nodes', (tester) async {
      // Add nodes before building widget
      controller.addNode(createTestNode(id: 'node-1'));
      controller.addNode(createTestNode(id: 'node-2'));

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: NodeFlowEditor<String, dynamic>(
              controller: controller,
              nodeBuilder: (context, node) =>
                  Container(key: ValueKey(node.id), child: Text(node.id)),
              theme: NodeFlowTheme.light,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('node-1'), findsOneWidget);
      expect(find.text('node-2'), findsOneWidget);
    });

    testWidgets('editor renders CommentNode as a node', (tester) async {
      controller.addNode(createTestNode(id: 'node-1'));
      controller.addNode(
        createTestCommentNode<String>(data: '', id: 'comment-1'),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: NodeFlowEditor<String, dynamic>(
              controller: controller,
              nodeBuilder: (context, node) =>
                  Container(key: ValueKey(node.id), child: Text(node.id)),
              theme: NodeFlowTheme.light,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Editor should build successfully with both nodes
      expect(find.byType(NodeFlowEditor<String, dynamic>), findsOneWidget);
      expect(controller.nodeCount, equals(2));
    });
  });

  group('NodeFlowEditor - Behavior Modes', () {
    testWidgets('design mode allows editing', (tester) async {
      controller.addNode(createTestNode(id: 'node-1'));

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: NodeFlowEditor<String, dynamic>(
              controller: controller,
              nodeBuilder: (context, node) => Container(),
              theme: NodeFlowTheme.light,
              behavior: NodeFlowBehavior.design,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // In design mode, controller should allow drag
      expect(controller.behavior.canDrag, isTrue);
      expect(controller.behavior.canSelect, isTrue);
      expect(controller.behavior.canCreate, isTrue);
    });

    testWidgets('preview mode limits editing', (tester) async {
      controller.addNode(createTestNode(id: 'node-1'));

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: NodeFlowEditor<String, dynamic>(
              controller: controller,
              nodeBuilder: (context, node) => Container(),
              theme: NodeFlowTheme.light,
              behavior: NodeFlowBehavior.preview,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Preview mode should still allow viewing
      expect(find.byType(NodeFlowEditor<String, dynamic>), findsOneWidget);
    });

    testWidgets('present mode is display only', (tester) async {
      controller.addNode(createTestNode(id: 'node-1'));

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: NodeFlowEditor<String, dynamic>(
              controller: controller,
              nodeBuilder: (context, node) => Container(),
              theme: NodeFlowTheme.light,
              behavior: NodeFlowBehavior.present,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Present mode should still render
      expect(find.byType(NodeFlowEditor<String, dynamic>), findsOneWidget);
    });
  });

  group('NodeFlowEditor - Controller Integration', () {
    testWidgets('node additions reflect in UI', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: NodeFlowEditor<String, dynamic>(
              controller: controller,
              nodeBuilder: (context, node) =>
                  Container(key: ValueKey(node.id), child: Text(node.id)),
              theme: NodeFlowTheme.light,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Initially empty
      expect(find.text('dynamic-node'), findsNothing);

      // Add node after widget is built
      controller.addNode(createTestNode(id: 'dynamic-node'));

      await tester.pumpAndSettle();

      // Node should now be rendered
      expect(find.text('dynamic-node'), findsOneWidget);
    });

    testWidgets('node removals reflect in UI', (tester) async {
      controller.addNode(createTestNode(id: 'node-1'));

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: NodeFlowEditor<String, dynamic>(
              controller: controller,
              nodeBuilder: (context, node) =>
                  Container(key: ValueKey(node.id), child: Text(node.id)),
              theme: NodeFlowTheme.light,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();
      expect(find.text('node-1'), findsOneWidget);

      // Remove node
      controller.removeNode('node-1');

      await tester.pumpAndSettle();

      // Node should be gone
      expect(find.text('node-1'), findsNothing);
    });

    testWidgets('viewport changes update display', (tester) async {
      controller.addNode(createTestNode(id: 'node-1'));
      controller.setScreenSize(const Size(800, 600));

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 800,
              height: 600,
              child: NodeFlowEditor<String, dynamic>(
                controller: controller,
                nodeBuilder: (context, node) => Container(),
                theme: NodeFlowTheme.light,
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Change viewport
      controller.setViewport(GraphViewport(x: 100, y: 100, zoom: 1.5));

      await tester.pumpAndSettle();

      // Editor should still be visible
      expect(find.byType(NodeFlowEditor<String, dynamic>), findsOneWidget);
    });

    testWidgets('interactive camera commits reactive viewport only on end', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 800,
              height: 600,
              child: NodeFlowEditor<String, dynamic>(
                controller: controller,
                nodeBuilder: (context, node) => Container(),
                theme: NodeFlowTheme.light,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final committed = <GraphViewport>[];
      final dispose = reaction(
        (_) => controller.viewportObservable.value,
        (viewport) => committed.add(viewport),
      );
      addTearDown(dispose.call);

      final initialCommitted = controller.viewportObservable.value;
      final gesture = await tester.startGesture(
        tester.getCenter(find.byType(InteractiveViewer)),
      );
      await gesture.moveBy(const Offset(40, 20));
      await tester.pump();
      await gesture.moveBy(const Offset(40, 20));
      await tester.pump();

      expect(controller.viewport, isNot(initialCommitted));
      expect(controller.viewportObservable.value, initialCommitted);
      expect(committed, isEmpty);

      await gesture.up();
      await tester.pump();

      expect(controller.viewportObservable.value, controller.viewport);
      expect(committed, hasLength(1));
    });

    testWidgets(
      'camera gesture replaces node widgets with painted navigation',
      (tester) async {
        controller.addNodes([
          createTestNode(id: 'node-1', position: const Offset(100, 100)),
          createTestNode(id: 'node-2', position: const Offset(300, 100)),
        ]);

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SizedBox(
                width: 800,
                height: 600,
                child: NodeFlowEditor<String, dynamic>(
                  controller: controller,
                  nodeBuilder: (context, node) => Text(node.id),
                  theme: NodeFlowTheme.light,
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('node-1'), findsOneWidget);
        expect(find.text('node-2'), findsOneWidget);
        expect(find.byType(NodesThumbnailLayer<String>), findsNothing);

        final gesture = await tester.startGesture(const Offset(700, 500));
        await gesture.moveBy(const Offset(40, 20));
        await tester.pump();

        expect(controller.interaction.isViewportInteracting.value, isTrue);
        expect(find.byType(NodesThumbnailLayer<String>), findsOneWidget);
        expect(find.text('node-1'), findsNothing);
        expect(find.text('node-2'), findsNothing);

        await gesture.up();
        await tester.pump();

        expect(controller.interaction.isViewportInteracting.value, isFalse);
        expect(find.byType(NodesThumbnailLayer<String>), findsNothing);
        expect(find.text('node-1'), findsOneWidget);
        expect(find.text('node-2'), findsOneWidget);
      },
    );

    testWidgets('external live camera drives transform without MobX commit', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 800,
              height: 600,
              child: NodeFlowEditor<String, dynamic>(
                controller: controller,
                nodeBuilder: (context, node) => Container(),
                theme: NodeFlowTheme.light,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      const camera = GraphViewport(x: 125, y: 75, zoom: 1.25);
      final committedBefore = controller.viewportObservable.value;
      controller.updateCameraViewport(camera);
      await tester.pump();

      final viewer = tester.widget<InteractiveViewer>(
        find.byType(InteractiveViewer),
      );
      final transform = viewer.transformationController!.value;
      final translation = transform.getTranslation();
      expect(translation.x, camera.x);
      expect(translation.y, camera.y);
      expect(transform.getMaxScaleOnAxis(), camera.zoom);
      expect(controller.viewportObservable.value, committedBefore);

      controller.commitCameraViewport();
      expect(controller.viewportObservable.value, camera);
    });
  });

  group('NodeFlowEditor - Adaptive Overview Interaction', () {
    testWidgets('thumbnail nodes remain selectable, tappable, and draggable', (
      tester,
    ) async {
      controller.dispose();
      controller = NodeFlowController<String, dynamic>(
        nodes: [
          createTestNode(
            id: 'overview-node',
            position: const Offset(100, 100),
            size: const Size(100, 100),
          ),
          createTestNode(
            id: 'threshold-node',
            position: const Offset(300, 100),
            size: const Size(100, 100),
          ),
        ],
        config: NodeFlowConfig(
          plugins: [LodPlugin(minThreshold: 0, maxInteractiveNodes: 1)],
        ),
      );
      var tapCount = 0;
      var dragStartCount = 0;
      var dragStopCount = 0;

      await tester.pumpWidget(
        MaterialApp(
          home: SizedBox(
            width: 800,
            height: 600,
            child: NodeFlowEditor<String, dynamic>(
              controller: controller,
              nodeBuilder: (context, node) => Text(node.id),
              theme: NodeFlowTheme.light,
              events: NodeFlowEvents<String, dynamic>(
                node: NodeEvents<String>(
                  onTap: (_) => tapCount++,
                  onDragStart: (_) => dragStartCount++,
                  onDragStop: (_) => dragStopCount++,
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(controller.lod!.useThumbnailMode, isTrue);
      expect(find.byType(NodesThumbnailLayer<String>), findsWidgets);
      expect(find.text('overview-node'), findsNothing);

      await tester.tapAt(const Offset(150, 150));
      await tester.pump();

      expect(controller.selectedNodeIds, contains('overview-node'));
      expect(tapCount, 1);

      await tester.dragFrom(const Offset(150, 150), const Offset(40, 20));
      await tester.pump();

      expect(
        controller.getNode('overview-node')!.position.value,
        const Offset(140, 120),
      );
      expect(dragStartCount, 1);
      expect(dragStopCount, 1);
      expect(controller.draggedNodeId, isNull);
      expect(controller.canvasLocked, isFalse);
    });

    testWidgets('canceling an overview drag restores the node position', (
      tester,
    ) async {
      controller.dispose();
      controller = NodeFlowController<String, dynamic>(
        nodes: [
          createTestNode(
            id: 'overview-node',
            position: const Offset(100, 100),
            size: const Size(100, 100),
          ),
          createTestNode(
            id: 'threshold-node',
            position: const Offset(300, 100),
            size: const Size(100, 100),
          ),
        ],
        config: NodeFlowConfig(
          plugins: [LodPlugin(minThreshold: 0, maxInteractiveNodes: 1)],
        ),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: SizedBox(
            width: 800,
            height: 600,
            child: NodeFlowEditor<String, dynamic>(
              controller: controller,
              nodeBuilder: (context, node) => Text(node.id),
              theme: NodeFlowTheme.light,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final gesture = await tester.startGesture(const Offset(150, 150));
      await gesture.moveBy(const Offset(40, 20));
      await tester.pump();

      expect(controller.draggedNodeId, 'overview-node');
      expect(
        controller.getNode('overview-node')!.position.value,
        const Offset(140, 120),
      );

      await gesture.cancel();
      await tester.pump();

      expect(
        controller.getNode('overview-node')!.position.value,
        const Offset(100, 100),
      );
      expect(controller.draggedNodeId, isNull);
      expect(controller.canvasLocked, isFalse);
    });
  });

  group('NodeFlowEditor - Theme Changes', () {
    testWidgets('theme changes apply correctly', (tester) async {
      controller.addNode(createTestNode(id: 'node-1'));

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: NodeFlowEditor<String, dynamic>(
              controller: controller,
              nodeBuilder: (context, node) => Container(),
              theme: NodeFlowTheme.light,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Rebuild with dark theme
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: NodeFlowEditor<String, dynamic>(
              controller: controller,
              nodeBuilder: (context, node) => Container(),
              theme: NodeFlowTheme.dark,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Should still render correctly
      expect(find.byType(NodeFlowEditor<String, dynamic>), findsOneWidget);
    });
  });

  group('NodeFlowEditor - Scroll Behavior', () {
    testWidgets('scrollToZoom can be configured via config', (tester) async {
      // Configure scrollToZoom via the controller's config
      controller.config.update(scrollToZoom: false);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: NodeFlowEditor<String, dynamic>(
              controller: controller,
              nodeBuilder: (context, node) => Container(),
              theme: NodeFlowTheme.light,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Editor should build successfully
      expect(find.byType(NodeFlowEditor<String, dynamic>), findsOneWidget);
      // Verify config was applied
      expect(controller.config.scrollToZoom.value, isFalse);
    });
  });

  group('NodeFlowEditor - Events System', () {
    testWidgets('events onInit callback fires', (tester) async {
      var initCalled = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: NodeFlowEditor<String, dynamic>(
              controller: controller,
              nodeBuilder: (context, node) => Container(),
              theme: NodeFlowTheme.light,
              events: NodeFlowEvents<String, dynamic>(
                onInit: () {
                  initCalled = true;
                },
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(initCalled, isTrue);
    });

    testWidgets('default ports fire mouse enter and leave callbacks', (
      tester,
    ) async {
      final node = createTestNodeWithOutputPort(
        id: 'node-1',
        portId: 'output-1',
      );
      controller.addNode(node);

      Node<String>? enteredNode;
      Port? enteredPort;
      Node<String>? leftNode;
      Port? leftPort;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 800,
              height: 600,
              child: NodeFlowEditor<String, dynamic>(
                controller: controller,
                nodeBuilder: (context, node) => const SizedBox.expand(),
                theme: NodeFlowTheme.light,
                events: NodeFlowEvents<String, dynamic>(
                  port: PortEvents<String>(
                    onMouseEnter: (node, port) {
                      enteredNode = node;
                      enteredPort = port;
                    },
                    onMouseLeave: (node, port) {
                      leftNode = node;
                      leftPort = port;
                    },
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final portFinder = find.byType(PortWidget<String>);
      expect(portFinder, findsOneWidget);

      final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
      await mouse.addPointer(location: const Offset(700, 500));
      await mouse.moveTo(tester.getCenter(portFinder));
      await tester.pump();

      expect(enteredNode, same(node));
      expect(enteredPort, same(node.ports.single));

      await mouse.moveTo(const Offset(700, 500));
      await tester.pump();

      expect(leftNode, same(node));
      expect(leftPort, same(node.ports.single));
    });
  });

  group('NodeFlowEditor - Layout and Sizing', () {
    testWidgets('editor fills available space', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 800,
              height: 600,
              child: NodeFlowEditor<String, dynamic>(
                controller: controller,
                nodeBuilder: (context, node) => Container(),
                theme: NodeFlowTheme.light,
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Find the editor widget
      final editorWidget = tester.widget<NodeFlowEditor<String, dynamic>>(
        find.byType(NodeFlowEditor<String, dynamic>),
      );

      expect(editorWidget, isNotNull);
    });

    testWidgets('editor updates screen size on controller', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 800,
              height: 600,
              child: NodeFlowEditor<String, dynamic>(
                controller: controller,
                nodeBuilder: (context, node) => Container(),
                theme: NodeFlowTheme.light,
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Controller should have screen size set (via _SizeObserver)
      expect(controller.screenSize, isNot(Size.zero));
    });
  });

  group('NodeFlowEditor - Multiple Nodes', () {
    testWidgets('renders large number of nodes', (tester) async {
      // Add many nodes
      for (var i = 0; i < 50; i++) {
        controller.addNode(
          createTestNode(
            id: 'node-$i',
            position: Offset(i * 150.0, (i % 5) * 100.0),
          ),
        );
      }

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 1920,
              height: 1080,
              child: NodeFlowEditor<String, dynamic>(
                controller: controller,
                nodeBuilder: (context, node) => Container(
                  key: ValueKey(node.id),
                  width: 100,
                  height: 60,
                  color: Colors.blue,
                ),
                theme: NodeFlowTheme.light,
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Editor should render without error
      expect(find.byType(NodeFlowEditor<String, dynamic>), findsOneWidget);
      expect(controller.nodeCount, equals(50));
    });
  });
}
