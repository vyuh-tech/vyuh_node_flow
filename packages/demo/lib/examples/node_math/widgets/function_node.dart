import 'package:flutter/material.dart';

import '../evaluation.dart';
import '../models.dart';
import '../theme.dart';

/// Content widget for a function node - matches reference design.
class FunctionNodeContent extends StatelessWidget {
  final FunctionData data;
  final EvalResult? result;

  const FunctionNodeContent({super.key, required this.data, this.result});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Center(
        child: Text(
          data.function.symbol,
          style: const TextStyle(
            color: MathColors.portOperator,
            fontSize: 20,
            fontWeight: FontWeight.bold,
            fontFamily: 'monospace',
          ),
        ),
      ),
    );
  }
}
