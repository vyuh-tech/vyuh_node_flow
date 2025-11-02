import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:vyuh_node_flow/vyuh_node_flow.dart';

import '../../shared/ui_widgets.dart';

class ThemingExample extends StatefulWidget {
  const ThemingExample({super.key});

  @override
  State<ThemingExample> createState() => _ThemingExampleState();
}

class _ThemingExampleState extends State<ThemingExample> {
  late final NodeFlowController<Map<String, dynamic>> _controller;
  late NodeFlowTheme _theme;

  @override
  void initState() {
    super.initState();
    _theme = NodeFlowTheme.light;
    _controller = NodeFlowController<Map<String, dynamic>>(
      config: NodeFlowConfig(),
    );
    _createExampleGraph();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _createExampleGraph() {
    // Create a sample graph to demonstrate theming
    final node1 = Node<Map<String, dynamic>>(
      id: 'node1',
      type: 'source',
      position: const Offset(100, 100),
      size: const Size(150, 100),
      data: {'label': 'Source'},
      outputPorts: const [
        Port(
          id: 'out1',
          name: 'Output 1',
          position: PortPosition.right,
          offset: Offset(0, 30),
        ),
        Port(
          id: 'out2',
          name: 'Output 2',
          position: PortPosition.right,
          offset: Offset(0, 70),
        ),
      ],
    );

    final node2 = Node<Map<String, dynamic>>(
      id: 'node2',
      type: 'transform',
      position: const Offset(350, 80),
      size: const Size(150, 100),
      data: {'label': 'Transform'},
      inputPorts: const [
        Port(
          id: 'in1',
          name: 'Input',
          position: PortPosition.left,
          offset: Offset(0, 50),
        ),
      ],
      outputPorts: const [
        Port(
          id: 'out1',
          name: 'Output',
          position: PortPosition.right,
          offset: Offset(0, 50),
        ),
      ],
    );

    final node3 = Node<Map<String, dynamic>>(
      id: 'node3',
      type: 'sink',
      position: const Offset(600, 100),
      size: const Size(150, 100),
      data: {'label': 'Sink'},
      inputPorts: const [
        Port(
          id: 'in1',
          name: 'Input 1',
          position: PortPosition.left,
          offset: Offset(0, 30),
        ),
        Port(
          id: 'in2',
          name: 'Input 2',
          position: PortPosition.left,
          offset: Offset(0, 70),
        ),
      ],
    );

    _controller.addNode(node1);
    _controller.addNode(node2);
    _controller.addNode(node3);

    // Add connections
    _controller.addConnection(
      Connection(
        id: 'conn1',
        sourceNodeId: 'node1',
        sourcePortId: 'out1',
        targetNodeId: 'node2',
        targetPortId: 'in1',
      ),
    );

    _controller.addConnection(
      Connection(
        id: 'conn2',
        sourceNodeId: 'node2',
        sourcePortId: 'out1',
        targetNodeId: 'node3',
        targetPortId: 'in1',
      ),
    );
  }

  void _updateTheme(NodeFlowTheme newTheme) {
    setState(() {
      _theme = newTheme;
    });
  }

  Widget _buildNode(BuildContext context, Node<Map<String, dynamic>> node) {
    // Calculate inner border radius
    final outerBorderRadius = _theme.nodeTheme.borderRadius;
    final borderWidth = _theme.nodeTheme.borderWidth;
    final outerRadius = outerBorderRadius.topLeft.x;
    final innerRadius = math.max(0.0, outerRadius - borderWidth);

    Color nodeColor;
    IconData icon;

    switch (node.type) {
      case 'source':
        nodeColor = Colors.green.shade100;
        icon = Icons.input;
        break;
      case 'transform':
        nodeColor = Colors.blue.shade100;
        icon = Icons.transform;
        break;
      case 'sink':
        nodeColor = Colors.orange.shade100;
        icon = Icons.output;
        break;
      default:
        nodeColor = Colors.grey.shade100;
        icon = Icons.circle;
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: nodeColor,
        borderRadius: BorderRadius.circular(innerRadius),
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
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // Main Editor
        Expanded(
          child: NodeFlowEditor<Map<String, dynamic>>(
            controller: _controller,
            nodeBuilder: _buildNode,
            theme: _theme,
          ),
        ),
        // Theme Control Panel
        ControlPanel(
          title: 'Theme Editor',
          width: 320,
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh, size: 20),
              onPressed: () {
                _updateTheme(NodeFlowTheme.light);
              },
              tooltip: 'Reset to Light Theme',
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
          ],
          children: [
            _buildThemePresets(),
            const SizedBox(height: 24),
            _buildConnectionStyleSection(),
            const SizedBox(height: 24),
            _buildConnectionColorsSection(),
            const SizedBox(height: 24),
            _buildStrokeWidthSection(),
            const SizedBox(height: 24),
            _buildPortSizeSection(),
            const SizedBox(height: 24),
            _buildGridSection(),
            const SizedBox(height: 24),
            _buildNodeBorderSection(),
          ],
        ),
      ],
    );
  }

  Widget _buildThemePresets() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionTitle('Theme Presets'),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: ElevatedButton(
                onPressed: () => _updateTheme(NodeFlowTheme.light),
                child: const Text('Light', style: TextStyle(fontSize: 12)),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: ElevatedButton(
                onPressed: () => _updateTheme(NodeFlowTheme.dark),
                child: const Text('Dark', style: TextStyle(fontSize: 12)),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildConnectionStyleSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionTitle('Connection Style'),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: ConnectionStyles.all.map((style) {
            if (style == ConnectionStyles.customBezier) {
              return const SizedBox.shrink();
            }
            return ChoiceChip(
              label: Text(
                style.displayName,
                style: const TextStyle(fontSize: 11),
              ),
              selected: _theme.connectionStyle == style,
              onSelected: (selected) {
                if (selected) {
                  _updateTheme(
                    _theme.copyWith(
                      connectionStyle: style,
                      temporaryConnectionStyle: style,
                    ),
                  );
                }
              },
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildConnectionColorsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionTitle('Connection Colors'),
        const SizedBox(height: 12),
        _buildColorPicker('Normal', _theme.connectionTheme.color, (color) {
          _updateTheme(
            _theme.copyWith(
              connectionTheme: _theme.connectionTheme.copyWith(color: color),
            ),
          );
        }),
        const SizedBox(height: 8),
        _buildColorPicker('Selected', _theme.connectionTheme.selectedColor, (
          color,
        ) {
          _updateTheme(
            _theme.copyWith(
              connectionTheme: _theme.connectionTheme.copyWith(
                selectedColor: color,
              ),
            ),
          );
        }),
        const SizedBox(height: 8),
        _buildColorPicker('Temporary', _theme.temporaryConnectionTheme.color, (
          color,
        ) {
          _updateTheme(
            _theme.copyWith(
              temporaryConnectionTheme: _theme.temporaryConnectionTheme
                  .copyWith(color: color),
            ),
          );
        }),
      ],
    );
  }

  Widget _buildColorPicker(
    String label,
    Color color,
    Function(Color) onColorChanged,
  ) {
    return Row(
      children: [
        SizedBox(
          width: 80,
          child: Text(label, style: const TextStyle(fontSize: 12)),
        ),
        GestureDetector(
          onTap: () => _showColorPicker(color, onColorChanged),
          child: Container(
            width: 40,
            height: 24,
            decoration: BoxDecoration(
              color: color,
              border: Border.all(color: Colors.grey.shade400),
              borderRadius: BorderRadius.circular(4),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            '#${color.toARGB32().toRadixString(16).substring(2).toUpperCase()}',
            style: TextStyle(
              fontSize: 11,
              fontFamily: 'monospace',
              color: Colors.grey.shade600,
            ),
          ),
        ),
      ],
    );
  }

  void _showColorPicker(Color initialColor, Function(Color) onColorChanged) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Pick a color'),
        content: SingleChildScrollView(
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children:
                [
                  Colors.red,
                  Colors.pink,
                  Colors.purple,
                  Colors.deepPurple,
                  Colors.indigo,
                  Colors.blue,
                  Colors.lightBlue,
                  Colors.cyan,
                  Colors.teal,
                  Colors.green,
                  Colors.lightGreen,
                  Colors.lime,
                  Colors.yellow,
                  Colors.amber,
                  Colors.orange,
                  Colors.deepOrange,
                  Colors.brown,
                  Colors.grey,
                  Colors.blueGrey,
                  Colors.black,
                ].map((color) {
                  return GestureDetector(
                    onTap: () {
                      onColorChanged(color);
                      Navigator.of(context).pop();
                    },
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: color,
                        border: Border.all(
                          color: color == initialColor
                              ? Colors.white
                              : Colors.grey.shade300,
                          width: color == initialColor ? 3 : 1,
                        ),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  );
                }).toList(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  Widget _buildStrokeWidthSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionTitle('Stroke Width'),
        const SizedBox(height: 12),
        _buildSlider('Normal', _theme.connectionTheme.strokeWidth, 1.0, 5.0, (
          value,
        ) {
          _updateTheme(
            _theme.copyWith(
              connectionTheme: _theme.connectionTheme.copyWith(
                strokeWidth: value,
              ),
            ),
          );
        }),
        _buildSlider(
          'Selected',
          _theme.connectionTheme.selectedStrokeWidth,
          1.0,
          6.0,
          (value) {
            _updateTheme(
              _theme.copyWith(
                connectionTheme: _theme.connectionTheme.copyWith(
                  selectedStrokeWidth: value,
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildPortSizeSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionTitle('Port Size'),
        const SizedBox(height: 12),
        _buildSlider('Size', _theme.portTheme.size, 6.0, 16.0, (value) {
          _updateTheme(
            _theme.copyWith(portTheme: _theme.portTheme.copyWith(size: value)),
          );
        }),
      ],
    );
  }

  Widget _buildSlider(
    String label,
    double value,
    double min,
    double max,
    Function(double) onChanged,
  ) {
    return Row(
      children: [
        SizedBox(
          width: 80,
          child: Text(label, style: const TextStyle(fontSize: 12)),
        ),
        Expanded(
          child: Slider(
            value: value,
            min: min,
            max: max,
            divisions: ((max - min) * 2).toInt(),
            label: value.toStringAsFixed(1),
            onChanged: onChanged,
          ),
        ),
        SizedBox(
          width: 35,
          child: Text(
            value.toStringAsFixed(1),
            style: const TextStyle(fontSize: 11),
            textAlign: TextAlign.right,
          ),
        ),
      ],
    );
  }

  Widget _buildGridSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionTitle('Grid'),
        const SizedBox(height: 12),
        _buildColorPicker('Grid Color', _theme.gridColor, (color) {
          _updateTheme(_theme.copyWith(gridColor: color));
        }),
        const SizedBox(height: 8),
        _buildSlider('Grid Size', _theme.gridSize, 10.0, 50.0, (value) {
          _updateTheme(_theme.copyWith(gridSize: value));
        }),
        _buildSlider('Grid Thickness', _theme.gridThickness, 0.5, 3.0, (value) {
          _updateTheme(_theme.copyWith(gridThickness: value));
        }),
        const SizedBox(height: 8),
        const Text('Grid Style', style: TextStyle(fontSize: 12)),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: GridStyle.values.map((style) {
            return ChoiceChip(
              label: Text(style.name, style: const TextStyle(fontSize: 11)),
              selected: _theme.gridStyle == style,
              onSelected: (selected) {
                if (selected) {
                  _updateTheme(_theme.copyWith(gridStyle: style));
                }
              },
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildNodeBorderSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionTitle('Node Border'),
        const SizedBox(height: 12),
        _buildSlider('Border Width', _theme.nodeTheme.borderWidth, 0.0, 5.0, (
          value,
        ) {
          _updateTheme(
            _theme.copyWith(
              nodeTheme: _theme.nodeTheme.copyWith(borderWidth: value),
            ),
          );
        }),
        _buildSlider(
          'Border Radius',
          _theme.nodeTheme.borderRadius.topLeft.x,
          0.0,
          20.0,
          (value) {
            _updateTheme(
              _theme.copyWith(
                nodeTheme: _theme.nodeTheme.copyWith(
                  borderRadius: BorderRadius.circular(value),
                ),
              ),
            );
          },
        ),
        const SizedBox(height: 8),
        _buildColorPicker('Border Color', _theme.nodeTheme.borderColor, (
          color,
        ) {
          _updateTheme(
            _theme.copyWith(
              nodeTheme: _theme.nodeTheme.copyWith(borderColor: color),
            ),
          );
        }),
        const SizedBox(height: 8),
        _buildColorPicker('Selected', _theme.nodeTheme.selectedBorderColor, (
          color,
        ) {
          _updateTheme(
            _theme.copyWith(
              nodeTheme: _theme.nodeTheme.copyWith(selectedBorderColor: color),
            ),
          );
        }),
      ],
    );
  }
}
