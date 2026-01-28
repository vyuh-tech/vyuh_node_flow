import 'package:flutter/material.dart';
import 'package:vyuh_node_flow/vyuh_node_flow.dart';

import '../shared/ui_widgets.dart';

class PortLabelsExample extends StatefulWidget {
  const PortLabelsExample({super.key});

  @override
  State<PortLabelsExample> createState() => _PortLabelsExampleState();
}

class _PortLabelsExampleState extends State<PortLabelsExample> {
  final _theme = NodeFlowTheme.light;
  double _labelOffset = 10.0;
  double _fontSize = 11.0;

  // Create controller with initial nodes and connections
  final _controller = NodeFlowController<String, dynamic>(
    initialViewport: const GraphViewport(x: 50, y: 50, zoom: 1.0),
    nodes: _createNodes(),
    connections: _createConnections(),
  );

  static List<Node<String>> _createNodes() {
    return [
      // Node 1: All port positions
      Node<String>(
        id: 'node-1',
        type: 'demo',
        position: const Offset(100, 100),
        size: const Size(180, 180),
        data: 'All Positions',
        ports: [
          Port(
            id: 'input-left',
            name: 'Left Input',
            position: PortPosition.left,
            type: PortType.input,
            offset: Offset(-2, 90), // Vertical center
            showLabel: true,
          ),
          Port(
            id: 'input-top',
            name: 'Top',
            position: PortPosition.top,
            type: PortType.input,
            offset: Offset(90, -2), // Horizontal center
            showLabel: true,
          ),
          Port(
            id: 'output-right',
            name: 'Right Output',
            position: PortPosition.right,
            type: PortType.output,
            offset: Offset(2, 90), // Vertical center
            showLabel: true,
          ),
          Port(
            id: 'output-bottom',
            name: 'Bottom',
            position: PortPosition.bottom,
            type: PortType.output,
            offset: Offset(90, 2), // Horizontal center
            showLabel: true,
          ),
        ],
      ),
      // Node 2: Different port shapes with labels
      Node<String>(
        id: 'node-2',
        type: 'demo',
        position: const Offset(400, 100),
        size: const Size(160, 230),
        data: 'Port Shapes',
        ports: [
          Port(
            id: 'circle-input',
            name: 'Circle',
            position: PortPosition.left,
            type: PortType.input,
            offset: Offset(-2, 20),
            shape: MarkerShapes.circle,
            showLabel: true,
          ),
          Port(
            id: 'rectangle-input',
            name: 'Rectangle',
            position: PortPosition.left,
            type: PortType.input,
            offset: Offset(-2, 50),
            shape: MarkerShapes.rectangle,
            showLabel: true,
          ),
          Port(
            id: 'diamond-input',
            name: 'Diamond',
            position: PortPosition.left,
            type: PortType.input,
            offset: Offset(-2, 80),
            shape: MarkerShapes.diamond,
            showLabel: true,
          ),
          Port(
            id: 'triangle-input',
            name: 'Triangle',
            position: PortPosition.left,
            type: PortType.input,
            offset: Offset(-2, 110),
            shape: MarkerShapes.triangle,
            showLabel: true,
          ),
          Port(
            id: 'capsule-output',
            name: 'Capsule',
            position: PortPosition.right,
            type: PortType.output,
            offset: Offset(2, 115), // Vertical center of 230 height
            shape: MarkerShapes.capsuleHalf,
            showLabel: true,
          ),
        ],
      ),
      // Node 3: Multiple ports on same side
      Node<String>(
        id: 'node-3',
        type: 'demo',
        position: const Offset(100, 350),
        size: const Size(180, 180),
        data: 'Multiple Ports',
        ports: [
          ...List.generate(
            3,
            (i) => Port(
              id: 'input-$i',
              name: 'Input ${i + 1}',
              position: PortPosition.left,
              type: PortType.input,
              offset: Offset(-2, 20 + (i * 30.0)),
              showLabel: true,
            ),
          ),
          ...List.generate(
            3,
            (i) => Port(
              id: 'output-$i',
              name: 'Out ${i + 1}',
              position: PortPosition.right,
              type: PortType.output,
              offset: Offset(2, 20 + (i * 30.0)),
              showLabel: true,
            ),
          ),
        ],
      ),
      // Node 4: Mixed labels (some on, some off)
      Node<String>(
        id: 'node-4',
        type: 'demo',
        position: const Offset(400, 350),
        size: const Size(160, 140),
        data: 'Mixed Labels',
        ports: [
          Port(
            id: 'labeled-input',
            name: 'With Label',
            position: PortPosition.left,
            type: PortType.input,
            offset: Offset(-2, 20), // Starting offset
            showLabel: true, // Label enabled
          ),
          Port(
            id: 'unlabeled-input',
            name: 'No Label',
            position: PortPosition.left,
            type: PortType.input,
            offset: Offset(-2, 50), // 20 + 30 separation
            showLabel: false, // Label disabled
          ),
          Port(
            id: 'labeled-output',
            name: 'With Label',
            position: PortPosition.right,
            type: PortType.output,
            offset: Offset(2, 20), // Starting offset
            showLabel: true,
          ),
          Port(
            id: 'unlabeled-output',
            name: 'No Label',
            position: PortPosition.right,
            type: PortType.output,
            offset: Offset(2, 50), // 20 + 30 separation
            showLabel: false,
          ),
        ],
      ),
    ];
  }

  static List<Connection> _createConnections() {
    return [
      Connection(
        id: 'conn-1',
        sourceNodeId: 'node-1',
        sourcePortId: 'output-right',
        targetNodeId: 'node-2',
        targetPortId: 'circle-input',
      ),
      Connection(
        id: 'conn-2',
        sourceNodeId: 'node-3',
        sourcePortId: 'output-1',
        targetNodeId: 'node-4',
        targetPortId: 'labeled-input',
      ),
    ];
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Widget _buildNode(BuildContext context, Node<String> node) {
    final theme = Theme.of(context);

    // Light theme colors for nodes
    final nodeColor = Colors.indigo.shade50;
    final textColor = Colors.indigo.shade900;
    final subtextColor = Colors.indigo.shade700;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: nodeColor,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              node.data,
              style: theme.textTheme.titleSmall?.copyWith(
                color: textColor,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Text(
              node.id,
              style: theme.textTheme.bodySmall?.copyWith(
                color: subtextColor,
                fontSize: 10,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ResponsiveControlPanel(
      controller: _controller,
      onReset: () {
        _controller.clearGraph();
        for (final node in _createNodes()) {
          _controller.addNode(node);
        }
        for (final conn in _createConnections()) {
          _controller.addConnection(conn);
        }
        _controller.fitToView();
      },
      child: NodeFlowEditor<String, dynamic>(
        controller: _controller,
        theme: _theme.copyWith(
          portTheme: _theme.portTheme.copyWith(
            labelTextStyle: TextStyle(
              fontSize: _fontSize,
              color: Colors.indigo.shade900,
              fontWeight: FontWeight.w600,
            ),
            labelOffset: _labelOffset,
          ),
        ),
        nodeBuilder: _buildNode,
        events: NodeFlowEvents(onInit: () => _controller.fitToView()),
      ),
      children: [
        const SectionTitle('Settings'),
        SectionContent(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Font Size: ${_fontSize.toStringAsFixed(0)}',
                style: theme.textTheme.bodyMedium,
              ),
              Slider(
                value: _fontSize,
                min: 8.0,
                max: 16.0,
                divisions: 8,
                onChanged: (value) {
                  setState(() {
                    _fontSize = value;
                  });
                },
              ),
              const SizedBox(height: 12),
              Text(
                'Label Offset: ${_labelOffset.toStringAsFixed(0)}',
                style: theme.textTheme.bodyMedium,
              ),
              Slider(
                value: _labelOffset,
                min: 4.0,
                max: 20.0,
                divisions: 16,
                onChanged: (value) {
                  setState(() {
                    _labelOffset = value;
                  });
                },
              ),
            ],
          ),
        ),
      ],
    );
  }
}
