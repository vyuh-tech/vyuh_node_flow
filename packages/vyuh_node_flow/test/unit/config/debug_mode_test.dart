/// Unit tests for the DebugMode enum and NodeFlowConfig debug functionality.
///
/// Tests cover:
/// - DebugMode enum values and helper properties
/// - DebugMode helper methods (isEnabled, showSpatialIndex, showAutoPanZone)
/// - NodeFlowConfig debug mode operations (toggle, set, cycle)
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
  // NodeFlowConfig Debug Mode - Constructor
  // ===========================================================================

  group('NodeFlowConfig - DebugMode Constructor', () {
    test('defaults to DebugMode.none', () {
      final config = NodeFlowConfig();

      expect(config.debugMode.value, equals(DebugMode.none));
    });

    test('accepts debugMode parameter', () {
      final config = NodeFlowConfig(debugMode: DebugMode.all);

      expect(config.debugMode.value, equals(DebugMode.all));
    });

    test('accepts spatialIndex debug mode', () {
      final config = NodeFlowConfig(debugMode: DebugMode.spatialIndex);

      expect(config.debugMode.value, equals(DebugMode.spatialIndex));
    });

    test('accepts autoPanZone debug mode', () {
      final config = NodeFlowConfig(debugMode: DebugMode.autoPanZone);

      expect(config.debugMode.value, equals(DebugMode.autoPanZone));
    });
  });

  // ===========================================================================
  // NodeFlowConfig Debug Mode - toggleDebugMode
  // ===========================================================================

  group('NodeFlowConfig - toggleDebugMode', () {
    test('toggles from none to all', () {
      final config = NodeFlowConfig(debugMode: DebugMode.none);

      config.toggleDebugMode();

      expect(config.debugMode.value, equals(DebugMode.all));
    });

    test('toggles from all to none', () {
      final config = NodeFlowConfig(debugMode: DebugMode.all);

      config.toggleDebugMode();

      expect(config.debugMode.value, equals(DebugMode.none));
    });

    test('toggles from spatialIndex to none', () {
      final config = NodeFlowConfig(debugMode: DebugMode.spatialIndex);

      config.toggleDebugMode();

      expect(config.debugMode.value, equals(DebugMode.none));
    });

    test('toggles from autoPanZone to none', () {
      final config = NodeFlowConfig(debugMode: DebugMode.autoPanZone);

      config.toggleDebugMode();

      expect(config.debugMode.value, equals(DebugMode.none));
    });
  });

  // ===========================================================================
  // NodeFlowConfig Debug Mode - setDebugMode
  // ===========================================================================

  group('NodeFlowConfig - setDebugMode', () {
    test('sets specific debug mode', () {
      final config = NodeFlowConfig(debugMode: DebugMode.none);

      config.setDebugMode(DebugMode.spatialIndex);

      expect(config.debugMode.value, equals(DebugMode.spatialIndex));
    });

    test('can set to same mode', () {
      final config = NodeFlowConfig(debugMode: DebugMode.all);

      config.setDebugMode(DebugMode.all);

      expect(config.debugMode.value, equals(DebugMode.all));
    });

    test('can set each debug mode value', () {
      final config = NodeFlowConfig();

      for (final mode in DebugMode.values) {
        config.setDebugMode(mode);
        expect(config.debugMode.value, equals(mode));
      }
    });
  });

  // ===========================================================================
  // NodeFlowConfig Debug Mode - cycleDebugMode
  // ===========================================================================

  group('NodeFlowConfig - cycleDebugMode', () {
    test('cycles through all modes in order', () {
      final config = NodeFlowConfig(debugMode: DebugMode.none);

      // none -> all
      config.cycleDebugMode();
      expect(config.debugMode.value, equals(DebugMode.all));

      // all -> spatialIndex
      config.cycleDebugMode();
      expect(config.debugMode.value, equals(DebugMode.spatialIndex));

      // spatialIndex -> autoPanZone
      config.cycleDebugMode();
      expect(config.debugMode.value, equals(DebugMode.autoPanZone));

      // autoPanZone -> none (wraps around)
      config.cycleDebugMode();
      expect(config.debugMode.value, equals(DebugMode.none));
    });

    test('completes full cycle starting from any mode', () {
      for (final startMode in DebugMode.values) {
        final config = NodeFlowConfig(debugMode: startMode);

        // Cycle through all 4 modes to get back to start
        config.cycleDebugMode();
        config.cycleDebugMode();
        config.cycleDebugMode();
        config.cycleDebugMode();

        expect(
          config.debugMode.value,
          equals(startMode),
          reason: 'Should return to $startMode after full cycle',
        );
      }
    });
  });

  // ===========================================================================
  // NodeFlowConfig Debug Mode - update method
  // ===========================================================================

  group('NodeFlowConfig - update with debugMode', () {
    test('update can set debug mode', () {
      final config = NodeFlowConfig(debugMode: DebugMode.none);

      config.update(debugMode: DebugMode.all);

      expect(config.debugMode.value, equals(DebugMode.all));
    });

    test('update preserves debug mode when not specified', () {
      final config = NodeFlowConfig(debugMode: DebugMode.spatialIndex);

      config.update(snapToGrid: true);

      expect(config.debugMode.value, equals(DebugMode.spatialIndex));
    });
  });

  // ===========================================================================
  // NodeFlowConfig Debug Mode - copyWith
  // ===========================================================================

  group('NodeFlowConfig - copyWith debugMode', () {
    test('copyWith can change debug mode', () {
      final config = NodeFlowConfig(debugMode: DebugMode.none);

      final newConfig = config.copyWith(debugMode: DebugMode.autoPanZone);

      expect(newConfig.debugMode.value, equals(DebugMode.autoPanZone));
      expect(
        config.debugMode.value,
        equals(DebugMode.none),
      ); // Original unchanged
    });

    test('copyWith preserves debug mode when not specified', () {
      final config = NodeFlowConfig(debugMode: DebugMode.all);

      final newConfig = config.copyWith(snapToGrid: true);

      expect(newConfig.debugMode.value, equals(DebugMode.all));
    });
  });

  // ===========================================================================
  // Integration - Debug Mode with Config Helpers
  // ===========================================================================

  group('DebugMode - Integration with Config', () {
    test('helper properties work correctly after setDebugMode', () {
      final config = NodeFlowConfig(debugMode: DebugMode.none);

      expect(config.debugMode.value.isEnabled, isFalse);
      expect(config.debugMode.value.showSpatialIndex, isFalse);
      expect(config.debugMode.value.showAutoPanZone, isFalse);

      config.setDebugMode(DebugMode.spatialIndex);

      expect(config.debugMode.value.isEnabled, isTrue);
      expect(config.debugMode.value.showSpatialIndex, isTrue);
      expect(config.debugMode.value.showAutoPanZone, isFalse);
    });

    test('helper properties work correctly after cycleDebugMode', () {
      final config = NodeFlowConfig(debugMode: DebugMode.none);

      config.cycleDebugMode(); // -> all
      expect(config.debugMode.value.isEnabled, isTrue);
      expect(config.debugMode.value.showSpatialIndex, isTrue);
      expect(config.debugMode.value.showAutoPanZone, isTrue);

      config.cycleDebugMode(); // -> spatialIndex
      expect(config.debugMode.value.isEnabled, isTrue);
      expect(config.debugMode.value.showSpatialIndex, isTrue);
      expect(config.debugMode.value.showAutoPanZone, isFalse);
    });
  });
}
