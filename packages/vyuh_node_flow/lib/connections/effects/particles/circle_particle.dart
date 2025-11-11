import 'dart:ui';

import '../particle_painter.dart';

/// A circular particle painter.
///
/// Renders particles as simple filled circles, useful for basic
/// flow visualization and data movement indication.
///
/// Example:
/// ```dart
/// ParticleEffect(
///   particlePainter: CircleParticle(radius: 4.0),
///   particleCount: 5,
///   speed: 2,
/// )
/// ```
class CircleParticle implements ParticlePainter {
  /// Creates a circular particle painter.
  ///
  /// Parameters:
  /// - [radius]: The radius of the circle in pixels. Default: 3.0
  /// - [color]: Optional color override. If null, uses connection color.
  const CircleParticle({this.radius = 3.0, this.color})
    : assert(radius > 0, 'Radius must be positive');

  /// The radius of the circle in pixels
  final double radius;

  /// Optional color override for the particle (null = use connection color)
  final Color? color;

  @override
  void paint(Canvas canvas, Offset position, Tangent tangent, Paint basePaint) {
    final particlePaint = Paint()
      ..color = color ?? basePaint.color
      ..style = PaintingStyle.fill;

    canvas.drawCircle(position, radius, particlePaint);
  }

  @override
  Size get size => Size(radius * 2, radius * 2);
}
