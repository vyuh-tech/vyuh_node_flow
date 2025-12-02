import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:vyuh_node_flow/vyuh_node_flow.dart';

import '../../shared/ui_widgets.dart';

class EditableConnectionsExample extends StatefulWidget {
  const EditableConnectionsExample({super.key});

  @override
  State<EditableConnectionsExample> createState() =>
      _EditableConnectionsExampleState();
}

class _EditableConnectionsExampleState
    extends State<EditableConnectionsExample> {
  late final NodeFlowController<Map<String, dynamic>> _controller;
  late NodeFlowTheme _theme;

  @override
  void initState() {
    super.initState();
    _theme = _createTheme();
    _controller = NodeFlowController<Map<String, dynamic>>(
      config: NodeFlowConfig(),
    );

    // Add initial nodes and connections after first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _addInitialNodesAndConnections();
    });
  }

  NodeFlowTheme _createTheme() {
    return NodeFlowTheme.light.copyWith(
      connectionTheme: NodeFlowTheme.light.connectionTheme.copyWith(
        style: EditableSmoothStepConnectionStyle(),
        selectedColor: Colors.deepPurple,
        selectedStrokeWidth: 3.0,
        cornerRadius: 12.0,
      ),
    );
  }

  void _addInitialNodesAndConnections() {
    // Create nodes in a grid layout
    final nodes = [
      Node<Map<String, dynamic>>(
        id: 'node-1',
        type: 'input',
        position: const Offset(100, 100),
        data: {'label': 'Input A'},
        size: const Size(150, 100),
        outputPorts: const [
          Port(
            id: 'output',
            name: 'Out',
            position: PortPosition.right,
            offset: Offset(2, 50),
          ),
        ],
      ),
      Node<Map<String, dynamic>>(
        id: 'node-2',
        type: 'input',
        position: const Offset(100, 250),
        data: {'label': 'Input B'},
        size: const Size(150, 100),
        outputPorts: const [
          Port(
            id: 'output',
            name: 'Out',
            position: PortPosition.right,
            offset: Offset(2, 50),
          ),
        ],
      ),
      Node<Map<String, dynamic>>(
        id: 'node-3',
        type: 'process',
        position: const Offset(400, 150),
        data: {'label': 'Process'},
        size: const Size(150, 120),
        inputPorts: const [
          Port(
            id: 'input1',
            name: 'In 1',
            position: PortPosition.left,
            offset: Offset(-2, 40),
          ),
          Port(
            id: 'input2',
            name: 'In 2',
            position: PortPosition.left,
            offset: Offset(-2, 80),
          ),
        ],
        outputPorts: const [
          Port(
            id: 'output',
            name: 'Out',
            position: PortPosition.right,
            offset: Offset(2, 60),
          ),
        ],
      ),
      Node<Map<String, dynamic>>(
        id: 'node-4',
        type: 'output',
        position: const Offset(700, 175),
        data: {'label': 'Output'},
        size: const Size(150, 100),
        inputPorts: const [
          Port(
            id: 'input',
            name: 'In',
            position: PortPosition.left,
            offset: Offset(-2, 50),
          ),
        ],
      ),
    ];

    for (final node in nodes) {
      _controller.addNode(node);
    }

    // Create connections with editable control points
    final connections = [
      // Simple connection without control points (uses default algorithm)
      Connection(
        id: 'conn-1',
        sourceNodeId: 'node-1',
        sourcePortId: 'output',
        targetNodeId: 'node-3',
        targetPortId: 'input1',
      ),
      // Connection with control points (manually edited path)
      Connection(
        id: 'conn-2',
        sourceNodeId: 'node-2',
        sourcePortId: 'output',
        targetNodeId: 'node-3',
        targetPortId: 'input2',
        controlPoints: [const Offset(320, 300), const Offset(320, 230)],
      ),
      // Another connection without control points
      Connection(
        id: 'conn-3',
        sourceNodeId: 'node-3',
        sourcePortId: 'output',
        targetNodeId: 'node-4',
        targetPortId: 'input',
      ),
    ];

    for (final connection in connections) {
      _controller.addConnection(connection);
    }

    // Fit view to show all nodes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _controller.fitToView();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _addControlPoint() {
    // Add a control point to the middle of the first connection
    _controller.addControlPoint('conn-1', const Offset(300, 100));
  }

  void _removeControlPoints() {
    // Clear all control points from the second connection
    _controller.clearControlPoints('conn-2');
  }

  void _toggleEditableStyle() {
    setState(() {
      final currentStyle = _theme.connectionTheme.style;
      final isEditable = currentStyle is EditablePathConnectionStyle;

      _theme = _theme.copyWith(
        connectionTheme: _theme.connectionTheme.copyWith(
          style: isEditable
              ? ConnectionStyles.smoothstep
              : const EditableSmoothStepConnectionStyle(),
        ),
      );
    });
  }

  Widget _buildNode(BuildContext context, Node<Map<String, dynamic>> node) {
    final outerBorderRadius = _theme.nodeTheme.borderRadius;
    final borderWidth = _theme.nodeTheme.borderWidth;
    final outerRadius = outerBorderRadius.topLeft.x;
    final innerRadius = math.max(0.0, outerRadius - borderWidth);

    final theme = Theme.of(context);

    // Different colors for different node types
    final Color nodeColor;
    final Color iconColor;

    switch (node.type) {
      case 'input':
        nodeColor = Colors.green.shade100;
        iconColor = Colors.green.shade700;
        break;
      case 'process':
        nodeColor = Colors.blue.shade100;
        iconColor = Colors.blue.shade700;
        break;
      case 'output':
        nodeColor = Colors.orange.shade100;
        iconColor = Colors.orange.shade700;
        break;
      default:
        nodeColor = Colors.grey.shade100;
        iconColor = Colors.grey.shade700;
    }

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
          textAlign: TextAlign.center,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isEditable =
        _theme.connectionTheme.style is EditablePathConnectionStyle;

    return ResponsiveControlPanel(
      title: 'Controls',
      width: 340,
      child: NodeFlowEditor<Map<String, dynamic>>(
        controller: _controller,
        nodeBuilder: _buildNode,
        theme: _theme,
      ),
      children: [
        const SectionTitle('Editable Connections'),
        const SizedBox(height: 12),
        ControlButton(
          label: isEditable ? 'Disable Editing' : 'Enable Editing',
          icon: isEditable ? Icons.lock : Icons.edit,
          onPressed: _toggleEditableStyle,
        ),
        const SizedBox(height: 8),
        ControlButton(
          label: 'Add Control Point',
          icon: Icons.add_location,
          onPressed: isEditable ? _addControlPoint : null,
        ),
        const SizedBox(height: 8),
        ControlButton(
          label: 'Clear Control Points',
          icon: Icons.clear_all,
          onPressed: isEditable ? _removeControlPoints : null,
        ),
        const SizedBox(height: 16),
        const InfoCard(
          title: 'Instructions',
          content:
              '1. Enable editing mode to see control points\n'
              '2. Drag control points to modify connection paths\n'
              '3. Control points define waypoints for smooth step routing\n'
              '4. Connections without control points use automatic routing',
        ),
        const SizedBox(height: 16),
        const InfoCard(
          title: 'Features',
          content:
              '• Drag control points to customize paths\n'
              '• Add/remove control points programmatically\n'
              '• Maintains orthogonal (90°) routing\n'
              '• Smooth rounded corners at bends',
        ),
      ],
    );
  }
}
