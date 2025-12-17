import 'package:flutter/material.dart';
import 'package:vyuh_node_flow/vyuh_node_flow.dart';

/// Example demonstrating the NodeFlowViewer widget
class ViewerExample extends StatefulWidget {
  const ViewerExample({super.key});

  @override
  State<ViewerExample> createState() => _ViewerExampleState();
}

class _ViewerExampleState extends State<ViewerExample> {
  late final NodeFlowController<String> _controller;

  @override
  void initState() {
    super.initState();
    _controller = NodeFlowController<String>();

    // Load sample data
    final nodes = _createSampleNodes();
    final connections = _createSampleConnections();

    // Add nodes to controller
    for (final node in nodes.values) {
      _controller.addNode(node);
    }

    // Add connections to controller
    for (final connection in connections) {
      _controller.addConnection(connection);
    }

    // Fit view to show all nodes centered
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
    return NodeFlowViewer<String>(
      controller: _controller,
      nodeBuilder: _buildNode,
      theme: NodeFlowTheme.light,
      // Uses NodeFlowBehavior.preview by default (pan, zoom, select, drag)
      scrollToZoom: true,
      showAnnotations: false,
    );
  }

  /// Create sample nodes for the viewer
  Map<String, Node<String>> _createSampleNodes() {
    return {
      'input': Node<String>(
        id: 'input',
        type: 'input',
        data: 'Input Node',
        position: const Offset(100, 100),
        size: const Size(150, 80),
        inputPorts: [],
        outputPorts: [
          Port(
            id: 'out',
            name: 'Output',
            position: PortPosition.right,
            offset: Offset(2, 20),
          ),
        ],
      ),
      'process': Node<String>(
        id: 'process',
        type: 'process',
        data: 'Processing Node',
        position: const Offset(300, 200),
        size: const Size(150, 100),
        inputPorts: [
          Port(
            id: 'in',
            name: 'Input',
            position: PortPosition.left,
            offset: Offset(-2, 20),
          ),
        ],
        outputPorts: [
          Port(
            id: 'out1',
            name: 'Result',
            position: PortPosition.right,
            offset: Offset(2, 20),
          ),
          Port(
            id: 'out2',
            name: 'Error',
            position: PortPosition.right,
            offset: Offset(2, 20),
          ),
        ],
      ),
      'output1': Node<String>(
        id: 'output1',
        type: 'output',
        data: 'Output Node 1',
        position: const Offset(500, 150),
        size: const Size(150, 80),
        inputPorts: [
          Port(
            id: 'in',
            name: 'Input',
            position: PortPosition.left,
            offset: Offset(-2, 20),
          ),
        ],
        outputPorts: [],
      ),
      'output2': Node<String>(
        id: 'output2',
        type: 'output',
        data: 'Output Node 2',
        position: const Offset(500, 280),
        size: const Size(150, 80),
        inputPorts: [
          Port(
            id: 'in',
            name: 'Input',
            position: PortPosition.left,
            offset: Offset(-2, 20),
          ),
        ],
        outputPorts: [],
      ),
    };
  }

  /// Create sample connections between nodes
  List<Connection> _createSampleConnections() {
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
