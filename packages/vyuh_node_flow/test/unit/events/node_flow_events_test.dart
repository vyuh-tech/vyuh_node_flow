/// Unit tests for NodeFlowEvents and related event classes.
///
/// Tests cover:
/// - NodeFlowEvents construction and copyWith
/// - NodeEvents construction and copyWith
/// - PortEvents construction and copyWith
/// - ConnectionEvents construction and copyWith
/// - ViewportEvents construction and copyWith
/// - SelectionState properties
/// - FlowError construction
@Tags(['unit'])
library;

import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:vyuh_node_flow/vyuh_node_flow.dart';

import '../../helpers/test_factories.dart';

void main() {
  setUp(() {
    resetTestCounters();
  });

  // ===========================================================================
  // NodeFlowEvents Tests
  // ===========================================================================

  group('NodeFlowEvents', () {
    test('default constructor creates empty events', () {
      const events = NodeFlowEvents<String, dynamic>();

      expect(events.node, isNull);
      expect(events.port, isNull);
      expect(events.connection, isNull);
      expect(events.viewport, isNull);
      expect(events.onSelectionChange, isNull);
      expect(events.onInit, isNull);
      expect(events.onError, isNull);
    });

    test('constructor with all parameters', () {
      void nodeHandler(Node<String> node) {}
      void portHandler(Node<String> node, Port port) {}
      void connectionHandler(Connection<dynamic> conn) {}
      void viewportHandler(GraphViewport vp) {}
      void selectionHandler(SelectionState<String, dynamic> state) {}
      void initHandler() {}
      void errorHandler(FlowError error) {}

      final events = NodeFlowEvents<String, dynamic>(
        node: NodeEvents<String>(onTap: nodeHandler),
        port: PortEvents<String>(onTap: portHandler),
        connection: ConnectionEvents<String, dynamic>(onTap: connectionHandler),
        viewport: ViewportEvents(onMove: viewportHandler),
        onSelectionChange: selectionHandler,
        onInit: initHandler,
        onError: errorHandler,
      );

      expect(events.node, isNotNull);
      expect(events.port, isNotNull);
      expect(events.connection, isNotNull);
      expect(events.viewport, isNotNull);
      expect(events.onSelectionChange, isNotNull);
      expect(events.onInit, isNotNull);
      expect(events.onError, isNotNull);
    });

    test('copyWith replaces specified values', () {
      const original = NodeFlowEvents<String, dynamic>();
      void nodeHandler(Node<String> node) {}

      final copied = original.copyWith(
        node: NodeEvents<String>(onTap: nodeHandler),
      );

      expect(copied.node, isNotNull);
      expect(copied.port, isNull);
      expect(copied.connection, isNull);
    });

    test('copyWith preserves unspecified values', () {
      void initHandler() {}
      final original = NodeFlowEvents<String, dynamic>(onInit: initHandler);
      void nodeHandler(Node<String> node) {}

      final copied = original.copyWith(
        node: NodeEvents<String>(onTap: nodeHandler),
      );

      expect(copied.node, isNotNull);
      expect(copied.onInit, equals(initHandler));
    });

    test('copyWith with all values', () {
      void newNodeHandler(Node<String> node) {}
      void newPortHandler(Node<String> node, Port port) {}
      void newConnectionHandler(Connection<dynamic> conn) {}
      void newViewportHandler(GraphViewport vp) {}
      void newSelectionHandler(SelectionState<String, dynamic> state) {}
      void newInitHandler() {}
      void newErrorHandler(FlowError error) {}

      const original = NodeFlowEvents<String, dynamic>();

      final copied = original.copyWith(
        node: NodeEvents<String>(onTap: newNodeHandler),
        port: PortEvents<String>(onTap: newPortHandler),
        connection: ConnectionEvents<String, dynamic>(
          onTap: newConnectionHandler,
        ),
        viewport: ViewportEvents(onMove: newViewportHandler),
        onSelectionChange: newSelectionHandler,
        onInit: newInitHandler,
        onError: newErrorHandler,
      );

      expect(copied.node, isNotNull);
      expect(copied.port, isNotNull);
      expect(copied.connection, isNotNull);
      expect(copied.viewport, isNotNull);
      expect(copied.onSelectionChange, isNotNull);
      expect(copied.onInit, isNotNull);
      expect(copied.onError, isNotNull);
    });
  });

  // ===========================================================================
  // NodeEvents Tests
  // ===========================================================================

  group('NodeEvents', () {
    test('default constructor creates empty events', () {
      const events = NodeEvents<String>();

      expect(events.onCreated, isNull);
      expect(events.onBeforeDelete, isNull);
      expect(events.onDeleted, isNull);
      expect(events.onSelected, isNull);
      expect(events.onTap, isNull);
      expect(events.onDoubleTap, isNull);
      expect(events.onDragStart, isNull);
      expect(events.onDrag, isNull);
      expect(events.onDragStop, isNull);
      expect(events.onDragCancel, isNull);
      expect(events.onResizeCancel, isNull);
      expect(events.onMouseEnter, isNull);
      expect(events.onMouseLeave, isNull);
      expect(events.onContextMenu, isNull);
    });

    test('constructor with all callbacks', () {
      void onCreate(Node<String> node) {}
      Future<bool> onBeforeDelete(Node<String> node) async => true;
      void onDelete(Node<String> node) {}
      void onSelect(Node<String>? node) {}
      void onTap(Node<String> node) {}
      void onDoubleTap(Node<String> node) {}
      void onDragStart(Node<String> node) {}
      void onDrag(Node<String> node) {}
      void onDragStop(Node<String> node) {}
      void onDragCancel(Node<String> node) {}
      void onResizeCancel(Node<String> node) {}
      void onMouseEnter(Node<String> node) {}
      void onMouseLeave(Node<String> node) {}
      void onContextMenu(Node<String> node, ScreenPosition pos) {}

      final events = NodeEvents<String>(
        onCreated: onCreate,
        onBeforeDelete: onBeforeDelete,
        onDeleted: onDelete,
        onSelected: onSelect,
        onTap: onTap,
        onDoubleTap: onDoubleTap,
        onDragStart: onDragStart,
        onDrag: onDrag,
        onDragStop: onDragStop,
        onDragCancel: onDragCancel,
        onResizeCancel: onResizeCancel,
        onMouseEnter: onMouseEnter,
        onMouseLeave: onMouseLeave,
        onContextMenu: onContextMenu,
      );

      expect(events.onCreated, isNotNull);
      expect(events.onBeforeDelete, isNotNull);
      expect(events.onDeleted, isNotNull);
      expect(events.onSelected, isNotNull);
      expect(events.onTap, isNotNull);
      expect(events.onDoubleTap, isNotNull);
      expect(events.onDragStart, isNotNull);
      expect(events.onDrag, isNotNull);
      expect(events.onDragStop, isNotNull);
      expect(events.onDragCancel, isNotNull);
      expect(events.onResizeCancel, isNotNull);
      expect(events.onMouseEnter, isNotNull);
      expect(events.onMouseLeave, isNotNull);
      expect(events.onContextMenu, isNotNull);
    });

    test('copyWith replaces specified values', () {
      void originalTap(Node<String> node) {}
      final original = NodeEvents<String>(onTap: originalTap);
      void newDoubleTap(Node<String> node) {}

      final copied = original.copyWith(onDoubleTap: newDoubleTap);

      expect(copied.onTap, equals(originalTap));
      expect(copied.onDoubleTap, equals(newDoubleTap));
    });

    test('copyWith preserves all unspecified values', () {
      void onCreate(Node<String> node) {}
      void onDelete(Node<String> node) {}
      void onTap(Node<String> node) {}
      final original = NodeEvents<String>(
        onCreated: onCreate,
        onDeleted: onDelete,
        onTap: onTap,
      );
      void newDoubleTap(Node<String> node) {}

      final copied = original.copyWith(onDoubleTap: newDoubleTap);

      expect(copied.onCreated, equals(onCreate));
      expect(copied.onDeleted, equals(onDelete));
      expect(copied.onTap, equals(onTap));
      expect(copied.onDoubleTap, equals(newDoubleTap));
    });
  });

  // ===========================================================================
  // PortEvents Tests
  // ===========================================================================

  group('PortEvents', () {
    test('default constructor creates empty events', () {
      const events = PortEvents<String>();

      expect(events.onTap, isNull);
      expect(events.onDoubleTap, isNull);
      expect(events.onMouseEnter, isNull);
      expect(events.onMouseLeave, isNull);
      expect(events.onContextMenu, isNull);
    });

    test('constructor with all callbacks', () {
      void onTap(Node<String> node, Port port) {}
      void onDoubleTap(Node<String> node, Port port) {}
      void onMouseEnter(Node<String> node, Port port) {}
      void onMouseLeave(Node<String> node, Port port) {}
      void onContextMenu(Node<String> node, Port port, ScreenPosition pos) {}

      final events = PortEvents<String>(
        onTap: onTap,
        onDoubleTap: onDoubleTap,
        onMouseEnter: onMouseEnter,
        onMouseLeave: onMouseLeave,
        onContextMenu: onContextMenu,
      );

      expect(events.onTap, isNotNull);
      expect(events.onDoubleTap, isNotNull);
      expect(events.onMouseEnter, isNotNull);
      expect(events.onMouseLeave, isNotNull);
      expect(events.onContextMenu, isNotNull);
    });

    test('copyWith replaces specified values', () {
      void originalTap(Node<String> node, Port port) {}
      final original = PortEvents<String>(onTap: originalTap);
      void newDoubleTap(Node<String> node, Port port) {}

      final copied = original.copyWith(onDoubleTap: newDoubleTap);

      expect(copied.onTap, equals(originalTap));
      expect(copied.onDoubleTap, equals(newDoubleTap));
    });

    test('copyWith with all values', () {
      void newTap(Node<String> node, Port port) {}
      void newDoubleTap(Node<String> node, Port port) {}
      void newMouseEnter(Node<String> node, Port port) {}
      void newMouseLeave(Node<String> node, Port port) {}
      void newContextMenu(Node<String> node, Port port, ScreenPosition pos) {}

      const original = PortEvents<String>();

      final copied = original.copyWith(
        onTap: newTap,
        onDoubleTap: newDoubleTap,
        onMouseEnter: newMouseEnter,
        onMouseLeave: newMouseLeave,
        onContextMenu: newContextMenu,
      );

      expect(copied.onTap, equals(newTap));
      expect(copied.onDoubleTap, equals(newDoubleTap));
      expect(copied.onMouseEnter, equals(newMouseEnter));
      expect(copied.onMouseLeave, equals(newMouseLeave));
      expect(copied.onContextMenu, equals(newContextMenu));
    });
  });

  // ===========================================================================
  // ConnectionEvents Tests
  // ===========================================================================

  group('ConnectionEvents', () {
    test('default constructor creates empty events', () {
      const events = ConnectionEvents<String, dynamic>();

      expect(events.onCreated, isNull);
      expect(events.onBeforeDelete, isNull);
      expect(events.onDeleted, isNull);
      expect(events.onSelected, isNull);
      expect(events.onTap, isNull);
      expect(events.onDoubleTap, isNull);
      expect(events.onMouseEnter, isNull);
      expect(events.onMouseLeave, isNull);
      expect(events.onContextMenu, isNull);
      expect(events.onConnectStart, isNull);
      expect(events.onConnectEnd, isNull);
      expect(events.onBeforeStart, isNull);
      expect(events.onBeforeComplete, isNull);
    });

    test('constructor with all callbacks', () {
      void onCreate(Connection<dynamic> conn) {}
      Future<bool> onBeforeDelete(Connection<dynamic> conn) async => true;
      void onDelete(Connection<dynamic> conn) {}
      void onSelect(Connection<dynamic>? conn) {}
      void onTap(Connection<dynamic> conn) {}
      void onDoubleTap(Connection<dynamic> conn) {}
      void onMouseEnter(Connection<dynamic> conn) {}
      void onMouseLeave(Connection<dynamic> conn) {}
      void onContextMenu(Connection<dynamic> conn, ScreenPosition pos) {}
      void onConnectStart(Node<String> node, Port port) {}
      void onConnectEnd(Node<String>? node, Port? port, GraphPosition pos) {}
      ConnectionValidationResult onBeforeStart(
        ConnectionStartContext<String> ctx,
      ) {
        return const ConnectionValidationResult.allow();
      }

      ConnectionValidationResult onBeforeComplete(
        ConnectionCompleteContext<String> ctx,
      ) {
        return const ConnectionValidationResult.allow();
      }

      final events = ConnectionEvents<String, dynamic>(
        onCreated: onCreate,
        onBeforeDelete: onBeforeDelete,
        onDeleted: onDelete,
        onSelected: onSelect,
        onTap: onTap,
        onDoubleTap: onDoubleTap,
        onMouseEnter: onMouseEnter,
        onMouseLeave: onMouseLeave,
        onContextMenu: onContextMenu,
        onConnectStart: onConnectStart,
        onConnectEnd: onConnectEnd,
        onBeforeStart: onBeforeStart,
        onBeforeComplete: onBeforeComplete,
      );

      expect(events.onCreated, isNotNull);
      expect(events.onBeforeDelete, isNotNull);
      expect(events.onDeleted, isNotNull);
      expect(events.onSelected, isNotNull);
      expect(events.onTap, isNotNull);
      expect(events.onDoubleTap, isNotNull);
      expect(events.onMouseEnter, isNotNull);
      expect(events.onMouseLeave, isNotNull);
      expect(events.onContextMenu, isNotNull);
      expect(events.onConnectStart, isNotNull);
      expect(events.onConnectEnd, isNotNull);
      expect(events.onBeforeStart, isNotNull);
      expect(events.onBeforeComplete, isNotNull);
    });

    test('copyWith replaces specified values', () {
      void originalTap(Connection<dynamic> conn) {}
      final original = ConnectionEvents<String, dynamic>(onTap: originalTap);
      void newDoubleTap(Connection<dynamic> conn) {}

      final copied = original.copyWith(onDoubleTap: newDoubleTap);

      expect(copied.onTap, equals(originalTap));
      expect(copied.onDoubleTap, equals(newDoubleTap));
    });

    test('copyWith preserves all unspecified values', () {
      void onCreate(Connection<dynamic> conn) {}
      void onDelete(Connection<dynamic> conn) {}
      void onConnectStart(Node<String> node, Port port) {}
      final original = ConnectionEvents<String, dynamic>(
        onCreated: onCreate,
        onDeleted: onDelete,
        onConnectStart: onConnectStart,
      );
      void newTap(Connection<dynamic> conn) {}

      final copied = original.copyWith(onTap: newTap);

      expect(copied.onCreated, equals(onCreate));
      expect(copied.onDeleted, equals(onDelete));
      expect(copied.onConnectStart, equals(onConnectStart));
      expect(copied.onTap, equals(newTap));
    });
  });

  // ===========================================================================
  // ViewportEvents Tests
  // ===========================================================================

  group('ViewportEvents', () {
    test('default constructor creates empty events', () {
      const events = ViewportEvents();

      expect(events.onMove, isNull);
      expect(events.onMoveStart, isNull);
      expect(events.onMoveEnd, isNull);
      expect(events.onCanvasTap, isNull);
      expect(events.onCanvasDoubleTap, isNull);
      expect(events.onCanvasContextMenu, isNull);
    });

    test('constructor with all callbacks', () {
      void onMove(GraphViewport vp) {}
      void onMoveStart(GraphViewport vp) {}
      void onMoveEnd(GraphViewport vp) {}
      void onCanvasTap(GraphPosition pos) {}
      void onCanvasDoubleTap(GraphPosition pos) {}
      void onCanvasContextMenu(GraphPosition pos) {}

      final events = ViewportEvents(
        onMove: onMove,
        onMoveStart: onMoveStart,
        onMoveEnd: onMoveEnd,
        onCanvasTap: onCanvasTap,
        onCanvasDoubleTap: onCanvasDoubleTap,
        onCanvasContextMenu: onCanvasContextMenu,
      );

      expect(events.onMove, isNotNull);
      expect(events.onMoveStart, isNotNull);
      expect(events.onMoveEnd, isNotNull);
      expect(events.onCanvasTap, isNotNull);
      expect(events.onCanvasDoubleTap, isNotNull);
      expect(events.onCanvasContextMenu, isNotNull);
    });

    test('copyWith replaces specified values', () {
      void originalMove(GraphViewport vp) {}
      final original = ViewportEvents(onMove: originalMove);
      void newMoveStart(GraphViewport vp) {}

      final copied = original.copyWith(onMoveStart: newMoveStart);

      expect(copied.onMove, equals(originalMove));
      expect(copied.onMoveStart, equals(newMoveStart));
    });

    test('copyWith with all values', () {
      void newMove(GraphViewport vp) {}
      void newMoveStart(GraphViewport vp) {}
      void newMoveEnd(GraphViewport vp) {}
      void newCanvasTap(GraphPosition pos) {}
      void newCanvasDoubleTap(GraphPosition pos) {}
      void newCanvasContextMenu(GraphPosition pos) {}

      const original = ViewportEvents();

      final copied = original.copyWith(
        onMove: newMove,
        onMoveStart: newMoveStart,
        onMoveEnd: newMoveEnd,
        onCanvasTap: newCanvasTap,
        onCanvasDoubleTap: newCanvasDoubleTap,
        onCanvasContextMenu: newCanvasContextMenu,
      );

      expect(copied.onMove, equals(newMove));
      expect(copied.onMoveStart, equals(newMoveStart));
      expect(copied.onMoveEnd, equals(newMoveEnd));
      expect(copied.onCanvasTap, equals(newCanvasTap));
      expect(copied.onCanvasDoubleTap, equals(newCanvasDoubleTap));
      expect(copied.onCanvasContextMenu, equals(newCanvasContextMenu));
    });
  });

  // ===========================================================================
  // SelectionState Tests
  // ===========================================================================

  group('SelectionState', () {
    test('constructor creates state with nodes and connections', () {
      final node = createTestNode(id: 'node-1');
      final connection = createTestConnection(
        sourceNodeId: 'node-a',
        targetNodeId: 'node-b',
      );

      final state = SelectionState<String, dynamic>(
        nodes: [node],
        connections: [connection],
      );

      expect(state.nodes, hasLength(1));
      expect(state.connections, hasLength(1));
    });

    test('hasSelection returns true when nodes are selected', () {
      final node = createTestNode(id: 'node-1');

      final state = SelectionState<String, dynamic>(
        nodes: [node],
        connections: [],
      );

      expect(state.hasSelection, isTrue);
    });

    test('hasSelection returns true when connections are selected', () {
      final connection = createTestConnection(
        sourceNodeId: 'node-a',
        targetNodeId: 'node-b',
      );

      final state = SelectionState<String, dynamic>(
        nodes: [],
        connections: [connection],
      );

      expect(state.hasSelection, isTrue);
    });

    test('hasSelection returns true when both are selected', () {
      final node = createTestNode(id: 'node-1');
      final connection = createTestConnection(
        sourceNodeId: 'node-a',
        targetNodeId: 'node-b',
      );

      final state = SelectionState<String, dynamic>(
        nodes: [node],
        connections: [connection],
      );

      expect(state.hasSelection, isTrue);
    });

    test('hasSelection returns false when nothing is selected', () {
      const state = SelectionState<String, dynamic>(nodes: [], connections: []);

      expect(state.hasSelection, isFalse);
    });
  });

  // ===========================================================================
  // FlowError Tests
  // ===========================================================================

  group('FlowError', () {
    test('constructor with message only', () {
      const error = FlowError(message: 'Test error');

      expect(error.message, equals('Test error'));
      expect(error.error, isNull);
      expect(error.stackTrace, isNull);
    });

    test('constructor with all parameters', () {
      final exception = Exception('Test exception');
      final stackTrace = StackTrace.current;

      final error = FlowError(
        message: 'Test error',
        error: exception,
        stackTrace: stackTrace,
      );

      expect(error.message, equals('Test error'));
      expect(error.error, equals(exception));
      expect(error.stackTrace, equals(stackTrace));
    });

    test('error can be any object', () {
      const error = FlowError(message: 'Test error', error: 'String error');

      expect(error.error, isA<String>());
      expect(error.error, equals('String error'));
    });
  });

  // ===========================================================================
  // Integration Tests with Controller
  // ===========================================================================

  group('Events Integration', () {
    test('controller setEvents applies events correctly', () {
      Node<String>? tappedNode;
      void onTap(Node<String> node) {
        tappedNode = node;
      }

      final controller = createTestController();
      controller.updateEvents(
        NodeFlowEvents<String, dynamic>(node: NodeEvents<String>(onTap: onTap)),
      );

      expect(controller.events.node?.onTap, isNotNull);
    });

    test('node events fire correctly', () {
      Node<String>? createdNode;
      void onCreate(Node<String> node) {
        createdNode = node;
      }

      final controller = createTestController();
      controller.updateEvents(
        NodeFlowEvents<String, dynamic>(
          node: NodeEvents<String>(onCreated: onCreate),
        ),
      );

      final node = createTestNode(id: 'new-node');
      controller.addNode(node);

      expect(createdNode, isNotNull);
      expect(createdNode!.id, equals('new-node'));
    });

    test('connection events fire correctly', () {
      Connection<dynamic>? createdConn;
      void onCreate(Connection<dynamic> conn) {
        createdConn = conn;
      }

      final nodeA = createTestNodeWithOutputPort(id: 'node-a');
      final nodeB = createTestNodeWithInputPort(id: 'node-b');
      final controller = createTestController(nodes: [nodeA, nodeB]);
      controller.updateEvents(
        NodeFlowEvents<String, dynamic>(
          connection: ConnectionEvents<String, dynamic>(onCreated: onCreate),
        ),
      );

      controller.createConnection('node-a', 'output-1', 'node-b', 'input-1');

      expect(createdConn, isNotNull);
    });

    test('selection change event fires', () {
      SelectionState<String, dynamic>? lastSelection;
      void onSelectionChange(SelectionState<String, dynamic> state) {
        lastSelection = state;
      }

      final node = createTestNode(id: 'node-1');
      final controller = createTestController(nodes: [node]);
      controller.updateEvents(
        NodeFlowEvents<String, dynamic>(onSelectionChange: onSelectionChange),
      );

      controller.selectNode('node-1');

      expect(lastSelection, isNotNull);
      expect(lastSelection!.hasSelection, isTrue);
      expect(lastSelection!.nodes.first.id, equals('node-1'));
    });
  });
}
