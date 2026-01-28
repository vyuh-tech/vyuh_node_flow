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
///   endpointSize: Size.square(5.0),
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
  /// - [endpointSize]: The size of the endpoint marker (width and height) in logical pixels
  /// - [gap]: Optional gap between the port and the endpoint marker (default: 0)
  ///
  /// The calculation accounts for:
  /// - Gap distance between port and endpoint (applied first)
  /// - Endpoint marker size (width for horizontal, height for vertical orientations)
  /// - Port orientation to position markers correctly
  ///
  /// Note: With edge-aligned ports, portPos is already at the port's outer edge,
  /// so we offset by the gap first, then by the endpoint marker size.
  ///
  /// Returns: A record with `endpointPos` and `linePos` offsets
  static ({Offset endpointPos, Offset linePos}) calculatePortConnectionPoints(
    Offset portPos,
    PortPosition portPosition,
    Size endpointSize, {
    double gap = 0.0,
  }) {
    switch (portPosition) {
      case PortPosition.left:
        // For horizontal orientation, use width
        // First apply gap, then position endpoint marker
        final gapOffset = portPos.dx - gap;
        final endpointPos = Offset(
          gapOffset - endpointSize.width / 2,
          portPos.dy,
        );
        // Line starts at the left edge of the endpoint marker
        final linePos = Offset(gapOffset - endpointSize.width, portPos.dy);
        return (endpointPos: endpointPos, linePos: linePos);
      case PortPosition.right:
        // For horizontal orientation, use width
        // First apply gap, then position endpoint marker
        final gapOffset = portPos.dx + gap;
        final endpointPos = Offset(
          gapOffset + endpointSize.width / 2,
          portPos.dy,
        );
        // Line starts at the right edge of the endpoint marker
        final linePos = Offset(gapOffset + endpointSize.width, portPos.dy);
        return (endpointPos: endpointPos, linePos: linePos);
      case PortPosition.top:
        // For vertical orientation, use height
        // First apply gap, then position endpoint marker
        final gapOffset = portPos.dy - gap;
        final endpointPos = Offset(
          portPos.dx,
          gapOffset - endpointSize.height / 2,
        );
        // Line starts at the top edge of the endpoint marker
        final linePos = Offset(portPos.dx, gapOffset - endpointSize.height);
        return (endpointPos: endpointPos, linePos: linePos);
      case PortPosition.bottom:
        // For vertical orientation, use height
        // First apply gap, then position endpoint marker
        final gapOffset = portPos.dy + gap;
        final endpointPos = Offset(
          portPos.dx,
          gapOffset + endpointSize.height / 2,
        );
        // Line starts at the bottom edge of the endpoint marker
        final linePos = Offset(portPos.dx, gapOffset + endpointSize.height);
        return (endpointPos: endpointPos, linePos: linePos);
    }
  }

  /// Calculates endpoint positions for a bidirectional port.
  ///
  /// Bidirectional ports can connect in either direction. The endpoint position
  /// is calculated based on the **effective direction** (the direction the line
  /// should extend), not the physical port position.
  ///
  /// Parameters:
  /// - [portPos]: The connection point at the port's physical location
  /// - [physicalPosition]: The port's physical position on the node edge
  /// - [effectiveDirection]: The direction the line should extend (toward target)
  /// - [endpointSize]: Size of the endpoint marker
  /// - [gap]: Gap between port and endpoint marker
  static ({Offset endpointPos, Offset linePos})
  calculateBidirectionalPortConnectionPoints(
    Offset portPos,
    PortPosition physicalPosition,
    PortPosition effectiveDirection,
    Size endpointSize, {
    double gap = 0.0,
  }) {
    // Always use the EFFECTIVE direction for calculating endpoint positions.
    // This ensures the endpoint marker and line position are oriented correctly
    // based on where the connection is actually going, not where the port
    // physically sits on the node.
    //
    // Example: A LEFT-side bidi port connecting to a target on the RIGHT
    // should have its endpoint calculated as if exiting rightward.
    return calculatePortConnectionPoints(
      portPos,
      effectiveDirection,
      endpointSize,
      gap: gap,
    );
  }
}
