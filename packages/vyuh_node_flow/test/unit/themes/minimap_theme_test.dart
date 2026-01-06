/// Comprehensive tests for MinimapTheme.
///
/// Tests MinimapTheme construction, predefined themes, copyWith functionality,
/// and all theme properties.
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vyuh_node_flow/vyuh_node_flow.dart';

void main() {
  group('MinimapTheme', () {
    group('Construction', () {
      test('creates with default values', () {
        const theme = MinimapTheme();

        expect(theme.backgroundColor, equals(const Color(0xFFF5F5F5)));
        expect(theme.nodeColor, equals(const Color(0xFF1976D2)));
        expect(theme.viewportColor, equals(const Color(0xFF1976D2)));
        expect(theme.viewportFillOpacity, equals(0.1));
        expect(theme.viewportBorderOpacity, equals(0.4));
        expect(theme.borderColor, equals(const Color(0xFFBDBDBD)));
        expect(theme.borderWidth, equals(1.0));
        expect(theme.borderRadius, equals(4.0));
        expect(theme.padding, equals(const EdgeInsets.all(4.0)));
        expect(theme.showViewport, isTrue);
        expect(theme.nodeBorderRadius, equals(2.0));
      });

      test('creates with custom backgroundColor', () {
        const theme = MinimapTheme(backgroundColor: Colors.red);

        expect(theme.backgroundColor, equals(Colors.red));
      });

      test('creates with custom nodeColor', () {
        const theme = MinimapTheme(nodeColor: Colors.green);

        expect(theme.nodeColor, equals(Colors.green));
      });

      test('creates with custom viewportColor', () {
        const theme = MinimapTheme(viewportColor: Colors.orange);

        expect(theme.viewportColor, equals(Colors.orange));
      });

      test('creates with custom viewportFillOpacity', () {
        const theme = MinimapTheme(viewportFillOpacity: 0.25);

        expect(theme.viewportFillOpacity, equals(0.25));
      });

      test('creates with custom viewportBorderOpacity', () {
        const theme = MinimapTheme(viewportBorderOpacity: 0.6);

        expect(theme.viewportBorderOpacity, equals(0.6));
      });

      test('creates with custom borderColor', () {
        const theme = MinimapTheme(borderColor: Colors.purple);

        expect(theme.borderColor, equals(Colors.purple));
      });

      test('creates with custom borderWidth', () {
        const theme = MinimapTheme(borderWidth: 2.5);

        expect(theme.borderWidth, equals(2.5));
      });

      test('creates with custom borderRadius', () {
        const theme = MinimapTheme(borderRadius: 8.0);

        expect(theme.borderRadius, equals(8.0));
      });

      test('creates with custom padding', () {
        const theme = MinimapTheme(padding: EdgeInsets.all(12.0));

        expect(theme.padding, equals(const EdgeInsets.all(12.0)));
      });

      test('creates with showViewport set to false', () {
        const theme = MinimapTheme(showViewport: false);

        expect(theme.showViewport, isFalse);
      });

      test('creates with custom nodeBorderRadius', () {
        const theme = MinimapTheme(nodeBorderRadius: 4.0);

        expect(theme.nodeBorderRadius, equals(4.0));
      });

      test('creates with all custom properties', () {
        const theme = MinimapTheme(
          backgroundColor: Colors.black,
          nodeColor: Colors.white,
          viewportColor: Colors.cyan,
          viewportFillOpacity: 0.2,
          viewportBorderOpacity: 0.5,
          borderColor: Colors.grey,
          borderWidth: 3.0,
          borderRadius: 10.0,
          padding: EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
          showViewport: false,
          nodeBorderRadius: 5.0,
        );

        expect(theme.backgroundColor, equals(Colors.black));
        expect(theme.nodeColor, equals(Colors.white));
        expect(theme.viewportColor, equals(Colors.cyan));
        expect(theme.viewportFillOpacity, equals(0.2));
        expect(theme.viewportBorderOpacity, equals(0.5));
        expect(theme.borderColor, equals(Colors.grey));
        expect(theme.borderWidth, equals(3.0));
        expect(theme.borderRadius, equals(10.0));
        expect(
          theme.padding,
          equals(const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0)),
        );
        expect(theme.showViewport, isFalse);
        expect(theme.nodeBorderRadius, equals(5.0));
      });
    });

    group('Predefined Themes', () {
      test('light theme is available', () {
        expect(MinimapTheme.light, isNotNull);
      });

      test('dark theme is available', () {
        expect(MinimapTheme.dark, isNotNull);
      });

      test('light theme has correct backgroundColor', () {
        expect(
          MinimapTheme.light.backgroundColor,
          equals(const Color(0xFFF5F5F5)),
        );
      });

      test('dark theme has correct backgroundColor', () {
        expect(
          MinimapTheme.dark.backgroundColor,
          equals(const Color(0xFF2D2D2D)),
        );
      });

      test('light theme has correct nodeColor', () {
        expect(MinimapTheme.light.nodeColor, equals(const Color(0xFF1976D2)));
      });

      test('dark theme has correct nodeColor', () {
        expect(MinimapTheme.dark.nodeColor, equals(const Color(0xFF64B5F6)));
      });

      test('light theme has correct viewportColor', () {
        expect(
          MinimapTheme.light.viewportColor,
          equals(const Color(0xFF1976D2)),
        );
      });

      test('dark theme has correct viewportColor', () {
        expect(
          MinimapTheme.dark.viewportColor,
          equals(const Color(0xFF64B5F6)),
        );
      });

      test('light theme has correct borderColor', () {
        expect(MinimapTheme.light.borderColor, equals(const Color(0xFFBDBDBD)));
      });

      test('dark theme has correct borderColor', () {
        expect(MinimapTheme.dark.borderColor, equals(const Color(0xFF424242)));
      });

      test('light and dark themes have different backgroundColors', () {
        expect(
          MinimapTheme.light.backgroundColor,
          isNot(equals(MinimapTheme.dark.backgroundColor)),
        );
      });

      test('light and dark themes have different nodeColors', () {
        expect(
          MinimapTheme.light.nodeColor,
          isNot(equals(MinimapTheme.dark.nodeColor)),
        );
      });

      test('light and dark themes have different viewportColors', () {
        expect(
          MinimapTheme.light.viewportColor,
          isNot(equals(MinimapTheme.dark.viewportColor)),
        );
      });

      test('light and dark themes have different borderColors', () {
        expect(
          MinimapTheme.light.borderColor,
          isNot(equals(MinimapTheme.dark.borderColor)),
        );
      });

      test('both themes have default viewportFillOpacity', () {
        expect(MinimapTheme.light.viewportFillOpacity, equals(0.1));
        expect(MinimapTheme.dark.viewportFillOpacity, equals(0.1));
      });

      test('both themes have default viewportBorderOpacity', () {
        expect(MinimapTheme.light.viewportBorderOpacity, equals(0.4));
        expect(MinimapTheme.dark.viewportBorderOpacity, equals(0.4));
      });

      test('both themes have default borderWidth', () {
        expect(MinimapTheme.light.borderWidth, equals(1.0));
        expect(MinimapTheme.dark.borderWidth, equals(1.0));
      });

      test('both themes have default borderRadius', () {
        expect(MinimapTheme.light.borderRadius, equals(4.0));
        expect(MinimapTheme.dark.borderRadius, equals(4.0));
      });

      test('both themes have default padding', () {
        expect(MinimapTheme.light.padding, equals(const EdgeInsets.all(4.0)));
        expect(MinimapTheme.dark.padding, equals(const EdgeInsets.all(4.0)));
      });

      test('both themes have default showViewport', () {
        expect(MinimapTheme.light.showViewport, isTrue);
        expect(MinimapTheme.dark.showViewport, isTrue);
      });

      test('both themes have default nodeBorderRadius', () {
        expect(MinimapTheme.light.nodeBorderRadius, equals(2.0));
        expect(MinimapTheme.dark.nodeBorderRadius, equals(2.0));
      });
    });

    group('copyWith', () {
      test('copies with new backgroundColor', () {
        const original = MinimapTheme.light;
        final copied = original.copyWith(backgroundColor: Colors.yellow);

        expect(copied.backgroundColor, equals(Colors.yellow));
        expect(copied.nodeColor, equals(original.nodeColor));
        expect(copied.viewportColor, equals(original.viewportColor));
        expect(copied.borderColor, equals(original.borderColor));
      });

      test('copies with new nodeColor', () {
        const original = MinimapTheme.light;
        final copied = original.copyWith(nodeColor: Colors.pink);

        expect(copied.nodeColor, equals(Colors.pink));
        expect(copied.backgroundColor, equals(original.backgroundColor));
      });

      test('copies with new viewportColor', () {
        const original = MinimapTheme.light;
        final copied = original.copyWith(viewportColor: Colors.teal);

        expect(copied.viewportColor, equals(Colors.teal));
        expect(copied.backgroundColor, equals(original.backgroundColor));
      });

      test('copies with new viewportFillOpacity', () {
        const original = MinimapTheme.light;
        final copied = original.copyWith(viewportFillOpacity: 0.3);

        expect(copied.viewportFillOpacity, equals(0.3));
        expect(
          copied.viewportBorderOpacity,
          equals(original.viewportBorderOpacity),
        );
      });

      test('copies with new viewportBorderOpacity', () {
        const original = MinimapTheme.light;
        final copied = original.copyWith(viewportBorderOpacity: 0.7);

        expect(copied.viewportBorderOpacity, equals(0.7));
        expect(
          copied.viewportFillOpacity,
          equals(original.viewportFillOpacity),
        );
      });

      test('copies with new borderColor', () {
        const original = MinimapTheme.light;
        final copied = original.copyWith(borderColor: Colors.brown);

        expect(copied.borderColor, equals(Colors.brown));
        expect(copied.backgroundColor, equals(original.backgroundColor));
      });

      test('copies with new borderWidth', () {
        const original = MinimapTheme.light;
        final copied = original.copyWith(borderWidth: 4.0);

        expect(copied.borderWidth, equals(4.0));
        expect(copied.borderRadius, equals(original.borderRadius));
      });

      test('copies with new borderRadius', () {
        const original = MinimapTheme.light;
        final copied = original.copyWith(borderRadius: 12.0);

        expect(copied.borderRadius, equals(12.0));
        expect(copied.borderWidth, equals(original.borderWidth));
      });

      test('copies with new padding', () {
        const original = MinimapTheme.light;
        final copied = original.copyWith(padding: const EdgeInsets.all(16.0));

        expect(copied.padding, equals(const EdgeInsets.all(16.0)));
        expect(copied.borderRadius, equals(original.borderRadius));
      });

      test('copies with new showViewport', () {
        const original = MinimapTheme.light;
        final copied = original.copyWith(showViewport: false);

        expect(copied.showViewport, isFalse);
        expect(copied.viewportColor, equals(original.viewportColor));
      });

      test('copies with new nodeBorderRadius', () {
        const original = MinimapTheme.light;
        final copied = original.copyWith(nodeBorderRadius: 6.0);

        expect(copied.nodeBorderRadius, equals(6.0));
        expect(copied.nodeColor, equals(original.nodeColor));
      });

      test('preserves all values when no parameters provided', () {
        const original = MinimapTheme.light;
        final copied = original.copyWith();

        expect(copied.backgroundColor, equals(original.backgroundColor));
        expect(copied.nodeColor, equals(original.nodeColor));
        expect(copied.viewportColor, equals(original.viewportColor));
        expect(
          copied.viewportFillOpacity,
          equals(original.viewportFillOpacity),
        );
        expect(
          copied.viewportBorderOpacity,
          equals(original.viewportBorderOpacity),
        );
        expect(copied.borderColor, equals(original.borderColor));
        expect(copied.borderWidth, equals(original.borderWidth));
        expect(copied.borderRadius, equals(original.borderRadius));
        expect(copied.padding, equals(original.padding));
        expect(copied.showViewport, equals(original.showViewport));
        expect(copied.nodeBorderRadius, equals(original.nodeBorderRadius));
      });

      test('copies multiple properties at once', () {
        const original = MinimapTheme.light;
        final copied = original.copyWith(
          backgroundColor: Colors.indigo,
          nodeColor: Colors.amber,
          viewportColor: Colors.lime,
          borderColor: Colors.deepOrange,
          showViewport: false,
        );

        expect(copied.backgroundColor, equals(Colors.indigo));
        expect(copied.nodeColor, equals(Colors.amber));
        expect(copied.viewportColor, equals(Colors.lime));
        expect(copied.borderColor, equals(Colors.deepOrange));
        expect(copied.showViewport, isFalse);
        // Unchanged properties
        expect(
          copied.viewportFillOpacity,
          equals(original.viewportFillOpacity),
        );
        expect(
          copied.viewportBorderOpacity,
          equals(original.viewportBorderOpacity),
        );
        expect(copied.borderWidth, equals(original.borderWidth));
        expect(copied.borderRadius, equals(original.borderRadius));
        expect(copied.padding, equals(original.padding));
        expect(copied.nodeBorderRadius, equals(original.nodeBorderRadius));
      });

      test('can chain copyWith calls', () {
        const original = MinimapTheme.light;
        final copied = original
            .copyWith(backgroundColor: Colors.red)
            .copyWith(nodeColor: Colors.green)
            .copyWith(borderRadius: 20.0);

        expect(copied.backgroundColor, equals(Colors.red));
        expect(copied.nodeColor, equals(Colors.green));
        expect(copied.borderRadius, equals(20.0));
        expect(copied.viewportColor, equals(original.viewportColor));
      });
    });

    group('Theme Properties', () {
      group('viewportFillOpacity', () {
        test('accepts zero opacity', () {
          const theme = MinimapTheme(viewportFillOpacity: 0.0);

          expect(theme.viewportFillOpacity, equals(0.0));
        });

        test('accepts full opacity', () {
          const theme = MinimapTheme(viewportFillOpacity: 1.0);

          expect(theme.viewportFillOpacity, equals(1.0));
        });

        test('accepts fractional opacity', () {
          const theme = MinimapTheme(viewportFillOpacity: 0.5);

          expect(theme.viewportFillOpacity, equals(0.5));
        });
      });

      group('viewportBorderOpacity', () {
        test('accepts zero opacity', () {
          const theme = MinimapTheme(viewportBorderOpacity: 0.0);

          expect(theme.viewportBorderOpacity, equals(0.0));
        });

        test('accepts full opacity', () {
          const theme = MinimapTheme(viewportBorderOpacity: 1.0);

          expect(theme.viewportBorderOpacity, equals(1.0));
        });

        test('accepts fractional opacity', () {
          const theme = MinimapTheme(viewportBorderOpacity: 0.5);

          expect(theme.viewportBorderOpacity, equals(0.5));
        });
      });

      group('borderWidth', () {
        test('accepts zero width', () {
          const theme = MinimapTheme(borderWidth: 0.0);

          expect(theme.borderWidth, equals(0.0));
        });

        test('accepts large width', () {
          const theme = MinimapTheme(borderWidth: 10.0);

          expect(theme.borderWidth, equals(10.0));
        });
      });

      group('borderRadius', () {
        test('accepts zero radius', () {
          const theme = MinimapTheme(borderRadius: 0.0);

          expect(theme.borderRadius, equals(0.0));
        });

        test('accepts large radius', () {
          const theme = MinimapTheme(borderRadius: 50.0);

          expect(theme.borderRadius, equals(50.0));
        });
      });

      group('nodeBorderRadius', () {
        test('accepts zero radius', () {
          const theme = MinimapTheme(nodeBorderRadius: 0.0);

          expect(theme.nodeBorderRadius, equals(0.0));
        });

        test('accepts large radius', () {
          const theme = MinimapTheme(nodeBorderRadius: 20.0);

          expect(theme.nodeBorderRadius, equals(20.0));
        });
      });

      group('padding', () {
        test('accepts zero padding', () {
          const theme = MinimapTheme(padding: EdgeInsets.zero);

          expect(theme.padding, equals(EdgeInsets.zero));
        });

        test('accepts asymmetric padding', () {
          const padding = EdgeInsets.only(
            left: 8,
            top: 4,
            right: 12,
            bottom: 6,
          );
          const theme = MinimapTheme(padding: padding);

          expect(theme.padding, equals(padding));
        });

        test('accepts large padding', () {
          const theme = MinimapTheme(padding: EdgeInsets.all(32.0));

          expect(theme.padding, equals(const EdgeInsets.all(32.0)));
        });
      });

      group('showViewport', () {
        test('defaults to true', () {
          const theme = MinimapTheme();

          expect(theme.showViewport, isTrue);
        });

        test('can be set to false', () {
          const theme = MinimapTheme(showViewport: false);

          expect(theme.showViewport, isFalse);
        });

        test('can be set to true explicitly', () {
          const theme = MinimapTheme(showViewport: true);

          expect(theme.showViewport, isTrue);
        });
      });
    });

    group('Type', () {
      test('is const-constructible', () {
        const theme = MinimapTheme();

        expect(theme, isNotNull);
      });

      test('light theme is const', () {
        const theme = MinimapTheme.light;

        expect(theme, isNotNull);
      });

      test('dark theme is const', () {
        const theme = MinimapTheme.dark;

        expect(theme, isNotNull);
      });
    });
  });

  group('MinimapPosition', () {
    test('has topLeft value', () {
      expect(MinimapPosition.topLeft, isNotNull);
    });

    test('has topRight value', () {
      expect(MinimapPosition.topRight, isNotNull);
    });

    test('has bottomLeft value', () {
      expect(MinimapPosition.bottomLeft, isNotNull);
    });

    test('has bottomRight value', () {
      expect(MinimapPosition.bottomRight, isNotNull);
    });

    test('all values are distinct', () {
      final values = MinimapPosition.values;
      expect(values.toSet().length, equals(values.length));
    });

    test('has exactly 4 positions', () {
      expect(MinimapPosition.values.length, equals(4));
    });
  });
}
