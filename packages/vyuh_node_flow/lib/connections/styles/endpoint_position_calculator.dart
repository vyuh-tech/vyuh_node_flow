import 'package:flutter/material.dart';

import '../../ports/port.dart';

/// Utility class for calculating endpoint marker and connection line positions.
///
/// This calculator determines the exact positions where endpoint markers should
/// be drawn and where connection lines should start/end, taking into account
/// port positions, sizes, and endpoint marker dimensions.
///
/// ## Purpose
/// When rendering connections, we need to:
/// 1. Position the endpoint marker (arrow, circle, etc.) just outside the port
/// 2. Ensure the connection line starts/ends at the edge of the endpoint marker
/// 3. Account for port orientation (left, right, top, bottom)
///
/// ## Usage Example
/// ```dart
/// final points = EndpointPositionCalculator.calculatePortConnectionPoints(
///   portPos: Offset(100, 50),
///   portPosition: PortPosition.right,
///   endpointSize: 5.0,
///   portSize: 8.0,
/// );
///
/// // Draw endpoint marker at points.endpointPos
/// // Start connection line at points.linePos
/// ```
///
/// See also:
/// - [ConnectionEndPoint] for endpoint marker configuration
/// - [PortPosition] for port orientations
class EndpointPositionCalculator {
  /// Calculates endpoint marker and line positions for a port connection.
  ///
  /// Returns a record containing:
  /// - `endpointPos`: The center position where the endpoint marker should be drawn
  /// - `linePos`: The position where the connection line should start/end
  ///
  /// Parameters:
  /// - [portPos]: The center position of the port in logical pixels
  /// - [portPosition]: The orientation of the port (left, right, top, or bottom)
  /// - [endpointSize]: The size (diameter) of the endpoint marker in logical pixels
  /// - [portSize]: The size (diameter) of the port in logical pixels
  ///
  /// The calculation accounts for:
  /// - Port radius (portSize / 2)
  /// - Endpoint marker size
  /// - Port orientation to position markers correctly
  ///
  /// Returns: A record with `endpointPos` and `linePos` offsets
  static ({Offset endpointPos, Offset linePos}) calculatePortConnectionPoints(
    Offset portPos,
    PortPosition portPosition,
    double endpointSize,
    double portSize,
  ) {
    // Port radius is half the port size
    final portRadius = portSize / 2;

    switch (portPosition) {
      case PortPosition.left:
        // Endpoint starts at the left edge of the port
        final endpointPos = Offset(
          portPos.dx - portRadius - endpointSize / 2,
          portPos.dy,
        );
        final linePos = Offset(
          portPos.dx - portRadius - endpointSize,
          portPos.dy,
        );
        return (endpointPos: endpointPos, linePos: linePos);
      case PortPosition.right:
        // Endpoint starts at the right edge of the port
        final endpointPos = Offset(
          portPos.dx + portRadius + endpointSize / 2,
          portPos.dy,
        );
        final linePos = Offset(
          portPos.dx + portRadius + endpointSize,
          portPos.dy,
        );
        return (endpointPos: endpointPos, linePos: linePos);
      case PortPosition.top:
        // Endpoint starts at the top edge of the port
        final endpointPos = Offset(
          portPos.dx,
          portPos.dy - portRadius - endpointSize / 2,
        );
        final linePos = Offset(
          portPos.dx,
          portPos.dy - portRadius - endpointSize,
        );
        return (endpointPos: endpointPos, linePos: linePos);
      case PortPosition.bottom:
        // Endpoint starts at the bottom edge of the port
        final endpointPos = Offset(
          portPos.dx,
          portPos.dy + portRadius + endpointSize / 2,
        );
        final linePos = Offset(
          portPos.dx,
          portPos.dy + portRadius + endpointSize,
        );
        return (endpointPos: endpointPos, linePos: linePos);
    }
  }
}
