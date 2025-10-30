import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../graph/node_flow_controller.dart';

/// Represents a single action that can be triggered in the node flow editor
abstract class NodeFlowAction<T> {
  const NodeFlowAction({
    required this.id,
    required this.label,
    this.description,
    this.category = 'General',
  });

  /// Unique identifier for this action
  final String id;

  /// Human-readable label for menus/palettes
  final String label;

  /// Optional description for tooltips
  final String? description;

  /// Category for grouping in menus
  final String category;

  /// Execute the action with the given controller and context
  bool execute(NodeFlowController<T> controller, BuildContext? context);

  /// Check if this action can be executed in the current state
  bool canExecute(NodeFlowController<T> controller) => true;
}

/// Manages keyboard shortcuts and their mappings to actions
class NodeFlowShortcutManager<T> {
  NodeFlowShortcutManager({Map<LogicalKeySet, String>? customShortcuts})
    : _shortcuts = {..._defaultShortcuts, ...?customShortcuts};

  final Map<LogicalKeySet, String> _shortcuts;
  final Map<String, NodeFlowAction<T>> _actions = {};

  /// Default keyboard shortcuts
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

  /// Register a new action
  void registerAction(NodeFlowAction<T> action) {
    _actions[action.id] = action;
  }

  /// Register multiple actions at once
  void registerActions(List<NodeFlowAction<T>> actions) {
    for (final action in actions) {
      registerAction(action);
    }
  }

  /// Get all registered actions grouped by category
  Map<String, List<NodeFlowAction<T>>> getActionsByCategory() {
    final result = <String, List<NodeFlowAction<T>>>{};
    for (final action in _actions.values) {
      result.putIfAbsent(action.category, () => []).add(action);
    }
    return result;
  }

  /// Find action by its ID
  NodeFlowAction<T>? getAction(String actionId) => _actions[actionId];

  /// Find actions that match a search query
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

  /// Get the keyboard shortcut for an action (if any)
  LogicalKeySet? getShortcutForAction(String actionId) {
    for (final entry in _shortcuts.entries) {
      if (entry.value == actionId) {
        return entry.key;
      }
    }
    return null;
  }

  /// Handle a keyboard event and execute the corresponding action if found
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

  /// Add or update a keyboard shortcut
  void setShortcut(LogicalKeySet keySet, String actionId) {
    _shortcuts[keySet] = actionId;
  }

  /// Remove a keyboard shortcut
  void removeShortcut(LogicalKeySet keySet) {
    _shortcuts.remove(keySet);
  }

  /// Get all current shortcuts
  Map<LogicalKeySet, String> get shortcuts => Map.unmodifiable(_shortcuts);

  /// Get the shortcuts key map for dialog display
  Map<LogicalKeySet, String> get keyMap => Map.unmodifiable(_shortcuts);

  /// Get all registered actions for dialog display
  Map<String, NodeFlowAction<T>> get actions => Map.unmodifiable(_actions);
}

/// Concrete implementation of common node flow actions
class DefaultNodeFlowActions<T> {
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
    return controller.hasSelection ||
        controller.annotations.selectedAnnotationIds.isNotEmpty;
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
