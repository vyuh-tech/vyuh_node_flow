import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';

import '../minimap_theme.dart';
import '../node_flow_controller.dart';
import '../node_flow_minimap.dart';
import '../node_flow_theme.dart';

/// Minimap overlay widget that renders the minimap in the specified corner.
///
/// Uses [MinimapTheme] from [NodeFlowTheme] for positioning and styling.
class MinimapOverlay<T> extends StatelessWidget {
  const MinimapOverlay({
    super.key,
    required this.controller,
    required this.theme,
    required this.transformationController,
    required this.canvasSize,
  });

  final NodeFlowController<T> controller;
  final NodeFlowTheme theme;
  final TransformationController transformationController;
  final Size canvasSize;

  @override
  Widget build(BuildContext context) {
    return Observer(
      builder: (_) {
        if (!controller.config.showMinimap.value) {
          return const SizedBox.shrink();
        }

        final minimapTheme = theme.minimapTheme;
        final position = minimapTheme.position;
        final margin = minimapTheme.margin;

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
            interactive: controller.config.isMinimapInteractive.value,
          ),
        );
      },
    );
  }
}
