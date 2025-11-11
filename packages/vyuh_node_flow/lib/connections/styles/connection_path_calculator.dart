import 'package:flutter/material.dart';

import '../../ports/port.dart';
import 'connection_style_base.dart';
import 'connection_styles.dart';

/// Utility class for creating connection paths from style definitions.
///
/// This calculator serves as a facade for the polymorphic [ConnectionStyle]
/// system, providing a simple static method to create paths while handling
/// backward compatibility and style resolution.
///
/// ## Design Pattern
/// This class uses the Strategy pattern, delegating path creation to the
/// appropriate [ConnectionStyle] implementation based on the provided style
/// parameter.
///
/// ## Usage Example
/// ```dart
/// final path = ConnectionPathCalculator.createConnectionPath(
///   style: ConnectionStyles.smoothstep,
///   start: Offset(10, 20),
///   end: Offset(100, 80),
///   curvature: 0.5,
///   sourcePort: outputPort,
///   targetPort: inputPort,
/// );
/// ```
///
/// See also:
/// - [ConnectionStyle] for the base style interface
/// - [ConnectionStyles] for built-in style constants
/// - [PathParameters] for path creation parameters
class ConnectionPathCalculator {
  /// Creates a connection path based on the connection style and parameters.
  ///
  /// This method delegates to the polymorphic connection style classes
  /// instead of using switch statements, allowing for better extensibility
  /// and support for custom connection styles.
  ///
  /// Parameters:
  /// - [style]: The connection style (can be [ConnectionStyle] instance or string ID)
  /// - [start]: Start point of the connection in logical pixels
  /// - [end]: End point of the connection in logical pixels
  /// - [curvature]: Curvature factor for bezier-style connections (0.0 to 1.0)
  /// - [sourcePort]: Optional source port for position-aware path creation
  /// - [targetPort]: Optional target port for position-aware path creation
  /// - [cornerRadius]: Radius for rounded corners in step-style connections
  /// - [offset]: Offset distance from ports in logical pixels
  ///
  /// Returns: A [Path] object representing the connection geometry
  ///
  /// Example:
  /// ```dart
  /// // Using a built-in style constant
  /// final bezierPath = ConnectionPathCalculator.createConnectionPath(
  ///   style: ConnectionStyles.bezier,
  ///   start: Offset(0, 0),
  ///   end: Offset(100, 100),
  ///   curvature: 0.5,
  /// );
  ///
  /// // Using a style ID string
  /// final stepPath = ConnectionPathCalculator.createConnectionPath(
  ///   style: 'step',
  ///   start: Offset(0, 0),
  ///   end: Offset(100, 100),
  ///   curvature: 0.3,
  ///   cornerRadius: 8.0,
  /// );
  /// ```
  static Path createConnectionPath({
    required dynamic style, // Accept both old enum and new class instances
    required Offset start,
    required Offset end,
    required double curvature,
    Port? sourcePort,
    Port? targetPort,
    double cornerRadius = 4.0,
    double offset = 10.0,
  }) {
    // Convert style to connection style instance if it's still an enum
    final ConnectionStyle connectionStyle = _resolveConnectionStyle(style);

    // Create path parameters
    final params = PathParameters(
      start: start,
      end: end,
      curvature: curvature,
      sourcePort: sourcePort,
      targetPort: targetPort,
      cornerRadius: cornerRadius,
      offset: offset,
    );

    // Delegate to the connection style's createPath method
    return connectionStyle.createPath(params);
  }

  /// Resolves a connection style parameter to a [ConnectionStyle] instance.
  ///
  /// This method handles backward compatibility by accepting both legacy enum
  /// values, string IDs, and new [ConnectionStyle] instances. It converts
  /// string IDs to their corresponding style instances.
  ///
  /// Parameters:
  /// - [style]: Can be a [ConnectionStyle] instance or a string ID
  ///
  /// Returns: A [ConnectionStyle] instance, defaulting to [ConnectionStyles.smoothstep]
  /// if the style cannot be resolved
  static ConnectionStyle _resolveConnectionStyle(dynamic style) {
    // If it's already a ConnectionStyle instance, return it directly
    if (style is ConnectionStyle) {
      return style;
    }

    // If it's a string ID, try to find the built-in style
    if (style is String) {
      final foundStyle = ConnectionStyles.findById(style);
      if (foundStyle != null) {
        return foundStyle;
      }
    }

    // Default fallback to smoothstep if the style is unrecognized
    return ConnectionStyles.smoothstep;
  }
}
