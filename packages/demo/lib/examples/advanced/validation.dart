import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:vyuh_node_flow/vyuh_node_flow.dart';

import '../../shared/ui_widgets.dart';

class ConnectionValidationExample extends StatefulWidget {
  const ConnectionValidationExample({super.key});

  @override
  State<ConnectionValidationExample> createState() =>
      _ConnectionValidationExampleState();
}

class _ConnectionValidationExampleState
    extends State<ConnectionValidationExample> {
  late final NodeFlowController<String> _controller;
  late final NodeFlowTheme _theme;
  String _lastMessage = '';

  @override
  void initState() {
    super.initState();
    _theme = NodeFlowTheme.light;
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

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _controller.fitToView();
    });
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
    return ResponsiveControlPanel(
      title: 'Validation Rules',
      width: 320,
      child: NodeFlowEditor<String>(
        controller: _controller,
        theme: _theme,
        nodeBuilder: (context, node) => _buildNode(node),
        events: NodeFlowEvents<String>(
          connection: ConnectionEvents<String>(
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
        enableNodeDeletion: false,
      ),
      children: [
        const SectionTitle('Connection Rules'),
        const SizedBox(height: 8),
        const InfoCard(
          title: 'Validation Logic',
          content:
              '• Locked nodes (gray) cannot create or receive connections\n'
              '• Input nodes cannot connect directly to output nodes\n'
              '• Input nodes can have at most 2 output connections\n'
              '• Special ports can only connect to other special ports',
        ),
        const SizedBox(height: 24),
        const SectionTitle('Last Action'),
        const SizedBox(height: 8),
        if (_lastMessage.isNotEmpty)
          InfoCard(title: 'Status', content: _lastMessage)
        else
          const InfoCard(
            title: 'Status',
            content: 'No actions yet. Try creating connections!',
          ),
        const SizedBox(height: 24),
        const SectionTitle('Node Types'),
        const SizedBox(height: 8),
        _buildLegend(),
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
