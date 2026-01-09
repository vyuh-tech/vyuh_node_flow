/// Unit tests for InteractionState selection-related functionality.
///
/// Tests cover:
/// - Selection drag canvas locking
/// - Canvas unlocking on finishSelection
@Tags(['unit'])
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:vyuh_node_flow/src/nodes/interaction_state.dart';
import 'package:vyuh_node_flow/src/graph/coordinates.dart';

void main() {
  late InteractionState state;

  setUp(() {
    state = InteractionState();
  });

  group('Selection Drag Canvas Locking', () {
    test('canvasLocked is false by default', () {
      expect(state.canvasLocked.value, isFalse);
    });

    test('canvasLocked can be set to true for selection drag', () {
      state.canvasLocked.value = true;
      expect(state.canvasLocked.value, isTrue);
    });

    test('finishSelection clears selection start point', () {
      // Set up selection drag state
      state.updateSelection(
        startPoint: const GraphPosition(Offset(100, 100)),
        rectangle: GraphRect.fromPoints(
          const GraphPosition(Offset(100, 100)),
          const GraphPosition(Offset(200, 200)),
        ),
      );
      expect(state.selectionStart.value, isNotNull);

      state.finishSelection();

      expect(state.selectionStart.value, isNull);
    });

    test('finishSelection clears selection rectangle', () {
      // Set up selection drag state
      state.updateSelection(
        startPoint: const GraphPosition(Offset(100, 100)),
        rectangle: GraphRect.fromPoints(
          const GraphPosition(Offset(100, 100)),
          const GraphPosition(Offset(200, 200)),
        ),
      );
      expect(state.selectionRect.value, isNotNull);

      state.finishSelection();

      expect(state.selectionRect.value, isNull);
    });

    test('finishSelection unlocks canvas', () {
      // Set up selection drag state with canvas locked
      state.canvasLocked.value = true;
      state.updateSelection(
        startPoint: const GraphPosition(Offset(100, 100)),
        rectangle: GraphRect.fromPoints(
          const GraphPosition(Offset(100, 100)),
          const GraphPosition(Offset(200, 200)),
        ),
      );
      expect(state.canvasLocked.value, isTrue);

      state.finishSelection();

      // Canvas should be unlocked after finishing selection
      expect(state.canvasLocked.value, isFalse);
    });

    test('isDrawingSelection returns true during selection drag', () {
      expect(state.isDrawingSelection, isFalse);

      state.updateSelection(
        startPoint: const GraphPosition(Offset(100, 100)),
        rectangle: GraphRect.fromPoints(
          const GraphPosition(Offset(100, 100)),
          const GraphPosition(Offset(200, 200)),
        ),
      );

      expect(state.isDrawingSelection, isTrue);

      state.finishSelection();

      expect(state.isDrawingSelection, isFalse);
    });

    test('isCanvasLocked getter reflects canvasLocked value', () {
      expect(state.isCanvasLocked, isFalse);

      state.canvasLocked.value = true;
      expect(state.isCanvasLocked, isTrue);

      state.finishSelection();
      expect(state.isCanvasLocked, isFalse);
    });
  });

  group('Selection State Management', () {
    test('updateSelection sets both start point and rectangle', () {
      state.updateSelection(
        startPoint: const GraphPosition(Offset(50, 50)),
        rectangle: GraphRect.fromPoints(
          const GraphPosition(Offset(50, 50)),
          const GraphPosition(Offset(150, 150)),
        ),
      );

      expect(state.selectionStartPoint?.offset, equals(const Offset(50, 50)));
      expect(state.currentSelectionRect, isNotNull);
    });

    test('resetState clears all selection state and unlocks canvas', () {
      // Set up various interaction state
      state.canvasLocked.value = true;
      state.updateSelection(
        startPoint: const GraphPosition(Offset(100, 100)),
        rectangle: GraphRect.fromPoints(
          const GraphPosition(Offset(100, 100)),
          const GraphPosition(Offset(200, 200)),
        ),
      );
      state.draggedNodeId.value = 'test-node';

      state.resetState();

      expect(state.canvasLocked.value, isFalse);
      expect(state.selectionStart.value, isNull);
      expect(state.selectionRect.value, isNull);
      expect(state.draggedNodeId.value, isNull);
    });
  });
}
