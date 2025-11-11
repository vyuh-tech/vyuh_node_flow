import 'dart:ui';

/// Abstract interface for connection animation effects.
///
/// Custom animation effects can be created by implementing this interface.
/// Each effect encapsulates its own configuration and rendering logic.
///
/// Example:
/// ```dart
/// class MyCustomEffect implements ConnectionEffect {
///   MyCustomEffect({required this.customParam});
///
///   final double customParam;
///
///   @override
///   void paint(Canvas canvas, Path path, Paint basePaint, double animationValue) {
///     // Custom animation rendering logic
///   }
/// }
/// ```
abstract interface class ConnectionEffect {
  /// Paints the animated connection effect on the canvas.
  ///
  /// Parameters:
  /// - [canvas]: The canvas to draw on
  /// - [path]: The connection path (pre-computed and cached)
  /// - [basePaint]: The base paint object with color, stroke width, etc.
  /// - [animationValue]: The current animation value (0.0 to 1.0, repeating)
  ///
  /// Implementations should use [animationValue] to create continuous
  /// animations. The value continuously cycles from 0.0 to 1.0.
  void paint(Canvas canvas, Path path, Paint basePaint, double animationValue);
}
