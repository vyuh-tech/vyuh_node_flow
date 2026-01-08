/// Unit tests for node data handling in vyuh_node_flow.
///
/// Tests cover:
/// - Node data generic type handling with various types
/// - Node metadata (type, layer, locked, selectable)
/// - Node type checking (isResizable, type guards)
/// - Data serialization patterns for different data types
@Tags(['unit'])
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vyuh_node_flow/vyuh_node_flow.dart';

import '../../helpers/test_factories.dart';
import '../../helpers/test_utils.dart';

// =============================================================================
// Custom Data Types for Testing
// =============================================================================

/// Simple class for testing complex data types.
class PersonData implements NodeData {
  final String name;
  final int age;
  final List<String> tags;

  PersonData({required this.name, required this.age, this.tags = const []});

  @override
  PersonData clone() => PersonData(name: name, age: age, tags: List.from(tags));

  Map<String, dynamic> toJson() => {'name': name, 'age': age, 'tags': tags};

  factory PersonData.fromJson(Map<String, dynamic> json) => PersonData(
    name: json['name'] as String,
    age: json['age'] as int,
    tags: (json['tags'] as List<dynamic>?)?.cast<String>() ?? [],
  );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PersonData &&
          runtimeType == other.runtimeType &&
          name == other.name &&
          age == other.age;

  @override
  int get hashCode => name.hashCode ^ age.hashCode;
}

/// Immutable value class for testing.
class ConfigData implements NodeData {
  final String key;
  final dynamic value;
  final bool required;

  const ConfigData({
    required this.key,
    required this.value,
    this.required = false,
  });

  @override
  ConfigData clone() => ConfigData(key: key, value: value, required: required);

  Map<String, dynamic> toJson() => {
    'key': key,
    'value': value,
    'required': required,
  };

  factory ConfigData.fromJson(Map<String, dynamic> json) => ConfigData(
    key: json['key'] as String,
    value: json['value'],
    required: json['required'] as bool? ?? false,
  );
}

/// Nested data structure for testing complex serialization.
class WorkflowStepData implements NodeData {
  final String stepId;
  final String action;
  final Map<String, dynamic> parameters;
  final List<String> dependsOn;

  WorkflowStepData({
    required this.stepId,
    required this.action,
    this.parameters = const {},
    this.dependsOn = const [],
  });

  @override
  WorkflowStepData clone() => WorkflowStepData(
    stepId: stepId,
    action: action,
    parameters: Map.from(parameters),
    dependsOn: List.from(dependsOn),
  );

  Map<String, dynamic> toJson() => {
    'stepId': stepId,
    'action': action,
    'parameters': parameters,
    'dependsOn': dependsOn,
  };

  factory WorkflowStepData.fromJson(Map<String, dynamic> json) =>
      WorkflowStepData(
        stepId: json['stepId'] as String,
        action: json['action'] as String,
        parameters: Map<String, dynamic>.from(json['parameters'] as Map? ?? {}),
        dependsOn: (json['dependsOn'] as List<dynamic>?)?.cast<String>() ?? [],
      );
}

void main() {
  setUp(() {
    resetTestCounters();
  });

  // ===========================================================================
  // Node Data Generic Type Handling
  // ===========================================================================
  group('Node Data Generic Type Handling', () {
    group('Primitive Types', () {
      test('node with String data', () {
        final node = Node<String>(
          id: 'string-node',
          type: 'test',
          position: Offset.zero,
          data: 'Hello, World!',
        );

        expect(node.data, equals('Hello, World!'));
        expect(node.data, isA<String>());
      });

      test('node with int data', () {
        final node = Node<int>(
          id: 'int-node',
          type: 'test',
          position: Offset.zero,
          data: 42,
        );

        expect(node.data, equals(42));
        expect(node.data, isA<int>());
      });

      test('node with double data', () {
        final node = Node<double>(
          id: 'double-node',
          type: 'test',
          position: Offset.zero,
          data: 3.14159,
        );

        expect(node.data, closeTo(3.14159, 0.0001));
        expect(node.data, isA<double>());
      });

      test('node with bool data', () {
        final node = Node<bool>(
          id: 'bool-node',
          type: 'test',
          position: Offset.zero,
          data: true,
        );

        expect(node.data, isTrue);
        expect(node.data, isA<bool>());
      });
    });

    group('Collection Types', () {
      test('node with List data', () {
        final listData = ['item1', 'item2', 'item3'];
        final node = Node<List<String>>(
          id: 'list-node',
          type: 'test',
          position: Offset.zero,
          data: listData,
        );

        expect(node.data, equals(listData));
        expect(node.data.length, equals(3));
        expect(node.data, isA<List<String>>());
      });

      test('node with Map data', () {
        final mapData = {'key1': 'value1', 'key2': 'value2'};
        final node = Node<Map<String, String>>(
          id: 'map-node',
          type: 'test',
          position: Offset.zero,
          data: mapData,
        );

        expect(node.data, equals(mapData));
        expect(node.data['key1'], equals('value1'));
        expect(node.data, isA<Map<String, String>>());
      });

      test('node with Set data', () {
        final setData = {'a', 'b', 'c'};
        final node = Node<Set<String>>(
          id: 'set-node',
          type: 'test',
          position: Offset.zero,
          data: setData,
        );

        expect(node.data, equals(setData));
        expect(node.data.contains('a'), isTrue);
        expect(node.data, isA<Set<String>>());
      });
    });

    group('Custom Object Types', () {
      test('node with PersonData', () {
        final personData = PersonData(name: 'Alice', age: 30, tags: ['admin']);
        final node = Node<PersonData>(
          id: 'person-node',
          type: 'test',
          position: Offset.zero,
          data: personData,
        );

        expect(node.data.name, equals('Alice'));
        expect(node.data.age, equals(30));
        expect(node.data.tags, contains('admin'));
        expect(node.data, isA<PersonData>());
      });

      test('node with ConfigData', () {
        final configData = ConfigData(
          key: 'timeout',
          value: 30,
          required: true,
        );
        final node = Node<ConfigData>(
          id: 'config-node',
          type: 'test',
          position: Offset.zero,
          data: configData,
        );

        expect(node.data.key, equals('timeout'));
        expect(node.data.value, equals(30));
        expect(node.data.required, isTrue);
        expect(node.data, isA<ConfigData>());
      });

      test('node with WorkflowStepData', () {
        final stepData = WorkflowStepData(
          stepId: 'step-1',
          action: 'process',
          parameters: {'input': 'data', 'format': 'json'},
          dependsOn: ['step-0'],
        );
        final node = Node<WorkflowStepData>(
          id: 'step-node',
          type: 'test',
          position: Offset.zero,
          data: stepData,
        );

        expect(node.data.stepId, equals('step-1'));
        expect(node.data.action, equals('process'));
        expect(node.data.parameters['input'], equals('data'));
        expect(node.data.dependsOn, contains('step-0'));
      });
    });

    group('Nullable Types', () {
      test('node with nullable data containing value', () {
        final node = Node<String?>(
          id: 'nullable-node',
          type: 'test',
          position: Offset.zero,
          data: 'not null',
        );

        expect(node.data, isNotNull);
        expect(node.data, equals('not null'));
      });

      test('node with nullable data containing null', () {
        final node = Node<String?>(
          id: 'null-node',
          type: 'test',
          position: Offset.zero,
          data: null,
        );

        expect(node.data, isNull);
      });
    });

    group('Data Immutability', () {
      test('node data is final and cannot be reassigned', () {
        final node = Node<String>(
          id: 'immutable-node',
          type: 'test',
          position: Offset.zero,
          data: 'original',
        );

        // The data field is final, so it cannot be reassigned
        // This test verifies the data can be accessed consistently
        expect(node.data, equals('original'));
        expect(node.data, equals(node.data)); // Consistent access
      });

      test('mutable data objects can be modified through reference', () {
        final listData = ['item1'];
        final node = Node<List<String>>(
          id: 'mutable-data-node',
          type: 'test',
          position: Offset.zero,
          data: listData,
        );

        // Modifying through the original reference
        listData.add('item2');

        // Node data reflects the change (same reference)
        expect(node.data.length, equals(2));
        expect(node.data, contains('item2'));
      });

      test('NodeData clone creates independent copy', () {
        final original = PersonData(name: 'Bob', age: 25, tags: ['user']);
        final cloned = original.clone();

        expect(cloned.name, equals(original.name));
        expect(cloned.age, equals(original.age));
        expect(cloned.tags, equals(original.tags));

        // Verify they are different instances
        expect(identical(cloned, original), isFalse);
        expect(identical(cloned.tags, original.tags), isFalse);
      });
    });
  });

  // ===========================================================================
  // Node Metadata
  // ===========================================================================
  group('Node Metadata', () {
    group('Node Type', () {
      test('regular node has custom type', () {
        final node = createTestNode(type: 'processor');
        expect(node.type, equals('processor'));
      });

      test('different node types can coexist', () {
        final inputNode = createTestNode(id: 'input', type: 'input');
        final outputNode = createTestNode(id: 'output', type: 'output');
        final processorNode = createTestNode(id: 'proc', type: 'processor');

        expect(inputNode.type, equals('input'));
        expect(outputNode.type, equals('output'));
        expect(processorNode.type, equals('processor'));
      });

      test('GroupNode has type "group"', () {
        final group = createTestGroupNode<String>(data: 'test');
        expect(group.type, equals('group'));
      });

      test('CommentNode has type "comment"', () {
        final comment = createTestCommentNode<String>(data: 'test');
        expect(comment.type, equals('comment'));
      });
    });

    group('Node Layer', () {
      test('regular node is in middle layer by default', () {
        final node = createTestNode();
        expect(node.layer, equals(NodeRenderLayer.middle));
      });

      test('GroupNode is in background layer', () {
        final group = createTestGroupNode<String>(data: 'test');
        expect(group.layer, equals(NodeRenderLayer.background));
      });

      test('CommentNode is in foreground layer', () {
        final comment = createTestCommentNode<String>(data: 'test');
        expect(comment.layer, equals(NodeRenderLayer.foreground));
      });

      test('node layers are ordered correctly', () {
        expect(
          NodeRenderLayer.background.index,
          lessThan(NodeRenderLayer.middle.index),
        );
        expect(
          NodeRenderLayer.middle.index,
          lessThan(NodeRenderLayer.foreground.index),
        );
      });
    });

    group('Node Locked State', () {
      test('node is unlocked by default', () {
        final node = createTestNode();
        expect(node.locked, isFalse);
      });

      test('node can be created locked', () {
        final node = Node<String>(
          id: 'locked-node',
          type: 'test',
          position: Offset.zero,
          data: 'test',
          locked: true,
        );

        expect(node.locked, isTrue);
      });

      test('GroupNode can be created locked', () {
        final group = createTestGroupNode<String>(data: 'test', locked: true);
        expect(group.locked, isTrue);
      });

      test('CommentNode can be created locked', () {
        final comment = createTestCommentNode<String>(
          data: 'test',
          locked: true,
        );
        expect(comment.locked, isTrue);
      });
    });

    group('Node Selectable State', () {
      test('regular node is selectable by default', () {
        final node = createTestNode();
        expect(node.selectable, isTrue);
      });

      test('node can be created non-selectable', () {
        final node = Node<String>(
          id: 'non-selectable',
          type: 'test',
          position: Offset.zero,
          data: 'test',
          selectable: false,
        );

        expect(node.selectable, isFalse);
      });

      test('GroupNode is selectable by default', () {
        final group = createTestGroupNode<String>(data: 'test');
        expect(group.selectable, isTrue);
      });

      test('CommentNode is selectable by default', () {
        final comment = createTestCommentNode<String>(data: 'test');
        expect(comment.selectable, isTrue);
      });
    });

    group('Node ID Uniqueness', () {
      test('nodes can have custom IDs', () {
        final node = createTestNode(id: 'custom-id-123');
        expect(node.id, equals('custom-id-123'));
      });

      test('factory generates unique IDs', () {
        final node1 = createTestNode();
        final node2 = createTestNode();
        final node3 = createTestNode();

        expect(node1.id, isNot(equals(node2.id)));
        expect(node2.id, isNot(equals(node3.id)));
        expect(node1.id, isNot(equals(node3.id)));
      });
    });
  });

  // ===========================================================================
  // Node Type Checking
  // ===========================================================================
  group('Node Type Checking', () {
    group('isResizable', () {
      test('regular node is not resizable', () {
        final node = createTestNode();
        expect(node.isResizable, isFalse);
      });

      test('GroupNode with bounds behavior is resizable', () {
        final group = createTestGroupNode<String>(
          behavior: GroupBehavior.bounds,
          data: 'test',
        );
        expect(group.isResizable, isTrue);
      });

      test('GroupNode with explicit behavior is not resizable', () {
        final group = createTestGroupNode<String>(
          behavior: GroupBehavior.explicit,
          data: 'test',
        );
        expect(group.isResizable, isFalse);
      });

      test('GroupNode with parent behavior is resizable', () {
        final group = createTestGroupNode<String>(
          behavior: GroupBehavior.parent,
          data: 'test',
        );
        expect(group.isResizable, isTrue);
      });

      test('CommentNode is resizable', () {
        final comment = createTestCommentNode<String>(data: 'test');
        expect(comment.isResizable, isTrue);
      });
    });

    group('Type Guards', () {
      test('can check if node is GroupNode', () {
        final Node<String> regularNode = createTestNode();
        final Node<String> groupNode = createTestGroupNode<String>(
          data: 'test',
        );

        expect(regularNode, isNot(isA<GroupNode>()));
        expect(groupNode, isA<GroupNode>());
        expect(groupNode, isA<GroupNode<String>>());
      });

      test('can check if node is CommentNode', () {
        final Node<String> regularNode = createTestNode();
        final Node<String> commentNode = createTestCommentNode<String>(
          data: 'test',
        );

        expect(regularNode, isNot(isA<CommentNode>()));
        expect(commentNode, isA<CommentNode>());
        expect(commentNode, isA<CommentNode<String>>());
      });

      test('can cast node to specific type', () {
        final Node<String> node = createTestGroupNode<String>(data: 'test');

        if (node is GroupNode<String>) {
          expect(node.currentTitle, isNotEmpty);
          expect(node.behavior, isNotNull);
        } else {
          fail('Node should be castable to GroupNode<String>');
        }
      });

      test('nodes with different generic types are different types', () {
        final Node<String> stringNode = Node<String>(
          id: 'string',
          type: 'test',
          position: Offset.zero,
          data: 'test',
        );
        final Node<int> intNode = Node<int>(
          id: 'int',
          type: 'test',
          position: Offset.zero,
          data: 42,
        );

        expect(stringNode, isA<Node<String>>());
        expect(intNode, isA<Node<int>>());
        expect(stringNode, isNot(isA<Node<int>>()));
        expect(intNode, isNot(isA<Node<String>>()));
      });
    });

    group('GroupNode Specific Checks', () {
      test('isGroupable depends on behavior', () {
        final boundsGroup = createTestGroupNode<String>(
          behavior: GroupBehavior.bounds,
          data: 'test',
        );
        final explicitGroup = createTestGroupNode<String>(
          behavior: GroupBehavior.explicit,
          data: 'test',
        );
        final parentGroup = createTestGroupNode<String>(
          behavior: GroupBehavior.parent,
          data: 'test',
        );

        expect(boundsGroup.isGroupable, isFalse);
        expect(explicitGroup.isGroupable, isTrue);
        expect(parentGroup.isGroupable, isTrue);
      });

      test('isEmpty depends on behavior and node membership', () {
        final emptyExplicitGroup = GroupNode<String>(
          id: 'empty',
          position: Offset.zero,
          size: const Size(200, 150),
          title: 'Empty',
          data: 'test',
          behavior: GroupBehavior.explicit,
        );

        final boundsGroup = createTestGroupNode<String>(
          behavior: GroupBehavior.bounds,
          data: 'test',
        );

        expect(emptyExplicitGroup.isEmpty, isTrue);
        expect(boundsGroup.isEmpty, isFalse); // bounds is never "empty"
      });

      test('shouldRemoveWhenEmpty is true only for explicit behavior', () {
        final explicitGroup = createTestGroupNode<String>(
          behavior: GroupBehavior.explicit,
          data: 'test',
        );
        final boundsGroup = createTestGroupNode<String>(
          behavior: GroupBehavior.bounds,
          data: 'test',
        );
        final parentGroup = createTestGroupNode<String>(
          behavior: GroupBehavior.parent,
          data: 'test',
        );

        expect(explicitGroup.shouldRemoveWhenEmpty, isTrue);
        expect(boundsGroup.shouldRemoveWhenEmpty, isFalse);
        expect(parentGroup.shouldRemoveWhenEmpty, isFalse);
      });
    });
  });

  // ===========================================================================
  // Data Serialization Patterns
  // ===========================================================================
  group('Data Serialization Patterns', () {
    group('String Data Serialization', () {
      test('toJson serializes string data correctly', () {
        final node = createTestNode(id: 'string-node', data: 'test-data');

        final json = node.toJson((data) => data);

        expect(json['data'], equals('test-data'));
        expect(json['id'], equals('string-node'));
      });

      test('fromJson deserializes string data correctly', () {
        final json = {
          'id': 'restored',
          'type': 'test',
          'x': 0.0,
          'y': 0.0,
          'data': 'restored-data',
        };

        final node = Node<String>.fromJson(json, (data) => data as String);

        expect(node.data, equals('restored-data'));
      });

      test('round-trip serialization preserves string data', () {
        final original = createTestNode(data: 'round-trip-test');
        final restored = roundTripNodeJson(original);

        expect(restored.data, equals(original.data));
      });
    });

    group('Complex Data Serialization', () {
      test('toJson serializes custom object data', () {
        final personData = PersonData(name: 'Alice', age: 30);
        final node = Node<PersonData>(
          id: 'person-node',
          type: 'person',
          position: const Offset(100, 100),
          data: personData,
        );

        final json = node.toJson((data) => data.toJson());

        expect(json['data'], isA<Map<String, dynamic>>());
        expect(json['data']['name'], equals('Alice'));
        expect(json['data']['age'], equals(30));
      });

      test('fromJson deserializes custom object data', () {
        final json = {
          'id': 'person-node',
          'type': 'person',
          'x': 100.0,
          'y': 100.0,
          'data': {
            'name': 'Bob',
            'age': 25,
            'tags': ['admin', 'user'],
          },
        };

        final node = Node<PersonData>.fromJson(
          json,
          (data) => PersonData.fromJson(data as Map<String, dynamic>),
        );

        expect(node.data.name, equals('Bob'));
        expect(node.data.age, equals(25));
        expect(node.data.tags, containsAll(['admin', 'user']));
      });

      test('round-trip serialization preserves complex data', () {
        final personData = PersonData(
          name: 'Charlie',
          age: 35,
          tags: ['developer', 'admin'],
        );
        final original = Node<PersonData>(
          id: 'person-node',
          type: 'person',
          position: const Offset(50, 75),
          data: personData,
        );

        final json = original.toJson((data) => data.toJson());
        final restored = Node<PersonData>.fromJson(
          json,
          (data) => PersonData.fromJson(data as Map<String, dynamic>),
        );

        expect(restored.data.name, equals(personData.name));
        expect(restored.data.age, equals(personData.age));
        expect(restored.data.tags, equals(personData.tags));
      });
    });

    group('Nested Data Serialization', () {
      test('serializes deeply nested data structures', () {
        final stepData = WorkflowStepData(
          stepId: 'step-1',
          action: 'transform',
          parameters: {
            'input': {'source': 'file', 'path': '/data/input.json'},
            'transform': ['filter', 'map', 'reduce'],
            'options': {'parallel': true, 'timeout': 30},
          },
          dependsOn: ['init', 'validate'],
        );
        final node = Node<WorkflowStepData>(
          id: 'workflow-step',
          type: 'step',
          position: Offset.zero,
          data: stepData,
        );

        final json = node.toJson((data) => data.toJson());

        expect(json['data']['stepId'], equals('step-1'));
        expect(json['data']['parameters']['input']['source'], equals('file'));
        expect(json['data']['parameters']['transform'], hasLength(3));
      });

      test('deserializes deeply nested data structures', () {
        final json = {
          'id': 'step',
          'type': 'step',
          'x': 0.0,
          'y': 0.0,
          'data': {
            'stepId': 'step-2',
            'action': 'output',
            'parameters': {
              'format': 'csv',
              'columns': ['id', 'name', 'value'],
            },
            'dependsOn': ['step-1'],
          },
        };

        final node = Node<WorkflowStepData>.fromJson(
          json,
          (data) => WorkflowStepData.fromJson(data as Map<String, dynamic>),
        );

        expect(node.data.stepId, equals('step-2'));
        expect(node.data.parameters['format'], equals('csv'));
        expect(node.data.parameters['columns'], hasLength(3));
        expect(node.data.dependsOn, contains('step-1'));
      });
    });

    group('GroupNode Data Serialization', () {
      test('GroupNode toJson includes group-specific fields', () {
        final group = GroupNode<String>(
          id: 'group-1',
          position: const Offset(100, 200),
          size: const Size(400, 300),
          title: 'Test Group',
          data: 'group-data',
          color: Colors.red,
          behavior: GroupBehavior.explicit,
          nodeIds: {'node-1', 'node-2'},
        );

        final json = group.toJson((data) => data);

        expect(json['title'], equals('Test Group'));
        expect(json['behavior'], equals('explicit'));
        expect(json['nodeIds'], containsAll(['node-1', 'node-2']));
        expect(json['color'], isNotNull);
        expect(json['data'], equals('group-data'));
      });

      test('GroupNode fromJson restores all fields', () {
        final json = {
          'id': 'restored-group',
          'x': 100.0,
          'y': 200.0,
          'width': 400.0,
          'height': 300.0,
          'title': 'Restored Group',
          'data': 'restored-data',
          'color': Colors.blue.toARGB32(),
          'behavior': 'parent',
          'nodeIds': ['child-1', 'child-2'],
        };

        final group = GroupNode<String>.fromJson(
          json,
          dataFromJson: (data) => data as String,
        );

        expect(group.id, equals('restored-group'));
        expect(group.currentTitle, equals('Restored Group'));
        expect(group.data, equals('restored-data'));
        expect(group.behavior, equals(GroupBehavior.parent));
        expect(group.nodeIds, containsAll(['child-1', 'child-2']));
      });

      test('GroupNode with complex data round-trips correctly', () {
        final original = GroupNode<PersonData>(
          id: 'person-group',
          position: const Offset(50, 50),
          size: const Size(500, 400),
          title: 'People',
          data: PersonData(name: 'Group Owner', age: 40),
          behavior: GroupBehavior.explicit,
          nodeIds: {'person-1', 'person-2'},
        );

        final json = original.toJson((data) => data.toJson());
        final restored = GroupNode<PersonData>.fromJson(
          json,
          dataFromJson: (data) =>
              PersonData.fromJson(data as Map<String, dynamic>),
        );

        expect(restored.data.name, equals('Group Owner'));
        expect(restored.data.age, equals(40));
        expect(restored.currentTitle, equals('People'));
        expect(restored.nodeIds, containsAll(['person-1', 'person-2']));
      });
    });

    group('CommentNode Data Serialization', () {
      test('CommentNode toJson includes comment-specific fields', () {
        final comment = CommentNode<String>(
          id: 'comment-1',
          position: const Offset(50, 75),
          text: 'This is a note',
          data: 'comment-data',
          width: 250,
          height: 150,
          color: Colors.yellow,
        );

        final json = comment.toJson((data) => data);

        expect(json['text'], equals('This is a note'));
        expect(json['width'], equals(250.0));
        expect(json['height'], equals(150.0));
        expect(json['data'], equals('comment-data'));
      });

      test('CommentNode fromJson restores all fields', () {
        final json = {
          'id': 'restored-comment',
          'x': 100.0,
          'y': 150.0,
          'width': 300.0,
          'height': 200.0,
          'text': 'Restored note',
          'data': 'restored-data',
          'color': Colors.pink.toARGB32(),
        };

        final comment = CommentNode<String>.fromJson(
          json,
          dataFromJson: (data) => data as String,
        );

        expect(comment.id, equals('restored-comment'));
        expect(comment.text, equals('Restored note'));
        expect(comment.data, equals('restored-data'));
        expect(comment.width, equals(300.0));
        expect(comment.height, equals(200.0));
      });

      test('CommentNode with complex data round-trips correctly', () {
        final original = CommentNode<ConfigData>(
          id: 'config-comment',
          position: const Offset(200, 200),
          text: 'Configuration note',
          data: ConfigData(key: 'api_key', value: 'secret', required: true),
          width: 220,
          height: 130,
        );

        final json = original.toJson((data) => data.toJson());
        final restored = CommentNode<ConfigData>.fromJson(
          json,
          dataFromJson: (data) =>
              ConfigData.fromJson(data as Map<String, dynamic>),
        );

        expect(restored.data.key, equals('api_key'));
        expect(restored.data.value, equals('secret'));
        expect(restored.data.required, isTrue);
        expect(restored.text, equals('Configuration note'));
      });
    });

    group('Serialization Edge Cases', () {
      test('handles null data in serialization', () {
        final node = Node<String?>(
          id: 'nullable-node',
          type: 'test',
          position: Offset.zero,
          data: null,
        );

        final json = node.toJson((data) => data);
        expect(json['data'], isNull);

        final restored = Node<String?>.fromJson(
          json,
          (data) => data as String?,
        );
        expect(restored.data, isNull);
      });

      test('handles empty string data', () {
        final node = createTestNode(data: '');
        final restored = roundTripNodeJson(node);
        expect(restored.data, isEmpty);
      });

      test('handles special characters in string data', () {
        final specialString = 'Line1\nLine2\tTabbed "Quoted" \'Single\'';
        final node = createTestNode(data: specialString);
        final restored = roundTripNodeJson(node);
        expect(restored.data, equals(specialString));
      });

      test('handles unicode in string data', () {
        final unicodeString = 'Hello World';
        final node = createTestNode(data: unicodeString);
        final restored = roundTripNodeJson(node);
        expect(restored.data, equals(unicodeString));
      });

      test('handles very long string data', () {
        final longString = 'A' * 10000;
        final node = createTestNode(data: longString);
        final restored = roundTripNodeJson(node);
        expect(restored.data.length, equals(10000));
      });

      test('fromJson handles missing optional fields gracefully', () {
        final minimalJson = {'id': 'minimal', 'type': 'test', 'data': 'data'};

        final node = Node<String>.fromJson(
          minimalJson,
          (data) => data as String,
        );

        expect(node.id, equals('minimal'));
        expect(node.position.value, equals(Offset.zero));
        expect(node.currentZIndex, equals(0));
        expect(node.isVisible, isTrue);
      });
    });
  });

  // ===========================================================================
  // Integration Tests
  // ===========================================================================
  group('Data Handling Integration', () {
    test('controller preserves node data types correctly', () {
      final stringNode = createTestNode(id: 'string', data: 'string-data');
      final controller = createTestController(nodes: [stringNode]);

      final retrieved = controller.nodes['string'];
      expect(retrieved, isNotNull);
      expect(retrieved!.data, equals('string-data'));
      expect(retrieved.data, isA<String>());
    });

    test('controller handles mixed data types', () {
      // Using dynamic to allow mixed types in the same controller
      final controller = NodeFlowController<dynamic, dynamic>();

      // Add nodes with different data types
      final node1 = Node<String>(
        id: 'node-1',
        type: 'string',
        position: Offset.zero,
        data: 'string-data',
      );
      final node2 = Node<int>(
        id: 'node-2',
        type: 'int',
        position: const Offset(100, 0),
        data: 42,
      );

      controller.addNode(node1);
      controller.addNode(node2);

      expect(controller.nodes['node-1']?.data, equals('string-data'));
      expect(controller.nodes['node-2']?.data, equals(42));
    });

    test('copyWith preserves data correctly for GroupNode', () {
      final original = GroupNode<PersonData>(
        id: 'original',
        position: const Offset(100, 100),
        size: const Size(400, 300),
        title: 'Original',
        data: PersonData(name: 'Original', age: 25),
      );

      final copy = original.copyWith(title: 'Copy');

      expect(copy.data.name, equals(original.data.name));
      expect(copy.data.age, equals(original.data.age));
      expect(copy.currentTitle, equals('Copy'));
    });

    test('copyWith preserves data correctly for CommentNode', () {
      final original = CommentNode<ConfigData>(
        id: 'original',
        position: const Offset(50, 50),
        text: 'Original text',
        data: ConfigData(key: 'key', value: 'value'),
      );

      final copy = original.copyWith(text: 'Copy text');

      expect(copy.data.key, equals(original.data.key));
      expect(copy.data.value, equals(original.data.value));
      expect(copy.text, equals('Copy text'));
    });
  });
}
