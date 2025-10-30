import 'package:flutter/material.dart';

import 'connection_endpoint.dart';

enum EndpointShape {
  capsuleHalf,
  circle,
  square,
  diamond,
  triangle,
  none, // No endpoint marker
}

class ConnectionTheme {
  const ConnectionTheme({
    this.color = Colors.grey,
    this.selectedColor = Colors.blue,
    this.strokeWidth = 2.0,
    this.selectedStrokeWidth = 3.0,
    this.dashPattern,
    this.startPoint = ConnectionEndPoint.none,
    this.endPoint = ConnectionEndPoint.capsuleHalf,
    this.animationDuration = const Duration(milliseconds: 300),
    this.bezierCurvature = 0.3,
    this.cornerRadius = 4.0,
    this.hitTolerance = 8.0,
  });

  final Color color;
  final Color selectedColor;
  final double strokeWidth;
  final double selectedStrokeWidth;
  final List<double>? dashPattern;
  final ConnectionEndPoint startPoint;
  final ConnectionEndPoint endPoint;
  final Duration animationDuration;
  final double bezierCurvature;
  final double cornerRadius;
  final double hitTolerance;

  ConnectionTheme copyWith({
    Color? color,
    Color? selectedColor,
    double? strokeWidth,
    double? selectedStrokeWidth,
    List<double>? dashPattern,
    ConnectionEndPoint? startPoint,
    ConnectionEndPoint? endPoint,
    Duration? animationDuration,
    double? bezierCurvature,
    double? cornerRadius,
    double? hitTolerance,
  }) {
    return ConnectionTheme(
      color: color ?? this.color,
      selectedColor: selectedColor ?? this.selectedColor,
      strokeWidth: strokeWidth ?? this.strokeWidth,
      selectedStrokeWidth: selectedStrokeWidth ?? this.selectedStrokeWidth,
      dashPattern: dashPattern,
      startPoint: startPoint ?? this.startPoint,
      endPoint: endPoint ?? this.endPoint,
      animationDuration: animationDuration ?? this.animationDuration,
      bezierCurvature: bezierCurvature ?? this.bezierCurvature,
      cornerRadius: cornerRadius ?? this.cornerRadius,
      hitTolerance: hitTolerance ?? this.hitTolerance,
    );
  }

  static const light = ConnectionTheme(
    color: Color(0xFF666666),
    selectedColor: Color(0xFF2196F3),
    strokeWidth: 2.0,
    selectedStrokeWidth: 3.0,
    startPoint: ConnectionEndPoint.none,
    endPoint: ConnectionEndPoint.capsuleHalf,
    bezierCurvature: 0.5,
    cornerRadius: 4.0,
    hitTolerance: 8.0,
  );

  static const dark = ConnectionTheme(
    color: Color(0xFF999999),
    selectedColor: Color(0xFF64B5F6),
    strokeWidth: 2.0,
    selectedStrokeWidth: 3.0,
    startPoint: ConnectionEndPoint.none,
    endPoint: ConnectionEndPoint.capsuleHalf,
    bezierCurvature: 0.5,
    cornerRadius: 4.0,
    hitTolerance: 8.0,
  );
}

// ConnectionStyleTheme class has been removed in favor of direct properties on NodeFlowTheme
