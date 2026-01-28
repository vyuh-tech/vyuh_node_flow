import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:vyuh_node_flow/vyuh_node_flow.dart';

import '../shared/ui_widgets.dart';

class ConnectionValidationExample extends StatefulWidget {
  const ConnectionValidationExample({super.key});

  @override
  State<ConnectionValidationExample> createState() =>
      _ConnectionValidationExampleState();
}

class _ConnectionValidationExampleState
    extends State<ConnectionValidationExample> {
  final _theme = NodeFlowTheme.light;
  final _controller = NodeFlowController<String, dynamic>(
    config: NodeFlowConfig(),
    nodes: _createNodes(),
    connections: _createConnections(),
  );
  String _lastMessage = '';

  static List<Node<String>> _createNodes() {
    return [
      // Input node with multiple output ports
      Node<String>(
        id: 'input',
        type: 'input',
        position: const Offset(100, 100),
        size: const Size(120, 80),
        data: 'Input Node',
        ports: [
          Port(
            id: 'out1',
            name: 'Output 1',
            type: PortType.output,
            position: PortPosition.right,
            offset: Offset(2, 20), // Multiple ports: starting offset 20
          ),
          Port(
            id: 'out2',
            name: 'Output 2',
            type: PortType.output,
            position: PortPosition.right,
            multiConnections: true,
            offset: Offset(2, 50), // Multiple ports: 20 + 30 separation
          ),
        ],
      ),
      // Processing node with input and output ports
      Node<String>(
        id: 'processing',
        type: 'processing',
        position: const Offset(300, 100),
        size: const Size(140, 100),
        data: 'Processing Node',
        ports: [
          Port(
            id: 'in1',
            name: 'Input 1',
            type: PortType.input,
            position: PortPosition.left,
            offset: Offset(-2, 20), // Multiple ports: starting offset 20
          ),
          Port(
            id: 'in2',
            name: 'Input 2',
            type: PortType.input,
            position: PortPosition.left,
            multiConnections: true,
            offset: Offset(-2, 50), // Multiple ports: 20 + 30 separation
          ),
          Port(
            id: 'out1',
            name: 'Result',
            type: PortType.output,
            position: PortPosition.right,
            offset: Offset(2, 50), // Vertical center of 100 height
          ),
        ],
      ),
      // Output node
      Node<String>(
        id: 'output',
        type: 'output',
        position: const Offset(500, 120),
        size: const Size(120, 80),
        data: 'Output Node',
        ports: [
          Port(
            id: 'in1',
            name: 'Input',
            type: PortType.input,
            position: PortPosition.left,
            offset: Offset(-2, 40), // Vertical center of 80 height
          ),
        ],
      ),
      // Special "locked" node that doesn't allow new connections
      Node<String>(
        id: 'locked',
        type: 'locked',
        position: const Offset(300, 250),
        size: const Size(120, 80),
        data: 'Locked Node',
        ports: [
          Port(
            id: 'in1',
            name: 'Locked In',
            type: PortType.input,
            position: PortPosition.left,
            offset: Offset(-2, 40), // Vertical center of 80 height
          ),
          Port(
            id: 'out1',
            name: 'Locked Out',
            type: PortType.output,
            position: PortPosition.right,
            offset: Offset(2, 40), // Vertical center of 80 height
          ),
        ],
      ),
    ];
  }

  static List<Connection> _createConnections() {
    return [
      // Initial connection to demonstrate validation with existing connections
      Connection(
        id: 'initial_conn',
        sourceNodeId: 'input',
        sourcePortId: 'out1',
        targetNodeId: 'processing',
        targetPortId: 'in1',
      ),
    ];
  }

  void _showMessage(String message) {
    setState(() {
      _lastMessage = message;
    });
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
    // Example 1: Prevent any connections to/from locked nodes
    // Note: We must check BOTH sourceNode and targetNode because:
    // - Dragging OUTPUT→INPUT: targetNode is the drop target
    // - Dragging INPUT→OUTPUT: sourceNode is the drop target (direction swapped)
    if (context.sourceNode.type == 'locked') {
      _showMessage('Cannot connect from locked nodes!');
      return const ConnectionValidationResult.deny(
        reason: 'Source node is locked',
        showMessage: true,
      );
    }
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
    return ResponsiveControlPanel(
      controller: _controller,
      onReset: () {
        _controller.clearGraph();
        for (final node in _createNodes()) {
          _controller.addNode(node);
        }
        for (final conn in _createConnections()) {
          _controller.addConnection(conn);
        }
        _controller.fitToView();
      },
      child: NodeFlowEditor<String, dynamic>(
        controller: _controller,
        theme: _theme,
        nodeBuilder: (context, node) => _buildNode(node),
        events: NodeFlowEvents<String, dynamic>(
          onInit: () => _controller.fitToView(),
          connection: ConnectionEvents<String, dynamic>(
            onBeforeStart: _onBeforeStartConnection,
            onBeforeComplete: _onBeforeCompleteConnection,
            onCreated: (connection) {
              _showMessage('Connection created: ${connection.id}');
            },
            onDeleted: (connection) {
              _showMessage('Connection deleted: ${connection.id}');
            },
          ),
        ),
        // Uses NodeFlowBehavior.design by default (full editing)
      ),
      children: [
        const SectionTitle('About'),
        SectionContent(
          child: InfoCard(
            title: 'Validation Logic',
            content:
                '• Locked nodes (gray) cannot create or receive connections\n'
                '• Input nodes cannot connect directly to output nodes\n'
                '• Input nodes can have at most 2 output connections\n'
                '• Special ports can only connect to other special ports',
          ),
        ),
        const SectionTitle('Last Action'),
        SectionContent(
          child: _lastMessage.isNotEmpty
              ? InfoCard(title: 'Status', content: _lastMessage)
              : const InfoCard(
                  title: 'Status',
                  content: 'No actions yet. Try creating connections!',
                ),
        ),
        const SectionTitle('Node Types'),
        SectionContent(child: _buildLegend()),
      ],
    );
  }

  Widget _buildNode(Node<String> node) {
    // Calculate inner border radius
    final outerBorderRadius = _theme.nodeTheme.borderRadius;
    final borderWidth = _theme.nodeTheme.borderWidth;
    final outerRadius = outerBorderRadius.topLeft.x;
    final innerRadius = math.max(0.0, outerRadius - borderWidth);

    return Builder(
      builder: (context) {
        final theme = Theme.of(context);
        final isDark = theme.brightness == Brightness.dark;

        Color nodeColor;
        IconData nodeIcon;
        Color iconColor;
        Color textColor;

        switch (node.type) {
          case 'input':
            // Soft mint green
            nodeColor = isDark
                ? const Color(0xFF2D4A3E)
                : const Color(0xFFD4F1E8);
            nodeIcon = Icons.input;
            iconColor = isDark
                ? const Color(0xFF88D5B3)
                : const Color(0xFF1B5E3F);
            textColor = iconColor;
            break;
          case 'processing':
            // Soft sky blue
            nodeColor = isDark
                ? const Color(0xFF2D3E52)
                : const Color(0xFFD4E7F7);
            nodeIcon = Icons.settings;
            iconColor = isDark
                ? const Color(0xFF88B8E6)
                : const Color(0xFF1B4D7A);
            textColor = iconColor;
            break;
          case 'output':
            // Soft peach
            nodeColor = isDark
                ? const Color(0xFF4A3D32)
                : const Color(0xFFFFE5D4);
            nodeIcon = Icons.output;
            iconColor = isDark
                ? const Color(0xFFFFB088)
                : const Color(0xFF8B4513);
            textColor = iconColor;
            break;
          case 'locked':
            // Soft lavender
            nodeColor = isDark
                ? const Color(0xFF3E3247)
                : const Color(0xFFE8D4F1);
            nodeIcon = Icons.lock;
            iconColor = isDark
                ? const Color(0xFFC088D5)
                : const Color(0xFF6B2D8B);
            textColor = iconColor;
            break;
          default:
            nodeColor = theme.colorScheme.surface;
            nodeIcon = Icons.help;
            iconColor = theme.colorScheme.onSurface;
            textColor = theme.colorScheme.onSurface;
        }

        return Container(
          decoration: BoxDecoration(
            color: nodeColor,
            borderRadius: BorderRadius.circular(innerRadius),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(nodeIcon, color: iconColor, size: 24),
              const SizedBox(height: 4),
              Text(
                node.data,
                style: theme.textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: textColor,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildLegend() {
    return Builder(
      builder: (context) {
        final theme = Theme.of(context);
        final isDark = theme.brightness == Brightness.dark;

        return Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerLowest,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: theme.colorScheme.outlineVariant),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Legend',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 12),
              _buildLegendItem(
                isDark ? const Color(0xFF2D4A3E) : const Color(0xFFD4F1E8),
                'Input Node',
                'Can have multiple outputs',
                theme,
              ),
              const SizedBox(height: 8),
              _buildLegendItem(
                isDark ? const Color(0xFF2D3E52) : const Color(0xFFD4E7F7),
                'Processing Node',
                'Transforms data',
                theme,
              ),
              const SizedBox(height: 8),
              _buildLegendItem(
                isDark ? const Color(0xFF4A3D32) : const Color(0xFFFFE5D4),
                'Output Node',
                'Final destination',
                theme,
              ),
              const SizedBox(height: 8),
              _buildLegendItem(
                isDark ? const Color(0xFF3E3247) : const Color(0xFFE8D4F1),
                'Locked Node',
                'No connections allowed',
                theme,
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildLegendItem(
    Color color,
    String title,
    String description,
    ThemeData theme,
  ) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 16,
          height: 16,
          margin: const EdgeInsets.only(top: 2),
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(4),
            border: Border.all(
              color: theme.colorScheme.outline.withValues(alpha: 0.2),
              width: 1,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: theme.textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                description,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}
