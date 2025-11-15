import 'package:flutter/material.dart';

import '../graph/canvas_transform_provider.dart';
import '../ports/port.dart';
import '../ports/port_theme.dart';
import 'port_shape_widget.dart';

class PortWidget extends StatelessWidget {
  const PortWidget({
    super.key,
    required this.port,
    required this.theme,
    this.isConnected = false,
    this.onTap,
    this.onHover,
    this.isHighlighted = false,
  });

  final Port port;
  final PortTheme theme;
  final bool isConnected;
  final ValueChanged<Port>? onTap;
  final ValueChanged<(Port, bool)>? onHover;
  final bool isHighlighted;

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        // Port shape
        MouseRegion(
          onEnter: (_) => onHover?.call((port, true)),
          onExit: (_) => onHover?.call((port, false)),
          child: PortShapeWidget(
            shape: port.shape,
            position: port.position,
            size: theme.size,
            color: _getPortColor(),
            borderColor: _getBorderColor(),
            borderWidth: _getBorderWidth(),
            isOutputPort: port.isSource,
          ),
        ),
        // Port label (if enabled in both theme and port)
        if (theme.showLabel && port.showLabel)
          _PortLabel(port: port, theme: theme),
      ],
    );
  }

  /// Determines the appropriate color for the port based on its state
  Color _getPortColor() {
    if (isHighlighted) {
      return theme.snappingColor; // Use snapping color for drag operations
    } else if (isConnected) {
      return theme.connectedColor;
    } else {
      return theme.color;
    }
  }

  /// Get border color based on port state
  Color _getBorderColor() {
    if (isHighlighted) {
      return Colors.black; // Strong black border for snap feedback
    } else {
      return theme.borderColor;
    }
  }

  /// Get border width based on port state
  double _getBorderWidth() {
    if (isHighlighted) {
      return theme.borderWidth + 1.5;
    } else {
      return theme.borderWidth;
    }
  }
}

/// Private widget for rendering port labels
/// Handles positioning based on port position and theme settings
class _PortLabel extends StatelessWidget {
  const _PortLabel({required this.port, required this.theme});

  final Port port;
  final PortTheme theme;

  @override
  Widget build(BuildContext context) {
    // Check zoom level for responsive visibility
    final canvasProvider = CanvasTransformProvider.of(context);
    final currentScale = canvasProvider?.scale ?? 1.0;

    // Hide label if zoom is below threshold
    if (currentScale < theme.labelVisibilityThreshold) {
      return const SizedBox.shrink();
    }

    final textStyle =
        theme.labelTextStyle ??
        const TextStyle(
          fontSize: 10.0,
          color: Color(0xFF333333),
          fontWeight: FontWeight.w500,
        );

    // Calculate label position based on port position
    // Labels appear "inside" (toward the node)
    // Offset is measured from the inner edge of the port
    switch (port.position) {
      case PortPosition.left:
        // Left port: label to the right (inside)
        // Offset from right edge of port, vertically centered
        return Positioned(
          left: theme.size + theme.labelOffset,
          top: theme.size / 2,
          child: FractionalTranslation(
            translation: const Offset(0.0, -0.5),
            child: Text(port.name, style: textStyle, textAlign: TextAlign.left),
          ),
        );
      case PortPosition.right:
        // Right port: label to the left (inside)
        // Offset from left edge of port, vertically centered
        return Positioned(
          right: theme.size + theme.labelOffset,
          top: theme.size / 2,
          child: FractionalTranslation(
            translation: const Offset(0.0, -0.5),
            child: Text(
              port.name,
              style: textStyle,
              textAlign: TextAlign.right,
            ),
          ),
        );
      case PortPosition.top:
        // Top port: label below (inside)
        // Offset from bottom edge of port, horizontally centered
        return Positioned(
          left: theme.size / 2,
          top: theme.size / 2 + theme.labelOffset,
          child: FractionalTranslation(
            translation: const Offset(-0.5, 0.0), // Center horizontally
            child: Text(
              port.name,
              style: textStyle,
              textAlign: TextAlign.center,
            ),
          ),
        );
      case PortPosition.bottom:
        // Bottom port: label above (inside)
        // Offset from top edge of port, horizontally centered
        return Positioned(
          left: theme.size / 2,
          bottom: theme.size / 2 + theme.labelOffset,
          child: FractionalTranslation(
            translation: const Offset(-0.5, 0.0), // Center horizontally
            child: Text(
              port.name,
              style: textStyle,
              textAlign: TextAlign.center,
            ),
          ),
        );
    }
  }
}
