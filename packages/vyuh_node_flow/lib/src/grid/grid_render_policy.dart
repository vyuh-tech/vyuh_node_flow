import '../editor/themes/node_flow_theme.dart';
import 'grid_styles.dart';

/// Runtime rendering policy for grid fidelity.
///
/// During active viewport interaction, this policy can temporarily reduce
/// grid cost to keep panning smooth. Full fidelity is restored immediately
/// when interaction ends.
class GridRenderPolicy {
  const GridRenderPolicy._();

  /// Returns the effective theme to use for grid rendering in the current state.
  static NodeFlowTheme resolve({
    required NodeFlowTheme baseTheme,
    required bool isViewportInteracting,
    required bool adaptiveInteractionActive,
    required bool useThumbnailMode,
  }) {
    if (!isViewportInteracting) {
      return baseTheme;
    }

    // At extreme adaptive fidelity reductions, skip grid rendering entirely.
    // This avoids expensive point/path generation while the scene is in
    // thumbnail mode for interaction responsiveness.
    if (useThumbnailMode) {
      return baseTheme.copyWith(
        gridTheme: baseTheme.gridTheme.copyWith(style: GridStyles.none),
      );
    }

    // Keep default visuals when adaptive mode is not active.
    if (!adaptiveInteractionActive) {
      return baseTheme;
    }

    final gridTheme = baseTheme.gridTheme;
    final coarseSize = (gridTheme.size * 2.0).clamp(8.0, 256.0);
    final coarseColor = gridTheme.color.withValues(
      alpha: (gridTheme.color.a * 0.7).clamp(0.0, 1.0),
    );

    return baseTheme.copyWith(
      gridTheme: gridTheme.copyWith(size: coarseSize, color: coarseColor),
    );
  }
}
