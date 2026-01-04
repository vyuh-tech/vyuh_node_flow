import 'package:flutter/material.dart';

import '../evaluation.dart';
import '../models.dart';
import '../theme.dart';

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

  // Text styles for measurement
  static const _expressionStyle = TextStyle(
    color: MathColors.textSecondary,
    fontSize: 13,
    fontWeight: FontWeight.w400,
  );

  @override
  void didUpdateWidget(ResultNodeContent oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Schedule size check after frame to ensure proper measurement
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _checkAndUpdateSize();
    });
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _checkAndUpdateSize();
    });
  }

  void _checkAndUpdateSize() {
    final expression = widget.result?.expression ?? '';
    final newSize = _calculateRequiredSize(expression);

    // Only notify if size actually changed
    if (_lastSize != newSize) {
      _lastSize = newSize;
      widget.onSizeChanged?.call(newSize);
    }
  }

  Size _calculateRequiredSize(String expression) {
    if (expression.isEmpty || expression == '?') {
      return Size(MathNodeSizes.resultMinWidth, MathNodeSizes.resultHeight);
    }

    // Measure expression text width
    final textPainter = TextPainter(
      text: TextSpan(text: expression, style: _expressionStyle),
      textDirection: TextDirection.ltr,
      maxLines: 1,
    );
    textPainter.layout();

    // Calculate required width: text width + padding
    final requiredWidth = textPainter.width + MathNodeSizes.resultPadding;

    // Clamp to min/max constraints
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
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.max,
        children: [
          // Expression at top
          if (expression.isNotEmpty && !isUnconnected)
            Flexible(
              child: Text(
                expression,
                style: _expressionStyle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),

          // Equals sign (hide if unconnected)
          if (!isUnconnected)
            const Text(
              '=',
              style: TextStyle(
                color: MathColors.textSecondary,
                fontSize: 14,
                fontWeight: FontWeight.w400,
              ),
            ),

          // Result value
          Flexible(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                isUnconnected
                    ? '?'
                    : (hasError
                        ? '?'
                        : (value != null ? _formatValue(value) : '?')),
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

  String _formatValue(double value) {
    if (value.isNaN || value.isInfinite) return '?';
    if (value == value.toInt()) {
      return value.toInt().toString();
    }
    return value.toStringAsFixed(2);
  }
}
