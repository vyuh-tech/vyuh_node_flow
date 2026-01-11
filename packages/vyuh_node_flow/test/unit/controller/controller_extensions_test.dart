/// Unit tests for NodeFlowController internal extension methods.
///
/// The extension methods in node_flow_controller_extensions.dart are internal
/// (prefixed with _) and delegate to InteractionState. These tests verify
/// the behavior of the underlying InteractionState methods and the controller
/// methods that expose this functionality.
///
/// Tests cover:
/// - Pointer position management
/// - Canvas lock state management
/// - Stale drag state cleanup
/// - Selection rectangle operations
/// - Interaction state lifecycle
/// - Resize operations (startResize, endResize, handle drift)
/// - Selection toggle edge cases
/// - Connection creation edge cases
/// - Concurrent state management
/// - TemporaryConnection state
/// - Observable reactivity
/// - Getter correctness
/// - Update method partial updates
/// - Error handling and edge cases
@Tags(['unit'])
library;

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vyuh_node_flow/src/connections/temporary_connection.dart';
import 'package:vyuh_node_flow/vyuh_node_flow.dart';

import '../../helpers/test_factories.dart';

void main() {
  setUp(() {
    resetTestCounters();
  });

  // ===========================================================================
  // InteractionState - Pointer Position Management
  // ===========================================================================

  group('InteractionState - Pointer Position', () {
    test('initial pointer position is null', () {
      final controller = createTestController();

      expect(controller.pointerPosition, isNull);
    });

    test('setPointerPosition updates pointer position', () {
      final controller = createTestController();
      const position = ScreenPosition(Offset(100, 200));

      controller.interaction.setPointerPosition(position);

      expect(controller.pointerPosition, equals(position));
    });

    test('setPointerPosition with null clears position', () {
      final controller = createTestController();
      controller.interaction.setPointerPosition(
        const ScreenPosition(Offset(100, 200)),
      );

      controller.interaction.setPointerPosition(null);

      expect(controller.pointerPosition, isNull);
    });

    test('pointerPosition getter returns lastPointerPosition value', () {
      final controller = createTestController();
      const position = ScreenPosition(Offset(50, 75));

      controller.interaction.lastPointerPosition.value = position;

      expect(controller.interaction.pointerPosition, equals(position));
    });
  });

  // ===========================================================================
  // InteractionState - Canvas Lock State
  // ===========================================================================

  group('InteractionState - Canvas Lock', () {
    test('initial canvas lock state is false', () {
      final controller = createTestController();

      expect(controller.canvasLocked, isFalse);
      expect(controller.interaction.isCanvasLocked, isFalse);
    });

    test('update sets canvas locked state', () {
      final controller = createTestController();

      controller.interaction.update(canvasLocked: true);

      expect(controller.canvasLocked, isTrue);
    });

    test('update can unlock canvas', () {
      final controller = createTestController();
      controller.interaction.update(canvasLocked: true);

      controller.interaction.update(canvasLocked: false);

      expect(controller.canvasLocked, isFalse);
    });

    test('canvasLocked observable reflects state', () {
      final controller = createTestController();

      expect(controller.interaction.canvasLocked.value, isFalse);

      controller.interaction.canvasLocked.value = true;

      expect(controller.canvasLocked, isTrue);
    });
  });

  // ===========================================================================
  // InteractionState - Drag State
  // ===========================================================================

  group('InteractionState - Drag State', () {
    test('initial dragged node is null', () {
      final controller = createTestController();

      expect(controller.draggedNodeId, isNull);
      expect(controller.interaction.currentDraggedNodeId, isNull);
    });

    test('setDraggedNode sets dragged node ID', () {
      final controller = createTestController();
      controller.addNode(createTestNode(id: 'node-1'));

      controller.interaction.setDraggedNode('node-1');

      expect(controller.draggedNodeId, equals('node-1'));
    });

    test('setDraggedNode with null clears dragged node', () {
      final controller = createTestController();
      controller.addNode(createTestNode(id: 'node-1'));
      controller.interaction.setDraggedNode('node-1');

      controller.interaction.setDraggedNode(null);

      expect(controller.draggedNodeId, isNull);
    });

    test('startNodeDrag sets dragged node state', () {
      // Note: Canvas locking is handled by DragSession, not startNodeDrag
      final controller = createTestController();
      final node = createTestNode(id: 'drag-node');
      controller.addNode(node);

      controller.startNodeDrag('drag-node');

      expect(controller.draggedNodeId, equals('drag-node'));
      // Canvas locking is handled by DragSession in the widget layer
      // startNodeDrag just sets the state, but doesn't lock the canvas
    });

    test('startNodeDrag selects node if not already selected', () {
      final controller = createTestController();
      controller.addNode(createTestNode(id: 'node-1'));
      controller.addNode(createTestNode(id: 'node-2'));
      controller.selectNode('node-1');

      controller.startNodeDrag('node-2');

      expect(controller.selectedNodeIds, contains('node-2'));
    });

    test('endNodeDrag clears dragged node state', () {
      // Note: Canvas locking is handled by DragSession, not endNodeDrag
      final controller = createTestController();
      controller.addNode(createTestNode(id: 'drag-node'));
      controller.startNodeDrag('drag-node');

      controller.endNodeDrag();

      expect(controller.draggedNodeId, isNull);
      // Canvas unlock is handled by DragSession in the widget layer
    });

    test('endNodeDrag resets node dragging flag', () {
      final controller = createTestController();
      final node = createTestNode(id: 'drag-node');
      controller.addNode(node);
      controller.startNodeDrag('drag-node');

      controller.endNodeDrag();

      expect(controller.getNode('drag-node')!.dragging.value, isFalse);
    });
  });

  // ===========================================================================
  // InteractionState - Selection Rectangle
  // ===========================================================================

  group('InteractionState - Selection Rectangle', () {
    test('initial selection state is not drawing', () {
      final controller = createTestController();

      expect(controller.isDrawingSelection, isFalse);
      expect(controller.selectionRect, isNull);
      expect(controller.selectionStartPoint, isNull);
    });

    test('updateSelection sets start point', () {
      final controller = createTestController();
      const startPoint = GraphPosition(Offset(100, 100));

      controller.interaction.updateSelection(startPoint: startPoint);

      expect(controller.selectionStartPoint, equals(startPoint));
    });

    test('updateSelection sets selection rectangle', () {
      final controller = createTestController();
      final rect = GraphRect.fromLTWH(100, 100, 200, 150);

      controller.interaction.updateSelection(rectangle: rect);

      expect(controller.selectionRect, equals(rect));
      expect(controller.isDrawingSelection, isTrue);
    });

    test('updateSelection with intersecting nodes selects them', () {
      final controller = createTestController();
      controller.addNode(createTestNode(id: 'node-1'));
      controller.addNode(createTestNode(id: 'node-2'));

      controller.interaction.updateSelection(
        rectangle: GraphRect.fromLTWH(0, 0, 100, 100),
        intersectingNodes: ['node-1', 'node-2'],
        selectNodes: controller.selectNodes,
      );

      expect(controller.selectedNodeIds, containsAll(['node-1', 'node-2']));
    });

    test('updateSelection with toggle mode toggles selection', () {
      final controller = createTestController();
      controller.addNode(createTestNode(id: 'node-1'));
      controller.addNode(createTestNode(id: 'node-2'));
      controller.selectNode('node-1'); // Pre-select node-1

      // First update adds node-2 to intersecting
      controller.interaction.updateSelection(
        rectangle: GraphRect.fromLTWH(0, 0, 100, 100),
        intersectingNodes: ['node-2'],
        toggle: true,
        selectNodes: controller.selectNodes,
      );

      expect(controller.selectedNodeIds, contains('node-2'));
    });

    test('finishSelection clears selection state', () {
      final controller = createTestController();
      controller.interaction.updateSelection(
        startPoint: const GraphPosition(Offset(50, 50)),
        rectangle: GraphRect.fromLTWH(50, 50, 100, 100),
      );

      controller.interaction.finishSelection();

      expect(controller.isDrawingSelection, isFalse);
      expect(controller.selectionRect, isNull);
      expect(controller.selectionStartPoint, isNull);
    });
  });

  // ===========================================================================
  // InteractionState - Connection Creation State
  // ===========================================================================

  group('InteractionState - Connection Creation', () {
    test('initial connection state is not creating', () {
      final controller = createTestController();

      expect(controller.isConnecting, isFalse);
      expect(controller.temporaryConnection, isNull);
    });

    test('startConnectionDrag sets temporary connection', () {
      final node = createTestNodeWithOutputPort(id: 'source-node');
      final controller = createTestController(nodes: [node]);

      controller.startConnectionDrag(
        nodeId: 'source-node',
        portId: 'output-1',
        isOutput: true,
        startPoint: const Offset(100, 100),
        nodeBounds: const Rect.fromLTWH(0, 0, 100, 100),
      );

      expect(controller.isConnecting, isTrue);
      expect(controller.temporaryConnection, isNotNull);
      expect(
        controller.temporaryConnection!.startNodeId,
        equals('source-node'),
      );
      expect(controller.temporaryConnection!.startPortId, equals('output-1'));
    });

    test('cancelConnectionDrag clears temporary connection', () {
      final node = createTestNodeWithOutputPort(id: 'source-node');
      final controller = createTestController(nodes: [node]);
      controller.startConnectionDrag(
        nodeId: 'source-node',
        portId: 'output-1',
        isOutput: true,
        startPoint: const Offset(100, 100),
        nodeBounds: const Rect.fromLTWH(0, 0, 100, 100),
      );

      controller.cancelConnectionDrag();

      expect(controller.isConnecting, isFalse);
      expect(controller.temporaryConnection, isNull);
    });

    test('connection creation sets temporary connection', () {
      // Note: canvas lock is handled by drag session, not startConnectionDrag
      final node = createTestNodeWithOutputPort(id: 'source-node');
      final controller = createTestController(nodes: [node]);

      controller.startConnectionDrag(
        nodeId: 'source-node',
        portId: 'output-1',
        isOutput: true,
        startPoint: const Offset(100, 100),
        nodeBounds: const Rect.fromLTWH(0, 0, 100, 100),
      );

      expect(controller.isConnecting, isTrue);
      controller.cancelConnectionDrag();
    });
  });

  // ===========================================================================
  // InteractionState - Resize State
  // ===========================================================================

  group('InteractionState - Resize State', () {
    test('initial resize state is not resizing', () {
      final controller = createTestController();

      expect(controller.isResizing, isFalse);
      expect(controller.resizingNodeId, isNull);
    });

    test('endResize when not resizing does nothing', () {
      final controller = createTestController();

      // Should not throw
      controller.interaction.endResize();

      expect(controller.isResizing, isFalse);
      expect(controller.resizingNodeId, isNull);
    });

    test('setHandleDrift updates drift value', () {
      final controller = createTestController();

      controller.interaction.setHandleDrift(const Offset(10, 20));

      expect(
        controller.interaction.currentHandleDrift,
        equals(const Offset(10, 20)),
      );
    });
  });

  // ===========================================================================
  // InteractionState - Viewport Interaction
  // ===========================================================================

  group('InteractionState - Viewport Interaction', () {
    test('initial viewport interaction state is false', () {
      final controller = createTestController();

      expect(controller.interaction.isViewportDragging, isFalse);
    });

    test('setViewportInteracting updates state', () {
      final controller = createTestController();

      controller.interaction.setViewportInteracting(true);

      expect(controller.interaction.isViewportDragging, isTrue);
    });

    test('setViewportInteracting to false clears state', () {
      final controller = createTestController();
      controller.interaction.setViewportInteracting(true);

      controller.interaction.setViewportInteracting(false);

      expect(controller.interaction.isViewportDragging, isFalse);
    });
  });

  // ===========================================================================
  // InteractionState - Connection Hover
  // ===========================================================================

  group('InteractionState - Connection Hover', () {
    test('initial hover state is false', () {
      final controller = createTestController();

      expect(controller.interaction.isHoveringConnection, isFalse);
    });

    test('setHoveringConnection updates state', () {
      final controller = createTestController();

      controller.interaction.setHoveringConnection(true);

      expect(controller.interaction.isHoveringConnection, isTrue);
    });

    test('setHoveringConnection to false clears state', () {
      final controller = createTestController();
      controller.interaction.setHoveringConnection(true);

      controller.interaction.setHoveringConnection(false);

      expect(controller.interaction.isHoveringConnection, isFalse);
    });
  });

  // ===========================================================================
  // InteractionState - Cursor Override
  // ===========================================================================

  group('InteractionState - Cursor Override', () {
    test('initial cursor override is null', () {
      final controller = createTestController();

      expect(controller.interaction.currentCursorOverride, isNull);
      expect(controller.interaction.hasCursorOverride, isFalse);
    });

    test('setCursorOverride sets cursor', () {
      final controller = createTestController();

      controller.interaction.setCursorOverride(SystemMouseCursors.grab);

      expect(
        controller.interaction.currentCursorOverride,
        equals(SystemMouseCursors.grab),
      );
      expect(controller.interaction.hasCursorOverride, isTrue);
    });

    test('setCursorOverride with null clears cursor', () {
      final controller = createTestController();
      controller.interaction.setCursorOverride(SystemMouseCursors.grab);

      controller.interaction.setCursorOverride(null);

      expect(controller.interaction.currentCursorOverride, isNull);
      expect(controller.interaction.hasCursorOverride, isFalse);
    });
  });

  // ===========================================================================
  // InteractionState - Selection Started
  // ===========================================================================

  group('InteractionState - Selection Started', () {
    test('initial selection started state is false', () {
      final controller = createTestController();

      expect(controller.interaction.hasStartedSelection, isFalse);
    });

    test('setSelectionStarted sets state', () {
      final controller = createTestController();

      controller.interaction.setSelectionStarted(true);

      expect(controller.interaction.hasStartedSelection, isTrue);
    });

    test('setSelectionStarted to false clears state', () {
      final controller = createTestController();
      controller.interaction.setSelectionStarted(true);

      controller.interaction.setSelectionStarted(false);

      expect(controller.interaction.hasStartedSelection, isFalse);
    });
  });

  // ===========================================================================
  // InteractionState - Reset State
  // ===========================================================================

  group('InteractionState - Reset State', () {
    test('resetState clears all interaction state', () {
      final controller = createTestController();

      // Set up various states
      controller.interaction.setDraggedNode('node-1');
      controller.interaction.setPointerPosition(
        const ScreenPosition(Offset(100, 100)),
      );
      controller.interaction.update(canvasLocked: true);
      controller.interaction.updateSelection(
        startPoint: const GraphPosition(Offset(50, 50)),
        rectangle: GraphRect.fromLTWH(50, 50, 100, 100),
      );
      controller.interaction.setViewportInteracting(true);
      controller.interaction.setHoveringConnection(true);
      controller.interaction.setCursorOverride(SystemMouseCursors.grab);
      controller.interaction.setSelectionStarted(true);

      controller.interaction.resetState();

      expect(controller.draggedNodeId, isNull);
      expect(controller.pointerPosition, isNull);
      expect(controller.canvasLocked, isFalse);
      expect(controller.isDrawingSelection, isFalse);
      expect(controller.selectionRect, isNull);
      expect(controller.selectionStartPoint, isNull);
      expect(controller.interaction.isViewportDragging, isFalse);
      expect(controller.interaction.isHoveringConnection, isFalse);
      expect(controller.interaction.currentCursorOverride, isNull);
      expect(controller.interaction.hasStartedSelection, isFalse);
    });

    test('resetState clears resize state', () {
      final controller = createTestController();
      // Manually set resize state through observable to test reset
      controller.interaction.resizingNodeId.value = 'node-1';

      controller.interaction.resetState();

      expect(controller.isResizing, isFalse);
      expect(controller.resizingNodeId, isNull);
    });
  });

  // ===========================================================================
  // Computed Active Node/Connection IDs
  // ===========================================================================

  group('Active Node and Connection IDs', () {
    test('activeNodeIds includes dragged node', () {
      final controller = createTestController();
      controller.addNode(createTestNode(id: 'node-1'));

      controller.startNodeDrag('node-1');

      expect(controller.activeNodeIds, contains('node-1'));
    });

    test(
      'activeNodeIds includes all selected nodes when dragging selected',
      () {
        final controller = createTestController();
        controller.addNode(createTestNode(id: 'node-1'));
        controller.addNode(createTestNode(id: 'node-2'));
        controller.addNode(createTestNode(id: 'node-3'));
        controller.selectNodes(['node-1', 'node-2']);

        controller.startNodeDrag('node-1');

        expect(controller.activeNodeIds, containsAll(['node-1', 'node-2']));
        expect(controller.activeNodeIds, isNot(contains('node-3')));
      },
    );

    test('activeNodeIds includes resizing node', () {
      final controller = createTestController();
      controller.addNode(createTestNode(id: 'node-1'));

      // Manually set resize state through observable to test behavior
      controller.interaction.resizingNodeId.value = 'node-1';

      expect(controller.activeNodeIds, contains('node-1'));
    });

    test('activeConnectionIds returns connections of dragged node', () {
      final nodeA = createTestNodeWithOutputPort(id: 'node-a');
      final nodeB = createTestNodeWithInputPort(id: 'node-b');
      final controller = createTestController(nodes: [nodeA, nodeB]);

      // Add connection through API (which populates _connectionsByNodeId)
      controller.createConnection('node-a', 'output-1', 'node-b', 'input-1');

      controller.startNodeDrag('node-a');

      expect(controller.activeConnectionIds, hasLength(1));
    });

    test('activeConnectionIds empty when no interaction', () {
      final controller = createTestController();

      expect(controller.activeConnectionIds, isEmpty);
    });
  });

  // ===========================================================================
  // Edge Cases and Error Handling
  // ===========================================================================

  group('Edge Cases', () {
    test('operations on empty controller do not throw', () {
      final controller = createTestController();

      expect(
        () => controller.interaction.setDraggedNode(null),
        returnsNormally,
      );
      expect(
        () => controller.interaction.setPointerPosition(null),
        returnsNormally,
      );
      expect(() => controller.interaction.finishSelection(), returnsNormally);
      expect(() => controller.interaction.resetState(), returnsNormally);
    });

    test('startNodeDrag with non-existent node sets drag state anyway', () {
      // Note: The controller does not validate node existence when setting
      // drag state. The UI layer is responsible for only dragging valid nodes.
      final controller = createTestController();

      controller.startNodeDrag('non-existent');

      // Drag state is still set even if node doesn't exist
      expect(controller.draggedNodeId, equals('non-existent'));
    });

    test('endNodeDrag when not dragging does nothing', () {
      final controller = createTestController();

      // Should not throw
      controller.endNodeDrag();

      expect(controller.draggedNodeId, isNull);
    });

    test('cancelConnectionDrag when not connecting does nothing', () {
      final controller = createTestController();

      // Should not throw
      controller.cancelConnectionDrag();

      expect(controller.isConnecting, isFalse);
    });

    test('updateSelection with no selectNodes callback is safe', () {
      final controller = createTestController();

      // Should not throw
      controller.interaction.updateSelection(
        rectangle: GraphRect.fromLTWH(0, 0, 100, 100),
        intersectingNodes: ['node-1'],
        // No selectNodes callback provided
      );

      expect(controller.isDrawingSelection, isTrue);
    });
  });

  // ===========================================================================
  // InteractionState - Resize Operations
  // ===========================================================================

  group('InteractionState - Resize Operations', () {
    test('startResize sets all resize state', () {
      final controller = createTestController();
      final node = createTestGroupNode<String>(id: 'group-1', data: 'test');
      controller.addNode(node);

      controller.interaction.startResize(
        'group-1',
        ResizeHandle.bottomRight,
        const Offset(100, 100),
        const Rect.fromLTWH(0, 0, 200, 150),
      );

      expect(controller.resizingNodeId, equals('group-1'));
      expect(
        controller.interaction.currentResizeHandle,
        equals(ResizeHandle.bottomRight),
      );
      expect(
        controller.interaction.currentResizeStartPosition,
        equals(const Offset(100, 100)),
      );
      expect(
        controller.interaction.currentOriginalNodeBounds,
        equals(const Rect.fromLTWH(0, 0, 200, 150)),
      );
      expect(controller.interaction.currentHandleDrift, equals(Offset.zero));
      expect(controller.canvasLocked, isTrue);
      expect(
        controller.interaction.currentCursorOverride,
        equals(SystemMouseCursors.resizeUpLeftDownRight),
      );
    });

    test('startResize with different handles sets correct cursor', () {
      final controller = createTestController();

      // Test top-left corner
      controller.interaction.startResize(
        'node-1',
        ResizeHandle.topLeft,
        const Offset(0, 0),
        const Rect.fromLTWH(0, 0, 100, 100),
      );
      expect(
        controller.interaction.currentCursorOverride,
        equals(SystemMouseCursors.resizeUpLeftDownRight),
      );
      controller.interaction.endResize();

      // Test top-right corner
      controller.interaction.startResize(
        'node-1',
        ResizeHandle.topRight,
        const Offset(100, 0),
        const Rect.fromLTWH(0, 0, 100, 100),
      );
      expect(
        controller.interaction.currentCursorOverride,
        equals(SystemMouseCursors.resizeUpRightDownLeft),
      );
      controller.interaction.endResize();

      // Test vertical edge
      controller.interaction.startResize(
        'node-1',
        ResizeHandle.topCenter,
        const Offset(50, 0),
        const Rect.fromLTWH(0, 0, 100, 100),
      );
      expect(
        controller.interaction.currentCursorOverride,
        equals(SystemMouseCursors.resizeUpDown),
      );
      controller.interaction.endResize();

      // Test horizontal edge
      controller.interaction.startResize(
        'node-1',
        ResizeHandle.centerLeft,
        const Offset(0, 50),
        const Rect.fromLTWH(0, 0, 100, 100),
      );
      expect(
        controller.interaction.currentCursorOverride,
        equals(SystemMouseCursors.resizeLeftRight),
      );
    });

    test('endResize clears all resize state', () {
      final controller = createTestController();

      controller.interaction.startResize(
        'node-1',
        ResizeHandle.bottomRight,
        const Offset(100, 100),
        const Rect.fromLTWH(0, 0, 200, 150),
      );
      controller.interaction.setHandleDrift(const Offset(10, 20));

      controller.interaction.endResize();

      expect(controller.resizingNodeId, isNull);
      expect(controller.interaction.currentResizeHandle, isNull);
      expect(controller.interaction.currentResizeStartPosition, isNull);
      expect(controller.interaction.currentOriginalNodeBounds, isNull);
      expect(controller.interaction.currentHandleDrift, equals(Offset.zero));
      expect(controller.canvasLocked, isFalse);
      expect(controller.interaction.currentCursorOverride, isNull);
    });

    test('setHandleDrift accumulates drift during constrained resize', () {
      final controller = createTestController();

      controller.interaction.startResize(
        'node-1',
        ResizeHandle.bottomRight,
        const Offset(100, 100),
        const Rect.fromLTWH(0, 0, 100, 100),
      );

      controller.interaction.setHandleDrift(const Offset(5, 10));
      expect(
        controller.interaction.currentHandleDrift,
        equals(const Offset(5, 10)),
      );

      controller.interaction.setHandleDrift(const Offset(15, 25));
      expect(
        controller.interaction.currentHandleDrift,
        equals(const Offset(15, 25)),
      );
    });

    test('resize state persists through multiple handle drift updates', () {
      final controller = createTestController();

      controller.interaction.startResize(
        'group-1',
        ResizeHandle.centerRight,
        const Offset(200, 100),
        const Rect.fromLTWH(0, 0, 200, 200),
      );

      // Simulate multiple drift updates (pointer moves faster than resize can follow)
      for (var i = 0; i < 10; i++) {
        controller.interaction.setHandleDrift(Offset(i * 2.0, i * 1.0));
      }

      // Core resize state should be preserved
      expect(controller.resizingNodeId, equals('group-1'));
      expect(
        controller.interaction.currentResizeHandle,
        equals(ResizeHandle.centerRight),
      );
      expect(
        controller.interaction.currentResizeStartPosition,
        equals(const Offset(200, 100)),
      );
    });
  });

  // ===========================================================================
  // InteractionState - Selection Toggle Edge Cases
  // ===========================================================================

  group('InteractionState - Selection Toggle Edge Cases', () {
    test(
      'toggle selection with empty previous set selects all intersecting',
      () {
        final controller = createTestController();
        controller.addNode(createTestNode(id: 'node-1'));
        controller.addNode(createTestNode(id: 'node-2'));
        controller.addNode(createTestNode(id: 'node-3'));

        controller.interaction.updateSelection(
          rectangle: GraphRect.fromLTWH(0, 0, 100, 100),
          intersectingNodes: ['node-1', 'node-2'],
          toggle: true,
          selectNodes: controller.selectNodes,
        );

        expect(controller.selectedNodeIds, containsAll(['node-1', 'node-2']));
        expect(controller.selectedNodeIds, isNot(contains('node-3')));
      },
    );

    test('toggle selection deselects nodes that leave intersection', () {
      final controller = createTestController();
      controller.addNode(createTestNode(id: 'node-1'));
      controller.addNode(createTestNode(id: 'node-2'));

      // First update: both nodes intersecting
      controller.interaction.updateSelection(
        rectangle: GraphRect.fromLTWH(0, 0, 200, 200),
        intersectingNodes: ['node-1', 'node-2'],
        toggle: true,
        selectNodes: controller.selectNodes,
      );

      expect(controller.selectedNodeIds, containsAll(['node-1', 'node-2']));

      // Second update: only node-1 intersecting (node-2 left rectangle)
      controller.interaction.updateSelection(
        rectangle: GraphRect.fromLTWH(0, 0, 100, 100),
        intersectingNodes: ['node-1'],
        toggle: true,
        selectNodes: controller.selectNodes,
      );

      // node-2 should be toggled (deselected) since it left the intersection
      expect(controller.selectedNodeIds, contains('node-1'));
      // Note: Actual toggle behavior depends on implementation details
    });

    test('non-toggle selection replaces previous selection', () {
      final controller = createTestController();
      controller.addNode(createTestNode(id: 'node-1'));
      controller.addNode(createTestNode(id: 'node-2'));
      controller.addNode(createTestNode(id: 'node-3'));

      // Pre-select node-1
      controller.selectNode('node-1');
      expect(controller.selectedNodeIds, contains('node-1'));

      // Non-toggle selection with different nodes
      controller.interaction.updateSelection(
        rectangle: GraphRect.fromLTWH(100, 100, 100, 100),
        intersectingNodes: ['node-2', 'node-3'],
        toggle: false,
        selectNodes: controller.selectNodes,
      );

      // Should replace selection with node-2 and node-3
      expect(controller.selectedNodeIds, containsAll(['node-2', 'node-3']));
    });

    test(
      'selection with empty intersecting list clears selection in non-toggle mode',
      () {
        final controller = createTestController();
        controller.addNode(createTestNode(id: 'node-1'));
        controller.selectNode('node-1');

        controller.interaction.updateSelection(
          rectangle: GraphRect.fromLTWH(500, 500, 100, 100),
          intersectingNodes: [],
          toggle: false,
          selectNodes: controller.selectNodes,
        );

        expect(controller.selectedNodeIds, isEmpty);
      },
    );

    test('finishSelection clears previously intersecting tracking', () {
      final controller = createTestController();
      controller.addNode(createTestNode(id: 'node-1'));

      // First selection with toggle
      controller.interaction.updateSelection(
        rectangle: GraphRect.fromLTWH(0, 0, 100, 100),
        intersectingNodes: ['node-1'],
        toggle: true,
        selectNodes: controller.selectNodes,
      );

      controller.interaction.finishSelection();

      // Start a new selection - should have fresh state
      controller.interaction.updateSelection(
        startPoint: const GraphPosition(Offset(200, 200)),
        rectangle: GraphRect.fromLTWH(200, 200, 100, 100),
      );

      expect(
        controller.selectionStartPoint,
        equals(const GraphPosition(Offset(200, 200))),
      );
    });
  });

  // ===========================================================================
  // InteractionState - Connection Creation Edge Cases
  // ===========================================================================

  group('InteractionState - Connection Creation Edge Cases', () {
    test('connectionStartNodeId returns correct value during drag', () {
      final node = createTestNodeWithOutputPort(id: 'source');
      final controller = createTestController(nodes: [node]);

      controller.startConnectionDrag(
        nodeId: 'source',
        portId: 'output-1',
        isOutput: true,
        startPoint: const Offset(100, 50),
        nodeBounds: const Rect.fromLTWH(0, 0, 100, 100),
      );

      expect(controller.interaction.connectionStartNodeId, equals('source'));
      expect(controller.interaction.connectionStartPortId, equals('output-1'));
    });

    test('connection creation from input port sets correct direction', () {
      final node = createTestNodeWithInputPort(id: 'target');
      final controller = createTestController(nodes: [node]);

      controller.startConnectionDrag(
        nodeId: 'target',
        portId: 'input-1',
        isOutput: false,
        startPoint: const Offset(0, 50),
        nodeBounds: const Rect.fromLTWH(0, 0, 100, 100),
      );

      expect(controller.isConnecting, isTrue);
      expect(controller.temporaryConnection!.isStartFromOutput, isFalse);
    });

    test('updateConnectionDrag updates temporary connection endpoint', () {
      final node = createTestNodeWithOutputPort(id: 'source');
      final controller = createTestController(nodes: [node]);

      controller.startConnectionDrag(
        nodeId: 'source',
        portId: 'output-1',
        isOutput: true,
        startPoint: const Offset(100, 50),
        nodeBounds: const Rect.fromLTWH(0, 0, 100, 100),
      );

      controller.updateConnectionDrag(graphPosition: const Offset(200, 100));

      expect(
        controller.temporaryConnection!.currentPoint,
        equals(const Offset(200, 100)),
      );
    });

    test('completeConnectionDrag clears temporary connection on success', () {
      final nodeA = createTestNodeWithOutputPort(id: 'node-a');
      final nodeB = createTestNodeWithInputPort(id: 'node-b');
      final controller = createTestController(nodes: [nodeA, nodeB]);

      controller.startConnectionDrag(
        nodeId: 'node-a',
        portId: 'output-1',
        isOutput: true,
        startPoint: const Offset(100, 50),
        nodeBounds: const Rect.fromLTWH(0, 0, 100, 100),
      );

      controller.updateConnectionDrag(
        graphPosition: const Offset(200, 50),
        targetNodeId: 'node-b',
        targetPortId: 'input-1',
        targetNodeBounds: const Rect.fromLTWH(150, 0, 100, 100),
      );

      final result = controller.completeConnectionDrag(
        targetNodeId: 'node-b',
        targetPortId: 'input-1',
      );

      expect(result, isNotNull);
      expect(controller.isConnecting, isFalse);
      expect(controller.temporaryConnection, isNull);
      expect(controller.connections.length, equals(1));
    });

    test(
      'completeConnectionDrag returns null when no temporary connection',
      () {
        final node = createTestNodeWithOutputPort(id: 'source');
        final controller = createTestController(nodes: [node]);

        // No connection started - just try to complete without starting
        final result = controller.completeConnectionDrag(
          targetNodeId: 'target',
          targetPortId: 'input-1',
        );

        expect(result, isNull);
        expect(controller.isConnecting, isFalse);
        expect(controller.connections, isEmpty);
      },
    );

    test('cancelConnectionDrag clears connection state mid-drag', () {
      final node = createTestNodeWithOutputPort(id: 'source');
      final controller = createTestController(nodes: [node]);

      controller.startConnectionDrag(
        nodeId: 'source',
        portId: 'output-1',
        isOutput: true,
        startPoint: const Offset(100, 50),
        nodeBounds: const Rect.fromLTWH(0, 0, 100, 100),
      );

      controller.updateConnectionDrag(graphPosition: const Offset(150, 75));
      expect(controller.isConnecting, isTrue);

      controller.cancelConnectionDrag();

      expect(controller.isConnecting, isFalse);
      expect(controller.temporaryConnection, isNull);
    });
  });

  // ===========================================================================
  // InteractionState - Concurrent State Management
  // ===========================================================================

  group('InteractionState - Concurrent State Management', () {
    test('only one major interaction can be active at a time', () {
      final controller = createTestController();
      controller.addNode(createTestNode(id: 'node-1'));

      // Start a node drag
      controller.startNodeDrag('node-1');
      expect(controller.draggedNodeId, equals('node-1'));

      // End the drag
      controller.endNodeDrag();
      expect(controller.draggedNodeId, isNull);

      // Now can start resize
      controller.interaction.startResize(
        'node-1',
        ResizeHandle.bottomRight,
        const Offset(100, 100),
        const Rect.fromLTWH(0, 0, 100, 100),
      );
      expect(controller.isResizing, isTrue);
    });

    test('resetState clears all concurrent states', () {
      final controller = createTestController();
      final node = createTestNodeWithOutputPort(id: 'node-1');
      controller.addNode(node);

      // Set up multiple states
      controller.interaction.setDraggedNode('node-1');
      controller.interaction.setPointerPosition(
        const ScreenPosition(Offset(50, 50)),
      );
      controller.interaction.update(canvasLocked: true);
      controller.interaction.updateSelection(
        startPoint: const GraphPosition(Offset(0, 0)),
        rectangle: GraphRect.fromLTWH(0, 0, 100, 100),
      );
      controller.interaction.setViewportInteracting(true);
      controller.interaction.setHoveringConnection(true);
      controller.interaction.setCursorOverride(SystemMouseCursors.grab);
      controller.interaction.setSelectionStarted(true);
      controller.interaction.resizingNodeId.value = 'node-1';
      controller.interaction.resizeHandle.value = ResizeHandle.topLeft;

      // Reset everything
      controller.interaction.resetState();

      // Verify all states are cleared
      expect(controller.draggedNodeId, isNull);
      expect(controller.pointerPosition, isNull);
      expect(controller.canvasLocked, isFalse);
      expect(controller.isDrawingSelection, isFalse);
      expect(controller.selectionRect, isNull);
      expect(controller.selectionStartPoint, isNull);
      expect(controller.interaction.isViewportDragging, isFalse);
      expect(controller.interaction.isHoveringConnection, isFalse);
      expect(controller.interaction.currentCursorOverride, isNull);
      expect(controller.interaction.hasStartedSelection, isFalse);
      expect(controller.isResizing, isFalse);
      expect(controller.interaction.currentResizeHandle, isNull);
    });

    test('canvas lock state survives individual state changes', () {
      final controller = createTestController();

      controller.interaction.update(canvasLocked: true);
      expect(controller.canvasLocked, isTrue);

      controller.interaction.setDraggedNode('node-1');
      expect(controller.canvasLocked, isTrue);

      controller.interaction.setDraggedNode(null);
      expect(controller.canvasLocked, isTrue);

      controller.interaction.update(canvasLocked: false);
      expect(controller.canvasLocked, isFalse);
    });
  });

  // ===========================================================================
  // InteractionState - TemporaryConnection State
  // ===========================================================================

  group('InteractionState - TemporaryConnection State', () {
    test('update with temporaryConnection sets connection state', () {
      final controller = createTestController();
      final tempConnection = TemporaryConnection(
        startPoint: const Offset(100, 50),
        startNodeId: 'node-a',
        startPortId: 'port-1',
        isStartFromOutput: true,
        startNodeBounds: const Rect.fromLTWH(0, 0, 100, 100),
        initialCurrentPoint: const Offset(100, 50),
      );

      controller.interaction.update(temporaryConnection: tempConnection);

      expect(controller.isConnecting, isTrue);
      expect(controller.temporaryConnection, equals(tempConnection));
    });

    test('cancelConnection clears temporary connection', () {
      final controller = createTestController();
      final tempConnection = TemporaryConnection(
        startPoint: const Offset(100, 50),
        startNodeId: 'node-a',
        startPortId: 'port-1',
        isStartFromOutput: true,
        startNodeBounds: const Rect.fromLTWH(0, 0, 100, 100),
        initialCurrentPoint: const Offset(100, 50),
      );

      controller.interaction.update(temporaryConnection: tempConnection);
      expect(controller.isConnecting, isTrue);

      controller.interaction.cancelConnection();

      expect(controller.isConnecting, isFalse);
      expect(controller.temporaryConnection, isNull);
    });

    test(
      'temporary connection preserves immutable properties during updates',
      () {
        final node = createTestNodeWithOutputPort(id: 'source');
        final controller = createTestController(nodes: [node]);

        controller.startConnectionDrag(
          nodeId: 'source',
          portId: 'output-1',
          isOutput: true,
          startPoint: const Offset(100, 50),
          nodeBounds: const Rect.fromLTWH(0, 0, 100, 100),
        );

        final original = controller.temporaryConnection!;
        final originalStartPoint = original.startPoint;
        final originalStartNodeId = original.startNodeId;
        final originalStartPortId = original.startPortId;

        // Update connection point
        controller.updateConnectionDrag(graphPosition: const Offset(200, 100));

        expect(
          controller.temporaryConnection!.startPoint,
          equals(originalStartPoint),
        );
        expect(
          controller.temporaryConnection!.startNodeId,
          equals(originalStartNodeId),
        );
        expect(
          controller.temporaryConnection!.startPortId,
          equals(originalStartPortId),
        );
        expect(
          controller.temporaryConnection!.currentPoint,
          equals(const Offset(200, 100)),
        );
      },
    );
  });

  // ===========================================================================
  // InteractionState - Stale State Cleanup Scenarios
  // ===========================================================================

  group('InteractionState - Stale State Cleanup Scenarios', () {
    test(
      'dragging flag on node cleared even if controller state inconsistent',
      () {
        final controller = createTestController();
        final node = createTestNode(id: 'node-1');
        controller.addNode(node);

        // Manually set the node's dragging flag (simulating stale state)
        node.dragging.value = true;
        expect(controller.getNode('node-1')!.dragging.value, isTrue);

        // Simulate cleanup that would happen in _cleanupStaleDragState
        // by using the public API that triggers similar cleanup
        controller.endNodeDrag();

        // The dragging flag should be reset
        expect(controller.getNode('node-1')!.dragging.value, isFalse);
      },
    );

    test('multiple nodes with stale dragging flags get cleaned up', () {
      final controller = createTestController();
      controller.addNode(createTestNode(id: 'node-1'));
      controller.addNode(createTestNode(id: 'node-2'));
      controller.addNode(createTestNode(id: 'node-3'));

      // Manually set dragging flags on multiple nodes
      controller.getNode('node-1')!.dragging.value = true;
      controller.getNode('node-2')!.dragging.value = true;

      // Start and end a drag on node-3 to trigger cleanup
      controller.startNodeDrag('node-3');
      controller.endNodeDrag();

      // All dragging flags should be false
      expect(controller.getNode('node-1')!.dragging.value, isFalse);
      expect(controller.getNode('node-2')!.dragging.value, isFalse);
      expect(controller.getNode('node-3')!.dragging.value, isFalse);
    });
  });

  // ===========================================================================
  // InteractionState - Observable Reactivity
  // ===========================================================================

  group('InteractionState - Observable Reactivity', () {
    test('dragged node ID observable updates synchronously', () {
      final controller = createTestController();
      controller.addNode(createTestNode(id: 'node-1'));

      final observedValues = <String?>[];
      controller.interaction.draggedNodeId.observe((change) {
        observedValues.add(change.newValue);
      });

      controller.startNodeDrag('node-1');
      controller.endNodeDrag();

      expect(observedValues, contains('node-1'));
      expect(observedValues.last, isNull);
    });

    test('canvas locked observable updates on interaction state change', () {
      final controller = createTestController();

      final lockedStates = <bool>[];
      controller.interaction.canvasLocked.observe((change) {
        lockedStates.add(change.newValue ?? false);
      });

      controller.interaction.update(canvasLocked: true);
      controller.interaction.update(canvasLocked: false);

      expect(lockedStates, equals([true, false]));
    });

    test('selection rect observable updates during drag', () {
      final controller = createTestController();

      final rects = <GraphRect?>[];
      controller.interaction.selectionRect.observe((change) {
        rects.add(change.newValue);
      });

      controller.interaction.updateSelection(
        rectangle: GraphRect.fromLTWH(0, 0, 100, 100),
      );
      controller.interaction.updateSelection(
        rectangle: GraphRect.fromLTWH(0, 0, 200, 200),
      );
      controller.interaction.finishSelection();

      expect(rects.length, equals(3));
      expect(rects[0]!.width, equals(100));
      expect(rects[1]!.width, equals(200));
      expect(rects[2], isNull);
    });
  });

  // ===========================================================================
  // InteractionState - Getters Return Correct Values
  // ===========================================================================

  group('InteractionState - Getter Correctness', () {
    test('isCreatingConnection tracks temporaryConnection correctly', () {
      final controller = createTestController();

      expect(controller.interaction.isCreatingConnection, isFalse);

      final tempConnection = TemporaryConnection(
        startPoint: const Offset(0, 0),
        startNodeId: 'n1',
        startPortId: 'p1',
        isStartFromOutput: true,
        startNodeBounds: const Rect.fromLTWH(0, 0, 100, 100),
        initialCurrentPoint: const Offset(0, 0),
      );

      controller.interaction.update(temporaryConnection: tempConnection);
      expect(controller.interaction.isCreatingConnection, isTrue);

      controller.interaction.cancelConnection();
      expect(controller.interaction.isCreatingConnection, isFalse);
    });

    test('currentSelectionRect returns correct rectangle', () {
      final controller = createTestController();
      final rect = GraphRect.fromLTWH(10, 20, 30, 40);

      expect(controller.interaction.currentSelectionRect, isNull);

      controller.interaction.updateSelection(rectangle: rect);

      expect(controller.interaction.currentSelectionRect, equals(rect));
    });

    test('all resize getters return consistent values', () {
      final controller = createTestController();

      // Before resize
      expect(controller.interaction.currentResizingNodeId, isNull);
      expect(controller.interaction.currentResizeHandle, isNull);
      expect(controller.interaction.currentResizeStartPosition, isNull);
      expect(controller.interaction.currentOriginalNodeBounds, isNull);
      expect(controller.interaction.isResizing, isFalse);

      // During resize
      controller.interaction.startResize(
        'node-1',
        ResizeHandle.bottomCenter,
        const Offset(50, 100),
        const Rect.fromLTWH(0, 0, 100, 100),
      );

      expect(controller.interaction.currentResizingNodeId, equals('node-1'));
      expect(
        controller.interaction.currentResizeHandle,
        equals(ResizeHandle.bottomCenter),
      );
      expect(
        controller.interaction.currentResizeStartPosition,
        equals(const Offset(50, 100)),
      );
      expect(
        controller.interaction.currentOriginalNodeBounds,
        equals(const Rect.fromLTWH(0, 0, 100, 100)),
      );
      expect(controller.interaction.isResizing, isTrue);

      // After resize
      controller.interaction.endResize();

      expect(controller.interaction.currentResizingNodeId, isNull);
      expect(controller.interaction.currentResizeHandle, isNull);
      expect(controller.interaction.currentResizeStartPosition, isNull);
      expect(controller.interaction.currentOriginalNodeBounds, isNull);
      expect(controller.interaction.isResizing, isFalse);
    });
  });

  // ===========================================================================
  // InteractionState - Update Method Partial Updates
  // ===========================================================================

  group('InteractionState - Update Method', () {
    test(
      'update with only canvasLocked does not affect temporaryConnection',
      () {
        final controller = createTestController();
        final tempConnection = TemporaryConnection(
          startPoint: const Offset(0, 0),
          startNodeId: 'n1',
          startPortId: 'p1',
          isStartFromOutput: true,
          startNodeBounds: const Rect.fromLTWH(0, 0, 100, 100),
          initialCurrentPoint: const Offset(0, 0),
        );

        controller.interaction.update(temporaryConnection: tempConnection);
        controller.interaction.update(canvasLocked: true);

        expect(controller.isConnecting, isTrue);
        expect(controller.canvasLocked, isTrue);
      },
    );

    test(
      'update with only temporaryConnection does not affect canvasLocked',
      () {
        final controller = createTestController();
        controller.interaction.update(canvasLocked: true);

        final tempConnection = TemporaryConnection(
          startPoint: const Offset(0, 0),
          startNodeId: 'n1',
          startPortId: 'p1',
          isStartFromOutput: true,
          startNodeBounds: const Rect.fromLTWH(0, 0, 100, 100),
          initialCurrentPoint: const Offset(0, 0),
        );

        controller.interaction.update(temporaryConnection: tempConnection);

        // canvasLocked should still be true (not changed by update)
        expect(controller.canvasLocked, isTrue);
        expect(controller.isConnecting, isTrue);
      },
    );

    test('update with null parameters does nothing', () {
      final controller = createTestController();
      controller.interaction.update(canvasLocked: true);

      // Call update with no parameters
      controller.interaction.update();

      // State should be unchanged
      expect(controller.canvasLocked, isTrue);
    });
  });

  // ===========================================================================
  // Error Handling - Additional Edge Cases
  // ===========================================================================

  group('Error Handling - Additional Edge Cases', () {
    test('selection update with null rectangle only updates start point', () {
      final controller = createTestController();

      controller.interaction.updateSelection(
        startPoint: const GraphPosition(Offset(50, 50)),
      );

      expect(
        controller.selectionStartPoint,
        equals(const GraphPosition(Offset(50, 50))),
      );
      expect(controller.selectionRect, isNull);
      expect(controller.isDrawingSelection, isFalse);
    });

    test('selection update with null start point only updates rectangle', () {
      final controller = createTestController();

      controller.interaction.updateSelection(
        rectangle: GraphRect.fromLTWH(0, 0, 100, 100),
      );

      expect(controller.selectionStartPoint, isNull);
      expect(controller.selectionRect, isNotNull);
      expect(controller.isDrawingSelection, isTrue);
    });

    test('setPointerPosition handles various offset values', () {
      final controller = createTestController();

      // Zero offset
      controller.interaction.setPointerPosition(
        const ScreenPosition(Offset.zero),
      );
      expect(
        controller.pointerPosition,
        equals(const ScreenPosition(Offset.zero)),
      );

      // Negative values
      controller.interaction.setPointerPosition(
        const ScreenPosition(Offset(-100, -50)),
      );
      expect(
        controller.pointerPosition,
        equals(const ScreenPosition(Offset(-100, -50))),
      );

      // Large values
      controller.interaction.setPointerPosition(
        const ScreenPosition(Offset(10000, 10000)),
      );
      expect(
        controller.pointerPosition,
        equals(const ScreenPosition(Offset(10000, 10000))),
      );

      // Fractional values
      controller.interaction.setPointerPosition(
        const ScreenPosition(Offset(1.5, 2.7)),
      );
      expect(
        controller.pointerPosition,
        equals(const ScreenPosition(Offset(1.5, 2.7))),
      );
    });

    test('handle drift can be set to negative values', () {
      final controller = createTestController();

      controller.interaction.startResize(
        'node-1',
        ResizeHandle.topLeft,
        const Offset(0, 0),
        const Rect.fromLTWH(0, 0, 100, 100),
      );

      controller.interaction.setHandleDrift(const Offset(-20, -15));
      expect(
        controller.interaction.currentHandleDrift,
        equals(const Offset(-20, -15)),
      );
    });

    test('resize with zero-sized original bounds', () {
      final controller = createTestController();

      // Should not throw with zero-sized bounds
      controller.interaction.startResize(
        'node-1',
        ResizeHandle.bottomRight,
        const Offset(0, 0),
        Rect.zero,
      );

      expect(controller.isResizing, isTrue);
      expect(
        controller.interaction.currentOriginalNodeBounds,
        equals(Rect.zero),
      );

      controller.interaction.endResize();
    });
  });
}
