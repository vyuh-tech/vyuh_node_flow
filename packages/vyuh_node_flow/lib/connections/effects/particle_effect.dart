import 'dart:ui';

import 'connection_effect.dart';
import 'particle_painter.dart';
import 'particles/circle_particle.dart';

/// An animation effect that shows particles moving along the connection path.
///
/// Creates a visual flow effect where multiple particles travel along the
/// connection, useful for showing data flow or direction. Particles can be
/// customized using different [ParticlePainter] implementations.
///
/// Example:
/// ```dart
/// // Circle particles
/// connection.animationEffect = ParticleEffect(
///   particlePainter: CircleParticle(radius: 4.0),
///   particleCount: 5,
///   speed: 2,
/// );
///
/// // Arrow particles
/// connection.animationEffect = ParticleEffect(
///   particlePainter: ArrowParticle(length: 12.0),
///   particleCount: 3,
///   speed: 1,
/// );
///
/// // Emoji particles
/// connection.animationEffect = ParticleEffect(
///   particlePainter: CharacterParticle(character: '🚀', fontSize: 16.0),
///   particleCount: 3,
///   speed: 1,
/// );
/// ```
class ParticleEffect implements ConnectionEffect {
  /// Creates a particle animation effect.
  ///
  /// Parameters:
  /// - [particlePainter]: The painter to use for rendering particles. If null, defaults to CircleParticle.
  /// - [particleCount]: Number of particles traveling along the path. Default: 3
  /// - [speed]: Number of complete cycles per animation period. Default: 1
  /// - [connectionOpacity]: Opacity of the base connection (0.0-1.0). Default: 0.3
  ParticleEffect({
    ParticlePainter? particlePainter,
    this.particleCount = 3,
    this.speed = 1,
    this.connectionOpacity = 0.3,
  }) : particlePainter = particlePainter ?? const CircleParticle(),
       assert(particleCount > 0, 'Particle count must be positive'),
       assert(speed > 0, 'Speed must be positive'),
       assert(
         connectionOpacity >= 0 && connectionOpacity <= 1.0,
         'Connection opacity must be between 0 and 1',
       );

  /// The painter used to render each particle
  final ParticlePainter particlePainter;

  /// Number of particles traveling along the path
  final int particleCount;

  /// Number of complete cycles per animation period (integer for seamless looping)
  final int speed;

  /// Opacity of the base connection underneath particles (0.0 to 1.0)
  /// 0.0 = invisible, 1.0 = full opacity
  final double connectionOpacity;

  @override
  void paint(Canvas canvas, Path path, Paint basePaint, double animationValue) {
    // Draw the static path first (underneath the particles) with configured opacity
    if (connectionOpacity > 0) {
      final pathPaint = Paint()
        ..color = basePaint.color.withValues(alpha: connectionOpacity)
        ..strokeWidth = basePaint.strokeWidth
        ..style = PaintingStyle.stroke
        ..strokeCap = basePaint.strokeCap
        ..strokeJoin = basePaint.strokeJoin;

      canvas.drawPath(path, pathPaint);
    }

    // Draw particles on top
    final pathMetrics = path.computeMetrics();

    for (final metric in pathMetrics) {
      final pathLength = metric.length;

      // Draw particles evenly distributed along the path
      for (int i = 0; i < particleCount; i++) {
        // Calculate particle position with animation offset
        // For seamless looping: position at t=0 and t=1 must be equivalent (differ by 1.0)
        final particleOffset = i / particleCount;
        final animatedPosition =
            (particleOffset + animationValue * speed) % 1.0;
        final distance = animatedPosition * pathLength;

        // Get the position and tangent at this point on the path
        final tangent = metric.getTangentForOffset(distance);
        if (tangent == null) continue;

        // Draw particle using the custom painter
        particlePainter.paint(canvas, tangent.position, tangent, basePaint);
      }
    }
  }
}
