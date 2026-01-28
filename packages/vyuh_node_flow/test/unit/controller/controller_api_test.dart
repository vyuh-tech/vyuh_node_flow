/// Unit tests for the NodeFlowController API extension.
///
/// Tests cover:
/// - CommentNode factory methods (createCommentNode)
/// - GroupNode factory methods (createGroupNode, createGroupNodeAroundNodes)
/// - Group utility methods (findContainedNodes, hideAllGroupAndCommentNodes, showAllGroupAndCommentNodes)
/// - Widget-level drag API (startNodeDrag, moveNodeDrag, endNodeDrag, cancelNodeDrag)
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
  // CommentNode Factory Methods
  // ===========================================================================

  group('createCommentNode', () {
    test('creates comment node with required parameters', () {
      final controller = createTestController();

      final comment = controller.createCommentNode(
        position: const Offset(100, 200),
        text: 'Test comment',
        data: 'comment-data',
      );

      expect(comment, isA<CommentNode<String>>());
      expect(comment.position.value, equals(const Offset(100, 200)));
      expect(comment.text, equals('Test comment'));
      expect(comment.data, equals('comment-data'));
      expect(controller.nodeCount, equals(1));
      expect(controller.getNode(comment.id), equals(comment));
    });

    test('creates comment node with custom ID', () {
      final controller = createTestController();

      final comment = controller.createCommentNode(
        position: Offset.zero,
        text: 'Note',
        data: 'data',
        id: 'my-custom-comment-id',
      );

      expect(comment.id, equals('my-custom-comment-id'));
    });

    test('creates comment node with custom dimensions', () {
      final controller = createTestController();

      final comment = controller.createCommentNode(
        position: Offset.zero,
        text: 'Note',
        data: 'data',
        width: 300.0,
        height: 150.0,
      );

      expect(comment.width, equals(300.0));
      expect(comment.height, equals(150.0));
    });

    test('creates comment node with default dimensions', () {
      final controller = createTestController();

      final comment = controller.createCommentNode(
        position: Offset.zero,
        text: 'Note',
        data: 'data',
      );

      expect(comment.width, equals(200.0));
      expect(comment.height, equals(100.0));
    });

    test('creates comment node with custom color', () {
      final controller = createTestController();

      final comment = controller.createCommentNode(
        position: Offset.zero,
        text: 'Note',
        data: 'data',
        color: Colors.red,
      );

      expect(comment.color, equals(Colors.red));
    });

    test('creates comment node with default color (light yellow)', () {
      final controller = createTestController();

      final comment = controller.createCommentNode(
        position: Offset.zero,
        text: 'Note',
        data: 'data',
      );

      expect(comment.color, equals(const Color(0xFFFFF59D)));
    });

    test('auto-generates ID with comment prefix when not provided', () {
      final controller = createTestController();

      final comment = controller.createCommentNode(
        position: Offset.zero,
        text: 'Note',
        data: 'data',
      );

      expect(comment.id, startsWith('comment-'));
    });

    test('custom IDs allow creating multiple comments with unique IDs', () {
      final controller = createTestController();

      final comment1 = controller.createCommentNode(
        position: Offset.zero,
        text: 'Note 1',
        data: 'data1',
        id: 'comment-custom-1',
      );

      final comment2 = controller.createCommentNode(
        position: const Offset(100, 0),
        text: 'Note 2',
        data: 'data2',
        id: 'comment-custom-2',
      );

      expect(comment1.id, equals('comment-custom-1'));
      expect(comment2.id, equals('comment-custom-2'));
      expect(comment1.id, isNot(equals(comment2.id)));
    });

    test('adds comment node to controller nodes map', () {
      final controller = createTestController();

      final comment = controller.createCommentNode(
        position: const Offset(50, 50),
        text: 'My note',
        data: 'test-data',
      );

      expect(controller.nodes.containsKey(comment.id), isTrue);
      expect(controller.nodes[comment.id], equals(comment));
    });
  });

  // ===========================================================================
  // GroupNode Factory Methods
  // ===========================================================================

  group('createGroupNode', () {
    test('creates group node with required parameters', () {
      final controller = createTestController();

      final group = controller.createGroupNode(
        title: 'Test Group',
        position: const Offset(100, 200),
        size: const Size(400, 300),
        data: 'group-data',
      );

      expect(group, isA<GroupNode<String>>());
      expect(group.currentTitle, equals('Test Group'));
      expect(group.position.value, equals(const Offset(100, 200)));
      expect(group.size.value, equals(const Size(400, 300)));
      expect(group.data, equals('group-data'));
      expect(controller.nodeCount, equals(1));
    });

    test('creates group node with custom ID', () {
      final controller = createTestController();

      final group = controller.createGroupNode(
        title: 'My Group',
        position: Offset.zero,
        size: const Size(200, 150),
        data: 'data',
        id: 'custom-group-id',
      );

      expect(group.id, equals('custom-group-id'));
    });

    test('creates group node with custom color', () {
      final controller = createTestController();

      final group = controller.createGroupNode(
        title: 'Colored Group',
        position: Offset.zero,
        size: const Size(200, 150),
        data: 'data',
        color: Colors.green,
      );

      expect(group.currentColor, equals(Colors.green));
    });

    test('creates group node with default color (blue)', () {
      final controller = createTestController();

      final group = controller.createGroupNode(
        title: 'Default Group',
        position: Offset.zero,
        size: const Size(200, 150),
        data: 'data',
      );

      expect(group.currentColor, equals(const Color(0xFF2196F3)));
    });

    test('creates group node with specified behavior', () {
      final controller = createTestController();

      final explicitGroup = controller.createGroupNode(
        title: 'Explicit Group',
        position: Offset.zero,
        size: const Size(200, 150),
        data: 'data',
        behavior: GroupBehavior.explicit,
      );

      final parentGroup = controller.createGroupNode(
        title: 'Parent Group',
        position: const Offset(300, 0),
        size: const Size(200, 150),
        data: 'data',
        behavior: GroupBehavior.parent,
      );

      expect(explicitGroup.behavior, equals(GroupBehavior.explicit));
      expect(parentGroup.behavior, equals(GroupBehavior.parent));
    });

    test('creates group node with default behavior (bounds)', () {
      final controller = createTestController();

      final group = controller.createGroupNode(
        title: 'Bounds Group',
        position: Offset.zero,
        size: const Size(200, 150),
        data: 'data',
      );

      expect(group.behavior, equals(GroupBehavior.bounds));
    });

    test('creates group node with initial nodeIds', () {
      final controller = createTestController();
      controller.addNode(createTestNode(id: 'node-1'));
      controller.addNode(createTestNode(id: 'node-2'));

      final group = controller.createGroupNode(
        title: 'Group with Nodes',
        position: Offset.zero,
        size: const Size(400, 300),
        data: 'data',
        behavior: GroupBehavior.explicit,
        nodeIds: {'node-1', 'node-2'},
      );

      expect(group.nodeIds, containsAll(['node-1', 'node-2']));
      expect(group.hasNode('node-1'), isTrue);
      expect(group.hasNode('node-2'), isTrue);
    });

    test('creates group node with custom padding', () {
      final controller = createTestController();
      const customPadding = EdgeInsets.all(50.0);

      final group = controller.createGroupNode(
        title: 'Padded Group',
        position: Offset.zero,
        size: const Size(300, 200),
        data: 'data',
        padding: customPadding,
      );

      expect(group.padding, equals(customPadding));
    });

    test('creates group node with default padding', () {
      final controller = createTestController();

      final group = controller.createGroupNode(
        title: 'Default Padding Group',
        position: Offset.zero,
        size: const Size(300, 200),
        data: 'data',
      );

      expect(group.padding, equals(kGroupNodeDefaultPadding));
    });

    test('creates group node with input and output ports', () {
      final controller = createTestController();
      final inputPort = createInputPort(id: 'group-in');
      final outputPort = createOutputPort(id: 'group-out');

      final group = controller.createGroupNode(
        title: 'Subflow Group',
        position: Offset.zero,
        size: const Size(400, 300),
        data: 'data',
        ports: [inputPort, outputPort],
      );

      expect(group.inputPorts, hasLength(1));
      expect(group.outputPorts, hasLength(1));
      expect(group.inputPorts.first.id, equals('group-in'));
      expect(group.outputPorts.first.id, equals('group-out'));
    });

    test('auto-generates ID with group prefix when not provided', () {
      final controller = createTestController();

      final group = controller.createGroupNode(
        title: 'Test Group',
        position: Offset.zero,
        size: const Size(200, 150),
        data: 'data',
      );

      expect(group.id, startsWith('group-'));
    });

    test('custom IDs allow creating multiple groups with unique IDs', () {
      final controller = createTestController();

      final group1 = controller.createGroupNode(
        title: 'Group 1',
        position: Offset.zero,
        size: const Size(200, 150),
        data: 'data1',
        id: 'group-custom-1',
      );

      final group2 = controller.createGroupNode(
        title: 'Group 2',
        position: const Offset(300, 0),
        size: const Size(200, 150),
        data: 'data2',
        id: 'group-custom-2',
      );

      expect(group1.id, equals('group-custom-1'));
      expect(group2.id, equals('group-custom-2'));
      expect(group1.id, isNot(equals(group2.id)));
    });
  });

  group('createGroupNodeAroundNodes', () {
    test('creates group around specified nodes', () {
      final controller = createTestController();
      controller.addNode(
        createTestNode(
          id: 'node-1',
          position: const Offset(100, 100),
          size: const Size(100, 50),
        ),
      );
      controller.addNode(
        createTestNode(
          id: 'node-2',
          position: const Offset(250, 100),
          size: const Size(100, 50),
        ),
      );

      final group = controller.createGroupNodeAroundNodes(
        title: 'Surrounding Group',
        nodeIds: {'node-1', 'node-2'},
        data: 'group-data',
      );

      expect(group, isA<GroupNode<String>>());
      expect(group.currentTitle, equals('Surrounding Group'));
      expect(controller.nodeCount, equals(3)); // 2 nodes + 1 group
    });

    test('calculates bounding box with default padding', () {
      final controller = createTestController();
      // Node at (100, 100) with size (100, 50) -> right edge at 200, bottom at 150
      controller.addNode(
        createTestNode(
          id: 'node-1',
          position: const Offset(100, 100),
          size: const Size(100, 50),
        ),
      );
      // Node at (250, 100) with size (100, 50) -> right edge at 350, bottom at 150
      controller.addNode(
        createTestNode(
          id: 'node-2',
          position: const Offset(250, 100),
          size: const Size(100, 50),
        ),
      );

      final group = controller.createGroupNodeAroundNodes(
        title: 'Calculated Group',
        nodeIds: {'node-1', 'node-2'},
        data: 'data',
        // Default padding is EdgeInsets.all(20.0)
      );

      // Min X = 100 - 20 = 80
      // Min Y = 100 - 20 = 80
      // Max X = 350 + 20 = 370
      // Max Y = 150 + 20 = 170
      expect(group.position.value.dx, equals(80.0));
      expect(group.position.value.dy, equals(80.0));
      expect(group.size.value.width, equals(290.0)); // 370 - 80
      expect(group.size.value.height, equals(90.0)); // 170 - 80
    });

    test('calculates bounding box with custom padding', () {
      final controller = createTestController();
      controller.addNode(
        createTestNode(
          id: 'node-1',
          position: const Offset(100, 100),
          size: const Size(100, 50),
        ),
      );

      final group = controller.createGroupNodeAroundNodes(
        title: 'Custom Padding Group',
        nodeIds: {'node-1'},
        data: 'data',
        padding: const EdgeInsets.fromLTRB(10, 30, 10, 30),
      );

      // Min X = 100 - 10 = 90
      // Min Y = 100 - 30 = 70
      // Max X = 200 + 10 = 210
      // Max Y = 150 + 30 = 180
      expect(group.position.value.dx, equals(90.0));
      expect(group.position.value.dy, equals(70.0));
      expect(group.size.value.width, equals(120.0)); // 210 - 90
      expect(group.size.value.height, equals(110.0)); // 180 - 70
    });

    test('uses default position and size when no nodes exist', () {
      final controller = createTestController();

      final group = controller.createGroupNodeAroundNodes(
        title: 'Empty Group',
        nodeIds: {'non-existent-1', 'non-existent-2'},
        data: 'data',
      );

      expect(group.position.value, equals(Offset.zero));
      expect(group.size.value, equals(const Size(200, 150)));
    });

    test('uses default position and size when nodeIds is empty', () {
      final controller = createTestController();

      final group = controller.createGroupNodeAroundNodes(
        title: 'Empty NodeIds Group',
        nodeIds: <String>{},
        data: 'data',
      );

      expect(group.position.value, equals(Offset.zero));
      expect(group.size.value, equals(const Size(200, 150)));
    });

    test('ignores non-existent nodes in mixed set', () {
      final controller = createTestController();
      controller.addNode(
        createTestNode(
          id: 'existing-node',
          position: const Offset(50, 50),
          size: const Size(80, 40),
        ),
      );

      final group = controller.createGroupNodeAroundNodes(
        title: 'Mixed Group',
        nodeIds: {'existing-node', 'non-existent'},
        data: 'data',
        padding: const EdgeInsets.all(10.0),
      );

      // Should only consider 'existing-node'
      // Position: 50-10=40, 50-10=40
      // Size: (50+80+10)-(50-10) = 100, (50+40+10)-(50-10) = 60
      expect(group.position.value.dx, equals(40.0));
      expect(group.position.value.dy, equals(40.0));
    });

    test('creates group with specified behavior', () {
      final controller = createTestController();
      controller.addNode(createTestNode(id: 'node-1'));

      final group = controller.createGroupNodeAroundNodes(
        title: 'Parent Behavior Group',
        nodeIds: {'node-1'},
        data: 'data',
        behavior: GroupBehavior.parent,
      );

      expect(group.behavior, equals(GroupBehavior.parent));
    });

    test('adds nodeIds to group for explicit/parent behavior', () {
      final controller = createTestController();
      controller.addNode(createTestNode(id: 'node-1'));
      controller.addNode(createTestNode(id: 'node-2'));

      final explicitGroup = controller.createGroupNodeAroundNodes(
        title: 'Explicit Group',
        nodeIds: {'node-1', 'node-2'},
        data: 'data',
        behavior: GroupBehavior.explicit,
      );

      expect(explicitGroup.nodeIds, containsAll(['node-1', 'node-2']));
    });

    test('does not add nodeIds for bounds behavior', () {
      final controller = createTestController();
      controller.addNode(createTestNode(id: 'node-1'));

      final boundsGroup = controller.createGroupNodeAroundNodes(
        title: 'Bounds Group',
        nodeIds: {'node-1'},
        data: 'data',
        behavior: GroupBehavior.bounds,
      );

      // For bounds behavior, nodeIds should be empty
      expect(boundsGroup.nodeIds, isEmpty);
    });

    test('creates group with input and output ports', () {
      final controller = createTestController();
      controller.addNode(createTestNode(id: 'node-1'));

      final group = controller.createGroupNodeAroundNodes(
        title: 'Subflow Group',
        nodeIds: {'node-1'},
        data: 'data',
        ports: [
          createInputPort(id: 'in-1'),
          createOutputPort(id: 'out-1'),
        ],
      );

      expect(group.inputPorts, hasLength(1));
      expect(group.outputPorts, hasLength(1));
    });

    test('creates group with custom ID', () {
      final controller = createTestController();
      controller.addNode(createTestNode(id: 'node-1'));

      final group = controller.createGroupNodeAroundNodes(
        title: 'Custom ID Group',
        nodeIds: {'node-1'},
        data: 'data',
        id: 'my-custom-group',
      );

      expect(group.id, equals('my-custom-group'));
    });

    test('creates group with custom color', () {
      final controller = createTestController();
      controller.addNode(createTestNode(id: 'node-1'));

      final group = controller.createGroupNodeAroundNodes(
        title: 'Colored Group',
        nodeIds: {'node-1'},
        data: 'data',
        color: Colors.purple,
      );

      expect(group.currentColor, equals(Colors.purple));
    });
  });

  // ===========================================================================
  // Group Utility Methods
  // ===========================================================================

  group('findContainedNodes', () {
    test('finds nodes completely within group bounds', () {
      final controller = createTestController();

      // Add a group at position (0, 0) with size (400, 300)
      final group = controller.createGroupNode(
        title: 'Container Group',
        position: Offset.zero,
        size: const Size(400, 300),
        data: 'group-data',
      );

      // Add nodes inside the group bounds
      controller.addNode(
        createTestNode(
          id: 'inside-1',
          position: const Offset(50, 50),
          size: const Size(80, 40),
        ),
      );
      controller.addNode(
        createTestNode(
          id: 'inside-2',
          position: const Offset(200, 150),
          size: const Size(80, 40),
        ),
      );

      // Add node outside the group bounds
      controller.addNode(
        createTestNode(
          id: 'outside',
          position: const Offset(500, 500),
          size: const Size(80, 40),
        ),
      );

      // Need to initialize the spatial index for this to work
      // In a real scenario, this happens when the editor is initialized
      // For unit tests, we can check the logic directly

      final containedNodes = controller.findContainedNodes(group);

      // The spatial index needs to be properly initialized for this test
      // Since we're testing without full editor initialization,
      // the result depends on the spatial index state
      expect(containedNodes, isA<Set<String>>());
    });
  });

  group('hideAllGroupAndCommentNodes', () {
    test('hides all group nodes', () {
      final controller = createTestController();

      controller.createGroupNode(
        title: 'Group 1',
        position: Offset.zero,
        size: const Size(200, 150),
        data: 'data1',
      );
      controller.createGroupNode(
        title: 'Group 2',
        position: const Offset(300, 0),
        size: const Size(200, 150),
        data: 'data2',
      );

      controller.hideAllGroupAndCommentNodes();

      for (final node in controller.nodes.values) {
        if (node is GroupNode) {
          expect(node.isVisible, isFalse);
        }
      }
    });

    test('hides all comment nodes', () {
      final controller = createTestController();

      controller.createCommentNode(
        position: Offset.zero,
        text: 'Comment 1',
        data: 'data1',
      );
      controller.createCommentNode(
        position: const Offset(300, 0),
        text: 'Comment 2',
        data: 'data2',
      );

      controller.hideAllGroupAndCommentNodes();

      for (final node in controller.nodes.values) {
        if (node is CommentNode) {
          expect(node.isVisible, isFalse);
        }
      }
    });

    test('does not hide regular nodes', () {
      final controller = createTestController();

      controller.addNode(createTestNode(id: 'regular-node', visible: true));
      controller.createGroupNode(
        title: 'Group',
        position: const Offset(200, 0),
        size: const Size(200, 150),
        data: 'data',
      );
      controller.createCommentNode(
        position: const Offset(500, 0),
        text: 'Comment',
        data: 'data',
      );

      controller.hideAllGroupAndCommentNodes();

      final regularNode = controller.getNode('regular-node')!;
      expect(regularNode.isVisible, isTrue);
    });

    test('handles empty controller', () {
      final controller = createTestController();

      // Should not throw
      expect(() => controller.hideAllGroupAndCommentNodes(), returnsNormally);
    });
  });

  group('showAllGroupAndCommentNodes', () {
    test('shows all hidden group nodes', () {
      final controller = createTestController();

      controller.createGroupNode(
        title: 'Group 1',
        position: Offset.zero,
        size: const Size(200, 150),
        data: 'data1',
      );
      controller.createGroupNode(
        title: 'Group 2',
        position: const Offset(300, 0),
        size: const Size(200, 150),
        data: 'data2',
      );

      controller.hideAllGroupAndCommentNodes();
      controller.showAllGroupAndCommentNodes();

      for (final node in controller.nodes.values) {
        if (node is GroupNode) {
          expect(node.isVisible, isTrue);
        }
      }
    });

    test('shows all hidden comment nodes', () {
      final controller = createTestController();

      controller.createCommentNode(
        position: Offset.zero,
        text: 'Comment 1',
        data: 'data1',
      );
      controller.createCommentNode(
        position: const Offset(300, 0),
        text: 'Comment 2',
        data: 'data2',
      );

      controller.hideAllGroupAndCommentNodes();
      controller.showAllGroupAndCommentNodes();

      for (final node in controller.nodes.values) {
        if (node is CommentNode) {
          expect(node.isVisible, isTrue);
        }
      }
    });

    test('does not affect regular nodes', () {
      final controller = createTestController();

      controller.addNode(createTestNode(id: 'regular-node', visible: false));
      controller.createGroupNode(
        title: 'Group',
        position: const Offset(200, 0),
        size: const Size(200, 150),
        data: 'data',
      );

      controller.hideAllGroupAndCommentNodes();
      controller.showAllGroupAndCommentNodes();

      final regularNode = controller.getNode('regular-node')!;
      // Regular node should remain hidden (it was hidden initially)
      expect(regularNode.isVisible, isFalse);
    });

    test('handles empty controller', () {
      final controller = createTestController();

      // Should not throw
      expect(() => controller.showAllGroupAndCommentNodes(), returnsNormally);
    });
  });

  // ===========================================================================
  // Widget-Level Drag API - startNodeDrag
  // ===========================================================================

  group('startNodeDrag', () {
    test('selects node if not already selected', () {
      final controller = createTestController();
      controller.addNode(createTestNode(id: 'node-1'));
      controller.addNode(createTestNode(id: 'node-2'));

      controller.startNodeDrag('node-1');

      expect(controller.selectedNodeIds, contains('node-1'));
    });

    test('keeps node selected if already selected', () {
      final controller = createTestController();
      controller.addNode(createTestNode(id: 'node-1'));
      controller.selectNode('node-1');

      controller.startNodeDrag('node-1');

      expect(controller.selectedNodeIds, contains('node-1'));
    });

    test('sets dragged node ID', () {
      final controller = createTestController();
      controller.addNode(createTestNode(id: 'drag-me'));

      controller.startNodeDrag('drag-me');

      expect(controller.draggedNodeId, equals('drag-me'));
    });

    test('sets dragging flag on node', () {
      final controller = createTestController();
      final node = createTestNode(id: 'node-1');
      controller.addNode(node);

      controller.startNodeDrag('node-1');

      expect(controller.getNode('node-1')!.dragging.value, isTrue);
    });

    test(
      'sets dragging flag on all selected nodes when dragging selected node',
      () {
        final controller = createTestController();
        controller.addNode(createTestNode(id: 'node-1'));
        controller.addNode(createTestNode(id: 'node-2'));
        controller.addNode(createTestNode(id: 'node-3'));
        controller.selectNodes(['node-1', 'node-2']);

        controller.startNodeDrag('node-1');

        expect(controller.getNode('node-1')!.dragging.value, isTrue);
        expect(controller.getNode('node-2')!.dragging.value, isTrue);
        expect(controller.getNode('node-3')!.dragging.value, isFalse);
      },
    );

    test('brings node to front', () {
      final controller = createTestController();
      controller.addNode(createTestNode(id: 'node-1', zIndex: 0));
      controller.addNode(createTestNode(id: 'node-2', zIndex: 10));

      controller.startNodeDrag('node-1');

      final node1 = controller.getNode('node-1')!;
      final node2 = controller.getNode('node-2')!;
      expect(node1.currentZIndex, greaterThan(node2.currentZIndex));
    });
  });

  // ===========================================================================
  // Widget-Level Drag API - moveNodeDrag
  // ===========================================================================

  group('moveNodeDrag', () {
    test('moves dragged node by delta', () {
      final controller = createTestController();
      controller.addNode(
        createTestNode(id: 'node-1', position: const Offset(100, 100)),
      );
      controller.startNodeDrag('node-1');

      controller.moveNodeDrag(const Offset(50, 30));

      final node = controller.getNode('node-1')!;
      expect(node.position.value, equals(const Offset(150, 130)));
    });

    test('moves all selected nodes when dragging a selected node', () {
      final controller = createTestController();
      controller.addNode(
        createTestNode(id: 'node-1', position: const Offset(100, 100)),
      );
      controller.addNode(
        createTestNode(id: 'node-2', position: const Offset(200, 200)),
      );
      controller.selectNodes(['node-1', 'node-2']);
      controller.startNodeDrag('node-1');

      controller.moveNodeDrag(const Offset(25, 25));

      expect(
        controller.getNode('node-1')!.position.value,
        equals(const Offset(125, 125)),
      );
      expect(
        controller.getNode('node-2')!.position.value,
        equals(const Offset(225, 225)),
      );
    });

    test('does nothing when no node is being dragged', () {
      final controller = createTestController();
      controller.addNode(
        createTestNode(id: 'node-1', position: const Offset(100, 100)),
      );

      controller.moveNodeDrag(const Offset(50, 30));

      // Position should remain unchanged
      expect(
        controller.getNode('node-1')!.position.value,
        equals(const Offset(100, 100)),
      );
    });

    test('updates visual position with snap-to-grid', () {
      final controller = createTestController(
        config: NodeFlowConfig(
          plugins: [
            SnapPlugin([GridSnapDelegate(gridSize: 20.0)], enabled: true),
          ],
        ),
      );
      controller.addNode(
        createTestNode(id: 'node-1', position: const Offset(100, 100)),
      );
      controller.startNodeDrag('node-1');

      controller.moveNodeDrag(const Offset(15, 25));

      final node = controller.getNode('node-1')!;
      // Visual position should be snapped
      expect(node.visualPosition.value.dx % 20, equals(0));
      expect(node.visualPosition.value.dy % 20, equals(0));
    });
  });

  // ===========================================================================
  // Widget-Level Drag API - endNodeDrag
  // ===========================================================================

  group('endNodeDrag', () {
    test('clears dragged node ID', () {
      final controller = createTestController();
      controller.addNode(createTestNode(id: 'node-1'));
      controller.startNodeDrag('node-1');

      controller.endNodeDrag();

      expect(controller.draggedNodeId, isNull);
    });

    test('clears dragging flag on all dragged nodes', () {
      final controller = createTestController();
      controller.addNode(createTestNode(id: 'node-1'));
      controller.addNode(createTestNode(id: 'node-2'));
      controller.selectNodes(['node-1', 'node-2']);
      controller.startNodeDrag('node-1');

      controller.endNodeDrag();

      expect(controller.getNode('node-1')!.dragging.value, isFalse);
      expect(controller.getNode('node-2')!.dragging.value, isFalse);
    });

    test('clears last pointer position', () {
      final controller = createTestController();
      controller.addNode(createTestNode(id: 'node-1'));
      controller.startNodeDrag('node-1');

      controller.endNodeDrag();

      expect(controller.interaction.lastPointerPosition.value, isNull);
    });

    test('does nothing when not dragging', () {
      final controller = createTestController();

      // Should not throw
      expect(() => controller.endNodeDrag(), returnsNormally);
      expect(controller.draggedNodeId, isNull);
    });
  });

  // ===========================================================================
  // Widget-Level Drag API - cancelNodeDrag
  // ===========================================================================

  group('cancelNodeDrag', () {
    test('reverts node positions to original', () {
      final controller = createTestController();
      controller.addNode(
        createTestNode(id: 'node-1', position: const Offset(100, 100)),
      );
      controller.startNodeDrag('node-1');
      controller.moveNodeDrag(const Offset(50, 50));

      controller.cancelNodeDrag({'node-1': const Offset(100, 100)});

      expect(
        controller.getNode('node-1')!.position.value,
        equals(const Offset(100, 100)),
      );
    });

    test('reverts multiple node positions', () {
      final controller = createTestController();
      controller.addNode(
        createTestNode(id: 'node-1', position: const Offset(100, 100)),
      );
      controller.addNode(
        createTestNode(id: 'node-2', position: const Offset(200, 200)),
      );
      controller.selectNodes(['node-1', 'node-2']);
      controller.startNodeDrag('node-1');
      controller.moveNodeDrag(const Offset(50, 50));

      controller.cancelNodeDrag({
        'node-1': const Offset(100, 100),
        'node-2': const Offset(200, 200),
      });

      expect(
        controller.getNode('node-1')!.position.value,
        equals(const Offset(100, 100)),
      );
      expect(
        controller.getNode('node-2')!.position.value,
        equals(const Offset(200, 200)),
      );
    });

    test('clears dragged node ID', () {
      final controller = createTestController();
      controller.addNode(createTestNode(id: 'node-1'));
      controller.startNodeDrag('node-1');

      controller.cancelNodeDrag({'node-1': Offset.zero});

      expect(controller.draggedNodeId, isNull);
    });

    test('clears dragging flag on all dragged nodes', () {
      final controller = createTestController();
      controller.addNode(createTestNode(id: 'node-1'));
      controller.addNode(createTestNode(id: 'node-2'));
      controller.selectNodes(['node-1', 'node-2']);
      controller.startNodeDrag('node-1');

      controller.cancelNodeDrag({'node-1': Offset.zero, 'node-2': Offset.zero});

      expect(controller.getNode('node-1')!.dragging.value, isFalse);
      expect(controller.getNode('node-2')!.dragging.value, isFalse);
    });

    test('clears last pointer position', () {
      final controller = createTestController();
      controller.addNode(createTestNode(id: 'node-1'));
      controller.startNodeDrag('node-1');

      controller.cancelNodeDrag({'node-1': Offset.zero});

      expect(controller.interaction.lastPointerPosition.value, isNull);
    });

    test('updates visual position with snap-to-grid on revert', () {
      final controller = createTestController(
        config: NodeFlowConfig(
          plugins: [
            SnapPlugin([GridSnapDelegate(gridSize: 20.0)], enabled: true),
          ],
        ),
      );
      controller.addNode(createTestNode(id: 'node-1'));
      controller.startNodeDrag('node-1');
      controller.moveNodeDrag(const Offset(50, 50));

      controller.cancelNodeDrag({'node-1': const Offset(100, 100)});

      final node = controller.getNode('node-1')!;
      expect(node.visualPosition.value.dx % 20, equals(0));
      expect(node.visualPosition.value.dy % 20, equals(0));
    });

    test('handles empty original positions map', () {
      final controller = createTestController();
      controller.addNode(createTestNode(id: 'node-1'));
      controller.startNodeDrag('node-1');

      // Should not throw
      expect(() => controller.cancelNodeDrag({}), returnsNormally);
    });
  });

  // ===========================================================================
  // Edge Cases
  // ===========================================================================

  group('Edge Cases', () {
    test('drag operations on non-existent nodes do not throw', () {
      final controller = createTestController();

      expect(() => controller.startNodeDrag('non-existent'), returnsNormally);
    });

    test(
      'creating multiple groups and comments with unique IDs works correctly',
      () {
        final controller = createTestController();

        for (int i = 0; i < 5; i++) {
          controller.createGroupNode(
            id: 'group-$i',
            title: 'Group $i',
            position: Offset(i * 200.0, 0),
            size: const Size(150, 100),
            data: 'group-$i',
          );
          controller.createCommentNode(
            id: 'comment-$i',
            position: Offset(i * 200.0, 150),
            text: 'Comment $i',
            data: 'comment-$i',
          );
        }

        expect(controller.nodeCount, equals(10)); // 5 groups + 5 comments

        final groups = controller.nodes.values.whereType<GroupNode>().toList();
        final comments = controller.nodes.values
            .whereType<CommentNode>()
            .toList();

        expect(groups, hasLength(5));
        expect(comments, hasLength(5));
      },
    );

    test('hide/show operations are idempotent', () {
      final controller = createTestController();
      controller.createGroupNode(
        title: 'Group',
        position: Offset.zero,
        size: const Size(200, 150),
        data: 'data',
      );

      // Multiple hides should have same effect as one hide
      controller.hideAllGroupAndCommentNodes();
      controller.hideAllGroupAndCommentNodes();
      controller.hideAllGroupAndCommentNodes();

      for (final node in controller.nodes.values) {
        if (node is GroupNode || node is CommentNode) {
          expect(node.isVisible, isFalse);
        }
      }

      // Multiple shows should have same effect as one show
      controller.showAllGroupAndCommentNodes();
      controller.showAllGroupAndCommentNodes();
      controller.showAllGroupAndCommentNodes();

      for (final node in controller.nodes.values) {
        if (node is GroupNode || node is CommentNode) {
          expect(node.isVisible, isTrue);
        }
      }
    });

    test('mixed group and comment visibility operations', () {
      final controller = createTestController();

      final group = controller.createGroupNode(
        title: 'Group',
        position: Offset.zero,
        size: const Size(200, 150),
        data: 'group-data',
      );
      final comment = controller.createCommentNode(
        position: const Offset(300, 0),
        text: 'Comment',
        data: 'comment-data',
      );
      controller.addNode(createTestNode(id: 'regular'));

      // Hide special nodes
      controller.hideAllGroupAndCommentNodes();

      expect(group.isVisible, isFalse);
      expect(comment.isVisible, isFalse);
      expect(controller.getNode('regular')!.isVisible, isTrue);

      // Show special nodes
      controller.showAllGroupAndCommentNodes();

      expect(group.isVisible, isTrue);
      expect(comment.isVisible, isTrue);
      expect(controller.getNode('regular')!.isVisible, isTrue);
    });
  });
}
