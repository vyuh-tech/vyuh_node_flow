/// Unit tests for NodeFlowConfig reactive configuration class.
///
/// Tests cover:
/// - Default configuration values
/// - Custom configuration with constructor parameters
/// - Reactive property updates via update() method
/// - toggleSnapping() method
/// - snapToGridIfEnabled() helper method
/// - copyWith() method for creating modified copies
/// - defaultConfig factory
/// - defaultExtensions() static method
/// - Extension registry integration
/// - Edge cases and boundary conditions
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
    test('snapToGrid defaults to false', () {
      final config = NodeFlowConfig();

      expect(config.snapToGrid.value, isFalse);
    });

    test('gridSize defaults to 20.0', () {
      final config = NodeFlowConfig();

      expect(config.gridSize.value, equals(20.0));
    });

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
    });
  });

  // ===========================================================================
  // Custom Configuration
  // ===========================================================================

  group('NodeFlowConfig - Custom Configuration', () {
    test('accepts custom snapToGrid value', () {
      final config = NodeFlowConfig(snapToGrid: true);

      expect(config.snapToGrid.value, isTrue);
    });

    test('accepts custom gridSize value', () {
      final config = NodeFlowConfig(gridSize: 50.0);

      expect(config.gridSize.value, equals(50.0));
    });

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
        snapToGrid: true,
        gridSize: 32.0,
        portSnapDistance: 12.0,
        minZoom: 0.25,
        maxZoom: 4.0,
        scrollToZoom: false,
        showAttribution: false,
      );

      expect(config.snapToGrid.value, isTrue);
      expect(config.gridSize.value, equals(32.0));
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
    });
  });

  // ===========================================================================
  // toggleSnapping Method
  // ===========================================================================

  group('NodeFlowConfig - toggleSnapping', () {
    test('toggles from false to true', () {
      final config = NodeFlowConfig(snapToGrid: false);

      config.toggleSnapping();

      expect(config.snapToGrid.value, isTrue);
    });

    test('toggles from true to false', () {
      final config = NodeFlowConfig(snapToGrid: true);

      config.toggleSnapping();

      expect(config.snapToGrid.value, isFalse);
    });

    test('multiple toggles work correctly', () {
      final config = NodeFlowConfig(snapToGrid: false);

      config.toggleSnapping();
      expect(config.snapToGrid.value, isTrue);

      config.toggleSnapping();
      expect(config.snapToGrid.value, isFalse);

      config.toggleSnapping();
      expect(config.snapToGrid.value, isTrue);
    });
  });

  // ===========================================================================
  // update Method
  // ===========================================================================

  group('NodeFlowConfig - update', () {
    test('updates snapToGrid when provided', () {
      final config = NodeFlowConfig(snapToGrid: false);

      config.update(snapToGrid: true);

      expect(config.snapToGrid.value, isTrue);
    });

    test('updates gridSize when provided', () {
      final config = NodeFlowConfig(gridSize: 20.0);

      config.update(gridSize: 40.0);

      expect(config.gridSize.value, equals(40.0));
    });

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
        snapToGrid: true,
        gridSize: 64.0,
        portSnapDistance: 32.0,
        minZoom: 0.2,
        maxZoom: 8.0,
        scrollToZoom: false,
      );

      expect(config.snapToGrid.value, isTrue);
      expect(config.gridSize.value, equals(64.0));
      expect(config.portSnapDistance.value, equals(32.0));
      expect(config.minZoom.value, equals(0.2));
      expect(config.maxZoom.value, equals(8.0));
      expect(config.scrollToZoom.value, isFalse);
    });

    test('does not change properties when null is provided', () {
      final config = NodeFlowConfig(
        snapToGrid: true,
        gridSize: 30.0,
        portSnapDistance: 10.0,
        minZoom: 0.3,
        maxZoom: 3.0,
        scrollToZoom: false,
      );

      config.update();

      expect(config.snapToGrid.value, isTrue);
      expect(config.gridSize.value, equals(30.0));
      expect(config.portSnapDistance.value, equals(10.0));
      expect(config.minZoom.value, equals(0.3));
      expect(config.maxZoom.value, equals(3.0));
      expect(config.scrollToZoom.value, isFalse);
    });

    test('partially updates only specified properties', () {
      final config = NodeFlowConfig(
        snapToGrid: false,
        gridSize: 20.0,
        portSnapDistance: 8.0,
      );

      config.update(gridSize: 50.0);

      expect(config.snapToGrid.value, isFalse);
      expect(config.gridSize.value, equals(50.0));
      expect(config.portSnapDistance.value, equals(8.0));
    });
  });

  // ===========================================================================
  // snapToGridIfEnabled Method
  // ===========================================================================

  group('NodeFlowConfig - snapToGridIfEnabled', () {
    test('returns unchanged position when snapping is disabled', () {
      final config = NodeFlowConfig(snapToGrid: false, gridSize: 20.0);
      const position = Offset(15.0, 27.0);

      final result = config.snapToGridIfEnabled(position);

      expect(result, equals(position));
    });

    test('snaps to nearest grid intersection when enabled', () {
      final config = NodeFlowConfig(snapToGrid: true, gridSize: 20.0);
      const position = Offset(15.0, 27.0);

      final result = config.snapToGridIfEnabled(position);

      expect(result, equals(const Offset(20.0, 20.0)));
    });

    test('snaps position exactly on grid line correctly', () {
      final config = NodeFlowConfig(snapToGrid: true, gridSize: 20.0);
      const position = Offset(40.0, 60.0);

      final result = config.snapToGridIfEnabled(position);

      expect(result, equals(const Offset(40.0, 60.0)));
    });

    test('snaps position at midpoint to nearest', () {
      final config = NodeFlowConfig(snapToGrid: true, gridSize: 20.0);
      const position = Offset(10.0, 10.0);

      final result = config.snapToGridIfEnabled(position);

      // 10 / 20 = 0.5, rounded = 1, * 20 = 20
      expect(result, equals(const Offset(20.0, 20.0)));
    });

    test('snaps negative coordinates correctly', () {
      final config = NodeFlowConfig(snapToGrid: true, gridSize: 20.0);
      const position = Offset(-15.0, -27.0);

      final result = config.snapToGridIfEnabled(position);

      // -15 / 20 = -0.75, rounded = -1, * 20 = -20
      // -27 / 20 = -1.35, rounded = -1, * 20 = -20
      expect(result, equals(const Offset(-20.0, -20.0)));
    });

    test('respects custom grid size', () {
      final config = NodeFlowConfig(snapToGrid: true, gridSize: 50.0);
      const position = Offset(67.0, 118.0);

      final result = config.snapToGridIfEnabled(position);

      // 67 / 50 = 1.34, rounded = 1, * 50 = 50
      // 118 / 50 = 2.36, rounded = 2, * 50 = 100
      expect(result, equals(const Offset(50.0, 100.0)));
    });

    test('handles origin position', () {
      final config = NodeFlowConfig(snapToGrid: true, gridSize: 20.0);
      const position = Offset(0.0, 0.0);

      final result = config.snapToGridIfEnabled(position);

      expect(result, equals(const Offset(0.0, 0.0)));
    });

    test('handles very small grid size', () {
      final config = NodeFlowConfig(snapToGrid: true, gridSize: 1.0);
      const position = Offset(15.7, 27.3);

      final result = config.snapToGridIfEnabled(position);

      expect(result, equals(const Offset(16.0, 27.0)));
    });

    test('handles large coordinates', () {
      final config = NodeFlowConfig(snapToGrid: true, gridSize: 20.0);
      const position = Offset(10015.0, 20027.0);

      final result = config.snapToGridIfEnabled(position);

      expect(result, equals(const Offset(10020.0, 20020.0)));
    });
  });

  // ===========================================================================
  // copyWith Method
  // ===========================================================================

  group('NodeFlowConfig - copyWith', () {
    test('creates copy with same values when no arguments provided', () {
      final config = NodeFlowConfig(
        snapToGrid: true,
        gridSize: 30.0,
        portSnapDistance: 10.0,
        minZoom: 0.3,
        maxZoom: 3.0,
        scrollToZoom: false,
        showAttribution: false,
      );

      final copy = config.copyWith();

      expect(copy.snapToGrid.value, equals(config.snapToGrid.value));
      expect(copy.gridSize.value, equals(config.gridSize.value));
      expect(
        copy.portSnapDistance.value,
        equals(config.portSnapDistance.value),
      );
      expect(copy.minZoom.value, equals(config.minZoom.value));
      expect(copy.maxZoom.value, equals(config.maxZoom.value));
      expect(copy.scrollToZoom.value, equals(config.scrollToZoom.value));
      expect(copy.showAttribution, equals(config.showAttribution));
    });

    test('creates copy with new snapToGrid value', () {
      final config = NodeFlowConfig(snapToGrid: false);

      final copy = config.copyWith(snapToGrid: true);

      expect(copy.snapToGrid.value, isTrue);
      expect(config.snapToGrid.value, isFalse); // Original unchanged
    });

    test('creates copy with new gridSize value', () {
      final config = NodeFlowConfig(gridSize: 20.0);

      final copy = config.copyWith(gridSize: 100.0);

      expect(copy.gridSize.value, equals(100.0));
      expect(config.gridSize.value, equals(20.0)); // Original unchanged
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

      final copy = config.copyWith(
        snapToGrid: true,
        gridSize: 64.0,
        maxZoom: 10.0,
        showAttribution: false,
      );

      expect(copy.snapToGrid.value, isTrue);
      expect(copy.gridSize.value, equals(64.0));
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
      final config = NodeFlowConfig(gridSize: 20.0);
      final copy = config.copyWith();

      config.update(gridSize: 100.0);

      expect(copy.gridSize.value, equals(20.0)); // Copy unchanged
      expect(config.gridSize.value, equals(100.0));
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

      expect(config.snapToGrid.value, isFalse);
      expect(config.gridSize.value, equals(20.0));
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
    test('returns five extensions', () {
      final extensions = NodeFlowConfig.defaultExtensions();

      expect(extensions, hasLength(5));
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
    });

    test('all extensions are accessible', () {
      final config = NodeFlowConfig();

      final extensions = config.extensionRegistry.all.toList();

      expect(extensions, hasLength(5));
    });
  });

  // ===========================================================================
  // Observable Reactivity
  // ===========================================================================

  group('NodeFlowConfig - Observable Reactivity', () {
    test('snapToGrid is observable', () {
      final config = NodeFlowConfig(snapToGrid: false);
      var reactionCount = 0;

      final dispose = reaction(
        (_) => config.snapToGrid.value,
        (_) => reactionCount++,
      );

      config.update(snapToGrid: true);

      expect(reactionCount, equals(1));

      dispose();
    });

    test('gridSize is observable', () {
      final config = NodeFlowConfig(gridSize: 20.0);
      var reactionCount = 0;

      final dispose = reaction(
        (_) => config.gridSize.value,
        (_) => reactionCount++,
      );

      config.update(gridSize: 40.0);

      expect(reactionCount, equals(1));

      dispose();
    });

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

    test('toggleSnapping triggers reaction', () {
      final config = NodeFlowConfig(snapToGrid: false);
      var reactionCount = 0;

      final dispose = reaction(
        (_) => config.snapToGrid.value,
        (_) => reactionCount++,
      );

      config.toggleSnapping();

      expect(reactionCount, equals(1));

      dispose();
    });
  });

  // ===========================================================================
  // Edge Cases and Boundary Conditions
  // ===========================================================================

  group('NodeFlowConfig - Edge Cases', () {
    test('handles zero gridSize', () {
      final config = NodeFlowConfig(gridSize: 0.0);

      expect(config.gridSize.value, equals(0.0));
    });

    test('handles negative gridSize', () {
      final config = NodeFlowConfig(gridSize: -10.0);

      expect(config.gridSize.value, equals(-10.0));
    });

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

    test('snapToGridIfEnabled throws with zero grid size', () {
      final config = NodeFlowConfig(snapToGrid: true, gridSize: 0.0);

      // Division by zero in rounding operation causes UnsupportedError
      expect(
        () => config.snapToGridIfEnabled(const Offset(10.0, 20.0)),
        throwsUnsupportedError,
      );
    });

    test('update with same values does not break observables', () {
      final config = NodeFlowConfig(snapToGrid: true, gridSize: 20.0);

      expect(
        () => config.update(snapToGrid: true, gridSize: 20.0),
        returnsNormally,
      );

      expect(config.snapToGrid.value, isTrue);
      expect(config.gridSize.value, equals(20.0));
    });

    test('multiple rapid updates work correctly', () {
      final config = NodeFlowConfig();

      for (var i = 0; i < 100; i++) {
        config.update(gridSize: i.toDouble());
      }

      expect(config.gridSize.value, equals(99.0));
    });

    test('multiple rapid toggles work correctly', () {
      final config = NodeFlowConfig(snapToGrid: false);

      for (var i = 0; i < 100; i++) {
        config.toggleSnapping();
      }

      // 100 toggles from false should end at false (even number)
      expect(config.snapToGrid.value, isFalse);
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
      config.update(snapToGrid: true);

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
