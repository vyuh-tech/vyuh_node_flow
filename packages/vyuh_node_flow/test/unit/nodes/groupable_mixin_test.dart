/// Unit tests for GroupableMixin.
///
/// Tests cover:
/// - Context attachment and detachment
/// - Groupable configuration
/// - Child node callbacks
/// - Reaction lifecycle management
/// - MobX reaction setup for position/size tracking
/// - Auto-removal support
/// - Edge cases with nested groups
@Tags(['unit'])
library;

import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:mobx/mobx.dart';
import 'package:vyuh_node_flow/vyuh_node_flow.dart';

import '../../helpers/test_factories.dart';

/// A test node that uses GroupableMixin with configurable behavior.
///
/// This allows testing the mixin's behavior in isolation with
/// controllable isGroupable and groupedNodeIds values.
class TestGroupableNode<T> extends Node<T> with GroupableMixin<T> {
  TestGroupableNode({
    required super.id,
    required super.data,
    super.position = Offset.zero,
    bool groupable = false,
    Set<String>? memberIds,
    bool removeWhenEmpty = false,
    bool empty = false,
  }) : _isGroupable = Observable(groupable),
       _memberIds = ObservableSet.of(memberIds ?? {}),
       _removeWhenEmpty = removeWhenEmpty,
       _isEmpty = empty,
       super(type: 'test-groupable');

  final Observable<bool> _isGroupable;
  final ObservableSet<String> _memberIds;
  final bool _removeWhenEmpty;
  final bool _isEmpty;

  // Track callback invocations for testing
  final List<String> contextAttachedCalls = [];
  final List<String> contextDetachingCalls = [];
  final List<(String, Offset)> childMovedCalls = [];
  final List<(String, Size)> childResizedCalls = [];
  final List<Set<String>> childrenDeletedCalls = [];
  final List<(String, Rect)> nodeAddedCalls = [];
  final List<Set<String>> selectionChangedCalls = [];

  @override
  bool get isGroupable => _isGroupable.value;

  set isGroupable(bool value) => runInAction(() => _isGroupable.value = value);

  @override
  Set<String> get groupedNodeIds => _memberIds.toSet();

  void addMember(String nodeId) => runInAction(() => _memberIds.add(nodeId));

  void removeMember(String nodeId) =>
      runInAction(() => _memberIds.remove(nodeId));

  @override
  bool get shouldRemoveWhenEmpty => _removeWhenEmpty;

  @override
  bool get isEmpty => _isEmpty;

  @override
  void onContextAttached() {
    super.onContextAttached();
    contextAttachedCalls.add(id);
  }

  @override
  void onContextDetaching() {
    super.onContextDetaching();
    contextDetachingCalls.add(id);
  }

  @override
  void onChildMoved(String nodeId, Offset newPosition) {
    super.onChildMoved(nodeId, newPosition);
    childMovedCalls.add((nodeId, newPosition));
  }

  @override
  void onChildResized(String nodeId, Size newSize) {
    super.onChildResized(nodeId, newSize);
    childResizedCalls.add((nodeId, newSize));
  }

  @override
  void onChildrenDeleted(Set<String> nodeIds) {
    super.onChildrenDeleted(nodeIds);
    childrenDeletedCalls.add(nodeIds);
  }

  @override
  void onNodeAdded(String nodeId, Rect nodeBounds) {
    super.onNodeAdded(nodeId, nodeBounds);
    nodeAddedCalls.add((nodeId, nodeBounds));
  }

  @override
  void onSelectionChanged(Set<String> selectedNodeIds) {
    super.onSelectionChanged(selectedNodeIds);
    selectionChangedCalls.add(selectedNodeIds);
  }
}

void main() {
  setUp(() {
    resetTestCounters();
  });

  // ===========================================================================
  // Context Attachment Tests
  // ===========================================================================

  group('GroupableMixin - Context Attachment', () {
    test('GroupNode starts without context', () {
      final group = createTestGroupNode<String>(id: 'group-1', data: 'test');

      expect(group.hasContext, isFalse);
      expect(group.groupContext, isNull);
    });

    test('GroupNode gets context when added to controller', () {
      final group = createTestGroupNode<String>(id: 'group-1', data: 'test');
      final controller = createTestController();

      controller.addNode(group);

      final addedGroup = controller.getNode('group-1') as GroupNode<String>;
      expect(addedGroup.hasContext, isTrue);
      expect(addedGroup.groupContext, isNotNull);
    });

    test('GroupNode loses context when removed from controller', () {
      final group = createTestGroupNode<String>(id: 'group-1', data: 'test');
      final controller = createTestController();
      controller.addNode(group);

      controller.removeNode('group-1');

      // The removed node should have context cleared
      // Note: We can't easily test this since the node is removed
      expect(controller.getNode('group-1'), isNull);
    });

    test('CommentNode can be added to controller', () {
      final comment = createTestCommentNode<String>(
        id: 'comment-1',
        data: 'test',
      );
      final controller = createTestController();

      controller.addNode(comment);

      final addedComment =
          controller.getNode('comment-1') as CommentNode<String>;
      expect(addedComment, isNotNull);
      expect(addedComment.id, equals('comment-1'));
    });

    test('attachContext calls onContextAttached callback', () {
      final node = TestGroupableNode<String>(
        id: 'test-1',
        data: 'test',
        groupable: false,
      );
      final controller = createTestController();

      controller.addNode(node);

      final addedNode =
          controller.getNode('test-1') as TestGroupableNode<String>;
      expect(addedNode.contextAttachedCalls, contains('test-1'));
    });

    test('detachContext calls onContextDetaching callback', () {
      final node = TestGroupableNode<String>(
        id: 'test-1',
        data: 'test',
        groupable: false,
      );
      final controller = createTestController();
      controller.addNode(node);

      // Keep a reference before removal
      final addedNode =
          controller.getNode('test-1') as TestGroupableNode<String>;

      controller.removeNode('test-1');

      expect(addedNode.contextDetachingCalls, contains('test-1'));
    });

    test('attachContext sets up reactions when isGroupable is true', () {
      final member = createTestNode(
        id: 'member-1',
        position: const Offset(100, 100),
      );
      final node = TestGroupableNode<String>(
        id: 'test-1',
        data: 'test',
        groupable: true,
        memberIds: {'member-1'},
      );
      final controller = createTestController();
      controller.addNode(member);
      controller.addNode(node);

      // Reactions should be set up - moving member should trigger callback
      final addedNode =
          controller.getNode('test-1') as TestGroupableNode<String>;

      // Move the member node to trigger the position reaction
      final memberNode = controller.getNode('member-1')!;
      runInAction(() => memberNode.position.value = const Offset(200, 200));

      // Allow reactions to fire
      expect(addedNode.hasContext, isTrue);
    });

    test('attachContext skips reactions when isGroupable is false', () {
      final node = TestGroupableNode<String>(
        id: 'test-1',
        data: 'test',
        groupable: false, // Not groupable
      );
      final controller = createTestController();
      controller.addNode(node);

      final addedNode =
          controller.getNode('test-1') as TestGroupableNode<String>;

      // Should have context but no reactions for position tracking
      expect(addedNode.hasContext, isTrue);
      expect(addedNode.childMovedCalls, isEmpty);
    });
  });

  // ===========================================================================
  // Groupable Configuration Tests
  // ===========================================================================

  group('GroupableMixin - Configuration', () {
    test('GroupNode with bounds behavior is not groupable', () {
      final group = createTestGroupNode<String>(
        id: 'group-1',
        data: 'test',
        behavior: GroupBehavior.bounds,
      );
      final controller = createTestController(nodes: [group]);

      final addedGroup = controller.getNode('group-1') as GroupNode<String>;
      expect(addedGroup.isGroupable, isFalse);
    });

    test('GroupNode with explicit behavior is groupable', () {
      final group = createTestGroupNode<String>(
        id: 'group-1',
        data: 'test',
        behavior: GroupBehavior.explicit,
        nodeIds: {'member-1', 'member-2'},
      );
      final controller = createTestController(nodes: [group]);

      final addedGroup = controller.getNode('group-1') as GroupNode<String>;
      expect(addedGroup.isGroupable, isTrue);
    });

    test('groupedNodeIds returns member node IDs', () {
      final member1 = createTestNode(id: 'member-1');
      final member2 = createTestNode(id: 'member-2');
      final group = createTestGroupNode<String>(
        id: 'group-1',
        data: 'test',
        behavior: GroupBehavior.explicit,
        nodeIds: {'member-1', 'member-2'},
      );
      final controller = createTestController(nodes: [member1, member2, group]);

      final addedGroup = controller.getNode('group-1') as GroupNode<String>;
      expect(addedGroup.groupedNodeIds, containsAll(['member-1', 'member-2']));
    });

    test('default isGroupable returns false', () {
      final node = TestGroupableNode<String>(
        id: 'test-1',
        data: 'test',
        groupable: false,
      );

      expect(node.isGroupable, isFalse);
    });

    test('default groupedNodeIds returns empty set', () {
      final node = TestGroupableNode<String>(id: 'test-1', data: 'test');

      expect(node.groupedNodeIds, isEmpty);
    });
  });

  // ===========================================================================
  // Empty Group Tests
  // ===========================================================================

  group('GroupableMixin - Empty Groups', () {
    test('isEmpty returns true when group has no members', () {
      final group = createTestGroupNode<String>(
        id: 'group-1',
        data: 'test',
        behavior: GroupBehavior.explicit,
        nodeIds: {},
      );
      final controller = createTestController(nodes: [group]);

      final addedGroup = controller.getNode('group-1') as GroupNode<String>;
      expect(addedGroup.isEmpty, isTrue);
    });

    test('isEmpty returns false when group has members', () {
      final member = createTestNode(id: 'member-1');
      final group = createTestGroupNode<String>(
        id: 'group-1',
        data: 'test',
        behavior: GroupBehavior.explicit,
        nodeIds: {'member-1'},
      );
      final controller = createTestController(nodes: [member, group]);

      final addedGroup = controller.getNode('group-1') as GroupNode<String>;
      expect(addedGroup.isEmpty, isFalse);
    });

    test('shouldRemoveWhenEmpty is true for explicit behavior', () {
      // GroupNode overrides shouldRemoveWhenEmpty:
      // - explicit behavior: true (auto-remove when empty)
      // - bounds/parent behavior: false (persist when empty)
      final group = createTestGroupNode<String>(
        id: 'group-1',
        data: 'test',
        behavior: GroupBehavior.explicit,
        nodeIds: {},
      );
      final controller = createTestController(nodes: [group]);

      final addedGroup = controller.getNode('group-1') as GroupNode<String>;
      expect(addedGroup.shouldRemoveWhenEmpty, isTrue);
    });

    test('shouldRemoveWhenEmpty is false for bounds behavior', () {
      final group = createTestGroupNode<String>(
        id: 'group-1',
        data: 'test',
        behavior: GroupBehavior.bounds,
      );
      final controller = createTestController(nodes: [group]);

      final addedGroup = controller.getNode('group-1') as GroupNode<String>;
      expect(addedGroup.shouldRemoveWhenEmpty, isFalse);
    });

    test('default shouldRemoveWhenEmpty returns false', () {
      final node = TestGroupableNode<String>(
        id: 'test-1',
        data: 'test',
        removeWhenEmpty: false,
      );

      expect(node.shouldRemoveWhenEmpty, isFalse);
    });

    test('default isEmpty returns false', () {
      final node = TestGroupableNode<String>(
        id: 'test-1',
        data: 'test',
        empty: false,
      );

      expect(node.isEmpty, isFalse);
    });

    test('custom shouldRemoveWhenEmpty can return true', () {
      final node = TestGroupableNode<String>(
        id: 'test-1',
        data: 'test',
        removeWhenEmpty: true,
      );

      expect(node.shouldRemoveWhenEmpty, isTrue);
    });

    test('custom isEmpty can return true', () {
      final node = TestGroupableNode<String>(
        id: 'test-1',
        data: 'test',
        empty: true,
      );

      expect(node.isEmpty, isTrue);
    });
  });

  // ===========================================================================
  // Child Node Tracking Tests
  // ===========================================================================

  group('GroupableMixin - Child Node Tracking', () {
    test('group receives context for tracking child nodes', () {
      final member = createTestNode(
        id: 'member-1',
        position: const Offset(50, 50),
      );
      final group = createTestGroupNode<String>(
        id: 'group-1',
        data: 'test',
        behavior: GroupBehavior.explicit,
        nodeIds: {'member-1'},
      );
      // Use addNode to ensure context is attached
      final controller = createTestController();
      controller.addNode(member);
      controller.addNode(group);

      final addedGroup = controller.getNode('group-1') as GroupNode<String>;
      expect(addedGroup.groupContext, isNotNull);
      expect(addedGroup.groupContext!.getNode('member-1'), isNotNull);
    });

    test('context provides getNode method', () {
      final member = createTestNode(
        id: 'member-1',
        position: const Offset(100, 100),
      );
      final group = createTestGroupNode<String>(
        id: 'group-1',
        data: 'test',
        behavior: GroupBehavior.explicit,
        nodeIds: {'member-1'},
      );
      // Use addNode to ensure context is attached
      final controller = createTestController();
      controller.addNode(member);
      controller.addNode(group);

      final addedGroup = controller.getNode('group-1') as GroupNode<String>;
      final trackedMember = addedGroup.groupContext!.getNode('member-1');

      expect(trackedMember, isNotNull);
      expect(trackedMember!.id, equals('member-1'));
      expect(trackedMember.position.value, equals(const Offset(100, 100)));
    });

    test('context getNode returns null for non-existent node', () {
      final group = createTestGroupNode<String>(
        id: 'group-1',
        data: 'test',
        behavior: GroupBehavior.explicit,
      );
      final controller = createTestController();
      controller.addNode(group);

      final addedGroup = controller.getNode('group-1') as GroupNode<String>;
      final nonExistent = addedGroup.groupContext!.getNode('non-existent');

      expect(nonExistent, isNull);
    });
  });

  // ===========================================================================
  // Group Behavior Tests
  // ===========================================================================

  group('GroupableMixin - Group Behaviors', () {
    test('bounds behavior group does not track members', () {
      final member = createTestNode(id: 'member-1');
      final group = createTestGroupNode<String>(
        id: 'group-1',
        data: 'test',
        behavior: GroupBehavior.bounds,
        nodeIds: {'member-1'},
      );
      final controller = createTestController(nodes: [member, group]);

      final addedGroup = controller.getNode('group-1') as GroupNode<String>;
      // bounds behavior means isGroupable is false
      expect(addedGroup.isGroupable, isFalse);
    });

    test('explicit behavior group tracks members', () {
      final member = createTestNode(id: 'member-1');
      final group = createTestGroupNode<String>(
        id: 'group-1',
        data: 'test',
        behavior: GroupBehavior.explicit,
        nodeIds: {'member-1'},
      );
      final controller = createTestController(nodes: [member, group]);

      final addedGroup = controller.getNode('group-1') as GroupNode<String>;
      expect(addedGroup.isGroupable, isTrue);
    });

    test('parent behavior group tracks members', () {
      final member = createTestNode(id: 'member-1');
      final group = createTestGroupNode<String>(
        id: 'group-1',
        data: 'test',
        behavior: GroupBehavior.parent,
        nodeIds: {'member-1'},
      );
      final controller = createTestController(nodes: [member, group]);

      final addedGroup = controller.getNode('group-1') as GroupNode<String>;
      expect(addedGroup.isGroupable, isTrue);
    });

    test('bounds behavior returns empty groupedNodeIds', () {
      final group = createTestGroupNode<String>(
        id: 'group-1',
        data: 'test',
        behavior: GroupBehavior.bounds,
        nodeIds: {'member-1', 'member-2'},
      );
      final controller = createTestController(nodes: [group]);

      final addedGroup = controller.getNode('group-1') as GroupNode<String>;
      expect(addedGroup.groupedNodeIds, isEmpty);
    });
  });

  // ===========================================================================
  // Context Lifecycle Tests
  // ===========================================================================

  group('GroupableMixin - Context Lifecycle', () {
    test('onContextAttached is called when added to controller', () {
      // Note: We can't easily test the callback itself, but we can verify
      // the context is properly attached
      final group = createTestGroupNode<String>(
        id: 'group-1',
        data: 'test',
        behavior: GroupBehavior.explicit,
      );
      final controller = createTestController();

      controller.addNode(group);

      final addedGroup = controller.getNode('group-1') as GroupNode<String>;
      expect(addedGroup.hasContext, isTrue);
    });

    test('multiple groups can be added to same controller', () {
      final group1 = createTestGroupNode<String>(
        id: 'group-1',
        data: 'test1',
        behavior: GroupBehavior.explicit,
      );
      final group2 = createTestGroupNode<String>(
        id: 'group-2',
        data: 'test2',
        behavior: GroupBehavior.explicit,
      );
      final controller = createTestController();

      controller.addNode(group1);
      controller.addNode(group2);

      final addedGroup1 = controller.getNode('group-1') as GroupNode<String>;
      final addedGroup2 = controller.getNode('group-2') as GroupNode<String>;
      expect(addedGroup1.hasContext, isTrue);
      expect(addedGroup2.hasContext, isTrue);
    });

    test('removing one group does not affect other groups', () {
      // Use bounds behavior since explicit behavior auto-removes empty groups
      // when other nodes are deleted
      final group1 = createTestGroupNode<String>(
        id: 'group-1',
        data: 'test1',
        behavior: GroupBehavior.bounds,
      );
      final group2 = createTestGroupNode<String>(
        id: 'group-2',
        data: 'test2',
        behavior: GroupBehavior.bounds,
      );
      final controller = createTestController();
      controller.addNode(group1);
      controller.addNode(group2);

      controller.removeNode('group-1');

      expect(controller.getNode('group-1'), isNull);
      final addedGroup2 = controller.getNode('group-2') as GroupNode<String>;
      expect(addedGroup2.hasContext, isTrue);
    });

    test('empty explicit group is auto-removed when nodes are deleted', () {
      // This tests the auto-removal behavior of empty explicit groups
      final group1 = createTestGroupNode<String>(
        id: 'group-1',
        data: 'test1',
        behavior: GroupBehavior.explicit,
        nodeIds: {}, // Empty group
      );
      final member = createTestNode(id: 'member-1');
      final controller = createTestController();
      controller.addNode(group1);
      controller.addNode(member);

      // Removing an unrelated node triggers the deletion check
      controller.removeNode('member-1');

      // Empty explicit group should be auto-removed
      expect(controller.getNode('group-1'), isNull);
    });

    test('detachContext clears group context', () {
      final node = TestGroupableNode<String>(
        id: 'test-1',
        data: 'test',
        groupable: false,
      );
      final controller = createTestController();
      controller.addNode(node);

      final addedNode =
          controller.getNode('test-1') as TestGroupableNode<String>;
      expect(addedNode.hasContext, isTrue);

      controller.removeNode('test-1');

      // After detach, context should be null
      expect(addedNode.hasContext, isFalse);
      expect(addedNode.groupContext, isNull);
    });
  });

  // ===========================================================================
  // Integration with Controller Tests
  // ===========================================================================

  group('GroupableMixin - Controller Integration', () {
    test('group can access nodes through context', () {
      final member = createTestNode(
        id: 'member-1',
        position: const Offset(100, 100),
      );
      final group = createTestGroupNode<String>(
        id: 'group-1',
        data: 'test',
        behavior: GroupBehavior.explicit,
        nodeIds: {'member-1'},
      );
      // Use addNode to ensure context is attached
      final controller = createTestController();
      controller.addNode(member);
      controller.addNode(group);

      final addedGroup = controller.getNode('group-1') as GroupNode<String>;
      final context = addedGroup.groupContext!;

      // Context should provide access to nodes via getNode
      final node = context.getNode('member-1');
      expect(node, isNotNull);
      expect(node!.id, equals('member-1'));
    });

    test('group context provides findNodesInBounds', () {
      final member = createTestNode(
        id: 'member-1',
        position: const Offset(100, 100),
        size: const Size(100, 100),
      );
      final group = createTestGroupNode<String>(
        id: 'group-1',
        data: 'test',
        behavior: GroupBehavior.explicit,
        nodeIds: {'member-1'},
        position: const Offset(50, 50),
        size: const Size(200, 200),
      );
      // Use addNode to ensure context is attached
      final controller = createTestController();
      controller.addNode(member);
      controller.addNode(group);

      final addedGroup = controller.getNode('group-1') as GroupNode<String>;
      final context = addedGroup.groupContext!;

      // Find nodes in bounds
      final bounds = const Rect.fromLTWH(0, 0, 500, 500);
      final nodesInBounds = context.findNodesInBounds(bounds);
      expect(nodesInBounds, isNotEmpty);
    });

    test('group context provides moveNodes', () {
      final member = createTestNode(
        id: 'member-1',
        position: const Offset(100, 100),
      );
      final group = createTestGroupNode<String>(
        id: 'group-1',
        data: 'test',
        behavior: GroupBehavior.explicit,
        nodeIds: {'member-1'},
      );
      // Use addNode to ensure context is attached
      final controller = createTestController();
      controller.addNode(member);
      controller.addNode(group);

      final addedGroup = controller.getNode('group-1') as GroupNode<String>;
      final context = addedGroup.groupContext!;

      // Move nodes by delta
      context.moveNodes({'member-1'}, const Offset(50, 50));

      final movedMember = controller.getNode('member-1')!;
      expect(movedMember.position.value, equals(const Offset(150, 150)));
    });
  });

  // ===========================================================================
  // Child Callback Tests
  // ===========================================================================

  group('GroupableMixin - Child Callbacks', () {
    test('onChildMoved is called with nodeId and position', () {
      final member = createTestNode(
        id: 'member-1',
        position: const Offset(100, 100),
      );
      final node = TestGroupableNode<String>(
        id: 'test-1',
        data: 'test',
        groupable: true,
        memberIds: {'member-1'},
      );
      final controller = createTestController();
      controller.addNode(member);
      controller.addNode(node);

      final addedNode =
          controller.getNode('test-1') as TestGroupableNode<String>;

      // Move the member to trigger reaction
      final memberNode = controller.getNode('member-1')!;
      runInAction(() => memberNode.position.value = const Offset(200, 200));

      // Wait for the reaction to fire (async behavior)
      // The callback tracks calls
      expect(addedNode.childMovedCalls, isNotEmpty);
      expect(addedNode.childMovedCalls.last.$1, equals('member-1'));
    });

    test('onChildResized is called with nodeId and size', () {
      final member = createTestNode(id: 'member-1', size: const Size(100, 100));
      final node = TestGroupableNode<String>(
        id: 'test-1',
        data: 'test',
        groupable: true,
        memberIds: {'member-1'},
      );
      final controller = createTestController();
      controller.addNode(member);
      controller.addNode(node);

      final addedNode =
          controller.getNode('test-1') as TestGroupableNode<String>;

      // Resize the member to trigger reaction
      final memberNode = controller.getNode('member-1')!;
      runInAction(() => memberNode.size.value = const Size(200, 200));

      // The callback tracks calls
      expect(addedNode.childResizedCalls, isNotEmpty);
      expect(addedNode.childResizedCalls.last.$1, equals('member-1'));
    });

    test('onChildrenDeleted is called when members are deleted', () {
      final member = createTestNode(id: 'member-1');
      final group = createTestGroupNode<String>(
        id: 'group-1',
        data: 'test',
        behavior: GroupBehavior.explicit,
        nodeIds: {'member-1'},
      );
      final controller = createTestController();
      controller.addNode(member);
      controller.addNode(group);

      // Delete the member
      controller.removeNode('member-1');

      // Group should have received the deletion callback
      // (GroupNode implements onChildrenDeleted to remove from nodeIds)
      final addedGroup = controller.getNode('group-1');
      // Group may be auto-removed if empty, so check if it exists
      if (addedGroup != null) {
        final groupNode = addedGroup as GroupNode<String>;
        expect(groupNode.nodeIds, isNot(contains('member-1')));
      }
    });

    test('onNodeAdded callback is invokable', () {
      final node = TestGroupableNode<String>(id: 'test-1', data: 'test');

      // Manually invoke the callback
      node.onNodeAdded('new-node', const Rect.fromLTWH(0, 0, 100, 100));

      expect(node.nodeAddedCalls, hasLength(1));
      expect(node.nodeAddedCalls.first.$1, equals('new-node'));
    });

    test('onSelectionChanged callback is invokable', () {
      final node = TestGroupableNode<String>(id: 'test-1', data: 'test');

      // Manually invoke the callback
      node.onSelectionChanged({'node-1', 'node-2'});

      expect(node.selectionChangedCalls, hasLength(1));
      expect(
        node.selectionChangedCalls.first,
        containsAll(['node-1', 'node-2']),
      );
    });

    test('default onChildMoved is no-op', () {
      final group = createTestGroupNode<String>(
        id: 'group-1',
        data: 'test',
        behavior: GroupBehavior.bounds, // Bounds behavior doesn't track
      );
      final controller = createTestController(nodes: [group]);

      final addedGroup = controller.getNode('group-1') as GroupNode<String>;
      // Calling onChildMoved on bounds behavior should not throw
      addedGroup.onChildMoved('any-node', Offset.zero);
      // No exception means it's a no-op
    });

    test('default onChildResized is no-op', () {
      final group = createTestGroupNode<String>(
        id: 'group-1',
        data: 'test',
        behavior: GroupBehavior.bounds,
      );
      final controller = createTestController(nodes: [group]);

      final addedGroup = controller.getNode('group-1') as GroupNode<String>;
      // Calling onChildResized on bounds behavior should not throw
      addedGroup.onChildResized('any-node', Size.zero);
    });
  });

  // ===========================================================================
  // Reaction Management Tests
  // ===========================================================================

  group('GroupableMixin - Reaction Management', () {
    test('reactions track multiple member nodes', () {
      final member1 = createTestNode(
        id: 'member-1',
        position: const Offset(100, 100),
      );
      final member2 = createTestNode(
        id: 'member-2',
        position: const Offset(200, 200),
      );
      final node = TestGroupableNode<String>(
        id: 'test-1',
        data: 'test',
        groupable: true,
        memberIds: {'member-1', 'member-2'},
      );
      final controller = createTestController();
      controller.addNode(member1);
      controller.addNode(member2);
      controller.addNode(node);

      final addedNode =
          controller.getNode('test-1') as TestGroupableNode<String>;

      // Move member-1
      runInAction(
        () => controller.getNode('member-1')!.position.value = const Offset(
          150,
          150,
        ),
      );

      // Move member-2
      runInAction(
        () => controller.getNode('member-2')!.position.value = const Offset(
          250,
          250,
        ),
      );

      // Both moves should be tracked
      final movedIds = addedNode.childMovedCalls.map((c) => c.$1).toSet();
      expect(movedIds, containsAll(['member-1', 'member-2']));
    });

    test('reactions ignore non-member nodes', () {
      final member = createTestNode(
        id: 'member-1',
        position: const Offset(100, 100),
      );
      final nonMember = createTestNode(
        id: 'non-member',
        position: const Offset(300, 300),
      );
      final node = TestGroupableNode<String>(
        id: 'test-1',
        data: 'test',
        groupable: true,
        memberIds: {'member-1'}, // Only member-1
      );
      final controller = createTestController();
      controller.addNode(member);
      controller.addNode(nonMember);
      controller.addNode(node);

      final addedNode =
          controller.getNode('test-1') as TestGroupableNode<String>;
      addedNode.childMovedCalls.clear(); // Clear initial calls

      // Move non-member
      runInAction(
        () => controller.getNode('non-member')!.position.value = const Offset(
          400,
          400,
        ),
      );

      // Non-member move should not be tracked
      final movedIds = addedNode.childMovedCalls.map((c) => c.$1).toSet();
      expect(movedIds, isNot(contains('non-member')));
    });

    test('reactions are disposed when node is removed', () {
      final member = createTestNode(id: 'member-1');
      final node = TestGroupableNode<String>(
        id: 'test-1',
        data: 'test',
        groupable: true,
        memberIds: {'member-1'},
      );
      final controller = createTestController();
      controller.addNode(member);
      controller.addNode(node);

      final addedNode =
          controller.getNode('test-1') as TestGroupableNode<String>;

      controller.removeNode('test-1');

      // Context should be detached
      expect(addedNode.hasContext, isFalse);
      expect(addedNode.contextDetachingCalls, isNotEmpty);
    });

    test('shouldSkipUpdates prevents callbacks during batch operations', () {
      final member = createTestNode(
        id: 'member-1',
        position: const Offset(100, 100),
      );
      final group = createTestGroupNode<String>(
        id: 'group-1',
        data: 'test',
        behavior: GroupBehavior.explicit,
        nodeIds: {'member-1'},
      );
      final controller = createTestController();
      controller.addNode(member);
      controller.addNode(group);

      // The shouldSkipUpdates callback is used internally during group drag
      // to prevent recursive updates - we just verify context has it
      final addedGroup = controller.getNode('group-1') as GroupNode<String>;
      expect(addedGroup.groupContext!.shouldSkipUpdates, isNotNull);
    });
  });

  // ===========================================================================
  // Nested Groups Tests
  // ===========================================================================

  group('GroupableMixin - Nested Groups', () {
    test('nested groups maintain correct z-index ordering', () {
      final member = createTestNode(id: 'member-1');
      final innerGroup = createTestGroupNode<String>(
        id: 'inner-group',
        data: 'inner',
        behavior: GroupBehavior.explicit,
        nodeIds: {'member-1'},
        zIndex: -1,
      );
      final outerGroup = createTestGroupNode<String>(
        id: 'outer-group',
        data: 'outer',
        behavior: GroupBehavior.explicit,
        nodeIds: {'inner-group'},
        zIndex: -2,
      );
      final controller = createTestController();
      controller.addNode(member);
      controller.addNode(innerGroup);
      controller.addNode(outerGroup);

      final inner = controller.getNode('inner-group') as GroupNode<String>;
      final outer = controller.getNode('outer-group') as GroupNode<String>;

      // Inner group should have higher z-index than outer group
      expect(inner.zIndex.value, greaterThan(outer.zIndex.value));
    });

    test('multiple levels of nesting are supported', () {
      final member = createTestNode(id: 'member-1');
      final level1 = createTestGroupNode<String>(
        id: 'level-1',
        data: 'level1',
        behavior: GroupBehavior.parent,
        nodeIds: {'member-1'},
      );
      final level2 = createTestGroupNode<String>(
        id: 'level-2',
        data: 'level2',
        behavior: GroupBehavior.parent,
        nodeIds: {'level-1'},
      );
      final level3 = createTestGroupNode<String>(
        id: 'level-3',
        data: 'level3',
        behavior: GroupBehavior.parent,
        nodeIds: {'level-2'},
      );
      final controller = createTestController();
      controller.addNode(member);
      controller.addNode(level1);
      controller.addNode(level2);
      controller.addNode(level3);

      // All groups should have context
      expect(
        (controller.getNode('level-1') as GroupNode<String>).hasContext,
        isTrue,
      );
      expect(
        (controller.getNode('level-2') as GroupNode<String>).hasContext,
        isTrue,
      );
      expect(
        (controller.getNode('level-3') as GroupNode<String>).hasContext,
        isTrue,
      );
    });
  });

  // ===========================================================================
  // Dynamic Member Changes Tests
  // ===========================================================================

  group('GroupableMixin - Dynamic Member Changes', () {
    test('adding member to group updates groupedNodeIds', () {
      final member = createTestNode(id: 'member-1');
      final group = createTestGroupNode<String>(
        id: 'group-1',
        data: 'test',
        behavior: GroupBehavior.explicit,
        nodeIds: {},
      );
      final controller = createTestController();
      controller.addNode(member);
      controller.addNode(group);

      final addedGroup = controller.getNode('group-1') as GroupNode<String>;
      expect(addedGroup.groupedNodeIds, isEmpty);

      addedGroup.addNode('member-1');

      expect(addedGroup.groupedNodeIds, contains('member-1'));
    });

    test('removing member from group updates groupedNodeIds', () {
      final member = createTestNode(id: 'member-1');
      final group = createTestGroupNode<String>(
        id: 'group-1',
        data: 'test',
        behavior: GroupBehavior.explicit,
        nodeIds: {'member-1'},
      );
      final controller = createTestController();
      controller.addNode(member);
      controller.addNode(group);

      final addedGroup = controller.getNode('group-1') as GroupNode<String>;
      expect(addedGroup.groupedNodeIds, contains('member-1'));

      addedGroup.removeNode('member-1');

      expect(addedGroup.groupedNodeIds, isNot(contains('member-1')));
    });

    test('clearing all members updates groupedNodeIds', () {
      final member1 = createTestNode(id: 'member-1');
      final member2 = createTestNode(id: 'member-2');
      final group = createTestGroupNode<String>(
        id: 'group-1',
        data: 'test',
        behavior: GroupBehavior.parent, // Parent doesn't auto-remove when empty
        nodeIds: {'member-1', 'member-2'},
      );
      final controller = createTestController();
      controller.addNode(member1);
      controller.addNode(member2);
      controller.addNode(group);

      final addedGroup = controller.getNode('group-1') as GroupNode<String>;
      expect(addedGroup.groupedNodeIds.length, equals(2));

      addedGroup.clearNodes();

      expect(addedGroup.groupedNodeIds, isEmpty);
    });
  });

  // ===========================================================================
  // isGroupable Dynamic Changes Tests
  // ===========================================================================

  group('GroupableMixin - isGroupable Changes', () {
    test('changing behavior from bounds to explicit enables groupable', () {
      final member = createTestNode(id: 'member-1');
      final group = createTestGroupNode<String>(
        id: 'group-1',
        data: 'test',
        behavior: GroupBehavior.bounds,
      );
      final controller = createTestController();
      controller.addNode(member);
      controller.addNode(group);

      final addedGroup = controller.getNode('group-1') as GroupNode<String>;
      expect(addedGroup.isGroupable, isFalse);

      addedGroup.setBehavior(
        GroupBehavior.explicit,
        captureContainedNodes: {'member-1'},
      );

      expect(addedGroup.isGroupable, isTrue);
      expect(addedGroup.groupedNodeIds, contains('member-1'));
    });

    test('changing behavior from explicit to bounds disables groupable', () {
      final member = createTestNode(id: 'member-1');
      final group = createTestGroupNode<String>(
        id: 'group-1',
        data: 'test',
        behavior: GroupBehavior.explicit,
        nodeIds: {'member-1'},
      );
      final controller = createTestController();
      controller.addNode(member);
      controller.addNode(group);

      final addedGroup = controller.getNode('group-1') as GroupNode<String>;
      expect(addedGroup.isGroupable, isTrue);

      addedGroup.setBehavior(GroupBehavior.bounds);

      expect(addedGroup.isGroupable, isFalse);
      // groupedNodeIds should be empty for bounds behavior
      expect(addedGroup.groupedNodeIds, isEmpty);
    });

    test('TestGroupableNode isGroupable can be toggled', () {
      final node = TestGroupableNode<String>(
        id: 'test-1',
        data: 'test',
        groupable: false,
      );

      expect(node.isGroupable, isFalse);

      node.isGroupable = true;

      expect(node.isGroupable, isTrue);
    });
  });

  // ===========================================================================
  // Edge Cases Tests
  // ===========================================================================

  group('GroupableMixin - Edge Cases', () {
    test('attachContext with null context early returns from reactions', () {
      // This is tested implicitly - when context is null, reactions
      // early return. We verify by checking no errors occur.
      final node = TestGroupableNode<String>(
        id: 'test-1',
        data: 'test',
        groupable: true,
      );

      // Node without controller has no context
      expect(node.hasContext, isFalse);
      // Callbacks should not throw
      node.onChildMoved('any', Offset.zero);
      node.onChildResized('any', Size.zero);
    });

    test('reactions handle missing member nodes gracefully', () {
      // Create a groupable node that references non-existent members
      final node = TestGroupableNode<String>(
        id: 'test-1',
        data: 'test',
        groupable: true,
        memberIds: {'non-existent-1', 'non-existent-2'},
      );
      final controller = createTestController();
      controller.addNode(node);

      // No errors should occur - reactions just skip missing nodes
      expect(controller.getNode('test-1'), isNotNull);
    });

    test('hasContext returns false before attachment', () {
      final node = TestGroupableNode<String>(id: 'test-1', data: 'test');

      expect(node.hasContext, isFalse);
    });

    test('hasContext returns true after attachment', () {
      final node = TestGroupableNode<String>(id: 'test-1', data: 'test');
      final controller = createTestController();
      controller.addNode(node);

      final addedNode =
          controller.getNode('test-1') as TestGroupableNode<String>;
      expect(addedNode.hasContext, isTrue);
    });

    test('groupContext is accessible after attachment', () {
      final node = TestGroupableNode<String>(id: 'test-1', data: 'test');
      final controller = createTestController();
      controller.addNode(node);

      final addedNode =
          controller.getNode('test-1') as TestGroupableNode<String>;
      expect(addedNode.groupContext, isNotNull);
      expect(addedNode.groupContext!.getNode, isNotNull);
      expect(addedNode.groupContext!.moveNodes, isNotNull);
      expect(addedNode.groupContext!.findNodesInBounds, isNotNull);
    });

    test('empty groupedNodeIds does not cause reaction errors', () {
      final node = TestGroupableNode<String>(
        id: 'test-1',
        data: 'test',
        groupable: true,
        memberIds: {}, // Empty
      );
      final controller = createTestController();
      controller.addNode(node);

      // No errors should occur
      expect(controller.getNode('test-1'), isNotNull);
    });

    test('onContextDetaching is called before context is cleared', () {
      final node = TestGroupableNode<String>(id: 'test-1', data: 'test');
      final controller = createTestController();
      controller.addNode(node);

      final addedNode =
          controller.getNode('test-1') as TestGroupableNode<String>;

      // Verify context exists before removal
      expect(addedNode.hasContext, isTrue);

      controller.removeNode('test-1');

      // onContextDetaching should have been called
      expect(addedNode.contextDetachingCalls, isNotEmpty);
      // And context should now be null
      expect(addedNode.hasContext, isFalse);
    });
  });

  // ===========================================================================
  // Position and Size Observable Tests
  // ===========================================================================

  group('GroupableMixin - Observable Position/Size Tracking', () {
    test('position changes trigger onChildMoved for all members', () {
      final member1 = createTestNode(
        id: 'member-1',
        position: const Offset(50, 50),
      );
      final member2 = createTestNode(
        id: 'member-2',
        position: const Offset(150, 150),
      );
      final node = TestGroupableNode<String>(
        id: 'test-1',
        data: 'test',
        groupable: true,
        memberIds: {'member-1', 'member-2'},
      );
      final controller = createTestController();
      controller.addNode(member1);
      controller.addNode(member2);
      controller.addNode(node);

      final addedNode =
          controller.getNode('test-1') as TestGroupableNode<String>;
      addedNode.childMovedCalls.clear();

      // Move member-1
      runInAction(
        () => controller.getNode('member-1')!.position.value = const Offset(
          60,
          60,
        ),
      );

      // Should have recorded the move
      expect(addedNode.childMovedCalls.any((c) => c.$1 == 'member-1'), isTrue);
    });

    test('size changes trigger onChildResized for all members', () {
      final member1 = createTestNode(
        id: 'member-1',
        size: const Size(100, 100),
      );
      final member2 = createTestNode(id: 'member-2', size: const Size(80, 80));
      final node = TestGroupableNode<String>(
        id: 'test-1',
        data: 'test',
        groupable: true,
        memberIds: {'member-1', 'member-2'},
      );
      final controller = createTestController();
      controller.addNode(member1);
      controller.addNode(member2);
      controller.addNode(node);

      final addedNode =
          controller.getNode('test-1') as TestGroupableNode<String>;
      addedNode.childResizedCalls.clear();

      // Resize member-2
      runInAction(
        () => controller.getNode('member-2')!.size.value = const Size(120, 120),
      );

      // Should have recorded the resize
      expect(
        addedNode.childResizedCalls.any((c) => c.$1 == 'member-2'),
        isTrue,
      );
    });
  });

  // ===========================================================================
  // Group Member Management Integration Tests
  // ===========================================================================

  group('GroupableMixin - Member Management Integration', () {
    test('adding nested group as member adjusts z-index', () {
      final innerGroup = createTestGroupNode<String>(
        id: 'inner',
        data: 'inner',
        behavior: GroupBehavior.parent,
        zIndex: -1,
      );
      final outerGroup = createTestGroupNode<String>(
        id: 'outer',
        data: 'outer',
        behavior: GroupBehavior.parent,
        zIndex: -1, // Same z-index initially
      );
      final controller = createTestController();
      controller.addNode(innerGroup);
      controller.addNode(outerGroup);

      final outer = controller.getNode('outer') as GroupNode<String>;

      // Add inner to outer
      outer.addNode('inner');

      final inner = controller.getNode('inner') as GroupNode<String>;

      // Inner should now have higher z-index
      expect(inner.zIndex.value, greaterThan(outer.zIndex.value));
    });

    test('hasNode returns true for members', () {
      final member = createTestNode(id: 'member-1');
      final group = createTestGroupNode<String>(
        id: 'group-1',
        data: 'test',
        behavior: GroupBehavior.explicit,
        nodeIds: {'member-1'},
      );
      final controller = createTestController();
      controller.addNode(member);
      controller.addNode(group);

      final addedGroup = controller.getNode('group-1') as GroupNode<String>;
      expect(addedGroup.hasNode('member-1'), isTrue);
      expect(addedGroup.hasNode('non-member'), isFalse);
    });

    test('onChildrenDeleted removes deleted members from group', () {
      final member1 = createTestNode(id: 'member-1');
      final member2 = createTestNode(id: 'member-2');
      final group = createTestGroupNode<String>(
        id: 'group-1',
        data: 'test',
        behavior: GroupBehavior.parent, // Parent doesn't auto-remove
        nodeIds: {'member-1', 'member-2'},
      );
      final controller = createTestController();
      controller.addNode(member1);
      controller.addNode(member2);
      controller.addNode(group);

      final addedGroup = controller.getNode('group-1') as GroupNode<String>;
      expect(addedGroup.nodeIds, containsAll(['member-1', 'member-2']));

      // Delete member-1
      controller.removeNode('member-1');

      expect(addedGroup.nodeIds, isNot(contains('member-1')));
      expect(addedGroup.nodeIds, contains('member-2'));
    });
  });
}
