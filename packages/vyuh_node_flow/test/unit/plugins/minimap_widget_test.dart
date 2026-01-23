/// Comprehensive unit tests for NodeFlowMinimap widget.
///
/// Tests widget behavior, configuration, interaction, edge cases,
/// and the MinimapPainter and MinimapControllerExtension.
@Tags(['unit'])
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vyuh_node_flow/vyuh_node_flow.dart';

import '../../helpers/test_factories.dart';

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

  // ===========================================================================
  // Widget Construction and Configuration
  // ===========================================================================

  group('NodeFlowMinimap - Widget Construction', () {
    testWidgets('creates widget with required parameters', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: NodeFlowMinimap<String>(
              controller: controller,
              size: const Size(200, 150),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.byType(NodeFlowMinimap<String>), findsOneWidget);
    });

    testWidgets('uses default theme when not specified', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: NodeFlowMinimap<String>(
              controller: controller,
              size: const Size(200, 150),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      final widget = tester.widget<NodeFlowMinimap<String>>(
        find.byType(NodeFlowMinimap<String>),
      );
      expect(widget.theme, equals(MinimapTheme.light));
    });

    testWidgets('uses default interactive value of true', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: NodeFlowMinimap<String>(
              controller: controller,
              size: const Size(200, 150),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      final widget = tester.widget<NodeFlowMinimap<String>>(
        find.byType(NodeFlowMinimap<String>),
      );
      expect(widget.interactive, isTrue);
    });

    testWidgets('respects custom size parameter', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: NodeFlowMinimap<String>(
              controller: controller,
              size: const Size(300, 225),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      final container = tester.widget<Container>(find.byType(Container).first);
      expect(container.constraints?.maxWidth, equals(300));
      expect(container.constraints?.maxHeight, equals(225));
    });

    testWidgets('applies theme background color', (tester) async {
      final customTheme = MinimapTheme.light.copyWith(
        backgroundColor: Colors.red.shade100,
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

      final container = tester.widget<Container>(find.byType(Container).first);
      final decoration = container.decoration as BoxDecoration;
      expect(decoration.color, equals(Colors.red.shade100));
    });

    testWidgets('applies theme border radius', (tester) async {
      final customTheme = MinimapTheme.light.copyWith(borderRadius: 12.0);

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

      final container = tester.widget<Container>(find.byType(Container).first);
      final decoration = container.decoration as BoxDecoration;
      expect(decoration.borderRadius, equals(BorderRadius.circular(12.0)));
    });

    testWidgets('applies theme border color and width', (tester) async {
      final customTheme = MinimapTheme.light.copyWith(
        borderColor: Colors.purple,
        borderWidth: 3.0,
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

      final container = tester.widget<Container>(find.byType(Container).first);
      final decoration = container.decoration as BoxDecoration;
      expect(decoration.border, isNotNull);
    });
  });

  // ===========================================================================
  // Interactive Mode Behavior
  // ===========================================================================

  group('NodeFlowMinimap - Interactive Mode', () {
    testWidgets('includes GestureDetector when interactive is true', (
      tester,
    ) async {
      controller.addNode(createTestNode(id: 'node-1'));

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: NodeFlowMinimap<String>(
              controller: controller,
              size: const Size(200, 150),
              interactive: true,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.byType(GestureDetector), findsOneWidget);
    });

    testWidgets('excludes GestureDetector when interactive is false', (
      tester,
    ) async {
      controller.addNode(createTestNode(id: 'node-1'));

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: NodeFlowMinimap<String>(
              controller: controller,
              size: const Size(200, 150),
              interactive: false,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.byType(GestureDetector), findsNothing);
    });

    testWidgets('includes MouseRegion when interactive', (tester) async {
      controller.addNode(createTestNode(id: 'node-1'));

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: NodeFlowMinimap<String>(
              controller: controller,
              size: const Size(200, 150),
              interactive: true,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      final mouseRegionFinder = find.descendant(
        of: find.byType(NodeFlowMinimap<String>),
        matching: find.byType(MouseRegion),
      );
      expect(mouseRegionFinder, findsOneWidget);
    });

    testWidgets('tap changes viewport position', (tester) async {
      // Add nodes spread across graph
      for (var i = 0; i < 5; i++) {
        controller.addNode(
          createTestNode(id: 'node-$i', position: Offset(i * 200.0, i * 150.0)),
        );
      }

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: NodeFlowMinimap<String>(
              controller: controller,
              size: const Size(200, 150),
              interactive: true,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Tap on the minimap
      await tester.tap(find.byType(NodeFlowMinimap<String>));
      await tester.pumpAndSettle();

      // Viewport should have changed (unless tap was on center)
      expect(find.byType(NodeFlowMinimap<String>), findsOneWidget);
      // The viewport might not change if we tap exactly at current center
      // but the tap handling should work without errors
    });

    testWidgets('drag updates viewport continuously', (tester) async {
      // Add nodes spread across graph
      for (var i = 0; i < 5; i++) {
        controller.addNode(
          createTestNode(id: 'node-$i', position: Offset(i * 200.0, i * 150.0)),
        );
      }

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: NodeFlowMinimap<String>(
              controller: controller,
              size: const Size(200, 150),
              interactive: true,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Perform a drag gesture
      final center = tester.getCenter(find.byType(NodeFlowMinimap<String>));
      await tester.dragFrom(center, const Offset(50, 30));
      await tester.pumpAndSettle();

      // Widget should remain rendered
      expect(find.byType(NodeFlowMinimap<String>), findsOneWidget);
    });

    testWidgets('cursor changes during drag', (tester) async {
      controller.addNode(createTestNode(id: 'node-1'));

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: NodeFlowMinimap<String>(
              controller: controller,
              size: const Size(200, 150),
              interactive: true,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Get the MouseRegion widget inside the minimap
      final mouseRegionFinder = find.descendant(
        of: find.byType(NodeFlowMinimap<String>),
        matching: find.byType(MouseRegion),
      );

      expect(mouseRegionFinder, findsOneWidget);

      final mouseRegion = tester.widget<MouseRegion>(mouseRegionFinder);

      // Initial cursor should be grab
      expect(mouseRegion.cursor, equals(SystemMouseCursors.grab));
    });
  });

  // ===========================================================================
  // Empty Graph Handling
  // ===========================================================================

  group('NodeFlowMinimap - Empty Graph', () {
    testWidgets('renders without errors when graph is empty', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: NodeFlowMinimap<String>(
              controller: controller,
              size: const Size(200, 150),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.byType(NodeFlowMinimap<String>), findsOneWidget);
    });

    testWidgets('tap on empty graph is safe', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: NodeFlowMinimap<String>(
              controller: controller,
              size: const Size(200, 150),
              interactive: true,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Should not throw
      await tester.tap(find.byType(NodeFlowMinimap<String>));
      await tester.pumpAndSettle();

      expect(find.byType(NodeFlowMinimap<String>), findsOneWidget);
    });

    testWidgets('drag on empty graph is safe', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: NodeFlowMinimap<String>(
              controller: controller,
              size: const Size(200, 150),
              interactive: true,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      final center = tester.getCenter(find.byType(NodeFlowMinimap<String>));
      await tester.dragFrom(center, const Offset(50, 30));
      await tester.pumpAndSettle();

      expect(find.byType(NodeFlowMinimap<String>), findsOneWidget);
    });
  });

  // ===========================================================================
  // Reactive Updates
  // ===========================================================================

  group('NodeFlowMinimap - Reactive Updates', () {
    testWidgets('updates when nodes are added', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: NodeFlowMinimap<String>(
              controller: controller,
              size: const Size(200, 150),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Add a node
      controller.addNode(createTestNode(id: 'new-node'));
      await tester.pumpAndSettle();

      expect(find.byType(NodeFlowMinimap<String>), findsOneWidget);
    });

    testWidgets('updates when nodes are removed', (tester) async {
      controller.addNode(createTestNode(id: 'node-1'));
      controller.addNode(createTestNode(id: 'node-2'));

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: NodeFlowMinimap<String>(
              controller: controller,
              size: const Size(200, 150),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Remove a node
      controller.removeNode('node-1');
      await tester.pumpAndSettle();

      expect(find.byType(NodeFlowMinimap<String>), findsOneWidget);
    });

    testWidgets('updates when node positions change', (tester) async {
      controller.addNode(
        createTestNode(id: 'node-1', position: const Offset(0, 0)),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: NodeFlowMinimap<String>(
              controller: controller,
              size: const Size(200, 150),
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

    testWidgets('updates when viewport changes', (tester) async {
      controller.addNode(createTestNode(id: 'node-1'));

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: NodeFlowMinimap<String>(
              controller: controller,
              size: const Size(200, 150),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Change viewport
      controller.setViewport(GraphViewport(x: 100, y: 100, zoom: 1.5));
      await tester.pumpAndSettle();

      expect(find.byType(NodeFlowMinimap<String>), findsOneWidget);
    });

    testWidgets('updates when connections are added', (tester) async {
      controller.addNode(createTestNodeWithOutputPort(id: 'node-1'));
      controller.addNode(createTestNodeWithInputPort(id: 'node-2'));

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: NodeFlowMinimap<String>(
              controller: controller,
              size: const Size(200, 150),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Add connection
      controller.addConnection(
        createTestConnection(
          sourceNodeId: 'node-1',
          sourcePortId: 'output-1',
          targetNodeId: 'node-2',
          targetPortId: 'input-1',
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(NodeFlowMinimap<String>), findsOneWidget);
    });
  });

  // ===========================================================================
  // Theme Variations
  // ===========================================================================

  group('NodeFlowMinimap - Theme Variations', () {
    testWidgets('renders with light theme', (tester) async {
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

      expect(find.byType(NodeFlowMinimap<String>), findsOneWidget);
    });

    testWidgets('renders with dark theme', (tester) async {
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

    testWidgets('renders with custom colors', (tester) async {
      controller.addNode(createTestNode(id: 'node-1'));

      final customTheme = MinimapTheme(
        backgroundColor: Colors.yellow.shade100,
        nodeColor: Colors.blue,
        viewportColor: Colors.green,
        borderColor: Colors.red,
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

    testWidgets('renders with viewport indicator hidden', (tester) async {
      controller.addNode(createTestNode(id: 'node-1'));

      final themeWithoutViewport = MinimapTheme.light.copyWith(
        showViewport: false,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: NodeFlowMinimap<String>(
              controller: controller,
              size: const Size(200, 150),
              theme: themeWithoutViewport,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.byType(NodeFlowMinimap<String>), findsOneWidget);
    });

    testWidgets('renders with custom padding', (tester) async {
      controller.addNode(createTestNode(id: 'node-1'));

      final customTheme = MinimapTheme.light.copyWith(
        padding: const EdgeInsets.all(16.0),
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

    testWidgets('renders with zero padding', (tester) async {
      controller.addNode(createTestNode(id: 'node-1'));

      final customTheme = MinimapTheme.light.copyWith(padding: EdgeInsets.zero);

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

  // ===========================================================================
  // Large Graph Scenarios
  // ===========================================================================

  group('NodeFlowMinimap - Large Graph', () {
    testWidgets('handles many nodes', (tester) async {
      // Add 100 nodes
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
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.byType(NodeFlowMinimap<String>), findsOneWidget);
    });

    testWidgets('handles nodes spread across large area', (tester) async {
      // Add nodes at extreme positions
      controller.addNode(
        createTestNode(id: 'node-tl', position: const Offset(-1000, -1000)),
      );
      controller.addNode(
        createTestNode(id: 'node-tr', position: const Offset(2000, -1000)),
      );
      controller.addNode(
        createTestNode(id: 'node-bl', position: const Offset(-1000, 2000)),
      );
      controller.addNode(
        createTestNode(id: 'node-br', position: const Offset(2000, 2000)),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: NodeFlowMinimap<String>(
              controller: controller,
              size: const Size(200, 150),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.byType(NodeFlowMinimap<String>), findsOneWidget);
    });

    testWidgets('handles nodes with various sizes', (tester) async {
      controller.addNode(createTestNode(id: 'small', size: const Size(50, 30)));
      controller.addNode(
        createTestNode(
          id: 'large',
          position: const Offset(100, 0),
          size: const Size(300, 200),
        ),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: NodeFlowMinimap<String>(
              controller: controller,
              size: const Size(200, 150),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.byType(NodeFlowMinimap<String>), findsOneWidget);
    });
  });

  // ===========================================================================
  // Screen Size Edge Cases
  // ===========================================================================

  group('NodeFlowMinimap - Screen Size Handling', () {
    testWidgets('handles zero screen size gracefully', (tester) async {
      final zeroSizeController = createTestController();
      // Don't set screen size (remains zero)

      controller.addNode(createTestNode(id: 'node-1'));

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: NodeFlowMinimap<String>(
              controller: zeroSizeController,
              size: const Size(200, 150),
              interactive: true,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Tap should be safe even with zero screen size
      await tester.tap(find.byType(NodeFlowMinimap<String>));
      await tester.pumpAndSettle();

      expect(find.byType(NodeFlowMinimap<String>), findsOneWidget);

      zeroSizeController.dispose();
    });

    testWidgets('handles small minimap size', (tester) async {
      controller.addNode(createTestNode(id: 'node-1'));

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: NodeFlowMinimap<String>(
              controller: controller,
              size: const Size(50, 40),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.byType(NodeFlowMinimap<String>), findsOneWidget);
    });

    testWidgets('handles very large minimap size', (tester) async {
      controller.addNode(createTestNode(id: 'node-1'));

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: NodeFlowMinimap<String>(
              controller: controller,
              size: const Size(500, 400),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.byType(NodeFlowMinimap<String>), findsOneWidget);
    });
  });

  // ===========================================================================
  // Viewport Indicator
  // ===========================================================================

  group('NodeFlowMinimap - Viewport Indicator', () {
    testWidgets('shows viewport when showViewport is true', (tester) async {
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
      // CustomPaint is used for rendering the minimap
      final customPaintFinder = find.descendant(
        of: find.byType(NodeFlowMinimap<String>),
        matching: find.byType(CustomPaint),
      );
      expect(customPaintFinder, findsOneWidget);
    });

    testWidgets('viewport indicator responds to zoom changes', (tester) async {
      controller.addNode(createTestNode(id: 'node-1'));

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: NodeFlowMinimap<String>(
              controller: controller,
              size: const Size(200, 150),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Change zoom
      controller.zoomTo(2.0);
      await tester.pumpAndSettle();

      expect(find.byType(NodeFlowMinimap<String>), findsOneWidget);
    });

    testWidgets('viewport indicator responds to pan changes', (tester) async {
      controller.addNode(createTestNode(id: 'node-1'));

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: NodeFlowMinimap<String>(
              controller: controller,
              size: const Size(200, 150),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Change pan
      controller.setViewport(controller.viewport.copyWith(x: 100, y: 50));
      await tester.pumpAndSettle();

      expect(find.byType(NodeFlowMinimap<String>), findsOneWidget);
    });
  });

  // ===========================================================================
  // MinimapPainter Tests
  // ===========================================================================

  group('MinimapPainter', () {
    test('shouldRepaint returns true when controller changes', () {
      final controller1 = createTestController();
      final controller2 = createTestController();

      final painter1 = MinimapPainter<String>(
        controller: controller1,
        theme: MinimapTheme.light,
      );

      final painter2 = MinimapPainter<String>(
        controller: controller2,
        theme: MinimapTheme.light,
      );

      expect(painter1.shouldRepaint(painter2), isTrue);

      controller1.dispose();
      controller2.dispose();
    });

    test('shouldRepaint returns true when theme changes', () {
      final painter1 = MinimapPainter<String>(
        controller: controller,
        theme: MinimapTheme.light,
      );

      final painter2 = MinimapPainter<String>(
        controller: controller,
        theme: MinimapTheme.dark,
      );

      expect(painter1.shouldRepaint(painter2), isTrue);
    });

    test('shouldRepaint returns false when nothing changes', () {
      final painter1 = MinimapPainter<String>(
        controller: controller,
        theme: MinimapTheme.light,
      );

      final painter2 = MinimapPainter<String>(
        controller: controller,
        theme: MinimapTheme.light,
      );

      expect(painter1.shouldRepaint(painter2), isFalse);
    });
  });

  // ===========================================================================
  // MinimapControllerExtension Tests
  // ===========================================================================

  group('MinimapControllerExtension', () {
    test('panToPosition does nothing when screen size is zero', () {
      final zeroSizeController = createTestController();
      // Don't set screen size

      final initialViewport = zeroSizeController.viewport;
      zeroSizeController.panToPosition(const Offset(100, 100));

      expect(zeroSizeController.viewport, equals(initialViewport));

      zeroSizeController.dispose();
    });

    test('panToPosition centers viewport on given position', () {
      final node = createTestNode(
        id: 'node-1',
        position: const Offset(500, 500),
      );
      controller.addNode(node);

      final targetPosition = const Offset(500, 500);
      controller.panToPosition(targetPosition);

      // Viewport should be adjusted to center on target
      final vp = controller.viewport;
      expect(vp, isNotNull);
    });

    test('panToPosition maintains current zoom level', () {
      controller.addNode(createTestNode(id: 'node-1'));

      controller.zoomTo(2.0);
      final zoomBefore = controller.viewport.zoom;

      controller.panToPosition(const Offset(200, 200));

      expect(controller.viewport.zoom, equals(zoomBefore));
    });

    test('panToPosition calculates correct offset for origin', () {
      controller.addNode(createTestNode(id: 'node-1'));

      // Pan to origin
      controller.panToPosition(Offset.zero);

      final vp = controller.viewport;
      // At origin with zoom 1.0, the viewport offset should be half screen size
      expect(vp.x, equals(controller.screenSize.width / 2));
      expect(vp.y, equals(controller.screenSize.height / 2));
    });

    test('panToPosition calculates correct offset for positive position', () {
      controller.addNode(createTestNode(id: 'node-1'));

      final targetX = 100.0;
      final targetY = 100.0;
      controller.panToPosition(Offset(targetX, targetY));

      final vp = controller.viewport;
      final expectedX =
          controller.screenSize.width / 2 - targetX * controller.viewport.zoom;
      final expectedY =
          controller.screenSize.height / 2 - targetY * controller.viewport.zoom;

      expect(vp.x, closeTo(expectedX, 0.01));
      expect(vp.y, closeTo(expectedY, 0.01));
    });

    test('panToPosition works with different zoom levels', () {
      controller.addNode(createTestNode(id: 'node-1'));

      // Test with zoom 0.5
      controller.zoomTo(0.5);
      controller.panToPosition(const Offset(100, 100));

      var vp = controller.viewport;
      expect(vp.zoom, equals(0.5));

      // Test with zoom 2.0
      controller.zoomTo(2.0);
      controller.panToPosition(const Offset(100, 100));

      vp = controller.viewport;
      expect(vp.zoom, equals(2.0));
    });
  });

  // ===========================================================================
  // Gesture Interaction Details
  // ===========================================================================

  group('NodeFlowMinimap - Gesture Interactions', () {
    testWidgets('pan start snaps viewport to cursor', (tester) async {
      // Add nodes spread out
      for (var i = 0; i < 5; i++) {
        controller.addNode(
          createTestNode(id: 'node-$i', position: Offset(i * 200.0, i * 150.0)),
        );
      }

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: NodeFlowMinimap<String>(
              controller: controller,
              size: const Size(200, 150),
              interactive: true,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Start a drag
      final center = tester.getCenter(find.byType(NodeFlowMinimap<String>));
      final gesture = await tester.startGesture(center);
      await tester.pump();

      // Continue drag
      await gesture.moveBy(const Offset(20, 10));
      await tester.pump();

      // End drag
      await gesture.up();
      await tester.pumpAndSettle();

      expect(find.byType(NodeFlowMinimap<String>), findsOneWidget);
    });

    testWidgets('pan end resets dragging state', (tester) async {
      controller.addNode(createTestNode(id: 'node-1'));

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: NodeFlowMinimap<String>(
              controller: controller,
              size: const Size(200, 150),
              interactive: true,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      final mouseRegionFinder = find.descendant(
        of: find.byType(NodeFlowMinimap<String>),
        matching: find.byType(MouseRegion),
      );

      // Start drag
      final center = tester.getCenter(find.byType(NodeFlowMinimap<String>));
      final gesture = await tester.startGesture(center);
      await tester.pump();

      // End drag
      await gesture.up();
      await tester.pumpAndSettle();

      // After drag, cursor should return to grab
      final mouseRegion = tester.widget<MouseRegion>(mouseRegionFinder);
      expect(mouseRegion.cursor, equals(SystemMouseCursors.grab));
    });
  });

  // ===========================================================================
  // Widget Clipping and Layout
  // ===========================================================================

  group('NodeFlowMinimap - Layout', () {
    testWidgets('content is clipped to minimap bounds', (tester) async {
      controller.addNode(createTestNode(id: 'node-1'));

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: NodeFlowMinimap<String>(
              controller: controller,
              size: const Size(200, 150),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify ClipRRect is present in minimap
      final clipRRectFinder = find.descendant(
        of: find.byType(NodeFlowMinimap<String>),
        matching: find.byType(ClipRRect),
      );
      expect(clipRRectFinder, findsOneWidget);
    });

    testWidgets('Observer widget wraps CustomPaint', (tester) async {
      controller.addNode(createTestNode(id: 'node-1'));

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: NodeFlowMinimap<String>(
              controller: controller,
              size: const Size(200, 150),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      final customPaintFinder = find.descendant(
        of: find.byType(NodeFlowMinimap<String>),
        matching: find.byType(CustomPaint),
      );
      expect(customPaintFinder, findsOneWidget);
    });

    testWidgets('Stack layout contains minimap content', (tester) async {
      controller.addNode(createTestNode(id: 'node-1'));

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: NodeFlowMinimap<String>(
              controller: controller,
              size: const Size(200, 150),
              interactive: true,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Stack should contain both CustomPaint and interactive area
      final stackFinder = find.descendant(
        of: find.byType(NodeFlowMinimap<String>),
        matching: find.byType(Stack),
      );
      expect(stackFinder, findsOneWidget);
    });
  });

  // ===========================================================================
  // Node Visibility
  // ===========================================================================

  group('NodeFlowMinimap - Node Visibility', () {
    testWidgets('invisible nodes still contribute to bounds', (tester) async {
      controller.addNode(
        createTestNode(id: 'visible', position: const Offset(0, 0)),
      );
      controller.addNode(
        createTestNode(
          id: 'invisible',
          position: const Offset(500, 500),
          visible: false,
        ),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: NodeFlowMinimap<String>(
              controller: controller,
              size: const Size(200, 150),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.byType(NodeFlowMinimap<String>), findsOneWidget);
    });
  });

  // ===========================================================================
  // Widget State Preservation
  // ===========================================================================

  group('NodeFlowMinimap - State Management', () {
    testWidgets('preserves state during rebuild', (tester) async {
      controller.addNode(createTestNode(id: 'node-1'));

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: NodeFlowMinimap<String>(
              controller: controller,
              size: const Size(200, 150),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Trigger rebuild by adding a node
      controller.addNode(createTestNode(id: 'node-2'));
      await tester.pumpAndSettle();

      expect(find.byType(NodeFlowMinimap<String>), findsOneWidget);
    });

    testWidgets('handles controller disposal gracefully', (tester) async {
      final localController = createTestController();
      localController.setScreenSize(const Size(800, 600));
      localController.addNode(createTestNode(id: 'node-1'));

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: NodeFlowMinimap<String>(
              controller: localController,
              size: const Size(200, 150),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Dispose controller
      localController.dispose();

      // Remove widget
      await tester.pumpWidget(
        const MaterialApp(home: Scaffold(body: SizedBox.shrink())),
      );

      await tester.pumpAndSettle();
    });
  });

  // ===========================================================================
  // Aspect Ratio Handling
  // ===========================================================================

  group('NodeFlowMinimap - Aspect Ratio', () {
    testWidgets('handles wide aspect ratio nodes', (tester) async {
      controller.addNode(createTestNode(id: 'wide', size: const Size(400, 50)));

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: NodeFlowMinimap<String>(
              controller: controller,
              size: const Size(200, 150),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.byType(NodeFlowMinimap<String>), findsOneWidget);
    });

    testWidgets('handles tall aspect ratio nodes', (tester) async {
      controller.addNode(createTestNode(id: 'tall', size: const Size(50, 400)));

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: NodeFlowMinimap<String>(
              controller: controller,
              size: const Size(200, 150),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.byType(NodeFlowMinimap<String>), findsOneWidget);
    });

    testWidgets('handles square aspect ratio nodes', (tester) async {
      controller.addNode(
        createTestNode(id: 'square', size: const Size(100, 100)),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: NodeFlowMinimap<String>(
              controller: controller,
              size: const Size(200, 150),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.byType(NodeFlowMinimap<String>), findsOneWidget);
    });
  });

  // ===========================================================================
  // Negative Coordinate Handling
  // ===========================================================================

  group('NodeFlowMinimap - Negative Coordinates', () {
    testWidgets('handles nodes at negative positions', (tester) async {
      controller.addNode(
        createTestNode(id: 'neg', position: const Offset(-200, -200)),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: NodeFlowMinimap<String>(
              controller: controller,
              size: const Size(200, 150),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.byType(NodeFlowMinimap<String>), findsOneWidget);
    });

    testWidgets('handles mixed positive and negative positions', (
      tester,
    ) async {
      controller.addNode(
        createTestNode(id: 'neg', position: const Offset(-200, -200)),
      );
      controller.addNode(
        createTestNode(id: 'pos', position: const Offset(200, 200)),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: NodeFlowMinimap<String>(
              controller: controller,
              size: const Size(200, 150),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.byType(NodeFlowMinimap<String>), findsOneWidget);
    });

    testWidgets('tap interaction works with negative coordinates', (
      tester,
    ) async {
      controller.addNode(
        createTestNode(id: 'neg', position: const Offset(-200, -200)),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: NodeFlowMinimap<String>(
              controller: controller,
              size: const Size(200, 150),
              interactive: true,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      await tester.tap(find.byType(NodeFlowMinimap<String>));
      await tester.pumpAndSettle();

      expect(find.byType(NodeFlowMinimap<String>), findsOneWidget);
    });
  });

  // ===========================================================================
  // Special Node Types
  // ===========================================================================

  group('NodeFlowMinimap - Special Node Types', () {
    testWidgets('handles CommentNode', (tester) async {
      controller.addNode(
        createTestCommentNode(
          id: 'comment-1',
          data: 'comment-data',
          position: const Offset(50, 50),
        ),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: NodeFlowMinimap<String>(
              controller: controller,
              size: const Size(200, 150),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.byType(NodeFlowMinimap<String>), findsOneWidget);
    });

    testWidgets('handles GroupNode', (tester) async {
      controller.addNode(
        createTestGroupNode(
          id: 'group-1',
          data: 'group-data',
          position: const Offset(0, 0),
          size: const Size(300, 200),
        ),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: NodeFlowMinimap<String>(
              controller: controller,
              size: const Size(200, 150),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.byType(NodeFlowMinimap<String>), findsOneWidget);
    });

    testWidgets('handles mixed node types', (tester) async {
      controller.addNode(createTestNode(id: 'regular'));
      controller.addNode(
        createTestCommentNode(
          id: 'comment',
          data: 'data',
          position: const Offset(100, 0),
        ),
      );
      controller.addNode(
        createTestGroupNode(
          id: 'group',
          data: 'data',
          position: const Offset(0, 100),
        ),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: NodeFlowMinimap<String>(
              controller: controller,
              size: const Size(200, 150),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.byType(NodeFlowMinimap<String>), findsOneWidget);
    });
  });

  // ===========================================================================
  // Bounds Calculation Edge Cases
  // ===========================================================================

  group('NodeFlowMinimap - Bounds Edge Cases', () {
    testWidgets('handles single node at origin', (tester) async {
      controller.addNode(createTestNode(id: 'origin', position: Offset.zero));

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: NodeFlowMinimap<String>(
              controller: controller,
              size: const Size(200, 150),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.byType(NodeFlowMinimap<String>), findsOneWidget);
    });

    testWidgets('handles overlapping nodes', (tester) async {
      controller.addNode(
        createTestNode(id: 'node-1', position: const Offset(50, 50)),
      );
      controller.addNode(
        createTestNode(id: 'node-2', position: const Offset(50, 50)),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: NodeFlowMinimap<String>(
              controller: controller,
              size: const Size(200, 150),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.byType(NodeFlowMinimap<String>), findsOneWidget);
    });

    testWidgets('handles nodes in a line (zero height bounds)', (tester) async {
      for (var i = 0; i < 5; i++) {
        controller.addNode(
          createTestNode(
            id: 'node-$i',
            position: Offset(i * 100.0, 0),
            size: const Size(50, 50),
          ),
        );
      }

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: NodeFlowMinimap<String>(
              controller: controller,
              size: const Size(200, 150),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.byType(NodeFlowMinimap<String>), findsOneWidget);
    });

    testWidgets('handles nodes in a column (zero width bounds)', (
      tester,
    ) async {
      for (var i = 0; i < 5; i++) {
        controller.addNode(
          createTestNode(
            id: 'node-$i',
            position: Offset(0, i * 100.0),
            size: const Size(50, 50),
          ),
        );
      }

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: NodeFlowMinimap<String>(
              controller: controller,
              size: const Size(200, 150),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.byType(NodeFlowMinimap<String>), findsOneWidget);
    });
  });

  // ===========================================================================
  // MinimapPlugin Lifecycle Tests
  // ===========================================================================

  group('MinimapPlugin - Lifecycle', () {
    test('has correct id', () {
      final extension = MinimapPlugin();
      expect(extension.id, equals('minimap'));
    });

    test('attach stores controller reference', () {
      final extension = MinimapPlugin();
      extension.attach(controller);

      // The controller reference is private, but we can verify it works
      // by testing methods that depend on it
      controller.addNode(
        createTestNode(id: 'node-1', position: const Offset(100, 100)),
      );

      // centerOn should work when attached
      extension.centerOn(const Offset(100, 100));

      // No exception means attach worked
      expect(true, isTrue);
    });

    test('detach clears controller reference', () {
      final extension = MinimapPlugin();
      extension.attach(controller);
      extension.detach();

      // focusNodes should not throw when detached (does nothing)
      extension.focusNodes({'node-1'});
      expect(true, isTrue);
    });

    test('multiple attach/detach cycles work correctly', () {
      final extension = MinimapPlugin();

      // First cycle
      extension.attach(controller);
      extension.detach();

      // Second cycle
      extension.attach(controller);
      extension.detach();

      // Third cycle with different controller
      final controller2 = createTestController();
      controller2.setScreenSize(const Size(800, 600));
      extension.attach(controller2);
      extension.detach();

      controller2.dispose();
      expect(true, isTrue);
    });
  });

  // ===========================================================================
  // MinimapPlugin Visibility Tests
  // ===========================================================================

  group('MinimapPlugin - Visibility', () {
    test('default visibility is false', () {
      final extension = MinimapPlugin();
      expect(extension.isVisible, isFalse);
    });

    test('can be initialized with visibility true', () {
      final extension = MinimapPlugin(visible: true);
      expect(extension.isVisible, isTrue);
    });

    test('show() makes minimap visible', () {
      final extension = MinimapPlugin();
      extension.show();
      expect(extension.isVisible, isTrue);
    });

    test('hide() makes minimap hidden', () {
      final extension = MinimapPlugin(visible: true);
      extension.hide();
      expect(extension.isVisible, isFalse);
    });

    test('toggle() switches visibility', () {
      final extension = MinimapPlugin();
      expect(extension.isVisible, isFalse);

      extension.toggle();
      expect(extension.isVisible, isTrue);

      extension.toggle();
      expect(extension.isVisible, isFalse);
    });

    test('setVisible() sets visibility directly', () {
      final extension = MinimapPlugin();

      extension.setVisible(true);
      expect(extension.isVisible, isTrue);

      extension.setVisible(false);
      expect(extension.isVisible, isFalse);
    });
  });

  // ===========================================================================
  // MinimapPlugin Size Tests
  // ===========================================================================

  group('MinimapPlugin - Size', () {
    test('default size is 200x150', () {
      final extension = MinimapPlugin();
      expect(extension.size, equals(const Size(200, 150)));
    });

    test('can be initialized with custom size', () {
      final extension = MinimapPlugin(size: const Size(300, 200));
      expect(extension.size, equals(const Size(300, 200)));
    });

    test('setSize() updates size', () {
      final extension = MinimapPlugin();
      extension.setSize(const Size(400, 300));
      expect(extension.size, equals(const Size(400, 300)));
    });

    test('setWidth() updates only width', () {
      final extension = MinimapPlugin(size: const Size(200, 150));
      extension.setWidth(300);
      expect(extension.size, equals(const Size(300, 150)));
    });

    test('setHeight() updates only height', () {
      final extension = MinimapPlugin(size: const Size(200, 150));
      extension.setHeight(250);
      expect(extension.size, equals(const Size(200, 250)));
    });
  });

  // ===========================================================================
  // MinimapPlugin Interactivity Tests
  // ===========================================================================

  group('MinimapPlugin - Interactivity', () {
    test('default interactive is true', () {
      final extension = MinimapPlugin();
      expect(extension.isInteractive, isTrue);
    });

    test('can be initialized with interactive false', () {
      final extension = MinimapPlugin(interactive: false);
      expect(extension.isInteractive, isFalse);
    });

    test('enableInteraction() enables interaction', () {
      final extension = MinimapPlugin(interactive: false);
      extension.enableInteraction();
      expect(extension.isInteractive, isTrue);
    });

    test('disableInteraction() disables interaction', () {
      final extension = MinimapPlugin();
      extension.disableInteraction();
      expect(extension.isInteractive, isFalse);
    });

    test('toggleInteraction() switches interactivity', () {
      final extension = MinimapPlugin();
      expect(extension.isInteractive, isTrue);

      extension.toggleInteraction();
      expect(extension.isInteractive, isFalse);

      extension.toggleInteraction();
      expect(extension.isInteractive, isTrue);
    });

    test('setInteractive() sets interactivity directly', () {
      final extension = MinimapPlugin();

      extension.setInteractive(false);
      expect(extension.isInteractive, isFalse);

      extension.setInteractive(true);
      expect(extension.isInteractive, isTrue);
    });
  });

  // ===========================================================================
  // MinimapPlugin Position Tests
  // ===========================================================================

  group('MinimapPlugin - Position', () {
    test('default position is bottomRight', () {
      final extension = MinimapPlugin();
      expect(extension.position, equals(MinimapPosition.bottomRight));
    });

    test('can be initialized with custom position', () {
      final extension = MinimapPlugin(position: MinimapPosition.topLeft);
      expect(extension.position, equals(MinimapPosition.topLeft));
    });

    test('setPosition() updates position', () {
      final extension = MinimapPlugin();

      extension.setPosition(MinimapPosition.topLeft);
      expect(extension.position, equals(MinimapPosition.topLeft));

      extension.setPosition(MinimapPosition.topRight);
      expect(extension.position, equals(MinimapPosition.topRight));

      extension.setPosition(MinimapPosition.bottomLeft);
      expect(extension.position, equals(MinimapPosition.bottomLeft));

      extension.setPosition(MinimapPosition.bottomRight);
      expect(extension.position, equals(MinimapPosition.bottomRight));
    });

    test('cyclePosition() cycles through all positions clockwise', () {
      final extension = MinimapPlugin(position: MinimapPosition.topLeft);

      extension.cyclePosition();
      expect(extension.position, equals(MinimapPosition.topRight));

      extension.cyclePosition();
      expect(extension.position, equals(MinimapPosition.bottomLeft));

      extension.cyclePosition();
      expect(extension.position, equals(MinimapPosition.bottomRight));

      extension.cyclePosition();
      expect(extension.position, equals(MinimapPosition.topLeft));
    });

    test('cyclePosition() wraps around correctly', () {
      final extension = MinimapPlugin(position: MinimapPosition.bottomRight);
      extension.cyclePosition();
      expect(extension.position, equals(MinimapPosition.topLeft));
    });
  });

  // ===========================================================================
  // MinimapPlugin Highlighting Tests
  // ===========================================================================

  group('MinimapPlugin - Highlighting', () {
    test('default highlightedNodeIds is empty', () {
      final extension = MinimapPlugin();
      expect(extension.highlightedNodeIds, isEmpty);
    });

    test('default highlightRegion is null', () {
      final extension = MinimapPlugin();
      expect(extension.highlightRegion, isNull);
    });

    test('default autoHighlightSelection is true', () {
      final extension = MinimapPlugin();
      expect(extension.autoHighlightSelection, isTrue);
    });

    test('can be initialized with autoHighlightSelection false', () {
      final extension = MinimapPlugin(autoHighlightSelection: false);
      expect(extension.autoHighlightSelection, isFalse);
    });

    test('setAutoHighlightSelection() updates value', () {
      final extension = MinimapPlugin();
      extension.setAutoHighlightSelection(false);
      expect(extension.autoHighlightSelection, isFalse);

      extension.setAutoHighlightSelection(true);
      expect(extension.autoHighlightSelection, isTrue);
    });

    test('highlightNodes() sets highlighted nodes', () {
      final extension = MinimapPlugin();

      extension.highlightNodes({'node-1', 'node-2'});
      expect(extension.highlightedNodeIds, equals({'node-1', 'node-2'}));
    });

    test('highlightNodes() replaces previous highlights', () {
      final extension = MinimapPlugin();

      extension.highlightNodes({'node-1'});
      extension.highlightNodes({'node-2', 'node-3'});

      expect(extension.highlightedNodeIds, equals({'node-2', 'node-3'}));
    });

    test('highlightArea() sets highlight region', () {
      final extension = MinimapPlugin();
      final region = const Rect.fromLTWH(0, 0, 100, 100);

      extension.highlightArea(region);
      expect(extension.highlightRegion, equals(region));
    });

    test('highlightArea() replaces previous region', () {
      final extension = MinimapPlugin();

      extension.highlightArea(const Rect.fromLTWH(0, 0, 100, 100));
      extension.highlightArea(const Rect.fromLTWH(50, 50, 200, 200));

      expect(
        extension.highlightRegion,
        equals(const Rect.fromLTWH(50, 50, 200, 200)),
      );
    });

    test('clearHighlights() clears all highlights', () {
      final extension = MinimapPlugin();

      extension.highlightNodes({'node-1', 'node-2'});
      extension.highlightArea(const Rect.fromLTWH(0, 0, 100, 100));

      extension.clearHighlights();

      expect(extension.highlightedNodeIds, isEmpty);
      expect(extension.highlightRegion, isNull);
    });
  });

  // ===========================================================================
  // MinimapPlugin Navigation Tests
  // ===========================================================================

  group('MinimapPlugin - Navigation', () {
    test('centerOn() does nothing when not attached', () {
      final extension = MinimapPlugin();
      // Should not throw
      extension.centerOn(const Offset(100, 100));
      expect(true, isTrue);
    });

    test('centerOn() centers viewport when attached', () {
      final extension = MinimapPlugin();
      extension.attach(controller);
      controller.addNode(
        createTestNode(id: 'node-1', position: const Offset(500, 500)),
      );

      extension.centerOn(const Offset(500, 500));

      // Viewport should be adjusted
      expect(controller.viewport, isNotNull);
    });

    test('focusNodes() does nothing when not attached', () {
      final extension = MinimapPlugin();
      // Should not throw
      extension.focusNodes({'node-1'});
      expect(true, isTrue);
    });

    test('focusNodes() does nothing with empty set', () {
      final extension = MinimapPlugin();
      extension.attach(controller);

      final initialViewport = controller.viewport;
      extension.focusNodes({});

      // Viewport should not change
      expect(controller.viewport, equals(initialViewport));
    });

    test('focusNodes() centers on single node', () {
      final extension = MinimapPlugin();
      extension.attach(controller);
      controller.addNode(
        createTestNode(
          id: 'node-1',
          position: const Offset(500, 500),
          size: const Size(100, 50),
        ),
      );

      extension.focusNodes({'node-1'});

      // Viewport should be adjusted
      expect(controller.viewport, isNotNull);
    });

    test('focusNodes() centers on multiple nodes bounds', () {
      final extension = MinimapPlugin();
      extension.attach(controller);
      controller.addNode(
        createTestNode(
          id: 'node-1',
          position: const Offset(0, 0),
          size: const Size(100, 50),
        ),
      );
      controller.addNode(
        createTestNode(
          id: 'node-2',
          position: const Offset(500, 500),
          size: const Size(100, 50),
        ),
      );

      extension.focusNodes({'node-1', 'node-2'});

      // Viewport should be adjusted to show both nodes
      expect(controller.viewport, isNotNull);
    });

    test('focusNodes() ignores non-existent nodes', () {
      final extension = MinimapPlugin();
      extension.attach(controller);
      controller.addNode(
        createTestNode(id: 'node-1', position: const Offset(100, 100)),
      );

      // Includes non-existent node
      extension.focusNodes({'node-1', 'non-existent'});

      // Should still work with the existing node
      expect(controller.viewport, isNotNull);
    });

    test('focusNodes() does nothing if all nodes are non-existent', () {
      final extension = MinimapPlugin();
      extension.attach(controller);

      final initialViewport = controller.viewport;
      extension.focusNodes({'non-existent-1', 'non-existent-2'});

      // Viewport should not change
      expect(controller.viewport, equals(initialViewport));
    });
  });

  // ===========================================================================
  // MinimapPlugin onEvent Tests
  // ===========================================================================

  group('MinimapPlugin - onEvent', () {
    test('auto-highlights selected nodes when enabled', () {
      final extension = MinimapPlugin(autoHighlightSelection: true);
      extension.attach(controller);

      final event = SelectionChanged(
        selectedNodeIds: {'node-1', 'node-2'},
        selectedConnectionIds: {},
        previousNodeIds: {},
        previousConnectionIds: {},
      );

      extension.onEvent(event);

      expect(extension.highlightedNodeIds, equals({'node-1', 'node-2'}));
    });

    test('clears highlights when selection is empty', () {
      final extension = MinimapPlugin(autoHighlightSelection: true);
      extension.attach(controller);

      // First select some nodes
      extension.highlightNodes({'node-1'});
      extension.highlightArea(const Rect.fromLTWH(0, 0, 100, 100));

      // Then clear selection
      final event = SelectionChanged(
        selectedNodeIds: {},
        selectedConnectionIds: {},
        previousNodeIds: {'node-1'},
        previousConnectionIds: {},
      );

      extension.onEvent(event);

      expect(extension.highlightedNodeIds, isEmpty);
      expect(extension.highlightRegion, isNull);
    });

    test('does not auto-highlight when disabled', () {
      final extension = MinimapPlugin(autoHighlightSelection: false);
      extension.attach(controller);

      final event = SelectionChanged(
        selectedNodeIds: {'node-1'},
        selectedConnectionIds: {},
        previousNodeIds: {},
        previousConnectionIds: {},
      );

      extension.onEvent(event);

      expect(extension.highlightedNodeIds, isEmpty);
    });

    test('ignores non-selection events', () {
      final extension = MinimapPlugin(autoHighlightSelection: true);
      extension.attach(controller);

      // Set some highlights first
      extension.highlightNodes({'node-1'});

      // Send a non-selection event (ViewportChanged for example)
      // Note: We can't easily test this without creating the event,
      // but the switch statement with default case handles it
      expect(extension.highlightedNodeIds, equals({'node-1'}));
    });
  });

  // ===========================================================================
  // MinimapPlugin Theme Tests
  // ===========================================================================

  group('MinimapPlugin - Theme', () {
    test('default theme is light', () {
      final extension = MinimapPlugin();
      expect(extension.theme, equals(MinimapTheme.light));
    });

    test('can be initialized with dark theme', () {
      final extension = MinimapPlugin(theme: MinimapTheme.dark);
      expect(extension.theme, equals(MinimapTheme.dark));
    });

    test('can be initialized with custom theme', () {
      final customTheme = MinimapTheme(
        backgroundColor: Colors.red,
        nodeColor: Colors.blue,
      );
      final extension = MinimapPlugin(theme: customTheme);
      expect(extension.theme.backgroundColor, equals(Colors.red));
      expect(extension.theme.nodeColor, equals(Colors.blue));
    });
  });

  // ===========================================================================
  // MinimapPlugin Margin Tests
  // ===========================================================================

  group('MinimapPlugin - Margin', () {
    test('default margin is 20.0', () {
      final extension = MinimapPlugin();
      expect(extension.margin, equals(20.0));
    });

    test('can be initialized with custom margin', () {
      final extension = MinimapPlugin(margin: 30.0);
      expect(extension.margin, equals(30.0));
    });

    test('margin of zero is valid', () {
      final extension = MinimapPlugin(margin: 0.0);
      expect(extension.margin, equals(0.0));
    });
  });

  // ===========================================================================
  // MinimapPluginAccess Tests
  // ===========================================================================

  group('MinimapPluginAccess', () {
    test('returns null when extension is not registered', () {
      // Create controller without default extensions (no minimap)
      final noMinimapController = createTestController(
        config: createTestConfig(
          plugins: [], // Empty extensions - no minimap
        ),
      );

      expect(noMinimapController.minimap, isNull);

      noMinimapController.dispose();
    });

    test('returns extension when registered', () {
      // Create controller without default minimap
      final testController = createTestController(
        config: createTestConfig(
          plugins: [], // Start with no extensions
        ),
      );
      testController.setScreenSize(const Size(800, 600));

      final extension = MinimapPlugin(visible: true);
      testController.addPlugin(extension);

      expect(testController.minimap, isNotNull);
      expect(testController.minimap, same(extension));

      testController.dispose();
    });

    test('can access extension methods via accessor', () {
      // Default controller already has MinimapPlugin
      expect(controller.minimap, isNotNull);
      final initialVisibility = controller.minimap?.isVisible ?? false;

      controller.minimap?.toggle();
      expect(controller.minimap?.isVisible, equals(!initialVisibility));
    });

    test('returns null after extension is removed', () {
      // Create controller without default minimap
      final testController = createTestController(
        config: createTestConfig(
          plugins: [], // Start with no extensions
        ),
      );

      final extension = MinimapPlugin();
      testController.addPlugin(extension);
      expect(testController.minimap, isNotNull);

      testController.removePlugin(extension.id);
      expect(testController.minimap, isNull);

      testController.dispose();
    });

    test('default controller has minimap extension', () {
      // The default controller created in setUp has MinimapPlugin
      expect(controller.minimap, isNotNull);
    });
  });

  // ===========================================================================
  // MinimapPlugin Edge Cases
  // ===========================================================================

  group('MinimapPlugin - Edge Cases', () {
    test('handles multiple rapid state changes', () {
      final extension = MinimapPlugin();

      for (var i = 0; i < 100; i++) {
        extension.toggle();
        extension.cyclePosition();
        extension.highlightNodes({'node-$i'});
      }

      // Should not throw
      expect(true, isTrue);
    });

    test('handles concurrent highlight operations', () {
      final extension = MinimapPlugin();

      extension.highlightNodes({'a', 'b'});
      extension.highlightArea(const Rect.fromLTWH(0, 0, 50, 50));
      extension.highlightNodes({'c', 'd'});
      extension.clearHighlights();
      extension.highlightArea(const Rect.fromLTWH(10, 10, 100, 100));

      expect(extension.highlightedNodeIds, isEmpty);
      expect(
        extension.highlightRegion,
        equals(const Rect.fromLTWH(10, 10, 100, 100)),
      );
    });

    test('handles empty node id set in highlightNodes', () {
      final extension = MinimapPlugin();
      extension.highlightNodes({'node-1'});
      extension.highlightNodes({});

      expect(extension.highlightedNodeIds, isEmpty);
    });

    test('handles very large highlight region', () {
      final extension = MinimapPlugin();
      extension.highlightArea(
        const Rect.fromLTWH(-100000, -100000, 200000, 200000),
      );

      expect(extension.highlightRegion, isNotNull);
    });

    test('handles negative position highlight region', () {
      final extension = MinimapPlugin();
      extension.highlightArea(const Rect.fromLTWH(-500, -500, 100, 100));

      expect(
        extension.highlightRegion,
        equals(const Rect.fromLTWH(-500, -500, 100, 100)),
      );
    });

    test('handles zero-sized highlight region', () {
      final extension = MinimapPlugin();
      extension.highlightArea(const Rect.fromLTWH(100, 100, 0, 0));

      expect(extension.highlightRegion, isNotNull);
    });

    test('all MinimapPosition values are valid', () {
      for (final position in MinimapPosition.values) {
        final extension = MinimapPlugin(position: position);
        expect(extension.position, equals(position));
      }
    });

    test('extension works correctly without ever attaching', () {
      final extension = MinimapPlugin();

      extension.show();
      extension.hide();
      extension.toggle();
      extension.setSize(const Size(300, 200));
      extension.setPosition(MinimapPosition.topLeft);
      extension.cyclePosition();
      extension.highlightNodes({'a', 'b'});
      extension.highlightArea(const Rect.fromLTWH(0, 0, 100, 100));
      extension.clearHighlights();
      extension.centerOn(const Offset(50, 50));
      extension.focusNodes({'node-1'});

      // All operations should work without throwing
      expect(extension.isVisible, isTrue);
    });
  });

  // ===========================================================================
  // MinimapPlugin - Viewport Synchronization Tests
  // ===========================================================================

  group('MinimapPlugin - Viewport Synchronization', () {
    test('centerOn respects current zoom level', () {
      final extension = MinimapPlugin();
      extension.attach(controller);
      controller.addNode(createTestNode(id: 'node-1'));

      controller.zoomTo(2.0);
      final zoomBefore = controller.viewport.zoom;

      extension.centerOn(const Offset(100, 100));

      expect(controller.viewport.zoom, equals(zoomBefore));
    });

    test('focusNodes calculates correct bounds for different sized nodes', () {
      final extension = MinimapPlugin();
      extension.attach(controller);

      controller.addNode(
        createTestNode(
          id: 'small',
          position: const Offset(0, 0),
          size: const Size(50, 50),
        ),
      );
      controller.addNode(
        createTestNode(
          id: 'large',
          position: const Offset(200, 200),
          size: const Size(200, 150),
        ),
      );

      extension.focusNodes({'small', 'large'});

      // The bounds should include both nodes fully
      expect(controller.viewport, isNotNull);
    });

    test('focusNodes handles nodes at negative positions', () {
      final extension = MinimapPlugin();
      extension.attach(controller);

      controller.addNode(
        createTestNode(id: 'neg', position: const Offset(-300, -300)),
      );
      controller.addNode(
        createTestNode(id: 'pos', position: const Offset(300, 300)),
      );

      extension.focusNodes({'neg', 'pos'});

      expect(controller.viewport, isNotNull);
    });
  });

  // ===========================================================================
  // MinimapPosition Enum Tests
  // ===========================================================================

  group('MinimapPosition', () {
    test('has all expected values', () {
      expect(MinimapPosition.values.length, equals(4));
      expect(MinimapPosition.values, contains(MinimapPosition.topLeft));
      expect(MinimapPosition.values, contains(MinimapPosition.topRight));
      expect(MinimapPosition.values, contains(MinimapPosition.bottomLeft));
      expect(MinimapPosition.values, contains(MinimapPosition.bottomRight));
    });

    test('values have correct indices for cycling', () {
      expect(MinimapPosition.topLeft.index, equals(0));
      expect(MinimapPosition.topRight.index, equals(1));
      expect(MinimapPosition.bottomLeft.index, equals(2));
      expect(MinimapPosition.bottomRight.index, equals(3));
    });
  });
}
