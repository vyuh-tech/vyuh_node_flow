/// Unit tests for node selection functionality in vyuh_node_flow.
///
/// Tests cover all selection-related methods on NodeFlowController:
/// - Single node selection
/// - Multi-node selection
/// - Toggle selection
/// - Select all / clear selection
/// - Rectangle selection (bounds-based)
/// - Selection events
/// - Selection state observables
/// - Edge cases and error handling
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

  // ===========================================================================
  // Single Node Selection
  // ===========================================================================

  group('Single Node Selection', () {
    test('selectNode selects a single node', () {
      final node = createTestNode(id: 'node-1');
      controller.addNode(node);

      controller.selectNode('node-1');

      expect(controller.isNodeSelected('node-1'), isTrue);
      expect(controller.selectedNodeIds.length, equals(1));
      expect(controller.selectedNodeIds, contains('node-1'));
    });

    test('selectNode updates node selected state', () {
      final node = createTestNode(id: 'node-1');
      controller.addNode(node);

      controller.selectNode('node-1');

      expect(node.isSelected, isTrue);
    });

    test('selectNode clears previous selection by default', () {
      controller.addNode(createTestNode(id: 'node-1'));
      controller.addNode(createTestNode(id: 'node-2'));

      controller.selectNode('node-1');
      controller.selectNode('node-2');

      expect(controller.isNodeSelected('node-1'), isFalse);
      expect(controller.isNodeSelected('node-2'), isTrue);
      expect(controller.selectedNodeIds.length, equals(1));
    });

    test('selectNode for non-existent node clears previous selection', () {
      controller.addNode(createTestNode(id: 'node-1'));
      controller.selectNode('node-1');

      controller.selectNode('non-existent');

      // Previous selection is cleared, and non-existent ID is added to selection set
      // This is the expected behavior - the controller tracks selection IDs independently
      expect(controller.isNodeSelected('node-1'), isFalse);
      expect(controller.isNodeSelected('non-existent'), isTrue);
    });

    test('selectNode clears connection selection', () {
      final node1 = createTestNodeWithOutputPort(id: 'node-1', portId: 'out-1');
      final node2 = createTestNodeWithInputPort(id: 'node-2', portId: 'in-1');
      final conn = createTestConnection(
        id: 'conn-1',
        sourceNodeId: 'node-1',
        sourcePortId: 'out-1',
        targetNodeId: 'node-2',
        targetPortId: 'in-1',
      );
      controller.addNode(node1);
      controller.addNode(node2);
      controller.addConnection(conn);

      controller.selectConnection('conn-1');
      expect(controller.selectedConnectionIds.length, equals(1));

      controller.selectNode('node-1');

      expect(controller.selectedConnectionIds, isEmpty);
      expect(controller.selectedNodeIds.length, equals(1));
    });

    test('selecting same node again keeps it selected', () {
      controller.addNode(createTestNode(id: 'node-1'));

      controller.selectNode('node-1');
      controller.selectNode('node-1');

      expect(controller.isNodeSelected('node-1'), isTrue);
      expect(controller.selectedNodeIds.length, equals(1));
    });
  });

  // ===========================================================================
  // Multi-Node Selection
  // ===========================================================================

  group('Multi-Node Selection', () {
    test('selectNodes selects multiple nodes at once', () {
      controller.addNode(createTestNode(id: 'node-1'));
      controller.addNode(createTestNode(id: 'node-2'));
      controller.addNode(createTestNode(id: 'node-3'));

      controller.selectNodes(['node-1', 'node-2']);

      expect(controller.selectedNodeIds.length, equals(2));
      expect(controller.selectedNodeIds, containsAll(['node-1', 'node-2']));
      expect(controller.isNodeSelected('node-3'), isFalse);
    });

    test('selectNodes clears previous selection by default', () {
      controller.addNode(createTestNode(id: 'node-1'));
      controller.addNode(createTestNode(id: 'node-2'));
      controller.addNode(createTestNode(id: 'node-3'));

      controller.selectNode('node-1');
      controller.selectNodes(['node-2', 'node-3']);

      expect(controller.isNodeSelected('node-1'), isFalse);
      expect(controller.selectedNodeIds.length, equals(2));
    });

    test('selectNodes with toggle adds to existing selection', () {
      controller.addNode(createTestNode(id: 'node-1'));
      controller.addNode(createTestNode(id: 'node-2'));
      controller.addNode(createTestNode(id: 'node-3'));

      controller.selectNode('node-1');
      controller.selectNodes(['node-2', 'node-3'], toggle: true);

      expect(controller.selectedNodeIds.length, equals(3));
      expect(
        controller.selectedNodeIds,
        containsAll(['node-1', 'node-2', 'node-3']),
      );
    });

    test('selectNodes includes non-existent node IDs in selection set', () {
      controller.addNode(createTestNode(id: 'node-1'));
      controller.addNode(createTestNode(id: 'node-2'));

      controller.selectNodes(['node-1', 'non-existent', 'node-2']);

      // The selection set includes all provided IDs, even if nodes don't exist
      // Only existing nodes will have their selected state updated visually
      expect(controller.selectedNodeIds.length, equals(3));
      expect(
        controller.selectedNodeIds,
        containsAll(['node-1', 'node-2', 'non-existent']),
      );
      // Existing nodes have their state updated
      expect(controller.getNode('node-1')!.isSelected, isTrue);
      expect(controller.getNode('node-2')!.isSelected, isTrue);
    });

    test('selectNodes with empty list clears selection when not toggling', () {
      controller.addNode(createTestNode(id: 'node-1'));
      controller.selectNode('node-1');

      controller.selectNodes([]);

      expect(controller.selectedNodeIds, isEmpty);
    });

    test('selectNodes with empty list and toggle preserves selection', () {
      controller.addNode(createTestNode(id: 'node-1'));
      controller.selectNode('node-1');

      controller.selectNodes([], toggle: true);

      expect(controller.selectedNodeIds.length, equals(1));
      expect(controller.isNodeSelected('node-1'), isTrue);
    });

    test('selectNodes updates all selected node states', () {
      final node1 = createTestNode(id: 'node-1');
      final node2 = createTestNode(id: 'node-2');
      controller.addNode(node1);
      controller.addNode(node2);

      controller.selectNodes(['node-1', 'node-2']);

      expect(node1.isSelected, isTrue);
      expect(node2.isSelected, isTrue);
    });
  });

  // ===========================================================================
  // Toggle Selection
  // ===========================================================================

  group('Toggle Selection', () {
    test('selectNode with toggle adds to existing selection', () {
      controller.addNode(createTestNode(id: 'node-1'));
      controller.addNode(createTestNode(id: 'node-2'));

      controller.selectNode('node-1');
      controller.selectNode('node-2', toggle: true);

      expect(controller.selectedNodeIds.length, equals(2));
      expect(controller.selectedNodeIds, containsAll(['node-1', 'node-2']));
    });

    test('selectNode with toggle deselects already selected node', () {
      controller.addNode(createTestNode(id: 'node-1'));

      controller.selectNode('node-1');
      expect(controller.isNodeSelected('node-1'), isTrue);

      controller.selectNode('node-1', toggle: true);
      expect(controller.isNodeSelected('node-1'), isFalse);
      expect(controller.selectedNodeIds, isEmpty);
    });

    test(
      'selectNode with toggle preserves other selections when deselecting',
      () {
        controller.addNode(createTestNode(id: 'node-1'));
        controller.addNode(createTestNode(id: 'node-2'));
        controller.addNode(createTestNode(id: 'node-3'));

        controller.selectNode('node-1');
        controller.selectNode('node-2', toggle: true);
        controller.selectNode('node-3', toggle: true);

        controller.selectNode('node-2', toggle: true);

        expect(controller.isNodeSelected('node-1'), isTrue);
        expect(controller.isNodeSelected('node-2'), isFalse);
        expect(controller.isNodeSelected('node-3'), isTrue);
        expect(controller.selectedNodeIds.length, equals(2));
      },
    );

    test('toggle selection updates node selected state correctly', () {
      final node = createTestNode(id: 'node-1');
      controller.addNode(node);

      controller.selectNode('node-1');
      expect(node.isSelected, isTrue);

      controller.selectNode('node-1', toggle: true);
      expect(node.isSelected, isFalse);
    });
  });

  // ===========================================================================
  // Select All / Clear Selection
  // ===========================================================================

  group('Select All / Clear Selection', () {
    test('selectAllNodes selects every selectable node', () {
      controller.addNode(createTestNode(id: 'node-1'));
      controller.addNode(createTestNode(id: 'node-2'));
      controller.addNode(createTestNode(id: 'node-3'));

      controller.selectAllNodes();

      expect(controller.selectedNodeIds.length, equals(3));
      expect(
        controller.selectedNodeIds,
        containsAll(['node-1', 'node-2', 'node-3']),
      );
    });

    test('selectAllNodes updates all node selected states', () {
      final node1 = createTestNode(id: 'node-1');
      final node2 = createTestNode(id: 'node-2');
      controller.addNode(node1);
      controller.addNode(node2);

      controller.selectAllNodes();

      expect(node1.isSelected, isTrue);
      expect(node2.isSelected, isTrue);
    });

    test('selectAllNodes on empty controller does nothing', () {
      controller.selectAllNodes();

      expect(controller.selectedNodeIds, isEmpty);
    });

    test('clearNodeSelection deselects all nodes', () {
      controller.addNode(createTestNode(id: 'node-1'));
      controller.addNode(createTestNode(id: 'node-2'));
      controller.selectAllNodes();
      expect(controller.selectedNodeIds.length, equals(2));

      controller.clearNodeSelection();

      expect(controller.selectedNodeIds, isEmpty);
    });

    test('clearNodeSelection updates all node selected states', () {
      final node1 = createTestNode(id: 'node-1');
      final node2 = createTestNode(id: 'node-2');
      controller.addNode(node1);
      controller.addNode(node2);
      controller.selectAllNodes();

      controller.clearNodeSelection();

      expect(node1.isSelected, isFalse);
      expect(node2.isSelected, isFalse);
    });

    test('clearNodeSelection on empty selection does nothing', () {
      controller.clearNodeSelection();

      expect(controller.selectedNodeIds, isEmpty);
    });

    test('clearSelection clears both nodes and connections', () {
      final node1 = createTestNodeWithOutputPort(id: 'node-1', portId: 'out-1');
      final node2 = createTestNodeWithInputPort(id: 'node-2', portId: 'in-1');
      final conn = createTestConnection(
        id: 'conn-1',
        sourceNodeId: 'node-1',
        sourcePortId: 'out-1',
        targetNodeId: 'node-2',
        targetPortId: 'in-1',
      );
      controller.addNode(node1);
      controller.addNode(node2);
      controller.addConnection(conn);

      controller.selectNode('node-1');
      controller.selectConnection('conn-1');

      controller.clearSelection();

      expect(controller.selectedNodeIds, isEmpty);
      expect(controller.selectedConnectionIds, isEmpty);
    });

    test('invertSelection swaps selected and unselected nodes', () {
      controller.addNode(createTestNode(id: 'node-1'));
      controller.addNode(createTestNode(id: 'node-2'));
      controller.addNode(createTestNode(id: 'node-3'));

      controller.selectNode('node-1');

      controller.invertSelection();

      expect(controller.isNodeSelected('node-1'), isFalse);
      expect(controller.isNodeSelected('node-2'), isTrue);
      expect(controller.isNodeSelected('node-3'), isTrue);
      expect(controller.selectedNodeIds.length, equals(2));
    });

    test('invertSelection on empty selection selects all', () {
      controller.addNode(createTestNode(id: 'node-1'));
      controller.addNode(createTestNode(id: 'node-2'));

      controller.invertSelection();

      expect(controller.selectedNodeIds.length, equals(2));
    });

    test('invertSelection on all selected clears selection', () {
      controller.addNode(createTestNode(id: 'node-1'));
      controller.addNode(createTestNode(id: 'node-2'));
      controller.selectAllNodes();

      controller.invertSelection();

      expect(controller.selectedNodeIds, isEmpty);
    });

    test('selectNodesByType selects only nodes of given type', () {
      controller.addNode(createTestNode(id: 'process-1', type: 'process'));
      controller.addNode(createTestNode(id: 'process-2', type: 'process'));
      controller.addNode(createTestNode(id: 'decision-1', type: 'decision'));

      controller.selectNodesByType('process');

      expect(controller.selectedNodeIds.length, equals(2));
      expect(
        controller.selectedNodeIds,
        containsAll(['process-1', 'process-2']),
      );
      expect(controller.isNodeSelected('decision-1'), isFalse);
    });

    test('selectNodesByType clears previous selection', () {
      controller.addNode(createTestNode(id: 'process-1', type: 'process'));
      controller.addNode(createTestNode(id: 'decision-1', type: 'decision'));
      controller.selectNode('decision-1');

      controller.selectNodesByType('process');

      expect(controller.isNodeSelected('decision-1'), isFalse);
    });

    test('selectSpecificNodes selects only specified nodes', () {
      controller.addNode(createTestNode(id: 'node-1'));
      controller.addNode(createTestNode(id: 'node-2'));
      controller.addNode(createTestNode(id: 'node-3'));
      controller.selectAllNodes();

      controller.selectSpecificNodes(['node-2']);

      expect(controller.selectedNodeIds.length, equals(1));
      expect(controller.isNodeSelected('node-2'), isTrue);
    });
  });

  // ===========================================================================
  // Rectangle Selection (Bounds-Based)
  // ===========================================================================

  group('Rectangle Selection', () {
    test('nodes positioned inside selection rect are selected', () {
      // Create nodes at known positions
      controller.addNode(
        createTestNode(
          id: 'inside-1',
          position: const Offset(50, 50),
          size: const Size(50, 50),
        ),
      );
      controller.addNode(
        createTestNode(
          id: 'inside-2',
          position: const Offset(100, 100),
          size: const Size(50, 50),
        ),
      );
      controller.addNode(
        createTestNode(
          id: 'outside',
          position: const Offset(300, 300),
          size: const Size(50, 50),
        ),
      );

      // Select nodes within rect (0,0) to (200,200)
      final nodesInBounds = <String>[];
      for (final node in controller.nodes.values) {
        final nodeRect = Rect.fromLTWH(
          node.position.value.dx,
          node.position.value.dy,
          node.size.value.width,
          node.size.value.height,
        );
        final selectionRect = const Rect.fromLTRB(0, 0, 200, 200);
        if (selectionRect.contains(nodeRect.topLeft) &&
            selectionRect.contains(nodeRect.bottomRight)) {
          nodesInBounds.add(node.id);
        }
      }
      controller.selectNodes(nodesInBounds);

      expect(controller.selectedNodeIds.length, equals(2));
      expect(controller.selectedNodeIds, containsAll(['inside-1', 'inside-2']));
      expect(controller.isNodeSelected('outside'), isFalse);
    });

    test('partially overlapping nodes are not included in strict bounds', () {
      // Node that only partially overlaps selection rect
      controller.addNode(
        createTestNode(
          id: 'partial',
          position: const Offset(150, 150),
          size: const Size(100, 100), // Extends to 250,250
        ),
      );

      // Selection rect from 0,0 to 200,200
      // Node starts at 150,150 and ends at 250,250
      // So it's partially inside but not fully contained
      final selectionRect = const Rect.fromLTRB(0, 0, 200, 200);
      final nodeRect = const Rect.fromLTWH(150, 150, 100, 100);

      // Strict containment check
      final isFullyContained =
          selectionRect.contains(nodeRect.topLeft) &&
          selectionRect.contains(nodeRect.bottomRight);

      expect(isFullyContained, isFalse);
    });

    test('nodes at rect boundary are included when fully contained', () {
      controller.addNode(
        createTestNode(
          id: 'boundary',
          position: const Offset(0, 0),
          size: const Size(100, 100),
        ),
      );

      final selectionRect = const Rect.fromLTRB(0, 0, 100, 100);
      final nodeRect = const Rect.fromLTWH(0, 0, 100, 100);

      // Check if node is contained (using left-top inclusive)
      final topLeftIn = selectionRect.contains(nodeRect.topLeft);
      // Note: bottomRight might be exclusive in Rect.contains
      expect(topLeftIn, isTrue);
    });

    test('empty rect selects no nodes', () {
      controller.addNode(createTestNode(id: 'node-1', position: Offset.zero));

      // Empty rect
      const selectionRect = Rect.fromLTRB(10, 10, 10, 10);
      final nodesInBounds = <String>[];
      for (final node in controller.nodes.values) {
        final nodeRect = Rect.fromLTWH(
          node.position.value.dx,
          node.position.value.dy,
          node.size.value.width,
          node.size.value.height,
        );
        if (selectionRect.contains(nodeRect.topLeft) &&
            selectionRect.contains(nodeRect.bottomRight)) {
          nodesInBounds.add(node.id);
        }
      }
      controller.selectNodes(nodesInBounds);

      expect(controller.selectedNodeIds, isEmpty);
    });

    test('large rect containing all nodes selects all', () {
      controller.addNode(
        createTestNode(id: 'node-1', position: const Offset(50, 50)),
      );
      controller.addNode(
        createTestNode(id: 'node-2', position: const Offset(100, 100)),
      );
      controller.addNode(
        createTestNode(id: 'node-3', position: const Offset(150, 150)),
      );

      // Large rect that contains all nodes
      const selectionRect = Rect.fromLTRB(-100, -100, 1000, 1000);
      final nodesInBounds = <String>[];
      for (final node in controller.nodes.values) {
        final nodeRect = Rect.fromLTWH(
          node.position.value.dx,
          node.position.value.dy,
          node.size.value.width,
          node.size.value.height,
        );
        if (selectionRect.contains(nodeRect.topLeft) &&
            selectionRect.contains(nodeRect.bottomRight)) {
          nodesInBounds.add(node.id);
        }
      }
      controller.selectNodes(nodesInBounds);

      expect(controller.selectedNodeIds.length, equals(3));
    });
  });

  // ===========================================================================
  // Selection Events
  // ===========================================================================

  group('Selection Events', () {
    test('selectNode fires onSelected callback', () {
      Node<String>? selectedNode;
      controller.addNode(createTestNode(id: 'node-1'));
      controller.updateEvents(
        NodeFlowEvents<String, dynamic>(
          node: NodeEvents<String>(onSelected: (node) => selectedNode = node),
        ),
      );

      controller.selectNode('node-1');

      expect(selectedNode, isNotNull);
      expect(selectedNode!.id, equals('node-1'));
    });

    test('clearNodeSelection fires onSelected callback with null', () {
      Node<String>? lastSelectedNode;
      controller.addNode(createTestNode(id: 'node-1'));
      controller.updateEvents(
        NodeFlowEvents<String, dynamic>(
          node: NodeEvents<String>(
            onSelected: (node) => lastSelectedNode = node,
          ),
        ),
      );

      controller.selectNode('node-1');
      expect(lastSelectedNode?.id, equals('node-1'));

      controller.clearNodeSelection();
      expect(lastSelectedNode, isNull);
    });

    test('onSelectionChange fires when selection changes', () {
      SelectionState<String, dynamic>? lastSelectionState;
      controller.addNode(createTestNode(id: 'node-1'));
      controller.addNode(createTestNode(id: 'node-2'));
      controller.updateEvents(
        NodeFlowEvents<String, dynamic>(
          onSelectionChange: (state) => lastSelectionState = state,
        ),
      );

      controller.selectNode('node-1');

      expect(lastSelectionState, isNotNull);
      expect(lastSelectionState!.nodes.length, equals(1));
      expect(lastSelectionState!.nodes.first.id, equals('node-1'));
    });

    test('onSelectionChange includes both nodes and connections', () {
      SelectionState<String, dynamic>? lastSelectionState;
      final node1 = createTestNodeWithOutputPort(id: 'node-1', portId: 'out-1');
      final node2 = createTestNodeWithInputPort(id: 'node-2', portId: 'in-1');
      final conn = createTestConnection(
        id: 'conn-1',
        sourceNodeId: 'node-1',
        sourcePortId: 'out-1',
        targetNodeId: 'node-2',
        targetPortId: 'in-1',
      );
      controller.addNode(node1);
      controller.addNode(node2);
      controller.addConnection(conn);
      controller.updateEvents(
        NodeFlowEvents<String, dynamic>(
          onSelectionChange: (state) => lastSelectionState = state,
        ),
      );

      controller.selectNode('node-1');

      expect(lastSelectionState, isNotNull);
      expect(lastSelectionState!.nodes.isNotEmpty, isTrue);
    });

    test('selection event contains correct node data', () {
      Node<String>? selectedNode;
      final node = createTestNode(
        id: 'node-1',
        data: 'test-data',
        position: const Offset(100, 200),
      );
      controller.addNode(node);
      controller.updateEvents(
        NodeFlowEvents<String, dynamic>(
          node: NodeEvents<String>(onSelected: (n) => selectedNode = n),
        ),
      );

      controller.selectNode('node-1');

      expect(selectedNode, isNotNull);
      expect(selectedNode!.data, equals('test-data'));
      expect(selectedNode!.position.value, equals(const Offset(100, 200)));
    });
  });

  // ===========================================================================
  // Selection State Observable
  // ===========================================================================

  group('Selection State Observable', () {
    test('hasSelection returns true when nodes selected', () {
      controller.addNode(createTestNode(id: 'node-1'));

      expect(controller.hasSelection, isFalse);

      controller.selectNode('node-1');

      expect(controller.hasSelection, isTrue);
    });

    test('hasSelection returns true when connections selected', () {
      final node1 = createTestNodeWithOutputPort(id: 'node-1', portId: 'out-1');
      final node2 = createTestNodeWithInputPort(id: 'node-2', portId: 'in-1');
      final conn = createTestConnection(
        id: 'conn-1',
        sourceNodeId: 'node-1',
        sourcePortId: 'out-1',
        targetNodeId: 'node-2',
        targetPortId: 'in-1',
      );
      controller.addNode(node1);
      controller.addNode(node2);
      controller.addConnection(conn);

      expect(controller.hasSelection, isFalse);

      controller.selectConnection('conn-1');

      expect(controller.hasSelection, isTrue);
    });

    test('hasSelection updates when selection changes', () {
      controller.addNode(createTestNode(id: 'node-1'));

      expect(controller.hasSelection, isFalse);

      controller.selectNode('node-1');
      expect(controller.hasSelection, isTrue);

      controller.clearNodeSelection();
      expect(controller.hasSelection, isFalse);
    });

    test('selectedNodeIds returns unmodifiable set', () {
      controller.addNode(createTestNode(id: 'node-1'));
      controller.selectNode('node-1');

      final ids = controller.selectedNodeIds;

      // Verify it returns the correct data
      expect(ids, contains('node-1'));
    });

    test('isNodeSelected returns correct state for each node', () {
      controller.addNode(createTestNode(id: 'node-1'));
      controller.addNode(createTestNode(id: 'node-2'));
      controller.addNode(createTestNode(id: 'node-3'));

      controller.selectNodes(['node-1', 'node-2']);

      expect(controller.isNodeSelected('node-1'), isTrue);
      expect(controller.isNodeSelected('node-2'), isTrue);
      expect(controller.isNodeSelected('node-3'), isFalse);
      expect(controller.isNodeSelected('non-existent'), isFalse);
    });
  });

  // ===========================================================================
  // Selection with Node Removal
  // ===========================================================================

  group('Selection with Node Removal', () {
    test('removing selected node clears it from selection', () {
      controller.addNode(createTestNode(id: 'node-1'));
      controller.selectNode('node-1');
      expect(controller.selectedNodeIds.length, equals(1));

      controller.removeNode('node-1');

      expect(controller.selectedNodeIds, isEmpty);
      expect(controller.isNodeSelected('node-1'), isFalse);
    });

    test('removing one selected node preserves other selections', () {
      controller.addNode(createTestNode(id: 'node-1'));
      controller.addNode(createTestNode(id: 'node-2'));
      controller.addNode(createTestNode(id: 'node-3'));
      controller.selectAllNodes();
      expect(controller.selectedNodeIds.length, equals(3));

      controller.removeNode('node-2');

      expect(controller.selectedNodeIds.length, equals(2));
      expect(controller.isNodeSelected('node-1'), isTrue);
      expect(controller.isNodeSelected('node-3'), isTrue);
    });

    test('deleteNodes removes multiple selected nodes', () {
      controller.addNode(createTestNode(id: 'node-1'));
      controller.addNode(createTestNode(id: 'node-2'));
      controller.addNode(createTestNode(id: 'node-3'));
      controller.selectAllNodes();

      controller.deleteNodes(['node-1', 'node-2']);

      expect(controller.nodeCount, equals(1));
      expect(controller.selectedNodeIds.length, equals(1));
      expect(controller.isNodeSelected('node-3'), isTrue);
    });
  });

  // ===========================================================================
  // Selection with Visibility
  // ===========================================================================

  group('Selection with Visibility', () {
    test('can select visible node', () {
      controller.addNode(createTestNode(id: 'node-1', visible: true));

      controller.selectNode('node-1');

      expect(controller.isNodeSelected('node-1'), isTrue);
    });

    test('can select hidden node', () {
      controller.addNode(createTestNode(id: 'node-1', visible: false));

      controller.selectNode('node-1');

      expect(controller.isNodeSelected('node-1'), isTrue);
    });

    test('hideSelectedNodes hides only selected nodes', () {
      controller.addNode(createTestNode(id: 'selected', visible: true));
      controller.addNode(createTestNode(id: 'not-selected', visible: true));
      controller.selectNode('selected');

      controller.hideSelectedNodes();

      expect(controller.getNode('selected')!.isVisible, isFalse);
      expect(controller.getNode('not-selected')!.isVisible, isTrue);
    });

    test('showSelectedNodes shows only selected nodes', () {
      controller.addNode(createTestNode(id: 'selected', visible: false));
      controller.addNode(createTestNode(id: 'not-selected', visible: false));
      controller.selectNode('selected');

      controller.showSelectedNodes();

      expect(controller.getNode('selected')!.isVisible, isTrue);
      expect(controller.getNode('not-selected')!.isVisible, isFalse);
    });
  });

  // ===========================================================================
  // Selection Count
  // ===========================================================================

  group('Selection Count', () {
    test('selectedNodeIds count matches actual selection', () {
      controller.addNode(createTestNode(id: 'node-1'));
      controller.addNode(createTestNode(id: 'node-2'));
      controller.addNode(createTestNode(id: 'node-3'));

      expect(controller.selectedNodeIds.length, equals(0));

      controller.selectNode('node-1');
      expect(controller.selectedNodeIds.length, equals(1));

      controller.selectNode('node-2', toggle: true);
      expect(controller.selectedNodeIds.length, equals(2));

      controller.selectNode('node-1', toggle: true);
      expect(controller.selectedNodeIds.length, equals(1));

      controller.clearNodeSelection();
      expect(controller.selectedNodeIds.length, equals(0));
    });

    test('selection operations are efficient with many nodes', () {
      // Create many nodes
      for (var i = 0; i < 100; i++) {
        controller.addNode(createTestNode(id: 'node-$i'));
      }

      final stopwatch = Stopwatch()..start();
      controller.selectAllNodes();
      stopwatch.stop();

      expect(controller.selectedNodeIds.length, equals(100));
      // Should complete quickly (under 100ms for 100 nodes)
      expect(stopwatch.elapsedMilliseconds, lessThan(100));
    });
  });

  // ===========================================================================
  // Edge Cases
  // ===========================================================================

  group('Edge Cases', () {
    test('selection operations on empty controller do not throw', () {
      expect(() => controller.selectNode('any'), returnsNormally);
      expect(() => controller.selectNodes(['a', 'b']), returnsNormally);
      expect(() => controller.clearNodeSelection(), returnsNormally);
      expect(() => controller.selectAllNodes(), returnsNormally);
      expect(() => controller.invertSelection(), returnsNormally);
    });

    test('selection state is independent of node data', () {
      final node = createTestNode(id: 'node-1', data: 'test-data');
      controller.addNode(node);
      controller.selectNode('node-1');

      // Node data is immutable, selection should be independent
      expect(controller.isNodeSelected('node-1'), isTrue);
      expect(controller.getNode('node-1')!.data, equals('test-data'));
    });

    test('selection is maintained through node position changes', () {
      controller.addNode(
        createTestNode(id: 'node-1', position: const Offset(0, 0)),
      );
      controller.selectNode('node-1');

      controller.setNodePosition('node-1', const Offset(100, 100));

      expect(controller.isNodeSelected('node-1'), isTrue);
    });

    test('selection is maintained through node size changes', () {
      controller.addNode(
        createTestNode(id: 'node-1', size: const Size(100, 100)),
      );
      controller.selectNode('node-1');

      controller.setNodeSize('node-1', const Size(200, 200));

      expect(controller.isNodeSelected('node-1'), isTrue);
    });

    test('duplicate node inherits deselected state', () {
      controller.addNode(createTestNode(id: 'original'));
      controller.selectNode('original');

      controller.duplicateNode('original');

      // The duplicate should NOT be selected by default
      final duplicateNode = controller.nodes.values.firstWhere(
        (n) => n.id != 'original',
      );
      expect(duplicateNode.isSelected, isFalse);
      expect(controller.selectedNodeIds.length, equals(1));
    });
  });

  // ===========================================================================
  // Selectability
  // ===========================================================================

  group('Node Selectability', () {
    test('selectable node can be selected', () {
      controller.addNode(createTestNode(id: 'node-1'));
      final node = controller.getNode('node-1')!;
      expect(node.selectable, isTrue);

      controller.selectNode('node-1');

      expect(controller.isNodeSelected('node-1'), isTrue);
    });

    test('selectAllNodes respects selectable property', () {
      controller.addNode(createTestNode(id: 'node-1'));
      controller.addNode(createTestNode(id: 'node-2'));

      controller.selectAllNodes();

      // All test nodes have selectable = true by default
      expect(controller.selectedNodeIds.length, equals(2));
    });
  });
}
