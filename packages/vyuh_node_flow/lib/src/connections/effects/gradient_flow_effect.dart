import 'dart:ui';

import 'connection_effect.dart';

/// An animation effect that creates a flowing gradient along the connection.
///
/// The gradient smoothly flows along the path, creating an elegant
/// visual effect that shows direction and movement.
///
/// Example:
/// ```dart
/// connection.animationEffect = GradientFlowEffect(
///   colors: [Colors.blue, Colors.cyan, Colors.blue],
///   speed: 1.0,
/// );
/// ```
class GradientFlowEffect implements ConnectionEffect {
  /// Creates a gradient flow animation effect.
  ///
  /// Parameters:
  /// - [colors]: List of colors for the gradient. Default: null (uses connection color)
  /// - [speed]: Number of complete cycles per animation period. Default: 1
  /// - [gradientLength]: Length of the gradient. If < 1, treated as percentage (0.25 = 25% of path).
  ///                     If >= 1, treated as absolute pixels. Default: 0.25 (25%)
  /// - [connectionOpacity]: Opacity of the base connection (0.0-1.0). Default: 1.0 (no fading)
  GradientFlowEffect({
    this.colors,
    this.speed = 1,
    this.gradientLength = 0.25,
    this.connectionOpacity = 1.0,
  }) : assert(speed > 0, 'Speed must be positive'),
       assert(gradientLength > 0, 'Gradient length must be positive'),
       assert(
         connectionOpacity >= 0 && connectionOpacity <= 1.0,
         'Connection opacity must be between 0 and 1',
       ),
       assert(
         colors == null || colors.length >= 2,
         'Colors list must contain at least 2 colors',
       );

  /// Colors for the gradient. If null, creates a gradient using the connection color.
  final List<Color>? colors;

  /// Number of complete cycles per animation period (integer for seamless looping)
  final int speed;

  /// Length of the gradient.
  /// - If < 1: treated as percentage of path length (0.25 = 25%)
  /// - If >= 1: treated as absolute pixels
  final double gradientLength;

  /// Opacity of the base connection outside the gradient (0.0 to 1.0)
  /// 1.0 = full opacity (no fading), 0.0 = invisible
  final double connectionOpacity;

  @override
  void paint(Canvas canvas, Path path, Paint basePaint, double animationValue) {
    final pathMetrics = path.computeMetrics();

    for (final metric in pathMetrics) {
      final pathLength = metric.length;
      // Interpret gradientLength as percentage if < 1, absolute pixels if >= 1
      final gradientSpan = gradientLength < 1
          ? gradientLength * pathLength
          : gradientLength;

      // Calculate the animated position (moves forward along path, extends beyond end)
      // Scale to go from -gradientSpan to pathLength + gradientSpan so it can fully enter and exit
      final totalRange = pathLength + (2 * gradientSpan);
      // Apply modulo on pixel distance for seamless looping at any speed
      final pixelDistance = (animationValue * speed * totalRange) % totalRange;
      final gradientCenter = pixelDistance - gradientSpan;

      // Calculate start and end of the gradient segment
      final gradientStart = gradientCenter - (gradientSpan / 2);
      final gradientEnd = gradientCenter + (gradientSpan / 2);

      // Only draw if gradient is visible on the path
      if (gradientEnd < 0 || gradientStart > pathLength) {
        // Gradient is completely off the path, draw base connection with configured opacity
        if (connectionOpacity > 0) {
          final basePaintWithOpacity = Paint()
            ..color = basePaint.color.withValues(alpha: connectionOpacity)
            ..strokeWidth = basePaint.strokeWidth
            ..style = PaintingStyle.stroke
            ..strokeCap = basePaint.strokeCap
            ..strokeJoin = basePaint.strokeJoin;
          canvas.drawPath(path, basePaintWithOpacity);
        }
        continue;
      }

      // Clamp to visible portion
      final visibleStart = gradientStart.clamp(0.0, pathLength);
      final visibleEnd = gradientEnd.clamp(0.0, pathLength);

      // Extract the visible gradient segment
      final gradientPath = metric.extractPath(visibleStart, visibleEnd);

      // Get tangent positions for shader direction
      final startTangent = metric.getTangentForOffset(visibleStart);
      final endTangent = metric.getTangentForOffset(visibleEnd);

      if (startTangent == null || endTangent == null) continue;

      // Create gradient colors
      final gradientColors =
          colors ??
          [
            basePaint.color.withValues(alpha: 0.0),
            basePaint.color,
            basePaint.color.withValues(alpha: 0.0),
          ];

      // Generate color stops evenly distributed based on number of colors
      final colorStops = List.generate(
        gradientColors.length,
        (i) => i / (gradientColors.length - 1),
      );

      // Draw the rest of the path first (underneath) with configured opacity
      if (connectionOpacity > 0) {
        final basePaintWithOpacity = Paint()
          ..color = basePaint.color.withValues(alpha: connectionOpacity)
          ..strokeWidth = basePaint.strokeWidth
          ..style = PaintingStyle.stroke
          ..strokeCap = basePaint.strokeCap
          ..strokeJoin = basePaint.strokeJoin;

        if (visibleStart > 0) {
          final beforePath = metric.extractPath(0, visibleStart);
          canvas.drawPath(beforePath, basePaintWithOpacity);
        }

        if (visibleEnd < pathLength) {
          final afterPath = metric.extractPath(visibleEnd, pathLength);
          canvas.drawPath(afterPath, basePaintWithOpacity);
        }
      }

      // Create linear gradient shader along the path segment
      final shader = Gradient.linear(
        startTangent.position,
        endTangent.position,
        gradientColors,
        colorStops,
      );

      // Draw the gradient segment on top
      final gradientPaint = Paint()
        ..shader = shader
        ..strokeWidth = basePaint.strokeWidth
        ..style = PaintingStyle.stroke
        ..strokeCap = basePaint.strokeCap
        ..strokeJoin = basePaint.strokeJoin;

      canvas.drawPath(gradientPath, gradientPaint);
    }
  }
}
