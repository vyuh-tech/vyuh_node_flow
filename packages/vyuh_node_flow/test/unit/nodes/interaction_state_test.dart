/// Unit tests for [InteractionState].
///
/// Tests cover:
/// - Initial state values
/// - Observable properties (draggedNodeId, lastPointerPosition, temporaryConnection, etc.)
/// - Convenience getters
/// - State mutation methods (setDraggedNode, setPointerPosition, update, etc.)
/// - Selection state management
/// - Resize state management
/// - State reset behavior
@Tags(['unit'])
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vyuh_node_flow/src/connections/temporary_connection.dart';
import 'package:vyuh_node_flow/src/editor/resizer_widget.dart';
import 'package:vyuh_node_flow/src/graph/coordinates.dart';
import 'package:vyuh_node_flow/src/nodes/interaction_state.dart';

import '../../helpers/test_utils.dart';

void main() {
  late InteractionState state;

  setUp(() {
    state = InteractionState();
  });

  // ===========================================================================
  // Initial State
  // ===========================================================================
  group('Initial State', () {
    test('draggedNodeId is null initially', () {
      expect(state.draggedNodeId.value, isNull);
      expect(state.currentDraggedNodeId, isNull);
    });

    test('lastPointerPosition is null initially', () {
      expect(state.lastPointerPosition.value, isNull);
      expect(state.pointerPosition, isNull);
    });

    test('temporaryConnection is null initially', () {
      expect(state.temporaryConnection.value, isNull);
      expect(state.isCreatingConnection, isFalse);
    });

    test('selectionStart is null initially', () {
      expect(state.selectionStart.value, isNull);
      expect(state.selectionStartPoint, isNull);
    });

    test('selectionRect is null initially', () {
      expect(state.selectionRect.value, isNull);
      expect(state.currentSelectionRect, isNull);
      expect(state.isDrawingSelection, isFalse);
    });

    test('canvasLocked is false initially', () {
      expect(state.canvasLocked.value, isFalse);
      expect(state.isCanvasLocked, isFalse);
    });

    test('isViewportInteracting is false initially', () {
      expect(state.isViewportInteracting.value, isFalse);
      expect(state.isViewportDragging, isFalse);
    });

    test('hoveringConnection is false initially', () {
      expect(state.hoveringConnection.value, isFalse);
      expect(state.isHoveringConnection, isFalse);
    });

    test('cursorOverride is null initially', () {
      expect(state.cursorOverride.value, isNull);
      expect(state.currentCursorOverride, isNull);
      expect(state.hasCursorOverride, isFalse);
    });

    test('selectionStarted is false initially', () {
      expect(state.selectionStarted.value, isFalse);
      expect(state.hasStartedSelection, isFalse);
    });

    test('resizingNodeId is null initially', () {
      expect(state.resizingNodeId.value, isNull);
      expect(state.currentResizingNodeId, isNull);
      expect(state.isResizing, isFalse);
    });

    test('resizeHandle is null initially', () {
      expect(state.resizeHandle.value, isNull);
      expect(state.currentResizeHandle, isNull);
    });

    test('resizeStartPosition is null initially', () {
      expect(state.resizeStartPosition.value, isNull);
      expect(state.currentResizeStartPosition, isNull);
    });

    test('originalNodeBounds is null initially', () {
      expect(state.originalNodeBounds.value, isNull);
      expect(state.currentOriginalNodeBounds, isNull);
    });

    test('handleDrift is Offset.zero initially', () {
      expect(state.handleDrift.value, equals(Offset.zero));
      expect(state.currentHandleDrift, equals(Offset.zero));
    });
  });

  // ===========================================================================
  // Dragged Node State
  // ===========================================================================
  group('Dragged Node State', () {
    test('setDraggedNode sets the dragged node ID', () {
      state.setDraggedNode('node-1');

      expect(state.draggedNodeId.value, equals('node-1'));
      expect(state.currentDraggedNodeId, equals('node-1'));
    });

    test('setDraggedNode can clear the dragged node', () {
      state.setDraggedNode('node-1');
      state.setDraggedNode(null);

      expect(state.draggedNodeId.value, isNull);
      expect(state.currentDraggedNodeId, isNull);
    });

    test('draggedNodeId is observable', () {
      final tracker = ObservableTracker<String?>();
      tracker.track(state.draggedNodeId);

      state.setDraggedNode('node-1');
      state.setDraggedNode('node-2');
      state.setDraggedNode(null);

      expect(
        tracker.values,
        containsAllInOrder([null, 'node-1', 'node-2', null]),
      );
      tracker.dispose();
    });
  });

  // ===========================================================================
  // Pointer Position State
  // ===========================================================================
  group('Pointer Position State', () {
    test('setPointerPosition sets the pointer position', () {
      final position = ScreenPosition.fromXY(100, 200);
      state.setPointerPosition(position);

      expect(state.lastPointerPosition.value, equals(position));
      expect(state.pointerPosition, equals(position));
    });

    test('setPointerPosition can clear the pointer position', () {
      state.setPointerPosition(ScreenPosition.fromXY(100, 200));
      state.setPointerPosition(null);

      expect(state.lastPointerPosition.value, isNull);
      expect(state.pointerPosition, isNull);
    });

    test('lastPointerPosition is observable', () {
      final tracker = ObservableTracker<ScreenPosition?>();
      tracker.track(state.lastPointerPosition);

      final pos1 = ScreenPosition.fromXY(50, 50);
      final pos2 = ScreenPosition.fromXY(100, 100);

      state.setPointerPosition(pos1);
      state.setPointerPosition(pos2);

      expect(tracker.values, containsAllInOrder([null, pos1, pos2]));
      tracker.dispose();
    });
  });

  // ===========================================================================
  // Temporary Connection State
  // ===========================================================================
  group('Temporary Connection State', () {
    TemporaryConnection createTempConnection() {
      return TemporaryConnection(
        startPoint: const Offset(100, 100),
        startNodeId: 'source-node',
        startPortId: 'output-1',
        isStartFromOutput: true,
        startNodeBounds: const Rect.fromLTWH(50, 50, 100, 100),
        initialCurrentPoint: const Offset(100, 100),
      );
    }

    test('update sets temporary connection', () {
      final tempConnection = createTempConnection();

      state.update(temporaryConnection: tempConnection);

      expect(state.temporaryConnection.value, equals(tempConnection));
      expect(state.isCreatingConnection, isTrue);
    });

    test('connectionStartNodeId returns the source node ID', () {
      final tempConnection = createTempConnection();
      state.update(temporaryConnection: tempConnection);

      expect(state.connectionStartNodeId, equals('source-node'));
    });

    test('connectionStartPortId returns the source port ID', () {
      final tempConnection = createTempConnection();
      state.update(temporaryConnection: tempConnection);

      expect(state.connectionStartPortId, equals('output-1'));
    });

    test('cancelConnection clears temporary connection', () {
      state.update(temporaryConnection: createTempConnection());
      state.cancelConnection();

      expect(state.temporaryConnection.value, isNull);
      expect(state.isCreatingConnection, isFalse);
      expect(state.connectionStartNodeId, isNull);
      expect(state.connectionStartPortId, isNull);
    });

    test('temporaryConnection is observable', () {
      final tracker = ObservableTracker<TemporaryConnection?>();
      tracker.track(state.temporaryConnection);

      final tempConnection = createTempConnection();
      state.update(temporaryConnection: tempConnection);
      state.cancelConnection();

      expect(tracker.values.length, equals(3));
      expect(tracker.values[0], isNull);
      expect(tracker.values[1], equals(tempConnection));
      expect(tracker.values[2], isNull);
      tracker.dispose();
    });
  });

  // ===========================================================================
  // Canvas Lock State
  // ===========================================================================
  group('Canvas Lock State', () {
    test('update sets canvasLocked', () {
      state.update(canvasLocked: true);

      expect(state.canvasLocked.value, isTrue);
      expect(state.isCanvasLocked, isTrue);
    });

    test('update can unlock canvas', () {
      state.update(canvasLocked: true);
      state.update(canvasLocked: false);

      expect(state.canvasLocked.value, isFalse);
      expect(state.isCanvasLocked, isFalse);
    });

    test('canvasLocked is observable', () {
      final tracker = ObservableTracker<bool>();
      tracker.track(state.canvasLocked);

      state.update(canvasLocked: true);
      state.update(canvasLocked: false);

      expect(tracker.values, containsAllInOrder([false, true, false]));
      tracker.dispose();
    });
  });

  // ===========================================================================
  // Selection State
  // ===========================================================================
  group('Selection State', () {
    test('updateSelection sets selection start point', () {
      final startPoint = GraphPosition.fromXY(100, 100);

      state.updateSelection(startPoint: startPoint);

      expect(state.selectionStart.value, equals(startPoint));
      expect(state.selectionStartPoint, equals(startPoint));
    });

    test('updateSelection sets selection rectangle', () {
      final rect = GraphRect.fromLTWH(100, 100, 200, 150);

      state.updateSelection(rectangle: rect);

      expect(state.selectionRect.value, equals(rect));
      expect(state.currentSelectionRect, equals(rect));
      expect(state.isDrawingSelection, isTrue);
    });

    test('updateSelection calls selectNodes callback without toggle', () {
      final selectedNodes = <List<String>>[];

      state.updateSelection(
        rectangle: GraphRect.fromLTWH(0, 0, 100, 100),
        intersectingNodes: ['node-1', 'node-2'],
        toggle: false,
        selectNodes: (List<String> nodes, {bool toggle = false}) {
          selectedNodes.add(nodes);
          return null;
        },
      );

      expect(selectedNodes.length, equals(1));
      expect(selectedNodes.first, containsAll(['node-1', 'node-2']));
    });

    test('updateSelection calls selectNodes callback with toggle', () {
      final toggledNodes = <List<String>>[];
      var toggleState = false;

      state.updateSelection(
        rectangle: GraphRect.fromLTWH(0, 0, 100, 100),
        intersectingNodes: ['node-1', 'node-2'],
        toggle: true,
        selectNodes: (List<String> nodes, {bool toggle = false}) {
          toggledNodes.add(nodes);
          toggleState = toggle;
          return null;
        },
      );

      // First call with toggle=true should select nodes that changed state
      expect(toggledNodes.length, equals(1));
      expect(toggleState, isTrue);
    });

    test('updateSelection toggle mode prevents flickering', () {
      final toggledNodes = <List<String>>[];

      // First update: nodes 1, 2 intersecting
      state.updateSelection(
        rectangle: GraphRect.fromLTWH(0, 0, 100, 100),
        intersectingNodes: ['node-1', 'node-2'],
        toggle: true,
        selectNodes: (List<String> nodes, {bool toggle = false}) {
          toggledNodes.add(nodes);
          return null;
        },
      );

      // Second update: same nodes still intersecting - should not toggle again
      toggledNodes.clear();
      state.updateSelection(
        rectangle: GraphRect.fromLTWH(0, 0, 100, 100),
        intersectingNodes: ['node-1', 'node-2'],
        toggle: true,
        selectNodes: (List<String> nodes, {bool toggle = false}) {
          toggledNodes.add(nodes);
          return null;
        },
      );

      // Should not call selectNodes since intersection state didn't change
      expect(toggledNodes.isEmpty || toggledNodes.first.isEmpty, isTrue);
    });

    test('updateSelection toggle mode detects changed intersections', () {
      final toggledNodes = <List<String>>[];

      // First update: nodes 1, 2 intersecting
      state.updateSelection(
        rectangle: GraphRect.fromLTWH(0, 0, 100, 100),
        intersectingNodes: ['node-1', 'node-2'],
        toggle: true,
        selectNodes: (List<String> nodes, {bool toggle = false}) {
          toggledNodes.add(nodes);
          return null;
        },
      );

      toggledNodes.clear();

      // Second update: node-3 added, node-1 removed
      state.updateSelection(
        rectangle: GraphRect.fromLTWH(0, 0, 100, 100),
        intersectingNodes: ['node-2', 'node-3'],
        toggle: true,
        selectNodes: (List<String> nodes, {bool toggle = false}) {
          toggledNodes.add(List.from(nodes));
          return null;
        },
      );

      // Should toggle node-1 (left) and node-3 (entered)
      expect(toggledNodes.length, equals(1));
      expect(toggledNodes.first, containsAll(['node-1', 'node-3']));
    });

    test('finishSelection clears selection state', () {
      state.updateSelection(
        startPoint: GraphPosition.fromXY(0, 0),
        rectangle: GraphRect.fromLTWH(0, 0, 100, 100),
      );

      state.finishSelection();

      expect(state.selectionStart.value, isNull);
      expect(state.selectionRect.value, isNull);
      expect(state.isDrawingSelection, isFalse);
    });

    test('setSelectionStarted sets selection started state', () {
      state.setSelectionStarted(true);

      expect(state.selectionStarted.value, isTrue);
      expect(state.hasStartedSelection, isTrue);
    });

    test('setSelectionStarted can reset state', () {
      state.setSelectionStarted(true);
      state.setSelectionStarted(false);

      expect(state.selectionStarted.value, isFalse);
      expect(state.hasStartedSelection, isFalse);
    });

    test('selection state is observable', () {
      final startTracker = ObservableTracker<GraphPosition?>();
      startTracker.track(state.selectionStart);

      final rectTracker = ObservableTracker<GraphRect?>();
      rectTracker.track(state.selectionRect);

      final startPoint = GraphPosition.fromXY(50, 50);
      final rect = GraphRect.fromLTWH(50, 50, 100, 100);

      state.updateSelection(startPoint: startPoint, rectangle: rect);
      state.finishSelection();

      expect(startTracker.values, containsAllInOrder([null, startPoint, null]));
      expect(rectTracker.values, containsAllInOrder([null, rect, null]));

      startTracker.dispose();
      rectTracker.dispose();
    });
  });

  // ===========================================================================
  // Viewport Interaction State
  // ===========================================================================
  group('Viewport Interaction State', () {
    test('setViewportInteracting sets interaction state', () {
      state.setViewportInteracting(true);

      expect(state.isViewportInteracting.value, isTrue);
      expect(state.isViewportDragging, isTrue);
    });

    test('setViewportInteracting can reset state', () {
      state.setViewportInteracting(true);
      state.setViewportInteracting(false);

      expect(state.isViewportInteracting.value, isFalse);
      expect(state.isViewportDragging, isFalse);
    });

    test('isViewportInteracting is observable', () {
      final tracker = ObservableTracker<bool>();
      tracker.track(state.isViewportInteracting);

      state.setViewportInteracting(true);
      state.setViewportInteracting(false);

      expect(tracker.values, containsAllInOrder([false, true, false]));
      tracker.dispose();
    });
  });

  // ===========================================================================
  // Hovering Connection State
  // ===========================================================================
  group('Hovering Connection State', () {
    test('setHoveringConnection sets hovering state', () {
      state.setHoveringConnection(true);

      expect(state.hoveringConnection.value, isTrue);
      expect(state.isHoveringConnection, isTrue);
    });

    test('setHoveringConnection can reset state', () {
      state.setHoveringConnection(true);
      state.setHoveringConnection(false);

      expect(state.hoveringConnection.value, isFalse);
      expect(state.isHoveringConnection, isFalse);
    });

    test('hoveringConnection is observable', () {
      final tracker = ObservableTracker<bool>();
      tracker.track(state.hoveringConnection);

      state.setHoveringConnection(true);
      state.setHoveringConnection(false);

      expect(tracker.values, containsAllInOrder([false, true, false]));
      tracker.dispose();
    });
  });

  // ===========================================================================
  // Cursor Override State
  // ===========================================================================
  group('Cursor Override State', () {
    test('setCursorOverride sets cursor', () {
      state.setCursorOverride(SystemMouseCursors.grab);

      expect(state.cursorOverride.value, equals(SystemMouseCursors.grab));
      expect(state.currentCursorOverride, equals(SystemMouseCursors.grab));
      expect(state.hasCursorOverride, isTrue);
    });

    test('setCursorOverride can clear cursor', () {
      state.setCursorOverride(SystemMouseCursors.grab);
      state.setCursorOverride(null);

      expect(state.cursorOverride.value, isNull);
      expect(state.currentCursorOverride, isNull);
      expect(state.hasCursorOverride, isFalse);
    });

    test('cursorOverride is observable', () {
      final tracker = ObservableTracker<MouseCursor?>();
      tracker.track(state.cursorOverride);

      state.setCursorOverride(SystemMouseCursors.grab);
      state.setCursorOverride(SystemMouseCursors.grabbing);
      state.setCursorOverride(null);

      expect(
        tracker.values,
        containsAllInOrder([
          null,
          SystemMouseCursors.grab,
          SystemMouseCursors.grabbing,
          null,
        ]),
      );
      tracker.dispose();
    });
  });

  // ===========================================================================
  // Resize State
  // ===========================================================================
  group('Resize State', () {
    test('startResize initializes resize state', () {
      state.startResize(
        'node-1',
        ResizeHandle.bottomRight,
        const Offset(200, 200),
        const Rect.fromLTWH(100, 100, 100, 100),
      );

      expect(state.resizingNodeId.value, equals('node-1'));
      expect(state.currentResizingNodeId, equals('node-1'));
      expect(state.resizeHandle.value, equals(ResizeHandle.bottomRight));
      expect(state.currentResizeHandle, equals(ResizeHandle.bottomRight));
      expect(state.resizeStartPosition.value, equals(const Offset(200, 200)));
      expect(state.currentResizeStartPosition, equals(const Offset(200, 200)));
      expect(
        state.originalNodeBounds.value,
        equals(const Rect.fromLTWH(100, 100, 100, 100)),
      );
      expect(
        state.currentOriginalNodeBounds,
        equals(const Rect.fromLTWH(100, 100, 100, 100)),
      );
      expect(state.handleDrift.value, equals(Offset.zero));
      expect(state.isResizing, isTrue);
      expect(state.isCanvasLocked, isTrue);
    });

    test('startResize sets cursor override based on handle', () {
      state.startResize(
        'node-1',
        ResizeHandle.topLeft,
        const Offset(100, 100),
        const Rect.fromLTWH(100, 100, 100, 100),
      );

      expect(state.hasCursorOverride, isTrue);
      expect(
        state.currentCursorOverride,
        equals(SystemMouseCursors.resizeUpLeftDownRight),
      );
    });

    test('setHandleDrift updates drift value', () {
      state.startResize(
        'node-1',
        ResizeHandle.bottomRight,
        const Offset(200, 200),
        const Rect.fromLTWH(100, 100, 100, 100),
      );

      state.setHandleDrift(const Offset(10, 15));

      expect(state.handleDrift.value, equals(const Offset(10, 15)));
      expect(state.currentHandleDrift, equals(const Offset(10, 15)));
    });

    test('endResize clears resize state', () {
      state.startResize(
        'node-1',
        ResizeHandle.bottomRight,
        const Offset(200, 200),
        const Rect.fromLTWH(100, 100, 100, 100),
      );
      state.setHandleDrift(const Offset(10, 15));

      state.endResize();

      expect(state.resizingNodeId.value, isNull);
      expect(state.currentResizingNodeId, isNull);
      expect(state.resizeHandle.value, isNull);
      expect(state.currentResizeHandle, isNull);
      expect(state.resizeStartPosition.value, isNull);
      expect(state.currentResizeStartPosition, isNull);
      expect(state.originalNodeBounds.value, isNull);
      expect(state.currentOriginalNodeBounds, isNull);
      expect(state.handleDrift.value, equals(Offset.zero));
      expect(state.currentHandleDrift, equals(Offset.zero));
      expect(state.isResizing, isFalse);
      expect(state.isCanvasLocked, isFalse);
      expect(state.hasCursorOverride, isFalse);
    });

    test('resize state is observable', () {
      final resizingTracker = ObservableTracker<String?>();
      resizingTracker.track(state.resizingNodeId);

      state.startResize(
        'node-1',
        ResizeHandle.bottomRight,
        const Offset(200, 200),
        const Rect.fromLTWH(100, 100, 100, 100),
      );
      state.endResize();

      expect(
        resizingTracker.values,
        containsAllInOrder([null, 'node-1', null]),
      );
      resizingTracker.dispose();
    });

    test('different resize handles have correct cursors', () {
      final handleCursors = {
        ResizeHandle.topLeft: SystemMouseCursors.resizeUpLeftDownRight,
        ResizeHandle.topRight: SystemMouseCursors.resizeUpRightDownLeft,
        ResizeHandle.bottomLeft: SystemMouseCursors.resizeUpRightDownLeft,
        ResizeHandle.bottomRight: SystemMouseCursors.resizeUpLeftDownRight,
        ResizeHandle.topCenter: SystemMouseCursors.resizeUpDown,
        ResizeHandle.bottomCenter: SystemMouseCursors.resizeUpDown,
        ResizeHandle.centerLeft: SystemMouseCursors.resizeLeftRight,
        ResizeHandle.centerRight: SystemMouseCursors.resizeLeftRight,
      };

      for (final entry in handleCursors.entries) {
        state.startResize(
          'node-1',
          entry.key,
          const Offset(100, 100),
          const Rect.fromLTWH(50, 50, 100, 100),
        );

        expect(
          state.currentCursorOverride,
          equals(entry.value),
          reason: 'Handle ${entry.key} should have cursor ${entry.value}',
        );

        state.endResize();
      }
    });
  });

  // ===========================================================================
  // Reset State
  // ===========================================================================
  group('Reset State', () {
    test('resetState clears all interaction state', () {
      // Set up various states
      state.setDraggedNode('node-1');
      state.setPointerPosition(ScreenPosition.fromXY(100, 100));
      state.update(
        canvasLocked: true,
        temporaryConnection: TemporaryConnection(
          startPoint: const Offset(100, 100),
          startNodeId: 'node-1',
          startPortId: 'output-1',
          isStartFromOutput: true,
          startNodeBounds: const Rect.fromLTWH(50, 50, 100, 100),
          initialCurrentPoint: const Offset(100, 100),
        ),
      );
      state.updateSelection(
        startPoint: GraphPosition.fromXY(0, 0),
        rectangle: GraphRect.fromLTWH(0, 0, 100, 100),
      );
      state.setViewportInteracting(true);
      state.setHoveringConnection(true);
      state.setCursorOverride(SystemMouseCursors.grab);
      state.setSelectionStarted(true);
      state.startResize(
        'node-2',
        ResizeHandle.bottomRight,
        const Offset(200, 200),
        const Rect.fromLTWH(100, 100, 100, 100),
      );

      state.resetState();

      // Verify all state is reset
      expect(state.draggedNodeId.value, isNull);
      expect(state.lastPointerPosition.value, isNull);
      expect(state.temporaryConnection.value, isNull);
      expect(state.selectionStart.value, isNull);
      expect(state.selectionRect.value, isNull);
      expect(state.canvasLocked.value, isFalse);
      expect(state.isViewportInteracting.value, isFalse);
      expect(state.hoveringConnection.value, isFalse);
      expect(state.cursorOverride.value, isNull);
      expect(state.selectionStarted.value, isFalse);
      expect(state.resizingNodeId.value, isNull);
      expect(state.resizeHandle.value, isNull);
      expect(state.resizeStartPosition.value, isNull);
      expect(state.originalNodeBounds.value, isNull);
      expect(state.handleDrift.value, equals(Offset.zero));
    });

    test('resetState can be called on clean state', () {
      // Should not throw
      expect(() => state.resetState(), returnsNormally);

      // State should remain clean
      expect(state.draggedNodeId.value, isNull);
      expect(state.isResizing, isFalse);
    });
  });

  // ===========================================================================
  // Update Method
  // ===========================================================================
  group('Update Method', () {
    test('update with null parameters does not change state', () {
      state.update(canvasLocked: true);
      final tempConnection = TemporaryConnection(
        startPoint: const Offset(0, 0),
        startNodeId: 'node-1',
        startPortId: 'port-1',
        isStartFromOutput: true,
        startNodeBounds: const Rect.fromLTWH(0, 0, 100, 100),
        initialCurrentPoint: const Offset(0, 0),
      );
      state.update(temporaryConnection: tempConnection);

      // Update with null parameters
      state.update();

      // State should remain unchanged
      expect(state.isCanvasLocked, isTrue);
      expect(state.temporaryConnection.value, equals(tempConnection));
    });

    test('update sets multiple properties atomically', () {
      final tempConnection = TemporaryConnection(
        startPoint: const Offset(100, 100),
        startNodeId: 'node-1',
        startPortId: 'output-1',
        isStartFromOutput: true,
        startNodeBounds: const Rect.fromLTWH(50, 50, 100, 100),
        initialCurrentPoint: const Offset(100, 100),
      );

      state.update(canvasLocked: true, temporaryConnection: tempConnection);

      expect(state.isCanvasLocked, isTrue);
      expect(state.temporaryConnection.value, equals(tempConnection));
    });
  });

  // ===========================================================================
  // Edge Cases
  // ===========================================================================
  group('Edge Cases', () {
    test('rapid state changes are handled correctly', () {
      for (var i = 0; i < 100; i++) {
        state.setDraggedNode('node-$i');
      }
      state.setDraggedNode(null);

      expect(state.currentDraggedNodeId, isNull);
    });

    test('multiple resize operations do not leak state', () {
      // First resize
      state.startResize(
        'node-1',
        ResizeHandle.topLeft,
        const Offset(100, 100),
        const Rect.fromLTWH(100, 100, 100, 100),
      );
      state.setHandleDrift(const Offset(50, 50));
      state.endResize();

      // Second resize
      state.startResize(
        'node-2',
        ResizeHandle.bottomRight,
        const Offset(200, 200),
        const Rect.fromLTWH(150, 150, 150, 150),
      );

      // Should not have drift from first resize
      expect(state.currentHandleDrift, equals(Offset.zero));
      expect(state.currentResizingNodeId, equals('node-2'));
      expect(state.currentResizeHandle, equals(ResizeHandle.bottomRight));
    });

    test('selection toggle with empty intersecting nodes', () {
      var callCount = 0;

      state.updateSelection(
        rectangle: GraphRect.fromLTWH(0, 0, 100, 100),
        intersectingNodes: [],
        toggle: true,
        selectNodes: (List<String> nodes, {bool toggle = false}) {
          callCount++;
          return null;
        },
      );

      // Should not call selectNodes for empty intersection change
      // First call establishes baseline, no change from empty to empty
      expect(callCount, equals(0));
    });

    test('selection finishes clears previous intersecting tracking', () {
      final selectedNodes = <List<String>>[];

      // First selection
      state.updateSelection(
        startPoint: GraphPosition.fromXY(0, 0),
        rectangle: GraphRect.fromLTWH(0, 0, 100, 100),
        intersectingNodes: ['node-1'],
        toggle: true,
        selectNodes: (List<String> nodes, {bool toggle = false}) {
          selectedNodes.add(List.from(nodes));
          return null;
        },
      );
      state.finishSelection();

      selectedNodes.clear();

      // Second selection - should not remember previous intersection
      state.updateSelection(
        startPoint: GraphPosition.fromXY(0, 0),
        rectangle: GraphRect.fromLTWH(0, 0, 100, 100),
        intersectingNodes: ['node-1'],
        toggle: true,
        selectNodes: (List<String> nodes, {bool toggle = false}) {
          selectedNodes.add(List.from(nodes));
          return null;
        },
      );

      // Should toggle node-1 again since we finished and started a new selection
      expect(selectedNodes.length, equals(1));
      expect(selectedNodes.first, contains('node-1'));
    });

    test('concurrent state modifications work correctly', () {
      // Simulate concurrent updates that might happen during user interaction
      state.setDraggedNode('node-1');
      state.setPointerPosition(ScreenPosition.fromXY(100, 100));
      state.update(canvasLocked: true);

      expect(state.currentDraggedNodeId, equals('node-1'));
      expect(state.pointerPosition?.dx, equals(100));
      expect(state.isCanvasLocked, isTrue);
    });
  });

  // ===========================================================================
  // ResizeHandle Extension Tests
  // ===========================================================================
  group('ResizeHandle Extension', () {
    test('corner handles are identified correctly', () {
      expect(ResizeHandle.topLeft.isCorner, isTrue);
      expect(ResizeHandle.topRight.isCorner, isTrue);
      expect(ResizeHandle.bottomLeft.isCorner, isTrue);
      expect(ResizeHandle.bottomRight.isCorner, isTrue);
    });

    test('edge handles are identified correctly', () {
      expect(ResizeHandle.topCenter.isEdge, isTrue);
      expect(ResizeHandle.bottomCenter.isEdge, isTrue);
      expect(ResizeHandle.centerLeft.isEdge, isTrue);
      expect(ResizeHandle.centerRight.isEdge, isTrue);
    });

    test('corner handles are not edge handles', () {
      expect(ResizeHandle.topLeft.isEdge, isFalse);
      expect(ResizeHandle.topRight.isEdge, isFalse);
      expect(ResizeHandle.bottomLeft.isEdge, isFalse);
      expect(ResizeHandle.bottomRight.isEdge, isFalse);
    });

    test('edge handles are not corner handles', () {
      expect(ResizeHandle.topCenter.isCorner, isFalse);
      expect(ResizeHandle.bottomCenter.isCorner, isFalse);
      expect(ResizeHandle.centerLeft.isCorner, isFalse);
      expect(ResizeHandle.centerRight.isCorner, isFalse);
    });

    test('edges list contains only edge handles', () {
      final edges = ResizeHandleExtension.edges;

      expect(edges.length, equals(4));
      expect(edges, contains(ResizeHandle.topCenter));
      expect(edges, contains(ResizeHandle.bottomCenter));
      expect(edges, contains(ResizeHandle.centerLeft));
      expect(edges, contains(ResizeHandle.centerRight));
      expect(edges.every((h) => h.isEdge), isTrue);
    });

    test('all ResizeHandle values exist', () {
      expect(ResizeHandle.values.length, equals(8));
    });
  });
}
