/// Unit tests for NodeFlowConfig reactive configuration class.
///
/// Tests cover:
/// - Default configuration values
/// - Custom configuration with constructor parameters
/// - Reactive property updates via update() method
/// - copyWith() method for creating modified copies
/// - defaultConfig factory
/// - defaultExtensions() static method
/// - Extension registry integration
/// - Edge cases and boundary conditions
///
/// Note: Grid snapping functionality (snapToGrid, gridSize, toggleSnapping,
/// snapToGridIfEnabled) has been moved to SnapExtension with GridSnapDelegate.
/// See snap_delegate_test.dart for grid snapping tests.
@Tags(['unit'])
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:mobx/mobx.dart';
import 'package:vyuh_node_flow/vyuh_node_flow.dart';

void main() {
  // ===========================================================================
  // Default Configuration Values
  // ===========================================================================

  group('NodeFlowConfig - Default Values', () {
    test('portSnapDistance defaults to 8.0', () {
      final config = NodeFlowConfig();

      expect(config.portSnapDistance.value, equals(8.0));
    });

    test('minZoom defaults to 0.5', () {
      final config = NodeFlowConfig();

      expect(config.minZoom.value, equals(0.5));
    });

    test('maxZoom defaults to 2.0', () {
      final config = NodeFlowConfig();

      expect(config.maxZoom.value, equals(2.0));
    });

    test('scrollToZoom defaults to true', () {
      final config = NodeFlowConfig();

      expect(config.scrollToZoom.value, isTrue);
    });

    test('showAttribution defaults to true', () {
      final config = NodeFlowConfig();

      expect(config.showAttribution, isTrue);
    });

    test('extensionRegistry is populated with default extensions', () {
      final config = NodeFlowConfig();

      expect(config.extensionRegistry.get<AutoPanExtension>(), isNotNull);
      expect(config.extensionRegistry.get<DebugExtension>(), isNotNull);
      expect(config.extensionRegistry.get<LodExtension>(), isNotNull);
      expect(config.extensionRegistry.get<MinimapExtension>(), isNotNull);
      expect(config.extensionRegistry.get<StatsExtension>(), isNotNull);
      expect(config.extensionRegistry.get<SnapExtension>(), isNotNull);
    });

    test('default SnapExtension contains GridSnapDelegate', () {
      final config = NodeFlowConfig();
      final snapExt = config.extensionRegistry.get<SnapExtension>();

      expect(snapExt, isNotNull);
      expect(snapExt!.gridSnapDelegate, isNotNull);
      expect(snapExt.gridSnapDelegate!.enabled, isFalse); // Disabled by default
      expect(snapExt.gridSnapDelegate!.gridSize, equals(20.0));
    });
  });

  // ===========================================================================
  // Custom Configuration
  // ===========================================================================

  group('NodeFlowConfig - Custom Configuration', () {
    test('accepts custom portSnapDistance value', () {
      final config = NodeFlowConfig(portSnapDistance: 16.0);

      expect(config.portSnapDistance.value, equals(16.0));
    });

    test('accepts custom minZoom value', () {
      final config = NodeFlowConfig(minZoom: 0.1);

      expect(config.minZoom.value, equals(0.1));
    });

    test('accepts custom maxZoom value', () {
      final config = NodeFlowConfig(maxZoom: 5.0);

      expect(config.maxZoom.value, equals(5.0));
    });

    test('accepts custom scrollToZoom value', () {
      final config = NodeFlowConfig(scrollToZoom: false);

      expect(config.scrollToZoom.value, isFalse);
    });

    test('accepts custom showAttribution value', () {
      final config = NodeFlowConfig(showAttribution: false);

      expect(config.showAttribution, isFalse);
    });

    test('accepts all custom values simultaneously', () {
      final config = NodeFlowConfig(
        portSnapDistance: 12.0,
        minZoom: 0.25,
        maxZoom: 4.0,
        scrollToZoom: false,
        showAttribution: false,
      );

      expect(config.portSnapDistance.value, equals(12.0));
      expect(config.minZoom.value, equals(0.25));
      expect(config.maxZoom.value, equals(4.0));
      expect(config.scrollToZoom.value, isFalse);
      expect(config.showAttribution, isFalse);
    });

    test('accepts custom extensions list', () {
      final customDebug = DebugExtension(mode: DebugMode.all);
      final config = NodeFlowConfig(extensions: [customDebug]);

      expect(config.extensionRegistry.get<DebugExtension>(), isNotNull);
      expect(
        config.extensionRegistry.get<DebugExtension>()!.mode,
        equals(DebugMode.all),
      );
      // Only the provided extension should be in the registry
      expect(config.extensionRegistry.get<MinimapExtension>(), isNull);
    });

    test('accepts empty extensions list', () {
      final config = NodeFlowConfig(extensions: []);

      expect(config.extensionRegistry.get<AutoPanExtension>(), isNull);
      expect(config.extensionRegistry.get<DebugExtension>(), isNull);
      expect(config.extensionRegistry.get<LodExtension>(), isNull);
      expect(config.extensionRegistry.get<MinimapExtension>(), isNull);
      expect(config.extensionRegistry.get<StatsExtension>(), isNull);
      expect(config.extensionRegistry.get<SnapExtension>(), isNull);
    });

    test('accepts custom SnapExtension with configured GridSnapDelegate', () {
      final config = NodeFlowConfig(
        extensions: [
          SnapExtension([GridSnapDelegate(gridSize: 50.0, enabled: true)]),
        ],
      );

      final snapExt = config.extensionRegistry.get<SnapExtension>();
      expect(snapExt, isNotNull);
      expect(snapExt!.gridSnapDelegate!.gridSize, equals(50.0));
      expect(snapExt.gridSnapDelegate!.enabled, isTrue);
    });
  });

  // ===========================================================================
  // update Method
  // ===========================================================================

  group('NodeFlowConfig - update', () {
    test('updates portSnapDistance when provided', () {
      final config = NodeFlowConfig(portSnapDistance: 8.0);

      config.update(portSnapDistance: 20.0);

      expect(config.portSnapDistance.value, equals(20.0));
    });

    test('updates minZoom when provided', () {
      final config = NodeFlowConfig(minZoom: 0.5);

      config.update(minZoom: 0.1);

      expect(config.minZoom.value, equals(0.1));
    });

    test('updates maxZoom when provided', () {
      final config = NodeFlowConfig(maxZoom: 2.0);

      config.update(maxZoom: 10.0);

      expect(config.maxZoom.value, equals(10.0));
    });

    test('updates scrollToZoom when provided', () {
      final config = NodeFlowConfig(scrollToZoom: true);

      config.update(scrollToZoom: false);

      expect(config.scrollToZoom.value, isFalse);
    });

    test('updates multiple properties at once', () {
      final config = NodeFlowConfig();

      config.update(
        portSnapDistance: 32.0,
        minZoom: 0.2,
        maxZoom: 8.0,
        scrollToZoom: false,
      );

      expect(config.portSnapDistance.value, equals(32.0));
      expect(config.minZoom.value, equals(0.2));
      expect(config.maxZoom.value, equals(8.0));
      expect(config.scrollToZoom.value, isFalse);
    });

    test('does not change properties when null is provided', () {
      final config = NodeFlowConfig(
        portSnapDistance: 10.0,
        minZoom: 0.3,
        maxZoom: 3.0,
        scrollToZoom: false,
      );

      config.update();

      expect(config.portSnapDistance.value, equals(10.0));
      expect(config.minZoom.value, equals(0.3));
      expect(config.maxZoom.value, equals(3.0));
      expect(config.scrollToZoom.value, isFalse);
    });

    test('partially updates only specified properties', () {
      final config = NodeFlowConfig(portSnapDistance: 8.0, minZoom: 0.5);

      config.update(minZoom: 0.1);

      expect(config.portSnapDistance.value, equals(8.0)); // Unchanged
      expect(config.minZoom.value, equals(0.1));
    });
  });

  // ===========================================================================
  // copyWith Method
  // ===========================================================================

  group('NodeFlowConfig - copyWith', () {
    test('creates copy with same values when no arguments provided', () {
      final config = NodeFlowConfig(
        portSnapDistance: 10.0,
        minZoom: 0.3,
        maxZoom: 3.0,
        scrollToZoom: false,
        showAttribution: false,
      );

      final copy = config.copyWith();

      expect(
        copy.portSnapDistance.value,
        equals(config.portSnapDistance.value),
      );
      expect(copy.minZoom.value, equals(config.minZoom.value));
      expect(copy.maxZoom.value, equals(config.maxZoom.value));
      expect(copy.scrollToZoom.value, equals(config.scrollToZoom.value));
      expect(copy.showAttribution, equals(config.showAttribution));
    });

    test('creates copy with new portSnapDistance value', () {
      final config = NodeFlowConfig(portSnapDistance: 8.0);

      final copy = config.copyWith(portSnapDistance: 24.0);

      expect(copy.portSnapDistance.value, equals(24.0));
      expect(config.portSnapDistance.value, equals(8.0)); // Original unchanged
    });

    test('creates copy with new minZoom value', () {
      final config = NodeFlowConfig(minZoom: 0.5);

      final copy = config.copyWith(minZoom: 0.01);

      expect(copy.minZoom.value, equals(0.01));
      expect(config.minZoom.value, equals(0.5)); // Original unchanged
    });

    test('creates copy with new maxZoom value', () {
      final config = NodeFlowConfig(maxZoom: 2.0);

      final copy = config.copyWith(maxZoom: 20.0);

      expect(copy.maxZoom.value, equals(20.0));
      expect(config.maxZoom.value, equals(2.0)); // Original unchanged
    });

    test('creates copy with new scrollToZoom value', () {
      final config = NodeFlowConfig(scrollToZoom: true);

      final copy = config.copyWith(scrollToZoom: false);

      expect(copy.scrollToZoom.value, isFalse);
      expect(config.scrollToZoom.value, isTrue); // Original unchanged
    });

    test('creates copy with new showAttribution value', () {
      final config = NodeFlowConfig(showAttribution: true);

      final copy = config.copyWith(showAttribution: false);

      expect(copy.showAttribution, isFalse);
      expect(config.showAttribution, isTrue); // Original unchanged
    });

    test('creates copy with multiple new values', () {
      final config = NodeFlowConfig();

      final copy = config.copyWith(maxZoom: 10.0, showAttribution: false);

      expect(
        copy.portSnapDistance.value,
        equals(8.0),
      ); // Unchanged from default
      expect(copy.minZoom.value, equals(0.5)); // Unchanged from default
      expect(copy.maxZoom.value, equals(10.0));
      expect(copy.scrollToZoom.value, isTrue); // Unchanged from default
      expect(copy.showAttribution, isFalse);
    });

    test('copy is independent from original', () {
      final config = NodeFlowConfig(portSnapDistance: 20.0);
      final copy = config.copyWith();

      config.update(portSnapDistance: 100.0);

      expect(copy.portSnapDistance.value, equals(20.0)); // Copy unchanged
      expect(config.portSnapDistance.value, equals(100.0));
    });

    test('copy creates new extension registry with default extensions', () {
      final config = NodeFlowConfig();
      final copy = config.copyWith();

      // copyWith creates a new NodeFlowConfig which gets default extensions
      // since extensions parameter is not passed through copyWith
      expect(copy.extensionRegistry.get<AutoPanExtension>(), isNotNull);
      expect(copy.extensionRegistry.get<DebugExtension>(), isNotNull);
      expect(copy.extensionRegistry.get<LodExtension>(), isNotNull);
      expect(copy.extensionRegistry.get<MinimapExtension>(), isNotNull);
      expect(copy.extensionRegistry.get<StatsExtension>(), isNotNull);
      expect(copy.extensionRegistry.get<SnapExtension>(), isNotNull);
    });

    test('copy does not preserve custom extensions', () {
      // Note: copyWith does not preserve extensions - it creates fresh defaults
      final customDebug = DebugExtension(mode: DebugMode.all);
      final config = NodeFlowConfig(extensions: [customDebug]);

      final copy = config.copyWith();

      // The copy gets default extensions, not the custom ones
      final debugExt = copy.extensionRegistry.get<DebugExtension>();
      expect(debugExt, isNotNull);
      expect(debugExt!.mode, equals(DebugMode.none)); // Default, not custom
    });
  });

  // ===========================================================================
  // defaultConfig Factory
  // ===========================================================================

  group('NodeFlowConfig - defaultConfig', () {
    test('returns a new NodeFlowConfig instance', () {
      final config = NodeFlowConfig.defaultConfig;

      expect(config, isA<NodeFlowConfig>());
    });

    test('has all default values', () {
      final config = NodeFlowConfig.defaultConfig;

      expect(config.portSnapDistance.value, equals(8.0));
      expect(config.minZoom.value, equals(0.5));
      expect(config.maxZoom.value, equals(2.0));
      expect(config.scrollToZoom.value, isTrue);
      expect(config.showAttribution, isTrue);
    });

    test('has default extensions', () {
      final config = NodeFlowConfig.defaultConfig;

      expect(config.extensionRegistry.get<AutoPanExtension>(), isNotNull);
      expect(config.extensionRegistry.get<DebugExtension>(), isNotNull);
      expect(config.extensionRegistry.get<LodExtension>(), isNotNull);
      expect(config.extensionRegistry.get<MinimapExtension>(), isNotNull);
      expect(config.extensionRegistry.get<StatsExtension>(), isNotNull);
      expect(config.extensionRegistry.get<SnapExtension>(), isNotNull);
    });

    test('returns different instance each call', () {
      final config1 = NodeFlowConfig.defaultConfig;
      final config2 = NodeFlowConfig.defaultConfig;

      expect(identical(config1, config2), isFalse);
    });
  });

  // ===========================================================================
  // defaultExtensions Static Method
  // ===========================================================================

  group('NodeFlowConfig - defaultExtensions', () {
    test('returns six extensions', () {
      final extensions = NodeFlowConfig.defaultExtensions();

      expect(extensions, hasLength(6));
    });

    test('contains AutoPanExtension', () {
      final extensions = NodeFlowConfig.defaultExtensions();

      expect(extensions.whereType<AutoPanExtension>(), hasLength(1));
    });

    test('contains DebugExtension', () {
      final extensions = NodeFlowConfig.defaultExtensions();

      expect(extensions.whereType<DebugExtension>(), hasLength(1));
    });

    test('contains LodExtension', () {
      final extensions = NodeFlowConfig.defaultExtensions();

      expect(extensions.whereType<LodExtension>(), hasLength(1));
    });

    test('contains MinimapExtension', () {
      final extensions = NodeFlowConfig.defaultExtensions();

      expect(extensions.whereType<MinimapExtension>(), hasLength(1));
    });

    test('contains StatsExtension', () {
      final extensions = NodeFlowConfig.defaultExtensions();

      expect(extensions.whereType<StatsExtension>(), hasLength(1));
    });

    test('contains SnapExtension', () {
      final extensions = NodeFlowConfig.defaultExtensions();

      expect(extensions.whereType<SnapExtension>(), hasLength(1));
    });

    test('returns new list each call', () {
      final extensions1 = NodeFlowConfig.defaultExtensions();
      final extensions2 = NodeFlowConfig.defaultExtensions();

      expect(identical(extensions1, extensions2), isFalse);
    });

    test('DebugExtension defaults to DebugMode.none', () {
      final extensions = NodeFlowConfig.defaultExtensions();
      final debugExt = extensions.whereType<DebugExtension>().first;

      expect(debugExt.mode, equals(DebugMode.none));
    });

    test('MinimapExtension defaults to not visible', () {
      final extensions = NodeFlowConfig.defaultExtensions();
      final minimapExt = extensions.whereType<MinimapExtension>().first;

      expect(minimapExt.isVisible, isFalse);
    });

    test('SnapExtension contains GridSnapDelegate disabled by default', () {
      final extensions = NodeFlowConfig.defaultExtensions();
      final snapExt = extensions
          .whereType<SnapExtension>()
          .first;

      expect(snapExt.gridSnapDelegate, isNotNull);
      expect(snapExt.gridSnapDelegate!.enabled, isFalse);
      expect(snapExt.gridSnapDelegate!.gridSize, equals(20.0));
    });
  });

  // ===========================================================================
  // Extension Registry Integration
  // ===========================================================================

  group('NodeFlowConfig - Extension Registry', () {
    test('extensionRegistry is accessible', () {
      final config = NodeFlowConfig();

      expect(config.extensionRegistry, isNotNull);
      expect(config.extensionRegistry, isA<ExtensionRegistry>());
    });

    test('can retrieve extensions by type', () {
      final config = NodeFlowConfig();

      final minimap = config.extensionRegistry.get<MinimapExtension>();
      final debug = config.extensionRegistry.get<DebugExtension>();

      expect(minimap, isNotNull);
      expect(debug, isNotNull);
    });

    test('can register additional extensions', () {
      final config = NodeFlowConfig();
      final customExt = DebugExtension(mode: DebugMode.spatialIndex);

      config.extensionRegistry.register(customExt);

      final retrieved = config.extensionRegistry.get<DebugExtension>();
      expect(retrieved!.mode, equals(DebugMode.spatialIndex));
    });

    test('custom extensions override same-id extensions', () {
      final customDebug = DebugExtension(mode: DebugMode.all);
      final config = NodeFlowConfig(
        extensions: [customDebug, MinimapExtension()],
      );

      final debugExt = config.extensionRegistry.get<DebugExtension>();
      expect(debugExt!.mode, equals(DebugMode.all));
    });

    test('extension IDs are accessible', () {
      final config = NodeFlowConfig();

      final ids = config.extensionRegistry.ids.toList();

      expect(ids, contains('auto-pan'));
      expect(ids, contains('debug'));
      expect(ids, contains('lod'));
      expect(ids, contains('minimap'));
      expect(ids, contains('stats'));
      expect(ids, contains('snap'));
    });

    test('all extensions are accessible', () {
      final config = NodeFlowConfig();

      final extensions = config.extensionRegistry.all.toList();

      expect(extensions, hasLength(6));
    });
  });

  // ===========================================================================
  // Observable Reactivity
  // ===========================================================================

  group('NodeFlowConfig - Observable Reactivity', () {
    test('portSnapDistance is observable', () {
      final config = NodeFlowConfig(portSnapDistance: 8.0);
      var reactionCount = 0;

      final dispose = reaction(
        (_) => config.portSnapDistance.value,
        (_) => reactionCount++,
      );

      config.update(portSnapDistance: 16.0);

      expect(reactionCount, equals(1));

      dispose();
    });

    test('minZoom is observable', () {
      final config = NodeFlowConfig(minZoom: 0.5);
      var reactionCount = 0;

      final dispose = reaction(
        (_) => config.minZoom.value,
        (_) => reactionCount++,
      );

      config.update(minZoom: 0.1);

      expect(reactionCount, equals(1));

      dispose();
    });

    test('maxZoom is observable', () {
      final config = NodeFlowConfig(maxZoom: 2.0);
      var reactionCount = 0;

      final dispose = reaction(
        (_) => config.maxZoom.value,
        (_) => reactionCount++,
      );

      config.update(maxZoom: 5.0);

      expect(reactionCount, equals(1));

      dispose();
    });

    test('scrollToZoom is observable', () {
      final config = NodeFlowConfig(scrollToZoom: true);
      var reactionCount = 0;

      final dispose = reaction(
        (_) => config.scrollToZoom.value,
        (_) => reactionCount++,
      );

      config.update(scrollToZoom: false);

      expect(reactionCount, equals(1));

      dispose();
    });
  });

  // ===========================================================================
  // Edge Cases and Boundary Conditions
  // ===========================================================================

  group('NodeFlowConfig - Edge Cases', () {
    test('handles very small minZoom', () {
      final config = NodeFlowConfig(minZoom: 0.001);

      expect(config.minZoom.value, equals(0.001));
    });

    test('handles very large maxZoom', () {
      final config = NodeFlowConfig(maxZoom: 1000.0);

      expect(config.maxZoom.value, equals(1000.0));
    });

    test('handles minZoom greater than maxZoom', () {
      // Config allows this - validation is responsibility of consumer
      final config = NodeFlowConfig(minZoom: 5.0, maxZoom: 1.0);

      expect(config.minZoom.value, equals(5.0));
      expect(config.maxZoom.value, equals(1.0));
    });

    test('handles zero portSnapDistance', () {
      final config = NodeFlowConfig(portSnapDistance: 0.0);

      expect(config.portSnapDistance.value, equals(0.0));
    });

    test('handles negative minZoom', () {
      final config = NodeFlowConfig(minZoom: -1.0);

      expect(config.minZoom.value, equals(-1.0));
    });

    test('update with same values does not break observables', () {
      final config = NodeFlowConfig(portSnapDistance: 20.0);

      expect(() => config.update(portSnapDistance: 20.0), returnsNormally);

      expect(config.portSnapDistance.value, equals(20.0));
    });

    test('multiple rapid updates work correctly', () {
      final config = NodeFlowConfig();

      for (var i = 0; i < 100; i++) {
        config.update(portSnapDistance: i.toDouble());
      }

      expect(config.portSnapDistance.value, equals(99.0));
    });
  });

  // ===========================================================================
  // Immutability of showAttribution
  // ===========================================================================

  group('NodeFlowConfig - showAttribution Immutability', () {
    test('showAttribution is final and cannot be changed', () {
      final config = NodeFlowConfig(showAttribution: true);

      // showAttribution is final, not observable
      // Verify it stays constant
      expect(config.showAttribution, isTrue);

      // Even after updates to other properties
      config.update(minZoom: 0.1);

      expect(config.showAttribution, isTrue);
    });

    test('only way to change showAttribution is through copyWith', () {
      final config = NodeFlowConfig(showAttribution: true);

      final copy = config.copyWith(showAttribution: false);

      expect(config.showAttribution, isTrue);
      expect(copy.showAttribution, isFalse);
    });
  });
}
