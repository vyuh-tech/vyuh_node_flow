/// Defines standard anchor positions along a connection path.
///
/// Anchor values represent positions along the connection from source (0.0) to target (1.0).
class ConnectionAnchor {
  /// Anchor position at the start of the connection (source port).
  static const double start = 0.0;

  /// Anchor position at the center of the connection.
  static const double center = 0.5;

  /// Anchor position at the end of the connection (target port).
  static const double end = 1.0;
}
