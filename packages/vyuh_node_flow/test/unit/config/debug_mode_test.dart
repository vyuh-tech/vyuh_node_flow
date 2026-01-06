/// Unit tests for the DebugMode enum and DebugExtension functionality.
///
/// Tests cover:
/// - DebugMode enum values and helper properties
/// - DebugMode helper methods (isEnabled, showSpatialIndex, showAutoPanZone)
/// - DebugExtension operations (toggle, set, cycle)
/// - Observable debug mode behavior
@Tags(['unit'])
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:vyuh_node_flow/vyuh_node_flow.dart';

void main() {
  // ===========================================================================
  // DebugMode Enum Values
  // ===========================================================================

  group('DebugMode - Enum Values', () {
    test('has four values', () {
      expect(DebugMode.values, hasLength(4));
    });

    test('contains expected values in order', () {
      expect(DebugMode.values[0], equals(DebugMode.none));
      expect(DebugMode.values[1], equals(DebugMode.all));
      expect(DebugMode.values[2], equals(DebugMode.spatialIndex));
      expect(DebugMode.values[3], equals(DebugMode.autoPanZone));
    });
  });

  // ===========================================================================
  // DebugMode.isEnabled Property
  // ===========================================================================

  group('DebugMode - isEnabled', () {
    test('none is not enabled', () {
      expect(DebugMode.none.isEnabled, isFalse);
    });

    test('all is enabled', () {
      expect(DebugMode.all.isEnabled, isTrue);
    });

    test('spatialIndex is enabled', () {
      expect(DebugMode.spatialIndex.isEnabled, isTrue);
    });

    test('autoPanZone is enabled', () {
      expect(DebugMode.autoPanZone.isEnabled, isTrue);
    });
  });

  // ===========================================================================
  // DebugMode.showSpatialIndex Property
  // ===========================================================================

  group('DebugMode - showSpatialIndex', () {
    test('none does not show spatial index', () {
      expect(DebugMode.none.showSpatialIndex, isFalse);
    });

    test('all shows spatial index', () {
      expect(DebugMode.all.showSpatialIndex, isTrue);
    });

    test('spatialIndex shows spatial index', () {
      expect(DebugMode.spatialIndex.showSpatialIndex, isTrue);
    });

    test('autoPanZone does not show spatial index', () {
      expect(DebugMode.autoPanZone.showSpatialIndex, isFalse);
    });
  });

  // ===========================================================================
  // DebugMode.showAutoPanZone Property
  // ===========================================================================

  group('DebugMode - showAutoPanZone', () {
    test('none does not show autopan zone', () {
      expect(DebugMode.none.showAutoPanZone, isFalse);
    });

    test('all shows autopan zone', () {
      expect(DebugMode.all.showAutoPanZone, isTrue);
    });

    test('spatialIndex does not show autopan zone', () {
      expect(DebugMode.spatialIndex.showAutoPanZone, isFalse);
    });

    test('autoPanZone shows autopan zone', () {
      expect(DebugMode.autoPanZone.showAutoPanZone, isTrue);
    });
  });

  // ===========================================================================
  // DebugMode Combinations
  // ===========================================================================

  group('DebugMode - Combinations', () {
    test('only all mode shows both overlays', () {
      for (final mode in DebugMode.values) {
        final showsBoth = mode.showSpatialIndex && mode.showAutoPanZone;
        if (mode == DebugMode.all) {
          expect(showsBoth, isTrue, reason: 'all mode should show both');
        } else {
          expect(showsBoth, isFalse, reason: '$mode should not show both');
        }
      }
    });

    test('each specific mode shows only its overlay', () {
      // spatialIndex shows only spatial index
      expect(DebugMode.spatialIndex.showSpatialIndex, isTrue);
      expect(DebugMode.spatialIndex.showAutoPanZone, isFalse);

      // autoPanZone shows only autopan zone
      expect(DebugMode.autoPanZone.showSpatialIndex, isFalse);
      expect(DebugMode.autoPanZone.showAutoPanZone, isTrue);
    });
  });

  // ===========================================================================
  // DebugExtension - Constructor
  // ===========================================================================

  group('DebugExtension - Constructor', () {
    test('defaults to DebugMode.none', () {
      final ext = DebugExtension();

      expect(ext.mode, equals(DebugMode.none));
    });

    test('accepts mode parameter', () {
      final ext = DebugExtension(mode: DebugMode.all);

      expect(ext.mode, equals(DebugMode.all));
    });

    test('accepts spatialIndex debug mode', () {
      final ext = DebugExtension(mode: DebugMode.spatialIndex);

      expect(ext.mode, equals(DebugMode.spatialIndex));
    });

    test('accepts autoPanZone debug mode', () {
      final ext = DebugExtension(mode: DebugMode.autoPanZone);

      expect(ext.mode, equals(DebugMode.autoPanZone));
    });

    test('has correct id', () {
      final ext = DebugExtension();

      expect(ext.id, equals('debug'));
    });

    test('mode returns current mode', () {
      final ext = DebugExtension(mode: DebugMode.all);

      expect(ext.mode, equals(DebugMode.all));
    });
  });

  // ===========================================================================
  // DebugExtension - toggle
  // ===========================================================================

  group('DebugExtension - toggle', () {
    test('toggles from none to all', () {
      final ext = DebugExtension(mode: DebugMode.none);

      ext.toggle();

      expect(ext.mode, equals(DebugMode.all));
    });

    test('toggles from all to none', () {
      final ext = DebugExtension(mode: DebugMode.all);

      ext.toggle();

      expect(ext.mode, equals(DebugMode.none));
    });

    test('toggles from spatialIndex to none', () {
      final ext = DebugExtension(mode: DebugMode.spatialIndex);

      ext.toggle();

      expect(ext.mode, equals(DebugMode.none));
    });

    test('toggles from autoPanZone to none', () {
      final ext = DebugExtension(mode: DebugMode.autoPanZone);

      ext.toggle();

      expect(ext.mode, equals(DebugMode.none));
    });
  });

  // ===========================================================================
  // DebugExtension - setMode
  // ===========================================================================

  group('DebugExtension - setMode', () {
    test('sets specific debug mode', () {
      final ext = DebugExtension(mode: DebugMode.none);

      ext.setMode(DebugMode.spatialIndex);

      expect(ext.mode, equals(DebugMode.spatialIndex));
    });

    test('can set to same mode', () {
      final ext = DebugExtension(mode: DebugMode.all);

      ext.setMode(DebugMode.all);

      expect(ext.mode, equals(DebugMode.all));
    });

    test('can set each debug mode value', () {
      final ext = DebugExtension();

      for (final mode in DebugMode.values) {
        ext.setMode(mode);
        expect(ext.mode, equals(mode));
      }
    });
  });

  // ===========================================================================
  // DebugExtension - cycle
  // ===========================================================================

  group('DebugExtension - cycle', () {
    test('cycles through all modes in order', () {
      final ext = DebugExtension(mode: DebugMode.none);

      // none -> all
      ext.cycle();
      expect(ext.mode, equals(DebugMode.all));

      // all -> spatialIndex
      ext.cycle();
      expect(ext.mode, equals(DebugMode.spatialIndex));

      // spatialIndex -> autoPanZone
      ext.cycle();
      expect(ext.mode, equals(DebugMode.autoPanZone));

      // autoPanZone -> none (wraps around)
      ext.cycle();
      expect(ext.mode, equals(DebugMode.none));
    });

    test('completes full cycle starting from any mode', () {
      for (final startMode in DebugMode.values) {
        final ext = DebugExtension(mode: startMode);

        // Cycle through all 4 modes to get back to start
        ext.cycle();
        ext.cycle();
        ext.cycle();
        ext.cycle();

        expect(
          ext.mode,
          equals(startMode),
          reason: 'Should return to $startMode after full cycle',
        );
      }
    });
  });

  // ===========================================================================
  // DebugExtension - Convenience Methods
  // ===========================================================================

  group('DebugExtension - Convenience Methods', () {
    test('showAll sets mode to all', () {
      final ext = DebugExtension(mode: DebugMode.none);

      ext.showAll();

      expect(ext.mode, equals(DebugMode.all));
    });

    test('hide sets mode to none', () {
      final ext = DebugExtension(mode: DebugMode.all);

      ext.hide();

      expect(ext.mode, equals(DebugMode.none));
    });
  });

  // ===========================================================================
  // DebugExtension - Reactive Getters
  // ===========================================================================

  group('DebugExtension - Reactive Getters', () {
    test('isEnabled reflects current mode', () {
      final ext = DebugExtension(mode: DebugMode.none);
      expect(ext.isEnabled, isFalse);

      ext.setMode(DebugMode.all);
      expect(ext.isEnabled, isTrue);

      ext.setMode(DebugMode.spatialIndex);
      expect(ext.isEnabled, isTrue);

      ext.hide();
      expect(ext.isEnabled, isFalse);
    });

    test('showSpatialIndex reflects current mode', () {
      final ext = DebugExtension(mode: DebugMode.none);
      expect(ext.showSpatialIndex, isFalse);

      ext.setMode(DebugMode.all);
      expect(ext.showSpatialIndex, isTrue);

      ext.setMode(DebugMode.spatialIndex);
      expect(ext.showSpatialIndex, isTrue);

      ext.setMode(DebugMode.autoPanZone);
      expect(ext.showSpatialIndex, isFalse);
    });

    test('showAutoPanZone reflects current mode', () {
      final ext = DebugExtension(mode: DebugMode.none);
      expect(ext.showAutoPanZone, isFalse);

      ext.setMode(DebugMode.all);
      expect(ext.showAutoPanZone, isTrue);

      ext.setMode(DebugMode.autoPanZone);
      expect(ext.showAutoPanZone, isTrue);

      ext.setMode(DebugMode.spatialIndex);
      expect(ext.showAutoPanZone, isFalse);
    });
  });

  // ===========================================================================
  // Integration - DebugExtension with Config
  // ===========================================================================

  group('DebugExtension - Integration with NodeFlowConfig', () {
    test('can be added to extensions list', () {
      final debugExt = DebugExtension(mode: DebugMode.all);
      final config = NodeFlowConfig(extensions: [debugExt]);

      final retrieved = config.extensionRegistry.get<DebugExtension>();
      expect(retrieved, isNotNull);
      expect(retrieved!.mode, equals(DebugMode.all));
    });

    test('is included in default extensions', () {
      final config = NodeFlowConfig();

      final debugExt = config.extensionRegistry.get<DebugExtension>();
      expect(debugExt, isNotNull);
      expect(debugExt!.mode, equals(DebugMode.none));
    });

    test('can override default extension', () {
      final customDebug = DebugExtension(mode: DebugMode.spatialIndex);
      final config = NodeFlowConfig(
        extensions: [
          customDebug,
          // Other default extensions would go here...
        ],
      );

      final retrieved = config.extensionRegistry.get<DebugExtension>();
      expect(retrieved, isNotNull);
      expect(retrieved!.mode, equals(DebugMode.spatialIndex));
    });
  });
}
