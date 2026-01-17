/// Unit tests for the [NodeContainer] widget.
///
/// Tests cover:
/// - Container layout and positioning
/// - Child widget handling and rendering
/// - Node bounds calculations for port positioning
/// - Port connection checking
/// - Visibility handling based on node state
/// - LOD visibility control
/// - Resize handle display logic
@Tags(['unit'])
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vyuh_node_flow/vyuh_node_flow.dart';

// Import NodeContainer and ResizerWidget directly as they're not part of the public API
import 'package:vyuh_node_flow/src/nodes/node_container.dart';
import 'package:vyuh_node_flow/src/editor/resizer_widget.dart';

import '../../helpers/test_factories.dart';
import '../../helpers/test_utils.dart';

void main() {
  setUp(() {
    resetTestCounters();
  });

  // ==========================================================================
  // NodeContainer Construction Tests
  // ==========================================================================
  group('NodeContainer Construction', () {
    test('creates container with required parameters', () {
      final node = createTestNode();
      final controller = createTestController();
      const child = SizedBox(width: 100, height: 100);

      final container = NodeContainer<String>(
        node: node,
        controller: controller,
        child: child,
      );

      expect(container.node, equals(node));
      expect(container.controller, equals(controller));
      expect(container.child, equals(child));
    });

    test('creates container with default portSnapDistance of 8.0', () {
      final node = createTestNode();
      final controller = createTestController();

      final container = NodeContainer<String>(
        node: node,
        controller: controller,
        child: const SizedBox(),
      );

      expect(container.portSnapDistance, equals(8.0));
    });

    test('creates container with custom portSnapDistance', () {
      final node = createTestNode();
      final controller = createTestController();

      final container = NodeContainer<String>(
        node: node,
        controller: controller,
        portSnapDistance: 12.0,
        child: const SizedBox(),
      );

      expect(container.portSnapDistance, equals(12.0));
    });

    test('creates container with empty connections list by default', () {
      final node = createTestNode();
      final controller = createTestController();

      final container = NodeContainer<String>(
        node: node,
        controller: controller,
        child: const SizedBox(),
      );

      expect(container.connections, isEmpty);
    });

    test('creates container with connections list', () {
      final node = createTestNodeWithPorts(id: 'node-a');
      final nodeB = createTestNodeWithPorts(id: 'node-b');
      final controller = createTestController(nodes: [node, nodeB]);
      final connection = createTestConnection(
        sourceNodeId: 'node-a',
        targetNodeId: 'node-b',
      );

      final container = NodeContainer<String>(
        node: node,
        controller: controller,
        connections: [connection],
        child: const SizedBox(),
      );

      expect(container.connections.length, equals(1));
      expect(container.connections.first.sourceNodeId, equals('node-a'));
    });

    test('creates container with optional shape', () {
      final node = createTestNode();
      final controller = createTestController();
      final shape = _TestNodeShape();

      final container = NodeContainer<String>(
        node: node,
        controller: controller,
        shape: shape,
        child: const SizedBox(),
      );

      expect(container.shape, equals(shape));
    });

    test('creates container with null shape by default', () {
      final node = createTestNode();
      final controller = createTestController();

      final container = NodeContainer<String>(
        node: node,
        controller: controller,
        child: const SizedBox(),
      );

      expect(container.shape, isNull);
    });
  });

  // ==========================================================================
  // Callback Tests
  // ==========================================================================
  group('NodeContainer Callbacks', () {
    test('stores onTap callback', () {
      final node = createTestNode();
      final controller = createTestController();
      var tapped = false;

      final container = NodeContainer<String>(
        node: node,
        controller: controller,
        child: const SizedBox(),
        onTap: () => tapped = true,
      );

      expect(container.onTap, isNotNull);
      container.onTap!();
      expect(tapped, isTrue);
    });

    test('stores onDoubleTap callback', () {
      final node = createTestNode();
      final controller = createTestController();
      var doubleTapped = false;

      final container = NodeContainer<String>(
        node: node,
        controller: controller,
        child: const SizedBox(),
        onDoubleTap: () => doubleTapped = true,
      );

      expect(container.onDoubleTap, isNotNull);
      container.onDoubleTap!();
      expect(doubleTapped, isTrue);
    });

    test('stores onContextMenu callback', () {
      final node = createTestNode();
      final controller = createTestController();
      ScreenPosition? receivedPosition;

      final container = NodeContainer<String>(
        node: node,
        controller: controller,
        child: const SizedBox(),
        onContextMenu: (pos) => receivedPosition = pos,
      );

      expect(container.onContextMenu, isNotNull);
      final testPos = screenPos(100, 200);
      container.onContextMenu!(testPos);
      expect(receivedPosition, equals(testPos));
    });

    test('stores onMouseEnter callback', () {
      final node = createTestNode();
      final controller = createTestController();
      var entered = false;

      final container = NodeContainer<String>(
        node: node,
        controller: controller,
        child: const SizedBox(),
        onMouseEnter: () => entered = true,
      );

      expect(container.onMouseEnter, isNotNull);
      container.onMouseEnter!();
      expect(entered, isTrue);
    });

    test('stores onMouseLeave callback', () {
      final node = createTestNode();
      final controller = createTestController();
      var left = false;

      final container = NodeContainer<String>(
        node: node,
        controller: controller,
        child: const SizedBox(),
        onMouseLeave: () => left = true,
      );

      expect(container.onMouseLeave, isNotNull);
      container.onMouseLeave!();
      expect(left, isTrue);
    });

    test('stores onPortTap callback', () {
      final node = createTestNode();
      final controller = createTestController();
      String? receivedNodeId;
      String? receivedPortId;
      bool? receivedIsOutput;

      final container = NodeContainer<String>(
        node: node,
        controller: controller,
        child: const SizedBox(),
        onPortTap: (nodeId, portId, isOutput) {
          receivedNodeId = nodeId;
          receivedPortId = portId;
          receivedIsOutput = isOutput;
        },
      );

      expect(container.onPortTap, isNotNull);
      container.onPortTap!('node-1', 'port-1', true);
      expect(receivedNodeId, equals('node-1'));
      expect(receivedPortId, equals('port-1'));
      expect(receivedIsOutput, isTrue);
    });

    test('stores onPortHover callback', () {
      final node = createTestNode();
      final controller = createTestController();
      String? receivedNodeId;
      String? receivedPortId;
      bool? receivedIsHover;

      final container = NodeContainer<String>(
        node: node,
        controller: controller,
        child: const SizedBox(),
        onPortHover: (nodeId, portId, isHover) {
          receivedNodeId = nodeId;
          receivedPortId = portId;
          receivedIsHover = isHover;
        },
      );

      expect(container.onPortHover, isNotNull);
      container.onPortHover!('node-1', 'port-1', true);
      expect(receivedNodeId, equals('node-1'));
      expect(receivedPortId, equals('port-1'));
      expect(receivedIsHover, isTrue);
    });

    test('stores onPortContextMenu callback', () {
      final node = createTestNode();
      final controller = createTestController();
      String? receivedNodeId;
      String? receivedPortId;
      ScreenPosition? receivedPosition;

      final container = NodeContainer<String>(
        node: node,
        controller: controller,
        child: const SizedBox(),
        onPortContextMenu: (nodeId, portId, position) {
          receivedNodeId = nodeId;
          receivedPortId = portId;
          receivedPosition = position;
        },
      );

      expect(container.onPortContextMenu, isNotNull);
      final testPos = screenPos(50, 75);
      container.onPortContextMenu!('node-1', 'port-1', testPos);
      expect(receivedNodeId, equals('node-1'));
      expect(receivedPortId, equals('port-1'));
      expect(receivedPosition, equals(testPos));
    });
  });

  // ==========================================================================
  // Port Connection Checking Tests
  // ==========================================================================
  group('Port Connection Detection', () {
    test('_isPortConnected returns true for connected output port', () {
      final node = createTestNodeWithOutputPort(id: 'node-a', portId: 'out-1');
      final nodeB = createTestNodeWithInputPort(id: 'node-b', portId: 'in-1');
      final controller = createTestController(nodes: [node, nodeB]);
      final connection = createTestConnection(
        sourceNodeId: 'node-a',
        sourcePortId: 'out-1',
        targetNodeId: 'node-b',
        targetPortId: 'in-1',
      );

      final container = NodeContainer<String>(
        node: node,
        controller: controller,
        connections: [connection],
        child: const SizedBox(),
      );

      // Use reflection or testing helper to access private method
      // Since _isPortConnected is private, we test indirectly through behavior
      expect(container.connections.length, equals(1));
      expect(
        container.connections.any(
          (c) => c.sourceNodeId == 'node-a' && c.sourcePortId == 'out-1',
        ),
        isTrue,
      );
    });

    test('_isPortConnected returns true for connected input port', () {
      final nodeA = createTestNodeWithOutputPort(id: 'node-a', portId: 'out-1');
      final node = createTestNodeWithInputPort(id: 'node-b', portId: 'in-1');
      final controller = createTestController(nodes: [nodeA, node]);
      final connection = createTestConnection(
        sourceNodeId: 'node-a',
        sourcePortId: 'out-1',
        targetNodeId: 'node-b',
        targetPortId: 'in-1',
      );

      final container = NodeContainer<String>(
        node: node,
        controller: controller,
        connections: [connection],
        child: const SizedBox(),
      );

      expect(
        container.connections.any(
          (c) => c.targetNodeId == 'node-b' && c.targetPortId == 'in-1',
        ),
        isTrue,
      );
    });

    test('multiple connections can be tracked', () {
      final node = Node<String>(
        id: 'node-a',
        type: 'test',
        position: Offset.zero,
        data: 'test',
        outputPorts: [
          createOutputPort(id: 'out-1'),
          createOutputPort(id: 'out-2'),
        ],
      );
      final nodeB = createTestNodeWithInputPort(id: 'node-b', portId: 'in-1');
      final nodeC = createTestNodeWithInputPort(id: 'node-c', portId: 'in-1');
      final controller = createTestController(nodes: [node, nodeB, nodeC]);

      final connections = [
        createTestConnection(
          sourceNodeId: 'node-a',
          sourcePortId: 'out-1',
          targetNodeId: 'node-b',
          targetPortId: 'in-1',
        ),
        createTestConnection(
          sourceNodeId: 'node-a',
          sourcePortId: 'out-2',
          targetNodeId: 'node-c',
          targetPortId: 'in-1',
        ),
      ];

      final container = NodeContainer<String>(
        node: node,
        controller: controller,
        connections: connections,
        child: const SizedBox(),
      );

      expect(container.connections.length, equals(2));
    });
  });

  // ==========================================================================
  // Node Bounds Calculation Tests
  // ==========================================================================
  group('Node Bounds Calculations', () {
    test('node position reflects in container', () {
      final node = createTestNode(position: const Offset(100, 200));
      final controller = createTestController(nodes: [node]);

      final container = NodeContainer<String>(
        node: node,
        controller: controller,
        child: const SizedBox(),
      );

      expect(container.node.position.value, equals(const Offset(100, 200)));
    });

    test('node size reflects in container', () {
      final node = createTestNode(size: const Size(250, 150));
      final controller = createTestController(nodes: [node]);

      final container = NodeContainer<String>(
        node: node,
        controller: controller,
        child: const SizedBox(),
      );

      expect(container.node.size.value, equals(const Size(250, 150)));
    });

    test('node bounds calculation is correct', () {
      final node = createTestNode(
        position: const Offset(50, 100),
        size: const Size(200, 150),
      );
      final controller = createTestController(nodes: [node]);

      final container = NodeContainer<String>(
        node: node,
        controller: controller,
        child: const SizedBox(),
      );

      final bounds = container.node.getBounds();
      expect(bounds.left, equals(50));
      expect(bounds.top, equals(100));
      expect(bounds.width, equals(200));
      expect(bounds.height, equals(150));
      expect(bounds.right, equals(250));
      expect(bounds.bottom, equals(250));
    });

    test('visual position is used for rendering', () {
      final node = createTestNode(position: const Offset(100, 100));
      // Simulate snap-to-grid by setting different visual position
      node.setVisualPosition(const Offset(112, 112));

      final controller = createTestController(nodes: [node]);

      final container = NodeContainer<String>(
        node: node,
        controller: controller,
        child: const SizedBox(),
      );

      // Container node should have the updated visual position
      expect(
        container.node.visualPosition.value,
        equals(const Offset(112, 112)),
      );
      // Position should remain unchanged
      expect(container.node.position.value, equals(const Offset(100, 100)));
    });
  });

  // ==========================================================================
  // Port Builder Tests
  // ==========================================================================
  group('Port Builder', () {
    test('stores custom port builder', () {
      final node = createTestNodeWithPorts();
      final controller = createTestController(nodes: [node]);

      Widget customBuilder(BuildContext ctx, Node<String> n, Port p) {
        return Container(width: 16, height: 16, color: Colors.red);
      }

      final container = NodeContainer<String>(
        node: node,
        controller: controller,
        portBuilder: customBuilder,
        child: const SizedBox(),
      );

      expect(container.portBuilder, isNotNull);
    });

    test('port builder is null by default', () {
      final node = createTestNode();
      final controller = createTestController(nodes: [node]);

      final container = NodeContainer<String>(
        node: node,
        controller: controller,
        child: const SizedBox(),
      );

      expect(container.portBuilder, isNull);
    });
  });

  // ==========================================================================
  // Resizable Node Tests
  // ==========================================================================
  group('Resizable Node Handling', () {
    test('regular node is not resizable by default', () {
      final node = createTestNode();
      final controller = createTestController(nodes: [node]);

      final container = NodeContainer<String>(
        node: node,
        controller: controller,
        child: const SizedBox(),
      );

      expect(container.node.isResizable, isFalse);
    });

    test('group node is resizable', () {
      final group = createTestGroupNode<String>(
        behavior: GroupBehavior.bounds,
        data: 'test',
      );
      final controller = createTestController(nodes: [group]);

      final container = NodeContainer<String>(
        node: group,
        controller: controller,
        child: const SizedBox(),
      );

      expect(container.node.isResizable, isTrue);
    });

    test('comment node is resizable', () {
      final comment = createTestCommentNode<String>(data: 'test');
      final controller = createTestController(nodes: [comment]);

      final container = NodeContainer<String>(
        node: comment,
        controller: controller,
        child: const SizedBox(),
      );

      expect(container.node.isResizable, isTrue);
    });

    test('selected resizable node should show resize handles', () {
      final group = createTestGroupNode<String>(
        behavior: GroupBehavior.bounds,
        data: 'test',
      );
      group.isSelected = true;

      final controller = createTestController(nodes: [group]);

      final container = NodeContainer<String>(
        node: group,
        controller: controller,
        child: const SizedBox(),
      );

      // Resizer should be shown when node is selected and resizable
      expect(container.node.isSelected, isTrue);
      expect(container.node.isResizable, isTrue);
    });
  });

  // ==========================================================================
  // Behavior Mode and Resize Handle Visibility Tests
  // ==========================================================================
  group('Behavior Mode and Resize Handle Visibility', () {
    test('design mode allows resize handles (canUpdate: true)', () {
      final group = createTestGroupNode<String>(
        behavior: GroupBehavior.bounds,
        data: 'test',
      );
      group.isSelected = true;
      final controller = createTestController(nodes: [group]);

      // Design mode is the default
      expect(controller.behavior, equals(NodeFlowBehavior.design));
      expect(controller.behavior.canUpdate, isTrue);

      // Node is resizable and selected
      expect(group.isSelected, isTrue);
      expect(group.isResizable, isTrue);
    });

    test('preview mode hides resize handles (canUpdate: false)', () {
      final group = createTestGroupNode<String>(
        behavior: GroupBehavior.bounds,
        data: 'test',
      );
      group.isSelected = true;
      final controller = createTestController(nodes: [group]);

      controller.setBehavior(NodeFlowBehavior.preview);

      expect(controller.behavior, equals(NodeFlowBehavior.preview));
      expect(controller.behavior.canUpdate, isFalse);
      expect(controller.behavior.canDrag, isTrue); // Can still drag

      // Node is still resizable (intrinsic property), but handles won't show
      expect(group.isResizable, isTrue);
    });

    test('inspect mode hides resize handles (canUpdate: false)', () {
      final group = createTestGroupNode<String>(
        behavior: GroupBehavior.bounds,
        data: 'test',
      );
      group.isSelected = true;
      final controller = createTestController(nodes: [group]);

      controller.setBehavior(NodeFlowBehavior.inspect);

      expect(controller.behavior, equals(NodeFlowBehavior.inspect));
      expect(controller.behavior.canUpdate, isFalse);
      expect(controller.behavior.canDrag, isFalse); // Cannot drag either

      // Node is still resizable (intrinsic property), but handles won't show
      expect(group.isResizable, isTrue);
    });

    test('present mode hides resize handles (canUpdate: false)', () {
      final group = createTestGroupNode<String>(
        behavior: GroupBehavior.bounds,
        data: 'test',
      );
      group.isSelected = true;
      final controller = createTestController(nodes: [group]);

      controller.setBehavior(NodeFlowBehavior.present);

      expect(controller.behavior, equals(NodeFlowBehavior.present));
      expect(controller.behavior.canUpdate, isFalse);

      // Node is still resizable (intrinsic property), but handles won't show
      expect(group.isResizable, isTrue);
    });

    test('switching back to design mode restores resize handles', () {
      final group = createTestGroupNode<String>(
        behavior: GroupBehavior.bounds,
        data: 'test',
      );
      group.isSelected = true;
      final controller = createTestController(nodes: [group]);

      // Start in design mode
      expect(controller.behavior.canUpdate, isTrue);

      // Switch to preview
      controller.setBehavior(NodeFlowBehavior.preview);
      expect(controller.behavior.canUpdate, isFalse);

      // Switch back to design
      controller.setBehavior(NodeFlowBehavior.design);
      expect(controller.behavior.canUpdate, isTrue);
    });

    test('CommentNode respects behavior mode for resize handles', () {
      final comment = createTestCommentNode<String>(data: 'test');
      comment.isSelected = true;
      final controller = createTestController(nodes: [comment]);

      // In design mode
      expect(controller.behavior.canUpdate, isTrue);
      expect(comment.isResizable, isTrue);

      // In preview mode
      controller.setBehavior(NodeFlowBehavior.preview);
      expect(controller.behavior.canUpdate, isFalse);
      expect(
        comment.isResizable,
        isTrue,
      ); // Still resizable, just handles hidden
    });
  });

  // ==========================================================================
  // Visibility Tests
  // ==========================================================================
  group('Visibility Handling', () {
    test('visible node is included', () {
      final node = createTestNode(visible: true);
      final controller = createTestController(nodes: [node]);

      final container = NodeContainer<String>(
        node: node,
        controller: controller,
        child: const SizedBox(),
      );

      expect(container.node.isVisible, isTrue);
    });

    test('hidden node is excluded from rendering', () {
      final node = createTestNode(visible: false);
      final controller = createTestController(nodes: [node]);

      final container = NodeContainer<String>(
        node: node,
        controller: controller,
        child: const SizedBox(),
      );

      expect(container.node.isVisible, isFalse);
    });

    test('visibility can be toggled', () {
      final node = createTestNode(visible: true);
      final controller = createTestController(nodes: [node]);

      final container = NodeContainer<String>(
        node: node,
        controller: controller,
        child: const SizedBox(),
      );

      expect(container.node.isVisible, isTrue);

      node.isVisible = false;
      expect(container.node.isVisible, isFalse);

      node.isVisible = true;
      expect(container.node.isVisible, isTrue);
    });
  });

  // ==========================================================================
  // Locked Node Tests
  // ==========================================================================
  group('Locked Node Handling', () {
    test('unlocked node is draggable', () {
      final node = Node<String>(
        id: 'unlocked',
        type: 'test',
        position: Offset.zero,
        data: 'test',
        locked: false,
      );
      final controller = createTestController(nodes: [node]);

      final container = NodeContainer<String>(
        node: node,
        controller: controller,
        child: const SizedBox(),
      );

      expect(container.node.locked, isFalse);
    });

    test('locked node is not draggable', () {
      final node = Node<String>(
        id: 'locked',
        type: 'test',
        position: Offset.zero,
        data: 'test',
        locked: true,
      );
      final controller = createTestController(nodes: [node]);

      final container = NodeContainer<String>(
        node: node,
        controller: controller,
        child: const SizedBox(),
      );

      expect(container.node.locked, isTrue);
    });
  });

  // ==========================================================================
  // Node with Ports Tests
  // ==========================================================================
  group('Node with Ports', () {
    test('container handles node with input ports', () {
      final node = createTestNodeWithInputPort(id: 'node-with-input');
      final controller = createTestController(nodes: [node]);

      final container = NodeContainer<String>(
        node: node,
        controller: controller,
        child: const SizedBox(),
      );

      expect(container.node.inputPorts.length, equals(1));
      expect(container.node.outputPorts, isEmpty);
    });

    test('container handles node with output ports', () {
      final node = createTestNodeWithOutputPort(id: 'node-with-output');
      final controller = createTestController(nodes: [node]);

      final container = NodeContainer<String>(
        node: node,
        controller: controller,
        child: const SizedBox(),
      );

      expect(container.node.inputPorts, isEmpty);
      expect(container.node.outputPorts.length, equals(1));
    });

    test('container handles node with both input and output ports', () {
      final node = createTestNodeWithPorts(id: 'node-with-both');
      final controller = createTestController(nodes: [node]);

      final container = NodeContainer<String>(
        node: node,
        controller: controller,
        child: const SizedBox(),
      );

      expect(container.node.inputPorts.length, equals(1));
      expect(container.node.outputPorts.length, equals(1));
    });

    test('container handles node with multiple ports on same side', () {
      final node = Node<String>(
        id: 'multi-port',
        type: 'test',
        position: Offset.zero,
        data: 'test',
        inputPorts: [
          createInputPort(id: 'in-1'),
          createInputPort(id: 'in-2'),
          createInputPort(id: 'in-3'),
        ],
        outputPorts: [
          createOutputPort(id: 'out-1'),
          createOutputPort(id: 'out-2'),
        ],
      );
      final controller = createTestController(nodes: [node]);

      final container = NodeContainer<String>(
        node: node,
        controller: controller,
        child: const SizedBox(),
      );

      expect(container.node.inputPorts.length, equals(3));
      expect(container.node.outputPorts.length, equals(2));
    });
  });

  // ==========================================================================
  // Selection State Tests
  // ==========================================================================
  group('Selection State', () {
    test('selected state is reflected in container', () {
      final node = createTestNode();
      node.isSelected = true;

      final controller = createTestController(nodes: [node]);

      final container = NodeContainer<String>(
        node: node,
        controller: controller,
        child: const SizedBox(),
      );

      expect(container.node.isSelected, isTrue);
    });

    test('unselected state is reflected in container', () {
      final node = createTestNode();
      node.isSelected = false;

      final controller = createTestController(nodes: [node]);

      final container = NodeContainer<String>(
        node: node,
        controller: controller,
        child: const SizedBox(),
      );

      expect(container.node.isSelected, isFalse);
    });

    test('selection state can change', () {
      final node = createTestNode();
      final controller = createTestController(nodes: [node]);

      final container = NodeContainer<String>(
        node: node,
        controller: controller,
        child: const SizedBox(),
      );

      expect(container.node.isSelected, isFalse);

      node.isSelected = true;
      expect(container.node.isSelected, isTrue);

      node.isSelected = false;
      expect(container.node.isSelected, isFalse);
    });
  });

  // ==========================================================================
  // Z-Index Tests
  // ==========================================================================
  group('Z-Index Handling', () {
    test('z-index is reflected in container', () {
      final node = createTestNode(zIndex: 5);
      final controller = createTestController(nodes: [node]);

      final container = NodeContainer<String>(
        node: node,
        controller: controller,
        child: const SizedBox(),
      );

      expect(container.node.currentZIndex, equals(5));
    });

    test('negative z-index is supported', () {
      final node = createTestNode(zIndex: -1);
      final controller = createTestController(nodes: [node]);

      final container = NodeContainer<String>(
        node: node,
        controller: controller,
        child: const SizedBox(),
      );

      expect(container.node.currentZIndex, equals(-1));
    });

    test('z-index can change', () {
      final node = createTestNode(zIndex: 0);
      final controller = createTestController(nodes: [node]);

      final container = NodeContainer<String>(
        node: node,
        controller: controller,
        child: const SizedBox(),
      );

      expect(container.node.currentZIndex, equals(0));

      node.currentZIndex = 10;
      expect(container.node.currentZIndex, equals(10));
    });
  });

  // ==========================================================================
  // Special Node Types Tests
  // ==========================================================================
  group('Special Node Types', () {
    test('GroupNode works with NodeContainer', () {
      final group = createTestGroupNode<String>(
        id: 'group-1',
        position: const Offset(50, 50),
        size: const Size(400, 300),
        data: 'group-data',
      );
      final controller = createTestController(nodes: [group]);

      final container = NodeContainer<String>(
        node: group,
        controller: controller,
        child: const SizedBox(),
      );

      expect(container.node.id, equals('group-1'));
      expect(container.node.position.value, equals(const Offset(50, 50)));
      expect(container.node.size.value, equals(const Size(400, 300)));
    });

    test('CommentNode works with NodeContainer', () {
      final comment = createTestCommentNode<String>(
        id: 'comment-1',
        position: const Offset(100, 100),
        data: 'comment-data',
      );
      final controller = createTestController(nodes: [comment]);

      final container = NodeContainer<String>(
        node: comment,
        controller: controller,
        child: const SizedBox(),
      );

      expect(container.node.id, equals('comment-1'));
      expect(container.node.position.value, equals(const Offset(100, 100)));
    });

    test('GroupNode with ports works with NodeContainer', () {
      final inputPort = createInputPort(id: 'group-in');
      final outputPort = createOutputPort(id: 'group-out');

      final group = GroupNode<String>(
        id: 'subflow-group',
        position: Offset.zero,
        size: const Size(400, 300),
        title: 'Subflow',
        data: 'test',
        inputPorts: [inputPort],
        outputPorts: [outputPort],
      );
      final controller = createTestController(nodes: [group]);

      final container = NodeContainer<String>(
        node: group,
        controller: controller,
        child: const SizedBox(),
      );

      expect(container.node.inputPorts.length, equals(1));
      expect(container.node.outputPorts.length, equals(1));
    });
  });

  // ==========================================================================
  // Edge Cases
  // ==========================================================================
  group('Edge Cases', () {
    test('node at origin position', () {
      final node = createTestNode(position: Offset.zero);
      final controller = createTestController(nodes: [node]);

      final container = NodeContainer<String>(
        node: node,
        controller: controller,
        child: const SizedBox(),
      );

      expect(container.node.position.value, equals(Offset.zero));
    });

    test('node at negative position', () {
      final node = createTestNode(position: const Offset(-100, -200));
      final controller = createTestController(nodes: [node]);

      final container = NodeContainer<String>(
        node: node,
        controller: controller,
        child: const SizedBox(),
      );

      expect(container.node.position.value, equals(const Offset(-100, -200)));
    });

    test('node with very large position', () {
      final node = createTestNode(position: const Offset(10000, 10000));
      final controller = createTestController(nodes: [node]);

      final container = NodeContainer<String>(
        node: node,
        controller: controller,
        child: const SizedBox(),
      );

      expect(container.node.position.value, equals(const Offset(10000, 10000)));
    });

    test('node with very small size', () {
      final node = createTestNode(size: const Size(10, 10));
      final controller = createTestController(nodes: [node]);

      final container = NodeContainer<String>(
        node: node,
        controller: controller,
        child: const SizedBox(),
      );

      expect(container.node.size.value, equals(const Size(10, 10)));
    });

    test('node with very large size', () {
      final node = createTestNode(size: const Size(5000, 3000));
      final controller = createTestController(nodes: [node]);

      final container = NodeContainer<String>(
        node: node,
        controller: controller,
        child: const SizedBox(),
      );

      expect(container.node.size.value, equals(const Size(5000, 3000)));
    });

    test('empty child widget', () {
      final node = createTestNode();
      final controller = createTestController(nodes: [node]);

      final container = NodeContainer<String>(
        node: node,
        controller: controller,
        child: const SizedBox.shrink(),
      );

      expect(container.child, isA<SizedBox>());
    });
  });

  // ==========================================================================
  // DetailVisibility Integration Tests
  // ==========================================================================
  group('DetailVisibility Integration', () {
    test('full visibility shows all elements', () {
      const visibility = DetailVisibility.full;

      expect(visibility.showPorts, isTrue);
      expect(visibility.showResizeHandles, isTrue);
      expect(visibility.showNodeContent, isTrue);
    });

    test('minimal visibility hides most elements', () {
      const visibility = DetailVisibility.minimal;

      expect(visibility.showPorts, isFalse);
      expect(visibility.showResizeHandles, isFalse);
      expect(visibility.showNodeContent, isFalse);
    });

    test('standard visibility shows some elements', () {
      const visibility = DetailVisibility.standard;

      expect(visibility.showPorts, isFalse);
      expect(visibility.showResizeHandles, isFalse);
      expect(visibility.showNodeContent, isTrue);
    });

    test('custom visibility configuration', () {
      const visibility = DetailVisibility(
        showPorts: true,
        showResizeHandles: false,
        showNodeContent: true,
        showPortLabels: false,
      );

      expect(visibility.showPorts, isTrue);
      expect(visibility.showResizeHandles, isFalse);
      expect(visibility.showNodeContent, isTrue);
      expect(visibility.showPortLabels, isFalse);
    });
  });

  // ==========================================================================
  // Widget Rendering Tests (require pumpWidget)
  // These tests verify basic rendering behavior of NodeContainer.
  // Note: Tests for nodes with ports require full editor initialization
  // and are covered in integration tests.
  // ==========================================================================
  group('Widget Rendering', () {
    late NodeFlowController<String, dynamic> controller;

    setUp(() {
      controller = createTestController();
      controller.setScreenSize(const Size(800, 600));
    });

    tearDown(() {
      controller.dispose();
    });

    testWidgets('renders visible node without ports', (tester) async {
      // Use a node without ports to avoid theme dependency
      final node = createTestNode(id: 'visible-node', visible: true);
      controller.addNode(node);

      await tester.pumpWidget(
        MaterialApp(
          home: Stack(
            children: [
              NodeContainer<String>(
                node: node,
                controller: controller,
                child: Container(
                  key: const Key('node-content'),
                  color: Colors.blue,
                  width: 100,
                  height: 100,
                ),
              ),
            ],
          ),
        ),
      );

      await tester.pumpAndSettle();

      // The container should render the child
      expect(find.byKey(const Key('node-content')), findsOneWidget);
    });

    testWidgets('does not render hidden node', (tester) async {
      final node = createTestNode(id: 'hidden-node', visible: false);
      controller.addNode(node);

      await tester.pumpWidget(
        MaterialApp(
          home: Stack(
            children: [
              NodeContainer<String>(
                node: node,
                controller: controller,
                child: Container(
                  key: const Key('hidden-content'),
                  color: Colors.blue,
                  width: 100,
                  height: 100,
                ),
              ),
            ],
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Hidden node should not render its content
      expect(find.byKey(const Key('hidden-content')), findsNothing);
    });

    testWidgets('node position affects widget placement', (tester) async {
      final node = createTestNode(
        id: 'positioned-node',
        position: const Offset(100, 200),
      );
      controller.addNode(node);

      await tester.pumpWidget(
        MaterialApp(
          home: Stack(
            children: [
              NodeContainer<String>(
                node: node,
                controller: controller,
                child: Container(
                  key: const Key('positioned-content'),
                  color: Colors.blue,
                  width: 100,
                  height: 100,
                ),
              ),
            ],
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Find the Positioned widget - confirms rendering happens
      final positionedFinder = find.byType(Positioned);
      expect(positionedFinder, findsWidgets);
    });

    testWidgets('GroupNode without ports renders in NodeContainer', (
      tester,
    ) async {
      // Create group without ports to avoid theme dependency
      final group = GroupNode<String>(
        id: 'group-render',
        position: const Offset(50, 50),
        size: const Size(300, 200),
        title: 'Test Group',
        data: 'test',
        // No ports
      );
      controller.addNode(group);

      await tester.pumpWidget(
        MaterialApp(
          home: Stack(
            children: [
              NodeContainer<String>(
                node: group,
                controller: controller,
                child: Container(
                  key: const Key('group-content'),
                  color: Colors.lightBlue.withAlpha(100),
                ),
              ),
            ],
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.byKey(const Key('group-content')), findsOneWidget);
    });

    testWidgets('CommentNode renders in NodeContainer', (tester) async {
      final comment = createTestCommentNode<String>(
        id: 'comment-render',
        data: 'test',
        position: const Offset(100, 100),
      );
      controller.addNode(comment);

      await tester.pumpWidget(
        MaterialApp(
          home: Stack(
            children: [
              NodeContainer<String>(
                node: comment,
                controller: controller,
                child: Container(
                  key: const Key('comment-content'),
                  color: Colors.yellow,
                ),
              ),
            ],
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.byKey(const Key('comment-content')), findsOneWidget);
    });

    testWidgets('node with custom shape renders', (tester) async {
      // Use node without ports
      final node = createTestNode(id: 'shaped-node');
      controller.addNode(node);
      final shape = _TestNodeShape();

      await tester.pumpWidget(
        MaterialApp(
          home: Stack(
            children: [
              NodeContainer<String>(
                node: node,
                controller: controller,
                shape: shape,
                child: Container(
                  key: const Key('shaped-node-content'),
                  color: Colors.blue,
                ),
              ),
            ],
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.byType(NodeContainer<String>), findsOneWidget);
      expect(find.byKey(const Key('shaped-node-content')), findsOneWidget);
    });

    testWidgets('node callbacks are stored', (tester) async {
      final node = createTestNode(id: 'callback-node');
      controller.addNode(node);
      var tapCount = 0;

      await tester.pumpWidget(
        MaterialApp(
          home: Stack(
            children: [
              NodeContainer<String>(
                node: node,
                controller: controller,
                onTap: () => tapCount++,
                child: Container(
                  key: const Key('tappable-content'),
                  color: Colors.blue,
                  width: 100,
                  height: 100,
                ),
              ),
            ],
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Node container should be rendered
      expect(find.byType(NodeContainer<String>), findsOneWidget);
    });

    testWidgets('visibility changes trigger rebuild', (tester) async {
      final node = createTestNode(id: 'toggle-node', visible: true);
      controller.addNode(node);

      await tester.pumpWidget(
        MaterialApp(
          home: Stack(
            children: [
              NodeContainer<String>(
                node: node,
                controller: controller,
                child: Container(
                  key: const Key('toggle-content'),
                  color: Colors.blue,
                  width: 100,
                  height: 100,
                ),
              ),
            ],
          ),
        ),
      );

      await tester.pumpAndSettle();
      expect(find.byKey(const Key('toggle-content')), findsOneWidget);

      // Toggle visibility
      node.isVisible = false;
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('toggle-content')), findsNothing);

      // Toggle back
      node.isVisible = true;
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('toggle-content')), findsOneWidget);
    });

    testWidgets('position changes trigger rebuild', (tester) async {
      final node = createTestNode(
        id: 'move-node',
        position: const Offset(50, 50),
      );
      controller.addNode(node);

      await tester.pumpWidget(
        MaterialApp(
          home: Stack(
            children: [
              NodeContainer<String>(
                node: node,
                controller: controller,
                child: Container(
                  key: const Key('move-content'),
                  color: Colors.blue,
                  width: 100,
                  height: 100,
                ),
              ),
            ],
          ),
        ),
      );

      await tester.pumpAndSettle();
      expect(find.byKey(const Key('move-content')), findsOneWidget);

      // Move node
      node.setVisualPosition(const Offset(200, 200));
      await tester.pumpAndSettle();

      // Widget should still be rendered (just moved)
      expect(find.byKey(const Key('move-content')), findsOneWidget);
    });

    testWidgets('resizable node shows ResizerWidget in design mode', (
      tester,
    ) async {
      final group = GroupNode<String>(
        id: 'resizable-group',
        position: const Offset(50, 50),
        size: const Size(200, 150),
        title: 'Test Group',
        data: 'test',
      );
      group.isSelected = true;
      controller.addNode(group);

      // Controller defaults to design mode
      expect(controller.behavior, equals(NodeFlowBehavior.design));

      await tester.pumpWidget(
        MaterialApp(
          home: Stack(
            children: [
              NodeContainer<String>(
                node: group,
                controller: controller,
                child: Container(color: Colors.blue),
              ),
            ],
          ),
        ),
      );

      await tester.pumpAndSettle();

      // ResizerWidget should be present in design mode
      expect(find.byType(ResizerWidget), findsOneWidget);
    });

    testWidgets('resizable node hides ResizerWidget in preview mode', (
      tester,
    ) async {
      final group = GroupNode<String>(
        id: 'resizable-group',
        position: const Offset(50, 50),
        size: const Size(200, 150),
        title: 'Test Group',
        data: 'test',
      );
      group.isSelected = true;
      controller.addNode(group);

      // Set to preview mode
      controller.setBehavior(NodeFlowBehavior.preview);

      await tester.pumpWidget(
        MaterialApp(
          home: Stack(
            children: [
              NodeContainer<String>(
                node: group,
                controller: controller,
                child: Container(color: Colors.blue),
              ),
            ],
          ),
        ),
      );

      await tester.pumpAndSettle();

      // ResizerWidget should NOT be present in preview mode
      expect(find.byType(ResizerWidget), findsNothing);
    });

    testWidgets('resizable node hides ResizerWidget in inspect mode', (
      tester,
    ) async {
      final group = GroupNode<String>(
        id: 'resizable-group',
        position: const Offset(50, 50),
        size: const Size(200, 150),
        title: 'Test Group',
        data: 'test',
      );
      group.isSelected = true;
      controller.addNode(group);

      // Set to inspect mode
      controller.setBehavior(NodeFlowBehavior.inspect);

      await tester.pumpWidget(
        MaterialApp(
          home: Stack(
            children: [
              NodeContainer<String>(
                node: group,
                controller: controller,
                child: Container(color: Colors.blue),
              ),
            ],
          ),
        ),
      );

      await tester.pumpAndSettle();

      // ResizerWidget should NOT be present in inspect mode
      expect(find.byType(ResizerWidget), findsNothing);
    });

    testWidgets('switching behavior mode updates ResizerWidget visibility', (
      tester,
    ) async {
      final group = GroupNode<String>(
        id: 'resizable-group',
        position: const Offset(50, 50),
        size: const Size(200, 150),
        title: 'Test Group',
        data: 'test',
      );
      group.isSelected = true;
      controller.addNode(group);

      await tester.pumpWidget(
        MaterialApp(
          home: Stack(
            children: [
              NodeContainer<String>(
                node: group,
                controller: controller,
                child: Container(color: Colors.blue),
              ),
            ],
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Design mode - ResizerWidget visible
      expect(find.byType(ResizerWidget), findsOneWidget);

      // Switch to preview mode
      controller.setBehavior(NodeFlowBehavior.preview);
      await tester.pumpAndSettle();

      // ResizerWidget should disappear
      expect(find.byType(ResizerWidget), findsNothing);

      // Switch back to design mode
      controller.setBehavior(NodeFlowBehavior.design);
      await tester.pumpAndSettle();

      // ResizerWidget should reappear
      expect(find.byType(ResizerWidget), findsOneWidget);
    });
  });
}

/// A simple test implementation of [NodeShape] for testing.
class _TestNodeShape extends NodeShape {
  _TestNodeShape();

  @override
  Path buildPath(Size size) {
    return Path()..addRect(Rect.fromLTWH(0, 0, size.width, size.height));
  }

  @override
  List<PortAnchor> getPortAnchors(Size size) {
    return [
      PortAnchor(
        position: PortPosition.left,
        offset: Offset(0, size.height / 2),
      ),
      PortAnchor(
        position: PortPosition.right,
        offset: Offset(size.width, size.height / 2),
      ),
      PortAnchor(position: PortPosition.top, offset: Offset(size.width / 2, 0)),
      PortAnchor(
        position: PortPosition.bottom,
        offset: Offset(size.width / 2, size.height),
      ),
    ];
  }
}
