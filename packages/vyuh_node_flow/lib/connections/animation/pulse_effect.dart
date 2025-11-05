import 'dart:math' as math;
import 'dart:ui';

import 'connection_animation_effect.dart';

/// An animation effect that creates a pulsing/glowing effect on the connection.
///
/// The connection pulses by animating its opacity and optionally its width,
/// creating a breathing or glowing effect.
///
/// Example:
/// ```dart
/// connection.animationEffect = PulseEffect(
///   speed: 1,
///   minOpacity: 0.3,
///   maxOpacity: 1.0,
///   widthVariation: 1.5,
/// );
/// ```
class PulseEffect implements ConnectionAnimationEffect {
  /// Creates a pulse animation effect.
  ///
  /// Parameters:
  /// - [speed]: Number of complete pulse cycles per animation period. Default: 1
  /// - [minOpacity]: Minimum opacity during pulse cycle. Default: 0.4
  /// - [maxOpacity]: Maximum opacity during pulse cycle. Default: 1.0
  /// - [widthVariation]: Width multiplier at peak of pulse (1.0 = no variation). Default: 1.0
  PulseEffect({
    this.speed = 1,
    this.minOpacity = 0.4,
    this.maxOpacity = 1.0,
    this.widthVariation = 1.0,
  }) : assert(speed > 0, 'Speed must be positive'),
       assert(
         minOpacity >= 0 && minOpacity <= 1,
         'Min opacity must be between 0 and 1',
       ),
       assert(
         maxOpacity >= 0 && maxOpacity <= 1,
         'Max opacity must be between 0 and 1',
       ),
       assert(minOpacity <= maxOpacity, 'Min opacity must be <= max opacity'),
       assert(widthVariation >= 1.0, 'Width variation must be >= 1.0');

  /// Number of complete pulse cycles per animation period (integer for seamless looping)
  final int speed;

  /// Minimum opacity during the pulse cycle
  final double minOpacity;

  /// Maximum opacity during the pulse cycle
  final double maxOpacity;

  /// Width multiplier at the peak of the pulse (1.0 = no width change)
  final double widthVariation;

  @override
  void paint(Canvas canvas, Path path, Paint basePaint, double animationValue) {
    // Use sine wave for smooth pulsing (0 to 1 and back)
    final pulseProgress =
        (math.sin((animationValue * speed) * 2 * math.pi) + 1) / 2;

    // Calculate animated opacity
    final opacity = minOpacity + (maxOpacity - minOpacity) * pulseProgress;

    // Calculate animated width
    final width =
        basePaint.strokeWidth +
        (basePaint.strokeWidth * (widthVariation - 1.0) * pulseProgress);

    // Create pulsing paint
    final pulsePaint = Paint()
      ..color = basePaint.color.withValues(alpha: opacity)
      ..strokeWidth = width
      ..style = PaintingStyle.stroke
      ..strokeCap = basePaint.strokeCap
      ..strokeJoin = basePaint.strokeJoin;

    canvas.drawPath(path, pulsePaint);

    // Optional: Add a glow effect at peak pulse
    if (pulseProgress > 0.7 && widthVariation > 1.0) {
      final glowPaint = Paint()
        ..color = basePaint.color.withValues(alpha: opacity * 0.3)
        ..strokeWidth = width * 1.5
        ..style = PaintingStyle.stroke
        ..strokeCap = basePaint.strokeCap
        ..strokeJoin = basePaint.strokeJoin
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3.0);

      canvas.drawPath(path, glowPaint);
    }
  }
}
