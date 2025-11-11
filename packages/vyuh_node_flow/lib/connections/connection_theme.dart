import 'package:flutter/material.dart';

import 'connection_endpoint.dart';
import 'effects/connection_effect.dart';
import 'styles/connection_style_base.dart';
import 'styles/connection_styles.dart';

/// Defines the visual styling and behavior of connections in the node flow.
///
/// [ConnectionTheme] centralizes all visual properties for connections including
/// colors, stroke widths, endpoint markers, animation settings, and geometric
/// parameters like curvature and corner radius.
///
/// ## Usage Example
/// ```dart
/// const theme = ConnectionTheme(
///   color: Colors.grey,
///   selectedColor: Colors.blue,
///   strokeWidth: 2.0,
///   selectedStrokeWidth: 3.0,
///   endPoint: ConnectionEndPoint.triangle,
///   bezierCurvature: 0.5,
/// );
/// ```
///
/// ## Predefined Themes
/// - [ConnectionTheme.light]: Optimized for light backgrounds
/// - [ConnectionTheme.dark]: Optimized for dark backgrounds
///
/// See also:
/// - [ConnectionEndPoint] for endpoint marker configuration
/// - [NodeFlowTheme] for overall theme configuration
class ConnectionTheme {
  /// Creates a connection theme with the specified visual properties.
  ///
  /// Parameters:
  /// - [style]: The connection line style (bezier, smoothstep, straight, etc.)
  /// - [color]: Default color for unselected connections
  /// - [selectedColor]: Color for selected connections
  /// - [strokeWidth]: Stroke width for unselected connections in logical pixels
  /// - [selectedStrokeWidth]: Stroke width for selected connections in logical pixels
  /// - [dashPattern]: Optional dash pattern for dashed lines (e.g., [5, 3] for 5px dash, 3px gap)
  /// - [startPoint]: Endpoint marker for the connection start
  /// - [endPoint]: Endpoint marker for the connection end
  /// - [animationEffect]: Optional default animation effect for connections
  /// - [bezierCurvature]: Curvature factor for bezier-style connections (0.0 to 1.0)
  /// - [cornerRadius]: Radius for rounded corners in step-style connections
  /// - [portExtension]: Distance connections extend straight from ports before curving
  /// - [hitTolerance]: Distance tolerance for hit testing in logical pixels
  const ConnectionTheme({
    this.style = ConnectionStyles.smoothstep,
    this.color = Colors.grey,
    this.selectedColor = Colors.blue,
    this.strokeWidth = 2.0,
    this.selectedStrokeWidth = 3.0,
    this.dashPattern,
    this.startPoint = ConnectionEndPoint.none,
    this.endPoint = ConnectionEndPoint.capsuleHalf,
    this.animationEffect,
    this.bezierCurvature = 0.3,
    this.cornerRadius = 4.0,
    this.portExtension = 20.0,
    this.hitTolerance = 8.0,
  });

  /// The connection line style (bezier, smoothstep, straight, etc.).
  ///
  /// Defines how the connection path is rendered between nodes.
  /// See [ConnectionStyles] for available built-in styles.
  final ConnectionStyle style;

  /// Default color for unselected connections.
  final Color color;

  /// Color for selected connections.
  final Color selectedColor;

  /// Stroke width for unselected connections in logical pixels.
  final double strokeWidth;

  /// Stroke width for selected connections in logical pixels.
  final double selectedStrokeWidth;

  /// Optional dash pattern for dashed lines.
  ///
  /// If null, connections are drawn as solid lines. If specified, the pattern
  /// alternates between dash and gap lengths. For example, [5, 3] creates
  /// 5-pixel dashes with 3-pixel gaps.
  final List<double>? dashPattern;

  /// Endpoint marker for the connection start (source).
  final ConnectionEndPoint startPoint;

  /// Endpoint marker for the connection end (target).
  final ConnectionEndPoint endPoint;

  /// Optional default animation effect for all connections.
  ///
  /// If specified, this effect will be used for all connections unless
  /// overridden by the individual connection's [animationEffect] property.
  /// If null, connections will have no animation effect by default.
  ///
  /// Common effects include:
  /// - [FlowingDashEffect]: Flowing dashed line animation
  /// - [ParticleEffect]: Particles moving along the connection
  /// - [GradientFlowEffect]: Animated gradient flowing along the path
  /// - [PulseEffect]: Pulsing/glowing effect
  final ConnectionEffect? animationEffect;

  /// Curvature factor for bezier-style connections.
  ///
  /// Valid range is typically 0.0 to 1.0:
  /// - 0.0: More direct curve
  /// - 0.5: Moderate curve (recommended)
  /// - 1.0: Maximum curve
  final double bezierCurvature;

  /// Radius for rounded corners in step-style connections.
  ///
  /// Only applies to step and smoothstep connection styles. Controls how
  /// rounded the 90-degree turns are.
  final double cornerRadius;

  /// Distance connections extend straight from ports before curving.
  ///
  /// This value determines how far the connection path extends in a straight
  /// line from the port before beginning to curve. Also used as the gap
  /// distance for label positioning at the start and end of connections.
  final double portExtension;

  /// Distance tolerance for hit testing in logical pixels.
  ///
  /// Determines how close a pointer must be to a connection to register
  /// a hit. Larger values make connections easier to select but may cause
  /// overlapping hit areas.
  final double hitTolerance;

  /// Creates a copy of this theme with optionally updated properties.
  ///
  /// Any parameter that is not provided will retain its current value.
  ///
  /// Note: Passing null for [dashPattern] or [animationEffect] will set them to null.
  ConnectionTheme copyWith({
    ConnectionStyle? style,
    Color? color,
    Color? selectedColor,
    double? strokeWidth,
    double? selectedStrokeWidth,
    List<double>? dashPattern,
    ConnectionEndPoint? startPoint,
    ConnectionEndPoint? endPoint,
    ConnectionEffect? animationEffect,
    double? bezierCurvature,
    double? cornerRadius,
    double? portExtension,
    double? hitTolerance,
  }) {
    return ConnectionTheme(
      style: style ?? this.style,
      color: color ?? this.color,
      selectedColor: selectedColor ?? this.selectedColor,
      strokeWidth: strokeWidth ?? this.strokeWidth,
      selectedStrokeWidth: selectedStrokeWidth ?? this.selectedStrokeWidth,
      dashPattern: dashPattern,
      startPoint: startPoint ?? this.startPoint,
      endPoint: endPoint ?? this.endPoint,
      animationEffect: animationEffect,
      bezierCurvature: bezierCurvature ?? this.bezierCurvature,
      cornerRadius: cornerRadius ?? this.cornerRadius,
      portExtension: portExtension ?? this.portExtension,
      hitTolerance: hitTolerance ?? this.hitTolerance,
    );
  }

  /// Predefined light theme optimized for light backgrounds.
  ///
  /// Features:
  /// - Smoothstep connection style
  /// - Dark gray connections (0xFF666666) for good contrast
  /// - Blue selection color (Material blue 500)
  /// - No start marker, capsule-half end marker
  /// - Moderate curvature (0.5)
  static const light = ConnectionTheme(
    style: ConnectionStyles.smoothstep,
    color: Color(0xFF666666),
    selectedColor: Color(0xFF2196F3),
    strokeWidth: 2.0,
    selectedStrokeWidth: 3.0,
    startPoint: ConnectionEndPoint.none,
    endPoint: ConnectionEndPoint.capsuleHalf,
    bezierCurvature: 0.5,
    cornerRadius: 4.0,
    portExtension: 20.0,
    hitTolerance: 8.0,
  );

  /// Predefined dark theme optimized for dark backgrounds.
  ///
  /// Features:
  /// - Smoothstep connection style
  /// - Light gray connections (0xFF999999) for good contrast
  /// - Light blue selection color (Material blue 300)
  /// - No start marker, capsule-half end marker
  /// - Moderate curvature (0.5)
  static const dark = ConnectionTheme(
    style: ConnectionStyles.smoothstep,
    color: Color(0xFF999999),
    selectedColor: Color(0xFF64B5F6),
    strokeWidth: 2.0,
    selectedStrokeWidth: 3.0,
    startPoint: ConnectionEndPoint.none,
    endPoint: ConnectionEndPoint.capsuleHalf,
    bezierCurvature: 0.5,
    cornerRadius: 4.0,
    portExtension: 20.0,
    hitTolerance: 8.0,
  );
}
