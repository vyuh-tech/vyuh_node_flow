import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';

import '../../editor/controller/node_flow_controller.dart';
import 'minimap_extension.dart';
import 'node_flow_minimap.dart';

/// Minimap overlay widget that renders the minimap in the specified corner.
///
/// Uses [MinimapExtension] for positioning, styling, and state.
/// Theme, position, and margin are all configured via the extension.
class MinimapOverlay<T> extends StatelessWidget {
  const MinimapOverlay({
    super.key,
    required this.controller,
  });

  final NodeFlowController<T, dynamic> controller;

  @override
  Widget build(BuildContext context) {
    final minimap = controller.minimap;

    // If minimap extension is not configured, render nothing
    if (minimap == null) {
      return const SizedBox.shrink();
    }

    // Observer for reactive updates when minimap visibility or settings change
    return Observer(
      builder: (_) {
        // If minimap is not visible, render nothing
        if (!minimap.isVisible) {
          return const SizedBox.shrink();
        }

        // Get theme, position, and margin from extension (not NodeFlowTheme)
        final minimapTheme = minimap.theme;
        final position = minimap.position;
        final margin = minimap.margin;

        return Positioned(
          top:
              position == MinimapPosition.topLeft ||
                  position == MinimapPosition.topRight
              ? margin
              : null,
          bottom:
              position == MinimapPosition.bottomLeft ||
                  position == MinimapPosition.bottomRight
              ? margin
              : null,
          left:
              position == MinimapPosition.topLeft ||
                  position == MinimapPosition.bottomLeft
              ? margin
              : null,
          right:
              position == MinimapPosition.topRight ||
                  position == MinimapPosition.bottomRight
              ? margin
              : null,
          child: NodeFlowMinimap<T>(
            controller: controller,
            theme: minimapTheme,
            size: minimap.size,
            interactive: minimap.isInteractive,
          ),
        );
      },
    );
  }
}
