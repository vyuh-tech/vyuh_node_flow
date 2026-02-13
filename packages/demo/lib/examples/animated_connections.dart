import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:mobx/mobx.dart';
import 'package:vyuh_node_flow/vyuh_node_flow.dart';

import '../shared/ui_widgets.dart';

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

// Endpoint shape presets (name → MarkerShape)
const _endpointShapes = <String, MarkerShape>{
  'none': MarkerShapes.none,
  'circle': MarkerShapes.circle,
  'triangle': MarkerShapes.triangle,
  'diamond': MarkerShapes.diamond,
  'rectangle': MarkerShapes.rectangle,
  'capsule': MarkerShapes.capsuleHalf,
};

// Color presets for connection and endpoint color selectors
final _colorPresets = <String, Color>{
  'Red': Colors.red,
  'Orange': Colors.orange,
  'Green': Colors.green,
  'Blue': Colors.blue,
  'Purple': Colors.purple,
  'Cyan': Colors.cyan,
  'Teal': Colors.teal,
  'Pink': Colors.pink,
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

    // Auto-apply visual properties when they change
    reaction(
      (_) => [endpointShape, connectionColor, endpointColor, strokeWidth],
      (_) => applyVisualProperties(),
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

  final Observable<String> _endpointShape = Observable('triangle');

  String get endpointShape => _endpointShape.value;

  set endpointShape(String value) =>
      runInAction(() => _endpointShape.value = value);

  final Observable<Color?> _connectionColor = Observable(null);

  Color? get connectionColor => _connectionColor.value;

  set connectionColor(Color? value) =>
      runInAction(() => _connectionColor.value = value);

  final Observable<Color?> _endpointColor = Observable(null);

  Color? get endpointColor => _endpointColor.value;

  set endpointColor(Color? value) =>
      runInAction(() => _endpointColor.value = value);

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

  void applyVisualProperties() {
    if (selectedConnection == null) return;

    final shape = _endpointShapes[endpointShape] ?? MarkerShapes.triangle;

    runInAction(() {
      selectedConnection!.endPoint = ConnectionEndPoint(
        shape: shape,
        size: const Size.square(5.0),
        color: endpointColor,
      );
      selectedConnection!.color = connectionColor;
      selectedConnection!.strokeWidth = strokeWidth;
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
  late final NodeFlowController<Map<String, dynamic>, dynamic> _controller;
  late final AnimationDemoStore _store;

  @override
  void initState() {
    super.initState();
    _store = AnimationDemoStore();
    _controller = NodeFlowController<Map<String, dynamic>, dynamic>(
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
      ports: [
        Port(
          id: 'out_right',
          name: 'Output',
          type: PortType.output,
          position: PortPosition.right,
          offset: Offset(2, 40),
        ),
        Port(
          id: 'out_top',
          name: 'Top',
          type: PortType.output,
          position: PortPosition.top,
          offset: Offset(75, -2),
        ),
        Port(
          id: 'out_bottom',
          name: 'Bottom',
          type: PortType.output,
          position: PortPosition.bottom,
          offset: Offset(75, 2),
        ),
      ],
    );

    final node2 = Node<Map<String, dynamic>>(
      id: 'node2',
      type: 'processor',
      position: const Offset(350, 180),
      size: const Size(150, 80),
      data: {'label': 'Processor Middle'},
      ports: [
        Port(
          id: 'in_left',
          name: 'Input',
          type: PortType.input,
          position: PortPosition.left,
          offset: Offset(-2, 40),
        ),
        Port(
          id: 'out_right',
          name: 'Output',
          type: PortType.output,
          position: PortPosition.right,
          offset: Offset(2, 40),
        ),
      ],
    );

    final node5 = Node<Map<String, dynamic>>(
      id: 'node5',
      type: 'sync',
      position: const Offset(650, 180),
      size: const Size(150, 80),
      data: {'label': 'Data Sync'},
      ports: [
        Port(
          id: 'in_left',
          name: 'Input',
          type: PortType.input,
          position: PortPosition.left,
          offset: Offset(-2, 40),
        ),
        Port(
          id: 'in_top',
          name: 'Top',
          type: PortType.input,
          position: PortPosition.top,
          offset: Offset(75, -2),
        ),
        Port(
          id: 'in_bottom',
          name: 'Bottom',
          type: PortType.input,
          position: PortPosition.bottom,
          offset: Offset(75, 2),
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
      ports: [
        Port(
          id: 'in_bottom',
          name: 'Input',
          type: PortType.input,
          position: PortPosition.bottom,
          offset: Offset(75, 2),
        ),
        Port(
          id: 'out_top',
          name: 'Output',
          type: PortType.output,
          position: PortPosition.top,
          offset: Offset(75, -2),
        ),
      ],
    );

    final node7 = Node<Map<String, dynamic>>(
      id: 'node7',
      type: 'processor',
      position: const Offset(350, 330),
      size: const Size(150, 80),
      data: {'label': 'Processor Bottom'},
      ports: [
        Port(
          id: 'in_top',
          name: 'Input',
          type: PortType.input,
          position: PortPosition.top,
          offset: Offset(75, -2),
        ),
        Port(
          id: 'out_bottom',
          name: 'Output',
          type: PortType.output,
          position: PortPosition.bottom,
          offset: Offset(75, 2),
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
      controller: _controller,
      onReset: () {
        _controller.clearGraph();
        _store.selectedConnection = null;
        _createExampleGraph();
        _controller.fitToView();
      },
      child: NodeFlowEditor<Map<String, dynamic>, dynamic>(
        controller: _controller,
        nodeBuilder: _buildNode,
        theme: NodeFlowTheme.light,

        events: NodeFlowEvents<Map<String, dynamic>, dynamic>(
          connection: ConnectionEvents<Map<String, dynamic>, dynamic>(
            onSelected: (connection) {
              _store.selectedConnection = connection;
              if (connection != null) {
                // Read back visual properties
                // Use effective endpoint (falls back to theme if null)
                final themeEndPoint =
                    NodeFlowTheme.light.connectionTheme.endPoint;
                final ep = connection.endPoint ?? themeEndPoint;
                _store.endpointShape =
                    _endpointShapes.entries
                        .where((e) => e.value == ep.shape)
                        .map((e) => e.key)
                        .firstOrNull ??
                    'capsule';
                _store.endpointColor = connection.endPoint?.color;
                _store.connectionColor = connection.color;
                _store.strokeWidth = connection.strokeWidth ?? 2.0;

                // Read back animation effect
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
      children: [
        const SectionTitle('About'),
        SectionContent(
          child: InfoCard(
            title: 'Instructions',
            content:
                'Click on a connection to select it. Customize its endpoint shape, colors, stroke width, and animation effect — all per-connection.',
          ),
        ),
        Observer(
          builder: (context) => _store.selectedConnection == null
              ? SectionContent(
                  child: InfoCard(
                    title: 'Select a Connection',
                    content:
                        'Click on a connection to select it and customize its appearance.',
                  ),
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SectionTitle('Selected Connection'),
                    SectionContent(
                      child: _SelectedConnectionInfo(
                        connection: _store.selectedConnection!,
                        controller: _controller,
                      ),
                    ),
                    const SectionTitle('Appearance'),
                    SectionContent(
                      child: ConnectionAppearanceControls(
                        endpointShape: _store.endpointShape,
                        connectionColor: _store.connectionColor,
                        endpointColor: _store.endpointColor,
                        strokeWidth: _store.strokeWidth,
                        onEndpointShapeChanged: (value) =>
                            _store.endpointShape = value,
                        onConnectionColorChanged: (value) =>
                            _store.connectionColor = value,
                        onEndpointColorChanged: (value) =>
                            _store.endpointColor = value,
                        onStrokeWidthChanged: (value) =>
                            _store.strokeWidth = value,
                      ),
                    ),
                    const SectionTitle('Effect Type'),
                    SectionContent(
                      child: EffectTypeSelector(
                        selectedEffectType: _store.selectedEffectType,
                        onChanged: (value) {
                          if (value != null) {
                            _store.selectedEffectType = value;
                          }
                        },
                      ),
                    ),
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
        SectionContent(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
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
          ),
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
        SectionContent(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
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
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 8,
                    ),
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
          ),
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
        SectionContent(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
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
          ),
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
        SectionContent(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
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
          ),
        ),
      ],
    );
  }
}

/// Controls for per-connection visual properties: endpoint shape, colors, stroke width
class ConnectionAppearanceControls extends StatelessWidget {
  const ConnectionAppearanceControls({
    super.key,
    required this.endpointShape,
    required this.connectionColor,
    required this.endpointColor,
    required this.strokeWidth,
    required this.onEndpointShapeChanged,
    required this.onConnectionColorChanged,
    required this.onEndpointColorChanged,
    required this.onStrokeWidthChanged,
  });

  final String endpointShape;
  final Color? connectionColor;
  final Color? endpointColor;
  final double strokeWidth;
  final ValueChanged<String> onEndpointShapeChanged;
  final ValueChanged<Color?> onConnectionColorChanged;
  final ValueChanged<Color?> onEndpointColorChanged;
  final ValueChanged<double> onStrokeWidthChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Endpoint Shape',
          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 8),
        EndpointShapeSelector(
          selectedShape: endpointShape,
          onShapeSelected: onEndpointShapeChanged,
        ),
        const SubsectionDivider(),
        ColorSelector(
          label: 'Connection Color',
          selectedColor: connectionColor,
          onColorSelected: onConnectionColorChanged,
        ),
        const SubsectionDivider(),
        ColorSelector(
          label: 'Endpoint Color',
          selectedColor: endpointColor,
          onColorSelected: onEndpointColorChanged,
        ),
        const SubsectionDivider(),
        SliderControl(
          label: 'Stroke Width',
          value: strokeWidth,
          min: 1.0,
          max: 10.0,
          onChanged: onStrokeWidthChanged,
        ),
      ],
    );
  }
}

/// Chip selector for endpoint marker shapes
class EndpointShapeSelector extends StatelessWidget {
  const EndpointShapeSelector({
    super.key,
    required this.selectedShape,
    required this.onShapeSelected,
  });

  final String selectedShape;
  final ValueChanged<String> onShapeSelected;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: _endpointShapes.keys.map((key) {
        final displayName = key[0].toUpperCase() + key.substring(1);
        return StyledChip(
          label: displayName,
          selected: key == selectedShape,
          onSelected: (selected) {
            if (selected) onShapeSelected(key);
          },
        );
      }).toList(),
    );
  }
}

/// Color picker showing preset swatches with a "Default" (theme) option
class ColorSelector extends StatelessWidget {
  const ColorSelector({
    super.key,
    required this.label,
    required this.selectedColor,
    required this.onColorSelected,
  });

  final String label;
  final Color? selectedColor;
  final ValueChanged<Color?> onColorSelected;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: [
            // Default (theme) option
            _ColorSwatch(
              color: null,
              isSelected: selectedColor == null,
              onTap: () => onColorSelected(null),
            ),
            ..._colorPresets.values.map(
              (color) => _ColorSwatch(
                color: color,
                isSelected: selectedColor == color,
                onTap: () => onColorSelected(color),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

/// A tappable color swatch circle. Null color renders as "Default".
class _ColorSwatch extends StatelessWidget {
  const _ColorSwatch({
    required this.color,
    required this.isSelected,
    required this.onTap,
  });

  final Color? color;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final borderColor = isSelected
        ? Theme.of(context).colorScheme.primary
        : Colors.grey.shade400;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 28,
        height: 28,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: color ?? Colors.grey.shade300,
          border: Border.all(color: borderColor, width: isSelected ? 2.5 : 1.0),
        ),
        child: color == null
            ? Center(
                child: Icon(
                  Icons.refresh,
                  size: 14,
                  color: Colors.grey.shade600,
                ),
              )
            : null,
      ),
    );
  }
}

/// Displays selected connection info with proper styling
class _SelectedConnectionInfo extends StatelessWidget {
  const _SelectedConnectionInfo({
    required this.connection,
    required this.controller,
  });

  final Connection connection;
  final NodeFlowController<Map<String, dynamic>, dynamic> controller;

  @override
  Widget build(BuildContext context) {
    final sourceNode = controller.nodes[connection.sourceNodeId];
    final targetNode = controller.nodes[connection.targetNodeId];
    final sourceName = sourceNode?.data['label'] ?? connection.sourceNodeId;
    final targetName = targetNode?.data['label'] ?? connection.targetNodeId;

    return InfoCard(
      title: '$sourceName → $targetName',
      content:
          'Port: ${connection.sourcePortId} → ${connection.targetPortId}\nID: ${connection.id}',
    );
  }
}
