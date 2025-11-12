import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../ports/port.dart';

/// Parameters for connection path creation
class ConnectionPathParameters {
  const ConnectionPathParameters({
    required this.start,
    required this.end,
    required this.curvature,
    this.sourcePort,
    this.targetPort,
    this.cornerRadius = 4.0,
    this.offset = 10.0,
  });

  /// Start point of the connection
  final Offset start;

  /// End point of the connection
  final Offset end;

  /// Curvature parameter for bezier curves (0.0 to 1.0)
  final double curvature;

  /// Source port information (optional)
  final Port? sourcePort;

  /// Target port information (optional)
  final Port? targetPort;

  /// Corner radius for rounded connections
  final double cornerRadius;

  /// Offset distance from ports
  final double offset;

  /// Get source port position, defaulting to right if not specified
  PortPosition get sourcePosition => sourcePort?.position ?? PortPosition.right;

  /// Get target port position, defaulting to left if not specified
  PortPosition get targetPosition => targetPort?.position ?? PortPosition.left;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ConnectionPathParameters &&
          runtimeType == other.runtimeType &&
          start == other.start &&
          end == other.end &&
          curvature == other.curvature &&
          sourcePort == other.sourcePort &&
          targetPort == other.targetPort &&
          cornerRadius == other.cornerRadius &&
          offset == other.offset;

  @override
  int get hashCode => Object.hash(
    start,
    end,
    curvature,
    sourcePort,
    targetPort,
    cornerRadius,
    offset,
  );
}

/// Abstract base class for connection styles
///
/// Each connection style encapsulates its own:
/// - Path creation logic
/// - Hit testing capabilities
/// - Bend detection parameters
/// - Optimization strategies
abstract class ConnectionStyle {
  const ConnectionStyle();

  /// Unique identifier for this connection style
  String get id;

  /// Human-readable display name
  String get displayName;

  // === Core Path Creation ===

  /// Creates the geometric path for drawing this connection
  /// This is the main responsibility of each connection style
  Path createPath(ConnectionPathParameters params);

  // === Hit Testing ===

  /// Default hit tolerance for this connection style
  /// Some styles may need different tolerances based on their geometry
  double get defaultHitTolerance => 8.0;

  /// Creates an expanded path for hit testing
  /// The base implementation provides a simple stroke-based expansion
  Path createHitTestPath(Path originalPath, double tolerance) {
    return _createSimpleStrokeHitTestPath(originalPath, tolerance);
  }

  // === Bend Detection (for caching optimization) ===

  /// Whether this connection style needs bend detection for hit testing optimization
  bool get needsBendDetection => true;

  /// Whether this connection style has predictable bend points that can be calculated exactly
  bool get hasExactBendPoints => false;

  /// Get exact bend points for styles that support it (e.g., step connections)
  /// Returns null if the style doesn't support exact bend point calculation
  List<Offset>? getExactBendPoints(ConnectionPathParameters params) => null;

  /// Get bend detection threshold angle in radians
  /// Used for detecting significant direction changes in the path
  double get bendThreshold => math.pi / 6; // 30 degrees default

  /// Get number of samples to use for bend detection based on path length
  int getSampleCount(double pathLength) {
    return math.min(15, math.max(3, (pathLength / 30).ceil()));
  }

  /// Get minimum distance between bend points as multiplier of tolerance
  double get minBendDistance => 4.0;

  // === Style Comparison ===

  /// Check if two connection styles are equivalent
  /// This is used for caching decisions and theme comparisons
  bool isEquivalentTo(ConnectionStyle other) {
    return runtimeType == other.runtimeType && id == other.id;
  }

  // === Helper Methods ===

  /// Creates a simple stroke-based hit test path (fallback implementation)
  Path _createSimpleStrokeHitTestPath(Path originalPath, double tolerance) {
    final bounds = originalPath.getBounds();

    if (bounds.width <= 0 && bounds.height <= 0) {
      return Path();
    }

    // Simple approach: inflate the bounding rectangle
    // Subclasses can override createHitTestPath for more sophisticated approaches
    return Path()..addRect(bounds.inflate(tolerance));
  }

  // === Factory Methods (for backward compatibility) ===

  /// Convert from legacy enum values to connection style instances
  static ConnectionStyle fromEnum(dynamic enumValue) {
    // This will be implemented once we have the concrete classes
    throw UnimplementedError(
      'fromEnum will be implemented with concrete classes',
    );
  }

  @override
  String toString() => 'ConnectionStyle(id: $id, displayName: $displayName)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ConnectionStyle &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => Object.hash(runtimeType, id);
}
