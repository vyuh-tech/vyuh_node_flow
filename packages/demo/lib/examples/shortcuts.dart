import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:vyuh_node_flow/vyuh_node_flow.dart';

import '../shared/ui_widgets.dart';

/// A comprehensive example showcasing keyboard shortcuts and the Actions/Shortcuts system.
///
/// This example demonstrates:
/// - All default keyboard shortcuts
/// - Shortcuts viewer dialog
/// - Custom shortcuts
/// - Visual hints and help overlay
/// - Real-time shortcut feedback
class ShortcutsExample extends StatefulWidget {
  const ShortcutsExample({super.key});

  @override
  State<ShortcutsExample> createState() => _ShortcutsExampleState();
}

class _ShortcutsExampleState extends State<ShortcutsExample> {
  late NodeFlowController<Map<String, dynamic>, dynamic> _controller;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _initializeController();
    _loadManufacturingWorkflow();
  }

  void _initializeController() {
    final config = NodeFlowConfig(
      snapToGrid: false,
      extensions: [
        MinimapExtension(config: const MinimapConfig(visible: true)),
        StatsExtension(),
        ...NodeFlowConfig.defaultExtensions().where(
          (e) => e is! MinimapExtension,
        ),
      ],
    );

    _controller = NodeFlowController<Map<String, dynamic>, dynamic>(
      config: config,
    );

    // Add a custom shortcut: Cmd/Ctrl + S to save (just shows a message)
    _controller.shortcuts.setShortcut(
      LogicalKeySet(LogicalKeyboardKey.keyS, LogicalKeyboardKey.meta),
      'custom_save',
    );
    _controller.shortcuts.setShortcut(
      LogicalKeySet(LogicalKeyboardKey.keyS, LogicalKeyboardKey.control),
      'custom_save',
    );

    // Add a custom shortcut: Cmd/Ctrl + E to export
    _controller.shortcuts.setShortcut(
      LogicalKeySet(LogicalKeyboardKey.keyE, LogicalKeyboardKey.meta),
      'custom_export',
    );
    _controller.shortcuts.setShortcut(
      LogicalKeySet(LogicalKeyboardKey.keyE, LogicalKeyboardKey.control),
      'custom_export',
    );

    // Register custom actions
    _controller.shortcuts.registerAction(_CustomSaveAction());
    _controller.shortcuts.registerAction(_CustomExportAction());
  }

  Future<void> _loadManufacturingWorkflow() async {
    try {
      final graph = await NodeGraph.fromAssetMap(
        'assets/data/manufacturing_workflow.json',
      );

      if (mounted) {
        setState(() {
          _controller.loadGraph(graph);
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _showShortcutsDialog() {
    final shortcuts = _controller.shortcuts.keyMap;
    final actions = _controller.shortcuts.actions;

    showDialog(
      context: context,
      builder: (context) =>
          _SimpleShortcutsDialog(shortcuts: shortcuts, actions: actions),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return ResponsiveControlPanel(
      controller: _controller,
      onReset: () {
        _controller.clearGraph();
        _loadManufacturingWorkflow();
      },
      child: NodeFlowEditor<Map<String, dynamic>, dynamic>(
        controller: _controller,
        theme: NodeFlowTheme.light,
        nodeBuilder: _buildNode,
      ),
      children: _buildSidePanelChildren(),
    );
  }

  Widget _buildNode(BuildContext context, Node<Map<String, dynamic>> node) {
    final theme = Theme.of(context);
    final nodeType = node.data['name'] ?? node.type;

    // Get the theme values - using NodeFlowTheme.light
    final nodeFlowTheme = NodeFlowTheme.light;
    final themeBorderRadius = nodeFlowTheme.nodeTheme.borderRadius.topLeft.x;
    final themeBorderWidth = nodeFlowTheme.nodeTheme.borderWidth;
    final innerBorderRadius = themeBorderRadius - themeBorderWidth;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(innerBorderRadius),
        boxShadow: node.isSelected
            ? [
                BoxShadow(
                  color: theme.colorScheme.primary.withValues(alpha: 0.3),
                  blurRadius: 8,
                  spreadRadius: 2,
                ),
              ]
            : [
                BoxShadow(
                  color: theme.shadowColor.withValues(alpha: 0.1),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            nodeType,
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          ...[
            const SizedBox(height: 4),
            Text(
              node.type,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.textTheme.bodySmall?.color?.withValues(alpha: 0.6),
              ),
            ),
          ],
        ],
      ),
    );
  }

  List<Widget> _buildSidePanelChildren() {
    return [
      const SectionTitle('Shortcuts'),
      SectionContent(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildShortcutCategory('Selection', [
              _buildShortcutRow('Cmd/Ctrl + A', 'Select all nodes'),
              _buildShortcutRow('Cmd/Ctrl + I', 'Invert selection'),
              _buildShortcutRow('Escape', 'Clear selection'),
              _buildShortcutRow('Shift + Drag', 'Multi-select'),
            ]),
            const SizedBox(height: 12),
            _buildShortcutCategory('Editing', [
              _buildShortcutRow('Delete/Backspace', 'Delete selected'),
              _buildShortcutRow('Cmd/Ctrl + D', 'Duplicate'),
              _buildShortcutRow('Cmd/Ctrl + C', 'Copy'),
              _buildShortcutRow('Cmd/Ctrl + V', 'Paste'),
            ]),
            const SizedBox(height: 12),
            _buildShortcutCategory('Navigation', [
              _buildShortcutRow('F', 'Fit to view'),
              _buildShortcutRow('H', 'Fit selected'),
              _buildShortcutRow('Cmd/Ctrl + 0', 'Reset zoom'),
              _buildShortcutRow('Cmd/Ctrl + =', 'Zoom in'),
              _buildShortcutRow('Cmd/Ctrl + -', 'Zoom out'),
            ]),
            const SizedBox(height: 12),
            _buildShortcutCategory('Custom', [
              _buildShortcutRow('Cmd/Ctrl + S', 'Save workflow', custom: true),
              _buildShortcutRow('Cmd/Ctrl + E', 'Export graph', custom: true),
            ]),
          ],
        ),
      ),
      const SectionTitle('Actions'),
      SectionContent(
        child: ControlButton(
          icon: Icons.keyboard,
          label: 'View All Shortcuts',
          onPressed: _showShortcutsDialog,
        ),
      ),
    ];
  }

  Widget _buildShortcutCategory(String title, List<Widget> shortcuts) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title.toUpperCase(),
          style: theme.textTheme.labelSmall?.copyWith(
            fontWeight: FontWeight.bold,
            letterSpacing: 0.5,
            color: theme.colorScheme.primary,
          ),
        ),
        const SizedBox(height: 8),
        ...shortcuts,
      ],
    );
  }

  Widget _buildShortcutRow(
    String keys,
    String description, {
    bool custom = false,
  }) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Text(
              keys,
              style: theme.textTheme.bodySmall?.copyWith(
                fontFamily: 'monospace',
                fontWeight: FontWeight.w500,
                color: custom ? theme.colorScheme.secondary : null,
              ),
            ),
          ),
          Expanded(
            flex: 4,
            child: Text(
              description,
              style: theme.textTheme.bodySmall,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}

// Custom action for saving
class _CustomSaveAction extends NodeFlowAction<Map<String, dynamic>> {
  const _CustomSaveAction()
    : super(
        id: 'custom_save',
        label: 'Save Workflow',
        description: 'Save the current workflow (custom action)',
        category: 'Custom',
      );

  @override
  bool execute(
    NodeFlowController<Map<String, dynamic>, dynamic> controller,
    BuildContext? context,
  ) {
    // Custom save action - in a real app, this would persist the workflow
    final graph = controller.exportGraph();
    final jsonString = graph.toJsonString(indent: true);
    Clipboard.setData(ClipboardData(text: jsonString));
    return true;
  }
}

// Custom action for exporting
class _CustomExportAction extends NodeFlowAction<Map<String, dynamic>> {
  const _CustomExportAction()
    : super(
        id: 'custom_export',
        label: 'Export Graph',
        description: 'Export the graph to JSON (custom action)',
        category: 'Custom',
      );

  @override
  bool execute(
    NodeFlowController<Map<String, dynamic>, dynamic> controller,
    BuildContext? context,
  ) {
    final graph = controller.exportGraph();
    final jsonString = graph.toJsonString(indent: true);
    Clipboard.setData(ClipboardData(text: jsonString));
    return true;
  }
}

/// A simple shortcuts dialog built by the demo.
///
/// This demonstrates how external code can build its own shortcuts UI
/// using the data from controller.shortcuts.keyMap and controller.shortcuts.actions.
class _SimpleShortcutsDialog extends StatelessWidget {
  const _SimpleShortcutsDialog({
    required this.shortcuts,
    required this.actions,
  });

  final Map<LogicalKeySet, String> shortcuts;
  final Map<String, NodeFlowAction> actions;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // Group shortcuts by category
    final categorized = <String, List<MapEntry<LogicalKeySet, String>>>{};
    for (final entry in shortcuts.entries) {
      final action = actions[entry.value];
      final category = action?.category ?? 'General';
      categorized.putIfAbsent(category, () => []).add(entry);
    }

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        width: 500,
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.7,
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
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
            const SizedBox(height: 16),
            Flexible(
              child: ListView(
                shrinkWrap: true,
                children: [
                  for (final category in categorized.keys) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primaryContainer.withValues(
                          alpha: 0.3,
                        ),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        category.toUpperCase(),
                        style: theme.textTheme.labelSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    for (final entry in categorized[category]!)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8, left: 8),
                        child: Row(
                          children: [
                            SizedBox(
                              width: 150,
                              child: Text(
                                _formatKeySet(entry.key),
                                style: theme.textTheme.bodySmall?.copyWith(
                                  fontFamily: 'monospace',
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                            Expanded(
                              child: Text(
                                actions[entry.value]?.label ?? entry.value,
                                style: theme.textTheme.bodySmall,
                              ),
                            ),
                          ],
                        ),
                      ),
                    const SizedBox(height: 12),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatKeySet(LogicalKeySet keySet) {
    final keys = keySet.keys.toList();
    // Sort modifiers first
    keys.sort((a, b) {
      final aIsModifier = _isModifier(a);
      final bIsModifier = _isModifier(b);
      if (aIsModifier && !bIsModifier) return -1;
      if (!aIsModifier && bIsModifier) return 1;
      return 0;
    });
    return keys.map(_keyLabel).join(' + ');
  }

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

  String _keyLabel(LogicalKeyboardKey key) {
    if (key == LogicalKeyboardKey.meta ||
        key == LogicalKeyboardKey.metaLeft ||
        key == LogicalKeyboardKey.metaRight) {
      return '⌘';
    }
    if (key == LogicalKeyboardKey.control ||
        key == LogicalKeyboardKey.controlLeft ||
        key == LogicalKeyboardKey.controlRight) {
      return 'Ctrl';
    }
    if (key == LogicalKeyboardKey.shift ||
        key == LogicalKeyboardKey.shiftLeft ||
        key == LogicalKeyboardKey.shiftRight) {
      return '⇧';
    }
    if (key == LogicalKeyboardKey.alt ||
        key == LogicalKeyboardKey.altLeft ||
        key == LogicalKeyboardKey.altRight) {
      return '⌥';
    }
    if (key == LogicalKeyboardKey.arrowUp) return '↑';
    if (key == LogicalKeyboardKey.arrowDown) return '↓';
    if (key == LogicalKeyboardKey.arrowLeft) return '←';
    if (key == LogicalKeyboardKey.arrowRight) return '→';
    if (key == LogicalKeyboardKey.escape) return 'Esc';
    if (key == LogicalKeyboardKey.delete) return 'Del';
    if (key == LogicalKeyboardKey.backspace) return '⌫';
    if (key.keyLabel.length == 1) return key.keyLabel.toUpperCase();
    return key.keyLabel;
  }
}
