import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:vyuh_node_flow/vyuh_node_flow.dart';

import '../shared/ui_widgets.dart';

/// Example demonstrating the NodeFlowMinimap widget
class MinimapExample extends StatefulWidget {
  const MinimapExample({super.key});

  @override
  State<MinimapExample> createState() => _MinimapExampleState();
}

class _MinimapExampleState extends State<MinimapExample> {
  late final NodeFlowController<Map<String, dynamic>, dynamic> _controller;
  late NodeFlowTheme _theme;

  @override
  void initState() {
    super.initState();
    _controller = NodeFlowController<Map<String, dynamic>, dynamic>(
      config: NodeFlowConfig(
        extensions: [
          MinimapExtension(
            visible: true,
            interactive: true,
            position: MinimapPosition.bottomRight,
            theme: MinimapTheme.light,
          ),
          StatsExtension(),
          ...NodeFlowConfig.defaultExtensions().where(
            (e) => e is! MinimapExtension,
          ),
        ],
      ),
    );

    _theme = _buildTheme();
    _createLargeGraph();
  }

  NodeFlowTheme _buildTheme() {
    return NodeFlowTheme.light.copyWith(
      connectionTheme: ConnectionTheme.light.copyWith(
        style: ConnectionStyles.smoothstep,
      ),
    );
  }

  void _updateMinimapPosition(MinimapPosition position) {
    // Position is updated directly on the extension (reactive)
    _controller.minimap?.setPosition(position);
  }

  void _updateMinimapSize(Size size) {
    // Size is updated directly on the extension (reactive)
    _controller.minimap?.setSize(size);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _createLargeGraph() {
    // Create a larger graph that requires scrolling/panning
    final nodes = <Node<Map<String, dynamic>>>[];
    final connections = <Connection>[];

    // Create a grid of nodes
    for (int row = 0; row < 5; row++) {
      for (int col = 0; col < 6; col++) {
        final id = 'node-$row-$col';
        nodes.add(
          Node<Map<String, dynamic>>(
            id: id,
            type: _getNodeType(row, col),
            position: Offset(col * 250.0 + 100, row * 200.0 + 100),
            size: const Size(150, 80),
            data: {'label': 'Node $row-$col', 'row': row, 'col': col},
            inputPorts: col > 0
                ? [
                    Port(
                      id: 'in',
                      name: 'Input',
                      position: PortPosition.left,
                      offset: const Offset(
                        -2,
                        40,
                      ), // Vertical center of 80 height
                    ),
                  ]
                : [],
            outputPorts: col < 5
                ? [
                    Port(
                      id: 'out',
                      name: 'Output',
                      position: PortPosition.right,
                      offset: const Offset(
                        2,
                        40,
                      ), // Vertical center of 80 height
                    ),
                  ]
                : [],
          ),
        );

        // Create horizontal connections
        if (col > 0) {
          connections.add(
            Connection(
              id: 'conn-$row-${col - 1}-$col',
              sourceNodeId: 'node-$row-${col - 1}',
              sourcePortId: 'out',
              targetNodeId: 'node-$row-$col',
              targetPortId: 'in',
            ),
          );
        }
      }
    }

    // Add all nodes and connections
    for (final node in nodes) {
      _controller.addNode(node);
    }
    for (final connection in connections) {
      _controller.addConnection(connection);
    }
  }

  String _getNodeType(int row, int col) {
    if (col == 0) return 'input';
    if (col == 5) return 'output';
    return 'process';
  }

  Widget _buildNode(BuildContext context, Node<Map<String, dynamic>> node) {
    Color color;
    IconData icon;

    switch (node.type) {
      case 'input':
        color = Colors.green.shade100;
        icon = Icons.input;
        break;
      case 'output':
        color = Colors.orange.shade100;
        icon = Icons.output;
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
          Icon(icon, size: 24, color: Colors.grey.shade700),
          const SizedBox(height: 4),
          Text(
            node.data['label'] ?? '',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 12,
              color: Colors.grey.shade800,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  void _resetExample() {
    _controller.clearGraph();
    _createLargeGraph();
    _controller.fitToView();
  }

  @override
  Widget build(BuildContext context) {
    return ResponsiveControlPanel(
      controller: _controller,
      onReset: _resetExample,
      child: NodeFlowEditor<Map<String, dynamic>, dynamic>(
        controller: _controller,
        nodeBuilder: _buildNode,
        theme: _theme,
        events: NodeFlowEvents(onInit: () => _controller.fitToView()),
      ),
      children: [
        const SectionTitle('About'),
        SectionContent(
          child: InfoCard(
            title: 'Navigate',
            content:
                'Use the minimap to navigate around the large graph. Pan and zoom to explore different areas.',
          ),
        ),
        _buildMinimapToggle(),
        _buildMinimapInteractivity(),
        _buildMinimapPosition(),
        _buildMinimapSize(),
        _buildNavigationButtons(),
      ],
    );
  }

  Widget _buildMinimapToggle() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SectionTitle('Visibility'),
        SectionContent(
          child: Observer(
            builder: (_) => Row(
              children: [
                const Text('Show Minimap', style: TextStyle(fontSize: 12)),
                const Spacer(),
                Switch(
                  value: _controller.minimap?.isVisible ?? false,
                  onChanged: (value) {
                    _controller.minimap?.setVisible(value);
                  },
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMinimapInteractivity() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SectionTitle('Interactivity'),
        SectionContent(
          child: Observer(
            builder: (_) {
              final minimap = _controller.minimap;
              return Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Interactive (click to navigate)',
                      style: TextStyle(fontSize: 12),
                    ),
                  ),
                  Switch(
                    value: minimap?.isInteractive ?? false,
                    onChanged: (minimap?.isVisible ?? false)
                        ? (value) {
                            minimap?.setInteractive(value);
                          }
                        : null,
                  ),
                ],
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildMinimapPosition() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SectionTitle('Position'),
        SectionContent(
          child: Observer(
            builder: (_) {
              // Observe showMinimap for enabling/disabling and current position
              final minimap = _controller.minimap;
              final showMinimap = minimap?.isVisible ?? false;
              final currentPosition =
                  minimap?.position ?? MinimapPosition.bottomRight;

              return Wrap(
                spacing: 8,
                runSpacing: 8,
                children:
                    [
                      ('Top Left', MinimapPosition.topLeft),
                      ('Top Right', MinimapPosition.topRight),
                      ('Bottom Left', MinimapPosition.bottomLeft),
                      ('Bottom Right', MinimapPosition.bottomRight),
                    ].map((entry) {
                      final (name, position) = entry;
                      return StyledChip(
                        label: name,
                        selected: currentPosition == position,
                        onSelected: showMinimap
                            ? (selected) {
                                if (selected) {
                                  _updateMinimapPosition(position);
                                }
                              }
                            : null,
                      );
                    }).toList(),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildMinimapSize() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SectionTitle('Size'),
        SectionContent(
          child: Observer(
            builder: (_) {
              final minimap = _controller.minimap;
              final showMinimap = minimap?.isVisible ?? false;
              final currentSize = minimap?.size ?? const Size(200, 150);

              return Column(
                children: [
                  Row(
                    children: [
                      const SizedBox(
                        width: 50,
                        child: Text('Width', style: TextStyle(fontSize: 12)),
                      ),
                      Expanded(
                        child: Slider(
                          value: currentSize.width,
                          min: 100,
                          max: 400,
                          divisions: 30,
                          label: currentSize.width.toStringAsFixed(0),
                          onChanged: showMinimap
                              ? (value) {
                                  _updateMinimapSize(
                                    Size(value, currentSize.height),
                                  );
                                }
                              : null,
                        ),
                      ),
                      SizedBox(
                        width: 40,
                        child: Text(
                          currentSize.width.toStringAsFixed(0),
                          style: const TextStyle(fontSize: 11),
                          textAlign: TextAlign.right,
                        ),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      const SizedBox(
                        width: 50,
                        child: Text('Height', style: TextStyle(fontSize: 12)),
                      ),
                      Expanded(
                        child: Slider(
                          value: currentSize.height,
                          min: 75,
                          max: 300,
                          divisions: 30,
                          label: currentSize.height.toStringAsFixed(0),
                          onChanged: showMinimap
                              ? (value) {
                                  _updateMinimapSize(
                                    Size(currentSize.width, value),
                                  );
                                }
                              : null,
                        ),
                      ),
                      SizedBox(
                        width: 40,
                        child: Text(
                          currentSize.height.toStringAsFixed(0),
                          style: const TextStyle(fontSize: 11),
                          textAlign: TextAlign.right,
                        ),
                      ),
                    ],
                  ),
                ],
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildNavigationButtons() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SectionTitle('Quick Navigation'),
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
}
