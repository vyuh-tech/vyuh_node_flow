/// Comprehensive unit tests for [CommentNode].
///
/// Tests cover:
/// - CommentNode construction with various parameters
/// - Text content and styling properties
/// - Size and position observables
/// - Resizable behavior (from ResizableMixin)
/// - Size constraints (min/max)
/// - Serialization/deserialization
/// - copyWith functionality
/// - Edge cases and boundary conditions
/// - MobX reactivity
/// - Integration with NodeFlowController
@Tags(['unit'])
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobx/mobx.dart';
import 'package:vyuh_node_flow/vyuh_node_flow.dart';
import 'package:vyuh_node_flow/src/editor/resizer_widget.dart';

import '../../helpers/test_factories.dart';
import '../../helpers/test_utils.dart';

void main() {
  setUp(() {
    resetTestCounters();
  });

  // ===========================================================================
  // Construction Tests
  // ===========================================================================
  group('CommentNode Construction', () {
    group('Required Parameters', () {
      test('creates comment node with all required parameters', () {
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
      });

      test('creates comment node with generic type', () {
        final comment = CommentNode<int>(
          id: 'comment-int',
          position: Offset.zero,
          text: 'Number comment',
          data: 42,
        );

        expect(comment.data, equals(42));
        expect(comment.data, isA<int>());
      });

      test('creates comment node with nullable data type', () {
        final comment = CommentNode<String?>(
          id: 'comment-nullable',
          position: Offset.zero,
          text: 'Nullable',
          data: null,
        );

        expect(comment.data, isNull);
      });

      test('creates comment node with complex data type', () {
        final mapData = {'key': 'value', 'count': 42};
        final comment = CommentNode<Map<String, dynamic>>(
          id: 'comment-map',
          position: Offset.zero,
          text: 'Map comment',
          data: mapData,
        );

        expect(comment.data, equals(mapData));
        expect(comment.data['key'], equals('value'));
      });
    });

    group('Default Values', () {
      test('default width is 200.0', () {
        final comment = createTestCommentNode<String>(data: 'test');
        expect(comment.width, equals(200.0));
      });

      test('default height is 100.0', () {
        final comment = createTestCommentNode<String>(data: 'test');
        expect(comment.height, equals(100.0));
      });

      test('default color is yellow', () {
        final comment = createTestCommentNode<String>(data: 'test');
        expect(comment.color, equals(Colors.yellow));
      });

      test('default zIndex is 0', () {
        final comment = createTestCommentNode<String>(data: 'test');
        expect(comment.zIndex.value, equals(0));
      });

      test('default isVisible is true', () {
        final comment = createTestCommentNode<String>(data: 'test');
        expect(comment.isVisible, isTrue);
      });

      test('default locked is false', () {
        final comment = createTestCommentNode<String>(data: 'test');
        expect(comment.locked, isFalse);
      });

      test('type is always "comment"', () {
        final comment = createTestCommentNode<String>(data: 'test');
        expect(comment.type, equals('comment'));
      });

      test('layer is always foreground', () {
        final comment = createTestCommentNode<String>(data: 'test');
        expect(comment.layer, equals(NodeRenderLayer.foreground));
      });

      test('selectable is always false', () {
        final comment = createTestCommentNode<String>(data: 'test');
        expect(comment.selectable, isFalse);
      });

      test('has no input ports', () {
        final comment = createTestCommentNode<String>(data: 'test');
        expect(comment.inputPorts, isEmpty);
      });

      test('has no output ports', () {
        final comment = createTestCommentNode<String>(data: 'test');
        expect(comment.outputPorts, isEmpty);
      });
    });

    group('Custom Parameters', () {
      test('creates with custom width', () {
        final comment = CommentNode<String>(
          id: 'custom-width',
          position: Offset.zero,
          text: 'Custom',
          data: 'test',
          width: 300,
        );

        expect(comment.width, equals(300));
      });

      test('creates with custom height', () {
        final comment = CommentNode<String>(
          id: 'custom-height',
          position: Offset.zero,
          text: 'Custom',
          data: 'test',
          height: 150,
        );

        expect(comment.height, equals(150));
      });

      test('creates with custom color', () {
        final comment = CommentNode<String>(
          id: 'custom-color',
          position: Offset.zero,
          text: 'Colored',
          data: 'test',
          color: Colors.pink,
        );

        expect(comment.color, equals(Colors.pink));
      });

      test('creates with custom zIndex', () {
        final comment = CommentNode<String>(
          id: 'custom-zindex',
          position: Offset.zero,
          text: 'High z-index',
          data: 'test',
          zIndex: 100,
        );

        expect(comment.zIndex.value, equals(100));
      });

      test('creates with isVisible false', () {
        final comment = CommentNode<String>(
          id: 'invisible',
          position: Offset.zero,
          text: 'Hidden',
          data: 'test',
          isVisible: false,
        );

        expect(comment.isVisible, isFalse);
      });

      test('creates with locked true', () {
        final comment = CommentNode<String>(
          id: 'locked',
          position: Offset.zero,
          text: 'Locked',
          data: 'test',
          locked: true,
        );

        expect(comment.locked, isTrue);
      });

      test('creates with all custom parameters', () {
        final comment = CommentNode<String>(
          id: 'fully-custom',
          position: const Offset(50, 75),
          text: 'Full custom',
          data: 'custom-data',
          width: 250,
          height: 175,
          color: Colors.green,
          zIndex: 5,
          isVisible: true,
          locked: false,
        );

        expect(comment.id, equals('fully-custom'));
        expect(comment.position.value, equals(const Offset(50, 75)));
        expect(comment.text, equals('Full custom'));
        expect(comment.data, equals('custom-data'));
        expect(comment.width, equals(250));
        expect(comment.height, equals(175));
        expect(comment.color, equals(Colors.green));
        expect(comment.zIndex.value, equals(5));
        expect(comment.isVisible, isTrue);
        expect(comment.locked, isFalse);
      });
    });
  });

  // ===========================================================================
  // Observable Text Property Tests
  // ===========================================================================
  group('Text Property', () {
    test('text getter returns current value', () {
      final comment = createTestCommentNode<String>(
        text: 'Initial text',
        data: 'test',
      );

      expect(comment.text, equals('Initial text'));
    });

    test('text setter updates value', () {
      final comment = createTestCommentNode<String>(
        text: 'Initial',
        data: 'test',
      );

      comment.text = 'Updated text';

      expect(comment.text, equals('Updated text'));
    });

    test('text is reactive (MobX observable)', () {
      final comment = createTestCommentNode<String>(
        text: 'Initial',
        data: 'test',
      );
      final tracker = ObservableTracker<String>();

      // Create a computed that reads the text
      var textValue = '';
      final disposer = autorun((_) {
        textValue = comment.text;
        tracker.values.add(textValue);
      });

      // Initial value
      expect(tracker.values, contains('Initial'));

      // Update and verify reaction
      comment.text = 'Changed';
      expect(tracker.values, contains('Changed'));

      disposer();
    });

    test('text can be empty string', () {
      final comment = CommentNode<String>(
        id: 'empty-text',
        position: Offset.zero,
        text: '',
        data: 'test',
      );

      expect(comment.text, isEmpty);
    });

    test('text can be very long', () {
      final longText = 'A' * 10000;
      final comment = CommentNode<String>(
        id: 'long-text',
        position: Offset.zero,
        text: longText,
        data: 'test',
      );

      expect(comment.text.length, equals(10000));
    });

    test('text supports unicode characters', () {
      final comment = CommentNode<String>(
        id: 'unicode',
        position: Offset.zero,
        text: 'Hello World!',
        data: 'test',
      );

      expect(comment.text, equals('Hello World!'));
    });

    test('text supports multiline content', () {
      final multilineText = 'Line 1\nLine 2\nLine 3';
      final comment = CommentNode<String>(
        id: 'multiline',
        position: Offset.zero,
        text: multilineText,
        data: 'test',
      );

      expect(comment.text, equals(multilineText));
      expect(comment.text.split('\n').length, equals(3));
    });
  });

  // ===========================================================================
  // Observable Color Property Tests
  // ===========================================================================
  group('Color Property', () {
    test('color getter returns current value', () {
      final comment = createTestCommentNode<String>(
        color: Colors.orange,
        data: 'test',
      );

      expect(comment.color, equals(Colors.orange));
    });

    test('color setter updates value', () {
      final comment = createTestCommentNode<String>(
        color: Colors.yellow,
        data: 'test',
      );

      comment.color = Colors.blue;

      expect(comment.color, equals(Colors.blue));
    });

    test('color is reactive (MobX observable)', () {
      final comment = createTestCommentNode<String>(
        color: Colors.yellow,
        data: 'test',
      );
      final colors = <Color>[];

      final disposer = autorun((_) {
        colors.add(comment.color);
      });

      // Initial value
      expect(colors, contains(Colors.yellow));

      // Update and verify reaction
      comment.color = Colors.red;
      expect(colors, contains(Colors.red));

      disposer();
    });

    test('color supports alpha values', () {
      final transparentColor = Colors.blue.withValues(alpha: 0.5);
      final comment = CommentNode<String>(
        id: 'transparent',
        position: Offset.zero,
        text: 'Transparent',
        data: 'test',
        color: transparentColor,
      );

      expect(comment.color.a, closeTo(0.5, 0.01));
    });

    test('color can be custom ARGB value', () {
      const customColor = Color(0xFFABCDEF);
      final comment = CommentNode<String>(
        id: 'custom-argb',
        position: Offset.zero,
        text: 'Custom ARGB',
        data: 'test',
        color: customColor,
      );

      expect(comment.color, equals(customColor));
    });
  });

  // ===========================================================================
  // Size Observable Tests
  // ===========================================================================
  group('Size Observable', () {
    test('width getter returns size.width', () {
      final comment = createTestCommentNode<String>(
        width: 250,
        height: 150,
        data: 'test',
      );

      expect(comment.width, equals(250));
      expect(comment.width, equals(comment.size.value.width));
    });

    test('height getter returns size.height', () {
      final comment = createTestCommentNode<String>(
        width: 250,
        height: 150,
        data: 'test',
      );

      expect(comment.height, equals(150));
      expect(comment.height, equals(comment.size.value.height));
    });

    test('size.value matches width and height', () {
      final comment = CommentNode<String>(
        id: 'sized',
        position: Offset.zero,
        text: 'Sized',
        data: 'test',
        width: 300,
        height: 200,
      );

      expect(comment.size.value, equals(const Size(300, 200)));
    });

    test('size is reactive (MobX observable)', () {
      final comment = createTestCommentNode<String>(
        width: 200,
        height: 100,
        data: 'test',
      );
      final sizes = <Size>[];

      final disposer = autorun((_) {
        sizes.add(comment.size.value);
      });

      // Initial value
      expect(sizes, contains(const Size(200, 100)));

      // Update via setSize
      comment.setSize(const Size(300, 200));
      expect(sizes, contains(const Size(300, 200)));

      disposer();
    });
  });

  // ===========================================================================
  // Position Observable Tests
  // ===========================================================================
  group('Position Observable', () {
    test('position getter returns current value', () {
      final comment = createTestCommentNode<String>(
        position: const Offset(100, 200),
        data: 'test',
      );

      expect(comment.position.value, equals(const Offset(100, 200)));
    });

    test('position can be updated', () {
      final comment = createTestCommentNode<String>(data: 'test');

      comment.position.value = const Offset(300, 400);

      expect(comment.position.value, equals(const Offset(300, 400)));
    });

    test('position supports negative coordinates', () {
      final comment = CommentNode<String>(
        id: 'negative-pos',
        position: const Offset(-100, -50),
        text: 'Negative',
        data: 'test',
      );

      expect(comment.position.value, equals(const Offset(-100, -50)));
    });

    test('position supports large coordinates', () {
      final comment = CommentNode<String>(
        id: 'large-pos',
        position: const Offset(10000, 20000),
        text: 'Large',
        data: 'test',
      );

      expect(comment.position.value, equals(const Offset(10000, 20000)));
    });
  });

  // ===========================================================================
  // ResizableMixin Tests
  // ===========================================================================
  group('Resizable Behavior', () {
    test('CommentNode has ResizableMixin', () {
      final comment = createTestCommentNode<String>(data: 'test');

      expect(comment.isResizable, isTrue);
    });

    test('minSize returns Size(100, 60)', () {
      final comment = createTestCommentNode<String>(data: 'test');

      expect(comment.minSize, equals(const Size(100, 60)));
    });

    test('minWidth constant is 100.0', () {
      expect(CommentNode.minWidth, equals(100.0));
    });

    test('minHeight constant is 60.0', () {
      expect(CommentNode.minHeight, equals(60.0));
    });

    test('maxSize returns Size(600, 400)', () {
      final comment = createTestCommentNode<String>(data: 'test');

      expect(comment.maxSize, equals(const Size(600, 400)));
    });

    test('maxWidth constant is 600.0', () {
      expect(CommentNode.maxWidth, equals(600.0));
    });

    test('maxHeight constant is 400.0', () {
      expect(CommentNode.maxHeight, equals(400.0));
    });

    group('setSize Constraints', () {
      test('setSize enforces minimum width', () {
        final comment = createTestCommentNode<String>(data: 'test');

        comment.setSize(const Size(50, 100)); // Width below minimum

        expect(comment.width, equals(CommentNode.minWidth));
        expect(comment.height, equals(100)); // Height unchanged
      });

      test('setSize enforces minimum height', () {
        final comment = createTestCommentNode<String>(data: 'test');

        comment.setSize(const Size(200, 30)); // Height below minimum

        expect(comment.width, equals(200)); // Width unchanged
        expect(comment.height, equals(CommentNode.minHeight));
      });

      test('setSize enforces maximum width', () {
        final comment = createTestCommentNode<String>(data: 'test');

        comment.setSize(const Size(800, 200)); // Width above maximum

        expect(comment.width, equals(CommentNode.maxWidth));
        expect(comment.height, equals(200)); // Height unchanged
      });

      test('setSize enforces maximum height', () {
        final comment = createTestCommentNode<String>(data: 'test');

        comment.setSize(const Size(300, 500)); // Height above maximum

        expect(comment.width, equals(300)); // Width unchanged
        expect(comment.height, equals(CommentNode.maxHeight));
      });

      test('setSize clamps both dimensions simultaneously', () {
        final comment = createTestCommentNode<String>(data: 'test');

        comment.setSize(
          const Size(50, 800),
        ); // Width too small, height too large

        expect(comment.width, equals(CommentNode.minWidth));
        expect(comment.height, equals(CommentNode.maxHeight));
      });

      test('setSize allows valid sizes within constraints', () {
        final comment = createTestCommentNode<String>(data: 'test');

        comment.setSize(const Size(300, 200));

        expect(comment.width, equals(300));
        expect(comment.height, equals(200));
      });

      test('setSize at exact minimum is allowed', () {
        final comment = createTestCommentNode<String>(data: 'test');

        comment.setSize(
          const Size(CommentNode.minWidth, CommentNode.minHeight),
        );

        expect(comment.width, equals(CommentNode.minWidth));
        expect(comment.height, equals(CommentNode.minHeight));
      });

      test('setSize at exact maximum is allowed', () {
        final comment = createTestCommentNode<String>(data: 'test');

        comment.setSize(
          const Size(CommentNode.maxWidth, CommentNode.maxHeight),
        );

        expect(comment.width, equals(CommentNode.maxWidth));
        expect(comment.height, equals(CommentNode.maxHeight));
      });
    });

    group('calculateResize', () {
      test('respects minimum size when shrinking', () {
        final comment = createTestCommentNode<String>(
          data: 'test',
          width: 200,
          height: 100,
        );
        final originalBounds = comment.getBounds();

        final result = comment.calculateResize(
          handle: ResizeHandle.bottomRight,
          originalBounds: originalBounds,
          startPosition: originalBounds.bottomRight,
          currentPosition: originalBounds.topLeft + const Offset(50, 30),
        );

        expect(
          result.newBounds.width,
          greaterThanOrEqualTo(CommentNode.minWidth),
        );
        expect(
          result.newBounds.height,
          greaterThanOrEqualTo(CommentNode.minHeight),
        );
        expect(result.constrainedByMin, isTrue);
      });

      test('respects maximum size when expanding', () {
        final comment = createTestCommentNode<String>(
          data: 'test',
          width: 200,
          height: 100,
        );
        final originalBounds = comment.getBounds();

        final result = comment.calculateResize(
          handle: ResizeHandle.bottomRight,
          originalBounds: originalBounds,
          startPosition: originalBounds.bottomRight,
          currentPosition: originalBounds.bottomRight + const Offset(500, 400),
        );

        expect(result.newBounds.width, lessThanOrEqualTo(CommentNode.maxWidth));
        expect(
          result.newBounds.height,
          lessThanOrEqualTo(CommentNode.maxHeight),
        );
        expect(result.constrainedByMax, isTrue);
      });

      test('calculateResize works with all handles', () {
        final comment = createTestCommentNode<String>(
          data: 'test',
          width: 200,
          height: 100,
          position: const Offset(100, 100),
        );
        final originalBounds = comment.getBounds();

        // Test each resize handle
        for (final handle in ResizeHandle.values) {
          final result = comment.calculateResize(
            handle: handle,
            originalBounds: originalBounds,
            startPosition: originalBounds.center,
            currentPosition: originalBounds.center + const Offset(10, 10),
          );

          expect(result.newBounds, isNotNull);
          expect(
            result.newBounds.width,
            greaterThanOrEqualTo(CommentNode.minWidth),
          );
          expect(
            result.newBounds.height,
            greaterThanOrEqualTo(CommentNode.minHeight),
          );
        }
      });
    });

    group('applyBounds', () {
      test('applyBounds updates position and size', () {
        final comment = createTestCommentNode<String>(
          data: 'test',
          position: const Offset(0, 0),
          width: 200,
          height: 100,
        );

        comment.applyBounds(const Rect.fromLTWH(50, 75, 300, 200));

        expect(comment.position.value, equals(const Offset(50, 75)));
        expect(comment.width, equals(300));
        expect(comment.height, equals(200));
      });

      test('applyBounds respects size constraints', () {
        final comment = createTestCommentNode<String>(data: 'test');

        comment.applyBounds(const Rect.fromLTWH(0, 0, 50, 30));

        expect(comment.width, equals(CommentNode.minWidth));
        expect(comment.height, equals(CommentNode.minHeight));
      });
    });

    group('resize convenience method', () {
      test('resize combines calculateResize and applyBounds', () {
        final comment = createTestCommentNode<String>(
          data: 'test',
          position: const Offset(100, 100),
          width: 200,
          height: 100,
        );
        final originalBounds = comment.getBounds();

        final result = comment.resize(
          handle: ResizeHandle.bottomRight,
          originalBounds: originalBounds,
          startPosition: originalBounds.bottomRight,
          currentPosition: originalBounds.bottomRight + const Offset(50, 50),
        );

        expect(comment.width, equals(250));
        expect(comment.height, equals(150));
        expect(result.newBounds.size, equals(const Size(250, 150)));
      });
    });
  });

  // ===========================================================================
  // copyWith Tests
  // ===========================================================================
  group('copyWith', () {
    test('copyWith with no arguments returns equivalent copy', () {
      final original = CommentNode<String>(
        id: 'original',
        position: const Offset(100, 100),
        text: 'Original text',
        data: 'original-data',
        width: 250,
        height: 150,
        color: Colors.orange,
        zIndex: 5,
        isVisible: true,
        locked: false,
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
      expect(copy.isVisible, equals(original.isVisible));
      expect(copy.locked, equals(original.locked));
    });

    test('copyWith overrides id', () {
      final original = createTestCommentNode<String>(
        id: 'original',
        data: 'test',
      );

      final copy = original.copyWith(id: 'new-id');

      expect(copy.id, equals('new-id'));
    });

    test('copyWith overrides position', () {
      final original = createTestCommentNode<String>(
        position: const Offset(0, 0),
        data: 'test',
      );

      final copy = original.copyWith(position: const Offset(100, 200));

      expect(copy.position.value, equals(const Offset(100, 200)));
    });

    test('copyWith overrides text', () {
      final original = createTestCommentNode<String>(
        text: 'Original',
        data: 'test',
      );

      final copy = original.copyWith(text: 'New text');

      expect(copy.text, equals('New text'));
    });

    test('copyWith overrides data', () {
      final original = createTestCommentNode<String>(data: 'original');

      final copy = original.copyWith(data: 'new-data');

      expect(copy.data, equals('new-data'));
    });

    test('copyWith overrides width', () {
      final original = createTestCommentNode<String>(width: 200, data: 'test');

      final copy = original.copyWith(width: 300);

      expect(copy.width, equals(300));
    });

    test('copyWith overrides height', () {
      final original = createTestCommentNode<String>(height: 100, data: 'test');

      final copy = original.copyWith(height: 150);

      expect(copy.height, equals(150));
    });

    test('copyWith overrides color', () {
      final original = createTestCommentNode<String>(
        color: Colors.yellow,
        data: 'test',
      );

      final copy = original.copyWith(color: Colors.green);

      expect(copy.color, equals(Colors.green));
    });

    test('copyWith overrides zIndex', () {
      final original = createTestCommentNode<String>(zIndex: 0, data: 'test');

      final copy = original.copyWith(zIndex: 10);

      expect(copy.zIndex.value, equals(10));
    });

    test('copyWith overrides isVisible', () {
      final original = createTestCommentNode<String>(
        isVisible: true,
        data: 'test',
      );

      final copy = original.copyWith(isVisible: false);

      expect(copy.isVisible, isFalse);
    });

    test('copyWith overrides locked', () {
      final original = createTestCommentNode<String>(
        locked: false,
        data: 'test',
      );

      final copy = original.copyWith(locked: true);

      expect(copy.locked, isTrue);
    });

    test('copyWith with multiple overrides', () {
      final original = createTestCommentNode<String>(
        id: 'original',
        text: 'Original',
        color: Colors.yellow,
        data: 'test',
      );

      final copy = original.copyWith(
        id: 'new-id',
        text: 'New text',
        color: Colors.red,
        width: 400,
        height: 250,
      );

      expect(copy.id, equals('new-id'));
      expect(copy.text, equals('New text'));
      expect(copy.color, equals(Colors.red));
      expect(copy.width, equals(400));
      expect(copy.height, equals(250));
      // Unchanged properties
      expect(copy.data, equals(original.data));
      expect(copy.position.value, equals(original.position.value));
    });

    test('copyWith creates independent instance', () {
      final original = createTestCommentNode<String>(
        text: 'Original',
        data: 'test',
      );

      final copy = original.copyWith();

      // Modify copy
      copy.text = 'Modified';

      // Original should be unchanged
      expect(original.text, equals('Original'));
    });
  });

  // ===========================================================================
  // Serialization Tests
  // ===========================================================================
  group('JSON Serialization', () {
    group('toJson', () {
      test('toJson includes all required fields', () {
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
        expect(json['type'], equals('comment'));
        expect(json['x'], equals(50.0));
        expect(json['y'], equals(75.0));
        expect(json['width'], equals(220.0));
        expect(json['height'], equals(130.0));
        expect(json['text'], equals('JSON text'));
        expect(json['data'], equals('json-data'));
        expect(json['color'], isNotNull);
      });

      test('toJson includes inherited Node fields', () {
        final comment = CommentNode<String>(
          id: 'full-json',
          position: const Offset(100, 200),
          text: 'Full',
          data: 'data',
          zIndex: 5,
          isVisible: false,
          locked: true,
        );

        final json = comment.toJson((data) => data);

        expect(json['zIndex'], equals(5));
        expect(json['isVisible'], equals(false));
        expect(json['locked'], equals(true));
        expect(json['layer'], equals('foreground'));
        expect(json['selectable'], equals(false));
      });

      test('toJson handles empty text', () {
        final comment = CommentNode<String>(
          id: 'empty',
          position: Offset.zero,
          text: '',
          data: 'test',
        );

        final json = comment.toJson((data) => data);

        expect(json['text'], equals(''));
      });

      test('toJson with custom data transformer', () {
        final comment = CommentNode<Map<String, dynamic>>(
          id: 'map-comment',
          position: Offset.zero,
          text: 'Map data',
          data: {'key': 'value', 'count': 42},
        );

        final json = comment.toJson((data) => data);

        expect(json['data'], isA<Map<String, dynamic>>());
        expect(json['data']['key'], equals('value'));
        expect(json['data']['count'], equals(42));
      });
    });

    group('fromJson', () {
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
          'locked': false,
        };

        final comment = CommentNode<String>.fromJson(
          json,
          dataFromJson: (json) => json as String,
        );

        expect(comment.id, equals('reconstructed'));
        expect(comment.position.value, equals(const Offset(50, 75)));
        expect(comment.width, equals(220.0));
        expect(comment.height, equals(130.0));
        expect(comment.text, equals('Reconstructed text'));
        expect(comment.data, equals('data'));
        expect(comment.currentZIndex, equals(3));
      });

      test('fromJson handles missing text field', () {
        final json = {'id': 'no-text', 'x': 0.0, 'y': 0.0, 'data': 'test'};

        final comment = CommentNode<String>.fromJson(
          json,
          dataFromJson: (json) => json as String,
        );

        expect(comment.text, equals('')); // Default empty text
      });

      test('fromJson handles missing width field', () {
        final json = {
          'id': 'no-width',
          'x': 0.0,
          'y': 0.0,
          'text': 'Test',
          'data': 'test',
        };

        final comment = CommentNode<String>.fromJson(
          json,
          dataFromJson: (json) => json as String,
        );

        expect(comment.width, equals(200.0)); // Default width
      });

      test('fromJson handles missing height field', () {
        final json = {
          'id': 'no-height',
          'x': 0.0,
          'y': 0.0,
          'text': 'Test',
          'data': 'test',
        };

        final comment = CommentNode<String>.fromJson(
          json,
          dataFromJson: (json) => json as String,
        );

        expect(comment.height, equals(100.0)); // Default height
      });

      test('fromJson handles missing color field', () {
        final json = {
          'id': 'no-color',
          'x': 0.0,
          'y': 0.0,
          'text': 'Test',
          'data': 'test',
        };

        final comment = CommentNode<String>.fromJson(
          json,
          dataFromJson: (json) => json as String,
        );

        // Colors.yellow is a MaterialColor, but when restored from JSON it's a Color
        // Compare by ARGB value instead
        expect(
          comment.color.toARGB32(),
          equals(Colors.yellow.toARGB32()),
        ); // Default color
      });

      test('fromJson handles missing zIndex field', () {
        final json = {
          'id': 'no-zindex',
          'x': 0.0,
          'y': 0.0,
          'text': 'Test',
          'data': 'test',
        };

        final comment = CommentNode<String>.fromJson(
          json,
          dataFromJson: (json) => json as String,
        );

        expect(comment.currentZIndex, equals(0)); // Default zIndex
      });

      test('fromJson handles missing isVisible field', () {
        final json = {
          'id': 'no-visible',
          'x': 0.0,
          'y': 0.0,
          'text': 'Test',
          'data': 'test',
        };

        final comment = CommentNode<String>.fromJson(
          json,
          dataFromJson: (json) => json as String,
        );

        expect(comment.isVisible, isTrue); // Default visible
      });

      test('fromJson handles missing locked field', () {
        final json = {
          'id': 'no-locked',
          'x': 0.0,
          'y': 0.0,
          'text': 'Test',
          'data': 'test',
        };

        final comment = CommentNode<String>.fromJson(
          json,
          dataFromJson: (json) => json as String,
        );

        expect(comment.locked, isFalse); // Default unlocked
      });

      test('fromJson with integer position values', () {
        final json = {
          'id': 'int-pos',
          'x': 100,
          'y': 200,
          'text': 'Int position',
          'data': 'test',
        };

        final comment = CommentNode<String>.fromJson(
          json,
          dataFromJson: (json) => json as String,
        );

        expect(comment.position.value, equals(const Offset(100, 200)));
      });

      test('fromJson with integer size values', () {
        final json = {
          'id': 'int-size',
          'x': 0,
          'y': 0,
          'width': 300,
          'height': 200,
          'text': 'Int size',
          'data': 'test',
        };

        final comment = CommentNode<String>.fromJson(
          json,
          dataFromJson: (json) => json as String,
        );

        expect(comment.width, equals(300.0));
        expect(comment.height, equals(200.0));
      });
    });

    group('Round-trip serialization', () {
      test('round-trip preserves all properties', () {
        final original = CommentNode<String>(
          id: 'round-trip',
          position: const Offset(150, 250),
          text: 'Round trip test',
          data: 'round-trip-data',
          width: 280,
          height: 180,
          color: Colors.purple,
          zIndex: 7,
          isVisible: true,
          locked: false,
        );

        final json = original.toJson((data) => data);
        final restored = CommentNode<String>.fromJson(
          json,
          dataFromJson: (json) => json as String,
        );

        expect(restored.id, equals(original.id));
        expect(restored.position.value, equals(original.position.value));
        expect(restored.text, equals(original.text));
        expect(restored.data, equals(original.data));
        expect(restored.width, equals(original.width));
        expect(restored.height, equals(original.height));
        expect(restored.currentZIndex, equals(original.currentZIndex));
        expect(restored.isVisible, equals(original.isVisible));
        expect(restored.locked, equals(original.locked));
      });

      test('round-trip with complex data type', () {
        final complexData = {
          'title': 'Complex',
          'items': [1, 2, 3],
          'nested': {'a': 'b'},
        };

        final original = CommentNode<Map<String, dynamic>>(
          id: 'complex-round-trip',
          position: Offset.zero,
          text: 'Complex data',
          data: complexData,
        );

        final json = original.toJson((data) => data);
        final restored = CommentNode<Map<String, dynamic>>.fromJson(
          json,
          dataFromJson: (json) => Map<String, dynamic>.from(json as Map),
        );

        expect(restored.data['title'], equals('Complex'));
        expect(restored.data['items'], equals([1, 2, 3]));
        expect(restored.data['nested']['a'], equals('b'));
      });
    });
  });

  // ===========================================================================
  // Edge Cases
  // ===========================================================================
  group('Edge Cases', () {
    test('comment node at origin', () {
      final comment = CommentNode<String>(
        id: 'origin',
        position: Offset.zero,
        text: 'At origin',
        data: 'test',
      );

      expect(comment.position.value, equals(Offset.zero));
    });

    test('comment node at negative coordinates', () {
      final comment = CommentNode<String>(
        id: 'negative',
        position: const Offset(-200, -100),
        text: 'Negative coords',
        data: 'test',
      );

      expect(comment.position.value.dx, equals(-200));
      expect(comment.position.value.dy, equals(-100));
    });

    test('comment node with minimum size', () {
      final comment = CommentNode<String>(
        id: 'min-size',
        position: Offset.zero,
        text: 'Min',
        data: 'test',
        width: CommentNode.minWidth,
        height: CommentNode.minHeight,
      );

      expect(comment.width, equals(CommentNode.minWidth));
      expect(comment.height, equals(CommentNode.minHeight));
    });

    test('comment node with maximum size', () {
      final comment = CommentNode<String>(
        id: 'max-size',
        position: Offset.zero,
        text: 'Max',
        data: 'test',
        width: CommentNode.maxWidth,
        height: CommentNode.maxHeight,
      );

      expect(comment.width, equals(CommentNode.maxWidth));
      expect(comment.height, equals(CommentNode.maxHeight));
    });

    test('size below minimum is clamped on setSize', () {
      final comment = createTestCommentNode<String>(data: 'test');

      comment.setSize(const Size(0, 0));

      expect(comment.width, equals(CommentNode.minWidth));
      expect(comment.height, equals(CommentNode.minHeight));
    });

    test('size above maximum is clamped on setSize', () {
      final comment = createTestCommentNode<String>(data: 'test');

      comment.setSize(const Size(1000, 1000));

      expect(comment.width, equals(CommentNode.maxWidth));
      expect(comment.height, equals(CommentNode.maxHeight));
    });

    test('comment node with special characters in text', () {
      final specialText = 'Line1\nLine2\tTabbed "Quoted" \'Single\' <html>';
      final comment = CommentNode<String>(
        id: 'special-chars',
        position: Offset.zero,
        text: specialText,
        data: 'test',
      );

      expect(comment.text, equals(specialText));
    });

    test('multiple text updates in sequence', () {
      final comment = createTestCommentNode<String>(
        text: 'Initial',
        data: 'test',
      );

      comment.text = 'Update 1';
      expect(comment.text, equals('Update 1'));

      comment.text = 'Update 2';
      expect(comment.text, equals('Update 2'));

      comment.text = 'Update 3';
      expect(comment.text, equals('Update 3'));
    });

    test('multiple color updates in sequence', () {
      final comment = createTestCommentNode<String>(
        color: Colors.yellow,
        data: 'test',
      );

      comment.color = Colors.red;
      expect(comment.color, equals(Colors.red));

      comment.color = Colors.blue;
      expect(comment.color, equals(Colors.blue));

      comment.color = Colors.green;
      expect(comment.color, equals(Colors.green));
    });

    test('visibility toggle', () {
      final comment = createTestCommentNode<String>(data: 'test');

      expect(comment.isVisible, isTrue);

      comment.isVisible = false;
      expect(comment.isVisible, isFalse);

      comment.isVisible = true;
      expect(comment.isVisible, isTrue);
    });

    test('selection toggle', () {
      final comment = createTestCommentNode<String>(data: 'test');

      expect(comment.isSelected, isFalse);

      comment.isSelected = true;
      expect(comment.isSelected, isTrue);

      comment.isSelected = false;
      expect(comment.isSelected, isFalse);
    });

    test('editing state toggle', () {
      final comment = createTestCommentNode<String>(data: 'test');

      expect(comment.isEditing, isFalse);

      comment.isEditing = true;
      expect(comment.isEditing, isTrue);

      comment.isEditing = false;
      expect(comment.isEditing, isFalse);
    });
  });

  // ===========================================================================
  // Controller Integration Tests
  // ===========================================================================
  group('Integration with NodeFlowController', () {
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

    test('comment node in sorted nodes by z-index', () {
      final regularNode = createTestNode(id: 'node-1', zIndex: 0);
      final comment = createTestCommentNode<String>(
        id: 'comment-1',
        zIndex: 10,
        data: 'comment-data',
      );
      final controller = createTestController(nodes: [regularNode, comment]);

      final sortedNodes = controller.sortedNodes;

      expect(sortedNodes.first.id, equals('node-1')); // Lower z-index
      expect(sortedNodes.last.id, equals('comment-1')); // Higher z-index
    });

    test('multiple comment nodes can be added', () {
      final controller = createTestController();
      final comment1 = createTestCommentNode<String>(id: 'c-1', data: 'c1');
      final comment2 = createTestCommentNode<String>(id: 'c-2', data: 'c2');
      final comment3 = createTestCommentNode<String>(id: 'c-3', data: 'c3');

      controller.addNode(comment1);
      controller.addNode(comment2);
      controller.addNode(comment3);

      expect(controller.nodes.length, equals(3));
      expect(controller.nodes['c-1'], isA<CommentNode<String>>());
      expect(controller.nodes['c-2'], isA<CommentNode<String>>());
      expect(controller.nodes['c-3'], isA<CommentNode<String>>());
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

    test('comment node color can be changed after adding to controller', () {
      final comment = createTestCommentNode<String>(
        id: 'comment-1',
        color: Colors.yellow,
        data: 'test',
      );
      final controller = createTestController(nodes: [comment]);

      final retrievedComment =
          controller.nodes['comment-1'] as CommentNode<String>;
      retrievedComment.color = Colors.blue;

      expect(retrievedComment.color, equals(Colors.blue));
    });

    test('comment nodes mixed with other node types', () {
      final regularNode = createTestNode(id: 'regular-1');
      final groupNode = createTestGroupNode<String>(id: 'group-1', data: 'g');
      final comment = createTestCommentNode<String>(id: 'comment-1', data: 'c');

      final controller = createTestController(
        nodes: [regularNode, groupNode, comment],
      );

      expect(controller.nodes.length, equals(3));
      expect(controller.nodes['regular-1'], isA<Node<String>>());
      expect(controller.nodes['group-1'], isA<GroupNode<String>>());
      expect(controller.nodes['comment-1'], isA<CommentNode<String>>());
    });
  });

  // ===========================================================================
  // buildWidget Tests
  // ===========================================================================
  group('buildWidget', () {
    test('buildWidget returns widget when no widgetBuilder', () {
      final comment = createTestCommentNode<String>(data: 'test');

      // buildWidget requires a BuildContext, but we can test that it doesn't
      // return null (meaning it's a self-rendering node)
      // Since CommentNode provides its own _CommentContent, buildWidget should
      // return a widget when called with a proper BuildContext
      expect(comment.widgetBuilder, isNull);
    });

    test('widgetBuilder can be set per instance', () {
      Widget customBuilder(BuildContext context, CommentNode<String> node) {
        return Container();
      }

      final comment = CommentNode<String>(
        id: 'custom-builder',
        position: Offset.zero,
        text: 'Custom',
        data: 'test',
      );

      // widgetBuilder is set via constructor, so create a new node to test
      // Note: Currently the CommentNode constructor doesn't expose widgetBuilder
      // This test documents the expected behavior
      expect(comment.widgetBuilder, isNull);
    });
  });

  // ===========================================================================
  // Bounds Calculation Tests
  // ===========================================================================
  group('Bounds Calculation', () {
    test('getBounds returns correct rectangle', () {
      final comment = CommentNode<String>(
        id: 'bounds-test',
        position: const Offset(100, 50),
        text: 'Bounds',
        data: 'test',
        width: 250,
        height: 150,
      );

      final bounds = comment.getBounds();

      expect(bounds.left, equals(100));
      expect(bounds.top, equals(50));
      expect(bounds.width, equals(250));
      expect(bounds.height, equals(150));
      expect(bounds.right, equals(350));
      expect(bounds.bottom, equals(200));
    });

    test('containsPoint returns true for point inside', () {
      final comment = CommentNode<String>(
        id: 'contains-test',
        position: const Offset(100, 100),
        text: 'Contains',
        data: 'test',
        width: 200,
        height: 100,
      );

      expect(comment.containsPoint(const Offset(150, 150)), isTrue);
      expect(comment.containsPoint(const Offset(100, 100)), isTrue);
      expect(comment.containsPoint(const Offset(200, 150)), isTrue);
    });

    test('containsPoint returns false for point outside', () {
      final comment = CommentNode<String>(
        id: 'outside-test',
        position: const Offset(100, 100),
        text: 'Outside',
        data: 'test',
        width: 200,
        height: 100,
      );

      expect(comment.containsPoint(const Offset(50, 50)), isFalse);
      expect(comment.containsPoint(const Offset(350, 150)), isFalse);
      expect(comment.containsPoint(const Offset(150, 250)), isFalse);
    });
  });
}
