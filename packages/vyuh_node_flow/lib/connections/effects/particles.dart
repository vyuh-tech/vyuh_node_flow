import 'particle_painter.dart';
import 'particles/arrow_particle.dart';
import 'particles/character_particle.dart';
import 'particles/circle_particle.dart';

/// Built-in particle painters
///
/// This class provides easy access to all the built-in particle painters
/// that can be used with [ParticleEffect].
class Particles {
  // Private constructor to prevent instantiation
  const Particles._();

  // === Built-in Particle Constants ===

  /// Small circular particle (3px radius)
  static const ParticlePainter circle = CircleParticle();

  /// Medium circular particle (5px radius)
  static const ParticlePainter circleMedium = CircleParticle(radius: 5.0);

  /// Large circular particle (8px radius)
  static const ParticlePainter circleLarge = CircleParticle(radius: 8.0);

  /// Standard arrow particle
  static const ParticlePainter arrow = ArrowParticle();

  /// Large arrow particle
  static const ParticlePainter arrowLarge = ArrowParticle(
    length: 16.0,
    width: 10.0,
  );

  /// Dot character particle
  static final ParticlePainter dot = CharacterParticle(character: '●');

  /// Right arrow character particle
  static final ParticlePainter rightArrow = CharacterParticle(character: '→');

  /// Rocket emoji particle
  static final ParticlePainter rocket = CharacterParticle(
    character: '🚀',
    fontSize: 16.0,
  );

  /// Fire emoji particle
  static final ParticlePainter fire = CharacterParticle(
    character: '🔥',
    fontSize: 16.0,
  );

  /// Star emoji particle
  static final ParticlePainter star = CharacterParticle(
    character: '⭐',
    fontSize: 16.0,
  );

  /// Sparkle emoji particle
  static final ParticlePainter sparkle = CharacterParticle(
    character: '✨',
    fontSize: 16.0,
  );

  // === Collections ===

  /// All built-in circle particles
  static const List<ParticlePainter> allCircles = [
    circle,
    circleMedium,
    circleLarge,
  ];

  /// All built-in arrow particles
  static const List<ParticlePainter> allArrows = [arrow, arrowLarge];

  /// All built-in character particles
  static final List<ParticlePainter> allCharacters = [dot, rightArrow];

  /// All built-in emoji particles
  static final List<ParticlePainter> allEmojis = [rocket, fire, star, sparkle];

  /// All built-in particles
  static final List<ParticlePainter> all = [
    ...allCircles,
    ...allArrows,
    ...allCharacters,
    ...allEmojis,
  ];
}

/// Extension to add convenience methods to particle painter instances
extension ParticlePainterExtension on ParticlePainter {
  /// Check if this is a built-in particle
  bool get isBuiltIn => Particles.all.contains(this);
}
