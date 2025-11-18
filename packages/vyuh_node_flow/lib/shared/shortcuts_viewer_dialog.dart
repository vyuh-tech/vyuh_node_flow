import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../graph/node_flow_actions.dart';

/// A comprehensive shortcuts viewer dialog that displays all available
/// keyboard shortcuts organized by category.
///
/// This dialog presents keyboard shortcuts in a user-friendly format with:
/// - Categorized shortcuts (General, Selection, Navigation, etc.)
/// - Platform-specific key symbols (⌘ on macOS, Ctrl on Windows/Linux)
/// - Action descriptions alongside each shortcut
/// - Searchable and scrollable interface
///
/// The dialog automatically formats shortcuts based on the current platform,
/// showing appropriate symbols for modifier keys (Command, Control, Alt, Shift).
///
/// Example usage:
/// ```dart
/// void showShortcuts(BuildContext context) {
///   showDialog(
///     context: context,
///     builder: (context) => ShortcutsViewerDialog(
///       shortcuts: controller.shortcuts.shortcuts,
///       actions: controller.shortcuts.getAllActions(),
///     ),
///   );
/// }
/// ```
///
/// See also:
/// - [NodeFlowAction], which provides action metadata like label and description
/// - [LogicalKeySet], used to define keyboard shortcuts
class ShortcutsViewerDialog extends StatelessWidget {
  /// Creates a shortcuts viewer dialog.
  ///
  /// Parameters:
  /// - [shortcuts]: A map of keyboard shortcuts to action IDs
  /// - [actions]: A map of action IDs to [NodeFlowAction] objects for metadata
  const ShortcutsViewerDialog({
    super.key,
    required this.shortcuts,
    this.actions = const {},
  });

  /// The map of keyboard shortcuts to action IDs.
  ///
  /// Each key is a [LogicalKeySet] representing a keyboard combination,
  /// and each value is the ID of the action triggered by that shortcut.
  final Map<LogicalKeySet, String> shortcuts;

  /// The map of action IDs to [NodeFlowAction] objects.
  ///
  /// This provides metadata about each action including its label, description,
  /// and category for organizing the display.
  final Map<String, NodeFlowAction> actions;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final categorizedShortcuts = _categorizeShortcuts();

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        width: 700,
        height: MediaQuery.of(context).size.height * 0.8,
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Keyboard Shortcuts',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Quick reference for all available keyboard shortcuts',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.textTheme.bodySmall?.color,
              ),
            ),
            const SizedBox(height: 24),

            // Shortcuts list
            Expanded(
              child: ListView.separated(
                itemCount: categorizedShortcuts.length,
                separatorBuilder: (context, index) =>
                    const SizedBox(height: 24),
                itemBuilder: (context, index) {
                  final category = categorizedShortcuts.keys.elementAt(index);
                  final shortcuts = categorizedShortcuts[category]!;

                  return _ShortcutCategory(
                    category: category,
                    shortcuts: shortcuts,
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Organizes shortcuts into categories based on their action metadata.
  ///
  /// This method groups shortcuts by their action's category property and sorts
  /// them alphabetically within each category. The "General" category is always
  /// shown first if it exists.
  ///
  /// Returns a map where keys are category names and values are lists of
  /// shortcuts in that category, sorted by action label.
  Map<String, List<_ShortcutInfo>> _categorizeShortcuts() {
    final categorized = <String, List<_ShortcutInfo>>{};

    shortcuts.forEach((keySet, actionId) {
      final action = actions[actionId];
      if (action == null) return;

      final category = action.category;
      categorized
          .putIfAbsent(category, () => [])
          .add(_ShortcutInfo(keySet: keySet, action: action));
    });

    // Sort categories alphabetically, but keep "General" first if it exists
    final sortedCategories = categorized.keys.toList()
      ..sort((a, b) {
        if (a == 'General') return -1;
        if (b == 'General') return 1;
        return a.compareTo(b);
      });

    return {
      for (final category in sortedCategories)
        category: categorized[category]!
          ..sort((a, b) => a.action.label.compareTo(b.action.label)),
    };
  }
}

/// A widget that displays a category section in the shortcuts viewer.
///
/// This internal widget renders a category header and all shortcuts within that
/// category. Categories are visually separated and labeled for easy navigation.
class _ShortcutCategory extends StatelessWidget {
  const _ShortcutCategory({required this.category, required this.shortcuts});

  /// The name of this category (e.g., "General", "Selection", "Navigation").
  final String category;

  /// The list of shortcuts in this category.
  final List<_ShortcutInfo> shortcuts;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Category header
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: theme.colorScheme.primaryContainer.withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(
            category.toUpperCase(),
            style: theme.textTheme.labelMedium?.copyWith(
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
              color: theme.colorScheme.primary,
            ),
          ),
        ),
        const SizedBox(height: 12),

        // Shortcuts in category
        ...shortcuts.map(
          (shortcut) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _ShortcutRow(shortcut: shortcut),
          ),
        ),
      ],
    );
  }
}

/// A widget that displays a single shortcut entry in the viewer.
///
/// This internal widget renders:
/// - The keyboard combination (e.g., "Cmd + C" or "Ctrl + Shift + Z")
/// - The action label and description
/// - Platform-specific key symbols and formatting
class _ShortcutRow extends StatelessWidget {
  const _ShortcutRow({required this.shortcut});

  /// The shortcut information to display.
  final _ShortcutInfo shortcut;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: theme.dividerColor.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          // Keyboard shortcut
          Expanded(
            flex: 2,
            child: Wrap(
              spacing: 4,
              runSpacing: 4,
              children: _buildKeyWidgets(shortcut.keySet),
            ),
          ),

          const SizedBox(width: 24),

          // Action description
          Expanded(
            flex: 3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  shortcut.action.label,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                ),
                if (shortcut.action.description != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    shortcut.action.description!,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.textTheme.bodySmall?.color?.withValues(
                        alpha: 0.8,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Builds a list of widgets representing the keys in a shortcut.
  ///
  /// This method creates [_KeyWidget] instances for each key in the set,
  /// with modifiers (Ctrl, Cmd, Alt, Shift) appearing first, separated by " + ".
  ///
  /// Returns a list of widgets that visually represent the keyboard combination.
  List<Widget> _buildKeyWidgets(LogicalKeySet keySet) {
    final widgets = <Widget>[];
    final keys = keySet.keys.toList();

    // Sort keys to ensure modifiers come first
    keys.sort((a, b) {
      final aIsModifier = _isModifier(a);
      final bIsModifier = _isModifier(b);
      if (aIsModifier && !bIsModifier) return -1;
      if (!aIsModifier && bIsModifier) return 1;
      return 0;
    });

    for (var i = 0; i < keys.length; i++) {
      widgets.add(_KeyWidget(logicalKey: keys[i]));
      if (i < keys.length - 1) {
        widgets.add(const Text(' + ', style: TextStyle(fontSize: 12)));
      }
    }

    return widgets;
  }

  /// Checks if a key is a modifier key (Cmd, Ctrl, Alt, Shift).
  ///
  /// Returns true for any variant of modifier keys (left, right, or generic).
  bool _isModifier(LogicalKeyboardKey key) {
    return key == LogicalKeyboardKey.meta ||
        key == LogicalKeyboardKey.metaLeft ||
        key == LogicalKeyboardKey.metaRight ||
        key == LogicalKeyboardKey.control ||
        key == LogicalKeyboardKey.controlLeft ||
        key == LogicalKeyboardKey.controlRight ||
        key == LogicalKeyboardKey.shift ||
        key == LogicalKeyboardKey.shiftLeft ||
        key == LogicalKeyboardKey.shiftRight ||
        key == LogicalKeyboardKey.alt ||
        key == LogicalKeyboardKey.altLeft ||
        key == LogicalKeyboardKey.altRight;
  }
}

/// A widget that renders a single keyboard key with platform-specific styling.
///
/// This internal widget displays a key in a keyboard-like appearance with:
/// - Platform-specific symbols (⌘ for Cmd on macOS, Ctrl on Windows/Linux)
/// - Arrow symbols for arrow keys (↑ ↓ ← →)
/// - Monospace font for consistency
/// - Shadow and border styling to mimic a physical key
class _KeyWidget extends StatelessWidget {
  const _KeyWidget({required this.logicalKey});

  /// The keyboard key to display.
  final LogicalKeyboardKey logicalKey;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final keyLabel = _getKeyLabel(logicalKey);

    return Container(
      constraints: const BoxConstraints(minWidth: 32),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(
          color: theme.colorScheme.outline.withValues(alpha: 0.3),
        ),
        boxShadow: [
          BoxShadow(
            color: theme.shadowColor.withValues(alpha: 0.1),
            offset: const Offset(0, 1),
            blurRadius: 2,
          ),
        ],
      ),
      child: Text(
        keyLabel,
        style: theme.textTheme.labelSmall?.copyWith(
          fontWeight: FontWeight.w500,
          fontFamily: 'monospace',
        ),
        textAlign: TextAlign.center,
      ),
    );
  }

  /// Returns true if the current platform is macOS.
  ///
  /// This is used to determine whether to show macOS-style symbols (⌘)
  /// or Windows/Linux-style labels (Ctrl, Win).
  bool get _isMacOS {
    return defaultTargetPlatform == TargetPlatform.macOS;
  }

  /// Converts a [LogicalKeyboardKey] to a display label.
  ///
  /// This method returns platform-appropriate labels for keys:
  /// - Modifier keys show symbols on macOS (⌘ ⌃ ⌥ ⇧) or text on Windows/Linux
  /// - Arrow keys show arrow symbols (↑ ↓ ← →)
  /// - Special keys show abbreviated names (Esc, Del, etc.)
  /// - Letter and number keys show uppercase letters or digits
  ///
  /// Returns a string suitable for display in the shortcuts viewer.
  String _getKeyLabel(LogicalKeyboardKey key) {
    // Handle modifier keys with platform-specific labels
    if (key == LogicalKeyboardKey.meta ||
        key == LogicalKeyboardKey.metaLeft ||
        key == LogicalKeyboardKey.metaRight) {
      return _isMacOS ? '⌘' : 'Win';
    }
    if (key == LogicalKeyboardKey.control ||
        key == LogicalKeyboardKey.controlLeft ||
        key == LogicalKeyboardKey.controlRight) {
      return _isMacOS ? '⌃' : 'Ctrl';
    }
    if (key == LogicalKeyboardKey.shift ||
        key == LogicalKeyboardKey.shiftLeft ||
        key == LogicalKeyboardKey.shiftRight) {
      return _isMacOS ? '⇧' : 'Shift';
    }
    if (key == LogicalKeyboardKey.alt ||
        key == LogicalKeyboardKey.altLeft ||
        key == LogicalKeyboardKey.altRight) {
      return _isMacOS ? '⌥' : 'Alt';
    }

    // Handle arrow keys
    if (key == LogicalKeyboardKey.arrowUp) return '↑';
    if (key == LogicalKeyboardKey.arrowDown) return '↓';
    if (key == LogicalKeyboardKey.arrowLeft) return '←';
    if (key == LogicalKeyboardKey.arrowRight) return '→';

    // Handle special keys
    if (key == LogicalKeyboardKey.escape) return 'Esc';
    if (key == LogicalKeyboardKey.delete) return 'Del';
    if (key == LogicalKeyboardKey.backspace) return '⌫';
    if (key == LogicalKeyboardKey.enter) return '↵';
    if (key == LogicalKeyboardKey.space) return 'Space';
    if (key == LogicalKeyboardKey.tab) return 'Tab';

    // Handle function keys
    if (key.keyLabel.startsWith('F') && key.keyLabel.length <= 3) {
      return key.keyLabel;
    }

    // Handle numeric keys
    if (key == LogicalKeyboardKey.digit0) return '0';
    if (key == LogicalKeyboardKey.digit1) return '1';
    if (key == LogicalKeyboardKey.digit2) return '2';
    if (key == LogicalKeyboardKey.digit3) return '3';
    if (key == LogicalKeyboardKey.digit4) return '4';
    if (key == LogicalKeyboardKey.digit5) return '5';
    if (key == LogicalKeyboardKey.digit6) return '6';
    if (key == LogicalKeyboardKey.digit7) return '7';
    if (key == LogicalKeyboardKey.digit8) return '8';
    if (key == LogicalKeyboardKey.digit9) return '9';

    // Handle letter keys
    if (key.keyLabel.length == 1) {
      return key.keyLabel.toUpperCase();
    }

    // Handle special character keys
    if (key == LogicalKeyboardKey.minus) return '-';
    if (key == LogicalKeyboardKey.equal) return '=';
    if (key == LogicalKeyboardKey.bracketLeft) return '[';
    if (key == LogicalKeyboardKey.bracketRight) return ']';

    // Default to key label
    return key.keyLabel;
  }
}

/// Internal data class that pairs a keyboard shortcut with its action.
///
/// This class is used internally by [ShortcutsViewerDialog] to organize
/// shortcuts for display. It combines the keyboard combination with the
/// action metadata needed for rendering.
class _ShortcutInfo {
  const _ShortcutInfo({required this.keySet, required this.action});

  /// The keyboard combination that triggers this action.
  final LogicalKeySet keySet;

  /// The action that is triggered by this keyboard shortcut.
  ///
  /// Contains metadata like label, description, and category.
  final NodeFlowAction action;
}
