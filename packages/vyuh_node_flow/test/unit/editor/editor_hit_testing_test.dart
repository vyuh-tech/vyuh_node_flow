/// Unit tests for the editor hit testing functionality.
///
/// Tests cover:
/// - HitTestResult construction and properties
/// - HitTarget enum values and behavior
/// - HitTestResult convenience getters
/// - Spatial index hit testing scenarios
/// - Viewport coordinate transformations
/// - Layer-based hit testing priority
/// - Z-index ordering during hit testing
@Tags(['unit'])
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vyuh_node_flow/vyuh_node_flow.dart';
import 'package:vyuh_node_flow/src/shared/spatial/graph_spatial_index.dart';

import '../../helpers/test_factories.dart';

void main() {
  setUp(() {
    resetTestCounters();
  });

  // ===========================================================================
  // HitTarget Enum Tests
  // ===========================================================================

  group('HitTarget Enum', () {
    test('has all expected values', () {
      expect(HitTarget.values, hasLength(4));
      expect(HitTarget.values, contains(HitTarget.node));
      expect(HitTarget.values, contains(HitTarget.port));
      expect(HitTarget.values, contains(HitTarget.connection));
      expect(HitTarget.values, contains(HitTarget.canvas));
    });

    test('node target represents node hit', () {
      expect(HitTarget.node.name, equals('node'));
    });

    test('port target represents port hit', () {
      expect(HitTarget.port.name, equals('port'));
    });

    test('connection target represents connection hit', () {
      expect(HitTarget.connection.name, equals('connection'));
    });

    test('canvas target represents empty canvas hit', () {
      expect(HitTarget.canvas.name, equals('canvas'));
    });
  });

  // ===========================================================================
  // HitTestResult Construction Tests
  // ===========================================================================

  group('HitTestResult Construction', () {
    test('creates default canvas hit result', () {
      const result = HitTestResult();

      expect(result.hitType, equals(HitTarget.canvas));
      expect(result.nodeId, isNull);
      expect(result.portId, isNull);
      expect(result.connectionId, isNull);
      expect(result.isOutput, isNull);
      expect(result.position, isNull);
    });

    test('creates node hit result', () {
      const result = HitTestResult(
        hitType: HitTarget.node,
        nodeId: 'test-node-1',
        position: Offset(100, 200),
      );

      expect(result.hitType, equals(HitTarget.node));
      expect(result.nodeId, equals('test-node-1'));
      expect(result.position, equals(const Offset(100, 200)));
    });

    test('creates port hit result', () {
      const result = HitTestResult(
        hitType: HitTarget.port,
        nodeId: 'parent-node',
        portId: 'output-port-1',
        isOutput: true,
        position: Offset(150, 100),
      );

      expect(result.hitType, equals(HitTarget.port));
      expect(result.nodeId, equals('parent-node'));
      expect(result.portId, equals('output-port-1'));
      expect(result.isOutput, isTrue);
    });

    test('creates input port hit result', () {
      const result = HitTestResult(
        hitType: HitTarget.port,
        nodeId: 'parent-node',
        portId: 'input-port-1',
        isOutput: false,
      );

      expect(result.hitType, equals(HitTarget.port));
      expect(result.isOutput, isFalse);
    });

    test('creates connection hit result', () {
      const result = HitTestResult(
        hitType: HitTarget.connection,
        connectionId: 'conn-1',
        position: Offset(300, 150),
      );

      expect(result.hitType, equals(HitTarget.connection));
      expect(result.connectionId, equals('conn-1'));
      expect(result.nodeId, isNull);
    });
  });

  // ===========================================================================
  // HitTestResult Convenience Getters Tests
  // ===========================================================================

  group('HitTestResult Convenience Getters', () {
    test('isNode returns true only for node hits', () {
      const nodeResult = HitTestResult(
        hitType: HitTarget.node,
        nodeId: 'node-1',
      );
      const portResult = HitTestResult(
        hitType: HitTarget.port,
        nodeId: 'node-1',
        portId: 'port-1',
      );
      const connectionResult = HitTestResult(
        hitType: HitTarget.connection,
        connectionId: 'conn-1',
      );
      const canvasResult = HitTestResult();

      expect(nodeResult.isNode, isTrue);
      expect(portResult.isNode, isFalse);
      expect(connectionResult.isNode, isFalse);
      expect(canvasResult.isNode, isFalse);
    });

    test('isPort returns true only for port hits', () {
      const nodeResult = HitTestResult(
        hitType: HitTarget.node,
        nodeId: 'node-1',
      );
      const portResult = HitTestResult(
        hitType: HitTarget.port,
        nodeId: 'node-1',
        portId: 'port-1',
      );
      const connectionResult = HitTestResult(
        hitType: HitTarget.connection,
        connectionId: 'conn-1',
      );
      const canvasResult = HitTestResult();

      expect(nodeResult.isPort, isFalse);
      expect(portResult.isPort, isTrue);
      expect(connectionResult.isPort, isFalse);
      expect(canvasResult.isPort, isFalse);
    });

    test('isConnection returns true only for connection hits', () {
      const nodeResult = HitTestResult(
        hitType: HitTarget.node,
        nodeId: 'node-1',
      );
      const portResult = HitTestResult(
        hitType: HitTarget.port,
        nodeId: 'node-1',
        portId: 'port-1',
      );
      const connectionResult = HitTestResult(
        hitType: HitTarget.connection,
        connectionId: 'conn-1',
      );
      const canvasResult = HitTestResult();

      expect(nodeResult.isConnection, isFalse);
      expect(portResult.isConnection, isFalse);
      expect(connectionResult.isConnection, isTrue);
      expect(canvasResult.isConnection, isFalse);
    });

    test('isCanvas returns true only for canvas hits', () {
      const nodeResult = HitTestResult(
        hitType: HitTarget.node,
        nodeId: 'node-1',
      );
      const portResult = HitTestResult(
        hitType: HitTarget.port,
        nodeId: 'node-1',
        portId: 'port-1',
      );
      const connectionResult = HitTestResult(
        hitType: HitTarget.connection,
        connectionId: 'conn-1',
      );
      const canvasResult = HitTestResult();

      expect(nodeResult.isCanvas, isFalse);
      expect(portResult.isCanvas, isFalse);
      expect(connectionResult.isCanvas, isFalse);
      expect(canvasResult.isCanvas, isTrue);
    });
  });

  // ===========================================================================
  // HitTestResult Edge Cases
  // ===========================================================================

  group('HitTestResult Edge Cases', () {
    test('port hit includes parent node ID', () {
      const result = HitTestResult(
        hitType: HitTarget.port,
        nodeId: 'parent-node-id',
        portId: 'child-port-id',
        isOutput: true,
      );

      // Port hits should always have a nodeId for context
      expect(result.nodeId, isNotNull);
      expect(result.portId, isNotNull);
    });

    test('handles position with negative coordinates', () {
      const result = HitTestResult(
        hitType: HitTarget.node,
        nodeId: 'node-1',
        position: Offset(-100, -50),
      );

      expect(result.position!.dx, equals(-100));
      expect(result.position!.dy, equals(-50));
    });

    test('handles position with zero coordinates', () {
      const result = HitTestResult(
        hitType: HitTarget.node,
        nodeId: 'node-1',
        position: Offset.zero,
      );

      expect(result.position, equals(Offset.zero));
    });

    test('handles position with large coordinates', () {
      const result = HitTestResult(
        hitType: HitTarget.node,
        nodeId: 'node-1',
        position: Offset(10000, 10000),
      );

      expect(result.position!.dx, equals(10000));
      expect(result.position!.dy, equals(10000));
    });
  });

  // ===========================================================================
  // InteractionState Hit Testing Related Tests
  // ===========================================================================

  group('InteractionState for Hit Testing', () {
    test('tracks hovered connection state', () {
      final controller = createTestController();
      final state = controller.interaction;

      expect(state.isHoveringConnection, isFalse);

      state.setHoveringConnection(true);
      expect(state.isHoveringConnection, isTrue);

      state.setHoveringConnection(false);
      expect(state.isHoveringConnection, isFalse);
    });

    test('tracks selection started state for shift key', () {
      final controller = createTestController();
      final state = controller.interaction;

      expect(state.hasStartedSelection, isFalse);

      state.setSelectionStarted(true);
      expect(state.hasStartedSelection, isTrue);

      state.setSelectionStarted(false);
      expect(state.hasStartedSelection, isFalse);
    });

    test('tracks pointer position for hover events', () {
      final controller = createTestController();
      final state = controller.interaction;

      expect(state.pointerPosition, isNull);

      final position = ScreenPosition(const Offset(100, 200));
      state.setPointerPosition(position);
      expect(state.pointerPosition?.offset, equals(const Offset(100, 200)));

      state.setPointerPosition(null);
      expect(state.pointerPosition, isNull);
    });

    test('resetState clears all hit testing related state', () {
      final controller = createTestController();
      final state = controller.interaction;

      // Set various states
      state.setHoveringConnection(true);
      state.setSelectionStarted(true);
      state.setPointerPosition(ScreenPosition(const Offset(100, 200)));

      // Reset
      state.resetState();

      // Verify all cleared
      expect(state.isHoveringConnection, isFalse);
      expect(state.hasStartedSelection, isFalse);
      expect(state.pointerPosition, isNull);
    });
  });

  // ===========================================================================
  // Controller Hit Testing Support Tests
  // ===========================================================================

  group('Controller Hit Testing Support', () {
    test('controller provides spatial index for hit testing', () {
      final controller = createTestController();

      expect(controller.spatialIndex, isNotNull);
    });

    test('controller tracks canvas lock state', () {
      final controller = createTestController();

      expect(controller.canvasLocked, isFalse);

      // Canvas is locked during drag operations
      controller.interaction.canvasLocked.value = true;
      expect(controller.canvasLocked, isTrue);

      controller.interaction.canvasLocked.value = false;
      expect(controller.canvasLocked, isFalse);
    });

    test('controller exposes interaction state for hit testing', () {
      final controller = createTestController();

      expect(controller.interaction, isNotNull);
      expect(controller.interaction.isHoveringConnection, isFalse);
    });
  });

  // ===========================================================================
  // Selection Rectangle Tests
  // ===========================================================================

  group('Selection Rectangle Hit Testing', () {
    test('tracks selection rectangle state', () {
      final controller = createTestController();
      final state = controller.interaction;

      expect(state.isDrawingSelection, isFalse);
      expect(state.currentSelectionRect, isNull);

      // Start selection
      state.updateSelection(
        startPoint: const GraphPosition(Offset(0, 0)),
        rectangle: const GraphRect(Rect.fromLTWH(0, 0, 100, 100)),
      );

      expect(state.isDrawingSelection, isTrue);
      expect(state.currentSelectionRect?.rect.width, equals(100));
    });

    test('finishes selection clears rectangle state', () {
      final controller = createTestController();
      final state = controller.interaction;

      // Setup selection
      state.updateSelection(
        startPoint: const GraphPosition(Offset(0, 0)),
        rectangle: const GraphRect(Rect.fromLTWH(0, 0, 100, 100)),
      );

      expect(state.isDrawingSelection, isTrue);

      // Finish selection
      state.finishSelection();

      expect(state.isDrawingSelection, isFalse);
      expect(state.currentSelectionRect, isNull);
      expect(state.selectionStartPoint, isNull);
    });

    test('selection tracks start point separately from rectangle', () {
      final controller = createTestController();
      final state = controller.interaction;

      const startPoint = GraphPosition(Offset(50, 50));
      const rectangle = GraphRect(Rect.fromLTWH(50, 50, 200, 150));

      state.updateSelection(startPoint: startPoint, rectangle: rectangle);

      expect(state.selectionStartPoint?.offset, equals(const Offset(50, 50)));
      expect(state.currentSelectionRect?.rect.width, equals(200));
      expect(state.currentSelectionRect?.rect.height, equals(150));
    });
  });

  // ===========================================================================
  // Cursor Override for Hit Testing
  // ===========================================================================

  group('Cursor Override for Hit Testing', () {
    test('cursor override takes precedence', () {
      final controller = createTestController();
      final state = controller.interaction;

      expect(state.currentCursorOverride, isNull);
      expect(state.hasCursorOverride, isFalse);

      state.setCursorOverride(SystemMouseCursors.resizeUpDown);

      expect(
        state.currentCursorOverride,
        equals(SystemMouseCursors.resizeUpDown),
      );
      expect(state.hasCursorOverride, isTrue);
    });

    test('clearing cursor override restores normal cursor derivation', () {
      final controller = createTestController();
      final state = controller.interaction;

      state.setCursorOverride(SystemMouseCursors.resizeUpDown);
      expect(state.hasCursorOverride, isTrue);

      state.setCursorOverride(null);
      expect(state.hasCursorOverride, isFalse);
    });
  });

  // ===========================================================================
  // Spatial Index Hit Testing Tests
  // ===========================================================================

  group('Spatial Index Hit Testing', () {
    late GraphSpatialIndex<String, dynamic> spatialIndex;

    setUp(() {
      spatialIndex = GraphSpatialIndex<String, dynamic>();
    });

    test('hitTest returns canvas when no elements at point', () {
      final result = spatialIndex.hitTest(const Offset(1000, 1000));

      expect(result.hitType, equals(HitTarget.canvas));
      expect(result.nodeId, isNull);
      expect(result.portId, isNull);
      expect(result.connectionId, isNull);
    });

    test('hitTest detects node at point', () {
      final node = createTestNode(
        id: 'hit-node',
        position: const Offset(100, 100),
        size: const Size(100, 50),
      );
      spatialIndex.update(node);

      // Hit test at center of node
      final result = spatialIndex.hitTest(const Offset(150, 125));

      expect(result.hitType, equals(HitTarget.node));
      expect(result.nodeId, equals('hit-node'));
    });

    test('hitTest returns canvas when testing outside node bounds', () {
      final node = createTestNode(
        id: 'bounded-node',
        position: const Offset(100, 100),
        size: const Size(100, 50),
      );
      spatialIndex.update(node);

      // Hit test outside node bounds
      final result = spatialIndex.hitTest(const Offset(50, 50));

      expect(result.hitType, equals(HitTarget.canvas));
    });

    test('hitTest respects z-index ordering for overlapping nodes', () {
      // Create two overlapping nodes with different z-indices
      final backNode = createTestNode(
        id: 'back-node',
        position: const Offset(100, 100),
        size: const Size(100, 100),
        zIndex: 0,
      );
      final frontNode = createTestNode(
        id: 'front-node',
        position: const Offset(120, 120),
        size: const Size(100, 100),
        zIndex: 10,
      );
      spatialIndex.update(backNode);
      spatialIndex.update(frontNode);

      // Hit test at overlapping region should return front node
      final result = spatialIndex.hitTest(const Offset(150, 150));

      expect(result.hitType, equals(HitTarget.node));
      expect(result.nodeId, equals('front-node'));
    });

    test('hitTest detects input port on node', () {
      final node = createTestNodeWithInputPort(
        id: 'port-node',
        portId: 'test-input',
        position: const Offset(100, 100),
      );
      // Set size to ensure proper port positioning
      node.setSize(const Size(100, 50));
      spatialIndex.update(node);

      // Get port center
      const portSize = Size.square(10);
      final portCenter = node.getPortCenter('test-input', portSize: portSize);

      final result = spatialIndex.hitTest(portCenter);

      expect(result.hitType, equals(HitTarget.port));
      expect(result.nodeId, equals('port-node'));
      expect(result.portId, equals('test-input'));
      expect(result.isOutput, isFalse);
    });

    test('hitTest detects output port on node', () {
      final node = createTestNodeWithOutputPort(
        id: 'port-node',
        portId: 'test-output',
        position: const Offset(100, 100),
      );
      node.setSize(const Size(100, 50));
      spatialIndex.update(node);

      // Get port center
      const portSize = Size.square(10);
      final portCenter = node.getPortCenter('test-output', portSize: portSize);

      final result = spatialIndex.hitTest(portCenter);

      expect(result.hitType, equals(HitTarget.port));
      expect(result.nodeId, equals('port-node'));
      expect(result.portId, equals('test-output'));
      expect(result.isOutput, isTrue);
    });

    test('hitTestPort returns port result when port at point', () {
      final node = createTestNodeWithInputPort(
        id: 'port-node',
        portId: 'test-port',
        position: const Offset(100, 100),
      );
      node.setSize(const Size(100, 50));
      spatialIndex.update(node);

      // Get port center
      const portSize = Size.square(10);
      final portCenter = node.getPortCenter('test-port', portSize: portSize);

      final result = spatialIndex.hitTestPort(portCenter);

      expect(result, isNotNull);
      expect(result!.hitType, equals(HitTarget.port));
      expect(result.portId, equals('test-port'));
    });

    test('hitTestPort returns null when no port at point', () {
      final node = createTestNode(
        id: 'no-port-node',
        position: const Offset(100, 100),
        size: const Size(100, 50),
      );
      spatialIndex.update(node);

      // Hit test far from any ports
      final result = spatialIndex.hitTestPort(const Offset(500, 500));

      expect(result, isNull);
    });

    test('nodesAt returns all nodes containing point', () {
      final node1 = createTestNode(
        id: 'node-1',
        position: const Offset(100, 100),
        size: const Size(100, 100),
      );
      final node2 = createTestNode(
        id: 'node-2',
        position: const Offset(120, 120),
        size: const Size(100, 100),
      );
      spatialIndex.update(node1);
      spatialIndex.update(node2);

      // Point in overlapping region
      final nodes = spatialIndex.nodesAt(const Offset(150, 150));

      expect(nodes, hasLength(2));
      expect(nodes.map((n) => n.id), containsAll(['node-1', 'node-2']));
    });

    test('nodesAt returns empty list when no nodes at point', () {
      final node = createTestNode(
        id: 'single-node',
        position: const Offset(100, 100),
        size: const Size(50, 50),
      );
      spatialIndex.update(node);

      final nodes = spatialIndex.nodesAt(const Offset(500, 500));

      expect(nodes, isEmpty);
    });

    test('nodesIn returns nodes within bounds', () {
      final node1 = createTestNode(
        id: 'inside-node',
        position: const Offset(50, 50),
        size: const Size(50, 50),
      );
      final node2 = createTestNode(
        id: 'outside-node',
        position: const Offset(500, 500),
        size: const Size(50, 50),
      );
      spatialIndex.update(node1);
      spatialIndex.update(node2);

      final nodes = spatialIndex.nodesIn(const Rect.fromLTWH(0, 0, 200, 200));

      expect(nodes, hasLength(1));
      expect(nodes.first.id, equals('inside-node'));
    });

    test('nodesIn handles empty bounds', () {
      final node = createTestNode(
        id: 'test-node',
        position: const Offset(100, 100),
        size: const Size(50, 50),
      );
      spatialIndex.update(node);

      final nodes = spatialIndex.nodesIn(Rect.zero);

      expect(nodes, isEmpty);
    });

    test('hitTest skips hidden nodes', () {
      final visibleNode = createTestNode(
        id: 'visible',
        position: const Offset(100, 100),
        size: const Size(100, 100),
        visible: true,
      );
      final hiddenNode = createTestNode(
        id: 'hidden',
        position: const Offset(100, 100),
        size: const Size(100, 100),
        visible: false,
        zIndex: 10, // Higher z-index but hidden
      );
      spatialIndex.update(visibleNode);
      spatialIndex.update(hiddenNode);

      final result = spatialIndex.hitTest(const Offset(150, 150));

      expect(result.hitType, equals(HitTarget.node));
      expect(result.nodeId, equals('visible'));
    });

    test('nodesAt skips hidden nodes', () {
      final visibleNode = createTestNode(
        id: 'visible',
        position: const Offset(100, 100),
        size: const Size(100, 100),
        visible: true,
      );
      final hiddenNode = createTestNode(
        id: 'hidden',
        position: const Offset(100, 100),
        size: const Size(100, 100),
        visible: false,
      );
      spatialIndex.update(visibleNode);
      spatialIndex.update(hiddenNode);

      final nodes = spatialIndex.nodesAt(const Offset(150, 150));

      expect(nodes, hasLength(1));
      expect(nodes.first.id, equals('visible'));
    });

    test('connectionsAt returns connections near point', () {
      // Create source and target nodes
      final sourceNode = createTestNodeWithOutputPort(
        id: 'source',
        portId: 'output-1',
        position: const Offset(0, 0),
      );
      sourceNode.setSize(const Size(100, 50));
      final targetNode = createTestNodeWithInputPort(
        id: 'target',
        portId: 'input-1',
        position: const Offset(200, 0),
      );
      targetNode.setSize(const Size(100, 50));

      spatialIndex.update(sourceNode);
      spatialIndex.update(targetNode);

      // Create connection with segment bounds
      final connection = createTestConnection(
        id: 'conn-1',
        sourceNodeId: 'source',
        targetNodeId: 'target',
      );
      spatialIndex.updateConnection(connection, [
        const Rect.fromLTWH(100, 20, 100, 10),
      ]);

      // Query at point within segment bounds
      final connections = spatialIndex.connectionsAt(const Offset(150, 25));

      expect(connections, hasLength(1));
      expect(connections.first.id, equals('conn-1'));
    });

    test('getNode returns node by id', () {
      final node = createTestNode(id: 'lookup-node');
      spatialIndex.update(node);

      final found = spatialIndex.getNode('lookup-node');

      expect(found, isNotNull);
      expect(found!.id, equals('lookup-node'));
    });

    test('getNode returns null for non-existent id', () {
      final found = spatialIndex.getNode('non-existent');

      expect(found, isNull);
    });

    test('getConnection returns connection by id', () {
      // Create source and target nodes
      final sourceNode = createTestNodeWithOutputPort(id: 'source');
      final targetNode = createTestNodeWithInputPort(id: 'target');
      spatialIndex.update(sourceNode);
      spatialIndex.update(targetNode);

      final connection = createTestConnection(
        id: 'conn-lookup',
        sourceNodeId: 'source',
        targetNodeId: 'target',
      );
      spatialIndex.updateConnection(connection, []);

      final found = spatialIndex.getConnection('conn-lookup');

      expect(found, isNotNull);
      expect(found!.id, equals('conn-lookup'));
    });

    test('getConnection returns null for non-existent id', () {
      final found = spatialIndex.getConnection('non-existent');

      expect(found, isNull);
    });

    test('spatial index tracks node count', () {
      expect(spatialIndex.nodeCount, equals(0));

      spatialIndex.update(createTestNode(id: 'node-1'));
      expect(spatialIndex.nodeCount, equals(1));

      spatialIndex.update(createTestNode(id: 'node-2'));
      expect(spatialIndex.nodeCount, equals(2));
    });

    test('spatial index tracks connection count', () {
      final sourceNode = createTestNodeWithOutputPort(id: 'source');
      final targetNode = createTestNodeWithInputPort(id: 'target');
      spatialIndex.update(sourceNode);
      spatialIndex.update(targetNode);

      expect(spatialIndex.connectionCount, equals(0));

      final connection = createTestConnection(
        id: 'conn-1',
        sourceNodeId: 'source',
        targetNodeId: 'target',
      );
      spatialIndex.updateConnection(connection, []);

      expect(spatialIndex.connectionCount, equals(1));
    });

    test('spatial index tracks port count', () {
      final node = createTestNodeWithPorts(id: 'ports-node');
      node.setSize(const Size(100, 50));
      spatialIndex.update(node);

      // One input port + one output port = 2 ports
      expect(spatialIndex.portCount, equals(2));
    });

    test('spatial index version increments on changes', () {
      final initialVersion = spatialIndex.version.value;

      spatialIndex.update(createTestNode(id: 'version-test'));

      expect(spatialIndex.version.value, greaterThan(initialVersion));
    });
  });

  // ===========================================================================
  // Viewport Coordinate Transformation Tests
  // ===========================================================================

  group('Viewport Coordinate Transformation', () {
    test('toGraph converts screen to graph coordinates at 1x zoom', () {
      const viewport = GraphViewport(x: 0, y: 0, zoom: 1.0);

      final screenPos = ScreenPosition(const Offset(100, 200));
      final graphPos = viewport.toGraph(screenPos);

      expect(graphPos.offset.dx, equals(100));
      expect(graphPos.offset.dy, equals(200));
    });

    test('toGraph accounts for viewport translation', () {
      // Positive x means the graph origin is translated left in screen space
      const viewport = GraphViewport(x: 50, y: 100, zoom: 1.0);

      final screenPos = ScreenPosition(const Offset(100, 200));
      final graphPos = viewport.toGraph(screenPos);

      // Graph position = (screen - translation) / zoom
      expect(graphPos.offset.dx, equals(50));
      expect(graphPos.offset.dy, equals(100));
    });

    test('toGraph accounts for zoom', () {
      const viewport = GraphViewport(x: 0, y: 0, zoom: 2.0);

      final screenPos = ScreenPosition(const Offset(200, 400));
      final graphPos = viewport.toGraph(screenPos);

      // At 2x zoom, screen position 200 corresponds to graph position 100
      expect(graphPos.offset.dx, equals(100));
      expect(graphPos.offset.dy, equals(200));
    });

    test('toScreen converts graph to screen coordinates', () {
      const viewport = GraphViewport(x: 0, y: 0, zoom: 1.0);

      final graphPos = GraphPosition(const Offset(100, 200));
      final screenPos = viewport.toScreen(graphPos);

      expect(screenPos.offset.dx, equals(100));
      expect(screenPos.offset.dy, equals(200));
    });

    test('toScreen accounts for zoom', () {
      const viewport = GraphViewport(x: 0, y: 0, zoom: 2.0);

      final graphPos = GraphPosition(const Offset(100, 200));
      final screenPos = viewport.toScreen(graphPos);

      // At 2x zoom, graph position 100 corresponds to screen position 200
      expect(screenPos.offset.dx, equals(200));
      expect(screenPos.offset.dy, equals(400));
    });

    test('coordinate conversion is reversible', () {
      const viewport = GraphViewport(x: 100, y: 50, zoom: 1.5);

      final originalScreen = ScreenPosition(const Offset(300, 400));
      final graphPos = viewport.toGraph(originalScreen);
      final backToScreen = viewport.toScreen(graphPos);

      expect(backToScreen.offset.dx, closeTo(originalScreen.offset.dx, 0.001));
      expect(backToScreen.offset.dy, closeTo(originalScreen.offset.dy, 0.001));
    });

    test('toGraph with combined pan and zoom', () {
      // Pan (100, 50) and zoom 2x
      const viewport = GraphViewport(x: 100, y: 50, zoom: 2.0);

      // Screen (300, 150) -> graph ((300-100)/2, (150-50)/2) = (100, 50)
      final screenPos = ScreenPosition(const Offset(300, 150));
      final graphPos = viewport.toGraph(screenPos);

      expect(graphPos.offset.dx, equals(100));
      expect(graphPos.offset.dy, equals(50));
    });

    test('hit testing uses graph coordinates after viewport transform', () {
      final spatialIndex = GraphSpatialIndex<String, dynamic>();

      // Node at graph position (100, 100)
      final node = createTestNode(
        id: 'graph-pos',
        position: const Offset(100, 100),
        size: const Size(100, 100),
      );
      spatialIndex.update(node);

      // Viewport with pan
      const viewport = GraphViewport(x: 50, y: 50, zoom: 1.0);

      // Screen position (200, 200) -> graph (150, 150) which is inside node
      final screenPos = ScreenPosition(const Offset(200, 200));
      final graphPos = viewport.toGraph(screenPos);

      final result = spatialIndex.hitTest(graphPos.offset);

      expect(result.hitType, equals(HitTarget.node));
      expect(result.nodeId, equals('graph-pos'));
    });

    test('hit testing respects zoomed viewport', () {
      final spatialIndex = GraphSpatialIndex<String, dynamic>();

      // Small node at origin
      final node = createTestNode(
        id: 'zoom-test',
        position: Offset.zero,
        size: const Size(50, 50),
      );
      spatialIndex.update(node);

      // Zoomed out (zoom 0.5 means graph appears half size)
      const viewport = GraphViewport(x: 0, y: 0, zoom: 0.5);

      // Screen (50, 50) -> graph (100, 100) which is outside node (0,0 to 50,50)
      final screenPos = ScreenPosition(const Offset(50, 50));
      final graphPos = viewport.toGraph(screenPos);

      final result = spatialIndex.hitTest(graphPos.offset);

      expect(result.hitType, equals(HitTarget.canvas));
    });
  });

  // ===========================================================================
  // Layer-Based Hit Testing Priority Tests
  // ===========================================================================

  group('Layer-Based Hit Testing Priority', () {
    late GraphSpatialIndex<String, dynamic> spatialIndex;

    setUp(() {
      spatialIndex = GraphSpatialIndex<String, dynamic>();
    });

    test('foreground layer has highest hit priority', () {
      // Create a middle layer node and a foreground (comment) node
      final middleNode = createTestNode(
        id: 'middle-node',
        position: const Offset(100, 100),
        size: const Size(100, 100),
      );
      final foregroundNode = createTestCommentNode<String>(
        id: 'foreground-node',
        position: const Offset(120, 120),
        data: 'comment',
        width: 100,
        height: 100,
      );
      spatialIndex.update(middleNode);
      spatialIndex.update(foregroundNode);

      // Hit test at overlapping region
      final result = spatialIndex.hitTest(const Offset(150, 150));

      expect(result.hitType, equals(HitTarget.node));
      // Foreground node should be hit even though middle node has same position
      expect(result.nodeId, equals('foreground-node'));
    });

    test('middle layer has priority over background layer', () {
      // Create a background (group) node and a middle layer node
      final backgroundNode = createTestGroupNode<String>(
        id: 'background-node',
        position: const Offset(50, 50),
        size: const Size(200, 200),
        data: 'group',
      );
      final middleNode = createTestNode(
        id: 'middle-node',
        position: const Offset(100, 100),
        size: const Size(100, 100),
      );
      spatialIndex.update(backgroundNode);
      spatialIndex.update(middleNode);

      // Hit test at overlapping region
      final result = spatialIndex.hitTest(const Offset(150, 150));

      expect(result.hitType, equals(HitTarget.node));
      expect(result.nodeId, equals('middle-node'));
    });

    test('background layer is hit when no foreground or middle nodes', () {
      final backgroundNode = createTestGroupNode<String>(
        id: 'background-node',
        position: const Offset(100, 100),
        size: const Size(200, 200),
        data: 'group',
      );
      spatialIndex.update(backgroundNode);

      final result = spatialIndex.hitTest(const Offset(150, 150));

      expect(result.hitType, equals(HitTarget.node));
      expect(result.nodeId, equals('background-node'));
    });

    test('ports have priority over middle layer nodes at same position', () {
      // Create node with ports that overlap another node
      final nodeWithPort = createTestNodeWithOutputPort(
        id: 'node-with-port',
        portId: 'output-1',
        position: const Offset(100, 100),
      );
      nodeWithPort.setSize(const Size(100, 50));

      final overlappingNode = createTestNode(
        id: 'overlapping-node',
        position: const Offset(150, 100),
        size: const Size(100, 50),
        zIndex: -1, // Lower z-index
      );

      spatialIndex.update(nodeWithPort);
      spatialIndex.update(overlappingNode);

      // Get port center
      const portSize = Size.square(10);
      final portCenter = nodeWithPort.getPortCenter(
        'output-1',
        portSize: portSize,
      );

      final result = spatialIndex.hitTest(portCenter);

      // Port should be hit since it has priority
      expect(result.hitType, equals(HitTarget.port));
      expect(result.portId, equals('output-1'));
    });
  });

  // ===========================================================================
  // Z-Index Within Layer Tests
  // ===========================================================================

  group('Z-Index Ordering Within Same Layer', () {
    late GraphSpatialIndex<String, dynamic> spatialIndex;

    setUp(() {
      spatialIndex = GraphSpatialIndex<String, dynamic>();
    });

    test('higher z-index wins within same layer', () {
      final lowZNode = createTestNode(
        id: 'low-z',
        position: const Offset(100, 100),
        size: const Size(100, 100),
        zIndex: 1,
      );
      final highZNode = createTestNode(
        id: 'high-z',
        position: const Offset(100, 100),
        size: const Size(100, 100),
        zIndex: 100,
      );
      // Add in wrong order to ensure z-index is respected
      spatialIndex.update(highZNode);
      spatialIndex.update(lowZNode);

      final result = spatialIndex.hitTest(const Offset(150, 150));

      expect(result.hitType, equals(HitTarget.node));
      expect(result.nodeId, equals('high-z'));
    });

    test('z-index can be updated and affects hit testing', () {
      final node1 = createTestNode(
        id: 'node-1',
        position: const Offset(100, 100),
        size: const Size(100, 100),
        zIndex: 10,
      );
      final node2 = createTestNode(
        id: 'node-2',
        position: const Offset(100, 100),
        size: const Size(100, 100),
        zIndex: 5,
      );
      spatialIndex.update(node1);
      spatialIndex.update(node2);

      // Initially node-1 has higher z-index
      var result = spatialIndex.hitTest(const Offset(150, 150));
      expect(result.nodeId, equals('node-1'));

      // Update node-2 to have higher z-index
      node2.zIndex.value = 20;
      spatialIndex.update(node2);

      result = spatialIndex.hitTest(const Offset(150, 150));
      expect(result.nodeId, equals('node-2'));
    });

    test('multiple nodes at same z-index are handled consistently', () {
      final node1 = createTestNode(
        id: 'same-z-1',
        position: const Offset(100, 100),
        size: const Size(100, 100),
        zIndex: 5,
      );
      final node2 = createTestNode(
        id: 'same-z-2',
        position: const Offset(100, 100),
        size: const Size(100, 100),
        zIndex: 5,
      );
      spatialIndex.update(node1);
      spatialIndex.update(node2);

      final result = spatialIndex.hitTest(const Offset(150, 150));

      expect(result.hitType, equals(HitTarget.node));
      // Should hit one of them consistently
      expect(result.nodeId, anyOf(equals('same-z-1'), equals('same-z-2')));
    });
  });

  // ===========================================================================
  // Port Hit Testing With Overlapping Nodes Tests
  // ===========================================================================

  group('Port Hit Testing With Overlapping Nodes', () {
    late GraphSpatialIndex<String, dynamic> spatialIndex;

    setUp(() {
      spatialIndex = GraphSpatialIndex<String, dynamic>();
    });

    test(
      'port of lower z-index node covered by higher z-index node is not hit',
      () {
        // Create node with port at lower z-index
        final bottomNode = createTestNodeWithOutputPort(
          id: 'bottom-node',
          portId: 'covered-port',
          position: const Offset(100, 100),
        );
        bottomNode.setSize(const Size(100, 50));

        // Create covering node at higher z-index that overlaps the port area
        final coveringNode = createTestNode(
          id: 'covering-node',
          position: const Offset(180, 100), // Overlaps right side where port is
          size: const Size(100, 50),
          zIndex: 10,
        );

        spatialIndex.update(bottomNode);
        spatialIndex.update(coveringNode);

        // Get port center
        const portSize = Size.square(10);
        final portCenter = bottomNode.getPortCenter(
          'covered-port',
          portSize: portSize,
        );

        final result = spatialIndex.hitTest(portCenter);

        // Covering node should be hit instead of the port
        expect(result.hitType, equals(HitTarget.node));
        expect(result.nodeId, equals('covering-node'));
      },
    );

    test('port is hittable when not covered by other nodes', () {
      final nodeWithPort = createTestNodeWithOutputPort(
        id: 'port-node',
        portId: 'uncovered-port',
        position: const Offset(100, 100),
      );
      nodeWithPort.setSize(const Size(100, 50));

      // Create non-overlapping node
      final otherNode = createTestNode(
        id: 'other-node',
        position: const Offset(300, 100),
        size: const Size(100, 50),
      );

      spatialIndex.update(nodeWithPort);
      spatialIndex.update(otherNode);

      // Get port center
      const portSize = Size.square(10);
      final portCenter = nodeWithPort.getPortCenter(
        'uncovered-port',
        portSize: portSize,
      );

      final result = spatialIndex.hitTest(portCenter);

      expect(result.hitType, equals(HitTarget.port));
      expect(result.portId, equals('uncovered-port'));
    });

    test('port of higher z-index node is hit even when lower node nearby', () {
      // Lower z-index node
      final bottomNode = createTestNode(
        id: 'bottom-node',
        position: const Offset(100, 100),
        size: const Size(150, 50),
        zIndex: 1,
      );

      // Higher z-index node with port
      final topNode = createTestNodeWithOutputPort(
        id: 'top-node',
        portId: 'top-port',
        position: const Offset(120, 100),
      );
      topNode.setSize(const Size(100, 50));
      topNode.zIndex.value = 10;

      spatialIndex.update(bottomNode);
      spatialIndex.update(topNode);

      // Get port center of top node
      const portSize = Size.square(10);
      final portCenter = topNode.getPortCenter('top-port', portSize: portSize);

      final result = spatialIndex.hitTest(portCenter);

      expect(result.hitType, equals(HitTarget.port));
      expect(result.portId, equals('top-port'));
    });

    test('ports on hidden nodes are not hit', () {
      final hiddenNode = createTestNodeWithOutputPort(
        id: 'hidden-node',
        portId: 'hidden-port',
        position: const Offset(100, 100),
        visible: false,
      );
      hiddenNode.setSize(const Size(100, 50));

      spatialIndex.update(hiddenNode);

      // Get port center
      const portSize = Size.square(10);
      final portCenter = hiddenNode.getPortCenter(
        'hidden-port',
        portSize: portSize,
      );

      final result = spatialIndex.hitTest(portCenter);

      // Should not hit the port of hidden node
      expect(result.hitType, equals(HitTarget.canvas));
    });
  });

  // ===========================================================================
  // Edge Cases and Boundary Conditions
  // ===========================================================================

  group('Hit Testing Edge Cases', () {
    late GraphSpatialIndex<String, dynamic> spatialIndex;

    setUp(() {
      spatialIndex = GraphSpatialIndex<String, dynamic>();
    });

    test('hit testing at exact node boundary', () {
      final node = createTestNode(
        id: 'boundary-node',
        position: const Offset(100, 100),
        size: const Size(100, 50),
      );
      spatialIndex.update(node);

      // Test at exact top-left corner
      final topLeft = spatialIndex.hitTest(const Offset(100, 100));
      expect(topLeft.hitType, equals(HitTarget.node));

      // Test just outside top-left corner
      final outsideTopLeft = spatialIndex.hitTest(const Offset(99, 99));
      expect(outsideTopLeft.hitType, equals(HitTarget.canvas));
    });

    test('hit testing with negative coordinates', () {
      final node = createTestNode(
        id: 'negative-node',
        position: const Offset(-100, -100),
        size: const Size(50, 50),
      );
      spatialIndex.update(node);

      final result = spatialIndex.hitTest(const Offset(-75, -75));

      expect(result.hitType, equals(HitTarget.node));
      expect(result.nodeId, equals('negative-node'));
    });

    test('hit testing with zero-size node returns canvas', () {
      final node = createTestNode(
        id: 'zero-node',
        position: const Offset(100, 100),
        size: Size.zero,
      );
      spatialIndex.update(node);

      final result = spatialIndex.hitTest(const Offset(100, 100));

      // Zero-size node should not be hit
      expect(result.hitType, equals(HitTarget.canvas));
    });

    test('hit testing handles very large coordinates', () {
      final node = createTestNode(
        id: 'large-coord-node',
        position: const Offset(10000, 10000),
        size: const Size(100, 100),
      );
      spatialIndex.update(node);

      final result = spatialIndex.hitTest(const Offset(10050, 10050));

      expect(result.hitType, equals(HitTarget.node));
      expect(result.nodeId, equals('large-coord-node'));
    });

    test('spatial index handles rapid node updates', () {
      final node = createTestNode(
        id: 'rapid-update-node',
        position: const Offset(100, 100),
        size: const Size(100, 100),
      );
      spatialIndex.update(node);

      // Rapidly update node position
      for (var i = 0; i < 100; i++) {
        node.position.value = Offset(100.0 + i, 100.0 + i);
        spatialIndex.update(node);
      }

      // Final position should be (199, 199), so (250, 250) should be inside
      final result = spatialIndex.hitTest(const Offset(250, 250));

      expect(result.hitType, equals(HitTarget.node));
      expect(result.nodeId, equals('rapid-update-node'));
    });

    test('batch operations update spatial index correctly', () {
      spatialIndex.batch(() {
        for (var i = 0; i < 5; i++) {
          final node = createTestNode(
            id: 'batch-node-$i',
            position: Offset(i * 100.0, 0),
            size: const Size(50, 50),
          );
          spatialIndex.update(node);
        }
      });

      expect(spatialIndex.nodeCount, equals(5));

      // All nodes should be hittable
      for (var i = 0; i < 5; i++) {
        final result = spatialIndex.hitTest(Offset(i * 100.0 + 25, 25));
        expect(result.hitType, equals(HitTarget.node));
        expect(result.nodeId, equals('batch-node-$i'));
      }
    });
  });

  // ===========================================================================
  // Selection With Hit Testing Tests
  // ===========================================================================

  group('Selection Integration with Hit Testing', () {
    late GraphSpatialIndex<String, dynamic> spatialIndex;

    setUp(() {
      spatialIndex = GraphSpatialIndex<String, dynamic>();
    });

    test('selection rectangle selects nodes within bounds', () {
      final nodes = [
        createTestNode(
          id: 'inside-1',
          position: const Offset(50, 50),
          size: const Size(50, 50),
        ),
        createTestNode(
          id: 'inside-2',
          position: const Offset(100, 100),
          size: const Size(50, 50),
        ),
        createTestNode(
          id: 'outside',
          position: const Offset(500, 500),
          size: const Size(50, 50),
        ),
      ];
      for (final node in nodes) {
        spatialIndex.update(node);
      }

      // Get nodes in selection rectangle
      final selectedNodes = spatialIndex.nodesIn(
        const Rect.fromLTWH(0, 0, 200, 200),
      );

      expect(selectedNodes, hasLength(2));
      expect(
        selectedNodes.map((n) => n.id),
        containsAll(['inside-1', 'inside-2']),
      );
      expect(selectedNodes.map((n) => n.id), isNot(contains('outside')));
    });

    test('nodesIn handles partially overlapping nodes', () {
      final node = createTestNode(
        id: 'partial-node',
        position: const Offset(150, 150),
        size: const Size(100, 100),
      );
      spatialIndex.update(node);

      // Selection rect partially overlaps node
      final selectedNodes = spatialIndex.nodesIn(
        const Rect.fromLTWH(0, 0, 175, 175),
      );

      // Node should be included if any part overlaps
      expect(selectedNodes, hasLength(1));
      expect(selectedNodes.first.id, equals('partial-node'));
    });

    test('selection does not include hidden nodes', () {
      final visibleNode = createTestNode(
        id: 'visible-select',
        position: const Offset(50, 50),
        size: const Size(50, 50),
        visible: true,
      );
      final hiddenNode = createTestNode(
        id: 'hidden-select',
        position: const Offset(100, 100),
        size: const Size(50, 50),
        visible: false,
      );
      spatialIndex.update(visibleNode);
      spatialIndex.update(hiddenNode);

      final selectedNodes = spatialIndex.nodesIn(
        const Rect.fromLTWH(0, 0, 200, 200),
      );

      expect(selectedNodes, hasLength(1));
      expect(selectedNodes.first.id, equals('visible-select'));
    });
  });
}
