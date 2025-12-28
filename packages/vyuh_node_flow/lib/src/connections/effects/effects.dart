/// Connection effects for animations and visual enhancements.
///
/// This library provides a collection of built-in effects that can
/// be applied to connections in a node flow diagram.
///
/// ## Available Effects
///
/// - [FlowingDashEffect]: Creates a flowing dash pattern along the connection
/// - [ParticleEffect]: Shows particles moving along the connection path
/// - [GradientFlowEffect]: Animates a gradient flowing along the path
/// - [PulseEffect]: Creates a pulsing/glowing effect on the connection
///
/// ## Usage Example
///
/// ```dart
/// import 'package:vyuh_node_flow/vyuh_node_flow.dart';
///
/// // Use pre-configured effects
/// connection.animationEffect = ConnectionEffects.flowingDashFast;
/// connection.animationEffect = ConnectionEffects.particlesRocket;
/// connection.animationEffect = ConnectionEffects.pulseStrong;
///
/// // Or create custom effect instances
/// connection.animationEffect = FlowingDashEffect(
///   speed: 2,
///   dashLength: 10,
///   gapLength: 5,
/// );
///
/// connection.animationEffect = ParticleEffect(
///   particlePainter: Particles.arrow,
///   particleCount: 5,
///   speed: 2,
/// );
///
/// connection.animationEffect = GradientFlowEffect(
///   colors: [Colors.blue, Colors.cyan, Colors.blue],
///   speed: 1,
/// );
///
/// connection.animationEffect = PulseEffect(
///   speed: 1,
///   minOpacity: 0.3,
///   maxOpacity: 1.0,
///   widthVariation: 1.5,
/// );
/// ```
///
/// ## Custom Effects
///
/// You can create custom effects by implementing [ConnectionEffect]:
///
/// ```dart
/// class MyCustomEffect implements ConnectionEffect {
///   @override
///   void paint(Canvas canvas, Path path, Paint basePaint, double animationValue) {
///     // Your custom effect rendering logic
///   }
/// }
/// ```
library;

export 'connection_effect.dart';
export 'connection_effects.dart';
export 'flowing_dash_effect.dart';
export 'gradient_flow_effect.dart';
export 'particle_effect.dart';
export 'particle_painter.dart';
export 'particles.dart';
export 'particles/arrow_particle.dart';
export 'particles/character_particle.dart';
export 'particles/circle_particle.dart';
export 'pulse_effect.dart';
