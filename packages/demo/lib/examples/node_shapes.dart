import 'package:flutter/material.dart';
import 'package:vyuh_node_flow/vyuh_node_flow.dart';

import '../shared/ui_widgets.dart';

class NodeShapesExample extends StatefulWidget {
  const NodeShapesExample({super.key});

  @override
  State<NodeShapesExample> createState() => _NodeShapesExampleState();
}

class _NodeShapesExampleState extends State<NodeShapesExample> {
  final _theme = NodeFlowTheme.light;

  // Create controller with initial nodes
  final _controller = NodeFlowController<Map<String, dynamic>, dynamic>(
    config: NodeFlowConfig(),
    nodes: _createNodes(),
    connections: _createConnections(),
  );

  static List<Node<Map<String, dynamic>>> _createNodes() {
    return [
      // Rectangle (default) node - output only
      Node<Map<String, dynamic>>(
        id: 'rectangle',
        type: 'Process',
        position: const Offset(100, 100),
        data: {'label': 'Rectangle\n(Default)'},
        size: const Size(150, 100),
        ports: [
          Port(
            id: 'output',
            name: 'Out',
            type: PortType.output,
            position: PortPosition.right,
            offset: Offset(2, 50),
          ),
        ],
      ),
      // Circle node - input only, allows multiple connections
      // Shaped nodes use Offset.zero (default) since anchors define port positions
      Node<Map<String, dynamic>>(
        id: 'circle',
        type: 'Terminal',
        position: const Offset(300, 100),
        data: {'label': 'Circle\nStart/End'},
        size: const Size(120, 120),
        ports: [
          Port(
            id: 'input',
            name: 'In',
            type: PortType.input,
            position: PortPosition.left,
            multiConnections: true,
          ),
        ],
      ),
      // Diamond node
      // Shaped nodes use Offset.zero (default) since anchors define port positions
      Node<Map<String, dynamic>>(
        id: 'diamond',
        type: 'Decision',
        position: const Offset(100, 280),
        data: {'label': 'Diamond\nDecision'},
        size: const Size(140, 100),
        ports: [
          Port(
            id: 'input',
            name: 'In',
            type: PortType.input,
            position: PortPosition.top,
          ),
          Port(
            id: 'output-yes',
            name: 'Yes',
            type: PortType.output,
            position: PortPosition.right,
          ),
          Port(
            id: 'output-no',
            name: 'No',
            type: PortType.output,
            position: PortPosition.bottom,
          ),
        ],
      ),
      // Hexagon node - horizontal
      // Shaped nodes use Offset.zero (default) since anchors define port positions
      Node<Map<String, dynamic>>(
        id: 'hexagon',
        type: 'Preparation',
        position: const Offset(300, 280),
        data: {'label': 'Hexagon\nPreparation'},
        size: const Size(160, 100),
        ports: [
          Port(
            id: 'input',
            name: 'In',
            type: PortType.input,
            position: PortPosition.left,
          ),
          Port(
            id: 'output',
            name: 'Out',
            type: PortType.output,
            position: PortPosition.right,
          ),
        ],
      ),
      // Vertical hexagon node
      // Shaped nodes use Offset.zero (default) since anchors define port positions
      Node<Map<String, dynamic>>(
        id: 'hexagon-vertical',
        type: 'VerticalPreparation',
        position: const Offset(500, 280),
        data: {'label': 'Vertical\nHexagon'},
        size: const Size(120, 150),
        ports: [
          Port(
            id: 'input',
            name: 'In',
            type: PortType.input,
            position: PortPosition.top,
          ),
          Port(
            id: 'output',
            name: 'Out',
            type: PortType.output,
            position: PortPosition.bottom,
          ),
        ],
      ),
    ];
  }

  static List<Connection> _createConnections() {
    return [
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
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
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

  void _resetGraph() {
    _controller.clearGraph();

    for (final node in _createNodes()) {
      _controller.addNode(node);
    }
    for (final connection in _createConnections()) {
      _controller.addConnection(connection);
    }

    _controller.fitToView();
  }

  @override
  Widget build(BuildContext context) {
    return ResponsiveControlPanel(
      controller: _controller,
      onReset: _resetGraph,
      child: NodeFlowEditor<Map<String, dynamic>, dynamic>(
        controller: _controller,
        nodeBuilder: _buildNode,
        nodeShapeBuilder: _buildNodeShape,
        theme: _theme,
        events: NodeFlowEvents(onInit: () => _controller.fitToView()),
      ),
      children: [
        const SectionTitle('About'),
        SectionContent(
          child: InfoCard(
            title: 'Node Shapes',
            content:
                'Demonstrates different node shapes including Rectangle (default), Circle, Diamond, and Hexagon (horizontal & vertical)',
          ),
        ),
      ],
    );
  }
}
