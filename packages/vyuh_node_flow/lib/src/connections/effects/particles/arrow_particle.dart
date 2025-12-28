import 'dart:math' as math;
import 'dart:ui';

import '../particle_painter.dart';

/// An arrow-shaped particle painter.
///
/// Renders particles as directional arrows that rotate to follow
/// the path tangent, providing clear visual indication of flow direction.
///
/// Example:
/// ```dart
/// ParticleEffect(
///   particlePainter: ArrowParticle(
///     length: 12.0,
///     width: 8.0,
///   ),
///   particleCount: 3,
///   speed: 1,
/// )
/// ```
class ArrowParticle implements ParticlePainter {
  /// Creates an arrow particle painter.
  ///
  /// Parameters:
  /// - [length]: The length of the arrow in pixels. Default: 10.0
  /// - [width]: The width of the arrow head in pixels. Default: 6.0
  /// - [color]: Optional color override. If null, uses connection color.
  const ArrowParticle({this.length = 10.0, this.width = 6.0, this.color})
    : assert(length > 0, 'Length must be positive'),
      assert(width > 0, 'Width must be positive');

  /// The length of the arrow in pixels
  final double length;

  /// The width of the arrow head in pixels
  final double width;

  /// Optional color override for the particle (null = use connection color)
  final Color? color;

  @override
  void paint(Canvas canvas, Offset position, Tangent tangent, Paint basePaint) {
    final particlePaint = Paint()
      ..color = color ?? basePaint.color
      ..style = PaintingStyle.fill;

    // Calculate rotation angle from tangent
    final angle = math.atan2(tangent.vector.dy, tangent.vector.dx);

    // Save canvas state
    canvas.save();

    // Translate to position and rotate
    canvas.translate(position.dx, position.dy);
    canvas.rotate(angle);

    // Draw simple triangle arrow (pointing right by default)
    final arrowPath = Path()
      ..moveTo(length / 2, 0) // Arrow tip (front)
      ..lineTo(-length / 2, -width / 2) // Top back corner
      ..lineTo(-length / 2, width / 2) // Bottom back corner
      ..close();

    canvas.drawPath(arrowPath, particlePaint);

    // Restore canvas state
    canvas.restore();
  }

  @override
  Size get size => Size(length, width);
}
