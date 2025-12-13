import 'bezier_connection_style.dart';
import 'connection_style_base.dart';
import 'step_connection_style.dart';
import 'straight_connection_style.dart';

/// Built-in connection styles
///
/// This class provides easy access to all the built-in connection styles.
final class ConnectionStyles {
  // Private constructor to prevent instantiation
  const ConnectionStyles._();

  // === Built-in Style Constants ===

  /// Straight line connections with port extensions
  static const ConnectionStyle straight = StraightConnectionStyle();

  /// Smooth bezier curve connections
  static const ConnectionStyle bezier = BezierConnectionStyle();

  /// 90-degree step connections without rounded corners
  static const ConnectionStyle step = StepConnectionStyle(cornerRadius: 0);

  /// 90-degree step connections with rounded corners
  static const ConnectionStyle smoothstep = StepConnectionStyle(
    cornerRadius: 8.0,
  );

  /// Custom bezier connections with configurable parameters
  static const ConnectionStyle customBezier = CustomBezierConnectionStyle();

  // === Collections ===

  /// All built-in connection styles
  static const List<ConnectionStyle> all = [
    straight,
    bezier,
    step,
    smoothstep,
    customBezier,
  ];

  /// Built-in styles mapped by their ID
  static const Map<String, ConnectionStyle> byId = {
    'straight': straight,
    'bezier': bezier,
    'step': step,
    'smoothstep': smoothstep,
    'customBezier': customBezier,
  };

  // === Utility Methods ===

  /// Find a connection style by its ID
  ///
  /// Returns null if no built-in style with the given ID exists.
  /// For custom styles, you'll need to manage them separately.
  static ConnectionStyle? findById(String id) {
    return byId[id];
  }

  /// Get all connection style IDs
  static List<String> get allIds => byId.keys.toList();

  /// Check if a style is a built-in style
  static bool isBuiltIn(ConnectionStyle style) {
    return byId.containsKey(style.id);
  }

  /// Get a connection style with fallback to default
  ///
  /// If the requested style is not found, returns the default style (smoothstep).
  static ConnectionStyle getWithFallback(String? id) {
    if (id == null) return smoothstep;
    return byId[id] ?? smoothstep;
  }
}

/// Extension to add conversion methods to connection style instances
extension ConnectionStyleExtension on ConnectionStyle {
  /// Check if this is a built-in connection style
  bool get isBuiltIn => ConnectionStyles.isBuiltIn(this);
}
