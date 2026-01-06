/// Unit tests for special node types: GroupNode and CommentNode.
///
/// Tests cover:
/// - GroupNode construction, properties, copyWith, and behaviors
/// - CommentNode construction, properties, and copyWith
/// - GroupNode-specific functionality (member nodes, bounds, explicit behavior)
/// - CommentNode-specific functionality (text, color, constraints)
/// - Integration with NodeFlowController for adding/removing special nodes
/// - Serialization for both node types
@Tags(['unit'])
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vyuh_node_flow/vyuh_node_flow.dart';

import '../../helpers/test_factories.dart';
import '../../helpers/test_utils.dart';

void main() {
  setUp(() {
    resetTestCounters();
  });

  // ==========================================================================
  // GroupNode Tests
  // ==========================================================================
  group('GroupNode', () {
    group('Construction', () {
      test('creates group node with required parameters', () {
        final group = GroupNode<String>(
          id: 'group-1',
          position: const Offset(100, 100),
          size: const Size(400, 300),
          title: 'Test Group',
          data: 'group-data',
        );

        expect(group.id, equals('group-1'));
        expect(group.position.value, equals(const Offset(100, 100)));
        expect(group.size.value, equals(const Size(400, 300)));
        expect(group.currentTitle, equals('Test Group'));
        expect(group.data, equals('group-data'));
        expect(group.type, equals('group'));
      });

      test('creates group node with default values', () {
        final group = createTestGroupNode<String>(data: 'test');

        expect(group.currentColor, equals(Colors.blue));
        expect(group.behavior, equals(GroupBehavior.bounds));
        expect(group.nodeIds, isEmpty);
        expect(group.padding, equals(kGroupNodeDefaultPadding));
        expect(group.zIndex.value, equals(-1));
        expect(group.isVisible, isTrue);
        expect(group.locked, isFalse);
      });

      test('creates group node with custom color', () {
        final group = GroupNode<String>(
          id: 'colored-group',
          position: Offset.zero,
          size: const Size(300, 200),
          title: 'Colored',
          data: 'test',
          color: Colors.red,
        );

        expect(group.currentColor, equals(Colors.red));
      });

      test('creates group node with explicit behavior and nodeIds', () {
        final group = GroupNode<String>(
          id: 'explicit-group',
          position: const Offset(50, 50),
          size: const Size(500, 400),
          title: 'Explicit Group',
          data: 'test',
          behavior: GroupBehavior.explicit,
          nodeIds: {'node-1', 'node-2', 'node-3'},
        );

        expect(group.behavior, equals(GroupBehavior.explicit));
        expect(group.nodeIds, containsAll(['node-1', 'node-2', 'node-3']));
        expect(group.nodeIds.length, equals(3));
      });

      test('creates group node with parent behavior', () {
        final group = GroupNode<String>(
          id: 'parent-group',
          position: Offset.zero,
          size: const Size(300, 200),
          title: 'Parent',
          data: 'test',
          behavior: GroupBehavior.parent,
          nodeIds: {'child-1'},
        );

        expect(group.behavior, equals(GroupBehavior.parent));
        expect(group.hasNode('child-1'), isTrue);
      });

      test('creates group node with custom padding', () {
        const customPadding = EdgeInsets.all(30);
        final group = GroupNode<String>(
          id: 'padded-group',
          position: Offset.zero,
          size: const Size(300, 200),
          title: 'Padded',
          data: 'test',
          padding: customPadding,
        );

        expect(group.padding, equals(customPadding));
      });

      test('creates group node with ports for subflow patterns', () {
        final inputPort = Port(
          id: 'in-1',
          name: 'Input',
          type: PortType.input,
          position: PortPosition.left,
        );
        final outputPort = Port(
          id: 'out-1',
          name: 'Output',
          type: PortType.output,
          position: PortPosition.right,
        );

        final group = GroupNode<String>(
          id: 'subflow-group',
          position: Offset.zero,
          size: const Size(400, 300),
          title: 'Subflow',
          data: 'test',
          inputPorts: [inputPort],
          outputPorts: [outputPort],
        );

        expect(group.inputPorts.length, equals(1));
        expect(group.outputPorts.length, equals(1));
        expect(group.inputPorts.first.id, equals('in-1'));
        expect(group.outputPorts.first.id, equals('out-1'));
      });

      test('creates group node in background layer by default', () {
        final group = createTestGroupNode<String>(data: 'test');

        expect(group.layer, equals(NodeRenderLayer.background));
      });

      test('creates group node not selectable by default', () {
        final group = createTestGroupNode<String>(data: 'test');

        expect(group.selectable, isFalse);
      });
    });

    group('Properties', () {
      test('observableTitle is reactive', () {
        final group = createTestGroupNode<String>(
          title: 'Initial',
          data: 'test',
        );
        final tracker = ObservableTracker<String>();
        tracker.track(group.observableTitle);

        group.updateTitle('Updated Title');

        expect(group.currentTitle, equals('Updated Title'));
        expect(tracker.values, contains('Updated Title'));
        tracker.dispose();
      });

      test('observableColor is reactive', () {
        final group = createTestGroupNode<String>(
          color: Colors.blue,
          data: 'test',
        );
        final tracker = ObservableTracker<Color>();
        tracker.track(group.observableColor);

        group.updateColor(Colors.green);

        expect(group.currentColor, equals(Colors.green));
        expect(tracker.values, contains(Colors.green));
        tracker.dispose();
      });

      test('observableSize is reactive', () {
        final group = createTestGroupNode<String>(
          size: const Size(300, 200),
          data: 'test',
        );

        group.setSize(const Size(500, 400));

        expect(group.currentSize, equals(const Size(500, 400)));
        expect(group.observableSize.value, equals(const Size(500, 400)));
      });

      test('bounds returns correct rectangle', () {
        final group = GroupNode<String>(
          id: 'bounds-group',
          position: const Offset(100, 50),
          size: const Size(300, 200),
          title: 'Bounds',
          data: 'test',
        );

        final bounds = group.bounds;

        expect(bounds.left, equals(100));
        expect(bounds.top, equals(50));
        expect(bounds.width, equals(300));
        expect(bounds.height, equals(200));
      });

      test('isResizable returns true for bounds behavior', () {
        final group = createTestGroupNode<String>(
          behavior: GroupBehavior.bounds,
          data: 'test',
        );

        expect(group.isResizable, isTrue);
      });

      test('isResizable returns false for explicit behavior', () {
        final group = createTestGroupNode<String>(
          behavior: GroupBehavior.explicit,
          data: 'test',
        );

        expect(group.isResizable, isFalse);
      });

      test('isResizable returns true for parent behavior', () {
        final group = createTestGroupNode<String>(
          behavior: GroupBehavior.parent,
          data: 'test',
        );

        expect(group.isResizable, isTrue);
      });
    });

    group('Member Node Management', () {
      test('addNode adds node to explicit membership', () {
        final group = GroupNode<String>(
          id: 'explicit-group',
          position: Offset.zero,
          size: const Size(300, 200),
          title: 'Explicit',
          data: 'test',
          behavior: GroupBehavior.explicit,
        );

        group.addNode('new-node');

        expect(group.hasNode('new-node'), isTrue);
        expect(group.nodeIds, contains('new-node'));
      });

      test('removeNode removes node from membership', () {
        final group = GroupNode<String>(
          id: 'group',
          position: Offset.zero,
          size: const Size(300, 200),
          title: 'Group',
          data: 'test',
          behavior: GroupBehavior.explicit,
          nodeIds: {'node-1', 'node-2'},
        );

        group.removeNode('node-1');

        expect(group.hasNode('node-1'), isFalse);
        expect(group.hasNode('node-2'), isTrue);
      });

      test('clearNodes removes all nodes', () {
        final group = GroupNode<String>(
          id: 'group',
          position: Offset.zero,
          size: const Size(300, 200),
          title: 'Group',
          data: 'test',
          behavior: GroupBehavior.explicit,
          nodeIds: {'node-1', 'node-2', 'node-3'},
        );

        group.clearNodes();

        expect(group.nodeIds, isEmpty);
      });

      test('hasNode returns false for non-member', () {
        final group = createTestGroupNode<String>(
          behavior: GroupBehavior.explicit,
          nodeIds: {'node-1'},
          data: 'test',
        );

        expect(group.hasNode('non-existent'), isFalse);
      });
    });

    group('Bounds Calculation', () {
      test('containsRect returns true for rect inside bounds', () {
        final group = GroupNode<String>(
          id: 'group',
          position: const Offset(0, 0),
          size: const Size(400, 300),
          title: 'Group',
          data: 'test',
        );

        final innerRect = const Rect.fromLTWH(50, 50, 100, 100);

        expect(group.containsRect(innerRect), isTrue);
      });

      test('containsRect returns false for rect outside bounds', () {
        final group = GroupNode<String>(
          id: 'group',
          position: const Offset(0, 0),
          size: const Size(400, 300),
          title: 'Group',
          data: 'test',
        );

        final outerRect = const Rect.fromLTWH(500, 500, 100, 100);

        expect(group.containsRect(outerRect), isFalse);
      });

      test('containsRect returns false for partially overlapping rect', () {
        final group = GroupNode<String>(
          id: 'group',
          position: const Offset(0, 0),
          size: const Size(400, 300),
          title: 'Group',
          data: 'test',
        );

        final partialRect = const Rect.fromLTWH(350, 250, 100, 100);

        expect(group.containsRect(partialRect), isFalse);
      });
    });

    group('Size Constraints', () {
      test('setSize enforces minimum width', () {
        final group = createTestGroupNode<String>(data: 'test');

        group.setSize(const Size(50, 200)); // Width below minimum

        expect(group.currentSize.width, greaterThanOrEqualTo(100));
      });

      test('setSize enforces minimum height', () {
        final group = createTestGroupNode<String>(data: 'test');

        group.setSize(const Size(200, 30)); // Height below minimum

        expect(group.currentSize.height, greaterThanOrEqualTo(60));
      });

      test('minSize returns correct minimum dimensions', () {
        final group = createTestGroupNode<String>(data: 'test');

        expect(group.minSize, equals(const Size(100, 60)));
      });
    });

    group('GroupBehavior', () {
      test('isGroupable returns false for bounds behavior', () {
        final group = createTestGroupNode<String>(
          behavior: GroupBehavior.bounds,
          data: 'test',
        );

        expect(group.isGroupable, isFalse);
      });

      test('isGroupable returns true for explicit behavior', () {
        final group = createTestGroupNode<String>(
          behavior: GroupBehavior.explicit,
          data: 'test',
        );

        expect(group.isGroupable, isTrue);
      });

      test('isGroupable returns true for parent behavior', () {
        final group = createTestGroupNode<String>(
          behavior: GroupBehavior.parent,
          data: 'test',
        );

        expect(group.isGroupable, isTrue);
      });

      test('isEmpty returns true when explicit group has no nodes', () {
        final group = GroupNode<String>(
          id: 'empty-group',
          position: Offset.zero,
          size: const Size(300, 200),
          title: 'Empty',
          data: 'test',
          behavior: GroupBehavior.explicit,
        );

        expect(group.isEmpty, isTrue);
      });

      test('isEmpty returns false for bounds behavior', () {
        final group = createTestGroupNode<String>(
          behavior: GroupBehavior.bounds,
          data: 'test',
        );

        expect(group.isEmpty, isFalse);
      });

      test('shouldRemoveWhenEmpty is true for explicit behavior', () {
        final group = createTestGroupNode<String>(
          behavior: GroupBehavior.explicit,
          data: 'test',
        );

        expect(group.shouldRemoveWhenEmpty, isTrue);
      });

      test('shouldRemoveWhenEmpty is false for bounds behavior', () {
        final group = createTestGroupNode<String>(
          behavior: GroupBehavior.bounds,
          data: 'test',
        );

        expect(group.shouldRemoveWhenEmpty, isFalse);
      });

      test('shouldRemoveWhenEmpty is false for parent behavior', () {
        final group = createTestGroupNode<String>(
          behavior: GroupBehavior.parent,
          data: 'test',
        );

        expect(group.shouldRemoveWhenEmpty, isFalse);
      });
    });

    group('copyWith', () {
      test('copyWith creates new instance with same values', () {
        final original = GroupNode<String>(
          id: 'original',
          position: const Offset(100, 100),
          size: const Size(400, 300),
          title: 'Original',
          data: 'original-data',
          color: Colors.blue,
          behavior: GroupBehavior.explicit,
          nodeIds: {'node-1'},
          zIndex: 5,
        );

        final copy = original.copyWith();

        expect(copy.id, equals(original.id));
        expect(copy.position.value, equals(original.position.value));
        expect(copy.size.value, equals(original.size.value));
        expect(copy.currentTitle, equals(original.currentTitle));
        expect(copy.data, equals(original.data));
        expect(copy.currentColor, equals(original.currentColor));
        expect(copy.behavior, equals(original.behavior));
        expect(copy.nodeIds, equals(original.nodeIds));
      });

      test('copyWith overrides specified values', () {
        final original = createTestGroupNode<String>(
          title: 'Original',
          color: Colors.blue,
          data: 'test',
        );

        final copy = original.copyWith(
          id: 'new-id',
          title: 'New Title',
          color: Colors.red,
        );

        expect(copy.id, equals('new-id'));
        expect(copy.currentTitle, equals('New Title'));
        expect(copy.currentColor, equals(Colors.red));
        // Original values preserved for unspecified properties
        expect(copy.position.value, equals(original.position.value));
      });
    });

    group('JSON Serialization', () {
      test('toJson produces valid JSON', () {
        final group = GroupNode<String>(
          id: 'json-group',
          position: const Offset(100, 200),
          size: const Size(400, 300),
          title: 'JSON Group',
          data: 'json-data',
          color: Colors.red,
          behavior: GroupBehavior.explicit,
          nodeIds: {'node-1', 'node-2'},
        );

        final json = group.toJson((data) => data);

        expect(json['id'], equals('json-group'));
        expect(json['x'], equals(100.0));
        expect(json['y'], equals(200.0));
        expect(json['width'], equals(400.0));
        expect(json['height'], equals(300.0));
        expect(json['title'], equals('JSON Group'));
        expect(json['behavior'], equals('explicit'));
        expect(json['nodeIds'], containsAll(['node-1', 'node-2']));
      });

      test('fromJson reconstructs group node correctly', () {
        final json = {
          'id': 'reconstructed',
          'x': 100.0,
          'y': 200.0,
          'width': 400.0,
          'height': 300.0,
          'title': 'Reconstructed',
          'data': 'data',
          'color': Colors.green.toARGB32(),
          'behavior': 'parent',
          'nodeIds': ['child-1'],
          'zIndex': 3,
          'isVisible': true,
        };

        final group = GroupNode<String>.fromJson(
          json,
          dataFromJson: (json) => json as String,
        );

        expect(group.id, equals('reconstructed'));
        expect(group.position.value, equals(const Offset(100, 200)));
        expect(group.size.value, equals(const Size(400, 300)));
        expect(group.currentTitle, equals('Reconstructed'));
        expect(group.behavior, equals(GroupBehavior.parent));
        expect(group.nodeIds, contains('child-1'));
        expect(group.currentZIndex, equals(3));
      });
    });
  });

  // ==========================================================================
  // CommentNode Tests
  // ==========================================================================
  group('CommentNode', () {
    group('Construction', () {
      test('creates comment node with required parameters', () {
        final comment = CommentNode<String>(
          id: 'comment-1',
          position: const Offset(100, 100),
          text: 'Test comment',
          data: 'comment-data',
        );

        expect(comment.id, equals('comment-1'));
        expect(comment.position.value, equals(const Offset(100, 100)));
        expect(comment.text, equals('Test comment'));
        expect(comment.data, equals('comment-data'));
        expect(comment.type, equals('comment'));
      });

      test('creates comment node with default values', () {
        final comment = createTestCommentNode<String>(data: 'test');

        expect(comment.width, equals(200.0));
        expect(comment.height, equals(100.0));
        expect(comment.color, equals(Colors.yellow));
        expect(comment.zIndex.value, equals(0));
        expect(comment.isVisible, isTrue);
        expect(comment.locked, isFalse);
      });

      test('creates comment node with custom dimensions', () {
        final comment = CommentNode<String>(
          id: 'custom-comment',
          position: Offset.zero,
          text: 'Custom',
          data: 'test',
          width: 300,
          height: 150,
        );

        expect(comment.width, equals(300));
        expect(comment.height, equals(150));
      });

      test('creates comment node with custom color', () {
        final comment = CommentNode<String>(
          id: 'colored-comment',
          position: Offset.zero,
          text: 'Colored',
          data: 'test',
          color: Colors.pink,
        );

        expect(comment.color, equals(Colors.pink));
      });

      test('creates comment node in foreground layer', () {
        final comment = createTestCommentNode<String>(data: 'test');

        expect(comment.layer, equals(NodeRenderLayer.foreground));
      });

      test('creates comment node not selectable by default', () {
        final comment = createTestCommentNode<String>(data: 'test');

        expect(comment.selectable, isFalse);
      });

      test('creates comment node with no ports', () {
        final comment = createTestCommentNode<String>(data: 'test');

        expect(comment.inputPorts, isEmpty);
        expect(comment.outputPorts, isEmpty);
      });
    });

    group('Properties', () {
      test('text is observable and updates correctly', () {
        final comment = createTestCommentNode<String>(
          text: 'Initial text',
          data: 'test',
        );

        comment.text = 'Updated text';

        expect(comment.text, equals('Updated text'));
      });

      test('color is observable and updates correctly', () {
        final comment = createTestCommentNode<String>(
          color: Colors.yellow,
          data: 'test',
        );

        comment.color = Colors.blue;

        expect(comment.color, equals(Colors.blue));
      });

      test('width and height reflect size', () {
        final comment = CommentNode<String>(
          id: 'sized-comment',
          position: Offset.zero,
          text: 'Sized',
          data: 'test',
          width: 250,
          height: 120,
        );

        expect(comment.width, equals(250));
        expect(comment.height, equals(120));
        expect(comment.size.value, equals(const Size(250, 120)));
      });
    });

    group('Size Constraints', () {
      test('minSize is 100x60', () {
        final comment = createTestCommentNode<String>(data: 'test');

        expect(comment.minSize, equals(const Size(100, 60)));
      });

      test('maxSize is 600x400', () {
        final comment = createTestCommentNode<String>(data: 'test');

        expect(comment.maxSize, equals(const Size(600, 400)));
      });

      test('setSize enforces minimum width', () {
        final comment = createTestCommentNode<String>(data: 'test');

        comment.setSize(const Size(50, 100)); // Below minimum width

        expect(comment.width, equals(CommentNode.minWidth));
      });

      test('setSize enforces minimum height', () {
        final comment = createTestCommentNode<String>(data: 'test');

        comment.setSize(const Size(200, 30)); // Below minimum height

        expect(comment.height, equals(CommentNode.minHeight));
      });

      test('setSize enforces maximum width', () {
        final comment = createTestCommentNode<String>(data: 'test');

        comment.setSize(const Size(800, 200)); // Above maximum width

        expect(comment.width, equals(CommentNode.maxWidth));
      });

      test('setSize enforces maximum height', () {
        final comment = createTestCommentNode<String>(data: 'test');

        comment.setSize(const Size(300, 500)); // Above maximum height

        expect(comment.height, equals(CommentNode.maxHeight));
      });
    });

    group('Resizable Capability', () {
      test('isResizable returns true', () {
        final comment = createTestCommentNode<String>(data: 'test');

        expect(comment.isResizable, isTrue);
      });
    });

    group('copyWith', () {
      test('copyWith creates new instance with same values', () {
        final original = CommentNode<String>(
          id: 'original',
          position: const Offset(100, 100),
          text: 'Original text',
          data: 'original-data',
          width: 250,
          height: 150,
          color: Colors.orange,
          zIndex: 5,
        );

        final copy = original.copyWith();

        expect(copy.id, equals(original.id));
        expect(copy.position.value, equals(original.position.value));
        expect(copy.text, equals(original.text));
        expect(copy.data, equals(original.data));
        expect(copy.width, equals(original.width));
        expect(copy.height, equals(original.height));
        expect(copy.color, equals(original.color));
        expect(copy.zIndex.value, equals(original.zIndex.value));
      });

      test('copyWith overrides specified values', () {
        final original = createTestCommentNode<String>(
          text: 'Original',
          color: Colors.yellow,
          data: 'test',
        );

        final copy = original.copyWith(
          id: 'new-id',
          text: 'New text',
          color: Colors.green,
        );

        expect(copy.id, equals('new-id'));
        expect(copy.text, equals('New text'));
        expect(copy.color, equals(Colors.green));
        // Original values preserved for unspecified properties
        expect(copy.position.value, equals(original.position.value));
      });
    });

    group('JSON Serialization', () {
      test('toJson produces valid JSON', () {
        final comment = CommentNode<String>(
          id: 'json-comment',
          position: const Offset(50, 75),
          text: 'JSON text',
          data: 'json-data',
          width: 220,
          height: 130,
          color: Colors.pink,
        );

        final json = comment.toJson((data) => data);

        expect(json['id'], equals('json-comment'));
        expect(json['x'], equals(50.0));
        expect(json['y'], equals(75.0));
        expect(json['width'], equals(220.0));
        expect(json['height'], equals(130.0));
        expect(json['text'], equals('JSON text'));
        expect(json['data'], equals('json-data'));
      });

      test('fromJson reconstructs comment node correctly', () {
        final json = {
          'id': 'reconstructed',
          'x': 50.0,
          'y': 75.0,
          'width': 220.0,
          'height': 130.0,
          'text': 'Reconstructed text',
          'data': 'data',
          'color': Colors.cyan.toARGB32(),
          'zIndex': 3,
          'isVisible': true,
        };

        final comment = CommentNode<String>.fromJson(
          json,
          dataFromJson: (json) => json as String,
        );

        expect(comment.id, equals('reconstructed'));
        expect(comment.position.value, equals(const Offset(50, 75)));
        expect(comment.size.value, equals(const Size(220, 130)));
        expect(comment.text, equals('Reconstructed text'));
        expect(comment.currentZIndex, equals(3));
      });

      test('fromJson handles missing optional fields', () {
        final json = {
          'id': 'minimal',
          'x': 0.0,
          'y': 0.0,
          'data': 'minimal-data',
        };

        final comment = CommentNode<String>.fromJson(
          json,
          dataFromJson: (json) => json as String,
        );

        expect(comment.id, equals('minimal'));
        expect(comment.text, equals('')); // Default empty text
        expect(comment.width, equals(200.0)); // Default width
        expect(comment.height, equals(100.0)); // Default height
      });
    });
  });

  // ==========================================================================
  // Integration with NodeFlowController Tests
  // ==========================================================================
  group('Integration with NodeFlowController', () {
    group('GroupNode Integration', () {
      test('adding group node to controller', () {
        final controller = createTestController();
        final group = createTestGroupNode<String>(
          id: 'group-1',
          data: 'group-data',
        );

        controller.addNode(group);

        expect(controller.nodes.containsKey('group-1'), isTrue);
        expect(controller.nodes['group-1'], isA<GroupNode<String>>());
      });

      test('removing group node from controller', () {
        final group = createTestGroupNode<String>(
          id: 'group-1',
          data: 'group-data',
        );
        final controller = createTestController(nodes: [group]);

        controller.removeNode('group-1');

        expect(controller.nodes.containsKey('group-1'), isFalse);
      });

      test('group node appears in sorted nodes at correct position', () {
        final regularNode = createTestNode(id: 'node-1', zIndex: 0);
        final group = createTestGroupNode<String>(
          id: 'group-1',
          zIndex: -1,
          data: 'group-data',
        );
        final controller = createTestController(nodes: [regularNode, group]);

        final sortedNodes = controller.sortedNodes;

        // Group should be first (lower z-index)
        expect(sortedNodes.first.id, equals('group-1'));
        expect(sortedNodes.last.id, equals('node-1'));
      });

      test('multiple group nodes can be added', () {
        final controller = createTestController();
        final group1 = createTestGroupNode<String>(id: 'group-1', data: 'g1');
        final group2 = createTestGroupNode<String>(id: 'group-2', data: 'g2');

        controller.addNode(group1);
        controller.addNode(group2);

        expect(controller.nodes.length, equals(2));
        expect(controller.nodes['group-1'], isA<GroupNode<String>>());
        expect(controller.nodes['group-2'], isA<GroupNode<String>>());
      });
    });

    group('CommentNode Integration', () {
      test('adding comment node to controller', () {
        final controller = createTestController();
        final comment = createTestCommentNode<String>(
          id: 'comment-1',
          data: 'comment-data',
        );

        controller.addNode(comment);

        expect(controller.nodes.containsKey('comment-1'), isTrue);
        expect(controller.nodes['comment-1'], isA<CommentNode<String>>());
      });

      test('removing comment node from controller', () {
        final comment = createTestCommentNode<String>(
          id: 'comment-1',
          data: 'comment-data',
        );
        final controller = createTestController(nodes: [comment]);

        controller.removeNode('comment-1');

        expect(controller.nodes.containsKey('comment-1'), isFalse);
      });

      test('comment node appears in sorted nodes at correct position', () {
        final regularNode = createTestNode(id: 'node-1', zIndex: 0);
        final comment = createTestCommentNode<String>(
          id: 'comment-1',
          zIndex: 10,
          data: 'comment-data',
        );
        final controller = createTestController(nodes: [regularNode, comment]);

        final sortedNodes = controller.sortedNodes;

        // Comment should be last (higher z-index)
        expect(sortedNodes.first.id, equals('node-1'));
        expect(sortedNodes.last.id, equals('comment-1'));
      });

      test('multiple comment nodes can be added', () {
        final controller = createTestController();
        final comment1 = createTestCommentNode<String>(id: 'c-1', data: 'c1');
        final comment2 = createTestCommentNode<String>(id: 'c-2', data: 'c2');

        controller.addNode(comment1);
        controller.addNode(comment2);

        expect(controller.nodes.length, equals(2));
        expect(controller.nodes['c-1'], isA<CommentNode<String>>());
        expect(controller.nodes['c-2'], isA<CommentNode<String>>());
      });
    });

    group('Mixed Node Types', () {
      test('controller handles mix of regular, group, and comment nodes', () {
        final regularNode = createTestNode(id: 'regular-1');
        final group = createTestGroupNode<String>(id: 'group-1', data: 'g');
        final comment = createTestCommentNode<String>(
          id: 'comment-1',
          data: 'c',
        );

        final controller = createTestController(
          nodes: [regularNode, group, comment],
        );

        expect(controller.nodes.length, equals(3));
        expect(controller.nodes['regular-1'], isA<Node<String>>());
        expect(controller.nodes['group-1'], isA<GroupNode<String>>());
        expect(controller.nodes['comment-1'], isA<CommentNode<String>>());
      });

      test('nodes are sorted correctly by z-index with mixed types', () {
        final group = createTestGroupNode<String>(
          id: 'group-1',
          zIndex: -1,
          data: 'g',
        );
        final regularNode = createTestNode(id: 'regular-1', zIndex: 0);
        final comment = createTestCommentNode<String>(
          id: 'comment-1',
          zIndex: 10,
          data: 'c',
        );

        final controller = createTestController(
          nodes: [regularNode, group, comment],
        );

        final sortedNodes = controller.sortedNodes;

        expect(sortedNodes[0].id, equals('group-1')); // z-index: -1
        expect(sortedNodes[1].id, equals('regular-1')); // z-index: 0
        expect(sortedNodes[2].id, equals('comment-1')); // z-index: 10
      });

      test('removing one type does not affect others', () {
        final regularNode = createTestNode(id: 'regular-1');
        final group = createTestGroupNode<String>(id: 'group-1', data: 'g');
        final comment = createTestCommentNode<String>(
          id: 'comment-1',
          data: 'c',
        );
        final controller = createTestController(
          nodes: [regularNode, group, comment],
        );

        controller.removeNode('group-1');

        expect(controller.nodes.length, equals(2));
        expect(controller.nodes.containsKey('regular-1'), isTrue);
        expect(controller.nodes.containsKey('comment-1'), isTrue);
      });
    });

    group('Special Node Behaviors', () {
      test(
        'group node with bounds behavior does not return groupedNodeIds',
        () {
          final group = createTestGroupNode<String>(
            behavior: GroupBehavior.bounds,
            data: 'test',
          );

          expect(group.groupedNodeIds, isEmpty);
        },
      );

      test('group node with explicit behavior returns groupedNodeIds', () {
        final group = GroupNode<String>(
          id: 'explicit-group',
          position: Offset.zero,
          size: const Size(300, 200),
          title: 'Explicit',
          data: 'test',
          behavior: GroupBehavior.explicit,
          nodeIds: {'node-1', 'node-2'},
        );

        expect(group.groupedNodeIds, containsAll(['node-1', 'node-2']));
      });

      test('comment node text can be changed after adding to controller', () {
        final comment = createTestCommentNode<String>(
          id: 'comment-1',
          text: 'Initial',
          data: 'test',
        );
        final controller = createTestController(nodes: [comment]);

        final retrievedComment =
            controller.nodes['comment-1'] as CommentNode<String>;
        retrievedComment.text = 'Updated';

        expect(retrievedComment.text, equals('Updated'));
      });

      test('group node title can be changed after adding to controller', () {
        final group = createTestGroupNode<String>(
          id: 'group-1',
          title: 'Initial',
          data: 'test',
        );
        final controller = createTestController(nodes: [group]);

        final retrievedGroup = controller.nodes['group-1'] as GroupNode<String>;
        retrievedGroup.updateTitle('Updated');

        expect(retrievedGroup.currentTitle, equals('Updated'));
      });
    });
  });

  // ==========================================================================
  // Edge Cases
  // ==========================================================================
  group('Edge Cases', () {
    test('group node at negative coordinates', () {
      final group = GroupNode<String>(
        id: 'negative-group',
        position: const Offset(-200, -100),
        size: const Size(400, 300),
        title: 'Negative',
        data: 'test',
      );

      expect(group.bounds.left, equals(-200));
      expect(group.bounds.top, equals(-100));
    });

    test('comment node with empty text', () {
      final comment = CommentNode<String>(
        id: 'empty-comment',
        position: Offset.zero,
        text: '',
        data: 'test',
      );

      expect(comment.text, isEmpty);
    });

    test('group node with very large size', () {
      final group = GroupNode<String>(
        id: 'large-group',
        position: Offset.zero,
        size: const Size(10000, 8000),
        title: 'Large',
        data: 'test',
      );

      expect(group.currentSize, equals(const Size(10000, 8000)));
    });

    test('group node with many member nodes', () {
      final nodeIds = Set<String>.from(List.generate(100, (i) => 'node-$i'));

      final group = GroupNode<String>(
        id: 'many-nodes-group',
        position: Offset.zero,
        size: const Size(1000, 800),
        title: 'Many Nodes',
        data: 'test',
        behavior: GroupBehavior.explicit,
        nodeIds: nodeIds,
      );

      expect(group.nodeIds.length, equals(100));
    });

    test('comment node with very long text', () {
      final longText = 'A' * 1000;
      final comment = CommentNode<String>(
        id: 'long-text-comment',
        position: Offset.zero,
        text: longText,
        data: 'test',
      );

      expect(comment.text.length, equals(1000));
    });
  });
}
