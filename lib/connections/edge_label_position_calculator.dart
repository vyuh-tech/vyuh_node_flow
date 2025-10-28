import 'package:flutter/material.dart';

import '../connections/connection.dart' show Connection;
import '../connections/connection_style_base.dart';
import '../connections/label_theme.dart';
import '../nodes/node.dart';
import '../ports/port.dart';
import '../shared/label_position_calculator.dart';
import 'connection_path_calculator.dart';
import 'endpoint_position_calculator.dart';

class LabelPositionData {
  final Rect? centerRect;
  final Rect? startRect;
  final Rect? endRect;

  const LabelPositionData({this.centerRect, this.startRect, this.endRect});
}

class EdgeLabelPositionCalculator {
  /// Calculates all label positions for a connection
  /// Takes a connection and figures out all the positioning internally
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

  /// Calculates the center position for a connection label
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

  /// Calculates the center position of a connection path (t=0.5 point)
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

  /// Calculates the start label position near the source endpoint
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

  /// Calculates the end label position near the target endpoint
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
