import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';

import '../node_flow_config.dart';
import '../node_flow_controller.dart';
import '../node_flow_minimap.dart';
import '../node_flow_theme.dart';

/// Minimap overlay widget that renders the minimap in the specified corner
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

        return Positioned(
          top:
              controller.config.minimapPosition.value ==
                      CornerPosition.topLeft ||
                  controller.config.minimapPosition.value ==
                      CornerPosition.topRight
              ? 20
              : null,
          bottom:
              controller.config.minimapPosition.value ==
                      CornerPosition.bottomLeft ||
                  controller.config.minimapPosition.value ==
                      CornerPosition.bottomRight
              ? 20
              : null,
          left:
              controller.config.minimapPosition.value ==
                      CornerPosition.topLeft ||
                  controller.config.minimapPosition.value ==
                      CornerPosition.bottomLeft
              ? 20
              : null,
          right:
              controller.config.minimapPosition.value ==
                      CornerPosition.topRight ||
                  controller.config.minimapPosition.value ==
                      CornerPosition.bottomRight
              ? 20
              : null,
          child: NodeFlowMinimap<T>(
            controller: controller,
            size: controller.config.minimapSize.value,
            interactive: controller
                .config
                .isMinimapInteractive
                .value, // Explicitly enable interactivity even in read-only mode
          ),
        );
      },
    );
  }
}
