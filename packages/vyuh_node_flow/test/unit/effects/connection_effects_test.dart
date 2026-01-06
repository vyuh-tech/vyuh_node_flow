/// Comprehensive tests for connection effects.
///
/// Tests all connection effects through the public API.
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vyuh_node_flow/vyuh_node_flow.dart';

void main() {
  group('ConnectionEffect Interface', () {
    test('ConnectionEffect is an interface that can be implemented', () {
      // Verify that ConnectionEffect is usable as a type
      final effect = FlowingDashEffect();
      expect(effect, isA<ConnectionEffect>());
    });
  });

  group('ConnectionEffects', () {
    group('Flowing Dash Effects', () {
      test('flowingDash is available', () {
        expect(ConnectionEffects.flowingDash, isNotNull);
        expect(ConnectionEffects.flowingDash, isA<ConnectionEffect>());
        expect(ConnectionEffects.flowingDash, isA<FlowingDashEffect>());
      });

      test('flowingDashFast is available', () {
        expect(ConnectionEffects.flowingDashFast, isNotNull);
        expect(ConnectionEffects.flowingDashFast, isA<ConnectionEffect>());
        expect(ConnectionEffects.flowingDashFast, isA<FlowingDashEffect>());
      });

      test('flowingDashSlow is available', () {
        expect(ConnectionEffects.flowingDashSlow, isNotNull);
        expect(ConnectionEffects.flowingDashSlow, isA<ConnectionEffect>());
        expect(ConnectionEffects.flowingDashSlow, isA<FlowingDashEffect>());
      });

      test('allFlowingDash contains all flowing dash effects', () {
        expect(ConnectionEffects.allFlowingDash, hasLength(3));
        expect(
          ConnectionEffects.allFlowingDash,
          containsAll([
            ConnectionEffects.flowingDash,
            ConnectionEffects.flowingDashFast,
            ConnectionEffects.flowingDashSlow,
          ]),
        );
      });
    });

    group('Particle Effects', () {
      test('particles is available', () {
        expect(ConnectionEffects.particles, isNotNull);
        expect(ConnectionEffects.particles, isA<ConnectionEffect>());
        expect(ConnectionEffects.particles, isA<ParticleEffect>());
      });

      test('particlesArrow is available', () {
        expect(ConnectionEffects.particlesArrow, isNotNull);
        expect(ConnectionEffects.particlesArrow, isA<ConnectionEffect>());
        expect(ConnectionEffects.particlesArrow, isA<ParticleEffect>());
      });

      test('particlesFast is available', () {
        expect(ConnectionEffects.particlesFast, isNotNull);
        expect(ConnectionEffects.particlesFast, isA<ConnectionEffect>());
        expect(ConnectionEffects.particlesFast, isA<ParticleEffect>());
      });

      test('particlesRocket is available', () {
        expect(ConnectionEffects.particlesRocket, isNotNull);
        expect(ConnectionEffects.particlesRocket, isA<ConnectionEffect>());
        expect(ConnectionEffects.particlesRocket, isA<ParticleEffect>());
      });

      test('particlesFire is available', () {
        expect(ConnectionEffects.particlesFire, isNotNull);
        expect(ConnectionEffects.particlesFire, isA<ConnectionEffect>());
        expect(ConnectionEffects.particlesFire, isA<ParticleEffect>());
      });

      test('allParticles contains all particle effects', () {
        expect(ConnectionEffects.allParticles, hasLength(5));
        expect(
          ConnectionEffects.allParticles,
          containsAll([
            ConnectionEffects.particles,
            ConnectionEffects.particlesArrow,
            ConnectionEffects.particlesFast,
            ConnectionEffects.particlesRocket,
            ConnectionEffects.particlesFire,
          ]),
        );
      });
    });

    group('Gradient Flow Effects', () {
      test('gradientFlow is available', () {
        expect(ConnectionEffects.gradientFlow, isNotNull);
        expect(ConnectionEffects.gradientFlow, isA<ConnectionEffect>());
        expect(ConnectionEffects.gradientFlow, isA<GradientFlowEffect>());
      });

      test('gradientFlowBlue is available', () {
        expect(ConnectionEffects.gradientFlowBlue, isNotNull);
        expect(ConnectionEffects.gradientFlowBlue, isA<ConnectionEffect>());
        expect(ConnectionEffects.gradientFlowBlue, isA<GradientFlowEffect>());
      });

      test('gradientFlowPurple is available', () {
        expect(ConnectionEffects.gradientFlowPurple, isNotNull);
        expect(ConnectionEffects.gradientFlowPurple, isA<ConnectionEffect>());
        expect(ConnectionEffects.gradientFlowPurple, isA<GradientFlowEffect>());
      });

      test('gradientFlowFast is available', () {
        expect(ConnectionEffects.gradientFlowFast, isNotNull);
        expect(ConnectionEffects.gradientFlowFast, isA<ConnectionEffect>());
        expect(ConnectionEffects.gradientFlowFast, isA<GradientFlowEffect>());
      });

      test('allGradientFlow contains all gradient flow effects', () {
        expect(ConnectionEffects.allGradientFlow, hasLength(4));
        expect(
          ConnectionEffects.allGradientFlow,
          containsAll([
            ConnectionEffects.gradientFlow,
            ConnectionEffects.gradientFlowBlue,
            ConnectionEffects.gradientFlowPurple,
            ConnectionEffects.gradientFlowFast,
          ]),
        );
      });
    });

    group('Pulse Effects', () {
      test('pulse is available', () {
        expect(ConnectionEffects.pulse, isNotNull);
        expect(ConnectionEffects.pulse, isA<ConnectionEffect>());
        expect(ConnectionEffects.pulse, isA<PulseEffect>());
      });

      test('pulseFast is available', () {
        expect(ConnectionEffects.pulseFast, isNotNull);
        expect(ConnectionEffects.pulseFast, isA<ConnectionEffect>());
        expect(ConnectionEffects.pulseFast, isA<PulseEffect>());
      });

      test('pulseSubtle is available', () {
        expect(ConnectionEffects.pulseSubtle, isNotNull);
        expect(ConnectionEffects.pulseSubtle, isA<ConnectionEffect>());
        expect(ConnectionEffects.pulseSubtle, isA<PulseEffect>());
      });

      test('pulseStrong is available', () {
        expect(ConnectionEffects.pulseStrong, isNotNull);
        expect(ConnectionEffects.pulseStrong, isA<ConnectionEffect>());
        expect(ConnectionEffects.pulseStrong, isA<PulseEffect>());
      });

      test('allPulse contains all pulse effects', () {
        expect(ConnectionEffects.allPulse, hasLength(4));
        expect(
          ConnectionEffects.allPulse,
          containsAll([
            ConnectionEffects.pulse,
            ConnectionEffects.pulseFast,
            ConnectionEffects.pulseSubtle,
            ConnectionEffects.pulseStrong,
          ]),
        );
      });
    });

    group('All Effects Collection', () {
      test('all contains all built-in effects', () {
        expect(ConnectionEffects.all, hasLength(16));
        expect(
          ConnectionEffects.all,
          containsAll([
            ...ConnectionEffects.allFlowingDash,
            ...ConnectionEffects.allParticles,
            ...ConnectionEffects.allGradientFlow,
            ...ConnectionEffects.allPulse,
          ]),
        );
      });
    });
  });

  group('ConnectionEffectExtension', () {
    test('isBuiltIn returns true for built-in effects', () {
      expect(ConnectionEffects.flowingDash.isBuiltIn, isTrue);
      expect(ConnectionEffects.particles.isBuiltIn, isTrue);
      expect(ConnectionEffects.gradientFlow.isBuiltIn, isTrue);
      expect(ConnectionEffects.pulse.isBuiltIn, isTrue);
    });

    test('isBuiltIn returns false for custom effects', () {
      final customEffect = FlowingDashEffect(speed: 5, dashLength: 20);
      expect(customEffect.isBuiltIn, isFalse);
    });
  });

  group('FlowingDashEffect', () {
    test('default constructor creates effect with default values', () {
      final effect = FlowingDashEffect();
      expect(effect.speed, equals(1));
      expect(effect.dashLength, equals(10));
      expect(effect.gapLength, equals(5));
    });

    test('constructor accepts custom values', () {
      final effect = FlowingDashEffect(speed: 3, dashLength: 15, gapLength: 8);
      expect(effect.speed, equals(3));
      expect(effect.dashLength, equals(15));
      expect(effect.gapLength, equals(8));
    });

    test('implements ConnectionEffect', () {
      final effect = FlowingDashEffect();
      expect(effect, isA<ConnectionEffect>());
    });

    test('speed must be positive', () {
      expect(() => FlowingDashEffect(speed: 0), throwsA(isA<AssertionError>()));
      expect(
        () => FlowingDashEffect(speed: -1),
        throwsA(isA<AssertionError>()),
      );
    });

    test('dashLength must be positive', () {
      expect(
        () => FlowingDashEffect(dashLength: 0),
        throwsA(isA<AssertionError>()),
      );
      expect(
        () => FlowingDashEffect(dashLength: -5),
        throwsA(isA<AssertionError>()),
      );
    });

    test('gapLength must be positive', () {
      expect(
        () => FlowingDashEffect(gapLength: 0),
        throwsA(isA<AssertionError>()),
      );
      expect(
        () => FlowingDashEffect(gapLength: -3),
        throwsA(isA<AssertionError>()),
      );
    });

    test('flowingDashFast has higher speed', () {
      final standard = ConnectionEffects.flowingDash as FlowingDashEffect;
      final fast = ConnectionEffects.flowingDashFast as FlowingDashEffect;
      expect(fast.speed, greaterThan(standard.speed));
    });

    test('flowingDashSlow has different dash configuration', () {
      final slow = ConnectionEffects.flowingDashSlow as FlowingDashEffect;
      expect(slow.speed, equals(1));
      expect(slow.dashLength, equals(15));
      expect(slow.gapLength, equals(10));
    });
  });

  group('ParticleEffect', () {
    test('default constructor creates effect with default values', () {
      final effect = ParticleEffect();
      expect(effect.particleCount, equals(3));
      expect(effect.speed, equals(1));
      expect(effect.connectionOpacity, equals(0.3));
      expect(effect.particlePainter, isA<CircleParticle>());
    });

    test('constructor accepts custom values', () {
      final effect = ParticleEffect(
        particlePainter: Particles.arrow,
        particleCount: 5,
        speed: 2,
        connectionOpacity: 0.5,
      );
      expect(effect.particleCount, equals(5));
      expect(effect.speed, equals(2));
      expect(effect.connectionOpacity, equals(0.5));
      expect(effect.particlePainter, same(Particles.arrow));
    });

    test('implements ConnectionEffect', () {
      final effect = ParticleEffect();
      expect(effect, isA<ConnectionEffect>());
    });

    test('particleCount must be positive', () {
      expect(
        () => ParticleEffect(particleCount: 0),
        throwsA(isA<AssertionError>()),
      );
      expect(
        () => ParticleEffect(particleCount: -1),
        throwsA(isA<AssertionError>()),
      );
    });

    test('speed must be positive', () {
      expect(() => ParticleEffect(speed: 0), throwsA(isA<AssertionError>()));
      expect(() => ParticleEffect(speed: -1), throwsA(isA<AssertionError>()));
    });

    test('connectionOpacity must be between 0 and 1', () {
      expect(
        () => ParticleEffect(connectionOpacity: -0.1),
        throwsA(isA<AssertionError>()),
      );
      expect(
        () => ParticleEffect(connectionOpacity: 1.1),
        throwsA(isA<AssertionError>()),
      );
    });

    test('connectionOpacity can be 0 (invisible connection)', () {
      final effect = ParticleEffect(connectionOpacity: 0.0);
      expect(effect.connectionOpacity, equals(0.0));
    });

    test('connectionOpacity can be 1 (full opacity)', () {
      final effect = ParticleEffect(connectionOpacity: 1.0);
      expect(effect.connectionOpacity, equals(1.0));
    });

    test('particlesArrow uses arrow particle painter', () {
      final effect = ConnectionEffects.particlesArrow as ParticleEffect;
      expect(effect.particlePainter, same(Particles.arrow));
      expect(effect.particleCount, equals(3));
    });

    test('particlesFast has more particles and higher speed', () {
      final effect = ConnectionEffects.particlesFast as ParticleEffect;
      expect(effect.particleCount, equals(5));
      expect(effect.speed, equals(2));
    });

    test('particlesRocket uses rocket emoji particle', () {
      final effect = ConnectionEffects.particlesRocket as ParticleEffect;
      expect(effect.particlePainter, same(Particles.rocket));
      expect(effect.particleCount, equals(3));
    });

    test('particlesFire uses fire emoji particle with higher speed', () {
      final effect = ConnectionEffects.particlesFire as ParticleEffect;
      expect(effect.particlePainter, same(Particles.fire));
      expect(effect.particleCount, equals(4));
      expect(effect.speed, equals(2));
    });
  });

  group('GradientFlowEffect', () {
    test('default constructor creates effect with default values', () {
      final effect = GradientFlowEffect();
      expect(effect.colors, isNull);
      expect(effect.speed, equals(1));
      expect(effect.gradientLength, equals(0.25));
      expect(effect.connectionOpacity, equals(1.0));
    });

    test('constructor accepts custom values', () {
      final effect = GradientFlowEffect(
        colors: [Colors.red, Colors.blue],
        speed: 2,
        gradientLength: 0.5,
        connectionOpacity: 0.8,
      );
      expect(effect.colors, equals([Colors.red, Colors.blue]));
      expect(effect.speed, equals(2));
      expect(effect.gradientLength, equals(0.5));
      expect(effect.connectionOpacity, equals(0.8));
    });

    test('implements ConnectionEffect', () {
      final effect = GradientFlowEffect();
      expect(effect, isA<ConnectionEffect>());
    });

    test('speed must be positive', () {
      expect(
        () => GradientFlowEffect(speed: 0),
        throwsA(isA<AssertionError>()),
      );
      expect(
        () => GradientFlowEffect(speed: -1),
        throwsA(isA<AssertionError>()),
      );
    });

    test('gradientLength must be positive', () {
      expect(
        () => GradientFlowEffect(gradientLength: 0),
        throwsA(isA<AssertionError>()),
      );
      expect(
        () => GradientFlowEffect(gradientLength: -0.1),
        throwsA(isA<AssertionError>()),
      );
    });

    test('connectionOpacity must be between 0 and 1', () {
      expect(
        () => GradientFlowEffect(connectionOpacity: -0.1),
        throwsA(isA<AssertionError>()),
      );
      expect(
        () => GradientFlowEffect(connectionOpacity: 1.1),
        throwsA(isA<AssertionError>()),
      );
    });

    test('colors list must have at least 2 colors', () {
      expect(
        () => GradientFlowEffect(colors: [Colors.red]),
        throwsA(isA<AssertionError>()),
      );
      expect(
        () => GradientFlowEffect(colors: []),
        throwsA(isA<AssertionError>()),
      );
    });

    test('gradientFlowBlue has blue color gradient', () {
      final effect = ConnectionEffects.gradientFlowBlue as GradientFlowEffect;
      expect(effect.colors, isNotNull);
      expect(effect.colors, contains(Colors.blue));
      expect(effect.colors, contains(Colors.cyan));
    });

    test('gradientFlowPurple has purple color gradient', () {
      final effect = ConnectionEffects.gradientFlowPurple as GradientFlowEffect;
      expect(effect.colors, isNotNull);
      expect(effect.colors, contains(Colors.purple));
      expect(effect.colors, contains(Colors.pink));
    });

    test('gradientFlowFast has higher speed and different gradient length', () {
      final effect = ConnectionEffects.gradientFlowFast as GradientFlowEffect;
      expect(effect.speed, equals(2));
      expect(effect.gradientLength, equals(0.3));
    });

    test('gradientLength less than 1 is treated as percentage', () {
      final effect = GradientFlowEffect(gradientLength: 0.5);
      expect(effect.gradientLength, equals(0.5));
      expect(effect.gradientLength, lessThan(1.0));
    });

    test('gradientLength >= 1 is treated as absolute pixels', () {
      final effect = GradientFlowEffect(gradientLength: 50);
      expect(effect.gradientLength, equals(50.0));
      expect(effect.gradientLength, greaterThanOrEqualTo(1.0));
    });
  });

  group('PulseEffect', () {
    test('default constructor creates effect with default values', () {
      final effect = PulseEffect();
      expect(effect.speed, equals(1));
      expect(effect.minOpacity, equals(0.4));
      expect(effect.maxOpacity, equals(1.0));
      expect(effect.widthVariation, equals(1.0));
    });

    test('constructor accepts custom values', () {
      final effect = PulseEffect(
        speed: 2,
        minOpacity: 0.2,
        maxOpacity: 0.9,
        widthVariation: 1.8,
      );
      expect(effect.speed, equals(2));
      expect(effect.minOpacity, equals(0.2));
      expect(effect.maxOpacity, equals(0.9));
      expect(effect.widthVariation, equals(1.8));
    });

    test('implements ConnectionEffect', () {
      final effect = PulseEffect();
      expect(effect, isA<ConnectionEffect>());
    });

    test('speed must be positive', () {
      expect(() => PulseEffect(speed: 0), throwsA(isA<AssertionError>()));
      expect(() => PulseEffect(speed: -1), throwsA(isA<AssertionError>()));
    });

    test('minOpacity must be between 0 and 1', () {
      expect(
        () => PulseEffect(minOpacity: -0.1),
        throwsA(isA<AssertionError>()),
      );
      expect(
        () => PulseEffect(minOpacity: 1.1),
        throwsA(isA<AssertionError>()),
      );
    });

    test('maxOpacity must be between 0 and 1', () {
      expect(
        () => PulseEffect(maxOpacity: -0.1),
        throwsA(isA<AssertionError>()),
      );
      expect(
        () => PulseEffect(maxOpacity: 1.1),
        throwsA(isA<AssertionError>()),
      );
    });

    test('minOpacity must be <= maxOpacity', () {
      expect(
        () => PulseEffect(minOpacity: 0.8, maxOpacity: 0.5),
        throwsA(isA<AssertionError>()),
      );
    });

    test('widthVariation must be >= 1.0', () {
      expect(
        () => PulseEffect(widthVariation: 0.5),
        throwsA(isA<AssertionError>()),
      );
      expect(
        () => PulseEffect(widthVariation: 0.9),
        throwsA(isA<AssertionError>()),
      );
    });

    test('widthVariation of 1.0 means no width change', () {
      final effect = PulseEffect(widthVariation: 1.0);
      expect(effect.widthVariation, equals(1.0));
    });

    test('pulseFast has higher speed', () {
      final standard = ConnectionEffects.pulse as PulseEffect;
      final fast = ConnectionEffects.pulseFast as PulseEffect;
      expect(fast.speed, greaterThan(standard.speed));
    });

    test('pulseSubtle has minimal opacity variation', () {
      final effect = ConnectionEffects.pulseSubtle as PulseEffect;
      expect(effect.minOpacity, equals(0.6));
      expect(effect.maxOpacity, equals(1.0));
      expect(effect.widthVariation, equals(1.2));
    });

    test('pulseStrong has strong opacity and width variation', () {
      final effect = ConnectionEffects.pulseStrong as PulseEffect;
      expect(effect.minOpacity, equals(0.3));
      expect(effect.maxOpacity, equals(1.0));
      expect(effect.widthVariation, equals(2.0));
    });
  });

  group('Particles', () {
    group('Circle Particles', () {
      test('circle particle is available', () {
        expect(Particles.circle, isNotNull);
        expect(Particles.circle, isA<ParticlePainter>());
        expect(Particles.circle, isA<CircleParticle>());
      });

      test('circleMedium particle is available', () {
        expect(Particles.circleMedium, isNotNull);
        expect(Particles.circleMedium, isA<CircleParticle>());
      });

      test('circleLarge particle is available', () {
        expect(Particles.circleLarge, isNotNull);
        expect(Particles.circleLarge, isA<CircleParticle>());
      });

      test('allCircles contains all circle particles', () {
        expect(Particles.allCircles, hasLength(3));
        expect(
          Particles.allCircles,
          containsAll([
            Particles.circle,
            Particles.circleMedium,
            Particles.circleLarge,
          ]),
        );
      });
    });

    group('Arrow Particles', () {
      test('arrow particle is available', () {
        expect(Particles.arrow, isNotNull);
        expect(Particles.arrow, isA<ParticlePainter>());
        expect(Particles.arrow, isA<ArrowParticle>());
      });

      test('arrowLarge particle is available', () {
        expect(Particles.arrowLarge, isNotNull);
        expect(Particles.arrowLarge, isA<ArrowParticle>());
      });

      test('allArrows contains all arrow particles', () {
        expect(Particles.allArrows, hasLength(2));
        expect(
          Particles.allArrows,
          containsAll([Particles.arrow, Particles.arrowLarge]),
        );
      });
    });

    group('Character Particles', () {
      test('dot particle is available', () {
        expect(Particles.dot, isNotNull);
        expect(Particles.dot, isA<ParticlePainter>());
        expect(Particles.dot, isA<CharacterParticle>());
      });

      test('rightArrow particle is available', () {
        expect(Particles.rightArrow, isNotNull);
        expect(Particles.rightArrow, isA<CharacterParticle>());
      });

      test('allCharacters contains all character particles', () {
        expect(Particles.allCharacters, hasLength(2));
        expect(
          Particles.allCharacters,
          containsAll([Particles.dot, Particles.rightArrow]),
        );
      });
    });

    group('Emoji Particles', () {
      test('rocket particle is available', () {
        expect(Particles.rocket, isNotNull);
        expect(Particles.rocket, isA<ParticlePainter>());
        expect(Particles.rocket, isA<CharacterParticle>());
      });

      test('fire particle is available', () {
        expect(Particles.fire, isNotNull);
        expect(Particles.fire, isA<CharacterParticle>());
      });

      test('star particle is available', () {
        expect(Particles.star, isNotNull);
        expect(Particles.star, isA<CharacterParticle>());
      });

      test('sparkle particle is available', () {
        expect(Particles.sparkle, isNotNull);
        expect(Particles.sparkle, isA<CharacterParticle>());
      });

      test('allEmojis contains all emoji particles', () {
        expect(Particles.allEmojis, hasLength(4));
        expect(
          Particles.allEmojis,
          containsAll([
            Particles.rocket,
            Particles.fire,
            Particles.star,
            Particles.sparkle,
          ]),
        );
      });
    });

    group('All Particles Collection', () {
      test('all contains all built-in particles', () {
        expect(Particles.all, hasLength(11));
        expect(
          Particles.all,
          containsAll([
            ...Particles.allCircles,
            ...Particles.allArrows,
            ...Particles.allCharacters,
            ...Particles.allEmojis,
          ]),
        );
      });
    });
  });

  group('ParticlePainterExtension', () {
    test('isBuiltIn returns true for built-in particles', () {
      expect(Particles.circle.isBuiltIn, isTrue);
      expect(Particles.arrow.isBuiltIn, isTrue);
      expect(Particles.rocket.isBuiltIn, isTrue);
    });

    test('isBuiltIn returns false for custom particles', () {
      final customParticle = CircleParticle(radius: 10.0);
      expect(customParticle.isBuiltIn, isFalse);
    });
  });

  group('CircleParticle', () {
    test('default constructor creates particle with default radius', () {
      const particle = CircleParticle();
      expect(particle.radius, equals(3.0));
      expect(particle.color, isNull);
    });

    test('constructor accepts custom radius', () {
      const particle = CircleParticle(radius: 8.0);
      expect(particle.radius, equals(8.0));
    });

    test('constructor accepts custom color', () {
      const particle = CircleParticle(color: Colors.red);
      expect(particle.color, equals(Colors.red));
    });

    test('size is twice the radius', () {
      const particle = CircleParticle(radius: 5.0);
      expect(particle.size, equals(const Size(10.0, 10.0)));
    });

    test('implements ParticlePainter', () {
      const particle = CircleParticle();
      expect(particle, isA<ParticlePainter>());
    });

    test('radius must be positive', () {
      expect(() => CircleParticle(radius: 0), throwsA(isA<AssertionError>()));
      expect(() => CircleParticle(radius: -1), throwsA(isA<AssertionError>()));
    });
  });

  group('ArrowParticle', () {
    test('default constructor creates particle with default dimensions', () {
      const particle = ArrowParticle();
      expect(particle.length, equals(10.0));
      expect(particle.width, equals(6.0));
      expect(particle.color, isNull);
    });

    test('constructor accepts custom dimensions', () {
      const particle = ArrowParticle(length: 16.0, width: 10.0);
      expect(particle.length, equals(16.0));
      expect(particle.width, equals(10.0));
    });

    test('constructor accepts custom color', () {
      const particle = ArrowParticle(color: Colors.blue);
      expect(particle.color, equals(Colors.blue));
    });

    test('size equals length and width', () {
      const particle = ArrowParticle(length: 12.0, width: 8.0);
      expect(particle.size, equals(const Size(12.0, 8.0)));
    });

    test('implements ParticlePainter', () {
      const particle = ArrowParticle();
      expect(particle, isA<ParticlePainter>());
    });

    test('length must be positive', () {
      expect(() => ArrowParticle(length: 0), throwsA(isA<AssertionError>()));
      expect(() => ArrowParticle(length: -1), throwsA(isA<AssertionError>()));
    });

    test('width must be positive', () {
      expect(() => ArrowParticle(width: 0), throwsA(isA<AssertionError>()));
      expect(() => ArrowParticle(width: -1), throwsA(isA<AssertionError>()));
    });

    test('arrowLarge has larger dimensions', () {
      final standard = Particles.arrow as ArrowParticle;
      final large = Particles.arrowLarge as ArrowParticle;
      expect(large.length, greaterThan(standard.length));
      expect(large.width, greaterThan(standard.width));
    });
  });

  group('CharacterParticle', () {
    test('default constructor creates particle with default values', () {
      final particle = CharacterParticle();
      expect(particle.character, equals('\u25cf')); // Bullet character
      expect(particle.fontSize, equals(12.0));
      expect(particle.color, isNull);
    });

    test('constructor accepts custom character', () {
      final particle = CharacterParticle(character: '\u2192'); // Right arrow
      expect(particle.character, equals('\u2192'));
    });

    test('constructor accepts custom font size', () {
      final particle = CharacterParticle(fontSize: 20.0);
      expect(particle.fontSize, equals(20.0));
    });

    test('constructor accepts custom color', () {
      final particle = CharacterParticle(color: Colors.green);
      expect(particle.color, equals(Colors.green));
    });

    test('implements ParticlePainter', () {
      final particle = CharacterParticle();
      expect(particle, isA<ParticlePainter>());
    });

    test('character must not be empty', () {
      expect(
        () => CharacterParticle(character: ''),
        throwsA(isA<AssertionError>()),
      );
    });

    test('fontSize must be positive', () {
      expect(
        () => CharacterParticle(fontSize: 0),
        throwsA(isA<AssertionError>()),
      );
      expect(
        () => CharacterParticle(fontSize: -1),
        throwsA(isA<AssertionError>()),
      );
    });

    test('size is computed from character and font size', () {
      final particle = CharacterParticle(character: 'X', fontSize: 16.0);
      expect(particle.size.width, greaterThan(0));
      expect(particle.size.height, greaterThan(0));
    });

    test('rocket particle has larger font size', () {
      final rocket = Particles.rocket as CharacterParticle;
      expect(rocket.fontSize, equals(16.0));
    });
  });

  group('Effect Type Verification', () {
    test('all flowing dash effects are FlowingDashEffect type', () {
      for (final effect in ConnectionEffects.allFlowingDash) {
        expect(effect, isA<FlowingDashEffect>());
      }
    });

    test('all particle effects are ParticleEffect type', () {
      for (final effect in ConnectionEffects.allParticles) {
        expect(effect, isA<ParticleEffect>());
      }
    });

    test('all gradient flow effects are GradientFlowEffect type', () {
      for (final effect in ConnectionEffects.allGradientFlow) {
        expect(effect, isA<GradientFlowEffect>());
      }
    });

    test('all pulse effects are PulseEffect type', () {
      for (final effect in ConnectionEffects.allPulse) {
        expect(effect, isA<PulseEffect>());
      }
    });
  });
}
