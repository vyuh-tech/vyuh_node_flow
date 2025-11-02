import 'package:flutter/material.dart';

import '../connections/connection.dart' show Connection;
import '../connections/connection_style_base.dart';
import '../connections/label_theme.dart';
import '../nodes/node.dart';
import '../ports/port.dart';
import '../shared/label_position_calculator.dart';
import 'connection_path_calculator.dart';
import 'endpoint_position_calculator.dart';

/// Contains the calculated rectangular bounds for connection labels.
///
/// Each connection can have up to three labels:
/// - [centerRect]: Label positioned at the midpoint of the connection
/// - [startRect]: Label positioned near the source endpoint
/// - [endRect]: Label positioned near the target endpoint
///
/// Null values indicate that the corresponding label is not present.
class LabelPositionData {
  /// Creates label position data with optional label rectangles.
  const LabelPositionData({this.centerRect, this.startRect, this.endRect});

  /// Rectangular bounds for the center label.
  ///
  /// Positioned at t=0.5 (midpoint) of the connection path.
  final Rect? centerRect;

  /// Rectangular bounds for the start label.
  ///
  /// Positioned near the source endpoint, offset based on port position
  /// and [LabelTheme] settings.
  final Rect? startRect;

  /// Rectangular bounds for the end label.
  ///
  /// Positioned near the target endpoint, offset based on port position
  /// and [LabelTheme] settings.
  final Rect? endRect;
}

/// Utility class for calculating connection label positions.
///
/// This calculator determines the exact rectangular bounds for all three types
/// of connection labels (center, start, and end), taking into account:
/// - Connection path geometry
/// - Port positions and orientations
/// - Endpoint marker sizes
/// - Label text sizes
/// - Theme-defined offsets
///
/// ## Label Types
/// 1. **Center Label**: Positioned at the exact midpoint (t=0.5) of the connection path
/// 2. **Start Label**: Positioned near the source endpoint, offset by [LabelTheme.horizontalOffset]
///    or [LabelTheme.verticalOffset] depending on port orientation
/// 3. **End Label**: Positioned near the target endpoint, similarly offset
///
/// ## Usage Example
/// ```dart
/// final labelData = EdgeLabelPositionCalculator.calculateAllLabelPositions(
///   connection: myConnection,
///   sourceNode: sourceNode,
///   targetNode: targetNode,
///   connectionStyle: ConnectionStyles.smoothstep,
///   curvature: 0.5,
///   portSize: 8.0,
///   endpointSize: 5.0,
///   labelTheme: myLabelTheme,
/// );
///
/// if (labelData?.centerRect != null) {
///   // Draw center label at labelData.centerRect
/// }
/// ```
///
/// See also:
/// - [LabelTheme] for label styling and offset configuration
/// - [Connection] for label text management
class EdgeLabelPositionCalculator {
  /// Calculates all label positions for a connection.
  ///
  /// This is the main entry point that orchestrates the calculation of all
  /// three label positions (center, start, and end) for a connection.
  ///
  /// Parameters:
  /// - [connection]: The connection whose labels to position
  /// - [sourceNode]: The source node of the connection
  /// - [targetNode]: The target node of the connection
  /// - [connectionStyle]: The style used to render the connection
  /// - [curvature]: Curvature factor for the connection (0.0 to 1.0)
  /// - [portSize]: Size of the ports in logical pixels
  /// - [endpointSize]: Size of the endpoint markers in logical pixels
  /// - [labelTheme]: Theme defining label appearance and offsets
  ///
  /// Returns: A [LabelPositionData] containing rectangles for all present labels,
  /// or null if the calculation fails (e.g., ports not found)
  ///
  /// The method:
  /// 1. Finds the source and target ports on their respective nodes
  /// 2. Calculates port positions and endpoint positions
  /// 3. Determines label sizes from text and theme
  /// 4. Computes final label positions based on connection geometry
  static LabelPositionData? calculateAllLabelPositions({
    required Connection connection,
    required Node sourceNode,
    required Node targetNode,
    required ConnectionStyle connectionStyle,
    required double curvature,
    required double portSize,
    required double endpointSize,
    required LabelTheme labelTheme,
  }) {
    try {
      // Get port positions
      final sourcePortPosition = sourceNode.getPortPosition(
        connection.sourcePortId,
        portSize: portSize,
      );
      final targetPortPosition = targetNode.getPortPosition(
        connection.targetPortId,
        portSize: portSize,
      );

      // Find the actual port objects
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

      // Calculate endpoint positions using the existing utility
      final source = EndpointPositionCalculator.calculatePortConnectionPoints(
        sourcePortPosition,
        sourcePort?.position ?? PortPosition.right,
        endpointSize,
        portSize,
      );
      final target = EndpointPositionCalculator.calculatePortConnectionPoints(
        targetPortPosition,
        targetPort?.position ?? PortPosition.left,
        endpointSize,
        portSize,
      );

      // Now do the actual positioning calculation
      return _calculateLabelRects(
        connection: connection,
        connectionStyle: connectionStyle,
        sourceLinePos: source.linePos,
        targetLinePos: target.linePos,
        sourceEndpointPos: source.endpointPos,
        targetEndpointPos: target.endpointPos,
        curvature: curvature,
        portSize: portSize,
        labelTheme: labelTheme,
        sourcePort: sourcePort,
        targetPort: targetPort,
      );
    } catch (e) {
      return null;
    }
  }

  /// Internal method to calculate label rects from processed data
  static LabelPositionData _calculateLabelRects({
    required Connection connection,
    required ConnectionStyle connectionStyle,
    required Offset sourceLinePos,
    required Offset targetLinePos,
    required Offset sourceEndpointPos,
    required Offset targetEndpointPos,
    required double curvature,
    required double portSize,
    required LabelTheme labelTheme,
    Port? sourcePort,
    Port? targetPort,
  }) {
    Rect? centerRect;
    Rect? startRect;
    Rect? endRect;

    // Calculate center label rect
    if (connection.label != null && connection.label!.isNotEmpty) {
      final centerPosition = calculateCenterPosition(
        connectionStyle: connectionStyle,
        start: sourceLinePos,
        end: targetLinePos,
        curvature: curvature,
        sourcePort: sourcePort,
        targetPort: targetPort,
      );
      final centerSize = LabelPositionCalculator.calculateLabelSize(
        connection.label!,
        labelTheme,
      );

      centerRect = Rect.fromLTWH(
        centerPosition.dx - centerSize.width / 2,
        centerPosition.dy - centerSize.height / 2,
        centerSize.width,
        centerSize.height,
      );
    }

    // Calculate start label rect
    if (connection.startLabel != null && connection.startLabel!.isNotEmpty) {
      final startSize = LabelPositionCalculator.calculateLabelSize(
        connection.startLabel!,
        labelTheme,
      );
      final startPosition = calculateStartPosition(
        sourceEndpointPos,
        sourcePort,
        portSize,
        labelTheme,
        startSize,
      );

      startRect = Rect.fromLTWH(
        startPosition.dx,
        startPosition.dy,
        startSize.width,
        startSize.height,
      );
    }

    // Calculate end label rect
    if (connection.endLabel != null && connection.endLabel!.isNotEmpty) {
      final endSize = LabelPositionCalculator.calculateLabelSize(
        connection.endLabel!,
        labelTheme,
      );
      final endPosition = calculateEndPosition(
        targetEndpointPos,
        targetPort,
        portSize,
        labelTheme,
        endSize,
      );

      endRect = Rect.fromLTWH(
        endPosition.dx,
        endPosition.dy,
        endSize.width,
        endSize.height,
      );
    }

    return LabelPositionData(
      centerRect: centerRect,
      startRect: startRect,
      endRect: endRect,
    );
  }

  /// Calculates the center position for a connection label.
  ///
  /// The center position is determined by finding the point at t=0.5
  /// (the exact midpoint) of the connection path. This ensures the label
  /// is positioned at the geometric center of the connection regardless
  /// of the connection style (bezier, step, straight, etc.).
  ///
  /// Parameters:
  /// - [connectionStyle]: The style used to create the connection path
  /// - [start]: Start point of the connection line (after endpoint marker)
  /// - [end]: End point of the connection line (before endpoint marker)
  /// - [curvature]: Curvature factor for bezier-style connections
  /// - [sourcePort]: Optional source port for position-aware path creation
  /// - [targetPort]: Optional target port for position-aware path creation
  ///
  /// Returns: The offset where the center label should be positioned
  ///
  /// If path calculation fails, returns the simple midpoint between start and end.
  static Offset calculateCenterPosition({
    required ConnectionStyle connectionStyle,
    required Offset start,
    required Offset end,
    required double curvature,
    Port? sourcePort,
    Port? targetPort,
  }) {
    try {
      // Create the connection path using the utility
      final connectionPath = ConnectionPathCalculator.createConnectionPath(
        style: connectionStyle,
        start: start,
        end: end,
        curvature: curvature,
        sourcePort: sourcePort,
        targetPort: targetPort,
      );

      final pathCenter = _calculateCenterPositionFromPath(connectionPath);

      // If path calculation fails, use simple midpoint
      if (pathCenter == Offset.zero) {
        return Offset((start.dx + end.dx) / 2, (start.dy + end.dy) / 2);
      }

      return pathCenter;
    } catch (e) {
      // Fallback to simple midpoint calculation
      return Offset((start.dx + end.dx) / 2, (start.dy + end.dy) / 2);
    }
  }

  /// Calculates the center position of a connection path (t=0.5 point).
  ///
  /// This internal method computes the exact point at t=0.5 along the
  /// connection path using Flutter's path metrics API.
  ///
  /// Parameters:
  /// - [connectionPath]: The path to analyze
  ///
  /// Returns: The position at t=0.5, or [Offset.zero] if the path is invalid
  static Offset _calculateCenterPositionFromPath(Path connectionPath) {
    final pathMetrics = connectionPath.computeMetrics();

    if (pathMetrics.isEmpty) {
      return Offset.zero;
    }

    final pathMetric = pathMetrics.first;

    if (pathMetric.length <= 0) {
      return Offset.zero;
    }

    // Get the point at t=0.5 (midpoint) of the path
    final midDistance = pathMetric.length * 0.5;
    final tangent = pathMetric.getTangentForOffset(midDistance);

    if (tangent == null) {
      return Offset.zero;
    }

    // Return the exact center position on the connection path (t=0.5)
    return tangent.position;
  }

  /// Calculates the start label position near the source endpoint.
  ///
  /// The label is positioned relative to the endpoint marker based on the
  /// source port's orientation and the [LabelTheme]'s offset settings.
  ///
  /// Parameters:
  /// - [endpointPosition]: Center position of the source endpoint marker
  /// - [sourcePort]: The source port (null defaults to positioning above)
  /// - [portSize]: Size of the port in logical pixels
  /// - [labelTheme]: Theme containing offset settings
  /// - [labelSize]: Size of the label text (used for centering)
  ///
  /// Returns: Top-left corner position for the label rectangle
  ///
  /// Positioning rules:
  /// - Left ports: Label goes LEFT of endpoint by [LabelTheme.horizontalOffset]
  /// - Right ports: Label goes RIGHT of endpoint by [LabelTheme.horizontalOffset]
  /// - Top ports: Label goes UP from endpoint by [LabelTheme.verticalOffset]
  /// - Bottom ports: Label goes DOWN from endpoint by [LabelTheme.verticalOffset]
  static Offset calculateStartPosition(
    Offset endpointPosition,
    Port? sourcePort,
    double portSize,
    LabelTheme labelTheme,
    Size labelSize,
  ) {
    if (sourcePort == null) {
      return endpointPosition + Offset(0, -labelTheme.verticalOffset);
    }

    // Position label relative to endpoint using exact theme offsets
    switch (sourcePort.position) {
      case PortPosition.left:
        // Left port: label goes LEFT from endpoint by theme offset
        return Offset(
          endpointPosition.dx - labelTheme.horizontalOffset - labelSize.width,
          endpointPosition.dy - labelSize.height / 2,
        );
      case PortPosition.right:
        // Right port: label goes RIGHT from endpoint by theme offset
        return Offset(
          endpointPosition.dx + labelTheme.horizontalOffset,
          endpointPosition.dy - labelSize.height / 2,
        );
      case PortPosition.top:
        // Top port: label goes UP from endpoint by theme offset
        return Offset(
          endpointPosition.dx - labelSize.width / 2,
          endpointPosition.dy - labelTheme.verticalOffset - labelSize.height,
        );
      case PortPosition.bottom:
        // Bottom port: label goes DOWN from endpoint by theme offset
        return Offset(
          endpointPosition.dx - labelSize.width / 2,
          endpointPosition.dy + labelTheme.verticalOffset,
        );
    }
  }

  /// Calculates the end label position near the target endpoint.
  ///
  /// The label is positioned relative to the endpoint marker based on the
  /// target port's orientation and the [LabelTheme]'s offset settings.
  ///
  /// Parameters:
  /// - [endpointPosition]: Center position of the target endpoint marker
  /// - [targetPort]: The target port (null defaults to positioning above)
  /// - [portSize]: Size of the port in logical pixels
  /// - [labelTheme]: Theme containing offset settings
  /// - [labelSize]: Size of the label text (used for centering)
  ///
  /// Returns: Top-left corner position for the label rectangle
  ///
  /// Positioning rules:
  /// - Left ports: Label goes LEFT of endpoint by [LabelTheme.horizontalOffset]
  /// - Right ports: Label goes RIGHT of endpoint by [LabelTheme.horizontalOffset]
  /// - Top ports: Label goes UP from endpoint by [LabelTheme.verticalOffset]
  /// - Bottom ports: Label goes DOWN from endpoint by [LabelTheme.verticalOffset]
  static Offset calculateEndPosition(
    Offset endpointPosition,
    Port? targetPort,
    double portSize,
    LabelTheme labelTheme,
    Size labelSize,
  ) {
    if (targetPort == null) {
      return endpointPosition + Offset(0, -labelTheme.verticalOffset);
    }

    // Position label relative to endpoint using exact theme offsets
    switch (targetPort.position) {
      case PortPosition.left:
        // Left port: label goes LEFT from endpoint by theme offset
        return Offset(
          endpointPosition.dx - labelTheme.horizontalOffset - labelSize.width,
          endpointPosition.dy - labelSize.height / 2,
        );
      case PortPosition.right:
        // Right port: label goes RIGHT from endpoint by theme offset
        return Offset(
          endpointPosition.dx + labelTheme.horizontalOffset,
          endpointPosition.dy - labelSize.height / 2,
        );
      case PortPosition.top:
        // Top port: label goes UP from endpoint by theme offset
        return Offset(
          endpointPosition.dx - labelSize.width / 2,
          endpointPosition.dy - labelTheme.verticalOffset - labelSize.height,
        );
      case PortPosition.bottom:
        // Bottom port: label goes DOWN from endpoint by theme offset
        return Offset(
          endpointPosition.dx - labelSize.width / 2,
          endpointPosition.dy + labelTheme.verticalOffset,
        );
    }
  }
}
