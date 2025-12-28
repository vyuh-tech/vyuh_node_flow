import 'dart:ui';

/// Defines style overrides for a connection at the widget level.
///
/// [ConnectionStyleOverrides] allows customizing the appearance of individual
/// connections without modifying the connection model or theme. These overrides
/// are resolved at render time via a callback.
///
/// ## Usage
///
/// Provide a `connectionStyleResolver` callback to [NodeFlowEditor]:
///
/// ```dart
/// NodeFlowEditor(
///   connectionStyleResolver: (connection) {
///     if (connection.data?['type'] == 'error') {
///       return ConnectionStyleOverrides(
///         color: Colors.red,
///         selectedColor: Colors.red.shade700,
///         strokeWidth: 3.0,
///       );
///     }
///     return null; // Use theme defaults
///   },
/// )
/// ```
///
/// ## Override Cascade
///
/// Colors and styles are resolved in this order of precedence:
/// 1. Widget-level overrides from `connectionStyleResolver` (if provided)
/// 2. Theme colors (from [ConnectionTheme])
class ConnectionStyleOverrides {
  /// Creates connection style overrides.
  ///
  /// All parameters are optional. Only provided values will override
  /// the theme defaults.
  const ConnectionStyleOverrides({
    this.color,
    this.selectedColor,
    this.strokeWidth,
    this.selectedStrokeWidth,
  });

  /// Override for the connection color when not selected.
  final Color? color;

  /// Override for the connection color when selected.
  final Color? selectedColor;

  /// Override for the connection stroke width when not selected.
  final double? strokeWidth;

  /// Override for the connection stroke width when selected.
  final double? selectedStrokeWidth;

  /// Creates a copy of this instance with the given fields replaced.
  ConnectionStyleOverrides copyWith({
    Color? color,
    Color? selectedColor,
    double? strokeWidth,
    double? selectedStrokeWidth,
  }) {
    return ConnectionStyleOverrides(
      color: color ?? this.color,
      selectedColor: selectedColor ?? this.selectedColor,
      strokeWidth: strokeWidth ?? this.strokeWidth,
      selectedStrokeWidth: selectedStrokeWidth ?? this.selectedStrokeWidth,
    );
  }
}

/// Type definition for the connection style resolver callback.
///
/// This callback is invoked for each connection during rendering to determine
/// if any style overrides should be applied.
///
/// Return `null` to use the theme defaults, or return a [ConnectionStyleOverrides]
/// instance to customize the connection's appearance.
///
/// Example:
/// ```dart
/// ConnectionStyleResolver myResolver = (connection) {
///   if (connection.data?['priority'] == 'high') {
///     return ConnectionStyleOverrides(
///       color: Colors.orange,
///       strokeWidth: 3.0,
///     );
///   }
///   return null;
/// };
/// ```
typedef ConnectionStyleResolver =
    ConnectionStyleOverrides? Function(dynamic connection);
