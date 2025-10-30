import 'package:flutter/material.dart';

import '../ports/port.dart';

class EndpointPositionCalculator {
  /// Calculates endpoint and line positions for a port connection
  /// Returns {endpointPos, linePos} where endpointPos is the center of the endpoint
  /// and linePos is where the connection line should start/end
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
