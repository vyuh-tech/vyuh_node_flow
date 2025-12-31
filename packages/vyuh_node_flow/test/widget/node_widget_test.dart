@Tags(['widget'])
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vyuh_node_flow/vyuh_node_flow.dart';

import '../helpers/test_factories.dart';

/// Widget tests for NodeWidget.
///
/// These tests verify that individual node widgets build correctly,
/// handle state changes, and integrate with the controller.
void main() {
  late NodeFlowController<String, dynamic> controller;

  setUp(() {
    resetTestCounters();
    controller = createTestController();
    controller.setScreenSize(const Size(800, 600));
  });

  tearDown(() {
    controller.dispose();
  });

  group('NodeWidget - Basic Rendering', () {
    testWidgets('node widget builds with custom content', (tester) async {
      final node = createTestNode(id: 'test-node');
      controller.addNode(node);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: NodeFlowEditor<String, dynamic>(
              controller: controller,
              nodeBuilder: (context, node) => Container(
                key: const ValueKey('custom-content'),
                child: const Text('Custom Node'),
              ),
              theme: NodeFlowTheme.light,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Custom Node'), findsOneWidget);
    });

    testWidgets('node widget respects visibility', (tester) async {
      final node = createTestNode(id: 'test-node');
      controller.addNode(node);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: NodeFlowEditor<String, dynamic>(
              controller: controller,
              nodeBuilder: (context, node) => Text(node.id),
              theme: NodeFlowTheme.light,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();
      expect(find.text('test-node'), findsOneWidget);

      // Hide node
      controller.setNodeVisibility('test-node', false);

      await tester.pumpAndSettle();

      // Hidden node should not render its content
      // (it returns SizedBox.shrink when not visible)
      expect(find.text('test-node'), findsNothing);
    });
  });

  group('NodeWidget - Port Rendering', () {
    testWidgets('node with ports renders port widgets', (tester) async {
      final node = createTestNodeWithPorts(id: 'ports-node');
      controller.addNode(node);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: NodeFlowEditor<String, dynamic>(
              controller: controller,
              nodeBuilder: (context, node) =>
                  SizedBox(width: 100, height: 60, child: Text(node.id)),
              theme: NodeFlowTheme.light,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Node should be rendered
      expect(find.text('ports-node'), findsOneWidget);
    });

    testWidgets('custom port builder is used when provided', (tester) async {
      final node = createTestNodeWithPorts(id: 'custom-ports-node');
      controller.addNode(node);

      var customPortBuilderCalled = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: NodeFlowEditor<String, dynamic>(
              controller: controller,
              nodeBuilder: (context, node) => SizedBox(width: 100, height: 60),
              portBuilder: (context, node, port) {
                customPortBuilderCalled = true;
                // Use helper methods to derive isOutput if needed:
                // final isOutput = node.isOutputPort(port);
                return Container(
                  key: ValueKey('port-${port.id}'),
                  width: 12,
                  height: 12,
                  color: Colors.red,
                );
              },
              theme: NodeFlowTheme.light,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(customPortBuilderCalled, isTrue);
    });
  });

  group('NodeWidget - Selection State', () {
    testWidgets('selection state changes update node appearance', (
      tester,
    ) async {
      final node = createTestNode(id: 'select-node');
      controller.addNode(node);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: NodeFlowEditor<String, dynamic>(
              controller: controller,
              nodeBuilder: (context, node) => SizedBox(
                key: const ValueKey('node-content'),
                width: 100,
                height: 60,
                child: Text(node.isSelected ? 'Selected' : 'Not Selected'),
              ),
              theme: NodeFlowTheme.light,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();
      expect(find.text('Not Selected'), findsOneWidget);

      // Select node
      controller.selectNode('select-node');

      await tester.pumpAndSettle();

      expect(find.text('Selected'), findsOneWidget);
    });
  });

  group('NodeWidget - Position Updates', () {
    testWidgets('node position changes update widget', (tester) async {
      final node = createTestNode(
        id: 'move-node',
        position: const Offset(100, 100),
      );
      controller.addNode(node);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 800,
              height: 600,
              child: NodeFlowEditor<String, dynamic>(
                controller: controller,
                nodeBuilder: (context, node) => SizedBox(
                  width: 100,
                  height: 60,
                  child: Text(
                    'Pos: ${node.position.value.dx.toInt()},${node.position.value.dy.toInt()}',
                  ),
                ),
                theme: NodeFlowTheme.light,
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();
      expect(find.text('Pos: 100,100'), findsOneWidget);

      // Move node
      controller.moveNode('move-node', const Offset(50, 50));

      await tester.pumpAndSettle();

      expect(find.text('Pos: 150,150'), findsOneWidget);
    });
  });

  group('NodeWidget - Size Updates', () {
    testWidgets('node size changes update widget', (tester) async {
      final node = createTestNode(id: 'size-node', size: const Size(100, 60));
      controller.addNode(node);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 800,
              height: 600,
              child: NodeFlowEditor<String, dynamic>(
                controller: controller,
                nodeBuilder: (context, node) => Text(
                  'Size: ${node.size.value.width.toInt()}x${node.size.value.height.toInt()}',
                ),
                theme: NodeFlowTheme.light,
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();
      expect(find.text('Size: 100x60'), findsOneWidget);

      // Change size
      controller.setNodeSize('size-node', const Size(200, 120));

      await tester.pumpAndSettle();

      expect(find.text('Size: 200x120'), findsOneWidget);
    });
  });

  group('NodeWidget - ZIndex and Ordering', () {
    testWidgets('z-index changes reflect in ordering', (tester) async {
      final node1 = createTestNode(id: 'node-1', zIndex: 0);
      final node2 = createTestNode(id: 'node-2', zIndex: 1);
      controller.addNode(node1);
      controller.addNode(node2);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: NodeFlowEditor<String, dynamic>(
              controller: controller,
              nodeBuilder: (context, node) => Container(
                key: ValueKey(node.id),
                child: Text('${node.id}: z=${node.zIndex.value}'),
              ),
              theme: NodeFlowTheme.light,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('node-1: z=0'), findsOneWidget);
      expect(find.text('node-2: z=1'), findsOneWidget);

      // Bring node-1 to front
      controller.bringNodeToFront('node-1');

      await tester.pumpAndSettle();

      // node-1 should now have higher z-index
      final updatedNode1 = controller.getNode('node-1')!;
      final updatedNode2 = controller.getNode('node-2')!;
      expect(updatedNode1.zIndex.value, greaterThan(updatedNode2.zIndex.value));
    });
  });

  group('NodeWidget - Drag State', () {
    testWidgets('dragging state changes update node', (tester) async {
      final node = createTestNode(id: 'drag-node');
      controller.addNode(node);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: NodeFlowEditor<String, dynamic>(
              controller: controller,
              nodeBuilder: (context, node) => SizedBox(
                width: 100,
                height: 60,
                child: Text(node.dragging.value ? 'Dragging' : 'Not Dragging'),
              ),
              theme: NodeFlowTheme.light,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();
      expect(find.text('Not Dragging'), findsOneWidget);

      // Start drag
      controller.startNodeDrag('drag-node');

      await tester.pumpAndSettle();

      expect(find.text('Dragging'), findsOneWidget);

      // End drag
      controller.endNodeDrag();

      await tester.pumpAndSettle();

      expect(find.text('Not Dragging'), findsOneWidget);
    });
  });

  group('NodeWidget - Node Data Access', () {
    testWidgets('node data is accessible in builder', (tester) async {
      final node = Node<String>(
        id: 'data-node',
        type: 'custom',
        position: const Offset(0, 0),
        size: const Size(100, 60),
        data: 'My Custom Data',
      );
      controller.addNode(node);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: NodeFlowEditor<String, dynamic>(
              controller: controller,
              nodeBuilder: (context, node) => Text('Data: ${node.data}'),
              theme: NodeFlowTheme.light,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Data: My Custom Data'), findsOneWidget);
    });
  });

  group('NodeWidget - Multiple Nodes', () {
    testWidgets('multiple nodes render correctly', (tester) async {
      for (var i = 0; i < 10; i++) {
        controller.addNode(
          createTestNode(
            id: 'multi-$i',
            position: Offset(i * 120.0, (i % 3) * 80.0),
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
                nodeBuilder: (context, node) => SizedBox(
                  key: ValueKey(node.id),
                  width: 100,
                  height: 60,
                  child: Text(node.id),
                ),
                theme: NodeFlowTheme.light,
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // All nodes should be rendered
      for (var i = 0; i < 10; i++) {
        expect(find.text('multi-$i'), findsOneWidget);
      }
    });
  });

  group('NodeWidget - Shape Nodes', () {
    testWidgets('editor with custom node shape builder', (tester) async {
      final node = createTestNode(id: 'shaped-node');
      controller.addNode(node);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: NodeFlowEditor<String, dynamic>(
              controller: controller,
              nodeBuilder: (context, node) => Text(node.id),
              nodeShapeBuilder: (context, node) {
                // Return a circle shape
                return CircleShape(
                  fillColor: Colors.blue.shade100,
                  strokeColor: Colors.blue,
                  strokeWidth: 2.0,
                );
              },
              theme: NodeFlowTheme.light,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Node should render
      expect(find.text('shaped-node'), findsOneWidget);
    });
  });
}
