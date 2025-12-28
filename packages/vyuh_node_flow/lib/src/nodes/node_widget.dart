import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';

import 'node.dart';
import 'node_shape.dart';
import 'node_shape_clipper.dart';
import 'node_shape_painter.dart';
import 'node_theme.dart';

/// A widget that builds the visual content of a node.
///
/// This widget is responsible for rendering the node's visual appearance:
/// - Background color and border
/// - Shape (rectangular, circular, diamond, etc.)
/// - Content (custom child or default type/id display)
/// - Selection styling
///
/// **Important**: This widget does NOT handle:
/// - Positioning (handled by [NodeContainer])
/// - Gestures (handled by [NodeContainer])
/// - Ports (handled by [NodeContainer])
/// - Resize handles (handled by [NodeContainer])
///
/// The widget supports three rendering modes:
/// 1. **Self-rendering**: When [Node.buildWidget] returns non-null, it's used directly
///    (no styling applied - the node controls its own appearance)
/// 2. **Custom content**: Provide a [child] widget for complete control over node appearance
/// 3. **Default style**: Use [NodeWidget.defaultStyle] for standard node rendering
///
/// Example with custom content:
/// ```dart
/// NodeWidget<MyData>(
///   node: myNode,
///   theme: nodeTheme,
///   child: MyCustomNodeContent(data: myNode.data),
///   backgroundColor: Colors.blue.shade50,
/// )
/// ```
///
/// See also:
/// * [NodeContainer], which handles positioning and interactions
/// * [Node], the data model for nodes
/// * [NodeTheme], which defines default styling
class NodeWidget<T> extends StatelessWidget {
  /// Creates a node widget with optional custom content.
  ///
  /// Parameters:
  /// * [node] - The node data model to render
  /// * [theme] - The node theme for styling
  /// * [child] - Optional custom widget to display as node content
  /// * [shape] - Optional shape for the node (renders shaped node instead of rectangle)
  /// * [backgroundColor] - Custom background color (overrides theme)
  /// * [selectedBackgroundColor] - Custom selected background color (overrides theme)
  /// * [borderColor] - Custom border color (overrides theme)
  /// * [selectedBorderColor] - Custom selected border color (overrides theme)
  /// * [borderWidth] - Custom border width (overrides theme)
  /// * [selectedBorderWidth] - Custom selected border width (overrides theme)
  /// * [borderRadius] - Custom border radius (overrides theme)
  /// * [padding] - Custom padding (overrides theme)
  const NodeWidget({
    super.key,
    required this.node,
    required this.theme,
    this.child,
    this.shape,
    this.backgroundColor,
    this.selectedBackgroundColor,
    this.borderColor,
    this.selectedBorderColor,
    this.borderWidth,
    this.selectedBorderWidth,
    this.borderRadius,
    this.padding,
  });

  /// Creates a node widget with default content layout.
  ///
  /// This constructor uses the standard node rendering which displays
  /// the node type as a title and node ID as content.
  const NodeWidget.defaultStyle({
    super.key,
    required this.node,
    required this.theme,
    this.shape,
    this.backgroundColor,
    this.selectedBackgroundColor,
    this.borderColor,
    this.selectedBorderColor,
    this.borderWidth,
    this.selectedBorderWidth,
    this.borderRadius,
    this.padding,
  }) : child = null;

  /// The node data model to render.
  final Node<T> node;

  /// The theme for styling the node.
  final NodeTheme theme;

  /// Optional custom widget to display as node content.
  ///
  /// When null, default content (type and ID) is displayed.
  final Widget? child;

  /// Optional shape for the node.
  ///
  /// When null, the node is rendered as a rectangle.
  /// When provided, the node is rendered using the shape's path and visual properties.
  final NodeShape? shape;

  /// Custom background color.
  final Color? backgroundColor;

  /// Custom background color for selected state.
  final Color? selectedBackgroundColor;

  /// Custom border color.
  final Color? borderColor;

  /// Custom border color for selected state.
  final Color? selectedBorderColor;

  /// Custom border width.
  final double? borderWidth;

  /// Custom border width for selected state.
  final double? selectedBorderWidth;

  /// Custom border radius.
  final BorderRadius? borderRadius;

  /// Custom padding inside the node.
  final EdgeInsets? padding;

  @override
  Widget build(BuildContext context) {
    // Self-rendering nodes handle everything themselves
    final selfRenderedWidget = node.buildWidget(context);
    if (selfRenderedWidget != null) {
      return selfRenderedWidget;
    }

    return Observer(
      builder: (_) {
        final isSelected = node.isSelected;
        final content = child ?? _buildDefaultContent(theme);

        if (shape != null) {
          return _buildShapedNode(theme, isSelected, content);
        } else {
          return _buildRectangularNode(theme, isSelected, content);
        }
      },
    );
  }

  Widget _buildDefaultContent(NodeTheme nodeTheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          node.type,
          style: nodeTheme.titleStyle,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 4),
        Text(
          node.id,
          style: nodeTheme.contentStyle,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  Color _getBackgroundColor(NodeTheme nodeTheme, bool isSelected) {
    if (isSelected) {
      return selectedBackgroundColor ??
          backgroundColor ??
          nodeTheme.selectedBackgroundColor;
    }
    return backgroundColor ?? nodeTheme.backgroundColor;
  }

  Color _getBorderColor(NodeTheme nodeTheme, bool isSelected) {
    if (isSelected) {
      return selectedBorderColor ??
          borderColor ??
          nodeTheme.selectedBorderColor;
    }
    return borderColor ?? nodeTheme.borderColor;
  }

  double _getBorderWidth(NodeTheme nodeTheme, bool isSelected) {
    if (isSelected) {
      return selectedBorderWidth ??
          borderWidth ??
          nodeTheme.selectedBorderWidth;
    }
    return borderWidth ?? nodeTheme.borderWidth;
  }

  Widget _buildShapedNode(
    NodeTheme nodeTheme,
    bool isSelected,
    Widget content,
  ) {
    return CustomPaint(
      painter: NodeShapePainter(
        shape: shape!,
        backgroundColor: _getBackgroundColor(nodeTheme, isSelected),
        borderColor: _getBorderColor(nodeTheme, isSelected),
        borderWidth: _getBorderWidth(nodeTheme, isSelected),
        size: node.size.value,
      ),
      child: ClipPath(
        clipper: NodeShapeClipper(shape: shape!),
        child: Center(child: content),
      ),
    );
  }

  Widget _buildRectangularNode(
    NodeTheme nodeTheme,
    bool isSelected,
    Widget content,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: _getBackgroundColor(nodeTheme, isSelected),
        border: Border.all(
          color: _getBorderColor(nodeTheme, isSelected),
          width: _getBorderWidth(nodeTheme, isSelected),
        ),
        borderRadius: borderRadius ?? nodeTheme.borderRadius,
      ),
      child: content,
    );
  }
}
