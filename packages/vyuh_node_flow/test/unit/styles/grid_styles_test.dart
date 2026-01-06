/// Comprehensive tests for grid styles.
///
/// Tests all grid styles through the public API.
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vyuh_node_flow/vyuh_node_flow.dart';

void main() {
  group('GridStyles', () {
    group('Built-in Styles', () {
      test('lines style is available', () {
        expect(GridStyles.lines, isNotNull);
        expect(GridStyles.lines, isA<GridStyle>());
      });

      test('dots style is available', () {
        expect(GridStyles.dots, isNotNull);
        expect(GridStyles.dots, isA<GridStyle>());
      });

      test('cross style is available', () {
        expect(GridStyles.cross, isNotNull);
        expect(GridStyles.cross, isA<GridStyle>());
      });

      test('hierarchical style is available', () {
        expect(GridStyles.hierarchical, isNotNull);
        expect(GridStyles.hierarchical, isA<GridStyle>());
      });

      test('none style is available', () {
        expect(GridStyles.none, isNotNull);
        expect(GridStyles.none, isA<GridStyle>());
      });
    });
  });

  group('GridStyle Interface', () {
    test('all grid styles implement GridStyle', () {
      final styles = <GridStyle>[
        GridStyles.dots,
        GridStyles.lines,
        GridStyles.cross,
        GridStyles.hierarchical,
        GridStyles.none,
      ];

      for (final style in styles) {
        expect(style, isA<GridStyle>());
      }
    });
  });

  group('GridTheme', () {
    group('Construction', () {
      test('creates with all required values', () {
        final theme = GridTheme(
          color: Colors.grey,
          size: 20.0,
          thickness: 1.0,
          style: GridStyles.dots,
        );
        expect(theme.color, equals(Colors.grey));
        expect(theme.size, equals(20.0));
        expect(theme.thickness, equals(1.0));
        expect(theme.style, same(GridStyles.dots));
      });

      test('creates with custom size', () {
        final theme = GridTheme(
          color: Colors.grey,
          size: 32.0,
          thickness: 1.0,
          style: GridStyles.dots,
        );
        expect(theme.size, equals(32.0));
      });

      test('creates with custom thickness', () {
        final theme = GridTheme(
          color: Colors.grey,
          size: 20.0,
          thickness: 2.5,
          style: GridStyles.dots,
        );
        expect(theme.thickness, equals(2.5));
      });

      test('creates with lines style', () {
        final theme = GridTheme(
          color: Colors.blue,
          size: 25.0,
          thickness: 1.5,
          style: GridStyles.lines,
        );
        expect(theme.style, same(GridStyles.lines));
      });

      test('creates with cross style', () {
        final theme = GridTheme(
          color: Colors.green,
          size: 30.0,
          thickness: 2.0,
          style: GridStyles.cross,
        );
        expect(theme.style, same(GridStyles.cross));
      });
    });

    group('Predefined Themes', () {
      test('light theme is available', () {
        expect(GridTheme.light, isNotNull);
        expect(GridTheme.light.style, same(GridStyles.dots));
      });

      test('dark theme is available', () {
        expect(GridTheme.dark, isNotNull);
        expect(GridTheme.dark.style, same(GridStyles.dots));
      });

      test('light and dark themes have different colors', () {
        expect(GridTheme.light.color, isNot(equals(GridTheme.dark.color)));
      });

      test('predefined themes have reasonable defaults', () {
        expect(GridTheme.light.size, equals(20.0));
        expect(GridTheme.light.thickness, equals(1.0));
        expect(GridTheme.dark.size, equals(20.0));
        expect(GridTheme.dark.thickness, equals(1.0));
      });
    });

    group('copyWith', () {
      test('copies with new color', () {
        final original = GridTheme.light;
        final copied = original.copyWith(color: Colors.red);

        expect(copied.color, equals(Colors.red));
        expect(copied.size, equals(original.size));
        expect(copied.thickness, equals(original.thickness));
        expect(copied.style, same(original.style));
      });

      test('copies with new size', () {
        final original = GridTheme.light;
        final copied = original.copyWith(size: 40.0);

        expect(copied.size, equals(40.0));
        expect(copied.color, equals(original.color));
      });

      test('copies with new thickness', () {
        final original = GridTheme.light;
        final copied = original.copyWith(thickness: 3.0);

        expect(copied.thickness, equals(3.0));
        expect(copied.color, equals(original.color));
      });

      test('copies with new style', () {
        final original = GridTheme.light;
        final copied = original.copyWith(style: GridStyles.lines);

        expect(copied.style, same(GridStyles.lines));
        expect(copied.color, equals(original.color));
      });

      test('returns same values when no parameters provided', () {
        final original = GridTheme(
          color: Colors.purple,
          size: 25.0,
          thickness: 2.0,
          style: GridStyles.hierarchical,
        );
        final copied = original.copyWith();

        expect(copied.color, equals(original.color));
        expect(copied.size, equals(original.size));
        expect(copied.thickness, equals(original.thickness));
        expect(copied.style, same(original.style));
      });

      test('can update multiple properties at once', () {
        final original = GridTheme.light;
        final copied = original.copyWith(
          color: Colors.blue,
          size: 50.0,
          style: GridStyles.cross,
        );

        expect(copied.color, equals(Colors.blue));
        expect(copied.size, equals(50.0));
        expect(copied.style, same(GridStyles.cross));
        expect(copied.thickness, equals(original.thickness));
      });
    });
  });
}
