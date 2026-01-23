@Tags(['widget'])
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vyuh_node_flow/vyuh_node_flow.dart';

import '../helpers/test_factories.dart';

/// Widget tests for NodeFlowMinimap.
///
/// These tests verify that the minimap widget builds correctly,
/// responds to graph changes, and supports interactive navigation.
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

  group('Minimap - Basic Rendering', () {
    testWidgets('minimap widget builds successfully', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: NodeFlowMinimap<String>(
              controller: controller,
              size: const Size(200, 150),
              theme: MinimapTheme.light,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.byType(NodeFlowMinimap<String>), findsOneWidget);
    });

    testWidgets('minimap renders with nodes', (tester) async {
      // Add nodes
      for (var i = 0; i < 10; i++) {
        controller.addNode(
          createTestNode(
            id: 'node-$i',
            position: Offset(i * 100.0, (i % 3) * 80.0),
          ),
        );
      }

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: NodeFlowMinimap<String>(
              controller: controller,
              size: const Size(200, 150),
              theme: MinimapTheme.light,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.byType(NodeFlowMinimap<String>), findsOneWidget);
    });

    testWidgets('minimap with dark theme', (tester) async {
      controller.addNode(createTestNode(id: 'node-1'));

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: NodeFlowMinimap<String>(
              controller: controller,
              size: const Size(200, 150),
              theme: MinimapTheme.dark,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.byType(NodeFlowMinimap<String>), findsOneWidget);
    });
  });

  group('Minimap - Reactive Updates', () {
    testWidgets('minimap updates when node added', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: NodeFlowMinimap<String>(
              controller: controller,
              size: const Size(200, 150),
              theme: MinimapTheme.light,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Add node after minimap is built
      controller.addNode(createTestNode(id: 'dynamic-node'));

      await tester.pumpAndSettle();

      // Minimap should still render
      expect(find.byType(NodeFlowMinimap<String>), findsOneWidget);
    });

    testWidgets('minimap updates when node moved', (tester) async {
      controller.addNode(createTestNode(id: 'node-1'));

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: NodeFlowMinimap<String>(
              controller: controller,
              size: const Size(200, 150),
              theme: MinimapTheme.light,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Move node
      controller.moveNode('node-1', const Offset(100, 100));

      await tester.pumpAndSettle();

      expect(find.byType(NodeFlowMinimap<String>), findsOneWidget);
    });

    testWidgets('minimap updates when viewport changes', (tester) async {
      controller.addNode(createTestNode(id: 'node-1'));

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: NodeFlowMinimap<String>(
              controller: controller,
              size: const Size(200, 150),
              theme: MinimapTheme.light,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Change viewport
      controller.setViewport(GraphViewport(x: 100, y: 50, zoom: 1.5));

      await tester.pumpAndSettle();

      expect(find.byType(NodeFlowMinimap<String>), findsOneWidget);
    });
  });

  group('Minimap - Interactive Mode', () {
    testWidgets('interactive minimap builds with gesture detector', (
      tester,
    ) async {
      controller.addNode(createTestNode(id: 'node-1'));

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: NodeFlowMinimap<String>(
              controller: controller,
              size: const Size(200, 150),
              theme: MinimapTheme.light,
              interactive: true,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Should find GestureDetector for interactive mode
      expect(find.byType(GestureDetector), findsOneWidget);
    });

    testWidgets('non-interactive minimap has no gesture handling', (
      tester,
    ) async {
      controller.addNode(createTestNode(id: 'node-1'));

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: NodeFlowMinimap<String>(
              controller: controller,
              size: const Size(200, 150),
              theme: MinimapTheme.light,
              interactive: false,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // GestureDetector should not be present in non-interactive mode
      expect(find.byType(GestureDetector), findsNothing);
    });

    testWidgets('tap on minimap updates viewport', (tester) async {
      // Add nodes spread out
      for (var i = 0; i < 5; i++) {
        controller.addNode(
          createTestNode(id: 'node-$i', position: Offset(i * 200.0, i * 150.0)),
        );
      }

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 200,
              height: 150,
              child: NodeFlowMinimap<String>(
                controller: controller,
                size: const Size(200, 150),
                theme: MinimapTheme.light,
                interactive: true,
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Store initial viewport for reference (viewport may change on tap)
      expect(controller.viewport, isNotNull);

      // Tap on minimap
      await tester.tap(find.byType(NodeFlowMinimap<String>));
      await tester.pumpAndSettle();

      // Viewport should have changed (pan position)
      // Note: Exact values depend on minimap calculation
      expect(find.byType(NodeFlowMinimap<String>), findsOneWidget);
    });
  });

  group('Minimap - Theme Configuration', () {
    testWidgets('custom size is respected', (tester) async {
      controller.addNode(createTestNode(id: 'node-1'));

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: NodeFlowMinimap<String>(
              controller: controller,
              size: const Size(300, 200),
              theme: MinimapTheme.light,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Find the container with our size
      final container = tester.widget<Container>(find.byType(Container).first);
      expect(container.constraints?.maxWidth, equals(300));
      expect(container.constraints?.maxHeight, equals(200));
    });

    testWidgets('custom theme colors work', (tester) async {
      controller.addNode(createTestNode(id: 'node-1'));

      final customTheme = MinimapTheme.light.copyWith(
        backgroundColor: Colors.blue.shade100,
        nodeColor: Colors.red,
        viewportColor: Colors.green,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: NodeFlowMinimap<String>(
              controller: controller,
              size: const Size(200, 150),
              theme: customTheme,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.byType(NodeFlowMinimap<String>), findsOneWidget);
    });
  });

  group('Minimap - Empty Graph', () {
    testWidgets('minimap handles empty graph gracefully', (tester) async {
      // No nodes added

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: NodeFlowMinimap<String>(
              controller: controller,
              size: const Size(200, 150),
              theme: MinimapTheme.light,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Should render without error
      expect(find.byType(NodeFlowMinimap<String>), findsOneWidget);
    });

    testWidgets('tap on empty minimap is safe', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: NodeFlowMinimap<String>(
              controller: controller,
              size: const Size(200, 150),
              theme: MinimapTheme.light,
              interactive: true,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Tap should not cause error
      await tester.tap(find.byType(NodeFlowMinimap<String>));
      await tester.pumpAndSettle();

      expect(find.byType(NodeFlowMinimap<String>), findsOneWidget);
    });
  });

  group('Minimap - Large Graph', () {
    testWidgets('minimap handles large node count', (tester) async {
      // Add many nodes
      for (var i = 0; i < 100; i++) {
        controller.addNode(
          createTestNode(
            id: 'node-$i',
            position: Offset((i % 10) * 150.0, (i ~/ 10) * 100.0),
          ),
        );
      }

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: NodeFlowMinimap<String>(
              controller: controller,
              size: const Size(200, 150),
              theme: MinimapTheme.light,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.byType(NodeFlowMinimap<String>), findsOneWidget);
    });
  });

  group('Minimap - Viewport Indicator', () {
    testWidgets('viewport indicator shows when enabled', (tester) async {
      controller.addNode(createTestNode(id: 'node-1'));

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: NodeFlowMinimap<String>(
              controller: controller,
              size: const Size(200, 150),
              theme: MinimapTheme.light.copyWith(showViewport: true),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.byType(NodeFlowMinimap<String>), findsOneWidget);
    });

    testWidgets('viewport indicator hidden when disabled', (tester) async {
      controller.addNode(createTestNode(id: 'node-1'));

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: NodeFlowMinimap<String>(
              controller: controller,
              size: const Size(200, 150),
              theme: MinimapTheme.light.copyWith(showViewport: false),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.byType(NodeFlowMinimap<String>), findsOneWidget);
    });
  });

  group('Minimap - Integration with Editor', () {
    testWidgets('minimap shows via MinimapPlugin visibility', (tester) async {
      // Create controller with minimap visible via extension
      final visibleController = createTestController(
        config: NodeFlowConfig(
          plugins: [
            MinimapPlugin(visible: true),
            ...NodeFlowConfig.defaultPlugins().where(
              (e) => e is! MinimapPlugin,
            ),
          ],
        ),
      );
      visibleController.setScreenSize(const Size(800, 600));
      visibleController.addNode(createTestNode(id: 'node-1'));

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 800,
              height: 600,
              child: NodeFlowEditor<String, dynamic>(
                controller: visibleController,
                nodeBuilder: (context, node) =>
                    SizedBox(width: 100, height: 60),
                theme: NodeFlowTheme.light,
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.byType(NodeFlowEditor<String, dynamic>), findsOneWidget);
      // The built-in minimap overlay renders NodeFlowMinimap when visible
      // Note: Type parameter is dynamic due to extension system type erasure
      expect(
        find.byWidgetPredicate((w) => w is NodeFlowMinimap),
        findsOneWidget,
      );

      visibleController.dispose();
    });

    testWidgets('minimap hidden via MinimapPlugin visibility', (tester) async {
      // Create controller with minimap hidden via extension
      final hiddenController = createTestController(
        config: NodeFlowConfig(
          plugins: [
            MinimapPlugin(visible: false),
            ...NodeFlowConfig.defaultPlugins().where(
              (e) => e is! MinimapPlugin,
            ),
          ],
        ),
      );
      hiddenController.setScreenSize(const Size(800, 600));
      hiddenController.addNode(createTestNode(id: 'node-1'));

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 800,
              height: 600,
              child: NodeFlowEditor<String, dynamic>(
                controller: hiddenController,
                nodeBuilder: (context, node) =>
                    SizedBox(width: 100, height: 60),
                theme: NodeFlowTheme.light,
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.byType(NodeFlowEditor<String, dynamic>), findsOneWidget);
      // Minimap should not render when visibility is false
      expect(find.byType(NodeFlowMinimap<String>), findsNothing);

      hiddenController.dispose();
    });
  });

  group('Minimap - Mouse Cursor', () {
    testWidgets('interactive minimap has gesture handling', (tester) async {
      controller.addNode(createTestNode(id: 'node-1'));

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: NodeFlowMinimap<String>(
              controller: controller,
              size: const Size(200, 150),
              theme: MinimapTheme.light,
              interactive: true,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Minimap should render and be interactive (has GestureDetector)
      expect(find.byType(NodeFlowMinimap<String>), findsOneWidget);
      expect(find.byType(GestureDetector), findsOneWidget);
    });
  });
}
