import 'package:flutter/material.dart';

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
    return MouseRegion(
      onEnter: (_) => onHover?.call((port, true)),
      onExit: (_) => onHover?.call((port, false)),
      child: PortShapeWidget(
        shape: port.shape,
        position: port.position,
        size: theme.size,
        color: _getPortColor(),
        borderColor: _getBorderColor(),
        borderWidth: _getBorderWidth(),
      ),
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
