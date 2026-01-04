import 'package:flutter/material.dart';
import 'package:vyuh_node_flow/vyuh_node_flow.dart';

import '../shared/ui_widgets.dart';

/// Demonstrates AutoPan functionality with switchable presets.
///
/// AutoPan automatically pans the viewport when dragging elements near the
/// edge of the canvas. This example allows switching between:
/// - Normal: Balanced settings for general use
/// - Fast: Quick panning for large canvases
/// - Precise: Fine control with smaller movements
/// - Custom: User-configurable settings
/// - Disabled: AutoPan turned off
class AutoPanExample extends StatefulWidget {
  const AutoPanExample({super.key});

  @override
  State<AutoPanExample> createState() => _AutoPanExampleState();
}

enum AutoPanPreset { normal, fast, precise, custom, disabled }

class _AutoPanExampleState extends State<AutoPanExample> {
  late NodeFlowController<String, dynamic> _controller;
  AutoPanPreset _selectedPreset = AutoPanPreset.normal;

  // Custom settings
  double _edgePadding = 50.0;
  double _panAmount = 10.0;
  bool _useProximityScaling = false;

  @override
  void initState() {
    super.initState();
    _controller = NodeFlowController<String, dynamic>(
      config: NodeFlowConfig(
        extensions: [
          AutoPanExtension(), // Uses defaults (normal preset values)
          DebugExtension(
            mode: DebugMode.autoPanZone,
          ), // Show edge zones overlay by default
          LodExtension(),
          MinimapExtension(),
          StatsExtension(),
        ],
      ),
    );
    _createExampleGraph();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _createExampleGraph() {
    // Create nodes spread across the canvas to encourage autopan usage
    final positions = [
      const Offset(100, 100),
      const Offset(400, 100),
      const Offset(700, 100),
      const Offset(100, 300),
      const Offset(400, 300),
      const Offset(700, 300),
      const Offset(100, 500),
      const Offset(400, 500),
      const Offset(700, 500),
    ];

    final types = ['source', 'process', 'sink'];

    for (var i = 0; i < positions.length; i++) {
      final typeIndex = i % 3;
      _controller.addNode(
        Node<String>(
          id: 'node-$i',
          type: types[typeIndex],
          position: positions[i],
          size: const Size(120, 80),
          data: 'Node ${i + 1}',
          inputPorts: typeIndex > 0
              ? [
                  Port(
                    id: 'in',
                    name: 'Input',
                    position: PortPosition.left,
                    offset: const Offset(-2, 40),
                  ),
                ]
              : [],
          outputPorts: typeIndex < 2
              ? [
                  Port(
                    id: 'out',
                    name: 'Output',
                    position: PortPosition.right,
                    offset: const Offset(2, 40),
                  ),
                ]
              : [],
        ),
      );
    }

    // Add some connections
    _controller.addConnection(
      Connection(
        id: 'c1',
        sourceNodeId: 'node-0',
        sourcePortId: 'out',
        targetNodeId: 'node-1',
        targetPortId: 'in',
      ),
    );
    _controller.addConnection(
      Connection(
        id: 'c2',
        sourceNodeId: 'node-1',
        sourcePortId: 'out',
        targetNodeId: 'node-2',
        targetPortId: 'in',
      ),
    );
    _controller.addConnection(
      Connection(
        id: 'c3',
        sourceNodeId: 'node-3',
        sourcePortId: 'out',
        targetNodeId: 'node-4',
        targetPortId: 'in',
      ),
    );
    _controller.addConnection(
      Connection(
        id: 'c4',
        sourceNodeId: 'node-4',
        sourcePortId: 'out',
        targetNodeId: 'node-5',
        targetPortId: 'in',
      ),
    );

    // Add a comment node to demonstrate node autopan
    _controller.addNode(
      CommentNode<String>(
        id: 'comment-1',
        position: const Offset(250, 400),
        width: 200,
        height: 100,
        text:
            'Drag me! Drag this note to the edge of the viewport to see autopan in action.',
        data: '',
        color: Colors.yellow.shade200,
      ),
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _controller.fitToView();
    });
  }

  void _updateAutoPan() {
    final autoPan = _controller.autoPan;
    if (autoPan == null) return;

    switch (_selectedPreset) {
      case AutoPanPreset.normal:
        autoPan.useNormal();
        autoPan.enable();
        break;
      case AutoPanPreset.fast:
        autoPan.useFast();
        autoPan.enable();
        break;
      case AutoPanPreset.precise:
        autoPan.usePrecise();
        autoPan.enable();
        break;
      case AutoPanPreset.custom:
        autoPan.setEdgePadding(EdgeInsets.all(_edgePadding));
        autoPan.setPanAmount(_panAmount);
        autoPan.setUseProximityScaling(_useProximityScaling);
        if (_useProximityScaling) {
          autoPan.setSpeedCurve(Curves.easeIn);
        } else {
          autoPan.setSpeedCurve(null);
        }
        autoPan.enable();
        break;
      case AutoPanPreset.disabled:
        autoPan.disable();
        break;
    }
  }

  Widget _buildNode(BuildContext context, Node<String> node) {
    Color color;
    IconData icon;

    switch (node.type) {
      case 'source':
        color = Colors.green.shade100;
        icon = Icons.input;
        break;
      case 'process':
        color = Colors.blue.shade100;
        icon = Icons.settings;
        break;
      case 'sink':
        color = Colors.orange.shade100;
        icon = Icons.output;
        break;
      default:
        color = Colors.grey.shade100;
        icon = Icons.circle;
    }

    return Container(
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
            node.data,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade800,
            ),
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
        _createExampleGraph();
        _controller.fitToView();
      },
      child: NodeFlowEditor<String, dynamic>(
        controller: _controller,
        nodeBuilder: _buildNode,
        theme: NodeFlowTheme.light,
      ),
      children: [
        _buildPresetSection(),
        _buildDebugModeToggle(),
        _buildCurrentSettingsInfo(),
        if (_selectedPreset == AutoPanPreset.custom) _buildCustomSettings(),
        _buildInstructions(),
      ],
    );
  }

  Widget _buildPresetSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SectionTitle('AutoPan Preset'),
        SectionContent(
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: AutoPanPreset.values.map((preset) {
              final isSelected = _selectedPreset == preset;
              final label = switch (preset) {
                AutoPanPreset.normal => 'Normal',
                AutoPanPreset.fast => 'Fast',
                AutoPanPreset.precise => 'Precise',
                AutoPanPreset.custom => 'Custom',
                AutoPanPreset.disabled => 'Disabled',
              };
              return StyledChip(
                label: label,
                selected: isSelected,
                onSelected: (selected) {
                  if (selected) {
                    setState(() {
                      _selectedPreset = preset;
                    });
                    _updateAutoPan();
                  }
                },
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildDebugModeToggle() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SectionTitle('Debug Visualization'),
        SectionContent(
          child: Row(
            children: [
              const Expanded(
                child: Text('Show Edge Zones', style: TextStyle(fontSize: 12)),
              ),
              Switch(
                value: _controller.debug?.showAutoPanZone ?? false,
                onChanged: (value) {
                  _controller.debug?.setMode(
                    value ? DebugMode.autoPanZone : DebugMode.none,
                  );
                  setState(() {});
                },
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCurrentSettingsInfo() {
    final autoPan = _controller.autoPan;
    final isDisabled = autoPan == null || !autoPan.isEnabled;

    final content = isDisabled
        ? 'AutoPan is disabled'
        : 'Edge Padding: ${_formatEdgePadding(autoPan.edgePadding)}\n'
              'Pan Amount: ${autoPan.panAmount.toStringAsFixed(0)} units\n'
              'Interval: ${autoPan.panInterval.inMilliseconds} ms\n'
              'Proximity Scaling: ${autoPan.useProximityScaling ? 'On' : 'Off'}';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SectionTitle('Current Settings'),
        SectionContent(
          child: InfoCard(
            title: isDisabled ? 'Disabled' : 'Active Configuration',
            content: content,
          ),
        ),
      ],
    );
  }

  String _formatEdgePadding(EdgeInsets padding) {
    // Check if all edges are equal (uniform padding)
    if (padding.left == padding.right &&
        padding.left == padding.top &&
        padding.left == padding.bottom) {
      return '${padding.left.toStringAsFixed(0)} px (all)';
    }
    // Show LTRB for non-uniform padding
    return 'L:${padding.left.toStringAsFixed(0)} T:${padding.top.toStringAsFixed(0)} '
        'R:${padding.right.toStringAsFixed(0)} B:${padding.bottom.toStringAsFixed(0)}';
  }

  Widget _buildCustomSettings() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SectionTitle('Custom Configuration'),
        SectionContent(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildSlider('Edge Padding', _edgePadding, 20, 100, (value) {
                setState(() => _edgePadding = value);
                _updateAutoPan();
              }),
              Text(
                'Distance from edge where panning starts',
                style: TextStyle(fontSize: 10, color: Colors.grey.shade600),
              ),
              const SizedBox(height: 12),
              _buildSlider('Pan Amount', _panAmount, 2, 30, (value) {
                setState(() => _panAmount = value);
                _updateAutoPan();
              }),
              Text(
                'Pan distance per tick (graph units)',
                style: TextStyle(fontSize: 10, color: Colors.grey.shade600),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  const Text(
                    'Proximity Scaling',
                    style: TextStyle(fontSize: 12),
                  ),
                  const Spacer(),
                  Switch(
                    value: _useProximityScaling,
                    onChanged: (value) {
                      setState(() => _useProximityScaling = value);
                      _updateAutoPan();
                    },
                  ),
                ],
              ),
              Text(
                'Speed increases as pointer gets closer to edge',
                style: TextStyle(fontSize: 10, color: Colors.grey.shade600),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSlider(
    String label,
    double value,
    double min,
    double max,
    ValueChanged<double> onChanged,
  ) {
    return Row(
      children: [
        SizedBox(
          width: 100,
          child: Text(label, style: const TextStyle(fontSize: 12)),
        ),
        Expanded(
          child: Slider(
            value: value,
            min: min,
            max: max,
            divisions: (max - min).toInt(),
            onChanged: onChanged,
          ),
        ),
        SizedBox(
          width: 40,
          child: Text(
            value.toStringAsFixed(0),
            style: const TextStyle(fontSize: 12),
            textAlign: TextAlign.right,
          ),
        ),
      ],
    );
  }

  Widget _buildInstructions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SectionTitle('Try It Out'),
        SectionContent(
          child: InfoCard(
            title: 'How to Test',
            content:
                '1. Drag a node toward the viewport edge\n'
                '2. Hold at the edge to trigger autopan\n'
                '3. The canvas pans to reveal more space\n'
                '4. Try different presets to feel the difference',
          ),
        ),
      ],
    );
  }
}
