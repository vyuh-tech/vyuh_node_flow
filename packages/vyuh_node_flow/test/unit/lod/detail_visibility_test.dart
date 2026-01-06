/// Unit tests for the [DetailVisibility] configuration class.
///
/// Tests cover:
/// - DetailVisibility class construction with all parameters
/// - Predefined presets (minimal, standard, full)
/// - Individual visibility flags and their defaults
/// - copyWith functionality for creating modified copies
/// - Equality and hash code behavior
/// - toString representation
@Tags(['unit'])
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:vyuh_node_flow/vyuh_node_flow.dart';

void main() {
  // ===========================================================================
  // DetailVisibility - Construction
  // ===========================================================================

  group('DetailVisibility - Construction', () {
    test('default constructor creates full visibility', () {
      const visibility = DetailVisibility();

      expect(visibility.showNodeContent, isTrue);
      expect(visibility.showPorts, isTrue);
      expect(visibility.showPortLabels, isTrue);
      expect(visibility.showConnectionLines, isTrue);
      expect(visibility.showConnectionLabels, isTrue);
      expect(visibility.showConnectionEndpoints, isTrue);
      expect(visibility.showResizeHandles, isTrue);
    });

    test('constructor accepts all visibility flags as false', () {
      const visibility = DetailVisibility(
        showNodeContent: false,
        showPorts: false,
        showPortLabels: false,
        showConnectionLines: false,
        showConnectionLabels: false,
        showConnectionEndpoints: false,
        showResizeHandles: false,
      );

      expect(visibility.showNodeContent, isFalse);
      expect(visibility.showPorts, isFalse);
      expect(visibility.showPortLabels, isFalse);
      expect(visibility.showConnectionLines, isFalse);
      expect(visibility.showConnectionLabels, isFalse);
      expect(visibility.showConnectionEndpoints, isFalse);
      expect(visibility.showResizeHandles, isFalse);
    });

    test('constructor allows mixed visibility flags', () {
      const visibility = DetailVisibility(
        showNodeContent: true,
        showPorts: false,
        showPortLabels: true,
        showConnectionLines: false,
        showConnectionLabels: true,
        showConnectionEndpoints: false,
        showResizeHandles: true,
      );

      expect(visibility.showNodeContent, isTrue);
      expect(visibility.showPorts, isFalse);
      expect(visibility.showPortLabels, isTrue);
      expect(visibility.showConnectionLines, isFalse);
      expect(visibility.showConnectionLabels, isTrue);
      expect(visibility.showConnectionEndpoints, isFalse);
      expect(visibility.showResizeHandles, isTrue);
    });

    test('const constructor allows compile-time initialization', () {
      // This should compile without errors
      const visibility = DetailVisibility(
        showNodeContent: true,
        showPorts: true,
      );

      expect(visibility, isNotNull);
    });
  });

  // ===========================================================================
  // DetailVisibility - Predefined Presets
  // ===========================================================================

  group('DetailVisibility - Predefined Presets', () {
    group('minimal preset', () {
      test('hides most elements', () {
        const visibility = DetailVisibility.minimal;

        expect(visibility.showNodeContent, isFalse);
        expect(visibility.showPorts, isFalse);
        expect(visibility.showPortLabels, isFalse);
        expect(visibility.showConnectionLabels, isFalse);
        expect(visibility.showConnectionEndpoints, isFalse);
        expect(visibility.showResizeHandles, isFalse);
      });

      test('keeps connection lines visible for graph structure', () {
        const visibility = DetailVisibility.minimal;

        expect(visibility.showConnectionLines, isTrue);
      });

      test('is a const value', () {
        // Verify minimal is available as a compile-time constant
        const visibilityList = [DetailVisibility.minimal];
        expect(visibilityList.length, equals(1));
      });
    });

    group('standard preset', () {
      test('shows node content and connection lines', () {
        const visibility = DetailVisibility.standard;

        expect(visibility.showNodeContent, isTrue);
        expect(visibility.showConnectionLines, isTrue);
      });

      test('hides ports and labels for cleaner appearance', () {
        const visibility = DetailVisibility.standard;

        expect(visibility.showPorts, isFalse);
        expect(visibility.showPortLabels, isFalse);
        expect(visibility.showConnectionLabels, isFalse);
        expect(visibility.showConnectionEndpoints, isFalse);
        expect(visibility.showResizeHandles, isFalse);
      });

      test('is a const value', () {
        const visibilityList = [DetailVisibility.standard];
        expect(visibilityList.length, equals(1));
      });
    });

    group('full preset', () {
      test('shows all elements', () {
        const visibility = DetailVisibility.full;

        expect(visibility.showNodeContent, isTrue);
        expect(visibility.showPorts, isTrue);
        expect(visibility.showPortLabels, isTrue);
        expect(visibility.showConnectionLines, isTrue);
        expect(visibility.showConnectionLabels, isTrue);
        expect(visibility.showConnectionEndpoints, isTrue);
        expect(visibility.showResizeHandles, isTrue);
      });

      test('equals default constructor', () {
        const full = DetailVisibility.full;
        const defaultVisibility = DetailVisibility();

        expect(full, equals(defaultVisibility));
      });

      test('is a const value', () {
        const visibilityList = [DetailVisibility.full];
        expect(visibilityList.length, equals(1));
      });
    });

    test('presets are distinct from each other', () {
      const minimal = DetailVisibility.minimal;
      const standard = DetailVisibility.standard;
      const full = DetailVisibility.full;

      expect(minimal, isNot(equals(standard)));
      expect(minimal, isNot(equals(full)));
      expect(standard, isNot(equals(full)));
    });

    test('presets form a progression from less to more visible', () {
      const minimal = DetailVisibility.minimal;
      const standard = DetailVisibility.standard;
      const full = DetailVisibility.full;

      // Minimal shows the least
      final minimalVisibleCount = _countVisibleFlags(minimal);
      final standardVisibleCount = _countVisibleFlags(standard);
      final fullVisibleCount = _countVisibleFlags(full);

      expect(minimalVisibleCount, lessThan(standardVisibleCount));
      expect(standardVisibleCount, lessThan(fullVisibleCount));
    });
  });

  // ===========================================================================
  // DetailVisibility - Individual Visibility Flags
  // ===========================================================================

  group('DetailVisibility - Individual Visibility Flags', () {
    test('showNodeContent controls node content visibility', () {
      const visible = DetailVisibility(showNodeContent: true);
      const hidden = DetailVisibility(showNodeContent: false);

      expect(visible.showNodeContent, isTrue);
      expect(hidden.showNodeContent, isFalse);
    });

    test('showPorts controls port visibility', () {
      const visible = DetailVisibility(showPorts: true);
      const hidden = DetailVisibility(showPorts: false);

      expect(visible.showPorts, isTrue);
      expect(hidden.showPorts, isFalse);
    });

    test('showPortLabels controls port label visibility', () {
      const visible = DetailVisibility(showPortLabels: true);
      const hidden = DetailVisibility(showPortLabels: false);

      expect(visible.showPortLabels, isTrue);
      expect(hidden.showPortLabels, isFalse);
    });

    test('showConnectionLines controls connection line visibility', () {
      const visible = DetailVisibility(showConnectionLines: true);
      const hidden = DetailVisibility(showConnectionLines: false);

      expect(visible.showConnectionLines, isTrue);
      expect(hidden.showConnectionLines, isFalse);
    });

    test('showConnectionLabels controls connection label visibility', () {
      const visible = DetailVisibility(showConnectionLabels: true);
      const hidden = DetailVisibility(showConnectionLabels: false);

      expect(visible.showConnectionLabels, isTrue);
      expect(hidden.showConnectionLabels, isFalse);
    });

    test('showConnectionEndpoints controls connection endpoint visibility', () {
      const visible = DetailVisibility(showConnectionEndpoints: true);
      const hidden = DetailVisibility(showConnectionEndpoints: false);

      expect(visible.showConnectionEndpoints, isTrue);
      expect(hidden.showConnectionEndpoints, isFalse);
    });

    test('showResizeHandles controls resize handle visibility', () {
      const visible = DetailVisibility(showResizeHandles: true);
      const hidden = DetailVisibility(showResizeHandles: false);

      expect(visible.showResizeHandles, isTrue);
      expect(hidden.showResizeHandles, isFalse);
    });

    test('flags are independent of each other', () {
      // Only showNodeContent is true
      const onlyNodeContent = DetailVisibility(
        showNodeContent: true,
        showPorts: false,
        showPortLabels: false,
        showConnectionLines: false,
        showConnectionLabels: false,
        showConnectionEndpoints: false,
        showResizeHandles: false,
      );

      expect(onlyNodeContent.showNodeContent, isTrue);
      expect(onlyNodeContent.showPorts, isFalse);
      expect(onlyNodeContent.showPortLabels, isFalse);
      expect(onlyNodeContent.showConnectionLines, isFalse);
      expect(onlyNodeContent.showConnectionLabels, isFalse);
      expect(onlyNodeContent.showConnectionEndpoints, isFalse);
      expect(onlyNodeContent.showResizeHandles, isFalse);
    });
  });

  // ===========================================================================
  // DetailVisibility - copyWith
  // ===========================================================================

  group('DetailVisibility - copyWith', () {
    test('copyWith returns identical copy when no parameters given', () {
      const original = DetailVisibility.full;
      final copy = original.copyWith();

      expect(copy, equals(original));
      expect(copy.showNodeContent, equals(original.showNodeContent));
      expect(copy.showPorts, equals(original.showPorts));
      expect(copy.showPortLabels, equals(original.showPortLabels));
      expect(copy.showConnectionLines, equals(original.showConnectionLines));
      expect(copy.showConnectionLabels, equals(original.showConnectionLabels));
      expect(
        copy.showConnectionEndpoints,
        equals(original.showConnectionEndpoints),
      );
      expect(copy.showResizeHandles, equals(original.showResizeHandles));
    });

    test('copyWith updates showNodeContent', () {
      const original = DetailVisibility.full;
      final copy = original.copyWith(showNodeContent: false);

      expect(copy.showNodeContent, isFalse);
      expect(copy.showPorts, isTrue);
      expect(copy.showPortLabels, isTrue);
      expect(copy.showConnectionLines, isTrue);
      expect(copy.showConnectionLabels, isTrue);
      expect(copy.showConnectionEndpoints, isTrue);
      expect(copy.showResizeHandles, isTrue);
    });

    test('copyWith updates showPorts', () {
      const original = DetailVisibility.full;
      final copy = original.copyWith(showPorts: false);

      expect(copy.showNodeContent, isTrue);
      expect(copy.showPorts, isFalse);
      expect(copy.showPortLabels, isTrue);
    });

    test('copyWith updates showPortLabels', () {
      const original = DetailVisibility.full;
      final copy = original.copyWith(showPortLabels: false);

      expect(copy.showPorts, isTrue);
      expect(copy.showPortLabels, isFalse);
      expect(copy.showConnectionLines, isTrue);
    });

    test('copyWith updates showConnectionLines', () {
      const original = DetailVisibility.full;
      final copy = original.copyWith(showConnectionLines: false);

      expect(copy.showPortLabels, isTrue);
      expect(copy.showConnectionLines, isFalse);
      expect(copy.showConnectionLabels, isTrue);
    });

    test('copyWith updates showConnectionLabels', () {
      const original = DetailVisibility.full;
      final copy = original.copyWith(showConnectionLabels: false);

      expect(copy.showConnectionLines, isTrue);
      expect(copy.showConnectionLabels, isFalse);
      expect(copy.showConnectionEndpoints, isTrue);
    });

    test('copyWith updates showConnectionEndpoints', () {
      const original = DetailVisibility.full;
      final copy = original.copyWith(showConnectionEndpoints: false);

      expect(copy.showConnectionLabels, isTrue);
      expect(copy.showConnectionEndpoints, isFalse);
      expect(copy.showResizeHandles, isTrue);
    });

    test('copyWith updates showResizeHandles', () {
      const original = DetailVisibility.full;
      final copy = original.copyWith(showResizeHandles: false);

      expect(copy.showConnectionEndpoints, isTrue);
      expect(copy.showResizeHandles, isFalse);
    });

    test('copyWith updates multiple fields simultaneously', () {
      const original = DetailVisibility.minimal;
      final copy = original.copyWith(
        showNodeContent: true,
        showPorts: true,
        showResizeHandles: true,
      );

      expect(copy.showNodeContent, isTrue);
      expect(copy.showPorts, isTrue);
      expect(copy.showPortLabels, isFalse); // Unchanged from minimal
      expect(copy.showConnectionLines, isTrue); // Unchanged from minimal
      expect(copy.showConnectionLabels, isFalse); // Unchanged from minimal
      expect(copy.showConnectionEndpoints, isFalse); // Unchanged from minimal
      expect(copy.showResizeHandles, isTrue);
    });

    test('copyWith does not modify original', () {
      const original = DetailVisibility.full;
      original.copyWith(showNodeContent: false, showPorts: false);

      // Original should be unchanged
      expect(original.showNodeContent, isTrue);
      expect(original.showPorts, isTrue);
    });

    test('copyWith can convert minimal to full', () {
      const minimal = DetailVisibility.minimal;
      final converted = minimal.copyWith(
        showNodeContent: true,
        showPorts: true,
        showPortLabels: true,
        showConnectionLines: true,
        showConnectionLabels: true,
        showConnectionEndpoints: true,
        showResizeHandles: true,
      );

      expect(converted, equals(DetailVisibility.full));
    });

    test('copyWith can convert full to minimal', () {
      const full = DetailVisibility.full;
      final converted = full.copyWith(
        showNodeContent: false,
        showPorts: false,
        showPortLabels: false,
        showConnectionLines: true,
        showConnectionLabels: false,
        showConnectionEndpoints: false,
        showResizeHandles: false,
      );

      expect(converted, equals(DetailVisibility.minimal));
    });

    test('chained copyWith calls work correctly', () {
      const original = DetailVisibility.minimal;
      final result = original
          .copyWith(showNodeContent: true)
          .copyWith(showPorts: true)
          .copyWith(showResizeHandles: true);

      expect(result.showNodeContent, isTrue);
      expect(result.showPorts, isTrue);
      expect(result.showPortLabels, isFalse);
      expect(result.showConnectionLines, isTrue);
      expect(result.showConnectionLabels, isFalse);
      expect(result.showConnectionEndpoints, isFalse);
      expect(result.showResizeHandles, isTrue);
    });
  });

  // ===========================================================================
  // DetailVisibility - Equality and HashCode
  // ===========================================================================

  group('DetailVisibility - Equality', () {
    test('identical instances are equal', () {
      const visibility1 = DetailVisibility.full;
      const visibility2 = DetailVisibility.full;

      expect(visibility1, equals(visibility2));
      expect(identical(visibility1, visibility2), isTrue);
    });

    test('instances with same values are equal', () {
      const visibility1 = DetailVisibility(
        showNodeContent: true,
        showPorts: false,
        showPortLabels: true,
        showConnectionLines: false,
        showConnectionLabels: true,
        showConnectionEndpoints: false,
        showResizeHandles: true,
      );
      const visibility2 = DetailVisibility(
        showNodeContent: true,
        showPorts: false,
        showPortLabels: true,
        showConnectionLines: false,
        showConnectionLabels: true,
        showConnectionEndpoints: false,
        showResizeHandles: true,
      );

      expect(visibility1, equals(visibility2));
    });

    test('instances with different showNodeContent are not equal', () {
      const visibility1 = DetailVisibility(showNodeContent: true);
      const visibility2 = DetailVisibility(showNodeContent: false);

      expect(visibility1, isNot(equals(visibility2)));
    });

    test('instances with different showPorts are not equal', () {
      const visibility1 = DetailVisibility(showPorts: true);
      const visibility2 = DetailVisibility(showPorts: false);

      expect(visibility1, isNot(equals(visibility2)));
    });

    test('instances with different showPortLabels are not equal', () {
      const visibility1 = DetailVisibility(showPortLabels: true);
      const visibility2 = DetailVisibility(showPortLabels: false);

      expect(visibility1, isNot(equals(visibility2)));
    });

    test('instances with different showConnectionLines are not equal', () {
      const visibility1 = DetailVisibility(showConnectionLines: true);
      const visibility2 = DetailVisibility(showConnectionLines: false);

      expect(visibility1, isNot(equals(visibility2)));
    });

    test('instances with different showConnectionLabels are not equal', () {
      const visibility1 = DetailVisibility(showConnectionLabels: true);
      const visibility2 = DetailVisibility(showConnectionLabels: false);

      expect(visibility1, isNot(equals(visibility2)));
    });

    test('instances with different showConnectionEndpoints are not equal', () {
      const visibility1 = DetailVisibility(showConnectionEndpoints: true);
      const visibility2 = DetailVisibility(showConnectionEndpoints: false);

      expect(visibility1, isNot(equals(visibility2)));
    });

    test('instances with different showResizeHandles are not equal', () {
      const visibility1 = DetailVisibility(showResizeHandles: true);
      const visibility2 = DetailVisibility(showResizeHandles: false);

      expect(visibility1, isNot(equals(visibility2)));
    });

    test('equality is symmetric', () {
      const visibility1 = DetailVisibility.standard;
      const visibility2 = DetailVisibility.standard;

      expect(visibility1 == visibility2, isTrue);
      expect(visibility2 == visibility1, isTrue);
    });

    test('equality is transitive', () {
      const visibility1 = DetailVisibility.minimal;
      const visibility2 = DetailVisibility.minimal;
      const visibility3 = DetailVisibility.minimal;

      expect(visibility1 == visibility2, isTrue);
      expect(visibility2 == visibility3, isTrue);
      expect(visibility1 == visibility3, isTrue);
    });

    test('not equal to null', () {
      const visibility = DetailVisibility.full;

      // Test that non-nullable type is not null (compile-time guaranteed)
      // ignore: unnecessary_null_comparison
      expect(visibility == null, isFalse);
    });

    test('not equal to different type', () {
      const visibility = DetailVisibility.full;

      // ignore: unrelated_type_equality_checks
      expect(visibility == 'not a visibility', isFalse);
    });
  });

  group('DetailVisibility - HashCode', () {
    test('equal instances have same hash code', () {
      const visibility1 = DetailVisibility.full;
      const visibility2 = DetailVisibility(
        showNodeContent: true,
        showPorts: true,
        showPortLabels: true,
        showConnectionLines: true,
        showConnectionLabels: true,
        showConnectionEndpoints: true,
        showResizeHandles: true,
      );

      expect(visibility1.hashCode, equals(visibility2.hashCode));
    });

    test('different instances have different hash codes', () {
      const minimal = DetailVisibility.minimal;
      const standard = DetailVisibility.standard;
      const full = DetailVisibility.full;

      // Different presets should have different hash codes
      expect(minimal.hashCode, isNot(equals(standard.hashCode)));
      expect(minimal.hashCode, isNot(equals(full.hashCode)));
      expect(standard.hashCode, isNot(equals(full.hashCode)));
    });

    test('hash code is consistent across calls', () {
      const visibility = DetailVisibility.standard;
      final hashCode1 = visibility.hashCode;
      final hashCode2 = visibility.hashCode;
      final hashCode3 = visibility.hashCode;

      expect(hashCode1, equals(hashCode2));
      expect(hashCode2, equals(hashCode3));
    });

    test('can be used in sets', () {
      const visibility1 = DetailVisibility.full;
      const visibility2 = DetailVisibility.full;
      const visibility3 = DetailVisibility.minimal;

      // Create set by adding elements to test deduplication
      final set = <DetailVisibility>{}
        ..add(visibility1)
        ..add(visibility2)
        ..add(visibility3);

      // visibility1 and visibility2 are equal, so set should have 2 elements
      expect(set.length, equals(2));
      expect(set.contains(DetailVisibility.full), isTrue);
      expect(set.contains(DetailVisibility.minimal), isTrue);
    });

    test('can be used as map keys', () {
      const full = DetailVisibility.full;
      const minimal = DetailVisibility.minimal;

      final map = <DetailVisibility, String>{
        full: 'Full visibility',
        minimal: 'Minimal visibility',
      };

      expect(map[DetailVisibility.full], equals('Full visibility'));
      expect(map[DetailVisibility.minimal], equals('Minimal visibility'));
    });
  });

  // ===========================================================================
  // DetailVisibility - toString
  // ===========================================================================

  group('DetailVisibility - toString', () {
    test('toString contains class name', () {
      const visibility = DetailVisibility.full;

      expect(visibility.toString(), contains('DetailVisibility'));
    });

    test('toString contains all property values', () {
      const visibility = DetailVisibility.full;
      final string = visibility.toString();

      expect(string, contains('showNodeContent: true'));
      expect(string, contains('showPorts: true'));
      expect(string, contains('showPortLabels: true'));
      expect(string, contains('showConnectionLines: true'));
      expect(string, contains('showConnectionLabels: true'));
      expect(string, contains('showConnectionEndpoints: true'));
      expect(string, contains('showResizeHandles: true'));
    });

    test('toString reflects false values', () {
      const visibility = DetailVisibility.minimal;
      final string = visibility.toString();

      expect(string, contains('showNodeContent: false'));
      expect(string, contains('showPorts: false'));
      expect(string, contains('showPortLabels: false'));
      expect(string, contains('showConnectionLines: true'));
      expect(string, contains('showConnectionLabels: false'));
      expect(string, contains('showConnectionEndpoints: false'));
      expect(string, contains('showResizeHandles: false'));
    });

    test('toString is consistent across calls', () {
      const visibility = DetailVisibility.standard;
      final string1 = visibility.toString();
      final string2 = visibility.toString();

      expect(string1, equals(string2));
    });
  });

  // ===========================================================================
  // DetailVisibility - Edge Cases
  // ===========================================================================

  group('DetailVisibility - Edge Cases', () {
    test('all flags true equals full preset', () {
      const custom = DetailVisibility(
        showNodeContent: true,
        showPorts: true,
        showPortLabels: true,
        showConnectionLines: true,
        showConnectionLabels: true,
        showConnectionEndpoints: true,
        showResizeHandles: true,
      );

      expect(custom, equals(DetailVisibility.full));
    });

    test(
      'all flags false differs from minimal (which has connectionLines)',
      () {
        const allFalse = DetailVisibility(
          showNodeContent: false,
          showPorts: false,
          showPortLabels: false,
          showConnectionLines: false,
          showConnectionLabels: false,
          showConnectionEndpoints: false,
          showResizeHandles: false,
        );

        expect(allFalse, isNot(equals(DetailVisibility.minimal)));
        expect(allFalse.showConnectionLines, isFalse);
        expect(DetailVisibility.minimal.showConnectionLines, isTrue);
      },
    );

    test('visibility can be stored in list', () {
      final visibilities = <DetailVisibility>[
        DetailVisibility.minimal,
        DetailVisibility.standard,
        DetailVisibility.full,
      ];

      expect(visibilities.length, equals(3));
      expect(visibilities[0], equals(DetailVisibility.minimal));
      expect(visibilities[1], equals(DetailVisibility.standard));
      expect(visibilities[2], equals(DetailVisibility.full));
    });

    test('visibility can be used in switch expression', () {
      const visibility = DetailVisibility.standard;

      // Test that visibility can be compared in conditions
      final result = switch (visibility) {
        DetailVisibility(showNodeContent: true, showPorts: false) => 'standard',
        DetailVisibility(showNodeContent: false) => 'minimal',
        _ => 'full',
      };

      expect(result, equals('standard'));
    });
  });
}

/// Helper function to count the number of visible flags in a DetailVisibility.
int _countVisibleFlags(DetailVisibility visibility) {
  var count = 0;
  if (visibility.showNodeContent) count++;
  if (visibility.showPorts) count++;
  if (visibility.showPortLabels) count++;
  if (visibility.showConnectionLines) count++;
  if (visibility.showConnectionLabels) count++;
  if (visibility.showConnectionEndpoints) count++;
  if (visibility.showResizeHandles) count++;
  return count;
}
