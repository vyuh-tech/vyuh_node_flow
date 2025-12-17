import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'node_flow_controller.dart';

/// Base class for actions that can be triggered in the node flow editor.
///
/// An action represents a user operation that can be executed via keyboard
/// shortcuts, menu items, or programmatically. Actions encapsulate both the
/// operation logic and metadata for UI presentation.
///
/// Each action has:
/// - Unique [id] for identification and mapping to shortcuts
/// - Human-readable [label] for menus and command palettes
/// - Optional [description] for tooltips
/// - [category] for grouping in menus
/// - [execute] method that performs the operation
/// - [canExecute] method for conditional enabling
///
/// Example implementation:
/// ```dart
/// class MyCustomAction<T> extends NodeFlowAction<T> {
///   const MyCustomAction()
///     : super(
///         id: 'my_custom_action',
///         label: 'My Custom Action',
///         description: 'Does something custom',
///         category: 'Custom',
///       );
///
///   @override
///   bool execute(NodeFlowController<T> controller, BuildContext? context) {
///     // Perform the action
///     controller.selectAllNodes();
///     return true; // Return true if action succeeded
///   }
///
///   @override
///   bool canExecute(NodeFlowController<T> controller) {
///     return controller.nodes.isNotEmpty;
///   }
/// }
/// ```
abstract class NodeFlowAction<T> {
  const NodeFlowAction({
    required this.id,
    required this.label,
    this.description,
    this.category = 'General',
  });

  /// Unique identifier for this action.
  ///
  /// Used to map keyboard shortcuts to actions and for programmatic execution.
  /// Should be lowercase with underscores (e.g., 'select_all_nodes').
  final String id;

  /// Human-readable label for UI presentation.
  ///
  /// Displayed in menus, command palettes, and keyboard shortcut dialogs.
  /// Should be concise and action-oriented (e.g., 'Select All').
  final String label;

  /// Optional description providing additional context.
  ///
  /// Used in tooltips and help documentation to explain what the action does.
  final String? description;

  /// Category for organizing actions in menus.
  ///
  /// Groups related actions together (e.g., 'Selection', 'Editing', 'Navigation').
  final String category;

  /// Executes the action's operation.
  ///
  /// Called when the action is triggered via keyboard shortcut, menu, or
  /// programmatically. Should perform the intended operation and return
  /// whether it succeeded.
  ///
  /// Parameters:
  /// - [controller]: The node flow controller to operate on
  /// - [context]: Optional build context for showing dialogs/snackbars
  ///
  /// Returns: `true` if the action was successfully executed, `false` otherwise
  bool execute(NodeFlowController<T> controller, BuildContext? context);

  /// Checks if this action can be executed in the current state.
  ///
  /// Used to enable/disable menu items and prevent invalid operations.
  /// The default implementation returns `true` (always enabled).
  ///
  /// Parameters:
  /// - [controller]: The node flow controller to check state against
  ///
  /// Returns: `true` if the action can currently be executed
  ///
  /// Example:
  /// ```dart
  /// @override
  /// bool canExecute(NodeFlowController<T> controller) {
  ///   // Only allow if at least 2 nodes are selected
  ///   return controller.selectedNodeIds.length >= 2;
  /// }
  /// ```
  bool canExecute(NodeFlowController<T> controller) => true;
}

/// Manages keyboard shortcuts and action execution.
///
/// The shortcut manager maintains:
/// - Registered actions that can be executed
/// - Keyboard shortcut mappings to action IDs
/// - Methods for handling keyboard events
/// - Action search and categorization
///
/// Built-in shortcuts follow platform conventions:
/// - Cmd/Ctrl for primary modifier
/// - Shift for variations
/// - Common key bindings (Cmd+A for select all, Delete for delete, etc.)
///
/// Example usage:
/// ```dart
/// // Create manager and register actions
/// final manager = NodeFlowShortcutManager<MyData>();
/// manager.registerActions(DefaultNodeFlowActions.createDefaultActions());
///
/// // Handle keyboard events
/// KeyboardListener(
///   onKeyEvent: (event) {
///     manager.handleKeyEvent(event, controller, context);
///   },
///   child: ...,
/// );
///
/// // Custom shortcut
/// manager.setShortcut(
///   LogicalKeySet(LogicalKeyboardKey.keyQ, LogicalKeyboardKey.meta),
///   'my_custom_action',
/// );
///
/// // Search actions
/// final results = manager.searchActions('select');
/// ```
class NodeFlowShortcutManager<T> {
  /// Creates a shortcut manager with optional custom shortcuts.
  ///
  /// Parameters:
  /// - [customShortcuts]: Optional map of keyboard shortcuts to action IDs
  ///   that will be added to or override default shortcuts
  ///
  /// Example:
  /// ```dart
  /// final manager = NodeFlowShortcutManager(
  ///   customShortcuts: {
  ///     LogicalKeySet(LogicalKeyboardKey.keyQ, LogicalKeyboardKey.meta): 'quit',
  ///   },
  /// );
  /// ```
  NodeFlowShortcutManager({Map<LogicalKeySet, String>? customShortcuts})
    : _shortcuts = {..._defaultShortcuts, ...?customShortcuts};

  final Map<LogicalKeySet, String> _shortcuts;
  final Map<String, NodeFlowAction<T>> _actions = {};

  /// Default keyboard shortcuts for common operations.
  ///
  /// Supports both Mac (Cmd) and Windows/Linux (Ctrl) conventions by
  /// registering both variants for most shortcuts.
  static final Map<LogicalKeySet, String> _defaultShortcuts = {
    // Selection
    LogicalKeySet(LogicalKeyboardKey.keyA, LogicalKeyboardKey.meta):
        'select_all_nodes',
    LogicalKeySet(LogicalKeyboardKey.keyA, LogicalKeyboardKey.control):
        'select_all_nodes',
    LogicalKeySet(LogicalKeyboardKey.keyI, LogicalKeyboardKey.meta):
        'invert_selection',
    LogicalKeySet(LogicalKeyboardKey.keyI, LogicalKeyboardKey.control):
        'invert_selection',

    // Editing
    LogicalKeySet(LogicalKeyboardKey.delete): 'delete_selected',
    LogicalKeySet(LogicalKeyboardKey.backspace): 'delete_selected',
    LogicalKeySet(LogicalKeyboardKey.keyD, LogicalKeyboardKey.meta):
        'duplicate_selected',
    LogicalKeySet(LogicalKeyboardKey.keyD, LogicalKeyboardKey.control):
        'duplicate_selected',
    LogicalKeySet(LogicalKeyboardKey.keyX, LogicalKeyboardKey.meta):
        'cut_selected',
    LogicalKeySet(LogicalKeyboardKey.keyX, LogicalKeyboardKey.control):
        'cut_selected',
    LogicalKeySet(LogicalKeyboardKey.keyC, LogicalKeyboardKey.meta):
        'copy_selected',
    LogicalKeySet(LogicalKeyboardKey.keyC, LogicalKeyboardKey.control):
        'copy_selected',
    LogicalKeySet(LogicalKeyboardKey.keyV, LogicalKeyboardKey.meta): 'paste',
    LogicalKeySet(LogicalKeyboardKey.keyV, LogicalKeyboardKey.control): 'paste',

    // Navigation & View
    LogicalKeySet(LogicalKeyboardKey.keyF): 'fit_to_view',
    LogicalKeySet(LogicalKeyboardKey.keyH): 'fit_selected',
    LogicalKeySet(LogicalKeyboardKey.digit0, LogicalKeyboardKey.meta):
        'reset_zoom',
    LogicalKeySet(LogicalKeyboardKey.digit0, LogicalKeyboardKey.control):
        'reset_zoom',
    LogicalKeySet(LogicalKeyboardKey.equal, LogicalKeyboardKey.meta): 'zoom_in',
    LogicalKeySet(LogicalKeyboardKey.equal, LogicalKeyboardKey.control):
        'zoom_in',
    LogicalKeySet(LogicalKeyboardKey.minus, LogicalKeyboardKey.meta):
        'zoom_out',
    LogicalKeySet(LogicalKeyboardKey.minus, LogicalKeyboardKey.control):
        'zoom_out',

    // Arrangement
    LogicalKeySet(LogicalKeyboardKey.bracketLeft, LogicalKeyboardKey.meta):
        'send_backward',
    LogicalKeySet(LogicalKeyboardKey.bracketLeft, LogicalKeyboardKey.control):
        'send_backward',
    LogicalKeySet(LogicalKeyboardKey.bracketRight, LogicalKeyboardKey.meta):
        'bring_forward',
    LogicalKeySet(LogicalKeyboardKey.bracketRight, LogicalKeyboardKey.control):
        'bring_forward',
    LogicalKeySet(LogicalKeyboardKey.bracketLeft): 'send_to_back',
    LogicalKeySet(LogicalKeyboardKey.bracketRight): 'bring_to_front',

    // Alignment
    LogicalKeySet(
      LogicalKeyboardKey.arrowUp,
      LogicalKeyboardKey.meta,
      LogicalKeyboardKey.shift,
    ): 'align_top',
    LogicalKeySet(
      LogicalKeyboardKey.arrowUp,
      LogicalKeyboardKey.control,
      LogicalKeyboardKey.shift,
    ): 'align_top',
    LogicalKeySet(
      LogicalKeyboardKey.arrowDown,
      LogicalKeyboardKey.meta,
      LogicalKeyboardKey.shift,
    ): 'align_bottom',
    LogicalKeySet(
      LogicalKeyboardKey.arrowDown,
      LogicalKeyboardKey.control,
      LogicalKeyboardKey.shift,
    ): 'align_bottom',
    LogicalKeySet(
      LogicalKeyboardKey.arrowLeft,
      LogicalKeyboardKey.meta,
      LogicalKeyboardKey.shift,
    ): 'align_left',
    LogicalKeySet(
      LogicalKeyboardKey.arrowLeft,
      LogicalKeyboardKey.control,
      LogicalKeyboardKey.shift,
    ): 'align_left',
    LogicalKeySet(
      LogicalKeyboardKey.arrowRight,
      LogicalKeyboardKey.meta,
      LogicalKeyboardKey.shift,
    ): 'align_right',
    LogicalKeySet(
      LogicalKeyboardKey.arrowRight,
      LogicalKeyboardKey.control,
      LogicalKeyboardKey.shift,
    ): 'align_right',

    // Grouping
    LogicalKeySet(LogicalKeyboardKey.keyG, LogicalKeyboardKey.meta):
        'create_group',
    LogicalKeySet(LogicalKeyboardKey.keyG, LogicalKeyboardKey.control):
        'create_group',
    LogicalKeySet(
      LogicalKeyboardKey.keyG,
      LogicalKeyboardKey.meta,
      LogicalKeyboardKey.shift,
    ): 'ungroup_node',
    LogicalKeySet(
      LogicalKeyboardKey.keyG,
      LogicalKeyboardKey.control,
      LogicalKeyboardKey.shift,
    ): 'ungroup_node',

    // General
    LogicalKeySet(LogicalKeyboardKey.escape): 'cancel_operation',
    LogicalKeySet(LogicalKeyboardKey.keyM): 'toggle_minimap',
    LogicalKeySet(LogicalKeyboardKey.keyN): 'toggle_snapping',
  };

  /// Registers a single action.
  ///
  /// Adds the action to the manager, making it available for execution.
  /// If an action with the same ID already exists, it will be replaced.
  ///
  /// Parameters:
  /// - [action]: The action to register
  void registerAction(NodeFlowAction<T> action) {
    _actions[action.id] = action;
  }

  /// Registers multiple actions at once.
  ///
  /// Convenience method for bulk registration. Commonly used with
  /// [DefaultNodeFlowActions.createDefaultActions].
  ///
  /// Parameters:
  /// - [actions]: List of actions to register
  ///
  /// Example:
  /// ```dart
  /// manager.registerActions(DefaultNodeFlowActions.createDefaultActions());
  /// ```
  void registerActions(List<NodeFlowAction<T>> actions) {
    for (final action in actions) {
      registerAction(action);
    }
  }

  /// Gets all registered actions grouped by category.
  ///
  /// Useful for building categorized menus or command palettes.
  ///
  /// Returns: Map where keys are category names and values are lists of actions
  ///
  /// Example:
  /// ```dart
  /// final byCategory = manager.getActionsByCategory();
  /// for (final entry in byCategory.entries) {
  ///   print('${entry.key}: ${entry.value.length} actions');
  /// }
  /// ```
  Map<String, List<NodeFlowAction<T>>> getActionsByCategory() {
    final result = <String, List<NodeFlowAction<T>>>{};
    for (final action in _actions.values) {
      result.putIfAbsent(action.category, () => []).add(action);
    }
    return result;
  }

  /// Finds an action by its ID.
  ///
  /// Parameters:
  /// - [actionId]: The unique identifier of the action to find
  ///
  /// Returns: The action if found, `null` otherwise
  NodeFlowAction<T>? getAction(String actionId) => _actions[actionId];

  /// Searches for actions matching a query string.
  ///
  /// Searches action labels, descriptions, and IDs (case-insensitive).
  /// Useful for implementing command palettes or search interfaces.
  ///
  /// Parameters:
  /// - [query]: The search query string
  ///
  /// Returns: List of actions matching the query
  ///
  /// Example:
  /// ```dart
  /// final results = manager.searchActions('align');
  /// // Returns all alignment-related actions
  /// ```
  List<NodeFlowAction<T>> searchActions(String query) {
    final lowerQuery = query.toLowerCase();
    return _actions.values
        .where(
          (action) =>
              action.label.toLowerCase().contains(lowerQuery) ||
              action.description?.toLowerCase().contains(lowerQuery) == true ||
              action.id.toLowerCase().contains(lowerQuery),
        )
        .toList();
  }

  /// Gets the keyboard shortcut for an action.
  ///
  /// Parameters:
  /// - [actionId]: The action ID to look up
  ///
  /// Returns: The [LogicalKeySet] for the action, or `null` if no shortcut exists
  LogicalKeySet? getShortcutForAction(String actionId) {
    for (final entry in _shortcuts.entries) {
      if (entry.value == actionId) {
        return entry.key;
      }
    }
    return null;
  }

  /// Handles keyboard events and executes matching actions.
  ///
  /// Call this from your keyboard event handler to process shortcuts.
  /// Only responds to [KeyDownEvent] to prevent duplicate executions.
  ///
  /// Parameters:
  /// - [event]: The keyboard event to handle
  /// - [controller]: The node flow controller to pass to actions
  /// - [context]: Optional build context for actions that need it
  ///
  /// Returns: `true` if an action was found and executed, `false` otherwise
  ///
  /// Example:
  /// ```dart
  /// Focus(
  ///   onKeyEvent: (node, event) {
  ///     if (manager.handleKeyEvent(event, controller, context)) {
  ///       return KeyEventResult.handled;
  ///     }
  ///     return KeyEventResult.ignored;
  ///   },
  ///   child: ...,
  /// );
  /// ```
  bool handleKeyEvent(
    KeyEvent event,
    NodeFlowController<T> controller,
    BuildContext? context,
  ) {
    if (event is! KeyDownEvent) return false;

    // Normalize pressed keys to handle left/right variants of modifier keys
    final allPressedKeys = {
      event.logicalKey,
      ...HardwareKeyboard.instance.logicalKeysPressed,
    };

    final normalizedPressedKeys = _normalizeKeySet(allPressedKeys);
    final pressedKeys = LogicalKeySet.fromSet(normalizedPressedKeys);

    // Direct lookup - O(1) instead of O(n)
    final actionId = _shortcuts[pressedKeys];
    if (actionId != null) {
      final action = _actions[actionId];
      if (action != null && action.canExecute(controller)) {
        final result = action.execute(controller, context);
        return result;
      }
    }

    return false;
  }

  /// Normalize modifier keys to handle left/right variants
  Set<LogicalKeyboardKey> _normalizeKeySet(Set<LogicalKeyboardKey> keys) {
    final normalized = <LogicalKeyboardKey>{};

    for (final key in keys) {
      // Convert specific left/right modifier keys to generic ones
      if (key == LogicalKeyboardKey.controlLeft ||
          key == LogicalKeyboardKey.controlRight) {
        normalized.add(LogicalKeyboardKey.control);
      } else if (key == LogicalKeyboardKey.metaLeft ||
          key == LogicalKeyboardKey.metaRight) {
        normalized.add(LogicalKeyboardKey.meta);
      } else if (key == LogicalKeyboardKey.altLeft ||
          key == LogicalKeyboardKey.altRight) {
        normalized.add(LogicalKeyboardKey.alt);
      } else if (key == LogicalKeyboardKey.shiftLeft ||
          key == LogicalKeyboardKey.shiftRight) {
        normalized.add(LogicalKeyboardKey.shift);
      } else {
        normalized.add(key);
      }
    }

    return normalized;
  }

  /// Sets or updates a keyboard shortcut.
  ///
  /// Maps a key combination to an action ID. If the shortcut already exists,
  /// it will be reassigned to the new action.
  ///
  /// Parameters:
  /// - [keySet]: The key combination (e.g., Cmd+S)
  /// - [actionId]: The ID of the action to execute
  ///
  /// Example:
  /// ```dart
  /// manager.setShortcut(
  ///   LogicalKeySet(LogicalKeyboardKey.keyS, LogicalKeyboardKey.meta),
  ///   'save_graph',
  /// );
  /// ```
  void setShortcut(LogicalKeySet keySet, String actionId) {
    _shortcuts[keySet] = actionId;
  }

  /// Removes a keyboard shortcut.
  ///
  /// Parameters:
  /// - [keySet]: The key combination to remove
  void removeShortcut(LogicalKeySet keySet) {
    _shortcuts.remove(keySet);
  }

  /// Gets all current keyboard shortcuts.
  ///
  /// Returns an unmodifiable map of shortcuts to action IDs.
  Map<LogicalKeySet, String> get shortcuts => Map.unmodifiable(_shortcuts);

  /// Gets the shortcuts map for UI display.
  ///
  /// Returns an unmodifiable map of shortcuts. Same as [shortcuts].
  Map<LogicalKeySet, String> get keyMap => Map.unmodifiable(_shortcuts);

  /// Gets all registered actions for UI display.
  ///
  /// Returns an unmodifiable map of action IDs to actions.
  Map<String, NodeFlowAction<T>> get actions => Map.unmodifiable(_actions);
}

/// Factory for creating default node flow actions.
///
/// Provides a complete set of built-in actions covering common operations
/// like selection, editing, navigation, alignment, and arrangement.
///
/// Use [createDefaultActions] to get all default actions for registration.
class DefaultNodeFlowActions<T> {
  /// Creates a list of all default actions.
  ///
  /// Returns a comprehensive set of actions including:
  /// - **Selection**: Select all, invert selection, clear selection
  /// - **Editing**: Delete, duplicate, cut, copy, paste
  /// - **Navigation**: Fit to view, fit selected, zoom controls
  /// - **Arrangement**: Bring forward, send backward, to front/back
  /// - **Alignment**: Align top/bottom/left/right, center horizontally/vertically
  /// - **General**: Cancel operation, toggle minimap/snapping
  ///
  /// Example:
  /// ```dart
  /// final manager = NodeFlowShortcutManager<MyData>();
  /// manager.registerActions(DefaultNodeFlowActions.createDefaultActions());
  /// ```
  static List<NodeFlowAction<T>> createDefaultActions<T>() {
    return [
      // Selection actions
      _SelectAllNodesAction<T>(),
      _InvertSelectionAction<T>(),
      _ClearSelectionAction<T>(),

      // Editing actions
      _DeleteSelectedAction<T>(),
      _DuplicateSelectedAction<T>(),
      _CutSelectedAction<T>(),
      _CopySelectedAction<T>(),
      _PasteAction<T>(),

      // Navigation actions
      _FitToViewAction<T>(),
      _FitSelectedAction<T>(),
      _ResetZoomAction<T>(),
      _ZoomInAction<T>(),
      _ZoomOutAction<T>(),

      // Arrangement actions
      _BringToFrontAction<T>(),
      _SendToBackAction<T>(),
      _BringForwardAction<T>(),
      _SendBackwardAction<T>(),

      // Alignment actions
      _AlignTopAction<T>(),
      _AlignBottomAction<T>(),
      _AlignLeftAction<T>(),
      _AlignRightAction<T>(),
      _AlignHorizontalCenterAction<T>(),
      _AlignVerticalCenterAction<T>(),

      // General actions
      _CancelOperationAction<T>(),
      _ToggleMinimapAction<T>(),
      _ToggleSnappingAction<T>(),
    ];
  }
}

// Concrete action implementations
class _SelectAllNodesAction<T> extends NodeFlowAction<T> {
  const _SelectAllNodesAction()
    : super(
        id: 'select_all_nodes',
        label: 'Select All',
        description: 'Select all nodes in the graph',
        category: 'Selection',
      );

  @override
  bool execute(NodeFlowController<T> controller, BuildContext? context) {
    controller.selectAllNodes();
    return true;
  }

  @override
  bool canExecute(NodeFlowController<T> controller) {
    return controller.nodes.isNotEmpty;
  }
}

class _InvertSelectionAction<T> extends NodeFlowAction<T> {
  const _InvertSelectionAction()
    : super(
        id: 'invert_selection',
        label: 'Invert Selection',
        description: 'Invert the current selection',
        category: 'Selection',
      );

  @override
  bool execute(NodeFlowController<T> controller, BuildContext? context) {
    controller.invertSelection();
    return true;
  }

  @override
  bool canExecute(NodeFlowController<T> controller) {
    return controller.nodes.isNotEmpty;
  }
}

class _ClearSelectionAction<T> extends NodeFlowAction<T> {
  const _ClearSelectionAction()
    : super(
        id: 'clear_selection',
        label: 'Clear Selection',
        description: 'Clear the current selection',
        category: 'Selection',
      );

  @override
  bool execute(NodeFlowController<T> controller, BuildContext? context) {
    controller.clearSelection();
    return true;
  }

  @override
  bool canExecute(NodeFlowController<T> controller) {
    return controller.hasSelection;
  }
}

class _DeleteSelectedAction<T> extends NodeFlowAction<T> {
  const _DeleteSelectedAction()
    : super(
        id: 'delete_selected',
        label: 'Delete',
        description: 'Delete selected nodes and connections',
        category: 'Editing',
      );

  @override
  bool execute(NodeFlowController<T> controller, BuildContext? context) {
    // Check if deletion is allowed by current behavior
    if (!controller.behavior.canDelete) {
      return false;
    }

    // Delete selected nodes
    for (final nodeId in controller.selectedNodeIds.toList()) {
      controller.removeNode(nodeId);
    }

    // Delete selected connections
    for (final connectionId in controller.selectedConnectionIds.toList()) {
      controller.removeConnection(connectionId);
    }

    // Delete selected annotations
    controller.annotations.deleteSelectedAnnotations();

    return true;
  }

  @override
  bool canExecute(NodeFlowController<T> controller) {
    return controller.behavior.canDelete &&
        (controller.hasSelection ||
            controller.annotations.selectedAnnotationIds.isNotEmpty);
  }
}

class _DuplicateSelectedAction<T> extends NodeFlowAction<T> {
  const _DuplicateSelectedAction()
    : super(
        id: 'duplicate_selected',
        label: 'Duplicate',
        description: 'Duplicate selected nodes',
        category: 'Editing',
      );

  @override
  bool execute(NodeFlowController<T> controller, BuildContext? context) {
    for (final nodeId in controller.selectedNodeIds.toList()) {
      controller.duplicateNode(nodeId);
    }
    return true;
  }

  @override
  bool canExecute(NodeFlowController<T> controller) {
    return controller.selectedNodeIds.isNotEmpty;
  }
}

class _CutSelectedAction<T> extends NodeFlowAction<T> {
  const _CutSelectedAction()
    : super(
        id: 'cut_selected',
        label: 'Cut',
        description: 'Cut selected nodes to clipboard',
        category: 'Editing',
      );

  @override
  bool execute(NodeFlowController<T> controller, BuildContext? context) {
    // TODO: Implement clipboard functionality
    return false;
  }

  @override
  bool canExecute(NodeFlowController<T> controller) {
    return controller.selectedNodeIds.isNotEmpty;
  }
}

class _CopySelectedAction<T> extends NodeFlowAction<T> {
  const _CopySelectedAction()
    : super(
        id: 'copy_selected',
        label: 'Copy',
        description: 'Copy selected nodes to clipboard',
        category: 'Editing',
      );

  @override
  bool execute(NodeFlowController<T> controller, BuildContext? context) {
    // TODO: Implement clipboard functionality
    return false;
  }

  @override
  bool canExecute(NodeFlowController<T> controller) {
    return controller.selectedNodeIds.isNotEmpty;
  }
}

class _PasteAction<T> extends NodeFlowAction<T> {
  const _PasteAction()
    : super(
        id: 'paste',
        label: 'Paste',
        description: 'Paste nodes from clipboard',
        category: 'Editing',
      );

  @override
  bool execute(NodeFlowController<T> controller, BuildContext? context) {
    // TODO: Implement clipboard functionality
    return false;
  }
}

class _FitToViewAction<T> extends NodeFlowAction<T> {
  const _FitToViewAction()
    : super(
        id: 'fit_to_view',
        label: 'Fit to View',
        description: 'Fit all nodes to the viewport',
        category: 'Navigation',
      );

  @override
  bool execute(NodeFlowController<T> controller, BuildContext? context) {
    controller.fitToView();
    return true;
  }

  @override
  bool canExecute(NodeFlowController<T> controller) {
    return controller.nodes.isNotEmpty;
  }
}

class _FitSelectedAction<T> extends NodeFlowAction<T> {
  const _FitSelectedAction()
    : super(
        id: 'fit_selected',
        label: 'Fit Selected to View',
        description: 'Fit selected nodes to the viewport',
        category: 'Navigation',
      );

  @override
  bool execute(NodeFlowController<T> controller, BuildContext? context) {
    controller.fitSelectedNodes();
    return true;
  }

  @override
  bool canExecute(NodeFlowController<T> controller) {
    return controller.selectedNodeIds.isNotEmpty;
  }
}

class _ResetZoomAction<T> extends NodeFlowAction<T> {
  const _ResetZoomAction()
    : super(
        id: 'reset_zoom',
        label: 'Reset Zoom',
        description: 'Reset zoom to 100%',
        category: 'Navigation',
      );

  @override
  bool execute(NodeFlowController<T> controller, BuildContext? context) {
    // Calculate delta to reach 1.0 zoom while maintaining focal point
    final currentZoom = controller.viewport.zoom;
    final targetZoom = 1.0;
    final delta = targetZoom - currentZoom;
    controller.zoomBy(delta);
    return true;
  }
}

class _ZoomInAction<T> extends NodeFlowAction<T> {
  const _ZoomInAction()
    : super(
        id: 'zoom_in',
        label: 'Zoom In',
        description: 'Zoom into the view',
        category: 'Navigation',
      );

  @override
  bool execute(NodeFlowController<T> controller, BuildContext? context) {
    controller.zoomBy(0.1);
    return true;
  }
}

class _ZoomOutAction<T> extends NodeFlowAction<T> {
  const _ZoomOutAction()
    : super(
        id: 'zoom_out',
        label: 'Zoom Out',
        description: 'Zoom out of the view',
        category: 'Navigation',
      );

  @override
  bool execute(NodeFlowController<T> controller, BuildContext? context) {
    controller.zoomBy(-0.1);
    return true;
  }
}

class _BringToFrontAction<T> extends NodeFlowAction<T> {
  const _BringToFrontAction()
    : super(
        id: 'bring_to_front',
        label: 'Bring to Front',
        description: 'Bring selected nodes and annotations to front',
        category: 'Arrangement',
      );

  @override
  bool execute(NodeFlowController<T> controller, BuildContext? context) {
    // Handle selected annotations first
    final selectedAnnotationIds = controller.annotations.selectedAnnotationIds;
    if (selectedAnnotationIds.isNotEmpty) {
      for (final annotationId in selectedAnnotationIds) {
        controller.annotations.bringAnnotationToFront(annotationId);
      }
      return true;
    }

    // Handle selected nodes (original behavior)
    for (final nodeId in controller.selectedNodeIds) {
      controller.bringNodeToFront(nodeId);
    }
    return true;
  }

  @override
  bool canExecute(NodeFlowController<T> controller) {
    return controller.selectedNodeIds.isNotEmpty ||
        controller.annotations.selectedAnnotationIds.isNotEmpty;
  }
}

class _SendToBackAction<T> extends NodeFlowAction<T> {
  const _SendToBackAction()
    : super(
        id: 'send_to_back',
        label: 'Send to Back',
        description: 'Send selected nodes and annotations to back',
        category: 'Arrangement',
      );

  @override
  bool execute(NodeFlowController<T> controller, BuildContext? context) {
    // Handle selected annotations first
    final selectedAnnotationIds = controller.annotations.selectedAnnotationIds;
    if (selectedAnnotationIds.isNotEmpty) {
      for (final annotationId in selectedAnnotationIds) {
        controller.annotations.sendAnnotationToBack(annotationId);
      }
      return true;
    }

    // Handle selected nodes (original behavior)
    for (final nodeId in controller.selectedNodeIds) {
      controller.sendNodeToBack(nodeId);
    }
    return true;
  }

  @override
  bool canExecute(NodeFlowController<T> controller) {
    return controller.selectedNodeIds.isNotEmpty ||
        controller.annotations.selectedAnnotationIds.isNotEmpty;
  }
}

class _BringForwardAction<T> extends NodeFlowAction<T> {
  const _BringForwardAction()
    : super(
        id: 'bring_forward',
        label: 'Bring Forward',
        description: 'Bring selected nodes and annotations forward one layer',
        category: 'Arrangement',
      );

  @override
  bool execute(NodeFlowController<T> controller, BuildContext? context) {
    // Handle selected annotations first
    final selectedAnnotationIds = controller.annotations.selectedAnnotationIds;
    if (selectedAnnotationIds.isNotEmpty) {
      for (final annotationId in selectedAnnotationIds) {
        controller.annotations.bringAnnotationForward(annotationId);
      }
      return true;
    }

    // Handle selected nodes
    for (final nodeId in controller.selectedNodeIds) {
      controller.bringNodeForward(nodeId);
    }
    return true;
  }

  @override
  bool canExecute(NodeFlowController<T> controller) {
    return controller.selectedNodeIds.isNotEmpty ||
        controller.annotations.selectedAnnotationIds.isNotEmpty;
  }
}

class _SendBackwardAction<T> extends NodeFlowAction<T> {
  const _SendBackwardAction()
    : super(
        id: 'send_backward',
        label: 'Send Backward',
        description: 'Send selected nodes and annotations backward one layer',
        category: 'Arrangement',
      );

  @override
  bool execute(NodeFlowController<T> controller, BuildContext? context) {
    // Handle selected annotations first
    final selectedAnnotationIds = controller.annotations.selectedAnnotationIds;
    if (selectedAnnotationIds.isNotEmpty) {
      for (final annotationId in selectedAnnotationIds) {
        controller.annotations.sendAnnotationBackward(annotationId);
      }
      return true;
    }

    // Handle selected nodes
    for (final nodeId in controller.selectedNodeIds) {
      controller.sendNodeBackward(nodeId);
    }
    return true;
  }

  @override
  bool canExecute(NodeFlowController<T> controller) {
    return controller.selectedNodeIds.isNotEmpty ||
        controller.annotations.selectedAnnotationIds.isNotEmpty;
  }
}

class _AlignTopAction<T> extends NodeFlowAction<T> {
  const _AlignTopAction()
    : super(
        id: 'align_top',
        label: 'Align Top',
        description: 'Align selected nodes to top edge',
        category: 'Alignment',
      );

  @override
  bool execute(NodeFlowController<T> controller, BuildContext? context) {
    controller.alignNodes(
      controller.selectedNodeIds.toList(),
      NodeAlignment.top,
    );
    return true;
  }

  @override
  bool canExecute(NodeFlowController<T> controller) {
    return controller.selectedNodeIds.length >= 2;
  }
}

class _AlignBottomAction<T> extends NodeFlowAction<T> {
  const _AlignBottomAction()
    : super(
        id: 'align_bottom',
        label: 'Align Bottom',
        description: 'Align selected nodes to bottom edge',
        category: 'Alignment',
      );

  @override
  bool execute(NodeFlowController<T> controller, BuildContext? context) {
    controller.alignNodes(
      controller.selectedNodeIds.toList(),
      NodeAlignment.bottom,
    );
    return true;
  }

  @override
  bool canExecute(NodeFlowController<T> controller) {
    return controller.selectedNodeIds.length >= 2;
  }
}

class _AlignLeftAction<T> extends NodeFlowAction<T> {
  const _AlignLeftAction()
    : super(
        id: 'align_left',
        label: 'Align Left',
        description: 'Align selected nodes to left edge',
        category: 'Alignment',
      );

  @override
  bool execute(NodeFlowController<T> controller, BuildContext? context) {
    controller.alignNodes(
      controller.selectedNodeIds.toList(),
      NodeAlignment.left,
    );
    return true;
  }

  @override
  bool canExecute(NodeFlowController<T> controller) {
    return controller.selectedNodeIds.length >= 2;
  }
}

class _AlignRightAction<T> extends NodeFlowAction<T> {
  const _AlignRightAction()
    : super(
        id: 'align_right',
        label: 'Align Right',
        description: 'Align selected nodes to right edge',
        category: 'Alignment',
      );

  @override
  bool execute(NodeFlowController<T> controller, BuildContext? context) {
    controller.alignNodes(
      controller.selectedNodeIds.toList(),
      NodeAlignment.right,
    );
    return true;
  }

  @override
  bool canExecute(NodeFlowController<T> controller) {
    return controller.selectedNodeIds.length >= 2;
  }
}

class _AlignHorizontalCenterAction<T> extends NodeFlowAction<T> {
  const _AlignHorizontalCenterAction()
    : super(
        id: 'align_horizontal_center',
        label: 'Align Horizontal Center',
        description: 'Align selected nodes to horizontal center',
        category: 'Alignment',
      );

  @override
  bool execute(NodeFlowController<T> controller, BuildContext? context) {
    controller.alignNodes(
      controller.selectedNodeIds.toList(),
      NodeAlignment.horizontalCenter,
    );
    return true;
  }

  @override
  bool canExecute(NodeFlowController<T> controller) {
    return controller.selectedNodeIds.length >= 2;
  }
}

class _AlignVerticalCenterAction<T> extends NodeFlowAction<T> {
  const _AlignVerticalCenterAction()
    : super(
        id: 'align_vertical_center',
        label: 'Align Vertical Center',
        description: 'Align selected nodes to vertical center',
        category: 'Alignment',
      );

  @override
  bool execute(NodeFlowController<T> controller, BuildContext? context) {
    controller.alignNodes(
      controller.selectedNodeIds.toList(),
      NodeAlignment.verticalCenter,
    );
    return true;
  }

  @override
  bool canExecute(NodeFlowController<T> controller) {
    return controller.selectedNodeIds.length >= 2;
  }
}

class _CancelOperationAction<T> extends NodeFlowAction<T> {
  const _CancelOperationAction()
    : super(
        id: 'cancel_operation',
        label: 'Cancel',
        description: 'Cancel current operation',
        category: 'General',
      );

  @override
  bool execute(NodeFlowController<T> controller, BuildContext? context) {
    // Cancel connection creation
    controller.interaction.cancelConnection();

    // Finish selection
    controller.interaction.finishSelection();

    // Clear selection if nothing else to cancel
    if (!controller.interaction.isCreatingConnection &&
        !controller.interaction.isDrawingSelection) {
      controller.clearSelection();
    }

    return true;
  }
}

class _ToggleMinimapAction<T> extends NodeFlowAction<T> {
  const _ToggleMinimapAction()
    : super(
        id: 'toggle_minimap',
        label: 'Toggle Minimap',
        description: 'Show or hide the minimap overlay',
        category: 'View',
      );

  @override
  bool execute(NodeFlowController<T> controller, BuildContext? context) {
    controller.config.toggleMinimap();
    return true;
  }
}

class _ToggleSnappingAction<T> extends NodeFlowAction<T> {
  const _ToggleSnappingAction()
    : super(
        id: 'toggle_snapping',
        label: 'Toggle Snapping',
        description: 'Toggle grid snapping for nodes and annotations',
        category: 'Editing',
      );

  @override
  bool execute(NodeFlowController<T> controller, BuildContext? context) {
    controller.config.toggleSnapping();
    return true;
  }
}
