import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../graph/node_flow_controller.dart';
import 'node_flow_actions.dart';

/// Flutter Actions wrapper for NodeFlow actions
class NodeFlowFlutterAction<T> extends Action<NodeFlowActionIntent<T>> {
  NodeFlowFlutterAction(this.nodeFlowAction, this.controller);

  final NodeFlowAction<T> nodeFlowAction;
  final NodeFlowController<T> controller;

  @override
  bool isEnabled(NodeFlowActionIntent<T> intent) {
    return nodeFlowAction.canExecute(controller);
  }

  @override
  Object? invoke(NodeFlowActionIntent<T> intent) {
    if (nodeFlowAction.canExecute(controller)) {
      return nodeFlowAction.execute(controller, intent.context);
    }
    return null;
  }
}

/// Intent for NodeFlow actions
class NodeFlowActionIntent<T> extends Intent {
  const NodeFlowActionIntent({required this.actionId, this.context});

  final String actionId;
  final BuildContext? context;
}

/// Widget that provides Flutter Actions/Shortcuts integration for NodeFlow
class NodeFlowActionsProvider<T> extends StatelessWidget {
  const NodeFlowActionsProvider({
    super.key,
    required this.controller,
    required this.child,
  });

  final NodeFlowController<T> controller;
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

/// Alternative simpler approach using just Focus widget
class NodeFlowKeyboardHandler<T> extends StatefulWidget {
  const NodeFlowKeyboardHandler({
    super.key,
    required this.controller,
    required this.child,
    this.autofocus = true,
    this.focusNode,
  });

  final NodeFlowController<T> controller;
  final Widget child;
  final bool autofocus;
  final FocusNode? focusNode;

  @override
  State<NodeFlowKeyboardHandler<T>> createState() =>
      _NodeFlowKeyboardHandlerState<T>();
}

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

  /// Public method to manually request focus
  void requestFocus() {
    _focusNode.requestFocus();
  }
}

/// Mixin for widgets that want to handle NodeFlow actions
mixin NodeFlowActionsMixin<T extends StatefulWidget> on State<T> {
  NodeFlowController? get nodeFlowController;

  /// Execute a NodeFlow action by ID
  bool executeAction(String actionId) {
    final controller = nodeFlowController;
    if (controller == null) return false;

    final action = controller.shortcuts.getAction(actionId);
    if (action != null && action.canExecute(controller)) {
      return action.execute(controller, context);
    }
    return false;
  }

  /// Check if an action can be executed
  bool canExecuteAction(String actionId) {
    final controller = nodeFlowController;
    if (controller == null) return false;

    final action = controller.shortcuts.getAction(actionId);
    return action?.canExecute(controller) ?? false;
  }

  /// Get keyboard shortcut for an action
  String? getActionShortcut(String actionId) {
    final controller = nodeFlowController;
    if (controller == null) return null;

    final shortcut = controller.shortcuts.getShortcutForAction(actionId);
    return shortcut != null ? _shortcutToString(shortcut) : null;
  }

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
