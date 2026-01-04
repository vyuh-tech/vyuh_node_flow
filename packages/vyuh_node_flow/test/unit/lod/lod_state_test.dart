/// Unit tests for the LOD (Level of Detail) system.
///
/// Tests cover:
/// - DetailVisibility configuration class and factory presets
/// - LodExtension threshold configuration and visibility resolution
/// - LodExtension reactive state and normalized zoom calculations
/// - Integration with NodeFlowConfig
@Tags(['unit'])
library;

import 'package:flutter_test/flutter_test.dart';
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
  });

  // ===========================================================================
  // DetailVisibility - Custom Configuration
  // ===========================================================================

  group('DetailVisibility - Custom Configuration', () {
    test('custom visibility can hide specific elements', () {
      const visibility = DetailVisibility(
        showNodeContent: true,
        showPorts: true,
        showPortLabels: false, // Hide labels only
        showConnectionLines: true,
        showConnectionLabels: false,
        showConnectionEndpoints: true,
        showResizeHandles: false,
      );

      expect(visibility.showNodeContent, isTrue);
      expect(visibility.showPorts, isTrue);
      expect(visibility.showPortLabels, isFalse);
      expect(visibility.showConnectionLines, isTrue);
      expect(visibility.showConnectionLabels, isFalse);
      expect(visibility.showConnectionEndpoints, isTrue);
      expect(visibility.showResizeHandles, isFalse);
    });

    test('equality works for same configuration', () {
      const v1 = DetailVisibility.full;
      const v2 = DetailVisibility(
        showNodeContent: true,
        showPorts: true,
        showPortLabels: true,
        showConnectionLines: true,
        showConnectionLabels: true,
        showConnectionEndpoints: true,
        showResizeHandles: true,
      );

      expect(v1, equals(v2));
    });
  });

  // ===========================================================================
  // LodExtension - Threshold Configuration
  // ===========================================================================

  group('LodExtension - Threshold Configuration', () {
    test('default thresholds have sensible values', () {
      final controller = NodeFlowController<String, dynamic>();
      final lod = controller.lod!;

      // Actual defaults: minThreshold=0.03, midThreshold=0.1
      expect(lod.minThreshold, equals(0.03));
      expect(lod.midThreshold, equals(0.1));
      expect(lod.minVisibility, same(DetailVisibility.minimal));
      expect(lod.midVisibility, same(DetailVisibility.standard));
      expect(lod.maxVisibility, same(DetailVisibility.full));

      controller.dispose();
    });

    test('disabled LOD always shows full detail', () {
      final controller = NodeFlowController<String, dynamic>(
        config: NodeFlowConfig(minZoom: 0.0, maxZoom: 1.0),
        initialViewport: const GraphViewport(zoom: 0.1),
      );
      final lod = controller.lod!;

      // LOD disabled by default
      expect(lod.isEnabled, isFalse);

      // At any zoom we get full visibility when disabled
      expect(lod.currentVisibility, same(DetailVisibility.full));

      controller.setViewport(const GraphViewport(zoom: 0.5));
      expect(lod.currentVisibility, same(DetailVisibility.full));

      controller.setViewport(const GraphViewport(zoom: 1.0));
      expect(lod.currentVisibility, same(DetailVisibility.full));

      controller.dispose();
    });

    test('can set thresholds at runtime', () {
      final controller = NodeFlowController<String, dynamic>(
        config: NodeFlowConfig(
          minZoom: 0.0,
          maxZoom: 1.0,
          extensions: [
            LodExtension(enabled: true),
            ...NodeFlowConfig.defaultExtensions().where(
              (e) => e is! LodExtension,
            ),
          ],
        ),
        initialViewport: const GraphViewport(zoom: 0.5),
      );
      final lod = controller.lod!;

      // Set custom thresholds
      lod.setThresholds(minThreshold: 0.3, midThreshold: 0.7);
      expect(lod.minThreshold, equals(0.3));
      expect(lod.midThreshold, equals(0.7));

      // At zoom 0.5 with new thresholds (0.3-0.7), should be mid visibility
      expect(lod.currentVisibility, same(DetailVisibility.standard));

      controller.dispose();
    });
  });

  // ===========================================================================
  // LodExtension - Visibility Resolution
  // ===========================================================================

  group('LodExtension - Visibility Resolution', () {
    test('returns correct visibility for each zoom zone', () {
      final controller = NodeFlowController<String, dynamic>(
        config: NodeFlowConfig(
          minZoom: 0.0,
          maxZoom: 1.0,
          extensions: [
            LodExtension(enabled: true, minThreshold: 0.25, midThreshold: 0.60),
            ...NodeFlowConfig.defaultExtensions().where(
              (e) => e is! LodExtension,
            ),
          ],
        ),
        initialViewport: const GraphViewport(zoom: 0.0),
      );
      final lod = controller.lod!;

      // Below minThreshold -> minVisibility
      controller.setViewport(const GraphViewport(zoom: 0.0));
      expect(lod.currentVisibility, same(DetailVisibility.minimal));

      controller.setViewport(const GraphViewport(zoom: 0.24));
      expect(lod.currentVisibility, same(DetailVisibility.minimal));

      // At or above minThreshold but below midThreshold -> midVisibility
      controller.setViewport(const GraphViewport(zoom: 0.25));
      expect(lod.currentVisibility, same(DetailVisibility.standard));

      controller.setViewport(const GraphViewport(zoom: 0.40));
      expect(lod.currentVisibility, same(DetailVisibility.standard));

      controller.setViewport(const GraphViewport(zoom: 0.59));
      expect(lod.currentVisibility, same(DetailVisibility.standard));

      // At or above midThreshold -> maxVisibility
      controller.setViewport(const GraphViewport(zoom: 0.60));
      expect(lod.currentVisibility, same(DetailVisibility.full));

      controller.setViewport(const GraphViewport(zoom: 0.80));
      expect(lod.currentVisibility, same(DetailVisibility.full));

      controller.setViewport(const GraphViewport(zoom: 1.0));
      expect(lod.currentVisibility, same(DetailVisibility.full));

      controller.dispose();
    });

    test('edge cases: thresholds at boundaries', () {
      // All thresholds at 0 - always max
      final controllerMin = NodeFlowController<String, dynamic>(
        config: NodeFlowConfig(
          minZoom: 0.0,
          maxZoom: 1.0,
          extensions: [
            LodExtension(enabled: true, minThreshold: 0.0, midThreshold: 0.0),
            ...NodeFlowConfig.defaultExtensions().where(
              (e) => e is! LodExtension,
            ),
          ],
        ),
        initialViewport: const GraphViewport(zoom: 0.0),
      );
      expect(controllerMin.lod!.currentVisibility, same(DetailVisibility.full));
      controllerMin.setViewport(const GraphViewport(zoom: 0.5));
      expect(controllerMin.lod!.currentVisibility, same(DetailVisibility.full));
      controllerMin.dispose();

      // All thresholds at 1 - always min except at exactly 1
      final controllerMax = NodeFlowController<String, dynamic>(
        config: NodeFlowConfig(
          minZoom: 0.0,
          maxZoom: 1.0,
          extensions: [
            LodExtension(enabled: true, minThreshold: 1.0, midThreshold: 1.0),
            ...NodeFlowConfig.defaultExtensions().where(
              (e) => e is! LodExtension,
            ),
          ],
        ),
        initialViewport: const GraphViewport(zoom: 0.0),
      );
      expect(
        controllerMax.lod!.currentVisibility,
        same(DetailVisibility.minimal),
      );
      controllerMax.setViewport(const GraphViewport(zoom: 0.99));
      expect(
        controllerMax.lod!.currentVisibility,
        same(DetailVisibility.minimal),
      );
      controllerMax.setViewport(const GraphViewport(zoom: 1.0));
      expect(controllerMax.lod!.currentVisibility, same(DetailVisibility.full));
      controllerMax.dispose();
    });
  });

  // ===========================================================================
  // LodExtension - Normalized Zoom Calculation
  // ===========================================================================

  group('LodExtension - Normalized Zoom Calculation', () {
    test('calculates normalized zoom correctly', () {
      final controller = NodeFlowController<String, dynamic>(
        config: NodeFlowConfig(minZoom: 0.5, maxZoom: 2.0),
        initialViewport: const GraphViewport(zoom: 1.0),
      );

      // At zoom 1.0, with range 0.5-2.0
      // normalized = (1.0 - 0.5) / (2.0 - 0.5) = 0.5 / 1.5 = 0.333...
      expect(controller.lod!.normalizedZoom, closeTo(0.333, 0.01));

      controller.dispose();
    });

    test('normalized zoom is 0 at minZoom', () {
      final controller = NodeFlowController<String, dynamic>(
        config: NodeFlowConfig(minZoom: 0.5, maxZoom: 2.0),
        initialViewport: const GraphViewport(zoom: 0.5),
      );

      expect(controller.lod!.normalizedZoom, equals(0.0));

      controller.dispose();
    });

    test('normalized zoom is 1 at maxZoom', () {
      final controller = NodeFlowController<String, dynamic>(
        config: NodeFlowConfig(minZoom: 0.5, maxZoom: 2.0),
        initialViewport: const GraphViewport(zoom: 2.0),
      );

      expect(controller.lod!.normalizedZoom, equals(1.0));

      controller.dispose();
    });

    test('normalized zoom clamps to valid range', () {
      // Below minZoom
      final controllerLow = NodeFlowController<String, dynamic>(
        config: NodeFlowConfig(minZoom: 0.5, maxZoom: 2.0),
        initialViewport: const GraphViewport(zoom: 0.3),
      );
      expect(controllerLow.lod!.normalizedZoom, equals(0.0));
      controllerLow.dispose();

      // Above maxZoom
      final controllerHigh = NodeFlowController<String, dynamic>(
        config: NodeFlowConfig(minZoom: 0.5, maxZoom: 2.0),
        initialViewport: const GraphViewport(zoom: 3.0),
      );
      expect(controllerHigh.lod!.normalizedZoom, equals(1.0));
      controllerHigh.dispose();
    });
  });

  // ===========================================================================
  // LodExtension - Current Visibility
  // ===========================================================================

  group('LodExtension - Current Visibility', () {
    test('returns visibility based on normalized zoom and thresholds', () {
      NodeFlowConfig configWithLod({
        double minThreshold = 0.25,
        double midThreshold = 0.60,
      }) => NodeFlowConfig(
        minZoom: 0.0,
        maxZoom: 1.0,
        extensions: [
          LodExtension(
            enabled: true,
            minThreshold: minThreshold,
            midThreshold: midThreshold,
          ),
          ...NodeFlowConfig.defaultExtensions().where(
            (e) => e is! LodExtension,
          ),
        ],
      );

      // Below minThreshold (zoom 0.1 = normalized 0.1)
      final controllerMin = NodeFlowController<String, dynamic>(
        config: configWithLod(),
        initialViewport: const GraphViewport(zoom: 0.1),
      );
      expect(
        controllerMin.lod!.currentVisibility,
        same(DetailVisibility.minimal),
      );
      controllerMin.dispose();

      // Between thresholds (zoom 0.4 = normalized 0.4)
      final controllerMid = NodeFlowController<String, dynamic>(
        config: configWithLod(),
        initialViewport: const GraphViewport(zoom: 0.4),
      );
      expect(
        controllerMid.lod!.currentVisibility,
        same(DetailVisibility.standard),
      );
      controllerMid.dispose();

      // Above midThreshold (zoom 0.8 = normalized 0.8)
      final controllerMax = NodeFlowController<String, dynamic>(
        config: configWithLod(),
        initialViewport: const GraphViewport(zoom: 0.8),
      );
      expect(controllerMax.lod!.currentVisibility, same(DetailVisibility.full));
      controllerMax.dispose();
    });
  });

  // ===========================================================================
  // LodExtension - Convenience Accessors
  // ===========================================================================

  group('LodExtension - Convenience Accessors', () {
    test('convenience accessors match currentVisibility', () {
      final controller = NodeFlowController<String, dynamic>(
        config: NodeFlowConfig(
          minZoom: 0.0,
          maxZoom: 1.0,
          extensions: [
            LodExtension(enabled: true, minThreshold: 0.25, midThreshold: 0.60),
            ...NodeFlowConfig.defaultExtensions().where(
              (e) => e is! LodExtension,
            ),
          ],
        ),
        initialViewport: const GraphViewport(zoom: 0.8), // Full visibility
      );

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
  // LodExtension - Enable/Disable
  // ===========================================================================

  group('LodExtension - Enable/Disable', () {
    test('disable() changes visibility behavior', () {
      final controller = NodeFlowController<String, dynamic>(
        config: NodeFlowConfig(
          minZoom: 0.0,
          maxZoom: 1.0,
          extensions: [
            LodExtension(enabled: true, minThreshold: 0.25, midThreshold: 0.60),
            ...NodeFlowConfig.defaultExtensions().where(
              (e) => e is! LodExtension,
            ),
          ],
        ),
        initialViewport: const GraphViewport(zoom: 0.5), // Mid-range
      );

      // Initially should be standard visibility
      expect(
        controller.lod!.currentVisibility,
        same(DetailVisibility.standard),
      );

      // Disable LOD (always full)
      controller.lod!.disable();

      // Now should be full visibility even at same zoom
      expect(controller.lod!.currentVisibility, same(DetailVisibility.full));

      controller.dispose();
    });

    test('toggle() switches enabled state', () {
      final controller = NodeFlowController<String, dynamic>(
        config: NodeFlowConfig(
          minZoom: 0.0,
          maxZoom: 1.0,
          extensions: [
            LodExtension(enabled: true, minThreshold: 0.25, midThreshold: 0.60),
            ...NodeFlowConfig.defaultExtensions().where(
              (e) => e is! LodExtension,
            ),
          ],
        ),
        initialViewport: const GraphViewport(zoom: 0.1),
      );

      final lod = controller.lod!;

      // Initially enabled, should be minimal
      expect(lod.isEnabled, isTrue);
      expect(lod.currentVisibility, same(DetailVisibility.minimal));

      // Toggle off
      lod.toggle();
      expect(lod.isEnabled, isFalse);
      expect(lod.currentVisibility, same(DetailVisibility.full));

      // Toggle back on
      lod.toggle();
      expect(lod.isEnabled, isTrue);
      expect(lod.currentVisibility, same(DetailVisibility.minimal));

      controller.dispose();
    });
  });

  // ===========================================================================
  // LodExtension - Reactivity
  // ===========================================================================

  group('LodExtension - Reactivity', () {
    test('visibility updates when viewport zoom changes', () {
      final controller = NodeFlowController<String, dynamic>(
        config: NodeFlowConfig(
          minZoom: 0.0,
          maxZoom: 1.0,
          extensions: [
            LodExtension(enabled: true, minThreshold: 0.25, midThreshold: 0.60),
            ...NodeFlowConfig.defaultExtensions().where(
              (e) => e is! LodExtension,
            ),
          ],
        ),
        initialViewport: const GraphViewport(zoom: 0.1),
      );

      // Start at minimal
      expect(controller.lod!.currentVisibility, same(DetailVisibility.minimal));

      // Zoom to mid-range
      controller.setViewport(const GraphViewport(zoom: 0.4));
      expect(
        controller.lod!.currentVisibility,
        same(DetailVisibility.standard),
      );

      // Zoom to full
      controller.setViewport(const GraphViewport(zoom: 0.8));
      expect(controller.lod!.currentVisibility, same(DetailVisibility.full));

      // Zoom back to minimal
      controller.setViewport(const GraphViewport(zoom: 0.1));
      expect(controller.lod!.currentVisibility, same(DetailVisibility.minimal));

      controller.dispose();
    });
  });

  // ===========================================================================
  // LodExtension - Extension Lifecycle
  // ===========================================================================

  group('LodExtension - Extension Lifecycle', () {
    test('lod getter returns the same extension instance', () {
      final controller = NodeFlowController<String, dynamic>();

      final lod1 = controller.lod;
      final lod2 = controller.lod;

      expect(identical(lod1, lod2), isTrue);

      controller.dispose();
    });

    test('lod extension is registered with controller', () {
      final controller = NodeFlowController<String, dynamic>();

      // Access lod to trigger lazy registration
      controller.lod;

      expect(controller.hasExtension('lod'), isTrue);

      controller.dispose();
    });
  });
}
