import 'dart:math' as math;

import 'package:flutter/material.dart';
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
      config: NodeFlowConfig.defaultConfig.copyWith(
        snapToGrid: true,
        snapAnnotationsToGrid: false, // Independent annotation snapping control
      ),
    );
    _setupExampleGraph();

    controller.resetViewport();
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
          offset: Offset(0, 20),
        ),
      ],
      inputPorts: [
        Port(
          id: 'input1',
          name: 'In',
          position: PortPosition.left,
          offset: Offset(0, 20),
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
          offset: Offset(0, 20),
        ),
      ],
      inputPorts: [
        Port(
          id: 'input1',
          name: 'In',
          position: PortPosition.left,
          offset: Offset(0, 20),
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
          offset: Offset(0, 20),
        ),
      ],
      inputPorts: [
        Port(
          id: 'input1',
          name: 'In',
          position: PortPosition.left,
          offset: Offset(0, 20),
        ),
        Port(
          id: 'input2',
          name: 'In2',
          position: PortPosition.left,
          offset: Offset(0, 40),
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
    controller.createGroupAnnotation(
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

    // 4. Sticky note linked to a node (follows node movements)
    final linkedSticky = controller.createStickyNote(
      position: const Offset(250, 350),
      text: 'Linked to Process C\nMoves with the node!',
      width: 160,
      height: 80,
      color: Colors.green.shade200,
      offset: Offset(50, 100),
    );
    controller.annotations.addNodeDependency(linkedSticky.id, 'node3');

    // 5. Another group for demonstration
    final group2 = controller.createGroupAnnotation(
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
    return Row(
      children: [
        // Main Editor
        Expanded(
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

              // Instructions overlay
              _buildInstructions(),
            ],
          ),
        ),
        // Control Panel on the right
        ControlPanel(
          title: 'Annotation Controls',
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
        ),
      ],
    );
  }

  Widget _buildInstructions() {
    return Positioned(
      top: 16,
      left: 16,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.black87,
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Annotation System Demo',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 8),
            Text(
              '• Drag sticky notes and markers around\n'
              '• Group annotations follow their nodes\n'
              '• Green sticky follows Process C\n'
              '• Use toolbar buttons to add more',
              style: TextStyle(color: Colors.white, fontSize: 12),
            ),
          ],
        ),
      ),
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

    controller.createGroupAnnotation(
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
