import 'package:flutter/material.dart';
import 'package:vyuh_node_flow/vyuh_node_flow.dart';

class ConnectionValidationExample extends StatefulWidget {
  const ConnectionValidationExample({super.key});

  @override
  State<ConnectionValidationExample> createState() =>
      _ConnectionValidationExampleState();
}

class _ConnectionValidationExampleState
    extends State<ConnectionValidationExample> {
  late final NodeFlowController<String> _controller;
  String _lastMessage = '';

  @override
  void initState() {
    super.initState();
    _controller = NodeFlowController<String>();
    _setupExampleGraph();
  }

  void _setupExampleGraph() {
    // Create nodes with different types and port configurations
    final inputNode = Node<String>(
      id: 'input',
      type: 'input',
      position: const Offset(100, 100),
      size: const Size(120, 80),
      data: 'Input Node',
      outputPorts: [
        const Port(
          id: 'out1',
          name: 'Output 1',
          position: PortPosition.right,
          offset: Offset(0, 20),
        ),
        const Port(
          id: 'out2',
          name: 'Output 2',
          position: PortPosition.right,
          multiConnections: true,
          offset: Offset(0, 40),
        ),
      ],
    );

    final processingNode = Node<String>(
      id: 'processing',
      type: 'processing',
      position: const Offset(300, 100),
      size: const Size(140, 100),
      data: 'Processing Node',
      inputPorts: [
        const Port(
          id: 'in1',
          name: 'Input 1',
          position: PortPosition.left,
          offset: Offset(0, 20),
        ),
        const Port(
          id: 'in2',
          name: 'Input 2',
          position: PortPosition.left,
          multiConnections: true,
          offset: Offset(0, 40),
        ),
      ],
      outputPorts: [
        const Port(
          id: 'out1',
          name: 'Result',
          position: PortPosition.right,
          offset: Offset(0, 20),
        ),
      ],
    );

    final outputNode = Node<String>(
      id: 'output',
      type: 'output',
      position: const Offset(500, 120),
      size: const Size(120, 80),
      data: 'Output Node',
      inputPorts: [
        const Port(
          id: 'in1',
          name: 'Input',
          position: PortPosition.left,
          offset: Offset(0, 20),
        ),
      ],
    );

    // Create a special "locked" node that doesn't allow new connections
    final lockedNode = Node<String>(
      id: 'locked',
      type: 'locked',
      position: const Offset(300, 250),
      size: const Size(120, 80),
      data: 'Locked Node',
      inputPorts: [
        const Port(
          id: 'in1',
          name: 'Locked In',
          position: PortPosition.left,
          offset: Offset(0, 20),
        ),
      ],
      outputPorts: [
        const Port(
          id: 'out1',
          name: 'Locked Out',
          position: PortPosition.right,
          offset: Offset(0, 20),
        ),
      ],
    );

    _controller.addNode(inputNode);
    _controller.addNode(processingNode);
    _controller.addNode(outputNode);
    _controller.addNode(lockedNode);

    // Add an existing connection to demonstrate validation with existing connections
    _controller.addConnection(
      Connection(
        id: 'initial_conn',
        sourceNodeId: 'input',
        sourcePortId: 'out1',
        targetNodeId: 'processing',
        targetPortId: 'in1',
      ),
    );
  }

  void _showMessage(String message) {
    setState(() {
      _lastMessage = message;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), duration: const Duration(seconds: 2)),
    );
  }

  ConnectionValidationResult _onBeforeStartConnection(
    ConnectionStartContext<String> context,
  ) {
    // Example 1: Prevent starting connections from locked nodes
    if (context.sourceNode.type == 'locked') {
      _showMessage('Cannot start connections from locked nodes!');
      return const ConnectionValidationResult.deny(
        reason: 'Locked node - connections not allowed',
        showMessage: true,
      );
    }

    // Example 2: Warn if starting from a port that already has connections
    if (context.existingConnections.isNotEmpty &&
        !context.sourcePort.multiConnections) {
      _showMessage(
        'Starting connection will replace existing connection on ${context.sourcePort.name}',
      );
    }

    // Example 3: Custom business logic - limit output connections for input nodes
    if (context.sourceNode.type == 'input' && context.isOutputPort) {
      final outputConnections = _controller.connections
          .where((c) => c.sourceNodeId == context.sourceNode.id)
          .length;

      if (outputConnections >= 2) {
        _showMessage('Input nodes can have at most 2 output connections!');
        return const ConnectionValidationResult.deny(
          reason: 'Maximum output connections exceeded for input node',
          showMessage: true,
        );
      }
    }

    return const ConnectionValidationResult.allow();
  }

  ConnectionValidationResult _onBeforeCompleteConnection(
    ConnectionCompleteContext<String> context,
  ) {
    // Example 1: Prevent any connections to locked nodes
    if (context.targetNode.type == 'locked') {
      _showMessage('Cannot connect to locked nodes!');
      return const ConnectionValidationResult.deny(
        reason: 'Target node is locked',
        showMessage: true,
      );
    }

    // Example 2: Prevent connecting input nodes directly to output nodes
    if (context.sourceNode.type == 'input' &&
        context.targetNode.type == 'output') {
      _showMessage(
        'Input nodes cannot connect directly to output nodes! Use a processing node.',
      );
      return const ConnectionValidationResult.deny(
        reason: 'Invalid direct connection from input to output',
        showMessage: true,
      );
    }

    // Example 3: Type compatibility check
    if (context.sourceNode.type == 'input' &&
        context.targetNode.type == 'processing') {
      // Allow this connection type
      _showMessage(
        'Creating connection: ${context.sourceNode.data} → ${context.targetNode.data}',
      );
    }

    // Example 4: Validate based on port names or custom rules
    if (context.sourcePort.name.contains('Special') &&
        !context.targetPort.name.contains('Special')) {
      _showMessage('Special ports can only connect to other special ports!');
      return const ConnectionValidationResult.deny(
        reason: 'Port type mismatch - special to non-special',
        showMessage: true,
      );
    }

    // Example 5: Check for cycles (simple example)
    if (context.sourceNode.id == context.targetNode.id) {
      _showMessage('Cannot create self-connections!');
      return const ConnectionValidationResult.deny(
        reason: 'Self-connection not allowed',
        showMessage: true,
      );
    }

    return const ConnectionValidationResult.allow();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Connection Validation Example'),
        backgroundColor: Colors.blue.shade100,
      ),
      body: Column(
        children: [
          // Info panel
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            color: Colors.grey.shade100,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Connection Validation Rules:',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const SizedBox(height: 8),
                const Text(
                  '• Locked nodes (gray) cannot create or receive connections',
                ),
                const Text(
                  '• Input nodes cannot connect directly to output nodes',
                ),
                const Text(
                  '• Input nodes can have at most 2 output connections',
                ),
                const Text(
                  '• Special ports can only connect to other special ports',
                ),
                const SizedBox(height: 8),
                if (_lastMessage.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      border: Border.all(color: Colors.blue.shade200),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      'Last action: $_lastMessage',
                      style: TextStyle(
                        color: Colors.blue.shade800,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          // Node flow editor
          Expanded(
            child: NodeFlowEditor<String>(
              controller: _controller,
              theme: NodeFlowTheme.light,
              nodeBuilder: (context, node) => _buildNode(node),
              onBeforeStartConnection: _onBeforeStartConnection,
              onBeforeCompleteConnection: _onBeforeCompleteConnection,
              onConnectionCreated: (connection) {
                _showMessage('Connection created: ${connection.id}');
              },
              onConnectionDeleted: (connection) {
                _showMessage('Connection deleted: ${connection.id}');
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNode(Node<String> node) {
    Color nodeColor;
    IconData nodeIcon;

    switch (node.type) {
      case 'input':
        nodeColor = Colors.green.shade100;
        nodeIcon = Icons.input;
        break;
      case 'processing':
        nodeColor = Colors.blue.shade100;
        nodeIcon = Icons.settings;
        break;
      case 'output':
        nodeColor = Colors.orange.shade100;
        nodeIcon = Icons.output;
        break;
      case 'locked':
        nodeColor = Colors.grey.shade300;
        nodeIcon = Icons.lock;
        break;
      default:
        nodeColor = Colors.white;
        nodeIcon = Icons.help;
    }

    return Container(
      decoration: BoxDecoration(
        color: nodeColor,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            nodeIcon,
            color: node.type == 'locked'
                ? Colors.red.shade600
                : Colors.grey.shade600,
            size: 24,
          ),
          const SizedBox(height: 4),
          Text(
            node.data,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 12,
              color: node.type == 'locked'
                  ? Colors.red.shade600
                  : Colors.grey.shade800,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}
