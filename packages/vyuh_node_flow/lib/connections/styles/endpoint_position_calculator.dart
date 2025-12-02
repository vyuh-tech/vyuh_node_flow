import 'package:flutter/material.dart';

import '../../ports/port.dart';

/// Utility class for calculating endpoint marker and connection line positions.
///
/// This calculator determines the exact positions where endpoint markers should
/// be drawn and where connection lines should start/end, taking into account
/// port positions and endpoint marker dimensions.
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
  /// - [portPos]: The connection point at the port's outer edge (from Node.getPortPosition)
  /// - [portPosition]: The orientation of the port (left, right, top, or bottom)
  /// - [endpointSize]: The size (diameter) of the endpoint marker in logical pixels
  ///
  /// The calculation accounts for:
  /// - Endpoint marker size
  /// - Port orientation to position markers correctly
  ///
  /// Note: With edge-aligned ports, portPos is already at the port's outer edge,
  /// so we only need to offset by the endpoint marker size.
  ///
  /// Returns: A record with `endpointPos` and `linePos` offsets
  static ({Offset endpointPos, Offset linePos}) calculatePortConnectionPoints(
    Offset portPos,
    PortPosition portPosition,
    double endpointSize,
  ) {
    switch (portPosition) {
      case PortPosition.left:
        // Endpoint marker center is half its size to the left of port edge
        final endpointPos = Offset(portPos.dx - endpointSize / 2, portPos.dy);
        // Line starts at the left edge of the endpoint marker
        final linePos = Offset(portPos.dx - endpointSize, portPos.dy);
        return (endpointPos: endpointPos, linePos: linePos);
      case PortPosition.right:
        // Endpoint marker center is half its size to the right of port edge
        final endpointPos = Offset(portPos.dx + endpointSize / 2, portPos.dy);
        // Line starts at the right edge of the endpoint marker
        final linePos = Offset(portPos.dx + endpointSize, portPos.dy);
        return (endpointPos: endpointPos, linePos: linePos);
      case PortPosition.top:
        // Endpoint marker center is half its size above port edge
        final endpointPos = Offset(portPos.dx, portPos.dy - endpointSize / 2);
        // Line starts at the top edge of the endpoint marker
        final linePos = Offset(portPos.dx, portPos.dy - endpointSize);
        return (endpointPos: endpointPos, linePos: linePos);
      case PortPosition.bottom:
        // Endpoint marker center is half its size below port edge
        final endpointPos = Offset(portPos.dx, portPos.dy + endpointSize / 2);
        // Line starts at the bottom edge of the endpoint marker
        final linePos = Offset(portPos.dx, portPos.dy + endpointSize);
        return (endpointPos: endpointPos, linePos: linePos);
    }
  }
}
