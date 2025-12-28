import 'package:flutter/material.dart';

import '../../editor/themes/node_flow_theme.dart';
import 'grid_style.dart';

/// Grid style that renders nothing.
///
/// This is a null object pattern implementation that provides a "no grid"
/// option without requiring null checks throughout the codebase.
///
/// Use this when you want a clean canvas with no background grid pattern.
class NoneGridStyle extends GridStyle {
  const NoneGridStyle();

  @override
  void paintGrid(
    Canvas canvas,
    NodeFlowTheme theme,
    ({double left, double top, double right, double bottom}) gridArea,
  ) {
    // Intentionally empty - render nothing
  }
}
