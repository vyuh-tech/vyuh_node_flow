/// Unit tests for the NodeFlowController Node API.
///
/// Tests cover:
/// - Node lookup operations (getNode, nodeIds, nodeCount)
/// - Node CRUD operations (addNode, removeNode, duplicateNode)
/// - Port API operations (getPort, addInputPort, removePort)
/// - Visibility API operations (setNodeVisibility, hideAllNodes)
/// - Selection API operations (selectNode, selectNodes, clearNodeSelection)
/// - Z-Order API operations (bringNodeToFront, sendNodeToBack)
/// - Position and size mutations (moveNode, setNodePosition, setNodeSize)
/// - Layout operations (alignNodes, distributeNodes)
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
  // Model APIs - Lookup
  // ===========================================================================

  group('Node Lookup APIs', () {
    test('getNode returns node for existing ID', () {
      final controller = createTestController();
      final node = createTestNode(id: 'node-1');
      controller.addNode(node);

      final result = controller.getNode('node-1');

      expect(result, isNotNull);
      expect(result!.id, equals('node-1'));
    });

    test('getNode returns null for non-existent ID', () {
      final controller = createTestController();

      final result = controller.getNode('non-existent');

      expect(result, isNull);
    });

    test('nodeIds returns all node IDs', () {
      final controller = createTestController();
      controller.addNode(createTestNode(id: 'node-1'));
      controller.addNode(createTestNode(id: 'node-2'));
      controller.addNode(createTestNode(id: 'node-3'));

      final ids = controller.nodeIds.toList();

      expect(ids, hasLength(3));
      expect(ids, containsAll(['node-1', 'node-2', 'node-3']));
    });

    test('nodeIds returns empty for empty graph', () {
      final controller = createTestController();

      final ids = controller.nodeIds.toList();

      expect(ids, isEmpty);
    });

    test('nodeCount returns correct count', () {
      final controller = createTestController();
      controller.addNode(createTestNode(id: 'node-1'));
      controller.addNode(createTestNode(id: 'node-2'));

      expect(controller.nodeCount, equals(2));
    });

    test('nodeCount returns 0 for empty graph', () {
      final controller = createTestController();

      expect(controller.nodeCount, equals(0));
    });

    test('getNodesByType returns nodes of matching type', () {
      final controller = createTestController();
      controller.addNode(createTestNode(id: 'n1', type: 'process'));
      controller.addNode(createTestNode(id: 'n2', type: 'decision'));
      controller.addNode(createTestNode(id: 'n3', type: 'process'));

      final processNodes = controller.getNodesByType('process');

      expect(processNodes, hasLength(2));
      expect(processNodes.map((n) => n.id), containsAll(['n1', 'n3']));
    });

    test('getNodesByType returns empty list for non-matching type', () {
      final controller = createTestController();
      controller.addNode(createTestNode(type: 'process'));

      final terminals = controller.getNodesByType('terminal');

      expect(terminals, isEmpty);
    });
  });

  // ===========================================================================
  // Model APIs - CRUD
  // ===========================================================================

  group('Node CRUD APIs', () {
    test('addNode adds node to controller', () {
      final controller = createTestController();
      final node = createTestNode(id: 'new-node');

      controller.addNode(node);

      expect(controller.nodeCount, equals(1));
      expect(controller.getNode('new-node'), isNotNull);
    });

    test('addNode makes node available in nodes map', () {
      final controller = createTestController();
      final node = createTestNode(id: 'test-node');

      controller.addNode(node);

      expect(controller.nodes['test-node'], equals(node));
    });

    test('addNode with snap-to-grid enabled snaps position', () {
      final controller = createTestController(
        config: NodeFlowConfig(
          extensions: [
            SnapExtension([GridSnapDelegate(gridSize: 20.0)], enabled: true),
          ],
        ),
      );
      final node = createTestNode(position: const Offset(15, 25));

      controller.addNode(node);

      // Should snap to nearest grid point
      final addedNode = controller.getNode(node.id)!;
      expect(addedNode.visualPosition.value.dx % 20, equals(0));
      expect(addedNode.visualPosition.value.dy % 20, equals(0));
    });

    test('removeNode removes node from controller', () {
      final controller = createTestController();
      controller.addNode(createTestNode(id: 'to-remove'));

      controller.removeNode('to-remove');

      expect(controller.getNode('to-remove'), isNull);
      expect(controller.nodeCount, equals(0));
    });

    test('removeNode removes associated connections', () {
      final nodeA = createTestNodeWithOutputPort(id: 'node-a');
      final nodeB = createTestNodeWithInputPort(id: 'node-b');
      final connection = createTestConnection(
        sourceNodeId: 'node-a',
        targetNodeId: 'node-b',
      );
      final controller = createTestController(
        nodes: [nodeA, nodeB],
        connections: [connection],
      );

      controller.removeNode('node-a');

      expect(controller.connections, isEmpty);
    });

    test('removeNode removes node from selection if selected', () {
      final controller = createTestController();
      controller.addNode(createTestNode(id: 'selected-node'));
      controller.selectNode('selected-node');

      controller.removeNode('selected-node');

      expect(controller.selectedNodeIds, isEmpty);
    });

    test('removeNode does nothing for non-existent ID', () {
      final controller = createTestController();
      controller.addNode(createTestNode(id: 'existing'));

      controller.removeNode('non-existent');

      expect(controller.nodeCount, equals(1));
    });

    test('duplicateNode creates copy with new ID', () {
      final controller = createTestController();
      final original = createTestNode(
        id: 'original',
        position: const Offset(100, 100),
      );
      controller.addNode(original);

      controller.duplicateNode('original');

      expect(controller.nodeCount, equals(2));
      final duplicates = controller.nodes.values
          .where((n) => n.id != 'original')
          .toList();
      expect(duplicates, hasLength(1));
      expect(duplicates.first.id, contains('original_copy_'));
    });

    test('duplicateNode positions copy offset from original', () {
      final controller = createTestController();
      controller.addNode(
        createTestNode(id: 'original', position: const Offset(100, 100)),
      );

      controller.duplicateNode('original');

      final duplicate = controller.nodes.values.firstWhere(
        (n) => n.id != 'original',
      );
      expect(duplicate.position.value.dx, equals(150));
      expect(duplicate.position.value.dy, equals(150));
    });

    test('duplicateNode does nothing for non-existent node', () {
      final controller = createTestController();

      controller.duplicateNode('non-existent');

      expect(controller.nodeCount, equals(0));
    });

    test('deleteNodes removes multiple nodes', () {
      final controller = createTestController();
      controller.addNode(createTestNode(id: 'node-1'));
      controller.addNode(createTestNode(id: 'node-2'));
      controller.addNode(createTestNode(id: 'node-3'));

      controller.deleteNodes(['node-1', 'node-3']);

      expect(controller.nodeCount, equals(1));
      expect(controller.getNode('node-2'), isNotNull);
    });
  });

  // ===========================================================================
  // Port APIs
  // ===========================================================================

  group('Port APIs', () {
    test('getPort returns port from node', () {
      final port = createInputPort(id: 'input-port');
      final node = createTestNode(id: 'node-1', inputPorts: [port]);
      final controller = createTestController(nodes: [node]);

      final result = controller.getPort('node-1', 'input-port');

      expect(result, isNotNull);
      expect(result!.id, equals('input-port'));
    });

    test('getPort returns null for non-existent port', () {
      final node = createTestNode(id: 'node-1');
      final controller = createTestController(nodes: [node]);

      final result = controller.getPort('node-1', 'non-existent');

      expect(result, isNull);
    });

    test('getPort returns null for non-existent node', () {
      final controller = createTestController();

      final result = controller.getPort('non-existent', 'port-id');

      expect(result, isNull);
    });

    test('getPort finds port in output ports', () {
      final port = createOutputPort(id: 'output-port');
      final node = createTestNode(id: 'node-1', outputPorts: [port]);
      final controller = createTestController(nodes: [node]);

      final result = controller.getPort('node-1', 'output-port');

      expect(result, isNotNull);
      expect(result!.id, equals('output-port'));
    });

    test('getInputPorts returns all input ports', () {
      final port1 = createInputPort(id: 'in-1');
      final port2 = createInputPort(id: 'in-2');
      final node = createTestNode(id: 'node-1', inputPorts: [port1, port2]);
      final controller = createTestController(nodes: [node]);

      final ports = controller.getInputPorts('node-1');

      expect(ports, hasLength(2));
      expect(ports.map((p) => p.id), containsAll(['in-1', 'in-2']));
    });

    test('getInputPorts returns empty list for non-existent node', () {
      final controller = createTestController();

      final ports = controller.getInputPorts('non-existent');

      expect(ports, isEmpty);
    });

    test('getOutputPorts returns all output ports', () {
      final port1 = createOutputPort(id: 'out-1');
      final port2 = createOutputPort(id: 'out-2');
      final node = createTestNode(id: 'node-1', outputPorts: [port1, port2]);
      final controller = createTestController(nodes: [node]);

      final ports = controller.getOutputPorts('node-1');

      expect(ports, hasLength(2));
    });

    test('addInputPort adds port to node', () {
      final node = createTestNode(id: 'node-1');
      final controller = createTestController(nodes: [node]);
      final newPort = createInputPort(id: 'new-input');

      controller.addInputPort('node-1', newPort);

      expect(controller.getPort('node-1', 'new-input'), isNotNull);
    });

    test('addInputPort does nothing for non-existent node', () {
      final controller = createTestController();
      final newPort = createInputPort(id: 'new-input');

      // Should not throw
      controller.addInputPort('non-existent', newPort);
    });

    test('addOutputPort adds port to node', () {
      final node = createTestNode(id: 'node-1');
      final controller = createTestController(nodes: [node]);
      final newPort = createOutputPort(id: 'new-output');

      controller.addOutputPort('node-1', newPort);

      expect(controller.getPort('node-1', 'new-output'), isNotNull);
    });

    test('removePort removes port from node', () {
      final port = createInputPort(id: 'port-to-remove');
      final node = createTestNode(id: 'node-1', inputPorts: [port]);
      final controller = createTestController(nodes: [node]);

      controller.removePort('node-1', 'port-to-remove');

      expect(controller.getPort('node-1', 'port-to-remove'), isNull);
    });

    test('removePort removes associated connections', () {
      final outPort = createOutputPort(id: 'out-1');
      final inPort = createInputPort(id: 'in-1');
      final nodeA = createTestNode(id: 'node-a', outputPorts: [outPort]);
      final nodeB = createTestNode(id: 'node-b', inputPorts: [inPort]);
      final connection = createTestConnection(
        sourceNodeId: 'node-a',
        sourcePortId: 'out-1',
        targetNodeId: 'node-b',
        targetPortId: 'in-1',
      );
      final controller = createTestController(
        nodes: [nodeA, nodeB],
        connections: [connection],
      );

      controller.removePort('node-a', 'out-1');

      expect(controller.connections, isEmpty);
    });

    test('setNodePorts replaces input ports', () {
      final node = createTestNode(
        id: 'node-1',
        inputPorts: [createInputPort(id: 'old-in')],
      );
      final controller = createTestController(nodes: [node]);
      final newPorts = [
        createInputPort(id: 'new-in-1'),
        createInputPort(id: 'new-in-2'),
      ];

      controller.setNodePorts('node-1', inputPorts: newPorts);

      expect(controller.getInputPorts('node-1'), hasLength(2));
      expect(controller.getPort('node-1', 'old-in'), isNull);
    });

    test('setNodePorts replaces output ports', () {
      final node = createTestNode(
        id: 'node-1',
        outputPorts: [createOutputPort(id: 'old-out')],
      );
      final controller = createTestController(nodes: [node]);
      final newPorts = [createOutputPort(id: 'new-out')];

      controller.setNodePorts('node-1', outputPorts: newPorts);

      expect(controller.getOutputPorts('node-1'), hasLength(1));
      expect(controller.getPort('node-1', 'new-out'), isNotNull);
    });
  });

  // ===========================================================================
  // Visual Query APIs - Bounds
  // ===========================================================================

  group('Node Bounds APIs', () {
    test('getNodeBounds returns correct rectangle', () {
      final node = createTestNode(
        id: 'node-1',
        position: const Offset(100, 200),
        size: const Size(150, 100),
      );
      final controller = createTestController(nodes: [node]);

      final bounds = controller.getNodeBounds('node-1');

      expect(bounds, isNotNull);
      expect(bounds!.left, equals(100));
      expect(bounds.top, equals(200));
      expect(bounds.width, equals(150));
      expect(bounds.height, equals(100));
    });

    test('getNodeBounds returns null for non-existent node', () {
      final controller = createTestController();

      final bounds = controller.getNodeBounds('non-existent');

      expect(bounds, isNull);
    });
  });

  // ===========================================================================
  // Visual Query APIs - Visibility
  // ===========================================================================

  group('Node Visibility APIs', () {
    test('getVisibleNodes returns only visible nodes', () {
      final controller = createTestController();
      controller.addNode(createTestNode(id: 'visible-1', visible: true));
      controller.addNode(createTestNode(id: 'visible-2', visible: true));
      controller.addNode(createTestNode(id: 'hidden', visible: false));

      final visibleNodes = controller.getVisibleNodes();

      expect(visibleNodes, hasLength(2));
      expect(
        visibleNodes.map((n) => n.id),
        containsAll(['visible-1', 'visible-2']),
      );
    });

    test('getHiddenNodes returns only hidden nodes', () {
      final controller = createTestController();
      controller.addNode(createTestNode(id: 'visible', visible: true));
      controller.addNode(createTestNode(id: 'hidden-1', visible: false));
      controller.addNode(createTestNode(id: 'hidden-2', visible: false));

      final hiddenNodes = controller.getHiddenNodes();

      expect(hiddenNodes, hasLength(2));
      expect(
        hiddenNodes.map((n) => n.id),
        containsAll(['hidden-1', 'hidden-2']),
      );
    });

    test('setNodeVisibility sets node visible', () {
      final controller = createTestController();
      controller.addNode(createTestNode(id: 'node-1', visible: false));

      controller.setNodeVisibility('node-1', true);

      expect(controller.getNode('node-1')!.isVisible, isTrue);
    });

    test('setNodeVisibility sets node hidden', () {
      final controller = createTestController();
      controller.addNode(createTestNode(id: 'node-1', visible: true));

      controller.setNodeVisibility('node-1', false);

      expect(controller.getNode('node-1')!.isVisible, isFalse);
    });

    test('setNodesVisibility sets multiple nodes visible', () {
      final controller = createTestController();
      controller.addNode(createTestNode(id: 'node-1', visible: false));
      controller.addNode(createTestNode(id: 'node-2', visible: false));

      controller.setNodesVisibility(['node-1', 'node-2'], true);

      expect(controller.getNode('node-1')!.isVisible, isTrue);
      expect(controller.getNode('node-2')!.isVisible, isTrue);
    });

    test('toggleNodeVisibility toggles visibility', () {
      final controller = createTestController();
      controller.addNode(createTestNode(id: 'node-1', visible: true));

      final result1 = controller.toggleNodeVisibility('node-1');
      expect(result1, isFalse);
      expect(controller.getNode('node-1')!.isVisible, isFalse);

      final result2 = controller.toggleNodeVisibility('node-1');
      expect(result2, isTrue);
      expect(controller.getNode('node-1')!.isVisible, isTrue);
    });

    test('toggleNodeVisibility returns null for non-existent node', () {
      final controller = createTestController();

      final result = controller.toggleNodeVisibility('non-existent');

      expect(result, isNull);
    });

    test('hideAllNodes hides all nodes', () {
      final controller = createTestController();
      controller.addNode(createTestNode(id: 'node-1', visible: true));
      controller.addNode(createTestNode(id: 'node-2', visible: true));

      controller.hideAllNodes();

      expect(controller.getNode('node-1')!.isVisible, isFalse);
      expect(controller.getNode('node-2')!.isVisible, isFalse);
    });

    test('showAllNodes shows all nodes', () {
      final controller = createTestController();
      controller.addNode(createTestNode(id: 'node-1', visible: false));
      controller.addNode(createTestNode(id: 'node-2', visible: false));

      controller.showAllNodes();

      expect(controller.getNode('node-1')!.isVisible, isTrue);
      expect(controller.getNode('node-2')!.isVisible, isTrue);
    });

    test('hideSelectedNodes hides only selected nodes', () {
      final controller = createTestController();
      controller.addNode(createTestNode(id: 'selected', visible: true));
      controller.addNode(createTestNode(id: 'not-selected', visible: true));
      controller.selectNode('selected');

      controller.hideSelectedNodes();

      expect(controller.getNode('selected')!.isVisible, isFalse);
      expect(controller.getNode('not-selected')!.isVisible, isTrue);
    });

    test('showSelectedNodes shows only selected nodes', () {
      final controller = createTestController();
      controller.addNode(createTestNode(id: 'selected', visible: false));
      controller.addNode(createTestNode(id: 'not-selected', visible: false));
      controller.selectNode('selected');

      controller.showSelectedNodes();

      expect(controller.getNode('selected')!.isVisible, isTrue);
      expect(controller.getNode('not-selected')!.isVisible, isFalse);
    });
  });

  // ===========================================================================
  // Selection APIs
  // ===========================================================================

  group('Node Selection APIs', () {
    test('selectNode selects a node', () {
      final controller = createTestController();
      controller.addNode(createTestNode(id: 'node-1'));

      controller.selectNode('node-1');

      expect(controller.selectedNodeIds, contains('node-1'));
      expect(controller.getNode('node-1')!.isSelected, isTrue);
    });

    test('selectNode clears previous selection by default', () {
      final controller = createTestController();
      controller.addNode(createTestNode(id: 'node-1'));
      controller.addNode(createTestNode(id: 'node-2'));
      controller.selectNode('node-1');

      controller.selectNode('node-2');

      expect(controller.selectedNodeIds, hasLength(1));
      expect(controller.selectedNodeIds, contains('node-2'));
      expect(controller.getNode('node-1')!.isSelected, isFalse);
    });

    test('selectNode with toggle adds to selection', () {
      final controller = createTestController();
      controller.addNode(createTestNode(id: 'node-1'));
      controller.addNode(createTestNode(id: 'node-2'));
      controller.selectNode('node-1');

      controller.selectNode('node-2', toggle: true);

      expect(controller.selectedNodeIds, hasLength(2));
      expect(controller.selectedNodeIds, containsAll(['node-1', 'node-2']));
    });

    test('selectNode with toggle removes if already selected', () {
      final controller = createTestController();
      controller.addNode(createTestNode(id: 'node-1'));
      controller.selectNode('node-1');

      controller.selectNode('node-1', toggle: true);

      expect(controller.selectedNodeIds, isEmpty);
      expect(controller.getNode('node-1')!.isSelected, isFalse);
    });

    test('selectNodes selects multiple nodes', () {
      final controller = createTestController();
      controller.addNode(createTestNode(id: 'node-1'));
      controller.addNode(createTestNode(id: 'node-2'));
      controller.addNode(createTestNode(id: 'node-3'));

      controller.selectNodes(['node-1', 'node-2']);

      expect(controller.selectedNodeIds, hasLength(2));
      expect(controller.selectedNodeIds, containsAll(['node-1', 'node-2']));
    });

    test('selectNodes clears previous selection by default', () {
      final controller = createTestController();
      controller.addNode(createTestNode(id: 'node-1'));
      controller.addNode(createTestNode(id: 'node-2'));
      controller.addNode(createTestNode(id: 'node-3'));
      controller.selectNode('node-1');

      controller.selectNodes(['node-2', 'node-3']);

      expect(controller.selectedNodeIds, hasLength(2));
      expect(controller.selectedNodeIds, isNot(contains('node-1')));
    });

    test('selectNodes with toggle adds to selection', () {
      final controller = createTestController();
      controller.addNode(createTestNode(id: 'node-1'));
      controller.addNode(createTestNode(id: 'node-2'));
      controller.addNode(createTestNode(id: 'node-3'));
      controller.selectNode('node-1');

      controller.selectNodes(['node-2', 'node-3'], toggle: true);

      expect(controller.selectedNodeIds, hasLength(3));
    });

    test('clearNodeSelection clears all node selections', () {
      final controller = createTestController();
      controller.addNode(createTestNode(id: 'node-1'));
      controller.addNode(createTestNode(id: 'node-2'));
      controller.selectNodes(['node-1', 'node-2']);

      controller.clearNodeSelection();

      expect(controller.selectedNodeIds, isEmpty);
      expect(controller.getNode('node-1')!.isSelected, isFalse);
      expect(controller.getNode('node-2')!.isSelected, isFalse);
    });

    test('isNodeSelected returns true for selected node', () {
      final controller = createTestController();
      controller.addNode(createTestNode(id: 'node-1'));
      controller.selectNode('node-1');

      expect(controller.isNodeSelected('node-1'), isTrue);
    });

    test('isNodeSelected returns false for unselected node', () {
      final controller = createTestController();
      controller.addNode(createTestNode(id: 'node-1'));

      expect(controller.isNodeSelected('node-1'), isFalse);
    });

    test('selectNode clears connection selection', () {
      final nodeA = createTestNodeWithOutputPort(id: 'node-a');
      final nodeB = createTestNodeWithInputPort(id: 'node-b');
      final connection = createTestConnection(
        id: 'conn-1',
        sourceNodeId: 'node-a',
        targetNodeId: 'node-b',
      );
      final controller = createTestController(
        nodes: [nodeA, nodeB],
        connections: [connection],
      );
      controller.selectConnection('conn-1');

      controller.selectNode('node-a');

      expect(controller.selectedConnectionIds, isEmpty);
    });
  });

  // ===========================================================================
  // Z-Order APIs
  // ===========================================================================

  group('Node Z-Order APIs', () {
    test('bringNodeToFront moves node to top z-index', () {
      final controller = createTestController();
      controller.addNode(createTestNode(id: 'node-1', zIndex: 0));
      controller.addNode(createTestNode(id: 'node-2', zIndex: 5));
      controller.addNode(createTestNode(id: 'node-3', zIndex: 10));

      controller.bringNodeToFront('node-1');

      final node1 = controller.getNode('node-1')!;
      expect(node1.currentZIndex, greaterThan(10));
    });

    test('sendNodeToBack moves node to bottom z-index', () {
      final controller = createTestController();
      controller.addNode(createTestNode(id: 'node-1', zIndex: 0));
      controller.addNode(createTestNode(id: 'node-2', zIndex: 5));
      controller.addNode(createTestNode(id: 'node-3', zIndex: 10));

      controller.sendNodeToBack('node-3');

      final node3 = controller.getNode('node-3')!;
      expect(node3.currentZIndex, lessThan(0));
    });

    test('bringNodeForward moves node one step up', () {
      final controller = createTestController();
      controller.addNode(createTestNode(id: 'node-1', zIndex: 0));
      controller.addNode(createTestNode(id: 'node-2', zIndex: 1));

      controller.bringNodeForward('node-1');

      final node1 = controller.getNode('node-1')!;
      final node2 = controller.getNode('node-2')!;
      expect(node1.currentZIndex, greaterThan(node2.currentZIndex));
    });

    test('sendNodeBackward moves node one step down', () {
      final controller = createTestController();
      controller.addNode(createTestNode(id: 'node-1', zIndex: 0));
      controller.addNode(createTestNode(id: 'node-2', zIndex: 1));

      controller.sendNodeBackward('node-2');

      final node1 = controller.getNode('node-1')!;
      final node2 = controller.getNode('node-2')!;
      expect(node2.currentZIndex, lessThan(node1.currentZIndex));
    });

    test('bringNodeToFront does nothing for non-existent node', () {
      final controller = createTestController();

      // Should not throw
      controller.bringNodeToFront('non-existent');
    });
  });

  // ===========================================================================
  // Mutation APIs - Position
  // ===========================================================================

  group('Node Position APIs', () {
    test('moveNode moves node by delta', () {
      final controller = createTestController();
      controller.addNode(
        createTestNode(id: 'node-1', position: const Offset(100, 100)),
      );

      controller.moveNode('node-1', const Offset(50, 30));

      final node = controller.getNode('node-1')!;
      expect(node.position.value, equals(const Offset(150, 130)));
    });

    test('moveNode does nothing for non-existent node', () {
      final controller = createTestController();

      // Should not throw
      controller.moveNode('non-existent', const Offset(50, 30));
    });

    test('moveSelectedNodes moves all selected nodes', () {
      final controller = createTestController();
      controller.addNode(
        createTestNode(id: 'node-1', position: const Offset(100, 100)),
      );
      controller.addNode(
        createTestNode(id: 'node-2', position: const Offset(200, 200)),
      );
      controller.selectNodes(['node-1', 'node-2']);

      controller.moveSelectedNodes(const Offset(25, 25));

      expect(
        controller.getNode('node-1')!.position.value,
        equals(const Offset(125, 125)),
      );
      expect(
        controller.getNode('node-2')!.position.value,
        equals(const Offset(225, 225)),
      );
    });

    test('setNodePosition sets absolute position', () {
      final controller = createTestController();
      controller.addNode(
        createTestNode(id: 'node-1', position: const Offset(100, 100)),
      );

      controller.setNodePosition('node-1', const Offset(300, 400));

      expect(
        controller.getNode('node-1')!.position.value,
        equals(const Offset(300, 400)),
      );
    });

    test('setNodePosition does nothing for non-existent node', () {
      final controller = createTestController();

      // Should not throw
      controller.setNodePosition('non-existent', const Offset(300, 400));
    });

    test('setNodePosition with snap-to-grid snaps visual position', () {
      final controller = createTestController(
        config: NodeFlowConfig(
          extensions: [
            SnapExtension([GridSnapDelegate(gridSize: 20.0)], enabled: true),
          ],
        ),
      );
      controller.addNode(createTestNode(id: 'node-1'));

      controller.setNodePosition('node-1', const Offset(105, 115));

      final node = controller.getNode('node-1')!;
      expect(node.visualPosition.value.dx % 20, equals(0));
      expect(node.visualPosition.value.dy % 20, equals(0));
    });
  });

  // ===========================================================================
  // Mutation APIs - Size
  // ===========================================================================

  group('Node Size APIs', () {
    test('setNodeSize updates node size', () {
      final controller = createTestController();
      controller.addNode(
        createTestNode(id: 'node-1', size: const Size(100, 100)),
      );

      controller.setNodeSize('node-1', const Size(200, 150));

      expect(
        controller.getNode('node-1')!.size.value,
        equals(const Size(200, 150)),
      );
    });

    test('setNodeSize does nothing for non-existent node', () {
      final controller = createTestController();

      // Should not throw
      controller.setNodeSize('non-existent', const Size(200, 150));
    });
  });

  // ===========================================================================
  // Layout APIs
  // ===========================================================================

  group('Node Layout APIs', () {
    test('alignNodes aligns nodes to left', () {
      final controller = createTestController();
      controller.addNode(
        createTestNode(id: 'node-1', position: const Offset(50, 100)),
      );
      controller.addNode(
        createTestNode(id: 'node-2', position: const Offset(150, 200)),
      );

      controller.alignNodes(['node-1', 'node-2'], NodeAlignment.left);

      expect(controller.getNode('node-1')!.position.value.dx, equals(50));
      expect(controller.getNode('node-2')!.position.value.dx, equals(50));
    });

    test('alignNodes aligns nodes to top', () {
      final controller = createTestController();
      controller.addNode(
        createTestNode(id: 'node-1', position: const Offset(50, 100)),
      );
      controller.addNode(
        createTestNode(id: 'node-2', position: const Offset(150, 200)),
      );

      controller.alignNodes(['node-1', 'node-2'], NodeAlignment.top);

      expect(controller.getNode('node-1')!.position.value.dy, equals(100));
      expect(controller.getNode('node-2')!.position.value.dy, equals(100));
    });

    test('alignNodes requires at least 2 nodes', () {
      final controller = createTestController();
      controller.addNode(
        createTestNode(id: 'node-1', position: const Offset(50, 100)),
      );

      // Should not throw or change anything
      controller.alignNodes(['node-1'], NodeAlignment.left);

      expect(
        controller.getNode('node-1')!.position.value,
        equals(const Offset(50, 100)),
      );
    });

    test('distributeNodesHorizontally distributes evenly', () {
      final controller = createTestController();
      controller.addNode(
        createTestNode(id: 'node-1', position: const Offset(0, 0)),
      );
      controller.addNode(
        createTestNode(id: 'node-2', position: const Offset(100, 0)),
      );
      controller.addNode(
        createTestNode(id: 'node-3', position: const Offset(300, 0)),
      );

      controller.distributeNodesHorizontally(['node-1', 'node-2', 'node-3']);

      // node-1 stays at 0, node-3 stays at 300
      // node-2 should be at 150 (middle)
      expect(controller.getNode('node-2')!.position.value.dx, closeTo(150, 1));
    });

    test('distributeNodesHorizontally requires at least 3 nodes', () {
      final controller = createTestController();
      controller.addNode(
        createTestNode(id: 'node-1', position: const Offset(0, 0)),
      );
      controller.addNode(
        createTestNode(id: 'node-2', position: const Offset(100, 0)),
      );

      // Should not throw or change anything
      controller.distributeNodesHorizontally(['node-1', 'node-2']);
    });

    test('distributeNodesVertically distributes evenly', () {
      final controller = createTestController();
      controller.addNode(
        createTestNode(id: 'node-1', position: const Offset(0, 0)),
      );
      controller.addNode(
        createTestNode(id: 'node-2', position: const Offset(0, 100)),
      );
      controller.addNode(
        createTestNode(id: 'node-3', position: const Offset(0, 400)),
      );

      controller.distributeNodesVertically(['node-1', 'node-2', 'node-3']);

      // node-1 stays at 0, node-3 stays at 400
      // node-2 should be at 200 (middle)
      expect(controller.getNode('node-2')!.position.value.dy, closeTo(200, 1));
    });
  });

  // ===========================================================================
  // Edge Cases
  // ===========================================================================

  group('Edge Cases', () {
    test('operations on empty controller do not throw', () {
      final controller = createTestController();

      expect(() => controller.getNode('any'), returnsNormally);
      expect(() => controller.removeNode('any'), returnsNormally);
      expect(() => controller.selectNode('any'), returnsNormally);
      expect(() => controller.clearNodeSelection(), returnsNormally);
      expect(() => controller.moveNode('any', Offset.zero), returnsNormally);
    });

    test('duplicate IDs are overwritten when adding nodes', () {
      final controller = createTestController();
      final node1 = createTestNode(id: 'same-id', data: 'first');
      final node2 = createTestNode(id: 'same-id', data: 'second');

      controller.addNode(node1);
      controller.addNode(node2);

      expect(controller.nodeCount, equals(1));
      expect(controller.getNode('same-id')!.data, equals('second'));
    });
  });
}
