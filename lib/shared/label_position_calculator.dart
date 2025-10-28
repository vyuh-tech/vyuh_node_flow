import 'package:flutter/material.dart';

import '../connections/label_theme.dart';
import '../ports/port.dart';

class LabelPositionCalculator {
  /// Calculates the size of a label including padding
  static Size calculateLabelSize(String text, LabelTheme labelTheme) {
    final textPainter = TextPainter(
      text: TextSpan(text: text, style: labelTheme.textStyle),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();

    final metrics = textPainter.computeLineMetrics().firstOrNull;
    final textHeight = metrics != null
        ? (metrics.unscaledAscent + metrics.descent).ceil()
        : textPainter.height;

    return Size(
      textPainter.width + labelTheme.padding.horizontal,
      textHeight + labelTheme.padding.vertical,
    );
  }

  /// Calculates label position on the outer side of the port, away from the node
  /// Labels are vertically centered on the connection path level
  static Offset calculatePortLabelPosition(
    Offset endpointPos,
    Port? port,
    Size labelSize,
    LabelTheme labelTheme, {
    required bool isEndLabel,
  }) {
    if (port == null) {
      // Default positioning if no port information - center vertically on connection
      return Offset(
        endpointPos.dx - labelSize.width / 2,
        endpointPos.dy - labelSize.height / 2,
      );
    }

    // Position label on the outer side of the port (away from the node)
    // All labels are vertically centered on the connection path
    switch (port.position) {
      case PortPosition.left:
        // Left port: label goes further to the LEFT (away from node)
        return Offset(
          endpointPos.dx - labelTheme.horizontalOffset - labelSize.width,
          endpointPos.dy - labelSize.height / 2, // Centered on connection path
        );

      case PortPosition.right:
        // Right port: label goes further to the RIGHT (away from node)
        return Offset(
          endpointPos.dx + labelTheme.horizontalOffset,
          endpointPos.dy - labelSize.height / 2, // Centered on connection path
        );

      case PortPosition.top:
        // Top port: label goes further UP (away from node)
        return Offset(
          endpointPos.dx - labelSize.width / 2,
          endpointPos.dy -
              labelTheme.verticalOffset -
              labelSize.height / 2, // Centered vertically
        );

      case PortPosition.bottom:
        // Bottom port: label goes further DOWN (away from node)
        return Offset(
          endpointPos.dx - labelSize.width / 2,
          endpointPos.dy +
              labelTheme.verticalOffset -
              labelSize.height / 2, // Centered vertically
        );
    }
  }
}
