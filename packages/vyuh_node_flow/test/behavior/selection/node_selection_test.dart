/// Behavior tests for node selection functionality.
///
/// Tests cover:
/// - Single node selection
/// - Toggle selection mode
/// - Multiple node selection
/// - Selection clearing
/// - Selection state management
/// - Z-index updates on selection
/// - Selection with visibility states
@Tags(['behavior'])
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vyuh_node_flow/vyuh_node_flow.dart';

import '../../helpers/test_factories.dart';

void main() {
  late NodeFlowController<String> controller;

  setUp(() {
    resetTestCounters();
    controller = createTestController();
  });

  group('Single Node Selection', () {
    test('selectNode selects a single node', () {
      final node = createTestNode(id: 'node1');
      controller.addNode(node);

      controller.selectNode('node1');

      expect(controller.isNodeSelected('node1'), isTrue);
      expect(controller.selectedNodeIds.length, equals(1));
    });

    test('selectNode clears previous selection by default', () {
      final node1 = createTestNode(id: 'node1');
      final node2 = createTestNode(id: 'node2');
      controller.addNode(node1);
      controller.addNode(node2);

      controller.selectNode('node1');
      controller.selectNode('node2');

      expect(controller.isNodeSelected('node1'), isFalse);
      expect(controller.isNodeSelected('node2'), isTrue);
      expect(controller.selectedNodeIds.length, equals(1));
    });

    test('selectNode updates node selected state', () {
      final node = createTestNode(id: 'node1');
      controller.addNode(node);

      controller.selectNode('node1');

      final retrievedNode = controller.getNode('node1');
      expect(retrievedNode?.selected.value, isTrue);
    });

    test('selectNode adds non-existent node ID to selection (no validation)', () {
      // Note: The API allows selecting non-existent node IDs without validation
      // This is a design choice for performance - validation happens elsewhere
      controller.selectNode('non-existent');

      // The ID is added to selection even though node doesn't exist
      expect(controller.selectedNodeIds, contains('non-existent'));
    });
  });

  group('Toggle Selection Mode', () {
    test('selectNode with toggle adds to existing selection', () {
      final node1 = createTestNode(id: 'node1');
      final node2 = createTestNode(id: 'node2');
      controller.addNode(node1);
      controller.addNode(node2);

      controller.selectNode('node1');
      controller.selectNode('node2', toggle: true);

      expect(controller.isNodeSelected('node1'), isTrue);
      expect(controller.isNodeSelected('node2'), isTrue);
      expect(controller.selectedNodeIds.length, equals(2));
    });

    test('selectNode with toggle deselects already selected node', () {
      final node = createTestNode(id: 'node1');
      controller.addNode(node);

      controller.selectNode('node1');
      controller.selectNode('node1', toggle: true);

      expect(controller.isNodeSelected('node1'), isFalse);
      expect(controller.selectedNodeIds, isEmpty);
    });

    test(
      'selectNode with toggle preserves other selections when deselecting',
      () {
        final node1 = createTestNode(id: 'node1');
        final node2 = createTestNode(id: 'node2');
        controller.addNode(node1);
        controller.addNode(node2);

        controller.selectNode('node1');
        controller.selectNode('node2', toggle: true);
        controller.selectNode('node1', toggle: true); // Deselect node1

        expect(controller.isNodeSelected('node1'), isFalse);
        expect(controller.isNodeSelected('node2'), isTrue);
        expect(controller.selectedNodeIds.length, equals(1));
      },
    );

    test('toggle on unselected node when others selected adds it', () {
      final node1 = createTestNode(id: 'node1');
      final node2 = createTestNode(id: 'node2');
      final node3 = createTestNode(id: 'node3');
      controller.addNode(node1);
      controller.addNode(node2);
      controller.addNode(node3);

      controller.selectNode('node1');
      controller.selectNode('node2', toggle: true);
      controller.selectNode('node3', toggle: true);

      expect(controller.selectedNodeIds.length, equals(3));
      expect(controller.isNodeSelected('node1'), isTrue);
      expect(controller.isNodeSelected('node2'), isTrue);
      expect(controller.isNodeSelected('node3'), isTrue);
    });
  });

  group('Multiple Node Selection', () {
    test('selectNodes selects multiple nodes at once', () {
      final node1 = createTestNode(id: 'node1');
      final node2 = createTestNode(id: 'node2');
      final node3 = createTestNode(id: 'node3');
      controller.addNode(node1);
      controller.addNode(node2);
      controller.addNode(node3);

      controller.selectNodes(['node1', 'node2', 'node3']);

      expect(controller.selectedNodeIds.length, equals(3));
    });

    test('selectNodes clears previous selection by default', () {
      final node1 = createTestNode(id: 'node1');
      final node2 = createTestNode(id: 'node2');
      final node3 = createTestNode(id: 'node3');
      controller.addNode(node1);
      controller.addNode(node2);
      controller.addNode(node3);

      controller.selectNode('node1');
      controller.selectNodes(['node2', 'node3']);

      expect(controller.isNodeSelected('node1'), isFalse);
      expect(controller.selectedNodeIds.length, equals(2));
    });

    test('selectNodes with toggle adds to existing selection', () {
      final node1 = createTestNode(id: 'node1');
      final node2 = createTestNode(id: 'node2');
      final node3 = createTestNode(id: 'node3');
      controller.addNode(node1);
      controller.addNode(node2);
      controller.addNode(node3);

      controller.selectNode('node1');
      controller.selectNodes(['node2', 'node3'], toggle: true);

      expect(controller.selectedNodeIds.length, equals(3));
    });

    test('selectNodes with toggle removes already selected nodes', () {
      final node1 = createTestNode(id: 'node1');
      final node2 = createTestNode(id: 'node2');
      controller.addNode(node1);
      controller.addNode(node2);

      controller.selectNodes(['node1', 'node2']);
      controller.selectNodes(['node1'], toggle: true);

      expect(controller.isNodeSelected('node1'), isFalse);
      expect(controller.isNodeSelected('node2'), isTrue);
    });

    test(
      'selectNodes adds all IDs including non-existent ones (no validation)',
      () {
        // Note: The API allows selecting non-existent node IDs without validation
        // This is a design choice for performance - validation happens elsewhere
        final node1 = createTestNode(id: 'node1');
        controller.addNode(node1);

        controller.selectNodes(['node1', 'non-existent', 'also-fake']);

        // All IDs are added to selection
        expect(controller.selectedNodeIds.length, equals(3));
        expect(controller.isNodeSelected('node1'), isTrue);
        expect(controller.selectedNodeIds, contains('non-existent'));
        expect(controller.selectedNodeIds, contains('also-fake'));
      },
    );

    test('selectAllNodes selects every node', () {
      final node1 = createTestNode(id: 'node1');
      final node2 = createTestNode(id: 'node2');
      final node3 = createTestNode(id: 'node3');
      controller.addNode(node1);
      controller.addNode(node2);
      controller.addNode(node3);

      controller.selectAllNodes();

      expect(controller.selectedNodeIds.length, equals(3));
    });

    test('selectNodesByType selects nodes of matching type', () {
      final node1 = createTestNode(id: 'node1', type: 'process');
      final node2 = createTestNode(id: 'node2', type: 'decision');
      final node3 = createTestNode(id: 'node3', type: 'process');
      controller.addNode(node1);
      controller.addNode(node2);
      controller.addNode(node3);

      controller.selectNodesByType('process');

      expect(controller.selectedNodeIds.length, equals(2));
      expect(controller.isNodeSelected('node1'), isTrue);
      expect(controller.isNodeSelected('node2'), isFalse);
      expect(controller.isNodeSelected('node3'), isTrue);
    });

    test('selectSpecificNodes replaces selection with exact list', () {
      final node1 = createTestNode(id: 'node1');
      final node2 = createTestNode(id: 'node2');
      final node3 = createTestNode(id: 'node3');
      controller.addNode(node1);
      controller.addNode(node2);
      controller.addNode(node3);

      controller.selectAllNodes();
      controller.selectSpecificNodes(['node2']);

      expect(controller.selectedNodeIds.length, equals(1));
      expect(controller.isNodeSelected('node2'), isTrue);
    });
  });

  group('Selection Clearing', () {
    test('clearNodeSelection deselects all nodes', () {
      final node1 = createTestNode(id: 'node1');
      final node2 = createTestNode(id: 'node2');
      controller.addNode(node1);
      controller.addNode(node2);

      controller.selectNodes(['node1', 'node2']);
      controller.clearNodeSelection();

      expect(controller.selectedNodeIds, isEmpty);
    });

    test('clearNodeSelection updates node selected state', () {
      final node = createTestNode(id: 'node1');
      controller.addNode(node);

      controller.selectNode('node1');
      controller.clearNodeSelection();

      final retrievedNode = controller.getNode('node1');
      expect(retrievedNode?.selected.value, isFalse);
    });

    test('clearNodeSelection on empty selection does nothing', () {
      controller.clearNodeSelection();

      expect(controller.selectedNodeIds, isEmpty);
    });

    test('clearSelection clears both nodes and connections', () {
      final node1 = createTestNodeWithInputPort(id: 'node1', portId: 'in1');
      final node2 = createTestNodeWithOutputPort(id: 'node2', portId: 'out1');
      controller.addNode(node1);
      controller.addNode(node2);

      // Create connection using positional parameters
      controller.createConnection('node2', 'out1', 'node1', 'in1');

      // Get the connection ID to select it
      final connectionId = controller.connectionIds.first;

      controller.selectNode('node1');
      controller.selectConnection(connectionId);
      controller.clearSelection();

      expect(controller.selectedNodeIds, isEmpty);
      expect(controller.selectedConnectionIds, isEmpty);
    });
  });

  group('Selection State Observable', () {
    test('hasSelection returns true when nodes selected', () {
      final node = createTestNode(id: 'node1');
      controller.addNode(node);

      expect(controller.hasSelection, isFalse);

      controller.selectNode('node1');

      expect(controller.hasSelection, isTrue);
    });

    test('hasSelection returns true when connections selected', () {
      final node1 = createTestNodeWithInputPort(id: 'node1', portId: 'in1');
      final node2 = createTestNodeWithOutputPort(id: 'node2', portId: 'out1');
      controller.addNode(node1);
      controller.addNode(node2);

      // Create connection using positional parameters
      controller.createConnection('node2', 'out1', 'node1', 'in1');
      final connectionId = controller.connectionIds.first;

      expect(controller.hasSelection, isFalse);

      controller.selectConnection(connectionId);

      expect(controller.hasSelection, isTrue);
    });

    test('hasSelection updates when selection changes', () {
      final node = createTestNode(id: 'node1');
      controller.addNode(node);

      controller.selectNode('node1');
      expect(controller.hasSelection, isTrue);

      controller.clearNodeSelection();
      expect(controller.hasSelection, isFalse);
    });
  });

  group('Selection with Node Removal', () {
    test('removing selected node clears it from selection', () {
      final node = createTestNode(id: 'node1');
      controller.addNode(node);
      controller.selectNode('node1');

      controller.removeNode('node1');

      expect(controller.selectedNodeIds, isEmpty);
      expect(controller.isNodeSelected('node1'), isFalse);
    });

    test('removing one selected node preserves others', () {
      final node1 = createTestNode(id: 'node1');
      final node2 = createTestNode(id: 'node2');
      controller.addNode(node1);
      controller.addNode(node2);
      controller.selectNodes(['node1', 'node2']);

      controller.removeNode('node1');

      expect(controller.selectedNodeIds.length, equals(1));
      expect(controller.isNodeSelected('node2'), isTrue);
    });
  });

  group('Selection with Visibility', () {
    test('can select hidden node', () {
      final node = createTestNode(id: 'node1', visible: false);
      controller.addNode(node);

      controller.selectNode('node1');

      expect(controller.isNodeSelected('node1'), isTrue);
    });

    test('hiding selected node keeps it selected', () {
      final node = createTestNode(id: 'node1');
      controller.addNode(node);
      controller.selectNode('node1');

      controller.setNodeVisibility('node1', false);

      expect(controller.isNodeSelected('node1'), isTrue);
    });

    test(
      'getVisibleNodes only returns visible selected nodes when filtering',
      () {
        final node1 = createTestNode(id: 'visible', visible: true);
        final node2 = createTestNode(id: 'hidden', visible: false);
        controller.addNode(node1);
        controller.addNode(node2);
        controller.selectNodes(['visible', 'hidden']);

        final visibleNodes = controller.getVisibleNodes();

        expect(visibleNodes.length, equals(1));
        expect(visibleNodes.first.id, equals('visible'));
        // But selection still includes both
        expect(controller.selectedNodeIds.length, equals(2));
      },
    );
  });

  group('Selection Events', () {
    test('selectNode fires onSelected callback', () {
      String? selectedNodeId;
      final node = createTestNode(id: 'node1');
      controller.addNode(node);
      controller.internalUpdateEvents(
        NodeFlowEvents<String>(
          node: NodeEvents<String>(
            onSelected: (n) {
              selectedNodeId = n?.id;
            },
          ),
        ),
      );

      controller.selectNode('node1');

      expect(selectedNodeId, equals('node1'));
    });

    test('clearNodeSelection fires onSelected callback with null', () {
      String? lastSelectedNodeId = 'initial';
      final node = createTestNode(id: 'node1');
      controller.addNode(node);
      controller.internalUpdateEvents(
        NodeFlowEvents<String>(
          node: NodeEvents<String>(
            onSelected: (n) {
              lastSelectedNodeId = n?.id;
            },
          ),
        ),
      );

      controller.selectNode('node1');
      expect(lastSelectedNodeId, equals('node1'));

      controller.clearNodeSelection();
      expect(lastSelectedNodeId, isNull);
    });
  });

  group('Selection with Bounds Filtering', () {
    test('can filter and select nodes by checking bounds manually', () {
      final node1 = createTestNode(id: 'node1', position: const Offset(50, 50));
      final node2 = createTestNode(
        id: 'node2',
        position: const Offset(150, 150),
      );
      final node3 = createTestNode(
        id: 'node3',
        position: const Offset(500, 500),
      );

      controller.addNode(node1);
      controller.addNode(node2);
      controller.addNode(node3);

      controller.setNodeSize('node1', const Size(100, 100));
      controller.setNodeSize('node2', const Size(100, 100));
      controller.setNodeSize('node3', const Size(100, 100));

      // Filter nodes manually by position
      final targetRect = const Rect.fromLTWH(0, 0, 300, 300);
      final nodesInRect = controller.nodes.values.where((node) {
        final bounds = controller.getNodeBounds(node.id);
        return bounds != null && targetRect.overlaps(bounds);
      }).toList();

      final nodeIds = nodesInRect.map((n) => n.id).toList();
      controller.selectNodes(nodeIds);

      expect(controller.isNodeSelected('node1'), isTrue);
      expect(controller.isNodeSelected('node2'), isTrue);
      expect(controller.isNodeSelected('node3'), isFalse);
    });
  });

  group('Invert Selection', () {
    test('invertSelection flips all selection states', () {
      final node1 = createTestNode(id: 'node1');
      final node2 = createTestNode(id: 'node2');
      final node3 = createTestNode(id: 'node3');
      controller.addNode(node1);
      controller.addNode(node2);
      controller.addNode(node3);

      controller.selectNodes(['node1', 'node2']);
      controller.invertSelection();

      expect(controller.isNodeSelected('node1'), isFalse);
      expect(controller.isNodeSelected('node2'), isFalse);
      expect(controller.isNodeSelected('node3'), isTrue);
    });

    test('invertSelection with all selected deselects all', () {
      final node1 = createTestNode(id: 'node1');
      final node2 = createTestNode(id: 'node2');
      controller.addNode(node1);
      controller.addNode(node2);

      controller.selectAllNodes();
      controller.invertSelection();

      expect(controller.selectedNodeIds, isEmpty);
    });

    test('invertSelection with none selected selects all', () {
      final node1 = createTestNode(id: 'node1');
      final node2 = createTestNode(id: 'node2');
      controller.addNode(node1);
      controller.addNode(node2);

      controller.invertSelection();

      expect(controller.selectedNodeIds.length, equals(2));
    });
  });

  group('Selection Count', () {
    test('selectedNodeIds count matches actual selection', () {
      final node1 = createTestNode(id: 'node1');
      final node2 = createTestNode(id: 'node2');
      controller.addNode(node1);
      controller.addNode(node2);

      expect(controller.selectedNodeIds.length, equals(0));

      controller.selectNode('node1');
      expect(controller.selectedNodeIds.length, equals(1));

      controller.selectNode('node2', toggle: true);
      expect(controller.selectedNodeIds.length, equals(2));

      controller.selectNode('node1', toggle: true);
      expect(controller.selectedNodeIds.length, equals(1));

      controller.clearNodeSelection();
      expect(controller.selectedNodeIds.length, equals(0));
    });
  });
}
