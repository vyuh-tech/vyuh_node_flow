/// Comprehensive unit tests for connection validation rules in vyuh_node_flow.
///
/// These tests cover the full spectrum of connection validation logic:
/// - Valid connection scenarios
/// - Invalid connection scenarios (same node, wrong port types, etc.)
/// - Port type compatibility
/// - Max connections enforcement
/// - Cycle prevention
/// - Connection constraints and rules
@Tags(['unit'])
library;

import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:vyuh_node_flow/vyuh_node_flow.dart';

import '../../helpers/test_factories.dart';
import '../../helpers/test_utils.dart';

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
  // Valid Connection Scenarios
  // ===========================================================================

  group('Valid Connection Scenarios', () {
    test('allows output to input connection on different nodes', () {
      final sourceNode = createTestNodeWithOutputPort(
        id: 'source',
        portId: 'out-1',
      );
      final targetNode = createTestNodeWithInputPort(
        id: 'target',
        portId: 'in-1',
      );
      controller.addNode(sourceNode);
      controller.addNode(targetNode);

      controller.startConnectionDrag(
        nodeId: 'source',
        portId: 'out-1',
        isOutput: true,
        startPoint: const Offset(100, 50),
        nodeBounds: const Rect.fromLTWH(0, 0, 100, 100),
      );

      final result = controller.canConnect(
        targetNodeId: 'target',
        targetPortId: 'in-1',
      );

      expect(result.allowed, isTrue);
      controller.cancelConnectionDrag();
    });

    test('allows input to output connection (bidirectional drag)', () {
      final sourceNode = createTestNodeWithOutputPort(
        id: 'source',
        portId: 'out-1',
      );
      final targetNode = createTestNodeWithInputPort(
        id: 'target',
        portId: 'in-1',
      );
      controller.addNode(sourceNode);
      controller.addNode(targetNode);

      // Start from input port (reverse direction)
      controller.startConnectionDrag(
        nodeId: 'target',
        portId: 'in-1',
        isOutput: false,
        startPoint: const Offset(200, 50),
        nodeBounds: const Rect.fromLTWH(200, 0, 100, 100),
      );

      // Connect to output port
      final result = controller.canConnect(
        targetNodeId: 'source',
        targetPortId: 'out-1',
      );

      expect(result.allowed, isTrue);
      controller.cancelConnectionDrag();
    });

    test('allows self-connection from output to input on same node', () {
      // Self-connections are allowed by default for feedback loops
      final node = createTestNodeWithPorts(
        id: 'self-node',
        inputPortId: 'in-1',
        outputPortId: 'out-1',
      );
      controller.addNode(node);

      controller.startConnectionDrag(
        nodeId: 'self-node',
        portId: 'out-1',
        isOutput: true,
        startPoint: const Offset(100, 50),
        nodeBounds: const Rect.fromLTWH(0, 0, 100, 100),
      );

      final result = controller.canConnect(
        targetNodeId: 'self-node',
        targetPortId: 'in-1',
      );

      // Self-connections are allowed by default (for feedback loops)
      expect(result.allowed, isTrue);
      controller.cancelConnectionDrag();
    });

    test('allows multiple connections from multi-connection output port', () {
      final sourceNode = createTestNode(
        id: 'source',
        outputPorts: [
          Port(
            id: 'out-1',
            name: 'Output',
            type: PortType.output,
            multiConnections: true,
          ),
        ],
      );
      final target1 = createTestNodeWithInputPort(
        id: 'target-1',
        portId: 'in-1',
      );
      final target2 = createTestNodeWithInputPort(
        id: 'target-2',
        portId: 'in-1',
      );
      controller.addNode(sourceNode);
      controller.addNode(target1);
      controller.addNode(target2);

      // Create first connection
      controller.startConnectionDrag(
        nodeId: 'source',
        portId: 'out-1',
        isOutput: true,
        startPoint: const Offset(100, 50),
        nodeBounds: const Rect.fromLTWH(0, 0, 100, 100),
      );
      controller.completeConnectionDrag(
        targetNodeId: 'target-1',
        targetPortId: 'in-1',
      );

      // Start second connection
      controller.startConnectionDrag(
        nodeId: 'source',
        portId: 'out-1',
        isOutput: true,
        startPoint: const Offset(100, 50),
        nodeBounds: const Rect.fromLTWH(0, 0, 100, 100),
      );

      final result = controller.canConnect(
        targetNodeId: 'target-2',
        targetPortId: 'in-1',
      );

      expect(result.allowed, isTrue);
      controller.cancelConnectionDrag();
    });

    test('allows multiple connections to multi-connection input port', () {
      final source1 = createTestNodeWithOutputPort(
        id: 'source-1',
        portId: 'out-1',
      );
      final source2 = createTestNodeWithOutputPort(
        id: 'source-2',
        portId: 'out-1',
      );
      final targetNode = createTestNode(
        id: 'target',
        inputPorts: [
          Port(
            id: 'in-1',
            name: 'Input',
            type: PortType.input,
            multiConnections: true,
          ),
        ],
      );
      controller.addNode(source1);
      controller.addNode(source2);
      controller.addNode(targetNode);

      // Create first connection
      controller.startConnectionDrag(
        nodeId: 'source-1',
        portId: 'out-1',
        isOutput: true,
        startPoint: const Offset(100, 50),
        nodeBounds: const Rect.fromLTWH(0, 0, 100, 100),
      );
      controller.completeConnectionDrag(
        targetNodeId: 'target',
        targetPortId: 'in-1',
      );

      // Start second connection
      controller.startConnectionDrag(
        nodeId: 'source-2',
        portId: 'out-1',
        isOutput: true,
        startPoint: const Offset(100, 150),
        nodeBounds: const Rect.fromLTWH(0, 100, 100, 100),
      );

      final result = controller.canConnect(
        targetNodeId: 'target',
        targetPortId: 'in-1',
      );

      expect(result.allowed, isTrue);
      controller.cancelConnectionDrag();
    });
  });

  // ===========================================================================
  // Invalid Connection Scenarios - Same Node
  // ===========================================================================

  group('Invalid Connection Scenarios - Same Port', () {
    test('rejects connecting a port to itself', () {
      final node = createTestNodeWithOutputPort(id: 'node', portId: 'out-1');
      controller.addNode(node);

      controller.startConnectionDrag(
        nodeId: 'node',
        portId: 'out-1',
        isOutput: true,
        startPoint: const Offset(100, 50),
        nodeBounds: const Rect.fromLTWH(0, 0, 100, 100),
      );

      final result = controller.canConnect(
        targetNodeId: 'node',
        targetPortId: 'out-1',
      );

      expect(result.allowed, isFalse);
      expect(result.reason, contains('itself'));
      controller.cancelConnectionDrag();
    });

    test('rejects input port connecting to itself', () {
      final node = createTestNodeWithInputPort(id: 'node', portId: 'in-1');
      controller.addNode(node);

      controller.startConnectionDrag(
        nodeId: 'node',
        portId: 'in-1',
        isOutput: false,
        startPoint: const Offset(0, 50),
        nodeBounds: const Rect.fromLTWH(0, 0, 100, 100),
      );

      final result = controller.canConnect(
        targetNodeId: 'node',
        targetPortId: 'in-1',
      );

      expect(result.allowed, isFalse);
      expect(result.reason, contains('itself'));
      controller.cancelConnectionDrag();
    });
  });

  // ===========================================================================
  // Invalid Connection Scenarios - Port Type Mismatch
  // ===========================================================================

  group('Invalid Connection Scenarios - Port Type Mismatch', () {
    test('rejects output to output connection', () {
      final node1 = createTestNodeWithOutputPort(id: 'node-1', portId: 'out-1');
      final node2 = createTestNodeWithOutputPort(id: 'node-2', portId: 'out-1');
      controller.addNode(node1);
      controller.addNode(node2);

      controller.startConnectionDrag(
        nodeId: 'node-1',
        portId: 'out-1',
        isOutput: true,
        startPoint: const Offset(100, 50),
        nodeBounds: const Rect.fromLTWH(0, 0, 100, 100),
      );

      final result = controller.canConnect(
        targetNodeId: 'node-2',
        targetPortId: 'out-1',
      );

      expect(result.allowed, isFalse);
      expect(result.reason, contains('output to output'));
      controller.cancelConnectionDrag();
    });

    test('rejects input to input connection', () {
      final node1 = createTestNodeWithInputPort(id: 'node-1', portId: 'in-1');
      final node2 = createTestNodeWithInputPort(id: 'node-2', portId: 'in-1');
      controller.addNode(node1);
      controller.addNode(node2);

      controller.startConnectionDrag(
        nodeId: 'node-1',
        portId: 'in-1',
        isOutput: false,
        startPoint: const Offset(0, 50),
        nodeBounds: const Rect.fromLTWH(0, 0, 100, 100),
      );

      final result = controller.canConnect(
        targetNodeId: 'node-2',
        targetPortId: 'in-1',
      );

      expect(result.allowed, isFalse);
      expect(result.reason, contains('input to input'));
      controller.cancelConnectionDrag();
    });

    test(
      'rejects starting connection from non-output when claiming output',
      () {
        final node = createTestNodeWithInputPort(id: 'node', portId: 'in-1');
        controller.addNode(node);

        final result = controller.canStartConnection(
          nodeId: 'node',
          portId: 'in-1',
          isOutput: true, // Claiming input port is output
        );

        expect(result.allowed, isFalse);
        expect(result.reason, contains('cannot emit'));
      },
    );

    test('rejects starting connection from non-input when claiming input', () {
      final node = createTestNodeWithOutputPort(id: 'node', portId: 'out-1');
      controller.addNode(node);

      final result = controller.canStartConnection(
        nodeId: 'node',
        portId: 'out-1',
        isOutput: false, // Claiming output port is input
      );

      expect(result.allowed, isFalse);
      expect(result.reason, contains('cannot receive'));
    });
  });

  // ===========================================================================
  // Invalid Connection Scenarios - Non-existent Elements
  // ===========================================================================

  group('Invalid Connection Scenarios - Non-existent Elements', () {
    test('rejects connection from non-existent source node', () {
      final result = controller.canStartConnection(
        nodeId: 'non-existent',
        portId: 'out-1',
        isOutput: true,
      );

      expect(result.allowed, isFalse);
      expect(result.reason, contains('Node not found'));
    });

    test('rejects connection from non-existent source port', () {
      final node = createTestNode(id: 'node');
      controller.addNode(node);

      final result = controller.canStartConnection(
        nodeId: 'node',
        portId: 'non-existent',
        isOutput: true,
      );

      expect(result.allowed, isFalse);
      expect(result.reason, contains('Port not found'));
    });

    test('rejects connection to non-existent target node', () {
      final node = createTestNodeWithOutputPort(id: 'source', portId: 'out-1');
      controller.addNode(node);

      controller.startConnectionDrag(
        nodeId: 'source',
        portId: 'out-1',
        isOutput: true,
        startPoint: const Offset(100, 50),
        nodeBounds: const Rect.fromLTWH(0, 0, 100, 100),
      );

      final result = controller.canConnect(
        targetNodeId: 'non-existent',
        targetPortId: 'in-1',
      );

      expect(result.allowed, isFalse);
      expect(result.reason, contains('Target node not found'));
      controller.cancelConnectionDrag();
    });

    test('rejects connection to non-existent target port', () {
      final source = createTestNodeWithOutputPort(
        id: 'source',
        portId: 'out-1',
      );
      final target = createTestNode(id: 'target');
      controller.addNode(source);
      controller.addNode(target);

      controller.startConnectionDrag(
        nodeId: 'source',
        portId: 'out-1',
        isOutput: true,
        startPoint: const Offset(100, 50),
        nodeBounds: const Rect.fromLTWH(0, 0, 100, 100),
      );

      final result = controller.canConnect(
        targetNodeId: 'target',
        targetPortId: 'non-existent',
      );

      expect(result.allowed, isFalse);
      expect(result.reason, contains('Target port not found'));
      controller.cancelConnectionDrag();
    });
  });

  // ===========================================================================
  // Invalid Connection Scenarios - Non-connectable Ports
  // ===========================================================================

  group('Invalid Connection Scenarios - Non-connectable Ports', () {
    test('rejects starting connection from non-connectable port', () {
      final node = createTestNode(
        id: 'node',
        outputPorts: [
          Port(
            id: 'out-1',
            name: 'Output',
            type: PortType.output,
            isConnectable: false,
          ),
        ],
      );
      controller.addNode(node);

      final result = controller.canStartConnection(
        nodeId: 'node',
        portId: 'out-1',
        isOutput: true,
      );

      expect(result.allowed, isFalse);
      expect(result.reason, contains('not connectable'));
    });

    test('rejects connection to non-connectable target port', () {
      final source = createTestNodeWithOutputPort(
        id: 'source',
        portId: 'out-1',
      );
      final target = createTestNode(
        id: 'target',
        inputPorts: [
          Port(
            id: 'in-1',
            name: 'Input',
            type: PortType.input,
            isConnectable: false,
          ),
        ],
      );
      controller.addNode(source);
      controller.addNode(target);

      controller.startConnectionDrag(
        nodeId: 'source',
        portId: 'out-1',
        isOutput: true,
        startPoint: const Offset(100, 50),
        nodeBounds: const Rect.fromLTWH(0, 0, 100, 100),
      );

      final result = controller.canConnect(
        targetNodeId: 'target',
        targetPortId: 'in-1',
      );

      expect(result.allowed, isFalse);
      expect(result.reason, contains('not connectable'));
      controller.cancelConnectionDrag();
    });
  });

  // ===========================================================================
  // Invalid Connection Scenarios - Duplicate Connections
  // ===========================================================================

  group('Invalid Connection Scenarios - Duplicate Connections', () {
    test('rejects duplicate connection between same ports', () {
      final source = createTestNode(
        id: 'source',
        outputPorts: [
          Port(
            id: 'out-1',
            name: 'Output',
            type: PortType.output,
            multiConnections: true,
          ),
        ],
      );
      final target = createTestNode(
        id: 'target',
        inputPorts: [
          Port(
            id: 'in-1',
            name: 'Input',
            type: PortType.input,
            multiConnections: true,
          ),
        ],
      );
      controller.addNode(source);
      controller.addNode(target);

      // Create existing connection
      final connection = createTestConnection(
        id: 'existing',
        sourceNodeId: 'source',
        sourcePortId: 'out-1',
        targetNodeId: 'target',
        targetPortId: 'in-1',
      );
      controller.addConnection(connection);

      // Try to create duplicate
      controller.startConnectionDrag(
        nodeId: 'source',
        portId: 'out-1',
        isOutput: true,
        startPoint: const Offset(100, 50),
        nodeBounds: const Rect.fromLTWH(0, 0, 100, 100),
      );

      final result = controller.canConnect(
        targetNodeId: 'target',
        targetPortId: 'in-1',
      );

      expect(result.allowed, isFalse);
      expect(result.reason, contains('already exists'));
      controller.cancelConnectionDrag();
    });
  });

  // ===========================================================================
  // Port Type Compatibility
  // ===========================================================================

  group('Port Type Compatibility', () {
    test('Port isOutput returns true for output type', () {
      final port = createTestPort(id: 'out', type: PortType.output);
      expect(port.isOutput, isTrue);
      expect(port.isInput, isFalse);
    });

    test('Port isInput returns true for input type', () {
      final port = createTestPort(id: 'in', type: PortType.input);
      expect(port.isInput, isTrue);
      expect(port.isOutput, isFalse);
    });

    test('left port defaults to input type', () {
      final port = Port(
        id: 'left-port',
        name: 'Left',
        position: PortPosition.left,
      );
      expect(port.type, equals(PortType.input));
    });

    test('right port defaults to output type', () {
      final port = Port(
        id: 'right-port',
        name: 'Right',
        position: PortPosition.right,
      );
      expect(port.type, equals(PortType.output));
    });

    test('top port defaults to input type', () {
      final port = Port(
        id: 'top-port',
        name: 'Top',
        position: PortPosition.top,
      );
      expect(port.type, equals(PortType.input));
    });

    test('bottom port defaults to output type', () {
      final port = Port(
        id: 'bottom-port',
        name: 'Bottom',
        position: PortPosition.bottom,
      );
      expect(port.type, equals(PortType.output));
    });

    test('explicit port type overrides position-based inference', () {
      final port = Port(
        id: 'custom-port',
        name: 'Custom',
        position: PortPosition.left,
        type: PortType.output, // Override default input type for left
      );
      expect(port.type, equals(PortType.output));
    });

    test('output-to-input is the standard flow direction', () {
      final source = createTestNodeWithOutputPort(id: 'source');
      final target = createTestNodeWithInputPort(id: 'target');

      final context = ConnectionCompleteContext(
        sourceNode: source,
        sourcePort: source.outputPorts.first,
        targetNode: target,
        targetPort: target.inputPorts.first,
        existingSourceConnections: [],
        existingTargetConnections: [],
      );

      expect(context.isOutputToInput, isTrue);
      expect(context.isInputToOutput, isFalse);
    });

    test('input-to-output is reverse direction', () {
      final source = createTestNodeWithInputPort(id: 'source');
      final target = createTestNodeWithOutputPort(id: 'target');

      final context = ConnectionCompleteContext(
        sourceNode: source,
        sourcePort: source.inputPorts.first,
        targetNode: target,
        targetPort: target.outputPorts.first,
        existingSourceConnections: [],
        existingTargetConnections: [],
      );

      expect(context.isInputToOutput, isTrue);
      expect(context.isOutputToInput, isFalse);
    });
  });

  // ===========================================================================
  // Max Connections Enforcement
  // ===========================================================================

  group('Max Connections Enforcement', () {
    test('respects maxConnections limit on target port', () {
      final source1 = createTestNodeWithOutputPort(
        id: 'source-1',
        portId: 'out-1',
      );
      final source2 = createTestNodeWithOutputPort(
        id: 'source-2',
        portId: 'out-1',
      );
      final target = createTestNode(
        id: 'target',
        inputPorts: [
          Port(
            id: 'in-1',
            name: 'Input',
            type: PortType.input,
            multiConnections: true,
            maxConnections: 1,
          ),
        ],
      );
      controller.addNode(source1);
      controller.addNode(source2);
      controller.addNode(target);

      // Create first connection
      controller.startConnectionDrag(
        nodeId: 'source-1',
        portId: 'out-1',
        isOutput: true,
        startPoint: const Offset(100, 50),
        nodeBounds: const Rect.fromLTWH(0, 0, 100, 100),
      );
      controller.completeConnectionDrag(
        targetNodeId: 'target',
        targetPortId: 'in-1',
      );
      expect(controller.connectionCount, equals(1));

      // Try second connection
      controller.startConnectionDrag(
        nodeId: 'source-2',
        portId: 'out-1',
        isOutput: true,
        startPoint: const Offset(100, 150),
        nodeBounds: const Rect.fromLTWH(0, 100, 100, 100),
      );

      final result = controller.canConnect(
        targetNodeId: 'target',
        targetPortId: 'in-1',
      );

      expect(result.allowed, isFalse);
      expect(result.reason, contains('maximum connections'));
      controller.cancelConnectionDrag();
    });

    test('respects maxConnections limit on source port', () {
      final source = createTestNode(
        id: 'source',
        outputPorts: [
          Port(
            id: 'out-1',
            name: 'Output',
            type: PortType.output,
            multiConnections: true,
            maxConnections: 1,
          ),
        ],
      );
      final target1 = createTestNodeWithInputPort(
        id: 'target-1',
        portId: 'in-1',
      );
      final target2 = createTestNodeWithInputPort(
        id: 'target-2',
        portId: 'in-1',
      );
      controller.addNode(source);
      controller.addNode(target1);
      controller.addNode(target2);

      // Create first connection
      controller.startConnectionDrag(
        nodeId: 'source',
        portId: 'out-1',
        isOutput: true,
        startPoint: const Offset(100, 50),
        nodeBounds: const Rect.fromLTWH(0, 0, 100, 100),
      );
      controller.completeConnectionDrag(
        targetNodeId: 'target-1',
        targetPortId: 'in-1',
      );
      expect(controller.connectionCount, equals(1));

      // Trying to start another connection should be rejected
      final result = controller.canStartConnection(
        nodeId: 'source',
        portId: 'out-1',
        isOutput: true,
      );

      expect(result.allowed, isFalse);
      expect(result.reason, contains('Maximum connections reached'));
    });

    test('maxConnections of 2 allows exactly 2 connections', () {
      final source = createTestNode(
        id: 'source',
        outputPorts: [
          Port(
            id: 'out-1',
            name: 'Output',
            type: PortType.output,
            multiConnections: true,
            maxConnections: 2,
          ),
        ],
      );
      final target1 = createTestNodeWithInputPort(
        id: 'target-1',
        portId: 'in-1',
      );
      final target2 = createTestNodeWithInputPort(
        id: 'target-2',
        portId: 'in-1',
      );
      final target3 = createTestNodeWithInputPort(
        id: 'target-3',
        portId: 'in-1',
      );
      controller.addNode(source);
      controller.addNode(target1);
      controller.addNode(target2);
      controller.addNode(target3);

      // Create first connection
      controller.startConnectionDrag(
        nodeId: 'source',
        portId: 'out-1',
        isOutput: true,
        startPoint: const Offset(100, 50),
        nodeBounds: const Rect.fromLTWH(0, 0, 100, 100),
      );
      controller.completeConnectionDrag(
        targetNodeId: 'target-1',
        targetPortId: 'in-1',
      );

      // Create second connection (should succeed)
      controller.startConnectionDrag(
        nodeId: 'source',
        portId: 'out-1',
        isOutput: true,
        startPoint: const Offset(100, 50),
        nodeBounds: const Rect.fromLTWH(0, 0, 100, 100),
      );
      controller.completeConnectionDrag(
        targetNodeId: 'target-2',
        targetPortId: 'in-1',
      );

      expect(controller.connectionCount, equals(2));

      // Third connection should be rejected
      final result = controller.canStartConnection(
        nodeId: 'source',
        portId: 'out-1',
        isOutput: true,
      );

      expect(result.allowed, isFalse);
    });

    test('null maxConnections allows unlimited connections', () {
      final source = createTestNode(
        id: 'source',
        outputPorts: [
          Port(
            id: 'out-1',
            name: 'Output',
            type: PortType.output,
            multiConnections: true,
            maxConnections: null, // Unlimited
          ),
        ],
      );
      controller.addNode(source);

      // Add many targets and create connections
      for (int i = 0; i < 10; i++) {
        final target = createTestNodeWithInputPort(
          id: 'target-$i',
          portId: 'in-1',
        );
        controller.addNode(target);

        controller.startConnectionDrag(
          nodeId: 'source',
          portId: 'out-1',
          isOutput: true,
          startPoint: const Offset(100, 50),
          nodeBounds: const Rect.fromLTWH(0, 0, 100, 100),
        );
        controller.completeConnectionDrag(
          targetNodeId: 'target-$i',
          targetPortId: 'in-1',
        );
      }

      expect(controller.connectionCount, equals(10));
    });

    test('single connection port replaces existing connection', () {
      final source1 = createTestNodeWithOutputPort(
        id: 'source-1',
        portId: 'out-1',
      );
      final source2 = createTestNodeWithOutputPort(
        id: 'source-2',
        portId: 'out-1',
      );
      final target = createTestNode(
        id: 'target',
        inputPorts: [
          Port(
            id: 'in-1',
            name: 'Input',
            type: PortType.input,
            multiConnections: false, // Single connection only
          ),
        ],
      );
      controller.addNode(source1);
      controller.addNode(source2);
      controller.addNode(target);

      // Create first connection
      controller.startConnectionDrag(
        nodeId: 'source-1',
        portId: 'out-1',
        isOutput: true,
        startPoint: const Offset(100, 50),
        nodeBounds: const Rect.fromLTWH(0, 0, 100, 100),
      );
      final conn1 = controller.completeConnectionDrag(
        targetNodeId: 'target',
        targetPortId: 'in-1',
      );
      expect(conn1!.sourceNodeId, equals('source-1'));
      expect(controller.connectionCount, equals(1));

      // Create second connection - should replace first
      controller.startConnectionDrag(
        nodeId: 'source-2',
        portId: 'out-1',
        isOutput: true,
        startPoint: const Offset(100, 150),
        nodeBounds: const Rect.fromLTWH(0, 100, 100, 100),
      );
      final conn2 = controller.completeConnectionDrag(
        targetNodeId: 'target',
        targetPortId: 'in-1',
      );

      expect(conn2!.sourceNodeId, equals('source-2'));
      expect(controller.connectionCount, equals(1));
      expect(controller.getConnection(conn1.id), isNull);
    });
  });

  // ===========================================================================
  // Cycle Prevention
  // ===========================================================================

  group('Cycle Prevention', () {
    test('detectCycles returns empty for acyclic graph', () {
      final nodeA = createTestNodeWithPorts(
        id: 'A',
        inputPortId: 'in',
        outputPortId: 'out',
      );
      final nodeB = createTestNodeWithPorts(
        id: 'B',
        inputPortId: 'in',
        outputPortId: 'out',
      );
      final nodeC = createTestNodeWithInputPort(id: 'C', portId: 'in');

      controller.addNode(nodeA);
      controller.addNode(nodeB);
      controller.addNode(nodeC);

      controller.addConnection(
        createTestConnection(
          sourceNodeId: 'A',
          sourcePortId: 'out',
          targetNodeId: 'B',
          targetPortId: 'in',
        ),
      );
      controller.addConnection(
        createTestConnection(
          sourceNodeId: 'B',
          sourcePortId: 'out',
          targetNodeId: 'C',
          targetPortId: 'in',
        ),
      );

      final cycles = controller.detectCycles();
      expect(cycles, isEmpty);
    });

    test('detectCycles finds simple A -> B -> A cycle', () {
      final nodeA = createTestNodeWithPorts(
        id: 'A',
        inputPortId: 'in',
        outputPortId: 'out',
      );
      final nodeB = createTestNodeWithPorts(
        id: 'B',
        inputPortId: 'in',
        outputPortId: 'out',
      );

      controller.addNode(nodeA);
      controller.addNode(nodeB);

      controller.addConnection(
        createTestConnection(
          sourceNodeId: 'A',
          sourcePortId: 'out',
          targetNodeId: 'B',
          targetPortId: 'in',
        ),
      );
      controller.addConnection(
        createTestConnection(
          sourceNodeId: 'B',
          sourcePortId: 'out',
          targetNodeId: 'A',
          targetPortId: 'in',
        ),
      );

      final cycles = controller.detectCycles();
      expect(cycles, isNotEmpty);
    });

    test('detectCycles finds A -> B -> C -> A cycle', () {
      final nodeA = createTestNodeWithPorts(
        id: 'A',
        inputPortId: 'in',
        outputPortId: 'out',
      );
      final nodeB = createTestNodeWithPorts(
        id: 'B',
        inputPortId: 'in',
        outputPortId: 'out',
      );
      final nodeC = createTestNodeWithPorts(
        id: 'C',
        inputPortId: 'in',
        outputPortId: 'out',
      );

      controller.addNode(nodeA);
      controller.addNode(nodeB);
      controller.addNode(nodeC);

      controller.addConnection(
        createTestConnection(
          sourceNodeId: 'A',
          sourcePortId: 'out',
          targetNodeId: 'B',
          targetPortId: 'in',
        ),
      );
      controller.addConnection(
        createTestConnection(
          sourceNodeId: 'B',
          sourcePortId: 'out',
          targetNodeId: 'C',
          targetPortId: 'in',
        ),
      );
      controller.addConnection(
        createTestConnection(
          sourceNodeId: 'C',
          sourcePortId: 'out',
          targetNodeId: 'A',
          targetPortId: 'in',
        ),
      );

      final cycles = controller.detectCycles();
      expect(cycles, isNotEmpty);
      expect(cycles.first.length, greaterThanOrEqualTo(3));
    });

    test('detectCycles finds self-loop as cycle', () {
      final node = createTestNodeWithPorts(
        id: 'self',
        inputPortId: 'in',
        outputPortId: 'out',
      );
      controller.addNode(node);

      controller.addConnection(
        createTestConnection(
          sourceNodeId: 'self',
          sourcePortId: 'out',
          targetNodeId: 'self',
          targetPortId: 'in',
        ),
      );

      final cycles = controller.detectCycles();
      expect(cycles, isNotEmpty);
    });

    test('hasCycles returns true when cycles exist', () {
      final nodeA = createTestNodeWithPorts(
        id: 'A',
        inputPortId: 'in',
        outputPortId: 'out',
      );
      final nodeB = createTestNodeWithPorts(
        id: 'B',
        inputPortId: 'in',
        outputPortId: 'out',
      );

      controller.addNode(nodeA);
      controller.addNode(nodeB);

      controller.addConnection(
        createTestConnection(
          sourceNodeId: 'A',
          sourcePortId: 'out',
          targetNodeId: 'B',
          targetPortId: 'in',
        ),
      );
      controller.addConnection(
        createTestConnection(
          sourceNodeId: 'B',
          sourcePortId: 'out',
          targetNodeId: 'A',
          targetPortId: 'in',
        ),
      );

      expect(controller.hasCycles(), isTrue);
    });

    test('hasCycles returns false for DAG', () {
      final nodeA = createTestNodeWithOutputPort(id: 'A', portId: 'out');
      final nodeB = createTestNodeWithInputPort(id: 'B', portId: 'in');

      controller.addNode(nodeA);
      controller.addNode(nodeB);

      controller.addConnection(
        createTestConnection(
          sourceNodeId: 'A',
          sourcePortId: 'out',
          targetNodeId: 'B',
          targetPortId: 'in',
        ),
      );

      expect(controller.hasCycles(), isFalse);
    });

    test('removing connection breaks cycle', () {
      final nodeA = createTestNodeWithPorts(
        id: 'A',
        inputPortId: 'in',
        outputPortId: 'out',
      );
      final nodeB = createTestNodeWithPorts(
        id: 'B',
        inputPortId: 'in',
        outputPortId: 'out',
      );

      controller.addNode(nodeA);
      controller.addNode(nodeB);

      controller.addConnection(
        createTestConnection(
          id: 'conn-ab',
          sourceNodeId: 'A',
          sourcePortId: 'out',
          targetNodeId: 'B',
          targetPortId: 'in',
        ),
      );
      controller.addConnection(
        createTestConnection(
          id: 'conn-ba',
          sourceNodeId: 'B',
          sourcePortId: 'out',
          targetNodeId: 'A',
          targetPortId: 'in',
        ),
      );

      expect(controller.hasCycles(), isTrue);

      controller.removeConnection('conn-ba');

      expect(controller.hasCycles(), isFalse);
    });

    test('diamond pattern without cycle is detected correctly', () {
      //     A
      //    / \
      //   B   C
      //    \ /
      //     D
      final nodeA = createTestNode(
        id: 'A',
        outputPorts: [
          Port(
            id: 'out-1',
            name: 'Out1',
            type: PortType.output,
            multiConnections: true,
          ),
        ],
      );
      final nodeB = createTestNodeWithPorts(
        id: 'B',
        inputPortId: 'in',
        outputPortId: 'out',
      );
      final nodeC = createTestNodeWithPorts(
        id: 'C',
        inputPortId: 'in',
        outputPortId: 'out',
      );
      final nodeD = createTestNode(
        id: 'D',
        inputPorts: [
          Port(
            id: 'in',
            name: 'In',
            type: PortType.input,
            multiConnections: true,
          ),
        ],
      );

      controller.addNode(nodeA);
      controller.addNode(nodeB);
      controller.addNode(nodeC);
      controller.addNode(nodeD);

      controller.addConnection(
        createTestConnection(
          sourceNodeId: 'A',
          sourcePortId: 'out-1',
          targetNodeId: 'B',
          targetPortId: 'in',
        ),
      );
      controller.addConnection(
        createTestConnection(
          sourceNodeId: 'A',
          sourcePortId: 'out-1',
          targetNodeId: 'C',
          targetPortId: 'in',
        ),
      );
      controller.addConnection(
        createTestConnection(
          sourceNodeId: 'B',
          sourcePortId: 'out',
          targetNodeId: 'D',
          targetPortId: 'in',
        ),
      );
      controller.addConnection(
        createTestConnection(
          sourceNodeId: 'C',
          sourcePortId: 'out',
          targetNodeId: 'D',
          targetPortId: 'in',
        ),
      );

      expect(controller.hasCycles(), isFalse);
    });
  });

  // ===========================================================================
  // Custom Validation Rules
  // ===========================================================================

  group('Custom Validation Rules', () {
    test('onBeforeStart callback can reject connection start', () {
      final node = createTestNodeWithOutputPort(id: 'node', portId: 'out-1');
      controller.addNode(node);

      controller.updateEvents(
        NodeFlowEvents<String, dynamic>(
          connection: ConnectionEvents<String, dynamic>(
            onBeforeStart: (context) {
              return const ConnectionValidationResult.deny(
                reason: 'Custom start rejection',
                showMessage: true,
              );
            },
          ),
        ),
      );

      final result = controller.canStartConnection(
        nodeId: 'node',
        portId: 'out-1',
        isOutput: true,
      );

      expect(result.allowed, isFalse);
      expect(result.reason, equals('Custom start rejection'));
      expect(result.showMessage, isTrue);
    });

    test('onBeforeComplete callback can reject connection completion', () {
      final source = createTestNodeWithOutputPort(
        id: 'source',
        portId: 'out-1',
      );
      final target = createTestNodeWithInputPort(id: 'target', portId: 'in-1');
      controller.addNode(source);
      controller.addNode(target);

      controller.updateEvents(
        NodeFlowEvents<String, dynamic>(
          connection: ConnectionEvents<String, dynamic>(
            onBeforeComplete: (context) {
              return const ConnectionValidationResult.deny(
                reason: 'Custom completion rejection',
              );
            },
          ),
        ),
      );

      controller.startConnectionDrag(
        nodeId: 'source',
        portId: 'out-1',
        isOutput: true,
        startPoint: const Offset(100, 50),
        nodeBounds: const Rect.fromLTWH(0, 0, 100, 100),
      );

      final result = controller.canConnect(
        targetNodeId: 'target',
        targetPortId: 'in-1',
      );

      expect(result.allowed, isFalse);
      expect(result.reason, equals('Custom completion rejection'));
      controller.cancelConnectionDrag();
    });

    test('onBeforeComplete receives correct context information', () {
      final source = createTestNodeWithOutputPort(
        id: 'source',
        portId: 'out-1',
      );
      final target = createTestNodeWithInputPort(id: 'target', portId: 'in-1');
      controller.addNode(source);
      controller.addNode(target);

      ConnectionCompleteContext<String>? capturedContext;
      controller.updateEvents(
        NodeFlowEvents<String, dynamic>(
          connection: ConnectionEvents<String, dynamic>(
            onBeforeComplete: (context) {
              capturedContext = context;
              return const ConnectionValidationResult.allow();
            },
          ),
        ),
      );

      controller.startConnectionDrag(
        nodeId: 'source',
        portId: 'out-1',
        isOutput: true,
        startPoint: const Offset(100, 50),
        nodeBounds: const Rect.fromLTWH(0, 0, 100, 100),
      );

      controller.canConnect(targetNodeId: 'target', targetPortId: 'in-1');

      expect(capturedContext, isNotNull);
      expect(capturedContext!.sourceNode.id, equals('source'));
      expect(capturedContext!.sourcePort.id, equals('out-1'));
      expect(capturedContext!.targetNode.id, equals('target'));
      expect(capturedContext!.targetPort.id, equals('in-1'));
      expect(capturedContext!.isSelfConnection, isFalse);
      expect(capturedContext!.isOutputToInput, isTrue);
      controller.cancelConnectionDrag();
    });

    test('can implement custom self-connection prevention', () {
      final node = createTestNodeWithPorts(
        id: 'self-node',
        inputPortId: 'in-1',
        outputPortId: 'out-1',
      );
      controller.addNode(node);

      controller.updateEvents(
        NodeFlowEvents<String, dynamic>(
          connection: ConnectionEvents<String, dynamic>(
            onBeforeComplete: (context) {
              if (context.isSelfConnection) {
                return const ConnectionValidationResult.deny(
                  reason: 'Self-connections are disabled',
                  showMessage: true,
                );
              }
              return const ConnectionValidationResult.allow();
            },
          ),
        ),
      );

      controller.startConnectionDrag(
        nodeId: 'self-node',
        portId: 'out-1',
        isOutput: true,
        startPoint: const Offset(100, 50),
        nodeBounds: const Rect.fromLTWH(0, 0, 100, 100),
      );

      final result = controller.canConnect(
        targetNodeId: 'self-node',
        targetPortId: 'in-1',
      );

      expect(result.allowed, isFalse);
      expect(result.reason, equals('Self-connections are disabled'));
      controller.cancelConnectionDrag();
    });

    test('can implement node type-based validation', () {
      final sourceNode = createTestNode(
        id: 'source',
        type: 'data-source',
        outputPorts: [createTestPort(id: 'out-1', type: PortType.output)],
      );
      final targetNode = createTestNode(
        id: 'target',
        type: 'data-sink',
        inputPorts: [createTestPort(id: 'in-1', type: PortType.input)],
      );
      final incompatibleTarget = createTestNode(
        id: 'incompatible',
        type: 'processor',
        inputPorts: [createTestPort(id: 'in-1', type: PortType.input)],
      );
      controller.addNode(sourceNode);
      controller.addNode(targetNode);
      controller.addNode(incompatibleTarget);

      controller.updateEvents(
        NodeFlowEvents<String, dynamic>(
          connection: ConnectionEvents<String, dynamic>(
            onBeforeComplete: (context) {
              // Only allow data-source to connect to data-sink
              if (context.sourceNode.type == 'data-source' &&
                  context.targetNode.type != 'data-sink') {
                return const ConnectionValidationResult.deny(
                  reason: 'Data sources can only connect to data sinks',
                );
              }
              return const ConnectionValidationResult.allow();
            },
          ),
        ),
      );

      // Valid connection
      controller.startConnectionDrag(
        nodeId: 'source',
        portId: 'out-1',
        isOutput: true,
        startPoint: const Offset(100, 50),
        nodeBounds: const Rect.fromLTWH(0, 0, 100, 100),
      );

      final validResult = controller.canConnect(
        targetNodeId: 'target',
        targetPortId: 'in-1',
      );
      expect(validResult.allowed, isTrue);
      controller.cancelConnectionDrag();

      // Invalid connection
      controller.startConnectionDrag(
        nodeId: 'source',
        portId: 'out-1',
        isOutput: true,
        startPoint: const Offset(100, 50),
        nodeBounds: const Rect.fromLTWH(0, 0, 100, 100),
      );

      final invalidResult = controller.canConnect(
        targetNodeId: 'incompatible',
        targetPortId: 'in-1',
      );
      expect(invalidResult.allowed, isFalse);
      expect(invalidResult.reason, contains('data sinks'));
      controller.cancelConnectionDrag();
    });
  });

  // ===========================================================================
  // Edge Cases
  // ===========================================================================

  group('Edge Cases', () {
    test('canConnect without active drag returns error', () {
      final result = controller.canConnect(
        targetNodeId: 'any',
        targetPortId: 'any',
      );

      expect(result.allowed, isFalse);
      expect(result.reason, contains('No active connection drag'));
    });

    test('completeConnectionDrag without starting returns null', () {
      final connection = controller.completeConnectionDrag(
        targetNodeId: 'any',
        targetPortId: 'any',
      );

      expect(connection, isNull);
    });

    test('cancelConnectionDrag without starting is safe', () {
      expect(() => controller.cancelConnectionDrag(), returnsNormally);
    });

    test('multiple sequential connection operations work correctly', () {
      final source = createTestNode(
        id: 'source',
        outputPorts: [
          createTestPort(id: 'out-1', type: PortType.output),
          createTestPort(id: 'out-2', type: PortType.output),
        ],
      );
      final target = createTestNode(
        id: 'target',
        inputPorts: [
          createTestPort(id: 'in-1', type: PortType.input),
          createTestPort(id: 'in-2', type: PortType.input),
        ],
      );
      controller.addNode(source);
      controller.addNode(target);

      // First connection
      controller.startConnectionDrag(
        nodeId: 'source',
        portId: 'out-1',
        isOutput: true,
        startPoint: const Offset(100, 50),
        nodeBounds: const Rect.fromLTWH(0, 0, 100, 100),
      );
      controller.completeConnectionDrag(
        targetNodeId: 'target',
        targetPortId: 'in-1',
      );

      // Second connection
      controller.startConnectionDrag(
        nodeId: 'source',
        portId: 'out-2',
        isOutput: true,
        startPoint: const Offset(100, 75),
        nodeBounds: const Rect.fromLTWH(0, 0, 100, 100),
      );
      controller.completeConnectionDrag(
        targetNodeId: 'target',
        targetPortId: 'in-2',
      );

      expect(controller.connectionCount, equals(2));
    });

    test('cancelled connection does not create connection', () {
      final source = createTestNodeWithOutputPort(
        id: 'source',
        portId: 'out-1',
      );
      final target = createTestNodeWithInputPort(id: 'target', portId: 'in-1');
      controller.addNode(source);
      controller.addNode(target);

      controller.startConnectionDrag(
        nodeId: 'source',
        portId: 'out-1',
        isOutput: true,
        startPoint: const Offset(100, 50),
        nodeBounds: const Rect.fromLTWH(0, 0, 100, 100),
      );

      controller.updateConnectionDrag(
        graphPosition: const Offset(200, 50),
        targetNodeId: 'target',
        targetPortId: 'in-1',
      );

      controller.cancelConnectionDrag();

      expect(controller.connectionCount, equals(0));
    });

    test('connection creation is normalized to output->input direction', () {
      final source = createTestNodeWithOutputPort(
        id: 'source',
        portId: 'out-1',
      );
      final target = createTestNodeWithInputPort(id: 'target', portId: 'in-1');
      controller.addNode(source);
      controller.addNode(target);

      // Start from input port (reverse direction)
      controller.startConnectionDrag(
        nodeId: 'target',
        portId: 'in-1',
        isOutput: false,
        startPoint: const Offset(200, 50),
        nodeBounds: const Rect.fromLTWH(200, 0, 100, 100),
      );

      final connection = controller.completeConnectionDrag(
        targetNodeId: 'source',
        targetPortId: 'out-1',
      );

      // Connection should be normalized: source(output) -> target(input)
      expect(connection, isNotNull);
      expect(connection!.sourceNodeId, equals('source'));
      expect(connection.sourcePortId, equals('out-1'));
      expect(connection.targetNodeId, equals('target'));
      expect(connection.targetPortId, equals('in-1'));
    });

    test('getOrphanNodes identifies nodes without connections', () {
      final connected1 = createTestNodeWithOutputPort(
        id: 'connected-1',
        portId: 'out',
      );
      final connected2 = createTestNodeWithInputPort(
        id: 'connected-2',
        portId: 'in',
      );
      final orphan1 = createTestNode(id: 'orphan-1');
      final orphan2 = createTestNode(id: 'orphan-2');

      controller.addNode(connected1);
      controller.addNode(connected2);
      controller.addNode(orphan1);
      controller.addNode(orphan2);

      controller.addConnection(
        createTestConnection(
          sourceNodeId: 'connected-1',
          sourcePortId: 'out',
          targetNodeId: 'connected-2',
          targetPortId: 'in',
        ),
      );

      final orphans = controller.getOrphanNodes();

      expect(orphans.length, equals(2));
      expect(orphans.map((n) => n.id), containsAll(['orphan-1', 'orphan-2']));
    });
  });
}
