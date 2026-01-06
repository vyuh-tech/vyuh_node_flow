/// Unit tests for the [SpatialItem] class hierarchy and related types.
///
/// Tests cover:
/// - SpatialItem sealed class hierarchy (NodeSpatialItem, PortSpatialItem, ConnectionSegmentItem)
/// - Construction and property access
/// - ID generation patterns
/// - Bounds calculations
/// - copyWithBounds functionality
/// - Equality and hashCode
/// - Factory extensions (SpatialItemFactories)
/// - Type checking extensions (SpatialItemTypeChecks)
/// - Pattern matching exhaustiveness
@Tags(['unit'])
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vyuh_node_flow/src/shared/spatial/spatial_grid.dart';
import 'package:vyuh_node_flow/src/shared/spatial/spatial_item.dart';

import '../../helpers/test_factories.dart';

void main() {
  setUp(() {
    resetTestCounters();
  });

  group('NodeSpatialItem', () {
    group('Construction', () {
      test('creates with required nodeId and bounds', () {
        const bounds = Rect.fromLTWH(100, 200, 150, 100);
        const item = NodeSpatialItem(nodeId: 'node-1', bounds: bounds);

        expect(item.nodeId, equals('node-1'));
        expect(item.bounds, equals(bounds));
      });

      test('creates with zero bounds', () {
        const item = NodeSpatialItem(nodeId: 'node-1', bounds: Rect.zero);

        expect(item.bounds, equals(Rect.zero));
      });

      test('creates with negative position bounds', () {
        const bounds = Rect.fromLTWH(-100, -200, 150, 100);
        const item = NodeSpatialItem(nodeId: 'node-1', bounds: bounds);

        expect(item.bounds.left, equals(-100));
        expect(item.bounds.top, equals(-200));
      });

      test('creates with large bounds', () {
        const bounds = Rect.fromLTWH(10000, 10000, 5000, 3000);
        const item = NodeSpatialItem(nodeId: 'node-1', bounds: bounds);

        expect(item.bounds, equals(bounds));
      });
    });

    group('ID Generation', () {
      test('id uses node_ prefix', () {
        const item = NodeSpatialItem(nodeId: 'my-node', bounds: Rect.zero);

        expect(item.id, equals('node_my-node'));
      });

      test('referenceId returns original nodeId', () {
        const item = NodeSpatialItem(nodeId: 'my-node', bounds: Rect.zero);

        expect(item.referenceId, equals('my-node'));
      });

      test('id is unique for different nodeIds', () {
        const item1 = NodeSpatialItem(nodeId: 'node-1', bounds: Rect.zero);
        const item2 = NodeSpatialItem(nodeId: 'node-2', bounds: Rect.zero);

        expect(item1.id, isNot(equals(item2.id)));
      });

      test('id handles special characters in nodeId', () {
        const item = NodeSpatialItem(
          nodeId: 'node:with:colons',
          bounds: Rect.zero,
        );

        expect(item.id, equals('node_node:with:colons'));
      });
    });

    group('Bounds Access', () {
      test('getBounds returns the same as bounds property', () {
        const bounds = Rect.fromLTWH(50, 75, 200, 150);
        const item = NodeSpatialItem(nodeId: 'node-1', bounds: bounds);

        expect(item.getBounds(), equals(item.bounds));
        expect(item.getBounds(), equals(bounds));
      });
    });

    group('copyWithBounds', () {
      test('creates new item with updated bounds', () {
        const originalBounds = Rect.fromLTWH(0, 0, 100, 100);
        const newBounds = Rect.fromLTWH(50, 50, 200, 150);
        const item = NodeSpatialItem(nodeId: 'node-1', bounds: originalBounds);

        final updated = item.copyWithBounds(newBounds);

        expect(updated.bounds, equals(newBounds));
        expect(updated.nodeId, equals('node-1'));
        expect(updated.id, equals(item.id));
      });

      test('does not modify original item', () {
        const originalBounds = Rect.fromLTWH(0, 0, 100, 100);
        const newBounds = Rect.fromLTWH(50, 50, 200, 150);
        const item = NodeSpatialItem(nodeId: 'node-1', bounds: originalBounds);

        item.copyWithBounds(newBounds);

        expect(item.bounds, equals(originalBounds));
      });

      test('returns NodeSpatialItem type', () {
        const item = NodeSpatialItem(nodeId: 'node-1', bounds: Rect.zero);

        final updated = item.copyWithBounds(
          const Rect.fromLTWH(10, 10, 50, 50),
        );

        expect(updated, isA<NodeSpatialItem>());
      });
    });

    group('Equality', () {
      test('equal when nodeId is same', () {
        const item1 = NodeSpatialItem(
          nodeId: 'node-1',
          bounds: Rect.fromLTWH(0, 0, 100, 100),
        );
        const item2 = NodeSpatialItem(
          nodeId: 'node-1',
          bounds: Rect.fromLTWH(50, 50, 200, 200),
        );

        expect(item1, equals(item2));
      });

      test('not equal when nodeId differs', () {
        const item1 = NodeSpatialItem(
          nodeId: 'node-1',
          bounds: Rect.fromLTWH(0, 0, 100, 100),
        );
        const item2 = NodeSpatialItem(
          nodeId: 'node-2',
          bounds: Rect.fromLTWH(0, 0, 100, 100),
        );

        expect(item1, isNot(equals(item2)));
      });

      test('hashCode consistent with equality', () {
        const item1 = NodeSpatialItem(nodeId: 'node-1', bounds: Rect.zero);
        const item2 = NodeSpatialItem(
          nodeId: 'node-1',
          bounds: Rect.fromLTWH(100, 100, 50, 50),
        );

        expect(item1.hashCode, equals(item2.hashCode));
      });

      test('can be used in Set', () {
        const item1 = NodeSpatialItem(nodeId: 'node-1', bounds: Rect.zero);
        const item2 = NodeSpatialItem(
          nodeId: 'node-1',
          bounds: Rect.fromLTWH(100, 100, 50, 50),
        );
        const item3 = NodeSpatialItem(nodeId: 'node-2', bounds: Rect.zero);

        final set = {item1, item2, item3};

        expect(set.length, equals(2));
      });
    });

    group('toString', () {
      test('includes nodeId and bounds', () {
        const bounds = Rect.fromLTWH(10, 20, 100, 50);
        const item = NodeSpatialItem(nodeId: 'my-node', bounds: bounds);

        final str = item.toString();

        expect(str, contains('my-node'));
        expect(str, contains('NodeSpatialItem'));
      });
    });
  });

  group('PortSpatialItem', () {
    group('Construction', () {
      test('creates with all required fields', () {
        const bounds = Rect.fromLTWH(95, 45, 20, 20);
        const item = PortSpatialItem(
          portId: 'port-1',
          nodeId: 'node-1',
          isOutput: true,
          bounds: bounds,
        );

        expect(item.portId, equals('port-1'));
        expect(item.nodeId, equals('node-1'));
        expect(item.isOutput, isTrue);
        expect(item.bounds, equals(bounds));
      });

      test('creates input port (isOutput=false)', () {
        const item = PortSpatialItem(
          portId: 'input-port',
          nodeId: 'node-1',
          isOutput: false,
          bounds: Rect.zero,
        );

        expect(item.isOutput, isFalse);
      });

      test('creates output port (isOutput=true)', () {
        const item = PortSpatialItem(
          portId: 'output-port',
          nodeId: 'node-1',
          isOutput: true,
          bounds: Rect.zero,
        );

        expect(item.isOutput, isTrue);
      });
    });

    group('ID Generation', () {
      test('id uses port_ prefix with nodeId and portId', () {
        const item = PortSpatialItem(
          portId: 'my-port',
          nodeId: 'my-node',
          isOutput: true,
          bounds: Rect.zero,
        );

        expect(item.id, equals('port_my-node_my-port'));
      });

      test('referenceId returns portId', () {
        const item = PortSpatialItem(
          portId: 'my-port',
          nodeId: 'my-node',
          isOutput: true,
          bounds: Rect.zero,
        );

        expect(item.referenceId, equals('my-port'));
      });

      test('id is unique for different ports on same node', () {
        const item1 = PortSpatialItem(
          portId: 'port-1',
          nodeId: 'node-1',
          isOutput: true,
          bounds: Rect.zero,
        );
        const item2 = PortSpatialItem(
          portId: 'port-2',
          nodeId: 'node-1',
          isOutput: false,
          bounds: Rect.zero,
        );

        expect(item1.id, isNot(equals(item2.id)));
      });

      test('id is unique for same port on different nodes', () {
        const item1 = PortSpatialItem(
          portId: 'port-1',
          nodeId: 'node-1',
          isOutput: true,
          bounds: Rect.zero,
        );
        const item2 = PortSpatialItem(
          portId: 'port-1',
          nodeId: 'node-2',
          isOutput: true,
          bounds: Rect.zero,
        );

        expect(item1.id, isNot(equals(item2.id)));
      });
    });

    group('Bounds Access', () {
      test('getBounds returns bounds property', () {
        const bounds = Rect.fromLTWH(10, 20, 15, 15);
        const item = PortSpatialItem(
          portId: 'port-1',
          nodeId: 'node-1',
          isOutput: true,
          bounds: bounds,
        );

        expect(item.getBounds(), equals(bounds));
      });
    });

    group('copyWithBounds', () {
      test('creates new item with updated bounds', () {
        const originalBounds = Rect.fromLTWH(0, 0, 20, 20);
        const newBounds = Rect.fromLTWH(100, 100, 25, 25);
        const item = PortSpatialItem(
          portId: 'port-1',
          nodeId: 'node-1',
          isOutput: true,
          bounds: originalBounds,
        );

        final updated = item.copyWithBounds(newBounds);

        expect(updated.bounds, equals(newBounds));
        expect(updated.portId, equals('port-1'));
        expect(updated.nodeId, equals('node-1'));
        expect(updated.isOutput, isTrue);
      });

      test('preserves isOutput value', () {
        const item = PortSpatialItem(
          portId: 'port-1',
          nodeId: 'node-1',
          isOutput: false,
          bounds: Rect.zero,
        );

        final updated = item.copyWithBounds(
          const Rect.fromLTWH(10, 10, 20, 20),
        );

        expect(updated.isOutput, isFalse);
      });

      test('returns PortSpatialItem type', () {
        const item = PortSpatialItem(
          portId: 'port-1',
          nodeId: 'node-1',
          isOutput: true,
          bounds: Rect.zero,
        );

        final updated = item.copyWithBounds(
          const Rect.fromLTWH(10, 10, 20, 20),
        );

        expect(updated, isA<PortSpatialItem>());
      });
    });

    group('Equality', () {
      test('equal when portId and nodeId match', () {
        const item1 = PortSpatialItem(
          portId: 'port-1',
          nodeId: 'node-1',
          isOutput: true,
          bounds: Rect.fromLTWH(0, 0, 20, 20),
        );
        const item2 = PortSpatialItem(
          portId: 'port-1',
          nodeId: 'node-1',
          isOutput: false, // Different isOutput
          bounds: Rect.fromLTWH(100, 100, 30, 30), // Different bounds
        );

        expect(item1, equals(item2));
      });

      test('not equal when portId differs', () {
        const item1 = PortSpatialItem(
          portId: 'port-1',
          nodeId: 'node-1',
          isOutput: true,
          bounds: Rect.zero,
        );
        const item2 = PortSpatialItem(
          portId: 'port-2',
          nodeId: 'node-1',
          isOutput: true,
          bounds: Rect.zero,
        );

        expect(item1, isNot(equals(item2)));
      });

      test('not equal when nodeId differs', () {
        const item1 = PortSpatialItem(
          portId: 'port-1',
          nodeId: 'node-1',
          isOutput: true,
          bounds: Rect.zero,
        );
        const item2 = PortSpatialItem(
          portId: 'port-1',
          nodeId: 'node-2',
          isOutput: true,
          bounds: Rect.zero,
        );

        expect(item1, isNot(equals(item2)));
      });

      test('hashCode consistent with equality', () {
        const item1 = PortSpatialItem(
          portId: 'port-1',
          nodeId: 'node-1',
          isOutput: true,
          bounds: Rect.zero,
        );
        const item2 = PortSpatialItem(
          portId: 'port-1',
          nodeId: 'node-1',
          isOutput: false,
          bounds: Rect.fromLTWH(50, 50, 10, 10),
        );

        expect(item1.hashCode, equals(item2.hashCode));
      });

      test('can be used in Set', () {
        const item1 = PortSpatialItem(
          portId: 'port-1',
          nodeId: 'node-1',
          isOutput: true,
          bounds: Rect.zero,
        );
        const item2 = PortSpatialItem(
          portId: 'port-1',
          nodeId: 'node-1',
          isOutput: false,
          bounds: Rect.fromLTWH(10, 10, 20, 20),
        );
        const item3 = PortSpatialItem(
          portId: 'port-2',
          nodeId: 'node-1',
          isOutput: true,
          bounds: Rect.zero,
        );

        final set = {item1, item2, item3};

        expect(set.length, equals(2));
      });
    });

    group('toString', () {
      test('includes portId, nodeId, and bounds', () {
        const bounds = Rect.fromLTWH(10, 20, 15, 15);
        const item = PortSpatialItem(
          portId: 'my-port',
          nodeId: 'my-node',
          isOutput: true,
          bounds: bounds,
        );

        final str = item.toString();

        expect(str, contains('my-port'));
        expect(str, contains('my-node'));
        expect(str, contains('PortSpatialItem'));
      });
    });
  });

  group('ConnectionSegmentItem', () {
    group('Construction', () {
      test('creates with all required fields', () {
        const bounds = Rect.fromLTWH(100, 100, 200, 50);
        const item = ConnectionSegmentItem(
          connectionId: 'conn-1',
          segmentIndex: 0,
          bounds: bounds,
        );

        expect(item.connectionId, equals('conn-1'));
        expect(item.segmentIndex, equals(0));
        expect(item.bounds, equals(bounds));
      });

      test('creates with different segment indices', () {
        const item0 = ConnectionSegmentItem(
          connectionId: 'conn-1',
          segmentIndex: 0,
          bounds: Rect.zero,
        );
        const item1 = ConnectionSegmentItem(
          connectionId: 'conn-1',
          segmentIndex: 1,
          bounds: Rect.zero,
        );
        const item5 = ConnectionSegmentItem(
          connectionId: 'conn-1',
          segmentIndex: 5,
          bounds: Rect.zero,
        );

        expect(item0.segmentIndex, equals(0));
        expect(item1.segmentIndex, equals(1));
        expect(item5.segmentIndex, equals(5));
      });
    });

    group('ID Generation', () {
      test('id uses conn_ prefix with connectionId and segment index', () {
        const item = ConnectionSegmentItem(
          connectionId: 'my-connection',
          segmentIndex: 3,
          bounds: Rect.zero,
        );

        expect(item.id, equals('conn_my-connection_seg_3'));
      });

      test('referenceId returns connectionId', () {
        const item = ConnectionSegmentItem(
          connectionId: 'my-connection',
          segmentIndex: 0,
          bounds: Rect.zero,
        );

        expect(item.referenceId, equals('my-connection'));
      });

      test('id is unique for different segments of same connection', () {
        const item1 = ConnectionSegmentItem(
          connectionId: 'conn-1',
          segmentIndex: 0,
          bounds: Rect.zero,
        );
        const item2 = ConnectionSegmentItem(
          connectionId: 'conn-1',
          segmentIndex: 1,
          bounds: Rect.zero,
        );

        expect(item1.id, isNot(equals(item2.id)));
      });

      test('id is unique for different connections', () {
        const item1 = ConnectionSegmentItem(
          connectionId: 'conn-1',
          segmentIndex: 0,
          bounds: Rect.zero,
        );
        const item2 = ConnectionSegmentItem(
          connectionId: 'conn-2',
          segmentIndex: 0,
          bounds: Rect.zero,
        );

        expect(item1.id, isNot(equals(item2.id)));
      });
    });

    group('Bounds Access', () {
      test('getBounds returns bounds property', () {
        const bounds = Rect.fromLTWH(50, 100, 300, 20);
        const item = ConnectionSegmentItem(
          connectionId: 'conn-1',
          segmentIndex: 0,
          bounds: bounds,
        );

        expect(item.getBounds(), equals(bounds));
      });
    });

    group('copyWithBounds', () {
      test('creates new item with updated bounds', () {
        const originalBounds = Rect.fromLTWH(0, 0, 100, 20);
        const newBounds = Rect.fromLTWH(50, 50, 200, 30);
        const item = ConnectionSegmentItem(
          connectionId: 'conn-1',
          segmentIndex: 2,
          bounds: originalBounds,
        );

        final updated = item.copyWithBounds(newBounds);

        expect(updated.bounds, equals(newBounds));
        expect(updated.connectionId, equals('conn-1'));
        expect(updated.segmentIndex, equals(2));
      });

      test('preserves segmentIndex', () {
        const item = ConnectionSegmentItem(
          connectionId: 'conn-1',
          segmentIndex: 5,
          bounds: Rect.zero,
        );

        final updated = item.copyWithBounds(
          const Rect.fromLTWH(10, 10, 50, 10),
        );

        expect(updated.segmentIndex, equals(5));
      });

      test('returns ConnectionSegmentItem type', () {
        const item = ConnectionSegmentItem(
          connectionId: 'conn-1',
          segmentIndex: 0,
          bounds: Rect.zero,
        );

        final updated = item.copyWithBounds(
          const Rect.fromLTWH(10, 10, 50, 10),
        );

        expect(updated, isA<ConnectionSegmentItem>());
      });
    });

    group('Equality', () {
      test('equal when connectionId and segmentIndex match', () {
        const item1 = ConnectionSegmentItem(
          connectionId: 'conn-1',
          segmentIndex: 2,
          bounds: Rect.fromLTWH(0, 0, 100, 20),
        );
        const item2 = ConnectionSegmentItem(
          connectionId: 'conn-1',
          segmentIndex: 2,
          bounds: Rect.fromLTWH(50, 50, 200, 30), // Different bounds
        );

        expect(item1, equals(item2));
      });

      test('not equal when connectionId differs', () {
        const item1 = ConnectionSegmentItem(
          connectionId: 'conn-1',
          segmentIndex: 0,
          bounds: Rect.zero,
        );
        const item2 = ConnectionSegmentItem(
          connectionId: 'conn-2',
          segmentIndex: 0,
          bounds: Rect.zero,
        );

        expect(item1, isNot(equals(item2)));
      });

      test('not equal when segmentIndex differs', () {
        const item1 = ConnectionSegmentItem(
          connectionId: 'conn-1',
          segmentIndex: 0,
          bounds: Rect.zero,
        );
        const item2 = ConnectionSegmentItem(
          connectionId: 'conn-1',
          segmentIndex: 1,
          bounds: Rect.zero,
        );

        expect(item1, isNot(equals(item2)));
      });

      test('hashCode consistent with equality', () {
        const item1 = ConnectionSegmentItem(
          connectionId: 'conn-1',
          segmentIndex: 3,
          bounds: Rect.zero,
        );
        const item2 = ConnectionSegmentItem(
          connectionId: 'conn-1',
          segmentIndex: 3,
          bounds: Rect.fromLTWH(100, 100, 50, 10),
        );

        expect(item1.hashCode, equals(item2.hashCode));
      });

      test('can be used in Set', () {
        const item1 = ConnectionSegmentItem(
          connectionId: 'conn-1',
          segmentIndex: 0,
          bounds: Rect.zero,
        );
        const item2 = ConnectionSegmentItem(
          connectionId: 'conn-1',
          segmentIndex: 0,
          bounds: Rect.fromLTWH(10, 10, 20, 5),
        );
        const item3 = ConnectionSegmentItem(
          connectionId: 'conn-1',
          segmentIndex: 1,
          bounds: Rect.zero,
        );

        final set = {item1, item2, item3};

        expect(set.length, equals(2));
      });
    });

    group('toString', () {
      test('includes connectionId, segmentIndex, and bounds', () {
        const bounds = Rect.fromLTWH(10, 20, 100, 15);
        const item = ConnectionSegmentItem(
          connectionId: 'my-conn',
          segmentIndex: 2,
          bounds: bounds,
        );

        final str = item.toString();

        expect(str, contains('my-conn'));
        expect(str, contains('2'));
        expect(str, contains('ConnectionSegmentItem'));
      });
    });
  });

  group('SpatialItemFactories', () {
    test('node factory creates NodeSpatialItem', () {
      const bounds = Rect.fromLTWH(100, 200, 150, 100);
      final item = SpatialItemFactories.node(
        nodeId: 'factory-node',
        bounds: bounds,
      );

      expect(item, isA<NodeSpatialItem>());
      expect(item.nodeId, equals('factory-node'));
      expect(item.bounds, equals(bounds));
    });

    test('port factory creates PortSpatialItem', () {
      const bounds = Rect.fromLTWH(95, 45, 20, 20);
      final item = SpatialItemFactories.port(
        portId: 'factory-port',
        nodeId: 'factory-node',
        isOutput: true,
        bounds: bounds,
      );

      expect(item, isA<PortSpatialItem>());
      expect(item.portId, equals('factory-port'));
      expect(item.nodeId, equals('factory-node'));
      expect(item.isOutput, isTrue);
      expect(item.bounds, equals(bounds));
    });

    test('connectionSegment factory creates ConnectionSegmentItem', () {
      const bounds = Rect.fromLTWH(100, 100, 200, 50);
      final item = SpatialItemFactories.connectionSegment(
        connectionId: 'factory-conn',
        segmentIndex: 3,
        bounds: bounds,
      );

      expect(item, isA<ConnectionSegmentItem>());
      expect(item.connectionId, equals('factory-conn'));
      expect(item.segmentIndex, equals(3));
      expect(item.bounds, equals(bounds));
    });
  });

  group('SpatialItemTypeChecks', () {
    test('isNode returns true for NodeSpatialItem', () {
      const SpatialItem item = NodeSpatialItem(
        nodeId: 'node-1',
        bounds: Rect.zero,
      );

      expect(item.isNode, isTrue);
      expect(item.isPort, isFalse);
      expect(item.isConnectionSegment, isFalse);
    });

    test('isPort returns true for PortSpatialItem', () {
      const SpatialItem item = PortSpatialItem(
        portId: 'port-1',
        nodeId: 'node-1',
        isOutput: true,
        bounds: Rect.zero,
      );

      expect(item.isNode, isFalse);
      expect(item.isPort, isTrue);
      expect(item.isConnectionSegment, isFalse);
    });

    test('isConnectionSegment returns true for ConnectionSegmentItem', () {
      const SpatialItem item = ConnectionSegmentItem(
        connectionId: 'conn-1',
        segmentIndex: 0,
        bounds: Rect.zero,
      );

      expect(item.isNode, isFalse);
      expect(item.isPort, isFalse);
      expect(item.isConnectionSegment, isTrue);
    });
  });

  group('Pattern Matching', () {
    test('exhaustive pattern matching works with sealed class', () {
      const List<SpatialItem> items = [
        NodeSpatialItem(nodeId: 'node-1', bounds: Rect.zero),
        PortSpatialItem(
          portId: 'port-1',
          nodeId: 'node-1',
          isOutput: true,
          bounds: Rect.zero,
        ),
        ConnectionSegmentItem(
          connectionId: 'conn-1',
          segmentIndex: 0,
          bounds: Rect.zero,
        ),
      ];

      final results = items.map((item) {
        return switch (item) {
          NodeSpatialItem(:final nodeId) => 'Node: $nodeId',
          PortSpatialItem(:final portId, :final nodeId) =>
            'Port: $portId on $nodeId',
          ConnectionSegmentItem(:final connectionId, :final segmentIndex) =>
            'Connection: $connectionId[$segmentIndex]',
        };
      }).toList();

      expect(results[0], equals('Node: node-1'));
      expect(results[1], equals('Port: port-1 on node-1'));
      expect(results[2], equals('Connection: conn-1[0]'));
    });

    test('pattern matching extracts all fields correctly', () {
      const item = PortSpatialItem(
        portId: 'test-port',
        nodeId: 'test-node',
        isOutput: false,
        bounds: Rect.fromLTWH(10, 20, 30, 40),
      );

      final result = switch (item) {
        PortSpatialItem(
          :final portId,
          :final nodeId,
          :final isOutput,
          :final bounds,
        ) =>
          'Port $portId on $nodeId, output=$isOutput, bounds=$bounds',
      };

      expect(result, contains('test-port'));
      expect(result, contains('test-node'));
      expect(result, contains('output=false'));
    });
  });

  group('SpatialIndexable Interface', () {
    test('NodeSpatialItem implements SpatialIndexable', () {
      const item = NodeSpatialItem(nodeId: 'node-1', bounds: Rect.zero);

      expect(item, isA<SpatialIndexable>());
      expect(item.id, isNotEmpty);
      expect(item.getBounds(), isA<Rect>());
    });

    test('PortSpatialItem implements SpatialIndexable', () {
      const item = PortSpatialItem(
        portId: 'port-1',
        nodeId: 'node-1',
        isOutput: true,
        bounds: Rect.zero,
      );

      expect(item, isA<SpatialIndexable>());
      expect(item.id, isNotEmpty);
      expect(item.getBounds(), isA<Rect>());
    });

    test('ConnectionSegmentItem implements SpatialIndexable', () {
      const item = ConnectionSegmentItem(
        connectionId: 'conn-1',
        segmentIndex: 0,
        bounds: Rect.zero,
      );

      expect(item, isA<SpatialIndexable>());
      expect(item.id, isNotEmpty);
      expect(item.getBounds(), isA<Rect>());
    });
  });

  group('Edge Cases', () {
    test('handles empty string IDs', () {
      const nodeItem = NodeSpatialItem(nodeId: '', bounds: Rect.zero);
      const portItem = PortSpatialItem(
        portId: '',
        nodeId: '',
        isOutput: true,
        bounds: Rect.zero,
      );
      const connItem = ConnectionSegmentItem(
        connectionId: '',
        segmentIndex: 0,
        bounds: Rect.zero,
      );

      expect(nodeItem.id, equals('node_'));
      expect(portItem.id, equals('port__'));
      expect(connItem.id, equals('conn__seg_0'));
    });

    test('handles very long IDs', () {
      final longId = 'a' * 1000;
      final nodeItem = NodeSpatialItem(nodeId: longId, bounds: Rect.zero);

      expect(nodeItem.id, equals('node_$longId'));
      expect(nodeItem.referenceId, equals(longId));
    });

    test('handles infinite bounds values', () {
      const bounds = Rect.fromLTRB(
        double.negativeInfinity,
        double.negativeInfinity,
        double.infinity,
        double.infinity,
      );
      const item = NodeSpatialItem(nodeId: 'infinite', bounds: bounds);

      expect(item.bounds.left, equals(double.negativeInfinity));
      expect(item.bounds.right, equals(double.infinity));
    });

    test('handles NaN bounds values', () {
      const bounds = Rect.fromLTWH(double.nan, double.nan, 100, 100);
      const item = NodeSpatialItem(nodeId: 'nan', bounds: bounds);

      expect(item.bounds.left.isNaN, isTrue);
    });

    test('segmentIndex zero is valid', () {
      const item = ConnectionSegmentItem(
        connectionId: 'conn-1',
        segmentIndex: 0,
        bounds: Rect.zero,
      );

      expect(item.segmentIndex, equals(0));
      expect(item.id, contains('_seg_0'));
    });

    test('negative segmentIndex is allowed by type but unusual', () {
      // While the type allows negative indices, they would be unusual in practice
      const item = ConnectionSegmentItem(
        connectionId: 'conn-1',
        segmentIndex: -1,
        bounds: Rect.zero,
      );

      expect(item.segmentIndex, equals(-1));
      expect(item.id, equals('conn_conn-1_seg_-1'));
    });
  });

  group('Cross-Type Equality', () {
    test('different spatial item types are never equal', () {
      const nodeItem = NodeSpatialItem(nodeId: 'id-1', bounds: Rect.zero);
      const portItem = PortSpatialItem(
        portId: 'id-1',
        nodeId: 'id-1',
        isOutput: true,
        bounds: Rect.zero,
      );
      const connItem = ConnectionSegmentItem(
        connectionId: 'id-1',
        segmentIndex: 0,
        bounds: Rect.zero,
      );

      expect(nodeItem == portItem, isFalse);
      expect(nodeItem == connItem, isFalse);
      expect(portItem == connItem, isFalse);
    });
  });
}
