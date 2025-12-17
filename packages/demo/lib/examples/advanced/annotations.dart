import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:vyuh_node_flow/vyuh_node_flow.dart';

import '../../shared/ui_widgets.dart';

/// Example showing how to use the annotation system
class AnnotationExample extends StatefulWidget {
  const AnnotationExample({super.key});

  @override
  State<AnnotationExample> createState() => _AnnotationExampleState();
}

class _AnnotationExampleState extends State<AnnotationExample> {
  late final NodeFlowController<Map<String, dynamic>> controller;
  late final NodeFlowTheme _theme;

  @override
  void initState() {
    super.initState();
    _theme = NodeFlowTheme.light;
    controller = NodeFlowController<Map<String, dynamic>>(
      config: NodeFlowConfig.defaultConfig,
    );
    _setupExampleGraph();

    // Fit view to show all content after first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      controller.resetViewport();
    });
  }

  void _setupExampleGraph() {
    // Create some example nodes with ports
    final node1 = Node<Map<String, dynamic>>(
      id: 'node1',
      type: 'process',
      position: const Offset(100, 100),
      size: const Size(150, 80),
      data: {'title': 'Process A'},
      outputPorts: [
        Port(
          id: 'output1',
          name: 'Out',
          position: PortPosition.right,
          offset: Offset(2, 40), // Vertical center of 80 height
        ),
      ],
      inputPorts: [
        Port(
          id: 'input1',
          name: 'In',
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
      outputPorts: [
        Port(
          id: 'output1',
          name: 'Out',
          position: PortPosition.right,
          offset: Offset(2, 40), // Vertical center of 80 height
        ),
      ],
      inputPorts: [
        Port(
          id: 'input1',
          name: 'In',
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
      outputPorts: [
        Port(
          id: 'output1',
          name: 'Out',
          position: PortPosition.right,
          offset: Offset(2, 40), // Vertical center of 80 height
        ),
      ],
      inputPorts: [
        Port(
          id: 'input1',
          name: 'In',
          position: PortPosition.left,
          offset: Offset(-2, 20), // Multiple ports: starting offset 20
        ),
        Port(
          id: 'input2',
          name: 'In2',
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

    // Create different types of annotations

    // 1. Sticky note annotation (free-floating)
    controller.createStickyNote(
      position: const Offset(400, 50),
      text: 'This is a sticky note!\n\nYou can drag me around.',
      width: 180,
      height: 120,
      color: Colors.yellow.shade200,
    );

    // 2. Group annotation (surrounds nodes)
    controller.createGroupAnnotationAroundNodes(
      title: 'Core Processes',
      nodeIds: {'node1', 'node2'},
      color: Colors.blue.shade300,
      padding: const EdgeInsets.all(30),
    );

    // 3. Marker annotations (small indicators)
    controller.createMarker(
      position: const Offset(80, 80),
      markerType: MarkerType.warning,
      color: Colors.orange,
      tooltip: 'Important: Check prerequisites',
    );

    controller.createMarker(
      position: const Offset(350, 80),
      markerType: MarkerType.info,
      color: Colors.blue,
      tooltip: 'Info: This process takes ~5 minutes',
    );

    // 4. Simple sticky note near a node
    controller.createStickyNote(
      position: const Offset(250, 350),
      text: 'Note for Process C\nContext and details here',
      width: 180,
      height: 80,
      color: Colors.green.shade200,
    );

    // 5. Another group for demonstration
    final group2 = controller.createGroupAnnotationAroundNodes(
      title: 'All Processes',
      nodeIds: {'node1', 'node2', 'node3'},
      color: Colors.purple.shade300,
      padding: const EdgeInsets.all(50),
    );
    // Put this group behind others
    controller.annotations.sendAnnotationToBack(group2.id);
  }

  @override
  Widget build(BuildContext context) {
    return ResponsiveControlPanel(
      title: 'Annotation Controls',
      width: 320,
      child: Stack(
        children: [
          // Use the actual NodeFlowEditor which handles all interactions properly
          NodeFlowEditor<Map<String, dynamic>>(
            controller: controller,
            theme: _theme,
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
        const InfoCard(
          title: 'Instructions',
          content:
              'Drag sticky notes and markers around. Group annotations follow their nodes. Select nodes and create groups.',
        ),
        const SizedBox(height: 24),
        const SectionTitle('Add Annotations'),
        const SizedBox(height: 8),
        ControlButton(
          label: 'Add Sticky Note',
          icon: Icons.add_comment,
          onPressed: _addRandomStickyNote,
        ),
        const SizedBox(height: 8),
        ControlButton(
          label: 'Add Marker',
          icon: Icons.place,
          onPressed: _addRandomMarker,
        ),
        const SizedBox(height: 8),
        ControlButton(
          label: 'Group Selected Nodes',
          icon: Icons.group_work,
          onPressed: _createRandomGroup,
        ),
        const SizedBox(height: 24),
        // Show behavior selector when a group is selected
        Observer(
          builder: (_) {
            final selected = controller.annotations.selectedAnnotation;
            if (selected is! GroupAnnotation) {
              return const SizedBox.shrink();
            }
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SectionTitle('Group Behavior'),
                const SizedBox(height: 8),
                _GroupBehaviorSelector(group: selected, controller: controller),
                const SizedBox(height: 24),
              ],
            );
          },
        ),
        const SectionTitle('Visibility'),
        const SizedBox(height: 8),
        ControlButton(
          label: 'Hide All Annotations',
          icon: Icons.visibility_off,
          onPressed: () => controller.hideAllAnnotations(),
        ),
        const SizedBox(height: 8),
        ControlButton(
          label: 'Show All Annotations',
          icon: Icons.visibility,
          onPressed: () => controller.showAllAnnotations(),
        ),
        const SizedBox(height: 24),
        const SectionTitle('Actions'),
        const SizedBox(height: 8),
        ControlButton(
          label: 'Clear All Annotations',
          icon: Icons.clear,
          onPressed: _clearAllAnnotations,
        ),
      ],
    );
  }

  void _addRandomStickyNote() {
    final random = DateTime.now().millisecondsSinceEpoch;
    controller.createStickyNote(
      position: Offset(
        50 + (random % 400).toDouble(),
        50 + ((random ~/ 400) % 300).toDouble(),
      ),
      text: 'Sticky Note #${controller.annotations.annotations.length + 1}',
      color: Colors.primaries[random % Colors.primaries.length].shade200,
    );
  }

  void _addRandomMarker() {
    final random = DateTime.now().millisecondsSinceEpoch;

    controller.createMarker(
      position: Offset(
        100 + (random % 300).toDouble(),
        100 + ((random ~/ 300) % 200).toDouble(),
      ),
      markerType: MarkerType.values[random % MarkerType.values.length],
      color: Colors.primaries[random % Colors.primaries.length],
      tooltip: 'Marker #${controller.annotations.annotations.length + 1}',
    );
  }

  void _createRandomGroup() {
    // Group selected nodes (or all nodes if none selected)
    final selectedNodeIds = controller.selectedNodeIds;
    final nodeIdsToGroup = selectedNodeIds.isNotEmpty
        ? selectedNodeIds
        : controller.nodes.keys.toSet();

    if (nodeIdsToGroup.isEmpty) {
      // No nodes to group
      return;
    }

    controller.createGroupAnnotationAroundNodes(
      title: 'Group ${DateTime.now().second}',
      nodeIds: nodeIdsToGroup,
      color: Colors
          .primaries[DateTime.now().millisecond % Colors.primaries.length]
          .shade100,
    );
  }

  void _clearAllAnnotations() {
    final annotationIds = controller.annotations.annotations.keys.toList();
    for (final id in annotationIds) {
      controller.removeAnnotation(id);
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

  final GroupAnnotation group;
  final NodeFlowController<Map<String, dynamic>> controller;

  void _changeBehavior(GroupBehavior newBehavior) {
    // If switching from bounds, capture currently contained nodes
    Set<String>? captureNodes;
    if (group.behavior == GroupBehavior.bounds &&
        newBehavior != GroupBehavior.bounds) {
      captureNodes = controller.annotations.findContainedNodes(group);
    }

    // Create node lookup for fitToNodes
    NodeLookup? nodeLookup;
    if (newBehavior == GroupBehavior.explicit) {
      nodeLookup = (nodeId) => controller.nodes[nodeId];
    }

    group.setBehavior(
      newBehavior,
      captureContainedNodes: captureNodes,
      nodeLookup: nodeLookup,
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
