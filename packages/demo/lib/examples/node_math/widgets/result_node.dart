import 'package:flutter/material.dart';

import '../evaluation.dart';
import '../models.dart';
import '../theme.dart';

/// Content widget for a result/output node - matches reference design.
class ResultNodeContent extends StatelessWidget {
  final ResultData data;
  final EvalResult? result;

  const ResultNodeContent({super.key, required this.data, this.result});

  @override
  Widget build(BuildContext context) {
    final expression = result?.expression ?? '';
    final value = result?.value;
    final hasError = result?.hasError ?? false;

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
          if (expression.isNotEmpty)
            Flexible(
              child: Text(
                expression,
                style: const TextStyle(
                  color: MathColors.textSecondary,
                  fontSize: 13,
                  fontWeight: FontWeight.w400,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),

          // Equals sign
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
                hasError ? '?' : (value != null ? _formatValue(value) : '?'),
                style: TextStyle(
                  color: hasError
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
