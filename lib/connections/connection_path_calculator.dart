import 'package:flutter/material.dart';

import '../ports/port.dart';
import 'connection_style_base.dart';
import 'connection_styles.dart';

class ConnectionPathCalculator {
  /// Creates a connection path based on the connection style and parameters
  ///
  /// This method now delegates to the polymorphic connection style classes
  /// instead of using switch statements. This allows for better extensibility
  /// and custom connection styles.
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

  /// Resolve the connection style parameter to a ConnectionStyle instance
  ///
  /// This method handles backward compatibility by accepting both legacy enum
  /// values and new ConnectionStyle instances. It converts enum values to
  /// their corresponding style instances.
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
