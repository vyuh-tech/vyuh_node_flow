import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../graph/node_flow_actions.dart';
import '../graph/node_flow_controller.dart';

/// A Flutter [Action] that dispatches to NodeFlow actions based on intent actionId.
///
/// This class acts as a dispatcher that bridges Flutter's Actions framework with
/// NodeFlow's action system. It receives [NodeFlowActionIntent]s and dispatches
/// them to the appropriate [NodeFlowAction] based on the intent's actionId.
///
/// The dispatcher:
/// - Looks up the appropriate NodeFlowAction using the intent's actionId
/// - Checks if the action can be executed before invoking it
/// - Executes the action with the controller and optional context
///
/// This design allows all NodeFlow actions to be handled by a single Flutter Action,
/// which is compatible with Flutter's type-based action registration system.
///
/// Example usage:
/// ```dart
/// final dispatcher = NodeFlowActionDispatcher(controller);
/// actions[NodeFlowActionIntent] = dispatcher;
/// ```
///
/// See also:
/// - [NodeFlowAction], the actions being dispatched to
/// - [NodeFlowActionIntent], the intent containing the action ID
/// - [NodeFlowKeyboardHandler], which sets up the dispatcher
class NodeFlowActionDispatcher<T> extends Action<NodeFlowActionIntent<T>> {
  /// Creates a NodeFlow action dispatcher.
  ///
  /// Parameters:
  /// - [controller]: The controller that actions will operate on
  NodeFlowActionDispatcher(this.controller);

  /// The controller that actions operate on.
  final NodeFlowController<T> controller;

  /// Checks if the action specified in the intent can currently be executed.
  ///
  /// Looks up the action by ID and checks its canExecute status.
  @override
  bool isEnabled(NodeFlowActionIntent<T> intent) {
    final action = controller.shortcuts.getAction(intent.actionId);
    return action?.canExecute(controller) ?? false;
  }

  /// Dispatches the intent to the appropriate NodeFlow action.
  ///
  /// Looks up the action by ID, checks if it can be executed, and invokes it.
  @override
  Object? invoke(NodeFlowActionIntent<T> intent) {
    final action = controller.shortcuts.getAction(intent.actionId);
    if (action != null && action.canExecute(controller)) {
      return action.execute(controller, intent.context);
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
/// Each intent instance is uniquely identified by its [actionId], allowing
/// multiple different actions to be registered in Flutter's actions system.
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
/// - [NodeFlowKeyboardHandler], which sets up actions and shortcuts
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

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is NodeFlowActionIntent<T> &&
          runtimeType == other.runtimeType &&
          actionId == other.actionId;

  @override
  int get hashCode => actionId.hashCode;
}

/// Primary keyboard handler for NodeFlow using Flutter's Actions and Shortcuts system.
///
/// This widget integrates NodeFlow's action system with Flutter's built-in
/// Actions and Shortcuts framework, providing proper keyboard shortcut handling
/// with all the benefits of Flutter's actions ecosystem (menu integration,
/// shortcut manager support, etc.).
///
/// Features:
/// - Proper integration with Flutter's Actions and Shortcuts system
/// - Automatic focus management with optional autofocus
/// - Support for custom focus nodes
/// - Action enabling/disabling based on controller state
/// - Platform-aware shortcut handling (Cmd on macOS, Ctrl on Windows/Linux)
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
/// See also:
/// - [Shortcuts], the Flutter widget used for shortcut mapping
/// - [Actions], the Flutter widget used for action handling
/// - [NodeFlowShortcutManager], which defines available shortcuts
class NodeFlowKeyboardHandler<T> extends StatefulWidget {
  /// Creates a keyboard handler for NodeFlow.
  ///
  /// Parameters:
  /// - [controller]: The NodeFlow controller containing the shortcuts and actions
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

  /// The NodeFlow controller containing the shortcuts and actions.
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
/// Manages the focus node lifecycle, builds the shortcuts and actions maps,
/// and integrates with Flutter's Actions/Shortcuts system.
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

  /// Converts a LogicalKeySet to a SingleActivator for Flutter's Shortcuts system.
  ///
  /// Extracts modifier keys and the primary key from the LogicalKeySet and
  /// creates a SingleActivator that Flutter's Shortcuts widget can use.
  SingleActivator? _convertToSingleActivator(LogicalKeySet keySet) {
    final keys = keySet.keys.toList();
    if (keys.isEmpty) return null;

    // Find the primary key (non-modifier)
    final primaryKey = keys.firstWhere(
      (key) => ![
        LogicalKeyboardKey.control,
        LogicalKeyboardKey.meta,
        LogicalKeyboardKey.alt,
        LogicalKeyboardKey.shift,
      ].contains(key),
      orElse: () => keys.first,
    );

    // Extract modifiers
    final control = keys.contains(LogicalKeyboardKey.control);
    final meta = keys.contains(LogicalKeyboardKey.meta);
    final alt = keys.contains(LogicalKeyboardKey.alt);
    final shift = keys.contains(LogicalKeyboardKey.shift);

    return SingleActivator(
      primaryKey,
      control: control,
      meta: meta,
      alt: alt,
      shift: shift,
    );
  }

  @override
  Widget build(BuildContext context) {
    // Build shortcuts map from NodeFlow shortcuts
    final shortcuts = <ShortcutActivator, Intent>{};

    // Convert NodeFlow shortcuts to Flutter shortcuts
    for (final entry in widget.controller.shortcuts.shortcuts.entries) {
      final actionId = entry.value;
      final keySet = entry.key;

      final activator = _convertToSingleActivator(keySet);
      if (activator != null) {
        shortcuts[activator] = NodeFlowActionIntent<T>(
          actionId: actionId,
          context: context,
        );
      }
    }

    // Create a single dispatcher action that routes all intents to their
    // corresponding NodeFlow actions
    final actions = <Type, Action<Intent>>{
      NodeFlowActionIntent<T>: NodeFlowActionDispatcher<T>(widget.controller),
    };

    return FocusableActionDetector(
      focusNode: _focusNode,
      autofocus: widget.autofocus,
      shortcuts: shortcuts,
      actions: actions,
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
