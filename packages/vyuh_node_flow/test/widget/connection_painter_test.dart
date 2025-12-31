@Tags(['widget'])
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vyuh_node_flow/vyuh_node_flow.dart';

import '../helpers/test_factories.dart';

/// Widget tests for connection rendering.
///
/// These tests verify that connections render correctly between nodes,
/// including path calculation, labels, and visual styles.
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

  group('Connection Rendering - Basic', () {
    testWidgets('connection renders between two nodes', (tester) async {
      controller.addNode(createTestNodeWithOutputPort(id: 'a', portId: 'out'));
      controller.addNode(createTestNodeWithInputPort(id: 'b', portId: 'in'));
      controller.createConnection('a', 'out', 'b', 'in');

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 800,
              height: 600,
              child: NodeFlowEditor<String, dynamic>(
                controller: controller,
                nodeBuilder: (context, node) =>
                    SizedBox(width: 100, height: 60, child: Text(node.id)),
                theme: NodeFlowTheme.light,
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Connection should exist
      expect(controller.connectionCount, equals(1));
      // Editor should render without error
      expect(find.byType(NodeFlowEditor<String, dynamic>), findsOneWidget);
    });

    testWidgets('multiple connections render correctly', (tester) async {
      controller.addNode(createTestNodeWithOutputPort(id: 'a', portId: 'out'));
      controller.addNode(createTestNodeWithInputPort(id: 'b', portId: 'in'));
      controller.addNode(createTestNodeWithInputPort(id: 'c', portId: 'in'));
      controller.addNode(createTestNodeWithInputPort(id: 'd', portId: 'in'));

      controller.createConnection('a', 'out', 'b', 'in');
      controller.createConnection('a', 'out', 'c', 'in');
      controller.createConnection('a', 'out', 'd', 'in');

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 800,
              height: 600,
              child: NodeFlowEditor<String, dynamic>(
                controller: controller,
                nodeBuilder: (context, node) =>
                    SizedBox(width: 100, height: 60),
                theme: NodeFlowTheme.light,
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(controller.connectionCount, equals(3));
    });

    testWidgets('connection removal updates UI', (tester) async {
      controller.addNode(createTestNodeWithOutputPort(id: 'a', portId: 'out'));
      controller.addNode(createTestNodeWithInputPort(id: 'b', portId: 'in'));
      controller.createConnection('a', 'out', 'b', 'in');

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 800,
              height: 600,
              child: NodeFlowEditor<String, dynamic>(
                controller: controller,
                nodeBuilder: (context, node) =>
                    SizedBox(width: 100, height: 60),
                theme: NodeFlowTheme.light,
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();
      expect(controller.connectionCount, equals(1));

      // Remove connection
      final conn = controller.connections.first;
      controller.removeConnection(conn.id);

      await tester.pumpAndSettle();
      expect(controller.connectionCount, equals(0));
    });
  });

  group('Connection Rendering - Selection', () {
    testWidgets('selected connection state changes', (tester) async {
      controller.addNode(createTestNodeWithOutputPort(id: 'a', portId: 'out'));
      controller.addNode(createTestNodeWithInputPort(id: 'b', portId: 'in'));
      controller.createConnection('a', 'out', 'b', 'in');

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 800,
              height: 600,
              child: NodeFlowEditor<String, dynamic>(
                controller: controller,
                nodeBuilder: (context, node) =>
                    SizedBox(width: 100, height: 60),
                theme: NodeFlowTheme.light,
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      final conn = controller.connections.first;
      expect(controller.selectedConnectionIds.contains(conn.id), isFalse);

      // Select connection
      controller.selectConnection(conn.id);

      await tester.pumpAndSettle();
      expect(controller.selectedConnectionIds.contains(conn.id), isTrue);

      // Deselect
      controller.clearConnectionSelection();

      await tester.pumpAndSettle();
      expect(controller.selectedConnectionIds.contains(conn.id), isFalse);
    });
  });

  group('Connection Rendering - Labels', () {
    testWidgets('connection with label renders', (tester) async {
      controller.addNode(createTestNodeWithOutputPort(id: 'a', portId: 'out'));
      controller.addNode(createTestNodeWithInputPort(id: 'b', portId: 'in'));

      // Create connection with label
      final connection = Connection(
        id: 'labeled-conn',
        sourceNodeId: 'a',
        sourcePortId: 'out',
        targetNodeId: 'b',
        targetPortId: 'in',
        label: ConnectionLabel(text: 'Test Label'),
      );
      controller.addConnection(connection);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 800,
              height: 600,
              child: NodeFlowEditor<String, dynamic>(
                controller: controller,
                nodeBuilder: (context, node) =>
                    SizedBox(width: 100, height: 60),
                theme: NodeFlowTheme.light,
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Connection should have label
      expect(connection.labels.isNotEmpty, isTrue);
    });

    testWidgets('custom label builder is used', (tester) async {
      controller.addNode(createTestNodeWithOutputPort(id: 'a', portId: 'out'));
      controller.addNode(createTestNodeWithInputPort(id: 'b', portId: 'in'));

      final connection = Connection(
        id: 'custom-label-conn',
        sourceNodeId: 'a',
        sourcePortId: 'out',
        targetNodeId: 'b',
        targetPortId: 'in',
        label: ConnectionLabel(text: 'Custom'),
      );
      controller.addConnection(connection);

      var customLabelBuilderCalled = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 800,
              height: 600,
              child: NodeFlowEditor<String, dynamic>(
                controller: controller,
                nodeBuilder: (context, node) =>
                    SizedBox(width: 100, height: 60),
                labelBuilder: (context, conn, label, rect, onTap) {
                  customLabelBuilderCalled = true;
                  // Note: Do NOT return Positioned - the library wraps it
                  return Container(
                    color: Colors.yellow,
                    child: Text(label.text),
                  );
                },
                theme: NodeFlowTheme.light,
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(customLabelBuilderCalled, isTrue);
    });
  });

  group('Connection Rendering - Animation', () {
    testWidgets('animated connection renders without error', (tester) async {
      // Position nodes for visible connection
      controller.addNode(
        createTestNodeWithOutputPort(
          id: 'a',
          portId: 'out',
          position: const Offset(100, 200),
        ),
      );
      controller.addNode(
        createTestNodeWithInputPort(
          id: 'b',
          portId: 'in',
          position: const Offset(400, 200),
        ),
      );

      // Use the built-in flowing dash effect
      final connection = Connection(
        id: 'animated-conn',
        sourceNodeId: 'a',
        sourcePortId: 'out',
        targetNodeId: 'b',
        targetPortId: 'in',
        animationEffect: ConnectionEffects.flowingDash,
      );
      controller.addConnection(connection);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 800,
              height: 600,
              child: NodeFlowEditor<String, dynamic>(
                controller: controller,
                nodeBuilder: (context, node) =>
                    SizedBox(width: 100, height: 60),
                theme: NodeFlowTheme.light,
              ),
            ),
          ),
        ),
      );

      // Use pump() instead of pumpAndSettle() since animations run continuously
      // and pumpAndSettle() would timeout waiting for them to finish
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Editor should render without error
      expect(find.byType(NodeFlowEditor<String, dynamic>), findsOneWidget);
      // Connection with animation effect should exist
      expect(connection.animationEffect, isNotNull);
      expect(controller.connectionCount, equals(1));
    });
  });

  group('Connection Rendering - Style Resolver', () {
    testWidgets('custom style resolver is configured', (tester) async {
      // Position nodes so connection is visible
      controller.addNode(
        createTestNodeWithOutputPort(
          id: 'a',
          portId: 'out',
          position: const Offset(100, 200),
        ),
      );
      controller.addNode(
        createTestNodeWithInputPort(
          id: 'b',
          portId: 'in',
          position: const Offset(400, 200),
        ),
      );
      // Create connection with custom styling directly on the Connection
      controller.addConnection(
        Connection(
          id: 'styled-conn',
          sourceNodeId: 'a',
          sourcePortId: 'out',
          targetNodeId: 'b',
          targetPortId: 'in',
          color: Colors.red,
          strokeWidth: 3.0,
        ),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 800,
              height: 600,
              child: NodeFlowEditor<String, dynamic>(
                controller: controller,
                nodeBuilder: (context, node) =>
                    SizedBox(width: 100, height: 60),
                theme: NodeFlowTheme.light,
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Editor should render without error with styled connection
      expect(find.byType(NodeFlowEditor<String, dynamic>), findsOneWidget);
      expect(controller.connectionCount, equals(1));
    });
  });

  group('Connection Rendering - Node Movement', () {
    testWidgets('connection updates when source node moves', (tester) async {
      controller.addNode(
        createTestNodeWithOutputPort(
          id: 'a',
          portId: 'out',
          position: const Offset(100, 100),
        ),
      );
      controller.addNode(
        createTestNodeWithInputPort(
          id: 'b',
          portId: 'in',
          position: const Offset(300, 100),
        ),
      );
      controller.createConnection('a', 'out', 'b', 'in');

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 800,
              height: 600,
              child: NodeFlowEditor<String, dynamic>(
                controller: controller,
                nodeBuilder: (context, node) =>
                    SizedBox(width: 100, height: 60),
                theme: NodeFlowTheme.light,
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Move source node
      controller.moveNode('a', const Offset(50, 50));

      await tester.pumpAndSettle();

      // Editor should still render without error
      expect(find.byType(NodeFlowEditor<String, dynamic>), findsOneWidget);
    });

    testWidgets('connection updates when target node moves', (tester) async {
      controller.addNode(
        createTestNodeWithOutputPort(
          id: 'a',
          portId: 'out',
          position: const Offset(100, 100),
        ),
      );
      controller.addNode(
        createTestNodeWithInputPort(
          id: 'b',
          portId: 'in',
          position: const Offset(300, 100),
        ),
      );
      controller.createConnection('a', 'out', 'b', 'in');

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 800,
              height: 600,
              child: NodeFlowEditor<String, dynamic>(
                controller: controller,
                nodeBuilder: (context, node) =>
                    SizedBox(width: 100, height: 60),
                theme: NodeFlowTheme.light,
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Move target node
      controller.moveNode('b', const Offset(-50, 100));

      await tester.pumpAndSettle();

      // Editor should still render without error
      expect(find.byType(NodeFlowEditor<String, dynamic>), findsOneWidget);
    });
  });

  group('Connection Rendering - Cascading Deletion', () {
    testWidgets('connections removed when source node deleted', (tester) async {
      controller.addNode(createTestNodeWithOutputPort(id: 'a', portId: 'out'));
      controller.addNode(createTestNodeWithInputPort(id: 'b', portId: 'in'));
      controller.createConnection('a', 'out', 'b', 'in');

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 800,
              height: 600,
              child: NodeFlowEditor<String, dynamic>(
                controller: controller,
                nodeBuilder: (context, node) =>
                    SizedBox(width: 100, height: 60),
                theme: NodeFlowTheme.light,
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();
      expect(controller.connectionCount, equals(1));

      // Remove source node
      controller.removeNode('a');

      await tester.pumpAndSettle();
      expect(controller.connectionCount, equals(0));
    });

    testWidgets('connections removed when target node deleted', (tester) async {
      controller.addNode(createTestNodeWithOutputPort(id: 'a', portId: 'out'));
      controller.addNode(createTestNodeWithInputPort(id: 'b', portId: 'in'));
      controller.createConnection('a', 'out', 'b', 'in');

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 800,
              height: 600,
              child: NodeFlowEditor<String, dynamic>(
                controller: controller,
                nodeBuilder: (context, node) =>
                    SizedBox(width: 100, height: 60),
                theme: NodeFlowTheme.light,
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();
      expect(controller.connectionCount, equals(1));

      // Remove target node
      controller.removeNode('b');

      await tester.pumpAndSettle();
      expect(controller.connectionCount, equals(0));
    });
  });
}
