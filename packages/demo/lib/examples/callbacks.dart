import 'package:flutter/material.dart';
import 'package:vyuh_node_flow/vyuh_node_flow.dart';

import '../design_kit/theme.dart';
import '../shared/ui_widgets.dart';

/// Example demonstrating the comprehensive event system
/// Shows all available events organized by category
class CallbacksExample extends StatefulWidget {
  const CallbacksExample({super.key});

  @override
  State<CallbacksExample> createState() => _CallbacksExampleState();
}

class _CallbacksExampleState extends State<CallbacksExample> {
  final List<String> _events = [];
  final ScrollController _scrollController = ScrollController();
  bool _autoScroll = true;
  int _eventCounter = 0;

  // Track event counts by category
  final Map<EventType, int> _eventCounts = {
    EventType.node: 0,
    EventType.connection: 0,
    EventType.viewport: 0,
    EventType.selection: 0,
    EventType.lifecycle: 0,
    EventType.interaction: 0,
  };

  // Create controller with initial nodes
  final _controller = NodeFlowController<Map<String, dynamic>, dynamic>(
    config: NodeFlowConfig(),
    nodes: [
      Node<Map<String, dynamic>>(
        id: 'node-1',
        type: 'start',
        position: const Offset(100, 150),
        size: const Size(120, 80),
        data: {'label': 'Start'},
        outputPorts: [
          Port(
            id: 'out',
            name: 'Output',
            position: PortPosition.right,
            offset: Offset(2, 40),
          ),
        ],
      ),
      Node<Map<String, dynamic>>(
        id: 'node-2',
        type: 'process',
        position: const Offset(300, 150),
        size: const Size(120, 80),
        data: {'label': 'Process'},
        inputPorts: [
          Port(
            id: 'in',
            name: 'Input',
            position: PortPosition.left,
            offset: Offset(-2, 40),
          ),
        ],
        outputPorts: [
          Port(
            id: 'out',
            name: 'Output',
            position: PortPosition.right,
            offset: Offset(2, 40),
          ),
        ],
      ),
      Node<Map<String, dynamic>>(
        id: 'node-3',
        type: 'end',
        position: const Offset(500, 150),
        size: const Size(120, 80),
        data: {'label': 'End'},
        inputPorts: [
          Port(
            id: 'in',
            name: 'Input',
            position: PortPosition.left,
            offset: Offset(-2, 40),
          ),
        ],
      ),
    ],
  );

  @override
  void dispose() {
    _scrollController.dispose();
    _controller.dispose();
    super.dispose();
  }

  void _addEvent(String message, EventType type) {
    setState(() {
      _eventCounter++;
      _eventCounts[type] = (_eventCounts[type] ?? 0) + 1;
      final timestamp = DateTime.now();
      final timeStr =
          '${timestamp.hour.toString().padLeft(2, '0')}:${timestamp.minute.toString().padLeft(2, '0')}:${timestamp.second.toString().padLeft(2, '0')}';

      final typeTag = _getEventTypeTag(type);
      _events.insert(0, '[$_eventCounter] $timeStr $typeTag $message');

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

  String _getEventTypeTag(EventType type) {
    switch (type) {
      case EventType.node:
        return '[NODE]';
      case EventType.connection:
        return '[CONN]';
      case EventType.viewport:
        return '[VIEW]';
      case EventType.selection:
        return '[SELECT]';
      case EventType.lifecycle:
        return '[LIFE]';
      case EventType.interaction:
        return '[INTERACT]';
    }
  }

  void _clearEvents() {
    setState(() {
      _events.clear();
      _eventCounter = 0;
      _eventCounts.updateAll((key, value) => 0);
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
      controller: _controller,
      onReset: () {
        _controller.clearGraph();
        _events.clear();
        _eventCounter = 0;
        for (final e in _eventCounts.keys) {
          _eventCounts[e] = 0;
        }
        // Recreate initial nodes
        _controller.addNode(
          Node<Map<String, dynamic>>(
            id: 'node-1',
            type: 'start',
            position: const Offset(100, 150),
            size: const Size(120, 80),
            data: {'label': 'Start'},
            outputPorts: [
              Port(
                id: 'out',
                name: 'Output',
                position: PortPosition.right,
                offset: Offset(2, 40),
              ),
            ],
          ),
        );
        _controller.addNode(
          Node<Map<String, dynamic>>(
            id: 'node-2',
            type: 'process',
            position: const Offset(300, 150),
            size: const Size(120, 80),
            data: {'label': 'Process'},
            inputPorts: [
              Port(
                id: 'in',
                name: 'Input',
                position: PortPosition.left,
                offset: Offset(-2, 40),
              ),
            ],
            outputPorts: [
              Port(
                id: 'out',
                name: 'Output',
                position: PortPosition.right,
                offset: Offset(2, 40),
              ),
            ],
          ),
        );
        _controller.addNode(
          Node<Map<String, dynamic>>(
            id: 'node-3',
            type: 'end',
            position: const Offset(500, 150),
            size: const Size(120, 80),
            data: {'label': 'End'},
            inputPorts: [
              Port(
                id: 'in',
                name: 'Input',
                position: PortPosition.left,
                offset: Offset(-2, 40),
              ),
            ],
          ),
        );
        _controller.fitToView();
      },
      child: NodeFlowEditor<Map<String, dynamic>, dynamic>(
        controller: _controller,
        nodeBuilder: _buildNode,
        theme: NodeFlowTheme.light.copyWith(
          connectionTheme: ConnectionTheme.light.copyWith(
            style: ConnectionStyles.smoothstep,
          ),
        ),
        // ========== NEW EVENT SYSTEM ==========
        events: NodeFlowEvents(
          // ===== NODE EVENTS =====
          node: NodeEvents(
            onCreated: (node) {
              _addEvent('Created ${node.id} (${node.type})', EventType.node);
            },
            onBeforeDelete: (node) async {
              _addEvent('Before delete: ${node.id} (allowing)', EventType.node);
              return true; // Allow deletion
            },
            onDeleted: (node) {
              _addEvent('Deleted ${node.id}', EventType.node);
            },
            onSelected: (node) {
              _addEvent(
                node != null ? 'Selected ${node.id}' : 'Deselected node',
                EventType.node,
              );
            },
            onTap: (node) {
              _addEvent('Tapped ${node.id}', EventType.interaction);
            },
            onDoubleTap: (node) {
              _addEvent('Double-tapped ${node.id}', EventType.interaction);
            },
            onDragStart: (node) {
              _addEvent('Drag started on ${node.id}', EventType.interaction);
            },
            onDrag: (node) {
              // Too noisy - skip logging each drag update
            },
            onDragStop: (node) {
              _addEvent(
                'Drag stopped on ${node.id} at ${node.position.value.dx.toInt()},${node.position.value.dy.toInt()}',
                EventType.interaction,
              );
            },
            onMouseEnter: (node) {
              _addEvent('Mouse entered ${node.id}', EventType.interaction);
            },
            onMouseLeave: (node) {
              _addEvent('Mouse left ${node.id}', EventType.interaction);
            },
            onContextMenu: (node, position) {
              _addEvent(
                'Context menu on ${node.id} at ${position.dx.toInt()},${position.dy.toInt()}',
                EventType.interaction,
              );
            },
          ),

          // ===== PORT EVENTS =====
          port: PortEvents(
            onTap: (node, port) {
              _addEvent(
                'Tapped ${port.isOutput ? 'output' : 'input'} port ${port.id} on ${node.id}',
                EventType.interaction,
              );
            },
            onDoubleTap: (node, port) {
              _addEvent(
                'Double-tapped ${port.isOutput ? 'output' : 'input'} port ${port.id} on ${node.id}',
                EventType.interaction,
              );
            },
            onMouseEnter: (node, port) {
              _addEvent(
                'Mouse entered ${port.isOutput ? 'output' : 'input'} port ${port.id} on ${node.id}',
                EventType.interaction,
              );
            },
            onMouseLeave: (node, port) {
              _addEvent(
                'Mouse left ${port.isOutput ? 'output' : 'input'} port ${port.id} on ${node.id}',
                EventType.interaction,
              );
            },
            onContextMenu: (node, port, position) {
              _addEvent(
                'Context menu on ${port.isOutput ? 'output' : 'input'} port ${port.id} at ${position.dx.toInt()},${position.dy.toInt()}',
                EventType.interaction,
              );
            },
          ),

          // ===== CONNECTION EVENTS =====
          connection: ConnectionEvents(
            onCreated: (connection) {
              _addEvent(
                'Created ${connection.sourceNodeId} → ${connection.targetNodeId}',
                EventType.connection,
              );
            },
            onBeforeDelete: (connection) async {
              _addEvent(
                'Before delete: ${connection.sourceNodeId} → ${connection.targetNodeId} (allowing)',
                EventType.connection,
              );
              return true; // Allow deletion
            },
            onDeleted: (connection) {
              _addEvent(
                'Deleted ${connection.sourceNodeId} → ${connection.targetNodeId}',
                EventType.connection,
              );
            },
            onSelected: (connection) {
              _addEvent(
                connection != null
                    ? 'Selected connection ${connection.id}'
                    : 'Deselected connection',
                EventType.connection,
              );
            },
            onTap: (connection) {
              _addEvent(
                'Tapped connection ${connection.id}',
                EventType.interaction,
              );
            },
            onDoubleTap: (connection) {
              _addEvent(
                'Double-tapped connection ${connection.id}',
                EventType.interaction,
              );
            },
            onMouseEnter: (connection) {
              _addEvent(
                'Mouse entered connection ${connection.id}',
                EventType.interaction,
              );
            },
            onMouseLeave: (connection) {
              _addEvent(
                'Mouse left connection ${connection.id}',
                EventType.interaction,
              );
            },
            onContextMenu: (connection, position) {
              _addEvent(
                'Context menu on connection ${connection.id} at ${position.dx.toInt()},${position.dy.toInt()}',
                EventType.interaction,
              );
            },
            onConnectStart: (sourceNode, sourcePort) {
              _addEvent(
                'Started connecting from ${sourceNode.id}:${sourcePort.id}',
                EventType.connection,
              );
            },
            onConnectEnd: (targetNode, targetPort, _) {
              final success = targetNode != null && targetPort != null;
              _addEvent(
                success
                    ? 'Connection completed to ${targetNode.id}:${targetPort.id}'
                    : 'Connection cancelled',
                EventType.connection,
              );
            },
            onBeforeStart: (context) {
              _addEvent(
                'Validating connection start from ${context.sourceNode.id}:${context.sourcePort.id}',
                EventType.connection,
              );
              return ConnectionValidationResult(allowed: true);
            },
            onBeforeComplete: (context) {
              _addEvent(
                'Validating connection: ${context.sourceNode.id}:${context.sourcePort.id} → ${context.targetNode.id}:${context.targetPort.id}',
                EventType.connection,
              );
              return ConnectionValidationResult(allowed: true);
            },
          ),

          // ===== VIEWPORT EVENTS =====
          viewport: ViewportEvents(
            onMoveStart: (viewport) {
              _addEvent(
                'Viewport move started (zoom: ${viewport.zoom.toStringAsFixed(2)})',
                EventType.viewport,
              );
            },
            onMove: (viewport) {
              // Too noisy - skip logging each move
            },
            onMoveEnd: (viewport) {
              _addEvent(
                'Viewport move ended at ${viewport.x.toInt()},${viewport.y.toInt()} (zoom: ${viewport.zoom.toStringAsFixed(2)})',
                EventType.viewport,
              );
            },
            onCanvasTap: (position) {
              _addEvent(
                'Canvas tapped at ${position.dx.toInt()},${position.dy.toInt()}',
                EventType.interaction,
              );
            },
            onCanvasDoubleTap: (position) {
              _addEvent(
                'Canvas double-tapped at ${position.dx.toInt()},${position.dy.toInt()}',
                EventType.interaction,
              );
            },
            onCanvasContextMenu: (position) {
              _addEvent(
                'Canvas context menu at ${position.dx.toInt()},${position.dy.toInt()}',
                EventType.interaction,
              );
            },
          ),

          // ===== TOP-LEVEL EVENTS =====
          onSelectionChange: (state) {
            final nodeCount = state.nodes.length;
            final connCount = state.connections.length;
            final total = nodeCount + connCount;

            if (total > 0) {
              final parts = <String>[];
              if (nodeCount > 0) {
                parts.add('$nodeCount node${nodeCount > 1 ? 's' : ''}');
              }
              if (connCount > 0) {
                parts.add('$connCount connection${connCount > 1 ? 's' : ''}');
              }

              _addEvent(
                'Selection changed: ${parts.join(', ')}',
                EventType.selection,
              );
            } else {
              _addEvent('Selection cleared', EventType.selection);
            }
          },
          onInit: () {
            _addEvent('Editor initialized', EventType.lifecycle);
            _controller.fitToView();
            _addEvent('Viewport fitted to view', EventType.viewport);
          },
          onError: (error) {
            _addEvent('Error: ${error.message}', EventType.lifecycle);
          },
        ),
      ),
      children: [
        const SectionTitle('About'),
        SectionContent(
          child: Text(
            'This example demonstrates ALL events in the new event system. '
            'Try dragging nodes, creating connections, panning/zooming, and right-clicking!',
            style: TextStyle(fontSize: 12, color: Colors.black54),
          ),
        ),
        _buildEventStats(),
        _buildQuickActions(),
        _buildEventLog(),
      ],
    );
  }

  Widget _buildEventStats() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SectionTitle('Event Statistics'),
        SectionContent(
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: EventType.values.map((type) {
              final count = _eventCounts[type] ?? 0;
              final color = _getEventTypeColor(type);
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: color),
                ),
                child: Text(
                  '${_getEventTypeTag(type).replaceAll('[', '').replaceAll(']', '')}: $count',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: color,
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Color _getEventTypeColor(EventType type) {
    switch (type) {
      case EventType.node:
        return Colors.blue;
      case EventType.connection:
        return Colors.purple;
      case EventType.viewport:
        return Colors.orange;
      case EventType.selection:
        return Colors.green;
      case EventType.lifecycle:
        return Colors.red;
      case EventType.interaction:
        return Colors.teal;
    }
  }

  Widget _buildQuickActions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SectionTitle('Quick Actions'),
        SectionContent(
          child: Grid2Cols(
            buttons: [
              GridButton(
                icon: Icons.add_circle_outline,
                label: 'Add Node',
                onPressed: () {
                  final nodeId =
                      'node-${DateTime.now().millisecondsSinceEpoch}';
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
                      inputPorts: [
                        Port(
                          id: 'in',
                          name: 'Input',
                          position: PortPosition.left,
                          offset: Offset(0, 40),
                        ),
                      ],
                      outputPorts: [
                        Port(
                          id: 'out',
                          name: 'Output',
                          position: PortPosition.right,
                          offset: Offset(0, 40),
                        ),
                      ],
                    ),
                  );
                },
              ),
              GridButton(
                icon: Icons.fit_screen,
                label: 'Fit View',
                onPressed: () {
                  _controller.fitToView();
                },
              ),
              GridButton(
                icon: Icons.clear,
                label: 'Clear Log',
                onPressed: _clearEvents,
              ),
              GridButton(
                icon: _autoScroll
                    ? Icons.check_box
                    : Icons.check_box_outline_blank,
                label: 'Auto-scroll',
                isActive: _autoScroll,
                onPressed: () {
                  setState(() {
                    _autoScroll = !_autoScroll;
                  });
                },
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildEventLog() {
    final theme = Theme.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SectionTitle.custom(
          child: Row(
            children: [
              Text(
                'EVENT LOG',
                style: theme.textTheme.labelSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: (isDark ? DemoTheme.accentLight : DemoTheme.accent)
                      .withValues(alpha: 0.7),
                  letterSpacing: 0.8,
                ),
              ),
              const Spacer(),
              Text(
                '${_events.length} events',
                style: theme.textTheme.labelSmall?.copyWith(
                  fontSize: 10,
                  color: context.textTertiaryColor,
                ),
              ),
            ],
          ),
        ),
        SectionContent(
          child: SizedBox(
            height: 350,
            child: _events.isEmpty
                ? Center(
                    child: Text(
                      'No events yet. Try interacting with the canvas!',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey.shade500,
                      ),
                    ),
                  )
                : ListView.builder(
                    controller: _scrollController,
                    itemCount: _events.length,
                    itemBuilder: (context, index) {
                      final event = _events[index];
                      final isRecent = index < 3;

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 2),
                        child: Text(
                          event,
                          style: TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 10,
                            color: isRecent
                                ? (isDark
                                      ? DemoTheme.accentLight
                                      : DemoTheme.accent)
                                : context.textSecondaryColor,
                            fontWeight: isRecent
                                ? FontWeight.w600
                                : FontWeight.normal,
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ),
      ],
    );
  }
}

enum EventType { node, connection, viewport, selection, lifecycle, interaction }
