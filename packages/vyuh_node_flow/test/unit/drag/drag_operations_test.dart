/// Comprehensive tests for drag and drop functionality in vyuh_node_flow.
///
/// Tests cover:
/// 1. Node dragging - Single node drag operations
/// 2. Connection dragging - Creating connections via drag
/// 3. Multi-node dragging - Dragging multiple selected nodes
/// 4. Drag constraints - Snap-to-grid and other constraints
@Tags(['unit'])
library;

import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:vyuh_node_flow/vyuh_node_flow.dart';

import '../../helpers/test_factories.dart';

void main() {
  late NodeFlowController<String, dynamic> controller;

  setUp(() {
    resetTestCounters();
    controller = createTestController();
  });

  tearDown(() {
    controller.dispose();
  });

  // ===========================================================================
  // 1. Node Dragging Tests
  // ===========================================================================
  group('Node Dragging', () {
    group('startNodeDrag', () {
      test('sets draggedNodeId in interaction state', () {
        final node = createTestNode(id: 'node1');
        controller.addNode(node);

        controller.startNodeDrag('node1');

        expect(controller.interaction.draggedNodeId.value, equals('node1'));
      });

      test('sets node dragging state to true', () {
        final node = createTestNode(id: 'node1');
        controller.addNode(node);

        controller.startNodeDrag('node1');

        expect(node.dragging.value, isTrue);
      });

      test('selects node if not already selected', () {
        final node = createTestNode(id: 'node1');
        controller.addNode(node);
        expect(controller.selectedNodeIds, isEmpty);

        controller.startNodeDrag('node1');

        expect(controller.selectedNodeIds, contains('node1'));
      });

      test('does not clear existing selection if node is already selected', () {
        final node1 = createTestNode(id: 'node1');
        final node2 = createTestNode(id: 'node2');
        controller.addNode(node1);
        controller.addNode(node2);

        // Multi-select both nodes
        controller.selectNode('node1');
        controller.selectNode('node2', toggle: true);
        expect(controller.selectedNodeIds.length, equals(2));

        // Start drag on already selected node
        controller.startNodeDrag('node1');

        // Multi-selection should be preserved
        expect(controller.selectedNodeIds.length, equals(2));
        expect(controller.selectedNodeIds, containsAll(['node1', 'node2']));
      });

      test('clears existing selection when dragging unselected node', () {
        final node1 = createTestNode(id: 'node1');
        final node2 = createTestNode(id: 'node2');
        controller.addNode(node1);
        controller.addNode(node2);

        // Select node2 first
        controller.selectNode('node2');
        expect(controller.selectedNodeIds, equals({'node2'}));

        // Start drag on unselected node1
        controller.startNodeDrag('node1');

        // Selection should change to node1 only
        expect(controller.selectedNodeIds, equals({'node1'}));
      });

      test('brings node to front (increases z-index)', () {
        final node1 = createTestNode(id: 'node1');
        final node2 = createTestNode(id: 'node2');
        controller.addNode(node1);
        controller.addNode(node2);

        final initialZIndex = node1.zIndex.value;

        controller.startNodeDrag('node1');

        expect(node1.zIndex.value, greaterThan(initialZIndex));
      });

      test('fires onDragStart callback', () {
        final node = createTestNode(id: 'node1');
        controller.addNode(node);

        Node<String>? draggedNode;
        controller.updateEvents(
          NodeFlowEvents<String, dynamic>(
            node: NodeEvents<String>(
              onDragStart: (n) {
                draggedNode = n;
              },
            ),
          ),
        );

        controller.startNodeDrag('node1');

        expect(draggedNode?.id, equals('node1'));
      });

      test('sets dragging state on all selected nodes for multi-drag', () {
        final node1 = createTestNode(id: 'node1');
        final node2 = createTestNode(id: 'node2');
        final node3 = createTestNode(id: 'node3');
        controller.addNode(node1);
        controller.addNode(node2);
        controller.addNode(node3);

        // Select multiple nodes
        controller.selectNode('node1');
        controller.selectNode('node2', toggle: true);

        controller.startNodeDrag('node1');

        expect(node1.dragging.value, isTrue);
        expect(node2.dragging.value, isTrue);
        expect(node3.dragging.value, isFalse);
      });

      test('handles non-existent node gracefully', () {
        expect(() => controller.startNodeDrag('non-existent'), returnsNormally);
        expect(
          controller.interaction.draggedNodeId.value,
          equals('non-existent'),
        );
      });
    });

    group('moveNodeDrag', () {
      test('updates node position by delta', () {
        final node = createTestNode(
          id: 'node1',
          position: const Offset(100, 100),
        );
        controller.addNode(node);
        controller.startNodeDrag('node1');

        controller.moveNodeDrag(const Offset(50, 30));

        expect(node.position.value, equals(const Offset(150, 130)));
      });

      test('updates visual position', () {
        final node = createTestNode(
          id: 'node1',
          position: const Offset(100, 100),
        );
        controller.addNode(node);
        controller.startNodeDrag('node1');

        controller.moveNodeDrag(const Offset(50, 30));

        expect(node.visualPosition.value, equals(const Offset(150, 130)));
      });

      test('fires onDrag callback', () {
        final node = createTestNode(
          id: 'node1',
          position: const Offset(100, 100),
        );
        controller.addNode(node);

        Node<String>? movedNode;
        controller.updateEvents(
          NodeFlowEvents<String, dynamic>(
            node: NodeEvents<String>(
              onDrag: (n) {
                movedNode = n;
              },
            ),
          ),
        );

        controller.startNodeDrag('node1');
        controller.moveNodeDrag(const Offset(50, 30));

        expect(movedNode?.id, equals('node1'));
      });

      test('does nothing without active drag', () {
        final node = createTestNode(
          id: 'node1',
          position: const Offset(100, 100),
        );
        controller.addNode(node);

        // Don't call startNodeDrag
        controller.moveNodeDrag(const Offset(50, 30));

        expect(node.position.value, equals(const Offset(100, 100)));
      });

      test('accumulates multiple movements', () {
        final node = createTestNode(id: 'node1', position: Offset.zero);
        controller.addNode(node);
        controller.startNodeDrag('node1');

        controller.moveNodeDrag(const Offset(10, 10));
        controller.moveNodeDrag(const Offset(20, 20));
        controller.moveNodeDrag(const Offset(30, 30));

        expect(node.position.value, equals(const Offset(60, 60)));
      });

      test('handles negative deltas', () {
        final node = createTestNode(
          id: 'node1',
          position: const Offset(100, 100),
        );
        controller.addNode(node);
        controller.startNodeDrag('node1');

        controller.moveNodeDrag(const Offset(-50, -30));

        expect(node.position.value, equals(const Offset(50, 70)));
      });

      test('handles zero delta', () {
        final node = createTestNode(
          id: 'node1',
          position: const Offset(50, 50),
        );
        controller.addNode(node);
        controller.startNodeDrag('node1');

        controller.moveNodeDrag(Offset.zero);

        expect(node.position.value, equals(const Offset(50, 50)));
      });

      test('handles very large deltas', () {
        final node = createTestNode(id: 'node1', position: Offset.zero);
        controller.addNode(node);
        controller.startNodeDrag('node1');

        controller.moveNodeDrag(const Offset(10000, 10000));

        expect(node.position.value, equals(const Offset(10000, 10000)));
      });

      test('allows negative coordinates', () {
        final node = createTestNode(id: 'node1', position: Offset.zero);
        controller.addNode(node);
        controller.startNodeDrag('node1');

        controller.moveNodeDrag(const Offset(-500, -300));

        expect(node.position.value, equals(const Offset(-500, -300)));
      });
    });

    group('endNodeDrag', () {
      test('clears node dragging state', () {
        final node = createTestNode(id: 'node1');
        controller.addNode(node);
        controller.startNodeDrag('node1');
        expect(node.dragging.value, isTrue);

        controller.endNodeDrag();

        expect(node.dragging.value, isFalse);
      });

      test('clears draggedNodeId', () {
        final node = createTestNode(id: 'node1');
        controller.addNode(node);
        controller.startNodeDrag('node1');
        expect(controller.interaction.draggedNodeId.value, isNotNull);

        controller.endNodeDrag();

        expect(controller.interaction.draggedNodeId.value, isNull);
      });

      test('fires onDragStop callback', () {
        final node = createTestNode(id: 'node1');
        controller.addNode(node);

        Node<String>? stoppedNode;
        controller.updateEvents(
          NodeFlowEvents<String, dynamic>(
            node: NodeEvents<String>(
              onDragStop: (n) {
                stoppedNode = n;
              },
            ),
          ),
        );

        controller.startNodeDrag('node1');
        controller.endNodeDrag();

        expect(stoppedNode?.id, equals('node1'));
      });

      test('fires onDragStop for all dragged nodes in multi-drag', () {
        final node1 = createTestNode(id: 'node1');
        final node2 = createTestNode(id: 'node2');
        controller.addNode(node1);
        controller.addNode(node2);

        final stoppedNodeIds = <String>[];
        controller.updateEvents(
          NodeFlowEvents<String, dynamic>(
            node: NodeEvents<String>(
              onDragStop: (n) {
                stoppedNodeIds.add(n.id);
              },
            ),
          ),
        );

        controller.selectNode('node1');
        controller.selectNode('node2', toggle: true);
        controller.startNodeDrag('node1');
        controller.endNodeDrag();

        expect(stoppedNodeIds, containsAll(['node1', 'node2']));
      });

      test('does nothing without active drag', () {
        final node = createTestNode(id: 'node1');
        controller.addNode(node);

        expect(() => controller.endNodeDrag(), returnsNormally);
      });

      test('multiple endNodeDrag calls are safe', () {
        final node = createTestNode(id: 'node1');
        controller.addNode(node);
        controller.startNodeDrag('node1');

        controller.endNodeDrag();
        expect(() => controller.endNodeDrag(), returnsNormally);
        expect(() => controller.endNodeDrag(), returnsNormally);
      });

      test('preserves final position after drag end', () {
        final node = createTestNode(id: 'node1', position: Offset.zero);
        controller.addNode(node);
        controller.startNodeDrag('node1');
        controller.moveNodeDrag(const Offset(100, 50));
        controller.endNodeDrag();

        expect(node.position.value, equals(const Offset(100, 50)));
      });
    });

    group('cancelNodeDrag', () {
      test('reverts positions to original values', () {
        final node = createTestNode(
          id: 'node1',
          position: const Offset(100, 100),
        );
        controller.addNode(node);
        controller.startNodeDrag('node1');
        controller.moveNodeDrag(const Offset(50, 50));

        controller.cancelNodeDrag({'node1': const Offset(100, 100)});

        expect(node.position.value, equals(const Offset(100, 100)));
      });

      test('clears dragging state on cancel', () {
        final node = createTestNode(id: 'node1');
        controller.addNode(node);
        controller.startNodeDrag('node1');
        expect(node.dragging.value, isTrue);

        controller.cancelNodeDrag({'node1': Offset.zero});

        expect(node.dragging.value, isFalse);
      });

      test('fires onDragCancel callback', () {
        final node = createTestNode(id: 'node1');
        controller.addNode(node);

        Node<String>? cancelledNode;
        controller.updateEvents(
          NodeFlowEvents<String, dynamic>(
            node: NodeEvents<String>(
              onDragCancel: (n) {
                cancelledNode = n;
              },
            ),
          ),
        );

        controller.startNodeDrag('node1');
        controller.cancelNodeDrag({'node1': Offset.zero});

        expect(cancelledNode?.id, equals('node1'));
      });
    });
  });

  // ===========================================================================
  // 2. Connection Dragging Tests
  // ===========================================================================
  group('Connection Dragging', () {
    group('startConnectionDrag', () {
      test('creates temporary connection', () {
        final node = createTestNodeWithOutputPort(id: 'node1', portId: 'out1');
        controller.addNode(node);

        final result = controller.startConnectionDrag(
          nodeId: 'node1',
          portId: 'out1',
          isOutput: true,
          startPoint: Offset.zero,
          nodeBounds: Rect.zero,
        );

        expect(result.allowed, isTrue);
        expect(controller.temporaryConnection, isNotNull);
        expect(controller.temporaryConnection?.startNodeId, equals('node1'));
        expect(controller.temporaryConnection?.startPortId, equals('out1'));
      });

      test('validates that port exists', () {
        final node = createTestNode(id: 'node1');
        controller.addNode(node);

        final result = controller.startConnectionDrag(
          nodeId: 'node1',
          portId: 'non-existent',
          isOutput: true,
          startPoint: Offset.zero,
          nodeBounds: Rect.zero,
        );

        expect(result.allowed, isFalse);
        expect(result.reason, contains('Port not found'));
      });

      test('validates that node exists', () {
        final result = controller.startConnectionDrag(
          nodeId: 'non-existent',
          portId: 'port1',
          isOutput: true,
          startPoint: Offset.zero,
          nodeBounds: Rect.zero,
        );

        expect(result.allowed, isFalse);
        expect(result.reason, contains('Node not found'));
      });

      test('fires onConnectStart callback', () {
        final node = createTestNodeWithOutputPort(id: 'node1', portId: 'out1');
        controller.addNode(node);

        Node<String>? startNode;
        Port? startPort;
        controller.updateEvents(
          NodeFlowEvents<String, dynamic>(
            connection: ConnectionEvents(
              onConnectStart: (n, p) {
                startNode = n;
                startPort = p;
              },
            ),
          ),
        );

        controller.startConnectionDrag(
          nodeId: 'node1',
          portId: 'out1',
          isOutput: true,
          startPoint: Offset.zero,
          nodeBounds: Rect.zero,
        );

        expect(startNode?.id, equals('node1'));
        expect(startPort?.id, equals('out1'));
      });

      test('respects behavior mode - denies when canCreate is false', () {
        final node = createTestNodeWithOutputPort(id: 'node1', portId: 'out1');
        controller.addNode(node);
        controller.setBehavior(NodeFlowBehavior.present);

        final result = controller.startConnectionDrag(
          nodeId: 'node1',
          portId: 'out1',
          isOutput: true,
          startPoint: Offset.zero,
          nodeBounds: Rect.zero,
        );

        expect(result.allowed, isFalse);
      });

      test('validates port direction - output must be output', () {
        final node = createTestNodeWithInputPort(id: 'node1', portId: 'in1');
        controller.addNode(node);

        final result = controller.startConnectionDrag(
          nodeId: 'node1',
          portId: 'in1',
          isOutput: true, // Claiming it's output but it's actually input
          startPoint: Offset.zero,
          nodeBounds: Rect.zero,
        );

        expect(result.allowed, isFalse);
      });

      test('allows starting from input port', () {
        final node = createTestNodeWithInputPort(id: 'node1', portId: 'in1');
        controller.addNode(node);

        final result = controller.startConnectionDrag(
          nodeId: 'node1',
          portId: 'in1',
          isOutput: false,
          startPoint: Offset.zero,
          nodeBounds: Rect.zero,
        );

        expect(result.allowed, isTrue);
        expect(controller.temporaryConnection?.isStartFromOutput, isFalse);
      });
    });

    group('updateConnectionDrag', () {
      test('updates temporary connection current point', () {
        final node = createTestNodeWithOutputPort(id: 'node1', portId: 'out1');
        controller.addNode(node);
        controller.startConnectionDrag(
          nodeId: 'node1',
          portId: 'out1',
          isOutput: true,
          startPoint: Offset.zero,
          nodeBounds: Rect.zero,
        );

        controller.updateConnectionDrag(graphPosition: const Offset(100, 100));

        expect(
          controller.temporaryConnection?.currentPoint,
          equals(const Offset(100, 100)),
        );
      });

      test('validates target port during drag', () {
        final source = createTestNodeWithOutputPort(
          id: 'source',
          portId: 'out1',
        );
        final target = createTestNodeWithInputPort(
          id: 'target',
          portId: 'in1',
          position: const Offset(200, 0),
        );
        controller.addNode(source);
        controller.addNode(target);

        controller.startConnectionDrag(
          nodeId: 'source',
          portId: 'out1',
          isOutput: true,
          startPoint: Offset.zero,
          nodeBounds: Rect.zero,
        );

        controller.updateConnectionDrag(
          graphPosition: const Offset(200, 50),
          targetNodeId: 'target',
          targetPortId: 'in1',
        );

        expect(controller.temporaryConnection?.targetNodeId, equals('target'));
        expect(controller.temporaryConnection?.targetPortId, equals('in1'));
      });

      test('rejects invalid target during drag', () {
        final source = createTestNodeWithOutputPort(
          id: 'source',
          portId: 'out1',
        );
        final target = createTestNodeWithOutputPort(
          id: 'target',
          portId: 'out2', // Another output - invalid target
          position: const Offset(200, 0),
        );
        controller.addNode(source);
        controller.addNode(target);

        controller.startConnectionDrag(
          nodeId: 'source',
          portId: 'out1',
          isOutput: true,
          startPoint: Offset.zero,
          nodeBounds: Rect.zero,
        );

        controller.updateConnectionDrag(
          graphPosition: const Offset(200, 50),
          targetNodeId: 'target',
          targetPortId: 'out2',
        );

        // Should NOT accept output-to-output connection
        expect(controller.temporaryConnection?.targetNodeId, isNull);
      });
    });

    group('canConnect', () {
      test('allows valid output-to-input connection', () {
        final source = createTestNodeWithOutputPort(
          id: 'source',
          portId: 'out1',
        );
        final target = createTestNodeWithInputPort(id: 'target', portId: 'in1');
        controller.addNode(source);
        controller.addNode(target);

        controller.startConnectionDrag(
          nodeId: 'source',
          portId: 'out1',
          isOutput: true,
          startPoint: Offset.zero,
          nodeBounds: Rect.zero,
        );

        final result = controller.canConnect(
          targetNodeId: 'target',
          targetPortId: 'in1',
        );

        expect(result.allowed, isTrue);
      });

      test('prevents self-connection', () {
        final node = createTestNodeWithPorts(
          id: 'node1',
          inputPortId: 'in1',
          outputPortId: 'out1',
        );
        controller.addNode(node);

        controller.startConnectionDrag(
          nodeId: 'node1',
          portId: 'out1',
          isOutput: true,
          startPoint: Offset.zero,
          nodeBounds: Rect.zero,
        );

        final result = controller.canConnect(
          targetNodeId: 'node1',
          targetPortId: 'out1',
        );

        expect(result.allowed, isFalse);
        expect(result.reason, contains('itself'));
      });

      test('prevents output-to-output connection', () {
        final source = createTestNodeWithOutputPort(
          id: 'source',
          portId: 'out1',
        );
        final target = createTestNodeWithOutputPort(
          id: 'target',
          portId: 'out2',
        );
        controller.addNode(source);
        controller.addNode(target);

        controller.startConnectionDrag(
          nodeId: 'source',
          portId: 'out1',
          isOutput: true,
          startPoint: Offset.zero,
          nodeBounds: Rect.zero,
        );

        final result = controller.canConnect(
          targetNodeId: 'target',
          targetPortId: 'out2',
        );

        expect(result.allowed, isFalse);
        expect(result.reason, contains('output to output'));
      });

      test('prevents input-to-input connection', () {
        final source = createTestNodeWithInputPort(id: 'source', portId: 'in1');
        final target = createTestNodeWithInputPort(id: 'target', portId: 'in2');
        controller.addNode(source);
        controller.addNode(target);

        controller.startConnectionDrag(
          nodeId: 'source',
          portId: 'in1',
          isOutput: false,
          startPoint: Offset.zero,
          nodeBounds: Rect.zero,
        );

        final result = controller.canConnect(
          targetNodeId: 'target',
          targetPortId: 'in2',
        );

        expect(result.allowed, isFalse);
        expect(result.reason, contains('input to input'));
      });

      test('prevents duplicate connections', () {
        // Create nodes with ports that allow multiple connections
        // so the existing connection isn't removed on startConnectionDrag
        final source = createTestNode(
          id: 'source',
          outputPorts: [
            createTestPort(
              id: 'out1',
              type: PortType.output,
              multiConnections: true,
            ),
          ],
        );
        final target = createTestNode(
          id: 'target',
          inputPorts: [
            createTestPort(
              id: 'in1',
              type: PortType.input,
              multiConnections: true,
            ),
          ],
        );
        controller.addNode(source);
        controller.addNode(target);

        // Create existing connection
        final connection = createTestConnection(
          sourceNodeId: 'source',
          sourcePortId: 'out1',
          targetNodeId: 'target',
          targetPortId: 'in1',
        );
        controller.addConnection(connection);

        controller.startConnectionDrag(
          nodeId: 'source',
          portId: 'out1',
          isOutput: true,
          startPoint: Offset.zero,
          nodeBounds: Rect.zero,
        );

        final result = controller.canConnect(
          targetNodeId: 'target',
          targetPortId: 'in1',
        );

        expect(result.allowed, isFalse);
        expect(result.reason, contains('already exists'));
      });
    });

    group('completeConnectionDrag', () {
      test('creates connection on valid target', () {
        final source = createTestNodeWithOutputPort(
          id: 'source',
          portId: 'out1',
        );
        final target = createTestNodeWithInputPort(id: 'target', portId: 'in1');
        controller.addNode(source);
        controller.addNode(target);

        controller.startConnectionDrag(
          nodeId: 'source',
          portId: 'out1',
          isOutput: true,
          startPoint: Offset.zero,
          nodeBounds: Rect.zero,
        );

        final connection = controller.completeConnectionDrag(
          targetNodeId: 'target',
          targetPortId: 'in1',
        );

        expect(connection, isNotNull);
        expect(connection?.sourceNodeId, equals('source'));
        expect(connection?.targetNodeId, equals('target'));
        expect(controller.connectionCount, equals(1));
      });

      test('clears temporary connection after completion', () {
        final source = createTestNodeWithOutputPort(
          id: 'source',
          portId: 'out1',
        );
        final target = createTestNodeWithInputPort(id: 'target', portId: 'in1');
        controller.addNode(source);
        controller.addNode(target);

        controller.startConnectionDrag(
          nodeId: 'source',
          portId: 'out1',
          isOutput: true,
          startPoint: Offset.zero,
          nodeBounds: Rect.zero,
        );
        controller.completeConnectionDrag(
          targetNodeId: 'target',
          targetPortId: 'in1',
        );

        expect(controller.temporaryConnection, isNull);
      });

      test('returns null for invalid target', () {
        final source = createTestNodeWithOutputPort(
          id: 'source',
          portId: 'out1',
        );
        final target = createTestNodeWithOutputPort(
          id: 'target',
          portId: 'out2',
        );
        controller.addNode(source);
        controller.addNode(target);

        controller.startConnectionDrag(
          nodeId: 'source',
          portId: 'out1',
          isOutput: true,
          startPoint: Offset.zero,
          nodeBounds: Rect.zero,
        );

        final connection = controller.completeConnectionDrag(
          targetNodeId: 'target',
          targetPortId: 'out2',
        );

        expect(connection, isNull);
        expect(controller.connectionCount, equals(0));
      });

      test('fires onConnectEnd callback with connection details', () {
        final source = createTestNodeWithOutputPort(
          id: 'source',
          portId: 'out1',
        );
        final target = createTestNodeWithInputPort(id: 'target', portId: 'in1');
        controller.addNode(source);
        controller.addNode(target);

        Node<String>? endNode;
        Port? endPort;
        controller.updateEvents(
          NodeFlowEvents<String, dynamic>(
            connection: ConnectionEvents(
              onConnectEnd: (n, p, pos) {
                endNode = n;
                endPort = p;
              },
            ),
          ),
        );

        controller.startConnectionDrag(
          nodeId: 'source',
          portId: 'out1',
          isOutput: true,
          startPoint: Offset.zero,
          nodeBounds: Rect.zero,
        );
        controller.completeConnectionDrag(
          targetNodeId: 'target',
          targetPortId: 'in1',
        );

        expect(endNode?.id, equals('target'));
        expect(endPort?.id, equals('in1'));
      });
    });

    group('cancelConnectionDrag', () {
      test('clears temporary connection', () {
        final node = createTestNodeWithOutputPort(id: 'node1', portId: 'out1');
        controller.addNode(node);
        controller.startConnectionDrag(
          nodeId: 'node1',
          portId: 'out1',
          isOutput: true,
          startPoint: Offset.zero,
          nodeBounds: Rect.zero,
        );

        expect(controller.temporaryConnection, isNotNull);

        controller.cancelConnectionDrag();

        expect(controller.temporaryConnection, isNull);
      });

      test('fires onConnectEnd callback with null values', () {
        final node = createTestNodeWithOutputPort(id: 'node1', portId: 'out1');
        controller.addNode(node);

        bool callbackCalled = false;
        Node<String>? endNode;
        Port? endPort;
        controller.updateEvents(
          NodeFlowEvents<String, dynamic>(
            connection: ConnectionEvents(
              onConnectEnd: (n, p, pos) {
                callbackCalled = true;
                endNode = n;
                endPort = p;
              },
            ),
          ),
        );

        controller.startConnectionDrag(
          nodeId: 'node1',
          portId: 'out1',
          isOutput: true,
          startPoint: Offset.zero,
          nodeBounds: Rect.zero,
        );
        controller.cancelConnectionDrag();

        expect(callbackCalled, isTrue);
        expect(endNode, isNull);
        expect(endPort, isNull);
      });

      test('resets highlighted port state', () {
        final source = createTestNodeWithOutputPort(
          id: 'source',
          portId: 'out1',
        );
        final target = createTestNodeWithInputPort(id: 'target', portId: 'in1');
        controller.addNode(source);
        controller.addNode(target);

        controller.startConnectionDrag(
          nodeId: 'source',
          portId: 'out1',
          isOutput: true,
          startPoint: Offset.zero,
          nodeBounds: Rect.zero,
        );

        // Update to hover over target
        controller.updateConnectionDrag(
          graphPosition: const Offset(100, 0),
          targetNodeId: 'target',
          targetPortId: 'in1',
        );

        // The target port should be highlighted
        final targetPort = controller.getPort('target', 'in1');
        expect(targetPort?.highlighted.value, isTrue);

        controller.cancelConnectionDrag();

        // Port should no longer be highlighted
        expect(targetPort?.highlighted.value, isFalse);
      });
    });
  });

  // ===========================================================================
  // 3. Multi-Node Dragging Tests
  // ===========================================================================
  group('Multi-Node Dragging', () {
    test('moves all selected nodes together', () {
      final node1 = createTestNode(
        id: 'node1',
        position: const Offset(100, 100),
      );
      final node2 = createTestNode(
        id: 'node2',
        position: const Offset(200, 200),
      );
      final node3 = createTestNode(
        id: 'node3',
        position: const Offset(300, 300),
      );
      controller.addNode(node1);
      controller.addNode(node2);
      controller.addNode(node3);

      // Select first two nodes
      controller.selectNode('node1');
      controller.selectNode('node2', toggle: true);

      // Start drag from node1
      controller.startNodeDrag('node1');
      controller.moveNodeDrag(const Offset(50, 50));

      // Both selected nodes should move
      expect(node1.position.value, equals(const Offset(150, 150)));
      expect(node2.position.value, equals(const Offset(250, 250)));
      // Unselected node should not move
      expect(node3.position.value, equals(const Offset(300, 300)));
    });

    test('fires onDrag callback for each moved node', () {
      final node1 = createTestNode(id: 'node1', position: Offset.zero);
      final node2 = createTestNode(id: 'node2', position: const Offset(100, 0));
      controller.addNode(node1);
      controller.addNode(node2);

      final movedNodeIds = <String>[];
      controller.updateEvents(
        NodeFlowEvents<String, dynamic>(
          node: NodeEvents<String>(
            onDrag: (n) {
              movedNodeIds.add(n.id);
            },
          ),
        ),
      );

      controller.selectNode('node1');
      controller.selectNode('node2', toggle: true);
      controller.startNodeDrag('node1');
      controller.moveNodeDrag(const Offset(25, 25));

      expect(movedNodeIds, containsAll(['node1', 'node2']));
    });

    test('clears dragging state on all nodes when drag ends', () {
      final node1 = createTestNode(id: 'node1');
      final node2 = createTestNode(id: 'node2');
      controller.addNode(node1);
      controller.addNode(node2);

      controller.selectNode('node1');
      controller.selectNode('node2', toggle: true);
      controller.startNodeDrag('node1');

      expect(node1.dragging.value, isTrue);
      expect(node2.dragging.value, isTrue);

      controller.endNodeDrag();

      expect(node1.dragging.value, isFalse);
      expect(node2.dragging.value, isFalse);
    });

    test('maintains relative positions during multi-drag', () {
      final node1 = createTestNode(id: 'node1', position: const Offset(0, 0));
      final node2 = createTestNode(
        id: 'node2',
        position: const Offset(100, 50),
      );
      controller.addNode(node1);
      controller.addNode(node2);

      controller.selectNode('node1');
      controller.selectNode('node2', toggle: true);
      controller.startNodeDrag('node1');
      controller.moveNodeDrag(const Offset(200, 300));
      controller.endNodeDrag();

      // Check that relative positions are maintained
      final relativeOffset = node2.position.value - node1.position.value;
      expect(relativeOffset, equals(const Offset(100, 50)));
    });

    test('large multi-node drag works correctly', () {
      // Create a grid of nodes
      final nodes = createNodeGrid(rows: 5, cols: 5);
      for (final node in nodes) {
        controller.addNode(node);
      }

      // Select all nodes
      for (final node in nodes) {
        controller.selectNode(node.id, toggle: true);
      }

      // Drag all nodes
      controller.startNodeDrag(nodes.first.id);
      controller.moveNodeDrag(const Offset(500, 500));
      controller.endNodeDrag();

      // All nodes should have moved by the same delta
      for (int i = 0; i < nodes.length; i++) {
        final row = i ~/ 5;
        final col = i % 5;
        final expectedX = col * 200.0 + 500;
        final expectedY = row * 150.0 + 500;
        expect(nodes[i].position.value, equals(Offset(expectedX, expectedY)));
      }
    });
  });

  // ===========================================================================
  // 4. Drag Constraints Tests
  // ===========================================================================
  group('Drag Constraints', () {
    group('Snap-to-Grid', () {
      test('snaps position to grid when enabled', () {
        final config = NodeFlowConfig(
          plugins: [
            SnapPlugin([GridSnapDelegate(gridSize: 20.0)], enabled: true),
          ],
        );
        controller = createTestController(config: config);

        final node = createTestNode(
          id: 'node1',
          position: const Offset(100, 100),
        );
        controller.addNode(node);
        controller.startNodeDrag('node1');

        // Move by 13 pixels - should snap to nearest 20-pixel grid
        controller.moveNodeDrag(const Offset(13, 17));

        // 100 + 13 = 113, snaps to 120
        // 100 + 17 = 117, snaps to 120
        expect(node.visualPosition.value, equals(const Offset(120, 120)));
      });

      test('does not snap when snap-to-grid is disabled', () {
        final config = NodeFlowConfig(
          plugins: [], // No snap extension = no grid snapping
        );
        controller = createTestController(config: config);

        final node = createTestNode(
          id: 'node1',
          position: const Offset(100, 100),
        );
        controller.addNode(node);
        controller.startNodeDrag('node1');

        controller.moveNodeDrag(const Offset(13, 17));

        expect(node.visualPosition.value, equals(const Offset(113, 117)));
      });

      test('respects grid size configuration', () {
        final config = NodeFlowConfig(
          plugins: [
            SnapPlugin([GridSnapDelegate(gridSize: 16.0)], enabled: true),
          ],
        );
        controller = createTestController(config: config);

        final node = createTestNode(id: 'node1', position: Offset.zero);
        controller.addNode(node);
        controller.startNodeDrag('node1');

        // Move by 10 pixels - should snap to 16
        controller.moveNodeDrag(const Offset(10, 10));

        expect(node.visualPosition.value, equals(const Offset(16, 16)));
      });

      test('snapping works with negative coordinates', () {
        final config = NodeFlowConfig(
          plugins: [
            SnapPlugin([GridSnapDelegate(gridSize: 20.0)], enabled: true),
          ],
        );
        controller = createTestController(config: config);

        final node = createTestNode(id: 'node1', position: Offset.zero);
        controller.addNode(node);
        controller.startNodeDrag('node1');

        controller.moveNodeDrag(const Offset(-33, -47));

        // -33 should snap to -40, -47 should snap to -40
        expect(node.visualPosition.value, equals(const Offset(-40, -40)));
      });

      test('actual position differs from visual position when snapping', () {
        final config = NodeFlowConfig(
          plugins: [
            SnapPlugin([GridSnapDelegate(gridSize: 20.0)], enabled: true),
          ],
        );
        controller = createTestController(config: config);

        final node = createTestNode(id: 'node1', position: Offset.zero);
        controller.addNode(node);
        controller.startNodeDrag('node1');

        controller.moveNodeDrag(const Offset(33, 47));

        // Actual position is unsnapped
        expect(node.position.value, equals(const Offset(33, 47)));
        // Visual position is snapped
        expect(node.visualPosition.value, equals(const Offset(40, 40)));
      });

      test('snapping preserves multi-node relative positions', () {
        final config = NodeFlowConfig(
          plugins: [
            SnapPlugin([GridSnapDelegate(gridSize: 20.0)], enabled: true),
          ],
        );
        controller = createTestController(config: config);

        final node1 = createTestNode(id: 'node1', position: const Offset(0, 0));
        final node2 = createTestNode(
          id: 'node2',
          position: const Offset(50, 30),
        );
        controller.addNode(node1);
        controller.addNode(node2);

        controller.selectNode('node1');
        controller.selectNode('node2', toggle: true);
        controller.startNodeDrag('node1');
        controller.moveNodeDrag(const Offset(5, 5));

        // Both should snap, but maintain relative offset
        // node1: 0+5=5 snaps to 0
        // node2: 50+5=55 snaps to 60, 30+5=35 snaps to 40
        expect(node1.visualPosition.value, equals(const Offset(0, 0)));
        expect(node2.visualPosition.value, equals(const Offset(60, 40)));
      });
    });

    group('Canvas Lock State', () {
      test('canvas is initially unlocked', () {
        expect(controller.canvasLocked, isFalse);
      });

      test('canvas lock can be controlled via interaction state', () {
        expect(controller.canvasLocked, isFalse);

        // Lock via interaction state (normally done by DragSession)
        controller.interaction.canvasLocked.value = true;
        expect(controller.canvasLocked, isTrue);

        // Unlock
        controller.interaction.canvasLocked.value = false;
        expect(controller.canvasLocked, isFalse);
      });

      test('node drag does not lock canvas by itself (session required)', () {
        final node = createTestNode(id: 'node1');
        controller.addNode(node);

        controller.startNodeDrag('node1');

        // Canvas is NOT locked by startNodeDrag - session handles this
        expect(controller.canvasLocked, isFalse);
      });

      test('connection drag does not lock canvas by itself', () {
        final node = createTestNodeWithOutputPort(id: 'node1', portId: 'out1');
        controller.addNode(node);

        controller.startConnectionDrag(
          nodeId: 'node1',
          portId: 'out1',
          isOutput: true,
          startPoint: Offset.zero,
          nodeBounds: Rect.zero,
        );

        // Canvas is NOT locked by startConnectionDrag - session handles this
        expect(controller.canvasLocked, isFalse);
      });

      test('endNodeDrag does not modify canvas lock state', () {
        final node = createTestNode(id: 'node1');
        controller.addNode(node);
        controller.startNodeDrag('node1');

        // Manually lock canvas to simulate DragSession behavior
        controller.interaction.canvasLocked.value = true;

        controller.endNodeDrag();

        // Canvas lock state unchanged - session handles unlocking
        expect(controller.canvasLocked, isTrue);
      });
    });
  });

  // ===========================================================================
  // Complete Drag Sequence Tests
  // ===========================================================================
  group('Complete Drag Sequences', () {
    test('full node drag sequence: start -> move -> end', () {
      final node = createTestNode(id: 'node1', position: Offset.zero);
      controller.addNode(node);

      controller.startNodeDrag('node1');
      expect(node.dragging.value, isTrue);

      controller.moveNodeDrag(const Offset(100, 50));
      expect(node.position.value, equals(const Offset(100, 50)));

      controller.endNodeDrag();
      expect(node.dragging.value, isFalse);
      expect(node.position.value, equals(const Offset(100, 50)));
    });

    test('events fire in correct order during drag sequence', () {
      final node = createTestNode(id: 'node1', position: Offset.zero);
      controller.addNode(node);

      final events = <String>[];
      controller.updateEvents(
        NodeFlowEvents<String, dynamic>(
          node: NodeEvents<String>(
            onDragStart: (n) => events.add('start'),
            onDrag: (n) => events.add('drag'),
            onDragStop: (n) => events.add('stop'),
          ),
        ),
      );

      controller.startNodeDrag('node1');
      controller.moveNodeDrag(const Offset(10, 10));
      controller.moveNodeDrag(const Offset(10, 10));
      controller.endNodeDrag();

      expect(events, equals(['start', 'drag', 'drag', 'stop']));
    });

    test('multiple sequential drags work correctly', () {
      final node = createTestNode(id: 'node1', position: Offset.zero);
      controller.addNode(node);

      // First drag
      controller.startNodeDrag('node1');
      controller.moveNodeDrag(const Offset(100, 100));
      controller.endNodeDrag();
      expect(node.position.value, equals(const Offset(100, 100)));

      // Second drag
      controller.startNodeDrag('node1');
      controller.moveNodeDrag(const Offset(50, 50));
      controller.endNodeDrag();
      expect(node.position.value, equals(const Offset(150, 150)));
    });

    test('dragging different nodes sequentially', () {
      final node1 = createTestNode(id: 'node1', position: Offset.zero);
      final node2 = createTestNode(
        id: 'node2',
        position: const Offset(100, 100),
      );
      controller.addNode(node1);
      controller.addNode(node2);

      // Drag first node
      controller.startNodeDrag('node1');
      controller.moveNodeDrag(const Offset(50, 50));
      controller.endNodeDrag();

      // Drag second node
      controller.startNodeDrag('node2');
      controller.moveNodeDrag(const Offset(25, 25));
      controller.endNodeDrag();

      expect(node1.position.value, equals(const Offset(50, 50)));
      expect(node2.position.value, equals(const Offset(125, 125)));
    });

    test('full connection drag sequence: start -> update -> complete', () {
      final source = createTestNodeWithOutputPort(id: 'source', portId: 'out1');
      final target = createTestNodeWithInputPort(
        id: 'target',
        portId: 'in1',
        position: const Offset(200, 0),
      );
      controller.addNode(source);
      controller.addNode(target);

      // Start
      final startResult = controller.startConnectionDrag(
        nodeId: 'source',
        portId: 'out1',
        isOutput: true,
        startPoint: Offset.zero,
        nodeBounds: Rect.zero,
      );
      expect(startResult.allowed, isTrue);
      expect(controller.isConnecting, isTrue);

      // Update
      controller.updateConnectionDrag(
        graphPosition: const Offset(200, 50),
        targetNodeId: 'target',
        targetPortId: 'in1',
      );
      expect(controller.temporaryConnection?.targetNodeId, equals('target'));

      // Complete
      final connection = controller.completeConnectionDrag(
        targetNodeId: 'target',
        targetPortId: 'in1',
      );
      expect(connection, isNotNull);
      expect(controller.isConnecting, isFalse);
      expect(controller.connectionCount, equals(1));
    });

    test('connection drag cancellation cleans up properly', () {
      final source = createTestNodeWithOutputPort(id: 'source', portId: 'out1');
      controller.addNode(source);

      controller.startConnectionDrag(
        nodeId: 'source',
        portId: 'out1',
        isOutput: true,
        startPoint: Offset.zero,
        nodeBounds: Rect.zero,
      );
      expect(controller.isConnecting, isTrue);

      controller.cancelConnectionDrag();
      expect(controller.isConnecting, isFalse);
      expect(controller.temporaryConnection, isNull);
      expect(controller.connectionCount, equals(0));
    });
  });
}
