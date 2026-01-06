/// Comprehensive tests for connection styles.
///
/// Tests all connection styles through the public API.
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vyuh_node_flow/vyuh_node_flow.dart';

void main() {
  group('ConnectionStyles', () {
    group('Built-in Styles', () {
      test('bezier style is available', () {
        expect(ConnectionStyles.bezier, isNotNull);
        expect(ConnectionStyles.bezier, isA<ConnectionStyle>());
      });

      test('straight style is available', () {
        expect(ConnectionStyles.straight, isNotNull);
        expect(ConnectionStyles.straight, isA<ConnectionStyle>());
      });

      test('step style is available', () {
        expect(ConnectionStyles.step, isNotNull);
        expect(ConnectionStyles.step, isA<ConnectionStyle>());
      });

      test('smoothstep style is available', () {
        expect(ConnectionStyles.smoothstep, isNotNull);
        expect(ConnectionStyles.smoothstep, isA<ConnectionStyle>());
      });

      test('customBezier style is available', () {
        expect(ConnectionStyles.customBezier, isNotNull);
        expect(ConnectionStyles.customBezier, isA<ConnectionStyle>());
      });

      test('all styles list contains all styles', () {
        expect(ConnectionStyles.all, hasLength(5));
        expect(ConnectionStyles.all, contains(ConnectionStyles.bezier));
        expect(ConnectionStyles.all, contains(ConnectionStyles.straight));
        expect(ConnectionStyles.all, contains(ConnectionStyles.step));
        expect(ConnectionStyles.all, contains(ConnectionStyles.smoothstep));
        expect(ConnectionStyles.all, contains(ConnectionStyles.customBezier));
      });

      test('byId map contains all styles', () {
        expect(ConnectionStyles.byId['bezier'], same(ConnectionStyles.bezier));
        expect(
          ConnectionStyles.byId['straight'],
          same(ConnectionStyles.straight),
        );
        expect(ConnectionStyles.byId['step'], same(ConnectionStyles.step));
        expect(
          ConnectionStyles.byId['smoothstep'],
          same(ConnectionStyles.smoothstep),
        );
        expect(
          ConnectionStyles.byId['customBezier'],
          same(ConnectionStyles.customBezier),
        );
      });
    });

    group('findById', () {
      test('returns correct style for valid ID', () {
        expect(
          ConnectionStyles.findById('bezier'),
          same(ConnectionStyles.bezier),
        );
        expect(
          ConnectionStyles.findById('straight'),
          same(ConnectionStyles.straight),
        );
      });

      test('returns null for invalid ID', () {
        expect(ConnectionStyles.findById('nonexistent'), isNull);
      });
    });

    group('allIds', () {
      test('returns all style IDs', () {
        final ids = ConnectionStyles.allIds;
        expect(ids, contains('bezier'));
        expect(ids, contains('straight'));
        expect(ids, contains('step'));
        expect(ids, contains('smoothstep'));
        expect(ids, contains('customBezier'));
      });
    });

    group('isBuiltIn', () {
      test('returns true for built-in styles', () {
        expect(ConnectionStyles.isBuiltIn(ConnectionStyles.bezier), isTrue);
        expect(ConnectionStyles.isBuiltIn(ConnectionStyles.straight), isTrue);
      });
    });

    group('getWithFallback', () {
      test('returns requested style when found', () {
        expect(
          ConnectionStyles.getWithFallback('bezier'),
          same(ConnectionStyles.bezier),
        );
      });

      test('returns smoothstep for null ID', () {
        expect(
          ConnectionStyles.getWithFallback(null),
          same(ConnectionStyles.smoothstep),
        );
      });

      test('returns smoothstep for unknown ID', () {
        expect(
          ConnectionStyles.getWithFallback('unknown'),
          same(ConnectionStyles.smoothstep),
        );
      });
    });
  });

  group('ConnectionStyle Interface', () {
    test('all styles have an ID', () {
      for (final style in ConnectionStyles.all) {
        expect(style.id, isNotEmpty);
      }
    });

    test('all styles have a display name', () {
      for (final style in ConnectionStyles.all) {
        expect(style.displayName, isNotEmpty);
      }
    });
  });

  group('ConnectionStyleExtension', () {
    test('isBuiltIn extension works', () {
      expect(ConnectionStyles.bezier.isBuiltIn, isTrue);
      expect(ConnectionStyles.straight.isBuiltIn, isTrue);
    });
  });

  group('ConnectionTheme', () {
    group('Predefined Themes', () {
      test('light theme is available', () {
        expect(ConnectionTheme.light, isNotNull);
        expect(ConnectionTheme.light.style, same(ConnectionStyles.smoothstep));
      });

      test('dark theme is available', () {
        expect(ConnectionTheme.dark, isNotNull);
        expect(ConnectionTheme.dark.style, same(ConnectionStyles.smoothstep));
      });

      test('light and dark themes have different colors', () {
        expect(
          ConnectionTheme.light.color,
          isNot(equals(ConnectionTheme.dark.color)),
        );
      });

      test('predefined themes have reasonable defaults', () {
        expect(ConnectionTheme.light.strokeWidth, equals(2.0));
        expect(ConnectionTheme.light.selectedStrokeWidth, equals(3.0));
        expect(ConnectionTheme.dark.strokeWidth, equals(2.0));
        expect(ConnectionTheme.dark.selectedStrokeWidth, equals(3.0));
      });

      test('predefined themes have endpoint configurations', () {
        expect(ConnectionTheme.light.startPoint, same(ConnectionEndPoint.none));
        expect(
          ConnectionTheme.light.endPoint,
          same(ConnectionEndPoint.capsuleHalf),
        );
        expect(ConnectionTheme.dark.startPoint, same(ConnectionEndPoint.none));
        expect(
          ConnectionTheme.dark.endPoint,
          same(ConnectionEndPoint.capsuleHalf),
        );
      });

      test('predefined themes have geometric properties', () {
        expect(ConnectionTheme.light.bezierCurvature, equals(0.5));
        expect(ConnectionTheme.light.cornerRadius, equals(4.0));
        expect(ConnectionTheme.light.portExtension, equals(20.0));
        expect(ConnectionTheme.light.hitTolerance, equals(8.0));
      });
    });

    group('copyWith', () {
      test('copies with new style', () {
        final original = ConnectionTheme.light;
        final copied = original.copyWith(style: ConnectionStyles.bezier);

        expect(copied.style, same(ConnectionStyles.bezier));
        expect(copied.color, equals(original.color));
      });

      test('copies with new color', () {
        final original = ConnectionTheme.light;
        final copied = original.copyWith(color: Colors.red);

        expect(copied.color, equals(Colors.red));
        expect(copied.style, same(original.style));
      });

      test('copies with new stroke width', () {
        final original = ConnectionTheme.light;
        final copied = original.copyWith(strokeWidth: 4.0);

        expect(copied.strokeWidth, equals(4.0));
        expect(copied.color, equals(original.color));
      });

      test('copies with new bezier curvature', () {
        final original = ConnectionTheme.light;
        final copied = original.copyWith(bezierCurvature: 0.8);

        expect(copied.bezierCurvature, equals(0.8));
        expect(copied.cornerRadius, equals(original.cornerRadius));
      });

      test('returns same values when no parameters provided', () {
        final original = ConnectionTheme.light;
        final copied = original.copyWith();

        expect(copied.style, same(original.style));
        expect(copied.color, equals(original.color));
        expect(copied.strokeWidth, equals(original.strokeWidth));
        expect(copied.bezierCurvature, equals(original.bezierCurvature));
      });

      test('can update multiple properties at once', () {
        final original = ConnectionTheme.light;
        final copied = original.copyWith(
          style: ConnectionStyles.step,
          strokeWidth: 5.0,
          cornerRadius: 8.0,
        );

        expect(copied.style, same(ConnectionStyles.step));
        expect(copied.strokeWidth, equals(5.0));
        expect(copied.cornerRadius, equals(8.0));
        expect(copied.color, equals(original.color));
      });
    });
  });

  group('ConnectionEndPoint', () {
    group('Predefined Endpoints', () {
      test('none endpoint is available', () {
        expect(ConnectionEndPoint.none, isNotNull);
      });

      test('capsuleHalf endpoint is available', () {
        expect(ConnectionEndPoint.capsuleHalf, isNotNull);
      });

      test('triangle endpoint is available', () {
        expect(ConnectionEndPoint.triangle, isNotNull);
      });

      test('circle endpoint is available', () {
        expect(ConnectionEndPoint.circle, isNotNull);
      });

      test('diamond endpoint is available', () {
        expect(ConnectionEndPoint.diamond, isNotNull);
      });

      test('rectangle endpoint is available', () {
        expect(ConnectionEndPoint.rectangle, isNotNull);
      });
    });

    group('Endpoint Properties', () {
      test('capsuleHalf has shape', () {
        expect(ConnectionEndPoint.capsuleHalf.shape, isNotNull);
      });

      test('triangle has shape', () {
        expect(ConnectionEndPoint.triangle.shape, isNotNull);
      });

      test('circle has size', () {
        expect(ConnectionEndPoint.circle.size, isNotNull);
      });
    });
  });
}
