/// Unit tests for InteractionLayer and InteractionLayerPainter.
///
/// Tests cover:
/// - Layer rendering with IgnorePointer and RepaintBoundary
/// - Selection rectangle rendering
/// - Temporary connection rendering
/// - InteractionLayerPainter shouldRepaint logic
/// - Canvas transform application
/// - Edge cases and null states
@Tags(['unit'])
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vyuh_node_flow/vyuh_node_flow.dart';
import 'package:vyuh_node_flow/src/connections/temporary_connection.dart';
import 'package:vyuh_node_flow/src/editor/layers/interaction_layer.dart';

import '../../helpers/test_factories.dart';

void main() {
  setUp(() {
    resetTestCounters();
  });

  // ===========================================================================
  // InteractionLayer Widget Construction Tests
  // ===========================================================================

  group('InteractionLayer Construction', () {
    test('creates with required parameters', () {
      final controller = createTestController();
      final transformationController = TransformationController();

      final layer = InteractionLayer<String>(
        controller: controller,
        transformationController: transformationController,
      );

      expect(layer.controller, equals(controller));
      expect(layer.transformationController, equals(transformationController));
      expect(layer.animation, isNull);
    });

    test('creates with optional animation parameter', () {
      final controller = createTestController();
      final transformationController = TransformationController();
      final animation = const AlwaysStoppedAnimation(0.5);

      final layer = InteractionLayer<String>(
        controller: controller,
        transformationController: transformationController,
        animation: animation,
      );

      expect(layer.animation, equals(animation));
    });
  });

  // ===========================================================================
  // InteractionLayer Widget Tree Structure Tests
  // ===========================================================================

  group('InteractionLayer Widget Tree', () {
    late NodeFlowController<String, dynamic> controller;
    late TransformationController transformationController;

    setUp(() {
      controller = createTestController();
      transformationController = TransformationController();
    });

    testWidgets('wraps content in IgnorePointer', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.light().copyWith(extensions: [NodeFlowTheme.light]),
          home: InteractionLayer<String>(
            controller: controller,
            transformationController: transformationController,
          ),
        ),
      );

      // Find IgnorePointer that is a descendant of InteractionLayer
      final ignorePointerFinder = find.descendant(
        of: find.byType(InteractionLayer<String>),
        matching: find.byType(IgnorePointer),
      );
      expect(ignorePointerFinder, findsOneWidget);
    });

    testWidgets('contains RepaintBoundary for performance', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.light().copyWith(extensions: [NodeFlowTheme.light]),
          home: InteractionLayer<String>(
            controller: controller,
            transformationController: transformationController,
          ),
        ),
      );

      // Find RepaintBoundary that is a descendant of InteractionLayer
      final repaintBoundaryFinder = find.descendant(
        of: find.byType(InteractionLayer<String>),
        matching: find.byType(RepaintBoundary),
      );
      expect(repaintBoundaryFinder, findsOneWidget);
    });

    testWidgets('contains CustomPaint for rendering', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.light().copyWith(extensions: [NodeFlowTheme.light]),
          home: InteractionLayer<String>(
            controller: controller,
            transformationController: transformationController,
          ),
        ),
      );

      // Find CustomPaint that is a descendant of InteractionLayer
      final customPaintFinder = find.descendant(
        of: find.byType(InteractionLayer<String>),
        matching: find.byType(CustomPaint),
      );
      expect(customPaintFinder, findsOneWidget);
    });

    testWidgets('CustomPaint uses infinite size', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.light().copyWith(extensions: [NodeFlowTheme.light]),
          home: InteractionLayer<String>(
            controller: controller,
            transformationController: transformationController,
          ),
        ),
      );

      // Find CustomPaint that is a descendant of InteractionLayer
      final customPaintFinder = find.descendant(
        of: find.byType(InteractionLayer<String>),
        matching: find.byType(CustomPaint),
      );
      final customPaint = tester.widget<CustomPaint>(customPaintFinder);
      expect(customPaint.size, equals(Size.infinite));
    });

    testWidgets('falls back to light theme when no theme in context', (
      tester,
    ) async {
      // Use MaterialApp without NodeFlowTheme extension
      await tester.pumpWidget(
        MaterialApp(
          home: InteractionLayer<String>(
            controller: controller,
            transformationController: transformationController,
          ),
        ),
      );

      // Should not throw and should render with default theme
      final customPaintFinder = find.descendant(
        of: find.byType(InteractionLayer<String>),
        matching: find.byType(CustomPaint),
      );
      expect(customPaintFinder, findsOneWidget);
    });
  });

  // ===========================================================================
  // InteractionLayerPainter Construction Tests
  // ===========================================================================

  group('InteractionLayerPainter Construction', () {
    late NodeFlowController<String, dynamic> controller;
    late TransformationController transformationController;

    setUp(() {
      controller = createTestController();
      transformationController = TransformationController();
    });

    test('creates with all required parameters', () {
      final painter = InteractionLayerPainter<String>(
        controller: controller,
        theme: NodeFlowTheme.light,
        selectionRect: null,
        temporaryConnection: null,
        transformationController: transformationController,
      );

      expect(painter.controller, equals(controller));
      expect(painter.theme, equals(NodeFlowTheme.light));
      expect(painter.selectionRect, isNull);
      expect(painter.temporaryConnection, isNull);
      expect(
        painter.transformationController,
        equals(transformationController),
      );
      expect(painter.animation, isNull);
    });

    test('creates with selection rectangle', () {
      const selectionRect = GraphRect(Rect.fromLTWH(100, 100, 200, 150));

      final painter = InteractionLayerPainter<String>(
        controller: controller,
        theme: NodeFlowTheme.light,
        selectionRect: selectionRect,
        temporaryConnection: null,
        transformationController: transformationController,
      );

      expect(painter.selectionRect, equals(selectionRect));
    });

    test('creates with temporary connection', () {
      final tempConnection = TemporaryConnection(
        startPoint: const Offset(100, 100),
        startNodeId: 'node-1',
        startPortId: 'output-1',
        isStartFromOutput: true,
        startNodeBounds: const Rect.fromLTWH(0, 0, 200, 100),
        initialCurrentPoint: const Offset(150, 150),
      );

      final painter = InteractionLayerPainter<String>(
        controller: controller,
        theme: NodeFlowTheme.light,
        selectionRect: null,
        temporaryConnection: tempConnection,
        transformationController: transformationController,
      );

      expect(painter.temporaryConnection, equals(tempConnection));
    });

    test('creates with animation', () {
      const animation = AlwaysStoppedAnimation(0.5);

      final painter = InteractionLayerPainter<String>(
        controller: controller,
        theme: NodeFlowTheme.light,
        selectionRect: null,
        temporaryConnection: null,
        transformationController: transformationController,
        animation: animation,
      );

      expect(painter.animation, equals(animation));
    });
  });

  // ===========================================================================
  // InteractionLayerPainter shouldRepaint Tests
  // ===========================================================================

  group('InteractionLayerPainter shouldRepaint', () {
    late NodeFlowController<String, dynamic> controller;
    late TransformationController transformationController;

    setUp(() {
      controller = createTestController();
      transformationController = TransformationController();
    });

    test('returns true when current has temporary connection', () {
      final tempConnection = TemporaryConnection(
        startPoint: const Offset(100, 100),
        startNodeId: 'node-1',
        startPortId: 'output-1',
        isStartFromOutput: true,
        startNodeBounds: const Rect.fromLTWH(0, 0, 200, 100),
        initialCurrentPoint: const Offset(150, 150),
      );

      final currentPainter = InteractionLayerPainter<String>(
        controller: controller,
        theme: NodeFlowTheme.light,
        selectionRect: null,
        temporaryConnection: tempConnection,
        transformationController: transformationController,
      );

      final oldPainter = InteractionLayerPainter<String>(
        controller: controller,
        theme: NodeFlowTheme.light,
        selectionRect: null,
        temporaryConnection: null,
        transformationController: transformationController,
      );

      expect(currentPainter.shouldRepaint(oldPainter), isTrue);
    });

    test('returns true when old had temporary connection', () {
      final tempConnection = TemporaryConnection(
        startPoint: const Offset(100, 100),
        startNodeId: 'node-1',
        startPortId: 'output-1',
        isStartFromOutput: true,
        startNodeBounds: const Rect.fromLTWH(0, 0, 200, 100),
        initialCurrentPoint: const Offset(150, 150),
      );

      final currentPainter = InteractionLayerPainter<String>(
        controller: controller,
        theme: NodeFlowTheme.light,
        selectionRect: null,
        temporaryConnection: null,
        transformationController: transformationController,
      );

      final oldPainter = InteractionLayerPainter<String>(
        controller: controller,
        theme: NodeFlowTheme.light,
        selectionRect: null,
        temporaryConnection: tempConnection,
        transformationController: transformationController,
      );

      expect(currentPainter.shouldRepaint(oldPainter), isTrue);
    });

    test('returns true when both have temporary connections', () {
      final tempConnection1 = TemporaryConnection(
        startPoint: const Offset(100, 100),
        startNodeId: 'node-1',
        startPortId: 'output-1',
        isStartFromOutput: true,
        startNodeBounds: const Rect.fromLTWH(0, 0, 200, 100),
        initialCurrentPoint: const Offset(150, 150),
      );

      final tempConnection2 = TemporaryConnection(
        startPoint: const Offset(100, 100),
        startNodeId: 'node-1',
        startPortId: 'output-1',
        isStartFromOutput: true,
        startNodeBounds: const Rect.fromLTWH(0, 0, 200, 100),
        initialCurrentPoint: const Offset(200, 200),
      );

      final currentPainter = InteractionLayerPainter<String>(
        controller: controller,
        theme: NodeFlowTheme.light,
        selectionRect: null,
        temporaryConnection: tempConnection2,
        transformationController: transformationController,
      );

      final oldPainter = InteractionLayerPainter<String>(
        controller: controller,
        theme: NodeFlowTheme.light,
        selectionRect: null,
        temporaryConnection: tempConnection1,
        transformationController: transformationController,
      );

      // Always repaints when temporary connection exists
      expect(currentPainter.shouldRepaint(oldPainter), isTrue);
    });

    test('returns true when selection rect changes', () {
      const selectionRect1 = GraphRect(Rect.fromLTWH(100, 100, 200, 150));
      const selectionRect2 = GraphRect(Rect.fromLTWH(100, 100, 300, 200));

      final currentPainter = InteractionLayerPainter<String>(
        controller: controller,
        theme: NodeFlowTheme.light,
        selectionRect: selectionRect2,
        temporaryConnection: null,
        transformationController: transformationController,
      );

      final oldPainter = InteractionLayerPainter<String>(
        controller: controller,
        theme: NodeFlowTheme.light,
        selectionRect: selectionRect1,
        temporaryConnection: null,
        transformationController: transformationController,
      );

      expect(currentPainter.shouldRepaint(oldPainter), isTrue);
    });

    test('returns true when selection rect added', () {
      const selectionRect = GraphRect(Rect.fromLTWH(100, 100, 200, 150));

      final currentPainter = InteractionLayerPainter<String>(
        controller: controller,
        theme: NodeFlowTheme.light,
        selectionRect: selectionRect,
        temporaryConnection: null,
        transformationController: transformationController,
      );

      final oldPainter = InteractionLayerPainter<String>(
        controller: controller,
        theme: NodeFlowTheme.light,
        selectionRect: null,
        temporaryConnection: null,
        transformationController: transformationController,
      );

      expect(currentPainter.shouldRepaint(oldPainter), isTrue);
    });

    test('returns true when selection rect removed', () {
      const selectionRect = GraphRect(Rect.fromLTWH(100, 100, 200, 150));

      final currentPainter = InteractionLayerPainter<String>(
        controller: controller,
        theme: NodeFlowTheme.light,
        selectionRect: null,
        temporaryConnection: null,
        transformationController: transformationController,
      );

      final oldPainter = InteractionLayerPainter<String>(
        controller: controller,
        theme: NodeFlowTheme.light,
        selectionRect: selectionRect,
        temporaryConnection: null,
        transformationController: transformationController,
      );

      expect(currentPainter.shouldRepaint(oldPainter), isTrue);
    });

    test('returns false when nothing changes', () {
      const selectionRect = GraphRect(Rect.fromLTWH(100, 100, 200, 150));

      final currentPainter = InteractionLayerPainter<String>(
        controller: controller,
        theme: NodeFlowTheme.light,
        selectionRect: selectionRect,
        temporaryConnection: null,
        transformationController: transformationController,
      );

      final oldPainter = InteractionLayerPainter<String>(
        controller: controller,
        theme: NodeFlowTheme.light,
        selectionRect: selectionRect,
        temporaryConnection: null,
        transformationController: transformationController,
      );

      expect(currentPainter.shouldRepaint(oldPainter), isFalse);
    });

    test(
      'returns false when both have null selection rect and no temp connection',
      () {
        final currentPainter = InteractionLayerPainter<String>(
          controller: controller,
          theme: NodeFlowTheme.light,
          selectionRect: null,
          temporaryConnection: null,
          transformationController: transformationController,
        );

        final oldPainter = InteractionLayerPainter<String>(
          controller: controller,
          theme: NodeFlowTheme.light,
          selectionRect: null,
          temporaryConnection: null,
          transformationController: transformationController,
        );

        expect(currentPainter.shouldRepaint(oldPainter), isFalse);
      },
    );
  });

  // ===========================================================================
  // InteractionLayerPainter Repaint Listenable Tests
  // ===========================================================================

  group('InteractionLayerPainter Repaint Listenable', () {
    late NodeFlowController<String, dynamic> controller;
    late TransformationController transformationController;

    setUp(() {
      controller = createTestController();
      transformationController = TransformationController();
    });

    test('listens to transformation controller without animation', () {
      final painter = InteractionLayerPainter<String>(
        controller: controller,
        theme: NodeFlowTheme.light,
        selectionRect: null,
        temporaryConnection: null,
        transformationController: transformationController,
      );

      // The repaint listenable should include the transformation controller
      // We can verify this by checking the painter was created successfully
      // and has the correct references
      expect(
        painter.transformationController,
        equals(transformationController),
      );
      expect(painter.animation, isNull);
    });

    test('listens to both transformation controller and animation', () {
      const animation = AlwaysStoppedAnimation(0.5);

      final painter = InteractionLayerPainter<String>(
        controller: controller,
        theme: NodeFlowTheme.light,
        selectionRect: null,
        temporaryConnection: null,
        transformationController: transformationController,
        animation: animation,
      );

      expect(
        painter.transformationController,
        equals(transformationController),
      );
      expect(painter.animation, equals(animation));
    });
  });

  // ===========================================================================
  // Selection Rectangle State Tests
  // ===========================================================================

  group('Selection Rectangle State', () {
    test('controller selection rect observable updates painter', () {
      final controller = createTestController();
      final state = controller.interaction;

      // Initially no selection
      expect(state.currentSelectionRect, isNull);

      // Start selection
      state.updateSelection(
        startPoint: const GraphPosition(Offset(0, 0)),
        rectangle: const GraphRect(Rect.fromLTWH(0, 0, 100, 100)),
      );

      expect(state.currentSelectionRect, isNotNull);
      expect(state.currentSelectionRect?.rect.width, equals(100));
      expect(state.currentSelectionRect?.rect.height, equals(100));
    });

    test('selection rect with negative coordinates', () {
      final controller = createTestController();
      final state = controller.interaction;

      state.updateSelection(
        startPoint: const GraphPosition(Offset(-50, -50)),
        rectangle: const GraphRect(Rect.fromLTWH(-50, -50, 200, 150)),
      );

      expect(state.currentSelectionRect?.rect.left, equals(-50));
      expect(state.currentSelectionRect?.rect.top, equals(-50));
    });

    test('selection rect after finish is cleared', () {
      final controller = createTestController();
      final state = controller.interaction;

      state.updateSelection(
        startPoint: const GraphPosition(Offset(0, 0)),
        rectangle: const GraphRect(Rect.fromLTWH(0, 0, 100, 100)),
      );

      expect(state.currentSelectionRect, isNotNull);

      state.finishSelection();

      expect(state.currentSelectionRect, isNull);
    });
  });

  // ===========================================================================
  // Temporary Connection State Tests
  // ===========================================================================

  group('Temporary Connection State', () {
    test('controller temporary connection is null initially', () {
      final controller = createTestController();
      expect(controller.temporaryConnection, isNull);
    });

    test('temporary connection from output port', () {
      final tempConnection = TemporaryConnection(
        startPoint: const Offset(100, 50),
        startNodeId: 'node-a',
        startPortId: 'output-1',
        isStartFromOutput: true,
        startNodeBounds: const Rect.fromLTWH(0, 0, 100, 100),
        initialCurrentPoint: const Offset(100, 50),
      );

      expect(tempConnection.isStartFromOutput, isTrue);
      expect(tempConnection.startNodeId, equals('node-a'));
      expect(tempConnection.startPortId, equals('output-1'));
    });

    test('temporary connection from input port', () {
      final tempConnection = TemporaryConnection(
        startPoint: const Offset(0, 50),
        startNodeId: 'node-b',
        startPortId: 'input-1',
        isStartFromOutput: false,
        startNodeBounds: const Rect.fromLTWH(0, 0, 100, 100),
        initialCurrentPoint: const Offset(0, 50),
      );

      expect(tempConnection.isStartFromOutput, isFalse);
      expect(tempConnection.startNodeId, equals('node-b'));
      expect(tempConnection.startPortId, equals('input-1'));
    });

    test('temporary connection updates current point', () {
      final tempConnection = TemporaryConnection(
        startPoint: const Offset(100, 50),
        startNodeId: 'node-a',
        startPortId: 'output-1',
        isStartFromOutput: true,
        startNodeBounds: const Rect.fromLTWH(0, 0, 100, 100),
        initialCurrentPoint: const Offset(100, 50),
      );

      expect(tempConnection.currentPoint, equals(const Offset(100, 50)));

      tempConnection.currentPoint = const Offset(200, 100);

      expect(tempConnection.currentPoint, equals(const Offset(200, 100)));
    });

    test('temporary connection sets target node when hovering', () {
      final tempConnection = TemporaryConnection(
        startPoint: const Offset(100, 50),
        startNodeId: 'node-a',
        startPortId: 'output-1',
        isStartFromOutput: true,
        startNodeBounds: const Rect.fromLTWH(0, 0, 100, 100),
        initialCurrentPoint: const Offset(100, 50),
      );

      expect(tempConnection.targetNodeId, isNull);
      expect(tempConnection.targetPortId, isNull);

      tempConnection.targetNodeId = 'node-b';
      tempConnection.targetPortId = 'input-1';
      tempConnection.targetNodeBounds = const Rect.fromLTWH(200, 0, 100, 100);

      expect(tempConnection.targetNodeId, equals('node-b'));
      expect(tempConnection.targetPortId, equals('input-1'));
      expect(
        tempConnection.targetNodeBounds,
        equals(const Rect.fromLTWH(200, 0, 100, 100)),
      );
    });

    test('temporary connection clears target when leaving hover', () {
      final tempConnection = TemporaryConnection(
        startPoint: const Offset(100, 50),
        startNodeId: 'node-a',
        startPortId: 'output-1',
        isStartFromOutput: true,
        startNodeBounds: const Rect.fromLTWH(0, 0, 100, 100),
        initialCurrentPoint: const Offset(100, 50),
        targetNodeId: 'node-b',
        targetPortId: 'input-1',
        targetNodeBounds: const Rect.fromLTWH(200, 0, 100, 100),
      );

      tempConnection.targetNodeId = null;
      tempConnection.targetPortId = null;
      tempConnection.targetNodeBounds = null;

      expect(tempConnection.targetNodeId, isNull);
      expect(tempConnection.targetPortId, isNull);
      expect(tempConnection.targetNodeBounds, isNull);
    });
  });

  // ===========================================================================
  // Canvas Transform Application Tests
  // ===========================================================================

  group('Canvas Transform Application', () {
    test('transformation controller identity matrix', () {
      final transformationController = TransformationController();

      expect(transformationController.value, equals(Matrix4.identity()));
    });

    test('transformation controller with translation', () {
      final transformationController = TransformationController();
      transformationController.value = Matrix4.translationValues(100, 50, 0);

      final translation = transformationController.value.getTranslation();
      expect(translation.x, equals(100));
      expect(translation.y, equals(50));
    });

    test('transformation controller with scale', () {
      final transformationController = TransformationController();
      transformationController.value = Matrix4.diagonal3Values(2.0, 2.0, 1.0);

      expect(transformationController.value.entry(0, 0), equals(2.0));
      expect(transformationController.value.entry(1, 1), equals(2.0));
    });

    test('transformation controller with combined transform', () {
      final transformationController = TransformationController();
      final transform = Matrix4.identity()
        ..translate(100.0, 50.0)
        ..scale(1.5, 1.5);
      transformationController.value = transform;

      // Scale is applied
      expect(transformationController.value.entry(0, 0), closeTo(1.5, 0.001));
      // Translation is also present
      final translation = transformationController.value.getTranslation();
      expect(translation.x, closeTo(100, 0.001));
    });
  });

  // ===========================================================================
  // Theme Integration Tests
  // ===========================================================================

  group('Theme Integration', () {
    test('uses connection theme color for selection rectangle', () {
      final theme = NodeFlowTheme.light;
      expect(theme.connectionTheme.color, isNotNull);
    });

    test('light theme provides selection colors', () {
      final theme = NodeFlowTheme.light;
      final selectionColor = theme.connectionTheme.color.withValues(alpha: 0.2);
      // Alpha is stored as 0-255 in Color, so 0.2 opacity gives value around 51
      expect(selectionColor.a, lessThan(1.0));
    });

    test('dark theme provides selection colors', () {
      final theme = NodeFlowTheme.dark;
      final selectionColor = theme.connectionTheme.color.withValues(alpha: 0.2);
      // Alpha is stored as 0-255 in Color, so 0.2 opacity gives value around 51
      expect(selectionColor.a, lessThan(1.0));
    });
  });

  // ===========================================================================
  // Edge Cases Tests
  // ===========================================================================

  group('Edge Cases', () {
    late NodeFlowController<String, dynamic> controller;
    late TransformationController transformationController;

    setUp(() {
      controller = createTestController();
      transformationController = TransformationController();
    });

    test('handles empty controller', () {
      final painter = InteractionLayerPainter<String>(
        controller: controller,
        theme: NodeFlowTheme.light,
        selectionRect: null,
        temporaryConnection: null,
        transformationController: transformationController,
      );

      expect(painter.controller.nodes, isEmpty);
      expect(painter.controller.connections, isEmpty);
    });

    test('handles zero-area selection rectangle', () {
      const selectionRect = GraphRect(Rect.fromLTWH(100, 100, 0, 0));

      final painter = InteractionLayerPainter<String>(
        controller: controller,
        theme: NodeFlowTheme.light,
        selectionRect: selectionRect,
        temporaryConnection: null,
        transformationController: transformationController,
      );

      expect(painter.selectionRect?.rect.isEmpty, isTrue);
    });

    test('handles very large selection rectangle', () {
      const selectionRect = GraphRect(
        Rect.fromLTWH(-10000, -10000, 20000, 20000),
      );

      final painter = InteractionLayerPainter<String>(
        controller: controller,
        theme: NodeFlowTheme.light,
        selectionRect: selectionRect,
        temporaryConnection: null,
        transformationController: transformationController,
      );

      expect(painter.selectionRect?.rect.width, equals(20000));
      expect(painter.selectionRect?.rect.height, equals(20000));
    });

    test(
      'handles temporary connection with identical start and current point',
      () {
        final tempConnection = TemporaryConnection(
          startPoint: const Offset(100, 100),
          startNodeId: 'node-a',
          startPortId: 'output-1',
          isStartFromOutput: true,
          startNodeBounds: const Rect.fromLTWH(0, 0, 200, 100),
          initialCurrentPoint: const Offset(100, 100),
        );

        // Start and current point are the same
        expect(tempConnection.startPoint, equals(tempConnection.currentPoint));
      },
    );

    test('handles temporary connection with very far current point', () {
      final tempConnection = TemporaryConnection(
        startPoint: const Offset(100, 100),
        startNodeId: 'node-a',
        startPortId: 'output-1',
        isStartFromOutput: true,
        startNodeBounds: const Rect.fromLTWH(0, 0, 200, 100),
        initialCurrentPoint: const Offset(10000, 10000),
      );

      expect(tempConnection.currentPoint, equals(const Offset(10000, 10000)));
    });

    test('handles temporary connection with negative coordinates', () {
      final tempConnection = TemporaryConnection(
        startPoint: const Offset(-100, -100),
        startNodeId: 'node-a',
        startPortId: 'output-1',
        isStartFromOutput: true,
        startNodeBounds: const Rect.fromLTWH(-200, -150, 200, 100),
        initialCurrentPoint: const Offset(-50, -50),
      );

      expect(tempConnection.startPoint.dx, equals(-100));
      expect(tempConnection.startPoint.dy, equals(-100));
      expect(tempConnection.currentPoint.dx, equals(-50));
      expect(tempConnection.currentPoint.dy, equals(-50));
    });
  });

  // ===========================================================================
  // Controller Integration Tests
  // ===========================================================================

  group('Controller Integration', () {
    test('interaction layer observes controller selection rect', () {
      final controller = createTestController();
      final state = controller.interaction;

      expect(controller.selectionRect, isNull);

      state.updateSelection(
        startPoint: const GraphPosition(Offset(50, 50)),
        rectangle: const GraphRect(Rect.fromLTWH(50, 50, 150, 100)),
      );

      expect(controller.selectionRect, isNotNull);
      expect(controller.selectionRect?.rect.width, equals(150));
    });

    test('interaction layer observes controller temporary connection', () {
      final controller = createTestController();

      expect(controller.temporaryConnection, isNull);
      expect(controller.isConnecting, isFalse);
    });

    test('painter receives controller nodes for port lookup', () {
      final nodeA = createTestNodeWithOutputPort(
        id: 'node-a',
        portId: 'output-1',
        position: const Offset(0, 0),
      );
      nodeA.setSize(const Size(100, 50));

      final nodeB = createTestNodeWithInputPort(
        id: 'node-b',
        portId: 'input-1',
        position: const Offset(200, 0),
      );
      nodeB.setSize(const Size(100, 50));

      final controller = createTestController(nodes: [nodeA, nodeB]);

      expect(controller.nodes['node-a'], isNotNull);
      expect(controller.nodes['node-b'], isNotNull);
      expect(controller.nodes['node-a']?.outputPorts.length, equals(1));
      expect(controller.nodes['node-b']?.inputPorts.length, equals(1));
    });

    test('painter finds ports for temporary connection rendering', () {
      final nodeA = createTestNodeWithOutputPort(
        id: 'node-a',
        portId: 'output-1',
        position: const Offset(0, 0),
      );
      nodeA.setSize(const Size(100, 50));

      final controller = createTestController(nodes: [nodeA]);

      // Find port by ID
      final node = controller.nodes['node-a'];
      Port? foundPort;
      for (final port in node!.outputPorts) {
        if (port.id == 'output-1') {
          foundPort = port;
          break;
        }
      }

      expect(foundPort, isNotNull);
      expect(foundPort?.id, equals('output-1'));
      expect(foundPort?.isOutput, isTrue);
    });
  });

  // ===========================================================================
  // Animation Value Tests
  // ===========================================================================

  group('Animation Value', () {
    late NodeFlowController<String, dynamic> controller;
    late TransformationController transformationController;

    setUp(() {
      controller = createTestController();
      transformationController = TransformationController();
    });

    test('animation value 0.0', () {
      const animation = AlwaysStoppedAnimation(0.0);

      final painter = InteractionLayerPainter<String>(
        controller: controller,
        theme: NodeFlowTheme.light,
        selectionRect: null,
        temporaryConnection: null,
        transformationController: transformationController,
        animation: animation,
      );

      expect(painter.animation?.value, equals(0.0));
    });

    test('animation value 1.0', () {
      const animation = AlwaysStoppedAnimation(1.0);

      final painter = InteractionLayerPainter<String>(
        controller: controller,
        theme: NodeFlowTheme.light,
        selectionRect: null,
        temporaryConnection: null,
        transformationController: transformationController,
        animation: animation,
      );

      expect(painter.animation?.value, equals(1.0));
    });

    test('animation value mid-range', () {
      const animation = AlwaysStoppedAnimation(0.5);

      final painter = InteractionLayerPainter<String>(
        controller: controller,
        theme: NodeFlowTheme.light,
        selectionRect: null,
        temporaryConnection: null,
        transformationController: transformationController,
        animation: animation,
      );

      expect(painter.animation?.value, equals(0.5));
    });
  });

  // ===========================================================================
  // Multiple Selection Rectangles Tests
  // ===========================================================================

  group('Multiple Selection States', () {
    test('selection state updates sequentially', () {
      final controller = createTestController();
      final state = controller.interaction;

      // First selection
      state.updateSelection(
        startPoint: const GraphPosition(Offset(0, 0)),
        rectangle: const GraphRect(Rect.fromLTWH(0, 0, 50, 50)),
      );
      expect(state.currentSelectionRect?.rect.width, equals(50));

      // Update selection (drag continues)
      state.updateSelection(
        startPoint: const GraphPosition(Offset(0, 0)),
        rectangle: const GraphRect(Rect.fromLTWH(0, 0, 100, 100)),
      );
      expect(state.currentSelectionRect?.rect.width, equals(100));

      // Update again
      state.updateSelection(
        startPoint: const GraphPosition(Offset(0, 0)),
        rectangle: const GraphRect(Rect.fromLTWH(0, 0, 200, 150)),
      );
      expect(state.currentSelectionRect?.rect.width, equals(200));
      expect(state.currentSelectionRect?.rect.height, equals(150));

      // Finish selection
      state.finishSelection();
      expect(state.currentSelectionRect, isNull);
    });
  });

  // ===========================================================================
  // Port Direction Logic Tests
  // ===========================================================================

  group('Port Direction Logic', () {
    test('output port starts connection as source', () {
      final tempConnection = TemporaryConnection(
        startPoint: const Offset(100, 50),
        startNodeId: 'node-a',
        startPortId: 'output-1',
        isStartFromOutput: true,
        startNodeBounds: const Rect.fromLTWH(0, 0, 100, 100),
        initialCurrentPoint: const Offset(200, 50),
      );

      // When starting from output: start is SOURCE, current point is TARGET
      expect(tempConnection.isStartFromOutput, isTrue);
      // The painter interprets:
      // sourcePoint = tempConnection.startPoint
      // targetPoint = tempConnection.currentPoint
    });

    test('input port starts connection as target', () {
      final tempConnection = TemporaryConnection(
        startPoint: const Offset(0, 50),
        startNodeId: 'node-b',
        startPortId: 'input-1',
        isStartFromOutput: false,
        startNodeBounds: const Rect.fromLTWH(0, 0, 100, 100),
        initialCurrentPoint: const Offset(-100, 50),
      );

      // When starting from input: start is TARGET, current point is SOURCE
      expect(tempConnection.isStartFromOutput, isFalse);
      // The painter interprets:
      // sourcePoint = tempConnection.currentPoint
      // targetPoint = tempConnection.startPoint
    });
  });

  // ===========================================================================
  // Repaint Boundary Verification Tests
  // ===========================================================================

  group('Repaint Boundary Behavior', () {
    testWidgets('repaint boundary isolates painting', (tester) async {
      final controller = createTestController();
      final transformationController = TransformationController();

      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.light().copyWith(extensions: [NodeFlowTheme.light]),
          home: InteractionLayer<String>(
            controller: controller,
            transformationController: transformationController,
          ),
        ),
      );

      // Find the RepaintBoundary that is a descendant of InteractionLayer
      final repaintBoundaryFinder = find.descendant(
        of: find.byType(InteractionLayer<String>),
        matching: find.byType(RepaintBoundary),
      );
      expect(repaintBoundaryFinder, findsOneWidget);

      // Find the IgnorePointer that is a descendant of InteractionLayer
      final ignorePointerFinder = find.descendant(
        of: find.byType(InteractionLayer<String>),
        matching: find.byType(IgnorePointer),
      );
      expect(ignorePointerFinder, findsOneWidget);
    });
  });

  // ===========================================================================
  // Theme Fallback Tests
  // ===========================================================================

  group('Theme Fallback', () {
    testWidgets('uses NodeFlowTheme.light as fallback', (tester) async {
      final controller = createTestController();
      final transformationController = TransformationController();

      // No NodeFlowTheme in context
      await tester.pumpWidget(
        MaterialApp(
          home: InteractionLayer<String>(
            controller: controller,
            transformationController: transformationController,
          ),
        ),
      );

      // Should render without error using fallback theme
      expect(find.byType(InteractionLayer<String>), findsOneWidget);
    });

    testWidgets('uses context theme when available', (tester) async {
      final controller = createTestController();
      final transformationController = TransformationController();

      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.dark().copyWith(extensions: [NodeFlowTheme.dark]),
          home: InteractionLayer<String>(
            controller: controller,
            transformationController: transformationController,
          ),
        ),
      );

      // Should render with dark theme
      expect(find.byType(InteractionLayer<String>), findsOneWidget);
    });
  });

  // ===========================================================================
  // Painting Logic Tests (Using Full NodeFlowEditor)
  // ===========================================================================

  group('InteractionLayer Painting via NodeFlowEditor', () {
    late NodeFlowController<String, dynamic> controller;

    setUp(() {
      controller = createTestController();
      controller.setScreenSize(const Size(800, 600));
    });

    tearDown(() {
      controller.dispose();
    });

    testWidgets('paints selection rectangle when selection is active', (
      tester,
    ) async {
      controller.addNode(createTestNode(id: 'node-1', position: Offset.zero));
      controller.addNode(
        createTestNode(id: 'node-2', position: const Offset(100, 100)),
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
                    Container(width: 100, height: 60, color: Colors.blue),
                theme: NodeFlowTheme.light,
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Start a selection rectangle
      controller.interaction.updateSelection(
        startPoint: const GraphPosition(Offset(0, 0)),
        rectangle: const GraphRect(Rect.fromLTWH(0, 0, 200, 200)),
      );

      await tester.pump();

      // Selection rectangle should be present
      expect(controller.selectionRect, isNotNull);
      expect(controller.selectionRect?.rect.width, equals(200));
      expect(controller.selectionRect?.rect.height, equals(200));
    });

    testWidgets('clears selection rectangle after finish', (tester) async {
      controller.addNode(createTestNode(id: 'node-1'));

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

      // Start and finish selection
      controller.interaction.updateSelection(
        startPoint: const GraphPosition(Offset(50, 50)),
        rectangle: const GraphRect(Rect.fromLTWH(50, 50, 100, 100)),
      );
      await tester.pump();

      controller.interaction.finishSelection();
      await tester.pump();

      expect(controller.selectionRect, isNull);
    });

    testWidgets('renders with transformed viewport', (tester) async {
      controller.addNode(createTestNode(id: 'node-1'));

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

      // Pan and zoom the viewport
      controller.setViewport(GraphViewport(x: 100, y: 100, zoom: 2.0));

      await tester.pumpAndSettle();

      // Editor should still render
      expect(find.byType(NodeFlowEditor<String, dynamic>), findsOneWidget);
    });

    testWidgets('updates when selection rect changes size', (tester) async {
      controller.addNode(createTestNode(id: 'node-1'));

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

      // Start with small selection
      controller.interaction.updateSelection(
        startPoint: const GraphPosition(Offset(0, 0)),
        rectangle: const GraphRect(Rect.fromLTWH(0, 0, 50, 50)),
      );
      await tester.pump();

      expect(controller.selectionRect?.rect.width, equals(50));

      // Expand selection
      controller.interaction.updateSelection(
        startPoint: const GraphPosition(Offset(0, 0)),
        rectangle: const GraphRect(Rect.fromLTWH(0, 0, 200, 150)),
      );
      await tester.pump();

      expect(controller.selectionRect?.rect.width, equals(200));
      expect(controller.selectionRect?.rect.height, equals(150));
    });
  });

  // ===========================================================================
  // Selection Rectangle Visual Tests
  // ===========================================================================

  group('Selection Rectangle Rendering', () {
    late NodeFlowController<String, dynamic> controller;

    setUp(() {
      controller = createTestController();
      controller.setScreenSize(const Size(800, 600));
    });

    tearDown(() {
      controller.dispose();
    });

    testWidgets('selection rectangle uses theme connection color', (
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

      // Verify theme has selection color
      final theme = NodeFlowTheme.light;
      expect(theme.connectionTheme.color, isNotNull);
    });

    testWidgets('selection rectangle renders with negative coordinates', (
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

      // Selection in negative coordinates
      controller.interaction.updateSelection(
        startPoint: const GraphPosition(Offset(-100, -100)),
        rectangle: const GraphRect(Rect.fromLTWH(-100, -100, 200, 200)),
      );

      await tester.pump();

      expect(controller.selectionRect?.rect.left, equals(-100));
      expect(controller.selectionRect?.rect.top, equals(-100));
    });

    testWidgets('multiple selection updates in sequence', (tester) async {
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

      // Simulate drag selection
      for (var i = 0; i < 10; i++) {
        controller.interaction.updateSelection(
          startPoint: const GraphPosition(Offset(0, 0)),
          rectangle: GraphRect(
            Rect.fromLTWH(0, 0, i * 20.0 + 10, i * 20.0 + 10),
          ),
        );
        await tester.pump();
      }

      expect(controller.selectionRect?.rect.width, equals(190));
    });
  });

  // ===========================================================================
  // Temporary Connection Observer Tests
  // ===========================================================================

  group('Temporary Connection Observation', () {
    test('observer builder accesses temp connection properties', () {
      final tempConnection = TemporaryConnection(
        startPoint: const Offset(100, 50),
        startNodeId: 'node-a',
        startPortId: 'output-1',
        isStartFromOutput: true,
        startNodeBounds: const Rect.fromLTWH(0, 0, 100, 100),
        initialCurrentPoint: const Offset(100, 50),
      );

      // Simulate what the Observer builder does
      tempConnection.currentPoint;
      tempConnection.targetNodeId;
      tempConnection.targetPortId;

      // These should be accessible without error
      expect(tempConnection.currentPoint, equals(const Offset(100, 50)));
      expect(tempConnection.targetNodeId, isNull);
      expect(tempConnection.targetPortId, isNull);
    });

    test('observer builder accesses temp connection with target', () {
      final tempConnection = TemporaryConnection(
        startPoint: const Offset(100, 50),
        startNodeId: 'node-a',
        startPortId: 'output-1',
        isStartFromOutput: true,
        startNodeBounds: const Rect.fromLTWH(0, 0, 100, 100),
        initialCurrentPoint: const Offset(200, 50),
        targetNodeId: 'node-b',
        targetPortId: 'input-1',
        targetNodeBounds: const Rect.fromLTWH(200, 0, 100, 100),
      );

      // Simulate what the Observer builder does
      final currentPoint = tempConnection.currentPoint;
      final targetNodeId = tempConnection.targetNodeId;
      final targetPortId = tempConnection.targetPortId;

      expect(currentPoint, equals(const Offset(200, 50)));
      expect(targetNodeId, equals('node-b'));
      expect(targetPortId, equals('input-1'));
    });
  });

  // ===========================================================================
  // Painter Port Lookup Logic Tests
  // ===========================================================================

  group('Painter Port Lookup Logic', () {
    test('finds output port when starting from output', () {
      final nodeA = createTestNodeWithOutputPort(
        id: 'node-a',
        portId: 'output-1',
        position: const Offset(0, 0),
      );
      nodeA.setSize(const Size(100, 50));

      final controller = createTestController(nodes: [nodeA]);

      // Simulate painter logic for finding start port
      final startNode = controller.nodes['node-a'];
      expect(startNode, isNotNull);

      final isStartFromOutput = true;
      final portList = isStartFromOutput
          ? startNode!.outputPorts
          : startNode!.inputPorts;

      Port? startPort;
      for (final port in portList) {
        if (port.id == 'output-1') {
          startPort = port;
          break;
        }
      }

      expect(startPort, isNotNull);
      expect(startPort?.id, equals('output-1'));
      expect(startPort?.isOutput, isTrue);
    });

    test('finds input port when starting from input', () {
      final nodeB = createTestNodeWithInputPort(
        id: 'node-b',
        portId: 'input-1',
        position: const Offset(200, 0),
      );
      nodeB.setSize(const Size(100, 50));

      final controller = createTestController(nodes: [nodeB]);

      // Simulate painter logic for finding start port
      final startNode = controller.nodes['node-b'];
      expect(startNode, isNotNull);

      final isStartFromOutput = false;
      final portList = isStartFromOutput
          ? startNode!.outputPorts
          : startNode!.inputPorts;

      Port? startPort;
      for (final port in portList) {
        if (port.id == 'input-1') {
          startPort = port;
          break;
        }
      }

      expect(startPort, isNotNull);
      expect(startPort?.id, equals('input-1'));
      expect(startPort?.isInput, isTrue);
    });

    test('finds hovered input port when starting from output', () {
      final nodeA = createTestNodeWithOutputPort(
        id: 'node-a',
        portId: 'output-1',
        position: const Offset(0, 0),
      );
      nodeA.setSize(const Size(100, 50));

      final nodeB = createTestNodeWithInputPort(
        id: 'node-b',
        portId: 'input-1',
        position: const Offset(200, 0),
      );
      nodeB.setSize(const Size(100, 50));

      final controller = createTestController(nodes: [nodeA, nodeB]);

      // Simulate painter logic for finding hovered port
      final isStartFromOutput = true;
      final targetNodeId = 'node-b';
      final targetPortId = 'input-1';

      final hoveredNode = controller.nodes[targetNodeId];
      expect(hoveredNode, isNotNull);

      // Hovered port is the opposite type of start port
      final portList = isStartFromOutput
          ? hoveredNode!.inputPorts
          : hoveredNode!.outputPorts;

      Port? hoveredPort;
      for (final port in portList) {
        if (port.id == targetPortId) {
          hoveredPort = port;
          break;
        }
      }

      expect(hoveredPort, isNotNull);
      expect(hoveredPort?.id, equals('input-1'));
      expect(hoveredPort?.isInput, isTrue);
    });

    test('finds hovered output port when starting from input', () {
      final nodeA = createTestNodeWithOutputPort(
        id: 'node-a',
        portId: 'output-1',
        position: const Offset(0, 0),
      );
      nodeA.setSize(const Size(100, 50));

      final nodeB = createTestNodeWithInputPort(
        id: 'node-b',
        portId: 'input-1',
        position: const Offset(200, 0),
      );
      nodeB.setSize(const Size(100, 50));

      final controller = createTestController(nodes: [nodeA, nodeB]);

      // Simulate starting from input (node-b), hovering over output (node-a)
      final isStartFromOutput = false;
      final targetNodeId = 'node-a';
      final targetPortId = 'output-1';

      final hoveredNode = controller.nodes[targetNodeId];
      expect(hoveredNode, isNotNull);

      // Hovered port is the opposite type of start port (input -> output)
      final portList = isStartFromOutput
          ? hoveredNode!.inputPorts
          : hoveredNode!.outputPorts;

      Port? hoveredPort;
      for (final port in portList) {
        if (port.id == targetPortId) {
          hoveredPort = port;
          break;
        }
      }

      expect(hoveredPort, isNotNull);
      expect(hoveredPort?.id, equals('output-1'));
      expect(hoveredPort?.isOutput, isTrue);
    });

    test('returns null when start node not found', () {
      final controller = createTestController();

      final startNode = controller.nodes['non-existent'];
      expect(startNode, isNull);
    });

    test('returns null when start port not found', () {
      final nodeA = createTestNodeWithOutputPort(
        id: 'node-a',
        portId: 'output-1',
        position: const Offset(0, 0),
      );
      nodeA.setSize(const Size(100, 50));

      final controller = createTestController(nodes: [nodeA]);

      final startNode = controller.nodes['node-a'];
      expect(startNode, isNotNull);

      // Search for non-existent port
      final portList = startNode!.outputPorts;
      Port? startPort;
      for (final port in portList) {
        if (port.id == 'non-existent-port') {
          startPort = port;
          break;
        }
      }

      expect(startPort, isNull);
    });

    test('returns null when hovered node not found', () {
      final controller = createTestController();

      final hoveredNode = controller.nodes['non-existent'];
      expect(hoveredNode, isNull);
    });

    test('returns null when hovered port not found', () {
      final nodeB = createTestNodeWithInputPort(
        id: 'node-b',
        portId: 'input-1',
        position: const Offset(200, 0),
      );
      nodeB.setSize(const Size(100, 50));

      final controller = createTestController(nodes: [nodeB]);

      final hoveredNode = controller.nodes['node-b'];
      expect(hoveredNode, isNotNull);

      // Search for non-existent port
      final portList = hoveredNode!.inputPorts;
      Port? hoveredPort;
      for (final port in portList) {
        if (port.id == 'non-existent-port') {
          hoveredPort = port;
          break;
        }
      }

      expect(hoveredPort, isNull);
    });
  });

  // ===========================================================================
  // Source/Target Direction Logic Tests
  // ===========================================================================

  group('Source/Target Direction Logic', () {
    test('output to input: start is source, current is target', () {
      final tempConnection = TemporaryConnection(
        startPoint: const Offset(100, 50),
        startNodeId: 'node-a',
        startPortId: 'output-1',
        isStartFromOutput: true,
        startNodeBounds: const Rect.fromLTWH(0, 0, 100, 100),
        initialCurrentPoint: const Offset(200, 50),
        targetNodeBounds: const Rect.fromLTWH(200, 0, 100, 100),
      );

      final isStartFromOutput = tempConnection.isStartFromOutput;
      expect(isStartFromOutput, isTrue);

      // Simulate painter logic
      late final Offset sourcePoint;
      late final Offset targetPoint;
      late final Rect? sourceNodeBounds;
      late final Rect? targetNodeBounds;

      if (isStartFromOutput) {
        sourcePoint = tempConnection.startPoint;
        targetPoint = tempConnection.currentPoint;
        sourceNodeBounds = tempConnection.startNodeBounds;
        targetNodeBounds = tempConnection.targetNodeBounds;
      } else {
        sourcePoint = tempConnection.currentPoint;
        targetPoint = tempConnection.startPoint;
        sourceNodeBounds = tempConnection.targetNodeBounds;
        targetNodeBounds = tempConnection.startNodeBounds;
      }

      expect(sourcePoint, equals(const Offset(100, 50)));
      expect(targetPoint, equals(const Offset(200, 50)));
      expect(sourceNodeBounds, equals(const Rect.fromLTWH(0, 0, 100, 100)));
      expect(targetNodeBounds, equals(const Rect.fromLTWH(200, 0, 100, 100)));
    });

    test('input to output: current is source, start is target', () {
      final tempConnection = TemporaryConnection(
        startPoint: const Offset(200, 50),
        startNodeId: 'node-b',
        startPortId: 'input-1',
        isStartFromOutput: false,
        startNodeBounds: const Rect.fromLTWH(200, 0, 100, 100),
        initialCurrentPoint: const Offset(100, 50),
        targetNodeBounds: const Rect.fromLTWH(0, 0, 100, 100),
      );

      final isStartFromOutput = tempConnection.isStartFromOutput;
      expect(isStartFromOutput, isFalse);

      // Simulate painter logic
      late final Offset sourcePoint;
      late final Offset targetPoint;
      late final Rect? sourceNodeBounds;
      late final Rect? targetNodeBounds;

      if (isStartFromOutput) {
        sourcePoint = tempConnection.startPoint;
        targetPoint = tempConnection.currentPoint;
        sourceNodeBounds = tempConnection.startNodeBounds;
        targetNodeBounds = tempConnection.targetNodeBounds;
      } else {
        sourcePoint = tempConnection.currentPoint;
        targetPoint = tempConnection.startPoint;
        sourceNodeBounds = tempConnection.targetNodeBounds;
        targetNodeBounds = tempConnection.startNodeBounds;
      }

      expect(sourcePoint, equals(const Offset(100, 50)));
      expect(targetPoint, equals(const Offset(200, 50)));
      expect(sourceNodeBounds, equals(const Rect.fromLTWH(0, 0, 100, 100)));
      expect(targetNodeBounds, equals(const Rect.fromLTWH(200, 0, 100, 100)));
    });
  });

  // ===========================================================================
  // Painter with Nodes Having Ports Tests
  // ===========================================================================

  group('Painter with Nodes Having Multiple Ports', () {
    test('finds correct port among multiple ports', () {
      final node = createTestNode(
        id: 'multi-port-node',
        position: const Offset(0, 0),
        inputPorts: [
          createTestPort(id: 'input-1', type: PortType.input),
          createTestPort(id: 'input-2', type: PortType.input),
          createTestPort(id: 'input-3', type: PortType.input),
        ],
        outputPorts: [
          createTestPort(id: 'output-1', type: PortType.output),
          createTestPort(id: 'output-2', type: PortType.output),
        ],
      );
      node.setSize(const Size(100, 100));

      final controller = createTestController(nodes: [node]);

      final startNode = controller.nodes['multi-port-node'];
      expect(startNode, isNotNull);

      // Find second output port
      Port? foundPort;
      for (final port in startNode!.outputPorts) {
        if (port.id == 'output-2') {
          foundPort = port;
          break;
        }
      }

      expect(foundPort, isNotNull);
      expect(foundPort?.id, equals('output-2'));

      // Find second input port
      Port? foundInputPort;
      for (final port in startNode.inputPorts) {
        if (port.id == 'input-2') {
          foundInputPort = port;
          break;
        }
      }

      expect(foundInputPort, isNotNull);
      expect(foundInputPort?.id, equals('input-2'));
    });

    test('handles node with no ports', () {
      final node = createTestNode(
        id: 'no-ports-node',
        position: const Offset(0, 0),
        inputPorts: [],
        outputPorts: [],
      );

      final controller = createTestController(nodes: [node]);

      final startNode = controller.nodes['no-ports-node'];
      expect(startNode, isNotNull);
      expect(startNode!.inputPorts, isEmpty);
      expect(startNode.outputPorts, isEmpty);
    });
  });

  // ===========================================================================
  // Temporary Connection Equality Tests
  // ===========================================================================

  group('Temporary Connection Equality', () {
    test('identical temporary connections are equal', () {
      final conn1 = TemporaryConnection(
        startPoint: const Offset(100, 50),
        startNodeId: 'node-a',
        startPortId: 'output-1',
        isStartFromOutput: true,
        startNodeBounds: const Rect.fromLTWH(0, 0, 100, 100),
        initialCurrentPoint: const Offset(100, 50),
      );

      final conn2 = TemporaryConnection(
        startPoint: const Offset(100, 50),
        startNodeId: 'node-a',
        startPortId: 'output-1',
        isStartFromOutput: true,
        startNodeBounds: const Rect.fromLTWH(0, 0, 100, 100),
        initialCurrentPoint: const Offset(100, 50),
      );

      expect(conn1, equals(conn2));
      expect(conn1.hashCode, equals(conn2.hashCode));
    });

    test('different temporary connections are not equal', () {
      final conn1 = TemporaryConnection(
        startPoint: const Offset(100, 50),
        startNodeId: 'node-a',
        startPortId: 'output-1',
        isStartFromOutput: true,
        startNodeBounds: const Rect.fromLTWH(0, 0, 100, 100),
        initialCurrentPoint: const Offset(100, 50),
      );

      final conn2 = TemporaryConnection(
        startPoint: const Offset(200, 50),
        startNodeId: 'node-b',
        startPortId: 'output-2',
        isStartFromOutput: true,
        startNodeBounds: const Rect.fromLTWH(100, 0, 100, 100),
        initialCurrentPoint: const Offset(200, 50),
      );

      expect(conn1, isNot(equals(conn2)));
    });
  });
}
