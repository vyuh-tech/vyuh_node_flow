@Tags(['behavior'])
library;

import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:vyuh_node_flow/vyuh_node_flow.dart';

import '../../helpers/test_factories.dart';

void main() {
  late NodeFlowController<String> controller;

  setUp(() {
    controller = createTestController();
  });

  tearDown(() {
    controller.dispose();
  });

  group('Basic Connection Creation', () {
    test('create connection between output and input ports', () {
      final node1 = createTestNode(
        id: 'node1',
        position: const Offset(0, 0),
        inputPorts: [],
        outputPorts: [createTestPort(id: 'out1', type: PortType.output)],
      );
      final node2 = createTestNode(
        id: 'node2',
        position: const Offset(200, 0),
        inputPorts: [createTestPort(id: 'in1', type: PortType.input)],
        outputPorts: [],
      );
      controller.addNode(node1);
      controller.addNode(node2);

      controller.createConnection('node1', 'out1', 'node2', 'in1');

      expect(controller.connectionCount, equals(1));
      expect(controller.getConnectionsForNode('node1'), hasLength(1));
      expect(controller.getConnectionsForNode('node2'), hasLength(1));
    });

    test('create connection fires onCreated callback', () {
      final node1 = createTestNode(
        id: 'node1',
        outputPorts: [createTestPort(id: 'out1', type: PortType.output)],
      );
      final node2 = createTestNode(
        id: 'node2',
        inputPorts: [createTestPort(id: 'in1', type: PortType.input)],
      );
      controller.addNode(node1);
      controller.addNode(node2);

      Connection? createdConnection;
      controller.updateEvents(
        NodeFlowEvents<String>(
          connection: ConnectionEvents(onCreated: (c) => createdConnection = c),
        ),
      );

      controller.createConnection('node1', 'out1', 'node2', 'in1');

      expect(createdConnection, isNotNull);
      expect(createdConnection!.sourceNodeId, equals('node1'));
      expect(createdConnection!.targetNodeId, equals('node2'));
    });

    test('addConnection with explicit ID', () {
      final node1 = createTestNode(
        id: 'node1',
        outputPorts: [createTestPort(id: 'out1', type: PortType.output)],
      );
      final node2 = createTestNode(
        id: 'node2',
        inputPorts: [createTestPort(id: 'in1', type: PortType.input)],
      );
      controller.addNode(node1);
      controller.addNode(node2);

      final connection = createTestConnection(
        id: 'my-connection',
        sourceNodeId: 'node1',
        sourcePortId: 'out1',
        targetNodeId: 'node2',
        targetPortId: 'in1',
      );
      controller.addConnection(connection);

      expect(controller.getConnection('my-connection'), isNotNull);
    });
  });

  group('Connection Validation - canStartConnection', () {
    test('allows starting from valid output port', () {
      final node = createTestNode(
        id: 'node1',
        outputPorts: [createTestPort(id: 'out1', type: PortType.output)],
      );
      controller.addNode(node);

      final result = controller.canStartConnection(
        nodeId: 'node1',
        portId: 'out1',
        isOutput: true,
      );

      expect(result.allowed, isTrue);
    });

    test('allows starting from valid input port', () {
      final node = createTestNode(
        id: 'node1',
        inputPorts: [createTestPort(id: 'in1', type: PortType.input)],
      );
      controller.addNode(node);

      final result = controller.canStartConnection(
        nodeId: 'node1',
        portId: 'in1',
        isOutput: false,
      );

      expect(result.allowed, isTrue);
    });

    test('rejects non-existent node', () {
      final result = controller.canStartConnection(
        nodeId: 'non-existent',
        portId: 'out1',
        isOutput: true,
      );

      expect(result.allowed, isFalse);
      expect(result.reason, contains('Node not found'));
    });

    test('rejects non-existent port', () {
      final node = createTestNode(id: 'node1');
      controller.addNode(node);

      final result = controller.canStartConnection(
        nodeId: 'node1',
        portId: 'non-existent',
        isOutput: true,
      );

      expect(result.allowed, isFalse);
      expect(result.reason, contains('Port not found'));
    });

    test('rejects wrong port direction (output flag on input port)', () {
      final node = createTestNode(
        id: 'node1',
        inputPorts: [createTestPort(id: 'in1', type: PortType.input)],
        outputPorts: [],
      );
      controller.addNode(node);

      final result = controller.canStartConnection(
        nodeId: 'node1',
        portId: 'in1',
        isOutput: true, // Claiming input port is output
      );

      expect(result.allowed, isFalse);
      expect(result.reason, contains('cannot emit'));
    });

    test('rejects non-connectable port', () {
      final port = Port(
        id: 'out1',
        name: 'Output 1',
        type: PortType.output,
        isConnectable: false,
      );
      final node = createTestNode(id: 'node1', outputPorts: [port]);
      controller.addNode(node);

      final result = controller.canStartConnection(
        nodeId: 'node1',
        portId: 'out1',
        isOutput: true,
      );

      expect(result.allowed, isFalse);
      expect(result.reason, contains('not connectable'));
    });
  });

  group('Connection Validation - canConnect', () {
    late Node<String> sourceNode;
    late Node<String> targetNode;

    setUp(() {
      sourceNode = createTestNode(
        id: 'source',
        position: const Offset(0, 0),
        outputPorts: [createTestPort(id: 'out1', type: PortType.output)],
      );
      targetNode = createTestNode(
        id: 'target',
        position: const Offset(200, 0),
        inputPorts: [createTestPort(id: 'in1', type: PortType.input)],
      );
      controller.addNode(sourceNode);
      controller.addNode(targetNode);
    });

    test('allows valid output to input connection', () {
      // Start a connection drag first
      controller.startConnectionDrag(
        nodeId: 'source',
        portId: 'out1',
        isOutput: true,
        startPoint: const Offset(100, 50),
        nodeBounds: const Rect.fromLTWH(0, 0, 100, 100),
      );

      final result = controller.canConnect(
        targetNodeId: 'target',
        targetPortId: 'in1',
      );

      expect(result.allowed, isTrue);

      controller.cancelConnectionDrag();
    });

    test('rejects connecting port to itself', () {
      controller.startConnectionDrag(
        nodeId: 'source',
        portId: 'out1',
        isOutput: true,
        startPoint: const Offset(100, 50),
        nodeBounds: const Rect.fromLTWH(0, 0, 100, 100),
      );

      final result = controller.canConnect(
        targetNodeId: 'source',
        targetPortId: 'out1',
      );

      expect(result.allowed, isFalse);
      expect(result.reason, contains('itself'));

      controller.cancelConnectionDrag();
    });

    test('rejects output to output connection', () {
      final targetWithOutput = createTestNode(
        id: 'target2',
        outputPorts: [createTestPort(id: 'out1', type: PortType.output)],
      );
      controller.addNode(targetWithOutput);

      controller.startConnectionDrag(
        nodeId: 'source',
        portId: 'out1',
        isOutput: true,
        startPoint: const Offset(100, 50),
        nodeBounds: const Rect.fromLTWH(0, 0, 100, 100),
      );

      final result = controller.canConnect(
        targetNodeId: 'target2',
        targetPortId: 'out1',
      );

      expect(result.allowed, isFalse);
      expect(result.reason, contains('output to output'));

      controller.cancelConnectionDrag();
    });

    test('rejects input to input connection', () {
      final sourceWithInput = createTestNode(
        id: 'source2',
        inputPorts: [createTestPort(id: 'in1', type: PortType.input)],
      );
      final targetWithInput = createTestNode(
        id: 'target2',
        inputPorts: [createTestPort(id: 'in2', type: PortType.input)],
      );
      controller.addNode(sourceWithInput);
      controller.addNode(targetWithInput);

      controller.startConnectionDrag(
        nodeId: 'source2',
        portId: 'in1',
        isOutput: false,
        startPoint: const Offset(0, 50),
        nodeBounds: const Rect.fromLTWH(0, 0, 100, 100),
      );

      final result = controller.canConnect(
        targetNodeId: 'target2',
        targetPortId: 'in2',
      );

      expect(result.allowed, isFalse);
      expect(result.reason, contains('input to input'));

      controller.cancelConnectionDrag();
    });

    test('rejects duplicate connection', () {
      // Need to use ports with multiConnections=true, otherwise
      // startConnectionDrag removes existing connections automatically.
      // Create fresh nodes with multi-connection ports for this test.
      final multiSourceNode = createTestNode(
        id: 'multi-source',
        position: const Offset(0, 0),
        outputPorts: [
          Port(
            id: 'out1',
            name: 'Output 1',
            type: PortType.output,
            multiConnections: true,
          ),
        ],
      );
      final multiTargetNode = createTestNode(
        id: 'multi-target',
        position: const Offset(200, 0),
        inputPorts: [
          Port(
            id: 'in1',
            name: 'Input 1',
            type: PortType.input,
            multiConnections: true,
          ),
        ],
      );
      controller.addNode(multiSourceNode);
      controller.addNode(multiTargetNode);

      // Create existing connection
      final conn = createTestConnection(
        id: 'existing',
        sourceNodeId: 'multi-source',
        sourcePortId: 'out1',
        targetNodeId: 'multi-target',
        targetPortId: 'in1',
      );
      controller.addConnection(conn);

      // Try to create same connection again
      controller.startConnectionDrag(
        nodeId: 'multi-source',
        portId: 'out1',
        isOutput: true,
        startPoint: const Offset(100, 50),
        nodeBounds: const Rect.fromLTWH(0, 0, 100, 100),
      );

      final result = controller.canConnect(
        targetNodeId: 'multi-target',
        targetPortId: 'in1',
      );

      expect(result.allowed, isFalse);
      expect(result.reason, contains('already exists'));

      controller.cancelConnectionDrag();
    });

    test('rejects connection to non-existent target node', () {
      controller.startConnectionDrag(
        nodeId: 'source',
        portId: 'out1',
        isOutput: true,
        startPoint: const Offset(100, 50),
        nodeBounds: const Rect.fromLTWH(0, 0, 100, 100),
      );

      final result = controller.canConnect(
        targetNodeId: 'non-existent',
        targetPortId: 'in1',
      );

      expect(result.allowed, isFalse);
      expect(result.reason, contains('Target node not found'));

      controller.cancelConnectionDrag();
    });

    test('rejects connection to non-existent target port', () {
      controller.startConnectionDrag(
        nodeId: 'source',
        portId: 'out1',
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

  group('Connection Drag Workflow', () {
    late Node<String> sourceNode;
    late Node<String> targetNode;

    setUp(() {
      sourceNode = createTestNode(
        id: 'source',
        position: const Offset(0, 0),
        outputPorts: [createTestPort(id: 'out1', type: PortType.output)],
      );
      targetNode = createTestNode(
        id: 'target',
        position: const Offset(200, 0),
        inputPorts: [createTestPort(id: 'in1', type: PortType.input)],
      );
      controller.addNode(sourceNode);
      controller.addNode(targetNode);
    });

    test('startConnectionDrag creates temporary connection', () {
      expect(controller.interaction.temporaryConnection.value, isNull);

      controller.startConnectionDrag(
        nodeId: 'source',
        portId: 'out1',
        isOutput: true,
        startPoint: const Offset(100, 50),
        nodeBounds: const Rect.fromLTWH(0, 0, 100, 100),
      );

      expect(controller.interaction.temporaryConnection.value, isNotNull);
      final temp = controller.interaction.temporaryConnection.value!;
      expect(temp.startNodeId, equals('source'));
      expect(temp.startPortId, equals('out1'));
      expect(temp.isStartFromOutput, isTrue);

      controller.cancelConnectionDrag();
    });

    test(
      'startConnectionDrag does not lock canvas directly (session handles locking)',
      () {
        // Note: Canvas locking is now handled by DragSession in the UI layer.
        expect(controller.interaction.canvasLocked.value, isFalse);

        controller.startConnectionDrag(
          nodeId: 'source',
          portId: 'out1',
          isOutput: true,
          startPoint: const Offset(100, 50),
          nodeBounds: const Rect.fromLTWH(0, 0, 100, 100),
        );

        // Controller method does NOT lock canvas - that's the session's job
        expect(controller.interaction.canvasLocked.value, isFalse);

        controller.cancelConnectionDrag();
      },
    );

    test('startConnectionDrag fires onConnectStart callback', () {
      Node<String>? startNode;
      Port? startPort;

      controller.updateEvents(
        NodeFlowEvents<String>(
          connection: ConnectionEvents(
            onConnectStart: (node, port) {
              startNode = node;
              startPort = port;
            },
          ),
        ),
      );

      controller.startConnectionDrag(
        nodeId: 'source',
        portId: 'out1',
        isOutput: true,
        startPoint: const Offset(100, 50),
        nodeBounds: const Rect.fromLTWH(0, 0, 100, 100),
      );

      expect(startNode?.id, equals('source'));
      expect(startPort?.id, equals('out1'));
      expect(startPort?.isOutput, isTrue);

      controller.cancelConnectionDrag();
    });

    test('updateConnectionDrag updates current point', () {
      controller.startConnectionDrag(
        nodeId: 'source',
        portId: 'out1',
        isOutput: true,
        startPoint: const Offset(100, 50),
        nodeBounds: const Rect.fromLTWH(0, 0, 100, 100),
      );

      controller.updateConnectionDrag(graphPosition: const Offset(150, 75));

      final temp = controller.interaction.temporaryConnection.value!;
      expect(temp.currentPoint, equals(const Offset(150, 75)));

      controller.cancelConnectionDrag();
    });

    test('completeConnectionDrag creates connection', () {
      controller.startConnectionDrag(
        nodeId: 'source',
        portId: 'out1',
        isOutput: true,
        startPoint: const Offset(100, 50),
        nodeBounds: const Rect.fromLTWH(0, 0, 100, 100),
      );

      controller.updateConnectionDrag(
        graphPosition: const Offset(200, 50),
        targetNodeId: 'target',
        targetPortId: 'in1',
      );

      final connection = controller.completeConnectionDrag(
        targetNodeId: 'target',
        targetPortId: 'in1',
      );

      expect(connection, isNotNull);
      expect(connection!.sourceNodeId, equals('source'));
      expect(connection.sourcePortId, equals('out1'));
      expect(connection.targetNodeId, equals('target'));
      expect(connection.targetPortId, equals('in1'));
      expect(controller.connectionCount, equals(1));
    });

    test('completeConnectionDrag clears temporary connection', () {
      controller.startConnectionDrag(
        nodeId: 'source',
        portId: 'out1',
        isOutput: true,
        startPoint: const Offset(100, 50),
        nodeBounds: const Rect.fromLTWH(0, 0, 100, 100),
      );

      controller.completeConnectionDrag(
        targetNodeId: 'target',
        targetPortId: 'in1',
      );

      expect(controller.interaction.temporaryConnection.value, isNull);
    });

    test(
      'completeConnectionDrag does not manage canvas lock (session handles locking)',
      () {
        // Note: Canvas locking is now handled by DragSession in the UI layer.
        controller.startConnectionDrag(
          nodeId: 'source',
          portId: 'out1',
          isOutput: true,
          startPoint: const Offset(100, 50),
          nodeBounds: const Rect.fromLTWH(0, 0, 100, 100),
        );

        // Canvas was never locked by startConnectionDrag - session handles that
        expect(controller.interaction.canvasLocked.value, isFalse);

        controller.completeConnectionDrag(
          targetNodeId: 'target',
          targetPortId: 'in1',
        );

        // Canvas lock state unchanged by controller methods
        expect(controller.interaction.canvasLocked.value, isFalse);
      },
    );

    test('completeConnectionDrag fires onConnectEnd with target', () {
      Node<String>? endTargetNode;
      Port? endTargetPort;
      controller.updateEvents(
        NodeFlowEvents<String>(
          connection: ConnectionEvents(
            onConnectEnd: (node, port, _) {
              endTargetNode = node;
              endTargetPort = port;
            },
          ),
        ),
      );

      controller.startConnectionDrag(
        nodeId: 'source',
        portId: 'out1',
        isOutput: true,
        startPoint: const Offset(100, 50),
        nodeBounds: const Rect.fromLTWH(0, 0, 100, 100),
      );

      controller.completeConnectionDrag(
        targetNodeId: 'target',
        targetPortId: 'in1',
      );

      // On success, target node and port are non-null
      expect(endTargetNode, isNotNull);
      expect(endTargetNode?.id, equals('target'));
      expect(endTargetPort, isNotNull);
      expect(endTargetPort?.id, equals('in1'));
    });
  });

  group('Cancel Connection Drag', () {
    test('cancelConnectionDrag clears temporary connection', () {
      final node = createTestNode(
        id: 'node1',
        outputPorts: [createTestPort(id: 'out1', type: PortType.output)],
      );
      controller.addNode(node);

      controller.startConnectionDrag(
        nodeId: 'node1',
        portId: 'out1',
        isOutput: true,
        startPoint: const Offset(100, 50),
        nodeBounds: const Rect.fromLTWH(0, 0, 100, 100),
      );

      expect(controller.interaction.temporaryConnection.value, isNotNull);

      controller.cancelConnectionDrag();

      expect(controller.interaction.temporaryConnection.value, isNull);
    });

    test(
      'cancelConnectionDrag does not manage canvas lock (session handles locking)',
      () {
        // Note: Canvas locking is now handled by DragSession in the UI layer.
        final node = createTestNode(
          id: 'node1',
          outputPorts: [createTestPort(id: 'out1', type: PortType.output)],
        );
        controller.addNode(node);

        controller.startConnectionDrag(
          nodeId: 'node1',
          portId: 'out1',
          isOutput: true,
          startPoint: const Offset(100, 50),
          nodeBounds: const Rect.fromLTWH(0, 0, 100, 100),
        );

        // Canvas was never locked by startConnectionDrag - session handles that
        expect(controller.interaction.canvasLocked.value, isFalse);

        controller.cancelConnectionDrag();

        // Canvas lock state unchanged by controller methods
        expect(controller.interaction.canvasLocked.value, isFalse);
      },
    );

    test('cancelConnectionDrag fires onConnectEnd with null', () {
      final node = createTestNode(
        id: 'node1',
        outputPorts: [createTestPort(id: 'out1', type: PortType.output)],
      );
      controller.addNode(node);

      bool callbackFired = false;
      Node<String>? endTargetNode;
      Port? endTargetPort;
      controller.updateEvents(
        NodeFlowEvents<String>(
          connection: ConnectionEvents(
            onConnectEnd: (node, port, _) {
              callbackFired = true;
              endTargetNode = node;
              endTargetPort = port;
            },
          ),
        ),
      );

      controller.startConnectionDrag(
        nodeId: 'node1',
        portId: 'out1',
        isOutput: true,
        startPoint: const Offset(100, 50),
        nodeBounds: const Rect.fromLTWH(0, 0, 100, 100),
      );

      controller.cancelConnectionDrag();

      // On cancel, callback fires with null values
      expect(callbackFired, isTrue);
      expect(endTargetNode, isNull);
      expect(endTargetPort, isNull);
    });

    test('cancelConnectionDrag does not create connection', () {
      final node1 = createTestNode(
        id: 'node1',
        outputPorts: [createTestPort(id: 'out1', type: PortType.output)],
      );
      final node2 = createTestNode(
        id: 'node2',
        inputPorts: [createTestPort(id: 'in1', type: PortType.input)],
      );
      controller.addNode(node1);
      controller.addNode(node2);

      controller.startConnectionDrag(
        nodeId: 'node1',
        portId: 'out1',
        isOutput: true,
        startPoint: const Offset(100, 50),
        nodeBounds: const Rect.fromLTWH(0, 0, 100, 100),
      );

      controller.updateConnectionDrag(
        graphPosition: const Offset(200, 50),
        targetNodeId: 'node2',
        targetPortId: 'in1',
      );

      controller.cancelConnectionDrag();

      expect(controller.connectionCount, equals(0));
    });
  });

  group('Bidirectional Connection (Input to Output)', () {
    test('connection from input port to output port works', () {
      final sourceNode = createTestNode(
        id: 'source',
        outputPorts: [createTestPort(id: 'out1', type: PortType.output)],
      );
      final targetNode = createTestNode(
        id: 'target',
        inputPorts: [createTestPort(id: 'in1', type: PortType.input)],
      );
      controller.addNode(sourceNode);
      controller.addNode(targetNode);

      // Start from input port (reverse direction)
      controller.startConnectionDrag(
        nodeId: 'target',
        portId: 'in1',
        isOutput: false,
        startPoint: const Offset(200, 50),
        nodeBounds: const Rect.fromLTWH(200, 0, 100, 100),
      );

      // Connect to output port
      final connection = controller.completeConnectionDrag(
        targetNodeId: 'source',
        targetPortId: 'out1',
      );

      // Connection should be normalized: output → input
      expect(connection, isNotNull);
      expect(connection!.sourceNodeId, equals('source'));
      expect(connection.sourcePortId, equals('out1'));
      expect(connection.targetNodeId, equals('target'));
      expect(connection.targetPortId, equals('in1'));
    });
  });

  group('Max Connections Limit', () {
    test('respects maxConnections on target port', () {
      final source1 = createTestNode(
        id: 'source1',
        outputPorts: [createTestPort(id: 'out1', type: PortType.output)],
      );
      final source2 = createTestNode(
        id: 'source2',
        outputPorts: [createTestPort(id: 'out1', type: PortType.output)],
      );
      final target = createTestNode(
        id: 'target',
        inputPorts: [
          Port(
            id: 'in1',
            name: 'Input 1',
            type: PortType.input,
            maxConnections: 1,
            multiConnections: true,
          ),
        ],
      );
      controller.addNode(source1);
      controller.addNode(source2);
      controller.addNode(target);

      // Create first connection
      controller.startConnectionDrag(
        nodeId: 'source1',
        portId: 'out1',
        isOutput: true,
        startPoint: const Offset(100, 50),
        nodeBounds: const Rect.fromLTWH(0, 0, 100, 100),
      );
      controller.completeConnectionDrag(
        targetNodeId: 'target',
        targetPortId: 'in1',
      );
      expect(controller.connectionCount, equals(1));

      // Try second connection to same port
      controller.startConnectionDrag(
        nodeId: 'source2',
        portId: 'out1',
        isOutput: true,
        startPoint: const Offset(100, 150),
        nodeBounds: const Rect.fromLTWH(0, 100, 100, 100),
      );

      final result = controller.canConnect(
        targetNodeId: 'target',
        targetPortId: 'in1',
      );

      expect(result.allowed, isFalse);
      expect(result.reason, contains('maximum connections'));

      controller.cancelConnectionDrag();
    });
  });

  group('Custom Validation Callbacks', () {
    test('onBeforeStart can reject connection start', () {
      final node = createTestNode(
        id: 'node1',
        outputPorts: [createTestPort(id: 'out1', type: PortType.output)],
      );
      controller.addNode(node);

      controller.updateEvents(
        NodeFlowEvents<String>(
          connection: ConnectionEvents<String>(
            onBeforeStart: (context) {
              return const ConnectionValidationResult.deny(
                reason: 'Custom rejection',
              );
            },
          ),
        ),
      );

      final result = controller.canStartConnection(
        nodeId: 'node1',
        portId: 'out1',
        isOutput: true,
      );

      expect(result.allowed, isFalse);
      expect(result.reason, contains('Custom rejection'));
    });

    test('onBeforeComplete can reject connection completion', () {
      final source = createTestNode(
        id: 'source',
        outputPorts: [createTestPort(id: 'out1', type: PortType.output)],
      );
      final target = createTestNode(
        id: 'target',
        inputPorts: [createTestPort(id: 'in1', type: PortType.input)],
      );
      controller.addNode(source);
      controller.addNode(target);

      controller.updateEvents(
        NodeFlowEvents<String>(
          connection: ConnectionEvents<String>(
            onBeforeComplete: (context) {
              return const ConnectionValidationResult.deny(
                reason: 'Not allowed by policy',
              );
            },
          ),
        ),
      );

      controller.startConnectionDrag(
        nodeId: 'source',
        portId: 'out1',
        isOutput: true,
        startPoint: const Offset(100, 50),
        nodeBounds: const Rect.fromLTWH(0, 0, 100, 100),
      );

      final result = controller.canConnect(
        targetNodeId: 'target',
        targetPortId: 'in1',
      );

      expect(result.allowed, isFalse);
      expect(result.reason, contains('Not allowed by policy'));

      controller.cancelConnectionDrag();
    });

    test('onBeforeComplete receives correct context', () {
      final source = createTestNode(
        id: 'source',
        outputPorts: [createTestPort(id: 'out1', type: PortType.output)],
      );
      final target = createTestNode(
        id: 'target',
        inputPorts: [createTestPort(id: 'in1', type: PortType.input)],
      );
      controller.addNode(source);
      controller.addNode(target);

      ConnectionCompleteContext<String>? capturedContext;
      controller.updateEvents(
        NodeFlowEvents<String>(
          connection: ConnectionEvents<String>(
            onBeforeComplete: (context) {
              capturedContext = context;
              return const ConnectionValidationResult.allow();
            },
          ),
        ),
      );

      controller.startConnectionDrag(
        nodeId: 'source',
        portId: 'out1',
        isOutput: true,
        startPoint: const Offset(100, 50),
        nodeBounds: const Rect.fromLTWH(0, 0, 100, 100),
      );

      controller.canConnect(targetNodeId: 'target', targetPortId: 'in1');

      expect(capturedContext, isNotNull);
      expect(capturedContext!.sourceNode.id, equals('source'));
      expect(capturedContext!.sourcePort.id, equals('out1'));
      expect(capturedContext!.targetNode.id, equals('target'));
      expect(capturedContext!.targetPort.id, equals('in1'));

      controller.cancelConnectionDrag();
    });
  });

  group('Single Connection Port (Replacement Behavior)', () {
    test('new connection replaces existing on single-connection port', () {
      final source1 = createTestNode(
        id: 'source1',
        outputPorts: [createTestPort(id: 'out1', type: PortType.output)],
      );
      final source2 = createTestNode(
        id: 'source2',
        outputPorts: [createTestPort(id: 'out1', type: PortType.output)],
      );
      final target = createTestNode(
        id: 'target',
        inputPorts: [
          Port(
            id: 'in1',
            name: 'Input 1',
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
        nodeId: 'source1',
        portId: 'out1',
        isOutput: true,
        startPoint: const Offset(100, 50),
        nodeBounds: const Rect.fromLTWH(0, 0, 100, 100),
      );
      final conn1 = controller.completeConnectionDrag(
        targetNodeId: 'target',
        targetPortId: 'in1',
      );
      expect(controller.connectionCount, equals(1));
      expect(conn1!.sourceNodeId, equals('source1'));

      // Create second connection - should replace first
      controller.startConnectionDrag(
        nodeId: 'source2',
        portId: 'out1',
        isOutput: true,
        startPoint: const Offset(100, 150),
        nodeBounds: const Rect.fromLTWH(0, 100, 100, 100),
      );
      final conn2 = controller.completeConnectionDrag(
        targetNodeId: 'target',
        targetPortId: 'in1',
      );

      // Should still have only 1 connection, from source2
      expect(controller.connectionCount, equals(1));
      expect(conn2!.sourceNodeId, equals('source2'));

      // Original connection should be gone
      expect(controller.getConnection(conn1.id), isNull);
    });
  });

  group('Edge Cases', () {
    test('completeConnectionDrag without starting returns null', () {
      final connection = controller.completeConnectionDrag(
        targetNodeId: 'target',
        targetPortId: 'in1',
      );

      expect(connection, isNull);
    });

    test('cancelConnectionDrag without starting is safe', () {
      expect(() => controller.cancelConnectionDrag(), returnsNormally);
    });

    test('canConnect without active drag returns error', () {
      final result = controller.canConnect(
        targetNodeId: 'target',
        targetPortId: 'in1',
      );

      expect(result.allowed, isFalse);
      expect(result.reason, contains('No active connection drag'));
    });

    test('multiple sequential connection drags work', () {
      final source = createTestNode(
        id: 'source',
        outputPorts: [
          createTestPort(id: 'out1', type: PortType.output),
          createTestPort(id: 'out2', type: PortType.output),
        ],
      );
      final target = createTestNode(
        id: 'target',
        inputPorts: [
          createTestPort(id: 'in1', type: PortType.input),
          createTestPort(id: 'in2', type: PortType.input),
        ],
      );
      controller.addNode(source);
      controller.addNode(target);

      // First connection
      controller.startConnectionDrag(
        nodeId: 'source',
        portId: 'out1',
        isOutput: true,
        startPoint: const Offset(100, 50),
        nodeBounds: const Rect.fromLTWH(0, 0, 100, 100),
      );
      controller.completeConnectionDrag(
        targetNodeId: 'target',
        targetPortId: 'in1',
      );

      // Second connection
      controller.startConnectionDrag(
        nodeId: 'source',
        portId: 'out2',
        isOutput: true,
        startPoint: const Offset(100, 75),
        nodeBounds: const Rect.fromLTWH(0, 0, 100, 100),
      );
      controller.completeConnectionDrag(
        targetNodeId: 'target',
        targetPortId: 'in2',
      );

      expect(controller.connectionCount, equals(2));
    });
  });
}
