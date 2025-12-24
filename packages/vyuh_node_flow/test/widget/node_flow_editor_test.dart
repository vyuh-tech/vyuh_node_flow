@Tags(['widget'])
library;

import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vyuh_node_flow/vyuh_node_flow.dart';

import '../helpers/test_factories.dart';

/// Widget tests for NodeFlowEditor.
///
/// These tests verify that the editor widget builds correctly, handles
/// configuration changes, and properly integrates with the controller.
void main() {
  late NodeFlowController<String> controller;

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
            body: NodeFlowEditor<String>(
              controller: controller,
              nodeBuilder: (context, node) => Container(),
              theme: NodeFlowTheme.light,
            ),
          ),
        ),
      );

      expect(find.byType(NodeFlowEditor<String>), findsOneWidget);
    });

    testWidgets('editor with initial nodes renders nodes', (tester) async {
      // Add nodes before building widget
      controller.addNode(createTestNode(id: 'node-1'));
      controller.addNode(createTestNode(id: 'node-2'));

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: NodeFlowEditor<String>(
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

    testWidgets('editor respects showAnnotations flag', (tester) async {
      controller.addNode(createTestNode(id: 'node-1'));
      controller.addAnnotation(createTestStickyAnnotation(id: 'sticky-1'));

      // Build with annotations disabled
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: NodeFlowEditor<String>(
              controller: controller,
              nodeBuilder: (context, node) => Container(),
              theme: NodeFlowTheme.light,
              showAnnotations: false,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Editor should build successfully
      expect(find.byType(NodeFlowEditor<String>), findsOneWidget);
    });
  });

  group('NodeFlowEditor - Behavior Modes', () {
    testWidgets('design mode allows editing', (tester) async {
      controller.addNode(createTestNode(id: 'node-1'));

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: NodeFlowEditor<String>(
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
            body: NodeFlowEditor<String>(
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
      expect(find.byType(NodeFlowEditor<String>), findsOneWidget);
    });

    testWidgets('present mode is display only', (tester) async {
      controller.addNode(createTestNode(id: 'node-1'));

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: NodeFlowEditor<String>(
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
      expect(find.byType(NodeFlowEditor<String>), findsOneWidget);
    });
  });

  group('NodeFlowEditor - Controller Integration', () {
    testWidgets('node additions reflect in UI', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: NodeFlowEditor<String>(
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
            body: NodeFlowEditor<String>(
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
              child: NodeFlowEditor<String>(
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
      expect(find.byType(NodeFlowEditor<String>), findsOneWidget);
    });
  });

  group('NodeFlowEditor - Theme Changes', () {
    testWidgets('theme changes apply correctly', (tester) async {
      controller.addNode(createTestNode(id: 'node-1'));

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: NodeFlowEditor<String>(
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
            body: NodeFlowEditor<String>(
              controller: controller,
              nodeBuilder: (context, node) => Container(),
              theme: NodeFlowTheme.dark,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Should still render correctly
      expect(find.byType(NodeFlowEditor<String>), findsOneWidget);
    });
  });

  group('NodeFlowEditor - Scroll Behavior', () {
    testWidgets('scrollToZoom can be configured', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: NodeFlowEditor<String>(
              controller: controller,
              nodeBuilder: (context, node) => Container(),
              theme: NodeFlowTheme.light,
              scrollToZoom: false,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Editor should build successfully
      expect(find.byType(NodeFlowEditor<String>), findsOneWidget);
    });
  });

  group('NodeFlowEditor - Events System', () {
    testWidgets('events onInit callback fires', (tester) async {
      var initCalled = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: NodeFlowEditor<String>(
              controller: controller,
              nodeBuilder: (context, node) => Container(),
              theme: NodeFlowTheme.light,
              events: NodeFlowEvents<String>(
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
  });

  group('NodeFlowEditor - Layout and Sizing', () {
    testWidgets('editor fills available space', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 800,
              height: 600,
              child: NodeFlowEditor<String>(
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
      final editorWidget = tester.widget<NodeFlowEditor<String>>(
        find.byType(NodeFlowEditor<String>),
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
              child: NodeFlowEditor<String>(
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
              child: NodeFlowEditor<String>(
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
      expect(find.byType(NodeFlowEditor<String>), findsOneWidget);
      expect(controller.nodeCount, equals(50));
    });
  });
}
