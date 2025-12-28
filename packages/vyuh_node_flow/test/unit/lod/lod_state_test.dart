/// Unit tests for the LOD (Level of Detail) system.
///
/// Tests cover:
/// - DetailVisibility configuration class and factory presets
/// - LODConfig threshold configuration and visibility resolution
/// - LODState reactive state and normalized zoom calculations
/// - Integration with NodeFlowConfig
@Tags(['unit'])
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:mobx/mobx.dart';
import 'package:vyuh_node_flow/vyuh_node_flow.dart';

void main() {
  // ===========================================================================
  // DetailVisibility - Factory Presets
  // ===========================================================================

  group('DetailVisibility - Factory Presets', () {
    test('minimal preset hides most elements but keeps connection lines', () {
      const visibility = DetailVisibility.minimal;

      expect(visibility.showNodeContent, isFalse);
      expect(visibility.showPorts, isFalse);
      expect(visibility.showPortLabels, isFalse);
      expect(
        visibility.showConnectionLines,
        isTrue,
      ); // Kept for graph structure
      expect(visibility.showConnectionLabels, isFalse);
      expect(visibility.showConnectionEndpoints, isFalse);
      expect(visibility.showResizeHandles, isFalse);
    });

    test('standard preset shows node content and connections only', () {
      const visibility = DetailVisibility.standard;

      expect(visibility.showNodeContent, isTrue);
      expect(visibility.showPorts, isFalse);
      expect(visibility.showPortLabels, isFalse);
      expect(visibility.showConnectionLines, isTrue);
      expect(visibility.showConnectionLabels, isFalse);
      expect(visibility.showConnectionEndpoints, isFalse);
      expect(visibility.showResizeHandles, isFalse);
    });

    test('full preset shows all elements', () {
      const visibility = DetailVisibility.full;

      expect(visibility.showNodeContent, isTrue);
      expect(visibility.showPorts, isTrue);
      expect(visibility.showPortLabels, isTrue);
      expect(visibility.showConnectionLines, isTrue);
      expect(visibility.showConnectionLabels, isTrue);
      expect(visibility.showConnectionEndpoints, isTrue);
      expect(visibility.showResizeHandles, isTrue);
    });

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
  });

  // ===========================================================================
  // DetailVisibility - Custom Configuration
  // ===========================================================================

  group('DetailVisibility - Custom Configuration', () {
    test('can create custom visibility configuration', () {
      const visibility = DetailVisibility(
        showNodeContent: true,
        showPorts: true,
        showPortLabels: false,
        showConnectionLines: true,
        showConnectionLabels: true,
        showConnectionEndpoints: false,
        showResizeHandles: false,
      );

      expect(visibility.showNodeContent, isTrue);
      expect(visibility.showPorts, isTrue);
      expect(visibility.showPortLabels, isFalse);
      expect(visibility.showConnectionLines, isTrue);
      expect(visibility.showConnectionLabels, isTrue);
      expect(visibility.showConnectionEndpoints, isFalse);
      expect(visibility.showResizeHandles, isFalse);
    });

    test('copyWith creates modified copy', () {
      const original = DetailVisibility.minimal;
      final modified = original.copyWith(showNodeContent: true);

      expect(modified.showNodeContent, isTrue);
      expect(modified.showPorts, isFalse); // Other values preserved
      expect(modified.showConnectionLines, isTrue); // Preserved from minimal
    });

    test('copyWith preserves unspecified values', () {
      const original = DetailVisibility.full;
      final modified = original.copyWith(showResizeHandles: false);

      expect(modified.showNodeContent, isTrue);
      expect(modified.showPorts, isTrue);
      expect(modified.showPortLabels, isTrue);
      expect(modified.showConnectionLines, isTrue);
      expect(modified.showConnectionLabels, isTrue);
      expect(modified.showConnectionEndpoints, isTrue);
      expect(modified.showResizeHandles, isFalse); // Only this changed
    });
  });

  // ===========================================================================
  // LODConfig - Configuration Basics
  // ===========================================================================

  group('LODConfig - Configuration Basics', () {
    test('has valid default thresholds', () {
      const config = LODConfig();

      expect(config.minThreshold, greaterThanOrEqualTo(0.0));
      expect(config.minThreshold, lessThanOrEqualTo(1.0));
      expect(config.midThreshold, greaterThanOrEqualTo(config.minThreshold));
      expect(config.midThreshold, lessThanOrEqualTo(1.0));
    });

    test('has expected default visibility presets', () {
      const config = LODConfig();

      expect(config.minVisibility, same(DetailVisibility.minimal));
      expect(config.midVisibility, same(DetailVisibility.standard));
      expect(config.maxVisibility, same(DetailVisibility.full));
    });

    test('defaultConfig is a constant LODConfig', () {
      expect(LODConfig.defaultConfig, isA<LODConfig>());
    });
  });

  // ===========================================================================
  // LODConfig - Disabled Configuration
  // ===========================================================================

  group('LODConfig - Disabled Configuration', () {
    test('disabled config has zero thresholds', () {
      const config = LODConfig.disabled;

      expect(config.minThreshold, equals(0.0));
      expect(config.midThreshold, equals(0.0));
    });

    test('disabled config always returns max visibility', () {
      const config = LODConfig.disabled;

      // At any normalized zoom level, should get max visibility
      expect(config.getVisibilityForZoom(0.0), same(config.maxVisibility));
      expect(config.getVisibilityForZoom(0.5), same(config.maxVisibility));
      expect(config.getVisibilityForZoom(1.0), same(config.maxVisibility));
    });
  });

  // ===========================================================================
  // LODConfig - getVisibilityForZoom
  // ===========================================================================

  group('LODConfig - getVisibilityForZoom', () {
    test('returns correct visibility based on threshold boundaries', () {
      const config = LODConfig(minThreshold: 0.25, midThreshold: 0.60);

      // Below minThreshold -> minVisibility
      expect(config.getVisibilityForZoom(0.0), same(config.minVisibility));
      expect(config.getVisibilityForZoom(0.24), same(config.minVisibility));

      // Between thresholds -> midVisibility
      expect(config.getVisibilityForZoom(0.25), same(config.midVisibility));
      expect(config.getVisibilityForZoom(0.59), same(config.midVisibility));

      // At or above midThreshold -> maxVisibility
      expect(config.getVisibilityForZoom(0.60), same(config.maxVisibility));
      expect(config.getVisibilityForZoom(1.0), same(config.maxVisibility));
    });

    test('handles edge cases correctly', () {
      const config = LODConfig(minThreshold: 0.3, midThreshold: 0.7);

      // At exactly minThreshold - should be midVisibility
      expect(
        config.getVisibilityForZoom(config.minThreshold),
        same(config.midVisibility),
      );

      // At exactly midThreshold - should be maxVisibility
      expect(
        config.getVisibilityForZoom(config.midThreshold),
        same(config.maxVisibility),
      );
    });
  });

  // ===========================================================================
  // LODConfig - Custom Thresholds
  // ===========================================================================

  group('LODConfig - Custom Thresholds', () {
    test('can create with custom thresholds', () {
      const config = LODConfig(minThreshold: 0.3, midThreshold: 0.7);

      expect(config.minThreshold, equals(0.3));
      expect(config.midThreshold, equals(0.7));
    });

    test('can use custom visibility presets', () {
      const customMinimal = DetailVisibility(
        showNodeContent: true,
        showPorts: false,
        showPortLabels: false,
        showConnectionLines: false,
        showConnectionLabels: false,
        showConnectionEndpoints: false,
        showResizeHandles: false,
      );

      const config = LODConfig(
        minThreshold: 0.2,
        midThreshold: 0.5,
        minVisibility: customMinimal,
      );

      expect(config.minVisibility, same(customMinimal));
      expect(config.getVisibilityForZoom(0.1), same(customMinimal));
    });
  });

  // ===========================================================================
  // LODState - Normalized Zoom Calculation
  // ===========================================================================

  group('LODState - Normalized Zoom Calculation', () {
    test('calculates normalized zoom correctly', () {
      final config = NodeFlowConfig(minZoom: 0.5, maxZoom: 2.0);
      final viewport = Observable(GraphViewport(zoom: 1.0));
      final lodState = LODState(config: config, viewport: viewport);

      // At zoom 1.0, with range 0.5-2.0
      // normalized = (1.0 - 0.5) / (2.0 - 0.5) = 0.5 / 1.5 = 0.333...
      expect(lodState.normalizedZoom, closeTo(0.333, 0.01));
    });

    test('normalized zoom is 0 at minZoom', () {
      final config = NodeFlowConfig(minZoom: 0.5, maxZoom: 2.0);
      final viewport = Observable(GraphViewport(zoom: 0.5));
      final lodState = LODState(config: config, viewport: viewport);

      expect(lodState.normalizedZoom, equals(0.0));
    });

    test('normalized zoom is 1 at maxZoom', () {
      final config = NodeFlowConfig(minZoom: 0.5, maxZoom: 2.0);
      final viewport = Observable(GraphViewport(zoom: 2.0));
      final lodState = LODState(config: config, viewport: viewport);

      expect(lodState.normalizedZoom, equals(1.0));
    });

    test('normalized zoom clamps to valid range', () {
      final config = NodeFlowConfig(minZoom: 0.5, maxZoom: 2.0);

      // Below minZoom
      final viewportLow = Observable(GraphViewport(zoom: 0.3));
      final lodStateLow = LODState(config: config, viewport: viewportLow);
      expect(lodStateLow.normalizedZoom, equals(0.0));

      // Above maxZoom
      final viewportHigh = Observable(GraphViewport(zoom: 3.0));
      final lodStateHigh = LODState(config: config, viewport: viewportHigh);
      expect(lodStateHigh.normalizedZoom, equals(1.0));
    });
  });

  // ===========================================================================
  // LODState - Current Visibility
  // ===========================================================================

  group('LODState - Current Visibility', () {
    test('returns visibility based on normalized zoom and thresholds', () {
      // Test with explicit thresholds at 0.25 and 0.60
      const lodConfig = LODConfig(minThreshold: 0.25, midThreshold: 0.60);

      // Below minThreshold (zoom 0.1 = normalized 0.1)
      final configMin = NodeFlowConfig(
        minZoom: 0.0,
        maxZoom: 1.0,
        lodConfig: lodConfig,
      );
      final viewportMin = Observable(GraphViewport(zoom: 0.1));
      final lodStateMin = LODState(config: configMin, viewport: viewportMin);
      expect(lodStateMin.currentVisibility, same(DetailVisibility.minimal));

      // Between thresholds (zoom 0.4 = normalized 0.4)
      final configMid = NodeFlowConfig(
        minZoom: 0.0,
        maxZoom: 1.0,
        lodConfig: lodConfig,
      );
      final viewportMid = Observable(GraphViewport(zoom: 0.4));
      final lodStateMid = LODState(config: configMid, viewport: viewportMid);
      expect(lodStateMid.currentVisibility, same(DetailVisibility.standard));

      // Above midThreshold (zoom 0.8 = normalized 0.8)
      final configMax = NodeFlowConfig(
        minZoom: 0.0,
        maxZoom: 1.0,
        lodConfig: lodConfig,
      );
      final viewportMax = Observable(GraphViewport(zoom: 0.8));
      final lodStateMax = LODState(config: configMax, viewport: viewportMax);
      expect(lodStateMax.currentVisibility, same(DetailVisibility.full));
    });
  });

  // ===========================================================================
  // LODState - Convenience Accessors
  // ===========================================================================

  group('LODState - Convenience Accessors', () {
    test('convenience accessors match currentVisibility', () {
      final config = NodeFlowConfig(
        minZoom: 0.0,
        maxZoom: 1.0,
        lodConfig: const LODConfig(minThreshold: 0.25, midThreshold: 0.60),
      );
      final viewport = Observable(GraphViewport(zoom: 0.5));
      final lodState = LODState(config: config, viewport: viewport);

      final visibility = lodState.currentVisibility;

      expect(lodState.showNodeContent, equals(visibility.showNodeContent));
      expect(lodState.showPorts, equals(visibility.showPorts));
      expect(lodState.showPortLabels, equals(visibility.showPortLabels));
      expect(
        lodState.showConnectionLines,
        equals(visibility.showConnectionLines),
      );
      expect(
        lodState.showConnectionLabels,
        equals(visibility.showConnectionLabels),
      );
      expect(
        lodState.showConnectionEndpoints,
        equals(visibility.showConnectionEndpoints),
      );
      expect(lodState.showResizeHandles, equals(visibility.showResizeHandles));
    });
  });

  // ===========================================================================
  // LODState - LODConfig Updates
  // ===========================================================================

  group('LODState - LODConfig Updates', () {
    test('updateConfig changes visibility resolution', () {
      final config = NodeFlowConfig(
        minZoom: 0.0,
        maxZoom: 1.0,
        lodConfig: const LODConfig(minThreshold: 0.25, midThreshold: 0.60),
      );
      // Zoom 0.3 with default thresholds would be standard visibility
      final viewport = Observable(GraphViewport(zoom: 0.3));
      final lodState = LODState(config: config, viewport: viewport);

      // Initially at standard visibility
      expect(lodState.currentVisibility, same(DetailVisibility.standard));

      // Update to disabled LOD
      lodState.updateConfig(LODConfig.disabled);

      // Now should always show full
      expect(lodState.currentVisibility, same(DetailVisibility.full));
    });
  });

  // ===========================================================================
  // NodeFlowConfig - LOD Integration
  // ===========================================================================

  group('NodeFlowConfig - LOD Integration', () {
    test('accepts lodConfig parameter', () {
      const customLOD = LODConfig(minThreshold: 0.3, midThreshold: 0.7);
      final config = NodeFlowConfig(lodConfig: customLOD);

      expect(config.lodConfig.value.minThreshold, equals(0.3));
      expect(config.lodConfig.value.midThreshold, equals(0.7));
    });

    test('setLODConfig updates config', () {
      final config = NodeFlowConfig();

      config.setLODConfig(LODConfig.disabled);

      expect(config.lodConfig.value.minThreshold, equals(0.0));
    });

    test('disableLOD sets disabled config', () {
      final config = NodeFlowConfig();

      config.disableLOD();

      expect(config.lodConfig.value, same(LODConfig.disabled));
    });

    test('copyWith preserves lodConfig when not specified', () {
      const customLOD = LODConfig(minThreshold: 0.1, midThreshold: 0.5);
      final config = NodeFlowConfig(lodConfig: customLOD);

      final copied = config.copyWith(snapToGrid: true);

      expect(copied.lodConfig.value.minThreshold, equals(0.1));
      expect(copied.lodConfig.value.midThreshold, equals(0.5));
    });

    test('copyWith can change lodConfig', () {
      final config = NodeFlowConfig();

      final copied = config.copyWith(lodConfig: LODConfig.disabled);

      expect(copied.lodConfig.value, same(LODConfig.disabled));
    });
  });

  // ===========================================================================
  // Integration - Zoom Changes and Reactivity
  // ===========================================================================

  group('LODState - Reactivity', () {
    test('visibility updates when zoom changes', () {
      // Use simple 0-1 range for easy testing
      // Explicit thresholds for predictable testing
      final config = NodeFlowConfig(
        minZoom: 0.0,
        maxZoom: 1.0,
        lodConfig: const LODConfig(minThreshold: 0.25, midThreshold: 0.60),
      );
      final viewport = Observable(GraphViewport(zoom: 0.0));

      final lodState = LODState(config: config, viewport: viewport);

      // Initially at minimal (zoom 0.0)
      expect(lodState.currentVisibility, same(DetailVisibility.minimal));

      // Zoom in to medium range (0.4 is between 0.25 and 0.60)
      runInAction(() {
        viewport.value = GraphViewport(zoom: 0.4);
      });
      expect(lodState.currentVisibility, same(DetailVisibility.standard));

      // Zoom in to full detail (0.8 is above 0.60)
      runInAction(() {
        viewport.value = GraphViewport(zoom: 0.8);
      });
      expect(lodState.currentVisibility, same(DetailVisibility.full));

      // Zoom back out to minimal (0.1 is below 0.25)
      runInAction(() {
        viewport.value = GraphViewport(zoom: 0.1);
      });
      expect(lodState.currentVisibility, same(DetailVisibility.minimal));
    });
  });
}
