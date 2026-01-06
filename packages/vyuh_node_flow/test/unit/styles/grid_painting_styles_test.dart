/// Comprehensive tests for grid painting styles.
///
/// Tests the grid style implementations through the public API.
/// Covers GridStyles constants, GridStyle behavior, and GridTheme integration.
library;

import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vyuh_node_flow/vyuh_node_flow.dart';

import '../../helpers/test_factories.dart';

void main() {
  setUp(() {
    resetTestCounters();
  });

  group('GridStyles Constants', () {
    group('Static Style Instances', () {
      test('lines style is a GridStyle instance', () {
        expect(GridStyles.lines, isA<GridStyle>());
      });

      test('dots style is a GridStyle instance', () {
        expect(GridStyles.dots, isA<GridStyle>());
      });

      test('cross style is a GridStyle instance', () {
        expect(GridStyles.cross, isA<GridStyle>());
      });

      test('hierarchical style is a GridStyle instance', () {
        expect(GridStyles.hierarchical, isA<GridStyle>());
      });

      test('none style is a GridStyle instance', () {
        expect(GridStyles.none, isA<GridStyle>());
      });

      test('all static styles are const instances', () {
        // Verify that multiple accesses return the same instance
        expect(identical(GridStyles.lines, GridStyles.lines), isTrue);
        expect(identical(GridStyles.dots, GridStyles.dots), isTrue);
        expect(identical(GridStyles.cross, GridStyles.cross), isTrue);
        expect(
          identical(GridStyles.hierarchical, GridStyles.hierarchical),
          isTrue,
        );
        expect(identical(GridStyles.none, GridStyles.none), isTrue);
      });

      test('all styles are distinct from each other', () {
        final styles = [
          GridStyles.lines,
          GridStyles.dots,
          GridStyles.cross,
          GridStyles.hierarchical,
          GridStyles.none,
        ];

        // Each style should be unique
        for (var i = 0; i < styles.length; i++) {
          for (var j = i + 1; j < styles.length; j++) {
            expect(
              identical(styles[i], styles[j]),
              isFalse,
              reason: 'Style $i and $j should be different',
            );
          }
        }
      });
    });

    group('Style Types', () {
      test('all styles extend GridStyle', () {
        expect(GridStyles.lines, isA<GridStyle>());
        expect(GridStyles.dots, isA<GridStyle>());
        expect(GridStyles.cross, isA<GridStyle>());
        expect(GridStyles.hierarchical, isA<GridStyle>());
        expect(GridStyles.none, isA<GridStyle>());
      });

      test('styles have correct runtime types', () {
        // Just verify they have distinct types
        final lineType = GridStyles.lines.runtimeType;
        final dotsType = GridStyles.dots.runtimeType;
        final crossType = GridStyles.cross.runtimeType;
        final hierarchicalType = GridStyles.hierarchical.runtimeType;
        final noneType = GridStyles.none.runtimeType;

        expect(lineType, isNot(equals(dotsType)));
        expect(lineType, isNot(equals(crossType)));
        expect(lineType, isNot(equals(hierarchicalType)));
        expect(lineType, isNot(equals(noneType)));
      });
    });
  });

  group('GridStyles.lines', () {
    group('Paint Method', () {
      test('paint method accepts valid parameters', () {
        final style = GridStyles.lines;
        final recorder = PictureRecorder();
        final canvas = Canvas(recorder);
        final viewport = createTestViewport();

        // Should not throw
        expect(
          () => style.paint(
            canvas,
            const Size(800, 600),
            NodeFlowTheme.light,
            viewport,
          ),
          returnsNormally,
        );
      });

      test('paint handles zero grid size gracefully', () {
        final style = GridStyles.lines;
        final recorder = PictureRecorder();
        final canvas = Canvas(recorder);
        final viewport = createTestViewport();

        // Create theme with zero grid size
        final theme = NodeFlowTheme.light.copyWith(
          gridTheme: GridTheme.light.copyWith(size: 0.0),
        );

        // Should not throw - implementation should return early
        expect(
          () => style.paint(canvas, const Size(800, 600), theme, viewport),
          returnsNormally,
        );
      });

      test('paint handles negative grid size gracefully', () {
        final style = GridStyles.lines;
        final recorder = PictureRecorder();
        final canvas = Canvas(recorder);
        final viewport = createTestViewport();

        // Create theme with negative grid size
        final theme = NodeFlowTheme.light.copyWith(
          gridTheme: GridTheme.light.copyWith(size: -10.0),
        );

        // Should not throw
        expect(
          () => style.paint(canvas, const Size(800, 600), theme, viewport),
          returnsNormally,
        );
      });

      test('paint works with various viewport zoom levels', () {
        final style = GridStyles.lines;
        final recorder = PictureRecorder();
        final canvas = Canvas(recorder);

        final zoomLevels = [0.1, 0.5, 1.0, 2.0, 4.0];

        for (final zoom in zoomLevels) {
          final viewport = createTestViewport(zoom: zoom);
          expect(
            () => style.paint(
              canvas,
              const Size(800, 600),
              NodeFlowTheme.light,
              viewport,
            ),
            returnsNormally,
            reason: 'Should work with zoom level $zoom',
          );
        }
      });

      test('paint works with various viewport pan offsets', () {
        final style = GridStyles.lines;
        final recorder = PictureRecorder();
        final canvas = Canvas(recorder);

        final offsets = [
          (x: 0.0, y: 0.0),
          (x: 100.0, y: 100.0),
          (x: -500.0, y: -300.0),
          (x: 1000.0, y: -1000.0),
        ];

        for (final offset in offsets) {
          final viewport = createTestViewport(x: offset.x, y: offset.y);
          expect(
            () => style.paint(
              canvas,
              const Size(800, 600),
              NodeFlowTheme.light,
              viewport,
            ),
            returnsNormally,
            reason: 'Should work with pan offset (${offset.x}, ${offset.y})',
          );
        }
      });

      test('paint works with different canvas sizes', () {
        final style = GridStyles.lines;
        final recorder = PictureRecorder();
        final canvas = Canvas(recorder);
        final viewport = createTestViewport();

        final sizes = [
          const Size(100, 100),
          const Size(1920, 1080),
          const Size(4000, 3000),
          const Size(1, 1),
        ];

        for (final size in sizes) {
          expect(
            () => style.paint(canvas, size, NodeFlowTheme.light, viewport),
            returnsNormally,
            reason: 'Should work with canvas size $size',
          );
        }
      });
    });
  });

  group('GridStyles.dots', () {
    group('Paint Method', () {
      test('paint method accepts valid parameters', () {
        final style = GridStyles.dots;
        final recorder = PictureRecorder();
        final canvas = Canvas(recorder);
        final viewport = createTestViewport();

        expect(
          () => style.paint(
            canvas,
            const Size(800, 600),
            NodeFlowTheme.light,
            viewport,
          ),
          returnsNormally,
        );
      });

      test('paint handles zero grid size gracefully', () {
        final style = GridStyles.dots;
        final recorder = PictureRecorder();
        final canvas = Canvas(recorder);
        final viewport = createTestViewport();

        final theme = NodeFlowTheme.light.copyWith(
          gridTheme: GridTheme.light.copyWith(size: 0.0),
        );

        expect(
          () => style.paint(canvas, const Size(800, 600), theme, viewport),
          returnsNormally,
        );
      });

      test('paint works with various zoom levels', () {
        final style = GridStyles.dots;
        final recorder = PictureRecorder();
        final canvas = Canvas(recorder);

        for (final zoom in [0.25, 0.5, 1.0, 2.0, 3.0]) {
          final viewport = createTestViewport(zoom: zoom);
          expect(
            () => style.paint(
              canvas,
              const Size(800, 600),
              NodeFlowTheme.light,
              viewport,
            ),
            returnsNormally,
            reason: 'Should handle zoom $zoom',
          );
        }
      });

      test('paint works with various grid thicknesses', () {
        final style = GridStyles.dots;
        final recorder = PictureRecorder();
        final canvas = Canvas(recorder);
        final viewport = createTestViewport();

        final thicknesses = [0.5, 1.0, 2.0, 3.0, 5.0];

        for (final thickness in thicknesses) {
          final theme = NodeFlowTheme.light.copyWith(
            gridTheme: GridTheme.light.copyWith(thickness: thickness),
          );

          expect(
            () => style.paint(canvas, const Size(800, 600), theme, viewport),
            returnsNormally,
            reason: 'Should work with thickness $thickness',
          );
        }
      });
    });
  });

  group('GridStyles.cross', () {
    group('Paint Method', () {
      test('paint method accepts valid parameters', () {
        final style = GridStyles.cross;
        final recorder = PictureRecorder();
        final canvas = Canvas(recorder);
        final viewport = createTestViewport();

        expect(
          () => style.paint(
            canvas,
            const Size(800, 600),
            NodeFlowTheme.light,
            viewport,
          ),
          returnsNormally,
        );
      });

      test('paint handles zero grid size gracefully', () {
        final style = GridStyles.cross;
        final recorder = PictureRecorder();
        final canvas = Canvas(recorder);
        final viewport = createTestViewport();

        final theme = NodeFlowTheme.light.copyWith(
          gridTheme: GridTheme.light.copyWith(size: 0.0),
        );

        expect(
          () => style.paint(canvas, const Size(800, 600), theme, viewport),
          returnsNormally,
        );
      });

      test('paint works with various zoom levels', () {
        final style = GridStyles.cross;
        final recorder = PictureRecorder();
        final canvas = Canvas(recorder);

        for (final zoom in [0.25, 0.5, 1.0, 2.0, 3.0]) {
          final viewport = createTestViewport(zoom: zoom);
          expect(
            () => style.paint(
              canvas,
              const Size(800, 600),
              NodeFlowTheme.light,
              viewport,
            ),
            returnsNormally,
            reason: 'Should handle zoom $zoom',
          );
        }
      });

      test('paint works with various grid thicknesses', () {
        final style = GridStyles.cross;
        final recorder = PictureRecorder();
        final canvas = Canvas(recorder);
        final viewport = createTestViewport();

        final thicknesses = [0.5, 1.0, 2.0, 3.0];

        for (final thickness in thicknesses) {
          final theme = NodeFlowTheme.light.copyWith(
            gridTheme: GridTheme.light.copyWith(thickness: thickness),
          );

          expect(
            () => style.paint(canvas, const Size(800, 600), theme, viewport),
            returnsNormally,
            reason: 'Should work with thickness $thickness',
          );
        }
      });
    });
  });

  group('GridStyles.hierarchical', () {
    group('Paint Method', () {
      test('paint method accepts valid parameters', () {
        final style = GridStyles.hierarchical;
        final recorder = PictureRecorder();
        final canvas = Canvas(recorder);
        final viewport = createTestViewport();

        expect(
          () => style.paint(
            canvas,
            const Size(800, 600),
            NodeFlowTheme.light,
            viewport,
          ),
          returnsNormally,
        );
      });

      test('paint handles zero grid size gracefully', () {
        final style = GridStyles.hierarchical;
        final recorder = PictureRecorder();
        final canvas = Canvas(recorder);
        final viewport = createTestViewport();

        final theme = NodeFlowTheme.light.copyWith(
          gridTheme: GridTheme.light.copyWith(size: 0.0),
        );

        expect(
          () => style.paint(canvas, const Size(800, 600), theme, viewport),
          returnsNormally,
        );
      });

      test('paint works with various zoom levels', () {
        final style = GridStyles.hierarchical;
        final recorder = PictureRecorder();
        final canvas = Canvas(recorder);

        for (final zoom in [0.1, 0.5, 1.0, 2.0, 5.0]) {
          final viewport = createTestViewport(zoom: zoom);
          expect(
            () => style.paint(
              canvas,
              const Size(800, 600),
              NodeFlowTheme.light,
              viewport,
            ),
            returnsNormally,
            reason: 'Should handle zoom $zoom',
          );
        }
      });

      test('paint works with large pan offsets', () {
        final style = GridStyles.hierarchical;
        final recorder = PictureRecorder();
        final canvas = Canvas(recorder);

        final viewport = createTestViewport(x: 10000.0, y: 10000.0);
        expect(
          () => style.paint(
            canvas,
            const Size(800, 600),
            NodeFlowTheme.light,
            viewport,
          ),
          returnsNormally,
        );
      });

      test('paint works with various grid sizes', () {
        final style = GridStyles.hierarchical;
        final recorder = PictureRecorder();
        final canvas = Canvas(recorder);
        final viewport = createTestViewport();

        final sizes = [10.0, 20.0, 25.0, 50.0, 100.0];

        for (final size in sizes) {
          final theme = NodeFlowTheme.light.copyWith(
            gridTheme: GridTheme.light.copyWith(size: size),
          );

          expect(
            () => style.paint(canvas, const Size(800, 600), theme, viewport),
            returnsNormally,
            reason: 'Should work with grid size $size',
          );
        }
      });
    });
  });

  group('GridStyles.none', () {
    group('Paint Method', () {
      test('paint method accepts valid parameters', () {
        final style = GridStyles.none;
        final recorder = PictureRecorder();
        final canvas = Canvas(recorder);
        final viewport = createTestViewport();

        expect(
          () => style.paint(
            canvas,
            const Size(800, 600),
            NodeFlowTheme.light,
            viewport,
          ),
          returnsNormally,
        );
      });

      test('paint does not throw with any theme', () {
        final style = GridStyles.none;
        final recorder = PictureRecorder();
        final canvas = Canvas(recorder);
        final viewport = createTestViewport();

        // Test with light theme
        expect(
          () => style.paint(
            canvas,
            const Size(800, 600),
            NodeFlowTheme.light,
            viewport,
          ),
          returnsNormally,
        );

        // Test with dark theme
        expect(
          () => style.paint(
            canvas,
            const Size(800, 600),
            NodeFlowTheme.dark,
            viewport,
          ),
          returnsNormally,
        );
      });

      test('paint works regardless of grid size', () {
        final style = GridStyles.none;
        final recorder = PictureRecorder();
        final canvas = Canvas(recorder);
        final viewport = createTestViewport();

        final sizes = [0.0, 1.0, 20.0, 100.0, -10.0];

        for (final size in sizes) {
          final theme = NodeFlowTheme.light.copyWith(
            gridTheme: GridTheme.light.copyWith(size: size),
          );
          expect(
            () => style.paint(canvas, const Size(800, 600), theme, viewport),
            returnsNormally,
            reason: 'Should work with grid size $size',
          );
        }
      });
    });

    group('Null Object Pattern', () {
      test('none style implements null object pattern', () {
        // GridStyles.none should be usable wherever GridStyle is expected
        final GridStyle style = GridStyles.none;
        expect(style, isNotNull);
      });
    });
  });

  group('GridStyle Base Class', () {
    group('Paint Method Contract', () {
      test('all styles implement paint method', () {
        final styles = <GridStyle>[
          GridStyles.lines,
          GridStyles.dots,
          GridStyles.cross,
          GridStyles.hierarchical,
          GridStyles.none,
        ];

        final recorder = PictureRecorder();
        final canvas = Canvas(recorder);
        final viewport = createTestViewport();

        for (final style in styles) {
          expect(
            () => style.paint(
              canvas,
              const Size(800, 600),
              NodeFlowTheme.light,
              viewport,
            ),
            returnsNormally,
            reason: 'Style ${style.runtimeType} should implement paint',
          );
        }
      });
    });

    group('Theme Integration', () {
      test('styles work with light theme', () {
        final styles = <GridStyle>[
          GridStyles.lines,
          GridStyles.dots,
          GridStyles.cross,
          GridStyles.hierarchical,
        ];

        final recorder = PictureRecorder();
        final canvas = Canvas(recorder);
        final viewport = createTestViewport();

        for (final style in styles) {
          expect(
            () => style.paint(
              canvas,
              const Size(800, 600),
              NodeFlowTheme.light,
              viewport,
            ),
            returnsNormally,
          );
        }
      });

      test('styles work with dark theme', () {
        final styles = <GridStyle>[
          GridStyles.lines,
          GridStyles.dots,
          GridStyles.cross,
          GridStyles.hierarchical,
        ];

        final recorder = PictureRecorder();
        final canvas = Canvas(recorder);
        final viewport = createTestViewport();

        for (final style in styles) {
          expect(
            () => style.paint(
              canvas,
              const Size(800, 600),
              NodeFlowTheme.dark,
              viewport,
            ),
            returnsNormally,
          );
        }
      });

      test('styles work with custom grid colors', () {
        final recorder = PictureRecorder();
        final canvas = Canvas(recorder);
        final viewport = createTestViewport();

        final colors = [
          Colors.red,
          Colors.green,
          Colors.blue,
          Colors.transparent,
          const Color(0x00000000),
        ];

        for (final color in colors) {
          final theme = NodeFlowTheme.light.copyWith(
            gridTheme: GridTheme.light.copyWith(color: color),
          );

          expect(
            () => GridStyles.lines.paint(
              canvas,
              const Size(800, 600),
              theme,
              viewport,
            ),
            returnsNormally,
            reason: 'Should work with color $color',
          );
        }
      });

      test('styles work with custom grid thickness', () {
        final recorder = PictureRecorder();
        final canvas = Canvas(recorder);
        final viewport = createTestViewport();

        final thicknesses = [0.1, 0.5, 1.0, 2.0, 5.0];

        for (final thickness in thicknesses) {
          final theme = NodeFlowTheme.light.copyWith(
            gridTheme: GridTheme.light.copyWith(thickness: thickness),
          );

          expect(
            () => GridStyles.lines.paint(
              canvas,
              const Size(800, 600),
              theme,
              viewport,
            ),
            returnsNormally,
            reason: 'Should work with thickness $thickness',
          );
        }
      });

      test('styles work with custom grid sizes', () {
        final recorder = PictureRecorder();
        final canvas = Canvas(recorder);
        final viewport = createTestViewport();

        final sizes = [5.0, 10.0, 20.0, 50.0, 100.0];

        for (final size in sizes) {
          final theme = NodeFlowTheme.light.copyWith(
            gridTheme: GridTheme.light.copyWith(size: size),
          );

          expect(
            () => GridStyles.lines.paint(
              canvas,
              const Size(800, 600),
              theme,
              viewport,
            ),
            returnsNormally,
            reason: 'Should work with size $size',
          );
        }
      });
    });

    group('Viewport Integration', () {
      test('styles handle extreme zoom in', () {
        final styles = <GridStyle>[
          GridStyles.lines,
          GridStyles.dots,
          GridStyles.cross,
          GridStyles.hierarchical,
        ];

        final recorder = PictureRecorder();
        final canvas = Canvas(recorder);
        final viewport = createTestViewport(zoom: 10.0);

        for (final style in styles) {
          expect(
            () => style.paint(
              canvas,
              const Size(800, 600),
              NodeFlowTheme.light,
              viewport,
            ),
            returnsNormally,
          );
        }
      });

      test('styles handle extreme zoom out', () {
        final styles = <GridStyle>[
          GridStyles.lines,
          GridStyles.dots,
          GridStyles.cross,
          GridStyles.hierarchical,
        ];

        final recorder = PictureRecorder();
        final canvas = Canvas(recorder);
        final viewport = createTestViewport(zoom: 0.05);

        for (final style in styles) {
          expect(
            () => style.paint(
              canvas,
              const Size(800, 600),
              NodeFlowTheme.light,
              viewport,
            ),
            returnsNormally,
          );
        }
      });

      test('styles handle negative pan values', () {
        final styles = <GridStyle>[
          GridStyles.lines,
          GridStyles.dots,
          GridStyles.cross,
          GridStyles.hierarchical,
        ];

        final recorder = PictureRecorder();
        final canvas = Canvas(recorder);
        final viewport = createTestViewport(x: -500.0, y: -500.0);

        for (final style in styles) {
          expect(
            () => style.paint(
              canvas,
              const Size(800, 600),
              NodeFlowTheme.light,
              viewport,
            ),
            returnsNormally,
          );
        }
      });
    });
  });

  group('GridTheme with Different Styles', () {
    test('GridTheme can be created with each style', () {
      final styles = <GridStyle>[
        GridStyles.lines,
        GridStyles.dots,
        GridStyles.cross,
        GridStyles.hierarchical,
        GridStyles.none,
      ];

      for (final style in styles) {
        final theme = GridTheme(
          color: Colors.grey,
          size: 20.0,
          thickness: 1.0,
          style: style,
        );

        expect(theme.style, same(style));
      }
    });

    test('GridTheme.copyWith can change style', () {
      final original = GridTheme.light;
      expect(original.style, same(GridStyles.dots));

      final withLines = original.copyWith(style: GridStyles.lines);
      expect(withLines.style, same(GridStyles.lines));

      final withHierarchical = original.copyWith(
        style: GridStyles.hierarchical,
      );
      expect(withHierarchical.style, same(GridStyles.hierarchical));

      final withNone = original.copyWith(style: GridStyles.none);
      expect(withNone.style, same(GridStyles.none));
    });

    test('NodeFlowTheme can use different grid styles', () {
      final styles = <GridStyle>[
        GridStyles.lines,
        GridStyles.dots,
        GridStyles.cross,
        GridStyles.hierarchical,
        GridStyles.none,
      ];

      for (final style in styles) {
        final theme = NodeFlowTheme.light.copyWith(
          gridTheme: GridTheme.light.copyWith(style: style),
        );

        expect(theme.gridTheme.style, same(style));
      }
    });

    test('light theme uses dots style by default', () {
      expect(GridTheme.light.style, same(GridStyles.dots));
    });

    test('dark theme uses dots style by default', () {
      expect(GridTheme.dark.style, same(GridStyles.dots));
    });
  });

  group('GridTheme Properties', () {
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

  group('Edge Cases and Boundary Conditions', () {
    test('very small canvas size', () {
      final styles = <GridStyle>[
        GridStyles.lines,
        GridStyles.dots,
        GridStyles.cross,
        GridStyles.hierarchical,
      ];

      final recorder = PictureRecorder();
      final canvas = Canvas(recorder);
      final viewport = createTestViewport();

      for (final style in styles) {
        expect(
          () => style.paint(
            canvas,
            const Size(1, 1),
            NodeFlowTheme.light,
            viewport,
          ),
          returnsNormally,
        );
      }
    });

    test('zero canvas size', () {
      final styles = <GridStyle>[
        GridStyles.lines,
        GridStyles.dots,
        GridStyles.cross,
        GridStyles.hierarchical,
      ];

      final recorder = PictureRecorder();
      final canvas = Canvas(recorder);
      final viewport = createTestViewport();

      for (final style in styles) {
        expect(
          () => style.paint(canvas, Size.zero, NodeFlowTheme.light, viewport),
          returnsNormally,
        );
      }
    });

    test('very large canvas size', () {
      final styles = <GridStyle>[
        GridStyles.lines,
        GridStyles.dots,
        GridStyles.cross,
        GridStyles.hierarchical,
      ];

      final recorder = PictureRecorder();
      final canvas = Canvas(recorder);
      final viewport = createTestViewport();

      for (final style in styles) {
        expect(
          () => style.paint(
            canvas,
            const Size(10000, 10000),
            NodeFlowTheme.light,
            viewport,
          ),
          returnsNormally,
        );
      }
    });

    test('combined extreme viewport and canvas', () {
      final style = GridStyles.lines;
      final recorder = PictureRecorder();
      final canvas = Canvas(recorder);

      // Extreme zoom out with large pan
      final viewport = createTestViewport(x: -5000.0, y: -5000.0, zoom: 0.1);

      expect(
        () => style.paint(
          canvas,
          const Size(1920, 1080),
          NodeFlowTheme.light,
          viewport,
        ),
        returnsNormally,
      );
    });

    test('theme with very small grid size', () {
      final style = GridStyles.lines;
      final recorder = PictureRecorder();
      final canvas = Canvas(recorder);
      final viewport = createTestViewport();

      final theme = NodeFlowTheme.light.copyWith(
        gridTheme: GridTheme.light.copyWith(size: 0.1),
      );

      // This should still work, though it may render many lines
      expect(
        () => style.paint(
          canvas,
          const Size(100, 100), // Small canvas to limit iterations
          theme,
          viewport,
        ),
        returnsNormally,
      );
    });

    test('theme with very large grid size', () {
      final style = GridStyles.lines;
      final recorder = PictureRecorder();
      final canvas = Canvas(recorder);
      final viewport = createTestViewport();

      final theme = NodeFlowTheme.light.copyWith(
        gridTheme: GridTheme.light.copyWith(size: 1000.0),
      );

      expect(
        () => style.paint(canvas, const Size(800, 600), theme, viewport),
        returnsNormally,
      );
    });

    test('theme with transparent color', () {
      final style = GridStyles.lines;
      final recorder = PictureRecorder();
      final canvas = Canvas(recorder);
      final viewport = createTestViewport();

      final theme = NodeFlowTheme.light.copyWith(
        gridTheme: GridTheme.light.copyWith(color: Colors.transparent),
      );

      expect(
        () => style.paint(canvas, const Size(800, 600), theme, viewport),
        returnsNormally,
      );
    });

    test('theme with zero thickness', () {
      final style = GridStyles.lines;
      final recorder = PictureRecorder();
      final canvas = Canvas(recorder);
      final viewport = createTestViewport();

      final theme = NodeFlowTheme.light.copyWith(
        gridTheme: GridTheme.light.copyWith(thickness: 0.0),
      );

      expect(
        () => style.paint(canvas, const Size(800, 600), theme, viewport),
        returnsNormally,
      );
    });
  });

  group('All Styles Painting Comparison', () {
    test('all styles can paint to the same canvas sequentially', () {
      final styles = <GridStyle>[
        GridStyles.lines,
        GridStyles.dots,
        GridStyles.cross,
        GridStyles.hierarchical,
        GridStyles.none,
      ];

      final recorder = PictureRecorder();
      final canvas = Canvas(recorder);
      final viewport = createTestViewport();

      // Paint all styles sequentially to same canvas
      for (final style in styles) {
        expect(
          () => style.paint(
            canvas,
            const Size(800, 600),
            NodeFlowTheme.light,
            viewport,
          ),
          returnsNormally,
          reason: 'Style ${style.runtimeType} should paint without error',
        );
      }

      // Complete the recording
      final picture = recorder.endRecording();
      expect(picture, isNotNull);
    });

    test('styles can paint with both light and dark themes', () {
      final styles = <GridStyle>[
        GridStyles.lines,
        GridStyles.dots,
        GridStyles.cross,
        GridStyles.hierarchical,
        GridStyles.none,
      ];

      final themes = [NodeFlowTheme.light, NodeFlowTheme.dark];

      for (final theme in themes) {
        for (final style in styles) {
          final recorder = PictureRecorder();
          final canvas = Canvas(recorder);
          final viewport = createTestViewport();

          expect(
            () => style.paint(canvas, const Size(800, 600), theme, viewport),
            returnsNormally,
            reason:
                'Style ${style.runtimeType} should paint with ${theme == NodeFlowTheme.light ? "light" : "dark"} theme',
          );

          recorder.endRecording();
        }
      }
    });
  });

  group('Runtime Type Verification', () {
    test('each style has unique runtime type', () {
      final runtimeTypes = <Type>{};

      for (final style in [
        GridStyles.lines,
        GridStyles.dots,
        GridStyles.cross,
        GridStyles.hierarchical,
        GridStyles.none,
      ]) {
        expect(
          runtimeTypes.add(style.runtimeType),
          isTrue,
          reason: 'Each style should have a unique runtime type',
        );
      }
    });

    test('styles are not mutable', () {
      // GridStyle instances should be const and immutable
      // We verify this by checking they are the same instance on multiple accesses
      final lines1 = GridStyles.lines;
      final lines2 = GridStyles.lines;
      expect(identical(lines1, lines2), isTrue);
    });
  });
}
