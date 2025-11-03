import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:vyuh_node_flow/vyuh_node_flow.dart';

import '../../shared/ui_widgets.dart';

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
  late NodeFlowController<Map<String, dynamic>> _controller;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _initializeController();
    _loadManufacturingWorkflow();
  }

  void _initializeController() {
    final config = NodeFlowConfig(showMinimap: true, snapToGrid: false);

    _controller = NodeFlowController<Map<String, dynamic>>(config: config);

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
        _showSnackBar('Error loading workflow: $e');
      }
    }
  }

  void _showSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), duration: const Duration(seconds: 2)),
    );
  }

  void _showShortcutsDialog() {
    showDialog(
      context: context,
      builder: (context) => ShortcutsViewerDialog(
        shortcuts: _controller.shortcuts.shortcuts,
        actions: _controller.shortcuts.actions,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return ResponsiveControlPanel(
      title: 'Keyboard Shortcuts',
      width: 320,
      child: NodeFlowEditor<Map<String, dynamic>>(
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
    final theme = Theme.of(context);

    return [
      _buildShortcutCategory('Selection', [
        _buildShortcutRow('Cmd/Ctrl + A', 'Select all nodes'),
        _buildShortcutRow('Cmd/Ctrl + I', 'Invert selection'),
        _buildShortcutRow('Escape', 'Clear selection'),
        _buildShortcutRow('Shift + Drag', 'Multi-select'),
      ]),
      const SizedBox(height: 16),
      _buildShortcutCategory('Editing', [
        _buildShortcutRow('Delete/Backspace', 'Delete selected'),
        _buildShortcutRow('Cmd/Ctrl + D', 'Duplicate'),
        _buildShortcutRow('Cmd/Ctrl + C', 'Copy'),
        _buildShortcutRow('Cmd/Ctrl + V', 'Paste'),
      ]),
      const SizedBox(height: 16),
      _buildShortcutCategory('Navigation', [
        _buildShortcutRow('F', 'Fit to view'),
        _buildShortcutRow('H', 'Fit selected'),
        _buildShortcutRow('Cmd/Ctrl + 0', 'Reset zoom'),
        _buildShortcutRow('Cmd/Ctrl + =', 'Zoom in'),
        _buildShortcutRow('Cmd/Ctrl + -', 'Zoom out'),
      ]),
      const SizedBox(height: 16),
      _buildShortcutCategory('Custom', [
        _buildShortcutRow('Cmd/Ctrl + S', 'Save workflow', custom: true),
        _buildShortcutRow('Cmd/Ctrl + E', 'Export graph', custom: true),
      ]),
      const SizedBox(height: 24),
      ElevatedButton.icon(
        onPressed: _showShortcutsDialog,
        icon: const Icon(Icons.keyboard),
        label: const Text('View All Shortcuts'),
        style: ElevatedButton.styleFrom(
          minimumSize: const Size(double.infinity, 48),
        ),
      ),
      const SizedBox(height: 16),
      Observer(
        builder: (_) => Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Graph Stats',
                style: theme.textTheme.labelSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              _buildStatRow('Nodes', _controller.nodes.length.toString()),
              _buildStatRow(
                'Connections',
                _controller.connections.length.toString(),
              ),
              _buildStatRow(
                'Selected',
                _controller.selectedNodeIds.length.toString(),
              ),
            ],
          ),
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

  Widget _buildStatRow(String label, String value) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: theme.textTheme.bodySmall),
          Text(
            value,
            style: theme.textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.bold,
              fontFamily: 'monospace',
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
    NodeFlowController<Map<String, dynamic>> controller,
    BuildContext? context,
  ) {
    if (context != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Save triggered! (Custom shortcut: Cmd/Ctrl + S)'),
          duration: Duration(seconds: 2),
        ),
      );
    }
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
    NodeFlowController<Map<String, dynamic>> controller,
    BuildContext? context,
  ) {
    if (context != null) {
      final graph = controller.exportGraph();
      final jsonString = graph.toJsonString(indent: true);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Export triggered! Graph has ${graph.nodes.length} nodes',
          ),
          duration: const Duration(seconds: 2),
          action: SnackBarAction(
            label: 'Copy JSON',
            onPressed: () {
              Clipboard.setData(ClipboardData(text: jsonString));
            },
          ),
        ),
      );
    }
    return true;
  }
}
