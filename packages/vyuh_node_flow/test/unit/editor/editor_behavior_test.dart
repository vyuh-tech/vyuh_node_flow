/// Unit tests for the editor behavior modes and auto-pan extension.
///
/// Tests cover:
/// - NodeFlowBehavior enum values and computed properties
/// - Controller behavior API
/// - Controller resize state
/// - Auto-pan extension integration
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
  // NodeFlowBehavior Enum Tests
  // ===========================================================================

  group('NodeFlowBehavior Enum', () {
    test('has all expected behavior modes', () {
      expect(NodeFlowBehavior.values, hasLength(4));
      expect(NodeFlowBehavior.values, contains(NodeFlowBehavior.design));
      expect(NodeFlowBehavior.values, contains(NodeFlowBehavior.preview));
      expect(NodeFlowBehavior.values, contains(NodeFlowBehavior.inspect));
      expect(NodeFlowBehavior.values, contains(NodeFlowBehavior.present));
    });
  });

  group('NodeFlowBehavior.design', () {
    const behavior = NodeFlowBehavior.design;

    test('allows all CRUD operations', () {
      expect(behavior.canCreate, isTrue);
      expect(behavior.canUpdate, isTrue);
      expect(behavior.canDelete, isTrue);
    });

    test('allows all interactions', () {
      expect(behavior.canDrag, isTrue);
      expect(behavior.canSelect, isTrue);
      expect(behavior.canPan, isTrue);
      expect(behavior.canZoom, isTrue);
    });

    test('canModify returns true', () {
      expect(behavior.canModify, isTrue);
    });

    test('isInteractive returns true', () {
      expect(behavior.isInteractive, isTrue);
    });
  });

  group('NodeFlowBehavior.preview', () {
    const behavior = NodeFlowBehavior.preview;

    test('disallows structural changes', () {
      expect(behavior.canCreate, isFalse);
      expect(behavior.canUpdate, isFalse);
      expect(behavior.canDelete, isFalse);
    });

    test('allows layout adjustments and navigation', () {
      expect(behavior.canDrag, isTrue);
      expect(behavior.canSelect, isTrue);
      expect(behavior.canPan, isTrue);
      expect(behavior.canZoom, isTrue);
    });

    test('canModify returns false', () {
      expect(behavior.canModify, isFalse);
    });

    test('isInteractive returns true', () {
      expect(behavior.isInteractive, isTrue);
    });
  });

  group('NodeFlowBehavior.inspect', () {
    const behavior = NodeFlowBehavior.inspect;

    test('disallows structural changes', () {
      expect(behavior.canCreate, isFalse);
      expect(behavior.canUpdate, isFalse);
      expect(behavior.canDelete, isFalse);
    });

    test('allows selection and navigation but not dragging', () {
      expect(behavior.canDrag, isFalse);
      expect(behavior.canSelect, isTrue);
      expect(behavior.canPan, isTrue);
      expect(behavior.canZoom, isTrue);
    });

    test('canModify returns false', () {
      expect(behavior.canModify, isFalse);
    });

    test('isInteractive returns true', () {
      expect(behavior.isInteractive, isTrue);
    });
  });

  group('NodeFlowBehavior.present', () {
    const behavior = NodeFlowBehavior.present;

    test('disallows all CRUD operations', () {
      expect(behavior.canCreate, isFalse);
      expect(behavior.canUpdate, isFalse);
      expect(behavior.canDelete, isFalse);
    });

    test('disallows all interactions', () {
      expect(behavior.canDrag, isFalse);
      expect(behavior.canSelect, isFalse);
      expect(behavior.canPan, isFalse);
      expect(behavior.canZoom, isFalse);
    });

    test('canModify returns false', () {
      expect(behavior.canModify, isFalse);
    });

    test('isInteractive returns false', () {
      expect(behavior.isInteractive, isFalse);
    });
  });

  group('NodeFlowBehavior Computed Properties', () {
    test('canModify is true when any of create/update/delete is true', () {
      // design has all true, so canModify is true
      expect(NodeFlowBehavior.design.canModify, isTrue);

      // preview, inspect, and present have all false, so canModify is false
      expect(NodeFlowBehavior.preview.canModify, isFalse);
      expect(NodeFlowBehavior.inspect.canModify, isFalse);
      expect(NodeFlowBehavior.present.canModify, isFalse);
    });

    test('isInteractive is true when any interaction is allowed', () {
      // design, preview, and inspect allow interactions
      expect(NodeFlowBehavior.design.isInteractive, isTrue);
      expect(NodeFlowBehavior.preview.isInteractive, isTrue);
      expect(NodeFlowBehavior.inspect.isInteractive, isTrue);

      // present allows no interactions
      expect(NodeFlowBehavior.present.isInteractive, isFalse);
    });
  });

  // ===========================================================================
  // Controller Behavior API Tests
  // ===========================================================================

  group('Controller Behavior API', () {
    test('controller starts with design behavior by default', () {
      final controller = createTestController();
      expect(controller.behavior, equals(NodeFlowBehavior.design));
    });

    test('setBehavior changes the behavior mode', () {
      final controller = createTestController();

      controller.setBehavior(NodeFlowBehavior.preview);
      expect(controller.behavior, equals(NodeFlowBehavior.preview));

      controller.setBehavior(NodeFlowBehavior.present);
      expect(controller.behavior, equals(NodeFlowBehavior.present));

      controller.setBehavior(NodeFlowBehavior.design);
      expect(controller.behavior, equals(NodeFlowBehavior.design));
    });

    test('behavior affects controller capabilities', () {
      final controller = createTestController();

      controller.setBehavior(NodeFlowBehavior.design);
      expect(controller.behavior.canCreate, isTrue);
      expect(controller.behavior.canDelete, isTrue);

      controller.setBehavior(NodeFlowBehavior.preview);
      expect(controller.behavior.canCreate, isFalse);
      expect(controller.behavior.canDelete, isFalse);
    });
  });

  // ===========================================================================
  // Controller Resize State Tests
  // ===========================================================================

  group('Controller Resize State', () {
    test('exposes resize state from interaction', () {
      final controller = createTestController();

      expect(controller.resizingNodeId, isNull);
      expect(controller.isResizing, isFalse);
    });

    test('interaction provides resize state access', () {
      final controller = createTestController();
      final state = controller.interaction;

      expect(state.isResizing, isFalse);
      expect(state.currentResizingNodeId, isNull);
      expect(state.currentResizeHandle, isNull);
      expect(state.currentResizeStartPosition, isNull);
      expect(state.currentOriginalNodeBounds, isNull);
      expect(state.currentHandleDrift, equals(Offset.zero));
    });

    test('cursor override state accessible', () {
      final controller = createTestController();
      final state = controller.interaction;

      expect(state.hasCursorOverride, isFalse);
      expect(state.currentCursorOverride, isNull);

      // Set cursor override
      state.setCursorOverride(SystemMouseCursors.resizeLeftRight);

      expect(state.hasCursorOverride, isTrue);
      expect(
        state.currentCursorOverride,
        equals(SystemMouseCursors.resizeLeftRight),
      );

      // Clear cursor override
      state.setCursorOverride(null);
      expect(state.hasCursorOverride, isFalse);
    });

    test('canvas lock state accessible', () {
      final controller = createTestController();
      final state = controller.interaction;

      expect(state.isCanvasLocked, isFalse);

      state.canvasLocked.value = true;
      expect(state.isCanvasLocked, isTrue);

      state.canvasLocked.value = false;
      expect(state.isCanvasLocked, isFalse);
    });

    test('handle drift state accessible', () {
      final controller = createTestController();
      final state = controller.interaction;

      expect(state.currentHandleDrift, equals(Offset.zero));

      state.setHandleDrift(const Offset(10, 15));
      expect(state.currentHandleDrift, equals(const Offset(10, 15)));

      state.setHandleDrift(const Offset(-5, 20));
      expect(state.currentHandleDrift, equals(const Offset(-5, 20)));
    });

    test('endResize clears resize state', () {
      final controller = createTestController();
      final state = controller.interaction;

      // Set some state
      state.setHandleDrift(const Offset(10, 15));
      state.setCursorOverride(SystemMouseCursors.resizeUpDown);
      state.canvasLocked.value = true;

      // End resize
      state.endResize();

      expect(state.currentHandleDrift, equals(Offset.zero));
      expect(state.hasCursorOverride, isFalse);
      expect(state.isCanvasLocked, isFalse);
    });

    test('resetState clears all resize state', () {
      final controller = createTestController();
      final state = controller.interaction;

      // Set various states
      state.setHandleDrift(const Offset(10, 15));
      state.setCursorOverride(SystemMouseCursors.resizeUpDown);
      state.canvasLocked.value = true;
      state.setHoveringConnection(true);

      // Reset
      state.resetState();

      // Verify all cleared
      expect(state.currentHandleDrift, equals(Offset.zero));
      expect(state.hasCursorOverride, isFalse);
      expect(state.isCanvasLocked, isFalse);
      expect(state.isHoveringConnection, isFalse);
    });
  });

  // ===========================================================================
  // Auto-Pan Plugin Integration Tests
  // ===========================================================================

  group('AutoPanPlugin Integration', () {
    test('controller can have autopan extension attached', () {
      final controller = createTestController();
      final autoPan = AutoPanPlugin();

      controller.addPlugin(autoPan);

      expect(controller.hasPlugin('auto-pan'), isTrue);
    });

    test('autopan extension is retrievable by type', () {
      final controller = createTestController();
      final autoPan = AutoPanPlugin();

      controller.addPlugin(autoPan);

      final retrieved = controller.getPlugin<AutoPanPlugin>();
      expect(retrieved, isNotNull);
      expect(retrieved, equals(autoPan));
    });

    test('autopan can be enabled and disabled', () {
      final autoPan = AutoPanPlugin(enabled: true);

      expect(autoPan.isEnabled, isTrue);

      autoPan.disable();
      expect(autoPan.isEnabled, isFalse);

      autoPan.enable();
      expect(autoPan.isEnabled, isTrue);
    });

    test('autopan presets work correctly', () {
      final autoPan = AutoPanPlugin();

      autoPan.useNormal();
      expect(autoPan.panAmount, equals(10.0));
      expect(autoPan.edgePadding, equals(const EdgeInsets.all(50.0)));

      autoPan.useFast();
      expect(autoPan.panAmount, equals(20.0));
      expect(autoPan.edgePadding, equals(const EdgeInsets.all(60.0)));

      autoPan.usePrecise();
      expect(autoPan.panAmount, equals(5.0));
      expect(autoPan.edgePadding, equals(const EdgeInsets.all(30.0)));
    });

    test('autopan can toggle state', () {
      final autoPan = AutoPanPlugin(enabled: true);

      expect(autoPan.isEnabled, isTrue);

      autoPan.toggle();
      expect(autoPan.isEnabled, isFalse);

      autoPan.toggle();
      expect(autoPan.isEnabled, isTrue);
    });

    test('autopan can have custom configuration', () {
      final autoPan = AutoPanPlugin(
        enabled: true,
        panAmount: 15.0,
        edgePadding: const EdgeInsets.all(40.0),
      );

      expect(autoPan.isEnabled, isTrue);
      expect(autoPan.panAmount, equals(15.0));
      expect(autoPan.edgePadding, equals(const EdgeInsets.all(40.0)));
    });

    test('individual setters update settings', () {
      final autoPan = AutoPanPlugin();

      autoPan.setPanAmount(25.0);
      autoPan.setEdgePadding(const EdgeInsets.all(75.0));

      expect(autoPan.panAmount, equals(25.0));
      expect(autoPan.edgePadding, equals(const EdgeInsets.all(75.0)));
    });

    test('extension ID is auto-pan', () {
      final autoPan = AutoPanPlugin();
      expect(autoPan.id, equals('auto-pan'));
    });
  });

  // ===========================================================================
  // Plugin System Tests
  // ===========================================================================

  group('Plugin System', () {
    test('cannot add same extension twice', () {
      final controller = createTestController();
      final autoPan = AutoPanPlugin();

      controller.addPlugin(autoPan);

      expect(() => controller.addPlugin(autoPan), throwsStateError);
    });

    test('removePlugin removes by ID', () {
      final controller = createTestController();
      final autoPan = AutoPanPlugin();

      controller.addPlugin(autoPan);
      expect(controller.hasPlugin('auto-pan'), isTrue);

      controller.removePlugin('auto-pan');
      expect(controller.hasPlugin('auto-pan'), isFalse);
    });

    test('getPlugin returns null for non-existent extension', () {
      final controller = createTestController();

      final retrieved = controller.getPlugin<AutoPanPlugin>();
      expect(retrieved, isNull);
    });

    test('extensions getter returns list of all extensions', () {
      final controller = createTestController();
      final autoPan = AutoPanPlugin();
      final debug = DebugPlugin();

      controller.addPlugin(autoPan);
      controller.addPlugin(debug);

      expect(controller.plugins, hasLength(2));
      expect(controller.plugins, contains(autoPan));
      expect(controller.plugins, contains(debug));
    });
  });

  // ===========================================================================
  // Edge Cases and Error Handling
  // ===========================================================================

  group('Behavior Edge Cases', () {
    test('behavior changes preserve other controller state', () {
      final controller = createTestController();
      final node = createTestNode();
      controller.addNode(node);
      controller.selectNode(node.id);

      controller.setBehavior(NodeFlowBehavior.preview);

      expect(controller.behavior, equals(NodeFlowBehavior.preview));
      expect(controller.selectedNodeIds, contains(node.id));
      expect(controller.nodes.containsKey(node.id), isTrue);
    });

    test('endResize is idempotent', () {
      final controller = createTestController();
      final state = controller.interaction;

      // End without start should not throw
      state.endResize();
      expect(state.isResizing, isFalse);

      // Multiple ends should not throw
      state.endResize();
      state.endResize();
      expect(state.isResizing, isFalse);
    });

    test('resetState is idempotent', () {
      final controller = createTestController();
      final state = controller.interaction;

      // Reset on fresh state should not throw
      state.resetState();
      expect(state.isResizing, isFalse);

      // Multiple resets should not throw
      state.resetState();
      state.resetState();
      expect(state.isResizing, isFalse);
    });
  });
}
