import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:vyuh_node_flow/vyuh_node_flow.dart';

import '../../shared/ui_widgets.dart';

class SimpleNodeAdditionExample extends StatefulWidget {
  const SimpleNodeAdditionExample({super.key});

  @override
  State<SimpleNodeAdditionExample> createState() =>
      _SimpleNodeAdditionExampleState();
}

class _SimpleNodeAdditionExampleState extends State<SimpleNodeAdditionExample> {
  late final NodeFlowController<Map<String, dynamic>> _controller;
  late final NodeFlowTheme _theme;
  int _nodeCounter = 4; // Start from 4 since we have 3 initial nodes

  @override
  void initState() {
    super.initState();
    _theme = NodeFlowTheme.light;
    _controller = NodeFlowController<Map<String, dynamic>>(
      config: NodeFlowConfig(),
    );

    // Add initial nodes after first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _addInitialNodes();
    });
  }

  void _addInitialNodes() {
    final initialNodes = [
      Node<Map<String, dynamic>>(
        id: 'node-1',
        type: 'simple',
        position: const Offset(100, 150),
        data: {'label': 'Node 1'},
        size: const Size(150, 100),
        inputPorts: const [
          Port(
            id: 'input',
            name: 'In',
            position: PortPosition.left,
            offset: Offset(0, 50),
          ),
        ],
        outputPorts: const [
          Port(
            id: 'output',
            name: 'Out',
            position: PortPosition.right,
            offset: Offset(0, 50),
          ),
        ],
      ),
      Node<Map<String, dynamic>>(
        id: 'node-2',
        type: 'simple',
        position: const Offset(350, 100),
        data: {'label': 'Node 2'},
        size: const Size(150, 100),
        inputPorts: const [
          Port(
            id: 'input',
            name: 'In',
            position: PortPosition.left,
            offset: Offset(0, 50),
          ),
        ],
        outputPorts: const [
          Port(
            id: 'output',
            name: 'Out',
            position: PortPosition.right,
            offset: Offset(0, 50),
          ),
        ],
      ),
      Node<Map<String, dynamic>>(
        id: 'node-3',
        type: 'simple',
        position: const Offset(350, 250),
        data: {'label': 'Node 3'},
        size: const Size(150, 100),
        inputPorts: const [
          Port(
            id: 'input',
            name: 'In',
            position: PortPosition.left,
            offset: Offset(0, 50),
          ),
        ],
        outputPorts: const [
          Port(
            id: 'output',
            name: 'Out',
            position: PortPosition.right,
            offset: Offset(0, 50),
          ),
        ],
      ),
    ];

    for (final node in initialNodes) {
      _controller.addNode(node);
    }

    // Fit view to show all nodes centered
    Future.delayed(const Duration(milliseconds: 100), () {
      if (mounted) {
        _controller.fitToView();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _addNode() {
    final node = Node<Map<String, dynamic>>(
      id: 'node-$_nodeCounter',
      type: 'simple',
      position: Offset(
        100 + (_nodeCounter * 50.0),
        100 + (_nodeCounter * 50.0),
      ),
      data: {'label': 'Node $_nodeCounter'},
      size: const Size(150, 100),
      inputPorts: const [
        Port(
          id: 'input',
          name: 'In',
          position: PortPosition.left,
          offset: Offset(0, 50),
        ),
      ],
      outputPorts: const [
        Port(
          id: 'output',
          name: 'Out',
          position: PortPosition.right,
          offset: Offset(0, 50),
        ),
      ],
    );

    _controller.addNode(node);
    _nodeCounter++;
  }

  Widget _buildNode(BuildContext context, Node<Map<String, dynamic>> node) {
    // Calculate inner border radius by subtracting border width from outer radius
    final outerBorderRadius = _theme.nodeTheme.borderRadius;
    final borderWidth = _theme.nodeTheme.borderWidth;
    final outerRadius = outerBorderRadius.topLeft.x;
    final innerRadius = math.max(0.0, outerRadius - borderWidth);

    final theme = Theme.of(context);

    // Soft indigo
    final nodeColor = Colors.indigo.shade100;
    final iconColor = Colors.indigo;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: nodeColor,
        borderRadius: BorderRadius.circular(innerRadius),
      ),
      child: Center(
        child: Text(
          node.data['label'] ?? '',
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.bold,
            color: iconColor,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ResponsiveControlPanel(
      title: 'Controls',
      width: 320,
      child: NodeFlowEditor<Map<String, dynamic>>(
        controller: _controller,
        nodeBuilder: _buildNode,
        theme: _theme,
      ),
      children: [
        const SectionTitle('Actions'),
        const SizedBox(height: 12),
        ControlButton(label: 'Add Node', icon: Icons.add, onPressed: _addNode),
        const SizedBox(height: 8),
        ControlButton(
          label: 'Clear All',
          icon: Icons.clear,
          onPressed: () => _controller.clearGraph(),
        ),
        const SizedBox(height: 16),
        const InfoCard(
          title: 'Instructions',
          content:
              'Add nodes and connect them by dragging from output to input ports',
        ),
      ],
    );
  }
}
