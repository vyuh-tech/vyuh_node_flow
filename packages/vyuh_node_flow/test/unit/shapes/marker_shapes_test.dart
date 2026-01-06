/// Comprehensive tests for marker shapes.
///
/// Tests all marker shapes through the public API.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:vyuh_node_flow/vyuh_node_flow.dart';

void main() {
  group('MarkerShapes', () {
    group('Built-in Shapes', () {
      test('none shape is available', () {
        expect(MarkerShapes.none, isNotNull);
        expect(MarkerShapes.none, isA<MarkerShape>());
      });

      test('circle shape is available', () {
        expect(MarkerShapes.circle, isNotNull);
        expect(MarkerShapes.circle, isA<MarkerShape>());
      });

      test('rectangle shape is available', () {
        expect(MarkerShapes.rectangle, isNotNull);
        expect(MarkerShapes.rectangle, isA<MarkerShape>());
      });

      test('diamond shape is available', () {
        expect(MarkerShapes.diamond, isNotNull);
        expect(MarkerShapes.diamond, isA<MarkerShape>());
      });

      test('triangle shape is available', () {
        expect(MarkerShapes.triangle, isNotNull);
        expect(MarkerShapes.triangle, isA<MarkerShape>());
      });

      test('capsuleHalf shape is available', () {
        expect(MarkerShapes.capsuleHalf, isNotNull);
        expect(MarkerShapes.capsuleHalf, isA<MarkerShape>());
      });
    });
  });

  group('MarkerShape Interface', () {
    test('all marker shapes implement MarkerShape', () {
      final shapes = <MarkerShape>[
        MarkerShapes.none,
        MarkerShapes.circle,
        MarkerShapes.rectangle,
        MarkerShapes.diamond,
        MarkerShapes.triangle,
        MarkerShapes.capsuleHalf,
      ];

      for (final shape in shapes) {
        expect(shape, isA<MarkerShape>());
        expect(shape.typeName, isNotEmpty);
      }
    });

    test('all marker shapes have unique typeNames', () {
      final shapes = <MarkerShape>[
        MarkerShapes.none,
        MarkerShapes.circle,
        MarkerShapes.rectangle,
        MarkerShapes.diamond,
        MarkerShapes.triangle,
        MarkerShapes.capsuleHalf,
      ];

      final typeNames = shapes.map((s) => s.typeName).toSet();
      expect(typeNames.length, equals(shapes.length));
    });
  });

  group('MarkerShape typeNames', () {
    test('none has correct typeName', () {
      expect(MarkerShapes.none.typeName, equals('none'));
    });

    test('circle has correct typeName', () {
      expect(MarkerShapes.circle.typeName, equals('circle'));
    });

    test('rectangle has correct typeName', () {
      expect(MarkerShapes.rectangle.typeName, equals('rectangle'));
    });

    test('diamond has correct typeName', () {
      expect(MarkerShapes.diamond.typeName, equals('diamond'));
    });

    test('triangle has correct typeName', () {
      expect(MarkerShapes.triangle.typeName, equals('triangle'));
    });

    test('capsuleHalf has correct typeName', () {
      expect(MarkerShapes.capsuleHalf.typeName, equals('capsuleHalf'));
    });
  });

  group('MarkerShape Equality', () {
    test('same shape constants are identical', () {
      expect(identical(MarkerShapes.circle, MarkerShapes.circle), isTrue);
      expect(identical(MarkerShapes.triangle, MarkerShapes.triangle), isTrue);
    });
  });
}
