/// Unit tests for TemporaryConnection.
///
/// Tests cover:
/// - Constructor and initialization
/// - Immutable property access
/// - Observable property getters and setters
/// - Observable access
/// - Equality and hashCode
@Tags(['unit'])
library;

import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:vyuh_node_flow/src/connections/temporary_connection.dart';

void main() {
  // ===========================================================================
  // Constructor Tests
  // ===========================================================================

  group('TemporaryConnection - Constructor', () {
    test('constructor sets all immutable properties', () {
      final connection = TemporaryConnection(
        startPoint: const Offset(100, 100),
        startNodeId: 'node-1',
        startPortId: 'port-1',
        isStartFromOutput: true,
        startNodeBounds: const Rect.fromLTWH(0, 0, 200, 100),
        initialCurrentPoint: const Offset(150, 150),
      );

      expect(connection.startPoint, equals(const Offset(100, 100)));
      expect(connection.startNodeId, equals('node-1'));
      expect(connection.startPortId, equals('port-1'));
      expect(connection.isStartFromOutput, isTrue);
      expect(
        connection.startNodeBounds,
        equals(const Rect.fromLTWH(0, 0, 200, 100)),
      );
    });

    test('constructor initializes currentPoint with initial value', () {
      final connection = TemporaryConnection(
        startPoint: const Offset(100, 100),
        startNodeId: 'node-1',
        startPortId: 'port-1',
        isStartFromOutput: true,
        startNodeBounds: const Rect.fromLTWH(0, 0, 200, 100),
        initialCurrentPoint: const Offset(150, 150),
      );

      expect(connection.currentPoint, equals(const Offset(150, 150)));
    });

    test('constructor sets optional target values when provided', () {
      final connection = TemporaryConnection(
        startPoint: const Offset(100, 100),
        startNodeId: 'node-1',
        startPortId: 'port-1',
        isStartFromOutput: true,
        startNodeBounds: const Rect.fromLTWH(0, 0, 200, 100),
        initialCurrentPoint: const Offset(150, 150),
        targetNodeId: 'node-2',
        targetPortId: 'port-2',
        targetNodeBounds: const Rect.fromLTWH(300, 0, 200, 100),
      );

      expect(connection.targetNodeId, equals('node-2'));
      expect(connection.targetPortId, equals('port-2'));
      expect(
        connection.targetNodeBounds,
        equals(const Rect.fromLTWH(300, 0, 200, 100)),
      );
    });

    test('constructor initializes target values to null by default', () {
      final connection = TemporaryConnection(
        startPoint: const Offset(100, 100),
        startNodeId: 'node-1',
        startPortId: 'port-1',
        isStartFromOutput: true,
        startNodeBounds: const Rect.fromLTWH(0, 0, 200, 100),
        initialCurrentPoint: const Offset(150, 150),
      );

      expect(connection.targetNodeId, isNull);
      expect(connection.targetPortId, isNull);
      expect(connection.targetNodeBounds, isNull);
    });

    test('constructor with isStartFromOutput false', () {
      final connection = TemporaryConnection(
        startPoint: const Offset(100, 100),
        startNodeId: 'node-1',
        startPortId: 'port-1',
        isStartFromOutput: false,
        startNodeBounds: const Rect.fromLTWH(0, 0, 200, 100),
        initialCurrentPoint: const Offset(150, 150),
      );

      expect(connection.isStartFromOutput, isFalse);
    });
  });

  // ===========================================================================
  // Observable Property Tests
  // ===========================================================================

  group('TemporaryConnection - Observable Properties', () {
    test('currentPoint setter updates value', () {
      final connection = TemporaryConnection(
        startPoint: const Offset(100, 100),
        startNodeId: 'node-1',
        startPortId: 'port-1',
        isStartFromOutput: true,
        startNodeBounds: const Rect.fromLTWH(0, 0, 200, 100),
        initialCurrentPoint: const Offset(150, 150),
      );

      connection.currentPoint = const Offset(200, 200);

      expect(connection.currentPoint, equals(const Offset(200, 200)));
    });

    test('targetNodeId setter updates value', () {
      final connection = TemporaryConnection(
        startPoint: const Offset(100, 100),
        startNodeId: 'node-1',
        startPortId: 'port-1',
        isStartFromOutput: true,
        startNodeBounds: const Rect.fromLTWH(0, 0, 200, 100),
        initialCurrentPoint: const Offset(150, 150),
      );

      connection.targetNodeId = 'node-2';

      expect(connection.targetNodeId, equals('node-2'));
    });

    test('targetPortId setter updates value', () {
      final connection = TemporaryConnection(
        startPoint: const Offset(100, 100),
        startNodeId: 'node-1',
        startPortId: 'port-1',
        isStartFromOutput: true,
        startNodeBounds: const Rect.fromLTWH(0, 0, 200, 100),
        initialCurrentPoint: const Offset(150, 150),
      );

      connection.targetPortId = 'port-2';

      expect(connection.targetPortId, equals('port-2'));
    });

    test('targetNodeBounds setter updates value', () {
      final connection = TemporaryConnection(
        startPoint: const Offset(100, 100),
        startNodeId: 'node-1',
        startPortId: 'port-1',
        isStartFromOutput: true,
        startNodeBounds: const Rect.fromLTWH(0, 0, 200, 100),
        initialCurrentPoint: const Offset(150, 150),
      );

      connection.targetNodeBounds = const Rect.fromLTWH(300, 0, 200, 100);

      expect(
        connection.targetNodeBounds,
        equals(const Rect.fromLTWH(300, 0, 200, 100)),
      );
    });

    test('setters can set values to null', () {
      final connection = TemporaryConnection(
        startPoint: const Offset(100, 100),
        startNodeId: 'node-1',
        startPortId: 'port-1',
        isStartFromOutput: true,
        startNodeBounds: const Rect.fromLTWH(0, 0, 200, 100),
        initialCurrentPoint: const Offset(150, 150),
        targetNodeId: 'node-2',
        targetPortId: 'port-2',
        targetNodeBounds: const Rect.fromLTWH(300, 0, 200, 100),
      );

      connection.targetNodeId = null;
      connection.targetPortId = null;
      connection.targetNodeBounds = null;

      expect(connection.targetNodeId, isNull);
      expect(connection.targetPortId, isNull);
      expect(connection.targetNodeBounds, isNull);
    });
  });

  // ===========================================================================
  // Observable Access Tests
  // ===========================================================================

  group('TemporaryConnection - Observable Access', () {
    test('currentPointObservable provides MobX observable', () {
      final connection = TemporaryConnection(
        startPoint: const Offset(100, 100),
        startNodeId: 'node-1',
        startPortId: 'port-1',
        isStartFromOutput: true,
        startNodeBounds: const Rect.fromLTWH(0, 0, 200, 100),
        initialCurrentPoint: const Offset(150, 150),
      );

      final observable = connection.currentPointObservable;

      expect(observable, isNotNull);
      expect(observable.value, equals(const Offset(150, 150)));
    });

    test('targetNodeIdObservable provides MobX observable', () {
      final connection = TemporaryConnection(
        startPoint: const Offset(100, 100),
        startNodeId: 'node-1',
        startPortId: 'port-1',
        isStartFromOutput: true,
        startNodeBounds: const Rect.fromLTWH(0, 0, 200, 100),
        initialCurrentPoint: const Offset(150, 150),
        targetNodeId: 'node-2',
      );

      final observable = connection.targetNodeIdObservable;

      expect(observable, isNotNull);
      expect(observable.value, equals('node-2'));
    });

    test('targetPortIdObservable provides MobX observable', () {
      final connection = TemporaryConnection(
        startPoint: const Offset(100, 100),
        startNodeId: 'node-1',
        startPortId: 'port-1',
        isStartFromOutput: true,
        startNodeBounds: const Rect.fromLTWH(0, 0, 200, 100),
        initialCurrentPoint: const Offset(150, 150),
        targetPortId: 'port-2',
      );

      final observable = connection.targetPortIdObservable;

      expect(observable, isNotNull);
      expect(observable.value, equals('port-2'));
    });

    test('targetNodeBoundsObservable provides MobX observable', () {
      final connection = TemporaryConnection(
        startPoint: const Offset(100, 100),
        startNodeId: 'node-1',
        startPortId: 'port-1',
        isStartFromOutput: true,
        startNodeBounds: const Rect.fromLTWH(0, 0, 200, 100),
        initialCurrentPoint: const Offset(150, 150),
        targetNodeBounds: const Rect.fromLTWH(300, 0, 200, 100),
      );

      final observable = connection.targetNodeBoundsObservable;

      expect(observable, isNotNull);
      expect(observable.value, equals(const Rect.fromLTWH(300, 0, 200, 100)));
    });

    test('observable values sync with property setters', () {
      final connection = TemporaryConnection(
        startPoint: const Offset(100, 100),
        startNodeId: 'node-1',
        startPortId: 'port-1',
        isStartFromOutput: true,
        startNodeBounds: const Rect.fromLTWH(0, 0, 200, 100),
        initialCurrentPoint: const Offset(150, 150),
      );

      connection.currentPoint = const Offset(300, 300);
      expect(
        connection.currentPointObservable.value,
        equals(const Offset(300, 300)),
      );

      connection.targetNodeId = 'new-node';
      expect(connection.targetNodeIdObservable.value, equals('new-node'));
    });
  });

  // ===========================================================================
  // Equality Tests
  // ===========================================================================

  group('TemporaryConnection - Equality', () {
    test('equal connections have same properties', () {
      final connection1 = TemporaryConnection(
        startPoint: const Offset(100, 100),
        startNodeId: 'node-1',
        startPortId: 'port-1',
        isStartFromOutput: true,
        startNodeBounds: const Rect.fromLTWH(0, 0, 200, 100),
        initialCurrentPoint: const Offset(150, 150),
      );

      final connection2 = TemporaryConnection(
        startPoint: const Offset(100, 100),
        startNodeId: 'node-1',
        startPortId: 'port-1',
        isStartFromOutput: true,
        startNodeBounds: const Rect.fromLTWH(0, 0, 200, 100),
        initialCurrentPoint: const Offset(150, 150),
      );

      expect(connection1, equals(connection2));
    });

    test('different startPoint makes connections unequal', () {
      final connection1 = TemporaryConnection(
        startPoint: const Offset(100, 100),
        startNodeId: 'node-1',
        startPortId: 'port-1',
        isStartFromOutput: true,
        startNodeBounds: const Rect.fromLTWH(0, 0, 200, 100),
        initialCurrentPoint: const Offset(150, 150),
      );

      final connection2 = TemporaryConnection(
        startPoint: const Offset(200, 200),
        startNodeId: 'node-1',
        startPortId: 'port-1',
        isStartFromOutput: true,
        startNodeBounds: const Rect.fromLTWH(0, 0, 200, 100),
        initialCurrentPoint: const Offset(150, 150),
      );

      expect(connection1, isNot(equals(connection2)));
    });

    test('different startNodeId makes connections unequal', () {
      final connection1 = TemporaryConnection(
        startPoint: const Offset(100, 100),
        startNodeId: 'node-1',
        startPortId: 'port-1',
        isStartFromOutput: true,
        startNodeBounds: const Rect.fromLTWH(0, 0, 200, 100),
        initialCurrentPoint: const Offset(150, 150),
      );

      final connection2 = TemporaryConnection(
        startPoint: const Offset(100, 100),
        startNodeId: 'node-2',
        startPortId: 'port-1',
        isStartFromOutput: true,
        startNodeBounds: const Rect.fromLTWH(0, 0, 200, 100),
        initialCurrentPoint: const Offset(150, 150),
      );

      expect(connection1, isNot(equals(connection2)));
    });

    test('different currentPoint makes connections unequal', () {
      final connection1 = TemporaryConnection(
        startPoint: const Offset(100, 100),
        startNodeId: 'node-1',
        startPortId: 'port-1',
        isStartFromOutput: true,
        startNodeBounds: const Rect.fromLTWH(0, 0, 200, 100),
        initialCurrentPoint: const Offset(150, 150),
      );

      final connection2 = TemporaryConnection(
        startPoint: const Offset(100, 100),
        startNodeId: 'node-1',
        startPortId: 'port-1',
        isStartFromOutput: true,
        startNodeBounds: const Rect.fromLTWH(0, 0, 200, 100),
        initialCurrentPoint: const Offset(200, 200),
      );

      expect(connection1, isNot(equals(connection2)));
    });

    test('same instance equals itself', () {
      final connection = TemporaryConnection(
        startPoint: const Offset(100, 100),
        startNodeId: 'node-1',
        startPortId: 'port-1',
        isStartFromOutput: true,
        startNodeBounds: const Rect.fromLTWH(0, 0, 200, 100),
        initialCurrentPoint: const Offset(150, 150),
      );

      expect(connection, equals(connection));
    });

    test('not equal to different type', () {
      final connection = TemporaryConnection(
        startPoint: const Offset(100, 100),
        startNodeId: 'node-1',
        startPortId: 'port-1',
        isStartFromOutput: true,
        startNodeBounds: const Rect.fromLTWH(0, 0, 200, 100),
        initialCurrentPoint: const Offset(150, 150),
      );

      expect(connection, isNot(equals('not a connection')));
      expect(connection, isNot(equals(null)));
    });
  });

  // ===========================================================================
  // HashCode Tests
  // ===========================================================================

  group('TemporaryConnection - HashCode', () {
    test('equal connections have same hashCode', () {
      final connection1 = TemporaryConnection(
        startPoint: const Offset(100, 100),
        startNodeId: 'node-1',
        startPortId: 'port-1',
        isStartFromOutput: true,
        startNodeBounds: const Rect.fromLTWH(0, 0, 200, 100),
        initialCurrentPoint: const Offset(150, 150),
      );

      final connection2 = TemporaryConnection(
        startPoint: const Offset(100, 100),
        startNodeId: 'node-1',
        startPortId: 'port-1',
        isStartFromOutput: true,
        startNodeBounds: const Rect.fromLTWH(0, 0, 200, 100),
        initialCurrentPoint: const Offset(150, 150),
      );

      expect(connection1.hashCode, equals(connection2.hashCode));
    });

    test('hashCode changes with currentPoint', () {
      final connection = TemporaryConnection(
        startPoint: const Offset(100, 100),
        startNodeId: 'node-1',
        startPortId: 'port-1',
        isStartFromOutput: true,
        startNodeBounds: const Rect.fromLTWH(0, 0, 200, 100),
        initialCurrentPoint: const Offset(150, 150),
      );

      final hashCode1 = connection.hashCode;

      connection.currentPoint = const Offset(300, 300);
      final hashCode2 = connection.hashCode;

      expect(hashCode1, isNot(equals(hashCode2)));
    });

    test('hashCode changes with target values', () {
      final connection = TemporaryConnection(
        startPoint: const Offset(100, 100),
        startNodeId: 'node-1',
        startPortId: 'port-1',
        isStartFromOutput: true,
        startNodeBounds: const Rect.fromLTWH(0, 0, 200, 100),
        initialCurrentPoint: const Offset(150, 150),
      );

      final hashCode1 = connection.hashCode;

      connection.targetNodeId = 'node-2';
      final hashCode2 = connection.hashCode;

      expect(hashCode1, isNot(equals(hashCode2)));
    });
  });

  // ===========================================================================
  // Usage Scenario Tests
  // ===========================================================================

  group('TemporaryConnection - Usage Scenarios', () {
    test('simulates dragging from output port', () {
      // Start dragging from output port
      final connection = TemporaryConnection(
        startPoint: const Offset(200, 50),
        startNodeId: 'source-node',
        startPortId: 'output-port',
        isStartFromOutput: true,
        startNodeBounds: const Rect.fromLTWH(0, 0, 200, 100),
        initialCurrentPoint: const Offset(200, 50),
      );

      // Move pointer
      connection.currentPoint = const Offset(300, 100);
      connection.currentPoint = const Offset(400, 150);

      // Hover over target
      connection.targetNodeId = 'target-node';
      connection.targetPortId = 'input-port';
      connection.targetNodeBounds = const Rect.fromLTWH(400, 100, 200, 100);

      expect(connection.isStartFromOutput, isTrue);
      expect(connection.targetNodeId, equals('target-node'));
      expect(connection.targetPortId, equals('input-port'));
    });

    test('simulates dragging from input port', () {
      // Start dragging from input port
      final connection = TemporaryConnection(
        startPoint: const Offset(0, 50),
        startNodeId: 'target-node',
        startPortId: 'input-port',
        isStartFromOutput: false,
        startNodeBounds: const Rect.fromLTWH(0, 0, 200, 100),
        initialCurrentPoint: const Offset(0, 50),
      );

      // Move pointer backward to find source
      connection.currentPoint = const Offset(-100, 50);
      connection.currentPoint = const Offset(-200, 50);

      expect(connection.isStartFromOutput, isFalse);
    });

    test('simulates cancelling drag', () {
      final connection = TemporaryConnection(
        startPoint: const Offset(200, 50),
        startNodeId: 'source-node',
        startPortId: 'output-port',
        isStartFromOutput: true,
        startNodeBounds: const Rect.fromLTWH(0, 0, 200, 100),
        initialCurrentPoint: const Offset(200, 50),
      );

      // Move and set target
      connection.currentPoint = const Offset(400, 150);
      connection.targetNodeId = 'target-node';
      connection.targetPortId = 'input-port';

      // Move away from target
      connection.targetNodeId = null;
      connection.targetPortId = null;
      connection.targetNodeBounds = null;

      // Target should be cleared
      expect(connection.targetNodeId, isNull);
      expect(connection.targetPortId, isNull);
      expect(connection.targetNodeBounds, isNull);
    });
  });
}
