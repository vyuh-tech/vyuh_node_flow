/// Unit tests for the [Port] data model.
///
/// Tests cover:
/// - Port creation with all PortPosition values
/// - Port type inference from position
/// - Multi-connection and max connections configuration
/// - Port visibility and connectability
/// - Equality and copyWith
/// - JSON serialization
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

  group('Port Creation', () {
    test('creates port with required fields', () {
      final port = Port(id: 'test-port', name: 'Test Port');

      expect(port.id, equals('test-port'));
      expect(port.name, equals('Test Port'));
    });

    test('creates port with default position of left', () {
      final port = Port(id: 'port', name: 'Port');

      expect(port.position, equals(PortPosition.left));
    });

    test('creates port with default offset of zero', () {
      final port = Port(id: 'port', name: 'Port');

      expect(port.offset, equals(Offset.zero));
    });

    test('creates port with default multiConnections of false', () {
      final port = Port(id: 'port', name: 'Port');

      expect(port.multiConnections, isFalse);
    });

    test('creates port with default isConnectable of true', () {
      final port = Port(id: 'port', name: 'Port');

      expect(port.isConnectable, isTrue);
    });

    test('creates port with default showLabel of false', () {
      final port = Port(id: 'port', name: 'Port');

      expect(port.showLabel, isFalse);
    });

    test('creates port with null maxConnections by default', () {
      final port = Port(id: 'port', name: 'Port');

      expect(port.maxConnections, isNull);
    });
  });

  group('Port Position Values', () {
    test('creates port with PortPosition.left', () {
      final port = Port(
        id: 'left-port',
        name: 'Left',
        position: PortPosition.left,
      );

      expect(port.position, equals(PortPosition.left));
    });

    test('creates port with PortPosition.right', () {
      final port = Port(
        id: 'right-port',
        name: 'Right',
        position: PortPosition.right,
      );

      expect(port.position, equals(PortPosition.right));
    });

    test('creates port with PortPosition.top', () {
      final port = Port(
        id: 'top-port',
        name: 'Top',
        position: PortPosition.top,
      );

      expect(port.position, equals(PortPosition.top));
    });

    test('creates port with PortPosition.bottom', () {
      final port = Port(
        id: 'bottom-port',
        name: 'Bottom',
        position: PortPosition.bottom,
      );

      expect(port.position, equals(PortPosition.bottom));
    });
  });

  group('Port Type Inference', () {
    test('infers input type from left position', () {
      final port = Port(id: 'port', name: 'Port', position: PortPosition.left);

      expect(port.type, equals(PortType.input));
      expect(port.isInput, isTrue);
      expect(port.isOutput, isFalse);
    });

    test('infers input type from top position', () {
      final port = Port(id: 'port', name: 'Port', position: PortPosition.top);

      expect(port.type, equals(PortType.input));
      expect(port.isInput, isTrue);
    });

    test('infers output type from right position', () {
      final port = Port(id: 'port', name: 'Port', position: PortPosition.right);

      expect(port.type, equals(PortType.output));
      expect(port.isOutput, isTrue);
      expect(port.isInput, isFalse);
    });

    test('infers output type from bottom position', () {
      final port = Port(
        id: 'port',
        name: 'Port',
        position: PortPosition.bottom,
      );

      expect(port.type, equals(PortType.output));
      expect(port.isOutput, isTrue);
    });

    test('explicit type overrides inferred type', () {
      final port = Port(
        id: 'port',
        name: 'Port',
        position: PortPosition.left, // Would normally infer input
        type: PortType.output, // Explicit override
      );

      expect(port.type, equals(PortType.output));
      expect(port.isOutput, isTrue);
    });
  });

  group('Port Configuration', () {
    test('creates port with custom offset', () {
      final port = Port(id: 'port', name: 'Port', offset: const Offset(10, 20));

      expect(port.offset, equals(const Offset(10, 20)));
    });

    test('creates port with multiConnections enabled', () {
      final port = Port(id: 'port', name: 'Port', multiConnections: true);

      expect(port.multiConnections, isTrue);
    });

    test('creates port with maxConnections limit', () {
      final port = Port(
        id: 'port',
        name: 'Port',
        multiConnections: true,
        maxConnections: 5,
      );

      expect(port.maxConnections, equals(5));
    });

    test('creates port with isConnectable set to false', () {
      final port = Port(id: 'port', name: 'Port', isConnectable: false);

      expect(port.isConnectable, isFalse);
    });

    test('creates port with tooltip', () {
      final port = Port(
        id: 'port',
        name: 'Port',
        tooltip: 'This is a helpful tooltip',
      );

      expect(port.tooltip, equals('This is a helpful tooltip'));
    });

    test('creates port with showLabel enabled', () {
      final port = Port(id: 'port', name: 'Port', showLabel: true);

      expect(port.showLabel, isTrue);
    });

    test('creates port with custom size', () {
      final port = Port(id: 'port', name: 'Port', size: const Size(12, 12));

      expect(port.size, equals(const Size(12, 12)));
    });
  });

  group('Port Highlighted Observable', () {
    test('highlighted is false by default', () {
      final port = Port(id: 'port', name: 'Port');

      expect(port.highlighted.value, isFalse);
    });

    test('highlighted can be updated', () {
      final port = Port(id: 'port', name: 'Port');

      port.highlighted.value = true;

      expect(port.highlighted.value, isTrue);
    });
  });

  group('Port Equality', () {
    test('ports with same properties are equal', () {
      final port1 = Port(
        id: 'port',
        name: 'Port',
        position: PortPosition.left,
        offset: const Offset(10, 20),
        multiConnections: true,
        maxConnections: 5,
      );

      final port2 = Port(
        id: 'port',
        name: 'Port',
        position: PortPosition.left,
        offset: const Offset(10, 20),
        multiConnections: true,
        maxConnections: 5,
      );

      expect(port1, equals(port2));
    });

    test('ports with different id are not equal', () {
      final port1 = Port(id: 'port-1', name: 'Port');
      final port2 = Port(id: 'port-2', name: 'Port');

      expect(port1, isNot(equals(port2)));
    });

    test('ports with different position are not equal', () {
      final port1 = Port(id: 'port', name: 'Port', position: PortPosition.left);
      final port2 = Port(
        id: 'port',
        name: 'Port',
        position: PortPosition.right,
      );

      expect(port1, isNot(equals(port2)));
    });

    test('ports with different offset are not equal', () {
      final port1 = Port(
        id: 'port',
        name: 'Port',
        offset: const Offset(10, 20),
      );
      final port2 = Port(
        id: 'port',
        name: 'Port',
        offset: const Offset(30, 40),
      );

      expect(port1, isNot(equals(port2)));
    });
  });

  group('Port copyWith', () {
    test('copyWith creates a copy with same values', () {
      final original = Port(
        id: 'port',
        name: 'Port',
        position: PortPosition.left,
        offset: const Offset(10, 20),
        multiConnections: true,
        maxConnections: 5,
        isConnectable: true,
        showLabel: true,
        tooltip: 'Tooltip',
      );

      final copy = original.copyWith();

      expect(copy, equals(original));
    });

    test('copyWith changes specified properties', () {
      final original = Port(id: 'port', name: 'Original');

      final modified = original.copyWith(name: 'Modified', showLabel: true);

      expect(modified.id, equals('port')); // Unchanged
      expect(modified.name, equals('Modified')); // Changed
      expect(modified.showLabel, isTrue); // Changed
    });

    test('copyWith can change position', () {
      final original = Port(
        id: 'port',
        name: 'Port',
        position: PortPosition.left,
      );

      final modified = original.copyWith(position: PortPosition.right);

      expect(modified.position, equals(PortPosition.right));
    });

    test('copyWith can change type', () {
      final original = Port(id: 'port', name: 'Port', type: PortType.input);

      final modified = original.copyWith(type: PortType.output);

      expect(modified.type, equals(PortType.output));
    });

    test('copyWith can change multiConnections and maxConnections', () {
      final original = Port(
        id: 'port',
        name: 'Port',
        multiConnections: false,
        maxConnections: null,
      );

      final modified = original.copyWith(
        multiConnections: true,
        maxConnections: 10,
      );

      expect(modified.multiConnections, isTrue);
      expect(modified.maxConnections, equals(10));
    });
  });

  group('PortPosition Extension', () {
    test('connectionOffset for left position', () {
      final offset = PortPosition.left.connectionOffset(defaultPortSize);

      expect(offset.dx, equals(0));
      expect(offset.dy, equals(defaultPortSize.height / 2));
    });

    test('connectionOffset for right position', () {
      final offset = PortPosition.right.connectionOffset(defaultPortSize);

      expect(offset.dx, equals(defaultPortSize.width));
      expect(offset.dy, equals(defaultPortSize.height / 2));
    });

    test('connectionOffset for top position', () {
      final offset = PortPosition.top.connectionOffset(defaultPortSize);

      expect(offset.dx, equals(defaultPortSize.width / 2));
      expect(offset.dy, equals(0));
    });

    test('connectionOffset for bottom position', () {
      final offset = PortPosition.bottom.connectionOffset(defaultPortSize);

      expect(offset.dx, equals(defaultPortSize.width / 2));
      expect(offset.dy, equals(defaultPortSize.height));
    });

    test('isHorizontal is true for left and right', () {
      expect(PortPosition.left.isHorizontal, isTrue);
      expect(PortPosition.right.isHorizontal, isTrue);
      expect(PortPosition.top.isHorizontal, isFalse);
      expect(PortPosition.bottom.isHorizontal, isFalse);
    });

    test('isVertical is true for top and bottom', () {
      expect(PortPosition.top.isVertical, isTrue);
      expect(PortPosition.bottom.isVertical, isTrue);
      expect(PortPosition.left.isVertical, isFalse);
      expect(PortPosition.right.isVertical, isFalse);
    });

    test('normal vectors point outward', () {
      expect(PortPosition.left.normal, equals(const Offset(-1, 0)));
      expect(PortPosition.right.normal, equals(const Offset(1, 0)));
      expect(PortPosition.top.normal, equals(const Offset(0, -1)));
      expect(PortPosition.bottom.normal, equals(const Offset(0, 1)));
    });
  });

  group('JSON Serialization', () {
    test('toJson produces valid JSON', () {
      final port = Port(
        id: 'json-port',
        name: 'JSON Port',
        position: PortPosition.right,
        offset: const Offset(10, 20),
        multiConnections: true,
        maxConnections: 5,
        isConnectable: true,
        showLabel: true,
        tooltip: 'Test tooltip',
      );

      final json = port.toJson();

      expect(json['id'], equals('json-port'));
      expect(json['name'], equals('JSON Port'));
      expect(json['position'], equals('right'));
      expect(json['multiConnections'], isTrue);
      expect(json['maxConnections'], equals(5));
      expect(json['isConnectable'], isTrue);
      expect(json['showLabel'], isTrue);
      expect(json['tooltip'], equals('Test tooltip'));
    });

    test('fromJson reconstructs port correctly', () {
      // First serialize a port to get the correct JSON format
      final originalPort = Port(
        id: 'reconstructed',
        name: 'Reconstructed Port',
        position: PortPosition.left,
        offset: const Offset(5, 10),
        type: PortType.input,
        multiConnections: true,
        maxConnections: 3,
        isConnectable: false,
        showLabel: true,
        tooltip: 'Restored tooltip',
      );

      final json = originalPort.toJson();
      final port = Port.fromJson(json);

      expect(port.id, equals('reconstructed'));
      expect(port.name, equals('Reconstructed Port'));
      expect(port.position, equals(PortPosition.left));
      expect(port.offset, equals(const Offset(5, 10)));
      expect(port.type, equals(PortType.input));
      expect(port.multiConnections, isTrue);
      expect(port.maxConnections, equals(3));
      expect(port.isConnectable, isFalse);
      expect(port.showLabel, isTrue);
      expect(port.tooltip, equals('Restored tooltip'));
    });

    test('round-trip serialization preserves all properties', () {
      final original = Port(
        id: 'round-trip',
        name: 'Round Trip Port',
        position: PortPosition.bottom,
        offset: const Offset(75, 0),
        type: PortType.output,
        multiConnections: true,
        maxConnections: 10,
        isConnectable: true,
        showLabel: false,
        tooltip: 'Round trip test',
      );

      final json = original.toJson();
      final restored = Port.fromJson(json);

      expect(restored.id, equals(original.id));
      expect(restored.name, equals(original.name));
      expect(restored.position, equals(original.position));
      expect(restored.offset, equals(original.offset));
      expect(restored.type, equals(original.type));
      expect(restored.multiConnections, equals(original.multiConnections));
      expect(restored.maxConnections, equals(original.maxConnections));
      expect(restored.isConnectable, equals(original.isConnectable));
      expect(restored.showLabel, equals(original.showLabel));
      expect(restored.tooltip, equals(original.tooltip));
    });
  });

  group('Default Port Size', () {
    test('defaultPortSize is 9x9', () {
      expect(defaultPortSize, equals(const Size(9, 9)));
    });
  });

  group('Edge Cases', () {
    test('port with zero offset', () {
      final port = Port(id: 'port', name: 'Port', offset: Offset.zero);

      expect(port.offset, equals(Offset.zero));
    });

    test('port with negative offset', () {
      final port = Port(
        id: 'port',
        name: 'Port',
        offset: const Offset(-5, -10),
      );

      expect(port.offset, equals(const Offset(-5, -10)));
    });

    test('port with large offset', () {
      final port = Port(
        id: 'port',
        name: 'Port',
        offset: const Offset(1000, 1000),
      );

      expect(port.offset, equals(const Offset(1000, 1000)));
    });

    test('port with maxConnections of 0', () {
      final port = Port(
        id: 'port',
        name: 'Port',
        multiConnections: true,
        maxConnections: 0,
      );

      expect(port.maxConnections, equals(0));
    });

    test('port with very large maxConnections', () {
      final port = Port(
        id: 'port',
        name: 'Port',
        multiConnections: true,
        maxConnections: 1000000,
      );

      expect(port.maxConnections, equals(1000000));
    });
  });
}
