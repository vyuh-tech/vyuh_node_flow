import 'package:flutter/material.dart';
import 'package:vyuh_node_flow/vyuh_node_flow.dart';

import '../../shared/ui_widgets.dart';

class PortLabelsExample extends StatefulWidget {
  const PortLabelsExample({super.key});

  @override
  State<PortLabelsExample> createState() => _PortLabelsExampleState();
}

class _PortLabelsExampleState extends State<PortLabelsExample> {
  late final NodeFlowController<String> _controller;
  late final NodeFlowTheme _theme;
  bool _showLabels = true;
  double _labelOffset = 10.0;
  double _visibilityThreshold = 0.5;
  double _fontSize = 11.0;

  @override
  void initState() {
    super.initState();
    _theme = NodeFlowTheme.light;
    _controller = NodeFlowController<String>(
      initialViewport: const GraphViewport(x: 50, y: 50, zoom: 1.0),
    );
    _setupNodes();
  }

  void _setupNodes() {
    // Node 1: All port positions
    final node1 = Node<String>(
      id: 'node-1',
      type: 'demo',
      position: const Offset(100, 100),
      size: const Size(180, 180),
      data: 'All Positions',
      inputPorts: const [
        Port(
          id: 'input-left',
          name: 'Left Input',
          position: PortPosition.left,
          type: PortType.target,
          offset: Offset(0, 50),
          showLabel: true,
        ),
        Port(
          id: 'input-top',
          name: 'Top',
          position: PortPosition.top,
          type: PortType.target,
          offset: Offset(20, 0),
          showLabel: true,
        ),
      ],
      outputPorts: const [
        Port(
          id: 'output-right',
          name: 'Right Output',
          position: PortPosition.right,
          type: PortType.source,
          offset: Offset(0, 20),
          showLabel: true,
        ),
        Port(
          id: 'output-bottom',
          name: 'Bottom',
          position: PortPosition.bottom,
          type: PortType.source,
          offset: Offset(40, 0),
          showLabel: true,
        ),
      ],
    );

    // Node 2: Different port shapes with labels
    final node2 = Node<String>(
      id: 'node-2',
      type: 'demo',
      position: const Offset(400, 100),
      size: const Size(160, 230),
      data: 'Port Shapes',
      inputPorts: const [
        Port(
          id: 'circle-input',
          name: 'Circle',
          position: PortPosition.left,
          type: PortType.target,
          offset: Offset(0, 20),
          shape: MarkerShapes.circle,
          showLabel: true,
        ),
        Port(
          id: 'square-input',
          name: 'Square',
          position: PortPosition.left,
          type: PortType.target,
          offset: Offset(0, 40),
          shape: MarkerShapes.square,
          showLabel: true,
        ),
        Port(
          id: 'diamond-input',
          name: 'Diamond',
          position: PortPosition.left,
          type: PortType.target,
          offset: Offset(0, 60),
          shape: MarkerShapes.diamond,
          showLabel: true,
        ),
        Port(
          id: 'triangle-input',
          name: 'Triangle',
          position: PortPosition.left,
          type: PortType.target,
          offset: Offset(0, 80),
          shape: MarkerShapes.triangle,
          showLabel: true,
        ),
      ],
      outputPorts: const [
        Port(
          id: 'capsule-output',
          name: 'Capsule',
          position: PortPosition.right,
          type: PortType.source,
          offset: Offset(0, 40),
          shape: MarkerShapes.capsuleHalf,
          showLabel: true,
        ),
      ],
    );

    // Node 3: Multiple ports on same side
    final node3 = Node<String>(
      id: 'node-3',
      type: 'demo',
      position: const Offset(100, 350),
      size: const Size(180, 180),
      data: 'Multiple Ports',
      inputPorts: List.generate(
        3,
        (i) => Port(
          id: 'input-$i',
          name: 'Input ${i + 1}',
          position: PortPosition.left,
          type: PortType.target,
          offset: Offset(0, 20 + (i * 20.0)),
          showLabel: true,
        ),
      ),
      outputPorts: List.generate(
        3,
        (i) => Port(
          id: 'output-$i',
          name: 'Out ${i + 1}',
          position: PortPosition.right,
          type: PortType.source,
          offset: Offset(0, 20 + (i * 20.0)),
          showLabel: true,
        ),
      ),
    );

    // Node 4: Mixed labels (some on, some off)
    final node4 = Node<String>(
      id: 'node-4',
      type: 'demo',
      position: const Offset(400, 350),
      size: const Size(160, 140),
      data: 'Mixed Labels',
      inputPorts: const [
        Port(
          id: 'labeled-input',
          name: 'With Label',
          position: PortPosition.left,
          type: PortType.target,
          offset: Offset(0, 20),
          showLabel: true, // Label enabled
        ),
        Port(
          id: 'unlabeled-input',
          name: 'No Label',
          position: PortPosition.left,
          type: PortType.target,
          offset: Offset(0, 40),
          showLabel: false, // Label disabled
        ),
      ],
      outputPorts: const [
        Port(
          id: 'labeled-output',
          name: 'With Label',
          position: PortPosition.right,
          type: PortType.source,
          offset: Offset(0, 20),
          showLabel: true,
        ),
        Port(
          id: 'unlabeled-output',
          name: 'No Label',
          position: PortPosition.right,
          type: PortType.source,
          offset: Offset(0, 40),
          showLabel: false,
        ),
      ],
    );

    _controller.addNode(node1);
    _controller.addNode(node2);
    _controller.addNode(node3);
    _controller.addNode(node4);

    // Add some connections
    _controller.addConnection(
      Connection(
        id: 'conn-1',
        sourceNodeId: 'node-1',
        sourcePortId: 'output-right',
        targetNodeId: 'node-2',
        targetPortId: 'circle-input',
      ),
    );

    _controller.addConnection(
      Connection(
        id: 'conn-2',
        sourceNodeId: 'node-3',
        sourcePortId: 'output-1',
        targetNodeId: 'node-4',
        targetPortId: 'labeled-input',
      ),
    );
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
      title: 'Port Labels',
      width: 320,
      child: NodeFlowEditor<String>(
        controller: _controller,
        theme: _theme.copyWith(
          portTheme: _theme.portTheme.copyWith(
            showLabel: _showLabels,
            labelTextStyle: TextStyle(
              fontSize: _fontSize,
              color: Colors.indigo.shade900,
              fontWeight: FontWeight.w600,
            ),
            labelOffset: _labelOffset,
            labelVisibilityThreshold: _visibilityThreshold,
          ),
        ),
        nodeBuilder: _buildNode,
      ),
      children: [
        // Show labels toggle
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Show Labels', style: theme.textTheme.bodyMedium),
            Switch(
              value: _showLabels,
              onChanged: (value) {
                setState(() {
                  _showLabels = value;
                });
              },
            ),
          ],
        ),
        const SizedBox(height: 16),
        // Font size slider
        Column(
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
          ],
        ),
        const SizedBox(height: 16),
        // Label offset slider
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
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
        const SizedBox(height: 16),
        // Visibility threshold slider
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Zoom Threshold: ${(_visibilityThreshold * 100).toStringAsFixed(0)}%',
              style: theme.textTheme.bodyMedium,
            ),
            Slider(
              value: _visibilityThreshold,
              min: 0.0,
              max: 1.0,
              divisions: 10,
              onChanged: (value) {
                setState(() {
                  _visibilityThreshold = value;
                });
              },
            ),
          ],
        ),
      ],
    );
  }
}
