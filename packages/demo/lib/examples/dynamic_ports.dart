import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:vyuh_node_flow/vyuh_node_flow.dart';

import '../shared/ui_widgets.dart';

class DynamicPortsExample extends StatefulWidget {
  const DynamicPortsExample({super.key});

  @override
  State<DynamicPortsExample> createState() => _DynamicPortsExampleState();
}

class _DynamicPortsExampleState extends State<DynamicPortsExample> {
  final _theme = NodeFlowTheme.light;
  int _nodeCounter = 2; // Start from 2 since we have 2 initial nodes
  int _portCounter = 4; // Start from 4 since initial nodes have 4 ports total

  // Create controller with initial nodes
  final _controller = NodeFlowController<Map<String, dynamic>, dynamic>(
    config: NodeFlowConfig(),
    nodes: [
      // Node 1: Horizontal layout (left/right ports)
      Node<Map<String, dynamic>>(
        id: 'node-1',
        type: 'custom',
        position: const Offset(150, 150),
        size: const Size(120, 100),
        data: {'label': 'Horizontal'},
        inputPorts: [
          Port(
            id: 'port-1',
            name: 'Input',
            position: PortPosition.left,
            offset: Offset(-2, 50),
            type: PortType.input,
            multiConnections: true,
          ),
        ],
        outputPorts: [
          Port(
            id: 'port-2',
            name: 'Output',
            position: PortPosition.right,
            offset: Offset(2, 50),
            type: PortType.output,
          ),
        ],
      ),
      // Node 2: Vertical layout (top/bottom ports)
      Node<Map<String, dynamic>>(
        id: 'node-2',
        type: 'custom',
        position: const Offset(400, 150),
        size: const Size(120, 100),
        data: {'label': 'Vertical'},
        inputPorts: [
          Port(
            id: 'port-3',
            name: 'Input',
            position: PortPosition.top,
            offset: Offset(60, -2),
            type: PortType.input,
            multiConnections: true,
          ),
        ],
        outputPorts: [
          Port(
            id: 'port-4',
            name: 'Output',
            position: PortPosition.bottom,
            offset: Offset(60, 2),
            type: PortType.output,
          ),
        ],
      ),
    ],
  );

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _addNode() {
    _nodeCounter++;
    final node = Node<Map<String, dynamic>>(
      id: 'node-$_nodeCounter',
      type: 'custom',
      position: Offset(
        100.0 + (_nodeCounter * 50.0),
        100.0 + (_nodeCounter * 30.0),
      ),
      size: const Size(120, 80),
      // Initial size
      data: {'label': 'Node $_nodeCounter'},
      inputPorts: [],
      outputPorts: [],
    );
    _controller.addNode(node);
    _controller.selectNode(node.id);
  }

  void _addPort(PortPosition position) {
    final selectedIds = _controller.selectedNodeIds.toList();
    if (selectedIds.isEmpty) return;

    final nodeId = selectedIds.first;
    final node = _controller.getNode(nodeId);
    if (node == null) return;

    _portCounter++;
    final isOutput =
        position == PortPosition.right || position == PortPosition.bottom;

    // Get current ports for this position
    final currentPorts = isOutput ? node.outputPorts : node.inputPorts;
    final portsOnSide = currentPorts
        .where((p) => p.position == position)
        .length;

    // Calculate port offset (will be recalculated later with new size)
    final offset = _calculatePortOffset(position, portsOnSide, node.size.value);

    // Create new port
    final newPort = Port(
      id: 'port-$_portCounter',
      name: '${position.name} $_portCounter',
      position: position,
      offset: offset,
      type: isOutput ? PortType.output : PortType.input,
      multiConnections: isOutput ? false : true,
    );

    // Add port to appropriate list
    final updatedInputPorts = isOutput
        ? node.inputPorts.toList()
        : [...node.inputPorts, newPort];
    final updatedOutputPorts = isOutput
        ? [...node.outputPorts, newPort]
        : node.outputPorts.toList();

    // Calculate new size based on updated ports
    final newSize = _calculateNodeSize(updatedInputPorts, updatedOutputPorts);

    // Recalculate all port offsets with new size
    final finalInputPorts = _recalculatePortOffsets(updatedInputPorts, newSize);
    final finalOutputPorts = _recalculatePortOffsets(
      updatedOutputPorts,
      newSize,
    );

    // Update node size and ports using controller APIs
    _controller.setNodeSize(nodeId, newSize);
    _controller.setNodePorts(
      nodeId,
      inputPorts: finalInputPorts,
      outputPorts: finalOutputPorts,
    );
  }

  Offset _calculatePortOffset(PortPosition position, int index, Size nodeSize) {
    const spacing = 20.0;
    const startOffset = 20.0;

    switch (position) {
      case PortPosition.left:
        return Offset(-2, startOffset + (index * spacing));
      case PortPosition.right:
        return Offset(2, startOffset + (index * spacing));
      case PortPosition.top:
        return Offset(startOffset + (index * spacing), -2);
      case PortPosition.bottom:
        return Offset(startOffset + (index * spacing), 2);
    }
  }

  Size _calculateNodeSize(List<Port> inputPorts, List<Port> outputPorts) {
    const minWidth = 120.0;
    const minHeight = 80.0;
    const spacing = 20.0;
    const padding = 40.0; // Extra padding beyond last port

    // Count ports per side
    final leftPorts = inputPorts
        .where((p) => p.position == PortPosition.left)
        .length;
    final rightPorts = outputPorts
        .where((p) => p.position == PortPosition.right)
        .length;
    final topPorts =
        inputPorts.where((p) => p.position == PortPosition.top).length +
        outputPorts.where((p) => p.position == PortPosition.top).length;
    final bottomPorts =
        inputPorts.where((p) => p.position == PortPosition.bottom).length +
        outputPorts.where((p) => p.position == PortPosition.bottom).length;

    // Calculate required height based on vertical ports
    final maxVerticalPorts = math.max(leftPorts, rightPorts);
    final requiredHeight = maxVerticalPorts > 0
        ? (spacing * maxVerticalPorts) + padding
        : minHeight;

    // Calculate required width based on horizontal ports
    final maxHorizontalPorts = math.max(topPorts, bottomPorts);
    final requiredWidth = maxHorizontalPorts > 0
        ? (spacing * maxHorizontalPorts) + padding
        : minWidth;

    return Size(
      math.max(minWidth, requiredWidth),
      math.max(minHeight, requiredHeight),
    );
  }

  List<Port> _recalculatePortOffsets(List<Port> ports, Size nodeSize) {
    // Group ports by position
    final portsByPosition = <PortPosition, List<Port>>{};
    for (final port in ports) {
      portsByPosition.putIfAbsent(port.position, () => []).add(port);
    }

    // Recalculate offsets for each group
    final updatedPorts = <Port>[];
    for (final entry in portsByPosition.entries) {
      final position = entry.key;
      final positionPorts = entry.value;

      for (var i = 0; i < positionPorts.length; i++) {
        final port = positionPorts[i];
        final newOffset = _calculatePortOffset(position, i, nodeSize);
        updatedPorts.add(port.copyWith(offset: newOffset));
      }
    }

    return updatedPorts;
  }

  Widget _buildNode(BuildContext context, Node<Map<String, dynamic>> node) {
    // Calculate inner border radius
    final outerBorderRadius = _theme.nodeTheme.borderRadius;
    final borderWidth = _theme.nodeTheme.borderWidth;
    final outerRadius = outerBorderRadius.topLeft.x;
    final innerRadius = math.max(0.0, outerRadius - borderWidth);

    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // Soft lavender
    final nodeColor = isDark
        ? const Color(0xFF3E3247)
        : const Color(0xFFE8D4F1);
    final iconColor = isDark
        ? const Color(0xFFC088D5)
        : const Color(0xFF6B2D8B);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: nodeColor,
        borderRadius: BorderRadius.circular(innerRadius),
      ),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              node.data['label'] ?? '',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
                color: iconColor,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Text(
              'Ports: ${node.inputPorts.length + node.outputPorts.length}',
              style: theme.textTheme.bodySmall?.copyWith(
                color: iconColor.withValues(alpha: 0.7),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ResponsiveControlPanel(
      controller: _controller,
      onReset: () {
        _controller.clearGraph();
        _nodeCounter = 0;
        _addNode(); // Add one initial node
        _controller.fitToView();
      },
      child: NodeFlowEditor<Map<String, dynamic>, dynamic>(
        controller: _controller,
        nodeBuilder: _buildNode,
        theme: _theme,
        events: NodeFlowEvents(onInit: () => _controller.fitToView()),
      ),
      children: [
        const InfoCard(
          title: 'Instructions',
          content:
              'Add a node, then select it to add ports. The node will automatically resize to fit all ports.',
        ),
        const SizedBox(height: 24),

        // Add Node section
        const SectionTitle('Add Node'),
        const SizedBox(height: 8),
        ControlButton(label: 'Add Node', icon: Icons.add, onPressed: _addNode),
        const SizedBox(height: 24),

        // Add Ports section
        const SectionTitle('Add Ports'),
        const SizedBox(height: 8),
        Observer(
          builder: (_) {
            final hasSelection = _controller.selectedNodeIds.isNotEmpty;
            return Column(
              children: [
                Grid2Cols(
                  buttons: [
                    GridButton(
                      label: 'Left',
                      icon: Icons.arrow_back,
                      onPressed: hasSelection
                          ? () => _addPort(PortPosition.left)
                          : null,
                    ),
                    GridButton(
                      label: 'Right',
                      icon: Icons.arrow_forward,
                      onPressed: hasSelection
                          ? () => _addPort(PortPosition.right)
                          : null,
                    ),
                    GridButton(
                      label: 'Top',
                      icon: Icons.arrow_upward,
                      onPressed: hasSelection
                          ? () => _addPort(PortPosition.top)
                          : null,
                    ),
                    GridButton(
                      label: 'Bottom',
                      icon: Icons.arrow_downward,
                      onPressed: hasSelection
                          ? () => _addPort(PortPosition.bottom)
                          : null,
                    ),
                  ],
                ),
                if (!hasSelection) ...[
                  const SizedBox(height: 8),
                  Builder(
                    builder: (context) {
                      final theme = Theme.of(context);
                      return Text(
                        'Select a node to add ports',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                          fontStyle: FontStyle.italic,
                        ),
                      );
                    },
                  ),
                ],
              ],
            );
          },
        ),
        const SizedBox(height: 24),

        // Node Info section
        const SectionTitle('Selected Node'),
        const SizedBox(height: 8),
        Observer(
          builder: (_) {
            final selectedIds = _controller.selectedNodeIds.toList();
            if (selectedIds.isEmpty) {
              return const InfoCard(
                title: 'No Selection',
                content: 'Click a node to select it',
              );
            }

            final node = _controller.getNode(selectedIds.first);
            if (node == null) {
              return const InfoCard(title: 'Error', content: 'Node not found');
            }

            final leftPorts = node.inputPorts
                .where((p) => p.position == PortPosition.left)
                .length;
            final rightPorts = node.outputPorts
                .where((p) => p.position == PortPosition.right)
                .length;
            final topPorts =
                (node.inputPorts
                    .where((p) => p.position == PortPosition.top)
                    .length +
                node.outputPorts
                    .where((p) => p.position == PortPosition.top)
                    .length);
            final bottomPorts =
                (node.inputPorts
                    .where((p) => p.position == PortPosition.bottom)
                    .length +
                node.outputPorts
                    .where((p) => p.position == PortPosition.bottom)
                    .length);

            return InfoCard(
              title: node.data['label'] ?? 'Unknown',
              content:
                  'Size: ${node.size.value.width.toInt()} × ${node.size.value.height.toInt()}\n'
                  'Left: $leftPorts | Right: $rightPorts\n'
                  'Top: $topPorts | Bottom: $bottomPorts',
            );
          },
        ),
      ],
    );
  }
}
