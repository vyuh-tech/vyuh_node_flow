import 'package:flutter/material.dart';
import 'package:vyuh_node_flow/vyuh_node_flow.dart';

void main() {
  runApp(const MaterialApp(home: MyFlowEditor()));
}

class MyFlowEditor extends StatefulWidget {
  const MyFlowEditor({super.key});

  @override
  State<MyFlowEditor> createState() => _MyFlowEditorState();
}

class _MyFlowEditorState extends State<MyFlowEditor> {
  // Create controller with initial nodes and connections
  late final controller = NodeFlowController<String, dynamic>(
    nodes: [
      Node<String>(
        id: 'start',
        type: 'input',
        position: const Offset(100, 100),
        size: const Size(140, 70),
        data: 'Start',
        outputPorts: const [
          Port(id: 'out', name: 'Out', position: PortPosition.right),
        ],
      ),
      Node<String>(
        id: 'process',
        type: 'default',
        position: const Offset(320, 100),
        size: const Size(140, 70),
        data: 'Process',
        inputPorts: const [
          Port(id: 'in', name: 'In', position: PortPosition.left),
        ],
        outputPorts: const [
          Port(id: 'out', name: 'Out', position: PortPosition.right),
        ],
      ),
      Node<String>(
        id: 'end',
        type: 'output',
        position: const Offset(540, 100),
        size: const Size(140, 70),
        data: 'End',
        inputPorts: const [
          Port(id: 'in', name: 'In', position: PortPosition.left),
        ],
      ),
    ],
    connections: [
      Connection(
        id: 'conn-1',
        sourceNodeId: 'start',
        sourcePortId: 'out',
        targetNodeId: 'process',
        targetPortId: 'in',
      ),
      Connection(
        id: 'conn-2',
        sourceNodeId: 'process',
        sourcePortId: 'out',
        targetNodeId: 'end',
        targetPortId: 'in',
      ),
    ],
  );

  void _addNode() {
    final id = 'node-${DateTime.now().millisecondsSinceEpoch}';
    controller.addNode(Node<String>(
      id: id,
      type: 'default',
      position: const Offset(200, 250),
      size: const Size(140, 70),
      data: 'New Node',
      inputPorts: [Port(id: '$id-in', name: 'In', position: PortPosition.left)],
      outputPorts: [Port(id: '$id-out', name: 'Out', position: PortPosition.right)],
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Flow Editor'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: 'Add Node',
            onPressed: _addNode,
          ),
          IconButton(
            icon: const Icon(Icons.fit_screen),
            tooltip: 'Fit View',
            onPressed: () => controller.fitToView(),
          ),
        ],
      ),
      body: NodeFlowEditor<String, dynamic>(
        controller: controller,
        theme: NodeFlowTheme.light,
        nodeBuilder: (context, node) => Center(
          child: Text(
            node.data,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
        events: NodeFlowEvents(
          node: NodeEvents(
            onTap: (node) => debugPrint('Tapped: ${node.data}'),
          ),
          connection: ConnectionEvents(
            onCreated: (conn) => debugPrint('Connected: ${conn.id}'),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }
}
