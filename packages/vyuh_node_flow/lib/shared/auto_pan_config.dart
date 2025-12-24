import 'package:flutter/animation.dart';

/// Configuration for autopan behavior during drag operations.
///
/// When a dragged element (node, annotation, or connection) approaches the
/// edge of the viewport, autopan automatically pans the viewport to reveal
/// more canvas, allowing continued dragging beyond the current visible area.
///
/// ## Basic Usage
///
/// ```dart
/// // Use default configuration
/// NodeFlowConfig(
///   autoPan: AutoPanConfig.normal,
/// )
///
/// // Custom configuration
/// NodeFlowConfig(
///   autoPan: AutoPanConfig(
///     edgePadding: 60.0,
///     panAmount: 15.0,
///     useProximityScaling: true,
///   ),
/// )
/// ```
///
/// ## Edge Detection Zones
///
/// ```
/// ┌─────────────────────────────────────────────┐
/// │░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░│ ← edgePadding (top)
/// │░░┌─────────────────────────────────────┐░░░░│
/// │░░│                                     │░░░░│
/// │░░│         Safe area (no pan)          │░░░░│
/// │░░│                                     │░░░░│
/// │░░└─────────────────────────────────────┘░░░░│
/// │░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░│ ← edgePadding (bottom)
/// └─────────────────────────────────────────────┘
///  ↑                                           ↑
///  edgePadding (left)              edgePadding (right)
/// ```
class AutoPanConfig {
  /// Creates an autopan configuration.
  ///
  /// All parameters have sensible defaults for typical use cases.
  const AutoPanConfig({
    this.edgePadding = 50.0,
    this.panAmount = 10.0,
    this.panInterval = const Duration(milliseconds: 16),
    this.useProximityScaling = false,
    this.speedCurve,
  });

  /// Distance from viewport edge (in screen pixels) where autopan activates.
  ///
  /// When the pointer enters this zone during a drag, autopan begins.
  /// Larger values make it easier to trigger autopan but reduce the
  /// usable drag area. Typical values range from 30 to 80 pixels.
  final double edgePadding;

  /// Base pan amount per tick in graph units.
  ///
  /// This is the distance the viewport moves each [panInterval].
  /// Higher values result in faster panning. The actual pan speed
  /// may be scaled if [useProximityScaling] is enabled.
  final double panAmount;

  /// Duration between pan ticks.
  ///
  /// Controls how frequently the viewport is panned while the pointer
  /// is in an edge zone. Shorter durations result in smoother but more
  /// frequent updates. Default is 16ms (~60 ticks per second).
  final Duration panInterval;

  /// Whether to scale pan speed based on proximity to the edge.
  ///
  /// When true, panning is slower at the outer edge of the trigger zone
  /// and accelerates as the pointer gets closer to the viewport edge.
  /// This provides finer control when first entering the zone.
  final bool useProximityScaling;

  /// Curve for proximity-based speed scaling.
  ///
  /// Only used when [useProximityScaling] is true.
  /// - [Curves.linear]: Constant speed increase (default)
  /// - [Curves.easeIn]: Slow start, fast finish (recommended for precision)
  /// - [Curves.easeInQuad]: More gradual acceleration
  ///
  /// When null and [useProximityScaling] is true, linear scaling is used.
  final Curve? speedCurve;

  /// Normal autopan configuration suitable for most use cases.
  ///
  /// This is the recommended starting point for autopan behavior.
  /// Uses balanced settings: 50px edge padding, 10 graph units per tick.
  static const AutoPanConfig normal = AutoPanConfig();

  /// Alias for [normal] configuration.
  @Deprecated('Use AutoPanConfig.normal instead')
  static const AutoPanConfig defaultConfig = normal;

  /// Fast panning configuration for large canvases.
  ///
  /// Uses larger pan amounts and faster intervals for quick navigation.
  static const AutoPanConfig fast = AutoPanConfig(
    edgePadding: 60.0,
    panAmount: 20.0,
    panInterval: Duration(milliseconds: 12),
  );

  /// Slow, precise panning configuration.
  ///
  /// Uses smaller pan amounts and a narrower edge zone for fine control.
  static const AutoPanConfig precise = AutoPanConfig(
    edgePadding: 30.0,
    panAmount: 5.0,
    panInterval: Duration(milliseconds: 20),
  );

  /// Whether autopan is effectively enabled.
  ///
  /// Returns false if edge padding or pan amount is zero or negative.
  bool get isEnabled => edgePadding > 0 && panAmount > 0;

  /// Calculates the scaled pan amount based on proximity to edge.
  ///
  /// [proximity] is the distance from the edge zone boundary to the pointer,
  /// where 0 is at the boundary and [edgePadding] is at the viewport edge.
  ///
  /// Returns [panAmount] scaled according to [useProximityScaling] and
  /// [speedCurve] settings.
  double calculatePanAmount(double proximity) {
    if (!useProximityScaling || edgePadding <= 0) {
      return panAmount;
    }

    // Normalize proximity to 0-1 range (0 = at boundary, 1 = at edge)
    final normalizedProximity = (proximity / edgePadding).clamp(0.0, 1.0);

    // Apply curve if provided, otherwise use linear scaling
    final scaleFactor =
        speedCurve?.transform(normalizedProximity) ?? normalizedProximity;

    // Scale from 0.3x to 1.5x the base amount
    // This ensures some panning even at the boundary while accelerating near edge
    return panAmount * (0.3 + scaleFactor * 1.2);
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is AutoPanConfig &&
        other.edgePadding == edgePadding &&
        other.panAmount == panAmount &&
        other.panInterval == panInterval &&
        other.useProximityScaling == useProximityScaling &&
        other.speedCurve == speedCurve;
  }

  @override
  int get hashCode => Object.hash(
    edgePadding,
    panAmount,
    panInterval,
    useProximityScaling,
    speedCurve,
  );

  @override
  String toString() =>
      'AutoPanConfig('
      'edgePadding: $edgePadding, '
      'panAmount: $panAmount, '
      'panInterval: $panInterval, '
      'useProximityScaling: $useProximityScaling)';
}
