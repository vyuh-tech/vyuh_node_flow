import 'package:flutter/material.dart';

import '../evaluation.dart';
import '../models.dart';
import '../theme.dart';
import '../utils.dart';

/// Content widget for a result/output node with auto-resize based on expression.
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

  void _checkAndUpdateSize() {
    final expression = widget.result?.expression ?? '';
    final newSize = _calculateRequiredSize(expression);

    if (_lastSize != newSize) {
      _lastSize = newSize;
      widget.onSizeChanged?.call(newSize);
    }
  }

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

  String _getDisplayValue(double? value, bool hasError, bool isUnconnected) {
    if (isUnconnected || hasError || value == null) return '?';
    return MathFormatters.formatNumber(value);
  }
}
