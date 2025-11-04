import 'dart:ui';

import 'connection_animation_effect.dart';

/// An animation effect that creates a flowing dash pattern along the connection.
///
/// The dashes appear to move along the path, similar to the classic
/// "marching ants" effect commonly used in design tools.
///
/// Example:
/// ```dart
/// connection.animationEffect = FlowingDashEffect(
///   speed: 2.0,
///   dashLength: 10.0,
///   gapLength: 5.0,
/// );
/// ```
class FlowingDashEffect extends ConnectionAnimationEffect {
  /// Creates a flowing dash animation effect.
  ///
  /// Parameters:
  /// - [speed]: Number of complete cycles per animation period. Default: 1
  /// - [dashLength]: Length of each dash in pixels. Default: 10
  /// - [gapLength]: Length of gap between dashes in pixels. Default: 5
  FlowingDashEffect({this.speed = 1, this.dashLength = 10, this.gapLength = 5})
    : assert(speed > 0, 'Speed must be positive'),
      assert(dashLength > 0, 'Dash length must be positive'),
      assert(gapLength > 0, 'Gap length must be positive');

  /// Number of complete pattern cycles per animation period (integer for seamless looping)
  final int speed;

  /// Length of each dash segment in pixels
  final int dashLength;

  /// Length of gap between dash segments in pixels
  final int gapLength;

  @override
  void paint(Canvas canvas, Path path, Paint basePaint, double animationValue) {
    final pathMetrics = path.computeMetrics();

    for (final metric in pathMetrics) {
      final totalDashLength = dashLength + gapLength;

      // Calculate animated offset - pattern moves forward continuously
      // With integer speed, modulo ensures seamless looping (offset=0 at both t=0 and t=1)
      final animationOffset =
          (animationValue * speed * totalDashLength) % totalDashLength;

      // Start drawing from before the path begins, shifted by animation offset
      // As offset increases, starting point moves RIGHT (forward motion)
      double distance = animationOffset - totalDashLength;
      bool isDash = true;

      // Draw dashes along the path
      while (distance < metric.length) {
        final segmentLength = isDash ? dashLength : gapLength;
        final start = distance.clamp(0.0, metric.length);
        final end = (distance + segmentLength).clamp(0.0, metric.length);

        if (isDash && start < end) {
          final extractedPath = metric.extractPath(start, end);
          canvas.drawPath(extractedPath, basePaint);
        }

        distance += segmentLength;
        isDash = !isDash;
      }
    }
  }
}
