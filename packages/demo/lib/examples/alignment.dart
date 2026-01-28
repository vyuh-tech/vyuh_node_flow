import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:vyuh_node_flow/vyuh_node_flow.dart';

import '../shared/ui_widgets.dart';

class AlignmentExample extends StatefulWidget {
  const AlignmentExample({super.key});

  @override
  State<AlignmentExample> createState() => _AlignmentExampleState();
}

class _AlignmentExampleState extends State<AlignmentExample> {
  late final NodeFlowController<Map<String, dynamic>, dynamic> _controller;
  late final NodeFlowTheme _theme;
  final _random = math.Random();
  int _nodeCounter = 0;

  @override
  void initState() {
    super.initState();
    _theme = NodeFlowTheme.light;
    _controller = NodeFlowController<Map<String, dynamic>, dynamic>(
      config: NodeFlowConfig(),
    );
    _createInitialNodes();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _createInitialNodes() {
    // Create a variety of nodes at random positions with random sizes
    final nodes = [
      _createNode('1', const Offset(100, 100)),
      _createNode('2', const Offset(300, 150)),
      _createNode('3', const Offset(500, 120)),
      _createNode('4', const Offset(150, 300)),
      _createNode('5', const Offset(350, 280)),
      _createNode('6', const Offset(550, 320)),
      _createNode('7', const Offset(200, 450)),
      _createNode('8', const Offset(400, 470)),
    ];

    for (final node in nodes) {
      _controller.addNode(node);
    }
  }

  Node<Map<String, dynamic>> _createNode(String id, Offset position) {
    // Minimum size: 100x60
    // Add random 0-20 pixels to width and height
    final width = 100.0 + _random.nextInt(21);
    final height = 60.0 + _random.nextInt(21);
    final size = Size(width, height);

    return Node<Map<String, dynamic>>(
      id: 'node-$id',
      type: 'simple',
      position: position,
      data: {'label': 'Node $id'},
      size: size,
      ports: [
        Port(
          id: 'input',
          name: 'In',
          type: PortType.input,
          position: PortPosition.left,
          offset: Offset(-2, height / 2),
        ),
        Port(
          id: 'output',
          name: 'Out',
          type: PortType.output,
          position: PortPosition.right,
          offset: Offset(2, height / 2),
        ),
      ],
    );
  }

  void _addRandomNode() {
    _nodeCounter++;
    final randomX = 100.0 + _random.nextDouble() * 600;
    final randomY = 100.0 + _random.nextDouble() * 400;
    final node = _createNode('${_nodeCounter + 8}', Offset(randomX, randomY));
    _controller.addNode(node);
  }

  Widget _buildNode(BuildContext context, Node<Map<String, dynamic>> node) {
    // Calculate inner border radius by subtracting border width from outer radius
    final outerBorderRadius = _theme.nodeTheme.borderRadius;
    final borderWidth = _theme.nodeTheme.borderWidth;

    // Extract the radius value from the topLeft corner (assuming uniform radius)
    final outerRadius = outerBorderRadius.topLeft.x;
    final innerRadius = math.max(0.0, outerRadius - borderWidth);

    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // Soft peach
    final nodeColor = isDark
        ? const Color(0xFF4A3D32)
        : const Color(0xFFFFE5D4);
    final iconColor = isDark
        ? const Color(0xFFFFB088)
        : const Color(0xFF8B4513);

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
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ),
    );
  }

  void _alignLeft() {
    final selectedIds = _controller.selectedNodeIds.toList();
    if (selectedIds.length < 2) return;
    _controller.alignNodes(selectedIds, NodeAlignment.left);
  }

  void _alignRight() {
    final selectedIds = _controller.selectedNodeIds.toList();
    if (selectedIds.length < 2) return;
    _controller.alignNodes(selectedIds, NodeAlignment.right);
  }

  void _alignTop() {
    final selectedIds = _controller.selectedNodeIds.toList();
    if (selectedIds.length < 2) return;
    _controller.alignNodes(selectedIds, NodeAlignment.top);
  }

  void _alignBottom() {
    final selectedIds = _controller.selectedNodeIds.toList();
    if (selectedIds.length < 2) return;
    _controller.alignNodes(selectedIds, NodeAlignment.bottom);
  }

  void _alignCenterHorizontal() {
    final selectedIds = _controller.selectedNodeIds.toList();
    if (selectedIds.length < 2) return;
    _controller.alignNodes(selectedIds, NodeAlignment.horizontalCenter);
  }

  void _alignMiddleVertical() {
    final selectedIds = _controller.selectedNodeIds.toList();
    if (selectedIds.length < 2) return;
    _controller.alignNodes(selectedIds, NodeAlignment.verticalCenter);
  }

  void _distributeHorizontally() {
    final selectedIds = _controller.selectedNodeIds.toList();
    if (selectedIds.length < 3) return;
    _controller.distributeNodesHorizontally(selectedIds);
  }

  void _distributeVertically() {
    final selectedIds = _controller.selectedNodeIds.toList();
    if (selectedIds.length < 3) return;
    _controller.distributeNodesVertically(selectedIds);
  }

  void _gridLayout() {
    _controller.arrangeNodesInGrid(spacing: 180);
  }

  void _hierarchicalLayout() {
    _controller.arrangeNodesHierarchically();
  }

  void _bringToFront() {
    final selectedIds = _controller.selectedNodeIds.toList();
    if (selectedIds.isEmpty) return;
    _controller.bringNodeToFront(selectedIds.first);
  }

  void _sendToBack() {
    final selectedIds = _controller.selectedNodeIds.toList();
    if (selectedIds.isEmpty) return;
    _controller.sendNodeToBack(selectedIds.first);
  }

  void _resetExample() {
    _controller.clearGraph();
    _nodeCounter = 0;
    // Add initial nodes
    for (int i = 0; i < 5; i++) {
      _addRandomNode();
    }
    _controller.fitToView();
  }

  @override
  Widget build(BuildContext context) {
    return ResponsiveControlPanel(
      controller: _controller,
      onReset: _resetExample,
      child: NodeFlowEditor<Map<String, dynamic>, dynamic>(
        controller: _controller,
        nodeBuilder: _buildNode,
        theme: _theme,
      ),
      children: [
        // Add Node section
        const SectionTitle('Add Node'),
        SectionContent(
          child: ControlButton(
            label: 'Add Random Node',
            icon: Icons.add_circle_outline,
            onPressed: _addRandomNode,
          ),
        ),

        // Alignment section
        const SectionTitle('Align'),
        SectionContent(
          child: Grid2Cols(
            buttons: [
              GridButton(
                label: 'Left',
                icon: Icons.align_horizontal_left,
                onPressed: _alignLeft,
              ),
              GridButton(
                label: 'Right',
                icon: Icons.align_horizontal_right,
                onPressed: _alignRight,
              ),
              GridButton(
                label: 'Top',
                icon: Icons.align_vertical_top,
                onPressed: _alignTop,
              ),
              GridButton(
                label: 'Bottom',
                icon: Icons.align_vertical_bottom,
                onPressed: _alignBottom,
              ),
              GridButton(
                label: 'Center H',
                icon: Icons.align_horizontal_center,
                onPressed: _alignCenterHorizontal,
              ),
              GridButton(
                label: 'Center V',
                icon: Icons.align_vertical_center,
                onPressed: _alignMiddleVertical,
              ),
            ],
          ),
        ),

        // Distribution section
        const SectionTitle('Distribute'),
        SectionContent(
          child: Grid2Cols(
            buttons: [
              GridButton(
                label: 'Horizontal',
                icon: Icons.horizontal_distribute,
                onPressed: _distributeHorizontally,
              ),
              GridButton(
                label: 'Vertical',
                icon: Icons.vertical_distribute,
                onPressed: _distributeVertically,
              ),
            ],
          ),
        ),

        // Layout section
        const SectionTitle('Layout'),
        SectionContent(
          child: Grid2Cols(
            buttons: [
              GridButton(
                label: 'Grid',
                icon: Icons.grid_4x4,
                onPressed: _gridLayout,
              ),
              GridButton(
                label: 'Hierarchy',
                icon: Icons.account_tree,
                onPressed: _hierarchicalLayout,
              ),
            ],
          ),
        ),

        // Layering section
        const SectionTitle('Layering'),
        SectionContent(
          child: Grid2Cols(
            buttons: [
              GridButton(
                label: 'To Front',
                icon: Icons.flip_to_front,
                onPressed: _bringToFront,
              ),
              GridButton(
                label: 'To Back',
                icon: Icons.flip_to_back,
                onPressed: _sendToBack,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
