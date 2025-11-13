import 'package:flutter/material.dart';
import 'package:vyuh_node_flow/vyuh_node_flow.dart';

import '../../shared/ui_widgets.dart';

/// Example demonstrating event callbacks and listeners
class CallbacksExample extends StatefulWidget {
  const CallbacksExample({super.key});

  @override
  State<CallbacksExample> createState() => _CallbacksExampleState();
}

class _CallbacksExampleState extends State<CallbacksExample> {
  late final NodeFlowController<Map<String, dynamic>> _controller;
  final List<String> _events = [];
  final ScrollController _scrollController = ScrollController();
  bool _autoScroll = true;
  int _eventCounter = 0;

  @override
  void initState() {
    super.initState();
    _controller = NodeFlowController<Map<String, dynamic>>(
      config: NodeFlowConfig(),
    );

    _createInitialNodes();
    _addEvent('Example initialized', EventType.info);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _controller.fitToView();
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _controller.dispose();
    super.dispose();
  }

  void _createInitialNodes() {
    final node1 = Node<Map<String, dynamic>>(
      id: 'node-1',
      type: 'start',
      position: const Offset(100, 150),
      size: const Size(120, 80),
      data: {'label': 'Start'},
      outputPorts: const [
        Port(
          id: 'out',
          name: 'Output',
          position: PortPosition.right,
          offset: Offset(0, 20),
        ),
      ],
    );

    final node2 = Node<Map<String, dynamic>>(
      id: 'node-2',
      type: 'process',
      position: const Offset(300, 150),
      size: const Size(120, 80),
      data: {'label': 'Process'},
      inputPorts: const [
        Port(
          id: 'in',
          name: 'Input',
          position: PortPosition.left,
          offset: Offset(0, 20),
        ),
      ],
      outputPorts: const [
        Port(
          id: 'out',
          name: 'Output',
          position: PortPosition.right,
          offset: Offset(0, 20),
        ),
      ],
    );

    _controller.addNode(node1);
    _controller.addNode(node2);
  }

  void _addEvent(String message, EventType type) {
    setState(() {
      _eventCounter++;
      final timestamp = DateTime.now();
      final timeStr =
          '${timestamp.hour.toString().padLeft(2, '0')}:${timestamp.minute.toString().padLeft(2, '0')}:${timestamp.second.toString().padLeft(2, '0')}';
      _events.insert(0, '[$_eventCounter] $timeStr - $message');

      // Keep only last 100 events
      if (_events.length > 100) {
        _events.removeLast();
      }
    });

    if (_autoScroll && _scrollController.hasClients) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _scrollController.animateTo(
          0,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      });
    }
  }

  void _clearEvents() {
    setState(() {
      _events.clear();
      _eventCounter = 0;
    });
  }

  Widget _buildNode(BuildContext context, Node<Map<String, dynamic>> node) {
    Color color;
    IconData icon;

    switch (node.type) {
      case 'start':
        color = Colors.green.shade100;
        icon = Icons.play_arrow;
        break;
      case 'end':
        color = Colors.red.shade100;
        icon = Icons.stop;
        break;
      default:
        color = Colors.blue.shade100;
        icon = Icons.settings;
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 20, color: Colors.grey.shade700),
          const SizedBox(height: 4),
          Text(
            node.data['label'] ?? '',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 11,
              color: Colors.grey.shade800,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ResponsiveControlPanel(
      title: 'Event Callbacks',
      width: 340,
      child: NodeFlowEditor<Map<String, dynamic>>(
        controller: _controller,
        nodeBuilder: _buildNode,
        theme: NodeFlowTheme.light.copyWith(
          connectionTheme: ConnectionTheme.light.copyWith(
            style: ConnectionStyles.smoothstep,
          ),
        ),
        // Node callbacks
        onNodeCreated: (node) {
          _addEvent('Node created: ${node.id} (${node.type})', EventType.node);
        },
        onNodeDeleted: (node) {
          _addEvent('Node deleted: ${node.id}', EventType.node);
        },
        onNodeSelected: (node) {
          _addEvent(
            node != null ? 'Node selected: ${node.id}' : 'Node deselected',
            EventType.node,
          );
        },
        onNodeTap: (node) {
          _addEvent('Node tapped: ${node.id}', EventType.interaction);
        },
        onNodeDoubleTap: (node) {
          _addEvent('Node double-tapped: ${node.id}', EventType.interaction);
        },
        // Connection callbacks
        onConnectionCreated: (connection) {
          _addEvent(
            'Connection created: ${connection.sourceNodeId} → ${connection.targetNodeId}',
            EventType.connection,
          );
        },
        onConnectionDeleted: (connection) {
          _addEvent(
            'Connection deleted: ${connection.sourceNodeId} → ${connection.targetNodeId}',
            EventType.connection,
          );
        },
        onConnectionSelected: (connection) {
          _addEvent(
            connection != null
                ? 'Connection selected: ${connection.id}'
                : 'Connection deselected',
            EventType.connection,
          );
        },
        onConnectionTap: (connection) {
          _addEvent(
            'Connection tapped: ${connection.id}',
            EventType.interaction,
          );
        },
        onConnectionDoubleTap: (connection) {
          _addEvent(
            'Connection double-tapped: ${connection.id}',
            EventType.interaction,
          );
        },
        onBeforeStartConnection: (context) {
          _addEvent(
            'Starting connection from ${context.sourceNode.id}:${context.sourcePort.id}',
            EventType.connection,
          );
          return ConnectionValidationResult(allowed: true);
        },
        onBeforeCompleteConnection: (context) {
          _addEvent(
            'Completing connection: ${context.sourceNode.id}:${context.sourcePort.id} → ${context.targetNode.id}:${context.targetPort.id}',
            EventType.connection,
          );
          return ConnectionValidationResult(allowed: true);
        },
        // Annotation callbacks
        onAnnotationCreated: (annotation) {
          _addEvent(
            'Annotation created: ${annotation.id} (${annotation.runtimeType})',
            EventType.annotation,
          );
        },
        onAnnotationDeleted: (annotation) {
          _addEvent(
            'Annotation deleted: ${annotation.id}',
            EventType.annotation,
          );
        },
        onAnnotationSelected: (annotation) {
          _addEvent(
            annotation != null
                ? 'Annotation selected: ${annotation.id}'
                : 'Annotation deselected',
            EventType.annotation,
          );
        },
        onAnnotationTap: (annotation) {
          _addEvent(
            'Annotation tapped: ${annotation.id}',
            EventType.interaction,
          );
        },
      ),
      children: [
        const Text(
          'Interact with the canvas: create nodes, connections, and annotations. '
          'All events are logged in real-time below.',
          style: TextStyle(fontSize: 12, color: Colors.black54),
        ),
        const SizedBox(height: 16),
        _buildQuickActions(),
        const SizedBox(height: 16),
        _buildEventLog(),
      ],
    );
  }

  Widget _buildQuickActions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SectionTitle('Quick Actions'),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            ElevatedButton.icon(
              icon: const Icon(Icons.add_circle_outline, size: 14),
              label: const Text('Add Node', style: TextStyle(fontSize: 10)),
              onPressed: () {
                final nodeId = 'node-${DateTime.now().millisecondsSinceEpoch}';
                _controller.addNode(
                  Node<Map<String, dynamic>>(
                    id: nodeId,
                    type: 'process',
                    position: Offset(
                      200 + (_eventCounter % 3) * 100,
                      100 + (_eventCounter % 3) * 100,
                    ),
                    size: const Size(120, 80),
                    data: {'label': 'Node ${_eventCounter + 1}'},
                    inputPorts: const [
                      Port(
                        id: 'in',
                        name: 'Input',
                        position: PortPosition.left,
                        offset: Offset(0, 20),
                      ),
                    ],
                    outputPorts: const [
                      Port(
                        id: 'out',
                        name: 'Output',
                        position: PortPosition.right,
                        offset: Offset(0, 20),
                      ),
                    ],
                  ),
                );
              },
            ),
            ElevatedButton.icon(
              icon: const Icon(Icons.clear, size: 14),
              label: const Text('Clear Log', style: TextStyle(fontSize: 10)),
              onPressed: _clearEvents,
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Checkbox(
              value: _autoScroll,
              onChanged: (value) {
                setState(() {
                  _autoScroll = value ?? true;
                });
              },
            ),
            const Text('Auto-scroll to latest', style: TextStyle(fontSize: 11)),
          ],
        ),
      ],
    );
  }

  Widget _buildEventLog() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            const SectionTitle('Event Log'),
            const Spacer(),
            Text(
              '${_events.length} events',
              style: TextStyle(fontSize: 10, color: Colors.grey.shade600),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          height: 300,
          decoration: BoxDecoration(
            color: Colors.grey.shade50,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: _events.isEmpty
              ? Center(
                  child: Text(
                    'No events yet. Try interacting with the canvas!',
                    style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                  ),
                )
              : ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(8),
                  itemCount: _events.length,
                  itemBuilder: (context, index) {
                    final event = _events[index];
                    final isRecent = index < 3;

                    return Container(
                      margin: const EdgeInsets.only(bottom: 4),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: isRecent
                            ? Colors.blue.shade50
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        event,
                        style: TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 10,
                          color: isRecent
                              ? Colors.blue.shade900
                              : Colors.grey.shade800,
                          fontWeight: isRecent
                              ? FontWeight.w600
                              : FontWeight.normal,
                        ),
                      ),
                    );
                  },
                ),
        ),
        const SizedBox(height: 8),
        Text(
          'Tip: Select nodes/connections using click, delete with Delete/Backspace key',
          style: TextStyle(fontSize: 10, color: Colors.grey.shade600),
        ),
      ],
    );
  }
}

enum EventType { node, connection, annotation, interaction, info }
