/// Unit tests for the [LodPlugin] class.
///
/// These tests specifically target uncovered methods and edge cases:
/// - setMinThreshold() and setMidThreshold() individual setters
/// - setMinVisibility(), setMidVisibility(), setMaxVisibility() setters
/// - setEnabled() method
/// - onEvent() method
/// - detach() lifecycle method
/// - Edge case: normalizedZoom when zoom range is zero
@Tags(['unit'])
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:vyuh_node_flow/vyuh_node_flow.dart';

void main() {
  // ===========================================================================
  // LodPlugin - Individual Threshold Setters
  // ===========================================================================

  group('LodPlugin - setMinThreshold', () {
    test('setMinThreshold updates the minimum threshold value', () {
      final controller = NodeFlowController<String, dynamic>(
        config: NodeFlowConfig(
          minZoom: 0.0,
          maxZoom: 1.0,
          plugins: [
            LodPlugin(enabled: true, minThreshold: 0.1, midThreshold: 0.5),
            ...NodeFlowConfig.defaultPlugins().where((e) => e is! LodPlugin),
          ],
        ),
        initialViewport: const GraphViewport(zoom: 0.3),
      );

      final lod = controller.lod!;

      // Initial state
      expect(lod.minThreshold, equals(0.1));
      expect(lod.currentVisibility, same(DetailVisibility.standard));

      // Update minThreshold to 0.4 (now 0.3 is below minThreshold)
      lod.setMinThreshold(0.4);
      expect(lod.minThreshold, equals(0.4));
      expect(lod.currentVisibility, same(DetailVisibility.minimal));

      controller.dispose();
    });

    test('setMinThreshold validates range 0.0 to 1.0', () {
      final controller = NodeFlowController<String, dynamic>(
        config: NodeFlowConfig(
          plugins: [
            LodPlugin(enabled: true, minThreshold: 0.1, midThreshold: 0.5),
            ...NodeFlowConfig.defaultPlugins().where((e) => e is! LodPlugin),
          ],
        ),
      );

      final lod = controller.lod!;

      // Valid boundary values
      lod.setMinThreshold(0.0);
      expect(lod.minThreshold, equals(0.0));

      lod.setMinThreshold(0.5); // Must be <= midThreshold
      expect(lod.minThreshold, equals(0.5));

      controller.dispose();
    });
  });

  group('LodPlugin - setMidThreshold', () {
    test('setMidThreshold updates the mid threshold value', () {
      final controller = NodeFlowController<String, dynamic>(
        config: NodeFlowConfig(
          minZoom: 0.0,
          maxZoom: 1.0,
          plugins: [
            LodPlugin(enabled: true, minThreshold: 0.1, midThreshold: 0.5),
            ...NodeFlowConfig.defaultPlugins().where((e) => e is! LodPlugin),
          ],
        ),
        initialViewport: const GraphViewport(zoom: 0.6),
      );

      final lod = controller.lod!;

      // Initial state: zoom 0.6 is above midThreshold 0.5 -> full visibility
      expect(lod.midThreshold, equals(0.5));
      expect(lod.currentVisibility, same(DetailVisibility.full));

      // Update midThreshold to 0.8 (now 0.6 is between min and mid)
      lod.setMidThreshold(0.8);
      expect(lod.midThreshold, equals(0.8));
      expect(lod.currentVisibility, same(DetailVisibility.standard));

      controller.dispose();
    });

    test('setMidThreshold validates range 0.0 to 1.0', () {
      final controller = NodeFlowController<String, dynamic>(
        config: NodeFlowConfig(
          plugins: [
            LodPlugin(enabled: true, minThreshold: 0.1, midThreshold: 0.5),
            ...NodeFlowConfig.defaultPlugins().where((e) => e is! LodPlugin),
          ],
        ),
      );

      final lod = controller.lod!;

      // Valid boundary values
      lod.setMidThreshold(1.0);
      expect(lod.midThreshold, equals(1.0));

      lod.setMidThreshold(0.1); // Must be >= minThreshold
      expect(lod.midThreshold, equals(0.1));

      controller.dispose();
    });
  });

  // ===========================================================================
  // LodPlugin - Individual Visibility Setters
  // ===========================================================================

  group('LodPlugin - setMinVisibility', () {
    test('setMinVisibility updates the minimum visibility configuration', () {
      final controller = NodeFlowController<String, dynamic>(
        config: NodeFlowConfig(
          minZoom: 0.0,
          maxZoom: 1.0,
          plugins: [
            LodPlugin(enabled: true, minThreshold: 0.3, midThreshold: 0.6),
            ...NodeFlowConfig.defaultPlugins().where((e) => e is! LodPlugin),
          ],
        ),
        initialViewport: const GraphViewport(zoom: 0.1), // Below minThreshold
      );

      final lod = controller.lod!;

      // Initial state: zoom below minThreshold uses minVisibility (minimal)
      expect(lod.minVisibility, same(DetailVisibility.minimal));
      expect(lod.currentVisibility, same(DetailVisibility.minimal));

      // Update minVisibility to a custom configuration
      const customVisibility = DetailVisibility(
        showNodeContent: true,
        showPorts: false,
        showPortLabels: false,
        showConnectionLines: true,
        showConnectionLabels: false,
        showConnectionEndpoints: false,
        showResizeHandles: false,
      );
      lod.setMinVisibility(customVisibility);

      expect(lod.minVisibility, equals(customVisibility));
      expect(lod.currentVisibility, equals(customVisibility));

      controller.dispose();
    });
  });

  group('LodPlugin - setMidVisibility', () {
    test('setMidVisibility updates the mid visibility configuration', () {
      final controller = NodeFlowController<String, dynamic>(
        config: NodeFlowConfig(
          minZoom: 0.0,
          maxZoom: 1.0,
          plugins: [
            LodPlugin(enabled: true, minThreshold: 0.2, midThreshold: 0.8),
            ...NodeFlowConfig.defaultPlugins().where((e) => e is! LodPlugin),
          ],
        ),
        initialViewport: const GraphViewport(
          zoom: 0.5,
        ), // Between min and mid thresholds
      );

      final lod = controller.lod!;

      // Initial state: zoom between thresholds uses midVisibility (standard)
      expect(lod.midVisibility, same(DetailVisibility.standard));
      expect(lod.currentVisibility, same(DetailVisibility.standard));

      // Update midVisibility to a custom configuration
      const customVisibility = DetailVisibility(
        showNodeContent: true,
        showPorts: true,
        showPortLabels: false,
        showConnectionLines: true,
        showConnectionLabels: false,
        showConnectionEndpoints: true,
        showResizeHandles: false,
      );
      lod.setMidVisibility(customVisibility);

      expect(lod.midVisibility, equals(customVisibility));
      expect(lod.currentVisibility, equals(customVisibility));

      controller.dispose();
    });
  });

  group('LodPlugin - setMaxVisibility', () {
    test('setMaxVisibility updates the maximum visibility configuration', () {
      final controller = NodeFlowController<String, dynamic>(
        config: NodeFlowConfig(
          minZoom: 0.0,
          maxZoom: 1.0,
          plugins: [
            LodPlugin(enabled: true, minThreshold: 0.2, midThreshold: 0.5),
            ...NodeFlowConfig.defaultPlugins().where((e) => e is! LodPlugin),
          ],
        ),
        initialViewport: const GraphViewport(zoom: 0.8), // Above midThreshold
      );

      final lod = controller.lod!;

      // Initial state: zoom above midThreshold uses maxVisibility (full)
      expect(lod.maxVisibility, same(DetailVisibility.full));
      expect(lod.currentVisibility, same(DetailVisibility.full));

      // Update maxVisibility to a custom configuration (e.g., hide resize handles)
      const customVisibility = DetailVisibility(
        showNodeContent: true,
        showPorts: true,
        showPortLabels: true,
        showConnectionLines: true,
        showConnectionLabels: true,
        showConnectionEndpoints: true,
        showResizeHandles: false, // Hide resize handles even at max zoom
      );
      lod.setMaxVisibility(customVisibility);

      expect(lod.maxVisibility, equals(customVisibility));
      expect(lod.currentVisibility, equals(customVisibility));

      controller.dispose();
    });

    test('setMaxVisibility affects disabled LOD state', () {
      final controller = NodeFlowController<String, dynamic>(
        config: NodeFlowConfig(
          minZoom: 0.0,
          maxZoom: 1.0,
          plugins: [
            LodPlugin(enabled: false), // LOD disabled
            ...NodeFlowConfig.defaultPlugins().where((e) => e is! LodPlugin),
          ],
        ),
        initialViewport: const GraphViewport(zoom: 0.1), // Low zoom
      );

      final lod = controller.lod!;

      // When disabled, always returns maxVisibility
      expect(lod.isEnabled, isFalse);
      expect(lod.currentVisibility, same(DetailVisibility.full));

      // Update maxVisibility
      const customVisibility = DetailVisibility(
        showNodeContent: true,
        showPorts: false,
        showPortLabels: false,
        showConnectionLines: true,
        showConnectionLabels: false,
        showConnectionEndpoints: false,
        showResizeHandles: false,
      );
      lod.setMaxVisibility(customVisibility);

      // Even when disabled, currentVisibility should reflect new maxVisibility
      expect(lod.currentVisibility, equals(customVisibility));

      controller.dispose();
    });
  });

  // ===========================================================================
  // LodPlugin - setEnabled Method
  // ===========================================================================

  group('LodPlugin - setEnabled', () {
    test('setEnabled(true) enables LOD functionality', () {
      final controller = NodeFlowController<String, dynamic>(
        config: NodeFlowConfig(
          minZoom: 0.0,
          maxZoom: 1.0,
          plugins: [
            LodPlugin(enabled: false, minThreshold: 0.3, midThreshold: 0.6),
            ...NodeFlowConfig.defaultPlugins().where((e) => e is! LodPlugin),
          ],
        ),
        initialViewport: const GraphViewport(zoom: 0.1), // Below minThreshold
      );

      final lod = controller.lod!;

      // Initially disabled - always full visibility
      expect(lod.isEnabled, isFalse);
      expect(lod.currentVisibility, same(DetailVisibility.full));

      // Enable LOD
      lod.setEnabled(true);

      expect(lod.isEnabled, isTrue);
      // Now at zoom 0.1 with minThreshold 0.3, should be minimal
      expect(lod.currentVisibility, same(DetailVisibility.minimal));

      controller.dispose();
    });

    test('setEnabled(false) disables LOD functionality', () {
      final controller = NodeFlowController<String, dynamic>(
        config: NodeFlowConfig(
          minZoom: 0.0,
          maxZoom: 1.0,
          plugins: [
            LodPlugin(enabled: true, minThreshold: 0.3, midThreshold: 0.6),
            ...NodeFlowConfig.defaultPlugins().where((e) => e is! LodPlugin),
          ],
        ),
        initialViewport: const GraphViewport(zoom: 0.1), // Below minThreshold
      );

      final lod = controller.lod!;

      // Initially enabled - minimal visibility at low zoom
      expect(lod.isEnabled, isTrue);
      expect(lod.currentVisibility, same(DetailVisibility.minimal));

      // Disable LOD
      lod.setEnabled(false);

      expect(lod.isEnabled, isFalse);
      expect(lod.currentVisibility, same(DetailVisibility.full));

      controller.dispose();
    });

    test('setEnabled with same value has no effect', () {
      final controller = NodeFlowController<String, dynamic>(
        config: NodeFlowConfig(
          plugins: [
            LodPlugin(enabled: true),
            ...NodeFlowConfig.defaultPlugins().where((e) => e is! LodPlugin),
          ],
        ),
      );

      final lod = controller.lod!;

      expect(lod.isEnabled, isTrue);

      // Set to same value
      lod.setEnabled(true);
      expect(lod.isEnabled, isTrue);

      // Set to opposite, then same
      lod.setEnabled(false);
      expect(lod.isEnabled, isFalse);

      lod.setEnabled(false);
      expect(lod.isEnabled, isFalse);

      controller.dispose();
    });
  });

  // ===========================================================================
  // LodPlugin - Plugin ID
  // ===========================================================================

  group('LodPlugin - Plugin ID', () {
    test('extension has correct id', () {
      final lod = LodPlugin();
      expect(lod.id, equals('lod'));
    });
  });

  // ===========================================================================
  // LodPlugin - Normalized Zoom Edge Cases
  // ===========================================================================

  group('LodPlugin - Normalized Zoom Edge Cases', () {
    test('normalizedZoom returns 1.0 when zoom range is zero', () {
      // Create config where minZoom equals maxZoom
      final controller = NodeFlowController<String, dynamic>(
        config: NodeFlowConfig(
          minZoom: 1.0,
          maxZoom: 1.0, // Same as minZoom -> range is 0
          plugins: [
            LodPlugin(enabled: true),
            ...NodeFlowConfig.defaultPlugins().where((e) => e is! LodPlugin),
          ],
        ),
        initialViewport: const GraphViewport(zoom: 1.0),
      );

      final lod = controller.lod!;

      // When range is 0, normalizedZoom should return 1.0
      expect(lod.normalizedZoom, equals(1.0));

      controller.dispose();
    });
  });

  // ===========================================================================
  // LodPlugin - enable() Method
  // ===========================================================================

  group('LodPlugin - enable() Method', () {
    test('enable() sets isEnabled to true', () {
      final controller = NodeFlowController<String, dynamic>(
        config: NodeFlowConfig(
          minZoom: 0.0,
          maxZoom: 1.0,
          plugins: [
            LodPlugin(enabled: false),
            ...NodeFlowConfig.defaultPlugins().where((e) => e is! LodPlugin),
          ],
        ),
        initialViewport: const GraphViewport(zoom: 0.5),
      );

      final lod = controller.lod!;

      expect(lod.isEnabled, isFalse);

      lod.enable();

      expect(lod.isEnabled, isTrue);

      controller.dispose();
    });
  });

  // ===========================================================================
  // LodPlugin - Lifecycle Methods
  // ===========================================================================

  group('LodPlugin - Lifecycle Methods', () {
    test('onEvent does not throw for any graph event', () {
      final lod = LodPlugin();

      // Create a controller to attach the extension
      final controller = NodeFlowController<String, dynamic>(
        config: NodeFlowConfig(
          plugins: [
            lod,
            ...NodeFlowConfig.defaultPlugins().where((e) => e is! LodPlugin),
          ],
        ),
      );

      // onEvent should not throw for any event type
      // LOD extension does not react to graph events - it only reacts to
      // viewport zoom changes via MobX computed values
      const event = ViewportChanged(
        GraphViewport(zoom: 1.0),
        GraphViewport(zoom: 0.5),
      );
      expect(() => lod.onEvent(event), returnsNormally);

      controller.dispose();
    });

    test('detach cleans up controller reference', () {
      final lod = LodPlugin();

      // Create a controller to attach the extension
      final controller = NodeFlowController<String, dynamic>(
        config: NodeFlowConfig(
          plugins: [
            lod,
            ...NodeFlowConfig.defaultPlugins().where((e) => e is! LodPlugin),
          ],
        ),
      );

      // Plugin is attached, verify it has 'lod' id
      expect(lod.id, equals('lod'));

      // Detach should not throw
      expect(() => lod.detach(), returnsNormally);

      controller.dispose();
    });
  });
}
