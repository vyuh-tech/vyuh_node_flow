import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../connection.dart' show Connection;
import '../connection_label.dart';
import '../connection_path_cache.dart';
import '../label_theme.dart';
import '../../nodes/node.dart';
import '../../ports/port.dart';
import 'connection_style_base.dart';
import 'endpoint_position_calculator.dart';

/// Utility class for calculating connection label positions.
///
/// This calculator determines the exact rectangular bounds for connection labels
/// positioned anywhere along the connection path using anchor values (0.0-1.0)
/// and perpendicular offsets.
///
/// ## Key Features
/// - **Arbitrary positioning**: Labels can be placed at any point (0.0-1.0) along the path
/// - **Perpendicular offset**: Labels can be offset perpendicular to the path direction
/// - **Path-accurate**: Uses actual connection path geometry for precise positioning
/// - **Multiple labels**: Supports any number of labels per connection
///
/// ## Usage Example
/// ```dart
/// final labelRects = EdgeLabelPositionCalculator.calculateAllLabelPositions(
///   connection: myConnection,
///   sourceNode: sourceNode,
///   targetNode: targetNode,
///   connectionStyle: ConnectionStyles.smoothstep,
///   curvature: 0.5,
///   portSize: 8.0,
///   endpointSize: Size.square(5.0),
///   labelTheme: myLabelTheme,
/// );
///
/// // Render each label at its calculated position
/// for (final rect in labelRects) {
///   // Draw label at rect
/// }
/// ```
///
/// See also:
/// - [ConnectionLabel] for label configuration
/// - [LabelTheme] for label styling
/// - [Connection] for label management
class LabelCalculator {
  /// Calculates all label positions for a connection.
  ///
  /// This is the main entry point that orchestrates the calculation of all
  /// label positions for a connection's labels list.
  ///
  /// Parameters:
  /// - [connection]: The connection whose labels to position
  /// - [sourceNode]: The source node of the connection
  /// - [targetNode]: The target node of the connection
  /// - [connectionStyle]: The style used to render the connection
  /// - [curvature]: Curvature factor for the connection (0.0 to 1.0)
  /// - [endpointSize]: Size of the endpoint markers (width and height) in logical pixels
  /// - [labelTheme]: Theme defining label appearance
  /// - [pathCache]: Optional path cache to reuse cached connection paths
  ///
  /// Returns: A list of [Rect]s corresponding to each label in connection.labels,
  /// or an empty list if the calculation fails (e.g., ports not found)
  ///
  /// The method:
  /// 1. Finds the source and target ports on their respective nodes
  /// 2. Calculates port positions and endpoint positions
  /// 3. Gets or creates the connection path (using cache if provided)
  /// 4. For each label, calculates its position based on anchor and offset
  static List<Rect> calculateAllLabelPositions({
    required Connection connection,
    required Node sourceNode,
    required Node targetNode,
    required ConnectionStyle connectionStyle,
    required double curvature,
    required Size endpointSize,
    required LabelTheme labelTheme,
    ConnectionPathCache? pathCache,
    double portExtension = 10.0,
    double startGap = 0.0,
    double endGap = 0.0,
  }) {
    try {
      // Find the actual port objects first (needed for their sizes)
      Port? sourcePort;
      Port? targetPort;

      try {
        sourcePort = [
          ...sourceNode.inputPorts,
          ...sourceNode.outputPorts,
        ].firstWhere((port) => port.id == connection.sourcePortId);
      } catch (e) {
        // Source port not found
      }

      try {
        targetPort = [
          ...targetNode.inputPorts,
          ...targetNode.outputPorts,
        ].firstWhere((port) => port.id == connection.targetPortId);
      } catch (e) {
        // Target port not found
      }

      // Get port positions using each port's size
      final sourcePortPosition = sourceNode.getPortPosition(
        connection.sourcePortId,
        portSize: sourcePort?.size ?? defaultPortSize,
      );
      final targetPortPosition = targetNode.getPortPosition(
        connection.targetPortId,
        portSize: targetPort?.size ?? defaultPortSize,
      );

      // Calculate endpoint positions using the existing utility
      final source = EndpointPositionCalculator.calculatePortConnectionPoints(
        sourcePortPosition,
        sourcePort?.position ?? PortPosition.right,
        endpointSize,
        gap: startGap,
      );
      final target = EndpointPositionCalculator.calculatePortConnectionPoints(
        targetPortPosition,
        targetPort?.position ?? PortPosition.left,
        endpointSize,
        gap: endGap,
      );

      // Get or create the connection path
      // Use cache if provided, otherwise create a new path
      Path? connectionPath;
      if (pathCache != null) {
        connectionPath = pathCache.getOrCreatePath(
          connection: connection,
          sourceNode: sourceNode,
          targetNode: targetNode,
          connectionStyle: connectionStyle,
        );
      } else {
        final pathParams = ConnectionPathParameters(
          start: source.linePos,
          end: target.linePos,
          curvature: curvature,
          sourcePort: sourcePort,
          targetPort: targetPort,
          offset: portExtension,
        );
        final segmentResult = connectionStyle.createSegments(pathParams);
        connectionPath = connectionStyle.buildPath(
          segmentResult.start,
          segmentResult.segments,
        );
      }

      if (connectionPath == null) {
        return [];
      }

      // Calculate rect for each label
      final labelRects = <Rect>[];
      for (final label in connection.labels) {
        final rect = _calculateLabelRect(
          label: label,
          connectionPath: connectionPath,
          labelTheme: labelTheme,
          portExtension: portExtension,
        );
        if (rect != null) {
          labelRects.add(rect);
        }
      }

      return labelRects;
    } catch (e) {
      return [];
    }
  }

  /// Calculates a position at an arbitrary point along a connection.
  ///
  /// This method finds the exact point at a given anchor value (0.0-1.0)
  /// along the connection path. Useful for custom positioning logic.
  ///
  /// Parameters:
  /// - [connectionStyle]: The style used to create the connection path
  /// - [start]: Start point of the connection line (after endpoint marker)
  /// - [end]: End point of the connection line (before endpoint marker)
  /// - [anchor]: Position along path (0.0 = start, 1.0 = end, 0.5 = center)
  /// - [curvature]: Curvature factor for bezier-style connections
  /// - [sourcePort]: Optional source port for position-aware path creation
  /// - [targetPort]: Optional target port for position-aware path creation
  /// - [portExtension]: Distance connections extend from ports (default: 10.0)
  ///
  /// Returns: The offset at the specified anchor point
  ///
  /// If path calculation fails, returns a linear interpolation between start and end.
  static Offset calculatePositionAtAnchor({
    required ConnectionStyle connectionStyle,
    required Offset start,
    required Offset end,
    required double anchor,
    required double curvature,
    Port? sourcePort,
    Port? targetPort,
    double portExtension = 10.0,
  }) {
    try {
      // Create the connection path
      final pathParams = ConnectionPathParameters(
        start: start,
        end: end,
        curvature: curvature,
        sourcePort: sourcePort,
        targetPort: targetPort,
        offset: portExtension,
      );
      final segmentResult = connectionStyle.createSegments(pathParams);
      final connectionPath = connectionStyle.buildPath(
        segmentResult.start,
        segmentResult.segments,
      );

      final pathMetricsList = connectionPath.computeMetrics().toList();
      if (pathMetricsList.isEmpty) {
        return Offset.lerp(start, end, anchor)!;
      }

      final pathMetric = pathMetricsList.first;
      if (pathMetric.length <= 0) {
        return Offset.lerp(start, end, anchor)!;
      }

      // Get the point at the specified anchor
      final distance = anchor * pathMetric.length;
      final tangent = pathMetric.getTangentForOffset(distance);

      if (tangent == null) {
        return Offset.lerp(start, end, anchor)!;
      }

      return tangent.position;
    } catch (e) {
      // Fallback to linear interpolation
      return Offset.lerp(start, end, anchor)!;
    }
  }

  /// Calculates the size of a label text (excluding padding).
  ///
  /// This method uses Flutter's [TextPainter] to accurately measure the rendered
  /// size of the text based on the provided [labelTheme]. The returned size contains
  /// only the text dimensions - padding is NOT included.
  ///
  /// If [labelTheme.maxWidth] is set, the text will wrap to multiple lines when
  /// it exceeds that width. The maxWidth constraint applies to the text content only.
  ///
  /// If [labelTheme.maxLines] is set, the text will be limited to that number of lines.
  ///
  /// Parameters:
  /// - [text]: The text content to measure
  /// - [labelTheme]: The theme containing text style, padding, maxWidth, and maxLines
  ///
  /// Returns: A [Size] representing the text dimensions (padding NOT included).
  static Size _calculateLabelSize(String text, LabelTheme labelTheme) {
    final textPainter = TextPainter(
      text: TextSpan(text: text, style: labelTheme.textStyle),
      textDirection: TextDirection.ltr,
      maxLines: labelTheme.maxLines,
    );

    // maxWidth constrains the text content width (not including padding)
    final maxTextWidth = labelTheme.maxWidth.isFinite
        ? labelTheme.maxWidth
        : double.infinity;

    // Layout with width constraint
    textPainter.layout(maxWidth: maxTextWidth);

    // Return text size only (Container will add padding)
    return textPainter.size;
  }

  /// Calculates the rectangular bounds for a single label.
  ///
  /// Parameters:
  /// - [label]: The label to position
  /// - [connectionPath]: The connection path to position the label along
  /// - [labelTheme]: Theme defining label appearance
  ///
  /// Returns: The rectangular bounds for the label, or null if calculation fails
  static Rect? _calculateLabelRect({
    required ConnectionLabel label,
    required Path connectionPath,
    required LabelTheme labelTheme,
    required double portExtension,
  }) {
    try {
      // Get path metrics - convert to list to avoid consuming iterator
      final pathMetricsList = connectionPath.computeMetrics().toList();
      if (pathMetricsList.isEmpty) {
        return null;
      }

      final pathMetric = pathMetricsList.first;
      if (pathMetric.length <= 0) {
        return null;
      }

      // Calculate position at anchor point
      final distance = (label.anchor * pathMetric.length).clamp(
        0.0,
        pathMetric.length,
      );
      final tangent = pathMetric.getTangentForOffset(distance);
      if (tangent == null) {
        return null;
      }

      // Get position and direction at anchor point
      final anchorPosition = tangent.position;
      final tangentVector = tangent.vector;

      // Validate that we got valid position data
      if (!anchorPosition.dx.isFinite || !anchorPosition.dy.isFinite) {
        return null;
      }

      // Calculate label size
      final labelSize = _calculateLabelSize(label.text, labelTheme);

      // Validate label size
      if (labelSize.width <= 0 || labelSize.height <= 0) {
        return null;
      }

      // Calculate perpendicular offset
      final offset = label.offset;
      final perpendicularPosition = _applyPerpendicularOffset(
        position: anchorPosition,
        tangent: tangentVector,
        offset: offset,
      );

      // Validate perpendicular position
      if (!perpendicularPosition.dx.isFinite ||
          !perpendicularPosition.dy.isFinite) {
        return null;
      }

      // Position the label based on anchor value
      // The horizontal alignment changes progressively:
      // - anchor 0.0: left edge of visual label (including padding) at position
      // - anchor 0.5: center of visual label at position
      // - anchor 1.0: right edge of visual label at position

      // The visual label size includes padding
      final visualWidth = labelSize.width + labelTheme.padding.horizontal;
      final visualHeight = labelSize.height + labelTheme.padding.vertical;

      // Calculate where to position the Container
      // At 0.0: Container left edge at position
      // At 0.5: Container center at position
      // At 1.0: Container right edge at position
      var left = perpendicularPosition.dx - visualWidth * label.anchor;
      final top = perpendicularPosition.dy - visualHeight / 2;

      // Apply labelGap horizontally for endpoint anchors
      // Anchor is horizontal alignment, so gap is also horizontal
      final labelGap = labelTheme.labelGap;
      if (labelGap > 0) {
        if (label.anchor <= 0.0) {
          // At start (left), shift right by labelGap
          left += labelGap;
        } else if (label.anchor >= 1.0) {
          // At end (right), shift left by labelGap
          left -= labelGap;
        }
      }

      // Validate final rect values
      if (!left.isFinite || !top.isFinite) {
        return null;
      }

      // Return rect with VISUAL size (including padding)
      // This ensures widget constrains to exact calculated size
      final rect = Rect.fromLTWH(left, top, visualWidth, visualHeight);
      return rect;
    } catch (e) {
      return null;
    }
  }

  /// Applies a perpendicular offset to a position along a path.
  ///
  /// The offset is applied perpendicular to the path direction (tangent).
  /// Positive offsets go to the "left" of the path direction (when traveling along the path),
  /// negative offsets go to the "right".
  ///
  /// Parameters:
  /// - [position]: The base position on the path
  /// - [tangent]: The tangent vector (direction) at that position
  /// - [offset]: The perpendicular offset distance
  ///
  /// Returns: The new position after applying the perpendicular offset
  static Offset _applyPerpendicularOffset({
    required Offset position,
    required Offset tangent,
    required double offset,
  }) {
    if (offset == 0.0) return position;

    // Normalize the tangent vector
    final tangentLength = math.sqrt(
      tangent.dx * tangent.dx + tangent.dy * tangent.dy,
    );
    if (tangentLength == 0) return position;

    final normalizedTangent = Offset(
      tangent.dx / tangentLength,
      tangent.dy / tangentLength,
    );

    // Calculate perpendicular vector by rotating tangent 90 degrees counter-clockwise
    // For a 2D vector (x, y), rotating 90° CCW gives (-y, x)
    final perpendicular = Offset(-normalizedTangent.dy, normalizedTangent.dx);

    // Apply the offset along the perpendicular direction
    return position + (perpendicular * offset);
  }
}
