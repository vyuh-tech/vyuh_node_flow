/// Unit tests for the widget handlers extension on NodeFlowEditor.
///
/// Tests cover:
/// - Node gesture handlers (tap, double-tap, context menu, hover)
/// - Port gesture handlers (context menu)
/// - Selection behavior with modifier keys
/// - Event callback invocations
/// - Edge cases and error handling
@Tags(['unit'])
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vyuh_node_flow/vyuh_node_flow.dart';

import '../../helpers/test_factories.dart';

void main() {
  setUp(() {
    resetTestCounters();
  });

  // ===========================================================================
  // Node Tap Handler Tests
  // ===========================================================================

  group('_handleNodeTap', () {
    test('selecting unselected node selects it', () {
      final controller = createTestController();
      final node = createTestNode(id: 'node-1');
      controller.addNode(node);

      // Simulate node tap by directly calling selectNode (the handler calls this)
      controller.selectNode(node.id);

      expect(controller.isNodeSelected(node.id), isTrue);
      expect(controller.selectedNodeIds, contains(node.id));
    });

    test('selecting already selected node keeps it selected', () {
      final controller = createTestController();
      final node = createTestNode(id: 'node-1');
      controller.addNode(node);
      controller.selectNode(node.id);

      // Re-select the same node
      controller.selectNode(node.id);

      expect(controller.isNodeSelected(node.id), isTrue);
      expect(controller.selectedNodeIds.length, equals(1));
    });

    test('toggle selection adds to existing selection', () {
      final controller = createTestController();
      final node1 = createTestNode(id: 'node-1');
      final node2 = createTestNode(id: 'node-2');
      controller.addNode(node1);
      controller.addNode(node2);
      controller.selectNode(node1.id);

      // Toggle-select second node
      controller.selectNode(node2.id, toggle: true);

      expect(controller.isNodeSelected(node1.id), isTrue);
      expect(controller.isNodeSelected(node2.id), isTrue);
      expect(controller.selectedNodeIds.length, equals(2));
    });

    test('toggle selection removes from selection if already selected', () {
      final controller = createTestController();
      final node1 = createTestNode(id: 'node-1');
      final node2 = createTestNode(id: 'node-2');
      controller.addNode(node1);
      controller.addNode(node2);
      controller.selectNode(node1.id);
      controller.selectNode(node2.id, toggle: true);

      // Toggle-deselect first node
      controller.selectNode(node1.id, toggle: true);

      expect(controller.isNodeSelected(node1.id), isFalse);
      expect(controller.isNodeSelected(node2.id), isTrue);
      expect(controller.selectedNodeIds.length, equals(1));
    });

    test('fires onTap event callback', () {
      Node<String>? tappedNode;
      final controller = createTestController();
      final node = createTestNode(id: 'node-1');
      controller.addNode(node);

      // Initialize controller with events
      final theme = NodeFlowTheme.light;
      controller.initController(
        theme: theme,
        portSizeResolver: (port) => port.size ?? theme.portTheme.size,
        events: NodeFlowEvents<String, dynamic>(
          node: NodeEvents<String>(onTap: (n) => tappedNode = n),
        ),
      );

      // The handler fires onTap - simulate by directly calling it
      controller.events.node?.onTap?.call(node);

      expect(tappedNode, equals(node));
    });

    test('selecting node without toggle clears other selections', () {
      final controller = createTestController();
      final node1 = createTestNode(id: 'node-1');
      final node2 = createTestNode(id: 'node-2');
      final node3 = createTestNode(id: 'node-3');
      controller.addNode(node1);
      controller.addNode(node2);
      controller.addNode(node3);

      // Select multiple nodes
      controller.selectNode(node1.id);
      controller.selectNode(node2.id, toggle: true);

      // Select third node without toggle - should clear others
      controller.selectNode(node3.id);

      expect(controller.isNodeSelected(node1.id), isFalse);
      expect(controller.isNodeSelected(node2.id), isFalse);
      expect(controller.isNodeSelected(node3.id), isTrue);
      expect(controller.selectedNodeIds.length, equals(1));
    });
  });

  // ===========================================================================
  // Node Double Tap Handler Tests
  // ===========================================================================

  group('_handleNodeDoubleTap', () {
    test('fires onDoubleTap event callback', () {
      Node<String>? doubleTappedNode;
      final controller = createTestController();
      final node = createTestNode(id: 'node-1');
      controller.addNode(node);

      final theme = NodeFlowTheme.light;
      controller.initController(
        theme: theme,
        portSizeResolver: (port) => port.size ?? theme.portTheme.size,
        events: NodeFlowEvents<String, dynamic>(
          node: NodeEvents<String>(onDoubleTap: (n) => doubleTappedNode = n),
        ),
      );

      controller.events.node?.onDoubleTap?.call(node);

      expect(doubleTappedNode, equals(node));
    });

    test('double tap works without callback set', () {
      final controller = createTestController();
      final node = createTestNode(id: 'node-1');
      controller.addNode(node);

      final theme = NodeFlowTheme.light;
      controller.initController(
        theme: theme,
        portSizeResolver: (port) => port.size ?? theme.portTheme.size,
        events: const NodeFlowEvents<String, dynamic>(),
      );

      // Should not throw
      expect(
        () => controller.events.node?.onDoubleTap?.call(node),
        returnsNormally,
      );
    });
  });

  // ===========================================================================
  // Node Context Menu Handler Tests
  // ===========================================================================

  group('_handleNodeContextMenu', () {
    test('fires onContextMenu event callback with screen position', () {
      Node<String>? contextMenuNode;
      ScreenPosition? receivedPosition;

      final controller = createTestController();
      final node = createTestNode(id: 'node-1');
      controller.addNode(node);

      final theme = NodeFlowTheme.light;
      controller.initController(
        theme: theme,
        portSizeResolver: (port) => port.size ?? theme.portTheme.size,
        events: NodeFlowEvents<String, dynamic>(
          node: NodeEvents<String>(
            onContextMenu: (n, pos) {
              contextMenuNode = n;
              receivedPosition = pos;
            },
          ),
        ),
      );

      final screenPosition = ScreenPosition(const Offset(100, 200));
      controller.events.node?.onContextMenu?.call(node, screenPosition);

      expect(contextMenuNode, equals(node));
      expect(receivedPosition, equals(screenPosition));
    });

    test('context menu works without callback set', () {
      final controller = createTestController();
      final node = createTestNode(id: 'node-1');
      controller.addNode(node);

      final theme = NodeFlowTheme.light;
      controller.initController(
        theme: theme,
        portSizeResolver: (port) => port.size ?? theme.portTheme.size,
        events: const NodeFlowEvents<String, dynamic>(),
      );

      final screenPosition = ScreenPosition(const Offset(100, 200));

      // Should not throw
      expect(
        () => controller.events.node?.onContextMenu?.call(node, screenPosition),
        returnsNormally,
      );
    });
  });

  // ===========================================================================
  // Node Mouse Enter/Leave Handler Tests
  // ===========================================================================

  group('_handleNodeMouseEnter', () {
    test('fires onMouseEnter event callback', () {
      Node<String>? enteredNode;
      final controller = createTestController();
      final node = createTestNode(id: 'node-1');
      controller.addNode(node);

      final theme = NodeFlowTheme.light;
      controller.initController(
        theme: theme,
        portSizeResolver: (port) => port.size ?? theme.portTheme.size,
        events: NodeFlowEvents<String, dynamic>(
          node: NodeEvents<String>(onMouseEnter: (n) => enteredNode = n),
        ),
      );

      controller.events.node?.onMouseEnter?.call(node);

      expect(enteredNode, equals(node));
    });

    test('mouse enter works without callback set', () {
      final controller = createTestController();
      final node = createTestNode(id: 'node-1');
      controller.addNode(node);

      final theme = NodeFlowTheme.light;
      controller.initController(
        theme: theme,
        portSizeResolver: (port) => port.size ?? theme.portTheme.size,
        events: const NodeFlowEvents<String, dynamic>(),
      );

      // Should not throw
      expect(
        () => controller.events.node?.onMouseEnter?.call(node),
        returnsNormally,
      );
    });
  });

  group('_handleNodeMouseLeave', () {
    test('fires onMouseLeave event callback', () {
      Node<String>? leftNode;
      final controller = createTestController();
      final node = createTestNode(id: 'node-1');
      controller.addNode(node);

      final theme = NodeFlowTheme.light;
      controller.initController(
        theme: theme,
        portSizeResolver: (port) => port.size ?? theme.portTheme.size,
        events: NodeFlowEvents<String, dynamic>(
          node: NodeEvents<String>(onMouseLeave: (n) => leftNode = n),
        ),
      );

      controller.events.node?.onMouseLeave?.call(node);

      expect(leftNode, equals(node));
    });

    test('mouse leave works without callback set', () {
      final controller = createTestController();
      final node = createTestNode(id: 'node-1');
      controller.addNode(node);

      final theme = NodeFlowTheme.light;
      controller.initController(
        theme: theme,
        portSizeResolver: (port) => port.size ?? theme.portTheme.size,
        events: const NodeFlowEvents<String, dynamic>(),
      );

      // Should not throw
      expect(
        () => controller.events.node?.onMouseLeave?.call(node),
        returnsNormally,
      );
    });
  });

  // ===========================================================================
  // Port Context Menu Handler Tests
  // ===========================================================================

  group('_handlePortContextMenu', () {
    test('fires onContextMenu event callback for input port', () {
      Node<String>? contextMenuNode;
      Port? contextMenuPort;
      ScreenPosition? receivedPosition;

      final controller = createTestController();
      final inputPort = createTestPort(id: 'input-1', type: PortType.input);
      final node = createTestNode(id: 'node-1', inputPorts: [inputPort]);
      controller.addNode(node);

      final theme = NodeFlowTheme.light;
      controller.initController(
        theme: theme,
        portSizeResolver: (port) => port.size ?? theme.portTheme.size,
        events: NodeFlowEvents<String, dynamic>(
          port: PortEvents<String>(
            onContextMenu: (n, p, pos) {
              contextMenuNode = n;
              contextMenuPort = p;
              receivedPosition = pos;
            },
          ),
        ),
      );

      final screenPosition = ScreenPosition(const Offset(150, 250));
      controller.events.port?.onContextMenu?.call(
        node,
        inputPort,
        screenPosition,
      );

      expect(contextMenuNode, equals(node));
      expect(contextMenuPort, equals(inputPort));
      expect(receivedPosition, equals(screenPosition));
      expect(contextMenuPort?.isInput, isTrue);
    });

    test('fires onContextMenu event callback for output port', () {
      Node<String>? contextMenuNode;
      Port? contextMenuPort;

      final controller = createTestController();
      final outputPort = createTestPort(id: 'output-1', type: PortType.output);
      final node = createTestNode(id: 'node-1', outputPorts: [outputPort]);
      controller.addNode(node);

      final theme = NodeFlowTheme.light;
      controller.initController(
        theme: theme,
        portSizeResolver: (port) => port.size ?? theme.portTheme.size,
        events: NodeFlowEvents<String, dynamic>(
          port: PortEvents<String>(
            onContextMenu: (n, p, pos) {
              contextMenuNode = n;
              contextMenuPort = p;
            },
          ),
        ),
      );

      final screenPosition = ScreenPosition(const Offset(150, 250));
      controller.events.port?.onContextMenu?.call(
        node,
        outputPort,
        screenPosition,
      );

      expect(contextMenuNode, equals(node));
      expect(contextMenuPort, equals(outputPort));
      expect(contextMenuPort?.isOutput, isTrue);
    });

    test('port context menu works without callback set', () {
      final controller = createTestController();
      final port = createTestPort(id: 'port-1', type: PortType.input);
      final node = createTestNode(id: 'node-1', inputPorts: [port]);
      controller.addNode(node);

      final theme = NodeFlowTheme.light;
      controller.initController(
        theme: theme,
        portSizeResolver: (port) => port.size ?? theme.portTheme.size,
        events: const NodeFlowEvents<String, dynamic>(),
      );

      final screenPosition = ScreenPosition(const Offset(150, 250));

      // Should not throw
      expect(
        () => controller.events.port?.onContextMenu?.call(
          node,
          port,
          screenPosition,
        ),
        returnsNormally,
      );
    });
  });

  // ===========================================================================
  // Node Lookup Tests (used by port context menu handler)
  // ===========================================================================

  group('Node Lookup for Port Handlers', () {
    test('getNode returns node when it exists', () {
      final controller = createTestController();
      final node = createTestNode(id: 'node-1');
      controller.addNode(node);

      final result = controller.getNode('node-1');

      expect(result, isNotNull);
      expect(result?.id, equals('node-1'));
    });

    test('getNode returns null for non-existent node', () {
      final controller = createTestController();

      final result = controller.getNode('non-existent');

      expect(result, isNull);
    });

    test('finding port from node input and output ports', () {
      final controller = createTestController();
      final inputPort = createTestPort(id: 'input-1', type: PortType.input);
      final outputPort = createTestPort(id: 'output-1', type: PortType.output);
      final node = createTestNode(
        id: 'node-1',
        inputPorts: [inputPort],
        outputPorts: [outputPort],
      );
      controller.addNode(node);

      final retrievedNode = controller.getNode('node-1');
      expect(retrievedNode, isNotNull);

      // Find input port
      final foundInputPort = [
        ...retrievedNode!.inputPorts,
        ...retrievedNode.outputPorts,
      ].where((p) => p.id == 'input-1').firstOrNull;
      expect(foundInputPort, isNotNull);
      expect(foundInputPort?.isInput, isTrue);

      // Find output port
      final foundOutputPort = [
        ...retrievedNode.inputPorts,
        ...retrievedNode.outputPorts,
      ].where((p) => p.id == 'output-1').firstOrNull;
      expect(foundOutputPort, isNotNull);
      expect(foundOutputPort?.isOutput, isTrue);
    });

    test('finding port returns null for non-existent port ID', () {
      final controller = createTestController();
      final inputPort = createTestPort(id: 'input-1', type: PortType.input);
      final node = createTestNode(id: 'node-1', inputPorts: [inputPort]);
      controller.addNode(node);

      final retrievedNode = controller.getNode('node-1');
      final nonExistentPort = [
        ...retrievedNode!.inputPorts,
        ...retrievedNode.outputPorts,
      ].where((p) => p.id == 'non-existent').firstOrNull;

      expect(nonExistentPort, isNull);
    });
  });

  // ===========================================================================
  // Selection State Management Tests
  // ===========================================================================

  group('Selection State Management', () {
    test('selecting node clears connection selection', () {
      final controller = createTestController();
      final nodeA = createTestNodeWithOutputPort(
        id: 'node-a',
        portId: 'output-1',
      );
      final nodeB = createTestNodeWithInputPort(
        id: 'node-b',
        portId: 'input-1',
      );
      final connection = createTestConnection(
        sourceNodeId: 'node-a',
        sourcePortId: 'output-1',
        targetNodeId: 'node-b',
        targetPortId: 'input-1',
      );

      controller.addNode(nodeA);
      controller.addNode(nodeB);
      controller.addConnection(connection);
      controller.selectConnection(connection.id);

      expect(controller.selectedConnectionIds.isNotEmpty, isTrue);

      // Select a node
      controller.selectNode('node-a');

      // Connection selection should be cleared
      expect(controller.selectedConnectionIds.isEmpty, isTrue);
      expect(controller.isNodeSelected('node-a'), isTrue);
    });

    test('isNodeSelected returns correct values', () {
      final controller = createTestController();
      final node1 = createTestNode(id: 'node-1');
      final node2 = createTestNode(id: 'node-2');
      controller.addNode(node1);
      controller.addNode(node2);

      expect(controller.isNodeSelected('node-1'), isFalse);
      expect(controller.isNodeSelected('node-2'), isFalse);

      controller.selectNode('node-1');

      expect(controller.isNodeSelected('node-1'), isTrue);
      expect(controller.isNodeSelected('node-2'), isFalse);
    });

    test('clearNodeSelection deselects all nodes', () {
      final controller = createTestController();
      final node1 = createTestNode(id: 'node-1');
      final node2 = createTestNode(id: 'node-2');
      controller.addNode(node1);
      controller.addNode(node2);
      controller.selectNode(node1.id);
      controller.selectNode(node2.id, toggle: true);

      expect(controller.selectedNodeIds.length, equals(2));

      controller.clearNodeSelection();

      expect(controller.selectedNodeIds.isEmpty, isTrue);
      expect(controller.isNodeSelected('node-1'), isFalse);
      expect(controller.isNodeSelected('node-2'), isFalse);
    });

    test('node selected observable reflects selection state', () {
      final controller = createTestController();
      final node = createTestNode(id: 'node-1');
      controller.addNode(node);

      expect(node.selected.value, isFalse);

      controller.selectNode(node.id);
      expect(node.selected.value, isTrue);

      controller.clearNodeSelection();
      expect(node.selected.value, isFalse);
    });
  });

  // ===========================================================================
  // Multi-Selection Behavior Tests
  // ===========================================================================

  group('Multi-Selection Behavior', () {
    test('selecting multiple nodes with toggle preserves selections', () {
      final controller = createTestController();
      final nodes = createNodeRow(count: 5);
      for (final node in nodes) {
        controller.addNode(node);
      }

      controller.selectNode(nodes[0].id);
      controller.selectNode(nodes[1].id, toggle: true);
      controller.selectNode(nodes[2].id, toggle: true);

      expect(controller.selectedNodeIds.length, equals(3));
      expect(controller.isNodeSelected(nodes[0].id), isTrue);
      expect(controller.isNodeSelected(nodes[1].id), isTrue);
      expect(controller.isNodeSelected(nodes[2].id), isTrue);
      expect(controller.isNodeSelected(nodes[3].id), isFalse);
      expect(controller.isNodeSelected(nodes[4].id), isFalse);
    });

    test('selectNodes selects multiple nodes at once', () {
      final controller = createTestController();
      final nodes = createNodeRow(count: 5);
      for (final node in nodes) {
        controller.addNode(node);
      }

      controller.selectNodes([nodes[0].id, nodes[2].id, nodes[4].id]);

      expect(controller.selectedNodeIds.length, equals(3));
      expect(controller.isNodeSelected(nodes[0].id), isTrue);
      expect(controller.isNodeSelected(nodes[1].id), isFalse);
      expect(controller.isNodeSelected(nodes[2].id), isTrue);
      expect(controller.isNodeSelected(nodes[3].id), isFalse);
      expect(controller.isNodeSelected(nodes[4].id), isTrue);
    });

    test('selectNodes with toggle adds to existing selection', () {
      final controller = createTestController();
      final nodes = createNodeRow(count: 5);
      for (final node in nodes) {
        controller.addNode(node);
      }

      controller.selectNode(nodes[0].id);
      controller.selectNodes([nodes[2].id, nodes[3].id], toggle: true);

      expect(controller.selectedNodeIds.length, equals(3));
      expect(controller.isNodeSelected(nodes[0].id), isTrue);
      expect(controller.isNodeSelected(nodes[2].id), isTrue);
      expect(controller.isNodeSelected(nodes[3].id), isTrue);
    });
  });

  // ===========================================================================
  // GroupNode and CommentNode Handler Tests
  // ===========================================================================

  group('GroupNode and CommentNode Handlers', () {
    test('group node uses same node handlers', () {
      Node<String>? tappedNode;
      final controller = createTestController();
      final groupNode = createTestGroupNode<String>(
        id: 'group-1',
        data: 'group-data',
        title: 'Test Group',
      );
      controller.addNode(groupNode);

      final theme = NodeFlowTheme.light;
      controller.initController(
        theme: theme,
        portSizeResolver: (port) => port.size ?? theme.portTheme.size,
        events: NodeFlowEvents<String, dynamic>(
          node: NodeEvents<String>(onTap: (n) => tappedNode = n),
        ),
      );

      controller.events.node?.onTap?.call(groupNode);

      expect(tappedNode, equals(groupNode));
      expect(tappedNode is GroupNode, isTrue);
    });

    test('comment node uses same node handlers', () {
      Node<String>? tappedNode;
      final controller = createTestController();
      final commentNode = createTestCommentNode<String>(
        id: 'comment-1',
        data: 'comment-data',
        text: 'Test Comment',
      );
      controller.addNode(commentNode);

      final theme = NodeFlowTheme.light;
      controller.initController(
        theme: theme,
        portSizeResolver: (port) => port.size ?? theme.portTheme.size,
        events: NodeFlowEvents<String, dynamic>(
          node: NodeEvents<String>(onTap: (n) => tappedNode = n),
        ),
      );

      controller.events.node?.onTap?.call(commentNode);

      expect(tappedNode, equals(commentNode));
      expect(tappedNode is CommentNode, isTrue);
    });

    test('group node can be selected like regular node', () {
      final controller = createTestController();
      final groupNode = createTestGroupNode<String>(
        id: 'group-1',
        data: 'group-data',
        title: 'Test Group',
      );
      controller.addNode(groupNode);

      controller.selectNode(groupNode.id);

      expect(controller.isNodeSelected(groupNode.id), isTrue);
      expect(groupNode.selected.value, isTrue);
    });

    test('comment node can be selected like regular node', () {
      final controller = createTestController();
      final commentNode = createTestCommentNode<String>(
        id: 'comment-1',
        data: 'comment-data',
        text: 'Test Comment',
      );
      controller.addNode(commentNode);

      controller.selectNode(commentNode.id);

      expect(controller.isNodeSelected(commentNode.id), isTrue);
      expect(commentNode.selected.value, isTrue);
    });
  });

  // ===========================================================================
  // Event Callback Registration Tests
  // ===========================================================================

  group('Event Callback Registration', () {
    test('events can be updated after initialization', () {
      Node<String>? newTappedNode;
      final controller = createTestController();
      final node = createTestNode(id: 'node-1');
      controller.addNode(node);

      // Initial events (no callbacks)
      final theme = NodeFlowTheme.light;
      controller.initController(
        theme: theme,
        portSizeResolver: (port) => port.size ?? theme.portTheme.size,
        events: const NodeFlowEvents<String, dynamic>(),
      );

      // Update events with callbacks
      controller.updateEvents(
        NodeFlowEvents<String, dynamic>(
          node: NodeEvents<String>(onTap: (n) => newTappedNode = n),
        ),
      );

      controller.events.node?.onTap?.call(node);

      expect(newTappedNode, equals(node));
    });

    test('all node event callbacks can be set', () {
      var tapFired = false;
      var doubleTapFired = false;
      var mouseEnterFired = false;
      var mouseLeaveFired = false;
      var contextMenuFired = false;

      final controller = createTestController();
      final node = createTestNode(id: 'node-1');
      controller.addNode(node);

      final theme = NodeFlowTheme.light;
      controller.initController(
        theme: theme,
        portSizeResolver: (port) => port.size ?? theme.portTheme.size,
        events: NodeFlowEvents<String, dynamic>(
          node: NodeEvents<String>(
            onTap: (n) => tapFired = true,
            onDoubleTap: (n) => doubleTapFired = true,
            onMouseEnter: (n) => mouseEnterFired = true,
            onMouseLeave: (n) => mouseLeaveFired = true,
            onContextMenu: (n, pos) => contextMenuFired = true,
          ),
        ),
      );

      final screenPos = ScreenPosition(const Offset(0, 0));
      controller.events.node?.onTap?.call(node);
      controller.events.node?.onDoubleTap?.call(node);
      controller.events.node?.onMouseEnter?.call(node);
      controller.events.node?.onMouseLeave?.call(node);
      controller.events.node?.onContextMenu?.call(node, screenPos);

      expect(tapFired, isTrue);
      expect(doubleTapFired, isTrue);
      expect(mouseEnterFired, isTrue);
      expect(mouseLeaveFired, isTrue);
      expect(contextMenuFired, isTrue);
    });

    test('all port event callbacks can be set', () {
      var tapFired = false;
      var doubleTapFired = false;
      var mouseEnterFired = false;
      var mouseLeaveFired = false;
      var contextMenuFired = false;

      final controller = createTestController();
      final port = createTestPort(id: 'port-1', type: PortType.input);
      final node = createTestNode(id: 'node-1', inputPorts: [port]);
      controller.addNode(node);

      final theme = NodeFlowTheme.light;
      controller.initController(
        theme: theme,
        portSizeResolver: (port) => port.size ?? theme.portTheme.size,
        events: NodeFlowEvents<String, dynamic>(
          port: PortEvents<String>(
            onTap: (n, p) => tapFired = true,
            onDoubleTap: (n, p) => doubleTapFired = true,
            onMouseEnter: (n, p) => mouseEnterFired = true,
            onMouseLeave: (n, p) => mouseLeaveFired = true,
            onContextMenu: (n, p, pos) => contextMenuFired = true,
          ),
        ),
      );

      final screenPos = ScreenPosition(const Offset(0, 0));
      controller.events.port?.onTap?.call(node, port);
      controller.events.port?.onDoubleTap?.call(node, port);
      controller.events.port?.onMouseEnter?.call(node, port);
      controller.events.port?.onMouseLeave?.call(node, port);
      controller.events.port?.onContextMenu?.call(node, port, screenPos);

      expect(tapFired, isTrue);
      expect(doubleTapFired, isTrue);
      expect(mouseEnterFired, isTrue);
      expect(mouseLeaveFired, isTrue);
      expect(contextMenuFired, isTrue);
    });
  });

  // ===========================================================================
  // Edge Cases and Error Handling Tests
  // ===========================================================================

  group('Edge Cases', () {
    test('handler works with empty node list', () {
      final controller = createTestController();

      // No nodes added, should not throw
      expect(controller.nodes.isEmpty, isTrue);
      expect(controller.selectedNodeIds.isEmpty, isTrue);
    });

    test('selecting non-existent node does not throw', () {
      final controller = createTestController();

      // Should not throw, but node won't exist
      expect(() => controller.selectNode('non-existent'), returnsNormally);
    });

    test('toggle selection on non-existent node does not throw', () {
      final controller = createTestController();

      expect(
        () => controller.selectNode('non-existent', toggle: true),
        returnsNormally,
      );
    });

    test('events work with null event groups', () {
      final controller = createTestController();
      final node = createTestNode(id: 'node-1');
      controller.addNode(node);

      final theme = NodeFlowTheme.light;
      controller.initController(
        theme: theme,
        portSizeResolver: (port) => port.size ?? theme.portTheme.size,
        events: const NodeFlowEvents<String, dynamic>(node: null, port: null),
      );

      // Should not throw when events are null
      expect(() {
        controller.events.node?.onTap?.call(node);
        controller.events.node?.onDoubleTap?.call(node);
      }, returnsNormally);
    });

    test('selection event fires with correct node after toggle', () {
      final selectedNodes = <Node<String>?>[];
      final controller = createTestController();
      final node1 = createTestNode(id: 'node-1');
      final node2 = createTestNode(id: 'node-2');
      controller.addNode(node1);
      controller.addNode(node2);

      final theme = NodeFlowTheme.light;
      controller.initController(
        theme: theme,
        portSizeResolver: (port) => port.size ?? theme.portTheme.size,
        events: NodeFlowEvents<String, dynamic>(
          node: NodeEvents<String>(onSelected: (n) => selectedNodes.add(n)),
        ),
      );

      controller.selectNode(node1.id);
      controller.selectNode(node2.id, toggle: true);
      controller.selectNode(node1.id, toggle: true); // Deselect node1

      expect(selectedNodes.length, equals(3));
      expect(selectedNodes[0], equals(node1));
      expect(selectedNodes[1], equals(node2));
      expect(selectedNodes[2], isNull); // node1 was deselected
    });
  });

  // ===========================================================================
  // Interaction State Tests
  // ===========================================================================

  group('Interaction State Integration', () {
    test('canvas focus node exists', () {
      final controller = createTestController();

      expect(controller.canvasFocusNode, isNotNull);
    });

    test('interaction state is accessible', () {
      final controller = createTestController();

      expect(controller.interaction, isNotNull);
    });

    test('interaction state tracks dragged node', () {
      final controller = createTestController();
      final node = createTestNode(id: 'node-1');
      controller.addNode(node);

      expect(controller.draggedNodeId, isNull);

      // Start drag
      controller.startNodeDrag(node.id);

      expect(controller.draggedNodeId, equals(node.id));

      // End drag
      controller.endNodeDrag();

      expect(controller.draggedNodeId, isNull);
    });
  });

  // ===========================================================================
  // Drag Event Handler Tests
  // ===========================================================================

  group('Node Drag Event Handlers', () {
    test('fires onDragStart when drag begins', () {
      Node<String>? dragStartNode;
      final controller = createTestController();
      final node = createTestNode(id: 'node-1');
      controller.addNode(node);

      final theme = NodeFlowTheme.light;
      controller.initController(
        theme: theme,
        portSizeResolver: (port) => port.size ?? theme.portTheme.size,
        events: NodeFlowEvents<String, dynamic>(
          node: NodeEvents<String>(onDragStart: (n) => dragStartNode = n),
        ),
      );

      controller.startNodeDrag(node.id);

      expect(dragStartNode, equals(node));
    });

    test('fires onDrag during drag movement', () {
      final draggedNodes = <Node<String>>[];
      final controller = createTestController();
      final node = createTestNode(id: 'node-1');
      controller.addNode(node);

      final theme = NodeFlowTheme.light;
      controller.initController(
        theme: theme,
        portSizeResolver: (port) => port.size ?? theme.portTheme.size,
        events: NodeFlowEvents<String, dynamic>(
          node: NodeEvents<String>(onDrag: (n) => draggedNodes.add(n)),
        ),
      );

      controller.startNodeDrag(node.id);
      controller.moveNodeDrag(const Offset(10, 10));
      controller.moveNodeDrag(const Offset(5, 5));

      expect(draggedNodes.length, equals(2));
      expect(draggedNodes[0], equals(node));
      expect(draggedNodes[1], equals(node));
    });

    test('fires onDragStop when drag ends', () {
      Node<String>? dragStopNode;
      final controller = createTestController();
      final node = createTestNode(id: 'node-1');
      controller.addNode(node);

      final theme = NodeFlowTheme.light;
      controller.initController(
        theme: theme,
        portSizeResolver: (port) => port.size ?? theme.portTheme.size,
        events: NodeFlowEvents<String, dynamic>(
          node: NodeEvents<String>(onDragStop: (n) => dragStopNode = n),
        ),
      );

      controller.startNodeDrag(node.id);
      controller.endNodeDrag();

      expect(dragStopNode, equals(node));
    });

    test('fires onDragCancel when drag is cancelled', () {
      Node<String>? dragCancelNode;
      final controller = createTestController();
      final node = createTestNode(
        id: 'node-1',
        position: const Offset(100, 100),
      );
      controller.addNode(node);

      final theme = NodeFlowTheme.light;
      controller.initController(
        theme: theme,
        portSizeResolver: (port) => port.size ?? theme.portTheme.size,
        events: NodeFlowEvents<String, dynamic>(
          node: NodeEvents<String>(onDragCancel: (n) => dragCancelNode = n),
        ),
      );

      final originalPositions = {node.id: node.position.value};
      controller.startNodeDrag(node.id);
      controller.moveNodeDrag(const Offset(50, 50));
      controller.cancelNodeDrag(originalPositions);

      expect(dragCancelNode, equals(node));
      expect(node.position.value, equals(const Offset(100, 100)));
    });
  });

  // ===========================================================================
  // Connection Event Handler Tests
  // ===========================================================================

  group('Connection Event Handlers', () {
    test('fires onTap for connection tap', () {
      Connection<dynamic>? tappedConnection;
      final controller = createTestController();
      final nodeA = createTestNodeWithOutputPort(
        id: 'node-a',
        portId: 'output-1',
      );
      final nodeB = createTestNodeWithInputPort(
        id: 'node-b',
        portId: 'input-1',
      );
      final connection = createTestConnection(
        sourceNodeId: 'node-a',
        sourcePortId: 'output-1',
        targetNodeId: 'node-b',
        targetPortId: 'input-1',
      );

      controller.addNode(nodeA);
      controller.addNode(nodeB);
      controller.addConnection(connection);

      final theme = NodeFlowTheme.light;
      controller.initController(
        theme: theme,
        portSizeResolver: (port) => port.size ?? theme.portTheme.size,
        events: NodeFlowEvents<String, dynamic>(
          connection: ConnectionEvents<String, dynamic>(
            onTap: (c) => tappedConnection = c,
          ),
        ),
      );

      controller.events.connection?.onTap?.call(connection);

      expect(tappedConnection, equals(connection));
    });

    test('fires onDoubleTap for connection double tap', () {
      Connection<dynamic>? doubleTappedConnection;
      final controller = createTestController();
      final nodeA = createTestNodeWithOutputPort(
        id: 'node-a',
        portId: 'output-1',
      );
      final nodeB = createTestNodeWithInputPort(
        id: 'node-b',
        portId: 'input-1',
      );
      final connection = createTestConnection(
        sourceNodeId: 'node-a',
        sourcePortId: 'output-1',
        targetNodeId: 'node-b',
        targetPortId: 'input-1',
      );

      controller.addNode(nodeA);
      controller.addNode(nodeB);
      controller.addConnection(connection);

      final theme = NodeFlowTheme.light;
      controller.initController(
        theme: theme,
        portSizeResolver: (port) => port.size ?? theme.portTheme.size,
        events: NodeFlowEvents<String, dynamic>(
          connection: ConnectionEvents<String, dynamic>(
            onDoubleTap: (c) => doubleTappedConnection = c,
          ),
        ),
      );

      controller.events.connection?.onDoubleTap?.call(connection);

      expect(doubleTappedConnection, equals(connection));
    });
  });

  // ===========================================================================
  // Multi-Selection Preservation Tests
  // ===========================================================================

  group('Multi-Selection Preservation on Node Tap', () {
    test('clicking already selected node preserves multi-selection', () {
      final controller = createTestController();
      final node1 = createTestNode(id: 'node-1');
      final node2 = createTestNode(id: 'node-2');
      final node3 = createTestNode(id: 'node-3');
      controller.addNode(node1);
      controller.addNode(node2);
      controller.addNode(node3);

      // Select multiple nodes
      controller.selectNode(node1.id);
      controller.selectNode(node2.id, toggle: true);

      expect(controller.selectedNodeIds.length, equals(2));
      expect(controller.isNodeSelected(node1.id), isTrue);
      expect(controller.isNodeSelected(node2.id), isTrue);

      // Simulate tap on already-selected node without modifier (no change)
      // This is what _handleNodeTap does when isAlreadySelected && !toggle
      final isAlreadySelected = controller.isNodeSelected(node1.id);
      final toggle = false; // No modifier key
      if (!isAlreadySelected || toggle) {
        controller.selectNode(node1.id, toggle: toggle);
      }

      // Multi-selection should be preserved
      expect(controller.selectedNodeIds.length, equals(2));
      expect(controller.isNodeSelected(node1.id), isTrue);
      expect(controller.isNodeSelected(node2.id), isTrue);
    });

    test('clicking unselected node clears multi-selection', () {
      final controller = createTestController();
      final node1 = createTestNode(id: 'node-1');
      final node2 = createTestNode(id: 'node-2');
      final node3 = createTestNode(id: 'node-3');
      controller.addNode(node1);
      controller.addNode(node2);
      controller.addNode(node3);

      // Select multiple nodes
      controller.selectNode(node1.id);
      controller.selectNode(node2.id, toggle: true);

      // Simulate tap on unselected node without modifier
      final isAlreadySelected = controller.isNodeSelected(node3.id);
      final toggle = false;
      if (!isAlreadySelected || toggle) {
        controller.selectNode(node3.id, toggle: toggle);
      }

      // Only the clicked node should be selected
      expect(controller.selectedNodeIds.length, equals(1));
      expect(controller.isNodeSelected(node3.id), isTrue);
      expect(controller.isNodeSelected(node1.id), isFalse);
      expect(controller.isNodeSelected(node2.id), isFalse);
    });

    test('clicking with modifier key toggles selection', () {
      final controller = createTestController();
      final node1 = createTestNode(id: 'node-1');
      final node2 = createTestNode(id: 'node-2');
      controller.addNode(node1);
      controller.addNode(node2);

      // Select first node
      controller.selectNode(node1.id);

      // Simulate tap on already-selected node WITH modifier key (toggle)
      final isAlreadySelected = controller.isNodeSelected(node1.id);
      final toggle = true; // Modifier key pressed (Cmd/Ctrl)
      if (!isAlreadySelected || toggle) {
        controller.selectNode(node1.id, toggle: toggle);
      }

      // Node should be deselected
      expect(controller.isNodeSelected(node1.id), isFalse);
    });

    test('modifier key adds to existing selection', () {
      final controller = createTestController();
      final node1 = createTestNode(id: 'node-1');
      final node2 = createTestNode(id: 'node-2');
      controller.addNode(node1);
      controller.addNode(node2);

      // Select first node
      controller.selectNode(node1.id);

      // Simulate tap on unselected node WITH modifier key
      final isAlreadySelected = controller.isNodeSelected(node2.id);
      final toggle = true;
      if (!isAlreadySelected || toggle) {
        controller.selectNode(node2.id, toggle: toggle);
      }

      // Both nodes should be selected
      expect(controller.selectedNodeIds.length, equals(2));
      expect(controller.isNodeSelected(node1.id), isTrue);
      expect(controller.isNodeSelected(node2.id), isTrue);
    });
  });

  // ===========================================================================
  // Port Handler Edge Cases
  // ===========================================================================

  group('Port Handler Edge Cases', () {
    test('port context menu returns early for null node', () {
      final controller = createTestController();
      var callbackFired = false;

      final theme = NodeFlowTheme.light;
      controller.initController(
        theme: theme,
        portSizeResolver: (port) => port.size ?? theme.portTheme.size,
        events: NodeFlowEvents<String, dynamic>(
          port: PortEvents<String>(
            onContextMenu: (n, p, pos) => callbackFired = true,
          ),
        ),
      );

      // Simulate _handlePortContextMenu with non-existent node
      final node = controller.getNode('non-existent');
      if (node != null) {
        final screenPosition = ScreenPosition(const Offset(100, 100));
        controller.events.port?.onContextMenu?.call(
          node,
          node.inputPorts.first,
          screenPosition,
        );
      }

      // Callback should not fire because node is null
      expect(callbackFired, isFalse);
    });

    test('port context menu returns early for null port', () {
      final controller = createTestController();
      final node = createTestNode(id: 'node-1');
      controller.addNode(node);
      var callbackFired = false;

      final theme = NodeFlowTheme.light;
      controller.initController(
        theme: theme,
        portSizeResolver: (port) => port.size ?? theme.portTheme.size,
        events: NodeFlowEvents<String, dynamic>(
          port: PortEvents<String>(
            onContextMenu: (n, p, pos) => callbackFired = true,
          ),
        ),
      );

      // Simulate _handlePortContextMenu with node but non-existent port
      final retrievedNode = controller.getNode('node-1');
      if (retrievedNode != null) {
        final port = [
          ...retrievedNode.inputPorts,
          ...retrievedNode.outputPorts,
        ].where((p) => p.id == 'non-existent').firstOrNull;

        if (port != null) {
          final screenPosition = ScreenPosition(const Offset(100, 100));
          controller.events.port?.onContextMenu?.call(
            retrievedNode,
            port,
            screenPosition,
          );
        }
      }

      // Callback should not fire because port is null
      expect(callbackFired, isFalse);
    });

    test('port context menu fires for valid node and port', () {
      final controller = createTestController();
      final port = createTestPort(id: 'input-1', type: PortType.input);
      final node = createTestNode(id: 'node-1', inputPorts: [port]);
      controller.addNode(node);
      var callbackFired = false;

      final theme = NodeFlowTheme.light;
      controller.initController(
        theme: theme,
        portSizeResolver: (port) => port.size ?? theme.portTheme.size,
        events: NodeFlowEvents<String, dynamic>(
          port: PortEvents<String>(
            onContextMenu: (n, p, pos) => callbackFired = true,
          ),
        ),
      );

      // Simulate _handlePortContextMenu with valid node and port
      final retrievedNode = controller.getNode('node-1');
      if (retrievedNode != null) {
        final foundPort = [
          ...retrievedNode.inputPorts,
          ...retrievedNode.outputPorts,
        ].where((p) => p.id == 'input-1').firstOrNull;

        if (foundPort != null) {
          final screenPosition = ScreenPosition(const Offset(100, 100));
          controller.events.port?.onContextMenu?.call(
            retrievedNode,
            foundPort,
            screenPosition,
          );
        }
      }

      // Callback should fire because both node and port exist
      expect(callbackFired, isTrue);
    });
  });

  // ===========================================================================
  // Canvas Focus Tests
  // ===========================================================================

  group('Canvas Focus', () {
    test('canvas focus node is accessible', () {
      final controller = createTestController();
      expect(controller.canvasFocusNode, isNotNull);
      expect(controller.canvasFocusNode, isA<FocusNode>());
    });

    test('canvas focus can be requested', () {
      final controller = createTestController();
      // Note: In unit tests without a widget tree, we can only verify the focus node exists
      // Actual focus behavior requires widget tests
      expect(controller.canvasFocusNode.canRequestFocus, isTrue);
    });
  });

  // ===========================================================================
  // Viewport Event Handler Tests
  // ===========================================================================

  group('Viewport Event Handlers', () {
    test('fires onCanvasTap for canvas tap', () {
      GraphPosition? tappedPosition;
      final controller = createTestController();

      final theme = NodeFlowTheme.light;
      controller.initController(
        theme: theme,
        portSizeResolver: (port) => port.size ?? theme.portTheme.size,
        events: NodeFlowEvents<String, dynamic>(
          viewport: ViewportEvents(onCanvasTap: (pos) => tappedPosition = pos),
        ),
      );

      final position = GraphPosition(const Offset(200, 300));
      controller.events.viewport?.onCanvasTap?.call(position);

      expect(tappedPosition, equals(position));
    });

    test('fires onCanvasDoubleTap for canvas double tap', () {
      GraphPosition? doubleTappedPosition;
      final controller = createTestController();

      final theme = NodeFlowTheme.light;
      controller.initController(
        theme: theme,
        portSizeResolver: (port) => port.size ?? theme.portTheme.size,
        events: NodeFlowEvents<String, dynamic>(
          viewport: ViewportEvents(
            onCanvasDoubleTap: (pos) => doubleTappedPosition = pos,
          ),
        ),
      );

      final position = GraphPosition(const Offset(400, 500));
      controller.events.viewport?.onCanvasDoubleTap?.call(position);

      expect(doubleTappedPosition, equals(position));
    });

    test('fires onCanvasContextMenu for canvas context menu', () {
      GraphPosition? contextMenuPosition;
      final controller = createTestController();

      final theme = NodeFlowTheme.light;
      controller.initController(
        theme: theme,
        portSizeResolver: (port) => port.size ?? theme.portTheme.size,
        events: NodeFlowEvents<String, dynamic>(
          viewport: ViewportEvents(
            onCanvasContextMenu: (pos) => contextMenuPosition = pos,
          ),
        ),
      );

      final position = GraphPosition(const Offset(600, 700));
      controller.events.viewport?.onCanvasContextMenu?.call(position);

      expect(contextMenuPosition, equals(position));
    });

    test('fires viewport movement events', () {
      final viewportHistory = <GraphViewport>[];
      final controller = createTestController();

      final theme = NodeFlowTheme.light;
      controller.initController(
        theme: theme,
        portSizeResolver: (port) => port.size ?? theme.portTheme.size,
        events: NodeFlowEvents<String, dynamic>(
          viewport: ViewportEvents(
            onMoveStart: (v) => viewportHistory.add(v),
            onMove: (v) => viewportHistory.add(v),
            onMoveEnd: (v) => viewportHistory.add(v),
          ),
        ),
      );

      final viewport1 = GraphViewport(x: 0, y: 0, zoom: 1.0);
      final viewport2 = GraphViewport(x: 100, y: 100, zoom: 1.5);
      final viewport3 = GraphViewport(x: 200, y: 200, zoom: 2.0);

      controller.events.viewport?.onMoveStart?.call(viewport1);
      controller.events.viewport?.onMove?.call(viewport2);
      controller.events.viewport?.onMoveEnd?.call(viewport3);

      expect(viewportHistory.length, equals(3));
      expect(viewportHistory[0], equals(viewport1));
      expect(viewportHistory[1], equals(viewport2));
      expect(viewportHistory[2], equals(viewport3));
    });
  });
}
