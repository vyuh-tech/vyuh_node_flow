/// Animation effects for connections.
///
/// This library provides a collection of built-in animation effects that can
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
/// import 'package:vyuh_node_flow/connections/animation/animation_effects.dart';
///
/// // Apply a flowing dash effect
/// connection.animationEffect = FlowingDashEffect(
///   speed: 2.0,
///   dashLength: 10.0,
///   gapLength: 5.0,
/// );
///
/// // Apply a particle effect
/// connection.animationEffect = ParticleEffect(
///   particleCount: 5,
///   particleSize: 4.0,
///   speed: 1.5,
/// );
///
/// // Apply a gradient flow effect
/// connection.animationEffect = GradientFlowEffect(
///   colors: [Colors.blue, Colors.cyan, Colors.blue],
///   speed: 1.0,
/// );
///
/// // Apply a pulse effect
/// connection.animationEffect = PulseEffect(
///   pulseSpeed: 1.0,
///   minOpacity: 0.3,
///   maxOpacity: 1.0,
///   widthVariation: 1.5,
/// );
/// ```
///
/// ## Custom Effects
///
/// You can create custom animation effects by extending [ConnectionAnimationEffect]:
///
/// ```dart
/// class MyCustomEffect extends ConnectionAnimationEffect {
///   @override
///   void paint(Canvas canvas, Path path, Paint basePaint, double animationValue) {
///     // Your custom animation rendering logic
///   }
/// }
/// ```
library;

export 'connection_animation_effect.dart';
export 'flowing_dash_effect.dart';
export 'gradient_flow_effect.dart';
export 'particle_effect.dart';
export 'pulse_effect.dart';
