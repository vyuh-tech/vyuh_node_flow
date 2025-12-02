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
  MarkerShape _selectedPortShape = MarkerShapes.capsuleHalf;
  bool _scrollToZoom = true;
  double _endpointSize = 5.0;
  bool _useCustomPortBuilder = false;
  bool _useCustomLabelBuilder = false;

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
    // Port offsets specify the CENTER of the port shape:
    // - For left/right ports: offset.dy is the vertical center
    // - For top/bottom ports: offset.dx is the horizontal center
    final node1 = Node<Map<String, dynamic>>(
      id: 'node1',
      type: 'source',
      position: const Offset(100, 100),
      size: const Size(150, 100),
      data: {'label': 'Source'},
      outputPorts: [
        Port(
          id: 'out1',
          name: 'Output 1',
          position: PortPosition.right,
          offset: const Offset(2, 20), // Starting offset
          shape: _selectedPortShape,
          showLabel: true,
        ),
        Port(
          id: 'out2',
          name: 'Output 2',
          position: PortPosition.right,
          offset: const Offset(2, 50), // 20 + 30 separation
          shape: _selectedPortShape,
          showLabel: true,
        ),
        Port(
          id: 'out-top',
          name: 'Top',
          position: PortPosition.top,
          offset: const Offset(75, -2), // Horizontal center at mid-width
          shape: _selectedPortShape,
          showLabel: true,
        ),
        Port(
          id: 'out-bottom',
          name: 'Bottom',
          position: PortPosition.bottom,
          offset: const Offset(75, 2), // Horizontal center at mid-width
          shape: _selectedPortShape,
          showLabel: true,
        ),
      ],
    );

    final node2 = Node<Map<String, dynamic>>(
      id: 'node2',
      type: 'transform',
      position: const Offset(350, 80),
      size: const Size(150, 100),
      data: {'label': 'Transform'},
      inputPorts: [
        Port(
          id: 'in1',
          name: 'Input',
          position: PortPosition.left,
          offset: const Offset(-2, 50), // Vertical center at mid-height
          shape: _selectedPortShape,
          showLabel: true,
        ),
      ],
      outputPorts: [
        Port(
          id: 'out1',
          name: 'Output',
          position: PortPosition.right,
          offset: const Offset(2, 50), // Vertical center at mid-height
          shape: _selectedPortShape,
          showLabel: true,
        ),
      ],
    );

    final node3 = Node<Map<String, dynamic>>(
      id: 'node3',
      type: 'sink',
      position: const Offset(600, 100),
      size: const Size(150, 100),
      data: {'label': 'Sink'},
      inputPorts: [
        Port(
          id: 'in1',
          name: 'Input 1',
          position: PortPosition.left,
          offset: const Offset(-2, 20), // Starting offset
          shape: _selectedPortShape,
          showLabel: true,
        ),
        Port(
          id: 'in2',
          name: 'Input 2',
          position: PortPosition.left,
          offset: const Offset(-2, 50), // 20 + 30 separation
          shape: _selectedPortShape,
          showLabel: true,
        ),
        Port(
          id: 'in-top',
          name: 'Top',
          position: PortPosition.top,
          offset: const Offset(75, -2), // Horizontal center at mid-width
          shape: _selectedPortShape,
          showLabel: true,
        ),
        Port(
          id: 'in-bottom',
          name: 'Bottom',
          position: PortPosition.bottom,
          offset: const Offset(75, 2), // Horizontal center at mid-width
          shape: _selectedPortShape,
          showLabel: true,
        ),
      ],
    );

    _controller.addNode(node1);
    _controller.addNode(node2);
    _controller.addNode(node3);

    // Add connections with labels
    _controller.addConnection(
      Connection(
        id: 'conn1',
        sourceNodeId: 'node1',
        sourcePortId: 'out1',
        targetNodeId: 'node2',
        targetPortId: 'in1',
        label: ConnectionLabel.center(text: 'Data Flow'),
      ),
    );

    _controller.addConnection(
      Connection(
        id: 'conn2',
        sourceNodeId: 'node2',
        sourcePortId: 'out1',
        targetNodeId: 'node3',
        targetPortId: 'in1',
        label: ConnectionLabel.center(text: 'Transform'),
      ),
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _controller.fitToView();
    });
  }

  void _updateTheme(NodeFlowTheme newTheme) {
    setState(() {
      _theme = newTheme;
    });
  }

  void _resetToLightTheme() {
    setState(() {
      _theme = NodeFlowTheme.light;
      _selectedPortShape = MarkerShapes.capsuleHalf;
    });

    // Clear and recreate the graph with default port shapes
    _controller.clearGraph();
    _createExampleGraph();
  }

  void _updatePortShape(MarkerShape newShape) {
    setState(() {
      _selectedPortShape = newShape;
    });

    // Clear and recreate the graph with new port shapes
    _controller.clearGraph();
    _createExampleGraph();
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

  /// Custom port builder that colors ports based on whether they're input or output
  Widget _buildCustomPort(
    BuildContext context,
    Node<Map<String, dynamic>> node,
    Port port,
    bool isOutput,
    bool isConnected,
    bool isHighlighted,
  ) {
    final portTheme = _theme.portTheme;

    // Use different colors for input vs output ports
    final baseColor = isOutput ? Colors.green : Colors.blue;
    final color = isHighlighted
        ? baseColor.shade700
        : isConnected
        ? baseColor.shade400
        : baseColor.shade200;

    return PortWidget(
      port: port,
      theme: portTheme,
      isConnected: isConnected,
      isHighlighted: isHighlighted,
      color: color,
      connectedColor: baseColor.shade400,
      snappingColor: baseColor.shade700,
      borderColor: baseColor.shade800,
      borderWidth: isHighlighted ? 2.0 : 1.0,
    );
  }

  /// Custom label builder that adds icons to labels
  Widget _buildCustomLabel(
    BuildContext context,
    Connection connection,
    ConnectionLabel label,
    Rect position,
  ) {
    final labelTheme = _theme.labelTheme;

    // Use OverflowBox to allow custom sizing while maintaining center alignment
    // The position rect is calculated for the default label size, so we use
    // SizedBox + alignment to center our custom-sized widget
    return SizedBox(
      width: position.width,
      height: position.height,
      child: OverflowBox(
        maxWidth: double.infinity,
        maxHeight: double.infinity,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.amber.shade100,
            borderRadius: BorderRadius.circular(50), // Capsule shape
            border: Border.all(color: Colors.amber.shade400),
            boxShadow: [
              BoxShadow(
                color: Colors.amber.withValues(alpha: 0.3),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.bolt, size: 14, color: Colors.amber.shade800),
              const SizedBox(width: 4),
              Text(
                label.text,
                style: labelTheme.textStyle.copyWith(
                  color: Colors.amber.shade900,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ResponsiveControlPanel(
      title: 'Theme Editor',
      width: 320,
      actions: [
        IconButton(
          icon: const Icon(Icons.refresh, size: 20),
          onPressed: _resetToLightTheme,
          tooltip: 'Reset to Light Theme',
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(),
        ),
      ],
      child: NodeFlowEditor<Map<String, dynamic>>(
        controller: _controller,
        nodeBuilder: _buildNode,
        theme: _theme,
        scrollToZoom: _scrollToZoom,
        portBuilder: _useCustomPortBuilder ? _buildCustomPort : null,
        labelBuilder: _useCustomLabelBuilder ? _buildCustomLabel : null,
      ),
      children: [
        _buildThemePresets(),
        const SizedBox(height: 24),
        _buildConnectionStyleSection(),
        const SizedBox(height: 24),
        _buildConnectionEffectSection(),
        const SizedBox(height: 24),
        _buildConnectionColorsSection(),
        const SizedBox(height: 24),
        _buildStrokeWidthSection(),
        const SizedBox(height: 24),
        _buildPortSizeSection(),
        const SizedBox(height: 24),
        _buildCustomBuildersSection(),
        const SizedBox(height: 24),
        _buildGridSection(),
        const SizedBox(height: 24),
        _buildViewportSection(),
        const SizedBox(height: 24),
        _buildNodeBorderSection(),
      ],
    );
  }

  Widget _buildThemePresets() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SectionTitle('Theme Presets'),
        const SizedBox(height: 12),
        ControlButton(
          icon: Icons.light_mode,
          label: 'Light',
          onPressed: _resetToLightTheme,
        ),
        const SizedBox(height: 8),
        ControlButton(
          icon: Icons.dark_mode,
          label: 'Dark',
          onPressed: () {
            setState(() {
              _theme = NodeFlowTheme.dark;
              _selectedPortShape = MarkerShapes.capsuleHalf;
            });
            _controller.clearGraph();
            _createExampleGraph();
          },
        ),
      ],
    );
  }

  Widget _buildConnectionStyleSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
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
              selected: _theme.connectionTheme.style == style,
              onSelected: (selected) {
                if (selected) {
                  _updateTheme(
                    _theme.copyWith(
                      connectionTheme: _theme.connectionTheme.copyWith(
                        style: style,
                      ),
                      temporaryConnectionTheme: _theme.temporaryConnectionTheme
                          .copyWith(style: style),
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

  Widget _buildConnectionEffectSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SectionTitle('Connection Effect'),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children:
              [
                ('None', null),
                ('Flowing Dash', ConnectionEffects.flowingDash),
                ('Particles', ConnectionEffects.particles),
                ('Gradient', ConnectionEffects.gradientFlow),
                ('Pulse', ConnectionEffects.pulse),
              ].map((entry) {
                final (name, effect) = entry;
                return ChoiceChip(
                  label: Text(name, style: const TextStyle(fontSize: 11)),
                  selected: _theme.connectionTheme.animationEffect == effect,
                  onSelected: (selected) {
                    if (selected) {
                      _updateTheme(
                        _theme.copyWith(
                          connectionTheme: _theme.connectionTheme.copyWith(
                            animationEffect: effect,
                          ),
                          temporaryConnectionTheme: _theme
                              .temporaryConnectionTheme
                              .copyWith(animationEffect: effect),
                        ),
                      );
                    }
                  },
                );
              }).toList(),
        ),
        const SizedBox(height: 16),
        const Text('Start Point', style: TextStyle(fontSize: 12)),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children:
              [
                ('None', MarkerShapes.none),
                ('Circle', MarkerShapes.circle),
                ('Rectangle', MarkerShapes.rectangle),
                ('Diamond', MarkerShapes.diamond),
                ('Triangle', MarkerShapes.triangle),
                ('Capsule', MarkerShapes.capsuleHalf),
              ].map((entry) {
                final (name, shape) = entry;
                final isSelected =
                    _theme.connectionTheme.startPoint.shape == shape;
                return ChoiceChip(
                  label: Text(name, style: const TextStyle(fontSize: 11)),
                  selected: isSelected,
                  onSelected: (selected) {
                    if (selected) {
                      _updateTheme(
                        _theme.copyWith(
                          connectionTheme: _theme.connectionTheme.copyWith(
                            startPoint: ConnectionEndPoint(
                              shape: shape,
                              size: _endpointSize,
                            ),
                          ),
                        ),
                      );
                    }
                  },
                );
              }).toList(),
        ),
        const SizedBox(height: 12),
        const Text('End Point', style: TextStyle(fontSize: 12)),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children:
              [
                ('None', MarkerShapes.none),
                ('Circle', MarkerShapes.circle),
                ('Rectangle', MarkerShapes.rectangle),
                ('Diamond', MarkerShapes.diamond),
                ('Triangle', MarkerShapes.triangle),
                ('Capsule', MarkerShapes.capsuleHalf),
              ].map((entry) {
                final (name, shape) = entry;
                final isSelected =
                    _theme.connectionTheme.endPoint.shape == shape;
                return ChoiceChip(
                  label: Text(name, style: const TextStyle(fontSize: 11)),
                  selected: isSelected,
                  onSelected: (selected) {
                    if (selected) {
                      _updateTheme(
                        _theme.copyWith(
                          connectionTheme: _theme.connectionTheme.copyWith(
                            endPoint: ConnectionEndPoint(
                              shape: shape,
                              size: _endpointSize,
                            ),
                          ),
                        ),
                      );
                    }
                  },
                );
              }).toList(),
        ),
        const SizedBox(height: 12),
        _buildSlider('Endpoint Size', _endpointSize, 3.0, 15.0, (value) {
          setState(() {
            _endpointSize = value;
          });
          _updateTheme(
            _theme.copyWith(
              connectionTheme: _theme.connectionTheme.copyWith(
                startPoint: _theme.connectionTheme.startPoint.copyWith(
                  size: value,
                ),
                endPoint: _theme.connectionTheme.endPoint.copyWith(size: value),
              ),
            ),
          );
        }),
      ],
    );
  }

  Widget _buildConnectionColorsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
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
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SectionTitle('Connections'),
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
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SectionTitle('Ports'),
        const SizedBox(height: 12),
        _buildSlider('Size', _theme.portTheme.size.width, 6.0, 16.0, (value) {
          _updateTheme(
            _theme.copyWith(
              portTheme: _theme.portTheme.copyWith(size: Size.square(value)),
            ),
          );
        }),
        const SizedBox(height: 12),
        const Text('Port Shape', style: TextStyle(fontSize: 12)),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children:
              [
                ('circle', MarkerShapes.circle),
                ('rectangle', MarkerShapes.rectangle),
                ('diamond', MarkerShapes.diamond),
                ('triangle', MarkerShapes.triangle),
                ('capsule', MarkerShapes.capsuleHalf),
              ].map((entry) {
                final (name, shape) = entry;
                return ChoiceChip(
                  label: Text(name, style: const TextStyle(fontSize: 11)),
                  selected: _selectedPortShape == shape,
                  onSelected: (selected) {
                    if (selected) {
                      _updatePortShape(shape);
                    }
                  },
                );
              }).toList(),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            const Text('Show Labels', style: TextStyle(fontSize: 12)),
            const Spacer(),
            Switch(
              value: _theme.portTheme.showLabel,
              onChanged: (value) {
                _updateTheme(
                  _theme.copyWith(
                    portTheme: _theme.portTheme.copyWith(showLabel: value),
                  ),
                );
              },
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildCustomBuildersSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SectionTitle('Custom Builders'),
        const SizedBox(height: 12),
        Row(
          children: [
            const Text('Custom Port Builder', style: TextStyle(fontSize: 12)),
            const Spacer(),
            Switch(
              value: _useCustomPortBuilder,
              onChanged: (value) {
                setState(() {
                  _useCustomPortBuilder = value;
                });
              },
            ),
          ],
        ),
        Text(
          'Colors ports based on input (blue) / output (green)',
          style: TextStyle(fontSize: 10, color: Colors.grey.shade600),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            const Text('Custom Label Builder', style: TextStyle(fontSize: 12)),
            const Spacer(),
            Switch(
              value: _useCustomLabelBuilder,
              onChanged: (value) {
                setState(() {
                  _useCustomLabelBuilder = value;
                });
              },
            ),
          ],
        ),
        Text(
          'Adds icons and custom styling to connection labels',
          style: TextStyle(fontSize: 10, color: Colors.grey.shade600),
        ),
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
    final gridTheme = _theme.gridTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SectionTitle('Grid'),
        const SizedBox(height: 12),
        _buildColorPicker('Grid Color', gridTheme.color, (color) {
          _updateTheme(
            _theme.copyWith(gridTheme: gridTheme.copyWith(color: color)),
          );
        }),
        const SizedBox(height: 8),
        _buildSlider('Grid Size', gridTheme.size, 10.0, 50.0, (value) {
          _updateTheme(
            _theme.copyWith(gridTheme: gridTheme.copyWith(size: value)),
          );
        }),
        _buildSlider('Grid Thickness', gridTheme.thickness, 0.5, 3.0, (value) {
          _updateTheme(
            _theme.copyWith(gridTheme: gridTheme.copyWith(thickness: value)),
          );
        }),
        const SizedBox(height: 8),
        const Text('Grid Style', style: TextStyle(fontSize: 12)),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children:
              [
                ('lines', GridStyles.lines),
                ('dots', GridStyles.dots),
                ('hierarchical', GridStyles.hierarchical),
                ('cross', GridStyles.cross),
                ('none', GridStyles.none),
              ].map((entry) {
                final (name, style) = entry;
                return ChoiceChip(
                  label: Text(name, style: const TextStyle(fontSize: 11)),
                  selected: gridTheme.style == style,
                  onSelected: (selected) {
                    if (selected) {
                      _updateTheme(
                        _theme.copyWith(
                          gridTheme: gridTheme.copyWith(style: style),
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

  Widget _buildViewportSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SectionTitle('Viewport'),
        const SizedBox(height: 12),
        Row(
          children: [
            const Text('Scroll to Zoom', style: TextStyle(fontSize: 12)),
            const Spacer(),
            Switch(
              value: _scrollToZoom,
              onChanged: (value) {
                setState(() {
                  _scrollToZoom = value;
                });
              },
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildNodeBorderSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SectionTitle('Nodes'),
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
