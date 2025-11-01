import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:vyuh_node_flow/vyuh_node_flow.dart';

import '../../shared/ui_widgets.dart';

class ControllingNodesExample extends StatefulWidget {
  const ControllingNodesExample({super.key});

  @override
  State<ControllingNodesExample> createState() =>
      _ControllingNodesExampleState();
}

class _ControllingNodesExampleState extends State<ControllingNodesExample> {
  late final NodeFlowController<Map<String, dynamic>> _controller;
  late final NodeFlowTheme _theme;
  int _nodeCounter = 0;

  @override
  void initState() {
    super.initState();
    _theme = NodeFlowTheme.light;
    _controller = NodeFlowController<Map<String, dynamic>>(
      config: NodeFlowConfig(),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _addNode(String nodeType) {
    _nodeCounter++;
    final node = _createNode(nodeType, _nodeCounter);
    _controller.addNode(node);
  }

  Node<Map<String, dynamic>> _createNode(String nodeType, int counter) {
    final random = math.Random();
    final randomX = 100.0 + random.nextDouble() * 400;
    final randomY = 100.0 + random.nextDouble() * 300;

    // Different node configurations based on type
    final config = _getNodeConfig(nodeType);

    return Node<Map<String, dynamic>>(
      id: 'node-$counter',
      type: nodeType,
      position: Offset(randomX, randomY),
      data: {
        'label': '${config['label']} $counter',
        'colorType': config['colorType'],
      },
      size: config['size'] as Size,
      inputPorts: config['inputPorts'] as List<Port>,
      outputPorts: config['outputPorts'] as List<Port>,
    );
  }

  Map<String, dynamic> _getNodeConfig(String nodeType) {
    switch (nodeType) {
      case 'input':
        return {
          'label': 'Input',
          'colorType': 'primary',
          'size': const Size(120, 70),
          'inputPorts': const <Port>[],
          'outputPorts': const [
            Port(
              id: 'output',
              name: 'Out',
              position: PortPosition.right,
              offset: Offset(0, 35),
              type: PortType.source,
            ),
          ],
        };
      case 'process':
        return {
          'label': 'Process',
          'colorType': 'primaryContainer',
          'size': const Size(150, 80),
          'inputPorts': const [
            Port(
              id: 'input',
              name: 'In',
              position: PortPosition.left,
              offset: Offset(0, 40),
              type: PortType.target,
            ),
          ],
          'outputPorts': const [
            Port(
              id: 'output',
              name: 'Out',
              position: PortPosition.right,
              offset: Offset(0, 40),
              type: PortType.source,
            ),
          ],
        };
      case 'decision':
        return {
          'label': 'Decision',
          'colorType': 'secondaryContainer',
          'size': const Size(140, 100),
          'inputPorts': const [
            Port(
              id: 'input-left',
              name: 'In',
              position: PortPosition.left,
              offset: Offset(0, 50),
              type: PortType.target,
            ),
            Port(
              id: 'input-top',
              name: 'In',
              position: PortPosition.top,
              offset: Offset(70, 0),
              type: PortType.target,
            ),
          ],
          'outputPorts': const [
            Port(
              id: 'yes',
              name: 'Yes',
              position: PortPosition.right,
              offset: Offset(0, 50),
              type: PortType.source,
            ),
            Port(
              id: 'no',
              name: 'No',
              position: PortPosition.bottom,
              offset: Offset(70, 0),
              type: PortType.source,
            ),
          ],
        };
      case 'output':
        return {
          'label': 'Output',
          'colorType': 'tertiaryContainer',
          'size': const Size(120, 70),
          'inputPorts': const [
            Port(
              id: 'input',
              name: 'In',
              position: PortPosition.left,
              offset: Offset(0, 35),
              type: PortType.target,
            ),
          ],
          'outputPorts': const <Port>[],
        };
      default:
        return {
          'label': 'Node',
          'colorType': 'surfaceContainerHighest',
          'size': const Size(150, 80),
          'inputPorts': const <Port>[],
          'outputPorts': const <Port>[],
        };
    }
  }

  void _deleteSelectedNodes() {
    final selectedIds = _controller.selectedNodeIds.toList();
    for (final nodeId in selectedIds) {
      _controller.removeNode(nodeId);
    }
  }

  void _clearAll() {
    _controller.clearGraph();
    _nodeCounter = 0;
  }

  void _duplicateNode() {
    final selectedIds = _controller.selectedNodeIds.toList();
    if (selectedIds.isEmpty) return;
    _controller.duplicateNode(selectedIds.first);
  }

  void _moveNodeRight() {
    final selectedIds = _controller.selectedNodeIds.toList();
    if (selectedIds.isEmpty) return;
    for (final nodeId in selectedIds) {
      final node = _controller.getNode(nodeId);
      if (node != null) {
        _controller.setNodePosition(
          nodeId,
          node.position.value + const Offset(50, 0),
        );
      }
    }
  }

  void _moveNodeDown() {
    final selectedIds = _controller.selectedNodeIds.toList();
    if (selectedIds.isEmpty) return;
    for (final nodeId in selectedIds) {
      final node = _controller.getNode(nodeId);
      if (node != null) {
        _controller.setNodePosition(
          nodeId,
          node.position.value + const Offset(0, 50),
        );
      }
    }
  }

  void _moveNodeLeft() {
    final selectedIds = _controller.selectedNodeIds.toList();
    if (selectedIds.isEmpty) return;
    for (final nodeId in selectedIds) {
      final node = _controller.getNode(nodeId);
      if (node != null) {
        _controller.setNodePosition(
          nodeId,
          node.position.value + const Offset(-50, 0),
        );
      }
    }
  }

  void _moveNodeUp() {
    final selectedIds = _controller.selectedNodeIds.toList();
    if (selectedIds.isEmpty) return;
    for (final nodeId in selectedIds) {
      final node = _controller.getNode(nodeId);
      if (node != null) {
        _controller.setNodePosition(
          nodeId,
          node.position.value + const Offset(0, -50),
        );
      }
    }
  }

  void _selectAllNodes() {
    _controller.selectAllNodes();
  }

  void _invertSelection() {
    _controller.invertSelection();
  }

  void _clearSelection() {
    _controller.clearSelection();
  }

  Widget _buildNode(BuildContext context, Node<Map<String, dynamic>> node) {
    // Calculate inner border radius by subtracting border width from outer radius
    final outerBorderRadius = _theme.nodeTheme.borderRadius;
    final borderWidth = _theme.nodeTheme.borderWidth;
    final outerRadius = outerBorderRadius.topLeft.x;
    final innerRadius = math.max(0.0, outerRadius - borderWidth);

    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final colorType =
        node.data['colorType'] as String? ?? 'surfaceContainerHighest';

    Color nodeColor;
    Color iconColor;

    switch (colorType) {
      case 'primary':
        // Soft sky blue for input nodes
        nodeColor = isDark ? const Color(0xFF2D3E52) : const Color(0xFFD4E7F7);
        iconColor = isDark ? const Color(0xFF88B8E6) : const Color(0xFF1B4D7A);
        break;
      case 'primaryContainer':
        // Soft mint green for process nodes
        nodeColor = isDark ? const Color(0xFF2D4A3E) : const Color(0xFFD4F1E8);
        iconColor = isDark ? const Color(0xFF88D5B3) : const Color(0xFF1B5E3F);
        break;
      case 'secondaryContainer':
        // Soft peach for decision nodes
        nodeColor = isDark ? const Color(0xFF4A3D32) : const Color(0xFFFFE5D4);
        iconColor = isDark ? const Color(0xFFFFB088) : const Color(0xFF8B4513);
        break;
      case 'tertiaryContainer':
        // Soft lavender for output nodes
        nodeColor = isDark ? const Color(0xFF3E3247) : const Color(0xFFE8D4F1);
        iconColor = isDark ? const Color(0xFFC088D5) : const Color(0xFF6B2D8B);
        break;
      default:
        // Soft coral for default
        nodeColor = isDark ? const Color(0xFF4A3239) : const Color(0xFFFFD4DD);
        iconColor = isDark ? const Color(0xFFFF88AA) : const Color(0xFF8B2D47);
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: nodeColor,
        borderRadius: BorderRadius.circular(innerRadius),
      ),
      child: Center(
        child: Text(
          node.data['label'] ?? '',
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
            color: iconColor,
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // Main Editor
        Expanded(
          child: NodeFlowEditor<Map<String, dynamic>>(
            controller: _controller,
            nodeBuilder: _buildNode,
            theme: _theme,
          ),
        ),
        // Control Panel on the right
        ControlPanel(
          title: 'Node Controls',
          children: [
            // Instructions
            const InfoCard(
              title: 'Instructions',
              content:
                  'Click buttons to add nodes. Click to select, drag to move. Cmd-click or Shift-drag to select multiple nodes.',
            ),
            const SizedBox(height: 24),

            // Add Nodes section
            const SectionTitle('Add Nodes'),
            const SizedBox(height: 8),
            Grid2x2(
              buttons: [
                GridButton(
                  label: 'Input',
                  icon: Icons.input,
                  onPressed: () => _addNode('input'),
                ),
                GridButton(
                  label: 'Process',
                  icon: Icons.settings,
                  onPressed: () => _addNode('process'),
                ),
                GridButton(
                  label: 'Decision',
                  icon: Icons.call_split,
                  onPressed: () => _addNode('decision'),
                ),
                GridButton(
                  label: 'Output',
                  icon: Icons.output,
                  onPressed: () => _addNode('output'),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Node Actions section
            const SectionTitle('Node Actions'),
            const SizedBox(height: 8),
            Observer(
              builder: (_) {
                final hasSelection = _controller.selectedNodeIds.isNotEmpty;
                return ControlButton(
                  label: 'Delete Selected',
                  icon: Icons.delete,
                  onPressed: hasSelection ? _deleteSelectedNodes : null,
                );
              },
            ),
            const SizedBox(height: 8),
            Observer(
              builder: (_) {
                final hasSelection = _controller.selectedNodeIds.isNotEmpty;
                return ControlButton(
                  label: 'Duplicate Node',
                  icon: Icons.content_copy,
                  onPressed: hasSelection ? _duplicateNode : null,
                );
              },
            ),
            const SizedBox(height: 8),
            ControlButton(
              label: 'Clear All',
              icon: Icons.clear_all,
              onPressed: _clearAll,
            ),
            const SizedBox(height: 24),

            // Node Movement section
            const SectionTitle('Move Nodes'),
            const SizedBox(height: 8),
            Observer(
              builder: (_) {
                final hasSelection = _controller.selectedNodeIds.isNotEmpty;
                return Grid2x2(
                  buttons: [
                    GridButton(
                      label: 'Left',
                      icon: Icons.arrow_back,
                      onPressed: hasSelection ? _moveNodeLeft : null,
                    ),
                    GridButton(
                      label: 'Right',
                      icon: Icons.arrow_forward,
                      onPressed: hasSelection ? _moveNodeRight : null,
                    ),
                    GridButton(
                      label: 'Up',
                      icon: Icons.arrow_upward,
                      onPressed: hasSelection ? _moveNodeUp : null,
                    ),
                    GridButton(
                      label: 'Down',
                      icon: Icons.arrow_downward,
                      onPressed: hasSelection ? _moveNodeDown : null,
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: 24),

            // Selection section
            const SectionTitle('Selection'),
            const SizedBox(height: 8),
            ControlButton(
              label: 'Select All',
              icon: Icons.select_all,
              onPressed: _selectAllNodes,
            ),
            const SizedBox(height: 8),
            ControlButton(
              label: 'Invert Selection',
              icon: Icons.flip,
              onPressed: _invertSelection,
            ),
            const SizedBox(height: 8),
            ControlButton(
              label: 'Clear Selection',
              icon: Icons.deselect,
              onPressed: _clearSelection,
            ),
            const SizedBox(height: 24),

            // Selection Info section
            const SectionTitle('Selection Info'),
            const SizedBox(height: 8),
            Observer(
              builder: (_) {
                final selectedCount = _controller.selectedNodeIds.length;
                final totalNodes = _controller.nodes.length;

                return InfoCard(
                  title: 'Graph Stats',
                  content: 'Total Nodes: $totalNodes\nSelected: $selectedCount',
                );
              },
            ),
          ],
        ),
      ],
    );
  }
}
