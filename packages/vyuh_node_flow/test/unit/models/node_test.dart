/// Unit tests for the [Node] data model.
///
/// Tests cover:
/// - Node creation with required and optional fields
/// - Observable properties (position, size, zIndex, selected, dragging, visible)
/// - Port management (add, remove, find, update)
/// - Bounds calculation and hit testing
/// - JSON serialization
@Tags(['unit'])
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobx/mobx.dart';
import 'package:vyuh_node_flow/vyuh_node_flow.dart';

import '../../helpers/test_factories.dart';
import '../../helpers/test_utils.dart';

void main() {
  setUp(() {
    resetTestCounters();
  });

  group('Node Creation', () {
    test('creates node with required fields', () {
      final node = Node<String>(
        id: 'test-node',
        type: 'processor',
        position: const Offset(100, 200),
        data: 'test-data',
      );

      expect(node.id, equals('test-node'));
      expect(node.type, equals('processor'));
      expect(node.position.value, equals(const Offset(100, 200)));
      expect(node.data, equals('test-data'));
    });

    test('creates node with default size of 150x100', () {
      final node = createTestNode();

      expect(node.size.value, equals(const Size(150, 100)));
    });

    test('creates node with custom size', () {
      final node = createTestNode(size: const Size(200, 150));

      expect(node.size.value, equals(const Size(200, 150)));
    });

    test('creates node with empty ports by default', () {
      final node = createTestNode();

      expect(node.inputPorts, isEmpty);
      expect(node.outputPorts, isEmpty);
    });

    test('creates node with input ports', () {
      final inputPort = createTestPort(type: PortType.input);
      final node = createTestNode(inputPorts: [inputPort]);

      expect(node.inputPorts.length, equals(1));
      expect(node.inputPorts.first.id, equals(inputPort.id));
    });

    test('creates node with output ports', () {
      final outputPort = createTestPort(type: PortType.output);
      final node = createTestNode(outputPorts: [outputPort]);

      expect(node.outputPorts.length, equals(1));
      expect(node.outputPorts.first.id, equals(outputPort.id));
    });

    test('creates node with initial z-index', () {
      final node = createTestNode(zIndex: 5);

      expect(node.currentZIndex, equals(5));
    });

    test('creates node with visible=true by default', () {
      final node = createTestNode();

      expect(node.isVisible, isTrue);
    });

    test('creates node with visible=false', () {
      final node = createTestNode(visible: false);

      expect(node.isVisible, isFalse);
    });

    test('creates node with selected=false by default', () {
      final node = createTestNode();

      expect(node.isSelected, isFalse);
    });

    test('creates node with dragging=false by default', () {
      final node = createTestNode();

      expect(node.isDragging, isFalse);
    });

    test('initializes visual position same as position', () {
      final node = createTestNode(position: const Offset(50, 75));

      expect(node.visualPosition.value, equals(const Offset(50, 75)));
    });
  });

  group('Observable Properties', () {
    test('position is observable and updates correctly', () {
      final node = createTestNode(position: const Offset(0, 0));
      final tracker = ObservableTracker<Offset>();
      tracker.track(node.position);

      runInAction(() {
        node.position.value = const Offset(100, 100);
      });

      expect(node.position.value, equals(const Offset(100, 100)));
      expect(tracker.values, contains(const Offset(100, 100)));
      tracker.dispose();
    });

    test('size is observable and updates correctly', () {
      final node = createTestNode();

      runInAction(() {
        node.size.value = const Size(300, 200);
      });

      expect(node.size.value, equals(const Size(300, 200)));
    });

    test('zIndex is observable and updates correctly', () {
      final node = createTestNode(zIndex: 0);

      node.currentZIndex = 10;

      expect(node.currentZIndex, equals(10));
      expect(node.zIndex.value, equals(10));
    });

    test('selected is observable and updates correctly', () {
      final node = createTestNode();

      node.isSelected = true;

      expect(node.isSelected, isTrue);
      expect(node.selected.value, isTrue);
    });

    test('dragging is observable and updates correctly', () {
      final node = createTestNode();

      node.isDragging = true;

      expect(node.isDragging, isTrue);
      expect(node.dragging.value, isTrue);
    });

    test('visibility is observable and updates correctly', () {
      final node = createTestNode();

      node.isVisible = false;

      expect(node.isVisible, isFalse);
    });

    test('visual position updates via setVisualPosition', () {
      final node = createTestNode(position: const Offset(0, 0));

      node.setVisualPosition(const Offset(16, 16));

      expect(node.visualPosition.value, equals(const Offset(16, 16)));
      // Position should remain unchanged
      expect(node.position.value, equals(const Offset(0, 0)));
    });
  });

  group('Port Management', () {
    test('addInputPort adds port to inputPorts', () {
      final node = createTestNode();
      final port = createTestPort(id: 'new-input', type: PortType.input);

      node.addInputPort(port);

      expect(node.inputPorts.length, equals(1));
      expect(node.inputPorts.first.id, equals('new-input'));
    });

    test('addOutputPort adds port to outputPorts', () {
      final node = createTestNode();
      final port = createTestPort(id: 'new-output', type: PortType.output);

      node.addOutputPort(port);

      expect(node.outputPorts.length, equals(1));
      expect(node.outputPorts.first.id, equals('new-output'));
    });

    test('removeInputPort removes existing port', () {
      final port = createTestPort(id: 'input-to-remove', type: PortType.input);
      final node = createTestNode(inputPorts: [port]);

      final removed = node.removeInputPort('input-to-remove');

      expect(removed, isTrue);
      expect(node.inputPorts, isEmpty);
    });

    test('removeInputPort returns false for non-existent port', () {
      final node = createTestNode();

      final removed = node.removeInputPort('non-existent');

      expect(removed, isFalse);
    });

    test('removeOutputPort removes existing port', () {
      final port = createTestPort(
        id: 'output-to-remove',
        type: PortType.output,
      );
      final node = createTestNode(outputPorts: [port]);

      final removed = node.removeOutputPort('output-to-remove');

      expect(removed, isTrue);
      expect(node.outputPorts, isEmpty);
    });

    test('removeOutputPort returns false for non-existent port', () {
      final node = createTestNode();

      final removed = node.removeOutputPort('non-existent');

      expect(removed, isFalse);
    });

    test('removePort removes from either input or output ports', () {
      final inputPort = createTestPort(id: 'input-1', type: PortType.input);
      final outputPort = createTestPort(id: 'output-1', type: PortType.output);
      final node = createTestNode(
        inputPorts: [inputPort],
        outputPorts: [outputPort],
      );

      expect(node.removePort('input-1'), isTrue);
      expect(node.removePort('output-1'), isTrue);
      expect(node.inputPorts, isEmpty);
      expect(node.outputPorts, isEmpty);
    });

    test('updateInputPort replaces existing port', () {
      final originalPort = createTestPort(
        id: 'port-1',
        name: 'Original',
        type: PortType.input,
      );
      final node = createTestNode(inputPorts: [originalPort]);
      final updatedPort = originalPort.copyWith(name: 'Updated');

      final updated = node.updateInputPort('port-1', updatedPort);

      expect(updated, isTrue);
      expect(node.inputPorts.first.name, equals('Updated'));
    });

    test('updateOutputPort replaces existing port', () {
      final originalPort = createTestPort(
        id: 'port-1',
        name: 'Original',
        type: PortType.output,
      );
      final node = createTestNode(outputPorts: [originalPort]);
      final updatedPort = originalPort.copyWith(name: 'Updated');

      final updated = node.updateOutputPort('port-1', updatedPort);

      expect(updated, isTrue);
      expect(node.outputPorts.first.name, equals('Updated'));
    });

    test('updatePort updates from either input or output ports', () {
      final inputPort = createTestPort(
        id: 'input-1',
        name: 'Input',
        type: PortType.input,
      );
      final node = createTestNode(inputPorts: [inputPort]);

      final updated = node.updatePort(
        'input-1',
        inputPort.copyWith(name: 'Updated Input'),
      );

      expect(updated, isTrue);
      expect(node.inputPorts.first.name, equals('Updated Input'));
    });

    test('findPort finds port in inputPorts', () {
      final port = createTestPort(id: 'find-me', type: PortType.input);
      final node = createTestNode(inputPorts: [port]);

      final found = node.findPort('find-me');

      expect(found, isNotNull);
      expect(found!.id, equals('find-me'));
    });

    test('findPort finds port in outputPorts', () {
      final port = createTestPort(id: 'find-me', type: PortType.output);
      final node = createTestNode(outputPorts: [port]);

      final found = node.findPort('find-me');

      expect(found, isNotNull);
      expect(found!.id, equals('find-me'));
    });

    test('findPort returns null for non-existent port', () {
      final node = createTestNode();

      final found = node.findPort('non-existent');

      expect(found, isNull);
    });

    test('allPorts returns combined input and output ports', () {
      final inputPort = createTestPort(id: 'input', type: PortType.input);
      final outputPort = createTestPort(id: 'output', type: PortType.output);
      final node = createTestNode(
        inputPorts: [inputPort],
        outputPorts: [outputPort],
      );

      final allPorts = node.allPorts;

      expect(allPorts.length, equals(2));
      expect(allPorts.map((p) => p.id), containsAll(['input', 'output']));
    });
  });

  group('Bounds and Hit Testing', () {
    test('getBounds returns correct rectangle', () {
      final node = createTestNode(
        position: const Offset(100, 50),
        size: const Size(200, 100),
      );

      final bounds = node.getBounds();

      expect(bounds.left, equals(100));
      expect(bounds.top, equals(50));
      expect(bounds.width, equals(200));
      expect(bounds.height, equals(100));
    });

    test('containsPoint returns true for point inside node', () {
      final node = createTestNode(
        position: const Offset(0, 0),
        size: const Size(100, 100),
      );

      expect(node.containsPoint(const Offset(50, 50)), isTrue);
    });

    test('containsPoint returns true for point on edge', () {
      final node = createTestNode(
        position: const Offset(0, 0),
        size: const Size(100, 100),
      );

      // Top-left corner is inclusive
      expect(node.containsPoint(const Offset(0, 0)), isTrue);
      // Interior point near bottom-right (Rect.contains() excludes right/bottom edges)
      expect(node.containsPoint(const Offset(99, 99)), isTrue);
      // Left and top edges are inclusive
      expect(node.containsPoint(const Offset(0, 50)), isTrue);
      expect(node.containsPoint(const Offset(50, 0)), isTrue);
    });

    test('containsPoint returns false for point outside node', () {
      final node = createTestNode(
        position: const Offset(0, 0),
        size: const Size(100, 100),
      );

      expect(node.containsPoint(const Offset(-1, 50)), isFalse);
      expect(node.containsPoint(const Offset(101, 50)), isFalse);
      expect(node.containsPoint(const Offset(50, -1)), isFalse);
      expect(node.containsPoint(const Offset(50, 101)), isFalse);
    });
  });

  group('Port Position Calculations', () {
    test('getConnectionPoint for left port', () {
      final port = createTestPort(
        id: 'left-port',
        type: PortType.input,
        position: PortPosition.left,
        offset: const Offset(0, 50), // Center vertically on 100px tall node
      );
      final node = createTestNode(
        position: const Offset(100, 100),
        size: const Size(150, 100),
        inputPorts: [port],
      );

      final connectionPoint = node.getConnectionPoint(
        'left-port',
        portSize: defaultPortSize,
      );

      // Connection point should be at left edge of node
      expect(connectionPoint.dx, lessThan(node.visualPosition.value.dx + 10));
    });

    test('getConnectionPoint for right port', () {
      final port = createTestPort(
        id: 'right-port',
        type: PortType.output,
        position: PortPosition.right,
        offset: const Offset(0, 50),
      );
      final node = createTestNode(
        position: const Offset(100, 100),
        size: const Size(150, 100),
        outputPorts: [port],
      );

      final connectionPoint = node.getConnectionPoint(
        'right-port',
        portSize: defaultPortSize,
      );

      // Connection point should be at right edge of node
      expect(
        connectionPoint.dx,
        greaterThan(node.visualPosition.value.dx + node.size.value.width - 20),
      );
    });

    test('getConnectionPoint throws for non-existent port', () {
      final node = createTestNode();

      expect(
        () =>
            node.getConnectionPoint('non-existent', portSize: defaultPortSize),
        throwsArgumentError,
      );
    });

    test('getVisualPortOrigin throws for non-existent port', () {
      final node = createTestNode();

      expect(
        () =>
            node.getVisualPortOrigin('non-existent', portSize: defaultPortSize),
        throwsArgumentError,
      );
    });

    test('getPortCenter throws for non-existent port', () {
      final node = createTestNode();

      expect(
        () => node.getPortCenter('non-existent', portSize: defaultPortSize),
        throwsArgumentError,
      );
    });
  });

  group('JSON Serialization', () {
    test('toJson produces valid JSON', () {
      final node = createTestNode(
        id: 'json-test',
        type: 'processor',
        position: const Offset(100, 200),
        size: const Size(150, 100),
        data: 'test-data',
        zIndex: 5,
      );

      final json = node.toJson((data) => data);

      expect(json['id'], equals('json-test'));
      expect(json['type'], equals('processor'));
      // New simplified format uses x/y/width/height directly
      expect(json['x'], equals(100.0));
      expect(json['y'], equals(200.0));
      expect(json['width'], equals(150.0));
      expect(json['height'], equals(100.0));
      expect(json['data'], equals('test-data'));
      expect(json['zIndex'], equals(5));
    });

    test('fromJson reconstructs node correctly', () {
      // First serialize a node to get the correct JSON format
      final originalNode = Node<String>(
        id: 'reconstructed',
        type: 'processor',
        position: const Offset(100, 200),
        size: const Size(200, 150),
        data: 'restored-data',
        initialZIndex: 3,
        visible: true,
        inputPorts: [],
        outputPorts: [],
      );

      final json = originalNode.toJson((data) => data);
      final node = Node<String>.fromJson(json, (json) => json as String);

      expect(node.id, equals('reconstructed'));
      expect(node.type, equals('processor'));
      expect(node.position.value, equals(const Offset(100, 200)));
      expect(node.size.value, equals(const Size(200, 150)));
      expect(node.data, equals('restored-data'));
      expect(node.currentZIndex, equals(3));
      expect(node.isVisible, isTrue);
    });

    test('round-trip serialization preserves all properties', () {
      final original = createTestNode(
        id: 'round-trip',
        type: 'special',
        position: const Offset(50, 75),
        size: const Size(180, 120),
        data: 'round-trip-data',
        zIndex: 7,
        visible: true,
      );

      final restored = roundTripNodeJson(original);

      expect(restored.id, equals(original.id));
      expect(restored.type, equals(original.type));
      expect(restored.position.value, equals(original.position.value));
      expect(restored.size.value, equals(original.size.value));
      expect(restored.data, equals(original.data));
      expect(restored.currentZIndex, equals(original.currentZIndex));
      expect(restored.isVisible, equals(original.isVisible));
    });

    test('serialization includes ports', () {
      final inputPort = createTestPort(id: 'input-1', type: PortType.input);
      final outputPort = createTestPort(id: 'output-1', type: PortType.output);
      final node = createTestNode(
        inputPorts: [inputPort],
        outputPorts: [outputPort],
      );

      final json = node.toJson((data) => data);

      expect(json['inputPorts'], isA<List>());
      expect((json['inputPorts'] as List).length, equals(1));
      expect(json['outputPorts'], isA<List>());
      expect((json['outputPorts'] as List).length, equals(1));
    });

    test('fromJson handles missing optional fields', () {
      final json = {'id': 'minimal', 'type': 'basic', 'data': 'minimal-data'};

      final node = Node<String>.fromJson(json, (json) => json as String);

      expect(node.id, equals('minimal'));
      expect(node.type, equals('basic'));
      expect(node.position.value, equals(Offset.zero));
      expect(node.currentZIndex, equals(0));
      expect(node.isVisible, isTrue);
    });
  });

  group('Dispose', () {
    test('dispose can be called without error', () {
      final node = createTestNode();

      // Should not throw
      expect(() => node.dispose(), returnsNormally);
    });
  });

  group('Edge Cases', () {
    test('node at origin (0, 0)', () {
      final node = createTestNode(position: Offset.zero);

      expect(node.position.value, equals(Offset.zero));
      expect(node.containsPoint(const Offset(50, 50)), isTrue);
    });

    test('node at negative coordinates', () {
      final node = createTestNode(
        position: const Offset(-100, -50),
        size: const Size(50, 50),
      );

      expect(node.getBounds().left, equals(-100));
      expect(node.getBounds().top, equals(-50));
      expect(node.containsPoint(const Offset(-75, -25)), isTrue);
    });

    test('node at very large coordinates', () {
      final node = createTestNode(
        position: const Offset(10000, 10000),
        size: const Size(100, 100),
      );

      expect(node.position.value, equals(const Offset(10000, 10000)));
      expect(node.containsPoint(const Offset(10050, 10050)), isTrue);
    });

    test('multiple ports on same position', () {
      final port1 = createTestPort(
        id: 'port-1',
        position: PortPosition.left,
        offset: const Offset(0, 25),
        type: PortType.input,
      );
      final port2 = createTestPort(
        id: 'port-2',
        position: PortPosition.left,
        offset: const Offset(0, 75),
        type: PortType.input,
      );
      final node = createTestNode(
        size: const Size(150, 100),
        inputPorts: [port1, port2],
      );

      expect(node.inputPorts.length, equals(2));
      expect(node.findPort('port-1'), isNotNull);
      expect(node.findPort('port-2'), isNotNull);
    });
  });
}
