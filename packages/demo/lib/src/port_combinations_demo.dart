import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:mobx/mobx.dart';
import 'package:vyuh_node_flow/vyuh_node_flow.dart';

class PortCombinationsDemo extends StatefulWidget {
  const PortCombinationsDemo({super.key});

  @override
  State<PortCombinationsDemo> createState() => _PortCombinationsDemoState();
}

class _PortCombinationsDemoState extends State<PortCombinationsDemo> {
  late final NodeFlowController _controller;
  late final ThemeControlStore _themeControl;
  late NodeFlowTheme _currentTheme;
  Timer? _rotationTimer;
  late final List<ReactionDisposer> _disposers;
  bool _isUpdatingTheme = false;

  // Node IDs
  final String sourceNodeId = 'source-node';
  final String targetNodeId = 'target-node';

  @override
  void initState() {
    super.initState();

    _themeControl = ThemeControlStore();
    _currentTheme = NodeFlowTheme.light;
    _controller = NodeFlowController(
      initialViewport: const GraphViewport(x: 0, y: 200, zoom: 1.0),
    );
    _disposers = [];

    _initializeNodes();

    _setupThemeReactions();
    _updateThemeWithValues(); // Initialize theme with current store values
    _updateThemeWithGridValues(); // Initialize grid settings
    _setupAnimation();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Port Combinations Demo'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Row(
        children: [
          // Control Panel
          Container(
            width: 350,
            color: Colors.grey[100],
            child: _buildControlPanel(),
          ),
          // Node Flow Canvas
          Expanded(
            child: NodeFlowEditor(
              controller: _controller,
              theme: _currentTheme,
              nodeBuilder: (context, node) {
                return Container(
                  padding: const EdgeInsets.all(8),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        node.type,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(node.id, style: const TextStyle(fontSize: 10)),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _rotationTimer?.cancel();
    for (final disposer in _disposers) {
      disposer();
    }
    _themeControl.dispose();
    super.dispose();
  }

  void _initializeNodes() {
    // Create source node (center) with all ports
    final sourceNode = Node(
      id: sourceNodeId,
      position: const Offset(400, 100),
      size: const Size(100, 100),
      inputPorts: [
        Port(
          id: 'source-left',
          position: PortPosition.left,
          name: 'Left',

          offset: const Offset(0, 50),
        ),
        Port(
          id: 'source-top',
          position: PortPosition.top,
          name: 'Top',

          offset: const Offset(50, 0),
        ),
        Port(
          id: 'source-right',
          position: PortPosition.right,
          name: 'Right',

          offset: const Offset(0, 50),
        ),
        Port(
          id: 'source-bottom',
          position: PortPosition.bottom,
          name: 'Bottom',

          offset: const Offset(50, 0),
        ),
      ],
      type: 'Source',
      data: null,
    );

    // Create target node with all ports
    final targetNode = Node(
      id: targetNodeId,
      type: 'Target',
      position: const Offset(700, 300),
      size: const Size(100, 100),
      outputPorts: [
        Port(
          id: 'target-left',
          position: PortPosition.left,
          name: 'Left',

          offset: const Offset(0, 50),
        ),
        Port(
          id: 'target-top',
          position: PortPosition.top,
          name: 'Top',

          offset: const Offset(50, 0),
        ),
        Port(
          id: 'target-right',
          position: PortPosition.right,
          name: 'Right',

          offset: const Offset(0, 50),
        ),
        Port(
          id: 'target-bottom',
          position: PortPosition.bottom,
          name: 'Bottom',

          offset: const Offset(50, 0),
        ),
      ],
      data: null,
    );

    _controller.addNode(sourceNode);
    _controller.addNode(targetNode);

    // Create initial connection
    _updateConnection();
  }

  void _setupThemeReactions() {
    // React to connection theme property changes
    _disposers.add(
      reaction(
        (_) => [
          _themeControl._connectionStyle.value,
          _themeControl._offset.value,
          _themeControl._cornerRadius.value,
          _themeControl._strokeWidth.value,
          _themeControl._curvature.value,
          _themeControl._connectionColor.value,
          _themeControl._useDashedLine.value,
        ],
        (_) => _updateThemeWithValues(),
      ),
    );

    // React to port selection changes
    _disposers.add(
      reaction(
        (_) => [
          _themeControl._selectedSourcePort.value,
          _themeControl._selectedTargetPort.value,
        ],
        (_) => _updateConnection(),
      ),
    );

    // React to animation changes
    _disposers.add(
      reaction((_) => _themeControl._isRotating.value, _handleAnimationToggle),
    );

    // React to grid style changes
    _disposers.add(
      reaction(
        (_) => [
          _themeControl._gridStyle.value,
          _themeControl._snapToGrid.value,
          _themeControl._gridSize.value,
        ],
        (_) => _updateThemeWithGridValues(),
      ),
    );
  }

  void _updateThemeWithValues() {
    if (_isUpdatingTheme) return;
    _isUpdatingTheme = true;

    try {
      final currentTheme = _currentTheme;
      final useDashed = _themeControl._useDashedLine.value;

      final newConnectionTheme = currentTheme.connectionTheme.copyWith(
        color: _themeControl._connectionColor.value,
        strokeWidth: _themeControl._strokeWidth.value,
        cornerRadius: _themeControl._cornerRadius.value,
        bezierCurvature: _themeControl._curvature.value,
        dashPattern: useDashed ? [5, 5] : null,
      );

      final newTheme = currentTheme.copyWith(
        connectionStyle: _themeControl._connectionStyle.value,
        connectionTheme: newConnectionTheme,
      );

      setState(() {
        _currentTheme = newTheme;
      });
    } finally {
      _isUpdatingTheme = false;
    }
  }

  void _updateThemeWithGridValues() {
    final currentTheme = _currentTheme;
    final newTheme = currentTheme.copyWith(
      gridStyle: _themeControl._gridStyle.value,
      gridSize: _themeControl._gridSize.value,
    );

    setState(() {
      _currentTheme = newTheme;
    });
  }

  void _handleAnimationToggle(bool isRotating) {
    if (isRotating) {
      _startAnimation();
    } else {
      _stopAnimation();
    }
  }

  void _startAnimation() {
    _stopAnimation(); // Stop any existing animation
    _rotationTimer = Timer.periodic(const Duration(milliseconds: 50), (timer) {
      _updateTargetNodePosition();
    });
  }

  void _stopAnimation() {
    _rotationTimer?.cancel();
    _rotationTimer = null;
  }

  void _setupAnimation() {
    if (_themeControl._isRotating.value) {
      _startAnimation();
    }
  }

  void _updateTargetNodePosition() {
    if (!_themeControl._isRotating.value) return;

    final now = DateTime.now().millisecondsSinceEpoch / 1000.0;
    final angle = (now * _themeControl._rotationSpeed.value) % (2 * math.pi);

    // Source node center (position + half size)
    final sourceNode = _controller.nodes[sourceNodeId]!;
    final centerX = sourceNode.position.value.dx + sourceNode.size.width / 2;
    final centerY = sourceNode.position.value.dy + sourceNode.size.height / 2;
    final radius = _themeControl._orbitRadius.value;

    // Calculate new position for target node (subtract half size to center it)
    final targetNode = _controller.nodes[targetNodeId]!;
    final newX = centerX + radius * math.cos(angle) - targetNode.size.width / 2;
    final newY =
        centerY + radius * math.sin(angle) - targetNode.size.height / 2;

    // Update only position - visualPosition is computed automatically
    final newPosition = Offset(newX, newY);
    _controller.setNodePosition(targetNodeId, newPosition);
  }

  void _updateConnection() {
    // Remove existing connections
    final connectionsToRemove = _controller.connections.toList();
    for (final conn in connectionsToRemove) {
      _controller.removeConnection(conn.id);
    }

    // Create new connection based on selected ports
    final sourcePortId = _getPortId('source', _themeControl.selectedSourcePort);
    final targetPortId = _getPortId('target', _themeControl.selectedTargetPort);

    _controller.addConnection(
      Connection(
        id: 'demo-connection',
        sourceNodeId: sourceNodeId,
        sourcePortId: sourcePortId,
        targetNodeId: targetNodeId,
        targetPortId: targetPortId,
        label:
            '${_themeControl.selectedSourcePort.name} → ${_themeControl.selectedTargetPort.name}',
      ),
    );
  }

  String _getPortId(String prefix, PortPosition position) {
    return '$prefix-${position.name}';
  }

  Widget _buildControlPanel() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: 16,
        children: [
          Text(
            'Port Combinations',
            style: Theme.of(context).textTheme.headlineSmall,
          ),

          // Port Selection Section
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                spacing: 16,
                children: [
                  const Text(
                    'Port Selection',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),

                  // Source Port
                  const Text('Source Port:'),
                  Observer(
                    builder: (context) => Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: PortPosition.values
                          .map(
                            (port) => ChoiceChip(
                              label: Text(port.name.toUpperCase()),
                              selected:
                                  _themeControl._selectedSourcePort.value ==
                                  port,
                              onSelected: (selected) {
                                if (selected) {
                                  _themeControl.selectedSourcePort = port;
                                }
                              },
                            ),
                          )
                          .toList(),
                    ),
                  ),

                  // Target Port
                  const Text('Target Port:'),
                  Observer(
                    builder: (context) => Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: PortPosition.values
                          .map(
                            (port) => ChoiceChip(
                              label: Text(port.name.toUpperCase()),
                              selected:
                                  _themeControl._selectedTargetPort.value ==
                                  port,
                              onSelected: (selected) {
                                if (selected) {
                                  _themeControl.selectedTargetPort = port;
                                }
                              },
                            ),
                          )
                          .toList(),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Animation Section
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                spacing: 16,
                children: [
                  const Text(
                    'Animation',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),

                  // Rotation Toggle
                  Observer(
                    builder: (context) => SwitchListTile(
                      title: const Text('Orbit Target Node'),
                      subtitle: const Text(
                        'Target node orbits around source node',
                      ),
                      value: _themeControl._isRotating.value,
                      onChanged: (value) {
                        _themeControl.isRotating = value;
                      },
                    ),
                  ),

                  // Rotation Speed
                  Observer(
                    builder: (context) => Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Orbit Speed: ${_themeControl._rotationSpeed.value.toStringAsFixed(2)}',
                        ),
                        Slider(
                          value: _themeControl._rotationSpeed.value,
                          min: 0.1,
                          max: 2.0,
                          divisions: 19,
                          label: _themeControl._rotationSpeed.value
                              .toStringAsFixed(2),
                          onChanged: (value) {
                            _themeControl.rotationSpeed = value;
                          },
                        ),
                      ],
                    ),
                  ),

                  // Orbit Radius
                  Observer(
                    builder: (context) => Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Orbit Radius: ${_themeControl._orbitRadius.value.toStringAsFixed(0)}',
                        ),
                        Slider(
                          value: _themeControl._orbitRadius.value,
                          min: 50,
                          max: 400,
                          divisions: 35,
                          label: _themeControl._orbitRadius.value
                              .toStringAsFixed(0),
                          onChanged: (value) {
                            _themeControl.orbitRadius = value;
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Connection Style Section
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                spacing: 16,
                children: [
                  const Text(
                    'Connection Style',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),

                  // Connection Style Dropdown
                  Observer(
                    builder: (context) =>
                        DropdownButtonFormField<ConnectionStyle>(
                          decoration: const InputDecoration(
                            labelText: 'Style',
                            border: OutlineInputBorder(),
                          ),
                          initialValue: _themeControl._connectionStyle.value,
                          items: ConnectionStyles.all.map((style) {
                            return DropdownMenuItem(
                              value: style,
                              child: Text(style.displayName),
                            );
                          }).toList(),
                          onChanged: (value) {
                            if (value != null) {
                              _themeControl.connectionStyle = value;
                            }
                          },
                        ),
                  ),

                  // Offset Slider
                  Observer(
                    builder: (context) => Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Offset: ${_themeControl._offset.value.toStringAsFixed(1)}',
                        ),
                        Slider(
                          value: _themeControl._offset.value,
                          min: 5,
                          max: 50,
                          divisions: 45,
                          label: _themeControl._offset.value.toStringAsFixed(1),
                          onChanged: (value) {
                            _themeControl.offset = value;
                          },
                        ),
                      ],
                    ),
                  ),

                  // Corner Radius Slider
                  Observer(
                    builder: (context) => Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Corner Radius: ${_themeControl._cornerRadius.value.toStringAsFixed(1)}',
                        ),
                        Slider(
                          value: _themeControl._cornerRadius.value,
                          min: 0,
                          max: 20,
                          divisions: 20,
                          label: _themeControl._cornerRadius.value
                              .toStringAsFixed(1),
                          onChanged: (value) {
                            _themeControl.cornerRadius = value;
                          },
                        ),
                      ],
                    ),
                  ),

                  // Stroke Width Slider
                  Observer(
                    builder: (context) => Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Stroke Width: ${_themeControl._strokeWidth.value.toStringAsFixed(1)}',
                        ),
                        Slider(
                          value: _themeControl._strokeWidth.value,
                          min: 1,
                          max: 10,
                          divisions: 18,
                          label: _themeControl._strokeWidth.value
                              .toStringAsFixed(1),
                          onChanged: (value) {
                            _themeControl.strokeWidth = value;
                          },
                        ),
                      ],
                    ),
                  ),

                  // Curvature Slider (for Bezier style)
                  Observer(
                    builder: (context) =>
                        _themeControl._connectionStyle.value ==
                                ConnectionStyles.bezier ||
                            _themeControl._connectionStyle.value ==
                                ConnectionStyles.customBezier
                        ? Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Curvature: ${_themeControl._curvature.value.toStringAsFixed(2)}',
                              ),
                              Slider(
                                value: _themeControl._curvature.value,
                                min: 0.0,
                                max: 1.0,
                                divisions: 20,
                                label: _themeControl._curvature.value
                                    .toStringAsFixed(2),
                                onChanged: (value) {
                                  _themeControl.curvature = value;
                                },
                              ),
                            ],
                          )
                        : const SizedBox.shrink(),
                  ),

                  // Connection Color
                  Observer(
                    builder: (context) => ListTile(
                      title: const Text('Connection Color'),
                      trailing: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: _themeControl._connectionColor.value,
                          border: Border.all(color: Colors.grey),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      onTap: _showColorPicker,
                    ),
                  ),

                  // Dashed Line Toggle
                  Observer(
                    builder: (context) => SwitchListTile(
                      title: const Text('Dashed Line'),
                      value: _themeControl._useDashedLine.value,
                      onChanged: (value) {
                        _themeControl.useDashedLine = value;
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Grid Style Section
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                spacing: 16,
                children: [
                  const Text(
                    'Grid Settings',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),

                  // Grid Style Dropdown
                  Observer(
                    builder: (context) => DropdownButtonFormField<GridStyle>(
                      decoration: const InputDecoration(
                        labelText: 'Grid Style',
                        border: OutlineInputBorder(),
                      ),
                      initialValue: _themeControl._gridStyle.value,
                      items: GridStyle.values.map((style) {
                        return DropdownMenuItem(
                          value: style,
                          child: Text(style.name),
                        );
                      }).toList(),
                      onChanged: (value) {
                        if (value != null) {
                          _themeControl.gridStyle = value;
                        }
                      },
                    ),
                  ),

                  // Grid Size Slider
                  Observer(
                    builder: (context) => Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Grid Size: ${_themeControl._gridSize.value.toStringAsFixed(0)}px',
                        ),
                        Slider(
                          value: _themeControl._gridSize.value,
                          min: 5,
                          max: 50,
                          divisions: 45,
                          label: _themeControl._gridSize.value.toStringAsFixed(
                            0,
                          ),
                          onChanged: (value) {
                            _themeControl.gridSize = value;
                          },
                        ),
                      ],
                    ),
                  ),

                  // Snap to Grid Toggle
                  Observer(
                    builder: (context) => SwitchListTile(
                      title: const Text('Snap to Grid'),
                      subtitle: const Text(
                        'Align nodes to grid points when moving',
                      ),
                      value: _themeControl._snapToGrid.value,
                      onChanged: (value) {
                        _themeControl.snapToGrid = value;
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showColorPicker() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select Connection Color'),
        content: Observer(
          builder: (context) => Wrap(
            spacing: 8,
            runSpacing: 8,
            children:
                [
                      Colors.blue,
                      Colors.red,
                      Colors.green,
                      Colors.purple,
                      Colors.orange,
                      Colors.teal,
                      Colors.pink,
                      Colors.indigo,
                      Colors.brown,
                      Colors.grey,
                    ]
                    .map(
                      (color) => InkWell(
                        onTap: () {
                          _themeControl.connectionColor = color;
                          Navigator.of(context).pop();
                        },
                        child: Container(
                          width: 50,
                          height: 50,
                          decoration: BoxDecoration(
                            color: color,
                            border: Border.all(
                              color:
                                  _themeControl._connectionColor.value == color
                                  ? Colors.black
                                  : Colors.transparent,
                              width: 3,
                            ),
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      ),
                    )
                    .toList(),
          ),
        ),
      ),
    );
  }
}

// Store for theme control state
class ThemeControlStore {
  final Observable<PortPosition> _selectedSourcePort = Observable(
    PortPosition.right,
  );

  PortPosition get selectedSourcePort => _selectedSourcePort.value;

  set selectedSourcePort(PortPosition value) =>
      runInAction(() => _selectedSourcePort.value = value);

  final Observable<PortPosition> _selectedTargetPort = Observable(
    PortPosition.left,
  );

  PortPosition get selectedTargetPort => _selectedTargetPort.value;

  set selectedTargetPort(PortPosition value) =>
      runInAction(() => _selectedTargetPort.value = value);

  final Observable<ConnectionStyle> _connectionStyle = Observable(
    ConnectionStyles.smoothstep,
  );

  ConnectionStyle get connectionStyle => _connectionStyle.value;

  set connectionStyle(ConnectionStyle value) =>
      runInAction(() => _connectionStyle.value = value);

  final Observable<double> _offset = Observable(20.0);

  double get offset => _offset.value;

  set offset(double value) => runInAction(() => _offset.value = value);

  final Observable<double> _cornerRadius = Observable(8.0);

  double get cornerRadius => _cornerRadius.value;

  set cornerRadius(double value) =>
      runInAction(() => _cornerRadius.value = value);

  final Observable<double> _strokeWidth = Observable(2.0);

  double get strokeWidth => _strokeWidth.value;

  set strokeWidth(double value) =>
      runInAction(() => _strokeWidth.value = value);

  final Observable<double> _curvature = Observable(0.25);

  double get curvature => _curvature.value;

  set curvature(double value) => runInAction(() => _curvature.value = value);

  final Observable<Color> _connectionColor = Observable(Colors.blue);

  Color get connectionColor => _connectionColor.value;

  set connectionColor(Color value) =>
      runInAction(() => _connectionColor.value = value);

  final Observable<bool> _useDashedLine = Observable(false);

  bool get useDashedLine => _useDashedLine.value;

  set useDashedLine(bool value) =>
      runInAction(() => _useDashedLine.value = value);

  final Observable<bool> _isRotating = Observable(true);

  bool get isRotating => _isRotating.value;

  set isRotating(bool value) => runInAction(() => _isRotating.value = value);

  final Observable<double> _rotationSpeed = Observable(2.0);

  double get rotationSpeed => _rotationSpeed.value;

  set rotationSpeed(double value) =>
      runInAction(() => _rotationSpeed.value = value);

  final Observable<GridStyle> _gridStyle = Observable(GridStyle.dots);

  GridStyle get gridStyle => _gridStyle.value;

  set gridStyle(GridStyle value) => runInAction(() => _gridStyle.value = value);

  final Observable<bool> _snapToGrid = Observable(false);

  bool get snapToGrid => _snapToGrid.value;

  set snapToGrid(bool value) => runInAction(() => _snapToGrid.value = value);

  final Observable<double> _snapThreshold = Observable(10.0);

  double get snapThreshold => _snapThreshold.value;

  set snapThreshold(double value) =>
      runInAction(() => _snapThreshold.value = value);

  final Observable<double> _gridSize = Observable(20.0);

  double get gridSize => _gridSize.value;

  set gridSize(double value) => runInAction(() => _gridSize.value = value);

  final Observable<double> _orbitRadius = Observable(200.0);

  double get orbitRadius => _orbitRadius.value;

  set orbitRadius(double value) =>
      runInAction(() => _orbitRadius.value = value);

  void dispose() {
    // Cleanup if needed
  }
}
