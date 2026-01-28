import 'package:flutter/material.dart';
import 'package:vyuh_node_flow/vyuh_node_flow.dart';

import '../shared/ui_widgets.dart';

/// Example demonstrating the NodeFlowViewer widget
class ViewerExample extends StatefulWidget {
  const ViewerExample({super.key});

  @override
  State<ViewerExample> createState() => _ViewerExampleState();
}

class _ViewerExampleState extends State<ViewerExample> {
  final _controller = NodeFlowController<String, dynamic>(
    nodes: _createSampleNodes(),
    connections: _createSampleConnections(),
  );

  @override
  void initState() {
    super.initState();
    // NodeFlowViewer doesn't support events, so use post-frame callback
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _controller.fitToView();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ResponsiveControlPanel(
      controller: _controller,
      onReset: () => _controller.fitToView(),
      child: NodeFlowViewer<String, dynamic>(
        controller: _controller,
        nodeBuilder: _buildNode,
        theme: NodeFlowTheme.light,
        // Uses NodeFlowBehavior.preview by default (pan, zoom, select, drag)
      ),
      children: [
        const SectionTitle('About'),
        SectionContent(
          child: InfoCard(
            title: 'Read-Only Viewer',
            content:
                'The NodeFlowViewer provides a read-only view of node graphs. It supports panning and zooming but disables editing operations like creating connections or moving nodes.',
          ),
        ),
        const SectionTitle('Navigation'),
        SectionContent(
          child: Grid2Cols(
            buttons: [
              GridButton(
                icon: Icons.center_focus_strong,
                label: 'Fit to View',
                onPressed: () => _controller.fitToView(),
              ),
              GridButton(
                icon: Icons.zoom_in,
                label: 'Zoom In',
                onPressed: () => _controller.zoomBy(0.2),
              ),
              GridButton(
                icon: Icons.zoom_out,
                label: 'Zoom Out',
                onPressed: () => _controller.zoomBy(-0.2),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// Create sample nodes for the viewer
  static List<Node<String>> _createSampleNodes() {
    return [
      Node<String>(
        id: 'input',
        type: 'input',
        data: 'Input Node',
        position: const Offset(100, 100),
        size: const Size(150, 80),
        ports: [
          Port(
            id: 'out',
            name: 'Output',
            type: PortType.output,
            position: PortPosition.right,
            offset: Offset(2, 20),
          ),
        ],
      ),
      Node<String>(
        id: 'process',
        type: 'process',
        data: 'Processing Node',
        position: const Offset(300, 200),
        size: const Size(150, 100),
        ports: [
          Port(
            id: 'in',
            name: 'Input',
            type: PortType.input,
            position: PortPosition.left,
            offset: Offset(-2, 20),
          ),
          Port(
            id: 'out1',
            name: 'Result',
            type: PortType.output,
            position: PortPosition.right,
            offset: Offset(2, 20),
          ),
          Port(
            id: 'out2',
            name: 'Error',
            type: PortType.output,
            position: PortPosition.right,
            offset: Offset(2, 20),
          ),
        ],
      ),
      Node<String>(
        id: 'output1',
        type: 'output',
        data: 'Output Node 1',
        position: const Offset(500, 150),
        size: const Size(150, 80),
        ports: [
          Port(
            id: 'in',
            name: 'Input',
            type: PortType.input,
            position: PortPosition.left,
            offset: Offset(-2, 20),
          ),
        ],
      ),
      Node<String>(
        id: 'output2',
        type: 'output',
        data: 'Output Node 2',
        position: const Offset(500, 280),
        size: const Size(150, 80),
        ports: [
          Port(
            id: 'in',
            name: 'Input',
            type: PortType.input,
            position: PortPosition.left,
            offset: Offset(-2, 20),
          ),
        ],
      ),
    ];
  }

  /// Create sample connections between nodes
  static List<Connection> _createSampleConnections() {
    return [
      Connection(
        id: 'conn1',
        sourceNodeId: 'input',
        sourcePortId: 'out',
        targetNodeId: 'process',
        targetPortId: 'in',
      ),
      Connection(
        id: 'conn2',
        sourceNodeId: 'process',
        sourcePortId: 'out1',
        targetNodeId: 'output1',
        targetPortId: 'in',
      ),
      Connection(
        id: 'conn3',
        sourceNodeId: 'process',
        sourcePortId: 'out2',
        targetNodeId: 'output2',
        targetPortId: 'in',
      ),
    ];
  }

  /// Build a node widget for display
  Widget _buildNode(BuildContext context, Node<String> node) {
    IconData nodeIcon;

    // Customize appearance based on node data
    switch (node.data) {
      case 'Input Node':
        nodeIcon = Icons.input;
        break;
      case 'Processing Node':
        nodeIcon = Icons.settings;
        break;
      case 'Output Node 1':
      case 'Output Node 2':
        nodeIcon = Icons.output;
        break;
      default:
        nodeIcon = Icons.circle;
    }

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(nodeIcon, size: 20),
        const SizedBox(height: 6),
        Flexible(
          child: Text(
            node.data,
            style: const TextStyle(fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
