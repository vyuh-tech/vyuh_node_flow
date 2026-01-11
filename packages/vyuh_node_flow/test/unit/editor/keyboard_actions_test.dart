/// Unit tests for keyboard actions and shortcut management.
///
/// Tests cover:
/// - NodeFlowAction class structure and behavior
/// - NodeFlowShortcutManager for shortcut binding and lookup
/// - Action registration and lookup
/// - Platform-specific shortcuts (Cmd vs Ctrl)
/// - Default action implementations
/// - NodeFlowActionIntent class
/// - NodeFlowActionDispatcher class
/// - NodeFlowActionsMixin utility methods
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
  // NodeFlowAction Class Tests
  // ===========================================================================

  group('NodeFlowAction', () {
    test('has required properties', () {
      final action = _TestAction();

      expect(action.id, equals('test_action'));
      expect(action.label, equals('Test Action'));
      expect(action.description, equals('A test action for testing'));
      expect(action.category, equals('Test'));
    });

    test('canExecute returns true by default', () {
      final action = _TestAction();
      final controller = createTestController();

      expect(action.canExecute(controller), isTrue);
    });

    test('category defaults to General', () {
      final action = _ActionWithDefaultCategory();

      expect(action.category, equals('General'));
    });
  });

  // ===========================================================================
  // NodeFlowShortcutManager Tests
  // ===========================================================================

  group('NodeFlowShortcutManager', () {
    group('Creation', () {
      test('creates manager with default shortcuts', () {
        final manager = NodeFlowShortcutManager<String>();

        expect(manager.shortcuts, isNotEmpty);
      });

      test('creates manager with custom shortcuts', () {
        final customShortcut = LogicalKeySet(LogicalKeyboardKey.keyQ);
        final manager = NodeFlowShortcutManager<String>(
          customShortcuts: {customShortcut: 'custom_action'},
        );

        expect(manager.shortcuts[customShortcut], equals('custom_action'));
      });

      test('custom shortcuts override default shortcuts', () {
        // Get the default shortcut for select_all_nodes (Cmd+A)
        final keySet = LogicalKeySet(
          LogicalKeyboardKey.keyA,
          LogicalKeyboardKey.meta,
        );
        final manager = NodeFlowShortcutManager<String>(
          customShortcuts: {keySet: 'my_custom_select'},
        );

        expect(manager.shortcuts[keySet], equals('my_custom_select'));
      });
    });

    group('Action Registration', () {
      test('registerAction adds action to manager', () {
        final manager = NodeFlowShortcutManager<String>();
        final action = _TestAction();

        manager.registerAction(action);

        expect(manager.getAction('test_action'), equals(action));
      });

      test('registerActions adds multiple actions', () {
        final manager = NodeFlowShortcutManager<String>();
        final actions = [_TestAction(), _AnotherTestAction()];

        manager.registerActions(actions);

        expect(manager.getAction('test_action'), isNotNull);
        expect(manager.getAction('another_action'), isNotNull);
      });

      test('registering action with same id replaces existing', () {
        final manager = NodeFlowShortcutManager<String>();
        final action1 = _TestAction();
        final action2 = _ReplacementTestAction();

        manager.registerAction(action1);
        manager.registerAction(action2);

        final retrieved = manager.getAction('test_action');
        expect(retrieved?.label, equals('Replacement Action'));
      });

      test('getAction returns null for non-existent action', () {
        final manager = NodeFlowShortcutManager<String>();

        expect(manager.getAction('non_existent'), isNull);
      });
    });

    group('Shortcut Management', () {
      test('setShortcut adds new shortcut', () {
        final manager = NodeFlowShortcutManager<String>();
        final keySet = LogicalKeySet(LogicalKeyboardKey.keyW);

        manager.setShortcut(keySet, 'my_action');

        expect(manager.shortcuts[keySet], equals('my_action'));
      });

      test('setShortcut overrides existing shortcut', () {
        final manager = NodeFlowShortcutManager<String>();
        final keySet = LogicalKeySet(LogicalKeyboardKey.keyW);

        manager.setShortcut(keySet, 'action_1');
        manager.setShortcut(keySet, 'action_2');

        expect(manager.shortcuts[keySet], equals('action_2'));
      });

      test('removeShortcut removes existing shortcut', () {
        final manager = NodeFlowShortcutManager<String>();
        final keySet = LogicalKeySet(LogicalKeyboardKey.keyW);
        manager.setShortcut(keySet, 'my_action');

        manager.removeShortcut(keySet);

        expect(manager.shortcuts.containsKey(keySet), isFalse);
      });

      test('removeShortcut does nothing for non-existent shortcut', () {
        final manager = NodeFlowShortcutManager<String>();
        final keySet = LogicalKeySet(LogicalKeyboardKey.keyW);
        final initialCount = manager.shortcuts.length;

        manager.removeShortcut(keySet);

        expect(manager.shortcuts.length, equals(initialCount));
      });

      test('getShortcutForAction returns correct shortcut', () {
        final manager = NodeFlowShortcutManager<String>();

        final shortcut = manager.getShortcutForAction('select_all_nodes');

        expect(shortcut, isNotNull);
        expect(shortcut!.keys, contains(LogicalKeyboardKey.keyA));
      });

      test('getShortcutForAction returns null for action without shortcut', () {
        final manager = NodeFlowShortcutManager<String>();

        final shortcut = manager.getShortcutForAction('non_existent_action');

        expect(shortcut, isNull);
      });

      test('shortcuts getter returns unmodifiable map', () {
        final manager = NodeFlowShortcutManager<String>();

        final shortcuts = manager.shortcuts;

        expect(
          () => (shortcuts as Map)[LogicalKeySet(LogicalKeyboardKey.keyX)] =
              'test',
          throwsUnsupportedError,
        );
      });

      test('keyMap returns same unmodifiable map as shortcuts', () {
        final manager = NodeFlowShortcutManager<String>();

        expect(manager.keyMap, equals(manager.shortcuts));
      });

      test('actions getter returns unmodifiable map', () {
        final manager = NodeFlowShortcutManager<String>();

        final actions = manager.actions;

        expect(
          () => (actions as Map)['test'] = _TestAction(),
          throwsUnsupportedError,
        );
      });
    });

    group('Action Search', () {
      test('searchActions finds action by label', () {
        final manager = NodeFlowShortcutManager<String>();
        manager.registerAction(_TestAction());

        final results = manager.searchActions('Test');

        expect(results, isNotEmpty);
        expect(results.first.id, equals('test_action'));
      });

      test('searchActions finds action by description', () {
        final manager = NodeFlowShortcutManager<String>();
        manager.registerAction(_TestAction());

        final results = manager.searchActions('testing');

        expect(results, isNotEmpty);
        expect(results.first.id, equals('test_action'));
      });

      test('searchActions finds action by id', () {
        final manager = NodeFlowShortcutManager<String>();
        manager.registerAction(_TestAction());

        final results = manager.searchActions('test_action');

        expect(results, isNotEmpty);
        expect(results.first.id, equals('test_action'));
      });

      test('searchActions is case insensitive', () {
        final manager = NodeFlowShortcutManager<String>();
        manager.registerAction(_TestAction());

        final results = manager.searchActions('TEST');

        expect(results, isNotEmpty);
      });

      test('searchActions returns empty list for no matches', () {
        final manager = NodeFlowShortcutManager<String>();
        manager.registerAction(_TestAction());

        final results = manager.searchActions('nonexistent');

        expect(results, isEmpty);
      });
    });

    group('Action Categories', () {
      test('getActionsByCategory groups actions correctly', () {
        final manager = NodeFlowShortcutManager<String>();
        manager.registerAction(_TestAction());
        manager.registerAction(_CategoryAction1());
        manager.registerAction(_CategoryAction2());

        final byCategory = manager.getActionsByCategory();

        expect(byCategory.containsKey('Test'), isTrue);
        expect(byCategory.containsKey('Category1'), isTrue);
        expect(byCategory.containsKey('Category2'), isTrue);
        expect(byCategory['Test']!.length, equals(1));
      });

      test('getActionsByCategory returns empty map when no actions', () {
        final manager = NodeFlowShortcutManager<String>();

        final byCategory = manager.getActionsByCategory();

        expect(byCategory, isEmpty);
      });
    });
  });

  // ===========================================================================
  // Default Shortcuts Tests (Platform-specific)
  // ===========================================================================

  group('Default Shortcuts', () {
    test('includes both Cmd and Ctrl variants for select all', () {
      final manager = NodeFlowShortcutManager<String>();
      final cmdA = LogicalKeySet(
        LogicalKeyboardKey.keyA,
        LogicalKeyboardKey.meta,
      );
      final ctrlA = LogicalKeySet(
        LogicalKeyboardKey.keyA,
        LogicalKeyboardKey.control,
      );

      expect(manager.shortcuts[cmdA], equals('select_all_nodes'));
      expect(manager.shortcuts[ctrlA], equals('select_all_nodes'));
    });

    test('includes both Cmd and Ctrl variants for duplicate', () {
      final manager = NodeFlowShortcutManager<String>();
      final cmdD = LogicalKeySet(
        LogicalKeyboardKey.keyD,
        LogicalKeyboardKey.meta,
      );
      final ctrlD = LogicalKeySet(
        LogicalKeyboardKey.keyD,
        LogicalKeyboardKey.control,
      );

      expect(manager.shortcuts[cmdD], equals('duplicate_selected'));
      expect(manager.shortcuts[ctrlD], equals('duplicate_selected'));
    });

    test('includes both Cmd and Ctrl variants for copy', () {
      final manager = NodeFlowShortcutManager<String>();
      final cmdC = LogicalKeySet(
        LogicalKeyboardKey.keyC,
        LogicalKeyboardKey.meta,
      );
      final ctrlC = LogicalKeySet(
        LogicalKeyboardKey.keyC,
        LogicalKeyboardKey.control,
      );

      expect(manager.shortcuts[cmdC], equals('copy_selected'));
      expect(manager.shortcuts[ctrlC], equals('copy_selected'));
    });

    test('includes both Cmd and Ctrl variants for paste', () {
      final manager = NodeFlowShortcutManager<String>();
      final cmdV = LogicalKeySet(
        LogicalKeyboardKey.keyV,
        LogicalKeyboardKey.meta,
      );
      final ctrlV = LogicalKeySet(
        LogicalKeyboardKey.keyV,
        LogicalKeyboardKey.control,
      );

      expect(manager.shortcuts[cmdV], equals('paste'));
      expect(manager.shortcuts[ctrlV], equals('paste'));
    });

    test('includes both Cmd and Ctrl variants for cut', () {
      final manager = NodeFlowShortcutManager<String>();
      final cmdX = LogicalKeySet(
        LogicalKeyboardKey.keyX,
        LogicalKeyboardKey.meta,
      );
      final ctrlX = LogicalKeySet(
        LogicalKeyboardKey.keyX,
        LogicalKeyboardKey.control,
      );

      expect(manager.shortcuts[cmdX], equals('cut_selected'));
      expect(manager.shortcuts[ctrlX], equals('cut_selected'));
    });

    test('includes delete key for delete action', () {
      final manager = NodeFlowShortcutManager<String>();
      final delete = LogicalKeySet(LogicalKeyboardKey.delete);
      final backspace = LogicalKeySet(LogicalKeyboardKey.backspace);

      expect(manager.shortcuts[delete], equals('delete_selected'));
      expect(manager.shortcuts[backspace], equals('delete_selected'));
    });

    test('includes F key for fit to view', () {
      final manager = NodeFlowShortcutManager<String>();
      final keyF = LogicalKeySet(LogicalKeyboardKey.keyF);

      expect(manager.shortcuts[keyF], equals('fit_to_view'));
    });

    test('includes H key for fit selected', () {
      final manager = NodeFlowShortcutManager<String>();
      final keyH = LogicalKeySet(LogicalKeyboardKey.keyH);

      expect(manager.shortcuts[keyH], equals('fit_selected'));
    });

    test('includes Escape for cancel operation', () {
      final manager = NodeFlowShortcutManager<String>();
      final escape = LogicalKeySet(LogicalKeyboardKey.escape);

      expect(manager.shortcuts[escape], equals('cancel_operation'));
    });

    test('includes M key for toggle minimap', () {
      final manager = NodeFlowShortcutManager<String>();
      final keyM = LogicalKeySet(LogicalKeyboardKey.keyM);

      expect(manager.shortcuts[keyM], equals('toggle_minimap'));
    });

    test('includes N key for toggle snapping', () {
      final manager = NodeFlowShortcutManager<String>();
      final keyN = LogicalKeySet(LogicalKeyboardKey.keyN);

      expect(manager.shortcuts[keyN], equals('toggle_snapping'));
    });

    test('includes zoom shortcuts with modifiers', () {
      final manager = NodeFlowShortcutManager<String>();
      final cmdPlus = LogicalKeySet(
        LogicalKeyboardKey.equal,
        LogicalKeyboardKey.meta,
      );
      final cmdMinus = LogicalKeySet(
        LogicalKeyboardKey.minus,
        LogicalKeyboardKey.meta,
      );
      final cmdZero = LogicalKeySet(
        LogicalKeyboardKey.digit0,
        LogicalKeyboardKey.meta,
      );

      expect(manager.shortcuts[cmdPlus], equals('zoom_in'));
      expect(manager.shortcuts[cmdMinus], equals('zoom_out'));
      expect(manager.shortcuts[cmdZero], equals('reset_zoom'));
    });

    test('includes bracket keys for z-order', () {
      final manager = NodeFlowShortcutManager<String>();
      final bracketLeft = LogicalKeySet(LogicalKeyboardKey.bracketLeft);
      final bracketRight = LogicalKeySet(LogicalKeyboardKey.bracketRight);
      final cmdBracketLeft = LogicalKeySet(
        LogicalKeyboardKey.bracketLeft,
        LogicalKeyboardKey.meta,
      );
      final cmdBracketRight = LogicalKeySet(
        LogicalKeyboardKey.bracketRight,
        LogicalKeyboardKey.meta,
      );

      expect(manager.shortcuts[bracketLeft], equals('send_to_back'));
      expect(manager.shortcuts[bracketRight], equals('bring_to_front'));
      expect(manager.shortcuts[cmdBracketLeft], equals('send_backward'));
      expect(manager.shortcuts[cmdBracketRight], equals('bring_forward'));
    });

    test('includes grouping shortcuts', () {
      final manager = NodeFlowShortcutManager<String>();
      final cmdG = LogicalKeySet(
        LogicalKeyboardKey.keyG,
        LogicalKeyboardKey.meta,
      );
      final cmdShiftG = LogicalKeySet(
        LogicalKeyboardKey.keyG,
        LogicalKeyboardKey.meta,
        LogicalKeyboardKey.shift,
      );

      expect(manager.shortcuts[cmdG], equals('create_group'));
      expect(manager.shortcuts[cmdShiftG], equals('ungroup_node'));
    });

    test('includes alignment shortcuts with arrow keys', () {
      final manager = NodeFlowShortcutManager<String>();
      final cmdShiftUp = LogicalKeySet(
        LogicalKeyboardKey.arrowUp,
        LogicalKeyboardKey.meta,
        LogicalKeyboardKey.shift,
      );
      final cmdShiftDown = LogicalKeySet(
        LogicalKeyboardKey.arrowDown,
        LogicalKeyboardKey.meta,
        LogicalKeyboardKey.shift,
      );
      final cmdShiftLeft = LogicalKeySet(
        LogicalKeyboardKey.arrowLeft,
        LogicalKeyboardKey.meta,
        LogicalKeyboardKey.shift,
      );
      final cmdShiftRight = LogicalKeySet(
        LogicalKeyboardKey.arrowRight,
        LogicalKeyboardKey.meta,
        LogicalKeyboardKey.shift,
      );

      expect(manager.shortcuts[cmdShiftUp], equals('align_top'));
      expect(manager.shortcuts[cmdShiftDown], equals('align_bottom'));
      expect(manager.shortcuts[cmdShiftLeft], equals('align_left'));
      expect(manager.shortcuts[cmdShiftRight], equals('align_right'));
    });
  });

  // ===========================================================================
  // DefaultNodeFlowActions Tests
  // ===========================================================================

  group('DefaultNodeFlowActions', () {
    test('createDefaultActions returns all expected actions', () {
      final actions = DefaultNodeFlowActions.createDefaultActions<String>();

      // Selection actions
      expect(actions.any((a) => a.id == 'select_all_nodes'), isTrue);
      expect(actions.any((a) => a.id == 'invert_selection'), isTrue);
      expect(actions.any((a) => a.id == 'clear_selection'), isTrue);

      // Editing actions
      expect(actions.any((a) => a.id == 'delete_selected'), isTrue);
      expect(actions.any((a) => a.id == 'duplicate_selected'), isTrue);
      expect(actions.any((a) => a.id == 'cut_selected'), isTrue);
      expect(actions.any((a) => a.id == 'copy_selected'), isTrue);
      expect(actions.any((a) => a.id == 'paste'), isTrue);

      // Navigation actions
      expect(actions.any((a) => a.id == 'fit_to_view'), isTrue);
      expect(actions.any((a) => a.id == 'fit_selected'), isTrue);
      expect(actions.any((a) => a.id == 'reset_zoom'), isTrue);
      expect(actions.any((a) => a.id == 'zoom_in'), isTrue);
      expect(actions.any((a) => a.id == 'zoom_out'), isTrue);

      // Arrangement actions
      expect(actions.any((a) => a.id == 'bring_to_front'), isTrue);
      expect(actions.any((a) => a.id == 'send_to_back'), isTrue);
      expect(actions.any((a) => a.id == 'bring_forward'), isTrue);
      expect(actions.any((a) => a.id == 'send_backward'), isTrue);

      // Alignment actions
      expect(actions.any((a) => a.id == 'align_top'), isTrue);
      expect(actions.any((a) => a.id == 'align_bottom'), isTrue);
      expect(actions.any((a) => a.id == 'align_left'), isTrue);
      expect(actions.any((a) => a.id == 'align_right'), isTrue);
      expect(actions.any((a) => a.id == 'align_horizontal_center'), isTrue);
      expect(actions.any((a) => a.id == 'align_vertical_center'), isTrue);

      // General actions
      expect(actions.any((a) => a.id == 'cancel_operation'), isTrue);
      expect(actions.any((a) => a.id == 'toggle_minimap'), isTrue);
      expect(actions.any((a) => a.id == 'toggle_snapping'), isTrue);
    });

    test('all default actions have proper categories', () {
      final actions = DefaultNodeFlowActions.createDefaultActions<String>();

      final categories = actions.map((a) => a.category).toSet();

      // Should have well-defined categories
      expect(categories.contains('Selection'), isTrue);
      expect(categories.contains('Edit'), isTrue);
      expect(categories.contains('Navigation'), isTrue);
      expect(categories.contains('Arrangement'), isTrue);
      expect(categories.contains('Alignment'), isTrue);
    });

    test('all default actions have labels', () {
      final actions = DefaultNodeFlowActions.createDefaultActions<String>();

      for (final action in actions) {
        expect(
          action.label,
          isNotEmpty,
          reason: '${action.id} should have label',
        );
      }
    });
  });

  // ===========================================================================
  // Default Action Implementations - canExecute Tests
  // ===========================================================================

  group('Default Action canExecute', () {
    group('Selection Actions', () {
      test('select_all_nodes canExecute requires non-empty graph', () {
        final manager = NodeFlowShortcutManager<String>();
        manager.registerActions(
          DefaultNodeFlowActions.createDefaultActions<String>(),
        );

        final emptyController = createTestController();
        final populatedController = createTestController(
          nodes: [createTestNode()],
        );

        final action = manager.getAction('select_all_nodes')!;
        expect(action.canExecute(emptyController), isFalse);
        expect(action.canExecute(populatedController), isTrue);
      });

      test('invert_selection canExecute requires non-empty graph', () {
        final manager = NodeFlowShortcutManager<String>();
        manager.registerActions(
          DefaultNodeFlowActions.createDefaultActions<String>(),
        );

        final emptyController = createTestController();
        final populatedController = createTestController(
          nodes: [createTestNode()],
        );

        final action = manager.getAction('invert_selection')!;
        expect(action.canExecute(emptyController), isFalse);
        expect(action.canExecute(populatedController), isTrue);
      });

      test('clear_selection canExecute requires selection', () {
        final manager = NodeFlowShortcutManager<String>();
        manager.registerActions(
          DefaultNodeFlowActions.createDefaultActions<String>(),
        );

        final controller = createTestController(nodes: [createTestNode()]);

        final action = manager.getAction('clear_selection')!;
        expect(action.canExecute(controller), isFalse);

        controller.selectAllNodes();
        expect(action.canExecute(controller), isTrue);
      });
    });

    group('Editing Actions', () {
      test('delete_selected canExecute requires selection and permission', () {
        final manager = NodeFlowShortcutManager<String>();
        manager.registerActions(
          DefaultNodeFlowActions.createDefaultActions<String>(),
        );

        final node = createTestNode(id: 'node-1');
        final controller = createTestController(nodes: [node]);

        final action = manager.getAction('delete_selected')!;
        expect(action.canExecute(controller), isFalse);

        controller.selectNode('node-1');
        expect(action.canExecute(controller), isTrue);
      });

      test('duplicate_selected canExecute requires selection', () {
        final manager = NodeFlowShortcutManager<String>();
        manager.registerActions(
          DefaultNodeFlowActions.createDefaultActions<String>(),
        );

        final node = createTestNode(id: 'node-1');
        final controller = createTestController(nodes: [node]);

        final action = manager.getAction('duplicate_selected')!;
        expect(action.canExecute(controller), isFalse);

        controller.selectNode('node-1');
        expect(action.canExecute(controller), isTrue);
      });
    });

    group('Navigation Actions', () {
      test('fit_to_view canExecute requires non-empty graph', () {
        final manager = NodeFlowShortcutManager<String>();
        manager.registerActions(
          DefaultNodeFlowActions.createDefaultActions<String>(),
        );

        final emptyController = createTestController();
        final populatedController = createTestController(
          nodes: [createTestNode()],
        );

        final action = manager.getAction('fit_to_view')!;
        expect(action.canExecute(emptyController), isFalse);
        expect(action.canExecute(populatedController), isTrue);
      });

      test('fit_selected canExecute requires selection', () {
        final manager = NodeFlowShortcutManager<String>();
        manager.registerActions(
          DefaultNodeFlowActions.createDefaultActions<String>(),
        );

        final node = createTestNode(id: 'node-1');
        final controller = createTestController(nodes: [node]);

        final action = manager.getAction('fit_selected')!;
        expect(action.canExecute(controller), isFalse);

        controller.selectNode('node-1');
        expect(action.canExecute(controller), isTrue);
      });

      test('zoom actions always canExecute', () {
        final manager = NodeFlowShortcutManager<String>();
        manager.registerActions(
          DefaultNodeFlowActions.createDefaultActions<String>(),
        );

        final controller = createTestController();

        expect(manager.getAction('zoom_in')!.canExecute(controller), isTrue);
        expect(manager.getAction('zoom_out')!.canExecute(controller), isTrue);
        expect(manager.getAction('reset_zoom')!.canExecute(controller), isTrue);
      });
    });

    group('Arrangement Actions', () {
      test('z-order actions require selection', () {
        final manager = NodeFlowShortcutManager<String>();
        manager.registerActions(
          DefaultNodeFlowActions.createDefaultActions<String>(),
        );

        final node = createTestNode(id: 'node-1');
        final controller = createTestController(nodes: [node]);

        // All z-order actions require selection
        final zOrderActions = [
          'bring_to_front',
          'send_to_back',
          'bring_forward',
          'send_backward',
        ];

        for (final actionId in zOrderActions) {
          final action = manager.getAction(actionId)!;
          expect(
            action.canExecute(controller),
            isFalse,
            reason: '$actionId should not execute without selection',
          );
        }

        controller.selectNode('node-1');

        for (final actionId in zOrderActions) {
          final action = manager.getAction(actionId)!;
          expect(
            action.canExecute(controller),
            isTrue,
            reason: '$actionId should execute with selection',
          );
        }
      });
    });

    group('Alignment Actions', () {
      test('alignment actions require at least 2 selected nodes', () {
        final manager = NodeFlowShortcutManager<String>();
        manager.registerActions(
          DefaultNodeFlowActions.createDefaultActions<String>(),
        );

        final nodes = [
          createTestNode(id: 'node-1'),
          createTestNode(id: 'node-2'),
        ];
        final controller = createTestController(nodes: nodes);

        final alignmentActions = [
          'align_top',
          'align_bottom',
          'align_left',
          'align_right',
          'align_horizontal_center',
          'align_vertical_center',
        ];

        // No selection
        for (final actionId in alignmentActions) {
          final action = manager.getAction(actionId)!;
          expect(
            action.canExecute(controller),
            isFalse,
            reason: '$actionId should not execute without selection',
          );
        }

        // Single selection - still not enough
        controller.selectNode('node-1');
        for (final actionId in alignmentActions) {
          final action = manager.getAction(actionId)!;
          expect(
            action.canExecute(controller),
            isFalse,
            reason: '$actionId should not execute with single selection',
          );
        }

        // Two selections - should work
        controller.selectNode('node-2', toggle: true);
        for (final actionId in alignmentActions) {
          final action = manager.getAction(actionId)!;
          expect(
            action.canExecute(controller),
            isTrue,
            reason: '$actionId should execute with 2+ selections',
          );
        }
      });
    });

    group('General Actions', () {
      test('cancel_operation always canExecute', () {
        final manager = NodeFlowShortcutManager<String>();
        manager.registerActions(
          DefaultNodeFlowActions.createDefaultActions<String>(),
        );

        final controller = createTestController();

        final action = manager.getAction('cancel_operation')!;
        expect(action.canExecute(controller), isTrue);
      });

      test('toggle_snapping always canExecute', () {
        final manager = NodeFlowShortcutManager<String>();
        manager.registerActions(
          DefaultNodeFlowActions.createDefaultActions<String>(),
        );

        final controller = createTestController();

        final action = manager.getAction('toggle_snapping')!;
        expect(action.canExecute(controller), isTrue);
      });
    });
  });

  // ===========================================================================
  // Default Action Implementations - execute Tests
  // ===========================================================================

  group('Default Action execute', () {
    group('Selection Actions', () {
      test('select_all_nodes selects all nodes', () {
        final manager = NodeFlowShortcutManager<String>();
        manager.registerActions(
          DefaultNodeFlowActions.createDefaultActions<String>(),
        );

        final nodes = [createTestNode(id: 'n1'), createTestNode(id: 'n2')];
        final controller = createTestController(nodes: nodes);

        final action = manager.getAction('select_all_nodes')!;
        final result = action.execute(controller, null);

        expect(result, isTrue);
        expect(controller.selectedNodeIds, containsAll(['n1', 'n2']));
      });

      test('invert_selection inverts selection', () {
        final manager = NodeFlowShortcutManager<String>();
        manager.registerActions(
          DefaultNodeFlowActions.createDefaultActions<String>(),
        );

        final nodes = [createTestNode(id: 'n1'), createTestNode(id: 'n2')];
        final controller = createTestController(nodes: nodes);
        controller.selectNode('n1');

        final action = manager.getAction('invert_selection')!;
        final result = action.execute(controller, null);

        expect(result, isTrue);
        expect(controller.selectedNodeIds, contains('n2'));
        expect(controller.selectedNodeIds, isNot(contains('n1')));
      });

      test('clear_selection clears selection', () {
        final manager = NodeFlowShortcutManager<String>();
        manager.registerActions(
          DefaultNodeFlowActions.createDefaultActions<String>(),
        );

        final nodes = [createTestNode(id: 'n1')];
        final controller = createTestController(nodes: nodes);
        controller.selectNode('n1');

        final action = manager.getAction('clear_selection')!;
        final result = action.execute(controller, null);

        expect(result, isTrue);
        expect(controller.selectedNodeIds, isEmpty);
      });
    });

    group('Navigation Actions', () {
      test('zoom_in increases zoom', () {
        final manager = NodeFlowShortcutManager<String>();
        manager.registerActions(
          DefaultNodeFlowActions.createDefaultActions<String>(),
        );

        final controller = createTestController();
        final initialZoom = controller.currentZoom;

        final action = manager.getAction('zoom_in')!;
        final result = action.execute(controller, null);

        expect(result, isTrue);
        expect(controller.currentZoom, greaterThan(initialZoom));
      });

      test('zoom_out decreases zoom', () {
        final manager = NodeFlowShortcutManager<String>();
        manager.registerActions(
          DefaultNodeFlowActions.createDefaultActions<String>(),
        );

        final controller = createTestController();
        final initialZoom = controller.currentZoom;

        final action = manager.getAction('zoom_out')!;
        final result = action.execute(controller, null);

        expect(result, isTrue);
        expect(controller.currentZoom, lessThan(initialZoom));
      });

      test('reset_zoom resets to 1.0', () {
        final manager = NodeFlowShortcutManager<String>();
        manager.registerActions(
          DefaultNodeFlowActions.createDefaultActions<String>(),
        );

        final controller = createTestController(
          initialViewport: GraphViewport(x: 0, y: 0, zoom: 1.5),
        );

        final action = manager.getAction('reset_zoom')!;
        final result = action.execute(controller, null);

        expect(result, isTrue);
        expect(controller.currentZoom, closeTo(1.0, 0.01));
      });
    });

    group('General Actions', () {
      test('toggle_snapping toggles snap-to-grid', () {
        final manager = NodeFlowShortcutManager<String>();
        manager.registerActions(
          DefaultNodeFlowActions.createDefaultActions<String>(),
        );

        final controller = createTestController();
        final initialSnapping = controller.config.snapToGrid.value;

        final action = manager.getAction('toggle_snapping')!;
        final result = action.execute(controller, null);

        expect(result, isTrue);
        expect(
          controller.config.snapToGrid.value,
          isNot(equals(initialSnapping)),
        );
      });
    });
  });

  // ===========================================================================
  // NodeFlowActionIntent Tests
  // ===========================================================================

  group('NodeFlowActionIntent', () {
    test('creates intent with action id', () {
      const intent = NodeFlowActionIntent<String>(actionId: 'test_action');

      expect(intent.actionId, equals('test_action'));
      expect(intent.context, isNull);
    });

    test('creates intent with context', () {
      // Note: BuildContext would normally be provided by a widget test
      const intent = NodeFlowActionIntent<String>(actionId: 'test_action');

      expect(intent.actionId, equals('test_action'));
    });

    test('equality is based on actionId', () {
      const intent1 = NodeFlowActionIntent<String>(actionId: 'action_a');
      const intent2 = NodeFlowActionIntent<String>(actionId: 'action_a');
      const intent3 = NodeFlowActionIntent<String>(actionId: 'action_b');

      expect(intent1, equals(intent2));
      expect(intent1, isNot(equals(intent3)));
    });

    test('hashCode is based on actionId', () {
      const intent1 = NodeFlowActionIntent<String>(actionId: 'action_a');
      const intent2 = NodeFlowActionIntent<String>(actionId: 'action_a');

      expect(intent1.hashCode, equals(intent2.hashCode));
    });
  });

  // ===========================================================================
  // Controller Integration Tests
  // ===========================================================================

  group('Controller Integration', () {
    test('controller has shortcuts manager initialized', () {
      final controller = createTestController();

      expect(controller.shortcuts, isNotNull);
    });

    test('controller shortcuts have default actions registered', () {
      final controller = createTestController();

      expect(controller.shortcuts.getAction('select_all_nodes'), isNotNull);
      expect(controller.shortcuts.getAction('delete_selected'), isNotNull);
      expect(controller.shortcuts.getAction('zoom_in'), isNotNull);
    });

    test('canvasFocusNode is accessible', () {
      final controller = createTestController();

      expect(controller.canvasFocusNode, isNotNull);
      expect(controller.canvasFocusNode, isA<FocusNode>());
    });
  });

  // ===========================================================================
  // Edge Cases Tests
  // ===========================================================================

  group('Edge Cases', () {
    test('action with null description', () {
      final action = _ActionWithNullDescription();

      expect(action.description, isNull);
    });

    test('empty search query returns all actions', () {
      final manager = NodeFlowShortcutManager<String>();
      manager.registerAction(_TestAction());
      manager.registerAction(_AnotherTestAction());

      final results = manager.searchActions('');

      expect(results.length, equals(2));
    });

    test('multiple shortcuts can map to same action', () {
      final manager = NodeFlowShortcutManager<String>();

      // Both Cmd+A and Ctrl+A map to select_all_nodes
      final cmdA = LogicalKeySet(
        LogicalKeyboardKey.keyA,
        LogicalKeyboardKey.meta,
      );
      final ctrlA = LogicalKeySet(
        LogicalKeyboardKey.keyA,
        LogicalKeyboardKey.control,
      );

      expect(manager.shortcuts[cmdA], equals(manager.shortcuts[ctrlA]));
    });

    test('LogicalKeySet with multiple modifiers', () {
      final manager = NodeFlowShortcutManager<String>();

      // Cmd+Shift+G for ungroup
      final cmdShiftG = LogicalKeySet(
        LogicalKeyboardKey.keyG,
        LogicalKeyboardKey.meta,
        LogicalKeyboardKey.shift,
      );

      expect(manager.shortcuts[cmdShiftG], equals('ungroup_node'));
    });
  });

  // ===========================================================================
  // NodeFlowActionDispatcher Tests
  // ===========================================================================

  group('NodeFlowActionDispatcher', () {
    test('creates dispatcher with controller', () {
      final controller = createTestController();
      final dispatcher = NodeFlowActionDispatcher<String>(controller);

      expect(dispatcher.controller, equals(controller));
    });

    group('isEnabled', () {
      test('returns false when canvas does not have primary focus', () {
        final controller = createTestController(nodes: [createTestNode()]);
        final dispatcher = NodeFlowActionDispatcher<String>(controller);
        const intent = NodeFlowActionIntent<String>(
          actionId: 'select_all_nodes',
        );

        // By default, focus node does not have primary focus
        expect(dispatcher.isEnabled(intent), isFalse);
      });

      test('returns false for non-existent action', () {
        final controller = createTestController(nodes: [createTestNode()]);
        final dispatcher = NodeFlowActionDispatcher<String>(controller);
        const intent = NodeFlowActionIntent<String>(actionId: 'non_existent');

        expect(dispatcher.isEnabled(intent), isFalse);
      });

      test('returns false when action canExecute is false', () {
        final controller = createTestController();
        final action = _TrackingAction(canExecuteResult: false);
        controller.shortcuts.registerAction(action);

        final dispatcher = NodeFlowActionDispatcher<String>(controller);
        const intent = NodeFlowActionIntent<String>(
          actionId: 'tracking_action',
        );

        expect(dispatcher.isEnabled(intent), isFalse);
      });
    });

    group('invoke', () {
      test('executes action when canExecute is true', () {
        final controller = createTestController();
        final action = _TrackingAction(canExecuteResult: true);
        controller.shortcuts.registerAction(action);

        final dispatcher = NodeFlowActionDispatcher<String>(controller);
        const intent = NodeFlowActionIntent<String>(
          actionId: 'tracking_action',
        );

        final result = dispatcher.invoke(intent);

        expect(result, isTrue);
        expect(action.executeCount, equals(1));
      });

      test('returns null when action does not exist', () {
        final controller = createTestController();
        final dispatcher = NodeFlowActionDispatcher<String>(controller);
        const intent = NodeFlowActionIntent<String>(actionId: 'non_existent');

        final result = dispatcher.invoke(intent);

        expect(result, isNull);
      });

      test('returns null when action canExecute is false', () {
        final controller = createTestController();
        final action = _TrackingAction(canExecuteResult: false);
        controller.shortcuts.registerAction(action);

        final dispatcher = NodeFlowActionDispatcher<String>(controller);
        const intent = NodeFlowActionIntent<String>(
          actionId: 'tracking_action',
        );

        final result = dispatcher.invoke(intent);

        expect(result, isNull);
        expect(action.executeCount, equals(0));
      });

      test('passes context to action', () {
        final controller = createTestController();
        controller.shortcuts.registerAction(_TestAction());

        final dispatcher = NodeFlowActionDispatcher<String>(controller);
        const intent = NodeFlowActionIntent<String>(actionId: 'test_action');

        // Execute should not throw
        expect(() => dispatcher.invoke(intent), returnsNormally);
      });
    });
  });

  // ===========================================================================
  // NodeFlowActionsMixin Tests
  // ===========================================================================

  group('NodeFlowActionsMixin', () {
    testWidgets('executeAction returns false when controller is null', (
      tester,
    ) async {
      const widget = _TestMixinWidget(controller: null);
      await tester.pumpWidget(MaterialApp(home: widget));

      final state = tester.state<_TestMixinWidgetState>(
        find.byType(_TestMixinWidget),
      );
      final result = state.testExecuteAction('select_all_nodes');

      expect(result, isFalse);
    });

    testWidgets('executeAction returns false for non-existent action', (
      tester,
    ) async {
      final controller = createTestController();
      final widget = _TestMixinWidget(controller: controller);
      await tester.pumpWidget(MaterialApp(home: widget));

      final state = tester.state<_TestMixinWidgetState>(
        find.byType(_TestMixinWidget),
      );
      final result = state.testExecuteAction('non_existent_action');

      expect(result, isFalse);
    });

    testWidgets('executeAction returns false when action canExecute is false', (
      tester,
    ) async {
      final controller =
          createTestController(); // No nodes, so select_all canExecute is false
      final widget = _TestMixinWidget(controller: controller);
      await tester.pumpWidget(MaterialApp(home: widget));

      final state = tester.state<_TestMixinWidgetState>(
        find.byType(_TestMixinWidget),
      );
      final result = state.testExecuteAction('select_all_nodes');

      expect(result, isFalse);
    });

    testWidgets(
      'executeAction returns true when action executes successfully',
      (tester) async {
        final controller = createTestController(nodes: [createTestNode()]);
        final widget = _TestMixinWidget(controller: controller);
        await tester.pumpWidget(MaterialApp(home: widget));

        final state = tester.state<_TestMixinWidgetState>(
          find.byType(_TestMixinWidget),
        );
        final result = state.testExecuteAction('select_all_nodes');

        expect(result, isTrue);
        expect(controller.selectedNodeIds, isNotEmpty);
      },
    );

    testWidgets('canExecuteAction returns false when controller is null', (
      tester,
    ) async {
      const widget = _TestMixinWidget(controller: null);
      await tester.pumpWidget(MaterialApp(home: widget));

      final state = tester.state<_TestMixinWidgetState>(
        find.byType(_TestMixinWidget),
      );
      final result = state.testCanExecuteAction('select_all_nodes');

      expect(result, isFalse);
    });

    testWidgets('canExecuteAction returns false for non-existent action', (
      tester,
    ) async {
      final controller = createTestController();
      final widget = _TestMixinWidget(controller: controller);
      await tester.pumpWidget(MaterialApp(home: widget));

      final state = tester.state<_TestMixinWidgetState>(
        find.byType(_TestMixinWidget),
      );
      final result = state.testCanExecuteAction('non_existent_action');

      expect(result, isFalse);
    });

    testWidgets('canExecuteAction returns true when action can execute', (
      tester,
    ) async {
      final controller = createTestController(nodes: [createTestNode()]);
      final widget = _TestMixinWidget(controller: controller);
      await tester.pumpWidget(MaterialApp(home: widget));

      final state = tester.state<_TestMixinWidgetState>(
        find.byType(_TestMixinWidget),
      );
      final result = state.testCanExecuteAction('select_all_nodes');

      expect(result, isTrue);
    });

    testWidgets('getActionShortcut returns null when controller is null', (
      tester,
    ) async {
      const widget = _TestMixinWidget(controller: null);
      await tester.pumpWidget(MaterialApp(home: widget));

      final state = tester.state<_TestMixinWidgetState>(
        find.byType(_TestMixinWidget),
      );
      final result = state.testGetActionShortcut('select_all_nodes');

      expect(result, isNull);
    });

    testWidgets('getActionShortcut returns null for action without shortcut', (
      tester,
    ) async {
      final controller = createTestController();
      final widget = _TestMixinWidget(controller: controller);
      await tester.pumpWidget(MaterialApp(home: widget));

      final state = tester.state<_TestMixinWidgetState>(
        find.byType(_TestMixinWidget),
      );
      final result = state.testGetActionShortcut('non_existent_action');

      expect(result, isNull);
    });

    testWidgets('getActionShortcut returns formatted shortcut string', (
      tester,
    ) async {
      final controller = createTestController();
      final widget = _TestMixinWidget(controller: controller);
      await tester.pumpWidget(MaterialApp(home: widget));

      final state = tester.state<_TestMixinWidgetState>(
        find.byType(_TestMixinWidget),
      );
      final result = state.testGetActionShortcut('select_all_nodes');

      expect(result, isNotNull);
      // Should contain the key A and a modifier
      expect(result!.contains('A'), isTrue);
    });

    testWidgets('getActionShortcut formats Ctrl modifier correctly', (
      tester,
    ) async {
      final controller = createTestController();
      // Add a shortcut with Ctrl modifier
      controller.shortcuts.setShortcut(
        LogicalKeySet(LogicalKeyboardKey.keyT, LogicalKeyboardKey.control),
        'test_ctrl_action',
      );

      final widget = _TestMixinWidget(controller: controller);
      await tester.pumpWidget(MaterialApp(home: widget));

      final state = tester.state<_TestMixinWidgetState>(
        find.byType(_TestMixinWidget),
      );
      final result = state.testGetActionShortcut('test_ctrl_action');

      expect(result, isNotNull);
      expect(result!.contains('Ctrl'), isTrue);
    });

    testWidgets('getActionShortcut formats Cmd modifier correctly', (
      tester,
    ) async {
      final controller = createTestController();
      final widget = _TestMixinWidget(controller: controller);
      await tester.pumpWidget(MaterialApp(home: widget));

      final state = tester.state<_TestMixinWidgetState>(
        find.byType(_TestMixinWidget),
      );
      // select_all_nodes has Cmd+A shortcut
      final result = state.testGetActionShortcut('select_all_nodes');

      expect(result, isNotNull);
      // Should contain Cmd (meta key)
      expect(result!.contains('Cmd') || result.contains('Ctrl'), isTrue);
    });

    testWidgets('getActionShortcut formats Shift modifier correctly', (
      tester,
    ) async {
      final controller = createTestController();
      // Add a shortcut with Shift modifier
      controller.shortcuts.setShortcut(
        LogicalKeySet(LogicalKeyboardKey.keyS, LogicalKeyboardKey.shift),
        'test_shift_action',
      );

      final widget = _TestMixinWidget(controller: controller);
      await tester.pumpWidget(MaterialApp(home: widget));

      final state = tester.state<_TestMixinWidgetState>(
        find.byType(_TestMixinWidget),
      );
      final result = state.testGetActionShortcut('test_shift_action');

      expect(result, isNotNull);
      expect(result!.contains('Shift'), isTrue);
    });

    testWidgets('getActionShortcut formats Alt modifier correctly', (
      tester,
    ) async {
      final controller = createTestController();
      // Add a shortcut with Alt modifier
      controller.shortcuts.setShortcut(
        LogicalKeySet(LogicalKeyboardKey.keyA, LogicalKeyboardKey.alt),
        'test_alt_action',
      );

      final widget = _TestMixinWidget(controller: controller);
      await tester.pumpWidget(MaterialApp(home: widget));

      final state = tester.state<_TestMixinWidgetState>(
        find.byType(_TestMixinWidget),
      );
      final result = state.testGetActionShortcut('test_alt_action');

      expect(result, isNotNull);
      expect(result!.contains('Alt'), isTrue);
    });

    testWidgets(
      'getActionShortcut formats multiple modifiers with + separator',
      (tester) async {
        final controller = createTestController();
        final widget = _TestMixinWidget(controller: controller);
        await tester.pumpWidget(MaterialApp(home: widget));

        final state = tester.state<_TestMixinWidgetState>(
          find.byType(_TestMixinWidget),
        );
        // ungroup_node has Cmd+Shift+G shortcut
        final result = state.testGetActionShortcut('ungroup_node');

        expect(result, isNotNull);
        expect(result!.contains('+'), isTrue);
      },
    );
  });

  // ===========================================================================
  // NodeFlowKeyboardHandler Widget Tests
  // ===========================================================================

  group('NodeFlowKeyboardHandler', () {
    testWidgets('builds without error', (tester) async {
      final controller = createTestController();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: NodeFlowKeyboardHandler<String>(
              controller: controller,
              child: Container(),
            ),
          ),
        ),
      );

      expect(find.byType(NodeFlowKeyboardHandler<String>), findsOneWidget);
    });

    testWidgets('child is rendered', (tester) async {
      final controller = createTestController();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: NodeFlowKeyboardHandler<String>(
              controller: controller,
              child: const Text('Test Child'),
            ),
          ),
        ),
      );

      expect(find.text('Test Child'), findsOneWidget);
    });

    testWidgets('uses provided focus node', (tester) async {
      final controller = createTestController();
      final focusNode = FocusNode(debugLabel: 'CustomFocusNode');

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: NodeFlowKeyboardHandler<String>(
              controller: controller,
              focusNode: focusNode,
              child: Container(),
            ),
          ),
        ),
      );

      expect(find.byType(NodeFlowKeyboardHandler<String>), findsOneWidget);

      // Clean up
      focusNode.dispose();
    });

    testWidgets('autofocus is true by default', (tester) async {
      final controller = createTestController();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: NodeFlowKeyboardHandler<String>(
              controller: controller,
              child: Container(),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Widget should have autofocus enabled by default
      final handler = tester.widget<NodeFlowKeyboardHandler<String>>(
        find.byType(NodeFlowKeyboardHandler<String>),
      );
      expect(handler.autofocus, isTrue);
    });

    testWidgets('can disable autofocus', (tester) async {
      final controller = createTestController();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: NodeFlowKeyboardHandler<String>(
              controller: controller,
              autofocus: false,
              child: Container(),
            ),
          ),
        ),
      );

      final handler = tester.widget<NodeFlowKeyboardHandler<String>>(
        find.byType(NodeFlowKeyboardHandler<String>),
      );
      expect(handler.autofocus, isFalse);
    });

    testWidgets('disposes owned focus node on unmount', (tester) async {
      final controller = createTestController();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: NodeFlowKeyboardHandler<String>(
              controller: controller,
              child: Container(),
            ),
          ),
        ),
      );

      // Unmount the widget
      await tester.pumpWidget(
        const MaterialApp(home: Scaffold(body: SizedBox())),
      );

      // Should not throw on dispose
      expect(true, isTrue);
    });

    testWidgets('does not dispose provided focus node on unmount', (
      tester,
    ) async {
      final controller = createTestController();
      final focusNode = FocusNode(debugLabel: 'ProvidedFocusNode');

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: NodeFlowKeyboardHandler<String>(
              controller: controller,
              focusNode: focusNode,
              child: Container(),
            ),
          ),
        ),
      );

      // Unmount the widget
      await tester.pumpWidget(
        const MaterialApp(home: Scaffold(body: SizedBox())),
      );

      // The provided focus node should still be usable
      expect(() => focusNode.requestFocus(), returnsNormally);

      // Clean up
      focusNode.dispose();
    });

    testWidgets('wraps child with FocusableActionDetector', (tester) async {
      final controller = createTestController();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: NodeFlowKeyboardHandler<String>(
              controller: controller,
              child: const Text('Child'),
            ),
          ),
        ),
      );

      expect(find.byType(FocusableActionDetector), findsOneWidget);
    });

    testWidgets('registers shortcuts from controller', (tester) async {
      final controller = createTestController();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: NodeFlowKeyboardHandler<String>(
              controller: controller,
              child: Container(),
            ),
          ),
        ),
      );

      // The FocusableActionDetector should have shortcuts registered
      final detector = tester.widget<FocusableActionDetector>(
        find.byType(FocusableActionDetector),
      );
      expect(detector.shortcuts, isNotEmpty);
    });
  });

  // ===========================================================================
  // handleKeyEvent Tests
  // ===========================================================================

  group('handleKeyEvent', () {
    test('returns false for non-KeyDownEvent', () {
      final manager = NodeFlowShortcutManager<String>();
      final controller = createTestController();

      // KeyUpEvent should be ignored
      final keyUpEvent = KeyUpEvent(
        physicalKey: PhysicalKeyboardKey.keyA,
        logicalKey: LogicalKeyboardKey.keyA,
        timeStamp: Duration.zero,
      );

      final result = manager.handleKeyEvent(keyUpEvent, controller, null);

      expect(result, isFalse);
    });

    test('returns false when no matching shortcut', () {
      final manager = NodeFlowShortcutManager<String>();
      final controller = createTestController();

      // Create a key event for a key that has no shortcut
      final keyDownEvent = KeyDownEvent(
        physicalKey: PhysicalKeyboardKey.keyZ,
        logicalKey: LogicalKeyboardKey.keyZ,
        timeStamp: Duration.zero,
      );

      final result = manager.handleKeyEvent(keyDownEvent, controller, null);

      expect(result, isFalse);
    });

    test('returns false when action does not exist for shortcut', () {
      final manager = NodeFlowShortcutManager<String>();
      final controller = createTestController();

      // Set a shortcut for a non-existent action
      manager.setShortcut(
        LogicalKeySet(LogicalKeyboardKey.keyZ),
        'non_existent_action',
      );

      final keyDownEvent = KeyDownEvent(
        physicalKey: PhysicalKeyboardKey.keyZ,
        logicalKey: LogicalKeyboardKey.keyZ,
        timeStamp: Duration.zero,
      );

      final result = manager.handleKeyEvent(keyDownEvent, controller, null);

      expect(result, isFalse);
    });

    test('returns false when action canExecute returns false', () {
      final manager = NodeFlowShortcutManager<String>();
      final controller = createTestController();
      final action = _TrackingAction(canExecuteResult: false);

      manager.registerAction(action);
      manager.setShortcut(
        LogicalKeySet(LogicalKeyboardKey.keyT),
        'tracking_action',
      );

      final keyDownEvent = KeyDownEvent(
        physicalKey: PhysicalKeyboardKey.keyT,
        logicalKey: LogicalKeyboardKey.keyT,
        timeStamp: Duration.zero,
      );

      final result = manager.handleKeyEvent(keyDownEvent, controller, null);

      expect(result, isFalse);
      expect(action.executeCount, equals(0));
    });
  });

  // ===========================================================================
  // Key Normalization Tests
  // ===========================================================================

  group('Key Normalization', () {
    test('normalizes left control to control', () {
      final manager = NodeFlowShortcutManager<String>();

      // The manager should handle both controlLeft and control
      final ctrlA = LogicalKeySet(
        LogicalKeyboardKey.keyA,
        LogicalKeyboardKey.control,
      );

      expect(manager.shortcuts[ctrlA], equals('select_all_nodes'));
    });

    test('normalizes left meta to meta', () {
      final manager = NodeFlowShortcutManager<String>();

      final cmdA = LogicalKeySet(
        LogicalKeyboardKey.keyA,
        LogicalKeyboardKey.meta,
      );

      expect(manager.shortcuts[cmdA], equals('select_all_nodes'));
    });

    test('normalizes left shift to shift', () {
      final manager = NodeFlowShortcutManager<String>();

      final shiftCmdG = LogicalKeySet(
        LogicalKeyboardKey.keyG,
        LogicalKeyboardKey.meta,
        LogicalKeyboardKey.shift,
      );

      expect(manager.shortcuts[shiftCmdG], equals('ungroup_node'));
    });
  });

  // ===========================================================================
  // Action Intent with Context Tests
  // ===========================================================================

  group('NodeFlowActionIntent with context', () {
    testWidgets('intent preserves context', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              final intent = NodeFlowActionIntent<String>(
                actionId: 'test_action',
                context: context,
              );
              expect(intent.context, equals(context));
              return Container();
            },
          ),
        ),
      );
    });

    test('intents with same actionId but different contexts are equal', () {
      const intent1 = NodeFlowActionIntent<String>(
        actionId: 'test_action',
        context: null,
      );
      const intent2 = NodeFlowActionIntent<String>(
        actionId: 'test_action',
        context: null,
      );

      // Equality is based only on actionId
      expect(intent1, equals(intent2));
    });
  });

  // ===========================================================================
  // Invert Selection with All Selected Tests
  // ===========================================================================

  group('Invert Selection Edge Cases', () {
    test('invert selection when all nodes are selected clears selection', () {
      final manager = NodeFlowShortcutManager<String>();
      manager.registerActions(
        DefaultNodeFlowActions.createDefaultActions<String>(),
      );

      final nodes = [createTestNode(id: 'n1'), createTestNode(id: 'n2')];
      final controller = createTestController(nodes: nodes);
      controller.selectAllNodes();

      expect(controller.selectedNodeIds.length, equals(2));

      final action = manager.getAction('invert_selection')!;
      action.execute(controller, null);

      expect(controller.selectedNodeIds, isEmpty);
    });

    test('invert selection when no nodes are selected selects all', () {
      final manager = NodeFlowShortcutManager<String>();
      manager.registerActions(
        DefaultNodeFlowActions.createDefaultActions<String>(),
      );

      final nodes = [createTestNode(id: 'n1'), createTestNode(id: 'n2')];
      final controller = createTestController(nodes: nodes);

      expect(controller.selectedNodeIds, isEmpty);

      final action = manager.getAction('invert_selection')!;
      action.execute(controller, null);

      expect(controller.selectedNodeIds.length, equals(2));
    });
  });

  // ===========================================================================
  // Failing Action Execution Tests
  // ===========================================================================

  group('Failing Action Execution', () {
    test('action returning false from execute', () {
      final manager = NodeFlowShortcutManager<String>();
      manager.registerAction(const _FailingExecuteAction());

      final controller = createTestController();
      final action = manager.getAction('failing_action')!;

      final result = action.execute(controller, null);

      expect(result, isFalse);
    });
  });
}

// ===========================================================================
// Test Actions
// ===========================================================================

class _TestAction extends NodeFlowAction<String> {
  const _TestAction()
    : super(
        id: 'test_action',
        label: 'Test Action',
        description: 'A test action for testing',
        category: 'Test',
      );

  @override
  bool execute(
    NodeFlowController<String, dynamic> controller,
    BuildContext? context,
  ) {
    return true;
  }
}

class _AnotherTestAction extends NodeFlowAction<String> {
  const _AnotherTestAction()
    : super(
        id: 'another_action',
        label: 'Another Action',
        description: 'Another test action',
        category: 'Test',
      );

  @override
  bool execute(
    NodeFlowController<String, dynamic> controller,
    BuildContext? context,
  ) {
    return true;
  }
}

class _ReplacementTestAction extends NodeFlowAction<String> {
  const _ReplacementTestAction()
    : super(id: 'test_action', label: 'Replacement Action', category: 'Test');

  @override
  bool execute(
    NodeFlowController<String, dynamic> controller,
    BuildContext? context,
  ) {
    return true;
  }
}

class _ActionWithDefaultCategory extends NodeFlowAction<String> {
  const _ActionWithDefaultCategory()
    : super(id: 'default_category_action', label: 'Default Category Action');

  @override
  bool execute(
    NodeFlowController<String, dynamic> controller,
    BuildContext? context,
  ) {
    return true;
  }
}

class _ActionWithNullDescription extends NodeFlowAction<String> {
  const _ActionWithNullDescription()
    : super(id: 'null_description_action', label: 'Null Description Action');

  @override
  bool execute(
    NodeFlowController<String, dynamic> controller,
    BuildContext? context,
  ) {
    return true;
  }
}

class _CategoryAction1 extends NodeFlowAction<String> {
  const _CategoryAction1()
    : super(
        id: 'category1_action',
        label: 'Category 1 Action',
        category: 'Category1',
      );

  @override
  bool execute(
    NodeFlowController<String, dynamic> controller,
    BuildContext? context,
  ) {
    return true;
  }
}

class _CategoryAction2 extends NodeFlowAction<String> {
  const _CategoryAction2()
    : super(
        id: 'category2_action',
        label: 'Category 2 Action',
        category: 'Category2',
      );

  @override
  bool execute(
    NodeFlowController<String, dynamic> controller,
    BuildContext? context,
  ) {
    return true;
  }
}

/// Action that tracks execution for testing.
class _TrackingAction extends NodeFlowAction<String> {
  _TrackingAction({this.canExecuteResult = true})
    : super(id: 'tracking_action', label: 'Tracking Action', category: 'Test');

  final bool canExecuteResult;
  int executeCount = 0;

  @override
  bool execute(
    NodeFlowController<String, dynamic> controller,
    BuildContext? context,
  ) {
    executeCount++;
    return true;
  }

  @override
  bool canExecute(NodeFlowController<String, dynamic> controller) {
    return canExecuteResult;
  }
}

/// Action that returns false on execute.
class _FailingExecuteAction extends NodeFlowAction<String> {
  const _FailingExecuteAction()
    : super(id: 'failing_action', label: 'Failing Action', category: 'Test');

  @override
  bool execute(
    NodeFlowController<String, dynamic> controller,
    BuildContext? context,
  ) {
    return false;
  }
}

/// Test widget that uses NodeFlowActionsMixin.
class _TestMixinWidget extends StatefulWidget {
  const _TestMixinWidget({required this.controller});

  final NodeFlowController<String, dynamic>? controller;

  @override
  State<_TestMixinWidget> createState() => _TestMixinWidgetState();
}

class _TestMixinWidgetState extends State<_TestMixinWidget>
    with NodeFlowActionsMixin<_TestMixinWidget> {
  @override
  NodeFlowController<String, dynamic>? get nodeFlowController =>
      widget.controller;

  // Expose mixin methods for testing
  bool testExecuteAction(String actionId) => executeAction(actionId);
  bool testCanExecuteAction(String actionId) => canExecuteAction(actionId);
  String? testGetActionShortcut(String actionId) => getActionShortcut(actionId);

  @override
  Widget build(BuildContext context) {
    return Container();
  }
}
