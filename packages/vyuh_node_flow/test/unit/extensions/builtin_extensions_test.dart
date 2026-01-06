/// Unit tests for built-in extensions in the vyuh_node_flow package.
///
/// Tests cover:
/// - NodeFlowExtension base class interface and lifecycle
/// - ExtensionRegistry for managing extensions
/// - AutoPanExtension configuration and state
/// - DebugExtension modes and visual overlay properties
/// - LodExtension (Level of Detail) thresholds and visibility
/// - MinimapExtension state and highlighting
/// - StatsExtension statistics tracking
@Tags(['unit'])
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vyuh_node_flow/vyuh_node_flow.dart';

import '../../helpers/test_factories.dart';

void main() {
  setUp(() {
    resetTestCounters();
  });

  // ===========================================================================
  // NodeFlowExtension - Interface and Lifecycle
  // ===========================================================================

  group('NodeFlowExtension - Interface', () {
    test('extension has required id property', () {
      final ext = AutoPanExtension();
      expect(ext.id, isA<String>());
      expect(ext.id, isNotEmpty);
    });

    test('different extensions have different ids', () {
      final autoPan = AutoPanExtension();
      final debug = DebugExtension();
      final lod = LodExtension();
      final minimap = MinimapExtension();
      final stats = StatsExtension();

      final ids = {autoPan.id, debug.id, lod.id, minimap.id, stats.id};
      expect(ids, hasLength(5), reason: 'All extension ids should be unique');
    });

    test('extension ids follow naming convention', () {
      expect(AutoPanExtension().id, equals('auto-pan'));
      expect(DebugExtension().id, equals('debug'));
      expect(LodExtension().id, equals('lod'));
      expect(MinimapExtension().id, equals('minimap'));
      expect(StatsExtension().id, equals('stats'));
    });
  });

  group('NodeFlowExtension - Lifecycle', () {
    test('extensions are lazily attached when accessed', () {
      final controller = NodeFlowController<String, dynamic>();

      // Extensions are lazily attached when accessed via resolveExtension
      // Before access, hasExtension returns false
      expect(controller.hasExtension('auto-pan'), isFalse);

      // Access the extension via getter (triggers lazy attachment)
      final autoPan = controller.autoPan;
      expect(autoPan, isNotNull);

      // Now hasExtension returns true
      expect(controller.hasExtension('auto-pan'), isTrue);

      controller.dispose();
    });

    test('extension can be added after controller creation', () {
      final controller = NodeFlowController<String, dynamic>(
        config: NodeFlowConfig(extensions: []),
      );

      expect(controller.hasExtension('minimap'), isFalse);

      controller.addExtension(MinimapExtension(visible: true));

      expect(controller.hasExtension('minimap'), isTrue);
      expect(controller.minimap, isNotNull);

      controller.dispose();
    });

    test('extension can be removed from controller', () {
      final controller = NodeFlowController<String, dynamic>();

      // First access the extension to attach it
      final autoPan = controller.autoPan;
      expect(autoPan, isNotNull);
      expect(controller.hasExtension('auto-pan'), isTrue);

      controller.removeExtension('auto-pan');

      expect(controller.hasExtension('auto-pan'), isFalse);

      controller.dispose();
    });
  });

  // ===========================================================================
  // ExtensionRegistry - Management
  // ===========================================================================

  group('ExtensionRegistry - Adding Extensions', () {
    test('creates empty registry', () {
      final registry = ExtensionRegistry();

      expect(registry.all, isEmpty);
      expect(registry.ids, isEmpty);
    });

    test('creates registry with initial extensions', () {
      final extensions = [AutoPanExtension(), DebugExtension()];
      final registry = ExtensionRegistry(extensions);

      expect(registry.all, hasLength(2));
      expect(registry.ids, containsAll(['auto-pan', 'debug']));
    });

    test('register adds extension to registry', () {
      final registry = ExtensionRegistry();

      registry.register(AutoPanExtension());

      expect(registry.has('auto-pan'), isTrue);
    });

    test('register replaces existing extension with same id', () {
      final registry = ExtensionRegistry();
      final original = AutoPanExtension(panAmount: 10.0);
      final replacement = AutoPanExtension(panAmount: 20.0);

      registry.register(original);
      registry.register(replacement);

      final retrieved = registry.get<AutoPanExtension>();
      expect(retrieved?.panAmount, equals(20.0));
    });
  });

  group('ExtensionRegistry - Removing Extensions', () {
    test('remove deletes extension by id', () {
      final registry = ExtensionRegistry([
        AutoPanExtension(),
        DebugExtension(),
      ]);

      registry.remove('auto-pan');

      expect(registry.has('auto-pan'), isFalse);
      expect(registry.has('debug'), isTrue);
    });

    test('remove non-existent extension does nothing', () {
      final registry = ExtensionRegistry([AutoPanExtension()]);

      registry.remove('non-existent');

      expect(registry.all, hasLength(1));
    });

    test('clear removes all extensions', () {
      final registry = ExtensionRegistry([
        AutoPanExtension(),
        DebugExtension(),
        LodExtension(),
      ]);

      registry.clear();

      expect(registry.all, isEmpty);
      expect(registry.ids, isEmpty);
    });
  });

  group('ExtensionRegistry - Getting Extensions', () {
    test('get returns extension by type', () {
      final registry = ExtensionRegistry([
        AutoPanExtension(),
        DebugExtension(),
      ]);

      final autoPan = registry.get<AutoPanExtension>();
      final debug = registry.get<DebugExtension>();

      expect(autoPan, isA<AutoPanExtension>());
      expect(debug, isA<DebugExtension>());
    });

    test('get returns null for unregistered type', () {
      final registry = ExtensionRegistry([AutoPanExtension()]);

      final result = registry.get<MinimapExtension>();

      expect(result, isNull);
    });

    test('getById returns extension by id', () {
      final registry = ExtensionRegistry([AutoPanExtension()]);

      final result = registry.getById('auto-pan');

      expect(result, isA<AutoPanExtension>());
    });

    test('getById returns null for unknown id', () {
      final registry = ExtensionRegistry([AutoPanExtension()]);

      final result = registry.getById('unknown');

      expect(result, isNull);
    });
  });

  group('ExtensionRegistry - Has Extension Check', () {
    test('has returns true for registered extension', () {
      final registry = ExtensionRegistry([AutoPanExtension()]);

      expect(registry.has('auto-pan'), isTrue);
    });

    test('has returns false for unregistered extension', () {
      final registry = ExtensionRegistry([AutoPanExtension()]);

      expect(registry.has('minimap'), isFalse);
    });

    test('ids returns all registered extension ids', () {
      final registry = ExtensionRegistry([
        AutoPanExtension(),
        DebugExtension(),
        LodExtension(),
      ]);

      expect(registry.ids, containsAll(['auto-pan', 'debug', 'lod']));
    });

    test('all returns all registered extensions', () {
      final extensions = [AutoPanExtension(), DebugExtension()];
      final registry = ExtensionRegistry(extensions);

      expect(registry.all, hasLength(2));
      expect(registry.all.whereType<AutoPanExtension>(), hasLength(1));
      expect(registry.all.whereType<DebugExtension>(), hasLength(1));
    });
  });

  // ===========================================================================
  // AutoPanExtension - Configuration
  // ===========================================================================

  group('AutoPanExtension - Construction', () {
    test('creates with default values', () {
      final ext = AutoPanExtension();

      expect(ext.isEnabled, isTrue);
      expect(ext.edgePadding, equals(const EdgeInsets.all(50.0)));
      expect(ext.panAmount, equals(10.0));
      expect(ext.panInterval, equals(const Duration(milliseconds: 16)));
      expect(ext.useProximityScaling, isFalse);
      expect(ext.speedCurve, isNull);
    });

    test('creates with custom edge padding', () {
      final ext = AutoPanExtension(
        edgePadding: const EdgeInsets.only(left: 30, right: 40),
      );

      expect(ext.edgePadding.left, equals(30.0));
      expect(ext.edgePadding.right, equals(40.0));
    });

    test('creates with disabled state', () {
      final ext = AutoPanExtension(enabled: false);

      expect(ext.isEnabled, isFalse);
    });
  });

  group('AutoPanExtension - Configuration Properties', () {
    test('setEdgePadding updates padding', () {
      final ext = AutoPanExtension();

      ext.setEdgePadding(const EdgeInsets.all(100.0));

      expect(ext.edgePadding, equals(const EdgeInsets.all(100.0)));
    });

    test('setPanAmount updates pan amount', () {
      final ext = AutoPanExtension();

      ext.setPanAmount(25.0);

      expect(ext.panAmount, equals(25.0));
    });

    test('setPanInterval updates interval', () {
      final ext = AutoPanExtension();

      ext.setPanInterval(const Duration(milliseconds: 32));

      expect(ext.panInterval, equals(const Duration(milliseconds: 32)));
    });

    test('setUseProximityScaling updates scaling flag', () {
      final ext = AutoPanExtension();

      ext.setUseProximityScaling(true);

      expect(ext.useProximityScaling, isTrue);
    });

    test('setSpeedCurve updates curve', () {
      final ext = AutoPanExtension();

      ext.setSpeedCurve(Curves.easeOut);

      expect(ext.speedCurve, equals(Curves.easeOut));
    });
  });

  group('AutoPanExtension - Presets', () {
    test('useNormal applies balanced settings', () {
      final ext = AutoPanExtension(panAmount: 100.0);

      ext.useNormal();

      expect(ext.edgePadding, equals(const EdgeInsets.all(50.0)));
      expect(ext.panAmount, equals(10.0));
      expect(ext.panInterval, equals(const Duration(milliseconds: 16)));
    });

    test('useFast applies faster settings', () {
      final ext = AutoPanExtension();

      ext.useFast();

      expect(ext.edgePadding, equals(const EdgeInsets.all(60.0)));
      expect(ext.panAmount, equals(20.0));
      expect(ext.panInterval, equals(const Duration(milliseconds: 12)));
    });

    test('usePrecise applies precise settings', () {
      final ext = AutoPanExtension();

      ext.usePrecise();

      expect(ext.edgePadding, equals(const EdgeInsets.all(30.0)));
      expect(ext.panAmount, equals(5.0));
      expect(ext.panInterval, equals(const Duration(milliseconds: 20)));
    });
  });

  group('AutoPanExtension - Enable/Disable', () {
    test('enable enables autopan', () {
      final ext = AutoPanExtension(enabled: false);

      ext.enable();

      expect(ext.isEnabled, isTrue);
    });

    test('disable disables autopan', () {
      final ext = AutoPanExtension(enabled: true);

      ext.disable();

      expect(ext.isEnabled, isFalse);
    });

    test('toggle toggles state', () {
      final ext = AutoPanExtension(enabled: true);

      ext.toggle();
      expect(ext.isEnabled, isFalse);

      ext.toggle();
      expect(ext.isEnabled, isTrue);
    });
  });

  // ===========================================================================
  // DebugExtension - Construction and Settings
  // ===========================================================================

  group('DebugExtension - Construction', () {
    test('creates with default values', () {
      final ext = DebugExtension();

      expect(ext.mode, equals(DebugMode.none));
      expect(ext.isEnabled, isFalse);
      expect(ext.theme, isA<DebugTheme>());
    });

    test('creates with custom mode', () {
      final ext = DebugExtension(mode: DebugMode.all);

      expect(ext.mode, equals(DebugMode.all));
      expect(ext.isEnabled, isTrue);
    });

    test('creates with custom theme', () {
      final ext = DebugExtension(theme: DebugTheme.dark);

      expect(ext.theme, equals(DebugTheme.dark));
    });
  });

  group('DebugExtension - Mode Settings', () {
    test('setMode changes debug mode', () {
      final ext = DebugExtension();

      ext.setMode(DebugMode.spatialIndex);

      expect(ext.mode, equals(DebugMode.spatialIndex));
    });

    test('toggle switches between none and all', () {
      final ext = DebugExtension(mode: DebugMode.none);

      ext.toggle();
      expect(ext.mode, equals(DebugMode.all));

      ext.toggle();
      expect(ext.mode, equals(DebugMode.none));
    });

    test('cycle goes through all modes', () {
      final ext = DebugExtension(mode: DebugMode.none);

      ext.cycle(); // none -> all
      expect(ext.mode, equals(DebugMode.all));

      ext.cycle(); // all -> spatialIndex
      expect(ext.mode, equals(DebugMode.spatialIndex));

      ext.cycle(); // spatialIndex -> autoPanZone
      expect(ext.mode, equals(DebugMode.autoPanZone));

      ext.cycle(); // autoPanZone -> none
      expect(ext.mode, equals(DebugMode.none));
    });

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

    test('showOnlySpatialIndex sets correct mode', () {
      final ext = DebugExtension();

      ext.showOnlySpatialIndex();

      expect(ext.mode, equals(DebugMode.spatialIndex));
    });

    test('showOnlyAutoPanZone sets correct mode', () {
      final ext = DebugExtension();

      ext.showOnlyAutoPanZone();

      expect(ext.mode, equals(DebugMode.autoPanZone));
    });
  });

  group('DebugExtension - Visual Overlay Properties', () {
    test('showSpatialIndex reflects mode', () {
      final ext = DebugExtension();

      ext.setMode(DebugMode.none);
      expect(ext.showSpatialIndex, isFalse);

      ext.setMode(DebugMode.all);
      expect(ext.showSpatialIndex, isTrue);

      ext.setMode(DebugMode.spatialIndex);
      expect(ext.showSpatialIndex, isTrue);

      ext.setMode(DebugMode.autoPanZone);
      expect(ext.showSpatialIndex, isFalse);
    });

    test('showAutoPanZone reflects mode', () {
      final ext = DebugExtension();

      ext.setMode(DebugMode.none);
      expect(ext.showAutoPanZone, isFalse);

      ext.setMode(DebugMode.all);
      expect(ext.showAutoPanZone, isTrue);

      ext.setMode(DebugMode.autoPanZone);
      expect(ext.showAutoPanZone, isTrue);

      ext.setMode(DebugMode.spatialIndex);
      expect(ext.showAutoPanZone, isFalse);
    });
  });

  group('DebugTheme - Properties', () {
    test('light theme has expected values', () {
      const theme = DebugTheme.light;

      expect(theme.color, isNotNull);
      expect(theme.borderColor, isNotNull);
      expect(theme.activeColor, isNotNull);
      expect(theme.segmentColors, isNotEmpty);
    });

    test('dark theme has expected values', () {
      const theme = DebugTheme.dark;

      expect(theme.color, isNotNull);
      expect(theme.borderColor, isNotNull);
      expect(theme.activeColor, isNotNull);
      expect(theme.segmentColors, isNotEmpty);
    });

    test('getSegmentColor returns valid colors', () {
      const theme = DebugTheme.dark;

      expect(theme.getSegmentColor(0), isA<Color>());
      expect(theme.getSegmentColor(1), isA<Color>());
      expect(theme.getSegmentColor(2), isA<Color>());
      // Index beyond range returns last color
      expect(theme.getSegmentColor(100), isA<Color>());
    });
  });

  // ===========================================================================
  // LodExtension - Level of Detail
  // ===========================================================================

  group('LodExtension - Construction', () {
    test('creates with default values', () {
      final ext = LodExtension();

      expect(ext.isEnabled, isFalse);
      expect(ext.minThreshold, equals(0.03));
      expect(ext.midThreshold, equals(0.1));
      expect(ext.minVisibility, equals(DetailVisibility.minimal));
      expect(ext.midVisibility, equals(DetailVisibility.standard));
      expect(ext.maxVisibility, equals(DetailVisibility.full));
    });

    test('creates with enabled state', () {
      final ext = LodExtension(enabled: true);

      expect(ext.isEnabled, isTrue);
    });

    test('creates with custom thresholds', () {
      final ext = LodExtension(minThreshold: 0.2, midThreshold: 0.6);

      expect(ext.minThreshold, equals(0.2));
      expect(ext.midThreshold, equals(0.6));
    });

    test('creates with custom visibility presets', () {
      const customVisibility = DetailVisibility(
        showNodeContent: true,
        showPorts: false,
        showConnectionLines: true,
      );

      final ext = LodExtension(minVisibility: customVisibility);

      expect(ext.minVisibility, equals(customVisibility));
    });
  });

  group('LodExtension - Threshold Configuration', () {
    test('setMinThreshold updates threshold', () {
      final controller = NodeFlowController<String, dynamic>();
      final lod = controller.lod!;

      // First set a higher mid threshold, then set min threshold
      lod.setMidThreshold(0.5);
      lod.setMinThreshold(0.15);

      expect(lod.minThreshold, equals(0.15));

      controller.dispose();
    });

    test('setMidThreshold updates threshold', () {
      final controller = NodeFlowController<String, dynamic>();
      final lod = controller.lod!;

      lod.setMidThreshold(0.5);

      expect(lod.midThreshold, equals(0.5));

      controller.dispose();
    });

    test('setThresholds updates both thresholds', () {
      final controller = NodeFlowController<String, dynamic>();
      final lod = controller.lod!;

      lod.setThresholds(minThreshold: 0.2, midThreshold: 0.7);

      expect(lod.minThreshold, equals(0.2));
      expect(lod.midThreshold, equals(0.7));

      controller.dispose();
    });
  });

  group('LodExtension - Visibility Calculations', () {
    test('returns max visibility when disabled', () {
      final controller = NodeFlowController<String, dynamic>(
        config: NodeFlowConfig(minZoom: 0.0, maxZoom: 1.0),
        initialViewport: const GraphViewport(zoom: 0.0), // Very zoomed out
      );
      final lod = controller.lod!;

      // LOD disabled by default
      expect(lod.isEnabled, isFalse);
      expect(lod.currentVisibility, equals(DetailVisibility.full));

      controller.dispose();
    });

    test('returns correct visibility for zoom zones when enabled', () {
      final controller = NodeFlowController<String, dynamic>(
        config: NodeFlowConfig(
          minZoom: 0.0,
          maxZoom: 1.0,
          extensions: [
            LodExtension(enabled: true, minThreshold: 0.25, midThreshold: 0.6),
            ...NodeFlowConfig.defaultExtensions().where(
              (e) => e is! LodExtension,
            ),
          ],
        ),
        initialViewport: const GraphViewport(zoom: 0.1), // Below minThreshold
      );
      final lod = controller.lod!;

      // Below minThreshold -> minimal visibility
      expect(lod.currentVisibility, equals(DetailVisibility.minimal));

      // Between thresholds -> standard visibility
      controller.setViewport(const GraphViewport(zoom: 0.4));
      expect(lod.currentVisibility, equals(DetailVisibility.standard));

      // Above midThreshold -> full visibility
      controller.setViewport(const GraphViewport(zoom: 0.8));
      expect(lod.currentVisibility, equals(DetailVisibility.full));

      controller.dispose();
    });

    test('normalizedZoom calculates correctly', () {
      final controller = NodeFlowController<String, dynamic>(
        config: NodeFlowConfig(minZoom: 0.5, maxZoom: 2.0),
        initialViewport: const GraphViewport(zoom: 1.25),
      );
      final lod = controller.lod!;

      // (1.25 - 0.5) / (2.0 - 0.5) = 0.75 / 1.5 = 0.5
      expect(lod.normalizedZoom, closeTo(0.5, 0.01));

      controller.dispose();
    });
  });

  group('LodExtension - Enable/Disable', () {
    test('enable enables LOD', () {
      final controller = NodeFlowController<String, dynamic>();
      final lod = controller.lod!;

      lod.enable();

      expect(lod.isEnabled, isTrue);

      controller.dispose();
    });

    test('disable disables LOD', () {
      final controller = NodeFlowController<String, dynamic>(
        config: NodeFlowConfig(
          extensions: [
            LodExtension(enabled: true),
            ...NodeFlowConfig.defaultExtensions().where(
              (e) => e is! LodExtension,
            ),
          ],
        ),
      );
      final lod = controller.lod!;

      lod.disable();

      expect(lod.isEnabled, isFalse);

      controller.dispose();
    });

    test('toggle toggles state', () {
      final controller = NodeFlowController<String, dynamic>();
      final lod = controller.lod!;

      final initialState = lod.isEnabled;
      lod.toggle();
      expect(lod.isEnabled, equals(!initialState));

      controller.dispose();
    });
  });

  group('LodExtension - Convenience Accessors', () {
    test('convenience accessors match currentVisibility', () {
      final controller = NodeFlowController<String, dynamic>();
      final lod = controller.lod!;
      final visibility = lod.currentVisibility;

      expect(lod.showNodeContent, equals(visibility.showNodeContent));
      expect(lod.showPorts, equals(visibility.showPorts));
      expect(lod.showPortLabels, equals(visibility.showPortLabels));
      expect(lod.showConnectionLines, equals(visibility.showConnectionLines));
      expect(lod.showConnectionLabels, equals(visibility.showConnectionLabels));
      expect(
        lod.showConnectionEndpoints,
        equals(visibility.showConnectionEndpoints),
      );
      expect(lod.showResizeHandles, equals(visibility.showResizeHandles));

      controller.dispose();
    });
  });

  // ===========================================================================
  // MinimapExtension - Construction and State
  // ===========================================================================

  group('MinimapExtension - Construction', () {
    test('creates with default values', () {
      final ext = MinimapExtension();

      expect(ext.isVisible, isFalse);
      expect(ext.isInteractive, isTrue);
      expect(ext.position, equals(MinimapPosition.bottomRight));
      expect(ext.size, equals(const Size(200, 150)));
      expect(ext.margin, equals(20.0));
      expect(ext.autoHighlightSelection, isTrue);
    });

    test('creates with visibility enabled', () {
      final ext = MinimapExtension(visible: true);

      expect(ext.isVisible, isTrue);
    });

    test('creates with custom position', () {
      final ext = MinimapExtension(position: MinimapPosition.topLeft);

      expect(ext.position, equals(MinimapPosition.topLeft));
    });

    test('creates with custom size', () {
      final ext = MinimapExtension(size: const Size(300, 200));

      expect(ext.size, equals(const Size(300, 200)));
    });

    test('creates with custom theme', () {
      final ext = MinimapExtension(theme: MinimapTheme.dark);

      expect(ext.theme, equals(MinimapTheme.dark));
    });
  });

  group('MinimapExtension - Visibility', () {
    test('show makes minimap visible', () {
      final ext = MinimapExtension(visible: false);

      ext.show();

      expect(ext.isVisible, isTrue);
    });

    test('hide makes minimap invisible', () {
      final ext = MinimapExtension(visible: true);

      ext.hide();

      expect(ext.isVisible, isFalse);
    });

    test('toggle toggles visibility', () {
      final ext = MinimapExtension(visible: false);

      ext.toggle();
      expect(ext.isVisible, isTrue);

      ext.toggle();
      expect(ext.isVisible, isFalse);
    });

    test('setVisible sets visibility', () {
      final ext = MinimapExtension();

      ext.setVisible(true);
      expect(ext.isVisible, isTrue);

      ext.setVisible(false);
      expect(ext.isVisible, isFalse);
    });
  });

  group('MinimapExtension - Size', () {
    test('setSize updates size', () {
      final ext = MinimapExtension();

      ext.setSize(const Size(400, 300));

      expect(ext.size, equals(const Size(400, 300)));
    });

    test('setWidth updates only width', () {
      final ext = MinimapExtension(size: const Size(200, 150));

      ext.setWidth(300);

      expect(ext.size.width, equals(300));
      expect(ext.size.height, equals(150));
    });

    test('setHeight updates only height', () {
      final ext = MinimapExtension(size: const Size(200, 150));

      ext.setHeight(200);

      expect(ext.size.width, equals(200));
      expect(ext.size.height, equals(200));
    });
  });

  group('MinimapExtension - Interactivity', () {
    test('enableInteraction enables interaction', () {
      final ext = MinimapExtension(interactive: false);

      ext.enableInteraction();

      expect(ext.isInteractive, isTrue);
    });

    test('disableInteraction disables interaction', () {
      final ext = MinimapExtension(interactive: true);

      ext.disableInteraction();

      expect(ext.isInteractive, isFalse);
    });

    test('toggleInteraction toggles interaction', () {
      final ext = MinimapExtension(interactive: true);

      ext.toggleInteraction();
      expect(ext.isInteractive, isFalse);

      ext.toggleInteraction();
      expect(ext.isInteractive, isTrue);
    });
  });

  group('MinimapExtension - Position', () {
    test('setPosition updates position', () {
      final ext = MinimapExtension(position: MinimapPosition.bottomRight);

      ext.setPosition(MinimapPosition.topLeft);

      expect(ext.position, equals(MinimapPosition.topLeft));
    });

    test('cyclePosition cycles through positions', () {
      final ext = MinimapExtension(position: MinimapPosition.topLeft);

      ext.cyclePosition();
      expect(ext.position, equals(MinimapPosition.topRight));

      ext.cyclePosition();
      expect(ext.position, equals(MinimapPosition.bottomLeft));

      ext.cyclePosition();
      expect(ext.position, equals(MinimapPosition.bottomRight));

      ext.cyclePosition();
      expect(ext.position, equals(MinimapPosition.topLeft));
    });
  });

  group('MinimapExtension - Highlighting', () {
    test('highlightNodes sets highlighted node ids', () {
      final ext = MinimapExtension();

      ext.highlightNodes({'node-1', 'node-2'});

      expect(ext.highlightedNodeIds, containsAll(['node-1', 'node-2']));
    });

    test('highlightArea sets highlight region', () {
      final ext = MinimapExtension();
      const region = Rect.fromLTWH(0, 0, 100, 100);

      ext.highlightArea(region);

      expect(ext.highlightRegion, equals(region));
    });

    test('clearHighlights clears all highlights', () {
      final ext = MinimapExtension();
      ext.highlightNodes({'node-1'});
      ext.highlightArea(const Rect.fromLTWH(0, 0, 100, 100));

      ext.clearHighlights();

      expect(ext.highlightedNodeIds, isEmpty);
      expect(ext.highlightRegion, isNull);
    });

    test('setAutoHighlightSelection updates setting', () {
      final ext = MinimapExtension(autoHighlightSelection: true);

      ext.setAutoHighlightSelection(false);

      expect(ext.autoHighlightSelection, isFalse);
    });
  });

  // ===========================================================================
  // StatsExtension - Statistics Tracking
  // ===========================================================================

  group('StatsExtension - Construction', () {
    test('creates stats extension', () {
      final ext = StatsExtension();

      expect(ext.id, equals('stats'));
    });
  });

  group('StatsExtension - Node Statistics', () {
    test('nodeCount tracks number of nodes', () {
      final controller = NodeFlowController<String, dynamic>(
        nodes: [
          createTestNode(id: 'node-1'),
          createTestNode(id: 'node-2'),
        ],
        config: NodeFlowConfig(extensions: [StatsExtension()]),
      );
      final stats = controller.stats!;

      expect(stats.nodeCount, equals(2));

      controller.addNode(createTestNode(id: 'node-3'));
      expect(stats.nodeCount, equals(3));

      controller.dispose();
    });

    test('visibleNodeCount tracks visible nodes', () {
      final controller = NodeFlowController<String, dynamic>(
        nodes: [
          createTestNode(id: 'visible', visible: true),
          createTestNode(id: 'hidden', visible: false),
        ],
        config: NodeFlowConfig(extensions: [StatsExtension()]),
      );
      final stats = controller.stats!;

      expect(stats.visibleNodeCount, equals(1));

      controller.dispose();
    });

    test('lockedNodeCount tracks locked nodes', () {
      final lockedNode = createTestNode(id: 'node-1');
      // Create a new node with locked: true via constructor
      final regularNode = Node<String>(
        id: 'node-2',
        type: 'test',
        position: Offset.zero,
        data: 'data',
        locked: true,
      );
      final controller = NodeFlowController<String, dynamic>(
        nodes: [lockedNode, regularNode],
        config: NodeFlowConfig(extensions: [StatsExtension()]),
      );
      final stats = controller.stats!;

      // One node is locked (regularNode with locked: true)
      expect(stats.lockedNodeCount, equals(1));

      controller.dispose();
    });

    test('groupCount tracks group nodes', () {
      final group = createTestGroupNode<String>(id: 'group-1', data: 'data');
      final controller = NodeFlowController<String, dynamic>(
        nodes: [group],
        config: NodeFlowConfig(extensions: [StatsExtension()]),
      );
      final stats = controller.stats!;

      expect(stats.groupCount, equals(1));

      controller.dispose();
    });

    test('commentCount tracks comment nodes', () {
      final comment = createTestCommentNode<String>(
        id: 'comment-1',
        data: 'data',
      );
      final controller = NodeFlowController<String, dynamic>(
        nodes: [comment],
        config: NodeFlowConfig(extensions: [StatsExtension()]),
      );
      final stats = controller.stats!;

      expect(stats.commentCount, equals(1));

      controller.dispose();
    });
  });

  group('StatsExtension - Connection Statistics', () {
    test('connectionCount tracks connections', () {
      final nodeA = createTestNodeWithOutputPort(id: 'node-a');
      final nodeB = createTestNodeWithInputPort(id: 'node-b');
      final connection = createTestConnection(
        sourceNodeId: 'node-a',
        targetNodeId: 'node-b',
      );

      final controller = NodeFlowController<String, dynamic>(
        nodes: [nodeA, nodeB],
        connections: [connection],
        config: NodeFlowConfig(extensions: [StatsExtension()]),
      );
      final stats = controller.stats!;

      expect(stats.connectionCount, equals(1));

      controller.dispose();
    });

    test('avgConnectionsPerNode calculates correctly', () {
      final nodeA = createTestNodeWithOutputPort(id: 'node-a');
      final nodeB = createTestNodeWithPorts(id: 'node-b');
      final nodeC = createTestNodeWithInputPort(id: 'node-c');
      final conn1 = createTestConnection(
        id: 'conn-1',
        sourceNodeId: 'node-a',
        targetNodeId: 'node-b',
      );
      final conn2 = createTestConnection(
        id: 'conn-2',
        sourceNodeId: 'node-b',
        sourcePortId: 'output-1',
        targetNodeId: 'node-c',
      );

      final controller = NodeFlowController<String, dynamic>(
        nodes: [nodeA, nodeB, nodeC],
        connections: [conn1, conn2],
        config: NodeFlowConfig(extensions: [StatsExtension()]),
      );
      final stats = controller.stats!;

      // 2 connections / 3 nodes = 0.666...
      expect(stats.avgConnectionsPerNode, closeTo(0.666, 0.01));

      controller.dispose();
    });
  });

  group('StatsExtension - Selection Statistics', () {
    test('selectedNodeCount tracks selected nodes', () {
      final controller = NodeFlowController<String, dynamic>(
        nodes: [
          createTestNode(id: 'node-1'),
          createTestNode(id: 'node-2'),
        ],
        config: NodeFlowConfig(extensions: [StatsExtension()]),
      );
      final stats = controller.stats!;

      expect(stats.selectedNodeCount, equals(0));

      controller.selectNode('node-1');
      expect(stats.selectedNodeCount, equals(1));

      controller.selectNodes(['node-1', 'node-2']);
      expect(stats.selectedNodeCount, equals(2));

      controller.dispose();
    });

    test('hasSelection reflects selection state', () {
      final controller = NodeFlowController<String, dynamic>(
        nodes: [createTestNode(id: 'node-1')],
        config: NodeFlowConfig(extensions: [StatsExtension()]),
      );
      final stats = controller.stats!;

      expect(stats.hasSelection, isFalse);

      controller.selectNode('node-1');
      expect(stats.hasSelection, isTrue);

      controller.dispose();
    });

    test('isMultiSelection detects multiple selections', () {
      final controller = NodeFlowController<String, dynamic>(
        nodes: [
          createTestNode(id: 'node-1'),
          createTestNode(id: 'node-2'),
        ],
        config: NodeFlowConfig(extensions: [StatsExtension()]),
      );
      final stats = controller.stats!;

      controller.selectNode('node-1');
      expect(stats.isMultiSelection, isFalse);

      controller.selectNodes(['node-1', 'node-2']);
      expect(stats.isMultiSelection, isTrue);

      controller.dispose();
    });
  });

  group('StatsExtension - Viewport Statistics', () {
    test('zoom reflects current zoom level', () {
      final controller = NodeFlowController<String, dynamic>(
        initialViewport: const GraphViewport(zoom: 1.5),
        config: NodeFlowConfig(extensions: [StatsExtension()]),
      );
      final stats = controller.stats!;

      expect(stats.zoom, equals(1.5));

      controller.dispose();
    });

    test('zoomPercent returns percentage', () {
      final controller = NodeFlowController<String, dynamic>(
        initialViewport: const GraphViewport(zoom: 0.75),
        config: NodeFlowConfig(extensions: [StatsExtension()]),
      );
      final stats = controller.stats!;

      expect(stats.zoomPercent, equals(75));

      controller.dispose();
    });

    test('pan reflects current pan offset', () {
      final controller = NodeFlowController<String, dynamic>(
        initialViewport: const GraphViewport(x: 100, y: 200),
        config: NodeFlowConfig(extensions: [StatsExtension()]),
      );
      final stats = controller.stats!;

      expect(stats.pan.dx, equals(100));
      expect(stats.pan.dy, equals(200));

      controller.dispose();
    });
  });

  group('StatsExtension - Summary Helpers', () {
    test('summary returns node and connection counts', () {
      final nodeA = createTestNodeWithOutputPort(id: 'node-a');
      final nodeB = createTestNodeWithInputPort(id: 'node-b');
      final connection = createTestConnection(
        sourceNodeId: 'node-a',
        targetNodeId: 'node-b',
      );

      final controller = NodeFlowController<String, dynamic>(
        nodes: [nodeA, nodeB],
        connections: [connection],
        config: NodeFlowConfig(extensions: [StatsExtension()]),
      );
      final stats = controller.stats!;

      expect(stats.summary, equals('2 nodes, 1 connections'));

      controller.dispose();
    });

    test('selectionSummary shows nothing selected', () {
      final controller = NodeFlowController<String, dynamic>(
        nodes: [createTestNode(id: 'node-1')],
        config: NodeFlowConfig(extensions: [StatsExtension()]),
      );
      final stats = controller.stats!;

      expect(stats.selectionSummary, equals('Nothing selected'));

      controller.dispose();
    });

    test('selectionSummary shows selected counts', () {
      final controller = NodeFlowController<String, dynamic>(
        nodes: [
          createTestNode(id: 'node-1'),
          createTestNode(id: 'node-2'),
        ],
        config: NodeFlowConfig(extensions: [StatsExtension()]),
      );
      final stats = controller.stats!;

      controller.selectNode('node-1');
      expect(stats.selectionSummary, contains('1 node'));

      controller.selectNodes(['node-1', 'node-2']);
      expect(stats.selectionSummary, contains('2 nodes'));

      controller.dispose();
    });

    test('viewportSummary shows zoom and position', () {
      final controller = NodeFlowController<String, dynamic>(
        initialViewport: const GraphViewport(x: 50, y: 100, zoom: 0.8),
        config: NodeFlowConfig(extensions: [StatsExtension()]),
      );
      final stats = controller.stats!;

      expect(stats.viewportSummary, contains('80%'));
      expect(stats.viewportSummary, contains('50'));
      expect(stats.viewportSummary, contains('100'));

      controller.dispose();
    });
  });

  // ===========================================================================
  // Extensions with Controller Integration
  // ===========================================================================

  group('Extensions - Controller Integration', () {
    test('all default extensions can be resolved from config', () {
      final controller = NodeFlowController<String, dynamic>();

      // Extensions are lazily attached when accessed
      // Access each one to verify they're available
      expect(controller.autoPan, isNotNull);
      expect(controller.debug, isNotNull);
      expect(controller.lod, isNotNull);
      expect(controller.minimap, isNotNull);
      expect(controller.stats, isNotNull);

      // After access, they should be registered
      expect(controller.hasExtension('auto-pan'), isTrue);
      expect(controller.hasExtension('debug'), isTrue);
      expect(controller.hasExtension('lod'), isTrue);
      expect(controller.hasExtension('minimap'), isTrue);
      expect(controller.hasExtension('stats'), isTrue);

      controller.dispose();
    });

    test('extensions can be accessed via controller getters', () {
      final controller = NodeFlowController<String, dynamic>();

      expect(controller.autoPan, isA<AutoPanExtension>());
      expect(controller.debug, isA<DebugExtension>());
      expect(controller.lod, isA<LodExtension>());

      controller.dispose();
    });

    test('optional extensions return null when not registered', () {
      final controller = NodeFlowController<String, dynamic>(
        config: NodeFlowConfig(extensions: []),
      );

      expect(controller.minimap, isNull);
      expect(controller.stats, isNull);

      controller.dispose();
    });

    test('extensions can be added dynamically', () {
      final controller = NodeFlowController<String, dynamic>(
        config: NodeFlowConfig(extensions: []),
      );

      expect(controller.stats, isNull);

      controller.addExtension(StatsExtension());

      expect(controller.stats, isNotNull);

      controller.dispose();
    });

    test('resolveExtension returns registered extension', () {
      final controller = NodeFlowController<String, dynamic>();

      final autoPan = controller.resolveExtension<AutoPanExtension>();

      expect(autoPan, isA<AutoPanExtension>());

      controller.dispose();
    });

    test('resolveExtension returns null for unregistered extension', () {
      final controller = NodeFlowController<String, dynamic>(
        config: NodeFlowConfig(extensions: []),
      );

      final minimap = controller.resolveExtension<MinimapExtension>();

      expect(minimap, isNull);

      controller.dispose();
    });
  });

  group('Extensions - Custom Configuration', () {
    test('extensions can be customized via config', () {
      final controller = NodeFlowController<String, dynamic>(
        config: NodeFlowConfig(
          extensions: [
            AutoPanExtension(panAmount: 25.0),
            DebugExtension(mode: DebugMode.spatialIndex),
            LodExtension(enabled: true, minThreshold: 0.15),
          ],
        ),
      );

      expect(controller.autoPan?.panAmount, equals(25.0));
      expect(controller.debug?.mode, equals(DebugMode.spatialIndex));
      expect(controller.lod?.minThreshold, equals(0.15));
      expect(controller.lod?.isEnabled, isTrue);

      controller.dispose();
    });
  });
}
