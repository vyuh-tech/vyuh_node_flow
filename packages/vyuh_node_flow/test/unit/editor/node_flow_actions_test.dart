/// Unit tests for the node flow actions and shortcut manager.
///
/// Tests cover:
/// - NodeFlowAction base class
/// - DefaultNodeFlowActions factory
/// - Selection actions (select all, invert, clear)
/// - Editing actions (delete, duplicate)
/// - Navigation actions (fit to view, zoom)
/// - Arrangement actions (z-order)
/// - Alignment actions
/// - General actions (cancel, toggle minimap/snapping)
/// - NodeFlowShortcutManager
@Tags(['unit'])
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vyuh_node_flow/vyuh_node_flow.dart';

import '../../helpers/test_factories.dart';

void main() {
  setUp(() {
    resetTestCounters();
  });

  // ===========================================================================
  // DefaultNodeFlowActions Factory Tests
  // ===========================================================================

  group('DefaultNodeFlowActions', () {
    test('createDefaultActions returns all expected actions', () {
      final actions = DefaultNodeFlowActions.createDefaultActions<String>();

      expect(actions, isNotEmpty);
      // Verify we have a reasonable number of actions
      expect(actions.length, greaterThanOrEqualTo(20));
    });

    test('all actions have unique IDs', () {
      final actions = DefaultNodeFlowActions.createDefaultActions<String>();
      final ids = actions.map((a) => a.id).toSet();

      expect(ids.length, equals(actions.length));
    });

    test('all actions have non-empty labels', () {
      final actions = DefaultNodeFlowActions.createDefaultActions<String>();

      for (final action in actions) {
        expect(action.label, isNotEmpty);
      }
    });

    test('all actions have categories', () {
      final actions = DefaultNodeFlowActions.createDefaultActions<String>();

      for (final action in actions) {
        expect(action.category, isNotEmpty);
      }
    });

    test('actions are properly categorized', () {
      final actions = DefaultNodeFlowActions.createDefaultActions<String>();
      final categories = actions.map((a) => a.category).toSet();

      // Verify expected categories exist
      expect(categories, contains('Selection'));
      expect(categories, contains('Edit'));
      expect(categories, contains('Navigation'));
      expect(categories, contains('Arrangement'));
      expect(categories, contains('Alignment'));
    });
  });

  // ===========================================================================
  // Selection Action Tests
  // ===========================================================================

  group('Select All Action', () {
    test('action has correct metadata', () {
      final actions = DefaultNodeFlowActions.createDefaultActions<String>();
      final selectAll = actions.firstWhere((a) => a.id == 'select_all_nodes');

      expect(selectAll.id, equals('select_all_nodes'));
      expect(selectAll.label, equals('Select All'));
      expect(selectAll.category, equals('Selection'));
      expect(selectAll.description, isNotNull);
    });

    test('canExecute returns false when no nodes exist', () {
      final controller = createTestController();
      final actions = DefaultNodeFlowActions.createDefaultActions<String>();
      final selectAll = actions.firstWhere((a) => a.id == 'select_all_nodes');

      expect(selectAll.canExecute(controller), isFalse);
    });

    test('canExecute returns true when nodes exist', () {
      final controller = createTestController();
      controller.addNode(createTestNode());

      final actions = DefaultNodeFlowActions.createDefaultActions<String>();
      final selectAll = actions.firstWhere((a) => a.id == 'select_all_nodes');

      expect(selectAll.canExecute(controller), isTrue);
    });

    test('execute selects all selectable nodes', () {
      final controller = createTestController();
      final node1 = createTestNode(id: 'node-1');
      final node2 = createTestNode(id: 'node-2');
      final node3 = createTestNode(id: 'node-3');
      controller.addNode(node1);
      controller.addNode(node2);
      controller.addNode(node3);

      expect(controller.selectedNodeIds, isEmpty);

      final actions = DefaultNodeFlowActions.createDefaultActions<String>();
      final selectAll = actions.firstWhere((a) => a.id == 'select_all_nodes');
      final result = selectAll.execute(controller, null);

      expect(result, isTrue);
      expect(controller.selectedNodeIds, hasLength(3));
      expect(controller.selectedNodeIds, contains('node-1'));
      expect(controller.selectedNodeIds, contains('node-2'));
      expect(controller.selectedNodeIds, contains('node-3'));
    });
  });

  group('Invert Selection Action', () {
    test('action has correct metadata', () {
      final actions = DefaultNodeFlowActions.createDefaultActions<String>();
      final invert = actions.firstWhere((a) => a.id == 'invert_selection');

      expect(invert.id, equals('invert_selection'));
      expect(invert.label, equals('Invert Selection'));
      expect(invert.category, equals('Selection'));
    });

    test('canExecute returns false when no nodes exist', () {
      final controller = createTestController();
      final actions = DefaultNodeFlowActions.createDefaultActions<String>();
      final invert = actions.firstWhere((a) => a.id == 'invert_selection');

      expect(invert.canExecute(controller), isFalse);
    });

    test('canExecute returns true when nodes exist', () {
      final controller = createTestController();
      controller.addNode(createTestNode());

      final actions = DefaultNodeFlowActions.createDefaultActions<String>();
      final invert = actions.firstWhere((a) => a.id == 'invert_selection');

      expect(invert.canExecute(controller), isTrue);
    });

    test('execute inverts selection', () {
      final controller = createTestController();
      final node1 = createTestNode(id: 'node-1');
      final node2 = createTestNode(id: 'node-2');
      controller.addNode(node1);
      controller.addNode(node2);
      controller.selectNode('node-1');

      expect(controller.selectedNodeIds, contains('node-1'));
      expect(controller.selectedNodeIds, isNot(contains('node-2')));

      final actions = DefaultNodeFlowActions.createDefaultActions<String>();
      final invert = actions.firstWhere((a) => a.id == 'invert_selection');
      final result = invert.execute(controller, null);

      expect(result, isTrue);
      expect(controller.selectedNodeIds, isNot(contains('node-1')));
      expect(controller.selectedNodeIds, contains('node-2'));
    });
  });

  group('Clear Selection Action', () {
    test('action has correct metadata', () {
      final actions = DefaultNodeFlowActions.createDefaultActions<String>();
      final clear = actions.firstWhere((a) => a.id == 'clear_selection');

      expect(clear.id, equals('clear_selection'));
      expect(clear.label, equals('Clear Selection'));
      expect(clear.category, equals('Selection'));
    });

    test('canExecute returns false when nothing selected', () {
      final controller = createTestController();
      controller.addNode(createTestNode());

      final actions = DefaultNodeFlowActions.createDefaultActions<String>();
      final clear = actions.firstWhere((a) => a.id == 'clear_selection');

      expect(clear.canExecute(controller), isFalse);
    });

    test('canExecute returns true when nodes are selected', () {
      final controller = createTestController();
      final node = createTestNode();
      controller.addNode(node);
      controller.selectNode(node.id);

      final actions = DefaultNodeFlowActions.createDefaultActions<String>();
      final clear = actions.firstWhere((a) => a.id == 'clear_selection');

      expect(clear.canExecute(controller), isTrue);
    });

    test('execute clears selection', () {
      final controller = createTestController();
      final node = createTestNode();
      controller.addNode(node);
      controller.selectNode(node.id);

      expect(controller.selectedNodeIds, isNotEmpty);

      final actions = DefaultNodeFlowActions.createDefaultActions<String>();
      final clear = actions.firstWhere((a) => a.id == 'clear_selection');
      final result = clear.execute(controller, null);

      expect(result, isTrue);
      expect(controller.selectedNodeIds, isEmpty);
    });
  });

  // ===========================================================================
  // Editing Action Tests
  // ===========================================================================

  group('Delete Selected Action', () {
    test('action has correct metadata', () {
      final actions = DefaultNodeFlowActions.createDefaultActions<String>();
      final delete = actions.firstWhere((a) => a.id == 'delete_selected');

      expect(delete.id, equals('delete_selected'));
      expect(delete.label, equals('Delete'));
      expect(delete.category, equals('Edit'));
    });

    test('canExecute returns false when nothing selected', () {
      final controller = createTestController();
      controller.addNode(createTestNode());

      final actions = DefaultNodeFlowActions.createDefaultActions<String>();
      final delete = actions.firstWhere((a) => a.id == 'delete_selected');

      expect(delete.canExecute(controller), isFalse);
    });

    test('canExecute returns false when behavior disallows deletion', () {
      final controller = createTestController();
      final node = createTestNode();
      controller.addNode(node);
      controller.selectNode(node.id);
      controller.setBehavior(NodeFlowBehavior.preview);

      final actions = DefaultNodeFlowActions.createDefaultActions<String>();
      final delete = actions.firstWhere((a) => a.id == 'delete_selected');

      expect(delete.canExecute(controller), isFalse);
    });

    test(
      'canExecute returns true when selection exists and behavior allows',
      () {
        final controller = createTestController();
        final node = createTestNode();
        controller.addNode(node);
        controller.selectNode(node.id);

        final actions = DefaultNodeFlowActions.createDefaultActions<String>();
        final delete = actions.firstWhere((a) => a.id == 'delete_selected');

        expect(delete.canExecute(controller), isTrue);
      },
    );

    test('execute returns false when behavior disallows deletion', () {
      final controller = createTestController();
      final node = createTestNode();
      controller.addNode(node);
      controller.selectNode(node.id);
      controller.setBehavior(NodeFlowBehavior.preview);

      final actions = DefaultNodeFlowActions.createDefaultActions<String>();
      final delete = actions.firstWhere((a) => a.id == 'delete_selected');
      final result = delete.execute(controller, null);

      expect(result, isFalse);
    });

    test('execute returns true when behavior allows deletion', () {
      final controller = createTestController();
      final node = createTestNode();
      controller.addNode(node);
      controller.selectNode(node.id);

      final actions = DefaultNodeFlowActions.createDefaultActions<String>();
      final delete = actions.firstWhere((a) => a.id == 'delete_selected');
      final result = delete.execute(controller, null);

      expect(result, isTrue);
    });
  });

  group('Duplicate Selected Action', () {
    test('action has correct metadata', () {
      final actions = DefaultNodeFlowActions.createDefaultActions<String>();
      final duplicate = actions.firstWhere((a) => a.id == 'duplicate_selected');

      expect(duplicate.id, equals('duplicate_selected'));
      expect(duplicate.label, equals('Duplicate'));
      expect(duplicate.category, equals('Edit'));
    });

    test('canExecute returns false when nothing selected', () {
      final controller = createTestController();
      controller.addNode(createTestNode());

      final actions = DefaultNodeFlowActions.createDefaultActions<String>();
      final duplicate = actions.firstWhere((a) => a.id == 'duplicate_selected');

      expect(duplicate.canExecute(controller), isFalse);
    });

    test('canExecute returns true when nodes are selected', () {
      final controller = createTestController();
      final node = createTestNode();
      controller.addNode(node);
      controller.selectNode(node.id);

      final actions = DefaultNodeFlowActions.createDefaultActions<String>();
      final duplicate = actions.firstWhere((a) => a.id == 'duplicate_selected');

      expect(duplicate.canExecute(controller), isTrue);
    });

    test('execute duplicates selected nodes', () {
      final controller = createTestController();
      final node = createTestNode(id: 'original');
      controller.addNode(node);
      controller.selectNode(node.id);

      expect(controller.nodes.length, equals(1));

      final actions = DefaultNodeFlowActions.createDefaultActions<String>();
      final duplicate = actions.firstWhere((a) => a.id == 'duplicate_selected');
      final result = duplicate.execute(controller, null);

      expect(result, isTrue);
      expect(controller.nodes.length, equals(2));
    });
  });

  group('Cut Selected Action', () {
    test('action has correct metadata', () {
      final actions = DefaultNodeFlowActions.createDefaultActions<String>();
      final cut = actions.firstWhere((a) => a.id == 'cut_selected');

      expect(cut.id, equals('cut_selected'));
      expect(cut.label, equals('Cut'));
      expect(cut.category, equals('Edit'));
    });

    test('canExecute returns false when nothing selected', () {
      final controller = createTestController();
      controller.addNode(createTestNode());

      final actions = DefaultNodeFlowActions.createDefaultActions<String>();
      final cut = actions.firstWhere((a) => a.id == 'cut_selected');

      expect(cut.canExecute(controller), isFalse);
    });

    test('canExecute returns true when nodes are selected', () {
      final controller = createTestController();
      final node = createTestNode();
      controller.addNode(node);
      controller.selectNode(node.id);

      final actions = DefaultNodeFlowActions.createDefaultActions<String>();
      final cut = actions.firstWhere((a) => a.id == 'cut_selected');

      expect(cut.canExecute(controller), isTrue);
    });

    test('execute returns false (not yet implemented)', () {
      final controller = createTestController();
      final node = createTestNode();
      controller.addNode(node);
      controller.selectNode(node.id);

      final actions = DefaultNodeFlowActions.createDefaultActions<String>();
      final cut = actions.firstWhere((a) => a.id == 'cut_selected');
      final result = cut.execute(controller, null);

      // Currently returns false as clipboard not implemented
      expect(result, isFalse);
    });
  });

  group('Copy Selected Action', () {
    test('action has correct metadata', () {
      final actions = DefaultNodeFlowActions.createDefaultActions<String>();
      final copy = actions.firstWhere((a) => a.id == 'copy_selected');

      expect(copy.id, equals('copy_selected'));
      expect(copy.label, equals('Copy'));
      expect(copy.category, equals('Edit'));
    });

    test('canExecute returns false when nothing selected', () {
      final controller = createTestController();
      controller.addNode(createTestNode());

      final actions = DefaultNodeFlowActions.createDefaultActions<String>();
      final copy = actions.firstWhere((a) => a.id == 'copy_selected');

      expect(copy.canExecute(controller), isFalse);
    });

    test('execute returns false (not yet implemented)', () {
      final controller = createTestController();
      final node = createTestNode();
      controller.addNode(node);
      controller.selectNode(node.id);

      final actions = DefaultNodeFlowActions.createDefaultActions<String>();
      final copy = actions.firstWhere((a) => a.id == 'copy_selected');
      final result = copy.execute(controller, null);

      // Currently returns false as clipboard not implemented
      expect(result, isFalse);
    });
  });

  group('Paste Action', () {
    test('action has correct metadata', () {
      final actions = DefaultNodeFlowActions.createDefaultActions<String>();
      final paste = actions.firstWhere((a) => a.id == 'paste');

      expect(paste.id, equals('paste'));
      expect(paste.label, equals('Paste'));
      expect(paste.category, equals('Edit'));
    });

    test('canExecute returns true by default', () {
      final controller = createTestController();

      final actions = DefaultNodeFlowActions.createDefaultActions<String>();
      final paste = actions.firstWhere((a) => a.id == 'paste');

      // Default canExecute returns true
      expect(paste.canExecute(controller), isTrue);
    });

    test('execute returns false (not yet implemented)', () {
      final controller = createTestController();

      final actions = DefaultNodeFlowActions.createDefaultActions<String>();
      final paste = actions.firstWhere((a) => a.id == 'paste');
      final result = paste.execute(controller, null);

      // Currently returns false as clipboard not implemented
      expect(result, isFalse);
    });
  });

  // ===========================================================================
  // Navigation Action Tests
  // ===========================================================================

  group('Fit to View Action', () {
    test('action has correct metadata', () {
      final actions = DefaultNodeFlowActions.createDefaultActions<String>();
      final fitView = actions.firstWhere((a) => a.id == 'fit_to_view');

      expect(fitView.id, equals('fit_to_view'));
      expect(fitView.label, equals('Fit to View'));
      expect(fitView.category, equals('Navigation'));
    });

    test('canExecute returns false when no nodes exist', () {
      final controller = createTestController();

      final actions = DefaultNodeFlowActions.createDefaultActions<String>();
      final fitView = actions.firstWhere((a) => a.id == 'fit_to_view');

      expect(fitView.canExecute(controller), isFalse);
    });

    test('canExecute returns true when nodes exist', () {
      final controller = createTestController();
      controller.addNode(createTestNode());

      final actions = DefaultNodeFlowActions.createDefaultActions<String>();
      final fitView = actions.firstWhere((a) => a.id == 'fit_to_view');

      expect(fitView.canExecute(controller), isTrue);
    });

    test('execute returns true', () {
      final controller = createTestController();
      controller.addNode(createTestNode());
      // Set screen size for viewport calculations
      controller.setScreenSize(const Size(800, 600));

      final actions = DefaultNodeFlowActions.createDefaultActions<String>();
      final fitView = actions.firstWhere((a) => a.id == 'fit_to_view');
      final result = fitView.execute(controller, null);

      expect(result, isTrue);
    });
  });

  group('Fit Selected Action', () {
    test('action has correct metadata', () {
      final actions = DefaultNodeFlowActions.createDefaultActions<String>();
      final fitSelected = actions.firstWhere((a) => a.id == 'fit_selected');

      expect(fitSelected.id, equals('fit_selected'));
      expect(fitSelected.label, equals('Fit Selected to View'));
      expect(fitSelected.category, equals('Navigation'));
    });

    test('canExecute returns false when nothing selected', () {
      final controller = createTestController();
      controller.addNode(createTestNode());

      final actions = DefaultNodeFlowActions.createDefaultActions<String>();
      final fitSelected = actions.firstWhere((a) => a.id == 'fit_selected');

      expect(fitSelected.canExecute(controller), isFalse);
    });

    test('canExecute returns true when nodes are selected', () {
      final controller = createTestController();
      final node = createTestNode();
      controller.addNode(node);
      controller.selectNode(node.id);

      final actions = DefaultNodeFlowActions.createDefaultActions<String>();
      final fitSelected = actions.firstWhere((a) => a.id == 'fit_selected');

      expect(fitSelected.canExecute(controller), isTrue);
    });

    test('execute returns true', () {
      final controller = createTestController();
      final node = createTestNode();
      controller.addNode(node);
      controller.selectNode(node.id);
      controller.setScreenSize(const Size(800, 600));

      final actions = DefaultNodeFlowActions.createDefaultActions<String>();
      final fitSelected = actions.firstWhere((a) => a.id == 'fit_selected');
      final result = fitSelected.execute(controller, null);

      expect(result, isTrue);
    });
  });

  group('Reset Zoom Action', () {
    test('action has correct metadata', () {
      final actions = DefaultNodeFlowActions.createDefaultActions<String>();
      final resetZoom = actions.firstWhere((a) => a.id == 'reset_zoom');

      expect(resetZoom.id, equals('reset_zoom'));
      expect(resetZoom.label, equals('Reset Zoom'));
      expect(resetZoom.category, equals('Navigation'));
    });

    test('canExecute returns true by default', () {
      final controller = createTestController();

      final actions = DefaultNodeFlowActions.createDefaultActions<String>();
      final resetZoom = actions.firstWhere((a) => a.id == 'reset_zoom');

      expect(resetZoom.canExecute(controller), isTrue);
    });

    test('execute resets zoom to 1.0', () {
      final controller = createTestController();
      controller.setScreenSize(const Size(800, 600));
      controller.setViewport(const GraphViewport(x: 100, y: 100, zoom: 2.0));

      expect(controller.viewport.zoom, equals(2.0));

      final actions = DefaultNodeFlowActions.createDefaultActions<String>();
      final resetZoom = actions.firstWhere((a) => a.id == 'reset_zoom');
      final result = resetZoom.execute(controller, null);

      expect(result, isTrue);
      expect(controller.viewport.zoom, equals(1.0));
    });
  });

  group('Zoom In Action', () {
    test('action has correct metadata', () {
      final actions = DefaultNodeFlowActions.createDefaultActions<String>();
      final zoomIn = actions.firstWhere((a) => a.id == 'zoom_in');

      expect(zoomIn.id, equals('zoom_in'));
      expect(zoomIn.label, equals('Zoom In'));
      expect(zoomIn.category, equals('Navigation'));
    });

    test('execute increases zoom', () {
      final controller = createTestController();
      controller.setScreenSize(const Size(800, 600));
      final initialZoom = controller.viewport.zoom;

      final actions = DefaultNodeFlowActions.createDefaultActions<String>();
      final zoomIn = actions.firstWhere((a) => a.id == 'zoom_in');
      final result = zoomIn.execute(controller, null);

      expect(result, isTrue);
      expect(controller.viewport.zoom, greaterThan(initialZoom));
    });
  });

  group('Zoom Out Action', () {
    test('action has correct metadata', () {
      final actions = DefaultNodeFlowActions.createDefaultActions<String>();
      final zoomOut = actions.firstWhere((a) => a.id == 'zoom_out');

      expect(zoomOut.id, equals('zoom_out'));
      expect(zoomOut.label, equals('Zoom Out'));
      expect(zoomOut.category, equals('Navigation'));
    });

    test('execute decreases zoom', () {
      final controller = createTestController();
      controller.setScreenSize(const Size(800, 600));
      final initialZoom = controller.viewport.zoom;

      final actions = DefaultNodeFlowActions.createDefaultActions<String>();
      final zoomOut = actions.firstWhere((a) => a.id == 'zoom_out');
      final result = zoomOut.execute(controller, null);

      expect(result, isTrue);
      expect(controller.viewport.zoom, lessThan(initialZoom));
    });
  });

  // ===========================================================================
  // Arrangement Action Tests
  // ===========================================================================

  group('Bring to Front Action', () {
    test('action has correct metadata', () {
      final actions = DefaultNodeFlowActions.createDefaultActions<String>();
      final bringFront = actions.firstWhere((a) => a.id == 'bring_to_front');

      expect(bringFront.id, equals('bring_to_front'));
      expect(bringFront.label, equals('Bring to Front'));
      expect(bringFront.category, equals('Arrangement'));
    });

    test('canExecute returns false when nothing selected', () {
      final controller = createTestController();
      controller.addNode(createTestNode());

      final actions = DefaultNodeFlowActions.createDefaultActions<String>();
      final bringFront = actions.firstWhere((a) => a.id == 'bring_to_front');

      expect(bringFront.canExecute(controller), isFalse);
    });

    test('canExecute returns true when nodes are selected', () {
      final controller = createTestController();
      final node = createTestNode();
      controller.addNode(node);
      controller.selectNode(node.id);

      final actions = DefaultNodeFlowActions.createDefaultActions<String>();
      final bringFront = actions.firstWhere((a) => a.id == 'bring_to_front');

      expect(bringFront.canExecute(controller), isTrue);
    });

    test('execute brings selected node to front', () {
      final controller = createTestController();
      final node1 = createTestNode(id: 'node-1', zIndex: 0);
      final node2 = createTestNode(id: 'node-2', zIndex: 1);
      controller.addNode(node1);
      controller.addNode(node2);
      controller.selectNode('node-1');

      final actions = DefaultNodeFlowActions.createDefaultActions<String>();
      final bringFront = actions.firstWhere((a) => a.id == 'bring_to_front');
      final result = bringFront.execute(controller, null);

      expect(result, isTrue);
      expect(node1.zIndex.value, greaterThan(node2.zIndex.value));
    });
  });

  group('Send to Back Action', () {
    test('action has correct metadata', () {
      final actions = DefaultNodeFlowActions.createDefaultActions<String>();
      final sendBack = actions.firstWhere((a) => a.id == 'send_to_back');

      expect(sendBack.id, equals('send_to_back'));
      expect(sendBack.label, equals('Send to Back'));
      expect(sendBack.category, equals('Arrangement'));
    });

    test('execute sends selected node to back', () {
      final controller = createTestController();
      final node1 = createTestNode(id: 'node-1', zIndex: 1);
      final node2 = createTestNode(id: 'node-2', zIndex: 0);
      controller.addNode(node1);
      controller.addNode(node2);
      controller.selectNode('node-1');

      final actions = DefaultNodeFlowActions.createDefaultActions<String>();
      final sendBack = actions.firstWhere((a) => a.id == 'send_to_back');
      final result = sendBack.execute(controller, null);

      expect(result, isTrue);
      expect(node1.zIndex.value, lessThan(node2.zIndex.value));
    });
  });

  group('Bring Forward Action', () {
    test('action has correct metadata', () {
      final actions = DefaultNodeFlowActions.createDefaultActions<String>();
      final bringForward = actions.firstWhere((a) => a.id == 'bring_forward');

      expect(bringForward.id, equals('bring_forward'));
      expect(bringForward.label, equals('Bring Forward'));
      expect(bringForward.category, equals('Arrangement'));
    });

    test('canExecute returns false when nothing selected', () {
      final controller = createTestController();

      final actions = DefaultNodeFlowActions.createDefaultActions<String>();
      final bringForward = actions.firstWhere((a) => a.id == 'bring_forward');

      expect(bringForward.canExecute(controller), isFalse);
    });
  });

  group('Send Backward Action', () {
    test('action has correct metadata', () {
      final actions = DefaultNodeFlowActions.createDefaultActions<String>();
      final sendBackward = actions.firstWhere((a) => a.id == 'send_backward');

      expect(sendBackward.id, equals('send_backward'));
      expect(sendBackward.label, equals('Send Backward'));
      expect(sendBackward.category, equals('Arrangement'));
    });

    test('canExecute returns false when nothing selected', () {
      final controller = createTestController();

      final actions = DefaultNodeFlowActions.createDefaultActions<String>();
      final sendBackward = actions.firstWhere((a) => a.id == 'send_backward');

      expect(sendBackward.canExecute(controller), isFalse);
    });
  });

  // ===========================================================================
  // Alignment Action Tests
  // ===========================================================================

  group('Align Top Action', () {
    test('action has correct metadata', () {
      final actions = DefaultNodeFlowActions.createDefaultActions<String>();
      final alignTop = actions.firstWhere((a) => a.id == 'align_top');

      expect(alignTop.id, equals('align_top'));
      expect(alignTop.label, equals('Align Top'));
      expect(alignTop.category, equals('Alignment'));
    });

    test('canExecute returns false when less than 2 nodes selected', () {
      final controller = createTestController();
      final node = createTestNode();
      controller.addNode(node);
      controller.selectNode(node.id);

      final actions = DefaultNodeFlowActions.createDefaultActions<String>();
      final alignTop = actions.firstWhere((a) => a.id == 'align_top');

      expect(alignTop.canExecute(controller), isFalse);
    });

    test('canExecute returns true when 2 or more nodes selected', () {
      final controller = createTestController();
      final node1 = createTestNode(id: 'node-1');
      final node2 = createTestNode(id: 'node-2');
      controller.addNode(node1);
      controller.addNode(node2);
      controller.selectNodes(['node-1', 'node-2']);

      final actions = DefaultNodeFlowActions.createDefaultActions<String>();
      final alignTop = actions.firstWhere((a) => a.id == 'align_top');

      expect(alignTop.canExecute(controller), isTrue);
    });

    test('execute aligns nodes to top', () {
      final controller = createTestController();
      final node1 = createTestNode(
        id: 'node-1',
        position: const Offset(0, 100),
      );
      final node2 = createTestNode(
        id: 'node-2',
        position: const Offset(100, 0),
      );
      controller.addNode(node1);
      controller.addNode(node2);
      controller.selectNodes(['node-1', 'node-2']);

      final actions = DefaultNodeFlowActions.createDefaultActions<String>();
      final alignTop = actions.firstWhere((a) => a.id == 'align_top');
      final result = alignTop.execute(controller, null);

      expect(result, isTrue);
      // Both nodes should now have the same top Y position
      expect(node1.position.value.dy, equals(node2.position.value.dy));
    });
  });

  group('Align Bottom Action', () {
    test('action has correct metadata', () {
      final actions = DefaultNodeFlowActions.createDefaultActions<String>();
      final alignBottom = actions.firstWhere((a) => a.id == 'align_bottom');

      expect(alignBottom.id, equals('align_bottom'));
      expect(alignBottom.label, equals('Align Bottom'));
      expect(alignBottom.category, equals('Alignment'));
    });

    test('canExecute requires 2 or more nodes', () {
      final controller = createTestController();
      final node = createTestNode();
      controller.addNode(node);
      controller.selectNode(node.id);

      final actions = DefaultNodeFlowActions.createDefaultActions<String>();
      final alignBottom = actions.firstWhere((a) => a.id == 'align_bottom');

      expect(alignBottom.canExecute(controller), isFalse);
    });
  });

  group('Align Left Action', () {
    test('action has correct metadata', () {
      final actions = DefaultNodeFlowActions.createDefaultActions<String>();
      final alignLeft = actions.firstWhere((a) => a.id == 'align_left');

      expect(alignLeft.id, equals('align_left'));
      expect(alignLeft.label, equals('Align Left'));
      expect(alignLeft.category, equals('Alignment'));
    });
  });

  group('Align Right Action', () {
    test('action has correct metadata', () {
      final actions = DefaultNodeFlowActions.createDefaultActions<String>();
      final alignRight = actions.firstWhere((a) => a.id == 'align_right');

      expect(alignRight.id, equals('align_right'));
      expect(alignRight.label, equals('Align Right'));
      expect(alignRight.category, equals('Alignment'));
    });
  });

  group('Align Horizontal Center Action', () {
    test('action has correct metadata', () {
      final actions = DefaultNodeFlowActions.createDefaultActions<String>();
      final alignCenter = actions.firstWhere(
        (a) => a.id == 'align_horizontal_center',
      );

      expect(alignCenter.id, equals('align_horizontal_center'));
      expect(alignCenter.label, equals('Align Horizontal Center'));
      expect(alignCenter.category, equals('Alignment'));
    });
  });

  group('Align Vertical Center Action', () {
    test('action has correct metadata', () {
      final actions = DefaultNodeFlowActions.createDefaultActions<String>();
      final alignCenter = actions.firstWhere(
        (a) => a.id == 'align_vertical_center',
      );

      expect(alignCenter.id, equals('align_vertical_center'));
      expect(alignCenter.label, equals('Align Vertical Center'));
      expect(alignCenter.category, equals('Alignment'));
    });
  });

  // ===========================================================================
  // General Action Tests
  // ===========================================================================

  group('Cancel Operation Action', () {
    test('action has correct metadata', () {
      final actions = DefaultNodeFlowActions.createDefaultActions<String>();
      final cancel = actions.firstWhere((a) => a.id == 'cancel_operation');

      expect(cancel.id, equals('cancel_operation'));
      expect(cancel.label, equals('Cancel'));
      expect(cancel.category, equals('General'));
    });

    test('canExecute returns true by default', () {
      final controller = createTestController();

      final actions = DefaultNodeFlowActions.createDefaultActions<String>();
      final cancel = actions.firstWhere((a) => a.id == 'cancel_operation');

      expect(cancel.canExecute(controller), isTrue);
    });

    test('execute clears selection when no active operations', () {
      final controller = createTestController();
      final node = createTestNode();
      controller.addNode(node);
      controller.selectNode(node.id);

      expect(controller.selectedNodeIds, isNotEmpty);

      final actions = DefaultNodeFlowActions.createDefaultActions<String>();
      final cancel = actions.firstWhere((a) => a.id == 'cancel_operation');
      final result = cancel.execute(controller, null);

      expect(result, isTrue);
      expect(controller.selectedNodeIds, isEmpty);
    });
  });

  group('Toggle Minimap Action', () {
    test('action has correct metadata', () {
      final actions = DefaultNodeFlowActions.createDefaultActions<String>();
      final toggleMinimap = actions.firstWhere((a) => a.id == 'toggle_minimap');

      expect(toggleMinimap.id, equals('toggle_minimap'));
      expect(toggleMinimap.label, equals('Toggle Minimap'));
      expect(toggleMinimap.category, equals('Navigation'));
    });

    test('execute returns false when minimap extension not registered', () {
      final controller = createTestController(
        config: NodeFlowConfig(plugins: []),
      );

      final actions = DefaultNodeFlowActions.createDefaultActions<String>();
      final toggleMinimap = actions.firstWhere((a) => a.id == 'toggle_minimap');
      final result = toggleMinimap.execute(controller, null);

      expect(result, isFalse);
    });

    test('execute toggles minimap when extension registered', () {
      final controller = createTestController();

      // Add minimap extension
      final minimapPlugin = MinimapPlugin(visible: false);
      controller.addPlugin(minimapPlugin);

      expect(minimapPlugin.isVisible, isFalse);

      final actions = DefaultNodeFlowActions.createDefaultActions<String>();
      final toggleMinimap = actions.firstWhere((a) => a.id == 'toggle_minimap');
      final result = toggleMinimap.execute(controller, null);

      expect(result, isTrue);
      expect(minimapPlugin.isVisible, isTrue);
    });
  });

  group('Toggle Snapping Action', () {
    test('action has correct metadata', () {
      final actions = DefaultNodeFlowActions.createDefaultActions<String>();
      final toggleSnapping = actions.firstWhere(
        (a) => a.id == 'toggle_snapping',
      );

      expect(toggleSnapping.id, equals('toggle_snapping'));
      expect(toggleSnapping.label, equals('Toggle Snapping'));
      expect(toggleSnapping.category, equals('Edit'));
    });

    test('execute toggles SnapPlugin enabled state', () {
      // Create controller with SnapPlugin (disabled by default)
      final controller = createTestController(
        config: NodeFlowConfig(
          plugins: [
            SnapPlugin([GridSnapDelegate(gridSize: 20.0)]),
          ],
        ),
      );
      final snapExt = controller.snap;
      expect(snapExt, isNotNull);
      expect(snapExt!.enabled, isFalse);

      final actions = DefaultNodeFlowActions.createDefaultActions<String>();
      final toggleSnapping = actions.firstWhere(
        (a) => a.id == 'toggle_snapping',
      );
      final result = toggleSnapping.execute(controller, null);

      expect(result, isTrue);
      expect(snapExt.enabled, isTrue);

      // Toggle again
      toggleSnapping.execute(controller, null);
      expect(snapExt.enabled, isFalse);
    });
  });

  // ===========================================================================
  // NodeFlowShortcutManager Tests
  // ===========================================================================

  group('NodeFlowShortcutManager', () {
    test('creates with default shortcuts', () {
      final manager = NodeFlowShortcutManager<String>();

      expect(manager.shortcuts, isNotEmpty);
    });

    test('creates with custom shortcuts merged with defaults', () {
      final customKey = LogicalKeySet(
        LogicalKeyboardKey.keyQ,
        LogicalKeyboardKey.meta,
      );
      final manager = NodeFlowShortcutManager<String>(
        customShortcuts: {customKey: 'custom_action'},
      );

      expect(manager.shortcuts[customKey], equals('custom_action'));
      // Default shortcuts should still exist
      expect(manager.shortcuts.containsValue('select_all_nodes'), isTrue);
    });

    test('registerAction adds action', () {
      final manager = NodeFlowShortcutManager<String>();
      final actions = DefaultNodeFlowActions.createDefaultActions<String>();
      final action = actions.first;

      manager.registerAction(action);

      expect(manager.getAction(action.id), equals(action));
    });

    test('registerActions adds multiple actions', () {
      final manager = NodeFlowShortcutManager<String>();
      final actions = DefaultNodeFlowActions.createDefaultActions<String>();

      manager.registerActions(actions);

      for (final action in actions) {
        expect(manager.getAction(action.id), equals(action));
      }
    });

    test('getAction returns null for unknown action', () {
      final manager = NodeFlowShortcutManager<String>();

      expect(manager.getAction('unknown'), isNull);
    });

    test('getActionsByCategory groups actions correctly', () {
      final manager = NodeFlowShortcutManager<String>();
      manager.registerActions(
        DefaultNodeFlowActions.createDefaultActions<String>(),
      );

      final byCategory = manager.getActionsByCategory();

      expect(byCategory.containsKey('Selection'), isTrue);
      expect(byCategory.containsKey('Edit'), isTrue);
      expect(byCategory['Selection'], isNotEmpty);
    });

    test('searchActions finds matching actions', () {
      final manager = NodeFlowShortcutManager<String>();
      manager.registerActions(
        DefaultNodeFlowActions.createDefaultActions<String>(),
      );

      final results = manager.searchActions('select');

      expect(results, isNotEmpty);
      // Should find select_all_nodes and clear_selection at minimum
      expect(results.any((a) => a.id.contains('select')), isTrue);
    });

    test('searchActions is case insensitive', () {
      final manager = NodeFlowShortcutManager<String>();
      manager.registerActions(
        DefaultNodeFlowActions.createDefaultActions<String>(),
      );

      final resultsLower = manager.searchActions('select');
      final resultsUpper = manager.searchActions('SELECT');

      expect(resultsLower.length, equals(resultsUpper.length));
    });

    test('setShortcut adds new shortcut', () {
      final manager = NodeFlowShortcutManager<String>();
      final keySet = LogicalKeySet(
        LogicalKeyboardKey.keyT,
        LogicalKeyboardKey.meta,
      );

      manager.setShortcut(keySet, 'test_action');

      expect(manager.shortcuts[keySet], equals('test_action'));
    });

    test('removeShortcut removes shortcut', () {
      final manager = NodeFlowShortcutManager<String>();
      final keySet = LogicalKeySet(LogicalKeyboardKey.delete);

      // Default shortcuts should include delete
      expect(manager.shortcuts.containsKey(keySet), isTrue);

      manager.removeShortcut(keySet);

      expect(manager.shortcuts.containsKey(keySet), isFalse);
    });

    test('getShortcutForAction returns shortcut', () {
      final manager = NodeFlowShortcutManager<String>();

      final shortcut = manager.getShortcutForAction('select_all_nodes');

      expect(shortcut, isNotNull);
    });

    test('getShortcutForAction returns null for unknown action', () {
      final manager = NodeFlowShortcutManager<String>();

      final shortcut = manager.getShortcutForAction('unknown_action');

      expect(shortcut, isNull);
    });

    test('shortcuts getter returns unmodifiable map', () {
      final manager = NodeFlowShortcutManager<String>();

      final shortcuts = manager.shortcuts;

      expect(
        () => (shortcuts as Map)[LogicalKeySet(LogicalKeyboardKey.keyX)] = 'x',
        throwsUnsupportedError,
      );
    });

    test('keyMap is same as shortcuts', () {
      final manager = NodeFlowShortcutManager<String>();

      expect(manager.keyMap, equals(manager.shortcuts));
    });

    test('actions getter returns unmodifiable map', () {
      final manager = NodeFlowShortcutManager<String>();
      manager.registerActions(
        DefaultNodeFlowActions.createDefaultActions<String>(),
      );

      final actions = manager.actions;

      expect(actions, isNotEmpty);
    });
  });

  // ===========================================================================
  // Controller Integration Tests
  // ===========================================================================

  group('Controller Shortcuts Integration', () {
    test('controller initializes with shortcuts manager', () {
      final controller = createTestController();

      expect(controller.shortcuts, isNotNull);
    });

    test('controller shortcuts have default actions registered', () {
      final controller = createTestController();

      final selectAll = controller.shortcuts.getAction('select_all_nodes');
      expect(selectAll, isNotNull);
    });

    test('controller shortcuts can execute actions', () {
      final controller = createTestController();
      final node1 = createTestNode(id: 'node-1');
      final node2 = createTestNode(id: 'node-2');
      controller.addNode(node1);
      controller.addNode(node2);

      final selectAll = controller.shortcuts.getAction('select_all_nodes');
      expect(selectAll, isNotNull);

      final result = selectAll!.execute(controller, null);

      expect(result, isTrue);
      expect(controller.selectedNodeIds, hasLength(2));
    });
  });

  // ===========================================================================
  // Edge Cases
  // ===========================================================================

  group('Edge Cases', () {
    test('action execute works with null context', () {
      final controller = createTestController();
      controller.addNode(createTestNode());

      final actions = DefaultNodeFlowActions.createDefaultActions<String>();
      for (final action in actions) {
        // Execute should not throw with null context
        if (action.canExecute(controller)) {
          expect(() => action.execute(controller, null), returnsNormally);
        }
      }
    });

    test('alignment actions handle nodes with different sizes', () {
      final controller = createTestController();
      final node1 = createTestNode(
        id: 'node-1',
        position: const Offset(0, 0),
        size: const Size(100, 50),
      );
      final node2 = createTestNode(
        id: 'node-2',
        position: const Offset(200, 100),
        size: const Size(150, 75),
      );
      controller.addNode(node1);
      controller.addNode(node2);
      controller.selectNodes(['node-1', 'node-2']);

      final actions = DefaultNodeFlowActions.createDefaultActions<String>();
      final alignTop = actions.firstWhere((a) => a.id == 'align_top');
      final result = alignTop.execute(controller, null);

      expect(result, isTrue);
      expect(node1.position.value.dy, equals(node2.position.value.dy));
    });

    test('z-order actions work with single node', () {
      final controller = createTestController();
      final node = createTestNode(id: 'node-1', zIndex: 0);
      controller.addNode(node);
      controller.selectNode('node-1');

      final actions = DefaultNodeFlowActions.createDefaultActions<String>();
      final bringFront = actions.firstWhere((a) => a.id == 'bring_to_front');
      final result = bringFront.execute(controller, null);

      expect(result, isTrue);
      // Node should still be at front (z-index incremented)
      expect(node.zIndex.value, equals(1));
    });

    test('duplicate action works with multiple selected nodes', () {
      final controller = createTestController();
      final node1 = createTestNode(id: 'node-1');
      final node2 = createTestNode(id: 'node-2');
      controller.addNode(node1);
      controller.addNode(node2);
      controller.selectNodes(['node-1', 'node-2']);

      expect(controller.nodes.length, equals(2));

      final actions = DefaultNodeFlowActions.createDefaultActions<String>();
      final duplicate = actions.firstWhere((a) => a.id == 'duplicate_selected');
      duplicate.execute(controller, null);

      expect(controller.nodes.length, equals(4));
    });
  });
}
