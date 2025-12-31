import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:vyuh_node_flow/vyuh_node_flow.dart';

import '../shared/ui_widgets.dart';

/// Example demonstrating visibility toggling for nodes and annotations.
///
/// Features:
/// - List of all nodes and annotations in a side panel
/// - Eye icon to toggle visibility for each element
/// - Add nodes and annotations dynamically
/// - Visual feedback when elements are hidden
class VisibilityExample extends StatefulWidget {
  const VisibilityExample({super.key});

  @override
  State<VisibilityExample> createState() => _VisibilityExampleState();
}

class _VisibilityExampleState extends State<VisibilityExample> {
  late final NodeFlowController<Map<String, dynamic>, dynamic> controller;
  late final NodeFlowTheme _theme;
  final _random = math.Random();
  int _nodeCounter = 0;

  @override
  void initState() {
    super.initState();
    _theme = NodeFlowTheme.light;
    controller = NodeFlowController<Map<String, dynamic>, dynamic>(
      config: NodeFlowConfig(),
    );
    _setupExampleGraph();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      controller.resetViewport();
    });
  }

  void _setupExampleGraph() {
    // Create initial nodes
    final node1 = Node<Map<String, dynamic>>(
      id: 'node1',
      type: 'process',
      position: const Offset(100, 100),
      size: const Size(140, 70),
      data: {'title': 'Node 1'},
      outputPorts: [
        Port(
          id: 'output1',
          name: 'Out',
          position: PortPosition.right,
          offset: const Offset(2, 35),
        ),
      ],
      inputPorts: [
        Port(
          id: 'input1',
          name: 'In',
          position: PortPosition.left,
          offset: const Offset(-2, 35),
        ),
      ],
    );

    final node2 = Node<Map<String, dynamic>>(
      id: 'node2',
      type: 'process',
      position: const Offset(300, 100),
      size: const Size(140, 70),
      data: {'title': 'Node 2'},
      outputPorts: [
        Port(
          id: 'output1',
          name: 'Out',
          position: PortPosition.right,
          offset: const Offset(2, 35),
        ),
      ],
      inputPorts: [
        Port(
          id: 'input1',
          name: 'In',
          position: PortPosition.left,
          offset: const Offset(-2, 35),
        ),
      ],
    );

    final node3 = Node<Map<String, dynamic>>(
      id: 'node3',
      type: 'process',
      position: const Offset(500, 100),
      size: const Size(140, 70),
      data: {'title': 'Node 3'},
      outputPorts: [
        Port(
          id: 'output1',
          name: 'Out',
          position: PortPosition.right,
          offset: const Offset(2, 35),
        ),
      ],
      inputPorts: [
        Port(
          id: 'input1',
          name: 'In',
          position: PortPosition.left,
          offset: const Offset(-2, 35),
        ),
      ],
    );

    final node4 = Node<Map<String, dynamic>>(
      id: 'node4',
      type: 'process',
      position: const Offset(200, 250),
      size: const Size(140, 70),
      data: {'title': 'Node 4'},
      outputPorts: [
        Port(
          id: 'output1',
          name: 'Out',
          position: PortPosition.right,
          offset: const Offset(2, 35),
        ),
      ],
      inputPorts: [
        Port(
          id: 'input1',
          name: 'In',
          position: PortPosition.left,
          offset: const Offset(-2, 35),
        ),
      ],
    );

    final node5 = Node<Map<String, dynamic>>(
      id: 'node5',
      type: 'process',
      position: const Offset(400, 250),
      size: const Size(140, 70),
      data: {'title': 'Node 5'},
      outputPorts: [
        Port(
          id: 'output1',
          name: 'Out',
          position: PortPosition.right,
          offset: const Offset(2, 35),
        ),
      ],
      inputPorts: [
        Port(
          id: 'input1',
          name: 'In',
          position: PortPosition.left,
          offset: const Offset(-2, 35),
        ),
      ],
    );

    _nodeCounter = 5;

    controller
      ..addNode(node1)
      ..addNode(node2)
      ..addNode(node3)
      ..addNode(node4)
      ..addNode(node5);

    // Add connections
    controller.addConnection(
      Connection(
        id: 'conn1',
        sourceNodeId: 'node1',
        sourcePortId: 'output1',
        targetNodeId: 'node2',
        targetPortId: 'input1',
      ),
    );
    controller.addConnection(
      Connection(
        id: 'conn2',
        sourceNodeId: 'node2',
        sourcePortId: 'output1',
        targetNodeId: 'node3',
        targetPortId: 'input1',
      ),
    );
    controller.addConnection(
      Connection(
        id: 'conn3',
        sourceNodeId: 'node4',
        sourcePortId: 'output1',
        targetNodeId: 'node5',
        targetPortId: 'input1',
      ),
    );

    // Add initial comment nodes
    controller.addNode(
      CommentNode<Map<String, dynamic>>(
        id: 'comment1',
        position: const Offset(100, 350),
        text: 'Comment Note 1',
        data: {},
        color: Colors.yellow,
      ),
    );
  }

  void _addNode() {
    _nodeCounter++;
    final x = 100.0 + _random.nextDouble() * 400;
    final y = 100.0 + _random.nextDouble() * 300;

    final node = Node<Map<String, dynamic>>(
      id: 'node$_nodeCounter',
      type: 'process',
      position: Offset(x, y),
      size: const Size(140, 70),
      data: {'title': 'Node $_nodeCounter'},
      outputPorts: [
        Port(
          id: 'output1',
          name: 'Out',
          position: PortPosition.right,
          offset: const Offset(2, 35),
        ),
      ],
      inputPorts: [
        Port(
          id: 'input1',
          name: 'In',
          position: PortPosition.left,
          offset: const Offset(-2, 35),
        ),
      ],
    );

    controller.addNode(node);
  }

  void _addCommentNote() {
    final x = 50.0 + _random.nextDouble() * 500;
    final y = 50.0 + _random.nextDouble() * 350;
    final id = 'comment_${DateTime.now().millisecondsSinceEpoch}';

    controller.addNode(
      CommentNode<Map<String, dynamic>>(
        id: id,
        position: Offset(x, y),
        text: 'New comment note',
        data: {},
        color: _randomColor(),
      ),
    );
  }

  void _addGroup() {
    final x = 50.0 + _random.nextDouble() * 400;
    final y = 50.0 + _random.nextDouble() * 250;
    final id = 'group_${DateTime.now().millisecondsSinceEpoch}';

    controller.addNode(
      GroupNode<Map<String, dynamic>>(
        id: id,
        title: 'New Group',
        position: Offset(x, y),
        size: const Size(200, 150),
        data: {},
        color: _randomGroupColor(),
        behavior: GroupBehavior.bounds,
      ),
    );
  }

  Color _randomGroupColor() {
    final colors = [
      Colors.blue,
      Colors.purple,
      Colors.teal,
      Colors.indigo,
      Colors.cyan,
    ];
    return colors[_random.nextInt(colors.length)];
  }

  Color _randomColor() {
    final colors = [
      Colors.yellow,
      Colors.green.shade200,
      Colors.blue.shade200,
      Colors.pink.shade200,
      Colors.orange.shade200,
    ];
    return colors[_random.nextInt(colors.length)];
  }

  void _showAll() {
    // Show all nodes (including comment and group nodes)
    for (final node in controller.nodes.values) {
      node.isVisible = true;
    }
  }

  void _hideAll() {
    // Hide all nodes (including comment and group nodes)
    for (final node in controller.nodes.values) {
      node.isVisible = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return ResponsiveControlPanel(
      controller: controller,
      onReset: () {
        controller.clearGraph();
        _setupExampleGraph();
      },
      child: Stack(
        children: [
          NodeFlowEditor<Map<String, dynamic>, dynamic>(
            controller: controller,
            theme: _theme,
            nodeBuilder: (context, node) =>
                _NodeWidget(node: node, nodeFlowTheme: _theme),
          ),
        ],
      ),
      children: [
        const InfoCard(
          title: 'Instructions',
          content:
              'Toggle visibility of all node types using the eye icons. '
              'Hidden elements disappear from the canvas but remain in the list. '
              'Connections to hidden nodes are also hidden.',
        ),
        const SizedBox(height: 24),
        const SectionTitle('Add Elements'),
        const SizedBox(height: 8),
        Grid2Cols(
          buttons: [
            GridButton(label: 'Node', icon: Icons.add_box, onPressed: _addNode),
            GridButton(
              label: 'Comment',
              icon: Icons.sticky_note_2,
              onPressed: _addCommentNote,
            ),
            GridButton(
              label: 'Group',
              icon: Icons.group_work,
              onPressed: _addGroup,
            ),
            GridButton(
              label: 'Show All',
              icon: Icons.visibility,
              onPressed: _showAll,
            ),
          ],
        ),
        const SizedBox(height: 8),
        ControlButton(
          label: 'Hide All',
          icon: Icons.visibility_off,
          onPressed: _hideAll,
        ),
        const SizedBox(height: 24),
        const SectionTitle('All Nodes'),
        const SizedBox(height: 8),
        _NodeList(controller: controller),
      ],
    );
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }
}

/// Simple node widget
class _NodeWidget extends StatelessWidget {
  const _NodeWidget({required this.node, required this.nodeFlowTheme});

  final Node<Map<String, dynamic>> node;
  final NodeFlowTheme nodeFlowTheme;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final nodeColor = isDark
        ? const Color(0xFF2D3E52)
        : const Color(0xFFD4E7F7);
    final textColor = isDark
        ? const Color(0xFF88B8E6)
        : const Color(0xFF1B4D7A);

    // Calculate inner border radius (outer radius minus border width)
    final outerRadius = nodeFlowTheme.nodeTheme.borderRadius.topLeft.x;
    final borderWidth = nodeFlowTheme.nodeTheme.borderWidth;
    final innerRadius = (outerRadius - borderWidth).clamp(0.0, double.infinity);

    return Container(
      width: node.size.value.width,
      height: node.size.value.height,
      decoration: BoxDecoration(
        color: nodeColor,
        borderRadius: BorderRadius.circular(innerRadius),
      ),
      child: Center(
        child: Text(
          node.data['title'] as String? ?? node.id,
          style: theme.textTheme.titleSmall?.copyWith(color: textColor),
        ),
      ),
    );
  }
}

/// List of all nodes (including comment and group nodes) with visibility toggles
class _NodeList extends StatelessWidget {
  const _NodeList({required this.controller});

  final NodeFlowController<Map<String, dynamic>, dynamic> controller;

  @override
  Widget build(BuildContext context) {
    return Observer(
      builder: (_) {
        final nodes = controller.nodes.values.toList()
          ..sort((a, b) => a.id.compareTo(b.id));

        if (nodes.isEmpty) {
          return const _EmptyListMessage(message: 'No nodes');
        }

        return Column(
          children: nodes
              .map(
                (node) => _VisibilityTile(
                  id: node.id,
                  title: _getNodeTitle(node),
                  icon: _getNodeIcon(node),
                  isVisible: node.isVisible,
                  onToggle: () {
                    node.isVisible = !node.isVisible;
                  },
                  onTap: () {
                    controller.selectNode(node.id);
                  },
                ),
              )
              .toList(),
        );
      },
    );
  }

  String _getNodeTitle(Node node) {
    if (node is CommentNode) {
      final text = node.text;
      return text.length > 20 ? '${text.substring(0, 20)}...' : text;
    } else if (node is GroupNode) {
      final title = node.currentTitle;
      return title.isNotEmpty ? title : 'Group';
    } else if (node.data is Map && (node.data as Map).containsKey('title')) {
      return (node.data as Map)['title'] as String? ?? node.id;
    }
    return node.id;
  }

  IconData _getNodeIcon(Node node) {
    if (node is CommentNode) {
      return Icons.sticky_note_2;
    } else if (node is GroupNode) {
      return Icons.group_work;
    }
    return Icons.crop_square;
  }
}

/// Empty list placeholder
class _EmptyListMessage extends StatelessWidget {
  const _EmptyListMessage({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Text(
        message,
        style: theme.textTheme.bodySmall?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
          fontStyle: FontStyle.italic,
        ),
      ),
    );
  }
}

/// Tile for a single element with visibility toggle
class _VisibilityTile extends StatelessWidget {
  const _VisibilityTile({
    required this.id,
    required this.title,
    required this.icon,
    required this.isVisible,
    required this.onToggle,
    required this.onTap,
  });

  final String id;
  final String title;
  final IconData icon;
  final bool isVisible;
  final VoidCallback onToggle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      decoration: BoxDecoration(
        color: isVisible
            ? theme.colorScheme.surfaceContainerLowest
            : theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isVisible
              ? theme.colorScheme.outlineVariant
              : theme.colorScheme.outline.withValues(alpha: 0.3),
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              children: [
                Icon(
                  icon,
                  size: 18,
                  color: isVisible
                      ? theme.colorScheme.primary
                      : theme.colorScheme.onSurface.withValues(alpha: 0.4),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    title,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: isVisible
                          ? theme.colorScheme.onSurface
                          : theme.colorScheme.onSurface.withValues(alpha: 0.4),
                      decoration: isVisible ? null : TextDecoration.lineThrough,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                IconButton(
                  icon: Icon(
                    isVisible ? Icons.visibility : Icons.visibility_off,
                    size: 20,
                    color: isVisible
                        ? theme.colorScheme.primary
                        : theme.colorScheme.onSurface.withValues(alpha: 0.4),
                  ),
                  onPressed: onToggle,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(
                    minWidth: 32,
                    minHeight: 32,
                  ),
                  tooltip: isVisible ? 'Hide' : 'Show',
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
