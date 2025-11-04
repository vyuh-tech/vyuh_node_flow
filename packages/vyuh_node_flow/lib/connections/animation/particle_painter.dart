import 'dart:ui';

/// Abstract interface for rendering particles in a ParticleEffect.
///
/// Implement this interface to create custom particle visualizations
/// that can be used with [ParticleEffect].
///
/// Example:
/// ```dart
/// class CustomParticle implements ParticlePainter {
///   @override
///   void paint(Canvas canvas, Offset position, Tangent tangent, Paint basePaint) {
///     // Custom rendering logic
///   }
///
///   @override
///   Size get size => const Size(10, 10);
/// }
/// ```
abstract interface class ParticlePainter {
  /// Paints the particle at the given position along the connection path.
  ///
  /// Parameters:
  /// - [canvas]: The canvas to draw on
  /// - [position]: The center position of the particle
  /// - [tangent]: The path tangent at this position (for directional particles)
  /// - [basePaint]: The base paint from the connection (color, style, etc.)
  void paint(Canvas canvas, Offset position, Tangent tangent, Paint basePaint);

  /// The size of the particle.
  /// Used for layout calculations and bounds checking.
  Size get size;
}
