import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:vyuh_node_flow/vyuh_node_flow.dart';

import '../shared/ui_widgets.dart';

class LODExample extends StatefulWidget {
  const LODExample({super.key});

  @override
  State<LODExample> createState() => _LODExampleState();
}

class _LODExampleState extends State<LODExample> {
  late NodeFlowController<Map<String, dynamic>, dynamic> _controller;
  double _minThreshold = 0.25;
  double _midThreshold = 0.60;
  bool _lodEnabled = true;

  @override
  void initState() {
    super.initState();
    _controller = NodeFlowController<Map<String, dynamic>, dynamic>(
      config: NodeFlowConfig(
        extensions: [
          LodExtension(),
          AutoPanExtension(),
          DebugExtension(),
          MinimapExtension(),
          StatsExtension(),
        ],
      ),
      nodes: _createNodes(),
      connections: _createConnections(),
    );
  }

  static List<Node<Map<String, dynamic>>> _createNodes() {
    const portShape = MarkerShapes.capsuleHalf;

    // Create a larger graph to demonstrate LOD benefits
    return [
      // Row 1
      Node<Map<String, dynamic>>(
        id: 'input-1',
        type: 'input',
        position: const Offset(50, 50),
        size: const Size(140, 80),
        data: {'label': 'Data Source'},
        outputPorts: [
          Port(
            id: 'out',
            name: 'Output',
            position: PortPosition.right,
            offset: const Offset(2, 40),
            shape: portShape,
            showLabel: true,
          ),
        ],
      ),
      Node<Map<String, dynamic>>(
        id: 'input-2',
        type: 'input',
        position: const Offset(50, 200),
        size: const Size(140, 80),
        data: {'label': 'Config'},
        outputPorts: [
          Port(
            id: 'out',
            name: 'Settings',
            position: PortPosition.right,
            offset: const Offset(2, 40),
            shape: portShape,
            showLabel: true,
          ),
        ],
      ),

      // Row 2 - Processing
      Node<Map<String, dynamic>>(
        id: 'process-1',
        type: 'process',
        position: const Offset(280, 80),
        size: const Size(160, 100),
        data: {'label': 'Transform'},
        inputPorts: [
          Port(
            id: 'in-data',
            name: 'Data',
            position: PortPosition.left,
            offset: const Offset(-2, 30),
            shape: portShape,
            showLabel: true,
          ),
          Port(
            id: 'in-config',
            name: 'Config',
            position: PortPosition.left,
            offset: const Offset(-2, 70),
            shape: portShape,
            showLabel: true,
          ),
        ],
        outputPorts: [
          Port(
            id: 'out',
            name: 'Result',
            position: PortPosition.right,
            offset: const Offset(2, 50),
            shape: portShape,
            showLabel: true,
          ),
        ],
      ),
      Node<Map<String, dynamic>>(
        id: 'process-2',
        type: 'process',
        position: const Offset(280, 230),
        size: const Size(160, 100),
        data: {'label': 'Validate'},
        inputPorts: [
          Port(
            id: 'in',
            name: 'Input',
            position: PortPosition.left,
            offset: const Offset(-2, 50),
            shape: portShape,
            showLabel: true,
          ),
        ],
        outputPorts: [
          Port(
            id: 'out-valid',
            name: 'Valid',
            position: PortPosition.right,
            offset: const Offset(2, 30),
            shape: portShape,
            showLabel: true,
          ),
          Port(
            id: 'out-invalid',
            name: 'Invalid',
            position: PortPosition.right,
            offset: const Offset(2, 70),
            shape: portShape,
            showLabel: true,
          ),
        ],
      ),

      // Row 3 - Merge and Output
      Node<Map<String, dynamic>>(
        id: 'merge',
        type: 'merge',
        position: const Offset(530, 120),
        size: const Size(140, 100),
        data: {'label': 'Merge'},
        inputPorts: [
          Port(
            id: 'in-1',
            name: 'Input A',
            position: PortPosition.left,
            offset: const Offset(-2, 30),
            shape: portShape,
            showLabel: true,
          ),
          Port(
            id: 'in-2',
            name: 'Input B',
            position: PortPosition.left,
            offset: const Offset(-2, 70),
            shape: portShape,
            showLabel: true,
          ),
        ],
        outputPorts: [
          Port(
            id: 'out',
            name: 'Merged',
            position: PortPosition.right,
            offset: const Offset(2, 50),
            shape: portShape,
            showLabel: true,
          ),
        ],
      ),
      Node<Map<String, dynamic>>(
        id: 'output-1',
        type: 'output',
        position: const Offset(760, 80),
        size: const Size(140, 80),
        data: {'label': 'Result'},
        inputPorts: [
          Port(
            id: 'in',
            name: 'Data',
            position: PortPosition.left,
            offset: const Offset(-2, 40),
            shape: portShape,
            showLabel: true,
          ),
        ],
      ),
      Node<Map<String, dynamic>>(
        id: 'output-2',
        type: 'output',
        position: const Offset(760, 200),
        size: const Size(140, 80),
        data: {'label': 'Errors'},
        inputPorts: [
          Port(
            id: 'in',
            name: 'Errors',
            position: PortPosition.left,
            offset: const Offset(-2, 40),
            shape: portShape,
            showLabel: true,
          ),
        ],
      ),
    ];
  }

  static List<Connection> _createConnections() {
    return [
      Connection(
        id: 'conn-1',
        sourceNodeId: 'input-1',
        sourcePortId: 'out',
        targetNodeId: 'process-1',
        targetPortId: 'in-data',
        label: ConnectionLabel.center(text: 'Raw Data'),
      ),
      Connection(
        id: 'conn-2',
        sourceNodeId: 'input-2',
        sourcePortId: 'out',
        targetNodeId: 'process-1',
        targetPortId: 'in-config',
      ),
      Connection(
        id: 'conn-3',
        sourceNodeId: 'process-1',
        sourcePortId: 'out',
        targetNodeId: 'process-2',
        targetPortId: 'in',
        label: ConnectionLabel.center(text: 'Processed'),
      ),
      Connection(
        id: 'conn-4',
        sourceNodeId: 'process-1',
        sourcePortId: 'out',
        targetNodeId: 'merge',
        targetPortId: 'in-1',
      ),
      Connection(
        id: 'conn-5',
        sourceNodeId: 'process-2',
        sourcePortId: 'out-valid',
        targetNodeId: 'merge',
        targetPortId: 'in-2',
        label: ConnectionLabel.center(text: 'Valid'),
      ),
      Connection(
        id: 'conn-6',
        sourceNodeId: 'process-2',
        sourcePortId: 'out-invalid',
        targetNodeId: 'output-2',
        targetPortId: 'in',
        label: ConnectionLabel.center(text: 'Errors'),
      ),
      Connection(
        id: 'conn-7',
        sourceNodeId: 'merge',
        sourcePortId: 'out',
        targetNodeId: 'output-1',
        targetPortId: 'in',
        label: ConnectionLabel.center(text: 'Final'),
      ),
    ];
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _updateLODConfig() {
    final lod = _controller.lod;
    if (lod == null) return;

    if (_lodEnabled) {
      lod.setThresholds(
        minThreshold: _minThreshold,
        midThreshold: _midThreshold,
      );
      lod.enable();
    } else {
      lod.disable();
    }
  }

  Widget _buildNode(BuildContext context, Node<Map<String, dynamic>> node) {
    Color nodeColor;
    IconData icon;

    switch (node.type) {
      case 'input':
        nodeColor = Colors.green.shade100;
        icon = Icons.input;
        break;
      case 'process':
        nodeColor = Colors.blue.shade100;
        icon = Icons.transform;
        break;
      case 'merge':
        nodeColor = Colors.purple.shade100;
        icon = Icons.merge;
        break;
      case 'output':
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
      child: NodeFlowEditor<Map<String, dynamic>, dynamic>(
        controller: _controller,
        nodeBuilder: _buildNode,
        theme: NodeFlowTheme.light,
        events: NodeFlowEvents(onInit: () => _controller.fitToView()),
      ),
      children: [
        _buildCurrentState(),
        _buildThresholdControls(),
        _buildVisibilityInfo(),
        _buildZoomActions(),
      ],
    );
  }

  Widget _buildCurrentState() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SectionTitle('Current State'),
        SectionContent(
          child: Observer(
            builder: (_) {
              final lod = _controller.lod;
              final normalizedZoom = lod?.normalizedZoom ?? 1.0;

              // Determine LOD level
              String level;
              Color levelColor;
              if (normalizedZoom < _minThreshold) {
                level = 'Minimal';
                levelColor = Colors.red;
              } else if (normalizedZoom < _midThreshold) {
                level = 'Standard';
                levelColor = Colors.orange;
              } else {
                level = 'Full';
                levelColor = Colors.green;
              }

              if (!_lodEnabled) {
                level = 'Disabled (Full)';
                levelColor = Colors.grey;
              }

              return Column(
                children: [
                  _buildInfoRow(
                    'Zoom',
                    '${(_controller.viewport.zoom * 100).toStringAsFixed(0)}%',
                  ),
                  _buildInfoRow(
                    'Normalized',
                    '${(normalizedZoom * 100).toStringAsFixed(0)}%',
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: levelColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: levelColor.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.layers, size: 16, color: levelColor),
                        const SizedBox(width: 8),
                        Text(
                          'LOD Level: $level',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: levelColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Visual zoom scale
                  _buildZoomScale(normalizedZoom),
                ],
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildZoomScale(double normalizedZoom) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Zoom Scale',
          style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 6),
        SizedBox(
          height: 40,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              // Background gradient
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(4),
                  gradient: LinearGradient(
                    colors: [
                      Colors.red.withValues(alpha: 0.3),
                      Colors.orange.withValues(alpha: 0.3),
                      Colors.green.withValues(alpha: 0.3),
                    ],
                    stops: [
                      _minThreshold,
                      (_minThreshold + _midThreshold) / 2,
                      1.0,
                    ],
                  ),
                ),
              ),
              // Threshold markers
              Positioned(
                left: _minThreshold * 280 - 1,
                top: 0,
                bottom: 0,
                child: Container(width: 2, color: Colors.orange.shade800),
              ),
              Positioned(
                left: _midThreshold * 280 - 1,
                top: 0,
                bottom: 0,
                child: Container(width: 2, color: Colors.green.shade800),
              ),
              // Current position indicator
              Positioned(
                left: normalizedZoom.clamp(0.0, 1.0) * 280 - 6,
                top: -4,
                child: Container(
                  width: 12,
                  height: 48,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: Colors.grey.shade800, width: 2),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.2),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 4),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '${(_controller.config.minZoom.value * 100).toStringAsFixed(0)}%',
              style: TextStyle(fontSize: 10, color: Colors.grey.shade600),
            ),
            Text(
              '${(_controller.config.maxZoom.value * 100).toStringAsFixed(0)}%',
              style: TextStyle(fontSize: 10, color: Colors.grey.shade600),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 12)),
          Text(
            value,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  Widget _buildThresholdControls() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SectionTitle('LOD Configuration'),
        SectionContent(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  const Text('Enable LOD', style: TextStyle(fontSize: 12)),
                  const Spacer(),
                  Switch(
                    value: _lodEnabled,
                    onChanged: (value) {
                      setState(() {
                        _lodEnabled = value;
                      });
                      _updateLODConfig();
                    },
                  ),
                ],
              ),
              Text(
                _lodEnabled
                    ? 'Visual elements hide based on zoom level'
                    : 'All visual elements always visible',
                style: TextStyle(fontSize: 10, color: Colors.grey.shade600),
              ),
              const SizedBox(height: 16),
              _buildSlider(
                'Min Threshold',
                _minThreshold,
                0.0,
                _midThreshold - 0.05,
                (value) {
                  setState(() {
                    _minThreshold = value;
                  });
                  _updateLODConfig();
                },
              ),
              Text(
                'Below ${(_minThreshold * 100).toStringAsFixed(0)}%: Minimal detail',
                style: TextStyle(fontSize: 10, color: Colors.grey.shade600),
              ),
              const SizedBox(height: 8),
              _buildSlider(
                'Mid Threshold',
                _midThreshold,
                _minThreshold + 0.05,
                1.0,
                (value) {
                  setState(() {
                    _midThreshold = value;
                  });
                  _updateLODConfig();
                },
              ),
              Text(
                'Above ${(_midThreshold * 100).toStringAsFixed(0)}%: Full detail',
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
          width: 90,
          child: Text(label, style: const TextStyle(fontSize: 12)),
        ),
        Expanded(
          child: Slider(
            value: value.clamp(min, max),
            min: min,
            max: max,
            divisions: 20,
            label: '${(value * 100).toStringAsFixed(0)}%',
            onChanged: _lodEnabled ? onChanged : null,
          ),
        ),
        SizedBox(
          width: 40,
          child: Text(
            '${(value * 100).toStringAsFixed(0)}%',
            style: const TextStyle(fontSize: 11),
            textAlign: TextAlign.right,
          ),
        ),
      ],
    );
  }

  Widget _buildVisibilityInfo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SectionTitle('Current Visibility'),
        SectionContent(
          child: Observer(
            builder: (_) {
              final visibility =
                  _controller.lod?.currentVisibility ?? DetailVisibility.full;

              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildVisibilityRow(
                    'Node Content',
                    visibility.showNodeContent,
                  ),
                  _buildVisibilityRow('Ports', visibility.showPorts),
                  _buildVisibilityRow('Port Labels', visibility.showPortLabels),
                  _buildVisibilityRow(
                    'Connection Lines',
                    visibility.showConnectionLines,
                  ),
                  _buildVisibilityRow(
                    'Connection Labels',
                    visibility.showConnectionLabels,
                  ),
                  _buildVisibilityRow(
                    'Connection Endpoints',
                    visibility.showConnectionEndpoints,
                  ),
                  _buildVisibilityRow(
                    'Resize Handles',
                    visibility.showResizeHandles,
                  ),
                ],
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildVisibilityRow(String label, bool isVisible) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Icon(
            isVisible ? Icons.visibility : Icons.visibility_off,
            size: 14,
            color: isVisible ? Colors.green : Colors.grey,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: isVisible ? Colors.black87 : Colors.grey,
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: isVisible
                  ? Colors.green.withValues(alpha: 0.1)
                  : Colors.grey.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              isVisible ? 'Visible' : 'Hidden',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: isVisible ? Colors.green : Colors.grey,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildZoomActions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SectionTitle('Quick Zoom'),
        SectionContent(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Jump to specific zoom levels to see LOD changes',
                style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _buildZoomButton('Min', _controller.config.minZoom.value),
                  _buildZoomButton('25%', 0.25),
                  _buildZoomButton('50%', 0.5),
                  _buildZoomButton('75%', 0.75),
                  _buildZoomButton('100%', 1.0),
                  _buildZoomButton('150%', 1.5),
                  _buildZoomButton('Max', _controller.config.maxZoom.value),
                ],
              ),
              const SizedBox(height: 12),
              ControlButton(
                icon: Icons.fit_screen,
                label: 'Fit to View',
                onPressed: () => _controller.fitToView(),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildZoomButton(String label, double zoom) {
    return Observer(
      builder: (_) {
        final currentZoom = _controller.viewport.zoom;
        final isSelected = (currentZoom - zoom).abs() < 0.05;
        return StyledChip(
          label: label,
          selected: isSelected,
          onSelected: (_) => _controller.zoomTo(zoom),
        );
      },
    );
  }
}
