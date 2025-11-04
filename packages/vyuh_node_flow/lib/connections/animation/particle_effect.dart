import 'dart:ui';

import 'connection_animation_effect.dart';

/// An animation effect that shows particles moving along the connection path.
///
/// Creates a visual flow effect where multiple particles (dots) travel
/// along the connection, useful for showing data flow or direction.
///
/// Example:
/// ```dart
/// connection.animationEffect = ParticleEffect(
///   particleCount: 5,
///   particleSize: 4.0,
///   speed: 1.5,
/// );
/// ```
class ParticleEffect extends ConnectionAnimationEffect {
  /// Creates a particle animation effect.
  ///
  /// Parameters:
  /// - [particleCount]: Number of particles traveling along the path. Default: 3
  /// - [particleSize]: Radius of each particle in pixels. Default: 3
  /// - [speed]: Number of complete cycles per animation period. Default: 1
  /// - [particleColor]: Optional color override for particles. If null, uses basePaint color.
  ParticleEffect({
    this.particleCount = 3,
    this.particleSize = 3,
    this.speed = 1,
    this.particleColor,
  }) : assert(particleCount > 0, 'Particle count must be positive'),
       assert(particleSize > 0, 'Particle size must be positive'),
       assert(speed > 0, 'Speed must be positive');

  /// Number of particles traveling along the path
  final int particleCount;

  /// Radius of each particle in pixels
  final int particleSize;

  /// Number of complete cycles per animation period (integer for seamless looping)
  final int speed;

  /// Optional color override for particles (null = use connection color)
  final Color? particleColor;

  @override
  void paint(Canvas canvas, Path path, Paint basePaint, double animationValue) {
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

        // Draw particle at the calculated position
        final particlePaint = Paint()
          ..color = particleColor ?? basePaint.color
          ..style = PaintingStyle.fill;

        canvas.drawCircle(
          tangent.position,
          particleSize.toDouble(),
          particlePaint,
        );
      }
    }

    // Draw the static path underneath the particles
    final pathPaint = Paint()
      ..color = basePaint.color.withValues(alpha: 0.3)
      ..strokeWidth = basePaint.strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = basePaint.strokeCap
      ..strokeJoin = basePaint.strokeJoin;

    canvas.drawPath(path, pathPaint);
  }
}
