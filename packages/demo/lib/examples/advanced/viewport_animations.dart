import 'package:flutter/material.dart';
import 'package:vyuh_node_flow/vyuh_node_flow.dart';

import '../../shared/ui_widgets.dart';

/// Demonstrates Viewport Animation capabilities.
///
/// This example showcases all viewport animation methods:
/// - animateToNode: Center on a specific node
/// - animateToPosition: Navigate to any canvas position
/// - animateToBounds: Fit a region (like selection) in view
/// - animateToScale: Animate zoom level
/// - animateToViewport: Full viewport state transition
///
/// Also demonstrates customizing animation duration and curves.
class ViewportAnimationsExample extends StatefulWidget {
  const ViewportAnimationsExample({super.key});

  @override
  State<ViewportAnimationsExample> createState() =>
      _ViewportAnimationsExampleState();
}

class _ViewportAnimationsExampleState extends State<ViewportAnimationsExample> {
  late NodeFlowController<String> _controller;

  // Animation settings
  Duration _duration = const Duration(milliseconds: 400);
  Curve _curve = Curves.easeInOut;
  double _targetZoom = 1.0;

  // Available curves for selection
  static const _curves = <String, Curve>{
    'easeInOut': Curves.easeInOut,
    'easeIn': Curves.easeIn,
    'easeOut': Curves.easeOut,
    'linear': Curves.linear,
    'bounceOut': Curves.bounceOut,
    'elasticOut': Curves.elasticOut,
    'decelerate': Curves.decelerate,
    'fastOutSlowIn': Curves.fastOutSlowIn,
  };

  String _selectedCurveName = 'easeInOut';

  @override
  void initState() {
    super.initState();
    _controller = NodeFlowController<String>(
      config: NodeFlowConfig(autoPan: AutoPanConfig.normal),
    );
    _createExampleGraph();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _createExampleGraph() {
    // Create a scattered graph to make navigation interesting
    final nodeData = [
      ('start', 'Start', const Offset(100, 200), Colors.green),
      ('process-1', 'Process A', const Offset(350, 100), Colors.blue),
      ('process-2', 'Process B', const Offset(350, 300), Colors.blue),
      ('decision', 'Decision', const Offset(600, 200), Colors.amber),
      ('output-1', 'Output 1', const Offset(850, 100), Colors.orange),
      ('output-2', 'Output 2', const Offset(850, 300), Colors.orange),
      ('end', 'End', const Offset(1100, 200), Colors.red),
      // Far away nodes
      ('remote-1', 'Remote Node', const Offset(-300, -200), Colors.purple),
      ('remote-2', 'Distant Node', const Offset(1500, 500), Colors.teal),
    ];

    for (final (id, label, position, _) in nodeData) {
      final isStart = id == 'start' || id.startsWith('remote');
      final isEnd = id == 'end' || id.contains('output');

      _controller.addNode(
        Node<String>(
          id: id,
          type: id.split('-').first,
          position: position,
          size: const Size(120, 80),
          data: label,
          inputPorts: !isStart
              ? [
                  Port(
                    id: 'in',
                    name: 'Input',
                    position: PortPosition.left,
                    offset: const Offset(-2, 40),
                  ),
                ]
              : [],
          outputPorts: !isEnd
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

    // Create connections
    final connections = [
      ('start', 'process-1'),
      ('start', 'process-2'),
      ('process-1', 'decision'),
      ('process-2', 'decision'),
      ('decision', 'output-1'),
      ('decision', 'output-2'),
      ('output-1', 'end'),
      ('output-2', 'end'),
    ];

    for (var i = 0; i < connections.length; i++) {
      final (source, target) = connections[i];
      _controller.addConnection(
        Connection(
          id: 'c$i',
          sourceNodeId: source,
          sourcePortId: 'out',
          targetNodeId: target,
          targetPortId: 'in',
        ),
      );
    }

    // Add some groups for bounds animation demo
    _controller.addNode(
      GroupNode<String>(
        id: 'group-main',
        position: const Offset(80, 80),
        size: const Size(700, 280),
        title: 'Main Pipeline',
        data: '',
        color: Colors.blue.withValues(alpha: 0.1),
        behavior: GroupBehavior.bounds,
        zIndex: -1,
      ),
    );

    _controller.addNode(
      GroupNode<String>(
        id: 'group-outputs',
        position: const Offset(830, 80),
        size: const Size(300, 280),
        title: 'Outputs',
        data: '',
        color: Colors.orange.withValues(alpha: 0.1),
        behavior: GroupBehavior.bounds,
        zIndex: -1,
      ),
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _controller.fitToView();
    });
  }

  Widget _buildNode(BuildContext context, Node<String> node) {
    Color color;
    IconData icon;

    switch (node.type) {
      case 'start':
        color = Colors.green.shade100;
        icon = Icons.play_arrow;
        break;
      case 'process':
        color = Colors.blue.shade100;
        icon = Icons.settings;
        break;
      case 'decision':
        color = Colors.amber.shade100;
        icon = Icons.call_split;
        break;
      case 'output':
        color = Colors.orange.shade100;
        icon = Icons.output;
        break;
      case 'end':
        color = Colors.red.shade100;
        icon = Icons.stop;
        break;
      case 'remote':
      case 'distant':
        color = Colors.purple.shade100;
        icon = Icons.explore;
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
              fontSize: 11,
              fontWeight: FontWeight.w600,
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
      title: 'Viewport Animations',
      width: 340,
      child: NodeFlowEditor<String>(
        controller: _controller,
        nodeBuilder: _buildNode,
        theme: NodeFlowTheme.light,
      ),
      children: [
        _buildAnimationSettings(),
        const SizedBox(height: 24),
        _buildNavigateToNode(),
        const SizedBox(height: 24),
        _buildNavigateToPosition(),
        const SizedBox(height: 24),
        _buildZoomAnimations(),
        const SizedBox(height: 24),
        _buildBoundsAnimations(),
        const SizedBox(height: 24),
        _buildQuickActions(),
      ],
    );
  }

  Widget _buildAnimationSettings() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SectionTitle('Animation Settings'),
        const SizedBox(height: 12),

        // Duration slider
        Row(
          children: [
            const SizedBox(
              width: 80,
              child: Text('Duration', style: TextStyle(fontSize: 12)),
            ),
            Expanded(
              child: Slider(
                value: _duration.inMilliseconds.toDouble(),
                min: 100,
                max: 1500,
                divisions: 14,
                onChanged: (value) {
                  setState(() {
                    _duration = Duration(milliseconds: value.toInt());
                  });
                },
              ),
            ),
            SizedBox(
              width: 50,
              child: Text(
                '${_duration.inMilliseconds}ms',
                style: const TextStyle(fontSize: 11),
                textAlign: TextAlign.right,
              ),
            ),
          ],
        ),

        const SizedBox(height: 8),

        // Curve selector
        Row(
          children: [
            const SizedBox(
              width: 80,
              child: Text('Curve', style: TextStyle(fontSize: 12)),
            ),
            Expanded(
              child: DropdownButton<String>(
                value: _selectedCurveName,
                isExpanded: true,
                style: const TextStyle(fontSize: 12, color: Colors.black87),
                items: _curves.keys.map((name) {
                  return DropdownMenuItem(value: name, child: Text(name));
                }).toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      _selectedCurveName = value;
                      _curve = _curves[value]!;
                    });
                  }
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildNavigateToNode() {
    final nodes = _controller.nodes.values.toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SectionTitle('Navigate to Node'),
        const SizedBox(height: 8),
        Text(
          'Click a node name to animate the viewport to center on it',
          style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: nodes.map((node) {
            return ActionChip(
              label: Text(node.data, style: const TextStyle(fontSize: 11)),
              onPressed: () {
                _controller.animateToNode(
                  node.id,
                  zoom: _targetZoom,
                  duration: _duration,
                  curve: _curve,
                );
              },
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildNavigateToPosition() {
    final positions = [
      ('Origin', const Offset(0, 0)),
      ('Center', const Offset(500, 200)),
      ('Top-Right', const Offset(1200, -100)),
      ('Bottom-Left', const Offset(-200, 400)),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SectionTitle('Navigate to Position'),
        const SizedBox(height: 8),
        Text(
          'Animate to specific canvas coordinates',
          style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: positions.map((entry) {
            final (name, offset) = entry;
            return ActionChip(
              avatar: const Icon(Icons.place, size: 16),
              label: Text(name, style: const TextStyle(fontSize: 11)),
              onPressed: () {
                _controller.animateToPosition(
                  GraphOffset(offset),
                  zoom: _targetZoom,
                  duration: _duration,
                  curve: _curve,
                );
              },
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildZoomAnimations() {
    final zoomLevels = [0.5, 0.75, 1.0, 1.25, 1.5, 2.0];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SectionTitle('Zoom Animations'),
        const SizedBox(height: 8),
        Text(
          'Animate to a specific zoom level (keeps center fixed)',
          style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: zoomLevels.map((zoom) {
            final percentage = (zoom * 100).toInt();
            return ActionChip(
              avatar: Icon(
                zoom > 1.0
                    ? Icons.zoom_in
                    : (zoom < 1.0 ? Icons.zoom_out : Icons.center_focus_strong),
                size: 16,
              ),
              label: Text('$percentage%', style: const TextStyle(fontSize: 11)),
              onPressed: () {
                _controller.animateToScale(
                  zoom,
                  duration: _duration,
                  curve: _curve,
                );
              },
            );
          }).toList(),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            const SizedBox(
              width: 80,
              child: Text('Target Zoom', style: TextStyle(fontSize: 12)),
            ),
            Expanded(
              child: Slider(
                value: _targetZoom,
                min: 0.5,
                max: 2.0,
                divisions: 6,
                label: '${(_targetZoom * 100).toInt()}%',
                onChanged: (value) {
                  setState(() => _targetZoom = value);
                },
              ),
            ),
            SizedBox(
              width: 45,
              child: Text(
                '${(_targetZoom * 100).toInt()}%',
                style: const TextStyle(fontSize: 11),
                textAlign: TextAlign.right,
              ),
            ),
          ],
        ),
        Text(
          'Used for "Navigate to Node" and "Navigate to Position"',
          style: TextStyle(fontSize: 10, color: Colors.grey.shade600),
        ),
      ],
    );
  }

  Widget _buildBoundsAnimations() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SectionTitle('Bounds Animations'),
        const SizedBox(height: 8),
        Text(
          'Animate to fit regions in view',
          style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
        ),
        const SizedBox(height: 12),
        ControlButton(
          icon: Icons.select_all,
          label: 'Fit Selected Nodes',
          onPressed: () {
            final selected = _controller.selectedNodeIds;
            if (selected.isEmpty) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text(
                    'Select some nodes first (click to select, Shift+click for multi-select)',
                  ),
                  duration: Duration(seconds: 2),
                ),
              );
              return;
            }

            // Calculate bounds of selected nodes
            Rect? bounds;
            for (final nodeId in selected) {
              final node = _controller.getNode(nodeId);
              if (node != null) {
                final nodeBounds = node.getBounds();
                bounds = bounds?.expandToInclude(nodeBounds) ?? nodeBounds;
              }
            }

            if (bounds != null) {
              _controller.animateToBounds(
                GraphRect(bounds),
                padding: 50,
                duration: _duration,
                curve: _curve,
              );
            }
          },
        ),
        const SizedBox(height: 8),
        ControlButton(
          icon: Icons.fit_screen,
          label: 'Fit All Content',
          onPressed: () {
            // Get bounds of all nodes
            Rect? bounds;
            for (final node in _controller.nodes.values) {
              final nodeBounds = node.getBounds();
              bounds = bounds?.expandToInclude(nodeBounds) ?? nodeBounds;
            }

            if (bounds != null) {
              _controller.animateToBounds(
                GraphRect(bounds),
                padding: 80,
                duration: _duration,
                curve: _curve,
              );
            }
          },
        ),
        const SizedBox(height: 8),
        ControlButton(
          icon: Icons.crop_free,
          label: 'Animate to Main Pipeline',
          onPressed: () {
            // Animate to the "Main Pipeline" group bounds
            _controller.animateToBounds(
              GraphRect(const Rect.fromLTWH(80, 80, 700, 280)),
              padding: 30,
              duration: _duration,
              curve: _curve,
            );
          },
        ),
        const SizedBox(height: 8),
        ControlButton(
          icon: Icons.crop_square,
          label: 'Animate to Outputs',
          onPressed: () {
            // Animate to the "Outputs" group bounds
            _controller.animateToBounds(
              GraphRect(const Rect.fromLTWH(830, 80, 300, 280)),
              padding: 30,
              duration: _duration,
              curve: _curve,
            );
          },
        ),
      ],
    );
  }

  Widget _buildQuickActions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SectionTitle('Quick Actions'),
        const SizedBox(height: 12),
        Grid2Cols(
          buttons: [
            GridButton(
              icon: Icons.home,
              label: 'Reset View',
              onPressed: () {
                _controller.animateToViewport(
                  const GraphViewport(x: 0, y: 0, zoom: 1.0),
                  duration: _duration,
                  curve: _curve,
                );
              },
            ),
            GridButton(
              icon: Icons.center_focus_strong,
              label: 'Center Origin',
              onPressed: () {
                _controller.animateToPosition(
                  GraphOffset.zero,
                  zoom: 1.0,
                  duration: _duration,
                  curve: _curve,
                );
              },
            ),
            GridButton(
              icon: Icons.zoom_out_map,
              label: 'Fit All',
              onPressed: () {
                // Immediate fit
                _controller.fitToView();
              },
            ),
            GridButton(
              icon: Icons.explore,
              label: 'To Remote',
              onPressed: () {
                _controller.animateToNode(
                  'remote-1',
                  zoom: 1.2,
                  duration: _duration,
                  curve: _curve,
                );
              },
            ),
          ],
        ),
      ],
    );
  }
}
