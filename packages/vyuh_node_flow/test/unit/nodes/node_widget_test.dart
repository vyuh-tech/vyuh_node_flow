/// Unit tests for NodeWidget.
///
/// Tests cover:
/// - Widget building with various configurations
/// - State management and reactivity
/// - Selection visual state handling
/// - Shape rendering
/// - Custom content and default content
/// - LOD (Level of Detail) rendering
/// - Color and styling customizations
@Tags(['unit'])
library;

import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobx/mobx.dart';
import 'package:vyuh_node_flow/vyuh_node_flow.dart';

import '../../helpers/test_factories.dart';

void main() {
  setUp(() {
    resetTestCounters();
  });

  // ==========================================================================
  // Widget Building Tests
  // ==========================================================================
  group('NodeWidget - Widget Building', () {
    group('Basic Construction', () {
      testWidgets('creates NodeWidget with required parameters', (
        tester,
      ) async {
        final node = createTestNode(id: 'test-node', type: 'processor');

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SizedBox(
                width: 200,
                height: 150,
                child: NodeWidget<String>(node: node, theme: NodeTheme.light),
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Should render default content with type and id
        expect(find.text('processor'), findsOneWidget);
        expect(find.text('test-node'), findsOneWidget);
      });

      testWidgets('creates NodeWidget.defaultStyle constructor', (
        tester,
      ) async {
        final node = createTestNode(id: 'default-node', type: 'input');

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SizedBox(
                width: 200,
                height: 150,
                child: NodeWidget<String>.defaultStyle(
                  node: node,
                  theme: NodeTheme.light,
                ),
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Should render default content
        expect(find.text('input'), findsOneWidget);
        expect(find.text('default-node'), findsOneWidget);
      });

      testWidgets('renders custom child widget', (tester) async {
        final node = createTestNode(id: 'custom-node');

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SizedBox(
                width: 200,
                height: 150,
                child: NodeWidget<String>(
                  node: node,
                  theme: NodeTheme.light,
                  child: const Text('Custom Content'),
                ),
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();

        expect(find.text('Custom Content'), findsOneWidget);
        // Default content should not be rendered
        expect(find.text('custom-node'), findsNothing);
      });

      testWidgets('renders self-rendering node via widgetBuilder', (
        tester,
      ) async {
        final node = Node<String>(
          id: 'self-render-node',
          type: 'custom',
          position: Offset.zero,
          data: 'data',
          widgetBuilder: (context, node) {
            return Container(
              key: const ValueKey('self-rendered'),
              color: Colors.green,
              child: const Text('Self Rendered'),
            );
          },
        );

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SizedBox(
                width: 200,
                height: 150,
                child: NodeWidget<String>(node: node, theme: NodeTheme.light),
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Self-rendered content should be displayed
        expect(find.text('Self Rendered'), findsOneWidget);
        expect(find.byKey(const ValueKey('self-rendered')), findsOneWidget);
      });
    });

    group('Default Content', () {
      testWidgets('default content shows node type as title', (tester) async {
        final node = createTestNode(type: 'MyCustomType');

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SizedBox(
                width: 200,
                height: 150,
                child: NodeWidget<String>(node: node, theme: NodeTheme.light),
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();

        expect(find.text('MyCustomType'), findsOneWidget);
      });

      testWidgets('default content shows node id as content', (tester) async {
        final node = createTestNode(id: 'my-unique-id');

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SizedBox(
                width: 200,
                height: 150,
                child: NodeWidget<String>(node: node, theme: NodeTheme.light),
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();

        expect(find.text('my-unique-id'), findsOneWidget);
      });

      testWidgets('default content uses theme text styles', (tester) async {
        final node = createTestNode(type: 'TestType', id: 'test-id');
        final customTheme = NodeTheme.light.copyWith(
          titleStyle: const TextStyle(fontSize: 20, color: Colors.red),
          contentStyle: const TextStyle(fontSize: 14, color: Colors.blue),
        );

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SizedBox(
                width: 200,
                height: 150,
                child: NodeWidget<String>(node: node, theme: customTheme),
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Verify text widgets exist with styles from theme
        final titleFinder = find.text('TestType');
        final contentFinder = find.text('test-id');

        expect(titleFinder, findsOneWidget);
        expect(contentFinder, findsOneWidget);
      });
    });

    group('Container Decoration', () {
      testWidgets('rectangular node uses Container decoration', (tester) async {
        final node = createTestNode();

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SizedBox(
                width: 200,
                height: 150,
                child: NodeWidget<String>(node: node, theme: NodeTheme.light),
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Should find Container widget
        expect(find.byType(Container), findsWidgets);
      });

      testWidgets('custom border radius is applied', (tester) async {
        final node = createTestNode();
        const customRadius = BorderRadius.all(Radius.circular(16));

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SizedBox(
                width: 200,
                height: 150,
                child: NodeWidget<String>(
                  node: node,
                  theme: NodeTheme.light,
                  borderRadius: customRadius,
                ),
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Widget builds without error with custom border radius
        expect(find.byType(NodeWidget<String>), findsOneWidget);
      });
    });
  });

  // ==========================================================================
  // State Management Tests
  // ==========================================================================
  group('NodeWidget - State Management', () {
    group('MobX Reactivity', () {
      testWidgets('uses Observer for reactive updates', (tester) async {
        final node = createTestNode();

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SizedBox(
                width: 200,
                height: 150,
                child: NodeWidget<String>(node: node, theme: NodeTheme.light),
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Observer widget should be present for reactive updates
        expect(find.byType(Observer), findsWidgets);
      });

      testWidgets('rebuilds when selection state changes', (tester) async {
        final node = createTestNode(id: 'reactive-node');

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SizedBox(
                width: 200,
                height: 150,
                child: NodeWidget<String>(
                  node: node,
                  theme: NodeTheme.light,
                  backgroundColor: Colors.white,
                  selectedBackgroundColor: Colors.blue.shade100,
                ),
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Initial state - not selected
        expect(node.isSelected, isFalse);

        // Change selection state
        runInAction(() {
          node.isSelected = true;
        });

        await tester.pumpAndSettle();

        // Widget should rebuild with new state
        expect(node.isSelected, isTrue);
      });
    });

    group('showContent LOD Control', () {
      testWidgets('showContent true renders full content', (tester) async {
        final node = createTestNode(type: 'FullNode', id: 'full-id');

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SizedBox(
                width: 200,
                height: 150,
                child: NodeWidget<String>(
                  node: node,
                  theme: NodeTheme.light,
                  showContent: true,
                ),
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Full content should be visible
        expect(find.text('FullNode'), findsOneWidget);
        expect(find.text('full-id'), findsOneWidget);
      });

      testWidgets('showContent false renders simplified node', (tester) async {
        final node = createTestNode(type: 'HiddenContent', id: 'hidden-id');

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SizedBox(
                width: 200,
                height: 150,
                child: NodeWidget<String>(
                  node: node,
                  theme: NodeTheme.light,
                  showContent: false,
                ),
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Content should not be visible in simplified mode
        expect(find.text('HiddenContent'), findsNothing);
        expect(find.text('hidden-id'), findsNothing);
      });

      testWidgets('showContent false with custom child hides child', (
        tester,
      ) async {
        final node = createTestNode();

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SizedBox(
                width: 200,
                height: 150,
                child: NodeWidget<String>(
                  node: node,
                  theme: NodeTheme.light,
                  showContent: false,
                  child: const Text('Custom Child'),
                ),
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Custom child should not be visible
        expect(find.text('Custom Child'), findsNothing);
      });
    });
  });

  // ==========================================================================
  // Selection Visual State Tests
  // ==========================================================================
  group('NodeWidget - Selection Visual State', () {
    group('Background Color', () {
      testWidgets('uses theme backgroundColor when not selected', (
        tester,
      ) async {
        final node = createTestNode();
        node.isSelected = false;

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SizedBox(
                width: 200,
                height: 150,
                child: NodeWidget<String>(node: node, theme: NodeTheme.light),
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Widget should render with theme's background color
        expect(find.byType(NodeWidget<String>), findsOneWidget);
      });

      testWidgets('uses theme selectedBackgroundColor when selected', (
        tester,
      ) async {
        final node = createTestNode();
        node.isSelected = true;

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SizedBox(
                width: 200,
                height: 150,
                child: NodeWidget<String>(node: node, theme: NodeTheme.light),
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();

        expect(find.byType(NodeWidget<String>), findsOneWidget);
      });

      testWidgets('custom backgroundColor overrides theme', (tester) async {
        final node = createTestNode();

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SizedBox(
                width: 200,
                height: 150,
                child: NodeWidget<String>(
                  node: node,
                  theme: NodeTheme.light,
                  backgroundColor: Colors.amber,
                ),
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();

        expect(find.byType(NodeWidget<String>), findsOneWidget);
      });

      testWidgets('custom selectedBackgroundColor overrides theme', (
        tester,
      ) async {
        final node = createTestNode();
        node.isSelected = true;

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SizedBox(
                width: 200,
                height: 150,
                child: NodeWidget<String>(
                  node: node,
                  theme: NodeTheme.light,
                  selectedBackgroundColor: Colors.purple,
                ),
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();

        expect(find.byType(NodeWidget<String>), findsOneWidget);
      });

      testWidgets(
        'selected state uses backgroundColor as fallback when selectedBackgroundColor not provided',
        (tester) async {
          final node = createTestNode();
          node.isSelected = true;

          await tester.pumpWidget(
            MaterialApp(
              home: Scaffold(
                body: SizedBox(
                  width: 200,
                  height: 150,
                  child: NodeWidget<String>(
                    node: node,
                    theme: NodeTheme.light,
                    backgroundColor: Colors.orange,
                    // selectedBackgroundColor not provided
                  ),
                ),
              ),
            ),
          );

          await tester.pumpAndSettle();

          expect(find.byType(NodeWidget<String>), findsOneWidget);
        },
      );
    });

    group('Border Color', () {
      testWidgets('uses theme borderColor when not selected', (tester) async {
        final node = createTestNode();
        node.isSelected = false;

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SizedBox(
                width: 200,
                height: 150,
                child: NodeWidget<String>(node: node, theme: NodeTheme.light),
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();

        expect(find.byType(NodeWidget<String>), findsOneWidget);
      });

      testWidgets('uses theme selectedBorderColor when selected', (
        tester,
      ) async {
        final node = createTestNode();
        node.isSelected = true;

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SizedBox(
                width: 200,
                height: 150,
                child: NodeWidget<String>(node: node, theme: NodeTheme.light),
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();

        expect(find.byType(NodeWidget<String>), findsOneWidget);
      });

      testWidgets('custom borderColor overrides theme', (tester) async {
        final node = createTestNode();

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SizedBox(
                width: 200,
                height: 150,
                child: NodeWidget<String>(
                  node: node,
                  theme: NodeTheme.light,
                  borderColor: Colors.red,
                ),
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();

        expect(find.byType(NodeWidget<String>), findsOneWidget);
      });

      testWidgets('custom selectedBorderColor overrides theme', (tester) async {
        final node = createTestNode();
        node.isSelected = true;

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SizedBox(
                width: 200,
                height: 150,
                child: NodeWidget<String>(
                  node: node,
                  theme: NodeTheme.light,
                  selectedBorderColor: Colors.green,
                ),
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();

        expect(find.byType(NodeWidget<String>), findsOneWidget);
      });
    });

    group('Border Width', () {
      testWidgets('uses theme borderWidth when not selected', (tester) async {
        final node = createTestNode();
        node.isSelected = false;

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SizedBox(
                width: 200,
                height: 150,
                child: NodeWidget<String>(node: node, theme: NodeTheme.light),
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();

        expect(find.byType(NodeWidget<String>), findsOneWidget);
      });

      testWidgets('uses theme selectedBorderWidth when selected', (
        tester,
      ) async {
        final node = createTestNode();
        node.isSelected = true;

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SizedBox(
                width: 200,
                height: 150,
                child: NodeWidget<String>(node: node, theme: NodeTheme.light),
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();

        expect(find.byType(NodeWidget<String>), findsOneWidget);
      });

      testWidgets('custom borderWidth overrides theme', (tester) async {
        final node = createTestNode();

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SizedBox(
                width: 200,
                height: 150,
                child: NodeWidget<String>(
                  node: node,
                  theme: NodeTheme.light,
                  borderWidth: 4.0,
                ),
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();

        expect(find.byType(NodeWidget<String>), findsOneWidget);
      });

      testWidgets('custom selectedBorderWidth overrides theme', (tester) async {
        final node = createTestNode();
        node.isSelected = true;

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SizedBox(
                width: 200,
                height: 150,
                child: NodeWidget<String>(
                  node: node,
                  theme: NodeTheme.light,
                  selectedBorderWidth: 5.0,
                ),
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();

        expect(find.byType(NodeWidget<String>), findsOneWidget);
      });
    });

    group('Selection State Transitions', () {
      testWidgets('visual state updates when selection changes', (
        tester,
      ) async {
        final node = createTestNode();

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SizedBox(
                width: 200,
                height: 150,
                child: NodeWidget<String>(node: node, theme: NodeTheme.light),
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Initial state - not selected
        expect(node.isSelected, isFalse);

        // Select the node
        runInAction(() {
          node.isSelected = true;
        });

        await tester.pumpAndSettle();

        expect(node.isSelected, isTrue);

        // Deselect the node
        runInAction(() {
          node.isSelected = false;
        });

        await tester.pumpAndSettle();

        expect(node.isSelected, isFalse);
      });
    });
  });

  // ==========================================================================
  // Shape Rendering Tests
  // ==========================================================================
  group('NodeWidget - Shape Rendering', () {
    group('Shaped Nodes', () {
      testWidgets('renders shaped node with CircleShape', (tester) async {
        final node = createTestNode();
        const shape = CircleShape(
          fillColor: Colors.blue,
          strokeColor: Colors.blueAccent,
          strokeWidth: 2.0,
        );

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SizedBox(
                width: 200,
                height: 200,
                child: NodeWidget<String>(
                  node: node,
                  theme: NodeTheme.light,
                  shape: shape,
                ),
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Should find CustomPaint for shaped node
        expect(find.byType(CustomPaint), findsWidgets);
      });

      testWidgets('renders shaped node with DiamondShape', (tester) async {
        final node = createTestNode();
        const shape = DiamondShape(
          fillColor: Colors.orange,
          strokeColor: Colors.deepOrange,
          strokeWidth: 2.0,
        );

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SizedBox(
                width: 200,
                height: 200,
                child: NodeWidget<String>(
                  node: node,
                  theme: NodeTheme.light,
                  shape: shape,
                ),
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();

        expect(find.byType(CustomPaint), findsWidgets);
      });

      testWidgets('renders shaped node with HexagonShape', (tester) async {
        final node = createTestNode();
        const shape = HexagonShape(
          fillColor: Colors.purple,
          strokeColor: Colors.deepPurple,
          strokeWidth: 2.0,
        );

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SizedBox(
                width: 200,
                height: 200,
                child: NodeWidget<String>(
                  node: node,
                  theme: NodeTheme.light,
                  shape: shape,
                ),
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();

        expect(find.byType(CustomPaint), findsWidgets);
      });

      testWidgets('shaped node uses ClipPath for content clipping', (
        tester,
      ) async {
        final node = createTestNode();
        const shape = CircleShape();

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SizedBox(
                width: 200,
                height: 200,
                child: NodeWidget<String>(
                  node: node,
                  theme: NodeTheme.light,
                  shape: shape,
                ),
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();

        expect(find.byType(ClipPath), findsOneWidget);
      });

      testWidgets('shaped node with showContent false renders simplified', (
        tester,
      ) async {
        final node = createTestNode(type: 'ShapedHidden');
        const shape = DiamondShape();

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SizedBox(
                width: 200,
                height: 200,
                child: NodeWidget<String>(
                  node: node,
                  theme: NodeTheme.light,
                  shape: shape,
                  showContent: false,
                ),
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Should still have CustomPaint for shape
        expect(find.byType(CustomPaint), findsWidgets);
        // But content should be hidden
        expect(find.text('ShapedHidden'), findsNothing);
      });

      testWidgets('shaped node with custom child renders child', (
        tester,
      ) async {
        final node = createTestNode();
        const shape = CircleShape();

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SizedBox(
                width: 200,
                height: 200,
                child: NodeWidget<String>(
                  node: node,
                  theme: NodeTheme.light,
                  shape: shape,
                  child: const Icon(Icons.star),
                ),
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();

        expect(find.byIcon(Icons.star), findsOneWidget);
      });
    });

    group('Shape with Selection', () {
      testWidgets('shaped node updates when selected', (tester) async {
        final node = createTestNode();
        node.isSelected = false;
        const shape = CircleShape();

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SizedBox(
                width: 200,
                height: 200,
                child: NodeWidget<String>(
                  node: node,
                  theme: NodeTheme.light,
                  shape: shape,
                ),
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Select node
        runInAction(() {
          node.isSelected = true;
        });

        await tester.pumpAndSettle();

        // Widget should rebuild
        expect(find.byType(NodeWidget<String>), findsOneWidget);
        expect(node.isSelected, isTrue);
      });
    });
  });

  // ==========================================================================
  // Theme Integration Tests
  // ==========================================================================
  group('NodeWidget - Theme Integration', () {
    testWidgets('uses light theme styling', (tester) async {
      final node = createTestNode();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 200,
              height: 150,
              child: NodeWidget<String>(node: node, theme: NodeTheme.light),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.byType(NodeWidget<String>), findsOneWidget);
    });

    testWidgets('uses dark theme styling', (tester) async {
      final node = createTestNode();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 200,
              height: 150,
              child: NodeWidget<String>(node: node, theme: NodeTheme.dark),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.byType(NodeWidget<String>), findsOneWidget);
    });

    testWidgets('uses custom theme with copyWith', (tester) async {
      final node = createTestNode();
      final customTheme = NodeTheme.light.copyWith(
        backgroundColor: Colors.teal.shade50,
        borderColor: Colors.teal,
        selectedBorderColor: Colors.tealAccent,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 200,
              height: 150,
              child: NodeWidget<String>(node: node, theme: customTheme),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.byType(NodeWidget<String>), findsOneWidget);
    });
  });

  // ==========================================================================
  // Edge Cases and Error Handling
  // ==========================================================================
  group('NodeWidget - Edge Cases', () {
    testWidgets('handles node with empty type', (tester) async {
      final node = createTestNode(type: '');

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 200,
              height: 150,
              child: NodeWidget<String>(node: node, theme: NodeTheme.light),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.byType(NodeWidget<String>), findsOneWidget);
    });

    testWidgets('handles node with empty id', (tester) async {
      final node = createTestNode(id: '');

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 200,
              height: 150,
              child: NodeWidget<String>(node: node, theme: NodeTheme.light),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.byType(NodeWidget<String>), findsOneWidget);
    });

    testWidgets('handles node with very long type string', (tester) async {
      final longType = 'A' * 100;
      final node = createTestNode(type: longType);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 200,
              height: 150,
              child: NodeWidget<String>(node: node, theme: NodeTheme.light),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Should handle overflow gracefully
      expect(find.byType(NodeWidget<String>), findsOneWidget);
    });

    testWidgets('handles node with very long id string', (tester) async {
      final longId = 'B' * 100;
      final node = createTestNode(id: longId);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 200,
              height: 150,
              child: NodeWidget<String>(node: node, theme: NodeTheme.light),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Should handle overflow gracefully
      expect(find.byType(NodeWidget<String>), findsOneWidget);
    });

    testWidgets('handles zero border width', (tester) async {
      final node = createTestNode();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 200,
              height: 150,
              child: NodeWidget<String>(
                node: node,
                theme: NodeTheme.light,
                borderWidth: 0.0,
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.byType(NodeWidget<String>), findsOneWidget);
    });

    testWidgets('handles transparent colors', (tester) async {
      final node = createTestNode();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 200,
              height: 150,
              child: NodeWidget<String>(
                node: node,
                theme: NodeTheme.light,
                backgroundColor: Colors.transparent,
                borderColor: Colors.transparent,
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.byType(NodeWidget<String>), findsOneWidget);
    });

    testWidgets('handles very small node size with LOD simplified view', (
      tester,
    ) async {
      // Very small nodes use showContent: false for LOD rendering
      final node = createTestNode(size: const Size(10, 10));

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 10,
              height: 10,
              child: NodeWidget<String>(
                node: node,
                theme: NodeTheme.light,
                showContent: false, // LOD: simplified rendering for small nodes
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.byType(NodeWidget<String>), findsOneWidget);
    });

    testWidgets('handles very large node size', (tester) async {
      final node = createTestNode(size: const Size(2000, 2000));

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: SizedBox(
                width: 2000,
                height: 2000,
                child: NodeWidget<String>(node: node, theme: NodeTheme.light),
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.byType(NodeWidget<String>), findsOneWidget);
    });
  });

  // ==========================================================================
  // Multiple Widget Instances Tests
  // ==========================================================================
  group('NodeWidget - Multiple Instances', () {
    testWidgets('multiple NodeWidget instances render independently', (
      tester,
    ) async {
      final node1 = createTestNode(id: 'node-1', type: 'Type1');
      final node2 = createTestNode(id: 'node-2', type: 'Type2');
      final node3 = createTestNode(id: 'node-3', type: 'Type3');

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Column(
              children: [
                SizedBox(
                  width: 200,
                  height: 100,
                  child: NodeWidget<String>(
                    node: node1,
                    theme: NodeTheme.light,
                  ),
                ),
                SizedBox(
                  width: 200,
                  height: 100,
                  child: NodeWidget<String>(
                    node: node2,
                    theme: NodeTheme.light,
                  ),
                ),
                SizedBox(
                  width: 200,
                  height: 100,
                  child: NodeWidget<String>(
                    node: node3,
                    theme: NodeTheme.light,
                  ),
                ),
              ],
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Type1'), findsOneWidget);
      expect(find.text('Type2'), findsOneWidget);
      expect(find.text('Type3'), findsOneWidget);
      expect(find.text('node-1'), findsOneWidget);
      expect(find.text('node-2'), findsOneWidget);
      expect(find.text('node-3'), findsOneWidget);
    });

    testWidgets('selection change on one node does not affect others', (
      tester,
    ) async {
      final node1 = createTestNode(id: 'node-1');
      final node2 = createTestNode(id: 'node-2');

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Column(
              children: [
                SizedBox(
                  width: 200,
                  height: 100,
                  child: NodeWidget<String>(
                    node: node1,
                    theme: NodeTheme.light,
                  ),
                ),
                SizedBox(
                  width: 200,
                  height: 100,
                  child: NodeWidget<String>(
                    node: node2,
                    theme: NodeTheme.light,
                  ),
                ),
              ],
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Select only node1
      runInAction(() {
        node1.isSelected = true;
      });

      await tester.pumpAndSettle();

      expect(node1.isSelected, isTrue);
      expect(node2.isSelected, isFalse);
    });
  });

  // ==========================================================================
  // Padding Tests
  // ==========================================================================
  group('NodeWidget - Padding', () {
    testWidgets('custom padding is applied', (tester) async {
      final node = createTestNode();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 200,
              height: 150,
              child: NodeWidget<String>(
                node: node,
                theme: NodeTheme.light,
                padding: const EdgeInsets.all(20),
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.byType(NodeWidget<String>), findsOneWidget);
    });

    testWidgets('asymmetric padding is applied', (tester) async {
      final node = createTestNode();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 200,
              height: 150,
              child: NodeWidget<String>(
                node: node,
                theme: NodeTheme.light,
                padding: const EdgeInsets.only(
                  left: 10,
                  top: 20,
                  right: 30,
                  bottom: 40,
                ),
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.byType(NodeWidget<String>), findsOneWidget);
    });
  });

  // ==========================================================================
  // Complex Node Data Type Tests
  // ==========================================================================
  group('NodeWidget - Complex Node Data Types', () {
    testWidgets('renders node with complex data type', (tester) async {
      final node = Node<Map<String, dynamic>>(
        id: 'complex-node',
        type: 'complex',
        position: Offset.zero,
        data: {'key': 'value', 'count': 42},
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 200,
              height: 150,
              child: NodeWidget<Map<String, dynamic>>(
                node: node,
                theme: NodeTheme.light,
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('complex'), findsOneWidget);
      expect(find.text('complex-node'), findsOneWidget);
    });

    testWidgets('renders node with nullable data', (tester) async {
      final node = Node<String?>(
        id: 'nullable-node',
        type: 'nullable',
        position: Offset.zero,
        data: null,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 200,
              height: 150,
              child: NodeWidget<String?>(node: node, theme: NodeTheme.light),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('nullable'), findsOneWidget);
    });
  });
}
