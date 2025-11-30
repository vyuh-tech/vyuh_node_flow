import 'package:flutter/material.dart';

import '../graph/canvas_transform_provider.dart';
import '../nodes/node.dart';
import '../ports/port.dart';
import '../ports/port_theme.dart';
import 'port_shape_widget.dart';

/// Builder function type for customizing individual port widgets.
///
/// This typedef defines the signature for custom port builders that can be
/// provided to [NodeFlowEditor] or [NodeWidget] to customize port rendering.
///
/// Parameters:
/// - [context]: The build context
/// - [node]: The node containing this port
/// - [port]: The port being rendered
/// - [isOutput]: Whether this is an output port (true) or input port (false)
/// - [isConnected]: Whether the port currently has any connections
/// - [isHighlighted]: Whether the port is being hovered during connection drag
///
/// Example:
/// ```dart
/// PortBuilder myPortBuilder = (context, node, port, isOutput, isConnected, isHighlighted) {
///   final color = isOutput ? Colors.green : Colors.blue;
///   return PortWidget(
///     port: port,
///     theme: Theme.of(context).extension<NodeFlowTheme>()!.portTheme,
///     isConnected: isConnected,
///     isHighlighted: isHighlighted,
///     color: color,
///   );
/// };
/// ```
typedef PortBuilder<T> =
    Widget Function(
      BuildContext context,
      Node<T> node,
      Port port,
      bool isOutput,
      bool isConnected,
      bool isHighlighted,
    );

/// Widget for rendering a port on a node.
///
/// The [PortWidget] displays a port with its shape, color, and optional label.
/// It supports property overrides at both widget and model levels.
///
/// ## Property Cascade (lowest to highest priority)
///
/// Properties are resolved in this order of precedence:
/// 1. Theme values (from [PortTheme]) - lowest priority
/// 2. Widget-level overrides (constructor parameters)
/// 3. Model-level values (from [Port]) - highest priority
///
/// For example, port size is resolved as:
/// - `port.size` (if different from default) → widget `size` → `theme.size`
///
/// Example with overrides:
/// ```dart
/// PortWidget(
///   port: myPort, // port.size = 12.0 takes precedence
///   theme: PortTheme.light,
///   color: Colors.blue, // Override idle color
///   connectedColor: Colors.green, // Override connected color
/// )
/// ```
class PortWidget extends StatelessWidget {
  const PortWidget({
    super.key,
    required this.port,
    required this.theme,
    this.isConnected = false,
    this.onTap,
    this.onHover,
    this.isHighlighted = false,
    // Property overrides (widget level)
    this.size,
    this.color,
    this.connectedColor,
    this.snappingColor,
    this.borderColor,
    this.highlightBorderColor,
    this.borderWidth,
    this.highlightBorderWidthDelta,
  });

  final Port port;
  final PortTheme theme;
  final bool isConnected;
  final ValueChanged<Port>? onTap;
  final ValueChanged<(Port, bool)>? onHover;
  final bool isHighlighted;

  // Optional property overrides (widget level) - if null, uses model or theme values

  /// Override for the port size.
  /// Resolution: port.size → widget.size → theme.size
  final double? size;

  /// Override for the idle port color.
  final Color? color;

  /// Override for the connected port color.
  final Color? connectedColor;

  /// Override for the snapping (drag-over) port color.
  final Color? snappingColor;

  /// Override for the border color.
  final Color? borderColor;

  /// Override for the highlight border color.
  final Color? highlightBorderColor;

  /// Override for the border width.
  final double? borderWidth;

  /// Override for the additional highlight border width.
  final double? highlightBorderWidthDelta;

  @override
  Widget build(BuildContext context) {
    final effectiveSize = _getPortSize();

    return Stack(
      clipBehavior: Clip.none,
      children: [
        // Marker shape - uses model shape (highest priority)
        MouseRegion(
          onEnter: (_) => onHover?.call((port, true)),
          onExit: (_) => onHover?.call((port, false)),
          child: PortShapeWidget(
            shape: port.shape, // Model level - always wins
            position: port.position,
            size: effectiveSize,
            color: _getPortColor(),
            borderColor: _getBorderColor(),
            borderWidth: _getBorderWidth(),
          ),
        ),
        // Port label (if enabled in both theme and port)
        if (theme.showLabel && port.showLabel)
          _PortLabel(port: port, theme: theme, size: effectiveSize),
      ],
    );
  }

  /// Get the effective port size using the cascade:
  /// port.size (model) → widget.size → theme.size
  double _getPortSize() {
    // Model-level size takes precedence (Port default is 9.0)
    // If port.size differs from default, it was explicitly set
    return port.size != 9.0 ? port.size : (size ?? theme.size);
  }

  /// Determines the appropriate color for the port based on its state.
  ///
  /// Uses widget-level overrides if provided, otherwise falls back to theme.
  Color _getPortColor() {
    if (isHighlighted) {
      return snappingColor ?? theme.snappingColor;
    } else if (isConnected) {
      return connectedColor ?? theme.connectedColor;
    } else {
      return color ?? theme.color;
    }
  }

  /// Get border color based on port state.
  ///
  /// Uses widget-level overrides if provided, otherwise falls back to theme.
  Color _getBorderColor() {
    if (isHighlighted) {
      return highlightBorderColor ?? theme.highlightBorderColor;
    } else {
      return borderColor ?? theme.borderColor;
    }
  }

  /// Get border width based on port state.
  ///
  /// Uses widget-level overrides if provided, otherwise falls back to theme.
  double _getBorderWidth() {
    final baseBorderWidth = borderWidth ?? theme.borderWidth;
    if (isHighlighted) {
      final delta =
          highlightBorderWidthDelta ?? theme.highlightBorderWidthDelta;
      return baseBorderWidth + delta;
    } else {
      return baseBorderWidth;
    }
  }
}

/// Private widget for rendering port labels
/// Handles positioning based on port position and theme settings
class _PortLabel extends StatelessWidget {
  const _PortLabel({
    required this.port,
    required this.theme,
    required this.size,
  });

  final Port port;
  final PortTheme theme;
  final double size;

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
          left: size + theme.labelOffset,
          top: size / 2,
          child: FractionalTranslation(
            translation: const Offset(0.0, -0.5),
            child: Text(port.name, style: textStyle, textAlign: TextAlign.left),
          ),
        );
      case PortPosition.right:
        // Right port: label to the left (inside)
        // Offset from left edge of port, vertically centered
        return Positioned(
          right: size + theme.labelOffset,
          top: size / 2,
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
          left: size / 2,
          top: size / 2 + theme.labelOffset,
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
          left: size / 2,
          bottom: size / 2 + theme.labelOffset,
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
