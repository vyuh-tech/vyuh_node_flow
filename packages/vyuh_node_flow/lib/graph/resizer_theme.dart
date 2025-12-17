import 'package:flutter/material.dart';

/// Theme configuration for resize handles used by nodes and annotations.
///
/// Defines the visual appearance and interaction behavior for resize handles:
/// - Handle size (width/height of the visible handle)
/// - Fill color (interior color of the handle)
/// - Border color and width (outline of the handle)
/// - Snap distance (padding around handles for easier hit targeting)
///
/// Example:
/// ```dart
/// final customResizerTheme = ResizerTheme.light.copyWith(
///   handleSize: 12.0,
///   borderColor: Colors.green,
/// );
/// ```
class ResizerTheme {
  const ResizerTheme({
    required this.handleSize,
    required this.color,
    required this.borderColor,
    required this.borderWidth,
    required this.snapDistance,
  });

  /// Size of each resize handle (width and height).
  ///
  /// Handles are square, so this value applies to both dimensions.
  final double handleSize;

  /// Fill color of the resize handles.
  ///
  /// This is the interior/background color of the handle.
  final Color color;

  /// Border color of the resize handles.
  ///
  /// This is the outline color that provides contrast against the fill.
  final Color borderColor;

  /// Border width of the resize handles.
  ///
  /// Controls the thickness of the handle outline.
  final double borderWidth;

  /// Additional hit area around each handle for easier targeting.
  ///
  /// This creates a larger invisible hit area around the visible handle,
  /// making it easier to grab handles, especially on touch devices.
  /// Set to 0 for no padding beyond the visible handle.
  final double snapDistance;

  /// Creates a copy of this theme with the given fields replaced.
  ResizerTheme copyWith({
    double? handleSize,
    Color? color,
    Color? borderColor,
    double? borderWidth,
    double? snapDistance,
  }) {
    return ResizerTheme(
      handleSize: handleSize ?? this.handleSize,
      color: color ?? this.color,
      borderColor: borderColor ?? this.borderColor,
      borderWidth: borderWidth ?? this.borderWidth,
      snapDistance: snapDistance ?? this.snapDistance,
    );
  }

  /// Light theme resizer configuration.
  ///
  /// Uses white fill with blue border for visibility on light backgrounds.
  static const light = ResizerTheme(
    handleSize: 10.0,
    color: Colors.white,
    borderColor: Colors.blue,
    borderWidth: 1.0,
    snapDistance: 4.0,
  );

  /// Dark theme resizer configuration.
  ///
  /// Uses dark fill with lighter blue border for visibility on dark backgrounds.
  static const dark = ResizerTheme(
    handleSize: 10.0,
    color: Color(0xFF1E1E1E),
    borderColor: Color(0xFF64B5F6),
    // Colors.blue[300]
    borderWidth: 1.0,
    snapDistance: 4.0,
  );
}
