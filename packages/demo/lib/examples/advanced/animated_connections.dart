import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:mobx/mobx.dart';
import 'package:vyuh_node_flow/connections/animation/animation_effects.dart';
import 'package:vyuh_node_flow/vyuh_node_flow.dart';

import '../../shared/ui_widgets.dart';

// Gradient color presets
const Map<String, List<Color>> gradientPresets = {
  'red_white': [Colors.red, Colors.white, Colors.red],
  'purple_white': [Colors.purple, Colors.white, Colors.purple],
  'indigo_white': [Colors.indigo, Colors.white, Colors.indigo],
  'orange_yellow': [Colors.orange, Colors.yellow, Colors.orange],
};

// MobX Store for animation demo state
class AnimationDemoStore {
  AnimationDemoStore() {
    // Auto-apply effect when parameters change
    reaction(
      (_) => [
        selectedEffectType,
        speed,
        dashLength,
        gapLength,
        particleCount,
        particleSize,
        gradientLength,
        connectionOpacity,
        selectedGradientPreset,
        minOpacity,
        maxOpacity,
        widthVariation,
      ],
      (_) => applyAnimationEffect(),
    );
  }

  final Observable<Connection?> _selectedConnection = Observable(null);

  Connection? get selectedConnection => _selectedConnection.value;

  set selectedConnection(Connection? value) =>
      runInAction(() => _selectedConnection.value = value);

  final Observable<String> _selectedEffectType = Observable('none');

  String get selectedEffectType => _selectedEffectType.value;

  set selectedEffectType(String value) =>
      runInAction(() => _selectedEffectType.value = value);

  final Observable<int> _speed = Observable(1);

  int get speed => _speed.value;

  set speed(int value) => runInAction(() => _speed.value = value);

  final Observable<int> _dashLength = Observable(10);

  int get dashLength => _dashLength.value;

  set dashLength(int value) => runInAction(() => _dashLength.value = value);

  final Observable<int> _gapLength = Observable(5);

  int get gapLength => _gapLength.value;

  set gapLength(int value) => runInAction(() => _gapLength.value = value);

  final Observable<int> _particleCount = Observable(3);

  int get particleCount => _particleCount.value;

  set particleCount(int value) =>
      runInAction(() => _particleCount.value = value);

  final Observable<int> _particleSize = Observable(3);

  int get particleSize => _particleSize.value;

  set particleSize(int value) => runInAction(() => _particleSize.value = value);

  final Observable<double> _minOpacity = Observable(0.4);

  double get minOpacity => _minOpacity.value;

  set minOpacity(double value) => runInAction(() => _minOpacity.value = value);

  final Observable<double> _maxOpacity = Observable(1.0);

  double get maxOpacity => _maxOpacity.value;

  set maxOpacity(double value) => runInAction(() => _maxOpacity.value = value);

  final Observable<double> _widthVariation = Observable(1.0);

  double get widthVariation => _widthVariation.value;

  set widthVariation(double value) =>
      runInAction(() => _widthVariation.value = value);

  final Observable<double> _gradientLength = Observable(0.25);

  double get gradientLength => _gradientLength.value;

  set gradientLength(double value) =>
      runInAction(() => _gradientLength.value = value);

  final Observable<double> _connectionOpacity = Observable(1.0);

  double get connectionOpacity => _connectionOpacity.value;

  set connectionOpacity(double value) =>
      runInAction(() => _connectionOpacity.value = value);

  final Observable<String> _selectedGradientPreset = Observable('red_white');

  String get selectedGradientPreset => _selectedGradientPreset.value;

  set selectedGradientPreset(String value) =>
      runInAction(() => _selectedGradientPreset.value = value);

  final Observable<double> _strokeWidth = Observable(2.0);

  double get strokeWidth => _strokeWidth.value;

  set strokeWidth(double value) =>
      runInAction(() => _strokeWidth.value = value);

  void applyAnimationEffect() {
    if (selectedConnection == null) return;

    ConnectionAnimationEffect? effect;

    switch (selectedEffectType) {
      case 'flowing_dash':
        effect = FlowingDashEffect(
          speed: speed,
          dashLength: dashLength,
          gapLength: gapLength,
        );
        break;
      case 'particle':
        effect = ParticleEffect(
          particleCount: particleCount,
          particleSize: particleSize,
          speed: speed,
        );
        break;
      case 'gradient':
        effect = GradientFlowEffect(
          colors: gradientPresets[selectedGradientPreset],
          speed: speed,
          gradientLength: gradientLength,
          connectionOpacity: connectionOpacity,
        );
        break;
      case 'pulse':
        effect = PulseEffect(
          pulseSpeed: speed,
          minOpacity: minOpacity,
          maxOpacity: maxOpacity,
          widthVariation: widthVariation,
        );
        break;
      case 'none':
        effect = null;
        break;
    }

    runInAction(() {
      selectedConnection!.animationEffect = effect;
    });
  }
}

class AnimatedConnectionsExample extends StatefulWidget {
  const AnimatedConnectionsExample({super.key});

  @override
  State<AnimatedConnectionsExample> createState() =>
      _AnimatedConnectionsExampleState();
}

class _AnimatedConnectionsExampleState
    extends State<AnimatedConnectionsExample> {
  late final NodeFlowController<Map<String, dynamic>> _controller;
  late final AnimationDemoStore _store;

  @override
  void initState() {
    super.initState();
    _store = AnimationDemoStore();
    _controller = NodeFlowController<Map<String, dynamic>>(
      config: NodeFlowConfig(),
    );
    _createExampleGraph();

    WidgetsBinding.instance.addPostFrameCallback(
      (_) => _controller.fitToView(),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _createExampleGraph() {
    // Create a sample graph with multiple connections to demonstrate animation effects
    // Layout: Data Source (left) -> 3 Processors (middle) -> Data Sync (right)
    final node1 = Node<Map<String, dynamic>>(
      id: 'node1',
      type: 'source',
      position: const Offset(50, 150),
      size: const Size(150, 140),
      data: {'label': 'Data Source'},
      outputPorts: const [
        Port(
          id: 'out1',
          name: 'Stream A',
          position: PortPosition.right,
          offset: Offset(0, 35),
        ),
        Port(
          id: 'out2',
          name: 'Stream B',
          position: PortPosition.right,
          offset: Offset(0, 70),
        ),
        Port(
          id: 'out3',
          name: 'Stream C',
          position: PortPosition.right,
          offset: Offset(0, 105),
        ),
      ],
    );

    final node2 = Node<Map<String, dynamic>>(
      id: 'node2',
      type: 'processor',
      position: const Offset(350, 0),
      size: const Size(150, 80),
      data: {'label': 'Processor 1'},
      inputPorts: const [
        Port(
          id: 'in1',
          name: 'Input',
          position: PortPosition.left,
          offset: Offset(0, 40),
        ),
      ],
      outputPorts: const [
        Port(
          id: 'out1',
          name: 'Output',
          position: PortPosition.right,
          offset: Offset(0, 40),
        ),
      ],
    );

    final node3 = Node<Map<String, dynamic>>(
      id: 'node3',
      type: 'processor',
      position: const Offset(350, 180),
      size: const Size(150, 80),
      data: {'label': 'Processor 2'},
      inputPorts: const [
        Port(
          id: 'in1',
          name: 'Input',
          position: PortPosition.left,
          offset: Offset(0, 40),
        ),
      ],
      outputPorts: const [
        Port(
          id: 'out1',
          name: 'Output',
          position: PortPosition.right,
          offset: Offset(0, 40),
        ),
      ],
    );

    final node4 = Node<Map<String, dynamic>>(
      id: 'node4',
      type: 'processor',
      position: const Offset(350, 360),
      size: const Size(150, 80),
      data: {'label': 'Processor 3'},
      inputPorts: const [
        Port(
          id: 'in1',
          name: 'Input',
          position: PortPosition.left,
          offset: Offset(0, 40),
        ),
      ],
      outputPorts: const [
        Port(
          id: 'out1',
          name: 'Output',
          position: PortPosition.right,
          offset: Offset(0, 40),
        ),
      ],
    );

    final node5 = Node<Map<String, dynamic>>(
      id: 'node5',
      type: 'sync',
      position: const Offset(650, 150),
      size: const Size(150, 140),
      data: {'label': 'Data Sync'},
      inputPorts: const [
        Port(
          id: 'in1',
          name: 'Input 1',
          position: PortPosition.left,
          offset: Offset(0, 35),
        ),
        Port(
          id: 'in2',
          name: 'Input 2',
          position: PortPosition.left,
          offset: Offset(0, 70),
        ),
        Port(
          id: 'in3',
          name: 'Input 3',
          position: PortPosition.left,
          offset: Offset(0, 105),
        ),
      ],
    );

    _controller.addNode(node1);
    _controller.addNode(node2);
    _controller.addNode(node3);
    _controller.addNode(node4);
    _controller.addNode(node5);

    // Create connections with different default effects
    final conn1 = Connection(
      id: 'conn1',
      sourceNodeId: 'node1',
      sourcePortId: 'out1',
      targetNodeId: 'node2',
      targetPortId: 'in1',
      animationEffect: FlowingDashEffect(
        speed: 2,
        dashLength: 12,
        gapLength: 6,
      ),
    );

    final conn2 = Connection(
      id: 'conn2',
      sourceNodeId: 'node1',
      sourcePortId: 'out2',
      targetNodeId: 'node3',
      targetPortId: 'in1',
      animationEffect: ParticleEffect(
        particleCount: 4,
        particleSize: 4,
        speed: 1,
      ),
    );

    final conn3 = Connection(
      id: 'conn3',
      sourceNodeId: 'node1',
      sourcePortId: 'out3',
      targetNodeId: 'node4',
      targetPortId: 'in1',
      animationEffect: GradientFlowEffect(
        colors: gradientPresets['red_white'],
        speed: 1,
      ),
    );

    final conn4 = Connection(
      id: 'conn4',
      sourceNodeId: 'node2',
      sourcePortId: 'out1',
      targetNodeId: 'node5',
      targetPortId: 'in1',
      animationEffect: PulseEffect(
        pulseSpeed: 1,
        minOpacity: 0.3,
        maxOpacity: 1.0,
        widthVariation: 1.5,
      ),
    );

    final conn5 = Connection(
      id: 'conn5',
      sourceNodeId: 'node3',
      sourcePortId: 'out1',
      targetNodeId: 'node5',
      targetPortId: 'in2',
      // No animation effect - static connection
    );

    final conn6 = Connection(
      id: 'conn6',
      sourceNodeId: 'node4',
      sourcePortId: 'out1',
      targetNodeId: 'node5',
      targetPortId: 'in3',
      // No animation effect - static connection
    );

    _controller.addConnection(conn1);
    _controller.addConnection(conn2);
    _controller.addConnection(conn3);
    _controller.addConnection(conn4);
    _controller.addConnection(conn5);
    _controller.addConnection(conn6);
  }

  Widget _buildNode(BuildContext context, Node<Map<String, dynamic>> node) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Center(
        child: Text(
          node.data['label'] ?? node.id,
          style: Theme.of(context).textTheme.bodyMedium,
          textAlign: TextAlign.center,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ResponsiveControlPanel(
      title: 'Animation Controls',
      width: 320,
      actions: [
        IconButton(
          icon: const Icon(Icons.refresh, size: 20),
          onPressed: () {
            _controller.clearGraph();
            _store.selectedConnection = null;
            _createExampleGraph();
          },
          tooltip: 'Reset Graph',
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(),
        ),
      ],
      child: Observer(
        builder: (context) => NodeFlowEditor<Map<String, dynamic>>(
          controller: _controller,
          nodeBuilder: _buildNode,
          theme: NodeFlowTheme.light.copyWith(
            connectionTheme: NodeFlowTheme.light.connectionTheme.copyWith(
              strokeWidth: _store.strokeWidth,
              selectedStrokeWidth: _store.strokeWidth,
            ),
          ),
          onConnectionSelected: (connection) {
            _store.selectedConnection = connection;
            if (connection != null) {
              // Update UI based on current effect
              final effect = connection.animationEffect;
              if (effect is FlowingDashEffect) {
                _store.selectedEffectType = 'flowing_dash';
                _store.speed = effect.speed;
                _store.dashLength = effect.dashLength;
                _store.gapLength = effect.gapLength;
              } else if (effect is ParticleEffect) {
                _store.selectedEffectType = 'particle';
                _store.speed = effect.speed;
                _store.particleCount = effect.particleCount;
                _store.particleSize = effect.particleSize;
              } else if (effect is GradientFlowEffect) {
                _store.selectedEffectType = 'gradient';
                _store.speed = effect.speed;
                _store.gradientLength = effect.gradientLength;
              } else if (effect is PulseEffect) {
                _store.selectedEffectType = 'pulse';
                _store.speed = effect.pulseSpeed;
                _store.minOpacity = effect.minOpacity;
                _store.maxOpacity = effect.maxOpacity;
                _store.widthVariation = effect.widthVariation;
              } else {
                _store.selectedEffectType = 'none';
              }
            }
          },
        ),
      ),
      children: [
        // Connection appearance section (always visible)
        const SectionTitle('Connection Appearance'),
        const SizedBox(height: 12),
        Observer(
          builder: (context) => SliderControl(
            label: 'Stroke Width',
            value: _store.strokeWidth,
            min: 1.0,
            max: 10.0,
            onChanged: (value) => _store.strokeWidth = value,
          ),
        ),
        const SizedBox(height: 16),
        Observer(
          builder: (context) => _store.selectedConnection == null
              ? const Card(
                  child: Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Text(
                      'Click on a connection to select it and apply animation effects.',
                      style: TextStyle(fontSize: 12),
                    ),
                  ),
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            const Text(
                              'Selected Connection',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Builder(
                              builder: (context) {
                                final conn = _store.selectedConnection!;
                                final sourceNode =
                                    _controller.nodes[conn.sourceNodeId];
                                final targetNode =
                                    _controller.nodes[conn.targetNodeId];
                                final sourceName =
                                    sourceNode?.data['label'] ??
                                    conn.sourceNodeId;
                                final targetName =
                                    targetNode?.data['label'] ??
                                    conn.targetNodeId;

                                return RichText(
                                  text: TextSpan(
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.onSurface,
                                    ),
                                    children: [
                                      TextSpan(text: sourceName),
                                      TextSpan(
                                        text: ' (${conn.sourcePortId})',
                                        style: TextStyle(
                                          fontSize: 10,
                                          color: Theme.of(
                                            context,
                                          ).colorScheme.onSurfaceVariant,
                                        ),
                                      ),
                                      const TextSpan(text: ' → '),
                                      TextSpan(text: targetName),
                                      TextSpan(
                                        text: ' (${conn.targetPortId})',
                                        style: TextStyle(
                                          fontSize: 10,
                                          color: Theme.of(
                                            context,
                                          ).colorScheme.onSurfaceVariant,
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Animation effect selector (no section title)
                    EffectTypeSelector(
                      selectedEffectType: _store.selectedEffectType,
                      onChanged: (value) {
                        if (value != null) {
                          _store.selectedEffectType = value;
                        }
                      },
                    ),
                    const SizedBox(height: 16),
                    if (_store.selectedEffectType != 'none') ...[
                      EffectControlsPanel(
                        effectType: _store.selectedEffectType,
                        speed: _store.speed.toDouble(),
                        dashLength: _store.dashLength.toDouble(),
                        gapLength: _store.gapLength.toDouble(),
                        particleCount: _store.particleCount,
                        particleSize: _store.particleSize.toDouble(),
                        gradientLength: _store.gradientLength,
                        connectionOpacity: _store.connectionOpacity,
                        selectedGradientPreset: _store.selectedGradientPreset,
                        minOpacity: _store.minOpacity,
                        maxOpacity: _store.maxOpacity,
                        widthVariation: _store.widthVariation,
                        onSpeedChanged: (value) => _store.speed = value.round(),
                        onDashLengthChanged: (value) =>
                            _store.dashLength = value.round(),
                        onGapLengthChanged: (value) =>
                            _store.gapLength = value.round(),
                        onParticleCountChanged: (value) =>
                            _store.particleCount = value,
                        onParticleSizeChanged: (value) =>
                            _store.particleSize = value.round(),
                        onGradientLengthChanged: (value) =>
                            _store.gradientLength = value,
                        onConnectionOpacityChanged: (value) =>
                            _store.connectionOpacity = value,
                        onGradientPresetChanged: (value) =>
                            _store.selectedGradientPreset = value,
                        onMinOpacityChanged: (value) =>
                            _store.minOpacity = value,
                        onMaxOpacityChanged: (value) =>
                            _store.maxOpacity = value,
                        onWidthVariationChanged: (value) =>
                            _store.widthVariation = value,
                      ),
                    ],
                  ],
                ),
        ),
      ],
    );
  }
}

// Semantic Widgets for better performance

class SliderControl extends StatelessWidget {
  const SliderControl({
    super.key,
    required this.label,
    required this.value,
    required this.min,
    required this.max,
    required this.onChanged,
    this.divisions,
  });

  final String label;
  final double value;
  final double min;
  final double max;
  final ValueChanged<double> onChanged;
  final int? divisions;

  @override
  Widget build(BuildContext context) {
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
            divisions: divisions,
            label: value.toStringAsFixed(1),
            onChanged: onChanged,
          ),
        ),
        SizedBox(
          width: 40,
          child: Text(
            value.toStringAsFixed(divisions != null ? 0 : 1),
            style: const TextStyle(fontSize: 11),
            textAlign: TextAlign.right,
          ),
        ),
      ],
    );
  }
}

class EffectTypeSelector extends StatelessWidget {
  const EffectTypeSelector({
    super.key,
    required this.selectedEffectType,
    required this.onChanged,
  });

  final String selectedEffectType;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    return DropdownButton<String>(
      value: selectedEffectType,
      isExpanded: true,
      items: const [
        DropdownMenuItem(value: 'none', child: Text('None (Static)')),
        DropdownMenuItem(value: 'flowing_dash', child: Text('Flowing Dashes')),
        DropdownMenuItem(value: 'particle', child: Text('Particles')),
        DropdownMenuItem(value: 'gradient', child: Text('Gradient Flow')),
        DropdownMenuItem(value: 'pulse', child: Text('Pulse/Glow')),
      ],
      onChanged: onChanged,
    );
  }
}

class EffectControlsPanel extends StatelessWidget {
  const EffectControlsPanel({
    super.key,
    required this.effectType,
    required this.speed,
    required this.dashLength,
    required this.gapLength,
    required this.particleCount,
    required this.particleSize,
    required this.gradientLength,
    required this.connectionOpacity,
    required this.selectedGradientPreset,
    required this.minOpacity,
    required this.maxOpacity,
    required this.widthVariation,
    required this.onSpeedChanged,
    required this.onDashLengthChanged,
    required this.onGapLengthChanged,
    required this.onParticleCountChanged,
    required this.onParticleSizeChanged,
    required this.onGradientLengthChanged,
    required this.onConnectionOpacityChanged,
    required this.onGradientPresetChanged,
    required this.onMinOpacityChanged,
    required this.onMaxOpacityChanged,
    required this.onWidthVariationChanged,
  });

  final String effectType;
  final double speed;
  final double dashLength;
  final double gapLength;
  final int particleCount;
  final double particleSize;
  final double gradientLength;
  final double connectionOpacity;
  final String selectedGradientPreset;
  final double minOpacity;
  final double maxOpacity;
  final double widthVariation;
  final ValueChanged<double> onSpeedChanged;
  final ValueChanged<double> onDashLengthChanged;
  final ValueChanged<double> onGapLengthChanged;
  final ValueChanged<int> onParticleCountChanged;
  final ValueChanged<double> onParticleSizeChanged;
  final ValueChanged<double> onGradientLengthChanged;
  final ValueChanged<double> onConnectionOpacityChanged;
  final ValueChanged<String> onGradientPresetChanged;
  final ValueChanged<double> onMinOpacityChanged;
  final ValueChanged<double> onMaxOpacityChanged;
  final ValueChanged<double> onWidthVariationChanged;

  @override
  Widget build(BuildContext context) {
    switch (effectType) {
      case 'flowing_dash':
        return FlowingDashControls(
          speed: speed,
          dashLength: dashLength,
          gapLength: gapLength,
          onSpeedChanged: onSpeedChanged,
          onDashLengthChanged: onDashLengthChanged,
          onGapLengthChanged: onGapLengthChanged,
        );
      case 'particle':
        return ParticleControls(
          speed: speed,
          particleCount: particleCount,
          particleSize: particleSize,
          onSpeedChanged: onSpeedChanged,
          onParticleCountChanged: onParticleCountChanged,
          onParticleSizeChanged: onParticleSizeChanged,
        );
      case 'gradient':
        return GradientControls(
          speed: speed,
          gradientLength: gradientLength,
          connectionOpacity: connectionOpacity,
          selectedGradientPreset: selectedGradientPreset,
          onSpeedChanged: onSpeedChanged,
          onGradientLengthChanged: onGradientLengthChanged,
          onConnectionOpacityChanged: onConnectionOpacityChanged,
          onGradientPresetChanged: onGradientPresetChanged,
        );
      case 'pulse':
        return PulseControls(
          speed: speed,
          minOpacity: minOpacity,
          maxOpacity: maxOpacity,
          widthVariation: widthVariation,
          onSpeedChanged: onSpeedChanged,
          onMinOpacityChanged: onMinOpacityChanged,
          onMaxOpacityChanged: onMaxOpacityChanged,
          onWidthVariationChanged: onWidthVariationChanged,
        );
      default:
        return const SizedBox.shrink();
    }
  }
}

class FlowingDashControls extends StatelessWidget {
  const FlowingDashControls({
    super.key,
    required this.speed,
    required this.dashLength,
    required this.gapLength,
    required this.onSpeedChanged,
    required this.onDashLengthChanged,
    required this.onGapLengthChanged,
  });

  final double speed;
  final double dashLength;
  final double gapLength;
  final ValueChanged<double> onSpeedChanged;
  final ValueChanged<double> onDashLengthChanged;
  final ValueChanged<double> onGapLengthChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SectionTitle('Flowing Dash Settings'),
        const SizedBox(height: 12),
        SliderControl(
          label: 'Speed',
          value: speed,
          min: 0.1,
          max: 5.0,
          onChanged: onSpeedChanged,
        ),
        SliderControl(
          label: 'Dash Length',
          value: dashLength,
          min: 2.0,
          max: 30.0,
          onChanged: onDashLengthChanged,
        ),
        SliderControl(
          label: 'Gap Length',
          value: gapLength,
          min: 1.0,
          max: 20.0,
          onChanged: onGapLengthChanged,
        ),
      ],
    );
  }
}

class ParticleControls extends StatelessWidget {
  const ParticleControls({
    super.key,
    required this.speed,
    required this.particleCount,
    required this.particleSize,
    required this.onSpeedChanged,
    required this.onParticleCountChanged,
    required this.onParticleSizeChanged,
  });

  final double speed;
  final int particleCount;
  final double particleSize;
  final ValueChanged<double> onSpeedChanged;
  final ValueChanged<int> onParticleCountChanged;
  final ValueChanged<double> onParticleSizeChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SectionTitle('Particle Settings'),
        const SizedBox(height: 12),
        SliderControl(
          label: 'Speed',
          value: speed,
          min: 0.1,
          max: 5.0,
          onChanged: onSpeedChanged,
        ),
        SliderControl(
          label: 'Particle Count',
          value: particleCount.toDouble(),
          min: 1,
          max: 10,
          divisions: 9,
          onChanged: (value) => onParticleCountChanged(value.round()),
        ),
        SliderControl(
          label: 'Particle Size',
          value: particleSize,
          min: 1.0,
          max: 10.0,
          onChanged: onParticleSizeChanged,
        ),
      ],
    );
  }
}

class GradientControls extends StatelessWidget {
  const GradientControls({
    super.key,
    required this.speed,
    required this.gradientLength,
    required this.connectionOpacity,
    required this.selectedGradientPreset,
    required this.onSpeedChanged,
    required this.onGradientLengthChanged,
    required this.onConnectionOpacityChanged,
    required this.onGradientPresetChanged,
  });

  final double speed;
  final double gradientLength;
  final double connectionOpacity;
  final String selectedGradientPreset;
  final ValueChanged<double> onSpeedChanged;
  final ValueChanged<double> onGradientLengthChanged;
  final ValueChanged<double> onConnectionOpacityChanged;
  final ValueChanged<String> onGradientPresetChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SectionTitle('Gradient Settings'),
        const SizedBox(height: 12),
        const Text('Color Preset', style: TextStyle(fontSize: 12)),
        const SizedBox(height: 8),
        DropdownButton<String>(
          value: selectedGradientPreset,
          isExpanded: true,
          items: gradientPresets.keys.map((key) {
            final colors = gradientPresets[key]!;
            return DropdownMenuItem(
              value: key,
              child: Row(
                children: [
                  // Color preview
                  Container(
                    width: 60,
                    height: 20,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(colors: colors),
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(key.replaceAll('_', ' → ')),
                ],
              ),
            );
          }).toList(),
          onChanged: (value) {
            if (value != null) {
              onGradientPresetChanged(value);
            }
          },
        ),
        const SizedBox(height: 16),
        SliderControl(
          label: 'Speed',
          value: speed,
          min: 0.1,
          max: 5.0,
          onChanged: onSpeedChanged,
        ),
        SliderControl(
          label: 'Gradient Length',
          value: gradientLength,
          min: 0.1,
          max: 1.0,
          onChanged: onGradientLengthChanged,
        ),
        SliderControl(
          label: 'Connection Opacity',
          value: connectionOpacity,
          min: 0.0,
          max: 1.0,
          onChanged: onConnectionOpacityChanged,
        ),
      ],
    );
  }
}

class PulseControls extends StatelessWidget {
  const PulseControls({
    super.key,
    required this.speed,
    required this.minOpacity,
    required this.maxOpacity,
    required this.widthVariation,
    required this.onSpeedChanged,
    required this.onMinOpacityChanged,
    required this.onMaxOpacityChanged,
    required this.onWidthVariationChanged,
  });

  final double speed;
  final double minOpacity;
  final double maxOpacity;
  final double widthVariation;
  final ValueChanged<double> onSpeedChanged;
  final ValueChanged<double> onMinOpacityChanged;
  final ValueChanged<double> onMaxOpacityChanged;
  final ValueChanged<double> onWidthVariationChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SectionTitle('Pulse Settings'),
        const SizedBox(height: 12),
        SliderControl(
          label: 'Pulse Speed',
          value: speed,
          min: 0.1,
          max: 5.0,
          onChanged: onSpeedChanged,
        ),
        SliderControl(
          label: 'Min Opacity',
          value: minOpacity,
          min: 0.0,
          max: 1.0,
          onChanged: onMinOpacityChanged,
        ),
        SliderControl(
          label: 'Max Opacity',
          value: maxOpacity,
          min: 0.0,
          max: 1.0,
          onChanged: onMaxOpacityChanged,
        ),
        SliderControl(
          label: 'Width Variation',
          value: widthVariation,
          min: 1.0,
          max: 3.0,
          onChanged: onWidthVariationChanged,
        ),
      ],
    );
  }
}
