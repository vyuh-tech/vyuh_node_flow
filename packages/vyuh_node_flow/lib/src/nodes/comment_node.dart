import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:mobx/mobx.dart';

import '../editor/themes/node_flow_theme.dart';
import 'mixins/resizable_mixin.dart';
import 'node.dart';

/// A comment/sticky note node that can be placed anywhere on the canvas.
///
/// Comment nodes are free-floating elements that can be used for comments,
/// notes, or explanations within your node flow. They support:
/// - Custom text content with inline editing
/// - Configurable size and color
/// - Free movement and positioning
/// - Resizing via drag handles
/// - Auto-grow height when text exceeds current bounds
///
/// Comment nodes render in the foreground layer (above regular nodes).
///
/// ## Example
///
/// ```dart
/// final comment = CommentNode<String>(
///   id: 'note-1',
///   position: Offset(100, 100),
///   text: 'This is a reminder',
///   data: 'optional-data',
///   width: 200,
///   height: 150,
///   color: Colors.yellow,
/// );
/// controller.addNode(comment);
/// ```
class CommentNode<T> extends Node<T> with ResizableMixin<T> {
  CommentNode({
    required super.id,
    required super.position,
    required String text,
    required super.data,
    double width = 200.0,
    double height = 100.0,
    Color color = Colors.yellow,
    int zIndex = 0,
    bool isVisible = true,
    super.locked,
  }) : _text = Observable(text),
       _color = Observable(color),
       super(
         type: 'comment',
         size: Size(width, height),
         layer: NodeRenderLayer.foreground,
         initialZIndex: zIndex,
         visible: isVisible,
         selectable: true,
         inputPorts: const [],
         outputPorts: const [],
       );

  /// Observable text content of the comment.
  final Observable<String> _text;

  /// The text content displayed in the comment.
  String get text => _text.value;
  set text(String value) => runInAction(() => _text.value = value);

  /// Observable background color of the comment.
  final Observable<Color> _color;

  /// The background color of the comment.
  Color get color => _color.value;
  set color(Color value) => runInAction(() => _color.value = value);

  /// The width of the comment in pixels.
  double get width => size.value.width;

  /// The height of the comment in pixels.
  double get height => size.value.height;

  /// Minimum and maximum size constraints for comments.
  static const double minWidth = 100.0;
  static const double minHeight = 60.0;
  static const double maxWidth = 600.0;
  static const double maxHeight = 400.0;

  @override
  Size get minSize => const Size(minWidth, minHeight);

  @override
  Size? get maxSize => const Size(maxWidth, maxHeight);

  @override
  void setSize(Size newSize) {
    final constrainedSize = Size(
      newSize.width.clamp(minWidth, maxWidth),
      newSize.height.clamp(minHeight, maxHeight),
    );
    super.setSize(constrainedSize);
  }

  @override
  Widget? buildWidget(BuildContext context) {
    // Respect instance-level widgetBuilder first
    if (widgetBuilder != null) {
      return widgetBuilder!(context, this);
    }
    // CommentNode is self-rendering with its own styled content
    return _CommentContent<T>(node: this);
  }

  @override
  void paintThumbnail(
    Canvas canvas,
    Rect bounds, {
    required Color color,
    required bool isSelected,
    Color? selectedBorderColor,
    double borderRadius = 4.0,
  }) {
    // Use the comment's own color (not the parameter) with 15% opacity
    final commentColor = this.color.withValues(alpha: 0.15);
    final rrect = RRect.fromRectAndRadius(
      bounds,
      Radius.circular(borderRadius),
    );

    final paint = Paint()
      ..style = PaintingStyle.fill
      ..color = commentColor;
    canvas.drawRRect(rrect, paint);
  }

  @override
  void paintMinimapThumbnail(
    Canvas canvas,
    Rect bounds, {
    required Color defaultColor,
    double borderRadius = 2.0,
  }) {
    // Use the comment's own color with 15% opacity for subtle appearance
    final commentColor = color.withValues(alpha: 0.15);
    final rrect = RRect.fromRectAndRadius(
      bounds,
      Radius.circular(borderRadius),
    );

    final paint = Paint()
      ..style = PaintingStyle.fill
      ..color = commentColor;
    canvas.drawRRect(rrect, paint);
  }

  /// Creates a copy of this comment node with optional property overrides.
  ///
  /// This is useful for creating variations of an existing comment or
  /// for implementing undo/redo functionality.
  CommentNode<T> copyWith({
    String? id,
    Offset? position,
    String? text,
    T? data,
    double? width,
    double? height,
    Color? color,
    int? zIndex,
    bool? isVisible,
    bool? locked,
  }) {
    return CommentNode<T>(
      id: id ?? this.id,
      position: position ?? this.position.value,
      text: text ?? this.text,
      data: data ?? this.data,
      width: width ?? this.width,
      height: height ?? this.height,
      color: color ?? this.color,
      zIndex: zIndex ?? this.zIndex.value,
      isVisible: isVisible ?? this.isVisible,
      locked: locked ?? this.locked,
    );
  }

  /// Creates a [CommentNode] from a JSON map.
  ///
  /// This factory constructor is used during workflow deserialization to recreate
  /// comment nodes from saved data.
  ///
  /// Parameters:
  /// * [json] - The JSON map containing node data
  /// * [dataFromJson] - Function to deserialize the custom data of type [T]
  factory CommentNode.fromJson(
    Map<String, dynamic> json, {
    required T Function(Object? json) dataFromJson,
  }) {
    return CommentNode<T>(
      id: json['id'] as String,
      position: Offset(
        (json['x'] as num).toDouble(),
        (json['y'] as num).toDouble(),
      ),
      text: json['text'] as String? ?? '',
      data: dataFromJson(json['data']),
      width: (json['width'] as num?)?.toDouble() ?? 200.0,
      height: (json['height'] as num?)?.toDouble() ?? 100.0,
      color: Color(json['color'] as int? ?? Colors.yellow.toARGB32()),
      zIndex: json['zIndex'] as int? ?? 0,
      isVisible: json['isVisible'] as bool? ?? true,
      locked: json['locked'] as bool? ?? false,
    );
  }

  /// Converts this comment node to a JSON map.
  @override
  Map<String, dynamic> toJson(Object? Function(T value) toJsonT) => {
    ...super.toJson(toJsonT),
    'text': text,
    'color': color.toARGB32(),
  };
}

/// Internal widget for rendering comment content.
///
/// This StatefulWidget manages the text editing state, including the
/// TextEditingController and FocusNode needed for in-place editing.
class _CommentContent<T> extends StatefulWidget {
  const _CommentContent({super.key, required this.node});

  final CommentNode<T> node;

  @override
  State<_CommentContent<T>> createState() => _CommentContentState<T>();
}

class _CommentContentState<T> extends State<_CommentContent<T>> {
  late TextEditingController _textController;
  late FocusNode _focusNode;
  ReactionDisposer? _editingReaction;

  /// Stores the original text when editing starts, for cancel/restore.
  String _originalText = '';

  // For auto-grow calculation
  static const double _padding = 12.0;
  static const double _lineHeightFactor = 1.4;

  @override
  void initState() {
    super.initState();
    _textController = TextEditingController(text: widget.node.text);
    _focusNode = FocusNode();

    // React to editing state changes to auto-focus
    _editingReaction = reaction((_) => widget.node.isEditing, (bool isEditing) {
      if (isEditing) {
        // Store original text for potential cancel
        _originalText = widget.node.text;
        // Sync controller with current node text
        _textController.text = _originalText;

        // Auto-focus when editing starts
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            _focusNode.requestFocus();
            // Select all text for easy replacement
            _textController.selection = TextSelection(
              baseOffset: 0,
              extentOffset: _textController.text.length,
            );
          }
        });
      } else {
        _commitEdit();
      }
    }, fireImmediately: true);

    // Handle focus loss to end editing
    _focusNode.addListener(_onFocusChange);

    // Listen to text changes for auto-grow
    _textController.addListener(_onTextChanged);
  }

  void _onFocusChange() {
    if (!_focusNode.hasFocus && widget.node.isEditing) {
      _commitEdit();
    }
  }

  void _onTextChanged() {
    if (!widget.node.isEditing) return;

    // Schedule height calculation after the frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _updateHeightIfNeeded();
      }
    });
  }

  void _updateHeightIfNeeded() {
    final node = widget.node;
    final text = _textController.text;

    // Get the text style from node theme
    final flowTheme = Theme.of(context).extension<NodeFlowTheme>();
    final textStyle =
        flowTheme?.nodeTheme.titleStyle ??
        Theme.of(context).textTheme.bodyMedium;
    final fontSize = textStyle?.fontSize ?? 14.0;
    final lineHeight = fontSize * _lineHeightFactor;

    // Calculate required height based on text content
    final textPainter = TextPainter(
      text: TextSpan(text: text.isEmpty ? ' ' : text, style: textStyle),
      textDirection: TextDirection.ltr,
      maxLines: null,
    );

    // Layout with the available width (minus padding)
    final availableWidth = node.width - (_padding * 2);
    textPainter.layout(maxWidth: availableWidth);

    // Calculate required height: text height + padding + some buffer
    final requiredHeight = textPainter.height + (_padding * 2) + lineHeight;

    // Only grow, don't shrink below current height (user can manually resize smaller)
    if (requiredHeight > node.height) {
      final newHeight = requiredHeight.clamp(
        CommentNode.minHeight,
        CommentNode.maxHeight,
      );
      if (newHeight > node.height) {
        node.setSize(Size(node.width, newHeight));
      }
    }
  }

  void _commitEdit() {
    widget.node.text = _textController.text;
    widget.node.isEditing = false;
  }

  /// Cancels the edit and restores the original text.
  void _cancelEdit() {
    _textController.text = _originalText;
    widget.node.isEditing = false;
  }

  @override
  void dispose() {
    _editingReaction?.call();
    _textController.removeListener(_onTextChanged);
    _focusNode.removeListener(_onFocusChange);
    _focusNode.dispose();
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final flowTheme = Theme.of(context).extension<NodeFlowTheme>();
    assert(flowTheme != null, 'NodeFlowTheme must be provided in the context');

    final nodeTheme = flowTheme!.nodeTheme;
    final textStyle = nodeTheme.titleStyle;

    return Observer(
      builder: (_) {
        final isEditing = widget.node.isEditing;
        final isSelected = widget.node.isSelected;
        final node = widget.node;

        return Container(
          width: node.width,
          height: node.height,
          decoration: BoxDecoration(
            color: node.color.withValues(alpha: 0.9),
            borderRadius: nodeTheme.borderRadius,
            border: Border.all(
              color: isSelected
                  ? nodeTheme.selectedBorderColor
                  : Colors.transparent,
              width: nodeTheme.selectedBorderWidth,
            ),
          ),
          padding: const EdgeInsets.all(_padding),
          child: isEditing
              ? Focus(
                  // Capture Escape key before TextField processes it
                  onKeyEvent: (node, event) {
                    if (event is KeyDownEvent &&
                        event.logicalKey == LogicalKeyboardKey.escape) {
                      _cancelEdit();
                      return KeyEventResult.handled;
                    }
                    return KeyEventResult.ignored;
                  },
                  child: TextField(
                    controller: _textController,
                    focusNode: _focusNode,
                    style: textStyle,
                    maxLines: null,
                    expands: true,
                    textAlignVertical: TextAlignVertical.top,
                    cursorColor: Colors.black87,
                    decoration: const InputDecoration(
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      filled: false,
                      isDense: true,
                      isCollapsed: true,
                      contentPadding: EdgeInsets.zero,
                    ),
                    onSubmitted: (_) => _commitEdit(),
                  ),
                )
              : Text(node.text, style: textStyle, overflow: TextOverflow.fade),
        );
      },
    );
  }
}
