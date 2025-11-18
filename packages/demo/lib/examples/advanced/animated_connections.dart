import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:mobx/mobx.dart';
import 'package:vyuh_node_flow/vyuh_node_flow.dart';

import '../../shared/ui_widgets.dart';

// Gradient color presets
const Map<String, List<Color>> gradientPresets = {
  // Transparent to color gradients (glow trail effect)
  'transparent_red': [Color(0x00FF0000), Colors.red],
  'transparent_orange': [Color(0x00FF9800), Colors.orange],
  'transparent_magenta': [Color(0x00FF00FF), Color(0xFFFF00FF)],
  'transparent_cyan': [Color(0x0000FFFF), Colors.cyan],
  // Color to color gradients
  'yellow_red': [Colors.yellow, Colors.red],
  'lime_green': [Colors.lime, Colors.green],
  'cyan_purple': [Colors.cyan, Colors.purple],
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
        particleType,
        particleCharacter,
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

  final Observable<String> _particleType = Observable('circle');

  String get particleType => _particleType.value;

  set particleType(String value) =>
      runInAction(() => _particleType.value = value);

  final Observable<String> _particleCharacter = Observable('📦');

  String get particleCharacter => _particleCharacter.value;

  set particleCharacter(String value) =>
      runInAction(() => _particleCharacter.value = value);

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

  final Observable<String> _selectedGradientPreset = Observable(
    'transparent_cyan',
  );

  String get selectedGradientPreset => _selectedGradientPreset.value;

  set selectedGradientPreset(String value) =>
      runInAction(() => _selectedGradientPreset.value = value);

  final Observable<double> _strokeWidth = Observable(2.0);

  double get strokeWidth => _strokeWidth.value;

  set strokeWidth(double value) =>
      runInAction(() => _strokeWidth.value = value);

  void applyAnimationEffect() {
    if (selectedConnection == null) return;

    ConnectionEffect? effect;

    switch (selectedEffectType) {
      case 'flowing_dash':
        effect = FlowingDashEffect(
          speed: speed,
          dashLength: dashLength,
          gapLength: gapLength,
        );
        break;
      case 'particle':
        ParticlePainter particlePainter;
        switch (particleType) {
          case 'circle':
            particlePainter = CircleParticle(radius: particleSize.toDouble());
            break;
          case 'arrow':
            particlePainter = ArrowParticle(
              length: particleSize.toDouble() * 3,
              width: particleSize.toDouble() * 2,
            );
            break;
          case 'character':
            particlePainter = CharacterParticle(
              character: particleCharacter,
              fontSize: particleSize.toDouble() * 3,
            );
            break;
          default:
            particlePainter = CircleParticle(radius: particleSize.toDouble());
        }

        effect = ParticleEffect(
          particlePainter: particlePainter,
          particleCount: particleCount,
          speed: speed,
          connectionOpacity: connectionOpacity,
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
          speed: speed,
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
    // Layout: Data Source (left) -> Processor (middle) -> Data Sync (right)
    // Plus: Vertical connections via top and bottom processors
    final node1 = Node<Map<String, dynamic>>(
      id: 'node1',
      type: 'source',
      position: const Offset(50, 180),
      size: const Size(150, 80),
      data: {'label': 'Data Source'},
      outputPorts: const [
        Port(
          id: 'out_right',
          name: 'Output',
          position: PortPosition.right,
          offset: Offset(0, 40),
        ),
        Port(
          id: 'out_top',
          name: 'Top',
          position: PortPosition.top,
          offset: Offset(75, 0),
        ),
        Port(
          id: 'out_bottom',
          name: 'Bottom',
          position: PortPosition.bottom,
          offset: Offset(75, 0),
        ),
      ],
    );

    final node2 = Node<Map<String, dynamic>>(
      id: 'node2',
      type: 'processor',
      position: const Offset(350, 180),
      size: const Size(150, 80),
      data: {'label': 'Processor Middle'},
      inputPorts: const [
        Port(
          id: 'in_left',
          name: 'Input',
          position: PortPosition.left,
          offset: Offset(0, 40),
        ),
      ],
      outputPorts: const [
        Port(
          id: 'out_right',
          name: 'Output',
          position: PortPosition.right,
          offset: Offset(0, 40),
        ),
      ],
    );

    final node5 = Node<Map<String, dynamic>>(
      id: 'node5',
      type: 'sync',
      position: const Offset(650, 180),
      size: const Size(150, 80),
      data: {'label': 'Data Sync'},
      inputPorts: const [
        Port(
          id: 'in_left',
          name: 'Input',
          position: PortPosition.left,
          offset: Offset(0, 40),
        ),
        Port(
          id: 'in_top',
          name: 'Top',
          position: PortPosition.top,
          offset: Offset(75, 0),
        ),
        Port(
          id: 'in_bottom',
          name: 'Bottom',
          position: PortPosition.bottom,
          offset: Offset(75, 0),
        ),
      ],
    );

    // Create two additional processor nodes for vertical connections
    final node6 = Node<Map<String, dynamic>>(
      id: 'node6',
      type: 'processor',
      position: const Offset(350, 30),
      size: const Size(150, 80),
      data: {'label': 'Processor Top'},
      inputPorts: const [
        Port(
          id: 'in_bottom',
          name: 'Input',
          position: PortPosition.bottom,
          offset: Offset(75, 0),
        ),
      ],
      outputPorts: const [
        Port(
          id: 'out_top',
          name: 'Output',
          position: PortPosition.top,
          offset: Offset(75, 0),
        ),
      ],
    );

    final node7 = Node<Map<String, dynamic>>(
      id: 'node7',
      type: 'processor',
      position: const Offset(350, 330),
      size: const Size(150, 80),
      data: {'label': 'Processor Bottom'},
      inputPorts: const [
        Port(
          id: 'in_top',
          name: 'Input',
          position: PortPosition.top,
          offset: Offset(75, 0),
        ),
      ],
      outputPorts: const [
        Port(
          id: 'out_bottom',
          name: 'Output',
          position: PortPosition.bottom,
          offset: Offset(75, 0),
        ),
      ],
    );

    _controller.addNode(node1);
    _controller.addNode(node2);
    _controller.addNode(node5);
    _controller.addNode(node6);
    _controller.addNode(node7);

    // Create horizontal connection: Data Source -> Processor Middle -> Data Sync
    final conn1 = Connection(
      id: 'conn1',
      sourceNodeId: 'node1',
      sourcePortId: 'out_right',
      targetNodeId: 'node2',
      targetPortId: 'in_left',
      animationEffect: ConnectionEffects.flowingDash,
    );

    final conn2 = Connection(
      id: 'conn2',
      sourceNodeId: 'node2',
      sourcePortId: 'out_right',
      targetNodeId: 'node5',
      targetPortId: 'in_left',
      animationEffect: ParticleEffect(
        particlePainter: Particles.circle,
        // Store default: particleSize = 3
        particleCount: 3,
        // Store default
        speed: 1,
        // Store default
        connectionOpacity: 1.0, // Store default
      ),
    );

    // Create vertical connections (using store defaults)
    // Top path: Data Source -> Processor Top -> Data Sync
    final conn7 = Connection(
      id: 'conn7',
      sourceNodeId: 'node1',
      sourcePortId: 'out_top',
      targetNodeId: 'node6',
      targetPortId: 'in_bottom',
      // Note: Using default gradient with custom colors
      animationEffect: GradientFlowEffect(
        colors: gradientPresets['transparent_cyan'],
        speed: 1,
        gradientLength: 0.25,
        connectionOpacity: 1.0,
      ),
    );

    final conn8 = Connection(
      id: 'conn8',
      sourceNodeId: 'node6',
      sourcePortId: 'out_top',
      targetNodeId: 'node5',
      targetPortId: 'in_top',
      animationEffect: ConnectionEffects.pulse,
    );

    // Bottom path: Data Source -> Processor Bottom -> Data Sync
    final conn9 = Connection(
      id: 'conn9',
      sourceNodeId: 'node1',
      sourcePortId: 'out_bottom',
      targetNodeId: 'node7',
      targetPortId: 'in_top',
      animationEffect: ConnectionEffects.flowingDash,
    );

    final conn10 = Connection(
      id: 'conn10',
      sourceNodeId: 'node7',
      sourcePortId: 'out_bottom',
      targetNodeId: 'node5',
      targetPortId: 'in_bottom',
      animationEffect: ParticleEffect(
        particlePainter: Particles.circle,
        // Store default: particleSize = 3
        particleCount: 3,
        // Store default
        speed: 1,
        // Store default
        connectionOpacity: 1.0, // Store default
      ),
    );

    _controller.addConnection(conn1);
    _controller.addConnection(conn2);
    _controller.addConnection(conn7);
    _controller.addConnection(conn8);
    _controller.addConnection(conn9);
    _controller.addConnection(conn10);
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

          events: NodeFlowEvents<Map<String, dynamic>>(
            connection: ConnectionEvents<Map<String, dynamic>>(
              onSelected: (connection) {
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
                    // Note: particleSize is now part of the particlePainter, not the effect itself
                  } else if (effect is GradientFlowEffect) {
                    _store.selectedEffectType = 'gradient';
                    _store.speed = effect.speed;
                    _store.gradientLength = effect.gradientLength;
                  } else if (effect is PulseEffect) {
                    _store.selectedEffectType = 'pulse';
                    _store.speed = effect.speed;
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
                        particleType: _store.particleType,
                        particleCharacter: _store.particleCharacter,
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
                        onParticleTypeChanged: (value) =>
                            _store.particleType = value,
                        onParticleCharacterChanged: (value) =>
                            _store.particleCharacter = value,
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
    required this.particleType,
    required this.particleCharacter,
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
    required this.onParticleTypeChanged,
    required this.onParticleCharacterChanged,
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
  final String particleType;
  final String particleCharacter;
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
  final ValueChanged<String> onParticleTypeChanged;
  final ValueChanged<String> onParticleCharacterChanged;
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
          particleType: particleType,
          particleCharacter: particleCharacter,
          connectionOpacity: connectionOpacity,
          onSpeedChanged: onSpeedChanged,
          onParticleCountChanged: onParticleCountChanged,
          onParticleSizeChanged: onParticleSizeChanged,
          onParticleTypeChanged: onParticleTypeChanged,
          onParticleCharacterChanged: onParticleCharacterChanged,
          onConnectionOpacityChanged: onConnectionOpacityChanged,
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
          min: 1.0,
          max: 5.0,
          divisions: 4,
          onChanged: onSpeedChanged,
        ),
        SliderControl(
          label: 'Dash Length',
          value: dashLength,
          min: 2.0,
          max: 30.0,
          divisions: 28,
          onChanged: onDashLengthChanged,
        ),
        SliderControl(
          label: 'Gap Length',
          value: gapLength,
          min: 1.0,
          max: 20.0,
          divisions: 19,
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
    required this.particleType,
    required this.particleCharacter,
    required this.connectionOpacity,
    required this.onSpeedChanged,
    required this.onParticleCountChanged,
    required this.onParticleSizeChanged,
    required this.onParticleTypeChanged,
    required this.onParticleCharacterChanged,
    required this.onConnectionOpacityChanged,
  });

  final double speed;
  final int particleCount;
  final double particleSize;
  final String particleType;
  final String particleCharacter;
  final double connectionOpacity;
  final ValueChanged<double> onSpeedChanged;
  final ValueChanged<int> onParticleCountChanged;
  final ValueChanged<double> onParticleSizeChanged;
  final ValueChanged<String> onParticleTypeChanged;
  final ValueChanged<String> onParticleCharacterChanged;
  final ValueChanged<double> onConnectionOpacityChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SectionTitle('Particle Settings'),
        const SizedBox(height: 12),
        // Particle Type Selector
        const Text('Particle Type', style: TextStyle(fontSize: 12)),
        const SizedBox(height: 8),
        DropdownButton<String>(
          value: particleType,
          isExpanded: true,
          items: const [
            DropdownMenuItem(value: 'circle', child: Text('Circle')),
            DropdownMenuItem(value: 'arrow', child: Text('Arrow')),
            DropdownMenuItem(
              value: 'character',
              child: Text('Character/Emoji'),
            ),
          ],
          onChanged: (value) {
            if (value != null) onParticleTypeChanged(value);
          },
        ),
        const SizedBox(height: 12),
        // Character input (shown only for character type)
        if (particleType == 'character') ...[
          const Text('Character', style: TextStyle(fontSize: 12)),
          const SizedBox(height: 8),
          TextField(
            controller: TextEditingController(text: particleCharacter)
              ..selection = TextSelection.fromPosition(
                TextPosition(offset: particleCharacter.length),
              ),
            maxLength: 2,
            decoration: const InputDecoration(
              hintText: 'Enter emoji or character',
              border: OutlineInputBorder(),
              contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            ),
            onChanged: onParticleCharacterChanged,
          ),
          const SizedBox(height: 12),
        ],
        SliderControl(
          label: 'Speed',
          value: speed,
          min: 1.0,
          max: 5.0,
          divisions: 4,
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
          divisions: 9,
          onChanged: onParticleSizeChanged,
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
          min: 1.0,
          max: 5.0,
          divisions: 4,
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
