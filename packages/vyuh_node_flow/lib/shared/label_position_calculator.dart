import 'package:flutter/material.dart';

import '../connections/label_theme.dart';
import '../ports/port.dart';

/// A utility class for calculating label positions and sizes for connection labels.
///
/// This class provides static methods to:
/// - Calculate the rendered size of labels including padding
/// - Position labels relative to ports in a way that avoids overlapping with nodes
///
/// Labels are positioned on the outer side of ports (away from the node they're
/// connected to) and are vertically centered on the connection path for optimal
/// readability.
///
/// Example usage:
/// ```dart
/// final labelSize = LabelPositionCalculator.calculateLabelSize(
///   'My Label',
///   labelTheme,
/// );
///
/// final labelPosition = LabelPositionCalculator.calculatePortLabelPosition(
///   portPosition,
///   port,
///   labelSize,
///   labelTheme,
///   isEndLabel: true,
/// );
/// ```
///
/// See also:
/// - [LabelTheme], which defines styling and spacing for labels
/// - [Port], which defines the connection points on nodes
class LabelPositionCalculator {
  /// Calculates the size of a label including padding.
  ///
  /// This method uses Flutter's [TextPainter] to accurately measure the rendered
  /// size of the text based on the provided [labelTheme]. The returned size includes
  /// both the text dimensions and any padding defined in the theme.
  ///
  /// The height calculation uses line metrics when available for more accurate
  /// vertical sizing, which is especially important for proper vertical alignment.
  ///
  /// Parameters:
  /// - [text]: The text content to measure
  /// - [labelTheme]: The theme containing text style and padding information
  ///
  /// Returns a [Size] representing the total dimensions needed to render the label.
  ///
  /// Example:
  /// ```dart
  /// final labelTheme = LabelTheme(
  ///   textStyle: TextStyle(fontSize: 12),
  ///   padding: EdgeInsets.all(4),
  /// );
  /// final size = LabelPositionCalculator.calculateLabelSize(
  ///   'Hello World',
  ///   labelTheme,
  /// );
  /// // size.width includes text width + horizontal padding
  /// // size.height includes text height + vertical padding
  /// ```
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

  /// Calculates the optimal position for a label relative to a port.
  ///
  /// This method positions labels on the outer side of ports (away from the node
  /// center) to prevent overlap with node content. Labels are vertically centered
  /// on the connection path for better readability.
  ///
  /// The positioning logic varies based on the port's position:
  /// - **Left ports**: Label is placed to the left of the port
  /// - **Right ports**: Label is placed to the right of the port
  /// - **Top ports**: Label is placed above the port
  /// - **Bottom ports**: Label is placed below the port
  ///
  /// If no port information is available, the label is centered on the endpoint.
  ///
  /// Parameters:
  /// - [endpointPos]: The position of the connection endpoint (port location)
  /// - [port]: The port object containing position information, or null
  /// - [labelSize]: The size of the label (from [calculateLabelSize])
  /// - [labelTheme]: The theme containing offset information
  /// - [isEndLabel]: Whether this is an end label (vs. start label) on the connection
  ///
  /// Returns an [Offset] representing the top-left corner position for the label.
  ///
  /// Example:
  /// ```dart
  /// final port = Port(
  ///   id: 'output-1',
  ///   position: PortPosition.right,
  ///   offset: Offset(100, 50),
  /// );
  ///
  /// final labelPosition = LabelPositionCalculator.calculatePortLabelPosition(
  ///   Offset(150, 50),  // Endpoint position
  ///   port,
  ///   Size(80, 20),     // Label size
  ///   labelTheme,
  ///   isEndLabel: false,
  /// );
  /// // For a right port, label will be positioned to the right of the endpoint
  /// ```
  ///
  /// See also:
  /// - [PortPosition], which defines the possible port positions
  /// - [LabelTheme.horizontalOffset], used for left/right port spacing
  /// - [LabelTheme.verticalOffset], used for top/bottom port spacing
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
