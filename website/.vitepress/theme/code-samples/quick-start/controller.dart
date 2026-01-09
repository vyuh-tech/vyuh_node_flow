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

@override
void dispose() {
  controller.dispose();
  super.dispose();
}
