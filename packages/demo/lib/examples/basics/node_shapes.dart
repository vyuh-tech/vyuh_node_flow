import 'package:flutter/material.dart';
import 'package:vyuh_node_flow/vyuh_node_flow.dart';

import '../../shared/ui_widgets.dart';

class NodeShapesExample extends StatefulWidget {
  const NodeShapesExample({super.key});

  @override
  State<NodeShapesExample> createState() => _NodeShapesExampleState();
}

class _NodeShapesExampleState extends State<NodeShapesExample> {
  late final NodeFlowController<Map<String, dynamic>> _controller;
  late final NodeFlowTheme _theme;

  @override
  void initState() {
    super.initState();
    _theme = NodeFlowTheme.light;
    _controller = NodeFlowController<Map<String, dynamic>>(
      config: NodeFlowConfig(),
    );

    // Add example nodes with different shapes
    _addExampleNodes();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _addExampleNodes() {
    // Rectangle (default) node - output only
    final rectangleNode = Node<Map<String, dynamic>>(
      id: 'rectangle',
      type: 'Process',
      position: const Offset(100, 100),
      data: {'label': 'Rectangle\n(Default)'},
      size: const Size(150, 100),
      outputPorts: const [
        Port(
          id: 'output',
          name: 'Out',
          position: PortPosition.right,
          offset: Offset(0, 50),
        ),
      ],
    );

    // Circle node - input only, allows multiple connections
    final circleNode = Node<Map<String, dynamic>>(
      id: 'circle',
      type: 'Terminal',
      position: const Offset(300, 100),
      data: {'label': 'Circle\nStart/End'},
      size: const Size(120, 120),
      inputPorts: const [
        Port(
          id: 'input',
          name: 'In',
          position: PortPosition.left,
          multiConnections: true,
        ),
      ],
    );

    // Diamond node
    final diamondNode = Node<Map<String, dynamic>>(
      id: 'diamond',
      type: 'Decision',
      position: const Offset(100, 280),
      data: {'label': 'Diamond\nDecision'},
      size: const Size(140, 100),
      inputPorts: const [
        Port(id: 'input', name: 'In', position: PortPosition.top),
      ],
      outputPorts: const [
        Port(id: 'output-yes', name: 'Yes', position: PortPosition.right),
        Port(id: 'output-no', name: 'No', position: PortPosition.bottom),
      ],
    );

    // Hexagon node - horizontal
    final hexagonNode = Node<Map<String, dynamic>>(
      id: 'hexagon',
      type: 'Preparation',
      position: const Offset(300, 280),
      data: {'label': 'Hexagon\nPreparation'},
      size: const Size(160, 100),
      inputPorts: const [
        Port(id: 'input', name: 'In', position: PortPosition.left),
      ],
      outputPorts: const [
        Port(id: 'output', name: 'Out', position: PortPosition.right),
      ],
    );

    // Vertical hexagon node
    final verticalHexagonNode = Node<Map<String, dynamic>>(
      id: 'hexagon-vertical',
      type: 'VerticalPreparation',
      position: const Offset(500, 280),
      data: {'label': 'Vertical\nHexagon'},
      size: const Size(120, 150),
      inputPorts: const [
        Port(id: 'input', name: 'In', position: PortPosition.top),
      ],
      outputPorts: const [
        Port(id: 'output', name: 'Out', position: PortPosition.bottom),
      ],
    );

    // Add connections
    final connections = [
      Connection(
        id: 'conn-1',
        sourceNodeId: 'rectangle',
        sourcePortId: 'output',
        targetNodeId: 'circle',
        targetPortId: 'input',
      ),
      Connection(
        id: 'conn-2',
        sourceNodeId: 'diamond',
        sourcePortId: 'output-yes',
        targetNodeId: 'hexagon',
        targetPortId: 'input',
      ),
      Connection(
        id: 'conn-3',
        sourceNodeId: 'hexagon',
        sourcePortId: 'output',
        targetNodeId: 'hexagon-vertical',
        targetPortId: 'input',
      ),
    ];

    _controller.addNode(rectangleNode);
    _controller.addNode(circleNode);
    _controller.addNode(diamondNode);
    _controller.addNode(hexagonNode);
    _controller.addNode(verticalHexagonNode);

    for (final connection in connections) {
      _controller.addConnection(connection);
    }

    // Fit the view to show all nodes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Future.delayed(const Duration(milliseconds: 100), () {
        if (mounted) {
          _controller.fitToView();
        }
      });
    });
  }

  Widget _buildNode(BuildContext context, Node<Map<String, dynamic>> node) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // Different text colors for different node types
    Color textColor;

    switch (node.type) {
      case 'Terminal':
        textColor = isDark ? const Color(0xFF88D5B3) : const Color(0xFF1B5E3F);
        break;
      case 'Decision':
        textColor = isDark ? const Color(0xFFD5B388) : const Color(0xFF5E3F1B);
        break;
      case 'Preparation':
      case 'VerticalPreparation':
        textColor = isDark ? const Color(0xFFB388D5) : const Color(0xFF3F1B5E);
        break;
      default:
        textColor = isDark ? const Color(0xFF88B3D5) : const Color(0xFF1B3F5E);
    }

    return Center(
      child: Text(
        node.data['label'] ?? '',
        textAlign: TextAlign.center,
        style: theme.textTheme.titleSmall?.copyWith(
          fontWeight: FontWeight.bold,
          color: textColor,
        ),
      ),
    );
  }

  NodeShape? _buildNodeShape(
    BuildContext context,
    Node<Map<String, dynamic>> node,
  ) {
    switch (node.type) {
      case 'Terminal':
        return CircleShape();
      case 'Decision':
        return DiamondShape();
      case 'Preparation':
        return const HexagonShape(orientation: HexagonOrientation.horizontal);
      case 'VerticalPreparation':
        return const HexagonShape(orientation: HexagonOrientation.vertical);
      default:
        return null; // Rectangular node
    }
  }

  @override
  Widget build(BuildContext context) {
    return ResponsiveControlPanel(
      title: 'Node Shapes',
      width: 320,
      child: NodeFlowEditor<Map<String, dynamic>>(
        controller: _controller,
        nodeBuilder: _buildNode,
        nodeShapeBuilder: _buildNodeShape,
        theme: _theme,
      ),
      children: [
        const InfoCard(
          title: 'About',
          content:
              'Demonstrates different node shapes including Rectangle (default), Circle, Diamond, and Hexagon (horizontal & vertical)',
        ),
        const SizedBox(height: 16),
        const SectionTitle('Actions'),
        const SizedBox(height: 12),
        ControlButton(
          label: 'Reset',
          icon: Icons.refresh,
          onPressed: () {
            _controller.clearGraph();
            _addExampleNodes();
          },
        ),
      ],
    );
  }
}
