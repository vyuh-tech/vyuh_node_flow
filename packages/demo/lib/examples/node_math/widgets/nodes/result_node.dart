import 'package:flutter/material.dart';

import '../../evaluation/evaluator.dart';
import '../../core/models.dart';
import '../../presentation/theme.dart';
import '../../utils/formatters.dart';

/// Content widget displaying the computed expression and final value.
///
/// Auto-resizes horizontally to fit long expressions (up to [MathNodeSizes.resultMaxWidth]).
/// Notifies parent of size changes via [onSizeChanged] callback.
class ResultNodeContent extends StatefulWidget {
  final ResultData data;
  final EvalResult? result;
  final ValueChanged<Size>? onSizeChanged;

  const ResultNodeContent({
    super.key,
    required this.data,
    this.result,
    this.onSizeChanged,
  });

  @override
  State<ResultNodeContent> createState() => _ResultNodeContentState();
}

class _ResultNodeContentState extends State<ResultNodeContent> {
  Size? _lastSize;

  static const _expressionStyle = TextStyle(
    color: MathColors.textSecondary,
    fontSize: 13,
    fontWeight: FontWeight.w400,
  );

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _checkAndUpdateSize();
    });
  }

  @override
  void didUpdateWidget(ResultNodeContent oldWidget) {
    super.didUpdateWidget(oldWidget);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _checkAndUpdateSize();
    });
  }

  /// Compares current expression size with cached size, notifying parent on change.
  void _checkAndUpdateSize() {
    final expression = widget.result?.expression ?? '';
    final newSize = _calculateRequiredSize(expression);

    if (_lastSize != newSize) {
      _lastSize = newSize;
      widget.onSizeChanged?.call(newSize);
    }
  }

  /// Measures expression text width and returns clamped node size.
  ///
  /// Uses TextPainter for accurate measurement. Width is clamped between
  /// min (80px) and max (300px) to prevent extreme sizes.
  Size _calculateRequiredSize(String expression) {
    if (expression.isEmpty || expression == '?') {
      return Size(MathNodeSizes.resultMinWidth, MathNodeSizes.resultHeight);
    }

    final textPainter = TextPainter(
      text: TextSpan(text: expression, style: _expressionStyle),
      textDirection: TextDirection.ltr,
      maxLines: 1,
    );
    textPainter.layout();

    final requiredWidth = textPainter.width + MathNodeSizes.resultPadding;
    final width = requiredWidth.clamp(
      MathNodeSizes.resultMinWidth,
      MathNodeSizes.resultMaxWidth,
    );

    return Size(width, MathNodeSizes.resultHeight);
  }

  @override
  Widget build(BuildContext context) {
    final expression = widget.result?.expression ?? '';
    final value = widget.result?.value;
    final hasError = widget.result?.hasError ?? false;
    final isUnconnected = expression == '?';

    return Container(
      decoration: MathNodeStyles.nodeDecorationNoBorder,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.max,
        children: [
          if (expression.isNotEmpty && !isUnconnected)
            Flexible(
              child: Text(
                expression,
                style: _expressionStyle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          if (!isUnconnected)
            const Text(
              '=',
              style: TextStyle(
                color: MathColors.textSecondary,
                fontSize: 14,
                fontWeight: FontWeight.w400,
              ),
            ),
          Flexible(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                _getDisplayValue(value, hasError, isUnconnected),
                style: TextStyle(
                  color: (isUnconnected || hasError)
                      ? MathColors.textError
                      : MathColors.textResult,
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Formats the display value, showing "?" for error/unconnected states.
  String _getDisplayValue(double? value, bool hasError, bool isUnconnected) {
    if (isUnconnected || hasError || value == null) return '?';
    return MathFormatters.formatNumber(value);
  }
}
