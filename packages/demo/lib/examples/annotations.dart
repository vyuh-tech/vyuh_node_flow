import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:vyuh_node_flow/vyuh_node_flow.dart';

import '../shared/ui_widgets.dart';

/// Example showing how to use comment nodes and group nodes (formerly the annotation system)
class AnnotationExample extends StatefulWidget {
  const AnnotationExample({super.key});

  @override
  State<AnnotationExample> createState() => _AnnotationExampleState();
}

class _AnnotationExampleState extends State<AnnotationExample> {
  final _theme = NodeFlowTheme.light;
  final controller = NodeFlowController<Map<String, dynamic>, dynamic>(
    config: NodeFlowConfig(),
  );

  @override
  void initState() {
    super.initState();
    _setupExampleGraph();
  }

  void _setupExampleGraph() {
    // Create some example nodes with ports
    final node1 = Node<Map<String, dynamic>>(
      id: 'node1',
      type: 'process',
      position: const Offset(100, 100),
      size: const Size(150, 80),
      data: {'title': 'Process A'},
      ports: [
        Port(
          id: 'output1',
          name: 'Out',
          type: PortType.output,
          position: PortPosition.right,
          offset: Offset(2, 40), // Vertical center of 80 height
        ),
        Port(
          id: 'input1',
          name: 'In',
          type: PortType.input,
          position: PortPosition.left,
          offset: Offset(-2, 40), // Vertical center of 80 height
        ),
      ],
    );

    final node2 = Node<Map<String, dynamic>>(
      id: 'node2',
      type: 'process',
      position: const Offset(300, 100),
      size: const Size(150, 80),
      data: {'title': 'Process B'},
      ports: [
        Port(
          id: 'output1',
          name: 'Out',
          type: PortType.output,
          position: PortPosition.right,
          offset: Offset(2, 40), // Vertical center of 80 height
        ),
        Port(
          id: 'input1',
          name: 'In',
          type: PortType.input,
          position: PortPosition.left,
          offset: Offset(-2, 40), // Vertical center of 80 height
        ),
      ],
    );

    final node3 = Node<Map<String, dynamic>>(
      id: 'node3',
      type: 'process',
      position: const Offset(200, 250),
      size: const Size(150, 80),
      data: {'title': 'Process C'},
      ports: [
        Port(
          id: 'output1',
          name: 'Out',
          type: PortType.output,
          position: PortPosition.right,
          offset: Offset(2, 40), // Vertical center of 80 height
        ),
        Port(
          id: 'input1',
          name: 'In',
          type: PortType.input,
          position: PortPosition.left,
          offset: Offset(-2, 20), // Multiple ports: starting offset 20
        ),
        Port(
          id: 'input2',
          name: 'In2',
          type: PortType.input,
          position: PortPosition.left,
          offset: Offset(-2, 50), // Multiple ports: 20 + 30 separation
        ),
      ],
    );

    controller.addNode(node1);
    controller.addNode(node2);
    controller.addNode(node3);

    // Add connections between nodes
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
        sourceNodeId: 'node1',
        sourcePortId: 'output1',
        targetNodeId: 'node3',
        targetPortId: 'input1',
      ),
    );

    controller.addConnection(
      Connection(
        id: 'conn3',
        sourceNodeId: 'node2',
        sourcePortId: 'output1',
        targetNodeId: 'node3',
        targetPortId: 'input2',
      ),
    );

    // Create different types of nodes (formerly annotations)

    // 1. Comment node (free-floating, formerly sticky note)
    controller.addNode(
      CommentNode<Map<String, dynamic>>(
        id: 'comment1',
        position: const Offset(400, 50),
        text: 'This is a comment node!\n\nYou can drag me around.',
        data: {},
        width: 180,
        height: 120,
        color: Colors.yellow.shade200,
      ),
    );

    // 2. Group node (surrounds nodes)
    // Calculate bounds for nodes
    final node1Bounds = controller.getNode('node1')!.getBounds();
    final node2Bounds = controller.getNode('node2')!.getBounds();
    final groupBounds = node1Bounds.expandToInclude(node2Bounds);
    final padding = const EdgeInsets.all(30);

    controller.addNode(
      GroupNode<Map<String, dynamic>>(
        id: 'group1',
        position: Offset(
          groupBounds.left - padding.left,
          groupBounds.top - padding.top,
        ),
        size: Size(
          groupBounds.width + padding.left + padding.right,
          groupBounds.height + padding.top + padding.bottom,
        ),
        title: 'Core Processes',
        data: {},
        color: Colors.blue.shade300,
        behavior: GroupBehavior.explicit,
        nodeIds: {'node1', 'node2'},
        padding: padding,
      ),
    );

    // 3. MarkerAnnotation has been REMOVED - no replacement needed
    // (If you need markers, consider using CommentNode with smaller dimensions)

    // 4. Simple comment node near a node
    controller.addNode(
      CommentNode<Map<String, dynamic>>(
        id: 'comment2',
        position: const Offset(250, 350),
        text: 'Note for Process C\nContext and details here',
        data: {},
        width: 180,
        height: 80,
        color: Colors.green.shade200,
      ),
    );

    // 5. Another group for demonstration
    final allNodesBounds = [
      controller.getNode('node1')!.getBounds(),
      controller.getNode('node2')!.getBounds(),
      controller.getNode('node3')!.getBounds(),
    ].reduce((a, b) => a.expandToInclude(b));
    final padding2 = const EdgeInsets.all(50);

    final group2 = GroupNode<Map<String, dynamic>>(
      id: 'group2',
      position: Offset(
        allNodesBounds.left - padding2.left,
        allNodesBounds.top - padding2.top,
      ),
      size: Size(
        allNodesBounds.width + padding2.left + padding2.right,
        allNodesBounds.height + padding2.top + padding2.bottom,
      ),
      title: 'All Processes',
      data: {},
      color: Colors.purple.shade300,
      behavior: GroupBehavior.explicit,
      // Include child group 'group1' so it moves with parent and gets correct z-index
      nodeIds: {'node1', 'node2', 'node3', 'group1'},
      padding: padding2,
      zIndex: -1, // Put this group behind others
    );
    controller.addNode(group2);
  }

  @override
  Widget build(BuildContext context) {
    return ResponsiveControlPanel(
      controller: controller,
      onReset: () {
        controller.clearGraph();
        _setupExampleGraph();
        controller.resetViewport();
      },
      child: Stack(
        children: [
          // Use the actual NodeFlowEditor which handles all interactions properly
          NodeFlowEditor<Map<String, dynamic>, dynamic>(
            controller: controller,
            theme: _theme,
            events: NodeFlowEvents(onInit: () => controller.resetViewport()),
            nodeBuilder: (context, node) {
              // Calculate inner border radius
              final outerBorderRadius = _theme.nodeTheme.borderRadius;
              final borderWidth = _theme.nodeTheme.borderWidth;
              final outerRadius = outerBorderRadius.topLeft.x;
              final innerRadius = math.max(0.0, outerRadius - borderWidth);

              final theme = Theme.of(context);
              final isDark = theme.brightness == Brightness.dark;

              // Soft sky blue
              final nodeColor = isDark
                  ? const Color(0xFF2D3E52)
                  : const Color(0xFFD4E7F7);
              final iconColor = isDark
                  ? const Color(0xFF88B8E6)
                  : const Color(0xFF1B4D7A);

              return Container(
                width: node.size.value.width,
                height: node.size.value.height,
                decoration: BoxDecoration(
                  color: nodeColor,
                  borderRadius: BorderRadius.circular(innerRadius),
                ),
                child: Center(
                  child: Text(
                    node.data['title'] as String? ?? '',
                    style: theme.textTheme.titleSmall?.copyWith(
                      color: iconColor,
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
      children: [
        const SectionTitle('About'),
        SectionContent(
          child: InfoCard(
            title: 'Instructions',
            content:
                'Drag comment nodes around. Group nodes follow their contained nodes. Select nodes and create groups.',
          ),
        ),
        const SectionTitle('Add Nodes'),
        SectionContent(
          child: Grid2Cols(
            buttons: [
              GridButton(
                label: 'Comment',
                icon: Icons.add_comment,
                onPressed: _addRandomCommentNode,
              ),
              GridButton(
                label: 'Group',
                icon: Icons.group_work,
                onPressed: _createRandomGroup,
              ),
            ],
          ),
        ),
        // Show behavior selector when a group is selected
        Observer(
          builder: (_) {
            final selectedNodeId = controller.selectedNodeIds.isNotEmpty
                ? controller.selectedNodeIds.first
                : null;
            if (selectedNodeId == null) {
              return const SizedBox.shrink();
            }
            final selected = controller.getNode(selectedNodeId);
            if (selected is! GroupNode<Map<String, dynamic>>) {
              return const SizedBox.shrink();
            }
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SectionTitle('Group Behavior'),
                SectionContent(
                  child: _GroupBehaviorSelector(
                    group: selected,
                    controller: controller,
                  ),
                ),
              ],
            );
          },
        ),
        const SectionTitle('Visibility'),
        SectionContent(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Grid2Cols(
                buttons: [
                  GridButton(
                    label: 'Hide All',
                    icon: Icons.visibility_off,
                    onPressed: () {
                      for (final node in controller.nodes.values) {
                        if (node is CommentNode || node is GroupNode) {
                          node.isVisible = false;
                        }
                      }
                    },
                  ),
                  GridButton(
                    label: 'Show All',
                    icon: Icons.visibility,
                    onPressed: () {
                      for (final node in controller.nodes.values) {
                        if (node is CommentNode || node is GroupNode) {
                          node.isVisible = true;
                        }
                      }
                    },
                  ),
                ],
              ),
              const SizedBox(height: 12),
              ControlButton(
                label: 'Clear All Comment/Group Nodes',
                icon: Icons.clear,
                isDestructive: true,
                onPressed: _clearAllCommentAndGroupNodes,
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _addRandomCommentNode() {
    final random = DateTime.now().millisecondsSinceEpoch;
    final commentNodes = controller.nodes.values
        .whereType<CommentNode<Map<String, dynamic>>>()
        .length;

    controller.addNode(
      CommentNode<Map<String, dynamic>>(
        id: 'comment_$random',
        position: Offset(
          50 + (random % 400).toDouble(),
          50 + ((random ~/ 400) % 300).toDouble(),
        ),
        text: 'Comment Node #${commentNodes + 1}',
        data: {},
        color: Colors.primaries[random % Colors.primaries.length].shade200,
      ),
    );
  }

  void _createRandomGroup() {
    // Group selected nodes (or all regular nodes if none selected)
    final selectedNodeIds = controller.selectedNodeIds;
    final regularNodes = controller.nodes.values
        .where((n) => n is! CommentNode && n is! GroupNode)
        .map((n) => n.id)
        .toSet();

    final nodeIdsToGroup = selectedNodeIds.isNotEmpty
        ? selectedNodeIds.where(regularNodes.contains).toSet()
        : regularNodes;

    if (nodeIdsToGroup.isEmpty) {
      // No nodes to group
      return;
    }

    // Calculate bounds for all nodes to group
    final nodesToGroup = nodeIdsToGroup
        .map((id) => controller.getNode(id))
        .whereType<Node<Map<String, dynamic>>>()
        .toList();

    if (nodesToGroup.isEmpty) return;

    final groupBounds = nodesToGroup
        .map((n) => n.getBounds())
        .reduce((a, b) => a.expandToInclude(b));

    final padding = const EdgeInsets.all(30);
    final random = DateTime.now().millisecondsSinceEpoch;

    controller.addNode(
      GroupNode<Map<String, dynamic>>(
        id: 'group_$random',
        position: Offset(
          groupBounds.left - padding.left,
          groupBounds.top - padding.top,
        ),
        size: Size(
          groupBounds.width + padding.left + padding.right,
          groupBounds.height + padding.top + padding.bottom,
        ),
        title: 'Group ${DateTime.now().second}',
        data: {},
        color: Colors
            .primaries[DateTime.now().millisecond % Colors.primaries.length]
            .shade100,
        behavior: GroupBehavior.explicit,
        nodeIds: nodeIdsToGroup,
        padding: padding,
      ),
    );
  }

  void _clearAllCommentAndGroupNodes() {
    final nodeIds = controller.nodes.values
        .where((n) => n is CommentNode || n is GroupNode)
        .map((n) => n.id)
        .toList();

    for (final id in nodeIds) {
      controller.removeNode(id);
    }
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }
}

/// Widget for selecting group behavior
class _GroupBehaviorSelector extends StatelessWidget {
  const _GroupBehaviorSelector({required this.group, required this.controller});

  final GroupNode group;
  final NodeFlowController<Map<String, dynamic>, dynamic> controller;

  void _changeBehavior(GroupBehavior newBehavior) {
    // GroupNode behavior changes are handled through the node's setBehavior method
    // The implementation is in the GroupNode class itself
    group.setBehavior(
      newBehavior,
      nodeLookup: (nodeId) => controller.nodes[nodeId],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Observer(
      builder: (_) {
        final currentBehavior = group.behavior;
        return Container(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _BehaviorOption(
                behavior: GroupBehavior.bounds,
                currentBehavior: currentBehavior,
                label: 'Bounds',
                onTap: () => _changeBehavior(GroupBehavior.bounds),
              ),
              _BehaviorOption(
                behavior: GroupBehavior.explicit,
                currentBehavior: currentBehavior,
                label: 'Explicit',
                onTap: () => _changeBehavior(GroupBehavior.explicit),
              ),
              _BehaviorOption(
                behavior: GroupBehavior.parent,
                currentBehavior: currentBehavior,
                label: 'Parent',
                onTap: () => _changeBehavior(GroupBehavior.parent),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _BehaviorOption extends StatelessWidget {
  const _BehaviorOption({
    required this.behavior,
    required this.currentBehavior,
    required this.label,
    required this.onTap,
  });

  final GroupBehavior behavior;
  final GroupBehavior currentBehavior;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isSelected = behavior == currentBehavior;
    final theme = Theme.of(context);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? theme.colorScheme.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: isSelected
                      ? theme.colorScheme.onPrimary
                      : theme.colorScheme.onSurface,
                  fontWeight: isSelected ? FontWeight.w500 : FontWeight.normal,
                ),
              ),
            ),
            if (isSelected)
              Icon(Icons.check, size: 18, color: theme.colorScheme.onPrimary),
          ],
        ),
      ),
    );
  }
}
