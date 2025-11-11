import 'package:flutter/material.dart';

import 'connection_effect.dart';
import 'flowing_dash_effect.dart';
import 'gradient_flow_effect.dart';
import 'particle_effect.dart';
import 'particles.dart';
import 'pulse_effect.dart';

/// Built-in connection animation effects
///
/// This class provides easy access to all the built-in connection animation
/// effects that can be applied to connections in a node flow diagram.
class ConnectionEffects {
  // Private constructor to prevent instantiation
  const ConnectionEffects._();

  // === Built-in Effect Constants ===

  /// Flowing dash effect with default settings
  static final ConnectionEffect flowingDash = FlowingDashEffect();

  /// Fast flowing dash effect
  static final ConnectionEffect flowingDashFast = FlowingDashEffect(speed: 2);

  /// Slow flowing dash effect
  static final ConnectionEffect flowingDashSlow = FlowingDashEffect(
    speed: 1,
    dashLength: 15,
    gapLength: 10,
  );

  /// Standard particle effect with circle particles
  static final ConnectionEffect particles = ParticleEffect();

  /// Particle effect with arrow particles
  static final ConnectionEffect particlesArrow = ParticleEffect(
    particlePainter: Particles.arrow,
    particleCount: 3,
  );

  /// Fast particle effect with more particles
  static final ConnectionEffect particlesFast = ParticleEffect(
    particleCount: 5,
    speed: 2,
  );

  /// Rocket emoji particles
  static final ConnectionEffect particlesRocket = ParticleEffect(
    particlePainter: Particles.rocket,
    particleCount: 3,
  );

  /// Fire emoji particles
  static final ConnectionEffect particlesFire = ParticleEffect(
    particlePainter: Particles.fire,
    particleCount: 4,
    speed: 2,
  );

  /// Standard gradient flow effect
  static final ConnectionEffect gradientFlow = GradientFlowEffect();

  /// Blue to cyan gradient flow
  static final ConnectionEffect gradientFlowBlue = GradientFlowEffect(
    colors: [Colors.blue, Colors.cyan, Colors.blue],
  );

  /// Purple to pink gradient flow
  static final ConnectionEffect gradientFlowPurple = GradientFlowEffect(
    colors: [Colors.purple, Colors.pink, Colors.purple],
  );

  /// Fast gradient flow
  static final ConnectionEffect gradientFlowFast = GradientFlowEffect(
    speed: 2,
    gradientLength: 0.3,
  );

  /// Standard pulse effect
  static final ConnectionEffect pulse = PulseEffect();

  /// Fast pulse effect
  static final ConnectionEffect pulseFast = PulseEffect(speed: 2);

  /// Subtle pulse effect
  static final ConnectionEffect pulseSubtle = PulseEffect(
    minOpacity: 0.6,
    maxOpacity: 1.0,
    widthVariation: 1.2,
  );

  /// Strong pulse effect with glow
  static final ConnectionEffect pulseStrong = PulseEffect(
    minOpacity: 0.3,
    maxOpacity: 1.0,
    widthVariation: 2.0,
  );

  // === Collections ===

  /// All flowing dash effect variations
  static final List<ConnectionEffect> allFlowingDash = [
    flowingDash,
    flowingDashFast,
    flowingDashSlow,
  ];

  /// All particle effect variations
  static final List<ConnectionEffect> allParticles = [
    particles,
    particlesArrow,
    particlesFast,
    particlesRocket,
    particlesFire,
  ];

  /// All gradient flow effect variations
  static final List<ConnectionEffect> allGradientFlow = [
    gradientFlow,
    gradientFlowBlue,
    gradientFlowPurple,
    gradientFlowFast,
  ];

  /// All pulse effect variations
  static final List<ConnectionEffect> allPulse = [
    pulse,
    pulseFast,
    pulseSubtle,
    pulseStrong,
  ];

  /// All built-in connection effects
  static final List<ConnectionEffect> all = [
    ...allFlowingDash,
    ...allParticles,
    ...allGradientFlow,
    ...allPulse,
  ];
}

/// Extension to add convenience methods to connection animation effect instances
extension ConnectionEffectExtension on ConnectionEffect {
  /// Check if this is a built-in connection effect
  bool get isBuiltIn => ConnectionEffects.all.contains(this);
}
