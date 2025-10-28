import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';

import '../connections/connection.dart';
import '../graph/node_flow_theme.dart';
import '../nodes/node.dart';
import '../nodes/node_theme.dart';
import '../ports/port.dart';
import '../ports/port_widget.dart';

/// A unified node widget that handles positioning, core node functionality (ports, theming, interactions)
/// while allowing custom content to be provided as a child.
/// Works with Node\<T\> using MobX observables for reactive updates with optimized positioning.
///
/// Appearance can be customized per-node by providing optional appearance parameters.
/// If not provided, values from the theme will be used.
class NodeWidget<T> extends StatelessWidget {
  const NodeWidget({
    super.key,
    required this.node,
    this.child,
    this.connections = const [],
    this.onPortTap,
    this.onPortHover,
    this.onNodeTap,
    this.onNodeDoubleTap,
    this.hoveredPortInfo,
    this.backgroundColor,
    this.selectedBackgroundColor,
    this.borderColor,
    this.selectedBorderColor,
    this.borderWidth,
    this.selectedBorderWidth,
    this.borderRadius,
    this.padding,
  });

  /// Creates a default node widget with standard content layout
  const NodeWidget.defaultStyle({
    super.key,
    required this.node,
    this.connections = const [],
    this.onPortTap,
    this.onPortHover,
    this.onNodeTap,
    this.onNodeDoubleTap,
    this.hoveredPortInfo,
    this.backgroundColor,
    this.selectedBackgroundColor,
    this.borderColor,
    this.selectedBorderColor,
    this.borderWidth,
    this.selectedBorderWidth,
    this.borderRadius,
    this.padding,
  }) : child = null;

  final Node<T> node;
  final Widget? child;
  final List<Connection> connections;
  final void Function(String nodeId, String portId, bool isOutput)? onPortTap;
  final void Function(String nodeId, String portId, bool isHover)? onPortHover;
  final void Function(String nodeId)? onNodeTap;
  final void Function(String nodeId)? onNodeDoubleTap;
  final ({String nodeId, String portId, bool isOutput})? hoveredPortInfo;

  /// Custom background color (overrides theme default)
  final Color? backgroundColor;

  /// Custom background color when selected (overrides theme default)
  final Color? selectedBackgroundColor;

  /// Custom border color (overrides theme default)
  final Color? borderColor;

  /// Custom border color when selected (overrides theme default)
  final Color? selectedBorderColor;

  /// Custom border width (overrides theme default)
  final double? borderWidth;

  /// Custom border width when selected (overrides theme default)
  final double? selectedBorderWidth;

  /// Custom border radius (overrides theme default)
  final BorderRadius? borderRadius;

  /// Custom padding (overrides theme default)
  final EdgeInsets? padding;

  @override
  Widget build(BuildContext context) {
    final theme =
        Theme.of(context).extension<NodeFlowTheme>() ?? NodeFlowTheme.light;
    final nodeTheme = theme.nodeTheme;

    return Observer(
      builder: (context) {
        // Use visual position for rendering
        final position = node.visualPosition.value;
        final isSelected = node.isSelected;
        final size = node.size;

        return Positioned(
          left: position.dx,
          top: position.dy,
          child: SizedBox(
            width: size.width,
            height: size.height,
            child: GestureDetector(
              onTap: () => onNodeTap?.call(node.id),
              onDoubleTap: () => onNodeDoubleTap?.call(node.id),
              child: Stack(
                children: [
                  // Main node visual (inset by portHalfSize)
                  Positioned.fill(
                    child: Container(
                      margin: padding ?? nodeTheme.padding,
                      clipBehavior: Clip.antiAlias,
                      decoration: BoxDecoration(
                        color: _getNodeBackgroundColor(nodeTheme, isSelected),
                        border: Border.all(
                          color: _getNodeBorderColor(nodeTheme, isSelected),
                          width: _getNodeBorderWidth(nodeTheme, isSelected),
                        ),
                        borderRadius: borderRadius ?? nodeTheme.borderRadius,
                      ),
                      child: _buildNodeContent(nodeTheme),
                    ),
                  ),

                  // Input ports (positioned on edges of padded container)
                  ...node.inputPorts.map(
                    (port) => _buildPort(context, port, false, nodeTheme),
                  ),

                  // Output ports (positioned on edges of padded container)
                  ...node.outputPorts.map(
                    (port) => _buildPort(context, port, true, nodeTheme),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Color _getNodeBackgroundColor(NodeTheme nodeTheme, bool isSelected) {
    if (isSelected) {
      return selectedBackgroundColor ??
          backgroundColor ??
          nodeTheme.selectedBackgroundColor;
    } else {
      return backgroundColor ?? nodeTheme.backgroundColor;
    }
  }

  Color _getNodeBorderColor(NodeTheme nodeTheme, bool isSelected) {
    if (isSelected) {
      return selectedBorderColor ?? borderColor ?? nodeTheme.selectedBorderColor;
    } else {
      return borderColor ?? nodeTheme.borderColor;
    }
  }

  double _getNodeBorderWidth(NodeTheme nodeTheme, bool isSelected) {
    if (isSelected) {
      return selectedBorderWidth ?? borderWidth ?? nodeTheme.selectedBorderWidth;
    } else {
      return borderWidth ?? nodeTheme.borderWidth;
    }
  }

  Widget _buildNodeContent(NodeTheme nodeTheme) {
    // Use custom child if provided, otherwise fall back to default content
    if (child != null) {
      return child!;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Node title - always visible
        Text(
          node.type,
          style: nodeTheme.titleStyle,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),

        SizedBox(height: nodeTheme.padding.top / 3),

        // Simple node info
        Text(
          node.id,
          style: nodeTheme.contentStyle,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  Widget _buildPort(
    BuildContext context,
    Port port,
    bool isOutput,
    NodeTheme nodeTheme,
  ) {
    final theme =
        Theme.of(context).extension<NodeFlowTheme>() ?? NodeFlowTheme.light;
    final portTheme = theme.portTheme;
    final isConnected = _isPortConnected(port.id, isOutput);

    // Get the visual position from the Node model
    final visualPosition = node.getVisualPortPosition(
      port.id,
      portSize: portTheme.size,
    );

    return Positioned(
      left: visualPosition.dx,
      top: visualPosition.dy,
      child: PortWidget(
        port: port,
        theme: portTheme,
        isConnected: isConnected,
        isHighlighted: _isPortHighlighted(port.id, isOutput),
        onTap: onPortTap != null
            ? (p) => onPortTap!(node.id, p.id, isOutput)
            : null,
        onHover: onPortHover != null
            ? (data) => onPortHover!(node.id, data.$1.id, data.$2)
            : null,
      ),
    );
  }

  /// Checks if a port is connected by examining the connections list
  bool _isPortConnected(String portId, bool isOutput) {
    return connections.any((connection) {
      if (isOutput) {
        // For output ports, check if this port is the source of any connection
        return connection.sourceNodeId == node.id &&
            connection.sourcePortId == portId;
      } else {
        // For input ports, check if this port is the target of any connection
        return connection.targetNodeId == node.id &&
            connection.targetPortId == portId;
      }
    });
  }

  /// Checks if a port is highlighted (being hovered during connection drag)
  bool _isPortHighlighted(String portId, bool isOutput) {
    return hoveredPortInfo?.nodeId == node.id &&
        hoveredPortInfo?.portId == portId &&
        hoveredPortInfo?.isOutput == isOutput;
  }
}
