import 'detail_visibility.dart';

/// Configuration for Level of Detail (LOD) thresholds.
///
/// LOD controls which visual elements are rendered based on the current
/// zoom level. This improves performance when viewing large graphs and
/// reduces visual clutter at low zoom levels.
///
/// The zoom level is normalized to a 0.0-1.0 range based on the
/// [NodeFlowConfig.minZoom] and [NodeFlowConfig.maxZoom] values:
/// - 0.0 = at minimum zoom (most zoomed out)
/// - 1.0 = at maximum zoom (most zoomed in)
///
/// ## Threshold Behavior
///
/// ```
/// normalizedZoom:  0.0 ─────── minThreshold ─────── midThreshold ─────── 1.0
///                   │              │                    │               │
/// Visibility:    [  minVisibility ][   midVisibility   ][  maxVisibility ]
/// ```
///
/// Example:
/// ```dart
/// // Default configuration
/// final config = LODConfig();
///
/// // Custom thresholds
/// final custom = LODConfig(
///   minThreshold: 0.2,
///   midThreshold: 0.5,
///   minVisibility: DetailVisibility.minimal,
///   midVisibility: DetailVisibility.standard,
///   maxVisibility: DetailVisibility.full,
/// );
///
/// // Disable LOD (always show full detail)
/// final disabled = LODConfig.disabled;
/// ```
class LODConfig {
  /// Creates an LOD configuration with the specified thresholds and visibility.
  ///
  /// Parameters:
  /// - [minThreshold]: Normalized zoom below which [minVisibility] is used (default: 0.25)
  /// - [midThreshold]: Normalized zoom below which [midVisibility] is used (default: 0.60)
  /// - [minVisibility]: Visibility settings for lowest zoom level (default: minimal)
  /// - [midVisibility]: Visibility settings for medium zoom level (default: standard)
  /// - [maxVisibility]: Visibility settings for highest zoom level (default: full)
  const LODConfig({
    this.minThreshold = 0.03,
    this.midThreshold = 0.1,
    this.minVisibility = DetailVisibility.minimal,
    this.midVisibility = DetailVisibility.standard,
    this.maxVisibility = DetailVisibility.full,
  }) : assert(
         minThreshold >= 0.0 && minThreshold <= 1.0,
         'minThreshold must be between 0.0 and 1.0',
       ),
       assert(
         midThreshold >= 0.0 && midThreshold <= 1.0,
         'midThreshold must be between 0.0 and 1.0',
       ),
       assert(
         minThreshold <= midThreshold,
         'minThreshold must be <= midThreshold',
       );

  /// Normalized zoom threshold for minimal detail.
  ///
  /// When the normalized zoom is below this value, [minVisibility] is applied.
  /// Range: 0.0 to 1.0. Default: 0.25 (25% of zoom range).
  final double minThreshold;

  /// Normalized zoom threshold for standard detail.
  ///
  /// When the normalized zoom is at or above [minThreshold] but below this value,
  /// [midVisibility] is applied. When at or above this value, [maxVisibility]
  /// is applied.
  /// Range: 0.0 to 1.0. Default: 0.60 (60% of zoom range).
  final double midThreshold;

  /// Visibility configuration applied when normalizedZoom < [minThreshold].
  ///
  /// Default: [DetailVisibility.minimal] - only simple colored shapes.
  final DetailVisibility minVisibility;

  /// Visibility configuration applied when
  /// [minThreshold] <= normalizedZoom < [midThreshold].
  ///
  /// Default: [DetailVisibility.standard] - nodes, ports, and connections
  /// without labels.
  final DetailVisibility midVisibility;

  /// Visibility configuration applied when normalizedZoom >= [midThreshold].
  ///
  /// Default: [DetailVisibility.full] - all elements visible.
  final DetailVisibility maxVisibility;

  /// Default LOD configuration.
  ///
  /// Uses thresholds at 25% and 60% of the zoom range with
  /// minimal, standard, and full visibility presets.
  static const LODConfig defaultConfig = LODConfig();

  /// Disabled LOD configuration - always shows full detail.
  ///
  /// Use this to effectively disable the LOD system while keeping
  /// the infrastructure in place.
  static const LODConfig disabled = LODConfig(
    minThreshold: 0.0,
    midThreshold: 0.0,
  );

  /// Determines the appropriate visibility for a given normalized zoom value.
  ///
  /// [normalizedZoom] should be in the range 0.0 to 1.0 where:
  /// - 0.0 represents the minimum zoom (most zoomed out)
  /// - 1.0 represents the maximum zoom (most zoomed in)
  DetailVisibility getVisibilityForZoom(double normalizedZoom) {
    if (normalizedZoom < minThreshold) {
      return minVisibility;
    } else if (normalizedZoom < midThreshold) {
      return midVisibility;
    } else {
      return maxVisibility;
    }
  }

  /// Creates a copy of this configuration with the specified overrides.
  LODConfig copyWith({
    double? minThreshold,
    double? midThreshold,
    DetailVisibility? minVisibility,
    DetailVisibility? midVisibility,
    DetailVisibility? maxVisibility,
  }) {
    return LODConfig(
      minThreshold: minThreshold ?? this.minThreshold,
      midThreshold: midThreshold ?? this.midThreshold,
      minVisibility: minVisibility ?? this.minVisibility,
      midVisibility: midVisibility ?? this.midVisibility,
      maxVisibility: maxVisibility ?? this.maxVisibility,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is LODConfig &&
        other.minThreshold == minThreshold &&
        other.midThreshold == midThreshold &&
        other.minVisibility == minVisibility &&
        other.midVisibility == midVisibility &&
        other.maxVisibility == maxVisibility;
  }

  @override
  int get hashCode => Object.hash(
    minThreshold,
    midThreshold,
    minVisibility,
    midVisibility,
    maxVisibility,
  );

  @override
  String toString() =>
      'LODConfig('
      'minThreshold: $minThreshold, '
      'midThreshold: $midThreshold, '
      'minVisibility: $minVisibility, '
      'midVisibility: $midVisibility, '
      'maxVisibility: $maxVisibility)';
}
