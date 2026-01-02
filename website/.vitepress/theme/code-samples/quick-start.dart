import 'package:flutter/material.dart';
import 'package:vyuh_node_flow/vyuh_node_flow.dart';

void main() => runApp(MaterialApp(home: SimpleFlowEditor()));  // [!code focus]

class SimpleFlowEditor extends StatefulWidget {
  @override
  State<SimpleFlowEditor> createState() => _SimpleFlowEditorState();
}

class _SimpleFlowEditorState extends State<SimpleFlowEditor> {

  final _controller = NodeFlowController<String>(  // [!code focus]
    nodes: [  // [!code focus]
      Node(id: 'a', position: Offset(100, 150), data: 'Node 1',  // [!code focus]
           outputPorts: [Port(id: 'out')]),  // [!code focus]
      Node(id: 'b', position: Offset(350, 150), data: 'Node 2',  // [!code focus]
           inputPorts: [Port(id: 'in')], outputPorts: [Port(id: 'out')]),  // [!code focus]
      Node(id: 'c', position: Offset(600, 150), data: 'Node 3',  // [!code focus]
           inputPorts: [Port(id: 'in')]),  // [!code focus]
    ],  // [!code focus]
    connections: [  // [!code focus]
      Connection(id: 'c1', sourceNodeId: 'a', sourcePortId: 'out',  // [!code focus]
                 targetNodeId: 'b', targetPortId: 'in'),  // [!code focus]
      Connection(id: 'c2', sourceNodeId: 'b', sourcePortId: 'out',  // [!code focus]
                 targetNodeId: 'c', targetPortId: 'in'),  // [!code focus]
    ],  // [!code focus]
  );  // [!code focus]

  @override
  Widget build(BuildContext context) => NodeFlowEditor<String>(  // [!code focus]
    controller: _controller,  // [!code focus]
    theme: NodeFlowTheme.light,  // [!code focus]
    nodeBuilder: _buildNode,  // [!code focus]
  );  // [!code focus]

  Widget _buildNode(BuildContext context, Node<String> node) {  // [!code focus]
    return Container(  // [!code focus]
      padding: EdgeInsets.all(16),  // [!code focus]
      decoration: BoxDecoration(  // [!code focus]
        color: Colors.indigo.shade100,  // [!code focus]
        borderRadius: BorderRadius.circular(6),  // [!code focus]
      ),  // [!code focus]
      child: Text(node.data, style: TextStyle(fontWeight: FontWeight.bold)),  // [!code focus]
    );  // [!code focus]
  }  // [!code focus]

}
