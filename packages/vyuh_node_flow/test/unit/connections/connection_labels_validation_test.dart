/// Unit tests for ConnectionLabel, LabelTheme, ConnectionValidation, and ConnectionEndpoint.
///
/// Tests cover:
/// - ConnectionLabel creation and properties
/// - ConnectionLabel factory constructors (start, center, end)
/// - ConnectionLabel update methods
/// - LabelTheme construction and styling
/// - ConnectionValidationResult usage
/// - ConnectionStartContext and ConnectionCompleteContext
/// - ConnectionEndPoint construction and predefined endpoints
/// - Connection model with labels
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
  // ConnectionLabel Tests
  // ===========================================================================

  group('ConnectionLabel', () {
    group('Construction', () {
      test('creates label with required text parameter', () {
        final label = ConnectionLabel(text: 'Test Label');

        expect(label.text, equals('Test Label'));
      });

      test('creates label with default anchor at center (0.5)', () {
        final label = ConnectionLabel(text: 'Test');

        expect(label.anchor, equals(0.5));
      });

      test('creates label with default offset of 0.0', () {
        final label = ConnectionLabel(text: 'Test');

        expect(label.offset, equals(0.0));
      });

      test('creates label with custom anchor value', () {
        final label = ConnectionLabel(text: 'Test', anchor: 0.25);

        expect(label.anchor, equals(0.25));
      });

      test('creates label with custom offset value', () {
        final label = ConnectionLabel(text: 'Test', offset: 15.0);

        expect(label.offset, equals(15.0));
      });

      test('creates label with negative offset', () {
        final label = ConnectionLabel(text: 'Test', offset: -10.0);

        expect(label.offset, equals(-10.0));
      });

      test('creates label with custom id', () {
        final label = ConnectionLabel(text: 'Test', id: 'my-custom-id');

        expect(label.id, equals('my-custom-id'));
      });

      test('generates unique id when not provided', () {
        final label1 = ConnectionLabel(text: 'Test 1');
        final label2 = ConnectionLabel(text: 'Test 2');

        expect(label1.id, isNotEmpty);
        expect(label2.id, isNotEmpty);
        expect(label1.id, isNot(equals(label2.id)));
      });

      test('anchor must be between 0.0 and 1.0', () {
        expect(
          () => ConnectionLabel(text: 'Test', anchor: -0.1),
          throwsA(isA<AssertionError>()),
        );

        expect(
          () => ConnectionLabel(text: 'Test', anchor: 1.1),
          throwsA(isA<AssertionError>()),
        );
      });

      test('anchor at boundary values 0.0 and 1.0 is valid', () {
        final startLabel = ConnectionLabel(text: 'Start', anchor: 0.0);
        final endLabel = ConnectionLabel(text: 'End', anchor: 1.0);

        expect(startLabel.anchor, equals(0.0));
        expect(endLabel.anchor, equals(1.0));
      });
    });

    group('Factory Constructors', () {
      test('ConnectionLabel.start creates label at anchor 0.0', () {
        final label = ConnectionLabel.start(text: 'Start Label');

        expect(label.text, equals('Start Label'));
        expect(label.anchor, equals(0.0));
        expect(label.offset, equals(0.0));
      });

      test('ConnectionLabel.center creates label at anchor 0.5', () {
        final label = ConnectionLabel.center(text: 'Center Label');

        expect(label.text, equals('Center Label'));
        expect(label.anchor, equals(0.5));
        expect(label.offset, equals(0.0));
      });

      test('ConnectionLabel.end creates label at anchor 1.0', () {
        final label = ConnectionLabel.end(text: 'End Label');

        expect(label.text, equals('End Label'));
        expect(label.anchor, equals(1.0));
        expect(label.offset, equals(0.0));
      });

      test('ConnectionLabel.start accepts custom offset', () {
        final label = ConnectionLabel.start(text: 'Start', offset: 5.0);

        expect(label.offset, equals(5.0));
        expect(label.anchor, equals(0.0));
      });

      test('ConnectionLabel.center accepts custom offset', () {
        final label = ConnectionLabel.center(text: 'Center', offset: -3.0);

        expect(label.offset, equals(-3.0));
        expect(label.anchor, equals(0.5));
      });

      test('ConnectionLabel.end accepts custom offset', () {
        final label = ConnectionLabel.end(text: 'End', offset: 10.0);

        expect(label.offset, equals(10.0));
        expect(label.anchor, equals(1.0));
      });

      test('ConnectionLabel.start accepts custom id', () {
        final label = ConnectionLabel.start(text: 'Start', id: 'start-id');

        expect(label.id, equals('start-id'));
      });
    });

    group('Update Methods', () {
      test('updateText changes the label text', () {
        final label = ConnectionLabel(text: 'Original');

        label.updateText('Updated');

        expect(label.text, equals('Updated'));
      });

      test('updateAnchor changes the anchor position', () {
        final label = ConnectionLabel(text: 'Test');

        label.updateAnchor(0.75);

        expect(label.anchor, equals(0.75));
      });

      test('updateAnchor validates range', () {
        final label = ConnectionLabel(text: 'Test');

        expect(() => label.updateAnchor(-0.1), throwsA(isA<AssertionError>()));

        expect(() => label.updateAnchor(1.5), throwsA(isA<AssertionError>()));
      });

      test('updateOffset changes the offset value', () {
        final label = ConnectionLabel(text: 'Test');

        label.updateOffset(20.0);

        expect(label.offset, equals(20.0));
      });

      test('update method changes multiple properties at once', () {
        final label = ConnectionLabel(
          text: 'Original',
          anchor: 0.0,
          offset: 0.0,
        );

        label.update(text: 'New Text', anchor: 0.75, offset: 12.0);

        expect(label.text, equals('New Text'));
        expect(label.anchor, equals(0.75));
        expect(label.offset, equals(12.0));
      });

      test('update method allows partial updates', () {
        final label = ConnectionLabel(
          text: 'Original',
          anchor: 0.3,
          offset: 5.0,
        );

        label.update(text: 'New Text');

        expect(label.text, equals('New Text'));
        expect(label.anchor, equals(0.3)); // unchanged
        expect(label.offset, equals(5.0)); // unchanged
      });
    });

    group('JSON Serialization', () {
      test('toJson produces valid JSON', () {
        final label = ConnectionLabel(
          text: 'Test Label',
          anchor: 0.25,
          offset: 10.0,
          id: 'label-1',
        );

        final json = label.toJson();

        expect(json['text'], equals('Test Label'));
        expect(json['anchor'], equals(0.25));
        expect(json['offset'], equals(10.0));
        expect(json['id'], equals('label-1'));
      });

      test('fromJson reconstructs label correctly', () {
        final json = {
          'text': 'Restored Label',
          'anchor': 0.75,
          'offset': -5.0,
          'id': 'restored-id',
        };

        final label = ConnectionLabel.fromJson(json);

        expect(label.text, equals('Restored Label'));
        expect(label.anchor, equals(0.75));
        expect(label.offset, equals(-5.0));
        expect(label.id, equals('restored-id'));
      });

      test('fromJson uses defaults for missing optional fields', () {
        final json = {'text': 'Minimal', 'id': 'min-id'};

        final label = ConnectionLabel.fromJson(json);

        expect(label.text, equals('Minimal'));
        expect(label.anchor, equals(0.5)); // default
        expect(label.offset, equals(0.0)); // default
      });
    });

    group('toString', () {
      test('returns readable representation', () {
        final label = ConnectionLabel(
          text: 'Test',
          anchor: 0.5,
          offset: 10.0,
          id: 'test-id',
        );

        final str = label.toString();

        expect(str, contains('ConnectionLabel'));
        expect(str, contains('test-id'));
        expect(str, contains('Test'));
        expect(str, contains('0.5'));
        expect(str, contains('10.0'));
      });
    });
  });

  // ===========================================================================
  // LabelTheme Tests
  // ===========================================================================

  group('LabelTheme', () {
    group('Construction', () {
      test('creates theme with default values', () {
        const theme = LabelTheme();

        expect(theme.textStyle.fontSize, equals(12.0));
        expect(theme.backgroundColor, isNull);
        expect(theme.border, isNull);
        expect(
          theme.borderRadius,
          equals(const BorderRadius.all(Radius.circular(4.0))),
        );
        expect(
          theme.padding,
          equals(const EdgeInsets.symmetric(horizontal: 8, vertical: 2)),
        );
        expect(theme.maxWidth, equals(double.infinity));
        expect(theme.maxLines, isNull);
        expect(theme.offset, equals(0.0));
        expect(theme.labelGap, equals(8.0));
      });

      test('creates theme with custom text style', () {
        const customStyle = TextStyle(
          fontSize: 16.0,
          fontWeight: FontWeight.bold,
          color: Colors.red,
        );

        const theme = LabelTheme(textStyle: customStyle);

        expect(theme.textStyle.fontSize, equals(16.0));
        expect(theme.textStyle.fontWeight, equals(FontWeight.bold));
        expect(theme.textStyle.color, equals(Colors.red));
      });

      test('creates theme with custom background color', () {
        const theme = LabelTheme(backgroundColor: Colors.blue);

        expect(theme.backgroundColor, equals(Colors.blue));
      });

      test('creates theme with custom border', () {
        const border = Border.fromBorderSide(
          BorderSide(color: Colors.green, width: 2.0),
        );
        const theme = LabelTheme(border: border);

        expect(theme.border, equals(border));
      });

      test('creates theme with custom border radius', () {
        const radius = BorderRadius.all(Radius.circular(10.0));
        const theme = LabelTheme(borderRadius: radius);

        expect(theme.borderRadius, equals(radius));
      });

      test('creates theme with custom padding', () {
        const padding = EdgeInsets.all(16.0);
        const theme = LabelTheme(padding: padding);

        expect(theme.padding, equals(padding));
      });

      test('creates theme with custom maxWidth', () {
        const theme = LabelTheme(maxWidth: 150.0);

        expect(theme.maxWidth, equals(150.0));
      });

      test('creates theme with custom maxLines', () {
        const theme = LabelTheme(maxLines: 2);

        expect(theme.maxLines, equals(2));
      });

      test('creates theme with custom offset', () {
        const theme = LabelTheme(offset: 5.0);

        expect(theme.offset, equals(5.0));
      });

      test('creates theme with custom labelGap', () {
        const theme = LabelTheme(labelGap: 12.0);

        expect(theme.labelGap, equals(12.0));
      });
    });

    group('Predefined Themes', () {
      test('light theme has expected properties', () {
        const theme = LabelTheme.light;

        expect(theme.textStyle.color, equals(const Color(0xFF333333)));
        expect(theme.textStyle.fontSize, equals(12.0));
        expect(theme.textStyle.fontWeight, equals(FontWeight.w500));
        expect(theme.backgroundColor, equals(const Color(0xFFFBFBFB)));
        expect(theme.border, isNotNull);
        expect(
          theme.borderRadius,
          equals(const BorderRadius.all(Radius.circular(4.0))),
        );
        expect(theme.offset, equals(0.0));
      });

      test('dark theme has expected properties', () {
        const theme = LabelTheme.dark;

        expect(theme.textStyle.color, equals(const Color(0xFFE5E5E5)));
        expect(theme.textStyle.fontSize, equals(12.0));
        expect(theme.textStyle.fontWeight, equals(FontWeight.w500));
        expect(theme.backgroundColor, equals(const Color(0xFF404040)));
        expect(theme.border, isNotNull);
        expect(
          theme.borderRadius,
          equals(const BorderRadius.all(Radius.circular(4.0))),
        );
        expect(theme.offset, equals(0.0));
      });
    });

    group('copyWith', () {
      test('creates copy with updated textStyle', () {
        const original = LabelTheme.light;
        final copy = original.copyWith(
          textStyle: const TextStyle(fontSize: 20.0),
        );

        expect(copy.textStyle.fontSize, equals(20.0));
        expect(copy.backgroundColor, equals(original.backgroundColor));
      });

      test('creates copy with updated backgroundColor', () {
        const original = LabelTheme.light;
        final copy = original.copyWith(backgroundColor: Colors.orange);

        expect(copy.backgroundColor, equals(Colors.orange));
        expect(copy.textStyle, equals(original.textStyle));
      });

      test('creates copy with updated border', () {
        const original = LabelTheme.light;
        const newBorder = Border.fromBorderSide(
          BorderSide(color: Colors.purple, width: 3.0),
        );
        final copy = original.copyWith(border: newBorder);

        expect(copy.border, equals(newBorder));
      });

      test('creates copy with updated borderRadius', () {
        const original = LabelTheme.light;
        const newRadius = BorderRadius.all(Radius.circular(12.0));
        final copy = original.copyWith(borderRadius: newRadius);

        expect(copy.borderRadius, equals(newRadius));
      });

      test('creates copy with updated padding', () {
        const original = LabelTheme.light;
        const newPadding = EdgeInsets.all(20.0);
        final copy = original.copyWith(padding: newPadding);

        expect(copy.padding, equals(newPadding));
      });

      test('creates copy with updated maxWidth', () {
        const original = LabelTheme.light;
        final copy = original.copyWith(maxWidth: 200.0);

        expect(copy.maxWidth, equals(200.0));
      });

      test('creates copy with updated maxLines', () {
        const original = LabelTheme.light;
        final copy = original.copyWith(maxLines: 3);

        expect(copy.maxLines, equals(3));
      });

      test('creates copy with updated offset', () {
        const original = LabelTheme.light;
        final copy = original.copyWith(offset: 10.0);

        expect(copy.offset, equals(10.0));
      });

      test('creates copy with updated labelGap', () {
        const original = LabelTheme.light;
        final copy = original.copyWith(labelGap: 15.0);

        expect(copy.labelGap, equals(15.0));
      });

      test('copyWith with no arguments returns equivalent theme', () {
        const original = LabelTheme.light;
        final copy = original.copyWith();

        expect(copy.textStyle, equals(original.textStyle));
        expect(copy.backgroundColor, equals(original.backgroundColor));
        expect(copy.border, equals(original.border));
        expect(copy.borderRadius, equals(original.borderRadius));
        expect(copy.padding, equals(original.padding));
        expect(copy.maxWidth, equals(original.maxWidth));
        expect(copy.maxLines, equals(original.maxLines));
        expect(copy.offset, equals(original.offset));
        expect(copy.labelGap, equals(original.labelGap));
      });
    });
  });

  // ===========================================================================
  // ConnectionValidation Tests
  // ===========================================================================

  group('ConnectionValidationResult', () {
    group('Construction', () {
      test('creates result with defaults', () {
        const result = ConnectionValidationResult();

        expect(result.allowed, isTrue);
        expect(result.reason, isNull);
        expect(result.showMessage, isFalse);
      });

      test('creates result with custom allowed', () {
        const result = ConnectionValidationResult(allowed: false);

        expect(result.allowed, isFalse);
      });

      test('creates result with reason', () {
        const result = ConnectionValidationResult(
          allowed: false,
          reason: 'Cannot connect',
        );

        expect(result.reason, equals('Cannot connect'));
      });

      test('creates result with showMessage', () {
        const result = ConnectionValidationResult(
          allowed: false,
          showMessage: true,
        );

        expect(result.showMessage, isTrue);
      });
    });

    group('Factory Constructors', () {
      test('ConnectionValidationResult.allow creates allowed result', () {
        const result = ConnectionValidationResult.allow();

        expect(result.allowed, isTrue);
        expect(result.reason, isNull);
        expect(result.showMessage, isFalse);
      });

      test('ConnectionValidationResult.deny creates denied result', () {
        const result = ConnectionValidationResult.deny();

        expect(result.allowed, isFalse);
        expect(result.reason, isNull);
        expect(result.showMessage, isFalse);
      });

      test('ConnectionValidationResult.deny with reason', () {
        const result = ConnectionValidationResult.deny(reason: 'Port is full');

        expect(result.allowed, isFalse);
        expect(result.reason, equals('Port is full'));
      });

      test('ConnectionValidationResult.deny with showMessage', () {
        const result = ConnectionValidationResult.deny(
          reason: 'Invalid connection',
          showMessage: true,
        );

        expect(result.allowed, isFalse);
        expect(result.reason, equals('Invalid connection'));
        expect(result.showMessage, isTrue);
      });
    });
  });

  group('ConnectionStartContext', () {
    test('creates context with required parameters', () {
      final node = createTestNodeWithOutputPort(id: 'source-node');
      final port = node.outputPorts.first;

      final context = ConnectionStartContext(
        sourceNode: node,
        sourcePort: port,
        existingConnections: ['conn-1', 'conn-2'],
      );

      expect(context.sourceNode, equals(node));
      expect(context.sourcePort, equals(port));
      expect(context.existingConnections, equals(['conn-1', 'conn-2']));
    });

    test('isOutputPort returns true for output port', () {
      final node = createTestNodeWithOutputPort(id: 'source-node');
      final port = node.outputPorts.first;

      final context = ConnectionStartContext(
        sourceNode: node,
        sourcePort: port,
        existingConnections: [],
      );

      expect(context.isOutputPort, isTrue);
      expect(context.isInputPort, isFalse);
    });

    test('isInputPort returns true for input port', () {
      final node = createTestNodeWithInputPort(id: 'source-node');
      final port = node.inputPorts.first;

      final context = ConnectionStartContext(
        sourceNode: node,
        sourcePort: port,
        existingConnections: [],
      );

      expect(context.isInputPort, isTrue);
      expect(context.isOutputPort, isFalse);
    });

    test('existingConnections is empty when no connections', () {
      final node = createTestNodeWithOutputPort(id: 'source-node');
      final port = node.outputPorts.first;

      final context = ConnectionStartContext(
        sourceNode: node,
        sourcePort: port,
        existingConnections: [],
      );

      expect(context.existingConnections, isEmpty);
    });
  });

  group('ConnectionCompleteContext', () {
    test('creates context with all required parameters', () {
      final sourceNode = createTestNodeWithOutputPort(id: 'source');
      final targetNode = createTestNodeWithInputPort(id: 'target');
      final sourcePort = sourceNode.outputPorts.first;
      final targetPort = targetNode.inputPorts.first;

      final context = ConnectionCompleteContext(
        sourceNode: sourceNode,
        sourcePort: sourcePort,
        targetNode: targetNode,
        targetPort: targetPort,
        existingSourceConnections: ['conn-1'],
        existingTargetConnections: ['conn-2'],
      );

      expect(context.sourceNode, equals(sourceNode));
      expect(context.sourcePort, equals(sourcePort));
      expect(context.targetNode, equals(targetNode));
      expect(context.targetPort, equals(targetPort));
      expect(context.existingSourceConnections, equals(['conn-1']));
      expect(context.existingTargetConnections, equals(['conn-2']));
    });

    test('isOutputToInput returns true for output-to-input connection', () {
      final sourceNode = createTestNodeWithOutputPort(id: 'source');
      final targetNode = createTestNodeWithInputPort(id: 'target');
      final sourcePort = sourceNode.outputPorts.first;
      final targetPort = targetNode.inputPorts.first;

      final context = ConnectionCompleteContext(
        sourceNode: sourceNode,
        sourcePort: sourcePort,
        targetNode: targetNode,
        targetPort: targetPort,
        existingSourceConnections: [],
        existingTargetConnections: [],
      );

      expect(context.isOutputToInput, isTrue);
      expect(context.isInputToOutput, isFalse);
    });

    test('isInputToOutput returns true for input-to-output connection', () {
      final sourceNode = createTestNodeWithInputPort(id: 'source');
      final targetNode = createTestNodeWithOutputPort(id: 'target');
      final sourcePort = sourceNode.inputPorts.first;
      final targetPort = targetNode.outputPorts.first;

      final context = ConnectionCompleteContext(
        sourceNode: sourceNode,
        sourcePort: sourcePort,
        targetNode: targetNode,
        targetPort: targetPort,
        existingSourceConnections: [],
        existingTargetConnections: [],
      );

      expect(context.isInputToOutput, isTrue);
      expect(context.isOutputToInput, isFalse);
    });

    test('isSelfConnection returns true when same node', () {
      final node = createTestNodeWithPorts(id: 'self-node');
      final inputPort = node.inputPorts.first;
      final outputPort = node.outputPorts.first;

      final context = ConnectionCompleteContext(
        sourceNode: node,
        sourcePort: outputPort,
        targetNode: node,
        targetPort: inputPort,
        existingSourceConnections: [],
        existingTargetConnections: [],
      );

      expect(context.isSelfConnection, isTrue);
    });

    test('isSelfConnection returns false for different nodes', () {
      final sourceNode = createTestNodeWithOutputPort(id: 'source');
      final targetNode = createTestNodeWithInputPort(id: 'target');

      final context = ConnectionCompleteContext(
        sourceNode: sourceNode,
        sourcePort: sourceNode.outputPorts.first,
        targetNode: targetNode,
        targetPort: targetNode.inputPorts.first,
        existingSourceConnections: [],
        existingTargetConnections: [],
      );

      expect(context.isSelfConnection, isFalse);
    });

    test('isSamePort returns true when same node and port', () {
      final node = createTestNodeWithPorts(id: 'node');
      final port = node.inputPorts.first;

      final context = ConnectionCompleteContext(
        sourceNode: node,
        sourcePort: port,
        targetNode: node,
        targetPort: port,
        existingSourceConnections: [],
        existingTargetConnections: [],
      );

      expect(context.isSamePort, isTrue);
    });

    test('isSamePort returns false for different ports on same node', () {
      final node = createTestNodeWithPorts(id: 'node');
      final inputPort = node.inputPorts.first;
      final outputPort = node.outputPorts.first;

      final context = ConnectionCompleteContext(
        sourceNode: node,
        sourcePort: outputPort,
        targetNode: node,
        targetPort: inputPort,
        existingSourceConnections: [],
        existingTargetConnections: [],
      );

      expect(context.isSamePort, isFalse);
    });
  });

  // ===========================================================================
  // ConnectionEndPoint Tests
  // ===========================================================================

  group('ConnectionEndPoint', () {
    group('Construction', () {
      test('creates endpoint with required parameters', () {
        const endpoint = ConnectionEndPoint(
          shape: MarkerShapes.circle,
          size: Size.square(10.0),
        );

        expect(endpoint.shape, equals(MarkerShapes.circle));
        expect(endpoint.size, equals(const Size.square(10.0)));
      });

      test('creates endpoint with optional color', () {
        const endpoint = ConnectionEndPoint(
          shape: MarkerShapes.triangle,
          size: Size.square(8.0),
          color: Colors.blue,
        );

        expect(endpoint.color, equals(Colors.blue));
      });

      test('creates endpoint with optional borderColor', () {
        const endpoint = ConnectionEndPoint(
          shape: MarkerShapes.diamond,
          size: Size.square(6.0),
          borderColor: Colors.red,
        );

        expect(endpoint.borderColor, equals(Colors.red));
      });

      test('creates endpoint with optional borderWidth', () {
        const endpoint = ConnectionEndPoint(
          shape: MarkerShapes.rectangle,
          size: Size.square(5.0),
          borderWidth: 2.0,
        );

        expect(endpoint.borderWidth, equals(2.0));
      });

      test('creates endpoint with all optional parameters', () {
        const endpoint = ConnectionEndPoint(
          shape: MarkerShapes.capsuleHalf,
          size: Size(10.0, 5.0),
          color: Colors.green,
          borderColor: Colors.black,
          borderWidth: 1.5,
        );

        expect(endpoint.shape, equals(MarkerShapes.capsuleHalf));
        expect(endpoint.size, equals(const Size(10.0, 5.0)));
        expect(endpoint.color, equals(Colors.green));
        expect(endpoint.borderColor, equals(Colors.black));
        expect(endpoint.borderWidth, equals(1.5));
      });
    });

    group('Predefined Endpoints', () {
      test('none endpoint has zero size', () {
        const endpoint = ConnectionEndPoint.none;

        expect(endpoint.shape, equals(MarkerShapes.none));
        expect(endpoint.size, equals(Size.zero));
      });

      test('circle endpoint has default size', () {
        const endpoint = ConnectionEndPoint.circle;

        expect(endpoint.shape, equals(MarkerShapes.circle));
        expect(endpoint.size, equals(const Size.square(5.0)));
      });

      test('triangle endpoint has default size', () {
        const endpoint = ConnectionEndPoint.triangle;

        expect(endpoint.shape, equals(MarkerShapes.triangle));
        expect(endpoint.size, equals(const Size.square(5.0)));
      });

      test('diamond endpoint has default size', () {
        const endpoint = ConnectionEndPoint.diamond;

        expect(endpoint.shape, equals(MarkerShapes.diamond));
        expect(endpoint.size, equals(const Size.square(5.0)));
      });

      test('rectangle endpoint has default size', () {
        const endpoint = ConnectionEndPoint.rectangle;

        expect(endpoint.shape, equals(MarkerShapes.rectangle));
        expect(endpoint.size, equals(const Size.square(5.0)));
      });

      test('capsuleHalf endpoint has default size', () {
        const endpoint = ConnectionEndPoint.capsuleHalf;

        expect(endpoint.shape, equals(MarkerShapes.capsuleHalf));
        expect(endpoint.size, equals(const Size.square(5.0)));
      });
    });

    group('copyWith', () {
      test('creates copy with updated shape', () {
        const original = ConnectionEndPoint.circle;
        final copy = original.copyWith(shape: MarkerShapes.triangle);

        expect(copy.shape, equals(MarkerShapes.triangle));
        expect(copy.size, equals(original.size));
      });

      test('creates copy with updated size', () {
        const original = ConnectionEndPoint.circle;
        final copy = original.copyWith(size: const Size.square(12.0));

        expect(copy.size, equals(const Size.square(12.0)));
        expect(copy.shape, equals(original.shape));
      });

      test('creates copy with updated color', () {
        const original = ConnectionEndPoint.circle;
        final copy = original.copyWith(color: Colors.purple);

        expect(copy.color, equals(Colors.purple));
      });

      test('creates copy with updated borderColor', () {
        const original = ConnectionEndPoint.circle;
        final copy = original.copyWith(borderColor: Colors.yellow);

        expect(copy.borderColor, equals(Colors.yellow));
      });

      test('creates copy with updated borderWidth', () {
        const original = ConnectionEndPoint.circle;
        final copy = original.copyWith(borderWidth: 3.0);

        expect(copy.borderWidth, equals(3.0));
      });

      test('copyWith with no arguments returns equivalent endpoint', () {
        const original = ConnectionEndPoint(
          shape: MarkerShapes.diamond,
          size: Size.square(8.0),
          color: Colors.green,
          borderColor: Colors.black,
          borderWidth: 1.0,
        );
        final copy = original.copyWith();

        expect(copy, equals(original));
      });
    });

    group('Equality', () {
      test('endpoints with same properties are equal', () {
        const endpoint1 = ConnectionEndPoint(
          shape: MarkerShapes.circle,
          size: Size.square(5.0),
          color: Colors.blue,
        );
        const endpoint2 = ConnectionEndPoint(
          shape: MarkerShapes.circle,
          size: Size.square(5.0),
          color: Colors.blue,
        );

        expect(endpoint1, equals(endpoint2));
        expect(endpoint1.hashCode, equals(endpoint2.hashCode));
      });

      test('endpoints with different properties are not equal', () {
        const endpoint1 = ConnectionEndPoint.circle;
        const endpoint2 = ConnectionEndPoint.triangle;

        expect(endpoint1, isNot(equals(endpoint2)));
      });

      test('predefined endpoints are equal to equivalent custom endpoints', () {
        const custom = ConnectionEndPoint(
          shape: MarkerShapes.circle,
          size: Size.square(5.0),
        );

        expect(ConnectionEndPoint.circle, equals(custom));
      });
    });

    group('toString', () {
      test('returns readable representation', () {
        const endpoint = ConnectionEndPoint(
          shape: MarkerShapes.triangle,
          size: Size.square(8.0),
          color: Colors.red,
        );

        final str = endpoint.toString();

        expect(str, contains('ConnectionEndPoint'));
        expect(str, contains('shape:'));
        expect(str, contains('size:'));
      });
    });

    group('JSON Serialization', () {
      test('toJson produces valid JSON', () {
        const endpoint = ConnectionEndPoint(
          shape: MarkerShapes.diamond,
          size: Size.square(7.0),
        );

        final json = endpoint.toJson();

        expect(json, isA<Map<String, dynamic>>());
        expect(json['size'], isNotNull);
        expect(json['shape'], isNotNull);
      });

      test('round-trip serialization preserves size', () {
        const original = ConnectionEndPoint(
          shape: MarkerShapes.circle,
          size: Size.square(10.0),
        );

        final json = original.toJson();
        // Ensure shape is serialized as a Map for fromJson
        if (json['shape'] is MarkerShape) {
          json['shape'] = (json['shape'] as MarkerShape).toJson();
        }
        final restored = ConnectionEndPoint.fromJson(json);

        expect(restored.size, equals(original.size));
        expect(restored.shape.typeName, equals(original.shape.typeName));
      });
    });
  });

  // ===========================================================================
  // Connection with Labels Tests
  // ===========================================================================

  group('Connection with Labels', () {
    test('creates connection with startLabel', () {
      final connection = Connection(
        id: 'conn-1',
        sourceNodeId: 'node-a',
        sourcePortId: 'output-1',
        targetNodeId: 'node-b',
        targetPortId: 'input-1',
        startLabel: ConnectionLabel.start(text: 'Start'),
      );

      expect(connection.startLabel, isNotNull);
      expect(connection.startLabel!.text, equals('Start'));
      expect(connection.startLabel!.anchor, equals(0.0));
    });

    test('creates connection with center label', () {
      final connection = Connection(
        id: 'conn-1',
        sourceNodeId: 'node-a',
        sourcePortId: 'output-1',
        targetNodeId: 'node-b',
        targetPortId: 'input-1',
        label: ConnectionLabel.center(text: 'Processing'),
      );

      expect(connection.label, isNotNull);
      expect(connection.label!.text, equals('Processing'));
      expect(connection.label!.anchor, equals(0.5));
    });

    test('creates connection with endLabel', () {
      final connection = Connection(
        id: 'conn-1',
        sourceNodeId: 'node-a',
        sourcePortId: 'output-1',
        targetNodeId: 'node-b',
        targetPortId: 'input-1',
        endLabel: ConnectionLabel.end(text: 'Complete'),
      );

      expect(connection.endLabel, isNotNull);
      expect(connection.endLabel!.text, equals('Complete'));
      expect(connection.endLabel!.anchor, equals(1.0));
    });

    test('creates connection with all three labels', () {
      final connection = Connection(
        id: 'conn-1',
        sourceNodeId: 'node-a',
        sourcePortId: 'output-1',
        targetNodeId: 'node-b',
        targetPortId: 'input-1',
        startLabel: ConnectionLabel.start(text: 'Start'),
        label: ConnectionLabel.center(text: 'Middle'),
        endLabel: ConnectionLabel.end(text: 'End'),
      );

      expect(connection.startLabel!.text, equals('Start'));
      expect(connection.label!.text, equals('Middle'));
      expect(connection.endLabel!.text, equals('End'));
    });

    test('labels getter returns all non-null labels in order', () {
      final connection = Connection(
        id: 'conn-1',
        sourceNodeId: 'node-a',
        sourcePortId: 'output-1',
        targetNodeId: 'node-b',
        targetPortId: 'input-1',
        startLabel: ConnectionLabel.start(text: 'A'),
        label: ConnectionLabel.center(text: 'B'),
        endLabel: ConnectionLabel.end(text: 'C'),
      );

      final labels = connection.labels;

      expect(labels.length, equals(3));
      expect(labels[0].text, equals('A'));
      expect(labels[1].text, equals('B'));
      expect(labels[2].text, equals('C'));
    });

    test('labels getter returns only set labels', () {
      final connection = Connection(
        id: 'conn-1',
        sourceNodeId: 'node-a',
        sourcePortId: 'output-1',
        targetNodeId: 'node-b',
        targetPortId: 'input-1',
        label: ConnectionLabel.center(text: 'Only Center'),
      );

      final labels = connection.labels;

      expect(labels.length, equals(1));
      expect(labels[0].text, equals('Only Center'));
    });

    test('labels getter returns empty list when no labels set', () {
      final connection = Connection(
        id: 'conn-1',
        sourceNodeId: 'node-a',
        sourcePortId: 'output-1',
        targetNodeId: 'node-b',
        targetPortId: 'input-1',
      );

      expect(connection.labels, isEmpty);
    });

    test('labels can be updated after creation', () {
      final connection = Connection(
        id: 'conn-1',
        sourceNodeId: 'node-a',
        sourcePortId: 'output-1',
        targetNodeId: 'node-b',
        targetPortId: 'input-1',
      );

      connection.startLabel = ConnectionLabel.start(text: 'New Start');
      connection.label = ConnectionLabel.center(text: 'New Center');
      connection.endLabel = ConnectionLabel.end(text: 'New End');

      expect(connection.startLabel!.text, equals('New Start'));
      expect(connection.label!.text, equals('New Center'));
      expect(connection.endLabel!.text, equals('New End'));
    });

    test('labels can be removed by setting to null', () {
      final connection = Connection(
        id: 'conn-1',
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

      expect(connection.labels, isEmpty);
    });

    test('connection JSON serialization includes labels', () {
      final connection = Connection(
        id: 'json-conn',
        sourceNodeId: 'node-a',
        sourcePortId: 'output-1',
        targetNodeId: 'node-b',
        targetPortId: 'input-1',
        startLabel: ConnectionLabel.start(text: 'S'),
        label: ConnectionLabel.center(text: 'C'),
        endLabel: ConnectionLabel.end(text: 'E'),
      );

      final json = connection.toJson((data) => data);

      expect(json['startLabel'], isNotNull);
      expect(json['startLabel']['text'], equals('S'));
      expect(json['label'], isNotNull);
      expect(json['label']['text'], equals('C'));
      expect(json['endLabel'], isNotNull);
      expect(json['endLabel']['text'], equals('E'));
    });

    test('connection JSON deserialization restores labels', () {
      final json = {
        'id': 'restored-conn',
        'sourceNodeId': 'node-a',
        'sourcePortId': 'output-1',
        'targetNodeId': 'node-b',
        'targetPortId': 'input-1',
        'startLabel': {
          'text': 'Start',
          'anchor': 0.0,
          'offset': 5.0,
          'id': 'sl',
        },
        'label': {'text': 'Center', 'anchor': 0.5, 'offset': 0.0, 'id': 'cl'},
        'endLabel': {'text': 'End', 'anchor': 1.0, 'offset': -5.0, 'id': 'el'},
      };

      final connection = Connection<dynamic>.fromJson(json, (j) => j);

      expect(connection.startLabel!.text, equals('Start'));
      expect(connection.startLabel!.anchor, equals(0.0));
      expect(connection.startLabel!.offset, equals(5.0));
      expect(connection.label!.text, equals('Center'));
      expect(connection.endLabel!.text, equals('End'));
      expect(connection.endLabel!.offset, equals(-5.0));
    });
  });

  // ===========================================================================
  // Custom Validation Implementation Tests
  // ===========================================================================

  group('Custom Validation Implementation', () {
    test('can implement custom validation logic', () {
      ConnectionValidationResult validateConnection<T>(
        ConnectionCompleteContext<T> context,
      ) {
        // Prevent self-connections
        if (context.isSelfConnection) {
          return const ConnectionValidationResult.deny(
            reason: 'Self-connections not allowed',
            showMessage: true,
          );
        }

        // Only allow output-to-input
        if (!context.isOutputToInput) {
          return const ConnectionValidationResult.deny(
            reason: 'Must connect output to input',
          );
        }

        return const ConnectionValidationResult.allow();
      }

      // Test valid connection
      final sourceNode = createTestNodeWithOutputPort(id: 'source');
      final targetNode = createTestNodeWithInputPort(id: 'target');

      final validContext = ConnectionCompleteContext(
        sourceNode: sourceNode,
        sourcePort: sourceNode.outputPorts.first,
        targetNode: targetNode,
        targetPort: targetNode.inputPorts.first,
        existingSourceConnections: [],
        existingTargetConnections: [],
      );

      final validResult = validateConnection(validContext);
      expect(validResult.allowed, isTrue);

      // Test self-connection (invalid)
      final selfNode = createTestNodeWithPorts(id: 'self');

      final selfContext = ConnectionCompleteContext(
        sourceNode: selfNode,
        sourcePort: selfNode.outputPorts.first,
        targetNode: selfNode,
        targetPort: selfNode.inputPorts.first,
        existingSourceConnections: [],
        existingTargetConnections: [],
      );

      final selfResult = validateConnection(selfContext);
      expect(selfResult.allowed, isFalse);
      expect(selfResult.reason, equals('Self-connections not allowed'));
      expect(selfResult.showMessage, isTrue);
    });

    test('can validate max connections per port', () {
      ConnectionValidationResult validateMaxConnections<T>(
        ConnectionStartContext<T> context, {
        int maxConnections = 1,
      }) {
        if (context.existingConnections.length >= maxConnections) {
          return ConnectionValidationResult.deny(
            reason: 'Port already has $maxConnections connection(s)',
            showMessage: true,
          );
        }
        return const ConnectionValidationResult.allow();
      }

      final node = createTestNodeWithOutputPort(id: 'node');

      // Empty connections - should allow
      final emptyContext = ConnectionStartContext(
        sourceNode: node,
        sourcePort: node.outputPorts.first,
        existingConnections: [],
      );
      expect(validateMaxConnections(emptyContext).allowed, isTrue);

      // One existing connection with max 1 - should deny
      final fullContext = ConnectionStartContext(
        sourceNode: node,
        sourcePort: node.outputPorts.first,
        existingConnections: ['conn-1'],
      );
      expect(validateMaxConnections(fullContext).allowed, isFalse);

      // One existing connection with max 2 - should allow
      expect(
        validateMaxConnections(fullContext, maxConnections: 2).allowed,
        isTrue,
      );
    });
  });
}
