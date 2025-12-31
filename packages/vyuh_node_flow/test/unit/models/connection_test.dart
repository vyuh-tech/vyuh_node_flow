/// Unit tests for the [Connection] data model.
///
/// Tests cover:
/// - Connection creation with required and optional fields
/// - Observable properties (animated, selected, labels)
/// - Label management (start, center, end)
/// - Control points for editable paths
/// - Node and port involvement queries
/// - JSON serialization
@Tags(['unit'])
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:vyuh_node_flow/vyuh_node_flow.dart';

import '../../helpers/test_factories.dart';
import '../../helpers/test_utils.dart';

void main() {
  setUp(() {
    resetTestCounters();
  });

  group('Connection Creation', () {
    test('creates connection with required fields', () {
      final connection = Connection(
        id: 'conn-1',
        sourceNodeId: 'node-a',
        sourcePortId: 'output-1',
        targetNodeId: 'node-b',
        targetPortId: 'input-1',
      );

      expect(connection.id, equals('conn-1'));
      expect(connection.sourceNodeId, equals('node-a'));
      expect(connection.sourcePortId, equals('output-1'));
      expect(connection.targetNodeId, equals('node-b'));
      expect(connection.targetPortId, equals('input-1'));
    });

    test('creates connection with animated=false by default', () {
      final connection = createTestConnection(
        sourceNodeId: 'node-a',
        targetNodeId: 'node-b',
      );

      expect(connection.animated, isFalse);
    });

    test('creates connection with selected=false by default', () {
      final connection = createTestConnection(
        sourceNodeId: 'node-a',
        targetNodeId: 'node-b',
      );

      expect(connection.selected, isFalse);
    });

    test('creates connection with null data by default', () {
      final connection = createTestConnection(
        sourceNodeId: 'node-a',
        targetNodeId: 'node-b',
      );

      expect(connection.data, isNull);
    });

    test('creates connection with custom data', () {
      final connection = createTestConnection(
        sourceNodeId: 'node-a',
        targetNodeId: 'node-b',
        data: {'key': 'value', 'count': 42},
      );

      expect(connection.data, isNotNull);
      expect(connection.data!['key'], equals('value'));
      expect(connection.data!['count'], equals(42));
    });

    test('creates connection with animated=true', () {
      final connection = Connection(
        id: 'animated-conn',
        sourceNodeId: 'node-a',
        sourcePortId: 'output-1',
        targetNodeId: 'node-b',
        targetPortId: 'input-1',
        animated: true,
      );

      expect(connection.animated, isTrue);
    });

    test('creates connection with empty control points by default', () {
      final connection = createTestConnection(
        sourceNodeId: 'node-a',
        targetNodeId: 'node-b',
      );

      expect(connection.controlPoints, isEmpty);
    });
  });

  group('Observable Properties', () {
    test('animated is observable and updates correctly', () {
      final connection = createTestConnection(
        sourceNodeId: 'node-a',
        targetNodeId: 'node-b',
        animated: false,
      );

      connection.animated = true;

      expect(connection.animated, isTrue);
    });

    test('selected is observable and updates correctly', () {
      final connection = createTestConnection(
        sourceNodeId: 'node-a',
        targetNodeId: 'node-b',
      );

      connection.selected = true;

      expect(connection.selected, isTrue);
    });

    test('startLabel is observable and updates correctly', () {
      final connection = createTestConnection(
        sourceNodeId: 'node-a',
        targetNodeId: 'node-b',
      );

      connection.startLabel = ConnectionLabel.start(text: 'Start');

      expect(connection.startLabel, isNotNull);
      expect(connection.startLabel!.text, equals('Start'));
    });

    test('label (center) is observable and updates correctly', () {
      final connection = createTestConnection(
        sourceNodeId: 'node-a',
        targetNodeId: 'node-b',
      );

      connection.label = ConnectionLabel.center(text: 'Center');

      expect(connection.label, isNotNull);
      expect(connection.label!.text, equals('Center'));
    });

    test('endLabel is observable and updates correctly', () {
      final connection = createTestConnection(
        sourceNodeId: 'node-a',
        targetNodeId: 'node-b',
      );

      connection.endLabel = ConnectionLabel.end(text: 'End');

      expect(connection.endLabel, isNotNull);
      expect(connection.endLabel!.text, equals('End'));
    });

    test('labels can be set to null', () {
      final connection = Connection(
        id: 'conn',
        sourceNodeId: 'node-a',
        sourcePortId: 'output-1',
        targetNodeId: 'node-b',
        targetPortId: 'input-1',
        startLabel: ConnectionLabel.start(text: 'Start'),
        label: ConnectionLabel.center(text: 'Center'),
        endLabel: ConnectionLabel.end(text: 'End'),
      );

      connection.startLabel = null;
      connection.label = null;
      connection.endLabel = null;

      expect(connection.startLabel, isNull);
      expect(connection.label, isNull);
      expect(connection.endLabel, isNull);
    });
  });

  group('Labels Collection', () {
    test('labels returns empty list when no labels set', () {
      final connection = createTestConnection(
        sourceNodeId: 'node-a',
        targetNodeId: 'node-b',
      );

      expect(connection.labels, isEmpty);
    });

    test('labels returns all non-null labels', () {
      final connection = Connection(
        id: 'conn',
        sourceNodeId: 'node-a',
        sourcePortId: 'output-1',
        targetNodeId: 'node-b',
        targetPortId: 'input-1',
        startLabel: ConnectionLabel.start(text: 'Start'),
        label: ConnectionLabel.center(text: 'Center'),
        endLabel: ConnectionLabel.end(text: 'End'),
      );

      final labels = connection.labels;

      expect(labels.length, equals(3));
      expect(labels[0].text, equals('Start'));
      expect(labels[1].text, equals('Center'));
      expect(labels[2].text, equals('End'));
    });

    test('labels returns only set labels', () {
      final connection = Connection(
        id: 'conn',
        sourceNodeId: 'node-a',
        sourcePortId: 'output-1',
        targetNodeId: 'node-b',
        targetPortId: 'input-1',
        label: ConnectionLabel.center(text: 'Center Only'),
      );

      final labels = connection.labels;

      expect(labels.length, equals(1));
      expect(labels[0].text, equals('Center Only'));
    });
  });

  group('Control Points', () {
    test('controlPoints starts empty', () {
      final connection = createTestConnection(
        sourceNodeId: 'node-a',
        targetNodeId: 'node-b',
      );

      expect(connection.controlPoints, isEmpty);
    });

    test('controlPoints can be initialized with values', () {
      final connection = Connection(
        id: 'conn',
        sourceNodeId: 'node-a',
        sourcePortId: 'output-1',
        targetNodeId: 'node-b',
        targetPortId: 'input-1',
        controlPoints: [const Offset(100, 100), const Offset(200, 200)],
      );

      expect(connection.controlPoints.length, equals(2));
      expect(connection.controlPoints[0], equals(const Offset(100, 100)));
      expect(connection.controlPoints[1], equals(const Offset(200, 200)));
    });

    test('controlPoints can be updated via setter', () {
      final connection = createTestConnection(
        sourceNodeId: 'node-a',
        targetNodeId: 'node-b',
      );

      connection.controlPoints = [
        const Offset(50, 50),
        const Offset(150, 150),
        const Offset(250, 250),
      ];

      expect(connection.controlPoints.length, equals(3));
    });

    test('controlPoints is an ObservableList', () {
      final connection = createTestConnection(
        sourceNodeId: 'node-a',
        targetNodeId: 'node-b',
      );

      connection.controlPoints.add(const Offset(100, 100));

      expect(connection.controlPoints.length, equals(1));
    });
  });

  group('Node and Port Involvement', () {
    test('involvesNode returns true for source node', () {
      final connection = createTestConnection(
        sourceNodeId: 'node-a',
        targetNodeId: 'node-b',
      );

      expect(connection.involvesNode('node-a'), isTrue);
    });

    test('involvesNode returns true for target node', () {
      final connection = createTestConnection(
        sourceNodeId: 'node-a',
        targetNodeId: 'node-b',
      );

      expect(connection.involvesNode('node-b'), isTrue);
    });

    test('involvesNode returns false for unrelated node', () {
      final connection = createTestConnection(
        sourceNodeId: 'node-a',
        targetNodeId: 'node-b',
      );

      expect(connection.involvesNode('node-c'), isFalse);
    });

    test('involvesPort returns true for source port', () {
      final connection = Connection(
        id: 'conn',
        sourceNodeId: 'node-a',
        sourcePortId: 'output-1',
        targetNodeId: 'node-b',
        targetPortId: 'input-1',
      );

      expect(connection.involvesPort('node-a', 'output-1'), isTrue);
    });

    test('involvesPort returns true for target port', () {
      final connection = Connection(
        id: 'conn',
        sourceNodeId: 'node-a',
        sourcePortId: 'output-1',
        targetNodeId: 'node-b',
        targetPortId: 'input-1',
      );

      expect(connection.involvesPort('node-b', 'input-1'), isTrue);
    });

    test('involvesPort returns false for wrong node/port combination', () {
      final connection = Connection(
        id: 'conn',
        sourceNodeId: 'node-a',
        sourcePortId: 'output-1',
        targetNodeId: 'node-b',
        targetPortId: 'input-1',
      );

      // Wrong port for the node
      expect(connection.involvesPort('node-a', 'input-1'), isFalse);
      expect(connection.involvesPort('node-b', 'output-1'), isFalse);

      // Wrong node
      expect(connection.involvesPort('node-c', 'output-1'), isFalse);
    });
  });

  group('Effective Style Methods', () {
    test('getEffectiveStyle returns connection style if set', () {
      final connectionStyle = ConnectionStyles.bezier;
      final themeStyle = ConnectionStyles.straight;

      final connection = Connection(
        id: 'conn',
        sourceNodeId: 'node-a',
        sourcePortId: 'output-1',
        targetNodeId: 'node-b',
        targetPortId: 'input-1',
        style: connectionStyle,
      );

      expect(connection.getEffectiveStyle(themeStyle), equals(connectionStyle));
    });

    test(
      'getEffectiveStyle returns theme style if connection style is null',
      () {
        final themeStyle = ConnectionStyles.straight;

        final connection = Connection(
          id: 'conn',
          sourceNodeId: 'node-a',
          sourcePortId: 'output-1',
          targetNodeId: 'node-b',
          targetPortId: 'input-1',
        );

        expect(connection.getEffectiveStyle(themeStyle), equals(themeStyle));
      },
    );
  });

  group('JSON Serialization', () {
    test('toJson produces valid JSON', () {
      final connection = Connection(
        id: 'json-conn',
        sourceNodeId: 'node-a',
        sourcePortId: 'output-1',
        targetNodeId: 'node-b',
        targetPortId: 'input-1',
        data: {'key': 'value'},
      );

      final json = connection.toJson((data) => data);

      expect(json['id'], equals('json-conn'));
      expect(json['sourceNodeId'], equals('node-a'));
      expect(json['sourcePortId'], equals('output-1'));
      expect(json['targetNodeId'], equals('node-b'));
      expect(json['targetPortId'], equals('input-1'));
      expect(json['data'], equals({'key': 'value'}));
    });

    test('fromJson reconstructs connection correctly', () {
      final json = {
        'id': 'reconstructed',
        'sourceNodeId': 'source',
        'sourcePortId': 'out-port',
        'targetNodeId': 'target',
        'targetPortId': 'in-port',
        'data': {'restored': true},
      };

      final connection = Connection<dynamic>.fromJson(json, (json) => json);

      expect(connection.id, equals('reconstructed'));
      expect(connection.sourceNodeId, equals('source'));
      expect(connection.sourcePortId, equals('out-port'));
      expect(connection.targetNodeId, equals('target'));
      expect(connection.targetPortId, equals('in-port'));
      expect(connection.data!['restored'], isTrue);
    });

    test('round-trip serialization preserves all properties', () {
      final original = Connection(
        id: 'round-trip',
        sourceNodeId: 'node-a',
        sourcePortId: 'output-1',
        targetNodeId: 'node-b',
        targetPortId: 'input-1',
        data: {'key': 'value'},
      );

      final restored = roundTripConnectionJson(original);

      expect(restored.id, equals(original.id));
      expect(restored.sourceNodeId, equals(original.sourceNodeId));
      expect(restored.sourcePortId, equals(original.sourcePortId));
      expect(restored.targetNodeId, equals(original.targetNodeId));
      expect(restored.targetPortId, equals(original.targetPortId));
    });

    test('serialization includes labels', () {
      final connection = Connection(
        id: 'conn',
        sourceNodeId: 'node-a',
        sourcePortId: 'output-1',
        targetNodeId: 'node-b',
        targetPortId: 'input-1',
        startLabel: ConnectionLabel.start(text: 'Start'),
        label: ConnectionLabel.center(text: 'Center'),
        endLabel: ConnectionLabel.end(text: 'End'),
      );

      final json = connection.toJson((data) => data);

      expect(json['startLabel'], isNotNull);
      expect(json['label'], isNotNull);
      expect(json['endLabel'], isNotNull);
    });

    test('serialization includes control points', () {
      final connection = Connection(
        id: 'conn',
        sourceNodeId: 'node-a',
        sourcePortId: 'output-1',
        targetNodeId: 'node-b',
        targetPortId: 'input-1',
        controlPoints: [const Offset(100, 100), const Offset(200, 200)],
      );

      final json = connection.toJson((data) => data);

      expect(json['controlPoints'], isNotNull);
      expect((json['controlPoints'] as List).length, equals(2));
    });

    test('fromJson restores control points', () {
      final json = {
        'id': 'conn',
        'sourceNodeId': 'node-a',
        'sourcePortId': 'output-1',
        'targetNodeId': 'node-b',
        'targetPortId': 'input-1',
        'controlPoints': [
          {'dx': 50.0, 'dy': 60.0},
          {'dx': 150.0, 'dy': 160.0},
        ],
      };

      final connection = Connection<dynamic>.fromJson(json, (json) => json);

      expect(connection.controlPoints.length, equals(2));
      expect(connection.controlPoints[0], equals(const Offset(50, 60)));
      expect(connection.controlPoints[1], equals(const Offset(150, 160)));
    });

    test('fromJson restores labels', () {
      final json = {
        'id': 'conn',
        'sourceNodeId': 'node-a',
        'sourcePortId': 'output-1',
        'targetNodeId': 'node-b',
        'targetPortId': 'input-1',
        'startLabel': {'text': 'Start', 'anchor': 0.0},
        'label': {'text': 'Center', 'anchor': 0.5},
        'endLabel': {'text': 'End', 'anchor': 1.0},
      };

      final connection = Connection<dynamic>.fromJson(json, (json) => json);

      expect(connection.startLabel, isNotNull);
      expect(connection.startLabel!.text, equals('Start'));
      expect(connection.label, isNotNull);
      expect(connection.label!.text, equals('Center'));
      expect(connection.endLabel, isNotNull);
      expect(connection.endLabel!.text, equals('End'));
    });
  });

  group('Dispose', () {
    test('dispose can be called without error', () {
      final connection = createTestConnection(
        sourceNodeId: 'node-a',
        targetNodeId: 'node-b',
      );

      // Should not throw
      expect(() => connection.dispose(), returnsNormally);
    });
  });

  group('Edge Cases', () {
    test('connection with same source and target node (self-reference)', () {
      // This tests the data model - validation should happen at controller level
      final connection = Connection(
        id: 'self-conn',
        sourceNodeId: 'node-a',
        sourcePortId: 'output-1',
        targetNodeId: 'node-a',
        targetPortId: 'input-1',
      );

      expect(connection.involvesNode('node-a'), isTrue);
      expect(connection.sourceNodeId, equals(connection.targetNodeId));
    });

    test('connection with empty string IDs', () {
      final connection = Connection(
        id: '',
        sourceNodeId: '',
        sourcePortId: '',
        targetNodeId: '',
        targetPortId: '',
      );

      expect(connection.id, isEmpty);
      expect(connection.sourceNodeId, isEmpty);
    });

    test('connection with very long IDs', () {
      final longId = 'a' * 1000;
      final connection = Connection(
        id: longId,
        sourceNodeId: longId,
        sourcePortId: longId,
        targetNodeId: longId,
        targetPortId: longId,
      );

      expect(connection.id.length, equals(1000));
    });

    test('connection with special characters in IDs', () {
      final connection = Connection(
        id: 'conn-@#\$%^&*()',
        sourceNodeId: 'node-123',
        sourcePortId: 'port_with_underscore',
        targetNodeId: 'node.with.dots',
        targetPortId: 'port:with:colons',
      );

      expect(connection.id, contains('@'));
    });
  });
}
