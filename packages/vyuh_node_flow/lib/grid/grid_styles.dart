import 'styles/cross_grid_style.dart';
import 'styles/dots_grid_style.dart';
import 'styles/grid_style.dart';
import 'styles/hierarchical_grid_style.dart';
import 'styles/lines_grid_style.dart';
import 'styles/none_grid_style.dart';

/// Provides static constants for different grid styles.
///
/// This class offers pre-configured grid style instances that can be used
/// directly in themes or custom configurations.
///
/// Example usage:
/// ```dart
/// // Use in theme
/// final theme = NodeFlowTheme.light.copyWith(
///   gridStyle: GridStyles.lines,
/// );
///
/// // Use with custom multiplier for hierarchical
/// final customHierarchical = HierarchicalGridStyle(majorGridMultiplier: 10);
/// ```
final class GridStyles {
  // Private constructor to prevent instantiation
  GridStyles._();

  /// Lines grid style - evenly spaced vertical and horizontal lines.
  ///
  /// This is the most common grid style, providing clear visual reference.
  static const GridStyle lines = LinesGridStyle();

  /// Dots grid style - dots at grid intersections.
  ///
  /// More subtle than lines, reducing visual clutter while maintaining
  /// reference points.
  static const GridStyle dots = DotsGridStyle();

  /// Cross grid style - small crosses at grid intersections.
  ///
  /// More distinct than dots while remaining less prominent than full lines.
  static const GridStyle cross = CrossGridStyle();

  /// Hierarchical grid style with default 5x multiplier.
  ///
  /// Renders both minor and major lines at different intervals.
  /// Major lines appear every 5 minor grid cells.
  ///
  /// To create a hierarchical grid with a custom multiplier:
  /// ```dart
  /// final customHierarchical = HierarchicalGridStyle(majorGridMultiplier: 10);
  /// ```
  static const GridStyle hierarchical = HierarchicalGridStyle();

  /// No grid style - renders nothing.
  ///
  /// Provides a clean canvas with no background pattern.
  static const GridStyle none = NoneGridStyle();
}
