import 'package:flutter/material.dart';

import '../../editor/themes/node_flow_theme.dart';
import 'grid_sampling_policy.dart';
import 'grid_style.dart';

/// Grid style that renders a two-level hierarchical grid.
///
/// Creates a grid with both minor and major lines at different intervals:
/// - Minor lines: Rendered at standard gridSize spacing with lighter color (30% opacity)
/// - Major lines: Rendered at gridSize * majorGridMultiplier spacing with full color and double thickness
///
/// This provides a multi-level visual hierarchy that makes it easier to align
/// elements at different scales.
class HierarchicalGridStyle extends GridStyle {
  const HierarchicalGridStyle({this.majorGridMultiplier = 5});

  /// Multiplier for major grid spacing relative to minor grid.
  ///
  /// For example, if gridSize is 20 and majorGridMultiplier is 5,
  /// minor lines will be every 20 pixels and major lines every 100 pixels.
  final int majorGridMultiplier;

  @override
  void paintGrid(
    Canvas canvas,
    NodeFlowTheme theme,
    GridArea gridArea,
  ) {
    final gridTheme = theme.gridTheme;
    final minorSampling = GridSamplingPolicy.resolve(
      area: gridArea,
      baseSpacing: gridTheme.size,
      maxColumns: 240,
      maxRows: 240,
    );
    if (minorSampling == null) return;

    final majorBaseSpacing = minorSampling.spacing * majorGridMultiplier;
    final majorSampling = GridSamplingPolicy.resolve(
      area: gridArea,
      baseSpacing: majorBaseSpacing,
      maxColumns: 120,
      maxRows: 120,
    );
    if (majorSampling == null) return;

    // Create paint objects for minor and major grids
    final minorPaint = Paint()
      ..color = gridTheme.color.withValues(alpha: 0.3)
      ..strokeWidth = gridTheme.thickness
      ..style = PaintingStyle.stroke;

    final majorPaint = Paint()
      ..color = gridTheme.color
      ..strokeWidth = gridTheme.thickness * 2
      ..style = PaintingStyle.stroke;
    final minorPath = Path();
    final majorPath = Path();

    // Draw minor grid lines
    for (var col = 0; col < minorSampling.columns; col++) {
      final x = minorSampling.startX + col * minorSampling.spacing;
      minorPath
        ..moveTo(x, gridArea.top)
        ..lineTo(x, gridArea.bottom);
    }

    for (var row = 0; row < minorSampling.rows; row++) {
      final y = minorSampling.startY + row * minorSampling.spacing;
      minorPath
        ..moveTo(gridArea.left, y)
        ..lineTo(gridArea.right, y);
    }

    // Draw major grid lines (on top of minor lines)
    for (var col = 0; col < majorSampling.columns; col++) {
      final x = majorSampling.startX + col * majorSampling.spacing;
      majorPath
        ..moveTo(x, gridArea.top)
        ..lineTo(x, gridArea.bottom);
    }

    for (var row = 0; row < majorSampling.rows; row++) {
      final y = majorSampling.startY + row * majorSampling.spacing;
      majorPath
        ..moveTo(gridArea.left, y)
        ..lineTo(gridArea.right, y);
    }

    canvas.drawPath(minorPath, minorPaint);
    canvas.drawPath(majorPath, majorPaint);
  }
}
