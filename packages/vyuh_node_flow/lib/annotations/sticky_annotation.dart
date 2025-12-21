import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:mobx/mobx.dart';

import '../graph/node_flow_theme.dart';
import 'annotation.dart';

/// A sticky note annotation that can be placed anywhere on the canvas.
///
/// Sticky notes are free-floating annotations that can be used for comments,
/// notes, or explanations within your node flow. They support:
/// - Custom text content
/// - Configurable size and color
/// - Free movement and positioning
/// - Resizing via drag handles
///
/// ## Example
///
/// ```dart
/// final sticky = StickyAnnotation(
///   id: 'note-1',
///   position: Offset(100, 100),
///   text: 'This is a reminder',
///   width: 200,
///   height: 150,
///   color: Colors.yellow,
/// );
/// controller.annotations.addAnnotation(sticky);
/// ```
class StickyAnnotation extends Annotation {
  StickyAnnotation({
    required super.id,
    required Offset position,
    required String text,
    double width = 200.0,
    double height = 100.0,
    this.color = Colors.yellow,
    int zIndex = 0,
    bool isVisible = true,
    super.selected = false,
    super.isInteractive = true,
    super.metadata,
  }) : _text = Observable(text),
       _width = Observable(width),
       _height = Observable(height),
       super(
         type: 'sticky',
         initialPosition: position,
         initialZIndex: zIndex,
         initialIsVisible: isVisible,
       );

  /// Observable text content of the sticky note.
  final Observable<String> _text;

  /// The text content displayed in the sticky note.
  String get text => _text.value;
  set text(String value) => runInAction(() => _text.value = value);

  /// Observable width of the sticky note.
  final Observable<double> _width;

  /// Observable height of the sticky note.
  final Observable<double> _height;

  /// The width of the sticky note in pixels.
  double get width => _width.value;
  set width(double value) => runInAction(() => _width.value = value);

  /// The height of the sticky note in pixels.
  double get height => _height.value;
  set height(double value) => runInAction(() => _height.value = value);

  /// The background color of the sticky note.
  final Color color;

  /// Minimum and maximum size constraints for sticky notes.
  static const double minWidth = 100.0;
  static const double minHeight = 60.0;
  static const double maxWidth = 600.0;
  static const double maxHeight = 400.0;

  @override
  Size get size => Size(width, height);

  @override
  bool get isResizable => true;

  @override
  void setSize(Size newSize) {
    runInAction(() {
      _width.value = newSize.width.clamp(minWidth, maxWidth);
      _height.value = newSize.height.clamp(minHeight, maxHeight);
    });
  }

  @override
  Widget buildWidget(BuildContext context) {
    return _StickyContent(annotation: this);
  }

  /// Creates a copy of this sticky annotation with optional property overrides.
  ///
  /// This is useful for creating variations of an existing sticky note or
  /// for implementing undo/redo functionality.
  StickyAnnotation copyWith({
    String? id,
    Offset? position,
    String? text,
    double? width,
    double? height,
    Color? color,
    int? zIndex,
    bool? isVisible,
    bool? isInteractive,
    Map<String, dynamic>? metadata,
  }) {
    return StickyAnnotation(
      id: id ?? this.id,
      position: position ?? this.position,
      text: text ?? this.text,
      width: width ?? this.width,
      height: height ?? this.height,
      color: color ?? this.color,
      zIndex: zIndex ?? this.zIndex,
      isVisible: isVisible ?? this.isVisible,
      isInteractive: isInteractive ?? this.isInteractive,
      metadata: metadata ?? this.metadata,
    );
  }

  /// Creates a [StickyAnnotation] from a JSON map.
  ///
  /// This factory method is used during workflow deserialization to recreate
  /// sticky annotations from saved data.
  factory StickyAnnotation.fromJsonMap(Map<String, dynamic> json) {
    return StickyAnnotation(
      id: json['id'] as String,
      position: Offset(
        (json['x'] as num).toDouble(),
        (json['y'] as num).toDouble(),
      ),
      text: json['text'] as String? ?? '',
      width: (json['width'] as num?)?.toDouble() ?? 200.0,
      height: (json['height'] as num?)?.toDouble() ?? 100.0,
      color: Color(json['color'] as int? ?? Colors.yellow.toARGB32()),
      zIndex: json['zIndex'] as int? ?? 0,
      isVisible: json['isVisible'] as bool? ?? true,
      isInteractive: json['isInteractive'] as bool? ?? true,
      metadata: json['metadata'] as Map<String, dynamic>? ?? {},
    );
  }

  @override
  Map<String, dynamic> toJson() => {
    'id': id,
    'type': type,
    'x': position.dx,
    'y': position.dy,
    'text': text,
    'width': width,
    'height': height,
    'color': color.toARGB32(),
    'zIndex': zIndex,
    'isVisible': isVisible,
    'isInteractive': isInteractive,
    'metadata': metadata,
  };

  @override
  void fromJson(Map<String, dynamic> json) {
    final newPosition = Offset(
      (json['x'] as num).toDouble(),
      (json['y'] as num).toDouble(),
    );
    position = newPosition;
    zIndex = json['zIndex'] as int? ?? 0;
    isVisible = json['isVisible'] as bool? ?? true;
  }
}

/// Internal widget for rendering sticky note content.
///
/// This StatefulWidget manages the text editing state, including the
/// TextEditingController and FocusNode needed for in-place editing.
class _StickyContent extends StatefulWidget {
  const _StickyContent({required this.annotation});

  final StickyAnnotation annotation;

  @override
  State<_StickyContent> createState() => _StickyContentState();
}

class _StickyContentState extends State<_StickyContent> {
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
    _textController = TextEditingController(text: widget.annotation.text);
    _focusNode = FocusNode();

    // React to editing state changes to auto-focus
    _editingReaction = reaction((_) => widget.annotation.isEditing, (
      bool isEditing,
    ) {
      if (isEditing) {
        // Store original text for potential cancel
        _originalText = widget.annotation.text;
        // Sync controller with current annotation text
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
      }
    }, fireImmediately: true);

    // Handle focus loss to end editing
    _focusNode.addListener(_onFocusChange);

    // Listen to text changes for auto-grow
    _textController.addListener(_onTextChanged);
  }

  void _onFocusChange() {
    if (!_focusNode.hasFocus && widget.annotation.isEditing) {
      _commitEdit();
    }
  }

  void _onTextChanged() {
    if (!widget.annotation.isEditing) return;

    // Schedule height calculation after the frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _updateHeightIfNeeded();
      }
    });
  }

  void _updateHeightIfNeeded() {
    final annotation = widget.annotation;
    final text = _textController.text;

    // Get the text style
    final flowTheme = Theme.of(context).extension<NodeFlowTheme>();
    final annotationTheme = flowTheme?.annotationTheme;
    final textStyle =
        annotationTheme?.labelStyle ?? Theme.of(context).textTheme.bodyMedium;
    final fontSize = textStyle?.fontSize ?? 14.0;
    final lineHeight = fontSize * _lineHeightFactor;

    // Calculate required height based on text content
    final textPainter = TextPainter(
      text: TextSpan(text: text.isEmpty ? ' ' : text, style: textStyle),
      textDirection: TextDirection.ltr,
      maxLines: null,
    );

    // Layout with the available width (minus padding)
    final availableWidth = annotation.width - (_padding * 2);
    textPainter.layout(maxWidth: availableWidth);

    // Calculate required height: text height + padding + some buffer
    final requiredHeight = textPainter.height + (_padding * 2) + lineHeight;

    // Only grow, don't shrink below current height (user can manually resize smaller)
    if (requiredHeight > annotation.height) {
      final newHeight = requiredHeight.clamp(
        StickyAnnotation.minHeight,
        StickyAnnotation.maxHeight,
      );
      if (newHeight > annotation.height) {
        annotation.height = newHeight;
      }
    }
  }

  void _commitEdit() {
    widget.annotation.text = _textController.text;
    widget.annotation.isEditing = false;
  }

  /// Cancels the edit and restores the original text.
  void _cancelEdit() {
    _textController.text = _originalText;
    widget.annotation.isEditing = false;
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
    final annotationTheme = flowTheme?.annotationTheme;
    final textStyle =
        annotationTheme?.labelStyle ?? Theme.of(context).textTheme.bodyMedium;

    return Observer(
      builder: (_) {
        final isEditing = widget.annotation.isEditing;
        final annotation = widget.annotation;

        return Container(
          width: annotation.width,
          height: annotation.height,
          decoration: BoxDecoration(
            color: annotation.color.withValues(alpha: 0.9),
            borderRadius: BorderRadius.circular(8),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
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
              : Text(
                  annotation.text,
                  style: textStyle,
                  overflow: TextOverflow.fade,
                ),
        );
      },
    );
  }
}
