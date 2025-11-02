import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../graph/node_flow_actions.dart';
import '../graph/node_flow_controller.dart';

/// A Flutter [Action] wrapper that integrates [NodeFlowAction] with Flutter's
/// actions and shortcuts system.
///
/// This class bridges the gap between the NodeFlow action system and Flutter's
/// built-in [Action] framework, allowing NodeFlow actions to be triggered through
/// Flutter's standard keyboard shortcut mechanisms.
///
/// The action checks if it can be executed before invoking the underlying
/// [NodeFlowAction], ensuring that disabled actions don't respond to shortcuts.
///
/// Example usage:
/// ```dart
/// final action = NodeFlowFlutterAction(
///   myNodeFlowAction,
///   controller,
/// );
/// ```
///
/// See also:
/// - [NodeFlowAction], the underlying action being wrapped
/// - [NodeFlowActionIntent], the intent type for these actions
/// - [NodeFlowActionsProvider], which sets up actions and shortcuts
class NodeFlowFlutterAction<T> extends Action<NodeFlowActionIntent<T>> {
  /// Creates a Flutter action wrapper for a [NodeFlowAction].
  ///
  /// Parameters:
  /// - [nodeFlowAction]: The NodeFlow action to wrap
  /// - [controller]: The controller that the action will operate on
  NodeFlowFlutterAction(this.nodeFlowAction, this.controller);

  /// The underlying NodeFlow action being wrapped.
  final NodeFlowAction<T> nodeFlowAction;

  /// The controller that this action operates on.
  final NodeFlowController<T> controller;

  /// Checks if this action can currently be executed.
  ///
  /// Returns true if the underlying [nodeFlowAction] can execute on the current
  /// controller state, false otherwise. This controls whether keyboard shortcuts
  /// will trigger the action.
  @override
  bool isEnabled(NodeFlowActionIntent<T> intent) {
    return nodeFlowAction.canExecute(controller);
  }

  /// Invokes the underlying NodeFlow action.
  ///
  /// This method checks if the action can be executed before invoking it.
  /// If the action cannot be executed, it returns null without performing
  /// any operation.
  ///
  /// Parameters:
  /// - [intent]: The intent containing the action ID and optional context
  ///
  /// Returns the result of the action execution, or null if not executed.
  @override
  Object? invoke(NodeFlowActionIntent<T> intent) {
    if (nodeFlowAction.canExecute(controller)) {
      return nodeFlowAction.execute(controller, intent.context);
    }
    return null;
  }
}

/// An [Intent] representing a NodeFlow action to be executed.
///
/// This intent carries information about which action should be executed
/// and provides optional context for the action. It's used as part of Flutter's
/// actions and shortcuts system to trigger NodeFlow actions.
///
/// Example usage:
/// ```dart
/// final intent = NodeFlowActionIntent(
///   actionId: 'delete_selection',
///   context: context,
/// );
/// ```
///
/// See also:
/// - [NodeFlowFlutterAction], which handles these intents
/// - [NodeFlowActionsProvider], which maps shortcuts to these intents
class NodeFlowActionIntent<T> extends Intent {
  /// Creates an intent for a NodeFlow action.
  ///
  /// Parameters:
  /// - [actionId]: The unique identifier of the action to execute
  /// - [context]: Optional build context that may be needed by the action
  const NodeFlowActionIntent({required this.actionId, this.context});

  /// The unique identifier of the action to execute.
  final String actionId;

  /// Optional build context that may be needed by some actions.
  ///
  /// For example, actions that show dialogs or need theme information
  /// may require a build context.
  final BuildContext? context;
}

/// A widget that provides Flutter Actions/Shortcuts integration for NodeFlow.
///
/// This widget wraps its child with a [FocusableActionDetector] that automatically
/// converts NodeFlow actions and shortcuts into Flutter's standard actions and
/// shortcuts system. This enables keyboard shortcuts to work seamlessly with
/// NodeFlow's action system.
///
/// The provider:
/// - Converts [LogicalKeySet] shortcuts to Flutter [SingleActivator] shortcuts
/// - Creates [NodeFlowFlutterAction] instances for each NodeFlow action
/// - Maps keyboard shortcuts to their corresponding actions
///
/// Example usage:
/// ```dart
/// NodeFlowActionsProvider(
///   controller: nodeFlowController,
///   child: NodeFlowCanvas(...),
/// )
/// ```
///
/// Note: This is one of two approaches to keyboard handling in NodeFlow.
/// For a simpler, more direct approach, see [NodeFlowKeyboardHandler].
///
/// See also:
/// - [NodeFlowKeyboardHandler], an alternative keyboard handling approach
/// - [FocusableActionDetector], the Flutter widget used internally
class NodeFlowActionsProvider<T> extends StatelessWidget {
  /// Creates a provider for NodeFlow actions and shortcuts.
  ///
  /// Parameters:
  /// - [controller]: The NodeFlow controller containing actions and shortcuts
  /// - [child]: The widget to wrap with action handling
  const NodeFlowActionsProvider({
    super.key,
    required this.controller,
    required this.child,
  });

  /// The NodeFlow controller containing the actions and shortcuts to expose.
  final NodeFlowController<T> controller;

  /// The child widget that will have access to the actions and shortcuts.
  final Widget child;

  @override
  Widget build(BuildContext context) {
    // Build shortcuts map from our action system
    final shortcuts = <ShortcutActivator, Intent>{};
    final actions = <Type, Action<Intent>>{};

    // Convert NodeFlow shortcuts to Flutter shortcuts
    for (final entry in controller.shortcuts.shortcuts.entries) {
      final actionId = entry.value;
      final keySet = entry.key;

      // Convert LogicalKeySet to SingleActivator
      final keys = keySet.keys.toList();
      if (keys.isNotEmpty) {
        final primaryKey = keys.firstWhere(
          (key) => ![
            LogicalKeyboardKey.control,
            LogicalKeyboardKey.meta,
            LogicalKeyboardKey.alt,
            LogicalKeyboardKey.shift,
          ].contains(key),
          orElse: () => keys.first,
        );

        final activator = SingleActivator(
          primaryKey,
          control: keys.contains(LogicalKeyboardKey.control),
          meta: keys.contains(LogicalKeyboardKey.meta),
          alt: keys.contains(LogicalKeyboardKey.alt),
          shift: keys.contains(LogicalKeyboardKey.shift),
        );

        shortcuts[activator] = NodeFlowActionIntent<T>(
          actionId: actionId,
          context: context,
        );
      }
    }

    // Create Flutter actions for each NodeFlow action
    final actionsByCategory = controller.shortcuts.getActionsByCategory();
    for (final category in actionsByCategory.values) {
      for (final nodeFlowAction in category) {
        actions[NodeFlowActionIntent<T>] = NodeFlowFlutterAction<T>(
          nodeFlowAction,
          controller,
        );
      }
    }

    return FocusableActionDetector(
      shortcuts: shortcuts,
      actions: actions,
      child: child,
    );
  }
}

/// A simpler alternative to [NodeFlowActionsProvider] that handles keyboard
/// shortcuts using Flutter's [Focus] widget.
///
/// This widget provides a more direct approach to keyboard handling compared to
/// [NodeFlowActionsProvider]. Instead of using Flutter's actions framework, it
/// directly handles key events through the NodeFlow shortcuts system.
///
/// Features:
/// - Automatic focus management with optional autofocus
/// - Direct key event handling through the controller's shortcuts system
/// - Support for custom focus nodes
/// - Simpler implementation with less overhead
///
/// Example usage:
/// ```dart
/// NodeFlowKeyboardHandler(
///   controller: nodeFlowController,
///   autofocus: true,
///   child: NodeFlowCanvas(...),
/// )
/// ```
///
/// When to use this vs [NodeFlowActionsProvider]:
/// - Use this for simpler, more direct keyboard handling
/// - Use [NodeFlowActionsProvider] if you need integration with Flutter's
///   broader actions ecosystem (e.g., for menu integration)
///
/// See also:
/// - [NodeFlowActionsProvider], the alternative actions-based approach
/// - [Focus], the Flutter widget used internally for keyboard handling
class NodeFlowKeyboardHandler<T> extends StatefulWidget {
  /// Creates a keyboard handler for NodeFlow.
  ///
  /// Parameters:
  /// - [controller]: The NodeFlow controller containing the shortcuts system
  /// - [child]: The widget to wrap with keyboard handling
  /// - [autofocus]: Whether to automatically request focus (default: true)
  /// - [focusNode]: Optional custom focus node; if null, one will be created
  const NodeFlowKeyboardHandler({
    super.key,
    required this.controller,
    required this.child,
    this.autofocus = true,
    this.focusNode,
  });

  /// The NodeFlow controller containing the shortcuts to handle.
  final NodeFlowController<T> controller;

  /// The child widget that will have keyboard handling.
  final Widget child;

  /// Whether to automatically request focus when the widget is built.
  ///
  /// Defaults to true. Set to false if you want to manually control focus.
  final bool autofocus;

  /// Optional custom focus node.
  ///
  /// If provided, this focus node will be used instead of creating a new one.
  /// This is useful if you need to coordinate focus with other parts of your UI.
  final FocusNode? focusNode;

  @override
  State<NodeFlowKeyboardHandler<T>> createState() =>
      _NodeFlowKeyboardHandlerState<T>();
}

/// State for [NodeFlowKeyboardHandler].
///
/// Manages the focus node lifecycle and handles key events by routing them
/// through the NodeFlow shortcuts system.
class _NodeFlowKeyboardHandlerState<T>
    extends State<NodeFlowKeyboardHandler<T>> {
  late final FocusNode _focusNode;
  bool _ownsNode = false;

  @override
  void initState() {
    super.initState();
    if (widget.focusNode != null) {
      _focusNode = widget.focusNode!;
      _ownsNode = false;
    } else {
      _focusNode = FocusNode(debugLabel: 'NodeFlowKeyboardHandler');
      _ownsNode = true;
    }
    _focusNode.addListener(_onFocusChange);

    // Request focus on next frame to ensure widget is built
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && widget.autofocus) {
        _focusNode.requestFocus();
      }
    });
  }

  @override
  void dispose() {
    _focusNode.removeListener(_onFocusChange);
    if (_ownsNode) {
      _focusNode.dispose();
    }
    super.dispose();
  }

  void _onFocusChange() {
    // Focus state changed - could be used for debugging if needed
  }

  @override
  Widget build(BuildContext context) {
    return Focus(
      focusNode: _focusNode,
      autofocus: widget.autofocus,
      onKeyEvent: (node, event) {
        // Handle keyboard events through our actions system
        if (widget.controller.shortcuts.handleKeyEvent(
          event,
          widget.controller,
          context,
        )) {
          return KeyEventResult.handled;
        }
        return KeyEventResult.ignored;
      },
      child: widget.child,
    );
  }

  /// Manually requests focus for the keyboard handler.
  ///
  /// This can be useful if autofocus is disabled and you want to programmatically
  /// give focus to the keyboard handler at a specific time.
  void requestFocus() {
    _focusNode.requestFocus();
  }
}

/// A mixin that provides convenient methods for executing NodeFlow actions
/// from within stateful widgets.
///
/// This mixin is useful for widgets that need to programmatically trigger
/// NodeFlow actions, check if actions can be executed, or display keyboard
/// shortcuts in UI elements like menus or tooltips.
///
/// Example usage:
/// ```dart
/// class MyWidget extends StatefulWidget {
///   const MyWidget({super.key});
///
///   @override
///   State<MyWidget> createState() => _MyWidgetState();
/// }
///
/// class _MyWidgetState extends State<MyWidget> with NodeFlowActionsMixin {
///   NodeFlowController? _controller;
///
///   @override
///   NodeFlowController? get nodeFlowController => _controller;
///
///   void _handleDelete() {
///     if (canExecuteAction('delete_selection')) {
///       executeAction('delete_selection');
///     }
///   }
///
///   @override
///   Widget build(BuildContext context) {
///     final shortcut = getActionShortcut('delete_selection');
///     return TextButton(
///       onPressed: _handleDelete,
///       child: Text('Delete ($shortcut)'),
///     );
///   }
/// }
/// ```
///
/// See also:
/// - [NodeFlowController], which contains the actions system
/// - [NodeFlowAction], the action type being executed
mixin NodeFlowActionsMixin<T extends StatefulWidget> on State<T> {
  /// The NodeFlow controller to use for action execution.
  ///
  /// Subclasses must implement this getter to provide the controller.
  /// Return null if no controller is available.
  NodeFlowController? get nodeFlowController;

  /// Executes a NodeFlow action by its ID.
  ///
  /// This method looks up the action in the controller's shortcuts system,
  /// checks if it can be executed, and then executes it if possible.
  ///
  /// Parameters:
  /// - [actionId]: The unique identifier of the action to execute
  ///
  /// Returns true if the action was executed, false otherwise.
  ///
  /// Example:
  /// ```dart
  /// if (executeAction('delete_selection')) {
  ///   print('Deleted selected items');
  /// } else {
  ///   print('Could not delete (maybe nothing selected)');
  /// }
  /// ```
  bool executeAction(String actionId) {
    final controller = nodeFlowController;
    if (controller == null) return false;

    final action = controller.shortcuts.getAction(actionId);
    if (action != null && action.canExecute(controller)) {
      return action.execute(controller, context);
    }
    return false;
  }

  /// Checks if a NodeFlow action can currently be executed.
  ///
  /// This is useful for enabling/disabling UI elements based on whether
  /// their associated actions can be performed.
  ///
  /// Parameters:
  /// - [actionId]: The unique identifier of the action to check
  ///
  /// Returns true if the action exists and can be executed, false otherwise.
  ///
  /// Example:
  /// ```dart
  /// Widget build(BuildContext context) {
  ///   return ElevatedButton(
  ///     onPressed: canExecuteAction('undo') ? _undo : null,
  ///     child: const Text('Undo'),
  ///   );
  /// }
  /// ```
  bool canExecuteAction(String actionId) {
    final controller = nodeFlowController;
    if (controller == null) return false;

    final action = controller.shortcuts.getAction(actionId);
    return action?.canExecute(controller) ?? false;
  }

  /// Gets the keyboard shortcut string for an action.
  ///
  /// This returns a human-readable string representation of the keyboard
  /// shortcut assigned to an action, suitable for display in UI elements
  /// like menus or tooltips.
  ///
  /// Parameters:
  /// - [actionId]: The unique identifier of the action
  ///
  /// Returns a string like "Ctrl+C" or "Cmd+Shift+Z", or null if no shortcut
  /// is assigned or the action doesn't exist.
  ///
  /// Example:
  /// ```dart
  /// Widget build(BuildContext context) {
  ///   final deleteShortcut = getActionShortcut('delete_selection');
  ///   return ListTile(
  ///     title: const Text('Delete'),
  ///     trailing: Text(deleteShortcut ?? ''),
  ///     onTap: () => executeAction('delete_selection'),
  ///   );
  /// }
  /// ```
  String? getActionShortcut(String actionId) {
    final controller = nodeFlowController;
    if (controller == null) return null;

    final shortcut = controller.shortcuts.getShortcutForAction(actionId);
    return shortcut != null ? _shortcutToString(shortcut) : null;
  }

  /// Converts a [LogicalKeySet] to a human-readable string.
  ///
  /// This internal method formats keyboard shortcuts in a standard way,
  /// with modifiers (Ctrl, Cmd, Alt, Shift) appearing before the main key.
  String _shortcutToString(LogicalKeySet keySet) {
    final keys = keySet.keys.toList();
    final keyNames = <String>[];

    // Sort keys to show modifiers first
    keys.sort((a, b) {
      const modifiers = [
        LogicalKeyboardKey.control,
        LogicalKeyboardKey.meta,
        LogicalKeyboardKey.alt,
        LogicalKeyboardKey.shift,
      ];
      final aIsMod = modifiers.contains(a);
      final bIsMod = modifiers.contains(b);
      if (aIsMod && !bIsMod) return -1;
      if (!aIsMod && bIsMod) return 1;
      return 0;
    });

    for (final key in keys) {
      if (key == LogicalKeyboardKey.control) {
        keyNames.add('Ctrl');
      } else if (key == LogicalKeyboardKey.meta) {
        keyNames.add('Cmd');
      } else if (key == LogicalKeyboardKey.alt) {
        keyNames.add('Alt');
      } else if (key == LogicalKeyboardKey.shift) {
        keyNames.add('Shift');
      } else {
        keyNames.add(key.debugName ?? key.keyLabel);
      }
    }

    return keyNames.join('+');
  }
}
